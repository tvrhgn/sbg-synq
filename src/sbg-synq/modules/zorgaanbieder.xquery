module namespace sbgza = "http://sbg-synq.nl/zorgaanbieder";
(: voorstelling van de zorgaanbieder; batch-instellingen en document-verwijzingen worden hier verwerkt :)

(: get-collection(): zoek een document adhv verwijzing in stuur-bestand :)
(: retourneer een element voor gammelijke toegang tot de collecties :)
(: NB het is van belang dat de collectie namen niet overlappen met de element-namen van zorgaanbieder :)
declare function sbgza:get-collection( $zorgaanbieder as element(zorgaanbieder), $name as xs:string ) as element()*
{
    let $ref := $zorgaanbieder//collection[@name=$name][1]
    return 
        element { $name } 
                { (), 
                  doc(data($ref/@uri))//*[local-name()=data($ref/@elt)] 
                }
};

(: maak een elt met geldige datums voor de batch; 
  val terug op default de 3 maanden tot laatste einde maand voor datum
    
  $ts := data($batch/@datumCreatie),
  laten vallen? is nu technische export-datum; systeemafhankelijk
  :)
declare function sbgza:batch-gegevens($za as element()) 
as element(sbgza:batch-gegevens) {
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
    
return 
    element { 'sbgza:batch-gegevens' }
            {   attribute { 'agb-code' } {data($za/@code)}
                union attribute { 'zorgaanbieder' } {$za/*[local-name() eq 'naam']/text()}
                union attribute { 'startdatum' } {$start}
                union attribute { 'einddatum' } {$eind}
                union attribute { 'datumCreatie' } {$ts}, ()
             }
};



(: hieronder de gedefinieerde standaard collecties :)
declare function sbgza:build-zorgaanbieder( $za as element(zorgaanbieder) ) as element(sbgza:zorgaanbieder)
{
let $zorgdomeinen :=  sbgza:get-collection($za, 'sbg-zorgdomeinen'),
    $instr-lib  :=  sbgza:get-collection($za, 'instrumenten')

    return element { 'sbgza:zorgaanbieder' } 
                   { $za/@*, 
                    ( $za/*, $zorgdomeinen, $instr-lib)
                   }     

};

