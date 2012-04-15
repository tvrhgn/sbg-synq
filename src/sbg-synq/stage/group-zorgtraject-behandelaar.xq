(:

groepeer behandelaar per zorgtraject
:)



let $behs := .//behandelaar
let $zorgtrajecten := distinct-values( $behs/@zorgtrajectnummer )

return <behandelaar-doc>{
for $zt in $zorgtrajecten
let $beh := $behs[@zorgtrajectnummer eq $zt]
order by $zt
return <zorgtraject zorgtrajectnummer="{$zt}">{
  for $b in $beh
  return <behandelaar>{$b/@*[local-name() ne 'zorgtrajectnummer']}</behandelaar>

}</zorgtraject>
}</behandelaar-doc>