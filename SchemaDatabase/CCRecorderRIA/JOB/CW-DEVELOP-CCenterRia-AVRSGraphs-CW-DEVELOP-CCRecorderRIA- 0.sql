USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'CW-DEVELOP-CCenterRia-AVRSGraphs-CW-DEVELOP-CCRecorderRIA- 0') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N'CW-DEVELOP-CCenterRia-AVRSGraphs-CW-DEVELOP-CCRecorderRIA- 0', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Nuxiba' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Nuxiba'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CW-DEVELOP-CCenterRia-AVRSGraphs-CW-DEVELOP-CCRecorderRIA- 0',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'No description available.',
		@category_name=N'Nuxiba',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run agent.',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=10,
		@retry_interval=1,
		@os_run_priority=0,  @subsystem=N'TSQL',
		@command=N'-Publisher [CW-DEVELOP] -PublisherDB [CCenterRia] -Publication [AVRSGraphs] -Subscriber [CW-DEVELOP] -SubscriberDB [CCRecorderRIA] -SubscriptionType 1 -SubscriberSecurityMode 1    -Distributor [CW-DEVELOP] ',
		@database_name=N'CCRecorderRIA',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Replication agent schedule.',
		@enabled=0,
		@freq_type=1,
		@freq_interval=0,
		@freq_subday_type=0,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=19950101,
		@active_end_date=19950101,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave: