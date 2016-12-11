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
    | Closed
    | Rejected
    | Other String


parsePetitionState : String -> PetitionState
parsePetitionState state =
    case String.toLower (String.trim state) of
        "open" ->
            Open
        "closed" ->
            Closed
        "rejected" ->
            Rejected
        _ ->
            Other state


petitionStateDecoder : Json.Decoder PetitionState
petitionStateDecoder =
    Json.map parsePetitionState Json.string


type alias Country =
    { name : String
    , code : String
    , signatures : Int
    , isUK : Bool
    , isEU : Bool
    }


countryDecoder : Json.Decoder Country
countryDecoder =
    Json.map5 Country
        (Json.field "name" Json.string)
        (Json.field "code" Json.string)
        (Json.field "signature_count" Json.int)
        -- Look up UK membership using the country code.
        (Json.field "code" (Json.map Country.isUK Json.string))
        -- Look up EU membership using the country code.
        (Json.field "code" (Json.map Country.isEU Json.string))


type alias Constituency =
    { name : String
    , code : String
    -- MP can be null (due to death, resignation etc).
    , mp : Maybe String
    , signatures : Int
    , info : Maybe Constituencies.Item
    }


constituencyDecoder : Json.Decoder Constituency
constituencyDecoder =
    Json.map5 Constituency
        (Json.field "name" Json.string)
        (Json.field "ons_code" Json.string)
        (Json.field "mp" (Json.nullable Json.string))
        (Json.field "signature_count" Json.int)
        -- Look up constituency info using the ONS code.
        (Json.field "ons_code" (Json.map Constituencies.get Json.string))


