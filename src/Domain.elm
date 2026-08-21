module Domain exposing
    ( Dataset
    , Flow
    , Generation
    , Sample
    , flowFor
    , partners
    )


type alias Dataset =
    { source : String
    , sourceStatus : String
    , period : String
    , samples : List Sample
    }


type alias Sample =
    { timestamp : Int
    , label : String
    , generation : Generation
    , price : Float
    , flows : List Flow
    }


type alias Generation =
    { renewables : Float
    , coal : Float
    , gas : Float
    , other : Float
    }


type alias Flow =
    { country : String
    , value : Float
    , trade : Float
    }


partners : Dataset -> List String
partners dataset =
    dataset.samples
        |> List.head
        |> Maybe.map (.flows >> List.map .country)
        |> Maybe.withDefault []


flowFor : String -> Sample -> Float
flowFor country sample =
    sample.flows
        |> List.filter (\flow -> flow.country == country)
        |> List.head
        |> Maybe.map .value
        |> Maybe.withDefault 0
