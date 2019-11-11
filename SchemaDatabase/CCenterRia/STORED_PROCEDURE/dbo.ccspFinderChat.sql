CREATE PROCEDURE [dbo].[ccspFinderChat]
@action int,@ids nvarchar(max)=null

AS
BEGIN

SET NOCOUNT ON

declare @sql nvarchar(max)
if @action = 1 begin
	set @sql='select chatId,clientName,userId as agentId from ccRIAChats where chatId in('+@ids+')'
	exec (@sql)
end
--action 2 es para grabadora
else if @action = 3 begin
	set @sql='select conv.conversationId,max(msg.messageId) as messageId,conv.mailClient,conv.mailInbound
from conversation conv
inner join message msg on msg.conversationId=conv.conversationId
where conv.conversationId in('+@ids+')
group by conv.conversationId,conv.mailClient,conv.mailInbound'
	exec (@sql)
end
else if @action = 4 begin
	set @sql='select conv.conversationTwitterId,max(msg.messageOutTwitterId) as messageId,
conv.screenNameClient,conv.screenNameInbound
from conversationTwitter conv
inner join messageOutTwitter msg on msg.conversationTwitterId=conv.conversationTwitterId
where conv.conversationTwitterId in('+@ids+')
group by conv.conversationTwitterId,conv.screenNameClient,conv.screenNameInbound'
	exec (@sql)
end
--print (@sql)


END