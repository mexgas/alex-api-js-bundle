SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 99

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-4991 Verifica que el stored procedure no exista (ReportsMasterSubProcess)'
		SET @sql = '
			IF EXISTS (SELECT * FROM sys.procedures WHERE NAME = N''ReportsMasterSubProcess'')
			BEGIN
				DROP PROCEDURE ReportsMasterSubProcess
			END
		'
		EXEC(@sql)


		SET @process = 'CW-4991 Se agrega un nuevo Store Procedure llamado ReportsMasterSubProcess para la generacion exclusiva de los reportes'
		SET @sql = '
			CREATE PROCEDURE [dbo].[ReportsMasterSubProcess]
				--@from as DATETIME=NULL,
				--@to as DATETIME=NULL,
				--@dateStart DATETIME=NULL,
				--@scheduleTime int=NULL
			AS

			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

				DECLARE @from DATETIME = NULL
				DECLARE	@to DATETIME = NULL
				DECLARE @dateStart DATETIME = NULL
				DECLARE @scheduleTime int = 10


				-- Insert statements for procedure here
				PRINT ''--------------------------- Creacion tablas cada domingo ---------------------------''

				DECLARE @isSunday TINYINT,  @hourSunday TINYINT,@minSunday TINYINT

				SELECT @isSunday = DATEPART(dw, GETDATE()),@hourSunday = DATEPART(hh, getdate()), @minSunday = DATEPART(mi, GETDATE())

				IF @isSunday=1 AND @hourSunday = 3 AND @minSunday>=30 
	
				BEGIN

					IF EXISTS (SELECT * FROM sys.tables WHERE name = ''logsReportsMaster'') 
					BEGIN
						DROP TABLE logsReportsMaster
					END

					CREATE TABLE [logsReportsMaster](
						[id] INT IDENTITY not null PRIMARY KEY,
						[name] VARCHAR(100) not null,
						[status] TINYINT not null,
						[dateStart] DATETIME not null,
						[dateEnd] DATETIME not null,
						[error] VARCHAR(max) not null,
						[maxTime] INT not null)

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

				END

				PRINT ''--------------------------- Termina Creacion tablas cada domingo ---------------------------''

				PRINT ''EXEC ReportsMasterProcessWIthOnlyGenerate @from=''+CAST(@from as varchar)+'',@to=''+CAST(@to as varchar)+'',@scheduleTime=''+CAST(@scheduleTime as varchar)+'',@dateStart=''+CAST(@dateStart as varchar)

				EXEC ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=@scheduleTime,@dateStart=@dateStart	

			END
		'
		EXEC(@sql)



		SET @process = 'CW-4991 Se modifica el StoreProcedure de ReportsMasterProcess'
		SET @sql = '
			ALTER procedure [dbo].[ReportsMasterProcess] 

			as

			set nocount on

			declare @replicationName varchar(max)
			declare @SubProcessNameReports varchar(max)
			declare @dateStart datetime, @dateSP datetime
			declare @schedule_id int,@scheduleTime int
			declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

			declare @sessionKIll table(id int, sessionId int)
			declare @i int,@count int
			declare @sessionId int
			declare @SQL varchar(max)
			declare @name sysname
			declare @descError nvarchar(max)

			set @dateStart = getdate()
			set @scheduleTime = 10


			print ''---Get schedule_id and @scheduleTime ----''
			select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
				FROM msdb.dbo.sysjobs A
				LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
				INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
				where A.name=''ReportsMasterProcess''



			print ''---Kill Process Replication Merge Agent----''
			while exists(SELECT	s.session_id AS SessionID		
				from [master].sys.dm_exec_sessions  as s 
				LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
				where s.session_id in(
				select distinct r.blocking_session_id
				FROM [master].sys.dm_exec_sessions AS s
				INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
				WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
				)
				and s.[program_name] like ''%Replication Merge Agent%''	
				and DB_NAME(p.dbid)=''CCReportsRIA''	
			) begin
				insert into @sessionKIll(id,sessionId)
	
				SELECT	ROW_NUMBER() OVER(ORDER BY s.session_id) AS Row#, s.session_id AS SessionID		
				from [master].sys.dm_exec_sessions  as s 
				LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
				where s.session_id in(
				select distinct r.blocking_session_id
				FROM [master].sys.dm_exec_sessions AS s
				INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
				WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
				)
				and s.[program_name] like ''%Replication Merge Agent%''
				and DB_NAME(p.dbid)=''CCReportsRIA''

				select * from @sessionKIll

				select @i=1,@count =COUNT(*) from @sessionKIll
				while @i<=@count begin
					select @sessionId=sessionId from @sessionKIll where id=@i
					SET @SQL = ''KILL '' + CAST(@sessionId as varchar(max))
					begin try
						EXEC (@SQL)
					end try
					begin catch
						print @SQL+ '' is proccess end''
					end catch
					set @i=@i+1
				end
				delete from @sessionKIll
			end

			print ''--------------- Get Jobs Replication ------------------------------''
			create table #replications ([name] nvarchar(100), flag bit)

			;

			with jobNotStart as(
			select distinct A.[name] from msdb.dbo.sysjobs A 
				inner join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''		
				where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''	
			--union all
			--select distinct A.[name] from msdb.dbo.sysjobs A 
			--	inner join PublicationHighLoad B on A.[name] like ''%''+B.namePublication+''%''
			--	where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
			)

			insert into #replications
			select distinct A.[name],0 from msdb.dbo.sysjobs A 
				where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''	
				and A.name not in(select name from jobNotStart)	

			insert into #replications
			select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%CCReportsRIA- 0%'' and [name] like ''%CCRecorderRIA%'' order by [name]

			select @count=count(*) from #replications

			while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@dateStart,getdate())<(@scheduleTime*60)
			begin
				set rowcount 1
					select @replicationName = [name]
					from #replications with(nolock)
					where flag = 0
				set rowcount 0
	
				if (
					SELECT top 1 sjh.run_status
				  FROM msdb.dbo.sysjobhistory                sjh  
				  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
				  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
				  WHERE
				  j.name = @replicationName
				  order by sjh.instance_id desc		
				) <>4 
				or not exists(SELECT top 1 sjh.run_status
				  FROM msdb.dbo.sysjobhistory                sjh  
				  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
				  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
				  WHERE
				  j.name = @replicationName
				  order by sjh.instance_id desc	)
	
				begin
					exec msdb.dbo.sp_start_job @job_name = @replicationName
					print ''sp_start_job ''+@replicationName
				end
				else begin
					print ''Job is Init ''+@replicationName
				end

				update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

				WAITFOR DELAY ''00:00:03''		

				while (
					SELECT top 1 sjh.run_status
				  FROM msdb.dbo.sysjobhistory                sjh  
				  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
				  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
				  WHERE
				  j.name = @replicationName
				  order by sjh.instance_id desc		
				) = 4
				begin	
					WAITFOR DELAY ''00:00:01''
					print ''In Progress Job in ReplicationName: ''+@replicationName
					if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
						print ''Stop Job in ReplicationName: ''+@replicationName
						break	
					end
				end
				print ''Progress End Job in ReplicationName: ''+@replicationName
			end

			drop table #replications

			print ''--------------------------- Comienzo de subprocesos de reportes ---------------------------''

			/*C�digo del Job para la generaci�n de los reportes como subproceso.*/

			EXEC msdb.dbo.sp_start_job @job_name = ''ReportsMasterSubProcess''

			PRINT ''EXEC sp_start_job ReportsMasterSubProcess''

			print ''--------------------------- Termino subprocesos de reportes ---------------------------''


			declare @tableArticle table(nameArticle [sysname],objectId int)
			declare @tableTrigger table(id int identity, nameArticle [sysname])

			insert into @tableArticle(nameArticle,objectId)
			SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
			inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
			inner join sys.tables t on t.name=Art.name

			insert into @tableTrigger
			select t.name as nameTrigger from @tableArticle Art
			inner join sys.triggers  t on Art.objectId=t.parent_id
			where name not like ''MSmerge_%''

			select @i=1,@count =count(*) from @tableTrigger
			while @i<=@count
			begin
				select @name = nameArticle  from @tableTrigger where id=@i
				set @sql =''DROP TRIGGER ''+ @name 
				exec (@sql)
				set @i = @i+1
			end

			print ''--------------------------- DROP TRIGGER Tables ---------------------------''

			print ''---#reinitmergepullsubscription----''
			declare @lastTenMinuteFirst datetime
			declare @id int
			declare @publisher_reinit nvarchar(max)
			declare @publisher_db_reinit nvarchar(max)
			declare @publication_reinit nvarchar(max)
			declare @upload_first_reinit nvarchar(max)

			set @lastTenMinuteFirst = dateadd(minute,-@scheduleTime*2,getdate())

			create table #reinitmergepullsubscription(
			id int not null identity,
			publisher nvarchar(max) not null,
			publisher_db nvarchar(max)not null,
			publication nvarchar(max) not null,
			upload_first nvarchar(max) not null,
			[status] bit not null
			)

			insert into #reinitmergepullsubscription
			select distinct s.name, ma.publisher_db, ma.publication, ''false'', 0
			from distribution.dbo.MSmerge_history mh
			left outer join distribution.dbo.MSrepl_errors me
			on (mh.error_id = me.id)
			left outer join distribution.dbo.MSmerge_agents ma
			on (mh.agent_id = ma.id)
			left outer join master.sys.servers s
			on (ma.publisher_id = s.server_id)
			where 
			(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
			mh.comments like  ''%The Merge Agent failed because the schema of the article at the Publisher does not match the schema of the article at the Subscriber%'')
			and mh.time >= @lastTenMinuteFirst
			and ma.subscriber_db = ''CCReportsRIA''

			while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
				begin
					set rowcount 1
					select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
					from #reinitmergepullsubscription
					where [status] = 0
					set rowcount 0
		
					exec sp_reinitmergepullsubscription  @publisher = @publisher_reinit,    @puSblisher_db = @publisher_db_reinit,    @publication = @publication_reinit,    @upload_first = @upload_first_reinit

					update #reinitmergepullsubscription
					set [status] = 1
					where id = @id
				end

			drop table #reinitmergepullsubscription

			if DATEDIFF(ss,@dateStart,getdate())>@scheduleTime*60 begin
				set @scheduleTime=@scheduleTime+1
				if  @scheduleTime < 59 begin
					EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
				end	
			end
		'
		EXEC(@sql)

		SET @process = 'CW-4991 Se genera un bueno Job llamado ReportsMasterSubProcess para la generacion de los reportes.'
		SET @sql = '
			USE [msdb]

			/****** Object:  Job [ReportsMasterSubProcess]    Script Date: 26/03/2021 11:56:55 a. m. ******/
			IF EXISTS(SELECT * FROM  [msdb].[dbo].[sysjobs] AS [sJOB] WHERE [name]=N''ReportsMasterSubProcess'') 
			BEGIN
				EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterSubProcess'', @delete_unused_schedule=1
			END

			/****** Object:  Job [ReportsMasterSubProcess]    Script Date: 26/03/2021 11:56:56 a. m. ******/
			BEGIN TRANSACTION
			DECLARE @ReturnCode INT
			SELECT @ReturnCode = 0
			/****** Object:  JobCategory [Nuxiba]    Script Date: 26/03/2021 11:56:56 a. m. ******/
			IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
			BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

			END

			DECLARE @jobId BINARY(16)
			EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterSubProcess'', 
					@enabled=1, 
					@notify_level_eventlog=0, 
					@notify_level_email=0, 
					@notify_level_netsend=0, 
					@notify_level_page=0, 
					@delete_level=0, 
					@description=N''Generaci�n de reportes como subproceso'', 
					@category_name=N''Nuxiba'', 
					@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			/****** Object:  Step [Generacion de Reportes]    Script Date: 26/03/2021 11:56:58 a. m. ******/
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generacion de Reportes'', 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N''TSQL'', 
					@command=N''EXEC ReportsMasterSubProcess'', 
					@database_name=N''CCReportsRIA'', 
					@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			COMMIT TRANSACTION
			GOTO EndSave
			QuitWithRollback:
				IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
			EndSave:		
			
		'
		EXEC(@sql)

		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF

