port module Main exposing (..)


import Array exposing (Array)
import Char
import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Http
import Json.Decode as Json
import Random
import String
import Tuple

import Constituencies
import Country
import PetitionList exposing (PetitionList)


-- MODEL


type AppState
    = Home
    | Loading
    | Loaded Petition
    | Failed Http.Error


type View
    = Detail
    | Summary
    | CountryData
    | ConstituencyData


type Modal
    = FAQ
    | MyPetitions


type PetitionState
    = Open
    | Closed Date
    | Rejected Date


makePetitionStateDecoder : String -> Json.Decoder PetitionState
makePetitionStateDecoder state =
    case String.toLower (String.trim state) of
        "open" ->
            Json.succeed Open
        "closed" ->
            Json.map Closed (Json.at ["data", "attributes", "closed_at"] dateDecoder)
        "rejected" ->
            Json.map Rejected (Json.at ["data", "attributes", "rejected_at"] dateDecoder)
        _ ->
            Json.fail ("Unexpected petition state " ++ state)


type alias Country =
    { name : String
    , signatures : Int
    , isUK : Bool
    , isEU : Bool
    }


countryDecoder : Json.Decoder Country
countryDecoder =
    Json.map4 Country
        (Json.field "name" Json.string)
        (Json.field "signature_count" Json.int)
        -- Look up UK membership using the country code.
        (Json.field "code" (Json.map Country.isUK Json.string))
        -- Look up EU membership using the country code.
        (Json.field "code" (Json.map Country.isEU Json.string))


type alias Constituency =
    { name : String
    -- MP can be null (due to death, resignation etc).
    , mp : Maybe String
    , signatures : Int
    , info : Maybe Constituencies.Item
    }


constituencyDecoder : Json.Decoder Constituency
constituencyDecoder =
    Json.map4 Constituency
        (Json.field "name" Json.string)
        (Json.field "mp" (Json.nullable Json.string))
        (Json.field "signature_count" Json.int)
        -- Look up constituency info using the ONS code.
        (Json.field "ons_code" (Json.map Constituencies.get Json.string))


type alias Petition =
    { url : String
    , title : String
    , description : List String
    -- Creator is null for closed/rejected petitions.
    , creator : Maybe String
    , created : Date
    , state : PetitionState
    , signatures : Int
    , countries : List Country
    , constituencies : List Constituency
    }


petitionDecoder : Json.Decoder Petition
petitionDecoder =
    let
        andMap : Json.Decoder a -> Json.Decoder (a -> b) -> Json.Decoder b
        andMap =
            Json.map2 (|>)
    in
    Json.succeed Petition
        |> andMap (Json.at ["links", "self"] Json.string)
        |> andMap (Json.at ["data", "attributes", "action"] Json.string)
        |> andMap (Json.map2 (++)
                    (Json.at ["data", "attributes", "background"] linesDecoder)
                    (Json.at ["data", "attributes", "additional_details"] linesDecoder)
                  )
        |> andMap (Json.at ["data", "attributes", "creator_name"] (Json.nullable Json.string))
        |> andMap (Json.at ["data", "attributes", "created_at"] dateDecoder)
        |> andMap (Json.andThen makePetitionStateDecoder
                    (Json.at ["data", "attributes", "state"] Json.string)
                  )
        |> andMap (Json.at ["data", "attributes", "signature_count"] Json.int)
        |> andMap (Json.at ["data", "attributes", "signatures_by_country"] (Json.list countryDecoder))
        |> andMap (Json.at ["data", "attributes", "signatures_by_constituency"] (Json.list constituencyDecoder))


type SortBy
    = SortByCountry
    | SortByConstituency
    | SortBySignatures


type SortOrder
    = Asc
    | Desc


defaultSortOrder : SortBy -> SortOrder
defaultSortOrder by =
    case by of
        SortByCountry ->
            Asc
        SortByConstituency ->
            Asc
        SortBySignatures ->
            Desc


type alias SortOptions =
    { by : SortBy
    , order : SortOrder
    }


defaultSortOptions : SortOptions
defaultSortOptions =
    { by = SortBySignatures
    , order = defaultSortOrder SortBySignatures
    }


type CountryFilter
    = NonUK
    | NonEU
    | All


type GroupBy
    = GroupByRegion
    | GroupByCountry


type alias ReportOptions =
    { topCountryFilter : CountryFilter
    , constituencyGrouping : GroupBy
    , countrySortOptions : SortOptions
    , constituencySortOptions : SortOptions
    }


defaultReportOptions : ReportOptions
defaultReportOptions =
    { topCountryFilter = NonUK
    , constituencyGrouping = GroupByRegion
    , countrySortOptions = defaultSortOptions
    , constituencySortOptions = defaultSortOptions
    }


type alias Model =
    { logging : Bool
    , state : AppState
    , view : View
    , options : ReportOptions
    , modal : Maybe Modal
    , recent : PetitionList
    , saved : PetitionList
    , urlGenerator : Maybe (Random.Generator String)
    , input : String
    }


initialModel : Model
initialModel =
    { logging = False
    , state = Home
    , view = Summary
    , options = defaultReportOptions
    , modal = Nothing
    , recent = []
    , saved = []
    , urlGenerator = Nothing
    , input = ""
    }


-- UPDATE


-- Fetch the local storage value for a given key.
-- Result is returned via the onLocalStorage port.
port getLocalStorage : String -> Cmd msg


-- Set the local storage value for a given key.
port setLocalStorage : (String, String) -> Cmd msg


