/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jose Velasco. Jesus Gallardo
Date: 2015/03/10
Description:

	------ ALTER PROCEDURE RepOutDialDetail
	------ insert into ReportsFiltersMenus
	------ insert into ReportsFiltersText
	------ update RepOutDialDetail

	----se agrega scripts de email





Database: ccReportsRiaPara Mail
Required version: 28

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 29

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process = 'alter table RepOutDialDetail ------------'
	set @Sql= 'if not exists (select * from sys.columns where name = N''RepOutDialDetail'' and Object_ID = Object_ID(N''listName''))
	begin
		alter table RepOutDialDetail add listName varchar(80) null
	end'
	EXEC(@Sql)

	set @process = 'insert into ReportsFiltersMenus ----------'
	set @Sql= 'insert into ReportsFiltersMenus (idReport, filterMenuName) values (4010, ''text'')
			insert into ReportsFiltersText (reportName, restrictExp, dbColumn, id) values (''Dialing Detail'', ''A-Z a-z0-9 _\-'', ''listName'', 4010)'
	EXEC(@Sql)

	set @process = 'update RepOutDialDetail ---------'
	set @Sql= 'update RepOutDialDetail set listName = '''''
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] --------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]
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
		delete from RepOutDialDetail with(rowlock)
		where date >= @from AND date < @to

		--Inserta información de reporte
		insert into RepOutDialDetail
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime,
		datepart(yyyy,fecha), datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha), isnull(rl.name,'''')
		FROM (select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,
			  dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key
			  FROM ccoLogDials dial
			  left join ccocallsout co on
				(dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono
				 and tiporesdial_id = 1
				 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) >= convert(datetime,convert(varchar(19),dial.fecha),121)
				 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) <=  convert(datetime,convert(varchar(19),dial.fecha),121))
			  WHERE fecha >= @from AND fecha < @to) dials
		LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id
		LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id
		LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]
		LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id
		WHERE fecha >= @from AND fecha < @to
		order by fecha
	end'
	EXEC(@Sql)


	-----------------------------------reportes email


	set @process = 'insert FIlter Menu'
	set @Sql= 'if not exists(select * from reportsfiltersmenus where idReport=10010) begin
		insert into reportsfiltersmenus values(10010,''date'')
		insert into reportsfiltersmenus values(10010,''filterby'')
		insert into reportsfiltersmenus values(10020,''date'')
		insert into reportsfiltersmenus values(10020,''filterby'')
		insert into reportsfiltersmenus values(10030,''date'')
		insert into reportsfiltersmenus values(10030,''filterby'')
		insert into reportsfiltersmenus values(10040,''date'')
		insert into reportsfiltersmenus values(10040,''filterby'')
	end'
	EXEC(@Sql)


	set @process = 'Insert reportstotals'
	set @Sql= 'if not exists(select * from reportstotals where id=10010) begin
insert into reportstotals values(10010,''sum:download|sum:tWait|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:abandonedSystem|sum:abandonedAgent|avg:avgSend|sum:tQueue|sum:tsend|sum:totalWait|sum:tatencion|sum:tResponse|sum:twrapup'')
insert into ReportsTotals values(10020,''sum:download|sum:tWait|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:abandonedSystem|sum:abandonedAgent|sum:finishedConversation|sum:messageUnAssigned|sum:avgSend|sum:tQueue|sum:tsend|sum:totalWait|sum:tatencion|sum:tResponse|sum:twrapup'')
insert into ReportsTotals values(10030,''sum:tQueue|sum:twait|sum:timeretention|sum:timeansware|sum:twrapup|sum:tsend'')
insert into ReportsTotals values(10040,''sum:timeretention|sum:twrapup'')
end'
	EXEC(@Sql)

	set @process = 'conversation - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''conversation'') begin
create table [conversation](
	conversationId [int] identity NOT NULL,
	inboundId [smallint] NOT NULL,
	info [varchar](255) NULL,
	isInbox [bit] NOT NULL,
	isFinished [bit] NOT NULL,
	mailClient [varchar] (60) NOT NULL,
	mailInbound [varchar](60) NULL,
	meanContactTypeId [smallint] NOT NULL
)
end'

	EXEC(@Sql)

	set @process = 'message - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''message'') begin
create table [message](
	messageId [int] identity NOT NULL,
	conversationId [int] NOT NULL,
	messageStatusId [int] NOT NULL,
	userId [smallint] NOT NULL,
	[date] [datetime] NOT NULL,
	tQueue [datetime] NULL,
	tWait [int] NOT NULL DEFAULT(0),
	tRetention [int] NOT NULL DEFAULT(0),
	tResponse [int] NOT NULL DEFAULT(0),
	tWrapUp [tinyint] NOT NULL DEFAULT(0),
	tSend [datetime] NULL,
	isSender bit NOT NULL DEFAULT(0)
)
end'
	EXEC(@Sql)

	set @process = 'messageUnAssigned - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''messageUnAssigned'') 	begin
	Create table messageUnAssigned(
		[messageId] [int] NOT NULL,
		userId [int] NOT NULL,
		time [int] NOT NULL DEFAULT(0),
		isLogout [bit] NOT NULL DEFAULT(0)
	)
