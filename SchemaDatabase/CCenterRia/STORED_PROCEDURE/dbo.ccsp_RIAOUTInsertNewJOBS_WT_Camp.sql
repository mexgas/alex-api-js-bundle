CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1
AS
SET NOCOUNT ON

CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(20), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
declare @top int

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00
set @top=3000

SELECT @prioridad = isnull(Prioridad, '12345NNN')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

INSERT INTO #calloutIdSource
SELECT top(@top) cs.callout_id
FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
on cs.cal_key = wt.cal_keyw AND cs.cam_id = wt.cam_id 
WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

UNION

SELECT top(@top) Cout.callout_id
FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)

INSERT INTO #calloutIdSource2
SELECT top(@top) callout_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

IF exists(SELECT * FROM #calloutIdSource) 
BEGIN
	UPDATE ccoCallBacks
	SET [status] = 6, schedulerStatus = 1
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis
			)

	UPDATE ccoCallsOutSource
	SET cal_Status = 4
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis
			)
END

INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
 iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT top(@top) callout_id, cam_id, rtrim(left(ltrim(cal_telefono + '        ' + cal_telefono2 + '         ' 
+ cal_telefono3 + '         ' + cal_telefono4 + '         ' + cal_telefono5 + '         '), 13)) AS cal_telefono,
 CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
 CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
  CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
  CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
   CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
    CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
    CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
    CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
    CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
			NULL END iZonaHoraria_verano5, list_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

IF exists(SELECT * FROM #tempCallsOutSource)
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
	SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
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