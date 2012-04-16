module namespace sbgem = "http://sbg-synq.nl/epd-meting";
declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


(: dit zijn de attributen die meteen in de doel-ns gezet worden :)
declare variable $sbgem:dbc-atts := ('DBCTrajectnummer','DBCPrestatieCode','startdatumDBC','einddatumDBC','datumEersteSessie','datumLaatsteSessie','redenEindeDBC','redenNonResponseVoormeting','redenNonResponseNameting');
declare variable $sbgem:patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandpatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');
declare variable $sbgem:zorgtraject-atts := ('zorgtrajectnummer', 'locatiecode', 'primaireDiagnoseCode', 'GAFscore');
 (: , zorgdomeinCode ; reservecodes:)
declare variable $sbgem:behandelaar-atts := ( 'primairOfNeven', 'beroep', 'alias' );

    

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



declare function sbgem:splits-atts-sbg($def as xs:string+, $nds as node()*) 
as attribute()* 
{
    for $att in $nds
    let $name := local-name($att),
        $q-name := if ( exists(index-of( $def, $name ))) 
                      then concat('sbggz:', $name )  
                      else concat( 'sbgem:', $name )
    return 
        attribute { $q-name } 
                  { data($att) }
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

(: let $match-diagnose := ($diagnose, "x")[1] ,
    $match-circuit := ($circuit, "x")[1] ,
    $match-locatie := ($locatie, "x")[1] 
:)

declare function sbgem:zoek-domein-str($diagnose as xs:string?, $circuit as xs:string?, $locatie as xs:string?,
$domeinen as element(zorgdomein)*) 
as element(zorgdomein)* 
{
for $zd in $domeinen
let $rx-circuit := ($zd/koppel-dbc/@zorgcircuit, "")[1],
    $rx-diagnose := ($zd/koppel-dbc/@diagnose, "")[1],
    $rx-locatie := ($zd/koppel-dbc/@locatie, "")[1],
    $match := matches($circuit, $rx-circuit) and matches( $locatie, $rx-locatie ) and matches($diagnose, $rx-diagnose)
where $match
return <zorgdomein zorgdomeinCode='{$zd/@zorgdomeinCode}'>{$zd/koppel-dbc}</zorgdomein>
};

(: hier komt altijd een domein uit; het eerste dat in aanmerking komt of zorgdomein XX :)
declare function sbgem:bepaal-domein ($diagnose as xs:string?, $circuit as xs:string?, $locatie as xs:string?,
$domeinen as element(zorgdomein)*) 
as element(zorgdomein)
{
let $zds := for $domein in sbgem:zoek-domein-str($diagnose, $circuit, $locatie, $domeinen) 
                           union <zorgdomein zorgdomeinCode='XX'><naam>onbekend</naam></zorgdomein>
            order by $domein/koppel-dbc/@priority empty greatest, $domein/@zorgdomeinCode
            return $domein
 return $zds[1]
};


(: het eerste zorgdomein dat in aanmerking komt; gebruik prioriteit aan de data-kant om selectie te sturen 'XX' is max code :)
declare function sbgem:selecteer-domein ($dbc as node(), $domeinen as element(zorgdomein)*) 
as element(zorgdomein)
{
let $zds := for $domein in sbgem:zoek-domein($dbc, $domeinen) 
                           union <zorgdomein zorgdomeinCode='XXXXXXX'><naam>onbekend</naam></zorgdomein>
            order by $domein/koppel-dbc/@priority empty greatest, $domein/@zorgdomeinCode
            return $domein
 return $zds[1]
};

(: neem de metingen van client over en annoteer de zorg/meetdomeinen :)
(: todo: dit kan toch naar sbgm: ? nee: dan moet sbgm ineens kennis hebben van zorgdomeinen :)
(: verwerking meting attributen gebeurt wel in sbgm :)
declare function sbgem:annoteer-metingen( $metingen as element(sbgm:Meting)*, $domeinen as element(zorgdomein)* )
as element(sbgem:Meting)*
{
for $meting in $metingen
let $instr-zd := $domeinen//instrument[@code eq $meting/@sbggz:gebruiktMeetinstrument], 
    $zorgdomein := $instr-zd/../../@zorgdomeinCode,
    $meetdomein := string-join( distinct-values($instr-zd/../naam/text()), ', ' )
order by $meting/@datum
return element { 'sbgem:Meting' } 
        { $meting/@* 
            union attribute { 'sbgem:zorgdomein' } { $zorgdomein }
            union attribute { 'sbgem:meetdomein' } { $meetdomein },
            $meting/* }
};

(: forceer uniek :)
declare function sbgem:maak-nevendiagnose( $diagn as element(nevendiagnose)* ) 
as element(sbggz:NevendiagnoseCode)*
{
for $diag in distinct-values($diagn/@nevendiagnoseCode)
return 
    element { 'sbggz:NevendiagnoseCode' }
            {    attribute { 'sbggz:nevendiagnoseCode' } { $diag }
            }
};

declare function sbgem:maak-behandelaar( $behs as element(behandelaar)*  ) 
as element(sbggz:Behandelaar)* {
for $beh in $behs
let $geldig := data($beh/@primairOfNeven) ne '' and data($beh/@beroep) ne '' and data($beh/@alias) ne '',
 $geldig-att := if ( $geldig ) then () else attribute { 'ongeldig' } { true() }
 return element { 'sbggz:Behandelaar' } {
                sbgem:splits-atts-sbg($sbgem:behandelaar-atts, $beh/@*) 
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
               element { 'sbgem:xDBCTraject' } 
                            { sbgem:vertaal-elt-naar-att-sbg( $sbgem:dbc-atts, $dbc) 
                  }
      }
};

(: neem de gegevens over van de laatste dbc voor het zdomein (hetzelfde gebeurt eerder voor diagnosecode, locatie) :)
declare function sbgem:annoteer-zorgtraject( $zt as element(zorgtraject), $domeinen as element(zorgdomein)* )
as element( sbgem:Zorgtraject )
{
let $zt-dbcs := $zt/dbctraject,
    $zt-dbc := $zt/dbctraject[position() eq last()],
    $beh := $zt/behandelaar,
    $diag := $zt/nevendiagnose,
    $zorgdomein := sbgem:bepaal-domein( $zt/@primaireDiagnoseCode, $zt-dbc/@cl-zorgcircuit, $zt/@locatiecode, $domeinen )
return 
    element { 'sbgem:Zorgtraject' } 
            { sbgem:splits-atts-sbg( $sbgem:zorgtraject-atts, $zt/@* )
               union attribute { 'sbgem:zorgdomeinCode' } { $zorgdomein/@zorgdomeinCode }
                ,
              
            sbgem:maak-behandelaar($beh),
            sbgem:maak-nevendiagnose($diag),
            for $dbc in $zt-dbcs
            order by $dbc/@startDatum
            return 
               element { 'sbgem:DBCTraject' } 
                            { sbgem:splits-atts-sbg( $sbgem:dbc-atts, $dbc/@* ) 
                  }
      }
};

declare function sbgem:verwerk-zorgtrajecten( $zts as element(zorgtraject)*, $domeinen as element(zorgdomein)* )
as element( sbgem:Zorgtraject )*
{
for $zt in $zts
return sbgem:annoteer-zorgtraject($zt,$domeinen)
};


declare function sbgem:maak-patient-meting( 
    $pats as element(patient)*, 
    $metingen as element(metingen)*,
    $domeinen as element(zorgdomein)* ) 
as element(sbgem:Patient) *
{
for $pat in $pats
return 
   element { 'sbgem:Patient' } 
           { 
           sbgem:splits-atts-sbg($sbgem:patient-atts, $pat/@* ),
           <sbgem:metingen>{sbgem:annoteer-metingen($metingen[@koppelnummer eq $pat/@koppelnummer]/sbgm:Meting ,$domeinen)}</sbgem:metingen>,
           sbgem:verwerk-zorgtrajecten($pat/zorgtraject, $domeinen)
       }
};
