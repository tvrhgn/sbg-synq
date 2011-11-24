module namespace sbgza = "http://sbg-synq.nl/zorgaanbieder";
(: voorstelling van de zorgaanbieder; batch-instellingen en document-verwijzingen worden hier verwerkt :)

(: get-collection(): zoek een document adhv verwijzing in stuur-bestand :)
(: retourneer een element voor gammelijke toegang tot de collecties :)
(: NB het is van belang dat de collectie namen niet overlappen met de element-namen van zorgaanbieder :)
declare function sbgza:get-collection( $zorgaanbieder as element(zorgaanbieder), $name as xs:string ) as element()*
{
    let $ref := $zorgaanbieder//collection[@name=$name][1]
    return element { $name } { (), doc(data($ref/@uri))//*[local-name()=data($ref/@elt)] }
};

(: hieronder de gedefinieerde standaard collecties :)
declare function sbgza:build-zorgaanbieder( $za as element(zorgaanbieder) ) as element(zorgaanbieder)
{
let $zorgdomeinen :=  sbgza:get-collection($za, 'sbg-zorgdomeinen'),
    $instr-lib  :=  sbgza:get-collection($za, 'instrumenten'),
    $epd := sbgza:get-collection($za,  'epd' ),
    $rom := sbgza:get-collection($za,  'rom' ),
    $behandelaar := sbgza:get-collection($za, 'behandelaar'),
    $nevendiagnose  :=  sbgza:get-collection($za, 'nevendiagnose'),
    $rom-items := sbgza:get-collection($za, 'rom-items')
    return element { 'zorgaanbieder' } { $za/@*, $za/* 
            union ( $epd, $rom, $zorgdomeinen, $instr-lib, $behandelaar, $nevendiagnose, $rom-items )
            }     

};

