/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Ulises Espinosa
Date: 2019/07/24
Description: CW-2703


Database: ccReportsRia
Required version: 69


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 70

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		
		set @process = 'CW-2703 Creacion de la tabla ccCallCost_Ria '
		set @sql = 'if not exists (select * from sys.tables where name = N''ccCallCost_RIA'')
			    begin
			        CREATE TABLE [dbo].[ccCallCost_RIA](
						[country_id] [smallint] NOT NULL,
						[tipoLlamada_id] [smallint] NULL,
						[cost_per_min] [float] NULL,
						[additional_min] [float] NULL
					) ON [PRIMARY]
			    end'

		exec (@sql)

		set @process = 'CW-2703 Creacion del indice de la tabla ccCallCost_Ria '
		set @sql = 'if not exists (select * from sys.indexes where name = N''PK_ccCallCost'' and object_id = OBJECT_ID(N''ccCallCost_RIA''))
				    begin
				        CREATE UNIQUE INDEX PK_ccCallCost ON ccCallCost_RIA (country_id,tipoLlamada_id)
				    end'

		exec (@sql)

		SET @process = 'CW-2703 Correccion de la funcion'
		SET @sql = '
ALTER FUNCTION [dbo].[fnGetCstoTarifa](
		@tipoLlamada_id TINYINT, 
		@provedor_id SMALLINT, 
		@callTime INT,
		@country_id smallint = null)
	RETURNS DECIMAL(10,3)  
	AS
	BEGIN

		DECLARE @minutouno DECIMAL(10,3)  
		DECLARE @minutoadicional DECIMAL(10,3)
		DECLARE  @costo DECIMAL(10,3)
		IF @provedor_id IS NOT NULL
			BEGIN
			SELECT @minutouno = minutouno, 
				@minutoadicional = minutoadicional
				FROM cstoTarifa 
				WHERE tipollamada_id =  @tipoLlamada_id and @provedor_id = provedor_id
			SELECT @costo = @MinutoUno + CASE WHEN ISNULL(@callTime,0) > 0 
				THEN((CEILING(( ISNULL(@callTime,0) ) / 60.0 )- 1) * @MinutoAdicional ) 
				ELSE 0 
				END
		END
		ELSE
			BEGIN
				SELECT @minutouno = cost_per_min, 
					@minutoadicional = additional_min
					FROM ccCallCost_RIA 
					WHERE tipollamada_id =  @tipoLlamada_id AND country_id = @country_id
				SELECT @costo = @MinutoUno + CASE WHEN ISNULL(@callTime,0) > 0 
					THEN((CEILING(( ISNULL(@callTime,0) ) / 60.0 )- 1) * @MinutoAdicional ) 
					ELSE 0 
					END
			END
		RETURN ISNULL(@costo, 0)
	END'
		EXEC (@sql)

		SET @process = 'CW-2703 Correccion del sp ccspRepOutCallsDetail'
		SET @sql = '
ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @IVA INT
DECLARE @country AS TINYINT

SELECT @IVA = convert(INT, isnull(valor, 0))
FROM ccsettings
WHERE setting_id = 25

SELECT @country = convert(TINYINT, isnull(valor, 1))
FROM ccsettings
WHERE setting_id = 104

