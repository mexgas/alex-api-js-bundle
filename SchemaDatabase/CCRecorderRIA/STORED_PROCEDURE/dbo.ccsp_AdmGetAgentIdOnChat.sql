create PROCEDURE [dbo].[ccsp_AdmGetAgentIdOnChat]
			@chat_id int 
			AS
			BEGIN

			SET NOCOUNT ON;
			select userId from ccRIAChats where chatId=@chat_id
			END