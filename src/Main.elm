port module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Navigation as Navigation
import Copy exposing (copy)
import Course exposing (Course)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, preventDefaultOn)
import Html.Keyed
import Html.Parser
import Html.Parser.Util
import Http
import Id exposing (CourseId)
import Json.Decode as Decode
import Route
import Set exposing (Set)
import Task
import Ui.Button
import Ui.Date
import Ui.FormField
import Ui.Icons.Facebook
import Ui.Icons.Instagram
import Url exposing (Url)



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = UrlChanged
        }


port urlChanged : String -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MODEL


type alias Flags =
    { apiBaseUrl : String }


type alias Model =
    { navKey : Navigation.Key
    , apiBaseUrl : String
    , page : Route.Page
    , loadedImages : Set String
    , mobileMenuOpen : Bool
    , courses : List Course
    , loadingCourses : Bool
    , currentCourse : Maybe Course
    , error : Maybe Http.Error
    , registrationModal : Maybe Course.RegistrationModal
    , paymentDetails : Maybe Course.PaymentDetails
    , loadingPayment : Bool
    }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialPage =
            Route.toPage url

        initialCmd =
            case initialPage of
                Route.BookingConfirmation (Just paymentId) ->
                    Course.fetchPaymentDetails flags.apiBaseUrl paymentId GotPaymentDetails

                _ ->
                    if isPageCursussen initialPage then
                        Course.fetchCourses flags.apiBaseUrl GotCourses

                    else
                        Cmd.none
    in
    ( { navKey = key
      , apiBaseUrl = flags.apiBaseUrl
      , page = initialPage
      , loadedImages = Set.empty
      , mobileMenuOpen = False
      , courses = []
      , loadingCourses = isPageCursussen initialPage
      , currentCourse = Nothing
      , error = Nothing
      , registrationModal = Nothing
      , paymentDetails = Nothing
      , loadingPayment = isBookingConfirmationPage initialPage
      }
    , initialCmd
    )


isPageCursussen : Route.Page -> Bool
isPageCursussen page =
    case page of
        Route.Cursussen _ ->
            True

        _ ->
            False


isBookingConfirmationPage : Route.Page -> Bool
isBookingConfirmationPage page =
    case page of
        Route.BookingConfirmation _ ->
            True

        _ ->
            False



-- UPDATE


