xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for processing dates
~:)
module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace pdr="http://pdr.bbaw.de/namespaces/pdrws/";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace functx="http://www.functx.com";

declare variable $date:DATE_FORMAT_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/date", "DateFormatError");

(:~
 : Construct one normalized xs:date from a tei:date element's date or duration attributes (@from, @to, @when, @notBefore, @notAfter)
 :  
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the tei:date
 : @param $latest a boolean whether the constructed date shall be the latest or earliest possible
 : @return the constructed date as xs:date or empty
 :)
declare function date:getOneNormalizedDate($date as element()?, $latest as xs:boolean) as xs:date? {
    if($latest) then max($date/@* ! date:getCastableDate(., $latest))
    else min($date/@* ! date:getCastableDate(., $latest))
};


(:~
 : Checks, if given $date is castable as xs:date and returns this date.
 : If $date is castable as xs:gYear the first or the last day of the year (depending on $latest) will be returned 
 : (Helper function for date:getOneNormalizedDate() and date:printDate())
 : 
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the date to test as xs:string
 : @param $latest if $latest is set to true() the last day of the year will be returned
 : @return the (constructed) date as xs:date, empty-sequence() if no conversion is possible
 :)
declare %private function date:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:date? {
    if($date castable as xs:date) then xs:date($date)
    else if($date castable as xs:dateTime) then
        xs:date(xs:dateTime($date))
    else if($date castable as xs:gYear) then 
        if($latest) then xs:date(concat($date,'-12-31'))
        else xs:date(concat($date,'-01-01'))
    else if($date castable as xs:gYearMonth) then
        if($latest) then xs:date(concat($date, '-', functx:days-in-month(xs:date(concat($date,'-01')))))
        else xs:date(concat($date,'-01'))
    else if($date castable as xs:gMonthDay) then xs:date(concat('9999-', substring-after($date, '--')))
    else if($date castable as xs:gDay) then xs:date(concat('9999-12-', substring-after($date, '---')))
    else()
};

(:~
 : format year specification depending on positive or negative value
 :
 : @author Peter Stadler
 : @param $year the year as (positive or negative) integer
 : @param $lang the language switch (en|de)
 : @return xs:string
 : 
 : @editor Christian Schaper
 : added CE for low years after 0
 :)
declare function date:formatYear($year as xs:int, $lang as xs:string) as xs:string {
    if($year gt 100) then $year cast as xs:string
    else if($year gt 0) then
        if ($lang eq 'en') then concat ($year*1, ' CE')
        else concat ($year*1, ' n.&#8239;Chr.')
    else if($lang eq 'en') then concat($year*-1,' BCE')
    else concat($year*-1,' v.&#8239;Chr.')
};

(:~
 : Parse date from string via PDR webservice
 :
 : @author Peter Stadler
 : @param $input the input string
 : @return tei:date element with the matching part of the string as text content and isodate attributes
 :)
declare function date:parse-date($input as xs:string, $http-get as function() as item()) as element(tei:date)* {
    let $webservice-url := 'https://pdrprod.bbaw.de/pdrws/dates?lang=de&amp;output=xml'
    let $text := 'text=' || encode-for-uri($input)
    let $pdr-result := $http-get(xs:anyURI(string-join(($webservice-url, $text), '&amp;')))//pdr:result
    return 
        if($pdr-result) then 
            for $result in $pdr-result 
            return 
                element tei:date {$result/pdr:isodate/@*, $result/string(pdr:occurrence)}
        else ()
};

(:~
 :  Wrapper around the standard fn:format-date() function
 :  because the current implementation has a bug(?) with dates BC
~:)
declare function date:format-date($date as xs:date, $picture as xs:string, $lang as xs:string) as xs:string? {
    if(starts-with($date, '-')) then format-date($date, replace($picture, '\[Y\]', date:formatYear(year-from-date($date), $lang)), $lang, (), ())
    else format-date($date, $picture, $lang, (), ())
};

