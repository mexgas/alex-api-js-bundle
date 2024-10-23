@echo off

REM Definir la ruta donde están ubicados los archivos SQL o DACPAC
set DacpacPath=%~dp0

REM Definir el nombre del archivo ZIP que se va a crear
set ZipFileName=DacpacFiles.zip

REM Cambiar al directorio donde están los archivos .sql o .dacpac
cd /d %DacpacPath%

REM Verificar si el archivo ZIP ya existe y eliminarlo
if exist %ZipFileName% (
    echo El archivo %ZipFileName% ya existe. Eliminándolo...
    del %ZipFileName%
)

REM Comprimir todos los archivos .sql o .dacpac en un archivo ZIP usando PowerShell
echo Comprimiendo archivos SQL %ZipFileName%...
powershell -Command "Compress-Archive -Path '*.sql' -DestinationPath '%ZipFileName%'"

REM Verificar si el archivo ZIP se creó correctamente
if exist %ZipFileName% (
    echo Archivos comprimidos exitosamente en %ZipFileName%.
) else (
    echo Error al comprimir los archivos.
)

@REM pause
