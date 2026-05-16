/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/12/13
Description:

Database: CCReportsRIA
Required version: 104

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

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
BEGIN
	BEGIN TRAN

	BEGIN TRY

    set @process = 'CREATE JOB ReportsMasterProcess'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcess'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcess'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 03/09/2021 07:53:47 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcess'', 
        @enabled=0, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''ReportsMasterProcess'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 03/09/2021 07:53:47 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC ReportsMasterProcess'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportMasterProcessAfter'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=4, 
        @freq_subday_interval=20, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20130912, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=34000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=4, 
        @freq_subday_interval=25, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20201113, 
        @active_end_date=99991231, 
        @active_start_time=45500, 
        @active_end_time=234000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

    set @process = 'CREATE JOB ReportsMasterProcessPublicationHighLoad'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessPublicationHighLoad'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationHighLoad'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 03/09/2021 07:54:35 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationHighLoad'', 
        @enabled=0, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''ReportsMasterProcessPublicationHighLoad'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 03/09/2021 07:54:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC ReportsMasterProcessPublicationHighLoad'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=4, 
        @freq_subday_interval=5, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20130912, 
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
    EXEC(@sql)

    
    set @process = 'CREATE JOB ReportsMasterProcessYesterday'
    set @sql = 'USE [msdb]

