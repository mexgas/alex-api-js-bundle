/*
Autor: Armando Rodriguez
Fecha: 2010/00/00
Descripcion: Actualizacion de querys para correr todo desde los registros
Version requerida: 12
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '13'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @Sql='alter table ccGenOutCallDialsWG alter column amount int'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[telefonosTransferencia](
	[nombre] [varchar](50) NULL,
	[tel] [varchar](50) NULL
) ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[telefonosConferencia](
	[nombre] [varchar](50) NULL,
	[tel] [varchar](50) NULL
) ON [PRIMARY]
'
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


