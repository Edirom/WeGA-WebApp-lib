xquery version "3.1";

(:~
 : Test suite for the ICS (iCalendar) processing module.
 :)
module namespace icst="http://xquery.weber-gesamtausgabe.de/modules/ics-tests";

declare namespace ical="urn:ietf:params:xml:ns:icalendar-2.0";
import module namespace test="http://exist-db.org/xquery/xqsuite"
    at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

import module namespace ics="http://xquery.weber-gesamtausgabe.de/modules/ics"
    at "../xquery/ics.xqm";

(: Original sampletaken from <https://www.rfc-editor.org/rfc/rfc6321.html>. :)
declare variable $icst:sample-ics1 as xs:string :=
"BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Example Inc.//Example Calendar//EN
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:20080205T191224Z
DTSTART:20081006
SUMMARY:Planning meeting
UID:4088E990AD89CB3DBB484909
END:VEVENT
END:VCALENDAR";

(: Modified sample with folded line :)
declare variable $icst:sample-ics2 as xs:string :=
"BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Example Inc.//Example Calendar//EN
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:20080205T19
 1224Z
DTSTART:20081006
SUMMARY:Planning meeting
UID:4088E990AD89CB3DBB484909
END:VEVENT
END:VCALENDAR";

(: Incomplete sample missing END:VCALENDAR :)
declare variable $icst:sample-ics3 as xs:string :=
"BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Example Inc.//Example Calendar//EN
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:20080205T191224Z
DTSTART:20081006
SUMMARY:Planning meeting
UID:4088E990AD89CB3DBB484909
END:VEVENT
";

(: Sample with invalid character "#" and blank line :)
declare variable $icst:sample-ics4 as xs:string :=
"BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Example Inc.//Example Calendar//EN
VERSION:2.0
BEGIN:VEVENT

#
DTSTAMP:20080205T191224Z
DTSTART:20081006
SUMMARY:Planning meeting
UID:4088E990AD89CB3DBB484909
END:VEVENT
END:VCALENDAR";


declare variable $icst:expected-xml1 as element(ical:icalendar) :=
<icalendar xmlns="urn:ietf:params:xml:ns:icalendar-2.0">
    <vcalendar>
     <properties>
      <calscale>
        <text>GREGORIAN</text>
      </calscale>
      <prodid>
       <text>-//Example Inc.//Example Calendar//EN</text>
      </prodid>
      <version>
        <text>2.0</text>
      </version>
     </properties>
     <components>
      <vevent>
       <properties>
        <dtstamp>
          <date-time>2008-02-05T19:12:24Z</date-time>
        </dtstamp>
        <dtstart>
          <date>2008-10-06</date>
        </dtstart>
        <summary>
         <text>Planning meeting</text>
        </summary>
        <uid>
         <text>4088E990AD89CB3DBB484909</text>
        </uid>
       </properties>
      </vevent>
     </components>
    </vcalendar>
   </icalendar>
;

declare variable $icst:fail :=
    let $builtin := function-lookup(xs:QName("test:fail"), 4)
    return
        if (exists($builtin))
        then
            $builtin
        else (: fallback :)
            function ($message, $expected, $actual, $type) {
                error(xs:QName("icst:" || $type), $message, map {
                    "expected": $expected,
                    "actual": $actual
                })
            }
;

declare %test:assertTrue function icst:test-parse-ics1() as xs:boolean?  {
    let $parsed := ics:parse-ics($icst:sample-ics1)
    return
        if (deep-equal($parsed, $icst:expected-xml1)) then
            true()
        else
            $icst:fail("ICS parsing does not match expected XML structure.", $icst:expected-xml1, $parsed, "fail")
};

declare %test:assertTrue function icst:test-parse-ics2() as xs:boolean?  {
    let $parsed := ics:parse-ics($icst:sample-ics2)
    return
        if (deep-equal($parsed, $icst:expected-xml1)) then
            true()
        else
            $icst:fail("ICS parsing does not match expected XML structure.", $icst:expected-xml1, $parsed, "fail")
};

declare %test:assertEmpty function icst:test-parse-ics3() as xs:boolean?  {
    ics:parse-ics($icst:sample-ics3)
};

declare %test:assertTrue function icst:test-parse-ics4() as xs:boolean?  {
    let $parsed := ics:parse-ics($icst:sample-ics4)
    return
        if (deep-equal($parsed, $icst:expected-xml1)) then
            true()
        else
            $icst:fail("ICS parsing does not match expected XML structure.", $icst:expected-xml1, $parsed, "fail")
};
