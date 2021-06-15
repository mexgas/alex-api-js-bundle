cls
set pathReport=D:/schemaspy
java -jar schemaspy-6.1.0.jar -configFile ./CCenterRia.config.file -norows 

rem start "" "%pathReport%/CCenterRia/index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CCReportsRIA.config.file -norows 

rem start "" "%pathReport%/CCReportsRIA/index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CCRecorderRIA.config.file -norows 

rem start "" "%pathReport%/CCRecorderRIA/index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CW_CenterScript.config.file -norows 

rem start "" "/%pathReport%/CW_CenterScript/index.html"