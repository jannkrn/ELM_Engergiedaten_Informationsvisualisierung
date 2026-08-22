module View.TimeSeries exposing (view)

import Domain exposing (Sample, flowFor)
import Html exposing (Html, div, span, text)
import Html.Attributes as HA
import Svg exposing (Svg, circle, g, line, path, rect, svg, text_)
import Svg.Attributes as A
import Svg.Events


view : List Sample -> Int -> Maybe String -> (Int -> msg) -> Html msg
view samples selectedIndex selectedPartner onSelect =
    let
        width =
            900

        height =
            500

        left =
            78

        top =
            24

        plotWidth =
            790

        generationHeight =
            235

        generationBottom =
            top + generationHeight

        flowTop =
            326

        flowHeight =
            105

        flowBottom =
            flowTop + flowHeight

        count =
            max 1 (List.length samples)

        x index =
            left + toFloat index * plotWidth / toFloat (max 1 (count - 1))

        total sample =
            sample.generation.renewables + sample.generation.coal + sample.generation.gas + sample.generation.other

        maxPower =
            samples |> List.map total |> List.maximum |> Maybe.withDefault 1 |> max 1

        generationStep =
            niceGenerationStep maxPower

        generationMax =
            toFloat (ceiling (maxPower / generationStep)) * generationStep

        generationTicks =
            List.range 0 (round (generationMax / generationStep))
                |> List.map (\index -> toFloat index * generationStep)

        yGeneration value =
            generationBottom - value * generationHeight / generationMax

        renewTop sample =
            sample.generation.renewables

        coalTop sample =
            renewTop sample + sample.generation.coal

        gasTop sample =
            coalTop sample + sample.generation.gas

        allTop sample =
            gasTop sample + sample.generation.other

        area upper lower color =
            path [ A.d (areaPath x yGeneration samples upper lower), A.fill color, A.fillOpacity "0.92" ] []

        selectedSample =
            sampleAt selectedIndex samples

        selectedX =
            x selectedIndex

        flowMax =
            case selectedPartner of
                Nothing ->
                    1

                Just country ->
                    samples
                        |> List.map (flowFor country >> abs)
                        |> List.maximum
                        |> Maybe.withDefault 1
                        |> max 0.1
                        |> ceilingToHalf

        yFlow value =
            flowTop + flowHeight / 2 - value * (flowHeight * 0.45) / flowMax

        partnerLine =
            case selectedPartner of
                Nothing ->
                    [ text_
                        [ A.x (f (left + plotWidth / 2))
                        , A.y (f (flowTop + flowHeight / 2 + 4))
                        , A.textAnchor "middle"
                        , A.fontSize "12"
                        , A.fontFamily "Arial"
                        , A.fill "#697482"
                        ]
                        [ Svg.text "Partnerland in der Flussansicht oder Matrix auswählen" ]
                    ]

                Just country ->
                    let
                        selectedValue =
                            flowFor country selectedSample
                    in
                    [ path
                        [ A.d (linePath x (flowFor country >> yFlow) samples)
                        , A.fill "none"
                        , A.stroke "#7c3aed"
                        , A.strokeWidth "3"
                        ]
                        []
                    , circle
                        [ A.cx (f selectedX)
                        , A.cy (f (yFlow selectedValue))
                        , A.r "5"
                        , A.fill "#7c3aed"
                        , A.stroke "white"
                        , A.strokeWidth "2"
                        ]
                        []
                    , text_
                        [ A.x (f left)
                        , A.y (f (flowTop - 12))
                        , A.fontSize "12"
                        , A.fontFamily "Arial"
                        , A.fontWeight "700"
                        , A.fill "#4c5665"
                        ]
                        [ Svg.text ("Physischer Stromfluss Deutschland ↔ " ++ country) ]
                    ]

        hit index sample =
            g []
                [ Svg.title [] [ Svg.text (tooltipText selectedPartner sample) ]
                , rect
                    [ A.x (f (x index - plotWidth / toFloat count / 2))
                    , A.y (f top)
                    , A.width (f (plotWidth / toFloat count + 1))
                    , A.height (f (flowBottom - top))
                    , A.fill "transparent"
                    , A.cursor "pointer"
                    , Svg.Events.onClick (onSelect index)
                    ]
                    []
                ]

        labelAt index sample =
            if modBy 6 index == 0 then
                text_
                    [ A.x (f (x index))
                    , A.y (f (flowBottom + 25))
                    , A.textAnchor "middle"
                    , A.fontSize "10"
                    , A.fontFamily "Arial"
                    , A.fill "#5b6472"
                    ]
                    [ Svg.text sample.label ]

            else
                g [] []

        generationAxis =
            generationTicks |> List.concatMap (generationTick left plotWidth yGeneration)

        flowAxis =
            flowTicks left plotWidth flowTop flowHeight flowMax yFlow
    in
    div [ HA.class "timeseries-block" ]
        [ svg
            [ A.viewBox ("0 0 " ++ String.fromInt width ++ " " ++ String.fromInt height)
            , A.width "100%"
            , HA.attribute "role" "img"
            , HA.attribute "aria-label" "Gestapelte Zeitreihe der absoluten Erzeugungsleistung mit separater Stromflussskala"
            ]
            (generationAxis
                ++ [ text_
                        [ A.x "18"
                        , A.y (f (top + generationHeight / 2))
                        , A.textAnchor "middle"
                        , A.fontSize "12"
                        , A.fontFamily "Arial"
                        , A.fontWeight "700"
                        , A.fill "#4c5665"
                        , A.transform ("rotate(-90 18 " ++ f (top + generationHeight / 2) ++ ")")
                        ]
                        [ Svg.text "Erzeugungsleistung (GW)" ]
                   , area renewTop (always 0) "#63a35c"
                   , area coalTop renewTop "#665c54"
                   , area gasTop coalTop "#e6a23c"
                   , area allTop gasTop "#9ca3af"
                   ]
                ++ flowAxis
                ++ partnerLine
                ++ [ line
                        [ A.x1 (f selectedX)
                        , A.y1 (f top)
                        , A.x2 (f selectedX)
                        , A.y2 (f flowBottom)
                        , A.stroke "#1f2937"
                        , A.strokeWidth "2"
                        , A.strokeDasharray "5 4"
                        ]
                        []
                   , text_
                        [ A.x (f (left + plotWidth / 2))
                        , A.y (f (height - 8))
                        , A.textAnchor "middle"
                        , A.fontSize "12"
                        , A.fontFamily "Arial"
                        , A.fontWeight "700"
                        , A.fill "#4c5665"
                        ]
                        [ Svg.text "Zeitpunkt (UTC)" ]
                   ]
                ++ List.indexedMap hit samples
                ++ List.indexedMap labelAt samples
            )
        , selectedDetails selectedSample selectedPartner
        ]


generationTick : Float -> Float -> (Float -> Float) -> Float -> List (Svg msg)
generationTick left plotWidth y value =
    [ line
        [ A.x1 (f left)
        , A.y1 (f (y value))
        , A.x2 (f (left + plotWidth))
        , A.y2 (f (y value))
        , A.stroke "#dce2e8"
        , A.strokeWidth "1"
        ]
        []
    , text_
        [ A.x (f (left - 10))
        , A.y (f (y value + 4))
        , A.textAnchor "end"
        , A.fontSize "11"
        , A.fontFamily "Arial"
        , A.fill "#5b6472"
        ]
        [ Svg.text (formatNumber 0 value) ]
    ]


flowTicks : Float -> Float -> Float -> Float -> Float -> (Float -> Float) -> List (Svg msg)
flowTicks left plotWidth flowTop flowHeight flowMax y =
    let
        values =
            [ flowMax, 0, -flowMax ]

        tick value =
            [ line
                [ A.x1 (f left)
                , A.y1 (f (y value))
                , A.x2 (f (left + plotWidth))
                , A.y2 (f (y value))
                , A.stroke (if value == 0 then "#9aa5b1" else "#e4e8ed")
                , A.strokeWidth "1"
                , A.strokeDasharray (if value == 0 then "4 3" else "0")
                ]
                []
            , text_
                [ A.x (f (left - 10))
                , A.y (f (y value + 4))
                , A.textAnchor "end"
                , A.fontSize "11"
                , A.fontFamily "Arial"
                , A.fill "#5b6472"
                ]
                [ Svg.text (formatSigned value) ]
            ]
    in
    (values |> List.concatMap tick)
        ++ [ line
                [ A.x1 (f left)
                , A.y1 (f flowTop)
                , A.x2 (f left)
                , A.y2 (f (flowTop + flowHeight))
                , A.stroke "#aab2bd"
                ]
                []
           , text_
                [ A.x "18"
                , A.y (f (flowTop + flowHeight / 2))
                , A.textAnchor "middle"
                , A.fontSize "12"
                , A.fontFamily "Arial"
                , A.fontWeight "700"
                , A.fill "#4c5665"
                , A.transform ("rotate(-90 18 " ++ f (flowTop + flowHeight / 2) ++ ")")
                ]
                [ Svg.text "Stromfluss (GW)" ]
           ]


