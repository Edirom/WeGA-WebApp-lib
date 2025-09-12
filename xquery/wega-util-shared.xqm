xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module with utility functions 
 :)
module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared";

declare namespace map="http://www.w3.org/2005/xpath-functions/map";

(:~
 :  List of mimetypes
 :  Originally taken from https://raw.githubusercontent.com/eXist-db/exist/develop/exist-core/src/main/resources/org/exist/util/mime-types.xml
 :)
declare variable $wega-util-shared:mimetypes as element(wega-util-shared:mime-types) := 
<mime-types xmlns="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared">

    <!-- Mime types stored as XML -->
    <mime-type name="application/xml" type="xml">
        <description>XML document</description>
        <extensions>.xml,.xsd,.rng,.mods,.xmp,.xmi,.xconf,.xmap,.xsp,.wsdl,.x3d,.owl,.dbx,.tei,.xces,.ead,.xqx,.xform,.gml,.fo,.nvdl,.sch,.imdi,.cmdi,.odd,.jcmconnect,.ditaval</extensions>
    </mime-type>
    <!-- default is 'application/xml' for .xml This required to resolve 'text/xml' -->
    <mime-type name="text/xml" type="xml">
        <description>Deprecated XML document</description>
        <extensions>.xml</extensions>
    </mime-type>
    <mime-type name="application/xslt+xml" type="xml">
        <description>XSL document</description>
        <extensions>.xsl,.xslt</extensions>
    </mime-type>
    <mime-type name="application/stx+xml" type="xml">
        <description>STX document</description>
        <extensions>.stx</extensions>
    </mime-type>
    <mime-type name="application/rdf+xml" type="xml">
        <description>RDF document</description>
        <extensions>.rdf,.rdfs</extensions>
    </mime-type>
    <mime-type name="application/xhtml+xml" type="xml">
        <description>XHTML document</description>
        <extensions>.xhtml,.xht</extensions>
    </mime-type>
    <mime-type name="text/html" type="xml">
        <description>HTML document</description>
        <extensions>.html,.htm</extensions>
    </mime-type>
    <mime-type name="application/atom+xml" type="xml">
        <description>Atom Feed Document</description>
        <extensions>.atom</extensions>
    </mime-type>
    <mime-type name="image/svg+xml" type="xml">
        <description>SVG image</description>
        <extensions>.svg,.svgz</extensions>
    </mime-type>
    <mime-type name="application/xml+xproc" type="xml">
        <description>XML pipeline (XProc)</description>
        <extensions>.xpl,.xproc</extensions>
    </mime-type>
    <mime-type name="application/oebps-package+xml" type="xml">
        <description>Open Packaging Format (OPF) Document</description>
        <extensions>.opf</extensions>
    </mime-type>
    <mime-type name="application/x-dtbncx+xml" type="xml">
        <description>Navigation Control file for XML (NCX) Document</description>
        <extensions>.ncx</extensions>
    </mime-type>
    <mime-type name="application/scm+xml" type="xml">
        <description>Schema Component Model</description>
        <extensions>.scm</extensions>
    </mime-type>
    
    <!-- Binary mime types -->
    <mime-type name="application/exi" type="binary">
        <description>Efficient XML Interchange</description>
        <extensions>.exi</extensions>
    </mime-type>
    <mime-type name="application/xquery" type="binary">
        <description>XQuery script</description>
        <extensions>.xq,.xql,.xqm,.xquery,.xqy,.xqws</extensions>
    </mime-type>
    <mime-type name="application/octet-stream" type="binary">
        <description>Generic binary stream</description>
        <extensions>.jar,.exe,.dll,.o</extensions>
    </mime-type>
    <mime-type name="application/json" type="binary">
        <description>JSON</description>
        <extensions>.json</extensions>
    </mime-type>
    
    <mime-type name="application/zip" type="binary">
        <description>ZIP archive</description>
        <extensions>.zip</extensions>
    </mime-type>
    <!-- GZIP is an addition thats not provided by the original file --> 
    <mime-type name="application/gzip" type="binary">
        <description>GNU ZIP archive</description>
        <extensions>.gz,.gzip</extensions>
    </mime-type>
    <mime-type name="application/epub+zip" type="binary">
        <description>EPUB document</description>
        <extensions>.epub</extensions>
    </mime-type>
    <mime-type name="application/expath+xar" type="binary">
        <description>package XAR archive</description>
        <extensions>.xar</extensions>
    </mime-type>    

    <!-- OpenOffice.org - Open Document -->
    <mime-type name="application/vnd.oasis.opendocument.text" type="binary">
    	<description>OpenOffice.org Text Document</description>
    	<extensions>.odt</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.presentation" type="binary">
    	<description>OpenOffice.org Presentation</description>
    	<extensions>.odp</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.spreadsheet" type="binary">
    	<description>OpenOffice.org spreadsheet</description>
    	<extensions>.ods</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.graphics" type="binary">
    	<description>OpenOffice.org Drawing</description>
    	<extensions>.odg</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.chart" type="binary">
    	<description>OpenOffice.org Diagram Chart</description>
    	<extensions>.odc</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.formula" type="binary">
    	<description>OpenOffice.org Formula</description>
    	<extensions>.odf</extensions>
    </mime-type>
    <!-- .odb have several mime-types, first is default -->
    <mime-type name="application/vnd.oasis.opendocument.database" type="binary">
    	<description>OpenOffice.org Data Base</description>
    	<extensions>.odb</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.base" type="binary">
    	<description>OpenOffice.org Data Base</description>
    	<extensions>.odb</extensions>
    </mime-type>

    <mime-type name="application/vnd.oasis.opendocument.image" type="binary">
    	<description>OpenOffice.org Image</description>
    	<extensions>.odi</extensions>
    </mime-type>

    <mime-type name="application/vnd.oasis.opendocument.text-master" type="binary">
    	<description>OpenOffice.org Main Document</description>
    	<extensions>.odm</extensions>
    </mime-type>
    
    <!-- OpenDocument models -->
    <mime-type name="application/vnd.oasis.opendocument.text-template" type="binary">
    	<description>OpenOffice.org formatted Text model</description>
    	<extensions>.ott</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.spreadsheet-template" type="binary">
    	<description>OpenOffice.org spreadsheet model</description>
    	<extensions>.ots</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.presentation-template" type="binary">
    	<description>OpenOffice.org Presentation model</description>
    	<extensions>.otp</extensions>
    </mime-type>
    <mime-type name="application/vnd.oasis.opendocument.graphics-template" type="binary">
    	<description>OpenOffice.org Drawing model</description>
    	<extensions>.otg</extensions>
    </mime-type>

    <!-- OpenOffice.org - versions 1.X -->
    <mime-type name="application/vnd.sun.xml.writer" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sxw</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.writer.template" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.stw</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.writer.global" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sxg</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.calc" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sxc</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.calc.template" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.stc</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.impress" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sxi</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.impress.template" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sti</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.draw" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sxd</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.draw.template" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.std</extensions>
    </mime-type>
    <mime-type name="application/vnd.sun.xml.math" type="binary">
    	<description>OpenOffice.org Document</description>
    	<extensions>.sxm</extensions>
    </mime-type>

    <!-- Microsoft Office  -->
    <mime-type name="application/msword" type="binary">
    	<description>Microsoft Word Document</description>
    	<extensions>.doc</extensions>
    </mime-type>
    <mime-type name="application/vnd.ms-powerpoint" type="binary">
    	<description>Microsoft Powerpoint Document</description>
    	<extensions>.ppt</extensions>
    </mime-type>
    <mime-type name="application/vnd.ms-excel" type="binary">
    	<description>Microsoft Excel Document</description>
    	<extensions>.xls</extensions>
    </mime-type>
    <mime-type name="application/vnd.visio" type="binary">
        <description>Microsoft Visio Document</description>
        <extensions>.vsd</extensions>
    </mime-type>

    <!-- OOXML -->
    <mime-type name="application/vnd.openxmlformats-officedocument.wordprocessingml.document" type="binary">
        <description>OOXML Text Document</description>
        <extensions>.docx</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.openxmlformats-officedocument.wordprocessingml.template" type="binary">
        <description>OOXML Text Template</description>
        <extensions>.dotx</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.openxmlformats-officedocument.presentationml.template" type="binary">
        <description>OOXML Presentation Template</description>
        <extensions>.potx</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.openxmlformats-officedocument.presentationml.presentation" type="binary">
        <description>OOXML Presentation</description>
        <extensions>.pptx</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.openxmlformats-officedocument.presentationml.slideshow" type="binary">
        <description>OOXML Presentation Slideshow</description>
        <extensions>.ppsx</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" type="binary">
        <description>OOXML Spreadsheet</description>
        <extensions>.xlsx</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.openxmlformats-officedocument.spreadsheetml.template" type="binary">
        <description>OOXML Spreadsheet Template</description>
        <extensions>.xltx</extensions>
    </mime-type>

    <mime-type name="application/xml-dtd" type="binary">
        <description>External DTD subsets</description>
        <extensions>.dtd,.mod</extensions>
    </mime-type>

    <mime-type name="application/xml-external-parsed-entity" type="binary">
        <description>External parsed entities</description>
        <extensions>.ent</extensions>
    </mime-type>
    
    <mime-type name="application/vnd.adobe.flash-movie" type="binary">
        <description>Adobe Flash Movie</description>
        <extensions>.swf</extensions>
    </mime-type>

    <mime-type name="video/vnd.avi" type="binary">
        <description>Audio Video Interleaved</description>
        <extensions>.avi</extensions>
    </mime-type>

    <mime-type name="video/webm" type="binary">
        <description>WebM</description>
        <extensions>.webm</extensions>
    </mime-type>

    <mime-type name="text/x-java-source" type="binary">
        <description>Java source code</description>
        <extensions>.java</extensions>
    </mime-type>

    <mime-type name="application/java-byte-code" type="binary">
        <description>Java byte code</description>
        <extensions>.class</extensions>
    </mime-type>

    <mime-type name="application/relax-ng-compact-syntax" type="binary">
        <description>RelaxNG compact syntax</description>
        <extensions>.rnc</extensions>
    </mime-type>

    <mime-type name="application/prs.aff-dictionary" type="binary">
        <description>Affix File Format</description>
        <extensions>.aff</extensions>
    </mime-type>
    
    <mime-type name="application/prs.dictionary" type="binary">
        <description>Dictionary File Format</description>
        <extensions>.dic</extensions>
    </mime-type>

    <mime-type name="text/csv" type="binary">
        <description>Comma Seperated Values</description>
        <extensions>.csv</extensions>
    </mime-type>
    
    <mime-type name="text/plain" type="binary">
        <description>Plain text</description>
        <extensions>.txt,.text,.properties,.sh</extensions>
    </mime-type>

    <mime-type name="text/markdown" type="binary">
        <description>Markdown</description>
        <extensions>.md</extensions>
    </mime-type>

    <mime-type name="text/css" type="binary">
        <description>CSS stylesheet</description>
        <extensions>.css</extensions>
    </mime-type>

	<!-- DITA -->
    <mime-type name="application/dita+xml" type="xml">
        <description>DITA document</description>
        <extensions>.dita,.ditamap</extensions>
    </mime-type>

    <!-- Bitmaps -->
    <mime-type name="image/png" type="binary">
        <description>PNG image</description>
        <extensions>.png</extensions>
    </mime-type>
    <mime-type name="image/gif" type="binary">
        <description>GIF image</description>
        <extensions>.gif</extensions>
    </mime-type>
    <mime-type name="image/jpeg" type="binary">
        <description>JPEG image</description>
        <extensions>.jpg,.jpeg</extensions>
    </mime-type>
    <mime-type name="image/x-portable-bitmap" type="binary">
        <description>PBM Bitmap Format</description>
        <extensions>.pbm</extensions>
    </mime-type>
    <mime-type name="image/bmp" type="binary">
        <description>Windows Bitmap Image</description>
        <extensions>.bmp</extensions>
    </mime-type>
    <mime-type name="image/tiff" type="binary">
        <description>Tag Image File Format</description>
        <extensions>.tif</extensions>
    </mime-type>
    <mime-type name="image/x-xbitmap" type="binary">
        <description>X Bitmap Graphic</description>
        <extensions>.xbm</extensions>
    </mime-type>
	<mime-type name="image/vnd.microsoft.icon" type="binary">
		<description>Icon image</description>
		<extensions>.ico</extensions>
	</mime-type>

    <!-- Misc -->
    <mime-type name="application/pdf" type="binary">
        <description>PDF (Adobe)</description>
        <extensions>.pdf</extensions>
    </mime-type>
    <mime-type name="application/postscript" type="binary">
        <description>PostScript Document</description>
        <extensions>.eps,.ps</extensions>
    </mime-type>
    <mime-type name="application/javascript" type="binary">
        <description>JavaScript</description>
        <extensions>.js</extensions>
    </mime-type>
    <mime-type name="application/less" type="binary">
        <description>Less</description>
        <extensions>.less</extensions>
    </mime-type>
    
    <!-- Media types -->
    <mime-type name="audio/mpeg" type="binary">
        <description>MPEG Audio</description>
        <extensions>.mp2,.mp3,.mpga</extensions>
    </mime-type>
    <mime-type name="video/mpeg" type="binary">
        <description>MPEG Video</description>
        <extensions>.mpg,.mpeg</extensions>
    </mime-type>
    <mime-type name="video/mp4" type="binary">
        <description>MP4 Video</description>
        <extensions>.mp4</extensions>
    </mime-type>
    
    <!-- Font types -->
    <mime-type name="application/font-woff" type="binary">
        <description>WOFF File Format</description>
        <extensions>.woff</extensions>
    </mime-type>
    
