CREATE PROCEDURE [dbo].[ccsp_MultimediaConfigurations] 
					@Option AS SMALLINT,
					@ServiceType AS SMALLINT = 0
					AS
					BEGIN
					    SET NOCOUNT ON;
						BEGIN
					    IF(@Option = 1) -- Get Vonage Configurations depending the Service Type 
							BEGIN
								SELECT applicationId AS ApplicationId,
									   secretKey AS SecretKey,
									   messagesUrl AS MessagesUrl
								FROM ccVonageConfigurations
								WHERE serviceType = @ServiceType   -- 5 = WhatsApp
							END 

						IF(@Option = 2) -- Get WhatsApp registered numbers 
							BEGIN
								SELECT number AS AvailableNumbers FROM ccWhatsAppNumbers Numbers 
								INNER JOIN ccVonageConfigurations Configurations 
								ON Numbers.vonageId = Configurations.vonageId 
								AND Numbers.inboundId = 0 
								AND Numbers.status = 1 
								AND Configurations.serviceType = 5
							END 
						END
					END