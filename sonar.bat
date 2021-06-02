cls

set sonarBat="D:\Sonarqube\sonar-scanner-4.6.1.2450-windows\bin\sonar-scanner.bat"

%sonarBat% -D"sonar.projectKey=cw-database" -D"sonar.sources=./SchemaDatabase" -D"sonar.host.url=http://localhost:9000" -D"sonar.login=e999879c952a521e6f897bef05071a3e6763c79d"

pause