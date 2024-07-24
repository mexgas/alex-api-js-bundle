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

	SET @process = 'K060000-Se crea Tabla ChatBotConversation'
	SET @sql = 'if not exists(SELECT * FROM ccSettings WHERE setting_id = 252) begin

INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
VALUES (252, ''127.0.0.1'', ''Ubicacicion del Chatbot'', 1, ''GRL'', ''IP del servidor donde se encuentra el chatbot'', ''Chatbot Service location'', 1, ''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'')

end'
	EXEC(@sql)

	SET @process = 'K060000-Se inserta setting 256 Ruta para guardar conversaciones de chatbot'
	SET @sql = 'if not exists(select * from ccSettings2 where setting_id=256) begin
	INSERT INTO ccSettings2 (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
	VALUES (256, ''C:\Multimedia\Conversations\Chatbot'', ''Ruta donde se guardarán las conversaciones de Chatbot'', 1, ''GRL'', ''Se guardan los archivos .json separados por carpetas'', ''Path for saving Chatbot conversations'', 1, ''.{0,99}'');
	end'
	EXEC(@sql)


	
	SET @process = 'K060003 insert ccGalateaModules ModuleId=9 and ccGalateaOperations 78 and 79'
	SET @sql = 'if not exists(select * from ccGalateaModules where ModuleId=9)
begin
	insert into ccGalateaModules values(9,''Asociación de chatbot'',''Chatbot association'',''Associação de chatbot'')
end
if not exists(select * from ccGalateaOperations where OperationId=78)---Revisar por que existe crear uno nuevo
begin
	insert into ccGalateaOperations values(78,''Asociar chatbot'',''Associate chatbot'',''Associar chatbot'')
end
if not exists(select * from ccGalateaOperations where OperationId=79)---Revisar por que existe crear uno nuevo
begin
	insert into ccGalateaOperations values(79,''Desasociar chatbot'',''Disassociate chatbot'',''Desassociar chatbot'')
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

	SET @process = 'K060000-Se crea Tabla ChatBotConversation'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotConversation'') begin
	CREATE TABLE ChatBotConversation (
	ChatBotConversationId BIGINT IDENTITY(1,1) PRIMARY KEY, 
    ClientNumber VARCHAR(15),
    ClientName VARCHAR(50),
    ChatBotId INT,
    ChatBotName VARCHAR(255),
    ChatBotNumber VARCHAR(30),
    ChatBotDomain VARCHAR(50),
    CampIdTransfered INT,
    ConversationStatus VARCHAR(30),
    ConversationTime INT,
    EndStatus INT,
    QueueTime INT,
    FirstMessageTime DATETIME
	);
	end'
	EXEC(@sql)

		SET @process = 'K060000-Se crea Tabla ChatBotConversationMessage'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotConversationMessage'') begin
	CREATE TABLE ChatBotConversationMessage (
	MessageId UNIQUEIDENTIFIER PRIMARY KEY default NEWID(),
    ConversationChatBotId BIGINT NOT NULL,
    OriginType VARCHAR(50),
    MessageStatus VARCHAR(50),
	Date DATETIME,
    TypeMessage VARCHAR(50),
    Message VARCHAR(255)
	);
	end'
	EXEC(@sql)

	SET @process = 'K060033 - Se agregan campos para validad si ya fueron procesados los mensajes en azure'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM   INFORMATION_SCHEMA.COLUMNS 
		WHERE  TABLE_NAME = ''ChatBotConversationMessage''
		AND COLUMN_NAME = ''PendingToAzure'')
	BEGIN
		ALTER TABLE ChatBotConversationMessage ADD PendingToAzure smallint
	END

	IF NOT EXISTS (SELECT * FROM   INFORMATION_SCHEMA.COLUMNS 
		WHERE  TABLE_NAME = ''ChatBotConversationMessage''
		AND COLUMN_NAME = ''message_uuid'')
	BEGIN
		ALTER TABLE ChatBotConversationMessage ADD message_uuid varchar(50)
	END'
	EXEC(@sql)	

	SET @process = 'K060000-Se crea Tabla ChatBotRelation'
	SET @sql = 'if not exists(select * from sys.tables where name=''ChatBotRelation'') begin
	CREATE TABLE ChatBotRelation (
	AzureKnowledgeId int,
	ContactName varchar(255)
	);
	end'
	EXEC(@sql)


	SET @process = 'K060013-Buscador-Conversaciones ChatBot Create Table ccChatBotNode'
	SET @sql = 'if not exists(select * from sys.tables where name=''PinnedChatBots'') begin
	CREATE TABLE [dbo].[PinnedChatBots](
	[chatBotId] int not null,
	[AdminId] int not null
	)
	end'
	EXEC(@sql)

	SET @process = 'K060013-Buscador-Conversaciones ChatBot Create Table ccChatBotNode (si no existe la tabla )'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccChatBotNode'') begin
	CREATE TABLE [dbo].[ccChatBotNode](
		[conversationId] [int] NOT NULL primary key,
		[node] [xml] NULL,
		[dateIn] [datetime] NULL,
		[dateOut] [datetime] NULL,
		[status] [smallint] NOT NULL DEFAULT ((0))
	)
	end'
	EXEC(@sql)

	SET @process = 'K060013-Buscador-Conversaciones ChatBot Create Table ccChatBotNode (si ya existe la tabla)'
	SET @sql = 'if exists(select * from sys.tables where name=''ccChatBotNode'') begin
	UPDATE [dbo].[ccChatBotNode] SET [status] = 0 WHERE [status] IS NULL;

	ALTER TABLE [dbo].[ccChatBotNode]
	ALTER COLUMN [status] smallint NOT NULL;

	ALTER TABLE [dbo].[ccChatBotNode] ADD DEFAULT ((0)) FOR [status];
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

	SET @process = 'K060000-Se Drop SP ccsp_Save_ChatBot_Conversation_Message'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Save_ChatBot_Conversation_Message'')
	begin
	    DROP PROCEDURE ccsp_Save_ChatBot_Conversation_Message;
	end'
	EXEC(@sql)


	SET @process = 'K060000-Se crea SP ccsp_Save_ChatBot_Conversation_Message'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_Save_ChatBot_Conversation_Message]
	@option int,
	@conversationChatBotId BIGINT = null,
	@originType VARCHAR(50) = null,
	@messageStatus VARCHAR(50) = null,
	@date DateTime = null,
	@typeMessage VARCHAR(50) = null,
	@message VARCHAR(255) = null,
	@message_uuid varchar(50) = null

	as set nocount on

	IF(@option = 1) BEGIN

		INSERT INTO ChatBotConversationMessage(
		message_uuid,
		ConversationChatBotId,
		OriginType,
		MessageStatus,
		Date,
		TypeMessage,
		Message
		) 
		VALUES (
		@message_uuid,
		@conversationChatBotId,
		@originType,
		@messageStatus,
		@date,
		@typeMessage,
		@message
		);

		SELECT SCOPE_IDENTITY()
	END 
	IF(@option = 2)
	BEGIN
		UPDATE ChatBotConversationMessage SET message_uuid = @message_uuid
		WHERE ConversationChatBotId = @conversationChatBotId and ISNULL(message_uuid, '''') = ''''
		AND OriginType = @originType
	END
	IF(@option = 3)
	BEGIN
		UPDATE ChatBotConversationMessage SET MessageStatus = @messageStatus
		WHERE ConversationChatBotId = @conversationChatBotId AND message_uuid = @message_uuid
		AND OriginType = @originType
	END

	set nocount off'
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
					[description] [varchar](100) NOT NULL
				PRIMARY KEY CLUSTERED 
				(
					[id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]
				END'
	EXEC(@sql)

	SET @process = 'K060006 Insert the EndStatus in the table'
	SET @sql = 'TRUNCATE TABLE ChatBotConversationEndStatus;
				INSERT INTO ChatBotConversationEndStatus ([name],[description])
				VALUES 
				(''Finish'',''Finished by contact''), 
				(''Fail'',''Finished on failure''), 
				(''Transfer'',''Transferred to WhatsApp''),
				(''Callback'',''Transferred to call''), 
				(''Abandon'',''Abandoned'');'
	EXEC(@sql)

	SET @process = 'K060014 se agregan etiquetas correspindientes para los estatus'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM   INFORMATION_SCHEMA.COLUMNS 
	WHERE  TABLE_NAME = ''ChatBotConversationEndStatus''
	AND COLUMN_NAME = ''tag'')
	BEGIN
		alter table ChatBotConversationEndStatus 
		add [tag] [varchar](50),
			[es] [varchar](100),
			[en] [varchar](100),
			[pt] [varchar](100)
	END'
	EXEC(@sql)

	SET @process = 'K060014 se agregan etiquetas correspindientes para los estatus'
	SET @sql = 'UPDATE ChatBotConversationEndStatus SET [tag] = ''finished-by-contact'', es =''Finalizada por contacto'', en = ''Finished by contact'',pt =''Encerrada pelo contato'' where id = 1
	UPDATE ChatBotConversationEndStatus SET [tag] = ''finished-on-failure'', es = ''Finalizada por falla'', en = ''Finished on failure'', pt = ''Encerrada após falha'' where id = 2
	UPDATE ChatBotConversationEndStatus SET [tag] = ''transferred-to-whatsapp'', es = ''Transferida a WhatsApp'', en = ''Transferred to WhatsApp'', pt = ''Transferida para WhatsApp'' where id = 3
	UPDATE ChatBotConversationEndStatus SET [tag] = ''transferred-to-call'', es = ''Transferida a llamada'', en = ''Transferred to call'', pt = ''Transferida para chamada'' where id = 4
	UPDATE ChatBotConversationEndStatus SET [tag] = ''abandoned'', es = ''Abandonada'', en = ''Abandoned'', pt = ''Abandonada'' where id = 5
	'
	EXEC(@sql)

	---Todo es necesario eliminar antes de crear ccsp_GalateaChatBotConversationsResult
	SET @process = 'K060008-Se Drop SP ccsp_GalateaChatBotConversationsResult'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaChatBotConversationsResult'')
	begin
	    DROP PROCEDURE ccsp_GalateaChatBotConversationsResult;
	end'
	EXEC(@sql)


	SET @process = 'K060008 -Create or Alter SP ccsp_GalateaChatBotConversationsResult to insert abandoned conversations correctly'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaChatBotConversationsResult]
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

	SET @process = 'K060026- Drop SP ccsp_Get_ChatBot_Relations'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Get_ChatBot_Relations'')
	begin
	    DROP PROCEDURE ccsp_Get_ChatBot_Relations;
	end'
	EXEC(@sql)

	---Todo es necesario eliminar antes de crear ccsp_Get_ChatBot_Relations
	SET @process = 'K060026 Create or Alter procedure ccsp_Get_ChatBot_Relations to return related inbound campaigns'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_Get_ChatBot_Relations]
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

	SET @process = 'K060000-Se Drop SP ccsp_Get_Azure_Knowledge'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Get_Azure_Knowledge'')
	begin
	    DROP PROCEDURE ccsp_Get_Azure_Knowledge;
	end'
	EXEC(@sql)


	SET @process = 'K0026 Add A SELECT for default Messages'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_Get_Azure_Knowledge]
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
	end'
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

	SET @process = 'K060017 Add the menus of new reports and report menu'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM ccMenus WHERE menu_id = 15000 OR menu_id = 15010 OR menu_id = 15020 OR menu_id = 15030) BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF) VALUES
					(15000, ''Chatbot|Chatbot'', 15000, ''A'', 12, 3, ''''),
					(15010, ''Detalle de conversaciones|Conversations Detail'', 15000, ''B'', 12, 3, ''''),
					(15020, ''Conversaciones por chatbot|Conversations by Chatbot'', 15000, ''B'', 12, 3, ''''),
					(15030, ''Conversaciones transferidas a WhatsApp|Transferred Conversations to WhatsApp'', 15000, ''B'', 12, 3, '''');
				END'
	EXEC(@sql)
	
	SET @process = 'K060017 Add the release encrypted value to the menus'
	SET @sql = 'IF EXISTS(SELECT * FROM ccMenus WHERE menu_id = 15000 OR menu_id = 15010 OR menu_id = 15020 OR menu_id = 15030) BEGIN
					UPDATE ccMenus SET release = ''33b95227bffa5d65c9153de6446d153bd6852b9bf809975e12d665594f21f41b'' WHERE ccMenus.menu_id = 15000
					UPDATE ccMenus SET release = ''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370'' WHERE ccMenus.menu_id = 15010
					UPDATE ccMenus SET release = ''2605c8244920fb599fb936a4bf94521abfec097ca281c5864874691fe77a9dcb497d9428f876069fee726e663efa2ea23fd5c333b0be8fbc714d53e1fcb087c8'' WHERE ccMenus.menu_id = 15020
					UPDATE ccMenus SET release = ''2605c8244920fb599fb936a4bf94521ac1d8958f95ce9d3d1dcfbee594bd612c14c53787eec7f5671ec8aeeced55be43d4aafdd18714a1f51cd96626558813a4e4e0613c02e23f40e9f6b8341c44cf20'' WHERE ccMenus.menu_id = 15030
				END'
	EXEC(@sql)

	
	SET @process = 'K060013-Se Drop SP ccsp_Save_ChatBot_Conversation'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Save_ChatBot_Conversation'')
	begin
	    DROP PROCEDURE ccsp_Save_ChatBot_Conversation;
	end'
	EXEC(@sql)
	

	SET @process = 'K060013-Buscador-Conversaciones ChatBot, se agrega condicion para crear nodo multimedia'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_Save_ChatBot_Conversation]
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

		
	SET @process = 'K060033- Se crea tabla ccUnsentWAMessagesToAzureKnowledge para guardar mensajes pendientes para envíar a azure knowledge'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccUnsentWAMessagesToAzureKnowledge'') begin
		CREATE TABLE ccUnsentWAMessagesToAzureKnowledge(
			message_uuid VARCHAR(50) PRIMARY KEY,
			MessageJson VARCHAR(MAX) NOT NULL,
			[timestamp] datetime NOT NULL
		)
	END'
	EXEC(@sql)

	SET @process = 'K060033-Se Drop SP ccsp_UnsentMessagesToAzureKnowledge'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_UnsentMessagesToAzureKnowledge'')
	begin
	    DROP PROCEDURE ccsp_UnsentMessagesToAzureKnowledge;
	end'
	EXEC(@sql)

	SET @process = 'K060033- Se crea SP ccsp_UnsentMessagesToAzureKnowledge para gestionar mensajes pendientes para envíar a azure knowledge'
	SET @sql = 'CREATE PROCEDURE ccsp_UnsentMessagesToAzureKnowledge
	@action INT, 
	@MessageJson VARCHAR(max) = NULL, 
	@timestamp datetime = NULL,
	@message_uuid varchar(50) = null
	AS
	BEGIN
		IF @action = 1
		BEGIN
			DECLARE @ConversationId bigint = 0;
			IF EXISTS (SELECT ConversationChatBotId FROM ChatBotConversationMessage  where ISNULL(PendingToAzure, 0) = 0 and message_uuid = @message_uuid)
			BEGIN
				UPDATE ChatBotConversationMessage SET PendingToAzure = 1 WHERE message_uuid = @message_uuid;
				INSERT INTO ccUnsentWAMessagesToAzureKnowledge(message_uuid, MessageJson, [timestamp]) values(@message_uuid, @MessageJson, @timestamp)
				SELECT @ConversationId = ConversationChatBotId FROM ChatBotConversationMessage  where PendingToAzure = 1 and message_uuid = @message_uuid;
			END
			Select @ConversationId as ConversationId
			RETURN 0;
		END
		IF @action = 2
		BEGIN
			--SELECT MessageId, MessageJson from ccUnsentWAMessagesToAzureKnowledge ORDER BY [timestamp] asc
			SELECT a.Message_uuid, a.ConversationChatBotId as ConversationId, b.MessageJson from 
			ChatBotConversationMessage a
			INNER JOIN ccUnsentWAMessagesToAzureKnowledge b on a.message_uuid = b.message_uuid
			WHERE PendingToAzure = 1
			ORDER BY [timestamp] asc
			RETURN 0;
		END
		IF @action = 3
		BEGIN
			DELETE  FROM ccUnsentWAMessagesToAzureKnowledge WHERE message_uuid = @message_uuid
			UPDATE ChatBotConversationMessage set PendingToAzure = 2 WHERE PendingToAzure = 1 and  message_uuid = @message_uuid
			RETURN 0;
		END
	END'
	EXEC(@sql)

	SET @process = 'K060000-Se crea Tabla IVRChatBot'
	SET @sql = 'if not exists(select * from sys.tables where name=''IVRChatBot'') begin
	CREATE TABLE [dbo].[IVRChatBot](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ChatBotName] [varchar](255) NOT NULL,
	[Client] [varchar](255) NOT NULL,
	[IVR] [nvarchar](max) NOT NULL,
	[Language] [varchar](50) NOT NULL
	)

