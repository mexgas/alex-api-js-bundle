cls
java -jar schemaspy-6.1.0.jar -configFile ./CCenterRia.config.file -norows 

start "" ".\CCenterRia\index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CCReportsRIA.config.file -norows 

start "" ".\CCReportsRIA\index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CCRecorderRIA.config.file -norows 

start "" ".\CCRecorderRIA\index.html"

java -jar schemaspy-6.1.0.jar -configFile ./CW_CenterScript.config.file -norows 

start "" ".\CW_CenterScript\index.html"