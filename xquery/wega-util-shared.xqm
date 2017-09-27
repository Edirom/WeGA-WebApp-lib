xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module with utility functions 
~:)
module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared";

(:~
 :  A slight modification of the standard XPath function fn:doc-available()
 :  which will return false() for binary documents instead of failing
~:)
declare function wega-util-shared:doc-available($uri as xs:string?) as xs:boolean {
    try {doc-available($uri)}
    catch * {false()}
};

(:~
 : Helper function for guessing a mime-type from a file extension
 : (Should be expanded to read in $exist.home$/mime-types.xml)
 :
 : @author Peter Stadler 
 : @param $suffix the file extension
 : @return the mime-type or the empty sequence when no match was found
 :)
declare function wega-util-shared:guess-mimeType-from-suffix($suffix as xs:string) as xs:string? {
    switch($suffix)
        case 'xml' return 'application/xml'
        case 'rdf' return 'application/rdf+xml'
        case 'jpg' return 'image/jpeg'
        case 'png' return 'image/png'
        case 'txt' return 'text/plain'
        default return ()
};
