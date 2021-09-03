/*

Fecha: 2014/03/07
Descripcion: 
* Se crea el indice IX_RIA_GRABACION_1 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACIONCONSULTA_1 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACION_2 para mejora en el performance del proceso
* Se crea el indice X_RIA_GRABACIONCONSULTA_2 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACION_3 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACIONCONSULTA_3 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACION_4 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACIONCONSULTA_4 para mejora en el performance del proceso 
* Se crea el indice IX_RIA_GRABACION_5 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACIONCONSULTA_5 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACION_6 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACION_7 para mejora en el performance del proceso
* Se crea el indice IX_RIA_GRABACIONCONSULTA_7 para mejora en el performance del proceso
* Se crea el indice IX_TREC_BACKUPS_1 para mejora en el performance del proceso
* Se crean job para CCRecorderRIA
* Se altera store trsp_AdmSaveSupervisorMarks
* Se altera store trsp_AdmUpdateSaveScores
* Se altera store trsp_AdmVerifyingFormatEditing
* Se altera store trsp_AdmVerifyMarksToExport
* Se altera store trsp_GetListaBorrarRespaldo
* Se altera store trsp_GetListaBorrarSinRespaldo
* Se altera store trsp_GetCompleteBackupRange
* Se altera store trsp_AdmAVRSReportCallInfo
* Se altera store trsp_AdmCheckForMarks
* Se altera store trsp_AdmGetFormatsScored
* Se altera store trsp_AdmGetInfoFormatScored
* Se altera store trsp_AdmGetMarkTimeToCut
* Se altera store trsp_AdmGetNumericAnswer
* Se altera store trsp_AdmGetSupervisorsForAgent
* Se altera store trsp_ConsultaGrabaciones
* Se altera store trsp_GetFilesForBackup
* Se altera store trsp_GetFilesForBackupVal
* Se altera store trsp_GetFilesForBackupVal2
* Se altera store trsp_GetFilesToDelete
* Se altera store trsp_GetFirstBackupFile
* Se altera store trsp_AdmUpdateRecordingCoaaching
* Se altera store trsp_AdmSaveScoresFormaCalif
* Se altera store trsp_AdmRecSearchAllRecs *checar*
* Se altera store trsp_AdmRecSearchCalID *checar*
* Se altera store trsp_AdmRecSearchOneDay *checar*
* Se altera store trsp_AgtGetRepositoryCallHistory
* Se altera store trsp_AdmAVRSReportDemo
* Se altera store trsp_AdmX *checar*
* Se crea stored trsp_AdmGetRecordingsBackup
* Se crea stored trsp_AdmGetPathsBackup


* Se crea tabla RIA_NETWORKCREDENTIALS
* Se crea store trsp_AdmGetNetworkCredential
* Se modifica store trsp_AdmAVRSReportDemo
* Se modifica store trsp_AdmAVRSReportCallInfo
* Se modifica funcion ft_getTime
* Se modifica store trsp_GetFilesAnalisisGritos


* Se modifica store procedure trsp_AdmAVRSReportLanguage para adquirir el lenguage de los formatos de calificacion AVRS

* Se modifica stored procedure ReportsMasterProcessAVRS para reinicializar suscripciones en caso de error

Version requerida: 11

*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 12
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------

-- * Se crea el indice IX_RIA_GRABACION_1 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_1 - Create Index'
set @Sql='
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_1'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_1 ON RIA_GRABACION(tipo_llamada,cal_id); 
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACIONCONSULTA_1 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACIONCONSULTA_1 - Create Index'
set @Sql='
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACIONCONSULTA_1'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_1 ON RIA_GRABACIONCONSULTA(tipo_llamada,cal_id);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACION_2 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_2 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_2'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_2 ON RIA_GRABACION(grab_id,duracion);
END'
EXEC(@Sql)
--* Se crea el indice X_RIA_GRABACIONCONSULTA_2 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACIONCONSULTA_2 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACIONCONSULTA_2'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_2 ON RIA_GRABACIONCONSULTA(grab_id,duracion);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACION_3 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_3 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_3'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_3 ON RIA_GRABACION(finicio); 
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACIONCONSULTA_3 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACIONCONSULTA_3 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACIONCONSULTA_3'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_3 ON RIA_GRABACIONCONSULTA(finicio);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACION_4 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_4 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_4'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_4 ON RIA_GRABACION(grab_id,tamano,duracion);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACIONCONSULTA_4 para mejora en el performance del proceso 
set @process = 'IX_RIA_GRABACIONCONSULTA_4 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACIONCONSULTA_4'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_4 ON RIA_GRABACIONCONSULTA(grab_id,tamano,duracion);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACION_5 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_5 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_5'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_5 ON RIA_GRABACION(duracion); 
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACIONCONSULTA_5 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACIONCONSULTA_5 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACIONCONSULTA_5'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_5 ON RIA_GRABACIONCONSULTA(duracion); 
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACION_6 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_6 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_6'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_6 ON RIA_GRABACION(finicio,duracion);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACION_7 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACION_7 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACION_7'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_7 ON RIA_GRABACION(cal_id);
END'
EXEC(@Sql)
--* Se crea el indice IX_RIA_GRABACIONCONSULTA_7 para mejora en el performance del proceso
set @process = 'IX_RIA_GRABACIONCONSULTA_7 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_RIA_GRABACIONCONSULTA_7'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_7 ON RIA_GRABACIONCONSULTA(cal_id); 
END'
EXEC(@Sql)
--* Se crea el indice IX_TREC_BACKUPS_1 para mejora en el performance del proceso
set @process = 'IX_TREC_BACKUPS_1 - Create Index'
set @Sql='IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_TREC_BACKUPS_1'') 
BEGIN
	CREATE NONCLUSTERED INDEX IX_TREC_BACKUPS_1 ON TREC_BACKUPS(status_audio);
END'
EXEC(@Sql)

-- Se crean job para CCRecorderRIA
set @process = 'Shrink-IndexOptimizationRIA - Create Job'
set @Sql='
/****** Object:  Job [Shrink-IndexOptimizationRIA]    Script Date: 02/18/2014 12:05:15 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/18/2014 12:05:15 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Shrink-IndexOptimizationRIA'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Shrink de la base de datos y optimizacion de los indices de ria grabacion y ria grabacion consulta'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink]    Script Date: 02/18/2014 12:05:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKDATABASE (CCRecorderRIA)'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [trsp_OrganizeIndexes]    Script Date: 02/18/2014 12:05:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''trsp_OrganizeIndexes'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec dbo.trsp_OrganizeIndexes'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Shrink'', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=2, 
		@active_start_date=20111127, 
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
EXEC(@Sql)
--* Se altera store trsp_AdmSaveSupervisorMarks
set @process = 'trsp_AdmSaveSupervisorMarks - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmSaveSupervisorMarks]
    -- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@user_id int,
@marca nvarchar(MAX)


AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @grab_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

insert CCRecorderRIA.dbo.RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grab_id,@user_id,@marca,2,@tipo_llamada,@cal_id )

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmUpdateSaveScores
set @process = 'trsp_AdmUpdateSaveScores - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmUpdateSaveScores]
	-- Add the parameters for the stored procedure here

@id_forma int,
@cal_id int,
@tipo_llamada int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@version int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


declare @grab_id int

set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

Delete from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma

Update CCRecorderRIA.dbo.RIA_FORMACALIF 
set fecha_calif = GetDate(), id_calificador=@id_calificador,id_supervisor=@id_supervisor,total_forma=@total_forma, version=@version 
where id_forma=@id_forma and id_grabacion=@grab_id and id_formato=@id_formato

select @id_forma

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmVerifyingFormatEditing
set @process = 'trsp_AdmVerifyingFormatEditing - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmVerifyingFormatEditing]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@id_formato int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @grab_id int,
@id_forma int

    -- Insert statements for procedure here

set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

set @id_forma = (Select isnull(id_forma,0) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id and id_formato = @id_formato)


--Retrieving the id forma
select isnull(@id_forma,0)

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmVerifyMarksToExport
set @process = 'trsp_AdmVerifyMarksToExport - Alter Procedure'
set @Sql='
ALTER PROCEDURE  [dbo].[trsp_AdmVerifyMarksToExport]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada smallint

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @grab_id int


if @tipo_llamada = 1
begin

set @grab_id = (select top 1 * from (select top 1 grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = 1 order by 1 union select top 1 grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id=@cal_id and tipo_llamada =1 order by 1) x order by 1)
select count (*) from CCRECORDERRIA.dbo.RIA_MARCAS where grab_id=@grab_id


end
-- Retrieve the mark information from an outbound call
else
begin

set @grab_id = (select top 1 * from (select top 1 grab_id  from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = 2 order by 1 union select top 1  grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id=@cal_id and tipo_llamada =2 order by 1) x order by 1)
select count (*) from CCRECORDERRIA.dbo.RIA_MARCAS where grab_id=@grab_id

end

END
'
	EXEC(@Sql)
--* Se altera store trsp_GetListaBorrarRespaldo
set @process = 'trsp_GetListaBorrarRespaldo - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetListaBorrarRespaldo]
@cwIntegrated AS INT,
@cwIntegratedAVRSRIA AS INT
AS
BEGIN
    IF @cwIntegrated = 1
	BEGIN
	    select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio from TREC_BACKUPS inner join 
		(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
		ON TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 order by grab_id asc;

	END
	ELSE IF @cwIntegratedAVRSRIA = 1
	BEGIN
		select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio from TREC_BACKUPS inner join 
		(select grab_id, cal_id, Tipo_Llamada from RIA_GRABACION union select grab_id, cal_id, Tipo_Llamada from RIA_GRABACIONCONSULTA)as GRABACIONES
		ON TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 order by grab_id asc;
	END
	ELSE
	BEGIN
	    select top 10000 grab_id, status_audio from trec_backups with (index(IX_TREC_BACKUPS_1)) where status_audio = 1 order by grab_id asc
	END
END
'
	EXEC(@Sql)
--* Se altera store trsp_GetListaBorrarSinRespaldo
set @process = 'trsp_GetListaBorrarSinRespaldo - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetListaBorrarSinRespaldo]
@cwIntegrated AS INT,
@cwIntegratedRIA AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @maxBorrado INT
	DECLARE @datosTabla INT
	DECLARE @maxGrabId INT

    -- Insert statements for procedure here
	SELECT @maxBorrado = MAX(grab_id) from trec_backups with (index(IX_TREC_BACKUPS_1)) where  status_audio = 4 or status_audio = 5;
	SELECT @datosTabla = COUNT(grab_id) from trec_backups where grab_id > @maxBorrado;
	SELECT @maxGrabId = MAX(grab_id) from trec_backups;
	IF @datosTabla < 10000
	   BEGIN
			IF @cwIntegratedRIA = 1
				BEGIN
					insert into TREC_BACKUPS (grab_id,status_audio)
					select grab_id,2 as status_audio from RIA_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);
				END
			ELSE
				BEGIN
					insert into TREC_BACKUPS (grab_id,status_audio)
					select grab_id,2 as status_audio from TREC_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);
				END		
	   END
	IF @cwIntegrated = 1
	    BEGIN
		select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
		(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
		on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
	ELSE IF @cwIntegratedRIA = 1
		BEGIN
			select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
			(select grab_id, cal_id, Tipo_Llamada from RIA_GRABACION union select grab_id, cal_id, Tipo_Llamada from RIA_GRABACIONCONSULTA)as GRABACIONES
			on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;
		END
	ELSE
	    BEGIN
		select top 10000 grab_id, status_audio, status_video from trec_backups with (index(IX_TREC_BACKUPS_1)) where  status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
END
'
	EXEC(@Sql)
--* Se altera store trsp_GetCompleteBackupRange
set @process = 'trsp_GetCompleteBackupRange - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetCompleteBackupRange]
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

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmAVRSReportCallInfo
set @process = 'trsp_AdmAVRSReportCallInfo - Alter Procedure'
set @Sql='
ALTER  PROCEDURE [dbo].[trsp_AdmAVRSReportCallInfo]
@id_formato int,
@version int,
@call_id int,
@tipo int
AS
BEGIN
declare @id_grabacion as int


IF EXISTS (select grab_id from ria_grabacion with (index(IX_RIA_GRABACION_1)) where cal_id=@call_id and tipo_llamada=@tipo)
	BEGIN
		
		set @id_grabacion = (select grab_id from ria_grabacion with (index(IX_RIA_GRABACION_1)) where cal_id=@call_id and tipo_llamada=@tipo)

		SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
		  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACION.ani AS Telfono ,Tipo=
																				CASE WHEN (SELECT tipo_llamada 
																						    FROM RIA_GRABACION 
																					        WHERE grab_id=@id_grabacion)=1 THEN ''inbound'' 
																				ELSE ''outbound''
																			    END,
						      RIA_GRABACION.finicio AS Fecha,RIA_GRABACION.cal_id AS [Id de llamada],RIA_GRABACION.grab_id AS [Id de Grabacion],
							  RIA_GRABACION.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACION.duracion,''2'') AS Duracion,
							  [Campaña/GrupO ACD]=
							    CASE WHEN (SELECT tipo_llamada 
										   FROM RIA_GRABACION 
										   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																	   FROM RIA_GRABACION INNER JOIN
																	   ccInbound ON RIA_GRABACION.cam_id = ccInbound.Inbound_id
																	   WHERE (RIA_GRABACION.grab_id = @id_grabacion)) 
		     					ELSE (SELECT     ccCamps.cam_descripcion
									  FROM       RIA_GRABACION INNER JOIN
									  ccCamps ON RIA_GRABACION.cam_id = ccCamps.cam_id
									  WHERE     (RIA_GRABACION.grab_id = @id_grabacion))
								END,
							  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
					    FROM  RIA_FORMACALIF INNER JOIN
							 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
							  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
							  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
							  RIA_GRABACION ON RIA_FORMACALIF.id_grabacion = RIA_GRABACION.grab_id INNER JOIN
							  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
						WHERE RIA_FORMACALIF.id_formato=@id_formato and
							  RIA_FORMACALIF.version=@version and
							  RIA_FORMACALIF.id_grabacion=@id_grabacion and
							  RIA_FORMATOS.version=@version

	END
ELSE
	BEGIN

		set @id_grabacion =(select grab_id from RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1))  where cal_id=@call_id and tipo_llamada=@tipo)

		SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
		  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACIONCONSULTA.ani AS Telfono ,Tipo=
																				CASE WHEN (SELECT tipo_llamada 
																						    FROM RIA_GRABACIONCONSULTA 
																					        WHERE grab_id=@id_grabacion)=1 THEN ''inbound''
																				ELSE ''outbound''
																			    END,
						      RIA_GRABACIONCONSULTA.finicio AS Fecha,RIA_GRABACIONCONSULTA.cal_id AS [Id de llamada],RIA_GRABACIONCONSULTA.grab_id AS [Id de Grabacion],
							  RIA_GRABACIONCONSULTA.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACIONCONSULTA.duracion,''2'') AS Duracion,
							  [Campaña/GrupO ACD]=
							    CASE WHEN (SELECT tipo_llamada 
										   FROM RIA_GRABACIONCONSULTA 
										   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																	   FROM RIA_GRABACIONCONSULTA INNER JOIN
																	   ccInbound ON RIA_GRABACIONCONSULTA.cam_id = ccInbound.Inbound_id
																	   WHERE (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion)) 
		     					ELSE (SELECT     ccCamps.cam_descripcion
									  FROM       RIA_GRABACIONCONSULTA INNER JOIN
									  ccCamps ON RIA_GRABACIONCONSULTA.cam_id = ccCamps.cam_id
									  WHERE     (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion))
								END,
							  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
					    FROM  RIA_FORMACALIF INNER JOIN
							 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
							  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
							  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
							  RIA_GRABACIONCONSULTA ON RIA_FORMACALIF.id_grabacion = RIA_GRABACIONCONSULTA.grab_id INNER JOIN
							  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
						WHERE RIA_FORMACALIF.id_formato=@id_formato and
							  RIA_FORMACALIF.version=@version and
							  RIA_FORMACALIF.id_grabacion=@id_grabacion and
							  RIA_FORMATOS.version=@version

	END
								
END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmCheckForMarks
set @process = 'trsp_AdmCheckForMarks - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmCheckForMarks]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @grab_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


select count(*) from CCRecorderRIA.dbo.RIA_MARCAS where grab_id = @grab_id

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmGetFormatsScored
set @process = 'trsp_AdmGetFormatsScored - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmGetFormatsScored]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


declare @grab_id int

set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

 
select distinct id_formato from CCRecorderRIa.dbo.RIA_FORMACALIF where id_grabacion = @grab_id


END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmGetInfoFormatScored
set @process = 'trsp_AdmGetInfoFormatScored - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmGetInfoFormatScored]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@id_formato int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @version int,
@grab_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

set @version = (select MAX(version) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id and id_formato = @id_formato)
select id_forma, fecha_calif, id_calificador, id_supervisor, id_grabacion, id_formato,total_forma,age_id, version from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @grab_id and id_formato = @id_formato

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmGetMarkTimeToCut
set @process = 'trsp_AdmGetMarkTimeToCut - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmGetMarkTimeToCut]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada smallint


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @grab_id int

-- Retrieve the mark information from an inbound call
if @tipo_llamada = 1
begin

set @grab_id = (select top 1 * from (select top 1 grab_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = 1 order by 1 union select top 1 grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id=@cal_id and tipo_llamada =1 order by 1) x order by 1)
select top 1 isnull(marca,''00:00:00'') from CCRECORDERRIA.dbo.RIA_MARCAS where grab_id=@grab_id  order by 1


end
-- Retrieve the mark information from an outbound call
else
begin


set @grab_id = (select top 1 * from (select top 1 grab_id  from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = 2 order by 1 union select top 1  grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id=@cal_id and tipo_llamada =2 order by 1) x order by 1)
select top 1 isnull(marca,''00:00:00'') from CCRECORDERRIA.dbo.RIA_MARCAS where grab_id=@grab_id order by 1


end

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmGetNumericAnswer
set @process = 'trsp_AdmGetNumericAnswer - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmGetNumericAnswer]
	-- Add the parameters for the stored procedure here

@id_formato int,
@version int,
@id_pregunta int,
@cal_id int,
@tipo_llamada int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @id_forma as int,
@grab_id as int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

set @id_forma = (select id_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @grab_id and id_formato = @id_formato)

select ISNULL(peso,0) from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma and id_pregunta = @id_pregunta


END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmGetSupervisorsForAgent
set @process = 'trsp_AdmGetSupervisorsForAgent - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmGetSupervisorsForAgent]

@cal_id int,
@tipo_llamada int

AS
BEGIN

	SET NOCOUNT ON;

declare @age_id int

set @age_id = (select age_id from (select age_id from RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada)x)


select distinct a1.user_id as agt, a5.user_id as sup, a5.login from ccusers a1 
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join 
(select a3.user_id, a4.IDWG, a3.login  from ccusers a3 
inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)
where a1.user_id = @age_id
order by a1.user_id,a5.user_id

END
'
	EXEC(@Sql)
--* Se altera store trsp_ConsultaGrabaciones
set @process = 'trsp_ConsultaGrabaciones - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_ConsultaGrabaciones]
@tipoGrabacion  varchar(255),
@incluidos  varchar(5000),
@inicio datetime = 0,
@fin datetime = 0,
@duracionMin int = 0,
@duracionMax int = 0

AS

declare @fecha datetime

set @fecha = CAST(convert(VARCHAR(8), GETDATE()-31, 1) AS DATETIME)

if (@inicio > @fecha)
begin
select g.grab_id as Num, g.extension as Ext, g.finicio as Inicio, g.duracion as Duracion, age_id as Agente, puerto_id as Puerto
from RIA_GRABACION g with (index(IX_RIA_GRABACION_5)) 
where g.duracion > 5
end
else
begin
select g.grab_id as Num, g.extension as Ext, g.finicio as Inicio, g.duracion as Duracion, age_id as Agente, puerto_id as Puerto
from RIA_GRABACIONCONSULTA g with (index(IX_RIA_GRABACIONCONSULTA_5)) 
where g.duracion > 5
end

/*Select g.age_id, a.age_ap_paterno, a.age_ap_materno, a.age_nombre, g.grab_id, g.tipo_grab_id, g.cli_id, g.finicio, g.dvd_id, g.ani, 
g.tamano, g.dni, g.nombre_archivo, g.duracion, c.cli_nombre, g.extension, g.pos_pc  
>From TREC_GRABACION g, TREC_AGENTE a, TREC_CLIENTE c, TREC_MONITOR_EXTENSION b 
Where g.age_id *= a.age_id  and g.cli_id *= c.cli_id and g.extension*= b.mon_extension and duracion > 5
*/
'
	EXEC(@Sql)
