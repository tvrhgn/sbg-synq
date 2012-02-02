module namespace sbge = "http://sbg-synq.nl/sbg-epd";
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at 'sbg-metingen.xquery';
import module namespace sbgem="http://sbg-synq.nl/epd-meting" at 'epd-meting.xquery';

(: datum +/- periode inclusief :)
declare function sbge:in-periode( $datum as xs:date, $peildatum as xs:date, $periode-voor as xs:yearMonthDuration, $periode-na as xs:yearMonthDuration ) as xs:boolean
{
  $datum >= ($peildatum - $periode-voor) and $datum <= ($peildatum + $periode-na)
};

(: filter metingen binnen peildatums  +/- periode;  leid meetdomein en typemeting af; sorteer op afstand tot peildatum  :)
(: voeg attributen toe om meting te typeren (voor/na, meetdomein) en de selectie optimaal te doen (afstand, voor/na peildatum) :)
(: hier worden sbgem:Metingen omgebouwd tot Meting :)
declare function sbge:metingen-in-periode( 
$metingen as element(sbgem:Meting)*,  
$domein as element(zorgdomein), 
$peildatums as element(peildatums)
) 
as element(Meting)* {
for $peildatum in $peildatums//datum
let $type := $peildatum/@type,
    $periode-voor := ($domein/meetperiode-voor/text(), $domein/meetperiode/text())[1],
    $meetperiode-voor := if ( $periode-voor castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration( $periode-voor)
                         else xs:yearMonthDuration("P3M"),
    $periode-na := ($domein/meetperiode-na/text(), $domein/meetperiode/text())[1],
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


(: de datum-relaties (begin/eind) van de dbc bepalen of een meting het type 1: voor- of 2: nameting krijgt :)  
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

(: maak paren voor- en nametingen :)
(: basis is een gesorteerde set metingen per type; zie sbge:metingen-in-periode() :)
(: een meetpaar bevat maximaal 2 metingen van hetzelfde instrument; per meetdomein wordt maximaal 1 meetpaar geselecteerd :)
declare function sbge:selecteer-meetpaar ($kandidaten as element(Meting)*) as element(meet-paar)* 
{
    for $meetdomein in distinct-values($kandidaten/@sbgem:meetdomein)
    let $voormetingen := $kandidaten[@sbgem:meetdomein eq $meetdomein][@typemeting eq'1'],
        $nametingen := $kandidaten[@sbgem:meetdomein eq $meetdomein][@typemeting eq '2']
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
    return <meet-paar instrument="{$instr}" domein="{$meetdomein}" sbg-afstand="{$afstand}" compleet="{$compleet}">{$interval-att}
        {$optimale-voormeting}
        {$optimale-nameting}
    </meet-paar>
 };

(: een zorgtraject heeft al een zorgdomein bepaald door zorgcircuit, locatie en diagnose
als er een conflict is met het zorgdomein van de metingen, wordt het eerste zorgdomein van de metingen genomen
Dit dient om uitval van metingen te beperken.
Opm: dit maakt de betekenis van zorgdomein dus vager
distinct-values( tokenize( data($metingen/@zorgdomein), ' ')) 
:)
declare function sbge:bepaal-zorgdomein ( $zorgtraject as element(sbgem:Zorgtraject), $metingen as element(sbgem:Meting)* ) 
as xs:string
{
let $vals := string-join(distinct-values( data($metingen/@sbgem:zorgdomein))),
    $zorgdomein-kandidaten := tokenize($vals, ' ')
return if ( index-of( ($zorgdomein-kandidaten, 'XX'), $zorgtraject/@sbgem:zorgdomeinCode ) ) 
then $zorgtraject/@sbgem:zorgdomeinCode  (: geen conflict :)
else  ($zorgdomein-kandidaten, $zorgtraject/@sbgem:zorgdomeinCode, 'XX')[1]
};



(: vorm de sbgemPatienten om in Patienten door de metingen te filteren en toe te voegen aan de juiste DBC :)
declare function sbge:patient-dbc-meting( $patienten as element(sbgem:Patient)*, $domeinen as element(sbg-zorgdomeinen) ) 
as element(Patient) *
{
for $client in $patienten
let $clientmetingen := $client/sbgem:Meting
return 
   element { 'Patient' } 
           { $client/@*, 
       for $zt in $client/sbgem:Zorgtraject
       (: kijk of de metingen verwijzen naar een ander zorgdomein :)
       let $zorgdomein-code := sbge:bepaal-zorgdomein( $zt, $clientmetingen )
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
                      $optimale-meetpaar := $meetparen
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

