(: XQuery main module :)
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/sbg-bmimport.xquery';
import module namespace sbgem="http://sbg-synq.nl/epd-meting" at '../sbg-synq/epd-meting.xquery';
import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder"at '../sbg-synq/zorgaanbieder.xquery';
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


declare variable $test-doc := .; 

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

declare function local:get-object-ns($ctx, $elt as element()?) 
as element()?
{
let $deref := xs:boolean($elt/@ref) 
return 
if ( $deref  ) 
then   
   let $att := $elt/@*[local-name() ne 'ref'][1],
       $elt-name := name($elt),
       $att-name := name($att),
       $att-val :=  data($att)
    return $ctx//*[name() eq $elt-name][@*[name() eq $att-name][. eq $att-val]][1]
else 
    element { name($elt) }
             { $elt/@*,
              for $e in $elt/* return local:get-object-ns($ctx, $e) 
             }
};

declare function local:get-objects-ns($ctx, $elts as element()*) 
as element()*
{
for $o in $elts
return local:get-object-ns($ctx, $o)
};


(: vorm de test om naar het resultaat formaat :) 
declare function local:build-test-result( $test as element(test), $pass as xs:boolean, $setup as element()*, $actual as element()* ) 
as element(test)
{
let $act-elt := if ($pass) then () else 
    element { 'actual' } { for $elt in $actual return $elt } 
return 
element { 'test' } { $test/@* union attribute { 'pass' } { $pass }, 
  element {'setup' } { 
    for $elt in $setup 
    (: return element { local-name($elt) } { $elt/@*, $elt/text() } :)
    return $elt
  }
  union $test/description
  union $test/expected 
  union $act-elt 
  }     
};

(:
 ??
 test-compare-namespace.xq in home
:)
declare function local:atts-equal-ns( $exp as element(), $val as element() )
as xs:boolean
{
let $keys := for $n in $exp/@* return name($n)
let $atts-eq := for $k in $keys  
                let $att := $val/@*[name(.) eq $k]
                return $att and data($att) eq data($exp/@*[name(.) eq $k])

return 
    every $v in $atts-eq satisfies $v eq true()
};  


(: vergelijk de attribuut-waarden van $exp met de corresponderende in $val :)
declare function local:atts-equal( $exp as node(), $val as node()* )
as xs:boolean
{
let $atts-eq := 
    for $att in $exp/@*
    let $name := local-name($att)
    return data($val/@*[local-name() eq $name]) eq data($att)
return 
    every $v in $atts-eq satisfies $v eq true()
};  


declare function local:set-equal( $expected as node()*, $result as node()*, $key as xs:string )
as xs:boolean
{ 
let $len-eq := count($expected) eq count($result)
let $both-empty := not(exists($expected[1])) and not(exists($result[1])) 
let $pass-all :=  for $act in $result
                      let $id := data($act/@*[local-name() eq $key])
                      let $exp := $expected[@*[local-name() eq $key][. eq $id]]
 
                      return if ( $exp ) then local:atts-equal($exp,$act) else false() 
let $pass := every $v in $pass-all satisfies $v eq true()
return $len-eq and ($both-empty or $pass)
};


declare function local:ordered-set-equal( $expected as node()*, $result as node() * )
as xs:boolean*
{
let $len-eq := count($expected) eq count($result)
let $both-empty := not(exists($expected[1])) and not(exists($result[1])) 
let $pass-all :=  
    for $exp at $pos in $expected
    let $val := $result[$pos]
    return if ( $val ) then local:atts-equal( $exp, $val ) else false()
let $pass := every $v in $pass-all satisfies $v eq true()
return $len-eq and ($both-empty or $pass)
};

declare function local:sub1-equal( $expected as node(), $result as node() )
as xs:boolean
{
let $sub1-eq := for $elt in $expected/*
                let $val := $result/*[local-name() eq local-name($elt)]
                return local:data-equal($elt, $val) 
return (every $v in $sub1-eq satisfies $v eq true())
};

(: dont reimplement deepequal ? :)
declare function local:data-equal( $expected as node(), $result as node() )
as xs:boolean
{
let $atts-eq := local:atts-equal-ns($expected,$result),
    $data-eq := data($expected) eq data($result)
return $atts-eq and $data-eq      
};


(: ---------- group functies ------------------------ :)

declare function local:test-dbc-peildatums( $tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
for $test in $tests
let $dbc := local:get-object-ns($ctx, $test/setup/sbgem:DBCTraject[1]),
    $zorgdomein := local:get-object($ctx, $test/setup/zorgdomein[1]),
                        
    $expected := $test/expected/value/text(),
        
    $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ), 
    
    $test-string := concat( string($peildatums[1]), ', ', string($peildatums[2])),
    $pass := $expected eq $test-string,
    $actual :=  <value>{$test-string}</value>
    return local:build-test-result( $test, $pass, ($dbc, $zorgdomein), $actual )
};

declare function local:test-kandidaat-metingen($tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
(: setup bevat 1 dbc, 1 zorgdomein en N metingen :)
for $test in $tests
    let $dbc := local:get-object-ns($ctx, $test/setup/sbgem:DBCTraject),
        $zorgdomein := local:get-object($ctx, $test/setup/zorgdomein),
        $metingen := for $ref in $test/setup/Meting
                     return local:get-object($ctx, $ref),
                        
        $expected := $test/expected/kandidaat-metingen,
        
        $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ),
        $result := sbge:kandidaat-metingen( $metingen, $zorgdomein, $peildatums ),
        
        $pass :=  local:ordered-set-equal( $expected/voor/*, $result/voor/*)
                  and local:ordered-set-equal( $expected/na/*, $result/na/*)
        
    return local:build-test-result( $test, $pass, ($dbc, $zorgdomein, $metingen),  $result )
};

declare function local:test-bepaal-zorgdomein($tests as element(test)*, $ctx as element() ) 
as element(test)* 
{
(: setup bevat 1 zorgtraject en N metingen :)
for $test in $tests
    let $zt := $test/setup/sbgem:Zorgtraject,
        $metingen := for $ref in $test/setup/Meting
                     return local:get-object($ctx, $ref),
                        
        $expected := $test/expected/value,
        $result := sbge:bepaal-zorgdomein( $zt, $metingen ),
        
        $pass :=  $expected/text() eq $result
        
    return local:build-test-result( $test, $pass, ($zt, $metingen),  <value>{$result}</value> )
};

declare function local:test-maak-meetparen( $tests as element(test)*, $ctx as element() )
as element(test)*
{
(: setup bevat 1 dbc, 1 zorgdomein en N metingen :)
for $test in $tests
    let $dbc := local:get-object-ns($ctx, $test/setup/sbgem:DBCTraject),
        $zorgdomein := local:get-object($ctx, $test/setup/zorgdomein),
        $metingen := for $ref in $test/setup/Meting
                     return local:get-object($ctx, $ref),
                        
        $expected := $test/expected/meetparen,
        
        $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein ),
        $kandidaten := sbge:kandidaat-metingen( $metingen, $zorgdomein, $peildatums ),
        $result := sbge:optimale-meetpaar( $kandidaten, $zorgdomein ),
        
        $pass :=  local:set-equal( $expected//Meting, $result//Meting, 'meting-id')
        
    return local:build-test-result( $test, $pass, ($dbc, $zorgdomein, $metingen),  $result )
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
        
        $pass :=  local:atts-equal-ns( $expected, $act )
        
        return local:build-test-result( $test, $pass, ($def, $row),  $act )    
    
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
        
return local:build-test-result( $test, false(), ($def, $row),  <box pass="{$pass}">{$act}</box> )    
};
:)

declare function local:test-batch-gegevens($tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $za := local:get-object( $ctx, $test/setup/zorgaanbieder ),
        $expected := $test/expected/*[1],
               
        $result := sbgza:batch-gegevens($za),
        $pass :=  local:atts-equal($expected,$result)
        
return local:build-test-result( $test, $pass, ($za), $result  )    
}; 

(: doe tellingen op de sub-elementen in de hoop dat de juiste ontbreken :)
declare function local:gelijke-patienten($expected as element(sbggz:Patient)*, $result as element(sbggz:Patient)* )
{
let $cmp := for $pat in $expected
    let $res := $result[@koppelnummer eq $pat/@koppelnummer]
    return exists($res) 
        and count($pat//sbggz:Zorgtraject) eq count($res//sbggz:Zorgtraject) 
        and count($pat//DBCtraject ) eq count($res//DBCtraject)
        and count($pat//DBCtraject[@einddatumDBC] ) eq count($res//DBCtraject[@einddatumDBC])
        and count($pat//Meting ) eq count($res//Meting)
        and count($pat//Meting[@typemeting eq '1'] ) eq count($res//Meting[@typemeting eq '1'])
return count($expected) eq count($result) 
        and (every $v in $cmp satisfies $v eq true() )        
};

declare function local:test-filter-periode($tests as element(test)*, $ctx as element() )
as element(test)*
{
for $test in $tests
    let $za := local:get-object( $ctx, $test/setup/zorgaanbieder ),
        $pats := local:get-objects-ns($ctx, $test/setup//sbggz:Patient ),
        $expected := local:get-objects-ns($ctx, $test/expected//sbggz:Patient ),
               
        $result := sbgbm:filter-batchperiode( sbgza:batch-gegevens($za), $pats ),
        $pass := local:gelijke-patienten($expected,$result),
        $act := <box>{$result}</box>
        
return local:build-test-result( $test, $pass, ($za, $pats), $act  )    
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
        
        $pass :=  local:atts-equal-ns( $expected, $act )
        
        return local:build-test-result( $test, $pass, ($def, $row),  $act )    
    
};


(: dispatch functie :)
declare function local:run-tests($tests as element(tests)) as element(result)
{
<result>
{$tests/description}
{$tests/setup}{
let $ctx := $tests/setup,
    $zorgdomeinen := $ctx/sbg-zorgdomeinen,
    $instrumenten := sbgi:laad-instrumenten($ctx/sbg-instrumenten)

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
    else if ( $functie = 'sbgem:vertaal-elt-naar-att-ns' ) then local:test-vertaal-elts( $tests, $ctx  )
    else if ( $functie = 'sbgem:vertaal-elt-naar-filter-sbg' ) then local:test-filter-elts( $tests, $ctx  )
    else if ( $functie = 'sbgbm:filter-sbg-dbc-in-periode' ) then local:test-filter-periode( $tests, $ctx  )
    else if ( $functie = 'sbgza:batch-gegevens' ) then local:test-batch-gegevens($tests, $ctx )
     
    else if ( $functie = 'fall-through' ) then () else ()
     
}
</group>
}</result>
};

(: local:run-tests()//group[functie/text()="sbge:patient-dbc-meting"] :)

for $tests in $test-doc/tests
return local:run-tests($tests)