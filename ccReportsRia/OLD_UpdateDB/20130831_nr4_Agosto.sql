/*
Autor: Raymundo Gonzalez
Fecha: 2013/08/31
Descripcion: 
	Se agrega columa isTime a la tabla reportscharts para configurar los reportes con expresiones de tiempo en las graficas
	Se actualiza la tabla reportscharts para configurar los reportes con expresiones de tiempo en las graficas
	Se modifica el SP GetDefaultChart para enviar columna isTime para formato de horas en graficas
	Se modifica el SP GetReportMenus para ocultar menus de chat con base en configuracion
	Se crea la tabla ccRIAChats para reportes de chat
	Se crea la tabla ccRIAChatStatus para reportes de chat
	Se crea la tabla RepACDChats para reportes de chat
	Se crea la tabla RepChatsNotContacted para reportes de chat
	Se crea la tabla RepChatsEffectiveness para reportes de chat
	Se crea la tabla RepChatsDetail para reportes de chat
	Se crea la tabla RepAvgAnswerTimeChats para reportes de chat
	Se crea la tabla RepChatsAndCallsGeneral para reportes de chat
	Se insertan registros en la tabl ccRIAChatStatus para reportes de chat
	Se insertan registros en la tabla ccMenus para reportes de chat
	Se insertan registros en la tabla ReportsCharts para reportes de chat
	Se insertan registros en la tabla ReportsFilters para reportes de chat
	Se insertan registros en la tabla ReportsFiltersMenus para reportes de chat
	Se insertan registros en la tabla pivotReports para reportes de chat
	Se insertan registros en la tabla ReportsTotals para reportes de chat	
	Se modifica el SP ccspRepInDispositions para reportes de chat
	Se modifica el SP ccspRepInSubDispositions para reportes de chat
	Se crea el SP ccspRepAvgAnswerTimeChats para reportes de chat
	Se crea el SP ccspRepACDChats para reportes de chat
	Se crea el SP ccspRepChatsDetail para reportes de chat
	Se crea el SP ccspRepChatsEffectiveness para reportes de chat
	Se crea el SP ccspRepChatsNotContacted para reportes de chat
	Se crea el SP ccspRepChatsAndCallsGeneral para reportes de chat
	Se crea el Job ccspRepChatsDetail para reportes de chat
	Se crea el Job ccspRepACDChats para reportes de chat
	Se crea el Job ccspRepChatsNotContacted para reportes de chat
	Se crea el Job ccspRepChatsEffectiveness para reportes de chat
	Se crea el Job ccspRepAvgAnswerTimeChats para reportes de chat
	Se crea el Job ccspRepChatsAndCallsGeneral para reportes de chat
	Se insertan registros en la tabla migration para reportes de chat
	Se crea el Job CW Reports Migration Chat para reportes de chat
	
	/************************/
	/*** Reportes de AVRS ***/
	/************************/
	Se crea la tabla RepAVRSAgent para reportes de AVRS
	Se crea la tabla RepAVRSDisposition para reportes de AVRS
	Se crea la tabla RepAVRSQuestionDetail para reportes de AVRS
	Se crea la tabla RepAVRSRateDetail para reportes de AVRS
	Se crea la tabla RepAVRSScores para reportes de AVRS
	Se crea la tabla RepAVRSSection para reportes de AVRS
	Se crea la tabla RepAVRSSupervisor para reportes de AVRS
	Se insertan registros en la tabla ccMenus para reportes de AVRS
	Se insertan registros en la tabla ReportsFilters para reportes de AVRS
	Se insertan registros en la tabla ReportsCharts para reportes de AVRS
	Se insertan registros en la tabla ReportsFiltersRange para reportes de AVRS
	Se insertan registros en la tabla ReportsFiltersMenus para reportes de AVRS
	Se modifica el SP ccspRepCatalogos para reportes de AVRS
	Se crea el SP ccspRepAVRSAgent para reportes de AVRS
	Se crea el SP ccspRepAVRSDisposition para reportes de AVRS
	Se crea el SP ccspRepAVRSQuestionDetail para reportes de AVRS
	Se crea el SP ccspRepAVRSRateDetail para reportes de AVRS
	Se crea el SP ccspRepAVRSScores para reportes de AVRS
	Se crea el SP ccspRepAVRSSection para reportes de AVRS
	Se crea el SP ccspRepAVRSSupervisor para reportes de AVRS
	Se crea el Job ccspRepAVRSAgent para reportes de AVRS
	Se crea el Job ccspRepAVRSDisposition para reportes de AVRS
	Se crea el Job ccspRepAVRSQuestionDetail para reportes de AVRS
	Se crea el Job ccspRepAVRSRateDetail para reportes de AVRS
	Se crea el Job ccspRepAVRSScores para reportes de AVRS
	Se crea el Job ccspRepAVRSSection para reportes de AVRS
	Se crea el Job ccspRepAVRSSupervisor para reportes de AVRS
	
	/*************/
	/*** Fixes ***/
	/*************/
	Se modifica el SP ccspRepInEffectiveness para correcion en reporte
	Se insertan registros en la tabla Filters para catalogo de filtros
	Se actualiza registros de la tabla Filters para calificaciones de in y out
	Se actualizan registros de la tabla ReportsFilters para calificaciones de in y out
	Se inserta registro en la tabla ccsettings para tiempo de espera en generacion de reportes
	Se eliminan los horarios para los jobs que generan los reportes
	Se crea el SP ReportsMasterProcess para generar reportes paulatinamente
	Se crea el Job ReportsMasterProcess para generar reportes paulatinamente
	
Version requerida: 3
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '4'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		set @process = 'reportscharts - Alter Table'
		set @Sql = 'alter table reportscharts
add isTime int not null default 0'

	EXEC(@Sql)

		set @process = 'reportscharts - Update Table'
		set @Sql = 'update reportscharts
set isTime = 1
where id in (2010,2020,8010,8020,8030)'

	EXEC(@SQl)
	
		set @process = 'GetDefaultChart - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[GetDefaultChart] @id int 
AS
BEGIN
	select reportName, chartType, case chartType when 1 then x1 ELSE x1 + ''|'' + subX1 end as columns, countColumn, chartDescription, isTime
	from ReportsCharts
	WHERE id = @id
	order by id
END'

	EXEC(@Sql)
	
		set @process = 'GetReportMenus - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint
AS
BEGIN
	Select distinct Nivel, menu_descrip, menu_id,ordengral, 5 as filtersType
	from ccmenus
	where type = 2
	and (menu_id >= 2000) 
	and (menu_id not in (3130,3131,3132,3133,3134,3135,3136)
	or   menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1)
	order by ordengral asc
END'

	EXEC(@Sql)
	
/*********************************/
/*** TABLAS DE NUEVOS REPORTES ***/
/*********************************/

		set @process = 'ccRIAChats - Create Table'
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

		set @process = 'ccRIAChatStatus - Create Table'
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

		set @process = 'RepACDChats - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepACDChats](
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[domain] [varchar] (255) NOT NULL,
[areaId] [int] NOT NULL,
[area] [varchar](255) NOT NULL,
[totalChats] [int] NOT NULL,
[wAbandoned] [int] NOT NULL,
[wConnected] [int] NOT NULL,
[tquemax] [int] NOT NULL,
[tqueavg] [int] NOT NULL,
[nmohin] [int] NOT NULL,
[contacted] [int] NOT NULL,
[uncontacted] [int] NOT NULL,
[SL] [decimal] (10,2) NOT NULL,
[finishedByCostumer] [int] NOT NULL,
[finishedByAgent] [int] NOT NULL,
[finishedBySystem] [int] NOT NULL,
[finishedByAdmin] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL	
)ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepChatsNotContacted - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepChatsNotContacted](
[date] [datetime] NOT NULL,
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[areaId] [int] NOT NULL,
[area] [varchar](255) NOT NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL,
[chatStatusId] [smallint] NOT NULL,	
[chatStatus_count] [varchar](255) NOT NULL,
[count] [smallint] NOT NULL
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'RepChatsEffectiveness - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepChatsEffectiveness](
[date] [datetime] NOT NULL,
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[ntotalChat] [int] NOT NULL,
[nanswerChat] [int] NOT NULL,	
[nabndChat] [int] NOT NULL,
[avgAnswerTime] [decimal](10,2) NOT NULL,
[avgQueueTime] [decimal](10,2) NOT NULL,
[avgAbandonTime] [decimal](10,2) NOT NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL	
) ON [PRIMARY]'
	
	EXEC(@Sql)
	
		set @process = 'RepChatsDetail - Create Table'
		set @Sql='CREATE TABLE RepChatsDetail(
