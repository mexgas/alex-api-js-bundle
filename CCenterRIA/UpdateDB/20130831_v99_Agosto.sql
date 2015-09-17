/*
Autor: Raymundo Gonzalez
Fecha: 2013/08/31
Descripcion:
	Se crea el indice IX_ccoCallBacks3 para mejora de performance en consultas
	Se crea el indice IX_ccoCallBacks4 para mejora de performance en consultas
	Se crea la tabla ccRIAChats para funcionalidad de chat
	Se crea la tabla ccRIAChatStatus para funcionalidad de chat
	Se crea la tabla ccRIAChatMailbox para funcionalidad de chat
	Se crea la tabla ccRIAChatFinder para funcionalidad de chat
	Se crea la tabla ccRIAChatInboundMsgs para funcionalidad de chat
	Se crea la tabla ccRIAChatMsg para funcionalidad de chat
	Se crea la tabla ccRIAChatPredefinedMsg para funcionalidad de chat
	Se crea la tabla ccRIAChatInboundPredefinedMsg para funcionalidad de chat
	Se insertan los settings 139,140,141,142,143,144 y 145 para funcionalidad de chat, iniciar y detener grabaciones y configuracion de multiples engines
	Se insertan registros en la tabla ccTipoStatusAgente para funcionalidad de chat
	Se insertan registros en la tabla ccmenus para nuevo menu de plantillas de chat
	Se insertan registros en la tabla ccRIAChatStatus para funcionalidad de chat
	Se insertan registros en la tabla ccRIAChatMsg para funcionalidad de chat
	Se insertan registros en la tabla ccTipoMsgs para funcionalidad de chat
	Se agrega el campo startStopRecording a la tabla ccusers para iniciar o detener grabacion
	Se agrega el campo startStopRecording a la tabla ccusers_consulta para iniciar o detener grabacion
	Se agregan los campos chat, inactiveChatTime, maxChats, chatDomain, chatQueueOverflow, chatTimeOverflow a la tabla ccInbound para funcionalidad de chat
	Se agrega el campo startStopRecording a la tabla ccInbound para iniciar o detener grabacion
	Se agrega el campo startStopRecording a la tabla ccCamps para iniciar o detener grabacion
	Se crean llaves foraneas e indice en la tabla ccRIAChatInboundMsgs
	Se actualiza el valor del setting 136 en la tabla ccsettings
	Se crea el SP ccsp_RIAUpdateChatConfig para funcionalidad de chat
	Se crea el SP ccsp_ChatLoadCatalogues para funcionalidad de chat
	Se crea el SP ccsp_RIAInsertChat para funcionalidad de chat
	Se crea el SP ccsp_RIAChatDispositions para funcionalidad de chat
	Se crea el SP ccsp_RIAChatGetAllInfoACD para funcionalidad de chat
	Se crea el SP ccsp_ChatLoadChatsStatus para funcionalidad de chat
	Se crea el SP ccsp_ChatSaveQueueInfo para funcionalidad de chat
	Se crea el SP ccsp_RIAChatACDSchedule para funcionalidad de chat
	Se crea el SP ccsp_RIAChatMailbox para funcionalidad de chat
	Se crea el SP ccsp_ChatFinder para funcionalidad de chat
	Se crea el SP ccsp_RIAChatFinder para funcionalidad de chat
	Se crea el SP ccsp_RIAChatGetAutoMessage para funcionalidad de chat
	Se crea el SP ccsp_RIAChatCATMessages para funcionalidad de chat
	Se crea el SP ccsp_RIAChatADMInboundMsgs para funcionalidad de chat
	Se crea el SP ccsp_RIAChatADMInboundMsgs_Del para funcionalidad de chat
	Se crea el SP ccsp_AgentGetStartStopPermission  para iniciar o detener grabaciones
	Se crea el SP ccsp_AgentGetStartStopRecValue para iniciar o detener grabaciones
	Se crea el SP ccsp_RIACATChatPredefinedMsg para funcionalidad de chat
	Se crea el SP ccsp_RIAChatPredefinedMsg para funcionalidad de chat
	Se crea el SP ccsp_CWCheckMigration para reportes de AVRS
	Se modifica el SP ccsp_RIA_ABCAreas para funcionalidad de chat
	Se modifica el SP ccsp_RIAADMGetCalifDay para funcionalidad de chat
	Se modifica el SP ccsp_RIAADMGetCalifDayForced para funcionalidad de chat
	Se modifica el SP ccsp_RIAvoiceMail para funcionalidad de chat
	Se modifica el SP ccsp_RIAtmpChart para funcionalidad de chat
	Se modifica el SP ccsp_RIALoadACDGroups para funcionalidad de chat
	Se modifica el SP ccsp_RIA_ABCWorkGroups para funcionalidad de chat
	Se modifica el SP ccsp_RIA_ABCAgents para funcionalidad de chat
	Se modifica el SP ccsp_RIAADMGetPermisos para permisos de iniciar o detener grabaciones
	Se modifica el SP ccsp_RIAConfCamp para configuracion de iniciar o detener grabaciones
	Se modifica el SP ccsp_RIAConfEspec para configuracion de iniciar o detener grabaciones y funcionalidad de chat
	Se modifica el SP ccsp_RIAUpdateCamConfig para configuracion de iniciar o detener grabaciones
	Se modifica el SP ccsp_RIAUpdateEspecConfig para configuracion de iniciar o detener grabaciones y funcionalidad de chat
	Se modifica el SP ccsp_RIAMenuRoles para funcionalidad de chat
	Se modifica el SP ccsp_RIACATMenu para funcionalidad de chat
	Se modifica el SP ccsp_RIARegistryLists para optimizacion de performance
	Se modifica el trigger tg_ccUsers_Consulta para campo startStopRecording
	Se modifica el Job CW Transfer CallBacks Info para mejora de performance
	
Version requerida: 98
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '99'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'IX_ccoCallBacks3 - Create Index'
		set @Sql='IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = ''IX_ccoCallBacks3'')
BEGIN
	CREATE NONCLUSTERED INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallBacks]
	(
		[schedulerStatus] ASC,
		[callout_id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END'

	EXEC(@Sql)

		set @process = 'IX_ccoCallBacks4 - Create Index'
		set @Sql='IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = ''IX_ccoCallBacks4'')
BEGIN
	CREATE NONCLUSTERED INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallBacks]
	(
		[schedulerStatus] ASC,
		[status] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END'

	EXEC(@Sql)
	
		set @process = 'ccRIAChats - Create table'
		set @Sql='CREATE TABLE dbo.ccRIAChats(
chatId int NOT NULL IDENTITY (1, 1),
inboundId smallint NOT NULL,
domain varchar(50) NOT NULL,
userId smallint NOT NULL,
session varchar(50) NOT NULL,
chatStatus smallint NOT NULL,
tChatting smallint NOT NULL,
tWrapUp smallint NOT NULL,
requestDate datetime NOT NULL,
finishedBy tinyint NULL,
onQueue bit NULL,
tQueue smallint NOT NULL,
tTimeout int NOT NULL,
disposition smallint NOT NULL,
subDisposition smallint NOT NULL,
chatDate datetime NULL,
clientName varchar(50) NULL,
firstMessageTime datetime NULL
)  ON [PRIMARY]

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_userId DEFAULT 0 FOR userId

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_chatStatus DEFAULT 0 FOR chatStatus

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_tChatting DEFAULT 0 FOR tChatting

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_tWrapUp DEFAULT 0 FOR tWrapUp

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_tQueue DEFAULT 0 FOR tQueue

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_tTimeout DEFAULT 0 FOR tTimeout

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_disposition DEFAULT 0 FOR disposition

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_subDisposition DEFAULT 0 FOR subDisposition

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	DF_ccRIAChats_clientName DEFAULT '''' FOR clientName

ALTER TABLE dbo.ccRIAChats ADD CONSTRAINT
	PK_ccRIAChats_1 PRIMARY KEY CLUSTERED 
	(
	chatId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'

	EXEC(@Sql)
		
		set @process = 'ccRIAChatStatus - Create table'
		set @Sql='CREATE TABLE dbo.ccRIAChatStatus(
id int NOT NULL IDENTITY (0, 1),
description varchar(30) NOT NULL
)  ON [PRIMARY]

ALTER TABLE dbo.ccRIAChatStatus ADD CONSTRAINT
PK_ccRIAChatStatus PRIMARY KEY CLUSTERED 
(
id
) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
		
	EXEC(@Sql)
		
		set @process = 'ccRIAChatMailbox - Create table'
		set @Sql='CREATE TABLE [dbo].[ccRIAChatMailbox](
[ID] [int] IDENTITY(1,1) NOT NULL,
[file] [varchar](255) NOT NULL,
[chatID] [int] NOT NULL,
[status] [smallint] NOT NULL DEFAULT ((0)),
[tries] [int] NOT NULL DEFAULT ((0)),
[date] [datetime] NOT NULL DEFAULT (getdate())
) ON [PRIMARY]'

	EXEC(@Sql)
		
		set @process = 'ccRIAChatFinder - Create table'
		set @Sql='CREATE TABLE [dbo].[ccRIAChatFinder](
[id] [int] IDENTITY(1,1) NOT NULL,
[userId] [smallint] NOT NULL,
[params] [varchar](500) NOT NULL,
[status] [bit] NOT NULL,
[template] [varchar](100) NOT NULL,
CONSTRAINT [PK_ccRIAChatFinder] PRIMARY KEY CLUSTERED 
(
[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'

	EXEC(@Sql)
		
		set @process = 'ccRIAChatInboundMsgs - Create table'
		set @Sql='CREATE table ccRIAChatInboundMsgs(
[msg_id] [int] NOT NULL,
[Inbound_id] [smallint] NOT NULL,
[orden]     [tinyint] NOT NULL,
[type]      [tinyint] NOT NULL
) ON [PRIMARY]'

	EXEC(@Sql)
		
		set @process = 'ccRIAChatMsg - Create table'
		set @Sql='CREATE table ccRIAChatMsg(
[msg_id] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY ,
[msg] [varchar] (255) NOT NULL,
[Descripcion][varchar] (40) NOT NULL     
)'

	EXEC(@Sql)
	
		set @process = 'ccRIAChatPredefinedMsg - Create table'
		set @Sql = 'CREATE TABLE [dbo].[ccRIAChatPredefinedMsg](
[message_id] [smallint] IDENTITY(1,1) NOT NULL,
[description] [varchar](40) NOT NULL,
[message] [varchar](max) NOT NULL,
[message_status] [bit] NOT NULL,
CONSTRAINT [PK_ccRIAChatPredefinedMsg] PRIMARY KEY CLUSTERED 
(
[message_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccRIAChatPredefinedMsg - Alter Table'
		set @Sql = 'ALTER TABLE [dbo].[ccRIAChatPredefinedMsg] 
ADD  CONSTRAINT [DF_ccRIAChatPredefinedMsg_Status]  DEFAULT ((1)) FOR [message_status]'
			
	EXEC(@Sql)

		set @process = 'ccRIAChatInboundPredefinedMsg - Create Table'
		set @Sql = 'CREATE TABLE [dbo].[ccRIAChatInboundPredefinedMsg](
	[message_id] [smallint] NOT NULL,
	[Inbound_id] [smallint] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)

		set @process = 'ccsettings - Insert'
		set @Sql='insert into ccsettings 
values(139,	''.\chats'',	''Ruta para guardar los chats'',	1,	''GRL'',''	Se guarda los archivos .log separados por carpetas'',	''Path to save the chats'',	1)

insert into ccsettings 
values(140,'''',''Ubicacion del chat service'',1,''GRL'',''IP del servidor donde se encuentra el ChatService, se actualiza automaticamente cuando se abre el chat service'',''Chat Service location (automatically updated when the chat service starts)'',1)

insert into ccsettings
values(141, 30, ''Tolerancia para nivel de servicio de chats'', 1, ''REP'', ''Tiempo(segs) que se toma en consideración como "Time Delay" en la formula para determinar el nivel de servicio de un chat.'', ''Chats service level tolerance'', 0)

Insert into ccsettings 
values (142,''0'',''Agente detiene/continua una grabacion'',1,''AGT'',''0:desactivado, 1:activado'',''Agent stop/continue a recording'', 1)

insert into ccsettings 
values(143,'''',''Posición de engine(s)'',1,''ADM'',''pbxId|IP de los engine(s) separados por comas y pipe 1|127.0.0.1:5060,2|127.0.0.2::5060. Corresponde a los engines para llamadas remotas.'',''Engine location'',1)

insert into ccsettings 
values(144,''0'',''Intervalo de tiempo para Tips'',1,''ADM'',''Mostrar Tips 0:desactivado 1:mostrar al inicio, >=10 intervalo (en min.) para mostrar los tips'',''Tips Interval'',1)

insert into ccsettings 
values(145,''0'',''Activar configuración chat'',1,''X'',''Muestra en el admin configuracion para chat'',''Enable chat settings'',1)

INSERT INTO ccSettings
VALUES(146, '''', ''Ruta de la base de datos CCRecorderV2'', 1, ''ADM'', ''Ruta de la base de datos CCRecorderV2'', ''CCRecorderV2 Data Base Path'', 0)'
				
	EXEC(@Sql)
	
		set @process = 'ccTipoStatusAgente - Insert'
		set @Sql='insert into ccTipoStatusAgente (TipoStatusAge_id,descripcion) values(23,''ChatReq'')
insert into ccTipoStatusAgente (TipoStatusAge_id,descripcion) values(24,''Chatting'')'
			
	EXEC(@SQL)	

		set @process='ccmenus - Insert'
		set @Sql='insert into ccmenus
values(79, ''Plantillas de Chat|Chat Templates'',30,''B'',39,1,'''')'
		
	EXEC(@Sql)
	
		set @process = 'ccRIAChatStatus - Insert'
		set @Sql = 'insert into ccRIAChatStatus values(''Request'')
insert into ccRIAChatStatus values(''InactiveDomain'')
insert into ccRIAChatStatus values(''UnavailableAgents'')
insert into ccRIAChatStatus values(''Assigned'')
insert into ccRIAChatStatus values(''Connected'')
insert into ccRIAChatStatus values(''OutOfService'')
insert into ccRIAChatStatus values(''OutOfSchedule'')
insert into ccRIAChatStatus values(''NoSignedAgents'')
insert into ccRIAChatStatus values(''Queued'')
insert into ccRIAChatStatus values(''Abandon'')
insert into ccRIAChatStatus values(''QueueOverflow'')
insert into ccRIAChatStatus values(''TimeOverflow'')'
		
	EXEC(@Sql)
		
		set @process = 'ccRIAChatMsg - Insert'
		set @Sql='insert into ccRIAChatMsg values(''All of our agents are currently unavailable, please wait'',''Hold Message'')
insert into ccRIAChatMsg values(''Our schedule service has finished'',''Out of schedule Message'')
insert into ccRIAChatMsg values(''Service currently unavailable'',''Out of service Message'')
insert into ccRIAChatMsg values(''Welcome!'',''Welcome Message'')
insert into ccRIAChatMsg values(''There are not available agents'',''Without Agents Message'')
insert into ccRIAChatMsg values(''We can not attend your request, leave a message'',''Overflow Message'')'

	EXEC(@Sql)
		
		set @process = 'ccTipoMsgs - Insert'
		set @Sql='insert into ccTipoMsgs values(12,''Inactive Warning'',''InactiveWarning'')
insert into ccTipoMsgs values(13,''Chat Finished'',''ChatFinished'')'

	EXEC(@Sql)

		set @process = 'ccusers - Alter Table'
		set @Sql='Alter table ccusers
add startStopRecording bit NULL'

	EXEC(@Sql)
	
		set @process = 'ccusers_consulta - Alter Table'
		set @Sql='Alter table ccusers_consulta
add startStopRecording bit NULL'

	EXEC(@Sql)
	
		set @process = 'ccInbound - Alter Table'
		set @Sql='Alter table ccInbound ADD
chat tinyint NOT NULL CONSTRAINT DF_ccInbound_chat DEFAULT 0,
inactiveChatTime smallint NOT NULL CONSTRAINT DF_ccInbound_inactiveChatTime DEFAULT 60,
maxChats int NOT NULL CONSTRAINT DF_ccInbound_maxChats DEFAULT 3,
chatDomain varchar(500) NULL,
chatQueueOverflow smallint NOT NULL CONSTRAINT DF_ccInbound_chatQueueOverflow DEFAULT 15,
chatTimeOverflow smallint NOT NULL CONSTRAINT DF_ccInbound_chatTimeOverflow DEFAULT 300,
startStopRecording bit NULL'

	EXEC(@Sql)
	
		set @process = 'ccCamps - Alter Table'
		set @Sql='Alter table ccCamps
add startStopRecording bit NULL'
	
	EXEC(@Sql)
		
		set @process = 'ccRIAChatInboundMsgs - Alter Table'
		set @Sql='ALTER TABLE ccRIAChatInboundMsgs ADD CONSTRAINT fk_Inbound FOREIGN KEY (Inbound_id) REFERENCES ccInbound(Inbound_id)
ALTER TABLE ccRIAChatInboundMsgs ADD CONSTRAINT fk_MsgChat FOREIGN KEY (msg_id) REFERENCES ccRIAChatMsg(msg_id)
ALTER TABLE ccRIAChatInboundMsgs ADD CONSTRAINT fk_TipoMsgs FOREIGN KEY (type) REFERENCES ccTipoMsgs(tipomsg_id)
CREATE UNIQUE INDEX IX_ccInboundMsgs ON ccRIAChatInboundMsgs(msg_id, Inbound_id, orden,type)'

	EXEC(@Sql)
		
		set @process = 'ccsettings - Update'
		set @Sql = 'update ccsettings 
set valor = '''', detalle = ''Solo se debera utilizar si la aplicacion de reportes esta en otro servidor RIA: IP,Dominio'' 
where setting_id = 136'
		
	EXEC(@Sql)
		
		set @process = 'ccsp_RIAUpdateChatConfig - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAUpdateChatConfig]
@action smallint = 0,
@idArea smallint = 0,
@maxChats smallint = 0
AS

if @action = 1 begin	

select top 1 @maxChats = maxChats from ccInbound where IDArea = @idArea
return @maxChats
end

if @action = 2 begin
update ccInbound set maxChats = @maxChats where IDArea = @idArea
end'

	EXEC(@Sql)

		set @process = 'ccsp_ChatLoadCatalogues - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_ChatLoadCatalogues]
@action smallint,
@inboundId smallint = 0,
@userId smallint = 0
AS 
declare @language as tinyint

-- Carga grupos acd, cuando se añada el dominio hay que cambiar la segunda descripcion por dominio
if @action = 1
begin
select inbound_id, chatDomain, inactiveChatTime from ccinbound where chat > 0 and (chatDomain <> null or chatDomain <> '''')
end

if @action = 2
begin
select chatQueueOverflow, chatTimeOverflow from ccinbound where inbound_id = @inboundId
end

if @action = 3  --Se verifica el lenguaje debido a que en ingles el apellido paterno se guarda en el materno
begin	
select @language = valor  from ccsettings where setting_id = 27	
select user_id,Login,Nombres,case when @language = 1 then  apellidoMaterno  else apellidoPaterno end as lastname
from ccusers where status = 1 and TipoUser_id = 1
end

if @action = 4  --Se verifica el lenguaje debido a que en ingles el apellido paterno se guarda en el materno
begin	
select @language = valor  from ccsettings where setting_id = 27		
select Login,Nombres,case when @language = 1 then  apellidoMaterno  else apellidoPaterno end as lastname
from ccusers where status = 1 and TipoUser_id = 1 and user_id = @userId
end'

	EXEC(@Sql)
		
		set @process = 'ccsp_RIAInsertChat - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null
AS

if @action = 1 begin -- Inserta nuevo chat request
insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
values(@domain,@session,@status,getDate(),0,@clientName)
select scope_identity()	as chatId
end

if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
end

if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

if @action = 4 begin -- Save Final Status
if @firstMessage = 0
	begin
		update ccRIAChats set finishedBy = @finished where chatId = @chatId
	end
else
	begin
		update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
	end
end

if @action = 5 begin -- Save Chatting Time
update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
end'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatDispositions - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatDispositions]
@action smallint,
@chatId smallint,
@disposition smallint,
@subDisposition smallint,
@wrapUpTime smallint =0
as

if @action = 1 begin

update ccRIAChats set disposition = @disposition, subDisposition = @subDisposition, tWrapUp=@wrapUpTime where chatId = @chatId


end'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatGetAllInfoACD - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatGetAllInfoACD]
@Option AS SMALLINT,
@User_id AS SMALLINT,
@Date AS DATETIME = NULL
AS
SET NOCOUNT ON

DECLARE @dateStart DATETIME
DECLARE @dateEnd   DATETIME

IF @Date IS NULL
BEGIN
	SET @Date = GETDATE()
END

SET @dateStart = CONVERT(DATETIME, DATEDIFF(DAY, 0, @Date))
SET @dateEnd   = DATEADD (DAY, 1, @datestart)
SET @dateEnd   = DATEADD (SECOND, -1, @dateend)

IF @Option = 1 -- Chats
BEGIN

SELECT
	InboundId,
	Chats             = ISNULL (COUNT(*), 0),
	Request           = ISNULL (COUNT (CASE WHEN chatStatus =  0 THEN 1 ELSE NULL END), 0),
	InactiveDomain    = ISNULL (COUNT (CASE WHEN chatStatus =  1 THEN 1 ELSE NULL END), 0),
	UnavailableAgents = ISNULL (COUNT (CASE WHEN chatStatus =  2 THEN 1 ELSE NULL END), 0),
	Assigned          = ISNULL (COUNT (CASE WHEN chatStatus =  3 THEN 1 ELSE NULL END), 0),
	Connected         = ISNULL (COUNT (CASE WHEN chatStatus =  4 THEN 1 ELSE NULL END), 0),
	OutOfService      = ISNULL (COUNT (CASE WHEN chatStatus =  5 THEN 1 ELSE NULL END), 0),
	OutOfSchedule     = ISNULL (COUNT (CASE WHEN chatStatus =  6 THEN 1 ELSE NULL END), 0),
	NoSignedAgents    = ISNULL (COUNT (CASE WHEN chatStatus =  7 THEN 1 ELSE NULL END), 0),
	Queued            = ISNULL (COUNT (CASE WHEN chatStatus =  8 THEN 1 ELSE NULL END), 0),
	Abandon           = ISNULL (COUNT (CASE WHEN chatStatus =  9 THEN 1 ELSE NULL END), 0),
	QueueOverflow     = ISNULL (COUNT (CASE WHEN chatStatus = 10 THEN 1 ELSE NULL END), 0),
	TimeOverflow      = ISNULL (COUNT (CASE WHEN chatStatus = 11 THEN 1 ELSE NULL END), 0),

	ChattingAveTime   = ISNULL (CONVERT (INT, ROUND (AVG (CASE WHEN chatStatus = 4 THEN (tChatting + tWrapUp) * 1.0 ELSE NULL END), 0)), 0),
	QueueAveTime      = ISNULL (CONVERT (INT, ROUND (AVG (CASE WHEN onQueue    = 1 THEN  tQueue               * 1.0 ELSE NULL END), 0)), 0),
	QueueMaxTime      = ISNULL (                     MAX (CASE WHEN onQueue    = 1 THEN  tQueue                     ELSE NULL END)     , 0)

	FROM ccRIAChats
	WHERE requestDate >= @dateStart AND requestDate <= @dateEnd
	AND InboundId IN (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0)
	GROUP BY InboundId
END

SET NOCOUNT OFF'

	EXEC(@Sql)

		set @process = 'ccsp_ChatLoadChatsStatus - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_ChatLoadChatsStatus] 
@acdId int ,
@startDate datetime ,
@endDate datetime ,
@finishedChatsThreshold int = 10,
@abandonedChatsThreshold int = 10
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.	
SET NOCOUNT ON;
SELECT a.chatStatus as ''status'',
ISNULL(a.onQueue,0) as ''queued'',
CASE 
	WHEN a.ChatStatus = 4 AND a.tChatting >= @finishedChatsThreshold THEN 1					--Valid chat
	WHEN a.ChatStatus = 9 AND a.onQueue = 1 AND a.tQueue <= @abandonedChatsThreshold THEN 1    --Valid abandon
ELSE 0
END As ''valid'',
COUNT(*) AS ''count'',
SUM(a.tChatting) as ''timeChatting'',
SUM(a.tWrapUp) as ''timeWrapup'',
SUM(a.tQueue) AS ''timeWaiting'',
MAX(a.tQueue) AS ''maxWaiting''
FROM dbo.ccRIAChats as a
WHERE a.inboundId = @acdId     
AND a.requestDate BETWEEN @startDate AND @endDate
GROUP BY a.inboundId, a.chatStatus, ISNULL(a.onQueue,0), 
CASE 
	WHEN a.ChatStatus = 4 AND a.tChatting >= @finishedChatsThreshold THEN 1					--Valid chat
	WHEN a.ChatStatus = 9 AND a.onQueue = 1 AND a.tQueue <= @abandonedChatsThreshold THEN 1    --Valid abandon
ELSE 0
END -- As ''valid''
END'

	EXEC(@Sql)

		set @process = 'ccsp_ChatSaveQueueInfo - Create Procedure'
		set @Sql='CREATE PROCEDURE ccsp_ChatSaveQueueInfo 	
@action int ,
@chatId int ,
@timeQueued int 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF @action = 1 
	BEGIN
		UPDATE dbo.ccRiaChats SET tQueue = @timeQueued, onQueue = 1 WHERE chatId = @chatId ;			
	END
END'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatACDSchedule - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatACDSchedule]
@Option     AS SMALLINT,
@Inbound_Id AS INT
AS
SET NOCOUNT ON
SET DATEFIRST 1

declare @today  datetime
declare @day    smallint
declare @hour   smallint
declare @minute smallint
declare @total  smallint

IF @Option = 1 -- Schedule
BEGIN

select @today =  getdate()
select @day = datepart(dw,@today), @hour = datepart(hh,@today), @minute = datepart(mi,@today)

if ( @day=1 )	--LUNES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND LUNES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=2	--MARTES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND MARTES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=3	--MIERCOLES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND MIERCOLES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=4	--JUEVES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND JUEVES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=5	--VIERNES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND VIERNES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=6	--SABADO
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND SABADO = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=7	--DOMINGO
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND DOMINGO = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
select @total as ''ValidACDSchedules''
END

SET NOCOUNT OFF'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatMailbox - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatMailbox]
@action int,
@session varchar(80),
@pathFile varchar(500)
AS
if @action = 1 begin

	declare @chatId as int
	--El where de la fecha es para acotar resultados
	select @chatId = isnull(chatId,0) from ccriachats with(nolock) where session = @session and requestDate >= dateadd(hh, -1, getdate())  

	if @chatId <> 0 begin
		insert into ccRIAChatMailbox(chatId,[file]) values (@chatId, @pathFile)								
	end				

end'

	EXEC(@Sql)

		set @process = 'ccsp_ChatFinder - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_ChatFinder] 
@option int, 
@dateStart varchar(11),
@dateEnd varchar(11),
@acdGroup varchar(max),
@agents varchar(max),
@dispositions varchar(max),
@durationStart varchar(max),
@durationEnd varchar(max),
@chatId varchar(max),
@client varchar(max),
@domain varchar(max)
as

declare @sql nvarchar(max)

if @option = 1
begin
	set @sql = ''select chatId, isnull(b.descripcion,'''''''') as [acdGroup], isnull(c.description,'''''''') as [disposition], 
	isnull(login,'''''''') as [agent], chatDate, tChatting as [duration], clientName, domain
	from dbo.ccRIAChats a
	left join ccinbound b on (a.inboundId = b.inbound_id)
	left join ccTipoCalif c on (a.disposition = c.calif_id)
	left join ccusers d on (a.userId = d.user_id)
	where chatStatus = 4 ''

	if @chatId <> ''''
		set @sql = @sql + ''and chatId = '' + @chatId + '' ''
	else
		begin
			if @dateStart <> ''''
				set @sql = @sql + ''and chatDate >= '''''' + @dateStart + '' 00:00:00'' + '''''' ''

			if @dateEnd <> ''''
				set @sql = @sql + ''and chatDate < '''''' + @dateEnd + '' 23:59:59'' + '''''' ''

			if @acdGroup <> ''''
				set @sql = @sql + ''and a.inboundId in ('' + @acdGroup + '') ''

			if @agents <> ''''
				set @sql = @sql + ''and a.userId in ('' + @agents + '') ''

			if @dispositions <> ''''
				set @sql = @sql + ''and a.disposition in ('' + @dispositions + '') ''

			if (@durationStart <> '''' and @durationEnd = '''')
				set @sql = @sql + ''and tChatting >= '' + @durationStart + '' ''

			if (@durationStart = '''' and @durationEnd <> '''')
				set @sql = @sql + ''and tChatting <= '' + @durationEnd + '' ''

			if (@durationStart <> '''' and @durationEnd <> '''') and (convert(int,@durationStart) <= convert(int,@durationEnd))
				set @sql = @sql + ''and tChatting between '' + @durationStart + '' and '' + @durationEnd + '' ''

			if @client <> ''''
				set @sql = @sql + ''and clientName like ''''%'' + @client + ''%'''' ''

			if @domain <> ''''
				set @sql = @sql + ''and domain like ''''%'' + @domain + ''%'''' ''
		end

	set @sql = @sql + ''order by chatId''

	--print (@sql)
	exec (@sql)
end'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatFinder - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatFinder]
@action int,
@userId smallint = 0,
@params varchar(500) = '''',
@status bit = 0,
@id int = 0,
@template varchar(100) = ''''
AS

if @action = 1 begin  --Guarda nueva busqueda
insert into ccRIAChatFinder values(@userId,@params,1,@template)	
end

if @action = 3 begin --Actualiza busquedas
update ccRIAChatFinder set [status]=@status where id = @id
end

if @action = 4 begin --Actualiza busquedas
update ccRIAChatFinder set params=@params where id = @id

end

select ID,params,template from ccRIAChatFinder where userId = @userId and [status] = 1'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatGetAutoMessage - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatGetAutoMessage]
@action as tinyint,
@inboundId as int=null,
@type as tinyint=null,
@session as varchar(50)=null
AS
BEGIN

if @action = 1 begin

	select b.msg_id,b.msg from ccRIAChatInboundMsgs a inner join ccRIAChatMsg b 
	on a.msg_id = b.msg_id where Inbound_id = @inboundId and type = @type order by orden

end	
if @action = 2 begin
	select b.msg_id,b.msg from ccRIAChatInboundMsgs a 
	inner join ccRIAChatMsg b on a.msg_id = b.msg_id 
	inner join ccRiaChats c on a.Inbound_id = c.inboundId
	where c.[session] = @session
	and type = @type
	and convert(smalldatetime,CONVERT(varchar(11),c.requestDate,121)) = convert(smalldatetime,CONVERT(varchar(11),getdate(),121))
	order by orden

end

END'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatCATMessages - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatCATMessages]
@command tinyint,
@msg_id int=0,
@Description varchar(40)='''',
@msg varchar(255) = ''''

AS
set nocount on
If @command=0
begin
SELECT Descripcion FROM ccRIAChatMsg WHERE msg_id=@msg_id
return(0)
end 

If @command=1
begin
SELECT msg_id, msg,Descripcion from ccRIAChatMsg order by msg_id
return(0)
end 

if @command=2
begin
if EXISTS(select Descripcion from ccRIAChatMsg where Descripcion=@Description)
 begin
	select 1, ''Description en Uso''
	return(0)
 end

Insert ccRIAChatMsg (msg, descripcion) select @msg, @Description
return(0)
end 

if @command=3
begin
if exists(select msg_id from ccRIAChatInboundMsgs where msg_id=@msg_id)
 begin 
	select 1 --''Este Mensaje tiene alguna Especialidad asignada''
	return(0)
 end

Delete ccRIAChatMsg Where msg_id=@msg_id
return(0)
end 

if @command=4 
begin
Update ccRIAChatMsg set msg=@msg, descripcion=@Description Where msg_id=@msg_id
return(0)
end

if @command=5
begin
if EXISTS(select Descripcion from ccRIAChatMsg where descripcion= @Description)
 begin
	select 1, ''Descripcion en Uso''
	return(0)
 end

Insert ccRIAChatMsg (msg, descripcion) select @msg, @Description
return scope_identity()
end

set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_RIAChatADMInboundMsgs - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatADMInboundMsgs]
@Command tinyint, -- 1=Query, 2=Insert, 3=Delete
@msg_id int=null,
@Inbound_id smallint=null,
@order tinyint=null,
@Type tinyint=null
as
set nocount on
if @Command=1
begin
select A.type, A.orden, msg, A.Msg_id, D.msg_mostrar
from ccRIAChatInboundMsgs A join ccInbound B on A.Inbound_id=B.Inbound_id
join ccRIAChatMsg C on A.Msg_id=C.Msg_id left join ccTipoMsgs D on A.type=D.tipomsg_id
where A.Inbound_id=@Inbound_id
order by A.type, A.orden
return(0)
end

If @Command=2
begin
if not exists(select msg_id from ccRIAChatInboundMsgs where msg_id=@msg_id and inbound_id=@inbound_id and type=@type)
	insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type) values (@msg_id, @Inbound_id, @order, @Type)
return(0)
end
/*
if @Command=4
begin
update ccRIAChatInboundMsgs set queue=@queue 
where Inbound_id=@Inbound_id and Msg_id=@msg_id and orden=@order and type=1
return(0)
end
*/
set nocount off'

