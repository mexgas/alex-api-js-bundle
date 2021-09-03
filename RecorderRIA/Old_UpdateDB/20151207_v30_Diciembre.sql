/*
Date: 2015/11/17
Description: 
 
 rename RIA_GRABACIONCONSULTA
 drop CONSTRAINT PK_TREC_GRABACIONCONSULTA

 create RIA_GRABACIONCONSULTA

 create Index IX_RIA_GRABACIONCONSULTA_1
 create Index IX_RIA_GRABACIONCONSULTA_2
 create Index IX_RIA_GRABACIONCONSULTA_3
 create Index IX_RIA_GRABACIONCONSULTA_4
 create Index IX_RIA_GRABACIONCONSULTA_5
 create Index IX_RIA_GRABACIONCONSULTA_6
 create Index IX_RIA_GRABACIONCONSULTA_7
 create Index IX_RIA_GRABACIONCONSULTA_8
 create Index IX_ccRIAWorkGroupUsersConsulta2

 Add  Constraint TREC_GRABACIONCONSULTA

 Alter Function md5

 ALTER PROCEDURE trsp_muevegrabaciones
 ALTER PROCEDURE trsp_AdmCheckExportProfile
 ALTER PROCEDURE trsp_AdmGetRecExportProfile
 ALTER PROCEDURE trsp_AdmGetExportCamp
 ALTER PROCEDURE trsp_GetFirstBackupFile
 ALTER PROCEDURE trsp_GetAppParameters
 ALTER PROCEDURE trsp_GetParametersExportService
 ALTER PROCEDURE trsp_AdmRecSearchNodeACD
 ALTER PROCEDURE trsp_AdmRecSearchNodeCamp
 ALTER PROCEDURE trsp_AdmRecSearchNodeCalif
 ALTER PROCEDURE trsp_GetRecordigsExportService
 ALTER PROCEDURE trsp_GetCompleteBackupRange
 ALTER PROCEDURE trsp_GetFilesForBackup
 ALTER PROCEDURE trsp_AdmRecSearchCalID
 ALTER PROCEDURE trsp_AdmRecSearchCallIdStr
 ALTER PROCEDURE trsp_AdmGetAllRepositories
 ALTER PROCEDURE trsp_AdmRecSearchNodeWorkgroup
 ALTER PROCEDURE trsp_SaveAVRSBackupParameters
 ALTER PROCEDURE trsp_SaveAVRSExportParameters
 Alter PROCEDURE trsp_AdmRecSearchAllRecs
 Alter PROCEDURE trsp_AdmRecSearchOneDay

 Copy data to TREC_GRABACIONCONSULTA

 Delete Job Move Recordings
 Create Job Move Recordings

 Delete DatabaseCentinella
 Create DatabaseCentinella


Database: CCRecorderRia
Required version: 29
*/

SET nocount ON
DECLARE @Version VARCHAR(10) 
DECLARE @actualVersion VARCHAR(10)
DECLARE @Process VARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX)
DECLARE @errorGenerated VARCHAR(max)


/* Version to release (use the version of your own databse)*/
set @version = 30

/* Actual version (use your own script to do it) */
select @actualVersion=par_valor from trec_parametros where par_id = 30

