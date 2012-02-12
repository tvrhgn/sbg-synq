<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="run-sbg-patient-meting" version="1.0">

	<p:documentation>
	doe een run zoals in run-batch, maar roep de onderdelen aan vanuit xproc en sla de tussenresultaten apart op
	</p:documentation>

	<p:input port="source">
		<p:document href="../../sbg-synq-out/patient-meting.xml" />
	</p:input>
	
	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<p:output port="result">
		<p:pipe step="store-sbg-patient-meting" port="result" />
	</p:output>

	<p:variable name="result.doc"
		select="concat( //target[1]/tmp, '/sbg-patient-meting.xml')">
		<p:pipe step="run-sbg-patient-meting" port="config" />
	</p:variable>
	
	<p:xquery name="zorgaanbieder">
		<p:input port="source">
				<p:pipe step="run-sbg-patient-meting" port="config" />
		</p:input>
	
		<p:input port="query">
			<p:inline>
				<c:query>
			import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';
			import module namespace sbgbm="http://sbg-synq.nl/sbg-benchmark" at '../sbg-synq/sbg-bmimport.xquery';
			let $za := sbgza:build-zorgaanbieder( ./zorgaanbieder )
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
			<p:pipe step="zorgaanbieder" port="result"  />
			<p:pipe step="run-sbg-patient-meting" port="source" />
		</p:input>
	</p:wrap-sequence>
	
		 
	<p:xquery name="sbg-patient-meting">
		<p:input port="source">
			<p:pipe step="wrap-source" port="result" />
		</p:input>
	
		<p:input port="query">
			<p:inline>
				<c:query>
			import module namespace sbgza="http://sbg-synq.nl/zorgaanbieder" at '../sbg-synq/zorgaanbieder.xquery';
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

	<p:store name="store-sbg-patient-meting">
		<p:with-option name="href" select="$result.doc" />
		<p:input port="source" select="//sbg-patient-meting">
			<p:pipe step="sbg-patient-meting" port="result" />
		</p:input>
	</p:store>
 
 
</p:declare-step>
