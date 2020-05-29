/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2015/10/19
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara
Required version: 33

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 34

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try


	set @process = 'sp_RENAME --------- RepInCallsDetail.whoHangup'
	set @Sql= 'sp_RENAME ''RepInCallsDetail.whoHangup'', ''whoHangUp'' , ''COLUMN'''
	EXEC(@Sql)

	set @process = 'alter table --------- RepOutDialDetail'
	set @Sql= 'alter table RepOutDialDetail add billed varchar(255)'
	EXEC(@Sql)

	set @process = 'alter table  --------- RepInCallsDetail'
	set @Sql= 'alter table RepInCallsDetail alter column whoHangUp varchar(255)'
	EXEC(@Sql)

	set @process = 'insert --------- [TranslatedReports]  3010'
	set @Sql= 'insert into [TranslatedReports] values(3010,''whoHangUp'')'
	EXEC(@Sql)

	set @process = 'update ---------  RepInCallsDetail'
	set @Sql= 'update RepInCallsDetail set whoHangUp = case when whoHangUp = ''0'' then ''systemTranslated_Client''
	when whoHangUp = ''1'' then ''systemTranslated_Agent'' else ''systemTranslated_AgentSurvey'' end'
	EXEC(@Sql)

	set @process = 'update ReportsTotals ---------'
	set @Sql= 'update ReportsTotals set TotalColumns=''sum:queueTime|sum:xferTime|sum:ringingTime|sum:dialogTime|sum:mohTime'' WHERE Id=3010'
	EXEC(@Sql)


	set @process = 'update RepOutDialDetail ---------'
	set @Sql= 'update RepOutDialDetail set billed='''''
	EXEC(@Sql)

	set @process = 'update TranslatedReports ---------'
	set @Sql= 'update TranslatedReports set columns=''campaign|billed'' where id=4010'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE ccspRepInCallsDetail ---------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInCallsDetail with(rowlock)	where date >= @from AND date < @to

	insert into RepInCallsDetail
	select cal_inicio, Inbound_id, '''' as Inbound, statusCall_id, '''' as statusCall, calif_id, '''' as calif, isnull(califSub_id,0), '''' as califSub,
	dni_id, '''' as dni, user_id, '''' as agentName,
	isnull(cal_key,''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''',
	case when a.cal_whoHung = 0 then ''systemTranslated_Client''
	when a.cal_whoHung = 1 then ''systemTranslated_Agent''
	else ''systemTranslated_AgentSurvey'' end [whoHangUp]
	, cal_tMoh, datepart(yyyy,cal_inicio), datepart(mm,cal_inicio), datepart(dd,cal_inicio)
	, datepart(hh,cal_inicio), datepart(mi,cal_inicio)
	,di.provedor_id,prov.descrip [Proveedor],a.cal_puerto
	from cccallsin a
	left join ccoDialers di on di.dialer_id = a.cal_puerto
	left join cstoProvedor prov on di.provedor_id = prov.provedor_id
	where cal_inicio >= @from AND cal_inicio < @to

	update a set acdGroup = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccInbound b
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccstatusllamada b
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,'''')
	from RepInCallsDetail a
	left join cctipocalif b
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,'''')
	from RepInCallsDetail a
	left join cctipocalifsub b
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInCallsDetail a
	left join ccusers b
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set dnis = isnull(dni_numero,'''')
	from RepInCallsDetail a
	left join ccdnis b
	on a.dnisId = b.dni_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInCallsDetail a
	left join ccusers b
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to
end'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE ccspRepOutDialDetail ---------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		--Borrar lo que esta para no repetir
		delete from RepOutDialDetail with(rowlock)
		where date >= @from AND date < @to

		--Inserta información de reporte
		insert into RepOutDialDetail
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime,
		datepart(yyyy,fecha), datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha), isnull(rl.name,'''')
		,case when answerbit = 1 then ''systemTranslated_Charged'' else ''systemTranslated_NotCharged'' end as billed
		FROM (select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,
			  dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key
			  FROM ccoLogDials dial
			  left join ccocallsout co on
				(dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono
				 and tiporesdial_id = 1
				 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) >= convert(datetime,convert(varchar(19),dial.fecha),121)
				 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) <=  convert(datetime,convert(varchar(19),dial.fecha),121))
			  WHERE fecha >= @from AND fecha < @to) dials
		LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id
		LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id
		LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]
		LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id
		WHERE fecha >= @from AND fecha < @to
		order by fecha
	end'
	EXEC(@Sql)

	set @process = 'Job Alter -------- DatabaseCentinella '
		set @sql='IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/04/2016 12:39:48 ******/
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
				Fecha: 2014/10/15
				Descripcion:
					Centinela para monitoreo de performance y mantenimiento de las BD de SQL
				'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 02/04/2016 12:39:49 ******/
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

								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKDATABASE(N'''''''''''' + @dbName + '''''''''''', 10, TRUNCATEONLY)''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

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

						exec(@cmdSql)

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

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off