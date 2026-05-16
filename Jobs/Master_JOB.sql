
SET NOCOUNT ON

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

BEGIN TRAN

BEGIN TRY

    set @process = 'BEFORE CREATING DatabaseCentinella JOB'
    set @sql = 'USE [master];

IF OBJECT_ID(''dbo.userDatabases'', ''U'') IS NOT NULL
    DROP TABLE dbo.userDatabases;
IF OBJECT_ID(''dbo.indexMaintenance'', ''U'') IS NOT NULL
    DROP TABLE dbo.indexMaintenance;
IF OBJECT_ID(''dbo.logCentinella'', ''U'') IS NOT NULL
    DROP TABLE dbo.logCentinella;'
    EXEC(@sql)

    set @process = 'CREATE JOB DatabaseCentinella'
    set @sql = 'USE [msdb]
/****** Object:  Job [DatabaseCentinella] ******/
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''DatabaseCentinella'')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N''DatabaseCentinella'', @delete_unused_schedule = 1
END

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = N''Nuxiba'' AND category_class = 1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N''JOB'', @type = N''LOCAL'', @name = N''Nuxiba'';
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
                @enabled=1, 
                @notify_level_eventlog=0, 
                @notify_level_email=0, 
                @notify_level_netsend=0, 
                @notify_level_page=0, 
                @delete_level=0, 
                @description=N''Automated routine for SQL Server database maintenance and performance optimization. Includes dynamic index management, integrity checks (DBCC CHECKDB), and configurable backups via @enableBackups variable. Version March 2026'', 
                @category_name=N''Nuxiba'', 
                @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks] ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
                @step_id=1, 
                @cmdexec_success_code=0, 
                @on_success_action=1, 
                @on_success_step_id=0, 
                @on_fail_action=2, 
                @on_fail_step_id=0, 
                @retry_attempts=0, 
                @retry_interval=0, 
                @os_run_priority=0, @subsystem=N''TSQL'', 
                @command=N''use [master]

set nocount on

declare @idDb int
declare @dbName nvarchar(100)
declare @dbLog nvarchar(100)
declare @sql nvarchar(max)
declare @idIndex int
declare @tableName nvarchar(100)
declare @indexName nvarchar(100)
declare @process int
declare @firstSunday datetime
declare @idCmdSql int
declare @cmdSql nvarchar(max)
declare @maxTimeSeconds int
declare @maxTimeSecondsSunday int
declare @dateExecution datetime
declare @onlineOption nvarchar(3)
declare @enableBackups bit

set @idDb = 0
set @dbName = ''''''''
set @dbLog = ''''''''
set @sql = ''''''''
set @idIndex = 0
set @tableName = ''''''''
set @indexName = ''''''''
set @process = 1
set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
set @idCmdSql = 0
set @cmdSql = ''''''''
set @maxTimeSeconds = 7200
set @maxTimeSecondsSunday = 14400
set @dateExecution = getdate()

set @enableBackups = 0 


