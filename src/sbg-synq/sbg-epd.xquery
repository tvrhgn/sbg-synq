module namespace sbge = "http://sbg-synq.nl/sbg-epd";

(: pas de koppelregels toe :)

import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at 'sbg-metingen.xquery';
import module namespace sbgem="http://sbg-synq.nl/epd-meting" at 'epd-meting.xquery';

(: datum +/- periode inclusief :)
declare function sbge:in-periode( $datum as xs:date, $peildatum as xs:date, $periode-voor as xs:yearMonthDuration, $periode-na as xs:yearMonthDuration ) as xs:boolean
{
  $datum >= ($peildatum - $periode-voor) and $datum <= ($peildatum + $periode-na)
};

(: OUD ---
  filter metingen binnen peildatums  +/- periode;  leid meetdomein en typemeting af; sorteer op afstand tot peildatum  :)
(: voeg attributen toe om meting te typeren (voor/na, meetdomein) en de selectie optimaal te doen (afstand, voor/na peildatum) :)
(: hier worden sbgem:Metingen omgebouwd tot Meting :)
declare function sbge:metingen-in-periode( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as element(peildatums)
) 
as element(Meting)* 
{
for $peildatum in $peildatums//datum
let $type := $peildatum/@type,
    $periode-voor := ($domein/meetperiode/meetperiode-voor/text(), $domein/meetperiode/text())[1],
    $meetperiode-voor := if ( $periode-voor castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration( $periode-voor)
                         else xs:yearMonthDuration("P3M"),
    $periode-na := ($domein/meetperiode/meetperiode-na/text(), $domein/meetperiode/text())[1],
    $meetperiode-na := if ( $periode-na castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration( $periode-na)
                         else xs:yearMonthDuration("P3M")
order by $type  (: de eerste toekenning van een meting is aan voormeting (testscenario 16) :) 
return 
    for $m in $metingen[data(@datum)]
    let $afstand := xs:date($m/@datum) - xs:date($peildatum),
        $voor-peildatum := $afstand le xs:dayTimeDuration('P0D')
    order by abs(fn:days-from-duration($afstand))
    return if ( sbge:in-periode($m/@datum, $peildatum, $meetperiode-voor, $meetperiode-na ) ) then 
       element {'Meting' } {
                $m/@*
                union attribute { 'typemeting' } { $type } 
                union attribute { 'sbge:afstand' } { $afstand }
                union attribute { 'sbge:voor-peildatum' } { $voor-peildatum },
                $m/*
        }
        else ()
 };

(: OUD --
  er zijn altijd 2 peildatums :)


(: OUD -- resulterend zijn is een sequence metingen getypeerd, maar niet uniek :)
declare function sbge:metingen-in-periode-domein( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as xs:date+
) 
as element(Meting)* 
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
    for $m in $metingen[data(@datum)]
    let $afstand := xs:date($m/@datum) - xs:date($peildatum),
        $voor-peildatum := $afstand le xs:dayTimeDuration('P0D')
    order by $ix, abs(fn:days-from-duration($afstand))  (: de eerste toekenning van een meting is aan voormeting (testscenario 16) :)
    return if ( sbge:in-periode($m/@datum, $peildatum, $meetperiode-voor, $meetperiode-na ) ) then 
       element {'Meting' } {
                $m/@*
                union attribute { 'typemeting' } { $ix } 
                union attribute { 'sbge:afstand' } { $afstand }
                union attribute { 'sbge:voor-peildatum' } { $voor-peildatum },
                $m/*
        }
        else ()
};

(: NIEUW: bereid kandidaat-metingen voor;
selecteer de metingen en typeer ze tov de dbc-peildatums; ; sorteer ze op afstand tot peildatum  :)
declare function sbge:dbc-metingen( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as xs:date+
) 
as element(Meting)*
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
for $m in $metingen[data(@datum)]
let $afstand := xs:date($m/@datum) - xs:date($peildatum),
    $voor-peildatum := $afstand le xs:dayTimeDuration('P0D')
order by abs(fn:days-from-duration($afstand)) 
return if ( sbge:in-periode($m/@datum, $peildatum, $meetperiode-voor, $meetperiode-na ) ) then 
    element {'Meting' } {
                $m/@*
                union attribute { 'typemeting' } { $ix } 
                union attribute { 'sbge:afstand' } { $afstand }
                union attribute { 'sbge:voor-peildatum' } { $voor-peildatum },
                $m/*
     }
      else ()
};

(: neem de getypeerde metingen en verdeel ze in voor/na metingen :)
declare function sbge:kandidaat-metingen( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as xs:date+
) 
as element(kandidaat-metingen) 
{
let $metingen-met-type := sbge:dbc-metingen( $metingen, $domein, $peildatums )
return <kandidaat-metingen>
    <voor>{$metingen-met-type[@typemeting eq '1']}</voor>
    <na>{$metingen-met-type[@typemeting eq '2']}</na>
 </kandidaat-metingen>       
};

(: then ($interval ge days-from-duration( )) 
            and ($interval le days-from-duration(  ))
            :)
            (: hebben normale zd inderdaad geen restricties op interval? :)
declare function sbge:zoek-nameting( $vm as element(Meting), $na-metingen as element(Meting)*, $zorgdomein as element(zorgdomein)? )
as element(meetpaar)*
{
let $nms := $na-metingen[@sbgm:meting-id ne $vm/@sbgm:meting-id][@gebruiktMeetinstrument eq $vm/@gebruiktMeetinstrument]
                        [not(@sbge:meetdomein) or (./@sbge:meetdomein eq $vm/@sbge:meetdomein)]
for $nm in $nms
let $interval :=  days-from-duration(xs:date($nm/@datum) - xs:date($vm/@datum)),
    $som-afstand := abs(days-from-duration($vm/@sbge:afstand)) + abs(days-from-duration($nm/@sbge:afstand)),
    $zd-mper := $zorgdomein/meetperiode,
    $zd-interval-geldig := 
         if ( data($zd-mper/@min-afstand) castable as xs:integer
              and data($zd-mper/@max-afstand) castable as xs:integer ) 
                  then ($interval ge xs:integer($zd-mper/@min-afstand) ) 
            and ($interval le xs:integer($zd-mper/@max-afstand) )
         else true() 
where $zd-interval-geldig
order by $som-afstand, $interval descending
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

(: retourneer een meetpaar, of alleen een voormeting; niks als er alleen een nameting is :)
declare function sbge:optimale-meetpaar( $kandidaten as element(kandidaat-metingen), $zorgdomein as element(zorgdomein)? )
as element( meetpaar )?
{
let $optimaal := sbge:maak-meetparen($kandidaten,$zorgdomein)/*[1]
return if ( $optimaal ) then $optimaal 
else if ( $kandidaten/voor/* ) then <meetpaar alleen-voor="{true()}">{$kandidaten/voor/*[1]}</meetpaar> else ()
};


(: OUD -- 
de datum-relaties (begin/eind) van de dbc bepalen of een meting het type 1: voor- of 2: nameting krijgt :)  
(: ken aan een dbc twee geldige peildatums toe: voorkeur voor de sessiedatums, terugval op begin/eind, default-waarden :)
declare function sbge:dbc-peildatums ($dbc as node()) as element(peildatums) {
let $begin := if ( data($dbc/@datumEersteSessie) castable as xs:date ) 
              then xs:date(data($dbc/@datumEersteSessie))
              else 
                 if  ( data($dbc/@startdatumDBC) castable as xs:date ) 
                 then xs:date(data($dbc/@startdatumDBC)) 
                 else xs:date('1900-01-01'),
     $eind := if ( data($dbc/@datumLaatsteSessie) castable as xs:date ) 
              then xs:date(data($dbc/@datumLaatsteSessie)) 
              else 
                 if ( data($dbc/@einddatumDBC) castable as xs:date ) 
                 then xs:date(data($dbc/@einddatumDBC)) 
                 else xs:date('2100-01-01')
     return <peildatums>
                <datum type="1">{$begin}</datum>
                <datum type="2">{$eind}</datum>
     </peildatums>
};

(: NIEUW
  functie die altijd twee datums retourneert :)
(: kijkt naar het attribuut 'peildatums-eenvoudig' op zorgdomein om sessie datums evt te negeren :)
declare function sbge:dbc-peildatums-zorgdomein($dbc as element(), $zorgdomein as element(zorgdomein) ) 
as xs:date*
{
let $e-sessie := if ( $zorgdomein[@peildatums-eenvoudig eq 'true'] ) then "-negeer-" else data($dbc/@datumEersteSessie)
let $l-sessie := if ( $zorgdomein[@peildatums-eenvoudig eq 'true'] ) then "-negeer-" else data($dbc/@datumLaatsteSessie)
let $begin := data($dbc/@startdatumDBC)
let $eind := data($dbc/@einddatumDBC)

return (  if ( $e-sessie castable as xs:date ) 
              then xs:date($e-sessie)
              else 
                 if  ( $begin castable as xs:date ) 
                 then xs:date($begin ) 
                 else xs:date('1900-01-01')   (: kunstmatig minimum :)
         ,
         if ( $l-sessie castable as xs:date ) 
              then xs:date($l-sessie ) 
              else 
                 if ( $eind castable as xs:date ) 
                 then xs:date($eind) 
                 else xs:date('2100-01-01')  (: kunstmatig maximum :)
     )
};

(: maak paren voor- en nametingen :)
(: basis is een gesorteerde set metingen per type; zie sbge:metingen-in-periode() :)
(: een meetpaar bevat maximaal 2 metingen van hetzelfde instrument; per meetdomein wordt maximaal 1 meetpaar geselecteerd :)
declare function sbge:selecteer-meetpaar ($kandidaten as element(Meting)*) as element(meetpaar)* 
{
    for $meetdomein in distinct-values($kandidaten/@sbgem:meetdomein)
    let $voormetingen := $kandidaten[@sbgem:meetdomein eq $meetdomein][@typemeting eq '1'],
        $nametingen   := $kandidaten[@sbgem:meetdomein eq $meetdomein][@typemeting eq '2']
    return 
        for $instr in distinct-values($voormetingen/@gebruiktMeetinstrument union $nametingen/@gebruiktMeetinstrument)  (: vind nameting, ook als er geen voormeting is :)
        let $bbh-nametingen := $nametingen[@gebruiktMeetinstrument = $instr],
            $bbh-voormetingen := $voormetingen[@gebruiktMeetinstrument = $instr], 
            $optimale-voormeting := ($bbh-voormetingen[@sbge:voor-peildatum='true'], $bbh-voormetingen)[1],  (: coalesce :)
            $optimale-nameting := $bbh-nametingen[1][not(@sbgm:meting-id = $optimale-voormeting/@sbgm:meting-id)],
            $compleet := exists($optimale-voormeting) and exists($optimale-nameting),
            $afstand := (abs(fn:days-from-duration($optimale-voormeting/@sbge:afstand)) + abs(fn:days-from-duration($optimale-nameting/@sbge:afstand)),0)[1], 
            $interval-att := if ( $compleet ) 
                            then attribute { 'interval' } { xs:date($optimale-nameting/@datum) - xs:date($optimale-voormeting/@datum) } 
                            else ()
             
        order by $afstand
        return <meetpaar instrument="{$instr}" domein="{$meetdomein}" sbg-afstand="{$afstand}" compleet="{$compleet}">{$interval-att}
        {$optimale-voormeting}
        {$optimale-nameting}
    </meetpaar>
 };

(: een zorgtraject heeft al een zorgdomein bepaald door zorgcircuit, locatie en diagnose
als er een conflict is met het zorgdomein van de metingen, wordt het eerste zorgdomein van de metingen genomen
Dit dient om uitval van metingen te beperken.
Opm: dit maakt de betekenis van zorgdomein dus vager
:)
declare function sbge:bepaal-zorgdomein ( $zorgtraject as element(sbgem:Zorgtraject), $metingen as element(sbgem:Meting)* ) 
as xs:string
{
let $zd-dbc := $zorgtraject/@sbgem:zorgdomeinCode,
    $sbg-metingen := $metingen[not(@sbgm:instrument-ongeldig)],
    $zds-meting := distinct-values( data($sbg-metingen/@sbgem:zorgdomein))
return if ( not($sbg-metingen) or index-of( $zds-meting, $zd-dbc )  )  
then $zorgtraject/@sbgem:zorgdomeinCode
(: zds-meting kan nog steeds meer zorgdomeinen bevatten; neem de eerste :) 
else  tokenize( string-join($zds-meting, ' '), ' ')[1]
};



(: vorm de sbgemPatienten om in Patienten door de metingen te filteren en toe te voegen aan de juiste DBC :)
declare function sbge:patient-dbc-meting( $patienten as element(sbgem:Patient)*, $domeinen as element(sbg-zorgdomeinen) ) 
as element(Patient) *
{
for $client in $patienten
let $clientmetingen := $client/sbgem:Meting
return 
   element { 'Patient' } 
           { $client/@*
             union attribute { 'sbge:aantal-metingen' } { count($clientmetingen) }
       , 
       for $zt in $client/sbgem:Zorgtraject
       (: kijk of de metingen verwijzen naar een ander zorgdomein :)
       let $zorgdomein-code := if ( $clientmetingen ) then sbge:bepaal-zorgdomein( $zt, $clientmetingen ) else data($zt/@sbgem:zorgdomeinCode)
       return 
          element { 'Zorgtraject' } 
                  { $zt/@*[local-name() ne 'sbgem:zorgdomeinCode']
                  union attribute { 'zorgdomeinCode' } { $zorgdomein-code }
                    ,
                  for $dbc in $zt/sbgem:DBCTraject
                    (: selecteer alleen metingen die geldig zijn binnen het zorgdomein :)
                  let $zorgdomein-metingen := $clientmetingen[@zorgdomein eq $zorgdomein-code],
                    (: het zorgdomein-object met oa de waarden voor/na-periode :)
                       $zorgdomein := $domeinen//zorgdomein[@code eq $zorgdomein-code]
                  
                  let $peildatums := sbge:dbc-peildatums($dbc),
                      $metingen := sbge:metingen-in-periode($clientmetingen, $zorgdomein, $peildatums),
                      $meetparen := sbge:selecteer-meetpaar($metingen),
                      $optimale-meetpaar := $meetparen//Meting
                      (: if ( $dbc/einddatum ) 
                                            then $meetparen[count(Meting)=2]//Meting 
                                            else $meetparen//Meting[@typemeting='1'] :)
                  return 
                    element { 'DBCTraject' } 
                            { $dbc/@*,
                              $optimale-meetpaar }
      }
    }
};

