(: XQuery main module :)
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/sbg-bmimport.xquery';
import module namespace sbgem="http://sbg-synq.nl/epd-meting" at '../sbg-synq/epd-meting.xquery';
(: declare variable $test-doc := doc( '../sbg-testdata/unit-tests.xml')/*; :)

(: declare variable $test-doc as element()* external; 
declare variable $test-doc := doc( 'unit-tests.xml')/*;
:)

declare variable $test-doc := /*; 

(: filter atts of elts van de verkregen waarde ($actual) op basis van $expected:)
(: expected in de setup wordt daarmee een sjabloon voor weergave :)
declare function local:filter-atts( $nd as node(), $tpl as node() )
as node()*{
for $att in $tpl/@*
return $nd/@*[local-name() eq local-name($att)]
};

declare function local:filter-elts( $nd as node(), $tpl as node() )
as node()* {
for $elt in $tpl/*
return $nd/*[local-name() eq local-name($elt)]
};

declare function local:transfer-atts($elts as element()* ) as element()*
{
for $elt in $elts
return element { local-name($elt) } { (),
    for $att in $elt/@*
    return element { local-name($att) } { data($att) }
    }
};

(: zoek object op in globale context op basis van ref-name en ref-value op het element :)
declare function local:get-ref-object( $ctx, $ref as element() )
as element()
{
let $class := local-name($ref)
let $att-name := data($ref/@ref-name)
let $att-val :=  data($ref/@ref-value)
return $ctx//*[local-name() eq $class][@*[local-name() eq $att-name][. eq $att-val]][1]
};

declare function local:xget-object($ctx, $elt-name as xs:string, $att as attribute()) 
as element()?
{
let $att-name := local-name($att)
let $att-val :=  data($att)
return $ctx//*[local-name() eq $elt-name][@*[local-name() eq $att-name][. eq $att-val]][1]
};

(: deref 1 attribuut als @ref eq true :)
declare function local:get-object($ctx, $elt as element()?) 
as element()?
{
let $deref := xs:boolean($elt/@ref) 
return if ( $deref  ) then  
let $att := $elt/@*[local-name() ne 'ref'][1]
let $elt-name := local-name($elt)
let $att-name := local-name($att)
let $att-val :=  data($att)
return $ctx//*[local-name() eq $elt-name][@*[local-name() eq $att-name][. eq $att-val]][1]
else $elt
};

declare function local:build-test-result( $test as element(test), $pass as xs:boolean, $setup as element()*, $actual as element()? ) 
as element(test)
{
let $act-elt := if ($pass) then () else element { 'actual' } { $actual } 
return 
element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, 
  element {'setup' } { 
    for $elt in $setup 
    return element { local-name($elt) } { $elt/@* }
  }
  union $test/expected 
  union $act-elt 
  }     
};

declare function local:test-dbc-peildatums( $tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
for $test in $tests
let $dbc := local:get-object($ctx, $test/setup/DBCTraject[1]),
    $zorgdomein := local:get-object($ctx, $test/setup/zorgdomein[1]),
                        
    $expected := $test/expected/value/text(),
        
    $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ),
    
    $test-string := concat( string($peildatums[1]), ', ', string($peildatums[2])),
    $pass := $expected eq $test-string,
    $actual :=  <value>{$test-string}</value>
    return local:build-test-result( $test, $pass, ($dbc, $zorgdomein), $actual )
};



(: run de sbge:selecteer-domein() test :)
(: maakt gebruik van globale setup $zorgdomeinen :)
declare function local:test-selecteer-zorgdomein($tests as element(test)*, $zorgdomeinen as element(sbg-zorgdomeinen) ) as element(test)* {
    for $test in $tests
    let $dbc := $test/setup/dbc,
        $expected := $test/expected/*,
        
        $zd := sbgem:selecteer-domein( $dbc, $zorgdomeinen ),
        
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
        
        $patient-meting := sbgem:patient-meting-epd( $dbc, $metingen, $zorgdomeinen ),
        $dbc-meting := sbge:patient-dbc-meting( $patient-meting, $zorgdomeinen  )//Meting,
        
        $pass-all :=  for $act in $dbc-meting
                      let $exp := $expected[data(@sbgm:meting-id) eq data($act/@sbgm:meting-id)]
                      return $exp and (every $att in $exp/@*  satisfies data($act/@*[local-name() eq local-name($att)]) eq data($att)) 
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


declare function local:test-koppelproces-zorgdomein($tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
let $zorgdomeinen := $ctx//sbg-zorgdomeinen/*
let $dbcs := $ctx//epd/dbc
let $rom := $ctx//rom/Meting 
(: verwacht 1 dbc en meer metingen :)
for $test in $tests
    let $dbc := local:transfer-atts($test/setup/dbc),
        $metingen := for $ref in $test/setup//Meting
                     return local:get-ref-object($ctx, $ref),
                        
        $expected := local:get-ref-object($ctx,$test/expected//Meting),
        
        $patient-meting := sbgem:patient-meting-epd( $dbc, $metingen, $zorgdomeinen ),
        $dbc-meting := sbge:patient-dbc-meting( $patient-meting, $zorgdomeinen  )//Meting,
        
        $pass-all :=  for $act in $dbc-meting
                      let $exp := $expected[data(@sbgm:meting-id) eq data($act/@sbgm:meting-id)]
                      return $exp and (every $att in $exp/@*  satisfies data($act/@*[local-name() eq local-name($att)]) eq data($att)) 
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
        
        $check-result := every $pat in $expected satisfies index-of( $actual/@koppelnummer, $pat/@koppelnummer), 
        $pass := (count($actual) eq count($expected) and $check-result),                 
        
        $actual-elt := if ( $pass ) then () else element { 'actual' } { $actual }    
    return element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, $test/*, $actual-elt }
};

declare function local:run-tests() as element(result)
{
<result>{$test-doc/setup}{
let $ctx := $test-doc/setup,
    $zorgdomeinen := $test-doc/setup/sbg-zorgdomeinen,
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
    else if ( $functie = 'sbge:dbc-peildatums-zorgdomein' ) then local:test-dbc-peildatums( $tests, $ctx  )
    
     
    else if ( $functie = 'fall-through' ) then () else ()
     
}
</group>
}</result>
};

(: local:run-tests()//group[functie/text()="sbge:patient-dbc-meting"] :)

local:run-tests()