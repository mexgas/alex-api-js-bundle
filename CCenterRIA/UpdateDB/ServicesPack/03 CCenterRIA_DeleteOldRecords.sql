Use CCenterRIA;

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



    set @process = 'CREATE JOB CW Delete old records'
    set @sql = 'USE [msdb]

/****** Object:  Job [CW Delete old records]    Script Date: 30/03/2026 ******/
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW Delete old records'') begin
    EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1
END
/****** Object:  Job [CW Delete old records]    Script Date: 30/03/2026 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 30/03/2026 ******/
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
/****** Object:  Step [Delete Call And catalog]    Script Date: 30/03/2026 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Delete Call And catalog'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''/*******************************************************************/
-- Delete Old Records New Version - March 2026
/*******************************************************************/

SET NOCOUNT ON;

DECLARE @idSqlCmd int;
DECLARE @sqlCmd nvarchar(max);
DECLARE @sqlCmdExec nvarchar(max);
DECLARE @days int;
DECLARE @date datetime;
DECLARE @batchSize int;

SET @idSqlCmd = 0;
SET @sqlCmd  = '''''''';
SET @sqlCmdExec = '''''''';
SET @days = 30;
SET @batchSize = 4000;
SET @date = DATEADD(dd, -@days, GETDATE());

CREATE TABLE #sqlCmdDeleteOldRecords(
    idSqlCmd int identity primary key,
    sqlCmd nvarchar(max) not null,
    [status] int not null,
    isReplicated bit not null
);

CREATE TABLE #ccoCallsOutSourceIds(
    callout_id int not null primary key
);

INSERT INTO #ccoCallsOutSourceIds (callout_id)
SELECT DISTINCT c.callout_id
FROM ccoCallsOutSource c
WHERE c.cal_fechaDial < @date
AND NOT EXISTS (
    SELECT 1 
    FROM ccoLogDials l 
    WHERE l.callout_id = c.callout_id 
    AND l.fecha >= @date
);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''truncate table ccBorrardasReciclaje'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''truncate table ccLogCampsAgentesDia'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''truncate table cclogInfo'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''truncate table ccUploadTemporal'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccLogReciclaje where fecha < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccPosicionCamps where Fecha < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccPosicionEspecialidad where Fecha < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccRIAlog where operationDate < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) B from ccRIAChat_Log A inner join ccChatLog_AreaWg B on A.ChatID=B.ChatID where A.fecha_chat < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccRiaChat_log where fecha_chat < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccRIALogAgentesNotReady where fecha < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccRIAWorkGroup_logDial_id where timestamp < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) xxclientehistorial where fechaAct < @date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccCallsIn where cal_Inicio < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) cccallsreject where cal_inicio < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccLogAgentesDia where fecha < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccLogAgentesDia_Dialog where fecha_Dialog < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccLogAgentesNotReady where fecha < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccLogLogin where fecha < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccLogtransfers where fechaFin < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccriachats where chatDate < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccRIAWorkGroup_Calid where timestamp < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ivrcallsin where date < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ivroptions where date < @date'''', 0, 1);

/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) ccoLogDials where fecha < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) from ccoCallsOutData where callDate < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) from ccoLogDialsData where callDate < @date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) a from cchistoriallistanegra as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id and A.fecha<@date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) a from ccoWorkingTable as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id and cal_fechaDial<@date'''', 0, 0);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) a from ccocallbacks as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id where cal_fecha<@date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) a from ccoCallsOut as a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id where a.cal_Inicio<@date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) a from ccoCallsOutSource a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id and cal_fechaDial<@date'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) a from ccoCallPriorityOrder a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id'''', 0, 1);

INSERT INTO #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated) 
VALUES (''''delete TOP (@batchSize) A from ccoCallPriorityOrder A left join ccoCallsOutSource B on A.callout_id=B.callout_id where B.callout_id is null'''', 0, 1);

/******************************************************************/
/* BATCH EXECUTION ENGINE */
/******************************************************************/
DECLARE @RowsAffected int;
DECLARE @isBatchCmd bit;

WHILE (SELECT COUNT(*) FROM #sqlCmdDeleteOldRecords WHERE [status] = 0) > 0
BEGIN
    SELECT TOP 1 
        @idSqlCmd = idSqlCmd, 
        @sqlCmd = SqlCmd 
    FROM #sqlCmdDeleteOldRecords 
    WHERE [status] = 0 
    ORDER BY idSqlCmd;
    
    SET @RowsAffected = 1;
    SET @sqlCmdExec = @sqlCmd;
    SET @isBatchCmd = CASE WHEN @sqlCmd LIKE ''''%@batchSize%'''' THEN 1 ELSE 0 END;

    IF @isBatchCmd = 1
    BEGIN
        SET @sqlCmdExec = @sqlCmdExec + N''''; '''' + CHAR(13) + CHAR(10) + N''''SET @RowsAffected_OUT = @@ROWCOUNT;'''';
    END
	--PRINT ''''--------------------------------------------------'''';
	--PRINT @sqlCmdExec;
    WHILE @RowsAffected > 0
    BEGIN
        BEGIN TRY  
            IF @isBatchCmd = 1
            BEGIN
                EXEC sp_executesql 
                    @stmt = @sqlCmdExec, 
                    @params = N''''@date datetime, @batchSize int, @RowsAffected_OUT int OUTPUT'''', 
                    @date = @date, 
                    @batchSize = @batchSize,
                    @RowsAffected_OUT = @RowsAffected OUTPUT;
            END
            ELSE
            BEGIN
                EXEC sp_executesql 
                    @stmt = @sqlCmdExec, 
                    @params = N''''@date datetime, @batchSize int'''', 
                    @date = @date, 
                    @batchSize = @batchSize;

                SET @RowsAffected = 0;
            END
            
            IF @RowsAffected > 0
            BEGIN
                WAITFOR DELAY ''''00:00:01'''';
            END
        END TRY  
        BEGIN CATCH  
            INSERT INTO dbo.ccSqlCmdDeleteOldRecords_Errors (idSqlCmd, sqlCmd, errorNumber, errorMessage)
            VALUES (@idSqlCmd, @sqlCmd, ERROR_NUMBER(), ERROR_MESSAGE());

            SET @RowsAffected = 0; 
        END CATCH;   
    END

    UPDATE #sqlCmdDeleteOldRecords
    SET [status] = 1
    WHERE idSqlCmd = @idSqlCmd;
END

DROP TABLE #sqlCmdDeleteOldRecords;
DROP TABLE #ccoCallsOutSourceIds;'', 
		@database_name=N''CCenterRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete SMS]    Script Date: 30/03/2026 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Delete SMS'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''/***********************************************/
-- Delete Old Records New Version - March 2026
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @sqlCmdExec nvarchar(max)
declare @days int
declare @date datetime
declare @batchSize int

set @idSqlCmd = 0
set @sqlCmd  =''''''''
set @sqlCmdExec = ''''''''
set @days = 180
set @batchSize = 4000

set @date =dateadd(dd, -@days, getdate())


create table #sqlCmdDeleteOldRecords(
idSqlCmd int identity primary key,
sqlCmd nvarchar(max) not null,
[status] int not null,
isReplicated bit not null
)

create table #smsOutSourceIds(
smsout_id int not null primary key
)

insert into #smsOutSourceIds (smsout_id)
select distinct A.smsout_id
from smsOutSource A
where A.sms_dateDial < @date
and not exists (
    select 1 
    from smsccoLogDial b 
    where b.smsout_id = A.smsout_id 
    and b.smsDate >= @date
)

/******************************************************************/
/* Delete by date because rows in smsccoLogDial > smsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete TOP (@batchSize) smsccoLogDial where smsDate < @date'''', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete TOP (@batchSize) a from smsWorkingTable as a inner join #smsOutSourceIds as b on a.smsout_id = b.smsout_id and sms_dateDial<@date'''', 0, 0)


insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete TOP (@batchSize) a from smsoutSourceMessage a inner join #smsOutSourceIds b on a.smsout_id = b.smsout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete TOP (@batchSize) a from smsOutSource a inner join #smsOutSourceIds b on a.smsout_id = b.smsout_id and sms_dateDial<@date'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete TOP (@batchSize) a from ccSqlCmdDeleteOldRecords_Errors where errorDate<@date'''', 0, 1)


