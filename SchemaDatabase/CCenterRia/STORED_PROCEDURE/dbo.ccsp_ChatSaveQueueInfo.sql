CREATE PROCEDURE ccsp_ChatSaveQueueInfo 	
@action int ,
@chatId int ,
@timeQueued int 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF @action = 1 
	BEGIN
		UPDATE dbo.ccRiaChats SET tQueue = @timeQueued, onQueue = 1 WHERE chatId = @chatId ;			
	END
END