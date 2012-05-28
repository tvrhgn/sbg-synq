<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	name="run-unit-tests" version="1.0">

	<p:option name="report_dir" select="'../../sbg-synq-out'" />
	<p:input port="source">
		<p:empty />
	</p:input>


	<p:output port="result" sequence="true">
		<p:pipe step="store-checklist" port="result" />
	</p:output>

<!--  <p:document href="../sbg-synq-test/test-koppelproces.xml" />
			<p:document href="../sbg-synq-test/test-zorgaanbieder.xml" />
			<p:document href="../sbg-synq-test/test-epd-meting.xml" />
			 -->

	<p:wrap-sequence name="test-docs" wrapper="ctx">
		<p:input port="source" sequence="true">
			<p:document href="../sbg-synq-test/test-koppelproces.xml" />
			<p:document href="../sbg-synq-test/test-zorgaanbieder.xml" />
			<p:document href="../sbg-synq-test/test-epd-meting.xml" />
			<p:document href="../sbg-synq-test/unit-tests-instrument.xml" />
		</p:input>
	</p:wrap-sequence>

	<p:for-each name="tests"> 
		<p:iteration-source select="//tests">
			<p:pipe step="test-docs" port="result" />
		</p:iteration-source>
		<p:output port="result">
			<p:pipe step="run-tests" port="result" />
		</p:output>

		<p:xquery name="run-tests">
			<p:input port="source">
				<p:pipe step="tests" port="current" />
			</p:input>
			<p:input port="query">
				<p:data href="../sbg-synq-test/run-unit-tests.xq" />
			</p:input>
			<p:input port="parameters">
				<p:empty />
			</p:input>
		</p:xquery>
	</p:for-each>

<!--  meng andere tests in -->
	<p:wrap-sequence name="test-result" wrapper="doc">
		<p:input port="source">
			<p:pipe step="tests" port="result" />
		</p:input>
	</p:wrap-sequence>

	<p:store name="store-test-result">
		<p:input port="source">
			<p:pipe step="test-result" port="result" />
		</p:input>
		<p:with-option name="href"
			select="concat( $report_dir, '/run-unit-group.xml')" />
	</p:store>


	<p:xquery name="test-html">
		<p:input port="source">
			<p:pipe step="test-result" port="result" />
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq-test/html-unit-test.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>


	<p:store name="store-checklist" method="html" version="4.0">
		<p:with-option name="href"
			select="concat( $report_dir, '/run-unit-test.html')" />
	</p:store>

</p:declare-step>
 