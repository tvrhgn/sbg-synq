module namespace sbgem = "http://sbg-synq.nl/epd-meting";
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at 'sbg-metingen.xquery';
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


(: dit zijn de attributen die meteen in de doel-ns gezet worden :)
declare variable $sbgem:dbc-atts := ('DBCTrajectnummer','DBCPrestatieCode','startdatumDBC','einddatumDBC','datumEersteSessie','datumLaatsteSessie','redenEindeDBC','redenNonResponseVoormeting','redenNonResponseNameting');
declare variable $sbgem:patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandpatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');
declare variable $sbgem:zorgtraject-atts := ('zorgtrajectnummer', 'locatiecode', 'primaireDiagnoseCode', 'GAFscore'); (: , zorgdomeinCode ; reservecodes:)

(: neem de sub-elementen direct onder elt. als er text-content is, vertaal die dan naar een attribuut met de naam van het sub-element.
bepaal namespace van attribuut op basis van param $def: als de naam van het sub-element voorkomt in $def, gebruik dan de doel ns, anders de module-ns

def betekent definitief: deze attributen hebben hun definitieve waarde (in de context van sbg-synq processing); ze worden niet verder gewijzigd verderop in sbg-synq
het idee is dat wanneer een attribuut eenmaal in de doel ns staat, er niks meer veranderd mag worden (const)
uiteindelijk worden de @*[namespace-uri() eq 'http://sbgz.nl/schema/import/5.0.1'] gelicht voor de export; de benchmark-info. 
de andere attributen zijn nuttig voor de proces-info (bv toevoegen van geboortedatum)

:)
declare function sbgem:vertaal-elt-naar-att-sbg($def as xs:string+, $nd as node()) 
as attribute()* 
{
    for $elt in $nd/*[text()]
    let $prefix := if ( index-of( $def, local-name($elt)) gt 0 ) 
                      then 'sbggz:' 
                      else 'sbgem:'
    return 
        attribute { concat($prefix, local-name($elt)) } 
                  { $elt/text() }
};

(: selecteer alleen elt met naam in $def en vertaal die naar doel-ns :)
declare function sbgem:vertaal-elt-naar-filter-sbg($def as xs:string+, $nd as node()) 
as attribute()* 
{
    for $elt in $nd/*[text()]
    return if ( index-of( $def, local-name($elt)) gt 0 ) 
           then attribute { concat('sbggz:', local-name($elt)) } { $elt/text() }
           else ()
};

(: eerste zorgdomein-selectie: 
  gebaseerd op zorgcircuit, diagnose en locatie zoals aangegeven in sbg-zorgdomeinen.xml :)
(: primaireDiagnoseCode, cl-zorgcircuit, locatiecode zijn verplichte elementen van dbc :)
declare function sbgem:zoek-domein ($dbc as node(), $domeinen as element(zorgdomein)*) 
as element(zorgdomein)* 
{
let $diagnose := $dbc/primaireDiagnoseCode/text(),
    $circuit := $dbc/cl-zorgcircuit/text(),
    $locatie := $dbc/locatiecode/text()
for $zd in $domeinen
let $rx-circuit := ($zd/koppel-dbc/@zorgcircuit, ".*")[1],
    $rx-diagnose := ($zd/koppel-dbc/@diagnose, ".*")[1],
    $rx-locatie := ($zd/koppel-dbc/@locatie, ".*")[1]
where matches($circuit, $rx-circuit) and matches( $locatie, $rx-locatie ) and matches($diagnose, $rx-diagnose)
return $zd
};

(: selecteer juist domein; het eerste zorgdomein dat in aanmerking komt; gebruik prioriteit aan de data-kant om selectie te sturen 'XX' is max code:)
declare function sbgem:selecteer-domein ($dbc as node(), $domeinen as element(zorgdomein)*) 
as element(zorgdomein)
{
let $zds := for $domein in sbgem:zoek-domein($dbc, $domeinen) 
                           union <zorgdomein zorgdomeinCode='XX'><naam>onbekend</naam></zorgdomein>
            order by $domein/koppel-dbc/@priority empty greatest, $domein/@zorgdomeinCode
            return $domein
 return $zds[1]
};

(: neem de metingen van client over en annoteer de zorg/meetdomeinen :)
(: todo: dit kan toch naar sbgm: ? :)
(: todo: verwerking attributen is slordig ? :)
declare function sbgem:annoteer-metingen( $metingen as element(Meting)*, $domeinen as element(zorgdomein)* )
as element(Meting)*
{
for $meting in $metingen
let $instr-zd := $domeinen//instrument[@code eq $meting/@gebruiktMeetinstrument], 
    $zorgdomein := $instr-zd/../../@zorgdomeinCode,
    $meetdomein := string-join( distinct-values($instr-zd/../naam/text()), ', ' )
order by $meting/@datum
return element { 'Meting' } 
        { $meting/@* 
            union attribute { 'sbgem:zorgdomein' } { $zorgdomein }
            union attribute { 'sbgem:meetdomein' } { $meetdomein },
            $meting/* }
};

(: forceer uniek :)
declare function sbgem:maak-nevendiagnose( $diagn as node()* ) 
as element(sbggz:NevendiagnoseCode)*
{
for $diag in distinct-values($diagn/nevendiagnoseCode/text())
return 
    element { 'sbggz:NevendiagnoseCode' }
            {    attribute { 'nevendiagnoseCode' } {$diag}
            }
};

declare function sbgem:maak-behandelaar( $behs as node()*  ) 
as element(sbggz:Behandelaar)* {
for $beh in $behs[primairOfNeven/text()][beroep/text()][alias/text()]
let $pon := $beh/primairOfNeven,
    $beroep := $beh/beroep,
    $alias := $beh/alias
return 
    element { 'sbggz:Behandelaar' } 
            {   attribute { 'primairOfNeven' } {$pon} 
                union attribute { 'beroep' }  {$beroep}
                union attribute { 'alias' }   {$alias}
            }
};

       
declare function sbgem:annoteer-zorgtrajecten( $dbcs as node()*, $behs as node()*, $diagn as node()*, $domeinen as element(zorgdomein)* )
as element( sbgem:Zorgtraject )*
{
for $zt in distinct-values($dbcs/zorgtrajectnummer)
let $zt-dbcs := $dbcs[zorgtrajectnummer eq $zt],
    $beh := $behs[zorgtrajectnummer eq $zt],
    $diag := $diagn[zorgtrajectnummer eq $zt],
    $zt-dbc := $zt-dbcs[last()],   (: ga uit van 1 zdomein, diagnosecode, locatie etc over van laatste dbc in dit zorgtraject :)
    $zorgdomein := sbgem:selecteer-domein( $zt-dbc, $domeinen )
return 
    element { 'sbgem:Zorgtraject' } 
            { sbgem:vertaal-elt-naar-filter-sbg( $sbgem:zorgtraject-atts, $zt-dbc )
               union attribute { 'sbgem:zorgdomeinCode' } { $zorgdomein/@zorgdomeinCode }
                ,
            sbgem:maak-behandelaar($beh),
            sbgem:maak-nevendiagnose($diag),
            for $dbc in $zt-dbcs
            order by $dbc/startDatum
            return 
               element { 'sbgem:DBCTraject' } 
                            { sbgem:vertaal-elt-naar-att-sbg( $sbgem:dbc-atts, $dbc) 
                  }
      }
};


(: hier komt de onbewerkte epd-data binnen. de Metingen zijn al aangemaakt.
 Patient wordt hier voor het eerst opgebouwd; attributen worden in de juiste ns gezet; alle Metingen worden per patient ingevoegd.
 koppeling aan nevendiagnose en behandelaar.
 NB dit formaat is geschikt voor proces-informatie
:)
declare function sbgem:maak-patient-meting( 
    $dbcs as node()*, 
    $behs as node()*, 
    $diagn as node()*, 
    $metingen as element(Meting)*,
    $domeinen as element(sbg-zorgdomeinen) ) 
as element(sbgem:Patient) *
{
for $client in distinct-values( $dbcs/koppelnummer/text() )
let $client-dbcs := $dbcs[koppelnummer eq $client], 
    $laatste-dbc := $client-dbcs[last()]
return 
   element { 'sbgem:Patient' } 
           { 
           sbgem:vertaal-elt-naar-filter-sbg( $sbgem:patient-atts, $laatste-dbc ),
           <sbgem:metingen>{sbgem:annoteer-metingen($metingen[@sbgm:koppelnummer eq $client] ,$domeinen//zorgdomein)}</sbgem:metingen>,
           sbgem:annoteer-zorgtrajecten($client-dbcs, $behs, $diagn, $domeinen//zorgdomein)
       }
};
