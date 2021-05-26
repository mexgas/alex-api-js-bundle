cls

echo Se Configura por proyecto
 
set NameSpace=CWReportsEngine
set tokenSonar=3b2c3c2b334d7b2df79628443c52181df7a9b20b
set NameSpaceProyect="%NameSpace%.Services"
set pathDLL=".\%NameSpace%.Test.Unit\bin\Debug\%NameSpace%.Test.Unit.dll"

set PathOpenCover=%appdata%\..\Local\Apps\OpenCover\OpenCover.Console.exe
set PathNunit=C:\Program Files (x86)\NUnit.org\nunit-console\nunit3-console.exe
set PathReportGenerator=C:\ReportGenerator\ReportGenerator.exe


SonarScanner.MSBuild.exe begin /k:"%NameSpace%" /d:sonar.host.url="http://localhost:9000" /d:sonar.login="%tokenSonar%" 
MSBuild.exe "%NameSpace%.sln" /t:clean;rebuild  /p:Configuration=Debug

rem "%PathOpenCover%" -target:"%PathNunit%" -targetargs:"%pathDLL% --result=unitTestResult.xml;format=\"nunit2\"" -excludebyattribute:*.ExcludeFromCodeCoverage* -filter:"+[%NameSpaceProyect%]* -[%NameSpaceProyect%]*.Model.Dto.* -[%NameSpaceProyect%]*.Model.Db.* -[%NameSpaceProyect%]*.Helper.Event.* -[%NameSpaceProyect%]*.Wrapper.* -[%NameSpaceProyect%]*.Delegates.* -[%NameSpaceProyect%]*.Properties.* -[%NameSpaceProyect%]*.Repository.Db.* " -register:user -hideskipped:Filter -output:".\Coverge.xml"

SonarScanner.MSBuild.exe end /d:sonar.login="%tokenSonar%"

rem "%PathReportGenerator%" -reports:"Coverge.xml" -targetDir:"CoverageHTML" -reporttypes:HTML;PngChart "-historydir:HistoryCoverage"
rem start "" ".\CoverageHTML\index.htm"