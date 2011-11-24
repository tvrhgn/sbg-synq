module namespace sbgi = "http://sbg-synq.nl/sbg-instrument";
(: TODO meervoudige schalen, uitzonderingen, controles :)

(: voeg hier en daar extra attributen toe voor visuele controle :)
declare variable $sbgi:debug := false();

(: selecteer de items van de schaal en bereken de score voor elk item :)
(: TODO missed items :)
declare function sbgi:schaal-score( $schaal as element(schaal)?, $items as element()*) as element()*
{
  for $item in $schaal/score-items/item
  let $select :=  $items[itemnummer/text() = $item/text()],
      $ruwe-score := if ( $select/score/text() ) then $select/score/text() cast as xs:double else -1,
      $omscoren := $item/@omscoren = 'true',
      $score := if ( $omscoren ) then fn:abs($ruwe-score - ($item/@min + $item/@max)) else $ruwe-score,
      $debug-atts := if ( $sbgi:debug ) then attribute { 'omscoren' } { $omscoren } union attribute { 'ruwe-score' } { $ruwe-score } else ()
      return element { 'score' } { attribute { 'itemnummer' } { $item/text() }, $debug-atts, $score }
};


declare function sbgi:schaal-functie( $schaal as element(schaal), $items as node()+ ) as xs:double
{
if ( $schaal/berekening/@functie = 'sum' ) 
then fn:sum(sbgi:schaal-score($schaal, $items))
else if ( $schaal/berekening/@functie = 'avg' )
then fn:avg(sbgi:schaal-score($schaal, $items))
else -1
};

(: bereken de totaalscore door de juiste elementen te selecteren en de juiste functie toe te passen :)
(: de items die worden meegegeven moeten een itemnummer en een score element hebben :)
declare function sbgi:bereken-totaalscore-sbg( $instr as element(instrument)?, $items as node()* ) as xs:double
{
let  $schaal := $instr//schaal[@definitie='sbg'][1] 
return if ( exists( $schaal ) and count($items) gt 0 ) 
       then sbgi:schaal-functie( $schaal, $items )  
       else -1
};
(: deprecated :)
declare function sbgi:bereken-totaalscore( $instr as element(instrument)?, $items as node()* ) as xs:double
{
sbgi:bereken-totaalscore-sbg($instr,$items)
};


(: ---- parsen instrument data                         --- :)
(: onderstaande code hoort bij het laden parsen van het bron sbg-instrument bestand :)
(: model: score is een getal >= 0 en itemnummer is een integer > 0 :)

(: rationale: maakt het editen van de instrumenten-bibliotheek gemakkelijker; bezwaar: bron van verduistering :)
(: punt is dat de instrument-bibliotheek nog met de hand bijgehouden wordt... :)

(: hulp functie om string '1, 2, 3, 4' om te zetten in een lijst van elementen 'item' :)
declare function sbgi:expand-items( $item-str as text()?) 
	as element(item)*
{
  for $it in fn:tokenize($item-str, ' ?,')
  return <item>{fn:normalize-space($it)}</item>
};


(: lees het brondocument van instrumenten in en bereid de instrumenten voor :)
(: grotendeels een kopie van het brondocument :)
declare function sbgi:laad-instrumenten( $doc as element(sbg-instrumenten) )
as element(instrument)*
{
for $instr in $doc//instrument
let $item-str := $instr/schaal/items/text(),
$all := $instr/schaal/items/@all = 'true',
$functie := fn:normalize-space($instr/schaal/berekening/@functie),
$score-items := if ( $all ) then 
                <score-items all="true">{
                    for $ix in 1 to xs:integer($instr/@aantal-vragen)
                    return <item>{$ix}</item>
                }</score-items> 
                else <score-items bron-tekst="{$item-str}">{sbgi:expand-items($item-str)}</score-items>,
$omscoren := $instr/schaal/omscoren,
(: TODO for each; ondersteun verschillende score ranges op een item :)
$omscoor-items :=  <omscoor-items>{sbgi:expand-items($omscoren/text())}</omscoor-items>,
$nw-score-items := <score-items>{for $it in $score-items//item
                    let $omscoren := exists($omscoor-items//item[./text()=$it/text()]),
                        $att := if ($omscoren) then attribute { 'omscoren' } { 'true' } else ()
                    return element { 'item' } { $att, $it/text() }
                    }</score-items>
    return  element { 'instrument' } { $instr/@*,
       $instr/naam,
       $instr/verwijzing,
       element { 'schaal' } { $instr/schaal/@*, $nw-score-items, $instr/schaal/berekening}
    }
};

