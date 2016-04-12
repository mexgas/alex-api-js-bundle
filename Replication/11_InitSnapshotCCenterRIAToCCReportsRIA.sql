----11

/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/30
Descripcion:
	Merge Replication (Snapshots)

Version minima requerida: 102
*/
set nocount on

use [CCenterRia]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '119'

create table #temp([version] int)
insert into #temp
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

drop table #temp

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)

	---------------- INICIO SCRIPT ----------------

	set @Sql = 'use [CCenterRia]

	IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = ''migration'')
	BEGIN
		CREATE TABLE [dbo].[migration](
		[id] [int] NOT NULL,
		[description] [varchar](255) NOT NULL,
		[status] [bit] NOT NULL,
		[error] [nvarchar](max) NOT NULL,
		[dateStart] datetime NOT NULL,
		[dateEnd] datetime NOT NULL
		) ON [PRIMARY]

		insert into migration values (100 , ''LogDials'', 0, '''', '''', '''')
		insert into migration values (101 , ''LogAgentesDia'', 0, '''', '''', '''')
		insert into migration values (102 , ''CallsOutSource'', 0, '''', '''', '''')
		insert into migration values (103 , ''CallsOut'', 0, '''', '''', '''')
		insert into migration values (104 , ''CallsIn'', 0, '''', '''', '''')
		insert into migration values (105 , ''OutIn'', 0, '''', '''', '''')
		insert into migration values (106 , ''Users'', 0, '''', '''', '''')
		insert into migration values (107 , ''Activity'', 0, '''', '''', '''')
		insert into migration values (108 , ''Catalogs'', 0, '''', '''', '''')
		insert into migration values (109 , ''LogAgentesDia_Dialog'', 0, '''', '''', '''')
		insert into migration values (110 , ''Callbacks'', 0, '''', '''', '''')
		insert into migration values (111 , ''Chats'', 0, '''', '''', '''')
		insert into migration values (112 , ''SpecialAVRS'', 0, '''', '''', '''')
		insert into migration values (113 , ''MenuReportsRia'', 0, '''', '''', '''')
		insert into migration values (114 , ''IVR'', 0, '''', '''', '''')
		insert into migration values (115 , ''ConversationMail'', 0, '''', '''', '''')
		insert into migration values (114 , ''Conversationtweet'', 0, '''', '''', '''')

	END
	ELSE BEGIN
			insert into migration values (115 , ''ConversationMail'', 0, '''', '''', '''')
			insert into migration values (116 , ''Conversationtweet'', 0, '''', '''', '''')
	END'

		EXEC(@Sql)

			set @Sql='USE [msdb]

	/****** Object:  Job [CW Merge Replication]    Script Date: 08/08/2013 07:59:24 ******/
	IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Merge Replication'')
		EXEC msdb.dbo.sp_delete_job @job_name=N''CW Merge Replication'', @delete_unused_schedule=1

	/****** Object:  Job [CW Merge Replication]    Script Date: 07/01/2013 17:49:50 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/01/2013 17:49:50 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Merge Replication'',
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
	/****** Object:  Step [replication]    Script Date: 07/01/2013 17:49:50 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Merge Replication'',
			@step_id=1,
			@cmdexec_success_code=0,
			@on_success_action=1,
			@on_success_step_id=0,
			@on_fail_action=2,
			@on_fail_step_id=0,
			@retry_attempts=0,
			@retry_interval=0,
			@os_run_priority=0, @subsystem=N''TSQL'',
			@command=N''if (select count(*) from migration  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) > 0
	begin
		declare @id int
		declare @publicationName varchar(max)

		select top 1 @id=id, @publicationName=[description] from migration  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

		if @id > 100
			begin
				declare @temp varchar(max)
				declare @jobName varchar(max)
				declare @tempId int
				set @tempId = @id -1

				select @temp = [description] from migration  with (nolock) where id = @id-1

				if (select count(*)
				from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
				where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
				and publication = @temp) = 0
				begin
					set @id = @id - 1
				end

				if (select count(*)
				from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
				where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6)
				and publication = @temp) > 0
				begin
					set @id = @id + 1
				end

				if (select [dateStart] from migration  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''')
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
		if (select [dateStart] from migration  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')
		begin
			begin transaction replications
			begin try
				update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
				update migration with (rowlock) set [dateStart] = getdate() where id = @id
				exec sp_startpublication_snapshot @publication = @publicationName
				commit transaction replications
			end try
			begin catch
				ROLLBACK TRANSACTION replications;
				update migration with (rowlock) set [dateStart] = getdate() where id = @id
				update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
				update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
			end catch
		end
	end
	if exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900''''))
			begin
				if (select count(*)
				from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
				where b.publisher_db = ''''CCenterRia''''
				and b.id = a.agent_id
				and comments like ''''%A snapshot of%%article(s) was generated.%''''
				and runstatus = 2
				and publication = ''''MenuReportsRia'''') = 1
				begin
					update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 115 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
				end
			end'',
			@database_name=N''CCenterRia'',
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

	------------------ FIN SCRIPT @Sql ------------------

	select 'Merge Snapshots Finished'
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
