xquery version "3.1" encoding "UTF-8";

module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared";

import module namespace functx="http://www.functx.com";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";

declare variable $app-shared:FUNCTION_LOOKUP_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/app-shared", "FunctionLookupError");

(:~
 : Set an attribute to the value given in the $model map
 :
 : @author Peter Stadler
 :)
declare function app-shared:set-attr($node as node(), $model as map(*), $attr as xs:string, $key as xs:string) as element() {
    element {name($node)} {
        $node/@*[not(name(.) = $attr)],
        attribute {$attr} {$model($key)},
        templates:process($node/node(), $model)
    }
};

(:~
 : Simply print the string value of $model($key)
 :
 : @author Peter Stadler
 :)
declare 
    %templates:wrap
    function app-shared:print($node as node(), $model as map(*), $key as xs:string) as xs:string? {
        if ($model($key) castable as xs:string) then str:normalize-space($model($key))
        else app-shared:join($node, $model, $key, '0', '')
};

(:~
 : Simply print a sequence from the $model map by joining items with $separator
 :
 : @param $separator the separator for the string-join()
 : @author Peter Stadler
 :)
declare 
    %templates:wrap
    %templates:default("max", "0")
    %templates:default("separator", ", ")
    function app-shared:join($node as node(), $model as map(*), $key as xs:string, $max as xs:string, $separator as xs:string) as xs:string? {
        let $items := 
            if($max castable as xs:integer and number($max) le 0) then $model($key)
            else if($max castable as xs:integer and number($max) < count($model($key))) then (subsequence($model($key), 1, $max), '…')
            else if($max castable as xs:integer and number($max) > 0) then subsequence($model($key), 1, $max)
            else $model($key)
        return
            if (every $i in $items satisfies $i castable as xs:string) then string-join($items ! str:normalize-space(.), $separator)
            else ()
};


(:~
 : A non-wrapping alternative to the standard templates:each()
 : Gets rid of the superfluous first list item
 : 
 : @author Peter Stadler
 :)
declare 
    %templates:default("max", "0")
    %templates:default("callback", "0")
    %templates:default("callbackArity", "2")
    function app-shared:each($node as node(), $model as map(*), $from as xs:string, $to as xs:string, $max as xs:string, $callback as xs:string, $callbackArity as xs:string) as node()* {
    let $items := 
        if($max castable as xs:integer and $max != '0') then subsequence($model($from), 1, $max)
        else $model($from)
    let $callbackFunc := 
        try { function-lookup(xs:QName($callback), 2) } 
        catch * { error($app-shared:FUNCTION_LOOKUP_ERROR, 'Failed to lookup function "' || $callback || '". Error code was "' || $err:code || '". Error message was "' || $err:description || '".') }
    return (
        for $item in $items
        return 
            if(exists($callbackFunc)) then $callbackFunc($node, map:new(($model, map:entry($to, $item))))
            else 
                element { node-name($node) } {
                    $node/@*,
                    templates:process($node/node(), map:new(($model, map:entry($to, $item))))
                }
    )
};

(:~
 : Processes the node only if some $key (value) exists in $model 
 :
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app-shared:if-exists($node as node(), $model as map(*), $key as xs:string, $wrap as xs:string) as node()* {
        if(count($model($key)) gt 0) then 
            if($wrap = 'yes') then
                element {node-name($node)} {
                    $node/@*,
                    templates:process($node/node(), $model)
                }
            else templates:process($node/node(), $model)
        else ()
};

(:~
 : Processes the node only if some $key (value) *not* exists in $model 
 :
 : @author Peter Stadler
 :)
declare function app-shared:if-not-exists($node as node(), $model as map(*), $key as xs:string) as node()? {
    if(count($model($key)) eq 0) then 
        element {node-name($node)} {
            $node/@*,
            templates:process($node/node(), $model)
        }
    else ()
};

(:~
 : Processes the node only if some $key matches $value in $model 
 :
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app-shared:if-matches($node as node(), $model as map(*), $key as xs:string, $value as xs:string, $wrap as xs:string) as item()* {
        if($model($key) castable as xs:string and string($model($key)) = tokenize($value, '\s+')) then
            if($wrap = 'yes') then
                element {node-name($node)} {
                    $node/@*,
                    templates:process($node/node(), $model)
                }
            else templates:process($node/node(), $model)
        else ()
};

(:~
 : Processes the node only if some $key *not* matches $value in $model 
 :
 : @param $node the processed $node from the html template (a default param from the templating module)
 : @param $model a map (a default param from the templating module)
 : @param $key the key in $Model to look for
 : @param $value the value of $key to match
 : @param $wrap whether to copy the node $node to the output or just process the child nodes of $node  
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app-shared:if-not-matches($node as node(), $model as map(*), $key as xs:string, $value as xs:string, $wrap as xs:string) as item()* {
        if($model($key) castable as xs:string and string($model($key)) = tokenize($value, '\s+')) then ()
        else if($wrap = 'yes') then
            element {node-name($node)} {
                $node/@*,
                templates:process($node/node(), $model)
            }
        else templates:process($node/node(), $model)
};

declare function app-shared:order-list-items($node as node(), $model as map(*)) as element() {
    element {node-name($node)} {
        $node/@*,
        for $child in $node/node()
        let $childProcessed := templates:process($child, $model)
        order by str:normalize-space($childProcessed)
        return $childProcessed
    }
};

(:~
 : Outputs the raw value of $key, e.g. some HTML fragment 
 : that's not being wrapped with the $node element but replaces it.
~:)
declare function app-shared:output($node as node(), $model as map(*), $key as xs:string) as item()* {
    $model($key)
};
