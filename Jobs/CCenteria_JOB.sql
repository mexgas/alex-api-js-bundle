/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/12/13
Description:

Database: CCenterRia
Required version: 125.17

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
SET @version = 125 --**********actualizar a 122 sin fix
SET @versionfix = 17
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
@actualVersion >= @version 
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
        @active_end_time=55959
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

    set @process = 'CREATE JOB CW (Callback/abandoned update),(Campaign summary)'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1
end

if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW (Callback/abandoned update),(Campaign summary)'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW (Callback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1
end

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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW (Callback/abandoned update),(Campaign summary)'', 
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
		@enabled=1, 
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
/****** Object:  Step [Run sp]    Script Date: 27/11/2023 04:10:50 p. m. ******/
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
-- Delete Old Records New Version Febrero 2024 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int
declare @date datetime

set @idSqlCmd = 0
set @sqlCmd  =''''''''
set @days = 30

set @date =dateadd(dd, -@days, getdate())


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
select distinct A.callout_id
from ccoCallsOutSource A
inner join ccoLogDials b on A.callout_id = b.callout_id
where b.fecha < dateadd(dd, -@days, getdate())

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccBorrardasReciclaje'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccLogCampsAgentesDia'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table cclogInfo'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccUploadTemporal'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogReciclaje where fecha < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionCamps where Fecha < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionEspecialidad where Fecha < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAlog where operationDate < @date'''', 0, 0)
insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete from B from ccRIAChat_Log A inner join ccChatLog_AreaWg B on A.ChatID=B.ChatID  where A.fecha_chat < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRiaChat_log where fecha_chat < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIALogAgentesNotReady where fecha < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_logDial_id where timestamp < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete xxclientehistorial where fechaAct < @date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccCallsIn where cal_Inicio < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cccallsreject where cal_inicio < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia where fecha < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia_Dialog where fecha_Dialog < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesNotReady where fecha < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogLogin where fecha < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogtransfers where fechaFin < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccriachats where chatDate < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_Calid where timestamp < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivrcallsin where date < @date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivroptions where date < @date'''', 0, 1)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials where fecha < @date'''', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete a from cchistoriallistanegra as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id and A.fecha<@date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete a from ccoWorkingTable as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id and cal_fechaDial<@date'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete a from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id and cal_fecha<@date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete a from ccoCallsOut as a  inner join #ccoCallsOutSourceIds b on  a.callout_id = b.callout_id where a.cal_Inicio<@date'''', 0, 1)

