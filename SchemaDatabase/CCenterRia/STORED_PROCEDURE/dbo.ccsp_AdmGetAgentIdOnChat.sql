CREATE PROCEDURE  [dbo].[ccsp_AdmGetAgentIdOnChat]
			@chat_id int
			AS
			BEGIN
				select userId from ccRIAChats where chatId=@chat_id
			END