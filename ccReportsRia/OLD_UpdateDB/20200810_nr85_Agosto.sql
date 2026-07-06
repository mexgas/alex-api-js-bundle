SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 85

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4273 Insertar columna grabId en RepOutCallsDetail'
		set @sql = 'if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''grabId'' and TABLE_NAME = ''RepOutCallsDetail'') begin
			alter table RepOutCallsDetail add grabId int null
		end
		'
		EXEC(@sql)

		set @process = 'CW-4273 Insertar columna grabId en RepInCallsDetail'
		set @sql = 'if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''grabId'' and TABLE_NAME = ''RepInCallsDetail'') begin
			alter table RepInCallsDetail add grabId int null
		end
		'
		EXEC(@sql)

		set @process = 'CW-4273 Modificar sp ccspRepInCallsDetail'
		set @sql = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
DECLARE @callId AS INT

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))

	INSERT INTO @tab
	SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
	FROM (
		SELECT A.CallId, [Data], [Description]
		FROM DataCallIn A
		INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
		WHERE b.cal_Inicio >= @from AND b.cal_Inicio < @to
		) AS SourceTable
	pivot(max([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])) AS pvt

	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInCallsDetail WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId)
	SELECT cal_inicio, a.cal_id, Inbound_id, '''' AS Inbound, statusCall_id, '''' AS statusCall, a.calif_id, '''' AS calif, isnull(a.califSub_id, 0), '''' AS califSub, a.dni_id, '''' AS dni, user_id, '''' AS agentName, isnull(a.cal_key, ''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, a.cal_extension, '''', CASE 
			WHEN a.cal_whoHung = 0
				THEN ''systemTranslated_Client''
			WHEN a.cal_whoHung = 1
				THEN ''systemTranslated_Agent''
			ELSE ''systemTranslated_AgentSurvey''
			END [whoHangUp], a.cal_tMoh, datepart(yyyy, cal_inicio), datepart(mm, cal_inicio), datepart(dd, cal_inicio), datepart(hh, cal_inicio), datepart(mi, cal_inicio), di.provedor_id, prov.descrip [Proveedor], a.cal_puerto, CASE 
			WHEN a.file_moved = 1
				THEN ''systemTranslated_Remoto''
			ELSE ''Local''
			END AS file_Moved, cal_tNotas, AverageHandleTime = cal_tNotas + cal_tDialog, ISNULL(tab.Dato1, '''') AS Dato1, ISNULL(tab.Dato2, '''') AS Dato2, ISNULL(tab.Dato3, '''') AS Dato3, ISNULL(tab.Dato4, '''') AS Dato4, ISNULL(tab.Dato5, '''') AS Dato5,
			ISNULL(rc.cal_id, 0) AS grabId
	FROM cccallsin a
	LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
	LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
	LEFT JOIN @tab tab ON tab.callId = a.cal_id
	LEFT JOIN Ria_grabacion rc on rc.cal_id = a.cal_id 
	WHERE cal_inicio >= @from AND cal_inicio < @to

	UPDATE a
	SET acdGroup = isnull(descripcion, '''')
	FROM RepInCallsDetail a
	LEFT JOIN ccInbound b ON a.inboundId = b.Inbound_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET callStatus = isnull(descripcion, '''')
	FROM RepInCallsDetail a
	LEFT JOIN ccstatusllamada b ON a.callStatusId = b.statusCall_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET disposition = isnull(description, '''')
	FROM RepInCallsDetail a
	LEFT JOIN cctipocalif b ON a.dispositionId = b.calif_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET subDisposition = isnull(califSubDesc, '''')
	FROM RepInCallsDetail a
	LEFT JOIN cctipocalifsub b ON a.subDispositionId = b.califSub_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET dnis = isnull(dni_numero, '''')
	FROM RepInCallsDetail a
	LEFT JOIN ccdnis b ON a.dnisId = b.dni_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET [user] = isnull(LOGIN, ''''), agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''')
	FROM RepInCallsDetail a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to
END'
		EXEC(@sql)

		set @process = 'CW-4273 Modificar sp ccspRepOutCallsDetail'
		set @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
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
			WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
			WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
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
		ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
		ISNULL(rc.cal_id, 0) as grabId
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
		LEFT JOIN Ria_grabacion rc on rc.cal_id = Call.cal_id
	WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND Call.cal_manual IN (0, 2)
	ORDER BY DATE
END
'
		EXEC(@sql)

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
