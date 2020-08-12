CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
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
			SELECT cal_inicio, a.cal_id, Inbound_id, '' AS Inbound, statusCall_id, '' AS statusCall, a.calif_id, '' AS calif, isnull(a.califSub_id, 0), '' AS califSub, a.dni_id, '' AS dni, user_id, '' AS agentName, isnull(a.cal_key, ''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, a.cal_extension, '', CASE 
					WHEN a.cal_whoHung = 0
						THEN 'systemTranslated_Client'
					WHEN a.cal_whoHung = 1
						THEN 'systemTranslated_Agent'
					ELSE 'systemTranslated_AgentSurvey'
					END [whoHangUp], a.cal_tMoh, datepart(yyyy, cal_inicio), datepart(mm, cal_inicio), datepart(dd, cal_inicio), datepart(hh, cal_inicio), datepart(mi, cal_inicio), di.provedor_id, prov.descrip [Proveedor], a.cal_puerto, CASE 
					WHEN a.file_moved = 1
						THEN 'systemTranslated_Remoto'
					ELSE 'Local'
					END AS file_Moved, cal_tNotas, AverageHandleTime = cal_tNotas + cal_tDialog, ISNULL(tab.Dato1, '') AS Dato1, ISNULL(tab.Dato2, '') AS Dato2, ISNULL(tab.Dato3, '') AS Dato3, ISNULL(tab.Dato4, '') AS Dato4, ISNULL(tab.Dato5, '') AS Dato5,
					ISNULL(rc.cal_id, 0) AS grabId
			FROM cccallsin a
			LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
			LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
			LEFT JOIN @tab tab ON tab.callId = a.cal_id
			LEFT JOIN Ria_grabacion rc on rc.cal_id = a.cal_id 
			WHERE cal_inicio >= @from AND cal_inicio < @to

			UPDATE a
			SET acdGroup = isnull(descripcion, '')
			FROM RepInCallsDetail a
			LEFT JOIN ccInbound b ON a.inboundId = b.Inbound_id
			WHERE [date] >= @from AND [date] < @to

			UPDATE a
			SET callStatus = isnull(descripcion, '')
			FROM RepInCallsDetail a
			LEFT JOIN ccstatusllamada b ON a.callStatusId = b.statusCall_id
			WHERE [date] >= @from AND [date] < @to

			UPDATE a
			SET disposition = isnull(description, '')
			FROM RepInCallsDetail a
			LEFT JOIN cctipocalif b ON a.dispositionId = b.calif_id
			WHERE [date] >= @from AND [date] < @to

			UPDATE a
			SET subDisposition = isnull(califSubDesc, '')
			FROM RepInCallsDetail a
			LEFT JOIN cctipocalifsub b ON a.subDispositionId = b.califSub_id
			WHERE [date] >= @from AND [date] < @to

			UPDATE a
			SET dnis = isnull(dni_numero, '')
			FROM RepInCallsDetail a
			LEFT JOIN ccdnis b ON a.dnisId = b.dni_id
			WHERE [date] >= @from AND [date] < @to

			UPDATE a
			SET [user] = isnull(LOGIN, ''), agentName = isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, '')
			FROM RepInCallsDetail a
			LEFT JOIN ccUserView b ON a.userId = b.user_id
			WHERE [date] >= @from AND [date] < @to
		END