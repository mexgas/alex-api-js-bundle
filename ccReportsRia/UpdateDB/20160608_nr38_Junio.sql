/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 20160608
Description:

	SP ReportsMasterProcess: Se cambia para que se ejecuten la replicas de manera paulatina
Database: ccReportsRiaPara
Required version: 37

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 38

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = 'ALTER SP -- ReportsMasterProcess'
		set @Sql= 'ALTER procedure [dbo].[ReportsMasterProcess] as

set nocount on

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100), @replicationName nvarchar(100)
declare @numOfReports int,@numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int,@minReports int
DECLARE @dateBegin DATETIME,@dateSP datetime

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

set @repStrDelay = CONVERT(char(8), DATEADD(second, @repDelay, ''00:00:00''), 108)

set @dateSP = getdate()

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName


	update #replications with(rowlock) 	set flag = 1 where [name] = @replicationName

	WAITFOR DELAY ''00:00:01''

	while(
		SELECT count(*) FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) > 0
	begin
		WAITFOR DELAY ''00:00:01''
	end
end

drop table #replications

-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------

declare @descError nvarchar(max)
declare @i int,@count int
declare @name sysname,@sql nvarchar(max)



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
if @actualVersion = @version begin
	begin tran
	begin try

			set @process = 'DROP JOB -- ShrinkLogCCReportsRia'
		set @Sql= 'if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''ShrinkLogCCReportsRia'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCReportsRia'', @delete_unused_schedule=1'
		EXEC(@Sql)

		set @process = 'DROP JOB -- CW Reports Migration'
		set @Sql= 'if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Reports Migration'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Reports Migration'', @delete_unused_schedule=1'
		EXEC(@Sql)

		set @process = 'CREATE JOB -- CW Reports Migration'
		set @Sql= 'USE [msdb]
