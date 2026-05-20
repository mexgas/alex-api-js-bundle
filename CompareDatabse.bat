rem @echo off
setlocal EnableExtensions

REM Define la ruta a SqlPackage.exe
set "SqlPackagePath=C:\Devops\sqlpackage-win-x64-en-162.4.92.3\SqlPackage.exe"
set "ConnectionTimeout=300"
set "CommandTimeout=300"
set "MainServer=%SQL_SERVER_SERVER_MAIN%"
set "PrServer=%SQL_SERVER_SERVER_PR%"
set "SqlUser=%SQL_SERVER_USER%"
set "SqlPassword=%SQL_SERVER_PASSWORD%"

if "%MainServer%"=="" set "MainServer=192.168.1.59,1436"
if "%PrServer%"=="" set "PrServer=192.168.1.59,1437"
if "%SqlUser%"=="" set "SqlUser=sa"
if "%SqlPassword%"=="" set "SqlPassword=Nuxiba2024_"

REM Verifica si se pasaron los nombres de las bases de datos como parámetros
if "%~1"=="" (
    echo Por favor proporciona el nombre de la base de datos de origen como primer parámetro.
    exit /b 1
)


REM Define los nombres de las bases de datos pasados como parámetros
set "PrDatabaseName=%~1"
set "DestDatabaseName=%~2"
if "%DestDatabaseName%"=="" set "DestDatabaseName=%PrDatabaseName%"

echo("%PrDatabaseName%"| findstr /R "[\\/:*?<>|&]" >nul
if not errorlevel 1 (
    echo El nombre de la base de datos de Pr contiene caracteres no permitidos: %PrDatabaseName%
    exit /b 1
)

echo("%DestDatabaseName%"| findstr /R "[\\/:*?<>|&]" >nul
if not errorlevel 1 (
    echo El nombre de la base de datos de destino contiene caracteres no permitidos: %DestDatabaseName%
    exit /b 1
)

REM Define los detalles de conexión, con el parámetro TrustServerCertificate en la cadena de conexión
set "OriConnectionString=Data Source=%MainServer%;Initial Catalog=%DestDatabaseName%;User Id=%SqlUser%;Password=%SqlPassword%;Encrypt=False;TrustServerCertificate=True;Connect Timeout=%ConnectionTimeout%"
set "PrConnectionString=Data Source=%PrServer%;Initial Catalog=%PrDatabaseName%;User Id=%SqlUser%;Password=%SqlPassword%;Encrypt=False;TrustServerCertificate=True;Connect Timeout=%ConnectionTimeout%"
echo Servidor destino/main: %MainServer%
echo Servidor Pr: %PrServer%

REM Define los archivos DACPAC donde se guardarán los esquemas extraídos
set "PrDacpac=%PrDatabaseName%_Pr.dacpac"
set "OriDacpac=%DestDatabaseName%_Ori.dacpac"

REM Define los archivos de salida para el reporte XML y los scripts SQL
set "ReportFile=%PrDatabaseName%.xml"
set "ScriptFileForward=%PrDatabaseName%_Pr.sql"

set "ScriptFileBackward=%DestDatabaseName%_Ori.sql"

set "folderPrDacpac=%PrDatabaseName%_Pr"
set "folderOriDacpac=%DestDatabaseName%_Ori"

if exist "%PrDacpac%" del /f /q "%PrDacpac%"
if exist "%OriDacpac%" del /f /q "%OriDacpac%"
if exist "%ScriptFileForward%" del /f /q "%ScriptFileForward%"
if exist "%ScriptFileBackward%" del /f /q "%ScriptFileBackward%"
if exist "%folderPrDacpac%" rmdir /s /q "%folderPrDacpac%"
if exist "%folderOriDacpac%" rmdir /s /q "%folderOriDacpac%"

REM Extraer el esquema de la base de datos de destino a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de destino: %OriDacpac%...
"%SqlPackagePath%" /Action:Extract /SourceConnectionString:"%OriConnectionString%" /SourceTimeout:%ConnectionTimeout% /p:CommandTimeout=%CommandTimeout% /TargetFile:"%OriDacpac%" /OverwriteFiles:True
if errorlevel 1 (
    echo Error al generar el archivo DACPAC de destino: %OriDacpac%
    exit /b 1
)
if not exist "%OriDacpac%" (
    echo No se genero el archivo DACPAC de destino: %OriDacpac%
    exit /b 1
)

REM Extraer el esquema de la base de datos de origen a un archivo DACPAC
echo Generando archivo DACPAC de la base de datos de Pr: %PrDacpac%...
"%SqlPackagePath%" /Action:Extract /SourceConnectionString:"%PrConnectionString%" /SourceTimeout:%ConnectionTimeout% /p:CommandTimeout=%CommandTimeout% /TargetFile:"%PrDacpac%" /OverwriteFiles:True
if errorlevel 1 (
    echo Error al generar el archivo DACPAC de Pr: %PrDacpac%
    exit /b 1
)
if not exist "%PrDacpac%" (
    echo No se genero el archivo DACPAC de Pr: %PrDacpac%
    exit /b 1
)


unpackdacpac unpack "%PrDacpac%" "%folderPrDacpac%" --deploy-script-exclude-object-type Users --deploy-script-exclude-object-type Logins --deploy-script-exclude-object-type RoleMembership
if errorlevel 1 (
    echo Error al desempaquetar el archivo DACPAC de Pr: %PrDacpac%
    exit /b 1
)
if not exist "%folderPrDacpac%\model.sql" (
    echo No se encontro el archivo model.sql de Pr en: %folderPrDacpac%
    exit /b 1
)

unpackdacpac unpack "%OriDacpac%" "%folderOriDacpac%" --deploy-script-exclude-object-type Users --deploy-script-exclude-object-type Logins --deploy-script-exclude-object-type RoleMembership
if errorlevel 1 (
    echo Error al desempaquetar el archivo DACPAC de destino: %OriDacpac%
    exit /b 1
)
if not exist "%folderOriDacpac%\model.sql" (
    echo No se encontro el archivo model.sql de destino en: %folderOriDacpac%
    exit /b 1
)

:: Mover y renombrar el archivo
move /Y "%folderPrDacpac%\model.sql" "%ScriptFileForward%"
if errorlevel 1 (
    echo Error al mover el script de Pr: %ScriptFileForward%
    exit /b 1
)

move /Y "%folderOriDacpac%\model.sql" "%ScriptFileBackward%"
if errorlevel 1 (
    echo Error al mover el script de destino: %ScriptFileBackward%
    exit /b 1
)

exit /b 0
