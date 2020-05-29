/*
Autor: Jesus Gallardo
Fecha: 2014/08/08
Descripcion:
	Se agrega indice IX_cccallsreject en cccallsreject 
	Se agrega indice IX_ccriachats en ccriachats
	Se agrega indice IX_ivrcallsin en ivrcallsin 
	Se agrega indice IX_ivroptions en ivrcallsin
	Se agrega indice IX_ccLogAgentesDia_Dialog en ccLogAgentesDia_Dialog
	Se agrega indice IX_ccoCallBacks6 en ccoCallBacks

	Se crea Job DatabaseCentinella para perfomance de indices
	Se modifica Job NuxibaNewReportsMaintenancePlan para deshabilitarlo	

Version requerida: 17
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '18'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		set @process = 'Create - index  IX_cccallsreject in cccallsreject '
	set @Sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_cccallsreject'' AND object_id = OBJECT_ID(''cccallsreject''))
CREATE NONCLUSTERED INDEX [IX_cccallsreject] ON [dbo].[cccallsreject]
(
	[cal_inicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ccriachats in ccriachats '
	set @Sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ccriachats'' AND object_id = OBJECT_ID(''ccriachats''))
CREATE NONCLUSTERED INDEX [IX_ccriachats] ON [dbo].[ccriachats]
(
	[chatDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ivrcallsin in ivrcallsin '
	set @Sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ivrcallsin'' AND object_id = OBJECT_ID(''ivrcallsin''))
CREATE NONCLUSTERED INDEX [IX_ivrcallsin] ON [dbo].[ivrcallsin]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ivroptions in ivroptions '
	set @Sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ivroptions'' AND object_id = OBJECT_ID(''ivroptions''))
CREATE NONCLUSTERED INDEX [IX_ivroptions] ON [dbo].[ivroptions]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create - index  IX_ccLogAgentesDia_Dialog in ccLogAgentesDia_Dialog '
	set @Sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ccLogAgentesDia_Dialog'' AND object_id = OBJECT_ID(''ccLogAgentesDia_Dialog''))
CREATE NONCLUSTERED INDEX [IX_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog]
(
	[fecha_Dialog] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)
	
	set @process = 'Create - index  IX_ccoCallBacks6 in ccoCallBacks '
	set @Sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ccoCallBacks6'' AND object_id = OBJECT_ID(''ccoCallBacks''))
CREATE NONCLUSTERED INDEX [IX_ccoCallBacks6] ON [dbo].[ccoCallBacks]
(
	[callout_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'CREATE - JOB DatabaseCentinella '
	set @sql='USE [msdb]
/****** Object:  Job [DatabaseCentinella]    Script Date: 07/09/2014 19:44:44 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

/****** Object:  Job [DatabaseCentinella]    Script Date: 07/02/2014 00:05:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
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
Fecha: 2014/07/24
Descripcion:
	Centinela para monitoreo de performance y mantenimiento de las BD de SQL
'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 24/07/2014 09:07:56 PM ******/
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
			[status] int not null
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
		select getdate(), @sql, 0

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
				select getdate(), @sql, 0
				
				select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKDATABASE(N'''''''''''' + @dbName + '''''''''''', 10, TRUNCATEONLY)''''
				
				insert into logCentinella
				select getdate(), @sql, 0

				select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

				insert into logCentinella
				select getdate(), @sql, 0

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
				select getdate(), @sql, 0

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
		select getdate(), @sql, 0

	end

while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
	begin
		set rowcount 1
			select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
		set rowcount 0
	
		exec(@cmdSql)

		update logCentinella
		set status = 1
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

	set @process = 'DISABLE - JOB NuxibaNewReportsMaintenancePlan'
	set @sql='use [msdb]

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaNewReportsMaintenancePlan'')
	EXEC dbo.sp_update_job @job_name = N''NuxibaNewReportsMaintenancePlan'', @enabled = 0'

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
