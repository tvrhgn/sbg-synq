module namespace sbgm = "http://sbg-synq.nl/sbg-metingen";

import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at 'sbg-instrument.xquery';

(: wordt niet gebruikt :)
declare function sbgm:meting-geldig( $meting as node(), $items as node()*, $instr as element(instrument)?, $score as xs:double )
as xs:boolean
{
  (: score niet ongeldig; datum niet leeg; instrument gevonden; aantal items correct :)
  fn:not( $score = -1)
  and $meting/datum castable as xs:date
  and $instr 
  and fn:count($items) = xs:integer( $instr/@aantal-vragen )
  (: and $score gt ( xs:double(data($instr/schaal/@min)) -1 ) 
  and $score lt ( xs:double(data($instr/schaal/@max)) + 1)
  :)
};

(: future: is pas haalbaar als metingen worden gecached tussen verschillende uploads; wordt niet gebruikt :)
declare function sbgm:meting-item-geldig( $metingdetail as node(), $instr as element(instrument)) as xs:boolean
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
declare function sbgm:respondent-att($meting as node(), $instr as element(instrument)? ) as attribute(typeRespondent)? {

if ( $meting/typeRespondent )
then attribute { 'typeRespondent' } { $meting/typeRespondent/text() }
else if ( $instr/@typeRespondent ) 
     then attribute { 'typeRespondent' } {  data($instr/@typeRespondent) } 
     else ()
};

(: neem de totaalscore over uit de meting of bereken hem adhv de items :)
declare function sbgm:score-att($meting as node(), $items as node()*, $instr as element(instrument)? ) 
as attribute(totaalscoreMeting)? {
if ( $meting/totaalscoreMeting/text() castable as xs:double ) 
then  attribute { 'totaalscoreMeting'} {xs:double($meting/totaalscoreMeting/text()) } 
else if ( $items ) 
     then attribute { 'totaalscoreMeting'} {sbgi:bereken-totaalscore($instr, $items)}
     else ()
};

(: neem 'sbg-code' als het instrument die heeft, anders 'code' :)
declare function sbgm:instrument-att( $instr as element(instrument)? ) 
as attribute(gebruiktMeetinstrument)? {
let $code := (data($instr/@sbg-code), data($instr/@code))[1]
return
if ( $code ) 
then attribute { 'gebruiktMeetinstrument' } { $code  }
else ()
};



(: Items worden aan Metingen gekoppeld via een meting-id; van Metingen wordt de client bekend gemaakt via een koppelnummer :)
declare function sbgm:sbg-metingen($meting as node()*, $metingdetail as node()*, $instrumenten-lib as element(instrument)+) 
as element(Meting)*
  {
    for $m in $meting
    let $items := $metingdetail[meting-id eq $m/meting-id],
      $instr := $instrumenten-lib[@code eq $m/gebruiktMeetinstrument],
      $atts := attribute { 'sbgm:meting-id' } { $m/meting-id/text() } 
        union attribute { 'sbgm:koppelnummer'} {$m/koppelnummer/text()} 
        union attribute { 'datum'} {$m/datum/text()}
        union attribute { 'aardMeting' } { $m/aardMeting/text() }
        union sbgm:instrument-att($instr) 
        union sbgm:respondent-att($m,$instr)
      return 
      element { 'Meting' } { $atts,   
		  for $md in $items[itemnummer/text()]
	  (: niet altijd een getal :)
	      order by xs:integer(replace($md/itemnummer, "[^0-9.-]", "")), $md/itemnummer
	      return 
	      element { 'Item' } {
	        attribute { 'itemnummer' } {$md/itemnummer} 
	        union attribute { 'score' } {($md/score, $md/itemscore)[1]}
	       (: PoC-data gebruikt abus. itemscore :)
	       }
	}
  };

