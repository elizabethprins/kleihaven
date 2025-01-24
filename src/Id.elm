module Id exposing
    ( CourseId
    , PeriodId
    , fromJson
    , fromString
    , fromUrl
    , toCourseId
    , toJson
    , toPeriodId
    , toString
    )

import Json.Decode as Decode
import Json.Encode as Encode
import Url.Parser as Parser


type Id a
    = Id String


type alias CourseId =
    Id { course : () }


type alias PeriodId =
    Id { period : () }


toCourseId : CourseId -> String
toCourseId (Id id) =
    id


toPeriodId : PeriodId -> String
toPeriodId (Id id) =
    id



-- CONVERSIONS


toString : Id a -> String
toString (Id id) =
    id


fromUrl : Parser.Parser (Id b -> a) a
fromUrl =
    Parser.map Id Parser.string


fromJson : Decode.Decoder (Id a)
fromJson =
    Decode.map Id Decode.string


fromString : String -> Id a
fromString id =
    Id id


toJson : Id a -> Encode.Value
toJson (Id id) =
    Encode.string id
