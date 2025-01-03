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
    { title = "Kleihaven"
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
                    [ h1 [] [ text "Pagina in ontwikkeling" ] ]
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



-- VIEW PAGES


viewPageNotFound : List (Html Msg)
viewPageNotFound =
    [ h1 [] [ text "Pagina niet gevonden" ]
    , p [] [ text "De pagina die je zoekt bestaat niet." ]
    ]


viewPageHome : List (Html Msg)
viewPageHome =
    [ viewHomeIntro
    ]


viewHomeIntro : Html Msg
viewHomeIntro =
    section [ class "intro" ]
        [ -- div [ class "intro__extra" ]
          -- [ div [ class "card-img" ]
          --     [ img
          --         [ src "/assets/wadden.jpg"
          --         , class "intro__right__img"
          --         ]
          --         []
          --     ]
          -- ],
          div [ class "intro__left card card--green" ]
            [ h1 [ class "intro__title" ]
                [ text "Studio 1931" ]
            , h2 [ class "intro__subtitle" ]
                [ text "ontdekken, beleven en creëren op een bijzondere locatie" ]
            , p [ class "intro__text" ]
                [ text
                    """
            Gevestigd in een voormalige basisschool aan de Waddenzee, biedt Studio 1931
            keramiekcursussen, een artist-in-residence programma en gastenverblijf in
            een inspirerende omgeving.
                    """
                ]
            , Ui.Button.newPrimary
                { label = "Direct naar de cursussen"
                , action = Ui.Button.ToPage Route.Cursussen
                }
                |> Ui.Button.view
            ]
        , div [ class "intro__right" ]
            [ div [ class "card-img" ]
                [ img
                    [ src "/assets/9x16/huis-tuin.jpg"
                    , class "intro__right__img"
                    ]
                    []
                ]
            , div [ class "card-img" ]
                [ img
                    [ src "/assets/9x16/keramiek-lokaal.jpg"
                    , class "intro__right__img"
                    ]
                    []
                ]
            ]
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
    section [ class "intro" ]
        [ div [ class "intro__left card card--green" ]
            [ h1 [ class "intro__title" ]
                [ text "Kleihaven" ]
            , h2 [ class "intro__subtitle" ]
                [ text "het toevluchtsoord en de vertrekplek voor keramiek" ]
            , p [ class "intro__text" ]
                [ text
                    """
            Wil je keramist worden? Jouw creativiteit een boost geven? 
            Experimenteren met klei? Welkom bij de Kleihaven! 
            Wij bieden keramiekcursussen van enkele dagen tot twee volle weken.
                    """
                ]
            , Ui.Button.newPrimary
                { label = "Bekijk alle cursussen"
                , action = Ui.Button.ToPage Route.Cursussen
                }
                |> Ui.Button.view
            ]
        , div [ class "intro__right" ]
            [ div [ class "card-img" ]
                [ img
                    [ src "/assets/9x16/klei-barbara.jpg"
                    , class "intro__right__img"
                    ]
                    []
                ]
            , div [ class "card-img" ]
                [ img
                    [ src "/assets/9x16/potten-van-boven.jpg"
                    , class "intro__right__img"
                    ]
                    []
                ]
            ]
        ]


viewDivider : Html msg
viewDivider =
    img [ src "/assets/trimmingtool.svg", class "divider-img" ] []


viewKleihavenBlock : Html Msg
viewKleihavenBlock =
    section [ class "block" ]
        [ h2 [ class "centered" ] [ text "Ontdek, creëer en geniet!" ]
        , p [ class "centered" ] [ text "Bij Kleihaven ligt de wereld van keramiek in jouw handen" ]
        , div [ class "block__cards" ]
            [ div [ class "card-text-img -clickable" ]
                [ img
                    [ src "/assets/6x8/potje.jpg"
                    ]
                    []
                , div [ class "card-text-img__content" ]
                    [ p []
                        [ text
                            """
                Voor beginners en gevorderden – leer van beeldend kunstenaars en bevlogen docenten
                        """
                        ]
                    , p [ class "centered" ] [ text "☆" ]
                    , Ui.Button.secretLink
                        { label = "Bekijk onze cursussen"
                        , action = Ui.Button.ToPage Route.AIR
                        }
                        |> Ui.Button.view
                    ]
                ]
            , div [ class "card-text-img -clickable" ]
                [ img
                    [ src "/assets/6x8/mensen.jpg"
                    ]
                    []
                , div [ class "card-text-img__content" ]
                    [ p []
                        [ text
                            """
                Werk aan technische vaardigheden en ontdek jouw creatieve mogelijkheden
                        """
                        ]
                    , p [ class "centered" ] [ text "☆" ]
                    , Ui.Button.secretLink
                        { label = "Bekijk onze cursussen"
                        , action = Ui.Button.ToPage Route.AIR
                        }
                        |> Ui.Button.view
                    ]
                ]
            , div
                [ class "card-text-img -clickable" ]
                [ img
                    [ src "/assets/6x8/wieringen.jpg"
                    ]
                    []
                , div [ class "card-text-img__content" ]
                    [ p []
                        [ text
                            """
                Beleef voormalig eiland Wieringen, omringd door de Waddenzee en het IJsselmeer
                        """
                        ]
                    , p [ class "centered" ] [ text "☆" ]
                    , Ui.Button.secretLink
                        { label = "Bekijk onze cursussen"
                        , action = Ui.Button.ToPage Route.AIR
                        }
                        |> Ui.Button.view
                    ]
                ]
            ]
        ]


viewKleihavenBlockTwo : Html Msg
viewKleihavenBlockTwo =
    section [ class "block" ]
        [ h2 [ class "centered" ] [ text "Over de Kleihaven" ]
        , p [ class "centered" ]
            [ text
                """
        Kleihaven is gevestigd in Studio 1931, de oude school van Den Oever. 
        Het is een plek om te wonen, werken en verblijven in en tussen de kunsten – dat delen we graag met jou!
        """
            ]
        , div [ class "block__cards" ]
            [ div [ class "card-text" ]
                [ h3 [] [ text "Van binnen..." ]
                , p [] [ text """
                
        Eén van de lokalen is ingericht als volledig uitgeruste keramiekwerkplaats. 
        Hier staan acht splinternieuwe draaischijven, een grote kleiwals, strengenpers 
        en andere materialen voor je klaar. 
                """ ]
                , p [] [ text """Er zijn ovens in verschillende maten, en we hebben
        alles klaarstaan voor rakustook.""" ]
                , p [] [ text """
            Kortom – stap binnen en begin! 
            """ ]
                ]
            , div [ class "card-img" ]
                [ video [ autoplay True, attribute "muted" "true", loop True, attribute "playsinline" "true" ]
                    [ source [ src "/assets/raku.mov", type_ "video/mp4" ] []
                    ]
                ]
            , div [ class "card-text" ]
                [ h3 [] [ text "Naar buiten!" ]
                , p [] [ text """      
        Ook buiten is het genieten. Het oorspronkelijke schoolplein is een bloeiende 
        tuin geworden.
                """ ]
                , p [] [ text """      
        Zodra het weer het toelaat, werken we graag in de buitenlucht. 
        Denk aan grote tafels om samen aan te werken, of een rustig plekje met een kleibok 
        tussen de rozen en de eeuwenoude lindenbomen.
                """ ]
                , p [] [ text """
            Klinkt goed, toch? 
            """ ]
                ]
            ]
        ]
