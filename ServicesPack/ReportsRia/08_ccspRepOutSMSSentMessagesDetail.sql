USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepOutSMSSentMessagesDetail]    Script Date: 25/03/2026 12:40:49 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

		ALTER PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail] 
		@action as tinyint,
		@from as datetime = NULL,
		@to as datetime = NULL
		AS

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN
			--Borrar lo que esta para no repetir
			DELETE
			FROM RepOutSMSSentMessagesDetail WITH (ROWLOCK)
			WHERE date >= @from AND date < @to

			INSERT INTO RepOutSMSSentMessagesDetail
			SELECT smsout_id, cam_descripcion, phone, smsDate,res.translatedDesc, bill, logId, smslog.cam_id campaignId,smslog.SystemApiId
			FROM smsccoLogDial smslog (nolock)
				LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
				LEFT JOIN ccSMSResult res on res.resultId=smslog.statusSystemsId 
			WHERE smsDate >= @from AND smsDate < @to
		END