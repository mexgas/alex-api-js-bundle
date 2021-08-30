/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 22
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY
	
	set @process = 'CW-5697 Valida si existe ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql)

	set @process = 'CW-5697 Crea SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave]

	@action int,
	@conversationId int=0,
	@inboundId smallint=null,
	@phoneACD varchar(50)= null,
	@clientId varchar(25)= null,
	@conversationStatus smallint=0,
	@tChatting smallint=0,
	@tWrapUp smallint=0,
	@finishedBy tinyint = 0,
	@onQueue bit = null,
	@tQueue smallint = 0,
	@tTimeout int = 0,
	@clientName varchar(100)= null,
	@disposition smallint=0,
	@subDisposition smallint=0

AS
BEGIN
	DECLARE @isEndConversation bit
	DECLARE @meanContactTypeId smallint

	SET @meanContactTypeId = 1
SET NOCOUNT ON;

	IF @action = 1 BEGIN --new Conversation
		IF NOT EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWhatsAppConversations](
												inboundId, phoneACD, clientId, conversationStatus, tChatting, 
												tWrapUp, finishedBy, onQueue, tQueue, tTimeout, clientName, disposition, subDisposition) values 
											   (@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, 
												@tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @clientName, @disposition, @subDisposition)
			SELECT @conversationId=SCOPE_IDENTITY()
			SELECT @conversationId as ConversationId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS ConversationId
			RETURN (0)
		END
	END

	IF @action = 2 BEGIN --save conversation Times
		Update ccWhatsAppConversations 
		set tChatting = DATEDIFF(ss,conversationDate,getdate()), 
			conversationStatus = @conversationStatus, finishedBy = 1,
			tConversation = DATEDIFF(ss,requestDate,getdate()) 
		where conversationId = @conversationId  
	END
	
	IF @action = 3 BEGIN --save conversation Status
		Update ccWhatsAppConversations 
		set conversationDate = getdate(),
			conversationStatus = @conversationStatus
		where conversationId = @conversationId  
	END
END'
	
	EXEC(@sql)
	
    
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END