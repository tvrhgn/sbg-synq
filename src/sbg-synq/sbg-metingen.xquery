module namespace sbgm = "http://sbg-synq.nl/sbg-metingen";

import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at 'sbg-instrument.xquery';

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


declare function sbgm:meting-item-geldig( $metingdetail as node(), $instr as element(instrument)) as xs:boolean
{
  (: score is een getal > 0 :)
  $metingdetail/score castable as xs:double
  and xs:double($metingdetail/score) gt -1 
}; 


(: Items worden aan Metingen gekoppeld via een meting-id; van Metingen wordt de client bekend gemaakt via een koppelnummer :)
declare function sbgm:sbg-metingen($meting as node()*, $metingdetail as node()*, $instrumenten-lib as element(instrument)+) 
as element(Meting)*
  {
    for $m in $meting
    let $items := $metingdetail[meting-id=$m/meting-id],
      $instr := $instrumenten-lib[@code=$m/gebruiktMeetinstrument],
      $score := if ( $m/totaalscoreMeting/text() castable as xs:double ) 
                then xs:double($m/totaalscoreMeting/text() ) 
                else sbgi:bereken-totaalscore($instr, $items),
      $geldig := sbgm:meting-geldig( $m, $items, $instr, $score )
      return 
      
      <Meting sbgm:meting-id="{$m/meting-id}" 
            sbgm:koppelnummer="{$m/koppelnummer}" 
            sbgm:geldig="{$geldig}"
            datum="{$m/datum}" 
            gebruiktMeetinstrument="{$m/gebruiktMeetinstrument}" 
            totaalscoreMeting="{$score}">
	{
	  for $md in $items[itemnummer/text()]
	  (: niet altijd een getal; order by xs:integer($md/itemnummer) :)
	  return 
	  <Item sbgm:geldig="{sbgm:meting-item-geldig($md, $instr)}" itemnummer="{$md/itemnummer}" score="{($md/score, $md/itemscore)[1]}"/>  (: PoC-data gebruikt abus. itemscore :)
	}
  </Meting>
};

