(: importeer sbg-synq modules 
:)
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';


let $instr-oq := 
  <instrument code="OQ45-sd" aantal-vragen="45">
    <naam>OQ-45 Outcome Questionaire</naam>
    <schaal min="0" max="100" code="SD">
      <items>2, 3, 5, 6, 8, 9, 10, 11, 13 , 15, 22, 23, 24 , 25, 27, 29, 31
      , 33, 34, 35, 36, 40, 41, 42, 45</items>
      <omscoren min="0" max="4">13, 24, 31</omscoren>
      <berekening functie="sum">Sommatie van de betreffende items
      </berekening>
    </schaal>
  </instrument>

let $instr-bsi := 
  <instrument code="BSI" aantal-vragen="53" typeRespondent="01">
    <naam>BSI Brief Symptom Inventory</naam>
    <schaal min="0" max="4" code="TOT">
      <items all="true">1 tot 53</items>
      <berekening functie="avg">
    Gemiddelde van alle items
      </berekening>
    </schaal>
  </instrument>

 let $bsi := 
 <Meting koppelnummer="10103820" gebruiktMeetinstrument="BSI" datum="2012-02-29" aardMeting="3" meting-id="80963"><Item itemnummer="1" score="1"/><Item itemnummer="10" score="3"/><Item itemnummer="11" score="3"/><Item itemnummer="12" score="1"/><Item itemnummer="13" score="1"/><Item itemnummer="14" score="1"/><Item itemnummer="15" score="2"/><Item itemnummer="16" score="1"/><Item itemnummer="17" score="2"/><Item itemnummer="18" score="1"/><Item itemnummer="19" score="0"/><Item itemnummer="2" score="2"/><Item itemnummer="20" score="2"/><Item itemnummer="21" score="0"/><Item itemnummer="22" score="1"/><Item itemnummer="23" score="4"/><Item itemnummer="24" score="1"/><Item itemnummer="25" score="0"/><Item itemnummer="26" score="2"/><Item itemnummer="27" score="1"/><Item itemnummer="28" score="0"/><Item itemnummer="29" score="0"/><Item itemnummer="3" score="1"/><Item itemnummer="30" score="3"/><Item itemnummer="31" score="0"/><Item itemnummer="32" score="1"/><Item itemnummer="33" score="0"/><Item itemnummer="34" score="0"/><Item itemnummer="35" score="2"/><Item itemnummer="36" score="1"/><Item itemnummer="37" score="4"/><Item itemnummer="38" score="3"/><Item itemnummer="39" score="1"/><Item itemnummer="4" score="1"/><Item itemnummer="40" score="1"/><Item itemnummer="41" score="1"/><Item itemnummer="42" score="1"/><Item itemnummer="43" score="1"/><Item itemnummer="44" score="0"/><Item itemnummer="45" score="2"/><Item itemnummer="46" score="1"/><Item itemnummer="47" score="1"/><Item itemnummer="48" score="2"/><Item itemnummer="49" score="3"/><Item itemnummer="5" score="1"/><Item itemnummer="50" score="2"/><Item itemnummer="51" score="2"/><Item itemnummer="52" score="2"/><Item itemnummer="53" score="1"/><Item itemnummer="6" score="1"/><Item itemnummer="7" score="3"/><Item itemnummer="8" score="0"/><Item itemnummer="9" score="0"/></Meting>

let $instr-test := 
  <instrument code="TEST" aantal-vragen="10" typeRespondent="01">
    <naam>sbg-synq test instrument</naam>
    <schaal min="10" max="50" code="TOT">
      <items all="true">1 tot 10</items>
      <omscoren min="1" max="5">7, 8</omscoren>
      <berekening functie="sum">som</berekening>
    </schaal>
  </instrument>
  
 let $meting-1 := 
 <Meting koppelnummer="10103820" gebruiktMeetinstrument="TEST" datum="2012-02-29" meting-id="80963">
 <Item itemnummer="1" score="1"/>
 <Item itemnummer="2" score="1"/>
 <Item itemnummer="3" score="1"/>
 <Item itemnummer="4" score="1"/>
 <Item itemnummer="5" score="1"/>
 <Item itemnummer="6" score="1"/>
 <Item itemnummer="7" score="1"/>
 <Item itemnummer="8" score="1"/>
 <Item itemnummer="9" score="1"/>
 <Item itemnummer="10" score="1"/>
 </Meting>
  
  

let $instr := sbgi:laad-instrument($instr-test),
    $itemscores := sbgi:item-scores($meting-1,$instr),
    
      
    $meting := $meting-1,
    $score := sbgi:bereken-score($meting,$instr),
    
    $m := sbgm:maak-sbg-meting($meting, $instr)

return  $m

(:
count($itemscores)
$meting//Item[index-of($score-items, @itemnummer ) gt 0]
count()
53
count(data($instr/@score-items))
1 dus
<doc>{$instr/@score-items}</doc>
 $meting//Item[index-of($instr/@score-items, @itemnummer ) gt 0]
 :)
