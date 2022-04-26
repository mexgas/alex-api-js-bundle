CREATE PROCEDURE [dbo].[ccsptmpTimesHoldIn] @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#hold', N'U') IS NOT NULL
	DROP TABLE #hold

IF OBJECT_ID(N'tempdb..tempccHoldSession', N'U') IS NOT NULL
	DROP TABLE #tempccHoldSession

IF OBJECT_ID(N'tempdb..#holdMayores2', N'U') IS NOT NULL
	DROP TABLE #holdMayores2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = 'tmpTimesHoldIn'
		)
BEGIN
	CREATE TABLE tmpTimesHoldIn (
		inbound_id INT NOT NULL
		,userId INT NOT NULL
		,tiempohold INT NOT NULL
		,timegroup DATETIME
		,timegroup_next DATETIME
		)
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesHoldIn
		--drop table tmpTimesHoldIn
END

CREATE TABLE #hold (
	Fila INT
	,[userId] INT NOT NULL
	,[dateStart] [datetime] NOT NULL
	,[dateEnd] [datetime] NOT NULL
	,call_id INT NOT NULL
	,inbound_id INT NOT NULL
	,marca INT NOT NULL
	,Tipo_marca INT NOT NULL
	,Tipo_llamada INT NOT NULL
	,[timegroup] [datetime] NOT NULL
	,[timegroup_next] [datetime] NOT NULL
	,[time_dialog] [datetime] NOT NULL
	,[time_notes] [datetime] NOT NULL
	,[time_hold] [datetime] NOT NULL
	)

CREATE TABLE #tempccHoldSession (
	[fila] INT NOT NULL
	,[call_id] [int] NOT NULL
	,[userId] INT NOT NULL
	,[inbound_id] [int] NOT NULL
	,[hold] [datetime] NOT NULL
	,[unhold] [datetime] NULL
	,[Tipo_marca] [int] NOT NULL
	,[timegroup] [datetime] NOT NULL
	,[timegroup_next] [datetime] NOT NULL PRIMARY KEY (
		fila
		,call_id
		)
	)

CREATE TABLE #holdMayores2 (
	call_id INT NOT NULL
	,[userId] INT NOT NULL
	,inbound_id INT NOT NULL
	,hold [datetime] NOT NULL
	,[unhold] [datetime] NOT NULL
	,Tipo_marca INT NOT NULL
	,tiempoHold INT NOT NULL
	,[timegroup] [datetime] NOT NULL
	,[timegroup_next] [datetime] NOT NULL
	);

WITH timeHold
AS (
	SELECT User_id AS userId
		,cal_Inicio AS [dateStart]
		,dateadd(ss, cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas, cal_Inicio) AS [dateEnd]
		,cal_id AS cal_id
		,inbound_id AS inbound_id
		,isnull(h.marca, 0) AS Marca
		,CASE WHEN (h.tipo_marca > 0) THEN h.tipo_marca ELSE 0 END AS Tipo_marca
		,isnull(tipo_llamada, 0) AS Tipo_llamada
		,dbo.GetTimeGroup(cal_Inicio, 0) AS timegroup
		,dbo.GetTimeGroup(dateadd(ss, cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas, cal_Inicio), 1) AS timegroup_next
		,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring, 0), cal_inicio) AS time_dialog
		,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog, 0), cal_inicio) AS time_notes
		,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring + marca, 0), cal_Inicio) AS time_hold
	FROM cccallsin i(NOLOCK)
	LEFT JOIN RiaMarkHold h(NOLOCK)
		ON i.cal_id = h.call_id
			AND h.tipo_llamada = 1
	WHERE cal_Inicio BETWEEN @from
			AND @to
	)
INSERT INTO #hold
SELECT ROW_NUMBER() OVER (
		PARTITION BY cal_id ORDER BY time_hold
			,tipo_marca
		) Fila
	,*
FROM timeHold a
WHERE time_hold >= @from
	AND time_hold <= @to

INSERT INTO #tempccHoldSession
SELECT A.Fila
	,A.call_id
	,a.userId
	,a.inbound_id
	,A.time_hold hold
	,isnull(S.time_hold, a.time_notes) unhold
	,a.Tipo_marca Tipo_marca
	,a.timegroup timegroup
	,a.timegroup_next timegroup_next
FROM #hold A
LEFT JOIN #hold S
	ON A.Fila = S.Fila - 1
		AND A.call_id = S.call_id
		AND A.tipo_marca = 1
		AND S.tipo_marca = 0
WHERE A.tipo_llamada = 1
ORDER BY hold

SELECT ths.call_id
	,ths.userId
	,ths.inbound_id
	,ths.hold
	,ths.unhold
	,ths.Tipo_marca
	,[dbo].TimeInterval(th.[start], th.[stop], ths.hold, ths.unhold) AS tiempohold
	,ths.timegroup
	,ths.timegroup_next
INTO #tiempoHold
FROM #tempccHoldSession ths
INNER JOIN TmpTimesInterval th
	ON (
			ths.timegroup > th.Start
			AND ths.timegroup < th.stop
			)
		OR th.Start BETWEEN ths.timegroup
			AND ths.timegroup_next
WHERE [dbo].TimeInterval(th.[start], th.[stop], ths.hold, ths.unhold) > 0
	AND Tipo_marca = 1
	AND th.Start BETWEEN @from
		AND @to

INSERT INTO #holdMayores2
SELECT *
FROM #tiempoHold
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE #tiempoHold
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO #tiempoHold
SELECT call_id
	,userId AS userId
	,inbound_id AS inbound_id
	,hold
	,unhold
	,Tipo_marca
	,[dbo].TimeInterval(th.[start], th.[stop], hold, unhold) AS tiempohold
	,th.[start] AS timegroup
	,th.[stop] AS timegroup_next
FROM #holdMayores2 t
INNER JOIN TmpTimesInterval th
	ON (
			t.timegroup > th.Start
			AND t.timegroup < th.stop
			)
		OR th.Start BETWEEN t.timegroup
			AND t.timegroup_next
WHERE [dbo].TimeInterval(th.[start], th.[stop], hold, unhold) > 0
	AND th.Start BETWEEN @from
		AND @to

INSERT INTO tmpTimesHoldIn
SELECT inbound_id
	,userId
	,sum(tiempohold) AS tiempohold
	,timegroup
	,timegroup_next
FROM #tiempoHold
WHERE tiempoHold > 0
	AND Tipo_marca = 1
GROUP BY userId
	,inbound_id
	,timegroup
	,timegroup_next

IF OBJECT_ID(N'tempdb..#hold', N'U') IS NOT NULL
	DROP TABLE #hold

IF OBJECT_ID(N'tempdb..tempccHoldSession', N'U') IS NOT NULL
	DROP TABLE #tempccHoldSession

IF OBJECT_ID(N'tempdb..#holdMayores2', N'U') IS NOT NULL
	DROP TABLE #holdMayores2