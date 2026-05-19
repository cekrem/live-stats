module Types exposing (BackendModel, BackendMsg(..), Entry, FrontendModel, FrontendMsg(..), ToBackend(..), ToFrontend(..), computeStatsInterval, keepAliveInterval, maxSessionAge)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (ClientId)
import Time
import Url exposing (Url)



-- model


type alias FrontendModel =
    { key : Key
    , activePath : Maybe String
    , stats : Maybe (Dict String Int)
    }


type alias BackendModel =
    { stats : Dict String Entry
    }


type alias Entry =
    { timestamp : Time.Posix
    , slug : String
    }


type FrontendMsg
    = KeepAlive
    | UrlClicked UrlRequest
    | UrlChanged Url


type ToBackend
    = FrontendHeartbeat (Maybe String)


type BackendMsg
    = ClientDisconnected ClientId
    | ClientAlive (Maybe String) ClientId Time.Posix
    | Tick Time.Posix


type ToFrontend
    = StatsBroadcast (Dict String Int)



-- time constants


keepAliveInterval : number
keepAliveInterval =
    15000


computeStatsInterval : number
computeStatsInterval =
    5000


maxSessionAge : number
maxSessionAge =
    20000
