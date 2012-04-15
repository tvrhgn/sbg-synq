<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:px="http://sbg-synq.nl/xproc"
	xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1" name="run-stage"
	version="1.0">

	<p:documentation>
		laad de bron-bestanden en normaliseer het formaat voor
		sbg-synq
		- attributen ipv elementen
		- groepering op zorgtraject voor
		behandelaaren nevendiagnose
		op meting voor item op koppelnummer voor
		meting
		- opbouwen meting-doc inclusief items
		- opbouwen patient-doc inclusief metingen en zorgtraject
		
		NB in dit gedeelte worden de sbg-synq modules niet gebruikt; 
		het dient alleen om de data klaar te zetten in de default ns
	</p:documentation>

	<p:option name="stage.dir" select="'../../sbg-synq-out/stage'" />


	<p:input port="meting-doc">
		<p:document href="../../examples/PoC/PoC-data/Brondata_sbg-meting.xml" />
	</p:input>
	<p:input port="behandelaar-doc">
		<p:document href="../../examples/PoC/PoC-data/Brondata_Behandelaar.xml" />
	</p:input>
	<p:input port="nevendiagnose-doc">
		<p:document
			href="../../examples/PoC/PoC-data/Brondata_NevendiagnoseCode.xml" />
	</p:input>
	<p:input port="epd-doc">
		<p:document href="../../examples/PoC/PoC-data/Brondata_sbg-epd.xml" />
	</p:input>
	<p:input port="item-doc">
		<p:document href="../../examples/PoC/PoC-data/Brondata_sbg-item.xml" />
	</p:input>



	<p:output port="result">
		<p:pipe step="maak-patient" port="result" />
	</p:output>


	<p:declare-step type="px:elt-row-att" name="elt-row-att">
		<p:input port="source">
			<p:empty />
		</p:input>
		<p:output port="result">
			<p:pipe step="run-elt-row-att" port="result" />
		</p:output>

		<p:option name="elt" select="'elt-row'" />

		<p:xquery name="run-elt-row-att">
			<p:input port="query">
				<p:data href="../sbg-synq/stage/row-elt-atts.xq" />
			</p:input>
			<p:with-param name="row-elt" select="$elt" />
		</p:xquery>
	</p:declare-step>

	<px:elt-row-att name="patient-atts" elt="patient">
		<p:input port="source">
			<p:pipe step="run-stage" port="epd-doc" />
		</p:input>
	</px:elt-row-att>
	<px:elt-row-att name="meting-atts" elt="meting">
		<p:input port="source">
			<p:pipe step="run-stage" port="meting-doc" />
		</p:input>
	</px:elt-row-att>
	<px:elt-row-att name="item-atts" elt="item">
		<p:input port="source">
			<p:pipe step="run-stage" port="item-doc" />
		</p:input>
	</px:elt-row-att>
	<px:elt-row-att name="behandelaar-atts" elt="behandelaar">
		<p:input port="source">
			<p:pipe step="run-stage" port="behandelaar-doc" />
		</p:input>
	</px:elt-row-att>
	<px:elt-row-att name="nevendiagnose-atts" elt="nevendiagnose">
		<p:input port="source">
			<p:pipe step="run-stage" port="nevendiagnose-doc" />
		</p:input>
	</px:elt-row-att>


	<p:xquery name="groepeer-behandelaar">
		<p:input port="source">
			<p:pipe step="behandelaar-atts" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/stage/group-zorgtraject-behandelaar.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>


	<p:xquery name="groepeer-nevendiagnose">
		<p:input port="source">
			<p:pipe step="nevendiagnose-atts" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/stage/group-zorgtraject-nevendiagnose.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>

	<p:xquery name="groepeer-item">
		<p:input port="source">
			<p:pipe step="item-atts" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/stage/group-meting-item.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>

	<p:wrap-sequence name="meting-bestanden" wrapper="doc">
		<p:input port="source">
			<p:pipe step="meting-atts" port="result" />
			<p:pipe step="groepeer-item" port="result" />
		</p:input>
	</p:wrap-sequence>

	<p:xquery name="maak-meting">
		<p:input port="source">
			<p:pipe step="meting-bestanden" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/stage/build-meting.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>

	<p:xquery name="patient-meting">
		<p:input port="source">
			<p:pipe step="maak-meting" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/stage/group-patient-meting.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>


	<p:wrap-sequence name="patient-bestanden" wrapper="doc">
		<p:input port="source">
			<p:pipe step="patient-atts" port="result" />
			<p:pipe step="groepeer-behandelaar" port="result" />
			<p:pipe step="groepeer-nevendiagnose" port="result" />
			<p:pipe step="patient-meting" port="result" />
		</p:input>
	</p:wrap-sequence>

	<p:xquery name="maak-patient">
		<p:input port="source">
			<p:pipe step="patient-bestanden" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq/stage/build-patient.xq" />
		</p:input>
		<p:with-param name="-doc-" select="x-doc-x" />
	</p:xquery>
	
	
	<p:store name="store-patient-meting">
		<p:with-option name="href" select="concat( $stage.dir,'/metingen.xml')" />
		<p:input port="source">
			<p:pipe step="maak-meting" port="result" />
		</p:input>
	</p:store>


</p:declare-step>
