xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for processing ICS (iCalendar) formatted data.
~:)
module namespace ics="http://xquery.weber-gesamtausgabe.de/modules/ics";

declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace ical="urn:ietf:params:xml:ns:icalendar-2.0";

(:~
 : Main entry point to this module
 : Parses an ICS (iCalendar) formatted string into an XML structure
 : according to RFC 6321 <https://www.rfc-editor.org/rfc/rfc6321.html>.
 :
 : @param $text The raw ICS text.
 : @return An XML element representing the parsed ICS data.
 :)
declare function ics:parse-ics($text as xs:string) as element(ical:icalendar)? {
    let $unfolded := ics:unfold-lines($text)
    let $lines := tokenize($unfolded, "\r?\n")
    let $meta :=
        for $line in subsequence($lines, 2, index-of($lines, "BEGIN:VEVENT")[1] - 2)
        return ics:parse-ics-line($line)
    let $check-sanity :=
        $lines[. = "BEGIN:VEVENT"] and
        $lines[. = "END:VEVENT"] and
        $lines[. = "BEGIN:VCALENDAR"] and
        $lines[. = "END:VCALENDAR"]
    let $events :=
        if($check-sanity) then
            for $line at $pos in $lines
            where $line = "BEGIN:VEVENT"
            let $eventLines := subsequence($lines, $pos + 1, index-of($lines, "END:VEVENT")[. > $pos][1] - $pos - 1)
            return
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "vevent") } {
                    element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "properties") } {
                        for $l in $eventLines
                        return ics:parse-ics-line($l)
                    }
                }
        else ()
    return
        if($events) then
            element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "icalendar") } {
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "vcalendar") } {
                    element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "properties") } {
                        $meta
                    },
                    element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "components") } {
                        $events
                    }
                }
            }
        else ()
};

(:~
 : Parses a single line of ICS data into an XML element.
 :
 : @param $line A single line from the ICS data.
 : @return An XML element representing the parsed line.
 :)
declare function ics:parse-ics-line($line as xs:string) as element()? {
    let $nameAndParams := substring-before($line, ":")
    let $value := substring-after($line, ":")
    let $tokens := tokenize($nameAndParams, ";")
    let $name := lower-case($tokens[1])
    let $params :=
        for $p in subsequence($tokens, 2)
        let $p-key := fn:substring-before($p, "=")
        let $p-value := fn:substring-after($p, "=")
        return
            map {
                "key": $p-key,
                "value": $p-value
            }
    return
        try { ics:create-content-element($name, $value, $params) }
        catch * {()}
};

(:~
 : Unfolds lines according to RFC 5545 3.1 by replacing any CRLF
 : that is followed by spaces or tabs with nothing.
 : Helper function for `ics:parse-ics#1`.
 :
 : @param $text The raw ICS text with folded lines.
 : @return The ICS text with unfolded lines.
 :)
declare %private function ics:unfold-lines($text as xs:string) as xs:string {
    replace($text, "\r?\n[ \t]+", "")
};

(:~
 : Unescapes special characters in ICS values according to RFC 5545 3.3.11.
 : Helper function for `ics:parse-ics-line#1`.
 :
 : @param $value The ICS value with escaped characters.
 : @return The ICS value with unescaped characters.
 :)
declare %private function ics:unescape-ics($value as xs:string?) as xs:string? {
    let $v := replace($value, "\\\\", "\\")
    let $v := replace($v, "\\;", ";")
    let $v := replace($v, "\\,", ",")
    let $v := replace($v, "\\[Nn]", "&#10;")
    return $v
};

(:~)
 : Creates an XML content element for a given ICS property, value, and parameters.
 : Helper function for `ics:parse-ics-line#1`.
 :
 : @param $property The ICS property name.
 : @param $value The ICS property value.
 : @param $params A sequence of maps representing the ICS parameters.
 : @return An XML element representing the ICS property.
 :)
declare %private function ics:create-content-element(
    $property as xs:string, $value as xs:string,
    $params as map(*)*
    ) as element()? {
        let $elem-name := lower-case($property)
        let $paramsXML :=
            if(count($params) gt 0)
            then $params ! element { QName("urn:ietf:params:xml:ns:icalendar-2.0", lower-case(.?key)) } {
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "text") } {
                    .?value
                }
            }
            else ()
        let $valueXML :=
            switch($elem-name)
            case "dtstart" case "dtend" case "due" case "created" case "last-modified" case "dtstamp" return
                let $parsed := ics:parse-ics-datetime($value)
                return
                    if($parsed instance of xs:dateTime) then
                        element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "date-time") } {
                            $parsed
                        }
                    else if($parsed instance of xs:date) then
                        element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "date") } {
                            $parsed
                        }
                    else
                        element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "text") } {
                            ics:unescape-ics($value)
                        }
            case "url" return
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "uri") } {
                    ics:unescape-ics($value)
                }
            case "sequence" return
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "integer") } {
                    ics:unescape-ics($value)
                }
            case "attendee" return
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "cal-address") } {
                    ics:unescape-ics($value)
                }
            default return
                element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "text") } {
                    ics:unescape-ics($value)
                }
        return
            element { QName("urn:ietf:params:xml:ns:icalendar-2.0", $elem-name) } {
                if($paramsXML) then
                    element { QName("urn:ietf:params:xml:ns:icalendar-2.0", "parameters") } {
                        $paramsXML
                    }
                else (),
                $valueXML
            }
};

(:~
 : Parses an ICS date or date-time string into an `xs:date` or `xs:dateTime`.
 :
 : @param $val The ICS date or date-time string.
 : @return The parsed `xs:date` or `xs:dateTime`, or the original string if parsing fails.
 :)
declare function ics:parse-ics-datetime($val as xs:string) as xs:anyAtomicType {
    (: DATE: YYYYMMDD :)
    if (matches($val, '^\d{8}$')) then
        xs:date(substring($val, 1, 4) || '-' || substring($val, 5, 2) || '-' || substring($val, 7, 2))

    (: DATE-TIME UTC: YYYYMMDDTHHMMSSZ :)
    else if (matches($val, '^\d{8}T\d{6}Z$')) then
        xs:dateTime(substring($val, 1, 4) || '-' || substring($val, 5, 2) || '-' || substring($val, 7, 2) ||
                'T' || substring($val, 10, 2) || ':' || substring($val, 12, 2) || ':' || substring($val, 14, 2) || 'Z')

    (: DATE-TIME without timezone: YYYYMMDDTHHMMSS :)
    else if (matches($val, '^\d{8}T\d{6}$')) then
        xs:dateTime(substring($val, 1, 4) || '-' || substring($val, 5, 2) || '-' || substring($val, 7, 2) ||
                'T' || substring($val, 10, 2) || ':' || substring($val, 12, 2) || ':' || substring($val, 14, 2))

    (: Return the original string if parsing fails :)
    else $val
};