type Msg
    = NoOp
    | ClickedLink Browser.UrlRequest
    | UrlChanged Url
    | ImageLoaded String
    | ToggleMobileMenu
    | GotCourses (Result Http.Error (List Course))
    | OpenRegistrationModal Course Course.CoursePeriod
    | CloseRegistrationModal
    | CloseRegistrationAndOpenCourse CourseId
    | UpdateRegistrationName String
    | UpdateRegistrationEmail String
    | UpdateRegistrationSpots String
    | SubmitRegistration
    | GotBookingResponse (Result Course.BookingResponseError Course.BookingResponse)
    | CloseCourseDetailModal
    | GotPaymentDetails (Result Http.Error Course.PaymentDetails)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ClickedLink request ->
            case request of
                Browser.Internal url ->
                    ( model
                    , Cmd.batch
                        [ Navigation.pushUrl model.navKey (Url.toString url)
                        , Browser.Dom.setViewport 0 0
                            |> Task.perform (always NoOp)
                        ]
                    )

                Browser.External url ->
                    ( model
                    , Navigation.load url
                    )

        UrlChanged url ->
            let
                page =
                    Route.toPage url

                newModel =
                    { model
                        | page = page
                        , mobileMenuOpen = False
                    }

                newCmd =
                    urlChanged (Route.toUrl <| Route.toPage url)
            in
            if page == model.page then
                ( newModel, Cmd.none )

            else
                case page of
                    Route.Cursussen maybeCourseId ->
                        let
                            shouldFetchCourses =
                                not (isPageCursussen model.page)

                            staysOnPageCursussen =
                                isPageCursussen model.page
                        in
                        ( { newModel
                            | loadingCourses = shouldFetchCourses
                            , currentCourse =
                                maybeCourseId
                                    |> Maybe.andThen
                                        (\courseId ->
                                            List.filter (.id >> (==) courseId) model.courses
                                                |> List.head
                                        )
                            , loadedImages =
                                if staysOnPageCursussen then
                                    model.loadedImages

                                else
                                    Set.empty
                          }
                        , Cmd.batch
                            [ newCmd
                            , if shouldFetchCourses then
                                Course.fetchCourses model.apiBaseUrl GotCourses

                              else
                                Cmd.none
                            ]
                        )

                    Route.BookingConfirmation (Just paymentId) ->
                        ( { newModel
                            | loadingPayment = True
                          }
                        , Cmd.batch
                            [ newCmd
                            , Course.fetchPaymentDetails model.apiBaseUrl paymentId GotPaymentDetails
                            ]
                        )

                    _ ->
                        ( newModel, newCmd )

        ImageLoaded src ->
            ( { model | loadedImages = Set.insert src model.loadedImages }
            , Cmd.none
            )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        GotCourses result ->
            case result of
                Ok courses ->
                    ( { model
                        | courses = courses
                        , loadingCourses = False
                        , currentCourse =
                            case model.page of
                                Route.Cursussen (Just courseId) ->
                                    List.filter (.id >> (==) courseId) courses
                                        |> List.head

                                _ ->
                                    Nothing
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loadingCourses = False
                        , error = Just error
                      }
                    , Cmd.none
                    )

        OpenRegistrationModal course period ->
            ( { model
                | registrationModal =
                    Just
                        { course = course
                        , period = period
                        , name = ""
                        , email = ""
                        , spots = 1
                        , errors = Course.emptyValidationErrors
                        , submitting = False
                        , bookingError = Nothing
                        }
              }
            , Cmd.none
            )

        CloseRegistrationModal ->
            ( { model | registrationModal = Nothing }, Cmd.none )

        CloseRegistrationAndOpenCourse courseId ->
            ( { model | registrationModal = Nothing }
            , Navigation.pushUrl model.navKey (Route.toUrl (Route.Cursussen (Just courseId)))
            )

        UpdateRegistrationName name ->
            ( { model
                | registrationModal = Maybe.map (\m -> { m | name = name }) model.registrationModal
              }
            , Cmd.none
            )

        UpdateRegistrationEmail email ->
            ( { model
                | registrationModal = Maybe.map (\m -> { m | email = email }) model.registrationModal
              }
            , Cmd.none
            )

        UpdateRegistrationSpots spotsStr ->
            ( { model
                | registrationModal =
                    Maybe.map
                        (\m ->
                            { m
                                | spots =
                                    String.toInt spotsStr
                                        |> Maybe.withDefault m.spots
                                        |> clamp 1 10
                            }
                        )
                        model.registrationModal
              }
            , Cmd.none
            )

        SubmitRegistration ->
            case model.registrationModal of
                Nothing ->
                    ( model, Cmd.none )

                Just modal ->
                    let
                        validationErrors =
                            Course.validateRegistration modal

                        hasErrors =
                            validationErrors.name
                                /= Nothing
                                || validationErrors.email
                                /= Nothing
                                || validationErrors.spots
                                /= Nothing
                    in
                    if hasErrors then
                        ( { model
                            | registrationModal =
                                Just
                                    { modal
                                        | errors = validationErrors
                                        , bookingError = Nothing
                                    }
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | registrationModal =
                                Just
                                    { modal
                                        | errors = Course.emptyValidationErrors
                                        , submitting = True
                                        , bookingError = Nothing
                                    }
                          }
                        , Course.createBooking model.apiBaseUrl modal GotBookingResponse
                        )

        GotBookingResponse result ->
            case result of
                Ok response ->
                    if response.success then
                        ( { model
                            | registrationModal =
                                model.registrationModal
                                    |> Maybe.map (\m -> { m | submitting = False })
                          }
                        , Navigation.load response.paymentUrl
                        )

                    else
                        ( { model
                            | registrationModal =
                                model.registrationModal
                                    |> Maybe.map
                                        (\m ->
                                            { m
                                                | submitting = False
                                                , bookingError = Maybe.map Course.bookingErrorToString response.error
                                            }
                                        )
                          }
                        , Cmd.none
                        )

                Err error ->
                    let
                        errorMessage =
                            case error of
                                Course.Error bookingError ->
                                    Course.bookingErrorToString bookingError

                                Course.HttpError httpError ->
                                    case httpError of
                                        Http.NetworkError ->
                                            "Kan geen verbinding maken. Controleer je internetverbinding."

                                        Http.Timeout ->
                                            "De verbinding is verlopen. Probeer het opnieuw."

                                        _ ->
                                            "Er is iets misgegaan. Probeer het later opnieuw."
                    in
                    ( { model
                        | registrationModal =
                            model.registrationModal
                                |> Maybe.map
                                    (\m ->
                                        { m
                                            | submitting = False
                                            , bookingError = Just errorMessage
                                        }
                                    )
                      }
                    , Cmd.none
                    )

        CloseCourseDetailModal ->
            ( model
            , Navigation.pushUrl model.navKey (Route.toUrl (Route.Cursussen Nothing))
            )

        GotPaymentDetails result ->
            case result of
                Ok details ->
                    ( { model
                        | paymentDetails = Just details
                        , loadingPayment = False
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | loadingPayment = False }
                    , Cmd.none
                    )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = copy.title
    , body =
        [ viewNavigation model
        , main_ [ class "main" ] <|
            case model.page of
                Route.Home ->
                    viewPageHome model

                Route.Kleihaven ->
                    viewPageKleihaven model

                Route.Cursussen maybeCourseId ->
                    viewPageCursussen model maybeCourseId

                Route.AIR ->
                    viewPageAIR model

                Route.OverOns ->
                    viewPageOverOns

                Route.Privacy ->
                    viewPagePrivacy

                Route.FAQ ->
                    viewPageFAQ

                Route.Terms ->
                    viewPageTerms

                Route.NotFound ->
                    viewPageNotFound

                Route.BookingConfirmation _ ->
                    Course.viewBookingConfirmation
                        { loadingPayment = model.loadingPayment
                        , paymentDetails = model.paymentDetails
                        }
        , viewFooter model
        , viewRegistrationModal model.registrationModal model.currentCourse
        ]
    }


