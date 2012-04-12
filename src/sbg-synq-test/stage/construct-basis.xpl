<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/ns/xproc ../xproc/xproc.xsd"
	xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1" version="1.0"
	name="sbg-construct">

	<p:option name="stage.dir" select="'../../../sbg-synq-out'" />
	<p:option name="checklist_html" select="'checklist.html'" />

	<p:input port="source">
		<p:empty />
	</p:input>

	<p:input port="meting">
		<p:document href="../../../examples/PoC/PoC-data/Brondata_sbg-meting.xml" />
	</p:input>
	<p:input port="meting-item">
		<!-- <p:document href="/home/thijs/tmp/PDI/output/sbg/selectie/sbg-meting-item-select.xml" 
			/> -->
		<p:document href="../../../examples/PoC/PoC-data/Brondata_sbg-item.xml" />
	</p:input>

	<p:input port="epd">
		<p:document href="../../../examples/PoC/PoC-data/Brondata_sbg-epd.xml" />
	</p:input>

	<p:input port="behandelaar">
		<p:document href="../../../examples/PoC/PoC-data/Brondata_Behandelaar.xml" />
	</p:input>

	<p:input port="nevendiagnose">
		<p:document href="../../../examples/PoC/PoC-data/Brondata_NevendiagnoseCode.xml" />
	</p:input>


	<p:output port="result" sequence="true">
		<p:pipe step="store-t" port="result" />
	</p:output>

	<p:xquery name="meting-items">
		<p:input port="source">
			<p:pipe step="sbg-construct" port="meting-item" />
		</p:input>

		<p:input port="query">
			<p:data href="group-Items.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<p:wrap-sequence name="wrap-source" wrapper="context">
		<p:input port="source">
			<p:pipe step="sbg-construct" port="meting" />
			<p:pipe step="meting-items" port="result" />
		</p:input>
	</p:wrap-sequence>
	
	<p:xquery name="meting-in">
		<p:input port="source">
			<p:pipe step="wrap-source" port="result" />
		</p:input>

		<p:input port="query">
			<p:data href="build-Meting.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
			
		
	
	<p:xquery name="behandelaar-in">
		<p:input port="source">
			<p:pipe step="sbg-construct" port="behandelaar" />
		</p:input>

		<p:input port="query">
			<p:data href="group-Behandelaar.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
	<p:xquery name="nevendiagnose-in">
		<p:input port="source">
			<p:pipe step="sbg-construct" port="nevendiagnose" />
		</p:input>

		<p:input port="query">
			<p:data href="group-Nevendiagnose.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	
	<p:wrap-sequence name="wrap-source-epd" wrapper="context">
		<p:input port="source">
			<p:pipe step="sbg-construct" port="epd" />
			<p:pipe step="behandelaar-in" port="result" />
			<p:pipe step="nevendiagnose-in" port="result" />
		</p:input>
	</p:wrap-sequence>
	<p:xquery name="epd-in">
		<p:input port="source">
			<p:pipe step="wrap-source-epd" port="result" />
		</p:input>

		<p:input port="query">
			<p:data href="build-Patient.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
			


	<p:store name="store">
		<p:input port="source">
			<p:pipe step="meting-in" port="result" />
		</p:input>
		<p:with-option name="href"
			select="concat( $stage.dir, '/Meting-in.xml')" />
	</p:store>

	<p:store name="store-behandelaar">
		<p:input port="source">
			<p:pipe step="behandelaar-in" port="result" />
		</p:input>
		<p:with-option name="href"
			select="concat( $stage.dir, '/Behandelaar-in.xml')" />
	</p:store>

	<p:store name="store-nevendiagnose">
		<p:input port="source">
			<p:pipe step="nevendiagnose-in" port="result" />
		</p:input>
		<p:with-option name="href"
			select="concat( $stage.dir, '/NevendiagnoseCode-in.xml')" />
	</p:store>
	
	<p:store name="store-t">
		<p:input port="source">
			<p:pipe step="epd-in" port="result" />
		</p:input>
		<p:with-option name="href"
			select="concat( $stage.dir, '/t.xml')" />
	</p:store>

</p:declare-step>
