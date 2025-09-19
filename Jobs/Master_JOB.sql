
SET NOCOUNT ON

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

BEGIN TRAN

BEGIN TRY

    set @process = 'CREATE JOB '
    set @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''DatabaseCentinella'') begin
        EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 03/09/2021 07:49:16 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
                @enabled=1, 
                @notify_level_eventlog=0, 
                @notify_level_email=0, 
                @notify_level_netsend=0, 
                @notify_level_page=0, 
                @delete_level=0, 
                @description=N''Autor: Raymundo Gonzalez
                                Fecha: 2018/06/15
                                Descripcion:
                                        Centinela para monitoreo de performance y mantenimiento de las BD de SQL
                                '', 
                @category_name=N''[Uncategorized (Local)]'', 
                @owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 03/09/2021 07:49:16 p. m. ******/
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

if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
        begin
                create table dbo.indexMaintenance(
                        [idIndex] int not null identity primary key,
                        [dbName] nvarchar(100) not null,
                        [tableName] nvarchar(100) not null,
                        [indexName] nvarchar(100) not null,
                        [indexType] nvarchar(100) not null,
                        [indexFragmentation] nvarchar(100) not null,
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
SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
WHERE indexstats.avg_fragmentation_in_percent > 30
ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

                exec(@sql)

                update userDatabases
                set status = 1
                where idDb = @idDb
        end

while (select count(*) from indexMaintenance where status = 0) > 0
        begin
                set rowcount 1
                        select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
                set rowcount 0

                select @sql = ''''use ['''' + @dbName + ''''] ''''

                if @process = 1
                                select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )''''
                else if @process = 2
                                select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )''''
                else if @process = 3
                                select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN''''

                insert into logCentinella
                select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

                if @process < 3
                        update indexMaintenance set status = 1 where idIndex = @idIndex
                else
                        update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

                if @process < 3
                        begin
                                if (select count(*) from indexMaintenance where status = 0) = 0
                                        begin
                                                update indexMaintenance
                                                set status = 0

                                                set @process = @process + 1
                                        end
                        end
        end

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
--if 1=1
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


                                if @dbName in(''''CCenterRIA'''',''''CCRecorderRIA'''',''''CCReportsRIA'''',''''CW_CRMx'''') begin

                                        select @sql = ''''use ['''' + @dbName + ''''] ALTER DATABASE ''''+@dbName+ '''' SET RECOVERY SIMPLE''''

                                        insert into logCentinella
                                        select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0                                                 
                                
                                end                             

                                select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

                                insert into logCentinella
                                select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0                                                         

                                update userDatabases
                                set status = 1
                                where idDb = @idDb
                        end

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
                        
                        select @cmdSql, ERROR_MESSAGE(); -- Muestra el mensaje del error
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

delete userDatabases
delete indexMaintenance'', 
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
EndSave:'
    EXEC(@sql)

    set @process = 'CREATE JOB NuxibaShrink_tempdb_Weekly'
    set @sql = 'USE [msdb]
/****** Object:  Job [NuxibaShrink_tempdb_Weekly]    Script Date: 12/06/2025 10:28:25 a. m. ******/
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N''NuxibaShrink_tempdb_Weekly'')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N''NuxibaShrink_tempdb_Weekly'';
END

/****** Object:  Job [NuxibaShrink_tempdb_Weekly]    Script Date: 12/06/2025 10:28:25 a. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/06/2025 10:28:26 a. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaShrink_tempdb_Weekly'', 
                @enabled=1, 
                @notify_level_eventlog=2, 
                @notify_level_email=0, 
                @notify_level_netsend=0, 
                @notify_level_page=0, 
                @delete_level=0, 
                @description=N''Ejecuta SHRINK del log de tempdb y ajusta crecimiento a 256MB si aplica.'', 
                @category_name=N''[Uncategorized (Local)]'', 
                @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Validar_y_Shrink_tempdb_log]    Script Date: 12/06/2025 10:28:27 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Validar_y_Shrink_tempdb_log'', 
                @step_id=1, 
                @cmdexec_success_code=0, 
                @on_success_action=1, 
                @on_success_step_id=0, 
                @on_fail_action=2, 
                @on_fail_step_id=0, 
                @retry_attempts=0, 
                @retry_interval=0, 
                @os_run_priority=0, @subsystem=N''TSQL'', 
                @command=N''
DECLARE @log_size_mb FLOAT, @log_used_pct FLOAT;

-- Confirmar base activa
PRINT ''''Base actual: '''' + DB_NAME();

-- Obtener uso actual del log
SELECT 
    @log_size_mb = total_log_size_in_bytes / 1024.0 / 1024.0,
    @log_used_pct = used_log_space_in_percent
FROM sys.dm_db_log_space_usage;

PRINT ''''Tamaño actual del log de tempdb (MB): '''' + CAST(@log_size_mb AS VARCHAR(20));
PRINT ''''Uso actual del log (%): '''' + CAST(@log_used_pct AS VARCHAR(10));

-- Validar si SHRINK aplica
--IF @log_size_mb > 1024 AND @log_used_pct < 10
--BEGIN
    PRINT ''''✅ Ejecutando SHRINK del log de tempdb...'''';
    DBCC SHRINKFILE (templog, 1024);
    PRINT ''''✅ SHRINK completado.'''';
--END
'', 
                @database_name=N''tempdb'', 
                @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''NuxibaShrink_tempdb_Weekly'', 
                @enabled=1, 
                @freq_type=8, 
                @freq_interval=64, 
                @freq_subday_type=1, 
                @freq_subday_interval=0, 
                @freq_relative_interval=0, 
                @freq_recurrence_factor=1, 
                @active_start_date=20250612, 
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
