CREATE PROCEDURE [dbo].[ccspRepTrunkBusy] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
	CREATE TABLE #RtnValue (
		fecha DATETIME
		,puerto INT
		,cam_id INT
		,tbusy INT
		,contador INT
		,fechafin DATETIME
		,timegroup DATETIME
		,timegroupNext DATETIME
		)

	CREATE TABLE #RtnValue2 (
		fecha DATETIME
		,puerto INT
		,cam_id INT
		,tbusy INT
		,contador INT
		,fechafin DATETIME
		,timegroup DATETIME
		,timegroupNext DATETIME
		);

	WITH trunkOut
	AS (
		SELECT dials.fecha
			,dials.Puerto
			,dials.cam_id
			,dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0) AS tBusy
			,1 AS contador
			,dateadd(ss, dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0), dials.fecha) AS fechafin
		FROM ccologdials AS dials
		LEFT JOIN ccocallsout AS calls ON (
				dials.Puerto = calls.cal_puerto
				AND dials.cal_id = calls.cal_id
				)
		WHERE dials.fecha BETWEEN @from
				AND @to
		)
	INSERT INTO #RtnValue
	SELECT fecha
		,puerto
		,cam_id
		,tBusy
		,contador
		,fechafin
		,dbo.GetTimeGroup(fecha, 0) AS timegroup
		,dbo.GetTimeGroup(fechafin, 0) AS timegroupNext
	FROM trunkOut
	WHERE tBusy > 0

	INSERT INTO #RtnValue2
	SELECT *
	FROM #RtnValue
	WHERE datediff(mi, fecha, fechafin) > 15

	DELETE #RtnValue
	WHERE datediff(mi, fecha, fechafin) > 15

	INSERT INTO #RtnValue
	SELECT t.fecha
		,t.Puerto
		,t.cam_id
		,dbo.TimeInterval(th.start, th.stop, t.fecha, fechafin) AS tBusy
		,t.contador AS llamadas
		,fechafin
		,th.start
		,th.stop
	FROM #RtnValue2 t
	INNER JOIN TmpTimesInterval th ON (
			t.fecha > th.Start
			AND t.fecha < th.stop
			)
		OR th.Start BETWEEN t.fecha
			AND t.fechafin

	SELECT timegroup
		,puerto AS [port]
		,cam_id
		,SUM(tBusy) tBusy
		,sum(contador) AS llamadas
		,1 AS tipo
	INTO #ccGenOutPortStats
	FROM #RtnValue
	GROUP BY timegroup
		,puerto
		,cam_id

	INSERT INTO #ccGenOutPortStats
	SELECT timegroup
		,cal_puerto AS [port]
		,Inbound_id AS cam_id
		,sum(txfer + tRing + tDialog) AS tBusy
		,count(*) llamadas
		,0 AS tipo
	FROM tmpTimesInboundData
	GROUP BY timegroup
		,cal_puerto
		,Inbound_id
	HAVING sum(txfer + tRing + tDialog) > 0

	DELETE
	FROM RepInTrunkBusy
	WHERE DATE >= @from
		AND DATE < @to

	INSERT INTO RepInTrunkBusy
	SELECT timegroup
		,A.cam_id
		,[in].descripcion
		,[port]
		,tbusy
		,llamadas
		,datepart(yyyy, timegroup) AS [year]
		,datepart(mm, timegroup) AS [month]
		,datepart(dd, timegroup) AS [day]
		,datepart(hh, timegroup) AS [hour]
		,datepart(mi, timegroup) AS [minutes]
	FROM #ccGenOutPortStats A
	INNER JOIN ccInbound [in] ON [in].inbound_id = A.cam_id
		AND A.tipo = 0

	DELETE
	FROM RepOutTrunkBusy
	WHERE DATE >= @from
		AND DATE < @to

	INSERT INTO RepOutTrunkBusy
	SELECT timegroup
		,A.cam_id
		,[out].cam_descripcion
		,[port]
		,tbusy
		,llamadas
		,datepart(yyyy, timegroup) AS [year]
		,datepart(mm, timegroup) AS [month]
		,datepart(dd, timegroup) AS [day]
		,datepart(hh, timegroup) AS [hour]
		,datepart(mi, timegroup) AS [minutes]
	FROM #ccGenOutPortStats A
	INNER JOIN cccamps [out] ON (
			[out].cam_id = A.cam_id
			AND A.tipo = 1
			)

	DELETE
	FROM RepTrunkBusy
	WHERE DATE >= @from
		AND DATE < @to

	INSERT INTO RepTrunkBusy
	SELECT timegroup
		,port
		,tbusy
		,llamadas
		,datepart(yyyy, timegroup) AS [year]
		,datepart(mm, timegroup) AS [month]
		,datepart(dd, timegroup) AS [day]
		,datepart(hh, timegroup) AS [hour]
		,datepart(mi, timegroup) AS [minutes]
	FROM #ccGenOutPortStats A

	DROP TABLE #RtnValue

	DROP TABLE #RtnValue2

	DROP TABLE #ccGenOutPortStats
END