type Msg
    -- User actions
    = Start
    | LoadPetition Bool String
    | LoadRandomPetition
    | SetView View
    | ShowModal Modal
    | HideModal
    | SavePetition PetitionList.Item
    | UnsavePetition PetitionList.Item
    -- User inputs
    | UpdateInput String
    -- HTTP/JS Callbacks
    | OnHttpError Http.Error
    | OnPetitionLoaded Petition
    | OnRandomUrlsLoaded (Array String)
    | OnLocalStorage String (Maybe String)
    -- Options
    | SortCountryData SortBy
    | SortConstituencyData SortBy
    | FilterTopCountries CountryFilter
    | GroupConstituencies GroupBy
    -- Misc
    | BatchUpdate (List Msg)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        options : ReportOptions
        options =
            model.options

        log : a -> a
        log =
            if model.logging then
                Debug.log "update"
            else
                identity
    in
    case log msg of

        Start ->
            let
                model_ =
                    { model
                        | state = Home
                    }
            in
            (,) model_ Cmd.none

        LoadPetition reloading url ->
            let
                model_ =
                    if reloading then
                        { model
                            | state = Loading
                        }
                    else
                        { model
                            | state = Loading
                            , view = Summary
                            , options = defaultReportOptions
                        }
            in
            (,) model_ (fetchPetition url)

        OnPetitionLoaded petition ->
            let
                recent_ =
                    model.recent
                        |> PetitionList.add { url = petition.url, title = petition.title }

                model_ =
                    { model
                        | state = Loaded petition
                        , recent = recent_
                    }

                cmd =
                    setLocalStorage ("recent.petitions", (PetitionList.toJson recent_))
            in
            (,) model_ cmd

        LoadRandomPetition ->
            case model.urlGenerator of
                Just generator ->
                    (,) model (Random.generate (LoadPetition False) generator)
                Nothing ->
                    let
                        model_ =
                            { model
                                | state = Loading
                            }
                    in
                    (,) model_ fetchRandomUrls

        OnRandomUrlsLoaded urls ->
            let
                indexGenerator : Random.Generator Int
                indexGenerator =
                    Random.int 0 (Array.length urls - 1)

                getUrl : Int -> String
                getUrl index =
                    Array.get index urls
                        |> Maybe.withDefault defaultUrl

                model_ =
                    { model
                        | urlGenerator = Just (Random.map getUrl indexGenerator)
                    }
            in
            update LoadRandomPetition model_

        OnHttpError err ->
            let
                model_ =
                    { model
                        | state = Failed err
                    }
            in
            (,) model_ Cmd.none

        OnLocalStorage key (Just value) ->
            let
                model_ =
                    if key == "recent.petitions" then
                        { model
                            | recent = PetitionList.fromJson value
                        }
                    else if key == "saved.petitions" then
                        { model
                            | saved = PetitionList.fromJson value
                        }
                    else
                        model
            in
            (,) model_ Cmd.none

        OnLocalStorage _ Nothing ->
            (,) model Cmd.none

        SavePetition item ->
            updateSavedPetitions (PetitionList.add item model.saved) model

        UnsavePetition item ->
            updateSavedPetitions (PetitionList.remove item model.saved) model

        ShowModal modal ->
            (,) (updateModal (Just modal) model) Cmd.none

        HideModal ->
            (,) (updateModal Nothing model) Cmd.none

        SetView view ->
            let
                model_ =
                    { model
                        | view = view
                    }
            in
            (,) model_ Cmd.none

        UpdateInput input ->
            let
                model_ =
                    { model
                        | input = input
                    }
            in
            (,) model_ Cmd.none

        SortCountryData by ->
            let
                options_ =
                    { options
                        | countrySortOptions = updateSortOptions by options.countrySortOptions
                    }
            in
            (,) (updateReportOptions options_ model) Cmd.none

        SortConstituencyData by ->
            let
                options_ =
                    { options
                        | constituencySortOptions = updateSortOptions by options.constituencySortOptions
                    }
            in
            (,) (updateReportOptions options_ model) Cmd.none

        FilterTopCountries filter ->
            let
                options_ =
                    { options
                        | topCountryFilter = filter
                    }
            in
            (,) (updateReportOptions options_ model) Cmd.none

        GroupConstituencies by ->
            let
                options_ =
                    { options
                        | constituencyGrouping = by
                    }
            in
            (,) (updateReportOptions options_ model) Cmd.none

        -- TODO: Is there a better way to do handle multiple
        -- updates?
        --
        -- In some cases a single user action needs to trigger
        -- more than one action in the program. For example,
        -- when you select a petition from the My Petitions
        -- modal screen, the app has to close the modal AND
        -- THEN load the petition. That involves two separate
        -- Msgs: HideModal and LoadPetition.
        --
        -- BatchUpdate is a flexible way to handle these cases.
        -- It takes an arbitrary list of Msgs and calls update
        -- for each one in turn. The returned Model contains
        -- all of the accumulated changes from each call to
        -- update. The returned Cmd is the one from THE FINAL
        -- CALL to update. Any other Cmds generated along the
        -- way are discarded. Use with caution!
        BatchUpdate msgs ->
            let
                update_ : Msg -> (Model, Cmd Msg) -> (Model, Cmd Msg)
                update_ msg (model, _) =
                    update msg model
            in
            List.foldl update_ (model, Cmd.none) msgs


updateModal : (Maybe Modal) -> Model -> Model
updateModal maybeModal model =
    { model
        | modal = maybeModal
    }


updateReportOptions : ReportOptions -> Model -> Model
updateReportOptions options model =
    { model
        | options = options
    }


updateSavedPetitions : PetitionList -> Model -> (Model, Cmd Msg)
updateSavedPetitions petitions model =
    let
        model_ =
            { model
                | saved = petitions
            }

        cmd =
            setLocalStorage ("saved.petitions", (PetitionList.toJson petitions))
    in
    (,) model_ cmd


updateSortOptions : SortBy -> SortOptions -> SortOptions
updateSortOptions by opts =
    let
        order =
            if opts.by == by then
                case opts.order of
                    Asc ->
                        Desc
                    Desc ->
                        Asc
            else
                defaultSortOrder by
    in
    { by = by
    , order = order
    }


fetch : (a -> Msg) -> Json.Decoder a -> String -> Cmd Msg
fetch onSuccess decoder url =
    let
        handleResult : Result Http.Error a -> Msg
        handleResult result =
            case result of
                Ok a ->
                    onSuccess a
                Err err ->
                    OnHttpError err
    in
    Http.send handleResult (Http.get url decoder)


fetchPetition : String -> Cmd Msg
fetchPetition url =
    fetch OnPetitionLoaded petitionDecoder (withJsonExtension url)


fetchRandomUrls : Cmd Msg
fetchRandomUrls =
    let
        url : String
        url =
            urlWithParams [("state", "open")]

        decoder : Json.Decoder (Array String)
        decoder =
            Json.field "data" (Json.array (Json.at ["links", "self"] Json.string))
    in
    fetch OnRandomUrlsLoaded decoder url


-- VIEW


type alias Link =
    { text : String
    , msg : Msg
    , title : Maybe String
    , class : Maybe String
    , icon : Maybe String
    }


type PageType
    = NormalPage
    | ModalPage String


type alias Page =
    { type_ : PageType
    , class : Maybe String
    , title : String
    , content : List (Html Msg)
    , navitems : List Link
    , menuitems : List Link
    }


blankPage : Page
blankPage =
    { type_ = NormalPage
    , class = Nothing
    , title = ""
    , content = []
    , navitems = []
    , menuitems = []
    }


view : Model -> Html Msg
view model =
    case model.modal of
        Just FAQ ->
            renderFAQPage
        Just MyPetitions ->
            renderMyPetitionsPage model.saved model.recent
        Nothing ->
            case model.state of
                Home ->
                    renderHomePage model
                Loading ->
                    renderLoadingPage
                Loaded petition ->
                    renderPetitionPage petition model
                Failed err ->
                    renderErrorPage err


maybeRender : Maybe (Html Msg) -> Html Msg
maybeRender =
    Maybe.withDefault (Html.text "")


renderIcon : String -> Html Msg
renderIcon iconClass =
    Html.i
        [ Attributes.class iconClass ] []


