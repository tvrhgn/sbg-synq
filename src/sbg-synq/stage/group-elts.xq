(:
data staat al in attributen
groepeer elts per key-att; voeg container-elt in (wrap elts in container-elt)

dit is nuttig om het aantal lookups te verminderen?
de set met de keys is nu een stuk kleiner, met name als het aantal elementen relatief groot is, 
zoals bij meting-item (ongeveer 40 per metinng)

:)
declare variable $key as xs:string external;
declare variable $container-elt as xs:string external;

(: select leaves :)
let $elts := .//*[not(*)]

let $group-keys := distinct-values( $elts/@*[local-name() eq $key] )
let $name := local-name( $elts[1] )

return element { concat( $name, '-doc')  } {
for $k in $group-keys
let $elt := $elts[@*[local-name() eq $key][data(.) eq $k]]
return 
  element { $container-elt } {
    attribute { $key } { $k },
    for $e in $elt
    return 
      element { $name } {
	$e/@*[not(local-name() eq $key)]
      }
  }
}