[date] [datetime] NOT NULL,
[inboundId] [smallint] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[chatStatusId] [int] NOT NULL,
[chatStatus] [varchar](255)  NOT NULL,
[dispositionId] [int] NOT NULL,
[disposition] [varchar](255) NOT NULL,
[subDispositionId] [int] NOT NULL,
[subDisposition] [varchar](255) NOT NULL,
[domain] [varchar] (255) NOT NULL,
[userId] [int] NOT NULL,
[user] [varchar] (255) NOT NULL,
[clientName] [varchar] (255) NOT NULL,
[mohTime] [int] NOT NULL,
[xferTime] [int] NOT NULL,
[tChatting] [int] NOT NULL,
[agentName] [varchar] (255) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL	
)ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'RepAvgAnswerTimeChats - Create Table'
		set @Sql='CREATE TABLE [RepAvgAnswerTimeChats](
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](255) NOT NULL,
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[user] [varchar](255) NOT NULL,
[avgAnswerTime] [decimal](10,2) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
)'
				
	EXEC(@Sql)
	
		set @process = 'RepChatsAndCallsGeneral - Create Table'
		set @Sql='create table RepChatsAndCallsGeneral(
[date] [datetime] NOT NULL,
[inboundId] [int] NOT NULL,
[inbound] [varchar](255) NOT NULL,
[totalCalls] [int] NOT NULL,
[totalChats] [int] NOT NULL,
[abndQueueCalls] [int] NOT NULL,
[abndQueueChats] [int] NOT NULL,
[maxTQueueCalls] [int] NOT NULL,
[maxTQueueChats] [int] NOT NULL,
[noAnswerCalls] [int] NOT NULL,
[noAnswerChats] [int] NOT NULL,
[answerCalls] [int] NOT NULL,
[answerChats] [int] NOT NULL,
[serviceLevelCalls] [decimal](10,2) NOT NULL,
[serviceLevelChats] [decimal](10,2) NOT NULL,
[avgTQueueCalls] [int] NOT NULL,
[avgTQueueChats] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL	
)'

	EXEC(@Sql)
	
/***********************************************/	
/*** INSERCIONES A TABLAS DE NUEVOS REPORTES ***/
/***********************************************/	

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

		set @process = 'ccMenus - Insert'
		set @Sql='INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3130, ''Chats'', 3000, ''B'', 3, 2, '''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3131, ''ACD Chats'', 3000, ''C'', 3, 2, '''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3132, ''Chats Not Contacted'', 3000, ''C'', 3, 2, '''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3133, ''Chats Detail'', 3000, ''C'', 3, 2, '''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3134, ''Average Answer Time'', 3000, ''C'', 3, 2, '''')
