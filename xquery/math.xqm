xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for manipulating strings
~:)
module namespace math="http://xquery.weber-gesamtausgabe.de/modules/math";

declare namespace map="http://www.w3.org/2005/xpath-functions/map";
import module namespace functx="http://www.functx.com";

(:~
 : Simple mapping of integer to hex numbers 
 : Helper map for math:int2hex()
 :)
declare %private variable $math:int2hex as map(*) := map {
    '0' : '0',
    '1' : '1',
    '2' : '2',
    '3' : '3',
    '4' : '4',
    '5' : '5', 
    '6' : '6',
    '7' : '7',
    '8' : '8',
    '9' : '9',
    '10' : 'A',
    '11' : 'B',
    '12' : 'C',
    '13' : 'D',
    '14' : 'E',
    '15' : 'F'
};

(:~
 : Converts input to a hexadecimal string
 :
 : @param $number integer value that will be converted to a hex string
 : @return hexadecimal string
 :)
declare function math:int2hex($number as xs:int) as xs:string {
    let $pos := $number ge 0 (: check whether it's a positive number :)
    let $pos.number := (: turn negative numbers into positive :)
        if($pos) then $number
        else $number * -1
    let $hex.value :=
        if($pos.number lt 16) then $math:int2hex($pos.number)
        else (
            let $div := $pos.number div 16
            let $count := floor($div)
            let $remainder := ($div - $count) * 16
            return
                concat(
                    if($count gt 15) then math:int2hex($count)
                    else $math:int2hex($count),
                    $math:int2hex($remainder)
                )
        )
    return
        if($pos) then $hex.value
        else '-' || $hex.value (: readd minus sign if necessary :)
};


(:~
 : Converts input to a hexadecimal string of a minimum length
 : If minLength is greater than the converted hex number it will be prepended by zeros.
 : Otherwise the converted hex number will be output as is. 
 : NB: the resulting hex string can exceed minLength.
 :
 : @param $number integer value that will be converted to a hex string
 : @param $minLength integer value of the desired minimum length
 : @return hexadecimal string
 :)
declare function math:int2hex($number as xs:int, $minLength as xs:int) as xs:string {
    let $pos := $number ge 0 (: check whether it's a positive number :)
    let $pos.number := (: turn negative numbers into positive :)
        if($pos) then $number
        else $number * -1
    let $hex.value := math:int2hex($pos.number)
    let $padded.hex.value :=
        if ($minLength le string-length($hex.value)) then $hex.value
        else (functx:repeat-string('0', $minLength - string-length($hex.value)) || $hex.value)
    return
        if($pos) then $padded.hex.value
        else '-' || $padded.hex.value (: readd minus sign if necessary :)
};
