xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module with utility functions 
 :)
module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared";

(:~
 :  A slight modification of the standard XPath function fn:doc-available()
 :  which will return false() for binary documents instead of failing
 :)
declare function wega-util-shared:doc-available($uri as xs:string?) as xs:boolean {
    try {doc-available($uri)}
    catch * {false()}
};

(:~
 :  Checks whether the json resource identified by $uri is available.
 :)
declare function wega-util-shared:json-doc-available($uri as xs:string?) as xs:boolean {
    try {exists(json-doc($uri))}
    catch * {false()}
};

(:~
 :  A helper function for checking for content built on fn:boolean()
 :  Content is defined as non-zero, non-whitespace-only, non-false() and is recursively applied to maps and arrays
 :)
declare function wega-util-shared:has-content($items as item()*) as xs:boolean {
    some $item in $items satisfies
    typeswitch($item)
    case array(*) return some $i in $item?* satisfies wega-util-shared:has-content($i)
    case map(*) return some $i in map:keys($item) satisfies wega-util-shared:has-content($item($i))
    case attribute() return ( if(normalize-space($item) castable as xs:double) then wega-util-shared:has-content(xs:double(normalize-space($item))) else wega-util-shared:has-content(string($item)) )
    case element() return ( if(normalize-space($item) castable as xs:double) then wega-util-shared:has-content(xs:double(normalize-space($item))) else wega-util-shared:has-content(string($item)) )
    case xs:string return normalize-space($item) != ''
    case xs:date return true() 
    case xs:dateTime return true()
    case function(*) return true()
    default return boolean($item)
};

(:~
 : Helper function for guessing a mime-type from a file extension
 : Relies on the file $exist.home$/mime-types.xml which gets uploaded during installation of this package
 :
 : @author Peter Stadler 
 : @param $suffix the file extension
 : @return the mime-type or the empty sequence when no match was found
 :)
declare function wega-util-shared:guess-mimeType-from-suffix($suffix as xs:string) as xs:string? {
    let $extensions := doc('../mime-types.xml')//extensions
    return
        ($extensions[(tokenize(., ',\s*') = concat('.', $suffix))]/parent::mime-type[not(contains(description, 'Deprecated'))])/@name
};

(:~
 : Sort TEI elements by their cert-attribute (e.g. <tei:date cert="medium"/>)
 : NB: items without cert-attribute will rank the highest, followed by 'high', 'medium', 'low', 'unknown'
 :
 : @param $items the items to sort
 : @return the sorted sequence of the items
 :)
declare function wega-util-shared:order-by-cert($items as item()*) as item()* {
    let $order := map {
        'high' : 1,
        'medium' : 2,
        'low' : 3,
        'unknown' : 4,
        '' : 0
    }
    return
        for $i in $items
        let $cert := $i/string(@cert)
        order by $order($cert)
        return $i
};

(:~
 : Try to cast a given item to xs:string and check its semantic boolean value
 : 
 : @param $item the item to check
 : @return true() for 'yes', '1', or 'true', false() otherwise
 :)
declare function wega-util-shared:semantic-boolean($item as item()) as xs:boolean {
    let $true-strings := ('yes', '1', 'true')
    return
        if($item castable as xs:string)
        then normalize-space($item) = $true-strings
        else false()
};