-- Determine if the edition supports ONLINE INDEX REBUILD (Enterprise, Developer, Evaluation = 3)
IF CAST(SERVERPROPERTY(''''EngineEdition'''') AS INT) = 3
    SET @onlineOption = ''''ON''''
ELSE
    SET @onlineOption = ''''OFF''''

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
        begin
                if exists (select * from sys.tables where name = ''''userDatabases'''')
                        drop table userDatabases

                if exists (select * from sys.tables where name = ''''indexMaintenance'''')
                        drop table indexMaintenance

                if exists (select * from sys.tables where name = ''''logCentinella'''')
                        drop table logCentinella
        end

if not exists (select * from sys.tables where name = ''''userDatabases'''')
        begin
                create table dbo.userDatabases(
                        [idDb] int not null identity primary key,
                        [dbName] nvarchar(100) not null,
                        [dbLog] nvarchar(100) not null,
                        [status] bit not null
                )

                CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
                (
                        [dbName] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

                CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
                (
                        [status] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
        end
else
        begin
                TRUNCATE TABLE master.dbo.userDatabases
        end

if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
        begin
                create table dbo.indexMaintenance(
                        [idIndex] int not null identity primary key,
                        [dbName] nvarchar(100) not null,
                        [tableName] nvarchar(100) not null,
                        [indexName] nvarchar(100) not null,
                        [indexType] nvarchar(100) not null,
                        [indexFragmentation] decimal(5,2) not null,
                        [actionType] nvarchar(20) not null,
                        [status] bit not null
                )

                CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
                (
                        [dbName] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

                CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
                (
                        [tableName] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

                CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
                (
                        [status] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
        end
else
        begin
                TRUNCATE TABLE master.dbo.indexMaintenance
        end

if not exists (select * from sys.tables where name = ''''logCentinella'''')
        begin
                create table dbo.logCentinella(
                        [idCmdSql] int not null identity primary key,
                        [date] datetime not null,
                        [cmdSql] nvarchar(max) not null,
                        [status] int not null,
                        [dateStart] datetime not null,
                        [dateEnd] datetime not null,
                        [executionTimeSeconds] int not null
                )

                CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
                (
                        [date] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

                CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
                (
                        [status] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
        end

insert into userDatabases
select db_name(database_id), '''''''', 0
from sys.master_files
where state = 0
and has_dbaccess(db_name(database_id)) = 1
and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
and type = 0

update userDatabases
set [dbLog] = name
from sys.master_files
inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)



while (select count(*) from userDatabases where status = 0) > 0
        begin
                set rowcount 1
                        select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
                set rowcount 0

                select @sql = ''''use ['''' + @dbName + '''']

insert into master.dbo.indexMaintenance
SELECT 
    '''''''''''' + @dbName + '''''''''''',
    OBJECT_NAME(ind.OBJECT_ID),
    ind.name,
    indexstats.index_type_desc,
    indexstats.avg_fragmentation_in_percent,
    CASE 
        WHEN indexstats.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN ''''''''REORGANIZE''''''''
        WHEN indexstats.avg_fragmentation_in_percent > 30 THEN ''''''''REBUILD''''''''
        ELSE ''''''''NONE''''''''
    END,
    0
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''''''''LIMITED'''''''') indexstats
INNER JOIN sys.indexes ind 
    ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
INNER JOIN sys.objects obj 
        ON (obj.object_id = indexstats.object_id AND obj.type = ''''''''U'''''''')
WHERE indexstats.avg_fragmentation_in_percent >= 10
AND indexstats.page_count >= 50
ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

                exec(@sql)

                update userDatabases
                set status = 1
                where idDb = @idDb
        end


while (select count(*) from indexMaintenance where status = 0 and actionType <> ''''NONE'''') > 0
        begin
                set rowcount 1
                        select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 and actionType <> ''''NONE'''' order by idIndex
                set rowcount 0

                select @sql = ''''use ['''' + @dbName + ''''] ''''

                declare @action nvarchar(20)
                select @action = actionType from indexMaintenance where idIndex = @idIndex

                if @action = ''''REORGANIZE''''
                        begin
                                select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )''''
                                insert into logCentinella
                                select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

                                select @sql = ''''use ['''' + @dbName + ''''] UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN''''
                                insert into logCentinella
                                select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0
                        end
                else if @action = ''''REBUILD''''
                        begin
                                                                select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( FILLFACTOR = 100, PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = '''' + @onlineOption + '''' )''''
                                insert into logCentinella
                                select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0
                        end

                update indexMaintenance
                set status = 1
                where idIndex = @idIndex
        end

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
        begin
                update userDatabases
                set status = 0

                while (select count(*) from userDatabases where status = 0) > 0
                        begin
                                set rowcount 1
                                        select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
                                set rowcount 0

                                select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''

                                insert into logCentinella
                                select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0 
                                
                                if @enableBackups = 1
                                begin
                                    select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

drop table #RutaBak

BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

                                    insert into logCentinella
                                    select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0                         
                                end

                                if @dbName in(''''CCenterRIA'''',''''CCRecorderRIA'''',''''CCReportsRIA'''',''''CW_CRMx'''') begin

                                        select @sql = ''''use ['''' + @dbName + ''''] ALTER DATABASE ''''+@dbName+ '''' SET RECOVERY SIMPLE''''

                                        insert into logCentinella
                                        select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0                                                 
                                
                                end                             

                                update userDatabases
                                set status = 1
                                where idDb = @idDb
                        end

                if @enableBackups = 1
                begin
                    select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

drop table #RutaBak''''

                    insert into logCentinella
                    select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0
                end
        end

set @dateExecution = getdate()

while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
        begin
                set rowcount 1
                        select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
                set rowcount 0

                update logCentinella
                set dateStart = getdate()
                where idCmdSql = @idCmdSql

                BEGIN TRY
                        exec(@cmdSql)
                END TRY
                BEGIN CATCH
                        select @cmdSql AS FailedCommand, ERROR_MESSAGE() AS ErrorMessage;
                END CATCH

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
                                and d.text = @cmdSql) > 0
                        begin
                                WAITFOR DELAY ''''00:00:01''''
                        end

                if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
                        begin
                                if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
                                        BREAK
                        end
                else
                        begin
                                if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
                                        BREAK
                        end

                update logCentinella
                set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
                where idCmdSql = @idCmdSql
        end

TRUNCATE TABLE master.dbo.userDatabases
TRUNCATE TABLE master.dbo.indexMaintenance
'', 
                @database_name=N''master'', 
                @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
                @enabled=1, 
                @freq_type=4, 
                @freq_interval=1, 
                @freq_subday_type=1, 
                @freq_subday_interval=0, 
                @freq_relative_interval=0, 
                @freq_recurrence_factor=0, 
                @active_start_date=20140724, 
                @active_end_date=99991231, 
                @active_start_time=30000, 
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
        
    set @process = 'CREATE JOB CW_Global_Maintenance_SafetyStop'
    set @sql = 'USE [msdb]

-----------------------------------------------------------
-- 1. Pre-cleanup: Delete existing job if it already exists
-----------------------------------------------------------
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N''CW_Global_Maintenance_SafetyStop'')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N''CW_Global_Maintenance_SafetyStop'', @delete_unused_schedule = 1;
END

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SET @ReturnCode = 0

-----------------------------------------------------------
-- 2. Ensure Nuxiba category exists
-----------------------------------------------------------
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = N''Nuxiba'' AND category_class = 1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N''JOB'', @type = N''LOCAL'', @name = N''Nuxiba'';
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
END

-----------------------------------------------------------
-- 3. Create the Parent Job
-----------------------------------------------------------
DECLARE @jobId BINARY(16);

EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name = N''CW_Global_Maintenance_SafetyStop'', 
    @enabled = 1, 
    @description = N''Safety job that checks every morning at 6 AM if maintenance jobs (DatabaseCentinella, CW Delete old records) are still running and stops them if necessary.'', 
    @category_name = N''Nuxiba'', 
    @owner_login_name = N''replication'', 
    @notify_level_eventlog = 0, 
    @delete_level = 0,
    @job_id = @jobId OUTPUT;

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-----------------------------------------------------------
-- 4. STEP 1: Check and Stop ''DatabaseCentinella''
-----------------------------------------------------------
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @jobId, 
    @step_name = N''Check and Stop DatabaseCentinella'', 
    @step_id = 1,
    @subsystem = N''TSQL'', 
    @command = N''
SET NOCOUNT ON;
DECLARE @jobName NVARCHAR(128) = N''''DatabaseCentinella'''';
DECLARE @isRunning BIT = 0;

-- Check if the job is currently running
IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobactivity AS a
    INNER JOIN msdb.dbo.sysjobs AS b ON a.job_id = b.job_id
    WHERE b.name = @jobName
      AND a.start_execution_date IS NOT NULL
      AND a.stop_execution_date IS NULL
)
BEGIN
    SET @isRunning = 1;
END

IF @isRunning = 1
BEGIN
    PRINT ''''[SafetyStop] The job "'''' + @jobName + ''''" is currently running. Attempting to stop...'''';
    BEGIN TRY
        EXEC msdb.dbo.sp_stop_job @job_name = @jobName;
        PRINT ''''[SafetyStop] SUCCESSFULLY STOPPED: "'''' + @jobName + ''''".'''';
    END TRY
    BEGIN CATCH
        PRINT ''''[SafetyStop] ERROR attempting to stop: '''' + ERROR_MESSAGE();
        -- We do not THROW here to allow the Safety Job to proceed to the next step/job.
    END CATCH
END
ELSE
BEGIN
    PRINT ''''[SafetyStop] The job "'''' + @jobName + ''''" was not running. No action was taken.'''';
END
'', 
    @database_name = N''master'', 
    @on_success_action = 3, -- IMPORTANT: Go to the next step
    @on_fail_action = 3;    -- IMPORTANT: Go to the next step even if this fails

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-----------------------------------------------------------
-- 5. STEP 2: Check and Stop ''CW Delete old records''
-----------------------------------------------------------
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @jobId, 
    @step_name = N''Check and Stop CW Delete old records'', 
    @step_id = 2,
    @subsystem = N''TSQL'', 
    @command = N''
SET NOCOUNT ON;
DECLARE @jobName NVARCHAR(128) = N''''CW Delete old records'''';
DECLARE @isRunning BIT = 0;

-- Check if the job is currently running
IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobactivity AS a
    INNER JOIN msdb.dbo.sysjobs AS b ON a.job_id = b.job_id
    WHERE b.name = @jobName
      AND a.start_execution_date IS NOT NULL
      AND a.stop_execution_date IS NULL
)
BEGIN
    SET @isRunning = 1;
END

IF @isRunning = 1
BEGIN
    PRINT ''''[SafetyStop] The job "'''' + @jobName + ''''" is currently running. Attempting to stop...'''';
    BEGIN TRY
        EXEC msdb.dbo.sp_stop_job @job_name = @jobName;
        PRINT ''''[SafetyStop] SUCCESSFULLY STOPPED: "'''' + @jobName + ''''".'''';
    END TRY
    BEGIN CATCH
        PRINT ''''[SafetyStop] ERROR attempting to stop: '''' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT ''''[SafetyStop] The job "'''' + @jobName + ''''" was not running. No action was taken.'''';
END
'', 
    @database_name = N''master'', 
    @on_success_action = 1, -- Quit with success
    @on_fail_action = 2;    -- Quit with failure (if this last step fails, report it)

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-----------------------------------------------------------
-- 6. Schedule: Every day at 6:00 a.m.
-----------------------------------------------------------
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
    @job_id = @jobId, 
    @name = N''CW_Global_SafetyStop_Schedule'', 
    @enabled = 1, 
    @freq_type = 4,             -- Daily
    @freq_interval = 1,         -- Every day
    @active_start_time = 60000, -- 06:00:00
    @active_start_date = 20251023;

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-----------------------------------------------------------
-- 7. Assign job to local server
-----------------------------------------------------------
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver 
    @job_id = @jobId, 
    @server_name = N''(local)'';

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-----------------------------------------------------------
-- Final Commit
-----------------------------------------------------------
COMMIT TRANSACTION;
PRINT ''Job [CW_Global_Maintenance_SafetyStop] created successfully.''
GOTO EndSave;

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
    PRINT ''Error creating job. Rollback performed.''
EndSave:'
    EXEC(@sql)

     set @process = 'CREATE JOB '
    set @sql = ''
    EXEC(@sql)

  

COMMIT TRAN
END TRY

BEGIN CATCH
/* Error generated based on sintax */
SELECT @errorGenerated = 'DB script version: ' + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

RAISERROR (@errorGenerated, 11, 1)

ROLLBACK TRAN
END CATCH
