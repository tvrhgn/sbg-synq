(:


declare variable $meting-doc as xs:string external;
declare variable $item-doc as xs:string external;

for $mt in doc($meting-doc)//Row
let $mi := doc($item-doc)//Row[meting-id/text() eq $mt/meting-id/text()]

:)


declare function local:elt-filter-atts( $elt as element(), $atts as xs:string* )
{
  element { name($elt) }
  { $elt/@*[not(index-of( local-name(), $atts) gt 0)],
  $elt/text()
}
};

declare function local:build-atts( $row as element() ) as attribute()* {
  for $elt in $row/*
  return attribute { local-name($elt) } { data($elt) }
};

declare function local:build-Item( $mi-row as element() ) as element(Item) {
  element { 'Item' } { local:build-atts( $mi-row ) }
};

declare function local:build-Meting( $m-row as element(), $items as element()* ) as element(Meting) {
  let $atts := local:build-atts( $m-row )
  return 
    element { 'Meting' } 
    { $atts,  $items
    }
};


let $ctx := .

return 
<meting-doc>{
for $mt in $ctx//Row
let $mi := $ctx//meting[data(@meting-id) eq data($mt/meting-id)]
return local:build-Meting( $mt, $mi )
}</meting-doc>