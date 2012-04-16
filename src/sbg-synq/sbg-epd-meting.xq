import module namespace sbge="http://sbg-synq.nl/sbg-epd"  at '../sbg-synq/modules/sbg-epd.xquery';

declare namespace sbgm="http://sbg-synq.nl/sbg-metingen";
declare namespace sbgem="http://sbg-synq.nl/epd-meting";
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


let $pats := .//sbgem:Patient
let $domeinen := .//zorgdomein

return <patient-doc xmlns:sbge="http://sbg-synq.nl/sbg-epd" xmlns:sbgem="http://sbg-synq.nl/epd-meting" xmlns:sbgm="http://sbg-synq.nl/sbg-metingen" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1">{
sbge:sbg-patient-meting($pats, $domeinen)
}</patient-doc>
