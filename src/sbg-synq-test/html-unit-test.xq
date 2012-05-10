import module namespace ramh = "http://sbg-ram.nl/html" at "ram-html.xquery";
declare namespace sbgem="http://sbg-synq.nl/epd-meting";
declare namespace sbggz = "http://sbggz.nl/schema/import/5.0.1";

declare variable $result := .;

declare variable $jquery := <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>;
declare variable $jquery-ui := <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>;

declare variable $ui-script := <script>
<![CDATA[
$(function(){
    $("#result-doc").tabs();
    $("#group-tabs-1").tabs();
    $("#group-tabs-2").tabs();
    $("#group-tabs-3").tabs();
    $("#group-tabs-4").tabs();
    
    $(".test-accordion-fail").accordion({autoHeight: false, collapsible: true});
    $(".test-accordion-pass").accordion({autoHeight: false, collapsible: true});
    $(".test-accordion-pass").accordion("activate",false)
});
]]>
</script>;

(:

:)
declare function local:view-object($obj as element()* ) 
as element(div)*
{
let $name := local-name($obj)
return <div class="{$name}">{
if ( $name eq 'DBCTraject' ) then (ramh:atts-table-label($obj), for $o in $obj/* return local:view-object($o))
else if ( $name eq 'Patient' ) then (ramh:atts-table-label($obj), for $o in $obj/* return local:view-object($o))

else if ( $name eq 'Zorgtraject' ) then (ramh:atts-table-label($obj), for $o in $obj/* return local:view-object($o))
else if ( $name eq 'zorgaanbieder' ) then ramh:table-flatten($obj/batch[1], ('einddatumAangeleverdePeriode', 'aanleverperiode'))
else if ( $name eq 'batch' ) then (ramh:atts-table-label($obj), for $o in $obj/* return local:view-object($o))
else if ( $name eq 'batch-gegevens' ) then ramh:atts-table-label($obj)  
else if ( $name eq 'zorgdomein' ) then ramh:table-flatten($obj, ('naam', 'meetperiode')) 

else if ( $obj/@* and $name eq 'value' )   then ramh:atts-table-label($obj)
else if ( $name eq 'value' or $name eq 'def' )   then <div class="value">{data($obj)}</div>

else if ( $name eq 'Meting' or $name eq 'meting') then if ( count($obj/preceding-sibling::*[local-name() eq 'Meting' or local-name() eq 'meting']) eq 0 )
                                    then ramh:atts-table-rect(($obj, $obj/following-sibling::*[local-name() eq 'Meting' or local-name() eq 'meting']))
                                    else ()
else if ( $name eq 'Item' or $name eq 'item' ) then if ( count($obj/preceding-sibling::*[local-name() eq 'Item' or local-name() eq 'item']) eq 0 )
                                    then ramh:atts-table-rect(($obj, $obj/following-sibling::*[local-name() eq 'Item' or local-name() eq 'item']))
                                    else ()                                    

else if ( $name eq 'instrument' ) then ramh:elt-tree($obj)
                                    
else if ( $name eq 'meetparen' ) then (ramh:atts-table-tree($obj), local:view-object($obj//sbggz:Meting[1]))
else if ( $name eq 'row' ) then ramh:table-flatten( $obj, for $elt in $obj/* return local-name($elt))
else if ( $name eq 'kandidaat-metingen' ) then (ramh:atts-table-tree($obj), local:view-object($obj/voor/sbggz:Meting[1]), local:view-object($obj/na/sbgem:Meting[1]))
else for $o in $obj/* return local:view-object($o)
}</div>
}; 


 (: return h3 / div pairs for accordion :)
 declare function local:test-accordion( $tests as element()* )
 as element(div)
 {
 for $test at $test_ix in $tests
 let $pass := xs:boolean($test/@pass),
     $label := concat( $test/@code, ': ', $test/@name )
 return
 <div>
   <h3>
       {concat( $test/@name, ' ', $test/description)}
   </h3>
   <div class="test-view">
     <div class="setup">{
          for $obj in $test/setup/* return local:view-object($obj)
      }</div>
      <div class="expected">{
          for $obj in $test/expected/* return local:view-object($obj)
      }</div>
      { if ( not($pass) ) 
        then <div class="actual">{
            for $obj in $test/actual/* return local:view-object($obj)
            }</div>
        else ()
      }
   </div>
</div>
 };
 

let $content :=

<div id="result-doc">
{ramh:jquery-tabs-ul($result//result, 'description')}
{for $tests at $ix in $result//result
  return  
  <div class="result-tab" id="{concat( 'result-', $ix)}">
    <div id="{concat( 'group-tabs-', $ix)}" >
    <ul>{ 
        for $group at $group_ix in $tests/group
        let $gr-id := concat( 'group_', $ix, '_', $group_ix )
        return <li><a href="{concat( '#', $gr-id)}">{$group/function/text()}</a></li>
    }</ul>
    
    {
    for $group at $group_ix in $tests/group
    let $gr-id := concat( 'group_', $ix, '_', $group_ix )
    return 
    <div id="{$gr-id}" class="group-tab">
        <p>{$group/description}</p>
        {if ($group/test[@pass eq 'false'] ) then <h2 class="fail">fail</h2> else ()}
        <div class="test-accordion-fail">{
        for $test at $test_ix in $group/test[@pass eq 'false']
        let $view := local:test-accordion($test),
            $accordion := ($view/h3, $view/div)
        return  $accordion
        }</div>
        <h2 class="pass">pass</h2>
        <div class="test-accordion-pass">{
        for $test at $test_ix in $group/test[@pass ne 'false']
        let $view := local:test-accordion($test),
            $accordion := ($view/h3, $view/div)
        return  $accordion
        }</div>
    </div>
    }</div>  
    </div>
}</div>


return ramh:html-doc-jquery( <div>{$ui-script}{$content}</div>, "css/sbg-ram.css" )


