(: XQuery main module :)
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/sbg-bmimport.xquery';
(: declare variable $test-doc := doc( '../sbg-testdata/unit-tests.xml')/*; :)

(: declare variable $test-doc as element()* external; 
declare variable $test-doc := /*;
:)

 declare variable $test-doc := doc( 'unit-tests.xml')/*;

(: filter atts of elts van de verkregen waarde ($actual) op basis van $expected:)
(: expected in de setup wordt daarmee een sjabloon voor weergave :)
declare function local:filter-atts( $nd as node(), $tpl as node() )
as node()*{
for $att in $tpl/@*
return $nd/@*[local-name() = local-name($att)]
};

declare function local:filter-elts( $nd as node(), $tpl as node() )
as node()* {
for $elt in $tpl/*
return $nd/*[local-name() = local-name($elt)]
};

declare function local:transfer-atts($elts as element()* ) as element()*
{
for $elt in $elts
return element { local-name($elt) } { (),
    for $att in $elt/@*
    return element { local-name($att) } { data($att) }
    }
};


(: run de sbge:selecteer-domein() test :)
(: maakt gebruik van globale setup $zorgdomeinen :)
declare function local:test-selecteer-zorgdomein($tests as element(test)*, $zorgdomeinen as element(sbg-zorgdomeinen) ) as element(test)* {
    for $test in $tests
    let $dbc := $test/setup/dbc,
        $expected := $test/expected/*,
        
        $zd := sbge:selecteer-domein( $dbc, $zorgdomeinen ),
        
        $pass := every $att in $expected/@*  satisfies contains( $zd/@*, $att )  and local-name($zd) = local-name($expected),
        $actual := element { local-name($zd) } { local:filter-atts( $zd, $expected ), local:filter-elts( $zd, $expected ) },
        $actual-elt := if ( $pass ) then () else element { 'actual' } { $actual, () }  
    return element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, $test/* union $actual-elt }     
};

declare function local:test-bereken-score( $tests, $instrumenten ) as element(test)* {
    for $test in $tests
    let $meting := $test/setup/meting,
        $expected := xs:double($test/expected/value/text()),
        $instr := $instrumenten[@code=data($meting/@instrument)][1],
        
        $score := sbgi:bereken-totaalscore-sbg( $instr, $meting/item ),
        
        $pass := $score = $expected,
        $actual-elt := if ( $pass ) then () else element { 'actual' } { <value>{$score}</value> }  
    return element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, $test/* union $actual-elt }     

};
declare function local:test-koppelproces($tests as element(test)*, $zorgdomeinen as element(sbg-zorgdomeinen) ) as element(test)* {
    for $test in $tests
    let $dbc := local:transfer-atts($test/setup/dbc),
        $metingen := $test/setup//Meting,
        $expected := $test/expected//Meting,
        
        $dbc-meting := sbge:patient-dbc-meting( $dbc, $metingen, $zorgdomeinen  )//Meting,
        
        $pass-all :=  for $act in $dbc-meting
                      let $exp := $expected[data(@sbgm:meting-id) = data($act/@sbgm:meting-id)]
                      return every $att in $exp/@*  satisfies data($act/@*[local-name() = local-name($att)]) = data($att) 
                  ,
         (: TODO werkt als er geen expected is
         (nilled($expected[1]) and nilled($dbc-meting[1])) or ($pass-all, false())[1],
          :)
        $pass := (not(exists($expected[1])) and not(exists($dbc-meting[1]))) or ($pass-all, false())[1],                   
                  
        $actual := for $act in $dbc-meting
                   return element { local-name($act) } { local:filter-atts( $act, $expected[1] ), local:filter-elts( $act, $expected[1] ) },
        $actual-elt := if ( $pass ) then () else element { 'actual' } { $actual }    
        (: $actual-elt := <actual>{$dbc-meting}</actual> :)
    return element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, $test/*, $actual-elt }     
};

declare function local:test-filter-periode( $group as element(group)* ) as element(test)* {
let $batch := $group/setup/batch-gegevens
for $test in $group//test
    (: we testen een filter, dus input en output hebben hetzelfde type :)
    let $patient := $test/setup/Patient,
        $expected := $test/expected/Patient,
        
        $actual := sbgbm:filter-batchperiode( $batch, $patient ),
        
        $pass := (exists($actual) and exists($expected)) or (not(exists($actual)) and not(exists($expected))),                      
                  
        $actual-elt := if ( $pass ) then () else element { 'actual' } { $actual }    
    return element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, $test/*, $actual-elt }
};

declare function local:run-tests() as element(result)
{
<result>{$test-doc/setup}{
let $zorgdomeinen := $test-doc/setup/sbg-zorgdomeinen,
    $instrumenten := sbgi:laad-instrumenten($test-doc/setup/sbg-instrumenten)
for $group in $test-doc//group
let $functie := $group/functie/text(),
    $tests := $group//test
   
return <group>{$group/*[not(local-name()='test')]}
{ 

    if ( $functie = 'sbge:selecteer-domein' ) then local:test-selecteer-zorgdomein( $tests, $zorgdomeinen )
    else if ( $functie = 'sbgi:bereken-totaalscore-sbg' ) then local:test-bereken-score( $tests, $instrumenten )
    else if ( $functie = 'sbge:patient-dbc-meting' ) then local:test-koppelproces( $tests, $zorgdomeinen  )
    else if ( $functie = 'sbgbm:filter-batchperiode' ) then local:test-filter-periode( $group  )
     
    else if ( $functie = 'fall-through' ) then () else ()
     
}
</group>
}</result>
};

(: local:run-tests()//group[functie/text()="sbge:patient-dbc-meting"] :)

local:run-tests()