xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for math functions 
~:)
module namespace math="http://xquery.weber-gesamtausgabe.de/modules/math";

declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace w3cmath="http://www.w3.org/2005/xpath-functions/math";

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
 : Reverse mapping of hex to integer numbers 
 : Helper function for math:hex2int()
 :)
declare %private function math:reverse-int2hex-map() as map(*) {
    map:merge(
        map:for-each($math:int2hex, function($key, $value) {
            map:entry($value, $key)
        })
    )
};

(:~
 : Converts input to a hexadecimal string
 :
 : @param $number integer value that will be converted to a hex string
 : @return hexadecimal string
 :)
declare function math:int2hex($number as xs:integer) as xs:string {
    let $pos := $number ge 0 (: check whether it's a positive number :)
    let $pos.number := (: turn negative numbers into positive :)
        abs($number)
    let $hex.value :=
        if($pos.number lt 16) then $math:int2hex(string($pos.number))
        else (
            let $div := $pos.number div 16
            let $count := floor($div)
            let $remainder := ($div - $count) * 16
            return
                concat(
                    if($count gt 15) then math:int2hex($count => xs:integer())
                    else $math:int2hex(string($count)),
                    $math:int2hex(string($remainder))
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
declare function math:int2hex($number as xs:integer, $minLength as xs:integer) as xs:string {
    let $pos := $number ge 0 (: check whether it's a positive number :)
    let $pos.number := (: turn negative numbers into positive :)
        abs($number)
    let $hex.value := math:int2hex($pos.number => xs:integer())
    let $padded.hex.value :=
        if ($minLength le string-length($hex.value)) then $hex.value
        else (math:repeat-string('0', $minLength - string-length($hex.value)) || $hex.value)
    return
        if($pos) then $padded.hex.value
        else '-' || $padded.hex.value (: readd minus sign if necessary :)
};

(:~
 : Converts a (string) hex value to an integer
 : If the string value does is not a proper hex value, 
 : the empty sequence is returned
 :
 : @param $number hex string that will be converted to an integer
 : @return integer value of the hex string or the empty sequence if conversion fails
 :)
declare function math:hex2int($number as xs:string) as xs:integer? {
    let $hex2int.map := math:reverse-int2hex-map()
    let $pos := not(starts-with(normalize-space($number), '-'))
    let $pos.number := 
        if($pos) then normalize-space($number) => upper-case()
        else substring(normalize-space($number), 2) => upper-case()
    let $sum := 
        sum(
            for $i in (1 to string-length($pos.number))
            let $pow := string-length($pos.number) - $i
            return
                number($hex2int.map(substring($pos.number, $i, 1))) * w3cmath:pow(16, $pow)
        )
    return
        if(not(matches($pos.number, '^[0-9A-F]+$'))) then () (: return empty sequence for non-valid hex values :)
        else if($pos) then $sum => xs:integer()
        else ($sum * -1) (: readd minus sign if necessary :) => xs:integer()
};

(:~
 : The function returns a string consisting of a given 
 : number of copies of $stringToRepeat concatenated together. 
 : To pad a string to a particular length, use the functx:pad-string-to-length function.
 :
 : Function taken from https://www.datypic.com/xq/functx_repeat-string.html
 :
 : @param $stringToRepeat the to be repeated string
 : @param $count number of copies
 : @return the repeated string
 :)
declare function math:repeat-string($stringToRepeat as xs:string?, $count as xs:integer) as xs:string {
    string-join((for $i in 1 to $count return $stringToRepeat), '')
};

(:~
 : Compute a check digit for a given ID
 : The check digit is computed by multiplying the 
 : codepoint of each character with a multiplier taken 
 : from a fixed sequence (2, 4, 6, 8, 9, 5, 3, 1)
 : 
 : @param $id the id to compute the check digit for
 : @return the computed check digit as a hexadecimal value 
 :)
declare function math:compute-check-digit($id as xs:string) as xs:string {
    (: Initial sequence of weights :)
    let $weightsSeq := (2, 4, 6, 8, 9, 5, 3, 1)
    (: Factor of size difference between the initial sequence of weights and the string-length of the provided ID (aka payload) :)
    let $factor := (string-length($id) div count($weightsSeq)) => ceiling() => xs:integer()
    (: extend the sequence of weights by $factor :)
    let $weightsSeqExtended := for $i in (1 to $factor) return $weightsSeq
    (: now finally adjust the sequence of weights to the length of the payload :)
    let $weights := subsequence($weightsSeqExtended, 1, string-length($id))
    
    let $codepoints := string-to-codepoints($id)
    let $weighted-codepoints := for $i at $c in string-to-codepoints($id) return $i * $weights[$c]
    return math:int2hex(sum($weighted-codepoints) mod 16)
};

(:~
 : Validate an ID 
 : by stripping off the last character/digit and comparing it to 
 : the computed check digit of `math:compute-check-digit#1`
 :
 : @param $id the ID to check
 : @return true if the comparison is successful, false otherwise 
 :)
declare function math:validate-check-digit($id as xs:string?) as xs:boolean {
    substring($id, string-length($id)) = math:compute-check-digit(substring($id, 1, string-length($id) - 1))
};
