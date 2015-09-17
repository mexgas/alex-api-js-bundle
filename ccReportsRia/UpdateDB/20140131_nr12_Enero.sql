/*
Autor: Raymundo Gonzalez
Fecha: 2014/01/31
Descripcion:
	Se renombran columnas de reportes para fix
	Se actualiza la tabla PivotReports para fix
	Se actualiza la tabla ReportsTotals para fix
	Se actualiza la tabla GroupByReports para fix
	Se agrega script del Job ShrinkLogCCReportsRia
	
Version requerida: 11
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '12'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'Columns rename'
		set @Sql='exec sp_rename ''RepOutAnswCalls.asig_tl'',''asigTl'',''COLUMN''
exec sp_rename ''RepOutAnswCalls.asig_nc'',''asigNc'',''COLUMN''
exec sp_rename ''RepOutAnswCalls.abdn_sis'',''abdnSis'',''COLUMN''
exec sp_rename ''RepInAnsw.time_max'',''timeMax'',''COLUMN''
exec sp_rename ''RepInAnsw.time_tot'',''timeTot'',''COLUMN''
exec sp_rename ''RepInAbnd.time_max'',''timeMax'',''COLUMN''
exec sp_rename ''RepInAbnd.time_tot'',''timeTot'',''COLUMN''
exec sp_rename ''RepAVRSDisposition.id_formato'',''idFormato'',''COLUMN''
exec sp_rename ''RepOutSubDispositions.wgId'',''workgroupId'',''COLUMN''
exec sp_rename ''RepOutDispositions.wgId'',''workgroupId'',''COLUMN'''

	EXEC(@Sql)
	
		set @process = 'PivotReports - Update'
		set @Sql='update PivotReports set complementColumns= ''date|campaignId|campaign|agentName|username|areaId|area|workgroupId|wg|dispositionId'' where id = 4040'

	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Update'
		set @Sql='update ReportsTotals set totalColumns=''sum:total|avg:asigTl|avg:asigNc|avg:Answered|avg:assigned|avg:abdnSis'' where id = 4130
update ReportsTotals set totalColumns=''sum:amount|avg:timeMax|avg:timeTot|sum:LT10|sum:LT20|sum:LT30|sum:LT40|sum:LT50|sum:LT60|sum:LT120|sum:LT180|sum:LT240|sum:LT300|sum:GT300'' where id = 3141
update ReportsTotals set totalColumns=''sum:amount|avg:timeMax|avg:timeTot|sum:LT10|sum:LT20|sum:LT30|sum:LT40|sum:LT50|sum:LT60|sum:LT120|sum:LT180|sum:LT240|sum:LT300|sum:GT300'' where id = 3142
update ReportsTotals set totalColumns=''sum:total|sum:abandonedCalls|avg:abandonedCallsPctg'' where id = 7010'

	EXEC(@Sql)
	
		set @process = 'GroupByReports - Update'
		set @Sql='update GroupByReports set columns=''inboundId|ACDGroup|callStatusId|areaId|area|workgroupId|wg|sum([count]):count:pivotGroup|max(callStatus_count):callStatus_count:pivotGroup'' where id =3030'

	EXEC(@Sql)

set @process = 'Job ShrinkLogCCReportsRia - Drop and Create'
		set @Sql='USE [msdb]

/****** Object:  Job [ShrinkLogCCReportsRia]    Script Date: 02/07/2014 13:40:58 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ShrinkLogCCReportsRia'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCReportsRia'', @delete_unused_schedule=1

/****** Object:  Job [ShrinkLogCCReportsRia]    Script Date: 02/07/2014 13:41:08 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/07/2014 13:41:08 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ShrinkLogCCReportsRia'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Shrink Log CCReportsRia'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 02/07/2014 13:41:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Checkpoint DB]    Script Date: 02/07/2014 13:41:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Checkpoint DB'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''CHECKPOINT'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 02/07/2014 13:41:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccReports_Log'''',1)'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Weekly'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20000101, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
