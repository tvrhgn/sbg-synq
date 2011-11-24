module namespace sbgtest = 'http://sbg-synq.nl/sbg-test';

(: bibliotheek van tests tegen een sbg uitvoerbestand :)
(: mini-vocabulaire: run-tests(doc, codelijst) geeft elementen in (test-results ( result*)) :) 
(: met attributen bron (verwijzing naar sbg-spreadsheet) en waarde (true of false) op het elt result :)
(: en evt een toelichting in de text-node :)

(: NB hier worden geen sbg-synq modules gebruikt :)
(: daardoor te gebruiken als een black-box test van diezelfde sbg-synq modules :)

(: okt 2011: meeste tests gemigreerd naar schematron :)
declare namespace  sbg = "http://sbggz.nl/schema/import/5.0.1";


declare function sbgtest:test-unique( $nd as node()* ) as xs:boolean {
    (: als het aantal verschillende waarden gelijk is aan het aantal data-elementen is elke waarde uniek 
    ? $nd and :)
    count( distinct-values( data($nd))) = count( $nd ) 
};

declare function sbgtest:test-reeks( $str as xs:string, $codelijst as element(codelijst) ) as xs:boolean
{
    exists( $codelijst/item[@code=$str] )
};

(: diagnosecode bestaat uit cijfers en punten voorafgegaan door as1_ of as2_ :)
declare function sbgtest:geldige-diagnose( $str as xs:string* ) as xs:boolean
{
    every $d in distinct-values( $str )
    satisfies matches( $d, 'as(1|2)_[0-9.]+' ) or $d = 'nb'
};


(: het resultaat van een test :)
declare function sbgtest:test-elt( $ref as xs:string, $doc as xs:string, $val as xs:boolean ) as element(result) {
    <result bron="{$ref}" waarde="{$val}" type="sbg-synq-test">{$doc}</result>
};

declare function sbgtest:add-tests( $test-doc as element(test-results), $tests as element(result)* ) as element(test-results)
{
    element { 'test-results' } { $test-doc//result, 
                                for $t in $tests
                                return if ( exists( $test-doc[@bron = $t/@bron] ) ) then () else $t }
};


(: hier worden de tests gedaan :)
(: was: declare function sbgtest:run-tests( $sbg-doc as document-node(), $code-doc as element(sbg-codelijsten) ) as element(test-results) :)
declare function sbgtest:run-tests( $sbg-doc as element(sbg:BenchmarkImport), $code-doc as element(sbg-codelijsten) ) as element(test-results) 
{
let $sbg-atts := element { 'batch-gegevens' } { $sbg-doc/@*, () },
    (: was: element { 'batch-gegevens' } { $sbg-doc//sbg:BenchmarkImport/@*, () },
      atts van het document-element kun je niet rechstreeks adresseren :)
     
    $zorgaanbieder := $sbg-doc//sbg:Zorgaanbieder,
    $patient := $zorgaanbieder//sbg:Patient,
    $zorgtraject := $zorgaanbieder//sbg:Zorgtraject,
    $dbctraject := $zorgaanbieder//sbg:DBCTraject,
    $behandelaar := $zorgaanbieder//sbg:Behandelaar,
    $meting := $dbctraject//sbg:Meting,
    $aantal-dbc := count($dbctraject),
    $aantal-gesloten := count($dbctraject[@redenSluiten or @einddatumDBC])

    return  <test-results>
    <test-info versie="0.9" start="{current-dateTime()}" type="sbg-synq-test">
    Naast de schema-validatie worden ook rechtstreeks controles gedaan op het benchmark bestand. Hieronder algemene kenmerken van het bestand.
        <aantal-dbc>{$aantal-dbc}</aantal-dbc>
        <aantal-metingen>{count($meting)}</aantal-metingen>
        <optimaal-minimum>{$aantal-dbc + $aantal-gesloten}</optimaal-minimum>
    </test-info>{
    sbgtest:test-elt('Algemeen_3',  '?? interpretatie: aantal zorgaanbieders groter dan 0', count($sbg-doc//sbg:Zorgaanbieder) > 0),
    sbgtest:test-elt('Algemeen_4',  '?? interpretatie: aantal attributen met lege string als data is 0',
                    count($sbg-doc//@*[data(.)='']) = 0),
    
    sbgtest:test-elt('Data Extractie_9',  'er is geen dbctraject met einddatum buiten periode',
                let $start := xs:date($sbg-atts/@startdatumAangeleverdePeriode),
                    $eind := xs:date($sbg-atts/@einddatumAangeleverdePeriode),
                    $pass := not(exists($dbctraject[xs:date(@einddatumDBC) lt $start]) or exists($dbctraject[xs:date(@einddatumDBC) gt $eind]))  
                return $pass ),
     
     
     sbgtest:test-elt('Structuur Controles_4', 'een instrument is uniek per typemeting (als het instrument maar in 1 meetdomein wordt gebruikt)',
                    every $dbc in $dbctraject
                    satisfies sbgtest:test-unique($dbc/sbg:Meting[@typemeting=1]/@gebruiktMeetinstrument)
                    and sbgtest:test-unique($dbc/sbg:Meting[@typemeting=2]/@gebruiktMeetinstrument)),
                    
                    
    sbgtest:test-elt( 'Structuur Controles_6', 'itemnummer moet uniek zijn in meting',
                    every $m in $meting
                    satisfies sbgtest:test-unique( $m//sbg:Item/@itemnummer )),
                    
     sbgtest:test-elt( 'Structuur Controles_7', 'zorgtrajectnummer uniek per patient',
                    every $p in $patient
                    satisfies sbgtest:test-unique( $p//sbg:Zorgtraject/@zorgtrajectnummer )),
    
     sbgtest:test-elt('Structuur Controles_8','behandelaar alias uniek per zorgtraject',
                     every $zt in $zorgtraject 
                     satisfies sbgtest:test-unique( $zt/sbg:Behandelaar/@alias )),
                     
     sbgtest:test-elt('Structuur Controles_11', 'nevendiagnosecode uniek per zorgtraject voor elke patient',
                     every $p in $patient, $zt in $p/sbg:Zorgtraject 
                     satisfies sbgtest:test-unique( $zt/sbg:NevendiagnoseCode/@nevendiagnoseCode )),
                     
    
     

    sbgtest:test-elt( 'Attribuut Controle_96', 'geldige diagnosecode', sbgtest:geldige-diagnose($zorgtraject/@primaireDiagnoseCode)),

     sbgtest:test-elt( 'Attribuut Controle_3', 'OK: startdatumAangeleverdePeriode onderdeel van configuratie (ref unit-test?)',
                     true()),

    sbgtest:test-elt( 'Attribuut Controle_22', 'getest in test-optimale-meting.xq', true()),
    
    
    sbgtest:test-elt( 'Attribuut Controle_56', 'type meting 1 of 2', 
        every $tm in distinct-values(data($meting/@typemeting))
        satisfies $tm = '1' or $tm = '2')           
                                                                                        
   }</test-results>                            
                                            
};

