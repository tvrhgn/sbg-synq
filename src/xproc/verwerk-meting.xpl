<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://sbg-synq.nl/xproc"
	xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1" name="verwerk-meting"
	version="1.0">

	<p:documentation>
		Neem het genormaliseerde bestand en selecteer de juiste dbcs
	</p:documentation>

	<p:option name="stage.dir" select="'../../sbg-synq-out/stage'" />

	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>
	
	<p:input port="instrumenten-lib">
		<p:document href="../../examples/sbg-instrumenten.xml" />
	</p:input>
	
	<p:input port="meting-doc">
		<p:document href="../../sbg-synq-out/stage/patient-meting.xml" />
	</p:input>
	
	
	<p:output port="result">
		<p:pipe step="store-selectie" port="result" />
	</p:output>


	<p:wrap-sequence name="bron-bestanden" wrapper="doc">
		<p:input port="source">
			<p:pipe step="verwerk-meting" port="meting-doc" />
			<p:pipe step="verwerk-meting" port="instrumenten-lib" />
		</p:input>
	</p:wrap-sequence>
	
	<p:xquery name="metingen">
		<p:input port="source">
			<p:pipe step="bron-bestanden" port="result"/>
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/verwerk-meting.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>


		
	<p:store name="store-selectie">
		<p:with-option name="href" select="concat( $stage.dir,'/sbgm-metingen.xml')" />
		<p:input port="source">
			<p:pipe step="metingen" port="result" />
		</p:input>
	</p:store>
	

</p:declare-step>
