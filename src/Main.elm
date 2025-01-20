port module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Navigation as Navigation
import Copy exposing (copy)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick)
import Html.Keyed
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Route
import Set exposing (Set)
import Task
import Ui.Button
import Ui.Date
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
    , error : Maybe Http.Error
    }


type alias Course =
    { title : String
    , description : String
    , imageUrl : String
    , price : Float
    , periods : List CoursePeriod
    }


type alias CoursePeriod =
    { id : String
    , startDate : String
    , endDate : String
    , timeInfo : Maybe String
    , availableSpots : Int
    }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialPage =
            Route.toPage url
    in
    ( { navKey = key
      , apiBaseUrl = flags.apiBaseUrl
      , page = initialPage
      , loadedImages = Set.empty
      , mobileMenuOpen = False
      , courses = []
      , loadingCourses = initialPage == Route.Cursussen
      , error = Nothing
      }
    , if initialPage == Route.Cursussen then
        fetchCourses flags.apiBaseUrl

      else
        Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | ClickedLink Browser.UrlRequest
    | UrlChanged Url
    | ImageLoaded String
    | ToggleMobileMenu
    | GotCourses (Result Http.Error (List Course))


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
            in
            if page == model.page then
                ( newModel, Cmd.none )

            else
                ( { newModel
                    | loadingCourses = page == Route.Cursussen
                    , loadedImages = Set.empty
                  }
                , Cmd.batch
                    [ urlChanged (Route.toUrl <| Route.toPage url)
                    , if page == Route.Cursussen then
                        fetchCourses model.apiBaseUrl

                      else
                        Cmd.none
                    ]
                )

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

                Route.Cursussen ->
                    viewPageCursussen model

                Route.AIR ->
                    viewPageAIR model

                Route.OverOns ->
                    viewPageOverOns

                Route.NotFound ->
                    viewPageNotFound
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
                , action = Ui.Button.ToPage Route.Cursussen
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
        [ h2 [ class "centered" ]
            [ text copy.home.block.title ]
        , p [ class "centered" ]
            [ text copy.home.block.description ]
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
                        , action = Ui.Button.ToPage Route.AIR
                        }
                        |> Ui.Button.view
                    ]
                , extraClass = "-clickable"
                }
    in
    section [ class "block" ]
        [ h2 [ class "centered" ] [ text copy.kleihaven.blockOne.title ]
        , p [ class "centered" ] [ text copy.kleihaven.blockOne.subtitle ]
        , div [ class "block__cards" ] <|
            List.map viewCard copy.kleihaven.blockOne.cards
        ]


viewKleihavenBlockTwo : Html Msg
viewKleihavenBlockTwo =
    section [ class "block" ]
        [ h2 [ class "centered" ] [ text copy.kleihaven.blockTwo.title ]
        , p [ class "centered" ]
            [ text copy.kleihaven.blockTwo.intro ]
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
        , action = Ui.Button.ToPage Route.Cursussen
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


{-|

        2025
        - draaien voor beginners (pasen, 4 dagen)
        - draaien en handvormen (meivakantie, 1week: 28 april - 4 mei)
        - draaien voor gevorderden (hemelvaart, 4 dagen)
        - decoratie en stooktechnieken (pinksteren, 3 dagen)
        - zomerschool: aan tafel! ( 2 weken in de zomer , start 21 juni, eind 5 juli)
        - zomerschool: vrij/creatief ( 2 weken in de zomer, start 13 juli, eind 25 julie)

-}
viewPageCursussen : Model -> List (Html Msg)
viewPageCursussen model =
    [ h1 [ class "centered" ] [ text "Cursusaanbod" ]
    , h2 [ class "centered" ] [ text "Keramiekcursussen voor elk niveau" ]
    , if model.loadingCourses then
        div [ class "centered" ]
            [ text "Cursussen worden geladen..." ]

      else
        case model.error of
            Just err ->
                div [ class "centered" ]
                    [ text "Sorry, er is iets misgegaan bij het laden van de cursussen" ]

            Nothing ->
                div [ class "courses-grid" ]
                    (List.map (viewCourse model.loadedImages) model.courses)
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
            , p [] [ text course.description ]
            , p [ class "course-card__price" ]
                [ text "Kosten per persoon: € "
                , text (String.fromFloat course.price)
                ]
            , div [ class "course-card__periods" ]
                (List.map viewCoursePeriod course.periods)
            ]
        , extraClass = "course-card -vertical"
        }


viewCoursePeriod : CoursePeriod -> Html Msg
viewCoursePeriod period =
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
        , Ui.Button.newPrimary
            { label = "Inschrijven"
            , action = Ui.Button.Msg NoOp
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



-- HTTP


fetchCourses : String -> Cmd Msg
fetchCourses apiBaseUrl =
    Http.get
        { url = apiBaseUrl ++ "/.netlify/functions/fetchCourses"
        , expect = Http.expectJson GotCourses coursesDecoder
        }


coursesDecoder : Decode.Decoder (List Course)
coursesDecoder =
    Decode.field "data"
        (Decode.field "data"
            (Decode.list courseDecoder)
        )


courseDecoder : Decode.Decoder Course
courseDecoder =
    Decode.succeed Course
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "description" Decode.string
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
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "startDate" Decode.string
        |> Pipeline.required "endDate" Decode.string
        |> Pipeline.optional "timeInfo" (Decode.maybe Decode.string) Nothing
        |> Pipeline.custom
            (Decode.map2 (\total booked -> total - booked)
                (Decode.field "totalSpots" Decode.int)
                (Decode.field "bookedSpots" Decode.int)
            )
