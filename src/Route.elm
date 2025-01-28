module Route exposing
    ( Page(..)
    , allPages
    , toLabel
    , toPage
    , toUrl
    )

import Id exposing (CourseId)
import Url exposing (Url)
import Url.Builder
import Url.Parser as Parser exposing ((</>), (<?>))
import Url.Parser.Query



-- URL HANDLING


type Page
    = Home
    | Kleihaven
    | Cursussen (Maybe CourseId)
    | OverOns
    | AIR
    | Privacy
    | FAQ
    | Terms
    | BookingConfirmation (Maybe String)
    | NotFound


allPages : List Page
allPages =
    [ Kleihaven
    , Cursussen Nothing
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
        , Parser.map
            (\str ->
                case str of
                    Just courseId ->
                        Cursussen (Just (Id.fromString courseId))

                    Nothing ->
                        Cursussen Nothing
            )
            (Parser.s "cursussen" <?> Url.Parser.Query.string "id")
        , Parser.map OverOns (Parser.s "over-ons")
        , Parser.map AIR (Parser.s "air")
        , Parser.map Privacy (Parser.s "privacy")
        , Parser.map FAQ (Parser.s "veelgestelde-vragen")
        , Parser.map Terms (Parser.s "algemene-voorwaarden")
        , Parser.map
            (\str ->
                case str of
                    Just paymentId ->
                        BookingConfirmation (Just paymentId)

                    Nothing ->
                        NotFound
            )
            (Parser.s "boeking" </> Parser.s "bevestiging" <?> Url.Parser.Query.string "id")
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

        Cursussen maybeCourseId ->
            case maybeCourseId of
                Just courseId ->
                    Url.Builder.absolute [ "cursussen" ] [ Url.Builder.string "id" (Id.toCourseId courseId) ]

                Nothing ->
                    Url.Builder.absolute [ "cursussen", "" ] []

        OverOns ->
            Url.Builder.absolute [ "over-ons", "" ] []

        AIR ->
            Url.Builder.absolute [ "air", "" ] []

        Privacy ->
            Url.Builder.absolute [ "privacy", "" ] []

        FAQ ->
            Url.Builder.absolute [ "veelgestelde-vragen", "" ] []

        Terms ->
            Url.Builder.absolute [ "algemene-voorwaarden", "" ] []

        BookingConfirmation maybePaymentId ->
            case maybePaymentId of
                Just paymentId ->
                    Url.Builder.absolute [ "boeking", "bevestiging" ] [ Url.Builder.string "id" paymentId ]

                Nothing ->
                    Url.Builder.absolute [ "boeking", "bevestiging" ] []


toLabel : Page -> String
toLabel page =
    case page of
        Home ->
            "Home"

        Kleihaven ->
            "Kleihaven"

        NotFound ->
            ""

        Cursussen _ ->
            "Cursussen"

        OverOns ->
            "Over Ons"

        AIR ->
            "AIR Programma's"

        Privacy ->
            "Privacy Policy"

        FAQ ->
            "Veelgestelde Vragen"

        Terms ->
            "Algemene Voorwaarden"

        BookingConfirmation _ ->
            "Bevestiging"
