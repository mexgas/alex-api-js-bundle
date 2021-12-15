USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'Reporte Especial Servicios Legales') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N'Reporte Especial Servicios Legales', @delete_unused_schedule=1
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Reporte Especial Servicios Legales',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'Generación de reporte a las 10:00 pm con la información de la actividad del día relacionada con un tabla especial para el cliente.',
		@category_name=N'Nuxiba',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generar Reporte',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0,  @subsystem=N'TSQL',
		@command=N'exec ccspGetReportWithCods',
		@database_name=N'CCReportsRIA',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Enviar Correo',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0,  @subsystem=N'TSQL',
		@command=N'
declare @pathFile varchar(100)
set @pathFile=''C:\ReporteEspecial\''
declare @fileName varchar(200)
select @fileName=''gets_''+replace(convert(varchar, getdate(),3),''/'','''')+''.txt''

DECLARE @attachmentFile varchar(250);
SET @attachmentFile = @pathFile+@fileName

SELECT @attachmentFile


EXEC msdb.dbo.sp_send_dbmail
	@profile_name = ''notificationscw''
	,@recipients = ''eflores@nuxiba.com''
	,@copy_recipients =''eflores@nuxiba.com''
	,@body = ''Se adjunta el reporte de la operación del día en un archivo de texto separado por pipes''
	,@subject = ''Reporte especial NUXIBA'',
     @file_attachments=@attachmentFile;',
		@database_name=N'CCReportsRIA',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'10 pm',
		@enabled=1,
		@freq_type=8,
		@freq_interval=126,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=1,
		@active_start_date=20210520,
		@active_end_date=99991231,
		@active_start_time=235200,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave: