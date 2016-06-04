module DataTemplates exposing (..)

import String exposing (contains)
import OmdbJson exposing (FilmDataModel)
import Template exposing (template, render, withString, withValue)


type alias FilmResultsModel = 
    { cast : String
    , director : String
    , writers : String
    , synopsis : String 
    , writerLabel : String
    , directorLabel : String
    }


rawTemplate =
    template "<hr><p><strong><u>INFORMATION</u></strong</p>"
        |> withString "<p><strong>CAST: "
        |> withValue .cast
        |> withString "</strong></p>"
        |> withString "<p><strong>"
        |> withValue .directorLabel
        |> withString ": "
        |> withValue .director
        |> withString "</strong></p>"
        |> withString "<p><strong>"
        |> withValue .writerLabel 
        |> withString ": "
        |> withValue .writers
        |> withString "</strong></p>"
        |> withString "<p><strong>SYNOPSIS: "
        |> withValue .synopsis
        |> withString "</strong></p>"


rawBuild : FilmDataModel -> String
rawBuild data =
    let
        filmData = dataPrepare data
    in
        render rawTemplate filmData


dataPrepare : FilmDataModel -> FilmResultsModel
dataPrepare data =
    let
        base = (FilmResultsModel "" "" "" "" "" "")
    in
        { base 
            | writerLabel = if (multiple data.writers) then
                    "WRITERS"
                else
                    "WRITER"
            , directorLabel = if (multiple data.director) then
                    "DIRECTORS"
                else
                    "DIRECTOR"
            , director = data.director
            , cast = data.cast
            , synopsis = data.synopsis
            , writers =data.writers
        }

multiple : String -> Bool
multiple record =
    if contains "," record then True else False