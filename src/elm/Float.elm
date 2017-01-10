module Float exposing
    ( toString
    , toStringN
    )


import String


toString : Float -> Result String String
toString value =
    expandScientific (Basics.toString value)


toStringN : Int -> Float -> Result String String
toStringN dps value =
    if isNaN value then
        Err "NaN"
    else if isInfinite value then
        Err "Infinity"
    else if dps < 0 then
        Err "Decimal places cannot be less than 0"
    else
        let
            rounding : Float
            rounding =
                0.5 / (toFloat (10 ^ dps))

            roundedValue : Float
            roundedValue =
                if value < 0 then
                    value - rounding
                else
                    value + rounding

            parts : Maybe (String, String)
            parts =
                toString roundedValue
                    |> Result.toMaybe
                    |> Maybe.andThen splitNum
        in
        case parts of
            Nothing ->
                Err "Unexpected result when converting float to string"
            Just (integer, fractional) ->
                if dps > 0 then
                    fractional
                        |> String.left dps
                        |> String.padRight dps '0'
                        |> String.cons '.'
                        |> String.append integer
                        |> Ok
                else
                    Ok integer


expandScientific : String -> Result String String
expandScientific value =
    case String.split "e" value of
        [ num, pow ] ->
            case String.toInt (unplus pow) of
                Ok pow ->
                    case splitNum num of
                        Just (integer, fractional) ->
                            Ok (shiftDecimal pow integer fractional)
                        Nothing ->
                            Err ("Could not expand '" ++ value ++ "': '" ++ num ++ "' is in an unexpected format")
                Err err ->
                    Err ("Could not expand '" ++ value ++ "': '" ++ pow ++ "' is not a valid integer")
        [ num ] ->
            Ok num
        _ ->
            Err ("Could not expand '" ++ value ++ "': input string is in an unexpected format")


shiftDecimal : Int -> String -> String -> String
shiftDecimal times =
    if times >= 0 then
        shiftDecimalR times
    else
        shiftDecimalL (abs times)


shiftDecimalR : Int -> String -> String -> String
shiftDecimalR times integer fractional =
    if times == 0 then
        case fractional of
            "" ->
                integer
            _ ->
                integer ++ "." ++ fractional
    else
        case String.uncons fractional of
            Just (digit, tail) ->
                shiftDecimalR (times - 1) (integer ++ String.fromChar digit) tail
            Nothing ->
                shiftDecimalR (times - 1) (integer ++ "0") ""


shiftDecimalL : Int -> String -> String -> String
shiftDecimalL times integer fractional =
    if times == 0 then
        case integer of
            "" ->
                "0." ++ fractional
            "-" ->
                "-0." ++ fractional
            _ ->
                integer ++ "." ++ fractional
    else
        case String.right 1 integer of
            "" ->
                shiftDecimalL (times - 1) "" ("0" ++ fractional)
            "-" ->
                shiftDecimalL (times - 1) "-" ("0" ++ fractional)
            digit ->
                shiftDecimalL (times - 1) (String.dropRight 1 integer) (digit ++ fractional)


unplus : String -> String
unplus value =
    case String.uncons value of
        Just ('+', tail) ->
            tail
        _ ->
            value


splitNum : String -> Maybe (String, String)
splitNum value =
    case String.split "." value of
        [ integer, fractional ] ->
            Just (integer, fractional)
        [ integer ] ->
            Just (integer, "")
        _ ->
            Nothing
