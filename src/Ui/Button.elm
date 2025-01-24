module Ui.Button exposing (Action(..), newClose, newLink, newPrimary, newSecondary, secretLink, view, withMobileOnly, withSpinner, withType)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Route


type Config msg
    = Config
        { label : String
        , action : Action msg
        , style : Style
        , isDisabled : Bool
        , isMobileOnly : Bool
        , buttonType : Maybe String
        , showSpinner : Bool
        }


type Action msg
    = ToPage Route.Page
    | ToUrl String
    | Msg msg
    | Submit


type Style
    = Primary
    | Secondary
    | Link
    | SecretLink
    | Close


new : Style -> { label : String, action : Action msg } -> Config msg
new style { label, action } =
    Config
        { label = label
        , action = action
        , style = style
        , isDisabled = False
        , isMobileOnly = False
        , buttonType = Nothing
        , showSpinner = False
        }


newPrimary : { label : String, action : Action msg } -> Config msg
newPrimary { label, action } =
    new Primary { label = label, action = action }


newSecondary : { label : String, action : Action msg } -> Config msg
newSecondary { label, action } =
    new Secondary { label = label, action = action }


newLink : { label : String, action : Action msg } -> Config msg
newLink { label, action } =
    new Link { label = label, action = action }


newClose : { label : String, action : Action msg } -> Config msg
newClose { label, action } =
    new Close { label = label, action = action }


secretLink : { label : String, action : Action msg } -> Config msg
secretLink { label, action } =
    new SecretLink { label = label, action = action }


withDisabledIf : Bool -> Config msg -> Config msg
withDisabledIf condition (Config config) =
    Config { config | isDisabled = condition }


withMobileOnly : Config msg -> Config msg
withMobileOnly (Config config) =
    Config { config | isMobileOnly = True }


withType : String -> Config msg -> Config msg
withType buttonType (Config config) =
    Config { config | buttonType = Just buttonType }


withSpinner : Bool -> Config msg -> Config msg
withSpinner showSpinner (Config config) =
    Config { config | showSpinner = showSpinner }



-- VIEW


view : Config msg -> Html msg
view (Config config) =
    let
        secretText =
            span [ class "visually-hidden" ] [ text config.label ]

        content =
            case config.style of
                SecretLink ->
                    [ secretText ]

                Close ->
                    [ secretText
                    , div [ class "modal__close" ]
                        [ text "x"
                        ]
                    ]

                _ ->
                    if config.showSpinner then
                        [ text config.label
                        , div [ class "loading-spinner" ] []
                        ]

                    else
                        [ text config.label ]
    in
    toHtmlNode (Config config) content



-- HELPERS


toHtmlNode : Config msg -> List (Html msg) -> Html msg
toHtmlNode (Config config) =
    let
        classList =
            toClassList (Config config)

        buttonAttrs =
            [ disabled config.isDisabled
            , classList
            , type_ (Maybe.withDefault "button" config.buttonType)
            ]
    in
    case config.action of
        ToPage page ->
            if config.isDisabled then
                span [ classList ]

            else
                a [ href (Route.toUrl page), classList ]

        ToUrl url ->
            if config.isDisabled then
                span [ classList ]

            else
                a
                    [ href url
                    , rel "noopener noreferrer"
                    , target "_blank"
                    , classList
                    ]

        Msg msg ->
            button
                (onClick msg
                    :: buttonAttrs
                )

        Submit ->
            button buttonAttrs


toClassList : Config msg -> Attribute msg
toClassList (Config config) =
    classList
        [ ( "button", config.style /= Link && config.style /= SecretLink )
        , ( "link", config.style == Link )
        , ( "button--primary", config.style == Primary )
        , ( "button--secondary", config.style == Secondary )
        , ( "-is-disabled", config.isDisabled )
        , ( "-is-mobile-only", config.isMobileOnly )
        , ( "link-secret", config.style == SecretLink )
        ]
