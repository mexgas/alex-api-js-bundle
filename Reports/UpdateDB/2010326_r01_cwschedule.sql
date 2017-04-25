/*
Autor: Armando Rodriguez
Fecha: 2010/03/25
Descripcion: Script de querys que cambiaron para el cwschedule para que corra bien y para agregar el campo del iva a la tabla ccsetings de ccReports
Version requerida: 0
*/
set nocount on
if (select valor from ccSettings where setting_id = 24) = '2.0'
	update ccsettings set valor = '0.0' where setting_id = 24

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '1'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(8000)
---------------- inicio SCRIPT @Sql ----------------

 		set @Sql='insert into ccsettings (setting_id,valor,descripcion,status,tipo) values (25,''16'',''Iva'',1,''RPT'')'
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCallCalif @start, @end
select * from ccGenOutCallCalif where timegroup >= @start and timegroup < @end'', writequery = ''ccGenOutCallCalif'' where description = ''ccspGenOutCallCalif'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCallDials @start, @end
select * from ccGenOutCallDials where timegroup >= @start and timegroup < @end'', writequery = ''ccGenOutCallDials'' where description = ''ccspGenOutCallDials'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCstoResumen @start, @end
select * from ccGenOutCstoResumen where timegroup >= @start and timegroup < @end'', writequery = ''ccGenOutCstoResumen'' where description = ''ccspGenOutCstoResumen'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCamp @start, @end
select * from ccGenOutCamp where timegroup >= @start and timegroup < @end'', writequery = ''ccGenOutCamp'' where description = ''ccspGenOutCamp'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInCalif @start, @end
select * from ccGenInCalif where timegroup >= @start and timegroup < @end'', writequery = ''ccGenInCalif'' where description = ''ccspGenInCalif'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInAnsw @start, @end
select * from ccGenInAnsw where timegroup >= @start and timegroup < @end'', writequery = ''ccGenInAnsw'' where description = ''ccspGenInAnsw'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInAbnd @start, @end
select * from ccGenInAbnd where timegroup >= @start and timegroup < @end'', writequery = ''ccGenInAbnd'' where description = ''ccspGenInAbnd'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInSpec @start, @end
select * from ccGenInSpec where timegroup >= @start and timegroup < @end'', writequery = ''ccGenInSpec'' where description = ''ccspGenInSpec'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenAgentStatusNotReady @start, @end
select * from ccGenAgentNotReady where timegroup >= @start and timegroup < @end'', writequery = ''ccGenAgentNotReady'' where description = ''ccspGenAgentStatusNotReady'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenAgent @start, @end
select * from ccGenAgent where timegroup >= @start and timegroup < @end'', writequery = ''ccGenAgent'' where description = ''ccspGenAgent'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCall @start, @end
select * from ccGenOutCall where timegroup >= @start and timegroup < @end'', writequery = ''ccGenOutCall'' where description = ''ccspGenOutCall'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInCallDNI @start, @end
select * from ccGenInCallDNI where timegroup >= @start and timegroup < @end'', writequery = ''ccGenInCallDNI'' where description = ''ccspGenInCallDNI'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInCall @start, @end
select * from ccgenincall where timegroup >= @start and timegroup < @end'', writequery = ''ccGenInCall'' where description = ''ccspGenInCall'''
	EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenSession @start, @end
select * from ccgensession where login >= @start and login < @end'', writequery = ''ccGenSession'' where description = ''ccspGenSession'''
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


