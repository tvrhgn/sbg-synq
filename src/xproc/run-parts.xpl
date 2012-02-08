<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="sbg-batch" version="1.0">

	<p:documentation>
	doe een run zoals in run-batch, maar roep de onderdelen aan vanuit xproc en sla de tussenresultaten apart op
	</p:documentation>

	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<p:output port="result">
		<p:pipe step="zorgaanbieder" port="result" />
	</p:output>

	<p:variable name="timestamp" select="current-dateTime()" />

	<!--  gebruik het configuratiedocument om de bestandsnaam van de output op te bouwen -->
	<p:variable name="batch-year" select="substring(//batch[1]/einddatumAangeleverdePeriode, 1, 4 )">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	<p:variable name="batch-month" select="substring(//batch[1]/einddatumAangeleverdePeriode, 6, 2)">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>

	<p:variable name="za-naam" select="upper-case(replace( /zorgaanbieder/naam, ' ', '' ))">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	
	<p:variable name="tmp.doc" select="concat( //target[1]/tmp, '/', 'bmstore.xml')">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	
	<p:variable name="result.doc"
		select="concat( //target[1]/ftp, '/', //@code[1], '_', //target[1]/@type, '_', $za-naam, '_SBG_', $batch-year, '_', $batch-month, '_', //target[1]/@volgnummer, '.xml')">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	
	<p:add-attribute name="config-add-ts" match="//batch[1]" attribute-name="datumCreatie">
		<p:with-option select="$timestamp" name="attribute-value"/>
		<p:input port="source">
			<p:pipe step="sbg-batch" port="config" />
		</p:input>
	</p:add-attribute>

	<p:xquery name="zorgaanbieder">
		<p:input port="source">
			<p:pipe step="config-add-ts" port="result" />
		</p:input>
	
		<p:input port="query">
			<p:inline>
				<c:query>
			import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';
			import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/sbg-bmimport.xquery';
			let $za := sbgza:build-zorgaanbieder( ./zorgaanbieder )
			return sbgbm:batch-gegevens($za)
			</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	

	<p:xquery name="metingen">
		<p:input port="source">
			<p:pipe step="config-add-ts" port="result" />
		</p:input>
	
		<p:input port="query">
			<p:inline>
				<c:query>
			import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';
			import module namespace sbgi="http://sbg-synq.nl/sbg-instrument" at '../sbg-synq/sbg-instrument.xquery';
			import module namespace sbgm="http://sbg-synq.nl/sbg-metingen" at '../sbg-synq/sbg-metingen.xquery';
			
			let $za := sbgza:build-zorgaanbieder( ./zorgaanbieder ),
				$instrumenten := sbgi:laad-instrumenten( $za/instrumenten/sbg-instrumenten )
			return element { 'result' } { (), $za, 
				element { 'metingen' } { (), sbgm:sbg-metingen($za/rom/*, $za/rom-items/*, $instrumenten) } 
				}
			</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
	 
	<p:xquery name="patient-meting">
		<p:input port="source">
			<p:pipe step="metingen" port="result" />
		</p:input>
	
		<p:input port="query">
			<p:inline>
				<c:query>
			import module namespace sbgem="http://sbg-synq.nl/epd-meting" at '../sbg-synq/epd-meting.xquery';		
			let $za := //zorgaanbieder
			return element { 'result' } { (), $za, 
				element { 'patient-meting' } { (), sbgem:patient-meting-epd( $za/epd/*, .//Meting, $za/sbg-zorgdomeinen/* ) }
				}
			</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
<!-- 
	<p:xquery name="sbg-patient-meting">
		<p:input port="source">
			<p:pipe step="patient-meting" port="result" />
		</p:input>
	
		<p:input port="query">
			<p:inline>
				<c:query>
			import module namespace sbge="http://sbg-synq.nl/sbg-epd" at '../sbg-synq/sbg-epd.xquery';		
			let $za := //zorgaanbieder
			return element { 'result' } { (), $za, 
				element { 'sbg-patient-meting' } { (), sbge:patient-dbc-meting( //patient-meting/*, $za/sbg-zorgdomeinen/* ) }
				}
			</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	 -->
	 
	<p:store name="store-zorgaanbieder">
		<p:with-option name="href" select="'../../sbg-synq-out/zorgaanbieder.xml'" />
		<p:input port="source">
			<p:pipe step="zorgaanbieder" port="result" />
		</p:input>
	</p:store>


	<p:store name="store-metingen">
		<p:with-option name="href" select="'../../sbg-synq-out/metingen.xml'" />
		<p:input port="source" select="//metingen">
			<p:pipe step="metingen" port="result" />
		</p:input>
	</p:store>

	<p:store name="store-patient-meting">
		<p:with-option name="href" select="'../../sbg-synq-out/patient-meting.xml'" />
		<p:input port="source" select="//patient-meting">
			<p:pipe step="patient-meting" port="result" />
		</p:input>
	</p:store>
<!-- 
	<p:store name="store-sbg-patient-meting">
		<p:with-option name="href" select="'../../sbg-synq-out/sbg-patient-meting.xml'" />
		<p:input port="source" select="//sbg-patient-meting">
			<p:pipe step="sbg-patient-meting" port="result" />
		</p:input>
	</p:store>
 -->
</p:declare-step>
