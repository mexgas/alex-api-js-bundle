USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepOutSMSAnswDetailByCamp]    Script Date: 25/03/2026 12:36:57 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ccspRepOutSMSAnswDetailByCamp] 
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
    FROM RepOutSMSAnswDetailByCamp WITH (ROWLOCK)
    WHERE date >= @from AND date < @to

    INSERT INTO RepOutSMSAnswDetailByCamp
    SELECT smsDate date, cam.cam_id camId, cam_descripcion campaignName,isnull(smslog.Message,src.message) message, phone senderNumber, cam.cam_id campaignId
    FROM smsccoLogDial smslog (nolock)
        LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
        LEFT JOIN smsoutSourceMessage src on src.smsout_id=smslog.smsout_id
    WHERE smsDate >= @from AND smsDate < @to
END
