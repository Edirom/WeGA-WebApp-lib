xquery version "3.1";

module namespace dt="http://xquery.weber-gesamtausgabe.de/modules/date-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "../xquery/date.xqm";
import module namespace functx="http://www.functx.com";

declare 
    %test:args("1817-01-04", "true")        %test:assertEquals("1817-01-04")
    %test:args("-1317-11-03", "true")       %test:assertEquals("-1317-11-03")
    %test:args("1317", "true")              %test:assertEquals("1317-12-31")
    %test:args("1817", "false")             %test:assertEquals("1817-01-01")
    %test:args("-1817", "false")            %test:assertEquals("-1817-01-01")
    %test:args("1317-11", "true")           %test:assertEquals("1317-11-30")
    %test:args("1817-05", "false")          %test:assertEquals("1817-05-01")
    %test:args("-1817-11", "false")         %test:assertEquals("-1817-11-01")
    %test:args("1999-05-31T13:20:00-05:00", "false")         %test:assertEquals("1999-05-31-05:00")
    %test:args("-1999-05-31T13:20:00-05:00", "false")        %test:assertEquals("-1999-05-31-05:00")
    function dt:test-getOneNormalizedDate-when($date as xs:string, $latest as xs:boolean) as xs:date? {
    let $dateElement := <tei:date when="{$date}"/>
    return
        date:getOneNormalizedDate($dateElement, $latest)
};

declare 
    %test:args("1817-01-04", "1817-01-08", "true")      %test:assertEquals("1817-01-08")
    %test:args("-1317-11-03", "-1316-05-03", "true")    %test:assertEquals("-1316-05-03")
    %test:args("1317", "1817", "true")                  %test:assertEquals("1817-12-31")
    %test:args("-1817", "-1317", "false")               %test:assertEquals("-1817-01-01")
    %test:args("1317-11", "1817-01-08", "true")         %test:assertEquals("1817-01-08")
    %test:args("-1817-11", "-1817-05", "false")         %test:assertEquals("-1817-05-01")
    function dt:test-getOneNormalizedDate-from-to($date1 as xs:string, $date2 as xs:string, $latest as xs:boolean) as xs:date? {
    let $dateElement := <tei:date from="{$date1}" to="{$date2}"/>
    return
        date:getOneNormalizedDate($dateElement, $latest)
};

