xquery version "3.1";

module namespace dt="http://xquery.weber-gesamtausgabe.de/modules/date-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "../xquery/date.xqm";

declare 
    %test:args("1817-01-04", "true")        %test:assertEquals("1817-01-04")
    %test:args("-1317-11-03", "true")       %test:assertEquals("-1317-11-03")
    %test:args("1317", "true")              %test:assertEquals("1317-12-31")
    %test:args("1817", "false")             %test:assertEquals("1817-01-01")
    %test:args("-1817", "false")            %test:assertEquals("-1817-01-01")
    %test:args("1317-11", "true")           %test:assertEquals("1317-11-30")
    %test:args("1817-05", "false")          %test:assertEquals("1817-05-01")
    %test:args("-1817-11", "false")         %test:assertEquals("-1817-11-01")
    %test:args("1999-05-31T13:20:00-05:00", "false")         %test:assertEquals("1999-05-31")
    %test:args("-1999-05-31T13:20:00-05:00", "false")        %test:assertEquals("-1999-05-31")
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