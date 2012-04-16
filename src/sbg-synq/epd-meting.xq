import module namespace sbgem="http://sbg-synq.nl/epd-meting" at '../sbg-synq/modules/epd-meting.xquery';
declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


let $pats := .//patient
let $metingen := .//metingen
let $domeinen := .//zorgdomein

return <patient-doc xmlns:sbgem="http://sbg-synq.nl/epd-meting" xmlns:sbgm="http://sbg-synq.nl/sbg-metingen" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1">{
sbgem:maak-patient-meting($pats,$metingen,$domeinen)
}</patient-doc>
