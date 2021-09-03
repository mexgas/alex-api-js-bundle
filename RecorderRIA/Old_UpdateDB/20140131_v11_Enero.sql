/*

Fecha: 2014/01/31
Descripcion: 

* Se crea tabla en CCRecorderRIA para BackupV2Net v.5.2
* Se alteran store procedures para nuevo backupV2 version 5.2
* Se altera store de analizagritos
* Se agrega sp para saber si XION tiene video
* Se agrega sp para saber si el engine esta encriptando las grabaciones
* Se altera sp para obtener los repositorios
* Se altera sp patra obtener los archivos de detector de gritos
* Se crea sp para bamiar lenguaje del pdf generado para calificaciones

Version requerida: 10

*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 11
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------

-- Se crea tabla para backupv2NET v5.2

set @process='TREC_ARCHIVO_GRABACION - Create table in CCRecorderRIA'
set @Sql='
CREATE TABLE [dbo].[TREC_ARCHIVO_GRABACION](
	[id] [varchar](20) NOT NULL,
	[lado] [char](1) NOT NULL,
	[grab_id_max] [bigint] NOT NULL,
	[hecho] [bit] NOT NULL CONSTRAINT [DF_TREC_ARCHIVO_GRABACION_done]  DEFAULT ((0)),
	[cli_id] [int] NOT NULL CONSTRAINT [DF_TREC_ARCHIVO_GRABACION_cli_id]  DEFAULT ((0)),
	[grab_id_active] [int] NULL,
 CONSTRAINT [PK_TREC_ARCHIVO] PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[lado] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
'
Exec(@Sql)


-- Se modifican sp para BackupV2NET v5.2

set @process='trspAdmRecordingsOfDay - Alter Store Procedure'
set @Sql='

ALTER PROCEDURE  [dbo].[trspAdmRecordingsOfDay]
@idAgent as INT
AS
set nocount on
DECLARE @CallType as INT

BEGIN
	(SELECT     a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN a.ani ELSE a.ani END AS Expr1, 
                      b.cam_descripcion AS Expr2, 
                      CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE WHEN a.tipo_llamada = 2 THEN d .description ELSE e.description END AS Expr4, 
                     isnull(a.id_nivel_grito,-1),@idAgent as age_id, isnull (i.total_forma,0) as rating,j.Computer, k.Nombres AS Agente,a.cam_id
	FROM         RIA_GRABACION AS a INNER JOIN
                      ccCamps AS b ON a.cam_id = b.cam_id LEFT OUTER JOIN
                      ccTipoCalifOUT AS d ON a.calif_id = d.calif_id LEFT OUTER JOIN
                      ccTipoCalif AS e ON a.calif_id = e.calif_id LEFT OUTER JOIN
                      RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito LEFT OUTER JOIN
					  RIA_FORMACALIF AS i on i.id_grabacion = a.grab_id left join 
					  ccPosicion j on j.pos_id = a.cal_extension * -1 left join 
					  ccUsers k on k.User_id = @idAgent
WHERE     (a.age_id = @idAgent) AND (a.tipo_llamada=2) AND(DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))

UNION ALL

	(SELECT     a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN a.ani ELSE a.ani END AS Expr1, 
                      c.descripcion AS Expr2, 
                      CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE WHEN a.tipo_llamada = 2 THEN d .description ELSE e.description END AS Expr4, 
                      isnull(a.id_nivel_grito,-1),@idAgent as age_id, isnull (i.total_forma,0) as rating, j.Computer, k.Nombres AS Agente,a.cam_id
	FROM         RIA_GRABACION AS a INNER JOIN
                      ccInbound AS c ON a.cam_id = c.Inbound_id LEFT OUTER JOIN
                      ccTipoCalifOUT AS d ON a.calif_id = d.calif_id LEFT OUTER JOIN
                      ccTipoCalif AS e ON a.calif_id = e.calif_id LEFT OUTER JOIN
                      RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito LEFT OUTER JOIN
					  RIA_FORMACALIF AS i on i.id_grabacion = a.grab_id left join 
					  ccPosicion j on j.pos_id = a.cal_extension * -1 left join 
					  ccUsers k on k.User_id = @idAgent
WHERE     (a.age_id = @idAgent) AND (a.tipo_llamada=1) AND (DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))
END
'
Exec(@Sql)


set @process='trsp_AVRSBackup - Alter Store Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AVRSBackup]

@option INT,
@grab_id INT,
@id_ruta_backup INT,
@status INT,
@ruta VARCHAR(50)

AS
BEGIN

    SET NOCOUNT ON;
    IF @option=1
        BEGIN
          SELECT MAX(id_ruta_backup) AS id_ruta_backup FROM TREC_RUTAS_BACKUP
    END
    IF @option=2
        BEGIN
            INSERT INTO TREC_RUTAS_BACKUP(ruta)VALUES(@ruta)
    END
   IF @option=3
        BEGIN
          SELECT grab_id FROM TREC_BACKUPS WHERE grab_id = @grab_id
    END
    IF @option=4
    BEGIN
            UPDATE TREC_BACKUPS SET status_audio=@status, id_ruta_backup=@id_ruta_backup WHERE grab_id=@grab_id
    END
    IF @option=5
        BEGIN
        IF @status = 3
        begin
            INSERT INTO TREC_BACKUPS (grab_id,status_audio,status_video,id_ruta_backup)VALUES(@grab_id,@status,3,@id_ruta_backup)
        end
        ELSE
        begin
            INSERT INTO TREC_BACKUPS (grab_id,status_audio,status_video,id_ruta_backup)VALUES(@grab_id,@status,0,@id_ruta_backup)
        end
    END
   IF @option=6
        BEGIN
        select * from TREC_LISTA_MAIL where nivel_id=1 or nivel_id=3
    END
   IF @option=7
        BEGIN
        select * from TREC_PARAMETROS where par_id=24
    END
    IF @option=8
        BEGIN
        select * from TREC_PARAMMAIL where MailType=4
    END

    IF @option=9
        BEGIN
         SELECT grab_id FROM TREC_BACKUPS WHERE grab_id = @grab_id
    END
    IF @option=10
        BEGIN
        UPDATE TREC_BACKUPS SET status_video=@status, id_ruta_backup=@id_ruta_backup WHERE grab_id=@grab_id
    END
   IF @option=11
        BEGIN
        INSERT INTO TREC_BACKUPS (grab_id,status_audio,status_video,id_ruta_backup)VALUES(@grab_id,0,@status,@id_ruta_backup)
    END
END
'
Exec(@Sql)


set @process='trsp_GetCompleteBackupRange - Alter Store Procedure'
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
Exec (@Sql)



set @process='trsp_GetFilesForBackup - Alter Store Procedure'
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
Exec (@Sql)



set @process='trsp_GetFirstBackupFile - Alter Store Procedure'
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
Exec (@Sql)




set @process='trsp_GetLabelForBackUp - Alter Store Procedure'
set @Sql='



ALTER PROCEDURE [dbo].[trsp_GetLabelForBackUp]
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

Exec (@Sql)


set @process='trsp_GetListaBorrarRespaldo - Alter Store Procedure'
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
Exec (@Sql)


set @process='trsp_GetListaBorrarSinRespaldo - Alter Store Procedure'
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



set @process='trsp_UpdateBackupState - Alter Store Procedure'
set @Sql=' 
ALTER PROCEDURE [dbo].[trsp_UpdateBackupState]
@Id 		VARCHAR(20),
@Lado 		CHAR(1),
@Done		BIT
AS
BEGIN
	UPDATE TREC_ARCHIVO_GRABACION SET hecho=@Done WHERE [id]=@Id AND lado=@Lado
END
'
Exec(@Sql)


-- Fix a sp trsp_AdmRecSearchNodeACD


set @process='trsp_AdmRecSearchNodeACD - Alter Store Procedure'
set @Sql='
ALTER PROCEDURE  [dbo].[trsp_AdmRecSearchNodeACD]
	-- Add the parameters for the stored procedure here


@Workgroup int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select a.idCampEsp, b.descripcion, d.frame from ccRIACampEspWG a
inner join ccInbound b on b.Inbound_id = a.idCampEsp
inner join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
inner join ccRIAGraphics d on d.graphic_id = c.graphic_id
where a.IDWG = @Workgroup and a.Tipo = 0

END
'
Exec(@Sql)



-- Se altera procedure trsp_GetFilesAnalisisGritos

set @process='trsp_GetFilesAnalisisGritos - Alter Store Procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
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
declare @Enc as nvarchar(5)


set @FInicio = dateadd(hh, 0, getdate())
set @sSql = N''''
set @sSql3 = N''''
set @sExtension = (select par_valor from trec_parametros where par_id = 54)
set @Enc = 	(SELECT par_valor from TREC_PARAMETROS WHERE par_id = 15)

if @Enc = ''1'' begin
set @sExtension = @sExtension + ''.enc''
end

select @integrado =count(*) from trec_parametros where par_id = 29
if (@integrado > 0)
	select @integrado = par_valor from trec_parametros where par_id = 29
set @sSql2 = '', isnull(tipo_llamada,0) from ria_grabacion NOLOCK where finicio < @fecInicio '' 
set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''
if (@integrado = 1 or @integrado = 2)
	set @sSql1 = ''Select top 1000 grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
	--set @sSql1 = ''Select top 1000 grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+''.VOX''+char(0x27)
else
	set @sSql1 = ''Select top 1000 grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
	--set @sSql1 = ''Select top 1000 grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+''.VOX''+char(0x27)
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
exec sp_executeSql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio
'
Exec(@Sql)


-- Se altera sp trsp_AdmGetAllRepositories

set @process='trsp_AdmGetAllRepositories - Alter Store Procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
	-- Add the parameters for the stored procedure here
@Mode int
-- Mode 1 para busqueda de grabaciones
-- Mode 2 para configuracion de repositorios

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF @Mode = 1
Begin

select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio  from TREC_REPOSITORIOS order by id_repositorio
	End
Else IF @Mode =2
	Begin
	
select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes  from TREC_REPOSITORIOS order by id_repositorio

End


END
'
Exec(@Sql)



-- Se modifica sp de trsp_AVRSGetExportRecRepository

set @process='trsp_AVRSGetExportRecRepository - Alter Store Procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AVRSGetExportRecRepository]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT par_valor from CCRecorderRIA.dbo.TREC_PARAMETROS where par_id = 65

END

'
Exec(@Sql)


-- Nuevo Script para BackupV2NET v5.2

set @process='trsp_SaveBackup - Create Store Procedure'
set @Sql='
CREATE PROCEDURE [dbo].[trsp_SaveBackup]
@Id 		VARCHAR(20),
@Lado 		CHAR(1),
@MaxGrab	INT,
@Done		BIT
AS
BEGIN
	INSERT INTO TREC_ARCHIVO_GRABACION(id,lado,grab_id_max,hecho) VALUES (@Id, @Lado, @MaxGrab, @Done)
END
'
Exec(@Sql)


set @process='trsp_AdmUpdateRecordingCoaaching - Create Store Procedure'
set @Sql='
CREATE PROCEDURE trsp_AdmUpdateRecordingCoaaching
@coaching_Id int,
@call_Id int,
@call_Type int
AS
BEGIN
	
	IF EXISTS( SELECT 1 FROM RIA_GRABACION WHERE cal_id = @call_Id AND tipo_llamada = @call_Type )

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
Exec(@Sql)


-- Nuevo Script que utiliza el Admin para saber si tiene video integrado a XION

set @process='trsp_AdmGetVideoStatus - Create Store Procedure'
set @Sql='

CREATE PROCEDURE trsp_AdmGetVideoStatus

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @Sql varchar(MAX),
		@value varchar(2) 
				
set @Sql = (select par_valor from trec_parametros where par_id = 60)
 
 if @Sql = ''FLV'' OR @Sql = ''flv'' OR @Sql = ''Flv'' begin
	set @value = ''1''
 end
 else
 begin
	set @value = ''0''
 end

select @value

END
'
Exec(@Sql)


-- Nuevo Store Procedure para obtener el valor si esta encriptando o no el Engine

set @process='trsp_GetEncryptValue - Create Store Procedure'
set @Sql='
CREATE PROCEDURE trsp_GetEncryptValue
AS 
BEGIN
	
	SELECT par_valor from TREC_PARAMETROS
	WHERE par_id = 15

END
'
Exec(@Sql)


-- Se crea store procedure para adquirir el lenguage de los formatos de calificacion AVRS


set @process='trsp_AdmAVRSReportLanguage - Create Store Procedure'
set @Sql='

CREATE PROCEDURE [dbo].[trsp_AdmAVRSReportLanguage]
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
	else if @idioma=4
   --if @idioma=4
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

			   ''Score Details'' as [018],
			   ''Template Topic'' as [019],
			   ''Answer'' as [020],
			   ''Points'' as [021],
			   ''Score'' as [022]
	end
END
'
Exec(@Sql)


-- Se actualiza sp para reportes de calificaciones AVRS trsp_AdmAVRSReportCallInfo

set @process ='trsp_AdmAVRSReportCallInfo - Alter Store Procedure'
set @Sql ='

ALTER  PROCEDURE [dbo].[trsp_AdmAVRSReportCallInfo]
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
								
END

'
Exec(@Sql)


-- Se altera sp para reportes de calificacion AVRS trsp_AdmAVRSReportDemo

set @process= 'trsp_AdmAVRSReportDemo - Alter Store Procedure'
set @Sql ='

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

	
--	drop table ##tbl_Reporte
--	drop table ##tbl_ReporteConcepto
--	drop table ##tbl_ReportePregunta
END
'
Exec(@Sql)


-- Se altera funcion para reportes de calificacion AVRS

set @process='ft_getTime - Alter Function'
set @Sql='
ALTER FUNCTION [dbo].[ft_getTime]
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
END
'
Exec(@Sql)



-- Se actualiza la version de la base de datos

set @process ='Update DB Version'
set @Sql='
 update trec_parametros set par_valor = ''11'' where par_id = 30 
'
Exec(@Sql)

	------------------ fin SCRIPT @Sql ------------------


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