--quita los calloutId que existen registros recientes
insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('''';with logDialsMax as(
select b.callout_id,MAX(b.fecha) fecha from #ccoCallsOutSourceIds A
inner join ccoLogDials b on A.callout_id = b.callout_id
group by b.callout_id
)
delete B from logDialsMax A
inner join #ccoCallsOutSourceIds B on A.callout_id=B.callout_id
where @date>A.fecha'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete a from ccoCallsOutSource a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id and cal_fechaDial<@date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete a from ccoCallPriorityOrder a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id where a.callout_id = b.callout_id'''', 0, 1)


while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
    begin
        set rowcount 1
            select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
        set rowcount 0
        
		--print (@sqlCmd)
		BEGIN TRY  
    		exec sp_executesql @sqlCmd, N''''@date datetime'''', @date
		END TRY  
		BEGIN CATCH  
		    SELECT ERROR_NUMBER() AS ErrorNumber  ,ERROR_MESSAGE() AS ErrorMessage;  
		END CATCH;   

		

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
		@freq_interval=92, 
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
EndSave:'
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
	
	set @process = 'CREATE JOB CW Update TimeZones'
    set @sql = 'USE [msdb]
	
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW Update TimeZones'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''CW Update TimeZones'', @delete_unused_schedule=1
end

/****** Object:  Job [CW Update TimeZones]    Script Date: 07/03/2023 03:46:46 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 07/03/2023 03:46:46 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Update TimeZones'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Inserta registros nuevos en la tabla de ccTimeZoneArea en caso de que la lada exista en la tabla de Series pero no en ccTimeZoneArea, valida contra las excepciones de horario de verano del gobierno de México'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert in TimeZoneArea]    Script Date: 07/03/2023 03:46:47 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Insert in TimeZoneArea'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=5, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''-- Insert new Rows in ccTimeZoneArea from Series if not Exists


insert into cctimezonearea (id_country,area,location,tz_standard,tz_daylight,locality)

select
1 as id_country,
CLD as area,
estado as location,
--ASIGNACION ZONA HORARIA ESTANDAR
--UTC-5
CASE WHEN ESTADO like ''''qroo%''''
THEN ''''32''''
--UTC-6
WHEN ESTADO in (''''CHIH'''',''''DGO'''',''''ZAC'''',''''JAL'''',''''COAH'''',''''NL'''',''''TAMPS'''',
''''SLP'''',''''GTO'''',''''AGS'''',''''QRO'''',''''HGO'''',''''VER'''',''''MICH'''',''''COL'''',''''MEX'''',''''CDMX'''',''''MOR'''',''''TLAX'''',''''PUE'''',''''GRO'''',''''OAX'''',
''''TAB'''',''''CHIS'''',''''CAMP'''',''''YUC'''') OR(MUNICIPIO=''''BAHIA DE BANDERAS'''' AND ESTADO=''''NAY'''')
THEN ''''64''''
--UTC-7
when ESTADO in (''''SON'''',''''SIN'''',''''BCS'''',''''NAY'''') 
then ''''128''''
--UTC-8
WHEN ESTADO in (''''BC'''')
THEN ''''256''''
ELSE ''''64''''
end as tz_standard,
--validaciones para zona horaria en verano.
-- 1. Valida si pertenece a los municipios correspondientes a la fraccion 1  
case when MUNICIPIO in(
''''Acuna'''', ''''Allende'''', ''''Guerrero'''', ''''Hidalgo'''', ''''Jimenez'''', ''''Morelos'''',
''''Nava'''', ''''Ocampo'''', ''''Piedras Negras'''', ''''Villa Union'''', ''''Zaragoza'''',
''''Anahuac'''',''''Nuevo Laredo'''', ''''Guerrero'''', ''''Mier'''', ''''Miguel Aleman'''', 
''''Camargo'''', ''''Gustavo Diaz Ordaz'''', ''''Reynosa'''', ''''Rio Bravo'''',
''''Valle Hermoso'''', ''''Matamoros'''') and ESTADO in (''''NL'''',''''COAH'''',''''TAMPS'''') 
then ''''32''''
--2 valida si pertenece a los municipios correspondientes a la fraccion 2
WHEN MUNICIPIO in (''''Coyame del Sotol'''', ''''OJINAGA'''', ''''Manuel Benavides'''') and ESTADO =''''CHIH''''
then ''''128''''
--3 fraccion 3
when ESTADO=''''BC'''' or(MUNICIPIO in (''''Janos'''', ''''Ascension'''',''''Juarez'''', ''''Praxedis G. Guerrero'''' , ''''Guadalupe'''') and MUNICIPIO =''''CHIH'''')
then ''''128''''
--4 NO CAMBIAN DE HORARIO - COLOCAR ZONA HORARIA DE ACUERDO AL ESTADO.
--UTC-5
WHEN ESTADO like ''''qroo%''''
THEN ''''32''''
--UTC-6
WHEN ESTADO in (''''CHIH'''',''''DGO'''',''''ZAC'''',''''JAL'''',''''COAH'''',''''NL'''',''''TAMPS'''',
''''SLP'''',''''GTO'''',''''AGS'''',''''QRO'''',''''HGO'''',''''VER'''',''''MICH'''',''''COL'''',''''MEX'''',''''CDMX'''',''''MOR'''',''''TLAX'''',''''PUE'''',''''GRO'''',''''OAX'''',
''''TAB'''',''''CHIS'''',''''CAMP'''',''''YUC'''') OR(MUNICIPIO=''''BAHIA DE BANDERAS'''' AND ESTADO=''''NAY'''')
THEN ''''64''''
--UTC-7
when ESTADO in (''''SON'''',''''SIN'''',''''BCS'''',''''NAY'''')
then ''''128''''
ELSE ''''64''''
end
 as tz_daylight,
MUNICIPIO as locality
from(
select s.POBLACION as POBLACIONSERIES,s.MUNICIPIO,s.CLD,s.ESTADO,t.area,t.locality,t.location from series s left join cctimezonearea t
on t.area=s.CLD and t.id_country=1 and s.ESTADO=t.location
and t.locality=s.MUNICIPIO
)x
where locality is null
group by CLD ,
estado ,
MUNICIPIO 
order by municipio

'', 
		@database_name=N''CCenterRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every Sunday'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20230307, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N''06a91baa-512b-45c8-a16a-79482b1e0d7d''
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

     set @process = 'DEV1-409 Create Job TruncateccDispositionDashboardResult'
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''TruncateccDispositionDashboardResult'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''TruncateccDispositionDashboardResult'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 20/09/2023 10:42:30 a. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''TruncateccDispositionDashboardResult'', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N''No description available.'', 
        @category_name=N''Nuxiba'', 
        @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [TruncateSaveDispositionResult]    Script Date: 20/09/2023 10:42:30 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''TruncateSaveDispositionResult'', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N''TSQL'', 
        @command=N''exec ccspSaveDispositionResult @action=0'', 
        @database_name=N''CCenterRIA'', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''SchTruncateSaveDispositionResult'', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20230920, 
        @active_end_date=99991231, 
        @active_start_time=1000, 
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