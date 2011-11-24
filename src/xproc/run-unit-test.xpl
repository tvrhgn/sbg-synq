<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" name="test-optimaal-zorgdomein" version="1.0">
    <p:input port="source" sequence="true">
    	<p:empty/>
    </p:input>
    
    <p:output port="result" sequence="true">
    	 <p:empty/>
    </p:output>
		    
    <p:xquery name="run-unit-test">
    	<p:input port="source">
    		<p:document href="../sbg-synq-test/unit-tests.xml"/>
	    </p:input>
    	<p:input port="query">
    		<p:data href="../sbg-synq-test/run-unit-tests.xq"/>
	    </p:input>
	    <p:input port="parameters">
	    	<p:empty/>
	    </p:input>
    </p:xquery>
    <p:store href="../sbg-testdata/run-unit-test.xml"/> 
    
    <p:xslt name="test-html">
    	<p:input port="source">
    		<p:pipe step="run-unit-test" port="result"/>
	    </p:input>
		<p:input port="stylesheet">
			<p:document href="../sbg-synq-test/html-unit-test.xsl"></p:document>
		</p:input>
		<p:input port="parameters">
	    	<p:empty/>
	    </p:input>
    </p:xslt>
    <p:xinclude/>
    
   <p:store href="../sbg-testdata/html/run-unit-test.html" method="html" version="4.0"/>
	
</p:declare-step>
