/*
Fecha: 2014/05/12
Descripcion: 	

Version requerida: 14
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 16
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Alter Table - [dbo.RIA_NETWORKCREDENTIALS]'
	set @Sql='
		ALTER TABLE dbo.RIA_NETWORKCREDENTIALS ADD status tinyint DEFAULT '''' NOT NULL ;
	'
	EXEC(@Sql)

	set @process = 'Alter Table - [TREC_REPOSITORIOS]'
	set @Sql='
		ALTER TABLE dbo.TREC_REPOSITORIOS ADD ruta_local_imagenes  text  DEFAULT '''' NOT NULL ;
	'
	EXEC(@Sql)


	set @process = 'Create table - TREC_REPO_NWCREDENTIALS'
	set @Sql='
	CREATE TABLE [dbo].[TREC_REPO_NWCREDENTIALS](
	[id_repository] [int] NOT NULL,
	[id_nwCredential] [int] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[id_repository] ASC,
		[id_nwCredential] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	'
	EXEC(@Sql)
	

	set @process = 'Alter procedure - trsp_GetFilesAnalisisGritos'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
	--@idRepositorios as varchar(32),
	@sExtension as varchar(10) = ''.vox''
	AS

	declare @Integrado as int
	declare @FInicio as datetime
	declare @sSql1 as nvarchar(180)
	declare @sSql2 as nvarchar (180)
	declare @sSql3 as nvarchar(180) 
	declare @sSql as nvarchar (512)
	declare @dLenAnt as tinyint
	declare @dLenNew as tinyint


	set @FInicio = dateadd(MINUTE, -1, getdate())
	set @sSql = N''
	set @sSql3 = N''
	set @sExtension = (select par_valor from trec_parametros where par_id = 54)

	select @integrado = par_valor from trec_parametros where par_id = 29

	--AVRS Integrada
	if (@integrado = 1)

		BEGIN

			set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
			set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
			set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

		END

	--AVRS Standalone
	else if(@integrado = 0)

		BEGIN

			set @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
			set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
			set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

		END

	--AVRS XION
	else if(@integrado = 2)
		BEGIN

			set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
			set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from ria_grabacion NOLOCK where finicio < @fecInicio ''
			set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

		END

	set @sSql = @sSql1 + @sSql2 + N'' order by finicio asc''
	exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio	
	'
	EXEC(@Sql)


	set @process = 'Alter procedure - trsp_GetNetworkCredentials'
	set @Sql='
	CREATE PROCEDURE [dbo].[trsp_GetNetworkCredentials]
	@id integer = 0,
	@domain varchar(50) = ''''
	AS
	BEGIN
		
		IF @id <> 0
			
			BEGIN

				SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
				FROM TREC_NETWORKCREDENTIALS 
				JOIN TREC_REPO_NWCREDENTIALS
				ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
				WHERE TREC_NETWORKCREDENTIALS.[id] = @id AND TREC_NETWORKCREDENTIALS.[status]=1

			END

		ELSE

			BEGIN
				IF LEN(@domain) > 0
					BEGIN
						SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
						FROM TREC_NETWORKCREDENTIALS 
						JOIN TREC_REPO_NWCREDENTIALS
						ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
						WHERE TREC_NETWORKCREDENTIALS.domain = @domain AND TREC_NETWORKCREDENTIALS.[status]=1
					END
				ELSE
					BEGIN
						SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
						FROM TREC_NETWORKCREDENTIALS 
						JOIN TREC_REPO_NWCREDENTIALS
						ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
						WHERE TREC_NETWORKCREDENTIALS.[status]=1
					END
			END

	END
	'
	EXEC(@Sql)

	set @process = 'Alter procedure - trsp_AdmRecSearchAllRecs'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]

	@Sup_id int,
	@Finicio datetime,
	@Ffin datetime

	AS
	BEGIN

		SET NOCOUNT ON;

	declare @fecha  datetime

	set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

		select r.id_grabacion, avg(r.total_forma) as total_forma
		into #tempRiaFormaCalif from ria_formacalif r 
		inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
		on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
		group by r.id_grabacion		
		
		select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
		into #tempCampEspWG from ccRIACampEspWGConsulta a 
		inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG


	if (@Finicio >= @fecha and @Ffin >= @fecha) 
		begin
		
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
			where a.finicio BETWEEN  @Finicio AND @Ffin
				

		end
	else if (@Finicio < @fecha and @Ffin < @fecha ) 
		begin
		
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
			from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3)) 		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN  @Finicio AND @Ffin
		
		end
	else if (@Finicio <= @fecha and @Ffin >= @fecha ) 
		begin
			select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, 
			a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN  @Finicio AND @Ffin
			union
			select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
			from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN  @Finicio AND @Ffin

		end

		drop table #tempRiaFormaCalif
		drop table #tempCampEspWG
		
	END
	'
	EXEC(@Sql)

		set @process = 'Delete and Create - Job ReportsMasterProcessAVRS'
		set @Sql='USE [msdb]

/****** Object:  Job [ReportsMasterProcessAVRS]    Script Date: 07/10/2014 11:57:31 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ReportsMasterProcessAVRS'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessAVRS'', @delete_unused_schedule=1

/****** Object:  Job [ReportsMasterProcessAVRS]    Script Date: 07/10/2014 11:57:55 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/10/2014 11:57:55 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessAVRS'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcessAVRS'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 07/10/2014 11:57:55 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessAVRS'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportsMasterProcessAVRS'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
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