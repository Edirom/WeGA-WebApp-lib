xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for geospatial functions 
~:)
module namespace geo = "http://xquery.weber-gesamtausgabe.de/modules/geo";

declare namespace array="http://www.w3.org/2005/xpath-functions/array";

declare variable $geo:GEOJSON_FORMAT_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/geo", "GeojsonFormatError");

(:~
 : Function to check if a point is inside a GeoJSON polygon, considering holes.
 : A point is considered inside the polygon if it is inside the exterior ring
 : and outside all interior rings.
 :
 : @param $point The GeoJSON point to check, e.g. map { "type": "Point", "coordinates": [3.5, 2.5] }
 : @param $polygon The GeoJSON polygon with possible holes, e.g. map { "type": "Polygon", "coordinates":  [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]] }
 : @return xs:boolean True if the point is inside the polygon or on one of the edges, false otherwise.
 :)
declare function geo:point-in-polygon($point as map(*), $polygon as map(*)) as xs:boolean {
    if(geo:is-valid-point($point) and geo:is-valid-polygon($polygon))
    then
        let $exterior as array(*) := $polygon("coordinates")(1)
        let $interiors as array(*)? :=
            if(array:size($polygon("coordinates")) gt 1)
            then array:tail($polygon("coordinates"))
            else ()
        let $inExterior as xs:boolean := geo:point-in-ring($point, $exterior)
        let $onExteriorEdge as xs:boolean := geo:point-on-edge($point, $exterior)
        let $inAnyInterior as xs:boolean := 
            if(exists($interiors)) 
            then some $interior in $interiors?* satisfies geo:point-in-ring($point, $interior)
            else false()
        let $onAnyInteriorEdge as xs:boolean :=
            if(exists($interiors))
            then some $interior in $interiors?* satisfies geo:point-on-edge($point, $interior)
            else false()
        return ($inExterior or $onExteriorEdge) and not ($inAnyInterior or $onAnyInteriorEdge)
    else error($geo:GEOJSON_FORMAT_ERROR, 'invalid geojson format')
};

(:~
 : Function to check if a point is inside a ring (exterior or interior).
 : Uses the ray-casting algorithm to count the number of intersections of a ray
 : starting from the point.
 :
 : @param $point The GeoJSON point to check, e.g. map { "type": "Point", "coordinates": [3.5, 2.5] }.
 : @param $ring The coordinates of the ring (array of arrays), e.g. [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]].
 : @return xs:boolean True if the point is inside the ring, false otherwise.
 :)
declare function geo:point-in-ring($point as map(*), $ring as array(*)) as xs:boolean {
    if(geo:is-valid-point($point) and geo:is-valid-ring($ring))
    then
        let $px as xs:double := $point("coordinates")(1)
        let $py as xs:double := $point("coordinates")(2)
        let $n as xs:integer := array:size($ring)
        let $intersections := 
            for $i in 1 to $n
            let $xi as xs:double := $ring($i)(1)
            let $yi as xs:double := $ring($i)(2)
            (:  $j = Index of the previous vertex, which helps in forming edges :)
            let $j as xs:integer := 
                if ($i = 1) 
                then $n
                else $i - 1
            let $xj as xs:double := $ring($j)(1)
            let $yj as xs:double := $ring($j)(2)
            return
                if (
                    (($yi > $py) != ($yj > $py)) and
                    ($px < (($xj - $xi) * ($py - $yi) div ($yj - $yi) + $xi))
                ) 
                then 1
                else 0
        return
            (sum($intersections) mod 2) = 1
    else error($geo:GEOJSON_FORMAT_ERROR, 'invalid geojson format')
};

(:~
 : XQuery function that checks whether a point is on the edge of a polygon ring (exterior or interior).
 :
 : @param $point The GeoJSON point to check, e.g. map { "type": "Point", "coordinates": [3.5, 2.5] }.
 : @param $ring The coordinates of the ring (array of arrays), e.g. [[ [0.0, 0.0], [0.0, 5.0], [5.0, 5.0], [5.0, 0.0], [0.0, 0.0] ]].
 : @return True if the point is on one of the edges, false otherwise.
 :)
declare function geo:point-on-edge($point as map(*), $ring as array(*)) as xs:boolean {
    if(geo:is-valid-point($point) and geo:is-valid-ring($ring))
    then
        let $px as xs:double := $point("coordinates")(1)
        let $py as xs:double := $point("coordinates")(2)
        let $n as xs:integer := array:size($ring)
        let $onEdge := 
            for $i in 1 to $n
            let $xi as xs:double := $ring($i)(1)
            let $yi as xs:double := $ring($i)(2)
            let $j as xs:integer := 
                if ($i = 1) 
                then $n
                else $i - 1
            let $xj as xs:double := $ring($j)(1)
            let $yj as xs:double := $ring($j)(2)
            return
                if (
                    ($px - $xi) * ($yj - $yi) = ($py - $yi) * ($xj - $xi) and 
                    min(($xi, $xj)) <= $px and 
                    $px <= max(($xi, $xj)) and 
                    min(($yi, $yj)) <= $py and 
                    $py <= max(($yi, $yj))
                ) 
                then true() else false()
        return some $x in $onEdge satisfies $x
    else error($geo:GEOJSON_FORMAT_ERROR, 'invalid geojson format')
};

(:~
 : Function to validate a GeoJSON point.
 :
 : @param $point The GeoJSON point to validate.
 : @return xs:boolean True if the point is valid, false otherwise.
 :)
declare function geo:is-valid-point($point as map(*)) as xs:boolean {
    ($point?type = "Point") and
    exists($point?coordinates) and
    (array:size($point?coordinates) = 2) and
    (every $coord in $point?coordinates?* satisfies $coord instance of xs:double)
};

(:~
 : Function to validate a GeoJSON ring (array of coordinates).
 :
 : @param $ring The ring to validate.
 : @return xs:boolean True if the ring is valid, false otherwise.
 :)
declare function geo:is-valid-ring($ring as array(*)) as xs:boolean {
    array:size($ring) >= 4 and
    $ring(1) = $ring(array:size($ring)) and
    (every $coordinate in $ring?* satisfies (
        array:size($coordinate) = 2 and
        $coordinate(1) instance of xs:double and
        $coordinate(2) instance of xs:double
    ))
};

(:~
 : Function to validate a GeoJSON polygon.
 :
 : @param $polygon The GeoJSON polygon to validate.
 : @return xs:boolean True if the polygon is valid, false otherwise.
 :)
declare function geo:is-valid-polygon($polygon as map(*)) as xs:boolean {
    $polygon?type = "Polygon" and
    exists($polygon?coordinates) and
    (every $ring in $polygon?coordinates?* satisfies geo:is-valid-ring($ring))
};

(:~
 : Function to validate GeoJSON input (either Point or Polygon).
 :
 : @param $geojson The GeoJSON data to validate.
 : @return xs:boolean True if the GeoJSON data is valid, false otherwise.
 :)
declare function local:is-valid-geojson($geojson as map(*)) as xs:boolean {
  ($geojson?type = "Point" and geo:is-valid-point($geojson)) or
  ($geojson?type = "Polygon" and geo:is-valid-polygon($geojson))
};