EXEC(@Sql)

		set @process = 'ccsp_RIAChatADMInboundMsgs_Del - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIAChatADMInboundMsgs_Del]
@msg_id varchar(255) = null,
@Inbound_id smallint = null,
@order varchar(255) = null,
@Type varchar(255) = null
as
set nocount on

declare @i int, @x int
declare @T_msg_id as table (id int, msg_id varchar(255))
declare @T_order as table (id int, [order] varchar(255))
declare @T_Type as table (id int, [type] varchar(255))
declare @T_all as table (id int, Inbound_id int, msg_id int, [order] int, [type] int)
declare @temp_ccRIAChatInboundMsgs as table(id int identity, Msg_id int, Inbound_id smallint, orden tinyint, Type tinyint)

insert @T_msg_id select * from dbo.fn_RIASplitDelimited(@msg_id, '','')
insert @T_order select * from dbo.fn_RIASplitDelimited(@order, '','')
insert @T_Type select * from dbo.fn_RIASplitDelimited(@Type, '','')

insert @T_all select m.id, @Inbound_id, msg_id, [order], [type] 
from @T_msg_id m join @T_order o on m.id = o.id join @T_Type t on o.id = t.id
order by o.[order]

select @i = 1, @x = count(id) from @T_all

while @i <= @x
begin
delete ccRIAChatInboundMsgs
where Inbound_id = @Inbound_id 
and msg_id in (select msg_id from @T_all where id = @i) 
and orden in (select [order] from @T_all where id = @i)
and Type in (select Type from @T_all where id = @i)
set @i = @i+1
end

