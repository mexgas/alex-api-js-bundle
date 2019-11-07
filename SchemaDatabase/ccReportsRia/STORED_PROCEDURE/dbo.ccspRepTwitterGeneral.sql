CREATE procedure [dbo].[ccspRepTwitterGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterGeneral with(rowlock) where date >= @from AND date < @to

	insert into RepTwitterGeneral
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+':00',121),isnull(descripcion,'') descripcion ,inboundid,
	case max(messagestatusid) when 1 then 'systemTranslated_Download_emails_from_server'
	when 2 then 'systemTranslated_Assign_message_to_agent'
	when 3 then 'systemTranslated_Read_the_message_agent'
	when 4 then 'systemTranslated_Unassign_message_to_agent'
	when 5 then 'systemTranslated_Message_answered_by_agent'
	when 6 then 'systemTranslated_Message_sent_to_the_client'
	when 7 then 'systemTranslated_Message_rejected_for_server'
	when 8 then 'systemTranslated_Message_rejected_for_server'
	when 9 then 'systemTranslated_Message_rejected_for_server'
	when 10 then 'systemTranslated_conversation_closed_for_system'
	when 11 then 'systemTranslated_Close_conversation_for_agent' else '' end statusMail,
	isnull(max(messagestatusid),0) messagestatusid,
	isnull(min(screenNameClient),'') as screenNameClient,
	conversationId, isnull(sum(tQueue),0) as [tQueueMultimedia],
	isnull(sum(twait),0) as  [twaitMultimedia], isnull(sum(tAtentionMultimedia),0) tAtentionMultimedia, isnull(sum(twrapup),0) twrapup,
	isnull(sum(tsent),0) tsent,
	sum(tfocus) as tfocus,
	datepart(yyyy,min(date)) [year],
	datepart(mm,min(date)) [mounth],
	datepart(dd,min(date)) [day],
	datepart(hh,min(date)) [hour],
	datepart(mi,min(date)) [minute]
from(

select
	msg.date date,
	conv.screenNameClient screenNameClient, isnull(inbo.descripcion,'') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationTwitterId conversationid,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue) end as tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent,
	msg.tresponse as tfocus
	from [messageOutTwitter] msg
	inner join [conversationTwitter] conv on msg.conversationTwitterId = conv.conversationTwitterId
	left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid
	where msg.date >= @from AND msg.date < @to
	)x
	group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+':00',121),descripcion,inboundid,conversationId
end