selectedDetails : Sample -> Maybe String -> Html msg
selectedDetails sample selectedPartner =
    let
        generation =
            sample.generation

        total =
            generation.renewables + generation.coal + generation.gas + generation.other

        generationItem label value =
            detailItem label (formatNumber 1 value ++ " GW · " ++ formatPercent value total)

        flowItem =
            case selectedPartner of
                Nothing ->
                    []

                Just country ->
                    [ detailItem ("Fluss " ++ country) (formatSigned (flowFor country sample) ++ " GW") ]
    in
    div [ HA.class "timeseries-details", HA.attribute "aria-live" "polite" ]
        (detailItem "Ausgewählte Stunde" sample.label
            :: detailItem "Gesamt" (formatNumber 1 total ++ " GW")
            :: generationItem "Erneuerbare" generation.renewables
            :: generationItem "Kohle" generation.coal
            :: generationItem "Gas" generation.gas
            :: generationItem "Sonstige" generation.other
            :: detailItem "Strompreis" (formatNumber 1 sample.price ++ " €/MWh")
            :: flowItem
        )


detailItem : String -> String -> Html msg
detailItem label value =
    span [ HA.class "timeseries-detail" ]
        [ span [ HA.class "timeseries-detail-label" ] [ text label ]
        , span [ HA.class "timeseries-detail-value" ] [ text value ]
        ]


tooltipText : Maybe String -> Sample -> String
tooltipText selectedPartner sample =
    let
        generation =
            sample.generation

        total =
            generation.renewables + generation.coal + generation.gas + generation.other

        flowLine =
            case selectedPartner of
                Nothing ->
                    ""

                Just country ->
                    "\nFluss " ++ country ++ ": " ++ formatSigned (flowFor country sample) ++ " GW"
    in
    sample.label
        ++ "\nGesamt: "
        ++ formatNumber 1 total
        ++ " GW"
        ++ "\nErneuerbare: "
        ++ formatNumber 1 generation.renewables
        ++ " GW ("
        ++ formatPercent generation.renewables total
        ++ ")"
        ++ "\nKohle: "
        ++ formatNumber 1 generation.coal
        ++ " GW ("
        ++ formatPercent generation.coal total
        ++ ")"
        ++ "\nGas: "
        ++ formatNumber 1 generation.gas
        ++ " GW ("
        ++ formatPercent generation.gas total
        ++ ")"
        ++ "\nSonstige: "
        ++ formatNumber 1 generation.other
        ++ " GW ("
        ++ formatPercent generation.other total
        ++ ")"
        ++ flowLine


niceGenerationStep : Float -> Float
niceGenerationStep maximum =
    if maximum <= 20 then
        5

    else if maximum <= 40 then
        10

    else if maximum <= 80 then
        20

    else if maximum <= 120 then
        25

    else
        50


ceilingToHalf : Float -> Float
ceilingToHalf value =
    toFloat (ceiling (value * 2)) / 2


formatPercent : Float -> Float -> String
formatPercent value total =
    if total <= 0 then
        "0 %"

    else
        formatNumber 0 (value * 100 / total) ++ " %"


formatSigned : Float -> String
formatSigned value =
    (if value > 0 then
        "+"

     else
        ""
    )
        ++ formatNumber 1 value


formatNumber : Int -> Float -> String
formatNumber decimals value =
    let
        factor =
            toFloat (10 ^ decimals)

        rounded =
            toFloat (round (value * factor)) / factor
    in
    String.fromFloat rounded |> String.replace "." ","


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


areaPath : (Int -> Float) -> (Float -> Float) -> List Sample -> (Sample -> Float) -> (Sample -> Float) -> String
areaPath x y samples upper lower =
    let
        topPoints =
            samples |> List.indexedMap (\index sample -> point (x index) (y (upper sample)))

        bottomPoints =
            samples |> List.indexedMap (\index sample -> point (x index) (y (lower sample))) |> List.reverse
    in
    "M " ++ String.join " L " (topPoints ++ bottomPoints) ++ " Z"


linePath : (Int -> Float) -> (Sample -> Float) -> List Sample -> String
linePath x y samples =
    samples
        |> List.indexedMap (\index sample -> point (x index) (y sample))
        |> String.join " L "
        |> (++) "M "


point : Float -> Float -> String
point x y =
    f x ++ " " ++ f y


f : Float -> String
f =
    String.fromFloat