(:~
 : Creates a verbal date representation for i.e. birthday or the sending date of a letter in paraphrasing @notBefore, @notAfter etc.
 : Hints on how to call this function and properly set the callback functions can be found (as code) in the testing directory in date-tests.xqm 
 :
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the date element to be displayed
 : @param $lang the current language (en|de)
 : @param $get-language-string a callback function that is expected to return a localized string for a given term. Passed arguments are $term as xs:string, $replacements as xs:string*, and $lang as xs:string 
 : @param $get-picture-string a callback function that is expected to return a picture string for a given language
 : @return text
 :)
declare function date:printDate($date as element()?, $lang as xs:string, $get-language-string as function(xs:string, xs:string*, xs:string) as xs:string, $get-picture-string as function(xs:string) as xs:string) as xs:string? {
    if($date) then (
        let $picture-string := $get-picture-string($lang) (: if($lang = 'de') then '[D1o] [MNn] [Y]' else '[MNn] [D], [Y]':)
        let $picture-string-day := replace($picture-string, '\[M[^\]]*\]|(,\s)?\[Y[^\]]*\]', '') => normalize-space() (: strip off month and year specifier from the picture string :)
        let $notBefore  := if($date/@notBefore) then date:getCastableDate(data($date/@notBefore),false())
                           else if($date/@notBefore-iso) then date:getCastableDate(data($date/@notBefore-iso),false())
                           else()
        let $notAfter   := if($date/@notAfter) then date:getCastableDate(data($date/@notAfter),true())
                           else if($date/@notAfter-iso) then date:getCastableDate(data($date/@notAfter-iso),true())
                           else()
        let $from       := if($date/@from) then date:getCastableDate(data($date/@from),false()) 
                           else if($date/@from-iso) then date:getCastableDate(data($date/@from-iso),false())
                           else if($date/@when-iso and contains($date/@when-iso, '/')) then date:getCastableDate(data(substring-before($date/@when-iso, '/')),false())
                           else()
        let $to         := if($date/@to)  then date:getCastableDate(data($date/@to),true())
                           else if($date/@to-iso) then date:getCastableDate(data($date/@to-iso),true())
                           else if($date/@when-iso and contains($date/@when-iso, '/')) then date:getCastableDate(data(substring-after($date/@when-iso, '/')),true())                            
                           else()
        let $notBefore_o := if($date/@notBefore-iso) then string($date/@notBefore-iso) else()
        let $notAfter_o  := if($date/@notAfter-iso)  then string($date/@notAfter-iso) else()
        let $from_o     := if($date/@from-iso) then string($date/@from-iso)
                           else if($date/@when-iso and contains($date/@when-iso, '/')) then substring-before($date/@when-iso, '/')
                           else()
        let $to_o       := if($date/@to-iso) then string($date/@to-iso)
                           else if($date/@when-iso and contains($date/@when-iso, '/')) then substring-after($date/@when-iso, '/')
                           else()
        
        let $myDate := 
            if($date/@when) then 
                if($date/@when castable as xs:date) then date:format-date($date/@when, $picture-string, $lang)
                else if($date/@when castable as xs:gYear) then date:formatYear($date/@when, $lang)
                else if($date/@when castable as xs:gYearMonth) then date:format-date(date:getCastableDate(data($date/@when),true()),'[MNn] [Y]', $lang)
                else if($date/@when castable as xs:gMonthDay) then $get-language-string('noYear',xs:string(date:format-date(date:getCastableDate(data($date/@when),true()),'[D]. [MNn]', $lang)), $lang)
                else if($date/@when castable as xs:gDay) then $get-language-string('noYearMonth',xs:string(date:format-date(date:getCastableDate(data($date/@when),true()),'[D].', $lang)), $lang)
                else if($date/@when castable as xs:dateTime) then date:format-date(xs:date(xs:dateTime($date/@when)), $picture-string, $lang)
                else error($date:DATE_FORMAT_ERROR, 'unsupported value for @when: "' || $date/@when || '".')
           (:  @when-iso für die busoni-app :)
             else if($date/@when-iso and not(contains($date/@when-iso, '/'))) then 
                if($date/@when-iso castable as xs:date) then date:format-date($date/@when-iso, $picture-string, $lang)
                else if($date/@when-iso castable as xs:gYear) then date:formatYear($date/@when-iso, $lang)
                else if($date/@when-iso castable as xs:gYearMonth) then date:format-date(date:getCastableDate(data($date/@when-iso),true()),'[MNn] [Y]', $lang)
                else if($date/@when-iso castable as xs:gMonthDay) then $get-language-string('noYear',xs:string(date:format-date(date:getCastableDate(data($date/@when-iso),true()),'[D]. [MNn]', $lang)), $lang)
                else if($date/@when-iso castable as xs:gDay) then $get-language-string('noYearMonth',xs:string(date:format-date(date:getCastableDate(data($date/@when-iso),true()),'[D].', $lang)), $lang)
                else if($date/@when-iso castable as xs:dateTime) then date:format-date(xs:date(xs:dateTime($date/@when-iso)), $picture-string, $lang)
                else error($date:DATE_FORMAT_ERROR, 'unsupported value for @when-iso: "' || $date/@when-iso || '".')                         
            else if(exists($notBefore)) then 
                if(exists($notAfter)) then 
                    if(year-from-date($notBefore) eq year-from-date($notAfter)) then 
                        if(month-from-date($notBefore) eq month-from-date($notAfter)) then 
                            if(day-from-date($notBefore) = 1 and day-from-date($notAfter) = functx:days-in-month($notAfter)) then date:format-date($notBefore,'[MNn] [Y]', $lang) (: August 1879 :)
                            else $get-language-string('dateBetween',(date:format-date($notBefore,$picture-string-day, $lang),date:format-date($notAfter,$picture-string, $lang)), $lang) (: Zwischen 1. und 7. August 1801 :)
                        else if(ends-with($notBefore, '01-01') and ends-with($notAfter, '12-31')) then date:formatYear(year-from-date($notBefore), $lang) (: 1879 :)
                        else if($notBefore_o castable as xs:gYearMonth) then
                            if($notAfter_o castable as xs:gYearMonth) then $get-language-string('dateBetween',(xs:string(date:format-date($notBefore,'[MNn]', $lang)),date:format-date($notAfter,'[MNn] [Y]', $lang)), $lang) (: Zwischen Mai und August 1909 :)
                            else $get-language-string('dateBetween',(xs:string(date:format-date($notBefore,'[MNn]', $lang)),date:format-date($notAfter,$picture-string, $lang)), $lang) (: Zwischen Mai und 8. August 1909 :)
                        else if($notAfter_o castable as xs:gYearMonth) then $get-language-string('dateBetween', (xs:string(date:format-date($notBefore,$picture-string, $lang)),date:format-date($notAfter,'[MNn] [Y]', $lang)), $lang) (: Zwischen 1. Juli 1789 und August 1789 :)
                        else $get-language-string('dateBetween', (replace(date:format-date($notBefore,$picture-string, $lang), '(,\s+)?' || year-from-date($notBefore), ''), date:format-date($notAfter,$picture-string, $lang)), $lang) (: Zwischen 1. Juli 1789 und 4. August 1789 :)
                    else if($notBefore_o castable as xs:gYear) then
                        if($notAfter_o castable as xs:gYear) then $get-language-string('dateBetween',(date:formatYear(year-from-date($notBefore), $lang),date:formatYear(year-from-date($notAfter), $lang)), $lang) (: Zwischen 1879 und 1881 :)
                        else if($notAfter_o castable as xs:gYearMonth) then $get-language-string('dateBetween',(date:formatYear(year-from-date($notBefore), $lang),date:format-date($notAfter,'[MNn] [Y]', $lang)), $lang) (: Zwischen 1879 und März 1881 :)
                        else $get-language-string('dateBetween', (date:formatYear(year-from-date($notBefore), $lang), date:format-date($notAfter,$picture-string, $lang)), $lang) (: Zwischen 1709 und 4. August 1789 :)
                    else if($notBefore_o castable as xs:gYearMonth) then
                        if($notAfter_o castable as xs:gYear) then $get-language-string('dateBetween',(date:format-date($notAfter,'[MNn] [Y]', $lang),date:formatYear(year-from-date($notAfter), $lang)), $lang) (: Zwischen März 1879 und 1881 :)
                        else if($notAfter_o castable as xs:gYearMonth) then $get-language-string('dateBetween',(date:format-date($notAfter,'[MNn] [Y]', $lang),date:format-date($notAfter,'[MNn] [Y]', $lang)), $lang) (: Zwischen März 1879 und März 1881 :)
                        else $get-language-string('dateBetween', (date:formatYear(year-from-date($notBefore), $lang), date:format-date($notAfter,$picture-string, $lang)), $lang) (: zwischen Mai 1709 und 4. August 1789 :)
                    else if($notAfter_o castable as xs:gYear) then $get-language-string('dateBetween', (date:format-date($notBefore,$picture-string, $lang), date:formatYear(year-from-date($notAfter), $lang)), $lang) (: Zwischen 1. Juli 1709 und 1789 :)
                    else if($notAfter_o castable as xs:gYearMonth) then $get-language-string('dateBetween', (date:format-date($notBefore,$picture-string, $lang), date:format-date($notAfter,'[MNn] [Y]', $lang)), $lang) (: Zwischen 1. Juli 1709 und August 1789 :)
                    else $get-language-string('dateBetween', (date:format-date($notBefore,$picture-string, $lang), date:format-date($notAfter,$picture-string, $lang)), $lang) (: Zwischen 1. Juli 1709 und 4. August 1789 :)
                else if($notBefore_o castable as xs:gYear) then $get-language-string('dateNotBefore', (date:formatYear(year-from-date($notBefore), $lang)), $lang) (: Frühestens 1709 :)
                else if($notBefore_o castable as xs:gYearMonth) then $get-language-string('dateNotBefore', (date:format-date($notBefore,'[MNn] [Y]', $lang)), $lang) (: Frühestens Juli 1709 :)
                else $get-language-string('dateNotBefore', (date:format-date($notBefore,$picture-string, $lang)), $lang) (: Frühestens 1. Juli 1709 :)
            else if(exists($notAfter)) then
                if($notAfter_o castable as xs:gYear) then $get-language-string('dateNotAfter', (date:formatYear(year-from-date($notAfter), $lang)), $lang) (: Spätestens 1709 :)
                else if($notAfter_o castable as xs:gYearMonth) then $get-language-string('dateNotAfter', (date:format-date($notAfter,'[MNn] [Y]', $lang)), $lang) (: Spätestens Juli 1709 :)
                else $get-language-string('dateNotAfter', (date:format-date($notAfter,$picture-string, $lang)), $lang) (: Spätestens 1. Juli 1709 :)
            else if(exists($from)) then             
                if(exists($to)) then 
                    if(year-from-date($from) eq year-from-date($to)) then 
                        if(month-from-date($from) eq month-from-date($to)) then 
                            if(day-from-date($from) = 1 and day-from-date($to) = functx:days-in-month($to)) then date:format-date($from,'[MNn] [Y]', $lang) (: August 1879 :)
                            else $get-language-string('fromTo',(date:format-date($from,$picture-string-day, $lang),date:format-date($to,$picture-string, $lang)), $lang) (: Vom 1. bis 7. August 1801 :)
                        else if(ends-with($from, '01-01') and ends-with($to, '12-31')) then date:formatYear(year-from-date($from), $lang) (: 1879 :)
                        else if($from_o castable as xs:gYearMonth) then
                            if($to_o castable as xs:gYearMonth) then $get-language-string('noFromTo',(date:format-date($from,'[MNn]', $lang),date:format-date($to,'[MNn] [Y]', $lang)), $lang) (: Mai bis August 1909 :)
                            else $get-language-string('noFromTo',(date:format-date($from,'[MNn]', $lang),date:format-date($to,$picture-string, $lang)), $lang) (: Mai bis 8. August 1909 :)
                        else if($to_o castable as xs:gYearMonth) then $get-language-string('noFromTo',(replace(date:format-date($from,$picture-string, $lang), '(,\s+)?' || date:formatYear(year-from-date($from), $lang), ''), date:format-date($to,'[MNn] [Y]', $lang)), $lang) (: 4. Juli bis August 1789 :)
                        else $get-language-string('fromTo', (replace(date:format-date($from,$picture-string, $lang), '(,\s+)?' || date:formatYear(year-from-date($from), $lang), ''), date:format-date($to,$picture-string, $lang)), $lang) (: Vom 1. Juli bis 4. August 1789 :)
                    else if($from_o castable as xs:gYear) then
                        if($to_o castable as xs:gYear) then $get-language-string('noFromTo',(date:formatYear(year-from-date($from), $lang),date:formatYear(year-from-date($to), $lang)), $lang) (: 1879 bis 1881 :)
                        else if($to_o castable as xs:gYearMonth) then $get-language-string('noFromTo',(date:formatYear(year-from-date($from), $lang),date:format-date($to,'[MNn] [Y]', $lang)), $lang) (: 1879 bis März 1881 :)
                        else $get-language-string('noFromTo', (date:formatYear(year-from-date($from), $lang), date:format-date($to,$picture-string, $lang)), $lang) (: 1709 bis 4. August 1789 :)
                    else if($from_o castable as xs:gYearMonth) then
                        if($to_o castable as xs:gYear) then $get-language-string('noFromTo',(date:format-date($from,'[MNn] [Y]', $lang),date:formatYear(year-from-date($to), $lang)), $lang) (: März 1879 bis 1881 :)
                        else if($to_o castable as xs:gYearMonth) then $get-language-string('noFromTo',(date:format-date($from,'[MNn] [Y]', $lang),date:format-date($to,'[MNn] [Y]', $lang)), $lang) (: März 1879 bis März 1881 :)
                        else $get-language-string('noFromTo', (date:format-date($from,'[MNn] [Y]', $lang), date:format-date($to,$picture-string, $lang)), $lang) (: Mai 1709 bis 4. August 1789 :)
                    else if($to_o castable as xs:gYear) then $get-language-string('fromTo', (date:format-date($from,$picture-string, $lang), date:formatYear(year-from-date($to), $lang)), $lang) (: Vom 1. Juli 1709 bis 1789 :)
                    else if($to_o castable as xs:gYearMonth) then $get-language-string('fromTo', (date:format-date($from,$picture-string, $lang), date:format-date($to,'[MNn] [Y]', $lang)), $lang) (: Vom 1. Juli 1709 bis August 1789 :)
                    else $get-language-string('fromTo', (date:format-date($from,$picture-string, $lang), date:format-date($to,$picture-string, $lang)), $lang) (: Vom 1. Juli 1709 bis 4. August 1789 :)
                else if($from_o castable as xs:gYear) then $get-language-string('fromToUnknown', date:formatYear(year-from-date($from), $lang), $lang) (: seit 1709 bis unbekannt :)
                else if($from_o castable as xs:gYearMonth) then $get-language-string('fromToUnknown', date:format-date($from,'[MNn] [Y]', $lang), $lang) (: von Juli 1709 bis unbekannt :)
                else $get-language-string('fromToUnknown', date:format-date($from,$picture-string, $lang), $lang) (: Vom 1. Juli 1709 bis unbekannt :)
            else if(exists($to)) then
                if ($to_o castable as xs:gYear) then $get-language-string('unknownTo', (date:formatYear(year-from-date($to), $lang)), $lang) (: von unbekannt bis 1709 :)
                else if ($to_o castable as xs:gYearMonth) then $get-language-string('unknownTo', (date:format-date($to,'[MNn] [Y]', $lang)), $lang) (: von unbekannt bis Juli 1709 :)
                else $get-language-string('unknownTo', (date:format-date($to,$picture-string, $lang)), $lang) (: von unbekannt bis 1. Juli 1709 :)
            else if(normalize-space($date) castable as xs:date) then date:format-date(xs:date(normalize-space($date)),$picture-string, $lang)
            else $get-language-string('dateUnknown', (), $lang)
        return 
            if(exists($myDate)) then string($myDate)
            else error($date:DATE_FORMAT_ERROR, string-join(('date:printDate()', 'wrong date format', serialize($date, <output:serialization-parameters><output:method>text</output:method></output:serialization-parameters>)), ' ;; '))
    )
    else ()
};

