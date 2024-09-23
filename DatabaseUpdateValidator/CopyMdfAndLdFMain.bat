@echo off
rem Copiar archivos .mdf y .ldf de una ruta relativa a otra

rem Definir las rutas relativas de origen y destino
set source=.\CCenterRIA\
set destination=.\DataMain

rem Crear el destino si no existe
if not exist %destination% (
    mkdir %destination%
)

rem Copiar todos los archivos .mdf y .ldf
for %%f in ("%source%\*.mdf" "%source%\*.ldf") do (
    if exist "%%~f" (
        copy "%%~f" "%destination%\"
        echo Archivo copiado: %%~f
    ) else (
        echo No se encontraron archivos .mdf o .ldf en la ruta de origen.
    )
)

set source=.\ccReportsRia\
set destination=.\DataMain

rem Crear el destino si no existe
if not exist %destination% (
    mkdir %destination%
)

rem Copiar todos los archivos .mdf y .ldf
for %%f in ("%source%\*.mdf" "%source%\*.ldf") do (
    if exist "%%~f" (
        copy "%%~f" "%destination%\"
        echo Archivo copiado: %%~f
    ) else (
        echo No se encontraron archivos .mdf o .ldf en la ruta de origen.
    )
)

set source=.\RecorderRIA\Database
set destination=.\DataMain

rem Crear el destino si no existe
if not exist %destination% (
    mkdir %destination%
)

rem Copiar todos los archivos .mdf y .ldf
for %%f in ("%source%\*.mdf" "%source%\*.ldf") do (
    if exist "%%~f" (
        copy "%%~f" "%destination%\"
        echo Archivo copiado: %%~f
    ) else (
        echo No se encontraron archivos .mdf o .ldf en la ruta de origen.
    )
)


echo Todos los archivos .mdf y .ldf han sido procesados.

