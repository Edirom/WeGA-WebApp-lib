xquery version "3.1";

module namespace ast="http://xquery.weber-gesamtausgabe.de/modules/app-shared-tests";

import module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared" at "../xquery/app-shared.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

declare 
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ["a", "b"]}')
    %test:arg("key", "items")
    %test:arg("max", "0")
    %test:arg("separator", ", ")
    %test:assertEquals("a, b")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ["a", "b"]}')
    %test:arg("key", "items")
    %test:arg("max", "2")
    %test:arg("separator", ", ")
    %test:assertEquals("a, b")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ["a", "b"]}')
    %test:arg("key", "items")
    %test:arg("max", "1")
    %test:arg("separator", ", ")
    %test:assertEquals("a, …")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": "b"}')
    %test:arg("key", "items")
    %test:arg("max", "5")
    %test:arg("separator", ", ")
    %test:assertEquals("b")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ["a", "b"]}')
    %test:arg("key", "foo")
    %test:arg("max", "1")
    %test:arg("separator", ", ")
    %test:assertEmpty
    function ast:test-join($node as xs:string, $model as xs:string, $key as xs:string, $max as xs:string, $separator as xs:string) as xs:string? {
        app-shared:join(parse-xml($node), parse-json($model), $key, $max, $separator)
};

declare 
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ["a", "b"]}')
    %test:arg("key", "items")
    %test:assertEquals("ab")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": "b"}')
    %test:arg("key", "items")
    %test:assertEquals("b")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ""}')
    %test:arg("key", "items")
    %test:assertEquals("")
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": ["a", "b"]}')
    %test:arg("key", "foo")
    %test:assertEmpty
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": null}')
    %test:arg("key", "items")
    %test:assertEmpty
    %test:arg("node", "<span/>")
    %test:arg("model", '{"items": NaN}')
    %test:arg("key", "items")
    %test:assertEquals("NaN")
    function ast:test-print($node as xs:string, $model as xs:string, $key as xs:string) as xs:string? {
        app-shared:print(parse-xml($node), parse-json($model), $key)
};
