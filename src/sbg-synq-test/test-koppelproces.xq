(: test sbge:patient-dbc-meting() :)
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';
import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';

declare variable $za-doc := '../sbg-testdata/zorgaanbieder-testconfig.xml';

declare variable $za := sbgza:build-zorgaanbieder( doc($za-doc )/zorgaanbieder );

declare variable $instrumenten := sbgi:laad-instrumenten( $za/instrumenten/sbg-instrumenten );
declare variable $sbg-zorgdomeinen := $za/sbg-zorgdomeinen/*;


(: vorm de meting-rijen om naar seq Meting :)
declare variable $sbg-rom := sbgm:sbg-metingen($za/rom/*, $za/rom-items/*, $instrumenten);


(: doe alle berekeningen die sbge:patient-dbc-meting() ook doet :)
(:sla alle tussenresultaten op in een vereenvoudigd patient-element; un-lazy de module :)
declare function local:test-result-dbcs( $dbcs as node()*, $metingen as element(Meting)* ) as element(result){
<result timestamp="{current-dateTime()}" xmlns:sbgm='http://sbg-synq.nl/sbg-metingen' xmlns:sbge='http://sbg-synq.nl/sbg-epd'>
  {
    for $client in distinct-values( $dbcs/koppelnummer )
    return <patient koppelnummer="{$client}">{
      for $dbc in $dbcs[koppelnummer=$client]
      let $peildatums := sbge:dbc-peildatums($dbc),
          $zorgdomein := sbge:selecteer-domein( $dbc, $sbg-zorgdomeinen ),
      (: NB clientmetingen bevat de stroom met de oorspronkelijke Meting-objecten; de sbge-Meting-objecten zijn niet equivalent, omdat het Meting-object opnieuw wordt aangemaakt :) 
        $clientmetingen := $metingen[@sbgm:koppelnummer=$dbc/koppelnummer or @koppelnummer=$dbc/koppelnummer],
        (: roep de functies die de tussenresultaten geven aan :)
        $metingen := sbge:metingen-in-periode($clientmetingen, $zorgdomein, $peildatums),
        $meetparen := sbge:selecteer-meetpaar($metingen),
        $optimaal := sbge:patient-dbc-meting($dbc, $clientmetingen, $sbg-zorgdomeinen)//Meting
       
      return <dbc DBCTrajectnummer="{$dbc/DBCTrajectnummer}"
                startdatumDBC="{$dbc/startdatumDBC}" 
                einddatumDBC="{$dbc/einddatumDBC}"
                datumEersteSessie="{$dbc/datumEersteSessie}"
                datumLaatsteSessie="{$dbc/datumLaatsteSessie}"
                zorgdomein="{$zorgdomein/@code}" aantal-metingen="{count($clientmetingen)}">
              {$peildatums}
              <metingen>{
              for $meting in $clientmetingen
              let $m-id := $meting/@sbgm:meting-id, 
                  $meetpaar := $meetparen[*[@sbgm:meting-id = $m-id]],
                  $meting-att := $meting/@*[namespace-uri() = ''],
                  
                  $soort := if ( exists( $optimaal[@sbgm:meting-id = $m-id] ) ) 
                            then "optimaal"
                            else 
                                if ( $meetpaar ) 
                                then "kandidaat"
                                else
                                    if ( exists( $metingen[@sbgm:meting-id = $m-id] )) 
                                    then "in-periode"
                                    else "negeer",
                  $meting-sbgm-att := $meting/@*[namespace-uri() = 'http://sbg-synq.nl/sbg-metingen'],

                (: kopieer de attributen van de meetparen :)
                $meetpaar-att := if ( $meetpaar ) then $meetpaar/@* else (),
                (: NB pak deze attributen op vanaf de kopieen die sbg-epd aanmaakt, niet bekend in de oorspronkelijke clientmetingen :)
                (: ?? kies het 1e object: dit is nodig omdat er voormetingen zijn die ook nametingen zijn; meting-id is niet langer key :)
                $meting-epd := $metingen[@sbgm:meting-id = $m-id][1],
                $afstand := fn:days-from-duration($meting-epd/@sbge:afstand),
                $afstand-att := if ( $afstand ) then attribute { 'afstand' } { $afstand } else (),
                $meting-epd-att := $meting-epd/@*[local-name() = 'typemeting'],  (: dit sbggz attr wordt toegevoegd in sbg-epd :)
                $meting-sbge-att := $meting-epd/@*[namespace-uri() = 'http://sbg-synq.nl/sbg-epd']
                                
              order by $meting/@datum
              return element { 'Meting' } 
                            { attribute { 'test-soort' } { $soort }
                                union ($afstand-att, $meetpaar-att, $meting-att, $meting-epd-att, $meting-sbgm-att, $meting-sbge-att)
                            }
                        }
              </metingen>
              
        </dbc>
     }
    </patient>
  }
</result>
};



declare function local:select-atts($elt as element()?, $atts as xs:string*, $add-atts as attribute()* ) as element()? 
{
if ( $elt ) 
then 
  let $atts := for $ln in $atts
               return $elt/@*[name() = $ln][string-length(data(.)) gt 0]  
  return element { local-name( $elt ) } { $atts union $add-atts }
else ()
};

(: zet de resultaten om in in een test-beschrijving; 
NB gaat er van uit dat het resultaat correct is; (gebruik test-koppelproces.xsl om dit vast te stellen) 
:)
declare function local:build-test( $result as element(result) ) as element(tests)
{
<tests timestamp="{current-dateTime()}">
    <group  xmlns:sbgm='http://sbg-synq.nl/sbg-metingen'  xmlns:sbge='http://sbg-synq.nl/sbg-epd'>
        <functie>sbge:patient-dbc-meting</functie>
        <beschrijving>selecteer optimale metingen bij dbc</beschrijving>{
        for $dbc in $result//dbc
        let $koppelnummer := data($dbc/../@koppelnummer),
            $koppel-att := attribute { 'koppelnummer' } { $koppelnummer },
            $koppel-att-2 := attribute { 'sbgm:koppelnummer' } { $koppelnummer },
            $zorgcircuit-att := attribute { 'cl-zorgcircuit' } { 1 },
            $zorgtrajectnummer-att := attribute { 'zorgtrajectnummer' } { $koppelnummer },
            $test-id := concat($dbc/../@koppelnummer, '/', $dbc/@DBCTrajectnummer) 
        return 
        <test name="{concat( 'testscenario ', replace( $test-id, '/', ' met '))}" code="{$test-id}">
            <setup>
                {local:select-atts($dbc,("DBCTrajectnummer", "startdatumDBC", "einddatumDBC", "datumEersteSessie", "datumLaatsteSessie" ), ($koppel-att, $zorgcircuit-att, $zorgtrajectnummer-att))}
                {
                      for $meting in $dbc/metingen/*
                      return local:select-atts($meting, ("sbgm:meting-id", "datum", "gebruiktMeetinstrument"), ($koppel-att-2) )
                }
            </setup>
            <expected>
             { let $vm := ($dbc/metingen/Meting[@typemeting = '1'][@test-soort = 'optimaal'], $dbc/metingen/Meting[@typemeting = '1'][@test-soort = 'kandidaat'])[1], 
                   $nm := ($dbc/metingen/Meting[@typemeting = '2'][@test-soort = 'optimaal'], $dbc/metingen/Meting[@typemeting = '2'][@test-soort = 'kandidaat'])[1]
                for $m in ($vm, $nm)
                return local:select-atts($m, ("sbgm:meting-id", "typemeting", "datum", "gebruiktMeetinstrument"), ($koppel-att-2) ) 
             }
            </expected>
        </test>
        }
    </group>
</tests>
};

(: dit is de main-functie :)
(: $crit := [startdatumDBC/text() gt '2012-01-01'] :)
(: maak de test-set :)

(: local:build-test( $test-result ) :)
let 
    $test-result := local:test-result-dbcs($za/epd/*, $sbg-rom),
    $test-doc := local:build-test( $test-result ),
    $roundtrip := local:test-result-dbcs($test-doc//dbc, $test-doc//Meting)
return $test-result
