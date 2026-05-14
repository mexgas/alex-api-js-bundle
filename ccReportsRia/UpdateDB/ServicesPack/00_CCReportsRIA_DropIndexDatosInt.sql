

/*
    Objetivo:
    - dbo.ccoCallsOut: columnas cal_tNotas, cal_tXfer, cal_tRing, cal_tDialog
    - dbo.ccCallsIn:   columnas cal_tNotas, cal_tXfer, cal_tRing, cal_tDialog
    - dbo.ccLogAgentesDia: columna tStatus

    Regla:
    - Solo actuar si la columna es tipo INT.
    - Si el índice ya existe, se elimina y se vuelve a crear.
*/

USE CCReportsRIA;
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
        t.name IN ('RepOutCallsDetail')
        AND c.name IN ('iva')
      )
   OR (
        t.name = 'RepOutAnswAndXferCalls'
        AND c.name = 'dialTimeSec'
      );
GO

DECLARE @sql nvarchar(MAX) = N'';

;WITH TargetColumns AS
(
    SELECT 'dbo' AS SchemaName, 'RepOutCallsDetail' AS TableName, 'iva'  AS ColumnName UNION ALL
    SELECT 'dbo', 'RepOutAnswAndXferCalls', 'dialTimeSec'
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
    
)
SELECT @sql = @sql + 
    N'DROP INDEX ' + QUOTENAME(IndexName) + 
    N' ON ' + QUOTENAME(SchemaName) + N'.' + QUOTENAME(TableName) + N';' + CHAR(13)
FROM IndexesToDrop;

PRINT @sql;

-- Ejecutar solo después de revisar el PRINT
EXEC sys.sp_executesql @sql;

GO