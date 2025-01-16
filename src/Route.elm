module Route exposing
    ( Page(..)
    , allPages
    , toLabel
    , toPage
    , toUrl
    )

import Url exposing (Url)
import Url.Builder
import Url.Parser as Parser



-- URL HANDLING


type Page
    = Home
    | Kleihaven
    | Cursussen
    | OverOns
    | AIR
    | NotFound


allPages : List Page
allPages =
    [ Kleihaven
    , Cursussen
    , AIR
    , OverOns
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
        , Parser.map Cursussen (Parser.s "cursussen")
        , Parser.map OverOns (Parser.s "over-ons")
        , Parser.map AIR (Parser.s "air")
        ]


toUrl : Page -> String
toUrl page =
    case page of
        Home ->
            Url.Builder.absolute [ "" ] []

        Kleihaven ->
            Url.Builder.absolute [ "kleihaven", "" ] []

        NotFound ->
            Url.Builder.absolute [ "notfound", "" ] []

        Cursussen ->
            Url.Builder.absolute [ "cursussen", "" ] []

        OverOns ->
            Url.Builder.absolute [ "over-ons", "" ] []

        AIR ->
            Url.Builder.absolute [ "air", "" ] []


toLabel : Page -> String
toLabel page =
    case page of
        Home ->
            "Home"

        Kleihaven ->
            "Kleihaven"

        NotFound ->
            ""

        Cursussen ->
            "Cursussen"

        OverOns ->
            "Over Ons"

        AIR ->
            "AIR Programma's"
