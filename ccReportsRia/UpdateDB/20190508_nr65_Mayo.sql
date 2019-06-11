/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Jesus Gallardo
Date: 2019/04/02
Description: CW-2114


Database: ccReportsRia
Required version: 64


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 65

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		SET @process = 'CW-2114 Rename Columns '
		SET @sql = 'if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''agentName'' AND t.name = ''RepAgentCallStatusesByInterval'')
begin	
	EXEC sp_RENAME ''RepAgentCallStatusesByInterval.agentName'', ''login'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''userName'' AND t.name = ''RepInCallsDetail'')
begin	
	EXEC sp_RENAME ''RepInCallsDetail.userName'', ''user'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''userName'' AND t.name = ''RepInDispositions'')
begin	
	EXEC sp_RENAME ''RepInDispositions.userName'', ''user'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''userName'' AND t.name = ''RepInSubDispositions'')
begin	
	EXEC sp_RENAME ''RepInSubDispositions.userName'', ''user'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''user'' AND t.name = ''RepChatsDetail'')
begin	
	EXEC sp_RENAME ''RepChatsDetail.user'', ''userName'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''user'' AND t.name = ''RepAvgAnswerTimeChats'')
begin	
	EXEC sp_RENAME ''RepAvgAnswerTimeChats.user'', ''userName'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''userName'' AND t.name = ''RepOutCallBilling'')
begin	
	EXEC sp_RENAME ''RepOutCallBilling.userName'', ''user'', ''COLUMN''
end

if exists(SELECT c.name AS ''ColumnName'', t.name AS ''TableName''
FROM sys.columns c
inner JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = ''userName'' AND t.name = ''RepOutSubDispositions'')
begin	
	EXEC sp_RENAME ''RepOutSubDispositions.userName'', ''user'', ''COLUMN''
end
'
		EXEC (@sql)


		SET @process = 'CW-2114 Change Name Pivot and GroupBy '
		SET @sql = 'update GroupByReports set columns=''userId|login|min([startInterval]):startInterval|max([endInterval]):endInterval|sum([readyTime]):readyTime|sum([twrapup]):twrapup|sum([tring]):tring|sum([tother]):tother|sum([tnav]):tnav|sum([tCallTransf]):tCallTransf|sum([twbCall]):twbCall'' 
,groupByColumns=''userId|login''
where id=2070

update PivotReports set complementColumns=''date|ACDGroup|agentName|user|area|wg|workgroupId|inboundId|areaId|dispositionId'' where id=3040
update PivotReports set complementColumns=''date|ACDGroup|agentName|user|area|wg|workgroupId|inboundId|areaId'' where id=3120


update PivotReports set complementColumns=''date|inboundId|campaignId|campACDDescription|userId|agentName|user|providerId|provider|dialId|dialType'' where id=4060

update PivotReports set complementColumns=''date|campaign|agentName|user|area|wg'' where id=4100