--* Se altera store trsp_GetFilesForBackup
set @process = 'trsp_GetFilesForBackup - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetFilesForBackup]
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

END
'
	EXEC(@Sql)
--* Se altera store trsp_GetFilesForBackupVal
set @process = 'trsp_GetFilesForBackupVal - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetFilesForBackupVal]
@start INT,
@end INT
AS
DECLARE @MinTime AS INT
Declare @ExistHist as bit

BEGIN

	if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONConsulta]''))
		set @ExistHist = 1
	else
		set @ExistHist = 0
	SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
	IF (@MinTime is NULL)
	BEGIN
		SELECT @MinTime=0
	END
	if @ExistHist = 1
	begin
		SELECT grab_id, finicio, fvalida FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
		union
		SELECT grab_id, finicio, fvalida FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
	end
	else
		SELECT grab_id, finicio, fvalida FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
END  
'
	EXEC(@Sql)
--* Se altera store trsp_GetFilesForBackupVal2
set @process = 'trsp_GetFilesForBackupVal2 - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetFilesForBackupVal2]
@start INT,
@end INT
AS

DECLARE @MinTime AS INT
Declare @ExistHist as bit

BEGIN

	if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONConsulta]''))
		set @ExistHist = 1
	else
		set @ExistHist = 0
	SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
	IF (@MinTime is NULL)
	BEGIN
		SELECT @MinTime=0
	END
	if @ExistHist = 1
	begin
		SELECT grab_id, finicio, fvalida2 FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
		union
		SELECT grab_id, finicio, fvalida2 FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
	end
	else
		SELECT grab_id, finicio, fvalida2 FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
