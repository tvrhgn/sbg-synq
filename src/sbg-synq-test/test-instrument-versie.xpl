<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/ns/xproc ../xproc/xproc.xsd"
	xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1" version="1.0" name="test-instrument-versie">

	<p:input port="source">
		<p:empty />
	</p:input>

	<p:input port="meting">
		<p:document href="../../examples/PoC/PoC-data/Brondata_sbg-meting.xml" />
	</p:input>

	<p:input port="meting-item">
		<p:document href="../../examples/PoC/PoC-data/Brondata_sbg-item.xml" />
	</p:input>

	<p:output port="result" sequence="true">
		<p:pipe step="meting" port="result" />
	</p:output>

	<p:identity name="meting">
		<p:input port="source" select="//Row[gebruiktMeetinstrument ne 'BSI']">
			<p:pipe step="test-instrument-versie" port="meting"></p:pipe>
		</p:input>
	</p:identity>

	<!-- <p:xquery name="query"> <p:input port="source"> </p:input> <p:input 
		port="query"> <p:data href="test-optimale-meting.xq" /> </p:input> <p:input 
		port="parameters"> <p:empty /> </p:input> </p:xquery> <p:store name="store" 
		href="../../sbg-synq-out/test-meting.xml"/> -->

</p:declare-step>