viewNavigation : Model -> Html Msg
viewNavigation model =
    let
        viewLogo =
            a [ class "logo", title "Studio 1931", href (Route.toUrl Route.Home) ]
                [ img
                    [ src "/assets/logostudio1931-small.png"
                    , alt "Studio 1931"
                    ]
                    []
                ]

        viewMenuItem page =
            li []
                [ Ui.Button.newLink
                    { label = Route.toLabel page
                    , action = Ui.Button.ToPage page
                    }
                    |> Ui.Button.view
                ]

        hamburgerButton =
            button
                [ class "hamburger"
                , onClick ToggleMobileMenu
                ]
                [ span [ class "hamburger-line" ] []
                , span [ class "hamburger-line" ] []
                , span [ class "hamburger-line" ] []
                ]
    in
    header
        [ classList
            [ ( "header", True )
            , ( "nav--open", model.mobileMenuOpen )
            ]
        ]
        [ div [ class "header__inner" ]
            [ viewLogo
            , hamburgerButton
            , nav [ class "nav" ]
                [ ul []
                    (List.map viewMenuItem Route.allPages)
                ]
            ]
        ]


viewFooter : Model -> Html Msg
viewFooter model =
    let
        footerPages =
            [ Route.Privacy
            , Route.FAQ
            , Route.Terms
            ]
    in
    footer [ class "footer" ]
        [ div [ class "footer__top" ]
            [ div [ class "footer__section" ]
                [ h4 [] [ text "Volg ons" ]
                , div [ class "footer__social" ]
                    [ a
                        [ href "https://instagram.com/studio.1931"
                        , target "_blank"
                        , rel "noopener noreferrer"
                        ]
                        [ Ui.Icons.Instagram.view
                        , span [ class "visually-hidden" ] [ text "Instagram" ]
                        ]
                    , a
                        [ href "https://facebook.com/studio.1931"
                        , target "_blank"
                        , rel "noopener noreferrer"
                        ]
                        [ Ui.Icons.Facebook.view
                        , span [ class "visually-hidden" ] [ text "Facebook" ]
                        ]
                    ]
                ]
            , div [ class "footer__section" ]
                [ h4 [] [ text "Contact" ]
                , address []
                    [ text "Studio1931"
                    , br [] []
                    , a
                        [ href "https://maps.app.goo.gl/STQx8Low2n1sw4267"
                        , target "_blank"
                        , rel "noopener noreferrer"
                        ]
                        [ text "Zwinstraat 66"
                        , br [] []
                        , text "1779 BH Den Oever"
                        ]
                    , br [] []
                    , a [ href "mailto:info@studio1931.nl" ] [ text "info@studio1931.nl" ]
                    ]
                ]
            , div [ class "footer__section" ]
                [ h4 [] [ text "Informatie" ]
                , footerPages
                    |> List.map
                        (\page ->
                            li []
                                [ Ui.Button.newLink
                                    { label = Route.toLabel page
                                    , action = Ui.Button.ToPage page
                                    }
                                    |> Ui.Button.view
                                ]
                        )
                    |> ul []
                ]
            ]
        , div [ class "footer__bottom" ]
            [ p [] [ text "© 2025 Studio1931. Alle rechten voorbehouden." ] ]
        ]



-- PAGE HELPERS


toContentPage : List (Html Msg) -> List (Html Msg)
toContentPage content =
    [ article [ class "content" ] content ]


viewIntro :
    Model
    -> { title : String, subtitle : String, intro : String, coursesButton : String }
    -> List ImgProps
    -> Html Msg