</mime-types>
;

(:~
 :  A slight modification of the standard XPath function fn:doc-available()
 :  which will return false() for binary documents instead of failing
 :)
declare function wega-util-shared:doc-available($uri as xs:string?) as xs:boolean {
    try {doc-available($uri)}
    catch * {false()}
};

(:~
 :  Checks whether the json resource identified by $uri is available.
 :)
declare function wega-util-shared:json-doc-available($uri as xs:string?) as xs:boolean {
    try {exists(json-doc($uri))}
    catch * {false()}
};

(:~
 :  A helper function for checking for content built on fn:boolean()
 :  Content is defined as non-zero, non-whitespace-only, non-false() and is recursively applied to maps and arrays
 :)
declare function wega-util-shared:has-content($items as item()*) as xs:boolean {
    some $item in $items satisfies
    typeswitch($item)
    case array(*) return some $i in $item?* satisfies wega-util-shared:has-content($i)
    case map(*) return some $i in map:keys($item) satisfies wega-util-shared:has-content($item($i))
    case attribute() return ( if(normalize-space($item) castable as xs:double) then wega-util-shared:has-content(xs:double(normalize-space($item))) else wega-util-shared:has-content(string($item)) )
    case element() return ( if(normalize-space($item) castable as xs:double) then wega-util-shared:has-content(xs:double(normalize-space($item))) else wega-util-shared:has-content(string($item)) )
    case xs:string return normalize-space($item) != ''
    case xs:date return true() 
    case xs:dateTime return true()
    case function(*) return true()
    default return boolean($item)
};

