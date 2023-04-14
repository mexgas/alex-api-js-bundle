/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 8
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN IVAN K020099 OUTBOUND TEMPLATES ------------------------------

		SET @process = 'IM-K020099 Create table for templates (ccWhatsAppOutboundTemplates)'
		SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ccWhatsAppOutboundTemplates'')
					BEGIN
						CREATE TABLE ccWhatsAppOutboundTemplates (
							TemplateId INT NOT NULL,
							Category VARCHAR(25) NOT NULL,
							TemplateName VARCHAR(500),
							LanguageCode VARCHAR(10),
							Status BIT,
							AsociatedNumber VARCHAR(30),
							Type VARCHAR(50),
							Format VARCHAR(15),
							Body VARCHAR(MAX),
							PRIMARY KEY (TemplateId)
						);
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Drop procedure if exists'
		SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppOutboundTemplates'')
					BEGIN
						DROP PROCEDURE ccsp_WhatsAppOutboundTemplates;
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Create new procedure for WhatsApp Outbound Templates'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppOutboundTemplates] 
					@Action SMALLINT, 
					@TemplateName VARCHAR(500) = '''' 
					AS  
					SET NOCOUNT ON;  
					IF @Action = 0  -- Get all template information
					BEGIN
						SELECT TemplateName, LanguageCode, Type, Format, Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
					END
					IF @Action = 1  -- Get template body 
					BEGIN
						SELECT Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
					END
					RETURN(0)
					SET NOCOUNT OFF'
		EXEC(@sql)

		SET @process = 'IM-K020099 Add action 2 which gets template information to display in Agent UI (lines 163 to 171) '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
					@action             INT
					, @conversationId     INT         = 0
					, @campId			  INT		  = NULL        
					, @phoneCamp          VARCHAR(50) = NULL
					, @clientId           VARCHAR(25) = NULL
					, @conversationStatus SMALLINT    = 0
					, @tChatting          FLOAT       = 0
					, @tWrapUp            SMALLINT    = 0
					, @finishedBy         TINYINT     = 0
					, @onQueue            BIT         = NULL
					, @tQueue             SMALLINT    = 0
					, @tTimeout           INT         = 0
					, @disposition        SMALLINT    = 0
					, @subDisposition     SMALLINT    = 0
					, @agentId            INT         = 0

					AS
					BEGIN
						SET NOCOUNT ON;
					    
						declare @conversationIdTemporal     INT;

					IF @action = 1 BEGIN --new Conversation
					    select @phoneCamp= number from ccWhatsAppNumbers where camp_id= @campId
							
						if @phoneCamp is null or @phoneCamp='''' begin
							select 0 as [ConversationId],0 as [MessageId]
							return(0)
						end

						if not exists (select * from ccWhatsAppConversationsOut where phoneCamp = @phoneCamp and clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) begin
							if not exists (select * from ccWhatsAppConversations where phoneACD = @phoneCamp and clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) begin
								INSERT INTO [ccWhatsAppConversationsOut]
								([camId] , [phoneCamp], clientId, conversationStatus, tChatting
								, tWrapUp, finishedBy, onQueue, tQueue, requestDate
								, tTimeout, disposition, subDisposition, agentId)
								VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
								@onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId);
					    
								SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
								SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
							end
							else begin
								select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username 
								FROM ccInbound A INNER JOIN ccWhatsAppConversations B 
								ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
								INNER JOIN ccUsers C ON B.agentId = C.User_id;
							end  
						end
						else begin
							select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username
							FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B 
							ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
							INNER JOIN ccUsers C ON B.agentId = C.User_id;
						end  
					END 
					IF @action = 2 -- Get Outbound Templates
					BEGIN
						IF @campId IS NOT NULL
						BEGIN
							DECLARE @AsociatedNumber VARCHAR(30) = (SELECT number from ccWhatsAppNumbers WHERE @campId = camp_id);
							SELECT * FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
						END
					END
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099'
		SET @sql = ''
		EXEC(@sql)

		-------------------------------------------- END IVAN K020099 OUTBOUND TEMPLATES   ------------------------------
		
----------------------------------------------------------------------------------------------------------------------------
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
