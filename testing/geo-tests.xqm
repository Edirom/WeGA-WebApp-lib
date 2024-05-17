xquery version "3.1";

module namespace geot="http://xquery.weber-gesamtausgabe.de/modules/geo-tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";
import module namespace geo="http://xquery.weber-gesamtausgabe.de/modules/geo" at "../xquery/geo.xqm";

declare 
    %test:args(
        '{ "type": "Point", "coordinates": [3.5, 2.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [0.0, 5.0] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 0.0] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 2.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [3.5, 7.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 7.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    function geot:test-point-in-ring($point as xs:string, $ring as xs:string) as xs:boolean {
        geo:point-in-ring($point => parse-json(), $ring => parse-json())
};

declare 
    %test:args(
        '{ "type": "Point", "coordinates": [3.5, 2.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [0.0, 5.0] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 0.0] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 2.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [3.5, 7.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 7.5] }',
        '[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]'
    )
    %test:assertFalse
    function geot:test-point-on-edge($point as xs:string, $ring as xs:string) as xs:boolean {
        geo:point-on-edge($point => parse-json(), $ring => parse-json())
};

declare 
    %test:args(
        '{ "type": "Point", "coordinates": [2.5, 2.5] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [2.5, 2.5] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ], [ [1.0, 1.0], [1.0, 4.0], [4.0, 4.0], [4.0, 1.0], [1.0, 1.0] ]]}'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [4, 4.43832400000014] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ], [ [1.0, 1.0], [1.0, 4.0], [4.0, 4.0], [4.0, 1.0], [1.0, 1.0] ]]}'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [4, 4.43832400000014] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [0.0, 5.0] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 0.0] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 2.5] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertTrue
    %test:args(
        '{ "type": "Point", "coordinates": [3.5, 7.5] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [5.0, 7.5] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }'
    )
    %test:assertFalse
    %test:args(
        '{ "type": "Point", "coordinates": [2, 4] }',
        '{ "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ], [ [1.0, 1.0], [1.0, 4.0], [4.0, 4.0], [4.0, 1.0], [1.0, 1.0] ]]}'
    )
    %test:assertFalse
    %test:args(
        '{ "foo": "bar" }',
        '{ "bli": "baz" }'
    )
    %test:assertError("GeojsonFormatError")
    function geot:test-point-in-polygon($point as xs:string, $polygon as xs:string) as xs:boolean {
        geo:point-in-polygon($point => parse-json(), $polygon => parse-json())
};