(:~
 :  Translate a Gregorian date to the Julian calendar
 :  NB: since the Julian calendar features leap years which are not present in the Gregorian calendar
 :  the returned datatype cannot be xs:date which is assumed to be a "valid representation of an XML Gregorian Calendar value".
 :  Hence the return type is xs:string in the format 'YYYY-MM-DD'
 :  see https://de.wikipedia.org/wiki/Umrechnung_zwischen_julianischem_und_gregorianischem_Kalender.
 :  The earliest supported Gregorian date is 1582-10-15, dates before will result in an empty sequence. 
 :
 :  @param $date the input date according to the Gregorian calendar  
 :  @return the converted date according to the Julian calendar
~:)
declare function date:gregorian2julian($date as xs:date) as xs:string? {
    if($date < xs:date('1582-10-15')) then ()
    else (
        let $JH :=
            if(month-from-date($date) lt 3) then floor((year-from-date($date) -1) div 100)
            else floor(year-from-date($date) div 100)
        let $diff := 3*(floor($JH div 4)) + ($JH mod 4) -2
        (: The Julian calendar has additional leap years, e.g. 1700, 1800, 1900 :)
        let $julianLeapYear := (year-from-date($date) mod 100 = 0) and not(year-from-date($date) mod 400 = 0)
        let $julianDate := $date - xs:dayTimeDuration('P' || $diff || 'D')
        return
            (: when going from March to February in a Julian leap year we need to add an extra day :)
            if($julianLeapYear and month-from-date($date) = 3 and month-from-date($julianDate) = 2)
            then substring($julianDate, 1, 8) || string(day-from-date($julianDate) + 1)
            else string($julianDate)
    )
};

(:~
 : Helper function returning RFC 822 compliant date
 : 
 : @author Benjamin W. Bohl, Bernd Alois Zimmermann-Gesamtausgabe
 : @param $dateTime input xs:dateTime
 : @return the constructed RFC 822 date-time as string
~:)
declare function date:rfc822($dateTime as xs:dateTime) as xs:string {
    let $year := year-from-date($dateTime)
    let $month := substring(format-date($dateTime,'[MNn]'), 1, 3)
    let $day := functx:pad-integer-to-length(day-from-date($dateTime), 2)
    let $day.string := substring(format-date($dateTime,'[F]'), 1, 3)
    let $time := format-time($dateTime,"[H]:[m]:[s]")
    let $timezone := 
        if(exists(timezone-from-dateTime($dateTime)))
        then translate(format-date($dateTime, '[Z]'), ':', '')
        else '+0000'
    return (
        $day.string ||', '|| $day || ' ' || $month || ' ' || $year || ' ' || $time || ' ' || $timezone
    )
};