IF @country IS NULL
	SET @country = 1

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepOutCallsDetail WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepOutCallsDetail
	SELECT Call.cal_inicio AS [date],
		Call.cal_key AS [callKey],
		Call.cal_telefono AS [telephone],
		Call.cal_txfer + call.cal_tring AS [transfer],
		Call.cal_tdialog AS [dialog],
		ISNULL(Call.cal_tMoh, 0) AS [nque],
		Call.cal_tnotas AS [wrapup],
		ISNULL(Tipo.[description], '''') AS [CallDisposition],
		Call.cal_extension AS [extension],
		isnull(Usr.user_id, 0) AS [userId],
		ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'') [login],
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username],
		camps.cam_id AS [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
		(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

		@IVA AS iva,
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
		CASE 
			WHEN prov.descrip IS NOT NULL THEN prov.descrip
			ELSE ''systemTranslated_NoCarrier'' 
		END AS [ByCarrier],
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [Calltypes],
		CASE 
			WHEN Call.cal_manual = 0 THEN ''systemTranslated_Auto'' 
			ELSE ''systemTranslated_Manual'' 
		END AS [dialType], 
		CASE 
			WHEN cal_whoHung = 0 THEN ''systemTranslated_Client'' 
			WHEN cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
			ELSE ''systemTranslated_AgentSurvey'' 
		END [whoHangUp], 
		CASE 
			WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
			ELSE isnull(sub.califSubDesc, '''') 
		END AS [subDisposition],
		sta.descripcion AS [dialResult], 
		Call.cal_id AS [calId],
		datepart(yyyy, Call.cal_inicio) AS [year],
		datepart(mm, Call.cal_inicio) AS [month],
		datepart(dd, Call.cal_inicio) AS [day],
		datepart(hh, Call.cal_inicio) AS [hour],
		datepart(mi, Call.cal_inicio) AS [minutes],
		Call.cal_puerto,
		ISNULL(cs.Dato1, '''') AS [data1],
		ISNULL(cs.Dato2, '''') AS [data2],
		ISNULL(cs.Dato3, '''') AS [data3],
		ISNULL(cs.Dato4, '''') AS [data4],
		ISNULL(cs.Dato5, '''') AS [data5],
		ISNULL(Call.cal_tMsg, 0) AS [MessageTime]
	FROM ccoCallsOut Call
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id = Tipo.calif_id
		LEFT JOIN ccUserView Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
		LEFT JOIN ccStatusLlamada sta ON call.statuscall_id = sta.statuscall_id
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
		LEFT JOIN ccTipoCalifSubOut sub ON call.califsub_id = sub.califsub_id
		LEFT JOIN ccoDialers di ON di.dialer_id = Call.cal_puerto AND call.provedor_id = di.provedor_id
		LEFT JOIN ccoCallsOutSource cs ON Call.callout_id = cs.callout_id
		LEFT JOIN ccCallCost_RIA cc ON cc.country_id = tl.country_id AND cc.tipoLlamada_id = tl.tipoLlamada_id
	WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND cal_manual IN (0, 2)
	ORDER BY DATE
END'
		EXEC (@sql)

		SET @process = 'CW-2703 Correcion del sp ccspRepOutCallBilling '
		SET @sql = '		
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
	
	SET @iva=CONVERT(DECIMAL(3,2),''1.''+@aux)

	IF @country is null
		SET @country = 1
	IF @from is null
		SELECT @from = convert(DATETIME,convert(VARCHAR(11),getdate()))
	IF @to is null
		SELECT @to = getdate()

IF @action = 1
BEGIN

	IF OBJECT_ID(''tempdb..#TempOutCallBilling'') IS NOT NULL DROP TABLE #TempOutCallBilling
	IF OBJECT_ID(''tempdb..#TempTransCallBilling'') IS NOT NULL DROP TABLE #TempTransCallBilling

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
		CASE WHEN provedor IS NULL THEN ''systemTranslated_NoCarrier'' ELSE provedor END AS provedor,
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
			INNER JOIN cstoTipoLlamada t with(index(IX_cstoTipoLlamada),nolock) ON cco.tipoLlamada_id = t.tipoLlamada_id 
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
		FROM ccoLogDials  cco with(index(IX_ccoLogDials),nolock)
			INNER JOIN ccoDialers cd with(index(IX_ccoDialers),nolock)  ON cco.puerto = cd.puerto
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
	SELECT CONVERT(smalldatetime, CONVERT(VARCHAR(13), [date], 121) + '':00'', 121) AS [date],
		[cam_id],
		[campACDDescription],
		[user_id],[agentName],
		[username],
		[provedor_id],
		[provedor],
		[tipoLlamada_id],
		(CASE 
			WHEN tipo = ''amount'' THEN ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Calls_Count''
			WHEN tipo = ''mins'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''MinBilled_Count''
			WHEN tipo = ''costo'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Cost_Count''
			WHEN tipo = ''costoIva'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Tax_Count''
			ELSE tipo
		END ) AS tipoLLamada_Count,
		CONVERT(VARCHAR,[tipollamada_Count])  AS [count],
		[tipoLLamada] AS tipoLlamadaDesp,
		CASE 
			WHEN tipo = ''costo'' THEN CONVERT(int,CONVERT(DECIMAL(10,2),[tipollamada_Count]) ) 
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
			''Camp - '' + camps.cam_descripcion AS campACDDescription,
			ISNULL(ccuse.[user_id] ,0) AS [user_id],
			CASE 
				WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName'' 
				ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno 
			END AS agentName,
			CASE
				WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName'' 
				ELSE ccuse.[Login] 
			END AS username,
			temp.provedor_id AS provedor_id,
			CASE WHEN prov.descrip IS NULL THEN ''systemTranslated_NoCarrier'' ELSE prov.descrip END AS provedor,
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
				WHEN camps.cam_descripcion IS NULL THEN ''ACD - '' + cci.descripcion 
				ELSE ''Camp - ''+ camps.cam_descripcion 
			END AS campACDDescription,
			ISNULL(ccuse.[user_id] ,0) AS [user_id],
			CASE 
				WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName''  
				ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno 
			END AS agentName,
			CASE
				WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName''
				ELSE ccuse.[Login]
			END AS username,
			[proveedorId],
			CASE WHEN provedor IS NULL THEN ''systemTranslated_NoCarrier'' ELSE provedor END,
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
END'
		EXEC (@sql)

		SET @process = 'CW-2703 Correccion del sp ccspRepOutAnswAndXferCalls'
		SET @sql = '
ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL
AS

IF @from IS NULL
SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT


SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1


IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WITH(ROWLOCK) WHERE DATE >= @from AND DATE < @TO

INSERT INTO RepOutAnswAndXferCalls

SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
	ISNULL(ccld.cal_id,0) AS [callid],
	ISNULL(ccld.cam_id,0) AS [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
	ISNULL([Call].user_id,0) AS [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
	CASE 
		WHEN (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 
			THEN COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) 
		ELSE 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) 
	END AS [dialog],
	ccld.telefono AS [telephone],
	ISNULL(Call.cal_manual,0) AS [dialId],
	ISNULL((SELECT [description] FROM dialType 
				WHERE dialId = Call.cal_manual),''systemTranslated_Auto'') AS [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
	CASE 
		WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
			CASE 
				WHEN (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 
					THEN COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) 
				ELSE 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) 
			END,@country)
		ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) / 60) * ccost.additional_min)))
	END AS [ncost],
	@IVA AS iva,
	CASE
		WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
			CASE 
				WHEN (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 
					THEN COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) 
				ELSE 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) 
			END,@country),0.00) * (1 + (@IVA / 100.00)))
		ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
	END	AS total
FROM (SELECT *, [dbo].[GetProveedor](Telefono, Puerto,CallType) AS proBIDs 
		FROM (SELECT *, tipoLlamada_id as CallType 
				FROM ccologdials WITH(NOLOCK)
					WHERE fecha >= @from and fecha < @to and answerbit = 1
				) as basequery 
		) ccld
	LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
			AND ccld.answerbit = 1
	LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
	LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id
			AND ccost.country_id = tl.country_id
ORDER BY DATE

INSERT INTO RepOutAnswAndXferCalls

SELECT DATEADD(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) AS [date],
	clt.cal_id AS [callid],
	COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
	COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
	ISNULL((CASE tipo 
				WHEN 1 THEN ci.User_id 
				ELSE co.User_id 
			END),0) AS [userId],
	ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
				(CASE tipo 
					WHEN 1 THEN ci.User_id 
					ELSE co.User_id 
				END)),''systemTranslated_NoName'') as [Agent],
	CASE 
		WHEN ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 THEN (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) 
		ELSE 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) 
	END AS [dialog],
	CASE 
		WHEN modo = 0 THEN ISNULL((SELECT TOP 1 tel FROM telefonosTransferencia WHERE tel = clt.destino),clt.destino)  
		WHEN modo = 3 THEN isnull((SELECT tel FROM telefonosConferencia WHERE tel = clt.destino),clt.destino) 
		WHEN modo = 4 THEN isnull((SELECT TOP 1 tel FROM telefonosTransferencia WHERE tel = clt.destino),clt.destino) 
		WHEN modo = 5 THEN isnull((SELECT Computer FROM ccposicion WHERE pos_id = abs(clt.destino)),clt.destino) 
	END AS [telephone],
	3 AS [dialId],
	(SELECT [description] FROM dialType WHERE dialId = 3) AS [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			CASE 
				WHEN ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 THEN (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) 
				ELSE 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) 
			END,@country), 0) 
		ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
	END AS [ncost],
	@IVA AS iva,
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			CASE 
				WHEN ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 THEN (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) 
				ELSE  60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) 
			END,@country),0.00) * (1 + (@IVA / 100.00))) 
		ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
	END AS [total]
FROM (SELECT *, tipoLlamada_id AS  CallType 
	FROM cclogtransfers WITH(NOLOCK) 
	WHERE modo not in (1,2) 
		AND (tAntesXfer > 0 or tDespuesXfer > 0) 
		AND dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from 
		AND dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
	LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
	LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
	LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
	LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
	LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
	LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id
order by date 

	end'
		EXEC (@sql)

		

		SET @process = 'CW-2703 Update del traductor'
		SET @sql = 'Update TranslatedReports set columns = ''agentName|user|dialType|provider'' where id = 4060 '
		EXEC (@sql)


		SET @process = 'CW-3133 Add Column ccoLogDials.tipoLlamada_id'
		SET @sql = 'if not exists (select * from sys.columns where name = N''tipoLlamada_id'' and Object_ID = Object_ID(N''ccoLogDials''))
		begin
			ALTER TABLE ccoLogDials  ADD tipoLlamada_id smallint  NULL 
		end'

		EXEC (@sql)

	
		SET @process = 'CW-3133 Add Column RepOutDialDetail.TipoTel'
		SET @sql = 'if not exists (select * from sys.columns where name = N''TipoTel'' and Object_ID = Object_ID(N''RepOutDialDetail''))
		begin
			ALTER TABLE RepOutDialDetail  ADD TipoTel varchar(max)  NULL 
		end'

		EXEC (@sql)

		SET @process = 'CW-3133 Update TranslatedReports id 4010'
		SET @sql = 'Update TranslatedReports set [columns]=''campaign|billed|fileMoved|dialType|TipoTel''  where id=4010'
		EXEC (@sql)

		EXEC (@sql)

		SET @process = 'CW-3133 Alter SP ccspRepOutDialDetail agregando la columna TipoTel '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]   
@action as tinyint,  
@from as datetime = null,  
@to as datetime = null  
AS  
if @from is null  
select @from = convert(datetime,convert(varchar(11),getdate()))  
select @to = getdate()  
if @action = 1  begin  
--Borrar lo que esta para no repetir  
delete from RepOutDialDetail with(rowlock)  
where date >= @from AND date < @to  
declare @country smallint
select @country=valor from ccSettings where setting_id=104

--Inserta informaci?n de reporte  
insert into RepOutDialDetail  
SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado, 
dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime,  
datepart(yyyy,fecha), datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha), isnull(rl.name,'''')  
,case when answerbit = 1 then ''systemTranslated_Charged'' else ''systemTranslated_NotCharged'' end as billed, 
isnull(cs.Dato1,'''') as data1, isnull(cs.Dato2,'''') as data2, isnull(cs.Dato3,'''') as data3, isnull(cs.Dato4,'''') as data4, isnull(cs.Dato5,'''') as data5
,case when dials.[file_moved] = 1 then ''systemTranslated_Remoto'' else ''Local'' end as file_Moved, dials.disconnectCause, COALESCE(dat.description, descripcion,''N/A'') DCCustomer
,dials.dialType,case when @country=1 then isnull((select case when dials.tipoLlamada_id in (1,2,5)   then ''systemTranslated_fijo''
	when dials.tipoLlamada_id in(3,4) then ''systemTranslated_cellPhone'' else  ''systemTranslated_Indefinite'' end
	),''systemTranslated_Indefinite'') else '''' end as TipoTel
FROM 
(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,  
	case when Left(dial.TipoDialingMode,1)=''1'' then ''Preview'' else
			case when right(dial.TipoDialingMode,2)=''00'' then ''systemTranslated_Auto'' 
			when right(dial.TipoDialingMode,2) in (''10'',''01'') then ''systemTranslated_Manual'' end end as dialType,
	dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key, co.file_moved,dial.tipoLlamada_id 
	FROM ccoLogDials dial (nolock)
	left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
	WHERE fecha >= @from AND fecha < @to) dials  
LEFT JOIN ccoCallsOutSource cs (nolock) ON dials.callout_id = cs.callout_id  
LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id  
LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]  
LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id 
LEFT JOIN DC_Extra dat on(dat.id = substring(dials.disconnectCause,21,3))
WHERE fecha >= @from AND fecha < @to  
order by fecha  
end'

		EXEC (@sql)



		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
