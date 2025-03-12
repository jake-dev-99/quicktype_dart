-- To decode the JSON data, add this file to your project, run
--
--     elm-package install NoRedInk/elm-decode-pipeline
--
-- add these imports
--
--     import Json.Decode exposing (decodeString)`);
--     import QuickType exposing (test, convert)
--
-- and you're off to the races with
--
--     decodeString test myJsonString
--     decodeString convert myJsonString

module QuickType exposing
    ( Test
    , testToString
    , test
    , Convert
    , convertToString
    , convert
    )

import Json.Decode as Jdec
import Json.Decode.Pipeline as Jpipe
import Json.Encode as Jenc
import Dict exposing (Dict, map, toList)
import Array exposing (Array, map)

type alias Test =
    { asdf : String
    , asdf2 : String
    }

type alias Convert =
    {
    }

-- decoders and encoders

testToString : Test -> String
testToString r = Jenc.encode 0 (encodeTest r)

convertToString : Convert -> String
convertToString r = Jenc.encode 0 (encodeConvert r)

test : Jdec.Decoder Test
test =
    Jpipe.decode Test
        |> Jpipe.required "asdf" Jdec.string
        |> Jpipe.required "asdf2" Jdec.string

encodeTest : Test -> Jenc.Value
encodeTest x =
    Jenc.object
        [ ("asdf", Jenc.string x.asdf)
        , ("asdf2", Jenc.string x.asdf2)
        ]

convert : Jdec.Decoder Convert
convert =
    Jpipe.decode Convert

encodeConvert : Convert -> Jenc.Value
encodeConvert x =
    Jenc.object
        [
        ]

--- encoder helpers

makeArrayEncoder : (a -> Jenc.Value) -> Array a -> Jenc.Value
makeArrayEncoder f arr =
    Jenc.array (Array.map f arr)

makeDictEncoder : (a -> Jenc.Value) -> Dict String a -> Jenc.Value
makeDictEncoder f dict =
    Jenc.object (toList (Dict.map (\k -> f) dict))

makeNullableEncoder : (a -> Jenc.Value) -> Maybe a -> Jenc.Value
makeNullableEncoder f m =
    case m of
    Just x -> f x
    Nothing -> Jenc.null
