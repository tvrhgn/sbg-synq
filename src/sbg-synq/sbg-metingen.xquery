module namespace sbgm = "http://sbg-synq.nl/sbg-metingen";

import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at 'sbg-instrument.xquery';
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";

(: deze atts worden meteen in de doel-ns geplaatst :)
declare variable $sbgm:meting-atts := ('datum','aardMeting');
(: 'typemeting' wordt pas bepaald in sbg-epd :) 
(: 'typeRespondent','gebruiktMeetinstrument','totaalscoreMeting', 'metingReserve01' :)

(: items worden alleen maar overgeheveld :)
declare variable $sbgm:item-atts := ('item','itemnummer', 'score');


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

declare function sbgm:meting-geldig( $meting as element(Meting), $instr as element(sbgi:instrument)?, $score as xs:double )
as xs:boolean
{
  not( $score lt 0)
  and $score ge xs:double($instr/schaal/@min) 
 
};

(: construeer een attribuut typeRespondent op basis van input gegevens  meting en geselecteerd instrument
als de meting een element typeRespondent heeft: gebruik die waarde,
als het instrument een @typeRespondent heeft: gebruik dat als default
maak anders geen attribuut aan ==> meting ongeldig  :) 
declare function sbgm:respondent-att($meting as element(Meting), $instr as element(sbgi:instrument)? ) 
as attribute()*
{
if ( $meting/@typeRespondent )
then attribute { 'sbggz:typeRespondent' } { data($meting/@typeRespondent) }
else if ( $instr/@typeRespondent ) 
     then ( attribute { 'sbggz:typeRespondent' } {  data($instr/@typeRespondent) },  attribute { 'sbgm:instrument-respondent' } { true() } )
     else ()
};

(: neem de totaalscore over uit de meting of bereken hem adhv de items :)
declare function sbgm:score-att($meting as element(Meting), $instr as element(sbgi:instrument)? ) 
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


declare function sbgm:maak-sbg-item($item as element(Item)) 
as element(sbggz:Item)
{
element { 'sbggz:Item' } {  
          $item/@*
        }
};


(:  :)
declare function sbgm:maak-sbg-meting($meting as element(Meting)*, $instr as element(sbgi:instrument)?) 
as element(sbgm:Meting)
{
element 
    { 'sbgm:Meting' } 
    { sbgm:splits-atts-sbg($sbgm:meting-atts, $meting/@*[not(exists(index-of( ('gebruiktMeetinstrument', 'totaalscoreMeting', 'typeRespondent'), local-name())))])  
      union sbgm:instrument-att($meting/@gebruiktMeetinstrument, $instr)
      union sbgm:score-att($meting,$instr)
      union sbgm:respondent-att($meting,$instr)
      ,
      for $item in $meting/Item
      return sbgm:maak-sbg-item($item)
    }
};

declare function sbgm:sbg-metingen($metingen as element(Meting)*, $instr-lib as element(sbgi:instrument)+) 
as element(sbgm:Meting)*
{
for $m in $metingen
let $instr := $instr-lib[@code eq $m/@gebruiktMeetinstrument]  
return sbgm:maak-sbg-meting($m, $instr)
};



(: stap 1: combineer Meting en Item tot Meting met Item
dit is dus de eerste join; hier worden ook de elementen omgezet in atts
Het is veel efficienter dit eerst te doen
 :)
declare function sbgm:elt-filter-atts( $elt as element(), $atts as xs:string* )
{
  element { name($elt) }
  { $elt/@*[not(index-of( local-name(), $atts) gt 0)],
  $elt/text()
}
};

declare function sbgm:build-atts( $row as element() ) as attribute()* {
  for $elt in $row/*
  return attribute { local-name($elt) } { data($elt) }
};

declare function sbgm:build-Item( $mi-row as element() ) as element(Item) {
  element { 'Item' } { sbgm:build-atts( $mi-row ) }
};

declare function sbgm:build-Meting( $m-row as element(), $mi-rows as element()* ) as element(Meting) {
  let $atts := sbgm:build-atts( $m-row )
  return 
    element { 'Meting' } 
    { $atts,  
    for $mi in $mi-rows 
    return sbgm:elt-filter-atts( sbgm:build-Item( $mi ), 'meting-id' )
    }
};

declare function sbgm:build-Metingen( $m-rows as element()*, $mi-rows as element()* ) as element(Meting)*
{
for $mt in $m-rows
let $mi := $mi-rows[meting-id/text() eq $mt/meting-id/text()]
return sbgm:build-Meting( $mt, $mi )
};