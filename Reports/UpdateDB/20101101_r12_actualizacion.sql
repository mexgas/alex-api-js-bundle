/*
Autor: Armando Rodriguez
Fecha: 2010/00/00
Descripcion: Actualizacion de querys para corregir problema con la transferencia de info de las tablas
Version requerida: 11
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '12'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exp_jobs set readquery =''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @fec1 as varchar(20)
select @fec1 = isnull(max(callout_id),0) from '''' + @server +''''.dbo.ccocallsoutsource WITH(NOLOCK)
''''
set @sql = @sql + ''''select callout_id,cal_key,cam_id,cal_fechaDial, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, Dato1, Dato2, Dato3, Dato4, Dato5 from ccoCallsOutSource WITH(NOLOCK) where callout_id > @fec1 AND cal_fechadial < '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'' where description = ''ccocallsoutsource'''
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccRIAAreaWorkGroup
	DROP CONSTRAINT FK_ccRIAAreas_IDArea'
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


