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

/* Version to release (use the version of your own databse)*/
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

	SET @process = 'K060008- Create Table ccChatBotConversationsResult'
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
end

'
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

	SET @process = 'K060008 -Create SP ccsp_GalateaChatBotConversationsResult'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaChatBotConversationsResult]
@action int,@chatBotId int,@status int=0,
@conversationId bigint=0,@campaignId int=0,
@activeConversations int = 0
AS
set nocount on

IF @action=0 BEGIN --Insertar estado de finalización en Tabla de Conversaciones
	UPDATE ChatBotConversation SET  EndStatus=@status, CampIdTransfered=@campaignId WHERE ChatBotConversationId = @conversationId;
	EXEC ccsp_GalateaChatBotConversationsResult @action=1, @chatBotId=@chatBotId,
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
