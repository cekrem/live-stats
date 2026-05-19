module Backend exposing (Model, app)

import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Task
import Time
import Types exposing (BackendModel, BackendMsg(..), Entry, ToBackend(..), ToFrontend(..))



-- init


type alias Model =
    BackendModel


app : { init : ( Model, Cmd BackendMsg ), update : BackendMsg -> Model -> ( Model, Cmd BackendMsg ), updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg ), subscriptions : Model -> Sub BackendMsg }
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions =
            always <|
                Sub.batch
                    [ Lamdera.onDisconnect <| always ClientDisconnected
                    , Time.every 5000 Tick
                    ]
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { stats = Dict.empty }
    , Cmd.none
    )



-- update


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        Tick now ->
            let
                isProbablyStillConnected { timestamp } =
                    Time.posixToMillis timestamp > Time.posixToMillis now - 20000

                prunedModel =
                    { model
                        | stats =
                            model.stats
                                |> Dict.filter (always isProbablyStillConnected)
                    }
            in
            broadcastStats prunedModel

        ClientDisconnected clientId ->
            ( { model | stats = model.stats |> Dict.remove clientId }, Cmd.none )

        ClientAlive Nothing _ _ ->
            broadcastStats model

        ClientAlive (Just slug) clientId timestamp ->
            let
                newModel =
                    { model
                        | stats =
                            model.stats
                                |> Dict.insert clientId
                                    { slug = slug
                                    , timestamp = timestamp
                                    }
                    }
            in
            broadcastStats newModel


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        FrontendHeartbeat maybeSlug ->
            ( model, Task.perform (ClientAlive maybeSlug clientId) Time.now )


broadcastStats : { a | stats : Dict k Entry } -> ( { a | stats : Dict k Entry }, Cmd BackendMsg )
broadcastStats model =
    ( model, Lamdera.broadcast <| StatsBroadcast (model |> computedStats) )


computedStats : { a | stats : Dict k Entry } -> Dict String Int
computedStats model =
    let
        incrementSlug : String -> Dict String Int -> Dict String Int
        incrementSlug slug =
            Dict.update slug (Maybe.withDefault 0 >> (+) 1 >> Just)
    in
    (model.stats
        |> Dict.map (always .slug)
    )
        |> Dict.foldl (always incrementSlug) Dict.empty
