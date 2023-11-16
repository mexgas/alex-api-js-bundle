/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.37

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
SET @versionfix = 40
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
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

	-----------------------------------------------------BEGIN Ivan Martin  K002083, K002084, K002085, K002086, K002087 -----------------------------------------------------------------

	-- BEGIN IVAN MARTIN K002083 feature/IM-DEV1-356-Global_Ids Global Ids para WhatsApp de entrada y de salida -----------------------------------------------------------------
	SET @process = 'K002083 Creación de nueva tabla ccWhatsAppGlobalIds para ids globales';
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ccWhatsAppGlobalIds'')
				BEGIN
					CREATE TABLE ccWhatsAppGlobalIds (
				    GlobalId BIGINT IDENTITY(1,1) NOT NULL,
					AssociatedNumber VARCHAR (30) NOT NULL,
					ClientNumber VARCHAR(30) NOT NULL, 
					FirstMessageDateFromAgent DATETIME,
					FirstMessageConversationIdFromAgent INT,
					FirstMessageConversationTypeFromAgent TINYINT,
					IsBilled BIT NOT NULL,
					PRIMARY KEY (GlobalId));
				END';
	EXEC (@sql);

	SET @process = 'K002083 Creación de nueva tabla para relacionar conversaciones con ids globales.';
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ccWhatsAppGlobalIdsRelationship'')
				BEGIN
					CREATE TABLE ccWhatsAppGlobalIdsRelationship (
				    GlobalId BIGINT NOT NULL,
				    ConversationId INT NOT NULL,
					ConversationType TINYINT NOT NULL,  -- ENTRADA, SALIDA, CHATBOT
					PRIMARY KEY (GlobalId, ConversationId, ConversationType),
					FOREIGN KEY (GlobalId) REFERENCES ccWhatsAppGlobalIds(GlobalId));
				END';
	EXEC (@sql);

	SET @process = 'K002083 Creación de indices para columnas ([AssociatedNumber], [ClientNumber], [FirstMessageDateFromAgent])';
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = N''INDEX_WhatsAppGlobalIds'' AND object_id = OBJECT_ID(N''ccWhatsAppGlobalIds''))
				BEGIN
				    CREATE NONCLUSTERED INDEX INDEX_WhatsAppGlobalIds ON [dbo].ccWhatsAppGlobalIds([AssociatedNumber], [ClientNumber], [FirstMessageDateFromAgent])
				END';
	EXEC (@sql);

	SET @process = 'K002083 DROP PROCEDURE ccsp_WhatsAppGlobalIds'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppGlobalIds'')
			    BEGIN
			        DROP PROCEDURE ccsp_WhatsAppGlobalIds;
			    END'
	EXEC(@sql)

	SET @process = 'K002083 Se crea nuevo SP para insertar y actualizar ids globales';
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppGlobalIds]  
					 @ConversationType TINYINT = -1,
					 @ConversationId INT = 0,
					 @MessageId VARCHAR(MAX) = '''',
					 @AssociatedNumber VARCHAR (30), 
					 @ClientNumber VARCHAR(30)
				AS  
				SET NOCOUNT ON;  

					IF @ConversationType = 0 AND NOT EXISTS(SELECT 1 FROM ccWhatsAppConversations WHERE conversationId = @ConversationId)
					BEGIN
						RAISERROR(''ERROR. No existe una conversación de entrada con el id especificado'', 18, 1);
						RETURN(0);
					END;
					ELSE IF @ConversationType = 1 AND NOT EXISTS(SELECT * FROM ccWhatsAppConversationsOut WHERE conversationId = @ConversationId)
					BEGIN
						RAISERROR(''ERROR. No existe una conversación de salida con el id especificado'', 18, 1);
						RETURN(0);
					END;
					ELSE
					BEGIN
						DECLARE @originType VARCHAR(20) = '''';
						DECLARE @firstMessageDateFromAgent DATETIME = NULL;
						DECLARE @messageStatus VARCHAR(20) = '''';
						DECLARE @firstMessageConversationIdFromAgent INT = NULL;
						DECLARE @firstMessageConversationTypeFromAgent TINYINT = NULL;
						DECLARE @isBilled BIT = 0;

						IF @ConversationType = 0 
						BEGIN
							SET @originType = (SELECT originType FROM ccWAMessagesConversations WHERE messageId = @MessageId);
							SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
							FROM ccWAMessagesConversations
							WHERE messageId = @MessageId AND @originType = ''Agent'';
						END;
						ELSE 
						BEGIN
							SET @originType = (SELECT originType FROM ccWAMessagesConversationsOut WHERE messageId = @MessageId);
							SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
							FROM ccWAMessagesConversationsOut
							WHERE messageId = @MessageId AND @originType = ''Agent'';
						END;

						DECLARE @globalId INT = (SELECT MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber);

						IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'')
						BEGIN
							SET @firstMessageConversationIdFromAgent = @ConversationId;
							SET @firstMessageConversationTypeFromAgent = @ConversationType;
							SET @isBilled = 1;
						END
						ELSE
						BEGIN
							SET @firstMessageDateFromAgent = NULL
						END

						IF @globalId IS NULL
						BEGIN
							INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
							VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

							SET @globalId = SCOPE_IDENTITY();
						END

						DECLARE @TempFirstMessageDate DATETIME = (SELECT FirstMessageDateFromAgent FROM ccWhatsAppGlobalIds WHERE GlobalId = @globalId);
						
						--Update if message status changes
						IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'') AND @globalId IS NOT NULL
						BEGIN
							UPDATE ccWhatsAppGlobalIds SET IsBilled = 1 WHERE GlobalId = @globalId
						END

						IF DATEDIFF(HOUR, @TempFirstMessageDate, GETDATE()) >= 24 
						BEGIN 
							INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
							VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

							SET @globalId = SCOPE_IDENTITY();	
						END

						-- If the message is from agent update the date 
						IF @originType = ''Agent'' AND @TempFirstMessageDate IS NULL
						BEGIN
							UPDATE ccWhatsAppGlobalIds SET FirstMessageDateFromAgent = @firstMessageDateFromAgent,
														   FirstMessageConversationIdFromAgent =  @ConversationId,
														   FirstMessageConversationTypeFromAgent = @ConversationType,
														   IsBilled = @isBilled
							WHERE GlobalId = @globalId;
						END
						-- Insert into ccWhatsAppGlobalIdsRelationship
						IF @globalId != 0 AND NOT EXISTS(SELECT GlobalId FROM ccWhatsAppGlobalIdsRelationship WHERE GlobalId = @globalId AND ConversationId = @ConversationId AND @ConversationType = ConversationType)
						BEGIN
							INSERT INTO ccWhatsAppGlobalIdsRelationship(GlobalId, ConversationId, ConversationType)
							VALUES (@globalId, @ConversationId, @ConversationType)
						END

						RETURN(1)
					END
				SET NOCOUNT OFF';
	EXEC (@sql);

	-- END IVAN MARTIN K002083 feature/IM-DEV1-356-Global_Ids Global Ids para WhatsApp de entrada y de salida -----------------------------------------------------------------

	-- BEGIN K002085 - Detalle de conversaciones de salida y K002086-Conversaciones de salida por campaña WhatsApp -----------------------------------------------------------------

	SET @process = 'K002085 y K002086 Se cambia Menu existente de WhatsApp para tener entrada y salida'
	SET @sql = 'IF EXISTS(SELECT 0 FROM ccMenus WHERE menu_id = 12000)
				BEGIN
					UPDATE ccMenus SET menu_descrip = ''WhatsApp de entrada|Inbound WhatsApp'',
									   		release = ''01fca49b34e37efff01faa6808ea7fb401278e754bbe713c58f023954497efc8537ce0372c9ec527e453b7d0af15f0ca''
					WHERE menu_id = 12000;
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea el nuevo menu para WhatsApp de salida'
	SET @sql = 'IF NOT EXISTS(SELECT 0 FROM ccMenus WHERE menu_id = 14000)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
					VALUES (14000, ''WhatsApp de salida|Outbound WhatsApp'', 14000, ''A'', 7, 3, '''', ''dfbbefd3a73055deff2fb6a4a7e9bda39e35164486951e90365adf857c5582516bacc0673d09950c7b8bc7e63f2956b3'');
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea submenu para Detalle de conversaciones'
	SET @sql = 'IF NOT EXISTS(SELECT 0 FROM ccMenus WHERE menu_id = 14010)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
					VALUES (14010, ''Detalle de conversaciones|Conversations Detail'', 14000, ''B'', 7, 3, '''', ''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370'');
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea submenu para Conversaciones por campaña'
	SET @sql = 'IF NOT EXISTS(SELECT 0 FROM ccMenus WHERE menu_id = 14020)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
					VALUES (14020, ''Conversaciones por campaña|Conversations by Campaign'', 14000, ''B'', 7, 3, '''', ''2605c8244920fb599fb936a4bf94521a7284d5e414815e8ef15fa8f6b0040db16a54ce29b02250a22a8cb87c41c6f3b30e3860a31b59d733442bb174a555b7b2'');
				END'
	EXEC(@sql)

	-- END K002085 - Detalle de conversaciones de salida y K002086-Conversaciones de salida por campaña WhatsApp -----------------------------------------------------------------

	-----------------------------------------------------END Ivan Martin  K002083, K002084, K002085, K002086, K002087 -----------------------------------------------------------------
	
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