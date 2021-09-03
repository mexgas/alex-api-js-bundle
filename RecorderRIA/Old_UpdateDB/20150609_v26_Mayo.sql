/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: José Velasco
Date: 2015/05/18
Description: AVRS

	Add  column IDWG en ria_grabacion
	Add  column IDWG en ria_grabacionConsulta

	Se crea Indice IX_RIA_GRABACION_8 para tabla RIA_grabacion
	Se crea Indice IX_RIA_GRABACIONCONSULTA_6 para tabla RIA_GRABACIONCONSULTA
	Se crea Indice IX_RIA_GRABACIONCONSULTA_8 para tabla RIA_GRABACIONCONSULTA

	Se modifica el SP trsp_muevegrabaciones para versiones diferentes a XION
	Se modifica el SP trsp_AdmRecSearchAllRecs para versiones diferentes a XION
	Se modifica el SP trsp_SaveAVRSExportParameters para la Aplicacion AVRS Recordings Manager

	Se agrega query para reconstruccion


Database: CCRecorderRia
Required version: 25

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 26

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	/* Start script release */
	set @process = 'Alter colum - RIA_NETWORKCREDENTIALS DEFAULT value type'
	set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''TypeNETWORKCREDENTIALS'')
	begin
		ALTER TABLE RIA_NETWORKCREDENTIALS ADD CONSTRAINT TypeNETWORKCREDENTIALS DEFAULT 1 FOR type
	end'
	EXEC(@sql)


	set @process = 'add colum - ria_grabacion'
	set @sql='if not exists (select * from sys.columns where name = N''IDWG'' and Object_ID = Object_ID(N''ria_grabacion''))  ALTER TABLE ria_grabacion ADD IDWG Varchar(800)  NULL '
	EXEC(@sql)

	set @process = 'add colum - ria_grabacionConsulta'
	set @sql='if not exists (select * from sys.columns where name = N''IDWG'' and Object_ID = Object_ID(N''ria_grabacionConsulta'')) ALTER TABLE ria_grabacionConsulta ADD IDWG Varchar(800)  NULL '
	EXEC(@sql)

	set @process = 'create index IX_RIA_GRABACION_8 in ria_grabacion'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_8'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
	begin
		CREATE NONCLUSTERED INDEX [IX_RIA_GRABACION_8] ON [dbo].[RIA_GRABACION]
			(
			 [finicio] ASC,
			 [IDWG] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	end'
	EXEC(@sql)


	set @process = 'create index IX_RIA_GRABACIONCONSULTA_6 in ria_grabacion'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACIONCONSULTA_6'' and object_id = OBJECT_ID(N''RIA_GRABACIONCONSULTA''))
	begin
		CREATE NONCLUSTERED INDEX [ IX_RIA_GRABACIONCONSULTA_6] ON [dbo].[RIA_GRABACIONCONSULTA]
			(
			 [finicio] ASC,
			 [duracion] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	end

'
	EXEC(@sql)


	set @process = 'create index IX_RIA_GRABACIONCONSULTA_8 in ria_grabacion'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACIONCONSULTA_8'' and object_id = OBJECT_ID(N''RIA_GRABACIONCONSULTA''))
	begin
		CREATE NONCLUSTERED INDEX [IX_RIA_GRABACIONCONSULTA_8] ON [dbo].[RIA_GRABACIONCONSULTA]
			(
			 [finicio] ASC,
			 [IDWG] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	end

'
	EXEC(@sql)


	set @process = 'alter SP  - trsp_muevegrabaciones'
	if exists (select * from sys.procedures where name = N'trsp_muevegrabaciones')
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

                           	INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,tamano,dni,duracion,pos_pc,extension,razon_id,nombre_archivo,
							info1,info2,info3,info4,info5,borra_id,fvalida,fvalida2,tipo_Llamada,cam_id,calif_id,id_repositorio,id_nivel_grito,cal_id,cal_key,cal_manual,cal_fcallback,cal_extension,
							cal_whoHung,cal_whoRec,id_plantilla,dni_id,id_rep_video,extra_info,extra_info2,IDWG)
							SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,tamano,dni,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
							info5,borra_id,fvalida,fvalida2,tipo_Llamada,cam_id,calif_id,id_repositorio,id_nivel_grito,cal_id,cal_key,cal_manual,cal_fcallback,cal_extension,cal_whoHung,cal_whoRec,
							id_plantilla,dni_id,id_rep_video,extra_info,extra_info2,IDWG
							FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;

							SET IDENTITY_INSERT RIA_GRABACIONCONSULTA OFF

							DELETE RIA_GRABACION with(rowlock) WHERE [finicio] < @fecha;
                    END
             else  --AVRS Integrada ó AVRS Stand Alone
                    BEGIN
                           SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

                           INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,tamano,dni,duracion,pos_pc,extension,razon_id,nombre_archivo,
                           info1,info2,info3,info4,info5,borra_id,fvalida,fvalida2,tipo_Llamada,cam_id,calif_id,id_repositorio,id_nivel_grito,cal_id,cal_key,cal_manual,cal_fcallback,cal_extension,
                           cal_whoHung,dni_id,id_rep_video,extra_info,extra_info2)
                           SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,tamano,dni,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
                           info5,borra_id,fvalida,fvalida2,tipo_Llamada,cam_id,calif_id,id_repositorio,id_nivel_grito,cal_id,cal_key,cal_manual,cal_fcallback,cal_extension,cal_whoHung,
                           dni_id,id_rep_video,extra_info,extra_info2
                           FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

                           SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

                           DELETE TREC_GRABACION with(rowlock) WHERE [finicio] < @fecha;
                    END
		END'

	EXEC(@Sql)

	set @process = 'alter SP  - trsp_AdmRecSearchAllRecs'
	if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchAllRecs')
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


		SELECT @sql1 = CASE WHEN EXISTS (
			select top 1 1
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_8))
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			where a.finicio BETWEEN  @Finicio AND @Ffin and a.IDWG is not null
			) THEN ''select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
			a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			grab_id as grabID, a.IDWG as IDWG
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_8))
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			where a.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END


		SELECT @sql2 = CASE WHEN EXISTS (
			select top 1 1
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			left join #tempComplete U on  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
			where a.finicio BETWEEN  @Finicio AND @Ffin and U.IDWG is not null
			) THEN ''select  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			a.grab_id as grabID, cast(g.IDWG as nvarchar) as IDWG
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			left join #tempComplete U on
			g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
			where U.IDWG is not null and U.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END


		 SELECT @sql3 = CASE WHEN EXISTS (
			 select top 1 1
			 from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
			 left join ccPosicion b on b.pos_id = a.cal_extension * -1
			 left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
			 left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			 left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			 where a.finicio BETWEEN  @Finicio AND @Ffin and a.IDWG is not null
			 ) THEN ''select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
			 a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			 isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			 isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			 CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			 CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			 grab_id as grabID, a.IDWG as IDWG
			 from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
			 left join ccPosicion b on b.pos_id = a.cal_extension * -1
			 left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
			 left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			 left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			 where a.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END

		 select @sqlUnion = '' union ''

		  if (@sql1 <> '''' and @sql2 <> '''' and @sql3 <> '''' )
             exec (@sql1 + @sqlUnion + @sql2 + @sqlUnion + @sql3 )
          else if (@sql1 <> '''' and @sql2 <> '''' and @sql3 = '''')
             exec (@sql1 + @sqlUnion + @sql2 )
		  else if (@sql1 <> '''' and @sql2 = '''' and @sql3 <> '''')
             exec (@sql1 + @sqlUnion + @sql3 )
		  else if (@sql1 = '''' and @sql2 <> '''' and @sql3 <> '''')
             exec (@sql2 + @sqlUnion + @sql3 )
		  else if (@sql1 <> '''' and @sql2 = '''' and @sql3 = '''')
             exec (@sql1 )
		  else if (@sql1 = '''' and @sql2 <> '''' and @sql3 = '''')
             exec (@sql2 )
		  else if (@sql1 = '''' and @sql2 = '''' and @sql3 <> '''')
             exec (@sql3 )

        drop table #tempRiaFormaCalif
        drop table #tempCampEspWG
		drop table #tempComplete

      END'

	EXEC(@Sql)


	set @process = 'alter SP  - trsp_SaveAVRSExportParameters'
	if exists (select * from sys.procedures where name = N'trsp_SaveAVRSExportParameters')
	set @sql='Alter PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
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

			UPDATE RIA_NETWORKCREDENTIALS
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
	EXEC(@Sql)

	set @process = 'Query reconstruccion IDWG in RIA_GRABACION'
	set @sql='declare @idWgs nvarchar(max) ,@idWgsCorchetes nvarchar(max) ,@sql nvarchar(max)
SELECT @idWgsCorchetes=COALESCE(@idWgsCorchetes + '', '', '''') + convert(varchar(max),QUOTENAME(IDWG)) FROM ccRIACat_WorkGroup
SELECT @idWgs=COALESCE(@idWgs + ''+ '', '''') + ''case when '' + convert(varchar(max),QUOTENAME(IDWG)) + '' is null then '''''''' else cast(''+ convert(varchar(max),QUOTENAME(IDWG)) + '' as nvarchar(max)) + '''','''' end'' FROM ccRIACat_WorkGroup

set @sql=''
select cal_id,User_id,tipo,'' + @idWgs + '' as idWgs
into #tempIDWG from
(select IDWG ,cal_id,User_id,tipo from ccRIAWorkGroup_Calid where timestamp >=  dateadd(dd, datediff(dd, 0, getdate()-90), 0)  and  timestamp  <  dateadd(dd, datediff(dd, 0, getdate()) - 1, 0)     ) a
pivot(
	max(IDWG)
	for idwg in(''+@idWgsCorchetes+'')
)as pvt
select cal_id,User_id,tipo,substring(idWgs,0,len(idWgs)) idWgs from #tempIDWG

UPDATE a
SET a.IDWG= isnull(substring(idWgs,0,len(idWgs)),0)
From RIA_GRABACION a
INNER JOIN  #tempIDWG b ON a.cal_id = b.cal_id and a.age_id=b.User_id and a.tipo_llamada=(b.tipo + 1 )

UPDATE a
SET a.IDWG= isnull(substring(idWgs,0,len(idWgs)),0)
From RIA_GRABACIONConsulta a
INNER JOIN  #tempIDWG b ON a.cal_id = b.cal_id and a.age_id=b.User_id and a.tipo_llamada=(b.tipo + 1 )

drop table #tempIDWG

UPDATE RIA_GRABACIONConsulta SET a.IDWG= 0 where IDWG is NULL
''
	 '
	EXEC(@sql)

	set @process = 'Create job - AVRSSaveWorkGroupCalid'
	set @sql='USE [msdb]


IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''AVRSSaveWorkGroupCalid'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''AVRSSaveWorkGroupCalid'', @delete_unused_schedule=1

/****** Object:  Job [AVRSSaveWorkGroupCalid]    Script Date: 25/05/2015 04:19:57 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT


SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 25/05/2015 04:19:57 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRSSaveWorkGroupCalid'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''This Job allows everyday, save the relations  between ccRIAWorkGroup_Calid and recordings in the new column added in RIAGrabacion (IDWG) so that customers can check the recordings without any problem after the purification process in  ccRIAWorkGroup_Calid'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AVRSSaveWorkgroupCalidTask]    Script Date: 25/05/2015 04:19:58 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''AVRSSaveWorkgroupCalidTask'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''declare @idWgs nvarchar(max) ,@idWgsCorchetes nvarchar(max) ,@sql nvarchar(max)
SELECT @idWgsCorchetes=COALESCE(@idWgsCorchetes + '''', '''', '''''''') + convert(varchar(max),QUOTENAME(IDWG)) FROM ccRIACat_WorkGroup
SELECT @idWgs=COALESCE(@idWgs + ''''+ '''', '''''''') + ''''case when '''' + convert(varchar(max),QUOTENAME(IDWG)) + '''' is null then '''''''''''''''' else cast(''''+ convert(varchar(max),QUOTENAME(IDWG)) + '''' as nvarchar(max)) + '''''''','''''''' end'''' FROM ccRIACat_WorkGroup

set @sql=''''
select cal_id,User_id,tipo,'''' + @idWgs + '''' as idWgs
into #tempIDWG from
(select IDWG ,cal_id,User_id,tipo from ccRIAWorkGroup_Calid where timestamp >=  DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()-1))  and  timestamp  <  DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))     ) a
pivot(
	max(IDWG)
	for idwg in(''''+@idWgsCorchetes+'''')
)as pvt
select cal_id,User_id,tipo,substring(idWgs,0,len(idWgs)) idWgs from #tempIDWG


UPDATE a
SET a.IDWG= substring(idWgs,0,len(idWgs))
From RIA_GRABACION a
INNER JOIN  #tempIDWG b ON a.cal_id = b.cal_id and a.age_id=b.User_id and a.tipo_llamada=(b.tipo + 1 )

drop table #tempIDWG
''''
exec(@sql)
'',
		@database_name=N''CCRecorderRIA'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''AVRSSaveWorkgroupCalidSchedule'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20150522,
		@active_end_date=99991231,
		@active_start_time=4000,
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
		update trec_parametros set par_valor = @Version where par_id = 30

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