CREATE PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia]

	@action int,
	@conversationId int=0,
	@disposition smallint=0,
	@subDisposition smallint=0,
	@tWrapUp smallint=0,
	@mediaType smallint=0

AS
BEGIN
	
SET NOCOUNT ON;
	
	IF @action = 1 BEGIN --Califica la conversación y pone el tiempo Notas
		DECLARE @Temp NVARCHAR(1000)= N'UPDATE ' + (SELECT CASE @mediaType
						WHEN 5 THEN 'ccRIAWhatsAppConversations'
						WHEN 6 THEN 'chat'
						ELSE ''
					END AS MediaTypeString) + 
					' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;' 
		EXEC sp_executesql @temp, N'@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT', @disposition, @subDisposition, @tWrapUp, @conversationId;
	END
END