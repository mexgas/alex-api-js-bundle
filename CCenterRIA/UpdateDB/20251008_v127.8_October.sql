/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Carlos Eduardo Muñoz Carbajal
Date: 2025/10/08
Description: Sprint 4 - Agente Luis
Database: CCenterRia
Required version: 127.2
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
    SET @version = 127 --**********actualizar a 124 sin fix
    SET @versionfix = 8
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

    ------------------------------------ BEGIN CARLOS MUÑOZ ------------------------------------
    SET @process = 'Added new columns to save behaviour and definition of models as well as a logical elimination of models'
    SET @sql = '
        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''quantumRoleId'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD quantumRoleId INT NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''roleName'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD roleName VARCHAR(30) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''language'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD language TINYINT NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''responseTone'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD responseTone SMALLINT NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''responseLength'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD responseLength TINYINT NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''objective'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD objective VARCHAR(1200) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''rules'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD rules VARCHAR(1200) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''instructions'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD instructions VARCHAR(8000) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''wasDeleted'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD wasDeleted BIT not null DEFAULT(0);
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''ReplyGreeting'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD ReplyGreeting NVARCHAR(350) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''ReplyFarewell'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD ReplyFarewell NVARCHAR(350) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''ReplySystemFailure'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD ReplySystemFailure NVARCHAR(350) NULL;
        END;

        IF COL_LENGTH(''dbo.ccVirtualAgent'', ''ReplyNoUnderstanding'') IS NULL
        BEGIN
            ALTER TABLE dbo.ccVirtualAgent
            ADD ReplyNoUnderstanding NVARCHAR(350) NULL;
        END;
    '

    EXEC(@sql)

    ------------------------------------- END CARLOS MUÑOZ -------------------------------------

    ------------------------------------ BEGIN JUAN MEDINA ------------------------------------

    SET @process = 'Adding new permissions to manage and view virtual agents modules'
    SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccPermissions WHERE Permissions_Id = 10044)
        BEGIN
            INSERT INTO ccPermissions VALUES (
                10044,
                ''Gestionar modulo agente virtual'',
                ''RolesPermissionManageVirtualAgentModule'',
                0,
                0,
                0,
                ''N/A'',
                1)
        END

        IF NOT EXISTS(SELECT * FROM ccPermissions WHERE Permissions_Id = 10045)
        BEGIN
            INSERT INTO ccPermissions VALUES (
                10045,
                ''Visualizar modulo agente virtual'',
                ''RolesPermissionViewVirtualAgentModule'',
                0,
                0,
                0,
                ''N/A'',
                1)
        END
	 '
    EXEC(@sql)

    SET @process = 'Permissions are added to the activity history identifier table'
    SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''10013'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''10013'', ''Gestionar campañas'', ''Manage campaigns'', ''Gerenciar campanhas'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''10040'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''10040'', ''Gestionar plantillas de Meta'', ''Manage Meta templates'', ''Gerenciar modelos de Meta'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''10042'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''10042'', ''Marcar en orden ascendente/descendente'', ''Dial in ascending/descending order'', ''Discar em ordem crescente/decrescente'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''10043'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''10043'', ''Habilitar/deshabilitar marcación progresiva'', ''Enable/disable progressive dialing'', ''Ativar/desativar discagem progressiva'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''10044'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''10044'', ''Gestionar modelos de agente virtual'', ''Manage virtual agent models'', ''Gerenciar modelos de agente virtual'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''10045'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''10045'', ''Monitorear modelos de agente virtual'', ''Monitor virtual agent models'', ''Monitorar modelos de agente virtual'');
        END
	 '
    EXEC(@sql)

    SET @process = 'Modules and operations are added for the virtual agent''s activity history.'

    SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 169)
		BEGIN 
		 INSERT INTO ccGalateaOperations VALUES (169, ''Crear modelo'', ''Create model'', ''Criar modelo'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 169)
		BEGIN
		 INSERT INTO ccGalateaModOpRelation VALUES(24, 169)
		END

		IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 170)
		BEGIN 
		 INSERT INTO ccGalateaOperations VALUES (170, ''Configurar estructura'', ''Configure framework'', ''Configurar estrutura'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 170)
		BEGIN
		 INSERT INTO ccGalateaModOpRelation VALUES(24, 170)
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION'', ''Objetivo, Reglas generales, Guion'', ''Objective, General rules, Script'', ''Objetivo, Regras gerais, Script'')
		END
	 '
    EXEC(@sql)

    SET @process = 'Add column Language'
    SET @sql = '
        IF COL_LENGTH(''ccVirtualAgentVoices'', ''Language'') IS NULL
        BEGIN
            ALTER TABLE ccVirtualAgentVoices
            ADD Language INT NULL;
        END;
		'
	EXEC(@sql);

	SET @process = 'Adding permission 10044 to root'
    SET @sql = '
        insert into ccRoles_Permissions values (1, 10044)
		'
	EXEC(@sql);

	SET @process = 'Adding permission 10045 to root'
    SET @sql = '
        insert into ccRoles_Permissions values (1, 10045)
		'
	EXEC(@sql);

	SET @process = 'Update Language in Alma and Luis'
	SET @sql = '
        UPDATE ccVirtualAgentVoices SET Language = 0 WHERE name = ''Alma'' OR name = ''Luis''
		'
	EXEC(@sql);

	SET @process = 'Voices are added for the virtual agent in English and Portuguese.'
	SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccVirtualAgentVoices WHERE name = ''Emma'')
        BEGIN
            INSERT INTO ccVirtualAgentVoices (name, gender, filename, isDefault, createdAt, quantumVoiceId, language)
            VALUES (''Emma'', ''Female'', ''Emma.mp3'', 0, GETDATE(), ''625jGFaa0zTLtQfxwc6Q'', 1);
        END

        IF NOT EXISTS(SELECT * FROM ccVirtualAgentVoices WHERE name = ''Lewis'')
        BEGIN
            INSERT INTO ccVirtualAgentVoices (name, gender, filename, isDefault, createdAt, quantumVoiceId, language)
            VALUES (''Lewis'', ''Male'', ''Lewis.mp3'', 0, GETDATE(), ''f5HLTX707KIM4SzJYzSz'', 1);
        END

        IF NOT EXISTS(SELECT * FROM ccVirtualAgentVoices WHERE name = ''Sofia'')
        BEGIN
            INSERT INTO ccVirtualAgentVoices (name, gender, filename, isDefault, createdAt, quantumVoiceId, language)
            VALUES (''Sofia'', ''Female'', ''Sofia.mp3'', 0, GETDATE(), ''cyD08lEy76q03ER1jZ7y'', 2);
        END

        IF NOT EXISTS(SELECT * FROM ccVirtualAgentVoices WHERE name = ''Luiz'')
        BEGIN
            INSERT INTO ccVirtualAgentVoices (name, gender, filename, isDefault, createdAt, quantumVoiceId, language)
            VALUES (''Luiz'', ''Male'', ''Luiz.mp3'', 0, GETDATE(), ''Hmn4B9B77pf6ttydteJ8'', 2);
        END
	 '
    EXEC(@sql);

    SET @process = 'Added operation and identifiers for editing virtual agents and their relationship with tables and columns.'
    SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 171)
        BEGIN
            INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
            VALUES (171, ''Editar modelo'', ''Edit model'', ''Editar modelo'');
        END

		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_NAME'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_NAME'', ''Nombre'', ''Name'', ''None'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_LANGUAGE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_LANGUAGE'', ''Idioma'', ''Language'', ''Idioma'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_TONE_OF_VOICE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_TONE_OF_VOICE'', ''Tono de voz'', ''Tone of voice'', ''Tom de voz'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_RESPONSE_LENGTH'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_RESPONSE_LENGTH'', ''Longitud de respuesta'', ''Response length'', ''Comprimento de resposta'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_NUMBER_OF_VIRTUAL_AGENTS'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_NUMBER_OF_VIRTUAL_AGENTS'', ''Número de agentes virtuales'', ''Number of virtual agents'', ''Número de agentes virtuais'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_VIRTUAL_AGENT_CAMPAIGN'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_VIRTUAL_AGENT_CAMPAIGN'', ''Campaña'', ''Campaign'', ''Campanha'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_VOICE_TYPE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_VOICE_TYPE'', ''Tipo de voz'', ''Voice type'', ''Tipo de voz'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_SCRIPTED_RESPONSES'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_SCRIPTED_RESPONSES'', ''Respuestas guiadas'', ''Scripted responses'', ''Respostas com script'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_RESPONSES'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_RESPONSES'', ''Saludo, Despedida, Error de sistema, Error de comprensión'', ''Greeting, End of conversation, System error, Fallback'', ''Saudação, Fim da conversa, Erro de sistema, Erro de compreensão'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_SPANISH_ES'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_SPANISH_ES'', ''Español (es)'', ''Spanish (es)'', ''Espanhol (es)'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_ENGLISH_EN'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_ENGLISH_EN'', ''Inglés (en)'', ''English (en)'', ''Inglês (en)'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_PORTUGUESE_PT'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_PORTUGUESE_PT'', ''Portugués (pt)'', ''Portuguese (pt)'', ''Português (pt)'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_FORTHRIGHT_AND_CONCISE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_FORTHRIGHT_AND_CONCISE'', ''Directo y conciso'', ''Forthright and concise'', ''Franco e conciso'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_SYMPATHETIC_AND_WARM'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_SYMPATHETIC_AND_WARM'', ''Empático y acompañante'', ''Sympathetic and warm'', ''Empático e receptivo'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_PERSUASIVE_AND_ACTION_ORIENTED'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_PERSUASIVE_AND_ACTION_ORIENTED'', ''Persuasivo y orientado a la acción'', ''Persuasive and action-oriented'', ''Persuasivo e orientado para a ação'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_NEUTRAL_AND_OBJECTIVE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_NEUTRAL_AND_OBJECTIVE'', ''Neutro y objetivo'', ''Neutral and objective'', ''Neutro e objetivo'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_RELAXED_AND_FRIENDLY'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_RELAXED_AND_FRIENDLY'', ''Relajado y amigable'', ''Relaxed and friendly'', ''Relaxado e amigável'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_CAMPAIGN_NONE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_CAMPAIGN_NONE'', ''Ninguno'', ''None'', ''Nenhum'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_SHORT_RESPONSE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_SHORT_RESPONSE'', ''Corta'', ''Short'', ''Curta'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_MEDIUM_RESPONSE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_MEDIUM_RESPONSE'', ''Mediana'', ''Medium'', ''Média'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_LONG_RESPONSE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_LONG_RESPONSE'', ''Larga'', ''Long'', ''Longa'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_NONE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_NONE'', ''Ninguna'', ''None'', ''Nenhum'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_VOICE_FEMALE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_VOICE_FEMALE'', ''Mujer (Alma)'', ''Female (Emma)'', ''Mulher (Sofia)'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_VOICE_MALE'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_VOICE_MALE'', ''Hombre (Luis)'', ''Male (Lewis)'', ''Homem (Luiz)'');
        END

        IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_VOICE_CUSTOM'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
            VALUES (''VA_VOICE_CUSTOM'', ''Personalizado'', ''Custom'', ''Personalizada'');
        END

       IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_NAME'' AND tableName = ''ccVirtualAgent'' AND colunName = ''nameAgent'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_NAME'', ''ccVirtualAgent'', ''nameAgent'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_LANGUAGE'' AND tableName = ''ccVirtualAgent'' AND colunName = ''language'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_LANGUAGE'', ''ccVirtualAgent'', ''language'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_TONE_OF_VOICE'' AND tableName = ''ccVirtualAgent'' AND colunName = ''responseTone'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_TONE_OF_VOICE'', ''ccVirtualAgent'', ''responseTone'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_RESPONSE_LENGTH'' AND tableName = ''ccVirtualAgent'' AND colunName = ''responseLength'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_RESPONSE_LENGTH'', ''ccVirtualAgent'', ''responseLength'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_NUMBER_OF_VIRTUAL_AGENTS'' AND tableName = ''ccVirtualAgent'' AND colunName = ''concurrentSessionsLimit'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_NUMBER_OF_VIRTUAL_AGENTS'', ''ccVirtualAgent'', ''concurrentSessionsLimit'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_VIRTUAL_AGENT_CAMPAIGN'' AND tableName = ''ccVirtualAgent'' AND colunName = ''idCampaign'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_VIRTUAL_AGENT_CAMPAIGN'', ''ccVirtualAgent'', ''idCampaign'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_VOICE_TYPE'' AND tableName = ''ccVirtualAgent'' AND colunName = ''voice'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_VOICE_TYPE'', ''ccVirtualAgent'', ''voice'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_SCRIPTED_RESPONSES'' AND tableName = ''ccVirtualAgent'' AND colunName = ''ReplyGreeting'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_SCRIPTED_RESPONSES'', ''ccVirtualAgent'', ''ReplyGreeting'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_SCRIPTED_RESPONSES'' AND tableName = ''ccVirtualAgent'' AND colunName = ''ReplyFarewell'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_SCRIPTED_RESPONSES'', ''ccVirtualAgent'', ''ReplyFarewell'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_SCRIPTED_RESPONSES'' AND tableName = ''ccVirtualAgent'' AND colunName = ''ReplySystemFailure'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_SCRIPTED_RESPONSES'', ''ccVirtualAgent'', ''ReplySystemFailure'');
        END

        IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''VA_SCRIPTED_RESPONSES'' AND tableName = ''ccVirtualAgent'' AND colunName = ''ReplyNoUnderstanding'')
        BEGIN
            INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
            VALUES (''VA_SCRIPTED_RESPONSES'', ''ccVirtualAgent'', ''ReplyNoUnderstanding'');
        END
	 '
    EXEC(@sql)

   SET @process = 'Drop function fn_translatePermissionsIds_TVF if exists'

	SET @sql = '
		IF EXISTS (SELECT * FROM sys.objects WHERE name = N''fn_translatePermissionsIds_TVF'')
		BEGIN
			DROP FUNCTION dbo.fn_translatePermissionsIds_TVF;
		END;
		';
	EXEC(@sql);

	SET @process = 'Added function fn_translatePermissionsIds_TVF for reading permissions in activity history'

    SET @sql = '
		-- =============================================
		-- Author:      Juan J. Medina
		-- Create date: 02/10/2025
		-- Description: Returns a string containing the names/labels
		--              (depending on the language) of a list of identifiers.
		--              If an identifier doesn''t exist in ccGalateaIdentifiers,
		--              it is left as is.
		-- Params:
		--   @identifiers: comma-delimited string (''10001,10002,10003'')
		--   @lang: 0=Spanish, 1=English, 2=Portuguese (default 1)
		-- Return: table with a single row and column [Message]
		-- =============================================
		CREATE FUNCTION [fn_translatePermissionsIds_TVF]
		(
			@Ids NVARCHAR(MAX),
			@lang int
		)
		RETURNS NVARCHAR(MAX)
		AS
		BEGIN

			 DECLARE @message NVARCHAR(MAX) = N'''';

			SELECT @message =
				STUFF((
					SELECT N'','' + 
						   (CASE 
								WHEN ci.Description IS NULL THEN LTRIM(RTRIM(rs.Value))
								ELSE CASE @lang
										 WHEN 0 THEN ci.TagEs
										 WHEN 2 THEN ci.TagPt
										 ELSE        ci.TagEn
									 END
							END)
					FROM dbo.fn_RIASplitDelimited(@Ids, '','') AS rs
					LEFT JOIN ccGalateaIdentifiers AS ci
						ON ci.Description = LTRIM(RTRIM(rs.Value))
					ORDER BY rs.id
					FOR XML PATH(''''), TYPE
				).value(''.'', ''NVARCHAR(MAX)''), 1, 1, N'''');

			RETURN @message;
		END
	 '
    EXEC(@sql)

    SET @process = 'Drop Procedure ccsp_GalateaChangeHistory '

	SET @sql = '
		IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_GalateaChangeHistory'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_GalateaChangeHistory;
		END'
	EXEC(@sql);

	SET @process = 'Added read permission change in ccsp_GalateaChangeHistory'

    SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
		@option TINYINT,
		@loginLst VARCHAR(max) = NULL,
		@moduleWithOperation varchar(max) = NULL,
		@operationDateIni SMALLDATETIME = NULL,
		@operationDateFin SMALLDATETIME = NULL,
		@top INT = 0
		AS
		SET NOCOUNT ON

		DECLARE @lang TINYINT

		SELECT @lang = valor
		FROM ccsettings
		WHERE setting_id = 27

		IF @option = 1 -- Catalogo de modulos
		BEGIN
			WITH Catalog AS(
			SELECT m.ModuleId as module_id, o.OperationId as operationType, 
			CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS mDescripcion, 
			CASE @lang WHEN 0 THEN OpTagEs WHEN 2 THEN OpTagPt ELSE OpTagEn END AS oDescripcion
			FROM ccGalateaOperations o WITH (INDEX (IX_ccGalateaOperations_Op))
			JOIN ccGalateaModOpRelation r ON o.OperationId = r.OperationId
			JOIN ccGalateaModules m WITH (INDEX (IX_ccGalateaModules_Mod)) ON r.ModuleId = m.ModuleId --WITH (INDEX (IX_ccGalateaModules_Mod))

			UNION

			SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
	
			UNION

			SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

			UNION

			SELECT ModuleId as module_id, 0, CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, 
			CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
			FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod))

			UNION

			SELECT ModuleId as module_id, - 1 , CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, '' - ''
			FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod)))

			SELECT module_id,operationType,mDescripcion,oDescripcion 
			FROM Catalog
			ORDER BY mDescripcion, oDescripcion

			RETURN (0)
		END

		IF @option = 2 -- Muestra informacion por filtros
		BEGIN

			declare @sql as nvarchar(max)
			DECLARE @table TABLE(id int,value varchar(max))
			declare @id int
			declare @moduleId varchar(max)
			declare @operationLst varchar(max)
			declare @query varchar(max) = '' and (''
			declare @value varchar(max)
			declare @first int = 1
			declare @pos int

			insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
			while exists(select * from @table)
			begin
				select top 1 @id = id, @value = value from @table
				set @pos = charindex('':'', @value)
				if(@pos <> 0)
				begin
					set @moduleId = substring(@value, 1, @pos-1)
					set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
					if(@first = 1)
					begin
						set @query = @query + ''l.moduleId='' + @moduleId + '' and l.operationId in ('' + @operationLst + '')''
						set @first = 0
					end
					else
					begin
						set @query = @query + '' or l.moduleId='' + @moduleId + '' and l.operationId in ('' + @operationLst + '')''
					end
				end

				delete @table where id = @id
			end
			set @query = @query + '')''


			SET ROWCOUNT @top

			set @sql =
			''DECLARE @tableLogin TABLE(id int,value varchar(255))
			insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

			SELECT L.LogId as log_id, L.Area as areaName, L.ActivityDate as operationDate,
			CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN O.OpTagEs WHEN 2 THEN O.OpTagPt ELSE O.OpTagEn END operationType,
			L.LOGIN,
			CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN M.MTagEs WHEN 2 THEN M.MTagPt ELSE M.MTagEn END module_id,
			CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
			CASE WHEN i.description IS NULL THEN L.Identifier ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN i.TagEs WHEN 2 THEN i.TagPt ELSE i.TagEn END END +
			CASE WHEN L.Identifier<>'''''''' AND L.Value<>'''''''' THEN '''': '''' ELSE '''''''' END +

			CASE WHEN V.description IS NULL 
				THEN 
					CASE 
						WHEN L.Identifier<>'''''''' AND (L.Identifier LIKE ''''COMMON_DELETE_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_ADD_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_DATE%'''')
							THEN dbo.GetDateByLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
						''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''OUT_SIP_IDENTIFIER'''' THEN dbo.GetSipLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
						''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''T&EDIT_TEMPLATE_BUTTONS'''' THEN dbo.GetMetaButtonTemplateHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
						''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'''' THEN dbo.GetAIVoiceCampaignHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
						''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'''' THEN dbo.GetAIVoiceCampaignHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
						''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''CREATE_ROLE_PERMISSIONS'''' THEN dbo.fn_translatePermissionsIds_TVF(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
				''ELSE L.value END
				ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.TagEs WHEN 2 THEN v.TagPt ELSE v.TagEn END END AS value

			FROM ccGalateaActivityLog L
			JOIN ccGalateaModules M WITH (INDEX (IX_ccGalateaModules_Mod)) ON L.ModuleId = M.ModuleId
			JOIN ccGalateaOperations O WITH (INDEX (IX_ccGalateaOperations_Op)) ON L.OperationId = O.OperationId
			LEFT JOIN targetRecord t ON t.targetT = L.target
			LEFT JOIN ccGalateaIdentifiers i ON i.Description = L.Identifier
			LEFT JOIN ccGalateaIdentifiers v ON v.Description = L.Value
			LEFT JOIN ccUsers CU ON CU.Login = L.login
			WHERE 1=1 
			AND
			CU.TipoUser_id = 2''
			+
			case isnull(@loginLst, '''') when '''' then '''' else
			'' AND L.LOGIN in (select value from @tableLogin) ''
			END
			+
			case isnull(@moduleWithOperation, '''') when '''' then '''' else
			@query
			end
			+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
			''AND L.ActivityDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.ActivityDate END ''
			+ '' AND L.ActivityDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.ActivityDate END''
			end
			+
			'' ORDER BY L.ActivityDate DESC''
			execute sp_executesql @sql
			--print @sql
		END
		SET NOCOUNT OFF
	 '
    EXEC(@sql)
    
    SET @process = 'Drop Procedure ccsp_DLRGetDialInfo '

	SET @sql = '
		IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_DLRGetDialInfo'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_DLRGetDialInfo;
		END'
	EXEC(@sql);

	SET @process = 'Added change to send country and time_zone to quantum in out calls'

    SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
            @callout_id int,
            @cam_id smallint=0,
            @iPortNumber smallint = 0
            AS
            set nocount on
            declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
            declare @prefix as varchar(15)
            declare @prefixCalKey as varchar(30)
            declare @tNoContesta as tinyint
            declare @ani as varchar(32)
            declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
            declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
            declare @ivr_script smallint, @surveycamid int
            declare @call_record_cam as tinyint
            declare @pais as tinyint 
            declare @sipHdrFormat varchar(255)
            declare @PrefixRec varchar(40)
            declare @recordHold bit, @recordIvr bit

            set @prefix =''''
            set @tNoContesta = 25
            set @ani=''''
            set @iTipoDial = 0
            set @detectAnswerMachine = 0
            set @detectVoiceMail =1
            set @cam_tnotas = 30
            set @keepDial = 0

            select @pais = valor from ccsettings where setting_id = 104
            select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

            -- Mensajes
            select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
            from dbo.fn_ccCamps_SelMessage(@cam_id)

            -- Prefijo por puerto
            select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
            -- Prefijo por campa?a
            if @prefix =''''
                select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
            -- Prefijo general, si es que esta habilitado
            if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
                select @prefix = valor from ccsettings nolock where setting_id =101

            select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

            -- Propiedades de campa?a
            select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
            @detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
            @call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
            ,@PrefixRec=ISNULL(prefijo,''''), @recordIvr=ISNULL(recordIvr,0)
            from ccCamps C (nolock) where C.cam_id=@cam_id

            if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

            --Custom MOH Files
            DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
            SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
            FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

            --Agrega prefijo Marcacion con directo
            declare @mainPrefix varchar(1), @phones varchar(max), @apikeyQuantum VARCHAR(300);
            set @prefixCalKey=''''
            select @mainPrefix = valor from ccSettings where setting_id=202
            select @apikeyQuantum = ISNULL(valor, '''') from dbo.ccSettings2 where setting_id=284
            declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix   varchar(30) null
            ,cal_Key    varchar(40)
            ,cal_telefono   varchar(30),cal_telefono2   varchar(30),cal_telefono3   varchar(30),cal_telefono4   varchar(30),cal_telefono5   varchar(30)
            ,Dato1  varchar(255),Dato2  varchar(255),Dato3  varchar(255),Dato4  varchar(255),Dato5  varchar(255)
            ,recyclePhone   SMALLINT
            ,recycleType BIT
            ,data_api_quantum VARCHAR(MAX)
            )
            insert into @tmpccoCallsOutSource
            SELECT 
                c.callout_id,
                c.dialPrefix,
                c.cal_Key,
                c.cal_telefono, c.cal_telefono2, c.cal_telefono3, c.cal_telefono4, c.cal_telefono5,
                c.Dato1, c.Dato2, c.Dato3, c.Dato4, c.Dato5,
                c.recyclePhone, c.recycleType,
                (
                    CASE 
                        WHEN RIGHT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')), 1) = N''}''
                            THEN LEFT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')), LEN(RTRIM(ISNULL(c.data_api_quantum, N''{}''))) - 1)
                        ELSE RTRIM(ISNULL(c.data_api_quantum, N''{}''))
                    END
                    +
                    CASE 
                        WHEN LEN(
                                LTRIM(RTRIM(
                                    CASE 
                                        WHEN LEFT(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}''))),1) = N''{'' 
                                        AND RIGHT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')),1) = N''}''
                                        THEN SUBSTRING(
                                                LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}''))),
                                                2,
                                                LEN(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}'')))) - 2
                                            )
                                        ELSE LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}'')))
                                    END
                                ))
                            ) > 0 
                        THEN N'','' ELSE N'''' 
                    END
                    +
                    N''"country": '' + CONVERT(NVARCHAR(20),@pais)
                    +
                    N'', "time_zone": '' + CONVERT(NVARCHAR(20),
                                        CASE
                                            WHEN c.iZonaHoraria  > 0 THEN c.iZonaHoraria
                                            WHEN c.iZonaHoraria2 > 0 THEN c.iZonaHoraria2
                                            WHEN c.iZonaHoraria3 > 0 THEN c.iZonaHoraria3
                                            WHEN c.iZonaHoraria4 > 0 THEN c.iZonaHoraria4
                                            WHEN c.iZonaHoraria5 > 0 THEN c.iZonaHoraria5
                                            ELSE 0
                                        END
                                    )
                    +
                    N''}''
                ) AS data_api_quantum
            FROM ccoCallsOutSource AS c WITH (NOLOCK)
            WHERE c.callout_id = @callout_id;

            SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
                @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
            FROM @tmpccoCallsOutSource

            if @iPortNumber >= 0 
            begin
                declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

                insert @Anis
                exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

                SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
            
                SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
                , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
                , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
                , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
                , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
                , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
                , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
                , isnull(@message_name, '''') as message_name
                , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
                , case when anis.p1 <> '''' then anis.p1 else @ani end ani
                , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
                , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
                , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
                , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
                , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
                , @cam_tnotas cam_tnotas, @keepDial keepDial
                , isnull(@messageDNCL_name, '''') as messageDNCL_name
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
                , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
                , isnull(@MohFiles,'''') as mohFiles
                ,@ivr_script ivrScript
                ,@sipheader data
                ,@PrefixRec as Prefijo,
                dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
                dbo.GetCarrierByTel(cal_telefono2) carrier2, 
                dbo.GetCarrierByTel(cal_telefono3) carrier3, 
                dbo.GetCarrierByTel(cal_telefono4) carrier4, 
                dbo.GetCarrierByTel(cal_telefono5) carrier5,
                @recordHold as recordHold,
                @recordIvr as recordIvr,
                isnull(C.data_api_quantum, '''') AS data_api_quantum,
                @apikeyQuantum AS key_api_quantum
                FROM @tmpccoCallsOutSource C
                left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
                left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
                left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
                WHERE C.callout_id = @callout_id
                return
            end 
            set nocount off
	 '
    EXEC(@sql)

    SET @process = 'Drop Procedure ccsp_InboundCallQuantumInfo '

	SET @sql = '
		IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_InboundCallQuantumInfo'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_InboundCallQuantumInfo;
		END'
	EXEC(@sql);

	SET @process = 'Added change to send country and time_zone to quantum inbound calls'

    SET @sql = '
			CREATE PROCEDURE [dbo].[ccsp_InboundCallQuantumInfo]
                @InboundId INT
            AS
            BEGIN
                IF EXISTS (SELECT 1 FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 11)
                BEGIN;
                    DECLARE @country VARCHAR(10);
                    DECLARE @quantumAgentId VARCHAR(100);
                    DECLARE @key VARCHAR(50);

                    SELECT @country = valor FROM ccSettings WHERE setting_id = 104;
                    SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
                    SELECT @quantumAgentId = quantumAgentId 
                        FROM ccVirtualAgent 
                        WHERE idCampaign = @InboundId AND campType = 0;

                    SELECT 
                        @key AS key_api_quantum,
                        ''{"type":0,"agent_id":"'' + ISNULL(@quantumAgentId, '''') + ''",''+''"country":''+ISNULL(@country,0)+'',''+''"time_zone":0}'' AS data_api_quantum
                
                END
            END
	 '
    EXEC(@sql)

    SET @process = 'Drop Procedure [ccsp_ManageQuantumDispositions] '

	SET @sql = '
		IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_ManageQuantumDispositions'')
		BEGIN
			DROP PROCEDURE ccsp_ManageQuantumDispositions;
		END'
	EXEC(@sql);

	SET @process = 'Actions are added for quantum endpoints.'

    SET @sql = '
		CREATE PROCEDURE ccsp_ManageQuantumDispositions
				@Action INT,
				@CampId INT = NULL,
				@AgentId INT = NULL,
				@CampType INT = NULL,
				@VoiceId INT = NULL
		AS
		BEGIN
			DECLARE @Inbound INT = 0, @Outbound INT = 1
			IF @Action = 1 --Get API Data
			BEGIN
				DECLARE @key VARCHAR(255)
				SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
				SELECT valor AS ApiUrl, @key AS [Key] FROM ccSettings2 WHERE setting_id = 290
			END
			IF @Action = 2 --Get Quantum Id Agent Data
			BEGIN
				SELECT quantumAgentId
				FROM ccVirtualAgent
				WHERE 
					(@AgentId IS NOT NULL AND idAgent = @AgentId)
					OR (@AgentId IS NULL AND campType = @CampType AND idCampaign = @CampId);
			END
			IF @Action = 3 --Get Quantum Dispositions by camp
			BEGIN
				IF @CampType = @Inbound
				BEGIN
					SELECT tc.calif_id AS [Id], tc.[Description] AS [Description], tc.CanReprogram as Callback
					FROM ccCalifCamp cc INNER JOIN ccTipoCalif tc
					ON cc.calif_id = tc.calif_id
					WHERE cc.tipo = 0
					AND cc.cam_id = @CampId
				END
				IF @CampType = @Outbound
				BEGIN
					SELECT tc.calif_id AS [Id], tc.[Description] AS [Description], tc.CanReprogram as Callback
					FROM ccCalifCamp cc INNER JOIN ccTipoCalifOut tc
					ON cc.calif_id = tc.calif_id
					WHERE cc.tipo = 1
					AND cc.cam_id = @CampId
				END
			END
			IF @Action = 4 -- Get Quantum Agent Voice Id
			BEGIN
				SELECT ISNULL(
					(SELECT QuantumVoiceId 
					 FROM ccVirtualAgentVoices 
					 WHERE ID = @VoiceId), 
					''''
				) AS QuantumVoiceId;
			END

			IF @Action = 5 -- Get Transfer Status 
			BEGIN
				SELECT 
					CASE 
						WHEN TransferToHumanAgents <> 0 OR TransferOnSuccessfulHandling <> 0 
						THEN CAST(1 AS BIT) 
						ELSE CAST(0 AS BIT) 
					END
				FROM ccInboundExtend
				WHERE Inbound_id = @CampId;
			END

			IF @Action = 6 -- Agent Id By Campaign 
			BEGIN
				SELECT ISNULL(
					(SELECT TOP 1 idAgent 
					 FROM ccVirtualAgent 
					 WHERE idCampaign = @CampId 
					   AND mediaType = 11),
					0
				) AS idAgent;
			END
		END
	 '
    EXEC(@sql)

   	 SET @process = 'Drop Procedure [ccsp_VirtualAgents] '

	SET @sql = '
		IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_VirtualAgents'')
		BEGIN
			DROP PROCEDURE ccsp_VirtualAgents;
		END'
	EXEC(@sql);

	SET @process = 'Actions are added for the creation, viewing, and editing flow of virtual agent models.'

    SET @sql = '
		CREATE PROCEDURE ccsp_VirtualAgents
		@action INT = 0,

		@idVirtualAgent INT = 0,
		--Creation
		@nameAgent NVARCHAR(255) = NULL,
		@responseTone TINYINT = 0,
		@languageAgent TINYINT = 0,
		@quantumRoleId INT = 0,
		@roleDescription NVARCHAR(30) = '''',
		@responseLength TINYINT = 0,
		@numberOfAgents INT = 0,
		@quantumAgentId NVARCHAR(50) = '''',
		@replyGreeting NVARCHAR(350) = '''',
		@replyFarewell NVARCHAR(350) = '''',
		@replySystemFailure NVARCHAR(350) = '''',
		@replyNoUnderstanding NVARCHAR(350) = '''',
		@statusAgent BIT = NULL,
		@campaignId INT = NULL,
		@mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
		@campType INT = NULL, -- 0 IN - 1 OUT
		@voiceID INT= 0,
		@adminId INT = 0,

		--Definition
		@objective VARCHAR(1200) = NULL,
		@rules VARCHAR(1200) = NULL,
		@instructions VARCHAR(8000) = NULL,
		@variables VARCHAR(500) = NULL,

		-- Masivo
		@virtualAgentIds VARCHAR(600) = NULL
		AS
		BEGIN
			DECLARE @idArea SMALLINT, @userName varchar(40)

			IF @action = 1
			BEGIN
				SELECT
					va.idAgent AS idAgent,
					va.NameAgent AS nombre,
					ISNULL(CAST(va.idCampaign AS INT),0) AS idCampaign,
					ISNULL(va.concurrentSessionsLimit, 0) AS concurrentSessionsLimit,
					CAST(va.StatusAgent AS BIT) AS status,
					CAST(va.mediaType AS INT) as SubType,
					ISNULL(
						CASE 
							WHEN va.CampType = 0 THEN ci.descripcion 
							ELSE co.cam_descripcion
						END, ''N/A''
					) AS campName,
					ISNULL(
						CASE 
							WHEN va.CampType = 0 THEN ci.IDArea -- Campaña de entrada
							ELSE co.IDArea -- Campaña de salida
						END,
					0) AS IDArea,
					CAST(ISNULL(
						CASE 
							WHEN va.CampType = 0 THEN ig.graphic_id -- Icono para entrada
							ELSE og.graphic_id -- Icono para salida
						END, 0
					) AS int) AS campaignGraph,
					CAST(va.CampType AS int) CampType,
					ISNULL(
						CASE 
							WHEN va.CampType = 0 THEN CAST(ci.Status AS BIT) -- Estado de la campaña de entrada
							ELSE CAST(co.cam_procesando AS BIT) -- Estado de la campaña de salida
						END, 0
					) AS IsActiveCampaign, -- Devuelve 1 o 0
					ISNULL(
						CASE 
							WHEN (va.CampType = 0 AND ci.chat = 5) THEN wn.Number
							WHEN (va.CampType = 1 AND co.CampType = 5) THEN wno.Number
							ELSE ''N/A''
						END, ''N/A''
					) AS NumeroAsociado,
					CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como ''YYYY-MM-DD''
					ISNULL(
						CASE 
							WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '''' THEN ''N/A''
							ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como ''YYYY-MM-DD''
						END, ''N/A''
					) AS FechaUltimaModificacion, -- Devuelve ''YYYY-MM-DD'' o ''N/A''
					ISNULL(va.voice,1) as Voice,
					CAST(CASE
						WHEN va.instructions IS NULL OR va.instructions = '''' THEN 0
						ELSE 1
						END AS bit) AS HasInstructions
				FROM dbo.ccVirtualAgent va
				LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
				LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
				LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
				LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
				LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
				LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
				WHERE va.wasDeleted = 0
			END

			ELSE IF @action = 2
			BEGIN
				-- We validate the capacity defined in the setting 281 with the received value. 
				DECLARE @TotalOfConcurrentAgents INT, 
						@UsedConcurrentAgents INT

				IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent)
				BEGIN
					SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
					RETURN
				END

				SELECT @TotalOfConcurrentAgents = CAST(valor AS int) FROM ccSettings2 WHERE setting_id = 281
				SELECT @UsedConcurrentAgents = ISNULL(SUM(concurrentSessionsLimit), 0) FROM ccVirtualAgent

				IF((@UsedConcurrentAgents + @numberOfAgents) <= @TotalOfConcurrentAgents)
				BEGIN
					-- Creación de un nuevo agente virtual
					DECLARE @newModelId int;

					INSERT INTO dbo.ccVirtualAgent (
						nameAgent, 
						statusAgent, 
						createDateAgent, 
						latestUpdateDateAgent,
						concurrentSessionsLimit,
						responseTone,
						language,
						quantumAgentId,
						quantumRoleId,
						roleName,
						responseLength,
						ReplyGreeting,
						ReplyFarewell,
						ReplySystemFailure,
						ReplyNoUnderstanding,
						voice
					)
					VALUES (
						@nameAgent, 
						0, 
						GETDATE(),
						GETDATE(),
						@numberOfAgents,
						@responseTone,
						@languageAgent,
						@quantumAgentId,
						@quantumRoleId,
						@roleDescription,
						@responseLength,
						@replyGreeting,
						@replyFarewell,
						@replySystemFailure,
						@replyNoUnderstanding,
						@voiceID
					);

					SET @newModelId = SCOPE_IDENTITY();

					-- Activity History 
				
					SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT
							(SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
							getDate(), 
							@userName, 
							169,
							24,
							'''',
							'''',
							@nameAgent

					IF @campaignId = 0
					BEGIN
						SELECT ''Agent created correctly'' AS Result, 0 AS ErrorCode, @newModelId as IdAgent;
						RETURN
					END

					-- Invoke campaign association and return association results
		
					CREATE TABLE #associationResult (Result varchar(100), ErrorCode int, idAgent int, nameAgent varchar(255), idCampaign int, campaignName varchar(40))

					INSERT INTO #associationResult(Result, ErrorCode,idAgent,nameAgent,idCampaign,campaignName)
					EXEC dbo.ccsp_VirtualAgents
						 @action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@newModelId;

					SELECT Result, ErrorCode, idAgent as IdAgent FROM #associationResult
					RETURN
				END
				ELSE
				BEGIN
					SELECT ''There are not contracted agents available'' AS Result, 2 AS ErrorCode; 
				END
			END

			ELSE IF @action = 3 -- Elimination of virtual Agent
			BEGIN
				CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255), quantumAgentId VARCHAR(50))

				UPDATE dbo.ccVirtualAgent
				SET
					idCampaign = 0,
					mediaType = 0,
					campType = 0,
					wasDeleted = 1
				OUTPUT deleted.idAgent, deleted.nameAgent, deleted.quantumAgentId INTO #deletedVirtualAgents
				WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

				SELECT * FROM #deletedVirtualAgents
			END

			ELSE IF @action = 4 -- Change of associated campaign. Brings the info for Activity history
			BEGIN
				DECLARE @PreviousAgentData AS TABLE(
					idAgent INT,
					nameAgent VARCHAR(255),
					idCampaign SMALLINT,
					camptype TINYINT
				);

				IF(@campaignId <> 0)
				BEGIN
					-- *** VALIDATIONS FOR CAMPAIGN ASSIGNATION ***
					-- Campaign was deleted
					DECLARE @campaignArea AS SMALLINT

					IF @campType = 0
						SELECT @campaignArea = IDArea FROM ccInbound WHERE Inbound_id = @campaignId
					ELSE IF @campType = 1
						SELECT @campaignArea = IDArea FROM ccCamps WHERE cam_id = @campaignId

					IF @campaignArea IS NULL
					BEGIN
						SELECT ''Campaign was deleted'' AS Result, 3 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign
						RETURN
					END

						--- Campaign was assigned to another model
					IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType)
					BEGIN
						SELECT ''Campaign has already been assigned'' as Result, 4 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
						RETURN
					END

					--- Campaign doesn''t belong to the same wg than te user
					DECLARE @CampaignIsNotInUserWorkgroup  BIT = 0;

					IF NOT EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7) -- It''s not a superUser
					BEGIN
						SELECT @CampaignIsNotInUserWorkgroup =
							CASE WHEN NOT EXISTS (
								SELECT 1
								FROM dbo.ccRIAWorkGroupUsers AS userWG
									JOIN dbo.ccRIACampEspWG AS campaignWg ON campaignWg.IDWG = userWG.IDWG
								WHERE userWG.User_id    = @adminId
									AND campaignWg.Tipo       = @campType 
									AND campaignWg.IdCampEsp  = @campaignId
							  )
							  THEN 1 ELSE 0 END;

						IF @CampaignIsNotInUserWorkgroup = 1
						BEGIN
							SELECT ''Campaign doesn''''t belong to admin workgroups'' as Result, 5 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
							RETURN
						END
					END
				END

				UPDATE ccVirtualAgent SET idCampaign = @campaignId,
										  mediaType = @mediaType,
										  camptype = @campType,
										  latestUpdateDateAgent = GETDATE()
										  OUTPUT deleted.idAgent, deleted.nameAgent, deleted.idCampaign, deleted.campType INTO @PreviousAgentData
										  WHERE idAgent = @idVirtualAgent
				IF @campaignId <> 0
					BEGIN
						SELECT
							''Campaign changed'' AS Result,
							0 AS ErrorCode,
							va.idAgent,
							va.nameAgent,
							CAST(va.idCampaign as int) idCampaign,
							CASE 
								WHEN @campType = 0 THEN i.descripcion
								ELSE cout.cam_descripcion 
							END AS campaignName
						FROM ccVirtualAgent va
							LEFT JOIN ccInbound i ON va.idCampaign = i.Inbound_id AND @campType = 0
							LEFT JOIN ccCamps cout ON va.idCampaign = cout.cam_id AND @campType = 1
						WHERE va.idAgent = @idVirtualAgent;
					END
				ELSE
					BEGIN
						SELECT
							''Campaign retired'' AS Result,
							0 AS ErrorCode,
							pvd.idAgent,
							pvd.nameAgent,
							CAST(0 as int) idCampaign,
							CASE 
								WHEN pvd.camptype = 0 THEN i.descripcion
								ELSE cout.cam_descripcion 
							END AS campaignName
						FROM @PreviousAgentData pvd
							LEFT JOIN ccInbound i ON pvd.idCampaign = i.Inbound_id AND pvd.camptype = 0
							LEFT JOIN ccCamps cout ON pvd.idCampaign = cout.cam_id AND pvd.camptype = 1
					END

			END

			ELSE IF @action = 5 -- Status change
			BEGIN
				CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

				UPDATE ccVirtualAgent SET statusAgent = @statusAgent,
										latestUpdateDateAgent = GETDATE()
				OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
				WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) and statusAgent != @statusAgent

				SELECT * FROM #updatedVirtualAgents
			END

			ELSE IF @action = 6 --Check if there''s enabled related agent to camp 
			BEGIN
				DECLARE @result bit = 0;

				IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idCampaign = @campaignId)
				BEGIN
					SELECT @result = statusAgent from ccVirtualAgent where idCampaign = @campaignId
				END

				select @result
			
			END
			ELSE IF (@action = 7) --- Get virtual agents by campaign id and camptype
			BEGIN
				DECLARE @defaultVoiceId VARCHAR(MAX)
				SELECT @defaultVoiceId = QuantumVoiceId FROM ccVirtualAgentVoices WHERE IsDefault = 1

				SELECT 
				cva.idAgent
				, ISNULL(cva.quantumAgentId,'''') AS QuantumAgentId
				, ISNULL(cva.location,'''') AS Location
				, ISNULL('''','''')  AS ProjectId
				, CASE 
					WHEN cva.voice IS NULL OR cva.voice = '''' THEN @defaultVoiceId
					ELSE ISNULL(cvav.QuantumVoiceId, @defaultVoiceId)
					END AS Voice
				FROM dbo.ccVirtualAgent AS cva
				LEFT JOIN ccVirtualAgentVoices cvav ON cvav.ID = cva.voice
				WHERE cva.idCampaign = @campaignId AND cva.campType = @campType;
			END
			ELSE IF (@action = 8) --- Reload virtual agent association
			BEGIN
				IF (@campType = 0)
					BEGIN 
						SELECT 
						cva.idAgent AS IdAgentVirtual
						,cva.nameAgent AS NameAgentVirtual
						,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
						,CONVERT(INT, cva.idCampaign) AS IdCampaign
						, cva.campType AS CampType
					FROM ccVirtualAgent cva
					LEFT JOIN ccInbound ci ON cva.idCampaign = ci.Inbound_id AND cva.campType = @campType
					WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
					END
				ELSE 
				BEGIN 
						SELECT 
						cva.idAgent AS IdAgentVirtual
						,cva.nameAgent AS NameAgentVirtual
						,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
						,CONVERT(INT, cva.idCampaign) AS IdCampaign
						, cva.campType AS CampType
					FROM ccVirtualAgent cva
					LEFT JOIN ccCamps cc ON cva.idCampaign = cc.cam_id AND cva.campType = @campType
					WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
					END
				END
			ELSE IF (@action = 9) --Get FileLocation from ccVirtualAgentVoices
			BEGIN
				select Name, FileName from ccVirtualAgentVoices where ID = @voiceID
			END
			ELSE IF (@action = 10) --Update voice
			BEGIN
				if exists(select * from ccVirtualAgent where idAgent=@idVirtualAgent)
				BEGIN
					update ccVirtualAgent set voice=@voiceID where idAgent=@idVirtualAgent
					select 1
				END
				ELSE BEGIN
					select 0
				END
			END
			ELSE IF(@action = 11) --get voice library
			BEGIN 
				select ID,Name,Gender, FileName, Language from ccVirtualAgentVoices
			END
			ELSE IF(@action = 12) -- get voice info by its Id
			BEGIN
				select QuantumVoiceId from ccVirtualAgentVoices where ID = @voiceID
			END
			ELSE IF (@action = 13) --Register model definition (Objectives, instructions, rules and variables)
			BEGIN
				DECLARE @modifiedModelName VARCHAR(255);

				UPDATE ccVirtualAgent
				SET
					objective   = @objective,
					rules       = @rules,
					instructions = @instructions,
					scriptAgent = @variables,
					latestUpdateDateAgent = GETDATE(),
					statusAgent = CASE WHEN idCampaign <> 0 THEN 1 ELSE 0 END
				WHERE idAgent = @idVirtualAgent;

				IF @@ROWCOUNT = 1
				BEGIN
					SELECT @modifiedModelName = nameAgent
					FROM ccVirtualAgent
					WHERE idAgent = @idVirtualAgent;

					SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

					-- ACTIVITY HISTORY REGISTER
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT
							(SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
							getDate(), 
							@userName, 
							170,
							24,
							''VA_STRUCTURE_CONFIGURATION'',
							'''',
							@modifiedModelName
				
					SELECT 0 AS ErrorCode
				END
				ELSE
				BEGIN
					SELECT 1 AS ErrorCode
				END

			END
			ELSE IF (@action = 14)
			BEGIN
				SELECT
					idAgent As IdAgent,
					nameAgent As Nombre,
					statusAgent As Status,
					ISNULL(concurrentSessionsLimit,0) As concurrentSessionsLimit,
					ISNULL(CAST(idCampaign AS INT),0) As idCampaign,
					ISNULL(CAST(mediaType AS INT),0) As SubType,
					ISNULL(CAST(campType AS INT),0) As campType,
					ISNULL(location,'''') As location,
					ISNULL(quantumAgentId,'''') As QuantumAgentId,
					ISNULL(scriptAgent,'''') As scriptAgent,
					ISNULL(voice,'''') As voice,
					ISNULL(ReplyGreeting,'''') As ReplyGreeting,
					ISNULL(ReplyFarewell,'''')As ReplyFarewell,
					ISNULL(ReplySystemFailure,'''') As ReplySystemFailure,
					ISNULL(ReplyNoUnderstanding,'''') As ReplyNoUnderstanding,
					ISNULL(language,0) As language,
					ISNULL(responseTone,0) As responseTone,
					ISNULL(roleName,'''') As RolName,
					ISNULL(responseLength,0) As responseLength,
					ISNULL(quantumRoleId,0) As quantumRolId,
					ISNULL(objective,'''') As objective,
					ISNULL(rules,'''') As rules,
					ISNULL(instructions,'''') As instructions
				FROM 
					ccVirtualAgent
				WHERE 
					idAgent = @idVirtualAgent
			END
			ELSE IF (@action = 15) -- UPDATE Agent Virtual 
			BEGIN
				DECLARE @AreaName  NVARCHAR(200),
						@Login NVARCHAR(200),
						@NameCampaing NVARCHAR(200);

				EXEC InsertLogAdminGalatea @action = 1,
											@tableName = ''ccVirtualAgent'',
											@columnNameId = ''idAgent'',
											@valueId = @idVirtualAgent,
											@userId = @adminId
				CREATE TABLE #ccVirtualAgentTable (
					columnInfo varchar(255),
					dataInfo varchar(255),
					identifierInfo varchar(255)
				)

				UPDATE ccVirtualAgent
				SET
					nameAgent = CASE 
									WHEN @nameAgent IS NOT NULL 
										 AND LTRIM(RTRIM(@nameAgent)) <> '''' 
										 AND @nameAgent <> nameAgent 
									THEN @nameAgent 
									ELSE nameAgent 
								END,

					latestUpdateDateAgent = GETDATE(),

					responseTone = CASE 
									   WHEN @responseTone IS NOT NULL 
											AND @responseTone > 0 
											AND (@responseTone <> responseTone OR responseTone IS NULL)
									   THEN @responseTone 
									   ELSE responseTone 
								   END,

					language = CASE 
									 WHEN @languageAgent IS NOT NULL 
										  AND (@languageAgent <> language OR language IS NULL)
									 THEN @languageAgent 
									 ELSE language 
								 END,

					concurrentSessionsLimit = CASE 
												  WHEN @numberOfAgents IS NOT NULL 
													   AND @numberOfAgents > 0 
													   AND (@numberOfAgents <> concurrentSessionsLimit OR concurrentSessionsLimit IS NULL)
												  THEN @numberOfAgents 
												  ELSE concurrentSessionsLimit 
											  END,

					responseLength = CASE 
										 WHEN @responseLength IS NOT NULL 
											  AND @responseLength > 0 
											  AND (@responseLength <> responseLength OR responseLength IS NULL)
										 THEN @responseLength 
										 ELSE responseLength 
									 END,

					ReplyGreeting = CASE 
										WHEN @replyGreeting IS NOT NULL 
											 AND LTRIM(RTRIM(@replyGreeting)) <> '''' 
											 AND (@replyGreeting <> ReplyGreeting OR ReplyGreeting IS NULL)
										THEN @replyGreeting 
										ELSE ReplyGreeting 
									END,

					ReplyFarewell = CASE 
										WHEN @replyFarewell IS NOT NULL 
											 AND LTRIM(RTRIM(@replyFarewell)) <> '''' 
											 AND (@replyFarewell <> ReplyFarewell OR ReplyFarewell IS NULL)
										THEN @replyFarewell 
										ELSE ReplyFarewell 
									END,

					ReplySystemFailure = CASE 
											 WHEN @replySystemFailure IS NOT NULL 
												  AND LTRIM(RTRIM(@replySystemFailure)) <> '''' 
												  AND (@replySystemFailure <> ReplySystemFailure OR ReplySystemFailure IS NULL)
											 THEN @replySystemFailure 
											 ELSE ReplySystemFailure 
										 END,

					ReplyNoUnderstanding = CASE 
											   WHEN @replyNoUnderstanding IS NOT NULL 
													AND LTRIM(RTRIM(@replyNoUnderstanding)) <> '''' 
													AND (@replyNoUnderstanding <> ReplyNoUnderstanding OR ReplyNoUnderstanding IS NULL)
											   THEN @replyNoUnderstanding 
											   ELSE ReplyNoUnderstanding 
										   END,

					voice = CASE 
								WHEN @voiceID IS NOT NULL 
									 AND @voiceID > 0 
									 AND (@voiceID <> voice OR voice IS NULL)
								THEN @voiceID 
								ELSE voice 
							END
				WHERE idAgent = @idVirtualAgent;

				IF @campaignId IS NOT NULL
				BEGIN
					EXEC dbo.ccsp_VirtualAgents
						 @action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@idVirtualAgent;
					IF @campaignId <> 0
					BEGIN
						IF @mediaType = 11
						BEGIN
							SELECT
								@NameCampaing = [descripcion]
							FROM ccInbound
							WHERE inbound_id = @campaignId
						END
						ELSE
							SELECT
								@NameCampaing = cam_descripcion
							FROM ccCamps
							WHERE cam_id = @campaignId
					END
				END

				EXEC InsertLogAdminGalatea @action = 2,
											@tableName = ''ccVirtualAgent'',
											@columnNameId = ''idAgent'',
											@valueId = @idVirtualAgent,
											@userId = @adminId,
											@tableTemp = ''#ccVirtualAgentTable''

				SELECT  @Login = U.[Login],
						@AreaName = A.[AreaName]
				FROM ccUsers AS U
				LEFT JOIN ccRIACat_Areas AS A
				  ON A.IDArea = U.IDArea
				WHERE U.User_id = @adminId;

				SELECT @NameAgent = v.nameAgent
				FROM dbo.ccVirtualAgent AS v
				WHERE v.idAgent = @idVirtualAgent;

				;WITH src AS (
					SELECT 
						CCVA.*,
						ROW_NUMBER() OVER (
							PARTITION BY CCVA.identifierInfo 
							ORDER BY CCVA.columnInfo 
						) AS rn
					FROM #ccVirtualAgentTable AS CCVA
				)
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT
					@AreaName,
					GETDATE(),
					@Login,
					171,
					24,
					S.identifierInfo,
					CASE
						WHEN S.identifierInfo IS NOT NULL AND S.identifierInfo <> '''' THEN 
							CASE
								WHEN S.identifierInfo = ''VA_LANGUAGE'' THEN
									CASE S.dataInfo
										WHEN 1 THEN ''VA_ENGLISH_EN''
										WHEN 2 THEN ''VA_PORTUGUESE_PT''
										ELSE ''VA_SPANISH_ES''
									END
								WHEN S.identifierInfo = ''VA_TONE_OF_VOICE'' THEN
									CASE S.dataInfo
										WHEN 1 THEN ''VA_FORTHRIGHT_AND_CONCISE''
										WHEN 2 THEN ''VA_SYMPATHETIC_AND_WARM''
										WHEN 3 THEN ''VA_PERSUASIVE_AND_ACTION_ORIENTED''
										WHEN 4 THEN ''VA_NEUTRAL_AND_OBJECTIVE''
										WHEN 5 THEN ''VA_RELAXED_AND_FRIENDLY''
										ELSE ''VA_NONE_TV''
									END
								WHEN S.identifierInfo = ''VA_RESPONSE_LENGTH'' THEN
									CASE S.dataInfo
										WHEN 1 THEN ''VA_SHORT_RESPONSE''
										WHEN 2 THEN ''VA_MEDIUM_RESPONSE''
										WHEN 3 THEN ''VA_LONG_RESPONSE''
										ELSE ''VA_NONE''
									END
								WHEN S.identifierInfo = ''VA_VIRTUAL_AGENT_CAMPAIGN'' THEN
									CASE S.dataInfo
										WHEN 0 THEN ''VA_NONE'' 
										ELSE @NameCampaing
									END
								WHEN S.identifierInfo = ''VA_VOICE_TYPE'' THEN
									CASE S.dataInfo
										WHEN 1 THEN ''VA_VOICE_FEMALE''
										WHEN 3 THEN ''VA_VOICE_FEMALE''
										WHEN 5 THEN ''VA_VOICE_FEMALE''
										WHEN 2 THEN ''VA_VOICE_MALE''
										WHEN 4 THEN ''VA_VOICE_MALE''
										WHEN 6 THEN ''VA_VOICE_MALE''
										ELSE ''VA_VOICE_MALE''
									END
								WHEN S.identifierInfo = ''VA_SCRIPTED_RESPONSES'' THEN
									''VA_RESPONSES'' 
								ELSE S.dataInfo
							END
						ELSE ''''
					END,
					@NameAgent
				FROM src AS S
				WHERE NULLIF(LTRIM(RTRIM(S.identifierInfo)), '''') IS NOT NULL
				  AND NOT (S.identifierInfo = ''VA_SCRIPTED_RESPONSES'' AND S.rn > 1)

			
				EXEC InsertLogAdminGalatea @action = 3,
											@tableName = ''ccVirtualAgent'',
											@columnNameId = ''idAgent'',
											@valueId = @idVirtualAgent,
											@userId = @adminId

				IF OBJECT_ID(N''tempdb..#ccVirtualAgentTable'') IS NOT NULL
				DROP TABLE #ccVirtualAgentTable

				SELECT ''Agent successfully updated'' AS Result, 0 AS ErrorCode, @idVirtualAgent as IdAgent;
			END
		END	
	 '
    EXEC(@sql)

    ------------------------------------- END JUAN MEDINA -------------------------------------

	
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
