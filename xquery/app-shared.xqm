xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery functions supplementing the eXist-db templating module
 :)
module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared";
declare namespace templates="http://exist-db.org/xquery/html-templating";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

import module namespace functx="http://www.functx.com";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "wega-util-shared.xqm";

declare variable $app-shared:FUNCTION_LOOKUP_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/app-shared", "FunctionLookupError");

(:~
 : Looking for the templates:process() function from the templating module
 : This module is a prerequisite for our supplement module 
 :)
declare variable $app-shared:templates-process := 
    try { function-lookup(xs:QName('templates:process'), 2) }
    catch * { error($app-shared:FUNCTION_LOOKUP_ERROR, 'Failed to lookup templates:process() from the eXist-db templating module. Error code was "' || $err:code || '". Error message was "' || $err:description || '".') };

(:~
 : Set an attribute to the value given in the $model map
 :
 : @author Peter Stadler
 :)
declare function app-shared:set-attr($node as node(), $model as map(*), $attr as xs:string, $key as xs:string) as element() {
    element {node-name($node)} {
        $node/@*[not(name(.) = $attr)],
        attribute {$attr} {$model($key)},
        $app-shared:templates-process($node/node(), $model)
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
 : @param $callback a callback function that will take two parameters ($node as node(), $model as map(*)) 
 : @param $callbackNamespace the namespace of the callback function
 : @author Peter Stadler
 :)
declare 
    %templates:default("max", "0")
    %templates:default("callback", "0")
    %templates:default("callbackNamespace", "")
    function app-shared:each($node as node(), $model as map(*), $from as xs:string, $to as xs:string, $max as xs:string, $callback as xs:string, $callbackNamespace as xs:string) as node()* {
    let $items := 
        if($max castable as xs:integer and $max != '0') then subsequence($model($from), 1, $max)
        else $model($from)
    let $callbackFunc := 
        if($callback ne '0') then 
            try { function-lookup(QName($callbackNamespace, $callback), 2) } 
            catch * { error($app-shared:FUNCTION_LOOKUP_ERROR, 'Failed to lookup function "' || $callback || '". Error code was "' || $err:code || '". Error message was "' || $err:description || '".') }
        else ()
    return (
        for $item in $items
        return 
            if(exists($callbackFunc)) then $callbackFunc($node, map:merge(($model, map:entry($to, $item))))
            else 
                element { node-name($node) } {
                    $node/@*,
                    $app-shared:templates-process($node/node(), map:merge(($model, map:entry($to, $item))))
                }
    )
};


(:~
 : Processes the node only if some $key exists in $model and its value is *not* the empty sequence, an empty string or false() 
 :
 : @param $node the current node to process from the HTML template
 : @parma $model the current model that's passed on by the templating module
 : @param $key the key to look for in the current $model. Multiple keys must be separated by whitespace only
 : @param $wrap whether to include the current node in the output (defaults to 'yes')
 : @param $or whether to search for with an logical OR when mulitple keys are given (defaults to 'yes')
 : @return the processed $node if the ckech was succesful, the empty sequence otherwise
 :)
declare 
    %templates:default("wrap", "yes")
    %templates:default("or", "yes")
    function app-shared:if-exists($node as node(), $model as map(*), $key as xs:string, $wrap as xs:string, $or as xs:string) as node()* {
        let $tokens := tokenize($key, '\s+')
        return
        if(wega-util-shared:semantic-boolean($or)) then 
            if(some $token in $tokens satisfies wega-util-shared:has-content($model($token))) 
            then app-shared:wrap($node, $app-shared:templates-process($node/node(), $model), $wrap) 
            else ()
        else 
            if(every $token in $tokens satisfies wega-util-shared:has-content($model($token))) 
            then app-shared:wrap($node, $app-shared:templates-process($node/node(), $model), $wrap) 
            else ()
};

(:~
 : Processes the node only if some $key (value) *not* exists in $model 
 :
 : @param $node the current node to process from the HTML template
 : @parma $model the current model that's passed on by the templating module
 : @param $key the key to look for in the current $model. Multiple keys must be separated by whitespace only
 : @param $wrap whether to include the current node in the output (defaults to 'yes')
 : @param $or whether to check with an logical OR when mulitple keys are given (defaults to 'yes')
 : @return the processed $node if the check was succesful, the empty sequence otherwise
 :)
declare 
    %templates:default("wrap", "yes")
    %templates:default("or", "yes")
    function app-shared:if-not-exists($node as node(), $model as map(*), $key as xs:string, $wrap as xs:string, $or as xs:string) as node()? {
        let $tokens := tokenize($key, '\s+')
        return
            if(wega-util-shared:semantic-boolean($or)) then 
                if(some $token in $tokens satisfies not(wega-util-shared:has-content($model($token)))) 
                then app-shared:wrap($node, $app-shared:templates-process($node/node(), $model), $wrap) 
                else ()
            else 
                if(every $token in $tokens satisfies not(wega-util-shared:has-content($model($token)))) 
                then app-shared:wrap($node, $app-shared:templates-process($node/node(), $model), $wrap) 
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
            app-shared:wrap($node, $app-shared:templates-process($node/node(), $model), $wrap)
        else ()
};

(:~
 : Processes the node only if some $key *not* matches $value in $model 
 :
 : @param $node the processed $node from the html template (a default param from the templating module)
 : @param $model a map (a default param from the templating module)
 : @param $key the key in $model to look for
 : @param $value the value of $key to match
 : @param $wrap whether to copy the node $node to the output or just process the child nodes of $node  
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app-shared:if-not-matches($node as node(), $model as map(*), $key as xs:string, $value as xs:string, $wrap as xs:string) as item()* {
        if($model($key) castable as xs:string and string($model($key)) = tokenize($value, '\s+')) then ()
        else app-shared:wrap($node, $app-shared:templates-process($node/node(), $model), $wrap)
};

(:~
 : Order list items by their string value
 : (used for navigation lists)
 :
 : @param $node the processed $node from the html template (a default param from the templating module)
 : @param $model a map (a default param from the templating module)
 : @return the ordered elements
 :)
declare function app-shared:order-list-items($node as node(), $model as map(*)) as element() {
    element {node-name($node)} {
        $node/@*,
        for $child in $node/node()
        let $childProcessed := $app-shared:templates-process($child, $model)
        order by str:normalize-space($childProcessed)
        return $childProcessed
    }
};

(:~
 : Outputs the raw value of $key, e.g. some HTML fragment 
 : Maps and arrays will be serialized as JSON 
 :
 : @param $node the processed $node from the html template (a default param from the templating module)
 : @param $model a map (a default param from the templating module)
 : @param $key the key in $model to look for
 : @param $wrap whether to copy the node $node to the output or to replace it with $model?key (default is "no")
~:)
declare 
    %templates:default("wrap", "no")
    function app-shared:output($node as node(), $model as map(*), $key as xs:string, $wrap as xs:string) as item()* {
        let $out := 
            typeswitch($model($key))
            case map(*) return serialize($model($key), <output:serialization-parameters><output:method>json</output:method></output:serialization-parameters> )
            case array(*) return serialize($model($key), <output:serialization-parameters><output:method>json</output:method></output:serialization-parameters> )
            default return $model($key)
        return app-shared:wrap($node, $out, $wrap)
};

(:~
 : Check if necessary, and wrap content in $node
 : Helper function for various functions above
 : 
 : @param $node the processed $node from the html template (a default param from the templating module)
 : @param $content the (new) content
 : @param $wrap whether to copy the node $node to the output or to replace it with $model?key
~:)
declare %private function app-shared:wrap($node as node(), $content as item()*, $wrap as xs:string) {
    if(wega-util-shared:semantic-boolean($wrap)) then
        element {node-name($node)} {
            $node/@*,
            $content 
        }
    else $content
};
