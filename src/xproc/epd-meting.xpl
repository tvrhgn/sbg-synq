<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://sbg-synq.nl/xproc"
	xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1" name="verwerk-meting"
	version="1.0">

	<p:documentation>
		promoveer patient en sbgm:Meting
	</p:documentation>

	<p:option name="stage.dir" select="'../../sbg-synq-out/stage'" />

	<p:input port="zorgdomeinen">
		<p:document href="../../examples/sbg-zorgdomeinen.xml" />
	</p:input>
	
	<p:input port="patient-doc">
		<p:document href="../../sbg-synq-out/stage/patient-in-doc.xml" />
	</p:input>
	
	<p:input port="meting-doc">
		<p:document href="../../sbg-synq-out/stage/sbgm-metingen.xml" />
	</p:input>
	
	
	<p:output port="result">
		<!-- <p:pipe step="store-selectie" port="result" />  -->
		<p:pipe step="sbg-patient-meting" port="result" />
	</p:output>


	<p:wrap-sequence name="bron-bestanden" wrapper="doc">
		<p:input port="source">
			<p:pipe step="verwerk-meting" port="patient-doc" />
			<p:pipe step="verwerk-meting" port="meting-doc" />
			<p:pipe step="verwerk-meting" port="zorgdomeinen" />
		</p:input>
	</p:wrap-sequence>
	
	<p:xquery name="epd-meting">
		<p:input port="source">
			<p:pipe step="bron-bestanden" port="result"/>
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/epd-meting.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>


	<p:wrap-sequence name="bron-sbg-patient-meting" wrapper="doc">
		<p:input port="source">
			<p:pipe step="epd-meting" port="result" />
			<p:pipe step="verwerk-meting" port="zorgdomeinen" />
		</p:input>
	</p:wrap-sequence>

	<p:xquery name="sbg-patient-meting">
		<p:input port="source">
			<p:pipe step="bron-sbg-patient-meting" port="result" />
		</p:input>

		<p:input port="query">
			<p:data href="../sbg-synq/sbg-epd-meting.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
	<p:store name="store-selectie">
		<p:with-option name="href" select="concat( $stage.dir,'/epd-meting.xml')" />
		<p:input port="source" >
		<p:pipe step="epd-meting" port="result" />		
			
		</p:input>
	</p:store>
	
 
	<p:store name="store-sbg-epd">
		<p:with-option name="href" select="concat( $stage.dir,'/sbg-epd-meting.xml')" />
		<p:input port="source" >
		<p:pipe step="sbg-patient-meting" port="result" />		
			
		</p:input>
	</p:store>
	<!--	 -->
	 
	<!--  todo: store proces-info: sbg-status -->

</p:declare-step>
