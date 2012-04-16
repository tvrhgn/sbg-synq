import module namespace sbgbm = "http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/modules/sbg-bmimport.xquery';
declare namespace  sbggz = "http://sbggz.nl/schema/import/5.0.1";


let $pats := .//sbggz:Patient
let $za := .//zorgaanbieder

return <benchmark-info xmlns:sbggz = "http://sbggz.nl/schema/import/5.0.1">{
sbgbm:build-sbg-bmimport( $za, $pats )
}</benchmark-info>