viewIntro model content imgProps =
    section [ class "intro" ]
        [ div [ class "intro__left card" ]
            [ h1 [ class "intro__title" ]
                [ text content.title ]
            , h2 [ class "intro__subtitle" ]
                [ text content.subtitle ]
            , p [ class "intro__text" ]
                [ text content.intro ]
            , Ui.Button.newPrimary
                { label = content.coursesButton
                , action = Ui.Button.ToPage (Route.Cursussen Nothing)
                }
                |> Ui.Button.view
            ]
        , div [ class "intro__right" ] <|
            List.map (viewImageCard model.loadedImages) imgProps
        ]


viewImageCard : Set String -> ImgProps -> Html Msg
viewImageCard loadedImages imgProps =
    Html.Keyed.node "div"
        [ class "card-img" ]
        [ ( imgProps.imgSrc
          , viewImage loadedImages imgProps
          )
        ]


viewTextImageCard : Set String -> ImgProps -> { content : List (Html Msg), extraClass : String } -> Html Msg
viewTextImageCard loadedImages imgProps content =
    div [ class ("card-text-img " ++ content.extraClass) ]
        [ viewImage loadedImages imgProps
        , div [ class "card-text-img__content" ] content.content
        ]


type alias ImgProps =
    { -- the relative path of the image in the /assets folder, without the extension
      -- example: 9x16/keramiek-lokaal
      imgSrc : String
    , imgAlt : String
    , lazy : Bool
    }


type ImageFormat
    = JPG
    | AVIF
    | WEBP


viewImage : Set String -> ImgProps -> Html Msg
viewImage loadedImages { imgSrc, imgAlt, lazy } =
    let
        lazyAttr =
            if lazy then
                [ attribute "loading" "lazy" ]

            else
                []

        toSrc format src =
            case format of
                JPG ->
                    "/assets/" ++ src ++ ".jpg"

                AVIF ->
                    "/assets/avif/" ++ src ++ ".avif"

                WEBP ->
                    "/assets/webp/" ++ src ++ ".webp"
    in
    Html.node "picture"
        []
        [ source [ attribute "srcSet" (toSrc AVIF imgSrc), type_ "image/avif" ] []
        , source [ attribute "srcSet" (toSrc WEBP imgSrc), type_ "image/webp" ] []
        , img
            ([ src (toSrc JPG imgSrc)
             , alt imgAlt
             , classList [ ( "loading", not (Set.member imgSrc loadedImages) ) ]
             , on "load" (Decode.succeed (ImageLoaded imgSrc))
             ]
                ++ lazyAttr
            )
            []
        ]


viewIf : Bool -> Html msg -> Html msg
viewIf condition html =
    if condition then
        html

    else
        text ""


viewMaybe : Maybe a -> (a -> Html msg) -> Html msg
viewMaybe maybe toHtml =
    case maybe of
        Just value ->
            toHtml value

        Nothing ->
            text ""



-- VIEW PAGES
-- HOMEPAGE


viewPageHome : Model -> List (Html Msg)
viewPageHome model =
    [ viewHomeIntro model
    , viewHomeBlock
    , viewHomeBlockKleihaven
    , viewHomeBlockAIR model
    , viewHomeBlockOverOns model
    ]


viewHomeIntro : Model -> Html Msg
viewHomeIntro model =
    viewIntro model
        { title = copy.home.title
        , subtitle = copy.home.subtitle
        , intro = copy.home.intro
        , coursesButton = copy.home.coursesButton
        }
        [ { imgSrc = "9x16/huis-tuin"
          , imgAlt = "Huis en bloeiende tuin van Studio 1931"
          , lazy = False
          }
        , { imgSrc = "9x16/keramiek-lokaal"
          , imgAlt = "Keramiekwerkplaats met draaischijven"
          , lazy = False
          }
        ]


viewHomeBlock : Html Msg
viewHomeBlock =
    section [ class "block -extra-margin-top" ]
        [ div [ class "block__header" ]
            [ h2 []
                [ text copy.home.block.title ]
            , p []
                [ text copy.home.block.description ]
            ]
        ]


viewHomeBlockKleihaven : Html Msg
viewHomeBlockKleihaven =
    section [ class "block -reduce-margin-mobile" ]
        [ div [ class "block__cards -centerpiece" ]
            [ img
                [ src "/assets/klei-potje.png"
                , alt "Pot van klei"
                ]
                []
            , div [ class "card-text" ]
                [ div []
                    [ h2 [] [ text copy.home.blockKleihaven.title ]
                    , p [] [ text copy.home.blockKleihaven.description1 ]
                    , p [] [ text copy.home.blockKleihaven.description2 ]
                    , p [] [ text copy.home.blockKleihaven.description3 ]
                    , Ui.Button.newSecondary
                        { label = copy.home.blockKleihaven.readMore
                        , action = Ui.Button.ToPage Route.Kleihaven
                        }
                        |> Ui.Button.view
                    ]
                ]
            , img
                [ src "/assets/klei-masker-klein.png"
                , alt "Keramieken masker"
                ]
                []
            ]
        ]


