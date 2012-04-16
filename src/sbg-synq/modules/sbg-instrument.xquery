module namespace sbgi = "http://sbg-synq.nl/sbg-instrument";
(: TODO meervoudige schalen :)

(: deprecated :)
(: bereken de totaalscore door de juiste elementen te selecteren en de juiste functie toe te passen :)
(: de items die worden meegegeven moeten een itemnummer en een score element hebben :)
declare function sbgi:bereken-totaalscore-sbg( $instr as element(instrument)?, $items as node()* ) as xs:double
{
-4
};

(: deprecated :)
declare function sbgi:bereken-totaalscore( $instr as element(instrument)?, $items as node()* ) as xs:double
{
sbgi:bereken-totaalscore-sbg($instr,$items)
};


(: verwerk Items die omgescoord moeten worden :)
declare function sbgi:item-omscores( $items as element(item)*, $min as xs:double?, $max as xs:double? )
as xs:double*
{
for $i in $items
let $ruwe-score := if ( $i/@score castable as xs:double ) then xs:double($i/@score) else -1
return fn:abs($ruwe-score - ($min + $max))
};

(: haal scores op van items :)
declare function sbgi:item-scores( $meting as element(meting), $instr as element(sbgi:instrument) )
as xs:double*
{
let $items :=     $meting/item[@itemnummer][index-of(tokenize($instr/@score-items, ' '), @itemnummer ) gt 0],
    $o-items :=   $meting/item[@itemnummer][index-of(tokenize($instr/@omscoor-items, ' '), @itemnummer ) gt 0]
return ( 
    for $i in ($items except $o-items)
    return xs:double($i/@score)
    ,
    sbgi:item-omscores($o-items, data($instr/@item-min), data($instr/@item-max))
    )
};

(: pas functie toe op scores :)
(: score -3 is een indicator dat de functie bekend is :)
declare function sbgi:instr-functie( $scores as xs:double*, $functie as xs:string ) 
as xs:double
{
if ( $functie = 'sum' ) 
then fn:sum($scores)
else if ( $functie = 'avg' )
then fn:avg($scores)
else -3
};


(: bereken de totaalscore door de juiste elementen te selecteren en de juiste functie toe te passen :)
(: score -2 is een indicator dat de score niet berekend kan worden: geen scores of geen functie :)
(: of is het beter het berekenen van de score te weigeren als bepaalde asserts fail :)
declare function sbgi:bereken-score( $meting as element(meting), $instr as element(sbgi:instrument)? ) as xs:double
{
let  $scores := sbgi:item-scores($meting, $instr),
    $functie := data($instr/schaal/@functie)
return if ( exists($functie) and count($scores) gt 0 ) 
       then sbgi:instr-functie( $scores, $functie )  
       else -2
};

(: hulp-functie om de handmatig gewijzigde itemstrings te normalizeren :)
declare function sbgi:schaal-items( $item-str as xs:string? ) 
as xs:string*
{
for $s in fn:tokenize(normalize-space($item-str), ' ?,') 
return replace($s, "\s", "")
};

(: geef een compacte en genormaliseerde weergave van een instrument uit het definitiebestand :)
(: gebruik controle-attribuut bij definieren van instrumenten :)
declare function sbgi:laad-instrument( $instr as element(instrument) )
as element(sbgi:instrument)
{   (: voorkeur voor sbg-definitie, anders schaal 1 :)
    let $schaal := ($instr/schaal[@definitie eq 'sbg'], $instr/schaal[1])[1],
        $score-items := if ( data($schaal/items/@all) eq 'true' and $instr/@aantal-vragen castable as xs:integer ) 
                    then 
                        for $ix in 1 to xs:integer($instr/@aantal-vragen)
                        return xs:string($ix)
                    else 
                        sbgi:schaal-items($schaal/items/text())
                    ,
     
                        
     $omscoor-items :=  sbgi:schaal-items($schaal/omscoren/text()),
     $omscoren := count( $omscoor-items ) gt 0,
     
     $omscoor-atts:= if ( $omscoren ) then (
                        attribute { 'item-min' } { xs:double($schaal/omscoren/@min) }, 
                        attribute { 'item-max' } { xs:double($schaal/omscoren/@max) }  
                        ) 
                        else (),
     $controle := if ( $omscoren and not($schaal/omscoren/@min and $schaal/omscoren/@max) ) 
                  then 'omscoren ongeldig'
                  else if ( $schaal/items/@all eq 'true' and not( $instr/@aantal-vragen castable as xs:integer ) )
                      then 'items niet af te leiden'
                      else if ( not( $schaal/@min and $schaal/@max ) ) then 'schaal grenzen niet bekend'
                      else 'instrument geldig'
return  
   element { 'sbgi:instrument' } 
           { $instr/@*
             union attribute { 'controle' } { $controle }
             union attribute { 'score-items' } { $score-items }
             union attribute { 'omscoor-items' } { $omscoor-items }
             union $omscoor-atts
             ,
             element { 'schaal' } 
                     { $instr/schaal/@*
                      union $instr/schaal/berekening/@functie
                      
                     }
           }
};

(: lees het brondocument van instrumenten in en bereid de instrumenten voor :)
declare function sbgi:laad-instrumenten( $instrs as element(instrument)* )
as element(sbgi:instrument)*
{
for $instr in $instrs
return sbgi:laad-instrument($instr)
};

