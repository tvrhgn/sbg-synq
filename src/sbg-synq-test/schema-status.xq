declare namespace iso="http://purl.oclc.org/dsdl/schematron";
declare namespace svrl="http://purl.oclc.org/dsdl/svrl";

(: vorm schematron report (svrl) om in het gestandaardiseerde test-results doc

<test-results>
   <result bron="" waarde="" type=""/>

declare variable $schema-uri := 'sbg-bmimport.schematron';
declare variable $schema-uri as xs:string external;
 :)


declare variable $schema-uri as xs:string external;

declare variable $schema := doc($schema-uri)/iso:schema;


declare variable $svrl := ./svrl:schematron-output;
declare variable $fails := .//svrl:failed-assert;

(: de bron-vermeldingen zijn listig opgenomen in de test role... :)
(: meervoudige verwijzingen voor 1 test worden gescheiden door een '+'  :)
declare function local:get-bron-ids( $str as xs:string ) as xs:string* 
{
    let $test-refs := tokenize( $str , "\+" )
    for $ref in $test-refs
    return normalize-space($ref)
};


<test-results>
<test-info versie="0.9" start="{current-dateTime()}" type="schema">
sbg-bmimport.schematron test het benchmark-import bestand op een selectie van structuur- en inhoudsaspecten.
<document>{data($svrl//*[@document][1]/@document)}</document>
<aantal-rules-fired>{count($svrl//svrl:fired-rule)}</aantal-rules-fired>
<aantal-failed-assert>{count($svrl//svrl:failed-assert)}</aantal-failed-assert>
</test-info>{
for $ass in $schema//iso:assert
let $desc := $ass/text()[1],
    $test := data($ass/@test)
for $bron in local:get-bron-ids($ass/@role)
    let $nr-fail := count( $fails[contains(./@role, $bron)] ),
        $pass := $nr-fail = 0,
        $msg := if ( $pass ) then "" else concat("; ", $nr-fail, "&#x2715; fout")
return <result bron="{$bron}" waarde="{$pass}" type="schematron">{concat($test, $msg)}</result>

}</test-results>