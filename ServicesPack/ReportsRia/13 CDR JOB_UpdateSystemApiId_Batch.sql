USE msdb
GO

DECLARE @jobId BINARY(16);

-- Elimina el job si ya existe
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'JOB_UpdateSystemApiId_Batch')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'JOB_UpdateSystemApiId_Batch';
END
GO

/****** Object:  Job [JOB_UpdateSystemApiId_Batch]    Script Date: 26/03/2026 03:56:34 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 26/03/2026 03:56:35 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'JOB_UpdateSystemApiId_Batch', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Actualiza SystemApiId por lotes con ventana de ejecución 10 PM a 4 AM.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Ejecutar SP]    Script Date: 26/03/2026 03:56:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Ejecutar SP', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON;
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
        WHEN CAST(@Now AS TIME) >= ''22:00:00''
            THEN DATEADD(DAY, 1, CAST(@Today AS DATETIME)) + CAST(''04:00:00'' AS DATETIME)
        ELSE
            CAST(@Today AS DATETIME) + CAST(''04:00:00'' AS DATETIME)
    END;

PRINT ''Inicio: '' + CONVERT(VARCHAR(19), GETDATE(), 120);
PRINT ''Corte: '' + CONVERT(VARCHAR(19), @StopAt, 120);



BEGIN TRY

    -------------------------------------------------------------------------
    -- 1) RepAgentSummary
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        IF GETDATE() >= @StopAt
        BEGIN
            PRINT ''Se alcanzó la hora límite. Fin controlado.'';
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

        PRINT ''RepOutSMSSentMessagesDetail actualizados: '' + CAST(@RowsAffected AS VARCHAR(20));

        WAITFOR DELAY ''00:00:01'';

        IF @RowsAffected = 0 BREAK;

        
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(''Error en Step 1: %s'', 16, 1, @Msg);
END CATCH;', 
		@database_name=N'CCReportsRIA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DeleteJob]    Script Date: 26/03/2026 03:56:35 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DeleteJob', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [CCReportsRIA];
SET NOCOUNT ON;

declare @date datetime=dateadd(dd,-60,getdate())

DECLARE @Pending BIGINT = 0;

SELECT @Pending = @Pending + COUNT_BIG(*)
FROM RepOutSMSSentMessagesDetail
WHERE SystemApiId is null and date>=@date

PRINT ''Pendientes totales: '' + CAST(@Pending AS VARCHAR(30));

IF @Pending = 0
BEGIN
    PRINT ''No hay registros pendientes. Se eliminará el job.'';

    EXEC msdb.dbo.sp_delete_job
        @job_name = N''JOB_UpdateSystemApiId_Batch'';
END
ELSE
BEGIN
    PRINT ''Aún existen registros pendientes. El job seguirá programado para la siguiente ejecución.'';
END', 
		@database_name=N'CCReportsRIA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SCH_UpdateDataAreaId_2300', 
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

