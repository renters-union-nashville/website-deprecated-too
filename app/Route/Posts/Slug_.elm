module Route.Posts.Slug_ exposing (ActionData, Data, route, RouteParams, Msg, Model)

{-|

@docs ActionData, Data, route, RouteParams, Msg, Model

-}

import BackendTask
import BackendTask.Custom
import Effect
import ErrorPage
import FatalError
import Head
import Html
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Markdown.Block exposing (Block)
import Markdown.Parser
import Markdown.Renderer
import PagesMsg exposing (PagesMsg)
import Platform.Sub
import Post
import RouteBuilder
import Server.Request exposing (Request)
import Server.Response
import Shared
import UrlPath
import View


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    { slug : String }


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.buildWithLocalState
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
        (RouteBuilder.serverRender { data = data, action = action, head = head })


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app shared =
    ( {}, Effect.none )


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect msg )
update app shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions :
    RouteParams
    -> UrlPath.UrlPath
    -> Shared.Model
    -> Model
    -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    { body : List Block
    }


type alias ActionData =
    {}


data :
    RouteParams
    -> Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response Data ErrorPage.ErrorPage)
data routeParams request =
    BackendTask.Custom.run "getPost"
        (Encode.string routeParams.slug)
        (Decode.nullable Post.decoder)
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\maybePost ->
                case maybePost of
                    Just post ->
                        let
                            parsed : Result String (List Block)
                            parsed =
                                post.body
                                    |> Markdown.Parser.parse
                                    |> Result.mapError (\_ -> "Invalid markdown.")
                        in
                        parsed
                            |> Result.mapError FatalError.fromString
                            |> Result.map
                                (\parsedMarkdown ->
                                    Server.Response.render
                                        { body = parsedMarkdown
                                        }
                                )
                            |> BackendTask.fromResult

                    Nothing ->
                        Server.Response.errorPage ErrorPage.NotFound
                            |> BackendTask.succeed
            )


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    []


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View.View (PagesMsg Msg)
view app shared model =
    { title = "Posts.Slug_"
    , body =
        [ Html.text "Here is your generated page!!!"
        , Html.div []
            (app.data.body
                |> Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer
                |> Result.withDefault []
            )
        ]
    }


action :
    RouteParams
    -> Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    BackendTask.succeed (Server.Response.render {})