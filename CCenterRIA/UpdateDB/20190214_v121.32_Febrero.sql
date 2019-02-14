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

		SET @process = 'CW-2620 '
		SET @Sql = ''

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
