module View.TimeSeries exposing (view)

import Domain exposing (Sample, flowFor)
import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (circle, g, line, path, rect, svg, text_)
import Svg.Attributes as A
import Svg.Events


view : List Sample -> Int -> Maybe String -> (Int -> msg) -> Html msg
view samples selectedIndex selectedPartner onSelect =
    let
        width =
            900

        height =
            350

        left =
            54

        top =
            30

        plotWidth =
            810

        plotHeight =
            250

        count =
            max 1 (List.length samples)

        x index =
            left + toFloat index * plotWidth / toFloat (max 1 (count - 1))

        total sample =
            sample.generation.renewables + sample.generation.coal + sample.generation.gas + sample.generation.other

        maxPower =
            samples |> List.map total |> List.maximum |> Maybe.withDefault 1 |> max 1

        y value =
            top + plotHeight - value * plotHeight / maxPower

        bottoms accessor =
            List.map accessor samples

        renewTop sample =
            sample.generation.renewables

        coalTop sample =
            renewTop sample + sample.generation.coal

        gasTop sample =
            coalTop sample + sample.generation.gas

        allTop sample =
            gasTop sample + sample.generation.other

        area upper lower color =
            path [ A.d (areaPath x y samples upper lower), A.fill color, A.fillOpacity "0.92" ] []

        selectedX =
            x selectedIndex

        partnerPoints =
            case selectedPartner of
                Nothing ->
                    []

                Just country ->
                    let
                        maxAbs =
                            samples |> List.map (flowFor country >> abs) |> List.maximum |> Maybe.withDefault 1 |> max 1

                        flowY sample =
                            top + plotHeight / 2 - flowFor country sample * (plotHeight * 0.38) / maxAbs
                    in
                    [ path
                        [ A.d (linePath x flowY samples)
                        , A.fill "none"
                        , A.stroke "#7c3aed"
                        , A.strokeWidth "3"
                        ]
                        []
                    ]

        hit index sample =
            rect
                [ A.x (f (x index - plotWidth / toFloat count / 2))
                , A.y (f top)
                , A.width (f (plotWidth / toFloat count + 1))
                , A.height (f plotHeight)
                , A.fill "transparent"
                , A.cursor "pointer"
                , Svg.Events.onClick (onSelect index)
                ]
                []

        labelAt index sample =
            if modBy 6 index == 0 then
                text_
                    [ A.x (f (x index))
                    , A.y (f (top + plotHeight + 23))
                    , A.textAnchor "middle"
                    , A.fontSize "10"
                    , A.fontFamily "Arial"
                    , A.fill "#5b6472"
                    ]
                    [ Svg.text sample.label ]

            else
                g [] []
    in
    svg
        [ A.viewBox ("0 0 " ++ String.fromInt width ++ " " ++ String.fromInt height)
        , A.width "100%"
        , HA.attribute "role" "img"
        , HA.attribute "aria-label" "Gestapelte Zeitreihe des Erzeugungsmix"
        ]
        ([ line [ A.x1 (f left), A.y1 (f (top + plotHeight)), A.x2 (f (left + plotWidth)), A.y2 (f (top + plotHeight)), A.stroke "#aab2bd" ] []
         , area renewTop (always 0) "#63a35c"
         , area coalTop renewTop "#665c54"
         , area gasTop coalTop "#e6a23c"
         , area allTop gasTop "#9ca3af"
         ]
            ++ partnerPoints
            ++ [ line [ A.x1 (f selectedX), A.y1 (f top), A.x2 (f selectedX), A.y2 (f (top + plotHeight)), A.stroke "#1f2937", A.strokeWidth "2", A.strokeDasharray "5 4" ] [] ]
            ++ List.indexedMap hit samples
            ++ List.indexedMap labelAt samples
        )


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