INSERT [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES (3135, ''Chats Effectiveness'', 3000, ''C'', 3, 2, '''')
insert into ccmenus values (3136, ''General Calls and Chats'', 3000, ''C'', 3, 2, '''')'
		
	EXEC(@Sql)
		
		set @process = 'ReportsCharts - Insert'
		set @Sql='insert into ReportsCharts values (3131, ''ACD Chats'', 1, ''inbound'', '''', '''', '''', ''sum([totalChats])'',''Chats per ACD Group'', 0)
insert into ReportsCharts values (3131, ''ACD Chats'', 2, ''year|month|day'', ''inbound'', '''', '''', ''sum([totalChats])'',''Chats per ACD Group by day'', 0)
insert into ReportsCharts values (3132, ''Chats not contacted'', 1, ''inbound'', '''', '''', '''', ''sum([count])'',''Not contacted chats per ACD Group'', 0)
insert into ReportsCharts values (3132, ''Chats not contacted'', 2, ''year|month|day'', ''inbound'', '''', '''', ''sum([count])'',''Not contacted chats per ACD Group by day'', 0)
insert into ReportsCharts values (3133, ''ACD Chats'', 1, ''inbound'', '''', '''', '''', '''',''Chats detail per ACD Group'', 0)
insert into ReportsCharts values (3133, ''ACD Chats'', 2, ''year|month|day'', ''inbound'', '''', '''', '''',''Chats detail per ACD Group by day'', 0)
insert into ReportsCharts values (3134, ''Average Answer Time'', 1, ''inbound'', '''', '''', '''', ''sum(convert(int,[avgAnswerTime])) / count(*)'',''Chats average answer time per ACD Group'', 1)
insert into ReportsCharts values (3134, ''Average Answer Time'', 2, ''year|month|day|hour'', ''inbound'', '''', '''', ''max(convert(int,[avgAnswerTime]))'',''Chats average answer time per ACD Group by hour'', 1)
insert into ReportsCharts values (3135, ''Chats Effectiveness'', 1, ''inbound'', '''', '''', '''', ''sum([ntotalChat])'',''Chats per ACD Group'', 0)
insert into ReportsCharts values (3135, ''Chats Effectiveness'', 2, ''year|month|day'', ''inbound'', '''', '''', ''sum([ntotalChat])'',''Chats per ACD Group by day'', 0)
insert into ReportsCharts values (3136, ''General Calls and Chats'', 1, ''inbound'', '''', '''', '''', ''sum([totalCalls]+[totalChats])'', ''Calls and chats per ACD Group'', 0)
insert into ReportsCharts values (3136, ''General Calls and Chats'', 2, ''year|month|day'', ''inbound'', '''', '''', ''sum([totalCalls]+[totalChats])'', ''Calls and chats per ACD Group by day'', 0)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFilters - Insert'
		set @Sql='insert into ReportsFilters values(''ACD Chats'', ''acds'', 3131)
insert into ReportsFilters values(''ACD Chats'', ''areas'', 3131)
insert into ReportsFilters values(''Chats not contacted'', ''acds'', 3132)
insert into ReportsFilters values(''Chats not contacted'', ''areas'', 3132)
insert into ReportsFilters values(''Chats detail'', ''acds'', 3133)
insert into ReportsFilters values (''Average Answer Time'', ''acds'', 3134)
insert into ReportsFilters values (''Average Answer Time'', ''users'', 3134)
insert into ReportsFilters values(''Chats Effectiveness'', ''acds'', 3135)
insert into ReportsFilters values (''General Calls and Chats'', ''acds'', 3136)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersMenus - Insert'
		set @Sql='INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3134, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3134, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3133, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3133, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3131, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3131, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3132, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3132, N''filterby'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3135, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (3135, N''filterby'')
insert into ReportsFiltersMenus values (3136, ''date'')
insert into ReportsFiltersMenus values (3136, ''filterby'')'
		
	EXEC(@Sql)
	
		set @process = 'pivotReports - Insert'
		set @Sql='insert into pivotReports values (3132, ''chatStatus_count'', ''date|inboundId|inbound|areaId|area|year|month|day|hour|minutes|chatStatusId'',''max'')'
					
	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Insert'
		set @Sql='insert into ReportsTotals values (3131, ''sum:totalChats|sum:wAbandoned|sum:wConnected|sum:tquemax|avg:tqueavg|sum:nmohin|sum:contacted|sum:uncontacted|sum:SL|sum:finishedByCostumer|sum:finishedByAgent|sum:finishedBySystem|sum:finishedByAdmin'')
insert into ReportsTotals values (3132, ''sum:count'')
insert into ReportsTotals values (3133, ''sum:mohTime|sum:xferTime|sum:tChatting'')
insert into ReportsTotals values (3134, ''avg:avgAnswerTime'')
insert into ReportsTotals values (3135, ''sum:ntotalChat|sum:nanswerChat|sum:nabndChat|avg:avgAnswerTime|avg:avgQueueTime|avg:avgAbandonTime'')
insert into ReportsTotals values (3136,	''sum:totalCalls|sum:totalChats|sum:abndQueueCalls|sum:abndQueueChats|sum:maxTQueueCalls|sum:maxTQueueChats|sum:noAnswerCalls|sum:noAnswerChats|sum:answerCalls|sum:answerChats|avg:serviceLevelCalls|avg:serviceLevelChats|avg:avgTQueueCalls|avg:avgTQueueChats'')'
	
	EXEC(@Sql)

/********************************************************/	
/*** MODIFICACIONES A STORED PROCEDURES PARA REPORTES ***/
/********************************************************/

		set @process = 'ccspRepInDispositions - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepInDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions where date >= @from AND date < @to
	
	insert into RepInDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, dispositionId, '''' as DispName,'''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''Workgroup1'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
		FROM (
			SELECT 
				a.cal_inicio as dateHour, a.Inbound_id, a.calif_id as dispositionId, user_id, b.IDArea
				from cccallsin a 		
				left join ccInbound b
				on	b.Inbound_id = a.Inbound_id		
				where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13	--Constestada
				and b.IDArea is not null
			UNION 
			SELECT 		
				requestDate,a.inboundId, a.disposition, a.userId, b.IDArea
				FROM ccRIAChats a
				left join ccInbound b
				on	b.Inbound_id = a.inboundId
				where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
				and b.IDArea is not null		
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, dispositionId, user_id, IDArea
	
	update a set acdGroup = isnull(descripcion,'''')
	from RepInDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''Dispositionless''), disposition_count = isnull(description,''Dispositionless'') + ''_Count''
	from RepInDispositions a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
			
	EXEC(@Sql)

		set @process = 'ccspRepInSubDispositions - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepInSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions where date >= @from AND date < @to

	insert into RepInSubDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, subDispositionId, '''' as DispName, '''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''Workgroup1'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
	 FROM 
	(
		select 
		cal_inicio as dateHour, a.Inbound_id,isnull(a.califSub_id,0) as subDispositionId, calif_id as dispositionId, user_id, b.IDArea
		from cccallsin a 		
		left join ccInbound b
		on	b.Inbound_id = a.Inbound_id		
		where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
		and b.IDArea is not null
		UNION 
		SELECT 		
			requestDate,a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
			FROM ccRIAChats a
			left join ccInbound b
			on	b.Inbound_id = a.inboundId
			where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
			and b.IDArea is not null
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, subDispositionId, user_id, IDArea

	update a set acdGroup = isnull(descripcion,'''')
	from RepInSubDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''Dispositionless''), subDisposition_count = isnull(califSubDesc,''Dispositionless'') + ''_Count''
	from RepInSubDispositions a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
			
	EXEC(@Sql)
	
/***************************************************/	
/*** CREACION DE STORED PROCEDURES PARA REPORTES ***/
/***************************************************/	

		set @process = 'ccspRepAvgAnswerTimeChats - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepAvgAnswerTimeChats where date >= @from and date < @to

		insert into RepAvgAnswerTimeChats
		select CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121) as [date], userId, [Login], inboundId, [inbound],
		[user], convert(decimal(10,2),(convert(decimal(10,2),sum([answerTime])) / convert(decimal(10,2),count(*)))) as [avgAnswerTime]
		, datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		from(
		select requestDate as [date], userId, [Login] as [login], 
		inboundId, c.descripcion as [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno as [user],
		case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
		else datediff(ss,chatdate,firstMessageTime) end as [answerTime]
		from ccriachats a
		left join ccusers b on (a.userId = b.user_id)
		left join ccinbound c on (a.inboundId = c.inbound_id)
		where b.user_id is not null
		and c.inbound_id is not null
		and a.chatstatus = 4) as answerTime
		group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121), userId, [Login], inboundId, [inbound], [user]

	end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepACDChats - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepACDChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
	
		delete from RepACDChats where date >= @from AND date < @to
		
		insert into RepACDChats
			select fecha,
			inboundId, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName,
			max([totalChats]),
			sum([waitingAbandoned]),
			sum([waitingConnected]),
			max(maxTQueue),
			max(avgTQueue),
			sum([onQueue]),
			sum([Connected]),
			sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]),
			0.00 as levelService,
			sum([byCostumer]) as finishedByCostumer,
			sum([byAgent]) as finishedByAgent,
			sum([bySystem]) as finishedBySystem,
			sum([byAdmin]) as finishedByAdmin,
			datepart(yyyy,CONVERT(varchar(20), fecha, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), fecha, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), fecha, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), fecha, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), fecha, 120)) as [minutes]
			from(

				select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
				count(*) as [totalChats],
				domain,
				ISNULL(count(CASE WHEN (chatstatus = 9) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
				ISNULL(count(CASE WHEN (chatstatus = 4) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingConnected],
				ISNULL(count(CASE WHEN (chatstatus = 4) THEN 1 ELSE NULL END),0)AS [Connected],
				ISNULL(count(CASE WHEN onQueue = 1 THEN 1 ELSE NULL END),0)AS [onQueue],
				ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
				ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
				ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
				ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
				ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
				ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
				ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
				ISNULL(count(CASE WHEN(finishedBy = 0)THEN 1 ELSE NULL END),0) AS [byCostumer],
				ISNULL(count(CASE WHEN(finishedBy = 1)THEN 1 ELSE NULL END),0) AS [byAgent],
				ISNULL(count(CASE WHEN(finishedBy = 2)THEN 1 ELSE NULL END),0) AS [bySystem],
				ISNULL(count(CASE WHEN(finishedBy = 3)THEN 1 ELSE NULL END),0) AS [byAdmin],
				max(tqueue) as maxTQueue,
				avg(tqueue) as avgTQueue
				from ccRIAChats a
				where
				chatStatus in (2,5,4,7,9,10,11)
				group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
				
			) as ChatDetail
			left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
			left join ccRIACat_Areas c on (c.IDArea = b.IDArea)
			where fecha >= @from and fecha < @to
			group by inboundId, fecha, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName
			
			declare @DTChat as int
			select @DTChat = valor from ccsettings where setting_id = 134
			
			select inboundId, descripcion, date,
			isnull(convert(decimal(10,2),convert(float,[Connected]) / NULLIF(convert(float, Total) * 100.00,0)),0) as NS
			into #tmpns
			from
			(select inboundId, descripcion, Date,
			sum([Connected>DT]) as [Connected], 
			sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
			sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
			from (
			select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date,
			ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
			ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
			ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
			from ccRIAChats a
			left outer join ccInbound c on (inboundId = inbound_id)
			where chatStatus in (3,4,7,9,10,11)
			and chatDate is not null
			group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
			group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid
			
			update RepACDChats set SL = b.NS 
			from RepACDChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId
			drop table #tmpns
	end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsDetail - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepChatsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		
		delete from RepChatsDetail where date >= @from AND date < @to
	
		insert into RepChatsDetail
			select requestDate,
			inboundId, b.descripcion, chatstatus, c.description, disposition, isnull(d.description,''''),
			subDisposition, isnull(califSubDesc,''''), domain, userid, isnull(f.login,''''), clientName, tqueue,
			0 as txfer, tchatting, 
			isnull(nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as Nombre,
			datepart(yyyy,CONVERT(varchar(20), requestDate, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), requestDate, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), requestDate, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), requestDate, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), requestDate, 120)) as [minutes]
			from ccRIAChats
			left join ccInbound b on (inboundId = inbound_id)
			left join ccRIAChatStatus c on (chatstatus = id)
			left join ccTipoCalif d on (calif_id = disposition)
			left join ccTipoCalifSub e on (califSub_id = subDisposition)
			left join ccusers f on (User_id = userid)
			where requestDate >= @from and requestDate < @to
			
			select isnull(datediff(ss,requestDate,chatdate) - tqueue,0) as xferTime, requestDate as date
			into #tmpxferTime
			from ccRIAChats where chatstatus = 4
			
			update RepChatsDetail set xferTime = b.xferTime
			from RepChatsDetail a, #tmpxferTime b where a.date = b.date 
			
			drop table #tmpxferTime 
	end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsEffectiveness - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepChatsEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsEffectiveness where date >= @from AND date < @to
	insert into RepChatsEffectiveness
	select 
		a.date, a.inboundId, d.descripcion as [inbound]
		,a.ntotalChat, isnull(b.nanswer,0) as nanswerChat, isnull(c.nabnd,0) as nabnd
		, convert(decimal(10,2),isnull(convert(decimal(10,0),b.nAnswerTime)/convert(decimal(10,0),nAnswer),0)) as [avgAnswerTime]	
		, convert(decimal(10,2),isnull(convert(decimal(10,0),b.tSumQueue)/convert(decimal(10,0),nAnswer),0)) as [avgQueueTime]	
		, convert(decimal(10,2),isnull(convert(decimal(10,0),c.tSumAbandon)/convert(decimal(10,0),c.nabnd),0)) as [avgAbandonTime]
		, datepart(yyyy,a.date) as [year], datepart(mm,a.date) as [mount]
		, datepart(dd,a.date) as [day], datepart(hh,a.date) as [hh], datepart(mi,a.date) as [minutes]
	FROM(
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121) as [date],
			a.inboundId , count(*) as ntotalChat
			FROM ccRIaChats a		
			where requestDate >= @from AND requestDate < @to
			group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121), a.inboundId	
		) as a	
		LEFT JOIN
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as date,
			inboundId , count(*) as nAnswer
			,sum(case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
				else datediff(ss,chatdate,firstMessageTime) end ) as [nAnswerTime]
			,sum(tQueue) as tSumQueue
			FROM ccRIaChats
			where chatStatus = 4 AND requestDate >= @from AND requestDate < @to -- Contestados
			group by CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), inboundId	
		)as b
		ON a.date =  b.date AND a.inboundId = b.inboundId
		LEFT JOIN 
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as date,
			inboundId , count(*) as nabnd, sum(tQueue) as tSumAbandon
			FROM ccRIaChats
			where chatStatus = 9 AND requestDate >= @from AND requestDate < @to -- abandonadas		
			group by CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), inboundId	
		)as c
		ON a.date = c.date AND a.inboundId = c.inboundId	
		INNER JOIN ccinbound d on (a.inboundId = d.inbound_id)
	)
	
end'
				
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsNotContacted - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepChatsNotContacted]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsNotContacted where date >= @from AND date < @to
	insert INTO RepChatsNotContacted
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121) as date,
		inboundId,MAX(b.descripcion) as Inbound, MAX(b.IDArea) as areaID, MAX(c.AreaName) as area,
		DATEPART(yyyy,MAX(requestDate)) as [year], DATEPART(mm,MAX(requestDate)) as [mounth], DATEPART(dd,MAX(requestDate)) as [day],
		DATEPART(hh,MAX(requestDate)) as [hour], 0 as minutes,
		a.chatStatus as chatStatus,MIN(d.description)+''_Count'' as descriptionCount, COUNT(a.chatStatus) as [count]
		FROM ccRIaChats a
		INNER JOIN ccInbound b ON a.inboundId = b.Inbound_id
		INNER JOIN ccRIACat_Areas c ON c.IDArea = b.IDArea 
		INNER JOIN ccRIAChatStatus d ON d.id = a.chatStatus
		where a.chatStatus IN(10,11,6,5,7) AND a.requestDate >= @from AND a.requestDate < @to
		group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121), a.inboundId, b.IDArea, a.chatStatus 
