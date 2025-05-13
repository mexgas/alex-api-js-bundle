set nocount on

use [CCenterRia]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '119'

--create table #temp([version] int)
--insert into #temp
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

--drop table #temp

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
		[status] [int] NOT NULL,
		[error] [nvarchar](max) NOT NULL,
		[dateStart] datetime NOT NULL,
		[dateEnd] datetime NOT NULL
		) ON [PRIMARY]		

	END	

	--Para asegurar el orden correcto en que toma los publicadores y evitar el error humano en los id que hacen tronar las replicas de Twitter.
	truncate table migration;

	insert into migration 
	select 99+ ROW_NUMBER() OVER(ORDER BY description ASC) AS Id,name as [description],0 status, '''',''1900-01-01 00:00:00.000'' dateStart,''1900-01-01 00:00:00.000'' dateEnd 
	from dbo.syspublications where db_name()=''CCenterRia''

	'
	EXEC(@Sql)
	
	set @Sql='USE [msdb]

/****** Object:  Job [CW Tran Replication]    Script Date: 23/06/2018 11:12:45 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''CW Tran Replication'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Tran Replication'', @delete_unused_schedule=1

/****** Object:  Job [CW Tran Replication]    Script Date: 23/06/2018 11:12:45 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:12:45 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Tran Replication'', 
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
/****** Object:  Step [CW Tran Replication]    Script Date: 23/06/2018 11:12:45 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Tran Replication'', 
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
declare @id int,@i int,@count int
declare @publicationName varchar(max)
declare @dateStart datetime,@dateNow datetime
declare @status int
declare @maxId int,@minId int

--delete from migration

select @maxId=isnull(max(id),99),@dateNow =getdate(),@i=0 FROM migration

insert into migration
SELECT ROW_NUMBER() OVER(ORDER BY name desc)+@maxId AS id, P.name as [description],0 as status,'''''''' as error,''''1901-01-01'''' as dateStart,''''1901-01-01'''' as dateEnd FROM dbo.syspublications P
left join migration M on P.name=M.[description]
where  db_name()=''''CCenterRia'''' and M.[description] is null 

select @minId=ISNULL(min(id),99), @maxId=isnull(max(id),99),@count=COUNT(*) FROM migration

select * FROM migration

if exists(select * FROM migration where status in(0,1)) begin

	while @i<@count and DATEDIFF(ss,@dateNow,getdate())<59 begin
		select @publicationName=[description],  @dateStart  = dateStart, @status = status from migration  with (nolock) where id=@minId+@i
		
		if @status = 2 begin		 
		 set @i=@i+1
		 continue;
		end

		if (not exists( select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id 
			and a.runstatus = 2 and b.publication = @publicationName and a.start_time < convert(datetime,convert(varchar(10),@dateStart,121)))	   
			) begin
				 update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id=@minId+@i     				 
				 exec sp_startpublication_snapshot @publication = @publicationName

				 WAITFOR DELAY ''''00:00:01''''

				while not exists(
					select *
					from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
					where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id 
					and a.runstatus = 2
					and b.publication = @publicationName and a.start_time > convert(datetime,convert(varchar(10),@dateStart,121))	
				)
				begin
					WAITFOR DELAY ''''00:00:01''''
					if DATEDIFF(ss,@dateNow,getdate())>=59 begin
						break
					end
				end
				update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id=@minId+@i				
		end
		else if(@status = 1 and
				exists( select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
						where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id 
						and a.runstatus = 2 and b.publication = @publicationName and a.start_time > convert(datetime,convert(varchar(10),@dateStart,121))
						)
			) begin 
	
			update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id=@minId+@i  and status=1
		end

		set @i=@i+1
		
	end

end
'', 
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
EndSave:
	'

		EXEC(@Sql)

	------------------ FIN SCRIPT @Sql ------------------

	select 'Tran Snapshots Finished'
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
