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
    SET @sql = 'DECLARE @process VARCHAR(MAX), @sql    VARCHAR(MAX);

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
    
	
    --------------------------------------------- Begin Ivan ----------------------------------------

    SET @process = 'Insert new setting 283 Mostrar alerta de error en agente al cancelar transferencias de llamada'
	SET @sql = '
    IF NOT EXISTS (SELECT * FROM ccSettings2 WHERE setting_id = 283) BEGIN
        INSERT INTO ccSettings2 (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
        VALUES (
        283, 
        ''0'',
        ''Mostrar alerta de error en agente al cancelar transferencias de llamada cuando el contacto cuelga (deshabilitado: 0, habilitado: 1)'', 
        1, 
        ''AGT'', 
        ''Mostrar alerta de error en agente al cancelar transferencias de llamada cuando el contacto cuelga (deshabilitado: 0, habilitado: 1)'', 
        ''Display error message for agent when cancelling call transfers after contacts hang up (disabled: 0, enabled: 1)'', 
        0, 
        ''Not used in Kolob'');
    END'
	EXEC(@sql)
    --------------------------------------------- END Ivan ----------------------------------------
    --------------------------------------------- BEGIN Luis Miguel Zamora Nuñez ----------------------------------------
    SET @process = 'Listas negras internacional ccsp_RIADNCList se modifica VARCHAR a NVARCHAR para compatibilidad'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] 
@phoneNumber AS NVARCHAR(30) = NULL, 
@idDNCList AS INTEGER, 
@tipoMov AS TINYINT, 
@calKey AS VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null,@cleanType=@cleanType
	EXEC ccsp_InsertDNCListSms @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	EXEC [ccsp_InsertDNCListWhatsApp] @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, ''4'', @idDNCList
	FROM cclistanegra
	WHERE idtipolista = @idDNCList

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idDNCList
END '
	EXEC(@sql)

	SET @process = 'Listas negras [ccsp_InsertDNCList] se agrega @params y correcciones del SP en valores tipo NVARCHAR'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as nvarchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS

Set nocount on

declare @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null
,@fnPhone nvarchar(100) =null
,@motivo nvarchar(100)
,@keyTranslate nvarchar(100)
,@params nvarchar(max)  

declare @phoneEmpty nvarchar(1)
set @phoneEmpty =''''


set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](@telephone)'' else  ''[dbo].[Verifica](@telephone)'' end

set @motivo=case when @cleanType=0 then ''Length exceeded'' else  ''Error en COFETEL'' end
set @keyTranslate=case when @cleanType=0 then ''description-length'' else  ''description-cofetel'' end


SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+@fnPhone+'',@calKey );
    '';
    EXEC (@dropTmpPhone);   
	
    EXEC sp_executesql @sqlcmd, N''@telephone nvarchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
	
END
else if @cleanType<>0 begin
	set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](phoneNumber)'' else  ''[dbo].[Verifica](phoneNumber)'' end
	
	set @sqlcmd=''update '' + @tmpTableName + '' set phoneNumber=''+@fnPhone
	
	EXEC (@sqlcmd);

	set @sqlcmd=''
	Insert into ccRIALogPhones 
select @ln_id,@phoneEmpty,phoneNumber,0,@motivo,@keyTranslate 
from ''+ @tmpTableName+''
where left(phoneNumber,1)= ''''E''''
delete from ''+ @tmpTableName+'' where left(phoneNumber,1)= ''''E''''
''
	print @sqlcmd
	set @params=''@ln_id int, @phoneEmpty nvarchar(1),@motivo nvarchar(100),@keyTranslate nvarchar(100)''
	EXEC sp_executesql @sqlcmd,@params,
	@ln_id=@ln_id
	,@phoneEmpty=@phoneEmpty,@motivo =@motivo ,@keyTranslate =@keyTranslate 

end

set @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.telefono is not null''
--print(@sqlcmd)
EXEC (@sqlcmd);   

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '' A 

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '' A '';

print ''xxx''
EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] ( [campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


CREATE TABLE [dbo].[#myprincipaltempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#helpTempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE TABLE [dbo].[#mytempCall](
    [callout_id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
    SET @sqlcmd = ''
    insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  cal_fechadial > getdate()-30
    ''

SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')   
EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

DECLARE @columnIndex INT = 2;
WHILE @columnIndex <= 5
BEGIN
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono''+CONVERT(varchar(10),@columnIndex))
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
	set @columnIndex=@columnIndex+1;
END

    SET @sqlcmd = ''insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
    where cal_fechadial > getdate()-30;
    '';
    
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    INSERT INTO #myprincipaltempCall
    SELECT * FROM #helpTempCall
    GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
      
    ,@sqlWithReplace nvarchar(max)
    
    set @column=''cal_telefono''
    set @params=''@phoneEmpty varchar(1),@fech datetime''
    set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
    and cs.cal_telefono3=@phoneEmpty
    and cs.cal_telefono4=@phoneEmpty
    and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
    when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
    when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
    when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
    else @phoneEmpty end ''

    set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set cal_telefono = CASE_UPDATE_WT
    from ccoCallsOutSource cs 
    inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

    set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin       
    -- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
    delete wt with(rowlock)
    from ccoWOrkingTable wt 
    inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
    inner join #mytempCall t on wt.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and
    cs.COLUMN_CHECK = wt.cal_telefono
    AND_DELETE_WT

    UPDATE_SMS_WT_QUERY

    --insertar el historial
    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    -- Eliminamos el telefono1 de CS
    update ccoCallsOutSource 
    set COLUMN_CHECK = @phoneEmpty
    from ccoCallsOutSource cs 
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech      

    truncate table #mytempCall
end''

    
    /******************/
    /*** Telefono 1 ***/
    /******************/
    
    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    print(@sqlWithReplace)  
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 2 ***/
    /******************/
    set @column=''cal_telefono2''
    
    set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
        and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
        when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 3 ***/
    /******************/
    set @column=''cal_telefono3''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 4 ***/
    /******************/    
    
    set @column=''cal_telefono4''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''cal_telefono5''   
    set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty'' 
    set @sqlCaseWorking=''''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
	EXEC(@sql)

    --------------------------------------------- END Luis Miguel Zamora Nuñez  ----------------------------------------


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
