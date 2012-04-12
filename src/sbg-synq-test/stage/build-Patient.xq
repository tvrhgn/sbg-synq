import module namespace stg = 'http://sbg-synq.nl/stage' at 'stage-row-elt.xquery';

declare variable $dbc-atts := ('DBCTrajectnummer','DBCPrestatieCode','startdatumDBC','einddatumDBC','datumEersteSessie','datumLaatsteSessie','redenEindeDBC','redenNonResponseVoormeting','redenNonResponseNameting');
declare variable $patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandpatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');
declare variable $zorgtraject-atts := ('zorgtrajectnummer', 'locatiecode', 'primaireDiagnoseCode', 'GAFscore'); (: , zorgdomeinCode ; reservecodes:)


let $ctx := .
let $pats := $ctx//Row
let $behs := $ctx//behandelaar-doc/*
let $nds := $ctx//nevendiagnose-doc/*

return 
<patient-doc>{
for $kn in distinct-values( $pats/koppelnummer )
let $pat := $pats[koppelnummer eq $kn]
return element { 'Patient' }
    { stg:build-atts-only($pat[1],$patient-atts),
      for $zt in distinct-values( $pat/zorgtrajectnummer ) 
      return 
        element { 'Zorgtraject' } 
            {stg:build-atts-only($pat[zorgtrajectnummer eq $zt][1],$zorgtraject-atts),
            ($behs[@zorgtrajectnummer eq $zt]/Behandelaar,
             $nds[@zorgtrajectnummer eq $zt]/NevendiagnoseCode,
            for $dbc in distinct-values( $pat/DBCTrajectnummer )
            return 
                element { 'DBCTraject' }
                {stg:build-atts-filter($pat[DBCTrajectnummer eq $dbc][1],($zorgtraject-atts, $patient-atts))
                }
             )
            }
        }
}</patient-doc>