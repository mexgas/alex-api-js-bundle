USE CCenterRIA
GO
ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
				@Action INT,
				@CampId INT = NULL,
				@AgentId INT = NULL,
				@CampType INT = NULL,
				@VoiceId INT = NULL
		AS
		BEGIN
			DECLARE @Inbound INT = 0, @Outbound INT = 1
			IF @Action = 1 --Get API Data
			BEGIN
				DECLARE @key VARCHAR(255)
				SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
				SELECT valor AS ApiUrl, @key AS [Key] FROM ccSettings2 WHERE setting_id = 290
			END
			IF @Action = 2 --Get Quantum Id Agent Data
			BEGIN
				SELECT quantumAgentId
				FROM ccVirtualAgent
				WHERE 
					(@AgentId IS NOT NULL AND idAgent = @AgentId)
					OR (@AgentId IS NULL AND campType = @CampType AND idCampaign = @CampId);
			END
			IF @Action = 3 --Get Quantum Dispositions by camp
			BEGIN
				SELECT 
					cci.calif_id AS [Id],
				cci.Description_cal AS [Description],
				CAST(CASE WHEN cci.CanReprogram = 1 OR cci.autoCallback = 1 THEN 1 ELSE 0 END AS INT) AS Callback,
				CAST(CASE 
				WHEN cci.TransferOpcion = 1 THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0 END  AS INT) AS Fallback,
				CAST(CASE 
				WHEN cci.TransferOpcion = 2  THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0  END AS INT) AS Success,
				CAST(CASE 
				WHEN cci.TransferOpcion = 3 THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0 END AS INT) AS Ivr,
				cci.ExtDescription AS RequiredData
				FROM dbo.ccCalifCampIA AS ccci INNER JOIN dbo.cctipoCalif_IA AS cci
				ON cci.calif_id = ccci.calif_id
				WHERE ccci.tipo = @CampType
				AND ccci.cam_id = @CampId
			END
			IF @Action = 4 -- Get Quantum Agent Voice Id
			BEGIN
				SELECT ISNULL(
					(SELECT QuantumVoiceId 
					 FROM ccVirtualAgentVoices 
					 WHERE ID = @VoiceId), 
					''
				) AS QuantumVoiceId;
			END

			IF @Action = 5 -- Get Transfer Status 
			BEGIN
				IF @CampType = 0
				BEGIN
					SELECT 
						 CASE 
						-- 1. If both transfer options are disabled (0), return FALSE (0).
						WHEN ISNULL(cie.TransferToHumanAgents, 0) = 0 
							 AND ISNULL(cie.TransferOnSuccessfulHandling, 0) = 0 THEN CAST(0 AS BIT)

						-- 2. LOGICAL VALIDATION:
						-- Ensure that all active configurations are valid and have no missing requirements.
						WHEN 
							(
								-- Validate 'TransferToHumanAgents' integrity
								CASE 
									WHEN cie.TransferToHumanAgents = 2 THEN 1 -- Valid: External transfer
									WHEN cie.TransferToHumanAgents = 1 AND ISNULL(ci2.idForNonComprehension, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
									WHEN cie.TransferToHumanAgents = 0 THEN 1 -- Valid: Option is disabled, skip validation
									ELSE 0 -- Invalid: Option enabled but missing target campaign ID
								END = 1
							)
							AND -- ALL enabled configurations must be valid simultaneously
							(
								-- Validate 'TransferOnSuccessfulHandling' integrity
								CASE 
									WHEN cie.TransferOnSuccessfulHandling = 2 THEN 1 -- Valid: External transfer
									WHEN cie.TransferOnSuccessfulHandling = 1 AND ISNULL(ci2.idForSuccessfulTransaction, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
									WHEN cie.TransferOnSuccessfulHandling = 0 THEN 1 -- Valid: Option is disabled, skip validation
									ELSE 0 -- Invalid: Option enabled but missing target campaign ID
								END = 1
							)
							THEN CAST(1 AS BIT)

						ELSE CAST(0 AS BIT)
					END
					FROM dbo.ccInboundExtend AS cie
					INNER JOIN dbo.ccInbound AS ci2
					ON ci2.Inbound_id = cie.Inbound_id
					WHERE cie.Inbound_id= @CampId;
				END
				ELSE
				BEGIN
					SELECT 
					CASE 
						WHEN EXISTS (SELECT 1 FROM dbo.ccInbound WHERE cam_id = @CampId) 
						THEN CAST(1 AS BIT) 
						ELSE CAST(0 AS BIT) 
					END AS ExisteCampana;
				END
			END

			IF @Action = 6 -- Agent Id By Campaign 
			BEGIN
				IF(@CampType = 0)
				BEGIN
				
					SELECT ISNULL(
						(SELECT TOP 1 idAgent 
						 FROM ccVirtualAgent 
						 WHERE idCampaign = @CampId 
						   AND mediaType = 11
						   AND campType = 0),
						0
					) AS idAgent;
				END
				ELSE
				BEGIN
					SELECT ISNULL(
							(SELECT TOP 1 idAgent 
							 FROM ccVirtualAgent 
							 WHERE idCampaign = @CampId 
							   AND mediaType = 10 AND campType = 1),
							0
						) AS idAgent;
				END
			END
		END