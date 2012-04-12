
(:

maak sbg-elementen in de default ns op basis van rij-xml in Row
- draag de elementen over naar attributen
- maak groepen voor de meervoudige elementen

declare variable $item-doc as xs:string external;
let $items := doc($item-doc)//Row
:)



declare function local:build-atts-dups( $row as element() ) as attribute()* {
let $nms := for $elt in $row/* return local-name($elt)
  for $nm in distinct-values( $nms ) 
  return attribute { $nm } { data($row/*[local-name() eq $nm][1]) }
};


declare function local:build-atts( $row as element() ) as attribute()* {
  for $elt in $row/*
  return attribute { local-name($elt) } { data($elt) }
};


declare function local:build-atts-filter( $row as element(), $atts as xs:string* )
as attribute()* 
{
  for $elt in $row/*[not(index-of( local-name(), $atts) gt 0)]
  return attribute { local-name($elt) } { data($elt) }
};

declare function local:build-atts-only( $row as element(), $atts as xs:string* )
as attribute()* 
{
  for $elt in $row/*[exists(index-of( $atts, local-name()))]
  return attribute { local-name($elt) } { data($elt) }
};


let $items := .//Row


return <item-doc>{
let $meting-ids := distinct-values( $items/meting-id )
for $id in $meting-ids
let $its := $items[meting-id eq $id]
return <meting meting-id="{$id}">{
  for $it in $its
  return <item>{local:build-atts-only($it, ('itemnummer', 'score'))}</item>

}</meting>
}</item-doc>