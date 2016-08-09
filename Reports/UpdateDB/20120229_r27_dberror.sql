/*
Autor: Armando Rodriguez
Fecha: 2011/03/02
Descripcion: cambia tablas de ccocallsout, ccocallsoutsource y ccologdials
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '27'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER TABLE dbo.ccoCallsOut
	alter column cal_telefono varchar(30) NOT NULL'
	EXEC(@Sql)

 	set @Sql='DROP INDEX ccoCallsOutSource.IX_ccoCallsOutSource_5'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccoCallsOutSource
	alter column cal_fechaDial datetime NOT NULL'
	EXEC(@Sql)

 	set @Sql='CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_5 ON dbo.ccoCallsOutSource
	(
	cal_fechaDial DESC
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccoLogDials
	alter column Telefono varchar(30) NOT NULL'
	EXEC(@Sql)

 	set @Sql=''
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


