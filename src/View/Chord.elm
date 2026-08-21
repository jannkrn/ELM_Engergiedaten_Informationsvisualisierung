module View.Chord exposing (view)

import Domain exposing (Flow, Sample)
import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (Svg, circle, defs, g, line, marker, path, svg, text_)
import Svg.Attributes as A
import Svg.Events


view : Maybe String -> Sample -> (String -> msg) -> Html msg
view selected sample onSelect =
    let
        width =
            560

        height =
            480

        cx =
            280

        cy =
            240

        radius =
            175

        flows =
            sample.flows

        count =
            max 1 (List.length flows)

        position index =
            let
                angle =
                    (-pi / 2) + (2 * pi * toFloat index / toFloat count)
            in
            ( cx + radius * cos angle, cy + radius * sin angle )

        edge index flow =
            let
                ( px, py ) =
                    position index

                isImport =
                    flow.value >= 0

                endpoints =
                    if isImport then
                        { x1 = px, y1 = py, x2 = cx, y2 = cy + 82 }

                    else
                        { x1 = cx, y1 = cy + 82, x2 = px, y2 = py }

                color =
                    if isImport then
                        "#c44545"

                    else
                        "#326db6"

                opacity =
                    case selected of
                        Nothing ->
                            "0.82"

                        Just country ->
                            if country == flow.country then
                                "1"

                            else
                                "0.16"

                strokeWidth =
                    String.fromFloat (2.5 + min 16 (abs flow.value * 2.4))
            in
            path
                [ A.d ("M " ++ f endpoints.x1 ++ " " ++ f endpoints.y1 ++ " Q " ++ f cx ++ " " ++ f (cy - 30) ++ " " ++ f endpoints.x2 ++ " " ++ f endpoints.y2)
                , A.fill "none"
                , A.stroke color
                , A.strokeWidth strokeWidth
                , A.strokeOpacity opacity
                , A.markerEnd (if isImport then "url(#arrow-red)" else "url(#arrow-blue)")
                , A.cursor "pointer"
                , Svg.Events.onClick (onSelect flow.country)
                ]
                [ Svg.title []
                    [ Svg.text
                        (flow.country
                            ++ ": physisch "
                            ++ f flow.value
                            ++ " GW, Handel "
                            ++ f flow.trade
                            ++ " GW"
                        )
                    ]
                ]

        node index flow =
            let
                ( x, y ) =
                    position index

                active =
                    selected == Just flow.country
            in
            g [ A.cursor "pointer", Svg.Events.onClick (onSelect flow.country) ]
                [ circle
                    [ A.cx (f x)
                    , A.cy (f y)
                    , A.r (if active then "14" else "10")
                    , A.fill (if active then "#f2c94c" else "#23354d")
                    , A.stroke "white"
                    , A.strokeWidth "2"
                    ]
                    []
                , text_
                    [ A.x (f (x + if x < cx then -14 else 14))
                    , A.y (f (y + 5))
                    , A.textAnchor (if x < cx then "end" else "start")
                    , A.fontSize "12"
                    , A.fontFamily "Arial"
                    , A.fontWeight (if active then "700" else "500")
                    , A.fill "#1f2937"
                    ]
                    [ Svg.text flow.country ]
                ]
    in
    svg
        [ A.viewBox ("0 0 " ++ String.fromInt width ++ " " ++ String.fromInt height)
        , A.width "100%"
        , HA.attribute "role" "img"
        , HA.attribute "aria-label" "Gerichteter Chord-Prototyp der Stromflüsse"
        ]
        ([ defs []
            [ arrow "arrow-red" "#c44545"
            , arrow "arrow-blue" "#326db6"
            ]
         , circle [ A.cx (f cx), A.cy (f (cy + 82)), A.r "45", A.fill "#f2c94c", A.stroke "#8a6d08", A.strokeWidth "2" ] []
         , text_ [ A.x (f cx), A.y (f (cy + 88)), A.textAnchor "middle", A.fontFamily "Arial", A.fontWeight "700", A.fontSize "21", A.fill "#172033" ] [ Svg.text "DE" ]
         ]
            ++ List.indexedMap edge flows
            ++ List.indexedMap node flows
        )


arrow : String -> String -> Svg msg
arrow markerId color =
    marker
        [ A.id markerId
        , A.viewBox "0 0 10 10"
        , A.refX "9"
        , A.refY "5"
        , A.markerWidth "6"
        , A.markerHeight "6"
        , A.orient "auto-start-reverse"
        ]
        [ path [ A.d "M 0 0 L 10 5 L 0 10 z", A.fill color ] [] ]


f : Float -> String
f =
    String.fromFloat
