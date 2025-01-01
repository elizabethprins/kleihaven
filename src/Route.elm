module Route exposing
    ( Page(..)
    , allPages
    , parser
    , toLabel
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


toLabel : Page -> String
toLabel page =
    case page of
        Home ->
            "Home"

        Kleihaven ->
            "Kleihaven"

        NotFound ->
            "Not Found"
