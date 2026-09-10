module Main exposing (main)

import Api
import Browser
import Domain exposing (Dataset, Sample, partners)
import Html exposing (Html, button, div, h1, h2, p, span, text)
import Html.Attributes exposing (class, disabled, id)
import Html.Events exposing (onClick)
import Http
import View.FlowNetwork
import View.FlowMatrix
import View.TimeSeries


type Model
    = Loading
    | Failed String
    | Ready State


type alias State =
    { dataset : Dataset
    , selectedIndex : Int
    , selectedPartner : Maybe String
    , windowStart : Int
    , windowSize : Int
    }


type Msg
    = GotDataset (Result Http.Error Dataset)
    | SelectPartner String
    | SelectTime Int
    | SelectCell String Int
    | SetWindowSize Int
    | MoveWindow Int
    | Reset


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Loading, Api.loadDataset GotDataset )
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( GotDataset (Ok dataset), _ ) ->
            ( Ready
                { dataset = dataset
                , selectedIndex = 0
                , selectedPartner = Nothing
                , windowStart = 0
                , windowSize = min 168 (List.length dataset.samples)
                }
            , Cmd.none
            )

        ( GotDataset (Err _), _ ) ->
            ( Failed "Der Datensatz konnte nicht über HTTP geladen werden.", Cmd.none )

        ( SelectPartner country, Ready state ) ->
            ( Ready { state | selectedPartner = Just country }, Cmd.none )

        ( SelectTime index, Ready state ) ->
            ( Ready { state | selectedIndex = index }, Cmd.none )

        ( SelectCell country index, Ready state ) ->
            ( Ready { state | selectedPartner = Just country, selectedIndex = index }, Cmd.none )

        ( SetWindowSize requestedSize, Ready state ) ->
            let
                sampleCount =
                    List.length state.dataset.samples

                nextSize =
                    min sampleCount requestedSize

                alignedStart =
                    if nextSize <= 0 then
                        0

                    else
                        state.selectedIndex - modBy nextSize state.selectedIndex

                nextStart =
                    clamp 0 (max 0 (sampleCount - nextSize)) alignedStart
            in
            ( Ready { state | windowStart = nextStart, windowSize = nextSize }, Cmd.none )

        ( MoveWindow direction, Ready state ) ->
            let
                sampleCount =
                    List.length state.dataset.samples

                nextStart =
                    clamp 0
                        (max 0 (sampleCount - state.windowSize))
                        (state.windowStart + direction * state.windowSize)
            in
            ( Ready { state | windowStart = nextStart, selectedIndex = nextStart }, Cmd.none )

        ( Reset, Ready state ) ->
            ( Ready { state | selectedPartner = Nothing, selectedIndex = state.windowStart }, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            div [ class "state-message" ] [ text "Daten werden geladen …" ]

        Failed message ->
            div [ class "state-message error" ] [ text message ]

        Ready state ->
            viewDashboard state


viewDashboard : State -> Html Msg
viewDashboard state =
    let
        samples =
            state.dataset.samples

        current =
            sampleAt state.selectedIndex samples

        visibleSamples =
            samples
                |> List.drop state.windowStart
                |> List.take state.windowSize

        visibleSelectedIndex =
            clamp 0 (max 0 (List.length visibleSamples - 1)) (state.selectedIndex - state.windowStart)

        countryList =
            partners state.dataset

        selectionLabel =
            Maybe.withDefault "alle Partnerländer" state.selectedPartner

        visiblePeriod =
            case ( List.head visibleSamples, List.reverse visibleSamples |> List.head ) of
                ( Just first, Just last ) ->
                    first.label ++ " – " ++ last.label

                _ ->
                    "–"

        canMoveBack =
            state.windowStart > 0

        canMoveForward =
            state.windowStart + state.windowSize < List.length samples
    in
    div [ class "app-shell" ]
        [ div [ class "hero" ]
            [ div []
                [ span [ class "eyebrow" ] [ text "ELM · VISUAL-ANALYTICS-PROJEKT" ]
                , h1 [] [ text "Deutschlands Rolle im europäischen Stromnetz" ]
                , p [ class "subtitle" ] [ text "Drei interaktiv verbundene Ansichten für physische Flüsse und Erzeugungsmix" ]
                ]
            , div [ class "source-card" ]
                [ span [ class "source-label" ] [ text "Datenstatus" ]
                , p [] [ text state.dataset.source ]
                , span [ class "source-status" ] [ text state.dataset.sourceStatus ]
                ]
            ]
        , div [ class "toolbar" ]
            [ span [] [ text ("Datensatz: " ++ state.dataset.period) ]
            , span [] [ text ("Ansicht: " ++ visiblePeriod) ]
            , span [] [ text ("Auswahl: " ++ selectionLabel ++ " · " ++ current.label) ]
            , button [ onClick Reset ] [ text "Auswahl zurücksetzen" ]
            ]
        , div [ class "range-toolbar" ]
            [ span [ class "range-label" ] [ text "Angezeigter Zeitraum" ]
            , rangeButton state.windowSize 48 "48 Stunden"
            , rangeButton state.windowSize 168 "7 Tage"
            , rangeButton state.windowSize (List.length samples) "Gesamter Monat"
            , button [ class "range-nav", disabled (not canMoveBack), onClick (MoveWindow -1) ] [ text "← vorheriger Zeitraum" ]
            , button [ class "range-nav", disabled (not canMoveForward), onClick (MoveWindow 1) ] [ text "nächster Zeitraum →" ]
            ]
        , div [ class "grid-two" ]
            [ sectionCard "flow-view" "1 · Gerichtete Flüsse" "Pfeilrichtung und Farbe zeigen Import oder Export; die Breite zeigt den Betrag."
                [ View.FlowNetwork.view state.selectedPartner current SelectPartner ]
            , sectionCard "timeline-view" "2 · Erzeugungsmix im Zeitverlauf" "Absolute Leistung in GW; Werte und Anteile beziehen sich auf die ausgewählte Stunde."
                [ View.TimeSeries.view visibleSamples visibleSelectedIndex state.selectedPartner
                    (\localIndex -> SelectTime (state.windowStart + localIndex))
                , legend
                ]
            ]
        , sectionCard "matrix-view" "3 · Pixelmatrix" "Eine Zelle wählt gleichzeitig Partnerland und Stunde; Zeilen und Spalten verwenden dieselbe globale Farbskala."
            [ View.FlowMatrix.view countryList samples visibleSamples visibleSelectedIndex state.selectedPartner
                (\country localIndex -> SelectCell country (state.windowStart + localIndex))
            ]
        , p [ class "footnote" ]
            [ text "Vorzeichen: positive Werte = Import nach Deutschland, negative Werte = Export aus Deutschland. Der Erzeugungsmix zeigt zeitgleiche Produktion und keine physische Herkunft einzelner Importmengen." ]
        ]


rangeButton : Int -> Int -> String -> Html Msg
rangeButton currentSize size label =
    button
        [ class
            (if currentSize == size then
                "range-button active"

             else
                "range-button"
            )
        , onClick (SetWindowSize size)
        ]
        [ text label ]


sectionCard : String -> String -> String -> List (Html msg) -> Html msg
sectionCard anchor title description content =
    div [ class "panel", id anchor ]
        (div [ class "panel-heading" ]
            [ div [] [ h2 [] [ text title ], p [] [ text description ] ] ]
            :: content
        )


legend : Html msg
legend =
    div [ class "legend" ]
        [ legendItem "#63a35c" "Erneuerbare"
        , legendItem "#665c54" "Kohle"
        , legendItem "#e6a23c" "Gas"
        , legendItem "#9ca3af" "Sonstige"
        , legendItem "#7c3aed" "physischer Fluss (eigene GW-Skala)"
        ]


legendItem : String -> String -> Html msg
legendItem color label =
    span [] [ span [ class "swatch", Html.Attributes.style "background" color ] [], text label ]


sampleAt : Int -> List Sample -> Sample
sampleAt index samples =
    samples
        |> List.drop index
        |> List.head
        |> Maybe.withDefault
            { timestamp = 0
            , label = "–"
            , generation = { renewables = 0, coal = 0, gas = 0, other = 0 }
            , price = 0
            , flows = []
            }
