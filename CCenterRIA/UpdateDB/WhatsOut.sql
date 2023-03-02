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
SET @versionfix = 4
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
		------------------------------------------------- BEGIN K00200- WhatsApp Out ----------------------------------------------------------------------

		------------------------------------------------- BEGIN K00200- Create Table Or Alter ----------------------------------------------------------------------
		SET @process = 'K00200- WhatsApp Out Create Table ccDisconnectionMCSOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccDisconnectionMCSOut'') begin
CREATE TABLE [dbo].[ccDisconnectionMCSOut](
	[disconnectionId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[timeStampDisconnection] [datetime] NOT NULL,
	[timeStampConnection] [datetime] NULL
)
end'
		EXEC(@sql)

		SET @process = 'K00200- WhatsApp Out Create Table ccWAMessagesConversationsOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWAMessagesConversationsOut'') begin
CREATE TABLE [dbo].[ccWAMessagesConversationsOut](
	[messageId] [varchar](75) NOT NULL,
	[conversationId] [int] NOT NULL,
	[timeStampMessage] [datetime] NOT NULL,
	[originType] [varchar](15) NOT NULL,
	[price] [varchar](10) NOT NULL,
	[messageIdUi] [int] NULL,
	[currency] [varchar](10) NULL,
	[typeMessage] [varchar](25) NULL,
	[content] [nvarchar](max) NULL,
	[clientNum] [varchar](15) NULL,
	[vonageNum] [varchar](15) NULL,
	[timeStampMessageUTC] [datetime] NULL,
	[messageStatus] [varchar](15) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Id que se recibe de parte de vonage'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''messageId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Id de la tabla ccWhatsAppConversationsOut.conversationId'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''conversationId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Fecha que lle el mensaje del Api'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''timeStampMessage''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Quien envio el mensaje Client o Agent'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''originType''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Precio del mensaje'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''price''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N'''' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''messageIdUi''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Costo del mensaje'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''currency''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tipo de mensaje enviado image,text,audio,video,...'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''typeMessage''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Mensaje enviado o recibido texto o ruta del archivo'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''content''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Numero del cliente que envio el mensaje'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''clientNum''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Numero que se registra de vonage '' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''vonageNum''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Fecha del mensaje en utc'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''timeStampMessageUTC''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Estado de los mensansajes messageStatus.messageStatusId'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut'', @level2type=N''COLUMN'',@level2name=N''messageStatus''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tabla guarda los mensajes'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWAMessagesConversationsOut''

end'
		EXEC(@sql)

		SET @process = 'K020016-Resultados de envío mensajes de WhatsApp de salida'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWAConversationsResult'') begin
CREATE TABLE [dbo].[ccWAConversationsResult] (
	[camId] [SMALLINT] NOT NULL,
	[SentMsg] [int] not null,
	[Delivered] [int] not null,
	[NotDelivered] [int] not null,
	[ReadMsg] [int] not null,
	[NotSupported] [int] not null,
)
end'
		EXEC(@sql)

		SET @process = 'K020093-Env�o manual WhatsApp de salida Create Table ccWAOperatingSummaryOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWAOperatingSummaryOut'') begin
CREATE TABLE [dbo].[ccWAOperatingSummaryOut](
	[CamId] [int] NOT NULL,
	[Attended] [int] NULL,
	[OnQueue] [int] NULL,
	[Assigned] [int] NULL,
	[Request] [int] NULL,
	[EndedBySystem] [int] NULL,
	[Available] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ccWAOperatingSummaryOut] ADD  DEFAULT ((0)) FOR [Attended]
ALTER TABLE [dbo].[ccWAOperatingSummaryOut] ADD  DEFAULT ((0)) FOR [OnQueue]
ALTER TABLE [dbo].[ccWAOperatingSummaryOut] ADD  DEFAULT ((0)) FOR [Assigned]
ALTER TABLE [dbo].[ccWAOperatingSummaryOut] ADD  DEFAULT ((0)) FOR [Request]
ALTER TABLE [dbo].[ccWAOperatingSummaryOut] ADD  DEFAULT ((0)) FOR [EndedBySystem]
ALTER TABLE [dbo].[ccWAOperatingSummaryOut] ADD  DEFAULT ((0)) FOR [Available]

end'
		EXEC(@sql)

		SET @process = 'K020093-Env�o manual WhatsApp de salida Create Table ccWAAverageConversationsOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWAAverageConversationsOut'') begin
CREATE TABLE [dbo].[ccWAAverageConversationsOut](
	[CamId] [smallint] NOT NULL,
	[AverageConversationTime] [int] NULL,
	[AverageDialogTime] [int] NULL,
	[AverageWaitingTime] [int] NULL,
	[MaximumWaitingTime] [int] NULL,
	[ServiceLevel] [smallint] NULL,
	[StatusUpdate] [bit] NULL,
	[LastUpdate] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ccWAAverageConversationsOut] ADD  DEFAULT ((0)) FOR [ServiceLevel]

ALTER TABLE [dbo].[ccWAAverageConversationsOut] ADD  DEFAULT ((0)) FOR [StatusUpdate]

End'
		EXEC(@sql)

		SET @process = 'K020093-Env�o manual WhatsApp de salida Create Table ccLastMessageAgentByConversationOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccLastMessageAgentByConversationOut'') begin
CREATE TABLE [dbo].[ccLastMessageAgentByConversationOut](
	[conversationId] [int] NOT NULL,
	[timeStampLastMessageAgent] [datetime] NOT NULL,
	[desconnectionAgent] [datetime] NULL
) ON [PRIMARY]


ALTER TABLE [dbo].[ccLastMessageAgentByConversationOut] ADD  DEFAULT (getdate()) FOR [timeStampLastMessageAgent]

End'
		EXEC(@sql)

		SET @process = 'K020093-Env�o manual WhatsApp de salida Create Table ccWhatsAppOutNode'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWhatsAppOutNode'') begin

CREATE TABLE [dbo].[ccWhatsAppOutNode](
	[conversationId] [int] NOT NULL,
	[node] [xml] NULL,
	[dateIn] [datetime] NULL,
	[dateOut] [datetime] NULL,
	[status] [smallint] NULL
	)

ALTER TABLE [dbo].[ccWhatsAppOutNode] ADD  DEFAULT (NULL) FOR [dateOut]


ALTER TABLE [dbo].[ccWhatsAppOutNode] ADD  DEFAULT ((0)) FOR [status]
End'
		EXEC(@sql)

		SET @process = 'K020093-Env�o manual WhatsApp de salida  Create Table ccWhatsAppOutNodeHistory'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWhatsAppOutNodeHistory'') begin

CREATE TABLE [dbo].[ccWhatsAppOutNodeHistory](
	[conversationId] [int] NOT NULL,
	[node] [xml] NULL,
	[dateIn] [datetime] NULL,
	[dateOut] [datetime] NULL,
	[status] [smallint] NULL
	)


End'
		EXEC(@sql)			

		SET @process = 'K020093-Env�o manual WhatsApp de salida Create Table ccWhatsAppConversationsOut'
		SET @sql = '
if not exists(select * from sys.tables where name=''ccWhatsAppConversationsOut'') begin
CREATE TABLE [dbo].[ccWhatsAppConversationsOut](
	[conversationId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[camId] [smallint] NOT NULL,
	[phoneCamp] [varchar](50) NOT NULL,
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
	[assignDate] [datetime] NULL,
	[agentId] [int] NULL,
	[FirstMessageAgent] [datetime] NULL
) ON [PRIMARY]


ALTER TABLE [dbo].[ccWhatsAppConversationsOut] ADD  CONSTRAINT [DF_ccWhatsAppConversationsOut_requestDate]  DEFAULT (getdate()) FOR [requestDate]

EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Indentificador de la tabla guarda las conversaciones'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''conversationId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Identificador de la campa�a en ccCamps'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''camId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Numero de whatsapp donde se enviara el mensaje'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''phoneCamp''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Numero del cliente que se desea enviar'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''clientId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Estado de la conversaciones'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''conversationStatus''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tiempo que paso en dialo el agente'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''tChatting''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tiempo que duro la conversacion'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''tConversation''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tiempo de notas'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''tWrapUp''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Cuando llega la conversacion por primera vez al multimedia'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''requestDate''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''(0) Conversacion abierta. (1) Conversacion cerrada'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''finishedBy''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Si el mensaje estuvo en cola de espera'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''onQueue''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tiempo que paso en espera antes de ser antendida por un agente'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''tQueue''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tiempo para responder el mensaje cuando contesta el cliente'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''tTimeout''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Id de la calificacion ccTipoCalifOUT.calif_id'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''disposition''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Id de la subcalificacion ccTipoCalifSubOUT.califSub_id'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''subDisposition''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''cuando empieza la conversacion'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''conversationDate''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Fecha que fue asignado al agente'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''assignDate''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Identificado de agente ccUsers.user_id'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''agentId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Fecha que se envio el primer mensaje el agente'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut'', @level2type=N''COLUMN'',@level2name=N''FirstMessageAgent''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tabla donde se guarda las conversaciones de salida whatsapp'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsOut''
end'
		EXEC(@sql)

		SET @process = 'K020093-Env�o manual WhatsApp de salida Create Table ccWhatsAppConversationsRelationshipOut'
		SET @sql = '
if not exists(select * from sys.tables where name=''ccWhatsAppConversationsRelationshipOut'') begin

CREATE TABLE [dbo].[ccWhatsAppConversationsRelationshipOut](
	[relationshipId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[conversationIdBefore] [int] NOT NULL,
	[conversationIdAfter] [int] NOT NULL
) 
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Indentificador de la tabla'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsRelationshipOut'', @level2type=N''COLUMN'',@level2name=N''relationshipId''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Id de la tabla ccWhatsAppConversationsOut.conversationId'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsRelationshipOut'', @level2type=N''COLUMN'',@level2name=N''conversationIdBefore''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Id de la tabla ccWhatsAppConversationsOut.conversationId'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsRelationshipOut'', @level2type=N''COLUMN'',@level2name=N''conversationIdAfter''
EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Tabla Relacion de mensaje anterior y siguiente'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccWhatsAppConversationsRelationshipOut''

end'
		EXEC(@sql)

		SET @process = 'K020017-Consultar conversaciones WhatsApp en Finder Create Table ccWhatsAppNodeOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWhatsAppNodeOut'') begin
CREATE TABLE [dbo].[ccWhatsAppNodeOut](
	[conversationId] [int] NOT NULL primary key,
	[node] [xml] NULL,
	[dateIn] [datetime] NULL,
	[dateOut] [datetime] NULL,
	[status] [smallint] NULL
)

ALTER TABLE [dbo].[ccWhatsAppNodeOut] ADD  DEFAULT (NULL) FOR [dateOut]
ALTER TABLE [dbo].[ccWhatsAppNodeOut] ADD  DEFAULT ((0)) FOR [status]
end'
		EXEC(@sql)

		SET @process = 'K020017-Consultar conversaciones WhatsApp en Finder Create Table ccWhatsAppNodeHistoryOut'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccWhatsAppNodeHistoryOut'') begin
CREATE TABLE [dbo].[ccWhatsAppNodeHistoryOut](
	[conversationId] [int] NOT NULL,
	[node] [xml] NULL,
	[dateIn] [datetime] NULL,
	[dateOut] [datetime] NULL,
	[status] [smallint] NULL
)
end'
		EXEC(@sql)

		SET @process = 'K020093-Envio manual WhatsApp de salida Insert Finder WhastAppOut'
		SET @sql = 'SET IDENTITY_INSERT ccFinderServices ON
if not exists(select * from ccFinderServices where name=''WhastAppOut'') begin
	insert into ccFinderServices (id,[name],ref,tableName,tableNameHistory,columnId,isActive)
	values(6,''WhastAppOut'',''R06'',''ccWhatsAppNodeOut'',''ccWhatsAppNodeHistoryOut'',''conversationId'',1)
end

SET IDENTITY_INSERT ccFinderServices OFF
'
		EXEC(@sql)

			SET @process = 'K020093-Env�o manual WhatsApp de salida'
		SET @sql = 'if not exists(
SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccWhatsAppConversations''
AND COLUMN_NAME = ''tQueue'' and DATA_TYPE=''bigint'')
alter table ccWhatsAppConversations alter column tQueue bigint
'
		EXEC(@sql)


------------------------------------------------- END K00200- Create Table Or Alter ----------------------------------------------------------------------
------------------------------------------------- BEGIN K00200- Create Store  ----------------------------------------------------------------------

		SET @process = 'K00200  DROP PROCEDURE ccsp_ConversationOutWASave'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationOutWASave'')
    begin
        DROP PROCEDURE ccsp_ConversationOutWASave;
    end'
		EXEC(@sql)

		SET @process = 'K00200  DROP PROCEDURE ccsp_ConversationWASaveOut'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASaveOut'')
    begin
        DROP PROCEDURE ccsp_ConversationWASaveOut;
    end'
		EXEC(@sql)


		SET @process = 'K00200  DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
    begin
        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
    end'
		EXEC(@sql)

		SET @process = 'K00200  DROP PROCEDURE ccsp_OutboundMultimediaCommon'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OutboundMultimediaCommon'')
    begin
        DROP PROCEDURE ccsp_OutboundMultimediaCommon;
    end'
		EXEC(@sql)

		SET @process = 'K00200  DROP PROCEDURE ccsp_WhatsAppInformationOut'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppInformationOut'')
    begin
        DROP PROCEDURE ccsp_WhatsAppInformationOut;
    end'
		EXEC(@sql)

		SET @process = 'K00200  CREATE PROCEDURE ccsp_ConversationOutWASave'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
@action             INT
, @conversationId     INT         = 0
, @campId          int    = NULL        
, @phoneCamp           VARCHAR(50) = NULL
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

	if not exists (select * from ccWhatsAppConversationsOut where camId = @campId and clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) begin
		if not exists (select * from ccWhatsAppConversations where clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) begin
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
END'
		EXEC(@sql)

		SET @process = 'K00200  CREATE PROCEDURE ccsp_ConversationWASaveOut'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
                                        , @conversationId     INT         = 0
                                        , @camId          SMALLINT    = NULL
                                        , @phoneCam           VARCHAR(50) = NULL
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
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

IF @action = 1
BEGIN --new Conversation
    IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A WHERE A.conversationId = @conversationId)
    BEGIN
        INSERT INTO [ccWhatsAppConversationsOut]
        (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

        --IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @camId) BEGIN
            SELECT @conversationId = SCOPE_IDENTITY();
            SELECT @conversationId AS ConversationId;
        --END
        --ELSE BEGIN

            --declare @conversationIdTemporal     INT;
            --SELECT @conversationIdTemporal = SCOPE_IDENTITY();
            --EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
            --SELECT 0 AS ConversationId;
        --END;

--        Save new request
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
           INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
        END
        ELSE BEGIN
            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
        END
        RETURN(0);
    END
    ELSE BEGIN
        DECLARE @conversationStatusTemp INT = @conversationStatus;
        IF @conversationStatus in(17,18) BEGIN
            SET @conversationStatusTemp = 1
        END
        INSERT INTO [ccWhatsAppConversationsOut]
        (camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
        SELECT @conversationIdNew = SCOPE_IDENTITY();

        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
        VALUES (@conversationId, @conversationIdNew);
        --Save new request by reassign
        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId

    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

    SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
    RETURN(0);
END;
END;

else IF @action = 2
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
	
    UPDATE ccWhatsAppConversationsOut
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(10,17,18) then 2
        when @conversationStatus = 11 then 1
        else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

        IF @conversationStatus in(13,10,17,18,11) BEGIN
            DECLARE @conversationDateTemp INT;
            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversationsOut where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

else IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
END;

else IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversationsOut
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversationsOut
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversationsOut](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
       
	   SELECT @camId=camId FROM ccWhatsAppConversationsOut A WHERE A.conversationId=@conversationId
		if not exists(select * from ccWAConversationsResult where camId=@camId)begin
			insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
		end
		exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
		
		 SELECT @messageId as MessageId
		
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

else IF @action = 5
BEGIN --save onQueue
    UPDATE ccWhatsAppConversationsOut
            SET onQueue = 1,
            conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
END;

else IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A where A.conversationId = @conversationId
	   
        UPDATE ccWhatsAppConversationsOut
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

    SELECT @conversationId as conversationId
    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut where conversationId=@conversationId;

    IF @onQueue = 1 BEGIN
     UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
    END
END;

 Else IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
END;
else IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
        UPDATE ccWAMessagesConversationsOut
                SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
		exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
		
    END;
END;

else IF @action = 9
BEGIN --Save last message time by conversationID
    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A WHERE A.conversationId=@conversationId) IS NULL BEGIN
        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
    END;
    ELSE
        BEGIN
            UPDATE ccLastMessageAgentByConversationOut
                SET timeStampLastMessageAgent = getDate()
            WHERE conversationId = @conversationId;
        END;
END;

else IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
END;

Else IF @action = 11
BEGIN --register desconnection agent by conversationID
	exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
END;

else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
        , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
        isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
        isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversationsOut A
        left join ccWAMessagesConversationsOut B on A.conversationId = B.conversationId
        left join [ccDisconnectionMCSOut] C on C.disconnectionId = @disconnectionIdTemp
        --where B.conversationId is null
        where A.requestDate >= @from 
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
        order by agentId desc, requestDate,timeStampMessage, camId, clientId 
END;
else IF @action = 13
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
        Inner join contactMeanOut C
        ON A.idCampEsp = C.camp_id
        where A.IDWG = 1 and A.Tipo = 1
        AND C.meanContactTypeId = 5
    )

    select DISTINCT A.User_Id from agents A
    left join usersByCampigns B on A.User_Id = B.User_Id
END;

else IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;
IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversationsOut
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;
END;
IF @action = 16 BEGIN --update content message
	if @camId is null or @camId=0 begin	
		SELECT @camId=camId FROM ccWhatsAppConversationsOut A WHERE A.conversationId=@conversationId
	end
         		
	if @messageStatus=''submitted'' begin
		update ccWAConversationsResult set SentMsg= SentMsg+1
	end
	else if @messageStatus=''delivered'' begin
		update ccWAConversationsResult set SentMsg= SentMsg-1,Delivered=Delivered+1
	end
	else if @messageStatus=''read'' begin
		update ccWAConversationsResult set Delivered=Delivered-1,ReadMsg=ReadMsg+1
	end
	else if @messageStatus=''rejected'' begin
		update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
	end

	SELECT @messageId as MessageId
END;

'
		EXEC(@sql)

		
		

		SET @process = 'K00200 CREATE PROCEDURE ccsp_GalateaGetOutboundConfiguration conexionInfo VARCHAR(50)'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT, @campID INT
AS
BEGIN
	DECLARE @AllCampaigns TABLE (
		cam_id SMALLINT, cam_Descripcion VARCHAR(60), cam_tNotas SMALLINT, cam_ocupado 
		SMALLINT, cam_noInt_ocupado SMALLINT, cam_inter_ocupado SMALLINT, 
		cam_nocontesto SMALLINT, cam_noInt_nocontesto SMALLINT, cam_inter_nocontesto 
		SMALLINT, cam_fax SMALLINT, cam_noInt_fax SMALLINT, cam_inter_fax SMALLINT, 
		cam_modomanual SMALLINT, ANI VARCHAR(15), cam_ShowCalifWnd BIT, 
		cam_StartTimerOnHangUp BIT, editableCallKey BIT, cam_tNoContesta SMALLINT, 
		iTipoDial SMALLINT, detectAnswerMachine SMALLINT, detectVoiceMail SMALLINT, 
		compliance SMALLINT, cam_inter_graba SMALLINT, cam_noint_graba SMALLINT, 
		progDial SMALLINT, excCallBack SMALLINT, dialOrder SMALLINT, dialPrefix VARCHAR
		(10), dialPrefixMan VARCHAR(10), dialPrefixXfe VARCHAR(10), listenManualCall 
		BIT, stopRecording BIT, abandonCallback BIT, frame SMALLINT, t_autoCB SMALLINT, 
		id_anilist INT, tDialonWrapUp SMALLINT, viewMode TINYINT, queSize SMALLINT, 
		DNCScrub INT, callerIdDesc VARCHAR(15), timeZoneRule INT, callsBySurvey INT, 
		ivrScript INT, surveyPctg INT, call_record SMALLINT, startStopRecording BIT, 
		leaveRecMessage BIT, manualCallOnChat BIT, callBackSurveyAgent BIT, 
		callBackSurveyClient BIT, isRelationSurvey BIT, funcEspDtmf INT, sipHdrFormat 
		VARCHAR(255), cam_inter_cancelled SMALLINT, prefijo VARCHAR(40), enbleprefix 
		BIT, exitAssisted BIT, previewDiscard BIT, CampType INT, conexionInfo VARCHAR(50
		), closeConversationTime SMALLINT, answerTimeoutClient INT, 
		allowFileAttachments BIT
		)

	

	INSERT INTO @AllCampaigns
	EXEC ccsp_RIAConfCamp @adminID, @campID

	SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall 
		ListenManualCall, stopRecording StopRecording, abandonCallback 
		AbandonCallBack, t_autoCB AutoCB, id_anilist IdIstANI, tDialonWrapUp 
		TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, 
		timeZoneRule TimeZoneRule, callsBySurvey CallsBySurvey, ivrScript IvrScript, 
		surveyPctg SurveyPctg, call_record CallRecord, startStopRecording 
		StartStopRecording, leaveRecMessage LeaveRecMessage, manualCallOnChat 
		ManualCallOnChat, callBackSurveyClient CallBackSurveyClient, 
		callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf, 
		sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix, prefijo Prefix, dialOrder 
		DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas 
		CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy, 
		cam_inter_ocupado CamInterBusy, cam_nocontesto CamNoAnswer, 
		cam_noInt_nocontesto CamNoIntNoAnswer, cam_inter_nocontesto 
		CamInterNoAnswer, (cam_inter_cancelled / 60) CamInterCancelled, 
		cam_fax CamFax, cam_noInt_fax CamNoIntFax, cam_inter_fax CamInterFax, 
		cam_modomanual CamModoManual, ANI, cam_StartTimerOnHangUp 
		CamStartTimerOnHangUp, editableCallKey EditableCallKey, cam_tNoContesta 
		CamTNoAnswer, iTipoDial CamIntensiveDialing, detectAnswerMachine 
		DetectAnswerMachine, detectVoiceMail DetectVoiceMail, compliance Compliance, 
		cam_inter_graba CamInterRecord, cam_noint_graba CamNoIntRecord, excCallBack 
		ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted 
		ExitAssistedDialMode, previewDiscard PreviewDiscard, CampType, 
		conexionInfo ConexionInfo, closeConversationTime CloseConversationTime, 
		answerTimeoutClient MUTimeOutClient, allowFileAttachments 
		AllowFileAttachments
	FROM @AllCampaigns
	WHERE cam_id = @campID
END
'
		EXEC(@sql)
	


		SET @process = 'K00200  CREATE PROCEDURE ccsp_OutboundMultimediaCommon if ( @TipoStatusAge_id = 34  and @call_id > 0) -- Dialogo WhatsApp actualizar tChatting'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_OutboundMultimediaCommon] 
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
			   @ServiceType AS ServiceType
		FROM ccWhatsAppConversationsOut
		WHERE conversationId = @ConversationId
	END
END

'
		EXEC(@sql)

		
		SET @process = 'K00200  CREATE PROCEDURE ccsp_WhatsAppInformationOut'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
@Option SMALLINT,
@camId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON
IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
	print (''Camp Is Not WhatsApp'')
	return(-1);
End

 
      
DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
--set @Today SMALLDATETIME = ''2022-03-24''
IF @Option = 0 BEGIN-- Reset TABLES
	TRUNCATE TABLE ccWAConversationsResult
	TRUNCATE table ccWAOperatingSummaryOut;
	TRUNCATE TABLE ccWAAverageConversationsOutOut;
	TRUNCATE TABLE ccLastMessageAgentByConversationOut;
END    
else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                WHERE CamId = @camId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = 2
		--(SELECT CASE 
		--WHEN defaultServiceLevelParameter IS NULL THEN 2 
		--WHEN defaultServiceLevelParameter = 0 THEN 2
		--ELSE defaultServiceLevelParameter END
		--FROM contactMeanIn WHERE inboundId = @camId);

		SET @DefaultValue = @DefaultValue * 60;
        DECLARE @LessThanDefault INT = 0;
        DECLARE @ReceivedConversations INT = 0;
        DECLARE @ServiceLevel SMALLINT = 0;

        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                @AverageDialogTime = ROUND(AVG(tChatting), 4),
                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                @ReceivedConversations = COUNT(conversationDate),
                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
        FROM ccWhatsAppConversationsOut WHERE camId = @camId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
            ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
            ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
            ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
            ISNULL(ServiceLevel, 0) AS ServiceLevel,
            ISNULL(Attended, 0) AS Attended,
            ISNULL(Assigned, 0) AS Assigned,
            ISNULL(OnQueue, 0) AS OnQueue,
            ISNULL(EndedBySystem, 0) AS EndedBySystem,
            ISNULL(Available, 0) AS Available,
            ISNULL(Request, 0) AS Request
    FROM ccWAAverageConversationsOut conv
    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
    WHERE conv.CamId = @camId OR summary.camId = @camId
END
else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                -- Average Queue/Waiting Time, and Service Level)
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
            VALUES(@camId, 1)
        END
END
else IF @Option = 3 -- Save time from accepted conversation by agent
BEGIN
    IF @ConversationId IS NOT NULL
    BEGIN
        UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
        --Save Conversation Assigned
        SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @camId
        
    END
END
else IF @Option = 4 -- Get Disposition Information
BEGIN
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificaci�n'' else ''No disposition'' end
from ccsettings where setting_id = 27 -- 0esp
SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
		ISNULL(disposition.calif_id, 0) AS DispositionId,
		COUNT(whatsConv.disposition) AS Total,
		ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
		COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
FROM ccWhatsAppConversationsOut whatsConv
LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
WHERE camId = @camId AND assignDate >= @Today
	and whatsConv.conversationStatus != 2
GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
END
else IF @Option = 5 -- Get Subdisposition Information
BEGIN
    SELECT relation.calif_id AS DispositionId,
            subDispositions.califSubDesc AS SubDispositionsName,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM cctipoSubCalifRel relation
    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
    INNER JOIN ccWhatsAppConversationsOut whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
    WHERE whatsConv.camId = @camId AND
            whatsConv.assignDate >= @Today AND
            relation.tipoSubRel = 0
    GROUP BY subDispositions.califSubDesc, relation.calif_id
END
ELSE IF @Option = 6 -- Agents Availables
BEGIN
    IF NOT EXISTS (SELECT camId FROM ccWAConversationsResult WHERE camId = @camId)
        BEGIN
            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
        END
    ELSE
        BEGIN
            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
        END
END

ELSE IF @Option = 7 -- Whats Conversations Results
BEGIN
	SELECT ISNULL(SentMsg, 0) AS SentMsg,
			ISNULL(Delivered, 0) AS Delivered,
			ISNULL(NotDelivered, 0) AS NotDelivered,
			ISNULL(ReadMsg, 0) AS ReadMsg,
			ISNULL(NotSupported, 0) AS NotSupported
	FROM ccWAConversationsResult
	WHERE camId = @camId
END
    
SET NOCOUNT OFF'
		EXEC(@sql)
------------------------------------------------- END CREATE Store ----------------------------------------------------------------------
------------------------------------------------- BEGIN Alter Store ----------------------------------------------------------------------

SET @process = 'K00200  ALTER PROCEDURE ccsp_SaveStatusAgent'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PAR�METRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
declare @cal_tDialog int
declare @cal_tNotas int
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall int
declare @cal_manual int 

set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))
--4 Dialog,6 Notas, 27 Notas Fallida
if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


set @cal_manual =0

if @TipoCall = 0 begin --IN

select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
        from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
    if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
    set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
    if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
    if @TipoStatusAge_id=6  begin
        if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
        else  set @tDialog=@tDialog-1
    end
    end
    update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
end
end
else begin --OUT
select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
set @Camp=@cam_id

if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
    if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
    set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
    if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
    if @TipoStatusAge_id=6  begin
        if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
        else  set @tDialog=@tDialog-1
    end
    end

    update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
end
else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
    update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  where cal_id = @call_id
else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
    update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
    insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
end

if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
--Valida que el agente no pudo guardar el status antes de desloguear
if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
    INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
end


end


if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
declare @tStatus3 int, @Fecha3 datetime
select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
from cccampsagente where user_id = @User_id


---Agregar callback en caso de este activo setting en campa�as o acd y tenga relacion de campa�a de encuesta
if @call_id>0 begin
if @TipoCall = 0 begin --IN

    select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

    if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
        if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
        begin
            if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
            begin
            insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
            values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
            end
        end
    end
end --@TipoCall = 0
else begin  --OUT



    select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
    select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
    from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
    where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

    if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
    if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
    begin
        insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
        values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
    end
    end
end
end--@isTransferSurvey = 0 and @callout_id>0


end

if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
declare @minimoDialogo tinyint 
select  @minimoDialogo = valor from ccSettings where setting_id = 13
if @cal_tDialog < @minimoDialogo
    begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
end

end 

if @TipoStatusAge_id =6  and @isLogout=0
begin
--Valida que el ccserver no haya guardado antes el status antes al desloguear
if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
    INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
end
else
INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )

if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
begin
INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

---Para Agente RIA: OAYC
INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
end

-- Actualiza para reporte de tiempos especiales (Boan)
if @Camp > 0
begin
if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
        where IdCampEsp = 0 and user_id = @User_id)
    begin
    update ccLogAgentesDia with(rowlock)
    set IdCampEsp = @Camp, Tipo = @TipoCall
    where IdCampEsp = 0
    and user_id = @User_id
    end

if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
        where IdCampEsp = 0 and user_id = @User_id)
    begin
    update ccLogAgentesNotReady with(rowlock)
    set IdCampEsp = @Camp, Tipo = @TipoCall
    where IdCampEsp = 0
    and user_id = @User_id
    end
end

if ( @TipoStatusAge_id = 34  and @call_id > 0) -- Dialogo WhatsApp
begin
	if @TipoCall=0 begin
		update ccWhatsAppConversations set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
		set @Camp = (select inboundId from ccWhatsAppConversations  where conversationId = @call_id);
		EXEC ccsp_WhatsAppInformation @Option = 2, @InboundId = @Camp
	end
	else begin
		update ccWhatsAppConversationsOut set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
		set @Camp = (select camId from ccWhatsAppConversationsOut  where conversationId = @call_id);
		EXEC ccsp_WhatsAppInformationOut @Option = 2, @camId = @Camp
	end
end
end'
		EXEC(@sql)


SET @process = 'K00200  Alter PROCEDURE ccsp_GalateaDeleteCampaignAndACD update contactMeanOut.conexionInfo empty'
		SET @sql = 'Alter PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
    @userId           SMALLINT,
    @DeleteCamId      VARCHAR(MAX),
    @DeleteACDGroupId VARCHAR(MAX),
    @moduleId         SMALLINT = 49
AS
BEGIN

    IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
        SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG
        INTO #CampsDelete
        FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
        inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
        left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
    IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
        SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG
        INTO #ACDDelete
        FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
        inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
        left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0

    IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
    begin
        select ''-1'' AS Result
        return
    end

    IF datalength(@DeleteCamId) > 0
        BEGIN

        if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
            --Borra las calificacion con reprogramacion
            delete ccCalifCamp from ccInbound A
            inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
            inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
            where A.cam_id in (select DeleteCamId from #CampsDelete)
            --Borra las subcalificacion con reprogramacion
            delete rel from ccInbound A
            inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
            inner join ccTipoCalif C on B.calif_id=C.calif_id
            inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
            inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
            where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

            update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

        end

        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
        select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

        delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
        select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

        delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
        delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

        IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
        SELECT ca.AreaName,
               GETDATE() operationDate,
               27 operationType,
               (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
               @moduleId module_id,
               c.cam_descripcion value,
               ca.AreaName AS target
        INTO #CampLog
        FROM ccRIACat_Areas ca
        Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
        WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

        Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)
		
        update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
        where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5
        
        update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        

    END
    IF datalength(@DeleteACDGroupId) > 0
        BEGIN

        if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
            begin
                update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
        end

        IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
        SELECT DISTINCT(IDWG)
        INTO #AllWGACD
        FROM ccRIACampEspWG ce
        WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
        select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
        from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
        where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
        select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
        from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
        where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

        delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
        delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


        IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
        SELECT ca.AreaName,
                GETDATE() operationDate,
                28 operationType,
                (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                @moduleId module_id,
                i.descripcion value,
                ca.AreaName AS target
        INTO #ACDLog
        FROM ccRIACat_Areas ca
        inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
        WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
            begin
                update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
        end
        if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
            begin
                update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
        end
        update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

        if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
            begin
                update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        end            
        update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        
    END

    IF datalength(@DeleteCamId) > 0
        Insert into ccRIALog Select * from #CampLog
    IF datalength(@DeleteACDGroupId) > 0
        Insert into ccRIALog Select * from #ACDLog

    SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG FROM #CampsDelete
    UNION
    SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG FROM #ACDDelete
    IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
    IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
	IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
END'
		EXEC(@sql)

	SET @process = 'K00200  ALTER PROCEDURE ccsp_CreateNodeMultimedia se agrega la opcion @type = 6'
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
    + ''"/>'')
            , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
                                                                    LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
                                                                    LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
                                                                    LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                    LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
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

SET @process = 'K00200  ALTER PROCEDURE ccsp_MultimediaCommon @campType para separar entrada/salida'
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
			   ISNULL(configuration.number, '''') AS Phone		       
		FROM  ccCamps campaign 
		INNER JOIN  ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id where configuration.status != 0 AND campaign.CampType = 5
END

ELSE IF @Option = 1 --  Get Acds Configuration List
BEGIN
		
	SELECT --inbound.chat AS ServiceType,
	CAST(inbound.Inbound_id AS INT) AS Id,
	inbound.descripcion AS [Name],
	ISNULL(configuration.conexionInfo, '''') AS Phone,
	CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
	inbound.tNotas AS WrapUpTime
	FROM  ccInbound inbound
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
		CAST(inbound.Inbound_id AS INT) AS ACDId,
		inbound.descripcion AS ACDName,
		ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
		CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
		inbound.tNotas AS WrapUpTime
		FROM  ccInbound inbound
		INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
	end
	else begin
	SELECT
		CAST(inbound.cam_id AS INT) AS ACDId,
		inbound.cam_descripcion AS ACDName,
		ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
		CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
		inbound.cam_tnotas AS WrapUpTime
		FROM  ccCamps inbound
		INNER JOIN  contactMeanOut configuration ON (inbound.cam_id = configuration.camp_id and inbound.cam_id = @inboundId)
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
		case when typeMessage <> ''text''  then '''' else content end as Content,
		typeMessage as Type,
		case 
				when typeMessage not in( ''text'' ,''location'', ''file'') then content
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
						when typeMessage = ''text'' or typeMessage = ''location''
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


		SET @process = 'K00200  ALTER PROCEDURE ccsp_Multimedia2 campo @camType para entrada/salida'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL, @senderId INT = NULL,@camType bit=0
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista Cam Or  ACD
		if @camType=0 begin		
			SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccInbound A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE @inboundId IS NULL OR @inboundId = A.Inbound_id
		end
		else begin
			SELECT DISTINCT A.cam_id AS Id,convert(tinyint, case when A.CampType =5  then A.CampType else 1 end) AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccCamps A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE @inboundId IS NULL OR @inboundId = A.cam_id
		end
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes
		SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
		FROM ccRIAWorkGroupUsers A
		INNER JOIN ccusers B ON A.User_id = B.User_id
		INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
		INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id
		LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
		WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
		ORDER BY A.User_id
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE (@senderId IS NULL OR @senderId = A.contactMeanOutId) and A.meanContactTypeId = 1
	END
	ELSE IF @action = 4
	BEGIN --List ACD Whatsapp
		SELECT  inboundId AS Id
		FROM contactMeanIn
		WHERE meanContactTypeId = 5
	END
END'
		EXEC(@sql)


		set @process = 'K020040 SP ccsp_GalateaAdminCampaigns cambio opcion 10 para obtener status de los agentes'
		set @sql ='ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
		@Option AS      SMALLINT, 
		@CampType AS    SMALLINT = 0, 
		@WorkgroupId AS INT      = 0, 
		@Id AS          INT      = 0, 
		@AdminId AS     SMALLINT = 0, 
		@PinUpdate AS   SMALLINT = 0, 
		@LoadId AS      INT      = 0, 
		@Type AS        SMALLINT = 0,
		@InboundType    SMALLINT = 0,
		@AreaId         SMALLINT = 0,
		@multi_type     varchar(max) = null
		AS
		BEGIN
			SET NOCOUNT ON;
			IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
				BEGIN
					IF @CampType = 1 -- Campaigns Out
						BEGIN
							IF @WorkgroupId IS NOT NULL
								BEGIN
									SELECT CAST(IdCampEsp AS INT) AS Id
									FROM ccRIACampEspWG
									WHERE IDWG = @WorkgroupId
											AND Tipo = 1
											ORDER BY IdCampEsp ASC;
							END;
							ELSE
								BEGIN
									RAISERROR(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1);
							END;
					END;
					IF @CampType = 0 -- Campaigns In (ACD)
						BEGIN
							IF @WorkgroupId IS NOT NULL
								BEGIN
									SELECT CAST(IdCampEsp AS INT) AS Id
									FROM ccRIACampEspWG
									WHERE IDWG = @WorkgroupId
											AND Tipo = 0
											ORDER BY IdCampEsp ASC;
							END;
							ELSE
								BEGIN
									RAISERROR(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1);
							END;
					END;
					RETURN 0;
			END;
			IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
				BEGIN
					IF @CampType = 1 -- Campaigns Out
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
											CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
																	CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType
									FROM ccCamps camps
											LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
											LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
									WHERE camps.cam_id = @Id
											ORDER BY camps.cam_descripcion ASC;
							END;
							ELSE
								BEGIN
									RAISERROR(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1);
							END;
					END;
					IF @CampType = 0 -- Campaigns In (ACD)
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
															CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
									FROM ccInbound inb
											LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
											LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
									WHERE inb.Inbound_id = @Id
											ORDER BY inb.descripcion ASC;
							END;
							ELSE
								BEGIN
									RAISERROR(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1);
							END;
					END;
					RETURN 0;
			END;
			IF @Option = 3   -- Update OverallTotalNew By Campaign
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							UPDATE ccCampsNvosCB
								SET 
									OverallTotalNew = ccCampsNvosCB.new
							WHERE id = @Id;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1);
					END;
					RETURN 0;
			END;
			IF @Option = 4   -- Update Pin from Campaign per Admin
				BEGIN
					IF @Id IS NOT NULL
						AND @AdminId IS NOT NULL
						BEGIN
							IF @PinUpdate = 1
								BEGIN
									INSERT INTO PinedCampaigns(CampId, AdminId, Type)
								VALUES(@Id, @AdminId, @Type);
							END;
							IF @PinUpdate = 0
								BEGIN
									DELETE FROM PinedCampaigns
									WHERE CampId = @Id
											AND AdminId = @AdminId
											AND Type = @Type;
							END;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. La campa?as o administrador no existen'', 18, 1);
					END;
					RETURN 0;
			END;
			IF @Option = 5   -- Get Pin from Campaign Ids per Admin
				BEGIN
					IF @AdminId IS NOT NULL
						BEGIN
							SELECT CampId AS Id
							FROM PinedCampaigns
							WHERE AdminId = @AdminId
									AND Type = @Type
									ORDER BY Id ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
					END;
					RETURN 0;
			END;
			IF @Option = 6   -- Get Blacklist Ids by Campaign Id
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							DECLARE @BlackListIds VARCHAR(MAX);
							SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
							FROM Camplistanegra
							WHERE cam_id = @Id
									AND STATUS = 1;
							SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1);
					END;
					RETURN 0;
			END;
			IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
				BEGIN
					IF(@Id IS NOT NULL
						AND EXISTS
					(
						SELECT *
						FROM cccamps
						WHERE cam_id = @Id
					))
						BEGIN
							SELECT TOP 1 list_id
							FROM ccRIARegistryLists
							WHERE cam_id = @Id
									AND STATUS = 2
									ORDER BY list_id DESC;
					END;
					ELSE
						BEGIN
							--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
							RAISERROR(''ERROR. No existe una campa?a con el id especificado'', 18, 1);
					END;
					RETURN 0;
			END;
			IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
				BEGIN
					IF(@LoadId IS NOT NULL
						AND EXISTS
					(
						SELECT *
						FROM ccRIARegistryLists
						WHERE list_id = @loadID
								AND STATUS <> 0
					))
						BEGIN
							UPDATE ccoCallsOutSource
								SET 
									cal_status = ''5''
							WHERE list_id = @loadID;
							DELETE FROM ccoWorkingTable
							WHERE list_id = @LoadId;
							EXEC ccsp_RIARegistryLists 
									@action = 6, 
									@list_id = @LoadId;
					END;
					ELSE
						BEGIN
							--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
							RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
					END;
					RETURN 0;
			END;
			IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
				BEGIN
					DECLARE @table TABLE
					(camId    INT, 
						campType TINYINT, 
						PRIMARY KEY(camId, campType)
					);
					INSERT INTO @table
							SELECT DISTINCT 
									IdCampEsp, Tipo
							FROM ccRIACampEspWG wg
							WHERE wg.IDWG IN
							(
								SELECT IDWG
								FROM ccRIAWorkGroupUsers
								WHERE IDWG <> @WorkgroupId
										AND User_id = @AdminId
							);
					SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
					FROM @table A
							RIGHT JOIN
					(
						SELECT wg.IdCampEsp, wg.Tipo
						FROM ccRIACampEspWG wg
						WHERE wg.IDWG = @WorkgroupId
					) B ON A.camId = B.IdCampEsp
							AND A.campType = B.Tipo
					WHERE A.camId IS NULL
							ORDER BY IdCampEsp;
					RETURN 0;
			END;
			IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
			BEGIN
			DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
			DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
			DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
			DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
			DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
			DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
			DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

			INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
			FROM ccRIAWorkGroupUsers WG, 
				ccUsers_Roles R
			WHERE WG.User_id = @AdminId
			OR (R.User_id = @AdminId
			AND R.Rol_id = 7);
					        
			INSERT INTO @AgentsList SELECT DISTINCT A.User_id
			FROM ccRIAWorkGroupUsers A
			INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
			INNER JOIN ccUsers C ON A.User_id = C.User_id 
			AND C.TipoUser_id = 1
			ORDER BY A.User_id;

							INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
			CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
			FROM ccRIACampEspWG campPerWg
			INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
			INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
			INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
			left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
			left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
			where C.TipoUser_id = 1
			AND campPerWg.Tipo = @CampType
			AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
					  
			;WITH lastState AS (
			SELECT A.user_id, MAX(A.fecha) AS fecha
			FROM ccLogAgentesDia A
			INNER JOIN @AgentsList B ON A.User_id = B.id
			WHERE fecha >= @date
			GROUP BY user_id)

			INSERT INTO @CurrentStatus 
			SELECT B.User_id,
			CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
			B.IdCampEsp,
			B.Tipo
			FROM lastState A
			INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
			AND A.fecha = B.fecha;

			IF @Id = 0 AND @CampType = 0 
			BEGIN
			DELETE FROM @tmpCamAgent WHERE multimediaType = 5
			END

			DECLARE @MultimediaType SMALLINT
			IF @CampType = 1 BEGIN
			SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
			END
			ELSE BEGIN
			SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
			END 

			DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

			INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
			(CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
			THEN @CampType ELSE null END) AS isCampDialog, B.camType
			FROM @tmpCamAgent A
			INNER JOIN @CurrentStatus B ON A.userId = B.userId
			WHERE (@Id = 0 or A.camId = @Id)

			IF @CampType = 1
			BEGIN
			;with  campDataTotal as(
				select camId,count(*) total from @tmpCamAgent A group by camId
			)

			insert into @campDataTotal
			select 
				A.camId,
				B.cam_descripcion as campName 
				,A.Total
				,C.AreaName as Area
				from campDataTotal A
				INNER JOIN ccCamps B ON A.camId= B.cam_id 
				INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
			END
			ELSE
			BEGIN    
			;with  campDataTotal as(
				select camId,count(*) total from @tmpCamAgent A group by camId
			)

			insert into @campDataTotal
			select 
				A.camId,
				B.descripcion as campName 
				,A.Total
				,C.AreaName as Area
				from campDataTotal A
				INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
				INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
			END

			;WITH stateCamp AS(
			SELECT A.CampId,
			count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
			count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
					WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
			COUNT(isCampDialog) AS dialog, 
			COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
			FROM @AgentStatus A
			INNER JOIN @CurrentStatus C ON A.userId = C.userId
			GROUP BY A.CampId
			)

			SELECT 
			A.camId,
			A.campName,
			A.Total,
				ISNULL(B.ready, 0) AS Ready,
			ISNULL(B.notReady, 0 ) AS NotReady, 
			ISNULL(B.dialog, 0) AS Dialog,
			CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
			A.Area
			FROM @campDataTotal A
			LEFT JOIN stateCamp B ON A.camId = B.CampId
			ORDER BY A.campName

				RETURN 0;
			END;
			IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
				BEGIN                
					IF Not EXISTS
					(
						SELECT *
						FROM ccUsers_Roles NOLOCK
						WHERE User_id = @AdminId
								AND Rol_id = 7
					)
						BEGIN
				print ''xxxx SIn Super''
							;WITH wgId
									AS (SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT 
										CAST(IdCampEsp AS INT) AS Id
									FROM ccRIACampEspWG A (NOLOCK)
										INNER JOIN wgId ON wgId.IDWG = A.IDWG
															AND A.Tipo = @CampType;
					END;
					ELSE
						BEGIN
				--print ''xxxx Super''
				IF @CampType = 1
				BEGIN
					SELECT DISTINCT 
						CAST(cam_id AS INT) AS Id
								FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
				END
				ELSE
				BEGIN 
					SELECT DISTINCT 
						CAST(Inbound_id AS INT) AS Id
								FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
				END
					END;
					RETURN 0;
			END;
			IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
				BEGIN
					IF @CampType = 1 -- Campaigns Out
						BEGIN
							SELECT DISTINCT 
									CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
													CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType
							FROM ccCamps camps (NOLOCK)
									INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
									INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
									--WHERE camps.cam_id = @Id
									ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							SELECT DISTINCT 
													CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
							FROM ccInbound inb (NOLOCK)
									INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
									INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
									ORDER BY inb.descripcion ASC;
					END;
					RETURN 0;
			END;
			IF @Option = 13
			BEGIN
				BEGIN                
					IF NOT EXISTS
					(
						SELECT *
						FROM ccUsers_Roles NOLOCK
						WHERE User_id = @AdminId
								AND Rol_id = 7
					)
						BEGIN
							IF @CampType = 1
								BEGIN
									WITH wgId
										AS (SELECT IDWG
											FROM ccRIAWorkGroupUsers NOLOCK
											WHERE user_id = @AdminId)
										SELECT DISTINCT 
											CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
										FROM ccRIACampEspWG A
											INNER JOIN wgId ON wgId.IDWG = A.IDWG
																AND A.Tipo = 1
											INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
								END
							ELSE
								BEGIN
									WITH wgId
										AS (SELECT IDWG
											FROM ccRIAWorkGroupUsers NOLOCK
											WHERE user_id = @AdminId)
										SELECT DISTINCT 
											CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
										FROM ccRIACampEspWG A (NOLOCK)
											INNER JOIN wgId ON wgId.IDWG = A.IDWG
																AND A.Tipo = 0
											INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
											AND ((@multi_type is null AND cci.chat = @InboundType)
												OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
								END
					END;
					ELSE
						BEGIN
						IF @CampType = 1
							BEGIN
								SELECT DISTINCT 
										CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
								FROM ccCamps NOLOCK where IDArea = @AreaId
							END
						ELSE
							BEGIN 
								SELECT DISTINCT 
										CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
								AND ((@multi_type is null AND cci.chat = @InboundType)
									OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

							END
					END;
					RETURN 0;
				END;
			END;

			IF @Option = 14
				BEGIN
					IF NOT EXISTS
					(
							SELECT *
							FROM ccUsers_Roles NOLOCK
							WHERE User_id = @AdminId
									AND Rol_id = 7
					)
						BEGIN
							WITH wgId
									AS (SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT 
										CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
									FROM ccRIACampEspWG A (NOLOCK)
										INNER JOIN wgId ON wgId.IDWG = A.IDWG
															AND A.Tipo = 0
										INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
										AND ((@multi_type is null AND cci.chat = @InboundType)
											OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

						END
					ELSE
						BEGIN
							SELECT DISTINCT 
							CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
							AND ((@multi_type is null AND cci.chat = @InboundType)
								OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

						END
				END
			IF @Option = 15
				BEGIN
					SELECT DISTINCT 
					CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
					FROM ccInbound NOLOCK where cam_id = @Id
				END
							END;'
			EXEC(@sql)

		set @process = 'K002075 SP ccsp_ConversationWASave se agrega opcion 15 para actualizar el contenido del mensaje cuando se descarga el archivo'
		set @sql =' ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
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
                IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) IS NULL BEGIN
                    INSERT INTO ccLastMessageAgentByConversation (conversationId) VALUES (@conversationId)
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
        END;'
		EXEC(@sql)

		set @process = 'K002075 SP ccspGalatea_Finder opcion 4 para obtener la informacion de la conversaci�n wa salida'
		set @sql ='ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
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
				     END;'
		EXEC(@sql)

		set @process = 'K020018 SP ccspGalatea_Finder cambio opcion 10 para traer la info del los nodos de wa salida'
		set @sql ='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
    
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
    else ''@CDATE''   end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
       update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
       and Xname=@name
end

else if @action = 10 begin
   declare @filterWg varchar(max)
    declare @len int
	declare @tipo int = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
 
    end
    else
    begin
    declare @serviceId varchar(10)
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
    end


    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
    select SUBSTRING(@filterWg,0, @len)
    end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    set @sql=''
    declare @dateStart datetime
    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
    EXECUTE sp_executesql  @sql

end'
		EXEC(@sql)

		set @process = 'K020018 SP ccsp_RIAConfCamp se agrega connUser y connpass'
		set @sql ='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
AS
SET NOCOUNT ON

DECLARE @tableExistsRec TABLE (camId INT PRIMARY KEY, existRec BIT)
DECLARE @camByUser TABLE (camId INT PRIMARY KEY, isCheck BIT)
DECLARE @camId INT, @id INT;

IF NOT EXISTS (
		SELECT *
		FROM ccUsers_Roles
		WHERE User_id = @User_id
			AND Rol_id = 7
		)
BEGIN
	INSERT INTO @camByUser
	SELECT *, 0
	FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
	WHERE @campID IS NULL
		OR cam_id = @campID
END
ELSE
BEGIN
	INSERT INTO @camByUser
	SELECT cam_id, 0
	FROM ccCamps
	WHERE (
			IDArea > 0
			OR IDArea IS NULL
			)
		AND (
			@campID IS NULL
			OR cam_id = @campID
			)
END

WHILE EXISTS (
		SELECT *
		FROM @camByUser
		WHERE isCheck = 0
		)
BEGIN
	SELECT TOP 1 @camId = camId
	FROM @camByUser
	WHERE isCheck = 0

	IF EXISTS (
			SELECT cam_id
			FROM ccoCallsOut
			WHERE cam_id = @camId
			)
	BEGIN
		INSERT INTO @tableExistsRec
		VALUES (@camId, 1)
	END
	ELSE
	BEGIN
		INSERT INTO @tableExistsRec
		VALUES (@camId, 0)
	END

	UPDATE @camByUser
	SET isCheck = 1
	WHERE camId = @camId
END

SELECT a1.cam_id, cam_Descripcion, cam_tNotas, cast(cam_ocupado AS INT) AS cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto AS INT) 
	AS cam_nocontesto, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax AS INT) AS cam_fax, cam_noInt_fax, cam_inter_fax, cast(cam_modomanual AS 
		INT) AS cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial, detectAnswerMachine, 
	detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial AS TINYINT) progDial, cast(excCallBack AS TINYINT) excCallBack, 
	dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall, stopRecording, cast(abandonCallback AS TINYINT) abandonCallback, a3.frame, 
	a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue AS queSize, DNCScrub, callerIdDesc, timeZoneRule
	, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record, 1) AS call_record, cast(startStopRecording AS TINYINT) startStopRecording, 
	leaveRecMessage, manualCallOnChat, callBackSurveyAgent, callBackSurveyClient, CASE 
		WHEN surveycamid IS NULL
			OR surveycamid = 0
			THEN 0
		ELSE 1
		END isRelationSurvey, isnull(a1.funcEspDtmf, 0), isnull(sipHdrFormat, '''') sipHdrFormat, cam_inter_cancelled, prefijo, enbleprefix = CASE 
		WHEN existRec = 0
			THEN 1
		ELSE 0
		END, isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard, isnull(CampType, 0) Chat, isnull(contact.conexionInfo, '''') 
	conexionInfo, isnull(contact.closeConversationTime, 0) closeConversationTime, isnull(contact.answerTimeoutClient, 0) answerTimeoutClient, 
	isnull(contact.allowFileAttachments, 0) allowFileAttachments
FROM ccCamps a1
INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
ORDER BY cam_descripcion

RETURN (0)

SET NOCOUNT OFF
'
		EXEC(@sql)

		set @process = 'K020018 SP ccsp_RIACampsManualCall se agrega CampType'
		set @sql ='ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall] @UserID INT, @onChat INT = 0
AS
SET NOCOUNT ON

IF (@onChat = 0)
BEGIN
	DECLARE @mod SMALLINT

	SELECT @mod = defCampaing
	FROM ccRIACat_Areas A
	WHERE A.IDArea = (
			SELECT IDArea
			FROM ccUsers
			WHERE User_id = @UserID
			)

	SELECT DISTINCT c.cam_id, c.cam_descripcion, CASE 
			WHEN ca.cam_id = @mod
				THEN 1
			ELSE 0
			END [isDefault], g.graphic_id, c.cam_ModoManual, isnull(c.CampType,1) as CampType
	FROM ccCamps c WITH (INDEX (PK_ccCamps))
	INNER JOIN ccCampsAgente ca ON c.cam_id = ca.cam_id
	INNER JOIN ccRIACampsGraph g ON g.cam_id = c.cam_id
	WHERE ca.user_id = @UserID
		AND cam_modoManual IN (1, 3)
	ORDER BY cam_descripcion
END
ELSE
	SELECT DISTINCT c.cam_id, c.cam_descripcion, g.graphic_id, c.cam_ModoManual, isnull(c.CampType,1) as CampType
	FROM ccCamps c WITH (INDEX (PK_ccCamps))
	INNER JOIN ccCampsAgente ca ON c.cam_id = ca.cam_id
	INNER JOIN ccRIACampsGraph g ON g.cam_id = c.cam_id
	WHERE ca.user_id = @UserID
		AND manualCallOnChat = 1
	ORDER BY cam_descripcion

SET NOCOUNT OFF;
'
		EXEC(@sql)

		------------------------------------------------- END BEGIN Alter Store ----------------------------------------------------------------------

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
