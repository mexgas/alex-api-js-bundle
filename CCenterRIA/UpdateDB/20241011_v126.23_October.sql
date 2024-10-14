/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/30
Description: Release 126.20240930.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
    	
		------------------------------------------------- BEGIN  K020039 IVAN MARTIN----------------------------------------------------------------------------------
		SET @process = 'K020039- Se elimina SP ccsp_MultimediaCommon'
        SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_MultimediaCommon'')
                    BEGIN
                        DROP PROCEDURE ccsp_MultimediaCommon;
                    END'
        EXEC(@sql)

        SET @process = 'K020039- Se agrega la opción 7 para obtener el valor de maxLimitQueueConversations en campañas de salida- Lineas 402 en adelante'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
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

                        IF @Option = 0 --  Obtener lista de configuraciones de campañas
                        BEGIN
                            SELECT CAST(campaign.cam_id AS INT) AS Id,
                                   campaign.cam_descripcion AS [Name],
                                   ISNULL(configuration.number, '''') AS Phone,
                                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                                   0 AS isMeta
                            FROM ccCamps campaign 
                            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                            INNER JOIN ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id
                            WHERE configuration.status != 0 AND campaign.CampType = 5

                            UNION ALL

                            SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
                                   campaign.cam_descripcion AS [Name],
                                   ISNULL(configuration.number, '''') AS Phone,
                                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                                   1 AS isMeta
                            FROM ccCamps campaign 
                            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                            INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
                            WHERE configuration.status != 0 AND campaign.CampType = 5   
                                                                                
                        END

                        ELSE IF @Option = 1 -- Obtener lista de configuraciones de ACDs
                        BEGIN
                            SELECT CAST(inbound.Inbound_id AS INT) AS Id,
                                   inbound.descripcion AS [Name],
                                   ISNULL(numbers.number, '''') AS Phone,
                                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                                   inbound.tNotas AS WrapUpTime,
                                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                                   0 AS isMeta
                            FROM ccInbound inbound
                            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                            INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId  
                            WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 

                            UNION ALL

                            SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
                                   inbound.descripcion AS [Name],
                                   ISNULL(numbers.number, '''') AS Phone,
                                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                                   inbound.tNotas AS WrapUpTime,
                                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                                   1 AS isMeta
                            FROM ccInbound inbound
                            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                            INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id
                            WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 
                                                                                
                        END

                         ELSE IF(@Option = 2)
                        BEGIN
                            DECLARE @OldAgentId INT = 0
                            DECLARE @OldConversationId INT = 0

                            IF @CampType = 0 BEGIN -- ACD
                                SELECT @OldAgentId = conv.agentId,
                                       @OldConversationId = rel.conversationIdBefore
                                FROM ccWhatsAppConversationsRelationship rel 
                                RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
                                WHERE rel.conversationIdAfter = @conversationId

                                SELECT CAST(i.chat AS int) AS ServiceType,
                                       CAST(c.conversationId AS int) AS ConversationID,
                                       c.clientId AS ClientId,
                                       cm.conexionInfo AS [To],
                                       CAST(i.Inbound_id AS int) AS ACDId,
                                       i.descripcion AS ACDName,
                                       CAST(g.graphic_id AS int) AS ACDGraphicId,
                                       CAST(cm.closeConversationTime AS int) AS [TimeOut],
                                       CAST(cm.answerTimeOut AS int) AS [TimeOutWarning],
                                       i.ExitWrapUpDisposition AS [ExitWrapUpDisposition],
                                       i.tNotas AS [WrapUpTime],
                                       i.ShowCalifWnd,
                                       CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                                       ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                                       ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                                       ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                                       ISNULL(@OldAgentId, 0) AS OldAgentId,
                                       ISNULL(@OldConversationId, 0) AS OldConversationId,
                                       c.agentId AS AgentId,
                                       ISNULL(c.IsAgentLoggingOut, 0) AS IsAgentLoggingOut,
                                       ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments,
                                       c.conversationDate AS ConversationDate
                                FROM ccWhatsAppConversations c
                                LEFT JOIN ccInbound i ON c.inboundId = i.Inbound_id 
                                LEFT JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId    
                                LEFT JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
                                LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                                LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
                                WHERE c.conversationId = @conversationId

                            END ELSE BEGIN -- Campaña
                                SELECT @OldAgentId = conv.agentId,
                                       @OldConversationId = rel.conversationIdBefore
                                FROM ccWhatsAppConversationsRelationshipOut rel 
                                RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
                                WHERE rel.conversationIdAfter = @conversationId

                                SELECT CAST(i.CampType AS int) AS ServiceType,
                                       CAST(c.conversationId AS int) AS ConversationID,
                                       c.clientId AS ClientId,
                                       c.phoneCamp AS [To],
                                       CAST(i.cam_id AS int) AS ACDId,
                                       i.cam_descripcion AS ACDName,
                                       CAST(g.graphic_id AS int) AS ACDGraphicId,
                                       CAST(cm.closeConversationTime AS int) AS [TimeOut],
                                       CAST(cm.answerTimeoutClient AS int) AS [TimeOutWarning],
                                       i.exitAssisted AS [ExitWrapUpDisposition],              
                                       CAST(i.cam_tnotas AS int) AS [WrapUpTime],
                                       i.cam_ShowCalifWnd AS ShowCalifWnd, 
                                       CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                                       ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                                       ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                                       ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                                       ISNULL(@OldAgentId, 0) AS OldAgentId,
                                       ISNULL(@OldConversationId, 0) AS OldConversationId,
                                       c.agentId AS AgentId,
                                       ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments,
                                       c.conversationDate AS ConversationDate
                                FROM ccWhatsAppConversationsOut c
                                LEFT JOIN ccCamps i ON c.camId = i.cam_id 
                                LEFT JOIN contactMeanOut cm ON c.camId = cm.camp_id
                                LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
                                LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
                                LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
                                WHERE c.conversationId = @conversationId
                            END
                        END
                        
                         ELSE IF(@Option = 3)
                        BEGIN
                            IF @CampType = 0 BEGIN -- ACD
                                SELECT CAST(inbound.Inbound_id AS INT) AS Id,
                                       inbound.descripcion AS Name,
                                       ISNULL(configuration.conexionInfo, '''') AS Phone,
                                       CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                                       inbound.tNotas AS WrapUpTime,
                                       CAST(ISNULL(graphics.graphic_id, 1) AS INT) AS GraphicId,
                                       0 AS isMeta
                                FROM ccInbound inbound
                                INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                                INNER JOIN ccWhatsAppNumbers von ON von.inboundId = inbound.Inbound_id
                                INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                                WHERE inbound.Inbound_id = @inboundId

                                UNION ALL

                                SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
                                       inbound.descripcion AS [Name],
                                       ISNULL(numbers.number, '''') AS Phone,
                                       CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                                       inbound.tNotas AS WrapUpTime,
                                       CAST(graphics.graphic_id AS INT) AS GraphicId,
                                       1 AS isMeta
                                FROM ccInbound inbound
                                INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                                INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                                INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id 
                                WHERE inbound.Inbound_id = @inboundId       
                            END ELSE BEGIN
                                SELECT CAST(campaign.cam_id AS INT) AS Id,
                                       campaign.cam_descripcion AS [Name],
                                       ISNULL(configuration.conexionInfo, '''') AS Phone,
                                       CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
                                       CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                                       CAST(graphics.graphic_id AS INT) AS GraphicId,
                                       0 AS isMeta
                                FROM ccCamps campaign
                                INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                                INNER JOIN ccWhatsAppNumbers von ON von.camp_id = campaign.cam_id
                                INNER JOIN contactMeanOut configuration ON campaign.cam_id = configuration.camp_id 
                                WHERE campaign.cam_id = @inboundId

                                UNION ALL

                                SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
                                       campaign.cam_descripcion AS [Name],
                                       ISNULL(configuration.number, '''') AS Phone,
                                       CAST(ISNULL(configurationOut.answerTimeoutClient, 0) AS int) AS TimeOut,
                                       CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                                       CAST(graphics.graphic_id AS INT) AS GraphicId,
                                       1 AS isMeta
                                FROM ccCamps campaign 
                                INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                                INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
                                INNER JOIN contactMeanOut configurationOut ON (campaign.cam_id = configurationOut.camp_id AND campaign.cam_id = @inboundId)
                                WHERE campaign.cam_id = @inboundId
                            END
                        END

                        ELSE IF(@Option = 4)
                        Begin
                            DECLARE @pathFile AS VARCHAR(MAX);
                            DECLARE @filetype AS VARCHAR(5);
                            DECLARE @mensajes TABLE(idMessage VARCHAR(150));
                            DECLARE @tmpMessageConversations TABLE(
                                [messageId] VARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                [conversationId] INT NOT NULL,
                                [timeStampMessage] DATETIME NOT NULL,
                                [originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                [price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                                [messageIdUi] INT NULL,
                                [currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                [typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                [content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                [clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                [vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                [timeStampMessageUTC] DATETIME NULL,
                                [messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                            );


                           INSERT INTO @mensajes
                           SELECT value FROM dbo.fn_RIASplitDelimited(@messagesList, '','');

                                                                            
                          IF (@CampType = 0)
                            BEGIN
                                INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
                                SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
                                FROM ccWAMessagesConversations 
                                WHERE messageId IN (SELECT idMessage FROM @mensajes);
                            END
                            IF (@CampType = 1)
                            BEGIN
                                INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
                                SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
                                FROM ccWAMessagesConversationsOut 
                                WHERE messageId IN (SELECT idMessage FROM @mensajes);
                            END

                            SELECT @pathFile = valor FROM ccSettings WHERE setting_id = 230;

                            SELECT
                                messageId AS MessageId,
                                messageStatus AS Status,
                                originType AS Origin,
                                CASE 
                                    WHEN originType = ''Client'' THEN 3
                                    WHEN originType = ''Agent'' THEN 2
                                    WHEN originType = ''Admin'' THEN 1
                                    ELSE 0 
                                END AS OriginType,
                                timeStampMessage AS [Timestamp],
                                CASE 
                                    WHEN typeMessage IN (''text'', ''template'', ''image'', ''video'') THEN content 
                                    ELSE '''' 
                                END AS Content,
                                typeMessage AS Type,
                                CASE 
                                    WHEN typeMessage IN (''file'', ''image'', ''video'') THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                                    WHEN typeMessage NOT IN (''text'', ''location'', ''file'', ''template'', ''image'', ''video'') THEN content
                                    ELSE '''' 
                                END AS Caption,
                                CASE 
                                    WHEN originType = ''Client'' THEN 
                                        CASE
                                            WHEN typeMessage = ''text'' OR typeMessage = ''location'' OR (typeMessage = ''file'' AND (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2) = '''') THEN ''''
                                            ELSE @pathFile + char(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + char(92) + CAST(conversationId / 1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + char(92) + typeMessage + char(92) + messageId + 
                                                CASE
                                                    WHEN typeMessage = ''video'' THEN ''.mp4''
                                                    WHEN typeMessage = ''image'' THEN ''.jpg''
                                                    WHEN typeMessage = ''audio'' THEN ''.mp3''
                                                    WHEN typeMessage = ''file'' THEN (SELECT SUBSTRING(content, LEN(content) - CHARINDEX(''.'', REVERSE(content)) + 1, LEN(content)))
                                                    ELSE '''' 
                                                END
                                        END
                                    ELSE 
                                        CASE
                                            WHEN typeMessage = ''text'' OR typeMessage = ''location'' OR typeMessage = ''template'' THEN ''''
                                            ELSE content
                                        END
                                END AS [Url],
                                CASE 
                                    WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [FileSize],
                                CASE 
                                    WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 4), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [FileName],
                                CASE 
                                    WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [Address],
                                CASE 
                                    WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [Lat],
                                CASE 
                                    WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [Long],
                                CASE 
                                    WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 4), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [Name],
                                CASE 
                                    WHEN typeMessage = ''location'' THEN ''https://www.google.com/maps/search/'' + (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2) + '','' + (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                                    ELSE '''' 
                                END AS [LocationURL]
                            FROM @tmpMessageConversations
                            ORDER BY Timestamp ASC;
                        END
                                                                                                
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
                                FROM [ccUsers]
                            WHERE [User_id] = @agentId
                        END
                        ELSE IF(@Option = 7)
                        BEGIN
                            IF @CampType = 0 BEGIN
                                -- No se sabe si se va a implementar
                                SELECT -1
                            END 
                            ELSE BEGIN
                                SELECT CAST(ISNULL(maxLimitQueueConversations,99) AS INT) AS MaxLimitQueueConversations 
                                FROM contactMeanOut
                                WHERE conexionInfo = @campaignNumber
                            END 
                        END
                    END'
        EXEC(@sql)

        ------------------------------------------------- END  K020039 IVAN MARTIN----------------------------------------------------------------------------------

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
