/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2015/10/19
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara
Required version: 34

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 35

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process = 'insert into ReportsFiltersMenu -------'
	set @sql='if not exists (select * from ReportsFiltersMenus where idReport in(10010,10020,10030,10040)) begin

insert into ReportsFiltersMenus (idReport,filterMenuName) values(10010,''date'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10010,''filterby'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10020,''date'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10020,''filterby'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10030,''date'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10030,''filterby'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10040,''date'')
insert into ReportsFiltersMenus (idReport,filterMenuName) values(10040,''filterby'')
end '
		EXEC(@sql)

	set @process = 'insert into ReportsFilters -------'
		set @sql='if not exists (select * from ReportsFilters where id in(10010,10020,10030,10040)) begin

insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterACD'',''acds'',11010)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterACD'',''users'',11010)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterAgente'',''acds'',11020)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterAgente'',''users'',11020)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterDetail'',''acds'',11030)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterDetail'',''users'',11030)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterGeneral'',''acds'',11040)
insert into ReportsFilters (reportName,filterName,id) values(''RepTwitterGeneral'',''users'',11040)
end'
	 EXEC(@sql)

	set @process = 'insert into ReportsTotals -------'
	set @sql='if not exists (select * from ReportsTotals where id in(10010,10020,10030,10040)) begin

insert into ReportsTotals (id,totalColumns)
values (10010,''sum:download|sum:tWait|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:abandonedSystem|sum:abandonedAgent|avg:avgSend|sum:tQueue|sum:tsend|sum:totalWait|sum:tatencion|sum:tResponse|sum:twrapup'')

insert into ReportsTotals (id,totalColumns)
values (10020,''sum:download|sum:tWait|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:abandonedSystem|sum:abandonedAgent|sum:finishedConversation|sum:messageUnAssigned|sum:avgSend|sum:tQueue|sum:tsend|sum:totalWait|sum:tatencion|sum:tResponse|sum:twrapup'')

insert into ReportsTotals (id,totalColumns)
values (10030,''sum:tQueue|sum:twait|sum:timeretention|sum:timeansware|sum:twrapup|sum:tsend'')

insert into ReportsTotals (id,totalColumns)
values (100140,''sum:timeretention|sum:twrapup'')
end'
	EXEC(@sql)

	set @process = 'insert into TranslatedReports -------'
	set @sql='
