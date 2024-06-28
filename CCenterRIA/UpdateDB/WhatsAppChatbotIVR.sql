/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 1
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
 
	----------------------------------------------------- BEGIN Marco K060011  ----------------------------------------------------------------

		SET @process = 'K060011 drop sp [ccsp_GalateaChatBotAdmin]'
		SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_GalateaChatBotAdmin'')
                begin
                    DROP PROCEDURE ccsp_GalateaChatBotAdmin;
                end'
		EXEC(@sql);

		SET @process = 'K060011 Create sp [ccsp_GalateaChatBotAdmin]'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaChatBotAdmin]
				@action int,@userId int=0,@chatBotId int=0,@camId int=0,@camType int=0,
				@chatBotConversationId bigint=0, @WAConversationId int=0,
				@IsPinned bit = 0, @AdminId int = 0
				AS
				set nocount on

				declare @camDescription varchar(255),@chatBotName varchar(255)
				if @action in(4,5) begin
					select @chatBotName=ProjectName from AzureKnowledge where Id=@chatBotId
					if @camType=0 begin
						select @camDescription=descripcion from ccInbound where Inbound_id=@camId
					end
					else begin
						select @camDescription=cam_descripcion from ccCamps where cam_id=@camId
					end
				end


				if @action=1 begin --Relation los que estan dados de alto con algun numero 
					select A.id,A.ProjectName,B.ContactName from AzureKnowledge A 
					inner join ChatBotRelation B on A.id=B.AzureKnowledgeId
				end
				else if @action=2 begin --Lista de campañas de entrada whats y Campaña de voz Normal
					;with WgRelationUser as(
					select Wgu.IDWG,WgC.IdCampEsp,WgC.Tipo from ccRIAWorkGroupUsers Wgu
					inner join ccRIACampEspWG WgC on WgC.IDWG =Wgu.IDWG
					where User_id=@userId
					)
					select CAST( A.IdCampEsp as int) as CamId,descripcion as [Description],CAST( A.Tipo as int) as CampTypeInOut 
					from WgRelationUser A 
					inner join ccInbound B on A.IdCampEsp=B.Inbound_id and A.Tipo=0 and B.chat=5
					union
					select CAST(A.IdCampEsp as int) as CamId,cam_descripcion as [Description],CAST( A.Tipo as int) as CampTypeInOut
					from WgRelationUser A 
					inner join ccCamps B on A.IdCampEsp=B.cam_id and A.Tipo=1 and B.CampType=0
				end
				else if @action=3 begin --Relacion de Chatbot con alguna campaña entrada/salida
					;with WgRelationUser as(
					select Wgu.IDWG,WgC.IdCampEsp,WgC.Tipo from ccRIAWorkGroupUsers Wgu
					inner join ccRIACampEspWG WgC on WgC.IDWG =Wgu.IDWG
					where User_id=@userId
					)
					select cast(A.chatBotId as int) as chatBotId,cast(A.campId as int) as CamId,CAST(A.campType as int) as CampTypeInOut 
					from ChatBotCampaign A
					inner join WgRelationUser B on A.campId=B.IdCampEsp and A.campType=B.Tipo
					where (@chatBotId=0 or chatBotId=@chatBotId)
				end
				else if @action=4 begin --Add Campaing
					if not exists(select * from ChatBotCampaign where chatBotId=@chatBotId and campId=@camId and campType=@camType) begin
						insert into ChatBotCampaign values(@chatBotId,@camId,@camType)
		
						exec ccsp_GalateaActivityLog @UserId=34,@Operations=78,@Identifiers='''',@Values=@chatBotName,@Module=9,
						@Target=@camDescription
					end
				end
				else if @action=5 begin --delete Campaing
					delete from ChatBotCampaign where chatBotId=@chatBotId and campId=@camId and campType=@camType
					exec ccsp_GalateaActivityLog @UserId=34,@Operations=79,@Identifiers='''',@Values=@chatBotName,@Module=9,
					@Target=@camDescription
				end
				ELSE IF @action = 6 BEGIN --Add relation of Chatbot-WA conversations
					IF NOT EXISTS(SELECT * FROM ChatBotWhatsAppConversation WHERE ChatBotConversationId = @chatBotConversationId
					AND WhatsAppConversationId = @WAConversationId AND CampType = @camType) BEGIN
						INSERT INTO ChatBotWhatsAppConversation (ChatBotConversationId, WhatsAppConversationId, CampType) VALUES (@chatBotConversationId, @WAConversationId, @camType)
					END
				END
				ELSE IF @action = 7 BEGIN --Get chatbotConversationId value if it exists
					SELECT B.ChatBotConversationId, A.phoneACD AS ContactName, A.clientID AS ClientNumber, cbc.ChatBotName FROM ccWhatsAppConversations A
					JOIN ChatBotWhatsAppConversation B ON B.WhatsAppConversationId = A.conversationId
					JOIN dbo.ChatBotConversation AS cbc ON b.ChatBotConversationId = cbc.ChatBotConversationId
					WHERE B.WhatsAppConversationId = @WAConversationId AND CampType = @camType;
				END
				ELSE IF @action = 8 BEGIN --GET AzureKnoledge bots
					select A.id as ChatBotId, A.ProjectName, CASE WHEN ISNULL(P.chatBotId, 0) > 0 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END as IsPinned 
					from AzureKnowledge A
					left join PinnedChatBots P on A.id = P.chatBotId and  P.AdminId = @AdminId
				END
				ELSE IF @action = 9 BEGIN
					IF(@IsPinned = 0)
					BEGIN
						DELETE FROM PinnedChatBots where chatBotId = @chatBotId and AdminId = @AdminId
					END
					ELSE
					BEGIN
						IF NOT EXISTS (select * from PinnedChatBots where chatBotId = @chatBotId and AdminId = @AdminId)
						BEGIN
							INSERT INTO PinnedChatBots values(@chatBotId, @AdminId)
						END
					END

					select A.id as ChatBotId, A.ProjectName, CASE WHEN ISNULL(P.chatBotId, 0) > 0 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END as IsPinned 
					from AzureKnowledge A
					left join PinnedChatBots P on A.id = P.chatBotId and P.AdminId = @AdminId
					WHERE a.id = @chatBotId
				END
				set nocount off'
		EXEC(@sql)

		SET @process = 'K060011 drop sp [ccsp_MultimediaCommon]'
		SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_MultimediaCommon'')
                begin
                    DROP PROCEDURE ccsp_MultimediaCommon;
                end'
		EXEC(@sql);

		SET @process = 'K060011 create sp [ccsp_MultimediaCommon] option 2 was modified, the #chatbotRelation table was created'
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
                        ISNULL(numbers.number, '''') AS Phone,
                        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                        inbound.tNotas AS WrapUpTime,
                        CAST(graphics.graphic_id AS INT) AS GraphicId
                        FROM  ccInbound inbound
                        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                        INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId
                        where inbound.Status != 0 AND configuration.meanContactTypeId = 5 and numbers.status != 0 
                                                                
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
				    END'
		EXEC(@sql)

		SET @process = 'K060011 drop sp [ccsp_AgentHistoricalChat]'
		SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_AgentHistoricalChat'')
                begin
                    DROP PROCEDURE ccsp_AgentHistoricalChat;
                end'
		EXEC(@sql);

		SET @process = 'K060011 create sp [ccsp_AgentHistoricalChat] option 4 was modified, chatbot information was added to the result'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
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
					FROM ccWhatsAppConversations with(nolock)
					WHERE clientId = @clientNum AND assignDate IS NOT NULL
					GROUP BY conversationId, assignDate
				END
				ELSE
				BEGIN  -- OUTBOUND
					SELECT conversationId AS ConversationId,
						   @campType AS CampType,
						   assignDate AS Date
					FROM ccWhatsAppConversationsOut with(nolock)
					WHERE clientId = @clientNum AND assignDate IS NOT NULL
					GROUP BY conversationId, assignDate
				END
				END

				IF @option = 2 --whatsapp, get acdId by conversation id
				BEGIN
				IF @campType = 0
				BEGIN
					SELECT CAST(inboundId AS INT)
					FROM [ccWhatsAppConversations] with(nolock)
					WHERE conversationId = @conversationId
				END
				ELSE
				BEGIN
					SELECT CAST(camId AS INT)
					FROM [ccWhatsAppConversationsOut] with(nolock)
					WHERE conversationId = @conversationId
				END
				END

				IF @option = 3 --get data conversation
				BEGIN
					DECLARE @OldAgentId INT = 0
					DECLARE @OldConversationId INT = 0

					SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
					FROM ccWhatsAppConversationsRelationship rel with(nolock)
					RIGHT JOIN ccWhatsAppConversations conv with(nolock) ON conv.conversationId = rel.conversationIdBefore
					WHERE rel.conversationIdAfter = @conversationId

					SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
						graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
					[WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
					[SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
					OldConversationId, c.agentId AS AgentId
					FROM ccInbound i
					INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
					INNER JOIN ccWhatsAppConversations c with(nolock) ON (
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

					SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations with(nolock) WHERE conversationId = @conversationId)
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
					END AS Content, typeMessage AS Type, CASE 
					WHEN typeMessage NOT IN (''text'', ''location'')
						THEN content
					ELSE ''''
					END AS Caption, CASE 
					WHEN originType = ''Client''
						THEN CASE 
								WHEN typeMessage = ''text''
									OR typeMessage = ''location''
									THEN ''''
								ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''INBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
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
					SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) WHERE conversationId = @conversationId)

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
					ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''OUTBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
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
							FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship] with(nolock)
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
							FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut] with(nolock)
									WHERE conversationIdAfter = @conversationId
									)
								THEN CAST(1 AS BIT)
							ELSE CAST(0 AS BIT)
							END
							END
				END
				END'
		EXEC(@sql)
	

        ---------------------------------------- END Marco K060011 -------------------------------------------------



 	
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
