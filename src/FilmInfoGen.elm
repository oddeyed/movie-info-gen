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
import DataTemplates exposing (..)
import Debug


default_poster =
    "assets/default_poster.jpg"
<<<<<<< 2a2eac5c88feff98eeaa86c0ca4d6a0c3a8f3191
default_description = 
    (p [style [("float", "right")]] [text "Loading..."])
=======


default_description =
    (p [ style [ ( "float", "right" ) ] ] [ text "Loading..." ])
>>>>>>> Running everything through the linter


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
    , generatedInfo : Html Msg
    }


init : String -> ( Model, Cmd Msg )
init query =
    -- Start with A Room with a View's IMDB ID
    ( Model query default_poster "starting up" Nothing [] "tt0091867" default_description
    , lookup query Nothing
    )



-- UPDATE


type Msg
    = DoSearch
    | NewQuery String
    | FetchSucceed SearchContainerModel
    | FetchFail Http.Error
    | FilmSelected String
    | GetSucceed FilmDataModel
    | GetFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        DoSearch ->
            ( { model | status = "Searching..." }, lookup model.query model.year )

        NewQuery string ->
            ( { model | query = string }, Cmd.none )

        FetchSucceed response ->
            ( { model
                | results = response.search
                , status = unwrap response
                , selectedIdx = autoGetID response.search
                , posterURL = grabPoster (autoGetID response.search) response.search
              }
            , getData model.selectedIdx
            )

        FetchFail error ->
            ( { model | status = toString error }, Cmd.none )

        FilmSelected idx ->
            ( { model
                | selectedIdx = idx
                , status = idx
                , posterURL = (grabPoster idx model.results)
              }
            , getData model.selectedIdx
            )

        GetFail error ->
            ( { model | status = toString error }, Cmd.none )

        GetSucceed data ->
            ( { model | generatedInfo = genDescription data }, Cmd.none )


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


genDescription : FilmDataModel -> Html Msg
genDescription data =
    (p [ style [ ( "text-align", "right" ), ( "display", "inline-block" ) ] ] [ text (rawBuild data) ])



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "internal" ]
        [ div [ class "internal" ]
            {- We start with the title
               Then we have the div containing the search bar and button
            -}
            [ h1 [] [ text "Film Info Generator" ]
            , div [] [ inputArea ]
            ]
          {- Then container of dropdown and results box -}
        , div [ class "container" ]
            [ dropDown model
            , resultsBox model
            ]
          {- Then the page footer -}
        , pageFooter model
        ]


resultsBox model =
    div [ class "resultsBox" ]
        [ text model.generatedInfo ]


dropDown model =
    div [ style [ ( "width", "50%" ) ] ]
        [ select [ onChange FilmSelected ] (List.map filmOption model.results)
        , br [] []
        , img [ src model.posterURL ] []
        ]


inputArea =
    Html.form [ onSubmit DoSearch ]
        -- TODO: Would be nice to have 'push enter' to search
        [ input [ placeholder "Film Title to Search", class "searchBar", onInput NewQuery ] []
        , button [ onClick DoSearch, class "searchBtn" ] [ text "Search!" ]
        ]


pageFooter model =
    footer []
        [ hr [] []
        , text <| "Status is... " ++ model.status
        , br [] []
        , text "(c) oddeyed - "
        , a [ href "https://github.com/oddeyed/movie-info-gen" ] [ text "Source @ Github" ]
        ]


-- Go through the results and get the posterURL for the given idx


grabPoster : String -> List SearchResultModel -> String
grabPoster idx results =
    let
        shortlist =
            List.filter (\item -> item.imdbID == idx) results

        entry =
            List.head shortlist
    in
        case entry of
            Nothing ->
                default_poster

            Just res ->
                res.posterURL



-- Special grab poster function for the first loaded


autoGetID : List SearchResultModel -> String
autoGetID results =
    let
        entry =
            List.head results
    in
        case entry of
            Nothing ->
                "0"

            Just res ->
                res.imdbID



-- Event to detect change in selected film


onChange : (String -> msg) -> Attribute msg
onChange tagger =
    on "change" (Json.map tagger targetValue)



-- Converts a SearchResultModel to html description


filmOption : SearchResultModel -> Html msg
filmOption response =
    Html.option [ value response.imdbID ] [ text <| response.title ++ " (" ++ response.year ++ ")" ]


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


filmOption : SearchResultModel -> Html msg
filmOption response =
    Html.option [ value response.imdbID ] [ text <| response.title ++ " (" ++ response.year ++ ")" ]



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
    Task.perform GetFail GetSucceed (getFilmData imdbID)
