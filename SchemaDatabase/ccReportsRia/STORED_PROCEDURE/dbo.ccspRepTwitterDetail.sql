CREATE procedure [dbo].[ccspRepTwitterDetail]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterDetail with(rowlock)	where date >= @from AND date < @to

	insert into RepTwitterDetail
	select msg.date date,
	case when msg.messagestatusid = 1 then 'systemTranslated_Download_emails_from_server'
	when msg.messagestatusid = 2 then 'systemTranslated_Assign_message_to_agent'
	when msg.messagestatusid = 3 then 'systemTranslated_Read_the_message_agent'
	when msg.messagestatusid = 4 then 'systemTranslated_Unassign_message_to_agent'
	when msg.messagestatusid = 5 then 'systemTranslated_Message_answered_by_agent'
	when msg.messagestatusid = 6 then 'systemTranslated_Message_sent_to_the_client'
	when msg.messagestatusid in (7,8,9) then 'systemTranslated_Message_rejected_for_server'
	when msg.messagestatusid = 10 then 'systemTranslated_conversation_closed_for_system'
	when msg.messagestatusid = 11 then 'systemTranslated_Close_conversation_for_agent' else '' end statusMail,
	conv.screenNameClient screenNameClient, isnull(inbo.descripcion,'') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationTwitterId conversationid,msg.messageOutTwitterId,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue) end as tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent,
	msg.tresponse as tfocus,
	datepart(yyyy,date) [year],
	datepart(mm,date) [mounth],
	datepart(dd,date) [day],
	datepart(hh,date) [hour],
	datepart(mi,date) [minute]
	from [messageOutTwitter] msg
	inner join [conversationTwitter] conv on msg.conversationTwitterId = conv.conversationTwitterId
	left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid
	left join messageUnAssingedTwit msgun on msg.messageOutTwitterId = msgun.messageOutTwitterId
	where msg.date >= @from AND msg.date < @to
	order by date,msg.conversationTwitterId,msg.messageOutTwitterId

end