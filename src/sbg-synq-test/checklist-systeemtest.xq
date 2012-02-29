import module namespace sbgtest = 'http://sbg-synq.nl/sbg-test' at 'sbg-systeemtest.xquery';

(: maak een html checklist op basis van het resultaat van sbg-systeem-test:run-tests() :)

declare namespace saxon="http://saxon.sf.net/";
declare namespace sbg = "http://sbggz.nl/schema/import/5.0.1";
declare namespace iso = "http://purl.oclc.org/dsdl/schematron";


declare option saxon:output "omit-xml-declaration=yes";
(: declare option saxon:output "method=html"; :)


(: param :)


(:
declare variable $test-doc := doc('sbg-systeemtest.xml')/sbg-systeemtest;
declare variable $schema-result external;
declare variable $sbg-synq-status-doc as xs:string external;
declare variable $schema-status-doc as xs:string external;
declare variable $sbg-cl := doc('sbg-codelijst.xml')/sbg-codelijsten;
declare variable $sbg-zorgdomein := doc( 'sbg-zorgdomein' )/sbg-zorgdomeinen; 
declare variable $sbg-input-doc := doc('../sbg-testdata/bmstore-anon.xml');

sbgtest:add-tests( , $schema-status );
declare variable $test-result := sbgtest:add-tests($test-run, $schema-status//result[@waarde = 'true']);
declare variable $test-result := $test-run;
 :)
(: input :) 
declare variable $context-doc := .;
declare variable $test-result := $context-doc//test-results;
declare variable $test-doc := $context-doc//sbg-systeemtest;
declare variable $xkenmerken := $context-doc//kenmerken;

(:
declare variable $schema-status := doc($schema-status-doc)/test-results;
declare variable $sbg-synq-status := doc($sbg-synq-status-doc)/test-results;
declare variable $test-run := sbgtest:run-tests($sbg-input-doc, $sbg-cl);
declare variable $test-result.1 := sbgtest:add-tests($test-run, $schema-status//result);
declare variable $test-result := sbgtest:add-tests($test-result.1, $sbg-synq-status//result[@waarde = 'true']);
:)



(: deze kenmerken zijn zoekstrings in de aspect tekst; worden als tags toegevoegd aan test voor representatie:)
declare variable $kenmerken := <kenmerken>
    <kenmerk type="verplicht">Wordt er altijd een waarde getoond</kenmerk>
    <kenmerk type="reeks">reeks</kenmerk>
    <kenmerk type="reeks">referentie</kenmerk>
    <kenmerk type="formaat">formaat</kenmerk>
    <kenmerk type="normatief">moet</kenmerk>
    <kenmerk type="normatief">afgesproken</kenmerk>
    <kenmerk type="normatief">dummy</kenmerk>
    <kenmerk type="normatief">mag niet</kenmerk>
    <kenmerk type="normatief">is mogelijk</kenmerk>
    <kenmerk type="steekproef">juist</kenmerk>
    <kenmerk type="steekproef">worden meegenomen</kenmerk>
    <kenmerk type="steekproef">dichtstbij</kenmerk>
    <kenmerk type="relatie"> betrekking</kenmerk>
    <kenmerk type="relatie">koppel</kenmerk>
    <kenmerk type="uniek">uniek</kenmerk>
</kenmerken>;


declare function local:build-kenmerk-class( $str as xs:string? ) as xs:string
{
    let $kms := for $km in $kenmerken//kenmerk
                let $heeft-kenmerk := contains( $str, $km/text() ),
                    $style := if ($heeft-kenmerk) then data($km/@type)  else ()  
                return $style,
        $km := distinct-values( $kms )
    return if ( count($km) > 0 ) then string-join(data($km), ' ') else 'geen'
};

declare function local:build-kenmerken( $tests as element(test)* ) as element(test)*
{
    for $t in $tests
    let $km-class := local:build-kenmerk-class($t/aspect/text())
    return element { 'test' } { $t/@* union attribute { 'km-class' } { $km-class }, $t/* }
    
};
declare function local:div-test-info( $info as element(test-info) ) as element(div)
{
let $ts := ($info/@start, $info/@datum)[1]
return 
<div class="test-info off {$info/@type}">
<p>{concat( $info/@type, ', versie ', $info/@versie, ': ', $ts)}</p>
<p>{$info/text()}</p>
<ul>
{
for $elt in $info/*
let $label := replace( local-name($elt), '-', ' ' )
return <li class="test-info">{$label}: {$elt/text()}</li>
}
</ul>
</div>    
};
     
(: html representatie  
:)
    
let $cnt := count($test-doc//test),
    $tests := local:build-kenmerken($test-doc//test),
    $cnt-nok := count($test-result//result[@waarde=false()]),
    $cnt-schema := count($test-result//result[@type eq 'schematron']),
    $cnt-sbg-synq := count($test-result//result[@waarde=true()][@type eq 'sbg-synq']),
    $cnt-ok := count($test-result//result[@waarde=true()][@type ne 'sbg-synq']),
    
    $groep-namen := distinct-values($test-doc//hoofdgroep/name/text()),
    $subgroep-namen := distinct-values($test-doc//hoofdgroep/subgroep/name/text()),
    $ssubgroep-namen := distinct-values($test-doc//hoofdgroep/subgroep/subsubgroep/name/text())
    
return
<html>
<head>
<title>sbg systeemtest 0.9</title>
</head>
<body>

<h2>{$test-result//test-info/document[1]/text()}</h2>
<div id = "resultaatcontrols">
    <div id="missed" class="test-control s-missed off">niet getest {$cnt - ($cnt-nok + $cnt-ok + $cnt-sbg-synq)}</div>
    <div id="fail" class="test-control s-fail off">niet OK {$cnt-nok}</div>
    <div id="pass" class="test-control s-pass off">OK {$cnt-ok}</div>
    <div id="schema" class="test-control s-schema off">in schema {$cnt-schema}</div>
    <div id="sbg-synq" class="test-control s-sbg-synq off">sbg-synq {$cnt-sbg-synq}</div>
</div>

<p>indeling SBG</p>

<div id="testinfo">
{ 
for $info in $test-result//test-info
return local:div-test-info($info)
}
</div>

<div id="groepcontrols">
    {
    for $groep in $groep-namen
    let $gr := translate($groep, " +.", ""),
        $aantal := count($test-doc/hoofdgroep[name=$groep]//test),
        $aantal-OK := sum( for $ref in $test-doc/hoofdgroep[name=$groep]//test/@bron 
                       return if (exists($test-result//result[@bron=$ref][@waarde='true'])) then 1 else 0 ),
        $perc := round(100 * $aantal-OK div $aantal),
        $bg-color := concat('hsl( 120, ', $perc, '%, 80%)') 
    return <div id="{$gr}" class="groep-control off" style="background-color: {$bg-color}">{$groep}<div class="aantal">{$perc}% van {$aantal}</div></div>
    }
</div>
<p>beperk selectie op kenmerken</p>
<div id="kenmerkcontrols">
    
    {
    for $kmk in (distinct-values($kenmerken//kenmerk/@type), 'geen') 
    let $km := translate($kmk, " +.", ""),
        $tsts := $tests[contains(@km-class, $kmk)],
        
        $aantal := count($tsts),
        $aantal-OK := sum( for $ref in $tsts/@bron 
                       return if (exists($test-result//result[@bron=$ref][@waarde='true'])) then 1 else 0 ),
        $perc := round(100 * $aantal-OK div $aantal),
    
        $bg-color := concat('hsl( 120, ', $perc + 10, '%, 80%)')
    return <div id="{$km}" class="kenmerk-control off" style="background-color: {$bg-color}">{$km}<div class="aantal">{$perc}% van {$aantal}</div></div>
    }
</div>

{ 
for $t in $test-doc//test
let $km-class := data($tests[@bron = $t/@bron]/@km-class),
    $aspect := ($t/aspect/text(), '-')[1],
    $groep := $t/../../../name/text(),
    $sgroep := $t/../../name/text(),
    $ssgroep :=$t/../name/text(),
    
    $result := $test-result//result[@bron=$t/@bron],
    $pass := if ( exists($result[@waarde='true'])) then 'pass' else 'fail',
    $result-class := if ( exists($result) ) then 
                        if ( $result[@type='schematron'] ) then concat( 'schema ', $pass )
                        else if ( $result[@type='sbg-synq'] ) then concat( 'sbg-synq ', $pass) 
                             else $pass 
                     else 'missed'
return  
 <div class="test {$km-class} off {$result-class} {translate($groep, " +.", "")}">
     <div class="bron">{data($t/@bron)}</div>
    <div class="groep">{$groep}.</div>
    <div class="subgroep">{$sgroep}.</div>
    <div class="subsubgroep">{$ssgroep}.</div>
    <div class="aspect">{$aspect}</div>
    <div class="result">{($result/text(), '.')[1]}</div>
    <div class="kenmerk">{$km-class}</div>
</div>
}
</body>
</html>