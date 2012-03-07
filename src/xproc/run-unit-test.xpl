<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	name="run-unit-tests" version="1.0">
	
	<p:option name="report_dir" select="'../../sbg-synq-out'" />
	<p:input port="source">
		<p:document href="../sbg-synq-test/test-koppelproces.xml" />
	</p:input>

	<p:output port="result" sequence="true">
		<p:pipe step="store-checklist" port="result" />
	</p:output>

	<p:xquery name="run-group">
		<p:input port="source">
			<p:pipe step="run-unit-tests" port="source"/>
		</p:input>
		<p:input port="query">
			<p:data href="../sbg-synq-test/run-unit-tests.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	<p:store name="store-test-result">
		<p:with-option name="href"
			select="concat( $report_dir, '/run-unit-group.xml')" />
	</p:store>

 	<p:xquery name="test-html">
		<p:input port="source">
			<p:pipe step="run-group" port="result"/>
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
 