end'
					
	EXEC(@Sql)

		set @process = 'ccspRepChatsAndCallsGeneral - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccspRepChatsAndCallsGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
	begin
		CREATE TABLE [dbo].[#callsin](
			[timegroup] [smalldatetime] NOT NULL,
			[inbound_id] [smallint] NOT NULL,
			[dni_id] [smallint] NOT NULL,
			[user_id] [smallint] NOT NULL,
			[ntotal] [smallint] NOT NULL,
			[ninitial] [smallint] NOT NULL,
			[nout_hour] [smallint] NOT NULL,
			[nout_service] [smallint] NOT NULL,
			[nabnd] [smallint] NOT NULL,
			[nno_agent] [smallint] NOT NULL,
			[nque] [smallint] NOT NULL,
			[ntimeout] [smallint] NOT NULL,
			[noverflow] [smallint] NOT NULL,
			[nxfer] [smallint] NOT NULL,
			[nxfer_que] [smallint] NOT NULL,
			[nabnd_xfer] [smallint] NOT NULL,
			[nabnd_ring] [smallint] NOT NULL,
			[nno_answer] [smallint] NOT NULL,
			[nabnd_dialog] [smallint] NOT NULL,
			[nanswer] [smallint] NOT NULL,
			[nlost] [smallint] NOT NULL,
			[nmsg] [smallint] NOT NULL,
			[nabnd_tres] [smallint] NOT NULL,
			[nansw_tres] [smallint] NOT NULL,
			[tque_max] [smallint] NOT NULL,
			[tque] [int] NOT NULL,
			[txfer] [int] NOT NULL,
			[tdialog] [int] NOT NULL,
			[tnotes] [int] NOT NULL,
			[tring] [int] NOT NULL,
			[tresp] [int] NOT NULL,
			[nMoh] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nMoh]  DEFAULT ((0)),
			[nWHag] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHag]  DEFAULT ((0)),
			[nWHcl] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHcl]  DEFAULT ((0)),
		) ON [PRIMARY]

		INSERT INTO #callsin(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
		,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
		,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
		SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
		,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
		,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
		FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
			,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
			,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
			,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
			,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
			,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
			,COUNT(cal_id)AS ntotal
			,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
			,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
			,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
			,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
			,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
			,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
			,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
			,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
			,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
			,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
			,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
			,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
			,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
			,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
			,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
			,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
			,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
			,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
		right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
		FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,*
		FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
		UNION
		SELECT timegroup_next,inbound_id,dni_id,[user_id]
			,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
			,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
			,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
			,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
			,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
		FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
			,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
			,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
			,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
			,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
			,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
		GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
		ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
		WHERE timegroup>=@from AND timegroup<@to
		AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
		ORDER BY timegroup,inbound_id,dni_id,[user_id]

		SELECT CONVERT(varchar(20), timegroup, 120) as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
		ntotal, nabnd_que, tque_max, nnoanswer, nanswer, SL, avgTQueue
		into #partialCalls
		FROM (SELECT xDetCall.tg as timegroup , xDetCall.inbound_id  as inbound_id,
			ISNULL(ntotal, 0) ntotal, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(tque_max, 0) tque_max , 
			ISNULL(tque, 0) tque, ISNULL(nanswer, 0) nanswer , ISNULL(tque/ NULLIF(nque, 0), 0) avgTQueue, 
			convert(decimal(10,2),ISNULL(SL_P_1 * 100 / NULLIF(ntotal,0), 0)) SL, ninitial + [nout_hour] + nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost as nnoanswer,
			SL_P_1, SL_P_2
			FROM (SELECT timegroup as tg, inbound_id, SUM(ntotal) ntotal , SUM(nabnd) nabnd_que , 
				MAX(tque_max) tque_max, NULLIF(SUM(nque), 0) nque,
				SUM(tque) tque, SUM(nanswer) nanswer, SUM(nanswer) AS SL_P_1 , 
				SUM(ninitial + [nout_hour] +  nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, 
				SUM(nabnd) nabnd, SUM(nno_agent) nno_agent, SUM(ntimeout) ntimeout, SUM(noverflow) noverflow, 
				SUM(nno_answer) nno_answer, SUM(nlost) nlost, sum([nout_hour]) [nout_hour], sum(nabnd_xfer) nabnd_xfer,
				SUM(nabnd_ring) nabnd_ring, SUM(nabnd_dialog) nabnd_dialog, SUM(ninitial) ninitial
				FROM #callsin  
				WHERE timegroup >= @from 
				AND timegroup < @to
				GROUP BY  timegroup, inbound_id) xDetCall) xDetail  
		INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
		where ccInbound.inbound_id is not null
		order by descripcion, CONVERT(varchar(20), timegroup, 120)

		select fecha as date,
		inboundId, b.descripcion,
		max([totalChats]) as [totalChats],
		sum([waitingAbandoned]) as [waitingAbandoned],
		max(maxTQueue) as maxTQueue,
		sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as [notConnected],
		sum([Connected]) as [Connected],
		convert(decimal(10,2),''0.00'') as SL,
		max(avgTQueue) as avgTQueue
		into #partialChats
		from(

			select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
			count(*) as [totalChats],
			domain,
			ISNULL(count(CASE WHEN (chatstatus = 9) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
			ISNULL(count(CASE WHEN (chatstatus = 4) THEN 1 ELSE NULL END),0)AS [Connected],
			ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
			ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
			ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
			max(tqueue) as maxTQueue,
			avg(tqueue) as avgTQueue
			from ccRIAChats a
			where
			chatStatus in (2,5,4,7,9,10,11)
			group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
			
		) as ChatDetail
		left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
		where fecha >= @from and fecha < @to
		group by inboundId, fecha, b.descripcion

		declare @DTChat as int
		select @DTChat = valor from ccsettings where setting_id = 134

		select inboundId, descripcion, date,
		isnull(convert(decimal(10,2),convert(float,[Connected]) / NULLIF(convert(float, Total) * 100.00,0)),0) as NS
		into #tmpns
		from
		(select inboundId, descripcion, Date,
		sum([Connected>DT]) as [Connected], 
		sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
		sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
		from (
		select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date,
		ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
		ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
		ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
		ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
		ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
		ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
		ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
		from ccRIAChats a
		left outer join ccInbound c on (inboundId = inbound_id)
		where chatStatus in (3,4,7,9,10,11)
		and chatDate is not null
		group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
		group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid

		update #partialChats set SL = b.NS 
		from #partialChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId

		delete RepChatsAndCallsGeneral where date >= @from and date <= @to

		insert into RepChatsAndCallsGeneral
		select convert(datetime,isnull(a.date, b.date)) as date, isnull(a.inboundId,b.inboundId) as inboundId, 
		isnull(a.inbound,b.descripcion) as descripcion,
		isnull(ntotal,0) as ntotal, isnull(totalChats,0) as totalChats, isnull(nabnd_que,0) as nabnd_que, 
		isnull(waitingAbandoned,0) as waitingAbandoned, isnull(tque_max,0) as tque_max, 
		isnull(maxTQueue,0) as maxTQueue, isnull(nnoanswer,0) as nnoanswer, isnull(notConnected,0) as notConnected,
		isnull(nanswer,0) as nanswer, isnull(Connected,0) as Connected, isnull(a.SL,0) as SL1, isnull(b.SL,0) as SL2, 
		isnull(a.avgTQueue,0) as avgTQueue1, isnull(b.avgTQueue,0) as avgTQueue2,
		datepart(yyyy,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [year],
		datepart(mm,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [month],
		datepart(dd,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [day],
		datepart(hh,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [minutes]
		from #partialCalls a
		full join #partialChats b on (a.date = b.date and a.inboundId = b.inboundId)

		drop table #tmpns
		drop table #partialChats
		drop table #partialCalls
		drop table #callsin
	end'
	
	EXEC(@Sql)

/**********************************************/
/*** JOBS PARA LA NUEVA VERSION DE REPORTES ***/
/**********************************************/

		set @process = 'ccspRepChatsDetail - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepChatsDetail]    Script Date: 05/20/2013 12:34:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/20/2013 12:34:00 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepChatsDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 05/20/2013 12:34:01 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepChatsDetail] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130520, 
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
EndSave:'

	EXEC(@Sql)
	
		set @process = 'ccspRepACDChats - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepACDChats]    Script Date: 05/14/2013 14:06:57 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/14/2013 14:06:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepACDChats'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 05/14/2013 14:06:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepACDChats] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130514, 
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
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsNotContacted - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepChatsNotContacted] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepChatsNotContacted'',
	@enabled=1,
	@notify_level_eventlog=0,
	@notify_level_email=0,
	@notify_level_netsend=0,
	@notify_level_page=0,
	@delete_level=0,
	@description=N''No description available.'',
	@category_name=N''[Uncategorized (Local)]'',
	@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
	@step_id=1,
	@cmdexec_success_code=0,
	@on_success_action=1,
	@on_success_step_id=0,
	@on_fail_action=2,
	@on_fail_step_id=0,
	@retry_attempts=0,
	@retry_interval=0,
	@os_run_priority=0, @subsystem=N''TSQL'',
	@command=N''EXEC [ccspRepChatsNotContacted] 1'',
	@database_name=N''ccReportsRia'',
	@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
	@enabled=1,
	@freq_type=4,
	@freq_interval=1,
	@freq_subday_type=4,
	@freq_subday_interval=10,
	@freq_relative_interval=0,
	@freq_recurrence_factor=0,
	@active_start_date=20120910,
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
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsEffectiveness - Create Job'
		set @Sql='USE [msdb]

/****** Object: Job [ccspRepChatsEffectiveness] Script Date: 09/10/2012 10:39:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object: JobCategory [[Uncategorized (Local)]]] Script Date: 09/10/2012 10:39:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''ccspRepChatsEffectiveness'',
	@enabled=1,
	@notify_level_eventlog=0,
	@notify_level_email=0,
	@notify_level_netsend=0,
	@notify_level_page=0,
	@delete_level=0,
	@description=N''No description available.'',
	@category_name=N''[Uncategorized (Local)]'',
	@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object: Step [LoadInformationReport] Script Date: 09/10/2012 10:39:15 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'',
	@step_id=1,
	@cmdexec_success_code=0,
	@on_success_action=1,
	@on_success_step_id=0,
	@on_fail_action=2,
	@on_fail_step_id=0,
	@retry_attempts=0,
	@retry_interval=0,
	@os_run_priority=0, @subsystem=N''TSQL'',
	@command=N''EXEC [ccspRepChatsEffectiveness] 1'',
	@database_name=N''ccReportsRia'',
	@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'',
	@enabled=1,
	@freq_type=4,
	@freq_interval=1,
	@freq_subday_type=4,
	@freq_subday_interval=10,
	@freq_relative_interval=0,
	@freq_recurrence_factor=0,
	@active_start_date=20120910,
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
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepAvgAnswerTimeChats - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ccspRepAvgAnswerTimeChats]    Script Date: 05/15/2013 15:41:32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/15/2013 15:41:32 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAvgAnswerTimeChats'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepAvgAnswerTimeChats'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 05/15/2013 15:41:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepAvgAnswerTimeChats] 1
'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadInformationReport'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130515, 
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
EndSave:'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepChatsAndCallsGeneral - Create Job'
		set @Sql='USE [msdb]
/****** Object:  Job [ccspRepChatsAndCallsGeneral]    Script Date: 06/10/2013 16:23:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/10/2013 16:23:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepChatsAndCallsGeneral'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepChatsAndCallsGeneral'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadReportInformation]    Script Date: 06/10/2013 16:23:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadReportInformation'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepChatsAndCallsGeneral] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''LoadReportInformation'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130610, 
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
EndSave:'
	
	EXEC(@Sql)

		set @process = 'migration - Insert'
		set @Sql='use [ccReportsRia]
insert into migration values (34 , ''SnapShots Completed Chat'', 0, '''', '''', '''')
insert into migration values (35 , ''ccspRepInDispositions'', 0, '''', '''', '''')
insert into migration values (36 , ''ccspRepInSubDispositions'', 0, '''', '''', '''')
insert into migration values (37 , ''ccspRepAvgAnswerTimeChats'', 0, '''', '''', '''')
insert into migration values (38 , ''ccspRepACDChats'', 0, '''', '''', '''')
insert into migration values (39 , ''ccspRepChatsDetail'', 0, '''', '''', '''')
insert into migration values (40 , ''ccspRepChatsEffectiveness'', 0, '''', '''', '''')
insert into migration values (41 , ''ccspRepChatsNotContacted'', 0, '''', '''', '''')
insert into migration values (42 , ''ccspRepChatsAndCallsGeneral'', 0, '''', '''', '''')
insert into migration values (43 , ''Migration Completed Chat'', 0, '''', '''', '''')'
	
	EXEC(@Sql)

		set @process = 'CW Reports Migration Chat - Create Job'
		set @sql = 'USE [msdb]
/****** Object:  Job [CW Reports Migration Chat]    Script Date: 06/20/2013 10:28:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/20/2013 10:28:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Reports Migration Chat'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [migration]    Script Date: 06/20/2013 10:28:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Reports Migration Chat'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''
if (select [status] from migration where id = 33) = 1 and (select [status] from migration where id = 43) = 0
begin
	if (select count(distinct publication)	
	from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b 	
	where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''') = 18
	begin
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate(), [dateEnd] = getdate() where id = 34
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id = 43
		
		declare @from as datetime
		declare @day as int 

		select @day = valor from ccReportsRia.dbo.ccSettings where setting_id = 27
		select @from = convert(datetime,convert(varchar(11),getdate() - @day))		
		
		BEGIN TRANSACTION ccspRepOutDialDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 35
			exec ccspRepInDispositions 1, @from  
			COMMIT TRANSACTION ccspRepOutDialDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDialDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 35
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 35 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 36
			exec ccspRepInSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 36
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 36 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentGI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 37
			exec ccspRepAvgAnswerTimeChats 1,  @from
			COMMIT TRANSACTION ccspRepAgentGI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentGI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 37
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 37 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 38
			exec ccspRepACDChats 1,  @from
			COMMIT TRANSACTION ccspRepAgentKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 38
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 38 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReady;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 39
			exec ccspRepChatsDetail 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReady;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReady;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 39
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 39 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReadyDet;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 40
			exec ccspRepChatsEffectiveness 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReadyDet;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReadyDet;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 40
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 40 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentSession;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 41
			exec ccspRepChatsNotContacted 1,  @from
			COMMIT TRANSACTION ccspRepAgentSession;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentSession;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 41
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 41 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInBill01900;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 42
			exec ccspRepChatsAndCallsGeneral 1,  @from
			COMMIT TRANSACTION ccspRepInBill01900;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInBill01900;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 42
		END CATCH
		
		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 42 and [error] = ''''''''
		
		update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id = 43 
	end
end'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''migration'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130620, 
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
EndSave:'
	
	EXEC(@Sql)
	
/************************/
/*** Reportes de AVRS ***/
/************************/

		set @process = 'RepAVRSAgent - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSAgent](
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[agentName] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[Dispositions] [int] NOT NULL,
[avgDisposition] [float] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAVRSDisposition - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSDisposition](
[date] [datetime] NULL,
[id_formato] [int] NULL,
[Template] [varchar](50) COLLATE Modern_Spanish_CI_AS NULL,
[userId] [int] NULL,
[agentName] [varchar](50) COLLATE Modern_Spanish_CI_AS NULL,
[grabId] [int] NULL,
[Disposition] [int] NULL,
[year] [int] NULL,
[month] [int] NULL,
[day] [int] NULL,
[hour] [int] NULL,
[minutes] [int] NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAVRSQuestionDetail - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSQuestionDetail](
[date] [datetime] NOT NULL,
[grabId] [int] NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[agentName] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[Supervisor] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[templateId] [int] NOT NULL,
[Template] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[sectionId] [int] NOT NULL,
[Section] [varchar](100) COLLATE Modern_Spanish_CI_AS NOT NULL,
[questionId] [int] NOT NULL,
[question] [varchar](100) COLLATE Modern_Spanish_CI_AS NOT NULL,
[answer] [varchar](max) COLLATE Modern_Spanish_CI_AS NOT NULL,
[Disposition] [int] NOT NULL,
[recordDate] [datetime] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAVRSRateDetail - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSRateDetail](
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](50) NOT NULL,
[agentName] [varchar](50) NOT NULL,
[Supervisor] [varchar](50) NOT NULL,
[grabId] [int] NOT NULL,
[templateId] [int] NOT NULL,
[Template] [varchar](50) NOT NULL,
[Disposition] [int] NOT NULL,
[recordDate] [datetime] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAVRSScores - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSScores](
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[agentName] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[disposition] [int] NOT NULL,
[avgDisposition] [float] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAVRSSection - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSSection](
[date] [datetime] NOT NULL,
[userId] [int] NOT NULL,
[login] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[agentName] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[templateId] [int] NOT NULL,
[Template] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[sectionId] [int] NOT NULL,
[Section] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[score] [int] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'RepAVRSSupervisor - Create Table (AVRS)'
		set @Sql = 'CREATE TABLE [dbo].[RepAVRSSupervisor](
[date] [datetime] NOT NULL,
[supervisorId] [int] NOT NULL,
[login] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[agentName] [varchar](50) COLLATE Modern_Spanish_CI_AS NOT NULL,
[Dispositions] [int] NOT NULL,
[avgDisposition] [float] NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccMenus - Insert (AVRS)'
		set @Sql = 'INSERT INTO ccMenus
VALUES (8050,''AVRS'',8000,''A'',8,2,'''')

INSERT INTO ccMenus
VALUES (8060,''Quality'',8000,''B'',8,2,'''')

INSERT INTO ccMenus
VALUES (8061,''Agent'',8000,''C'',8,2,'''')

INSERT INTO ccMenus
VALUES (8062,''Supervisor'',8000,''C'',8,2,'''')

INSERT INTO ccMenus
VALUES (8063,''Section'',8000,''C'',8,2,'''')

INSERT INTO ccMenus
VALUES (8070,''Detail'',8000,''B'',8,2,'''')

INSERT INTO ccMenus
VALUES (8071,''Question Detail'',8000,''C'',8,2,'''')

INSERT INTO ccMenus
VALUES (8072,''Rate Detail'',8000,''C'',8,2,'''')

INSERT INTO ccMenus
VALUES (8080,''Disposition'',8000,''B'',8,2,'''')'
		
	EXEC(@Sql)

		set @process = 'Filters - Insert (AVRS)'
		set @Sql = 'INSERT INTO Filters
VALUES (15,''templateSection'',15,''TemplateSection'',''TemplateSection'')

INSERT INTO Filters
VALUES (16,''template'',16,''Template'',''Template'')

INSERT INTO Filters
VALUES (17,''supervisors'',17,''Supervisors'',''Supervisors'')

INSERT INTO Filters
VALUES (18,''Disposition'',18,''Disposition'',''Disposition'')

INSERT INTO Filters
VALUES (19,''avgDisposition'',19,''Avg'',''Avg'')

INSERT INTO Filters
VALUES (20,''score'',20,''score'',''score'')'

	EXEC(@Sql)
	
		set @process = 'ReportsFilters - Insert (AVRS)'
		set @Sql = 'INSERT INTO [ReportsFilters]
VALUES (''Agent'',''users'',8061)

INSERT INTO [ReportsFilters]
VALUES (''Supervisor'',''supervisors'',8062)

INSERT INTO [ReportsFilters]
VALUES (''Section'',''users'',8063)

INSERT INTO [ReportsFilters]
VALUES (''Section'',''template'',8063)

INSERT INTO [ReportsFilters]
VALUES (''Section'',''templateSection'',8063)

INSERT INTO [ReportsFilters]
VALUES (''Question Detail'',''users'',8071)

INSERT INTO [ReportsFilters]
VALUES (''Question Detail'',''template'',8071)

INSERT INTO [ReportsFilters]
VALUES (''Question Detail'',''templateSection'',8071)

INSERT INTO [ReportsFilters]
VALUES (''Rate Detail'',''users'',8072)

INSERT INTO [ReportsFilters]
VALUES (''Rate Detail'',''template'',8072)

INSERT INTO [ReportsFilters]
VALUES (''Disposition'',''users'',8080)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsCharts - Insert (AVRS)'
		set @Sql = 'INSERT INTO [ReportsCharts]
VALUES (8061,''Agent'',1,''agentName'','''','''','''',''sum(Dispositions)'',''Total dispositions per Agent by date range'', 0)

INSERT INTO [ReportsCharts]
VALUES (8061,''Agent'',2,''year|month|day|agentName|Dispositions'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Total dispositions per Agent by date range'', 0)

INSERT INTO [ReportsCharts]
VALUES (8062,''Supervisor'',1,''agentName'','''','''','''',''sum(Dispositions)'',''Total dispositions per Supervisor by date range'', 0)

INSERT INTO [ReportsCharts]
VALUES (8062,''Supervisor'',2,''year|month|day|agentName|Dispositions'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Average dispositions'', 0)

INSERT INTO [ReportsCharts]
VALUES (8080,''Disposition'',1,''agentName'','''','''','''',''count(agentName)'',''Total dispositions per Agent by date range'', 0)

INSERT INTO [ReportsCharts]
VALUES (8080,''Disposition'',2,''year|month|day|agentName|Template'',''Disposition'','''','''',''avg(Disposition)'',''Average dispositions'', 0)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersRange - Insert (AVRS)'
		set @Sql = 'INSERT INTO [ReportsFiltersRange]
VALUES (''Agent'',''avgDisposition'',8061)

INSERT INTO [ReportsFiltersRange]
VALUES (''Supervisors'',''avgDisposition'',8062)

INSERT INTO [ReportsFiltersRange]
VALUES (''Section'',''score'',8063)

INSERT INTO [ReportsFiltersRange]
VALUES (''Question Detail'',''Disposition'',8071)

INSERT INTO [ReportsFiltersRange]
VALUES (''Rate Detail'',''Disposition'',8072)

INSERT INTO [ReportsFiltersRange]
VALUES (''Disposition'',''Disposition'',8080)'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersMenus - Insert (AVRS)'
		set @Sql = 'INSERT INTO [ReportsFiltersMenus]
VALUES (8061,''date'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8061,''filterby'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8061,''range'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8062,''date'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8062,''filterby'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8062,''range'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8063,''date'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8063,''filterby'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8063,''range'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8071,''date'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8071,''filterby'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8071,''range'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8072,''date'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8072,''filterby'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8072,''range'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8080,''date'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8080,''filterby'')

INSERT INTO [ReportsFiltersMenus]
VALUES (8080,''range'')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Insert (AVRS)'
		set @Sql = 'INSERT INTO [ReportsTotals]
VALUES (8061,''count:agentName|avg:avgDisposition'')

INSERT INTO [ReportsTotals]
VALUES (8062,''count:agentName|avg:avgDisposition'')

INSERT INTO [ReportsTotals]
VALUES (8063,''count:agentName|sum:score'')

INSERT INTO [ReportsTotals]
VALUES (8071,''count:agentName|sum:Disposition'')

INSERT INTO [ReportsTotals]
VALUES (8072,''count:agentName|avg:Disposition'')

INSERT INTO [ReportsTotals]
VALUES (8080,''count:agentName|avg:Disposition'')'
		
	EXEC(@Sql)

		set @process = 'ccspRepCatalogos - Alter Procedure (AVRS)'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range 

AS
if @action = 0 
begin
	-- CAMPAIGNS
	if @type = 1 
	begin
		SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn 
		FROM ccCamps 
		GROUP BY cam_id, cam_descripcion
		ORDER BY cam_descripcion
	end

	-- DIAL RESULTS
	if @type = 2
	begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn 
		from ccTipoResultadoDial 
		order by descripcion
	end

	-- WORKGROUPS
	if @type = 3
	begin
		select idwg as id, wgname as description, ''workgroupId'' as dbColumn 
		from ccRIACat_WorkGroup 
		group by idwg, wgname
		order by wgname
	end

	-- AREAS
	if @type = 4
	begin
		select idArea as id, AreaName as description, ''areaId'' as dbColumn 
		from ccRIACat_Areas
		group by idArea, AreaName
		order by AreaName
	end

	-- DISPOSITIONS OUT
	if @type = 5
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn 
		FROM ccTipoCalifOut 
		order by [description]
	end

	-- USERS
	if @type = 6
	begin
		SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn 
		FROM ccUsers 
		WHERE [status] = 1 
		and TipoUser_id = 1		
		ORDER BY [login]
	end

	-- ACDS
	if @type = 7
	begin
		select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
		from ccinbound 
		GROUP BY inbound_id, descripcion
		ORDER BY descripcion
	end

	-- DIDS
	if @type = 8
	begin
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis	
		
	end

	--DISPOSITIONS IN
	if @type = 9
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn 
		FROM ccTipoCalif 
		order by [description]
	end

	--SUBDISPOSITIONS IN
	if @type = 10
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn 
		FROM ccTipoCalifSub 
		order by [description]
	end

	--PROVIDER
	if @type = 11
	begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

	-- UNAVAILABLES
	if @type = 12
	begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn 
		FROM cctiponotready 
		order by descripcion
	end

	-- DIALERS
	if @type = 13
	begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn 
		FROM ccoDialers 
		order by descripcion
	end

	-- CallTYpes
	if @type = 14
	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn 
			FROM ccStatusLlamada
		order by descripcion
	end
	
	-- SUBDISPOSITIONS OUT
	if @type = 21
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn 
		FROM cctipocalifsubout 
		order by [description]
	end

	-- AVRS TEMPLATE-SECTION
	if @type = 15
	begin
		SELECT c.id_concepto as id, (t.nombre+''-''+c.con_descripcion) as description, ''sectionId'' as dbColumn 
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,nombre,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato,nombre) as t
		ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN RIA_CONCEPTOS c
		ON t.id_formato = c.id_formato AND t.version = c.version
		order by f.nombre
	end

	-- AVRS TEMPLATES
	if @type = 16
	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn 
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end
	
	-- AVRS SUPERVISOR
	if @type = 17
	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn 
		FROM ccUsers 
		WHERE [status] = 1 
		and TipoUser_id = 2		
		ORDER BY [login]
	end
end

if @action = 1 
begin
	-- TRUNKS
	if @type = 13
	begin
		SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
	end
	
	-- AVRS DISPOSITION
	if @type = 18
	begin
		SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
	end

	-- AVG DISPOSITION
	if @type = 19
	begin
		SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
	end

	-- SCORE
	if @type = 20
	begin
		SELECT 0 as [min], 100 as [max],''score'' as dbColumn
	end
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSAgent - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSAgent]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent
	
	INSERT INTO dbo.RepAVRSAgent
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		   YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
											 FROM dbo.RIA_FORMATOS
											 WHERE activo = 1
											 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)	
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSDisposition - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSDisposition]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSDisposition 

	INSERT INTO dbo.RepAVRSDisposition 
	SELECT f.fecha_calif,t.id_formato,t.nombre,u.User_id,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agente,f.id_grabacion,f.total_forma,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u 
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
											 FROM dbo.RIA_FORMATOS
											 WHERE activo = 1
											 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	order by f.fecha_calif,t.nombre,u.login

END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSQuestionDetail - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSQuestionDetail
	
	INSERT INTO dbo.RepAVRSQuestionDetail
	SELECT f.fecha_calif, f.id_grabacion, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], (s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS [supervisor], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion,
		   p.id_pregunta, p.enunciado_pregunta, r.etiquetas, r.peso AS [score], b.finicio, 
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
									  FROM RIA_FORMATOS
									  WHERE activo = 1
									  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN ccUsers s
	ON f.id_supervisor =  s.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta) INNER JOIN RIA_GRABACION b
	ON f.id_grabacion = b.grab_id
	ORDER BY f.fecha_calif,c.id_concepto,c.con_descripcion,t.id_formato,t.nombre,u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres
	
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSRateDetail - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSRateDetail]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRRateDetail 
	DELETE FROM dbo.RepAVRSRateDetail
	
	INSERT INTO dbo.RepAVRSRateDetail
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS supervisor,
		   g.grab_id,t.id_formato,t.nombre AS formato,f.total_forma,g.finicio,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
											 FROM dbo.RIA_FORMATOS
											 WHERE activo = 1
											 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN dbo.RIA_GRABACION g
		 ON f.id_grabacion = g.grab_id INNER JOIN dbo.ccUsers s
		 ON f.id_supervisor = s.User_Id
	order by f.fecha_calif,u.login,t.nombre
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSScores - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSScores]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSScores
	
	INSERT INTO dbo.RepAVRSScores
	--By Agent
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
											 FROM dbo.RIA_FORMATOS
											 WHERE activo = 1
											 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato
	GROUP BY f.fecha_calif,u.User_id,u.Login,u.apellidopaterno,u.apellidomaterno,u.nombres	
	UNION ALL
	--By Supervisor
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
													FROM dbo.RIA_FORMATOS
													WHERE activo = 1
													GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato
	GROUP BY f.fecha_calif,u.User_id,u.Login,u.apellidopaterno,u.apellidomaterno,u.nombres
		
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSSection - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSSection]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRSSection 
	DELETE FROM dbo.RepAVRSSection
	
	INSERT INTO dbo.RepAVRSSection
	SELECT f.fecha_calif, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion, SUM(r.peso) AS [score],
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
									  FROM RIA_FORMATOS
									  WHERE activo = 1
									  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta)
	GROUP BY f.fecha_calif,c.id_concepto,c.con_descripcion,t.id_formato,t.nombre,u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres
	
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSSupervisor - Create Procedure (AVRS)'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepAVRSSupervisor]
AS
BEGIN
	
	---Before insert delete first all table dbo.RepAVRSSupervisor 
	DELETE FROM dbo.RepAVRSSupervisor
	
	INSERT INTO dbo.RepAVRSSupervisor
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
													FROM dbo.RIA_FORMATOS
													WHERE activo = 1
													GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)	
		
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSAgent - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSAgent]    Script Date: 09/09/2013 10:19:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:19:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSAgent'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSAgent]    Script Date: 09/09/2013 10:19:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSAgent'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSAgent]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSAgent'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSDisposition - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSDisposition]    Script Date: 09/09/2013 10:22:20 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:22:20 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSDisposition'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSDisposition]    Script Date: 09/09/2013 10:22:20 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSDisposition'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSDisposition]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSDisposition'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSQuestionDetail - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSQuestionDetail]    Script Date: 09/09/2013 10:25:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:25:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSQuestionDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSQuestionDetail]    Script Date: 09/09/2013 10:25:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSQuestionDetail'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSQuestionDetail]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSQuestionDetail'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSRateDetail - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSRateDetail]    Script Date: 09/09/2013 10:28:39 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:28:39 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSRateDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSRateDetail]    Script Date: 09/09/2013 10:28:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSRateDetail'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSRateDetail]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSRateDetail'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSScores - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSScores]    Script Date: 09/09/2013 10:30:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:30:13 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSScores'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSScores]    Script Date: 09/09/2013 10:30:13 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSScores'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSScores]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSScores'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSSection - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSSection]    Script Date: 09/09/2013 10:32:18 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:32:18 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSSection'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSSection]    Script Date: 09/09/2013 10:32:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSSection'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSSection]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSSection'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSSupervisor - Create Job (AVRS)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepAVRSSupervisor]    Script Date: 09/09/2013 10:34:35 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/09/2013 10:34:35 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepAVRSSupervisor'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccspRepAVRSSupervisor]    Script Date: 09/09/2013 10:34:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccspRepAVRSSupervisor'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [dbo].[ccspRepAVRSSupervisor]'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccspRepAVRSSupervisor'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130909, 
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
EndSave:'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInEffectiveness - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
CREATE TABLE [dbo].[#ccGenInCall](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[dni_id] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[ntotal] [smallint] NOT NULL,
[ninitial] [smallint] NOT NULL,
[nout_hour] [smallint] NOT NULL,
[nout_service] [smallint] NOT NULL,
[nabnd] [smallint] NOT NULL,
[nno_agent] [smallint] NOT NULL,
[nque] [smallint] NOT NULL,
[ntimeout] [smallint] NOT NULL,
[noverflow] [smallint] NOT NULL,
[nxfer] [smallint] NOT NULL,
[nxfer_que] [smallint] NOT NULL,
[nabnd_xfer] [smallint] NOT NULL,
[nabnd_ring] [smallint] NOT NULL,
[nno_answer] [smallint] NOT NULL,
[nabnd_dialog] [smallint] NOT NULL,
[nanswer] [smallint] NOT NULL,
[nlost] [smallint] NOT NULL,
[nmsg] [smallint] NOT NULL,
[nabnd_tres] [smallint] NOT NULL,
[nansw_tres] [smallint] NOT NULL,
[tque_max] [smallint] NOT NULL,
[tque] [int] NOT NULL,
[txfer] [int] NOT NULL,
[tdialog] [int] NOT NULL,
[tnotes] [int] NOT NULL,
[tring] [int] NOT NULL,
[tresp] [int] NOT NULL,
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenSession](
[user_id] [smallint] NOT NULL,
[login] [datetime] NOT NULL,
[logout] [datetime] NOT NULL,
[extension] [varchar](7) NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#agents](
[timegroup] [smalldatetime] NOT NULL,
[user_id] [smallint] NOT NULL,
[tlog] [smallint] NOT NULL DEFAULT (0),
[treq] [smallint] NOT NULL DEFAULT (0),
[tnot_av] [int] NOT NULL,
[tav] [smallint] NOT NULL DEFAULT (0),
[tprob] [smallint] NOT NULL DEFAULT (0),
[tunknown] [smallint] NOT NULL DEFAULT (0),
[tother] [smallint] NOT NULL DEFAULT (0),
[nother] [smallint] NOT NULL DEFAULT (0),
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]		

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenInAbnd](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[amount] [smallint] NOT NULL,
[time_max] [smallint] NOT NULL,
[time_tot] [bigint] NOT NULL,
[<10] [smallint] NOT NULL,
[<20] [smallint] NOT NULL,
[<30] [smallint] NOT NULL,
[<40] [smallint] NOT NULL,
[<50] [smallint] NOT NULL,
[<60] [smallint] NOT NULL,
[<120] [smallint] NOT NULL,
[<180] [smallint] NOT NULL,
[<240] [smallint] NOT NULL,
[<300] [smallint] NOT NULL,
[+300] [smallint] NOT NULL
) ON [PRIMARY]

INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
,COUNT(cal_id)AS ntotal
,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
,*
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
UNION
SELECT timegroup_next,inbound_id,dni_id,[user_id]
,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
WHERE timegroup>=@from AND timegroup<@to
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
ORDER BY timegroup,inbound_id,dni_id,[user_id]

INSERT INTO #ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
FROM
	(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
	FROM 
		(SELECT uid, ext, MAX(login) as login, logout
		FROM
			(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
			FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0 
			AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
			FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/
			WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
			GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
		WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
	RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/
	ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
	WHERE tipomov = 1
	and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det 
) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from and login < @to
GROUP BY uid, login

INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
SELECT timegroup,[user_id],tlog,tnot_av
,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
,nother,nMoh,nWHag,nWHcl
FROM(
	SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
		,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
	 FROM(
		SELECT 
			xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
			,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer
			,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog
			,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes
			,ISNULL(SUM(#ccGenInCall.tring),0) as tring
			,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh
			,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag
			,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl

			,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t1
			,ISNULL((SELECT top 1 3600
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t2
			,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t3
			,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t4

		 FROM(
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
					,ccLogAgentesDia.[user_id]
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
					,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				 FROM ccLogAgentesDia
				 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
			)xTimeDetail
				LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])
			GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		)xDetail
)xAllTimes
WHERE tlog>0
ORDER BY timegroup,[user_id]

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccInboundAgentes.inbound_id
	, COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
 FROM #agents
	INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])
 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
 GROUP BY timegroup, ccInboundAgentes.inbound_id

insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
SELECT timegroup
, inbound_id
, COUNT(cal_inicio) AS amount
, MAX(tAbnd) AS time_max
, SUM(tAbnd) AS time_tot
, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
FROM	(
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cal_inicio
	, inbound_id
	, statuscall_id
	, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
	, (cal_twait + cal_txfer + cal_tring) AS tAbnd
 FROM ccCallsIn
	WHERE cal_inicio >= @from AND  cal_inicio < @to
	AND INBOUND_ID > 0
) xCalls
WHERE (abnd IS NOT NULL) 
GROUP BY timegroup, inbound_id

--Borrar lo que esta para no repetir
delete from RepInEffectiveness where date >= @from AND date < @to

insert into RepInEffectiveness
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''No ACD group'') descripcion , ntotal, nanswer, nabnd , tatention, 
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, tabnd_tot as tabndtot, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp, 
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
FROM ( 

SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, 
ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, 
ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot, 
ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count 

FROM (

SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, 
ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, 
SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp  
FROM #ccGenInCall  
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetCall  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count  
FROM #ccGenInSpec 
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetSpec 
ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot   
FROM #ccGenInAbnd  
WHERE timegroup >= @from 
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetAbnd 
ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id) 
) xDetail  
LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)  
ORDER BY date

