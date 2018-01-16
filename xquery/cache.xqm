xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for caching documents and collections
~:)
module namespace my-cache="http://xquery.weber-gesamtausgabe.de/modules/cache";

import module namespace functx="http://www.functx.com";
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "wega-util-shared.xqm";
import module namespace cm="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";

declare variable $my-cache:TOO_MANY_PARAMETERS_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/cache", "TooManyParametersError");
declare variable $my-cache:UNSUPPORTED_PARAMETER_VALUE_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/cache", "UnsupportedParameterValueError");

(:~
 : A caching function for documents (XML and binary)
 : The documents will be stored and retrieved from the db location given for $docURI, hence eXist-db index configurations may be applied to speed up queries
 :
 : @author Peter Stadler
 : @param $docURI the database URI of the document, i.e. where to store the file
 : @param $callBack a function to create the document content (initially, and when the document is outdated)
 : @param $lease an xs:dayTimeDuration value of how long the cache should persist, e.g. P999D (= 999 days). 
 :          Alternatively, $lease can be a callback function – then one argument (the last change date of the file as xs:date()?) will be provided 
 :          and the function should return xs:boolean
 : @param $onFailure a callback function which is fired on failure. 
 :          It takes two arguments as xs:string, the error code and the error description.
 : @return the cached document
 :)
declare function my-cache:doc($docURI as xs:string, $callback as function() as item(), $callback-params as item()*, $lease as item()?, $onFailure as function() as item()*) as item()* {
    let $fileName := functx:substring-after-last($docURI, '/')
    let $collection := functx:substring-before-last($docURI, '/')
    let $currentDateTimeOfFile := 
        if(wega-util-shared:doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else if(util:binary-doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else ()
    let $updateNecessary := 
        typeswitch($lease)
        case xs:dayTimeDuration return
            ($currentDateTimeOfFile + $lease) lt current-dateTime()
            or empty($currentDateTimeOfFile)
        case empty() return true() 
        case function() as xs:boolean return $lease($currentDateTimeOfFile)
        default return error($my-cache:UNSUPPORTED_PARAMETER_VALUE_ERROR, 'The parameter value for $lease must be xs:dayTimeDuration()? or a function reference which must take exactly one argument.')
    return 
        try {
            if($updateNecessary) then (
                let $content := 
                    if(count($callback-params) eq 0) then $callback()
                    else if(count($callback-params) eq 1) then $callback($callback-params)
                    else if(count($callback-params) eq 2) then $callback($callback-params[1], $callback-params[2])
                    else if(count($callback-params) eq 3) then $callback($callback-params[1], $callback-params[2], $callback-params[3])
                    else if(count($callback-params) eq 4) then $callback($callback-params[1], $callback-params[2], $callback-params[3], $callback-params[4])
                    else error($my-cache:TOO_MANY_PARAMETERS_ERROR, 'Too many arguments to callback function within cache:doc(). A maximum of 4 arguments is supported')
                let $mime-type := wega-util-shared:guess-mimeType-from-suffix(functx:substring-after-last($docURI, '.'))
                let $store-file := my-cache:store-file($collection, $fileName, $content, $mime-type, ())
                return 
                    if(util:binary-doc-available($store-file)) then util:binary-doc($store-file)
                    else if(wega-util-shared:doc-available($store-file)) then doc($store-file) 
                    else ()
            )
            else if(util:binary-doc-available($docURI)) then util:binary-doc($docURI)
            else if(wega-util-shared:doc-available($docURI)) then doc($docURI)
            else ()
        }
        catch * {
            $onFailure($err:code, $err:description)
        }
};

(:~
 : A caching function for node sets
 : The nodes are cached as Java objects by the eXist-db CacheModule (org.exist.xquery.modules.cache.CacheModule)
 :
 : @author Peter Stadler
 : @param $cacheKey some name/key for the collection (the cache) 
 : @param $callBack a function to create the collection
 : @param $lease an xs:dayTimeDuration value of how long the cache should persist, e.g. P999D (= 999 days). 
 :          Alternatively, $lease can be a callback function – then one argument (the last change date of the file as xs:date()?) will be provided 
 :          and the function must return xs:boolean: true(), if the cache is to be updated, false() otherwise. 
 : @param $onFailure a callback function which is fired on failure. 
 :          It takes two arguments as xs:string, the error code and the error description.
 : @return the cached collection
 :)
declare function my-cache:collection($cacheKey as xs:string, $callback as function() as item()*, $lease as item()?, $onFailure as function() as item()*) as item()* {
    let $cacheName := 'wega-cache'
    let $dateTimeOfCache := cm:get($cacheName, $cacheKey || 'lastModDateTime')
    let $updateNecessary := 
        if(empty($lease) or empty($dateTimeOfCache)) then true()
        else 
            typeswitch($lease)
            case xs:dayTimeDuration return ($dateTimeOfCache + $lease) lt current-dateTime()
            case function() as xs:boolean return $lease($dateTimeOfCache)
            default return error($my-cache:UNSUPPORTED_PARAMETER_VALUE_ERROR, 'The parameter value for $lease must be xs:dayTimeDuration()? or a function reference which must take exactly one argument.')
    return 
        if($updateNecessary) then (
            try {
                let $content := $callback()
                let $put-cache := (
                    cm:put($cacheName, $cacheKey || 'lastModDateTime', current-dateTime()),
                    cm:put($cacheName, $cacheKey, $content)
                )
                return $content
            }
            catch * {
                $onFailure($err:code, $err:description)
            }
        )
        else cm:get($cacheName, $cacheKey)
};

(:~
 : Store some content as file in the db
 : (Helper function for cache:doc())
 : 
 : @author Peter Stadler
 : @param $collection the collection to put the file in. If it does not exist, it will be created  
 : @param $fileName the filename of the to be created resource with filename extension
 : @param $contents the content to store. Either a node, an xs:string, a Java file object or an xs:anyURI
 : @param $mime-type the mime-type of the to be created file
 : @param $onFailure a callback function which is fired on failure. 
 :   It takes two arguments as xs:string, the error code and the error description.
 :   If no onFailure function is provided, all possible errors get promoted to the calling function  
 : @return Returns the path to the newly created resource, empty sequence otherwise
 :)
declare %private function my-cache:store-file($collection as xs:string, $fileName as xs:string, $contents as item(), $mime-type as xs:string, $onFailure as item()?) as xs:string? {
    let $createCollection := 
        for $coll in tokenize($collection, '/')
        let $parentColl := substring-before($collection, $coll)
        return 
            if(xmldb:collection-available($parentColl || '/' || $coll)) then ()
            else xmldb:create-collection($parentColl, $coll)
    return
        if($onFailure) then 
            try { xmldb:store($collection, $fileName, $contents, $mime-type) }
            catch * { $onFailure($err:code, $err:description) }
        else xmldb:store($collection, $fileName, $contents, $mime-type)
};
