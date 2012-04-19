(:

groepeer metingen per client
strip de items?
:)


let $metingen := .//meting
let $patienten := distinct-values( $metingen/@koppelnummer )

return <meting-doc>{
for $pat in $patienten
let $meting := $metingen[@koppelnummer eq $pat]
order by $pat
return <patient koppelnummer="{$pat}">{
    for $m in $meting
    return element { 'meting' } { $m/@*[local-name() ne 'koppelnummer'], $m/* } 
}</patient>
}</meting-doc>
