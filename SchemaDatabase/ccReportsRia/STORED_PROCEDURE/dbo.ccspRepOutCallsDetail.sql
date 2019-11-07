CREATE PROCEDURE [dbo].[ccspRepOutCallsDetail] 
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
		ISNULL(Tipo.[description], '') AS [CallDisposition],
		Call.cal_extension AS [extension],
		isnull(Usr.user_id, 0) AS [userId],
		ISNULL(convert(VARCHAR(255), Usr.LOGIN), 'systemTranslated_NoUserName') [login],
		ISNULL(Usr.ApellidoPaterno + ' ' + ISNULL(Usr.ApellidoMaterno, '') + ' ' + Usr.Nombres, '') AS [username],
		camps.cam_id AS [campaignId],
		ISNULL(camps.cam_descripcion, 'systemTranslated_NoCampaign') AS [campaign],
		(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

		@IVA AS iva,
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
		CASE 
			WHEN prov.descrip IS NOT NULL THEN prov.descrip
			ELSE 'systemTranslated_NoCarrier' 
		END AS [ByCarrier],
		ISNULL(tl.descrip, 'systemTranslated_Indefinite') AS [Calltypes],
		CASE 
			WHEN Call.cal_manual = 0 THEN 'systemTranslated_Auto' 
			ELSE 'systemTranslated_Manual' 
		END AS [dialType], 
		CASE 
			WHEN cal_whoHung = 0 THEN 'systemTranslated_Client' 
			WHEN cal_whoHung = 1 THEN 'systemTranslated_Agent' 
			ELSE 'systemTranslated_AgentSurvey' 
		END [whoHangUp], 
		CASE 
			WHEN call.califsub_id = 0 THEN 'systemTranslated_NoSubDisposition' 
			ELSE isnull(sub.califSubDesc, '') 
		END AS [subDisposition],
		sta.descripcion AS [dialResult], 
		Call.cal_id AS [calId],
		datepart(yyyy, Call.cal_inicio) AS [year],
		datepart(mm, Call.cal_inicio) AS [month],
		datepart(dd, Call.cal_inicio) AS [day],
		datepart(hh, Call.cal_inicio) AS [hour],
		datepart(mi, Call.cal_inicio) AS [minutes],
		Call.cal_puerto,
		ISNULL(cs.Dato1, '') AS [data1],
		ISNULL(cs.Dato2, '') AS [data2],
		ISNULL(cs.Dato3, '') AS [data3],
		ISNULL(cs.Dato4, '') AS [data4],
		ISNULL(cs.Dato5, '') AS [data5],
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
END