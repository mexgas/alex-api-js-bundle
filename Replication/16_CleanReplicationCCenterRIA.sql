USE [msdb]

/****** Object:  Job [CleanReplicationCCenterRIA]    Script Date: 19/12/2023 09:20:22 p. m. ******/
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'CW Delete old records') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N'CleanReplicationCCenterRIA', @delete_unused_schedule=1
end

/****** Object:  Job [CleanReplicationCCenterRIA]    Script Date: 19/12/2023 09:20:22 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 19/12/2023 09:20:22 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Nuxiba' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Nuxiba'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CleanReplicationCCenterRIA', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Limpia las replicas de base datos', 
		@category_name=N'Nuxiba', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Merge Replication]    Script Date: 19/12/2023 09:20:22 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean Merge Replication', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @num_genhistory_rows	int
,@num_contents_rows	int
,@num_tombstone_rows	int
,@aggressive_cleanup_only	bit
,@MSmerge_contents int
,@MSmerge_genhistory int
,@MSmerge_tombstone int
,@dateStart datetime
,@dateEnd datetime

set @aggressive_cleanup_only=0
set @dateStart=GETDATE()


EXEC sp_mergemetadataretentioncleanup 
   @num_genhistory_rows= @num_genhistory_rows out
   ,@num_contents_rows= @num_contents_rows out
   ,@num_tombstone_rows= @num_tombstone_rows out
   ,@aggressive_cleanup_only= @aggressive_cleanup_only

', 
		@database_name=N'CCenterRIA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Clean Replication Merge', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20231219, 
		@active_end_date=99991231, 
		@active_start_time=210000, 
		@active_end_time=55959		
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave: