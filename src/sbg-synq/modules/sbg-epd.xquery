module namespace sbge = "http://sbg-synq.nl/sbg-epd";
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


(: pas de koppelregels toe op de procesinfo (zie epd-meting.xquery)
plaats de sbggz-attributen in de doel-ns
 :)

declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace sbgem="http://sbg-synq.nl/epd-meting";

(: datum +/- periode inclusief :)
declare function sbge:in-periode( $datum as xs:date, $peildatum as xs:date, $periode-voor as xs:yearMonthDuration, $periode-na as xs:yearMonthDuration ) as xs:boolean
{
  $datum ge ($peildatum - $periode-voor) and $datum le ($peildatum + $periode-na)
};

(: bereid kandidaat-metingen voor;
selecteer de metingen en typeer ze tov de dbc-peildatums; ; sorteer ze op afstand tot peildatum  
NB: metingen zijn niet uniek in het resultaat
metingen staan nu in de doel-ns 
:)

declare function sbge:dbc-metingen( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as xs:date+
) 
as element(sbggz:Meting)*
{ 
for $peildatum at $ix in $peildatums
let $periode-voor := ($domein/meetperiode/meetperiode-voor/text(), $domein/meetperiode/text())[1],
    $meetperiode-voor := if ( $periode-voor castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration( $periode-voor)
                         else xs:yearMonthDuration("P3M"),
    $periode-na := ($domein/meetperiode/meetperiode-na/text(), $domein/meetperiode/text())[1],
    $meetperiode-na := if ( $periode-na castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration( $periode-na)
                         else xs:yearMonthDuration("P3M") 
for $m in $metingen[data(@sbggz:datum)]
let $afstand := xs:date($m/@sbggz:datum) - xs:date($peildatum),
    $voor-peildatum := $afstand le xs:dayTimeDuration('P0D')
order by abs(fn:days-from-duration($afstand)) 
return if ( sbge:in-periode($m/@sbggz:datum, $peildatum, $meetperiode-voor, $meetperiode-na ) ) then 
    element {'sbggz:Meting' } {
                $m/@*
                union attribute { 'sbggz:typemeting' } { $ix } 
                union attribute { 'sbge:afstand' } { $afstand }
                union attribute { 'sbge:voor-peildatum' } { $voor-peildatum },
                $m/*
     }
      else ()
};

(: overweeg om een leeg element te retourneren? :)
(: neem de getypeerde metingen en verdeel ze in voor/na metingen :)
(: NB er gaan sbgem:Metingen in en er komen sbggz:Metingen uit :)
declare function sbge:kandidaat-metingen( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as xs:date+
) 
as element(kandidaat-metingen) 
{
let $metingen-met-type := sbge:dbc-metingen( $metingen, $domein, $peildatums )
return <kandidaat-metingen>
    <voor>{$metingen-met-type[@sbggz:typemeting eq '1']}</voor>
    <na>{$metingen-met-type[@sbggz:typemeting eq '2']}</na>
 </kandidaat-metingen>       
};

(: maak geldige meetparen bij gegeven voormeting; start bij metingen met hetzelfde instrument en meetdomein :)
declare function sbge:zoek-nameting( $vm as element(sbggz:Meting), $na-metingen as element(sbggz:Meting)*, $zorgdomein as element(zorgdomein)? )
as element(meetpaar)*
{
let $nms := $na-metingen[@sbgm:meting-id ne $vm/@sbgm:meting-id]
                        [@sbggz:gebruiktMeetinstrument eq $vm/@sbggz:gebruiktMeetinstrument]
                        [not(@sbge:meetdomein) or (./@sbge:meetdomein eq $vm/@sbge:meetdomein)]
                        [@sbggz:datum gt $vm/@sbggz:datum]
for $nm in $nms
let $v-datum := xs:date($vm/@sbggz:datum),
    $n-datum := xs:date($nm/@sbggz:datum),
    $interval :=  days-from-duration($n-datum - $v-datum),
    $som-afstand := abs(days-from-duration($vm/@sbge:afstand)) + abs(days-from-duration($nm/@sbge:afstand)),
    $zd-mper := $zorgdomein/meetperiode,
    $zd-interval-geldig := 
         if ( $zd-mper/@min-afstand castable as xs:yearMonthDuration
              and $zd-mper/@max-afstand castable as xs:yearMonthDuration ) 
                  then $n-datum - xs:yearMonthDuration($zd-mper/@min-afstand) ge $v-datum 
                   and $n-datum - xs:yearMonthDuration($zd-mper/@max-afstand) le $v-datum
         else true() 
where $zd-interval-geldig
order by $som-afstand
return <meetpaar som-afstand="{$som-afstand}" interval="{$interval}">
        {$vm}
        {$nm}
    </meetpaar>
 };

declare function sbge:maak-meetparen( $kandidaten as element(kandidaat-metingen), $zorgdomein  as element(zorgdomein)? )
as element(meetparen)
{ 
let $voor-metingen := $kandidaten/voor/*,
    $na-metingen := $kandidaten/na/*
return <meetparen>{
for $vm in $voor-metingen
return sbge:zoek-nameting($vm,$na-metingen,$zorgdomein)
}</meetparen>
};

(: retourneer een meetpaar, met een voor en na-meting, of 1 van beide, met een voorkeur voor voormeting :)
(: bij zorgdomeinen met een afstands-criterium tussen voor en na, kan nooit alleen een eindmeting geleverd worden? :)
declare function sbge:optimale-meetpaar( $kandidaten as element(kandidaat-metingen), $zorgdomein as element(zorgdomein)? )
as element( meetpaar )?
{
let $optimaal := sbge:maak-meetparen($kandidaten,$zorgdomein)/*[1]
return 
    if ( $optimaal ) then $optimaal 
    else if ( $kandidaten/voor/* ) 
        then <meetpaar alleen-voor="{true()}">{$kandidaten/voor/*[1]}</meetpaar> 
        else if ( not($zorgdomein/meetperiode/@min-afstand) and $kandidaten/na/* ) 
            then <meetpaar alleen-na="{true()}">{$kandidaten/na/*[1]}</meetpaar>
            else ()
};


(: 
  functie die altijd twee datums retourneert :)
(: kijkt naar het attribuut 'peildatums-eenvoudig' op zorgdomein om sessie datums evt te negeren :)
declare function sbge:dbc-peildatums-zorgdomein($dbc as element(), $zorgdomein as element(zorgdomein) ) 
as xs:date*
{
let $e-sessie := if ( $zorgdomein[@peildatums-eenvoudig eq 'true'] ) then "-negeer-" else data($dbc/@sbggz:datumEersteSessie)
let $l-sessie := if ( $zorgdomein[@peildatums-eenvoudig eq 'true'] ) then "-negeer-" else data($dbc/@sbggz:datumLaatsteSessie)
let $begin := data($dbc/@sbggz:startdatumDBC)
let $eind := data($dbc/@sbggz:einddatumDBC)

return (  if ( $e-sessie castable as xs:date ) 
              then xs:date($e-sessie)
              else 
                 if  ( $begin castable as xs:date ) 
                 then xs:date($begin ) 
                 else xs:date('1900-01-01')   (: kunstmatig minimum :)
         ,
         if ( $l-sessie castable as xs:date and $eind )  (: negeer laatste sessie al einddatum ontbreekt :) 
              then xs:date($l-sessie ) 
              else 
                 if ( $eind castable as xs:date ) 
                 then xs:date($eind) 
                 else xs:date('2100-01-01')  (: kunstmatig maximum :)
     )
};

(: een zorgtraject heeft al een zorgdomein gekregen in sbgem (bepaald door zorgcircuit, locatie en diagnose)
als er een conflict is met het zorgdomein van de metingen, wordt het eerste zorgdomein van de metingen genomen
Dit dient om uitval van metingen te beperken.
Opm: dit maakt de betekenis van zorgdomein dus vager
:)
declare function sbge:bepaal-zorgdomein ( $zorgtraject as element(sbgem:Zorgtraject), $metingen as element(sbgem:Meting)* ) 
as xs:string
{
let $zd-zt := data($zorgtraject/@sbgem:zorgdomeinCode),
    $sbg-metingen := $metingen[not(@sbgm:instrument-ongeldig)],
    $zds-meting := distinct-values( tokenize( string-join($sbg-metingen/@sbgem:zorgdomein, ' '), ' '))
return if ( not($sbg-metingen) or exists(index-of( $zds-meting, $zd-zt )  ))  
then $zorgtraject/@sbgem:zorgdomeinCode
(: zds-meting kan nog steeds meer zorgdomeinen bevatten; neem de eerste :) 
else  $zds-meting[1]
};


(: vervang sbgem:zorgdomein-code :) 
declare function sbge:maak-zorgtraject( $zt as element(sbgem:Zorgtraject), $zorgdomein-code as xs:string, $dbcs as element(sbggz:DBCTraject)* ) 
as element(sbggz:Zorgtraject)
{ 
element { 'sbggz:Zorgtraject' } 
        { $zt/@*[local-name() ne 'sbgem:zorgdomeinCode']
           union attribute { 'sbggz:zorgdomeinCode' } { $zorgdomein-code }
        ,
        $zt/sbggz:*, 
        $dbcs 
}
};

(: laat alleen geldige metingen door :)
declare function sbge:maak-metingen( $metingen as element(sbggz:Meting)* )
as element (sbggz:Meting)*
{
for $m in $metingen
return if ( $m/@totaalscoreMeting eq '999' ) 
        then 
            if ( count($m/sbggz:Item) gt 0 and count( $m/sbggz:Item[not(@itemnummer)][not(@score)] ) eq 0 )
            then $m
            else ()
        else 
          element { 'sbggz:Meting' } { $m/@sbggz:*,
            for $i in $m/sbggz:Item[exists(@sbggz:itemnummer)][exists(@sbggz:score)] (: verplichte attributen :)
            return 
                element { 'sbggz:Item' } { $i/@sbggz:* }
        }
};


(: maak dbc; filter de juiste metingen :)
declare function sbge:maak-dbc( $dbc as element(sbgem:DBCTraject), $metingen as element(sbgem:Meting)*, $zorgdomein as element(zorgdomein)  ) 
as element(sbggz:DBCTraject)
{ 
let $peildatums := sbge:dbc-peildatums-zorgdomein($dbc, $zorgdomein),

    $kandidaten := sbge:kandidaat-metingen($metingen, $zorgdomein, $peildatums),
    $optimale-meetpaar := sbge:optimale-meetpaar($kandidaten, $zorgdomein)
return 
    element { 'sbggz:DBCTraject' } 
        { $dbc/@*,
        sbge:maak-metingen( $optimale-meetpaar//sbggz:Meting )
        (:
        data($peildatums) 
        $metingen
        :)
    }
};


(: beginpunt is het Patient-object met alle metingen uit epd-meting :)
(: dit is de laatste step; hierna hoeven alleen de correcte attributen gefilterd :)
(: - controleer zorgdomein; neem evt over uit meting :)
declare function sbge:patient-sbg-meting( $patient as element(sbgem:Patient), $domeinen as element(zorgdomein)* ) 
as element(sbggz:Patient)
{
let $clientmetingen := $patient//sbgem:Meting[not(@sbgm:score-ongeldig)][not(@sbgm:te-veel-items-ongeldig)]
return 
   element { 'sbggz:Patient' } 
           { $patient/@*
             union attribute { 'sbge:aantal-metingen' } { count($clientmetingen) }
       ,
       for $zt in $patient/sbgem:Zorgtraject
       let $zorgdomein-code := if ( $clientmetingen ) 
                               then sbge:bepaal-zorgdomein( $zt, $clientmetingen ) 
                               else data($zt/@sbgem:zorgdomeinCode),
           $zorgdomein := $domeinen[@zorgdomeinCode eq $zorgdomein-code],
           $zorgdomein-metingen := $clientmetingen (: geldig in zorgdomein? :),
           
           $dbcs := for $dbc in $zt/sbgem:DBCTraject 
                    return sbge:maak-dbc($dbc,$zorgdomein-metingen,$zorgdomein)
       
       return sbge:maak-zorgtraject($zt,$zorgdomein-code,$dbcs)
         
    }
};

declare function sbge:sbg-patient-meting( $patient as element(sbgem:Patient)*, $domeinen as element(zorgdomein)* ) 
as element(sbggz:Patient)*
{
for $p in $patient
return sbge:patient-sbg-meting($p,$domeinen)
};
