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
	

	------------------------------------------- BEGIN Isaac ----------------------------------------

	SET @process = 'Delete sp ccsp_MetaWAOutboundTemplates - fix update template insert activity log'
	SET @sql = '
if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
begin
  DROP PROCEDURE ccsp_MetaWAOutboundTemplates;
end
	'
	EXEC(@sql)

	SET @process = 'Create sp ccsp_MetaWAOutboundTemplates - fix update template insert activity log'
	SET @sql = '
CREATE PROCEDURE ccsp_MetaWAOutboundTemplates
@action TINYINT = NULL,
@whatsAppTemplateID BIGINT = 0,
@id varchar(200) = NULL,
@Category varchar(50) = NULL,
@TemplateName varchar(512) = NULL,
@AllowCategoryChange tinyint = NULL,
@LanguageCode varchar(10)= NULL,
@Status varchar(200)= NULL, 
@header nvarchar(max)= null,
@body nvarchar(max) = null,
@footer nvarchar(max) = null,
@buttons nvarchar(max) = null,
@metaStatus varchar(30) = NULL,
@FilePath varchar(1024) = null,
@HistoryLog varchar(max) = null,
@campId SMALLINT = NULL,
@UserId	SMALLINT = 0,
@MetaId INT = 0,
@CreationDate DATETIME = NULL,
@headerLink nvarchar(max)= null
AS
BEGIN
    IF(@action = 1) -- get template by id
    BEGIN
        SELECT 
        cmwot.Id 
        ,cmwot.TemplateName AS Name
        ,cmwot.Status AS Status
        ,Category AS Category
        ,ISNULL(cmwot.notes, '''' ) AS Notes
        ,cmwot.header AS Header
        ,Body
        ,cmwot.footer AS Footer
        ,cmwot.buttons AS Buttons
        ,cmwot.LanguageCode
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,cmwot.FilePath
        ,cmwot.Status AS Status
		,cmwot.headerLink AS HeaderLink
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        WHERE cmwot.Id = @whatsAppTemplateID
    END
    ELSE IF(@action = 2)
    BEGIN
        SELECT cmwan.MetaId AS Id, cmwan.Number FROM dbo.ccMetaWhatsAppNumbers AS cmwan
        Left JOIN dbo.ccMetaWhatsAppConfigurations AS cmwac
        ON cmwan.MetaId = cmwac.Id
        WHERE cmwan.Status = 1
    END
    ELSE IF(@action = 3)
    BEGIN
        UPDATE ccMetaWAOutboundTemplates SET StatusCW = 0 WHERE Id = @whatsAppTemplateID
        SELECT @@ROWCOUNT;
        RETURN 0;
    END
    ELSE IF(@action = 4) --create
    BEGIN
        insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons,FilePath,MetaId,StatusCW,CreationDate,headerLink)
        values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons,@FilePath,@MetaId,1,@CreationDate,@headerLink)
    END
    ELSE IF(@action = 5) -- Get Template Config By Id
    BEGIN
        SELECT n.WAAccountId, n.Token, c.Url as [Url], t.TemplateName 
        FROM ccMetaWAOutboundTemplates t
        INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
        left JOIN ccMetaWhatsAppConfigurations c on c.Id = 2
        WHERE t.Id = @whatsAppTemplateID
        RETURN 0;
    END
    ELSE IF(@action = 6) -- update status to delete
    BEGIN
        DECLARE @newStatus bit = 1;
        IF(@metaStatus = ''DELETED'')
        BEGIN
            SET @newStatus = 0
        END
        UPDATE ccMetaWAOutboundTemplates SET 
        [Status] = @metaStatus, 
        StatusCW = @newStatus,
        RemovalDate = ISNULL(RemovalDate, GETDATE())
        WHERE Id = @whatsAppTemplateID
        AND [StatusCW] = 1;
        SELECT @@ROWCOUNT;
        RETURN 0;
    END
    ELSE IF(@action = 7) -- Get template campaigns associated
    BEGIN
        SELECT ISNULL(n.Cam_Id,0) as Cam_Id, ISNULL(n.Inbound_Id,0) AS Inbound_Id FROM ccMetaWAOutboundTemplates t
        INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
        left JOIN ccMetaWhatsAppConfigurations c on n.MetaId = c.Id
        WHERE t.Id = @whatsAppTemplateID
        RETURN 0;
    END
    ELSE IF (@action = 8) -- update template
    BEGIN
        DECLARE @tableHistoryLog TABLE (Id INT, Value VARCHAR(MAX))
        DECLARE @areaName VARCHAR(50),
                @login VARCHAR(50)

        SELECT
            @areaName = ca.AreaName,
            @login = cu.Login
        FROM ccUsers cu
        INNER JOIN ccRIACat_Areas ca with(nolock) ON cu.IDArea = ca.IDArea
        WHERE cu.User_id = @UserId

        INSERT INTO @tableHistoryLog 
        SELECT tb.Id, tb.Value
        FROM dbo.fn_RIASplitDelimited(@HistoryLog, ''|'') tb


        -- insert into activity log table and update template data
        IF (@header IS NULL OR LEN(@header) = 0) AND (SELECT LEN(ISNULL(header,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when header is null or '''' and before update header contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'',''COMMON_NONE_O'',@TemplateName)
        END
		ELSE IF (@header IS NOT NULL OR LEN(@header) <> 0) AND (SELECT header FROM ccMetaWAOutboundTemplates WHERE Id = @Id) IS NULL -- when header isnt null or '''' and before update header is null
		BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT
				@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'', Value, @TemplateName
			FROM @tableHistoryLog
			WHERE Id = 2 
		END

        IF (@footer IS NULL OR LEN(@footer) = 0) AND (SELECT LEN(ISNULL(footer,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when footer is null or '''' and before update footer contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'',''COMMON_NONE_O'',@TemplateName)
        END
		ELSE IF (@footer IS NOT NULL OR LEN(@footer) <> 0) AND (SELECT footer FROM ccMetaWAOutboundTemplates WHERE Id = @Id) IS NULL -- when footer isnt null or '''' and before update footer is null
		BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT
				@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'', Value, @TemplateName
			FROM @tableHistoryLog
			WHERE Id = 4 
		END

        IF (@buttons IS NULL OR LEN(@buttons) = 0) AND (SELECT LEN(ISNULL(buttons,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when buttons is null or '''' and before update buttons contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'',''COMMON_NONE_O'',@TemplateName)
        END
		ELSE IF (@buttons IS NOT NULL OR LEN(@buttons) <> 0) AND (SELECT buttons FROM ccMetaWAOutboundTemplates WHERE Id = @Id) IS NULL -- when buttons isnt null or '''' and before update buttons is null
		BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT
				@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'', Value, @TemplateName
			FROM @tableHistoryLog
			WHERE Id = 5
		END
        
        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccMetaWAOutboundTemplates'', @columnNameId=''Id'', @valueId= @Id, @userId= 1
        Create table #ccMetaWAOutboundTemplates 
        (
            columnInfo VARCHAR(MAX),
            dataInfo VARCHAR(MAX),
            identifierInfo VARCHAR(MAX)
        )

        UPDATE ccMetaWAOutboundTemplates
        SET Category = @Category,
            header = @header,
            body = @body,
            footer = @footer,
            buttons = @buttons,
            FilePath = @FilePath,
			Status = ''PENDING'',
			headerLink = @headerLink
        WHERE Id = @Id

        EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccMetaWAOutboundTemplates'', @columnNameId = ''Id'', @valueId = @Id, @userId = 1,  @tableTemp=''#ccMetaWAOutboundTemplates'';

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            @areaName,
            GETDATE(),
            @login,
            122,
            20,
            cc.identifierInfo,
            tb1.Value,
            @TemplateName
        FROM #ccMetaWAOutboundTemplates cc
        INNER JOIN  @tableHistoryLog  tb1 ON cc.columnInfo = (CASE 
                                                                WHEN tb1.Id = 1 THEN ''Category''
                                                                WHEN tb1.Id = 2 THEN ''header'' 
                                                                WHEN tb1.Id = 3 THEN ''body'' 
                                                                WHEN tb1.Id = 4 THEN ''footer''
                                                                WHEN tb1.Id > 4 THEN ''buttons''
                                                                END)
		WHERE cc.identifierInfo is not null

		EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccMetaWAOutboundTemplates'', @columnNameId = ''Id'', @valueId = @Id, @userId = 1,  @tableTemp=''#ccMetaWAOutboundTemplates'';
    END
    else IF(@action = 9) -- get templates by phone number
    BEGIN
        ;WITH tb1 as(
            SELECT
                gal.Target AS TemplateName,
                MAX(gal.ActivityDate) AS Date
            FROM ccGalateaActivityLog gal 
            WHERE gal.OperationId = 122 
            AND gal.ModuleId = 20 
            AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
            GROUP BY gal.Target, CAST(gal.ActivityDate AS DATE)
        )
        ,TemplateIsEditable AS (
            SELECT
                tb1.TemplateName,
                CASE WHEN COUNT(*) >= 10 THEN 2 WHEN MAX(tb1.Date) >= DATEADD(HOUR, -24, GETDATE()) THEN 1 ELSE 0 END AS IsEditable
            FROM tb1
            GROUP BY tb1.TemplateName
        )
        SELECT 
        cmwot.Id 
        ,cmwot.TemplateName AS Name
        ,cmwot.Status AS Status
        ,Category AS Category
        ,ISNULL(cmwot.notes, '''' ) AS Notes
        ,cmwot.header AS Header
        ,Body
        ,cmwot.footer AS Footer
        ,cmwot.buttons AS Buttons
        ,cmwot.LanguageCode
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,ISNULL(tie.IsEditable, 0) AS IsEditable
        ,cmwot.FilePath
		,cmwot.CreationDate
        FROM  dbo.ccMetaWAOutboundTemplates cmwot
        LEFT JOIN TemplateIsEditable tie ON tie.TemplateName = CAST(cmwot.TemplateName AS VARCHAR(MAX))
        WHERE cmwot.MetaId = @whatsAppTemplateID
        AND cmwot.StatusCW = 1
    END
    ELSE IF(@action = 10) -- Check if an other load is executing for the campaign
    BEGIN
        SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT , 1) ELSE CONVERT(BIT, 0) END AS IsProcessExecuting FROM dbo.ccRIALoading AS crl
        WHERE crl.cam_id = @campId AND crl.state IN (0,2) AND crl.loadType = 3;
    END
    ELSE IF(@action = 11) --Check if the campaign was eliminated or desasigned
    BEGIN
        DECLARE @campaignIsEliminateDesasigned BIT = 0;
        DECLARE @idAreaNull SMALLINT = 0;

        SELECT  @idAreaNull = cc.IDArea FROM dbo.ccCamps AS cc WHERE cc.cam_id = @campId

        IF(@idAreaNull IS NULL)
        BEGIN
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue eliminada
        END

        IF NOT EXISTS(SELECT TOP 1 crcew.IdCampEsp FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu
        ON crwgu.IDWG = crcew.IDWG
        WHERE crwgu.User_id = @UserId AND crcew.Tipo = 1 AND crcew.IdCampEsp = @campId)
        BEGIN 
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue desasignada del grupo de trabajo
        END

        SELECT @campaignIsEliminateDesasigned;
    END
    ELSE IF(@action = 12) --Get new numbers loaded in  ccWhatsAppOutSource 
    BEGIN
        SELECT cwt.Callkey FROM dbo.ccoWAWorkingTable AS cwt with(nolock)
        WHERE cwt.CamId = @campId AND cwt.WaStatus = 0
        UNION
        SELECT cwaos.CallKey FROM dbo.ccWhatsAppOutSource AS cwaos with(nolock,index(IX_WASource_1))
        WHERE cwaos.camId = @campId AND cwaos.Status = 0
    END
    IF(@action = 13) -- Get templates by campaign number assigned
    BEGIN
        SELECT 
        cmwot.Id 
        ,cmwot.TemplateName AS Name
        ,cmwot.Status AS Status
        ,Category AS Category
        ,ISNULL(cmwot.notes, '''' ) AS Notes
        ,cmwot.header AS Header
        ,Body
        ,cmwot.footer AS Footer
        ,cmwot.buttons AS Buttons
        ,cmwot.LanguageCode
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,cmwot.FilePath
		,cmwot.CreationDate
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan ON 
        cmwot.MetaId = cmwan.MetaId
        WHERE cmwot.StatusCW = 1 AND cmwan.Cam_Id = @campId AND cmwot.Status = ''APPROVED''
    END
    ELSE IF (@action = 14) -- check if campaing exists
    BEGIN
        IF EXISTS(SELECT 1 FROM dbo.ccMetaWAOutboundTemplates cmwot WHERE cmwot.Id = @whatsAppTemplateID)
            SELECT 1
        ELSE
            SELECT 0
    END
END
	'
	EXEC(@sql)

	--------------------------------------------- END Isaac ----------------------------------------
	-----------------------------------------------BEGIN Marco Garcia ----------------------------------
	SET @process = 'MAGV Organizar el listado de permisos correctamente'
	SET @sql = 'DECLARE @process VARCHAR(MAX), @sql	VARCHAR(MAX);

	ALTER TABLE ccRoles_Permissions NOCHECK CONSTRAINT ALL;
	ALTER TABLE dbo.ccPermissions NOCHECK CONSTRAINT ALL;

	DECLARE @ccPermissionsTmp TABLE 
	(
		Permissions_Id int,
		DESCRIPTION varchar(250)
	);

	INSERT INTO @ccPermissionsTmp
	VALUES
	( 10001, ''Iniciar y detener campañas|Start and stop Campaign''),
	( 10002, ''Carga de base de datos|Data Import''), 
	( 10003, ''CenterScript|CenterScript''), 
	( 10004, ''Roles''), 
	( 10005, ''Eliminar nuevos registros|Delete new records''), 
	( 10006, ''Devolucion de llamada|CallBacks''), 
	( 10007, ''Areas|Areas''), 
	( 10008, ''Gestionar de areas''), 
	( 10009, ''Gestionar tipos de no disponible''), 
	( 10010, ''Gestionar permisos de agente''), 
	( 10011, ''Gestionar campañas''), 
	( 10012, ''Gestionar asignacion de puertos''), 
	( 10013, ''Gestion de Campañas eliminar,agregar, etc''), 
	( 10014, ''Gestionar horarios''), 
	( 10015, ''Gestionar chat con agentes''), 
	( 10016, ''Gestionar monitoreo de llamada''), 
	( 10017, ''Solo monitoreo''), 
	( 10018, ''Gestionar formatos de evaluacion''), 
	( 10019, ''Gestionar historial de actividad''), 
	( 10020, ''Gestionar inicio automatico''), 
	( 10021, ''Gestionar calificaciones''), 
	( 10022, ''Gestionar factor de marcacion fijo''), 
	( 10023, ''Gestionar lista de ANI local''), 
	( 10024, ''Gestionar numeros DNIS''), 
	( 10025, ''Gestionar listas negras''), 
	( 10026, ''Acceder a reporteador''), 
	( 10027, ''Acceder a buscador''), 
	( 10028, ''Gestionar Asociacion de campaña''), 
	( 10029, ''Gestionar Mensajes Automaticos''), 
	( 10030, ''Gestionar administradores conectados''), 
	( 10031, ''Gestionar Numeros de Transferencia''), 
	( 10032, ''Gestionar configuracion de callback''), 
	( 10033, ''Reciclar registros''), 
	( 10034, ''Monitorear áreas y asignar/desasignar usuarios''), 
	( 10035, ''Acceder a buscador (sin descarga de archivos)''), 
	( 10036, ''Gestionar Segmentos''), 
	( 10037, ''Cargar registros SMS por segmento''), 
	( 10038, ''Validaciones SMS Masivo''), 
	( 10039, ''Plantillas SMS Masivo''), 
	( 10040, ''Gestionar plantillas de Meta''), 
	( 10041, ''Configurar desvío de llamadas entre campañas de diferentes áreas''),
	( 10042, ''Marcar en orden ascendente/descendente''),
	( 10043, ''Habilitar/deshabilitar marcación progresiva'');

	SELECT
		OldPermissionId = cp.Permissions_Id,
		NewPermissionId = cpt.Permissions_Id,
		Description = cpt.Description
	INTO #Mapping
	FROM ccPermissions cp
	INNER JOIN @ccPermissionsTmp cpt -- O la tabla que contiene los valores correctos
	ON cp.Description = cpt.Description; -- Coincidir por descripción u otro campo confiable

	UPDATE cp SET cp.Permissions_Id = cpt.NewPermissionId 
	FROM dbo.ccPermissions AS cp 
	INNER JOIN #Mapping AS cpt
	ON cpt.DESCRIPTION = cp.Description

	UPDATE  crp SET crp.Permissions_Id = cpt.NewPermissionId
	FROM dbo.ccRoles_Permissions AS crp
	INNER JOIN #Mapping AS cpt
	ON crp.Permissions_Id = cpt.OldPermissionId

	DROP TABLE #Mapping

	-- Habilitar nuevamente las restricciones de FK
	ALTER TABLE ccRoles_Permissions CHECK CONSTRAINT ALL;
	ALTER TABLE dbo.ccPermissions CHECK CONSTRAINT ALL;';
	EXEC(@sql);
	--------------------------------------- END Marco García -----------------------------------------------------------


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
