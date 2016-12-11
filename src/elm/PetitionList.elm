module PetitionList exposing
    ( PetitionList
    , Item
    , add
    , remove
    , member
    , fromJson
    , toJson
    )


import Json.Decode exposing ((:=))
import Json.Encode


type alias Item =
    { url : String
    , title : String
    }


type alias PetitionList = List Item


-- TODO: This should be configurable by the caller.
maxLength : Int
maxLength =
    6


itemDecoder : Json.Decode.Decoder Item
itemDecoder =
    Json.Decode.object2 Item
        ("url" := Json.Decode.string)
        ("title" := Json.Decode.string)


itemEncoder : Item -> Json.Encode.Value
itemEncoder item =
    Json.Encode.object
        [ ("url", Json.Encode.string item.url)
        , ("title", Json.Encode.string item.title)
        ]


fromJson : String -> PetitionList
fromJson json =
    json
        |> Json.Decode.decodeString (Json.Decode.list itemDecoder)
        |> Result.map (List.take maxLength)
        |> Result.withDefault []


toJson : PetitionList -> String
toJson plist =
    plist
        |> List.map itemEncoder
        |> Json.Encode.list
        |> Json.Encode.encode 0


member : Item -> PetitionList -> Bool
member item plist =
    plist
        |> List.any (.url >> (==) item.url)


add : Item -> PetitionList -> PetitionList
add item plist =
    plist
        |> remove item
        |> (::) item
        |> List.take maxLength


remove : Item -> PetitionList -> PetitionList
remove item plist =
    plist
        |> List.filter (.url >> (/=) item.url)
