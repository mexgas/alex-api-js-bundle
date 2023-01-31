/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion = @version and @actualVersionFix >= @versionfix - 1) or
@actualVersion = @version +1
BEGIN
    BEGIN TRAN

    BEGIN TRY

    set @process = 'CREATE JOB CleanNodeBaseXCCenterRIA'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CleanNodeBaseXCCenterRIA'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''CleanNodeBaseXCCenterRIA'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CleanNodeBaseXCCenterRIA'', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''Move the history database records'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MoveNodeBaseXChat]    Script Date: 03/09/2021 07:41:39 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXChat'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''exec ccsp_CleanNodeBaseX 1'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MoveNodeBaseXEmail]    Script Date: 03/09/2021 07:41:39 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXEmail'', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''exec ccsp_CleanNodeBaseX 3'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MoveNodeBaseXTwitter]    Script Date: 03/09/2021 07:41:39 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXTwitter'', 
        @step_id=3, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''exec ccsp_CleanNodeBaseX 4'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CleanNodeBaseXCCenterRIA'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=4, 
        @freq_subday_interval=30, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20180911, 
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
    EXEC(@sql)

    set @process = 'CREATE JOB CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
    set @sql = 'USE [msdb]

if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1
end

/****** Object:  Job [CW (AutoStart),(Callback/abandoned update),(Campaign summary)]    Script Date: 11/10/2021 11:02:12 a. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 11/10/2021 11:02:12 a. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Se funcioan los jobs CW AutoStart, CW Callback/abandoned update y CW Campaign summary'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Callback/abandoned update]    Script Date: 11/10/2021 11:02:13 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Callback/abandoned update'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @callout_id_array varchar(max), @SQL varchar(max)
set @callout_id_array=''''|''''

select @callout_id_array=@callout_id_array+coalesce('''',''''+cast(callout_id as varchar(10)), @callout_id_array, '''''''')
from ccRIAUpdateCallBack_Abandon where minCallBackAbandonXpire < getdate()

if len(@callout_id_array)>1
 begin
  select @callout_id_array=replace(@callout_id_array, ''''|,'''', '''''''')

  set @SQL=''''delete ccoWorkingTable with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
  exec(@SQL)

  set @SQL=''''delete ccRIAUpdateCallBack_Abandon with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
  exec(@SQL)

  set @SQL=''''update ccoCallBacks with(rowlock) set [status] = 4, schedulerStatus = 1 where callout_id in (''''+@callout_id_array+'''') and [status] = 0''''
  exec(@SQL)
 end'', 
		@database_name=N''CCenterRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Campaign summary]    Script Date: 11/10/2021 11:02:13 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Campaign summary'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccsp_RIAGetCampsNvosCB 0,2,0'', 
		@database_name=N''CCenterRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Commons Tasj'', 
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
		@active_end_time=235959, 
		@schedule_uid=N''e0e3a902-8fb2-48b8-8a14-b5f5d0f24216''
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

    set @process = 'CREATE JOB CW (AutoStart)'
    set @sql = 'USE [msdb]

if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW (AutoStart)'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart)'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW (AutoStart)'', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Se coloca independiente el autostart'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW AutoStart]    Script Date: 28/09/2021 11:53:59 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW AutoStart'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccsp_OutGenerateAutoinicio'', 
		@database_name=N''CCenterRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Commons Tasj'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20151022, 
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
    EXEC(@sql)

    set @process = 'CREATE JOB CW Delete old records'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW Delete old records'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 03/09/2021 07:46:53 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''No description available.'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 03/09/2021 07:46:53 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=1, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''/***********************************************/
-- Delete Old Records New Version Febrero 2016 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int

set @idSqlCmd = 0
set @sqlCmd  =''''''''
set @days = 30

create table #sqlCmdDeleteOldRecords(
idSqlCmd int identity primary key,
sqlCmd nvarchar(max) not null,
[status] int not null,
isReplicated bit not null
)

create table #ccoCallsOutSourceIds(
callout_id int not null primary key
)

insert into #ccoCallsOutSourceIds (callout_id)
select callout_id
from ccoCallsOutSource
where cal_fechadial < dateadd(dd, -@days, getdate())

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccBorrardasReciclaje'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccLogCampsAgentesDia'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table cclogInfo'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccUploadTemporal'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogReciclaje where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionCamps where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionEspecialidad where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAlog where operationDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRiaChat_log where fecha_chat < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete xxclientehistorial where fechaAct < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccCallsIn where cal_Inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cccallsreject where cal_inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogLogin where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogtransfers where fechaFin < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccriachats where chatDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivrcallsin where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivroptions where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cchistoriallistanegra from cchistoriallistanegra as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoWorkingTable from ccoWorkingTable as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccocallbacks from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOut from ccoCallsOut as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials from ccoLogDials as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOutSource from ccoCallsOutSource as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
    begin
        set rowcount 1
            select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
        set rowcount 0

        exec(@sqlCmd)

        WAITFOR DELAY ''''00:00:01''''

        while(SELECT count(*)
                FROM sys.dm_exec_requests a
                INNER JOIN sys.dm_exec_connections b
                ON a.session_id = b.session_id
                INNER JOIN sys.dm_exec_sessions c
                ON c.session_id = a.session_id
                CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
                WHERE a.session_id > 50
                AND a.session_id = @@SPID
                and d.text = @sqlCmd) > 0
            begin
                WAITFOR DELAY ''''00:00:01''''
            end

        update #sqlCmdDeleteOldRecords
        set [status] = 1
        where idSqlCmd = @idSqlCmd
    end

