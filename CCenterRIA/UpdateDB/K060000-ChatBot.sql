/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: K060000-ChatBot

Database: CCenterRia
Required version: 125.33

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own database)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 6
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF 1=1
BEGIN
	BEGIN TRAN
	BEGIN TRY

-------------------------------------------------- Begin David Medina -----------------------------------------------------------------------------------
--------------------------------------------------------- DDL -------------------------------------------------------------------------------------------
---------------------------------------------------- k060036|k060037 ------------------------------------------------------------------------------------
-------------------------------------------------------- Tablas -----------------------------------------------------------------------------------------
SET @process = 'Creación de nueva tabla IVR para separar el IVR de la tabla chatbot'
SET @sql = 'if not exists (select * from sys.tables where name = N''IVR'')
			begin
				create table IVR(
				IVRID smallint IDENTITY(1,1) PRIMARY KEY,
				IVRName varchar(40),
				IVR varchar(max));
			end'
EXEC(@sql)

SET @process = 'Creación de tabla nueva de chatbot y relación de tabla chatbot a IVR'
SET @sql = 'if not exists (select * from sys.tables where name = N''Chatbot'')
			 begin
				create table Chatbot (
				ID int IDENTITY(1,1) PRIMARY KEY,
				ChatBotName	varchar(40),
				IVRID smallint NULL,
				AssociatedPhone	varchar(20) NULL,
				CreationDate	date,
				LastModificationDate	date,
				Status	bit,
				CONSTRAINT FK_Chatbot_IVR FOREIGN KEY (IVRID) REFERENCES IVR(IVRID) ON DELETE SET NULL)
			end'
EXEC(@sql)

--------------------------------------------------------- SPs ------------------------------------------------------------------------------------------
set @process = 'delete de ccsp_ChatbotManagement por si ya existe'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_ChatbotManagement'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_ChatbotManagement]
        END'
EXEC(@sql)

set @process = 'Creación de SP para gestión de chatbots'
set @sql = 'CREATE proc [dbo].[ccsp_ChatbotManagement]	 
@type int,
@ChatbotName varchar(40) = null,
@TemplateId smallint = null,
@AssociatedNumber varchar(20) = null

as
set nocount on

if @type=1 
begin 
	select id as ChatbotId, ChatBotName as ChatbotName, AssociatedPhone as AssociatedNumber,  FORMAT(CreationDate, ''dd/MM/yyyy'') as CreationDate, 
	FORMAT(LastModificationDate, ''dd/MM/yyyy'') as LastModificationDate, status as ChatbotStatus from Chatbot 
	return(0) 
end 

if @type=2
begin
	WITH DistinctAssociatedPhone AS (
    SELECT id AS ChatbotId, AssociatedPhone AS AssociatedNumber, ROW_NUMBER() OVER (PARTITION BY AssociatedPhone ORDER BY id) AS rn FROM Chatbot WHERE AssociatedPhone IS NOT NULL
	)
	SELECT ChatbotId, AssociatedNumber FROM DistinctAssociatedPhone WHERE rn = 1; 
end

if @type=3 
begin
	select distinct IVRID as IVRID , IVRName as IVRTemplate from IVR  
	return(0) 
end

if @type=4
begin
	if exists(select LTRIM(RTRIM(ChatBotName)) from Chatbot where Status=1 and ChatBotName=LTRIM(RTRIM(@ChatBotName))) begin
		select -1 as result
		return(0)
	end
	insert into ChatBot(ChatBotName, IVRID, AssociatedPhone, CreationDate, LastModificationDate, Status) values (@ChatbotName, @TemplateId, @AssociatedNumber, getdate(), getdate(), 1)
	select top 1 ID as result from chatbot order by ID desc
	return(0)
