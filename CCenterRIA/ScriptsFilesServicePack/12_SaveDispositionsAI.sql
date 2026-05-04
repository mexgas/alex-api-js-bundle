USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[SaveDispositionsAI]    Script Date: 2/18/2026 9:22:44 AM ******/
-- Se agregó el action 5 para obtener la transcripción de la llamada de IA y el option 6
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SaveDispositionsAI]
@action        smallint    = NULL,
@call_Id       int         = NULL,
@Qualification varchar(MAX)= NULL,
@result        varchar(MAX)= NULL,
@Observations  varchar(MAX)= NULL,
@CallbackAT    DATETIME = NULL,
@Transcription varchar(MAX)= NULL,
@CamType       bit         = 0,
@disposition_Id SMALLINT = null,
@CapturedData varchar(max) = null
AS
BEGIN
	SET NOCOUNT ON;
	--Variables para devolución de llamada 
	DECLARE @cal_key varchar(40) ='';
	DECLARE @cam_id smallint;
	DECLARE @cal_telefono varchar(19);
	DECLARE @inbound_id smallint = NULL;
	DECLARE @CanReprogram smallint  = null

	-- Validacion del Status del Setting 289
	DECLARE @trans_status BIT = NULL;
	
	DECLARE @valor  NVARCHAR(15) = NULL;

	SELECT @valor = TRY_CAST(valor AS NVARCHAR(15))	
	FROM ccSettings2
	WHERE setting_id = 289;

	DECLARE @status NVARCHAR(5);
	DECLARE @sep    INT;

	SET @sep = CHARINDEX('|', ISNULL(@valor, ''));
	SET @status = CASE
					WHEN @sep > 0 THEN SUBSTRING(@valor, 1, @sep - 1)
					ELSE ISNULL(@valor, '')
				  END;

	IF @action = 1  -- Outbound
	BEGIN
		IF EXISTS (SELECT 1 FROM ccoCallsOutDispositionIA WHERE call_id = @call_Id)
        BEGIN
            UPDATE ccoCallsOutDispositionIA
            SET Qualification = @Qualification,
                result = @result,
                Observations = @Observations,
				CapturedData = @CapturedData
            WHERE call_id = @call_Id;
        END
        ELSE
        BEGIN
            INSERT INTO ccoCallsOutDispositionIA (call_id, Qualification, result, Observations,CapturedData)
            VALUES (@call_Id, @Qualification, @result, @Observations,@CapturedData);
        END

		IF EXISTS (SELECT 1 FROM ccTipoCalif WHERE calif_id = @disposition_Id)
		BEGIN
			UPDATE dbo.ccoCallsOut 
			SET calif_id = @disposition_Id
			WHERE cal_id = @call_Id;
		END
	END

	ELSE IF @action = 2 AND @status = '1'   -- Outbound
	BEGIN
		--Se deja pendiente para el siguiente Sprint 
		--DECLARE @cam_id smallint = NULL;

		--Select @cam_id = cam_id 
		--From ccoCallsOut
		--Where cal_id = @call_Id

		--Select @trans_status = IsCallTranscriptionEnabled
		--From ccCampsExtend
		--Where cam_id  = @cam_id

		--IF @trans_status = 1
		--BEGIN
		--	INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
		--	VALUES (@call_Id, @Transcription);
		--END

		IF EXISTS (SELECT 1 FROM ccoCallsOutTranscriptionIA WHERE call_id = @call_Id)
        BEGIN
            UPDATE ccoCallsOutTranscriptionIA
            SET Transcription = @Transcription
            WHERE call_id = @call_Id;
        END
        ELSE
        BEGIN
            INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
            VALUES (@call_Id, @Transcription);
        END
	END

	ELSE IF @action = 3  -- Inbound
	BEGIN
		Select @CanReprogram = CanReprogram from ccTipoCalif where calif_id = @disposition_Id
		
		IF (@CallbackAT IS NOT NULL  
			AND CONVERT(datetime, @CallbackAT, 120) IS NOT NULL 
			AND CONVERT(datetime, @CallbackAT, 120) > GETDATE()  
			AND @CanReprogram <> 0)
		BEGIN
			INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations, CallbackAT,disposition_id,CapturedData)
			VALUES (@call_Id, @Qualification, @result, @Observations,@CallbackAT,@disposition_Id,@CapturedData);

			SELECT @inbound_id = Inbound_id, @cal_telefono = cal_ANI
				FROM ccCallsIn 
				WHERE cal_id = @call_Id;

			SELECT @cam_id = cam_id
				FROM ccInbound
				WHERE Inbound_id  = @inbound_id

			EXEC ccsp_INInsertaCallBack
				@cal_key = @call_Id,
				@cam_id = @cam_id,
				@cal_telefono = @cal_telefono,
				@fechadial = @CallbackAT,
				@dato4 = @result,
				@dato5 = @Observations

			IF EXISTS (SELECT 1 FROM ccTipoCalif WHERE calif_id = @disposition_Id)
			BEGIN
				UPDATE ccCallsIn
				SET calif_id = @disposition_Id
				WHERE cal_id = @call_Id;
			END
		END

		ELSE BEGIN
			INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations,disposition_id,CapturedData)
			VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id,@CapturedData);

			IF EXISTS (SELECT 1 FROM ccTipoCalif WHERE calif_id = @disposition_Id)
			BEGIN
				UPDATE ccCallsIn
				SET calif_id = @disposition_Id
				WHERE cal_id = @call_Id;
			END
		END

	END

	ELSE IF @action = 4 AND @status = '1'   -- Inbound
	BEGIN
		
		Select @inbound_id = Inbound_id 
			From ccCallsIn 
			Where cal_id = @call_Id
		
		Select @trans_status = IsCallTranscriptionEnabled
			From ccInboundExtend
			Where Inbound_id  = @inbound_id

		IF @trans_status = 1
		BEGIN
			INSERT INTO ccCallsInTranscriptionIA (call_id, Transcription)
			VALUES (@call_Id, @Transcription);
		END
	END
	ELSE IF @action = 5 -- Get ia call transcription by callId
	BEGIN
		IF(@CamType = 1)
		BEGIN
			SELECT ccoti.call_id AS CallId ,
                   ccoti.Transcription,
				   ISNULL(ccodi.disposition_id, 0) AS DispositionID ,
				   ISNULL(ccodi.Qualification, '') AS Qualification 
				   FROM dbo.ccoCallsOutTranscriptionIA AS ccoti
				   INNER JOIN dbo.ccoCallsOutDispositionIA AS ccodi
				   ON ccodi.call_id = ccoti.call_id
			WHERE ccoti.call_id = @call_Id
		END
		ELSE
		BEGIN
			SELECT cciti.call_id AS CallId,
                   cciti.Transcription,
				   ISNULL(ccidi.disposition_id, 0) AS DispositionID ,
				   ISNULL(ccidi.Qualification, '') AS Qualification 
				   FROM dbo.ccCallsInTranscriptionIA AS cciti
				   INNER JOIN dbo.ccCallsInDispositionIA AS ccidi
				   ON ccidi.call_id = cciti.call_id
			WHERE cciti.call_id = @call_Id
		END

	END
	ELSE IF @action = 6 -- Get IA Call Model by call_id
	BEGIN
		IF(@CamType = 1)
		BEGIN
			SELECT cva.idAgent AS IdAgent, cva.nameAgent AS NameAgent FROM dbo.ccoCallsOut AS cco
			INNER JOIN dbo.ccVirtualAgent AS cva
			ON cco.virtualAgentId = cva.idAgent
			WHERE cco.cal_id = @call_Id
		END

	END

END