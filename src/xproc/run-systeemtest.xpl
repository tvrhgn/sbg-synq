<p:declare-step version="1.0" xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/ns/xproc xproc.xsd" xmlns:iso="http://purl.oclc.org/dsdl/schematron"
	xmlns:sbg="http://sbggz.nl/schema/import/5.0.1" xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
	name="sbg-systeemtest">


	<p:option name="report_dir" select="'../../sbg-synq-out'" />
	<p:option name="checklist_html" select="'checklist.html'" />

	<!-- het benchmark-bestand voor analyse -->
	<p:input port="source">
		<p:document href="../../sbg-synq-out/bmstore.xml" />
	</p:input>

	<!-- een bestand met de sbg codelijsten -->
	<p:input port="sbg-codelijst">
		<p:document href="../schema/sbg-codelijst.xml" />
	</p:input>

	<!-- een xml-versie van SBG XSD 20110204.xls -->
	<p:input port="sbg-testdoc">
		<p:document href="../sbg-synq-test/sbg-systeemtest.xml" />
	</p:input>

	<!-- sbg-synq status gerelateerd aan test -->
	<p:input port="sbg-synq-status">
		<p:document href="../sbg-synq-test/sbg-synq-status.xml" />
	</p:input>

	<!-- schematron-implementatie van een gedeelte van de tests uit sbg-testdoc -->
	<p:input port="schema">
		<p:document href="../schema/sbg-bmimport.schematron" />
	</p:input>

	<!-- xsd schema van sbg -->
	<p:input port="sbg-schema">
		<!-- <p:document href="/home/thijs/tmp/SBG XSD 20110204.xsd" /> -->
		<p:document href="../schema/SBGXSD20110204.xsd" />
	</p:input>

	<p:output port="result" sequence="true">
		<p:pipe step="store-test-result" port="result" />

	</p:output>

	<p:output port="ignore">
		<p:pipe step="schematron" port="result" />
	</p:output>

	<p:variable name="schema-doc" select="'../schema/sbg-bmimport.schematron'" />


	<!-- xsd schema-controle met standaard xerces past niet altijd in geheugen 
		:-( <p:pipe step="sbg-validatie" port="report" /> <p:try name="sbg-validatie"> 
		<p:group> <p:output port="result"> <p:pipe step="sbg-schema" port="result" 
		/> </p:output> <p:output port="report" sequence="true"> <p:empty /> </p:output> 
		<p:validate-with-xml-schema name="sbg-schema"> <p:input port="source"> <p:pipe 
		step="sbg-systeemtest" port="source" /> </p:input> <p:input port="schema"> 
		<p:pipe step="sbg-systeemtest" port="sbg-schema" /> </p:input> </p:validate-with-xml-schema> 
		</p:group> <p:catch name="catch"> <p:output port="result"> <p:pipe step="sbg-systeemtest" 
		port="source" /> </p:output> <p:output port="report"> <p:pipe step="id" port="result" 
		/> </p:output> <p:identity name="id"> <p:input port="source"> <p:pipe step="catch" 
		port="error" /> </p:input> </p:identity> </p:catch> </p:try> -->


	<p:validate-with-schematron assert-valid="false"
		name="schematron">
		<p:input port="source">
			<p:pipe step="sbg-systeemtest" port="source" />
		</p:input>
		<p:input port="schema">
			<p:pipe step="sbg-systeemtest" port="schema" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:validate-with-schematron>


	<p:wrap-sequence name="schema-status-source" wrapper="context">
		<p:input port="source">
			<p:pipe step="sbg-systeemtest" port="sbg-testdoc" />  <!-- het bron document -->
			<p:pipe step="sbg-systeemtest" port="schema" />   <!-- 1 iso:schema -->
			<p:pipe step="schematron" port="report" />       <!-- 1 svrl:schema-output -->
		</p:input>
	</p:wrap-sequence>

	<p:xquery name="schema-status">
		<p:input port="source">
			<p:pipe step="schema-status-source" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq-test/schema-status.xq" />
		</p:input>
		<p:with-param name="schema-uri" select="$schema-doc" />
	</p:xquery>

	<p:store name="store-test-result">
		<p:with-option name="href"
			select="concat( $report_dir, '/test-result-schematron.xml')" />
	</p:store>

	<p:wrap-sequence name="html-status-source" wrapper="context">
		<p:input port="source">
			<p:pipe step="sbg-systeemtest" port="sbg-testdoc" />  <!-- het bron document -->
			<p:pipe port="result" step="schema-status" />
		</p:input>
	</p:wrap-sequence>


	<p:xquery name="html-schema-status">
		<p:input port="source">
			<p:pipe port="result" step="html-status-source" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq-test/html-systeem-test.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<p:store name="store-test-html" method="html" version="4.0">
		<p:with-option name="href"
			select="concat( $report_dir, '/schematron-result.html')" />
	</p:store>



	<!-- plaats de benodigde documenten in 1 context om ze gemakkelijk toegankelijk 
		te maken in xquery <p:pipe port="sbg-codelijst" step="sbg-systeemtest" /> 
		<p:wrap-sequence name="sbg-synq-test-source" wrapper="context"> <p:input 
		port="source"> <p:pipe port="source" step="sbg-systeemtest" /> <p:pipe port="sbg-codelijst" 
		step="sbg-systeemtest" /> </p:input> </p:wrap-sequence> -->

	<!-- run extra tests in sbg-systeemtest.xquery ? <p:xquery name="sbg-synq-test"> 
		<p:input port="source"> <p:pipe port="result" step="sbg-synq-test-source" 
		/> </p:input> <p:input port="query"> <p:inline> <c:query> import module namespace 
		sbgtest = 'http://sbg-synq.nl/sbg-test' at '../sbg-synq-test/sbg-systeemtest.xquery'; 
		declare namespace sbg = "http://sbggz.nl/schema/import/5.0.1"; sbgtest:run-tests(//sbg:BenchmarkImport, 
		//sbg-codelijsten) </c:query> </p:inline> </p:input> <p:input port="parameters"> 
		<p:empty /> </p:input> </p:xquery> <p:pipe port="result" step="sbg-synq-test" 
		/> -->

	<!-- verwerk bestand in het ad-hoc testresults formaat <p:wrap-sequence 
		name="collect-test-result" wrapper="test-results"> <p:input port="source" 
		select="//result|//test-info" sequence="true"> <p:pipe port="result" step="schema-status" 
		/> <p:pipe port="sbg-synq-status" step="sbg-systeemtest" /> </p:input> </p:wrap-sequence> -->
	<!-- plaats de benodigde documenten in 1 context om ze gemakkelijk toegankelijk 
		te maken in xquery <p:wrap-sequence name="checklist-source" wrapper="xquery-context"> 
		<p:input port="source"> <p:pipe port="sbg-testdoc" step="sbg-systeemtest" 
		/> <p:pipe port="result" step="collect-test-result" /> </p:input> </p:wrap-sequence> 
		<p:xquery name="checklist"> <p:input port="source"> <p:pipe step="checklist-source" 
		port="result" /> </p:input> <p:input port="query"> <p:data href="../sbg-synq-test/checklist-systeemtest.xq" 
		/> </p:input> <p:input port="parameters"> <p:empty /> </p:input> </p:xquery> -->


	<!-- <p:inline> <link rel="stylesheet" type="text/css" href="sbg-testdata.css"></link> 
		</p:inline> -->

	<!-- doe dit niet in xproc !! <p:insert position="last-child" match="//head" 
		name="html-head"> <p:input port="insertion"> <p:pipe step="read-css" port="result" 
		/> <p:pipe step="read-jquery" port="result" /> <p:pipe step="read-js" port="result" 
		/> </p:input> </p:insert> <p:insert position="last-child" match="//*[@id='testinfo']" 
		name="welcome-msg"> <p:input port="insertion"> <p:inline> <div class='test-info 
		init-msg'> <h2>controle benchmark-bestand</h2> gebruik gekleurde velden als 
		knoppen. (F5 = reset) </div> </p:inline> </p:input> </p:insert> <p:store 
		name="store-checklist" method="html" version="4.0"> <p:with-option name="href" 
		select="concat( $report_dir, '/', $checklist_html)" /> </p:store> <p:wrap 
		wrapper="style" match="c:data/text()" name="copy-static.1"> <p:input port="source"> 
		<p:data href="../site/sbg-testdata.css" content-type="text/css" /> </p:input> 
		</p:wrap> <p:unwrap name="read-css" match="c:data" /> <p:wrap wrapper="script" 
		match="c:data/text()" name="copy-static.2"> <p:input port="source"> <p:data 
		href="../site/jquery-1.6.2.min.js" content-type="text/javascript" /> </p:input> 
		</p:wrap> <p:unwrap name="read-jquery" match="c:data" /> <p:wrap wrapper="script" 
		match="c:data/text()" name="copy-static"> <p:input port="source"> <p:data 
		href="../site/checklist-systeemtest.js" content-type="text/javascript" /> 
		</p:input> </p:wrap> <p:unwrap name="read-js" match="c:data" /> -->


	<!-- <p:store name="store-schematron-output"> <p:input port="source" select="//svrl:schematron-output"> 
		<p:pipe step="schematron" port="report" /> </p:input> <p:with-option name="href" 
		select="concat( $report_dir, '/schematron-svrl.xml')" /> </p:store> -->

</p:declare-step>
