 
(: verwerk de test-metingen van PoC en combineer met test-epd; toon resultaat in html :)
declare namespace saxon="http://saxon.sf.net/";
declare namespace html="http://www.w3.org/1999/xhtml";
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';
import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';

declare option saxon:output "omit-xml-declaration=yes";

declare variable $za-doc := '../sbg-testdata/zorgaanbieder-testconfig.xml';

declare variable $za := sbgza:build-zorgaanbieder( doc($za-doc )/zorgaanbieder );

declare variable $instrumenten := sbgi:laad-instrumenten( $za/instrumenten/sbg-instrumenten );
declare variable $sbg-zorgdomeinen := $za/sbg-zorgdomeinen;
declare variable $epd := $za/epd;
declare variable $rom := $za/rom;
declare variable $rom-items := $za/rom-items;

(: meetperiode :)
declare variable $periode := xs:yearMonthDuration('P3M');



(: vorm de meting-rijen om naar seq Meting :)
declare variable $sbg-rom := sbgm:sbg-metingen($za/rom/*, $za/rom-items/*, $instrumenten);


(: doe alle berekeningen die sbge:patient-dbc-meting ook doet :)
(:sla alle tussenresultaten op in een vereenvoudigd patient-element :)
declare function local:test-result-dbcs( $dbcs as node()*, $metingen as node()* ) as element(result){
<result>
  {
    for $client in distinct-values( $dbcs/koppelnummer )
    return <patient koppelnummer="{$client}">{
      for $dbc in $dbcs[koppelnummer=$client]
      let $clientmetingen := $metingen//Meting[@sbgm:koppelnummer=$dbc/koppelnummer],
        $peildatums := sbge:dbc-peildatums($dbc),
        $zorgdomein := sbge:selecteer-domein( $dbc, $sbg-zorgdomeinen ),
        $metingen := sbge:metingen-in-periode($clientmetingen, $zorgdomein, $peildatums),
        $meetparen := sbge:selecteer-meetpaar($metingen),
        $optimaal := sbge:patient-dbc-meting($dbc, $clientmetingen, $sbg-zorgdomeinen)//Meting
      return <dbc dbc-id="{$dbc/DBCTrajectnummer}" max-abs-duur="{$periode}"
                startdatumDBC="{$dbc/startdatumDBC}" 
                einddatumDBC="{$dbc/einddatumDBC}"
                datumEersteSessie="{$dbc/datumEersteSessie}"
                datumLaatsteSessie="{$dbc/datumLaatsteSessie}">
              {$peildatums}
              <metingen>{$clientmetingen}</metingen>
              <metingen-in-periode>{$metingen}</metingen-in-periode>
              <kandidaat-metingen>{$meetparen}</kandidaat-metingen>
              <optimale-metingen>{$optimaal}</optimale-metingen>
        </dbc>
     }
    </patient>
  }
</result>
};


(: html table voor dbc uit local:test-result-dbcs(); toont de grensdatums :)
declare function local:html-test-dbc($dbc as element(dbc)*) as element(table)* {
if ( $dbc ) then 
<table class="dbc-datums">
<tr><td colspan="2" class="dbc-id">{concat( 'DBC ', $dbc/@dbc-id)}</td></tr>
<tr><td>DBC startdatum</td><td>DBC einddatum</td></tr>
<tr><td class="dbc-datum">{data($dbc/@startdatumDBC)}</td>
  <td class="dbc-datum">{data($dbc/@einddatumDBC)}</td></tr>
<tr><td>eerste sessiedatum</td><td>laatste sessiedatum</td></tr>
<tr><td class="dbc-datum">{data($dbc/@datumEersteSessie)}</td>
    <td class="dbc-datum">{data($dbc/@datumLaatsteSessie)}</td></tr>
</table>
else ()
};

(: haal alle tussenresultaten weer op en zet eigenschappen om in html/css :)
declare function local:html-tr-meting( $dbc as element(dbc)*, $metingen as element(Meting)*) as element(tr)* {
for $meting in $metingen
(: ga na of deze meting ook voorkomt in metingen-in-periode, kandidaat- of optimale-metingen :)
let $voormeting := $dbc/metingen-in-periode//Meting[@typemeting='1'][@sbgm:meting-id = $meting/@sbgm:meting-id],
    $nameting := $dbc/metingen-in-periode//Meting[@typemeting='2'][@sbgm:meting-id = $meting/@sbgm:meting-id],
    $kandidaat-voor := $dbc/kandidaat-metingen//Meting[@typemeting='1'][@sbgm:meting-id = $meting/@sbgm:meting-id],
    $kandidaat-na := $dbc/kandidaat-metingen//Meting[@typemeting='2'][@sbgm:meting-id = $meting/@sbgm:meting-id],
    $optimaal-voor := $dbc/optimale-metingen//Meting[@typemeting='1'][@sbgm:meting-id = $meting/@sbgm:meting-id],
    $optimaal-na := $dbc/optimale-metingen//Meting[@typemeting='2'][@sbgm:meting-id = $meting/@sbgm:meting-id],
    
    $voor-class := concat( 'afstand, voor_kandidaat_optimaal_', exists($kandidaat-voor), '_' , exists($optimaal-voor) ),
    $na-class := concat( 'afstand, na_kandidaat_optimaal_', exists($kandidaat-na), '_' , exists($optimaal-na) ),
    
    $afstand-voor := fn:days-from-duration($voormeting/@sbge:afstand),
    $afstand-na := fn:days-from-duration($nameting/@sbge:afstand)
order by $meting/@datum 
    return <tr class="meting">
    <td>{data($meting/@sbgm:meting-id)}</td>
    <td>{data($meting/@gebruiktMeetinstrument)}</td>
    <td>{data($meting/@datum)}</td>
    <td class="{$voor-class}">{$afstand-voor}</td>
    <td class="{$na-class}">{$afstand-na}</td>
    </tr>
};


declare function local:html-test-optimale-meting($result as element(result)*) as element(div)*
{
<div id="content">{
for $p in $result//patient, $dbc in $p/dbc
let $client := data($p/@koppelnummer),
    $dbc-nr := data($dbc/@dbc-id)
order by xs:integer($client)
return 
<table class="client">
  <tr>
        <td class="client">{$client}</td> <td></td> <td></td>
        <td colspan="2">{local:html-test-dbc($dbc)}</td>
  </tr>
  <tr>
     <td></td>      <td></td>     <td></td> 
     <td>peildatum voor</td> <td>peildatum na</td>
   </tr>
   <tr>
     <td></td>      <td></td>     <td></td> 
     <td>{$dbc/peildatums/datum[@type='1']}</td> <td>{$dbc/peildatums/datum[@type='2']}</td>
   </tr> 
   {
        for $meting in $dbc/metingen/Meting
        order by $meting/@gebruiktMeetinstrument, $meting/@datum
        return local:html-tr-meting( $dbc, $meting )
     }
    </table>
    }
</div>
};


declare function local:html-doc($result as element(result)) as element(html:html)
{
<html:html>
<head>
<title>test-epd</title>
<link rel="stylesheet" type="text/css" href="sbg-testdata.css"/>
</head>
<body> 
<h2>SBG PoC test-set</h2>
<p>Test gaat in op correct matchen van DBC-peildatums en ROM-metingen.</p>
<p>verklaring van de celkleuren:</p>
<table class="meting">
<tr class="meting">
<td class="voor_kandidaat_optimaal_false_false">geen voormeting</td>
<td class="na_kandidaat_optimaal_false_false">geen nameting</td>
</tr>
<tr>
<td class="voor_kandidaat_optimaal_true_false">voormeting</td>
<td class="na_kandidaat_optimaal_true_false">nameting</td>
</tr>
<tr>
<td class="voor_kandidaat_optimaal_true_true">optimale voormeting</td>
<td class="na_kandidaat_optimaal_true_true">optimale nameting</td>
</tr>
</table>
<p>(* in de ID betekent: gewijzigd tov aangeleverde data)</p>
<p>run sbg-synq versie 0.8  {current-dateTime()}</p>
{
local:html-test-optimale-meting($result)
}</body>

</html:html>
};

(: dit is de main-functie :)
(: maak de test-set :)
let $test-result := local:test-result-dbcs($epd/*, $sbg-rom),
(: rapporteer :)
$html := local:html-doc($test-result)

(: $html := $test-result :)
return $html


