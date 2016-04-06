/*

Fecha: 2013/11/29
Descripcion: 
* Se agrega trec_parametros para replicas publicador
* Se crean y alteran store procedures para el nuevo BackupV2
* Se modifica el diseño de algunas tablas para el BackupV2
* Se crea el SP ReportsMasterProcessAVRS y el job para el control de replicas

Version requerida: 8

*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 9
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------


set @process='trec_parametros - insert replicas'
set @SQl='insert into TREC_PARAMETROS(par_id,par_descripcion,par_valor,par_detail) values(66,''HOSTNAME|IP CW'','''',''Parametros para guardar datos de publicador para las replicas'')
'
Exec(@Sql)

-- Modificando diseño de tablas

set @process='TREC_BACKUPS - Alter column id_ruta_backup'
set @SQl='
ALTER TABLE [TREC_BACKUPS]
ALTER COLUMN [id_ruta_backup] int NULL
'
Exec(@Sql)


-- Update en trec_parametros par_id = 29 para agregar version RIA

set @process = 'Update trec_parametros par_id = 29'
set @Sql='

UPDATE [TREC_PARAMETROS]
SET 
par_valor = ''2'',
par_detail= ''0= Sin integracion, 1=Con integracion CW 2=CW XION''   
WHERE par_id = 29
'
Exec(@Sql)


-- Creacion y alteracion de procedures para nueva version de BackupV2 en CW XION

set @process = 'trsp_UpdateBackupState - Create store procedure'
set @Sql='

CREATE PROCEDURE [dbo].[trsp_UpdateBackupState]
@Id 		VARCHAR(20),
@Lado 		CHAR(1),
@Done		BIT
AS
BEGIN
	UPDATE TREC_ARCHIVO_GRABACION SET hecho=@Done WHERE [id]=@Id AND lado=@Lado
END
'
Exec(@Sql)


set @process = 'trsp_GetCompleteBackupRange - Create store procedure'
set @Sql='

CREATE PROCEDURE [dbo].[trsp_GetCompleteBackupRange]
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
				SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACIONCONSULTA
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				if (@MinFile is NULL)
				begin
					SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION
						WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
					set @UsoHist = 0
				end
			end
			else
			begin
				SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				set @UsoHist = 0
			end

			SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACION WHERE finicio <= @EndDate
			IF (@MaxExist is NULL)
			BEGIN
				if (@UsoHist = 1)
				begin
					SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACIONCONSULTA WHERE finicio <= @EndDate
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
				SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACIONCONSULTA
					WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
					AND (tamano > 0) AND (duracion >= @MinTime)		

				IF (@CountHist is NULL)
				BEGIN
					SELECT @CountHist = 0
				END
			end
			SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACION
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
				SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACIONCONSULTA
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				if (@MinFile is NULL)
				begin
					SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION
						WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
					set @UsoHist = 0
				end
			end
			else
			begin
				SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				set @UsoHist = 0
			end

			SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACION WHERE finicio <= @EndDate
			IF (@MaxExist is NULL)
			BEGIN
				if (@UsoHist = 1)
				begin
					SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACIONCONSULTA WHERE finicio <= @EndDate
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
				SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACIONCONSULTA
					WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
					AND (tamano > 0) AND (duracion >= @MinTime)		

				IF (@CountHist is NULL)
				BEGIN
					SELECT @CountHist = 0
				END
			end
			SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACION
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
Exec(@Sql)


set @process = 'trsp_GetDaysToValidateLicensed - Create procedure'
set @Sql='

CREATE PROCEDURE [dbo].[trsp_GetDaysToValidateLicensed]
AS
BEGIN
	DECLARE @isIntegrated AS INT

	-- 0 AVRS STANDALONE
	-- 1 AVRS CW INTEGRATED
	-- 2 AVRS RIA CW INTEGRATED
	SET @isIntegrated = (SELECT par_valor FROM TREC_PARAMETROS 
						WHERE par_id = 29)
	

	IF @isIntegrated = 2
		BEGIN
			SELECT datediff(dd, (select isnull(max(finicio), getdate()-1) FROM RIA_GRABACION), getdate()) as dias
		END
	ELSE
		BEGIN
			SELECT datediff(dd, (select isnull(max(finicio), getdate()-1) FROM TREC_GRABACION), getdate()) as dias			
		END
END

'
Exec (@Sql)


set @process = 'trsp_GetFilesForBackup - Alter procedure'
set @Sql= '
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
					SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
					union
					SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACIONConsulta WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
				else
				begin
					SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM RIA_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
					union
					SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM RIA_GRABACIONConsulta WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
			end
			else
			begin
				if @ExistRepositorio = 1
				begin
					SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
				else
				begin
					SELECT grab_id, tipo_llamada, cal_id, 0,0  FROM RIA_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
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
					SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
					union
					SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACIONConsulta WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
				else
				begin
					SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM TREC_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
					union
					SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM TREC_GRABACIONConsulta WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
			end
			else
			begin
				if @ExistRepositorio = 1
				begin
					SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
				else
				begin
					SELECT grab_id, tipo_llamada, cal_id, 0,0  FROM TREC_GRABACION WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
				end
			end

		END

END  
'
Exec(@Sql)

set @process='trsp_GetFirstBackupFile - Alter procedure'
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
				SELECT @MinHistorico = MIN(grab_id) FROM RIA_GRABACIONConsulta 
					WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
				if (@MinHistorico is NULL)
				begin	
					SELECT  @FirstBackupFile=grab_id, @Date=finicio 
						FROM RIA_GRABACION 
						WHERE grab_id =(SELECT MIN(grab_id) 
							FROM RIA_GRABACION 
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
						FROM RIA_GRABACION 
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
				SELECT @MinHistorico = MIN(grab_id) FROM TREC_GRABACIONConsulta 
					WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
				if (@MinHistorico is NULL)
				begin	
					SELECT  @FirstBackupFile=grab_id, @Date=finicio 
						FROM TREC_GRABACION 
						WHERE grab_id =(SELECT MIN(grab_id) 
							FROM TREC_GRABACION 
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
						FROM TREC_GRABACION 
						WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
			end

			SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
		END 

END  
'
Exec(@Sql)


set @process ='trsp_GetLabelForBackUp - Create procedure'
set @Sql= '

CREATE PROCEDURE [dbo].[trsp_GetLabelForBackUp]
@LabelDate DATETIME,
@Grupos INTEGER
AS

DECLARE @LabelMain AS VARCHAR(20)
DECLARE @Label AS VARCHAR(20)
DECLARE @Label3 AS VARCHAR(20)
DECLARE @iLabel AS VARCHAR(20)
DECLARE @Label2 AS VARCHAR(20)
declare @Integrado as int

select @integrado =count(*) from trec_parametros where par_id = 29
if @integrado > 0
	select @integrado = par_valor from trec_parametros where par_id = 29

IF @Grupos > 1
BEGIN
	SELECT @iLabel=1	
LabelLoop:
	SELECT @Label=CONVERT(VARCHAR,YEAR(@LabelDate))+''_''+CONVERT(VARCHAR,MONTH(@LabelDate))+''_''+CONVERT(VARCHAR,DAY(@LabelDate))+''_''+CONVERT(VARCHAR,@ilabel)
	if (@integrado = 1) or (@integrado = 2)
		SELECT @Label3 = ''N''+@Label +''_A''
	else
		SELECT @Label3 = @Label +''_A''
	SELECT @Label2=[id] FROM TREC_ARCHIVO_GRABACION WHERE [id]=@Label3
	--SELECT @Label2, @Label3, @Label
	IF (@Label2 = @Label3)
	BEGIN
		SELECT @iLabel=@iLabel+1
		GOTO LabelLoop
	END
	SELECT @Label=CONVERT(VARCHAR,YEAR(@LabelDate))+''_''+CONVERT(VARCHAR,MONTH(@LabelDate))+''_''+CONVERT(VARCHAR,DAY(@LabelDate))+''_''+CONVERT(VARCHAR,@ilabel)
	SELECT @Label2=[id] FROM TREC_ARCHIVO_GRABACION WHERE [id]=@Label3
	if (@integrado = 1) or (@integrado = 2)
		SELECT @Label3 = ''N''+@Label +''_B''
	else
		SELECT @Label3 = @Label +''_B''
	IF (@Label2 = @Label3)
	BEGIN
		SELECT @iLabel=@iLabel+1
		GOTO LabelLoop
	END
END
ELSE
BEGIN
	SELECT @iLabel=1	
LabelLoopOne:
	SELECT @Label=CONVERT(VARCHAR,YEAR(@LabelDate))+''_''+CONVERT(VARCHAR,MONTH(@LabelDate))+''_''+CONVERT(VARCHAR,DAY(@LabelDate))+''_''+CONVERT(VARCHAR,@ilabel)
	if (@integrado = 1) or (@integrado = 2)
		SELECT @Label3 = ''N''+@Label
	else
		SELECT @Label3 = @Label
	SELECT @Label2=[id] FROM TREC_ARCHIVO_GRABACION WHERE [id]=@Label3
	IF (@Label2=@Label3)
	BEGIN
		SELECT @iLabel=@iLabel+1
		GOTO LabelLoopOne
	END
END

if (@integrado = 1) or (@integrado = 2)
	SELECT ''Label''=''N''+@Label
else
	SELECT ''Label''= @Label
'
Exec(@Sql)


set @process='trsp_GetListaBorrarRespaldo - Alter procedure'
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
	    select top 10000 grab_id, status_audio from trec_backups where status_audio = 1 order by grab_id asc
	END
END
'
Exec(@Sql)


set @process='trsp_GetListaBorrarSinRespaldo - Alter procedure'
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
	SELECT @maxBorrado = MAX(grab_id) from trec_backups where status_audio = 4 or status_audio = 5;
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
		select top 10000 grab_id, status_audio, status_video from trec_backups where status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
END
'
Exec(@Sql)

set @process='ReportsMasterProcessAVRS - Create Procedure'
set @Sql='CREATE procedure [dbo].[ReportsMasterProcessAVRS] as

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

drop table #replications'

Exec(@Sql)

set @process='ReportsMasterProcessAVRS - Create Job'
set @Sql='USE [msdb]

/****** Object:  Job [ReportsMasterProcessAVRS]    Script Date: 12/09/2013 17:15:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 12/09/2013 17:15:27 ******/
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
/****** Object:  Step [Generate Reports]    Script Date: 12/09/2013 17:15:28 ******/
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
		@database_name=N''CCRecorderRia'', 
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

Exec(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 update trec_parametros set par_valor = '9' where par_id = 30 

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