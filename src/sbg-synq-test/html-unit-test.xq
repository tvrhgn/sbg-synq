import module namespace ramh = "http://sbg-ram.nl/html" at "ram-html.xquery";

declare variable $result := /*;


let $content := 
    for $group in $result//group
    return <div><h2>{$group/function/text()}</h2>
        <p>{$group/description}</p>
    {
    for $test in $group//test
    let $pass := xs:boolean($test/@pass),
        $label := concat( $test/@code, ': ', $test/@name )
    return <div class="test">
        <div class="{concat( 'status pass-', $pass)}">{$label}</div>
        <div class="test desc">{$test/description/text()}</div>{
        if ( not($pass) ) 
        then <div class="actual">
            {ramh:atts-table-tree($test/actual)}
            {ramh:atts-table-rect($test/actual//*[not(./*)])}
        </div>
        else () 
        }
    </div>
}</div>
return ramh:html-doc( <div>{$content}</div>, "" )