insert @temp_ccRIAChatInboundMsgs select distinct r.*
from ccRIAChatInboundMsgs r join @T_all a on
r.Inbound_id = a.Inbound_id and r.Type = a.Type
order by orden

select @i = 1, @x = count(id) from @temp_ccRIAChatInboundMsgs

while @i <= @x
begin
delete ccRIAChatInboundMsgs 
where Inbound_id = @Inbound_id 
and msg_id in (select msg_id from @temp_ccRIAChatInboundMsgs where id = @i) 
and orden in (select orden from @temp_ccRIAChatInboundMsgs where id = @i)
and Type in (select Type from @temp_ccRIAChatInboundMsgs where id = @i)
set @i = @i+1
end

update @temp_ccRIAChatInboundMsgs set orden = id
insert into ccRIAChatInboundMsgs (Msg_id, Inbound_id, orden, Type)
select Msg_id, Inbound_id, orden, Type from @temp_ccRIAChatInboundMsgs

return(0)
set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_RIAConfEspec - Alter Procedure'
		set @Sql='ALTER procEDURE [dbo].[ccsp_RIAConfEspec] 
@User_id int 
AS 
set nocount on
select inbound_id, Descripcion, Status, tNotas,
tMaxWaitCall, nMaxQue,tel_maxwait, tel_MaxQueue, tel_outservice, tel_noct, ShowCalifWnd, 
StartTimerOnHangUp, editableCallKey, queuePosition, tMaxQueueCallBack, stopRecording, dialPrefixOverflow,
OpriorityT, callerIdDesc, chat, inactiveChatTime, maxChats, chatDomain, chatQueueOverflow, chatTimeOverflow,
startStopRecording
from ccInbound 
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 2))
return(0)
set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_RIAUpdateEspecConfig - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint,
@descripcion varchar(50) = null,
@Status tinyint = null,
@tNotas int = null,
@tMaxWaitCall int = null,
@nMaxQue int = null,
@tel_maxwait varchar(15) = null,
@tel_MaxQueue varchar(15) = null,
@tel_outservice varchar(15) = null,
@tel_noct varchar(15) = null,
@ShowCalifWnd bit = null,
@StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@queuePosition bit = null, 
@tMaxQueueCallBack smallint = null,
@stopRecording bit = null,
@dialPrefixOverflow varchar(10) = null,
@OpriorityT smallint= null,
@callerIdDesc varchar(15) = null,
@chat tinyint = null,
@inactiveChatTime smallint = null,
@maxChats tinyint = null,
@chatDomain varchar(max) = null,
@chatQueue smallint = null,
@chatTime smallint = null,
@dRestrictPlay bit = null
as
set nocount on
UPDATE ccInbound SET 
descripcion = isnull(@descripcion,descripcion),
Status = isnull(@status,status),
tNotas = isnull(@tNotas,tNotas),
tMaxWaitCall = isnull(@tMaxWaitCall,tMaxWaitCall),
nMaxQue = isnull(@nMaxQue,nMaxQue),
tel_maxwait = isnull(@tel_maxwait,tel_maxwait),
tel_MaxQueue = isnull(@tel_MaxQueue,tel_MaxQueue),
tel_outservice = isnull(@tel_outservice,tel_outservice),
tel_noct = isnull(@tel_noct,tel_noct),
bnocturno = case when isnull(@tel_noct,''0'')=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
StartTimerOnHangUp = isnull(@StartTimerOnHangUp,StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey,editableCallKey),
queuePosition = isnull(@queuePosition,queuePosition),
tMaxQueueCallBack = isnull(@tMaxQueueCallBack,tMaxQueueCallBack),
stopRecording = isnull(@stopRecording, stopRecording),
dialPrefixOverflow = isnull(@dialPrefixOverflow, dialPrefixOverflow),
OpriorityT = isnull(@OpriorityT, OpriorityT),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
chat = isnull(@chat,chat),
inactiveChatTime = isnull(@inactiveChatTime,inactiveChatTime),
maxChats = isnull(@maxChats,maxChats),
chatQueueOverflow = isnull(@chatQueue,15),
chatTimeOverflow = isnull(@chatTime,300),
startStopRecording = isnull(@dRestrictPlay,startStopRecording)
where inbound_id = @inbound_id

