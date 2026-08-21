module Main exposing (main)

import Api
import Browser
import Domain exposing (Dataset, Sample, partners)
import Html exposing (Html, button, div, h1, h2, p, span, text)
import Html.Attributes exposing (class, disabled, id)
import Html.Events exposing (onClick)
import Http
import View.Chord
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
    }


type Msg
    = GotDataset (Result Http.Error Dataset)
    | SelectPartner String
    | SelectTime Int
    | SelectCell String Int
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
            ( Ready { dataset = dataset, selectedIndex = 0, selectedPartner = Nothing }, Cmd.none )

        ( GotDataset (Err _), _ ) ->
            ( Failed "Der Datensatz konnte nicht über HTTP geladen werden.", Cmd.none )

        ( SelectPartner country, Ready state ) ->
            ( Ready { state | selectedPartner = Just country }, Cmd.none )

        ( SelectTime index, Ready state ) ->
            ( Ready { state | selectedIndex = index }, Cmd.none )

        ( SelectCell country index, Ready state ) ->
            ( Ready { state | selectedPartner = Just country, selectedIndex = index }, Cmd.none )

        ( Reset, Ready state ) ->
            ( Ready { state | selectedPartner = Nothing, selectedIndex = 0 }, Cmd.none )

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

        countryList =
            partners state.dataset

        selectionLabel =
            Maybe.withDefault "alle Partnerländer" state.selectedPartner
    in
    div [ class "app-shell" ]
        [ div [ class "hero" ]
            [ div []
                [ span [ class "eyebrow" ] [ text "ELM-PROTOTYP · ZWEITER ZWISCHENSTAND" ]
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
            [ span [] [ text ("Zeitraum: " ++ state.dataset.period) ]
            , span [] [ text ("Auswahl: " ++ selectionLabel ++ " · " ++ current.label) ]
            , button [ onClick Reset ] [ text "Auswahl zurücksetzen" ]
            ]
        , div [ class "grid-two" ]
            [ sectionCard "chord-view" "1 · Gerichtete Flüsse" "Klick auf eine Verbindung filtert die anderen Ansichten."
                [ View.Chord.view state.selectedPartner current SelectPartner ]
            , sectionCard "timeline-view" "2 · Erzeugungsmix im Zeitverlauf" "Klick auf eine Stunde aktualisiert Chord und Matrix."
                [ View.TimeSeries.view samples state.selectedIndex state.selectedPartner SelectTime
                , legend
                ]
            ]
        , sectionCard "matrix-view" "3 · Pixelmatrix" "Eine Zelle wählt gleichzeitig Partnerland und Stunde."
            [ View.FlowMatrix.view countryList samples state.selectedIndex state.selectedPartner SelectCell ]
        , p [ class "footnote" ]
            [ text "Vorzeichen: positive Werte = Import nach Deutschland, negative Werte = Export aus Deutschland. Der Erzeugungsmix zeigt zeitgleiche Produktion und keine physische Herkunft einzelner Importmengen." ]
        ]


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
        , legendItem "#7c3aed" "gewähltes Länderpaar"
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

