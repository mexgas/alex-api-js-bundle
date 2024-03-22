ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
	@action AS TINYINT,
	@from AS DATETIME= null,
	@to AS DATETIME= null

AS

	DECLARE @country AS TINYINT
	DECLARE @iva AS DECIMAL(3,2)
	DECLARE @aux AS VARCHAR(3)

	SELECT @country = CONVERT(TINYINT,isnull(valor,1)) FROM ccsettings WHERE setting_id = 104
	SELECT @aux = isnull(valor,0) FROM ccsettings WHERE setting_id = 25
	
	SET @iva=CONVERT(DECIMAL(3,2),'1.'+@aux)

	IF @country is null
		SET @country = 1
	IF @from is null
		SELECT @from = convert(DATETIME,convert(VARCHAR(11),getdate()))
	IF @to is null
		SELECT @to = getdate()

IF @action = 1
BEGIN

	IF OBJECT_ID('tempdb..#TempOutCallBilling') IS NOT NULL DROP TABLE #TempOutCallBilling
	IF OBJECT_ID('tempdb..#TempTransCallBilling') IS NOT NULL DROP TABLE #TempTransCallBilling

	DELETE FROM RepOutCallBilling WITH(rowlock) WHERE [date] >= @FROM AND [date] < @to

	CREATE TABLE #TempTransCallBilling(
		[date] datetime NOT NULL,
		camId INT NOT NULL,
		inboundId INT NOT NULL,
		userId INT NOT NULL,
		[proveedorId] INT NOT NULL,
		provedor VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		[tipollamadaId] INT NOT NULL,	
		[tipoLlamada] VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		[amount] INT NOT NULL,
		mins INT NOT NULL,
		costo DECIMAL(10,2) NOT NULL,
		costoIva DECIMAL(10,2) NOT NULL
	)

	INSERT INTO #TempTransCallBilling
	
	SELECT 
		[date],
		[camp_id],
		[inbund_id],
		[user_id],
		CASE WHEN [proveedorId] IS NULL THEN -1 ELSE [proveedorId] END AS proveedorId,
		CASE WHEN provedor IS NULL THEN 'systemTranslated_NoCarrier' ELSE provedor END AS provedor,
		[tipollamadaId],
		[tipoLlamada],
		COUNT(*) AS amount,
		SUM(mins) AS mins,  
		SUM([costo]) AS [costo],
		SUM( costo ) * @iva AS costoIva
	FROM (
		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
			cco.cam_id AS [camp_id],
			0 AS [inbund_id],
			cco.[User_id] AS [user_id],
			channel.proveedorId AS [proveedorId],
			prov.descrip AS provedor,
			tipoLlam.tipoLlamada_id AS [tipollamadaId],
			tipoLlam.descrip AS [tipoLlamada],
			CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],
			dbo.fnGetCstoTarifa(trans.tipoLlamada_id,channel.proveedorId,tAntesXfer+tDespuesXfer+1,@country) AS [costo]
		FROM 
			ccLogTransfers  trans 
			INNER JOIN ccoCallsOut cco ON cco.cal_id=trans.cal_id 
					AND tipo = 2
			INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country 
					AND tipoLlam.tipoLlamada_id = trans.tipoLlamada_id
			LEFT JOIN ccCallCost_RIA CCost on CCost.country_id = tipoLlam.country_id 
					AND CCost.tipoLlamada_id = tipoLlam.tipoLlamada_id
			LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId 
					AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
			LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE trans.fechaFin BETWEEN @from AND @to

		UNION ALL

		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
			0 AS [camp_id],
			cci.Inbound_id AS [inbund_id],
			cci.[User_id] AS [user_id],
			channel.proveedorId AS [proveedorId],
			prov.descrip AS provedor,
			tipoLlam.tipoLlamada_id AS [tipollamadaId],
			tipoLlam.descrip AS [tipoLlamada],
			CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],
			dbo.fnGetCstoTarifa(trans.tipoLlamada_id,channel.proveedorId,tAntesXfer+tDespuesXfer+1,@country) AS [costo]
		FROM	
			ccLogTransfers  trans 
			INNER JOIN ccCallsIn cci ON cci.cal_id=trans.cal_id 
					AND tipo = 1
			INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country 
					AND tipoLlam.tipoLlamada_id = trans.tipoLlamada_id
			LEFT JOIN ccCallCost_RIA CCost on CCost.country_id = tipoLlam.country_id 
							AND CCost.tipoLlamada_id = tipoLlam.tipoLlamada_id
			LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId 
					AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
			LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE trans.fechaFin BETWEEN @from AND @to 
			AND modo NOT IN (1,2)
	)x
	WHERE [costo] > 0
	GROUP BY [DATE],[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada]
		

	SELECT cal_inicio AS [date],
		cam_id,
		inboundId,
		[user_id],
		CASE WHEN provedor_id IS NULL THEN -1 ELSE provedor_id END AS provedor_id,
		tipoLlamada_id,
		MIN(tipoLlamada) AS tipoLlamada,
		COUNT(*) AS amount,
		SUM( mins) AS mins,
		SUM( costo ) AS costo,
		SUM( costo ) * @iva AS costoIva
	INTO #TempOutCallBilling
	FROM
	(
		SELECT cal_inicio,
			cco.cam_id AS cam_id,
			0 AS inboundId,
			cco.user_id AS user_id,
			cco.provedor_id,
			cco.tipoLlamada_id,
			t.descrip AS tipoLlamada,
			CEILING((cal_tXfer + cal_tRing + totalCall_Time +1 ) / 60.0 ) AS mins,
			dbo.fnGetCstoTarifa(cco.tipoLlamada_id, cco.provedor_id, cco.totalCall_Time,@country) AS costo
		FROM ccoCallsOut cco
			INNER JOIN cstoTipoLlamada t with(nolock) ON cco.tipoLlamada_id = t.tipoLlamada_id 
					AND country_id = @country
			LEFT JOIN ccCallCost_RIA CCost WITH(NOLOCK) ON CCost.country_id = t.country_id 
					AND CCost.tipoLlamada_id = t.tipoLlamada_id 
		WHERE cal_inicio >= @FROM 
			AND  cal_inicio < @to
			AND [User_id] <> 0

		UNION ALL

		-- Tambien las llamdas que fueron fax
		SELECT cco.fecha AS fecha,
			cco.cam_id,0 AS inboundId,
			0 AS userId,
			p.provedor_id,
			l.tipoLlamada_id,
			l.descrip AS tipoLlamada,
			1 AS mins,
			CASE 
				WHEN p.provedor_id IS NOT NULL THEN t.MinutoUno
				ELSE CONVERT(DECIMAL(10,2),CCost.cost_per_min)
			END AS costo
		FROM ccoLogDials  cco with(nolock)
			INNER JOIN ccoDialers cd with(nolock)  ON cco.puerto = cd.puerto
			LEFT JOIN cstoProvedor p ON cd.provedor_id = p.provedor_id
			LEFT JOIN cstoTarifa t ON  p.provedor_id = t.provedor_id 
					AND cco.tipoLlamada_id = t.tipoLlamada_id
			INNER JOIN cstotipollamada l on cco.tipoLlamada_id = l.tipoLlamada_id 
					AND country_id = @country
			LEFT JOIN ccCallCost_RIA CCost WITH(NOLOCK) ON CCost.country_id = l.country_id 
			AND CCost.tipoLlamada_id = l.tipoLlamada_id 	
		WHERE cco.fecha >=  @FROM 
			AND cco.fecha < @to  
			AND cco.answerbit = 1 
			AND cco.tiporesdial_id <> 1
	) costo
	GROUP BY cal_inicio, cam_id,inboundId, [user_id], provedor_id, tipoLlamada_id
		

	INSERT RepOutCallBilling
	SELECT CONVERT(smalldatetime, CONVERT(VARCHAR(13), [date], 121) + ':00', 121) AS [date],
		[cam_id],
		[campACDDescription],
		[user_id],[agentName],
		[username],
		[provedor_id],
		[provedor],
		[tipoLlamada_id],
		(CASE 
			WHEN tipo = 'amount' THEN 'systemTranslated_' + REPLACE([tipoLLamada],' ','') + 'Calls_Count'
			WHEN tipo = 'mins' THEN + 'systemTranslated_' + REPLACE([tipoLLamada],' ','') + 'MinBilled_Count'
			WHEN tipo = 'costo' THEN + 'systemTranslated_' + REPLACE([tipoLLamada],' ','') + 'Cost_Count'
			WHEN tipo = 'costoIva' THEN + 'systemTranslated_' + REPLACE([tipoLLamada],' ','') + 'Tax_Count'
			ELSE tipo
		END ) AS tipoLLamada_Count,
		CONVERT(VARCHAR,[tipollamada_Count])  AS [count],
		[tipoLLamada] AS tipoLlamadaDesp,
		CASE 
			WHEN tipo = 'costo' THEN CONVERT(int,CONVERT(DECIMAL(10,2),[tipollamada_Count]) ) 
			ELSE 0 
		END,
		DATEPART(yyyy,[date]) AS [year],
		DATEPART(mm,[date]) AS [month],
		DATEPART(dd,[date]) AS [day],
		DATEPART(hh,[date]) AS [hour],
		DATEPART(mi,[date]) AS [min],
		inboundId AS [inboundId],
		[dialId],
		[dialType]
	FROM(
		SELECT [date],
			temp.cam_id AS cam_id,inboundId,
			'Camp - ' + camps.cam_descripcion AS campACDDescription,
			ISNULL(ccuse.[user_id] ,0) AS [user_id],
			CASE 
				WHEN ccuse.[user_id] IS NULL THEN 'systemTranslated_NoName' 
				ELSE  ccuse.Nombres+' '+ ccuse.ApellidoPaterno+' '+ccuse.ApellidoMaterno 
			END AS agentName,
			CASE
				WHEN ccuse.[Login] IS NULL THEN 'systemTranslated_NoUserName' 
				ELSE ccuse.[Login] 
			END AS username,
			temp.provedor_id AS provedor_id,
			CASE WHEN prov.descrip IS NULL THEN 'systemTranslated_NoCarrier' ELSE prov.descrip END AS provedor,
			[tipoLlamada_id],
			[tipoLLamada],
			[tipoLLamada] AS tipoLlamadaDesp,
			CONVERT(VARCHAR,[amount]) AS [amount],
			CONVERT(VARCHAR,[mins]) AS [mins],
			CONVERT(VARCHAR,[costo]) AS [costo],
			CONVERT(VARCHAR,[costoIva]) AS [costoIva],
			di.id AS [dialId],
			di.[description] AS [dialType]
		FROM #TempOutCallBilling temp
			INNER JOIN ccCamps camps ON camps.cam_id = temp.cam_id
			LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.[user_id]
			LEFT JOIN cstoprovedor prov ON prov.provedor_id = temp.provedor_id
			INNER JOIN Dials di ON di.Id = 2
		UNION ALL
		SELECT [date],
			camId,
			inboundId,
			CASE
				WHEN camps.cam_descripcion IS NULL THEN 'ACD - ' + cci.descripcion 
				ELSE 'Camp - '+ camps.cam_descripcion 
			END AS campACDDescription,
			ISNULL(ccuse.[user_id] ,0) AS [user_id],
			CASE 
				WHEN ccuse.[user_id] IS NULL THEN 'systemTranslated_NoName'  
				ELSE  ccuse.Nombres+' '+ ccuse.ApellidoPaterno+' '+ccuse.ApellidoMaterno 
			END AS agentName,
			CASE
				WHEN ccuse.[Login] IS NULL THEN 'systemTranslated_NoUserName'
				ELSE ccuse.[Login]
			END AS username,
			[proveedorId],
			CASE WHEN provedor IS NULL THEN 'systemTranslated_NoCarrier' ELSE provedor END,
			[tipollamadaId],
			[tipoLlamada],
			[tipoLlamada] [tipoLlamadaDesp],
			CONVERT(VARCHAR,[amount]) AS [amount],
			CONVERT(VARCHAR,[mins]) AS [mins],
			CONVERT(VARCHAR,[costo]) AS [costo],
			CONVERT(VARCHAR,[costoIva]) AS [costoIva],
			di.Id AS [dialId],
			di.[description] AS [dialType]
		FROM #TempTransCallBilling temp
			LEFT JOIN ccCamps camps ON camps.cam_id = temp.camId
			LEFT JOIN ccinbound cci ON cci.Inbound_id=temp.inboundId 
			LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.userId
			INNER JOIN Dials di ON di.Id = 1
	) p
	UNPIVOT
		([tipollamada_Count] for tipo IN
		([amount], [mins], [costo], [costoIva])
	)AS unpvt
END