module namespace sbge = "http://sbg-synq.nl/sbg-epd";
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at 'sbg-metingen.xquery';
(: declare namespace sbggz = "http://sbggz.nl/schema/import/5.0.1"; :)

declare variable $sbge:dbc-atts := ('DBCTrajectnummer','DBCPrestatieCode','startdatumDBC','einddatumDBC','datumEersteSessie','datumLaatsteSessie','redenEindeDBC','redenNonResponseVoormeting','redenNonResponseNameting');
declare variable $sbge:patient-atts := ('koppelnummer','geboorteJaar', 'geboorteMaand', 'geslacht', 'postcodegebied', 'geboortelandpatient', 'geboortelandVader', 'geboortelandMoeder', 'leefsituatie', 'opleidingsniveau');


(: dient om te garanderen dat alleen geselecteerde attributen doorgegeven worden die bovendien een waarde moeten hebben :)
(: hier wordt de elt content overgedragen naar atts :)
(: TODO ? waarom niet hier de sbggz ns al hanteren en de mogelijkheid voor niet sbg-attributen open houden? antwoord: dan moet je Patient weer helemaal opnieuw opbouwen:)
declare function sbge:build-sbg-atts($sbg-atts, $dbc-raw as node()?) as attribute()* {
    for $att-name in $sbg-atts
    let $val := $dbc-raw/*[local-name()=$att-name][string-length(.)>0][1]/text(),
        $att := if ( $val ) then attribute { $att-name } { $val } else ()
    return $att
};

(: datum +/- periode inclusief :)
declare function sbge:in-periode( $datum as xs:date, $peildatum as xs:date, $periode-voor as xs:yearMonthDuration, $periode-na as xs:yearMonthDuration ) as xs:boolean
{
  $datum >= ($peildatum - $periode-voor) and $datum <= ($peildatum + $periode-na)
};


(: $meetperiode-voor := if ( $domein/meetperiode-voor/text() castable as xs:yearMonthDuration ) 
                         then xs:yearMonthDuration($domein/meetperiode-voor/text())
                         else  
                            if ( $domein/meetperiode-voor/text() castable as xs:yearMonthDuration ) 
                            then xs:yearMonthDuration( $domein/meetperiode/text())
                            else xs:yearMonthDuration("P3M"),
                            
    $meetperiode-na := ($domein/meetperiode-na/text(), $domein/meetperiode/text(), xs:yearMonthDuration("P3M"))[1]
    :)

(: filter metingen binnen peildatums  +/- periode;  leid meetdomein en typemeting af; sorteer op afstand tot peildatum  :)
(: bouw Meting opnieuw op; TODO bekijk xquery update:)
(: voeg attributen toe om meting te typeren (voor/na, meetdomein) en de selectie optimaal te doen (afstand, voor/na peildatum) :)
declare function sbge:metingen-in-periode( 
$metingen as element(Meting)*,  
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
    for $m in $metingen[data(@datum)]  (: todo datum moet een waarde hebben :)
    let $afstand := xs:date($m/@datum) - xs:date($peildatum),
        $voor-peildatum := $afstand le xs:dayTimeDuration('P0D'),
        $meetdomein := $domein/meetdomein/naam[..//instrument/@code = $m/@gebruiktMeetinstrument]/text() (: ? is er dit altijd maar 1; waarom is meetdomein geen att van instrument ? :) 
    order by abs(fn:days-from-duration($afstand))
    return if ( sbge:in-periode($m/@datum, $peildatum, $meetperiode-voor, $meetperiode-na ) ) then 
       element {'Meting' } {
                $m/@*
                union attribute { 'typemeting' } { $type } 
                union attribute { 'sbge:afstand' } { $afstand }
                union attribute { 'sbge:meetdomein' } { $meetdomein }  
                union attribute { 'sbge:voor-peildatum' } { $voor-peildatum },
                $m/*
        }
        else ()
 };


(: zorgdomein wordt geselecteerd adhv zorgcircuit, diagnose en locatie :)
(: gebruik sbg-element cl-zorgcircuit :)
(: primaireDiagnoseCode, cl-zorgcircuit, locatiecode zijn verplichte elementen van dbc :)
declare function sbge:filter-domein ($dbc as node(), $domeinen as element(sbg-zorgdomeinen)) as element(zorgdomein)* 
{
let $diagnose := $dbc/primaireDiagnoseCode/text(),
    $circuit := $dbc/cl-zorgcircuit/text(),
    $locatie := $dbc/locatiecode/text()
for $zd in $domeinen/zorgdomein
let $rx-circuit := ($zd/koppel-dbc/@zorgcircuit, ".*")[1],
    $rx-diagnose := ($zd/koppel-dbc/@diagnose, ".*")[1],
    $rx-locatie := ($zd/koppel-dbc/@locatie, ".*")[1]
where matches($circuit, $rx-circuit) and matches( $locatie, $rx-locatie ) and matches($diagnose, $rx-diagnose)
return $zd
};

(: selecteer juist domein; het eerste zorgdomein dat in aanmerking komt; gebruik prioriteit aan de data-kant om selectie te sturen 'XX' is max code:)
declare function sbge:selecteer-domein ($dbc as node(), $domeinen as element(sbg-zorgdomeinen)) as element(zorgdomein) {
let $zds := for $domein in sbge:filter-domein($dbc, $domeinen) 
                    union <zorgdomein code='XX'><naam>onbekend</naam></zorgdomein>
            order by $domein/koppel-dbc/@priority empty greatest, $domein/@code
            return $domein
 return $zds[1]
};


(: de datum-relaties (begin/eind) van de dbc bepalen of een meting het type 1: voor- of 2: nameting krijgt :)  
(: ken aan een dbc twee geldige peildatums toe: voorkeur voor de sessiedatums, terugval op begin/eind, default-waarden :)
declare function sbge:dbc-peildatums ($dbc as node()) as element(peildatums) {
let $begin := if ( $dbc/datumEersteSessie/text() castable as xs:date ) 
              then xs:date($dbc/datumEersteSessie)
              else 
                 if  ( $dbc/startdatumDBC/text() castable as xs:date ) 
                 then xs:date($dbc/startdatumDBC) 
                 else xs:date('1900-01-01'),
     $eind := if ( $dbc/datumLaatsteSessie/text() castable as xs:date ) 
              then xs:date($dbc/datumLaatsteSessie) 
              else 
                 if ( $dbc/einddatumDBC/text() castable as xs:date ) 
                 then xs:date($dbc/einddatumDBC) 
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
    for $meetdomein in distinct-values($kandidaten/@sbge:meetdomein)
    let $voormetingen := $kandidaten[@sbge:meetdomein=$meetdomein][@typemeting='1'],
        $nametingen := $kandidaten[@sbge:meetdomein=$meetdomein][@typemeting='2']
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

(: deprecated  Patient//Meting bevat de optimale metingen; ?:)
declare function sbge:x-optimale-meetpaar ($paren as element(meet-paar)*) as element(Meting)* 
{
    $paren[count(Meting)=2][1]//Meting
};

(: stelregel in functioneel programmeren: een functie van meer dan 7 regels is te complex... :)
declare function sbge:patient-dbc-meting( 
    $dbcs as node()*, 
    $metingen as element(Meting)*, 
    $domeinen as element(sbg-zorgdomeinen) ) 
as element(Patient) *
{
for $client in distinct-values( $dbcs/koppelnummer )
let $client-dbcs := $dbcs[koppelnummer = $client]
return 
   element { 'Patient' } 
           { sbge:build-sbg-atts( $sbge:patient-atts, $client-dbcs[1] ), 
       for $zt in distinct-values($client-dbcs/zorgtrajectnummer)
       let $zt-dbcs := $client-dbcs[zorgtrajectnummer = $zt],
           $eerste-dbc := $zt-dbcs[1],   (: ga uit van 1 zdomein, diagnosecode etc voor alle dbcs in dit zorgtraject :)
           $zorgdomein := sbge:selecteer-domein( $eerste-dbc, $domeinen )
       return 
          element { 'Zorgtraject' } 
                  { attribute { 'zorgtrajectnummer' } { $zt} 
                    union attribute { 'zorgdomeinCode' } { $zorgdomein/@code }
                    union attribute { 'primaireDiagnoseCode' } { $eerste-dbc/primaireDiagnoseCode }
                    union attribute { 'locatiecode' } { $eerste-dbc/locatiecode }
                    union attribute { 'GAFscore' } { $eerste-dbc/GAFscore }
                    ,
                  for $dbc in $zt-dbcs
                  let $clientmetingen := $metingen[@sbgm:koppelnummer=$dbc/koppelnummer],
                      $peildatums := sbge:dbc-peildatums($dbc),
                      $metingen := sbge:metingen-in-periode($clientmetingen, $zorgdomein, $peildatums),
                      $meetparen := sbge:selecteer-meetpaar($metingen),
                      $optimale-meetpaar := if ( $dbc/einddatum ) 
                                            then $meetparen[count(Meting)=2]//Meting 
                                            else $meetparen//Meting[@typemeting='1']
                  return 
                    element { 'DBCTraject' } 
                            { sbge:build-sbg-atts($sbge:dbc-atts, $dbc), $optimale-meetpaar }
      }
    }
};