renderLink : Link -> Html Msg
renderLink link =
    let
        requiredAttributes : List (Html.Attribute Msg)
        requiredAttributes =
            [ Events.onClick link.msg
            , Attributes.href "javascript:;"
            ]

        optionalAttributes : List (Html.Attribute Msg)
        optionalAttributes =
            filterMaybes
                [ Maybe.map Attributes.title link.title
                , Maybe.map Attributes.class link.class
                ]
    in
    Html.a
        (requiredAttributes ++ optionalAttributes)
        [ maybeRender (Maybe.map renderIcon link.icon)
        , Html.text link.text
        ]


renderPage : Page -> Html Msg
renderPage page =
    let
        home : Link
        home =
            case page.type_ of
                NormalPage ->
                    { text = "UK Petitions"
                    , msg = Start
                    , title = Just "Get Started"
                    , icon = Just "icon-portcullis"
                    , class = Nothing
                    }
                ModalPage name ->
                    { text = name
                    , msg = HideModal
                    , title = Just "Back"
                    , icon = Just "icon-back"
                    , class = Nothing
                    }

        menu : String -> List Link -> Maybe (Html Msg)
        menu class links =
            links
                |> List.map renderLink
                |> List.map (\a -> Html.li [] [ a ])
                |> listToMaybe
                |> Maybe.map (Html.ul [ Attributes.class class ])

        footer : Maybe (Html Msg)
        footer =
            case page.type_ of
                NormalPage ->
                    Just renderFooter
                ModalPage _ ->
                    Nothing
    in
    Html.div -- Wrapper element required by Elm :(
        [ Attributes.id "elm-body"
        , Attributes.class (Maybe.withDefault "" page.class)
        ]
        [ Html.div -- Extra wrapper for sticky footer CSS :(
            [ Attributes.classList
                [ ("content-wrapper", footer /= Nothing) ]
            ]
            [ Html.header []
                [ Html.h1 []
                    [ renderLink home ]
                , maybeRender (menu "menu" page.menuitems)
                ]
            , Html.div
                [ Attributes.class "main" ]
                [ Html.div
                    [ Attributes.class "page" ]
                    (List.append
                        [ Html.div
                            [ Attributes.class "titles" ]
                            [ Html.h2 []
                                [ Html.text page.title ]
                            , maybeRender (menu "nav" page.navitems)
                            ]
                        ]
                        page.content
                    )
                ]
            ]
        , maybeRender footer
        ]


renderHomePage : Model -> Html Msg
renderHomePage model =
    let
        content : List (Html Msg)
        content =
            [ renderInput model.input
            , Html.p []
                [ Html.text "(or "
                , Html.a
                    [ Events.onClick LoadRandomPetition
                    , Attributes.href "javascript:;"
                    ]
                    [ Html.text "click here" ]
                , Html.text " to load one at random)"
                ]
            ]
    in
    renderPage
        { blankPage
            | title = "Get Started"
            , class = Just "pg-home"
            , content = content
            , menuitems = defaultLinks
        }


renderPetitionPage : Petition -> Model -> Html Msg
renderPetitionPage petition model =
    let
        item : PetitionList.Item
        item =
            PetitionList.Item petition.url petition.title

        isSaved : Bool
        isSaved =
            PetitionList.member item model.saved

        content : List (Html Msg)
        content =
            case model.view of
                Summary ->
                    renderPetitionSummary petition model.options
                Detail ->
                    renderPetitionDetail petition
                CountryData ->
                    renderPetitionCountries petition model.options
                ConstituencyData ->
                    renderPetitionConstituencies petition model.options
    in
    renderPage
        { blankPage
            | title = petition.title
            , content = content
            , navitems = navigationLinks model.view
            , menuitems = (petitionLinks item isSaved) ++ defaultLinks
        }


renderLoadingPage : Html Msg
renderLoadingPage =
    let
        imageSize : Int
        imageSize = 80
    in
    Html.div
        [ Attributes.class "pg-loading" ]
        -- TODO: Get rid of the extra HTML elements on the
        -- loading page.
        --
        -- This page contains an empty header element wrapped
        -- in a div. These elements serve no purpose other
        -- than to facilitate a CSS transition when switching
        -- between the loading page and the content pages.
        -- The header slides up when data is loading and
        -- slides down again when the results come back.
        --
        -- This effect relies on Elm knowing that the header
        -- in the loading page is the same element as the
        -- header in the content pages. That's why we need
        -- the extra wrapper div below. If we don't wrap
        -- this header in two divs like in the content pages,
        -- Elm can't match up the elements in its virtual DOM.
        -- It just scraps the original header and draws a
        -- new one. We need ONE header with multiple states
        -- in order for the CSS transition to work.
        --
        -- This is a temporary solution. We want some way of
        -- transitioning between pages that a) doesn't require
        -- any extra elements and b) works across all pages.
        -- To be revisited...
        [ Html.div []
            [ Html.header [] []
            , Html.img
                [ Attributes.src "assets/img/loading.svg"
                , Attributes.width imageSize
                , Attributes.height imageSize
                ] []
            , Html.h3 []
                [ Html.text "Hang on a sec..." ]
            ]
        ]


renderErrorPage : Http.Error -> Html Msg
renderErrorPage err =
    let
        reason : String
        reason =
            case err of
                Http.BadUrl url ->
                    url ++ " is not a valid URL."
                Http.Timeout ->
                    "the request timed out."
                Http.NetworkError ->
                    "there was a problem with the network."
                Http.BadStatus resp ->
                    "the request returned "
                        ++ toString resp.status.code
                        ++ " "
                        ++ resp.status.message
                        ++ "."
                Http.BadPayload msg resp ->
                    "the results came back in a format I wasn't expecting."

        content : List (Html Msg)
        content =
            [ Html.div
                [ Attributes.class "error-message" ]
                [ Html.p
                    [ Attributes.class "larger" ]
                    [ Html.text "Sorry, I couldn't complete your request:"
                    , Html.br [] []
                    , Html.text reason
                    ]
                , Html.p
                    [ Attributes.class "large" ]
                    [ Html.text "You can head "
                    , Html.a
                        [ Events.onClick Start
                        , Attributes.href "javascript:;"
                        ]
                        [ Html.text "back to the homepage" ]
                    , Html.text " and try again."
                    , Html.br [] []
                    , Html.text "If it keeps happening, feel free to "
                    , Html.a
                        [ Attributes.href "https://twitter.com/deepilla"
                        , Attributes.target "_blank"
                        ]
                        [ Html.text "drop me a line" ]
                    , Html.text "."
                    ]
                ]
            ]
    in
    renderPage
        { blankPage
            | title = "Oh Sheesh, Y'all :("
            , content = content
            , menuitems = defaultLinks
        }


