USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'CW (AutoStart),(Callback/abandoned update),(Campaign summary)') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N'CW (AutoStart),(Callback/abandoned update),(Campaign summary)', @delete_unused_schedule=1
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CW (AutoStart),(Callback/abandoned update),(Campaign summary)',
		@enabled=0,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'Se funcioan los jobs CW AutoStart, CW Callback/abandoned update y CW Campaign summary',
		@category_name=N'Nuxiba',
		@owner_login_name=N'replication', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CW Callback/abandoned update',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0,  @subsystem=N'TSQL',
		@command=N'declare @callout_id_array varchar(max), @SQL varchar(max)
set @callout_id_array=''|''

select @callout_id_array=@callout_id_array+coalesce('',''+cast(callout_id as varchar(10)), @callout_id_array, '''')
from ccRIAUpdateCallBack_Abandon where minCallBackAbandonXpire < getdate()

if len(@callout_id_array)>1
 begin
  select @callout_id_array=replace(@callout_id_array, ''|,'', '''')

  set @SQL=''delete ccoWorkingTable with(rowlock) where callout_id in (''+@callout_id_array+'')''
  exec(@SQL)

  set @SQL=''delete ccRIAUpdateCallBack_Abandon with(rowlock) where callout_id in (''+@callout_id_array+'')''
  exec(@SQL)

  set @SQL=''update ccoCallBacks with(rowlock) set [status] = 4, schedulerStatus = 1 where callout_id in (''+@callout_id_array+'') and [status] = 0''
  exec(@SQL)
 end',
		@database_name=N'CCenterRia',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CW Campaign summary',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0,  @subsystem=N'TSQL',
		@command=N'exec ccsp_RIAGetCampsNvosCB 0,2,0',
		@database_name=N'CCenterRia',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'CW Commons Tasj',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=15,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20151022,
		@active_end_date=99991231,
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