drop table #ccGenInCall
drop table #ccGenInSpec
drop table #ccGenSession
drop table #agents
drop table #ccGenInAbnd
end'
	
	EXEC(@Sql)

		set @process = 'Filters - Insert (Fix)'
		set @Sql = 'insert into Filters values(21,''dispositionsOut'',5,''Dispositions'',''Disposition'')
insert into Filters values(22,''subdispositionsOut'',21,''Subdispositions'',''Subdisposition'')'
		
	EXEC(@Sql)

		set @process = 'Filters - Update (Fix)'
		set @Sql = 'update Filters set name=''dispositionsIn'' where id =9
update Filters set name=''subdispositionsIn'' where id =10'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFilters - Update (Fix)'
		set @Sql = 'update ReportsFilters set filterName = ''dispositionsIn''  where id =3040 and filterName=''dispositions''
update ReportsFilters set filterName = ''subdispositionsIn''  where id =3120 and filterName=''subdispositions''
update ReportsFilters set filterName = ''dispositionsOut''  where id =4040 and filterName=''dispositions''
update ReportsFilters set filterName = ''subdispositionsOut''  where id =4100 and filterName=''subdispositions'''
		
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert (Fix)'
		set @Sql = 'insert into ccsettings
values (28, ''5'', ''Intervalo de espera(seg) entre reportes'', 1, ''X'')'
		
	EXEC(@Sql)
	
		set @process = 'jobSchedules - Delete (Fix)'
		set @Sql = 'declare @scheduleId nvarchar(max)

set @scheduleId = ''''