insert into [IVRChatBot] (ChatBotName,Client,IVR,Language)
values(''ChatBotTestivr'',''Laboratorio Médico Polanco''
,''{    "0":    {     "title":"Menú Principal",     "message":"Laboratorio Médico Polanco y estoy aquí para ayudarte\nPuedes conocer nuestro Aviso de Privacidad para el tratamiento de tus datos aquí: ??\n\nhttp://c1i.co/a00lr0f2\n\n¿En qué te podemos ayudar hoy? ??\nEscribe el número de la opción deseada",     "option":     {      "1":{"text":"\n1. Estudios y cotizaciones", "next":"1"},      "2":{"text":"\n2. Horarios y sucursales cercanas", "next":"2"},      "3":{"text":"\n3. Perfiles respiratorios y COVID", "next":"3"},      "4":{"text":"\n4. Resultados", "next":"4"},      "5":{"text":"\n5. Descarga tu factura", "next":"5"}     }        },    "1":    {     "title":"Estudios y cotizaciones",     "message":"A continuación, selecciona la categoría del estudio que deseas cotizar: ??",     "option":     {      "1":{"text":"\n1. Salud Mujer", "next":"1.1"},      "2":{"text":"\n2. Prevención", "next":"1.2"},      "3":{"text":"\n3. Salud Hombre", "next":"1.3"},      "4":{"text":"\n4. COVID", "next":"1.4"},      "5":{"text":"\n5. Análisis Clínicos", "next":"1.5"},      "6":{"text":"\n6. Imagenología", "next":"1.6"},      "7":{"text":"\n7. Menu Inicial", "next":"0"}     }    },    "1.1":    {     "title":"Salud Mujer",     "message":"Por favor, escribe el número del estudio de tu interés: ??",     "option":     {      "1":{"text":"\n1. Perfil Hormonal", "next":"1.1.1"},      "2":{"text":"\n2. Check up Mamario", "next":"1.1.2"},      "3":{"text":"\n3. Check up Mujer LMP", "next":"1.1.3"},      "4":{"text":"\n4. Menu estudios", "next":"1"},      "5":{"text":"\n5. Menu inicial", "next":"0"}     }    },    "1.1.1":    {     "title":"Perfil Hormonal",     "message":"Perfil Hormonal 1\n\n?? Precio de lista: $3,796.00\n\n?? Precio promoción: $1,619.00\n\n?? Los precios pueden variar sin previo aviso. A continuación, te mostramos las indicaciones: ?? \n\n? Recomendable 4 horas de ayuno. Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ?? \n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "Si":{"text":"\n1. Si ?", "next":"1.1.1.1"},      "No":{"text":"\n2. No ?", "next":"1.1.1.2"}     }    },    "1.1.1.1":    {     "title":"Perfil Hormonal Si",     "message":"En breve, uno de nuestros asesores ???? atenderá tu consulta. \n\nRecuerda, cuidarte es amarte. ??",     "metadata":     {      "get_campaigns":true,      "extra_metadata":true     }    },    "1.1.1.2":    {     "title":"Perfil Hormonal No",     "message":"Por favor, escribe el número del estudio de tu interés: ??",     "option":     {      "1":{"text":"\n1. Menú anterior", "next":"1.1.1"},      "2":{"text":"\n2. Menú Salud Mujer", "next":"1.1"},      "3":{"text":"\n3. Menú inicial", "next":"0"},      "4":{"text":"\n4. Hablar con asesor", "next":"-2"},      "5":{"text":"\n5. Salir", "next":"-1"}     }    },    "1.1.2":    {     "title":"Check Up Mamario",     "message":"Check Up Mamario\n\n?? Precio de lista: $2,298.00\n\n?? Precio promoción: $1,149.00\n\n?? Los precios pueden variar sin previo aviso. A continuación, te mostramos las indicaciones: ?? \n\n? Recomendable 4 horas de ayuno. Es importante que te prepares para tus estudios. ??¿Deseas adquirir tu estudio ahora? ??\n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "Si":{"text":"\n1. Si ?", "next":"1.1.2.1"},      "No":{"text":"\n2. No ?", "next":"1.1.2.2"}     }    },    "1.1.2.1":    {     "title":"Check Up Mamario Si",     "message":"En breve, uno de nuestros asesores ???? atenderá tu consulta. \n\nRecuerda, cuidarte es amarte. ??",     "metadata":     {      "get_campaigns":true     }    },    "1.1.2.2":    {     "title":"Check Up Mamario No",     "message":"¿Te podemos ayudar en algo más? ?? \n\nSelecciona una de las siguientes opciones: ?? A continuación, te mostramos las indicaciones: ?? \n\n? 1. Ser mayor de 39 años.\n? 2. Menor de 40 años presentar receta original.\n? 2. Realizar aseo general.\n? 3. No aplicar desodorante, crema, talco, etc., sobre la piel. \n? 5. En caso de contar con estudios previos presentarlos. \n? 6. Agendar cita.\n{0:33 p. m., 12/10/2023} Laboratorio Médico Polanco: Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ??\n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "1":{"text":"\n1. Menú anterior", "next":"1.1.2"},      "2":{"text":"\n2. Menú Salud Mujer", "next":"1.1"},      "3":{"text":"\n3. Menú inicial", "next":"0"},      "4":{"text":"\n4. Hablar con asesor", "next":"-2"},      "5":{"text":"\n5. Salir", "next":"-1"}     }    },    "1.1.3":    {     "title":"Check Up Mujer LMP",     "message":"Check Up Mujer LMP\n\n?? Precio de lista: $5,398.00\n\n?? Precio promoción: $2,699.00. A continuación, te mostramos las indicaciones: ??\n\n? Es importante la preparación para tus estudios por favor descargue la información y agende su cita, PMLMP36.png. Es importante que te prepares para tus estudios. ?? Por favor descarga la información que te muestro a continuación: ?? Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ?? \n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "1":{"text":"\n1. Si ?", "next":"1.1.3.1"},      "2":{"text":"\n2. No ?", "next":"1.1.3.2"}     }    },    "1.1.3.1":    {     "title":"Check Up Mujer LMP Si",     "message":"En breve, uno de nuestros asesores ???? atenderá tu consulta. \n\nRecuerda, cuidarte es amarte. ??",     "metadata":     {      "get_campaigns":true     }    },    "1.1.3.2":    {     "title":"Check Up Mujer LMP No",     "message":"¿Te podemos ayudar en algo más? ?? \n\nSelecciona una de las siguientes opciones: ?? A continuación, te mostramos las indicaciones: ?? \n\n? 1. Ser mayor de 39 años.\n? 2. Menor de 40 años presentar receta original.\n? 2. Realizar aseo general.\n? 3. No aplicar desodorante, crema, talco, etc., sobre la piel. \n? 5. En caso de contar con estudios previos presentarlos. \n? 6. Agendar cita.\nLaboratorio Médico Polanco: Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ?? \n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "1":{"text":"\n1. Menú anterior", "next":"1.1.3"},      "2":{"text":"\n2. Menú Salud Mujer", "next":"1.1"},      "3":{"text":"\n3. Menú inicial", "next":"0"},      "4":{"text":"\n4. Hablar con asesor", "next":"-2"},      "5":{"text":"\n5. Salir", "next":"-1"}     }    },    "1.2":    {     "title":"Prevención",     "message":"Por favor, escribe el número del estudio de tu interés: ??",     "option":     {      "1":{"text":"\n1. Check Up Tiroideo", "next":"1.2.1"},      "2":{"text":"\n2. Check Up Integral", "next":"1.2.2"},      "3":{"text":"\n3. Check Up Básico", "next":"1.2.3"},      "4":{"text":"\n4. Check Up Saludable", "next":"1.2.4"},      "5":{"text":"\n5. Menú estudios", "next":"1"},      "6":{"text":"\n6. Menú inicial", "next":"0"}     }    },    "1.2.1":    {     "title":"Check Up Tiroideo",     "message":"?? Precio de lista: $3,598.00\n\n?? Precio promoción: $1,799.00\n\n?? Los precios pueden variar sin previo aviso. A continuación, te mostramos las indicaciones: ?? \n\n? 1. Ayuno entre 9 y 16 horas. \n? 2. El último alimento debe ser el habitual.  \n? 3. Se prefiere la primera orina de la mañana en frasco otorgado en sucursal. \n? 4. Mujeres: no estar menstruando. Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ??",     "option":     {      "Si":{"text":"\n1. Si ?", "next":"1.2.1.1"},      "No":{"text":"\n2. No ?", "next":"1.2.1.2"}     }    },    "1.5":    {     "title":"Análisis Clínicos",     "message":"Por favor, escribe el número del estudio de tu interés: ??\nEscribe el número de la opción deseada",     "option":     {      "1":{"text":"\n1. Biometría Hemática", "next":"1.5.1"},      "2":{"text":"\n2. Hemoglobina Glucosilada (HB-A1C)", "next":"1.5.2"},      "3":{"text":"\n3. Química Sanguí­nea de 27 elementos", "next":"1.5.3"},      "4":{"text":"\n4. Química Sanguínea de 36 elementos", "next":"1.5.4"},      "5":{"text":"\n5. Vitamina D(25 HIDROXICOLECALCIFEROL)", "next":"1.5.5"},      "6":{"text":"\n6. Menú estudios", "next":"1"},      "7":{"text":"\n7. Menú inicial", "next":"0"}     }    },    "1.5.1":    {     "title":"Biometría Hemática",     "message":"Biometría Hemática\n\n?? Precio de lista: $534.00\n\n?? Precio promoción: $267.00\n\n?? Los precios pueden variar sin previo aviso. A continuación, te mostramos las indicaciones: ??\n\n? No se requiere ayuno\n? Nota: El precio promoción aplica si eres miembro del programa Recompensas Polanco Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ?? \n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "Si":{"text":"\n1. Si ?", "next":"1.5.1.1"},      "No":{"text":"\n2. No ?", "next":"1.5.1.2"}     }    },    "1.5.1.1":    {     "title":"Biometría Hemática Si",     "message":"¿Te podemos ayudar en algo más? ?? \n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "1":{"text":"\n1. Menú anterior", "next":"1.5.1"},      "2":{"text":"\n2. Menú Anális Clínicos", "next":"1.5"},      "3":{"text":"\n3. Menú inicial", "next":"0"},      "4":{"text":"\n4. Hablar con asesor", "next":"-2"},      "5":{"text":"\n5. Salir", "next":"-1"}     }    },    "1.5.1.2":    {     "title":"Biometría Hemática No",     "message":"¿Te podemos ayudar en algo más? ?? \n\nSelecciona una de las siguientes opciones: ?? A continuación, te mostramos las indicaciones: ?? \n\n? 1. Ser mayor de 39 años.\n? 2. Menor de 40 años presentar receta original.\n? 2. Realizar aseo general.\n? 3. No aplicar desodorante, crema, talco, etc., sobre la piel. \n? 5. En caso de contar con estudios previos presentarlos. \n? 6. Agendar cita.\n{0:33 p. m., 12/10/2023} Laboratorio Médico Polanco: Es importante que te prepares para tus estudios. ?? ¿Deseas adquirir tu estudio ahora? ??\n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "1":{"text":"\n1. Menú anterior", "next":"1.5.1"},      "2":{"text":"\n2. Menú Anális Clínicos", "next":"1.5"},      "3":{"text":"\n3. Menú inicial", "next":"0"},      "4":{"text":"\n4. Hablar con asesor", "next":"-2"},      "5":{"text":"\n5. Salir", "next":"-1"}     }    },    "2":    {     "title":"Sucursales",     "message":"Compártenos tu Código Postal o ubicación y te mostraremos nuestras sucursales más cercanas! \n\nSelecciona una de las siguientes opciones: ??",     "option":     {      "1":{"text":"\n1. Código Postal", "next":"2.1"},      "2":{"text":"\n2. Ubicación", "next":"2.2"}     }    },    "2.1":    {     "title":"Sucursales Código Postal",     "message":"Aquí está el listado de sucursales ?? más cercanas a ti: ??\n\n? Agrícola Oriental \nAv. Javier Rojo Gómez No. 382 \nhorario: \nlunes a viernes: 07:00-15:00 \nsábado: 07:00-15:00 domingo: N/A \nubicación: https://www.google.com/maps/search/?api=1&map_action=map&query=19.391767,-99.073786&zoom=10\n\n? Ermita \nAvenida Ermita Iztapalapa No. 927 \nhorario: \nlunes a viernes: 07:00-15:00 \nsábado: 07:00-15:00 \ndomingo: 08:00-14:00 \nubicación: https://www.google.com/maps/search/?api=1&map_action=map&query=19.355734,-99.101457&zoom=10\n\n? Jardín Balbuena \nAvenida Fray Servando No. 935 \nhorario: \nlunes a viernes: 06:00-19:00 \nsábado: 06:00-15:00 \ndomingo: 08:00-14:00 \nubicación: https://www.google.com/maps/search/?api=1&map_action=map&query=19.417487,-99.103439&zoom=10\n\n? Aragón \nCalle 34 Local 1 \nhorario: \nlunes a viernes: 07:00-18:00 \nsábado: 07:00-15:00 \ndomingo: 08:00-14:00 \nubicación: https://www.google.com/maps/search/?api=1&map_action=map&query=19.478164,-99.053915&zoom=10 Puedes verificar con uno de nuestros asesores ???? los servicios disponibles. ¿Qué deseas hacer ahora? ?? \n\nSelecciona una de las siguientes opciones: ?? \n\nPowered by Auronix",     "option":     {      "1":{"text":"\n1. Menú inicial", "next":"0"},      "2":{"text":"\n2. Asesor", "next":"-1"}     }    }  }'',
''ES'')
	
	end'
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
