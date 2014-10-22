#!/bin/bash
export PATH=$PATH:/home/tenfialho/Desenvolvimento/VIDEOCONFERENCIA/Arquivo_vconf/flex_sdk_4.1/bin/
mxmlc -load-config flex-config.xml ./src/cmdo.mxml -output ./bin/cmdo.swf
mxmlc -load-config flex-config.xml ./src/cmdomin.mxml -output ./bin/cmdomin.swf
mxmlc -load-config flex-config.xml ./src/omds.mxml -output ./bin/omds.swf
