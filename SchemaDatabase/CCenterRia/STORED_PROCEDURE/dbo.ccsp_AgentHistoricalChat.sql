CREATE PROCEDURE [dbo].[ccsp_AgentHistoricalChat]
	@option SMALLINT,
	@clientNum VARCHAR(15) = ''
    AS
    BEGIN
        IF @option = 1 --whatsapp, get conversation ids
        BEGIN
            SELECT conversationId FROM [CCenterRia].[dbo].[ccWhatsAppConversations] WHERE clientId = @clientNum GROUP BY conversationId
        END
    END