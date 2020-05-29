/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Daniel Vega
Date: 2017/11/23
Description:
**********************************************************************************************

CW-976 Email Discard

**********************************************************************************************
Database: ccReportsRia
Required version: 43



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =44
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'Alter SP --ccspRemEmailACD CW-976'
	set @Sql= '
ALTER PROCEDURE [dbo].[ccspRepEmailACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

delete from RepEmailACD with(rowlock) where date >= @from AND date < @to

	insert into RepEmailACD
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(unassigned),0) as unassigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,
		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,
				 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
				 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
				 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
				 case when msg.messagestatusid = 3 then 1 else 0 end actives,
				 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
				 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
				 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
				 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
				 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
				 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
				  case when msg.messagestatusid = 13 then 1 else 0 end emailSpam,

				 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
				 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
				 msg.twait twait,
				 msg.twait + msg.tretention + msg.tresponse tatention,
				 msg.twrapup twrapup
				 from [message] msg inner join [conversation] conv
				on msg.conversationId = conv.conversationId
				left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				left join ccusers usuario on usuario.User_id = msg.userid
				where msg.date >= @from AND msg.date < @to
				)x
				group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid
end'
	EXEC(@sql)
  
		
	
		set @process = 'Alter SP --ccspRepEmailAgente CW-976'
	set @Sql= '
ALTER PROCEDURE [dbo].[ccspRepEmailAgente]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailAgente with(rowlock)	where date >= @from AND date < @to

	insert into RepEmailAgente
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(name,'''') as name, isnull(userid,0) as userId,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(messageUnAssigned),0) messageUnAssigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,

		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,msg.messageid,
			 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
			 usuario.nombres as name,usuario.[User_Id] as userid,
			 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
			 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
			 case when msg.messagestatusid = 3 then 1 else 0 end actives,
			 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
			 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
			 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
			 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
			 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
			 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
			 case when msg.messagestatusid = 13 then 1 else 0 end emailSpam,
			 sum(case when msgun.messageid is null then 0 else 1 end) messageUnAssigned,
			 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
			 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
			 msg.twait twait,
			 msg.twait + msg.tretention + msg.tresponse tatention,
			 msg.twrapup twrapup
			 from [message] msg
			 inner join [conversation] conv on msg.conversationId = conv.conversationId
			 left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
			 left join ccusers usuario on usuario.User_id = msg.userid
			 left join messageUnAssigned msgun on msg.UserId=msgun.UserId and msgun.messageId = msg.messageId
			 where  msg.userId>0 and msg.date >= @from AND msg.date < @to
			 group by msg.messageid,msg.date,inbo.descripcion,inbo.inbound_id,usuario.nombres,usuario.[User_Id],msg.messagestatusid,msg.tqueue,
			 msg.twait, msg.tretention, msg.tresponse, msg.twrapup, msg.tSend

			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId

end
	'
	EXEC(@sql)

	
	
	set @process = 'Alter SP --ccspRepEmailDetail CW-976'
	set @Sql= '
ALTER procedure [dbo].[ccspRepEmailDetail]
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
	case when msg.messagestatusid = 1 then ''systemTranslated_Download_emails_from_server''
	when msg.messagestatusid = 2 then ''systemTranslated_Assign_message_to_agent''
	when msg.messagestatusid = 3 then ''systemTranslated_Read_the_message_agent''
	when msg.messagestatusid = 4 then ''systemTranslated_Unassign_message_to_agent''
	when msg.messagestatusid = 5 then ''systemTranslated_Message_answered_by_agent''
	when msg.messagestatusid = 6 then ''systemTranslated_Message_sent_to_the_client''
	when msg.messagestatusid in (7,8,9) then ''systemTranslated_Message_rejected_for_server''
	when msg.messagestatusid = 10 then ''systemTranslated_conversation_closed_for_system''
	when msg.messagestatusid = 13 then ''systemTranslated_Message_email_Spam''	
	when msg.messagestatusid = 11 then ''systemTranslated_Close_conversation_for_agent'' else '''' end statusMail,

	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,msg.messageId,
	msg.messagestatusid messagestatusid,
	isnull(datediff(second,msg.[date],isnull(msg.tqueue,getdate())),0) tQueue, msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	isnull(datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend),0) tsent,
	datepart(yyyy,date) [year],
	datepart(mm,date) [mounth],
	datepart(dd,date) [day],
	datepart(hh,date) [hour],
	datepart(mi,date) [minute],
	msg.tresponse as tfocus
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId left join [ccInbound] inbo
	on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
	where msg.date >= @from AND msg.date < @to
	order by date,msg.conversationId,msg.messageId

end
	'
	EXEC(@sql)

	
	
	set @process = 'Alter SP --ccspRepEmailGeneral CW-976'
	set @Sql= '
ALTER procedure [dbo].[ccspRepEmailGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailGeneral with(rowlock) where date >= @from AND date < @to

	insert into RepEmailGeneral
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),isnull(descripcion,'''') descripcion ,inboundid,
	case max(messagestatusid) when 1 then ''systemTranslated_Download_emails_from_server''
	when 2 then ''systemTranslated_Assign_message_to_agent''
	when 3 then ''systemTranslated_Read_the_message_agent''
	when 4 then ''systemTranslated_Unassign_message_to_agent''
	when 5 then ''systemTranslated_Message_answered_by_agent''
	when 6 then ''systemTranslated_Message_sent_to_the_client''
	when 7 then ''systemTranslated_Message_rejected_for_server''
	when 8 then ''systemTranslated_Message_rejected_for_server''
	when 9 then ''systemTranslated_Message_rejected_for_server''
	when 10 then ''systemTranslated_conversation_closed_for_system''
	when 13 then ''systemTranslated_Message_email_Spam''
	when 11 then ''systemTranslated_Close_conversation_for_agent'' else '''' end statusMail,



	isnull(max(messagestatusid),0) messagestatusid,
	isnull(min(mailClient),'''') mailClient,
	conversationId, isnull(sum(tQueue),0) as [tQueueMultimedia],
	isnull(sum(twait),0) as  [twaitMultimedia], isnull(sum(tAtentionMultimedia),0) tAtentionMultimedia, isnull(sum(twrapup),0) twrapup,
	isnull(sum(tsent),0) tsent,
	datepart(yyyy,min(date)) [year],
	datepart(mm,min(date)) [mounth],
	datepart(dd,min(date)) [day],
	datepart(hh,min(date)) [hour],
	datepart(mi,min(date)) [minute],
	sum(tFocus) as tFocus
from(

select
	msg.date date,
	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue)  end tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else
		datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent
	,msg.tresponse as tFocus
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId
	inner join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	inner join ccusers usuario on usuario.User_id = msg.userid
	where msg.date >= @from AND msg.date < @to
	)x
	group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion,inboundid,conversationId

end
	'
	EXEC(@sql)



	set @process = ''
	set @Sql= ''
	EXEC(@sql)


	if @actualVersion  = @version - 1
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