type alias Petition =
    { url : String
    , title : String
    , description : List String
    -- Creator is null for closed petitions.
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
        |> andMap (Json.at ["data", "attributes", "state"] petitionStateDecoder)
        |> andMap (Json.at ["data", "attributes", "signature_count"] Json.int)
        |> andMap (Json.at ["data", "attributes", "signatures_by_country"] (Json.list countryDecoder))
        |> andMap (Json.at ["data", "attributes", "signatures_by_constituency"] (Json.list constituencyDecoder))


type SortBy
    = ByCountry
    | ByConstituency
    | BySignatures


type SortOrder
    = Asc
    | Desc


defaultSortOrder : SortBy -> SortOrder
defaultSortOrder by =
    case by of
        ByCountry ->
            Asc
        ByConstituency ->
            Asc
        BySignatures ->
            Desc


type alias SortOptions =
    { by : SortBy
    , order : SortOrder
    }


defaultSortOptions : SortOptions
defaultSortOptions =
    { by = BySignatures
    , order = defaultSortOrder BySignatures
    }


type CountryFilter
    = NonUK
    | NonEU
    | All


type alias ReportOptions =
    { topCountryFilter : CountryFilter
    , showRegions : Bool
    , countrySortOptions : SortOptions
    , constituencySortOptions : SortOptions
    }


defaultReportOptions : ReportOptions
defaultReportOptions =
    { topCountryFilter = NonUK
    , showRegions = True
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
    -- HTTP Callbacks
    | OnPetitionLoaded Petition
    | OnRandomUrlsLoaded (Array String)
    | OnHttpError Http.Error
    | OnLocalStorage String (Maybe String)
    -- Options
    | SortCountryData SortBy
    | SortConstituencyData SortBy
    | FilterTopCountries CountryFilter
    | ShowRegions Bool
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
                -- If we're reloading the current petition, keep
                -- the existing settings. Otherwise, reset to the
                -- defaults.
                (view, options) =
                    if reloading then
                        (model.view, model.options)
                    else
                        (Summary, defaultReportOptions)

                model_ =
                    { model
                        | state = Loading
                        , view = view
                        , options = options
                    }
            in
            (,) model_ (getPetition url)

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
                    (,) model_ getRandomUrls

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
                        -- TODO: After urlGenerator is initialised, it
                        -- has access to the urls array for the lifetime
                        -- of the program. Find out how this works!
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

        OnLocalStorage key maybeValue ->
            let
                model_ =
                    maybeValue
                        |> Maybe.map (\value -> updateModelFromLocalStorage key value model)
                        |> Maybe.withDefault model
            in
            (,) model_ Cmd.none

        SavePetition item ->
            updateSavedPetitions (PetitionList.add item model.saved) model

        UnsavePetition item ->
            updateSavedPetitions (PetitionList.remove item model.saved) model

        ShowModal modal ->
            updateModal (Just modal) model

        HideModal ->
            updateModal Nothing model

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
            updateReportOptions options_ model

        SortConstituencyData by ->
            let
                options_ =
                    { options
                        | constituencySortOptions = updateSortOptions by options.constituencySortOptions
                    }
            in
            updateReportOptions options_ model

        FilterTopCountries filter ->
            let
                options_ =
                    { options
                        | topCountryFilter = filter
                    }
            in
            updateReportOptions options_ model

        ShowRegions show ->
            let
                options_ =
                    { options
                        | showRegions = show
                    }
            in
            updateReportOptions options_ model

        -- HACK ALERT! Hopefully there's a proper Elm way to
        -- do this, but for now...
        --
        -- In some cases a single user action needs to trigger
        -- more than one action in the program. For example,
        -- when you select a petition from the My Petitions
        -- screen, the app has to close the My Petitions modal
        -- AND load the petition. That involves two separate
        -- Msgs: HideModal and LoadPetition.
        --
        -- We could handle this by passing a Msg argument to
        -- HideModal, e.g.:
        --
        --      HideModal (LoadPetition False url)
        --
        -- But then HideModal has to handle an extra, completely
        -- unrelated message. And we have to use the same trick
        -- for every message with similar behaviour. When a user
        -- chooses a command from a pop-up menu, for example, we
        -- want to hide the menu and then execute the command.
        -- Do we pass a Msg to HideMenu too?
        --
        -- A more flexible and extensible solution is to provide
        -- a dummy Msg that takes an arbitrary list of Msgs and
        -- calls update for each one. That's what BatchUpdate
        -- does. The returned Model includes all the changes from
        -- each call to update. The returned Cmd is the one from
        -- the FINAL call to update. Any other Cmds generated
        -- along the way are discarded!
        --
        -- TODO: Find a less hacky way to do this.
        BatchUpdate msgs ->
            let
                update_ : Msg -> (Model, Cmd Msg) -> (Model, Cmd Msg)
                update_ msg (model, _) =
                    update msg model
            in
            List.foldl update_ (model, Cmd.none) msgs


httpGet : String -> Json.Decoder a -> (a -> Msg) -> Cmd Msg
httpGet url decoder onSuccess =
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


getPetition : String -> Cmd Msg
getPetition url =
    httpGet (withJsonExtension url) petitionDecoder OnPetitionLoaded


getRandomUrls : Cmd Msg
getRandomUrls =
    let
        url : String
        url =
            urlWithParams [("state", "open")]

        decoder : Json.Decoder (Array String)
        decoder =
            Json.field "data" (Json.array (Json.at ["links", "self"] Json.string))
    in
    httpGet url decoder OnRandomUrlsLoaded


updateModelFromLocalStorage : String -> String -> Model -> Model
updateModelFromLocalStorage key value model =
    case key of
        "recent.petitions" ->
            { model
                | recent = PetitionList.fromJson value
            }
        "saved.petitions" ->
            { model
                | saved = PetitionList.fromJson value
            }
        _ ->
            model


updateModal : (Maybe Modal) -> Model -> (Model, Cmd Msg)
updateModal maybeModal model =
    let
        model_ =
            { model
                | modal = maybeModal
            }
    in
    (,) model_ Cmd.none


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


updateReportOptions : ReportOptions -> Model -> (Model, Cmd Msg)
updateReportOptions options model =
    let
        model_ =
            { model
                | options = options
            }
    in
    (,) model_ Cmd.none


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
    , title : String
    , content : List (Html Msg)
    , navitems : List Link
    , menuitems : List Link
    }


blankPage : Page
blankPage =
    { type_ = NormalPage
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
        [ Attributes.id "elm-container" ]
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
        mru : Maybe (Html Msg)
        mru =
            model.recent
                |> renderPetitionList
                |> Maybe.map (List.repeat 1)
                |> Maybe.map ((::) (Html.h4 [] [ Html.text "You recently viewed" ]))
                |> Maybe.map (Html.div [ Attributes.class "mru" ])

        content : List (Html Msg)
        content =
            [ Html.p
                [ Attributes.class "large intro" ]
                [ Html.text "To view a petition, enter the URL below. Don't have one in mind? "
                , Html.a
                    [ Events.onClick LoadRandomPetition
                    , Attributes.href "javascript:;"
                    ]
                    [ Html.text "Click here to load a random petition" ]
                , Html.text "."
                ]
            , renderInput model.input
            , maybeRender mru
            ]
    in
    renderPage
        { blankPage
            | title = "Get Started"
            , content = content
            , menuitems = defaultLinks
        }


renderPetitionPage : Petition -> Model -> Html Msg
renderPetitionPage petition model =
    let
        isSaved : Bool
        isSaved =
            PetitionList.member (PetitionList.Item petition.url petition.title) model.saved

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
            , menuitems = (petitionLinks petition.url petition.title isSaved) ++ defaultLinks
        }


renderLoadingPage : Html Msg
renderLoadingPage =
    let
        imageSize : Int
        imageSize = 80
    in
    Html.div
        [ Attributes.class "loading" ]
        -- HACK ALERT! Hopefully there's a proper Elm way
        -- to do this, but for now...
        --
        -- This page includes an empty header element in
        -- order to produce a CSS transition when switching
        -- between the loading page and the content pages.
        -- The header slides up when data is loading and
        -- slides down again when the data comes back.
        --
        -- This effect relies on Elm realising that the
        -- header in the loading page is the same element
        -- as the header from the content page. That's
        -- why we need an extra wrapper div. The content
        -- page header is wrapped in two divs, so the
        -- loading page header needs to be too. Otherwise,
        -- Elm can't match the elements in its virtual DOM.
        -- It just scraps the original header and draws a
        -- new one. Instead of one element which changes
        -- from State A to State B, we end up with two
        -- completely different elements and therefore
        -- no transition.
        --
        -- TODO: Find a better way to transition between
        -- pages.
        [ Html.div []
            [ Html.header [] []
            , Html.img
                [ Attributes.src "assets/img/loading.svg"
                , Attributes.width imageSize
                , Attributes.height imageSize
                ] []
            , Html.p
                [ Attributes.class "message" ]
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
                    "The request timed out."
                Http.NetworkError ->
                    "There was some kind of network error."
                Http.BadStatus resp ->
                    "The request returned Status "
                        ++ toString resp.status.code
                        ++ " "
                        ++ resp.status.message
                        ++ "."
                Http.BadPayload msg resp ->
                    "The results came back in a format I wasn't expecting."

        content : List (Html Msg)
        content =
            [ Html.p []
                [ Html.text "Sorry, I couldn't complete your request. "
                , Html.text reason
                , Html.text " Maybe head "
                , Html.a
                    [ Events.onClick Start
                    , Attributes.href "javascript:;"
                    ]
                    [ Html.text "back to the homepage" ]
                , Html.text " and try again."
                ]
            , Html.p []
                [ Html.text "If this keeps happening, feel free to "
                , Html.a
                    [ Attributes.href "https://twitter.com/deepilla"
                    , Attributes.target "_blank"
                    ]
                    [ Html.text "drop me a line" ]
                , Html.text "."
                ]
            ]
    in
    renderPage
        { blankPage
            | title = "Oh Sheesh, Y'all!"
            , content = content
            , menuitems = defaultLinks
        }


renderMyPetitionsPage : PetitionList -> PetitionList -> Html Msg
renderMyPetitionsPage saved recent =
    let
        renderPetitions : String -> PetitionList -> Html Msg
        renderPetitions defaultMsg petitions =
            petitions
                |> renderPetitionListModal
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
            List.repeat (List.length questions) [ Html.text "To be written..." ]

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
    [ renderPercentages petition
    , renderTopCountries petition opts
    , renderUkRegions petition opts
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
                Closed ->
                    "Closed"
                Rejected ->
                    "Rejected"
                Other state ->
                    capitalise state

        linkToPetition : Html Msg
        linkToPetition =
            Html.a
                [ Attributes.href (withoutJsonExtension petition.url)
                , Attributes.target "_blank"
                , Attributes.class "button"
                , Attributes.title ("View this petition on " ++ baseUrl)
                ]
                [ Html.text "View petition" ]
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
            List.length petition.countries

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
                , msg = Just (SortCountryData ByCountry)
                , icon = Just (iconClass ByCountry)
                }
            ,   { text = "Signatures"
                , title = Just "Sort by Signatures"
                , align = Just Center
                , span = Nothing
                , msg = Just (SortCountryData BySignatures)
                , icon = Just (iconClass BySignatures)
                }
            ,   { text = "Signatures (%)"
                , title = Nothing
                , align = Just Center
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
                , align = Just Center
                , span = Nothing
                }
            ,   { value = .signatures >> formatPercentage (dps 1) total
                , title = Just (.signatures >> formatPercentage (dps 4) total)
                , align = Just Center
                , span = Nothing
                }
            ]

        footerRow : String -> Int -> List (Cell a)
        footerRow label amount =
            [
                { value = always label
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = always (thousands amount)
                , title = Nothing
                , align = Just Center
                , span = Nothing
                }
            ,   { value = always ""
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ]

        footers : List (Row (List Country))
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
            List.length petition.constituencies

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

        country : Constituency -> String
        country constituency =
            constituency.info
                |> Maybe.map .country
                |> Maybe.map countryString
                |> Maybe.withDefault ""

        region : Constituency -> String
        region constituency =
            constituency.info
                |> Maybe.andThen .region
                |> Maybe.map regionString
                |> Maybe.withDefault ""

        headers : List Header
        headers =
            [
                { text = "Constituency"
                , title = Just "Sort by Constituency"
                , align = Nothing
                , span = Nothing
                , msg = Just (SortConstituencyData ByConstituency)
                , icon = Just (iconClass ByConstituency)
                }
            ,   { text = "Country"
                , title = Just "Sort by Country"
                , align = Nothing
                , span = Nothing
                , msg = Just (SortConstituencyData ByCountry)
                , icon = Just (iconClass ByCountry)
                }
            ,   { text = "Region"
                , title = Nothing
                , align = Nothing
                , span = Nothing
                , msg = Nothing
                , icon = Nothing
                }
            ,   { text = "Signatures"
                , title = Just "Sort data by Signatures"
                , align = Just Center
                , span = Nothing
                , msg = Just (SortConstituencyData BySignatures)
                , icon = Just (iconClass BySignatures)
                }
            ,   { text = "Signatures (%)"
                , title = Nothing
                , align = Just Center
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
            ,   { value = country
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = region
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ,   { value = .signatures >> thousands
                , title = Nothing
                , align = Just Center
                , span = Nothing
                }
            ,   { value = .signatures >> formatPercentage (dps 1) total
                , title = Just (.signatures >> formatPercentage (dps 4) total)
                , align = Just Center
                , span = Nothing
                }
            ]

        footerRow : String -> Int -> List (Cell a)
        footerRow label amount =
            [
                { value = always label
                , title = Nothing
                , align = Nothing
                , span = Just 3
                }
            ,   { value = always (thousands amount)
                , title = Nothing
                , align = Just Center
                , span = Nothing
                }
            ,   { value = always ""
                , title = Nothing
                , align = Nothing
                , span = Nothing
                }
            ]

        footers : List (Row (List Constituency))
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


renderPercentages : Petition -> Html Msg
renderPercentages petition =
    let
        total : Int
        total =
            totalSignatures petition.countries

        count : Int
        count =
            List.length petition.countries

        -- NOTE: Type annotations don't work with tuples.
        -- (ukCountries, nonUkCountries) : (List Country, List Country)
        (ukCountries, nonUkCountries) = List.partition .isUK petition.countries

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
            , Html.text (" " ++ (pluraliseSignatures total) ++ " in ")
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


renderTopCountries : Petition -> ReportOptions -> Html Msg
renderTopCountries petition opts =
    let
        filter : (Country -> Bool)
        filter =
            case opts.topCountryFilter of
                All ->
                    always True
                NonUK ->
                    not << .isUK
                NonEU ->
                    not << .isEU

        limit : Int
        limit =
            10

        data : List Country
        data =
            petition.countries
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

        radioMsgs : List CountryFilter
        radioMsgs =
            [ NonUK
            , NonEU
            , All
            ]

        suffix : String
        suffix =
            case opts.topCountryFilter of
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
                    "filterTopCountries"
                    radioLabels
                    (List.map FilterTopCountries radioMsgs)
                    (List.map ((==) opts.topCountryFilter) radioMsgs)
                )
            ]
            , renderBarChart barLabels barValues
        ]


renderUkRegions : Petition -> ReportOptions -> Html Msg
renderUkRegions petition opts =
    let
        country : Constituency -> String
        country constituency =
            constituency.info
                |> Maybe.map .country
                |> Maybe.map countryString
                |> Maybe.withDefault "Unknown"

        region : Constituency -> String
        region constituency =
            constituency.info
                |> Maybe.andThen .region
                |> Maybe.map regionString
                |> Maybe.withDefault (country constituency)

        key : (Constituency -> String)
        key =
            if opts.showRegions then
                region
            else
                country

        updateDict : (Constituency -> String) -> Constituency -> Dict String Int -> Dict String Int
        updateDict key constituency =
            let
                update : Int -> Maybe Int -> Maybe Int
                update value total =
                    Just ((Maybe.withDefault 0 total) + value)
            in
            Dict.update (key constituency) (update constituency.signatures)

        -- NOTE: Type annotations don't work with tuples.
        -- (barLabels, barValues) : (List String, List Int)
        (barLabels, barValues) =
            petition.constituencies
                |> List.foldr (updateDict key) Dict.empty
                |> Dict.toList
                |> sort Desc Tuple.second
                |> List.unzip

        radioLabels : List String
        radioLabels =
            [ "By Region"
            , "By Country"
            ]

        radioMsgs : List Bool
        radioMsgs =
            [ True
            , False
            ]
    in
    Html.div []
        [ Html.div
            [ Attributes.class "bar-header" ]
            [ Html.h3 []
                [ Html.text "UK Signatures By "
                , Html.text (if opts.showRegions then "Region" else "Country")
                ]
            , Html.span
                [ Attributes.class "options" ]
                (renderRadioGroup
                    "showRegions"
                    radioLabels
                    (List.map ShowRegions radioMsgs)
                    (List.map ((==) opts.showRegions) radioMsgs)
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
            -- TODO: Need a better check for valid URLs (regex?).
            (String.startsWith "http://" url) || (String.startsWith "https://" url)
    in
    Html.form
        [ Events.onSubmit (LoadPetition False url)
        , Attributes.class "textbox"
        ]
        [ Html.input
            [ Events.onInput UpdateInput
            , Attributes.autofocus True
            , Attributes.placeholder ("e.g. " ++ defaultUrl)
            , Attributes.value currentValue
            , Attributes.accesskey 'u'
            ] []
        , Html.button
            [ Attributes.disabled (not isValid)
            , Attributes.title "Fetch data for this petition"
            ]
            [ renderIcon "icon-download" ]
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


renderPetitionListModal : PetitionList -> Maybe (Html Msg)
renderPetitionListModal =
    let
        urlToMsg : String -> Msg
        urlToMsg url =
            BatchUpdate
                [ HideModal
                , LoadPetition False url
                ]
    in
    renderPetitionListWithMsg urlToMsg


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
                [ Attributes.title (label ++ ": " ++ (thousands value) ++ " " ++ (pluraliseSignatures value)) ]
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
    = Left
    | Right
    | Center


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


type alias Row a =
    List (Cell a)


-- TODO: Fix this type annotation. It causes a compilation
-- error in Elm 0.18.
-- renderTable : List Header -> Row a -> List (Row (List a)) -> List a -> Html Msg
renderTable headers cells footers data =
    let
        alignAttribute : Align -> Html.Attribute Msg
        alignAttribute align =
            Attributes.style [("text-align", String.toLower (toString align))]

        th : Header -> Html Msg
        th header =
            let
                maybeLink : List (Html Msg) -> List (Html Msg)
                maybeLink content =
                    case header.msg of
                        Just msg ->
                            [ Html.a
                                [ Events.onClick msg
                                , Attributes.href "javascript:;"
                                ]
                                content
                            ]
                        Nothing ->
                            content
            in
            Html.th
                (filterMaybes
                    [ Maybe.map Attributes.title header.title
                    , Maybe.map Attributes.colspan header.span
                    , Maybe.map alignAttribute header.align
                    ]
                )
                (maybeLink
                    [ Html.text header.text
                    , maybeRender (Maybe.map renderIcon header.icon)
                    ]
                )

        td : Cell a -> a -> Html Msg
        td cell item =
            Html.td
                (filterMaybes
                    [ Maybe.map (\f -> Attributes.title (f item)) cell.title
                    , Maybe.map Attributes.colspan cell.span
                    , Maybe.map alignAttribute cell.align
                    ]
                )
                [ Html.text (cell.value item) ]

        tr : List (Cell a) -> a -> Html Msg
        tr cells item =
            Html.tr []
                (List.map (\cell -> td cell item) cells)
    in
    Html.table
        [ Attributes.class "tabular" ]
        [ Html.thead []
            [ Html.tr [] (List.map th headers) ]
        , Html.tfoot []
            (List.map (\cells -> tr cells data) footers)
        , Html.tbody []
            (List.map (tr cells) data)
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


petitionLinks : String -> String -> Bool -> List Link
petitionLinks url title isSaved =
    let
        -- NOTE: Type annotations don't work with tuples.
        -- (String, String, Msg)
        (saveLabel, saveTitle, saveMsg) =
            if isSaved then
                ( "Unsave"
                , "Remove this petition from My Petitions"
                , UnsavePetition
                )
            else
                ( "Save"
                , "Add this petition to My Petitions"
                , SavePetition
                )
    in
    [
        { text = "Refresh"
        , msg = LoadPetition True url
        , title = Just "Reload data for this petition"
        , icon = Nothing
        , class = Nothing
        }
    ,   { text = saveLabel
        , msg = saveMsg (PetitionList.Item url title)
        , title = Just saveTitle
        , icon = Nothing
        , class = Nothing
        }
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

        loadCmd : Cmd Msg
        loadCmd =
            config.id
                |> Maybe.map urlWithId
                |> Maybe.map getPetition
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
                |> (::) loadCmd
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


-- UTILS
-- TODO: Think about moving some of these into modules.


-- JSON Utils


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


-- Maybe Utils


filterMaybes : List (Maybe a) -> List a
filterMaybes =
    List.filterMap identity


listToMaybe : List a -> Maybe (List a)
listToMaybe list =
    if List.isEmpty list then
        Nothing
    else
        Just list


-- Number Utils

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


-- Date Utils


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


-- String Utils


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


pluraliseCountries : Int -> String
pluraliseCountries =
    pluralise "country" "countries"


pluraliseConstituencies : Int -> String
pluraliseConstituencies =
    pluralise "constituency" "constituencies"


pluraliseSignatures : Int -> String
pluraliseSignatures =
    pluralise "signature" "signatures"


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


withJsonExtension : String -> String
withJsonExtension =
    withSuffix ".json"


withoutJsonExtension : String -> String
withoutJsonExtension =
    withoutSuffix ".json"


-- Petition Utils


sort : SortOrder -> (a -> comparable) -> List a -> List a
sort order property =
    case order of
        Asc ->
            List.sortBy property
        Desc ->
            List.reverse << List.sortBy property


sortCountries : SortOptions -> List Country -> List Country
sortCountries opts =
    case opts.by of
        ByCountry ->
            sort opts.order .name
        BySignatures ->
            sort opts.order .signatures
        ByConstituency ->
            identity


sortConstituencies : SortOptions -> List Constituency -> List Constituency
sortConstituencies opts =
    case opts.by of
        ByConstituency ->
            sort opts.order .name
        ByCountry ->
            sort opts.order .code
        BySignatures ->
            sort opts.order .signatures


countryString : Constituencies.Country -> String
countryString country =
    case country of
        Constituencies.Eng ->
            "England"
        Constituencies.NI ->
            "N. Ireland"
        Constituencies.Scot ->
            "Scotland"
        Constituencies.Wales ->
            "Wales"


regionString : Constituencies.Region -> String
regionString region =
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


-- TODO: Replace this function with Http.url if/when
-- that function makes it into Elm 0.18.
-- See https://groups.google.com/forum/#!topic/elm-discuss/XaIr96e8qXk
-- and https://github.com/elm-lang/http/pull/15
url : String -> List (String, String) -> String
url baseUrl args =
    let
        queryPair : (String, String) -> String
        queryPair (key,value) =
            queryEscape key ++ "=" ++ queryEscape value

        queryEscape : String -> String
        queryEscape string =
            String.join "+" (String.split "%20" (Http.encodeUri string))
    in
    case args of
        [] ->
            baseUrl
        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)
