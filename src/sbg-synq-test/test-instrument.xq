(: importeer sbg-synq modules :)
import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';

(: stuur-bestand :)
declare variable $zorgaanbieder := doc('../sbg-testdata/zorgaanbieder-testconfig.xml')/zorgaanbieder;

declare variable $zorgdomeinen :=  local:get-collection('zorgdomeinen');

declare variable $instr-lib  :=  local:get-collection('instrumenten');
declare variable $test-metingen := local:get-collection( 'rom' );
declare variable $rom-items := local:get-collection('rom-items');    
     
declare variable $instrumenten := sbgi:laad-instrumenten( $instr-lib );
    (: contrueer de Metingen uit de rom-data :)
declare variable $sbg-rom := sbgm:sbg-metingen($test-metingen,$rom-items,$instrumenten);
    (: construeer Patient; koppel de Metingen aan de DBCTrajecten :)


(: zoek een document adhv verwijzing in stuur-bestand :)
declare function local:get-collection( $name as xs:string ) as item()*
{
    let $ref := $zorgaanbieder//collection[@name=$name][1] 
    return doc(data($ref/@uri))//*[local-name()=data($ref/@elt)]
};

declare function local:test-mansa( ) as element(result)
{
<result>
{
let $instr-code := 'MANSA'
for $meting in $test-metingen[gebruiktMeetinstrument/text()=$instr-code]
let $items := $rom-items[meting-id = $meting/meting-id],
  $instr := $instrumenten[@code=$meting/gebruiktMeetinstrument]
  return <meting id="{$meting/meting-id}">
    
    <score-controle>
      {sbgi:schaal-score($instr/schaal[1],$items)}
    </score-controle>
    <sbg-interface>
      {sbgm:sbg-metingen($meting,$items,$instrumenten)}
    </sbg-interface>
  </meting>
}
</result>
};

declare function local:test-laad-instrumenten( ) as element(result)
{
<result>
{$instrumenten}
</result>
};


    
    

(:
 
 local:test-laad-instrumenten() 
:)

local:test-mansa()

