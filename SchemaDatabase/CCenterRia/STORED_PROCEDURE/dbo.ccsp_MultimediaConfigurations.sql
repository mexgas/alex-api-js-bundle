CREATE PROCEDURE [dbo].[ccsp_MultimediaConfigurations] 
				@Option AS SMALLINT,
				@ServiceType AS SMALLINT = 0,
				@Number AS VARCHAR(25) = ''
				AS
				BEGIN
				    SET NOCOUNT ON;
					BEGIN
				    IF(@Option = 1) -- Get Vonage Configurations depending the Service Type and number 
						BEGIN
							SELECT config.applicationId AS ApplicationId,
								   config.secretKey AS SecretKey,
								   config.messagesUrl AS MessagesUrl
							FROM ccVonageConfigurations config
							INNER JOIN ccWhatsAppNumbers numbers ON config.vonageId = numbers.vonageId 
							AND numbers.number = @Number 
							AND config.serviceType = @ServiceType   -- 5 = WhatsApp
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