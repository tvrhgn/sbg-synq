module namespace ramh = "http://sbg-ram.nl/html";

declare function ramh:css-name($str as xs:string) as xs:string {
lower-case(replace($str, "\s+", "-" ))
};

declare function ramh:ns-short( $ns as xs:string )
as xs:string
{
    concat( substring-after( $ns, '.nl/' ) , ':' )
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


(: maak een verticale tabel voor het huidie element :)
declare function ramh:atts-table-label( $elt as element() ) 
as element(table)
{
<table>{
let $name := local-name($elt)
return <tr class="{concat('table-header ', $name)}"><td>{$name}</td><td>{count($elt/preceding-sibling::*[local-name() eq $name]) + 1}</td></tr>
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
        <td>{$name}</td><td>{count($elts)}</td>
        {for $i in 3 to count($header) return <td/>}
        </tr>
return <table>{$caption}{ramh:tr( $header )}{
    for $elt in $elts
    return ramh:atts-tr-rect($elt, $header)}</table>
};

(: maak een table met 1 rij :)
declare function ramh:atts-table-single( $elt as element(), $header as xs:string* )
as element(table)
{
<table class="single">
<tr class="single">
<td>{local-name($elt)}</td>
{
for $h in $header
return ramh:att-td-compact($elt/@*[local-name() eq $h])
}<td class="count-children">{count($elt/*)}</td></tr></table>
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




(: maak een html-doc; geef 1 css href mee voor onmiddellijk resultaat; scripts e.d. elders :)  
declare function ramh:html-doc($content as element(div),  $css as xs:string? )
as element(html)
{
let $css-href := if (string-length($css) gt 0) then $css else 'sbg-ram.css' 
return <html><head>
 <link href="{$css-href}" rel="stylesheet" type="text/css"/>
</head>
<body>{$content}</body>
</html>
};
