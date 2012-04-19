
declare function local:build-meting( $meting as element(meting), $items as element(item)* ) 
as element(meting) 
{
element { 'meting' } 
    { $meting/@*,  $items 
    }
};

declare function local:build-metingen( $metingen as element(meting-doc), $items as element(item-doc) ) as element(meting)*
{
for $meting in $metingen/meting
let $id := $meting/@meting-id,
    $its := $items/meting[@meting-id eq $id]/item
return local:build-meting( $meting, $its )
};


<meting-doc>{
let $metingen := .//meting-doc
let $items := .//item-doc
return local:build-metingen( $metingen, $items )
}</meting-doc>