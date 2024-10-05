cls
set pathReport=D:/schemaspy
java -jar schemaspy-6.1.0.jar -configFile ./CCenterRia.config.file -norows -o "%pathReport%/CCenterRia"

rem start "" "%pathReport%/CCenterRia/index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CCReportsRIA.config.file -norows -o "%pathReport%/CCReportsRIA"

rem start "" "%pathReport%/CCReportsRIA/index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CCRecorderRIA.config.file -norows -o "%pathReport%/CCRecorderRIA"

rem start "" "%pathReport%/CCRecorderRIA/index.html"

@REM java -jar schemaspy-6.1.0.jar -configFile ./CW_CenterScript.config.file -norows -o "%pathReport%/CW_CenterScript"

rem start "" "/%pathReport%/CW_CenterScript/index.html"