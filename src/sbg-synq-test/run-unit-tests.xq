(: XQuery main module :)
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/modules/sbg-epd.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/modules/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/modules/sbg-metingen.xquery';
import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/modules/sbg-bmimport.xquery';
import module namespace sbgem="http://sbg-synq.nl/epd-meting" at '../sbg-synq/modules/epd-meting.xquery';
import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/modules/zorgaanbieder.xquery';

import module namespace unit='http://sbg-synq.nl/unit-test' at 'unit-test.xquery';

declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


declare variable $test-doc := .; 



(: ---------- group functies ------------------------ :)

declare function local:test-dbc-peildatums( $tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
for $test in $tests
let $dbc := unit:get-object-ns($ctx, $test/setup/sbgem:DBCTraject[1]),
    $zorgdomein := unit:get-object($ctx, $test/setup/zorgdomein[1]),
                        
    $expected := $test/expected/value/text(),
        
    $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ), 
    
    $test-string := concat( string($peildatums[1]), ', ', string($peildatums[2])),
    $pass := $expected eq $test-string,
    $actual :=  <value>{$test-string}</value>
    return unit:build-test-result( $test, $pass, ($dbc, $zorgdomein), $actual )
};

declare function local:test-kandidaat-metingen($tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
(: setup bevat 1 dbc, 1 zorgdomein en N metingen :)
for $test in $tests
    let $dbc := unit:get-object-ns($ctx, $test/setup/sbgem:DBCTraject),
        $zorgdomein := unit:get-object($ctx, $test/setup/zorgdomein),
        $metingen := for $ref in $test/setup/sbgem:Meting
                     return unit:get-object-ns($ctx, $ref),
                        
        $expected := $test/expected/kandidaat-metingen,
        
        $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ),
        $result := sbge:kandidaat-metingen( $metingen, $zorgdomein, $peildatums ),
        
        
        $pass :=  unit:ordered-set-equal( $expected/voor/*, $result/voor/*)
                  and unit:ordered-set-equal( $expected/na/*, $result/na/*)
        
    return unit:build-test-result( $test, $pass, ($dbc, $zorgdomein, $metingen),  $result )
};

declare function local:test-bepaal-zorgdomein($tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
(: setup bevat 1 zorgtraject en N metingen :)
for $test in $tests
    let $zt := $test/setup/sbgem:Zorgtraject,
        $metingen := for $ref in $test/setup/sbgem:Meting
                     return unit:get-object($ctx, $ref),
                        
        $expected := $test/expected/value,
        $result := sbge:bepaal-zorgdomein( $zt, $metingen ),
        
        $pass :=  $expected/text() eq $result
        
    return unit:build-test-result( $test, $pass, ($zt, $metingen),  <value>{$result}</value> )
};

declare function local:test-maak-meetparen( $tests as element(test)*, $ctx as element() )
as element(test)*
{
(: setup bevat 1 dbc, 1 zorgdomein en N metingen :)
for $test in $tests
    let $dbc := unit:get-object-ns($ctx, $test/setup/sbgem:DBCTraject),
        $zorgdomein := unit:get-object($ctx, $test/setup/zorgdomein),
        $metingen := for $ref in $test/setup/sbgem:Meting
                     return unit:get-object($ctx, $ref),
                        
        $expected := $test/expected/meetparen,
        
        $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ),
        $kandidaten := sbge:kandidaat-metingen( $metingen, $zorgdomein, $peildatums ),
        $result := sbge:optimale-meetpaar( $kandidaten, $zorgdomein ),
        
        $pass :=  unit:set-equal( $expected//sbggz:Meting, $result//sbggz:Meting, 'meting-id')
        
    return unit:build-test-result( $test, $pass, ($dbc, $zorgdomein, $metingen),  $result )
};

declare function local:test-vertaal-elts( $tests as element(test)*, $ctx as element() )
as element(test)*
{
(: setup bevat 1 row en 1 string+ met namen voor const waarden
$act := <value>{$result}</value>,
$act := element { 'value' } { attribute { 'marker' } { 'OK' } union $result },
$result := sbgem:vertaal-elt-naar-att-sbg( 'locatiecode', $row ),
$expected := $test/expected/value,
$expected := <value sbggz:locatiecode="A"/>,
        
        $result := attribute { 'sbgem:locatiecode' } {  "A" },

:)
for $test in $tests
    let $def := $test/setup/def,
        $row := $test/setup/row,
        $expected := $test/expected/value,                
        
        $param := distinct-values( tokenize($def/text(), ', ')),
        
        $result := sbgem:vertaal-elt-naar-att-sbg( $param, $row ),
        
        $act := element { 'value' } { $result },
        
        $pass :=  unit:atts-equal-ns( $expected, $act )
        
        return unit:build-test-result( $test, $pass, ($def, $row),  $act )    
    
};



(: 
SJABLOON
declare function local:test-vertaal-elts( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $def := $test/setup/,
        $row := $test/setup/,
        $expected := $test/expected/,                
               
        $result := 
        
        $act := element { 'value' } { $result },
        
        $pass :=  ( $expected, $act )
        
return unit:build-test-result( $test, false(), ($def, $row),  <box pass="{$pass}">{$act}</box> )    
};
:)

declare function local:test-bereken-score( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $instr-def := unit:get-object($ctx, $test/setup/instrument),
        $meting := unit:get-object($ctx, $test/setup/meting),
        $expected := $test/expected/value,
                        
        $instr := sbgi:laad-instrument($instr-def),
          
        $result := sbgi:bereken-score($meting,$instr), 
        
        $act := element { 'value' } { $result },
        
        $pass :=  data($expected) eq data($act)
        
return unit:build-test-result( $test, $pass, ($instr-def, $meting//item),  $act )    
};

declare function local:test-score-items( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $instr-def := unit:get-object($ctx, $test/setup/instrument),
        $meting := unit:get-object($ctx, $test/setup/meting),
        $expected := unit:double-seq($test/expected/value/text()),
                        
        $instr := sbgi:laad-instrument($instr-def),
          
        $result := sbgi:item-scores($meting,$instr),
        
        $act := element { 'value' } { $expected },
        
        
        $pass := unit:set-equal-atomic( $expected, $result )
        
return unit:build-test-result( $test, $pass, ($instr-def, $meting//item),  $act )    
};

declare function local:test-honosca-sum( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $instr-def := unit:get-object($ctx, $test/setup/instrument),
        $meting := unit:get-object($ctx, $test/setup/meting),
        $expected := xs:double($test/expected/value/text()),
                        
        $instr := sbgi:laad-instrument($instr-def),
          
        $result := sbgi:bereken-score($meting,$instr),
        
        $act := element { 'value' } { $result },
        
        $pass := $expected eq $result
        
return unit:build-test-result( $test, $pass, ($instr-def, $meting//item),  $act )    
};

declare function local:test-sbg-metingen( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $instr-def := unit:get-object($ctx, $test/setup/instrument),
        $meting := unit:get-object($ctx, $test/setup/meting),
        $expected := $test/expected/*,
                        
        $instr := sbgi:laad-instrument($instr-def),
          
        $result := sbgm:sbg-metingen($meting, $instr),
        
        $pass :=  unit:atts-equal( $expected, $result )
        
return unit:build-test-result( $test, $pass, ($instr, $meting/item),  $result )    
};


declare function local:test-batch-gegevens($tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $za := unit:get-object( $ctx, $test/setup/zorgaanbieder ),
        $expected := $test/expected/*[1],
               
        $result := sbgza:batch-gegevens($za),
        $pass :=  unit:atts-equal($expected,$result)
        
return unit:build-test-result( $test, $pass, ($za), $result  )    
}; 

(: doe tellingen op de sub-elementen in de hoop dat de juiste ontbreken :)
declare function local:gelijke-patienten($expected as element(sbggz:Patient)*, $result as element(sbggz:Patient)* )
{
let $cmp := for $pat in $expected
    let $res := $result[@koppelnummer eq $pat/@koppelnummer]
    return exists($res) 
        and count($pat//sbggz:Zorgtraject) eq count($res//sbggz:Zorgtraject) 
        and count($pat//sbggz:DBCtraject ) eq count($res//sbggz:DBCtraject)
        and count($pat//sbggz:DBCtraject[@einddatumDBC] ) eq count($res//sbggz:DBCtraject[@einddatumDBC])
        and count($pat//sbggz:Meting ) eq count($res//sbggz:Meting)
        and count($pat//sbggz:Meting[@typemeting eq '1'] ) eq count($res//sbggz:Meting[@typemeting eq '1'])
return count($expected) eq count($result) 
        and (every $v in $cmp satisfies $v eq true() )        
};

(: zorgtrajectnummers, dbc-trajectnummers en meting-datum verplicht :)
declare function local:gelijke-patient-atts($expected as element(), $result as element()? )
{
let $pat-equal := unit:atts-equal-ns($expected,$result)
let $zt-equal := every $z in 
                 for $zt in $expected//*[local-name() eq 'Zorgtraject']
                 let $zt-r := $result/*[local-name() eq 'Zorgtraject'][@sbggz:zorgtrajectnummer eq $zt/@sbggz:zorgtrajectnummer]
                 return if ( $zt-r ) 
                    then unit:atts-equal-ns($zt, $zt-r)
                    else  true()
                 satisfies $z eq true()

let $dbc-equal := every $d in 
                    for $dbc in $expected//*[local-name() eq 'DBCtraject']
                    let $dbc-r := $result//*[local-name() eq 'DBCtraject'][@sbggz:DBCTrajectnummer eq $dbc/@sbggz:DBCTrajectnummer]
                    return unit:atts-equal-ns($dbc, $dbc-r)
                   satisfies $d eq true()
let $meting-equal := every $m in 
                    for $mt in $expected//*[local-name() eq 'Meting']
                    let $mt-rs := $result//*[local-name() eq 'Meting']
                              
                    return if ( exists($mt-rs[@sbggz:datum eq $mt/@sbggz:datum]
                                        [@sbggz:gebruiktMeetinstrument eq $mt/@sbggz:gebruiktMeetinstrument]
                                        [@sbggz:typemeting eq $mt/@sbggz:typemeting]) ) 
                           then true() else false()
                    satisfies $m eq true()

return $pat-equal and $zt-equal and $dbc-equal and $meting-equal            
                
};



declare function local:test-filter-periode($tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $za := unit:get-object( $ctx, $test/setup/zorgaanbieder ),
        $pats := unit:get-objects-ns($ctx, $test/setup//sbggz:Patient ),
        $expected := unit:get-objects-ns($ctx, $test/expected//sbggz:Patient ),
               
        $result := sbgbm:filter-batchperiode( sbgza:batch-gegevens($za), $pats ),
        $pass := local:gelijke-patienten($expected,$result),
        $act := <box>{$result}</box>
        
return unit:build-test-result( $test, $pass, ($za, $pats), $act  )    
}; 

declare function local:test-filter-elts( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $def := $test/setup/def,
        $row := $test/setup/row,
        $expected := $test/expected/value,                
        
        $param := distinct-values( tokenize($def/text(), ', ')),
        
        $result := sbgem:vertaal-elt-naar-filter-sbg( $param, $row ),
        
        $act := element { 'value' } { $result },
        
        $pass :=  unit:atts-equal-ns( $expected, $act )
        
        return unit:build-test-result( $test, $pass, ($def, $row),  $act )    
    
};

declare function local:patient-sbg-meting( $tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $pat := $test/setup/sbgem:Patient,
        $zds := $ctx//zorgdomein,
        $expected := $test/expected/sbggz:Patient,                
               
        $result := sbge:patient-sbg-meting($pat, $zds),
        
        $pass :=  local:gelijke-patient-atts($expected,$result)
                
return unit:build-test-result( $test, $pass, ($pat, $zds), $result )    
};




(: dispatch functie :)
declare function local:run-tests($tests as element(tests)) as element(result)
{
<result>
{$tests/description}
{$tests/setup}{
let $ctx := $tests/setup,
    $zorgdomeinen := $ctx/sbg-zorgdomeinen,
    $instrumenten := sbgi:laad-instrumenten($ctx/instrument)

for $group in $test-doc//group
let $functie := $group/function/text(),
    $tests := $group//test
   
return <group>{$group/*[not(local-name()='test')]}
{ 

    if ( $functie = 'start-dispatch' ) then ()
    
    else if ( $functie = 'sbge:dbc-peildatums-zorgdomein' ) then local:test-dbc-peildatums( $tests, $ctx  )
    else if ( $functie = 'sbge:kandidaat-metingen' ) then local:test-kandidaat-metingen( $tests, $ctx  )
    else if ( $functie = 'sbge:maak-meetparen' ) then local:test-maak-meetparen( $tests, $ctx  )
    else if ( $functie = 'sbge:bepaal-zorgdomein' ) then local:test-bepaal-zorgdomein( $tests, $ctx  )
    else if ( $functie = 'sbge:patient-sbg-meting' ) then local:patient-sbg-meting( $tests, $ctx  )
    else if ( $functie = 'sbgem:vertaal-elt-naar-att-ns' ) then local:test-vertaal-elts( $tests, $ctx  )
    else if ( $functie = 'sbgem:vertaal-elt-naar-filter-sbg' ) then local:test-filter-elts( $tests, $ctx  )
    else if ( $functie = 'sbgbm:filter-sbg-dbc-in-periode' ) then local:test-filter-periode( $tests, $ctx  )
    else if ( $functie = 'sbgza:batch-gegevens' ) then local:test-batch-gegevens($tests, $ctx )
    else if ( $functie = 'sbgi:bereken-score' ) then local:test-bereken-score($tests, $ctx )
    else if ( $functie = 'sbgi:item-scores' ) then local:test-score-items($tests, $ctx )
    else if ( $functie = 'sbgi:honosca-sum' ) then local:test-honosca-sum($tests, $ctx )
    else if ( $functie = 'sbgm:sbg-metingen' ) then local:test-sbg-metingen($tests,$ctx)
    
    else if ( $functie = 'fall-through' ) then () else ()
     
}
</group>
}</result>
};

(: local:run-tests()//group[functie/text()="sbge:patient-dbc-meting"] :)

for $tests in $test-doc/tests
return local:run-tests($tests)