END  
'
	EXEC(@Sql)
--* Se altera store trsp_GetFilesToDelete
set @process = 'trsp_GetFilesToDelete - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetFilesToDelete]
@finicio as datetime,
@ffin as datetime,
@sinLimite as bit,
@duracion as int
 AS
IF @sinLimite=1
BEGIN
	SELECT grab_id FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3)) WHERE finicio BETWEEN @finicio AND @ffin
END
ELSE
BEGIN
	SELECT grab_id FROM RIA_GRABACION with (index(IX_RIA_GRABACION_6)) WHERE finicio BETWEEN @finicio AND @ffin AND duracion<@duracion
END
'
	EXEC(@Sql)
--* Se altera store trsp_GetFirstBackupFile
set @process = 'trsp_GetFirstBackupFile - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_GetFirstBackupFile]
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

END 
'
	EXEC(@Sql)
--* Se altera store trsp_AdmUpdateRecordingCoaaching
set @process = 'trsp_AdmUpdateRecordingCoaaching - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmUpdateRecordingCoaaching]
@coaching_Id int,
@call_Id int,
@call_Type int
AS
BEGIN
	
	IF EXISTS( SELECT 1 FROM RIA_GRABACION with (index(IX_RIA_GRABACION_1)) WHERE cal_id = @call_Id AND tipo_llamada = @call_Type )

		BEGIN

			UPDATE RIA_GRABACION
			SET calif_id = @coaching_Id
			WHERE cal_id = @call_Id AND tipo_llamada = @call_Type

		END

	ELSE

		BEGIN

			UPDATE RIA_GRABACIONCONSULTA
			SET calif_id = @coaching_Id
			WHERE cal_id = @call_Id AND tipo_llamada = @call_Type

		END