renderMyPetitionsPage : PetitionList -> PetitionList -> Html Msg
renderMyPetitionsPage saved recent =
    let
        urlToMsg : String -> Msg
        urlToMsg url =
            BatchUpdate
                [ HideModal
                , LoadPetition False url
                ]

        renderPetitions : String -> PetitionList -> Html Msg
        renderPetitions defaultMsg petitions =
            petitions
                |> renderPetitionListWithMsg urlToMsg
                |> Maybe.withDefault (Html.p [] [ Html.text defaultMsg ])

        content : List (Html Msg)
        content =
            [ Html.h3 []
                [ Html.text "Saved petitions" ]
            , renderPetitions "You haven't saved any petitions yet" saved
            , Html.h3 []
                [ Html.text "Recently viewed petitions" ]
            , renderPetitions "You haven't viewed any petitions yet" recent
            ]
    in
    renderPage
        { blankPage
            | type_ = ModalPage "My Petitions"
            , title = "Your Petitions"
            , content = content
        }


renderFAQPage : Html Msg
renderFAQPage =
    let
        questions : List String
        questions =
            [ "What does this site do"
            , "What is the UK Petitions website"
            , "How does this site work"
            , "Why doesn't the total number of signatures for the petition equal the sum of signatures per country"
            , "Why doesn't the number of UK signatures equal the sum of signatures per constituency"
            ]

        answers : List (List (Html Msg))
        answers =
            List.map (always [ Html.text "To be written..." ]) questions

        render : String -> List (Html Msg) -> List (Html Msg)
        render question answer =
            (Html.h3 [] [ Html.text (question ++ "?") ]) :: answer
    in
    renderPage
        { blankPage
            | type_ = ModalPage "FAQ"
            , title = "Frequently Asked Questions"
            , content = List.concat (List.map2 render questions answers)
        }


renderFooter : Html Msg
renderFooter =
    Html.footer []
        [ Html.small []
            [ Html.a
                [ Attributes.href "http://deepilla.com"
                , Attributes.target "_blank"
                ]
                [ Html.text "A deepilla jawn" ]
            , Html.text ". Made with "
            , Html.a
                [ Attributes.href "http://elm-lang.org"
                , Attributes.target "_blank"
                , Attributes.title "A delightful language for reliable webapps"
                ]
                [ Html.text "Elm" ]
            , Html.text " and "
            , Html.a
                [ Attributes.href "http://sass-lang.com"
                , Attributes.target "_blank"
                , Attributes.title "CSS with superpowers"
                ]
                [ Html.text "Sass" ]
            , Html.text ". Contains public sector information licensed under the "
            , Html.a
                [ Attributes.href "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"
                , Attributes.target "_blank"
                ]
                [ Html.text "Open Government Licence v3.0" ]
            , Html.text "."
            ]
        ]


renderPetitionSummary : Petition -> ReportOptions -> List (Html Msg)
renderPetitionSummary petition opts =
    [ renderPercentages petition.signatures petition.countries
    , renderTopCountries 10 opts.topCountryFilter petition.countries
    , renderConstituencies opts.constituencyGrouping petition.constituencies
    ]


renderPetitionDetail : Petition -> List (Html Msg)
renderPetitionDetail petition =
    let
        p : String -> Html Msg
        p text =
            Html.p [] [ Html.text text ]

        formatPetitionState : PetitionState -> String
        formatPetitionState state =
            case state of
                Open ->
                    "Open"
                Closed _ ->
                    "Closed"
                Rejected _ ->
                    "Rejected"

        linkToPetition : Html Msg
        linkToPetition =
            Html.a
                [ Attributes.href (withoutJsonExtension petition.url)
                , Attributes.target "_blank"
                , Attributes.class "button"
                , Attributes.title ("View this petition on " ++ baseUrl)
                ]
                [ Html.text "Open this petition" ]
    in
    [ Html.ol
        [ Attributes.class "meta" ]
        [ Html.dt []
            [ Html.text "Created by" ]
        , Html.dd []
            [ Html.text (Maybe.withDefault "Unknown" petition.creator) ]
        , Html.dt []
            [ Html.text "Created on" ]
        , Html.dd []
            [ Html.text (formatDate petition.created) ]
        , Html.dt []
            [ Html.text "Status" ]
        , Html.dd []
            [ Html.text (formatPetitionState petition.state) ]
        ]
    , Html.div
        [ Attributes.class "description" ]
        (List.concat
            [ (List.map p petition.description)
            , [linkToPetition]
            ]
        )
    ]


