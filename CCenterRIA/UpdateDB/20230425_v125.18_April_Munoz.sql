/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 18
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN Jonathan Ramirez Errores de WhatsApp Version 2023.425.125.8------------------------------
		SET @process = 'Alter table ccWhatsAppConversationsOut add Column IsAgentLoggingOut'
		SET @sql = '
		IF EXISTS (SELECT * FROM sys.columns WHERE name = N''IsAgentLoggigOut'' and Object_ID = Object_ID(N''ccWhatsAppConversationsOut''))
		BEGIN
			ALTER TABLE ccWhatsAppConversationsOut DROP COLUMN IsAgentLoggigOut
			IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversationsOut'')) BEGIN
				ALTER TABLE ccWhatsAppConversationsOut ADD IsAgentLoggingOut BIT null
			END 
		END ELSE BEGIN
			IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversationsOut'')) BEGIN
				ALTER TABLE ccWhatsAppConversationsOut ADD IsAgentLoggingOut BIT null
			END 
		END
		'
		EXEC(@sql)


		SET @process = 'ALTER PROCEDURE ccsp_WhatsAppInformationOut, se agrega NoLOCK y query'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
		@Option SMALLINT,
		@camId SMALLINT = 0,
		@ConversationId INT = 0,
		@AgentsAvailables INT = 0,
		@IncreaseDecreaseAgent BIT = NULL

		AS
		SET NOCOUNT ON
		IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
			print (''Camp Is Not WhatsApp'')
			return(-1);
		End

		 
		      
		DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
		--set @Today SMALLDATETIME = ''2022-03-24''
		IF @Option = 0 BEGIN-- Reset TABLES
			TRUNCATE TABLE ccWAConversationsResult
			TRUNCATE table ccWAOperatingSummaryOut;
			TRUNCATE TABLE ccWAAverageConversationsOut;
			TRUNCATE TABLE ccLastMessageAgentByConversationOut;
		END    
		else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
		BEGIN
		    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
		                WHERE CamId = @camId
		                AND (LastUpdate IS NULL
		                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
		                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
		    BEGIN
		        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

		        DECLARE @AverageConversationTime INT = 0;
		        DECLARE @AverageDialogTime INT = 0;
		        DECLARE @AverageWaitingTime INT = 0;
		        DECLARE @MaximumWaitingTime INT = 0;
		        DECLARE @DefaultValue INT = 2


				SET @DefaultValue = @DefaultValue * 60;
		        DECLARE @LessThanDefault INT = 0;
		        DECLARE @ReceivedConversations INT = 0;
		        DECLARE @ServiceLevel SMALLINT = 0;

		        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

		        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
		                @AverageDialogTime = ROUND(AVG(tChatting), 4),
		                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
		                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
		                @ReceivedConversations = COUNT(conversationDate),
		                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
		        FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
		        AND requestDate >= @Today

		        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

		        ----------------------------------------------------- Update table --------------------------------------------------------

		        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
		        BEGIN
		            UPDATE ccWAAverageConversationsOut
		            SET AverageConversationTime = @AverageConversationTime,
		                AverageDialogTime = @AverageDialogTime,
		                AverageWaitingTime = @AverageWaitingTime,
		                MaximumWaitingTime = @MaximumWaitingTime,
		                ServiceLevel = @ServiceLevel,
		                StatusUpdate = 0,
		                LastUpdate = GETDATE()
		            WHERE CamId = @camId
		        END
		        ELSE
		        BEGIN
		            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
		                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
		            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
		                    @ServiceLevel, 0 , GETDATE())
		        END
		    END
		    --------------------------------- Results -----------------------------------

		    if exists (select * from ccWAOperatingSummaryOut with(nolock) where CamId=@camId
		                and (OnQueue<0 or Assigned<0)
		                ) begin
		                
		                    set @Today =convert(date,getdate(),121)

		                    ;with waOperationSummary as(
		                    select 
		                    CamId
		                    ,count(case when finishedBy=1 then 1 end) Attended
		                    ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
		                    ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
		                    ,count(*) Request
		                    ,count(case when finishedBy=2 then 1 end) EndedBySystem
		                    from ccWhatsAppConversationsOut with(nolock)
		                    where camId = @camId and requestDate>=@Today
		                    group by CamId
		                    )
		                    update A 
		                    set A.Attended=B.Attended, A.Assigned=B.Assigned
		                    
		                    ,A.Request=B.Request,A.EndedBySystem=B.EndedBySystem
		                    from ccWAOperatingSummaryOut A 
		                    inner join waOperationSummary B on A.CamId=B.CamId
		                end

		    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
		            ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
		            ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
		            ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
		            ISNULL(ServiceLevel, 0) AS ServiceLevel,
		            ISNULL(Attended, 0) AS Attended,
		            ISNULL(Assigned, 0) AS Assigned,
		            ISNULL(OnQueue, 0) AS OnQueue,
		            ISNULL(EndedBySystem, 0) AS EndedBySystem,
		            ISNULL(Available, 0) AS Available,
		            ISNULL(Request, 0) AS Request
		    FROM ccWAAverageConversationsOut conv
		    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
		    WHERE conv.CamId = @camId OR summary.camId = @camId
		END
		else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
		                -- Average Queue/Waiting Time, and Service Level)
		BEGIN
		    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
		        BEGIN
		            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
		            WHERE CamId = @camId
		        END
		        ELSE
		        BEGIN
		            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
		            VALUES(@camId, 1)
		        END
		END
		else IF @Option = 3 -- Save time from accepted conversation by agent
		BEGIN
		    IF @ConversationId IS NOT NULL
		    BEGIN
		        UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
		        --Save Conversation Assigned
		        SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
		        UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
		        
		    END
		END
		else IF @Option = 4 -- Get Disposition Information
		BEGIN
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
		select @nIdioma = case valor when 0 then ''Sin calificaci?n'' else ''No disposition'' end
		from ccsettings where setting_id = 27 -- 0esp
		SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
				ISNULL(disposition.calif_id, 0) AS DispositionId,
				COUNT(whatsConv.disposition) AS Total,
				ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
				COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		FROM ccWhatsAppConversationsOut whatsConv with(nolock)
		LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
		WHERE camId = @camId AND assignDate >= @Today
			and whatsConv.conversationStatus != 2
		GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
		END
		else IF @Option = 5 -- Get Subdisposition Information
		BEGIN
		    SELECT relation.calif_id AS DispositionId,
		            subDispositions.califSubDesc AS SubDispositionsName,
		            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		    FROM cctipoSubCalifRel relation
		    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
		    INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
		    WHERE whatsConv.camId = @camId AND
		            whatsConv.assignDate >= @Today AND
		            relation.tipoSubRel = 0
		    GROUP BY subDispositions.califSubDesc, relation.calif_id
		END
		ELSE IF @Option = 6 -- Agents Availables
		BEGIN
		    IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
		        BEGIN
		            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
		        END
		    ELSE
		        BEGIN
		            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
		        END
		END

		ELSE IF @Option = 7 -- Whats Conversations Results
		BEGIN
			SELECT ISNULL(SentMsg, 0) AS SentMsg,
					ISNULL(Delivered, 0) AS Delivered,
					ISNULL(NotDelivered, 0) AS NotDelivered,
					ISNULL(ReadMsg, 0) AS ReadMsg,
					ISNULL(NotSupported, 0) AS NotSupported
			FROM ccWAConversationsResult
			WHERE camId = @camId
		END
		    
		SET NOCOUNT OFF
		'
		EXEC(@sql)

		SET @process = 'ALTER SP ccsp_WhatsAppInformation, se agrega NOLOCK'
		SET @sql = '
		USE [CCenterRIA]
		GO
		/****** Object:  StoredProcedure [dbo].[ccsp_WhatsAppInformation]    Script Date: 19/3/2024 17:24:48 ******/
		SET ANSI_NULLS ON
		GO
		SET QUOTED_IDENTIFIER ON
		GO
		ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
		@Option SMALLINT,
	    @InboundId SMALLINT = 0,
	    @ConversationId INT = 0,
	    @AgentsAvailables INT = 0,
	    @IncreaseDecreaseAgent BIT = NULL

	    AS
	    SET NOCOUNT ON

		IF @Option = 0 BEGIN-- Reset TABLES
		    TRUNCATE TABLE ccWAOperatingSummary;
		    TRUNCATE TABLE ccWAAverageConversations;
		    TRUNCATE TABLE ccLastMessageAgentByConversation;
		END


		IF @InboundId IS NULL or  
		NOT EXISTS (SELECT * FROM ccInbound with(nolock) WHERE Inbound_id = @InboundId AND chat = 5) 
		BEGIN
		RETURN (-1)
		END

		            DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
		            
		            IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
		                BEGIN
		    IF EXISTS (SELECT * FROM ccWAAverageConversations with(nolock)
		                               WHERE InboundId = @InboundId
		                               AND (LastUpdate IS NULL
		                               OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
		                               OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
		                    BEGIN
		                        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

		                        DECLARE @AverageConversationTime INT = 0;
		                        DECLARE @AverageDialogTime INT = 0;
		                        DECLARE @AverageWaitingTime INT = 0;
		                        DECLARE @MaximumWaitingTime INT = 0;
		                        DECLARE @DefaultValue INT = (SELECT CASE 
																	WHEN defaultServiceLevelParameter IS NULL THEN 2 
																	WHEN defaultServiceLevelParameter = 0 THEN 2
																	ELSE defaultServiceLevelParameter END
																FROM contactMeanIn WHERE inboundId = @InboundId);
		                        SET @DefaultValue = @DefaultValue * 60;
		                        DECLARE @LessThanDefault INT = 0;
		                        DECLARE @ReceivedConversations INT = 0;
		                        DECLARE @ServiceLevel SMALLINT = 0;

		                        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

		                        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
		                               @AverageDialogTime = ROUND(AVG(tChatting), 4),
		                               @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
		                               @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
		                               @ReceivedConversations = COUNT(conversationDate),
		                               @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
		                        FROM ccWhatsAppConversations WHERE inboundId = @InboundId
		                        AND requestDate >= @Today

		                        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

		                        ----------------------------------------------------- Update table --------------------------------------------------------

		                        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
		                        BEGIN
		                            UPDATE ccWAAverageConversations
		                            SET AverageConversationTime = @AverageConversationTime,
		                                AverageDialogTime = @AverageDialogTime,
		                                AverageWaitingTime = @AverageWaitingTime,
		                                MaximumWaitingTime = @MaximumWaitingTime,
		                                ServiceLevel = @ServiceLevel,
		                                StatusUpdate = 0,
		                                LastUpdate = GETDATE()
		                            WHERE InboundId = @InboundId
		                        END
		                        ELSE
		                        BEGIN
		                            INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
		                                                                  AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
		                            VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
		                                   @ServiceLevel, 0 , GETDATE())
		                        END
		                    END
		                    --------------------------------- Results -----------------------------------

		    if exists (select * from ccWAOperatingSummary with(nolock) where Inboundid=@InboundId
		    and (OnQueue<0 or Assigned<0)
		    ) begin                                
		        set @Today =convert(date,getdate(),121)

		        ;with waOperationSummary as(
		                select 
		        inboundId
		        --,count(case when finishedBy=1 then 1 end) Attend
		        ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
		        ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
		        --,count(*) Request
		        --,count(case when finishedBy=2 then 1 end) EndedBySystem
		        from ccWhatsAppConversations with(nolock)
		        where inboundId=@InboundId
		        and requestDate>=@Today
		        group by inboundId
		        )
		        update A 
		        set A.OnQueue=B.onQueue, A.Assigned=B.Assigned
		        from ccWAOperatingSummary A 
		        inner join waOperationSummary B on A.Inboundid=B.inboundId
		    end


		                    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
		                           ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
		                           ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
		                           ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
		                           ISNULL(ServiceLevel, 0) AS ServiceLevel,
		                           ISNULL(Attended, 0) AS Attended,
		                           ISNULL(Assigned, 0) AS Assigned,
		                           ISNULL(OnQueue, 0) AS OnQueue,
		                           ISNULL(EndedBySystem, 0) AS EndedBySystem,
		                           ISNULL(Available, 0) AS Available,
		                           ISNULL(Request, 0) AS Request
		                    FROM ccWAAverageConversations conv
		                    RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
		                    WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
		                END
		ELSE IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
		                           -- Average Queue/Waiting Time, and Service Level)
		            BEGIN
		                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
		                    BEGIN
		                        UPDATE ccWAAverageConversations SET StatusUpdate = 1
		                        WHERE InboundId = @InboundId
		                    END
		                    ELSE
		                    BEGIN
		                        INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
		                        VALUES(@InboundId, 1)
		                    END
		            END
		ELSE IF @Option = 3 -- Save time from accepted conversation by agent
		            BEGIN
		                IF @ConversationId IS NOT NULL
		                BEGIN
		                    UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
		                    --Save Conversation Assigned
		            SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
		                    UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
		                    --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
		                END
		            END
		ELSE IF @Option = 4 -- Get Disposition Information
		            BEGIN
						declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
						select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
						from ccsettings where setting_id = 27 -- 0esp
						SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
								ISNULL(disposition.calif_id, 0) AS DispositionId,
								COUNT(whatsConv.disposition) AS Total,
								ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
								COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		        FROM ccWhatsAppConversations whatsConv with(nolock) 
						LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
						WHERE inboundId = @InboundId AND assignDate >= @Today
							and whatsConv.conversationStatus != 2
						GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
		            END
		ELSE IF @Option = 5 -- Get Subdisposition Information
		            BEGIN
		                SELECT relation.calif_id AS DispositionId,
		                       subDispositions.califSubDesc AS SubDispositionsName,
		                       COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		                FROM cctipoSubCalifRel relation
		                INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
		        INNER JOIN ccWhatsAppConversations whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
		                WHERE whatsConv.inboundId = @InboundId AND
		                      whatsConv.assignDate >= @Today AND
		                      relation.tipoSubRel = 1
		                GROUP BY subDispositions.califSubDesc, relation.calif_id
		            END
		ELSE IF @Option = 6 -- Agents Availables
		            BEGIN
		                IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
		                    BEGIN
		                        INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
		                    END
		                ELSE
		                    BEGIN
		                        UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
		                    END
		            END

		    RETURN(0)
		    SET NOCOUNT OFF

		'
		EXEC(@sql)

		SET @process = 'ALTER SP ccsp_ConversationWASaveOut, add NOLOCK'
		SET @sql = '
		USE [CCenterRIA]
		GO
		/****** Object:  StoredProcedure [dbo].[ccsp_ConversationWASaveOut]    Script Date: 08/03/2024 01:42:01 p. m. ******/
		SET ANSI_NULLS ON
		GO
		SET QUOTED_IDENTIFIER ON
		GO
		ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
		                                        , @conversationId     INT         = 0
		                                        , @camId          SMALLINT    = NULL
		                                        , @phoneCam           VARCHAR(50) = NULL
		                                        , @clientId           VARCHAR(25) = NULL
		                                        , @conversationStatus SMALLINT    = 0
		                                        , @tChatting          FLOAT    = 0
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
		                                        , @messageIdUi        INT         = NULL
		                                        , @clientNum          VARCHAR(15) = NULL
		                                        , @vonageNum          VARCHAR(15) = NULL
		                                        , @typeMessage        VARCHAR(25) = ''''
		                                        , @content            NVARCHAR(MAX)= NULL
		                                        , @timeStampMessage   DATETIME    = NULL
		                                        , @timeStampMessageUTC DATETIME   = NULL
		                                        , @originType         VARCHAR(15) = NULL
		                                        , @currency           VARCHAR(10) = ''-''
		                                        , @price              VARCHAR(10) = ''0.00''
		                                        , @messageStatus      VARCHAR(15) = ''N/A''
		                                        , @listConversationsIds   VARCHAR(MAX) = NULL
												, @IsAgentLoggingOut  BIT = 0
		AS
		BEGIN
		    DECLARE @isEndConversation BIT;
		    DECLARE @meanContactTypeId SMALLINT;
		    DECLARE @conversationIdNew INT;
		    SET @meanContactTypeId = 1;
		    SET NOCOUNT ON;

		IF @action = 1
		BEGIN --new Conversation
		    IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock)
		    WHERE A.conversationId = @conversationId)
		    BEGIN
		        INSERT INTO [ccWhatsAppConversationsOut]
		        (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
		        VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
		        
		        
		        SELECT @conversationId = SCOPE_IDENTITY();
		        SELECT @conversationId AS ConversationId;

		--        Save new request
		        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
		           INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
		        END
		        ELSE BEGIN
		            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
		        END
		        RETURN(0);
		    END
		    ELSE BEGIN
		        DECLARE @conversationStatusTemp INT = @conversationStatus;
		        IF @conversationStatus in(17,18) BEGIN
		            SET @conversationStatusTemp = 1
		        END	

				DECLARE @RequestDate DATETIME = NULL;
				SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversationsOut WITH(NOLOCK) WHERE conversationId = @conversationId;

		        INSERT INTO [ccWhatsAppConversationsOut]
					(camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId, requestDate)
		        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, 
					@tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
		        SELECT @conversationIdNew = SCOPE_IDENTITY();

		        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
		        VALUES (@conversationId, @conversationIdNew);
		        --Save new request by reassign
		        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
		        WHERE camId = @camId

		    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

		    SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
		    RETURN(0);
		END;
		END;

		else IF @action = 2
		BEGIN --save conversation Times
		    DECLARE @conversationIdTemp INT;
		    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

		    IF @listConversationsIds IS NOT NULL begin
		        INSERT INTO @TablaTemp
		        SELECT value,0
		        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
		        where value is not null and value<>''''
		    end
		    else begin
		        INSERT INTO @TablaTemp values(@conversationId,0)
		    end
			
		    UPDATE ccWhatsAppConversationsOut
		    SET
		    conversationStatus = @conversationStatus
		    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
		    when @conversationStatus in(11) then 1
		        else 0 end
		    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
		    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
		    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
		    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

		    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
		    BEGIN
		        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
		        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

		        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
		            DECLARE @conversationDateTemp INT;
		            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
		            from ccWhatsAppConversationsOut where conversationId = @conversationId;

		            IF @conversationStatus = 13 BEGIN
		                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam with(nolock) where NumberClient = @clientId) BEGIN
		                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
		                END
		            END
		            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
		                IF @conversationDateTemp > 0 BEGIN
		                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
		                END
		                ELSE BEGIN
		                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
		                END
		            END
		            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
		                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
		            END
		        END
		        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
		    END

		END;

		else IF @action = 3
		BEGIN --save conversation Status
		    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
		END;

		else IF @action = 4 BEGIN --save messages from conversation
		    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId)
		        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A with(nolock) WHERE A.messageId=@messageId)
		    BEGIN
		        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
		            (SELECT messageIdUi
		                FROM ccWAMessagesConversationsOut
		                WHERE originType IN (''Agent'', ''Admin'')
		                AND conversationId = @conversationId)
		            BEGIN
		                UPDATE ccWhatsAppConversationsOut
		                    SET FirstMessageAgent = @timeStampMessage
		                    WHERE conversationId = @conversationId;
		            END

		        INSERT INTO [ccWAMessagesConversationsOut](
		                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
		                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
		        SELECT @messageId=SCOPE_IDENTITY()
		       
		       SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
				if not exists(select * from ccWAConversationsResult where camId=@camId)begin
					insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
				end
				exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
				
				 SELECT @messageId as MessageId
				
		        RETURN (0)
		    END
		    ELSE BEGIN
		        SELECT 0 AS MessageId
		        RETURN (0)
		    END
		END;

		else IF @action = 5
		BEGIN --save onQueue
		    UPDATE ccWhatsAppConversationsOut
		            SET onQueue = 1,
		            conversationStatus = @conversationStatus
		    WHERE conversationId = @conversationId;
		    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
		    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
		END;

		else IF @action = 6
		BEGIN --save agent, assigdate and tqueue
		    declare @agentIdTmp int
		    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
			   
		        UPDATE ccWhatsAppConversationsOut
		                SET agentId = @agentId,
		                assignDate = getdate(),
		                conversationStatus = @conversationStatus
		                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
		        WHERE conversationId = @conversationId;

		    SELECT @conversationId as conversationId
		    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;

		    IF @onQueue = 1 BEGIN
		     UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
		    END
		END;

		 Else IF @action = 7
		BEGIN --update price message
		    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
		END;
		else IF @action = 8
		BEGIN --update status message
		    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A with(nolock) 
		        WHERE A.messageId=@messageId) <> ''read'' 
		    BEGIN
		        UPDATE ccWAMessagesConversationsOut
		                SET messageStatus = @messageStatus
		        WHERE messageId = @messageId;
				exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
				
		    END;
		END;

		else IF @action = 9
		BEGIN --Save last message time by conversationID
		    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A with(nolock) 
		        WHERE A.conversationId=@conversationId) IS NULL BEGIN
		        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
		    END;
		    ELSE
		        BEGIN
		            UPDATE ccLastMessageAgentByConversationOut
		                SET timeStampLastMessageAgent = getDate()
		            WHERE conversationId = @conversationId;
		        END;
		END;

		else IF @action = 10
		BEGIN --drop and insert register by conversationID
		    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
		END;

		Else IF @action = 11
		BEGIN --register desconnection agent by conversationID
			exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
		END;

		else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
		    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] with(nolock) 
		    where timeStampConnection is null order by timeStampDisconnection desc);
		    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

		    declare @from as datetime;
		    select @from = convert(datetime,convert(varchar(11),getdate()))
		    set @from=DATEADD(dd,-1,@from);
		        select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
		        , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
		        isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
		        isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
		        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
		        from ccWhatsAppConversationsOut A with(nolock) 
		        left join ccWAMessagesConversationsOut B with(nolock) on A.conversationId = B.conversationId
		        left join [ccDisconnectionMCSOut] C with(nolock) on C.disconnectionId = @disconnectionIdTemp        
		        where A.requestDate >= @from 
		            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
		        order by agentId desc, requestDate,timeStampMessage, camId, clientId 
		END;
		else IF @action = 13
		BEGIN ---Obtain agents ON STATUS READY
		    WITH agents
		    AS(
		        SELECT c.User_id, c.fecha, c.currentStatus
		        FROM ccLogAgentesDia c
		        INNER JOIN 
		        (
		            SELECT User_id, MAX(fecha) max_time
		            FROM ccLogAgentesDia with(nolock)
		            where fecha>=CONVERT(date,getdate(),121)
		            GROUP BY User_id
		        ) AS t
		        ON c.fecha = t.max_time
		        AND c.User_id=t.User_id AND currentStatus in (3,34)
		    ), usersByCampigns
		    AS (
		        select IdCampEsp, User_id from ccRIACampEspWG A
		        Inner join ccRIAWorkGroupUsers B
		        on A.IDWG = B.IDWG
		        Inner join contactMeanOut C
		        ON A.idCampEsp = C.camp_id
		        where A.IDWG = 1 and A.Tipo = 1
		        AND C.meanContactTypeId = 5
		    )

		    select DISTINCT A.User_Id from agents A
		    left join usersByCampigns B on A.User_Id = B.User_Id
		END;

		else IF @action = 14
		BEGIN --register desconnection MCS
		    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
		END;
		ELSE IF @action = 15
		    BEGIN --update content message
		        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
		            UPDATE ccWAMessagesConversationsOut
		                    SET content = @content
		            WHERE messageId = @messageId;
		        END;
		    END;
		ELSE IF @action = 16 BEGIN --update content message
			if @camId is null or @camId=0 begin	
		        SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
			end
		         		
			if @messageStatus=''submitted'' begin
				update ccWAConversationsResult set SentMsg= SentMsg+1
			end
			else if @messageStatus=''delivered'' begin
				update ccWAConversationsResult set SentMsg= SentMsg-1,Delivered=Delivered+1
			end
			else if @messageStatus=''read'' begin
				update ccWAConversationsResult set Delivered=Delivered-1,ReadMsg=ReadMsg+1
			end
			else if @messageStatus=''rejected'' begin
				update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
			end

			SELECT @messageId as MessageId
		END;
		ELSE IF @action = 17 BEGIN --update agent status for reassigning error message
			UPDATE ccWhatsAppConversationsOut
			SET IsAgentLoggingOut = @IsAgentLoggingOut
			WHERE conversationId = @conversationId;
		END;
		ELSE IF @action = 18 BEGIN
				DECLARE @dateNow DATETIME;
				SET @dateNow = DATEADD(HOUR, -23, GETDATE());

				UPDATE ccWhatsAppConversationsOut 
		    SET finishedBy = 2, conversationStatus=17
				WHERE finishedBy = 0  AND requestDate <= @dateNow	
			END;
		END;
		'
		EXEC(@sql)

		SET @process = 'ALTER SP ccsp_MultimediaCommon, se agrega timstampUTC'
		SET @sql = '
USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_MultimediaCommon]    Script Date: 08/03/2024 01:42:01 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
				    @Option AS SMALLINT,
				    @inboundId AS SMALLINT = 0,
				    @conversationId AS INT = 0,
				    @ServiceType AS SMALLINT = 0,
				    @status as SMALLINT =0,
				    @messagesList as varchar(max) = '''',
				    @agentId AS SMALLINT = 0,
				    @CampType bit =0
				    AS
				    BEGIN
				        SET NOCOUNT ON;

				    IF @Option = 0 --  Get Campaigns Configuration List
				    BEGIN
				            SELECT CAST(campaign.cam_id AS INT) AS Id,
				                    campaign.cam_descripcion AS [Name],
				                    ISNULL(configuration.number, '''') AS Phone,
				                    CAST(graphics.graphic_id AS INT) AS GraphicId
				            FROM  ccCamps campaign 
				            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
				            INNER JOIN  ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id where configuration.status != 0 AND campaign.CampType = 5
				                            
				    END

				    ELSE IF @Option = 1 --  Get Acds Configuration List
				    BEGIN
				                            
				        SELECT --inbound.chat AS ServiceType,
				        CAST(inbound.Inbound_id AS INT) AS Id,
				        inbound.descripcion AS [Name],
				        ISNULL(configuration.conexionInfo, '''') AS Phone,
				        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
				        inbound.tNotas AS WrapUpTime,
				        CAST(graphics.graphic_id AS INT) AS GraphicId
				        FROM  ccInbound inbound
				        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
				        INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId where inbound.Status != 0 
				                            
				    END

				    ELSE IF(@Option = 2)
				    BEGIN


				        DECLARE @OldAgentId INT = 0
				        DECLARE @OldConversationId INT = 0
				        if @campType =0 begin --ACD
				            SELECT  @OldAgentId = conv.agentId,
				                    @OldConversationId = rel.conversationIdBefore
				            FROM ccWhatsAppConversationsRelationship rel 
				            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
				            WHERE rel.conversationIdAfter = @conversationId

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
				        i.tNotas as [WrapUpTime],
				        i.ShowCalifWnd,
				        cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
				        ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
				        isnull(permission.AllowUnassign,0) as AllowUnassign,
				        isnull(permission.AllowSpam,0) as AllowSpam,
				        ISNULL(@OldAgentId, 0) AS OldAgentId,
				        ISNULL(@OldConversationId, 0) AS OldConversationId,
				        c.agentId AS AgentId,
				        c.IsAgentLoggingOut AS IsAgentLoggingOut
				        from ccWhatsAppConversations c
				        left join ccInbound i on c.inboundId = i.Inbound_id 
				        left JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId    
				        LEFT JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
				        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
				        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

				        where c.conversationId = @conversationId

				            
				        End
				        ELSE BEGIN --Camp
				            SELECT  @OldAgentId = conv.agentId,
				                    @OldConversationId = rel.conversationIdBefore
				            FROM ccWhatsAppConversationsRelationshipOut rel 
				            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
				            WHERE rel.conversationIdAfter = @conversationId

				            SELECT
				            cast(i.CampType as int) AS ServiceType,
				            cast(c.conversationId as int) as ConversationID,
				            c.clientId as ClientId,
				            c.phoneCamp as [To],
				            cast(i.cam_id as int) as ACDId,
				            i.cam_descripcion as ACDName,
				            cast(g.graphic_id as int) as ACDGraphicId,
				            cast(cm.closeConversationTime as int) as [TimeOut],
				            cast(cm.answerTimeoutClient as int) as [TimeOutWarning],
				            i.exitAssisted as [ExitWrapUpDisposition],              
				            cast(i.cam_tnotas as int) [WrapUpTime],
				            i.cam_ShowCalifWnd as ShowCalifWnd, 
				            cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
				            ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
				            isnull(permission.AllowUnassign,0) as AllowUnassign,
				            isnull(permission.AllowSpam,0) as AllowSpam,
				            ISNULL(@OldAgentId, 0) AS OldAgentId,
				            ISNULL(@OldConversationId, 0) AS OldConversationId,
				            c.agentId AS AgentId
				            FROM  ccWhatsAppConversationsOut c
				            LEFT JOIN  ccCamps i ON c.camId = i.cam_id 
				            LEFT JOIN  contactMeanOut cm  ON c.camId = cm.camp_id
				            LEFT JOIN ccRIACampsGraph g on g.cam_id = c.camId
				            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
				            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

				            where c.conversationId = @conversationId
				        END
				    END
				    ELSE IF(@Option = 3)
				    BEGIN
				        if @campType =0 begin --ACD
				            SELECT
				            CAST(inbound.Inbound_id AS INT) AS Id,
				            inbound.descripcion AS Name,
				            ISNULL(configuration.conexionInfo, '''') AS Phone,
				            CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
				            inbound.tNotas AS WrapUpTime,
				                CAST(graphics.graphic_id AS INT) AS GraphicId
				            FROM  ccInbound inbound
				            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
				            INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
				        end
				        else begin
				        SELECT
				            CAST(campaign.cam_id AS INT) AS Id,
				            campaign.cam_descripcion AS Name,
				            ISNULL(configuration.conexionInfo, '''') AS Phone,
				            CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
				            cast(campaign.cam_tnotas as int) AS WrapUpTime,
				            CAST(graphics.graphic_id AS INT) AS GraphicId
				            FROM  ccCamps campaign
				            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
				            INNER JOIN  contactMeanOut configuration ON (campaign.cam_id = configuration.camp_id and campaign.cam_id = @inboundId)
				        end
				    END
				    ELSE IF(@Option = 4)
				    Begin
				            declare @pathFile as varchar(max)
				            declare @filetype as varchar(5)
				            DECLARE @mensajes TABLE(idMessage VARCHAR(100));
				            DECLARE @tmpMessageConversations TABLE(
				                    [messageId] VARCHAR(75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
				                ,[conversationId] INT NOT NULL
				                ,[timeStampMessage] DATETIME NOT NULL
				                ,[originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
				                ,[price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
				                ,[messageIdUi] INT NULL
				                ,[currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[timeStampMessageUTC] DATETIME NULL
				                ,[messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				            );

				        insert into @mensajes
				        select value from dbo.fn_RIASplitDelimited(@messagesList,'','')
				                        
				            if(@CampType = 0)
				            BEGIN
				                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus) 
								select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus
				                FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
				            END
				            if(@CampType = 1)
				            BEGIN
				                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus) 
								select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus
				                FROM ccWAMessagesConversationsOut  where messageId in (select idMessage from @mensajes)
				            END
				            select @pathFile = valor from ccSettings where setting_id=230
				        select
				            messageId as MessageId,
				            messageStatus as Status,
				            originType as Origin,
				            case when originType =''Client'' then 3
				                    when originType =''Agent'' then 2
				                    when originType =''Admin'' then 1
				            else 0 end as OriginType,
				            timeStampMessage as [Timestamp],
				            case when typeMessage IN (''text'', ''template'')  then content else '''' end as Content,
				            typeMessage as Type,
				            case 
				                    when typeMessage not in( ''text'' ,''location'', ''file'', ''template'') then content
				                    else
				                        case
				                            when typeMessage = ''file'' then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) 
				                                    else '''' end
				                    end as Caption,
				            case 
				                    when originType = ''Client''
				                    then
				                        case
				                                when typeMessage = ''text'' or typeMessage = ''location''
				                                or (typeMessage = ''file'' and (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) = '''' )
				                            then ''''
				                                else char(92)+char(92)+''WhatsApp''+char(92)+char(92)+ CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END +char(92)+char(92)+cast(conversationId/1000 as varchar(30))+char(92)+char(92)+cast(conversationId as varchar(20))+char(92)+char(92)+ typeMessage + char(92)+char(92)+ messageId +
				                                case
				                                        when typeMessage = ''video'' then ''.mp4''
				                                        when typeMessage = ''image'' then ''.jpg''
				                                        when typeMessage = ''audio'' then ''.mp3''
				                                        when typeMessage = ''file''
				                                        then (select substring(content, LEN(content) - CHARINDEX(''.'',REVERSE(content))+1, len(content)))
				                                    else '''' end
				                        end
				                    else
				                        case
				                            when typeMessage = ''text'' or typeMessage = ''location'' OR typeMessage = ''template''
				                            then ''''
				                            else content
				                    end
				                end as [Url],
				                case when typeMessage = ''file'' 
				                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2)
				                else '''' end as [FileSize],
				                case when typeMessage = ''file'' 
				                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2)
				                else '''' end as [FileName],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
				            case when typeMessage = ''location''
				            then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
				                (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
				                from @tmpMessageConversations
				            order by Timestamp asc

				    End
				                                            
				    ELSE IF(@Option = 5)
				    BEGIN
				        if @CampType =0 begin
				            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
				                FROM contactMeanIn
				            WHERE inboundId = @inboundId
				        end 
				        else begin
				            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
				                FROM contactMeanOut
				            WHERE camp_id = @inboundId
				        end 
				    END
				    ELSE IF(@Option = 6)
				    BEGIN
				        SELECT [Login] AS ''OriginName''
				            FROM [CCenterRIA].[dbo].[ccUsers]
				        WHERE [User_id] = @agentId
				    END
				    END
		'
		EXEC(@sql)

		SET @process = 'ALTER SP ccsp_ConversationWASave, se agregan opciones, eliminar 23 hrs'
		SET @sql = '
USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_ConversationWASave]    Script Date: 12/03/2024 07:24:33 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                    , @conversationId     INT         = 0
                    , @inboundId          SMALLINT    = NULL
                    , @phoneACD           VARCHAR(50) = NULL
                    , @clientId           VARCHAR(25) = NULL
                    , @conversationStatus SMALLINT    = 0
                    , @tChatting          FLOAT    = 0
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
                    , @messageIdUi        INT         = NULL
                    , @clientNum          VARCHAR(15) = NULL
                    , @vonageNum          VARCHAR(15) = NULL
                    , @typeMessage        VARCHAR(25) = ''''
                    , @content            NVARCHAR(MAX)= NULL
                    , @timeStampMessage   DATETIME    = NULL
                    , @timeStampMessageUTC DATETIME   = NULL
                    , @originType         VARCHAR(15) = NULL
                    , @currency           VARCHAR(10) = ''-''
                    , @price              VARCHAR(10) = ''0.00''
                    , @messageStatus      VARCHAR(15) = ''N/A''
                    , @listConversationsIds   VARCHAR(MAX) = NULL
					, @IsAgentLoggingOut  BIT = 0
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
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

            IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
                SELECT @conversationId = SCOPE_IDENTITY();
                SELECT @conversationId AS ConversationId;
            END
            ELSE BEGIN

                declare @conversationIdTemporal     INT;
                SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                SELECT 0 AS ConversationId;
            END;

            --Save new request
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
                END
            ELSE
                BEGIN
                    UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
                END
            RETURN(0);
        END
        ELSE
        BEGIN
            DECLARE @conversationStatusTemp INT = @conversationStatus;
            IF @conversationStatus in(17,18) BEGIN
                SET @conversationStatusTemp = 1
            END

			DECLARE @RequestDate DATETIME = NULL;
			SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

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
			, requestDate
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
            SELECT @conversationIdNew = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                , conversationIdAfter)
                VALUES (@conversationId, @conversationIdNew);
            --Save new request by reassign
UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
WHERE InboundId = @inboundId

        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
        RETURN(0);
    END;
END;

ELSE IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end

    UPDATE ccWhatsAppConversations
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
    else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

	IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                END
            END
			ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

ELSE IF @action = 3
BEGIN --save conversation Status
UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 4 BEGIN --save messages from conversation
IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversations
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversations
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversations](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
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
                SET onQueue = 1,
                conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
    END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
	SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

    IF (@agentIdTmp is null or @agentIdTmp=0)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

        SELECT @conversationId as conversationId
SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
declare @onQueueInt int

    IF @onQueue = 1 BEGIN
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
        if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

            select          
            @onQueueInt=count(case when onQueue =1 then 1 end)
            from ccWhatsAppConversations with(nolock)
            where inboundId= @inboundId
            and requestDate>=convert(date,getdate(),121)

            UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

        end

    END
    END
END;

ELSE IF @action = 7
    BEGIN --update price message
        UPDATE ccWAMessagesConversations
                SET price = @price,
                    currency = @currency
        WHERE messageId = @messageId;
    END;

ELSE IF @action = 8
    BEGIN --update status message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET messageStatus = @messageStatus
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 9
    BEGIN --Save last message time by conversationID
        IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
            INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
        END;
        ELSE
            BEGIN
                UPDATE ccLastMessageAgentByConversation
                    SET timeStampLastMessageAgent = getDate()
                WHERE conversationId = @conversationId;
            END;
    END;

ELSE IF @action = 10
    BEGIN --drop and insert register by conversationID
        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 11
    BEGIN --register desconnection agent by conversationID
        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 12
    BEGIN --Obtain conversationsWA post MCS reset

        declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
        UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

        declare @from as datetime;-- = ''01-07-2022'';
        select @from = convert(datetime,convert(varchar(11),getdate()))
        set @from=DATEADD(dd,-1,@from);
            select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
            ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
			from ccWhatsAppConversations A with(nolock)
            left join ccWAMessagesConversations B on A.conversationId = B.conversationId
            left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
            where A.requestDate >= @from 
                and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
            order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
    END;
ELSE IF @action = 13
    BEGIN ---Obtain agents ON STATUS READY
        WITH agents
        AS(
            SELECT c.User_id, c.fecha, c.currentStatus
            FROM ccLogAgentesDia c
            INNER JOIN 
            (
                SELECT User_id, MAX(fecha) max_time
	            FROM ccLogAgentesDia with(nolock)
	            where fecha>=CONVERT(date,getdate(),121)
                GROUP BY User_id
            ) AS t
            ON c.fecha = t.max_time
            AND c.User_id=t.User_id AND currentStatus in (3,34)
        ), usersByCampigns
        AS (
            select IdCampEsp, User_id from ccRIACampEspWG A
            Inner join ccRIAWorkGroupUsers B
            on A.IDWG = B.IDWG
            Inner join contactMeanIn C
            ON A.idCampEsp = C.inboundId
            where A.IDWG = 1 and A.Tipo = 0
            AND C.meanContactTypeId = 5
        )

        select DISTINCT A.User_Id from agents A
        left join usersByCampigns B on A.User_Id = B.User_Id
    END;

ELSE IF @action = 14
    BEGIN --register desconnection MCS
        INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
    END;

ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 16
    BEGIN --update agent status for reassigning error message
            UPDATE ccWhatsAppConversations
            SET IsAgentLoggingOut = @IsAgentLoggingOut
            WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 18 BEGIN
		DECLARE @dateNow DATETIME;
		SET @dateNow = DATEADD(HOUR, -23, GETDATE());

		UPDATE ccWhatsAppConversations
		SET finishedBy = 2, conversationStatus=17
		WHERE finishedBy = 0 AND requestDate <= @dateNow	
	END;
END;
		'
		EXEC(@sql)

		SET @process = 'alter sp ccsp_ConversationOutWASave, se agregan opciones, terminar 23 hrs'
		SET @sql = '
USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_ConversationOutWASave]    Script Date: 19/3/2024 16:54:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
@action             INT
, @conversationId     INT         = 0
, @campId			  INT		  = NULL        
, @phoneCamp          VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT       = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0

