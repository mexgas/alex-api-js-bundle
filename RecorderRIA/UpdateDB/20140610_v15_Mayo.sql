/*
Fecha: 2014/05/12
Descripcion: 	
	Se pone rol dbwoner al sa si este es diferente

Version requerida: 14
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 15
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'update -- dbowner DATABASE'
	set @Sql='if not exists (select * from sys.databases where suser_sname(owner_sid)=''sa'' and name=''CCRecorderRIA'') ALTER AUTHORIZATION ON DATABASE::CCRecorderRIA TO sa 	'

	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
	--Generamos nueva version
	--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 	update trec_parametros set par_valor = @Version where par_id = 30 

	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
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