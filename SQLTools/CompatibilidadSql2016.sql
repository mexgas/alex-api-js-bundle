DECLARE @target_level INT = 130;
DECLARE @required_current_level INT = 100;
DECLARE @major_version INT;

-- Obtener versión del motor
SELECT @major_version = 
    CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(30)), 4) AS INT);

PRINT 'Version del motor (major): ' + CAST(@major_version AS VARCHAR);

-- Validar soporte de SQL 2016+
IF @major_version < 13
BEGIN
    PRINT 'El motor no soporta COMPATIBILITY_LEVEL 130';
    RETURN;
END

DECLARE @db SYSNAME;
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE name IN ('CCenterRIA','CW_CenterScript','CCRecorderRIA','CCReportsRIA');

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @current_level INT;

    SELECT @current_level = compatibility_level
    FROM sys.databases
    WHERE name = @db;

    PRINT '----------------------------------------';
    PRINT 'Base: ' + @db;
    PRINT 'Nivel actual: ' + CAST(@current_level AS VARCHAR);

    IF @current_level = @required_current_level
    BEGIN
        PRINT 'Actualizando a 130...';

        DECLARE @sql NVARCHAR(MAX) =
            'ALTER DATABASE [' + @db + '] SET COMPATIBILITY_LEVEL = 130';

        EXEC(@sql);

        PRINT 'Actualizada correctamente';
    END
    ELSE
    BEGIN
        PRINT 'No se actualiza (no esta en nivel 100)';
    END

    FETCH NEXT FROM db_cursor INTO @db;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Resultado final
SELECT 
    name,
    compatibility_level
FROM sys.databases
WHERE name IN ('CCenterRIA','CW_CenterScript','CCRecorderRIA','CCReportsRIA');