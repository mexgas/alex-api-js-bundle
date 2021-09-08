CREATE PROCEDURE [dbo].[ccsp_RIAChatDispositions] @action         SMALLINT
                                               , @chatId         SMALLINT
                                               , @disposition    SMALLINT
                                               , @subDisposition SMALLINT
                                               , @wrapUpTime     SMALLINT = 0
AS
     IF @action = 1
     BEGIN

         UPDATE ccRIAChats
                SET
                    disposition = @disposition
                  , subDisposition = @subDisposition
                  , tWrapUp = @wrapUpTime
         WHERE chatId = @chatId;
         
		 exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=1
		 		 

     END;