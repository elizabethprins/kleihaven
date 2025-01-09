port module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation as Navigation
import Copy exposing (copy)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick)
import Html.Keyed
import Json.Decode as Decode
import Process
import Route
import Set exposing (Set)
import Task
import Ui.Button
import Url exposing (Url)



-- MAIN


main : Program () Model Msg
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
subscriptions model =
    Sub.none



-- MODEL


type alias Model =
    { navKey : Navigation.Key
    , page : Route.Page
    , loadedImages : Set String
    , mobileMenuOpen : Bool
    }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { navKey = key
      , page = Route.toPage url
      , loadedImages = Set.empty
      , mobileMenuOpen = False
      }
    , urlChanged (Route.toUrl <| Route.toPage url)
    )



-- UPDATE


type Msg
    = NoOp
    | ClickedLink Browser.UrlRequest
    | UrlChanged Url
    | ImageLoaded String
    | ToggleMobileMenu


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
            in
            ( { model
                | page = page
                , mobileMenuOpen = False
              }
            , urlChanged (Route.toUrl <| Route.toPage url)
            )

        ImageLoaded src ->
            ( { model | loadedImages = Set.insert src model.loadedImages }
            , Cmd.none
            )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = copy.title
    , body =
        [ viewNavigation model
        , main_ [ class "main" ] <|
            case model.page of
                Route.Kleihaven ->
                    viewPageKleihaven model

                Route.Home ->
                    viewPageHome model

                Route.NotFound ->
                    viewPageNotFound

                _ ->
                    [ h1 [] [ text copy.pageInDevelopment ] ]
        ]
    }


viewNavigation : Model -> Html Msg
viewNavigation model =
    let
        viewLogo =
            a [ class "logo", title "Studio 1931", href (Route.toUrl Route.Home) ]
                [ img
                    [ src "/assets/logostudio1931-small.png"
                    , class "logo"
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
        [ viewLogo
        , hamburgerButton
        , nav [ class "nav" ]
            [ ul []
                (List.map viewMenuItem Route.allPages)
            ]
        ]



-- PAGE HELPERS


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


viewPageNotFound : List (Html Msg)
viewPageNotFound =
    [ h1 [] [ text copy.notFound.title ]
    , p [] [ text copy.notFound.description ]
    ]



-- HOMEPAGE


viewPageHome : Model -> List (Html Msg)
viewPageHome model =
    [ viewHomeIntro model
    , viewHomeBlock model
    , viewHomeBlockKleihaven model
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


viewHomeBlock : Model -> Html Msg
viewHomeBlock { loadedImages } =
    section [ class "block" ]
        [ h2 [ class "centered" ]
            [ text "Programma's en activiteiten" ]
        , p [ class "centered" ]
            [ text """
        Studio1931 is een broedplaats met artistieke programma's en activiteiten. 
        Bij ons vind je alle ruimte om je ideeën tot leven te brengen.
        """ ]
        ]


viewHomeBlockKleihaven : Model -> Html Msg
viewHomeBlockKleihaven { loadedImages } =
    section [ class "block" ]
        [ div [ class "block__cards -centerpiece" ]
            [ img
                [ src "/assets/klei-potje.png"
                , alt "Pot van klei"
                ]
                []
            , div [ class "card-text" ]
                [ div []
                    [ h2 [] [ text "Studio1931 presenteert: Kleihaven" ]
                    , p [] [ text """
          Bij Kleihaven draait alles om leren en creëren.
          Onder de inspirerende leiding van bevlogen kunstenaars en docenten bieden we
          diverse keramiekcursussen, variërend van enkele dagen tot twee weken.
          Van draaitechnieken en handvormen tot glazuren en stooktechnieken – bij ons
          kun je zowel je technische vaardigheden als je creatieve ideeën verder ontwikkelen.
          """ ]
                    , p []
                        [ text """
          Onze cursussen zijn geschikt voor zowel enthousiaste amateurs als doorgewinterde
          professionals. En wil je het meeste uit je ervaring halen? Blijf dan logeren in ons
          gastenverblijf en dompel je volledig onder in de creatieve sfeer.
          """
                        ]
                    , p [] [ text """
          Kleihaven biedt voor elk wat wils, een bijzondere leerervaring voor je handen en je hoofd.
          """ ]
                    , Ui.Button.newSecondary
                        { label = "Lees meer"
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
                [ h2 [] [ text "Artist in Residence programma's" ]
                , p [] [ text """
                Ben jij beeldend kunstenaar en toe aan een plek waar frisse zeewind nieuwe 
                energie aan je werk geeft? Of je nu ruimte zoekt om bestaande plannen uit 
                te werken, of inspiratie op te doen voor nieuwe projecten, Studio1931 biedt een ruime 
                werkplek en tijd om je te focussen. 
                """ ]
                , p [] [ text """
            We bieden werkperiodes van 4 à 6 weken voor individuele kunstenaars of duo's.
            Ook hebben we onze Tussen Zoet en Zout week: 
            een jaarlijks terugkerende projectweek waar meerdere kunstenaars (samen)werken.
            """ ]
                , p [] [ text """
            Laat je meevoeren door de rust, wind 
                en bijzondere omgeving - dé ingrediënten om jouw proces en werk te laten bruisen. 
            """ ]
                , Ui.Button.newSecondary
                    { label = "Lees meer"
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
        [ div [ class "block__cards -two-cards" ]
            [ viewImageCard model.loadedImages
                { imgSrc = "wieringen"
                , imgAlt = "Uitzicht over de Waddenzee vanaf voormalig eiland Wieringen"
                , lazy = True
                }
            , div [ class "card-text" ]
                [ h2 []
                    [ text "Over Studio1931" ]
                , p []
                    [ text """
                Studio1931 heeft als doel om makers, publiek, kunst en omgeving met elkaar te verbinden.
                 """ ]
                , p [] [ text """
                We zijn gevestigd in de oude basisschool van Den Oever, 
                op het voormalige Zuiderzee-eiland Wieringen.
                Het is een prachtige plek om zowel te wonen als te werken in 
                en tussen de kunsten.
                """ ]
                , p [] [ text """
                Met werelderfgoed de Waddenzee in de achtertuin 
                en het IJsselmeer op loopafstand zit Studio1931 op een bijzondere 
                locatie waar de zeewind alle artistieke plannen en creatieve ideeën aanwakkert.
                """ ]
                , Ui.Button.newSecondary
                    { label = "Lees meer"
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
            div [ class "card-text-img -clickable" ]
                [ viewImage model.loadedImages
                    { imgSrc = content.imgSrc
                    , imgAlt = content.imgAlt
                    , lazy = True
                    }
                , div [ class "card-text-img__content" ]
                    [ p []
                        [ text content.text ]
                    , p [ class "centered" ] [ text "☆" ]
                    , Ui.Button.secretLink
                        { label = copy.kleihaven.blockOne.viewCoursesButton
                        , action = Ui.Button.ToPage Route.AIR
                        }
                        |> Ui.Button.view
                    ]
                ]
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