END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmSaveScoresFormaCalif
set @process = 'trsp_AdmSaveScoresFormaCalif - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmSaveScoresFormaCalif]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@version int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @grab_id int,
@age_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
set @age_id = (select age_id from (select age_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


Insert CCRecorderRIA.dbo.RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version)
values
(GetDate(),@id_calificador,@id_supervisor,@grab_id,@id_formato,@total_forma,@age_id,@version)

select Scope_Identity()

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmRecSearchAllRecs
set @process = 'trsp_AdmRecSearchAllRecs - Alter Procedure'
set @Sql=
'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]

@Sup_id int,
@Finicio datetime,
@Ffin datetime

AS
BEGIN

	SET NOCOUNT ON;

declare @fecha  datetime

set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

if (@Finicio >= @fecha and @Ffin >= @fecha) 
	begin
	with temp as (
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, a.grab_id as grabID
        from RIA_GRABACION a with (index(IX_RIA_GRABACION_3)) 
		left join ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		ccTipoCalif AS f ON a.calif_id = f.calif_id
		
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
			   )
			 )
		   )

		--order by finicio desc
		)	
	select distinct cal_id, Tipo_llamada, cam_id, calif_id, duracion, id_nivel_grito, age_id,
		finicio, ani, dni, cal_key,cal_manual,
		pos_id, Computer,
		total_forma,id_repositorio,score,
		formato_duracion,grabID from temp
	end
else if (@Finicio < @fecha and @Ffin < @fecha ) 
	begin
	with temp as (
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, a.grab_id as grabID
        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3)) 
		left join ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		ccTipoCalif AS f ON a.calif_id = f.calif_id
		
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
			   )
			 )
		   )

		--order by finicio desc
		)	
	select distinct cal_id, Tipo_llamada, cam_id, calif_id, duracion, id_nivel_grito, age_id,
		finicio, ani, dni, cal_key,cal_manual,
		pos_id, Computer,
		total_forma,id_repositorio,score,
		formato_duracion,grabID from temp
	end
else if (@Finicio <= @fecha and @Ffin >= @fecha ) 
	begin
	with temp as (	
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, a.grab_id as grabID
        from RIA_GRABACION a with (index(IX_RIA_GRABACION_3)) 
		left join ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		ccTipoCalif AS f ON a.calif_id = f.calif_id
		
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
			   )
			 )
		  )
		UNION ALL	
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, a.grab_id as grabID
        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3)) 
		left join ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		ccTipoCalif AS f ON a.calif_id = f.calif_id
		--****
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		--****
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
			   )
			 )
		   )

		--order by finicio desc	
		)	
	    select distinct cal_id, Tipo_llamada, cam_id, calif_id, duracion, id_nivel_grito, age_id,
		finicio, ani, dni, cal_key,cal_manual,
		pos_id, Computer,
		total_forma,id_repositorio,score,
		formato_duracion,grabID from temp
	end
END'

EXEC(@Sql)
--* Se altera store trsp_AdmRecSearchCalID
set @process = 'trsp_AdmRecSearchCalID - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
	-- Add the parameters for the stored procedure here
@Sup_id int,
@CalID int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
with temp as (
select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (z.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from RIA_GRABACION a with (index(IX_RIA_GRABACION_7)) 
left join ccPosicion b
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
--****
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		--****
where 
(a.cal_id = @CalID)
and(
(Tipo_llamada = 2 and
a.cam_id in 
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1))
OR 
(Tipo_llamada = 1 and
a.cam_id in
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))
UNION ALL
select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (z.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_7)) 
left join ccPosicion b
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
--****
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		--****
where 
(a.cal_id = @CalID)
and(
	(Tipo_llamada = 2 and
	 a.cam_id in 
	 (select distinct a.IdCampEsp from CCRIACampEspWG a
	  inner join  ccRIAWorkGroupUsers b
	  on b.User_id = @Sup_id
	  inner join ccRIACat_WorkGroup c
	  on c.IDWG = a.IDWG
	  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
     )
    )
OR 
   (Tipo_llamada = 1 and
	 a.cam_id in
    (select distinct a.IdCampEsp from CCRIACampEspWG a
     inner join  ccRIAWorkGroupUsers b
     on b.User_id = @Sup_id
     inner join ccRIACat_WorkGroup c
     on c.IDWG = a.IDWG
     where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
    )
   )
  )
--order by finicio desc
)
select distinct cal_id, Tipo_llamada, cam_id, calif_id, duracion, id_nivel_grito, age_id,
		finicio, ani, dni, cal_key,cal_manual,
		pos_id, Computer,
		total_forma,id_repositorio,score,
		formato_duracion from temp
END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmRecSearchOneDay
set @process = 'trsp_AdmRecSearchOneDay - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]

@Sup_id int

AS
BEGIN

	SET NOCOUNT ON;
with temp as (
select  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, a.cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer, 
isnull (z.total_forma,0) as total_forma, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, a.grab_id as grabID

from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
left join ccPosicion b 
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
--****
		left JOIN (select r.id_grabacion, avg(r.total_forma) as total_forma 
					from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif 
					group by id_grabacion,id_formato)t 
					on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
					group by r.id_grabacion)z 
		on a.grab_id=z.id_grabacion
		--****
where 
(a.finicio >= Convert(nvarchar(11),Getdate(),120))
and(
(Tipo_llamada = 2 and
a.cam_id in 
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1))
OR
(Tipo_llamada = 1 and
a.cam_id in
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))

--order by finicio desc
)
select distinct cal_id, Tipo_llamada, cam_id, calif_id, duracion, id_nivel_grito, age_id,
		finicio, ani, dni, cal_key,cal_manual,
		pos_id, Computer,
		total_forma,id_repositorio,score,
		formato_duracion,grabID from temp
END
'
	EXEC(@Sql)