drop table #sqlCmdDeleteOldRecords
drop table #ccoCallsOutSourceIds'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Tuesday, Thursday and Saturday at 3:00 am'', 
        @enabled=1, 
        @freq_type=8, 
        @freq_interval=84, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=1, 
        @active_start_date=20041022, 
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
EndSave:
'
    EXEC(@sql)

    set @process = 'CREATE JOB CW Stop inactive campaigns'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW Stop inactive campaigns'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''CW Stop inactive campaigns'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Stop inactive campaigns'', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''No description available.'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 03/09/2021 07:48:09 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=1, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''/*
Detener campa?as inactivas:
    Localiza campa?as que no tienen agentes asignados (Base de Reportes)
    Localiza campa?que no tienen informacion en ccGenOutCallDials (Base de Reportes)
    Contabiliza las llamadas de la ultima semana en ccoLogDials (Base de Reportes)
    Genera una media de llamadas por dia de la campa?a, previas a la ultima semana en base a ccoLogDials (Base de Reportes)
    Verifica que las llamadas de la ultima semana sean mayores a la media por campa?a multiplicado por el porcentaje definido en el setting (Base de Reportes, String de CCenterRIA)
    Si las llamadas no superan el porcentaje de la media, son detenidas junto a las campa?as que no tienen agentes (incluye autoinicio en CCenterRIA)
*/
set nocount on
declare @cam_id int, @iEjecutar int, @Ejecutar bit, @dias int, @ReportServer varchar(50), @SQL varchar(4000)
select @iEjecutar = cast(valor as int) from ccSettings where setting_id = 86
select @Ejecutar = cast(@iEjecutar as bit)

if @Ejecutar = 1
begin

select @ReportServer = valor from ccSettings where setting_id = 22
select @ReportServer = @ReportServer + ''''.dbo.'''', @dias = 8 -- dias de rango (semana)

create table temp_cam_id (cam_id int)

set @SQL=''''declare @cccamps as table(cam_id int)
insert into @cccamps select cam_id from ccCamps where cam_procesando = 1 and cam_id not in 
(select cam_id from ccCampsAgente) union 
select cam_id from ccCamps where cam_procesando = 1 and cam_id not in 
(select cam_id from ''''+@ReportServer+''''ccGenOutCallDials)

insert into temp_cam_id select total.cam_id from (select c.cam_id, isnull(count(l.cam_id), 0) LastCalls_Week
from ''''+@ReportServer+''''ccoLogDials l right join ccCamps c 
on c.cam_id = l.cam_id and l.fecha > (getdate()-''''+cast(@dias as varchar(10))+'''')
where c.cam_id not in (select cam_id from @cccamps) and c.cam_procesando = 1
group by c.cam_id) 
total join
(select cam_id, avg(suma) mediaXdia, avg(suma)*cast(''''+cast(@iEjecutar as varchar(10))+'''' as decimal(18,2))/100 mediaXsetting
from (SELECT cam_id, convert(varchar(10), timegroup, 112) fecha, count(*) suma
FROM ''''+@ReportServer+''''ccGenOutCallDials where timegroup < (getdate()-''''+cast(@dias as varchar(10))+'''')
and cam_id not in (select cam_id from @cccamps)
group by cam_id, convert(varchar(10), timegroup, 112)) pre_media group by cam_id) 
media on total.cam_id = media.cam_id where total.LastCalls_Week < media.mediaXsetting
union
select camp.cam_id from @cccamps camp
order by 1''''

exec(@SQL)

DECLARE camp CURSOR FOR 
    select cam_id from temp_cam_id
OPEN camp

FETCH NEXT FROM camp
INTO @cam_id
WHILE @@FETCH_STATUS = 0
BEGIN
   exec ccsp_OUTCampMovs @cam_id, 0, 1
   update ccCamps set cam_bnew = 4 where cam_id = @cam_id
   FETCH NEXT FROM camp
   INTO @cam_id
END

CLOSE camp
DEALLOCATE camp

drop table temp_cam_id
end
set nocount off'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every Sunday at 5:00'', 
        @enabled=1, 
        @freq_type=8, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=30, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=1, 
        @active_start_date=20100201, 
        @active_end_date=99991231, 
        @active_start_time=50000, 
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

    set @process = 'CREATE JOB DNCKillList'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''DNCKillList'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''DNCKillList'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 03/09/2021 07:51:11 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DNCKillList'', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''Deletes from cc_KillList table according to an specific time (setting 215)'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccKillList]    Script Date: 03/09/2021 07:51:11 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccKillList'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''exec cc_DNCKillList'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccKillList'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=8, 
        @freq_subday_interval=1, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20190531, 
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
    EXEC(@sql)

    set @process = 'CREATE JOB '
    set @sql = ''
    EXEC(@sql)

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END