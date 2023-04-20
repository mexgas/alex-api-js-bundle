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
SET @versionfix = 15
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

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN IVAN K020099 OUTBOUND TEMPLATES ------------------------------

		SET @process = 'IM-K020099 Create table for templates (ccWhatsAppOutboundTemplates)'
		SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ccWhatsAppOutboundTemplates'')
					BEGIN
						CREATE TABLE ccWhatsAppOutboundTemplates (
						TemplateId INT NOT NULL,
						Category VARCHAR(25) NOT NULL,
						TemplateName VARCHAR(500),
						LanguageCode VARCHAR(10),
						Status BIT,
						AsociatedNumber VARCHAR(30),
						Type VARCHAR(50),
						Format VARCHAR(15),
						Body VARCHAR(MAX),
						PRIMARY KEY (TemplateId));
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Drop procedure if exists'
		SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppOutboundTemplates'')
					BEGIN
						DROP PROCEDURE ccsp_WhatsAppOutboundTemplates;
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Create new procedure for WhatsApp Outbound Templates'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppOutboundTemplates] 
					@Action SMALLINT, 
					@TemplateName VARCHAR(500) = '''' 
					AS  
					SET NOCOUNT ON;  
					IF @Action = 0  -- Get all template information
					BEGIN
						SELECT TemplateName, LanguageCode, Type, Format, Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
					END
					IF @Action = 1  -- Get template body 
					BEGIN
						SELECT Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
					END
					RETURN(0)
					SET NOCOUNT OFF'
		EXEC(@sql)

		SET @process = 'IM-K020099 Add action 2 which gets template information to display in Agent UI (lines 162 to 169) '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
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

						if not exists (select * from ccWhatsAppConversationsOut where phoneCamp = @phoneCamp and clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) begin
							if not exists (select * from ccWhatsAppConversations where phoneACD = @phoneCamp and clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) begin
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
								FROM ccInbound A INNER JOIN ccWhatsAppConversations B 
								ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
								INNER JOIN ccUsers C ON B.agentId = C.User_id;
							end  
						end
						else begin
							select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username
							FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B 
							ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
							INNER JOIN ccUsers C ON B.agentId = C.User_id;
						end  
					END 
					IF @action = 2 -- Get Outbound Templates
					BEGIN
						IF @campId IS NOT NULL
						BEGIN
							DECLARE @AsociatedNumber VARCHAR(30) = (SELECT number from ccWhatsAppNumbers WHERE @campId = camp_id);
							SELECT * FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
						END
					END
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Add property requestDate line(201)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OutboundMultimediaCommon] 
					@Action INT,
					@ConversationId INT = NULL
					AS
					BEGIN
					SET NOCOUNT ON;

						IF @Action = 0 -- Get WhatsApp Campaigns List
						BEGIN 
							SELECT CAST(campaigns.cam_id AS INT) AS Id,
								   campaigns.cam_descripcion AS Name,
								   waNumbers.number AS Phone,
								   5 as [Type]
							FROM ccCamps campaigns
							INNER JOIN ccWhatsAppNumbers waNumbers
							ON campaigns.cam_id = waNumbers.camp_id
							WHERE campaigns.CampType = 5 AND waNumbers.status = 1
							ORDER BY campaigns.cam_id 
						END

						ELSE IF @Action = 1 -- Get Outbound WhatsApp conversation by conversation id
						BEGIN 
							DECLARE @ServiceType VARCHAR(20) = ''whatsapp''
							SELECT conversationId AS ConversationID,
								   clientId AS ClientId,
								   phoneCamp AS CampaignPhone,
								   agentId AS AgentId,
								   @ServiceType AS ServiceType,
								   requestDate AS InitialDate
							FROM ccWhatsAppConversationsOut
							WHERE conversationId = @ConversationId
						END
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Add template filter to get its content lines(404 and 407). Add Inner join in options 0 and 1 to get GraphicId lines(227,229,243,245)'
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
									c.agentId AS AgentId
							FROM  ccInbound i
								INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
								INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
								INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
								LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
								LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

							WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
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
									cm.conexionInfo as [To],
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
							FROM  ccCamps i
								INNER JOIN  contactMeanOut cm  ON i.cam_id = cm.camp_id
								INNER JOIN ccWhatsAppConversationsOut c ON (c.camId = i.cam_id and c.conversationId = @conversationId)
								INNER JOIN ccRIACampsGraph g on g.cam_id = i.cam_id
								LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
								LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

							WHERE i.CampType = @ServiceType and i.cam_id = @inboundId
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

		SET @process = 'IM-K020099 Add assignDate in option 1 lines (497 and 596). Add graphic id in option 4 lines (561,565,681,687,805). Add template filter'
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
							DECLARE @camp_acd_id INT = 0;

							IF @campType = 0
							BEGIN
								SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations WHERE conversationId = @conversationId)

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

		-------------------------------------------- END IVAN K020099 OUTBOUND TEMPLATES   ------------------------------
		
		set @process = ' Drop column sched_id from table ccSmsSchedules'
		set @sql = '
		if exists (select * from sys.columns where name = N''sched_id'' and Object_ID = Object_ID(N''ccSmsSchedules''))
		begin
		    alter table ccSmsSchedules drop column sched_id
		end
		'
		EXEC(@sql)

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
