CREATE procedure  [dbo].[ccsp_UpdateACDWhatsappConfig]

					@ConexionInfo varchar(400),
					@inbound_id int,
					@ConnUser varchar(60),
					@tNotas int,
					@closeConversationTime tinyint,
					@ShowCalifWnd bit 

					AS
					set nocount on
					    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
					    BEGIN
					        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime where inboundId = @inbound_id;
							UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
					    END;

					    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
					    BEGIN
					        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd where Inbound_id = @inbound_id;
					    END;
					SELECT @inbound_id;
					return(@inbound_id)

					set nocount off