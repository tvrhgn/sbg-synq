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

(: score niet ongeldig; datum niet leeg; instrument gevonden in bibliotheek; score in range en aantal items correct als items bekend zijn 
 and $score ge data($instr/schaal/@min) 
  and $score le data($instr/schaal/@max)
  and (if ( exists( $instr/@aantal-vragen) ) 
       then fn:count($meting/Item) eq xs:integer( $instr/@aantal-vragen ) 
       else true() ) :)

declare function sbgm:meting-geldig( $meting as element(meting), $instr as element(sbgi:instrument)?, $score as xs:double )
as xs:boolean
{
  not( $score lt 0) 
  and $score ge xs:double($instr/schaal/@min) 
 
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


declare function sbgm:maak-sbg-item($item as element(item)) 
as element(sbggz:Item)
{
element { 'sbggz:Item' } {  
          sbgm:splits-atts-sbg( $sbgm:item-atts, $item/@*)
        }
};


(:  :)
declare function sbgm:maak-sbg-meting($meting as element(meting)*, $instr as element(sbgi:instrument)?) 
as element(sbgm:Meting)
{
element 
    { 'sbgm:Meting' } 
    { sbgm:splits-atts-sbg($sbgm:meting-atts, $meting/@*[not(exists(index-of( ('gebruiktMeetinstrument', 'totaalscoreMeting', 'typeRespondent'), local-name())))])  
      union sbgm:instrument-att($meting/@gebruiktMeetinstrument, $instr)
      union sbgm:score-att($meting,$instr)
      union sbgm:respondent-att($meting,$instr)
      ,
      for $item in $meting/item
      return sbgm:maak-sbg-item($item)
    }
};

declare function sbgm:sbg-metingen($metingen as element(meting)*, $instr-lib as element(sbgi:instrument)+) 
as element(sbgm:Meting)*
{
for $m in $metingen
let $instr := $instr-lib[@code eq $m/@gebruiktMeetinstrument]  
return sbgm:maak-sbg-meting($m, $instr)
};