--* Se altera store trsp_AgtGetRepositoryCallHistory
set @process = 'trsp_AgtGetRepositoryCallHistory - Alter Procedure'
set @Sql='
ALTER PROCEDURE  [dbo].[trsp_AgtGetRepositoryCallHistory]

@CallID int,
@Tipo_llamada smallint


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @IDRepositorio int

set @IDRepositorio = (select id_repositorio from RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @CallID and tipo_llamada = @Tipo_llamada UNION select id_repositorio from RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @CallID and tipo_llamada = @Tipo_llamada)

select isnull(dirvirtual_audio,'''') as dirvirtual_audio  from TREC_REPOSITORIOS where id_repositorio = @IDRepositorio

END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmAVRSReportDemo
set @process = 'trsp_AdmAVRSReportDemo - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportDemo]
@id_formato int,
@version int,
@call_id int,
@tipo int
AS
BEGIN
	CREATE TABLE #tbl_ReporteConcepto(id int primary key identity(1,1),id_concepto int,concepto varchar(max));
	CREATE TABLE #tbl_ReportePregunta(id int primary key identity(1,1),id_pregunta int,pregunta varchar(max),id_concepto int,respuesta nvarchar(max),peso int,valor int);
	CREATE TABLE #tbl_Reporte(id int primary key identity(1,1),conceptopregunta varchar(max),respuesta varchar(max),puntos nvarchar(max),valorTotal nvarchar(max));

	declare @iter as int
	declare @iter1 as int
	declare @id_concepto int
	declare @respuesta varchar(max)
	declare @idForma as int
	declare @id_grabacion as int
	set @iter=1
	set @iter1=1
	

	IF EXISTS (select grab_id from ria_grabacion with (index(IX_RIA_GRABACION_1)) where cal_id=@call_id and tipo_llamada=@tipo)
		BEGIN
			
			set @id_grabacion = (select grab_id from RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id=@call_id and tipo_llamada=@tipo)

		END
	ELSE
		BEGIN

			set @id_grabacion = (select grab_id from RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id=@call_id and tipo_llamada=@tipo)
			
		END

	set @idForma=(select id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version)

	INSERT into #tbl_ReporteConcepto select id_concepto,con_descripcion from RIA_CONCEPTOS where id_formato=@id_formato and version=@version

	while @iter <=(select count(1)  from #tbl_ReporteConcepto)
	begin
		select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter
		INSERT into #tbl_ReportePregunta  SELECT  RIA_PREGUNTAS.id_pregunta, RIA_PREGUNTAS.enunciado_pregunta, RIA_PREGUNTAS.id_concepto,RIA_RESULTADOSFORMA.etiquetas, RIA_RESULTADOSFORMA.peso,RIA_PREGUNTAS.peso
						  FROM         RIA_PREGUNTAS INNER JOIN
						  RIA_RESULTADOSFORMA ON RIA_PREGUNTAS.id_pregunta = RIA_RESULTADOSFORMA.id_pregunta
						  where id_concepto=@id_concepto and RIA_RESULTADOSFORMA.id_forma=@idForma;
	set @iter = @iter+1;
	end

	while @iter1 <= (select count(1)  from #tbl_ReporteConcepto) 
	begin
		INSERT into #tbl_Reporte select concepto,'''','''','''' from #tbl_ReporteConcepto where id=@iter1
		select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter1
		INSERT into #tbl_Reporte select pregunta,respuesta,peso,valor from #tbl_ReportePregunta where id_concepto=@id_concepto
		set @iter1 = @iter1+1;
	end	

	INSERT into #tbl_Reporte
	select ''Total'','''',convert(nvarchar(max),sum(convert(int,puntos)))as peso,convert(nvarchar(max),sum(convert(int,valorTotal)))as valor From #tbl_Reporte
	
	select * from #tbl_Reporte

	
--	drop table ##tbl_Reporte
--	drop table ##tbl_ReporteConcepto
--	drop table ##tbl_ReportePregunta
END
'
	EXEC(@Sql)
--* Se altera store trsp_AdmX
set @process = 'trsp_AdmX - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmX]

@Sup_id int,
@Finicio1 datetime,
@Finicio2 datetime
AS
DECLARE    @grab_id INT,@age_id INT,@ffin datetime,@finicio datetime,@duracion INT,@id_repositorio INT,@id_nivel_grito INT,@tipo_llamada INT,@cam_id varchar(80),@calif_id INT,@ani  varchar(80),@dni varchar(80),@cal_id INT,@cal_key varchar(80),@cal_manual INT,@formato_duracion varchar(15) --cursor I
DECLARE @TablaTemporal TABLE(grab_id numeric(18,0),finicio datetime,duracion numeric(18,0),tipo_llamada numeric(18,0),cam_id varchar(80),descipcion varchar(80),user_idd numeric(18,0),loginn varchar(80),Nombres varchar(80),ApellidoPaterno varchar(80), ApellidoMaterno varchar(80),calif_id numeric(18,0),descripcionC varchar(80),cal_id numeric(18,0),id_repositorio numeric(18,0),ffin datetime,id_nivel_grito numeric(18,0),ani varchar(80),dni varchar(80),cal_key varchar(80),cal_manual numeric(18,0),Computer varchar(80),pos_id numeric(18,0),total_forma numeric(18,0),score varchar(80),formato_duracion varchar(15))
BEGIN
     SET NOCOUNT ON;
   DECLARE @vt1 varchar(80)
   DECLARE @vt2 varchar(80)
   DECLARE @vt3 varchar(80)
   DECLARE @vt4 varchar(80)
   DECLARE @vt5 varchar(80)
   DECLARE @vt6 varchar(80)
   DECLARE @vt7 varchar(80)
   DECLARE @vt8 varchar(80)
   DECLARE @vt9 int
   DECLARE @vt10 int
   DECLARE @vt22 varchar(80)
   DECLARE @tipoUs int
   DECLARE @fecha  datetime
   
   SET @grab_id=0
   SET @age_id=0
   SET @ffin='' ''
   SET @finicio='' ''
   SET @duracion='' ''
   SET @id_repositorio='' ''
   SET @tipo_llamada=0
   SET @cam_id='' ''
   SET @calif_id='' ''
   SET @cal_id='' ''
  
   SET @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

    if (@Finicio1 >= @fecha)
        BEGIN
            DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,isnull(cal_manual,0) as cal_manual,
                     CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 / 60), 2)
                      + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
                     FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3))   
                     where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
            OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            WHILE (@@FETCH_STATUS = 0 ) BEGIN
                SET @vt3 = (SELECT Login from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt4 = (SELECT Nombres from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt5 = (SELECT ApellidoPaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt6 = (SELECT ApellidoMaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt7 = (SELECT Description from trvw_tl_ccTipoCalif where calif_id=@calif_id)
                SET @vt8 = (SELECT b.computer  as pos_id from trvw_tl_RIA_GRABACION a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @tipoUs = (SELECT TipoUser_id from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from trvw_tl_RIA_GRABACION a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                --SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
                SET @vt10 = (select avg(r.total_forma) from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif where id_grabacion=@grab_id group by id_grabacion,id_formato)  t 
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion) 
			   
                IF(@tipo_llamada=1 and @tipoUs=1)
                  BEGIN          
                   SET @vt1 = (SELECT descripcion from trvw_tl_ccInbound where Inbound_id=@cam_id)
                   SET @vt22 = (SELECT Description from ccTipoCalif where calif_id=@calif_id)
                   END
                ELSE IF(@tipo_llamada=2 and @tipoUs=1)
                  BEGIN
                    SET @vt1 = (SELECT cam_descripcion from trvw_tl_ccCamps where cam_id=@cam_id)
                    SET @vt22 = (SELECT Description from ccTipoCalifOUT where calif_id=@calif_id)
                  END
               
                INSERT INTO @TablaTemporal(grab_id,finicio,duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,ffin,id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion)values(@grab_id,@finicio,@duracion,@tipo_llamada,@cam_id,@vt1,@age_id,@vt3,@vt4,@vt5,@vt6,@calif_id,@vt7,@cal_id,@id_repositorio,DATEADD(second,@duracion,@finicio),@id_nivel_grito,@ani,@dni,@cal_key,@cal_manual,@vt8,@vt9,@vt10,@vt22,@formato_duracion)
               
                SET @vt1= '' ''
                SET @vt3= '' ''
                SET @vt4= '' ''
                SET @vt5= '' ''
                SET @vt6= '' ''
                SET @vt7= '' ''
                SET @vt8= '' ''
                SET @vt9= '' ''
                SET @vt10= '' ''
                SET @vt22= '' ''
                SET @tipoUs= '' ''
                FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            END
            CLOSE ElCursorI
            DEALLOCATE ElCursorI
        END
    ELSE IF (@Finicio1 < @fecha)
        BEGIN
            DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,isnull(cal_manual,0) as cal_manual,
                     CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 / 60), 2)
                      + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
                     FROM trvw_tl_RIA_GRABACIONCONSULTA   
                     where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
            OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            WHILE (@@FETCH_STATUS = 0 ) BEGIN
                SET @vt3 = (SELECT Login from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt4 = (SELECT Nombres from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt5 = (SELECT ApellidoPaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt6 = (SELECT ApellidoMaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt7 = (SELECT Description from trvw_tl_ccTipoCalif where calif_id=@calif_id)
                SET @vt8 = (SELECT b.computer  as pos_id from trvw_tl_RIA_GRABACIONCONSULTA a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @tipoUs = (SELECT TipoUser_id from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from trvw_tl_RIA_GRABACIONCONSULTA a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                --SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
			   SET @vt10 = (select avg(r.total_forma) from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif where id_grabacion=@grab_id group by id_grabacion,id_formato)  t 
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion) 
			   
                IF(@tipo_llamada=1 and @tipoUs=1)
                  BEGIN          
                   SET @vt1 = (SELECT descripcion from trvw_tl_ccInbound where Inbound_id=@cam_id)
                   SET @vt22 = (SELECT Description from ccTipoCalif where calif_id=@calif_id)
                   END
                ELSE IF(@tipo_llamada=2 and @tipoUs=1)
                  BEGIN
                    SET @vt1 = (SELECT cam_descripcion from trvw_tl_ccCamps where cam_id=@cam_id)
                    SET @vt22 = (SELECT Description from ccTipoCalifOUT where calif_id=@calif_id)
                  END
           
                INSERT INTO @TablaTemporal(grab_id,finicio,duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,ffin,id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion)values(@grab_id,@finicio,@duracion,@tipo_llamada,@cam_id,@vt1,@age_id,@vt3,@vt4,@vt5,@vt6,@calif_id,@vt7,@cal_id,@id_repositorio,DATEADD(second,@duracion,@finicio),@id_nivel_grito,@ani,@dni,@cal_key,@cal_manual,@vt8,@vt9,@vt10,@vt22,@formato_duracion)
               
                SET @vt1= '' ''
                SET @vt3= '' ''
                SET @vt4= '' ''
                SET @vt5= '' ''
                SET @vt6= '' ''
                SET @vt7= '' ''
                SET @vt8= '' ''
                SET @vt9= '' ''
                SET @vt10= '' ''
                SET @vt22= '' ''
                SET @tipoUs= '' ''
                FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            END
            CLOSE ElCursorI
            DEALLOCATE ElCursorI
        END
  
       SELECT grab_id,CONVERT(VARCHAR(24),finicio,120) as ''finicio'',duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,CONVERT(VARCHAR(24),ffin,120) as ''ffin'',id_nivel_grito,ani,dni,cal_key,isnull(cal_manual,0) as cal_manual,Computer,pos_id,total_forma,score,formato_duracion
    FROM @TablaTemporal
    ORDER BY finicio,duracion
END'
	EXEC(@Sql)
--* Se crea stored trsp_AdmGetRecordingsBackup
set @process = 'trsp_AdmGetRecordingsBackup - Create Procedure'
set @Sql='
CREATE PROCEDURE [dbo].[trsp_AdmGetRecordingsBackup]
AS
BEGIN
	SET NOCOUNT ON;
select grab_id, isnull(status_audio,0),isnull(status_video,0), isnull(id_ruta_backup,0) from TREC_BACKUPS
END'
EXEC(@Sql)
--* Se crea stored trsp_AdmGetPathsBackup
set @process = 'trsp_AdmGetPathsBackup - Create Procedure'
set @Sql='CREATE PROCEDURE [dbo].[trsp_AdmGetPathsBackup]
AS
BEGIN
	SET NOCOUNT ON;
select id_ruta_backup,ruta from TREC_RUTAS_BACKUP
END'
EXEC(@Sql)





--* Se crea tabla RIA_NETWORKCREDENTIALS
set @process = 'RIA_NETWORKCREDENTIALS - Create Table'
set @Sql='CREATE TABLE RIA_NETWORKCREDENTIALS(
[id] [int] IDENTITY(1,1) NOT NULL,
[domain] [varchar](50) NOT NULL,
[user] [varchar](100) NOT NULL,
[password] [varchar](100) NOT NULL
)'
EXEC(@Sql)
--* Se crea store trsp_AdmGetNetworkCredential
set @process = 'trsp_AdmGetNetworkCredential - Create Procedure'
set @Sql='CREATE PROCEDURE [dbo].[trsp_AdmGetNetworkCredential]
@domain varchar(50)
AS
BEGIN
	
	SELECT [domain],[user],[password]
	FROM RIA_NETWORKCREDENTIALS
	WHERE domain like @domain

END'
EXEC(@Sql)
--* Se modifica store trsp_AdmAVRSReportDemo
set @process = 'trsp_AdmAVRSReportDemo - Alter Procedure'
set @Sql='ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportDemo]
@id_formato int,
@version int,
@call_id int,
@tipo int
AS
BEGIN
	CREATE TABLE #tbl_ReporteConcepto(id int primary key identity(1,1),id_concepto int,concepto varchar(max));
	CREATE TABLE #tbl_ReportePregunta(id int primary key identity(1,1),id_pregunta int,pregunta varchar(max),id_concepto int,respuesta nvarchar(max),peso int,valor int);
	CREATE TABLE #tbl_Reporte(id int primary key identity(1,1),conceptopregunta varchar(max),respuesta varchar(max),puntos nvarchar(max),valorTotal nvarchar(max));

	declare @iter as int
	declare @iter1 as int
	declare @id_concepto int
	declare @respuesta varchar(max)
	declare @idForma as int
	declare @id_grabacion as int
	set @iter=1
	set @iter1=1
	

	IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
		BEGIN
			
			set @id_grabacion = (select grab_id from RIA_GRABACION where cal_id=@call_id and tipo_llamada=@tipo)

		END
	ELSE
		BEGIN

			set @id_grabacion = (select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)
			
		END

	set @idForma=(select id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version)

	INSERT into #tbl_ReporteConcepto select id_concepto,con_descripcion from RIA_CONCEPTOS where id_formato=@id_formato and version=@version

	while @iter <=(select count(1)  from #tbl_ReporteConcepto)
	begin
		select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter
		INSERT into #tbl_ReportePregunta  SELECT  RIA_PREGUNTAS.id_pregunta, RIA_PREGUNTAS.enunciado_pregunta, RIA_PREGUNTAS.id_concepto,RIA_RESULTADOSFORMA.etiquetas, RIA_RESULTADOSFORMA.peso,RIA_PREGUNTAS.peso
						  FROM         RIA_PREGUNTAS INNER JOIN
						  RIA_RESULTADOSFORMA ON RIA_PREGUNTAS.id_pregunta = RIA_RESULTADOSFORMA.id_pregunta
						  where id_concepto=@id_concepto and RIA_RESULTADOSFORMA.id_forma=@idForma;
	set @iter = @iter+1;
	end

	while @iter1 <= (select count(1)  from #tbl_ReporteConcepto) 
	begin
		INSERT into #tbl_Reporte select concepto,'''','''','''' from #tbl_ReporteConcepto where id=@iter1
		select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter1
		INSERT into #tbl_Reporte select pregunta,respuesta,peso,valor from #tbl_ReportePregunta where id_concepto=@id_concepto
		set @iter1 = @iter1+1;
	end	

	INSERT into #tbl_Reporte
	select ''Total'','''',convert(nvarchar(max),sum(convert(int,puntos)))as peso,convert(nvarchar(max),sum(convert(int,valorTotal)))as valor From #tbl_Reporte
	
	select * from #tbl_Reporte

END'
EXEC(@Sql)
--* Se modifica store trsp_AdmAVRSReportCallInfo
set @process = 'trsp_AdmAVRSReportCallInfo - Alter Procedure'
set @Sql='ALTER  PROCEDURE [dbo].[trsp_AdmAVRSReportCallInfo]
@id_formato int,
@version int,
@call_id int,
@tipo int
AS
BEGIN
declare @id_grabacion as int


IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
	BEGIN
		
		set @id_grabacion = (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)

		SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
		  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACION.ani AS Telfono ,Tipo=
																				CASE WHEN (SELECT tipo_llamada 
																						    FROM RIA_GRABACION 
																					        WHERE grab_id=@id_grabacion)=1 THEN ''inbound'' 
																				ELSE ''outbound'' 
																			    END,
						      RIA_GRABACION.finicio AS Fecha,RIA_GRABACION.cal_id AS [Id de llamada],RIA_GRABACION.grab_id AS [Id de Grabacion],
							  RIA_GRABACION.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACION.duracion,''2'') AS Duracion,
							  [Campaña/GrupO ACD]=
							    CASE WHEN (SELECT tipo_llamada 
										   FROM RIA_GRABACION 
										   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																	   FROM RIA_GRABACION INNER JOIN
																	   ccInbound ON RIA_GRABACION.cam_id = ccInbound.Inbound_id
																	   WHERE (RIA_GRABACION.grab_id = @id_grabacion)) 
		     					ELSE (SELECT     ccCamps.cam_descripcion
									  FROM       RIA_GRABACION INNER JOIN
									  ccCamps ON RIA_GRABACION.cam_id = ccCamps.cam_id
									  WHERE     (RIA_GRABACION.grab_id = @id_grabacion))
								END,
							  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
					    FROM  RIA_FORMACALIF INNER JOIN
							 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
							  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
							  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
							  RIA_GRABACION ON RIA_FORMACALIF.id_grabacion = RIA_GRABACION.grab_id INNER JOIN
							  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
						WHERE RIA_FORMACALIF.id_formato=@id_formato and
							  RIA_FORMACALIF.version=@version and
							  RIA_FORMACALIF.id_grabacion=@id_grabacion and
							  RIA_FORMATOS.version=@version

	END
ELSE
	BEGIN

		set @id_grabacion =(select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)

		SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
		  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACIONCONSULTA.ani AS Telfono ,Tipo=
																				CASE WHEN (SELECT tipo_llamada 
																						    FROM RIA_GRABACIONCONSULTA 
																					        WHERE grab_id=@id_grabacion)=1 THEN ''inbound'' 
																				ELSE ''outbound'' 
																			    END,
						      RIA_GRABACIONCONSULTA.finicio AS Fecha,RIA_GRABACIONCONSULTA.cal_id AS [Id de llamada],RIA_GRABACIONCONSULTA.grab_id AS [Id de Grabacion],
							  RIA_GRABACIONCONSULTA.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACIONCONSULTA.duracion,''2'') AS Duracion,
							  [Campaña/GrupO ACD]=
							    CASE WHEN (SELECT tipo_llamada 
										   FROM RIA_GRABACIONCONSULTA 
										   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																	   FROM RIA_GRABACIONCONSULTA INNER JOIN
																	   ccInbound ON RIA_GRABACIONCONSULTA.cam_id = ccInbound.Inbound_id
																	   WHERE (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion)) 
		     					ELSE (SELECT     ccCamps.cam_descripcion
									  FROM       RIA_GRABACIONCONSULTA INNER JOIN
									  ccCamps ON RIA_GRABACIONCONSULTA.cam_id = ccCamps.cam_id
									  WHERE     (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion))
								END,
							  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
					    FROM  RIA_FORMACALIF INNER JOIN
							 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
							  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
							  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
							  RIA_GRABACIONCONSULTA ON RIA_FORMACALIF.id_grabacion = RIA_GRABACIONCONSULTA.grab_id INNER JOIN
							  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
						WHERE RIA_FORMACALIF.id_formato=@id_formato and
							  RIA_FORMACALIF.version=@version and
							  RIA_FORMACALIF.id_grabacion=@id_grabacion and
							  RIA_FORMATOS.version=@version

	END
								
END'
EXEC(@Sql)
--* Se modifica funcion ft_getTime
set @process = 'ft_getTime - Alter Function'
set @Sql='ALTER FUNCTION [dbo].[ft_getTime]
(
    @segundos INT,
    @type varchar(max)  -- Forma en la que se va a transformar
)                       -- 1: Formato String x horas x minutos x segundos
                        -- 2: Formato Number HH:MM:SS
--Llamada a la función
--DECLARE @format varchar(255)
--SET @format = (SELECT dbo.myfn_sla_get_format_HMS(8500,1))
--PRINT @format
RETURNS VARCHAR(MAX)
AS 
BEGIN
    DECLARE @temp VARCHAR(100)
    DECLARE @horas INT
    DECLARE @minutos INT
    DECLARE @tempMINUTOS INT
	DECLARE @sSegundos VARCHAR(100)
	DECLARE @sMinutos VARCHAR(100)
	DECLARE @sHoras VARCHAR(100)

 
    SET @temp =''...''
 
    IF (@segundos < 3600 AND @segundos >= 60) BEGIN
        SET @minutos =  FLOOR(@segundos / 60)
        SET @segundos = @segundos % 60
            --Según el tipo recibido lo formateo de una forma u otra
			IF @minutos > 9
				BEGIN
					set @sMinutos = CONVERT(VARCHAR, @minutos)						
				END
			ELSE
				BEGIN
					set @sMinutos = ''0'' + CONVERT(VARCHAR, @minutos)
				END 
					
			IF @segundos > 9
				BEGIN
					set  @sSegundos = CONVERT(VARCHAR, @segundos)
				END
			ELSE
				BEGIN
					set @sSegundos = ''0'' + CONVERT(VARCHAR, @segundos)
				END

            IF @type = 1
                SET @temp = ''0 Horas '' + CONVERT(VARCHAR, @minutos) + '' Minutos '' + CONVERT(VARCHAR, @segundos) + '' Segundos''
            ELSE	           
                SET @temp = ''00:'' + @sMinutos + '':'' +  @sSegundos

    END ELSE IF(@segundos < 60)
	BEGIN
		SET @minutos =  0
        SET @segundos = @segundos
            --Según el tipo recibido lo formateo de una forma u otra
			IF @segundos > 9
				BEGIN
					set  @sSegundos = CONVERT(VARCHAR, @segundos)
				END
			ELSE
				BEGIN
					set @sSegundos = ''0'' + CONVERT(VARCHAR, @segundos)
				END

            IF @type = 1
                SET @temp = ''0 Horas '' + CONVERT(VARCHAR, @minutos) + '' Minutos '' + CONVERT(VARCHAR, @segundos) + '' Segundos''
            ELSE
				SET @temp = ''00:'' + ''00'' + '':'' + @sSegundos

	END ELSE
BEGIN 
    SET @horas = FLOOR(@segundos / 3600)
    SET @tempMINUTOS = @segundos % 3600
    SET @minutos = FLOOR(@tempMINUTOS / 60) --MINUTOS FINALES
    SET @segundos = @tempMINUTOS % 60
        --Según el tipo recibido lo formateo de una forma u otra

		IF @horas > 9
			BEGIN
				set @sHoras = CONVERT(VARCHAR, @horas) 
			END
		ELSE
			BEGIN
				set @sHoras = ''0'' + CONVERT(VARCHAR, @horas) 
			END

		IF @minutos > 9
			BEGIN
				set @sMinutos = CONVERT(VARCHAR, @minutos)				
			END
		ELSE
			BEGIN
				set @sMinutos = ''0'' + CONVERT(VARCHAR, @minutos)						
			END 
					
		IF @segundos > 9
			BEGIN
				set  @sSegundos = CONVERT(VARCHAR, @segundos)
			END
		ELSE
			BEGIN
				set @sSegundos = ''0'' + CONVERT(VARCHAR, @segundos)
			END

        IF @type = 1
            SET @temp = CONVERT(VARCHAR, @horas) + '' Horas '' + CONVERT(VARCHAR, @minutos) + '' Minutos '' + CONVERT(VARCHAR, @segundos) + '' Segundos''
        ELSE            
            SET @temp = @sHoras + '':'' + @sMinutos + '':'' + @sSegundos
END 
    RETURN @temp
END'
EXEC(@Sql)
--* Se modifica store trsp_GetFilesAnalisisGritos
set @process = 'trsp_GetFilesAnalisisGritos - Alter Procedure'
set @Sql='ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
@idRepositorios as varchar(32),
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


set @FInicio = dateadd(hh, -1, getdate())
set @sSql = N''''
set @sSql3 = N''''
set @sExtension = (select par_valor from trec_parametros where par_id = 54)


select @integrado = par_valor from trec_parametros where par_id = 29

if (@integrado = 1 or @integrado = 0)

	BEGIN

		set @sSql1 = ''Select top 1000 grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
		set @sSql2 = '', isnull(tipo_llamada,0) from trec_grabacion NOLOCK where finicio < @fecInicio '' 
		set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

	END

else
	BEGIN

		set @sSql1 = ''Select top 1000 grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
		set @sSql2 = '', isnull(tipo_llamada,0) from ria_grabacion NOLOCK where finicio < @fecInicio ''
		set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

	END

if (@idRepositorios <> '''')
begin
	set @dLenAnt = len(@idRepositorios)
	set @idRepositorios = replace(@idRepositorios, ''NULL'', '''')
	if (len(@idRepositorios) = 0)   -- solo solicita NULL
		set @sSql3 = '' and id_repositorio is NULL ''
	else
	begin
		set @dLenNew = len(@idRepositorios) 
		if (@dLenNew = @dLenAnt)
			set @sSql3 = '' and id_repositorio in ('' + @idRepositorios +'')''
		else
		begin
			set @idRepositorios = right(@idRepositorios, @dLenNew-1)
			set @sSql3 = '' and (id_repositorio in ('' + @idRepositorios +'') or (id_repositorio is NULL)) ''
		end
	end
end
set @sSql = @sSql1 + @sSql2 + @sSql3 + N'' order by finicio asc''
--print (@sSql)
exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio'
EXEC(@Sql)

-- Se modifica store procedure para adquirir el lenguage de los formatos de calificacion AVRS
set @process='trsp_AdmAVRSReportLanguage - Alter Store Procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportLanguage]
@idioma as int
AS
BEGIN
	
	SET NOCOUNT ON;
	if @idioma=1
	begin
		select ''Reporte de Evaluacion de Llamadas'' as [001], 
		       ''Información de la Llamada'' as [002], 
			   ''agente'' as [003],
			   ''Supervisor'' as [004],
			   ''Teléfono'' as [005],
			   ''Tipo de Llamada'' as [006],
			   ''Fecha'' as [007],
			   ''ID de LLamada'' as [008],
			   ''ID de Grabación'' as [009],
			   ''CallKey'' as [010],
			   ''Duración'' as [011],
			   ''Campaña/ACD'' as [012],
			   ''Formato de Calificacion'' as [013],
			   ''Fecha de Revisión'' as [014],
			   ''Firma de Agente'' as [015],
			   ''Firma de Supervisor'' as [016],
			   ''Firma de Calidad'' as [017],

			   ''Detalles de Evaluación'' as [018],
			   ''Concepto/Pregunta'' as [019],
			   ''Respuesta'' as [020],
			   ''Puntos'' as [021],
			   ''Valor Total'' as [022]
	end
	else if @idioma=2
	begin
		select ''Call Evaluation Report'' as [001], 
		       ''Call Information'' as [002], 
			   ''Agent'' as [003],
			   ''Supervisor'' as [004],
			   ''Phone'' as [005],
			   ''Call Type'' as [006],
			   ''Date'' as [007],
			   ''Call ID'' as [008],
			   ''Recording ID'' as [009],
			   ''CallKey'' as [010],
			   ''Length'' as [011],
			   ''Camp./ACD '' as [012],
			   ''Score Template'' as [013],
			   ''Revision Date'' as [014],
			   ''        Agent'' as [015],
			   ''        Supervisor'' as [016],
			   ''    Quality Dept.'' as [017],

			   ''Rating Details'' as [018],
			   ''Topic/Question'' as [019],
			   ''Answer'' as [020],
			   ''Points'' as [021],
			   ''Score'' as [022]
	end
END
'
Exec(@Sql)

-- Se modifica stored procedure ReportsMasterProcessAVRS para reinicializar suscripciones en caso de error
set @process='ReportsMasterProcessAVRS - Alter Store Procedure'
set @Sql='ALTER procedure [dbo].[ReportsMasterProcessAVRS] as

declare @dateStart datetime
declare @replicationName nvarchar(100)
declare @numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int

set nocount on

set @dateStart = getdate()
set @replicationName = ''''
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 600

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag
from msdb.dbo.sysjobs
where [name] like ''%CCRecorderRIA- 0%''
and [name] like ''%CCenterRia%''
order by [name]

select @numOfReplications = count(*)
from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@repDelay)) + convert(VARCHAR(6),@repDelay),3,0,'':''),6,0,'':'')

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock)
	set flag = 1
	where [name] = @replicationName

	waitfor delay @repStrDelay
end

drop table #replications

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where mh.comments like ''%You must reinitialize the subscription (without upload)%''
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''CCRecorderRIA''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first 
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
Exec(@Sql)

-- Se actualiza la version de la base de datos
set @process ='Update DB Version'
set @Sql='
 update trec_parametros set par_valor = ''12'' where par_id = 30 
'
Exec(@Sql)

	------------------ fin SCRIPT @Sql ------------------


	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 12, 1)
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