if not exists (select * from TranslatedReports where id = 11040) begin 
insert into TranslatedReports  (id,columns)
values(11040,''statusTwetter'')
end'
	EXEC(@sql)



	set @process = 'CREATE TABLE [dbo].[RepTwitterGeneral]----- '
		set @sql='if not exists (select * from sys.tables where name = N''RepTwitterGeneral'')
	begin
		CREATE TABLE [dbo].[RepTwitterGeneral](
	[date] [datetime] NOT NULL,
	[statusTwetter] [varchar](255) NULL,
	[screenNameClient] [varchar](100) NULL,
	[descripcion] [varchar](50) NULL,
	[inboundid] [int] NULL,
	[conversationTwitterId] [bigint] NULL,
	[messagestatusid] [int] NULL,
	[tQueue] [int] NULL,
	[twait] [int] NULL,
	[twrapup] [int] NULL,
	[tsent] [int] NULL,
	[year] [int] NULL,
	[mounth] [int] NULL,
	[day] [int] NULL,
	[hour] [int] NULL,
	[minute] [int] NULL
) ON [PRIMARY]
	end'
		EXEC(@sql)

		set @process = 'CREATE TABLE [dbo].[RepTwitterDetail]-------'
		set @sql='if not exists (select * from sys.tables where name = N''RepTwitterDetail'')
	begin
		CREATE TABLE [dbo].[RepTwitterDetail](
	[date] [datetime] NOT NULL,
	[statusTwitter] [varchar](255) NOT NULL,
	[screenNameClient] [varchar](60) NOT NULL,
	[descripcion] [varchar](50) NOT NULL,
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
		EXEC(@sql)


		set @process = 'CREATE TABLE [dbo].[RepTwitterAgente]--------'
		set @sql='if not exists (select * from sys.tables where name = N''RepTwitterAgente'')
	begin
		CREATE TABLE [dbo].[RepTwitterAgente](
	[date] [datetime] NOT NULL,
	[name] [varchar](45) NOT NULL,
	[userid] [int] NOT NULL,
	[descripcion] [varchar](50) NOT NULL,
	[inboundid] [smallint] NOT NULL,
	[Downloads] [int] NOT NULL,
	[tWait] [int] NOT NULL,
	[ontrack] [int] NOT NULL,
	[rejected] [int] NOT NULL,
	[assigned] [int] NOT NULL,
	[totalAssets] [int] NOT NULL,
	[abandonedSystem] [int] NOT NULL,
	[abandonedAgent] [int] NOT NULL,
	[finishedConversation] [int] NOT NULL,
	[messageUnAssigned] [int] NOT NULL,
	[sentvsdownloaded] [int] NOT NULL,
	[tQueue] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[wait] [int] NOT NULL,
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
		EXEC(@sql)


		set @process = 'CREATE TABLE [dbo].[RepTwitterACD]---------'
		set @sql='if not exists (select * from sys.tables where name = N''RepTwitterACD'')
	begin
		CREATE TABLE [dbo].[RepTwitterACD](
	[date] [datetime] NOT NULL,
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
		EXEC(@sql)

	set @process = 'Drop PROCEDURE  --- ccspRepTwitterGeneral,ccspRepTwitterDetail,ccspRepTwitterAgente,ccspRepTwitterACD'
	set @sql='if exists (select * from sys.procedures where name = N''ccspRepTwitterGeneral'') DROP PROCEDURE ccspRepTwitterGeneral
	if exists (select * from sys.procedures where name = N''ccspRepTwitterDetail'') DROP PROCEDURE ccspRepTwitterDetail
	if exists (select * from sys.procedures where name = N''ccspRepTwitterAgente'') DROP PROCEDURE ccspRepTwitterAgente
	if exists (select * from sys.procedures where name = N''ccspRepTwitterACD'') DROP PROCEDURE ccspRepTwitterACD'
	EXEC(@Sql)

	set @process = 'create procedure [dbo].[ccspRepTwitterGeneral]------'
	set @Sql= 'create procedure [dbo].[ccspRepTwitterGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()


if @action = 1	begin


delete from RepTwitterGeneral with(rowlock)
where date >= @from AND date < @to

		insert into RepTwitterGeneral

			select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date ,
			case max(messagestatusid) when 1 then ''systemTranslate_Download_tweets_from_server''
			when 2 then ''systemTranslate_Assign_message_to_agent''
			when 3 then ''systemTranslate_Read_the_message_agent''
			when 4 then ''systemTranslate_Unassign_message_to_agent''
			when 5 then ''systemTranslate_Message_answered_by_agent''
			when 6 then ''systemTranslate_Message_sent_to_the_client''
			when 7 then ''systemTranslate_Message_rejected_for_server''
			when 8 then ''systemTranslate_Sending_the_message_is_rescheduled''
			when 10 then ''systemTranslate_conversation_closed_for_system''
			when 11 then ''systemTranslate_Close_conversation_for_agent''
			else ''systemTranslate_Other'' end statusTwetter,
			--min(mailClient),
			screenNameClient,
			descripcion,
			inboundid,
			conversationTwitterId,
			max(messagestatusid) messagestatusid,
			ISNULL(tQueue,0) tQueue,
			ISNULL(sum(twait),0) twait,
			ISNULL(sum(twrapup),0) twrapup,
		    ISNULL(sum(tsent),0)tsent,
			datepart(yyyy,min(date)) [year],datepart(mm,min(date)) [mounth],datepart(dd,min(date)) [day],datepart(hh,min(date)) [hour],datepart(mi,min(date)) [minute]
		from (
			select msg.date,
				conv.screenNameClient screenNameClient,
				inbo.descripcion descripcion,
				inbo.inbound_id inboundid ,
				conv.conversationTwitterId conversationTwitterId,
				 msg.messagestatusid messagestatusid ,
				datediff(second,msg.date,msg.tqueue) tQueue,
				msg.twait twait,
				msg.twait + msg.tresponse timeansware,
				msg.twrapup twrapup,
			--datediff(ss,dateadd(ss, msg.twait + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent
				DATEDIFF(SECOND,dateadd(ss, msg.twait + msg.tresponse + msg.twrapup , msg.tqueue ),msg.tsend) tsent  --msg.tsend tsent
				from messageOutTwitter msg inner join conversationTwitter conv on msg.conversationTwitterId = conv.conversationTwitterId
				left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				where msg.date >= @from AND msg.date < @to)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),screenNameClient,descripcion,inboundid,conversationTwitterId,tQueue


end'
	EXEC(@Sql)

	set @process = 'create SP ------ccspRepTwitterDetail'
	set @Sql= 'create PROCEDURE [dbo].[ccspRepTwitterDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
BEGIN
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepTwitterDetail
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
	when msg.messagestatusid = 11 then ''systemTranslate_Close_conversation_for_agent'' else '''' end statusTwitter,
	conv.screenNameClient screenNameClient,	inbo.descripcion descripcion ,inbo.inbound_id inbound,conv.conversationTwitterId conversationid,
	msg.messagestatusid,
isnull(datediff(second,msg.date,msg.tqueue),0) tQueue,
isnull(msg.twait,0) twait,
msg.tretention timeretention,
msg.twait + msg.tretention + msg.tresponse timeansware,msg.twrapup twrapup,
ISNULL( datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend),0) tsent,
datepart(yyyy,date) [year],datepart(mm,date) [mounth],datepart(dd,date) [day],datepart(hh,date) [hour],datepart(mi,date) [minute]
from [messageOutTwitter] msg inner join [conversationTwitter] conv
on msg.conversationTwitterId = conv.conversationTwitterId left join [ccInbound] inbo
on inbo.inbound_Id = conv.inboundId
left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssingedTwit msgun on msg.messageOutTwitterId = msgun.messageOutTwitterId
			where msg.date >= @from AND msg.date < @to

end
END'
	EXEC(@Sql)

	set @process = 'create SP -------- ccspRepTwitterAgente'
	set @Sql= 'create PROCEDURE [dbo].[ccspRepTwitterAgente]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterAgente with(rowlock)
	where date >= @from AND date < @to

	insert into RepTwitterAgente
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
	select  msg.date date,
	 ISNULL(usuario.nombres,''systemTranslate_WithOut_Agent'') name , isnull(usuario.[User_Id],0) userid, ---agregar en asp traduccion
	msg.messageOutTwitterId,
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
			ISNULL( datediff(second,msg.date,msg.tqueue),0) tQueue,
			ISNULL( datediff(ss,msg.tsend,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue)),0) tsent,
			 msg.twait twait,
			 msg.twait + msg.tretention + msg.tresponse tatention,
			 msg.tresponse tResponse,
			 msg.twrapup twrapup
			 from [messageOutTwitter] msg
			inner join [conversationTwitter] conv on msg.conversationTwitterId = conv.conversationTwitterId
			left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
			left join ccusers usuario on usuario.User_id = msg.userid
			left join messageUnAssigned msgun on msg.UserId=msgun.UserId
				where msg.date >= @from AND msg.date < @to
			group by msg.date,usuario.nombres,usuario.[User_Id],msg.messagestatusid,inbo.descripcion,inbo.inbound_id,conv.isfinished,msg.tqueue,
			msg.twait,msg.tretention,msg.tresponse,msg.twrapup,msg.tsend,msg.messageOutTwitterId

			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId


end'
	EXEC(@Sql)

	set @process = 'create SP -- ccspRepTwitterACD'
	set @Sql= 'create PROCEDURE [dbo].[ccspRepTwitterACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterACD with(rowlock)
	where date >= @from AND date < @to


insert into RepTwitterACD
select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
	descripcion ,inboundid,
	count(*) Downloads,sum(wait) wait,sum(onTrack) onTrack,
	sum(rejected) rejected,sum(assigned) assigned,sum(totalassets) totalassets,
	sum(abandonedsystem) abandonedsystem,sum(abandonedbyagent) abandonedbyagent,sum(finishedconversation) finishedconversation,
	isnull(count(*)/sum(nullIf(sendTweet,0)),0) sentvsdownloaded,
	sum(tQueue) tQueue,sum(tsent) tsent,sum(twait) twait,sum(tatention) tatention,
	sum(tResponse) tResponse,sum(twrapup) twrapup,
	datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
	datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
	datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
	datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
	datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]

 from (
	select msgout.date date,
			 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
			 case when msgout.messagestatusid in(1,4) then 1 else 0 end wait,
			 case when msgout.messagestatusid = 7 then 1 else 0 end rejected,
			 case when msgout.messagestatusid = 2 then 1 else 0 end assigned,
			 case when msgout.messagestatusid = 6 then 1 else 0 end onTrack,
			 case when msgout.messagestatusid = 3 then 1 else 0 end totalassets,
			 case when msgout.messagestatusid = 10 then 1 else 0 end abandonedsystem,
			 case when msgout.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
			 case when msgout.messagestatusid in(6,10,11) then 1 else 0 end sendTweet,
			 case when convt.isfinished = 1 then 1 else 0 end finishedconversation,
			ISNULL( datediff(second,msgout.date,msgout.tqueue),0) tQueue,
		   ISNULL(datediff(ss,dateadd(ss, msgout.twait + msgout.tretention + msgout.tresponse + msgout.twrapup,msgout.tqueue),msgout.tsend),0) tsent,
			 msgout.twait twait,
			 msgout.twait + msgout.tretention + msgout.tresponse tatention,
			 msgout.tresponse tResponse,
			 msgout.twrapup twrapup


			from [messageOutTwitter] msgout inner join [conversationTwitter] convt
			on msgout.conversationTwitterId = convt.conversationTwitterId
			left join [ccInbound] inbo
			on inbo.inbound_Id = convt.inboundId
			left join ccusers usuario on usuario.User_id = msgout.userid
			 left join messageUnAssigned msgunt on msgout.messageOutTwitterId = msgunt.messageid
			where msgout.date >= @from AND msgout.date < @to
			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid

end'
	EXEC(@Sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccspRepEmailACD] ------------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepEmailACD]

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
	isnull(descripcion,''''), isnull(inboundid,0),
	isnull(count(*),0) Downloads, isnull(sum(wait),0) wait, isnull(sum(onTrack),0) onTrack,
	isnull(sum(rejected),0) rejected, isnull(sum(assigned),0) assigned, isnull(sum(totalassets),0) totalassets,
	isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
	isnull(sum(finishedconversation),0) finishedconversation,
	isnull(count(*)/sum(nullIf(sendMail,0)),0) sentvsdownloaded,
	isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait, isnull(sum(tatention),0) tatention,
	isnull(sum(tResponse),0) tResponse, isnull(sum(twrapup),0) twrapup,
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
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccspRepEmailAgente] -------------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepEmailAgente]
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
	isnull(name,''''), isnull(userid,0),
	isnull(descripcion,'''') , isnull(inboundid,0),
	isnull(count(*),0) Downloads, isnull(sum(wait),0) wait, isnull(sum(onTrack),0) onTrack,
	isnull(sum(rejected),0) rejected, isnull(sum(assigned),0) assigned, isnull(sum(totalassets),0) totalassets,
	isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
	isnull(sum(finishedconversation),0) finishedconversation,
	isnull(sum(messageUnAssigned),0) messageUnAssigned,
	isnull(count(*)/sum(nullIf(sendMail,0)),0) sentvsdownloaded,
	isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait, isnull(sum(tatention),0) tatention,
	isnull(sum(tResponse),0) tResponse, isnull(sum(twrapup),0) twrapup,
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
	EXEC(@Sql)

	set @process = 'ALTER procedure [dbo].[ccspRepEmailDetail] ---------'
	set @Sql= 'ALTER procedure [dbo].[ccspRepEmailDetail]

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
	isnull(conv.mailClient,'''') mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, isnull(conv.conversationId,0) conversationid,
	isnull(msg.messagestatusid,0) messagestatusid,
	isnull(datediff(second,msg.[date],msg.tqueue),0) tQueue, isnull(msg.twait,0) twait,
	isnull(msg.tretention,0) timeretention,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) timeansware, isnull(msg.twrapup,0) twrapup,
	isnull(datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend),0) tsent,
	datepart(yyyy,date) [year],
	datepart(mm,date) [mounth],
	datepart(dd,date) [day],
	datepart(hh,date) [hour],
	datepart(mi,date) [minute]
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId left join [ccInbound] inbo
	on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
	where msg.date >= @from AND msg.date < @to

end'
	EXEC(@Sql)

	set @process = 'ALTER procedure [dbo].[ccspRepEmailGeneral] ----------'
	set @Sql= 'ALTER procedure [dbo].[ccspRepEmailGeneral]

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
	isnull(min(mailClient),'''') mailClient, isnull(descripcion,'''') descripcion,
	isnull(inboundid,0) inboundid, isnull(conversationId,0) conversationId,
	isnull(max(messagestatusid),0) messagestatusid,
	isnull(sum(twait),0) twait, isnull(sum(timeretention),0) timeretention, isnull(sum(twrapup),0) twrapup,
	isnull(sum(tsent),0) tsent,
	datepart(yyyy,min(date)) [year],
	datepart(mm,min(date)) [mounth],
	datepart(dd,min(date)) [day],
	datepart(hh,min(date)) [hour],
	datepart(mi,min(date)) [minute]
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
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[GetReportMenus]  ----- '
		set @sql='ALTER PROCEDURE [dbo].[GetReportMenus]
--@userId = 10,@activeChat = 1,
--@activeAVRS = 1,
--@activeEmail =1,
--@activeTwitter =1

@userId int,
@activeChat tinyint,
@activeAVRS tinyint,
@activeCRM tinyint=0,
@activeEmail tinyint=0,
@activeTwitter tinyint=0
AS
BEGIN

select menu_id,
	substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
	nullif(parent,menu_id) as parent,Nivel,ordengral,release
	into #tempCCMenus
	from ccMenus with(nolock)
	where type = 3 and menu_id >= 2000 and(
		(menu_id not in (
		3130,3131,3132,3133,3134,3135,3136,
		8050,8060,8061,8062,8063,8070,8071,8072,8080,
		9000,9010,
		10000,10010,10020,10030,10040,
		11000,11010,11020,11030,11040
		))
		or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
		or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
		or  (@activeCRM = 1 and menu_id in (9000,9010) )
		or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
		or (@activeTwitter = 1 and menu_id in (11000,11010,11020,11030,11040))
		)
		order by menu_id


;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent,release)
AS
(
	select
		distinct b.Nivel as Nivel,
		b.menu_descrip as menu_descrip,
		b.menu_id as menu_id,
		b.ordengral as ordengral,
		b.parent as parent,b.release
		from #tempCCMenus as b
		inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
	UNION ALL


--RECURSIViDAD
	select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent,a.release
		from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
)

select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by menu_id

select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release from #tempCCMenusUser A
where  menu_id not in
	(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
order by menu_id

drop table #tempCCMenus
drop table #tempCCMenusUser

END '
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