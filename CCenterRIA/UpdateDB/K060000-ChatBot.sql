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

		SET @process = 'K060000-Se crea Tabla ccssetings 2'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccSettings2'') begin
	CREATE TABLE ccSettings2(
	setting_id smallint NOT NULL,
	valor varchar(300),
	descripcion varchar(150) NOT NULL,
	Status tinyint,
	Tipo varchar(3),
	detalle varchar(600),
	description varchar(600),
	bLoadSettings bit,
	validate varchar(255)
	);
	end'
	EXEC(@sql)

	SET @process = 'K060000-Se inserta setting 256 Ruta para guardar conversaciones de chatbot'
	SET @sql = 'if not exists(select * ccSettings2 where setting_id=256) begin
	INSERT INTO ccSettings2 (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
	VALUES (256, ''C:\Multimedia\Conversations\Chatbot'', ''Ruta donde se guardarán las conversaciones de Chatbot'', 1, ''GRL'', ''Se guardan los archivos .json separados por carpetas'', ''Path for saving Chatbot conversations'', 1, ''.{0,99}'');
	end'
	EXEC(@sql)

	SET @process = 'K060000-Se crea vista de los settings'
	SET @sql = 'IF NOT EXISTS(select * from sys.views where name=''VIEW_SETTINGS'')
	BEGIN
		CREATE VIEW [dbo].[VIEW_SETTINGS]
		AS
		select setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate from ccSettings 
		union
		select setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate from ccSettings2
	END'
	EXEC(@sql)

	SET @process = 'K060013-Buscador-Conversaciones ChatBot Create Table ccChatBotNode'
	SET @sql = 'if not exists(select * from sys.tables where name=''PinnedChatBots'') begin
	CREATE TABLE [dbo].[PinnedChatBots](
	[chatBotId] int not null,
	[AdminId] int not null
	)
	end'
	EXEC(@sql)

	SET @process = 'K060013-Buscador-Conversaciones ChatBot Create Table ccChatBotNode'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccChatBotNode'') begin
	CREATE TABLE [dbo].[ccChatBotNode](
		[conversationId] [int] NOT NULL primary key,
		[node] [xml] NULL,
		[dateIn] [datetime] NULL,
		[dateOut] [datetime] NULL,
		[status] [smallint] NULL
	)

	ALTER TABLE [dbo].[ccChatBotNode] ADD  DEFAULT (NULL) FOR [dateOut]
	ALTER TABLE [dbo].[ccChatBotNode] ADD  DEFAULT ((0)) FOR [status]
	end'
	EXEC(@sql)

	SET @process = 'K060013-Buscador-Conversaciones ChatBot Create Table ccChatBotNodeHistory'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccChatBotNodeHistory'') begin
	CREATE TABLE [dbo].[ccChatBotNodeHistory](
		[conversationId] [int] NOT NULL,
		[node] [xml] NULL,
		[dateIn] [datetime] NULL,
		[dateOut] [datetime] NULL,
		[status] [smallint] NULL
	)
	end'
	EXEC(@sql)

	SET @process = 'K060013-Buscador-Conversaciones ChatBot Insert Finder ChatBot'
	SET @sql = 'SET IDENTITY_INSERT ccFinderServices ON
	if not exists(select * from ccFinderServices where name=''ChatBot'') begin
		insert into ccFinderServices (id,[name],ref,tableName,tableNameHistory,columnId,isActive)
		values(7,''ChatBot'',''R07'',''ccChatBotNode'',''ccChatBotNodeHistory'',''conversationId'',1)
	end

	SET IDENTITY_INSERT ccFinderServices OFF'
	EXEC(@sql)


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
		INSERT INTO ChatBotWhatsAppConversation VALUES (@chatBotConversationId, @WAConversationId, @camType)
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

	-------------------------------------------- BEGIN Enrique Ruiz ---------------------------------------------------------------------------------
	SET @process = 'K060005 Create table ChatBotWhatsAppConversation which contains the relation of ids from ChatBot and WhatsApp conversations'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotWhatsAppConversation'') begin
	CREATE TABLE [dbo].ChatBotWhatsAppConversation(
					ChatBotConversationId [bigint] NULL,
					WhatsAppConversationId [int] NULL,
					CampType [tinyint] NULL
				) ON [PRIMARY]
	END'
	EXEC(@sql)

	SET @process = 'Create table AzureKnowledge adding Language data'
	SET @sql = 'if not exists(select * from sys.tables where name=''AzureKnowledge'') begin
	CREATE TABLE AzureKnowledge (
					id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
					ProjectName varchar(255) NOT NULL,
					EndPoint varchar(255) NOT NULL,
					SubscriptionKey varchar(255) NOT NULL,
					DeploymentName varchar(255) NOT NULL,
					Language varchar(50) NOT NULL
				)
				END'
	EXEC(@sql)

	SET @process = 'K060006 Create table ChatBotConversationEndStatus which contains the different manners a conversation can end'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotConversationEndStatus'') begin
	CREATE TABLE [dbo].[ChatBotConversationEndStatus](
					[id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[name] [varchar](30) NOT NULL,
					[description] [varchar](100) NOT NULL,
				PRIMARY KEY CLUSTERED 
				(
					[id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]
				END'
	EXEC(@sql)

	SET @process = 'K060006 Insert the EndStatus in the table'
	SET @sql = ' TRUNCATE TABLE ChatBotConversationEndStatus;
				INSERT INTO ChatBotConversationEndStatus ([name],[description])
				VALUES (''Finish'',''Finished by client''), (''Fail'',''Finished by system fail''), (''Transfer'',''Transfered to WhatsApp campaign''),
				(''Callback'',''Transfered to callback''), (''Abandon'',''Abandoned by client'');'
	EXEC(@sql)

	SET @process = 'K060008 -Create or Alter SP ccsp_GalateaChatBotConversationsResult to insert abandoned conversations correctly'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_GalateaChatBotConversationsResult]
				@action int,@chatBotId int,@status int=0,
				@conversationId bigint=0,@campaignId int=0,
				@activeConversations int = 0
				AS
				set nocount on

				IF @action=0 BEGIN --Insertar estado de finalización en Tabla de Conversaciones
					UPDATE ChatBotConversation SET EndStatus=@status, CampIdTransfered=@campaignId, ConversationTime =  DATEDIFF(ss, ISNULL(FirstMessageTime, GETDATE()), GETDATE()) WHERE ChatBotConversationId = @conversationId;

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
					DECLARE @AverageTime varchar(8)
					DECLARE @timeInSeconds int

					select  @timeInSeconds = SUM(ConversationTime)/COUNT(ConversationTime) from ChatBotConversation
					WHERE EndStatus > 0 and FirstMessageTime >= CAST(CAST(GETDATE() AS date) AS datetime)
					AND ConversationTime > 0 and ChatBotId = @ChatBotId

					SELECT @AverageTime =
						RIGHT(''00''+CONVERT(VARCHAR(10),@timeInSeconds/3600),2)  
						+'':'' 
						+ RIGHT(''00''+CONVERT(VARCHAR(2),(@timeInSeconds%3600)/60),2) 
						+'':'' 
						+ RIGHT(''00''+CONVERT(VARCHAR(2),@timeInSeconds%60),2) 
					select  *, @AverageTime AS AverageTime from ccChatBotConversationsResult where chatBotId=@chatBotId
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
	SET @process = 'K060026 Create or Alter procedure ccsp_Get_ChatBot_Relations to return related inbound campaigns'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_Get_ChatBot_Relations]
				@option int, @chatbotId int = null
				as set nocount on

				IF(@option = 1) BEGIN --All relations of Azure Knowledge and Phone Number
					SELECT b.AzureKnowledgeId,A.ProjectName,B.ContactName FROM AzureKnowledge A 
					INNER JOIN ChatBotRelation B ON A.id = B.AzureKnowledgeId
				END

				ELSE IF(@option = 2) BEGIN  --Inbound Campaigns that have a ChatBot associated
					SELECT  CAST(ROW_NUMBER() OVER(ORDER BY A.inboundId ASC) AS INT) AS rowId, 
					A.inboundId AS campId, A.name AS campName, A.connUser AS campNumber,
					CAST(B.campType AS tinyint) AS campType, B.chatBotId, CAST(0 AS SMALLINT) AS validSchedule
					from contactMeanIn A
					JOIN ChatBotCampaign B ON A.inboundId = B.campId
					WHERE B.chatBotId = @chatbotId AND B.campType = 0;
				END 
				ELSE IF(@option = 3) BEGIN 
					--To do: Retornar lista de Campañas de Voz de Salida Habilitadas y en Horario, en este momento retorna lo mismo que opcion 2

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

		SET @process = 'K0026 Add A SELECT for default Messages'
	SET @sql = 'CREATE OR ALTER   PROCEDURE [dbo].[ccsp_Get_Azure_Knowledge]
				@option int
				as set nocount on

				IF(@option = 1) BEGIN 
					SELECT * FROM AzureKnowledge;
				END
				ELSE IF(@option = 2) BEGIN 
					SELECT * FROM ChatBotDefaultMessages;
				END 

				set nocount off'
	EXEC(@sql)

	SET @process = 'K060026 Create Table for default Chatbot messages'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotDefaultMessages'') begin
	CREATE TABLE ChatBotDefaultMessages(
		[MessageTagName] [varchar](50) PRIMARY KEY NOT NULL,
		[MeTagES] [varchar](250) NOT NULL,
		[MeTagEN] [varchar](250) NOT NULL,
		[MeTagPT] [varchar](250) NOT NULL,
	)
	end';
	EXEC(@sql)

	SET @process = 'K060026 Insert Default Messages into Chatbot Table'
	SET @sql = 'TRUNCATE TABLE ChatBotDefaultMessages;
				INSERT INTO ChatBotDefaultMessages (MessageTagName, MeTagES, MeTagEN, MeTagPT)
				VALUES
					(''no-answer-found'', ''Lo siento, no entendí la respuesta.'', ''Sorry, I didn’t get that.'', ''Desculpe, não entendi.''),
					(''continue-prompt'', ''¿Intentamos otra vez?'', ''Do you want to continue?'', ''Tentar de novo?''),
					(''option-continue'', ''Intentar'', ''Continue'', ''Tentar''),
					(''option-main-menu'', ''Volver a menú principal'', ''Return to main menu'', ''Retornar ao menu principal''),

					(''option-transfer-to-agent'', ''Transferir a un agente en WhatsApp'', ''Chat with an agent on WhatsApp'', ''Transferir para um agente no WhatsApp''),
					(''mssg-campaign-out-of-schedule'', ''Error al transferir. La campaña de WhatsApp {0} está fuera de horario.'',
						''Unable to connect. The WhatsApp campaign {0} is out of schedule.'', ''Erro ao transferir. A campanha de WhatsApp {0} está fora de horário.''),
					(''mssg-campaign-out-of-service'', ''Error al transferir. La campaña de WhatsApp {0} está fuera de servicio.'',
						''Unable to connect. The WhatsApp campaign {0} is out of service.'', ''Erro ao transferir. A campanha de WhatsApp {0} está fora de serviço.''),
					(''mssg-no-ready-agents-found'', ''Error al transferir. No hay agentes disponibles en este momento.'',
						''Unable to connect. There are no ready agents at this time.'', ''Erro ao transferir. Não há agentes disponíveis neste momento.''),
					(''mssg-unexpected-error'', ''Ocurrió un error inesperado.'', ''An unexpected error occurred.'', ''Ocorreu um erro inesperado.''),

					(''option-speak-with-agent'', ''Hablar con un agente por teléfono'', ''Speak with an agent over the phone'', ''Falar com um agente pelo telefone''),
					(''prompt-phone-number'', ''Proporcionar número telefónico'', ''Type your phone number'', ''Digitar o número de telefone''),
					(''prompt-validation'', ''¿El número {0} es correcto?'', ''Is the number {0} correct?'', ''O número {0} está correto?''),
					(''option-correct'', ''Sí'', ''Yes'', ''Sim''),
					(''option-not-correct'', ''No'', ''No'', ''Não''),
					(''mssg-success'', ''La llamada fue programada correctamente. Un agente se pondrá en contacto en breve.'',
						''Call programmed successfully. An agent will contact you shortly.'', ''A chamada foi programada com êxito. Um agente entrará em contato em breve.''),
					(''mssg-error-out-of-schedule'', ''Error al programar llamada. La campaña de marcación está fuera de horario.'',
						''Unable to program call. The dialing campaign is out of schedule.'', ''Erro ao programar a chamada. A campanha de discagem está fora de horário.''),
					(''mssg-error-out-of-service'', ''Error al programar llamada. La campaña de marcación está fuera de servicio.'',
						''Unable to program call. The dialing campaign is out of service.'', ''Erro ao programar a chamada. A campanha de discagem está fora de serviço.''),
					(''mssg-error-no-agents-found'', ''Error al programar llamada. No hay agentes disponibles en este momento.'',
						''Unable to program call. There are no ready agents at this time.'', ''Erro ao programar a chamada. Não há agentes disponíveis neste momento.''),
					(''mssg-error-generic'', ''Ocurrió un error inesperado.'', ''An unexpected error occurred.'', ''Ocorreu um erro inesperado.'')
				;'
	EXEC(@sql)
	
	SET @process = 'K060026 Create table for the relation of campaigns with the registered chatbots'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotCampaign'') begin
	CREATE TABLE ChatBotCampaign (
				chatBotId int NOT NULL,
				campId int NOT NULL,
				campType tinyint NOT NULL,
			);
	END'
	EXEC(@sql)
	---------------------------------------- END Enrique Ruiz ---------------------------------------------------------------------------------

	---------------------------------------- BEGIN MARCO GARCIA ------------------------------------
	SET @process = 'K060011-WhatsApp entrada->Histórico al asignar conversación de ChatBot a número de WhatsApp entrada, se agrega la consulta
	para obtener las conversaciones del chatbot'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
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
	--------------------------------------------- END MARCO GARCIA ----------------------------------------------

	-----------------------------------------------BEGIN MARCO CHAGOLLA-------------------------------------------
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

	SET @process = 'K060013-Buscador-Conversaciones ChatBot, se agrega condicion para crear nodo multimedia'
	SET @sql = 'CREATE OR ALTER   PROCEDURE [dbo].[ccsp_Save_ChatBot_Conversation]
	@option int,
	@clientNumber VARCHAR(15),
	@clientName VARCHAR(50),
	@chatBotId INT,
	@chatBotName VARCHAR(255),
	@chatBotNumber VARCHAR(30),
	@chatBotDomain VARCHAR(50),
	@campIdTransfered INT,
	@conversationStatus VARCHAR(30),
	@conversationTime INT,
	@endStatus VARCHAR(50),
	@queueTime INT,
	@firstMessageTime DATETIME,
	@ChatBotConversationId numeric(18,0) = 0

	as set nocount on

	IF(@option = 1) BEGIN

		INSERT INTO ChatBotConversation(
		ClientNumber,
		ClientName,
		ChatBotId,
		ChatBotName,
		ChatBotNumber,
		ChatBotDomain,
		CampIdTransfered,
		ConversationStatus,
		ConversationTime,
		EndStatus,
		QueueTime,
		FirstMessageTime
		) 
		VALUES (
		@clientNumber,
		@clientName,
		@chatBotId,
		@chatBotName,
		@chatBotNumber,
		@chatBotDomain,
		@campIdTransfered,
		@conversationStatus,
		@conversationTime,
		@endStatus,
		@queueTime,
		@firstMessageTime
		);

		SELECT @ChatBotConversationId = SCOPE_IDENTITY();
		IF @ChatBotConversationId > 0
		BEGIN
			EXEC ccsp_CreateNodeMultimedia @conversationId = @ChatBotConversationId, @type = 7
		END
		SELECT @ChatBotConversationId

	END
	IF @option = 2
	BEGIN
		EXEC ccsp_CreateNodeMultimedia @conversationId = @ChatBotConversationId, @type = 7
		SELECT @ChatBotConversationId
	END

	set nocount off'
	EXEC(@sql)

		SET @process = 'K060015-Buscador Conversaciones ChatBot transferidas a campaña WhatsApp de entrada, se agrega action 6 y 7 '
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
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
							B.whatsAppConversationId 
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
	------------------------------------------------END MARCO CHAGOLLA--------------------------------------------

		
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
