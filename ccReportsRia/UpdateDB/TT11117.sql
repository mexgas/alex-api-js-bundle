SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 120

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


	------------------------ BEGIN MARCO GARCIA TT11117-NuxibaEngine-Regitros de llamada en 0 --------------------
	set @process = 'TT11117-NuxibaEngine-Regitros de llamada en 0 drop sp ccspRepInCallsDetail'
	set @sql='
	if exists(select * from sys.procedures where name = ''ccspRepInCallsDetail'')
	begin
		DROP PROCEDURE ccspRepInCallsDetail
	end'
	EXEC(@sql)

	SET @process = 'TT11117-NuxibaEngine-Regitros de llamada en 0 create sp ccspRepInCallsDetail'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
		AS

		SET NOCOUNT ON

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN

			DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))
			DECLARE @fechaSUM DATETIME
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
			WHERE [date] >= @from AND [date] < @to

			
			INSERT INTO RepInCallsDetail (DATE,
 callid,
 inboundId,
 ACDGroup,
 callStatusId,
 callStatus,
 dispositionId,
 disposition,
 subDispositionId,
 subDisposition,
 dnisId,
 dnis,
 userId,
 [user],
 callKey,
 ANI,
 queueTime,
 xferTime,
 ringingTime,
 dialogTime,
 extension,
 agentName,
 whoHangUp,
 mohTime,
 year,
 month,
 day,
 hour,
 minutes,
 provedorId,
 provider,
 trunk,
 fileMoved,
 twrapup,
 AverageHandleTime,
 Dato1,
 Dato2,
 Dato3,
 Dato4,
 Dato5,
 grabId,
 nameDNI,
 numDNI,
 collectCall,
 timeTotalInCallSec,
 timeTotalInCallMin,
 statusCallByIVR,
 IVR_ID,
 callHung,
 recibeCallBy,
 cal_final)
			SELECT 
			   a.cal_inicio AS cal_ini, 
			   a.cal_id,
			   a.Inbound_id,
			   ISNULL(ccIn.descripcion, '''') AS Inbound, 
			   a.statusCall_id, 
			   ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
			   a.calif_id, 
			   ISNULL(disposition.description, '''') AS calif, 
			   ISNULL(a.califSub_id, 0), 
			   ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
			   a.dni_id, 
			   ISNULL(dnis.dni_numero, '''') AS dni, 
			   a.user_id, 
			   ISNULL(LOGIN, '''') AS [user], 
			   ISNULL(a.cal_key, '''') as cal_key, 
			   a.cal_ANI, 
			   cal_tWait, 
			   cal_tXfer, 
			   cal_tRing, 
			   cal_tDialog, 
			   a.cal_extension, 
			   ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
			   CASE
				   WHEN a.cal_whoHung = 0
				   THEN ''systemTranslated_Client''
				   WHEN a.cal_whoHung = 1
				   THEN ''systemTranslated_Agent''
				   ELSE ''systemTranslated_AgentSurvey''
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
			WHEN a.file_moved = 1 THEN ''systemTranslated_Remoto''
			WHEN a.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
				   ELSE ''Local''
			   END AS file_Moved, 
			   cal_tNotas, 
			   AverageHandleTime = cal_tNotas + cal_tDialog, 
			   ISNULL(tab.Dato1, '''') AS Dato1, 
			   ISNULL(tab.Dato2, '''') AS Dato2, 
			   ISNULL(tab.Dato3, '''') AS Dato3, 
			   ISNULL(tab.Dato4, '''') AS Dato4, 
			   ISNULL(tab.Dato5, '''') AS Dato5, 
			   ISNULL(rc.grab_id, 0) AS grabId,
			   ISNULL(dni_Descripcion, '''') AS nameDNI,
			   ISNULL(dnis.dni_numero, '''') AS dni,
			   CASE
					 WHEN statusLlamada.descripcion IS NOT NULL THEN ''Si''
					 ELSE ''No''
			   END AS collectCall,
			   CASE
					WHEN A.cal_final IS NULL THEN CAST( (cal_tDialog + cal_tXfer + cal_tWait + cal_tRing) AS INT)
			   ELSE CAST( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) AS INT)
			   END AS timeTotalInCallSec,
			   CASE
					WHEN A.cal_final IS NULL THEN CAST(FLOOR( ( cal_tDialog + cal_tXfer + cal_tWait  + cal_tRing  ) / 60) AS INT)
					ELSE CAST( FLOOR( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) / 60 ) AS INT) 
			   END + 
			   CASE
					WHEN A.cal_final IS NULL THEN 
						CASE 
							WHEN CEILING(CAST( (cal_tDialog + cal_tXfer  + cal_tWait  + cal_tRing) AS INT  ) % 60) != 0 THEN 1 
							ELSE 0
						END
					ELSE
						CASE
							WHEN CAST(CEILING( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) ) AS INT) % 60 != 0 THEN 1
							ELSE 0
						END
			   END AS timeTotalInCallMin,
			   CASE 
					WHEN a.IVR_id != 0 and ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_AbandonedInIVR''
					WHEN a.statusCall_id = 13 THEN ''systemTranslated_Answered''
					WHEN a.statusCall_id != 13 THEN ''''
					ELSE ''''
				END AS statusCallByIVR,
				ISNULL(ivrCIN.IVR_ID, 0) AS IVR,
				CASE
					WHEN ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_ClientSystem''
					ELSE ''''
				END AS statusCallByIVR,
				CASE
					WHEN ivrCIN.callid = a.cal_id THEN ''systemTranslated_SystemIVR''
					WHEN a.IVR_id = 0 THEN ''systemTranslated_CallInbound'' 
					ELSE ''''
				END AS [recibeCallBy], 
				ISNULL(a.cal_final, NULL) AS cal_final
		FROM cccallsin A   
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
			 LEFT JOIN repIVRDetail ivrCIN ON a.IVR_id = ivrCIN.IVR_ID 
		WHERE a.cal_inicio >= @from
			  AND a.cal_inicio < @to


		EXEC SupportReportCallInIVR 1, @from, @to

		END'
	EXEC(@sql)


	------------------------ END MARCO GARCIA TT11117-NuxibaEngine-Regitros de llamada en 0 --------------------


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
