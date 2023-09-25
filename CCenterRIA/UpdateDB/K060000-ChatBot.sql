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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 35
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


	SET @process = 'K060008- Create Table ccChatBotConversationsResult'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccChatBotConversationsResult'') begin
CREATE TABLE [dbo].[ccChatBotConversationsResult](
	[chatBotId] [int] NOT NULL,
	[FinishedByClient] [int] NOT NULL,
	[FinishedBySystemFail] [int] NOT NULL,
	[TransferWhatsAppCampaign] [int] NOT NULL,
	[TransferCallBack] [int] NOT NULL,
	[ActiveConversations] [int] NOT NULL
) 
end'
	EXEC(@sql)

	SET @process = 'K060008- Create Table ccChatBotConversationsAbandoned'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccChatBotConversationsAbandoned'') begin
CREATE TABLE [dbo].[ccChatBotConversationsAbandoned](
	[chatBotId] [int] NOT NULL ,
	[ConversationId] [int] NOT NULL,
	[Date] [datetime] NOT NULL,	
	primary key ([chatBotId],[ConversationId])
) 
end'
	EXEC(@sql)

	SET @process = 'K060003 insert ccGalateaModules ModuleId=9 and ccGalateaOperations 78 and 79'
	SET @sql = 'if not exists(select * from ccGalateaModules where ModuleId=9)
begin
	insert into ccGalateaModules values(9,''Asociación de chatbot'',''Chatbot association'',''Associação de chatbot'')
end
if not exists(select * from ccGalateaOperations where OperationId=78)
begin
	insert into ccGalateaOperations values(78,''Asociar chatbot'',''Associate chatbot'',''Associar chatbot'')
end
if not exists(select * from ccGalateaOperations where OperationId=79)
begin
	insert into ccGalateaOperations values(79,''Desasociar chatbot'',''Disassociate chatbot'',''Desassociar chatbot'')
end'
	EXEC(@sql)

	SET @process = 'K060003 DROP PROCEDURE ccsp_GalateaChatBotConversationsResult'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaChatBotConversationsResult'')
begin
    DROP PROCEDURE ccsp_GalateaChatBotConversationsResult;
end'
	EXEC(@sql)

	SET @process = 'K060003 DROP PROCEDURE ccsp_GalateaChatBotAdmin'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaChatBotAdmin'')
begin
    DROP PROCEDURE ccsp_GalateaChatBotAdmin;
end'
	EXEC(@sql)

	SET @process = 'K060003-Create SP ccsp_GalateaChatBotAdmin'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaChatBotAdmin]
@action int,@userId int=0,@chatBotId int=0,@camId int=0,@camType int=0,
@chatBotConversationId bigint=0, @WAConversationId int=0,
@IsPinned bit =null
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
	--set @chatBotId=@chatBotId/0
	if not exists(select * from ChatBotCampaign where chatBotId=@chatBotId and campId=@camId and campType=@camType) begin
		insert into ChatBotCampaign values(@chatBotId,@camId,@camType)
		
		exec ccsp_GalateaActivityLog @UserId=34,@Operations=78,@Identifiers='''',@Values=@chatBotName,@Module=9,
		@Target=@camDescription
	end
end
else if @action=5 begin --delete Campaing
	--set @chatBotId=@chatBotId/0
	delete from ChatBotCampaign where chatBotId=@chatBotId and campId=@camId and campType=@camType
	exec ccsp_GalateaActivityLog @UserId=34,@Operations=79,@Identifiers='''',@Values=@chatBotName,@Module=9,
	@Target=@camDescription
end
ELSE IF @action = 6 BEGIN --Add relation of Chatbot-WA conversations
	IF NOT EXISTS(SELECT * FROM ChatBotWhatsAppConversation WHERE ChatBotConversationId = @chatBotConversationId
	AND WhatsAppConversationId = @WAConversationId AND CampType = @camType) BEGIN
		INSERT INTO ChatBotWhatsAppConversation VALUES (@chatBotConversationId, @WAConversationId, @camType)
	END
END
ELSE IF @action = 7 BEGIN --Get chatbotConversationId value if it exists
	SELECT B.ChatBotConversationId, A.phoneACD AS ContactName, A.clientID AS ClientNumber FROM ccWhatsAppConversations A
	JOIN ChatBotWhatsAppConversation B ON B.WhatsAppConversationId = A.conversationId
	WHERE B.WhatsAppConversationId = @WAConversationId AND CampType = @camType;
END
ELSE IF @action = 8 BEGIN --GET AzureKnoledge bots
	select A.id as ChatBotId, A.ProjectName, ISNULL(A.IsPinned, 0) as IsPinned from AzureKnowledge A
END
ELSE IF @action = 9 BEGIN
	UPDATE AzureKnowledge set IsPinned = @IsPinned where id = @chatBotId
	select A.id as ChatBotId, A.ProjectName, ISNULL(A.IsPinned, 0) as IsPinned from AzureKnowledge A where A.id = @chatBotId
