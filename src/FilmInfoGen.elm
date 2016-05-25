module FilmInfoGen exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import String exposing (toInt)
import Task
import List
import FilmSearch exposing (..)
import OmdbFilmData exposing (..)
import OmdbJson exposing (..)
import DataTemplates exposing (..)
import Result exposing (Result, toMaybe, andThen)


default_poster =
    "assets/default_poster.jpg"

base_image_addr =
    "https://search.rhbrook.co.uk:5000/img/"


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
    , yearEnabled : Bool
    , results : List SearchResultModel
    , selectedIdx : String
    , generatedInfo : String
    , generatedType : GenInfoType
    , yearInput : String
    }


type GenInfoType
    = RawHTML
    | Rendered


init : String -> ( Model, Cmd Msg )
init query =
    -- Start with A Room with a View's IMDB ID
    ( Model query default_poster "starting up" False [] "tt0091867" "loading" Rendered ""
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
    | ChangeYearOpt Bool
    | NewYear String


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        DoSearch ->
            -- Add real function implementation to check the state of 'year' and use yearInput accordingly
            ( { model | status = "Searching..." }, lookup model.query (assignYear model) )

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
                , generatedInfo = "loading"
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

        ChangeYearOpt status ->
            ( { model | yearEnabled = status }, Cmd.none )

        NewYear input ->
            ( { model | yearInput = input }, Cmd.none )


genDescription : FilmDataModel -> String
genDescription data =
    rawBuild data


assignYear model =
    if model.yearEnabled then
        toMaybe (toInt model.yearInput)
    else
        Nothing



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "internal" ]
        [ div [ class "internal" ]
            {- We start with the title
               Then we have the div containing the search bar and button
            -}
            [ h1 [] [ text "Film Info Generator" ]
            , div [] [ inputArea model ]
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
        [ outputRadio RawHTML "Raw HTML" model
        , outputRadio Rendered "Formatted" model
        , resultsBox model
        ]


outputRadio opt name model =
    let
        isSelected =
            model.generatedType == opt

        changeHandler = 
            \_ -> ChangeOutput opt

        radioAttr =
            [ type' "radio", checked isSelected, onCheck changeHandler ]
    in
        label []
            [ input radioAttr []
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
    let
        filmOption =
            filmOptionFactory model

        opts =
            List.map filmOption model.results
    in
        div [ style [ ( "width", "50%" ) ] ]
            [ select [ class "dropDown", onChange FilmSelected ] opts
            , br [] []
            , img [ class "poster", src model.posterURL ] []
            ]


inputArea model =
    let 
        searchAttr = 
            [ placeholder "Film Title to Search", class "searchBar", onInput NewQuery ]

        buttonAttr = 
            [ onClick DoSearch, class "searchBtn" ]

        checkAttr =
            [ type' "checkbox", onCheck ChangeYearOpt, class "yearCheck" ]

        yearAttr =
            [ type' "number", onInput NewYear, disabled (not model.yearEnabled), class "yearBox", placeholder "Refine year" ]

    in
        Html.form [ onSubmit DoSearch ]
            [ div [ class "inputArea" ]
                [ input searchAttr []
                , button buttonAttr [ text "Search!" ]
                ]
            , div [ class "yearInput" ]
                [ input yearAttr []
                , input checkAttr []
                ]
            ]
        

pageFooter model =
    footer []
        [ hr [] []
        , span [ class "footerText" ]
            [ text <| "Status is... <" ++ model.status ++ ">"
            , br [] []
            , p []
                [ text "Website (c) oddeyed 2016 - Data from the OMDB API and IMDB images. "
                , text "Please submit issues and feature requests to "
                , a [ href "https://github.com/oddeyed/movie-info-gen" ] [ text "the project Github." ]
                ]
            , text "If you want to report a problem, please include the \"Status\" which can be found just above this text."
            ]
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
                base_image_addr ++ res.imdbID



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


filmOptionFactory : Model -> (SearchResultModel -> Html msg)
filmOptionFactory model =
    \resp ->
        let
            isSelected =
                model.selectedIdx == resp.imdbID
        in
            Html.option [ value resp.imdbID, selected isSelected ]
                [ text <| resp.title ++ " (" ++ resp.year ++ ")" ]



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
