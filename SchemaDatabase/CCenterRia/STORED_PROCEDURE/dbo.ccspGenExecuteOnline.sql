CREATE PROCEDURE [dbo].[ccspGenExecuteOnline]
AS
Declare @lastRun datetime
Declare @start datetime
Declare @end datetime
declare @dbname varchar(50)
declare @xSql varchar(200)
declare @server varchar(50)
if @@version like '%sql server 2008%'
begin
	select @dbname = name from sys.database_files where type =1
	set @xSql='DBCC SHRINKFILE ('+@dbName+', 1) WITH NO_INFOMSGS'
	exec (@xSql)
end
else begin
	select @dbname = db_name(dbid) from master..sysprocesses where spid=@@SPID 
	set @xSql='BACKUP LOG '+@dbName+' with truncate_only'
	exec (@xSql)
end

select @server = valor from ccSettings where setting_id = 22

-- Obtiene lastRun
select @lastRun = convert( datetime, valor, 121) from ccSettings where setting_id = 16

set @end = dateadd(mi, -5, getDate() )
IF @lastRun is null
	set @start = convert( datetime, convert( varchar(10), @end, 121) , 121)
ELSE
BEGIN
	if datepart(d, @lastRun) <> datepart(d, @end) or @lastRun > @end
		set @start = convert( datetime, convert( varchar(10), @end, 121) , 121)
	else
		set @start = @lastRun
END

--EXEC ccspGenSession @start, @end
EXEC ccspGenInCall @start, @end
EXEC ccspGenOutCall @start, @end

--EXEC ccspGenAgentStatusSepHour @start, @end
--EXEC ccspGenAgent @start, @end
--EXEC ccspGenAgentStatusSepHourNotReady @start, @end
--EXEC ccspGenAgentStatusNotReady  @start, @end
--EXEC ccspGenAgentReqTime @start

--EXEC ccspGenInSpec @start, @end
EXEC ccspGenInAbnd @start, @end
EXEC ccspGenInAnsw @start, @end
EXEC ccspGenInCalif @start, @end

--EXEC ccspGenOutCamp @start, @end
EXEC ccspGenOutCallCalif @start, @end
EXEC ccspGenOutCallDials @start, @end

EXEC ccspGenOutCstoResumen @start, @end

update ccSettings set valor = convert( varchar, @end, 121) where  setting_id = 16

select convert( varchar, @start, 121) , convert( varchar, @end, 121)

IF @server is not null and len( @server) > 0 
BEGIN
             exec ccspGenExporta @server,'ccGenInCall','timegroup',@start, @end
	exec ccspGenExporta @server,'ccGenOutCall','timegroup',@start, @end

	exec ccspGenExporta @server,'ccGenInCalif','timegroup',@start, @end
	exec ccspGenExporta @server,'ccGenInAbnd','timegroup',@start, @end
	exec ccspGenExporta @server,'ccGenInAnsw','timegroup',@start, @end
	
	exec ccspGenExporta @server,'ccGenOutCallCalif','timegroup',@start, @end
	exec ccspGenExporta @server,'ccGenOutCallDials','timegroup',@start, @end

	exec ccspGenExporta @server,'ccGenOutCstoResumen','timegroup',@start, @end

END