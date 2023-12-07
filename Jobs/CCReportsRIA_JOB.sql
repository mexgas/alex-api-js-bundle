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
        @enabled=1, 
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
        @freq_subday_interval=10, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20130912, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=40000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=4, 
        @freq_subday_interval=10, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20201113, 
        @active_end_date=99991231, 
        @active_start_time=43000, 
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

    set @process = 'CREATE JOB ReportsMasterProcessPublicationHighLoadPublicationHighLoad'
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
        @enabled=1, 
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

    set @process = 'CREATE JOB ReportsMasterProcessPublicationLowLoad'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessPublicationLowLoad'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 03/09/2021 07:55:33 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''ReportsMasterProcess'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 03/09/2021 07:55:33 p. m. ******/
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
        @freq_subday_type=4, 
        @freq_subday_interval=15, 
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

    set @process = 'CREATE JOB ReportsMasterSubProcess'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterSubProcess'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterSubProcess'', @delete_unused_schedule=1
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterSubProcess'', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''Generaci?n de reportes como subproceso'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generacion de Reportes]    Script Date: 03/09/2021 07:58:15 p. m. ******/
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
/****** Object:  Step [GenerateReport]    Script Date: 21/11/2023 02:24:39 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''GenerateReport'', 
        @step_id=1, 
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportGenateLow'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=8, 
        @freq_subday_interval=4, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20231121, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=40000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportGenateLowAfter'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=8, 
        @freq_subday_interval=4, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20231121, 
        @active_end_date=99991231, 
        @active_start_time=43000, 
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
        @enabled=1, 
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
        @freq_subday_interval=2, 
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

     set @process = 'CREATE JOB '
    set @sql = ''
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
