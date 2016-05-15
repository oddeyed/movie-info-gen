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
import OmdbFilmData exposing (..)
import OmdbJson exposing (..)

import Debug


default_poster = "assets/default_poster.jpg"


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
    , posterURL : String
    , status : String
    , year : Maybe Int
    , results : List SearchResultModel
    , selectedIdx : String
    , generatedInfo : String
    }


init : String -> ( Model, Cmd Msg )
init query =
    ( Model query default_poster "starting up" Nothing [] "" "Loading..."
    , lookup query Nothing
    )



-- UPDATE


type Msg
    = DoSearch
    | NewQuery String
    | FetchSucceed SearchContainerModel
    | FetchFail Http.Error
    | FilmSelected String
    | GenSucceed FilmDataModel
    | GenFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        DoSearch ->
            ( { model | status = "Searching..." }, lookup model.query model.year )

        NewQuery string ->
            ( { model | query = string }, Cmd.none )

        FetchSucceed response ->
            ( { model | results = response.search
                        , status = unwrap response
                        , posterURL = autoGrabPoster response.search }
            , Cmd.none )

        FetchFail error ->
            ( { model | status = toString error }, Cmd.none )

        FilmSelected idx ->
            ( { model | selectedIdx = idx
                        , status = idx
                        , posterURL = ( grabPoster idx model.results ) }
            , getData model.selectedIdx )

        _ -> 
            ( model, Cmd.none )


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
                [ text "Film Info Generator" ]
              {- Next we have the div containing the search bar and button -}
            , div []
                -- TODO: Would be nice to have 'push enter' to search
                [ input [ placeholder "Film Title to Search", floatLeft, onInput NewQuery ] []
                , button [ onClick DoSearch, searchBtn ] [ text "Search!" ]
                ]
            ]
        , div [ class "internal", style [("width", "90%"), ("text-align", "left")] ]
            {- Next comes poster display, dropdown selection and year select -}
            [ select [ style [("text-align", "left"), ("width", "50%")], onChange FilmSelected ] (List.map filmOption model.results)
            , br [] []
            , img [ src model.posterURL, style [("max-width", "50%"), ("display", "inline-block")] ] []
            ]
        -- Then the resulting text, with "Copy xxx to clipboard" buttons
        , footer []
            [ hr [] []
            , text <| "Status is... " ++ model.status
            , br [] []
            , text "(c) oddeyed - "
            , a [ href "https://github.com/oddeyed/movie-info-gen" ] [ text "Source @ Github" ]
            ]
        ]


-- Go through the results and get the posterURL for the given idx
grabPoster : String -> (List SearchResultModel) -> String
grabPoster idx results =
    let
        shortlist = List.filter (\item -> item.imdbID == idx) results
        entry = List.head shortlist
    in
        case entry of
            Nothing -> default_poster
            Just res -> res.posterURL


-- Special grab poster function for the first loaded
autoGrabPoster : List SearchResultModel -> String
autoGrabPoster results =
    let 
        entry = List.head results
    in
        case entry of
            Nothing -> default_poster
            Just res -> res.posterURL


-- Event to detect change in selected film
onChange : (String -> msg) -> Attribute msg
onChange tagger =
  on "change" (Json.map tagger targetValue)

-- Converts a SearchResultModel to html description
filmOption : SearchResultModel -> Html msg
filmOption response =
    Html.option [ value response.imdbID ] [ text <| response.title ++ " (" ++ response.year ++ ")"]


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


getData : String -> Cmd Msg
getData imdbID =
    Task.perform GenFail GenSucceed (getFilmData imdbID)
