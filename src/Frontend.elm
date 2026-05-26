module Frontend exposing (Model, app)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attr
import HtmlHelpers
import Lamdera
import Time
import Types exposing (FrontendModel, FrontendMsg(..), ToBackend(..), ToFrontend(..), keepAliveInterval)
import Url exposing (Url)


type alias Model =
    FrontendModel


app : { init : Lamdera.Url -> Nav.Key -> ( Model, Cmd FrontendMsg ), view : Model -> Browser.Document FrontendMsg, update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg ), updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg ), subscriptions : Model -> Sub FrontendMsg, onUrlRequest : UrlRequest -> FrontendMsg, onUrlChange : Url.Url -> FrontendMsg }
app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions =
            always <|
                Sub.batch
                    [ Time.every keepAliveInterval (always KeepAlive)
                    ]
        , view = view
        }


init : Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , stats = Nothing
      , activePath = url.query
      }
    , Lamdera.sendToBackend (FrontendHeartbeat url.query)
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( { model | activePath = url.query }
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged _ ->
            ( model, Cmd.none )

        KeepAlive ->
            ( model, Lamdera.sendToBackend (FrontendHeartbeat model.activePath) )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        StatsBroadcast stats ->
            ( { model | stats = Just stats }, Cmd.none )


view : Model -> Browser.Document FrontendMsg
view model =
    { title = "Live Stats!"
    , body =
        case ( model.stats, model.activePath ) of
            ( Nothing, _ ) ->
                []

            ( Just stats, Nothing ) ->
                [ viewDashboard stats, viewFooter ]

            ( Just stats, Just activePath ) ->
                [ HtmlHelpers.maybeNode viewSingleEntry (stats |> Dict.get activePath)
                ]
    }


viewDashboard : Dict String Int -> Html msg
viewDashboard stats =
    Html.table []
        [ Html.tbody []
            (Html.tr
                []
                [ Html.th [] [ Html.text "url" ]
                , Html.th [] [ Html.text "visitors" ]
                ]
                :: (stats
                        |> Dict.toList
                        |> List.sortBy (negate << Tuple.second)
                        |> List.map
                            (\( url, n ) ->
                                Html.tr []
                                    [ Html.td [] [ Html.a [ Attr.href url ] [ Html.text url ] ]
                                    , Html.td [] [ Html.text (String.fromInt n) ]
                                    ]
                            )
                   )
            )
        ]


viewSingleEntry : Int -> Html msg
viewSingleEntry n =
    Html.a
        [ Attr.href "https://livestats.lamdera.app"
        , Attr.target "_top"
        ]
        (case n of
            1 ->
                [ Html.text "One person reading this right now" ]

            many ->
                [ Html.text <| String.fromInt many
                , Html.text " people reading this right now"
                ]
        )


viewFooter : Html msg
viewFooter =
    Html.footer []
        [ Html.a [ Attr.href "https://cekrem.github.io" ] [ Html.text "made by cekrem" ]
        , Html.text " · "
        , Html.a [ Attr.href "https://github.com/cekrem/live-stats" ] [ Html.text "source" ]
        ]
