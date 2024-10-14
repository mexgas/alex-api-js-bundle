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
set OriConnectionString="Data Source=192.168.1.59,1436;Initial Catalog=%DestDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"
set PrConnectionString="Data Source=192.168.1.59,1437;Initial Catalog=%PrDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"

REM Define los archivos DACPAC donde se guardarán los esquemas extraídos
set PrDacpac=%PrDatabaseName%_Pr.dacpac
set OriDacpac=%DestDatabaseName%_Ori.dacpac

REM Define los archivos de salida para el reporte XML y los scripts SQL
set ReportFile=%PrDatabaseName%.xml
set ScriptFileForward=%PrDatabaseName%_Pr.sql

set ScriptFileBackward=%DestDatabaseName%_Ori.sql

REM Extraer el esquema de la base de datos de destino a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de destino: %OriDacpac%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%OriConnectionString% /TargetFile:%OriDacpac%


REM Extraer el esquema de la base de datos de origen a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de Pr: %PrDacpac%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%PrConnectionString% /TargetFile:%PrDacpac%


REM Comparar el archivo DACPAC de origen con la base de datos de destino (Forward) y generar un reporte XML y script SQL
echo Comparando el archivo DACPAC de origen con la base de datos de destino y generando el reporte XML 
%SqlPackagePath% /Action:DeployReport /SourceFile:%PrDacpac% /TargetConnectionString:%OriConnectionString% /OutputPath:%ReportFile%

echo Comparando el archivo DACPAC de origen con la base de datos de destino y generando el script SQL %ScriptFileForward%
%SqlPackagePath% /Action:Script /SourceFile:%PrDacpac% /TargetConnectionString:%OriConnectionString% /OutputPath:%ScriptFileForward%

%SqlPackagePath% /Action:Script /SourceFile:%OriDacpac% /TargetConnectionString:%PrConnectionString% /OutputPath:%ScriptFileBackward%

rem echo Archivos generados exitosamente:
rem echo - Reporte XML: %ReportFile%
rem echo - Origen -> Destino - Script SQL: %ScriptFileForward%
rem echo - Destino -> Origen - Script SQL: %ScriptFileBackward%
rem rem rem pause
