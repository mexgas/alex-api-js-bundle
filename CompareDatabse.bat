rem @echo off

REM Define la ruta a SqlPackage.exe
set SqlPackagePath="C:\Devops\sqlpackage-win-x64-en-162.4.92.3\SqlPackage.exe"

REM Verifica si se pasaron los nombres de las bases de datos como parámetros
if "%1"=="" (
    echo Por favor proporciona el nombre de la base de datos de origen como primer parámetro.
    exit /b
)


REM Define los nombres de las bases de datos pasados como parámetros
set PrDatabaseName=%1
set DestDatabaseName=%1

REM Define los detalles de conexión, con el parámetro TrustServerCertificate en la cadena de conexión
set OriConnectionString="Data Source=127.0.0.1,1436;Initial Catalog=%DestDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"
set PrConnectionString="Data Source=127.0.0.1,1437;Initial Catalog=%PrDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"

REM Define los archivos DACPAC donde se guardarán los esquemas extraídos
set PrDacpac=%PrDatabaseName%_Pr.dacpac
set OriDacpac=%DestDatabaseName%_Ori.dacpac

REM Define los archivos de salida para el reporte XML y los scripts SQL
set ReportFile=%PrDatabaseName%.xml
set ScriptFileForward=%PrDatabaseName%_Pr.sql

set ScriptFileBackward=%DestDatabaseName%_Ori.sql

set folderPrDacpac=%PrDatabaseName%_Pr
set folderOriDacpac=%DestDatabaseName%_Ori


REM Extraer el esquema de la base de datos de destino a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de destino: %OriDacpac%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%OriConnectionString% /TargetFile:%OriDacpac%

REM Extraer el esquema de la base de datos de origen a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de Pr: %PrDacpac%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%PrConnectionString% /TargetFile:%PrDacpac%


unpackdacpac unpack %PrDacpac% %folderPrDacpac% --deploy-script-exclude-object-type Users --deploy-script-exclude-object-type Logins --deploy-script-exclude-object-type RoleMembership
unpackdacpac unpack %OriDacpac% %folderOriDacpac% --deploy-script-exclude-object-type Users --deploy-script-exclude-object-type Logins --deploy-script-exclude-object-type RoleMembership

:: Mover y renombrar el archivo
move "%folderPrDacpac%\model.sql" "%ScriptFileForward%"    
move "%folderOriDacpac%\model.sql" "%ScriptFileBackward%"    

