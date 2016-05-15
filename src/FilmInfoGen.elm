module FilmInfoGen exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Task
import List
import FilmSearch exposing (..)
import OmdbJson exposing (..)


main =
    Html.program
        { init = init "A Room with a View"
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { query : String
    , gifUrl : String
    , status : String
    , year : Maybe Int
    }


init : String -> ( Model, Cmd Msg )
init query =
    ( Model query "waiting.gif" "starting up" Nothing
    , lookup "Star Wars" Nothing
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
            ( { model | status = "Searching..." }, lookup model.query model.year )

        NewQuery string ->
            ( { model | query = string }, Cmd.none )

        FetchSucceed response ->
            ( { model | status = unwrap response }, Cmd.none )

        FetchFail error ->
            ( { model | status = toString error }, Cmd.none )


unwrap : SearchContainerModel -> String
unwrap searchcontainer =
    let
        top =
            List.head searchcontainer.search
    in
        case top of
            Just result ->
                result.imdbID

            Nothing ->
                "Empty"



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "internal" ]
        [ div [ class "internal" ]
            {- We start with the title -}
            [ h1 []
                [ text "Film Info Generatorx`" ]
              {- Next we have the div containing the search bar and button -}
            , div []
                -- TODO: Would be nice to have 'push enter' to search
                [ input [ placeholder "Film Title to Search", floatLeft, onInput NewQuery, onSubmit DoSearch ] []
                , button [ onClick DoSearch, searchBtn ] [ text "Search!" ]
                ]
            ]
        , div []
            {- Next comes poster display, dropdown selection and year select -}
            [ br [] [] {- Then the resulting text, with "Copy xxx to clipboard" buttons -}
            , img [ src model.gifUrl ] []
            ]
        , footer []
            [ hr [] []
            , text <| "Status is... " ++ model.status
            , br [] []
            , text "(c) oddeyed - "
            , a [ href "https://github.com/oddeyed/movie-info-gen" ] [ text "Source @ Github" ]
            ]
        ]


floatLeft : Attribute a
floatLeft =
    style
        [ ( "width", "70%" )
        , ( "right", "0px" )
        , ( "height", "40px" )
        , ( "font-family", "inherit" )
        , ( "font-size", "1em" )
        , ( "text-align", "center" )
        ]


searchBtn : Attribute a
searchBtn =
    style
        [ ( "width", "25%" )
        , ( "left", "0px" )
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