END
set nocount off'
	EXEC(@sql)

	-------------------------------------------- BEGIN Enrique Ruiz ---------------------------------------------------------------------------------
	SET @process = 'K060005 Create table ChatBotWhatsAppConversation which contains the relation of ids from ChatBot and WhatsApp conversations'
	SET @sql = 'CREATE TABLE [dbo].ChatBotWhatsAppConversation(
					ChatBotConversationId [bigint] NULL,
					WhatsAppConversationId [int] NULL,
					CampType [tinyint] NULL
				) ON [PRIMARY]
				GO'
	EXEC(@sql)

	SET @process = 'Create table AzureKnowledge adding Language data'
	SET @sql = 'CREATE TABLE AzureKnowledge (
					id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
					ProjectName varchar(255) NOT NULL,
					EndPoint varchar(255) NOT NULL,
					SubscriptionKey varchar(255) NOT NULL,
					DeploymentName varchar(255) NOT NULL,
					Language varchar(50) NOT NULL
				)'
	EXEC(@sql)

	SET @process = 'K060006 Create table ChatBotConversationEndStatus which contains the different manners a conversation can end'
	SET @sql = 'CREATE TABLE [dbo].[ChatBotConversationEndStatus](
					[id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[name] [varchar](30) NOT NULL,
					[description] [varchar](100) NOT NULL,
					[rowguid] [uniqueidentifier] ROWGUIDCOL NULL,
				PRIMARY KEY CLUSTERED 
				(
					[id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]
				GO'
	EXEC(@sql)

	SET @process = 'K060008 -Create or Alter SP ccsp_GalateaChatBotConversationsResult to insert abandoned conversations correctly'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_GalateaChatBotConversationsResult]
				@action int,@chatBotId int,@status int=0,
				@conversationId bigint=0,@campaignId int=0,
				@activeConversations int = 0
				AS
				set nocount on

				IF @action=0 BEGIN --Insertar estado de finalización en Tabla de Conversaciones
					UPDATE ChatBotConversation SET EndStatus=@status, CampIdTransfered=@campaignId WHERE ChatBotConversationId = @conversationId;

					IF @status = 5
					BEGIN
						SET @action = 2
					END
					ELSE BEGIN
						SET @action = 1
					END;

					EXEC ccsp_GalateaChatBotConversationsResult @action=@action, @chatBotId=@chatBotId,
							@status=@status, @conversationId=@conversationId, @campaignId=@campaignId
					END
					--To do: Añadir consulta para finder
				if @action=1 begin --Actualizar el status
					declare @FinishedByClient int,@FinishedBySystemFail int,@TransferWhatsAppCampaign int,@TransferCallBack int
					select @FinishedByClient= case when @status=1 then 1 else 0 end
					,@FinishedBySystemFail= case when @status=2 then 1 else 0 end
					,@TransferWhatsAppCampaign= case when @status=3 then 1 else 0 end
					,@TransferCallBack= case when @status=4 then 1 else 0 end

					if not exists(select  * from ccChatBotConversationsResult where chatBotId=@chatBotId) begin
						insert into ccChatBotConversationsResult values(@chatBotId,@FinishedByClient,@FinishedBySystemFail,@TransferWhatsAppCampaign,@TransferCallBack, 1)
					end
					else begin
						update ccChatBotConversationsResult set [FinishedByClient]=[FinishedByClient]+@FinishedByClient
						,[FinishedBySystemFail]=[FinishedBySystemFail]+@FinishedBySystemFail
						,[TransferWhatsAppCampaign]=[TransferWhatsAppCampaign]+@TransferWhatsAppCampaign
						,[TransferCallBack]=[TransferCallBack]+@TransferCallBack
						where chatBotId=@chatBotId
					end
				end
				else if @action=2 begin	---Insert Conversation Abandoned
					insert into ccChatBotConversationsAbandoned values(@chatBotId,@conversationId,GETDATE())
				end
				else if @action=3 begin --Truncate Table 
					truncate table ccChatBotConversationsResult 
					truncate table ccChatBotConversationsAbandoned
				end
				else if @action=4 begin --GetChatBotConversationsResult
					select  * from ccChatBotConversationsResult where chatBotId=@chatBotId
				end
				else if @action=5 begin --GetChartAbandoned
					select CONVERT(varchar(5),dateadd(mi,-(DATEPART(MINUTE,Date) % 10),Date),108) [Hour]
					,COUNT(*) Amount
					from ccChatBotConversationsAbandoned where chatBotId=@chatBotId
					group by CONVERT(varchar(5),dateadd(mi,-(DATEPART(MINUTE,Date) % 10),Date),108)
				end
				else if @action=6 begin --Update Active Conversations
					UPDATE ccChatBotConversationsResult set activeConversations = @activeConversations where ChatBotId = @chatBotId 
				end

				set nocount off'
	EXEC(@sql)
	SET @process = 'K060005 Create or Alter procedure ccsp_Get_ChatBot_Relations to return related inbound campaigns'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_Get_ChatBot_Relations]
				@option int, @chatbotId int = null
				as set nocount on

				IF(@option = 1) BEGIN --All relations of Azure Knowledge and Phone Number
					SELECT b.AzureKnowledgeId,A.ProjectName,B.ContactName FROM AzureKnowledge A 
					INNER JOIN ChatBotRelation B ON A.id = B.AzureKnowledgeId
				END 
				ELSE IF(@option = 2 OR @option = 3) BEGIN  --Ibound Campaigns Active and in Schedule

					CREATE TABLE #ActiveCampaigns (
						rowId INT,
						campId INT,
						campName VARCHAR(30),
						campNumber VARCHAR(60),
						campType TINYINT,
						chatBotId INT,
						validSchedule SMALLINT);

					INSERT INTO #ActiveCampaigns
						SELECT  CAST(ROW_NUMBER() OVER(ORDER BY A.inboundId ASC) AS INT) AS rowId, 
						A.inboundId AS campId, A.name AS campName, A.connUser AS campNumber,
						CAST(0 AS tinyint) AS campType, B.chatBotId, CAST(0 AS SMALLINT) AS validSchedule
						from contactMeanIn A
						JOIN ChatBotCampaign B ON A.inboundId = B.campId
						JOIN ccInbound C ON A.inboundId = C.Inbound_id
						WHERE B.chatBotId = @chatbotId AND B.campType = 0 AND C.Status = 1;

					CREATE TABLE #ActiveSchedule (active INT);
					DECLARE @validSchedule INT;
					DECLARE @campId INT;
					DECLARE @totalRows INT;
					DECLARE @row INT;
					SET @totalRows = ISNULL((SELECT COUNT (*) FROM #ActiveCampaigns), 0);
					SET @row = 1;

					WHILE @row <= @totalRows
					BEGIN
						SET @campId = ISNULL((SELECT campId FROM #ActiveCampaigns WHERE rowId = @row), 0);
						INSERT INTO #ActiveSchedule EXEC ccsp_RIAChatACDSchedule @Option=1,@Inbound_Id=@campId
						SELECT @validSchedule = active FROM #ActiveSchedule;
						IF @validSchedule = 1
						BEGIN
							UPDATE #ActiveCampaigns SET validSchedule = @validSchedule WHERE campId = @campId;
						END;
						SET @row = @row + 1;
					END;

					SELECT CAST(ROW_NUMBER() OVER(ORDER BY campId ASC) AS INT) AS rowId,
					campId, campName, campNumber, campType, chatBotId FROM #ActiveCampaigns WHERE validSchedule = 1;

					DROP TABLE #ActiveSchedule;
					DROP TABLE #ActiveCampaigns;
				END 
				/*
				ELSE IF(@option = 3) BEGIN 
					--To do: Retornar lista de Campañas de Voz de Salida Habilitadas y en Horario, en este momento retorna lo mismo que opcion 2
					SELECT null AS rowId,
					null AS campId,  null AS campName,  null AS campType,  null AS chatBotId
				END */

				set nocount off'
	EXEC(@sql)

	SET @process = 'K060005 Alter procedure ccsp_ConversationWASave to register the chatbotId and WhatsAppConversationId when creating a new WhatsApp conversation'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
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

								IF (@chatBotConversationId != 0)
								BEGIN
									UPDATE ChatBotWhatsAppConversation SET WhatsAppConversationId = @conversationIdNew
									WHERE ChatBotConversationId = @chatBotConversationId AND WhatsAppConversationId = @conversationId AND CampType = 0;
								END;
					      
								--Save new request by reassign
					            UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

					        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus;

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
					END;'
	EXEC(@sql)

	SET @process = 'K060005 Alter procedure ccsp_MultimediaCommon to add chatBotConversationId when retrieving data from a WhatsAppIn conversation'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
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

							CREATE TABLE #ChatBotRelation (ChatBotConversationId INT, ContactName VARCHAR(50), ClientNumber VARCHAR(25));
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
							c.IsAgentLoggingOut AS IsAgentLoggingOut
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
	---------------------------------------- BEGIN Enrique Ruiz ---------------------------------------------------------------------------------

	SET @process = ''
	SET @sql = ''
	EXEC(@sql)

	SET @process = ''
	SET @sql = ''
	EXEC(@sql)

	SET @process = ''
	SET @sql = ''
	EXEC(@sql)
	
	SET @process = ''
	SET @sql = ''
	EXEC(@sql)

	SET @process = ''
	SET @sql = ''
	EXEC(@sql)
	
	SET @process = ''
	SET @sql = ''
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
