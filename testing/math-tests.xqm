xquery version "3.1";

module namespace mt="http://xquery.weber-gesamtausgabe.de/modules/math-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";
import module namespace m="http://xquery.weber-gesamtausgabe.de/modules/math" at "../xquery/math.xqm";

declare 
    %test:args("1")         %test:assertEquals("1")
    %test:args("15")        %test:assertEquals("F")
    %test:args("1024")      %test:assertEquals("400")
    %test:args("32756")     %test:assertEquals("7FF4")
    %test:args("35631")     %test:assertEquals("8B2F")
    %test:args("1048575")   %test:assertEquals("FFFFF")
    %test:args("-1")        %test:assertEquals("-1")
    %test:args("-15")       %test:assertEquals("-F")
    %test:args("-1024")     %test:assertEquals("-400")
    %test:args("-32756")    %test:assertEquals("-7FF4")
    %test:args("-35631")    %test:assertEquals("-8B2F")
    %test:args("-1048575")  %test:assertEquals("-FFFFF")
    function mt:test-int2hex($i as xs:int) as xs:string {
        m:int2hex($i)
};

declare 
    %test:args("1", "5")         %test:assertEquals("00001")
    %test:args("15", "8")        %test:assertEquals("0000000F")
    %test:args("1024", "3")      %test:assertEquals("400")
    %test:args("32756", "3")     %test:assertEquals("7FF4")
    %test:args("35631", "5")     %test:assertEquals("08B2F")
    %test:args("1048575", "8")   %test:assertEquals("000FFFFF")
    %test:args("-1", "5")        %test:assertEquals("-00001")
    %test:args("-15", "8")       %test:assertEquals("-0000000F")
    %test:args("-1024", "3")     %test:assertEquals("-400")
    %test:args("-32756", "3")    %test:assertEquals("-7FF4")
    %test:args("-35631", "5")    %test:assertEquals("-08B2F")
    %test:args("-1048575", "8")  %test:assertEquals("-000FFFFF")
    function mt:test-int2hex-minLength($i as xs:int, $j as xs:int) as xs:string {
        m:int2hex($i, $j)
};

declare 
    %test:args("1")         %test:assertEquals("1")
    %test:args("F")         %test:assertEquals("15")
    %test:args("0F")        %test:assertEquals("15")
    %test:args("400")       %test:assertEquals("1024")
    %test:args("7fF4")      %test:assertEquals("32756")
    %test:args("8b2F")      %test:assertEquals("35631")
    %test:args("0008b2F")   %test:assertEquals("35631")
    %test:args("FFffF")     %test:assertEquals("1048575")
    %test:args("-1")        %test:assertEquals("-1")
    %test:args("-F")        %test:assertEquals("-15")
    %test:args("-0F")       %test:assertEquals("-15")
    %test:args("-400")      %test:assertEquals("-1024")
    %test:args("-7FF4")     %test:assertEquals("-32756")
    %test:args("-8B2F")     %test:assertEquals("-35631")
    %test:args("-0008B2F")  %test:assertEquals("-35631")
    %test:args("-FFFFF")    %test:assertEquals("-1048575")
    function mt:test-hex2int($i as xs:string) as xs:int? {
        m:hex2int($i)
};

declare 
    %test:args("A040200")   %test:assertEquals("C")
    %test:args("A040201")   %test:assertEquals("F")
    %test:args("A040219")   %test:assertEquals("C")
    %test:args("")          %test:assertEquals("0")
    %test:args("FFffF")     %test:assertEquals("E")
    %test:args("-1")        %test:assertEquals("E")
    %test:args("€")         %test:assertEquals("8")
    %test:args("Ä")         %test:assertEquals("8")
    %test:args("0")         %test:assertEquals("0")
    %test:args("<yäölfwüoie09485asülvk")     %test:assertEquals("4")
    function mt:test-compute-check-digit($id as xs:string) as xs:string {
        m:compute-check-digit($id)
};

declare 
    %test:args("A040200C")  %test:assertTrue
    %test:args("A040201F")  %test:assertTrue
    %test:args("A040219C")  %test:assertTrue
    %test:args("")          %test:assertFalse
    %test:args("<yäölfwüoie09485asülvk4")   %test:assertTrue
    %test:args("yäölfwüoie09485asülvk4")    %test:assertFalse
    %test:args("-1")        %test:assertFalse
    %test:args("€8")        %test:assertTrue
    %test:arg("id")         %test:assertFalse
    function mt:test-validate-check-digit($id as xs:string?) as xs:boolean {
        m:validate-check-digit($id)
};
