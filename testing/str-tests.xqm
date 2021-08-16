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

declare 
    %test:args("Ordoñez, Carlos d'")        %test:assertEquals("Ordonez, Carlos d'")
    %test:args("Heinrich L’Estocq")         %test:assertEquals("Heinrich L’Estocq")
    %test:args("Abū al-Ḥasan Khān")         %test:assertEquals("Abu al-Hasan Khan")
    %test:args("Štěpánek, Jan Nepomuk")     %test:assertEquals("Stepanek, Jan Nepomuk")
    %test:arg("str", "Méhul", "Müller")      %test:assertEquals("Mehul", "Muller")
    function st:test-strip-diacritics($str as xs:string*) as xs:string* {
        str:strip-diacritics($str)
};

declare 
    %test:args("Frankfurt/Main")            %test:assertEquals("Frankfurt\/Main")
    %test:args("(Frankfurt (Main)")         %test:assertEquals("\(Frankfurt \(Main\)")
    %test:args("(Frankfurt am Main")        %test:assertEquals("\(Frankfurt am Main")
    %test:args("Kan[n] das{]]")             %test:assertEquals("Kan\[n\] das\{\]\]")
    %test:args("?wo? was??")                %test:assertEquals("\?wo\? was\?\?")
    %test:args("Madrid|Mailand")            %test:assertEquals("Madrid\|Mailand")
    %test:args("|")                         %test:assertEquals("\|")
    function st:test-escape-lucene-special-characters($str as xs:string) as xs:string {
        str:escape-lucene-special-characters($str)
};