if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessYesterday'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessYesterday'', @delete_unused_schedule=1
end
/****** Object:  Job [ReportsMasterProcessYesterday]    Script Date: 21/11/2023 02:10:16 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 21/11/2023 02:10:16 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessYesterday'', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''execute ReportsMasterProcess Yesterday 3:00 AM - 3:00 AM'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 21/11/2023 02:10:17 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''declare @from datetime,@to datetime,@dateNow datetime
set @to =convert(datetime,convert(varchar(11),getdate(),121)+''''03:00:00'''',121)
set @from =DATEADD(dd,-1,@to)

set @dateNow =getdate()

EXEC ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=30,@dateStart=@dateNow,@isAllReport=2'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportsMasterProcessWIthOnlyGenerate'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=10, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20130912, 
        @active_end_date=99991231, 
        @active_start_time=40000, 
        @active_end_time=235959     
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)    

    set @process = 'CREATE JOB ReportMasterProcessGenerateLow'
    set @sql = 'USE [msdb]

if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportMasterProcessGenerateLow'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportMasterProcessGenerateLow'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

/****** Object:  JobCategory [Nuxiba]    Script Date: 03/09/2021 07:58:15 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportMasterProcessGenerateLow'', 
        @enabled=0, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''No description available.'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Execute_LowLoad_Replication]    Script Date: 21/11/2023 02:24:39 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Execute_LowLoad_Replication'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessPublicationLowLoad'', 
		@database_name=N''CCReportsRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [GenerateReport]    Script Date: 21/11/2023 02:24:39 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''GenerateReport'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessWIthOnlyGenerate @isAllReport=1'', 
		@database_name=N''CCReportsRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow1'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=1000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow2'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow3'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=83000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow4'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=124000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow5'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=162500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow6'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=203500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ScheduleGenerateLow7'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20250224, 
		@active_end_date=99991231, 
		@active_start_time=233000, 
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
    EXEC(@sql)

    
set @process = 'CREATE JOB ReportsMasterProcessPublicationLowLoad'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessPublicationLowLoad'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 21/11/2023 03:16:15 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', 
        @enabled=0, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''ReportsMasterProcess'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 21/11/2023 03:16:15 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC ReportsMasterProcessPublicationLowLoad'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=8, 
        @freq_subday_interval=4, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20130912, 
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
    EXEC(@sql)

    set @process = 'CREATE JOB JOB_UpdateDataAreaId_Batch'
    set @sql = 'USE msdb

DECLARE @jobId BINARY(16);

-- Elimina el job si ya existe
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N''JOB_UpdateDataAreaId_Batch'')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N''JOB_UpdateDataAreaId_Batch'';
END
GO

/****** Object:  Job [JOB_UpdateDataAreaId_Batch]    Script Date: 26/03/2026 03:56:34 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 26/03/2026 03:56:35 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''JOB_UpdateDataAreaId_Batch'', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''Actualiza areaId/area por lotes con ventana de ejecución 10 PM a 4 AM.'', 
        @category_name=N''[Uncategorized (Local)]'', 
        @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Ejecutar SP]    Script Date: 26/03/2026 03:56:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Ejecutar SP'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @BatchSize INT = 10000;
DECLARE @RowsAffected INT = 1;
DECLARE @Now DATETIME = GETDATE();
DECLARE @Today DATE = CAST(GETDATE() AS DATE);
DECLARE @StopAt DATETIME;

-- Hora de corte: 04:00 AM
SET @StopAt =
    CASE
        WHEN CAST(@Now AS TIME) >= ''''22:00:00''''
            THEN DATEADD(DAY, 1, CAST(@Today AS DATETIME)) + CAST(''''04:00:00'''' AS DATETIME)
        ELSE
            CAST(@Today AS DATETIME) + CAST(''''04:00:00'''' AS DATETIME)
    END;

PRINT ''''Inicio: '''' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT ''''Corte: '''' + CONVERT(VARCHAR(19), @StopAt, 120);



BEGIN TRY

    -------------------------------------------------------------------------
    -- 1) RepAgentSummary
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        IF GETDATE() >= @StopAt
        BEGIN
            PRINT ''''Se alcanzó la hora límite. Fin controlado.'''';
            BREAK;
        END

        BEGIN TRAN;

        ;WITH CTE AS
        (
            SELECT TOP (@BatchSize)
                   R.*
            FROM RepAgentSummary R
            WHERE R.areaId = 0
            ORDER BY R.[date] DESC
        )
        UPDATE CTE
           SET areaId = A.IDArea,
               area   = A.AreaName
        FROM CTE R
        INNER JOIN ccUserView C
            ON R.userId = C.User_id
        INNER JOIN ccriacat_areas A
            ON C.IDArea = A.IDArea;

        SET @RowsAffected = @@ROWCOUNT;
        COMMIT TRAN;

        PRINT ''''RepAgentSummary actualizados: '''' + CAST(@RowsAffected AS VARCHAR(20));

        WAITFOR DELAY ''''00:00:01'''';

        IF @RowsAffected = 0 BREAK;

        
    END

    -------------------------------------------------------------------------
    -- 2) RepInCallsDetail
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        IF GETDATE() >= @StopAt
        BEGIN
            PRINT ''''Se alcanzó la hora límite. Fin controlado.'''';
            BREAK;
        END

        BEGIN TRAN;

        ;WITH CTE AS
        (
            SELECT TOP (@BatchSize)
                   R.*
            FROM RepInCallsDetail R
            WHERE R.areaId = 0
            ORDER BY R.[date] DESC
        )
        UPDATE CTE
           SET areaId = A.IDArea,
               area   = A.AreaName
        FROM CTE R
        INNER JOIN ccinbound C
            ON R.inboundId = C.inbound_id
        INNER JOIN ccriacat_areas A
            ON C.IDArea = A.IDArea;

        SET @RowsAffected = @@ROWCOUNT;
        COMMIT TRAN;

        PRINT ''''RepInCallsDetail actualizados: '''' + CAST(@RowsAffected AS VARCHAR(20));

         WAITFOR DELAY ''''00:00:01'''';

        IF @RowsAffected = 0 BREAK;

       
    END

    -------------------------------------------------------------------------
    -- 3) RepOutCallsDetail
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        IF GETDATE() >= @StopAt
        BEGIN
            PRINT ''''Se alcanzó la hora límite. Fin controlado.'''';
            BREAK;
        END

        BEGIN TRAN;

        ;WITH CTE AS
        (
            SELECT TOP (@BatchSize)
                   R.*
            FROM RepOutCallsDetail R
            WHERE R.areaId = 0
            ORDER BY R.[date] DESC
        )
        UPDATE CTE
           SET areaId = A.IDArea,
               area   = A.AreaName
        FROM CTE R
        INNER JOIN cccamps C
            ON R.campaignId = C.cam_id
        INNER JOIN ccriacat_areas A
            ON C.IDArea = A.IDArea;

        SET @RowsAffected = @@ROWCOUNT;
        COMMIT TRAN;

        PRINT ''''RepOutCallsDetail actualizados: '''' + CAST(@RowsAffected AS VARCHAR(20));

         WAITFOR DELAY ''''00:00:01'''';

        IF @RowsAffected = 0 BREAK;

       
    END

    -------------------------------------------------------------------------
    -- 4) RepOutDialDetail
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        IF GETDATE() >= @StopAt
        BEGIN
            PRINT ''''Se alcanzó la hora límite. Fin controlado.'''';
            BREAK;
        END

        BEGIN TRAN;

        ;WITH CTE AS
        (
            SELECT TOP (@BatchSize)
                   R.*
            FROM RepOutDialDetail R
            WHERE R.areaId = 0
            ORDER BY R.[date] DESC
        )
        UPDATE CTE
           SET areaId = A.IDArea,
               area   = A.AreaName
        FROM CTE R
        INNER JOIN cccamps C
            ON R.campaignId = C.cam_id
        INNER JOIN ccriacat_areas A
            ON C.IDArea = A.IDArea;

        SET @RowsAffected = @@ROWCOUNT;
        COMMIT TRAN;

        PRINT ''''RepOutDialDetail actualizados: '''' + CAST(@RowsAffected AS VARCHAR(20));

         WAITFOR DELAY ''''00:00:01'''';

        IF @RowsAffected = 0 BREAK;

       
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(''''Error en Step 1: %s'''', 16, 1, @Msg);
END CATCH;'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DisableJOb]    Script Date: 26/03/2026 03:56:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DisableJOb'', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''USE [CCReportsRIA];
SET NOCOUNT ON;

DECLARE @Pending BIGINT = 0;

SELECT @Pending = @Pending + COUNT_BIG(*)
FROM RepAgentSummary
WHERE areaId = 0;

SELECT @Pending = @Pending + COUNT_BIG(*)
FROM RepInCallsDetail
WHERE areaId = 0;

SELECT @Pending = @Pending + COUNT_BIG(*)
FROM RepOutCallsDetail
WHERE areaId = 0;

SELECT @Pending = @Pending + COUNT_BIG(*)
FROM RepOutDialDetail
WHERE areaId = 0;

PRINT ''''Pendientes totales: '''' + CAST(@Pending AS VARCHAR(30));

IF @Pending = 0
BEGIN
    PRINT ''''No hay registros pendientes. Se deshabilitará el job.'''';

    EXEC msdb.dbo.sp_update_job
        @job_name = N''''JOB_UpdateDataAreaId_Batch'''',
        @enabled = 0;
END
ELSE
BEGIN
    PRINT ''''Aún existen registros pendientes. El job seguirá programado para la siguiente ejecución.'''';
END'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''SCH_UpdateDataAreaId_2300'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20260326, 
        @active_end_date=99991231, 
        @active_start_time=220000, 
        @active_end_time=235959     
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)


    set @process = 'CREATE JOB JOB_UpdateSystemApiId_Batch'
    set @sql = 'USE msdb

DECLARE @jobId BINARY(16);

-- Elimina el job si ya existe
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N''JOB_UpdateSystemApiId_Batch'')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N''JOB_UpdateSystemApiId_Batch'';
END
GO

/****** Object:  Job [JOB_UpdateSystemApiId_Batch]    Script Date: 26/03/2026 03:56:34 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 26/03/2026 03:56:35 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''JOB_UpdateSystemApiId_Batch'', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''Actualiza SystemApiId por lotes con ventana de ejecución 10 PM a 4 AM.'', 
        @category_name=N''[Uncategorized (Local)]'', 
        @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Ejecutar SP]    Script Date: 26/03/2026 03:56:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Ejecutar SP'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @BatchSize INT = 10000;
DECLARE @RowsAffected INT = 1;
DECLARE @Now DATETIME = GETDATE();
DECLARE @Today DATE = CAST(GETDATE() AS DATE);
DECLARE @StopAt DATETIME;

declare @date datetime=dateadd(dd,-60,getdate())
-- Hora de corte: 04:00 AM
SET @StopAt =
    CASE
        WHEN CAST(@Now AS TIME) >= ''''22:00:00''''
            THEN DATEADD(DAY, 1, CAST(@Today AS DATETIME)) + CAST(''''04:00:00'''' AS DATETIME)
        ELSE
            CAST(@Today AS DATETIME) + CAST(''''04:00:00'''' AS DATETIME)
    END;

PRINT ''''Inicio: '''' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT ''''Corte: '''' + CONVERT(VARCHAR(19), @StopAt, 120);



BEGIN TRY

    -------------------------------------------------------------------------
    -- 1) RepAgentSummary
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        IF GETDATE() >= @StopAt
        BEGIN
            PRINT ''''Se alcanzó la hora límite. Fin controlado.'''';
            BREAK;
        END

        BEGIN TRAN;

        ;WITH CTE AS
        (
            SELECT TOP (@BatchSize)
                    R.*
            FROM RepOutSMSSentMessagesDetail R
            WHERE SystemApiId IS NULL
                AND [date] >= @date
            ORDER BY R.[date] DESC
        )
        UPDATE R
            SET SystemApiId = C.SystemApiId
        FROM CTE R
        INNER JOIN smsccoLogDial C
            ON R.messageId = C.logId;
     
        SET @RowsAffected = @@ROWCOUNT;
        COMMIT TRAN;

        PRINT ''''RepOutSMSSentMessagesDetail actualizados: '''' + CAST(@RowsAffected AS VARCHAR(20));

        WAITFOR DELAY ''''00:00:01'''';

        IF @RowsAffected = 0 BREAK;

        
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(''''Error en Step 1: %s'''', 16, 1, @Msg);
END CATCH;'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DeleteJob]    Script Date: 26/03/2026 03:56:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DeleteJob'', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''USE [CCReportsRIA];
SET NOCOUNT ON;

declare @date datetime=dateadd(dd,-60,getdate())

DECLARE @Pending BIGINT = 0;

SELECT @Pending = @Pending + COUNT_BIG(*)
FROM RepOutSMSSentMessagesDetail
WHERE SystemApiId is null and date>=@date

PRINT ''''Pendientes totales: '''' + CAST(@Pending AS VARCHAR(30));

IF @Pending = 0
BEGIN
    PRINT ''''No hay registros pendientes. Se eliminará el job.'''';

    EXEC msdb.dbo.sp_delete_job
        @job_name = N''''JOB_UpdateSystemApiId_Batch'''';
END
ELSE
BEGIN
    PRINT ''''Aún existen registros pendientes. El job seguirá programado para la siguiente ejecución.'''';
END'', 
        @database_name=N''CCReportsRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''SCH_UpdateDataAreaId_2300'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20260326, 
        @active_end_date=99991231, 
        @active_start_time=220000, 
        @active_end_time=235959     
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)


     set @process = 'CREATE JOB '
    set @sql = ''
    EXEC(@sql)
    	

		
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
