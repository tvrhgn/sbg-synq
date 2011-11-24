(: importeer sbg-synq modules :)
import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';
import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/sbg-bmimport.xquery';


(: stuur-bestand
declare variable $zorgaanbieder := doc('../sbg-testdata/zorgaanbieder-testconfig.xml')/zorgaanbieder;
declare variable $zorgaanbieder := doc('http://localhost:8080/exist/rest/db/home/thijs/sbg-synq-za/zorgaanbieder.xml')/zorgaanbieder;

declare variable $zorgaanbieder := ./zorgaanbieder
 :)
 
 

declare variable $zorgaanbieder := doc('../sbg-testdata/zorgaanbieder-testconfig.xml')/zorgaanbieder;

let $za := sbgza:build-zorgaanbieder( $zorgaanbieder ),
    
        (: compileer de instrumenten :)
    $instrumenten := sbgi:laad-instrumenten( $za/instrumenten/sbg-instrumenten ),
    
    (: neem de batch-instellingen over  ?? meetperiode gaat naar zorgdomeinen:)
    $batch := sbgbm:batch-gegevens($zorgaanbieder),
    
    (: contrueer de Metingen uit de rom-data :)
    $sbg-rom := sbgm:sbg-metingen($za/rom/*, $za/rom-items/*, $instrumenten),
    (: construeer Patient; koppel de Metingen aan de DBCTrajecten :)

    (: combineer de metingen met de dbcs :)
    $patient-meting := sbge:patient-dbc-meting( $za/epd/*, $sbg-rom, $za/sbg-zorgdomeinen/* ),
    
    (: construeer BenchmarkImport op basis van de instellingen in zorgaanbieder (meetperiode en aanleverperiode); voeg NevendiagnoseCode en Behandelaar toe  :)
    $bmimport := sbgbm:build-sbg-bmimport($za, $patient-meting,  $za/epd/*, $za/behandelaar/*, $za/nevendiagnose/* )
return $bmimport



            

