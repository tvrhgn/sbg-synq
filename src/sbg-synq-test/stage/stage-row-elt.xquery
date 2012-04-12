module namespace stg = 'http://sbg-synq.nl/stage';

(:

maak sbg-synq stage-formaat in de default ns op basis van rij-xml in Row
- draag de elementen over naar attributen
- maak groepen voor de meervoudige elementen

:)


(: draag alleen het eerste element met naam over :)
declare function stg:build-atts-dups( $row as element() ) as attribute()* {
let $nms := for $elt in $row/* return local-name($elt)
  for $nm in distinct-values( $nms ) 
  return attribute { $nm } { data($row/*[local-name() eq $nm][1]) }
};

(: het idee... :)
declare function stg:build-atts( $row as element() ) as attribute()* {
  for $elt in $row/*
  return attribute { local-name($elt) } { data($elt) }
};

(: filter 1 of meer elementen :)
declare function stg:build-atts-filter( $row as element(), $atts as xs:string* )
as attribute()* 
{
  for $elt in $row/*[not(exists(index-of( $atts, local-name())))]
  return attribute { local-name($elt) } { data($elt) }
};

(: selecteer 1 of meer elementen :)
declare function stg:build-atts-only( $row as element(), $atts as xs:string* )
as attribute()* 
{
  for $elt in $row/*[exists(index-of( $atts, local-name()))]
  return attribute { local-name($elt) } { data($elt) }
};
