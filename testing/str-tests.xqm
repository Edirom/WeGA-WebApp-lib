xquery version "3.1";

module namespace st="http://xquery.weber-gesamtausgabe.de/modules/str-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "../xquery/str.xqm";

declare 
    %test:args("D'Alembert, Jean-Baptiste") %test:assertEquals("Jean-Baptiste D'Alembert")
    %test:args("Orville, Philipp d'")       %test:assertEquals("Philipp d’Orville")
    %test:args("Heinrich L’Estocq")         %test:assertEquals("Heinrich L’Estocq")
    %test:args("L’Estocq, Heinrich")        %test:assertEquals("Heinrich L’Estocq")
    %test:args("Ordoñez, Carlos d'")        %test:assertEquals("Carlos d’Ordoñez")
    %test:args("Caroline, geb. Gräfin Clary Aldringen, verw. Gräfin Wurmbrand")        %test:assertEquals("Caroline, geb. Gräfin Clary Aldringen, verw. Gräfin Wurmbrand")
    function st:test-print-forename-surname($name as xs:string) as xs:string {
        str:print-forename-surname($name)
};
