/*
Autor: Armando Rodriguez
Fecha: 2011/05/29
Descripcion: Actualizacion de tablas ccuser y ccinbound
Version requerida: 17
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '18'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='alter table ccUsers alter column Nombres varchar(45) NOT NULL
alter table ccUsers alter column ApellidoPaterno varchar(35) NOT NULL
alter table ccUsers alter column ApellidoMaterno varchar(35) NULL
alter table ccInbound alter column voicePath varchar(30)'
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


