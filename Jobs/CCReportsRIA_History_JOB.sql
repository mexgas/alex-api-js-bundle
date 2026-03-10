/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:

Date: 2026/03/06
Description: Job for RepHist Copy, Verify, and Cleanup

Database: CCReportsRIA_History
Required version: 1

*/

SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 1

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion >= @version
BEGIN
	BEGIN TRAN

	BEGIN TRY

    SET @process = 'CREATE JOB RepHist_CopyVerifyAndCleanup'
    SET @sql = 'USE [msdb]

IF EXISTS(SELECT * FROM [msdb].[dbo].[sysjobs] AS [sJOB] WHERE [name]=N''RepHist_CopyVerifyAndCleanup'') 
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name=N''RepHist_CopyVerifyAndCleanup'', @delete_unused_schedule=1
END

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

/****** Object:  JobCategory [Nuxiba] ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16)

/****** Create Job ******/
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''RepHist_CopyVerifyAndCleanup'', 
        @enabled=0, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''Copy Rep% tables from CCReportsRIA to History, verify data integrity, and apply retention cleanup on both databases.'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''sa'', 
        @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step 1: Copy to History ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''01 - CopyReportsToHistory'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, -- Go to the next step
        @on_fail_action=2,    -- Quit job reporting failure
        @retry_attempts=1, 
        @retry_interval=5, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC CCReportsRIA_History.dbo.ccsp_RepHist_CopyReportsToHistory;'', 
        @database_name=N''CCReportsRIA_History'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step 2: Verify copy ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''02 - VerifyRepCopy'', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=3, -- Go to the next step
        @on_fail_action=2, 
        @retry_attempts=1, 
        @retry_interval=5, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC CCReportsRIA_History.dbo.ccsp_RepHist_VerifyCopy;'', 
        @database_name=N''CCReportsRIA_History'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step 3: Cleanup History ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''03 - CleanupHistory'', 
        @step_id=3, 
        @cmdexec_success_code=0, 
        @on_success_action=3, -- Go to the next step
        @on_fail_action=2, 
        @retry_attempts=1, 
        @retry_interval=5, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC CCReportsRIA_History.dbo.ccsp_RepHist_CleanupHistory;'', 
        @database_name=N''CCReportsRIA_History'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Step 4: Cleanup RIA ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''04 - CleanupRIA'', 
        @step_id=4, 
        @cmdexec_success_code=0, 
        @on_success_action=1, -- Quit with success
        @on_fail_action=2, 
        @retry_attempts=1, 
        @retry_interval=5, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''EXEC CCReportsRIA_History.dbo.ccsp_RepHist_CleanupRIA;'', 
        @database_name=N''CCReportsRIA_History'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Set Start Step ******/
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Add Schedule: Daily at 03:30 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Daily_03_30_AM'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20240101, 
        @active_end_date=99991231, 
        @active_start_time=33000, 
        @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Add Job Server ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

	SET @process = 'CREATE JOB '
    SET @sql = ''
    EXEC(@sql)

    SET @process = 'CREATE JOB '
    SET @sql = ''
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