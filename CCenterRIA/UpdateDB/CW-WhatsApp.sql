/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 22
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
	set @process = 'CW-WhatsApp crea SP tabla conversaciones whatsapp'
    set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccRIAWhatsAppConversations]'') AND type in (N''U''))
BEGIN
CREATE TABLE [dbo].[ccRIAWhatsAppConversations](
	[conversationId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[inboundId] [smallint] NOT NULL,
	[phoneACD] [varchar](50) NOT NULL,
	[clientId] [varchar](25) NOT NULL,
	[conversationStatus] [smallint] NOT NULL,
	[tChatting] [int] NOT NULL,
	[tConversation] [int] NULL,
	[tWrapUp] [smallint] NOT NULL,
	[requestDate] [datetime] NOT NULL,
	[finishedBy] [tinyint] NULL,
	[onQueue] [bit] NULL,
	[tQueue] [smallint] NOT NULL,
	[tTimeout] [int] NOT NULL,
	[disposition] [smallint] NOT NULL,
	[subDisposition] [smallint] NOT NULL,
	[conversationDate] [datetime] NULL,
	[clientName] [varchar](100) NULL,
	[firstMessageTime] [datetime] NULL,
 CONSTRAINT [pk_ccRIAWhatsAppMessages_1] PRIMARY KEY CLUSTERED 
(
	[conversationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[DF_ccRIAWhatsAppConversations_requestDate]'') AND type = ''D'')
BEGIN
ALTER TABLE [dbo].[ccRIAWhatsAppConversations] ADD  CONSTRAINT [DF_ccRIAWhatsAppConversations_requestDate]  DEFAULT (getdate()) FOR [requestDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[DF_ccRIAWhatsAppConversations_conversationDate]'') AND type = ''D'')
BEGIN
ALTER TABLE [dbo].[ccRIAWhatsAppConversations] ADD  CONSTRAINT [DF_ccRIAWhatsAppConversations_conversationDate]  DEFAULT (getdate()) FOR [conversationDate]
END
GO
'
 EXEC(@sql)


	set @process = 'CW-WhatsApp valida y si existe SP´para guardar calificaciones whatsapp'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_SaveDispositionsMultimedia'')
            begin
          DROP PROCEDURE ccsp_SaveDispositionsMultimedia;
            end'
    EXEC(@sql)

	set @process = 'CW-WhatsApp crea SP ccsp_SaveDispositionsMultimedia'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia]

	@action int,
	@conversationId int=0,
	@disposition smallint=0,
	@subDisposition smallint=0,
	@tWrapUp smallint=0,
	@mediaType smallint=0

AS
BEGIN
	
SET NOCOUNT ON;
	
	IF @action = 1 BEGIN --Califica la conversación y pone el tiempo Notas
		DECLARE @Temp NVARCHAR(1000)= N''UPDATE '' + (SELECT CASE @mediaType
						WHEN 5 THEN ''ccRIAWhatsAppConversations''
						WHEN 6 THEN ''chat''
						ELSE ''''
					END AS MediaTypeString) + 
					'' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;'' 
		EXEC sp_executesql @temp, N''@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT'', @disposition, @subDisposition, @tWrapUp, @conversationId;
	END
END'
	
	EXEC(@sql)
	
	
	set @process = 'CW-WhatsApp valida y si existe SP MultimediaCommon'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
            begin
          DROP PROCEDURE ccsp_MultimediaCommon;
            end'
    EXEC(@sql)

	set @process = 'CW-WhatsApp crea SP ccsp_MultimediaCommon '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon] 
@Option AS SMALLINT, 
@inboundId AS SMALLINT = 0, 
@conversationId AS INT = 0, 
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0
AS
BEGIN
    SET NOCOUNT ON;

    IF(@Option = 1)
		BEGIN
			/*SELECT Inbound_id AS Id, 
				   descripcion as Name, 
				   CAST(Status as bit), 
				   chat as Type 
			  FROM ccInbound 
			 WHERE chat <> 0*/

			 SELECT --inbound.chat AS ServiceType,
			   CAST(inbound.Inbound_id AS INT) AS ACDId,
			   inbound.descripcion AS ACDName,
			   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
			   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
			   inbound.tNotas AS WrapUpTime
			   --configuration.closeConversationTime AS CloseConversationMaxTime,
			   --CAST(Status as bit)

			   FROM  ccInbound inbound
			   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
		END      
	--ELSE
	--	BEGIN
 --           raiserror(''ERROR. No existe la opcion seleccionada o es nula'', 18, 1)
 --       END 

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
				i.tNotas as [WrapUpTime]
			FROM  ccInbound i
				INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
				INNER JOIN ccRIAWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
				INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
			WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
		END
	
	
END'
	
	EXEC(@sql)
	
	set @process = 'CW-WhatsApp valida y si existe SP ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql)

	set @process = 'CW-WhatsApp crea SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave]

	@action int,
	@conversationId int=0,
	@inboundId smallint=null,
	@phoneACD varchar(50)= null,
	@clientId varchar(25)= null,
	@conversationStatus smallint=0,
	@tChatting smallint=0,
	@tWrapUp smallint=0,
	@finishedBy tinyint = 0,
	@onQueue bit = null,
	@tQueue smallint = 0,
	@tTimeout int = 0,
	@clientName varchar(100)= null,
	@disposition smallint=0,
	@subDisposition smallint=0

AS
BEGIN
	DECLARE @isEndConversation bit
	DECLARE @meanContactTypeId smallint

	SET @meanContactTypeId = 1
SET NOCOUNT ON;

	IF @action = 1 BEGIN --new Conversation
		IF NOT EXISTS(SELECT A.conversationId conversationId FROM ccRIAWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccRIAWhatsAppConversations](
												inboundId, phoneACD, clientId, conversationStatus, tChatting, 
												tWrapUp, finishedBy, onQueue, tQueue, tTimeout, clientName, disposition, subDisposition) values 
											   (@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, 
												@tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @clientName, @disposition, @subDisposition)
			SELECT @conversationId=SCOPE_IDENTITY()
			SELECT @conversationId as ConversationId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS ConversationId
			RETURN (0)
		END
	END

	IF @action = 2 BEGIN --save conversation Times
		Update ccRIAWhatsAppConversations 
		set tChatting = DATEDIFF(ss,conversationDate,getdate()), 
			conversationStatus = @conversationStatus, finishedBy = 1,
			tConversation = DATEDIFF(ss,requestDate,getdate()) 
		where conversationId = @conversationId  
	END
END'
	
	EXEC(@sql)
	

	
	set @process = 'CW-WhatsApp insert setting 230 MultimediaCommon'
	set @sql = 'if not exists(select * from ccsettings where setting_id=230) 
	begin
		INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
		VALUES (230,''\Multimedia\Conversations\WhatsApp\ '',''Ruta donde se guardarán las conversaciones de WhatsApp'',	1,
				''GRL'',''Se guardan los archivos .json separados por carpetas'',''Path for saving WhatsApp conversations'',1,''.{0,99}'');
	end'
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