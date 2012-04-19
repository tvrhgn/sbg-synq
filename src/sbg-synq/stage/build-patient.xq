(: 
normaliseer epd-rijen naar patient- / zorgtraject- / dbctraject -doc 

invoer is patient-att

:)

declare variable $patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandPatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');
declare variable $zorgtraject-atts := ('zorgtrajectnummer', 'locatiecode', 'primaireDiagnoseCode', 'GAFscore', zorgdomeinCode);


let $pats := .//patient[not(*)]
let $behs := .//zorgtraject[behandelaar]
let $nevendiagnoses := .//zorgtraject[nevendiagnose]
let $metingen := .//patient[meting]

let $koppelnrs := distinct-values( $pats/@koppelnummer )
return <patient-doc>{

for $nr in $koppelnrs
let $dbcs := $pats[@koppelnummer eq $nr]
(: selecteer de laatste voor de meest up to date gegevens ?? :)
let $pat := $dbcs[count($dbcs)] 
let $ztnrs := distinct-values( $dbcs/@zorgtrajectnummer )
let $meting := $metingen[@koppelnummer eq $nr]/meting


return 
  element { 'patient' } {  
    $pat/@*[exists(index-of( $patient-atts, local-name()))]  ,
  ($meting,
  for $ztnr in $ztnrs
  let $zts := $dbcs[@zorgtrajectnummer eq $ztnr],
    $beh := $behs[@zorgtrajectnummer eq $ztnr]/behandelaar,
    $nevend := $nevendiagnoses[@zorgtrajectnummer eq $ztnr]/nevendiagnose
    
  return 
    element { 'zorgtraject' }
    { 
    ( $zts[1]/@*[exists(index-of( $zorgtraject-atts, local-name()))] ,
    $beh, $nevend,
    let $dbcnrs := distinct-values( $zts/@DBCTrajectnummer )
    for $nr in $dbcnrs
    let $dbc := $zts[@DBCTrajectnummer eq $nr]
    return 
      element { 'dbctraject' }
      { $dbc/@*[not(exists(index-of( ($patient-atts, $zorgtraject-atts), local-name())))]  }
    )
    }
  )}
}</patient-doc>