module Country exposing
    ( isUK
    , isEU
    )


import Set exposing (Set)


ukCountries : Set String
ukCountries =
    Set.singleton "GB"


euCountries : Set String
euCountries =
    Set.fromList
        -- See https://www.gov.uk/eu-eea
        [ "AT" -- Austria
        , "BE" -- Belgium
        , "BG" -- Bulgaria
        , "HR" -- Croatia
        , "CY" -- Republic of Cyprus
        , "CZ" -- Czech Republic
        , "DK" -- Denmark
        , "EE" -- Estonia
        , "FI" -- Finland
        , "FR" -- France
        , "DE" -- Germany
        , "GR" -- Greece
        , "HU" -- Hungary
        , "IE" -- Ireland
        , "IT" -- Italy
        , "LV" -- Latvia
        , "LT" -- Lithuania
        , "LU" -- Luxembourg
        , "MT" -- Malta
        , "NL" -- Netherlands
        , "PL" -- Poland
        , "PT" -- Portugal
        , "RO" -- Romania
        , "SK" -- Slovakia
        , "SI" -- Slovenia
        , "ES" -- Spain
        , "SE" -- Sweden
        , "GB" -- UK
        ]


isUK : String -> Bool
isUK countryCode =
    Set.member countryCode ukCountries


isEU : String -> Bool
isEU countryCode =
    Set.member countryCode euCountries
