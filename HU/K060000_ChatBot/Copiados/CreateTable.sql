use CCenterRIA;

if not exists(select * from sys.tables where name='ccChatBotConversationsResult') begin
CREATE TABLE [dbo].[ccChatBotConversationsResult](
	[chatBotId] [int] NOT NULL,
	[FinishedByClient] [int] NOT NULL,
	[FinishedBySystemFail] [int] NOT NULL,
	[TransferWhatsAppCampaign] [int] NOT NULL,
	[TransferCallBack] [int] NOT NULL,
	[ActiveConversations] [int] NOT NULL
) 
end

--drop table ccChatBotConversationsAbandoned
if not exists(select * from sys.tables where name='ccChatBotConversationsAbandoned') begin
CREATE TABLE [dbo].[ccChatBotConversationsAbandoned](
	[chatBotId] [int] NOT NULL ,
	[ConversationId] [int] NOT NULL,
	[Date] [datetime] NOT NULL,	
	primary key ([chatBotId],[ConversationId])
) 
end