end '
EXEC(@sql)
------------------------------------------------------ End David Medina ---------------------------------------------------------------------------------

	--Es necesario realizar un merge a mano con el ultimo SP 
	SET @process = 'K060005 Alter procedure ccsp_ConversationWASave to register the chatbotId and WhatsAppConversationId when creating a new WhatsApp conversation'
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
										, @chatBotConversationId BIGINT = 0
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
								IF (@chatBotConversationId != 0)
								BEGIN
									EXEC ccsp_GalateaChatBotAdmin @action = 6, @chatBotConversationId = @chatBotConversationId, @WAConversationId = @conversationId, @camType = 0;
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

								IF (@chatBotConversationId != 0)
								BEGIN
									UPDATE ChatBotWhatsAppConversation SET WhatsAppConversationId = @conversationIdNew
									WHERE ChatBotConversationId = @chatBotConversationId AND WhatsAppConversationId = @conversationId AND CampType = 0;
								END;
					      
								--Save new request by reassign
            UPDATE ccWAOperatingSummary SET Request = (Request + 1)
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
					            SET
					                --conversationDate = GETDATE(),
					                conversationStatus = @conversationStatus
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
					END;'
	EXEC(@sql)


	SET @process = 'K060011-WhatsApp entrada->Histórico al asignar conversación de ChatBot a número de WhatsApp entrada, se agrega la consulta
	para obtener las conversaciones del chatbot'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
					@option SMALLINT, 
					@clientNum VARCHAR(15) = '''', 
					@conversationId AS INT = 0, 
					@inboundId AS SMALLINT = 0, 
					@serviceType AS SMALLINT = 0,
					@campType AS INT = 0
		            AS
		            BEGIN
		                IF @option = 1 --whatsapp, get conversation ids
		                BEGIN
							DECLARE @tempId INT = 0
							IF @campType = 0 -- INBOUND
							BEGIN
								SELECT conversationId AS ConversationId,
									   @campType AS CampType,
									   assignDate AS Date
								FROM ccWhatsAppConversations
								WHERE clientId = @clientNum AND assignDate IS NOT NULL
								GROUP BY conversationId, assignDate
							END
							ELSE
							BEGIN  -- OUTBOUND
								SELECT conversationId AS ConversationId,
									   @campType AS CampType,
									   assignDate AS Date
								FROM ccWhatsAppConversationsOut
								WHERE clientId = @clientNum AND assignDate IS NOT NULL
								GROUP BY conversationId, assignDate
							END
		                END

		                IF @option = 2 --whatsapp, get acdId by conversation id
		                BEGIN
							IF @campType = 0
							BEGIN
								SELECT CAST(inboundId AS INT)
								FROM [CCenterRIA].[dbo].[ccWhatsAppConversations]
								WHERE conversationId = @conversationId
							END
							ELSE
							BEGIN
								SELECT CAST(camId AS INT)
								FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsOut]
								WHERE conversationId = @conversationId
							END
		                END

		                IF @option = 3 --get data conversation
		                BEGIN
		                    DECLARE @OldAgentId INT = 0
		                    DECLARE @OldConversationId INT = 0

		                    SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
		                    FROM ccWhatsAppConversationsRelationship rel
		                    RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
		                    WHERE rel.conversationIdAfter = @conversationId

		                    SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
		                            graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
		                        [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
		                        [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
		                        OldConversationId, c.agentId AS AgentId
		                    FROM ccInbound i
		                    INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
		                    INNER JOIN ccWhatsAppConversations c ON (
		                            c.inboundId = i.Inbound_id
		                            AND c.conversationId = @conversationId
		                            )
		                    INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
		                    LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
		                    LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
		                    WHERE i.chat = @serviceType
		                        AND i.Inbound_id = @inboundId

		                END

		                IF @option = 4 --get messages from conversation id
		                BEGIN
							DECLARE @filetype AS VARCHAR(5)
							DECLARE @camp_acd_id INT = 0, @conversationChatBotId BIGINT = 0;
							DECLARE @tmpChatbotRelation TABLE (ConversationChatBotId BIGINT, ContactName VARCHAR(150), ClientNumber VARCHAR(200), ChatBotName VARCHAR(255) );

							IF @campType = 0
							BEGIN
								INSERT INTO @tmpChatbotRelation 
								EXEC dbo.ccsp_GalateaChatBotAdmin @action=7,
								@camType=0, -- int
								@WAConversationId=@conversationId

								SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations WHERE conversationId = @conversationId)
								SET @conversationChatBotId = (SELECT tcr.ConversationChatBotId FROM @tmpChatbotRelation AS tcr)

								SELECT CAST(cbcm.MessageId AS VARCHAR(MAX)) AS MessageId
								, cbcm.MessageStatus AS STATUS
								, cbcm.OriginType AS Origin
								,CASE 
								WHEN originType = ''Client''
									THEN 3
								WHEN originType = ''Chatbot''
									THEN 4
								ELSE 0
								END AS OriginType,
								cbcm.Date AS Timestamp,
								CASE 
								WHEN typeMessage <> ''text''
									THEN ''''
								ELSE cbcm.Message
								END AS Content
								,cbcm.TypeMessage AS Type
								,CASE 
				                    when typeMessage not in( ''text'' ,''location'', ''file'', ''template'') then cbcm.Message
				                    else
				                        case
				                            when typeMessage = ''file'' then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(cbcm.Message,''|'') where id = 1),'':'') where id=2) 
				                                    else '''' end
				                    end as Caption
								,CASE 
								WHEN originType = ''Client''
									THEN CASE 
											WHEN cbcm.TypeMessage = ''text''
												OR cbcm.TypeMessage = ''location''
												THEN ''''
											ELSE CHAR(92) + CHAR(92) + ''ChatBot'' + CHAR(92) + CHAR(92) + ''INBOUND'' + CHAR(92) + CHAR(92) + cast(cbcm.ConversationChatBotId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(cbcm.ConversationChatBotId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
												cbcm.TypeMessage + CHAR(92) + CHAR(92) + CAST(cbcm.MessageId AS VARCHAR(MAX))  + CASE 
													WHEN cbcm.TypeMessage = ''video''
														THEN ''.mp4''
													WHEN cbcm.TypeMessage = ''image''
														THEN ''.jpg''
													WHEN cbcm.TypeMessage = ''audio''
														THEN ''.mp3''
													WHEN cbcm.TypeMessage = ''file''
														THEN (
																select substring(cbcm.Message, LEN(cbcm.Message) - CHARINDEX(''.'',REVERSE(cbcm.Message))+1, len(cbcm.Message))
																)
													ELSE ''''
													END
											END
									ELSE 
									CASE 
									WHEN cbcm.TypeMessage = ''text''
										OR cbcm.TypeMessage = ''location''
										THEN ''''
									ELSE cbcm.Message
									END
									END AS [Url]
									,CASE 
									WHEN cbcm.TypeMessage = ''location''
										THEN (
												SELECT value
												FROM dbo.fn_RIASplitDelimited((
															SELECT value
															FROM dbo.fn_RIASplitDelimited(cbcm.Message, ''|'')
															WHERE id = 1
															), '':'')
												WHERE id = 2
												)
									ELSE ''''
									END AS [Address]
									,CASE 
									WHEN cbcm.TypeMessage = ''location''
										THEN (
												SELECT value
												FROM dbo.fn_RIASplitDelimited((
															SELECT value
															FROM dbo.fn_RIASplitDelimited(cbcm.Message, ''|'')
															WHERE id = 2
															), '':'')
												WHERE id = 2
												)
									ELSE ''''
									END AS [Lat]
									,CASE 
									WHEN typeMessage = ''location''
										THEN (
												SELECT value
												FROM dbo.fn_RIASplitDelimited((
															SELECT value
															FROM dbo.fn_RIASplitDelimited(cbcm.Message, ''|'')
															WHERE id = 3
															), '':'')
												WHERE id = 2
												)
									ELSE ''''
									END AS [Long]
									,CASE 
									WHEN typeMessage = ''location''
										THEN (
												SELECT value
												FROM dbo.fn_RIASplitDelimited((
															SELECT value
															FROM dbo.fn_RIASplitDelimited(cbcm.Message, ''|'')
															WHERE id = 4
															), '':'')
												WHERE id = 2
												)
									ELSE ''''
									END AS [Name]
									,CASE 
									WHEN typeMessage = ''location''
										THEN ''https://www.google.com/maps/search/'' + (
												SELECT value
												FROM dbo.fn_RIASplitDelimited((
															SELECT value
															FROM dbo.fn_RIASplitDelimited(cbcm.Message, ''|'')
															WHERE id = 2
															), '':'')
												WHERE id = 2
												) + '','' + (
												SELECT value
												FROM dbo.fn_RIASplitDelimited((
															SELECT value
															FROM dbo.fn_RIASplitDelimited(cbcm.Message, ''|'')
															WHERE id = 3
															), '':'')
												WHERE id = 2
												)
									ELSE ''''
									END AS [LocationURL]
									,crig.graphic_id AS GraphicId,
									CAST(1 AS TINYINT) AS ChatBot
								FROM dbo.ChatBotConversationMessage AS cbcm 
								LEFT JOIN dbo.ccRIAInboundGraph AS crig ON crig.Inbound_id = @camp_acd_id
								WHERE cbcm.ConversationChatBotId = @conversationChatBotId
								UNION
								SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
		                        WHEN originType = ''Client''
		                            THEN 3
		                        WHEN originType = ''Agent''
		                            THEN 2
		                        WHEN originType = ''Admin''
		                            THEN 1
		                        ELSE 0
		                        END AS OriginType, timeStampMessage AS [Timestamp], CASE 
		                        WHEN typeMessage <> ''text''
		                            THEN ''''
		                        ELSE content
		                        END AS Content, typeMessage AS Type, 
								CASE 
				                    when typeMessage not in( ''text'' ,''location'', ''file'', ''template'') then content
				                    else
				                        case
				                            when typeMessage = ''file'' then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) 
				                                    else '''' end
				                    end as Caption, CASE 
		                        WHEN originType = ''Client''
		                            THEN CASE 
		                                    WHEN typeMessage = ''text''
		                                        OR typeMessage = ''location''
		                                        THEN ''''
		                                    ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''INBOUND'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
		                                        typeMessage + CHAR(92) + CHAR(92) + messageId + CASE 
		                                            WHEN typeMessage = ''video''
		                                                THEN ''.mp4''
		                                            WHEN typeMessage = ''image''
		                                                THEN ''.jpg''
		                                            WHEN typeMessage = ''audio''
		                                                THEN ''.mp3''
		                                            WHEN typeMessage = ''file''
		                                                THEN (
																select substring(content, LEN(content) - CHARINDEX(''.'',REVERSE(content))+1, len(content))
		                                                        )
		                                            ELSE ''''
		                                            END
		                                    END
		                        ELSE CASE 
		                                WHEN typeMessage = ''text''
		                                    OR typeMessage = ''location''
		                                    THEN ''''
		                                ELSE content
		                                END
		                        END AS [Url], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 1
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Address], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Lat], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Long], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 4
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Name], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN ''https://www.google.com/maps/search/'' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    ) + '','' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [LocationURL],
								graphics.graphic_id AS GraphicId,
								CAST(0 AS TINYINT) AS ChatBot
								FROM ccWAMessagesConversations
								LEFT JOIN ccRIAInboundGraph graphics ON Inbound_id = @camp_acd_id
								WHERE conversationId = @conversationId
								ORDER BY TIMESTAMP ASC
							END
							ELSE
							BEGIN
								SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut WHERE conversationId = @conversationId)

								SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
		                        WHEN originType = ''Client''
		                            THEN 3
		                        WHEN originType = ''Agent''
		                            THEN 2
		                        WHEN originType = ''Admin''
		                            THEN 1
		                        ELSE 0
		                        END AS OriginType, timeStampMessage AS [Timestamp], CASE 
		                        WHEN typeMessage IN (''text'', ''template'')
		                            THEN content 
		                        ELSE ''''
		                        END AS Content, typeMessage AS Type, CASE 
		                        WHEN typeMessage NOT IN (''text'', ''location'', ''template'')
		                            THEN content
		                        ELSE ''''
		                        END AS Caption, CASE 
		                        WHEN originType = ''Client''
		                            THEN CASE 
		                                    WHEN typeMessage = ''text''
		                                        OR typeMessage = ''location''
		                                        THEN ''''
		                                    ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
		                                        typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
		                                            WHEN typeMessage = ''video''
		                                                THEN ''mp4''
		                                            WHEN typeMessage = ''image''
		                                                THEN ''jpg''
		                                            WHEN typeMessage = ''audio''
		                                                THEN ''mp3''
		                                            WHEN typeMessage = ''file''
		                                                THEN (
		                                                        SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
		                                                        )
		                                            ELSE ''''
		                                            END
		                                    END
		                        ELSE CASE 
		                                WHEN typeMessage = ''text''
		                                    OR typeMessage = ''location''
											OR typeMessage = ''template''
		                                    THEN ''''
		                                ELSE content
		                                END
		                        END AS [Url], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 1
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Address], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Lat], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Long], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 4
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Name], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN ''https://www.google.com/maps/search/'' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    ) + '','' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [LocationURL],
								graphics.graphic_id AS GraphicId
								
								FROM ccWAMessagesConversationsOut
								LEFT JOIN ccRIACampsGraph graphics ON cam_id = @camp_acd_id
								WHERE conversationId = @conversationId
								ORDER BY TIMESTAMP ASC
							END
		                    
		                END

		                IF @option = 5 --get if conversation is reassigned
		                BEGIN
							IF @campType = 0
							BEGIN
								SELECT CASE 
		                            WHEN EXISTS (
		                                    SELECT *
		                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship]
		                                    WHERE conversationIdAfter = @conversationId
		                                    )
		                                THEN CAST(1 AS BIT)
		                            ELSE CAST(0 AS BIT)
		                            END
							END
							ELSE
							BEGIN
								SELECT CASE 
		                            WHEN EXISTS (
		                                    SELECT *
		                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut]
		                                    WHERE conversationIdAfter = @conversationId
		                                    )
		                                THEN CAST(1 AS BIT)
		                            ELSE CAST(0 AS BIT)
		                            END
							END
		                END
		            END'
	EXEC(@sql)

	--Alter Falta Realizar merge
	SET @process = 'K060013-Buscador-Conversaciones ChatBot, se agreca type 7 para guardar los nodos del chatbot'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
							, @supervisor     VARCHAR(255) = ''''
							, @template       VARCHAR(255) = ''''
							, @ScoreTemplate  INT          = 0
							, @type           INT                                                
	AS
	BEGIN

	DECLARE @xml XML, @dateStart DATETIME;
	DECLARE @info VARCHAR(255);
	DECLARE @infoEscape VARCHAR(MAX);
	DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
	SET @charEscape = ''"|''''''''|<|>|&'';
	SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

	DECLARE @existAttached BIT, @numInteracion SMALLINT;
	IF @type = 1
	BEGIN--CHAT
		SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
			+ ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid) 
		+ ''" CType="1'' 
		+ ''" C01="'' + CONVERT(VARCHAR(MAX), chatId) 
		+ ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, '''')) 
		+ ''" C03="'' + CONVERT(VARCHAR(MAX), domain) 
		+ ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')) 
		+ ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting) 
		+ ''" C06="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalif.[Description], ''N/A'')) 
		+ ''" C07="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalifsub.califSubdesc, ''N/A'')) 
		+ ''" C08="'' + CONVERT(VARCHAR(MAX), clientname) 
		+ ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
		+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
		+ ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
		+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
		+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], '''')) 
		+ ''"/>'')
				, @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
																LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
																LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
																LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = ccRIAChats.disposition
																LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = ccRIAChats.subdisposition
																									AND ccRIAChats.subdisposition <> 0
		WHERE chatId = @conversationId
				AND chatStatus = 4              

	END;
	ELSE IF @type = 3
	BEGIN--EMAIL
		SELECT @existAttached = CASE WHEN COUNT(*) > 0
								THEN 1 ELSE 0
								END FROM attached
		WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
		SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
		--Replaza los caracteres por los comunes
		SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
		SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
																INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

		SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
			+ ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
		+ ''" CType="1'' 
		+ ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId) 
		+ ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
		+ ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
		+ ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
		+ ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
		+ ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' ''))) 
		+ ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
		+ ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, ''''))) 
		+ ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
		+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
		+ ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached) 
		+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
		+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
		+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
		+ ''" C15="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
		+ ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
		+ ''"/>'')
				, @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
																	INNER JOIN message b ON a.conversationid = b.conversationid
																	LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
																	LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
																	LEFT OUTER JOIN relationmessageDisposition e ON e.messageId = b.messageId
																	LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
																	LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
																									AND e.subdispositionId <> 0
		WHERE a.conversationId = @conversationId
		GROUP BY a.conversationId
				, a.inboundid;

	END;
	ELSE IF @type = 4
	BEGIN--Twitter
		SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
		WHERE conversationTwitterId = @conversationId;

		SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
			+ ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
		+ ''" CType="1'' 
		+ ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId) 
		+ ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
		+ ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
		+ ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
		+ ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
		+ ''" C06="'' + MAX(a.screenNameClient) 
		+ ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
		+ ''" C08="'' + MAX(a.screenNameInbound) 
		+ ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
		+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
		+ ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
		+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
		+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
		+ ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
		+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
		+ ''"/>'')
				, @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
																INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
																LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
																LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
																LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
																LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
																LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
																									AND e.subdispositionId <> 0
		WHERE a.conversationTwitterId = @conversationId
		GROUP BY a.conversationTwitterId
				, a.inboundid;
	END;
	ELSE IF @type = 5 BEGIN --WhatsApp In
		SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
			+ ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid) 
		+ ''" CType="5'' 
		+ ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
		+ ''" C02="'' + ISNULL(inbound.descripcion, '''') 
		+ ''" C03="'' + ISNULL(ccusers.[Login], '''') 
		+ ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
		+ ''" C05="'' + clientId 
		+ ''" C06="'' + CONVERT(VARCHAR(MAX), tConversation) 
		+ ''" C07="'' + ISNULL(cctipocalif.[Description], ''N/A'') 
		+ ''" C08="'' + ISNULL(cctipocalifsub.califSubdesc, ''N/A'') 
		+ ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
		+ ''" C10="'' + phoneACD 
		+ ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
		+ ''" C12="'' + ISNULL(@supervisor, '''') 
		+ ''" C13="'' + ISNULL(@template, '''') 
		+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
		+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.ChatBotConversationId, 0))
		+ ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.ChatBotId, 0))
		+ ''" C17="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.ChatBotName, 0))
		+ ''"/>'')
				, @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
																		LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
																		LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
																		LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
																		LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
																		LEFT OUTER JOIN ChatBotWhatsAppConversation cbwac ON cbwac.WhatsAppConversationId = a.conversationId and cbwac.CampType = 0
																		LEFT OUTER JOIN ChatBotConversation cbc ON cbc.ChatBotConversationId = cbwac.ChatBotConversationId
		  WHERE A.conversationId = @conversationId;

	END;
	ELSE IF @type = 6 BEGIN --WhatsApp Out

		SELECT @xml = CONVERT(XML, ''<R06 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
			+ ''" CID="'' + CONVERT(VARCHAR(MAX), A.camId) 
		+ ''" CType="6'' 
		+ ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
		+ ''" C02="'' + ISNULL(c.cam_descripcion, '''') 
		+ ''" C03="'' + ISNULL(ccusers.[Login], '''') 
		+ ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
		+ ''" C05="'' + clientId 
		+ ''" C06="'' + CONVERT(VARCHAR(MAX), isnull(tConversation,0)) 
		+ ''" C07="'' + ISNULL(disposition.[Description], ''N/A'') 
		+ ''" C08="'' + ISNULL(subDisposition.califSubdesc, ''N/A'') 
		+ ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
		+ ''" C10="'' + phoneCamp 
		+ ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
		+ ''" C12="'' + ISNULL(@supervisor, '''') 
		+ ''" C13="'' + ISNULL(@template, '''') 
		+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
		+ ''"/>'')
				, @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversationsOut A
																		LEFT OUTER JOIN ccCamps c ON c.cam_id=A.camId
																		LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
																		LEFT OUTER JOIN ccTipoCalifOUT disposition ON disposition.calif_id= A.disposition
																		LEFT OUTER JOIN ccTipoCalifSubOUT subDisposition ON subDisposition.califSub_id = A.subdisposition
		WHERE A.conversationId = @conversationId;

	END;
	ELSE IF @type = 7 BEGIN --ChatBotIn
		SELECT @xml = CONVERT(XML, ''<R07 CDATE="'' + CONVERT(VARCHAR(23), cbc.FirstMessageTime, 126) 
			+ ''" CID="N/A'' 
		+ ''" CType="7'' 
		+ ''" C01="'' + CONVERT(VARCHAR(MAX), cbc.ChatBotConversationId) 
		+ ''" C02="N/A''
		+ ''" C03="N/A''
		+ ''" C04="N/A''
		+ ''" C05="'' + cbc.ClientNumber 
		+ ''" C06="'' + CONVERT(VARCHAR(MAX), ConversationTime) 
		+ ''" C07="N/A'' 
		+ ''" C08="N/A''
		+ ''" C09="'' 
		+ ''" C10="'' 
		+ ''" C11="''
		+ ''" C12="''
		+ ''" C13="''
		+ ''" C14="''
		+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.ChatBotConversationId, 0))
		+ ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.ChatBotId, 0))
		+ ''" C17="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.ChatBotName, 0))
		+ ''" C18="'' + CONVERT(VARCHAR(MAX), ISNULL(cbc.CampIdTransfered, 0))
		+ ''"/>'')
				, @dateStart = cbc.FirstMessageTime FROM ChatBotConversation cbc 
													LEFT OUTER JOIN ChatBotWhatsAppConversation cbwac 
													ON cbc.ChatBotConversationId = cbwac.ChatBotConversationId
		  WHERE cbc.ChatBotConversationId = @conversationId;

	END;

	DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
	DECLARE @parameterDefinition NVARCHAR(MAX);

	SELECT @tableName = tableName
			, @tableNameHistory = tableNameHistory
			, @columnId = columnId FROM ccFinderServices
	WHERE id =  @type;

	SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

	IF @xml IS NOT NULL
	BEGIN        

		SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
		BEGIN
			UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
		END
		else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
		BEGIN
			UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
		END
		else begin
			INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
		end     
		'';
                            
	END
	else begin
			SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
		BEGIN
			UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
		END
		else begin
			INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
		end '';
	end


		EXECUTE sp_executesql
				@sql
				, @parameterDefinition
				, @conversationId = @conversationId
				, @xml = @xml
				, @dateStart = @dateStart;

	END;'
	EXEC(@sql)

	SET @process = 'K060015-Buscador Conversaciones ChatBot transferidas a campaña WhatsApp de entrada, se agrega action 6 y 7 '
	SET @sql = 'CREATE ROCEDURE [dbo].[ccspGalatea_Finder] 
				@action INT, 
				@userId INT = 0, 
				@conversationId BIGINT = 0,
				@isSuperUser bit=0
				AS
				IF @action = 1
				    BEGIN--trae el nombre de la base de datos en BX
				    if @isSuperUser =0 begin

				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
				                                        AND WGCam.Tipo = 1
				            WHERE Wguser.User_id = @userId
				            UNION
				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
				                                            AND WGCam.Tipo = 0
				            WHERE Wguser.User_id = @userId;
				        end
				        else begin
				        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
				        UNION
				        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
				        end
				        RETURN 0;
				END;
				IF @action = 2
				    BEGIN
				    if @isSuperUser =0 begin
				        WITH WgId
				            AS (SELECT IDWG
				                FROM ccRIAWorkGroupUsers Wguser
				                WHERE Wguser.User_id = @userId)
				            SELECT DISTINCT 
				                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
				                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
				                                        AND TipoUser_id = 1;
				end
				else begin
				        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				        from ccUsers where TipoUser_id = 1;
				end
				        RETURN 0;
				END;
				IF @action = 3
				         BEGIN--Informacion de la conversacion de whatsApp
				               SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversations A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.inboundId, graph.graphic_id, A.phoneACD, A.clientId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 4
				         BEGIN--Informacion de la conversacion de whatsApp out
				               SELECT A.ConversationID, A.camId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneCamp AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.cam_descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversationsOut A
				                  LEFT JOIN ccCamps B ON A.camId = B.cam_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = A.camId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.camid, graph.graphic_id, A.phoneCamp, A.clientId, B.cam_descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 5
				         BEGIN--Informacion de la conversacion de Chat
				                SELECT A.ChatId AS ConversationID, A.inboundId AS CampaignId, A.userId AS AgentID, ISNULL(B.descripcion, ''N/A'') AS CampaignName,
							   ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, 
							   C.Login AS UserName, A.clientName as Client, ISNULL(A.chatDate, A.requestDate) as DateStart,
							   (cast(sum(A.tChatting) / 3600 as varchar(10)) + '':'' + 
				                right(''0'' + cast((sum(A.tChatting) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                right(''0'' + cast(sum(A.tChatting) % 60 as varchar(10)), 2)) as Duration
				             FROM ccRIAChats A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccUsers C ON A.userId = C.User_id
				             WHERE A.chatId = @conversationId
				             group by A.chatId, A.inboundId, A.userId, A.userId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc,
							 chatDate, requestDate, A.userId, C.Login, tChatting, clientName;

				             RETURN 0;
				     END;
				IF @action = 6
					BEGIN--Informacion de la conversacion de chatbot
							SELECT A.ChatBotConversationId AS conversationId, A.ChatBotNumber AS contactName, 
							A.ClientNumber AS clientNumber, a.ChatBotId as chatBotId, a.ChatBotName AS chatBotName, 
							A.CampIdTransfered AS campIdTransfered, A.FirstMessageTime as firstMessageTime
							,(cast(sum(A.conversationTime) / 3600 as varchar(10)) + '':'' + 
				            right(''0'' + cast((sum(A.conversationTime) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				            right(''0'' + cast(sum(A.conversationTime) % 60 as varchar(10)), 2)) as conversationTime,
							ISNULL(B.whatsAppConversationId,0) as whatsAppConversationId
							FROM  ChatBotConversation A
							LEFT JOIN ChatBotWhatsAppConversation B on A.ChatBotConversationId = B.ChatBotConversationId
				            WHERE A.ChatBotConversationId = @conversationId
				            group by A.ChatBotConversationId, A.ChatBotNumber,  A.ClientNumber, a.ChatBotId, a.ChatBotName, A.CampIdTransfered, A.FirstMessageTime, B.WhatsAppConversationId 
				            RETURN 0;
				     END;
				IF @action = 7 BEGIN
					select id as ChatBotId, projectName as ChatBotName from AzureKnowledge
				END;'
	EXEC(@sql)


	SET @process = 'K060024-Id global Chatbot-WhatsApp se actualiza SP para crear y actualizar los IDs globales del chatbot'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppGlobalIds]  
					 @ConversationType TINYINT = -1,
					 @ConversationId INT = 0,
					 @MessageId VARCHAR(MAX) = '''',
					 @AssociatedNumber VARCHAR (30), 
					 @ClientNumber VARCHAR(30)
				AS  
				SET NOCOUNT ON;  

					IF @ConversationType = 0 AND NOT EXISTS(SELECT 1 FROM ccWhatsAppConversations WHERE conversationId = @ConversationId)
					BEGIN
						RAISERROR(''ERROR. No existe una conversación de entrada con el id especificado'', 18, 1);
						RETURN(0);
					END;
					ELSE IF @ConversationType = 1 AND NOT EXISTS(SELECT * FROM ccWhatsAppConversationsOut WHERE conversationId = @ConversationId)
					BEGIN
						RAISERROR(''ERROR. No existe una conversación de salida con el id especificado'', 18, 1);
						RETURN(0);
					END;
					ELSE IF @ConversationType = 2 AND NOT EXISTS(SELECT * FROM ChatBotConversation WHERE ChatBotConversationId = @ConversationId)
					BEGIN
						RAISERROR(''ERROR. No existe una conversación de chatbot con el id especificado'', 18, 1);
						RETURN(0);
					END;
					ELSE
					BEGIN
						DECLARE @originType VARCHAR(20) = '''';
						DECLARE @firstMessageDateFromAgent DATETIME = NULL;
						DECLARE @messageStatus VARCHAR(20) = '''';
						DECLARE @firstMessageConversationIdFromAgent INT = NULL;
						DECLARE @firstMessageConversationTypeFromAgent TINYINT = NULL;
						DECLARE @isBilled BIT = 0;

						IF @ConversationType = 0 
						BEGIN
							SET @originType = (SELECT originType FROM ccWAMessagesConversations WHERE messageId = @MessageId);
							SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
							FROM ccWAMessagesConversations
							WHERE messageId = @MessageId AND @originType = ''Agent'';
						END;
						ELSE IF @ConversationType = 1 
						BEGIN
							SET @originType = (SELECT originType FROM ccWAMessagesConversationsOut WHERE messageId = @MessageId);
							SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
							FROM ccWAMessagesConversationsOut
							WHERE messageId = @MessageId AND @originType = ''Agent'';
						END;
						ELSE IF @ConversationType = 2 
						BEGIN
							SET @originType = (SELECT originType FROM ChatBotConversationMessage WHERE message_uuid = @MessageId);
							SELECT @firstMessageDateFromAgent = [Date], @messageStatus = messageStatus
							FROM ChatBotConversationMessage
							WHERE message_uuid = @MessageId AND @originType = ''Chatbot'';
						END;

						DECLARE @globalId INT = (SELECT MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber);

						IF (@originType = ''Agent'' OR @originType = ''Chatbot'')  AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'')
						BEGIN
							SET @firstMessageConversationIdFromAgent = @ConversationId;
							SET @firstMessageConversationTypeFromAgent = @ConversationType;
							SET @isBilled = 1;
						END
						ELSE
						BEGIN
							SET @firstMessageDateFromAgent = NULL
						END

						IF @globalId IS NULL
						BEGIN
							INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
							VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

							SET @globalId = SCOPE_IDENTITY();
						END

						DECLARE @TempFirstMessageDate DATETIME = (SELECT FirstMessageDateFromAgent FROM ccWhatsAppGlobalIds WHERE GlobalId = @globalId);
						
						--Update if message status changes
						IF(@originType = ''Agent'' OR @originType = ''Chatbot'') AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'') AND @globalId IS NOT NULL
						BEGIN
							UPDATE ccWhatsAppGlobalIds SET IsBilled = 1 WHERE GlobalId = @globalId
						END

						IF DATEDIFF(HOUR, @TempFirstMessageDate, GETDATE()) >= 24 
						BEGIN 
							INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
							VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

							SET @globalId = SCOPE_IDENTITY();	
						END

						-- If the message is from agent or chatbot update the date 
						IF (@originType = ''Agent'' OR @originType = ''Chatbot'') AND @TempFirstMessageDate IS NULL
						BEGIN
							UPDATE ccWhatsAppGlobalIds SET FirstMessageDateFromAgent = @firstMessageDateFromAgent,
														   FirstMessageConversationIdFromAgent =  @ConversationId,
														   FirstMessageConversationTypeFromAgent = @ConversationType,
														   IsBilled = @isBilled
							WHERE GlobalId = @globalId;
						END
						-- Insert into ccWhatsAppGlobalIdsRelationship
						IF @globalId != 0 AND NOT EXISTS(SELECT GlobalId FROM ccWhatsAppGlobalIdsRelationship WHERE GlobalId = @globalId AND ConversationId = @ConversationId AND @ConversationType = ConversationType)
						BEGIN
							INSERT INTO ccWhatsAppGlobalIdsRelationship(GlobalId, ConversationId, ConversationType)
							VALUES (@globalId, @ConversationId, @ConversationType)
						END

						RETURN(1)
					END
				SET NOCOUNT OFF'
	EXEC(@sql)

	---Todo Falta realizar merge
	SET @process = 'K060005 Alter procedure ccsp_MultimediaCommon to add chatBotConversationId when retrieving data from a WhatsAppIn conversation'
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
				        if @campType = 0 --ACD
						BEGIN
				            SELECT  @OldAgentId = conv.agentId,
				                    @OldConversationId = rel.conversationIdBefore
				            FROM ccWhatsAppConversationsRelationship rel 
				            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
				            WHERE rel.conversationIdAfter = @conversationId

							CREATE TABLE #ChatBotRelation (ChatBotConversationId INT, ContactName VARCHAR(50), ClientNumber VARCHAR(25), ChatBotName VARCHAR(255));
							INSERT INTO #ChatBotRelation EXEC ccsp_GalateaChatBotAdmin @action = 7,
							@WAConversationId = @conversationId, @camType = @CampType;

							SELECT
							cast(i.chat as int) AS ServiceType,
							cast(c.conversationId as int) as ConversationID,
							CAST(ISNULL(cb.ChatBotConversationId, 0)  AS INT) AS ChatBotConversationID,
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
							ISNULL(c.IsAgentLoggingOut,0) AS IsAgentLoggingOut
							from ccWhatsAppConversations c
							left join ccInbound i on c.inboundId = i.Inbound_id 
							left JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId    
							LEFT JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
							LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
							LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
							LEFT JOIN #ChatBotRelation cb ON cb.ClientNumber = c.clientId

							WHERE c.conversationId = @conversationId;
							DROP TABLE #ChatBotRelation;
	
				        END
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
				                select messageId, conversationId, timeStampMessageUTC, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus
				                FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
				            END
				            if(@CampType = 1)
				            BEGIN
				                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus) 
				                select messageId, conversationId, timeStampMessageUTC, originType
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
					ELSE IF(@Option = 7)--  Get ChatBotCampaigns Configuration List
				    BEGIN    
				        SELECT --inbound.chat AS ServiceType,
				        CAST(inbound.Inbound_id AS INT) AS Id,
				        inbound.descripcion AS [Name],
				        cbr.ContactName AS Phone,
				        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
				        inbound.tNotas AS WrapUpTime,
				        CAST(graphics.graphic_id AS INT) AS GraphicId
						--,cbr.ContactName AS ChatBotNumber
				        FROM  ccInbound inbound
				        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
				        INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
						INNER JOIN ChatBotCampaign cbc ON inbound.Inbound_id = cbc.campId
						INNER JOIN ChatBotRelation cbr ON cbc.chatBotId = cbr.AzureKnowledgeId
						WHERE cbc.campType = 0 AND inbound.Status != 0
						ORDER BY Id ASC
				    END
				    END'
	EXEC(@sql)


		
		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
		-- EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		-- EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