renderPetitionCountries : Petition -> ReportOptions -> List (Html Msg)
renderPetitionCountries petition opts =
    let
        data : List Country
        data =
            sortCountries opts.countrySortOptions petition.countries

        count : Int
        count =
            List.length data

        total : Int
        total =
            totalSignatures data

        iconClass : SortBy -> String
        iconClass by =
            if opts.countrySortOptions.by == by then
                case opts.countrySortOptions.order of
                    Asc ->
                        "icon-sort-asc"
                    Desc ->
                        "icon-sort-desc"
            else
                "icon-sort"

        headers : List Header
        headers =
            [
                { text = "Country"
                , title = Just "Sort by Country"
                , align = Nothing
                , span = Nothing
                , msg = Just (SortCountryData SortByCountry)
                , icon = Just (iconClass SortByCountry)
                }
            ,   { text = "Signatures"
                , title = Just "Sort by Signatures"
                , align = Just AlignCenter
                , span = Nothing
                , msg = Just (SortCountryData SortBySignatures)
                , icon = Just (iconClass SortBySignatures)
                }
            ,   { text = "Signatures (%)"
                , title = Nothing
                , align = Just AlignCenter
                , span = Nothing
                , msg = Nothing
                , icon = Nothing
                }
            ]

        body : List (Cell Country)
        body =
            [
                { value = .name
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = .signatures >> thousands
                , title = Nothing
                , align = Just AlignCenter
                , span = Nothing
                }
            ,   { value = .signatures >> formatPercentage (dps 1) total
                , title = Just (.signatures >> formatPercentage (dps 4) total)
                , align = Just AlignCenter
                , span = Nothing
                }
            ]

        footerRow : String -> Int -> List (Cell (List a))
        footerRow label amount =
            [
                { value = always label
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = always (thousands amount)
                , title = Nothing
                , align = Just AlignCenter
                , span = Nothing
                }
            ,   { value = always ""
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ]

        footers : List (List (Cell (List Country)))
        footers =
            if total /= petition.signatures then
                [ footerRow "Total" total
                , footerRow "Official Total" petition.signatures
                , footerRow "Difference" (petition.signatures - total)
                ]
            else
                [ footerRow "Total" total ]
    in
    [ Html.h3
        [ Attributes.class "subbed" ]
        [ Html.text "Signatures by Country" ]
    , Html.span []
        [ Html.text
            (thousands total
                ++ " "
                ++ pluraliseSignatures total
                ++ " in "
                ++ thousands count
                ++ " "
                ++ pluraliseCountries count
            )
        ]
    , renderTable headers body footers data
    ]


renderPetitionConstituencies : Petition -> ReportOptions -> List (Html Msg)
renderPetitionConstituencies petition opts =
    let
        data : List Constituency
        data =
            sortConstituencies opts.constituencySortOptions petition.constituencies

        count : Int
        count =
            List.length data

        total : Int
        total =
            totalSignatures data

        ukTotal : Int
        ukTotal =
            totalSignatures (List.filter .isUK petition.countries)

        iconClass : SortBy -> String
        iconClass by =
            if opts.constituencySortOptions.by == by then
                case opts.constituencySortOptions.order of
                    Asc ->
                        "icon-sort-asc"
                    Desc ->
                        "icon-sort-desc"
            else
                "icon-sort"

        title : Constituency -> String
        title constituency =
            constituency.name
                ++ ": MP "
                ++ (constituency.mp
                    |> Maybe.withDefault "Unknown")
                ++ ", Electorate "
                ++ (constituency.info
                    |> Maybe.map .electorate
                    |> Maybe.map thousands
                    |> Maybe.withDefault "Unknown")

        headers : List Header
        headers =
            [
                { text = "Constituency"
                , title = Just "Sort by Constituency"
                , align = Nothing
                , span = Nothing
                , msg = Just (SortConstituencyData SortByConstituency)
                , icon = Just (iconClass SortByConstituency)
                }
            ,   { text = "Country"
                , title = Just "Sort by Country"
                , align = Nothing
                , span = Nothing
                , msg = Just (SortConstituencyData SortByCountry)
                , icon = Just (iconClass SortByCountry)
                }
            ,   { text = "Region"
                , title = Nothing
                , align = Nothing
                , span = Nothing
                , msg = Nothing
                , icon = Nothing
                }
            ,   { text = "Signatures"
                , title = Just "Sort by Signatures"
                , align = Just AlignCenter
                , span = Nothing
                , msg = Just (SortConstituencyData SortBySignatures)
                , icon = Just (iconClass SortBySignatures)
                }
            ,   { text = "Signatures (%)"
                , title = Nothing
                , align = Just AlignCenter
                , span = Nothing
                , msg = Nothing
                , icon = Nothing
                }
            ]

        body : List (Cell Constituency)
        body =
            [
                { value = .name
                , title = Just title
                , align = Nothing
                , span = Nothing
                }
            ,   { value = getConstituencyCountryWithDefault ""
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = getConstituencyRegionWithDefault ""
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = .signatures >> thousands
                , title = Nothing
                , align = Just AlignCenter
                , span = Nothing
                }
            ,   { value = .signatures >> formatPercentage (dps 1) total
                , title = Just (.signatures >> formatPercentage (dps 4) total)
                , align = Just AlignCenter
                , span = Nothing
                }
            ]

        footerRow : String -> Int -> List (Cell (List a))
        footerRow label amount =
            [
                { value = always label
                , title = Nothing
                , align = Nothing
                , span = Just 3
                }
            ,   { value = always (thousands amount)
                , title = Nothing
                , align = Just AlignCenter
                , span = Nothing
                }
            ,   { value = always ""
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ]

        footers : List (List (Cell (List Constituency)))
        footers =
            if total /= ukTotal then
                [ footerRow "Total" total
                , footerRow "UK Signatures" ukTotal
                , footerRow "Difference" (ukTotal - total)
                ]
            else
                [ footerRow "Total" total ]
    in
    [ Html.h3
        [ Attributes.class "subbed" ]
        [ Html.text "UK Signatures by Constituency" ]
    , Html.span []
        [ Html.text
            (thousands total
                ++ " "
                ++ pluraliseSignatures total
                ++ " in "
                ++ thousands count
                ++ " "
                ++ pluraliseConstituencies count
            )
        ]
    , renderTable headers body footers data
    ]


renderPercentages : Int -> List Country -> Html Msg
renderPercentages officialTotal countries =
    let
        total : Int
        total =
            totalSignatures countries

        count : Int
        count =
            List.length countries

        -- NOTE: Type annotations don't work with tuples.
        -- (ukCountries, nonUkCountries) : (List Country, List Country)
        (ukCountries, nonUkCountries) = List.partition .isUK countries

        pie : String -> Int -> Html Msg
        pie label signatures =
            let
                percent : Float
                percent =
                    percentageOf total signatures

                displayPercent : Int
                displayPercent =
                    if percent > 95.0 && percent < 100.0 then
                        floor percent
                    else if percent < 5.0 && percent > 0.0 then
                        ceiling percent
                    else
                        round percent
            in
            Html.li
                [ Attributes.class ("pie pie" ++ toString displayPercent) ]
                [ Html.span
                    [ Attributes.class "percent" ]
                    [ Html.text ((dps 1 percent) ++ "%") ]
                , Html.text " "
                , Html.span
                    [ Attributes.class "label" ]
                    [ Html.text label ]
                , Html.text " "
                , Html.span
                    [ Attributes.class "brackets" ]
                    [ Html.text "(" ]
                , Html.span
                    [ Attributes.class "count" ]
                    [ Html.strong []
                        [ Html.text (thousands signatures) ]
                    , Html.text (" " ++ pluraliseSignatures signatures)
                    ]
                , Html.span
                    [ Attributes.class "brackets" ]
                    [ Html.text ")" ]
                ]
    in
    Html.div
        [ Attributes.class "percentages" ]
        [ Html.p
            [ Attributes.class "larger" ]
            [ Html.text "This petition has "
            , Html.span
                [ Attributes.class "highlight" ]
                [ Html.text (thousands total) ]
            , Html.text (" " ++ pluraliseSignatures total ++ " in ")
            , Html.span
                [ Attributes.class "highlight" ]
                [ Html.text (toString count) ]
            , Html.text (" " ++ pluraliseCountries count)
            ]
        , Html.ul []
            [ pie "UK" (totalSignatures ukCountries)
            , pie "Other" (totalSignatures nonUkCountries)
            ]
        ]


renderTopCountries : Int -> CountryFilter -> List Country -> Html Msg
renderTopCountries limit countryFilter countries =
    let
        filter : (Country -> Bool)
        filter =
            case countryFilter of
                All ->
                    always True
                NonUK ->
                    not << .isUK
                NonEU ->
                    not << .isEU

        data : List Country
        data =
            -- NOTE: The order of countries with the same
            -- number of signatures is not guaranteed and
            -- may change from render to render.
            countries
                |> List.filter filter
                |> sort Desc .signatures
                |> List.take limit

        barLabels : List String
        barLabels =
            List.map .name data

        barValues : List Int
        barValues =
            List.map .signatures data

        radioLabels : List String
        radioLabels =
            [ "Non-UK Only"
            , "Non-EU Only"
            , "All Countries"
            ]

        radioValues : List CountryFilter
        radioValues =
            [ NonUK
            , NonEU
            , All
            ]

        suffix : String
        suffix =
            case countryFilter of
                All ->
                    "Countries"
                NonUK ->
                    "Non-UK Countries"
                NonEU ->
                    "Non-EU Countries"
    in
    Html.div []
        [ Html.div
            [ Attributes.class "bar-header" ]
            [ Html.h3 []
                [ Html.text ("Top " ++ (toString limit) ++ " " ++ suffix) ]
            , Html.span
                [ Attributes.class "options" ]
                (renderRadioGroup
                    "filter-countries"
                    radioLabels
                    (List.map FilterTopCountries radioValues)
                    (List.map ((==) countryFilter) radioValues)
                )
            ]
            , renderBarChart barLabels barValues
        ]


renderConstituencies : GroupBy -> List Constituency -> Html Msg
renderConstituencies groupBy constituencies =
    let
        getCountry : Constituency -> String
        getCountry =
            getConstituencyCountryWithDefault "Unknown"

        getRegion : Constituency -> String
        getRegion constituency =
            getConstituencyRegionWithDefault (getCountry constituency) constituency

        getKey : Constituency -> String
        getKey =
            case groupBy of
                GroupByCountry ->
                    getCountry
                GroupByRegion ->
                    getRegion

        updateDict : (Constituency -> String) -> Constituency -> Dict String Int -> Dict String Int
        updateDict key constituency =
            let
                updateValue : Int -> Maybe Int -> Maybe Int
                updateValue value total =
                    Just ((Maybe.withDefault 0 total) + value)
            in
            Dict.update (key constituency) (updateValue constituency.signatures)

        -- NOTE: Type annotations don't work with tuples.
        -- (barLabels, barValues) : (List String, List Int)
        (barLabels, barValues) =
            constituencies
                |> List.foldl (updateDict getKey) Dict.empty
                |> Dict.toList
                |> sort Desc Tuple.second
                |> List.unzip

        radioLabels : List String
        radioLabels =
            [ "By Region"
            , "By Country"
            ]

        radioValues : List GroupBy
        radioValues =
            [ GroupByRegion
            , GroupByCountry
            ]

        suffix : String
        suffix =
            case groupBy of
                GroupByRegion ->
                    "Region"
                GroupByCountry ->
                    "Country"
    in
    Html.div []
        [ Html.div
            [ Attributes.class "bar-header" ]
            [ Html.h3 []
                [ Html.text ("UK Signatures By " ++ suffix) ]
            , Html.span
                [ Attributes.class "options" ]
                (renderRadioGroup
                    "group-constituencies"
                    radioLabels
                    (List.map GroupConstituencies radioValues)
                    (List.map ((==) groupBy) radioValues)
                )
            ]
        , renderBarChart barLabels barValues
        ]


renderInput : String -> Html Msg
renderInput currentValue =
    let
        url : String
        url =
            let
                value : String
                value =
                    String.trim currentValue
            in
            if not (String.isEmpty value) && String.all Char.isDigit value then
                urlWithId value
            else
                value

        isValid : Bool
        isValid =
            -- TODO: A better check for valid URLs (regex?).
            (String.startsWith "http://" url) || (String.startsWith "https://" url)
    in
    Html.form
        [ Events.onSubmit (LoadPetition False url)
        , Attributes.class "textbox"
        ]
        [ Html.label
            [ Attributes.for "textbox-input" ]
            [ renderIcon "icon-search"
            , Html.span
                [ Attributes.class "iconed" ]
                [ Html.text "URL" ]
            ]
        , Html.input
            [ Events.onInput UpdateInput
            , Attributes.id "textbox-input"
            , Attributes.autofocus True
            , Attributes.placeholder "Enter the URL of a petition"
            , Attributes.value currentValue
            , Attributes.accesskey 'u'
            ] []
        , Html.button
            [ Attributes.title "Fetch data for this petition"
            , Attributes.disabled (not isValid)
            ]
            [ Html.text "Go" ]
        ]


renderPetitionListWithMsg : (String -> Msg) -> PetitionList -> Maybe (Html Msg)
renderPetitionListWithMsg urlToMsg petitions =
    let
        linkToPetition : PetitionList.Item -> Html Msg
        linkToPetition petition =
            Html.a
                [ Events.onClick (urlToMsg petition.url)
                , Attributes.href "javascript:;"
                ]
                [ Html.text petition.title ]
    in
    petitions
        |> List.map linkToPetition
        |> List.map (\a -> Html.li [] [ a ])
        |> listToMaybe
        |> Maybe.map (Html.ol [ Attributes.class "petition-list" ])


renderPetitionList : PetitionList -> Maybe (Html Msg)
renderPetitionList =
    renderPetitionListWithMsg (LoadPetition False)


renderBarChart : List String -> List Int -> Html Msg
renderBarChart labels values =
    let
        max : Int
        max =
            Maybe.withDefault 0 (List.maximum values)

        tr : String -> Int -> Html Msg
        tr label value =
            let
                percent : Float
                percent =
                    percentageOf max value

                width: String
                width =
                    (toString percent) ++ "%"

                indent: String
                indent =
                    (toString (percent + 1.0)) ++ "%"
            in
            Html.tr
                [ Attributes.title (label ++ ": " ++ thousands value ++ " " ++ pluraliseSignatures value) ]
                [ Html.td
                    [ Attributes.class "label" ]
                    [ Html.text label ]
                , Html.td
                    [ Attributes.class "value" ]
                    [ Html.span
                        [ Attributes.style
                            [ ("display", "inline-block")
                            , ("width", width)
                            , ("text-indent", indent)
                            ]
                        ]
                        [ Html.text (thousands value) ]
                    ]
                ]
    in
    Html.table
        [ Attributes.class "bar" ] (List.map2 tr labels values)


renderRadioGroup : String -> List String -> List Msg -> List Bool -> List (Html Msg)
renderRadioGroup name labels msgs checks =
    let
        input : String -> Msg -> Bool -> Html Msg
        input label msg checked =
            Html.label
                [ Events.onCheck (always msg)
                , Attributes.class "radio"
                ]
                [ Html.input
                    [ Attributes.type_ "radio"
                    , Attributes.checked checked
                    , Attributes.name name
                    ] []
                , Html.span []
                    [ Html.text label ]
                ]
    in
    (List.map3 input labels msgs checks)


type Align
    = AlignLeft
    | AlignRight
    | AlignCenter


type alias Cell a =
    { value : (a -> String)
    , title : Maybe (a -> String)
    , align : Maybe Align
    , span : Maybe Int
    }


type alias Header =
    { text : String
    , title : Maybe String
    , align : Maybe Align
    , span : Maybe Int
    , msg : Maybe Msg
    , icon : Maybe String
    }


alignAttribute : Align -> Html.Attribute Msg
alignAttribute align =
    let
        value : String
        value =
            case align of
                AlignLeft ->
                    "left"
                AlignRight ->
                    "right"
                AlignCenter ->
                    "center"
    in
    Attributes.style [("text-align", value)]


th : Header -> Html Msg
th header =
    let
        linkTo : Msg -> List (Html Msg) -> Html Msg
        linkTo msg =
            Html.a
                [ Events.onClick msg
                , Attributes.href "javascript:;"
                ]

        maybeLink : Maybe Msg -> List (Html Msg) -> List (Html Msg)
        maybeLink msg contents =
            case msg of
                Just msg ->
                    [ linkTo msg contents ]
                Nothing ->
                    contents
    in
    Html.th
        (filterMaybes
            [ Maybe.map Attributes.title header.title
            , Maybe.map Attributes.colspan header.span
            , Maybe.map alignAttribute header.align
            ]
        )
        (maybeLink header.msg
            [ Html.text header.text
            , maybeRender (Maybe.map renderIcon header.icon)
            ]
        )


thead : List Header -> Maybe (Html Msg)
thead headers =
    List.map th headers
        |> listToMaybe
        |> Maybe.map (\ths -> [ Html.tr [] ths ])
        |> Maybe.map (Html.thead [])


td : Cell a -> a -> Html Msg
td cell item =
    Html.td
        (filterMaybes
            [ Maybe.map (\title -> Attributes.title (title item)) cell.title
            , Maybe.map Attributes.colspan cell.span
            , Maybe.map alignAttribute cell.align
            ]
        )
        [ Html.text (cell.value item) ]


tr : List (Cell a) -> a -> Html Msg
tr cells item =
    Html.tr []
        (List.map (\cell -> td cell item) cells)


tbody : List (Cell a) -> List a -> Maybe (Html Msg)
tbody cells items =
    List.map (tr cells) items
        |> listToMaybe
        |> Maybe.map (Html.tbody [])


tfoot : List (List (Cell (List a))) -> List a -> Maybe (Html Msg)
tfoot rows items =
    List.map (\cells -> tr cells items) rows
        |> listToMaybe
        |> Maybe.map (Html.tfoot [])


renderTable : List Header -> List (Cell a) -> List (List (Cell (List a))) -> List a -> Html Msg
renderTable headers body footers items =
    Html.table
        [ Attributes.class "tabular" ]
        [ maybeRender (thead headers)
        , maybeRender (tfoot footers items)
        , maybeRender (tbody body items)
        ]


navigationLinks : View -> List Link
navigationLinks currentView =
    let
        selected : View -> Maybe String
        selected view =
            if view == currentView then
                Just "selected"
            else
                Nothing
    in
    [
        { text = "Summary"
        , title = Nothing
        , class = selected Summary
        , msg = SetView Summary
        , icon = Nothing
        }
    ,   { text = "Details"
        , title = Nothing
        , class = selected Detail
        , msg = SetView Detail
        , icon = Nothing
        }
    ,   { text = "Countries"
        , title = Nothing
        , class = selected CountryData
        , msg = SetView CountryData
        , icon = Nothing
        }
    ,   { text = "Constituencies"
        , title = Nothing
        , class = selected ConstituencyData
        , msg = SetView ConstituencyData
        , icon = Nothing
        }
    ]


petitionLinks : PetitionList.Item -> Bool -> List Link
petitionLinks item isSaved =
    [
        { text = "Refresh"
        , msg = LoadPetition True item.url
        , title = Just "Reload data for this petition"
        , icon = Nothing
        , class = Nothing
        }
    ,   (if isSaved then
            { text = "Unsave"
            , msg = UnsavePetition item
            , title = Just "Remove this petition from My Petitions"
            , icon = Nothing
            , class = Nothing
            }
        else
            { text = "Save"
            , msg = SavePetition item
            , title = Just "Add this petition to My Petitions"
            , icon = Nothing
            , class = Nothing
            }
        )
    ]


defaultLinks : List Link
defaultLinks =
    [
        { text = "My Petitions"
        , msg = (ShowModal MyPetitions)
        , title = Just "Saved and recently viewed petitions"
        , icon = Nothing
        , class = Nothing
        }
    ,   { text = "FAQ"
        , msg = (ShowModal FAQ)
        , title = Just "Frequently asked questions"
        , icon = Nothing
        , class = Nothing
        }
    ]


-- SUBSCRIPTIONS


-- Return the localStorage value for a given key.
port onLocalStorage : ((String, Maybe String) -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    onLocalStorage (uncurry OnLocalStorage)


-- MAIN


type alias Config =
    { id : Maybe String
    , logging : Bool
    }


init : Config -> (Model, Cmd Msg)
init config =
    let
        localStorageKeys : List String
        localStorageKeys =
            [ "recent.petitions"
            , "saved.petitions"
            ]

        initialFetch : Cmd Msg
        initialFetch =
            config.id
                |> Maybe.map urlWithId
                |> Maybe.map fetchPetition
                |> Maybe.withDefault Cmd.none

        initialState : AppState
        initialState =
            config.id
                |> Maybe.map (always Loading)
                |> Maybe.withDefault Home

        model : Model
        model =
            { initialModel
                | state = initialState
                , logging = config.logging
            }

        cmd : Cmd Msg
        cmd =
            List.map getLocalStorage localStorageKeys
                |> (::) initialFetch
                |> Cmd.batch
    in
    (,) model cmd


main : Program Config Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


-- HELPER FUNCTIONS


sort : SortOrder -> (a -> comparable) -> List a -> List a
sort order property =
    case order of
        Asc ->
            List.sortBy property
        Desc ->
            List.reverse << List.sortBy property


-- JSON Helpers


dateDecoder : Json.Decoder Date
dateDecoder =
    let
        -- TODO: Replace this function if/when Elm 0.18
        -- gets a replacement for Json.Decode.customDecoder.
        -- See https://groups.google.com/forum/#!topic/elm-dev/Ctl_kSKJuYc
        stringToDateDecoder : String -> Json.Decoder Date
        stringToDateDecoder string =
            case (Date.fromString string) of
                Ok date ->
                    Json.succeed date
                Err err ->
                    Json.fail err
    in
    Json.andThen stringToDateDecoder Json.string


linesDecoder : Json.Decoder (List String)
linesDecoder =
    let
        lines : String -> List String
        lines string =
            string
                |> String.lines
                |> List.map String.trim
                |> List.filter (not << String.isEmpty)
    in
    Json.map lines Json.string


-- Maybe Helpers


filterMaybes : List (Maybe a) -> List a
filterMaybes =
    List.filterMap identity


listToMaybe : List a -> Maybe (List a)
listToMaybe list =
    if List.isEmpty list then
        Nothing
    else
        Just list


-- Number Helpers

dps : Int -> Float -> String
dps dps value =
    let
        dps_ : Int
        dps_ =
            max 0 dps

        rounding : Float
        rounding =
            0.5 / (toFloat (10 ^ dps_))

        value_ : Float
        value_ =
            if value < 0 then (value - rounding) else (value + rounding)

        parts : List String
        parts =
            String.split "." (toString value_)

        integer : Maybe String
        integer =
            List.head parts

        fractional : Maybe String
        fractional =
            List.head (List.drop 1 parts)
    in
    case integer of
        Just int ->
            let
                frac : String
                frac =
                    case fractional of
                        Just str ->
                            str
                                |> String.left dps_
                                |> String.padRight dps_ '0'
                        Nothing ->
                            String.repeat dps_ "0"
            in
            int ++ "." ++ frac
        Nothing ->
            "#NaN"


thousands : Int -> String
thousands number =
    let
        chunk : Int -> String -> List String
        chunk len string =
            let
                splitr : Int -> String -> List String -> List String
                splitr len string list =
                    let
                        head : String
                        head = String.dropRight len string

                        tail : String
                        tail = String.right len string
                    in
                    if tail == "" then
                        list
                    else
                        splitr len head (tail :: list)
            in
            splitr len string []
    in
    abs number
        |> toString
        |> chunk 3
        |> String.join ","
        |> (if number < 0 then String.cons '-' else identity)


toOrdinal : Int -> String
toOrdinal num =
    let
        mod10 : Int
        mod10 =
            rem num 10

        mod100 : Int
        mod100 =
            rem num 100

        suffix : String
        suffix =
            if mod10 == 1 && mod100 /= 11 then
                "st"
            else if mod10 == 2 && mod100 /= 12 then
                "nd"
            else if mod10 == 3 && mod100 /= 13 then
                "rd"
            else
                "th"
    in
    (toString num) ++ suffix


percentageOf : Int -> Int -> Float
percentageOf total value =
    100 * ((toFloat value) / (toFloat total))


formatPercentage : (Float -> String) -> Int -> Int -> String
formatPercentage format total value =
    format (percentageOf total value) ++ "%"


-- Date Helpers


dayToString : Date.Day -> String
dayToString day =
    case day of
        Date.Mon ->
            "Monday"
        Date.Tue ->
            "Tuesday"
        Date.Wed ->
            "Wednesday"
        Date.Thu ->
            "Thursday"
        Date.Fri ->
            "Friday"
        Date.Sat ->
            "Saturday"
        Date.Sun ->
            "Sunday"


monthToString : Date.Month -> String
monthToString month =
    case month of
        Date.Jan ->
            "January"
        Date.Feb ->
            "February"
        Date.Mar ->
            "March"
        Date.Apr ->
            "April"
        Date.May ->
            "May"
        Date.Jun ->
            "June"
        Date.Jul ->
            "July"
        Date.Aug ->
            "August"
        Date.Sep ->
            "September"
        Date.Oct ->
            "October"
        Date.Nov ->
            "November"
        Date.Dec ->
            "December"


formatDate : Date -> String
formatDate date =
    monthToString (Date.month date)
        ++ " "
        ++ toOrdinal (Date.day date)
        ++ ", "
        ++ toString (Date.year date)


-- String Helpers


capitalise : String -> String
capitalise string =
    case (String.uncons string) of
        Just (first, rest) ->
            String.cons (Char.toUpper first) rest
        Nothing ->
            ""


pluralise : String -> String -> Int -> String
pluralise singular plural count =
    if count == 1 then singular else plural


withSuffix : String -> String -> String
withSuffix suffix string =
    if not (String.endsWith suffix string) then
        string ++ suffix
    else
        string


withoutSuffix : String -> String -> String
withoutSuffix suffix string =
    if String.endsWith suffix string then
        String.dropRight (String.length suffix) string
    else
        string


-- Petition Helpers


sortCountries : SortOptions -> List Country -> List Country
sortCountries opts =
    case opts.by of
        SortByCountry ->
            sort opts.order .name
        SortBySignatures ->
            sort opts.order .signatures
        SortByConstituency ->
            identity


sortConstituencies : SortOptions -> List Constituency -> List Constituency
sortConstituencies opts =
    let
        getCountry : Constituency -> String
        getCountry constituency =
            getConstituencyCountryWithDefault "" constituency
                ++ "__"
                ++ constituency.name
    in
    case opts.by of
        SortByConstituency ->
            sort opts.order .name
        SortByCountry ->
            sort opts.order getCountry
        SortBySignatures ->
            sort opts.order .signatures


countryToString : Constituencies.Country -> String
countryToString country =
    case country of
        Constituencies.Eng ->
            "England"
        Constituencies.NI ->
            "N. Ireland"
        Constituencies.Scot ->
            "Scotland"
        Constituencies.Wales ->
            "Wales"


regionToString : Constituencies.Region -> String
regionToString region =
    case region of
        Constituencies.EMid ->
            "E. Midlands"
        Constituencies.East ->
            "Eastern"
        Constituencies.London ->
            "London"
        Constituencies.NE ->
            "North East"
        Constituencies.NW ->
            "North West"
        Constituencies.SE ->
            "South East"
        Constituencies.SW ->
            "South West"
        Constituencies.WMid ->
            "W. Midlands"
        Constituencies.Yorks ->
            "Yorkshire"


getConstituencyCountry : Constituency -> Maybe String
getConstituencyCountry constituency =
    constituency.info
        |> Maybe.map .country
        |> Maybe.map countryToString


getConstituencyCountryWithDefault : String -> Constituency -> String
getConstituencyCountryWithDefault default constituency =
    Maybe.withDefault default (getConstituencyCountry constituency)


getConstituencyRegion : Constituency -> Maybe String
getConstituencyRegion constituency =
    constituency.info
        |> Maybe.andThen .region
        |> Maybe.map regionToString


getConstituencyRegionWithDefault : String -> Constituency -> String
getConstituencyRegionWithDefault default constituency =
    Maybe.withDefault default (getConstituencyRegion constituency)


pluraliseCountries : Int -> String
pluraliseCountries =
    pluralise "country" "countries"


pluraliseConstituencies : Int -> String
pluraliseConstituencies =
    pluralise "constituency" "constituencies"


pluraliseSignatures : Int -> String
pluraliseSignatures =
    pluralise "signature" "signatures"


withJsonExtension : String -> String
withJsonExtension =
    withSuffix ".json"


withoutJsonExtension : String -> String
withoutJsonExtension =
    withoutSuffix ".json"


totalSignatures : List { a | signatures : Int } -> Int
totalSignatures list  =
    List.foldl (\a total -> total + a.signatures) 0 list


baseUrl : String
baseUrl =
    "https://petition.parliament.uk"


defaultUrl : String
defaultUrl =
    urlWithId "131215"


urlWithId : String -> String
urlWithId id =
    baseUrl ++ "/petitions/" ++ (Http.encodeUri id)


urlWithParams : List (String, String) -> String
urlWithParams params =
    url (baseUrl ++ "/petitions.json") params


-- TODO: Replace these functions with Http.url
-- if/when that function makes it back into Elm 0.18.
-- See https://groups.google.com/forum/#!topic/elm-discuss/XaIr96e8qXk
-- and https://github.com/elm-lang/http/pull/15
queryPair : (String, String) -> String
queryPair (key,value) =
    queryEscape key ++ "=" ++ queryEscape value

queryEscape : String -> String
queryEscape string =
    String.join "+" (String.split "%20" (Http.encodeUri string))

url : String -> List (String, String) -> String
url baseUrl args =
    case args of
        [] ->
            baseUrl
        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)
