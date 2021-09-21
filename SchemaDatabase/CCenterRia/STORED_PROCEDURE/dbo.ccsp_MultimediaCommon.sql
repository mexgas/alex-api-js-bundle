CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon] 
		@Option AS SMALLINT, 
		@inboundId AS SMALLINT = 0, 
		@conversationId AS INT = 0, 
		@ServiceType AS SMALLINT = 0,
		@status as SMALLINT =0
		AS
		BEGIN
		    SET NOCOUNT ON;

		    IF(@Option = 1)
				BEGIN

					 SELECT --inbound.chat AS ServiceType,
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
				END      

			IF(@Option = 2)
				BEGIN
					SELECT 
						cast(i.chat as int) AS ServiceType,
						cast(c.conversationId as int) as ConversationID,
						c.clientId as ClientId,
						cm.conexionInfo as [To],
						cast(i.Inbound_id as int) as ACDId,
						i.descripcion as ACDName,
						cast(g.graphic_id as int) as ACDGraphicId,
						cast(cm.closeConversationTime as int) as [TimeOut],
						cast(cm.answerTimeOut as int) as [TimeOutWarning],
						i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
						i.tNotas as [WrapUpTime]
					FROM  ccInbound i
						INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
						INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
						INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
					WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
				END
			IF(@Option = 3)
				BEGIN
					 SELECT 
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
				END   	
		END