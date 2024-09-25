@echo off

REM Definir la ruta donde están ubicados los archivos DACPAC
set DacpacPath=%~dp0

REM Definir el nombre del archivo ZIP que se va a crear
set ZipFileName=DacpacFiles.zip

REM Cambiar al directorio donde están los archivos .dacpac
cd /d %DacpacPath%

REM Comprimir todos los archivos .dacpac en un archivo ZIP
echo Comprimiendo archivos DACPAC en %ZipFileName%...
tar -cvf %ZipFileName% *.dacpac

REM Verificar si el archivo ZIP se creó correctamente
if exist %ZipFileName% (
    echo Archivos DACPAC comprimidos exitosamente en %ZipFileName%.
) else (
    echo Error al comprimir los archivos DACPAC.
)

pause
