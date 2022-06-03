/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 32
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

	    set @process = 'Version Bd 123.32 update ccsp_AgentHistoricalChat'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat]
        @option SMALLINT,
        @clientNum VARCHAR(15) = '''',
        @conversationId AS INT = 0,
        @inboundId AS SMALLINT = 0,
        @serviceType AS SMALLINT = 0
        AS
        BEGIN
            IF @option = 1 --whatsapp, get conversation ids
            BEGIN
                SELECT conversationId FROM [CCenterRIA].[dbo].[ccWhatsAppConversations] WHERE clientId = @clientNum GROUP BY conversationId
            END
            IF @option = 2 --whatsapp, get acdId by conversation id
            BEGIN
                SELECT CAST(inboundId AS INT) FROM [CCenterRIA].[dbo].[ccWhatsAppConversations] WHERE conversationId = @conversationId
            END
            IF @option = 3 --get data conversation
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
                    i.tNotas as [WrapUpTime],
                    i.ShowCalifWnd,
                    cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                    ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent]
                FROM  ccInbound i
                    INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
                    INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
                    INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
                    LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                WHERE i.chat = @serviceType and i.Inbound_id = @inboundId
            END
            IF @option = 4 --get messages from conversation id
            BEGIN
                declare @pathFile as varchar(max)
                declare @filetype as varchar(5)

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
                    case when typeMessage <> ''text''  then '''' else content end as Content,
                    typeMessage as Type,
                    case when typeMessage not in( ''text'' ,''location'') then content else '''' end as Caption,
                    case when typeMessage = ''text'' or typeMessage = ''location'' then '' else @pathFile +char(92)+cast(conversationId/1000 as varchar(30))+char(92)+cast(conversationId as varchar(20))+char(92)+ typeMessage + char(92)+ messageId +''.''+
                    case
                        when typeMessage = ''video'' then ''mp4''
                        when typeMessage = ''image'' then ''jpg''
                        when typeMessage = ''audio'' then ''mp3''
                        when typeMessage = ''file'' then (select substring(content, CHARINDEX(''.'',content)+1, len(content)))
                        else '''' end
                    end as [Url],
                    case when typeMessage = ''location''
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
                    case when typeMessage = ''location''
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '' end as [Lat],
                    case when typeMessage = ''location''
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '' end as [Long],
                    case when typeMessage = ''location''
                    then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '' end as [Name],
                    case when typeMessage = ''location''
                    then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
                        (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
                    from ccWAMessagesConversations where conversationId = @conversationId
                    order by Timestamp asc
            END
            IF @option = 5 --get if conversation is reassigned
            BEGIN
                SELECT CASE WHEN EXISTS (
                SELECT *
                FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship]
                WHERE conversationIdAfter = @conversationId
                )
                THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT) END
            END
        END'
		EXEC(@sql)

        set @process = 'Version Bd 123.32 update ccsp_MultimediaCommon'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
        @Option AS SMALLINT,
        @inboundId AS SMALLINT = 0,
        @conversationId AS INT = 0,
        @ServiceType AS SMALLINT = 0,
        @status as SMALLINT =0,
        @messagesList as varchar(max) = '''',
        @agentId AS SMALLINT = 0
        AS
        BEGIN
            SET NOCOUNT ON;

            IF(@Option = 1)
                BEGIN

                        SELECT --inbound.chat AS ServiceType,
                        CAST(inbound.Inbound_id AS INT) AS ACDId,
                        inbound.descripcion AS ACDName,
                        ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
                        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                        inbound.tNotas AS WrapUpTime

                        FROM  ccInbound inbound
                        INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId where inbound.Status != 0 
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
                        i.tNotas as [WrapUpTime],
                        i.ShowCalifWnd,
                        cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                        ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent]
                    FROM  ccInbound i
                        INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
                        INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
                        INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
                        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                    WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
                END
            IF(@Option = 3)
                BEGIN
                        SELECT
                        CAST(inbound.Inbound_id AS INT) AS ACDId,
                        inbound.descripcion AS ACDName,
                        ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
                        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                        inbound.tNotas AS WrapUpTime

                        FROM  ccInbound inbound
                        INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
                END
            IF(@Option = 4)
            Begin

                declare @pathFile as varchar(max)
                declare @filetype as varchar(5)
                DECLARE @mensajes TABLE(idMessage VARCHAR(100));

                insert into @mensajes
                select value from dbo.fn_RIASplitDelimited(@messagesList,'','')


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
                    case when typeMessage <> ''text''  then '''' else content end as Content,
                    typeMessage as Type,
                    case when typeMessage not in( ''text'' ,''location'') then content else '''' end as Caption,
                    case when typeMessage = ''text'' or typeMessage = ''location'' then '''' else @pathFile +char(92)+cast(conversationId/1000 as varchar(30))+char(92)+cast(conversationId as varchar(20))+char(92)+ typeMessage + char(92)+ messageId +''.''+
                    case
                        when typeMessage = ''video'' then ''mp4''
                        when typeMessage = ''image'' then ''jpg''
                        when typeMessage = ''audio'' then ''mp3''
                        when typeMessage = ''file'' then (select substring(content, CHARINDEX('.',content)+1, len(content)))
                        else '' end
                    end as [Url],
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
                    from ccWAMessagesConversations where messageId in (select idMessage from @mensajes)
                    order by Timestamp asc

            End
            
            IF(@Option = 5)
            BEGIN
                SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                    FROM contactMeanIn
                WHERE inboundId = @inboundId
            END

            IF(@Option = 6)
            BEGIN
                SELECT [Login] AS ''OriginName''
                    FROM [CCenterRIA].[dbo].[ccUsers]
                WHERE [User_id] = @agentId
            END
        END'
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


