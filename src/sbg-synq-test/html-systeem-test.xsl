<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xi="http://www.w3.org/2001/XInclude"
	
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	
	exclude-result-prefixes="xi">
	<xsl:output method="xhtml"></xsl:output>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="concat( 'sbg-synq systeem test ', 0.9 ) " />
				</title>
				<style type="text/css">
					<xi:include
						href="file:/home/thijs/project/eclipse-rep/sbg-testdata/xsbg-testdata.css"
						parse="text">
						<xi:fallback>
							.kenmerk-control { background-color: hsl( 30, 100%, 50% ); color: white; width:
							20em }
							.kenmerk-control.off { background-color: hsl( 30, 100%, 70% ) }
							.groep-control { width: 20em; }
							.groep-control.off {border: 2px solid green }
							.groep-control .aantal { display: block; font-size: 80%; vertical-align: bottom
							}
							#kenmerkcontrols { display: table }
							#kenmerkcontrols > div { display: table-cell; text-align: center }
							#groepcontrols { display: table; font-size: 85% }
							#groepcontrols > div { display: table-cell; text-align: center }
							.aantal { display: inline; align: right }

							.test { display: table; font-family: arial; display: block; position:
							relative; top: 0.2em; width: 50em; padding-bottom: 1em; left: 5em
							}
							.test.off { display: none; }
							.test.fail > div.bron { background-color: pink }
							.test.pass > div.bron { background-color: lightgreen }
							.test.missed > div.bron { background-color: lightblue }
							.test-control { display: table-cell; padding: 1em; }
							.test-control.s-fail { background-color: pink }
							.test-control.s-pass { background-color: lightgreen }
							.test-control.s-missed { background-color: lightblue }

							.bron { display: table-cell; width: 10em; padding-left: 1em;font-size:
							75% }
							.groep { display: table-cell; padding-left: 1em;font-size: 90% }
							.subgroep { display: table-cell; padding-left: 1em;font-size: 90%
							}
							.subsubgroep { display: table-cell; padding-left: 1em; }
							.aspect { display: table; padding: 2em; width: 30em; border: 1px solid
							green }
							.result { font-style: italic; align: right}
							.kenmerk {display: table-cell; padding-left: 1em; font-style: italic;
							font-size: 90%; border: 1px dashed orangej; background-color:
							hsl( 30, 100%, 50% ); color: white }
					</xi:fallback>
					</xi:include>
				</style>
				<script type="text/javascript" src="jquery-1.6.2.min.js"></script>
				<script type="text/javascript" src="checklist-systeemtest.js"></script>

			</head>
				<xsl:copy-of select="/div" />
		</html>

	</xsl:template>

</xsl:stylesheet>