DECLARE @RowsAffected int;
DECLARE @isBatchCmd bit;

WHILE (SELECT COUNT(*) FROM #sqlCmdDeleteOldRecords WHERE [status] = 0) > 0
BEGIN
    SELECT TOP 1 
        @idSqlCmd = idSqlCmd, 
        @sqlCmd = SqlCmd 
    FROM #sqlCmdDeleteOldRecords 
    WHERE [status] = 0 
    ORDER BY idSqlCmd;
    
    SET @RowsAffected = 1;
    SET @sqlCmdExec = @sqlCmd;
    SET @isBatchCmd = CASE WHEN @sqlCmd LIKE ''''%@batchSize%'''' THEN 1 ELSE 0 END;

    IF @isBatchCmd = 1
    BEGIN
        SET @sqlCmdExec = @sqlCmdExec + N''''; '''' + CHAR(13) + CHAR(10) + N''''SET @RowsAffected_OUT = @@ROWCOUNT;'''';
    END

    --PRINT ''''--------------------------------------------------'''';
    --PRINT @sqlCmdExec;

    WHILE @RowsAffected > 0
    BEGIN
        BEGIN TRY  
            IF @isBatchCmd = 1
            BEGIN
                EXEC sp_executesql 
                    @stmt = @sqlCmdExec, 
                    @params = N''''@date datetime, @batchSize int, @RowsAffected_OUT int OUTPUT'''', 
                    @date = @date, 
                    @batchSize = @batchSize,
                    @RowsAffected_OUT = @RowsAffected OUTPUT;
            END
            ELSE
            BEGIN
                EXEC sp_executesql 
                    @stmt = @sqlCmdExec, 
                    @params = N''''@date datetime, @batchSize int'''', 
                    @date = @date, 
                    @batchSize = @batchSize;

                SET @RowsAffected = 0;
            END
            
            IF @RowsAffected > 0
            BEGIN
                WAITFOR DELAY ''''00:00:01'''';
            END
        END TRY  
        BEGIN CATCH  
            INSERT INTO dbo.ccSqlCmdDeleteOldRecords_Errors (idSqlCmd, sqlCmd, errorNumber, errorMessage)
            VALUES (@idSqlCmd, @sqlCmd, ERROR_NUMBER(), ERROR_MESSAGE());

            SET @RowsAffected = 0; 
        END CATCH;   
    END

    UPDATE #sqlCmdDeleteOldRecords
    SET [status] = 1
    WHERE idSqlCmd = @idSqlCmd;
END

drop table #sqlCmdDeleteOldRecords
drop table #smsOutSourceIds'', 
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
EndSave:
'
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