viewHomeBlockAIR : Model -> Html Msg
viewHomeBlockAIR model =
    section [ class "block" ]
        [ div [ class "block__cards -two-cards" ]
            [ div [ class "card-text" ]
                [ h2 [] [ text copy.home.blockAIR.title ]
                , p [] [ text copy.home.blockAIR.description1 ]
                , p [] [ text copy.home.blockAIR.description2 ]
                , p [] [ text copy.home.blockAIR.description3 ]
                , Ui.Button.newSecondary
                    { label = copy.home.blockAIR.readMore
                    , action = Ui.Button.ToPage Route.AIR
                    }
                    |> Ui.Button.view
                ]
            , viewImageCard model.loadedImages
                { imgSrc = "air"
                , imgAlt = "Kunstenaars aan het werk in de studio"
                , lazy = True
                }
            ]
        ]


viewHomeBlockOverOns : Model -> Html Msg
viewHomeBlockOverOns model =
    section [ class "block" ]
        [ div [ class "block__cards -two-cards -img-left" ]
            [ viewImageCard model.loadedImages
                { imgSrc = "wieringen"
                , imgAlt = "Uitzicht over de Waddenzee vanaf voormalig eiland Wieringen"
                , lazy = True
                }
            , div [ class "card-text" ]
                [ h2 [] [ text copy.home.blockOverOns.title ]
                , p [] [ text copy.home.blockOverOns.description1 ]
                , p [] [ text copy.home.blockOverOns.description2 ]
                , p [] [ text copy.home.blockOverOns.description3 ]
                , Ui.Button.newSecondary
                    { label = copy.home.blockOverOns.readMore
                    , action = Ui.Button.ToPage Route.OverOns
                    }
                    |> Ui.Button.view
                ]
            ]
        ]



-- KLEIHAVEN PAGE


viewPageKleihaven : Model -> List (Html Msg)
viewPageKleihaven model =
    [ viewKleihavenIntro model
    , viewDivider
    , viewKleihavenBlock model
    , viewKleihavenBlockTwo
    , viewMobileCoursesButton
    ]


viewKleihavenIntro : Model -> Html Msg
viewKleihavenIntro model =
    viewIntro model
        { title = copy.kleihaven.title
        , subtitle = copy.kleihaven.subtitle
        , intro = copy.kleihaven.intro
        , coursesButton = copy.kleihaven.coursesButton
        }
        [ { imgSrc = "9x16/klei-barbara"
          , imgAlt = "Cursist aan het werk in de keramiekwerkplaats"
          , lazy = False
          }
        , { imgSrc = "9x16/potten-van-boven"
          , imgAlt = "Keramiekwerken van cursisten"
          , lazy = False
          }
        ]


viewDivider : Html msg
viewDivider =
    img [ src "/assets/trimmingtool.svg", class "divider-img" ] []


viewKleihavenBlock : Model -> Html Msg
viewKleihavenBlock model =
    let
        viewCard content =
            viewTextImageCard model.loadedImages
                { imgSrc = content.imgSrc
                , imgAlt = content.imgAlt
                , lazy = True
                }
                { content =
                    [ p []
                        [ text content.text ]
                    , p [ class "centered" ] [ text "☆" ]
                    , Ui.Button.secretLink
                        { label = copy.kleihaven.blockOne.viewCoursesButton
                        , action = Ui.Button.ToPage (Route.Cursussen Nothing)
                        }
                        |> Ui.Button.view
                    ]
                , extraClass = "-clickable"
                }
    in
    section [ class "block" ]
        [ div [ class "block__header" ]
            [ h2 [] [ text copy.kleihaven.blockOne.title ]
            , p [] [ text copy.kleihaven.blockOne.subtitle ]
            ]
        , div [ class "block__cards" ] <|
            List.map viewCard copy.kleihaven.blockOne.cards
        ]


