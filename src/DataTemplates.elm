module DataTemplates exposing (..)

import OmdbJson exposing (FilmDataModel)
import Template exposing (template, render, withString, withValue)


rawTemplate =
    template "<hr><p><strong><u>INFORMATION</u></strong</p>"
        |> withString "<p><strong>CAST: "
        |> withValue .cast
        |> withString "</strong></p>"
        |> withString "<p><strong>DIRECTOR: "
        |> withValue .director
        |> withString "</strong></p>"
        |> withString "<p><strong>WRITERS: "
        |> withValue .writers
        |> withString "</strong></p>"
        |> withString "<p><strong>SYNOPSIS: "
        |> withValue .synopsis
        |> withString "</strong></p>"


rawBuild : FilmDataModel -> String
rawBuild data =
    render rawTemplate data