if not exists( select inbound_id from ccinbound where inbound_id <> @inbound_id and chatDomain = @chatDomain ) begin
if isnull(@chatDomain,'''') <> '''' begin
	update ccinbound set chatDomain = @chatDomain where inbound_id = @inbound_id
end
end
else begin 
raiserror(''Domain already in another ACD Group'',15,4)
end


if @ShowCalifWnd = 1
begin
If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
 begin
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
	where inbound_id = @inbound_id
	select 1
	return(0)
 end

select 0
return(0)
end

else
UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
where inbound_id = @inbound_id
return(0)
set nocount off'

	EXEC(@Sql)
	
		set @process = 'ccsp_AgentGetStartStopPermission - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_AgentGetStartStopPermission]
@age_id int,
@cam_id int,
@call_type int

AS
BEGIN

	SET NOCOUNT ON;

declare @agentRec int, @valor as int

set @agentRec = (select startStopRecording from ccusers where [User_id] = @age_id)

IF @agentRec = 1
BEGIN

---------- Entra agente con permiso de StartStopRecording
IF @call_type = 1 BEGIN ------- Revisamos especialidad

set @valor = (select startStopRecording from ccInbound where Inbound_id = @cam_id )

END
ELSE ------- Revisamos Campaña
BEGIN

set @valor = (select startStopRecording from ccCamps where cam_id = @cam_id )

END
----------

END
ELSE
BEGIN

set @valor = 0

END

select @valor

END'

	EXEC(@Sql)
	
		set @process = 'ccsp_AgentGetStartStopRecValue - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_AgentGetStartStopRecValue]
@user_id int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @user_ok int, @setting_ok int, @result int

set @user_ok = (select isnull(startStopRecording,0) from ccusers where [User_id] = @user_id)
set @setting_ok = (select valor from ccsettings where setting_id = 142)

IF @user_ok = 1 AND @setting_ok = 1
BEGIN
set @result = 1
END
else
BEGIN
set @result = 0
END

select @result


END'

	EXEC(@Sql)

		set @process = 'ccsp_RIACATChatPredefinedMsg - Create Procedure'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_RIACATChatPredefinedMsg]