create table #jobSchedules (
schedule_id nvarchar(max),
flag bit
)

insert into #jobSchedules
select schedule_id, 0 as flag
from msdb.dbo.sysjobs a
left join msdb.dbo.sysjobschedules b on (a.job_id = b.job_id)
where [name] like ''ccsp%''
order by [name]

while (select count(*) from #jobSchedules with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @scheduleId = schedule_id
		from #jobSchedules with(nolock) 
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_delete_schedule @schedule_id = @scheduleId, @force_delete = 1

	update #jobSchedules with(rowlock)
	set flag = 1
	where schedule_id = @scheduleId
end

drop table #jobSchedules'
		
	EXEC(@Sql)

		set @process = 'ReportsMasterProcess - Create Procedure (Fix)'
		set @Sql = 'CREATE procedure [dbo].[ReportsMasterProcess] as

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100)
declare @numOfReports int

set nocount on

set @dateStart = getdate()
set @delay = 0
set @reportName = ''''
set @numOfReports = 0

create table #reports ([name] nvarchar(100), flag bit)

insert into #reports
select [name], 0 as flag
from msdb.dbo.sysjobs
where [name] like ''ccsp%''
order by [name]

select @numOfReports = count(*)
from #reports with(nolock)

select @delay = cast(valor as int)
from ccsettings
where setting_id = 28

if (@delay < 1)
	set @delay = 1
else if (@delay > floor(cast(600 as decimal) / cast(@numOfReports as decimal)))
	set @delay = floor(cast(600 as decimal) / cast(@numOfReports as decimal))

set @strDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@delay)) + convert(VARCHAR(6),@delay),3,0,'':''),6,0,'':'')

while(select count(*) from #reports with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @reportName = [name]
		from #reports with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @reportName

	update #reports with(rowlock)
	set flag = 1
	where [name] = @reportName

	waitfor delay @strDelay
end

drop table #reports'
		
	EXEC(@Sql)
	
		set @process = 'ReportsMasterProcess - Create Job (Fix)'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ReportsMasterProcess]    Script Date: 12/09/2013 06:13:43 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 12/09/2013 06:13:43 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcess'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcess'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 12/09/2013 06:13:43 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcess'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
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
EndSave:'
		
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
