CREATE PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia] @action         INT
                                                      , @conversationId bigint      = 0
                                                      , @disposition    SMALLINT = 0
                                                      , @subDisposition SMALLINT = 0
                                                      , @tWrapUp        SMALLINT = 0
                                                      , @mediaType      SMALLINT = 0
AS
BEGIN

    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --Califica la conversación y pone el tiempo Notas
        DECLARE @Temp NVARCHAR(1000),@type int
		set @type=CASE @mediaType WHEN 6 then 1 else @mediaType end ---revisar tabla ccfinderServices

		set @Temp= N'UPDATE ' +
                (SELECT CASE @mediaType WHEN 5
                        THEN 'ccWhatsAppConversations' WHEN 6
                        THEN 'chat' ELSE ''
                        END AS MediaTypeString
                ) + ' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;';
        EXEC sp_executesql
             @temp
           , N'@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT'
           , @disposition
           , @subDisposition
           , @tWrapUp
           , @conversationId;


		exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=@type

    END;
END;