CREATE PROCEDURE [dbo].[trsp_OrganizeIndexes]
AS

set nocount on;

DECLARE @porcentaje float,@nombre nvarchar(100);

DECLARE IndexCursor CURSOR FOR 
SELECT name,avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID(N'dbo.RIA_GRABACION'),
NULL, NULL, NULL) AS a JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;

DECLARE IndexCursor2 CURSOR FOR 
SELECT name,avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID(N'dbo.RIA_GRABACIONCONSULTA'),
NULL, NULL, NULL) AS a JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;


OPEN IndexCursor;

FETCH NEXT FROM IndexCursor INTO @nombre, @porcentaje;

WHILE @@FETCH_STATUS = 0
BEGIN 
  IF @porcentaje > 5 and @porcentaje <= 30
	BEGIN
	 exec('ALTER INDEX '+ @nombre + ' ON dbo.RIA_GRABACION REORGANIZE');
	END
  IF @porcentaje > 30
	BEGIN
	 exec('ALTER INDEX '+ @nombre + ' ON dbo.RIA_GRABACION REBUILD');
	END
   FETCH NEXT FROM IndexCursor INTO @nombre,@porcentaje;
END
CLOSE IndexCursor;
DEALLOCATE IndexCursor;

OPEN IndexCursor2;

FETCH NEXT FROM IndexCursor2 INTO @nombre, @porcentaje;

WHILE @@FETCH_STATUS = 0
BEGIN 
  IF @porcentaje > 5 and @porcentaje <= 30
	BEGIN
	  exec ('ALTER INDEX '+ @nombre +' ON dbo.RIA_GRABACIONCONSULTA REORGANIZE');
	END
  IF @porcentaje > 30
	BEGIN
	 exec ('ALTER INDEX '+ @nombre + ' ON dbo.RIA_GRABACIONCONSULTA REBUILD');
	END
   FETCH NEXT FROM IndexCursor2 INTO @nombre,@porcentaje;
END
CLOSE IndexCursor2;
DEALLOCATE IndexCursor2;

SELECT name,avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID(N'dbo.RIA_GRABACION'),
NULL, NULL, NULL) AS a JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id
UNION
SELECT name,avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID(N'dbo.RIA_GRABACIONCONSULTA'),
NULL, NULL, NULL) AS a JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;