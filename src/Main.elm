port module Main exposing (main)

import Browser
import Browser.Events
import Browser.Navigation as Navigation
import Copy exposing (copy)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
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
    }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { navKey = key
      , page = Route.toPage url
      }
    , urlChanged (Route.toUrl <| Route.toPage url)
    )



-- UPDATE


type Msg
    = NoOp
    | ClickedLink Browser.UrlRequest
    | UrlChanged Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ClickedLink request ->
            case request of
                Browser.Internal url ->
                    ( model
                    , Navigation.pushUrl model.navKey (Url.toString url)
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
            ( { model | page = page }
            , urlChanged (Route.toUrl <| Route.toPage url)
            )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = copy.title
    , body =
        [ viewNavigation
        , main_ [ class "main" ] <|
            case model.page of
                Route.Kleihaven ->
                    viewPageKleihaven

                Route.Home ->
                    viewPageHome

                Route.NotFound ->
                    viewPageNotFound

                _ ->
                    [ h1 [] [ text copy.pageInDevelopment ] ]
        ]
    }


viewNavigation : Html Msg
viewNavigation =
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
    in
    header [ class "header" ]
        [ viewLogo
        , nav [ class "nav" ]
            [ ul []
                (List.map viewMenuItem Route.allPages)
            ]
        ]



-- PAGE HELPERS


viewIntro : { title : String, subtitle : String, intro : String, coursesButton : String } -> List String -> Html Msg
viewIntro content imgSrcs =
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
            List.map viewImageCard imgSrcs
        ]


viewImageCard : String -> Html msg
viewImageCard imgSrc =
    div [ class "card-img" ]
        [ img
            [ src imgSrc
            , alt ""
            ]
            []
        ]



-- VIEW PAGES


viewPageNotFound : List (Html Msg)
viewPageNotFound =
    [ h1 [] [ text copy.notFound.title ]
    , p [] [ text copy.notFound.description ]
    ]



-- HOMEPAGE


viewPageHome : List (Html Msg)
viewPageHome =
    [ viewHomeIntro
    ]


viewHomeIntro : Html Msg
viewHomeIntro =
    viewIntro
        { title = copy.home.title
        , subtitle = copy.home.subtitle
        , intro = copy.home.intro
        , coursesButton = copy.home.coursesButton
        }
        [ "/assets/9x16/huis-tuin.jpg"
        , "/assets/9x16/keramiek-lokaal.jpg"
        ]



-- KLEIHAVEN


viewPageKleihaven : List (Html Msg)
viewPageKleihaven =
    [ viewKleihavenIntro
    , viewDivider
    , viewKleihavenBlock
    , viewKleihavenBlockTwo
    ]


viewKleihavenIntro : Html Msg
viewKleihavenIntro =
    viewIntro
        { title = copy.kleihaven.title
        , subtitle = copy.kleihaven.subtitle
        , intro = copy.kleihaven.intro
        , coursesButton = copy.kleihaven.coursesButton
        }
        [ "/assets/9x16/klei-barbara.jpg"
        , "/assets/9x16/potten-van-boven.jpg"
        ]


viewDivider : Html msg
viewDivider =
    img [ src "/assets/trimmingtool.svg", class "divider-img" ] []


viewKleihavenBlock : Html Msg
viewKleihavenBlock =
    let
        viewCard content =
            div [ class "card-text-img -clickable" ]
                [ img
                    [ src content.imgSrc
                    , alt ""
                    ]
                    []
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
                    [ source [ src "/assets/raku.mov", type_ "video/mp4" ] []
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
