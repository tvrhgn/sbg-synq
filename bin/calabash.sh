#! /bin/bash

# example xproc commandline
SBG_SYNQ_HOME=..

java  -cp $SBG_SYNQ_HOME/lib/calabash.jar:$SBG_SYNQ_HOME/lib/saxon9he.jar:$SBG_SYNQ_HOME/commons-codec-1.3.jar:$SBG_SYNQ_HOME/lib/commons-httpclient-3.1.jar:$SBG_SYNQ_HOME/lib/commons-logging-1.1.1.jar com.xmlcalabash.drivers.Main $@

echo Done.