@message_id varchar(max)=null,
@Description varchar(40)=null,
@message varchar(max)=null,
@Type smallint,
@CamEspId smallint=null
AS
set nocount on
declare @sql nvarchar(1000)

if @Type=1 -- Load
 begin
	Select message_id, description, [message] from ccRIAChatPredefinedMsg where message_status=1 order by 2
	return(0)
 end

If @Type=2 -- New
 begin
	If exists(select description from ccRIAChatPredefinedMsg where message_status=1 and description=@Description)
	 begin
		select -1
		return(0)
	 end
	 
	declare @msg_id smallint 
	set @msg_id = 0
	select top 1 @msg_id=message_id from ccRIAChatPredefinedMsg where message_status=0 and description=@Description
	If @msg_id>0
	begin
		update ccRIAChatPredefinedMsg set message_status=1, [message]=@message where description=@Description
		select @msg_id
		return(0)
	end

	insert into ccRIAChatPredefinedMsg (description, [message]) values (@Description,@message)
	select SCOPE_IDENTITY()
	return(0)
 end

If @Type=3 -- Update
 begin
	If exists(select description from ccRIAChatPredefinedMsg where message_status=1 and description=@Description)
		set @Description=null

	UPDATE ccRIAChatPredefinedMsg set Description=isnull(@Description, Description),[message]=isnull(@message, [message]) 
	where message_id in (select value from dbo.fn_RIASplitDelimited(@message_id, '',''))
	
	return(0)
 end

If @Type=4 -- Delete
 begin
	delete from ccRIAChatInboundPredefinedMsg where message_id in (select value from dbo.fn_RIASplitDelimited(@message_id, '',''))
	update ccRIAChatPredefinedMsg set message_status=0 where message_id in (select value from dbo.fn_RIASplitDelimited(@message_id, '',''))
	return(0)
 end

If @Type=5 --Relation
 begin
	select description from ccRIAChatPredefinedMsg where message_id=@message_id
	return(0)
 end

set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAChatPredefinedMsg - Create Procedure'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAChatPredefinedMsg]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InsertMessage_id varchar(1000),
@DeleteMessage_id varchar(1000)
AS
set nocount on

If @Type=1--get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where a1.chat>0 and isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=2--query
 begin
	select i.Inbound_id, descripcion , c.message_id, description, [message]
	from ccInbound i inner join ccRIAChatInboundPredefinedMsg c on i.Inbound_id=c.Inbound_id
	inner join ccRIAChatPredefinedMsg m on m.message_id=c.message_id where m.message_status=1 and i.Inbound_id=@CamEspID
	order by 4
	return(0)
 end

If @Type=3--get Areas
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql nvarchar(1000), @nIDArea nvarchar(10)

if @Type=4--Insert Schedules
 begin
	If @Type2=2
	 begin
		If exists(select inbound_id from ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID and message_id=@InsertMessage_id)
			select 2
		else
			if exists(select inbound_id from ccInbound where Inbound_id=@CamEspID) and exists(select message_id from ccRIAChatPredefinedMsg where message_status=1 and message_id=@InsertMessage_id)
					insert ccRIAChatInboundPredefinedMsg(inbound_id, message_id) select @CamEspID, @InsertMessage_id
		return(0)
	 end

	If @Type2<>1
		return(0)

		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql=''insert ccRIAChatInboundPredefinedMsg (inbound_id,message_id) 
			select distinct a.inbound_id, b.message_id from ccInbound a, ccRIAChatPredefinedMsg b where
			b.message_id in(''+@InsertMessage_id+'') and b.message_status=1 
			and not exists(select c.inbound_id, e.message_id from ccRIAChatInboundPredefinedMsg c
			join ccRIAChatPredefinedMsg e on e.message_id=c.message_id
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
			'' where c.inbound_id=a.inbound_id and b.message_id=e.message_id)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'' and chat>0)''
			execute sp_executesql @sql
		end
		return(0)
 end

If @Type=5--Delete Schedules
 begin
	If @Type2=2
	 begin
		delete ccRIAChatInboundPredefinedMsg where inbound_id=@CamEspID	and message_id=@DeleteMessage_id
		return(0)
	 end

	If @Type2<>1
		return(0)
		
		set @nIDArea = 0
		select @nIDArea=IDArea from ccUsers where USER_ID=@User_id
		if @nIDArea>0
		begin
			set @sql=''delete ccRIAChatInboundPredefinedMsg where inbound_id in(select inbound_id from 
			ccInbound where IDArea=''+@nIDArea+'') and message_id in(''+@DeleteMessage_id+'')''
			execute sp_executesql @sql
		end
		return(0)

 end
 
 If @Type=6 --get Areas
 begin
	select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	return(0)
 end

return(0)
set nocount off'
		
	EXEC(@Sql)
		
		set @process = 'ccsp_CWCheckMigration - Create Procedure'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_CWCheckMigration]
AS
BEGIN
		if not exists(select * from migrationAVRS WHERE status=0)
		begin
			return 1
		end
		else
		begin
			return 0
		end
END'
		
	EXEC(@Sql)
		
		set @process = 'ccsp_RIA_ABCAreas - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40)
AS
set nocount on
if @option=1 --Selected Area
begin
declare @maxchats as smallint

Select a.IDArea, AreaName, maxChats as maxChats  from ccRIACat_Areas a 
left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b
on a.IDArea = b.IDArea
where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0) 
when 0 then isnull(a.IDArea,0) else @IDArea end
order by AreaName
return(0)
end

if @option=2 --Insert Area
begin
if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
 begin
	select -1--, Nombre en Uso
	return(0)
 end

Insert into ccRIACat_Areas (AreaName) values (@Descripcion)			
select 1--, Area Insertada
return(0)
end

if @option=3 --Update Area
begin
if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
	Update ccRIACat_Areas set AreaName=@Descripcion where IDArea=@IDArea

return(0)
end

if @option=4 --Delete Area
begin	
if (exists(select IDArea from ccUsers where IDArea=@IDArea) 
 or exists(select IDArea from ccCamps where IDArea = @IDArea)
 or exists(select IDArea from ccInbound where IDArea=@IDArea)) 
 and (select valor from ccSettings where setting_id=95)<>1
 begin
	select -1
	return(0)
 end

declare @DWorkGroups as varchar(500)
Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

select @DWorkGroups = coalesce(@DWorkGroups + '','', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

if (select valor from ccSettings where setting_id=95)=1
 begin
	Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea	
	Update ccCamps set IDArea=NULL where IDArea=@IDArea
	Update ccUsers set IDArea=NULL where IDArea=@IDArea
 end

Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea
select @DWorkGroups
return(0)
end
return(0)
set nocount off'

	EXEC(@Sql)
		
		set @process = 'ccsp_RIAADMGetCalifDay - Alter Procedure'
		set @Sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(50), 
Total int ) 

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificaciÃ³n@Otros'' else ''No disposition@Others'' end
from ccsettings where setting_id = 27 -- 0esp

if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
		then case when description is not null 
					then description 
					else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end end as Calificacion, count(*) cantidad 
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
group by  co.cam_id, co.statuscall_id,description,descripcion

if @type=1 
insert into #CalifTemp 
select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion, count(*) 
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
where ci.cal_inicio > @today
and statuscall_id = 13 
group by description, cci.inbound_id 

-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign 
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @type=1 
select tipo, cam_id, calificacion, sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion, count(disposition) as Total 
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	group by inboundId, Description
	union all
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion, sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaÃ±a
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion order by tipo,cam_id 
if @type=0 
select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion, sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaÃ±a
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id, iTotal4Campaign


drop table #CalifTemp 
set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_RIAADMGetCalifDayForced - Alter Procedure'
		set @Sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(50), 
Total int ) 

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificaciÃ³n@Otros'' else ''No disposition@Others'' end
from ccsettings where setting_id = 27 -- 0esp

if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
		then case when description is not null 
					then description 
					else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end end as Calificacion, count(*) cantidad 
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
and co.cam_id = @cam_id
group by  co.cam_id, co.statuscall_id,description,descripcion

if @type=1 
insert into #CalifTemp 
select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion, count(*) 
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
where ci.cal_inicio > @today
and ci.inbound_id = @cam_id
and statuscall_id = 13 
group by description, cci.inbound_id 

-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign 
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @type=1 
select tipo, cam_id, calificacion, sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion, count(disposition) as Total 
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	and a.inboundId = @cam_id
	group by inboundId, Description
	union all
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion, sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaÃ±a
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion order by tipo,cam_id 
if @type=0 
select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion, sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaÃ±a
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id, iTotal4Campaign


