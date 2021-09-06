CREATE PROCEDURE [dbo].[ccsp_ConversationWASave]

	@action int,
	@conversationId int=0,
	@inboundId smallint=null,
	@phoneACD varchar(50)= null,
	@clientId varchar(25)= null,
	@conversationStatus smallint=0,
	@tChatting smallint=0,
	@tWrapUp smallint=0,
	@finishedBy tinyint = 0,
	@onQueue bit = null,
	@tQueue smallint = 0,
	@tTimeout int = 0,
	@disposition smallint=0,
	@subDisposition smallint=0,
	@agentId int = 0

AS
BEGIN
	DECLARE @isEndConversation bit
	DECLARE @meanContactTypeId smallint

	SET @meanContactTypeId = 1
SET NOCOUNT ON;

	IF @action = 1 BEGIN --new Conversation
		IF NOT EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWhatsAppConversations](
												inboundId, phoneACD, clientId, conversationStatus, tChatting, 
												tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition,agentId) values 
											   (@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, 
												@tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition,@agentId)
			SELECT @conversationId=SCOPE_IDENTITY()
			SELECT @conversationId as ConversationId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS ConversationId
			RETURN (0)
		END
	END

	IF @action = 2 BEGIN --save conversation Times
		Update ccWhatsAppConversations 
		set tChatting = DATEDIFF(ss,conversationDate,getdate()), 
			conversationStatus = @conversationStatus, finishedBy = 1,
			tConversation = DATEDIFF(ss,requestDate,getdate()) 
		where conversationId = @conversationId  
	END
	
	IF @action = 3 BEGIN --save conversation Status
		Update ccWhatsAppConversations 
		set conversationDate = getdate(),
			conversationStatus = @conversationStatus
		where conversationId = @conversationId  
	END
END