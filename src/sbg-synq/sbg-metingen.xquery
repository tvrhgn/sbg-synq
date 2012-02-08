module namespace sbgm = "http://sbg-synq.nl/sbg-metingen";

import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at 'sbg-instrument.xquery';

declare function sbgm:meting-geldig( $meting as node(), $items as node()*, $instr as element(instrument)?, $score as xs:double )
as xs:boolean
{
  (: score niet ongeldig; datum niet leeg; instrument gevonden in bibliotheek; score in range en aantal items correct als items bekend zijn:)
  not( $score = -1)
  and $meting/datum castable as xs:date
  and $instr 
  and $score gt ( xs:double(data($instr/schaal/@min)) -1 ) 
  and $score lt ( xs:double(data($instr/schaal/@max)) + 1)
  and (if ( $items ) 
       then fn:count($items) = xs:integer( $instr/@aantal-vragen ) 
       else true() )
};

(: wordt nog niet gebruikt :)
declare function sbgm:meting-item-geldig( $metingdetail as node(), $instr as element(instrument)) 
as xs:boolean
{
  (: score is een getal > 0 :)
  $metingdetail/score castable as xs:double
  and xs:double($metingdetail/score) gt -1 
}; 

(: construeer een attribuut typeRespondent op basis van input gegevens  meting en geselecteerd instrument
als de meting een element typeRespondent heeft: gebruik die waarde,
als het instrument een @typeRespondent heeft: gebruik dat als default
maak anders geen attribuut aan ==> meting ongeldig
 :) 
declare function sbgm:respondent-att($meting as node(), $instr as element(instrument)? ) 
as attribute()? 
{
if ( $meting/typeRespondent )
then attribute { 'typeRespondent' } { $meting/typeRespondent/text() }
else if ( $instr/@typeRespondent ) 
     then attribute { 'typeRespondent' } {  data($instr/@typeRespondent) } 
     else attribute { 'sbgm:geen-respondent' } { true() }
};

(: neem de totaalscore over uit de meting of bereken hem adhv de items :)
declare function sbgm:score-att($meting as node(), $items as node()*, $instr as element(instrument)? ) 
as attribute()* 
{
let $score := if ( $meting/totaalscoreMeting/text() castable as xs:double ) 
              then xs:double($meting/totaalscoreMeting/text())
              else if ( $items )  then sbgi:bereken-totaalscore($instr, $items)
              else -1,
    $geldig := sbgm:meting-geldig( $meting, $items, $instr, $score ),
    $score-geldig-att := if ( $geldig ) then () else attribute { 'sbgm:score-ongeldig' } { 'true' }
return attribute { 'totaalscoreMeting'} { $score }
       union $score-geldig-att
 
};

(: neem 'sbg-code' als het instrument die heeft, anders 'code' 
dit maakt het mogelijk meer versies van hetzelfde instrument op te nemen in de instrumenten-bibliotheek:)
declare function sbgm:instrument-att( $instr-code as xs:string, $instr as element(instrument)? ) 
as attribute()* 
{
let $code := (data($instr/@sbg-code), data($instr/@code))[1]
return
if ( $code ) 
then attribute { 'gebruiktMeetinstrument' } { $code  }
else attribute { 'sbgm:instrument-ongeldig' } { true() }
     union attribute { 'sbgm:gebruiktMeetinstrument' } { $instr-code }
};



(: Items worden aan Metingen gekoppeld via een meting-id; van Metingen wordt de client bekend gemaakt via een koppelnummer :)
declare function sbgm:sbg-metingen($meting as node()*, $metingdetail as node()*, $instrumenten-lib as element(instrument)+) 
as element(Meting)*
{
for $m in $meting
let $items := $metingdetail[meting-id eq $m/meting-id],
    $instr := $instrumenten-lib[@code eq $m/gebruiktMeetinstrument], 
    $instr-att := sbgm:instrument-att($m/gebruiktMeetinstrument, $instr),
      
    $atts := attribute { 'sbgm:meting-id' } { $m/meting-id/text() } 
        union attribute { 'sbgm:koppelnummer'} {$m/koppelnummer/text()} 
        union attribute { 'datum'} {$m/datum/text()}
        union attribute { 'aardMeting' } { $m/aardMeting/text() }
        union $instr-att
        union sbgm:score-att($m,$items,$instr)
        union sbgm:respondent-att($m,$instr)
return 
element { 'Meting' } { $atts,   
    for $md in $items[itemnummer/text()]
		  (: controle nog niet relevant 
		  let $item-geldig := sbgm:meting-item-geldig($md, $instr),
		    $geldig-att := if ( $item-geldig ) then () else attribute { 'sbgm:geldig' } { 'false' }
		    :)
	  (: niet altijd een getal :)
	order by xs:integer(replace($md/itemnummer, "[^0-9.-]", "")), $md/itemnummer
	return 
	element { 'Item' } {
	attribute { 'itemnummer' } {$md/itemnummer} 
	union attribute { 'score' } { $md/score }
	 (: union $geldig-att :)
	}
}
};