viewKleihavenBlockTwo : Html Msg
viewKleihavenBlockTwo =
    section [ class "block" ]
        [ div [ class "block__header" ]
            [ h2 [] [ text copy.kleihaven.blockTwo.title ]
            , p []
                [ text copy.kleihaven.blockTwo.intro ]
            ]
        , div [ class "block__cards" ]
            [ div [ class "card-text" ]
                [ h3 [] [ text copy.kleihaven.blockTwo.inside.title ]
                , p [] [ text copy.kleihaven.blockTwo.inside.text1 ]
                , p [] [ text copy.kleihaven.blockTwo.inside.text2 ]
                , p [] [ text copy.kleihaven.blockTwo.inside.text3 ]
                ]
            , div [ class "card-img" ]
                [ video [ autoplay True, attribute "muted" "true", loop True, attribute "playsinline" "true" ]
                    [ source [ src "/assets/raku.webm", type_ "video/webm" ] []
                    , source [ src "/assets/raku.mp4", type_ "video/mp4" ] []
                    ]
                ]
            , div [ class "card-text" ]
                [ h3 [] [ text copy.kleihaven.blockTwo.outside.title ]
                , p [] [ text copy.kleihaven.blockTwo.outside.text1 ]
                , p [] [ text copy.kleihaven.blockTwo.outside.text2 ]
                , p [] [ text copy.kleihaven.blockTwo.outside.text3 ]
                ]
            ]
        ]


viewMobileCoursesButton : Html Msg
viewMobileCoursesButton =
    Ui.Button.newPrimary
        { label = copy.kleihaven.mobileCoursesButton
        , action = Ui.Button.ToPage (Route.Cursussen Nothing)
        }
        |> Ui.Button.withMobileOnly
        |> Ui.Button.view



-- AIR


viewPageAIR : Model -> List (Html Msg)
viewPageAIR model =
    toContentPage
        [ h1 [] [ text "Artist in Residence" ]
        , p [ class "content__intro" ]
            [ text """
            Op zoek naar een inspirerende werkomgeving? Welkom bij Studio1931!
            """ ]
        , h2 [] [ text "Ondertitel!" ]
        , p [] [ text """
        Studio1931 stelt een van haar karakteristieke klaslokalen ter beschikking voor kunstenaars.
        Het atelier van circa 7 x 6 meter biedt volop ruimte en wordt soms gedeeld met andere makers.
        Met een hoog plafond en een grote raampartij heb je prachtig natuurlijk licht. Daarnaast is
        er een uitgebreide uitrusting aanwezig: een drukpers voor linoleum, droge naald en meer,
        evenals draaischijven, een kleiwals en keramiekovens.
        Alles wat je nodig hebt om jouw ideeën vorm te geven!
        """ ]
        , h3 [] [ text "Tussenkop!" ]
        , p [] [ text """
        Kunstenaars kunnen bij ons een artist-in-residence periode volgen, met werkperiodes
        variërend van twee tot acht weken. In overleg is veel mogelijk, zodat de periode
        volledig aansluit bij jouw wensen. Daarnaast bieden we de mogelijkheid om te verblijven
        in een volledig uitgeruste en gloednieuwe studio.
        """ ]
        , viewImage model.loadedImages
            { imgSrc = "air"
            , imgAlt = "Kunstenaars aan het werk in de studio"
            , lazy = True
            }
        , h3 [] [ text "Tussenkop" ]
        , p [] [ text """
        Interesse?
        Dat begrijpen we helemaal! Aanmelden kan op twee manieren:
        Via een Open Call - (link naar Open Call pagina) waarbij je reageert op een werkperiode
        met een specifiek onderwerp of thema, eventueel (deels) ondersteund door subsidie.
        Via jouw eigen werkplan of idee. We bekijken graag samen hoe dit in te passen is.
        Subsidie kun je, indien nodig, zelf aanvragen via de gebruiken kanalen.
        Meld je hier voor meer informatie en kosten!
        """ ]
        ]



-- OverOns


viewPageOverOns : List (Html Msg)
viewPageOverOns =
    toContentPage
        ([ h1 [] [ text "Over ons" ]
         ]
            ++ lorem
        )


lorem : List (Html Msg)
lorem =
    [ p [ class "content__intro" ] [ text copy.lorem ]
    , h2 [] [ text copy.loremTitle ]
    , p [] [ text copy.lorem ]
    , h3 [] [ text copy.loremTitle ]
    , p [] [ text copy.loremTwo ]
    , h3 [] [ text copy.loremTitle ]
    , p [] [ text copy.loremTwo ]
    ]



-- Cursussen