end'
	EXEC(@Sql)

	set @process = 'CREATE table RepEmailACD--'
	set @Sql= 'if not exists (select * from sys.tables where name = N''RepEmailACD'') begin
CREATE TABLE RepEmailACD
([date] datetime not null,
inbound varchar(50) not null,
inbounid smallint not null,
download int not null,
tWait int not null,
ontrack int not null,
rejected int not null,
assigned int not null,
totalAssets int not null,
abandonedSystem  int not null,
abandonedAgent int not null,
finishedConversation int not null,
avgSend int not null,
tQueue int not null,
tsend int not null,
totalWait int not null,
tatencion int not null,
tResponse int not null,
twrapup int not null,
[year] int not null,
[month] int not null,
[day] int not null,
[hour] int not null,
[minutes] int not null
) ON [PRIMARY]
end
'
		EXEC(@Sql)

	set @process = 'CREATE table RepEmailACDDetalle--'
	set @Sql= 'if not exists (select * from sys.tables where name = N''RepEmailAgente'') begin
CREATE TABLE [dbo].[RepEmailAgente](
	[date] [datetime] NOT NULL,
	agentName varchar(45) not null,
	userid int not null,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[download] [int] NOT NULL,
	[tWait] [int] NOT NULL,
	[ontrack] [int] NOT NULL,
	[rejected] [int] NOT NULL,
	[assigned] [int] NOT NULL,
	[totalAssets] [int] NOT NULL,
	[abandonedSystem] [int] NOT NULL,
	[abandonedAgent] [int] NOT NULL,
	[finishedConversation] [int] NOT NULL,
	messageUnAssigned int not null,
	[avgSend] [int] NOT NULL,
	[tQueue] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[totalWait] [int] NOT NULL,
	[tatencion] [int] NOT NULL,
	[tResponse] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]
end'
	EXEC(@Sql)


	set @process = 'Create table -- RepEmailDetail'
	set @Sql= 'if not exists (select * from sys.tables where name = N''RepEmailDetail'') begin
	CREATE TABLE [dbo].[RepEmailDetail](
	[date] [datetime] NOT NULL,
	[statusMail] varchar(255) NOT NULL,
	[mailClient] [varchar](60) NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[conversationid] [int] NOT NULL,
	[messagestatusid] [int] NOT NULL,
	[tQueue] [int] NOT NULL,
	[twait] [int] NOT NULL,
	[timeretention] [int] NOT NULL,
	[timeansware] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]
	end'
	EXEC(@Sql)

	set @process = 'Create table -- RepEmailGeneral'
	set @Sql= 'if not exists (select * from sys.tables where name = N''RepEmailGeneral'') begin
	CREATE TABLE [dbo].[RepEmailGeneral](
	[date] [datetime] NOT NULL,
	[statusMail] [varchar](255) NOT NULL,
	[mailClient] [varchar](60) NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[conversationid] [int] NOT NULL,
	[messagestatusid] [int] NOT NULL,
	[twait] [int] NOT NULL,
	[timeretention] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]
end'
	EXEC(@Sql)

	set @process = 'CREATE index -- IX_RepEmailACD'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepEmailACD'' and object_id = OBJECT_ID(N''IX_RepEmailACD''))
	begin
		CREATE NONCLUSTERED INDEX [IX_RepEmailACD] ON [dbo].[RepEmailACD]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@Sql)


	set @process = 'CREATE index -- IX_RepEmailAgente'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepEmailAgente'' and object_id = OBJECT_ID(N''RepEmailAgente''))
	begin
		CREATE NONCLUSTERED INDEX [IX_RepEmailAgente] ON [dbo].[RepEmailAgente]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@Sql)


	set @process = 'CREATE index -- IX_RepEmailDetail'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepEmailDetail'' and object_id = OBJECT_ID(N''RepEmailDetail''))
	begin
		CREATE NONCLUSTERED INDEX [IX_RepEmailDetail] ON [dbo].[RepEmailDetail]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@Sql)


	set @process = 'CREATE index -- IX_RepEmailGeneral'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepEmailGeneral'' and object_id = OBJECT_ID(N''RepEmailGeneral''))
	begin
		CREATE NONCLUSTERED INDEX [IX_RepEmailGeneral] ON [dbo].[RepEmailGeneral]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@Sql)

	set @process = 'ccsp_MailAdminAccount - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccspRepEmailACD'') DROP PROCEDURE ccspRepEmailACD'
	EXEC(@Sql)

	set @process = 'ccsp_MailAdminAccount - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccspRepEmailAgente'') DROP PROCEDURE ccspRepEmailAgente'
	EXEC(@Sql)

	set @process = 'ccsp_MailAdminAccount - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccspRepEmailDetail'') DROP PROCEDURE ccspRepEmailDetail'
	EXEC(@Sql)

	set @process = 'ccsp_MailAdminAccount - Drop if exists'
	set @Sql='if exists (select * from sys.procedures where name = N''ccspRepEmailGeneral'') DROP PROCEDURE ccspRepEmailGeneral'
	EXEC(@Sql)


	set @process ='CREATE PROCEDURE [dbo].[ccspRepEmailACD] ----'
	set @sql = 'Create PROCEDURE [dbo].[ccspRepEmailACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin



	delete from RepEmailACD with(rowlock)
	where date >= @from AND date < @to


