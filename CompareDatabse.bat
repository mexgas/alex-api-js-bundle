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
set TargetDatabaseName=%2

REM Define los detalles de conexión, con el parámetro TrustServerCertificate en la cadena de conexión
set SourceConnectionString="Data Source=192.168.1.59,1436;Initial Catalog=%SourceDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"
set TargetConnectionString="Data Source=192.168.1.59,1437;Initial Catalog=%TargetDatabaseName%;User Id=sa;Password=Nuxiba2024_;Encrypt=False;TrustServerCertificate=True"

REM Define los archivos DACPAC donde se guardarán los esquemas extraídos
set SourceDacpac=%~dp0Source_%SourceDatabaseName%.dacpac
set TargetDacpac=%~dp0Target_%TargetDatabaseName%.dacpac

REM Extraer el esquema de la base de datos de origen a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de origen: %SourceDatabaseName%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%SourceConnectionString% /TargetFile:%SourceDacpac%
if %ERRORLEVEL% neq 0 (
    echo Error al extraer el esquema de la base de datos de origen.
    pause
    exit /b
)

REM Extraer el esquema de la base de datos de destino a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de destino: %TargetDatabaseName%...
%SqlPackagePath% /Action:Extract /SourceConnectionString:%TargetConnectionString% /TargetFile:%TargetDacpac%
if %ERRORLEVEL% neq 0 (
    echo Error al extraer el esquema de la base de datos de destino.
    pause
    exit /b
)

echo Archivos DACPAC generados exitosamente:
echo - Origen: %SourceDacpac%
echo - Destino: %TargetDacpac%
