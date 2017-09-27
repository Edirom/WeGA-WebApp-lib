xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for caching documents and collections
~:)
module namespace cache="http://xquery.weber-gesamtausgabe.de/modules/cache";

import module namespace functx="http://www.functx.com";
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "wega-util-shared.xqm";

declare variable $cache:TOO_MANY_PARAMETERS_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/cache", "TooManyParametersError");
declare variable $cache:UNSUPPORTED_PARAMETER_VALUE_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/cache", "UnsupportedParameterValueError");

(:~
 : A caching function for documents (XML and binary)
 :
 : @author Peter Stadler
 : @param $docURI the database URI of the document
 : @param $callBack a function to create the document content when the document is outdated or not available
 : @param $lease an xs:dayTimeDuration value of how long the cache should persist, e.g. P999D (= 999 days). 
 :          Alternatively, $lease can be a callback function – then one argument (the last change date of the file as xs:date()?) will be provided 
 :          and the function should return xs:boolean
 : @return the cached document
 :)
declare function cache:doc($docURI as xs:string, $callback as function() as item(), $callback-params as item()*, $lease as item()?, $onFailure as function() as item()*) as item()* {
    let $fileName := functx:substring-after-last($docURI, '/')
    let $collection := functx:substring-before-last($docURI, '/')
    let $currentDateTimeOfFile := 
        if(wega-util-shared:doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else if(util:binary-doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else ()
    let $updateNecessary := 
        typeswitch($lease)
        case xs:dayTimeDuration return
            $currentDateTimeOfFile + $lease lt current-dateTime()
            or empty($lease) 
            or empty($currentDateTimeOfFile)
        case function() as xs:boolean return $lease($currentDateTimeOfFile)
        default return error($cache:UNSUPPORTED_PARAMETER_VALUE_ERROR, 'The parameter value for $lease must be xs:dayTimeDuration()? or a function reference which must take exactly one argument.')
    return 
	   if($updateNecessary) then (
            let $content := 
                if(count($callback-params) eq 0) then $callback()
                else if(count($callback-params) eq 1) then $callback($callback-params)
                else if(count($callback-params) eq 2) then $callback($callback-params[1], $callback-params[2])
                else if(count($callback-params) eq 3) then $callback($callback-params[1], $callback-params[2], $callback-params[3])
                else if(count($callback-params) eq 4) then $callback($callback-params[1], $callback-params[2], $callback-params[3], $callback-params[4])
                else error($cache:TOO_MANY_PARAMETERS_ERROR, 'Too many arguments to callback function within cache:doc(). A maximum of 4 arguments is supported')
            let $mime-type := wega-util-shared:guess-mimeType-from-suffix(functx:substring-after-last($docURI, '.'))
            let $store-file := cache:store-file($collection, $fileName, $content, $mime-type, $onFailure)
            return 
                if(util:binary-doc-available($store-file)) then util:binary-doc($store-file)
                else if(wega-util-shared:doc-available($store-file)) then doc($store-file) 
                else ()
        )
        else if(util:binary-doc-available($docURI)) then util:binary-doc($docURI)
        else if(wega-util-shared:doc-available($docURI)) then doc($docURI)
        else ()
};

(:~
 : Store some content as file in the db
 : (Helper function for cache:doc())
 : 
 : @author Peter Stadler
 : @param $collection the collection to put the file in. If it does not exist, it will be created  
 : @param $fileName the filename of the to be created resource with filename extension
 : @param $contents the content to store. Either a node, an xs:string, a Java file object or an xs:anyURI 
 : @return Returns the path to the newly created resource, empty sequence otherwise
 :)
declare %private function cache:store-file($collection as xs:string, $fileName as xs:string, $contents as item(), $mime-type as xs:string, $onFailure as function() as item()*) as xs:string? {
    let $createCollection := 
        for $coll in tokenize($collection, '/')
        let $parentColl := substring-before($collection, $coll)
        return 
            if(xmldb:collection-available($parentColl || '/' || $coll)) then ()
            else xmldb:create-collection($parentColl, $coll)
    return
        try { xmldb:store($collection, $fileName, $contents, $mime-type) }
        catch * { $onFailure($err:code, $err:description) }
};

