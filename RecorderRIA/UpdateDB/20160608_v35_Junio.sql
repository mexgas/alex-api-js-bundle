/*
Autor: Jose Velasco
Fecha: 2014/10/06
Descripcion:

	SP ReportsMasterProcessAVRS: Se cambia para que se ejecuten la replicas de manera paulatina
Version requerida: 34
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 35
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

---------------- inicio SCRIPT @Sql ----------------

	set @process = 'ALTER SP --ReportsMasterProcessAVRS'
	set @Sql='ALTER procedure [dbo].[ReportsMasterProcessAVRS] as

declare @dateStart datetime
declare @replicationName nvarchar(100)
declare @numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int

set nocount on

set @dateStart = getdate()
set @replicationName = ''''
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 600

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%CCRecorderRIA- 0%'' and [name] like ''%CCenterRia%'' order by [name]

select @numOfReplications = count(*)
from #replications with(nolock)

--set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

--set @repStrDelay =CONVERT(char(8), DATEADD(second, @repDelay, ''0:00:00''), 108)

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

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

	--waitfor delay @repStrDelay
end

drop table #replications

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
and ma.subscriber_db = ''CCRecorderRIA''
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

------------------ fin SCRIPT @Sql ------------------

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
if @Version_Actual = @Version begin
begin tran
	begin try
---------------- inicio SCRIPT @Sql ----------------
	set @process = 'DROP JOB -- Shrink-IndexOptimizationRIA'
	set @Sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''Shrink-IndexOptimizationRIA'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''Shrink-IndexOptimizationRIA'', @delete_unused_schedule=1'
	EXEC(@Sql)

	set @process = 'DROP JOB -- Shrink-IndexOptimization'
	set @Sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''Shrink-IndexOptimization'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''Shrink-IndexOptimization'', @delete_unused_schedule=1'
	EXEC(@Sql)

	set @process = 'DROP JOB -- TrucateTransactionLog'
	set @Sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''TrucateTransactionLog'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''TrucateTransactionLog'', @delete_unused_schedule=1'
	EXEC(@Sql)

	set @process = 'DROP JOB -- AVRSReports Merge Replication'
	set @Sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''AVRSReports Merge Replication'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''AVRSReports Merge Replication'', @delete_unused_schedule=1'
	EXEC(@Sql)

	set @process = ''
	set @Sql=''
	EXEC(@Sql)

	set @process = ''
	set @Sql='USE [msdb]
/****** Object:  Job [AVRSReports Merge Replication]    Script Date: 14/06/2016 12:30:38 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:30:38 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRSReports Merge Replication'',
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
/****** Object:  Step [AVRSReports Merge Replication]    Script Date: 14/06/2016 12:30:38 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''AVRSReports Merge Replication'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''if (select count(*) from MigrationAVRSReports  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) > 0
begin
	declare @id int
	declare @publicationName varchar(max)

	select top 1 @id=id, @publicationName=[description] from MigrationAVRSReports  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

	if @id > 100
		begin
			declare @temp varchar(max)
			declare @jobName varchar(max)
			declare @tempId int
			set @tempId = @id -1

			select @temp = [description] from MigrationAVRSReports  with (nolock) where id = @id-1

			if (select count(*)
			from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCRecorderRIA'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
			and publication = @temp) = 0
			begin
				set @id = @id - 1
			end

			if (select count(*)
			from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCRecorderRIA'''' and runstatus in (5,6)
			and publication = @temp) > 0
			begin
				set @id = @id + 1
			end

			if (select [dateStart] from MigrationAVRSReports  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''')
			begin
				if exists(select *
						  from distribution..MSreplication_monitordata
						  where publication = @temp
						  and agent_type = 1
						  and [status] = 0)
					begin
						select @jobName = agent_name
						from distribution..MSreplication_monitordata
						where publication = @temp
						and agent_type = 1
						and [status] = 0

						create table #jobActivity(
						session_id int null,
						job_id uniqueidentifier null,
						job_name sysname null,
						run_requested_date datetime null,
						run_requested_source sysname null,
						queued_date datetime null,
						start_execution_date datetime null,
						last_executed_step_id int null,
						last_exectued_step_date datetime null,
						stop_execution_date datetime null,
						next_scheduled_run_date datetime null,
						job_history_id int null,
						[message] nvarchar(1024) null,
						run_status int null,
						operator_id_emailed int null,
						operator_id_netsent int null,
						operator_id_paged int null
						)

						insert into #jobActivity
							exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

						if (select start_execution_date from #jobActivity) is null
							begin
								exec sp_startpublication_snapshot @publication = @temp
							end

						drop table #jobActivity
					end
			end
		end
	if (select [dateStart] from MigrationAVRSReports  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')
	begin
		begin transaction replications
		begin try
			update MigrationAVRSReports with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
			update MigrationAVRSReports with (rowlock) set [dateStart] = getdate() where id = @id
			exec sp_startpublication_snapshot @publication = @publicationName
			commit transaction replications
		end try
		begin catch
			ROLLBACK TRANSACTION replications;
			update MigrationAVRSReports with (rowlock) set [dateStart] = getdate() where id = @id
			update MigrationAVRSReports with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
			update MigrationAVRSReports with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
		end catch
	end
end
if exists (select * from MigrationAVRSReports where id = 102 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900''''))
		begin
			if (select count(*)
			from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCRecorderRIA''''
			and b.id = a.agent_id
			and comments like ''''%A snapshot of%%article(s) was generated.%''''
			and runstatus = 2
			and publication = ''''AVRSRecordings'''') = 1
			begin
				update MigrationAVRSReports with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 102 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
			end
end
if not exists (select * from MigrationAVRSReports where id = 102 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900''''))
	EXEC msdb.dbo.sp_update_job @job_name=N''''AVRSReports Merge Replication'''',@enabled = 0'',
		@database_name=N''CCRecorderRIA'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20130625,
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

------------------ fin SCRIPT @Sql ------------------
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