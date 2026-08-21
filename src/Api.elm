module Api exposing (loadDataset)

import Domain exposing (Dataset, Flow, Generation, Sample)
import Http
import Json.Decode as Decode exposing (Decoder)


loadDataset : (Result Http.Error Dataset -> msg) -> Cmd msg
loadDataset toMsg =
    Http.get
        { url = "data/energy.json"
        , expect = Http.expectJson toMsg datasetDecoder
        }


datasetDecoder : Decoder Dataset
datasetDecoder =
    Decode.map4 Dataset
        (Decode.field "source" Decode.string)
        (Decode.field "sourceStatus" Decode.string)
        (Decode.field "period" Decode.string)
        (Decode.field "samples" (Decode.list sampleDecoder))


sampleDecoder : Decoder Sample
sampleDecoder =
    Decode.map5 Sample
        (Decode.field "timestamp" Decode.int)
        (Decode.field "label" Decode.string)
        (Decode.field "generation" generationDecoder)
        (Decode.field "price" Decode.float)
        (Decode.field "flows" (Decode.list flowDecoder))


generationDecoder : Decoder Generation
generationDecoder =
    Decode.map4 Generation
        (Decode.field "renewables" Decode.float)
        (Decode.field "coal" Decode.float)
        (Decode.field "gas" Decode.float)
        (Decode.field "other" Decode.float)


flowDecoder : Decoder Flow
flowDecoder =
    Decode.map3 Flow
        (Decode.field "country" Decode.string)
        (Decode.field "value" Decode.float)
        (Decode.field "trade" Decode.float)
