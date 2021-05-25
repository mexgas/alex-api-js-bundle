cls

set sonarBat="D:\Sonarqube\sonar-scanner-4.6.1.2450-windows\bin\sonar-scanner.bat"

%sonarBat% -D"sonar.projectKey=cw-database" -D"sonar.sources=./SchemaDatabase" -D"sonar.host.url=http://localhost:9000" -D"sonar.login=3b2c3c2b334d7b2df79628443c52181df7a9b20b"

pause