/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 
		
Date: 2019/01/08
Description:

Database: CCenterRia
Required version: 121.31

Se agrega la tarea
CW-2031
CW-2576
CW-2487

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 32

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 31
BEGIN
	BEGIN TRAN

	BEGIN TRY				

		SET @process = 'CW-2686 ALTER SP ccsp_DLRSaveDialResult'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT, @tDialing TINYINT = 0, @tBusy SMALLINT = 0, @call_id INT = 0, @answerbit BIT = NULL, @tAnswerBit SMALLINT = 0, @canceledNoAgents BIT = 0, @disconnectCause VARCHAR(250) = '''', @cal_key VARCHAR(20) = '''', @call_TS VARCHAR(15) = ''''
AS
SET NOCOUNT ON

DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT
DECLARE @logDial_id INT
DECLARE @tAnswerBitFinal AS DATETIME

SELECT @RecicleSIC = IsNull(valor, 0)
FROM ccSettings
WHERE setting_id = 60

SELECT @tNow = getdate()

SELECT @tAnswerBitFinal = dateadd(ss, - @tAnswerBit, @tNow)

IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id)
	SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(@Telefono)
END
ELSE
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS)
	SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS
END

SELECT @logDial_id = scope_identity()

IF (@RecicleSIC = 1)
BEGIN
	UPDATE ccoWorkingTable
	WITH (ROWLOCK)

	SET tipoResDial_id = @tipoResDial_id
	WHERE callout_id = @callout_id
END

SELECT @logDial_id

-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
	UPDATE ccoCallsOut
	WITH (ROWLOCK)

	SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
	WHERE cal_id = @call_id AND cal_puerto = 0

	EXEC ccsp_CstoCalculaCosto @call_id

	IF @cal_key = ''''
	BEGIN
		SELECT @cal_key = cal_key
		FROM ccoCallsOutSource WITH (NOLOCK)
		WHERE @callout_id = callout_id

		UPDATE ccologdials
		WITH (ROWLOCK)

		SET cal_key = @cal_key
		WHERE logDial_id = @logDial_id
	END
END

-- inserta informacion para reportes de workgroup
INSERT ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, TIMESTAMP)
SELECT IDWG, @logDial_id, IdCampEsp, getdate()
FROM ccRIACampEspWG
WHERE tipo = 1 AND IdCampEsp = @cam_id

-- Guarda configuracion de TipoDialingMode
UPDATE ccoLogDials
WITH (ROWLOCK)

SET TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id)
WHERE logDial_id = @logDial_id
SET NOCOUNT OFF
'

		EXEC (@Sql)

		SET @process = 'CW-2686 Alter SP ccsp_RIAOUTInsertNewJOBS_WT_Camp'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1
AS
SET NOCOUNT ON

CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(20), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

DELETE ccUploadTemporal
WITH (ROWLOCK)
WHERE cam_id = @camp_id

CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

INSERT INTO #calloutIdSource
SELECT cs.callout_id
FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK), ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK)
WHERE cs.cal_key = wt.cal_keyw AND cs.cam_id = wt.cam_id AND cs.cam_id = @camp_id AND cs.cal_status IN (0, 7) AND wt.cal_status <= 2

UNION

SELECT Cout.callout_id
FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK), ccoworkingtable Wtab(NOLOCK)
WHERE Cout.callout_id = Wtab.callout_id AND Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)

INSERT INTO #calloutIdSource2
SELECT callout_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

IF (
		SELECT count(*)
		FROM #calloutIdSource
		) > 0
BEGIN
	UPDATE ccoCallBacks
	WITH (ROWLOCK)

	SET [status] = 6, schedulerStatus = 1
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis WITH (NOLOCK)
			)

	UPDATE ccoCallsOutSource
	WITH (ROWLOCK)

	SET cal_Status = 4
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis WITH (NOLOCK)
			)
END

INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT callout_id, cam_id, rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) AS cal_telefono, CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria, CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2, CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3, CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
			NULL END iZonaHoraria_verano5, list_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

SELECT @rowstoInsert = COUNT(*)
FROM #tempCallsOutSource

IF (
		SELECT COUNT(*)
		FROM #tempCallsOutSource WITH (NOLOCK)
		) > 0
