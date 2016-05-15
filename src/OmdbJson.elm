module OmdbJson exposing (..)

import Json.Decode
    exposing
        ( Decoder
        , (:=)
        , list
        , string
        , object1
        , object5
        )


type alias SearchContainerModel =
    { search : List SearchResultModel }


type alias SearchResultModel =
    { title : String
    , year : String
    , imdbID : String
    , entryType : String
    , posterURL : String
    }



{--Responses have five values, e.g.
    {
        "Title": "Star Wars: Episode IV - A New Hope",
        "Year": "1977",
        "imdbID": "tt0076759",
        "Type": "movie",
        "Poster": "http://ia.media-imdb.com/[snipped].jpg"
    }
And the overall structure is
    "Search": [List Response]
--}


searchResultDecoder : Decoder SearchResultModel
searchResultDecoder =
    object5 SearchResultModel
        ("Title" := string)
        ("Year" := string)
        ("imdbID" := string)
        ("Type" := string)
        ("Poster" := string)


searchContainerDecoder : Decoder SearchContainerModel
searchContainerDecoder =
    object1 SearchContainerModel
        ("Search" := list searchResultDecoder)
