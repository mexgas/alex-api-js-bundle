CREATE PROCEDURE [dbo].[ccspRepSpecialTimes] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepSpecialTimes
	WHERE DATE >= @from
		AND DATE < @to

	DECLARE @NotReady VARCHAR(max)

	SELECT TOP 1 @NotReady = descripcion
	FROM ccTipoNotReady
	ORDER BY tiponotready_id;

	WITH timeAgent
	AS (
		SELECT dateadd(mi, CASE WHEN datePart(mi, timeGroup) IN (15, 45) THEN - 15 ELSE 0 END, timeGroup) AS timeGroup
			,camId
			,camType
			,CASE WHEN tipostatusage_id = 3 THEN 'Tiempo Disponible' WHEN tipostatusage_id = 4 THEN 'Tiempo Dialogo' WHEN tipostatusage_id = 2 THEN 'Tiempo No Disponible' ELSE 'Otro' END AS tDescripcion
			,tStatus
			,TipoStatusAge_id
			,dateIni
			,dateEnd
			,dbo.AccountInterval(dateIni, dateEnd, timeGroup, timeGroupNext, 1) ntotal
		FROM tmpccLogAgentesDia
		WHERE tStatus > 0
		)
		,times
	AS (
		SELECT C.cam_id
			,0 AS inbound_id
			,'Camp - ' + C.cam_descripcion AS [Espec/Camp]
			,A.timegroup
			,A.tDescripcion
			,sum(tStatus) AS tStatus
		FROM timeAgent A
		INNER JOIN cccamps C ON A.camId = C.cam_id
			AND A.camType = 1
		GROUP BY C.cam_id
			,C.cam_descripcion
			,A.timeGroup
			,A.tDescripcion
		
		UNION ALL
		
		SELECT 0 AS cam_id
			,inbound_id
			,'ACD - ' + C.descripcion AS [Espec/Camp]
			,A.timegroup
			,A.tDescripcion
			,sum(tStatus) AS tStatus
		FROM timeAgent A
		INNER JOIN ccinbound C ON A.camId = C.inbound_id
			AND A.camType = 0
		GROUP BY C.inbound_id
			,C.descripcion
			,A.timeGroup
			,A.tDescripcion
		)
		,Report1
	AS (
		SELECT cam_id
			,inbound_id
			,[Espec/Camp]
			,timegroup
			,isnull([Tiempo Disponible], 0) + isnull([Tiempo Dialogo], 0) + isnull([Tiempo No Disponible], 0) + isnull([Otro], 0) AS [Tiempo Sesion]
			,isnull([Tiempo Disponible], 0) AS [Tiempo Disponible]
			,isnull([Tiempo Dialogo], 0) AS [Tiempo Dialogo]
			,isnull([Tiempo No Disponible], 0) AS [Tiempo No Disponible]
			,isnull([Otro], 0) AS [Otro]
		FROM times
		pivot(max(tstatus) FOR [tdescripcion] IN ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) AS pvtTimes
		WHERE [Espec/Camp] IS NOT NULL
		)
		,NotReadyTime
	AS (
		SELECT A.timeGroup
			,B.TipoNotReady_id
			,C.Descripcion
			,A.tStatus
			,A.camId
			,A.camType
			,A.ntotal
		FROM timeAgent A
		LEFT JOIN ccLogAgentesNotReady B ON A.dateEnd = B.fecha
		LEFT JOIN ccTipoNotReady c ON B.TipoNotReady_id = c.tiponotready_id
		WHERE TipoStatusAge_id = 2
		)
		,notready
	AS (
		SELECT 'Camp - ' + cam_descripcion AS [Espec/Camp]
			,A.timeGroup
			,A.Descripcion AS [descriptionT]
			,sum(A.tstatus) AS T
			,A.Descripcion AS [descriptionN]
			,sum(ntotal) AS N
		FROM NotReadyTime A
		LEFT JOIN cccamps b ON A.camId = b.cam_id
			AND A.camType = 1
		GROUP BY cam_descripcion
			,timeGroup
			,A.Descripcion
		
		UNION
		
		SELECT 'ACD - ' + b.descripcion AS [Espec/Camp]
			,A.timeGroup
			,A.Descripcion AS [descriptionT]
			,sum(A.tstatus) AS T
			,A.Descripcion AS [descriptionN]
			,sum(ntotal) AS N
		FROM NotReadyTime A
		LEFT JOIN ccinbound b ON A.camId = b.Inbound_id
			AND A.camType = 0
		GROUP BY b.descripcion
			,timeGroup
			,A.Descripcion
		)

	INSERT INTO RepSpecialTimes
	SELECT a.timeGroup AS [date]
		,a.cam_id AS [campaignId]
		,a.inbound_id AS [inboundId]
		,a.[Espec/Camp] AS [campACDDescription]
		,[Tiempo Sesion] AS [sessionTime]
		,[Tiempo Disponible] AS [readyTime]
		,[Tiempo Dialogo] AS [dialogTime]
		,[Tiempo No Disponible] AS [notReadyTime]
		,[Otro] AS [other]
		,descriptionN AS [descripcion]
		,descriptionN + '_Count' AS [descripcion_count]
		,[N] AS [count]
		,b.descriptionT + '_Time' AS [descripcion_time]
		,[T] AS [time]
		,[T] AS [timeSeconds]
		,datepart(yyyy, a.timeGroup) AS [year]
		,datepart(mm, a.timeGroup) AS [month]
		,datepart(dd, a.timeGroup) AS [day]
		,datepart(hh, a.timeGroup) AS [hour]
		,datepart(mi, a.timeGroup) AS [minutes]
	FROM Report1 a
	LEFT JOIN notready b ON (
			a.[Espec/Camp] = b.[Espec/Camp]
			AND a.timeGroup = b.timeGroup
			)
	WHERE b.timeGroup IS NOT NULL
	
	UNION
	
	SELECT a.timeGroup
		,a.cam_id
		,a.inbound_id
		,a.[Espec/Camp]
		,[Tiempo Sesion] AS [Tiempo Sesion]
		,[Tiempo Disponible] AS [Tiempo Disponible]
		,[Tiempo Dialogo] AS [Tiempo Dialogo]
		,[Tiempo No Disponible] AS [Tiempo No Disponible]
		,[Otro] AS [Otro]
		,@NotReady
		,@NotReady + '_Count'
		,0
		,@NotReady + '_Time'
		,'0'
		,0
		,datepart(yyyy, a.timeGroup) AS [year]
		,datepart(mm, a.timeGroup) AS [month]
		,datepart(dd, a.timeGroup) AS [day]
		,datepart(hh, a.timeGroup) AS [hour]
		,datepart(mi, a.timeGroup) AS [minutes]
	FROM Report1 a
	LEFT JOIN notready b ON (
			a.[Espec/Camp] = b.[Espec/Camp]
			AND a.timeGroup = b.timeGroup
			)
	WHERE b.timeGroup IS NULL
	ORDER BY a.[Espec/Camp]
		,a.timeGroup
END