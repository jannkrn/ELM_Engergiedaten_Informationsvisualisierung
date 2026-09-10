module View.FlowMatrix exposing (view)

import Domain exposing (Sample, flowFor)
import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (g, rect, svg, text_)
import Svg.Attributes as A
import Svg.Events


view : List String -> List Sample -> List Sample -> Int -> Maybe String -> (String -> Int -> msg) -> Html msg
view countries scaleSamples samples selectedIndex selectedPartner onSelect =
    let
        width =
            900

        left =
            116

        top =
            26

        cellWidth =
            730 / toFloat (max 1 (List.length samples))

        cellHeight =
            25

        tickStride =
            max 1 (ceiling (toFloat (List.length samples) / 8))

        height =
            round (top + cellHeight * toFloat (List.length countries) + 58)

        maxAbs =
            countries
                |> List.concatMap (\country -> List.map (flowFor country >> abs) scaleSamples)
                |> List.maximum
                |> Maybe.withDefault 1
                |> max 1

        cell rowIndex country col sample =
            let
                value =
                    flowFor country sample

                active =
                    selectedIndex == col && selectedPartner == Just country
            in
            rect
                [ A.x (f (left + toFloat col * cellWidth))
                , A.y (f (top + toFloat rowIndex * cellHeight))
                , A.width (f (cellWidth + 0.4))
                , A.height (f cellHeight)
                , A.fill (colorFor maxAbs value)
                , A.stroke (if active then "#111827" else "none")
                , A.strokeWidth (if active then "3" else "0")
                , A.cursor "pointer"
                , Svg.Events.onClick (onSelect country col)
                ]
                [ Svg.title []
                    [ Svg.text
                        (country
                            ++ " · "
                            ++ sample.label
                            ++ " · physisch "
                            ++ f value
                            ++ " GW"
                        )
                    ]
                ]

        row rowIndex country =
            g []
                (text_
                    [ A.x (f (left - 10))
                    , A.y (f (top + toFloat rowIndex * cellHeight + 17))
                    , A.textAnchor "end"
                    , A.fontSize "12"
                    , A.fontFamily "Arial"
                    , A.fontWeight (if selectedPartner == Just country then "700" else "400")
                    , A.fill "#1f2937"
                    ]
                    [ Svg.text country ]
                    :: List.indexedMap (cell rowIndex country) samples
                )

        label index sample =
            if modBy tickStride index == 0 then
                text_
                    [ A.x (f (left + (toFloat index + 0.5) * cellWidth))
                    , A.y (f (top + cellHeight * toFloat (List.length countries) + 22))
                    , A.textAnchor "middle"
                    , A.fontSize "10"
                    , A.fontFamily "Arial"
                    , A.fill "#5b6472"
                    ]
                    [ Svg.text sample.label ]

            else
                g [] []

        selectedRow =
            selectedPartner
                |> Maybe.andThen (indexOf countries)

        selectionGuides =
            (if selectedIndex >= 0 && selectedIndex < List.length samples then
                [ rect
                    [ A.x (f (left + toFloat selectedIndex * cellWidth))
                    , A.y (f top)
                    , A.width (f cellWidth)
                    , A.height (f (cellHeight * toFloat (List.length countries)))
                    , A.fill "none"
                    , A.stroke "#d39a00"
                    , A.strokeWidth "2"
                    , A.pointerEvents "none"
                    ]
                    []
                ]

             else
                []
            )
                ++ (case selectedRow of
                        Just rowIndex ->
                            [ rect
                                [ A.x (f left)
                                , A.y (f (top + toFloat rowIndex * cellHeight))
                                , A.width (f 730)
                                , A.height (f cellHeight)
                                , A.fill "none"
                                , A.stroke "#d39a00"
                                , A.strokeWidth "2"
                                , A.pointerEvents "none"
                                ]
                                []
                            ]

                        Nothing ->
                            []
                   )
    in
    svg
        [ A.viewBox ("0 0 " ++ String.fromInt width ++ " " ++ String.fromInt height)
        , A.width "100%"
        , HA.attribute "role" "img"
        , HA.attribute "aria-label" "Pixelmatrix der Stromflüsse nach Partnerland und Stunde"
        ]
        (List.indexedMap row countries
            ++ List.indexedMap label samples
            ++ selectionGuides
            ++ [ text_ [ A.x (f left), A.y (f (toFloat height - 8)), A.fontSize "11", A.fontFamily "Arial", A.fill "#326db6" ] [ Svg.text ("Export −" ++ oneDecimal maxAbs ++ " GW") ]
               , text_ [ A.x (f (left + 365)), A.y (f (toFloat height - 8)), A.textAnchor "middle", A.fontSize "11", A.fontFamily "Arial", A.fill "#5b6472" ] [ Svg.text "0 GW" ]
               , text_ [ A.x (f (left + 730)), A.y (f (toFloat height - 8)), A.textAnchor "end", A.fontSize "11", A.fontFamily "Arial", A.fill "#c44545" ] [ Svg.text ("Import +" ++ oneDecimal maxAbs ++ " GW") ]
               ]
        )


colorFor : Float -> Float -> String
colorFor maxAbs value =
    let
        ratio =
            min 1 (abs value / maxAbs)

        blend from to =
            round (toFloat from * (1 - ratio) + toFloat to * ratio)

        ( r, g, b ) =
            if value >= 0 then
                ( blend 232 190, blend 235 55, blend 238 55 )

            else
                ( blend 232 45, blend 235 100, blend 238 175 )
    in
    "rgb(" ++ String.fromInt r ++ "," ++ String.fromInt g ++ "," ++ String.fromInt b ++ ")"


f : Float -> String
f =
    String.fromFloat


oneDecimal : Float -> String
oneDecimal value =
    (toFloat (round (value * 10)) / 10)
        |> String.fromFloat
        |> String.replace "." ","


indexOf : List String -> String -> Maybe Int
indexOf values target =
    values
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, value ) -> value == target)
        |> List.head
        |> Maybe.map Tuple.first
