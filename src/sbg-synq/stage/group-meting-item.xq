let $items := .//item
let $metingen := distinct-values( $items/@meting-id )

return <item-doc>{
for $zt in $metingen
let $item := $items[@meting-id eq $zt]
order by $zt
return <meting meting-id="{$zt}">{
  for $it in $item
  return <item>{$it/@*[local-name() ne 'meting-id']}</item>

}</meting>
}</item-doc>