<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/ns/xproc ../xproc/xproc.xsd" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	version="1.0" name="template">

	<p:input port="source">
		<p:empty/>
	</p:input>


	<p:output port="result">
		<p:pipe step="store" port="result" />
	</p:output>


	<p:xquery name="query">
		<p:input port="source">
		</p:input>
		<p:input port="query">
			<p:data href="test-optimale-meting.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	<p:store name="store" href="../sbg-testdata/html/test-optimale-meting.html" method="html" version="4.0"/>


</p:declare-step>
