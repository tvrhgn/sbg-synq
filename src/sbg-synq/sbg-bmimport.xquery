module namespace sbgbm = "http://sbg-synq.nl/sbg-benchmark";
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";



(: laat alleen de attributen met een text-waarde in de default namespace door; 
  stript dus de applicatie-attributen :)
(: filter de attributen van een enkel element :)
declare function sbgbm:filter-atts( $nd as element() ) as attribute()* 
{
$nd/@*[namespace-uri() = ''][string-length(.) gt 0] 
}; 


(: forceer uniek :)
declare function sbgbm:build-sbg-nevendiagnose( $zt as element(Zorgtraject), $diagn as node()* ) 
as element(sbggz:NevendiagnoseCode)*
{
for $diag in distinct-values($diagn[zorgtrajectnummer eq $zt/@zorgtrajectnummer]/text())
return <sbggz:NevendiagnoseCode nevendiagnoseCode="{$diag}"/>
};

(: zoek de behandelaars bij een zorgtraject  :)
(: filter ongeldige er uit; forceer uniek ? :)
declare function sbgbm:build-sbg-behandelaar( $zt as element(Zorgtraject), $behs as node()*  ) 
as element(sbggz:Behandelaar)* {
for $beh in $behs[zorgtrajectnummer eq $zt/@zorgtrajectnummer][primairOfNeven/text()][beroep/text()][alias/text()]
let $pon := $beh/primairOfNeven,
    $beroep := $beh/beroep,
    $alias := $beh/alias
return <sbggz:Behandelaar primairOfNeven="{$pon}" beroep="{$beroep}" alias="{$alias}"/>
};

(: maak een doc met geldige datums voor de batch; datum is verplicht; 
  val terug op default de 3 maanden tot laatste einde maand voor datum  :)
declare function sbgbm:batch-gegevens($za as element(zorgaanbieder)) as element(batch-gegevens) {
let $batch := $za/batch[1],  (: voer alleen de de eerste batch uit :)
    $ts := data($batch/@datumCreatie),
    $today := fn:current-date(),
    $dom := fn:day-from-date($today),
    $default-eind := $today - xs:dayTimeDuration( concat( 'P', $dom, 'D' )), (: eind vorige maand :)
    $eind := (xs:date($batch/einddatumAangeleverdePeriode), $default-eind)[1], 
    $aanlever-periode := if ($batch/aanleverperiode castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration($batch/aanleverperiode) 
                         else xs:yearMonthDuration('P3M'),  
    $def-start := $eind - $aanlever-periode + xs:dayTimeDuration( 'P1D' ), (: begin v/d maand als $def-eind is eind v/d maand :) 
    $start := (xs:date($batch/startdatumAangeleverdePeriode), $def-start)[1],
    $meetperiode := if ($batch/meetperiode castable as xs:yearMonthDuration )
                     then xs:yearMonthDuration($batch/meetperiode)
                     else xs:yearMonthDuration('P3M')
    
return <batch-gegevens>
    <meetperiode>{$meetperiode}</meetperiode>
    <startdatum>{$start}</startdatum>
    <einddatum>{$eind}</einddatum>
    <timestamp>{$ts}</timestamp>
</batch-gegevens>
};

(: inclusive :)
declare function sbgbm:in-periode( $begin as xs:date, $eind as xs:date, $datum as xs:anyAtomicType? ) as xs:boolean
{
    $datum castable as xs:date and xs:date($datum) ge $begin and xs:date($datum) le $eind 
};

(: kijk of einddatum dbc in periode batch valt; laat ook dbc zonder einddatum door :)
declare function sbgbm:dbc-in-periode-batch( $inst as element(batch-gegevens), $dbcs as element(DBCTraject)* ) 
as element(DBCTraject)* 
{
    for $dbc in $dbcs
    return  if ( sbgbm:in-periode( $inst/startdatum, $inst/einddatum, $dbc/@einddatumDBC) or string($dbc/@einddatumDBC) eq '' )
            then $dbc else ()
 };
    
(: geef alleen de patienten met relevante dbcs  :)
declare function sbgbm:filter-batchperiode($inst as element(batch-gegevens), $patient-meting as element(Patient)*) 
as element(Patient)* 
{
for $pm in $patient-meting
let $dbcs := sbgbm:dbc-in-periode-batch($inst, $pm/Zorgtraject/DBCTraject)
return if (count($dbcs) gt 0) then $pm else ()
};


(: neem de patient-meting-objecten, links naar epd, behandelaar en diagnose-bestanden,
    selecteer patient metingen uit gewenste periode
    voeg nevendiagnose en behandelaar in om Patient compleet te maken.
    kopieer de juiste attributen volgens sbg-schema  :)
declare function sbgbm:build-sbg-bmimport (
    $za as element(zorgaanbieder), 
    $patient-meting as element(Patient)*, 
    $behs as node()*, 
    $diagn as node()* ) 
as element(sbggz:BenchmarkImport) 
{
let $batch := sbgbm:batch-gegevens($za)
return  
<sbggz:BenchmarkImport versie="5.0"
        startdatumAangeleverdePeriode="{$batch/startdatum}" 
        einddatumAangeleverdePeriode="{$batch/einddatum}" 
        datumCreatie="{$batch/timestamp}" 
    >
    <sbggz:Zorgaanbieder zorgaanbiedercode="{$za/@code}" zorgaanbiedernaam="{$za/naam}">
    {
    for $patient in sbgbm:filter-batchperiode($batch, $patient-meting)
    return element  { 'sbggz:Patient' } { sbgbm:filter-atts( $patient ) 
                      ,
                      for $zt in $patient/Zorgtraject
                      let $dbcs := sbgbm:dbc-in-periode-batch($batch, $zt/DBCTraject)
                      return element { 'sbggz:Zorgtraject' }
                          { sbgbm:filter-atts( $zt )
                          ,
                          sbgbm:build-sbg-nevendiagnose($zt, $diagn) 
                          union sbgbm:build-sbg-behandelaar($zt, $behs)
                          union 
                          (for $dbc in $dbcs
                           return element { 'sbggz:DBCTraject' }
                           { sbgbm:filter-atts($dbc)
                           ,
                            for $meting in $dbc/Meting
                            return element { 'sbggz:Meting' } 
                            { sbgbm:filter-atts($meting)
                            ,
                            for $item in $meting/Item
                             return element { 'sbggz:Item' }
                             { sbgbm:filter-atts($item) }
                            }
                            }
                           )
                          }
                 }
    }
    </sbggz:Zorgaanbieder>
</sbggz:BenchmarkImport>
};
