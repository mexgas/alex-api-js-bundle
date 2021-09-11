CREATE PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          SMALLINT    = 0
                                              , @tWrapUp            SMALLINT    = 0
                                              , @finishedBy         TINYINT     = 0
                                              , @onQueue            BIT         = NULL
                                              , @tQueue             SMALLINT    = 0
                                              , @tTimeout           INT         = 0
                                              , @disposition        SMALLINT    = 0
                                              , @subDisposition     SMALLINT    = 0
                                              , @agentId            INT         = 0
											  --VAR MESSAGES
											  , @messageId          VARCHAR(50) = NULL
											  , @messageIdUi        INT			= NULL
											  , @clientNum			VARCHAR(15) = NULL
											  , @vonageNum			VARCHAR(15) = NULL
											  , @typeMessage		VARCHAR(25) = ''
											  , @content			VARCHAR(MAX)= NULL
											  , @timeStampMessage   DATETIME	= NULL
											  , @timeStampMessageUTC DATETIME	= NULL
											  , @originType         VARCHAR(15) = NULL
											  , @currency			VARCHAR(10) = NULL
											  ,	@price				VARCHAR(10) = NULL
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;

    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
                      (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
                       WHERE A.conversationId = @conversationId
                      )
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
           , phoneACD
           , clientId
           , conversationStatus
           , tChatting
           , tWrapUp
           , finishedBy
           , onQueue
           , tQueue
           , tTimeout
           , disposition
           , subDisposition
           , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
            SELECT @conversationId = SCOPE_IDENTITY();
            SELECT @conversationId AS ConversationId;
            RETURN(0);
        END;
        ELSE
        BEGIN
            SELECT 0 AS ConversationId;
            RETURN(0);
        END;
    END;

    IF @action = 2
    BEGIN --save conversation Times
        UPDATE ccWhatsAppConversations
               SET
                   tChatting = DATEDIFF(ss, conversationDate, GETDATE())
                 , conversationStatus = @conversationStatus
                 , finishedBy = case when @conversationStatus = 10 then 2 else 1 end
                 , tConversation = DATEDIFF(ss, requestDate, GETDATE())
				 ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
				 ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
        WHERE conversationId = @conversationId;


		exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=5

    END;

    IF @action = 3
    BEGIN --save conversation Status
        UPDATE ccWhatsAppConversations
               SET
                   conversationDate = GETDATE()
                 , conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
    END;

	IF @action = 4 BEGIN --save messages from conversation
		IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWAMessagesConversations](
												messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price) values 
											   (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price)
			SELECT @messageId=SCOPE_IDENTITY()
			SELECT @messageId as MessageId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS MessageId
			RETURN (0)
		END
	END;

	IF @action = 5
    BEGIN --save onQueue 
        UPDATE ccWhatsAppConversations
               SET onQueue = 1
        WHERE conversationId = @conversationId;
    END;

	IF @action = 6
    BEGIN --save agent, assigdate and tqueue
        UPDATE ccWhatsAppConversations
               SET agentId = @agentId,
			   assignDate = getdate(),
			   conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;

		UPDATE ccWhatsAppConversations
               SET tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;
    END;
END;