drop table #CalifTemp 
set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_RIAvoiceMail - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAvoiceMail]
@type as tinyint,
@msgId int=null,
@bSent int=null,
@mailType int = 0 -- Other=0; ChatMailAdmin=1; ChatMailClient=2
as
set nocount on
if @type=1 -- getSettings
 begin
	declare @SMTP_setting varchar(255)
	declare @svr as varchar(50), @usr as varchar(50), @pwd as varchar(50), @ssl as bit, @typeSend as bit
	declare @smtpPort as integer

	select @SMTP_setting=valor from ccsettings where setting_id=98
	select @svr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 1
	select @usr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 2
	select @pwd = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 3	
	select @smtpPort = cast(value as integer) from  dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 4
	select @ssl = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 5
	select @typeSend = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 6
	if isnull(@smtpPort,0)=0 set @smtpPort=25
	if isnull(@ssl,0)=0 set @ssl=0
	if isnull(@typeSend,0)=0 set @typeSend=0
	
	select isNull(@svr,'''')  as svr, isNull(@usr,'''') as usr, isNull(@pwd,'''') as pwd, @smtpPort as smtpPt, @ssl as [ssl], @typeSend as [typeSend]
	return(0)
 end

if @type=2 -- getMailBoxes
 begin
	if isnull(@msgId,0)=0
	 begin
		raiserror(''Missing msgId'', 18, 1)
		return(0)
	 end

	declare @inbound_id int, @calid int, @acdName varchar(50)

	if @mailType = 0
	begin
		select @calid=cal_id from ccRIA_vmMessages where vmID=@msgId
		select @inbound_id=inbound_id from ccCallsIn where cal_id=@calid
	end
	else
	begin
		select @calid=chatId from ccRIAChatMailbox where ID=@msgId
		select @inbound_id=inboundId from ccRIAChats where chatId=@calid
	end
	
	select @acdName = descripcion from ccInbound where Inbound_id = @inbound_id
	
	if @mailType = 2
	begin
		select '''', @acdName as acdName
		return(0)
	end

	select mailbox, @acdName as acdName from ccRIA_vmMailBoxes M join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID
	where A.inbound_id in (0,@inbound_id)
	return(0)
 end

if @type=3 -- getNext
 begin
	declare @idm int, @archiv varchar(256), @tipo int
	select top 1 @idm= tt.ID, @archiv = tt.[file], @tipo = tt.[type]  from

	(select audios.vmID as ID, audios.archivo as [file], 1 as [type]  from 
	(select top 1 vmID, archivo from ccRIA_vmMessages where vmStatus=0 order by vmintentos, vmID) audios
	union 
	 select chats.ID,chats.[file], 2 as [type] from 
	(select top 1 ID as ID, [file] as [file] from ccRIAChatMailbox where [status] = 0 order by tries, ID) chats) tt

	if @tipo = 1
	begin
		update ccRIA_vmMessages set vmintentos=vmintentos+1 where vmID=@idm		
	end
	else
	begin
		update ccRIAChatMailbox set tries=tries+1 where [ID]=@idm		
	end

	select @idm as id, @archiv as archivo where @idm is not null

	return(0)
 end

if @type=4 -- setResult
 begin
	if @bSent is null or isnull(@msgId,0)=0
	 begin
		raiserror(''Missing data'', 18, 1)
		return(0)
	 end

 	if @bSent=1
	 begin
		if @mailType = 0
		begin
			update ccRIA_vmMessages set vmStatus=1 where vmID=@msgId			
		end
		else
		begin
			update ccRIAChatMailbox set [status] = 1 where ID = @msgId						
		end
		return(0)
	 end

		if @mailType = 0 
		begin
			update ccRIA_vmMessages set vmStatus=case when vmintentos<10 then vmStatus else 2 end where vmID=@msgId 
		end
		else
		begin
			update ccRIAChatMailbox set [status]=case when tries<10 then [status] else 2 end where ID=@msgId 
		end		
		return(0)	
	
	
 end'
				
	EXEC(@Sql)

		set @process = 'ccsp_RIAtmpChart - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAtmpChart]
@inbound_id smallint = NULL,
@graphicType smallint = NULL
as
SET NOCOUNT ON

declare @DT as int
select @DT = valor from ccsettings where setting_id = 12

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 141

if @graphicType = 1
begin
	declare @Fecha smalldatetime, @FechaW smalldatetime

	select @Fecha=convert(varchar(10), getdate(), 121)

	if exists(select cal_Inicio from cccallsin_tmpChart where cal_inicio < @Fecha)
		truncate table cccallsin_tmpChart

	delete cccallsin_tmpChart where inbound_id = @inbound_id and cal_inicio >= @Fecha
	select @FechaW=@Fecha

	while @FechaW <= convert(varchar(15), getdate(), 121)+''0:00''
	 begin
		if exists(Select SL.inbound_id from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt, 
			 sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
				from (Select @inbound_id inbound_id, @fechaW cal_inicio,
				 ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
				 ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
				 ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
				 ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
				 ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
				 ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
				 ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
				 ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
				 ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
				from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
				group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL)
		 begin
			insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
			Select SL.* ,case when (LC+LA+LS+LDt+LDc+LNC+LP) = 0 then ''1'' else cast((cast((LCt+LAt) as float)/cast((LC+LA+LS+LDt+LDc+LNC+LP) 
			 as float))*100 as decimal(18,2))end ServN 
			from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt, 
			 sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
				from (Select @inbound_id inbound_id, @fechaW cal_inicio,
				 ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
				 ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
				 ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
				 ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
				 ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
				 ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
				 ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
				 ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
				 ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
				from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
				group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL
		 end

		else
		 begin
			insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
			Select @inbound_id, @FechaW, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		 end
		select @FechaW=dateadd(minute, 10, @FechaW)
	 end

	if not exists(select d.descripcion from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join (select c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
		from cccallsin_tmpChart c join ccinbound i on c.inbound_id = i.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
		group by c.inbound_id, i.descripcion, c.NS) D on c.inbound_id = d.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id)
	 begin
		raiserror(''without ACD Group information	 '', 18, 1)
		return(0)
	 end

	select * from 
	(select top 20 @inbound_id inbound_id, d.descripcion, d.NS LastNS, convert(varchar(5), c.cal_inicio, 108) timestamp, c.NS
	from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join 
	(select top 1 c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
	 from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join ccinbound i on c.inbound_id = i.inbound_id
	 where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
		--and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
	 group by c.inbound_id, i.descripcion, c.NS order by timestamp desc) D on c.inbound_id = d.inbound_id
	where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
		--and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
	order by 4 desc) as chart order by 4
	return(0)
end

if @graphicType = 2
begin
	Declare @Times Table (
	StartDate datetime not null,
	EndDate datetime not null,
	[timestamp] varchar(5) not null)

	Declare @Start DateTime 
	Declare @End Datetime

	Set @End = getdate()
	Set @Start = convert(varchar(15),dateadd(minute, -200, @end),121) + ''0:00''

	While @Start < @End begin
		Insert @Times(StartDate, EndDate, [timestamp]) 
		values(@Start, DateAdd(minute, 10, @Start), convert(varchar(5), convert(datetime,@Start), 108))

		Set @Start = DateAdd(minute, 10, @Start) 
	End

	declare @descripcion varchar(50)
	select @descripcion = descripcion
	from ccinbound
	where inbound_id = @inbound_id

	create table #ChatSummary(
	inboundId smallint not null,
	descripcion varchar(50) not null,
	LastNS decimal(10,2) not null,
	[timestamp] varchar(5) not null,
	NS decimal(10,2) not null,
	)

	create table #ChatChart(
	inboundId smallint not null,
	descripcion varchar(50) not null,
	LastNS decimal(10,2) not null,
	[timestamp] varchar(5) not null,
	NS decimal(10,2) not null,
	)

	insert into #ChatSummary
	select inboundId, descripcion, 
	0.00 as LastNS,
	convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	convert(decimal(10,2),convert(float,[Connected]) / convert(float, Total) * 100.00) as NS
	from
	(select inboundId, descripcion, Date,
	sum([Connected>DT]) as [Connected], 
	sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
	sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
	from (
	select inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'' as Date,
	ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
	ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
	ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
	ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
	ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
	ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
	ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
	from ccRIAChats a
	right outer join @times b on (chatDate >= StartDate and chatDate < EndDate)
	left outer join ccInbound c on (inboundId = inbound_id)
	where inboundId = @inbound_id
	and chatStatus in (3,4,7,9,10,11)
	and chatDate is not null
	group by inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'') as ChatDetail
	group by inboundId, descripcion, Date) as ChatSummary

	insert into #ChatChart
	select case when (inboundId is null) then @inbound_id else inboundID end as inboundId, 
	case when (descripcion is null) then @descripcion else descripcion end as descripcion, 
	case when (LastNS is null) then 0.00 else LastNS end as LastNS, 
	case when (a.[timestamp] is null) then b.[timestamp] else a.[timestamp] end as [timestamp], 
	case when (NS is null) then 0.00 else NS end as NS
	from #ChatSummary a
	full outer join @times b on (a.[timestamp] = b.[timestamp])
	order by b.[timestamp]

	select a.inboundId, a.descripcion, b.NS as LastNS, a.[timestamp], a.NS
	from #ChatChart a, #ChatChart b
	where convert(varchar(5),dateadd(minute, -10, convert(datetime,a.[timestamp])), 108) = b.[timestamp]
	order by a.[timestamp]

	drop table #ChatSummary
	drop table #ChatChart
	return(0)
end

SET NOCOUNT OFF'

	EXEC(@Sql)

		set @process = 'ccsp_RIALoadACDGroups - Alter Procedure'
		set @Sql='ALTER PROCedure [dbo].[ccsp_RIALoadACDGroups]
@option smallint,
@AreaId smallint,
@Sup smallint,
@inbound_id int = 0,
@tipoModalidad tinyint = 0 -- llamada 0, chat 1 y ambos 2
AS
set nocount on
if @option = 1 -- Todas los ACDGroups
begin
select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
from ccinbound a1 join ccRIAinboundGraph a2 on (a1.inbound_id = a2.inbound_id)
join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
where a3.type_id = 1
order by descripcion
return(0)
end

if @option = 2 -- ACDGroups de un Area
begin
select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) 
IDArea, dbo.fn_CampEspWG(a1.inbound_id, 2) relationsWG
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
order by descripcion
return(0)
end

if @option = 3 -- ACDGroups por Supervisor
begin
select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) as IDArea, U.monitored
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
join ccSupervisorCam U on a1.inbound_id = U.cam_id
where U.user_id = @sup
and tipo = 0
and a3.type_id = 1 
and a1.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 2)) 	
order by descripcion
return(0)
end

if @option = 4 -- Rels ACD-Agents
begin
select inbound_id, descripcion, User_id, Login, skill, prioridad, IDArea, min(rel_id) rel_id
 from (select E.inbound_id, E.descripcion, A.User_id, A.Login, G.skill, G.prioridad, isnull(E.IDArea, 0) IDArea, G.rel_id
 from ccinboundAgentes G join ccinbound E on G.inbound_id = E.inbound_id
 join ccUsers A on A.User_id = G.User_id and A.TipoUser_Id = 1 and A.Status > 0
 where E.inbound_id in (select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0) 
  when 0 then user_id else @Sup end and tipo = 0)) as Relations
 group by inbound_id, descripcion, User_id, Login, skill, prioridad, IDArea
order by User_id, inbound_id, descripcion, prioridad
return(0)
end

if @option = 5 -- Todos los ACDGroups 
begin
option5:
select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
where a3.type_id = 1
order by descripcion
return(0)
end

if @option = 7 -- Un solo ACDGroups
begin
select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
where a3.type_id = 1 and status = 1 and a1.inbound_id = @inbound_id
order by descripcion
return(0)
end

if @option = 8 -- ACDGroups de un Agente
begin
select distinct a1.inbound_id, a1.descripcion, a3.frame
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
 join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
 join ccInboundAgentes a4 on a1.inbound_id = a4.inbound_id
where a3.type_id=1 and a4.user_id = @Sup
order by 2
return(0)
end

