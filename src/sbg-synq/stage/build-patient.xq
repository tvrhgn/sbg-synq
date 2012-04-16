(: 
normaliseer epd-rijen naar patient- / zorgtraject- / dbctraject -doc 

invoer is patient-att

:)

declare variable $patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandPatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');
declare variable $zorgtraject-atts := ('zorgtrajectnummer', 'locatiecode', 'primaireDiagnoseCode', 'GAFscore', zorgdomeinCode);


let $pats := .//patient
let $behs := .//*[behandelaar]
let $nevendiagnoses := .//*[nevendiagnose]
let $metingen := .//*[meting]

let $koppelnrs := distinct-values( $pats/@koppelnummer )
return <patient-doc>{
for $nr in $koppelnrs
let $pat := $pats[@koppelnummer eq $nr]
(: selecteer de laatste voor de meest up to date gegevens ?  -1 ?? :)
let $p := $pat[count($pat) - 1] 
let $ztnrs := distinct-values( $pat/@zorgtrajectnummer )
let $meting := $metingen[@koppelnummer eq $nr]/meting
return 
  element { 'patient' } 
  {  
  $p/@*[exists(index-of( $patient-atts, local-name()))]   ,
  $meting, 
  for $nr in $ztnrs
  let $zts := $pat[@zorgtrajectnummer eq $nr],
    $beh := $behs[@zorgtrajectnummer eq $nr]/behandelaar,
    $nevend := $nevendiagnoses[@zorgtrajectnummer eq $nr]/nevendiagnose
    
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
  }
}</patient-doc>