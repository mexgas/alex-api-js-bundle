@echo off
REM Definir la ruta de la carpeta origen SCHEMA_BD
set sourceDir=save-schema-db\SaveSchemaDbServices\bin\Debug\SCHEMA_BD

REM Definir la ruta de destino (la carpeta actual donde se ejecuta el .bat)
set destDir=%cd%\SCHEMA_BD

REM Verificar si la carpeta de destino ya existe, si es así, eliminarla
if exist "%destDir%" (
    echo La carpeta SCHEMA_BD ya existe en %destDir%, eliminándola...
    rmdir /S /Q "%destDir%"
)

REM Crear el destino si no existe
if not exist "%destDir%" mkdir "%destDir%"

REM Copiar todo el contenido de SCHEMA_BD al destino
xcopy /E /I /Y "%sourceDir%" "%destDir%"

REM Verificar si la copia fue exitosa
if errorlevel 1 (
    echo Error al copiar los archivos.
    exit /b 1
)

REM Eliminar la carpeta original
rmdir /S /Q "%sourceDir%"

REM Verificar si la eliminación fue exitosa
if exist "%sourceDir%" (
    echo No se pudo eliminar la carpeta original.
) else (
    echo Carpeta movida exitosamente.
)

exit /b 0