declare 
    %test:args("1817-11-01")    %test:assertEquals("1. November 1817")
    %test:args("1817-11")       %test:assertEquals("November 1817")
    %test:args("1817")          %test:assertEquals("1817")
    function dt:test-printDate-when($date as xs:string) as xs:string? {
    let $dateElement := <tei:date when="{$date}"/>
    return
        date:printDate($dateElement, 'de', dt:translate#3, function($lang) {'[D1o] [MNn] [Y]'})
};

declare 
    %test:args("1817-11-01", "1817-11-30", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("November 1817")
    %test:args("1817-11-02", "1817-11-30", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("vom 2. bis 30. November 1817")
    %test:args("1817-11-02", "1817-12-02", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("vom 2. November  bis 2. Dezember 1817")
    %test:args("1817-11-02", "1818-12-02", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("vom 2. November 1817 bis 2. Dezember 1818")
    %test:args("1817-11", "1817-12", "de", "[D1o] [MNn] [Y]")        %test:assertEquals("vom 1. November  bis 31. Dezember 1817")
    %test:args("1817-11", "1818-12", "de", "[D1o] [MNn] [Y]")        %test:assertEquals("vom 1. November 1817 bis 31. Dezember 1818")
    %test:args("1817", "1818", "de", "[D1o] [MNn] [Y]")              %test:assertEquals("vom 1. Januar 1817 bis 31. Dezember 1818")
    %test:args("1817-11-11", "", "de", "[D1o] [MNn] [Y]")            %test:assertEquals("vom 11. November 1817 bis unbekannt")
    %test:args("1817-11", "", "de", "[D1o] [MNn] [Y]")               %test:assertEquals("vom 1. November 1817 bis unbekannt")
    %test:args("1817", "", "de", "[D1o] [MNn] [Y]")                  %test:assertEquals("vom 1. Januar 1817 bis unbekannt")
    %test:args("", "1817", "de", "[D1o] [MNn] [Y]")                  %test:assertEquals("von unbekannt bis 31. Dezember 1817")
    %test:args("", "1817-11", "de", "[D1o] [MNn] [Y]")               %test:assertEquals("von unbekannt bis 30. November 1817")
    %test:args("", "1817-11-20", "de", "[D1o] [MNn] [Y]")            %test:assertEquals("von unbekannt bis 20. November 1817")
    %test:args("1817-11-01", "1817-11-30", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("November 1817")
    %test:args("1817-11-02", "1817-11-30", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("vom 2nd bis November 30th, 1817")
    %test:args("1817-11-02", "1817-12-02", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("vom November 2nd bis December 2nd, 1817")
    %test:args("1817-11-02", "1818-12-02", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("vom November 2nd, 1817 bis December 2nd, 1818")
    %test:args("1817-11", "1817-12", "en", "[MNn] [D1o], [Y]")        %test:assertEquals("vom November 1st bis December 31st, 1817")
    %test:args("1817-11", "1818-12", "en", "[MNn] [D1o], [Y]")        %test:assertEquals("vom November 1st, 1817 bis December 31st, 1818")
    %test:args("1817", "1818", "en", "[MNn] [D1o], [Y]")              %test:assertEquals("vom January 1st, 1817 bis December 31st, 1818")
    %test:args("1817-11-11", "", "en", "[MNn] [D1o], [Y]")            %test:assertEquals("vom November 11th, 1817 bis unbekannt")
    %test:args("1817-11", "", "en", "[MNn] [D1o], [Y]")               %test:assertEquals("vom November 1st, 1817 bis unbekannt")
    %test:args("1817", "", "en", "[MNn] [D1o], [Y]")                  %test:assertEquals("vom January 1st, 1817 bis unbekannt")
    %test:args("", "1817", "en", "[MNn] [D1o], [Y]")                  %test:assertEquals("von unbekannt bis December 31st, 1817")
    %test:args("", "1817-11", "en", "[MNn] [D1o], [Y]")               %test:assertEquals("von unbekannt bis November 30th, 1817")
    %test:args("", "1817-11-20", "en", "[MNn] [D1o], [Y]")            %test:assertEquals("von unbekannt bis November 20th, 1817")
    function dt:test-printDate-from-to($date1 as xs:string, $date2 as xs:string, $lang as xs:string, $picture-string as xs:string) as xs:string? {
    let $dateElement := <tei:date from="{$date1}" to="{$date2}"/>
    return
        date:printDate($dateElement, $lang, dt:translate#3, function($lang) {$picture-string})
};

declare 
    %test:args("1817-11-01", "1817-11-30", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("November 1817")
    %test:args("1817-11-02", "1817-11-30", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("zwischen 2. und 30. November 1817")
    %test:args("1817-11-02", "1817-12-02", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("zwischen 2. November  und 2. Dezember 1817")
    %test:args("1817-11-02", "1818-12-02", "de", "[D1o] [MNn] [Y]")  %test:assertEquals("zwischen 2. November 1817 und 2. Dezember 1818")
    %test:args("1817-11", "1817-12", "de", "[D1o] [MNn] [Y]")        %test:assertEquals("zwischen 1. November  und 31. Dezember 1817")
    %test:args("1817-11", "1818-12", "de", "[D1o] [MNn] [Y]")        %test:assertEquals("zwischen 1. November 1817 und 31. Dezember 1818")
    %test:args("1817", "1818", "de", "[D1o] [MNn] [Y]")              %test:assertEquals("zwischen 1. Januar 1817 und 31. Dezember 1818")
    %test:args("1817-11-11", "", "de", "[D1o] [MNn] [Y]")            %test:assertEquals("frühestens am 11. November 1817")
    %test:args("1817-11", "", "de", "[D1o] [MNn] [Y]")               %test:assertEquals("frühestens am 1. November 1817")
    %test:args("1817", "", "de", "[D1o] [MNn] [Y]")                  %test:assertEquals("frühestens am 1. Januar 1817")
    %test:args("", "1817", "de", "[D1o] [MNn] [Y]")                  %test:assertEquals("spätestens am 31. Dezember 1817")
    %test:args("", "1817-11", "de", "[D1o] [MNn] [Y]")               %test:assertEquals("spätestens am 30. November 1817")
    %test:args("", "1817-11-20", "de", "[D1o] [MNn] [Y]")            %test:assertEquals("spätestens am 20. November 1817")
    %test:args("1817-11-01", "1817-11-30", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("November 1817")
    %test:args("1817-11-02", "1817-11-30", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("zwischen 2nd und November 30th, 1817")
    %test:args("1817-11-02", "1817-12-02", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("zwischen November 2nd und December 2nd, 1817")
    %test:args("1817-11-02", "1818-12-02", "en", "[MNn] [D1o], [Y]")  %test:assertEquals("zwischen November 2nd, 1817 und December 2nd, 1818")
    %test:args("1817-11", "1817-12", "en", "[MNn] [D1o], [Y]")        %test:assertEquals("zwischen November 1st und December 31st, 1817")
    %test:args("1817-11", "1818-12", "en", "[MNn] [D1o], [Y]")        %test:assertEquals("zwischen November 1st, 1817 und December 31st, 1818")
    %test:args("1817", "1818", "en", "[MNn] [D1o], [Y]")              %test:assertEquals("zwischen January 1st, 1817 und December 31st, 1818")
    %test:args("1817-11-11", "", "en", "[MNn] [D1o], [Y]")            %test:assertEquals("frühestens am November 11th, 1817")
    %test:args("1817-11", "", "en", "[MNn] [D1o], [Y]")               %test:assertEquals("frühestens am November 1st, 1817")
    %test:args("1817", "", "en", "[MNn] [D1o], [Y]")                  %test:assertEquals("frühestens am January 1st, 1817")
    %test:args("", "1817", "en", "[MNn] [D1o], [Y]")                  %test:assertEquals("spätestens am December 31st, 1817")
    %test:args("", "1817-11", "en", "[MNn] [D1o], [Y]")               %test:assertEquals("spätestens am November 30th, 1817")
    %test:args("", "1817-11-20", "en", "[MNn] [D1o], [Y]")            %test:assertEquals("spätestens am November 20th, 1817")
    function dt:test-printDate-notBefore-notAfter($date1 as xs:string, $date2 as xs:string, $lang as xs:string, $picture-string as xs:string) as xs:string? {
    let $dateElement := <tei:date notBefore="{$date1}" notAfter="{$date2}"/>
    return
        date:printDate($dateElement, $lang, dt:translate#3, function($lang) {$picture-string})
};

declare %private function dt:translate($term as xs:string, $replacements as xs:string*, $lang as xs:string) {
    let $localized-string :=
        switch($term)
        case 'dateBetween'      return 'zwischen %1 und %2'
        case 'dateNotBefore'    return 'frühestens am %1'
        case 'dateNotAfter'     return 'spätestens am %1'
        case 'noFromTo'         return '%1 bis %2'
        case 'fromTo'           return 'vom %1 bis %2'
        case 'fromToUnknown'    return 'vom %1 bis unbekannt'
        case 'unknownTo'        return 'von unbekannt bis %1'
        case 'dateUnknown'      return 'Datum unbekannt'
        default                 return 'Error !'
    let $placeHolders := 
        for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return 
        functx:replace-multi($localized-string,$placeHolders,$replacements)
};
