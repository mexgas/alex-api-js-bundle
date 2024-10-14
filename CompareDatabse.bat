@echo off

REM Define la ruta a SqlPackage.exe
set SqlPackagePath="C:\Devops\sqlpackage-win-x64-en-162.4.92.3\SqlPackage.exe"

REM Verifica si se pasaron los nombres de las bases de datos como parámetros
if "%1"=="" (
    echo Por favor proporciona el nombre de la base de datos de origen como primer parámetro.
    exit /b
)

if "%2"=="" (
    echo Por favor proporciona el nombre de la base de datos de destino como segundo parámetro.
    exit /b
)

REM Define los nombres de las bases de datos pasados como parámetros
set SourceDatabaseName=%1
set PrDatabaseName=%2

REM Define los detalles de conexión, con el parámetro TrustServerCertificate en la cadena de conexión
set SourceConnectionString="Data Source=192.168.1.59,1436;Initial Catalog=%SourceDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"
set PrConnectionString="Data Source=192.168.1.59,1437;Initial Catalog=%PrDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"

REM Define los archivos DACPAC donde se guardarán los esquemas extraídos
set SourceDacpac=%SourceDatabaseName%_Ori.dacpac
set PrDacpac=%PrDatabaseName%_PR.dacpac

REM Define los archivos de salida para el reporte XML y los scripts SQL
set ScriptFileBackward=%SourceDatabaseName%_Ori.sql

set ReportFile=%PrDatabaseName%.xml
set ScriptFileForward=%PrDatabaseName%_Pr.sql


REM Extraer el esquema de la base de datos de origen a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de Pr: %SourceDatabaseName%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%SourceConnectionString% /TargetFile:%SourceDacpac%
if %ERRORLEVEL% neq 0 (
    echo Error al extraer el esquema de la base de datos de origen.
    pause
    exit /b
)

REM Extraer el esquema de la base de datos de destino a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de destino: %PrDatabaseName%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%PrConnectionString% /TargetFile:%PrDacpac%
if %ERRORLEVEL% neq 0 (
    echo Error al extraer el esquema de la base de datos de destino.
    pause
    exit /b
)

REM Comparar el archivo DACPAC de origen con la base de datos de destino (Forward) y generar un reporte XML y script SQL
echo Comparando el archivo DACPAC de origen con la base de datos de destino y generando el reporte XML 
%SqlPackagePath% /Action:DeployReport /SourceFile:%SourceDacpac% /TargetConnectionString:%SourceConnectionString% /OutputPath:%ReportFile%

echo Comparando el archivo DACPAC de origen con la base de datos de destino y generando el script SQL %ScriptFileForward%
%SqlPackagePath% /Action:Script /SourceFile:%SourceDacpac% /TargetConnectionString:%SourceConnectionString% /OutputPath:%ScriptFileBackward%

%SqlPackagePath% /Action:Script /SourceFile:%PrDacpac% /TargetConnectionString:%PrConnectionString% /OutputPath:%ScriptFileForward%

echo Archivos generados exitosamente:
echo - Reporte XML: %ReportFile%
echo - Origen -> Destino - Script SQL: %ScriptFileForward%
echo - Destino -> Origen - Script SQL: %ScriptFileBackward%
rem pause
