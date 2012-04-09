<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3.org/ns/xproc ../xproc/xproc.xsd"
	xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1" 
	xmlns:sbgm="http://sbg-synq.nl/sbg-metingen" 
	version="1.0"
	name="test-verwerk-meting">

	<p:input port="source">
		<p:document href="/home/thijs/tmp/PDI/output/sbg/selectie/Meting.xml" />
	</p:input>

	<p:input port="instrumenten-lib">
		<p:document href="../../examples/sbg-instrumenten.xml" />
	</p:input>

	<p:output port="result">
		<p:pipe step="store" port="result" />
	</p:output>

	<p:wrap-sequence name="wrap-source" wrapper="context">
		<p:input port="source">
			<p:pipe step="test-verwerk-meting" port="instrumenten-lib" />
			<p:pipe step="test-verwerk-meting" port="source" />
		</p:input>
	</p:wrap-sequence>

	<p:xquery name="metingen">
		<p:input port="source">
			<p:pipe step="wrap-source" port="result"/>
		</p:input>
		
		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace
					sbgi="http://sbg-synq.nl/sbg-instrument" at
					'../sbg-synq/sbg-instrument.xquery';
					import module namespace
					sbgm="http://sbg-synq.nl/sbg-metingen" at
					'../sbg-synq/sbg-metingen.xquery';

					let $ctx := .,
					$instrumenten :=
					sbgi:laad-instrumenten( $ctx//instrument ),
					
					$metingen := 
					sbgm:sbg-metingen($ctx//Meting, $instrumenten) 
					
					return &lt;result xmlns:sbgm="http://sbg-synq.nl/sbg-metingen" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1">
					{$metingen}
					&lt;/result>
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>
	<p:store name="store" href="../../sbg-synq-out/test-Meting.xml" />

</p:declare-step>
