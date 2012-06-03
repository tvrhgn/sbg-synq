module namespace unit = 'http://sbg-synq.nl/unit-test';

(: dit is nodig om elementen te kunnen aanmaken met name() :)
declare namespace sbge="http://sbg-synq.nl/sbg-epd";
declare namespace sbgi="http://sbg-synq.nl/sbg-instrument";
declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace sbgbm="http://sbg-synq.nl/sbg-benchmark";
declare namespace sbgem="http://sbg-synq.nl/epd-meting";
declare namespace sbggz="http://sbggz.nl/schema/import/5.0.1";

(: filter atts of elts van de verkregen waarde ($actual) op basis van $expected:)
(: expected in de setup wordt daarmee een sjabloon voor weergave :)
declare function unit:filter-atts( $nd as node(), $tpl as node() )
as node()*{
for $att in $tpl/@*
return $nd/@*[local-name() eq local-name($att)]
};

declare function unit:filter-elts( $nd as node(), $tpl as node() )
as node()* {
for $elt in $tpl/*
return $nd/*[local-name() eq local-name($elt)]
};

declare function unit:transfer-atts($elts as element()* ) as element()*
{
for $elt in $elts
return element { local-name($elt) } { (),
    for $att in $elt/@*
    return element { local-name($att) } { data($att) }
    }
};

(: zoek object op in globale context op basis van ref-name en ref-value op het element :)
declare function unit:get-ref-object( $ctx, $ref as element() )
as element()
{
let $class := local-name($ref)
let $att-name := data($ref/@ref-name)
let $att-val :=  data($ref/@ref-value)
return $ctx//*[local-name() eq $class][@*[local-name() eq $att-name][. eq $att-val]][1]
};

(: deref 1 attribuut als @ref eq true :)
declare function unit:get-object($ctx, $elt as element()?) 
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

declare function unit:get-object-ns($ctx, $elt as element()?) 
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
              for $e in $elt/* return unit:get-object-ns($ctx, $e) 
             }
};

declare function unit:get-objects-ns($ctx, $elts as element()*) 
as element()*
{
for $o in $elts
return unit:get-object-ns($ctx, $o)
};


(: vorm de test om naar het resultaat formaat :) 
declare function unit:build-test-result( $test as element(test), $pass as xs:boolean, $setup as element()*, $actual as element()* ) 
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
declare function unit:atts-equal-ns( $exp as element(), $val as element() )
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
declare function unit:atts-equal( $exp as node(), $val as node()* )
as xs:boolean
{
let $atts-eq := 
    for $att in $exp/@*
    let $name := local-name($att)
    return data($val/@*[local-name() eq $name]) eq data($att)
return 
    every $v in $atts-eq satisfies $v eq true()
};  


declare function unit:set-equal( $expected as node()*, $result as node()*, $key as xs:string )
as xs:boolean
{ 
let $len-eq := count($expected) eq count($result)
let $both-empty := not(exists($expected[1])) and not(exists($result[1])) 
let $pass-all :=  for $act in $result
                      let $id := data($act/@*[local-name() eq $key])
                      let $exp := $expected[@*[local-name() eq $key][. eq $id]]
 
                      return if ( $exp ) then unit:atts-equal($exp,$act) else false() 
let $pass := every $v in $pass-all satisfies $v eq true()
return $len-eq and ($both-empty or $pass)
};


(: hulp-functie om de handmatig gewijzigde itemstrings te normalizeren :)
declare function unit:numbers-string( $numbers-str as xs:string? ) 
as xs:string*
{
for $s in fn:tokenize(normalize-space($numbers-str), ' ?,') 
return replace($s, "\s", "")
};

declare function unit:double-seq( $numbers-str as xs:string? )
as xs:double*
{
for $v in unit:numbers-string($numbers-str)
return if ( $v castable as xs:double ) then xs:double($v) else -100001
};

declare function unit:set-equal-atomic( $expected as xs:anyAtomicType*, $result as xs:anyAtomicType* )
as xs:boolean
{ 
let $len-eq := count($expected) eq count($result)
let $both-empty := not(exists($expected[1])) and not(exists($result[1])) 
let $pass-all :=  for $act in $result
                  return exists(index-of( $expected, $act ))
let $pass := every $v in $pass-all satisfies $v eq true()
return $len-eq and ($both-empty or $pass)
};




declare function unit:ordered-set-equal( $expected as node()*, $result as node() * )
as xs:boolean*
{
let $len-eq := count($expected) eq count($result)
let $both-empty := not(exists($expected[1])) and not(exists($result[1])) 
let $pass-all :=  
    for $exp at $pos in $expected
    let $val := $result[$pos]
    return if ( $val ) then unit:atts-equal( $exp, $val ) else false()
let $pass := every $v in $pass-all satisfies $v eq true()
return $len-eq and ($both-empty or $pass)
};

declare function unit:sub1-equal( $expected as node(), $result as node() )
as xs:boolean
{
let $sub1-eq := for $elt in $expected/*
                let $val := $result/*[local-name() eq local-name($elt)]
                return unit:data-equal($elt, $val) 
return (every $v in $sub1-eq satisfies $v eq true())
};

(: deep-equal niet bruikbaar :)
declare function unit:data-equal( $expected as node(), $result as node() )
as xs:boolean
{
let $atts-eq := unit:atts-equal-ns($expected,$result),
    $data-eq := data($expected) eq data($result)
return $atts-eq and $data-eq      
};


