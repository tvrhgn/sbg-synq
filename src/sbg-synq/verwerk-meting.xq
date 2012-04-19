import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/modules/sbg-instrument.xquery';
import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at  '../sbg-synq/modules/sbg-metingen.xquery';

(: context heeft ./patient/meting :)

let $pats := .//patient
let $metingen := .//meting

let $instrumenten := sbgi:laad-instrumenten( .//instrument )

return <patient-doc xmlns:sbgm="http://sbg-synq.nl/sbg-metingen" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1">{
for $pat in $pats
return 
    element { 'metingen' } { $pat/@koppelnummer, 
        sbgm:sbg-metingen($pat/meting, $instrumenten)
        } 
}</patient-doc>


