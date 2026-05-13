Use CCenterRIA
DECLARE @sql NVARCHAR(MAX)
DECLARE @process VARCHAR(MAX)

------------------------------------ BEGIN Configuración Menú (CCenterRIA) ------------------------------------
SET @process = 'Configuración de Menú (2150) - Agentes Virtuales';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2150)
BEGIN
    INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) 
    VALUES (2150, ''Agentes virtuales|Virtual Agents'', 2000, ''B'', 2, 3, '''', ''505b0c30ff896f2db7e7b7946607de282293a6ed731cb58b9192c6d4a764bb05'');
    PRINT ''Menú 2150 insertado en ccMenus.'';
END

IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 2150)
BEGIN
    INSERT INTO ccMenuUser (id_User, id_Menu, type) 
    VALUES (1, 2150, 3);
    PRINT ''Permiso asignado al usuario 1 en ccMenuUser.'';
END
'
EXEC(@sql);

------------------------------------ BEGIN Ajuste Tablas DispositionIA ------------------------------------
SET @process = 'Agregar columna CapturedData a tablas de Disposición IA';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.ccoCallsOutDispositionIA''))
BEGIN
    ALTER TABLE dbo.ccoCallsOutDispositionIA ADD CapturedData VARCHAR(MAX) DEFAULT '''' WITH VALUES;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.ccCallsInDispositionIA''))
BEGIN
    ALTER TABLE dbo.ccCallsInDispositionIA ADD CapturedData VARCHAR(MAX) DEFAULT '''' WITH VALUES;
END
'
EXEC(@sql);