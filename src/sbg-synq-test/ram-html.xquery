module namespace ramh = "http://sbg-ram.nl/html";

declare variable $ramh:reverse-ns := <reverse-ns>
<ns uri="http://sbg-synq.nl/sbg-epd">sbge</ns>
<ns uri="http://sbg-synq.nl/sbg-instrument">sbgi</ns>
<ns uri="http://sbg-synq.nl/sbg-metingen">sbgm</ns>
<ns uri="http://sbg-synq.nl/sbg-benchmark">sbgbm</ns>
<ns uri="http://sbg-synq.nl/epd-meting">sbgem</ns>
<ns uri="http://sbg-synq.nl/zorgaanbieder">sbgza</ns>
<ns uri= "http://sbggz.nl/schema/import/5.0.1">sbggz</ns>
</reverse-ns>;

declare function ramh:css-name($str as xs:string) as xs:string {
lower-case(replace($str, "\s+", "-" ))
};

declare function ramh:ns-short( $ns as xs:string )
as xs:string
{
    concat( $ramh:reverse-ns/ns[@uri eq $ns]/text(), ':' )
};

declare function ramh:att-td ( $att as attribute() )
as element(td)
{
<td class="{concat('data ', local-name($att))}">{data($att)}</td>
};

declare function ramh:att-td-label ( $att as attribute() )
as element(td)
{
let $ns := namespace-uri($att)
let $prefix := if (string-length($ns) gt 0 ) then ramh:ns-short($ns)  else '' 
return <td class="{concat('label ', local-name($att))}">{concat($prefix, local-name($att))}</td>
};

declare function ramh:att-td-compact ( $att as attribute() )
as element(td)
{
let $ns := namespace-uri($att)
let $prefix := if (string-length($ns) gt 0 ) then ramh:ns-short($ns)  else '' 
return <td class="{concat('label ', local-name($att))}">{concat($prefix, local-name($att), ': ', data($att))}</td>
};

declare function ramh:att-tr-label ( $att as attribute() )
as element(tr)
{
<tr>
{ramh:att-td-label( $att )}
{ramh:att-td( $att )}
</tr>
};

declare function ramh:atts-tr( $elt as element() ) 
as element(tr)
{
let $name := local-name($elt)
return <tr>{
for $att in $elt/@*
order by local-name($att)
return ramh:att-td( $att )
}</tr>
};

declare function ramh:tr( $labels as xs:string* )
as element(tr)
{
<tr>{
for $label in $labels 
return ramh:att-td( attribute { 'caption' } { $label })
}</tr>
};


(: maak een regel in een tabel met kop-regel boven :)

declare function ramh:atts-tr-rect( $elt as element(), $header as xs:string* )
as element(tr)
{
<tr>{
for $name in $header
let $att := $elt/@*[local-name() eq $name]
return if ( $att ) then ramh:att-td($att) else <td/>
}</tr>
};

declare function ramh:rect-header( $elts as element()* )
as xs:string*
{
distinct-values( 
    for $att in $elts/@*
    return local-name($att))
};


