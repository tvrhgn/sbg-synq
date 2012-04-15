(:

groepeer nevendiagnose per zorgtraject
:)



let $diags := .//nevendiagnose
let $zorgtrajecten := distinct-values( $diags/@zorgtrajectnummer )

return <nevendiagnose-doc>{
for $zt in $zorgtrajecten
let $diag := $diags[@zorgtrajectnummer eq $zt]
order by $zt
return <zorgtraject zorgtrajectnummer="{$zt}">{
  for $nd in $diag
  return <nevendiagnose>{$nd/@*[local-name() ne 'zorgtrajectnummer']}</nevendiagnose>

}</zorgtraject>
}</nevendiagnose-doc>