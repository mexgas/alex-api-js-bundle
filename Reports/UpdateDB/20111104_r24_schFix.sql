/*
Autor: Mauricio perez
Fecha: 2011/11/04
Descripcion: 
	Correccion en script de job_id 44 de schedule (short calls)
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '24'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exp_jobs set ReadQuery = ''declare @server varchar(200), @sql varchar(8000)
declare @from datetime, @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calIni as varchar(15)
declare @calfin as varchar(15)
select @calIni = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccCallsReject 
select @calfin = min(cal_id) from (select isnull(min(cal_id),0) cal_id from ccCallsReject 
where cal_inicio > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccCallsReject as a where cal_id <> 0) as x ''''

set @sql = nchar(13) + @sql + '''' select cal_id, ani, dnis, puerto, cal_inicio Inbound_id from ccCallsReject WHERE cal_id > @calIni and cal_id<= @calfin''''

--print @sql
exec(@sql)'' 
where job_id = 44'
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


