/*
Autor: Armando Rodriguez
Fecha: 2011/03/30
Descripcion: se agrega la columna cal_whohug a los jos de callsin y callsout para que la informacion se muestre correctamente.
Version requerida: 15
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '16'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exp_jobs set readquery = ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calIni as varchar(15)
declare @calfin as varchar(15)
select @calIni = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccocallsout WITH(NOLOCK)
select @calfin = min(cal_id) from ( select isnull(min(cal_id),0) cal_id from ccocallsout with(index (IX_ccoCallsOut_2),NOLOCK) where cal_inicio > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccocallsout WITH(NOLOCK)) as a where cal_id <> 0
''''
set @sql = @sql + ''''select cal_id,callout_id, cal_telefono, cal_puerto,cam_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,cal_tlinebusy,costo,provedor_id,tipollamada_id, cal_tMoh, cal_whoHung from ccocallsout WITH(NOLOCK) WHERE cal_id > @calIni and cal_id<= @calfin''''
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'' where description = ''ccocallsout'''
	EXEC(@Sql)

 	set @Sql='update exp_jobs set readquery = ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calInii as varchar(15)
declare @calfini as varchar(15)
select @calInii = isnull(max(cal_id),1) from '''' + @server +''''.dbo.cccallsin  WITH(NOLOCK)
select @calfini = min(cal_id) from (select isnull(min(cal_id),0) cal_id from cccallsin with(index (IX_ccCallsIn),NOLOCK) where cal_inicio > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccCallsIn WITH(NOLOCK)) as a where cal_id <> 0
''''
set @sql = @sql + ''''select cal_id,dni_id, cal_ani, cal_puerto,inbound_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_twait,cal_txfer,cal_tcall,cal_tring,cal_xfer,cal_inicio,cal_opciones,cal_origin_id, cal_tMoh, cal_whoHung from cccallsin WITH(NOLOCK) WHERE cal_id > @calInii and cal_id<= @calfini''''
--print @sql
exec(@sql)

--exec ccsp_LogInfo @sql, -19'' where description = ''cccallsin'''
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


