(: XQuery main module :)

declare variable $duur as xs:string external;
declare variable $aanleverperiode as xs:string external;


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
    $month-i := if ( $month-p eq 12 ) then 1 else $month-p + 1,
    $year := if ( $month-p eq 12 ) then year-from-date($dat) + 1 else year-from-date($dat),
    
    $month := if ( $month-i lt 10 ) then concat( "0", $month-i) else xs:string( $month-i),
    $dat1 := xs:dateTime( concat( $year, "-", $month, "-01T00:00:00" ))

return xs:date($dat1 - xs:dayTimeDuration( "P1D"))
};



let $za := ./zorgaanbieder,
    $dur := local:get-duration( $duur, "P1M" ),
    $batch := $za/batch[1],
    $eind-datum := local:einde-maand(xs:date( $batch/einddatumAangeleverdePeriode ) + $dur ),
    $periode := local:get-duration( $aanleverperiode, $batch/aanleverperiode ),
    $andere-batch-elts := $batch/*[not(exists(index-of( ('aanleverperiode', 'einddatumAangeleverdePeriode'), local-name())))],
    $new-batch := element { 'batch' } { (), 
                    ($andere-batch-elts, 
                    element { 'aanleverperiode' } { $periode },
                    element { 'einddatumAangeleverdePeriode' } { $eind-datum })
                  },
    
    
    
    $volgnr := xs:integer( $za/target/@volgnummer ) + 1001,
    $type := "TEST",
    $new-target := element { 'target' } { 
                    attribute { 'type' } { $type } 
                    union attribute { 'volgnummer' } { substring(xs:string($volgnr), 2) },
                    ($za/target/tmp, $za/target/ftp)
                    } 
        
return 
    element { 'zorgaanbieder' } { $za/@*,
            ($za/naam, $new-batch, $new-target)
            }
      