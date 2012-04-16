<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="sbg-steps" version="1.0">

	<p:documentation>
		fase II: maak SBG-bestand op basis van de inhoud van
		de uitvoer van
		sbgem:epd-meting
	</p:documentation>

	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<p:input port="source">
		<p:document href="../../sbg-synq-out/stage/epd-meting.xml" />
	</p:input>


	<p:output port="result" sequence="true">
		<p:pipe step="config-add-ts" port="result" />
	</p:output>

	<p:variable name="timestamp" select="current-dateTime()" />

	<p:variable name="tmp.dir" select="//target[1]/tmp">
		<p:pipe step="sbg-steps" port="config" />
	</p:variable>

	<!-- gebruik het configuratiedocument om bestandsnamen op te bouwen -->
	<p:variable name="batch-year"
		select="substring(//batch[1]/einddatumAangeleverdePeriode, 1, 4 )">
		<p:pipe step="sbg-steps" port="config" />
	</p:variable>
	<p:variable name="batch-month"
		select="substring(//batch[1]/einddatumAangeleverdePeriode, 6, 2)">
		<p:pipe step="sbg-steps" port="config" />
	</p:variable>

	<p:variable name="za-naam"
		select="upper-case(replace( /zorgaanbieder/naam, ' ', '' ))">
		<p:pipe step="sbg-steps" port="config" />
	</p:variable>

	<!-- de drie uitvoer documenten van dit script -->
	<p:variable name="sbg-patient.doc"
		select="concat( $tmp.dir, '/sbg-patient-meting.xml')" />
	<p:variable name="bm-info.doc" select="concat( $tmp.dir, '/sbg-bmimport.xml')" />

	<p:variable name="bm-import.doc"
		select="concat( //target[1]/ftp, '/', //@code[1], '_', //target[1]/@type, '_', $za-naam, '_SBG_', $batch-year, '_', $batch-month, '_', //target[1]/@volgnummer, '.xml')">
		<p:pipe step="sbg-steps" port="config" />
	</p:variable>

	<!-- voeg timestamp in voor log en datumCreatie -->
	<p:add-attribute name="config-add-ts" match="//batch[1]"
		attribute-name="datumCreatie">
		<p:with-option select="$timestamp" name="attribute-value" />
		<p:input port="source">
			<p:pipe step="sbg-steps" port="config" />
		</p:input>
	</p:add-attribute>

	<p:xquery name="zorgaanbieder">
		<p:input port="source">
			<p:pipe step="config-add-ts" port="result" />
		</p:input>
		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace
					sbgza="http://sbg-synq.nl/zorgaanbieder" at
					'../sbg-synq/modules/zorgaanbieder.xquery';
					import module namespace
					sbgbm="http://sbg-synq.nl/sbg-benchmark" at
					'../sbg-synq/modules/sbg-bmimport.xquery';

					let $za :=
					sbgza:build-zorgaanbieder( ./zorgaanbieder )
					return $za
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<p:wrap-sequence name="wrap-source" wrapper="context">
		<p:input port="source">
			<p:pipe step="zorgaanbieder" port="result" />
			<p:pipe step="sbg-steps" port="source" />
		</p:input>
	</p:wrap-sequence>
	<p:xquery name="sbg-patient-meting">
		<p:input port="source">
			<p:pipe step="wrap-source" port="result" />
		</p:input>

		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace sbge="http://sbg-synq.nl/sbg-epd"
					at '../sbg-synq/modules/sbg-epd.xquery';
					declare namespace
					sbgza="http://sbg-synq.nl/zorgaanbieder";

					let $za :=
					.//sbgza:zorgaanbieder
					return
					element { 'result' } {
					(), $za,
					element
					{
					'sbg-patient-meting' } {
					(),
					sbge:sbg-patient-meting(
					//patient-doc/*, $za//zorgdomein )
					}
					}
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
	<p:store name="store-sbg-patient-meting">
		<p:with-option name="href" select="$sbg-patient.doc" />
		<p:input port="source" select="//sbg-patient-meting">
			<p:pipe step="sbg-patient-meting" port="result" />
		</p:input>
	</p:store>
	<p:wrap-sequence name="wrap-source-bminfo" wrapper="context">
		<p:input port="source">
			<p:pipe step="zorgaanbieder" port="result" />
			<p:pipe step="sbg-patient-meting" port="result" />
		</p:input>
	</p:wrap-sequence>
	<p:xquery name="sbg-benchmark-info">
		<p:input port="source">
			<p:pipe step="wrap-source-bminfo" port="result" />
		</p:input>
		<p:input port="query">
			<p:inline>
				<c:query> import module namespace
					sbgbm =
					"http://sbg-synq.nl/sbg-benchmark" at
					'../sbg-synq/modules/sbg-bmimport.xquery';
					declare namespace sbggz =
					"http://sbggz.nl/schema/import/5.0.1";
					declare namespace
					sbgza="http://sbg-synq.nl/zorgaanbieder";

					(: NB de logging za is nu ook ingevoegd :)
					let $za :=
					/context/result/sbgza:zorgaanbieder
					return element {
					'benchmark-info' } { (), /context/zorgaanbieder,
					sbgbm:build-sbg-bmimport(
					$za, //sbg-patient-meting//sbggz:Patient )
					}
				</c:query>
			</p:inline>
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
