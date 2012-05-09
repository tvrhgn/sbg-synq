module namespace sbgbm = "http://sbg-synq.nl/sbg-benchmark";

import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder"at 'zorgaanbieder.xquery';
declare namespace sbggz = "http://sbggz.nl/schema/import/5.0.1"; (:TODO breng batchgegevens over naar za: (schema/sbg-synq-config) of behandel als atomic? :)

declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace sbgem = "http://sbg-synq.nl/epd-meting";

(: uses-relatie eigenlijk niet gewenst ? 
declare namespace sbgza="http://sbg-synq.nl/zorgaanbieder";
:)


declare default element namespace "http://sbggz.nl/schema/import/5.0.1";



(: filter de attributen in de doel-ns en zet ze in default ns:)
declare function sbgbm:filter-sbg-atts( $atts as attribute()* )
as attribute()*
{
for $att in $atts[namespace-uri() eq 'http://sbggz.nl/schema/import/5.0.1' or namespace-uri() eq ''][data(.)]
return attribute { local-name($att) } { data($att) }
};

(: filter een elt en de children  :)
declare function sbgbm:filter-sbg-elt( $elt as element()? )
as element()*
{
if ( not(exists($elt)) ) 
then ()
else 
if( namespace-uri($elt) eq 'http://sbggz.nl/schema/import/5.0.1' or namespace-uri($elt) eq '' )
then 
    element  { local-name($elt) } 
             { sbgbm:filter-sbg-atts($elt/@*)
                ,
                for $e in $elt/*
                return sbgbm:filter-sbg-elt( $e )
             }
else ()
};

declare function sbgbm:new-filter-sbg-elt( $elt as element()? )
as element()*
{
element { local-name($elt) } { $elt/@sbggz:*, 
    for $e in $elt/sbggz:*
    return sbgbm:filter-sbg-elt($e)
}
};

declare function sbgbm:filter-sbg-elts( $elts as element()* )
as element()*
{
for $elt in $elts
return sbgbm:filter-sbg-elt($elt)
};

(: inclusive :)
declare function sbgbm:datum-in-periode( $begin as xs:date, $eind as xs:date, $datum as xs:date ) as xs:boolean
{
    $datum ge $begin and $datum le $eind 
};

(: kijk of einddatum dbc in periode batch valt; laat ook dbc zonder einddatum door als de startdatum voor de einddatum van batch valt 
:)

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
            $metingen := $dbc/sbggz:Meting[xs:date(@sbggz:datum) le $eind][@sbggz:typemeting eq '1']
        return 
            element { 'DBCTraject' } { $atts, $metingen }
     else ()
 };

declare function sbgbm:build-dbc( $dbc as element(DBCTraject) )
as element (DBCTraject )
{
element { 'DBCTraject' } { $dbc/@sbggz:*,
    for $m in $dbc/sbggz:Meting
    return element { 'Meting' } { $m/@sbggz:*,
        for $i in $m/sbggz:Item
        return element { 'Item' } { $i/@sbggz:* }
        }
    }
};

(: bouw patient opnieuw op voeg alleen zorgtrajecten in met dbcs in periode en voeg alleen dbcs in periode in
in het resultaat komen dus mogelijk patienten voor zonder zorgtraject; die zijn sbg-ongeldig
filter ook de niet doel-attributen weg
:)
declare function sbgbm:filter-sbg-dbc-in-periode( $inst as element(sbgza:batch-gegevens), $pat as element(Patient) )
as element(Patient)
{
element
{ local-name($pat) } 
{ sbgbm:filter-sbg-atts($pat/@*),
    for $zt in $pat/Zorgtraject
    let $dbcs := sbgbm:dbc-in-periode($zt/DBCTraject, $inst/@startdatum cast as xs:date, $inst/@einddatum cast as xs:date )
    return if ( count($dbcs) gt 0 ) 
           then
              element { local-name($zt) } 
                      { sbgbm:filter-sbg-atts($zt/@*),
                        ( sbgbm:filter-sbg-elts($zt/sbggz:NevendiagnoseCode), 
                        sbgbm:filter-sbg-elts($zt/sbggz:Behandelaar),
                        sbgbm:filter-sbg-elts($dbcs) )
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
return $selectie[./sbggz:Zorgtraject] (: zie filter-sbg-dbc-in-periode; als er geen dbcs zijn in periode, dan is er ook geen zorgtraject :)
};


(: 
    selecteer patient metingen uit gewenste periode
     kopieer alleen de geldige attributen  
     
    xmlns="http://sbggz.nl/schema/import/5.0.1" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
    eejj-mm-dd hh:mm:ss

        datumCreatie="{replace(substring( string($batch/@datumCreatie), 1, 19), 'T', ' ')}" 

    :)
declare function sbgbm:build-sbg-bmimport( $za as element(), $patient-meting as element(sbggz:Patient)* )
as element(sbggz:BenchmarkImport) 
{
let $batch := sbgza:batch-gegevens($za)
return  
<BenchmarkImport versie="5.0" 
        startdatumAangeleverdePeriode="{substring(string($batch/@startdatum), 1, 10)}" 
        einddatumAangeleverdePeriode="{substring(string($batch/@einddatum), 1, 10)}" 
        datumCreatie="{$batch/@datumCreatie}" 

    >
    <Zorgaanbieder zorgaanbiedercode="{$batch/@agb-code}" zorgaanbiedernaam="{$batch/@zorgaanbieder}">
    {
    sbgbm:filter-batchperiode($batch, $patient-meting)
    }
    </Zorgaanbieder>
</BenchmarkImport>
};
