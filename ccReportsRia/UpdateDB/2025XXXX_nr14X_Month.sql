/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: Fix muñoz

Database: CCReportsRIA
Required version: 145

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON --

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
SET @version = 146 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
----------------------------------------- BEGIN MACL KR186000 --------------------------------------
    
    SET @process = 'Alter table  RepOutCallsDetail'
    SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''originNumber''
          AND Object_ID = Object_ID(N''RepOutCallsDetail''))
BEGIN
    ALTER TABLE RepOutCallsDetail ADD 
	originNumber VARCHAR(50),
	callbackDate DATETIME,
	queueTimes INT,
	ringingTime INT
END'
    EXEC(@sql)

	SET @process = 'DROP VIEW RepViewOutCallsDetail'
    SET @sql = 'if exists (select * FROM sys.views where name = N''RepViewOutCallsDetail'')
begin
    DROP VIEW RepViewOutCallsDetail
end'
    EXEC(@sql)

	SET @process = 'UPDATE reportsTotals for report 4020'
    SET @sql = 'update reportsTotals set totalColumns = ''sum:transferTime|sum:queueTimes|sum:dialog|sum:nque|sum:wrapup|sum:duration|sum:ncost|sum:totalRow|sum:ringingTime''
where id = 4020'
    EXEC(@sql)

	SET @process = 'Create View RepViewOutCallsDetail'
    SET @sql = 'CREATE VIEW [dbo].[RepViewOutCallsDetail] AS 
	SELECT
	[date],
	[callKey],
	[originNumber],
	[telephone],
	[transfer] as transferTime,
	[queueTimes],
	[ringingTime],
	[dialog],
	[nque],
	[wrapup],
	[CallDisposition],
	[subDisposition],
	[callbackDate],
	[extension],
	[userId],
	[login] [agentName],
	[username] [login],
	[campaign],
	[duration],
	[ncost],
	[iva],
	[total] as [totalRow],
	[ByCarrier],
	[Calltypes],
	[dialType],
	[whoHangUp],
	[dialResult] as [callStatus],
	[calId],
	[year],
	[month],
	[day],
	[hour],
	[minutes],
	[trunk],
	[data1] [Dato1],
	[data2] [Dato2],
	[data3] [Dato3],
	[data4] [Dato4],
	[data5] [Dato5],
	[MessageTime],
	[grabId]
	FROM RepOutCallsDetail nolock'
    EXEC(@sql)

	SET @process = 'Alter SP ccspRepOutCallsDetail'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @IVA INT, @IVAstring varchar(3)
DECLARE @country AS TINYINT

SELECT @IVA = convert(INT, isnull(valor, 0))
FROM ccsettings
WHERE setting_id = 25

SELECT @IVAstring =CONVERT(VARCHAR(5),@IVA) + ''%''

SELECT @country = convert(TINYINT, isnull(valor, 1))
FROM ccsettings
WHERE setting_id = 104

IF @country IS NULL
	SET @country = 1

IF @action = 1
BEGIN
	DELETE FROM RepOutCallsDetail WITH (ROWLOCK)
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
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''')[login],
		ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'')  AS [username],
		camps.cam_id AS [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
		(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

		@IVAstring AS iva,
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
		CASE 
			WHEN prov.descrip IS NOT NULL THEN prov.descrip
			ELSE ''systemTranslated_NoCarrier'' 
		END AS [ByCarrier],
		case 
			when @country<>1 then '''' 
			WHEN ld.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
			WHEN ld.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' 
			ELSE ''systemTranslated_Indefinite'' END [Calltypes],
		CASE 
		WHEN ld.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
		WHEN ld.TipoDialingMode =  ''10000000'' THEN ''systemTranslated_Assisted'' 
		WHEN ld.TipoDialingMode IN (''00001000'',''00010000'', ''000010000'') THEN ''systemTranslated_Callback'' 
		WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto'' 
		WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' 
		WHEN ld.TipoDialingMode = ''000000000'' THEN ''systemTranslated_Auto''
		ELSE ''''
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
		sta.descTranslated AS [dialResult], 
		Call.cal_id as [calId],
		datepart(yyyy, Call.cal_inicio) AS [year],
		datepart(mm, Call.cal_inicio) AS [month],
		datepart(dd, Call.cal_inicio) AS [day],
		datepart(hh, Call.cal_inicio) AS [hour],
		datepart(mi, Call.cal_inicio) AS [minutes],
		Call.cal_puerto,
		ISNULL(cod.Data1,ISNULL(cs.Dato1, '''')) AS [data1],
		ISNULL(cod.Data2,ISNULL(cs.Dato2, '''')) AS [data2],
		ISNULL(cod.Data3,ISNULL(cs.Dato3, '''')) AS [data3],
		ISNULL(cod.Data4,ISNULL(cs.Dato4, '''')) AS [data4],
		ISNULL(cod.Data5,ISNULL(cs.Dato5, '''')) AS [data5],
		ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
		ISNULL(rc.grab_id, 0) as grabId,
		ld.ani as originNumber,
		call.cal_fcallback as callbackDate,
		cal_que as queueTimes,
		Call.cal_txfer + call.cal_tring 
		+ CASE WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ld.tDialing ELSE 0 END
		as ringingTime
	FROM ccoCallsOut Call (nolock)
		LEFT JOiN ccoLogDials ld (nolock) ON Call.cal_id=ld.cal_id
		LEFT JOIN ccTipoCalifOUT Tipo (nolock) ON Call.calif_id = Tipo.calif_id
		LEFT JOIN ccUserView Usr (nolock) ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps (nolock) ON camps.[cam_id] = Call.[cam_id]
		LEFT JOIN ccStatusLlamada sta (nolock) ON call.statuscall_id = sta.statuscall_id
		LEFT JOIN cstoProvedor prov (nolock) ON prov.[provedor_id] = Call.[provedor_id]
		LEFT JOIN cstoTipoLlamada tl (nolock) ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
		LEFT JOIN ccTipoCalifSubOut sub (nolock) ON call.califsub_id = sub.califsub_id
		LEFT JOIN ccoDialers di (nolock) ON di.dialer_id = Call.cal_puerto AND call.provedor_id = di.provedor_id
		LEFT JOIN ccoCallsOutSource cs (nolock) ON Call.callout_id = cs.callout_id
		LEFT JOIN ccoCallsOutData cod (NOLOCK) on cod.cal_id = call.cal_id
		LEFT JOIN ccCallCost_RIA cc (nolock) ON cc.country_id = tl.country_id AND cc.tipoLlamada_id = tl.tipoLlamada_id
		LEFT JOIN Ria_grabacion rc (nolock) on (rc.cal_id = Call.cal_id and rc.tipo_llamada = 2)
	WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND Call.cal_manual IN (0, 2) and ld.TipoDialingMode IS NOT NULL
	ORDER BY DATE
END'
    EXEC(@sql)

	------------------------------------------ END MACL ---------------------------------------------

    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
