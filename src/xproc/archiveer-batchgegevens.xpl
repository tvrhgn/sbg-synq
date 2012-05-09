<?xml version="1.0"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="archiveer-batchgegevens" version="1.0">

	<p:documentation>
		zet configuratie-bestand om in een logversie,
		voeg die
		in in het archief
		en zet een nieuw configuratie-bestand klaar

	</p:documentation>

	<!-- INPUT poorten -->
	<!-- het configuratie bestand -->
	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<!-- bron om in te voegen in archief-->
	<!-- standaard de  resultaat van de store --> 
	<!-- (de bestandsnaam van het import bestand) -->
	<p:input port="source">
		<p:document href="../../sbg-synq-out/stage/fn-bmimport.xml" />
	</p:input>

	<!-- het huidige archiefbestand -->
	<p:input port="za-archief">
		<p:inline>
			<zorgaanbieder-archief />
		</p:inline>
	</p:input>

	<!-- OUTPUT poorten -->
	<p:output port="config.nieuw">
		<p:pipe step="config.nieuw" port="result" />
	</p:output>

	<p:output port="archief">
		<p:pipe step="zorgaanbieder-archief" port="result" />
	</p:output>

	<!-- STEPS -->
	<!-- voer script volgende-batch.xq uit -->
	<!-- hier wordt de volgende batch ingesteld op eind van de maand volgend 
		op de huidige batch,met een aanleverperiode van 3M -->
	<p:xquery name="config.nieuw">
		<p:input port="source">
			<p:pipe step="archiveer-batchgegevens" port="config" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/volgende-batch.xq" />
		</p:input>
		<p:with-param name="duur" select="'P1M'" />
		<p:with-param name="aanleverperiode" select="'P3M'" />
	</p:xquery>

	<!-- voeg timestamp toe aan /zorgaanbieder -->
	<p:add-attribute name="config.result.1" match="/zorgaanbieder">
		<p:with-option name="attribute-name" select="'timestamp'" />
		<p:with-option name="attribute-value" select="current-dateTime()" />
		<p:input port="source">
			<p:pipe step="archiveer-batchgegevens" port="config" />
		</p:input>
	</p:add-attribute>

	<!-- voeg de inhoud van input poort source toe aan batch -->
	<p:insert name="config.result" match="/zorgaanbieder/batch"
		position="first-child">
		<p:input port="source">
			<p:pipe step="config.result.1" port="result" />
		</p:input>
		<p:input port="insertion">
			<p:pipe step="archiveer-batchgegevens" port="source" />
		</p:input>
	</p:insert>

	<!-- voeg de tot hier opgebouwde log-versie van het configuratie-bestand 
		toe aan bestaande archief -->
	<p:wrap-sequence name="zorgaanbieder-archief" wrapper="zorgaanbieder-archief">
		<p:input port="source" select="//zorgaanbieder">
			<p:pipe step="config.result" port="result" />
			<p:pipe step="archiveer-batchgegevens" port="za-archief" />
		</p:input>
	</p:wrap-sequence>


</p:declare-step>
