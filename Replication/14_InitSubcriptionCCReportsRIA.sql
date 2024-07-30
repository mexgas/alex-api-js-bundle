set nocount on

use [CCReportsRIA]

SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 104

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion >= @version
 begin
 	BEGIN TRAN

	BEGIN TRY

	set @process = 'Drop Table migration'
	set @Sql = '--

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = ''migration'')
BEGIN
	drop table migration
END	'
	EXEC(@Sql)

	set @process = 'CREATE Table migration'
	set @Sql = 'IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = ''migration'')
BEGIN
	CREATE TABLE [dbo].[migration](
	[id] [int] NOT NULL,
	[description] [varchar](255) NOT NULL,		
	[status] [int] NOT NULL,
	[error] [nvarchar](max) NOT NULL,
	[dateStart] datetime NOT NULL,
	[dateEnd] datetime NOT NULL,
	[db_name] [sysname] NULL,
	) ON [PRIMARY]		
END
truncate table migration;

insert into migration
select
ROW_NUMBER() OVER(ORDER BY B.name desc)+99 AS id, B.name as [description],0 as status,'''' as error,''1901-01-01'' as dateStart,''1901-01-01'' as dateEnd
,null db_name

from sysmergesubscriptions A
inner join sysmergepublications B on A.pubid=B.pubid
where A.db_name in(''CCReportsRIA'')
order by B.name,A.db_name


;with dbNamePublication as(

select A.description,s.db_name,S.status 
from migration A
inner join sysmergepublications B on A.description=B.name
inner join sysmergesubscriptions S on B.pubid=S.pubid 
where S.db_name in(''CCenterRIA'',''CCRecorderRIA'')
)
update M
set M.db_name=A.db_name
from dbNamePublication A
inner join migration M on A.description=M.description
'
	EXEC(@Sql)

	set @Sql = 'exec msdb..sp_update_job @job_name = ''ReportsMasterProcess'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportMasterProcessGenerateLow'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessPublicationHighLoad'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessPublicationLowLoad'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessYesterday'', @enabled = 0 --Enable
'
	EXEC(@Sql)

	set @process = 'Create Job CW_Merge_Replication_CCreportsRIA'
	set @Sql='USE [msdb]

if exists( select * from msdb.dbo.sysjobs where name=''CW_Merge_Replication_CCreportsRIA'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW_Merge_Replication_CCreportsRIA'', @delete_unused_schedule=1

/****** Object:  Job [CW Merge Replication]    Script Date: 23/06/2018 11:12:45 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW_Merge_Replication_CCreportsRIA'', 
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

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW_Merge_Replication_CCreportsRIA'', 
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
declare @id int,@i int
declare @publicationName varchar(max),@dbName sysname,@jobName varchar(max)
declare @dateStart datetime,@dateNow datetime
declare @statusSubcription int
declare @maxId int

select @maxId=isnull(max(id),1),@id=0,@i=0,@dateNow =getdate()
FROM migration


while DATEDIFF(ss,@dateNow,getdate())<59  and
 exists(select * FROM migration where status in(0,1))
and @id<= @maxId

begin
	select top 1 @publicationName=[description],  @dateStart  = dateStart,@dbName =[db_name],@id=id 
	from migration 
	where status in(0,1) and id>=@id
	order by id
				
	------ Revisa si ya se genero la primera subcripcion ------
	select @statusSubcription= S.status
	from sysmergepublications B 
	inner join sysmergesubscriptions S on B.pubid=S.pubid 		
	where S.db_name =DB_NAME() and B.name=@publicationName

	if @statusSubcription=1 begin
		select @statusSubcription,* from migration  where id=@id

		update migration with (rowlock) set [status] = 2,dateStart=GETDATE(), [dateEnd] = getdate() where id=@id
		set @i=@i+1
		set @id=@id+1			

		continue;
	end

	select @jobName= A.[name] from msdb.dbo.sysjobs A 		
	where A.[name] like ''''%''''+DB_NAME()+''''- 0%'''' and A.[name] like ''''%''''+@dbName+''''%''''
	and A.[name] like ''''%''''+@publicationName+''''-%''''


	
	update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id=@id
	exec msdb.dbo.sp_start_job @job_name = @jobName

		WAITFOR DELAY ''''00:00:01''''   

		while exists(
		select S.status
		from sysmergepublications B 
		inner join sysmergesubscriptions S on B.pubid=S.pubid 		
		where S.db_name =DB_NAME() and B.name=@publicationName
		and S.status<>1
		) 
	begin   
		WAITFOR DELAY ''''00:00:01''''
		print ''''In Progress Job in ReplicationName: ''''+@jobName        
		if DATEDIFF(ss,@dateNow,getdate())>59 begin
			select @publicationName publicationName, @jobName jobName
			break;
		end
	end
		print ''''Progress End Job in ReplicationName: ''''+@jobName

	select @statusSubcription= S.status
	from sysmergepublications B 
	inner join sysmergesubscriptions S on B.pubid=S.pubid 		
	where S.db_name =DB_NAME() and B.name=@publicationName
	and S.status<>1

	WAITFOR DELAY ''''00:00:01''''

	if @statusSubcription=1 begin	
		update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id=@id
	end
		
	set @i=@i+1
	set @id=@id+1
		
end
select @dateNow, DATEDIFF(ss,@dateNow,getdate())


if not exists(select * from migration where status in(0,1)) begin
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcess'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessPublicationHighLoad'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessPublicationLowLoad'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessYesterday'''', @enabled = 0 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterSubProcess'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportMasterProcessGenerateLow'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''CW_Merge_Replication_CCreportsRIA'''', @enabled = 0 --Disable

	exec ccSpCreateIndexReport
end
'', 
		@database_name=N''CCReportsRIA'', 
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

	select 'Merge Snapshots Finished'

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
	
 end

else
 begin
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
 end
set nocount off
