module OmdbFilmData exposing (getFilmData)

import Http exposing (url, post, empty, Error)
import Task exposing (Task)
import OmdbJson exposing (..)


getFilmData : String -> Task Error FilmDataModel
getFilmData imdbID =
    let
        request =
            getUrl imdbID
    in
        -- decode with filmDataDecoder from url reqest with empty body
        post filmDataDecoder request empty


getUrl : String -> String
getUrl imdbID =
    let
        addr =
            "https://www.omdbapi.com/"

        arglist =
            [ ( "i", imdbID ), ( "plot", "full" ), ( "r", "json" ) ]
    in
        url addr arglist
