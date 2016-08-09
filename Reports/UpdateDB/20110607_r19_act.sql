/*
Autor: Armando Rodriguez
Fecha: 2011/06/14
Descripcion: Actualizacion de tablas ccuser y ccinbound
Version requerida: 18
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '19'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenSession @start, @end'' where description = ''ccspGenSession''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenInCall @start, @end'' where description = ''ccspGenInCall''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenInCallDNI @start, @end'' where description = ''ccspGenInCallDNI''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenOutCall @start, @end'' where description = ''ccspGenOutCall''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenAgent @start, @end'' where description = ''ccspGenAgent''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenAgentStatusNotReady @start, @end'' where description = ''ccspGenAgentStatusNotReady''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenInSpec @start, @end'' where description = ''ccspGenInSpec''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenInAbnd @start, @end'' where description = ''ccspGenInAbnd''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenInAnsw @start, @end'' where description = ''ccspGenInAnsw''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenInCalif @start, @end'' where description = ''ccspGenInCalif''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenOutCamp @start, @end'' where description = ''ccspGenOutCamp''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenOutCallCalif @start, @end'' where description = ''ccspGenOutCallCalif''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenOutCallDials @start, @end'' where description = ''ccspGenOutCallDials''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenOutCstoResumen @start, @end'' where description = ''ccspGenOutCstoResumen''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenAgentStatusSepHour @start, @end'' where description = ''ccspGenAgentStatusSepHour''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)   EXEC ccspGenAgentStatusSepHourNotReady @start, @end'' where description = ''ccspGenAgentStatusSepHourNotReady''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime    set @end = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)   set @start = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)   EXEC ccspGenTelMarcados @start, @end'' where description = ''ccspGenTelMarcados''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenInCallWG @start, @end'' where description = ''ccspGenInCallWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenInSpecWG @start, @end'' where description = ''ccspGenInSpecWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenInAbndWG @start, @end'' where description = ''ccspGenInAbndWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenInAnswWG @start, @end'' where description = ''ccspGenInAnswWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenInCalifWG @start, @end'' where description = ''ccspGenInCalifWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenOutCallWG @start, @end'' where description = ''ccspGenOutCallWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''''00:00:00'''',121)   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenOutCampWG @start, @end'' where description = ''ccGenOutCampWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenOutCallCalifWG @start, @end'' where description = ''ccGenOutCallCalifWG''
update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime   set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121))   set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121)     EXEC ccspGenOutCallDialsWG @start, @end'' where description = ''ccGenOutCallDialsWG''
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


