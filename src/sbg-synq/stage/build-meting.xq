
declare function local:build-Meting( $meting as element(meting), $items as element(item)* ) 
as element(meting) 
{
element { 'meting' } 
    { $meting/@*,  $items 
    }
};

declare function local:build-Metingen( $metingen as element(meting-doc), $items as element(item-doc) ) as element(meting)*
{
for $meting in $metingen/meting
let $id := $meting/@meting-id,
    $its := $items/meting[@meting-id eq $id]/item
return local:build-Meting( $meting, $its )
};


<meting-doc>{
let $metingen := .//meting-doc
let $items := .//item-doc
return local:build-Metingen( $metingen, $items )
}</meting-doc>