@echo off

REM Definir la ruta donde están ubicados los archivos SQL
set DacpacPath=%~dp0

REM Definir el nombre del archivo ZIP que se va a crear
set ZipFileName=DacpacFiles.zip

REM Cambiar al directorio donde están los archivos .sql
cd /d %DacpacPath%

REM Comprimir todos los archivos .sql en un archivo ZIP usando la herramienta nativa de Windows (tar)
echo Comprimiendo archivos SQL en %ZipFileName%...
tar -cvf %ZipFileName% *.sql -a

REM Verificar si el archivo ZIP se creó correctamente
if exist %ZipFileName% (
    echo Archivos SQL comprimidos exitosamente en %ZipFileName%.
) else (
    echo Error al comprimir los archivos SQL.
)

@REM pause
