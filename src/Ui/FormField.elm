module Ui.FormField exposing
    ( FormField
    , new
    , view
    , withError
    , withMax
    , withMin
    , withRequired
    , withSelect
    , withType
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type Config msg
    = Config
        { id : String
        , label : String
        , value : String
        , onInput : String -> msg
        , inputType : String
        , isRequired : Bool
        , minValue : Maybe String
        , maxValue : Maybe String
        , error : Maybe String
        , fieldType : FieldType
        }


type FormField msg
    = FormField (Config msg)


type FieldType
    = Text
    | Email
    | Number
    | Select (List SelectOption)


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
new { id, label, value, onInput } =
    Config
        { id = id
        , label = label
        , value = value
        , onInput = onInput
        , inputType = "text"
        , isRequired = False
        , minValue = Nothing
        , maxValue = Nothing
        , error = Nothing
        , fieldType = Text
        }


withRequired : Bool -> Config msg -> Config msg
withRequired isRequired (Config config) =
    Config { config | isRequired = isRequired }


withType : String -> Config msg -> Config msg
withType inputType (Config config) =
    Config { config | inputType = inputType }


withMin : String -> Config msg -> Config msg
withMin minValue (Config config) =
    Config { config | minValue = Just minValue }


withMax : String -> Config msg -> Config msg
withMax maxValue (Config config) =
    Config { config | maxValue = Just maxValue }


withError : Maybe String -> Config msg -> Config msg
withError error (Config config) =
    Config { config | error = error }


withSelect : List SelectOption -> Config msg -> Config msg
withSelect options (Config config) =
    Config { config | fieldType = Select options }



-- VIEW


view : Config msg -> Html msg
view (Config config) =
    div [ class "form-group" ]
        [ label [ for config.id ] [ text config.label ]
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

            _ ->
                input
                    [ id config.id
                    , type_ (typeToString config.fieldType)
                    , value config.value
                    , onInput config.onInput
                    , class "form-field__input"
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

        Number ->
            "number"

        Select _ ->
            "select"
