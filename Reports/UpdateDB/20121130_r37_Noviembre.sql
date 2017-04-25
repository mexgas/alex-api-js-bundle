/*
Autor: Raymundo González
Fecha: 2012/11/30
Descripcion: 
	Se inserta la columna surveyCamId en la tabla ccCamps
	Se insertan nuevos campos en la tabla de exportación

Version requerida: 36
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '37'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @Sql='ALTER TABLE dbo.ccCamps 
ADD surveyCamId int default 0'
	
	EXEC(@Sql)

		set @Sql = 'DECLARE @var1 varchar(max)
DECLARE @var2 varchar(max)

SELECT @var1 = cols + '',surveyCamId'' FROM exportReports WHERE jobId = 203
SELECT @var2 = cols + '',surveyCamId'' FROM exportReports WHERE jobId = 204

UPDATE exportReports SET cols = @var1 WHERE jobId = 203
UPDATE exportReports SET cols = @var2 WHERE jobId = 204'

	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
