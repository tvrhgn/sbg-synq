<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="sbg-batch" version="1.0">

	<p:documentation>
		aanroep:
		calabash.sh
		-i config=/absolute/path/zorgaanbieder.xml
		run-batch-sbg.xpl
	
		zorgaanbieder.xml is het document met 
		de sbg-synq- en xproc-instellingen.

		TODO xquery uris configureerbaar maken? 
		
	</p:documentation>

	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<p:output port="result">
		<p:pipe step="logboek" port="result" />
	</p:output>

	<p:output port="result.debug" sequence="true">
		<p:empty />
	</p:output>


	<p:variable name="timestamp" select="current-dateTime()" />

	<!--  gebruik het configuratiedocument om de bestandsnaam van de output op te bouwen -->
	<p:variable name="batch-year" select="substring(//batch[1]/einddatumAangeleverdePeriode, 1, 4 )">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	<p:variable name="batch-month" select="substring(//batch[1]/einddatumAangeleverdePeriode, 6, 2)">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>

	<p:variable name="za-naam" select="upper-case(replace( /zorgaanbieder/naam, ' ', '' ))">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	
	<p:variable name="tmp.doc" select="concat( //target[1]/tmp, '/', 'bmstore.xml')">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	
	<p:variable name="result.doc"
		select="concat( //target[1]/ftp, '/', //@code[1], '_', //target[1]/@type, '_', $za-naam, '_SBG_', $batch-year, '_', $batch-month, '_', //target[1]/@volgnummer, '.xml')">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>
	
	<p:add-attribute name="config-add-ts" match="//batch[1]" attribute-name="datumCreatie">
		<p:with-option select="$timestamp" name="attribute-value"/>
		<p:input port="source">
			<p:pipe step="sbg-batch" port="config" />
		</p:input>
	</p:add-attribute>

	<!--  alle logica zit in de xquery-modules -->
	<p:xquery name="batch">
		<p:input port="source">
			<p:pipe step="config-add-ts" port="result" />
		</p:input>
	
		<p:input port="query">
			<p:data href="../sbg-synq/batch-bmimport.xq" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<!-- dit werkt, maar is een for-each niet beter? root-attributes?? -->
	<p:viewport name="anonimiseer" match="//sbggz:Patient">
		<p:output port="result" />
		<p:hash name="hash" algorithm="sha" match="@koppelnummer">
			<p:with-option name="value" select="//@koppelnummer" />  
			<p:input port="parameters">
				<p:empty />
			</p:input>
		</p:hash>
	</p:viewport>

	<p:store name="store-intern">
		<p:with-option name="href" select="$tmp.doc" />
		<p:input port="source">
			<p:pipe step="batch" port="result" />
		</p:input>
	</p:store>

	<p:store name="store-sbg">
		<p:with-option name="href" select="$result.doc" />
		<p:input port="source">
			<p:pipe step="anonimiseer" port="result" />
		</p:input>
	</p:store>

	<!--  de batch-instellingen en resultaat-uris worden verbatim beschikbaar gemaakt -->
	<p:wrap-sequence name="logboek.1" wrapper="xproc-log">
		<p:input port="source" sequence="true">
			<p:pipe step="sbg-batch" port="config" />
			<p:pipe step="store-intern" port="result" />
			<p:pipe step="store-sbg" port="result" />
		</p:input>
	</p:wrap-sequence>
	<p:add-attribute name="logboek" match="//xproc-log"
		attribute-name="timestamp">
		<p:with-option name="attribute-value" select="$timestamp" />
	</p:add-attribute>


</p:declare-step>
