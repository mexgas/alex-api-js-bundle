/*
Autor: Raymundo Gonzalez
Fecha: 2013/02/28
Descripcion: 
	Se actualiza la tabla ccoLogDials agregando la columna disconnectCause para almacenar la causa de desconexion de la llamada
	Se actualiza la tabla exportReports para agregar la columna disconnectCause de la tabla ccoLogDials
	
Version requerida: 41
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '42'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		set @process = 'ccoLogDials - Alter Table'
		set @Sql='alter table ccoLogDials add disconnectCause varchar(250) not null default '''''

	EXEC(@Sql)

		set @process = 'exportReports - Update'
		set @Sql='update exportReports 
set cols=''logDial_id,callout_id,cam_id,tipoResDial_id,Telefono,Puerto,fecha,tDialing,tBusy,answerbit,canceledNoAgents,cal_id,disconnectCause'' 
where jobid=3'

	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

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
