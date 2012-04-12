import module namespace stg = 'http://sbg-synq.nl/stage' at 'stage-row-elt.xquery';
(:

groepeer behandelaar per zorgtraject
:)



let $behs := ./*[1]/*
let $zorgtrajecten := distinct-values( $behs/zorgtrajectnummer )

return <behandelaar-doc>{
for $zt in $zorgtrajecten
let $beh := $behs[zorgtrajectnummer eq $zt]
return <zorgtraject zorgtrajectnummer="{$zt}">{
  for $b in $beh
  return <Behandelaar>{stg:build-atts-filter($b, ('zorgtrajectnummer'))}</Behandelaar>

}</zorgtraject>
}</behandelaar-doc>