CREATE PROCEDURE [dbo].ccspTimesccLogAgentesDia @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#tempccLogAgentesDia', N'U') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia

IF OBJECT_ID(N'tempdb..#tempccLogAgentesDia2', N'U') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = 'tmpccLogAgentesDia'
		)
BEGIN
	CREATE TABLE tmpccLogAgentesDia (
		id INT NOT NULL IDENTITY PRIMARY KEY
		,userId INT NOT NULL
		,TipoStatusAge_id TINYINT NOT NULL
		,tStatus FLOAT NOT NULL
		,dateIni DATETIME NOT NULL
		,dateEnd DATETIME NOT NULL
		,currentStatus INT NOT NULL
		,timeGroup DATETIME NOT NULL
		,timeGroupNext DATETIME NOT NULL
		,camId SMALLINT
		,camType SMALLINT
		,callId INT
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpccLogAgentesDia
		--drop table tmpccLogAgentesDia
END

CREATE TABLE #tempccLogAgentesDia (
	row INT NOT NULL
	,user_id INT NOT NULL
	,TipoStatusAge_id TINYINT NOT NULL
	,tStatus FLOAT NOT NULL
	,dateIni DATETIME NOT NULL
	,dateEnd DATETIME NOT NULL
	,currentStatus INT
	,timeGroup DATETIME NOT NULL
	,timeGroupNext DATETIME NOT NULL
	,camId SMALLINT
	,camType SMALLINT
	,callId INT
	);;

WITH tmpLog
AS (
	SELECT User_id AS userId
		,TipoStatusAge_id
		,tStatus
		,DATEADD(ss, - tStatus, fecha) dateIni
		,fecha dateEnd
		,ISNULL(currentStatus, 0) AS currentStatus
		,dbo.GetTimeGroup(DATEADD(ss, - tStatus, fecha), 0) AS timegroup
		,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
		,IdCampEsp AS camId
		,Tipo AS camType
		,callId
	FROM ccLogAgentesDia
	WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to 
	)
INSERT INTO #tempccLogAgentesDia
SELECT ROW_NUMBER() OVER (
		PARTITION BY userId ORDER BY dateIni
		) AS Row
	,userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timegroup
	,timegroup_next
	,camId
	,camType
	,callId
FROM tmpLog

DELETE A
FROM (
	SELECT CASE WHEN A.tStatus > S.tStatus THEN S.row ELSE A.row END row
		,A.user_id
	FROM #tempccLogAgentesDia A
	LEFT JOIN #tempccLogAgentesDia S ON A.Row = S.Row - 1
		AND A.user_id = S.user_id
	WHERE A.dateIni >= @from
		AND A.dateIni < @to
		AND A.TipoStatusAge_id = S.TipoStatusAge_id
		AND (
			S.dateEnd BETWEEN A.dateIni
				AND A.dateEnd
			OR S.dateIni BETWEEN A.dateIni
				AND A.dateEnd
			)
		AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 1
	) x
INNER JOIN #tempccLogAgentesDia A ON A.row = x.row
	AND A.user_id = x.user_id;

-----------Se agrega el estado actual
DECLARE @dateNow DATETIME
	,@date DATE
	,@maxLogout DATETIME;

SET @dateNow = GETDATE();

SELECT @maxLogout = MAX(logout)
FROM TmpSessionTimeGroup;

IF CONVERT(DATE, @dateNow, 121) = CONVERT(DATE, @to, 121)
BEGIN

	declare @today date

	set @today=convert(DATE, @to, 121)
		;

	WITH tempAgentLastStatus
	AS (
		SELECT User_id AS userId
			,MAX(fecha) AS fecha
		FROM ccLogAgentesDia
		WHERE fecha BETWEEN @today AND @to
		GROUP BY User_id
		)		

	INSERT INTO #tempccLogAgentesDia
	SELECT 0
		,A.user_id
		,A.currentStatus
		,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
		,A.dateEnd
		,@dateNow
		,A.currentStatus
		,dbo.GetTimeGroup(B.fecha, 0) AS timegroup
		,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
		,A.camId
		,A.camType
		,A.callId
	FROM #tempccLogAgentesDia A
	INNER JOIN tempAgentLastStatus B ON A.dateEnd = B.fecha
		AND A.User_id = B.userId
	WHERE A.dateIni BETWEEN convert(DATE, @to, 121)
			AND @to
		AND A.currentStatus NOT IN (- 2, - 1, 0);
END

SELECT *
INTO #tempccLogAgentesDia2
FROM #tempccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15

DELETE #tempccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;

INSERT INTO #tempccLogAgentesDia
SELECT 1
	,t.user_id
	,TipoStatusAge_id
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,t.camId
	,t.camType
	,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
	AND th.Start BETWEEN @from
		AND @to;

INSERT INTO tmpccLogAgentesDia (
	userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timeGroup
	,timeGroupNext
	,camId
	,camType
	,callId
	)
SELECT user_id AS userId
	,TipoStatusAge_id
	,SUM(tStatus) tStatus
	,MIN(dateIni) dateIni
	,MIN(dateEnd) dateEnd
	,currentStatus
	,timeGroup
	,timeGroupNext
	,min(camId) AS camId
	,min(camType) AS camType
	,min(callId) AS callId
FROM #tempccLogAgentesDia
GROUP BY timeGroup
	,user_id
	,TipoStatusAge_id
	,currentStatus
	,timeGroupNext
ORDER BY dateIni
	,userId

IF OBJECT_ID(N'tempdb..#tempccLogAgentesDia', N'U') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia

IF OBJECT_ID(N'tempdb..#tempccLogAgentesDia2', N'U') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2