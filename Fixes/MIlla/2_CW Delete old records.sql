USE [msdb]


/****** Object:  Job [CW Delete old records]    Script Date: 27/11/2023 04:10:49 p. m. ******/
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'CW Delete old records') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N'CW Delete old records', @delete_unused_schedule=1
end

/****** Object:  Job [CW Delete old records]    Script Date: 27/11/2023 04:10:49 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 27/11/2023 04:10:49 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Nuxiba' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Nuxiba'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CW Delete old records', 
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
/****** Object:  Step [Run sp]    Script Date: 27/11/2023 04:10:50 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run sp', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/***********************************************/
-- Delete Old Records New Version Febrero 2023 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int

set @idSqlCmd = 0
set @sqlCmd  =''''
set @days = 15

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
and callout_id not  in (select callout_id from ccoCallsOut  where cal_inicio > dateadd(dd, -@days, getdate() ))
and callout_id not  in (select callout_id from ccoLogDials where fecha > dateadd(dd, -@days, getdate() ))

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''truncate table ccBorrardasReciclaje'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''truncate table ccLogCampsAgentesDia'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''truncate table cclogInfo'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''truncate table ccUploadTemporal'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccLogReciclaje where fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccPosicionCamps where Fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccPosicionEspecialidad where Fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccRIAlog where operationDate < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccRiaChat_log where fecha_chat < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete xxclientehistorial where fechaAct < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccCallsIn where cal_Inicio < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete cccallsreject where cal_inicio < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccLogAgentesDia where fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccLogAgentesNotReady where fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccLogLogin where fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccLogtransfers where fechaFin < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccriachats where chatDate < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ivrcallsin where date < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ivroptions where date < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete ccoLogDials where fecha < dateadd(dd, -'' + cast(@days as nvarchar(max)) + '', getdate())'', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from cchistoriallistanegra as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from ccoWorkingTable as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from ccoCallsOut as a  inner join #ccoCallsOutSourceIds b on  a.callout_id = b.callout_id'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from ccoLogDials as a  inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from ccoCallsOutSource a inner join #ccoCallsOutSourceIds b on   a.callout_id = b.callout_id where a.callout_id = b.callout_id'', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''delete a from ccoCallPriorityOrder a inner join #ccoCallsOutSourceIds b on   a.callout_id = b.callout_id where a.callout_id = b.callout_id'', 0, 1)


while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
    begin
        set rowcount 1
            select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
        set rowcount 0

        exec(@sqlCmd)

        WAITFOR DELAY ''00:00:01''

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
                WAITFOR DELAY ''00:00:01''
            end

        update #sqlCmdDeleteOldRecords
        set [status] = 1
        where idSqlCmd = @idSqlCmd
    end

drop table #sqlCmdDeleteOldRecords
drop table #ccoCallsOutSourceIds', 
		@database_name=N'CCenterRIA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Tuesday, Thursday and Saturday at 3:00 am', 
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
		@active_end_time=235959, 
		@schedule_uid=N'4d390510-bd58-42cb-b310-7d7a8ce310b4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave: