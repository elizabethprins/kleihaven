port module Main exposing (main)

import Browser
import Browser.Events
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Process
import Route
import Set exposing (Set)
import Task
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
    { title = "Kleihaven"
    , body =
        [ viewNavigation
        , main_ [ class "main" ]
            [ case model.page of
                Route.Kleihaven ->
                    div [ class "main" ]
                        [ h1 [] [ text "Kleihaven" ]
                        , p [] [ text "Kleihaven is een toevluchtsoord en vertrekplek voor keramiek." ]
                        ]

                Route.Home ->
                    div [ class "home" ]
                        [ viewHomeIntro
                        ]

                Route.NotFound ->
                    div [ class "not-found" ]
                        [ h1 [] [ text "Pagina niet gevonden" ]
                        , p [] [ text "De pagina die je zoekt bestaat niet." ]
                        ]
            ]
        ]
    }


viewLogo : Html Msg
viewLogo =
    a [ class "logo", title "Studio 1931", href (Route.toUrl Route.Home) ]
        [ img
            [ src "/assets/logostudio1931-small.png"
            , class "logo"
            , alt "Studio 1931"
            ]
            []
        ]


viewNavigation : Html Msg
viewNavigation =
    header [ class "header" ]
        [ viewLogo
        , nav [ class "nav" ]
            [ ul []
                [ li [] [ a [ href (Route.toUrl Route.Kleihaven) ] [ text "Kleihaven" ] ]
                , li [] [ a [ href (Route.toUrl Route.Home) ] [ text "Home" ] ]
                , li [] [ a [ href "/notfound" ] [ text "NotFound!" ] ]
                ]
            ]
        ]


viewHomeIntro : Html Msg
viewHomeIntro =
    section [ class "home-intro" ]
        [ div [ class "home-intro__left card card--green" ]
            [ h1 [ class "home-intro__title" ]
                [ text "Kleihaven"
                ]
            , h2 [ class "home-intro__subtitle" ]
                [ text "het toevluchtsoord en de vertrekplek voor keramiek" ]
            , p [ class "home-intro__text" ]
                [ text
                    """
            Wil je keramist worden? Jouw creativiteit een boost geven? 
            Experimenteren met klei? Welkom bij de Kleihaven! 
            Wij bieden keramiekcursussen van enkele dagen tot twee volle weken.
                    """
                ]
            , button [ class "button" ]
                [ text "Bekijk alle cursussen" ]
            ]
        , div [ class "home-intro__right" ]
            [ img
                [ src "/assets/house-garden.jpg"
                , class "home-intro__right__img"
                , class "home-intro__right__img--back"
                ]
                []
            , img
                [ src "/assets/ceramic_classroom.jpeg"
                , class "home-intro__right__img"
                , class "home-intro__right__img--front"
                ]
                []
            ]
        ]
