import module namespace ramh = "http://sbg-ram.nl/html" at "ram-html.xquery";

declare variable $result := /*;

declare variable $jquery := <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>;
declare variable $jquery-ui := <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>;

declare variable $ui-script := <script>
<![CDATA[
$(function(){
    $("#group-tabs").tabs();
    $(".test-accordion-fail").accordion({autoHeight: false, collapsible: true});
    $(".test-accordion-fail").accordion("activate",false);
    $(".test-accordion-pass").accordion({autoHeight: false, collapsible: true});
    $(".test-accordion-pass").accordion("activate",false)
});
]]>
</script>;

declare function local:view-object($obj as element() ) 
as element(div)
{
let $name := local-name($obj)
return <div>{
if ( $name eq 'DBCTraject' ) then ramh:atts-table-label($obj)
else if ( $name eq 'Zorgtraject' ) then ramh:atts-table-rect($obj) 
else if ( $name eq 'zorgdomein' ) then (ramh:atts-table-rect($obj), ramh:atts-table-label($obj/meetperiode) )
else if ( $name eq 'value' ) then <div class="value">{data($obj/value)}</div>
else if ( $name eq 'Meting' ) then if ( count($obj/preceding-sibling::*[local-name() eq 'Meting']) eq 0 )
                                    then ramh:atts-table-rect(($obj, $obj/following-sibling::*[local-name() eq 'Meting']))
                                    else ()
else <div class="container">{for $o in $obj/* return local:view-object($o)}</div>
}</div>
}; 

(: maak een ul met een id eindigend op -tab
declare function local:jquery-tabs($elts as element(), $label as xs:string )
as element(ul)
{
let $name := local-name($elts[1])
return 
<ul id="{concat($name, '-tabs')}">{
    for $elt at $ix in $elts
    let $tab-id := concat($name, '-', $ix )
    return <li><a href="{concat( '#', $tab-id)}" class="{concat( $name, '-tab')}">{data($elt/*[local-name() eq $label])}</a></li>
}</ul>
};

<span class="{concat( 'status pass-', $pass)}">{$test/@code}</span>
 :)
 
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
      <div class="actual">{
          for $obj in $test/actual/* return local:view-object($obj)
      }</div>
   </div>
</div>
 };
 

let $content := 
    <div id="group-tabs">
    <ul>{ 
        for $group at $group_ix in $result/group
        let $gr-id := concat( 'group', $group_ix )
        return <li><a href="{concat( '#', $gr-id)}">{$group/function/text()}</a></li>
    }</ul>
    
    {
    for $group at $group_ix in $result/group
    let $gr-id := concat( 'group', $group_ix )
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
return ramh:html-doc-jquery( <div>{$ui-script}{$content}</div>, "" )


