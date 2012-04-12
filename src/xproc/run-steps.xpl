<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1"
	name="sbg-batch" version="1.0">

	<p:documentation>
		doe een run zoals in run-batch, maar roep de
		onderdelen aan vanuit xproc
		en sla de tussenresultaten apart op
	</p:documentation>

	<p:input port="config">
		<p:document href="../../examples/PoC/zorgaanbieder-PoC.xml" />
	</p:input>

	<p:output port="result">
		<p:pipe step="config-add-ts" port="result" />
	</p:output>

	<p:variable name="timestamp" select="current-dateTime()" />

	<p:variable name="tmp.dir" select="//target[1]/tmp">
		<p:pipe step="sbg-batch" port="config" />
	</p:variable>

	<p:add-attribute name="config-add-ts" match="//batch[1]"
		attribute-name="datumCreatie">
		<p:with-option select="$timestamp" name="attribute-value" />
		<p:input port="source">
			<p:pipe step="sbg-batch" port="config" />
		</p:input>
	</p:add-attribute>

	<!-- bouw de instrument-bibliotheek op voor zorgaanbieder -->
	<!-- verwerk ruwe meetgegevens en geef een elt 'result' met de zorgaanbieder 
		en een rij sbgm:Meting -->
	<p:xquery name="metingen">
		<p:input port="source">
			<p:pipe step="config-add-ts" port="result" />
		</p:input>

		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace
					sbgza="http://sbg-synq.nl/zorgaanbieder" at
					'../sbg-synq/zorgaanbieder.xquery';
					import module namespace
					sbgi="http://sbg-synq.nl/sbg-instrument" at
					'../sbg-synq/sbg-instrument.xquery';
					import module namespace
					sbgm="http://sbg-synq.nl/sbg-metingen" at
					'../sbg-synq/sbg-metingen.xquery';

					let $za :=
					sbgza:build-zorgaanbieder( ./zorgaanbieder ),
					$instrumenten :=
					sbgi:laad-instrumenten( $za/instrumenten//instrument ),
					
					$metingen :=
					sbgm:build-Metingen($za/rom/*, $za/rom-items/*)
					return
					element { 'result' }{
					(), $za,
					element { 'metingen' }{ 
					(),
					sbgm:sbg-metingen($metingen,
					$instrumenten) 
					}
					}
									</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<!-- koppel metingen aan epd; geef elt 'result' met de zorgaanbieder en 
		een rij sbgem:Patient -->
	<!-- een sbgem:Patient bevat alle metingen bekend bij een zekere client; 
		sbgem:zorgdomeinCode is de via zorgaanbieder afgeleide code -->
	<p:xquery name="patient-meting">
		<p:input port="source">
			<p:pipe step="metingen" port="result" />
		</p:input>

		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace
					sbgem="http://sbg-synq.nl/epd-meting" at
					'../sbg-synq/epd-meting.xquery';
					
					 declare namespace
					sbgm="http://sbg-synq.nl/sbg-metingen";
					
					let $za := //zorgaanbieder
					return
					element { 'result' } {
					(), $za,
					element { 'patient-meting' } { 
					(),
					sbgem:maak-patient-meting( $za/epd/*,
					$za/behandelaar/*,
					$za/nevendiagnose/*, .//sbgm:Meting,
					$za/sbg-zorgdomeinen/* ) 
					}
					}
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<!-- filter wat onderdelen om als basis voor proces-informatie; nevendiagnose, 
		meting-items zijn meer geschikt als onderzoeks-data; productiviteit behandelaar 
		is aan andere bron gekoppeld. Wordt naderhand opgeslagen als patient-meting.xml 
		om te laden in tabel -->
	<p:viewport name="patient-meting-compact" match="sbgem:Patient"
		xmlns:sbgem="http://sbg-synq.nl/epd-meting" xmlns:sbgm="http://sbg-synq.nl/sbg-metingen"
		xmlns:sbggz="http://sbggz.nl/schema/import/5.0.1">
		<p:delete
			match="//sbggz:NevendiagnoseCode | //Item | //sbggz:Behandelaar[@primairOfNeven eq '0']" />
	</p:viewport>

	<!-- filter de sbg te selecteren metingen en geef de zorgaanbieder en een 
		rij Patient -->
	<!-- zorgtraject krijgt hier een zorgdomeinCode die evt de metingen volgt 
		ipv de DBC 
	<p:xquery name="sbg-patient-meting">
		<p:input port="source">
			<p:pipe step="patient-meting" port="result" />
		</p:input>

		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace sbge="http://sbg-synq.nl/sbg-epd"
					at '../sbg-synq/sbg-epd.xquery';

					let $za := //zorgaanbieder
					return
					element { 'result' } {
					(), $za,
					element { 'sbg-patient-meting' } {
					(),
					sbge:sbg-patient-meting(//patient-meting/*,
					$za/sbg-zorgdomeinen//zorgdomein )
					}
					}
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

	<p:xquery name="sbg-benchmark-info">
		<p:input port="source">
			<p:pipe step="sbg-patient-meting" port="result" />
		</p:input>

		<p:input port="query">
			<p:inline>
				<c:query>
					import module namespace sbgbm =
					"http://sbg-synq.nl/sbg-benchmark" at
					'../sbg-synq/sbg-bmimport.xquery';
					declare namespace sbggz =
					"http://sbggz.nl/schema/import/5.0.1";

					let $za := //zorgaanbieder
					return
					element { 'result' } {
					(), $za,
					element { 'benchmark-info' } {
					(),
					sbgbm:build-sbg-bmimport( $za,
					//sbg-patient-meting//sbggz:Patient )
					}
					}
				</c:query>
			</p:inline>
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xquery>

-->


	<p:store name="store-zorgaanbieder">
		<p:with-option name="href"
			select="concat( $tmp.dir, '/zorgaanbieder.xml')" />
		<p:input port="source">
			<p:pipe step="config-add-ts" port="result" />
		</p:input>
	</p:store>


	<p:store name="store-metingen">
		<p:with-option name="href" select="concat( $tmp.dir,'/metingen.xml')" />
		<p:input port="source" select="//metingen">
			<p:pipe step="metingen" port="result" />
		</p:input>
	</p:store>

	<p:store name="store-patient-meting">
		<p:with-option name="href"
			select="concat( $tmp.dir,'/patient-meting.xml')" />
		<p:input port="source" select="//patient-meting">
			<p:pipe step="patient-meting" port="result" />
		</p:input>
	</p:store>

	<p:store name="store-patient-meting-compact">
		<p:with-option name="href"
			select="concat( $tmp.dir,'/patient-meting-compact.xml')" />
		<p:input port="source" select="//patient-meting">
			<p:pipe step="patient-meting-compact" port="result" />
		</p:input>
	</p:store>


</p:declare-step>
