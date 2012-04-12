import module namespace stg = 'http://sbg-synq.nl/stage' at 'stage-row-elt.xquery';
(:

groepeer behandelaar per zorgtraject
:)


(: select rows :)
let $nds := ./*[1]/*
let $zorgtrajecten := distinct-values( $nds/zorgtrajectnummer )

return <nevendiagnose-doc>{
for $zt in $zorgtrajecten
let $nd := $nds[zorgtrajectnummer eq $zt]
return <zorgtraject zorgtrajectnummer="{$zt}">{
  for $b in $nd
  return <NevendiagnoseCode>{stg:build-atts-filter($b, ('zorgtrajectnummer'))}</NevendiagnoseCode>

}</zorgtraject>
}</nevendiagnose-doc>