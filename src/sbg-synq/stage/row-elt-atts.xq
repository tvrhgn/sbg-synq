(: zet leaves om in elt/@att
deze stap is goedkoop
declare variable $row-doc as xs:string external;
 :)


declare variable $row-elt as xs:string external;


declare function local:build-atts( $row as element() ) as attribute()* {
  for $elt in $row/*
  return attribute { local-name($elt) } { data($elt) }
};

(: take parents of leaf elements :)
let $rows := .//*[*[not(*)]]

return 
    element { concat( $row-elt, '-doc') } { 
        for $row in $rows
        return element { $row-elt } { local:build-atts( $row ) }
    }




