module namespace sbgm = "http://sbg-synq.nl/sbg-metingen";

import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at 'sbg-instrument.xquery';
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";

(: deze atts worden meteen in de doel-ns geplaatst :)
declare variable $sbgm:meting-atts := ('datum','aardMeting');
(: 'typemeting' wordt pas bepaald in sbg-epd :) 
(: 'typeRespondent','gebruiktMeetinstrument','totaalscoreMeting', 'metingReserve01' :)

(: items worden alleen maar overgeheveld :)
declare variable $sbgm:item-atts := ('itemnummer', 'score');


declare function sbgm:splits-atts-sbg($def as xs:string+, $nds as node()*) 
as attribute()* 
{
    for $att in $nds
    let $name := local-name($att),
        $q-name := if ( exists(index-of( $def, $name ))) 
                      then concat('sbggz:', $name )  
                      else concat( 'sbgm:', $name )
    return 
        attribute { $q-name } 
                  { data($att) }
};

(: score niet ongeldig; datum niet leeg; 
instrument gevonden in bibliotheek; 
score in range en aantal items correct als 80% van de items bekend zijn
 
:)

declare function sbgm:meting-geldig( $meting as element(meting), $instr as element(sbgi:instrument)?, $score as xs:double )
as xs:boolean
{
  not( $score lt 0) 
  and $score ge (xs:double($instr/schaal/@min), 0)[1]
  and $score le (xs:double($instr/schaal/@max), 10000)[1]
   
};

(: construeer een attribuut typeRespondent op basis van input gegevens  meting en geselecteerd instrument
als de meting een element typeRespondent heeft: gebruik die waarde,
als het instrument een @typeRespondent heeft: gebruik dat als default
maak anders geen attribuut aan ==> meting ongeldig  :) 
declare function sbgm:respondent-att($meting as element(meting), $instr as element(sbgi:instrument)? ) 
as attribute()*
{
if ( $meting/@typeRespondent )
then attribute { 'sbggz:typeRespondent' } { data($meting/@typeRespondent) }
else if ( $instr/@typeRespondent ) 
     then ( attribute { 'sbggz:typeRespondent' } {  data($instr/@typeRespondent) },  attribute { 'sbgm:instrument-respondent' } { true() } )
     else ()
};

(: neem de totaalscore over uit de meting of bereken hem adhv de items :)
declare function sbgm:score-att($meting as element(meting), $instr as element(sbgi:instrument)? ) 
as attribute()* 
{
let $score := if ( $meting/@totaalscoreMeting castable as xs:double ) 
              then xs:double($meting/@totaalscoreMeting)
              else  sbgi:bereken-score($meting,$instr)
              ,
    $geldig := sbgm:meting-geldig( $meting, $instr, $score ),
    $score-geldig-att := if ( $geldig ) then () else attribute { 'sbgm:score-ongeldig' } { 'true' }
return attribute { 'sbggz:totaalscoreMeting'} { $score }
       union $score-geldig-att
 
};

(: neem 'sbg-code' als het instrument die heeft, anders 'code' 
dit maakt het mogelijk meer versies van hetzelfde instrument op te nemen in de instrumenten-bibliotheek:)
declare function sbgm:instrument-att( $instr-code as xs:string, $instr as element(sbgi:instrument)? ) 
as attribute()* 
{
let $code := (data($instr/@sbg-code), data($instr/@code))[1]
return
if ( $code ) 
then attribute { 'sbggz:gebruiktMeetinstrument' } { $code  }
else 
  attribute { 'sbgm:instrument-ongeldig' } { true() }
  union attribute { 'sbgm:gebruiktMeetinstrument' } { $instr-code } 
};


(: in dit model zijn de item-scores altijd integers :)
declare function sbgm:maak-sbg-item($item as element(item), $instr as element(sbgi:instrument)?) 
as element(sbggz:Item)?
{
let $score := (xs:integer($item/@score), -1)[1],
    $missed-att := 
        if ( $score lt xs:integer($instr/@item-min )
            or $score gt xs:integer($instr/@item-max ) ) 
        then attribute { 'sbgm:missed' } { true() }
        else ()
return
    if ( $item/@itemnummer ) (: items zonder nummer kunnen achterwege blijven :) 
    then
        element { 'sbggz:Item' } {  
            sbgm:splits-atts-sbg( $sbgm:item-atts, $item/@*)
            union $missed-att
        }
else ()
};

(: vul de item-scores aan op basis van gemiddelde; alleen geldig bij som-type totaal-score
eis is dat minimaal 80% van de items geldig is
score-att wordt hier opnieuw opgebouwd
 :) 
declare function sbgm:imputeer-score( $score-att as attribute()*, $cnt-missed as xs:integer, $cnt-items as xs:integer )
as attribute()* 
{
 let $score := xs:double($score-att[local-name() eq 'totaalscoreMeting'])
 return 
    attribute { 'sbggz:totaalscoreMeting' } { ($score div ( $cnt-items - $cnt-missed )) * $cnt-items }
    union $score-att[local-name() ne 'totaalscoreMeting']
    union attribute { 'sbgm:geimputeerd' } { 'true' }
};

(:  :)
declare function sbgm:maak-sbg-meting($meting as element(meting)*, $instr as element(sbgi:instrument)?) 
as element(sbgm:Meting)
{
let $items := for $item in tokenize( $instr/@score-items, ' ' )
              let $it := $meting/item[@itemnummer eq $item]
              return if ( $it ) 
                     then sbgm:maak-sbg-item($it, $instr)
                     else 
                        element { 'sbggz:Item' } {
                            attribute { 'sbggz:itenmummer' } { $item }
                            union attribute { 'sbgm:missed' } { true() } 
                        }
        ,
     $cnt-missed := count($items[@sbgm:missed]),
     $cnt-items := xs:integer($instr/@aantal-items), 
     $missed-perc := if ( exists($items[@sbgm:missed]))  
                     then round( 100 *  $cnt-missed div $cnt-items )
                     else 0,
     
     $missed-att := if ( $missed-perc gt 0 )  
                    then attribute { 'sbgm:items-missed-perc' } { $missed-perc }
                    else (),
                    
     $missed-imputeer := $missed-perc gt 0 and $missed-perc le 80,
     $missed-ongeldig-att := if ( $missed-perc gt 80 )
            then attribute  { 'sbgm:te-veel-items-ongeldig' } { true() }
            else (),
 
    $score-att0 := sbgm:score-att($meting,$instr),
    $score-att := if ( $missed-imputeer and contains( $instr/schaal/@functie, 'sum' )) 
        then sbgm:imputeer-score( $score-att0, $cnt-missed, $cnt-items ) 
        else $score-att0
             
return       
    element 
    { 'sbgm:Meting' } 
    { sbgm:splits-atts-sbg($sbgm:meting-atts, $meting/@*[not(exists(index-of( ('gebruiktMeetinstrument', 'totaalscoreMeting', 'typeRespondent'), local-name())))])  
      union sbgm:instrument-att($meting/@gebruiktMeetinstrument, $instr)
      union $score-att
      union sbgm:respondent-att($meting,$instr)
      union $missed-att
      union $missed-ongeldig-att
      ,
      $items
    }
};

declare function sbgm:sbg-metingen($metingen as element(meting)*, $instr-lib as element(sbgi:instrument)+) 
as element(sbgm:Meting)*
{
for $m in $metingen
let $instr := $instr-lib[@code eq $m/@gebruiktMeetinstrument]  
return sbgm:maak-sbg-meting($m, $instr)
};

