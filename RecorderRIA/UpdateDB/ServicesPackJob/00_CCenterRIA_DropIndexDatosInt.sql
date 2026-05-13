

/*
    Objetivo:
    - dbo.ccoCallsOut: columnas cal_tNotas, cal_tXfer, cal_tRing, cal_tDialog
    - dbo.ccCallsIn:   columnas cal_tNotas, cal_tXfer, cal_tRing, cal_tDialog
    - dbo.ccLogAgentesDia: columna tStatus

    Regla:
    - Solo actuar si la columna es tipo INT.
    - Si el índice ya existe, se elimina y se vuelve a crear.
*/

USE CCenterRIA;
GO

SET NOCOUNT ON;

------------------------------------------------------------
-- 1. Validar tipos de datos
------------------------------------------------------------

SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length,
    c.precision,
    c.scale
FROM sys.tables t
INNER JOIN sys.schemas s 
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c 
    ON c.object_id = t.object_id
INNER JOIN sys.types ty 
    ON ty.user_type_id = c.user_type_id
WHERE s.name = 'dbo'
  AND (
        t.name IN ('ccoCallsOut', 'ccCallsIn')
        AND c.name IN ('cal_tNotas', 'cal_tXfer', 'cal_tRing', 'cal_tDialog')
      )
   OR (
        t.name = 'ccLogAgentesDia'
        AND c.name = 'tStatus'
      );
GO

DECLARE @sql nvarchar(MAX) = N'';

;WITH TargetColumns AS
(
    SELECT 'dbo' AS SchemaName, 'ccoCallsOut' AS TableName, 'cal_tNotas'  AS ColumnName UNION ALL
    SELECT 'dbo', 'ccoCallsOut', 'cal_tXfer'   UNION ALL
    SELECT 'dbo', 'ccoCallsOut', 'cal_tRing'   UNION ALL
    SELECT 'dbo', 'ccoCallsOut', 'cal_tDialog' UNION ALL

    SELECT 'dbo', 'ccCallsIn', 'cal_tNotas'    UNION ALL
    SELECT 'dbo', 'ccCallsIn', 'cal_tXfer'     UNION ALL
    SELECT 'dbo', 'ccCallsIn', 'cal_tRing'     UNION ALL
    SELECT 'dbo', 'ccCallsIn', 'cal_tDialog'   UNION ALL

    SELECT 'dbo', 'ccLogAgentesDia', 'tStatus'
),
IndexesToDrop AS
(
    SELECT DISTINCT
        s.name AS SchemaName,
        t.name AS TableName,
        i.name AS IndexName
    FROM sys.indexes i
    INNER JOIN sys.tables t
        ON t.object_id = i.object_id
    INNER JOIN sys.schemas s
        ON s.schema_id = t.schema_id
    INNER JOIN sys.index_columns ic
        ON ic.object_id = i.object_id
       AND ic.index_id = i.index_id
    INNER JOIN sys.columns c
        ON c.object_id = ic.object_id
       AND c.column_id = ic.column_id
    INNER JOIN sys.types ty
        ON ty.user_type_id = c.user_type_id
    INNER JOIN TargetColumns tc
        ON tc.SchemaName = s.name
       AND tc.TableName = t.name
       AND tc.ColumnName = c.name
    WHERE i.is_primary_key = 0
      AND i.is_unique_constraint = 0
      AND i.type_desc IN ('CLUSTERED', 'NONCLUSTERED')
      AND ty.name = 'int'
)
SELECT @sql = @sql + 
    N'DROP INDEX ' + QUOTENAME(IndexName) + 
    N' ON ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N';' + CHAR(13)
FROM IndexesToDrop;

PRINT @sql;

-- Ejecutar solo después de revisar el PRINT
EXEC sys.sp_executesql @sql;


IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.ccLogAgentesDia')
      AND name = N'IX_ccLogAgentesDia_6'
)
AND EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.types ty 
        ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'dbo.ccLogAgentesDia')
      AND c.name = N'tStatus'
      AND ty.name = N'int'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ccLogAgentesDia_6] 
    ON [dbo].[ccLogAgentesDia]
    (
        [User_id] ASC,
        [TipoStatusAge_id] ASC,
        [fecha] ASC,
        [tStatus] ASC
    );
END;
GO