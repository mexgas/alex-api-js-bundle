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
SET @versionfix = 17
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
		-------------------------------------------- BEGIN IVAN MARTIN Errores de WhatsApp Version 2023.425.125.4------------------------------
		SET @process = 'Creacion de nueva columna en ccWhatsAppConversations para saber si el agente se deslogeo'
		SET @sql = 'if not exists (select * from sys.columns where name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversations''))
					begin
					    ALTER TABLE ccWhatsAppConversations ADD IsAgentLoggingOut BIT NOT NULL DEFAULT(0)
					end'
		EXEC(@sql)

		SET @process = 'Se agrega el action 16 en ccsp_ConversationWASave para actualizar el valor de la nueva columna. Lineas (424-432)';
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
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
					            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
					            SELECT @conversationIdNew = SCOPE_IDENTITY();

					            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
					                                                                , conversationIdAfter)
					                VALUES (@conversationId, @conversationIdNew);
					            --Save new request by reassign
					            UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

					        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

					        SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
					        RETURN(0);
					    END;
					END;

					IF @action = 2
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
					    , finishedBy = case when @conversationStatus = 10 then 2
					        when @conversationStatus = 17 then 2
					        when @conversationStatus = 18 then 2
					        else 1 end
					    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
					    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
					    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
					    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

					        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
					    BEGIN
					        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
					        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

					        IF @conversationStatus in(13,10,17,18,11) BEGIN
					            DECLARE @conversationDateTemp INT;
					            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId;

					            IF @conversationStatus = 13 BEGIN
					                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
					                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
					                END
					            END
					            ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
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

					IF @action = 3
					BEGIN --save conversation Status
					    UPDATE ccWhatsAppConversations
					            SET
					                --conversationDate = GETDATE(),
					                conversationStatus = @conversationStatus
					    WHERE conversationId = @conversationId;
					END;

					IF @action = 4 BEGIN --save messages from conversation
					    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
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
					        SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
					        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
					    END;

					IF @action = 6
					BEGIN --save agent, assigdate and tqueue
					    declare @agentIdTmp int
					    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

					    IF (@agentIdTmp is null or @agentIdTmp=0)
					    BEGIN
					        UPDATE ccWhatsAppConversations
					                SET agentId = @agentId,
					                assignDate = getdate(),
					                conversationStatus = @conversationStatus
					                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
					        WHERE conversationId = @conversationId;

					        SELECT @conversationId as conversationId
					    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;

					    IF @onQueue = 1 BEGIN
					    UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1) WHERE InboundId = @inboundId
					    END
					    END
					END;

					    IF @action = 7
					    BEGIN --update price message
					        UPDATE ccWAMessagesConversations
					                SET price = @price,
					                    currency = @currency
					        WHERE messageId = @messageId;
					    END;

					    IF @action = 8
					    BEGIN --update status message
					        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					            UPDATE ccWAMessagesConversations
					                    SET messageStatus = @messageStatus
					            WHERE messageId = @messageId;
					        END;
					    END;

					    IF @action = 9
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

					    IF @action = 10
					    BEGIN --drop and insert register by conversationID
					        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
					    END;

					    IF @action = 11
					    BEGIN --register desconnection agent by conversationID
					        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
					    END;

					    IF @action = 12
					    BEGIN --Obtain conversationsWA post MCS reset

					        declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
					        UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

					        declare @from as datetime;-- = ''01-07-2022'';
					        select @from = convert(datetime,convert(varchar(11),getdate()))
					        set @from=DATEADD(dd,-1,@from);
					            select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
					            ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
					            from ccWhatsAppConversations A
					            left join ccWAMessagesConversations B on A.conversationId = B.conversationId
					            left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
					            --where B.conversationId is null
					            where A.requestDate >= @from 
					                and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
					            order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
					    END;
					    IF @action = 13
					    BEGIN ---Obtain agents ON STATUS READY
					        WITH agents
					        AS(
					            SELECT c.User_id, c.fecha, c.currentStatus
					            FROM ccLogAgentesDia c
					            INNER JOIN 
					            (
					                SELECT User_id, MAX(fecha) max_time
					                FROM ccLogAgentesDia
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

					    IF @action = 14
					    BEGIN --register desconnection MCS
					        INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
					    END;

						IF @action = 15
					    BEGIN --update content message
					        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					            UPDATE ccWAMessagesConversations
					                    SET content = @content
					            WHERE messageId = @messageId;
					        END;
					    END;

						IF @action = 16
					    BEGIN --update agent status for reassigning error message
					        IF EXISTS(SELECT 0 FROM ccWhatsAppConversations WHERE conversationId = @conversationId)
							BEGIN
					            UPDATE ccWhatsAppConversations
					            SET IsAgentLoggingOut = @IsAgentLoggingOut
					            WHERE conversationId = @conversationId;
					        END;
					    END;
					END;';
		EXEC(@sql);

		SET @process = 'Se actualiza ccsp_MultimediaCommon para obtener el valor de la nueva columna. Linea (511)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
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
				                select messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus
				                FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
				            END
				            if(@CampType = 1)
				            BEGIN
				                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus) 
				                select messageId, conversationId, timeStampMessage, originType
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
				    END'
		EXEC(@sql)

		-------------------------------------------- END IVAN MARTIN Errores de WhatsApp Version 2023.425.125.4------------------------------
		
		
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


