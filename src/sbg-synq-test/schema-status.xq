declare namespace iso="http://purl.oclc.org/dsdl/schematron";
declare namespace svrl="http://purl.oclc.org/dsdl/svrl";

(: vorm schematron report (svrl) om in het gestandaardiseerde test-results doc

<test-results>
   <result bron="" waarde="" type=""/>

declare variable $schema-uri as xs:string external;

declare variable $schema := doc($schema-uri)/iso:schema;

 :)

declare variable $sbg-bron := //sbg-systeemtest[1];
declare variable $schema := //iso:schema[1];
declare variable $svrl := //svrl:schematron-output[1];

(: fails bevat de test die niet goed zijn gegaan; op att role is de verwijzing naar het test-document te vinden :)
declare variable $fails := $svrl//svrl:failed-assert;

(: de bron-vermeldingen zijn listig opgenomen in de test role... :)
(: meervoudige verwijzingen voor 1 test worden gescheiden door een '+'  :)
declare function local:get-bron-ids( $str as xs:string ) 
as xs:string*
{
    let $test-refs := tokenize( $str , "\+" )
    for $ref in $test-refs
    return normalize-space($ref)
};

(: zie http://www.w3.org/TR/xpath-functions bijlage D
NB; 'eq' werkt hier niet ?? :)
declare function local:value-intersect($arg1, $arg2)
as item()*
{
distinct-values( $arg1[. = $arg2] )
};

declare function local:value-except($arg1, $arg2)
as item()*
{
distinct-values( $arg1[not(. = $arg2)] )
};


(: geef de asserts die niet voorkomen in bron-document :)
declare function local:get-schema-zonder-bron()
as element(iso:assert) *
{
for $ass in $schema//iso:assert
let $bron-ids := local:get-bron-ids($ass/@role),
    $doorsnede := local:value-intersect( $sbg-bron//@bron, $bron-ids )
return if ( count($doorsnede) eq 0 ) then $ass else () 
};

(: geef de asserts met een ref naar bron; ompolen intersect/except ?:)
declare function local:get-schema-met-bron()
as element(iso:assert) *
{
for $ass in $schema//iso:assert
let $bron-ids := local:get-bron-ids($ass/@role),
    $verschil := local:value-except( $sbg-bron//@bron, $bron-ids )
return if ( count($verschil) gt 0 ) then $ass else () 

};

(: geef voor elke verwijzing naar bron een result-elt; er kunnen maw meer results verschijnen voor dezelfde assert :)
declare function local:assert-result( $ass as element(iso:assert) )
as element(result)*
{
let $desc := data($ass/text()),  (: mixed content mogelijk :)
    $test := data($ass/@test)

for $bron in local:get-bron-ids($ass/@role)
let $nr-fail := count( $fails[contains(./@role, $bron)] ),  (: hier worden de fails met overeenstemmende role geteld :)
    $pass := $nr-fail = 0,
    $msg := if ( $pass ) then "" else concat("; ", $nr-fail, "&#x2715; fout"),
    $type := if ( index-of( distinct-values( $sbg-bron//@bron), $bron)) then 'sbg-xls' else 'geen bron' 
return <result bron="{$bron}" pass="{$pass}" type="{$type}">{concat($test, $msg)}</result>
};

<test-run>
    <info versie="0.98" timestamp="{current-dateTime()}" type="schema">
    resultaat van een schematron-validatie met sbg-bmimport.schematron 
    <document>{data($svrl//*[@document][1]/@document)}</document>
    <schematron schema="sbg-bmimport.schematron">
        <aantal-rules-fired>{count($svrl//svrl:fired-rule)}</aantal-rules-fired>
        <aantal-failed-assert>{count($svrl//svrl:failed-assert)}</aantal-failed-assert>
        <passed>{ 
        for $ctx in distinct-values( $svrl//svrl:fired-rule/@context )
        let $rules := $svrl//svrl:fired-rule[@context eq $ctx]
        return <aantal-fired-rules context="{$ctx}" count="{count($rules)}"/>
        }</passed>
        <failed>{
        for $test in distinct-values( $fails/@test )
        let $f-asserts := $fails[@test eq $test],
        $code := distinct-values($f-asserts/@role)
        return <failed-asserts test="{$test}" code="{$code}" count="{count($f-asserts)}">{
        for $ass in $f-asserts[@onderdruk]
        return <location>{$ass/@location}</location>
        }</failed-asserts>
        }</failed>
    </schematron>
</info>
<results>{
for $ass in local:get-schema-met-bron() union local:get-schema-zonder-bron()
return local:assert-result($ass)
}

</results>
</test-run>