AS
BEGIN
	SET NOCOUNT ON;
					    
	declare @conversationIdTemporal     INT;

IF @action = 1 BEGIN --new Conversation
	select @phoneCamp= number from ccWhatsAppNumbers where camp_id= @campId
							
	if @phoneCamp is null or @phoneCamp='''' begin
		select 0 as [ConversationId],0 as [MessageId]
		return(0)
	end
	DECLARE @dateNow DATETIME;
	SET @dateNow = DATEADD(HOUR, -23, GETDATE());


	declare @existsConversationOut bit
    declare @existsConversation bit
	set @existsConversationOut =0
	set @existsConversation =0

	
	
	if not exists (select * from ccWhatsAppConversationsOut with(nolock) where
	phoneCamp = @phoneCamp and clientId = @clientId and	finishedBy=0 AND requestDate <= @dateNow) 
	begin		
		set @existsConversationOut=0
	end 
	else begin
		set @existsConversationOut=1
		UPDATE ccWhatsAppConversationsOut
		SET finishedBy = 2 ,conversationStatus=17
		WHERE finishedBy = 0  AND requestDate <= @dateNow
		and phoneCamp = @phoneCamp and clientId = @clientId
	end
	
	if not exists (select * from ccWhatsAppConversations with(nolock) where
    phoneACD = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
    begin       
        set @existsConversation=0
    end 
    else begin
        set @existsConversation=1
        UPDATE ccWhatsAppConversations
        SET finishedBy = 2 ,conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow
        and phoneACD = @phoneCamp and clientId = @clientId
    end
    
	if not exists (select 1 from ccWhatsAppConversationsOut with(nolock) 
		where phoneCamp = @phoneCamp and clientId = @clientId 
		and finishedBy = 0 and requestDate > @dateNow) 
	begin
		set @existsConversationOut=0
	end
	else begin
		set @existsConversationOut=1
	end
	
	if not exists (select 1 from ccWhatsAppConversations with(nolock) 
        where phoneACD = @phoneCamp and clientId = @clientId 
        and finishedBy = 0 and requestDate > @dateNow) 
    begin
        set @existsConversation=0
    end
    else begin
        set @existsConversation=1
    end
    
	if @existsConversationOut=0
	begin
        if @existsConversation = 0
		begin
			INSERT INTO [ccWhatsAppConversationsOut]
			([camId] , [phoneCamp], clientId, conversationStatus, tChatting
			, tWrapUp, finishedBy, onQueue, tQueue, requestDate
			, tTimeout, disposition, subDisposition, agentId)
			VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
			@onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId);
					    
			SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
			SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
		end
		else begin
			select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username 
			,B.conversationId as conversationIdExists
            FROM ccInbound A INNER JOIN ccWhatsAppConversations B WITH(NOLOCK)
			ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
			INNER JOIN ccUsers C ON B.agentId = C.User_id;
		end  
	end
	else begin
		select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username
		,B.conversationId as conversationIdExists
		FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B WITH(NOLOCK)
		ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
		INNER JOIN ccUsers C ON B.agentId = C.User_id;
	end  
END 
ELSE IF @action = 2 -- Get Outbound Templates
BEGIN
	IF @campId IS NOT NULL
	BEGIN
		DECLARE @AsociatedNumber VARCHAR(30) = (SELECT number from ccWhatsAppNumbers WHERE @campId = camp_id);
		SELECT * FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
	END
END
END
		'
		EXEC(@sql)

		-------------------------------------------- END Jonathan Ramirez Errores de WhatsApp Version 2023.425.125.8------------------------------
		
		
		----------------------------------------------------------------------------------------------------------------------------
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END


