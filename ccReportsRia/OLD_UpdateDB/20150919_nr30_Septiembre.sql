/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2015/10/19
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara 
Required version: 29

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 30

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process = 'alter SP -- ReportsMasterProcess'
	set @Sql= 'ALTER procedure [dbo].[ReportsMasterProcess] as

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100), @replicationName nvarchar(100)
declare @numOfReports int,@numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int,@minReports int

---shedule
declare @schedule_id int,@nameSchudule sysname,@job_id uniqueidentifier,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

--------------------------- Creacion tablas cada domingo ---------------------------
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = ''logsReportsMaster'')
			drop table logsReportsMaster

	create table [logsReportsMaster](
		[id] int identity not null primary key,
		[name] varchar(100) not null,
		[status] tinyint not null,
		[dateStart] datetime not null,
		[dateEnd] datetime not null,
		[error] varchar(max) not null,
		[maxTime] int not null)

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster1] ON [dbo].[logsReportsMaster]
	(
		[name] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster2] ON [dbo].[logsReportsMaster]
	(
	[status] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster3] ON [dbo].[logsReportsMaster]
	(
	[maxTime] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

end

--------------------------- Termina Creacion tablas cada domingo ---------------------------

set nocount on

set @dateStart = getdate()
set @delay = 0
set @strDelay = ''''
set @reportName = ''''
set @replicationName = ''''
set @numOfReports = 0
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 0
set @minReports = 0
set @scheduleTime = 10

--- obtiene el job_id, y el nombre del schedule_id asocioado al job reports Master
select  @job_id=A.job_id,@schedule_id=C.schedule_id, @nameSchudule=C.name,@scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcess''

-- obtiene los valores de los settings para el tiempo ejecucion de las replicas  y los jobs
select @minReplication = cast(substring(valor, 0, charindex(''|'',valor)) as int) from ccsettings where setting_id = 28
select @minReports = cast(substring(valor, charindex(''|'',valor) + 1, len(valor)) as int) from ccsettings where setting_id = 28

---- revisar los tiempos y actulizar el setting
if (@minReplication + @minReports) > @scheduleTime
begin
	set @scheduleTime= @minReplication + @minReports
	EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
end

set @minReplication = @minReplication * 60

-------------------- ejecuccion de las replicas -----------------------------------------

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCenterRia%''

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCRecorderRia%'' order by [name]

select @numOfReplications = count(*) from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = CONVERT(char(8), DATEADD(second, @repDelay, ''0:00:00''), 108) 

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock)
	set flag = 1
	where [name] = @replicationName

	waitfor delay @repStrDelay
end

drop table #replications

-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------

declare @descError nvarchar(max)
declare @i int,@count int
declare @name sysname,@sql nvarchar(max)
DECLARE @dateBegin DATETIME,@dateSP datetime


create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] <> ''ccspRepCatalogos''

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count
begin
	select @name = name from #tmpProcedureReports where id=@i

	set @sql =''EXEC ''+ @name +'' @action=1''
	set @dateSP = getdate()
	begin try

		exec (@sql)
		WAITFOR DELAY ''00:00:01''

		while(SELECT count(*)
			FROM sys.dm_exec_requests a
			INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
			INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d WHERE a.session_id > 50
			AND a.session_id = @@SPID and d.text = @sql) > 0
		begin
			WAITFOR DELAY ''00:00:01''
		end

		if( datediff(mi,@dateStart,getdate()) > @scheduleTime) begin
		set @scheduleTime = @scheduleTime+1
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime,error=''Increment time shuduler ''+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart=''19000101'' and dateEnd=''19000101''

			set @minReplication=@minReplication/60
			EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
			update ccsettings set valor=convert(varchar(max),@minReplication)+''|''+convert(varchar(max),@minReports+1),descripcion = ''Min. replicas | Min. reportes este se modifica automaticamente revisar tabla de logsReportsMaster, (Total ''+convert(varchar(max),@scheduleTime) +'' Minutos)'' where setting_id = 28
			break
		end
		set @i = @i+1
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
	end try
	begin catch
		select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
		set @i = @i+1
	end catch
end

drop table #tmpProcedureReports

-------------------- Reinicializa las subcripciones en caso de caducar-----------------------------------------

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where mh.comments like ''%You must reinitialize the subscription (without upload)%''
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''ccReportsRia''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@Sql)

	
			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off