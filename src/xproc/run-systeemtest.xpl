<p:declare-step version="1.0" xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/ns/xproc xproc.xsd" xmlns:iso="http://purl.oclc.org/dsdl/schematron"
	xmlns:sbg="http://sbggz.nl/schema/import/5.0.1" xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
	name="sbg-systeemtest">

  <p:option name="report_dir" select="'../../sbg-synq-out'"/>
  <p:option name="checklist_html" select="'checklist.html'"/>

	<p:input port="source">
		<p:document href="../../sbg-synq-out/bmstore.xml"/>
	</p:input>

	<p:input port="sbg-synq-status">
		<p:document href="../sbg-synq-test/sbg-synq-status.xml" />
	</p:input>

	<p:input port="sbg-testdoc">
		<p:document href="../sbg-synq-test/sbg-systeemtest.xml" />
	</p:input>

	<p:input port="schema">
		<p:document href="../schema/sbg-bmimport.schematron" />
	</p:input>

	<p:input port="sbg-codelijst">
		<p:document href="../schema/sbg-codelijst.xml" />
	</p:input>



	<p:output port="result" sequence="true">
		<p:pipe step="store-checklist" port="result" />
	</p:output>

	<p:variable name="schema-doc" select="'../schema/sbg-bmimport.schematron'" />

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

	<p:xquery name="schema-status">
		<p:input port="source">
			<p:pipe step="schematron" port="report" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq-test/schema-status.xq" />
		</p:input>
		<p:with-param name="schema-uri" select="$schema-doc" />
	</p:xquery>


	<!-- plaats de benodigde documenten in 1 context om ze gemakkelijk toegankelijk 
		te maken in xquery -->
	<p:wrap-sequence name="sbg-synq-test-source" wrapper="context">
		<p:input port="source">
			<p:pipe port="source" step="sbg-systeemtest" />
			<p:pipe port="sbg-codelijst" step="sbg-systeemtest" />
		</p:input>
	</p:wrap-sequence>
	<p:xquery name="sbg-synq-test">
		<p:input port="source">
			<p:pipe port="result" step="sbg-synq-test-source" />
		</p:input>
		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace sbgtest =
					'http://sbg-synq.nl/sbg-test' at
					'../sbg-synq-test/sbg-systeemtest.xquery';
					declare namespace sbg =
					"http://sbggz.nl/schema/import/5.0.1";
					
					sbgtest:run-tests(//sbg:BenchmarkImport, //sbg-codelijsten)
					
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	
	<p:wrap-sequence name="collect-test-result" wrapper="test-results">
		<p:input port="source" select="//result|//test-info" sequence="true">
			<p:pipe port="result" step="schema-status" />
			<p:pipe port="result" step="sbg-synq-test" />
			<p:pipe port="sbg-synq-status" step="sbg-systeemtest" />
		</p:input>
	</p:wrap-sequence>

<!-- plaats de benodigde documenten in 1 context om ze gemakkelijk toegankelijk 
		te maken in xquery -->
	<p:wrap-sequence name="checklist-source" wrapper="xquery-context">
		<p:input port="source">
			<p:pipe port="sbg-testdoc" step="sbg-systeemtest" />
			<p:pipe port="result" step="collect-test-result" />
		</p:input>
	</p:wrap-sequence>
	<p:xquery name="checklist">
		<p:input port="source">
			<p:pipe step="checklist-source" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq-test/checklist-systeemtest.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

<!--				<p:inline>
			<link rel="stylesheet" type="text/css" href="sbg-testdata.css"></link> 

			</p:inline>
-->
	
	<p:insert position="last-child" match="//head" name="html-head">
		<p:input port="insertion">
		        <p:pipe step="read-css" port="result" />
		        <p:pipe step="read-jquery" port="result" />
		        <p:pipe step="read-js" port="result" />
		</p:input>
	</p:insert>
	<p:insert position="last-child" match="//*[@id='testinfo']" name="welcome-msg">
		<p:input port="insertion">
			<p:inline>
				<div class='test-info init-msg'><h2>controle benchmark-bestand</h2>gebruik gekleurde velden als knoppen. (F5 = reset)</div>				
			</p:inline>
		</p:input>
	</p:insert>
	<p:store name="store-checklist" method="html" version="4.0">
	  <p:with-option name="href" select="concat( $report_dir, '/', $checklist_html)"/>
	  </p:store>

	  <p:wrap wrapper="style" match="c:data/text()" name="copy-static.1">
	    <p:input port="source">
	      <p:data href="../site/sbg-testdata.css" content-type="text/css"/>
	    </p:input>
	  </p:wrap>
	  <p:unwrap name="read-css" match="c:data"/>

	  <p:wrap wrapper="script" match="c:data/text()" name="copy-static.2">
	    <p:input port="source">
	      <p:data href="../site/jquery-1.6.2.min.js" content-type="text/javascript"/>
	    </p:input>
	  </p:wrap>
	  <p:unwrap name="read-jquery" match="c:data"/>

	  <p:wrap wrapper="script" match="c:data/text()" name="copy-static">
	    <p:input port="source">
	      <p:data href="../site/checklist-systeemtest.js" content-type="text/javascript"/>
	    </p:input>
	  </p:wrap>
	  <p:unwrap name="read-js" match="c:data"/>

</p:declare-step>
