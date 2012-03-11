module namespace sbgbm = "http://sbg-synq.nl/sbg-benchmark";
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";
declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace sbgem = "http://sbg-synq.nl/epd-meting";
declare default element namespace "http://sbggz.nl/schema/import/5.0.1";
(:  :)

(: maak een doc met geldige datums voor de batch; datum is verplicht; 
  val terug op default de 3 maanden tot laatste einde maand voor datum  
  $ts := data($batch/@datumCreatie),
  laten vallen? is nu technische export-datum; systeemafhankelijk
  :)
declare function sbgbm:batch-gegevens($za as element()) as element(batch-gegevens) {
let $batch := $za/batch[1],  (: voer alleen de de eerste batch uit :)
    $ts := (data($batch/@*[local-name() eq 'datumCreatie']), current-dateTime())[1],
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
    <sbggz:zorgaanbieder-agb>{data($za/@code)}</sbggz:zorgaanbieder-agb>
    <sbggz:zorgaanbieder>{$za/*[local-name() eq 'naam']}</sbggz:zorgaanbieder>
    <sbggz:startdatum>{$start}</sbggz:startdatum>
    <sbggz:einddatum>{$eind}</sbggz:einddatum>
    <sbggz:timestamp>{$ts}</sbggz:timestamp>
</batch-gegevens>
};

(: inclusive :)
declare function sbgbm:in-periode( $begin as xs:date, $eind as xs:date, $datum as xs:anyAtomicType? ) as xs:boolean
{
    $datum castable as xs:date and xs:date($datum) ge $begin and xs:date($datum) le $eind 
};

(: kijk of einddatum dbc in periode batch valt; laat ook dbc zonder einddatum door :)
declare function sbgbm:dbc-in-periode-batch( $inst as element(batch-gegevens), $dbcs as element(sbggz:DBCTraject)* ) 
as element(sbggz:DBCTraject)* 
{
    for $dbc in $dbcs
    return  if ( sbgbm:in-periode( $inst/sbggz:startdatum, $inst/sbggz:einddatum, $dbc/@sbggz:einddatumDBC) or string($dbc/@sbggz:einddatumDBC) eq '' )
            then $dbc else ()
 };
    
(: geef alleen de patienten met relevante dbcs  :)
declare function sbgbm:filter-batchperiode($inst as element(batch-gegevens), $patient-meting as element(sbggz:Patient)*) 
as element(sbggz:Patient)* 
{
for $pm in $patient-meting
let $dbcs := sbgbm:dbc-in-periode-batch($inst, $pm/sbggz:Zorgtraject/sbggz:DBCTraject)
return if (count($dbcs) gt 0) then $pm else ()
};

declare function sbgbm:filter-sbg-atts( $atts as attribute()* )
as attribute()*
{
for $att in $atts[namespace-uri() eq 'http://sbggz.nl/schema/import/5.0.1' or namespace-uri() eq ''][data(.)]
return attribute { local-name($att) } { data($att) }
};

declare function sbgbm:filter-sbg-elt( $elt as element() )
as element()*
{
if ( namespace-uri($elt) eq 'http://sbggz.nl/schema/import/5.0.1' or namespace-uri($elt) eq '' )
then element  { local-name($elt) } 
              { sbgbm:filter-sbg-atts($elt/@*)
              ,
              for $e in $elt/*
              return sbgbm:filter-sbg-elt( $e )
              }
else ()
};

(: neem de patient-meting-objecten, links naar epd, behandelaar en diagnose-bestanden,
    selecteer patient metingen uit gewenste periode
    voeg nevendiagnose en behandelaar in om Patient compleet te maken.
    kopieer de juiste attributen volgens sbg-schema  
    xmlns="http://sbggz.nl/schema/import/5.0.1" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
    eejj-mm-dd hh:mm:ss
    :)
declare function sbgbm:build-sbg-bmimport( $za as element(), $patient-meting as element(sbggz:Patient)* )
as element(sbggz:BenchmarkImport) 
{
let $batch := sbgbm:batch-gegevens($za)
return  
<BenchmarkImport versie="5.0" 
        startdatumAangeleverdePeriode="{substring(string($batch/sbggz:startdatum), 1, 10)}" 
        einddatumAangeleverdePeriode="{substring(string($batch/sbggz:einddatum), 1, 10)}" 
        datumCreatie="{replace(substring( string($batch/sbggz:timestamp), 1, 19), 'T', ' ')}" 
    >
    <Zorgaanbieder zorgaanbiedercode="{$batch/sbggz:zorgaanbieder-agb}" zorgaanbiedernaam="{$batch/sbggz:zorgaanbieder}">
    {
    for $patient in sbgbm:filter-batchperiode($batch, $patient-meting)
    return element  { 'Patient' } 
                    { sbgbm:filter-sbg-atts($patient/@*) 
                      ,
                      for $zt in $patient/sbggz:Zorgtraject
                      return sbgbm:filter-sbg-elt($zt)
                    }
    }
    </Zorgaanbieder>
</BenchmarkImport>
};
