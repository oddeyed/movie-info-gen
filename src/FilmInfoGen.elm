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
    , generatedType : GenInfoType
    }


type GenInfoType
    = RawHTML
    | Rendered


init : String -> ( Model, Cmd Msg )
init query =
    -- Start with A Room with a View's IMDB ID
    ( Model query default_poster "starting up" Nothing [] "tt0091867" "loading" RawHTML
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
    | ChangeOutput GenInfoType


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        DoSearch ->
            ( { model | status = "Searching..." }, lookup model.query model.year )

        NewQuery string ->
            ( { model
                | query = string
                , status = "Pending..."
              }
            , Cmd.none
            )

        FetchSucceed response ->
            ( { model
                | results = response.search
                , status = "OMDB Search Response in..."
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
                , status = "Selected " ++ idx ++ "..."
                , posterURL = (grabPoster idx model.results)
              }
            , getData idx
            )

        GetFail error ->
            ( { model | status = toString error }, Cmd.none )

        GetSucceed data ->
            ( { model
                | generatedInfo = genDescription data
                , status = "Generated text for " ++ model.selectedIdx
              }
            , Cmd.none
            )

        ChangeOutput opt ->
            ( { model
                | generatedType = opt
              }
            , Cmd.none
            )


genDescription : FilmDataModel -> String
genDescription data =
    rawBuild data



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
            , outputBox model
            ]
          {- Then the page footer -}
        , pageFooter model
        ]


outputBox model =
    div [ class "outputBox" ]
        [ radio RawHTML "Raw HTML" model
        , radio Rendered "Formatted" model
        , resultsBox model
        ]


radio opt name model =
    let
        isSelected =
            model.generatedType == opt
    in
        label []
            [ input [ type' "radio", checked isSelected, onCheck (\_ -> ChangeOutput opt) ] []
            , text name
            ]


resultsBox model =
    let
        helptext =
            "To copy, click in the box and use Ctrl+A "
                ++ "(Cmd+A on Mac), then Ctrl+C (Cmd+C on Mac)."
    in
        case model.generatedType of
            Rendered ->
                div [ class "resultsBox" ]
                    [ iframe [ class "results", srcdoc model.generatedInfo ] []
                    , p [] [ text helptext ]
                    ]

            RawHTML ->
                div [ class "resultsBox" ]
                    [ div [ class "results" ] [ text model.generatedInfo ]
                    , p [] [ text helptext ]
                    ]


dropDown model =
    div [ style [ ( "width", "50%" ) ] ]
        [ select [ class "dropDown", onChange FilmSelected ] (List.map filmOption model.results)
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
        , text <| "Status is... <" ++ model.status ++ ">"
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
