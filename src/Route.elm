module Route exposing
    ( MetaTags
    , Page(..)
    , allPages
    , parser
    , toMetaTags
    , toPage
    , toUrl
    )

import Url exposing (Url)
import Url.Builder
import Url.Parser as Parser exposing ((</>), s)



-- URL HANDLING


type Page
    = Home
    | Kleihaven
    | NotFound


allPages : List Page
allPages =
    [ Home
    , Kleihaven
    , NotFound
    ]


toPage : Url -> Page
toPage url =
    url
        |> Parser.parse parser
        |> Maybe.withDefault NotFound


parser : Parser.Parser (Page -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Kleihaven (Parser.s "kleihaven")
        ]


toUrl : Page -> String
toUrl page =
    case page of
        Home ->
            Url.Builder.absolute [] []

        Kleihaven ->
            Url.Builder.absolute [ "kleihaven" ] []

        NotFound ->
            Url.Builder.absolute [ "notfound" ] []



-- META TAGS


type alias MetaTags =
    { title : String
    , description : String
    , image : String
    , url : String
    }


toMetaTags : Url -> MetaTags
toMetaTags url =
    case toPage url of
        Home ->
            { title = "Kleihaven"
            , description = "Welkom bij de Kleihaven! Wij bieden keramiekcursussen van enkele dagen tot twee volle weken."
            , image = Url.Builder.absolute [ "assets", "1-IMG_3548.jpeg" ] []
            , url = toUrl Home
            }

        Kleihaven ->
            { title = "Kleihaven"
            , description = "Welkom bij de Kleihaven! Wij bieden keramiekcursussen van enkele dagen tot twee volle weken."
            , image = Url.Builder.absolute [ "assets", "1-IMG_3548.jpeg" ] []
            , url = toUrl Kleihaven
            }

        NotFound ->
            { title = "Studio 1931"
            , description = "Welkom bij de Kleihaven! Wij bieden keramiekcursussen van enkele dagen tot twee volle weken."
            , image = Url.Builder.absolute [ "assets", "1-IMG_3548.jpeg" ] []
            , url = toUrl Home
            }
