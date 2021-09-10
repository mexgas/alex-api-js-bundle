/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY
	set @process = 'CW-5786 crea tabla ccWAMessagesConversations'
    set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccWAMessagesConversations]'') AND type in (N''U''))
BEGIN
CREATE TABLE [dbo].[ccWAMessagesConversations](
	[messageId] [varchar](75) NOT NULL,
	[conversationId] [int] NOT NULL,
	[timeStampMessage] [datetime] NOT NULL,
	[originType] [varchar](15) NOT NULL,
	[price] [varchar](10) NOT NULL,
	[messageIdUi] [int] NULL,
	[currency] [varchar](10) NULL,
	[typeMessage] [varchar](25) NULL,
	[content] [varchar](max) NULL,
	[clientNum] [varchar](15) NULL,
	[vonageNum] [varchar](15) NULL,
	[timeStampMessageUTC] [datetime] NULL,
 CONSTRAINT [pk_ccWAMessagesConvs_1] PRIMARY KEY CLUSTERED 
(
	[messageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ccWAMessagesConversations]  WITH CHECK ADD  CONSTRAINT [fk_WAConversationId_1] FOREIGN KEY([conversationId])
REFERENCES [dbo].[ccWhatsAppConversations] ([conversationId])

ALTER TABLE [dbo].[ccWAMessagesConversations] CHECK CONSTRAINT [fk_WAConversationId_1]
END
'
EXEC(@sql)

 set @process = 'CW-5774 create SP ccsp_ConversationWASave '
    set @sql = '
	IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''firstMessageTime''
          AND Object_ID = Object_ID(N''ccWhatsAppConversations''))
BEGIN
	EXEC sp_rename ''ccWhatsAppConversations.firstMessageTime'', ''assignDate'', ''COLUMN'';
END
	'
	EXEC(@sql)

   	set @process = 'CW-5774 Valida si existe SP ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql) 

    set @process = 'CW-5774 create SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
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
											  , @typeMessage		VARCHAR(25) = ''''
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
END;'
    EXEC(@sql)
	
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END