BEGIN
	SELECT @rango = isnull(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
	FROM #tempCallsOutSource WITH (NOLOCK)

	SET @batchsizeFin = @batchsizeFin + @rango

	WHILE 1 = 1
	BEGIN
		-- Nuevos Jobs
		INSERT INTO ccoWorkingTable
		WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
		SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
		FROM #tempCallsOutSource
		WHERE id > @batchsizeIni AND id <= @batchsizeFin

		IF @batchsizeFin > @rowstoInsert
			BREAK
		ELSE
		BEGIN
			SET @batchsizeIni = @batchsizeIni + @rango
			SET @batchsizeFin = @batchsizeFin + @rango
		END
	END

	UPDATE ccoCallsOutSource
	SET cal_status = 2, dial_tels = @prioridad, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
	FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
	WHERE co.callout_id = cis3.callout_id
END

DROP TABLE #calloutIdSource

DROP TABLE #calloutIdSource2

DROP TABLE #tempCallsOutSource

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF
'

		EXEC (@Sql)

		SET @process = 'CW-2644 '
		SET @Sql = 'if not exists(select * from ccRIALog_Module where module_id=56)
						insert ccRIALog_Module values (56, ''FINDER|FINDER'')
					if not exists(select * from ccRIALog_Module where module_id=57)
						insert ccRIALog_Module values (57, ''RECORDING MANAGER|RECORDING MANAGER'')
					if not exists(select * from ccRIALog_Module where module_id=58)
						insert ccRIALog_Module values (58, ''DOWNLOAD MANAGER|DOWNLOAD MANAGER'')
					if not exists(select * from ccRIALog_Module where module_id=59)
						insert ccRIALog_Module values (59, ''RECORDER SERVER|RECORDER SERVER'')
					if not exists(select * from ccRIALog_Operation where operationType=170)
						insert ccRIALog_Operation values (170, ''BUSQUEDA|SEARCH'')
					if not exists(select * from ccRIALog_Operation where operationType=171)
						insert ccRIALog_Operation values (171, ''DESCARGA|DOWNLOAD'')
					if not exists(select * from ccRIALog_Operation where operationType=172)
						insert ccRIALog_Operation values (172, ''ENVIAR EMAIL|SEND EMAIL'')
					if not exists(select * from ccRIALog_Operation where operationType=173)
						insert ccRIALog_Operation values (173, ''EXPORTAR DESDE EXCEL|EXPORT FROM EXCEL'')
					if not exists(select * from ccRIALog_Operation where operationType=174)
						insert ccRIALog_Operation values (174, ''EXPORTAR|EXPORT'')
					if not exists(select * from ccRIALog_Operation where operationType=175)
						insert ccRIALog_Operation values (175, ''BACKUP|BACKUP'')
					if not exists(select * from ccRIALog_Operation where operationType=176)
						insert ccRIALog_Operation values (176, ''REPRODUCCION|PLAY'')'

		EXEC (@Sql)

		SET @process = 'CW-2644 ALTER SP ccsp_RIA_ABCLog'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCLog] @optiON TINYINT, @areaName VARCHAR(50) = NULL, @operationType TINYINT = NULL, @login VARCHAR(20) = NULL, @moduleId INT = NULL, @value VARCHAR(250) = NULL, @target VARCHAR(250) = NULL, @operationDateIni SMALLDATETIME = NULL, @operationDateFin SMALLDATETIME = NULL, @top INT = 0
					AS
					SET NOCOUNT ON

					IF @option = 1 -- muestra todo
					BEGIN
						SELECT log_id, areaName, operationDate, operationType, LOGIN, module_id, value, target
						FROM ccRIALog WITH (NOLOCK)

						RETURN (0)
					END

					IF @option = 2 -- insert
					BEGIN
						DECLARE @areaNameValue AS VARCHAR(50)
						DECLARE @loginNameValue AS VARCHAR(50)

						SET @areaNameValue = isnull(@areaName,'''')

						IF (left(@areaName, 1) = ''!'')
						BEGIN
							SELECT @areaNameValue = areaName
							FROM dbo.ccRIACat_Areas AS AREAS WITH (NOLOCK)
							WHERE AREAS.IDArea = right(@areaName, len(@areaName) - 1)
						END

						SET @loginNameValue = @login

						IF (left(@login, 1) = ''!'')
						BEGIN
							SELECT @loginNameValue = Login, 
							@areaNameValue = case datalength(@areaNameValue) when 0 then isnull(AreaName,'''') else @areaNameValue end
							FROM ccUsers us (nolock) left join ccRIACat_Areas area (nolock) on area.IDArea=us.IDArea
							WHERE User_id = right(@login, len(@login) - 1)
						END

						INSERT INTO ccRIALog
						VALUES (@areaNameValue, GETDATE(), @operationType, @loginNameValue, @moduleId, @value, @target)

						RETURN (0)
					END

					DECLARE @lang TINYINT

					SELECT @lang = valor
					FROM ccsettings
					WHERE setting_id = 27

					IF @option = 3 -- muestra información por filtros (System>Log) // Fechas
					BEGIN
						SET ROWCOUNT @top

						SELECT L.log_id, L.areaName, L.operationDate, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END operationType, L.LOGIN, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END module_id, CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE @lang WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target, CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE @lang WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
						FROM CCRIALOG L
						JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
						JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
						LEFT JOIN targetRecord t ON t.targetT = L.target
						LEFT JOIN valueRecord v ON v.valueT = L.value
						WHERE L.operationType = CASE isnull(@operationType, 0) WHEN 0 THEN L.operationType ELSE @operationType END AND L.LOGIN = CASE isnull(@login, '''') WHEN '''' THEN L.LOGIN ELSE @login END AND L.module_id = CASE isnull(@moduleId, 0) WHEN 0 THEN L.module_id ELSE @moduleId END AND L.target = CASE isnull(@target, '''') WHEN '''' THEN L.target ELSE @target END AND L.operationDate >= CASE WHEN isnull(@operationDateIni, '' 19000101 '') <> '' 19000101 '' AND isnull(@operationDateFin, '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, - 1, @operationDateIni) ELSE L.operationDate END AND L.operationDate <= CASE WHEN isnull(@operationDateIni, '' 19000101 '') <> '' 19000101 '' AND isnull(@operationDateFin, '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, 1, @operationDateFin) ELSE L.operationDate END
						ORDER BY L.operationDate DESC

						RETURN (0)
					END

					IF @option = 4 -- Catalogo de modulos
					BEGIN
						SELECT m.module_id, o.operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
						FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
						JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
						JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id
						
						UNION
						
						SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
						
						UNION
						
						SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
						
						UNION
						
						SELECT module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
						FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
						
						UNION
						
						SELECT module_id, - 1, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
						FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
						ORDER BY mDescripcion, oDescripcion

						RETURN (0)
					END

					IF @option = 5 -- Catalogo de operaciones
					BEGIN
						SELECT operationType, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion
						FROM ccRIALog_Operation WITH (INDEX (IX_ccRIALog_Operation))
						
						UNION
						
						SELECT 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
						ORDER BY 2

						RETURN (0)
					END

					SET NOCOUNT OFF
					'

		EXEC (@Sql)
		
		SET @process = 'CW-2487 Nuevo Setting 210'
		SET @Sql = 'if not exists(select * from ccsettings where setting_id=210)
			insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
			values (210,0,''Destinatarios de grabaciones para envío de email'',1,''ADM'',''0:Desactivado,1:Habilitar'',''Recordings Recipients. 0:Disabled,1:Enabled'',1,''^[0-1]$'')
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 Nuevo Menu 87'
		SET @Sql = 'if not exists(select * from ccmenus where menu_id=87)
			insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values (87,''Destinatarios de grabaciones|Recordings Recipients'',32,''B'',44,1,'''',''44c2462182a6c38fecaa6b187b70a43c7d14558a702cb4dd4f72d6da823ad6b90358675515652ad58ef44666b5e92f027723a4daf0af5d53fd9ae5c44ab070dc'')
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 Tabla ccRIACat_AddressBook'
		SET @Sql = 'if not exists (SELECT * 
							 FROM INFORMATION_SCHEMA.TABLES 
							 WHERE TABLE_SCHEMA = ''dbo'' 
							 AND  TABLE_NAME = ''ccRIACat_AddressBook'')
			BEGIN

				CREATE TABLE [dbo].[ccRIACat_AddressBook](
					[addr_Id] [smallint] IDENTITY(1,1) NOT NULL,
					[email] [varchar](100) NOT NULL,
					[name] [varchar](100) NOT NULL,
					[organization] [varchar](100) NOT NULL,
					[department] [varchar](50) NOT NULL,
					[job_title] [varchar](50) NOT NULL,
					[area_Id] [smallint] NULL,
				 CONSTRAINT [PK_ccRIACat_AddressBook] PRIMARY KEY CLUSTERED 
				(
					[addr_Id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]

			END
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 DROP Procedure ccsp_RIA_AddressBook'
		SET @Sql = 'IF EXISTS ( SELECT * 
					FROM   sysobjects 
					WHERE  id = object_id(N''[dbo].[ccsp_RIA_AddressBook]'') 
						   and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
		BEGIN
			DROP PROCEDURE [dbo].[ccsp_RIA_AddressBook]
		END
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 Procedure ccsp_RIA_AddressBook'
		SET @Sql = 'CREATE PROCEDURE [dbo].[ccsp_RIA_AddressBook]
			@action smallint,
			@Email varchar(100) = '''',
			@Name varchar(100) = '''',
			@Organization varchar(100) = '''',
			@Department varchar(100) = '''',
			@Title varchar(100) = '''',
			@IDArea smallint = NULL,
			@IDAddr smallint = NULL
			AS

			set nocount on

			if @action = 0 begin --Selected Address
				select addr_id,name,email,organization,department,job_title from ccRIACat_AddressBook nolock where area_id=@IDArea order by Name
				return(0)
			end
			else if @action=2 begin --Insert Address
				Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
				select 1, scope_identity()--, Address Insertada
				return(0)
			end
			else if @action=3 begin--Update Address
				update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
				return(0)
			end
			else if @action=4 begin --Delete Address
				delete ccRIACat_AddressBook where addr_id = @IDAddr
				return(0)
			end
		'
		EXEC (@Sql)
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
