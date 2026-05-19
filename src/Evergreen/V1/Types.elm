module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Lamdera
import Time
import Url


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , activePath : Maybe String
    , stats : Maybe (Dict.Dict String Int)
    }


type alias Entry =
    { timestamp : Time.Posix
    , slug : String
    }


type alias BackendModel =
    { stats : Dict.Dict String Entry
    }


type FrontendMsg
    = KeepAlive
    | UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url


type ToBackend
    = FrontendHeartbeat (Maybe String)


type BackendMsg
    = ClientDisconnected Lamdera.ClientId
    | ClientAlive (Maybe String) Lamdera.ClientId Time.Posix
    | Tick Time.Posix


type ToFrontend
    = StatsBroadcast (Dict.Dict String Int)
