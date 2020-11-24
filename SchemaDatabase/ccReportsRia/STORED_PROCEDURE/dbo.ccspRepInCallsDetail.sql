CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

SET NOCOUNT ON

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
	FROM RepInCallsDetail
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId)
	SELECT cal_inicio, 
       a.cal_id, 
       a.Inbound_id,
       ISNULL(ccIn.descripcion, '') AS Inbound, 
       a.statusCall_id, 
       ISNULL(statusLlamada.descripcion, '') AS statusCall, 
       a.calif_id, 
       ISNULL(disposition.description, '') AS calif, 
       ISNULL(a.califSub_id, 0), 
       ISNULL(subDisposition.califSubDesc, '') AS califSub, 
       a.dni_id, 
       ISNULL(dnis.dni_numero, '') AS dni, 
       a.user_id, 
       ISNULL(LOGIN, '') AS [user], 
       ISNULL(a.cal_key, '') as cal_key, 
       cal_ANI, 
       cal_tWait, 
       cal_tXfer, 
       cal_tRing, 
       cal_tDialog, 
       a.cal_extension, 
       ISNULL(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, '') AS agentName,
       CASE
           WHEN a.cal_whoHung = 0
           THEN 'systemTranslated_Client'
           WHEN a.cal_whoHung = 1
           THEN 'systemTranslated_Agent'
           ELSE 'systemTranslated_AgentSurvey'
       END [whoHangUp], 
       a.cal_tMoh, 
       DATEPART(yyyy, cal_inicio) [year], 
       DATEPART(mm, cal_inicio) [month], 
       DATEPART(dd, cal_inicio) [day], 
       DATEPART(hh, cal_inicio) [hour], 
       DATEPART(mi, cal_inicio) [minute], 
       di.provedor_id, 
       prov.descrip [Proveedor], 
       a.cal_puerto,
       CASE
           WHEN a.file_moved = 1
           THEN 'systemTranslated_Remoto'
           ELSE 'Local'
       END AS file_Moved, 
       cal_tNotas, 
       AverageHandleTime = cal_tNotas + cal_tDialog, 
       ISNULL(tab.Dato1, '') AS Dato1, 
       ISNULL(tab.Dato2, '') AS Dato2, 
       ISNULL(tab.Dato3, '') AS Dato3, 
       ISNULL(tab.Dato4, '') AS Dato4, 
       ISNULL(tab.Dato5, '') AS Dato5, 
       ISNULL(rc.cal_id, 0) AS grabId
FROM cccallsin a
     LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
     LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
     LEFT JOIN @tab tab ON tab.callId = a.cal_id
     LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
     LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
     LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
     LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
     LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
     LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
     LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
WHERE cal_inicio >= @from
      AND cal_inicio < @to;

END