if @option = 9 -- ACDGroups por Supervisor para mensajes llamadas o chat filtra las campaÃ±as
begin
select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) as IDArea, U.monitored
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
join ccSupervisorCam U on a1.inbound_id = U.cam_id
where U.user_id = @sup
and tipo = 0
and a3.type_id = 1 
and a1.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 2)) 
and a1.chat IN (2,@tipoModalidad)
order by descripcion
return(0)
end

return(0)
set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_RIA_ABCWorkGroups - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCWorkGroups]
@option smallint,
@IDWG smallint,
@user_Id smallint = 0,
@Descripcion varchar(45) = null,
@IDArea smallint = null,
@IDCampEsp varchar(2000),
@Type smallint
as
set nocount on
if @option = 0 -- All WokGroup
 begin
	select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1
	
	return(0)
 end

if @option = 1 -- Selected WokGroup
 begin
	if @type = 0
	begin
		select IDWG, WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and IDWG=@IDWG
	end
	else if @type = 1
	begin
		select w.IDWG, w.WGName, a.IDArea
		from ccRIACat_WorkGroup w
		join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
		join ccRIACat_Areas a on a.IDArea = aw.IDArea
		where w.StatusWorkGroup=1
	end
	else if @type = 2
	begin
		select w.WGName, a.IDArea, a.AreaName
		from ccRIACat_WorkGroup w
		join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
		join ccRIACat_Areas a on a.IDArea = aw.IDArea
		where w.StatusWorkGroup=1 and w.IDWG=@IDWG
	end
	else if @type = 3
	begin
		select count(*)
		from ccRIAWorkGroupUsers
		where idwg=@IDWG
		and user_id=@user_Id
	end

	return(0)
 end

if @option = 2 -- insert WorkGroup
 begin
	if exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
	 begin
		select -1 --, Nombre en Uso
		return(0)
	 end
	
	insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	if @@rowcount = 1
		select @IDWG = scope_identity()

	else 
	 begin
		select -2 --, No se inserto correctamente
		return(0)
	 end

	insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
	select 1 --, WG insertado
	return(0)
 end

if @option = 3 -- UpdateWokGroup
 begin
	Update ccRIACat_WorkGroup set WGName=@Descripcion where StatusWorkGroup=1 and IDWG=@IDWG
	return(0)
 end

if @option in (4,8) -- Delete WorkGroup (4:all / 8:only from acd/camps)
 begin
	Delete from ccCampsAgente where IDWG = @IDWG
	Delete from ccInboundAgentes where IDWG = @IDWG
	Delete from ccSupervisorCam where IDWG = @IDWG
	Delete from ccRIACampEspWG where IDWG = @IDWG
	
	if @option=4
	 begin
		Delete from ccRIAAreaWorkGroup where IDWG = @IDWG 
		Delete from ccRIAWorkGroupUsers where IDWG = @IDWG
		Update ccRIACat_WorkGroup set StatusWorkGroup=0 where IDWG=@IDWG
	 end
	return(0)
 end

if @option = 5 -- Insert WorkGroup in Camp or ACDGroup	
 begin
	if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) >= (select valor from ccSettings where setting_id=64) -- limit
	 begin
		select 2
		return(0)
	 end
	
	if exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- Ya existe el grupo en el ACD o Especialidad
	 begin
		select 1
		return(0)
	 end

	insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
	exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
	if @Type not in (0, 1) -- ACDGroup
		return(0)
		
	if @Type=0 --ACDGroup
	begin

		if @IDWG is null or @IDWG = 0
		 begin
			select 48
			return(0)
		 end
		 
		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		 join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
		and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

		insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
		select b.user_id, @IDCampEsp, 0, @IDWG
		from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
		 join ccusers s on b.user_id = s.user_id
		where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
		 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
	 
		return(0)
	end
	
	if @IDWG is null or @IDWG = 0
	 begin
		select 18
		return(0)
	 end

	-- if @Type = 1 -- Camp
	insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
	SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
	FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
	join ccusers s on u.user_id = s.user_id
	WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
	 and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
	
	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select b.user_id, @IDCampEsp, 1, @IDWG
	from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
	 join ccusers s on b.user_id = s.user_id
	where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
	 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)

	return(0)
 end

if @option = 6 -- Verifica si existe el grupo
 begin
  	select @IDWG = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
	 then 1 else 0 end
 
 	if isnull(@IDArea,0)=0
	 begin
		select @IDWG
		return(0)
	 end

 	if @IDWG=1
	 begin
		select ''-1''
		return(0)
	 end

	insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	if @@rowcount = 1
		select @IDWG = scope_identity()

	insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

if @option = 7 -- Delete WokGroup from ACD or Camp
 begin
	if @Type = 1
		Delete from ccCampsAgente where IDWG=@IDWG and cam_id=@IDCampEsp

	else if @Type = 0 
		Delete from ccInboundAgentes where IDWG=@IDWG and inbound_id=@IDCampEsp

	Delete from ccRIACampEspWG where IDWG=@IDWG and IdCampEsp=@IDCampEsp and Tipo=@Type

	return(0)
 end
 
return(0)
set nocount off'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_RIA_ABCAgents - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(12)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(1000)=null
as
set nocount on

if @option=0--All Users
 begin
	select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName
	
from ccusers as users with(nolock)
	 left join ccRIACat_Areas as areas with(nolock)
	 on users.IDArea=areas.IDArea
	return(0)
 end

if @option=1--selected User
 begin
	select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
	 isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
	from ccusers where User_id=@UserId 
	order by IDArea,Nombres,ApellidoPaterno,User_id
	return(0)
 end

if @option=2--insert
 begin
	if exists(select Login from ccUsers where Login=@Login)
	 begin
		select -1--,''Login en Uso''
		return(0)
	 end

	if exists(select Login from ccUsers_Consulta where Login = @Login)
	begin
		select -4 -- ''Login habia estado en Uso''
		return(0)
	end

	if exists(select Nombres from ccUsers where Nombres=@Nombres 
	and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
	 begin
		select -2--,''Nombre en Uso''
		return(0)
	 end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
	set @UserId = null
	SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID 
	FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
	LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
	INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
	FROM ccusers) AS w ON w.recID = d.recID

	if @UserId is null
	begin
		select -2--insert Error
		return(0)
	end
	
	set identity_insert ccusers on
	insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
	 Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
	 1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
	set identity_insert ccusers off

	delete ccMenuUser where id_User = @UserId
	delete ccRIAUserRole where user_id = @UserId
END
ELSE
BEGIN
	insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
	 Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
	 1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

	if @@rowcount=1
		select @UserId=scope_identity()
	else
	 begin
		select -2--insert Error
		return(0)
	 end
END
	insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
	insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
	insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)

	select @UserId,''Usuario '' + @Login + '' Dado de Alta''
	return(0)
 end

if @option=3--Update
 begin
	if @Login='''' and @Password <> ''''
	 begin
		Update ccUsers set Password=@Password where User_id=@UserId
		return(0)
	 end
     
	Update ccUsers 
	set Login=@Login,Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
	Password=case when @Password <> '''' then @Password else Password end,
	Sexo=@Sexo,canChangeStatus=@canChangeStatus where User_id=@UserId
	return(0)
 end

if @option=4--Delete
 begin
	delete from ccMenu_ViewsUser where user_id =@UserId
	delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
	delete from ccUsers where user_id=@UserId
	return(0)
 end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
 begin
	select @Type=TipoUser_id from ccUsers where User_id=@UserId

	if @Type not in(1,2,6)
		return(0)
    
	if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
	 begin
		select 3
		return(0)
	 end

	if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
	 begin
		select 1
		return(0)
	 end     

	insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)    
    
	if @Type=1 
	 begin
	 
	 	if @IDWG is null or @IDWG = 0
		 begin
			select 28
			return(0)
		 end
		insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

		select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
		 and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
		select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
		 and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

		return(0)
	 end

--else @Type=2 or @Type=6--Supervisor
	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,0,@IDWG
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
	 and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,1,@IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
	 and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	return(0)
 end

if @option=6--Delete Agent-Supervisor from WorkGroup
 begin
	if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
		select @UserId = @multipleUsers

	else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
		select @UserId = cast(substring(@multipleUsers, 1, 
		CHARINDEX('','', @multipleUsers)-1) as int)

	 select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
	 @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
	from ccUsers where User_id=@UserId

	Declare @SqlDelete nvarchar(4000)
	if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
	 begin
		set @SqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end 
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))		
		+ '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end 
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
		exec(@SqlDelete)
	 end

	if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
	 begin
		select -9 -- Se ingreso mal el id del usuario
		--delete ccinboundagentes where idwg=@IDWG
		--delete cccampsagente where idwg=@IDWG
		--delete ccSupervisorCam where idwg=@IDWG
	 end

	if @DeleteUsers=1
		Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

	return(0)
 end

if @option=7--Delete Agent from WorkGroup
 begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
	set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end + 
	 '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end + 
	 ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
	 '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10)) 
	exec(@sql)
return(0)
 end

if @option=8--Delete Supervisor from WorkGroup
 begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id='' 
	 + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
	 delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
	exec(@sql)

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' + 
	 ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
	exec(@sql)
	return(0)
 end

if @option=9
 begin
	update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
	return(0)
 end
set nocount off'
				
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAADMGetPermisos - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMGetPermisos] 
@user_id varchar(255), 
@Type int, 
@mask int = 0, 
@xferMask int = 0,
@xstartStopRecording int = 0,
@CanChangeStatus bit = null,
@XferAgents tinyint = null
AS 
set nocount on

If @Type = 1
 begin
	Select distinct A.User_id as ID, Login, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' +
	isNull(ApellidoMaterno, '''') as ''Nombre'', cast(dialMask & 1 as int) as ''Restringe celular'',
	cast( (dialMask & 2) /2 as int) as ''Restringe ld'', cast((dialMask & 4) / 4 as int) as ''Restringe local'',
	cast( xfermask as int) as ''Recibe transferencia'', cast(CanChangeStatus as tinyint) CanChangeStatus, 
	cast(XferAgents as tinyint) XferAgents,
	cast(startStopRecording as tinyint) startStopRecording
	from ccUsers A
	join ccRIAWorkGroupUsers B on A.user_id = B.user_id
	where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
	return(0)
 end

--if @Type = 2
If @xferMask=-1 and @mask=-1 and @xstartStopRecording=-1
 begin
	update ccUsers set NotReadyRestricted = ISNULL(@CanChangeStatus, NotReadyRestricted) , XferAgents = ISNULL(@XferAgents, XferAgents) 
	where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
	return(0)
 end

