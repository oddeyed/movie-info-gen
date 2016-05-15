module FilmInfoGen exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Task

import FilmSearch exposing (..)
import OmdbJson exposing (..)


main =
    Html.program
        { init = init "cats"
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { topic : String
    , gifUrl : String
    , query : String
    , visible_query : String
    , year : Maybe Int
    }


init : String -> (Model, Cmd Msg)
init topic =
    ( Model topic "waiting.gif" "None" "Foobar" Nothing
    , lookup "" Nothing
    )



-- UPDATE


type Msg
    = DoSearch
    | NewQuery String
    | FetchSucceed SearchContainerModel
    | FetchFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        DoSearch ->
            ( { model | visible_query = model.query }, lookup model.query model.year )

        NewQuery string ->
            ( { model | query = string }, Cmd.none )

        FetchSucceed response ->
            ( model, Cmd.none )

        FetchFail _ ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "internal" ]
        {- We start with the title -}
        [ h1 []
            [ text "Film Info Generator" ]
        {- Next we have the div containing the search bar and button -}
        , div []
            [ input [ placeholder "Film Title to Search", floatLeft, onInput NewQuery ] []
            , button [ onClick DoSearch, searchBtn ] [ text "Search!" ]
            ]
        {- Next comes poster display, dropdown selection and year select -}
        , br [] []
        {- Then the resulting text, with "Copy xxx to clipboard" buttons -}
        , img [ src model.gifUrl ] []
        ]


floatLeft : Attribute a
floatLeft =
    style
        [ ( "width", "70%" )
        , ( "float", "left" )
        , ( "height", "40px" )
        , ( "font-family", "inherit" )
        , ( "font-size", "1em" )
        , ( "text-align", "center" )
        ]


searchBtn : Attribute a
searchBtn =
    style
        [ ( "width", "25%" )
        , ( "float", "right" )
        , ( "height", "40px" )
        , ( "font-size", "1em" )
        , ( "font-family", "inherit" )
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP

lookup : Title -> Maybe Year -> Cmd Msg
lookup movie year =
    Task.perform FetchFail FetchSucceed (search movie year)

decodeGifUrl : Json.Decoder String
decodeGifUrl =
    Json.at [ "data", "image_url" ] Json.string
