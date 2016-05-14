import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Task


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
    }


init : String -> ( Model, Cmd Msg )
init topic =
    ( Model topic "waiting.gif"
    , getRandomGif topic
    )



-- UPDATE


type Msg
    = MorePlease
    | FetchSucceed String
    | FetchFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        MorePlease ->
            ( model, getRandomGif model.topic )

        FetchSucceed newUrl ->
            ( Model model.topic newUrl, Cmd.none )

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
            [ input [ placeholder "Film Title to Search", floatLeft ] []
            , button [ onClick MorePlease, searchBtn ] [ text "Search!" ]
            ]
        {- Next comes poster display, dropdown selection and year select -}
        , div [] []
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


getRandomGif : String -> Cmd Msg
getRandomGif topic =
    let
        url =
            "http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=" ++ topic
    in
        Task.perform FetchFail FetchSucceed (Http.get decodeGifUrl url)


decodeGifUrl : Json.Decoder String
decodeGifUrl =
    Json.at [ "data", "image_url" ] Json.string
