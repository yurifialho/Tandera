#!/bin/bash
export PATH=$PATH:/home/tenfialho/Desenvolvimento/VIDEOCONFERENCIA/Arquivo_vconf/flex_sdk_4.1/bin/
mxmlc -load-config flex-config.xml ./src/vconf2.mxml -output ./bin/modulo_CMDO2.swf
mxmlc -load-config flex-config.xml ./src/vconf3.mxml -output ./bin/modulo_OM2.swf
