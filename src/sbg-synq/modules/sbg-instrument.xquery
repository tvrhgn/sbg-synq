module namespace sbgi = "http://sbg-synq.nl/sbg-instrument";
(: TODO meervoudige schalen :)

(: instrument werkt met items, niet met Items :)
(: items zijn elementen zonder ns :)
(: verdere verwerking tot sbggz:Items gebeurt in sbg-metingen.xquery :)


(: verwerk items die omgescoord moeten worden :)
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
let $items :=     $meting/item[@itemnummer][exists(index-of(tokenize($instr/@score-items, ' '), @itemnummer ))],
    $o-items :=   $meting/item[@itemnummer][exists(index-of(tokenize($instr/@omscoor-items, ' '), @itemnummer ))]
return ( 
    for $i in ($items except $o-items)
    return xs:double($i/@score)
    ,
    sbgi:item-omscores($o-items, data($instr/@item-omscoor-min), data($instr/@item-omscoor-max))
    )
};

(: honosca heeft zijn eigen manier om missing values te coderen
9 = missed en moet meegenomen worden als 0
:)
declare function sbgi:sum-honosca( $scores as xs:double+ ) 
as xs:double
{
sum( $scores[. ne 9] )
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
else if ( $functie = 'sum-honosca' )
then sbgi:sum-honosca($scores)
else -3
};


(: bereken de totaalscore door de juiste elementen te selecteren en de juiste functie toe te passen :)
(: score -2 is een indicator dat de score niet berekend kan worden: geen scores of geen functie :)
(: of is het beter het berekenen van de score te weigeren als bepaalde asserts fail :)
declare function sbgi:bereken-score( $meting as element(meting), $instr as element(sbgi:instrument)? ) as xs:double
{
let  $scores := sbgi:item-scores($meting, $instr),
    $functie := data($instr//@functie)
return if ( exists($functie) and count($scores) gt 0 ) 
       then sbgi:instr-functie( $scores, $functie )  
       else count($scores)
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
     
     $item-atts := if ( $omscoren ) then (
                        attribute { 'item-omscoor-min' } { xs:double($schaal/omscoren/@min) }, 
                        attribute { 'item-omscoor-max' } { xs:double($schaal/omscoren/@max) }  
                        ) 
                        else
                        ( 
                        if ( $schaal/items/@min ) 
                        then attribute { 'item-min' } { data($schaal/items/@min) }
                        else attribute { 'item-min' } { 0 }
                        ,
                        if ( $schaal/items/@max  ) 
                        then attribute { 'item-max' } { data($schaal/items/@max) }
                        else attribute { 'item-max' } { 10000 }
                        )
                     ,
                     
     $controle := if ( $omscoren and not($schaal/omscoren/@min and $schaal/omscoren/@max) ) 
                  then 'omscoren ongeldig'
                  else if ( $schaal/items/@all eq 'true' and not( $instr/@aantal-vragen castable as xs:integer ) )
                      then 'items niet af te leiden'
                      else if ( not( $schaal/@min and $schaal/@max ) ) then 'schaal grenzen niet bekend'
                      else 'instrument geldig'
return  
   element { 'sbgi:instrument' } 
           { $instr/@*
             union attribute { 'aantal-items' } { count($score-items) + count($omscoor-items) }
             union attribute { 'controle' } { $controle }
             union attribute { 'score-items' } { $score-items }
             union attribute { 'omscoor-items' } { $omscoor-items }
             union $item-atts
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

