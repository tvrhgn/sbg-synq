module namespace sbgem = "http://sbg-synq.nl/epd-meting";
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at 'sbg-metingen.xquery';


declare variable $sbgem:dbc-atts := ('DBCTrajectnummer','DBCPrestatieCode','startdatumDBC','einddatumDBC','datumEersteSessie','datumLaatsteSessie','redenEindeDBC','redenNonResponseVoormeting','redenNonResponseNameting');
declare variable $sbgem:patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandpatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');
declare variable $sbgem:zorgtraject-atts := ('locatiecode', 'primaireDiagnoseCode', 'GAFScore'); (: 'zorgtrajectnummer', zorgdomeinCode ; reservecodes:)


(: dient om te garanderen dat alleen geselecteerde attributen doorgegeven worden die bovendien een waarde moeten hebben :)
(: hier wordt de elt content overgedragen naar atts :)
(: TODO ? waarom niet hier de sbggz ns al hanteren en de mogelijkheid voor niet sbg-attributen open houden? antwoord: dan moet je Patient weer helemaal opnieuw opbouwen:)
declare function sbgem:build-sbg-atts($sbg-atts as xs:string+, $nd as node()?) as attribute()* {
    for $elt in $nd/*[text()][index-of( $sbg-atts, local-name(.)) gt 0]
    return attribute { local-name($elt) } { $elt/text() }
};

(: draag element-content over naar attributen :)
declare function sbgem:build-atts( $nd as node() ) as attribute()* {

};

(: eerste zorgdomein-selectie: 
  gebaseerd op zorgcircuit, diagnose en locatie zoals aangegeven in sbg-zorgdomeinen.xml :)
(: primaireDiagnoseCode, cl-zorgcircuit, locatiecode zijn verplichte elementen van dbc :)
declare function sbgem:filter-domein ($dbc as node(), $domeinen as element(sbg-zorgdomeinen)) as element(zorgdomein)* 
{
let $diagnose := $dbc/primaireDiagnoseCode/text(),
    $circuit := $dbc/cl-zorgcircuit/text(),
    $locatie := $dbc/locatiecode/text()
for $zd in $domeinen/zorgdomein
let $rx-circuit := ($zd/koppel-dbc/@zorgcircuit, ".*")[1],
    $rx-diagnose := ($zd/koppel-dbc/@diagnose, ".*")[1],
    $rx-locatie := ($zd/koppel-dbc/@locatie, ".*")[1]
where matches($circuit, $rx-circuit) and matches( $locatie, $rx-locatie ) and matches($diagnose, $rx-diagnose)
return $zd
};

(: selecteer juist domein; het eerste zorgdomein dat in aanmerking komt; gebruik prioriteit aan de data-kant om selectie te sturen 'XX' is max code:)
declare function sbgem:selecteer-domein ($dbc as node(), $domeinen as element(sbg-zorgdomeinen)) as element(zorgdomein) {
let $zds := for $domein in sbgem:filter-domein($dbc, $domeinen) 
                    union <zorgdomein code='XX'><naam>onbekend</naam></zorgdomein>
            order by $domein/koppel-dbc/@priority empty greatest, $domein/@code
            return $domein
 return $zds[1]
};


(: maak een Patient-object met alle metingen, alle zorgtrajecten en per zorgtraject alle dbc's 
voeg geldige zorgdomeinen toe aan meting:)
declare function sbgem:patient-meting-epd( 
    $dbcs as node()*, 
    $metingen as element(Meting)*, 
    $domeinen as element(sbg-zorgdomeinen) ) 
as element(sbgem:Patient) *
{
for $client in distinct-values( $dbcs/koppelnummer/text() )
let $client-dbcs := $dbcs[koppelnummer eq $client], 
    $laatste-dbc := $client-dbcs[last()],
    $clientmetingen := $metingen[@sbgm:koppelnummer eq $client]
return 
   element { 'sbgem:Patient' } 
           { sbgem:build-sbg-atts( $sbgem:patient-atts, $laatste-dbc) ,
       for $meting in $clientmetingen
       let $instr-zd := $domeinen//instrument[@code eq $meting/@gebruiktMeetinstrument], 
        $zorgdomein := $instr-zd/../../@code,
        $meetdomein := distinct-values($instr-zd/../naam/text())
       order by $meting/@datum
       return element { 'sbgem:Meting' } 
        { $meting/@* 
            union attribute { 'sbgem:zorgdomein' } { $zorgdomein }
            union attribute { 'sbgem:meetdomein' } { $meetdomein },
            $meting/* }
       ,
       for $zt in distinct-values($client-dbcs/zorgtrajectnummer)
       let $zt-dbcs := $client-dbcs[zorgtrajectnummer eq $zt],
           $eerste-dbc := $zt-dbcs[1],   (: ga uit van 1 zdomein, diagnosecode etc voor alle dbcs in dit zorgtraject :)
           $zorgdomein := sbgem:selecteer-domein( $eerste-dbc, $domeinen )
       return 
          element { 'sbgem:Zorgtraject' } 
                  { sbgem:build-sbg-atts( $sbgem:zorgtraject-atts, $eerste-dbc) 
                    union attribute { 'zorgtrajectnummer' } { $zt }
                    union attribute { 'sbgem:zorgdomeinCode' } { $zorgdomein/@code }
                    ,
                  for $dbc in $zt-dbcs
                  order by $dbc/startDatum
                  return 
                    element { 'sbgem:DBCTraject' } 
                            { sbgem:build-sbg-atts( $sbgem:dbc-atts, $dbc) }
      }
    }
};
