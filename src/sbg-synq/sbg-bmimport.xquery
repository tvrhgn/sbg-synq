module namespace sbgbm = "http://sbg-synq.nl/sbg-benchmark";
declare namespace sbggz = "http://sbggz.nl/schema/import/5.0.1"; (:TODO breng batchgegevens over naar za: (schema/sbg-synq-config) of behandel als atomic? :)

declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace sbgem = "http://sbg-synq.nl/epd-meting";

(: uses-relatie eigenlijk niet gewenst ? 
declare namespace sbgza="http://sbg-synq.nl/zorgaanbieder";
:)
import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder"at '../sbg-synq/zorgaanbieder.xquery';

declare default element namespace "http://sbggz.nl/schema/import/5.0.1";


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

declare function sbgbm:datum-in-periode( $begin as xs:date, $eind as xs:date, $datum as xs:date ) as xs:boolean
{
    $datum ge $begin and $datum le $eind 
};

(: kijk of einddatum dbc in periode batch valt; laat ook dbc zonder einddatum door als de startdatum voor de einddatum van batch valt 

or ( string($dbc/@einddatumDBC) eq '' ) and days-from-duration( xs:date($dbc/@startdatumDBC) - xs:date($inst/sbggz:einddatum) ) lt 0 )
:)
declare function sbgbm:dbc-in-periode-batch( $inst as element(sbgza:batch-gegevens), $dbcs as element(DBCTraject)* ) 
as element(DBCTraject)* 
{
    for $dbc in $dbcs
    return  if ( sbgbm:in-periode( $inst/sbgza:startdatum, $inst/sbgza:einddatum, $dbc/@sbgza:einddatumDBC) 
                or ( not($dbc/@sbgza:einddatumDBC)  and days-from-duration( xs:date($dbc/@sbgza:startdatumDBC) - xs:date($inst/sbgza:einddatum) ) lt 0 ))  
            then $dbc else ()
 };


declare function sbgbm:dbc-in-periode( $dbcs as element(DBCTraject)*, $begin as xs:date, $eind as xs:date ) 
as element(DBCTraject)* 
{
for $dbc in $dbcs
let $startdatum := xs:date($dbc/@sbggz:startdatumDBC),
    $open :=  not( $dbc/@sbggz:einddatumDBC)  or not( data($dbc/@sbggz:einddatumDBC) castable as xs:date ),
    $einddatum := if ( data($dbc/@sbggz:einddatumDBC) castable as xs:date ) 
                  then xs:date($dbc/@sbggz:einddatumDBC) 
                  else xs:date( '1900-01-01' ),
    $in-periode := $einddatum ge $begin and $einddatum le $eind,
    $was-toen-open := $einddatum ge $eind and $startdatum le $eind 
return  
    if (  $in-periode ) then $dbc
    else
     if ( $open or $was-toen-open ) 
     then 
        let $atts := $dbc/@*[local-name() ne 'einddatumDBC'][local-name() ne 'datumLaatsteSessie'],
            $metingen := $dbc/*[xs:date(@datum) le $eind][@typemeting eq '1']
        return 
            element { 'DBCTraject' } { $atts, $metingen }
     else ()
 };


(: bouw patient opnieuw op voeg alleen zorgtrajecten in met dbcs in periode en voeg alleen dbcs in periode in
in het resultaat komen dus mogelijk patienten voor zonder zorgtraject; die zijn sbg-ongeldig
filter ook de niet doel-attributen weg
:)
declare function sbgbm:filter-sbg-dbc-in-periode( $inst as element(sbgza:batch-gegevens), $pat as element(Patient) )
as element(Patient)
{
element
{ name($pat) } 
{ sbgbm:filter-sbg-atts($pat/@*),
    for $zt in $pat/Zorgtraject
    let $dbcs := sbgbm:dbc-in-periode($zt/DBCTraject, $inst/@startdatum cast as xs:date, $inst/@einddatum cast as xs:date )
    return if ( count($dbcs) gt 0 ) 
           then
              element { name($zt) } 
                      { sbgbm:filter-sbg-atts($zt/@*),
                        $zt/sbggz:NevendiagnoseCode, 
                        $zt/sbggz:Behandelaar, 
                        for $dbc in $dbcs 
                        return sbgbm:filter-sbg-elt( $dbc )
                      }
           else ()
}
};


(: filter de dbcs uit en retourneer de patienten die dbcs overhouden :)
declare function sbgbm:filter-batchperiode($inst as element(sbgza:batch-gegevens), $pats as element(Patient)*) 
as element(Patient)* 
{
let $selectie := for $pat in $pats
                    return sbgbm:filter-sbg-dbc-in-periode($inst,$pat)
return $selectie[./sbggz:Zorgtraject]
};

    
(: geef alleen de patienten met relevante dbcs  TODO: filter ook alleen de relevante dbcs? :)
declare function sbgbm:xfilter-batchperiode($inst as element(sbgza:batch-gegevens), $pats as element(Patient)*) 
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
let $batch := sbgza:batch-gegevens($za)
return  
<BenchmarkImport versie="5.0" 
        startdatumAangeleverdePeriode="{substring(string($batch/@startdatum), 1, 10)}" 
        einddatumAangeleverdePeriode="{substring(string($batch/@einddatum), 1, 10)}" 
        datumCreatie="{replace(substring( string($batch/@datumCreatie), 1, 19), 'T', ' ')}" 
    >
    <Zorgaanbieder zorgaanbiedercode="{$batch/@agb-code}" zorgaanbiedernaam="{$batch/@zorgaanbieder}">
    {
    sbgbm:filter-batchperiode($batch, $patient-meting)
    }
    </Zorgaanbieder>
</BenchmarkImport>
};