(:~
 : Helper function for guessing a mime-type from a file extension
 :
 : @author Peter Stadler 
 : @param $suffix the file extension
 : @return the mime-type or the empty sequence when no match was found
 :)
declare function wega-util-shared:guess-mimeType-from-suffix($suffix as xs:string) as xs:string? {
    let $extensions := $wega-util-shared:mimetypes//wega-util-shared:extensions
    return
        ($extensions[(tokenize(., ',\s*') = concat('.', $suffix))]/parent::wega-util-shared:mime-type[not(contains(wega-util-shared:description, 'Deprecated'))])/@name
};

(:~
 : Sort TEI elements by their cert-attribute (e.g. <tei:date cert="medium"/>)
 : NB: items without cert-attribute will rank the highest, followed by 'high', 'medium', 'low', 'unknown'
 :
 : @param $items the items to sort
 : @return the sorted sequence of the items
 :)
declare function wega-util-shared:order-by-cert($items as item()*) as item()* {
    let $order := map {
        'high' : 1,
        'medium' : 2,
        'low' : 3,
        'unknown' : 4,
        '' : 0
    }
    return
        for $i in $items
        let $cert := $i/string(@cert)
        order by $order($cert)
        return $i
};

(:~
 : Try to cast a given item to xs:string and check its semantic boolean value
 : 
 : @param $item the item to check
 : @return true() for 'yes', '1', or 'true', false() otherwise
 :)
declare function wega-util-shared:semantic-boolean($item as item()) as xs:boolean {
    let $true-strings := ('yes', '1', 'true')
    return
        if($item castable as xs:string)
        then normalize-space(string($item)) = $true-strings
        else false()
};
