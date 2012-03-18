import module namespace ramh = "http://sbg-ram.nl/html" at "ram-html.xquery";

declare variable $context-doc := .;
declare variable $test-run := $context-doc//test-run;
declare variable $test-doc := $context-doc//sbg-systeemtest;


declare variable $jquery := <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>;
declare variable $jquery-ui := <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>;

declare variable $ui-script := <script>
<![CDATA[
$(function(){
    $("#schema-tabs").tabs();
    $(".result-accordion-fail").accordion({autoHeight: false, collapsible: true});
    $(".result-accordion-pass").accordion({autoHeight: false, collapsible: true});
    $(".result-accordion-pass").accordion("activate",false)
});
]]>
</script>;


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
 declare function local:result-accordion( $result as element() )
 as element(div)
 {
 let $test := $test-doc//test[./@bron eq $result/@bron],
    $label := ($test/@bron, $result/@bron)[1],
    $aspect := ($test/aspect/text(), '- aspect n/a -')[1],
    $groep := $test/../../../name/text(),
    $sgroep := $test/../../name/text(),
    $ssgroep :=$test/../name/text(),
    $h3-div := <div>
            <span class="test-bron">{data($label)}</span>
            <span class="test-groep">{$groep}</span>
            <span class="test-sub-groep">{$sgroep}</span>
            <span class="test-sub-sub-groep">{$ssgroep}</span>
        </div>
 return
 <div>
   <h3>{$h3-div/*}</h3>
   <div class="result-view">
   <div class="aspect">
      {$aspect}
      </div>
      <div class="test">
      {$result/text()}
      </div>
   </div>
</div>
 };
 

let $content := 
    <div id="schema-tabs">
    <ol>
         <li><a href="#schema-info">schema</a></li>
        <li><a href="#schema-result">asserts</a></li>
 
    </ol>
    
    <div id="schema-result">
    
       <h2>resultaat</h2>
       {if ($test-run//result[@pass eq 'false'] ) 
        then <h2 class="fail">invalid</h2> else ()}
        
       <div class="result-accordion-fail">{
       for $res in $test-run//result[@pass eq 'false']
       let $view := local:result-accordion($res),
            $accordion := ($view/h3, $view/div)
        return $accordion
        }</div>
       
       <h2 class="pass">valid</h2>
       <div class="result-accordion-pass">{
        for $res in $test-run//result[@pass ne 'false']
        let $view := local:result-accordion($res),
            $accordion := ($view/h3, $view/div)
        return $accordion
       }</div>
       
    </div>
    
      <!-- eerste tab moet je het laatst toevoegen -->
     <div id="schema-info" class="schema-tab">
     <h2>schema info</h2>
     <div class="schema-info">
     {ramh:atts-table-label($test-run/info)}
     <p>benchmark-bestand: <code>{$test-run/info/document/text()}</code></p>
     {
        if ($test-run/info/schematron/failed/* ) 
        then <h2 class="fail">invalid</h2> else ()
        }
        {ramh:atts-table-rect($test-run/info/schematron/failed/*)}
        <h2 class="pass">valid</h2>
        {ramh:atts-table-rect($test-run/info/schematron/passed/*)}
        </div>
    </div>
    
  </div>  
return ramh:html-doc-jquery( <div>{$ui-script}{$content}</div>, "" )


