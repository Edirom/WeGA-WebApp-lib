xquery version "3.1";

module namespace ct="http://xquery.weber-gesamtausgabe.de/modules/cache-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace my-cache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "../xquery/cache.xqm";

(:~
 : A unique identifier for the temporary test collection.
 : This ensures that each test run uses a fresh collection and avoids conflicts with other tests,
 : and can safely be removed after the tests complete.
 :)
declare variable $ct:unique-id := util:uuid();

(:~
 : The parent collection for the temporary test collection(s).
 : This collection needs to be created before the tests run. Also, it needs to have write permissions
 : for the (guest) user that runs the tests. The post-install.xql script takes care of this.
 :)
declare variable $ct:test-collection-parent := '/db/WebApp-lib-testfiles';
declare variable $ct:test-collection := string-join(($ct:test-collection-parent, $ct:unique-id), '/');

(:~
 : Prepare the temporary cache-test collection before the XQSuite module runs.
 :
 : @return the empty sequence
 :)
declare
    %test:setUp
    function ct:set-up() as xs:string? {
        if (not(xmldb:collection-available($ct:test-collection)))
        then xmldb:create-collection($ct:test-collection-parent, $ct:unique-id)
        else ()
};

(:~
 : Remove the temporary test collection after the module has finished running.
 :
 : @return the empty sequence
 :)
declare
    %test:tearDown
    function ct:tear-down() as empty-sequence() {
        if (xmldb:collection-available($ct:test-collection))
        then xmldb:remove($ct:test-collection)
        else ()
};

(:~
 : Create a unique database URI for cache tests so that each test runs on a fresh resource.
 :
 : @return a path under /db/test-cache/ with a UUID and .xml suffix
 :)
declare function ct:unique-doc-uri() as xs:string {
    $ct:test-collection || '/' || util:uuid() || '.xml'
};

(:~
 : The cached document should be refreshed once its lease has expired.
 : This verifies that the file is re-generated and that the newly stored value is returned.
 :
 : @return the refreshed value "updated"
 :)
declare
    %test:args("P1D")   %test:assertEquals("initial")
    %test:args("-PT1S")   %test:assertEquals("updated a second time")
    function ct:test-cache-doc-refreshes-after-expiry($duration as xs:dayTimeDuration) as xs:string {
        let $doc-uri := ct:unique-doc-uri()
        let $initial := my-cache:doc(
            $doc-uri,
            function() { <doc><value>initial</value></doc> },
            (),
            xs:dayTimeDuration("P1D"),
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )
        let $fresh := my-cache:doc(
            $doc-uri,
            function() { <doc><value>updated once</value></doc> },
            (),
            xs:dayTimeDuration("P1D"),
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )
        return my-cache:doc(
            $doc-uri,
            function() { <doc><value>updated a second time</value></doc> },
            (),
            $duration,
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )/doc/value/string()
};

(:~
 : A callback for documents may accept extra parameters that are passed through the cache wrapper.
 : This ensures the cache layer forwards argument lists without altering the content.
 :
 : @return the concatenated callback output "alpha-beta"
 :)
declare
    %test:assertEquals("alpha-beta")
    function ct:test-cache-doc-passes-callback-parameters() as xs:string {
        let $doc-uri := ct:unique-doc-uri()
        return my-cache:doc(
            $doc-uri,
            function($first as xs:string, $second as xs:string) {
                <doc><value>{concat($first, '-', $second)}</value></doc>
            },
            ('alpha', 'beta'),
            xs:dayTimeDuration("PT0S"),
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )/doc/value/string()
};

(:~
 : Collection caches should also expire based on the configured lease.
 : This test confirms the cached sequence is refreshed and that the updated values are returned.
 :
 : @return the refreshed values "third", "fourth"
 :)
declare
    %test:args("P1D")   %test:assertEquals("first", "second")
    %test:args("-PT1S")   %test:assertEquals("fifth", "sixth")
    function ct:test-cache-collection-refreshes-after-expiry($duration as xs:dayTimeDuration) as xs:string* {
        let $cache-key := 'cache-tests-' || util:uuid()
        let $initial := my-cache:collection(
            $cache-key,
            function() { ('first', 'second') },
            xs:dayTimeDuration("P1D"),
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )
        let $fresh := my-cache:collection(
            $cache-key,
            function() { ('third', 'fourth') },
            xs:dayTimeDuration("P1D"),
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )
        return my-cache:collection(
            $cache-key,
            function() { ('fifth', 'sixth') },
            $duration,
            function($code as xs:string, $desc as xs:string) { 'recovered' }
        )
};

(:~
 : A callback failure should trigger the configured recovery function instead of escaping the error.
 : This documents the expected fallback behavior for failed cache refreshes.
 :
 : @return "recovered"
 :)
declare
    %test:assertEquals("recovered")
    function ct:test-cache-doc-calls-on-failure() as xs:string {
        let $doc-uri := ct:unique-doc-uri()
        return my-cache:doc(
            $doc-uri,
            function() { error(QName('http://xquery.weber-gesamtausgabe.de/modules/cache-tests', 'Boom'), 'broken') },
            (),
            xs:dayTimeDuration("P1D"),
            function($code as item(), $desc as item()) { 'recovered' }
        )
};
