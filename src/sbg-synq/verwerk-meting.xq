import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/modules/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at  '../sbg-synq/modules/sbg-metingen.xquery';


let $pats := .//patient

let $instrumenten := sbgi:laad-instrumenten( .//instrument )

return <patient-doc>{
for $pat in $pats
return 
    element { 'metingen' } { $pat/@koppelnummer, 
        sbgm:sbg-metingen($pat/meting, $instrumenten)
        } 
}</patient-doc>