declare function ramh:count-levels($elt as node() )
as xs:integer
{
if ( $elt/* ) then 
1 + max( for $e in $elt/* return ramh:count-levels( $e )) 
else 1
};

declare function ramh:empty-cells( $cnt as xs:integer )
as element(td)*
{
for $i in 1 to $cnt return <td></td>
};

declare function ramh:att-tr-infix ( $skip as xs:integer, $att as attribute(), $append as xs:integer )
as element(tr)
{
<tr>
{ramh:empty-cells($skip)}
{ramh:att-td-label( $att )}
{ramh:att-td( $att )}
{ramh:empty-cells($append)}
</tr>
};

declare function ramh:atts-tr-infix ( $skip as xs:integer, $atts as attribute()*, $append as xs:integer )
as element(tr)*
{
for $att in $atts
return ramh:att-tr-infix( $skip, $att, $append )
};

declare function ramh:elt-tr-infix( $skip as xs:integer, $elt as element(), $width as xs:integer )
as element(table)*
{
let $name := local-name($elt),
    $append := $width - $skip - 2
return <div>
<table class="{concat( 'ram-tree ', $name)}">
<tr>{ramh:empty-cells($skip)}
    <td class="{concat( 'ram-tree-elt ', $name)}">{$name}</td>
    <td class="{concat( 'ram-tree-elt-desc ', $name)}">{$elt/text()}</td>
     {ramh:empty-cells( $append )
}</tr>
{ramh:atts-tr-infix( $skip, $elt/@*, $append)}
</table>
{ for $e in $elt/* return ramh:elt-tr-infix( $skip + 1, $e, $width )} 
</div>//table
};

declare function ramh:elt-tree( $elt as element() )
as element(table)*
{
let $levels := ramh:count-levels($elt),
    $width := $levels + 1

return ramh:elt-tr-infix( 0, $elt, $width )

};

(: -- hieronder de tabel-typen die de module-gebruiker nodig heeft --:)

(: maak een verticale tabel voor het huidie element :)
declare function ramh:atts-table-label( $elt as element() ) 
as element(table)
{
<table>{
let $name := local-name($elt)
return <tr class="{concat('object-label ', $name)}"><td>{$name}</td><td class="count-preceding">{count($elt/preceding-sibling::*[local-name() eq $name]) + 1}</td></tr>
}{
for $att in $elt/@*
let $att-name := local-name($att)
order by $att-name
return ramh:att-tr-label($att)
}</table>
};


(: maak een horizontale tabel met een kopregel voor een serie gelijksoortige element  :)
declare function ramh:atts-table-rect( $elts as element()* ) 
as element(table)
{
let $name := local-name($elts[1])
let $header := ramh:rect-header($elts)
let $caption :=  <tr class="{concat('table-header ', $name)}">
        <td class="count-children">{count($elts)}</td>
        <td class="{concat('object-label ', $name)}">{$name}</td>
        {for $i in 3 to count($header) return <td/>}
        </tr>
return <table>{$caption}{ramh:tr( $header )}{
    for $elt in $elts
    return ramh:atts-tr-rect($elt, $header)}</table>
};

(: maak een horizontale tabel met een kopregel voor een serie gelijksoortige element  :)
declare function ramh:atts-table-rect-label( $elts as element()*, $label as xs:string ) 
as element(table)
{
let $name := local-name($elts[1])
let $header := ramh:rect-header($elts)
let $caption :=  <tr class="{concat('table-header ', $name)}">
        <td class="count-children">{count($elts)}</td>
        <td class="{concat('object-label ', $name)}">{$label}</td>
        {for $i in 3 to count($header) return <td/>}
        </tr>
return <table>{$caption}{ramh:tr( $header )}{
    for $elt in $elts
    return ramh:atts-tr-rect($elt, $header)}</table>
};

(: maak een horizontale tabel met een kopregel voor een serie gelijksoortige element  :)
declare function ramh:atts-table-rect-header( $elts as element()*, $header as xs:string+ ) 
as element(table)
{
let $name := local-name($elts[1])
let $caption :=  <tr class="{concat('table-header ', $name)}">
        <td class="count-children">{count($elts)}</td>
        <td class="{concat('object-label ', $name)}">{$name}</td>
        {for $i in 3 to count($header) return <td/>}
        </tr>
return <table>{$caption}{ramh:tr( $header )}{
    for $elt in $elts
    return ramh:atts-tr-rect($elt, $header)}</table>
};

(: maak een table met 1 rij; tel het aantal children:)
declare function ramh:atts-table-single( $elt as element(), $header as xs:string* )
as element(table)
{
<table class="single">
<tr class="single">
{
for $h in $header
return ramh:att-td-compact($elt/@*[local-name() eq $h])
}<td class="count-children">{count($elt/*)}</td>
<td class="object-label">{local-name($elt)}</td>
</tr></table>
}; 


(: loop een hierarchie af en maak table-singles voor de structuur elementen; liever geen geneste tables? :)
declare function ramh:atts-table-tree( $elt as element() ) 
as element(div)
{
let $children := $elt/*[./*],
    $att-names := distinct-values(for $att in $elt/@* return local-name($att))
return <div class="table-tree">
    {   ramh:atts-table-single($elt, $att-names) }
    {  for $ch in $children
       return ramh:atts-table-tree( $ch ) }
 </div>
   
};

(: draag de data van een element en geselecteerde subelementn (namen) over naar 1 niveau van atts 
werkt alleen als de qnames uniek zijn; alles wordt omgezet naar een attribute :)
declare function ramh:flatten-sub-elts($elt as element(), $sub-elts as xs:string*)
as element()
{
let $subs := $elt/*[count(index-of($sub-elts, local-name())) ge 1],
    $atts := $subs/@*,
    $text-atts := for $e in $subs[text()] return attribute { local-name($e) } { $e/text() }
return element { local-name($elt) }
        { $elt/@*
          union $atts
          union $text-atts
        }
};

(: loop een hierarchie af en pik alle waarden en plaats in een labeled tree :) 
declare function ramh:table-flatten( $elt as element(), $sub-elts as xs:string* ) 
as element(table)
{
ramh:atts-table-label(ramh:flatten-sub-elts($elt, $sub-elts))
};


declare function ramh:html-doc-head($content as element(div),  $head-content as element()* )
as element(html)
{
<html>
    <head>{$head-content}</head>
<body>{$content}</body>
</html>
};


(: maak een ul met een id eindigend op -tab :)
declare function ramh:jquery-tabs-ul($elts as element()*, $label as xs:string )
as element(ul)
{
let $name := local-name($elts[1])
return 
    <ul id="{concat($name, '-tabs')}">{
        for $elt at $ix in $elts
        let $tab-id := concat($name, '-', $ix )
        return <li><a href="{concat( '#', $tab-id)}" class="{concat( $name, '-tab')}">{data(  ($elt/*[local-name() eq $label]/@label, $elt/@*[local-name() eq $label], $elt/*[local-name() eq $label]) [1]       ) }</a></li>
}</ul>
};


declare function ramh:html-doc-jquery($content as element(div),  $css as xs:string? )
as element(html)
{
let $css-href := if (string-length($css) gt 0) then $css else 'sbg-ram.css',
    $head := (

    <link rel="stylesheet" type="text/css" href="css/ui-lightness/jquery-ui-1.8.9.custom.css"></link>,
    <link href="{$css-href}" rel="stylesheet" type="text/css"/>,
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>,
    <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    )
return ramh:html-doc-head($content, $head)
};

(: maak een html-doc; geef 1 css href mee voor onmiddellijk resultaat; scripts e.d. elders :)  
declare function ramh:html-doc($content as element(div),  $css as xs:string? )
as element(html)
{
let $css-href := if (string-length($css) gt 0) then $css else 'sbg-ram.css' 
return ramh:html-doc-head($content, <link href="{$css-href}" rel="stylesheet" type="text/css"/>)
};
