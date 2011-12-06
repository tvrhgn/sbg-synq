<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xi="http://www.w3.org/2001/XInclude"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html"></xsl:output>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="concat( 'sbg-synq unit test', 0.9 ) " />
				</title>
				<link rel="stylesheet" type="text/css" href="sbg-testdata.css" />
							</head>
			<body>
				<xsl:apply-templates select="/result/setup" />
				<xsl:apply-templates select="/result/group" />
			</body>
		</html>

	</xsl:template>

	<xsl:template match="setup">
		<div class="result-setup">
			<h2>globale zorgdomeinen</h2>
			<xsl:apply-templates select=".//zorgdomein" />
			<h2>globale instrumenten</h2>
			<xsl:apply-templates select="./sbg-instrumenten/instrument" />
		</div>
	</xsl:template>

	<xsl:template match="group">
		<h2>
			<xsl:value-of select="./functie" />
		</h2>
		<p>
			<xsl:value-of select="./beschrijving" />
		</p>
		<div class="result-group">
			<xsl:apply-templates select="test" />
		</div>
	</xsl:template>

	<xsl:template match="test">
		<xsl:variable name="result">
			<xsl:choose>
				<xsl:when test="@pass='true'">
					pass
				</xsl:when>
				<xsl:otherwise>
					fail
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<div class="{concat('unit-test ',  normalize-space($result))}">
			<div class="test-code">
				<xsl:value-of select="./@code" />
			</div>
			<div class="test-name">
				<xsl:value-of select="./@name" />
			</div>
			<div class="test-setup">
				<xsl:apply-templates select="./setup/*" />
			</div>
			<!-- -->
			<xsl:choose>
				<xsl:when test="./actual/*">
					<div class="actual">
						<xsl:call-template name="html-div">
							<xsl:with-param name="node" select="./actual/*" />
						</xsl:call-template>
					</div>
				</xsl:when>
				<xsl:when test="./actual">
					<div class="actual"> - n/a -</div>
				</xsl:when>
			</xsl:choose>

			<div class="expected">
				<xsl:call-template name="html-div">
					<xsl:with-param name="node" select="./expected/*" />
				</xsl:call-template>
			</div>

		</div>
	</xsl:template>



	<xsl:template match="zorgdomein">
		<xsl:call-template name="html-div-code-naam" />
		<div class="koppel-dbc">
			<xsl:call-template name="html-div-att">
				<xsl:with-param name="nodes" select="./koppel-dbc/@*" />
			</xsl:call-template>
		</div>
		<!-- -->
	</xsl:template>

	<xsl:template match="instrument">
		<xsl:call-template name="html-div-code-naam" />
		<xsl:call-template name="html-div-att">
			<xsl:with-param name="nodes" select="./schaal/*" />
		</xsl:call-template>
		<xsl:call-template name="html-div-att">
			<xsl:with-param name="nodes" select="./items/*" />
		</xsl:call-template>
		<xsl:call-template name="html-div-att">
			<xsl:with-param name="nodes" select="./berekening/*" />
		</xsl:call-template>
		<!-- -->
	</xsl:template>


	<xsl:template match="setup/dbc">
		<xsl:call-template name="html-div" />
	</xsl:template>


	<xsl:template match="setup/Meting">
		<xsl:call-template name="html-div-col" />
	</xsl:template>
	
	<xsl:template match="Patient">
		<xsl:call-template name="html-div-col" />
	</xsl:template>
	
	<xsl:template match="batch-gegevens">
		<xsl:call-template name="html-div-col" />
	</xsl:template>

	<xsl:template match="value">
		<xsl:value-of select="./text()" />
	</xsl:template>

	<xsl:template name="html-div-col">
		<xsl:param name="node" select="." />
		<xsl:variable name="atts" select="$node/@*" />
		<xsl:variable name="elt-name" select="local-name($node)" />
		<xsl:variable name="nr-prev"
			select="count($node/preceding-sibling::*[local-name() = $elt-name])" />

<!-- 
		<div class="{concat('div-col ', $nr-prev, ' ', $elt-name)}">
		
		</div>
	 -->	
			<xsl:if test="$nr-prev = 0">
				<div class="{concat('div-col-caption ', $elt-name)}"><xsl:value-of select="$elt-name"/></div>
				<div class="{concat('div-col-header ', $elt-name)}">
					<xsl:for-each select="$atts">
						<div class="{concat('div-col-key ', local-name())}">
							<xsl:value-of select="local-name()" />
						</div>
					</xsl:for-each>
				</div>
			</xsl:if>
			<div class="{concat('div-col-row ', local-name())}">
				<xsl:for-each select="$atts">
					<div class="{concat('div-col-value ', local-name())}">
						<xsl:value-of select="." />
					</div>
				</xsl:for-each>
			</div>
		
	</xsl:template>


	<xsl:template name="html-div-code-naam">
		<xsl:param name="node" select="." />
		<xsl:variable name="naam">
			<xsl:value-of select="string(./naam)" />
		</xsl:variable>
		<div class="{local-name($node)}">
			<xsl:value-of select="concat($node/@code, ' ', $naam)" />
		</div>
	</xsl:template>

	<xsl:template name="html-div-att">
		<xsl:param name="nodes" select="./@*" />
		<xsl:if test="count($nodes) > 0">
			<table>
				<xsl:for-each select="$nodes">
					<xsl:call-template name="hmtl-tr" />
				</xsl:for-each>
			</table>
		</xsl:if>
	</xsl:template>


	<xsl:template name="html-div-elt">
		<xsl:param name="node" select="." />
		<xsl:if test="$node/*">
			<table class="{local-name($node)}">
				<xsl:for-each select="$node/*">
					<xsl:call-template name="hmtl-tr" />
				</xsl:for-each>
			</table>
		</xsl:if>
	</xsl:template>

	<xsl:template name="html-div">
		<xsl:param name="node" select="." />
		<xsl:if test="$node">
			<div class="{local-name($node)}">
				<p class="{concat( 'object-header ', local-name($node))}">
					<xsl:value-of select="local-name($node)" />
				</p>
				<xsl:call-template name="html-div-att">
					<xsl:with-param name="nodes" select="$node/@*" />
				</xsl:call-template>

				<xsl:call-template name="html-div-elt">
					<xsl:with-param name="node" select="$node" />
				</xsl:call-template>
				<xsl:value-of select="$node/text()" />
			</div>
		</xsl:if>
	</xsl:template>

	<xsl:template name="hmtl-tr">
		<xsl:param name="node" select="." />
		<tr>
			<td class="{local-name($node)}">
				<xsl:value-of select="local-name($node)" />
			</td>
			<td>
				<xsl:value-of select="string($node)" />
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="*|@*">
		<xsl:apply-templates />
	</xsl:template>

	<!-- -->
</xsl:stylesheet>