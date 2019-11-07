CREATE PROCEDURE [dbo].[ccsp_AvrsSyncronization] 
			@action SMALLINT, 
			@maxRecordsToTransfer INT = 10, 
			@id INT = 0
			AS
			SET NOCOUNT ON

			IF @action = 1
			BEGIN
				DECLARE @countrId INT

				SET @countrId = 1

				SELECT @countrId = valor
				FROM ccSettings
				WHERE setting_id = 104
				

				SELECT TOP (@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone, 
				cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, 0 AS cal_manual, cal_puerto, call.dni_id, fvalida, 
				cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
				CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
				dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo, 1 AS isCallRecord,isnull(dni.dni_numero,'') as DNIS
				FROM ccCallsIn AS call
				INNER JOIN ccInbound ON ccInbound.Inbound_id = call.Inbound_id
				INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 0
				LEFT JOIN ccDNIS dni on dni.dni_id=call.dni_id
				LEFT JOIN (
					SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
					FROM ccLogTransfers
					WHERE tipo = 1
					GROUP BY cal_id, tipo
					) trans ON call.cal_id = trans.cal_id
				
				UNION
				
				SELECT TOP (@maxRecordsToTransfer) call.cal_id AS CallId, user_id AS UserId, call.cam_id AS camAcdId, cast(call.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, 
				cal_inicio, cal_telefono, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, 
				cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
				CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
				dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo, dbo.EnableCallRecord(camps.call_record, @countrId, cal_telefono) AS isCallRecord, '' as DNIS
				FROM ccoCallsOut AS call
				INNER JOIN ccCamps camps ON camps.cam_id = call.cam_id
				INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 1
				LEFT JOIN (
					SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
					FROM ccLogTransfers
					WHERE tipo = 2
					GROUP BY cal_id, tipo
					) trans ON call.cal_id = trans.cal_id
			END
			ELSE IF @action = 2
			BEGIN
				DELETE
				FROM ccAVRSTransfer
				WHERE id = @id
			END