insert into RepEmailACD
select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
	descripcion ,inboundid,
	count(*) Downloads,sum(wait) wait,sum(onTrack) onTrack,
	sum(rejected) rejected,sum(assigned) assigned,sum(totalassets) totalassets,
	sum(abandonedsystem) abandonedsystem,sum(abandonedbyagent) abandonedbyagent,sum(finishedconversation) finishedconversation,
	isnull(count(*)/sum(nullIf(sendMail,0)),0) sentvsdownloaded,
	sum(tQueue) tQueue,sum(tsent) tsent,sum(twait) twait,sum(tatention) tatention,
	sum(tResponse) tResponse,sum(twrapup) twrapup,
	datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
	datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
	datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
	datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
	datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]

 from (
	select msg.date date,
			 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
			 case when msg.messagestatusid in(1,4) then 1 else 0 end wait,
			 case when msg.messagestatusid = 7 then 1 else 0 end rejected,
			 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
			 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
			 case when msg.messagestatusid = 3 then 1 else 0 end totalassets,
			 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
			 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
			 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
			 case when conv.isfinished = 1 then 1 else 0 end finishedconversation,
			 datediff(second,msg.date,msg.tqueue) tQueue,
			datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
			 msg.twait twait,
			 msg.twait + msg.tretention + msg.tresponse tatention,
			 msg.tresponse tResponse,
			 msg.twrapup twrapup
			 from [message] msg inner join [conversation] conv
			on msg.conversationId = conv.conversationId left join [ccInbound] inbo
			on inbo.inbound_Id = conv.inboundId
			left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
			where msg.date >= @from AND msg.date < @to
			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid

end'
	EXEC(@sql)

	set @process ='CREATE PROCEDURE [dbo].[ccspRepEmailAgente] ----'
	set @sql = 'Create PROCEDURE [dbo].[ccspRepEmailAgente]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailAgente with(rowlock)
	where date >= @from AND date < @to

	insert into RepEmailAgente
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
	name,userid,
	descripcion ,inboundid,
	count(*) Downloads,sum(wait) wait,sum(onTrack) onTrack,
	sum(rejected) rejected,sum(assigned) assigned,sum(totalassets) totalassets,
	sum(abandonedsystem) abandonedsystem,sum(abandonedbyagent) abandonedbyagent,sum(finishedconversation) finishedconversation,
	sum(messageUnAssigned) messageUnAssigned,
	isnull(count(*)/sum(nullIf(sendMail,0)),0) sentvsdownloaded,
	sum(tQueue) tQueue,sum(tsent) tsent,sum(twait) twait,sum(tatention) tatention,
	sum(tResponse) tResponse,sum(twrapup) twrapup,
	datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
	datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
	datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
	datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
	datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]

 from (

	select msg.date date,msg.messageid,
			usuario.nombres name,usuario.[User_Id] userid,
			 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
			 case when msg.messagestatusid in(1,4) then 1 else 0 end wait,
			 case when msg.messagestatusid = 7 then 1 else 0 end rejected,
			 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
			 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
			 case when msg.messagestatusid = 3 then 1 else 0 end totalassets,
			 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
			 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
			 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
			 case when conv.isfinished = 1 then 1 else 0 end finishedconversation,
			sum(case when msgun.messageid is null then  0 else 1 end) messageUnAssigned,
			 datediff(second,msg.date,msg.tqueue) tQueue,
			datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
			 msg.twait twait,
			 msg.twait + msg.tretention + msg.tresponse tatention,
			 msg.tresponse tResponse,
			 msg.twrapup twrapup
			 from [message] msg inner join [conversation] conv on msg.conversationId = conv.conversationId
			 left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
			left join ccusers usuario on usuario.User_id = msg.userid
			left join messageUnAssigned msgun on msg.UserId=msgun.UserId
				where msg.date >= @from AND msg.date < @to
			group by msg.date,usuario.nombres,usuario.[User_Id],msg.messagestatusid,inbo.descripcion,inbo.inbound_id,conv.isfinished,msg.tqueue,
			msg.twait,msg.tretention,msg.tresponse,msg.twrapup,msg.tsend,msg.messageId

			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId


end'
	EXEC(@sql)

	set @process ='CREATE PROCEDURE [dbo].[ccspRepEmailDetail] ----'
	set @sql = 'CREATE procedure [dbo].[ccspRepEmailDetail]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin



	delete from RepEmailDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepEmailDetail
		select msg.date date,
	case when msg.messagestatusid = 1 then ''systemTranslate_Download_emails_from_server''
	when msg.messagestatusid = 2 then ''systemTranslate_Assign_message_to_agent''
	when msg.messagestatusid = 3 then ''systemTranslate_Read_the_message_agent''
	when msg.messagestatusid = 4 then ''systemTranslate_Unassign_message_to_agent''
	when msg.messagestatusid = 5 then ''systemTranslate_Message_answered_by_agent''
	when msg.messagestatusid = 6 then ''systemTranslate_Message_sent_to_the_client''
	when msg.messagestatusid = 7 then ''systemTranslate_Message_rejected_for_server''
	when msg.messagestatusid = 8 then ''systemTranslate_Sending_the_message_is_rescheduled''
	when msg.messagestatusid = 10 then ''systemTranslate_conversation_closed_for_system''
	when msg.messagestatusid = 11 then ''systemTranslate_Close_conversation_for_agent'' else '''' end statusMail,
	conv.mailClient mailClient,	inbo.descripcion descripcion ,inbo.inbound_id inboundid,conv.conversationId conversationid,
	msg.messagestatusid,
datediff(second,msg.date,msg.tqueue) tQueue,msg.twait twait,
msg.tretention timeretention,
msg.twait + msg.tretention + msg.tresponse timeansware,msg.twrapup twrapup,
datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
datepart(yyyy,date) [year],datepart(mm,date) [mounth],datepart(dd,date) [day],datepart(hh,date) [hour],datepart(mi,date) [minute]
from [message] msg inner join [conversation] conv
on msg.conversationId = conv.conversationId left join [ccInbound] inbo
on inbo.inbound_Id = conv.inboundId
left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
			where msg.date >= @from AND msg.date < @to

end'
	EXEC(@sql)

	set @process ='CREATE PROCEDURE [dbo].[ccspRepEmailGeneral] ----'
	set @sql = 'CREATE procedure [dbo].[ccspRepEmailGeneral]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin



	delete from RepEmailGeneral with(rowlock)
	where date >= @from AND date < @to
insert into RepEmailGeneral
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date ,
	case max(messagestatusid) when 1 then ''systemTranslate_Download_emails_from_server''
	when 2 then ''systemTranslate_Assign_message_to_agent''
	when 3 then ''systemTranslate_Read_the_message_agent''
	when 4 then ''systemTranslate_Unassign_message_to_agent''
	when 5 then ''systemTranslate_Message_answered_by_agent''
	when 6 then ''systemTranslate_Message_sent_to_the_client''
	when 7 then ''systemTranslate_Message_rejected_for_server''
	when 8 then ''systemTranslate_Sending_the_message_is_rescheduled''
	when 10 then ''systemTranslate_conversation_closed_for_system''
	when 11 then ''systemTranslate_Close_conversation_for_agent''
	else ''systemTranslate_Other'' end	statusMail,
	min(mailClient),descripcion,inboundid,conversationId,max(messagestatusid),
	sum(twait) twait,sum(timeretention) timeretention,sum(twrapup) twrapup,
	sum(tsent) tsent,
	datepart(yyyy,min(date)) [year],datepart(mm,min(date)) [mounth],datepart(dd,min(date)) [day],datepart(hh,min(date)) [hour],datepart(mi,min(date)) [minute]
from (
	select msg.date,
		conv.mailClient mailClient,	inbo.descripcion descripcion ,inbo.inbound_id inboundid,conv.conversationId conversationid,
		msg.messagestatusid,
			datediff(second,msg.date,msg.tqueue) tQueue,msg.twait twait,
			msg.tretention timeretention,
			msg.twait + msg.tretention + msg.tresponse timeansware,msg.twrapup twrapup,
			datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent
			from [message] msg inner join [conversation] conv on msg.conversationId = conv.conversationId
			left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				where msg.date >= @from AND msg.date < @to
			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion,inboundid,conversationId



end'
	EXEC(@sql)

			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off