import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/modules/zorgaanbieder.xquery';
import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/modules/sbg-bmimport.xquery';


let $patient := .//patient
let $batch := sbgza:batch-gegevens(.//zorgaanbieder)

return <patient-selectie>{
    sbgbm:filter-batchperiode( $batch, $patient )
}</patient-selectie>


