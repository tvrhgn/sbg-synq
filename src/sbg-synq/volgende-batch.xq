(: XQuery main module :)

declare variable $duur as xs:string external;
declare variable $aanleverperiode as xs:string external;


(: maakt gebruik van de xpath 2.0 functie-bibliotheek :)
(: zie http://www.w3.org/TR/xpath-functions/#durations-dates-times  :)
declare function local:get-duration( $dur as xs:string, $default as xs:string )
as xs:yearMonthDuration
{
if ( $dur castable as xs:yearMonthDuration ) 
then xs:yearMonthDuration($dur) 
else xs:yearMonthDuration($default)
};


declare function local:einde-maand( $dat as xs:date )
as xs:date
{
let $month-p := month-from-date( $dat ),
    $month-i := if ( $month-p eq 12 ) 
                then 1 
                else $month-p + 1,
                
    $year :=    if ( $month-p eq 12 ) 
                then year-from-date($dat) + 1 
                else year-from-date($dat),
    (: 'lt' is 'less than'; 'kleiner dan' :)
    $month := if ( $month-i lt 10 ) then concat( "0", $month-i) else xs:string( $month-i),
    $eerste-volgende-maand := xs:dateTime( concat( $year, "-", $month, "-01T00:00:00" ))

return xs:date($eerste-volgende-maand - xs:dayTimeDuration( "P1D"))
};


(: neem de eerste zorgaanbieder uit de context :)
let $za := ./zorgaanbieder[1],
    $type := "TEST",
    $dur := local:get-duration( $duur, "P1M" ),
    $batch := $za/batch[1],
    $eind-datum := local:einde-maand(xs:date( $batch/einddatumAangeleverdePeriode ) + $dur ),
    $periode := local:get-duration( $aanleverperiode, $batch/aanleverperiode ),
    
    $andere-batch-elts := $batch/*[not(exists(index-of( ('aanleverperiode', 'einddatumAangeleverdePeriode'), local-name())))],
    
    (: xquery element constructor :)
    $new-batch := element { 'batch' } { (), 
                    ($andere-batch-elts, 
                    element { 'aanleverperiode' } { $periode },
                    element { 'einddatumAangeleverdePeriode' } { $eind-datum })
                  },
    
    (: oude truc om 0-padded strings te maken :)
    $volgnr := xs:integer( $za/target/@volgnummer ) + 1001,

    $new-target := element { 'target' } { 
                    attribute { 'type' } { $type } 
                    union attribute { 'volgnummer' } { substring(xs:string($volgnr), 2) },
                    ($za/target/tmp, $za/target/ftp)
                    } 
        
return 
    element { 'zorgaanbieder' } { $za/@*,
            ($za/naam, $new-batch, $new-target)
            }
      