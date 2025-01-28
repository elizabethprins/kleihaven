module Ui.Date exposing (periodString)

import Date
import Time exposing (Month(..), Weekday(..))


periodString : { start : String, end : String } -> String
periodString { start, end } =
    let
        startDate =
            Date.fromIsoString start

        endDate =
            Date.fromIsoString end

        format =
            Date.formatWithLanguage nl "E d MMMM"
    in
    case ( startDate, endDate ) of
        ( Ok start_, Ok end_ ) ->
            if Date.monthNumber start_ == Date.monthNumber end_ then
                Date.formatWithLanguage nl "E d" start_
                    ++ " t/m "
                    ++ format end_

            else
                format start_
                    ++ " t/m "
                    ++ format end_

        ( Ok start_, Err _ ) ->
            format start_

        ( Err _, Ok end_ ) ->
            format end_

        _ ->
            "Nog geen datum"


nl : Date.Language
nl =
    { monthName = toMonthName
    , monthNameShort = toMonthNameShort
    , weekdayName = toWeekdayName
    , weekdayNameShort = toWeekdayNameShort
    , dayWithSuffix = \_ -> ""
    }


toMonthName : Date.Month -> String
toMonthName month =
    case month of
        Jan ->
            "januari"

        Feb ->
            "februari"

        Mar ->
            "maart"

        Apr ->
            "april"

        May ->
            "mei"

        Jun ->
            "juni"

        Jul ->
            "juli"

        Aug ->
            "augustus"

        Sep ->
            "september"

        Oct ->
            "oktober"

        Nov ->
            "november"

        Dec ->
            "december"


toMonthNameShort : Month -> String
toMonthNameShort month =
    case month of
        Jan ->
            "jan"

        Feb ->
            "feb"

        Mar ->
            "mar"

        Apr ->
            "apr"

        May ->
            "mei"

        Jun ->
            "jun"

        Jul ->
            "jul"

        Aug ->
            "aug"

        Sep ->
            "sep"

        Oct ->
            "oct"

        Nov ->
            "nov"

        Dec ->
            "dec"


toWeekdayName : Weekday -> String
toWeekdayName weekday =
    case weekday of
        Mon ->
            "maandag"

        Tue ->
            "dinsdag"

        Wed ->
            "woensdag"

        Thu ->
            "donderdag"

        Fri ->
            "vrijdag"

        Sat ->
            "zaterdag"

        Sun ->
            "zondag"


toWeekdayNameShort : Weekday -> String
toWeekdayNameShort weekday =
    case weekday of
        Mon ->
            "ma"

        Tue ->
            "di"

        Wed ->
            "wo"

        Thu ->
            "do"

        Fri ->
            "vr"

        Sat ->
            "za"

        Sun ->
            "zo"
