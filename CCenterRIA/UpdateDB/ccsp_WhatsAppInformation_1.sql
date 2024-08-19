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
        select @nIdioma = case valor 
            when 0 then 'Sin calificación'
            when 2 then 'Sem classificação' 
            else 'No disposition' end
        from ccsettings where setting_id = 27 -- 0esp
        SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
                        ISNULL(disposition.calif_id, 0) AS DispositionId,
                        COUNT(whatsConv.disposition) AS Total,
                        ISNULL(disposition.GraphColor, '1DB4E2') AS GraphColor,
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