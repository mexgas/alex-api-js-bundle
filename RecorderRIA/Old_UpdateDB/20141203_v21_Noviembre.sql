
/*
Fecha: 2014/05/12
Descripcion: 	
	Se agrega Centinella 
	
Version requerida: 20
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 21
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Alter table -- trec_parametros'
	set @Sql='alter table trec_parametros alter column par_valor [varchar](600)'	

	EXEC(@Sql)

	set @process = 'Alter table -- trec_parametros'
	set @Sql='
	INSERT INTO TREC_PARAMETROS
	VALUES (67,''Automatic Backup Settings'',''0|0|1|0|100|11:35:00 AM|0|1|0|1'',''0 = NetBios; 1 = FTP; 2 = External Drive|Fixed Repository|Leave Recordings available|Media Type 0 = Custom; 1 = CD; 2 = DVD|Size|Time|Allow Smaller Folders|Delete Recordings|0  = MB; 1 = GB|0 = week; 1 = month'')

	INSERT INTO TREC_PARAMETROS
	VALUES (68,''Automatic Backup NetBios Settings'',''\\127.0.0.1\Recordings\Back|127.0.0.1|f7b29ae7ea75ea03a1c2463e8ec90939|156c6caec2209f8e167a481e6e819117|1'',''Path|Server|User|Password'')

	INSERT INTO TREC_PARAMETROS
	VALUES (69,''Automatic Backup FTP Settings'',''\home\Backup|127.0.0.1|f7b29ae7ea75ea03a1c2463e8ec90939|156c6caec2209f8e167a481e6e819117|1|22'',''Path|Server|User|Password|Protocol 0=FTP; 1=SFTP|Port'')

	INSERT INTO TREC_PARAMETROS
	VALUES (70,''Automatic Backup External Drive Settings'',''C:\Backup'',''Path'')
	'
	EXEC(@Sql)

	

	set @process = 'CREATE PROCEDURE -- trsp_AVRSBackupSaveRoute'
	set @Sql='
	CREATE PROCEDURE trsp_AVRSBackupSaveRoutetrsp_GetAppParameters
	@grab_id int,
	@status_audio int,
	@status_video int,
	@id_ruta_backup int
	AS
	BEGIN
		
		INSERT INTO TREC_BACKUPS VALUES(@grab_id, @status_audio, @status_video, @id_ruta_backup)

	END'

	EXEC(@Sql)


	set @process = 'CREATE PROCEDURE -- trsp_GetAppParameters'
	set @Sql='
	CREATE PROCEDURE [dbo].[trsp_GetAppParameters]
	@app_id AS INT
	AS
	BEGIN
	DECLARE  @avrs_enviroment AS INT
	DECLARE @SQL AS NVARCHAR(MAX)

	--AVRS Record Manager
	IF @app_id = 1
	BEGIN
		SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

			IF @avrs_enviroment = 2
				BEGIN
			
					SET @SQL = ''SELECT par_valor,par_id 
								FROM TREC_PARAMETROS 
								WHERE par_id 
								IN (67,57,68,69,70)
								ORDER BY par_id''
				
				END 
			ELSE
				BEGIN

					SET @SQL = ''SELECT * FROM
								(SELECT par_valor,par_id FROM TREC_PARAMETROS 
								WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,61,62,63,29,2,65,67)
								UNION
								SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
								FROM TREC_GRABACION)x
								ORDER BY x.par_id''
				END
	END

	EXEC sp_executesql @SQL

	END'

	EXEC(@Sql)

	set @process = 'Alter SP -- trsp_AdmRecSearchOneDay'
	set @Sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]

@Sup_id int

AS
BEGIN

		select r.id_grabacion, avg(r.total_forma) as total_forma
		into #tempRiaFormaCalif from ria_formacalif r 
		inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
		on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
		group by r.id_grabacion		
		
		select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
		into #tempCampEspWG from ccRIACampEspWGConsulta a 
		inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = 1 and a.IDWG = b.IDWG
		
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma,a.id_repositorio,
		CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
		a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
		left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
		left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
		where a.finicio >= Convert(nvarchar(11),Getdate(),120)

		drop table #tempRiaFormaCalif
		drop table #tempCampEspWG
END'	

	EXEC(@Sql)


	set @process = 'ALTER PROCEDURE -- trsp_GetParametersExportService'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_GetParametersExportService]
	AS
	BEGIN
	DECLARE  @avrs_enviroment AS INT
	DECLARE @SQL AS NVARCHAR(MAX)

	SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

		IF @avrs_enviroment = 2
			BEGIN
			
				SET @SQL = ''SELECT * FROM
							(SELECT par_valor,par_id FROM TREC_PARAMETROS 
							WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,61,62,63,29,2,65,67)
							UNION
							SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
							FROM RIA_GRABACION)x
							ORDER BY x.par_id''
				
			END 
		ELSE
			BEGIN

				SET @SQL = ''SELECT * FROM
							(SELECT par_valor,par_id FROM TREC_PARAMETROS 
							WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,61,62,63,29,2,65,67)
							UNION
							SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
							FROM TREC_GRABACION)x
							ORDER BY x.par_id''
			END

	EXEC sp_executesql @SQL

	END

	'
	EXEC(@Sql)

	set @process = 'CREATE PROCEDURE -- trsp_SaveAVRSBackupParameters'
	set @Sql='CREATE PROCEDURE trsp_SaveAVRSBackupParameters
	@settings AS VARCHAR(MAX),
	@NetBiosSettings AS VARCHAR(MAX) = '''',
	@FTPSettings AS VARCHAR(MAX) = '''',
	@ExtDriveSettings AS VARCHAR(MAX) = ''''
	AS
	BEGIN
		
		UPDATE TREC_PARAMETROS
		SET par_valor = @settings
		WHERE par_id = 67

		--NetBios
		IF LEN(@NetBiosSettings) > 0
			BEGIN
		
				UPDATE TREC_PARAMETROS
				SET par_valor = @NetBiosSettings
				WHERE par_id = 68
				
			END

		--FTP	
		IF LEN(@FTPSettings) > 0
			BEGIN
		
				UPDATE TREC_PARAMETROS
				SET par_valor = @FTPSettings
				WHERE par_id = 69
				
			END

		--ExtDrive	
		IF LEN(@ExtDriveSettings) > 0
			BEGIN
		
				UPDATE TREC_PARAMETROS
				SET par_valor = @ExtDriveSettings
				WHERE par_id = 70
				
			END
			
	END'
	
	EXEC(@Sql)

	set @process = 'Alter PROCEDURE -- trsp_SaveAVRSExportParameters'
	set @Sql='Alter PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
	@export_mode AS INT,
	@netcred_id AS INT = -1,
	@net_user AS VARCHAR(100) = '''',
	@net_password AS VARCHAR(100) = '''',
	@net_sever AS VARCHAR(max) = '''',
	@net_path AS VARCHAR(max) = '''',
	@ftp_user AS VARCHAR(100) = '''',
	@ftp_password AS VARCHAR(100) = '''',
	@ftp_sever AS VARCHAR(max) = '''',
	@ftp_path AS VARCHAR(max) = '''',
	@ftp_port AS INT = -1,
	@ftp_protocol AS INT = -1,
	@time_export AS VARCHAR(20) = '''',
	@grabid_start AS INT = -1,
	@csv_log AS INT = -1,
	@delete_rec AS INT = -1
	AS
	BEGIN

	DECLARE @repo_Id AS INT

		-- Update FTP Parameters	

		IF @export_mode = 1
			BEGIN

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_path
				WHERE
				par_id = 41

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_protocol
				WHERE
				par_id = 42

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_sever
				WHERE
				par_id = 43

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_user
				WHERE
				par_id = 44

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_password
				WHERE
				par_id = 45

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_port
				WHERE
				par_id = 46

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50	

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					
					END
			END
		ELSE
			BEGIN

				-- Update NetBios parameters

				UPDATE RIA_NETWORKCREDENTIALS
				SET
				[domain] = @net_sever,
				[user] = @net_user,
				[password] = @net_password
				WHERE
				id = @netcred_id
					
				UPDATE TREC_PARAMETROS
				SET par_valor = @net_path
				WHERE 
				par_id = 36
					
				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					END

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

			END
	END'
	
	EXEC(@Sql)


	set @process = 'Add job -- DatabaseCentinella'
	set @Sql='
		USE [master]

		if exists (select * from sys.tables where name = ''indexMaintenance'')
			begin			
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''idIndex'') 
						DROP TABLE [dbo].[indexMaintenance]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''dbName'') 
						DROP TABLE [dbo].[indexMaintenance]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''tableName'') 
						DROP TABLE [dbo].[indexMaintenance]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''indexName'') 
						DROP TABLE [dbo].[indexMaintenance]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''indexType'') 
						DROP TABLE [dbo].[indexMaintenance]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''indexFragmentation'') 
						DROP TABLE [dbo].[indexMaintenance]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''indexMaintenance'' and column_name = ''status'') 
						DROP TABLE [dbo].[indexMaintenance]
			end

		if exists (select * from sys.tables where name = ''logCentinella'')
			begin
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''idCmdSql'') 
						DROP TABLE [dbo].[logCentinella]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''date'') 
						DROP TABLE [dbo].[logCentinella]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''cmdSql'') 
						DROP TABLE [dbo].[logCentinella]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''status'') 
						DROP TABLE [dbo].[logCentinella]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''dateStart'') 
						DROP TABLE [dbo].[logCentinella]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''dateEnd'') 
						DROP TABLE [dbo].[logCentinella]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''logCentinella'' and column_name = ''executionTimeSeconds'') 
						DROP TABLE [dbo].[logCentinella]
			end

		if exists (select * from sys.tables where name = ''userDatabases'')
			begin
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''userDatabases'' and column_name = ''idDb'') 
						DROP TABLE [dbo].[userDatabases]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''userDatabases'' and column_name = ''dbName'') 
						DROP TABLE [dbo].[userDatabases]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''userDatabases'' and column_name = ''dbLog'') 
						DROP TABLE [dbo].[userDatabases]
				else
				if not exists( select * from INFORMATION_SCHEMA.COLUMNS where table_name = ''userDatabases'' and column_name = ''status'') 
						DROP TABLE [dbo].[userDatabases]	
			end


		USE [msdb]

		if exists (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''DatabaseCentinella'')
			EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

		USE [msdb]

		/****** Object:  Job [DatabaseCentinella]    Script Date: 15/10/2014 09:25:39 PM ******/
		BEGIN TRANSACTION
		DECLARE @ReturnCode INT
		SELECT @ReturnCode = 0
		/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 15/10/2014 09:25:39 PM ******/
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
		/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 15/10/2014 09:25:40 PM ******/
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
	--Generamos nueva version
	--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 	update trec_parametros set par_valor = @Version where par_id = 30 

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


