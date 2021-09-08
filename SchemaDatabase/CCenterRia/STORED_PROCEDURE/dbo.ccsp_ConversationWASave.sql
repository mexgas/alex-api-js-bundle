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
                                              , @agentId            INT
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
                 , finishedBy = 1
                 , tConversation = DATEDIFF(ss, requestDate, GETDATE())
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
END;