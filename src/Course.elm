module Course exposing
    ( BookingError
    , BookingResponse
    , BookingResponseError(..)
    , Course
    , CoursePeriod
    , PaymentDetails
    , PaymentStatus
    , RegistrationModal
    , ValidationErrors
    , bookingErrorToString
    , createBooking
    , emptyValidationErrors
    , fetchCourses
    , fetchPaymentDetails
    , validateRegistration
    , viewBookingConfirmation
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Id exposing (BookingId, CourseId, PeriodId)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Parser exposing ((|.), Parser)
import Route
import Ui.Button


type alias Course =
    { id : CourseId
    , title : String
    , description : String
    , content : Maybe String
    , imageUrl : String
    , price : Float
    , periods : List CoursePeriod
    }


type alias CoursePeriod =
    { id : PeriodId
    , startDate : String
    , endDate : String
    , timeInfo : Maybe String
    , availableSpots : Int
    }


type alias RegistrationModal =
    { course : Course
    , period : CoursePeriod
    , name : String
    , email : String
    , spots : Int
    , errors : ValidationErrors
    , bookingError : Maybe String
    , submitting : Bool
    }


type alias ValidationErrors =
    { name : Maybe String
    , email : Maybe String
    , spots : Maybe String
    }


emptyValidationErrors : ValidationErrors
emptyValidationErrors =
    { name = Nothing
    , email = Nothing
    , spots = Nothing
    }


type PaymentStatus
    = Open
    | Canceled
    | Pending
    | Expired
    | Failed
    | Paid
    | Authorized


type alias PaymentDetails =
    { status : PaymentStatus
    , paymentId : String
    , amount : { value : String, currency : String }
    , metadata :
        { courseId : CourseId
        , periodId : PeriodId
        , email : String
        , name : String
        , numberOfSpots : Int
        }
    , description : String
    }


type BookingError
    = SpotsNotAvailable
    | PeriodNotFound
    | PaymentConfigError
    | UnknownError String


type alias BookingResponse =
    { success : Bool
    , paymentUrl : String
    , error : Maybe BookingError
    }


type BookingResponseError
    = Error BookingError
    | HttpError Http.Error



-- VIEW


viewBookingConfirmation :
    { loadingPayment : Bool
    , paymentDetails : Maybe PaymentDetails
    }
    -> List (Html msg)
viewBookingConfirmation model =
    if model.loadingPayment then
        [ div [ class "centered" ]
            [ div [ class "loading-spinner" ] [] ]
        ]

    else
        case model.paymentDetails of
            Nothing ->
                [ div [ class "content" ]
                    [ h1 [] [ text "Betaling niet gevonden" ]
                    , p [] [ text "Er is geen betaling gevonden. Ga terug naar de cursussen en probeer het opnieuw." ]
                    , Ui.Button.newPrimary
                        { label = "Terug naar cursussen"
                        , action = Ui.Button.ToPage (Route.Cursussen Nothing)
                        }
                        |> Ui.Button.view
                    ]
                ]

            Just payment ->
                [ div [ class "content" ] <|
                    case payment.status of
                        Paid ->
                            [ h1 [] [ text "Bedankt voor je boeking!" ]
                            , p [] [ text ("We hebben je betaling ontvangen voor " ++ payment.description) ]
                            , p [] [ text ("Er is een bevestigingsmail verstuurd naar " ++ payment.metadata.email) ]
                            ]

                        Open ->
                            [ h1 [] [ text "Betaling gestart" ]
                            , p [] [ text "Je wordt doorgestuurd naar je bank om de betaling af te ronden." ]
                            , p [] [ text "Na succesvolle betaling ontvang je een bevestigingsmail." ]
                            ]

                        Pending ->
                            [ h1 [] [ text "Betaling in behandeling" ]
                            , p [] [ text "Je betaling wordt verwerkt door de bank." ]
                            , p [] [ text "Zodra de betaling is gelukt sturen we je een bevestigingsmail." ]
                            , p [] [ text "Je kunt deze pagina veilig sluiten." ]
                            ]

                        Failed ->
                            [ h1 [] [ text "Betaling mislukt" ]
                            , p [] [ text "Er is helaas iets misgegaan met je betaling. Probeer het opnieuw." ]
                            , Ui.Button.newPrimary
                                { label = "Terug naar cursussen"
                                , action = Ui.Button.ToPage (Route.Cursussen Nothing)
                                }
                                |> Ui.Button.view
                            ]

                        Canceled ->
                            [ h1 [] [ text "Betaling geannuleerd" ]
                            , p [] [ text "Je hebt de betaling geannuleerd." ]
                            , Ui.Button.newPrimary
                                { label = "Terug naar cursussen"
                                , action = Ui.Button.ToPage (Route.Cursussen Nothing)
                                }
                                |> Ui.Button.view
                            ]

                        Expired ->
                            [ h1 [] [ text "Betaling verlopen" ]
                            , p [] [ text "De betalingstermijn is verlopen. Maak een nieuwe boeking." ]
                            , Ui.Button.newPrimary
                                { label = "Terug naar cursussen"
                                , action = Ui.Button.ToPage (Route.Cursussen Nothing)
                                }
                                |> Ui.Button.view
                            ]

                        Authorized ->
                            [ h1 [] [ text "Betaling geautoriseerd" ]
                            , p [] [ text "Je betaling is geautoriseerd en wordt verwerkt." ]
                            , p [] [ text "Zodra de betaling is afgerond sturen we je een bevestigingsmail." ]
                            ]
                ]



-- VALIDATION


validateRegistration : RegistrationModal -> ValidationErrors
validateRegistration modal =
    { name =
        if String.isEmpty (String.trim modal.name) then
            Just "Naam is verplicht"

        else
            Nothing
    , email =
        if String.isEmpty (String.trim modal.email) then
            Just "E-mail is verplicht"

        else if not (isValidEmail modal.email) then
            Just "Vul een geldig e-mailadres in"

        else
            Nothing
    , spots =
        if modal.spots < 1 then
            Just "Kies minimaal 1 plek"

        else
            Nothing
    }


isValidEmail : String -> Bool
isValidEmail email =
    email
        |> String.trim
        |> Parser.run emailParser
        |> Result.map (always True)
        |> Result.withDefault False


emailParser : Parser ()
emailParser =
    let
        localPart =
            Parser.succeed ()
                |. Parser.chompIf (\c -> Char.isAlphaNum c || List.member c [ '.', '_', '-', '+' ])
                |. Parser.chompWhile (\c -> Char.isAlphaNum c || List.member c [ '.', '_', '-', '+' ])

        domainPart =
            Parser.succeed ()
                |. Parser.chompIf Char.isAlphaNum
                |. Parser.chompWhile (\c -> Char.isAlphaNum c || c == '-')
                |. Parser.symbol "."
                |. Parser.chompIf Char.isAlpha
                |. Parser.chompWhile Char.isAlpha
    in
    Parser.succeed ()
        |. localPart
        |. Parser.symbol "@"
        |. domainPart
        |. Parser.end



-- HTTP


fetchCourses : String -> (Result Http.Error (List Course) -> msg) -> Cmd msg
fetchCourses apiBaseUrl gotCourses =
    Http.get
        { url = apiBaseUrl ++ "/.netlify/functions/fetchCourses"
        , expect = Http.expectJson gotCourses coursesDecoder
        }


createBooking : String -> RegistrationModal -> (Result BookingResponseError BookingResponse -> msg) -> Cmd msg
createBooking apiBaseUrl modal gotBookingResponse =
    Http.post
        { url = apiBaseUrl ++ "/.netlify/functions/createBooking"
        , body = Http.jsonBody (bookingEncoder modal)
        , expect = expectJsonWithError gotBookingResponse bookingResponseDecoder bookingErrorDecoder
        }


fetchPaymentDetails : String -> BookingId -> (Result Http.Error PaymentDetails -> msg) -> Cmd msg
fetchPaymentDetails apiBaseUrl paymentId gotPaymentDetails =
    Http.get
        { url = apiBaseUrl ++ "/.netlify/functions/getPaymentStatus?id=" ++ Id.toBookingId paymentId
        , expect = Http.expectJson gotPaymentDetails paymentDetailsDecoder
        }


expectJsonWithError : (Result BookingResponseError a -> msg) -> Decode.Decoder a -> Decode.Decoder BookingError -> Http.Expect msg
expectJsonWithError toMsg decoder errorDecoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (HttpError (Http.BadUrl url))

                Http.Timeout_ ->
                    Err (HttpError Http.Timeout)

                Http.NetworkError_ ->
                    Err (HttpError Http.NetworkError)

                Http.BadStatus_ metadata body ->
                    case Decode.decodeString errorDecoder body of
                        Ok bookingError ->
                            Err (Error bookingError)

                        Err _ ->
                            Err (HttpError (Http.BadStatus metadata.statusCode))

                Http.GoodStatus_ _ body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (HttpError (Http.BadBody (Decode.errorToString err)))



-- DECODERS


coursesDecoder : Decode.Decoder (List Course)
coursesDecoder =
    Decode.field "data"
        (Decode.field "data"
            (Decode.list courseDecoder)
        )


courseDecoder : Decode.Decoder Course
courseDecoder =
    Decode.succeed Course
        |> Pipeline.required "id" Id.fromJson
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "description" Decode.string
        |> Pipeline.optional "content" (Decode.maybe Decode.string) Nothing
        |> Pipeline.required "imageUrl" Decode.string
        |> Pipeline.required "price"
            (Decode.string
                |> Decode.map String.toFloat
                |> Decode.map (Maybe.withDefault 0)
            )
        |> Pipeline.required "periods" (Decode.list coursePeriodDecoder)


coursePeriodDecoder : Decode.Decoder CoursePeriod
coursePeriodDecoder =
    Decode.succeed CoursePeriod
        |> Pipeline.required "id" Id.fromJson
        |> Pipeline.required "startDate" Decode.string
        |> Pipeline.required "endDate" Decode.string
        |> Pipeline.optional "timeInfo" (Decode.maybe Decode.string) Nothing
        |> Pipeline.custom
            (Decode.map2 (\total booked -> total - booked)
                (Decode.field "totalSpots" Decode.int)
                (Decode.field "bookedSpots" Decode.int)
            )


bookingResponseDecoder : Decode.Decoder BookingResponse
bookingResponseDecoder =
    Decode.succeed BookingResponse
        |> Pipeline.required "success" Decode.bool
        |> Pipeline.required "paymentUrl" Decode.string
        |> Pipeline.optional "error" (Decode.map Just bookingErrorDecoder) Nothing


bookingErrorDecoder : Decode.Decoder BookingError
bookingErrorDecoder =
    Decode.field "error" Decode.string
        |> Decode.andThen
            (\errorCode ->
                case errorCode of
                    "PERIOD_NOT_FOUND" ->
                        Decode.succeed PeriodNotFound

                    "SPOTS_NOT_AVAILABLE" ->
                        Decode.succeed SpotsNotAvailable

                    "PAYMENT_CONFIG_ERROR" ->
                        Decode.succeed PaymentConfigError

                    _ ->
                        Decode.field "message" Decode.string
                            |> Decode.map UnknownError
            )


paymentDetailsDecoder : Decode.Decoder PaymentDetails
paymentDetailsDecoder =
    Decode.succeed PaymentDetails
        |> Pipeline.required "status" (Decode.string |> Decode.map paymentStatusFromString)
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "amount"
            (Decode.map2 (\v c -> { value = v, currency = c })
                (Decode.field "value" Decode.string)
                (Decode.field "currency" Decode.string)
            )
        |> Pipeline.required "metadata"
            (Decode.succeed
                (\courseId periodId email name spots ->
                    { courseId = courseId
                    , periodId = periodId
                    , email = email
                    , name = name
                    , numberOfSpots = spots
                    }
                )
                |> Pipeline.required "courseId" Id.fromJson
                |> Pipeline.required "periodId" Id.fromJson
                |> Pipeline.required "email" Decode.string
                |> Pipeline.required "name" Decode.string
                |> Pipeline.required "numberOfSpots" Decode.int
            )
        |> Pipeline.required "description" Decode.string



-- ENCODERS


bookingEncoder : RegistrationModal -> Encode.Value
bookingEncoder modal =
    Encode.object
        [ ( "courseId", Encode.string (Id.toString modal.course.id) )
        , ( "periodId", Encode.string (Id.toString modal.period.id) )
        , ( "email", Encode.string (String.trim modal.email) )
        , ( "name", Encode.string (String.trim modal.name) )
        , ( "numberOfSpots", Encode.int modal.spots )
        ]



-- HELPERS


bookingErrorToString : BookingError -> String
bookingErrorToString error =
    case error of
        SpotsNotAvailable ->
            "Er zijn niet genoeg plekken meer beschikbaar. Ververs de pagina om het actuele aantal te zien. Mogelijk zitten deze plekken in het winkelmandje van een andere bezoeker. Probeer het dan later opnieuw."

        PeriodNotFound ->
            "De gekozen cursusperiode bestaat niet meer. Ververs de pagina om de beschikbare periodes te zien."

        PaymentConfigError ->
            "Er is een probleem met de betalingsconfiguratie. Probeer het later opnieuw of neem contact met ons op."

        UnknownError message ->
            "Er is iets misgegaan: " ++ message


paymentStatusFromString : String -> PaymentStatus
paymentStatusFromString str =
    case str of
        "open" ->
            Open

        "canceled" ->
            Canceled

        "pending" ->
            Pending

        "expired" ->
            Expired

        "failed" ->
            Failed

        "paid" ->
            Paid

        "authorized" ->
            Authorized

        _ ->
            Failed
