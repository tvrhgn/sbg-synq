module namespace sbgbm = "http://sbg-synq.nl/sbg-benchmark";
declare namespace sbggz = "http://sbggz.nl/schema/import/5.0.1"; (:TODO breng batchgegevens over naar za: (schema/sbg-synq-config) of behandel als atomic? :)
declare namespace sbgza="http://sbg-synq.nl/zorgaanbieder";
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

(: filter de attributen in de doel-ns :)
declare function sbgbm:filter-sbg-atts( $atts as attribute()* )
as attribute()*
{
for $att in $atts[namespace-uri() eq 'http://sbggz.nl/schema/import/5.0.1' or namespace-uri() eq ''][data(.)]
return attribute { local-name($att) } { data($att) }
};

(: filter een elt en de children  :)
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

(: inclusive :)
declare function sbgbm:in-periode( $begin as xs:date, $eind as xs:date, $datum as xs:anyAtomicType? ) as xs:boolean
{
    $datum castable as xs:date and xs:date($datum) ge $begin and xs:date($datum) le $eind 
};

(: kijk of einddatum dbc in periode batch valt; laat ook dbc zonder einddatum door als de startdatum voor de einddatum van batch valt 

or ( string($dbc/@einddatumDBC) eq '' ) and days-from-duration( xs:date($dbc/@startdatumDBC) - xs:date($inst/sbggz:einddatum) ) lt 0 )
:)
declare function sbgbm:dbc-in-periode-batch( $inst as element(batch-gegevens), $dbcs as element(DBCTraject)* ) 
as element(DBCTraject)* 
{
    for $dbc in $dbcs
    return  if ( sbgbm:in-periode( $inst/sbggz:startdatum, $inst/sbggz:einddatum, $dbc/@sbggz:einddatumDBC) 
                or ( not($dbc/@sbggz:einddatumDBC)  and days-from-duration( xs:date($dbc/@sbggz:startdatumDBC) - xs:date($inst/sbggz:einddatum) ) lt 0 ))  
            then $dbc else ()
 };


(: bouw patient opnieuw op voeg alleen zorgtrajecten in met dbcs in periode en voeg alleen dbcs in periode in
in het resultaat komen dus mogelijk patienten voor zonder zorgtraject; die zijn sbg-ongeldig
filter ook de niet doel-attributen weg
:)
declare function sbgbm:filter-sbg-dbc-in-periode( $inst as element(batch-gegevens), $pat as element(Patient) )
as element(Patient)
{
element  { name($pat) } 
         { sbgbm:filter-sbg-atts($pat/@*),
           for $zt in $pat/Zorgtraject
           let $dbcs := sbgbm:dbc-in-periode-batch($inst, $zt/DBCTraject)
           return if ( count($dbcs) gt 0 ) 
                    then
                        element { name($zt) } 
                                { sbgbm:filter-sbg-atts($zt/@*),                     
                                    for $dbc in $dbcs return sbgbm:filter-sbg-elt( $dbc )
                                }
                    else ()
         }
};


(: filter de dbcs uit en retourneer de patienten die dbcs overhouden :)
declare function sbgbm:filter-batchperiode($inst as element(batch-gegevens), $pats as element(Patient)*) 
as element(Patient)* 
{
let $selectie := for $pat in $pats
                    return sbgbm:filter-sbg-dbc-in-periode($inst,$pat)
return $selectie[./Zorgtraject]
};

    
(: geef alleen de patienten met relevante dbcs  TODO: filter ook alleen de relevante dbcs? :)
declare function sbgbm:xfilter-batchperiode($inst as element(batch-gegevens), $pats as element(Patient)*) 
as element(Patient)* 
{
for $pat in $pats
let $dbcs := sbgbm:dbc-in-periode-batch($inst, $pat/Zorgtraject/DBCTraject)
return if (count($dbcs) gt 0) then $pat else ()
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
    sbgbm:filter-batchperiode($batch, $patient-meting)
    }
    </Zorgaanbieder>
</BenchmarkImport>
};
