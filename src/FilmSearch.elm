module FilmSearch exposing (search, Title, Year) 

import Http exposing (url, post, empty, Error)
import Task exposing (Task)
import Maybe exposing (Maybe)

import OmdbJson exposing (..)

type alias Title = String
type alias Year = Int

type SearchMsg
    = FetchOK SearchContainerModel
    | FetchBad Error

search : Title -> Maybe Year -> Task Error SearchContainerModel
search movie year =
    let 
        request = getUrl movie year
    in
        -- decode with searchContainerDecode from url reqest with empty body
        post searchContainerDecoder request empty


getUrl : Title -> Maybe Year -> String
getUrl movie year =
    let
        addr = "http://www.omdbapi.com/?"
        arglist = [("s", movie), ("type", "movie"), ("r", "json")]
    in
        case year of
            Nothing -> 
                url addr arglist
            Just year ->
                url addr <| arglist ++ [("year",  toString year)]
