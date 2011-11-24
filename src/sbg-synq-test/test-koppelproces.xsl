<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:xi="http://www.w3.org/2001/XInclude"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:sbgm="http://sbg-synq.nl/sbg-metingen"
	xmlns:sbge="http://sbg-synq.nl/sbg-epd"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	>
	<xsl:output method="html"/>
<!--  -->
	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="concat( 'sbg-synq test koppelproces', 0.9 ) " />
				</title>
				<link rel="stylesheet" type="text/css" href="xsbg-testdata.css" />
				
				<style type="text/css">
					<xi:include
						href="file:/home/thijs/project/eclipse-rep/sbg-testdata/xsbg-testdata.css"
						parse="text">
<xi:fallback>
body { color:black }
td { text-align: center; padding-left: 1em; padding-right: 1em;}
tr {height: 1.2em }
table.client { padding: 2em; }
td.client {width: 16em }

.dbc-datums tr { background-color: #E08E1B;  }
.dbc-datums tr:nth-child(odd) { background-color: #E0B91B;  }
.dbc-datums tr:nth-child(even) { background-color: #E08E1B;  }

tr.meting { background-color: #9DE;  }
tr.meting:nth-child(odd) { background-color: #AEF;  }
tr.meting:nth-child(even) { background-color: #9DE;  }

.afstand { background-color: white }

.optimaal  { border: 2px solid blue;}
.kandidaat { border: 3px dotted blue }
.voor  { background-color: lightgreen }
.na  { background-color: pink }
.in-periode { color: #11A	 }
.meting-id { font-size: small }
</xi:fallback>
					</xi:include>
				</style>
			</head>
			<body>
				<h2>SBG PoC test-set</h2>
				<p>Test gaat in op correct matchen van DBC-peildatums en
					ROM-metingen.</p>
				<p>verklaring van de celkleuren:</p>
				<table class="meting">
					<tr class="meting">
						<td class="voor_kandidaat_optimaal_false_false">geen voormeting</td>
						<td class="na_kandidaat_optimaal_false_false">geen nameting</td>
					</tr>
					<tr>
						<td class="voor">voormeting</td>
						<td class="na">nameting</td>
					</tr>
					<tr>
						<td class="voor kandidaat">kandidaat voormeting</td>
						<td class="na kandidaat">kandidaat nameting</td>
					</tr>
					<tr>
						<td class="voor optimaal">optimale voormeting</td>
						<td class="na optimaal">optimale nameting</td>
					</tr>
				</table>
				<p>(* in de ID betekent: gewijzigd tov aangeleverde data)</p>
				<p>
					run <xsl:value-of select="substring(//@timestamp, 0, 17)" /> sbg-synq versie 0.8
					
				</p>

				<xsl:apply-templates select="/result/patient/dbc" />
			</body>
		</html>
	</xsl:template>

	<xsl:template match="patient/dbc">
		<div id="content">
			<table class="client">
				<tr>
					<td class="client">
						<xsl:value-of select="../@koppelnummer" />
					</td>
					<td></td>
					<td></td>
					<td colspan="2">
						<table class="dbc-datums">
							<tr>
								<td colspan="2" class="dbc-id">
									<xsl:value-of select="concat( 'DBC ', ./@DBCTrajectnummer)" />
								</td>
							</tr>
							<tr>
								<td>DBC startdatum</td>
								<td>DBC einddatum</td>
							</tr>
							<tr>
								<td class="dbc-datum">
									<xsl:value-of select="./@startdatumDBC" />
								</td>
								<td class="dbc-datum">
									<xsl:value-of select="./@einddatumDBC" />
								</td>
							</tr>
							<tr>
								<td>eerste sessiedatum</td>
								<td>laatste sessiedatum</td>
							</tr>
							<tr>
								<td class="dbc-datum">
									<xsl:value-of select="./@datumEersteSessie" />
								</td>
								<td class="dbc-datum">
									<xsl:value-of select="./@datumLaatsteSessie" />
								</td>
							</tr>
						</table>				
					</td>
				</tr>
				<tr>
					<td></td>
					<td></td>
					<td></td>
					<td>peildatum voor</td>
					<td>peildatum na</td>
				</tr>
				<tr>
					<td></td>
					<td></td>
					<td></td>
					<td><xsl:value-of select="./peildatums/datum[@type='1']"/></td>
					<td><xsl:value-of select="./peildatums/datum[@type='2']"/></td>
				</tr>
				<xsl:apply-templates select="metingen/Meting"/>
			</table>
		</div>
	</xsl:template>


	<xsl:template match="Meting">
			<tr class="meting">
			<td class="meting-id">
				<xsl:value-of select="./@sbgm:meting-id" />
			</td>
			<td>
				<xsl:value-of select="./@gebruiktMeetinstrument" />
			</td>
			<td>
				<xsl:value-of select="./@datum" />
			</td>
			<xsl:choose>
				<xsl:when test="./@typemeting = 1">
					<td class="{concat( 'voor ', ./@test-soort )}">
						<xsl:value-of select="./@afstand" />
					</td>
					<td></td>
				</xsl:when>
				<xsl:when test="./@typemeting = 2">
					<td></td>
					<td class="{concat( 'na ', ./@test-soort )}">
						<xsl:value-of select="./@afstand" />
					</td>
				</xsl:when>
				<xsl:otherwise>
					<td></td>
					<td></td>
				</xsl:otherwise>
			</xsl:choose>
		</tr>
	</xsl:template>
</xsl:stylesheet>