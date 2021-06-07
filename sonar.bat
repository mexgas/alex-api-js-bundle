cls

set sonarBat="D:\Sonarqube\sonar-scanner-4.6.1.2450-windows\bin\sonar-scanner.bat"
set sonarToken=3d8229d429a12390ba376d891418ac3324126c89

%sonarBat% -D"sonar.projectKey=cw-database" -D"sonar.sources=./SchemaDatabase" -D"sonar.host.url=http://localhost:9000" -D"sonar.login=%sonarToken%"
pause