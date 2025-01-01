module Ui.Button exposing (Action(..), newLink, newPrimary, newSecondary, view)

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
        }


type Action msg
    = ToPage Route.Page
    | ToUrl String
    | Msg msg


type Style
    = Primary
    | Secondary
    | Link


new : Style -> { label : String, action : Action msg } -> Config msg
new style { label, action } =
    Config
        { label = label
        , action = action
        , style = style
        , isDisabled = False
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


withDisabledIf : Bool -> Config msg -> Config msg
withDisabledIf condition (Config config) =
    Config { config | isDisabled = condition }



-- VIEW


view : Config msg -> Html msg
view (Config config) =
    toHtmlNode (Config config) [ text config.label ]



-- HELPERS


toHtmlNode : Config msg -> List (Html msg) -> Html msg
toHtmlNode (Config config) =
    let
        classList =
            toClassList (Config config)
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
                [ onClick msg
                , disabled config.isDisabled
                , classList
                ]


toClassList : Config msg -> Attribute msg
toClassList (Config config) =
    classList
        [ ( "button", config.style /= Link )
        , ( "link", config.style == Link )
        , ( "button--primary", config.style == Primary )
        , ( "button--secondary", config.style == Secondary )
        , ( "-is-disabled", config.isDisabled )
        ]