viewPageCursussen : Model -> Maybe CourseId -> List (Html Msg)
viewPageCursussen model maybeCourseId =
    [ h1 [ class "centered" ] [ text "Cursusaanbod" ]
    , div [ class "block__header" ]
        [ h2 [] [ text "Keramiekcursussen voor elk niveau" ]
        , p [] [ text "Onze cursussen bieden een unieke combinatie van handvormen en draaien, waar jouw creativiteit centraal staat. Met een mix van techniek, experiment en plezier ontdek je de magie van keramiek!" ]
        ]
    , if model.loadingCourses then
        div [ class "centered" ]
            [ div [ class "loading-spinner" ] [] ]

      else
        case model.error of
            Just _ ->
                div [ class "centered" ]
                    [ text "Sorry, er is iets misgegaan bij het laden van de cursussen" ]

            Nothing ->
                Html.Keyed.node "div"
                    []
                    [ ( "courses"
                      , div [ class "courses-grid" ]
                            (List.map (viewCourse model.loadedImages) model.courses)
                      )
                    ]
    , viewCourseDetailModal model
    ]


viewCourse : Set String -> Course -> Html Msg
viewCourse loadedImages course =
    viewTextImageCard loadedImages
        { imgSrc = course.imageUrl
        , imgAlt = course.title
        , lazy = True
        }
        { content =
            [ h3 [] [ text course.title ]
            , viewMaybe course.subtitle
                (\subtitle -> h4 [] [ text subtitle ])
            , p [ class "course-card__price" ]
                [ text "€"
                , text (String.fromFloat course.price)
                ]
            , p [ class "course-card__description" ]
                [ text course.description ]
            , Ui.Button.newPrimary
                { label = "Meer informatie"
                , action = Ui.Button.ToPage (Route.Cursussen (Just course.id))
                }
                |> Ui.Button.view
            , div [ class "course-card__periods" ]
                (List.map (viewCoursePeriod course) course.periods)
            ]
        , extraClass = "course-card -vertical"
        }


viewCoursePeriod : Course -> Course.CoursePeriod -> Html Msg
viewCoursePeriod =
    viewCoursePeriod_ False


viewCoursePeriodInModal : Course -> Course.CoursePeriod -> Html Msg
viewCoursePeriodInModal =
    viewCoursePeriod_ True


viewCoursePeriod_ : Bool -> Course -> Course.CoursePeriod -> Html Msg
viewCoursePeriod_ isModal course period =
    let
        button =
            if isModal then
                Ui.Button.newPrimary

            else
                Ui.Button.newLinkButton
    in
    div [ class "course-period" ]
        [ div []
            [ p [ class "course-period__dates" ]
                [ Ui.Date.periodString
                    { start = period.startDate
                    , end = period.endDate
                    }
                    |> text
                ]
            , viewTimeInfo period.timeInfo
            , p [ class "course-period__spots" ]
                [ text (String.fromInt period.availableSpots)
                , text " plekken beschikbaar"
                ]
            ]
        , button
            { label = "Direct inschrijven"
            , action = Ui.Button.Msg (OpenRegistrationModal course period)
            }
            |> Ui.Button.view
        ]


viewTimeInfo : Maybe String -> Html Msg
viewTimeInfo timeInfo =
    case timeInfo of
        Just info ->
            p [ class "course-period__time-info" ]
                [ text info ]

        Nothing ->
            text ""



-- NOT FOUND


viewPageNotFound : List (Html Msg)
viewPageNotFound =
    toContentPage
        [ h1 [] [ text copy.notFound.title ]
        , p [] [ text copy.notFound.description ]
        ]



-- PRIVACY


viewPagePrivacy : List (Html Msg)
viewPagePrivacy =
    toContentPage Copy.privacyPage



-- FAQ


viewPageFAQ : List (Html Msg)
viewPageFAQ =
    toContentPage Copy.faqPage



-- TERMS


viewPageTerms : List (Html Msg)
viewPageTerms =
    toContentPage Copy.termsPage



-- MODALS


viewModal :
    { closeMsg : Msg
    , extraClass : String
    , content : List (Html Msg)
    }
    -> Html Msg
viewModal { content, closeMsg, extraClass } =
    div [ class "modal-overlay" ]
        [ div [ class "modal-wrapper", class extraClass ]
            [ div [ class "modal" ]
                [ div [ class "modal__close" ]
                    [ Ui.Button.newClose
                        { label = "Sluiten"
                        , action = Ui.Button.Msg closeMsg
                        }
                        |> Ui.Button.view
                    ]
                , div [ class "modal__content" ] content
                ]
            ]
        , node "style"
            []
            [ text "body { height: 100%; overflow: hidden; }" ]
        ]



-- COURSE DETAIL MODAL


