module Ui.FormField exposing
    ( new
    , view
    , withError
    , withHtmlLabel
    , withRequired
    , withSelect
    , withTypeCheckbox
    , withTypeEmail
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type Config msg
    = Config
        { id : String
        , label : Html msg
        , value : String
        , onInput : String -> msg
        , fieldType : FieldType
        , error : Maybe String
        , isRequired : Bool
        }


type FieldType
    = Text
    | Email
    | Select (List SelectOption)
    | Checkbox


type alias SelectOption =
    { value : String
    , label : String
    , selected : Bool
    }


new :
    { id : String
    , label : String
    , value : String
    , onInput : String -> msg
    }
    -> Config msg
new config =
    Config
        { id = config.id
        , label = text config.label
        , value = config.value
        , onInput = config.onInput
        , fieldType = Text
        , error = Nothing
        , isRequired = False
        }


withRequired : Bool -> Config msg -> Config msg
withRequired isRequired (Config config) =
    Config { config | isRequired = isRequired }


withError : Maybe String -> Config msg -> Config msg
withError error (Config config) =
    Config { config | error = error }


withSelect : List SelectOption -> Config msg -> Config msg
withSelect options (Config config) =
    Config { config | fieldType = Select options }


withTypeEmail : Config msg -> Config msg
withTypeEmail (Config config) =
    Config { config | fieldType = Email }


withTypeCheckbox : Config msg -> Config msg
withTypeCheckbox (Config config) =
    Config { config | fieldType = Checkbox }


withHtmlLabel : Html msg -> Config msg -> Config msg
withHtmlLabel label (Config config) =
    Config { config | label = label }



-- VIEW


view : Config msg -> Html msg
view (Config config) =
    div
        [ class "form-group"
        , classList
            [ ( "form-group--checkbox", config.fieldType == Checkbox ) ]
        ]
        [ label [ for config.id ] [ config.label ]
        , case config.fieldType of
            Select options ->
                select
                    [ id config.id
                    , onInput config.onInput
                    , classList
                        [ ( "form-group__input", True )
                        , ( "form-group__input--error", config.error /= Nothing )
                        ]
                    ]
                    (List.map viewOption options)

            Checkbox ->
                input
                    [ id config.id
                    , type_ "checkbox"
                    , checked (config.value == "true")
                    , onInput config.onInput
                    , required config.isRequired
                    , class "form-group__checkbox"
                    , classList
                        [ ( "form-group__input", True )
                        , ( "form-group__input--error", config.error /= Nothing )
                        ]
                    ]
                    []

            _ ->
                input
                    [ id config.id
                    , type_ (typeToString config.fieldType)
                    , value config.value
                    , onInput config.onInput
                    , required config.isRequired
                    , classList
                        [ ( "form-group__input", True )
                        , ( "form-group__input--error", config.error /= Nothing )
                        ]
                    ]
                    []
        , viewError config.error
        ]


viewOption : SelectOption -> Html msg
viewOption opt =
    option
        [ value opt.value
        , selected opt.selected
        ]
        [ text opt.label ]


viewError : Maybe String -> Html msg
viewError error =
    case error of
        Just errorMessage ->
            div [ class "form-group__error" ]
                [ text errorMessage ]

        Nothing ->
            text ""


typeToString : FieldType -> String
typeToString fieldType =
    case fieldType of
        Text ->
            "text"

        Email ->
            "email"

        Select _ ->
            "select"

        Checkbox ->
            "checkbox"