If @xferMask=-1 and @xstartStopRecording=-1
 begin
	UPDATE ccUsers SET dialMask = @mask where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
 end


if @mask=-1 and @xstartStopRecording=-1
 begin
	UPDATE ccUsers SET xfermask = @xferMask where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
 end

if @mask=-1 and @xferMask=-1
begin
	UPDATE ccUsers SET startStopRecording = @xstartStopRecording where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
 
end

return(0)
set nocount off'

	EXEC(@Sql)
	
		set @process = 'ccsp_RIAConfCamp - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint 
AS 
set nocount on
	select a1.cam_id, cam_Descripcion
	 , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
	 , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
	 , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
	 , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
	 , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
	 , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
	 DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
     ,cast (startStopRecording as tinyint)startStopRecording
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'

	EXEC(@Sql)
	
		set @process = 'ccsp_RIAUpdateCamConfig - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null, 
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null, 
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null, 
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null
as
set nocount on
UPDATE ccCamps SET 
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial), 
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine), 
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording)
Where cam_id = @cam_id 

if @cam_ShowCalifWnd = 1
 begin
	If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
	 begin
		select 0
		return(0)
	 end
	 
	UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
	where cam_id = @cam_id
	select 1
	return(0)
  end

--else
UPDATE ccCamps SET 
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'

	EXEC(@Sql)
	
		set @process = 'ccsp_RIAMenuRoles - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on
select @reportRol = case @reportRol when 0 then 1 else @reportRol end, 
 @role_id = case @role_id when 0 then 1 else @role_id end

select @AE = valor from ccsettings where setting_id = 71

Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint

select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 142


If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id 
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin
	if @Role_id in (1, 10) and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	 begin
		Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
		if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)
					Insert into ccMenuUser values(@User_id,40,1)
		else If not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999))
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, 2 from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
		
	 end

	else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
	 begin
		if @InsertMenu_id <> 40
			  delete ccMenuUser where id_User = @User_id and type = @reportRol

		Insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
		If @reportRol = 1
			  Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,1)
	 end

	If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--    inserta parent en caso de no haberlo hecho en rol personalizado        
	Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
	(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
	where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
	where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

	return(0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
  Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

      else
            insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
      select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))  
		and ( b.id_Menu not in(79) or (@MenusChat = 1 and b.id_Menu in(79)))  
	  order by ordengral asc
      return(0)
 end

If @Type = 7 -- Get language
 begin
      select valor from ccSettings where setting_id = 27
      return(0)
 end

If @Type = 8 -- Insert the personalized menus of a supervisor
 begin
      insert into ccMenuUser (id_User, id_Menu, type)
      select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
       begin
            Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
            return(0)
       end

      insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 9 -- Delete all supervisor menus 
 begin
      delete ccMenuUser where id_User = @User_id and type = @reportRol
      return(0)
 end

If @Type = 10 -- Delete all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
      where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol 
      group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

      return(0)
 end

If @Type = 12
 begin
      declare @lan as tinyint
      select @lan = valor from ccSettings where setting_id = 27
      select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
      return(0)
 end

return(0)
set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIACATMenu - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145

if @Type=1
begin
	if @ReportRol <> 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	and ((menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79)) 
	or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	or (menu_id in (71,72) and @IVRScripting = 1)
	or (menu_id in (73,74,75,76) and @AVRS = 1)
	or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
	or (menu_id = 79 and @MenusChat > 0))
	order by ordengral asc
	return(0)


	--if @AVRS = 1
	--begin
	--	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	--	and ((menu_id not in (41,42,53,71,72,77,78)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	--	or (menu_id = 77 and @RelationCampInbNotReady = 1) or (menu_id = 78 and @RelationCampInbNotReady = 1)
	--	or (menu_id = 71 and @IVRScripting = 1) or (menu_id = 72 and @IVRScripting = 1))
	--	order by ordengral asc
	--	return(0)
	--end
	--else
	--begin
	--	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	--	and ((menu_id not in (41,42,53,71,72,73,74,75,76,77,78)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	--	or (menu_id = 77 and @RelationCampInbNotReady = 1) or (menu_id = 78 and @RelationCampInbNotReady = 1)
	--	or (menu_id = 71 and @IVRScripting = 1) or (menu_id = 72 and @IVRScripting = 1))
	--	order by ordengral asc
	--	return(0)
	--end
end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser values (@id_User, @id_Menu,1)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
  
  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIARegistryLists - Alter Procedure'
		set @Sql = 'ALTER Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0, 
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '''',
@status tinyint = 0,
@sequence smallint = 0
AS

--Status lista 0: inactiva, 1:pausa, 2:procesar

--Insert
IF @action = 1 begin

	IF @cam_id <> 0 begin
		select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
		set @sequence = @sequence + 1
		Insert into ccRIARegistryLists values (@cam_id, @name, 2, @sequence)
		select max(list_id) from ccRIARegistryLists
	end
end

--Update sequence
IF @action = 2 begin
	
	declare @oldSeq as int
	select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

	if @oldSeq <> @sequence begin
		
		if @oldSeq > @sequence begin
			update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
		end

		if @oldSeq < @sequence begin
			update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
		end

		update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

	end

end

--Change status
IF @action = 3 begin
	
	update ccRIARegistryLists set status = @status where list_id = @list_id

end

-- lista campañas y listas de registros
IF @action = 4 begin
	select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame from ccRIARegistryLists a 
	left join cccamps b on a.cam_id = b.cam_id
	left join ccRIACampsGraph c on a.cam_id = c.cam_id
	where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists ) 
	group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

end

-- listas de registros y no. registros
IF @action = 5 begin
	select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence   
	from ccRIARegistryLists a  (nolock) 
	left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_1),nolock) 
	on b.cam_id = @cam_id and a.list_id = b.list_id 
	where a.status > 0 and a.cam_id = @cam_id and status > 0 
	group by a.list_id,a.name,a.sequence order by a.sequence

end

-- borrar lista
IF @action = 6 begin

	select @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id
	select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
	exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id
	exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id

end

-- Detalle de numero de registros
IF @action = 7 begin
	
	if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
		select @status = status from ccRIARegistryLists where list_id = @list_id
		select @list_id as list_id,cam_id, @status as status,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as CB,
			count(case cal_status when 2 then 1 else null end) as Pro, 
			count(case cal_status when 3 then 1 else null end) as Fin
		from ccoWorkingTable where list_id = @list_id group by cam_id
	end
	ELSE begin
		select list_id, cam_id, status, 
		0 as New,
		0 as CB,
		0 as Pro,
		0 as Fin
		from ccRIARegistryLists where list_id = @list_id
	end


end

-- Cambia de nombre a la lista
IF @action = 8 begin
	
	update ccRIARegistryLists set name = @name where list_id = @list_id

end

-- Borra listas sin registros y reordena las listas
IF @action = 9 begin

	Create table TempRegs(
		list_id int,
		[name] varchar(100),
		NoRegistros int,
		sequence int)

	insert into TempRegs select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence from ccRIARegistryLists a 
		left join ccocallsoutsource b on a.list_id = b.list_id
		where a.status > 0 and a.cam_id = @cam_id and status > 0 group by a.list_id,a.name,a.sequence,a.status order by a.sequence

	while ( exists( select list_id from TempRegs where NoRegistros = 0 ) ) begin
		declare @listToDelete as int
		select top 1 @listToDelete = list_id from TempRegs where NoRegistros = 0
		exec ccsp_RIARegistryLists @action = 6, @list_id = @listToDelete
		delete from TempRegs where list_id =  @listToDelete
	end

	drop table TempRegs
	
	select @sequence=min(sequence) from ccRIARegistryLists where  cam_id = @cam_id and status = 0 

	select @list_id= list_id from ccRIARegistryLists where sequence =(
	select  max(sequence) as sequence from ccRIARegistryLists where  cam_id = @cam_id and status > 0 ) and cam_id = @cam_id

	exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

end'
		
	EXEC(@Sql)
	
		set @process = 'tg_ccUsers_Consulta - Alter Trigger'
		set @Sql='ALTER TRIGGER dbo.tg_ccUsers_Consulta ON dbo.ccUsers 
after delete
as begin
set nocount on
insert into ccusers_Consulta (User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoStatusAge_id, Password, 
 TipoUser_id, Status, TipoLLamadas, Sexo, filter, CanChangeStatus, fCreate, DialMask, 
 XferMask, LastPasswordChange, IDArea, NotReadyRestricted, startStopRecording)
select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoStatusAge_id, Password, 
 TipoUser_id, Status, TipoLLamadas, Sexo, filter, CanChangeStatus, fCreate, DialMask, 
 XferMask, LastPasswordChange, IDArea, NotReadyRestricted, startStopRecording
from deleted
set nocount off
end'
	
	EXEC(@Sql)
	
		set @process = 'CW Transfer CallBacks Info - Drop and Create Job'
		set @Sql = 'USE [msdb]

IF EXISTS (select * from sys.objects where object_id = object_id(N''[dbo].[CW Transfer CallBacks Info]'') and OBJECTPROPERTY(object_id, N''IsProcedure'') = 1)
BEGIN
	drop procedure [dbo].[sp_sentry_mail]

	/****** Object:  Job [CW Transfer CallBacks Info]    Script Date: 08/23/2013 15:28:39 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/23/2013 15:28:39 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Transfer CallBacks Info'', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N''CW Transfer CallBacks Info'', 
			@category_name=N''[Uncategorized (Local)]'', 
			@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [Move CallBacks Info]    Script Date: 08/23/2013 15:28:39 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Move CallBacks Info'', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N''TSQL'', 
			@command=N''delete ccocallbacks with(rowlock)
	where status > 0
	and schedulerStatus = 0

	update ccReports.dbo.ccocallbacks with(rowlock)
	set status = a.status, cal_fcallback = a.cal_fcallback
	from ccocallbacks a, ccReports.dbo.ccocallbacks b
	where a.schedulerStatus = 1
	and a. callout_id = b.callout_id

	insert into ccReports.dbo.ccocallbacks
	select *
	from ccocallbacks
	where schedulerStatus = 1
	and callout_id not in (select callout_id from ccReports.dbo.ccocallbacks)

	update ccocallbacks with(rowlock)
	set schedulerStatus = 0
	where schedulerStatus = 1'', 
			@database_name=N''CCenterRia'', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Transfer CallBacks Info'', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=4, 
			@freq_subday_interval=10, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20120820, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
	    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
END'
	
	EXEC(@Sql)
	
	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