update TranslatedReports set columns=''agentName|user|dialType'' where id=4060'
		EXEC (@sql)

		SET @process = 'CW-2114 Alter SP ccspRepInCallsDetail'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
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

	INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5)
	SELECT cal_inicio, cal_id, Inbound_id, '''' AS Inbound, statusCall_id, '''' AS statusCall, calif_id, '''' AS calif, isnull(califSub_id, 0), '''' AS califSub, dni_id, '''' AS dni, user_id, '''' AS agentName, isnull(cal_key, ''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''', CASE 
			WHEN a.cal_whoHung = 0
				THEN ''systemTranslated_Client''
			WHEN a.cal_whoHung = 1
				THEN ''systemTranslated_Agent''
			ELSE ''systemTranslated_AgentSurvey''
			END [whoHangUp], cal_tMoh, datepart(yyyy, cal_inicio), datepart(mm, cal_inicio), datepart(dd, cal_inicio), datepart(hh, cal_inicio), datepart(mi, cal_inicio), di.provedor_id, prov.descrip [Proveedor], a.cal_puerto, CASE 
			WHEN a.file_moved = 1
				THEN ''systemTranslated_Remoto''
			ELSE ''Local''
			END AS file_Moved, cal_tNotas, AverageHandleTime = cal_tNotas + cal_tDialog, ISNULL(tab.Dato1, '''') AS Dato1, ISNULL(tab.Dato2, '''') AS Dato2, ISNULL(tab.Dato3, '''') AS Dato3, ISNULL(tab.Dato4, '''') AS Dato4, ISNULL(tab.Dato5, '''') AS Dato5
	FROM cccallsin a
	LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
	LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
	LEFT JOIN @tab tab ON tab.callId = a.cal_id
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
END
'
		EXEC (@sql)

		SET @process = 'CW-2114 Alter SP ccspRepInDispositions'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInDispositions WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInDispositions
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, '''' AS ACDGroup, dispositionId, '''' AS DispName, '''', count(dispositionId) DispAmount, user_id, '''' AS LOGIN, '''' AS username, IDArea, '''' AS areaName, 1 AS wgId, ''systemTranslated_WorkGroup'' AS wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)), datepart(dd, max(dateHour)), datepart(hh, max(dateHour)), 0
	FROM (
		SELECT a.cal_inicio AS dateHour, a.Inbound_id, a.calif_id AS dispositionId, user_id, b.IDArea
		FROM cccallsin a
		LEFT JOIN ccInbound b ON b.Inbound_id = a.Inbound_id
		WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 --Constestada
			AND b.IDArea IS NOT NULL
		
		UNION
		
		SELECT requestDate, a.inboundId, a.disposition, a.userId, b.IDArea
		FROM ccRIAChats a
		LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
		WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
			AND b.IDArea IS NOT NULL
		) AS x
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, dispositionId, user_id, IDArea

	UPDATE a
	SET acdGroup = isnull(descripcion, '''')
	FROM RepInDispositions a
	LEFT JOIN ccInbound b ON a.inboundId = b.Inbound_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET disposition = isnull(description, ''systemTranslated_Dispositionless''), disposition_count = isnull(description, ''systemTranslated_Dispositionless'') + ''_Count''
	FROM RepInDispositions a
	LEFT JOIN cctipocalif b ON a.dispositionId = b.calif_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET [user] = isnull(LOGIN, '''')
	FROM RepInDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''')
	FROM RepInDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET area = isnull(AreaName, '''')
	FROM RepInDispositions a
	LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
	WHERE [date] >= @from AND [date] < @to
END
'
		EXEC (@sql)

		SET @process = 'CW-2114 Alter SP ccspRepInSubDispositions'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInSubDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInSubDispositions WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInSubDispositions
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, '''' AS ACDGroup, subDispositionId, '''' AS DispName, '''', count(dispositionId) DispAmount, user_id, '''' AS LOGIN, '''' AS username, IDArea, '''' AS areaName, 1 AS wgId, ''systemTranslated_WorkGroup'' AS wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)), datepart(dd, max(dateHour)), datepart(hh, max(dateHour)), 0
	FROM (
		SELECT cal_inicio AS dateHour, a.Inbound_id, isnull(a.califSub_id, 0) AS subDispositionId, calif_id AS dispositionId, user_id, b.IDArea
		FROM cccallsin a
		LEFT JOIN ccInbound b ON b.Inbound_id = a.Inbound_id
		WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 AND b.IDArea IS NOT NULL
		
		UNION
		
		SELECT requestDate, a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
		FROM ccRIAChats a
		LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
		WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
			AND b.IDArea IS NOT NULL
		) AS x
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, subDispositionId, user_id, IDArea

	UPDATE a
	SET acdGroup = isnull(descripcion, '''')
	FROM RepInSubDispositions a
	LEFT JOIN ccInbound b ON a.inboundId = b.Inbound_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET subDisposition = isnull(califSubDesc, ''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc, ''systemTranslated_Dispositionless'') + ''_Count''
	FROM RepInSubDispositions a
	LEFT JOIN cctipocalifsub b ON a.subDispositionId = b.califSub_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET [user] = isnull(LOGIN, '''')
	FROM RepInSubDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''')
	FROM RepInSubDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET area = isnull(AreaName, '''')
	FROM RepInSubDispositions a
	LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
	WHERE [date] >= @from AND [date] < @to
END
'
		EXEC (@sql)

		SET @process = 'CW-2114 Alter SP ccspRepOutSubDispositions'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSubDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepOutSubDispositions WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepOutSubDispositions
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121) AS dateHour, a.cam_id, '''' AS Campaign, isnull(a.califSub_id, 0), '''' AS DispName, '''', count(calif_id) DispAmount, user_id, '''' AS LOGIN, '''' AS username, b.IDArea, '''' AS areaName, 1 AS wgId, ''systemTranslated_WorkGroup'' AS wg, datepart(yyyy, max(cal_inicio)) AS year, datepart(mm, max(cal_inicio)), datepart(dd, max(cal_inicio)), datepart(hh, max(cal_inicio)), datepart(mi, max(cal_inicio))
	FROM ccocallsout a(NOLOCK)
	LEFT JOIN ccCamps b ON b.cam_Id = a.cam_id
	WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 AND cal_manual IN (0, 2) AND b.IDArea IS NOT NULL
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121), a.cam_id, a.califSub_id, user_id, b.IDArea

	UPDATE a
	SET campaign = isnull(cam_descripcion, '''')
	FROM RepOutSubDispositions a
	LEFT JOIN ccCamps b ON a.campaignId = b.cam_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET subDisposition = isnull(califSubDesc, ''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc, ''systemTranslated_Dispositionless'') + ''_Count''
	FROM RepOutSubDispositions a
	LEFT JOIN cctipocalifsubout b ON a.subDispositionId = b.califSub_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET [user] = isnull(LOGIN, '''')
	FROM RepOutSubDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''')
	FROM RepOutSubDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET area = isnull(AreaName, '''')
	FROM RepOutSubDispositions a
	LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
	WHERE [date] >= @from AND [date] < @to
END
'
		EXEC (@sql)
		
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
