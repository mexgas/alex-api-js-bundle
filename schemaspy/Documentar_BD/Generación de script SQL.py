import pandas as pd
import os
# Seleccionamos nuestro archivo a sacar los datos
archivo = 'C:/schemaspy/tablas Ejemplo.xlsx'

#Colocamos las hojas de calculo que revisaremos
arraytable = ['ccCallsIn', 'ccRIAWorkGroupUsers', 'ccRIACampEspWG', 'ccUsers', 'RepAgentGI', 'RepInCallsDetail', 'ccoCallsOut', 'RepOutDialDetail', 'RepOutCallsDetail']

template = ""

#Generación del script SQL
for table in arraytable:
    df = pd.read_excel(archivo, sheet_name=table)
    data_set = df.iloc[:, [0, 2]].values.tolist()
    template += "\n\n\n\n"
    for value in data_set:
        template += "EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'" + str(value[1]) +"' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'"+ str(table) +"', @level2type=N'COLUMN', @level2name=N'"+ str(value[0]) +"'\n"

#Guardamos el archivo con los scripts para documentar las tablas
file = open("C:/schemaspy/Script.sql", "w")
file.write(template)
file.close()