viewCourseDetailModal : Model -> Html Msg
viewCourseDetailModal model =
    case model.currentCourse of
        Just course ->
            viewModal
                { closeMsg = CloseCourseDetailModal
                , extraClass = "course-detail-modal"
                , content =
                    [ div [ class "modal__content__inner" ]
                        [ h2 [] [ text course.title ]
                        , p [ class "modal__content__intro" ]
                            [ text course.description ]
                        , div [ class "modal__content__image" ]
                            [ viewImage model.loadedImages
                                { imgSrc = course.imageUrl
                                , imgAlt = course.title
                                , lazy = False
                                }
                            ]
                        , p [ class "modal__content__price" ]
                            [ text "Kosten per persoon: € "
                            , text (String.fromFloat course.price)
                            ]
                        , viewParsedHtml "modal__content__text" course.content
                        ]
                    , div [ class "modal__content__periods" ]
                        (List.map (viewCoursePeriodInModal course) course.periods)
                    ]
                }

        Nothing ->
            text ""


viewParsedHtml : String -> Maybe String -> Html Msg
viewParsedHtml className maybeContent =
    case maybeContent of
        Just content ->
            case Html.Parser.run content of
                Ok nodes ->
                    div [ class className ]
                        (Html.Parser.Util.toVirtualDom nodes)

                Err _ ->
                    text "Oeps, er is iets misgegaan bij het laden van de tekst."

        Nothing ->
            text ""



-- REGISTRATION MODAL


viewRegistrationModal : Maybe Course.RegistrationModal -> Maybe Course -> Html Msg
viewRegistrationModal maybeModal currentCourse =
    case maybeModal of
        Nothing ->
            text ""

        Just modal ->
            viewModal
                { closeMsg = CloseRegistrationModal
                , extraClass = ""
                , content =
                    [ h2 [] [ text "Inschrijfformulier" ]
                    , h3 []
                        [ text modal.course.title ]
                    , p [ class "bold font-secondary" ]
                        [ Ui.Date.periodString
                            { start = modal.period.startDate
                            , end = modal.period.endDate
                            }
                            |> text
                        ]
                    , p [] [ text "Wat leuk dat je mee wilt doen! Vul het formulier in om je inschrijving te voltooien. Je wordt automatisch doorverwezen naar de betalingspagina." ]
                    , Html.form
                        [ preventDefaultOn "submit" (Decode.succeed ( SubmitRegistration, True ))
                        , novalidate True
                        ]
                        [ Ui.FormField.new
                            { id = "name"
                            , label = "Naam"
                            , value = modal.name
                            , onInput = UpdateRegistrationName
                            }
                            |> Ui.FormField.withRequired True
                            |> Ui.FormField.withError modal.errors.name
                            |> Ui.FormField.view
                        , Ui.FormField.new
                            { id = "email"
                            , label = "E-mail"
                            , value = modal.email
                            , onInput = UpdateRegistrationEmail
                            }
                            |> Ui.FormField.withTypeEmail
                            |> Ui.FormField.withRequired True
                            |> Ui.FormField.withError modal.errors.email
                            |> Ui.FormField.view
                        , Ui.FormField.new
                            { id = "spots"
                            , label = "Aantal plekken"
                            , value = String.fromInt modal.spots
                            , onInput = UpdateRegistrationSpots
                            }
                            |> Ui.FormField.withSelect
                                (List.range 1 modal.period.availableSpots
                                    |> List.map
                                        (\n ->
                                            { value = String.fromInt n
                                            , label = String.fromInt n
                                            , selected = n == modal.spots
                                            }
                                        )
                                )
                            |> Ui.FormField.withError modal.errors.spots
                            |> Ui.FormField.view
                        , p [ class "modal__total-cost" ]
                            [ text "Totaal: € "
                            , String.fromFloat (modal.course.price * toFloat modal.spots)
                                |> text
                            ]
                        , viewError modal.bookingError
                        , div [ class "modal-buttons" ]
                            [ viewIf (currentCourse == Nothing)
                                (Ui.Button.newLinkButton
                                    { label = "Meer lezen over deze cursus?"
                                    , action = Ui.Button.Msg (CloseRegistrationAndOpenCourse modal.course.id)
                                    }
                                    |> Ui.Button.withType "button"
                                    |> Ui.Button.view
                                )
                            , Ui.Button.newSecondary
                                { label = "Annuleren"
                                , action = Ui.Button.Msg CloseRegistrationModal
                                }
                                |> Ui.Button.withType "button"
                                |> Ui.Button.view
                            , Ui.Button.newPrimary
                                { label = "Afrekenen"
                                , action = Ui.Button.Submit
                                }
                                |> Ui.Button.withSpinner modal.submitting
                                |> Ui.Button.withType "submit"
                                |> Ui.Button.view
                            ]
                        ]
                    ]
                }


viewError : Maybe String -> Html msg
viewError maybeError =
    case maybeError of
        Just error ->
            p [ class "modal__error" ] [ text error ]

        Nothing ->
            text ""