/****** Object:  Job [CW Reports Migration]    Script Date: 14/06/2016 12:35:39 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:35:39 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Reports Migration'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Reports Migration]    Script Date: 14/06/2016 12:35:39 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Reports Migration'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''
if (select [status] from migration where id = 1) = 0
begin
	if (select count(distinct publication)
	from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
	where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''') = 17
	begin
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate(), [dateEnd] = getdate() where id = 1
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id = 33

		declare @from as datetime
		declare @day as int

		select @day = valor from ccReportsRia.dbo.ccSettings where setting_id = 27
		select @from = convert(datetime,convert(varchar(11),getdate() - @day))

		BEGIN TRANSACTION ccspRepOutDialDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 2
			exec ccspRepOutDialDetail 1, @from
			COMMIT TRANSACTION ccspRepOutDialDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDialDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 2
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 2 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 3
			exec ccspRepOutCalls 1,  @from
			COMMIT TRANSACTION ccspRepOutCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 3
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 3 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentGI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 4
			exec ccspRepAgentGI 1,  @from
			COMMIT TRANSACTION ccspRepAgentGI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentGI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 4
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 4 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 5
			exec ccspRepAgentKPI 1,  @from
			COMMIT TRANSACTION ccspRepAgentKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 5
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 5 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReady;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 6
			exec ccspRepAgentNotReady 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReady;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReady;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 6
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 6 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReadyDet;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 7
			exec ccspRepAgentNotReadyDet 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReadyDet;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReadyDet;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 7
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 7 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentSession;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 8
			exec ccspRepAgentSession 1,  @from
			COMMIT TRANSACTION ccspRepAgentSession;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentSession;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 8
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 8 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInBill01900;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 9
			exec ccspRepInBill01900 1,  @from
			COMMIT TRANSACTION ccspRepInBill01900;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInBill01900;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 9
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 9 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 10
			exec ccspRepInCalls 1,  @from
			COMMIT TRANSACTION ccspRepInCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 10
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 10 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInDIDResume;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 11
			exec ccspRepInDIDResume 1,  @from
			COMMIT TRANSACTION ccspRepInDIDResume;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInDIDResume;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 11
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 11 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInEffectiveness;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 12
			exec ccspRepInEffectiveness 1,  @from
			COMMIT TRANSACTION ccspRepInEffectiveness;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInEffectiveness;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 12
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 12 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInCallsDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 13
			exec ccspRepInCallsDetail 1,  @from
			COMMIT TRANSACTION ccspRepInCallsDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInCallsDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 13
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 13 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInNotTransferred;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 14
			exec ccspRepInNotTransferred 1,  @from
			COMMIT TRANSACTION ccspRepInNotTransferred;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInNotTransferred;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 14
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 14 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInRejectedCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 15
			exec ccspRepInRejectedCalls 1,  @from
			COMMIT TRANSACTION ccspRepInRejectedCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInRejectedCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 15
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 15 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallBacks;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 16
			exec ccspRepOutCallBacks 1,  @from
			COMMIT TRANSACTION ccspRepOutCallBacks;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallBacks;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 16
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 16 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRGeneral;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 17
			exec ccspRepIVRGeneral 1,  @from
			COMMIT TRANSACTION ccspRepIVRGeneral;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRGeneral;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 17
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 17 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRByOptions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 18
			exec ccspRepIVRByOptions 1,  @from
			COMMIT TRANSACTION ccspRepIVRByOptions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRByOptions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 18
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 18 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallsDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 19
			exec ccspRepOutCallsDetail 1,  @from
			COMMIT TRANSACTION ccspRepOutCallsDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallsDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 19
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 19 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallsByTelephone;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 20
			exec ccspRepOutCallsByTelephone 1,  @from
			COMMIT TRANSACTION ccspRepOutCallsByTelephone;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallsByTelephone;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 20
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 20 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 21
			exec ccspRepIVRDetail 1,  @from
			COMMIT TRANSACTION ccspRepIVRDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 21
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 21 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutDials;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 22
			exec ccspRepOutDials 1,  @from
			COMMIT TRANSACTION ccspRepOutDials;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDials;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 22
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 22 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRFirstOption;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 23
			exec ccspRepIVRFirstOption 1,  @from
			COMMIT TRANSACTION ccspRepIVRFirstOption;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRFirstOption;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 23
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 23 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInChangeFlow;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 24
			exec ccspRepInChangeFlow 1,  @from
			COMMIT TRANSACTION ccspRepInChangeFlow;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInChangeFlow;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 24
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 24 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallBilling;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 25
			exec ccspRepOutCallBilling 1,  @from
			COMMIT TRANSACTION ccspRepOutCallBilling;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallBilling;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 25
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 25 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 26
			exec ccspRepOutDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 26
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 26 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 27
			exec ccspRepOutKPI 1,  @from
			COMMIT TRANSACTION ccspRepOutKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 27
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 27 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutSubDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 28
			exec ccspRepOutSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutSubDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutSubDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 28
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 28 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepSpecialTimes;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 29
			exec ccspRepSpecialTimes 1,  @from
			COMMIT TRANSACTION ccspRepSpecialTimes;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepSpecialTimes;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 29
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 29 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepTrunkBusy;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 30
			exec ccspRepTrunkBusy 1,  @from
			COMMIT TRANSACTION ccspRepTrunkBusy;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepTrunkBusy;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 30
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 30 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 31
			exec ccspRepInDispositions 1,  @from
			COMMIT TRANSACTION ccspRepInDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 31
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 31 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInSubDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 32
			exec ccspRepInSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepInSubDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInSubDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 32
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 32 and [error] = ''''''''

		update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id = 33
	end
end
else begin
	EXEC msdb.dbo.sp_update_job @job_name=N''''CW Reports Migration'''',@enabled = 0
end
'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''migration'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20130620,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@Sql)


		set @process = 'ALTER SP -- ccspRepIVRSurveys'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepIVRSurveys]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
  if @from is null
    select @from = convert(datetime,convert(varchar(14),getdate(),121)+ ''00'',121)
  if @to is null
    select @to = getdate()


delete RepIVRSurveys with(rowlock)
  where [date] between @from and @to


insert RepIVRSurveys select [date],userId,[login],scriptId,surveyId,survey,calId,calKey,campaignId,inboundId,campACDDescription,
questionId,questionDescription,question_Count,[Count],[year],[month],[day],[hour],[minutes]
from
(
	select distinct
	cci.cal_Inicio as [date],
	isnull(cci.User_id, 0) as ''userId'',
	isnull(ccu.Login, ''No agent'') as ''login'',
	isnull(ivro.IVR_id, 0) as ''scriptId'',
	isnull(s.surveyId, 0) as ''surveyId'',
	isnull(s.description, '') as ''survey'',
	isnull(cci.cal_id, 0) as ''calId'',
	isnull(cci.cal_Key, '') as ''calKey'',
	0 as ''campaignId'',
	isnull(cci.Inbound_id, '') as ''inboundId'',
	''ACD - '' + isnull(ccin.descripcion,'') as ''campACDDescription'',
	isnull(ivro.questionId, 0) as ''questionId'',
	isnull(sq.description,'') as ''questionDescription'',
	isnull(sq.description,'')+ ''_UnCount'' as ''question_Count'',
	case when ivro.selectedOption = '' then ''systemTranslated_No_Option''
	when rqa.questionId is null then ivro.selectedOption
	when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description
	else ''systemTranslated_Invalid'' end as ''Count'',
	datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
	datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
	datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
	datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
	datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
	,rsq.orden
	from ccCallsIn cci with(nolock)
	inner join IVROptions ivro on cci.IVR_id = ivro.IVR_id and ivro.cal_id = cci.cal_id
	inner join ccUsers ccu on cci.User_id = ccu.User_id
	inner join Survey s on ivro.surveyId = s.surveyId
	inner join ccInbound ccin on cci.Inbound_id = ccin.Inbound_id
	inner join SurveyQuestion sq on ivro.questionId = sq.questionId
	inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
	left join SurveyAnswer sa on convert(varchar(5),sa.digit) = ivro.selectedOption
	left join relationQuestionAnswer rqa on rsq.surveyId = rqa.surveyId and rqa.questionId = rsq.questionId
	where cal_inicio between @from and @to

  union all

  select distinct
	cco.cal_Inicio as [date],cco.User_id as ''userId'',
	isnull(ccu.Login, ''No agent'') as ''login'',
	isnull(ivro.IVR_id, 0) as ''scriptId'',
	isnull(s.surveyId, 0) as ''surveyId'',
	isnull(s.description, '') as ''survey'',
	isnull(cco.cal_id, 0) as ''calId'',
	isnull(cco.cal_Key, '') as ''calKey'',
	isnull(ccc.[cam_id], '') as ''campaignId'',
	0 as ''inboundId'',
	''Camp - '' + isnull(ccc.[cam_descripcion],'') as ''campACDDescription'',
	isnull(ivro.questionId, 0) as ''questionId'',
	isnull(sq.description,'') as ''questionDescription'',
	isnull(sq.description,'')+ ''_UnCount' as 'question_Count'',
	case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
	when rqa.questionId is null then ivro.selectedOption
	when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description
	else ''systemTranslated_Invalid'' end as ''Count'',
		datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
	datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
	datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
	datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
	datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
	,rsq.orden
	from ccoCallsOut cco
	inner join IVROptions ivro on cco.cal_id = ivro.cal_id
	inner join ccUsers ccu on cco.User_id = ccu.User_id
	inner join Survey s on ivro.surveyId = s.surveyId
	inner join ccCamps ccc on cco.cam_id = ccc.cam_id
	inner join SurveyQuestion sq on ivro.questionId = sq.questionId
	inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
	left join SurveyAnswer sa on convert(varchar(5),sa.digit) = ivro.selectedOption
	left join relationQuestionAnswer rqa on rsq.surveyId = rqa.surveyId and rqa.questionId = rsq.questionId --and rqa.answerId = sa.answerId
	where cal_inicio between @from and @to

)surveys
order by calId,orden
end'

		EXEC(@Sql)
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