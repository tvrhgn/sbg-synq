<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="maak-sbg-bmimport" version="1.0">

	<p:documentation>
		doe de slectie volgens de instellingen, maak een export-bestand en anonimiseer 
	</p:documentation>

	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<p:input port="source">
		<p:document href="../../sbg-synq-out/stage/sbg-epd-meting.xml" />
	</p:input>


	<p:output port="result" sequence="true">
		<p:pipe step="store-benchmark-bestand" port="result" />
	</p:output>

	<p:variable name="timestamp" select="current-dateTime()" />

	<p:variable name="tmp.dir" select="//target[1]/tmp">
		<p:pipe step="maak-sbg-bmimport" port="config" />
	</p:variable>

	<!-- gebruik het configuratiedocument om bestandsnamen op te bouwen -->
	<p:variable name="batch-year"
		select="substring(//batch[1]/einddatumAangeleverdePeriode, 1, 4 )">
		<p:pipe step="maak-sbg-bmimport" port="config" />
	</p:variable>
	<p:variable name="batch-month"
		select="substring(//batch[1]/einddatumAangeleverdePeriode, 6, 2)">
		<p:pipe step="maak-sbg-bmimport" port="config" />
	</p:variable>

	<p:variable name="za-naam"
		select="upper-case(replace( /zorgaanbieder/naam, ' ', '' ))">
		<p:pipe step="maak-sbg-bmimport" port="config" />
	</p:variable>


	<!-- de twee uitvoer documenten van dit script -->
	<p:variable name="bm-info.doc" select="concat( $tmp.dir, '/sbg-bmimport.xml')" />
	<p:variable name="bm-import.doc"
		select="concat( //target[1]/ftp, '/', //@code[1], '_', //target[1]/@type, '_', $za-naam, '_SBG_', $batch-year, '_', $batch-month, '_', //target[1]/@volgnummer, '.xml')">
		<p:pipe step="maak-sbg-bmimport" port="config" />
	</p:variable>



	<p:wrap-sequence name="wrap-source-bminfo" wrapper="context">
		<p:input port="source">
			<p:pipe step="maak-sbg-bmimport" port="source" />
			<p:pipe step="maak-sbg-bmimport" port="config" />
		</p:input>
	</p:wrap-sequence>
	<p:xquery name="sbg-benchmark-info">
		<p:input port="source">
			<p:pipe step="wrap-source-bminfo" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/maak-sbg-bmimport.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
	<p:viewport name="anonimiseer" match="sbggz:Patient">
		<p:hash name="hash" algorithm="sha" match="@koppelnummer">
			<p:with-option name="value" select="//@koppelnummer" />
			<p:input port="parameters">
				<p:empty />
			</p:input>
		</p:hash>
	</p:viewport>
	<p:store name="store-benchmark-bestand">
		<p:with-option name="href" select="$bm-import.doc" />
		<p:input port="source"
			select="/benchmark-info//*[local-name() eq 'BenchmarkImport']">
			<p:pipe step="anonimiseer" port="result" />
		</p:input>
	</p:store>
	<p:store name="store-benchmark-info">
		<p:with-option name="href" select="$bm-info.doc" />
		<p:input port="source" select="/benchmark-info">
			<p:pipe step="sbg-benchmark-info" port="result" />
		</p:input>
	</p:store>
</p:declare-step>