if @actualVersion = @version - 1
BEGIN
BEGIN TRAN 
BEGIN TRY

	
	set @process = 'insert TREC_PARAMETROS --- Credential Replication'	 
	set @sql='if not exists(select * from TREC_PARAMETROS where par_id=73) 
	insert into TREC_PARAMETROS (par_id,par_descripcion,par_valor,par_detail) values(73,'''',''Credential Windows y SQL para replication'',''hostname\UserWindow|passWindow|userSQL|passSQL|hostaname'')'
	EXEC(@sql)


	set @process = 'disable replication'
	set @sql='sp_MSunmarkreplinfo RIA_GRABACIONCONSULTA'
	EXEC(@sql)


	set @process = 'rename table - RIA_GRABACIONCONSULTA'
	set @sql='if exists(select * from sys.tables where name=''RIA_GRABACIONCONSULTA'') and  not exists(select * from sys.tables where name=''RIA_GRABACIONCONSULTABackUp'') 
	exec sp_rename ''RIA_GRABACIONCONSULTA'', ''RIA_GRABACIONCONSULTABackUp'''
	EXEC(@sql)


	set @process = 'DROP CONSTRAINT -- PK_TREC_GRABACIONCONSULTA'	
	set @sql=' if exists(select * from sys.tables where name=''RIA_GRABACIONCONSULTA'') begin 
		if exists(select * from sys.tables where name=''RIA_GRABACIONCONSULTABackUp'')
		drop table RIA_GRABACIONCONSULTABackUp
	exec sp_rename ''RIA_GRABACIONCONSULTA'', ''RIA_GRABACIONCONSULTABackUp''
end'	
	EXEC(@sql)
	
	
	set @process = 'CREATE -- RIA_GRABACIONCONSULTA'
	set @sql='CREATE TABLE [dbo].[RIA_GRABACIONCONSULTA](
				[grab_id] [bigint] NOT NULL,
				[cli_id] [int] NULL,
				[age_id] [int] NULL DEFAULT (NULL),
				[puerto_id] [int] NULL DEFAULT ((0)),
				[tipo_grab_id] [tinyint] NULL,
				[age_id_rec] [int] NULL,
				[ffin] [datetime] NOT NULL DEFAULT (getdate()),
				[finicio] [datetime] NOT NULL  DEFAULT (getdate()),
				[ani] [varchar](30) NOT NULL DEFAULT (''''),
				[dni] [varchar](15) NULL DEFAULT (''''),				
				[tamano] [int] NULL   DEFAULT ((0)),
				[duracion] [int] NULL   DEFAULT ((0)),
				[pos_pc] [varchar](25) NULL  DEFAULT (''''),
				[extension] [varchar](25) NULL,
				[razon_id] [tinyint] NULL,
				[nombre_archivo] [varchar](20) NULL DEFAULT (''''),
				[info1] [varchar](50) NULL,
				[info2] [varchar](50) NULL,
				[info3] [varchar](50) NULL,
				[info4] [varchar](50) NULL,
				[info5] [varchar](50) NULL,
				[id_repositorio] [tinyint] NULL,
				[id_nivel_grito] [int] NULL,
				[tipo_llamada] [smallint] NULL,
				[cam_id] [smallint] NULL,
				[calif_id] [smallint] NULL  DEFAULT ((0)),
				[cal_id] [int] NULL,
				[cal_key] [varchar](20) NULL,
				[cal_manual] [tinyint] NULL  DEFAULT ((0)),
				[cal_extension] [int] NULL,
				[cal_whoHung] [smallint] NULL,
				[cal_whoRec] [int] NULL  DEFAULT ((0)),
				[id_plantilla] [smallint] NULL,
				[fvalida] [datetime] NULL,
				[fvalida2] [datetime] NULL,
				[borra_id] [bit] NULL,
				[cal_fcallback] [smalldatetime] NULL,
				[dni_id] [smallint] NULL,
				[extra_info] [varchar](50) NULL,
				[extra_info2] [varchar](50) NULL,
				[id_rep_video] [tinyint] NULL,
				[video] [int] NOT NULL DEFAULT ((0)),
				[IDWG] [varchar](800) NULL,
				[califSub_id] [smallint] NOT NULL,
				[cal_tMoh] [smallint] NOT NULL
		)	
	'	
	EXEC(@sql)

	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_1'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_1' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_1] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[tipo_llamada] ASC,
					[cal_id] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)


	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_2'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_2' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_2] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[grab_id] ASC,
					[duracion] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)

	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_3'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_3' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_3] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[finicio] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)


	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_4'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_4' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_4] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[grab_id] ASC,
					[tamano] ASC,
					[duracion] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)

	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_5'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_5' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_5] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[duracion] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)


	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_6'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_6' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_6] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[finicio] ASC,
					[duracion] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)


	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_7'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_7' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_7] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[cal_id] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)

	set @process = 'Create Index -- IX_RIA_GRABACIONCONSULTA_8'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_RIA_GRABACIONCONSULTA_8' AND object_id = OBJECT_ID('RIA_GRABACIONCONSULTA'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_8] ON [dbo].[RIA_GRABACIONCONSULTA] 
				(
					[finicio] ASC,
					[IDWG] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)


	set @process = 'Create Index -- IX_ccRIAWorkGroupUsersConsulta2'
	if not exists (SELECT * FROM sys.indexes WHERE name='IX_ccRIAWorkGroupUsersConsulta2' AND object_id = OBJECT_ID('ccRIAWorkGroupUsersConsulta'))
		set @sql='CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta] 
					(
					 [IDWG] ASC,
					 [User_id] ASC
					)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]'
	else
		set @sql = ''	
	EXEC(@sql)



	set @process = 'Add CONSTRAINT -- PK_TREC_GRABACIONCONSULTA'
	set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''PK_TREC_GRABACIONCONSULTA'')
	begin
	ALTER TABLE [dbo].[RIA_GRABACIONCONSULTA] ADD  CONSTRAINT [PK_TREC_GRABACIONCONSULTA] PRIMARY KEY CLUSTERED 
		(
			[grab_id] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]		
	end'
	EXEC(@sql)	


	set @process = 'Alter Function -- md5'
	set @sql='ALTER FUNCTION [dbo].[md5] (@data varchar(255)) 
	RETURNS CHAR(32) AS
	BEGIN
	return UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(HashBytes(''MD5'', lower(@data))), 3, 32))  
	END'			
	EXEC(@sql)	


	set @process = 'ALTER PROCEDURE -- trsp_muevegrabaciones'
		if  exists (select * from sys.procedures where name = N'trsp_muevegrabaciones')
				set @sql='ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
					       AS
					       BEGIN
					             declare @fecha datetime
					             declare @Integrado as int

					             select @integrado = par_valor from trec_parametros where par_id = 29
					             set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)


					             --AVRS XION
					             if (@integrado = 2)
					                    BEGIN
					                           SET IDENTITY_INSERT RIA_GRABACIONCONSULTA ON

					                           	INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
													info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
													cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh)												
												SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
													info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
													cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh
												FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;

												SET IDENTITY_INSERT RIA_GRABACIONCONSULTA OFF

												DELETE RIA_GRABACION with(rowlock) WHERE [finicio] < @fecha;
					                    END
					             else  --AVRS Integrada ó AVRS Stand Alone
					                    BEGIN
					                           SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

					                           INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
													info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
													cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG)
					                           SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
													info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
													cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
					                           FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

					                           SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

					                           DELETE TREC_GRABACION with(rowlock) WHERE [finicio] < @fecha;
					                    END
							END'
			else
				set @sql = ''		
		EXEC(@sql)


	set @process = 'ALTER PROCEDURE -- trsp_AdmCheckExportProfile'
		if  exists (select * from sys.procedures where name = N'trsp_AdmCheckExportProfile')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmCheckExportProfile]
							@id_usuario int
							AS
							BEGIN
								SET NOCOUNT ON;
								select count(*) from RIA_PERFILES_EXPORTACION where id_usuario = @id_usuario and active = 1
							END'
			else
				set @sql = ''		
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE -- trsp_AdmGetRecExportProfile'
		if  exists (select * from sys.procedures where name = N'trsp_AdmGetRecExportProfile')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetRecExportProfile]
							@id_usuario int
							AS
							BEGIN
								SET NOCOUNT ON;
							select isnull(max(campos),'''') from RIA_PERFILES_EXPORTACION where id_usuario = @id_usuario and active =1
							END'
			else
				set @sql = ''		
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE -- trsp_GetFirstBackupFile'
		if  exists (select * from sys.procedures where name = N'trsp_GetFirstBackupFile')
				set @sql='ALTER PROCEDURE [dbo].[trsp_GetFirstBackupFile]
					@isItegratedRIA bit
					AS
					DECLARE @FirstBackupFile as bigint
					DECLARE @LastGrabAr as bigint
					DECLARE @MinTime as integer
					DECLARE @Date as datetime
					Declare @MinHistorico as bigint
					Declare @ExistHist as bit

					BEGIN
					IF @isItegratedRIA = 1
						BEGIN
							--delete RIA_ARCHIVO_GRABACION where hecho = 0
							if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONConsulta]''))
								set @ExistHist = 1
							else
								set @ExistHist = 0
							SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							IF (@MinTime is NULL)
							BEGIN
								SELECT @MinTime=5
							END

							--SELECT @LastGrabAr=MAX(grab_id_max) FROM RIA_ARCHIVO_GRABACION
							SELECT @LastGrabAr=MAX(grab_id)  FROM TREC_BACKUPS
							IF (@LastGrabAr is NULL)
							BEGIN
								SELECT @LastGrabAr=-1
							END
							if @ExistHist = 1
							begin
								SELECT @MinHistorico = MIN(grab_id) FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) 
									WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
								if (@MinHistorico is NULL)
								begin	
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM RIA_GRABACION 
										WHERE grab_id =(SELECT MIN(grab_id) 
											FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
											WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
								end
								else
								begin
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM RIA_GRABACIONConsulta 
										WHERE grab_id =@MinHistorico
								end
							end
							else
							begin
								SELECT  @FirstBackupFile=grab_id, @Date=finicio 
									FROM RIA_GRABACION 
									WHERE grab_id =(SELECT MIN(grab_id) 
										FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
										WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
							end

							SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
						END
					ELSE
						BEGIN
							--delete RIA_ARCHIVO_GRABACION where hecho = 0
							if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONConsulta]''))
								set @ExistHist = 1
							else
								set @ExistHist = 0
							SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							IF (@MinTime is NULL)
							BEGIN
								SELECT @MinTime=5
							END

							--SELECT @LastGrabAr=MAX(grab_id_max) FROM RIA_ARCHIVO_GRABACION
							SELECT @LastGrabAr=MAX(grab_id)  FROM TREC_BACKUPS
							IF (@LastGrabAr is NULL)
							BEGIN
								SELECT @LastGrabAr=-1
							END
							if @ExistHist = 1
							begin
								SELECT @MinHistorico = MIN(grab_id) FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) 
									WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
								if (@MinHistorico is NULL)
								begin	
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM TREC_GRABACION 
										WHERE grab_id =(SELECT MIN(grab_id) 
											FROM TREC_GRABACION  with (index(IX_TREC_GRABACION_2)) 
											WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
								end
								else
								begin
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM TREC_GRABACIONConsulta 
										WHERE grab_id =@MinHistorico
								end
							end
							else
							begin
								SELECT  @FirstBackupFile=grab_id, @Date=finicio 
									FROM TREC_GRABACION 
									WHERE grab_id =(SELECT MIN(grab_id) 
										FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
										WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
							end

							SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
						END 

					END'
			else
				set @sql = ''		
		EXEC(@sql)

		
		set @process = 'ALTER PROCEDURE -- trsp_GetAppParameters'
		if  exists (select * from sys.procedures where name = N'trsp_GetAppParameters')
				set @sql='ALTER PROCEDURE [dbo].[trsp_GetAppParameters]
						  @app_id AS INT
						    AS
						    BEGIN
						    DECLARE  @avrs_enviroment AS INT
						    DECLARE @SQL AS NVARCHAR(MAX)

						    --AVRS Recordings Manager
						    IF @app_id = 1
						    BEGIN
						      SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

						        IF @avrs_enviroment = 2
						          BEGIN
						        
						            SET @SQL = ''SELECT par_valor,par_id 
						                  FROM TREC_PARAMETROS 
						                  WHERE par_id 
						                  IN (67,68,69,70)
						                  ORDER BY par_id''                      
						          END 
						        ELSE
						          BEGIN

						            SET @SQL = ''SELECT par_valor,par_id 
						                  FROM TREC_PARAMETROS 
						                  WHERE par_id 
						                  IN (82,83,84,85)
						                  ORDER BY par_id''  
						          END
						    END

						    EXEC sp_executesql @SQL

						    END'
			else
				set @sql = ''		
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE -- trsp_GetParametersExportService'
		if  exists (select * from sys.procedures where name = N'trsp_GetParametersExportService')
				set @sql='ALTER PROCEDURE [dbo].[trsp_GetParametersExportService]
							AS
							BEGIN

							DECLARE  @avrs_enviroment AS INT
							DECLARE @SQL AS NVARCHAR(MAX)

									SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

									IF @avrs_enviroment = 2
										BEGIN
										
											SET @SQL = ''SELECT * FROM
														(SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS 
														WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,61,62,63,29,2,65,67)
														UNION
														SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,''''''''
														FROM RIA_GRABACION)x
														ORDER BY x.par_id''
											
										END 
									ELSE
										BEGIN

											SET @SQL = ''SELECT * FROM
														(SELECT par_valor,par_id FROM TREC_PARAMETROS 
														WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,61,62,63,29,2,65,67)
														UNION
														SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
														FROM TREC_GRABACION)x
														ORDER BY x.par_id''
										END

								EXEC sp_executesql @SQL

							END'
			else
				set @sql = ''		
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchNodeACD'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchNodeACD')
				set @sql='ALTER PROCEDURE  [dbo].[trsp_AdmRecSearchNodeACD]
							@Workgroup int

							AS
							BEGIN
								SET NOCOUNT ON;

								select a.idCampEsp, b.descripcion, isnull(d.frame,1) from ccRIACampEspWGConsulta a
								inner join ccInbound b on b.Inbound_id = a.idCampEsp
								left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
								left join ccRIAGraphics d on d.graphic_id = c.graphic_id
								where a.IDWG = @Workgroup and a.Tipo = 0

							END'
			else
				set @sql = ''		
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchNodeCamp'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchNodeCamp')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeCamp]
							@Workgroup int
							AS
							BEGIN
								SET NOCOUNT ON;
								select a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
								inner join ccCamps b on b.cam_id = a.idCampEsp
								left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
								left join ccRIAGraphics d on d.graphic_id = c.graphic_id
								where a.IDWG = @Workgroup and a.Tipo = 1
							END'
			else
				set @sql = ''		
		EXEC(@sql)	

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchNodeCamp'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchNodeCamp')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeCamp]
							@Workgroup int
							AS
							BEGIN
								SET NOCOUNT ON;
								select a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
								inner join ccCamps b on b.cam_id = a.idCampEsp
								left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
								left join ccRIAGraphics d on d.graphic_id = c.graphic_id
								where a.IDWG = @Workgroup and a.Tipo = 1
							END'
			else
				set @sql = ''		
		EXEC(@sql)	

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchNodeCalif'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchNodeCalif')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeCalif]
							@CamACD_id int,
							@CallType int
							AS
							BEGIN
								SET NOCOUNT ON;

								IF @CallType = 0 
								BEGIN

									select a.calif_id, b.Description from ccCalifCamp a
									inner join ccTipoCalif b 
									on b.calif_id = a.calif_id and b.Calif_Status = 1
									where cam_id = @CamACD_id and a.tipo = 0
								END
								ELSE IF @CallType = 1 
									BEGIN 

										select a.calif_id, b.Description from ccCalifCamp a
										inner join ccTipoCalifOUT b 
										on b.calif_id = a.calif_id and b.CalifOUT_Status = 1
										where cam_id = @CamACD_id and a.tipo = 1
									END

							END'
			else
				set @sql = ''		
		EXEC(@sql)		

	set @process = 'ALTER PROCEDURE -- trsp_GetRecordigsExportService'
		if  exists (select * from sys.procedures where name = N'trsp_GetRecordigsExportService')
				set @sql='ALTER PROCEDURE [dbo].[trsp_GetRecordigsExportService]
						  @grabId AS INT,
						  @integrated AS INT
						  AS
						  BEGIN
						  DECLARE @SQL AS NVARCHAR(MAX)

						    IF @integrated = 1
						      BEGIN

						        SET @SQL = ''SELECT TOP 10000 * FROM(
						           SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio 
						           FROM RIA_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
						              t.id_repositorio = r.id_repositorio 
						           UNION 
						           SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio 
						           FROM RIA_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
						              t.id_repositorio = r.id_repositorio)x
						           WHERE x.grab_id >=''+ CONVERT(VARCHAR(10), @grabId) +''AND x.finicio < GETDATE()
						           ORDER BY x.grab_id''

						      END
						    ELSE IF @integrated = 0
						      BEGIN

						         SET @SQL = ''SELECT TOP 10000 * FROM(
						           SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio 
						           FROM TREC_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
						              t.id_repositorio = r.id_repositorio 
						           UNION 
						           SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio 
						           FROM TREC_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
						              t.id_repositorio = r.id_repositorio)x
						           WHERE x.grab_id >=''+ CONVERT(VARCHAR(10), @grabId) +''AND x.finicio < GETDATE()
						           ORDER BY x.grab_id''

						      END

						    EXEC SP_EXECUTESQL @SQL

						  END'
			else
				set @sql = ''		
		EXEC(@sql)	


	set @process = 'ALTER PROCEDURE -- trsp_GetCompleteBackupRange'
		if  exists (select * from sys.procedures where name = N'trsp_GetCompleteBackupRange')
				set @sql='ALTER PROCEDURE [dbo].[trsp_GetCompleteBackupRange]
						  @EndDate DATETIME,
						  @isIntegratedRIA BIT

						  AS
						  DECLARE @Count AS BIGINT
						  DECLARE @CountHist AS BIGINT
						  DECLARE @MaxExist AS bigint
						  DECLARE @MinTime AS INT
						  DECLARE @MinFile AS bigint
						  DECLARE @MaxFileAr AS bigint
						  declare @UsoHist as Bit
						  Declare @ExistHist as bit
						  
						  BEGIN

						  IF @isIntegratedRIA  = 1
						    BEGIN
						      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONCONSULTA]''))
						        set @ExistHist = 1
						      else
						        set @ExistHist = 0
						      SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
						      IF (@MinTime is NULL)
						      BEGIN
						        SELECT @MinTime=5
						      END

						      SELECT @MaxFileAr=MAX(grab_id) FROM TREC_BACKUPS
						      IF (@MaxFileAr is NULL)
						      BEGIN
						        SELECT @MaxFileAr=-1
						      END
						  
						      set @UsoHist =1
						      if @ExistHist = 1
						      begin
						        SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_2)) 
						          WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
						        if (@MinFile is NULL)
						        begin
						          SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
						            WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
						          set @UsoHist = 0
						        end
						      end
						      else
						      begin
						        SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
						          WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
						        set @UsoHist = 0
						      end

						      SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3)) WHERE finicio <= @EndDate 
						      IF (@MaxExist is NULL)
						      BEGIN
						        if (@UsoHist = 1)
						        begin
						          SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_3)) WHERE finicio <= @EndDate
						        end
						        else
						          SELECT @MaxExist=0
						      END 
						      if (@MinFile>@MaxExist)
						      begin
						        set @MaxExist = @MinFile
						      end
						      set @CountHist = 0
						      if (@UsoHist = 1)
						      begin
						        SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_4)) 
						          WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
						          AND (tamano > 0) AND (duracion >= @MinTime)   

						        IF (@CountHist is NULL)
						        BEGIN
						          SELECT @CountHist = 0
						        END
						      end
						      SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_4)) 
						        WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
						        AND (tamano > 0) AND (duracion >= @MinTime)   

						      IF (@Count is NULL)
						      BEGIN
						        SELECT @Count = 0
						      END

						      SELECT ''MinFile''=@MinFile,  ''MaxFile''=@MaxExist, ''Size''=(@Count+@CountHist)
						    END
						  ELSE
						    BEGIN
						      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONCONSULTA]''))
						        set @ExistHist = 1
						      else
						        set @ExistHist = 0
						      SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
						      IF (@MinTime is NULL)
						      BEGIN
						        SELECT @MinTime=5
						      END

						      SELECT @MaxFileAr=MAX(grab_id) FROM TREC_BACKUPS
						      IF (@MaxFileAr is NULL)
						      BEGIN
						        SELECT @MaxFileAr=-1
						      END
						  
						      set @UsoHist =1
						      if @ExistHist = 1
						      begin
						        SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_2)) 
						          WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
						        if (@MinFile is NULL)
						        begin
						          SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
						            WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
						          set @UsoHist = 0
						        end
						      end
						      else
						      begin
						        SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
						          WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
						        set @UsoHist = 0
						      end

						      SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_3)) WHERE finicio <= @EndDate
						      IF (@MaxExist is NULL)
						      BEGIN
						        if (@UsoHist = 1)
						        begin
						          SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_3)) WHERE finicio <= @EndDate
						        end
						        else
						          SELECT @MaxExist=0
						      END 
						      if (@MinFile>@MaxExist)
						      begin
						        set @MaxExist = @MinFile
						      end
						      set @CountHist = 0
						      if (@UsoHist = 1)
						      begin
						        SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_4)) 
						          WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
						          AND (tamano > 0) AND (duracion >= @MinTime)   

						        IF (@CountHist is NULL)
						        BEGIN
						          SELECT @CountHist = 0
						        END
						      end
						      SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_4)) 
						        WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
						        AND (tamano > 0) AND (duracion >= @MinTime)   

						      IF (@Count is NULL)
						      BEGIN
						        SELECT @Count = 0
						      END

						      SELECT ''MinFile''=@MinFile,  ''MaxFile''=@MaxExist, ''Size''=(@Count+@CountHist)

						    END

						  END'
			else
				set @sql = ''		
		EXEC(@sql)		

	set @process = 'ALTER PROCEDURE -- trsp_GetFilesForBackup'
		if  exists (select * from sys.procedures where name = N'trsp_GetFilesForBackup')
				set @sql='ALTER PROCEDURE [dbo].[trsp_GetFilesForBackup]
							@start bigint,
							@end bigint,
							@isIntegratedRIA bit
							AS
							DECLARE @MinTime AS INT
							Declare @ExistHist as bit
							declare @ExistRepositorio as bit

							BEGIN

							  IF @isIntegratedRIA = 1
							    BEGIN
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONConsulta]''))
							        set @ExistHist = 1
							      else
							        set @ExistHist = 0
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_Repositorios]''))
							        set @ExistRepositorio = 1
							      else
							        set @ExistRepositorio = 0
							      SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							      IF (@MinTime is NULL)
							      BEGIN
							        SELECT @MinTime=7
							      END
							      if @ExistHist = 1
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2))  WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end
							      else
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACION  with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0,0  FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end
							    END
							  ELSE
							    BEGIN
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONConsulta]''))
							        set @ExistHist = 1
							      else
							        set @ExistHist = 0
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_Repositorios]''))
							        set @ExistRepositorio = 1
							      else
							        set @ExistRepositorio = 0
							      SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							      IF (@MinTime is NULL)
							      BEGIN
							        SELECT @MinTime=7
							      END
							      if @ExistHist = 1
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACION with(index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end
							      else
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0,0  FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end

							    END

							END'
			else
				set @sql = ''		
		EXEC(@sql)					


	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchCalID'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchCalID')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
						@Sup_id int,
						@call_id as int

						AS
						BEGIN
						  SET NOCOUNT ON;

						   select r.id_grabacion, avg(r.total_forma) as total_forma
						   into #tempRiaFormaCalif from ria_formacalif r
						   inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
						   on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
						   group by r.id_grabacion

						   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
						   into #tempCampEspWG from ccRIACampEspWGConsulta a
						   inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

						   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
						   into #tempComplete
						   from  ccRIACampEspWGConsulta a inner join
						   (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in (select  distinct a.IDWG
						   from ccRIACampEspWGConsulta a
						   inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG)
						   and user_id <> @Sup_id) b
						   on a.IDWG=b.IDWG
						          

						   select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
						   a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
						   isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
						   isnull (z.total_forma,0) as total_forma,a.id_repositorio,
						   CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
						   CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
						   grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
						   from RIA_GRABACION a with (index(IX_RIA_GRABACION_8))
						   left join cctipocalifsubout k on k.califSub_id=a.califSub_id
						   left join cctipocalifsub p on p.califSub_id=a.califSub_id
						   left join ccPosicion b on b.pos_id = a.cal_extension * -1
						   left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
						   left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						   left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
						   where a.cal_id = @call_id
						   union
						   select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
						   a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
						   isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
						   isnull (z.total_forma,0) as total_forma,a.id_repositorio,
						   CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
						   CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
						   grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
						   from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						   left join cctipocalifsubout k on k.califSub_id=a.califSub_id
						   left join cctipocalifsub p on p.califSub_id=a.califSub_id
						   left join ccPosicion b on b.pos_id = a.cal_extension * -1
						   left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
						   left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						   left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
						   where a.cal_id = @call_id

						   drop table #tempRiaFormaCalif
						   drop table #tempCampEspWG
						   drop table #tempComplete

						END'
			else
				set @sql = ''		
		EXEC(@sql)	


	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchCallIdStr'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchCallIdStr')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
							@Sup_id int,
							@callIdList as nvarchar(max)
							AS
							BEGIN

							declare @fecha  datetime
							declare @sql nvarchar(max)

							    set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

							    select r.id_grabacion, avg(r.total_forma) as total_forma
							    into #tempRiaFormaCalif from ria_formacalif r 
							    inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
							    on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
							    group by r.id_grabacion   
							      
							    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
							    into #tempCampEspWG from ccRIACampEspWGConsulta a 
							    inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = 6 and a.IDWG = b.IDWG

							    set @sql = ''
							      select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
							      finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
							      isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
							      isnull (z.total_forma,0) as total_forma,a.id_repositorio,
							      CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
							      CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, 
							      a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
							      from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
							      left join ccPosicion b on b.pos_id = a.cal_extension * -1
							      --left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
							      left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
							      left join ccTipoCalif AS f ON a.calif_id = f.calif_id
							      left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
							      left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
							      inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
							      where a.cal_id in(''+@callIdList+'')''+''
							      union
							      select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
							      finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
							      isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
							      isnull (z.total_forma,0) as total_forma,a.id_repositorio,
							      CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
							      CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
							      a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
							      from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))   
							      left join ccPosicion b on b.pos_id = a.cal_extension * -1
							      --left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
							      left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
							      left join ccTipoCalif AS f ON a.calif_id = f.calif_id
							      left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
							      left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
							      inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
							      where a.cal_id in(''+@callIdList+'')''

							      exec sp_executesql @sql

							      drop table #tempRiaFormaCalif
							      drop table #tempCampEspWG
							END'
			else
				set @sql = ''		
		EXEC(@sql)	

	set @process = 'ALTER PROCEDURE -- trsp_AdmGetAllRepositories'
		if  exists (select * from sys.procedures where name = N'trsp_AdmGetAllRepositories')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
							@Mode int	
						AS
						BEGIN
							SET NOCOUNT ON;
							IF @Mode = 1
							Begin
								select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio, ruta_rep_video  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio
							End
							Else IF @Mode =2
								Begin
								select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_rep_video  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio
							End
						END'
			else
				set @sql = ''		
		EXEC(@sql)		
	
	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchNodeWorkgroup'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchNodeWorkgroup')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
							@User_id int
							AS
							BEGIN
									SET NOCOUNT ON;
									select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
									on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
									where a.user_id = @User_id order by 1
								END'
			else
				set @sql = ''		
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE -- trsp_SaveAVRSBackupParameters'
		if  exists (select * from sys.procedures where name = N'trsp_SaveAVRSBackupParameters')
				set @sql='ALTER PROCEDURE [dbo].[trsp_SaveAVRSBackupParameters]
						  @settings AS VARCHAR(MAX),
						  @NetBiosSettings AS VARCHAR(MAX) = '''',
						  @FTPSettings AS VARCHAR(MAX) = '''',
						  @ExtDriveSettings AS VARCHAR(MAX) = ''''
						  AS
						  BEGIN
						    
						    UPDATE TREC_PARAMETROS
						    SET par_valor = @settings
						    WHERE par_id = 82

						    --NetBios
						    IF LEN(@NetBiosSettings) > 0
						      BEGIN
						    
						        UPDATE TREC_PARAMETROS
						        SET par_valor = @NetBiosSettings
						        WHERE par_id = 83
						        
						      END

						    --FTP 
						    IF LEN(@FTPSettings) > 0
						      BEGIN
						    
						        UPDATE TREC_PARAMETROS
						        SET par_valor = @FTPSettings
						        WHERE par_id = 84
						        
						      END

						    --ExtDrive  
						    IF LEN(@ExtDriveSettings) > 0
						      BEGIN
						    
						        UPDATE TREC_PARAMETROS
						        SET par_valor = @ExtDriveSettings
						        WHERE par_id = 85
						        
						      END
						      
						  END'
			else
				set @sql = ''		
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE -- trsp_SaveAVRSExportParameters'
		if  exists (select * from sys.procedures where name = N'trsp_SaveAVRSExportParameters')
				set @sql='ALTER PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
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
						  @delete_rec AS INT = -1,
						  @export_format AS INT = 1
						  AS
						  BEGIN

						  DECLARE @repo_Id AS INT

						    -- Update FTP Parameters  

						    IF @export_mode = 1
						      BEGIN

						        UPDATE TREC_PARAMETROS
						        SET par_valor = @export_format
						        WHERE
						        par_id = 35

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

						        UPDATE TREC_NETWORKCREDENTIALS
						        SET
						        [domain] = @net_sever,
						        [user] = @net_user,
						        [password] = @net_password
						        WHERE
						        id = @netcred_id

						        UPDATE TREC_PARAMETROS
						        SET par_valor = @export_format
						        WHERE
						        par_id = 35
						          
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
			else
				set @sql = ''		
		EXEC(@sql)		

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchAllRecs'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchAllRecs')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
					      @Sup_id int,
					      @Finicio datetime,
					      @Ffin datetime
					      AS
					      BEGIN

					      SET NOCOUNT ON

					      declare @sql1 nvarchar(max)
					      declare @sql2 nvarchar(max)
					      declare @sql3 nvarchar(max)

						  declare @sqlUnion nvarchar(max)
						  declare @maxDate datetime

						  --Tabla con toda la informaciom
						  CREATE TABLE #tempRiAAllInfo(
									cal_id int,
									tipo_llamada smallint,
									cam_id smallint,
									calif_id smallint,
									duracion int,
									id_nivel_grito int,
									user_id int,
									finicio datetime,
									ani varchar (100),
									dni varchar (100),
									cal_key varchar (100),
									cal_manual tinyint, 
									posicion int,
									computer varchar(100),
									total_forma int,
									id_repositorio tinyint,
									score varchar (100),
									formato_duracion varchar(15),
									grab_id bigint,
									IDWG varchar (800),
									califSub_id varchar (800),
									cal_tMoh smallint
							)	

							CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
							(		  
							  [finicio] ASC
							)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


							create table #auxOutbound(
					           	    cal_id int,
									tipo_llamada smallint,
									cam_id smallint,
									calif_id smallint,
									duracion int,
									id_nivel_grito int,
									user_id int,
									finicio datetime,
									ani varchar (100),
									dni varchar (100),
									cal_key varchar (100),
									cal_manual tinyint, 
									posicion int,
									computer varchar(100),
									total_forma int,
									id_repositorio tinyint,
									score varchar (100),
									formato_duracion varchar(15),
									grab_id bigint,
									IDWG varchar (800),
									califSub_id varchar (800),
									cal_tMoh smallint
									)
									
						  --Segmento de Calificaciones
						  create table #tempRiaFormaCalif6(
					      id_grabacion bigint,
					      total_forma int)

						  insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
						  select r.id_grabacion, avg(r.total_forma) as total_forma
					      from ria_formacalif r
					      inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
					      on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					      group by r.id_grabacion
					      

						  --Segmento de Supervisor
					      create table #tempCampEspWG6(
					      IdCampEsp smallint,
					      Tipo smallint,
					      user_id smallint)
							 
						  CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6] 
						  (
							[user_id] ASc
						  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
					         
						  insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id)
					   	  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
						  from ccRIACampEspWGConsulta a
					      inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG		
							
						   --Segmento de usurios asociados al supervisor			     
					      create table #tempComplete6(
					      IdCampEsp smallint,
					      Tipo smallint ,
					      user_id smallint,
					      IDWG smallint)                 
					    
					      CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6] 
						  (		  
						   [user_id] ASC
						  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
					         
						 
					       insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)  
						   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
					       from  ccRIACampEspWGConsulta a  inner join
					       (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
								(select  distinct a.IDWG from ccRIACampEspWGConsulta a
								 inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
								 )and user_id <> @Sup_id
							) b on a.IDWG=b.IDWG

							--Seccion Inbound RIAGrabacion

							insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
								where a.IDWG is not null and a.finicio BETWEEN  cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) 
								and a.tipo_llamada=1
								
								
							insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
								where a.IDWG is not null and a.finicio BETWEEN  cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) 
								and a.tipo_llamada=1
								

							--Seccion Outbound RIAGrabacion
							insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
									select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (e.description,'''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
									left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
									left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
									where a.IDWG is not null and a.finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) 
									and a.tipo_llamada=2
										
							
							
							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
									        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
							inner join #tempComplete6 U  on a.user_id=U.user_id

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
									        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
							inner join #tempCampEspWG6 U  on a.user_id=U.user_id

							

							

							if (select count(*) from RIA_GRABACIONConsulta where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
							begin

								--Seccion Inbound RIA_GRABACIONConsulta

								insert into #tempRiAAllInfo
									select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
									where a.IDWG is not null and a.finicio BETWEEN  cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) 
									and a.tipo_llamada=1
									
								insert into #tempRiAAllInfo
									select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
									where a.IDWG is not null and a.finicio BETWEEN  cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) 
									and a.tipo_llamada=1
									

								delete from #auxOutbound

								--Seccion Outbound RIA_GRABACIONConsulta
								insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
										select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
													finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
													isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
													isnull (z.total_forma,0) as total_forma,a.id_repositorio,
													isnull (e.description,'''')  AS score,
													CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
													grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
										left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
										where a.IDWG is not null and a.finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) 
										and a.tipo_llamada=2
												
									
								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
								inner join #tempComplete6 U  on a.user_id=U.user_id

								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
								inner join #tempCampEspWG6 U  on a.user_id=U.user_id
							end		

							--Seleccionar info de tabla global
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
								   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								   id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh 
							from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc
							
							drop table #tempRiaFormaCalif6
							drop table #tempCampEspWG6
							drop table #tempComplete6
							drop table #tempRiAAllInfo
							drop table #auxOutbound
								
					      END'
			else
				set @sql = ''		
		EXEC(@sql)		

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchOneDay'
		if  exists (select * from sys.procedures where name = N'trsp_AdmRecSearchOneDay')
				set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
							@Sup_id int

							AS
							BEGIN

							declare @sql1 nvarchar(max)
							declare @sql2 nvarchar(max)
							declare @sqlUnion nvarchar(max)

								  --Tabla con toda la informaciom
								  CREATE TABLE #tempRiAAllInfoOneDay(
											cal_id int,
											tipo_llamada smallint,
											cam_id smallint,
											calif_id smallint,
											duracion int,
											id_nivel_grito int,
											user_id int,
											finicio datetime,
											ani varchar (100),
											dni varchar (100),
											cal_key varchar (100),
											cal_manual tinyint, 
											posicion int,
											computer varchar(100),
											total_forma int,
											id_repositorio tinyint,
											score varchar (100),
											formato_duracion varchar(15),
											grab_id bigint,
											IDWG varchar (800),
											califSub_id varchar(800),
											cal_tMoh smallint
									)	

									CREATE CLUSTERED INDEX [IX_tempRiAAllInfoOneDaydate] ON [#tempRiAAllInfoOneDay]
									(		  
									  [finicio] ASC
									)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


									create table #auxOutboundOneDay(
							           	    cal_id int,
											tipo_llamada smallint,
											cam_id smallint,
											calif_id smallint,
											duracion int,
											id_nivel_grito int,
											user_id int,
											finicio datetime,
											ani varchar (100),
											dni varchar (100),
											cal_key varchar (100),
											cal_manual tinyint, 
											posicion int,
											computer varchar(100),
											total_forma int,
											id_repositorio tinyint,
											score varchar (100),
											formato_duracion varchar(15),
											grab_id bigint,
											IDWG varchar (800),
											califSub_id varchar(800),
											cal_tMoh smallint
											)
											
								  --Segmento de Calificaciones
								  create table #tempRiaFormaCalifOneDay(
							      id_grabacion bigint,
							      total_forma int)

								  insert into #tempRiaFormaCalifOneDay (id_grabacion,total_forma)
								  select r.id_grabacion, avg(r.total_forma) as total_forma
							      from ria_formacalif r
							      inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
							      on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
							      group by r.id_grabacion
							      

								  --Segmento de Supervisor
							      create table #tempCampEspWGfOneDay(
							      IdCampEsp smallint,
							      Tipo smallint,
							      user_id smallint)
									 
								  CREATE NONCLUSTERED INDEX [IX_tempCampEspWGfOneDay] ON [#tempCampEspWGfOneDay] 
								  (
									[user_id] ASc
								  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
							         
								  insert into #tempCampEspWGfOneDay (IdCampEsp,Tipo,user_id)
							   	  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
								  from ccRIACampEspWGConsulta a
							      inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG		
									
								   --Segmento de usurios asociados al supervisor			     
							      create table #tempCompleteOneDay(
							      IdCampEsp smallint,
							      Tipo smallint ,
							      user_id smallint,
							      IDWG smallint)                 
							    
							      CREATE NONCLUSTERED INDEX [IX_tempCompleteOneDayUser] ON [#tempCompleteOneDay] 
								  (		  
								   [user_id] ASC
								  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
							         
								 
							       insert into #tempCompleteOneDay  (IdCampEsp,Tipo,user_id,IDWG)  
								   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
							       from  ccRIACampEspWGConsulta a  inner join
							       (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
										(select  distinct a.IDWG from ccRIACampEspWGConsulta a
										 inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
										 )and user_id <> @Sup_id
									) b on a.IDWG=b.IDWG

									--Seccion Inbound RIAGrabacion

									insert into #tempRiAAllInfoOneDay
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (f.description,'''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
										left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
										inner join #tempCompleteOneDay U with (index(IX_tempCompleteOneDayUser)) on a.age_id=U.user_id  
										where a.finicio >= Convert(nvarchar(11),Getdate(),120) 
										and a.tipo_llamada=1
										
										
									insert into #tempRiAAllInfoOneDay
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (f.description,'''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
										left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
										inner join #tempCampEspWGfOneDay U with (index(IX_tempCampEspWGfOneDay)) on a.age_id=U.user_id  
										where a.finicio >= Convert(nvarchar(11),Getdate(),120) 
										and a.tipo_llamada=1
										

									--Seccion Outbound RIAGrabacion
									insert into #auxOutboundOneDay(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
											select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
														finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
														isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
														isnull (z.total_forma,0) as total_forma,a.id_repositorio,
														isnull (e.description,'''')  AS score,
														CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
														grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
											from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
											left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
											left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
											left join ccPosicion b on b.pos_id = a.cal_extension * -1
											left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
											left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion			
											where a.finicio >= Convert(nvarchar(11),Getdate(),120) 
											and a.tipo_llamada=2
											
									
									
									insert into #tempRiAAllInfoOneDay
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
									inner join #tempCompleteOneDay U  on a.user_id=U.user_id

									insert into #tempRiAAllInfoOneDay
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
									inner join #tempCampEspWGfOneDay U  on a.user_id=U.user_id


									--Seleccionar info de tabla global
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
										   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
										   id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh 
									from #tempRiAAllInfoOneDay with (index(IX_tempRiAAllInfoOneDaydate))  order by finicio asc
									
									drop table #tempRiaFormaCalifOneDay
									drop table #tempCampEspWGfOneDay
									drop table #tempCompleteOneDay
									drop table #tempRiAAllInfoOneDay
									drop table #auxOutboundOneDay

								END'
			else
				set @sql = ''		
		EXEC(@sql)		


	set @process = 'Copy data to -- RIA_GRABACIONCONSULTA'
	if exists ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'  AND TABLE_NAME='RIA_GRABACIONCONSULTA')
		set @sql=' INSERT INTO RIA_GRABACIONCONSULTA (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
													info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
													cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh)
					select grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
													info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
													cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh from RIA_GRABACIONCONSULTABackUp '
	else
		set @sql = ''
	
	EXEC(@sql)

	set @process = 'Delete Job -- Move Recordings'
		if exists (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Move Recordings')
			set @sql='msdb.dbo.sp_delete_job @job_name=N''Move Recordings'', @delete_unused_schedule=1'
					else
			set @sql = ''		
		EXEC(@sql)


	set @process = 'create Job -- Move Recordings'
		if not exists (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Move Recordings')
			set @sql='USE [msdb]
						
						/****** Object:  Job [Move Recordings]    Script Date: 10/28/2015 12:42:47 ******/
						BEGIN TRANSACTION
						DECLARE @ReturnCode INT
						SELECT @ReturnCode = 0
						/****** Object:  JobCategory [Database Maintenance]    Script Date: 10/28/2015 12:42:47 ******/
						IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Database Maintenance'' AND category_class=1)
						BEGIN
						EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Database Maintenance''
						IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

						END

						DECLARE @jobId BINARY(16)
						EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Move Recordings'', 
								@enabled=1, 
								@notify_level_eventlog=2, 
								@notify_level_email=0, 
								@notify_level_netsend=0, 
								@notify_level_page=0, 
								@delete_level=0, 
								@description=N''Moves recordings from RIA_GRABACION to RIA_GRABACIONCONSULTA'', 
								@category_name=N''Database Maintenance'', 
								@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
						IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
						/****** Object:  Step [move and erase]    Script Date: 10/28/2015 12:42:47 ******/
						EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''move and erase'', 
								@step_id=1, 
								@cmdexec_success_code=0, 
								@on_success_action=1, 
								@on_success_step_id=0, 
								@on_fail_action=2, 
								@on_fail_step_id=0, 
								@retry_attempts=0, 
								@retry_interval=0, 
								@os_run_priority=0, @subsystem=N''TSQL'', 
								@command=N''exec trsp_muevegrabaciones'', 
								@database_name=N''CCRecorderRIA'', 
								@flags=0
						IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
						EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
						IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
						EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every day'', 
								@enabled=1, 
								@freq_type=4, 
								@freq_interval=1, 
								@freq_subday_type=1, 
								@freq_subday_interval=0, 
								@freq_relative_interval=0, 
								@freq_recurrence_factor=0, 
								@active_start_date=20080422, 
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
						EndSave:'
					else
			set @sql = ''		
		EXEC(@sql)


	set @process = 'delete DatabaseCentinella'
		if  exists (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DatabaseCentinella')
				set @sql='exec msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1'
			else
				set @sql = ''		
		EXEC(@sql)


	set @process = 'create DatabaseCentinella'
		if  exists (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DatabaseCentinella')
			set @sql='USE [msdb]
					
					/****** Object:  Job [DatabaseCentinella]    Script Date: 10/28/2015 12:46:17 ******/
					BEGIN TRANSACTION
					DECLARE @ReturnCode INT
					SELECT @ReturnCode = 0
					/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 10/28/2015 12:46:17 ******/
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
					/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 10/28/2015 12:46:17 ******/
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
					EndSave:
					'
					else
			set @sql = ''		
		EXEC(@sql)



------------------ End Script @Sql ------------------

UPDATE trec_parametros SET par_valor = @version WHERE par_id = 30

COMMIT tran
END try

BEGIN catch	
	SELECT @errorGenerated = 'DB Script Version: ' + cast(@version AS NVARCHAR) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)
	ROLLBACK tran
END catch
END

ELSE
 BEGIN
	SELECT 'Data base incorrect version ' + cast(@actualVersion AS VARCHAR(5)) + ', please update to  ' + cast(@Version AS VARCHAR(5))
 END
SET nocount off
