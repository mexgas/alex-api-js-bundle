/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 28
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
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

	------------------------------------------- BEGIN DM ----------------------------------------
	SET @process = 'K066021 Se añade columna ConversationReopened bit a tabla ccWhatsAppConversationsOut'
	SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''ConversationReopened'' AND Object_ID = Object_ID(N''dbo.ccWhatsAppConversationsOut''))
	BEGIN
		ALTER TABLE ccWhatsAppConversationsOut ADD ConversationReopened BIT DEFAULT 0 WITH VALUES;
	END'
	EXEC(@sql)

	SET @process = 'Se elimina SP ccsp_ConversationOutWASave'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_ConversationOutWASave'')
    BEGIN
        DROP PROCEDURE ccsp_ConversationOutWASave;
    END
    '
	EXEC(@sql)

    SET @process = '- Se agrega variable @ConversationReopened BIT
					- al momento de crear una conversación por plantilla se inserta a la tabla de conversaciones si la conversación fue reabierta en  columna ConversationReopened '
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
	@action             INT
	, @conversationId     INT         = 0
	, @campId             INT         = NULL        
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
	, @ConversationReopened BIT       = 0

	AS
	BEGIN
	SET NOCOUNT ON;
                        
	declare @conversationIdTemporal     INT;
	declare @metaId int

	IF @action = 1 BEGIN --new Conversation
	SELECT @phoneCamp = 
		ISNULL(
			(SELECT TOP 1 number FROM ccWhatsAppNumbers WHERE camp_id = @campId),
			(SELECT TOP 1 number FROM ccMetawhatsAppNumbers WHERE Cam_Id = @campId)
		);

	IF @phoneCamp IS NULL OR @phoneCamp = '''' BEGIN
		SELECT 0 AS [ConversationId], 0 AS [MessageId];
		RETURN(0);
	END;

	DECLARE @dateNow DATETIME;
	SET @dateNow = DATEADD(HOUR, -23, GETDATE());


	declare @existsConversationOut bit
	declare @existsConversation bit
	set @existsConversationOut =0
	set @existsConversation =0

	UPDATE ccWhatsAppConversationsOut
	SET finishedBy = 2, conversationStatus = 17
	WHERE finishedBy = 0 AND requestDate <= @dateNow
	AND phoneCamp = @phoneCamp AND clientId = @clientId;

	IF EXISTS (SELECT 1 FROM ccWhatsAppConversationsOut WITH(NOLOCK) 
				   WHERE phoneCamp = @phoneCamp AND clientId = @clientId AND finishedBy = 0 AND requestDate>= @dateNow) 
	BEGIN       
		select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, isnull(C.Login,''N/A'') Username
		,B.conversationId as conversationIdExists
		FROM ccCamps A 
		INNER JOIN ccWhatsAppConversationsOut B WITH(NOLOCK) ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
		LEFT JOIN ccUsers C ON B.agentId = C.User_id;
		RETURN(0);
	END 
    
	if exists (select 1 from ccWhatsAppConversations with(nolock) where
	phoneACD = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate >= @dateNow) 
	begin       
		select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, isnull(C.Login,''N/A'') Username
		,B.conversationId as conversationIdExists
		FROM ccInbound A 
		INNER JOIN ccWhatsAppConversations B WITH(NOLOCK) ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
		LEFT JOIN ccUsers C ON B.agentId = C.User_id;
		return(0);
	end 
    
	 INSERT INTO [ccWhatsAppConversationsOut]
	([camId] , [phoneCamp], clientId, conversationStatus, tChatting
	, tWrapUp, finishedBy, onQueue, tQueue, requestDate
	, tTimeout, disposition, subDisposition, agentId, ConversationReopened)
	VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
	@onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId, @ConversationReopened);
                        
	SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
	SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
		 
	END
	ELSE IF @action = 2 -- Get Outbound Templates
	BEGIN
    
		DECLARE @AsociatedNumber VARCHAR(30) 
		SELECT @AsociatedNumber= number from ccWhatsAppNumbers WHERE @campId = camp_id
		if @AsociatedNumber is not null begin
			SELECT cast(TemplateId as bigint),Category,TemplateName,LanguageCode,Status,AsociatedNumber
			,[Type],[Format],Body, 0 IsMeta
			FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
		end
		else begin
			SELECT @MetaId= MetaId from ccMetawhatsAppNumbers WHERE Cam_Id= @campId
			SELECT 
			cast(Id as bigint) as TemplateId,Category,TemplateName,LanguageCode as LanguageCode
			,A.StatusCW [Status],B.Number as AsociatedNumber, 1 IsMeta
			,''BODY'' [Type],''TEXT'' [Format],body as Body
			,header,footer
			FROM ccMetaWAOutboundTemplates  A 
			inner join ccMetawhatsAppNumbers B on A.MetaId=B.MetaId
			WHERE A.MetaId = @MetaId AND A.StatusCW = 1
			and A.body NOT LIKE ''%{{%'' 		AND A.body NOT LIKE ''%[[%''
			AND ISNULL(A.header, '''') NOT LIKE ''%{{%'' AND ISNULL(A.header, '''') NOT LIKE ''%[[%'' -- quitar plantillas donde el header tiene variables
			AND ISNULL(A.buttons, '''') NOT LIKE ''%{{%'' AND ISNULL(A.buttons, '''') NOT LIKE ''%[%'' -- quitar plantillas donde el buttons tiene variables de url
			and A.[Status]=''APPROVED''
			;
		end
    
	END
	END'
	EXEC(@sql)
	SET @process = 'K072001 Add setting'
	SET @sql = '
	if not exists(select * from ccSettings2 where setting_id=280 )
	begin
	insert into  ccSettings2 (setting_id,	valor,	descripcion	,Status,	Tipo,	detalle	,description, bLoadSettings) values
	(280,	''3'',	''Reintentos de validación automática de telefonía (default: 3, min: 1)'',	1,	''AGT'',	''Reintentos de validación automática de telefonía (default: 3, min: 1)'',
	''Retries for automatic telephony validation (default: 3, min: 1)'',1	)
	end'
	EXEC(@sql)
    -------------------------------------------- END DM -----------------------------------------
	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
