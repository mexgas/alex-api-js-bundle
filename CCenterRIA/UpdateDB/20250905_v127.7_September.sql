/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
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
    SET @versionfix = 7
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

    --- BEGIN RECG #3684--

    SET @process = '#3684 Add columns Received & UnSent to ccWAConversationsResult if not exists';

    SET @sql = '

    IF COL_LENGTH(''dbo.ccWAConversationsResult'', ''Received'') IS NULL
    BEGIN
        ALTER TABLE dbo.ccWAConversationsResult
            ADD Received INT NOT NULL
                CONSTRAINT DF_ccWAConversationsResult_Received DEFAULT(0);

    END;

    ';

    EXEC(@sql);


    SET @process = '#3684 Add columns Received & UnSent to ccWAConversationsResult if not exists';

    SET @sql = '

    IF COL_LENGTH(''dbo.ccWAConversationsResult'', ''UnSent'') IS NULL
    BEGIN
        ALTER TABLE dbo.ccWAConversationsResult
            ADD UnSent INT NOT NULL
                CONSTRAINT DF_ccWAConversationsResult_UnSent DEFAULT(0);

    END;

    ';

    EXEC(@sql);



    SET @process = '#3684 Add columns Received & UnSent to ccWAConversationsResult if not exists';

    SET @sql = '
     UPDATE dbo.ccWAConversationsResult
            SET Received = 0
        WHERE Received IS NULL;



        UPDATE dbo.ccWAConversationsResult
            SET UnSent = 0
        WHERE UnSent IS NULL;

    ';

    EXEC(@sql);

    --- END RECG #3684--

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
    EXEC(@sql);
  ------------------------------------ END CARLOS MUÑOZ ------------------------------------

	SET @process = 'Reintegration of sp'
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_OUTUpdateDialJobCommon'')
	BEGIN
		DROP PROCEDURE ccsp_OUTUpdateDialJobCommon;
	END
	'
	EXEC(@sql);

	SET @sql = '
		CREATE PROCEDURE ccsp_OUTUpdateDialJobCommon
		@action int,
		@callout_id     INT,
		@cam_id INT=0,
		@prioridadLlamada CHAR(8) OUTPUT,
		@Telefono VARCHAR(15)='''' OUTPUT

		AS
		SET NOCOUNT ON
		if @action=1 begin
			DECLARE @ExistePriorityOrder TINYINT
			SELECT 
				@prioridadLlamada = priorityCall,
				@ExistePriorityOrder = CASE WHEN callout_id IS NOT NULL THEN 1 ELSE 0 END
			FROM ccoCallPriorityOrder WITH (NOLOCK)
			WHERE callout_id = @callout_id

			IF @ExistePriorityOrder IS NULL
			BEGIN
				SELECT @prioridadLlamada = Prioridad
				FROM ccCampsPrioridadTel WITH (NOLOCK)
				WHERE cam_id = @cam_id

				INSERT INTO ccoCallPriorityOrder 
				VALUES (@callout_id, @prioridadLlamada)
			END
		end
		if @action=2 begin
			-- Cambiar la prioridad
			SET @prioridadLlamada = dbo.ChangePriorityCall(@prioridadLlamada)

			-- Actualizar la prioridad
			UPDATE ccoCallPriorityOrder WITH (rowlock)
			SET priorityCall = @prioridadLlamada
			WHERE callout_id = @callout_id

			-- Seleccionar el pr�ximo tel�fono
			DECLARE @sSQL NVARCHAR(MAX)
			SET @sSQL = ''SELECT @outA = RTRIM(LEFT(LTRIM(cal_telefono'' 
				+ CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
				+ ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
				+ ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
				+ ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
				+ ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
				+ ''+''''         ''''),13)) FROM ccoCallsOutSource WITH (NOLOCK) WHERE callout_id=''
				+ CAST(@callout_id AS VARCHAR(15))

			EXEC sp_executesql @sSQL, N''@outA VARCHAR(15) OUTPUT'', @outA = @Telefono OUTPUT
		end
		SET NOCOUNT OFF
		'
	EXEC(@sql);
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
                27,
                ''N/A'',
                1)
        END
		ELSE
		BEGIN
			UPDATE ccPermissions set OrderGrl = 27 where Permissions_Id = 10044
		END

        IF NOT EXISTS(SELECT * FROM ccPermissions WHERE Permissions_Id = 10045)
        BEGIN
            INSERT INTO ccPermissions VALUES (
                10045,
                ''Visualizar modulo agente virtual'',
                ''RolesPermissionViewVirtualAgentModule'',
                0,
                0,
                28,
                ''N/A'',
                1)
        END
		ELSE
		BEGIN
			UPDATE ccPermissions set OrderGrl = 28 where Permissions_Id = 10045
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

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION_OBJECTIVE'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION_OBJECTIVE'', ''Objetivo'', ''Objective'', ''Objetivo'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION_RULE'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION_RULE'', ''Reglas generales'', ''General rules'', ''Regras gerais'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION_SCRIPT'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION_SCRIPT'', ''Guion'', ''Script'', ''Script'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION_OBJECTIVE_RULE'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION_OBJECTIVE_RULE'', ''Objetivo, Reglas generales'', ''Objective, General rules'', ''Objetivo, Regras gerais'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION_OBJECTIVE_SCRIPT'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION_OBJECTIVE_SCRIPT'', ''Objetivo, Guion'', ''Objective, Script'', ''Objetivo, Script'')
		END

		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''VA_STRUCTURE_CONFIGURATION_RULE_SCRIPT'')
		BEGIN
		 INSERT INTO ccGalateaIdentifiers VALUES(''VA_STRUCTURE_CONFIGURATION_RULE_SCRIPT'', ''Reglas generales, Guion'', ''General rules, Script'', ''Regras gerais, Script'')
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
		IF NOT EXISTS (SELECT 1 FROM ccRoles_Permissions WHERE Rol_Id = 1 AND Permissions_Id = 10044)
		BEGIN
		 insert into ccRoles_Permissions values (1, 10044)
		END
		'
	EXEC(@sql);

	SET @process = 'Adding permission 10045 to root'
    SET @sql = '
        IF NOT EXISTS (SELECT 1 FROM ccRoles_Permissions WHERE Rol_Id = 1 AND Permissions_Id = 10045)
		BEGIN
		 insert into ccRoles_Permissions values (1, 10045)
		END
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
		--   @identifiers: comma-delimited string (''10001,10002'')
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
    
	------------------------------------ BEGIN Octavio Ortiz ------------------------------------
	-- ccVirtualAgent
	SET @process = 'AlterTable ccVirtualAgent';
	SET @sql = '
	IF COL_LENGTH(''ccVirtualAgent'', ''OriginalAgentId'') IS NULL
	BEGIN
		ALTER TABLE ccVirtualAgent
			ADD 
				CopiesCount INT NOT NULL DEFAULT(0),
				OriginalAgentId INT NOT NULL DEFAULT(0);
	END
	';
	EXEC(@sql);

	-- insert de valores de operacion para duplicacion 
	SET @process = 'Insert into ccGalateaOperations - Clone Agent';
	SET @sql = '
	IF NOT EXISTS (
		SELECT 1
		FROM ccGalateaOperations
		WHERE OperationId = 174
	)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (174, ''Clonar modelo'', ''Clone model'', ''Clonar modelo'');
	END
	';
	EXEC(@sql);

	---------------------------------------END Octavio Ortiz-------------------------------------

    ------------------------------------------------ BEGIN JUAN MEDINA ------------------------------------------------
	SET @process = 'Sprint 5 - DELETE PERMISSIONS CENTER SCRIPT '
    SET @sql = '
        IF EXISTS (Select 1 From ccRoles_Permissions where Permissions_Id = 10003)
		BEGIN
			DELETE ccRoles_Permissions  where Permissions_Id = 10003
		END

		IF EXISTS (Select 1 From ccPermissions where Permissions_Id = 10003)
		BEGIN
			DELETE ccPermissions  where Permissions_Id = 10003
		END 
	'
    EXEC(@sql)

		SET @process = 'Sprint 5 - DROP PROCEDURE GetReportMenus'
    SET @sql = '
        If Exists (Select 1 From sys.procedures Where name = N''GetReportMenus'')
        Begin
            DROP PROCEDURE GetReportMenus
        End
	'
    EXEC(@sql)

	SET @process = 'Sprint 5 - CREATE PROCEDURE GetReportMenus - Delete View Menu Email'
    SET @sql = '
		CREATE PROCEDURE [dbo].[GetReportMenus]
		@userId int,
		@activeChat tinyint,
		@activeAVRS tinyint,
		@activeCRM tinyint=0,
		@activeEmail tinyint=0,
		@activeTwitter tinyint=0
		AS
		BEGIN

		select menu_id,
			substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
			nullif(parent,menu_id) as parent,Nivel,ordengral,release
			into #tempCCMenus
			from ccMenus with(nolock)
			where type = 3 
			and menu_id >= 2000 
			and menu_id NOT IN (10010,10020,10030,10040)--Stop showing email menu in reports
			and(
				(menu_id not in (
				3130,3131,3132,3133,3134,3135,3136,
				8050,8060,8061,8062,8063,8070,8071,8072,8080,
				9000,9010,
				10000,10010,10020,10030,10040,
				11000,11010,11020,11030,11040
				))
				or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
				or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
				or  (@activeCRM = 1 and menu_id in (9000,9010) )
				or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
				or (@activeTwitter = 1 and menu_id in (11000,11010,11020,11030,11040))
				)
				order by menu_id


		;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent,release)
		AS
		(
			select
				distinct b.Nivel as Nivel,
				b.menu_descrip as menu_descrip,
				b.menu_id as menu_id,
				b.ordengral as ordengral,
				b.parent as parent,b.release
				from #tempCCMenus as b
				inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
			UNION ALL


		--RECURSIViDAD
			select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent,a.release
				from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
		)

		select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by ordengral,menu_id

		select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release,parent from #tempCCMenusUser A
		where  menu_id not in
			(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
		order by ordengral,menu_id

		drop table #tempCCMenus
		drop table #tempCCMenusUser

		END
	'
    EXEC(@sql)

	------------------------------------------------ END JUAN MEDINA ------------------------------------------------


	--- BEGIN MAGV KR234004--

		SET @process = 'KR234004 Add manualCRM  to ccoLogDials'
	SET @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''manualCRM'' AND OBJECT_ID = OBJECT_ID(''ccoLogDials''))
		begin
			ALTER TABLE ccoLogDials
			ADD manualCRM BIT NULL;
		end'
	exec (@sql)
		SET @process = 'KR234005 Add columns to table ccCamps'
		SET @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''rotativeAlgorithmManual'' AND OBJECT_ID = OBJECT_ID(''ccCamps''))
		begin
			ALTER TABLE ccCamps
			ADD rotativeAlgorithmManual smallint NULL;
		end
		IF not exists (SELECT * FROM SYS.columns WHERE name=''idAniListManual'' AND OBJECT_ID = OBJECT_ID(''ccCamps''))
		begin
			ALTER TABLE ccCamps
			ADD idAniListManual SMALLINT NULL;
		end
		IF not exists (SELECT * FROM SYS.columns WHERE name=''selectRotationManualDialing'' AND OBJECT_ID = OBJECT_ID(''ccCamps''))
		begin
			ALTER TABLE ccCamps
			ADD selectRotationManualDialing bit NULL;
		end
		'
	exec (@sql)
	--- END MAGV KR234004 ----

---------------------------BEGIN Octavio Ortiz Nova monti 8 fixes--------------------------------------------------


/* =========================================================================================
   ccsp_GalateaDeleteCampaignAndACD
   ========================================================================================= */

SET @process = 'Drop Procedure [dbo].[ccsp_GalateaDeleteCampaignAndACD]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaDeleteCampaignAndACD'')
        Begin
            DROP PROCEDURE ccsp_GalateaDeleteCampaignAndACD
        End';
EXEC(@sql);

SET @process = 'Create Procedure [dbo].[ccsp_GalateaDeleteCampaignAndACD]';
SET @sql = N'
CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
    @userId           SMALLINT,
    @DeleteCamId      VARCHAR(MAX),
    @DeleteACDGroupId VARCHAR(MAX),
    @moduleId         SMALLINT = 49
AS
BEGIN

    IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete;
    SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(c.CampType, 0) AS MediaType
    INTO #CampsDelete
    FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
    inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
    left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1;

    IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete;
    SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, cast(ISNULL(chat, 0) as int) AS MediaType
    INTO #ACDDelete
    FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
    inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
    left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0;

    IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
    begin
        select ''-1'' AS Result
        return
    end

    IF datalength(@DeleteCamId) > 0
    BEGIN

        if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
            --Borra las calificacion con reprogramacion
            delete ccCalifCamp from ccInbound A
            inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
            inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
            where A.cam_id in (select DeleteCamId from #CampsDelete)
            --Borra las subcalificacion con reprogramacion
            delete rel from ccInbound A
            inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
            inner join ccTipoCalif C on B.calif_id=C.calif_id
            inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
            inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
            where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

            update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

        end

        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
        select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

        delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
        select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

        delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
        delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

        IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog;
        SELECT ca.AreaName,
                GETDATE() operationDate,
                27 operationType,
                (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                @moduleId module_id,
                c.cam_descripcion value,
                ca.AreaName AS target
        INTO #CampLog
        FROM ccRIACat_Areas ca
        Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
        WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT A.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
        CASE
            WHEN CampType = 6 THEN 45
            WHEN CampType = 5 THEN 47
            WHEN CampType = 9 THEN 49
            WHEN CampType = 7 THEN 51
        ELSE 43 END,
        3,
        '''',
        '''',
        c.cam_descripcion
        FROM ccRIACat_Areas A INNER JOIN ccCamps c on A.IDArea = c.IDArea
        where c.cam_id in (select DeleteCamId from #CampsDelete)

        Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)

        update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
        where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5

        update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)

        update ccMetaWhatsAppNumbers set Cam_Id = 0 where Cam_Id in (select DeleteCamId from #CampsDelete)

    END

    IF datalength(@DeleteACDGroupId) > 0
    BEGIN

        if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
        begin
                update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
        end

        IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD;
        SELECT DISTINCT(IDWG)
        INTO #AllWGACD
        FROM ccRIACampEspWG ce
        WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
        select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
        from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
        where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
        select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
        from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
        where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

        delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
        delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

        IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog;
        SELECT ca.AreaName,
                GETDATE() operationDate,
                28 operationType,
                (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                @moduleId module_id,
                i.descripcion value,
                ca.AreaName AS target
        INTO #ACDLog
        FROM ccRIACat_Areas ca
        inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
        WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT a.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
        CASE
            WHEN chat = 5 THEN 41
            WHEN chat = 1 THEN 65
            WHEN chat = 11 THEN 156
            ELSE 61 END,
        3,
        '''',
        '''',
        i.descripcion
        FROM ccRIACat_Areas a inner join ccInbound i on a.IDArea = i.IDArea
        WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        Update ccInbound set IDArea = null, cam_id = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))
            begin
                update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
        end
        if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))
            begin
                update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
        end
        update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

        if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
            begin
                update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        end
        update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)

        update ccMetaWhatsAppNumbers set Inbound_Id = 0 where Inbound_Id in (select DeleteACDId from #ACDDelete)

    END

    IF datalength(@DeleteCamId) > 0
        Insert into ccRIALog Select * from #CampLog
    IF datalength(@DeleteACDGroupId) > 0
        Insert into ccRIALog Select * from #ACDLog

    SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
    UNION
    SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete

    IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
    IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
    IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
END
';
EXEC(@sql);

---------------------------------END Octavio Ortiz-----------------------------------------------------------------


	--------------------------------- BEGIN 20250905.0.0 ------------------------------------------------
	SET @process = 'ALTER FUNCTION [dbo].[Completa] Validar Extension para pruebas'
    SET @sql = 'ALTER FUNCTION [dbo].[Completa] (@phone VARCHAR(32), @pais VARCHAR(2) = '''', @cldLocal VARCHAR(5) = '''')
RETURNS VARCHAR(32)
AS
BEGIN
    declare @lenExt int
    select @lenExt= valor from ccsettings where setting_id=108

    if @lenExt=len(@phone) return @phone

    DECLARE @resultado VARCHAR(32)
    DECLARE @ld VARCHAR(7)
    DECLARE @isLocal BIT
    IF @pais = ''''
    BEGIN
        SELECT @pais = valor
        FROM ccSettings WITH (NOLOCK)
        WHERE setting_id = 104
    END
    IF @cldLocal = ''''
    BEGIN
        SELECT @cldLocal = valor
        FROM ccSettings WITH (NOLOCK)
        WHERE setting_id = 17
    END
    SELECT @phone = dbo.limpia(@phone)
    SELECT @resultado = @phone
    DECLARE @lenPhone INT, @lenLd INT
    SET @lenPhone = len(@resultado)
    SET @lenLd = len(@cldLocal)
    IF @pais = 1
    BEGIN --Empieza Mexico
        IF @lenPhone < 10
        BEGIN
            RETURN ''E_NV_Longitud'';
        END
        IF @lenPhone = 12 AND left(@phone, 2) <> ''01''
        BEGIN
            RETURN ''E_NV_Longitud'';
        END
        IF @lenPhone = 13 AND left(@phone, 3) NOT IN (''044'', ''045'')
        BEGIN
            RETURN ''E_NV_Longitud'';
        END
        SET @resultado = right(@resultado, 10)
        SET @isLocal = 0
        DECLARE @specialDialPlan TINYINT
        SELECT @specialDialPlan = valor
        FROM ccsettings WITH (NOLOCK)
        WHERE setting_id = 195
        IF EXISTS (
                SELECT TOP 1 area
                FROM ccRiaArecode NOLOCK
                WHERE area = left(@resultado, 3)
                )
            SELECT @ld = left(@resultado, 3), @isLocal = 1
        ELSE IF EXISTS (
                SELECT TOP 1 area
                FROM ccRiaArecode NOLOCK
                WHERE area = left(@resultado, 2)
                )
            SELECT @ld = left(@resultado, 2), @isLocal = 1
        ELSE
        BEGIN
            SET @ld = @cldLocal
            IF left(@resultado, len(@ld)) = @ld
            BEGIN
                SET @isLocal = 1
            END
        END
        SET @lenLd = len(@ld)
        IF @specialDialPlan = 1
        BEGIN
            --Number local 10 digit
            --Number LD 12 digit
            --Number Cell 13 digit
            SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE ''01'' + @resultado END --10 Dig Local, LD
                    WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE @phone END --12 Dig Local, LD
                    WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
                    ELSE ''E_NV_Longitud'' END --Other Long
        END
        ELSE IF @specialDialPlan = 0
        BEGIN
            --Number local 7 o 8 digit
            --Number LD 12 digit
            --Number Cell 13 digit
            SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE ''01'' + @resultado END --10 Dig Local, LD
                    WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE @phone END --12 Dig Local, LD
                    WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
                    ELSE ''E_NV_Longitud'' END
        END
        --Termina Mexico
        RETURN @resultado
    END
    ELSE IF @pais = 2
    BEGIN -- Empieza Argentina
        SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 3) OR (@lenPhone = 6 AND @lenLd = 4) THEN @resultado
                        -- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
                        -- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
                WHEN @lenPhone = 8 THEN CASE WHEN @lenLd = 4 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado END ELSE CASE WHEN @lenLd = 2 THEN @resultado END END
                        -- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
                WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''E_NV_Cel'' END
                        -- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
                        -- Si es diferente se le agrega un 0 para llamadas de larga distancia
                WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''0'' + @resultado END END
                        -- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
                        -- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
                WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END
                        -- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
                        -- si no es local se le agrega el 0 y se marca el numero
                WHEN @lenPhone = 12 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN CASE WHEN substring(@resultado, @lenLd + 1, 2) = ''15'' THEN right(@resultado, 12 - @lenLd) ELSE ''E_NV_Cel'' END ELSE ''0'' + @resultado END
                        -- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
                WHEN @lenPhone = 13 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN substring(@resultado, @lenLd + 2, 12 - @lenLd) ELSE @resultado END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
        --Termina Argentina
        RETURN @resultado
    END
    ELSE IF @pais = 3
    BEGIN --Empieza colombia
        SELECT @resultado = CASE
                --Si son 7 digitos, se regresa igual
                WHEN @lenPhone = 7 THEN @resultado
                        --Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
                WHEN @lenPhone = 8 THEN CASE WHEN left(@resultado, 1) = @cldLocal THEN right(@resultado, 7) ELSE @resultado END
                        -- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
                WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN ''0'' + @resultado ELSE ''E_NV_Cel'' END
                        --Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
                        --prefijo de celular
                WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
        -- Termina Colombia
        RETURN @resultado
    END
    ELSE IF @pais = 4
    BEGIN --Empieza USA
        SELECT @resultado = CASE @lenPhone WHEN 3 THEN CASE @resultado WHEN ''911'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN @resultado WHEN 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE ''1'' + @resultado END WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''1'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END ELSE ''E_NV_Longitud'' END
        --Termina USA
        RETURN @resultado
    END
    ELSE IF @pais = 5
    BEGIN --5:Chile
        SELECT @resultado = CASE @lenPhone WHEN 6 THEN @resultado WHEN 7 THEN @resultado
                        -- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
                WHEN 8 THEN CASE WHEN @cldLocal = left(@resultado, @lenLd) THEN right(@resultado, 8 - @lenLd) ELSE CASE WHEN left(@resultado, 1) IN (8, 9) THEN ''09'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''6'' THEN CASE WHEN left(@resultado, 2) IN (61, 63, 64, 65, 67) THEN @resultado ELSE ''09'' + @resultado END ELSE CASE WHEN left(@resultado, 1) = ''7'' THEN CASE WHEN left(@resultado, 2) IN (71, 72, 73, 75) THEN @resultado ELSE ''09'' + @resultado END ELSE @resultado END END END END
                        -- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
                        -- de telefonia voIp se le agrega el 0 al inicio
                WHEN 9 THEN CASE WHEN @cldLocal = left(@resultado, 2) THEN right(@resultado, 7) ELSE CASE WHEN left(@resultado, 2) IN (41, 32, 65) THEN @resultado ELSE CASE WHEN left(@resultado, 2) = ''44'' THEN ''0'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''9'' AND substring(@resultado, 2, 1) IN (6, 7, 8, 9) THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END END END END WHEN 10 THEN CASE WHEN left(@resultado, 2) = ''09'' THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
        -- Termina Chile
        RETURN @resultado
    END
    IF @pais = 6
    BEGIN -- Venezuela
        SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 10 THEN ''0'' + @resultado WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
            --Termina Venezuela
    ELSE IF @pais = 7
    BEGIN --7: Reino Unido
        SELECT @resultado = CASE @lenPhone WHEN 11 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''0'' + @resultado END WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END WHEN 8 THEN CASE WHEN substring(@resultado, 1, 2) = ''08'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN CASE WHEN left(@resultado, 1) = ''8'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
            -- Termina UK
    ELSE IF @pais = 8
    BEGIN -- arabia saudita
        SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 8 THEN CASE substring(@resultado, 1, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE ''0'' + @resultado END WHEN 9 THEN CASE substring(@resultado, 1, 1) WHEN ''5'' THEN ''0'' + @resultado WHEN ''0'' THEN CASE substring(@resultado, 2, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE @resultado END ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE substring(@resultado, 2, 1) WHEN ''5'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 11 THEN CASE substring(@resultado, 2, 1) WHEN ''8'' THEN CASE substring(@resultado, 3, 3) WHEN ''111'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE CASE WHEN substring(@resultado, 3, 3) = ''510'' OR substring(@resultado, 3, 3) = ''511'' THEN @resultado ELSE ''E_NV_Longitud'' END END WHEN 13 THEN @resultado ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END -- arabia saudita
    ELSE IF @pais = 9
    BEGIN --Australia
        SELECT @resultado = CASE @lenPhone WHEN 8 THEN
                        /*case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,@cldLocal)
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
                        CASE substring(@resultado, 1, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @cldLocal + @resultado END
                        /*else case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,''04'')
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
    ''04'' +  @resultado
    else ''E_NV_Cel'' end end*/
                WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN CASE substring(@resultado, 2, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE ''0'' + @resultado END ELSE ''E_NV_LD'' END WHEN 10 THEN CASE substring(@resultado, 3, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @resultado END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
    ELSE IF @pais = 10
    BEGIN --Brasil
        SELECT @resultado = CASE @lenPhone
                --llamada local fijo o celular
                WHEN 8 THEN @resultado WHEN 9 THEN @resultado WHEN 10 THEN -- Numero nacional
                        CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 8) ELSE @resultado END WHEN 11 THEN -- Este caso solomente es para numero celular
                        CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 9) ELSE @resultado END WHEN 12 THEN -- llamadas por cobrar local
                        CASE WHEN (left(@resultado, 4) = ''9090'') THEN right(@resultado, 8) ELSE ''E_NV_PC'' END WHEN 13 THEN CASE WHEN left(@resultado, 4) = ''9090'' THEN right(@resultado, 9) -- llamadas por cobrar local celular
                            WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 10) END -- llamadas de LDN
                            ELSE ''E_NV_Longitud'' END WHEN 14 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- llamadas por cobrar larga distancia
                                    CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 11) END WHEN left(@resultado, 1) = ''0'' THEN --llamada larga distancia a celular
                                    CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END WHEN 15 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- Llamadas por cobrar a celular LD
                                    CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
    ELSE IF @pais = 11
    BEGIN --Guatemala
        if @lenPhone <> 8 BEGIN
            SELECT @resultado = ''E_NV_Longitud''
        END
        ELSE IF CHARINDEX(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8,9'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 12
    BEGIN --Costa Rica
        IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF @lenPhone = 10 AND charindex(substring(@resultado, 1, 3), ''800,900,905'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF charindex(substring(@resultado, 1, 2), ''00,08'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 13
    BEGIN --Salvador
        IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,6,7'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 14
    BEGIN --Spain
        IF @lenPhone = 9 AND charindex(substring(@resultado, 1, 1), ''5,6,7,8,9'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 15
    BEGIN --Peru
        SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 1) OR (@lenPhone = 6 AND @lenLd = 2) THEN @resultado WHEN @lenPhone = 8 THEN CASE WHEN substring(@resultado, 1, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE ''0'' + @resultado END WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 1) = ''0'' AND substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE @resultado END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END --Termina Peru
    ELSE IF @pais = 16
    BEGIN --Panama
        SELECT @resultado = CASE WHEN (@lenPhone = 7) THEN CASE WHEN substring(@resultado, 1, 1) IN (''2'', ''3'', ''4'', ''5'', ''7'', ''9'') THEN @resultado ELSE ''E_'' + @resultado END WHEN (@lenPhone = 8) THEN CASE WHEN substring(@resultado, 1, 1) = ''6'' THEN @resultado ELSE ''E_'' + @resultado END ELSE CASE WHEN substring(@resultado, 1, 2) = ''00'' THEN @resultado ELSE ''E_'' + @resultado END END
        RETURN @resultado
    END
    -- Termina
    RETURN @resultado
END'
    EXEC(@sql)


SET @process = 'SEARS ALTER FUNCTION [dbo].[Completa_ListaNegra]'
    SET @sql = 'ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
RETURNS varchar(30) AS
begin
declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint

select @ld=valor from ccSettings with(nolock) where setting_id=17
select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @BLActivo = valor from ccsettings with(nolock) where setting_id = 114
declare @lenExt int
select @lenExt=valor from ccsettings where setting_id=108

if @lenExt=len(@cadena) return @Cadena

select @resultado=dbo.Completa(@Cadena, @pais, @ld)

if @BLActivo = 1 begin
    if @pais in (1,4)
        begin
        if left(@resultado, 1)=''E''
            return @resultado

        select @resultado = case
            when len(@resultado)in(7,8) then @ld + @resultado
            when @resultado=''911'' OR len(@resultado)=10 then @resultado
            when len(@resultado) in (11,12,13) then right(@resultado,10)
            else ''E_NV_Longitud''
            end

            return @resultado
        end

    if @pais = 2 begin
        select @resultado = dbo.fnClearPhoneArg(@cadena)
        return @resultado
    end

    if @pais = 3 and left(@resultado,1) <> ''E'' begin
        select @resultado = case
            when len(@resultado) = 7 then @ld + @resultado
            when len(@resultado) in(8,10) then @resultado
            when len(@resultado) = 11 then right(@resultado,10)
            else ''E_NV_Longitud'' end
        return @resultado
    end

    if @pais = 5 and left(@resultado,1) <> ''E'' begin
        select @resultado = case
            when len(@resultado) in (6,7) then @ld + @resultado
            when len(@resultado) in (8,9) then @resultado
            when len(@resultado) = 10 then right(@resultado,9)
            else ''E_NV_Longitud'' end
        return @resultado
    end

    if @pais = 6 and left(@resultado,1) <> ''E'' begin
        select @resultado = case
            when len(@resultado) = 7 then @ld + @resultado
            when len(@resultado) = 10 then @resultado
            when len(@resultado) = 11 then right(@resultado,10)
            else ''E_NV_Longitud'' end
        return @resultado
    end

    if @pais = 7 and left(@resultado,1) <> ''E'' begin
        select @resultado = right(@resultado,10)
        return @resultado
    end

    if @pais = 8 begin
        if left(@resultado,1) = ''E'' begin
            return @resultado
        end
        select @resultado = case
            when len(@resultado) = 7 then ''0'' + @ld + @resultado
            when len(@resultado) = 9 and substring(@resultado,1,1) = ''0'' then @resultado
            when len(@resultado) = 10 and substring(@resultado,2,1) = ''5'' then @resultado
            when len(@resultado) = 11 and substring(@resultado,3,3) in (''111'',''510'',''511'') then @resultado
            else ''E_NV_Longitud'' end
        return @resultado
    end

    if @pais in(9,10,11,12,13,14,15,16) and left(@resultado,1) <> ''E'' begin
        return @resultado
    end

end
else begin
    select @resultado = dbo.Limpia(@cadena)
end

return @resultado
end'
    EXEC(@sql)


    SET @process = 'UPDATE fnGetTimeZone para tomar en cuenta el campo locality y no tener problema cuando hay diferentes municipios con la misma LADA'
        SET @sql = 'ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
  declare @lada as varchar(5)
  declare @timeZone as int
  declare @ld as varchar(5)
  declare @location as varchar(500)
  declare @locality as varchar(255)
  declare @country as tinyInt
  declare @pais varchar(2)
  declare @serie varchar(10)
  declare @rank int
  declare @len int
  DECLARE @prefix3 VARCHAR(3)
  DECLARE @prefix2 VARCHAR(2)

  if @phone='''' begin
    return 0;
  end

  select @lada = valor from ccsettings with(nolock) where setting_id = 17
  select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104

  select @ld = ''''
  select @location = ''''
  set @timeZone=0

  set @len=len(@phone)

    if @country = 1 begin
        set @prefix3 = LEFT(@phone, 3)
        set @prefix2 =left(@phone, 2)

        if @len<10 and @len + len(@lada)=10 begin
            set @phone=@lada+@phone
            set @len=len(@phone)
        end

      if @len = 10
        begin
            IF EXISTS (
                    SELECT TOP 1 cld
                    FROM series NOLOCK
                    WHERE cld = @prefix3
                    and serie=SUBSTRING(@phone,4,3)
                    )
                SELECT @ld = @prefix3,@serie=SUBSTRING(@phone,4,3)
            ELSE IF EXISTS (
                    SELECT TOP 1 cld
                    FROM series NOLOCK
                    WHERE cld = @prefix2
                    and serie=SUBSTRING(@phone,3,4)
                    )
                SELECT @ld = @prefix2,@serie=SUBSTRING(@phone,3,4)


        end

      if @ld <> ''''
        begin
            set @rank=right(@phone, 4)

          select top 1 @location = estado, @locality = MUNICIPIO from series
          where cld = @ld and serie = @serie and @rank between [NUMERACION INICIAL] and [NUMERACION FINAL]

          if @location is null or not exists(select  locality from ccTimeZoneArea (nolock) where id_country=@country and area=@ld and locality=@locality)
            set @locality = null
        end
    else begin
        set @ld=@lada
    end

        set @location = case when @location = ''DF'' then ''CDMX'' else @location end

        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and
          area = @ld
          and ( @location is null or (location = @location and locality=@locality))
        if(@timeZone is null or @timeZone = 0)
        begin
            select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
              where id_country = @country and
              area = @ld
              and ( @location is null or location = @location)
        end

        if(@timeZone is null or @timeZone = 0)
        begin
            select top 1 @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end
            from ccTimeZoneArea t
            where id_country = @country and area = @lada
        end

        return isNull(@timeZone,0)
    end

   else  if @country = 2 begin
      declare @telTemp varchar(15)
      set @telTemp = @phone
      select @phone = dbo.Completa(@phone, @pais, @lada)
      if left(@phone,1) = ''E'' begin set @phone = @telTemp end
      select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
        ( len(@phone) = 6 and @lada = area and len(area) = 4 )
        or
        ( len(@phone) = 7 and @lada = area and len(area) = 3 )
        or
        ( len(@phone) = 8 and @lada = area and len(area) = 2 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
        if @timeZone is null
          begin
            select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
            where id_country = @country and (
              ( len(@phone) = 6 and @lada = area and len(area) = 4 )
              or
              ( len(@phone) = 7 and @lada = area and len(area) = 3 )
              or
              ( len(@phone) = 8 and @lada = area and len(area) = 2 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
          end
    end

  else if @country = 3 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
  end

   else if @country = 4

    begin
      select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
      ( len(@phone) = 7 and @lada = area and len(area) = 3 )
      or
      ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
      if @timeZone is null
        begin
          select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and (
          ( len(@phone) = 7 and @lada = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
        end
    end

   else if @country = 5 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 6 and @lada = area )
    or
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) = 8 and left(@phone,2) = area )
    or
    ( len(@phone) = 9 and left(@phone,2) = area )
    or
    ( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
  end

  else if @country = 6 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area and len(area) = 3 )
    or
    ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
  end

  else if @country = 7 begin
    declare @phoneTemp as varchar(10)
    select @phoneTemp = right ( @phone, 10 )
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
    where id_country = @country and (
    (len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
    (len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
    )
  end

  if @country = 8 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
    where id_country = @country and (
    (len(@phone) = 7 and @lada = area) or
    (len(@phone) = 9 and substring(@phone, 2, 1) = area) or
    (len(@phone) = 10 and substring(@phone, 2, 1) = area) or
    (len(@phone) = 11 and substring(@phone, 2, 1) = area))
  end

   else if @country = 9 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- len(@phone) = 10
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      (convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
      (convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
    end
  end

 else  if @country = 10 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- 8 <= len(@phone) <= 19
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      ((len(@phone) between  8 and  9)                                      and                   @lada = area) or
      ((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
      ((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
      ((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
      ((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
      ((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
    end
  end

  else if @country = 11 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 12 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 13 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 14 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      if len(@phone) = 9 begin
        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
        where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
      end
    end
  end

 else  if @country = 15 OR @country = 16  begin --Peru
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = 32
    end
  end

  if(@timeZone is null or @timeZone = 0)
    begin
        select top 1 @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end
        from ccTimeZoneArea t
        where id_country = @country and area = @lada
    end

  return isNull(@timeZone,0)
 END
        ';
        EXEC(@sql);



 SET @process = '#2493 ALTER FUNCTION [dbo].[ValidateBlackListPhone]'
       SET @sql = 'ALTER FUNCTION [dbo].[ValidateBlackListPhone] (@tel VARCHAR(32), @camId INT, @calKey VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @isBlackPhone BIT=0
    --PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
    DECLARE @hasTelefono BIGINT

    if @tel='''' return 0

    SELECT @hasTelefono = dbo.hashPhone(@tel)

    DECLARE @hasCalKey BIGINT

    -- Evitar doble condición innecesaria
    IF ISNULL(@calKey, '''') <> ''''
        SET @hasCalKey = dbo.hashList(@calKey)

    IF EXISTS (
            SELECT 1
            FROM cclistanegra a1
            INNER JOIN camplistanegra a2 WITH(nolock) ON a1.idtipolista = a2.idtipolista
            WHERE a2.cam_id = @camId AND STATUS = 1 AND a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
            )
        SET @isBlackPhone = 1

    RETURN @isBlackPhone
END'
   EXEC(@sql)



   SET @process = '#2543 ALTER function [dbo].[fn_ccCamps_SelMessage](@cam_id smallint)'
       SET @sql = 'ALTER function [dbo].[fn_ccCamps_SelMessage](@cam_id smallint)
returns @SelMessage table (msg_mostrar varchar(max), msg_mostrar_dnc varchar(max), msg_mostrar_dnc_confirm varchar(max) )
as
begin
declare @msg_mostrar varchar(max), @msg_mostrar_dnc varchar(max), @msg_mostrar_dnc_confirm varchar(max)
select @msg_mostrar='''', @msg_mostrar_dnc='''', @msg_mostrar_dnc_confirm = ''''

select @msg_mostrar=@msg_mostrar+coalesce(msgFile+'','','''')
from ccCampsMsgs M with(nolock)
inner join ccMsgFiles T with(nolock) on M.Msg_id=T.msg_id
where M.cam_id = @cam_id and type = 8 order by orden

select @msg_mostrar_dnc=@msg_mostrar_dnc+coalesce(msgFile+'','','''')
from ccCampsMsgs M with(nolock)
inner join ccMsgFiles T with(nolock) on M.Msg_id=T.msg_id
where M.cam_id = @cam_id and type = 11 order by orden

select @msg_mostrar_dnc_confirm=@msg_mostrar_dnc_confirm+coalesce(msgFile+'','','''')
from ccCampsMsgs M with(nolock)
inner join ccMsgFiles T with(nolock)on M.Msg_id=T.msg_id
where M.cam_id = @cam_id and type = 14 order by orden

insert into @SelMessage select
case when len(isnull(@msg_mostrar,''''))>0 then left(@msg_mostrar, len(@msg_mostrar)-1) else '''' end,
case when len(isnull(@msg_mostrar_dnc,''''))>0 then left(@msg_mostrar_dnc, len(@msg_mostrar_dnc)-1) else '''' end,
case when len(isnull(@msg_mostrar_dnc_confirm,''''))>0 then left(@msg_mostrar_dnc_confirm, len(@msg_mostrar_dnc_confirm)-1) else '''' end

return
end'
       EXEC(@sql)


    SET @process = '#2543 ALTER FUNCTION [dbo].[fnGetRotativeANI]'
       SET @sql = 'ALTER FUNCTION [dbo].[fnGetRotativeANI] (@aniListId int, @aniIdx varchar(max), @cld varchar(3) = '''', @serie varchar(4) = '''')
RETURNS @retANIinfo TABLE

(
    telAni varchar(30) NULL,
    idx int NULL
)
AS
BEGIN
    DECLARE @AniList table (aniIdx varchar(30))
    DECLARE @ani varchar(30), @idx int
    declare @lenCld int,@lenSerie int

    set @lenCld=len(@cld)
    set @lenSerie=len(@serie)

    INSERT @AniList
    SELECT value aniIdx FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0

    SELECT TOP 1 @ani = telAni, @idx = cast(RowNum as varchar(8))
    FROM RowRotativeAniListDetail with(nolock)
    WHERE id_RAniList = @aniListId and RowNum not in (SELECT aniIdx FROM @AniList)
        and (@lenCld = 0 or left(telAni, @lenCld) = @cld)
        and (@lenSerie = 0 or substring(telAni, @lenCld+1, 6-@lenCld) != @serie)
    ORDER BY (SELECT [NewId] FROM GetNewID)

    INSERT @retANIinfo
    SELECT @ani, @idx

    RETURN
END'
       EXEC(@sql)

    SET @process = '#2543 - se guarda información a la tabla ccoCallsOutData, Se optimiza para poner ZonasHorarias quitar el trigger '
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
    @cam_id smallint,
    @cal_Key varchar(40),
    @cal_Telefono varchar(30),
    @user_id int,
    @cal_extension varchar(7),
    @sData varchar(255) = '''', --HLAS para guardar notas de la llamada
    @existCallOut as int = 0,
    @callmode as smallint = 0,
    @odbc AS BIT = 0
    AS
    set
    nocount on
    declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
    declare @today datetime
declare @iZonaHoraria int, @iZonaHoraria_verano int

    set @today=convert(datetime,getdate())
    select @fecha=getdate()
    declare @dialPrefix integer
    select @dialPrefix = valor from ccSettings with(nolock) where setting_id = 202

    if @callmode = 1 begin
        INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
        select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension, @odbc
        select @cal_id = scope_identity()

        INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)
        SELECT @cal_id, @existCallOut, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
        FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @existCallOut

exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11

        insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
        select idwg, @cal_id, 0 as user_id, @fecha timestamp, 1 as tipo
        from ccRIACampEspWG wg
        where wg.tipo = 1 and wg.idcampesp =@cam_id

        select @calloutMaxTime = cam_tNoContesta from ccCamps with(nolock) where cam_id=@cam_id
        select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
      return(0)
    end


select @iZonaHoraria=dbo.fnGetTimeZone(@cal_Telefono, 0),@iZonaHoraria_verano=dbo.fnGetTimeZone(@cal_Telefono, 1)

    if @existCallOut=0  begin
        declare @prefijoMarcacion varchar(100)
        set @prefijoMarcacion = ''''
        declare @LasCallKey varchar(20)
        set @LasCallKey = @cal_Key
        declare @settingCallKey as int
        select @settingCallKey = valor from ccSettings where setting_id = 194

        if(@settingCallKey = 1) begin
            if (@cal_Key='''' or @cal_Key is null) begin
            select top 1 @LasCallKey=cal_Key from ccoCallsOut with(nolock) where cam_id=@cam_id and cal_Inicio>=@today and cal_manual=0 order by cal_id desc
                set @cal_Key= @LasCallKey
            end
        end

        if @dialPrefix = 1 and len(@cal_telefono)>20
            begin
                set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
                set @cal_telefono = RIGHT(@cal_telefono,10)
            end
        else
            begin
                set @prefijoMarcacion =''''
            end

    INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix, iZonaHoraria, iZonaHoraria_verano)
    select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData, @prefijoMarcacion, @iZonaHoraria, @iZonaHoraria_verano
        select @callout_id = scope_identity()

        INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
        select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
        select @cal_id = scope_identity()

        INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)
        SELECT @cal_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
        FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id

    exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
     end

    else begin --@existCallOut<>0
    Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData,
    iZonaHoraria = @iZonaHoraria,iZonaHoraria_verano = @iZonaHoraria_verano
    where callout_id = @existCallOut
        Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut

        set @callout_id = @existCallOut

        select top 1 @cal_id=cal_id from ccocallsout with(nolock) where callout_id = @callout_id order by cal_id desc

    if exists(select 1 from ccoLogDials with(nolock) where fecha>@today and cal_id=@cal_id) begin
            INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
            select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
            select @cal_id = scope_identity()

            INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)
            SELECT @cal_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
            FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id

        exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
        end

     end

    insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
    select idwg, @cal_id, 0 as user_id, @fecha timestamp, 1 as tipo
    from dbo.ccRIACampEspWG wg
    where wg.tipo = 1 and wg.idcampesp =@cam_id


    select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
    select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
    return(0)
set nocount off'
    EXEC(@sql)

    SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]'
       SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT] @UserID SMALLINT, @Extension VARCHAR(7) = NULL, @Computer VARCHAR(20) = NULL, @TipoMov TINYINT, -- 0= LogOut,  1=LogIN,   3=Consulta
    @fecha DATETIME = NULL,
    @ipPublica VARCHAR(15) = NULL
AS
SET NOCOUNT ON

IF @fecha IS NULL
    SET @fecha = getdate()

DECLARE @hourlogin VARCHAR(8)
DECLARE @sessionsecs INT
DECLARE @sessiontime VARCHAR(8)
DECLARE @fecha_ini DATETIME

IF @TipoMov = 1
BEGIN
    INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
    VALUES (@UserID, @Extension, 1, @fecha)

    INSERT ccLogAgentesDia (User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callID)
    VALUES (@UserID, 0, 0, @fecha, 0, 0, 1, 0)

    --Actualiza para no revisar en cada actualizacion solo hacerlo al inico
     IF NOT EXISTS (
                SELECT *
                FROM [ccLogAgentesDiaLast] with(nolock)
                WHERE User_id = @UserID
                )
    BEGIN
        INSERT [ccLogAgentesDiaLast]  (User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callID)
        VALUES (@UserID, 0, 0, @fecha, 0, 0, 1, 0)
    END
    ELSE
    BEGIN
        UPDATE [ccLogAgentesDiaLast] WITH (ROWLOCK, UPDLOCK)
        SET TipoStatusAge_id = 1,
            tStatus = 0,
            fecha = @fecha,
            IdCampEsp = 0,
            Tipo = 0,
            currentStatus = 1,
            callID = 0
        WHERE USER_ID = @UserID
    END

    UPDATE c
    SET User_id = @UserID, publicIp = @ipPublica
    FROM ccPosicion c WITH (INDEX (IX_ccPosicion))
    WHERE Computer = @Computer

    UPDATE c
    SET user_id = 0
    FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
    WHERE Computer <> @Computer AND user_id = @UserId

    UPDATE ccUsers
    SET TipoStatusAge_id = 3, LastLoginAttempt = @fecha
    WHERE User_id = @UserID

    IF EXISTS (
            SELECT valor
            FROM ccSettings
            WHERE tipo = ''AGT'' AND STATUS = ''1'' AND setting_id = ''53'' AND valor = 2
            )
    BEGIN
        IF NOT EXISTS (
                SELECT axLic_Desc
                FROM axLicG729_Data
                WHERE axLic_Status = 1 AND pos_id IN (
                        SELECT pos_id
                        FROM ccPosicion
                        WHERE Computer = @Computer OR user_id = @Userid
                        )
                )
        BEGIN
            RAISERROR (''Error. Without License'', 18, 1)

            RETURN (0)
        END

        UPDATE axLicG729_Data
        SET axLic_Status = 2
        WHERE axLic_Status = 1 AND pos_id IN (
                SELECT pos_id
                FROM ccPosicion
                WHERE Computer = @Computer OR user_id = @Userid
                )

        SELECT ''0'' CPLic

        RETURN (0)
    END

    RETURN (0)
END

IF @TipoMov = 0
BEGIN
    INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
    VALUES (@UserID, @Extension, 0, @fecha)

    UPDATE c
    SET User_id = 0
    FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
    WHERE Computer = @Computer OR user_id = @Userid

    UPDATE ccUsers
    SET TipoStatusAge_id = 0
    WHERE User_id = @UserID

    IF EXISTS (
            SELECT valor
            FROM ccSettings
            WHERE tipo = ''AGT'' AND STATUS = ''1'' AND setting_id = 53 AND valor = ''2''
            )
    BEGIN
        UPDATE axLicG729_Data
        SET axLic_Status = 0, pos_id = NULL, fecha_log = NULL
        WHERE pos_id IN (
                SELECT pos_id
                FROM ccPosicion
                WHERE Computer = @Computer OR user_id = @Userid
                )
    END

    RETURN (0)
END

IF @TipoMov = 3
BEGIN
    SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(11), getdate()))

    SELECT @hourlogin = convert(VARCHAR(8), isnull(min(fecha), getdate()), 114)
    FROM ccLogLogin
    WHERE TipoMov = 1 AND user_id = @UserID AND fecha >= @fecha_ini

    SELECT @sessionsecs = isnull(CASE WHEN sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) > 0 THEN sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) ELSE sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) + convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14))) END, 0)
    FROM ccLogLogin
    WHERE user_id = @UserID AND fecha > dateadd(hh, - 10, getdate())

    SELECT @sessiontime = RIGHT(''0'' + CONVERT(VARCHAR(6), @sessionsecs / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (@sessionsecs % 3600) / 60), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), @sessionsecs % 60), 2)

    SELECT ''HourLogin'' = @hourlogin, ''SessionTime'' = @sessiontime, ''SessionSecs'' = @sessionsecs

    RETURN (0)
END
'
       EXEC(@sql)


     SET @process = 'SEARS ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]
AS

declare @pais varchar(2)
declare @ld varchar(4)
declare @idagenda  int
declare @campsid int
declare @fechacal datetime
declare @Listid int

SET NOCOUNT ON

CREATE TABLE [dbo].[#mycamps] ( [campsid] [int]  NOT NULL primary key) ON [PRIMARY]

select top 1 @idagenda = idagenda, @campsid = campsid, @fechacal=fecharegs from ccagendalistanegra with(index(IX_ccagendalistanegra_4),nolock)
        where status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

IF @idagenda is not  null
BEGIN

select top 1 @Listid = idtipolista from ccagenda_tipolistanegra with(nolock)
        where idagenda = @idagenda order by idtipolista asc

update ccagendalistanegra with(rowlock) set inicio=getdate() where idagenda=@idagenda


insert #mycamps
select  campsid  from ccagendalistanegra where idagenda=@idagenda and  status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

CREATE TABLE [dbo].[#mytemp] (
[callout_id] [int] NOT NULL,
[telefono] [varchar] (15) NOT NULL ,
[cam_id] [smallint] NOT NULL ,
[tipomov] [int] NOT NULL,
[idtipolista] [int] NOT NULL
) ON [PRIMARY]

create table #tempListNegra(telefono varchar(32) NOT NULL,      idtipolista int NOT NULL)
CREATE NONCLUSTERED INDEX IX_tempListNegra_1 ON [dbo].#tempListNegra (telefono ASC)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

insert into #tempListNegra select dbo.Completa(telefono, @pais, @ld),idtipolista from ccListaNegra


declare @sqlReplace nvarchar(max),@sql nvarchar(max), @varEmpty varchar(1),@tipomov int
declare @sqlReplaceccoWOrkingTable nvarchar(max),@sqlccoWOrkingTable nvarchar(max),@col varchar(255)
declare @colZone varchar(255),@colZoneVerano varchar(255)

set @varEmpty=''''
set @tipomov=3
--cal_telefono


SET @sqlReplace = ''
IF @campsid = 0
BEGIN
    IF @Listid = 0
    BEGIN
        INSERT INTO #mytemp (callout_id, telefono, cam_id, tipomov, idtipolista)
        -- Guardamos en una tabla temporal los callout_id de todos los registros que tengan COL_PHONE_REPLACE en lista negra
        SELECT callout_id,
               COL_PHONE_REPLACE     AS telefono,
               cs.cam_id             AS cam_id,
               @tipomov              AS tipomov,
               ln.idtipolista        AS idtipolista
        FROM ccoCallsOutSource cs WITH (INDEX(IX_ccoCallsOutSource_4), NOLOCK)
        INNER JOIN #tempListNegra ln WITH (INDEX(IX_tempListNegra_1), NOLOCK)
            ON cs.COL_PHONE_REPLACE = ln.telefono
        WHERE cal_fechadial > @fechacal;
    END
    ELSE
    BEGIN
        INSERT INTO #mytemp (callout_id, telefono, cam_id, tipomov, idtipolista)
        -- Guardamos en una tabla temporal los callout_id de todos los registros que tengan COL_PHONE_REPLACE en lista negra
        SELECT callout_id,
               COL_PHONE_REPLACE     AS telefono,
               cs.cam_id             AS cam_id,
               @tipomov              AS tipomov,
               ln.idtipolista        AS idtipolista
        FROM ccoCallsOutSource cs WITH (INDEX(IX_ccoCallsOutSource_4), NOLOCK)
        INNER JOIN #tempListNegra ln WITH (INDEX(IX_tempListNegra_1), NOLOCK)
            ON cs.cal_telefono = ln.telefono
        WHERE cs.cal_fechadial > @fechacal
          AND ln.idtipolista IN (
                SELECT tl.idtipolista
                FROM ccagenda_tipolistanegra tl WITH (INDEX(IX_ccAgenda_TipolistaNegra), NOLOCK)
                WHERE tl.idagenda = @idagenda
          );
    END
END
ELSE
BEGIN
    IF @Listid = 0
    BEGIN
        INSERT INTO #mytemp (callout_id, telefono, cam_id, tipomov, idtipolista)
        -- Guardamos en una tabla temporal los callout_id de todos los registros que tengan COL_PHONE_REPLACE en lista negra
        SELECT callout_id,
               COL_PHONE_REPLACE     AS telefono,
               cs.cam_id             AS cam_id,
               @tipomov              AS tipomov,
               ln.idtipolista        AS idtipolista
        FROM ccoCallsOutSource cs WITH (INDEX(IX_ccoCallsOutSource_4), NOLOCK)
        INNER JOIN #tempListNegra ln WITH (INDEX(IX_tempListNegra_1), NOLOCK)
            ON cs.cal_telefono = ln.telefono
        INNER JOIN #mycamps ca
            ON cs.cam_id = ca.campsid
        WHERE cs.cal_fechadial > @fechacal;
    END
    ELSE
    BEGIN
        INSERT INTO #mytemp (callout_id, telefono, cam_id, tipomov, idtipolista)
        -- Guardamos en una tabla temporal los callout_id de todos los registros que tengan COL_PHONE_REPLACE en lista negra
        SELECT callout_id,
               COL_PHONE_REPLACE     AS telefono,
               cs.cam_id             AS cam_id,
               @tipomov              AS tipomov,
               ln.idtipolista        AS idtipolista
        FROM ccoCallsOutSource cs WITH (INDEX(IX_ccoCallsOutSource_4), NOLOCK)
        INNER JOIN #tempListNegra ln WITH (INDEX(IX_tempListNegra_1), NOLOCK)
            ON cs.cal_telefono = ln.telefono
        INNER JOIN #mycamps ca
            ON cs.cam_id = ca.campsid
        WHERE cs.cal_fechadial > @fechacal
          AND ln.idtipolista IN (
                SELECT tl.idtipolista
                FROM ccagenda_tipolistanegra tl WITH (INDEX(IX_ccAgenda_TipolistaNegra), NOLOCK)
                WHERE tl.idagenda = @idagenda
          );
    END
END
'';

-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
set @sqlReplaceccoWOrkingTable=''
DELETE wt WITH (ROWLOCK)
FROM ccoWOrkingTable wt
INNER JOIN ccoCallsOutSource cs ON wt.callout_id = cs.callout_id
INNER JOIN #mytemp t            ON wt.callout_id = t.callout_id
WHERE cs.cal_fechadial > @fechacal
    and cs.COL_PHONE_REPLACE = wt.cal_telefono AND
    WHERE_PHONE_REPLACE IS NULL;

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
UPDATE wt WITH (ROWLOCK)
SET wt.cal_telefono        = UPDATE_COL_REPLACE
,COL_ZONE_REPLACE         = NULL,
,COL_ZONE_VERANO_REPLACE = NULL
FROM ccoWOrkingTable wt
INNER JOIN ccoCallsOutSource cs ON cs.callout_id = wt.callout_id
INNER JOIN #mytemp t            ON cs.callout_id = t.callout_id
WHERE cs.cal_fechadial > @fechacal
  AND cs.cal_telefono = wt.cal_telefono;

---insertar el historial
INSERT INTO cchistoriallistanegra (callout_id, telefono, cam_id, idtipomov, idtipolista)
SELECT callout_id, telefono, cam_id, tipomov, idtipolista
FROM #mytemp;

-- Eliminamos el telefono1 de CS
UPDATE cs WITH (ROWLOCK)
SET cs.cal_telefono        = @varEmpty
,COL_ZONE_REPLACE        = 0
,COL_ZONE_VERANO_REPLACE = 0
FROM ccoCallsOutSource cs
INNER JOIN #mytemp t ON cs.callout_id = t.callout_id
WHERE cs.cal_fechadial > @fechacal;

truncate table #mytemp
''
-----------------------------------------------------------------------------  telefono1

-- Reemplazo del placeholder por el nombre de columna entre corchetes (seguro para identificadores)
set @col=N''cal_telefono''
set @colZone=N''iZonaHoraria''
set @colZoneVerano=N''iZonaHoraria_verano''

SET @sql = REPLACE(@sqlReplace, N''COL_PHONE_REPLACE'', @col);
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

-- Ejecuta con parámetros REALES (sp_executesql)
EXEC sp_executesql
    @sql,
    N''@fechacal DATETIME, @idagenda INT, @campsid INT, @Listid INT, @tipomov INT'',
    @fechacal = @fechacal,
    @idagenda = @idagenda,
    @campsid  = @campsid,
    @Listid   = @Listid,
    @tipomov  = @tipomov;

set @sql = REPLACE(@sqlReplaceccoWOrkingTable, N''WHERE_PHONE_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono2)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono3)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono4)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty)
      ) '')
set @sql = REPLACE(@sql, N''UPDATE_COL_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono2)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono3)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono4)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty),
        @varEmpty
    )
'')
set @sql = REPLACE(@sql, N''COL_PHONE_REPLACE'', @col)
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

print(@sql)

EXEC sp_executesql
  @sql,
  N''@fechacal DATETIME, @varEmpty VARCHAR(1)'',
  @fechacal = @fechacal,
  @varEmpty = @varEmpty;


----------------------------------------------------------------------------------- -telefono 2
-----------------------------------------------------------------------------  telefono1

set @col=N''cal_telefono2''
set @colZone=N''iZonaHoraria2''
set @colZoneVerano=N''iZonaHoraria_verano2''

SET @sql = REPLACE(@sqlReplace, N''COL_PHONE_REPLACE'', @col);
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

-- Ejecuta con parámetros REALES (sp_executesql)
EXEC sp_executesql
    @sql,
    N''@fechacal DATETIME, @idagenda INT, @campsid INT, @Listid INT, @tipomov INT'',
    @fechacal = @fechacal,
    @idagenda = @idagenda,
    @campsid  = @campsid,
    @Listid   = @Listid,
    @tipomov  = @tipomov;

set @sql = REPLACE(@sqlReplaceccoWOrkingTable, N''WHERE_PHONE_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono3)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono4)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty)
      ) '')
set @sql = REPLACE(@sql, N''UPDATE_COL_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono3)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono4)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty),
        @varEmpty
    )
'')
set @sql = REPLACE(@sql, N''COL_PHONE_REPLACE'', @col)
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

EXEC sp_executesql
  @sql,
  N''@fechacal DATETIME, @varEmpty VARCHAR(1)'',
  @fechacal = @fechacal,
  @varEmpty = @varEmpty;



----------------------------------------------------------------------------------- -telefono 3


set @col=N''cal_telefono3''
set @colZone=N''iZonaHoraria3''
set @colZoneVerano=N''iZonaHoraria_verano3''

SET @sql = REPLACE(@sqlReplace, N''COL_PHONE_REPLACE'', @col);
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

-- Ejecuta con parámetros REALES (sp_executesql)
EXEC sp_executesql
    @sql,
    N''@fechacal DATETIME, @idagenda INT, @campsid INT, @Listid INT, @tipomov INT'',
    @fechacal = @fechacal,
    @idagenda = @idagenda,
    @campsid  = @campsid,
    @Listid   = @Listid,
    @tipomov  = @tipomov;

set @sql = REPLACE(@sqlReplaceccoWOrkingTable, N''WHERE_PHONE_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono4)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty)
      ) '')
set @sql = REPLACE(@sql, N''UPDATE_COL_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono4)), @varEmpty),
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty),
        @varEmpty
    )
'')
set @sql = REPLACE(@sql, N''COL_PHONE_REPLACE'', @col)
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

EXEC sp_executesql
  @sql,
  N''@fechacal DATETIME, @varEmpty VARCHAR(1)'',
  @fechacal = @fechacal,
  @varEmpty = @varEmpty;

----------------------------------------------------------------------------------- -telefono 4

set @col=N''cal_telefono4''
set @colZone=N''iZonaHoraria4''
set @colZoneVerano=N''iZonaHoraria_verano4''

SET @sql = REPLACE(@sqlReplace, N''COL_PHONE_REPLACE'', @col);
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

-- Ejecuta con parámetros REALES (sp_executesql)
EXEC sp_executesql
    @sql,
    N''@fechacal DATETIME, @idagenda INT, @campsid INT, @Listid INT, @tipomov INT'',
    @fechacal = @fechacal,
    @idagenda = @idagenda,
    @campsid  = @campsid,
    @Listid   = @Listid,
    @tipomov  = @tipomov;

set @sql = REPLACE(@sqlReplaceccoWOrkingTable, N''WHERE_PHONE_REPLACE'', N''COALESCE(
        NULLIF(LTRIM(RTRIM(cs.cal_telefono5)), @varEmpty)
      ) '')
set @sql = REPLACE(@sql, N''UPDATE_COL_REPLACE'', N''LTRIM(RTRIM(cs.cal_telefono5)'')
set @sql = REPLACE(@sql, N''COL_PHONE_REPLACE'', @col)
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

EXEC sp_executesql
  @sql,
  N''@fechacal DATETIME, @varEmpty VARCHAR(1)'',
  @fechacal = @fechacal,
  @varEmpty = @varEmpty;


----------------------------------------------------------------------------------- -telefono 5
set @col=N''cal_telefono5''

SET @sql = REPLACE(@sqlReplace, N''COL_PHONE_REPLACE'', @col);
SET @sql = REPLACE(@sql, N''COL_ZONE_REPLACE'', @colZone);
SET @sql = REPLACE(@sql, N''COL_ZONE_VERANO_REPLACE'', @colZoneVerano);

-- Ejecuta con parámetros REALES (sp_executesql)
EXEC sp_executesql
    @sql,
    N''@fechacal DATETIME, @idagenda INT, @campsid INT, @Listid INT, @tipomov INT'',
    @fechacal = @fechacal,
    @idagenda = @idagenda,
    @campsid  = @campsid,
    @Listid   = @Listid,
    @tipomov  = @tipomov;

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt   inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = '''',iZonaHoraria5=0,iZonaHoraria_verano5=0
from ccoCallsOutSource cs
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

update ccagendalistanegra set termino=getdate() where idagenda=@idagenda
update ccagendalistanegra set status=''0'' where idagenda=@idagenda
drop table #mytemp
drop table #tempListNegra
END


drop table #mycamps

'
    EXEC(@sql)

    SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]'
       SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]
@callout_id int,
@phones varchar(max),
@aniList int,
@algo tinyint
AS
set nocount on
DECLARE @Tels table (id int, pid varchar(2), phone varchar(32), ani varchar(32))
if @aniList<=0 begin
    SELECT * FROM @Tels
    return(0)
end

DECLARE @aniIdx varchar(500), @aniCnt smallint, @aniCurList int, @usedAniCnt int, @phoneCnt int, @ani varchar(32), @idx varchar(8)
DECLARE @id_phone INT, @phone varchar(32), @usedAni varchar(30)

if exists(select 1 FROM ccRotativeAniListDetail with(nolock) WHERE id_RAniList = @aniList)
begin
    set @aniCnt=1
end
else begin
    set @aniCnt=0
end

SELECT @aniCurList=isnull(id_RAniList,0),@aniIdx=isnull(ani_idx,'''') FROM ccoWorkingTable with(nolock) WHERE callout_id = @callout_id

IF @aniList != @aniCurList SET @aniIdx = ''''

IF @aniCnt > 0
BEGIN
    INSERT @Tels
    SELECT id,''p''+cast(id as varchar(1)),value,'''' FROM fn_RIASplitDelimited(@phones, '';'') WHERE len(value)>0

    IF OBJECT_ID(''tempdb..#UsedAniList'') IS NOT NULL DROP TABLE #UsedAniList;
    SELECT * INTO #UsedAniList FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0
    SELECT @usedAniCnt=count(*) FROM #UsedAniList

    IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
    SELECT @usedAni = telAni FROM RowRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList AND RowNum=(
    SELECT TOP 1 value from #UsedAniList)

    DECLARE CUR_TEST CURSOR FAST_FORWARD FOR SELECT Id, phone FROM @Tels ORDER BY Id;
    OPEN CUR_TEST FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone

    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF @usedAniCnt >= @aniCnt SET @aniIdx = ''''

        IF @algo = 0
        BEGIN
            SELECT @ani = dbo.TelAni(@phone,@aniList)
        END
        ELSE IF @algo = 1
        BEGIN
            SELECT TOP 1 @ani=telAni, @idx=idx FROM fnGetRotativeANI(@aniList, @aniIdx, default, default)
        END
        ELSE IF @algo = 2 or @algo = 3
        BEGIN
            DECLARE @cld varchar(3), @serie varchar(4), @cldCnt smallint
            IF len(@phone) < 10
            BEGIN
                FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
                CONTINUE
            END
            IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@usedAni, 2))
                    SELECT @serie = substring(@usedAni, 3, 4)
                ELSE
                    SELECT @serie = substring(@usedAni, 4, 3)
            END
            IF @algo = 2 or (@algo = 3 and @usedAniCnt < 2)
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@phone, 2))
                    SET @cld = left(@phone, 2)
                ELSE
                    SET @cld = left(@phone, 3)
            END
            SELECT @cldCnt = count(*)
            FROM ccRotativeAniListDetail NOLOCK
            WHERE id_RAniList = @aniList
                AND (((@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) and left(telAni, len(@cld))=@cld) or (@algo = 3 and @usedAniCnt >= 2))
                AND (@algo = 2 OR @usedAni is null OR left(telAni, 6) != left(@usedAni, 6) OR @usedAniCnt >= 2)
            IF @cldCnt > 0 and @usedAniCnt >= @cldCnt and @algo = 2 SET @aniIdx = ''''
            SELECT TOP 1 @ani=telAni, @idx=idx
            FROM fnGetRotativeANI(@aniList, @aniIdx
                , case when @cldCnt > 0 and (@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) then @cld else '''' end
                , case when @algo = 2 then '''' when @usedAniCnt = 1 and @serie is not null then @serie else '''' end)
        END

        SELECT @aniIdx = @aniIdx+'',''+@idx, @usedAniCnt = @usedAniCnt+1, @usedAni = @ani

        UPDATE @Tels SET ani=@ani WHERE id=@id_phone

        FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
    END
    CLOSE CUR_TEST
    DEALLOCATE CUR_TEST

    UPDATE ccoWorkingTable --WITH (ROWLOCK)
    SET id_RAniList = @aniList, ani_idx = ISNULL(@aniIdx,'''')
    WHERE callout_id = @callout_id
END

SELECT * FROM @Tels

set nocount off'
       EXEC(@sql)

    SET @process = 'SEARS optimización de SP ccsp_GalateaAdminBlackListPhones'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminBlackListPhones]
@type TINYINT,
@idBlackList INT,
@generateCsv bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    /*Variables Tables*/
    DECLARE @repeatedPhoneNumbers TABLE (telefono VARCHAR(19))
    DECLARE @numbersWithoutrepeatedNumbers TABLE (telefono VARCHAR(19), calKey VARCHAR(40), fecha DATETIME)
    DECLARE @repeatedNumberPhonesAllColumns TABLE (telefono VARCHAR(19), calKey VARCHAR(40), fecha DATETIME)

    IF(@type = 1) -- GET BLACK LIST PHONES BY ID
    BEGIN

        /*Save phone numbers repeated in ccListanegra table*/
        INSERT INTO @repeatedPhoneNumbers
        (
            telefono
        )
        SELECT telefono FROM ccListaNegra
        WHERE idtipolista = @idBlackList
        GROUP BY telefono,
		CASE WHEN @generateCsv = 1 THEN calKey END
        HAVING COUNT(*)>1;



        /*Save phone numbers that are not repeated*/
        INSERT INTO @numbersWithoutrepeatedNumbers
        (
            telefono,
            calKey,
            fecha
        )
            SELECT cln.telefono, cln.calKey, MAX(chln.fecha) AS fecha FROM dbo.ccListaNegra AS cln with(nolock)
            INNER JOIN dbo.ccHistorialListaNegra AS chln with(nolock) ON chln.telefono = cln.telefono AND chln.idtipolista = cln.idtipolista
            LEFT JOIN @repeatedPhoneNumbers rpn ON cln.telefono = rpn.telefono
            WHERE rpn.telefono IS NULL AND chln.idtipolista = @idBlackList  AND chln.idtipomov IN (1,7)
            GROUP BY cln.telefono, cln.calKey

            /*Save phone numbers repeated with all the columns we need */
            INSERT INTO @repeatedNumberPhonesAllColumns
            (
                telefono,
                calKey,
                fecha
            )
        SELECT t.telefono,
                t.calKey,
                MIN(t.fecha) AS fecha FROM  ( SELECT cln.telefono, cln.calKey, MAX(chln.fecha) AS fecha FROM dbo.ccListaNegra AS cln with(nolock)
            INNER JOIN dbo.ccHistorialListaNegra AS chln with(nolock) ON chln.telefono = cln.telefono AND chln.idtipolista = cln.idtipolista
            LEFT JOIN @repeatedPhoneNumbers rpn ON cln.telefono = rpn.telefono
            WHERE rpn.telefono IS NOT NULL AND chln.idtipolista = @idBlackList  AND chln.idtipomov IN (1,7)
            GROUP BY cln.telefono, cln.calKey) t
            GROUP BY t.telefono,
                    t.calKey



        /*Get all phone numbers with necesary columns without phone numbers repeated*/
        SELECT telefono,
                ISNULL(calKey, '''') AS calKey,
                fecha FROM @numbersWithoutrepeatedNumbers
        UNION
            SELECT
            rnpac2.telefono,MIN(rnpac2.calKey) AS calKey, rnpac2.fecha
            FROM (
                SELECT rnpac.telefono,
                        MIN(rnpac.fecha) AS fecha FROM @repeatedNumberPhonesAllColumns AS rnpac
                        GROUP BY rnpac.telefono
                ) foo
                JOIN @repeatedNumberPhonesAllColumns AS rnpac2 ON foo.telefono = rnpac2.telefono AND foo.fecha = rnpac2.fecha
                GROUP BY rnpac2.telefono, rnpac2.fecha
                ORDER BY fecha DESC
    END
END'
        EXEC(@sql)

    SET @process = 'CW-9315 Validar SP  - Drop procedure ccsp_GalateaAdminCampaigns'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminCampaigns'')
        BEGIN
            DROP PROCEDURE dbo.ccsp_GalateaAdminCampaigns
        END'
    EXEC(@sql);



	SET @process = 'CW-9315 Validar SP  - Create procedure ccsp_GalateaAdminCampaigns'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
@Option AS      SMALLINT,
@CampType AS    SMALLINT = 0,
@WorkgroupId AS INT      = 0,
@Id AS          INT      = 0,
@AdminId AS     SMALLINT = 0,
@PinUpdate AS   SMALLINT = 0,
@LoadId AS      INT      = 0,
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null,
@IsWhatsAppCampaign  bit = 0,
@groupList as varchar (MAX) = NULL,
@CampId AS      SMALLINT = 0
AS
BEGIN
	SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
	IF @WorkgroupId IS NOT NULL BEGIN
		SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
		ORDER BY IdCampEsp ASC;
	END;
	ELSE BEGIN
		RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
	END;
	RETURN 0;
END;
IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id
    IF @CampType = 1 BEGIN-- Campaigns Out
        IF @Id IS NOT NULL BEGIN
            DECLARE @HasWorkingRowsForCampaign BIT = 0, @HasTemplatePaused   bit = 0,
        @HasTemplateDisabled bit = 0;

            IF EXISTS (
                SELECT 1
                FROM dbo.ccoWAWorkingTable AS cwwt
                WHERE cwwt.camId = @Id
            )
            BEGIN
                SET @HasWorkingRowsForCampaign = 1;
            END

            IF EXISTS (
                SELECT 1
                FROM dbo.ccoWAWorkingTable cwwt
                JOIN dbo.ccWhatsAppOutSource cwaos  ON cwaos.WAOut_Id = cwwt.WAOut_id
                JOIN dbo.ccMetaWAOutboundTemplates cmwot ON cmwot.Id = cwaos.TemplateId
                WHERE cwaos.camId = @Id AND cmwot.Status = ''PAUSED''
            ) SET @HasTemplatePaused = 1;

            IF EXISTS(
               SELECT 1 FROM dbo.ccMetaWAOutboundTemplates AS cmwot
                INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan
                ON cmwan.MetaId = cmwot.MetaId
                WHERE cmwan.Cam_Id = @Id AND cmwot.Status = ''DISABLED''
				AND cmwot.StatusCW = 1
            )
            BEGIN
                SET @HasTemplateDisabled = 1;
            END

            SELECT DISTINCT
            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
            camps.cam_procesando IsStarted,
            ISNULL(a.AreaName, '''') AS Area,
            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
            a.ToolsTransfer,
            @HasTemplatePaused AS HasTemplatePaused,
            @HasTemplateDisabled AS HasTemplateDisabled,
			@HasWorkingRowsForCampaign AS HasWorkingRowsForCampaign
            FROM ccCamps camps
            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
            WHERE camps.cam_id = @Id
            ORDER BY camps.cam_descripcion ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
        END;
    END;
    ELSE IF @CampType = 0 -- Campaigns In (ACD)
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    SELECT DISTINCT
                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted,
                    ISNULL(a.AreaName, '''') AS Area,
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                            a.ToolsTransfer
                    FROM ccInbound inb
                            LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                            LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                    WHERE inb.Inbound_id = @Id
                            ORDER BY inb.descripcion ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
            END;
    END;
    RETURN 0;
END;
ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

	IF @Id IS NOT NULL BEGIN
		UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
	END;
	ELSE BEGIN
		RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
	END;
	RETURN 0;
END;
ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
BEGIN
	IF @Id IS NOT NULL
		AND @AdminId IS NOT NULL
	BEGIN
		IF @PinUpdate = 1
		BEGIN
			INSERT INTO PinedCampaigns (CampId, AdminId, Type)
			VALUES (@Id, @AdminId, @Type);
		END;

		IF @PinUpdate = 0
		BEGIN
			DELETE
			FROM PinedCampaigns
			WHERE CampId = @Id
				AND AdminId = @AdminId
				AND Type = @Type;
		END;
	END;
	ELSE
	BEGIN
		RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
				);
	END;

	RETURN 0;
END;

ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin
	IF @AdminId IS NOT NULL BEGIN
		SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
		ORDER BY Id ASC;
	END;
	ELSE BEGIN
		RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
	END;
	RETURN 0;
END;
ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
BEGIN
	IF @Id IS NOT NULL
	BEGIN
		DECLARE @BlackListIds VARCHAR(MAX);

		SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
					(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
		FROM Camplistanegra
		WHERE cam_id = @Id
			AND STATUS = 1;

		SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
	END;
	ELSE
	BEGIN
		RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
	END;

	RETURN 0;
END;

ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
BEGIN
	IF (
			@Id IS NOT NULL
			AND EXISTS (
				SELECT *
				FROM cccamps
				WHERE cam_id = @Id
				)
			)
	BEGIN
		SELECT TOP 1 list_id
		FROM ccRIARegistryLists
		WHERE cam_id = @Id
			AND STATUS = 2
		ORDER BY list_id DESC;
	END;
	ELSE
	BEGIN
		--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
		RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
	END;

	RETURN 0;
END;

ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
BEGIN
	IF (
			@LoadId IS NOT NULL
			AND EXISTS (
				SELECT *
				FROM ccRIARegistryLists
				WHERE list_id = @loadID
					AND STATUS <> 0
				)
			)
	BEGIN
		UPDATE ccoCallsOutSource
		SET cal_status = ''5''
		WHERE list_id = @loadID;

		DELETE
		FROM ccoWorkingTable
		WHERE list_id = @LoadId;

		EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
	END;
	ELSE
	BEGIN
		--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
		RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
	END;

	RETURN 0;
END;

ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
BEGIN
	DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
		);

	INSERT INTO @table
	SELECT DISTINCT IdCampEsp, Tipo
	FROM ccRIACampEspWG wg
	WHERE wg.IDWG IN (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers
			WHERE IDWG <> @WorkgroupId
				AND User_id = @AdminId
			);

	SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
	FROM @table A
	RIGHT JOIN (
		SELECT wg.IdCampEsp, wg.Tipo
		FROM ccRIACampEspWG wg
		WHERE wg.IDWG = @WorkgroupId
		) B ON A.camId = B.IdCampEsp
		AND A.campType = B.Tipo
	WHERE A.camId IS NULL
	ORDER BY IdCampEsp;

	RETURN 0;
END;

ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
	DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
	DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
	DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
	DECLARE @tmpCamAgent TABLE (
		camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
			)
		);
	DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
		);
	DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
		);
	DECLARE @campDataTotal TABLE (
		camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId
			)
		);

	INSERT INTO @AdminWorkgroups
	SELECT DISTINCT IDWG
	FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
	WHERE WG.User_id = @AdminId
		OR (
			R.User_id = @AdminId
			AND R.Rol_id = 7
			);

	INSERT INTO @AgentsList
	SELECT DISTINCT A.User_id
	FROM ccRIAWorkGroupUsers A
	INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
	INNER JOIN ccUsers C ON A.User_id = C.User_id
		AND C.TipoUser_id = 1
	ORDER BY A.User_id;

	IF @IsWhatsAppCampaign  = 1
	BEGIN
		INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
		SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
					AND @CampType = 0 THEN inbound.chat ELSE NULL END
		FROM ccRIACampEspWG campPerWg
		INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
		INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
		INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
		LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
			AND @CampType = 0
		LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
			AND @CampType = 1
		WHERE C.TipoUser_id = 1
			AND (camps.CampType = 5 or inbound.chat = 5)
			AND campPerWg.Tipo = @CampType
			AND (
				@Id = 0
				OR campPerWg.IdCampEsp = @Id
				);
	END
	ELSE
	BEGIN
		INSERT INTO @tmpCamAgent
		SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
					AND @CampType = 0 THEN inbound.chat ELSE NULL END
		FROM ccRIACampEspWG campPerWg
		INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
		INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
		INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
		LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
			AND @CampType = 0
		LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
			AND @CampType = 1
		WHERE C.TipoUser_id = 1
			AND campPerWg.Tipo = @CampType
			AND (
				@Id = 0
				OR campPerWg.IdCampEsp = @Id
				);
	END;

	;WITH lastState
    AS (
        SELECT A.user_id, A.fecha
        ,CASE WHEN A.currentStatus <= 0 THEN 0 ELSE A.currentStatus END AS currentStatus
        ,IdCampEsp,Tipo
        FROM ccLogAgentesDiaLast A with(nolock)
        INNER JOIN @AgentsList B ON A.User_id = B.id
        WHERE fecha >= @date
        )
    INSERT INTO @CurrentStatus
    SELECT A.User_id, currentStatus, IdCampEsp, Tipo
    FROM lastState A


	IF @Id = 0
		AND @CampType = 0
	BEGIN
		DELETE
		FROM @tmpCamAgent
		WHERE multimediaType = 0
	END

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

	IF @CampType = 1
	BEGIN
		SELECT @MultimediaType = meanContactTypeId
		FROM contactMeanOut
		WHERE camp_id = @Id
	END
	ELSE
	BEGIN
		SELECT @chatType = ci.chat
		FROM dbo.ccInbound AS ci
		WHERE ci.Inbound_id = @Id;

		SELECT @MultimediaType = meanContactTypeId
		FROM contactMeanIn
		WHERE inboundId = @Id
	END

	IF (@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END

	DECLARE @StateIds VARCHAR(100) = (
			SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN
							''23'' ELSE ''4,5,6,9'' END
			) -- Add more for multimediaTypes

	;with stateDialog as(
	SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
)
	INSERT INTO @AgentStatus
	SELECT A.camId, A.userId, B.CurrentState,
	(CASE
		WHEN @chatType = 1 THEN
			CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
		ELSE
			CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
		END
	END) AS isCampDialog, B.camType

	FROM @tmpCamAgent A
	INNER JOIN @CurrentStatus B ON A.userId = B.userId
	WHERE (
			@Id = 0
			OR A.camId = @Id
			)

	IF @CampType = 1
	BEGIN
			;

		WITH campDataTotal
		AS (
			SELECT camId, count(*) total
			FROM @tmpCamAgent A
			GROUP BY camId
			)
		INSERT INTO @campDataTotal
		SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area, ISNULL(va.concurrentSessionsLimit,0) as NumberOfVirtualAgents
		FROM campDataTotal A
		INNER JOIN ccCamps B ON A.camId = B.cam_id
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
        LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1
	END
	ELSE
	BEGIN
			;

		WITH campDataTotal
		AS (
			SELECT camId, count(*) total
			FROM @tmpCamAgent A
			GROUP BY camId
			)
		INSERT INTO @campDataTotal
		SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area, 0 as NumberOfVirtualAgents
		FROM campDataTotal A
		INNER JOIN ccInbound B ON A.camId = B.Inbound_id
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END;

	WITH stateCamp
	AS (
		SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
			count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
							) THEN 1 WHEN A.CurrentState IN (6, 4
							)
						AND (
							A.CampId != C.IdCampEsp
							OR A.campType != @CampType
							) THEN 1 ELSE NULL END) AS notReady,
							COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog,
							COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
	COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
		FROM @AgentStatus A
		INNER JOIN @CurrentStatus C ON A.userId = C.userId
		GROUP BY A.CampId
		)
	SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady,
			0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL
				THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END
		Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, A.NumberOfVirtualAgents ,A.Area
	FROM @campDataTotal A
	LEFT JOIN stateCamp B ON A.camId = B.CampId
	ORDER BY A.campName

	RETURN 0;
END; -- *****************************************************************************************
ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
	IF NOT EXISTS (
			SELECT *
			FROM ccUsers_Roles WITH (NOLOCK)
			WHERE User_id = @AdminId
				AND Rol_id = 7
			)
	BEGIN
		--print ''xxxx SIn Super''
			;

		WITH wgId
		AS (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers WITH (NOLOCK)
			WHERE user_id = @AdminId
			)
		SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
		INTO #tempIds
		FROM ccRIACampEspWG A WITH (NOLOCK)
		INNER JOIN wgId ON wgId.IDWG = A.IDWG
			AND A.Tipo = @CampType;

		IF(@CampType = 1)
		BEGIN
			SELECT Id FROM #tempIds ids
			INNER JOIN ccCamps c on c.cam_id = ids.Id
			WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1)
			OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
		END
		ELSE
		BEGIN
			SELECT Id FROM #tempIds ids
			INNER JOIN ccInbound c on c.Inbound_id = ids.Id
			WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1)
			OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
		END
		DROP TABLE #tempIds
	END;
	ELSE
	BEGIN
		--print ''xxxx Super''
		IF @CampType = 1
		BEGIN
			SELECT DISTINCT CAST(cam_id AS INT) AS Id
			FROM ccCamps WITH (NOLOCK)
			WHERE IDArea IS NOT NULL
			AND(CampType = 5 AND @IsWhatsAppCampaign = 1)
			OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
		END
		ELSE
		BEGIN
			SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
			FROM ccInbound WITH (NOLOCK)
			WHERE IDArea IS NOT NULL
			AND (chat = 5 AND @IsWhatsAppCampaign = 1)
			OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
		END
	END;

	RETURN 0;
END;

ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
    IF @CampType = 1 -- Campaigns Out
    BEGIN
        ;WITH StopByCamp AS (
          SELECT
              cwaos.camId,
              IsStopDueTemplateStatusChange = CAST(
                  CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS BIT
              )
          FROM dbo.ccoWAWorkingTable AS cwwt
          INNER JOIN dbo.ccWhatsAppOutSource AS cwaos
              ON cwaos.WAOut_Id = cwwt.WAOut_id
          INNER JOIN dbo.ccMetaWAOutboundTemplates AS cmwot
              ON cmwot.Id = cwaos.TemplateId
          WHERE cmwot.Status IN (''PAUSED'', ''DISABLED'')
          GROUP BY cwaos.camId
        )

        SELECT DISTINCT
        CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
        isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
        camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
        CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
        ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
        ISNULL(sbc.IsStopDueTemplateStatusChange, 0) AS IsStopDueTemplateStatusChange
        FROM ccCamps camps(NOLOCK)
        INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
        LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
        LEFT  JOIN StopByCamp       sbc                   ON sbc.camId = camps.cam_id
        ORDER BY camps.cam_descripcion ASC;
    END;
    ELSE
    BEGIN
        SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
            (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS
            AreaId, inb.chat AS InboundType, 0 AS OutboundType
        FROM ccInbound inb(NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
        ORDER BY inb.descripcion ASC;
    END;

    RETURN 0;
END;

ELSE IF @Option = 13
BEGIN
	BEGIN
		IF NOT EXISTS (
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
					AND Rol_id = 7
				)
		BEGIN
			IF @CampType = 1
			BEGIN
				WITH wgId
				AS (
					SELECT IDWG
					FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT
									CAST(IdCampEsp AS INT) AS CampId,
									cam_descripcion AS Description,
									isnull(ccc.IDArea, -1) AS AreaID,
									CAST(-1 AS SMALLINT) AS CampaignType,
									CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
									CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
									CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
									CAST(1 AS INT) As CampType
				FROM ccRIACampEspWG A
				INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
				INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
				LEFT JOIN ccInbound cci(NOLOCK) ON ccc.cam_id = cci.cam_id
				LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
			END
			ELSE
			BEGIN
				WITH wgId
				AS (
					SELECT IDWG
					FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT
									CAST(IdCampEsp AS INT) AS CampId,
									descripcion AS Description,
									isnull(IDArea, -1) AS AreaID,
									CAST(chat AS SMALLINT) AS CampaignType,
									CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
									CAST(chat AS INT) AS Channel,
									CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
									CAST(0 AS INT) As CampType
				FROM ccRIACampEspWG A(NOLOCK)
				INNER JOIN wgId ON wgId.IDWG = A.IDWG
					AND A.Tipo = 0
				INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
									LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
									LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
			END
		END;
		ELSE
		BEGIN
			IF @CampType = 1
			BEGIN
						SELECT DISTINCT
								CAST(ccc.cam_id AS INT) AS CampId,
								cam_descripcion AS Description,
								isnull(ccc.IDArea, -1) AS AreaID,
								CAST(-1 AS SMALLINT) AS CampaignType,
								CAST(ISNULL(i.Inbound_id,-1) AS INT) AS RelatedCampId,
								CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
								CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
								CAST(1 AS INT) As CampType
						FROM ccCamps AS ccc (NOLOCK)
							LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
							left join ccInbound i on i.cam_id = ccc.cam_id
						where ccc.IDArea = @AreaId
			END
			ELSE
			BEGIN
						SELECT DISTINCT
								CAST(cci.Inbound_id AS INT) AS CampId,
								descripcion AS Description,
								isnull(IDArea, -1) AS AreaID,
								CAST(chat AS SMALLINT) AS CampaignType,
								CAST(chat AS INT) AS Channel,
								CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
								CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
								CAST(0 AS INT) As CampType
				FROM ccInbound cci(NOLOCK)
							LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
							LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
						where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

			END
		END;

		RETURN 0;
	END;
END;
ELSE IF @Option = 14
BEGIN
	IF NOT EXISTS (
			SELECT 1
			FROM ccUsers_Roles NOLOCK
			WHERE User_id = @AdminId
				AND Rol_id = 7
			)
	BEGIN
		WITH wgId
		AS (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT
								CAST(IdCampEsp AS INT) AS CampId,
								descripcion AS Description,
								isnull(IDArea, -1) AS AreaID,
								CAST(chat AS SMALLINT) AS CampaignType,
								CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
		FROM ccRIACampEspWG A(NOLOCK)
		INNER JOIN wgId ON wgId.IDWG = A.IDWG
			AND A.Tipo = 0
		INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id
			AND ((@multi_type is null AND cci.chat = @InboundType) OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

	END
	ELSE
	BEGIN
					SELECT DISTINCT
					CAST(Inbound_id AS INT) AS CampId,
					descripcion AS Description,
					isnull(IDArea, -1) AS AreaID,
					CAST(chat AS SMALLINT) AS CampaignType,
					CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
					FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
					AND ((@multi_type is null AND cci.chat = @InboundType)
						OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

	END
END

ELSE IF @Option = 15
BEGIN
			--SELECT DISTINCT
			--CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			--FROM ccInbound NOLOCK where cam_id = @Id and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))

	select
		CAST(Inbound_id AS INT) AS CampId,
		cci.descripcion AS Description,
		isnull(cci.IDArea, -1) AS AreaID,
		CAST(chat AS SMALLINT) AS CampaignType,
		CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId
	from ccCamps ccc
	INNER JOIN ccInbound cci ON cci.IDArea = ccc.IDArea
	where ccc.cam_id = @Id
		and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
		and isnull(cci.cam_id,-1) > 0

END
ELSE IF  @Option=16
begin
	DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
	DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
	select @AreaId = IDArea from ccUsers where User_id = @Id
	declare @camps table (cam_id int)
	insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
	if((select SUM(cam_id) from @camps) IS NULL)
		begin
			select '''' as CampName
			,0 as Conversations
			,0 as Assign
			,0 as OnQueu
			,0 AS FinishedBySystem
			,0 AS FinishedByAgent
			,'''' as AreaName
			,0 as IsAssignedCamps
		end
	else
		begin
			;with camDesc as(
			select
			c.cam_id as cam_id
			,cam_descripcion as cam_desc
			,area.AreaName
			from ccCamps c with (nolock)
			inner join @camps id on c.cam_id = id.cam_id
			inner join ccRIACat_Areas area on area.IDArea = c.IDArea
			group by area.AreaName, c.cam_id, c.cam_descripcion
			)
			,
			currentConversationWa as (
			select conversationId, camId, assignDate, onQueue,finishedBy
			,case when conversationStatus = 2 then 1 else 0 end as assigned
			from ccWhatsAppConversationsOut with (nolock)
			where assignDate >= @from and assignDate <= @to
			)
			select
			b.cam_desc as CampName
			,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
			,COALESCE(SUM(ccw.assigned), 0) AS Assign
			,COALESCE(count(ccw.onQueue),0) as OnQueu
			,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
			,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
			,b.AreaName as AreaName
			,1 as IsAssignedCamps
			from camDesc b
			left join currentConversationWa ccw on ccw.camId = b.cam_id
			group by b.cam_id, b.cam_desc, b.AreaName
		end
	end
ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
		IF @groupList IS NOT NULL BEGIN
			IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
			SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
			SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
			ORDER BY IdCampEsp ASC;
		END;
		ELSE BEGIN
			RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
		END;
		RETURN 0;
	END;

ELSE IF @Option = 18 BEGIN -- Validar si la campaña fue eliminada del area
		DECLARE @activo INT;

		IF @CampType = 0 BEGIN
			SELECT @activo = ISNULL(IDArea, 0)
			FROM ccInbound
			WHERE Inbound_id = @Id;
		END;

		ELSE BEGIN
		    SELECT @activo = ISNULL(IDArea, 0)
			FROM ccCamps
			WHERE cam_id = @Id;
		END;

		SELECT @activo;
	END;

ELSE IF @Option = 19
	BEGIN

		DECLARE @SuccessId INT, @NonComprehensionId INT;
		DECLARE @IsSuperUser BIT = 0;
		DECLARE @wgId TABLE (IDWG INT);

		IF EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7)
		BEGIN
			SET @IsSuperUser = 1;
		END
		ELSE
		BEGIN
			INSERT INTO @wgId (IDWG)
			SELECT IDWG
			FROM ccRIAWorkGroupUsers WITH (NOLOCK)
			WHERE user_id = @AdminId;
		END

		SELECT
			@SuccessId = ISNULL(idForSuccessfulTransaction, -1),
			@NonComprehensionId = ISNULL(idForNonComprehension, -1)
		FROM ccInbound WITH (NOLOCK)
		WHERE Inbound_id = @CampId;

		WITH MainCampaigns AS (
			SELECT
				CAST(cci.Inbound_id AS INT) AS CampId,
				cci.descripcion AS Description,
				ISNULL(cci.IDArea, -1) AS AreaID,
				CAST(cci.chat AS SMALLINT) AS CampaignType,
				CAST(0 AS BIT) AS IsSuccessTransfer,
				CAST(0 AS BIT) AS IsNonComprehensionTransfer
			FROM ccInbound cci WITH (NOLOCK)
			WHERE
			(
				-- Superusuario: por Área
				(@IsSuperUser = 1 AND cci.IDArea = @AreaId)
				OR
				-- Usuario normal: por Workgroup
				(@IsSuperUser = 0 AND EXISTS (
					SELECT 1 FROM ccRIACampEspWG A WITH (NOLOCK)
					INNER JOIN @wgId wg ON wg.IDWG = A.IDWG
					WHERE A.Tipo = 0 AND A.IdCampEsp = cci.Inbound_id
				))
			)
			AND cci.chat = 0
			AND cci.IDArea = @AreaId
		),
		ReferencedCampaigns AS (
			SELECT
				CAST(cci.Inbound_id AS INT) AS CampId,
				cci.descripcion AS Description,
				ISNULL(cci.IDArea, -1) AS AreaID,
				CAST(cci.chat AS SMALLINT) AS CampaignType,
				CASE WHEN cci.Inbound_id = @SuccessId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSuccessTransfer,
				CASE WHEN cci.Inbound_id = @NonComprehensionId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNonComprehensionTransfer
			FROM ccInbound cci WITH (NOLOCK)
			WHERE cci.Inbound_id IN (@SuccessId, @NonComprehensionId)
		)

		SELECT * FROM ReferencedCampaigns
		UNION ALL
		SELECT m.*
		FROM MainCampaigns m
		LEFT JOIN ReferencedCampaigns r
		  ON m.CampId = r.CampId
		WHERE r.CampId IS NULL;
	END;
END;'
	EXEC(@sql)


 SET @process = 'Se modifica ccsp_GalateaAdminCampaignsSurvey, para obtener campañas de IA'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaignsSurvey]
            @Option AS      INT,
            @CampType AS    INT = 0,
            @AdminId AS     INT = 0,
            @CampId AS      INT = 0,
            @SurveyCampId   INT = 0,
            @Module AS SMALLINT = 12,
            @HistoryAction AS SMALLINT = 1

            AS
            BEGIN
                DECLARE @idArea SMALLINT = NULL;
                DECLARE @operation INT = -1;
                DECLARE @mediaType INT = 0;

                IF(@Option IN (3, 4)) BEGIN
                    IF(@Module <> 12) BEGIN
                        IF(@CampType = 0)BEGIN
                            SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @CampId);
                            SET @operation = CASE WHEN @HistoryAction = 1 THEN
                                                                                CASE
                                                                                        WHEN @mediaType = 1  THEN 63
                                                                                        WHEN @mediaType = 5  THEN 40
                                                                                        ELSE 60 END
                                                                                ELSE
                                                                                    CASE
                                                                                        WHEN @mediaType = 1  THEN 64
                                                                                        WHEN @mediaType = 5  THEN 53
                                                                                        ELSE 52 END
                                                                                END;
                        END ELSE BEGIN
                            SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @CampId);
                            SET @operation = CASE WHEN @HistoryAction = 1 THEN
                                                                                CASE
                                                                                        WHEN @mediaType = 6  THEN 44
                                                                                        WHEN @mediaType = 5  THEN 46
                                                                                        WHEN @mediaType = 4  THEN 48
                                                                                        WHEN @mediaType = 7  THEN 50
                                                                                        ELSE 42 END
                                                                                ELSE
                                                                                    CASE
                                                                                        WHEN @mediaType = 6  THEN 55
                                                                                        WHEN @mediaType = 5  THEN 56
                                                                                        WHEN @mediaType = 4  THEN 57
                                                                                        WHEN @mediaType = 7  THEN 58
                                                                                        ELSE 54 END
                                                                                END;
                        END
                    END ELSE BEGIN
                        SET @operation = CASE WHEN @Option = 3 THEN 93 ELSE 94 END;
                    END
                END

                IF @Option = 1 -- Otption 1 - Get all campaigns
                BEGIN
                IF NOT EXISTS
                        (
                            SELECT 1
                            FROM ccUsers_Roles NOLOCK
                            WHERE User_id = @AdminId
                                    AND Rol_id = 7
                        )
                        BEGIN
                            IF @CampType = 1 BEGIN
                                WITH wgId
                                    AS (SELECT IDWG
                                        FROM ccRIAWorkGroupUsers NOLOCK
                                        WHERE user_id = @AdminId)
                                    SELECT DISTINCT
                                        CAST(IdCampEsp AS INT) AS CampId,
                                        cam_descripcion AS Description,
                                        CAST(isnull(IDArea, -1) AS INT) AS AreaID,
                                        CAST(CASE WHEN CampType = 9 THEN 10 ELSE CampType END AS INT) AS Channel,
                                        CAST(surveyCamId AS INT) AS SurveyCamId,
                                        CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                        CAST(1 AS INT) As CampType
                                    FROM ccRIACampEspWG A
                                        INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
                                        INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id AND ccc.CampType IN (0,4,9,6) AND ccc.ivrScript = 0 AND ccc.callsBySurvey = 0
                                        LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                            END ELSE BEGIN
                                WITH wgId
                                    AS (SELECT IDWG
                                        FROM ccRIAWorkGroupUsers NOLOCK
                                        WHERE user_id = @AdminId)
                                    SELECT DISTINCT
                                        CAST(IdCampEsp AS INT) AS CampId,
                                        descripcion AS Description,
                                        CAST(isnull(IDArea, -1) AS INT) AS AreaID,
                                        CAST(chat AS INT) AS Channel,
                                        CAST(isnull(ccie.SurveyCamId, 0) AS INT) AS SurveyCamId,
                                        CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                        CAST(0 AS INT) As CampType
                                    FROM ccRIACampEspWG A
                                        INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 0
                                        INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND cci.chat IN (0)
                                        LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                        LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    ORDER BY CampId ASC
                            END
                        END ELSE BEGIN
                            IF @CampType = 1 BEGIN
                                    SELECT DISTINCT
                                        CAST(ccc.cam_id AS INT) AS CampId,
                                        cam_descripcion AS Description,
                                        CAST(isnull(IDArea, -1) AS INT) AS AreaID,
                                        CAST(CampType AS INT) AS Channel,
                                        CAST(surveyCamId AS INT) AS SurveyCamId,
                                        CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                        CAST(1 AS INT) As CampType
                                    FROM ccCamps ccc (NOLOCK)
                                        LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                                    WHERE ccc.CampType IN (0,4,6) AND ccc.ivrScript = 0 AND ccc.callsBySurvey = 0
                            END ELSE BEGIN
                                    SELECT DISTINCT
                                        CAST(cci.Inbound_id AS INT) AS CampId,
                                        descripcion AS Description,
                                        CAST(isnull(IDArea, -1) AS INT) AS AreaID,
                                        CAST(chat AS INT) AS Channel,
                                        CAST(isnull(ccie.SurveyCamId, 0) AS INT) AS SurveyCamId,
                                        CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                        CAST(0 AS INT) As CampType
                                    FROM ccInbound cci (NOLOCK)
                                        LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                        LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    WHERE cci.chat = 0
                                    ORDER BY CampId ASC
                            END
                        END
                END -- Option 1 - Get all campaigns
                IF @Option = 2 BEGIN -- Option 2 - Get all survey camps
                    WITH wgId
                            AS (SELECT IDWG
                                FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT
                                CAST(IdCampEsp AS INT) AS CampId,
                                cam_descripcion AS Description,
                                CAST(isnull(IDArea, -1) AS INT) AS AreaID,
                                CAST(8 AS INT) AS Channel,
                                CAST(surveyCamId AS INT) AS SurveyCamId,
                                CAST(ccRCG.graphic_id AS INT) As Frame,
                                CAST(8 AS INT) As CampType
                            FROM ccRIACampEspWG A
                                INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
                                INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id AND ccc.CampType IN (0,8) AND ccc.ivrScript <> 0 AND ccc.callsBySurvey <> 0
                                LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                            ORDER BY CampId ASC
                END -- Option 2 - Get all survey camps
                IF(@Option = 3) BEGIN --Option 3 - Associate Survey Campaign to Campaign
                    IF(@CampType = 0) BEGIN
                        IF EXISTS(SELECT * FROM ccInbound WHERE Inbound_id = @CampId) BEGIN
                            IF EXISTS(SELECT * FROM ccInboundExtend WHERE Inbound_id = @CampId) BEGIN
                                UPDATE ccInboundExtend SET SurveyCamId = @SurveyCampId WHERE Inbound_id = @CampId;
                            END ELSE BEGIN
                                INSERT INTO ccInboundExtend (Inbound_id, SurveyCamId)
                                VALUES(@CampId, @SurveyCampId);
                            END

                            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @CampId)

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                            SELECT
                                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                                getDate(),
                                (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId),
                                @operation,
                                @Module,
                                CASE WHEN @Module = 12 THEN '''' ELSE ''ASSOCIATED_CAMP_SURVEY'' END,
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccInboundExtend WHERE Inbound_id = @CampId)),
                                (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @CampId)

                            SELECT 1 AS Status
                        END ELSE BEGIN
                            SELECT -1 AS Status
                        END
                    END
                    ELSE BEGIN
                        IF EXISTS(SELECT * FROM ccCamps WHERE cam_id = @CampId) BEGIN
                            UPDATE ccCamps SET SurveyCamId = @SurveyCampId WHERE cam_id = @CampId;

                            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @CampId)

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                            SELECT
                                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                                getDate(),
                                (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId),
                                @operation,
                                @Module,
                                CASE WHEN @Module = 12 THEN '''' ELSE ''ASSOCIATED_CAMP_SURVEY'' END,
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccCamps WHERE cam_id = @CampId)),
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @CampId)
                            SELECT 1 AS Status
                        END ELSE BEGIN
                            SELECT -1 AS Status
                        END
                    END
                END
                IF(@Option = 4) BEGIN --Option 4 - Disassociate Survey Campaign from Campaign
                    IF(@CampType = 0) BEGIN
                        IF EXISTS(SELECT * FROM ccInbound WHERE Inbound_id = @CampId) BEGIN
                            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @CampId)

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                            SELECT
                                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                                getDate(),
                                (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId),
                                @operation,
                                @Module,
                                CASE WHEN @Module = 12 THEN '''' ELSE ''DISASSOCIATED_CAMP_SURVEY'' END,
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccInboundExtend WHERE Inbound_id = @CampId)),
                                (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @CampId)

                            UPDATE ccInboundExtend SET SurveyCamId = 0 WHERE Inbound_id = @CampId;
                            SELECT 1 AS Status
                        END ELSE BEGIN
                            SELECT -2 AS Status
                        END
                    END
                    ELSE BEGIN
                        IF EXISTS(SELECT * FROM ccCamps WHERE cam_id = @CampId) BEGIN
                            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @CampId)

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                            SELECT
                                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                                getDate(),
                                (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId),
                                @operation,
                                @Module,
                                CASE WHEN @Module = 12 THEN '''' ELSE ''DISASSOCIATED_CAMP_SURVEY'' END,
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccCamps WHERE cam_id = @CampId)),
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @CampId)

                            UPDATE ccCamps SET SurveyCamId = 0 WHERE cam_id = @CampId;
                            SELECT 1 AS Status
                        END ELSE BEGIN
                            SELECT -2 AS Status
                        END
                    END
                END
            END;
    '
    EXEC(@sql);

    SET @process = 'CW-8305 se modifica update para planchar dialingType'
SET @sql = '
    ALTER PROCEDURE [dbo].[ccsp_GalateaDialer]
    @Description varchar(40)='''',
    @DialerId int = 0,
    @PortNumber int = 0,
    @Status varchar(1)='''',
    @action smallint=0,
    @Provider smallint=0,
    @XferType smallint=0,
    @PortEnd int = 0,
    @CampId smallint = 0,
    @dialer_ids varchar(2000)='''',
    @DialingType tinyint = 0,
    @idDialingCode int = 0
    AS
    set nocount on
    if @action=1
    begin
        select provedor_id as ProviderId, descrip as ProviderName  from cstoProvedor
    end
    if @action=2 --Insert
    begin
        create table #tempPortTable( portId int primary key)
        if @PortEnd>0 begin
            begin transaction
                while @PortNumber<=@portEnd begin
                insert into #tempPortTable values(@PortNumber)
                set @PortNumber=@PortNumber+1
                end
            commit transaction
        end
        else begin
            insert into #tempPortTable values(@PortNumber)
        end

        if exists(select Puerto from ccoDialers where Puerto in (select portId from #tempPortTable))
        begin
            drop table #tempPortTable
            select -1 as ResponseCode
            return(0)
        end
        Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype, DialingType, IdCode)
        Select @Description+''_''+CAST(portId as varchar(5)), portId, @Status, @Provider, @XferType, case @DialingType when 2 then 0 else @DialingType end, @idDialingCode from #tempPortTable t
        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription,
        p.descrip as ProviderDescription, Puerto, XferType, DialingType, IdCode as DialingCode
        from ccoDialers d
        inner join cstoProvedor p on p.provedor_id=d.provedor_id
        where Puerto in (select portId from #tempPortTable)
        drop table #tempPortTable
    end
    if @action=3 --Update
    begin
        if exists(select Puerto from ccoDialers where Puerto=@PortNumber and dialer_id <> @DialerId)
        begin
            select -1 as ResponseCode ---Port already exists
            return(0)
        end
        Update ccoDialers set Descripcion=case @Description when '''' then Descripcion else @Description+''_''+cast(@PortNumber as varchar(5)) end,
        Puerto=case @PortNumber when '''' then Puerto else @PortNumber end, Status=case @Status when '''' then Status else @status end,
        provedor_id=case @Provider when '''' then provedor_id else @Provider end,
        xfertype = case @XferType when 0 then xfertype else @XferType end,
        DialingType = case when @DialingType = 0 then DialingType when @DialingType = 2 then 0 else @DialingType end,
        IdCode = case when @DialingType = 1 then 0 when @idDialingCode != IdCode then @idDialingCode else IdCode end
        where Dialer_id=cast(@DialerId as int)

        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription,
        p.descrip as ProviderDescription, Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end as DialingCode
        from ccoDialers d
        inner join cstoProvedor p on p.provedor_id=d.provedor_id
        where dialer_id=@DialerId
    end
    if @action=4 --Delete
    begin
        if exists(select Dialer_id from ccoDialerCamp where
            Dialer_id in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '','')))
        begin
            select -2 as ResponseCode --Existe alguna campaña que esta utilizando este dialer
            return(0)
        end
        declare @portsDelete table(DialerId int, Port int,PortDescription varchar(15))
        insert @portsDelete (DialerId,Port,PortDescription)
        select Value, Puerto,Descripcion from dbo.fn_RIASplitDelimited (@dialer_ids, '','')
        inner join ccoDialers on dialer_id=Value
        delete from ccoDialers Where Dialer_id in (select DialerId from @portsDelete)

        select 200 as ResponseCode, DialerId, PortDescription
        from @portsDelete
    end
    if @action=5 --Ports Info
    begin
        select dc.cam_id as CampId, c.cam_descripcion as CampName, graphic_id as Frame, c.IDArea, a.AreaName
        from ccoDialerCamp dc
        inner join ccCamps c on c.cam_id=dc.cam_id
        inner join ccRIACat_Areas a on a.IDArea=c.IDArea
        inner join ccRIACampsGraph cg on c.cam_id=cg.cam_id
        where dc.dialer_id=@DialerId
        return(0)
    end
    if @action = 6
begin
    select dialer_id as PortId, Descripcion as PortName from ccoDialers where dialer_id in (select Value from dbo.fn_RIASplitDelimited(@dialer_ids, '',''))
    return(0)
end

if @action = 7
begin
    select cam_descripcion from ccCamps where @CampId = cam_id
    return(0)
end

if @action = 8
begin
    select
        case
            when @Description <> '''' and @Description + ''_'' + CAST(d.Puerto as varchar) <> d.Descripcion then cast(1 as bit)
            else cast(0 as bit)
        end as NameChanged,

        case
            when @XferType <> 0 and @XferType <> d.xfertype then cast(1 as bit)
            else cast(0 as bit)
        end as XferTypeChanged,

        case
            when @Provider <> 0 and @Provider <> d.provedor_id then cast(1 as bit)
            else cast(0 as bit)
        end as ProviderChanged,

        case
            when @PortNumber <> 0 and @PortNumber <> d.Puerto then cast(1 as bit)
            else cast(0 as bit)
        end as PortNumberChanged,

        d.Descripcion as PortName,

        p.descrip as ProviderName,

        x.description as XferName

    from ccoDialers d
    left join cstoProvedor p on p.provedor_id = @Provider
    left join ccoXferType x on x.XferType_id = @XferType
    where d.dialer_id = @DialerId

    return(0)
end
    set nocount off
'

EXEC(@sql)

	SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]'
       SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
DECLARE @now DATETIME = GETDATE();


if @type = 1 --Session time
    begin

        SELECT User_id, case
            WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
                THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
            ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
                convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), @now, 14)))
            END as logintime
        FROM ccLogLogin a with(nolock,index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
        where fecha >= @fecha_ini
        and a.User_id = b.agt
        and b.sup = @sup_id
        GROUP BY User_id
    end

else if @type = 2 begin--Status agent

    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where
        wgAdmin.User_id=@sup_id
    )

    select User_id,TipoStatusAge_id,sum(segundos) as segundos from (
    SELECT User_id, TipoStatusAge_id, tStatus As segundos
    FROM ccLogAgentesDia a with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent b  on  a.User_id = b.userId
    WHERE fecha >= @fecha_ini
    union all
    select A.User_id,
    case when A.TipoStatusAge_id in(0,1) then 3
    when A.currentStatus in (21,5,9) then 4
    else A.currentStatus end as TipoStatusAge_id,
    DATEDIFF(ss,A.fecha,getdate()) as seconds
    from ccLogAgentesDia A with(nolock)
    inner join
    (select max(fecha) fecha,USER_ID from ccLogAgentesDia D with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent C on D.User_id=C.userId
    where fecha >= @fecha_ini
        group by User_id) B
    on A.User_id=B.User_id and A.fecha=B.fecha and A.currentStatus not in (0,-2)

    )x
    group by User_id,TipoStatusAge_id
    ORDER BY User_id

end

else if @type = 3 begin

    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where
        wgAdmin.User_id=@sup_id
    )

    select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold
    from ccusers As users ,
        (
            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
            WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
            ELSE 2                          --Llamada de OutBound
            END AS ''type_calls'',
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end)) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
            from TableUserAgent as tAgent
            inner join ccoCallsOut calls WITH (NOLOCK index(IX_ccoCallsOut_10))
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id, cal_manual--,tAgent.login

            union

            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
            ELSE 1                          --Llamada de InBound
            END AS ''type_calls'',
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end)) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold

            from TableUserAgent as tAgent
            inner join ccCallsIn calls WITH (NOLOCK index(IX_ccCallsIn_5))
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id--,tAgent.login
        ) AS calls
        where users.user_id = calls.user_id

    end

else if @type = 4
    begin

        ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where
        wgAdmin.User_id=@sup_id
    )


        select a.user_id, a.login
        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
        inner join TableUserAgent b on a.User_id=b.userId
    end
else if @type = 5
    begin
    declare @users table(userId int primary key)


    if exists(select * from ccUsers_Roles where User_id=@sup_id and Rol_id=1 ) begin
        insert into @users
        select user_id from ccUsers where TipoUser_id=1
    end
    else begin

        insert into @users
        select distinct wgAgt.User_id as userId --,usr.login
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where
        wgAdmin.User_id=@sup_id
    end

    SELECT cast(User_id AS INT) UserId
        ,sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END) NotReady
        ,sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END) Ready
        ,sum(CASE WHEN TipoStatusAge_id = 4 THEN tStatus ELSE 0 END) Dialog
        ,sum(CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE 0 END) XFer
        ,sum(CASE WHEN TipoStatusAge_id = 6 THEN tStatus ELSE 0 END) Wrapup
        ,sum(CASE WHEN TipoStatusAge_id = 7 THEN tStatus ELSE 0 END) Other
        ,sum(CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE 0 END) Ringing
        ,sum(CASE WHEN TipoStatusAge_id = 11 THEN tStatus ELSE 0 END) Problem
        FROM ccLogAgentesDia A with(nolock)
        inner join @users B on A.User_id=B.userId
        WHERE fecha >= @fecha_ini
            AND TipoStatusAge_id > 0
        GROUP BY User_id


    end
set nocount on'
       EXEC(@sql)

    SET @process = 'cw-3201 drop function fnGetTimeZoneByZip'
        SET @Sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''fnGetTimeZoneByZip'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        Drop function fnGetTimeZoneByZip
    end'
        EXEC (@Sql)

     SET @process = 'cw-3201 drop function fnGetTimeZoneByZip'
        SET @Sql = 'CREATE FUNCTION dbo.fnGetTimeZoneByZip
(
    @zipCode VARCHAR(30)
)
RETURNS TABLE
AS
RETURN
(
    -- Devuelve ambos tz_id en una sola evaluación (invierno/verano)
    SELECT
        inv.tz_id AS tz_id_invierno,
        v.tz_id   AS tz_id_verano
    FROM ccTimeZoneAreaCP AS z WITH (NOLOCK)
    INNER JOIN ccTimeZones AS inv
        ON inv.tz_offset = z.WinterTimeDifference
    INNER JOIN ccTimeZones AS v
        ON v.tz_offset   = z.SummerTimeDifference
    WHERE z.ZipCode = @zipCode
);'
     EXEC (@Sql)


 SET @process = 'Se elimina SP ccsp_DeleteAndGetSMSOutIds'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_DeleteAndGetSMSOutIds'')
        begin
            DROP PROCEDURE ccsp_DeleteAndGetSMSOutIds;
        end'
    EXEC(@sql)


    SET @process = '#2154 CREATE PROCEDURE [dbo].[ccsp_DeleteAndGetSMSOutIds] '
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DeleteAndGetSMSOutIds]
@action int,
@tableName SYSNAME,
@campId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);

    -- Acción DELETE
    IF @action =1
    BEGIN
        SET @SQL = ''
        WHILE 1=1
        BEGIN
            DELETE TOP (5000) A
            FROM dbo.smsOutSource AS sos
            INNER JOIN dbo.'' + QUOTENAME(@TableName) + '' B ON sos.callkey = B.Cal_key
            INNER JOIN dbo.smsOutSourceMessage A ON A.smsout_id = sos.smsout_id
            LEFT JOIN dbo.smsworkingtable WT
                ON A.smsout_id = WT.smsout_id
                AND sos.cam_id = WT.cam_id
            WHERE sos.cam_id = @CampId
            AND (WT.smsout_id IS NULL or WT.sms_status=0);

            IF @@ROWCOUNT = 0 BREAK;
        END'';

        EXEC sp_executesql @SQL, N''@CampId INT'', @CampId = @CampId;
    END

    -- Acción SELECT
    ELSE IF @action = 2
    BEGIN
        SET @SQL = ''
        ;WITH RankedSMS AS (
            SELECT
                sos.smsout_id,
                sos.callkey,
                ROW_NUMBER() OVER (
                    PARTITION BY sos.callkey
                    ORDER BY sos.smsout_id DESC
                ) AS rn
            FROM dbo.smsOutSource AS sos WITH (NOLOCK)
            INNER JOIN dbo.'' + QUOTENAME(@TableName) + '' B
                ON sos.callkey = B.Cal_key
            LEFT JOIN dbo.smsworkingtable WT
                ON sos.smsout_id = WT.smsout_id
                AND sos.cam_id = WT.cam_id

            WHERE sos.cam_id = @CampId
            AND (WT.smsout_id IS NULL or WT.sms_status=0)
        )
        SELECT smsout_id, callkey
        FROM RankedSMS
        WHERE rn = 1;'';


        EXEC sp_executesql @SQL, N''@CampId INT'', @CampId = @CampId;
    END
END'
    EXEC(@sql)





set @process = 'Facturación - Validación sp ccsp_getCDRData'
    set @sql='
    if exists (select * from sys.procedures where name = N''ccsp_getCDRData'')
    begin
        DROP PROCEDURE ccsp_getCDRData
    end'
    EXEC(@sql)
    SET @process = 'Create  ccsp_getCDRData para obtener datos necesarios del CDR en el Telephony'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_getCDRData]
    @phone VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @country TINYINT;
    DECLARE @cldCountry VARCHAR(7);
    DECLARE @cldLocal VARCHAR(7);
    DECLARE @tel VARCHAR(32);
    DECLARE @ld VARCHAR(7);
    DECLARE @serie VARCHAR(10);
    DECLARE @cdrCountry VARCHAR(255) = '''';
    DECLARE @region VARCHAR(255) = '''';
    DECLARE @locality VARCHAR(255) = '''';
    DECLARE @modality VARCHAR(255) = '''';
    DECLARE @network_type VARCHAR(255) = '''';
    DECLARE @lon TINYINT;

    -- Get settings
    SELECT @country = valor FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
    SELECT @cldLocal = valor FROM ccSettings WITH (NOLOCK) WHERE setting_id = 17;
    SELECT @cldCountry = VALOR FROM ccsettings2 WHERE setting_id = 273;

    -- Clean phone
    SET @tel = dbo.limpia(@phone);
    SET @lon = LEN(@tel);

    IF @lon > 10
    BEGIN
        -- Detect country code
        SELECT TOP 1
            @cldCountry = CAST(CodeCountry AS VARCHAR(50)),
            @cdrCountry = CountryAbbreviation
        FROM ccWhatsOringCountry
        WHERE LEFT(@tel, LEN(CodeCountry)) = CodeCountry
        ORDER BY LEN(CodeCountry) DESC;

        -- Remove country code prefix from phone
        IF @cldCountry IS NOT NULL AND LEN(@cldCountry) > 0
        BEGIN
            IF LEFT(@tel, LEN(@cldCountry)) = @cldCountry
                SET @tel = SUBSTRING(@tel, LEN(@cldCountry)+1, LEN(@tel));
        END
    END
    ELSE
    BEGIN
        SELECT TOP 1
            @cldCountry = CAST(CodeCountry AS VARCHAR(50)),
            @cdrCountry = CountryAbbreviation
        FROM ccWhatsOringCountry
        WHERE REPLACE(@cldCountry, ''+'', '''') = CodeCountry
        ORDER BY LEN(CodeCountry) DESC;
    END

    IF @cldCountry = ''52''
    BEGIN
        IF @lon IN (7,8)
        BEGIN
            SET @tel = @cldLocal + @tel;
            SET @ld = @cldLocal;
        END

        SET @tel = RIGHT(@tel,10);
        SET @lon = LEN(@tel);

        IF @lon = 10
        BEGIN
            -- PRIMERO revisa si es 800 nacional de México
            IF LEFT(@tel, 3) = ''800''
            BEGIN
                SET @network_type = ''Toll-free'';
                SET @modality = '''';
                SET @region = '''';
                SET @locality = '''';
            END
            ELSE
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM series WITH (NOLOCK)
                    WHERE cld = LEFT(@tel,3) AND serie = SUBSTRING(@tel,4,3)
                )
                BEGIN
                    SET @ld = LEFT(@tel,3);
                    SET @serie = SUBSTRING(@tel,4,3);
                END
                ELSE IF EXISTS (
                    SELECT 1 FROM series WITH (NOLOCK)
                    WHERE cld = LEFT(@tel,2) AND serie = SUBSTRING(@tel,3,4)
                )
                BEGIN
                    SET @ld = LEFT(@tel,2);
                    SET @serie = SUBSTRING(@tel,3,4);
                END

                IF @serie IS NOT NULL
                BEGIN
                    SELECT TOP 1
                        @region = estado,
                        @locality = municipio,
                        @modality = modalidad,
                        @network_type = [TIPO DE RED]
                    FROM series WITH (NOLOCK)
                    WHERE cld = @ld AND serie = @serie;
                END
                ELSE
                BEGIN
                    SELECT TOP 1
                        @region = estado,
                        @locality = municipio,
                        @modality = modalidad,
                        @network_type = [TIPO DE RED]
                    FROM series WITH (NOLOCK)
                    WHERE cld = @cldLocal;
                END
            END
        END
    END

     -- Result with translation logic
    SELECT
        @tel AS phone,
        @locality AS locality,
        @region AS region,
        CASE
            WHEN @modality = ''FIJO'' THEN ''Fijo''
            ELSE @modality
        END AS modality,
        CASE
            WHEN @network_type = ''MOVIL'' THEN ''Mobile''
            WHEN @network_type = ''FIJO'' THEN ''Landline''
            ELSE @network_type
        END AS network_type,
        @cdrCountry AS country,
        @cldCountry AS country_code
END
'
    EXEC(@sql)



SET @process = '#2543 ALTER procedure [dbo].[ccsp_GetInfoDash]'
    SET @sql = 'ALTER procedure [dbo].[ccsp_GetInfoDash]
@CampId as smallint
as
set nocount on
declare @upd_date as datetime
declare @cps  as int
declare @today datetime

select @cps = [valor] from ccSettings  where setting_id=238
select
    @upd_date = date_update
from ccCampsInfo with(nolock) where cam_id = @CampId

set @today=convert(date,getdate(),121)

if @upd_date is null begin
    insert into ccCampsInfo(cam_id,contact_reg,dial_retries,date_update,calls_per_second)
    values(@CampId,0,0,getdate(),@cps)

    set @upd_date=@today
end

if (datediff(ss, @upd_date, getdate()) > 300) begin
    if not exists(select cam_id from ccocallsout with(nolock)
    where cam_id=@CampId and statuscall_id=13 and cal_inicio>= @today)
    begin
        update ccCampsInfo
            set contact_reg=0, dial_retries=0, date_update = getdate(), calls_per_second=@cps
        where cam_id = @CampId
    end else
    begin

        declare @vop1 decimal(12,2)
        declare @vop2 decimal(12,2)
        declare @vop3 decimal(12,2)
        declare @vop4 decimal(12,2)

        select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
        where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
        group by cam_id

        -- @vop2 y @vop4
        SELECT
          @vop2 = COUNT(DISTINCT callout_id),
          @vop4 = COUNT(DISTINCT telefono)
        FROM dbo.ccoLogDials WITH (NOLOCK)
        WHERE cam_id = @CampId AND fecha >= @today;

        -- @vop3 (reintentos de teléfono)
        SELECT
          @vop3 = COUNT(DISTINCT telefono)
        FROM dbo.ccoLogDials WITH (NOLOCK)
        WHERE cam_id = @CampId AND fecha >= @today
        GROUP BY telefono
        HAVING COUNT(1) > 1;


        if @vop2 is null
            set @vop2=0

        if @vop3 is null
            set @vop3=0

        if @vop4 is null
            set @vop4=0

        update ccCampsInfo set
             contact_reg=isnull( case when @vop2=0 then 0 else (@vop1/@vop2)*100 end,0)
            , dial_retries=isnull(case when @vop4=0 then 0 else(@vop3/@vop4)*100 end,0)
            , date_update=getdate()
    end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
    EXEC(@sql)


 SET @process = 'Sears ALTER PROCEDURE [dbo].[ccsp_IVRInsertCallback] ZonasHorarias'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_IVRInsertCallback]
    @ani    VARCHAR(40),
    @cam_id SMALLINT
AS
BEGIN
    -- Declaraciones
    DECLARE @tel VARCHAR(20);
    DECLARE @ld  VARCHAR(4);
    DECLARE @lon TINYINT,@iZonaHoraria int,@iZonaHoraria_verano int

    -- Limpieza y verificación del número
    SET @tel = RTRIM(LTRIM(@ani));
    SET @tel = dbo.verifica(@tel);

    -- Validación: si no comienza con ''E''
    IF LEFT(@tel, 1) <> ''E''
    BEGIN

        select @iZonaHoraria=dbo.fnGetTimeZone(@tel, 0),@iZonaHoraria_verano=dbo.fnGetTimeZone(@tel, 1)

        -- Inserta en ccoCallsOutSource
        INSERT INTO dbo.[ccoCallsOutSource]
        (
            [cal_key],
            [cal_telefono],
            [cam_id],
            [iZonaHoraria],
            [iZonaHoraria_verano]
        )
        VALUES
        (
            @ani,
            @tel,
            @cam_id,
            @iZonaHoraria,
            @iZonaHoraria_verano
        );

        -- Inserta en WT
        EXEC dbo.[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
            @cam_id,
            0;
    END;
END
'
    EXEC(@sql)


 SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_OUTCancelDialJOB]'
       SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTCancelDialJOB]
@callout_id    INT,
@IsAnswer      TINYINT,
@nOcupado      TINYINT,
@nNoContesta   TINYINT,
@nFax          TINYINT,
@nContestadora TINYINT,
@nShortCall    TINYINT,
@nOtro         TINYINT,
@ExisteWT      TINYINT = 1
AS
DECLARE @RecicleSIC TINYINT;

SELECT @RecicleSIC = valor FROM ccSettings with(nolock) WHERE setting_id = 60;
IF @RecicleSIC IS NULL
    SET @RecicleSIC = 0;

-- En workingtable
IF @ExisteWT > 0 BEGIN
    IF @IsAnswer = 1 BEGIN
            UPDATE ccoWorkingTable WITH(ROWLOCK)
            SET
                cal_fechaDial = DATEADD(hh, 1, GETDATE()),
                cal_status = 1,
                nOcupado = 1,
                nNoContesta = 1,
                nShortCall = nShortCall + 1
            WHERE callout_id = @callout_id;
    END;
        ELSE
        IF @RecicleSIC = 0 BEGIN
                DELETE ccoWorkingTable WITH(ROWLOCK) WHERE callout_id = @callout_id;
                DELETE ccoCallPriorityOrder WITH(ROWLOCK) WHERE callout_id = @callout_id;
        END;
END;'
       EXEC(@sql)


SET @process = '#2154 ALTER procedure [dbo].[ccsp_OUTGetNewJobsSMS]'
    SET @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobsSMS]
@CAMPID INT,
@action INT=0, --0 select and update, 1 select registry
@topCount INT=50

as
set nocount on
DECLARE @iZonas INT = NULL
DECLARE @bIsDaylight bit, @revHorario bit
DECLARE @country_id INT, @TipoJobs INT

DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
declare @sqlInsertGeneric nvarchar(MAX)
declare @parameters nvarchar(MAX)

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
SELECT @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0

if exists(SELECT cam_id from ccSmsSchedules where cam_id=@campid)
begin
    if @iZonas = 0 begin
        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
        return
    end
end


IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

CREATE TABLE #NEW_JOBS (
    SmsOutId INT
    ,CamId INT
    ,Phone VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS
    ,SmsStatus TINYINT
    ,DateDial DATETIME
    ,Tz1 INT
    ,Tz2 INT
    ,Tz3 INT
    ,Tz4 INT
    ,Tz5 INT
    ,CallKey VARCHAR(40)
    ,Message VARCHAR(255)
    )
set @sql=''''

DECLARE @new_calls_date VARCHAR(max) = '''';


SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)

    set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

    select @sqlInsertGeneric=nchar(13)+ ''INSERT #NEW_JOBS
SELECT top(@topCount) W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
sos.callkey as CallKey
,msg.message as Message
FROM smsWorkingTable W
left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
left join smsoutSourceMessage msg (nolock) on msg.smsout_id =W.smsout_id
WHERE STATUS_REPLACE_QUERY
and DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and msg.message is not null
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0)
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0)
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0)
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)''

if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
begin
    select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
    select @sql=@sql+REPLACE(
    REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial < dateadd(mi, 5, getdate())'')
        ,''STATUS_REPLACE_QUERY'',''W.sms_status=0'')
    select @sql=@sql+nchar(13)+'' order by W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
    --print(@sql)
end -- TOMA EN CUENTA LAS NUEVAS

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
    select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
    select @sql=@sql+nchar(13)+REPLACE(
        REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
    ,''STATUS_REPLACE_QUERY'',''W.sms_status=1 -- CallBacks'')
    select @sql=@sql+nchar(13)+'' order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)


end -- TOMA EN CUENTA LOS CALLBACKS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@iZonas int''

if @action=0
begin

    SELECT @sql=@sql+nchar(13)+ ''UPDATE smsWorkingTable with (rowlock) SET sms_status=2 --CALLBACK IN PROGRESS
    WHERE smsout_id in(SELECT SmsOutId from #NEW_JOBS)''
end


    select @sql=@sql+nchar(13)+ ''SELECT SmsOutId, CamId, Phone, SmsStatus, DateDial,
Tz1,Tz2,Tz3,Tz4,Tz5,CallKey as RegistryClient,Message
FROM #NEW_JOBS where len(Phone)>0
''


--print (@sql)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@iZonas=@iZonas

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

return(0)'
    EXEC(@sql)


    SET @process = 'SEARS ALTER PROCEDURE [dbo].[ccsp_OUTInsertaCallBack] ZonasHorarias'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertaCallBack]
    @cal_id        INT,
    @Telefono      VARCHAR(15),
    @Camp          SMALLINT,
    @FechaDial     SMALLDATETIME,
    @callout_id    INT = 0,
    @TelReprograma SMALLINT = -1,
    @user_id       INT = 0,
    @cal_Key       VARCHAR(40) = '''',
    @isAuto        BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @TelReprograma < 0
        RETURN (0);

    DECLARE @Fecha                SMALLDATETIME,
            @sSQL                 NVARCHAR(MAX),
            @iZonaHoraria         INT,
            @iZonaHoraria_verano  INT,
            @iZonaHoraria2        INT,
            @iZonaHoraria_verano2 INT,
            @iZonaHoraria3        INT,
            @iZonaHoraria_verano3 INT,
            @iZonaHoraria4        INT,
            @iZonaHoraria_verano4 INT,
            @iZonaHoraria5        INT,
            @iZonaHoraria_verano5 INT,
            @idZone               INT,
            @idZoneDaylight       INT,
            @list_id              INT,
            @bIsDaylight          BIT,
            @difference           INT,
            @TelOriginal          VARCHAR(15),
            @FechaOriginal        DATETIME,
            @country_id           VARCHAR(10),
            @ld                   VARCHAR(5);

    SELECT @country_id = valor FROM dbo.ccSettings WITH (NOLOCK) WHERE setting_id = 104;
    SELECT @ld   = valor FROM dbo.ccSettings WITH (NOLOCK) WHERE setting_id = 17;

    SELECT @callout_id   = callout_id,
           @TelOriginal  = cal_telefono,
           @FechaOriginal = cal_Inicio
    FROM dbo.ccoCallsOut
    WHERE cal_id = @cal_id;

    DECLARE @colSuffix  varchar(1) = CAST(@TelReprograma AS varchar(1));

    IF @TelReprograma = 0 -- Otro teléfono
    BEGIN
        DECLARE @tel2           VARCHAR(20),
                @tel3           VARCHAR(20),
                @tel4           VARCHAR(20),
                @tel5           VARCHAR(20),
                @phoneCompleted VARCHAR(20),
                @emptyPhoneMsg  VARCHAR(50);

        SELECT @idZone = dbo.fnGetTimeZone(@Telefono, 0),@idZoneDaylight = dbo.fnGetTimeZone(@Telefono, 1)

        SELECT @phoneCompleted = dbo.Completa(@Telefono, @country_id, @ld);
        SELECT @emptyPhoneMsg  = CASE valor WHEN 0 THEN ''El teléfono no puede ser nulo o vacío'' ELSE ''Phone number can not be null or empty'' END
        FROM dbo.ccSettings WHERE setting_id = 27;

        IF CHARINDEX(''E_NV'', @phoneCompleted) > 0 SET @phoneCompleted = @Telefono;
        IF @phoneCompleted = ''''
        BEGIN
            RAISERROR(@emptyPhoneMsg, 18, 1);
        END

        SELECT @tel2 = cal_telefono2,
               @tel3 = cal_telefono3,
               @tel4 = cal_telefono4,
               @tel5 = cal_telefono5,
               @cal_Key = cal_key
        FROM dbo.ccoCallsOutSource
        WHERE callout_id = @callout_id;

        SELECT @TelReprograma = CASE
                                    WHEN ISNULL(@tel4, '''') = '''' THEN 4
                                    WHEN ISNULL(@tel3, '''') = '''' THEN 3
                                    WHEN ISNULL(@tel2, '''') = '''' THEN 2
                                    ELSE 5
                                END;

        SET @sSQL = N''
        UPDATE dbo.ccoCallsOutSource
        SET cal_telefono'' + @colSuffix + N''       = @pPhone
            , cal_status                           = 2
            , iZonaHoraria'' + @colSuffix + N''       = @pIdZone
            , iZonaHoraria_Verano'' + @colSuffix + N'' = @pIdZoneDaylight
        WHERE callout_id = @pCalloutId;
        '';

        EXEC sys.sp_executesql
         @sSQL,
         N''@pPhone varchar(20), @pIdZone int, @pIdZoneDaylight int, @pCalloutId int'',
         @pPhone        = @phoneCompleted,
         @pIdZone       = @idZone,
         @pIdZoneDaylight = @idZoneDaylight,
         @pCalloutId    = @callout_id;

    END
    ELSE -- @TelReprograma > 0 teléfono ya existente
    BEGIN
        UPDATE dbo.ccoCallsOutSource
        SET cal_status = 2
        WHERE callout_id = @callout_id;

        set @colSuffix = CASE WHEN @TelReprograma = 1 THEN N'''' ELSE CONVERT(nvarchar(1), @TelReprograma) END;

        SET @sSQL = N''
        SELECT
            @outA = cal_key,
            @outB = iZonaHoraria'' + @colSuffix + N'',
            @outC = iZonaHoraria_Verano'' + @colSuffix + N'',
            @outD = RTRIM(LEFT(LTRIM(
                       cal_telefono  + N''''         '''' +
                       cal_telefono2 + N''''         '''' +
                       cal_telefono3 + N''''         '''' +
                       cal_telefono4 + N''''         '''' +
                       cal_telefono5 + N''''         ''''
                   ), 13))
        FROM dbo.ccoCallsOutSource
        WHERE callout_id = @pCalloutId;
        '';

        EXEC sys.sp_executesql
             @sSQL,
             N''@pCalloutId int,
               @outA varchar(33) OUTPUT,
               @outB int OUTPUT,
               @outC int OUTPUT,
               @outD varchar(19) OUTPUT'',
             @pCalloutId = @callout_id,
             @outA = @cal_Key OUTPUT,
             @outB = @idZone OUTPUT,
             @outC = @idZoneDaylight OUTPUT,
             @outD = @Telefono OUTPUT;
    END

    -- Para la fecha
    SELECT @bIsDaylight = dbo.fnIsDayLight(@country_id, GETDATE());

    IF @isAuto = 0
        SELECT @difference = dbo.fnGetTimeDifference(CASE WHEN @bIsDaylight = 0 THEN @idZone ELSE @idZoneDaylight END);
    ELSE
        SET @difference = 0;

    SELECT @Fecha = DATEADD(HOUR, @difference, CONVERT(DATETIME, @FechaDial, 101));

    UPDATE dbo.ccoCallsOut
    SET cal_fcallback = @FechaDial
    WHERE cal_id = @cal_id;

    -- Para las estadísticas
    IF EXISTS (SELECT 1 FROM dbo.ccRIAcallbacks WHERE año = YEAR(@Fecha) AND mes = MONTH(@Fecha) AND dia = DAY(@Fecha) AND hora = DATEPART(HOUR, @Fecha) AND cam_id = @Camp)
        UPDATE dbo.ccRIAcallbacks
        SET callbacks = callbacks + 1
        WHERE año = YEAR(@Fecha)
          AND mes = MONTH(@Fecha)
          AND dia = DAY(@Fecha)
          AND hora = DATEPART(HOUR, @Fecha)
          AND cam_id = @Camp;
    ELSE
        INSERT dbo.ccRIAcallbacks
        SELECT YEAR(@Fecha), MONTH(@Fecha), DAY(@Fecha), DATEPART(HOUR, @Fecha), ''1'', @Camp;

    SELECT @iZonaHoraria        = CASE WHEN LEN(cal_telefono)  > 0 THEN iZonaHoraria        ELSE NULL END,
           @iZonaHoraria_verano = CASE WHEN LEN(cal_telefono)  > 0 THEN iZonaHoraria_verano ELSE NULL END,
           @iZonaHoraria2       = CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2       ELSE NULL END,
           @iZonaHoraria_verano2= CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END,
           @iZonaHoraria3       = CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3       ELSE NULL END,
           @iZonaHoraria_verano3= CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END,
           @iZonaHoraria4       = CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4       ELSE NULL END,
           @iZonaHoraria_verano4= CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END,
           @iZonaHoraria5       = CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5       ELSE NULL END,
           @iZonaHoraria_verano5= CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE NULL END,
           @list_id             = list_id
    FROM dbo.ccoCallsOutSource
    WHERE callout_id = @callout_id;

    IF EXISTS (SELECT 1 FROM dbo.ccoWorkingTable WHERE callout_id = @callout_id)
    BEGIN
        UPDATE dbo.ccoWorkingTable
        SET cal_telefono       = @Telefono,
            cam_id             = @Camp,
            cal_fechaDial      = @Fecha,
            cal_status         = 1,
            nTryingContact     = 3,
            prioridad_cb       = 1,
            [user_id]          = @user_id,
            cal_keyw           = @cal_Key,
            iZonaHoraria       = @iZonaHoraria,
            iZonaHoraria_Verano= @iZonaHoraria_Verano,
            iZonaHoraria2      = @iZonaHoraria2,
            iZonaHoraria_Verano2= @iZonaHoraria_Verano2,
            iZonaHoraria3      = @iZonaHoraria3,
            iZonaHoraria_Verano3= @iZonaHoraria_Verano3,
            iZonaHoraria4      = @iZonaHoraria4,
            iZonaHoraria_Verano4= @iZonaHoraria_Verano4,
            iZonaHoraria5      = @iZonaHoraria5,
            iZonaHoraria_Verano5= @iZonaHoraria_Verano5
        WHERE callout_id = @callout_id;
    END
    ELSE
    BEGIN
        INSERT dbo.ccoWorkingTable
        (
            callout_id, cal_telefono, cam_id, cal_fechaDial, cal_status, nTryingContact, prioridad_cb,
            [user_id], cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2,
            iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5,
            iZonaHoraria_verano5, list_id
        )
        SELECT @callout_id, @Telefono, @Camp, @Fecha, 1, 3, 1,
               @user_id, @cal_Key,
               @iZonaHoraria, @iZonaHoraria_Verano,
               @iZonaHoraria2, @iZonaHoraria_Verano2,
               @iZonaHoraria3, @iZonaHoraria_Verano3,
               @iZonaHoraria4, @iZonaHoraria_Verano4,
               @iZonaHoraria5, @iZonaHoraria_Verano5,
               @list_id;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.ccoCallBacks WITH (NOLOCK) WHERE callout_id = @callout_id)
    BEGIN
        INSERT INTO dbo.ccoCallBacks
        (
            callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus
        )
        VALUES
        (
            @callout_id, @user_id, @Camp, @cal_Key, @TelOriginal, @Telefono, @FechaOriginal, @Fecha, NULL, 0, 1
        );
    END
    ELSE
    BEGIN
        UPDATE dbo.ccoCallBacks
        SET user_id        = @user_id,
            cam_id         = @Camp,
            cal_key        = @cal_Key,
            cal_telefono   = @TelOriginal,
            cal_telCB      = @Telefono,
            cal_fecha      = @FechaOriginal,
            cal_fusercallback = @Fecha,
            cal_fcallback  = NULL,
            status         = 0,
            schedulerStatus = 1
        WHERE callout_id = @callout_id;
    END

    SET NOCOUNT OFF;
END'
    EXEC(@sql)

     SET @process = 'SEARS ALTER PROCEDURE [dbo].[ccsp_OutInsertJob] ZonasHorarias'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OutInsertJob]
    @cve_t_cred   VARCHAR(4),
    @no_cuenta    VARCHAR(12),
    @cam_id       SMALLINT,
    @telempleo    VARCHAR(19),
    @telgarantia  VARCHAR(19),
    @teldomant    VARCHAR(19)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @iZonaHoraria        INT,
            @iZonaHoraria_verano INT,
            @iZonaHoraria2        INT,
            @iZonaHoraria_verano2 INT,
            @iZonaHoraria3        INT,
            @iZonaHoraria_verano3 INT

    -- Ajuste: uso de @telempleo para calcular la zona horaria en lugar de @cal_Telefono no declarado
    SET @iZonaHoraria        = dbo.fnGetTimeZone(@telempleo, 0);
    SET @iZonaHoraria_verano = dbo.fnGetTimeZone(@telempleo, 1);

    SET @iZonaHoraria2        = dbo.fnGetTimeZone(@telgarantia, 0);
    SET @iZonaHoraria_verano = dbo.fnGetTimeZone(@telgarantia, 1);

    SET @iZonaHoraria3        = dbo.fnGetTimeZone(@teldomant, 0);
    SET @iZonaHoraria_verano3 = dbo.fnGetTimeZone(@teldomant, 1);

    INSERT INTO dbo.[ccoCallsOutSource]
    (
        [cal_Key],
        [cam_id],
        [cal_telefono],
        [cal_telefono2],
        [cal_telefono3],
        [cal_status],
        [iZonaHoraria],
        [iZonaHoraria_verano],
        [iZonaHoraria2],
        [iZonaHoraria_verano2],
        [iZonaHoraria3],
        [iZonaHoraria_verano3]
    )
    VALUES
    (
        @cve_t_cred + @no_cuenta,
        @cam_id,
        @telempleo,
        @telgarantia,
        @teldomant,
        0,
        @iZonaHoraria,
        @iZonaHoraria_verano,
        @iZonaHoraria2,
        @iZonaHoraria_verano2,
        @iZonaHoraria3,
        @iZonaHoraria_verano3
    );

    SET NOCOUNT OFF;
END'
    EXEC(@sql)



SET @process = '#2543-Outbound-No se respetan tiempo de remarcacion.'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id     INT,
@CallResultDial TINYINT,
@isTCPA         BIT     = 0
AS
BEGIN

    SET NOCOUNT ON

    /*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
    ++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine */

    DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
    DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
    DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
    DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
    DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
    DECLARE @DateNextDial DATETIME, @DateNewDial DATETIME, @cam_id SMALLINT
    DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
    DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)
    DECLARE @ExistePriorityOrder TINYINT

    SELECT @cam_id = cam_id,
        @nOcupado = ISNULL(nOcupado, 0),
        @nNoContesta = ISNULL(nNoContesta, 0),
        @nFax = ISNULL(nFax, 0),
        @nContestadora = ISNULL(nContestadora, 0),
        @nShortCall = ISNULL(nShortCall, 0),
        @nOtro = ISNULL(nOtro, 0),
        @DateNextDial = cal_fechaDial
    FROM ccoWorkingTable with(nolock)
    WHERE callout_id = @callout_id

    SELECT @ExisteWT = CASE WHEN @cam_id IS NOT NULL THEN 1 ELSE 0 END
    SELECT @cal_status = CASE WHEN @isTCPA = 1 THEN 0 ELSE 1 END--si esta en modo TCPA no gene|rar callbacks

    IF @CallResultDial = 20 BEGIN-- CONTACTADO
        EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
        RETURN(0)
    END
    IF @CallResultDial = 1 BEGIN-- CONTESTO
        IF @isTCPA = 1 BEGIN
            UPDATE ccoWorkingTable WITH (ROWLOCK, UPDLOCK) SET cal_status = @cal_status WHERE callout_id = @callout_id
        END
        ELSE
        BEGIN
            IF (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) = 6
                RETURN(0)
            IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
                BEGIN
                    EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
            END
            ELSE BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
            END
        END
        RETURN(0)
    END
    IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
        SELECT @cam_ocupado = cam_ocupado,
        @cam_inter_ocupado = cam_inter_ocupado,
        @cam_NoInt_ocupado = cam_NoInt_ocupado,
        @nOcupado = @nOcupado + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_ocupado = 1
        BEGIN -- Opcion Ocupado HABILITADA
            IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4
            BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1    ELSE nNoContesta END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            IF @DateNewDial > @DateNextDial
            BEGIN   -- Nueva fecha de Call BACk
                UPDATE ccoWorkingTable WITH (ROWLOCK, UPDLOCK) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
                WHERE callout_id = @callout_id
                RETURN(0)
            END

            -- Mantiene la fecha de Call BACK
            UPDATE ccoWorkingTable WITH (ROWLOCK, UPDLOCK) SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- ELSE: Opcion Ocupado DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
        --select NO Contesta
        SELECT @cam_nocontesto = cam_nocontesto,
        @cam_inter_nocontesto = cam_inter_nocontesto,
        @cam_NoInt_nocontesto = cam_NoInt_nocontesto,
        @nNoContesta = @nNoContesta + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_nocontesto = 1
        BEGIN-- Opcion NoContesta HABILITADA
            IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4
            BEGIN --select No Contesta Habilitada
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
            ELSE nNoContesta END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

            UPDATE ccoWorkingTable WITH (ROWLOCK, UPDLOCK) SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono,
            cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial THEN @DateNewDial ELSE cal_fechaDial END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion NoContesta DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial = 4
    BEGIN-- Fax/Modem
        SELECT @cam_fax = cam_fax,
        @cam_inter_fax = cam_inter_fax,
        @cam_NoInt_fax = cam_NoInt_fax,
        @nFax = @nFax + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_fax = 1
        BEGIN-- Opcion Fax/Modem HABILITADA
            IF @nFax > @cam_NoInt_fax OR @nShortCall > 4
            BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            UPDATE ccoWorkingTable with(rowlock) SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono,
            cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial  THEN @DateNewDial ELSE cal_fechaDial END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion Fax/Modem DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial = 11
    BEGIN-- Maquina Contestadora
        SELECT @cam_graba = cam_graba,
        @cam_inter_graba = cam_inter_graba,
        @cam_NoInt_graba = cam_NoInt_graba,
        @nContestadora = @nContestadora + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
            IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4
            BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            UPDATE ccoWorkingTable with(rowlock) SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono,
            cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial THEN @DateNewDial ELSE cal_fechaDial END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion Maquina Contestadora DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial IN(10, 90)
    BEGIN--No Dial Tone, otros, NoService
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
        EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
    END

    RETURN(0)
    SET NOCOUNT OFF
END
'
EXEC(@sql);


SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_PhoneInBL]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_PhoneInBL]
@action as tinyint,
@cam_id as smallint = null,
@telefono as varchar(30) = null,
@cal_key as varchar(40) = null,
@telefono2 varchar(30) = null,
@telefono3 varchar(30) = null,
@telefono4 varchar(30) = null,
@telefono5 varchar(30) = null,
@insertRow nvarchar(max) =null

AS

declare @sql nvarchar(max)
DECLARE @tableName NVARCHAR(255)

if @action = 1 begin
    if (select dbo.ValidateBlackListPhone(@telefono,@cam_id,@cal_key)) = 1 begin
        select 1 as IsBlackList
    end
    else begin
        select 0 as IsBlackList
    end
end
else if @action =2 begin
    DECLARE @hKey BIGINT = dbo.hashList(@cal_key);

    ;WITH Phones AS (
      SELECT * FROM (
        SELECT 1 AS ord, dbo.hashPhone(@telefono) AS hTel
        UNION ALL
        SELECT 2, dbo.hashPhone(@telefono2)
        UNION ALL
        SELECT 3, dbo.hashPhone(@telefono3)
        UNION ALL
        SELECT 4, dbo.hashPhone(@telefono4)
        UNION ALL
        SELECT 5, dbo.hashPhone(@telefono5)
      ) AS phones
      WHERE hTel IS NOT NULL
    )
    SELECT
      MAX(CASE WHEN p.ord = 1 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList,
      MAX(CASE WHEN p.ord = 2 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList2,
      MAX(CASE WHEN p.ord = 3 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList3,
      MAX(CASE WHEN p.ord = 4 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList4,
      MAX(CASE WHEN p.ord = 5 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList5
    FROM Phones p
    LEFT JOIN (
      SELECT
        cn.Hashtel,
        cn.HashKey,
        cl.cam_id,
        1 AS match_flag
      FROM camplistanegra cl with(nolock)
      Inner JOIN cclistanegra  cn with(nolock) ON cn.idtipolista = cl.idtipolista AND (cn.HashKey IS NULL OR cn.HashKey = @hKey)
      WHERE cl.STATUS = 1
      and cl.cam_id = @cam_id
    ) m
      ON m.Hashtel  = p.hTel
end
else if @action =3 begin
    exec [ccsp_PhoneInBL] @action=6,@cam_id=@cam_id
    set @tableName = ''PhoneListTemp_'' + CAST(@cam_id AS VARCHAR);

    set @sql=''CREATE TABLE ''+@tableName+''(
        callout_id INT
        , hKey bigint
        , hTel bigint
        , ord int
        )
        CREATE NONCLUSTERED INDEX IX_''+@tableName+''_1 ON ''+@tableName+''(hTel, hKey);
        ''
    print(@sql)
    exec(@sql)
end
else if @action = 4 begin
    exec(@insertRow)
end

else if @action = 5 begin
    set @tableName = ''PhoneListTemp_'' + CAST(@cam_id AS VARCHAR);

    SET @sql = ''
    SELECT
        p.callout_id,
        MAX(CASE WHEN p.ord = 1 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList,
        MAX(CASE WHEN p.ord = 2 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList2,
        MAX(CASE WHEN p.ord = 3 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList3,
        MAX(CASE WHEN p.ord = 4 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList4,
        MAX(CASE WHEN p.ord = 5 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList5
    FROM '' + @tableName + '' p
    left join(SELECT cn.HashKey, cn.Hashtel,1 match_flag
        FROM camplistanegra cl WITH (NOLOCK)
        INNER JOIN cclistanegra cn WITH (NOLOCK)  ON cl.idtipolista = cn.idtipolista
        WHERE cl.status = 1 AND cl.cam_id = @cam_id
    )  m ON m.Hashtel = p.hTel AND (m.HashKey is null or m.HashKey = p.hKey)
    GROUP BY p.callout_id
    OPTION (RECOMPILE);
    '';
  --  print(@sql)
    EXEC sp_executesql @sql, N''@cam_id INT'', @cam_id = @cam_id;

end

else if @action = 6 begin
    set @tableName = ''PhoneListTemp_'' + CAST(@cam_id AS VARCHAR);

    set @sql = ''if exists( select * from sys.tables where name=''''''+@tableName+'''''') begin
    DROP TABLE ''+@tableName+''
end'';

    EXEC sp_executesql @sql;
end
'
    EXEC(@sql)


   SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_RecycleByDispositionOrResult]'
   SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RecycleByDispositionOrResult]
@Action SMALLINT = 0,
@cam_id SMALLINT = 0,
@result_id SMALLINT = 0,
@disposition_id SMALLINT = 0,
@subDisposition_id SMALLINT = 0
AS
BEGIN
    DECLARE @date DATE = CONVERT(VARCHAR,GETDATE(),23);
    DECLARE @count INT = 0;

    IF(@Action = 1) BEGIN --Count registers to recycle by Result
        SELECT DISTINCT COUNT(*) OVER() AS TotalRecords
        FROM ccoLogDials  ld WITH (NOLOCK)
        INNER JOIN ccoCallsOutSource cs WITH (NOLOCK) ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
        LEFT JOIN ccoWorkingTable wt WITH (NOLOCK) on cs.callout_id = wt.callout_id
        WHERE ld.fecha > @date
        AND cs.cal_status not in (0,1,7)
        AND ISNULL(ld.canBeRecycled, 1) = 1
        AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
        AND ld.tipoResDial_id = @result_id
        AND (wt.callout_id IS NULL OR wt.cal_status = 1)
        AND ld.cam_id = @cam_id
        GROUP BY ld.callout_id
        RETURN 0;
    END

    IF(@Action = 2) BEGIN --Count registers to recycle by Calif
        SELECT COUNT(DISTINCT co.callout_id) AS TotalRecords
        FROM ccoCallsOut co WITH (NOLOCK)
        INNER JOIN ccoCallsOutSource cs WITH (NOLOCK) ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
        LEFT JOIN ccoWorkingTable wt WITH (NOLOCK) on cs.callout_id = wt.callout_id
        WHERE co.cal_Inicio >= @date
        AND cs.cal_status not in (0,1,7)
        AND ISNULL(co.canBeRecycled, 1) = 1
        AND ISNULL(recycledByDisposition, 0) = 0
        AND co.calif_id = @disposition_id
        AND ISNULL(co.califSub_id, 0) <= 0
        AND cs.cam_id = @cam_id
        AND (wt.callout_id IS NULL OR wt.cal_status = 1)
        RETURN 0;
    END

    IF(@Action = 3) BEGIN --Count registers to recycle by CalifSub
        SELECT COUNT(DISTINCT co.callout_id) AS TotalRecords
        FROM ccoCallsOut co WITH (NOLOCK)
        INNER JOIN ccoCallsOutSource cs WITH (NOLOCK) ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
        LEFT JOIN ccoWorkingTable wt WITH (NOLOCK) on cs.callout_id = wt.callout_id
        WHERE co.cal_Inicio >= @date
        AND cs.cal_status not in (0,1,7)
        AND ISNULL(co.canBeRecycled, 1) = 1
        AND ISNULL(recycledByDisposition, 0) = 0
        AND co.calif_id = @disposition_id
        AND co.califSub_id = @subDisposition_id
        AND cs.cam_id = @cam_id
        AND (wt.callout_id IS NULL OR wt.cal_status = 1)
        RETURN 0;
    END

    IF(@Action = 4) BEGIN --Recycle registers to load by Result
        IF OBJECT_ID(''tempdb..#tmpCalloutIdResult'') IS NOT NULL DROP TABLE #tmpCalloutIdResult;

        CREATE TABLE #tmpCalloutIdResult (
            callout_id INT,
            Telefono VARCHAR(40),
            fecha DATETIME,
            RowFilter INT
        );

        INSERT INTO #tmpCalloutIdResult (callout_id, Telefono, fecha, RowFilter)
        SELECT ld.callout_id, ld.Telefono, ld.fecha,
        ROW_NUMBER() OVER (PARTITION BY ld.callout_id ORDER BY ld.fecha ASC) AS RowFilter
        FROM ccoLogDials ld WITH (NOLOCK)
        INNER JOIN ccoCallsOutSource cs WITH (NOLOCK) ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
        LEFT JOIN ccoWorkingTable wt WITH (NOLOCK) on cs.callout_id = wt.callout_id
        WHERE ld.fecha > @date
        AND cs.cal_status not in (0,1,7)
        AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
        AND ISNULL(ld.canBeRecycled, 1) = 1
        AND ld.tipoResDial_id = @result_id
        AND (wt.callout_id IS NULL OR wt.cal_status = 1)
        AND ld.cam_id = @cam_id
        GROUP BY ld.callout_id, ld.Telefono, ld.fecha

        DELETE wt
        FROM ccoWorkingTable wt WITH (ROWLOCK)
        INNER JOIN #tmpCalloutIdResult tc on wt.callout_id = tc.callout_id
        WHERE wt.cal_status = 1

        UPDATE cs WITH (ROWLOCK, UPDLOCK)
        SET cs.cal_status = 0, cs.recycledByResult = ISNULL(cs.recycledByResult, '''') + '','' +CONVERT(VARCHAR(2), @result_id),
        cs.recyclePhone = CASE
            WHEN tc.Telefono = cs.cal_telefono THEN 1
            WHEN tc.Telefono = cs.cal_telefono2 THEN 2
            WHEN tc.Telefono = cs.cal_telefono3 THEN 3
            WHEN tc.Telefono = cs.cal_telefono4 THEN 4
            ELSE 5 END,
        cs.recycleType = 0
        FROM ccoCallsOutSource cs
        INNER JOIN #tmpCalloutIdResult tc on cs.callout_id = tc.callout_id
        WHERE tc.RowFilter = 1

        UPDATE ld WITH (ROWLOCK, UPDLOCK)
        SET ld.canBeRecycled = 0
        FROM ccoLogDials ld
        INNER JOIN #tmpCalloutIdResult tc on ld.callout_id = tc.callout_id
        WHERE ld.fecha >= @date
        AND ld.tipoResDial_id = @result_id

        SELECT @count = COUNT(*) from #tmpCalloutIdResult

        EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

        DROP TABLE #tmpCalloutIdResult

        SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

        RETURN 0;
    END

    IF(@Action = 5) BEGIN --Recycle registers to load by Calif
        IF OBJECT_ID(''tempdb..#tmpCalloutId'') IS NOT NULL DROP TABLE #tmpCalloutId;
        CREATE TABLE #tmpCalloutId (callout_id INT);

        INSERT INTO #tmpCalloutId (callout_id)
        SELECT co.callout_id
        FROM ccoCallsOut co
        INNER JOIN ccoCallsOutSource cs WITH (NOLOCK) ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
        LEFT JOIN ccoWorkingTable wt WITH (NOLOCK) on cs.callout_id = wt.callout_id
        WHERE co.cal_Inicio >= @date
        AND cs.cal_status not in (0,1,7)
        AND ISNULL(co.canBeRecycled, 1) = 1
        AND ISNULL(recycledByDisposition, 0) = 0
        AND co.calif_id = @disposition_id
        AND ISNULL(co.califSub_id, 0) <= 0
        AND cs.cam_id = @cam_id
        AND (wt.callout_id IS NULL OR wt.cal_status = 1)
        GROUP BY co.callout_id

        UPDATE cs WITH (ROWLOCK, UPDLOCK)
        SET cs.cal_status = 0, cs.recycledByDisposition = 1, cs.recycleType = 1
        FROM ccoCallsOutSource cs
        INNER JOIN #tmpCalloutId tc on cs.callout_id = tc.callout_id

        UPDATE co WITH (ROWLOCK, UPDLOCK)
        SET co.canBeRecycled = 0
        FROM ccoCallsOut co
        INNER JOIN #tmpCalloutId tc on co.callout_id = tc.callout_id
        WHERE co.cal_Inicio >= @date

        DELETE wt
        FROM ccoWorkingTable wt WITH (ROWLOCK)
        INNER JOIN #tmpCalloutId tc on wt.callout_id = tc.callout_id
        WHERE wt.cal_status = 1

        SELECT @count = COUNT(*) from #tmpCalloutId

        EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

        DROP TABLE #tmpCalloutId

        SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

        RETURN 0;
    END

    IF(@Action = 6) BEGIN --Recycle registers by CalifSub
        IF OBJECT_ID(''tempdb..#tmpCalloutIdSub'') IS NOT NULL DROP TABLE #tmpCalloutIdSub;
        CREATE TABLE #tmpCalloutIdSub (callout_id INT);

        INSERT INTO #tmpCalloutIdSub (callout_id)

        SELECT co.callout_id
        FROM ccoCallsOut co WITH (NOLOCK)
        INNER JOIN ccoCallsOutSource cs WITH (NOLOCK) ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
        LEFT JOIN ccoWorkingTable wt WITH (NOLOCK) on cs.callout_id = wt.callout_id
        WHERE co.cal_Inicio >= @date
        AND cs.cal_status not in (0,1,7)
        AND ISNULL(co.canBeRecycled, 1) = 1
        AND ISNULL(recycledByDisposition, 0) = 0
        AND co.calif_id = @disposition_id
        AND co.califSub_id = @subDisposition_id
        AND cs.cam_id = @cam_id
        AND(wt.callout_id IS NULL OR wt.cal_status = 1)
        GROUP BY co.callout_id

        DELETE wt
        FROM ccoWorkingTable wt WITH (ROWLOCK)
        INNER JOIN #tmpCalloutIdSub tc on wt.callout_id = tc.callout_id
        WHERE wt.cal_status = 1

        UPDATE cs WITH (ROWLOCK, UPDLOCK)
        SET cs.cal_status = 0, cs.recycledByDisposition = 1, cs.recycleType = 1
        FROM ccoCallsOutSource cs
        INNER JOIN #tmpCalloutIdSub tc on cs.callout_id = tc.callout_id

        UPDATE co WITH (ROWLOCK, UPDLOCK)
        SET co.canBeRecycled = 0
        FROM ccoCallsOut co
        INNER JOIN #tmpCalloutIdSub tc on co.callout_id = tc.callout_id
        WHERE co.cal_Inicio >= @date

        SELECT @count = COUNT(*) from #tmpCalloutIdSub

        EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

        DROP TABLE #tmpCalloutIdSub

        SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

        RETURN 0;
    END
END'
       EXEC(@sql)

   SET @process = '#2543 ALTER PROCEDURE [dbo].[ccsp_RIA_mnuReciclar]'
       SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados /
--                3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings with(nolock) where setting_id = 60

If @Valor = 1
 begin
    declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
    select @Valor = valor from ccSettings with(nolock) where setting_id = 59

    If @Valor = 0
     begin
        select -2, ''No hay un limite para volver a reciclar''
        return(0)
     end

    select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

    -- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
    select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')

    exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id

    If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
    begin
        select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
        return(0)
    end

 end

if @type=0
 begin
    DECLARE @listName VARCHAR(255) = '''';
    create table #allReciycled(callout_id int not null primary key)

    if @list_id = 0 begin


        insert into #allReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_8),nolock) where cam_id = @cam_id and cal_status = 1


    end
    else begin

        insert into #allReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id

    end

    update ccoCallBacks with (ROWLOCK, UPDLOCK)
    set [status] = 3, schedulerStatus = 1
    from ccoCallBacks a with(index([IX_ccoCallBacks6]))
    inner join #allReciycled b on (a.callout_id = b.callout_id)
    where [status] = 0

    update ccoWorkingTable with (ROWLOCK, UPDLOCK)
    set cal_status = 0
    from ccoWorkingTable a
    inner join #allReciycled b on a.callout_id = b.callout_id

    drop table #allReciycled

    if @list_id = 0 begin
        select 1
    end
    else begin
        select 200 StatusCode, @listName ListName;
    end
 end

if @type in(1,3)
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
                         where cam_id = @cam_id
                         and cal_status = 1
                         and tiporesdial_id <> 1
                         and callout_id in (select distinct(b.callout_id)
                                                from ccologdials a with (index (IX_ccoLogDials_4),nolock)
                                                left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
                                                on a.callout_id = b.callout_id
                                                and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
                                                where calif_id = 0
                                                and calif_id is not null))
    and [status] = 0

    update ccoWorkingTable
    set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id
    and cal_status = 1
    and tiporesdial_id <> 1
    and callout_id in (select distinct(b.callout_id)
                           from ccologdials a with (index (IX_ccoLogDials_4),nolock)
                           left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
                           on a.callout_id = b.callout_id
                           and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
                           where calif_id = 0
                           and calif_id is not null)
 end

if @type in(2,3)
 begin

    Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
     ''where callout_id in ('' +
     ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
     ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
     ''and calif_id in ('' + @calif_id + ''))'' +
     ''and [status] = 0''

    exec(@SQL)

    Set @SQL = ''update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
     ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
     + -- and tiporesdial_id = 1 '' +
     ''and calif_id in ('' + @calif_id + '')''

    exec(@SQL)
 end

if @type = 4
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock)
                         where cam_id = @cam_id and cal_status = 3)
    and [status] = 0

    update ccoWorkingTable
  set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'
       EXEC(@sql)



SET @process = 'ALTER sp ccsp_RIAOUTInsertNewJOBS_WT_Camp Sears mejora en el proceso de carga';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
AS
SET NOCOUNT ON

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
DECLARE @campType AS INT
DECLARE @recordsQuantitySetting VARCHAR(8)
DECLARE @settingValueP1 VARCHAR(25)

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

        CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)
        --UPDATING TABLES BEFORE LOADING
        DECLARE @date datetime = GETDATE()
        UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
        UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

        INSERT INTO #smsoutIdSource
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK)
        on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id
        WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

        UNION

        SELECT top(@top) swt2.smsout_id
        FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id
        WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

        INSERT INTO #smsoutIdSource2
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

        INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone,
        iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
        SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         ''
        + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
            CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey,
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer,
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2,
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3,
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4,
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4,
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5,
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE
                    NULL END iTimeZone_summer5, list_id, sms_dateDialEnd, ISNULL(isSegmentLoad, 0)
        FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7)

        SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;


        IF EXISTS(SELECT * FROM #tempsmsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempsmsOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
               INSERT INTO dbo.smsWorkingTable  WITH (ROWLOCK)
                (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                SELECT t.smsout_id, t.cam_id, t.sms_phoneNumber, t.sms_status, t.sms_dateDial, 0, 0
                ,t.cal_keyw, t.iTimeZone, t.iTimeZone_summer, t.iTimeZone2, t.iTimeZone_summer2, t.iTimeZone3, t.iTimeZone_summer3
                , t.iTimeZone4, t.iTimeZone_summer4, t.iTimeZone5, t.iTimeZone_summer5, t.list_id,t.sms_dateDialEnd, t.isSegmentLoad
                FROM #tempsmsOutSource t
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                AND NOT EXISTS (
                    SELECT 1 FROM smsWorkingTable swt WHERE swt.smsout_id = t.smsout_id
                )

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.smsOutSource
            SET sms_status = 2
            FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
            WHERE sos.smsout_id = cis3.smsout_id
        END

        DROP TABLE #smsoutIdSource

        DROP TABLE #smsoutIdSource2

        DROP TABLE #tempsmsOutSource
END
ELSE IF(@campType = 5)
BEGIN
    CREATE TABLE #tempWhatsAppOutSource (Id INT PRIMARY KEY identity, WAOut_Id INT, CallKey VARCHAR(40), camId INT, PhoneNumber VARCHAR(30), Status INT, TimeZone int, TimeZone_Summer int, List_id INT, User_id SMALLINT, dateDial DATETIME)
    CREATE NONCLUSTERED INDEX [IX_TempWAO] ON [dbo].[#tempWhatsAppOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE TABLE #WAIdSource (WAOut_Id INT NOT NULL PRIMARY KEY)

    INSERT INTO #WAIdSource
    SELECT top(@top) cwaos.WAOut_Id
        FROM dbo.ccWhatsAppOutSource AS cwaos WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.Status IN (0) AND cwaos.camId = @camp_id

    INSERT INTO #tempWhatsAppOutSource
    (
        WAOut_Id,
        CallKey,
        camId,
        PhoneNumber,
        Status,
        TimeZone,
        TimeZone_Summer,
        List_id,
        User_id,
        dateDial
    )
        SELECT TOP(@top) cwaos.WAOut_Id, cwaos.CallKey,cwaos.camId, RTRIM(LEFT(LTRIM(cwaos.PhoneNumber + ''        '' ), 13)) AS phoneNumber,
            cwaos.Status AS WAStatus,
            CASE WHEN cwaos.TimeZone = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,0) ELSE cwaos.TimeZone END,
            CASE WHEN cwaos.TimeZone_Summer = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,1) ELSE cwaos.TimeZone_Summer END,
            list_id, cwaos.User_id, cwaos.dateDial
        FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.camId = @camp_id AND (cwaos.Status = 0)

    SELECT @rowstoInsert = COUNT(*) FROM #tempWhatsAppOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempWhatsAppOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempWhatsAppOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO dbo.ccoWAWorkingTable(WAOut_id, PhoneNumber, Callkey, CamId, WaStatus, dateDial, UserId,TimeZone, TimeZone_Summer)
                SELECT WAOut_Id, PhoneNumber, CallKey, camId, Status, dateDial , User_id, TimeZone ,TimeZone_Summer
                FROM #tempWhatsAppOutSource
                WHERE id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.ccWhatsAppOutSource
            SET
            Status = 2,
            TimeZone = cis3.TimeZone,
            TimeZone_Summer = cis3.TimeZone_Summer
            FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (NOLOCK), #tempWhatsAppOutSource  cis3 WITH (NOLOCK)
            WHERE cwaos.WAOut_Id = cis3.WAOut_Id
        END

        DROP TABLE #WAIdSource

        DROP TABLE #tempWhatsAppOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19),
        cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT,
        iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT,
        iZonaHoraria_verano5 INT, list_id INT, new_status int)

        CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

        INSERT INTO #calloutIdSource
        SELECT top(@top) cs.callout_id
        FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        inner join ccoWorkingTable wt WITH (INDEX (PK_ccoWorkingTable), NOLOCK)
        on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id
        WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

        UNION

        SELECT top(@top) Cout.callout_id
        FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
        inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id
        AND cout.cam_id = Wtab.cam_id
        WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)


        INSERT INTO #calloutIdSource2
        SELECT top(@top) callout_id
        FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
        WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

        IF exists(SELECT * FROM #calloutIdSource)
        BEGIN
            UPDATE ccoCallBacks
            SET [status] = 6, schedulerStatus = 1
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )

            UPDATE ccoCallsOutSource
            SET cal_Status = 4
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )
        END

        INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria,
        iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
            iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
        SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN
        CASE
            WHEN recyclePhone = 1 THEN cal_telefono
            WHEN recyclePhone = 2 THEN cal_telefono2
            WHEN recyclePhone = 3 THEN cal_telefono3
            WHEN recyclePhone = 4 THEN cal_telefono4
            else cal_telefono5
        END
        ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         ''
            + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13))
        END AS cal_telefono,
            CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key,
            CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
            CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano,
            CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
            CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2,
            CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3,
            CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
            CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4,
            CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4,
            CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5,
            CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE
                    NULL END iZonaHoraria_verano5, list_id
        FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

        IF EXISTS(SELECT * FROM #tempCallsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                 INSERT INTO ccoWorkingTable  WITH (ROWLOCK)
                (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT t.callout_id, t.cam_id, t.cal_telefono, t.cal_status, t.cal_fechaDial, t.cal_keyw,
                       t.iZonaHoraria, t.iZonaHoraria_verano, t.iZonaHoraria2, t.iZonaHoraria_verano2,
                       t.iZonaHoraria3, t.iZonaHoraria_verano3, t.iZonaHoraria4, t.iZonaHoraria_verano4,
                       t.iZonaHoraria5, t.iZonaHoraria_verano5, t.list_id
                FROM #tempCallsOutSource t
                WHERE t.id > @batchsizeIni AND t.id <= @batchsizeFin
                  AND NOT EXISTS (
                    SELECT 1 FROM ccoWorkingTable w WHERE w.callout_id = t.callout_id
                );


                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE ccoCallsOutSource
            SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
            FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
            WHERE co.callout_id = cis3.callout_id
        END

        DROP TABLE #calloutIdSource

        DROP TABLE #calloutIdSource2

        DROP TABLE #tempCallsOutSource
END

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF';
    EXEC(@sql);



SET @process = 'Alter SP ccsp_RIARegistryLists (se modifica action 6 para eliminar listas)'
    SET @sql = 'ALTER Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0,
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '''',
@status tinyint = 0,
@sequence smallint = 0,
@load_id int = 0,
@listIds VARCHAR(MAX) = '''',
@sequences VARCHAR(MAX) = ''''

AS

--Status lista 0: inactiva, 1:pausa, 2:procesar

--Insert
IF @action = 1 begin

    IF @cam_id <> 0 begin
        select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
        set @sequence = @sequence + 1
        Insert into ccRIARegistryLists(cam_id,name,status,sequence) values (@cam_id, @name, 2, @sequence)
        select max(list_id) from ccRIARegistryLists
    end
end

--Update sequence
IF @action = 2 begin

    declare @oldSeq as int
    select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

    if @oldSeq <> @sequence begin

        if @oldSeq > @sequence begin
            update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
        end

        if @oldSeq < @sequence begin
            update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
        end

        update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

    end

end

--Change status
IF @action = 3 begin

    update ccRIARegistryLists set status = @status where list_id = @list_id
    SELECT 200 as ReturnValue

end

-- lista campañas y listas de registros
IF @action = 4 begin
    select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame
    from ccRIARegistryLists a  with(nolock)
    left join cccamps b on a.cam_id = b.cam_id
    left join ccRIACampsGraph c on a.cam_id = c.cam_id
    where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists )
    group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

end

-- listas de registros y no. registros
IF @action = 5
begin
    select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence
    from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock)
    left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_13),nolock)
    on b.cam_id = @cam_id and a.list_id = b.list_id
    where a.status > 0 and a.cam_id = @cam_id and status > 0
    group by a.list_id,a.name,a.sequence
    order by a.sequence
end

-- borrar lista
IF @action = 6 begin
    DECLARE @listName Varchar(255);
    DECLARE @campaignStatus BIT;
    CREATE TABLE #DummyTable (Columna1 INT);

    select @cam_id = cam_id, @listName = name from ccRIARegistryLists where list_id = @list_id
    select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
    SELECT @campaignStatus = cam_procesando FROM ccCamps WHERE cam_id = @cam_id;

    IF @campaignStatus = 0
    BEGIN
        INSERT INTO #DummyTable
        exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id

        --delete new records in workingTable by camp_id and list_id
        delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0 AND list_id = @list_id

        --delete callbacks by camp_id and list_id
        delete from ccRIAUpdateCallBack_Abandon where callout_id in(
        SELECT callout_id from ccoWorkingTable with(nolock) where cam_id = @cam_id and cal_status = 1 AND list_id = @list_id)
        delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1 AND list_id = @list_id

        exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id
        SELECT 200 as StatusCode, @listName as ListName
    END
    ELSE
    BEGIN
        SELECT -8 as StatusCode,'''' as ListName
    END
end

-- Detalle de numero de registros
IF @action = 7 begin

    declare @total as int
    declare @countWorkingtable as int

    select @total = count(*) from ccocallsoutsource where list_id = @list_id
    select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

    if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
        select @status = status from ccRIARegistryLists where list_id = @list_id
        select @list_id as list_id,cast(cam_id as smallint) as cam_id, @status as status,
            count(case cal_status when 0 then 1 else null end) as New,
            count(case cal_status when 1 then 1 else null end) as CB,
            count(case cal_status when 2 then 1 else null end) as Pro,
            @total as Fin
        from ccoWorkingTable where list_id = @list_id group by cam_id
    end
    ELSE begin
        select list_id, cam_id, status,
        0 as New,
        0 as CB,
        0 as Pro,
        0 as Fin
        from ccRIARegistryLists where list_id = @list_id
    end


end

-- Cambia de nombre a la lista
IF @action = 8 begin

    update ccRIARegistryLists set name = @name where list_id = @list_id

end

-- Borra listas sin registros y reordena las listas
-- Actualizar orden de las listas ------------
IF @action = 9 begin


    DECLARE @list_Ids TABLE (i int, ListId int)
    insert @list_Ids select * from dbo.fn_RIASplitDelimited (@listIds, '','')

    DECLARE @list_sequence TABLE (i int, ListSecuence int)
    insert @list_sequence  select * from dbo.fn_RIASplitDelimited (@sequences, '','')


    declare @i int, @n int, @idList int, @secuence int
    select @i = 1 , @n = COUNT(ListId) from @list_Ids
    while (@i <= @n)
        begin
            select @secuence = ListSecuence from @list_sequence where i = @i
            select @idList = ListId from @list_Ids where i = @i
            update ccRIARegistryLists set sequence=@secuence where list_id=@idList
            set @i = @i + 1
        end
    select 1
end
IF @action = 10 begin
    select @cam_id=cam_id from ccRIARegistryLists where list_id=@list_id
    delete from ccoWorkingTable where cam_id=@cam_id and list_id=@list_id
end
    '
    EXEC(@sql)


SET @process = '#2154 ALTER PROCEDURE [dbo].[ccsp_smsOUTResetJobs]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_smsOUTResetJobs]
@camid AS INT= 0
AS
BEGIN

    CREATE TABLE #TempccoLogDials (
    smsout_id INT, PRIMARY KEY (smsout_id)
    );
    DECLARE @today DATETIME;

    SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);

    IF @camid = 0
    BEGIN
    INSERT INTO #TempccoLogDials
            SELECT  DISTINCT smsout_id
            FROM smsccoLogDial AS ld WITH(NOLOCK)
            WHERE smsDate >= @today
    END;
        ELSE
    IF @camid > 0
    BEGIN
        INSERT INTO #TempccoLogDials
            SELECT  DISTINCT smsout_id
            FROM smsccoLogDial AS ld WITH(NOLOCK)
            WHERE cam_id = @camid AND
                smsDate >= @today
    END;

    -- CALLBACKS Se han marcado recientemente
    WHILE 1=1
    BEGIN
        ;WITH cte AS (
            SELECT TOP (5000) wt.smsout_id
            FROM smsWorkingTable wt
            JOIN #TempccoLogDials ld ON wt.smsout_id = ld.smsout_id
            WHERE wt.sms_status = 2
        )
        UPDATE wt
        SET sms_status = 1
        FROM smsWorkingTable wt
        JOIN cte ON wt.smsout_id = cte.smsout_id;

        IF @@ROWCOUNT = 0 BREAK;
    END

    IF @camid = 0
    BEGIN
    -- NUEVAS - Nunca se han marcado
        WHILE 1=1
        BEGIN
            ;WITH cte AS (
                SELECT TOP (5000) smsout_id
                FROM smsWorkingTable
                WHERE sms_status = 2
            )
            UPDATE wt
            SET sms_status = 0
            FROM smsWorkingTable wt
            JOIN cte ON wt.smsout_id = cte.smsout_id;

            IF @@ROWCOUNT = 0 BREAK;
        END
    END;
    ELSE BEGIN
    -- NUEVAS - Nunca se han marcado
    UPDATE smsWorkingTable WITH(ROWLOCK)
        SET sms_status = 0
    WHERE sms_status = 2 AND
        cam_id = @camid;
    END;

    UPDATE c
    SET c.cam_procesando = 0
    FROM ccCamps c
    WHERE c.cam_id = @camid
    AND EXISTS (
    SELECT 1
    FROM ccSettings2
    WHERE setting_id = 258
        AND valor = 0
    );

    DROP TABLE #TempccoLogDials;
END;'
    EXEC(@sql)



    SET @process = 'SEARS DROP Procedure ccsp_UpdateCallsOutFromTempAction'
SET @Sql = 'IF EXISTS ( SELECT *
        FROM   sysobjects
        WHERE  id = object_id(N''[dbo].[ccsp_UpdateCallsOutFromTempAction]'')
               and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
BEGIN
DROP PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
END
'
EXEC (@Sql)


SET @process = 'SEARS DROP Procedure ccsp_UpdateSmsOutFromTempAction'
SET @Sql = 'IF EXISTS ( SELECT *
        FROM   sysobjects
        WHERE  id = object_id(N''[dbo].[ccsp_UpdateSmsOutFromTempAction]'')
               and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
BEGIN
DROP PROCEDURE [dbo].[ccsp_UpdateSmsOutFromTempAction]
END
'
EXEC (@Sql)




     SET @process = 'SEARS CREATE PROCEDURE dbo.ccsp_UpdateCallsOutFromTempAction Mejora proceso carga ZonasHorarias'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
    @action INT,
    @tableName NVARCHAR(255),
    @cal_status int = 0,
    @idLoad int=0,
    @motivo varchar(50)=null,
    @cam_id int=null,
    @isIAQuantumCamp bit =0,
    @internationalRecords int=0

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @paramDef NVARCHAR(300);
    DECLARE @count INT;
    declare @emtpy varchar(1)='''',@zipCodeSchedule bit
    declare @columnsIAQuntum varchar(max)=''''

    IF @action = 1
    BEGIN
        SET @sql = ''
        UPDATE '' + QUOTENAME(@tableName) + ''
        SET international = 1'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action = 2
    BEGIN

        if @isIAQuantumCamp =1 begin
            set @columnsIAQuntum='', data_api_quantum, data_overflow_variables_quantum''
        end

        SET @sql = ''
        INSERT INTO dbo.ccoCallsOutSource (
            cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
            Dato1, Dato2, Dato3, Dato4, Dato5,
            dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
            ,iZonaHoraria,iZonaHoraria_verano
            ,iZonaHoraria2,iZonaHoraria_verano2
            ,iZonaHoraria3,iZonaHoraria_verano3
            ,iZonaHoraria4,iZonaHoraria_verano4
            ,iZonaHoraria5,iZonaHoraria_verano5
            '' + @columnsIAQuntum + ''
        )
        SELECT
            cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
            Dato1, Dato2, Dato3, Dato4, Dato5,
            dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
            ,iZonaHoraria,iZonaHoraria_verano
            ,iZonaHoraria2,iZonaHoraria_verano2
            ,iZonaHoraria3,iZonaHoraria_verano3
            ,iZonaHoraria4,iZonaHoraria_verano4
            ,iZonaHoraria5,iZonaHoraria_verano5
            '' + @columnsIAQuntum + ''
        FROM '' + QUOTENAME(@tableName) + ''
        WHERE callout_id = 0'';

        EXEC sp_executesql @sql;
    END

    ELSE IF @action = 3
    BEGIN
        SET @sql = ''
        INSERT INTO dbo.ccoCallsPreviewData (
            cal_Key, cam_id, TotalData, Headers,
            Dato6, Dato7, Dato8, Dato9, Dato10,
            Dato11, Dato12, Dato13, Dato14, Dato15
        )
        SELECT
            cal_Key, cam_id, TotalData, Headers,
            Dato6, Dato7, Dato8, Dato9, Dato10,
            Dato11, Dato12, Dato13, Dato14, Dato15
        FROM '' + QUOTENAME(@tableName) + ''
        WHERE callout_id = 0;
        '';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action = 4
    BEGIN
        SET @sql = ''
        UPDATE C SET
            C.Headers = A.Headers,
            C.TotalData = A.TotalData,
            C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
            C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
        FROM '' + QUOTENAME(@tableName) + '' A
        INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
            ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
        '';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action =5
    BEGIN
        if @isIAQuantumCamp =1 begin
            set @columnsIAQuntum='', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum''
        end

        SET @sql = ''
        UPDATE C SET
            C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
            C.cal_telefono = A.cal_telefono,
            C.cal_telefono2 = A.cal_telefono2,
            C.cal_telefono3 = A.cal_telefono3,
            C.cal_telefono4 = A.cal_telefono4,
            C.cal_telefono5 = A.cal_telefono5,
            C.Dato1 = A.Dato1,
            C.Dato2 = A.Dato2,
            C.Dato3 = A.Dato3,
            C.Dato4 = A.Dato4,
            C.Dato5 = A.Dato5,
            C.dialPrefix = A.dialPrefix,
            C.list_id = A.list_id,
            C.cal_fechaDial = CASE WHEN A.callout_id = 0 THEN A.cal_fechaDial ELSE C.cal_fechaDial END,
            C.Region = A.Region,
            C.Localidad = A.Localidad,
            C.international = A.international,
            C.recycledByResult = @emtpy,
            C.recycledByDisposition = 0,
            C.recyclePhone = 0,
            C.recycleType = 1
            ,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
            ,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
            ,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
            ,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
            ,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
            '' + @columnsIAQuntum + ''
        FROM '' + QUOTENAME(@tableName) + '' A
        LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
        INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id'';

        SET @paramDef = N''@cal_status_param TINYINT, @emtpy varchar(1)'';
        EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @emtpy= @emtpy;
    END
    ELSE IF @action = 6
    BEGIN
        DECLARE @today DATE = CONVERT(DATE, GETDATE());

        SET @sql = ''
    UPDATE B
    SET B.list_id = A.list_id
    FROM '' + QUOTENAME(@tableName) + '' A
    INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
    INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
    WHERE B.list_id <> A.list_id;


      UPDATE ld WITH (ROWLOCK) SET ld.canBeRecycled = 0
      FROM '' + QUOTENAME(@tableName) + '' t
      LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
      INNER JOIN ccoLogDials ld WITH (ROWLOCK, UPDLOCK, INDEX(IX_LogDials_cam_tipo_fecha_callout)) ON ld.cam_id = t.cam_id and ld.callout_id = t.callout_id
      WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled=1 or ld.canBeRecycled is null);

      UPDATE co WITH (ROWLOCK) SET co.canBeRecycled = 0
      FROM '' + QUOTENAME(@tableName) + '' t
      LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
      INNER JOIN ccoCallsOut co WITH (ROWLOCK, UPDLOCK) ON co.callout_id = t.callout_id
      WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled=1 or co.canBeRecycled is null);
      '';
        --print(@sql)
        EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
    END
    ELSE IF @action = 7
    BEGIN

        -- Contar registros inválidos
        SET @sql = ''
        SELECT @cnt = COUNT(*)
        FROM '' + QUOTENAME(@tableName) + '' A
        LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
            ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
        WHERE B.callout_id IS NULL and A.callout_id > 0;'';

        EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

        -- Insertar en ccRIALogPhones los registros sin match
        SET @sql = ''
        INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
        SELECT @idLoad, A.cal_Key, @emtpy, 2, @motivo,@internationalRecords
        FROM '' + QUOTENAME(@tableName) + '' A
        LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
            ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
        WHERE B.callout_id IS NULL;'';

        EXEC sp_executesql @sql,
            N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
            @idLoad = @idLoad,
            @motivo = @motivo,
            @internationalRecords =@internationalRecords,
            @emtpy=@emtpy;

        -- Eliminar los registros sin match
        SET @sql = ''
        DELETE A
        FROM '' + QUOTENAME(@tableName) + '' A
        LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
            ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
        WHERE B.callout_id IS NULL;'';

        EXEC(@sql);

        -- Retornar el count como resultado
        SELECT @count AS RegistrosEliminados;
    END
    ELSE IF @action = 8
    BEGIN


        -- Contar total de registros antes del borrado
        SET @sql = ''
        SELECT @cnt = COUNT(*) FROM '' + QUOTENAME(@tableName) + '';'';

        EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

        -- Log en ccRIALogPhones todos los registros de la tabla temporal
        SET @sql = ''
        INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
        SELECT @idLoad, cal_Key, @emtpy, 2, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

        EXEC sp_executesql @sql,
                N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
            @idLoad = @idLoad,
            @motivo = @motivo,
            @internationalRecords =@internationalRecords,
            @emtpy=@emtpy;

        -- Eliminar todos los registros de la tabla temporal
        SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
        EXEC(@sql);

        -- Retornar el número de registros eliminados
        SELECT @count AS RegistrosEliminados;
    END
    ELSE IF @action = 9 BEGIN

        DECLARE @country TINYINT;
        SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
        if @country =1 begin
            select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id =@cam_id
        end
        if @zipCodeSchedule is null begin
            set @zipCodeSchedule=0
        end

        SET @sql = ''
    UPDATE T SET
        iZonaHoraria = CASE
            WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

        iZonaHoraria_verano = CASE
          WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

        iZonaHoraria2 = CASE
            WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

        iZonaHoraria_verano2 = CASE
          WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

        iZonaHoraria3 = CASE
            WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

        iZonaHoraria_verano3 = CASE
          WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

        iZonaHoraria4 = CASE
            WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

        iZonaHoraria_verano4 = CASE
          WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

        iZonaHoraria5 = CASE
            WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

        iZonaHoraria_verano5 = CASE
          WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
            WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
            ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

    FROM '' + QUOTENAME(@tableName) + '' T
    OUTER APPLY dbo.fnGetTimeZoneByZip(T.Dato1) AS Z
    ''
    EXEC sp_executesql @sql,
            N''@zipCodeSchedule bit,@country TINYINT,@emtpy varchar(1)'',
            @zipCodeSchedule = @zipCodeSchedule,
            @country = @country,
            @emtpy = @emtpy

    --print(@sql)
    END
    ELSE IF @action = 10
    BEGIN
        SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE callout_id = 0;'';
        EXEC sp_executesql @sql;
    END
     ELSE IF @action = 11 BEGIN

        SET @sql = ''
    UPDATE T SET
        international=@internationalRecords
    FROM '' + QUOTENAME(@tableName) + '' T
    ''
    EXEC sp_executesql @sql,
            N''@internationalRecords int'',
            @emtpy = @emtpy

    END


    ELSE
    BEGIN
        RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
        RETURN;
    END
END
'
    EXEC(@sql)



     SET @process = 'SEARS CREATE PROCEDURE dbo.ccsp_UpdateSmsOutFromTempAction Mejora proceso carga ZonasHorarias'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateSmsOutFromTempAction]
    @action INT,
    @tableName NVARCHAR(255),
    @sms_status int = 0,
    @idLoad int=0,
    @motivo varchar(50)=null,
    @DateStart varchar(50) = null,
    @DateEnd varchar(50) = null,
    @internationalRecords int=0

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @paramDef NVARCHAR(300);
    DECLARE @date datetime = getdate()
    declare @emtpy varchar(1)=''''

    IF @action = 1
    BEGIN
        SET @sql = ''INSERT INTO dbo.smsOutSource(callkey,sms_phoneNumber,sms_phoneNumber2,sms_phoneNumber3,sms_phoneNumber4,sms_phoneNumber5,
        data1,data2,data3,data4,data5,list_id,cam_id,Region,Localidad,sms_status,sms_dateDial,
        iTimeZone,iTimeZone_summer,iTimeZone2,iTimeZone_summer2,iTimeZone3,iTimeZone_summer3,iTimeZone4,iTimeZone_summer4,iTimeZone5,iTimeZone_summer5)
        select cal_Key,cal_telefono,cal_telefono2,cal_telefono3,cal_telefono4,cal_telefono5
        ,Dato1,Dato2,Dato3,Dato4,Dato5,list_id,cam_id,Region,Localidad,cal_status,cal_fechaDial
        ,iZonaHoraria,iZonaHoraria_verano
        ,iZonaHoraria2,iZonaHoraria_verano2
        ,iZonaHoraria3,iZonaHoraria_verano3
        ,iZonaHoraria4,iZonaHoraria_verano4
        ,iZonaHoraria5,iZonaHoraria_verano5
        from '' + QUOTENAME(@tableName) + '' where callout_id=0;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action = 2
    BEGIN
        SET @sql = N''
UPDATE A
SET A.cal_fechaDial = CASE
                         WHEN A.callout_id > 0 THEN B.sms_dateDial
                         ELSE @date
                      END
FROM '' + QUOTENAME(@tableName) + '' AS A
INNER JOIN smsOutSource AS B WITH (NOLOCK)
    ON A.callout_id = B.smsout_id;
'';
        SET @paramDef =  N''@date DATETIME'';
        EXEC sp_executesql @sql,@paramDef , @date = @date;
    END

    ELSE IF @action = 3
    BEGIN
        SET @sql = ''update C set C.sms_status = @sms_status,
C.sms_phoneNumber = A.cal_telefono,C.sms_phoneNumber2 = A.cal_telefono2,C.sms_phoneNumber3 = A.cal_telefono3,C.sms_phoneNumber4 = A.cal_telefono4,
C.sms_phoneNumber5 = A.cal_telefono5,
C.data1 = A.Dato1,C.data2 = A.Dato2,C.data3 = A.Dato3,C.data4 = A.Dato4,C.data5 = A.Dato5,
C.list_id = A.list_id,
C.sms_dateDial =  ''''''+@DateStart+'''''', C.sms_dateDialEnd =  ''''''+@DateEnd+'''''',
C.Region = A.Region,
C.Localidad = A.Localidad,
C.isSegmentLoad = 1
,C.iTimeZone=A.iZonaHoraria,C.iTimeZone_summer=A.iZonaHoraria_verano
,C.iTimeZone2=A.iZonaHoraria2,C.iTimeZone_summer2=A.iZonaHoraria_verano2
,C.iTimeZone3=A.iZonaHoraria3,C.iTimeZone_summer3=A.iZonaHoraria_verano3
,C.iTimeZone4=A.iZonaHoraria4,C.iTimeZone_summer4=A.iZonaHoraria_verano4
,C.iTimeZone5=A.iZonaHoraria5,C.iTimeZone_summer5=A.iZonaHoraria_verano5
from '' + QUOTENAME(@tableName) + '' A
left join dbo.smsWorkingTable  B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
inner join dbo.smsOutSource  C with(nolock) on A.callout_id=C.smsout_id
where B.smsout_id is null;'';

        SET @paramDef =   N''@sms_status int'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status;
    END
    ELSE IF @action = 4
    BEGIN
        SET @sql = ''update C set C.sms_status = @sms_status,
C.sms_phoneNumber = A.cal_telefono,C.sms_phoneNumber2 = A.cal_telefono2,C.sms_phoneNumber3 = A.cal_telefono3,C.sms_phoneNumber4 = A.cal_telefono4,
C.sms_phoneNumber5 = A.cal_telefono5,
C.data1 = A.Dato1,C.data2 = A.Dato2,C.data3 = A.Dato3,C.data4 = A.Dato4,C.data5 = A.Dato5,
C.list_id = A.list_id,
C.sms_dateDial =  A.cal_fechaDial,
C.Region = A.Region,
C.Localidad = A.Localidad
,C.isSegmentLoad = 0
from  '' + QUOTENAME(@tableName) + '' A
left join dbo.smsWorkingTable  B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
inner join dbo.smsOutSource  C with(nolock) on A.callout_id=C.smsout_id
where B.smsout_id is null;'';

        SET @paramDef =   N''@sms_status int'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status;
        print(@sql)

    END
    ELSE IF @action =5
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action =6
    BEGIN
        SET @sql = ''Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo,internationalRecords)
select @idLoad, A.cal_Key,@emtpy, 2, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;

delete A from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';

        SET @paramDef = N''@emtpy varchar(1),@idLoad int,@motivo varchar(50),@internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef,
        @emtpy=@emtpy,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;
    END

    ELSE IF @action =7
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';
Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo)
select @idLoad, A.cal_Key,@emtpy, 2, @motivo from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@emtpy varchar(1),@idLoad int,@motivo varchar(50)'';
        EXEC sp_executesql @sql, @paramDef, @emtpy = @emtpy,@idLoad=@idLoad,@motivo=@motivo;
    END
    ELSE IF @action = 8
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '' where callout_id=0;
delete from '' + QUOTENAME(@tableName) + '' where callout_id=0;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action =9
    BEGIN
        SET @sql = ''Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo,internationalRecords)
select @idLoad, A.cal_Key,@emtpy, 2, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@emtpy varchar(1),@idLoad int,@motivo varchar(50), @internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef,
        @emtpy=@emtpy,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;
    END
    ELSE IF @action = 10
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';'';
        EXEC sp_executesql @sql
    END
    ELSE IF @action = 11 BEGIN

        SET @sql = ''
    UPDATE T SET
        iZonaHoraria = CASE
            WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

        iZonaHoraria_verano = CASE
          WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

        iZonaHoraria2 = CASE
            WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

        iZonaHoraria_verano2 = CASE
          WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

        iZonaHoraria3 = CASE
            WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

        iZonaHoraria_verano3 = CASE
          WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

        iZonaHoraria4 = CASE
            WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

        iZonaHoraria_verano4 = CASE
          WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

        iZonaHoraria5 = CASE
            WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

        iZonaHoraria_verano5 = CASE
          WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

    FROM '' + QUOTENAME(@tableName) + '' T
    ''
    EXEC sp_executesql @sql,
            N''@emtpy varchar(1)'',
            @emtpy = @emtpy

    END


    ELSE
    BEGIN
        RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
        RETURN;
    END
END'
    EXEC(@sql)

    SET @process = 'K070104 Crear tabla variables Muñoz - Drop procedure xx_ObtieneAgenteVirtual'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''xx_ObtieneAgenteVirtual'')
        BEGIN
            DROP PROCEDURE dbo.xx_ObtieneAgenteVirtual
        END'
    EXEC(@sql);

    SET @process = 'K070104 Crear tabla variables Muñoz - CREATE procedure xx_ObtieneAgenteVirtual'
    SET @sql = 'CREATE PROCEDURE [dbo].[xx_ObtieneAgenteVirtual]
    @campaignId INT = NULL,
    @campType INT = NULL
    AS
    BEGIN
                SELECT
                cva.idAgent
                , ISNULL(cva.quantumAgentId,'''') AS QuantumAgentId
                , ISNULL(cva.location,'''') AS Location
                , ISNULL('''','''')  AS ProjectId
                , ISNULL(cva.voice,'''')  AS Voice
                , ISNULL(cva.scriptAgent, '''') AS ScriptAgent
                FROM dbo.ccVirtualAgent AS cva
                WHERE cva.idCampaign = @campaignId AND cva.campType = @campType;
    END'
    EXEC(@sql);

    SET @process = 'SEARS ALTER TRIGGER [dbo].[trigZonaHoraria] ZonasHorarias'
    SET @sql = 'ALTER TRIGGER [dbo].[trigZonaHoraria] ON [dbo].[ccoCallsOutSource]
FOR INSERT,UPDATE
AS
SET NOCOUNT ON
begin
declare @country as tinyint,@zipCodeSchedule bit
declare @tableCpZoneSchedule table(callout_id int primary key,iZonaHoraria int,iZonaHoraria_verano int)

select @country =convert(tinyint, valor) from ccSettings with(nolock) where setting_id = 104
if @country =1 begin
    select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id in(select top 1 cam_id from inserted)
end
if @zipCodeSchedule is null begin
    set @zipCodeSchedule=0
end

if @zipCodeSchedule = 1 begin

    insert into @tableCpZoneSchedule
    select cs.callout_id, inv.tz_id,v.tz_id
    from ccTimeZoneAreaCP zoneCp with(nolock)
    inner join inserted cs on zoneCp.ZipCode=cs.Dato1
    inner join ccTimeZones V on V.tz_offset=zoneCp.SummerTimeDifference
    inner join ccTimeZones inv on inv.tz_offset=zoneCp.WinterTimeDifference
end


if update(cal_telefono) begin
    update ccoCallsOutSource
    set iZonaHoraria =case  when i.cal_telefono ='''' then 0
        when cs.iZonaHoraria=0 or cs.cal_telefono<>i.cal_telefono then
                                case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono,0) end
                           else cs.iZonaHoraria end,

    iZonaHoraria_verano =case  when i.cal_telefono ='''' then 0
    when cs.iZonaHoraria_verano=0 or cs.cal_telefono<>i.cal_telefono then
                                    case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else dbo.fnGetTimeZone(cs.cal_telefono,1) end
                              else cs.iZonaHoraria_verano end
    from ccoCallsOutSource cs
    inner join inserted i
    left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
    on cs.callout_id = i.callout_id
end

if update(cal_telefono2) begin
    update ccoCallsOutSource
    set iZonaHoraria2 = case when i.cal_telefono2 ='''' then 0
                when cs.iZonaHoraria2=0 or cs.cal_telefono2<>i.cal_telefono2 then
                                    case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono2,0) end
                             else cs.iZonaHoraria2 end,

    iZonaHoraria_verano2 = case when i.cal_telefono2 ='''' then 0
    when cs.iZonaHoraria_verano2=0 or cs.cal_telefono2<>i.cal_telefono2 then
                                        case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else  dbo.fnGetTimeZone(cs.cal_telefono2,1) end
                                else cs.iZonaHoraria_verano2 end
    from ccoCallsOutSource cs
    inner join inserted i on cs.callout_id = i.callout_id
    left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id

end

if update(cal_telefono3) begin
    update ccoCallsOutSource
    set iZonaHoraria3 =  case when i.cal_telefono3 ='''' then 0
        when cs.iZonaHoraria3=0  or cs.cal_telefono3<>i.cal_telefono3 then
                                    case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono3,0) end
                              else cs.iZonaHoraria3 end,
    iZonaHoraria_verano3 = case when i.cal_telefono3 ='''' then 0
        when cs.iZonaHoraria_verano3=0 or cs.cal_telefono3<>i.cal_telefono3 then
                                        case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else  dbo.fnGetTimeZone(cs.cal_telefono3,1) end
                                else cs.iZonaHoraria_verano3 end
    from ccoCallsOutSource cs
    inner join inserted i on cs.callout_id = i.callout_id
    left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
end

if update(cal_telefono4) begin
    update ccoCallsOutSource
    set iZonaHoraria4 = case when i.cal_telefono4 ='''' then 0
    when cs.iZonaHoraria4=0  or cs.cal_telefono4<>i.cal_telefono4  then
                                    case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono4,0) end
                            else cs.iZonaHoraria4 end,
    iZonaHoraria_verano4 = case when i.cal_telefono4 ='''' then 0
    when cs.iZonaHoraria_verano4=0 or cs.cal_telefono4<>i.cal_telefono4 then
                                        case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else   dbo.fnGetTimeZone(cs.cal_telefono4,1) end
                                else cs.iZonaHoraria_verano4 end
    from ccoCallsOutSource cs
    inner join inserted i on cs.callout_id = i.callout_id
    left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
end

if update(cal_telefono5) begin
    update ccoCallsOutSource
    set iZonaHoraria5 = case when i.cal_telefono5 ='''' then 0
    when cs.iZonaHoraria5=0 or cs.cal_telefono5<>i.cal_telefono5  then
                                    case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono5,0) end
                            else cs.iZonaHoraria5 end,
    iZonaHoraria_verano5 = case when i.cal_telefono5 ='''' then 0
    when cs.iZonaHoraria_verano5=0  or cs.cal_telefono5<>i.cal_telefono5 then
                                        case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else   dbo.fnGetTimeZone(cs.cal_telefono5,1) end
                                else cs.iZonaHoraria_verano5 end
    from ccoCallsOutSource cs
    inner join inserted i on cs.callout_id = i.callout_id
    left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
end
end
'
    EXEC(@sql)

    SET @process = 'SEARS DISABLE TRIGGER [dbo].[trigZonaHoraria] se inserta en otro sp'
    SET @sql = 'DISABLE TRIGGER [dbo].[trigZonaHoraria]
ON [dbo].[ccoCallsOutSource];
'
    EXEC(@sql)

 	SET @process = 'DEV2-896 DROP SP xx_Inserta'
	SET @sql = 'IF OBJECT_ID(''dbo.xx_Inserta'',''P'') IS NOT NULL
    DROP PROCEDURE dbo.xx_Inserta;'
	EXEC(@sql)

	SET @process = 'DEV2-896 CREATE SP xx_Inserta'
	SET @sql = 'CREATE PROCEDURE [dbo].[xx_Inserta]
    @cal_key VARCHAR(20),
    @cal_telefono VARCHAR(19),
    @cal_telefono2 VARCHAR(19),
    @cal_telefono3 VARCHAR(19),
    @cal_telefono4 VARCHAR(19),
    @cal_telefono5 VARCHAR(19),
    @dato1 VARCHAR(255),
    @dato2 VARCHAR(255),
    @dato3 VARCHAR(255),
    @dato4 VARCHAR(255),
    @dato5 VARCHAR(255),
    @cam_id INT,
    @FCallBack SMALLDATETIME = '''',
    @cal_status TINYINT = 0,
    @User_id INT = 0,
    @dialPrefix VARCHAR(30) = ''''
AS
BEGIN
    DECLARE @calloutid INT;

    IF (@cal_status = 0)
        SET @FCallBack = GETDATE();

    DECLARE
        @z1 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono, 0) ELSE 0 END,
        @zv1 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono, 1) ELSE 0 END,

        @z2 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono2, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono2, 0) ELSE 0 END,
        @zv2 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono2, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono2, 1) ELSE 0 END,

        @z3 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono3, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono3, 0) ELSE 0 END,
        @zv3 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono3, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono3, 1) ELSE 0 END,

        @z4 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono4, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono4, 0) ELSE 0 END,
        @zv4 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono4, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono4, 1) ELSE 0 END,

        @z5 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono5, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono5, 0) ELSE 0 END,
        @zv5 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono5, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono5, 1) ELSE 0 END;

    INSERT INTO dbo.ccoCallsOutSource (
        cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
        dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id, dialPrefix,
        iZonaHoraria, iZonaHoraria_verano,
        iZonaHoraria2, iZonaHoraria_verano2,
        iZonaHoraria3, iZonaHoraria_verano3,
        iZonaHoraria4, iZonaHoraria_verano4,
        iZonaHoraria5, iZonaHoraria_verano5
    )
    VALUES (
        @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5,
        @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id, @dialPrefix,
        @z1, @zv1, @z2, @zv2, @z3, @zv3, @z4, @zv4, @z5, @zv5
    );

    SELECT @calloutid = SCOPE_IDENTITY();
    SELECT @calloutid;
END'
	EXEC(@sql)

	SET @process = 'DEV2-896 DROP SP xx_Actualiza'
	SET @sql = 'IF OBJECT_ID(''dbo.xx_Actualiza'',''P'') IS NOT NULL
    DROP PROCEDURE dbo.xx_Actualiza;'
	EXEC(@sql)

	SET @process = 'DEV2-896 CREATE SP xx_Actualiza'
	SET @sql = 'CREATE PROCEDURE [dbo].[xx_Actualiza]
    @callout_id INT,
    @cal_telefono VARCHAR(19),
    @cal_telefono2 VARCHAR(19),
    @cal_telefono3 VARCHAR(19),
    @cal_telefono4 VARCHAR(19),
    @cal_telefono5 VARCHAR(19),
    @dato1 VARCHAR(255),
    @dato2 VARCHAR(255),
    @dato3 VARCHAR(255),
    @dato4 VARCHAR(255),
    @dato5 VARCHAR(255),
    @dialPrefix VARCHAR(30) = ''''
AS
BEGIN
    DECLARE
        @z1 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono, 0) ELSE 0 END,
        @zv1 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono, 1) ELSE 0 END,

        @z2 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono2, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono2, 0) ELSE 0 END,
        @zv2 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono2, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono2, 1) ELSE 0 END,

        @z3 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono3, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono3, 0) ELSE 0 END,
        @zv3 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono3, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono3, 1) ELSE 0 END,

        @z4 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono4, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono4, 0) ELSE 0 END,
        @zv4 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono4, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono4, 1) ELSE 0 END,

        @z5 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono5, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono5, 0) ELSE 0 END,
        @zv5 INT = CASE WHEN LTRIM(RTRIM(ISNULL(@cal_telefono5, ''''))) <> '''' THEN dbo.fnGetTimeZone(@cal_telefono5, 1) ELSE 0 END;

    UPDATE dbo.ccoCallsOutSource
    SET
        cal_telefono = @cal_telefono,
        cal_telefono2 = @cal_telefono2,
        cal_telefono3 = @cal_telefono3,
        cal_telefono4 = @cal_telefono4,
        cal_telefono5 = @cal_telefono5,
        dato1 = @dato1,
        dato2 = @dato2,
        dato3 = @dato3,
        dato4 = @dato4,
        dato5 = @dato5,
        dialPrefix = @dialPrefix,
        cal_fechaDial = GETDATE(),
        cal_status = 0,
        iZonaHoraria = @z1,
        iZonaHoraria_verano = @zv1,
        iZonaHoraria2 = @z2,
        iZonaHoraria_verano2 = @zv2,
        iZonaHoraria3 = @z3,
        iZonaHoraria_verano3 = @zv3,
        iZonaHoraria4 = @z4,
        iZonaHoraria_verano4 = @zv4,
        iZonaHoraria5 = @z5,
        iZonaHoraria_verano5 = @zv5
    WHERE callout_id = @callout_id;
END'
	EXEC(@sql)

	SET @process = 'DEV2-896 DROP SP ccsp_SetTimeZonesForLoadTable'
	SET @sql = 'IF OBJECT_ID(''dbo.ccsp_SetTimeZonesForLoadTable'',''P'') IS NOT NULL
    DROP PROCEDURE dbo.ccsp_SetTimeZonesForLoadTable;'
	EXEC(@sql)

	SET @process = 'DEV2-896 CREATE SP ccsp_SetTimeZonesForLoadTable'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_SetTimeZonesForLoadTable]
    @loadTable NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX)

    SET @sql = ''
    UPDATE T SET
        iZonaHoraria = CASE
            WHEN (cal_telefono IS NOT NULL AND LTRIM(RTRIM(cal_telefono)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono, 0)
            ELSE 0 END,

        iZonaHoraria_verano = CASE
            WHEN (cal_telefono IS NOT NULL AND LTRIM(RTRIM(cal_telefono)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono, 1)
            ELSE 0 END,

        iZonaHoraria2 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono2)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono2, 0)
            ELSE 0 END,

        iZonaHoraria_verano2 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono2)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono2, 1)
            ELSE 0 END,

        iZonaHoraria3 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono3)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono3, 0)
            ELSE 0 END,

        iZonaHoraria_verano3 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono3)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono3, 1)
            ELSE 0 END,

        iZonaHoraria4 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono4)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono4, 0)
            ELSE 0 END,

        iZonaHoraria_verano4 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono4)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono4, 1)
            ELSE 0 END,

        iZonaHoraria5 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono5)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono5, 0)
            ELSE 0 END,

        iZonaHoraria_verano5 = CASE
            WHEN (LTRIM(RTRIM(cal_telefono5)) <> '''''''')
            THEN dbo.fnGetTimeZone(cal_telefono5, 1)
            ELSE 0 END
    FROM '' + QUOTENAME(@loadTable) + '' T;
    ''

    EXEC sp_executesql @sql
END'
	EXEC(@sql)

    --Begin Vladimir CW-9896--

	SET @process = 'CW-9896 DROP SP ccsp_RIALogPhones'
	SET @sql = 'IF OBJECT_ID(''dbo.ccsp_RIALogPhones'',''P'') IS NOT NULL
    DROP PROCEDURE dbo.ccsp_RIALogPhones;'
	EXEC(@sql)

	SET @process = 'CW-9896 CREATE SP ccsp_RIALogPhones'
	SET @sql = 'CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON


		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int, @LoadBySegment varchar(1)
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int
		SELECT @LoadBySegment = CAST(ISNULL(LoadBySegment,''0'') as varchar) from ccRIALoading where load_id = @load_id
		IF(@option = 0)
		BEGIN
			select CAST(@LoadBySegment as bit) as LoadBySegment
			return 0;
		END

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)
		if @nType like ''%____1%'' --Record Not Loaded
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,8)
			''

		if @nType like ''%___1_%''--Number Not Loaded
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,8)
			''

		if @nType like ''%__1__%''--Record Blocked
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov IN (1)
			''

		if @nType like ''%_1___%''--Number blocked
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov IN (1,4)
			''

		if @nType like ''%1____%''--Record Updated
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp
		where crlp.load_id = @load_id and (''
		+ ISNULL(STUFF(@CaseType,CHARINDEX(''or'',@CaseType),LEN(''or''),''''),'''') +'')) tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);

				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE
				BEGIN
						IF(@isKolob = 1)
						BEGIN

						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''


						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key,
							CASE
								WHEN ISNULL(crlp.telefono, '''''''') = '''''''' THEN ''''''''
								WHEN crlp.internationalRecords = 0 THEN ''''N-'''' + REPLACE(crlp.telefono, ''''E_'''', '''''''')
								ELSE ''''I-'''' + REPLACE(crlp.telefono, ''''E_'''', '''''''')
							END AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE
								crlp2.descTipoMov
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile,
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A''''
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.keyTranslate is not null THEN tlan.translate
							ELSE crlp.motivo END AS motivo,
							CAST('' + @LoadBySegment + '' as BIT) AS LoadBySegment
							from ccRIALogPhones AS crlp
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id ''
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +''
							)
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key,
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id ''
				+ @CaseType
			END
			--PRINT(@sql);


			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
		return(0)
		END
		set nocount OFF'
	EXEC(@sql)

    -- END CW-9896 Vladimir --

	-------------------------------------------------------------------- Begin K020039 MAGV ------------------------------------------------------------------
		SET @process = 'K020039 drop function fn_GetMessagesByConversationOrMessageId'
		SET @sql = 'if exists (select * from sys.objects where
		object_id = OBJECT_ID(N''fn_GetMessagesByConversationOrMessageId'')
		and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
		begin
			Drop function fn_GetMessagesByConversationOrMessageId
		end'
		EXEC(@sql)

		SET @process = 'K020039 CREATE function fn_GetMessagesByConversationOrMessageId'
		SET @sql = 'CREATE FUNCTION [dbo].[fn_GetMessagesByConversationOrMessageId]
				(
					@CampType INT,                           -- Parameter to select the table (0 = Inbound, 1 = Outbound)
					@conversationId INT = NULL,              -- Optional parameter for filtering by conversationId
					@messageIdList NVARCHAR(MAX) = NULL      -- Optional parameter for filtering by a list of messageIds
				)
				RETURNS @Messages TABLE
				(
					MessageId VARCHAR(150),
					Status VARCHAR(50),
					Origin VARCHAR(50),
					OriginType INT,
					Timestamp DATETIME,
					Content NVARCHAR(MAX),
					Type VARCHAR(20),
					Caption VARCHAR(MAX),
					Url VARCHAR(MAX),
					FileSize VARCHAR(20),
					FileName VARCHAR(MAX),
					Address VARCHAR(MAX),
					Lat VARCHAR(MAX),
					Long VARCHAR(MAX),
					Name VARCHAR(MAX),
					LocationURL VARCHAR(MAX),
					userAgent VARCHAR(50)
				)
				AS
				BEGIN


					DECLARE @tmpMessageConversations TABLE(
							[messageId] VARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
							[conversationId] INT NOT NULL,
							[timeStampMessage] DATETIME NOT NULL,
							[originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
							[price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
							[messageIdUi] INT NULL,
							[currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							[typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							[content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							[clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							[vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							[timeStampMessageUTC] DATETIME NULL,
							[messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
							[userAgent] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
						);
					DECLARE @baseFilePath VARCHAR(MAX)
					SELECT @baseFilePath = valor FROM ccSettings WHERE setting_id = 230

					IF (@CampType = 0)
					BEGIN
						INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus, userAgent)
						SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus, ISNULL(AgentLogin,'''')
						FROM ccWAMessagesConversations
						WHERE
						(@messageIdList IS NULL OR messageId IN (SELECT value FROM dbo.fn_RIASplitDelimited(@messageIdList, '','')))
						AND
						(@conversationId IS NULL OR conversationId = @conversationId)
					END
					IF (@CampType = 1)
					BEGIN
						INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus, userAgent)
						SELECT messageId, conversationId, timeStampMessage AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus, ISNULL(AgentLogin,'''')
						FROM ccWAMessagesConversationsOut
						WHERE
						(@messageIdList IS NULL OR messageId IN (SELECT value FROM dbo.fn_RIASplitDelimited(@messageIdList, '','')))
						AND
						(@conversationId IS NULL OR conversationId = @conversationId)
					END

					INSERT INTO @Messages
					SELECT
						messageId AS MessageId,
						messageStatus AS Status,
						originType AS Origin,
						CASE
							WHEN originType =''Client'' THEN 3
							WHEN originType =''Agent'' THEN 2
							WHEN originType =''Admin'' THEN 1
							ELSE 0
						END AS OriginType,
						timeStampMessage AS [Timestamp],
						CASE
							WHEN typeMessage IN (''text'', ''template'') THEN content
							ELSE ''''
						END AS Content,
						typeMessage AS Type,
						CASE
							WHEN originType = ''Client''
							THEN
								CASE
									WHEN typeMessage = ''file''
									THEN
										CASE
											WHEN NOT EXISTS (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
											THEN ''''
											ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
										END
									WHEN typeMessage IN (''image'', ''video'')
									THEN
										CASE
											WHEN NOT EXISTS(SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4) -- soporte con mensajes de vonage
											THEN content
											WHEN NOT EXISTS (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2) -- cuando no tiene caption
											THEN ''''
											ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
										END
									ELSE ''''
								END
							WHEN (originType = ''Agent'' OR originType = ''Admin'')
							THEN
								CASE
									WHEN typeMessage = ''file''
									THEN
										CASE
											WHEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2) <> (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
											THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
											ELSE ''''
										END
									WHEN typeMessage IN (''image'', ''video'')
									THEN
										CASE
											WHEN NOT EXISTS(SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4) -- soporte con mensajes de vonage
											THEN ''''
											WHEN NOT EXISTS (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2) -- cuando no tiene caption
											THEN ''''
											ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
										END
									ELSE ''''
								END
						END AS Caption,
						CASE
							WHEN originType = ''Client'' THEN
								CASE
									WHEN
										(typeMessage = ''text''
										OR typeMessage = ''location''
										OR (typeMessage = ''file''
											AND
											(SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2) = '''' )
										)
									THEN ''''
									WHEN typeMessage = ''file''
									THEN (SELECT SUBSTRING(value, 5, LEN(value)) FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 2)
									WHEN typeMessage IN (''image'', ''video'')
									THEN
										CASE
											WHEN NOT EXISTS(SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4) -- soporte con mensajes de vonage
											THEN (@baseFilePath + CHAR(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + CHAR(92) + CAST(conversationId/1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + CHAR(92) + typeMessage + CHAR(92) + messageId + CASE WHEN typeMessage = ''video'' THEN ''.mp4'' WHEN typeMessage = ''image'' THEN ''.jpg'' END)
											ELSE (SELECT SUBSTRING(value, 5, LEN(value)) FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 2)
										END
									WHEN typeMessage = ''audio''
									THEN
										CASE
											WHEN content = ''''
											THEN (@baseFilePath + CHAR(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + CHAR(92) + CAST(conversationId/1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + CHAR(92) + typeMessage + CHAR(92) + messageId + ''.mp3'')
											ELSE content
										END
									ELSE ''''
								END
							WHEN (originType = ''Agent'' OR originType = ''Admin'') THEN
								CASE
									WHEN typeMessage IN (''text'', ''location'', ''template'') THEN ''''
									WHEN typeMessage  = ''file'' THEN (SELECT SUBSTRING(Value, 5, LEN(Value)) FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2)
									WHEN typeMessage IN (''image'', ''video'')
									THEN
										CASE
											WHEN NOT EXISTS(SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4)
											THEN content
											ELSE (SELECT SUBSTRING(Value, 5, LEN(Value)) FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2)
										END
									WHEN typeMessage = ''audio'' THEN content
								END
						END AS [Url],
						CASE
							WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2)
							WHEN typeMessage IN (''image'', ''video'')
							THEN
								CASE
									WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2) = 0 -- soporte con mensajes de vonage
									THEN ''''
									ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2)
								END
							ELSE ''''
						END AS [FileSize],
						CASE
							WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
							WHEN typeMessage IN (''image'', ''video'')
							THEN
								CASE
									WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2) = 0 -- soporte con mensajes de vonage
									THEN ''''
									ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
								END
							ELSE ''''
						END AS [FileName],
						CASE
							WHEN
								typeMessage = ''location''
							THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
							ELSE ''''
						END AS [Address],
						CASE
							WHEN
								typeMessage = ''location''
							THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2)
							ELSE ''''
						END AS [Lat],
						CASE
							WHEN
								typeMessage = ''location''
							THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2)
							ELSE ''''
						END AS [Long],
						CASE
							WHEN
								typeMessage = ''location''
							THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
							ELSE ''''
						END AS [Name],
						CASE
							WHEN
								typeMessage = ''location''
							THEN
								(''https://www.google.com/maps/search/'' +
								(SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2) + '','' +
								(SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2))
							ELSE ''''
						END AS [LocationURL],
						userAgent
					FROM @tmpMessageConversations
					ORDER BY Timestamp ASC

					RETURN;
				END
				'
		EXEC(@sql)
	-------------------------------------------------------------------- END K020039 MAGV ------------------------------------------------------------------
	------------------------------------------------BEGIN MACL-----------------------------------------------

	SET @process = 'K066015 - Se agregan estados de la conversación a la opción 6'
	SET @sql = '    ALTER PROCEDURE [dbo].[ccsp_WhatsAppConversationHistory]
    @Option smallint = null,
    @agentId smallint = null,
    @From datetime = null,
    @To datetime = null,
    @InboundIdsLst varchar(max) = null,
    @OutboundIdsLst varchar(max) = null,
    @ClientNumbersLst varchar(max) = null,
    @MaxConversationHistory smallint = null,
    @ConversationIndex smallint = null,
    @ConversationId int = null,
    @ConversationIds  varchar(max) = null,
    @CamType bit = null,
    @CamId int = null,
    @ActualTime dateTime = null,
    @CamNumber varchar(max) = null,
    @ClientNumber varchar(max) = null,
    @AgentsIdsLst varchar(max) = null,
    @StatusLst varchar(max) = null

    AS
    BEGIN
        DECLARE @MaxConversationHistoryTime INT = NULL;
        DECLARE @MaxDaysPerWAConvo INT = NULL;
        DECLARE @FinalMaxValue INT = NULL;
        DECLARE @combinedCampsIn VARCHAR(MAX) = ''''
        DECLARE @combinedCampsOut VARCHAR(MAX) = ''''
        DECLARE @combinedInboundNames VARCHAR(MAX) = ''''
        DECLARE @combinedOutboundNames VARCHAR(MAX) = ''''

    IF @Option = 0 -- Obtiene filtros para agente
    BEGIN
        SELECT
            @combinedCampsIn = ISNULL(STUFF((
                SELECT '','' + CAST(i.inbound_id AS VARCHAR)
                FROM ccInboundAgentes ia
                INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
                WHERE ia.user_id = @agentId AND i.chat = 5
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),

            @combinedInboundNames = ISNULL(STUFF((
                SELECT '','' + i.descripcion
                FROM ccInboundAgentes ia
                INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
                WHERE ia.user_id = @agentId AND i.chat = 5
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

        SELECT
            @combinedCampsOut = ISNULL(STUFF((
                SELECT '','' + CAST(c.cam_id AS VARCHAR)
                FROM ccCampsAgente ca
                INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
                WHERE ca.user_id = @agentId AND c.CampType = 5
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),

            @combinedOutboundNames = ISNULL(STUFF((
                SELECT '','' + c.cam_descripcion
                FROM ccCampsAgente ca
                INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
                WHERE ca.user_id = @agentId AND c.CampType = 5
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

        IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
        BEGIN
            IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
            CREATE TABLE #TmpInboundIds (Id INT);
            INSERT INTO #TmpInboundIds (Id)
            SELECT CAST(value AS INT)
            FROM dbo.fn_RIASplitDelimited(@combinedCampsIn, '','');
            SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
            FROM ccInbound i
            INNER JOIN #TmpInboundIds tmp ON tmp.Id = i.inbound_id;
            IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
        END

        IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
        BEGIN
            IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
            CREATE TABLE #TmpOutboundIds (Id INT);
            INSERT INTO #TmpOutboundIds (Id)
            SELECT CAST(value AS INT)
            FROM dbo.fn_RIASplitDelimited(@combinedCampsOut, '','');
            SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
            FROM contactMeanOut cmo
            INNER JOIN #TmpOutboundIds tmp ON tmp.Id = cmo.camp_id;
            IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
        END

        SET @FinalMaxValue =
            CASE
                WHEN @MaxConversationHistoryTime IS NULL THEN ISNULL(@MaxDaysPerWAConvo, 0)
                WHEN @MaxDaysPerWAConvo IS NULL THEN ISNULL(@MaxConversationHistoryTime, 0)
                ELSE CASE
                    WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
                    ELSE @MaxDaysPerWAConvo
                END
            END;

        SELECT
            ISNULL(@combinedCampsIn, '''') AS InboundIdsLst,
            ISNULL(@combinedInboundNames, '''') AS InboundNamesLst,
            ISNULL(@combinedCampsOut, '''') AS OutboundIdsLst,
            ISNULL(@combinedOutboundNames, '''') AS OutboundNamesLst,
            ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;
        END
    END

    IF @Option = 1 -- Obtiene filtros de campañas para admin
    BEGIN
        DECLARE @campsIn VARCHAR(MAX) = ''''
        DECLARE @InboundNames VARCHAR(MAX) = ''''
        DECLARE @OutboundNames VARCHAR(MAX) = ''''
        DECLARE @campsOut VARCHAR(MAX) = ''''

        DECLARE @ClientIds VARCHAR(MAX) = ''''
        DECLARE @count INT
        DECLARE @id INT
        DECLARE @wg INT

        IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL
            DROP TABLE #AgentsRelations;

        SELECT ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
                IDWG, @campsIn AS campsIn, @campsOut AS campsOut,
                @InboundNames AS InboundNames, @OutboundNames AS OutboundNames
        INTO #AgentsRelations
        FROM ccRIAAreaWorkGroup wg
        WHERE EXISTS (
            SELECT 1
            FROM ccRIAWorkGroupUsers wgu
            WHERE wgu.IDWG = wg.IDWG
                AND wgu.user_id = @agentId
        );

        SELECT @count = COUNT(idWG) FROM #AgentsRelations;
        SET @id = 1;

        WHILE @id <= @count
        BEGIN
            SELECT @wg = idwg FROM #AgentsRelations WHERE Row = @id;

            SET @campsIn = '''';
            SET @campsOut = '''';
            SET @InboundNames = '''';
            SET @OutboundNames = '''';

            SELECT @campsIn = ISNULL(@campsIn + CASE WHEN @campsIn = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), inbound_id), @campsIn)
            FROM ccInbound i
            INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
            WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
            ORDER BY inbound_id;

            SELECT @campsOut = ISNULL(@campsOut + CASE WHEN @campsOut = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), cam_id), @campsOut)
            FROM ccCamps c
            INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
            WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
            ORDER BY cam_id;

            SELECT @InboundNames = ISNULL(@InboundNames + CASE WHEN @InboundNames = '''' THEN '''' ELSE '','' END + i.descripcion, @InboundNames)
            FROM ccInbound i
            WHERE i.Inbound_id IN (
                SELECT inbound_id FROM ccInbound
                INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
                WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
            )
            ORDER BY i.Inbound_id;

            SELECT @OutboundNames = ISNULL(@OutboundNames + CASE WHEN @OutboundNames = '''' THEN '''' ELSE '','' END + c.cam_descripcion, @OutboundNames)
            FROM ccCamps c
            WHERE c.cam_id IN (
                SELECT cam_id FROM ccCamps
                INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
                WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
            )
            ORDER BY c.cam_id;

            IF @campsIn IS NOT NULL AND @campsIn <> ''''
                SET @combinedCampsIn = ISNULL(@combinedCampsIn + CASE WHEN @combinedCampsIn = '''' THEN '''' ELSE '','' END + @campsIn, @combinedCampsIn);

            IF @campsOut IS NOT NULL AND @campsOut <> ''''
                SET @combinedCampsOut = ISNULL(@combinedCampsOut + CASE WHEN @combinedCampsOut = '''' THEN '''' ELSE '','' END + @campsOut, @combinedCampsOut);

            IF @InboundNames IS NOT NULL AND @InboundNames <> ''''
                SET @combinedInboundNames = ISNULL(@combinedInboundNames + CASE WHEN @combinedInboundNames = '''' THEN '''' ELSE '','' END + @InboundNames, @combinedInboundNames);

            IF @OutboundNames IS NOT NULL AND @OutboundNames <> ''''
                SET @combinedOutboundNames = ISNULL(@combinedOutboundNames + CASE WHEN @combinedOutboundNames = '''' THEN '''' ELSE '','' END + @OutboundNames, @combinedOutboundNames);

            SET @id = @id + 1;
        END

        IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
        BEGIN
            IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;

            CREATE TABLE #TmpInboundIds2 (Id INT);
            INSERT INTO #TmpInboundIds2 (Id)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@combinedCampsIn, '','');

            SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
            FROM ccInbound i
            INNER JOIN #TmpInboundIds2 tmp ON tmp.Id = i.Inbound_id;

            IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;
        END

        IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
        BEGIN
            IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;

            CREATE TABLE #TmpOutboundIds2 (Id INT);
            INSERT INTO #TmpOutboundIds2 (Id)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@combinedCampsOut, '','');

            SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
            FROM contactMeanOut cmo
            INNER JOIN #TmpOutboundIds2 tmp ON tmp.Id = cmo.camp_id;

            IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;
        END

        SET @FinalMaxValue = CASE
            WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
            WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
            ELSE CASE
                WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
                ELSE @MaxDaysPerWAConvo
            END
        END;

        SELECT
            @combinedCampsIn AS InboundIdsLst,
            @combinedInboundNames AS InboundNamesLst,
            @combinedCampsOut AS OutboundIdsLst,
            @combinedOutboundNames AS OutboundNamesLst,
            ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;

        IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL
            DROP TABLE #AgentsRelations;
        END

    IF @Option = 2 -- Obtiene agentes tomando en cuenta filtros de Inbound, Outbound, o Client Numbers
    BEGIN
        DECLARE @AgentIds VARCHAR(MAX) = '''';
        DECLARE @AgentLogins VARCHAR(MAX) = '''';
        DECLARE @AgentNames VARCHAR(MAX) = '''';
        DECLARE @AgentStatusList VARCHAR(MAX) = '''';
        DECLARE @CampType SMALLINT = 0;
        IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
        CREATE TABLE #TmpCampAgentWg (Id INT);

        IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
        BEGIN
            INSERT INTO #TmpCampAgentWg (Id)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
        END

        IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
        BEGIN
            INSERT INTO #TmpCampAgentWg (Id)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
            SET @CampType = 1;
        END

        IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
        BEGIN
            INSERT INTO #TmpCampAgentWg (Id)
            SELECT DISTINCT inboundId
            FROM ccWhatsAppConversations
            WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));

            INSERT INTO #TmpCampAgentWg (Id)
            SELECT DISTINCT camId
            FROM ccWhatsAppConversationsOut
            WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));
        END

        ;WITH LatestStatus AS (
            SELECT
                lad.User_id,
                lad.currentStatus,
                lad.fecha,
                ROW_NUMBER() OVER (PARTITION BY lad.User_id ORDER BY lad.fecha DESC) AS RowNum
            FROM ccLogAgentesDia lad
        )
        SELECT
            @AgentIds = ISNULL(@AgentIds + CASE WHEN @AgentIds = '''' THEN '''' ELSE '','' END + CAST(u.User_id AS VARCHAR), ''''),
            @AgentLogins = ISNULL(@AgentLogins + CASE WHEN @AgentLogins = '''' THEN '''' ELSE '','' END + u.Login, ''''),
            @AgentNames = ISNULL(@AgentNames + CASE WHEN @AgentNames = '''' THEN '''' ELSE '','' END + u.Nombres + '' '' + u.ApellidoPaterno + '' '' + ISNULL(u.ApellidoMaterno, ''''), ''''),
            @AgentStatusList = ISNULL(@AgentStatusList + CASE WHEN @AgentStatusList = '''' THEN '''' ELSE '','' END +
                               ISNULL(CASE WHEN ts.descripcion = ''Disponible'' THEN ''Ready'' ELSE ts.descripcion END, ''Unknown''), '''')
        FROM ccUsers u
        INNER JOIN ccRIAWorkGroupUsers wgu ON u.User_id = wgu.User_id
        INNER JOIN ccRIACampEspWG wg ON wg.IDWG = wgu.IDWG
        LEFT JOIN LatestStatus ls ON u.User_id = ls.User_id AND ls.RowNum = 1
        LEFT JOIN ccTipoStatusAgente ts ON ls.currentStatus = ts.TipoStatusAge_id
        WHERE wg.IdCampEsp IN (SELECT Id FROM #TmpCampAgentWg)
          AND u.TipoUser_id = 1
          AND wg.Tipo = (CASE
                            WHEN ((@InboundIdsLst IS NULL OR @InboundIdsLst = '''') AND (@OutboundIdsLst IS NULL OR @OutboundIdsLst = '''') AND (ISNULL(@ClientNumbersLst, '''') <> ''''))
                            THEN wg.Tipo
                            ELSE @CampType
                        END)
        GROUP BY u.User_id, u.Login, u.Nombres, u.ApellidoPaterno, u.ApellidoMaterno, ts.descripcion;

        SELECT @AgentIds AS AgentIdsList, @AgentLogins AS AgentLoginsList, @AgentNames AS AgentNamesList, @AgentStatusList AS AgentStatusList;

        IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
    END

    DECLARE @PageSize INT = 10;
    DECLARE @TotalConversations INT = 0;
    DECLARE @Offset INT;

    IF @Option = 3 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para agente
    BEGIN
        DECLARE @ClientNumberTable TABLE (ClientNumber BIGINT);
        DECLARE @InboundIdTable TABLE (InboundId INT);
        DECLARE @OutboundIdTable TABLE (OutboundId INT);

        IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
        BEGIN
            INSERT INTO @ClientNumberTable (ClientNumber)
            SELECT CAST(value AS BIGINT)
            FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
        END

        IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
        BEGIN
            INSERT INTO @InboundIdTable (InboundId)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
        END

        IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
        BEGIN
            INSERT INTO @OutboundIdTable (OutboundId)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
        END

        SELECT
            @TotalConversations = COUNT(*)
        FROM (
            SELECT DISTINCT c.ConversationId, ''Inbound'' AS MsgType
            FROM ccWhatsAppConversations c
            LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
            WHERE c.AgentId = @agentId
                AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
                AND c.requestDate BETWEEN @From AND @To
                AND m.content IS NOT NULL
                AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
                AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))
                AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)

            UNION ALL

        SELECT DISTINCT c.ConversationId, ''Outbound'' AS MsgType
        FROM ccWhatsAppConversationsOut c
        LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
        WHERE c.AgentId = @agentId
            AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
            AND c.requestDate BETWEEN @From AND @To
            AND m.content IS NOT NULL
            AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
            AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
            AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
            AND NOT (
                c.conversationStatus = 18
                AND EXISTS (
                    SELECT 1
                    FROM ccWAMessagesConversationsOut mo
                    WHERE mo.conversationId = c.ConversationId
                    GROUP BY mo.conversationId
                    HAVING COUNT(*) = 1 AND MAX(mo.messageStatus) = ''error''
                )
            )
        ) AS AllConversations;

        SET @Offset = (@ConversationIndex - 1);

        DECLARE @RemainingConversations INT = @TotalConversations - @Offset;
        IF @RemainingConversations < @PageSize
            SET @PageSize = @RemainingConversations;

        IF @Offset >= @TotalConversations
        BEGIN
            SELECT TOP 0
                CAST(0 AS INT) AS ConversationId,
                CAST(0 AS INT) AS CamId,
                '''' AS CamNumber,
                CAST(0 AS SMALLINT) AS Frame,
                '''' AS ClientNumber,
                '''' AS MessageContent,
                '''' AS CamType,
                CAST(GETDATE() AS DATETIME) AS LastMessageDateTime,
                @TotalConversations AS ConversationsCount
            WHERE 1 = 0;
            RETURN;
        END

        ;WITH LatestInboundMessages AS (
            SELECT
                c.ConversationId,
                c.InboundId AS CampaignId,
                ci.descripcion AS CamName,
                c.phoneACD as CamNumber,
                g.graphic_id AS GraphicId,
                c.clientId AS ClientNumber,
                m.content AS MessageContent,
                m.typeMessage AS MessageType,
                m.TimeStampMessage AS LastMessageTimestamp,
                ''Inbound'' AS CampType,
                ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
            FROM ccWhatsAppConversations c
            LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
            LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
            LEFT JOIN ccinbound ci ON ci.inbound_id = c.inboundid
            WHERE c.AgentId = @agentId
                AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
                AND c.requestDate BETWEEN @From AND @To
                AND m.content IS NOT NULL
                AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
                AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))
                AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
        ),

        LatestOutboundMessages AS (
            SELECT
                c.ConversationId,
                c.camId AS CampaignId,
                ca.cam_descripcion AS CamName,
                c.phoneCamp AS CamNumber,
                g.graphic_id AS GraphicId,
                c.clientId AS ClientNumber,
                m.content AS MessageContent,
                m.typeMessage AS MessageType,
                m.TimeStampMessage AS LastMessageTimestamp,
                ''Outbound'' AS CampType,
                ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
            FROM ccWhatsAppConversationsOut c
            LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
            LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
            LEFT JOIN ccCamps ca ON ca.cam_Id = c.camid
            WHERE c.AgentId = @agentId
                AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
                AND c.requestDate BETWEEN @From AND @To
                AND m.content IS NOT NULL
                AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
                AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
                AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
                AND NOT (
                c.conversationStatus = 18
                AND EXISTS (
                    SELECT 1
                    FROM ccWAMessagesConversationsOut mo
                    WHERE mo.conversationId = c.ConversationId
                    GROUP BY mo.conversationId
                    HAVING COUNT(*) = 1 AND MAX(mo.messageStatus) = ''error''
                )
            )
        ),

        CombinedMessages AS (
            SELECT
                ConversationId,
                CampaignId,
                CamNumber,
                CamName,
                GraphicId,
                ClientNumber,
                MessageContent,
                MessageType,
                LastMessageTimestamp,
                CampType
            FROM LatestInboundMessages
            WHERE rn = 1

            UNION ALL

            SELECT
                ConversationId,
                CampaignId,
                CamNumber,
                CamName,
                GraphicId,
                ClientNumber,
                MessageContent,
                MessageType,
                LastMessageTimestamp,
                CampType
            FROM LatestOutboundMessages
            WHERE rn = 1
        )

        SELECT conversationId AS ConversationId,
               CampaignId AS CamId,
               CamNumber AS CamNumber,
               CamName AS CamName,
               CAST(GraphicId AS SMALLINT) AS Frame,
               ClientNumber AS ClientNumber,
               MessageContent AS MessageContent,
               MessageType AS MessageType,
               CampType AS CamType,
               LastMessageTimestamp AS LastMessageDateTime,
               @TotalConversations AS ConversationsCount
        FROM CombinedMessages
        ORDER BY LastMessageTimestamp DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END;

    IF @Option = 4 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para administrador
    BEGIN
        -- Drop and recreate temporary tables
        IF OBJECT_ID(''tempdb..#ClientNumberTable'') IS NOT NULL DROP TABLE #ClientNumberTable;
        CREATE TABLE #ClientNumberTable (ClientNumber VARCHAR(50));

        IF OBJECT_ID(''tempdb..#InboundIdTable'') IS NOT NULL DROP TABLE #InboundIdTable;
        CREATE TABLE #InboundIdTable (InboundId INT);

        IF OBJECT_ID(''tempdb..#OutboundIdTable'') IS NOT NULL DROP TABLE #OutboundIdTable;
        CREATE TABLE #OutboundIdTable (OutboundId INT);

        IF OBJECT_ID(''tempdb..#AgentIdTable'') IS NOT NULL DROP TABLE #AgentIdTable;
        CREATE TABLE #AgentIdTable (AgentId INT);

        IF OBJECT_ID(''tempdb..#StatusTable'') IS NOT NULL DROP TABLE #StatusTable;
        CREATE TABLE #StatusTable (StatusCategory VARCHAR(50));

        IF OBJECT_ID(''tempdb..#StatusIdTable'') IS NOT NULL DROP TABLE #StatusIdTable;
        CREATE TABLE #StatusIdTable (StatusId INT);

        DECLARE @IncludeQueued BIT = 0;

        -- Populate temporary tables based on input parameters
        IF ISNULL(@ClientNumbersLst, '''') <> ''''
        BEGIN
            INSERT INTO #ClientNumberTable (ClientNumber)
            SELECT value
            FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
        END

        IF ISNULL(@InboundIdsLst, '''') <> ''''
        BEGIN
            INSERT INTO #InboundIdTable (InboundId)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
        END

        IF ISNULL(@OutboundIdsLst, '''') <> ''''
        BEGIN
            INSERT INTO #OutboundIdTable (OutboundId)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
        END

        IF ISNULL(@AgentsIdsLst, '''') <> ''''
        BEGIN
            INSERT INTO #AgentIdTable (AgentId)
            SELECT CAST(value AS INT)
            FROM fn_RIASplitDelimited(@AgentsIdsLst, '','');
        END

        IF ISNULL(@StatusLst, '''') <> ''''
        BEGIN
            INSERT INTO #StatusTable (StatusCategory)
            SELECT LTRIM(RTRIM(value))
            FROM fn_RIASplitDelimited(@StatusLst, '','');
        END

        -- Map status categories to internal Status IDs
        INSERT INTO #StatusIdTable (StatusId)
        SELECT StatusId
        FROM (
            SELECT CASE
                WHEN StatusCategory = ''active'' THEN messageStatusId
                WHEN StatusCategory = ''pre-assigned'' THEN 21
                WHEN StatusCategory = ''finished'' THEN messageStatusId
                ELSE NULL
            END AS StatusId
            FROM messageStatus
            INNER JOIN #StatusTable ON
                (StatusCategory = ''active'' AND messageStatusId IN (1, 2, 3, 5, 7, 8, 9))
                OR (StatusCategory = ''pre-assigned'' AND messageStatusId = 21)
                OR (StatusCategory = ''finished'' AND messageStatusId IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19))
        ) AS MappedStatus
        WHERE StatusId IS NOT NULL;

        IF EXISTS (SELECT 1 FROM #StatusTable WHERE StatusCategory = ''queued'')
        BEGIN
            SET @IncludeQueued = 1;
        END

        -- Calculate total conversations based on filters for Inbound, Outbound, or Client-only cases

        -- Case 1: Inbound Conversations
        IF @InboundIdsLst IS NOT NULL
        BEGIN
            WITH ConversationsWithMessages AS (
                -- Retrieve all conversations with messages
                SELECT DISTINCT c.ConversationId
                FROM ccWhatsAppConversations c
                INNER JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
                WHERE c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
                    AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
                    AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                    AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                    OR (@IncludeQueued = 1 AND c.onQueue = 1 AND c.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)))
            ),
            LinkedConversations AS (
                -- Include conversations linked to ones with messages
                SELECT DISTINCT r.conversationIdAfter AS ConversationId
                FROM ccWhatsAppConversationsRelationship r
                INNER JOIN ConversationsWithMessages cm ON r.conversationIdBefore = cm.ConversationId
            )
            SELECT
                @TotalConversations = COUNT(DISTINCT c.ConversationId)
            FROM ccWhatsAppConversations c
            WHERE c.ConversationId IN (
                -- Combine conversations with messages and li#StatusIdTablenked conversations
                SELECT ConversationId FROM ConversationsWithMessages
                UNION
                SELECT ConversationId FROM LinkedConversations
            )
            AND c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
            AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
            OR (@IncludeQueued = 1 AND c.onQueue = 1 AND c.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)));
        END

        -- Case 2: Outbound Conversations
        ELSE IF @OutboundIdsLst IS NOT NULL
        BEGIN
            SELECT
                @TotalConversations = COUNT(DISTINCT c.ConversationId)
            FROM ccWhatsAppConversationsOut c
            LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
            WHERE c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
                AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND c.onQueue = 1 AND c.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)))
        END

        -- Case 3: ClientNumbers only (when both Inbound and Outbound IDs are NULL)
        ELSE IF @ClientNumbersLst IS NOT NULL AND @TotalConversations = 0
        BEGIN
            DECLARE @InboundConversations INT = 0;
            DECLARE @OutboundConversations INT = 0;

            -- Count inbound conversations
            SELECT
                @InboundConversations = COUNT(DISTINCT whatsIn.ConversationId)
            FROM ccWhatsAppConversations whatsIn
            INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
            WHERE whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1 AND whatsIn.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)));

            -- Count outbound conversations
            SELECT
                @OutboundConversations = COUNT(DISTINCT whatOut.ConversationId)
            FROM ccWhatsAppConversationsOut whatOut
            INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
            WHERE whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND whatOut.onQueue = 1 AND whatOut.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)));

            -- Sum the inbound and outbound counts
            SET @TotalConversations = @InboundConversations + @OutboundConversations;
        END

        -- Paginate results based on @ConversationIndex
        SET @Offset = ISNULL(@ConversationIndex, 1) - 1;

        IF @ConversationIndex >= @TotalConversations
        BEGIN
            SET @Offset = @TotalConversations - @PageSize;
            IF @Offset < 0 SET @Offset = 0;
        END

        -- Collect unique conversation IDs from Inbound and Outbound messages
        ;WITH ExistingConversations AS (
            SELECT ConversationId FROM ccWhatsAppConversations WHERE InboundId IN (SELECT InboundId FROM #InboundIdTable)
            UNION
            SELECT ConversationId FROM ccWhatsAppConversationsOut WHERE camId IN (SELECT OutboundId FROM #OutboundIdTable)
        ),
        -- Retrieve paginated conversations for Inbound, Outbound, or Client-only case

        LatestInboundMessages AS (
            SELECT
                c.ConversationId,
                c.InboundId AS CampaignId,
                COALESCE(g.graphic_id, 0) AS GraphicId,
                COALESCE(c.clientId, '''') AS ClientNumber,
                COALESCE(m.content, '''') AS MessageContent,
                COALESCE(m.typeMessage, '''') AS MessageType,
                COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
                COALESCE(u.Login, '''') AS AgentLogin,
                CASE
                    WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
                    WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                    WHEN c.conversationStatus = 21 THEN ''pre-assigned''
                    ELSE ''finished''
                END AS ConversationStatus,
                ''Inbound'' AS CampType,
                ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
            FROM ccWhatsAppConversations c
            LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
            LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
            LEFT JOIN ccUsers u ON u.User_id = c.AgentId
            WHERE
                c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
                AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND c.onQueue = 1 AND c.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)))
        ),

        LatestOutboundMessages AS (
            SELECT
                c.ConversationId,
                c.camId AS CampaignId,
                COALESCE(g.graphic_id, 0) AS GraphicId,
                COALESCE(c.clientId, '''') AS ClientNumber,
                COALESCE(m.content, '''') AS MessageContent,
                COALESCE(m.typeMessage, '''') AS MessageType,
                COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
                COALESCE(u.Login, '''') AS AgentLogin,
                CASE
                    WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
                    WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                    WHEN c.conversationStatus = 21 THEN ''pre-assigned''
                    ELSE ''finished''
                END AS ConversationStatus,
                ''Outbound'' AS CampType,
                ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
            FROM ccWhatsAppConversationsOut c
            LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
            LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
            LEFT JOIN ccUsers u ON u.User_id = c.AgentId
            WHERE
                c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
                AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND c.onQueue = 1 AND c.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)))
        ),

        ClientOnlyMessages AS (
            -- Exclude conversations that already exist in ExistingConversations
            SELECT
                whatsIn.ConversationId,
                whatsIn.InboundId AS CampaignId,
                COALESCE(g.graphic_id, 0) AS GraphicId,
                COALESCE(whatsIn.clientId, '''') AS ClientNumber,
                COALESCE(m.content, '''') AS MessageContent,
                COALESCE(m.typeMessage, '''') AS MessageType,
                COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
                COALESCE(u.Login, '''') AS AgentLogin,
                CASE
                    WHEN whatsIn.onQueue = 1 AND whatsIn.conversationStatus = 8 THEN ''queued''
                    WHEN whatsIn.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                    WHEN whatsIn.conversationStatus = 21 THEN ''pre-assigned''
                    ELSE ''finished''
                END AS ConversationStatus,
                ''Inbound'' AS CampType,
                ROW_NUMBER() OVER (PARTITION BY whatsIn.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
            FROM ccWhatsAppConversations whatsIn
            INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
            LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = whatsIn.InboundId
            LEFT JOIN ccUsers u ON u.User_id = whatsIn.AgentId
            WHERE
                whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1 AND whatsIn.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)))
                AND whatsIn.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)

            UNION ALL

            SELECT
                whatOut.ConversationId,
                whatOut.camId AS CampaignId,
                COALESCE(g.graphic_id, 0) AS GraphicId,
                COALESCE(whatOut.clientId, '''') AS ClientNumber,
                COALESCE(m.content, '''') AS MessageContent,
                COALESCE(m.typeMessage, '''') AS MessageType,
                COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
                COALESCE(u.Login, '''') AS AgentLogin,
                CASE
                    WHEN whatOut.onQueue = 1 AND whatOut.conversationStatus = 8 THEN ''queued''
                    WHEN whatOut.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                    WHEN whatOut.conversationStatus = 21 THEN ''pre-assigned''
                    ELSE ''finished''
                END AS ConversationStatus,
                ''Outbound'' AS CampType,
                ROW_NUMBER() OVER (PARTITION BY whatOut.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
            FROM ccWhatsAppConversationsOut whatOut
            INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
            LEFT JOIN ccRIACampsGraph g ON g.cam_id = whatOut.camId
            LEFT JOIN ccUsers u ON u.User_id = whatOut.AgentId
            WHERE
                whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
                AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
                AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable))
                OR (@IncludeQueued = 1 AND whatOut.onQueue = 1 AND whatOut.conversationStatus NOT IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)))
                AND whatOut.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)
        )

        -- Final result
        SELECT
            CAST(ConversationId AS INT) AS ConversationId,
            CAST(CampaignId AS SMALLINT) AS CamId,
            CAST(GraphicId AS SMALLINT) AS Frame,
            CAST(ClientNumber AS VARCHAR(50)) AS ClientNumber,
            CAST(MessageContent AS VARCHAR(MAX)) AS MessageContent,
            CAST(MessageType AS VARCHAR(MAX)) AS MessageType,
            CAST(LastMessageTimestamp AS DATETIME) AS LastMessageDateTime,
            CAST(AgentLogin AS VARCHAR(50)) AS AgentLogin,
            CAST(ConversationStatus AS VARCHAR(50)) AS ConversationStatus,
            CAST(CampType AS VARCHAR(50)) AS CamType,
            CAST(@TotalConversations AS INT) AS ConversationsCount
        FROM (
            SELECT * FROM LatestInboundMessages WHERE rn = 1
            UNION ALL
            SELECT * FROM LatestOutboundMessages WHERE rn = 1
            UNION ALL
            SELECT * FROM ClientOnlyMessages WHERE rn = 1
				AND NOT EXISTS (SELECT 1 FROM #InboundIdTable)
				AND NOT EXISTS (SELECT 1 FROM #OutboundIdTable)
        ) AS CombinedMessages
        ORDER BY ConversationId DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
    END;

    IF @Option = 5 -- Obtiene número máximo de días a buscar por historial cuando se filtra por campañas
    BEGIN
        IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

        CREATE TABLE #TmpInboundIdsCampFilter (Id INT);

        INSERT INTO #TmpInboundIdsCampFilter (Id)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@InboundIdsLst, '','');

        SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
        FROM ccInbound i
        INNER JOIN #TmpInboundIdsCampFilter tmp ON tmp.Id = i.Inbound_id;

        IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

        IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

        CREATE TABLE #TmpOutboundIdsCampFilter (Id INT);

        INSERT INTO #TmpOutboundIdsCampFilter (Id)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');

        SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
        FROM contactMeanOut cmo
        INNER JOIN #TmpOutboundIdsCampFilter tmp ON tmp.Id = cmo.camp_id;

        IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

        SET @FinalMaxValue = CASE
            WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
            WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
            ELSE CASE
                WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
                ELSE @MaxDaysPerWAConvo
            END
        END;

         SELECT CAST(@FinalMaxValue AS SMALLINT) AS MaxConversationHistory;
    END;

    IF @Option = 6 -- Obtener cabecera de varias conversaciones
    BEGIN
        CREATE TABLE #TmpConversationIds (Id INT);
        INSERT INTO #TmpConversationIds (Id)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@ConversationIds, '','');

        IF @CamType = 0
        BEGIN
            SELECT
                cwc.conversationId AS ConversationId,
                (CASE WHEN cwc.disposition = 0 THEN ''N/A'' ELSE ctc.Description END) AS Disposition,
                (CASE WHEN cwc.SubDisposition = 0 THEN ''N/A'' ELSE ctcs.califSubDesc END) AS SubDisposition,
                cwc.inboundId AS CamId,
                ISNULL(cwc.conversationDate, ''1900-01-01'') AS ConversationDate,
                (CASE
                    WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
                        OR cwc.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
                        OR cwc.tConversation IS NULL THEN 0
                    ELSE cwc.tConversation
                END) AS TConversation,
                0 AS CampType,
                ci.descripcion AS CampName,
                cwc.clientId AS PhoneNumber,
                (CASE
                    WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
                        OR cwc.conversationStatus IN (10, 17)
                        OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
                    ELSE cu.User_id
                END) AS AgentId,
                (CASE
                    WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
                        OR cwc.conversationStatus IN (10, 17)
                        OR cu.User_id IS NULL THEN ''''
                    ELSE cu.Nombres
                END) AS AgentName,
                (CASE
                    WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
                        OR cwc.conversationStatus IN (10, 17)
                        OR cu.User_id IS NULL THEN ''''
                    ELSE cu.Login
                END) AS AgentLogin,
                ISNULL(CAST(mwn.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
                ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName,
				CASE
                    WHEN cwc.onQueue = 1 AND cwc.conversationStatus = 8 THEN ''queued''
                    WHEN cwc.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                    WHEN cwc.conversationStatus = 21 THEN ''pre-assigned''
                    ELSE ''finished''
                END AS ConversationStatus
            FROM ccWhatsAppConversations cwc
            INNER JOIN ccInbound ci ON ci.inbound_id = cwc.inboundId
            LEFT JOIN ccUsers cu ON cu.User_id = cwc.agentId
            INNER JOIN #TmpConversationIds tci ON tci.Id = cwc.conversationId
            LEFT JOIN ccTipoCalif ctc ON ctc.calif_id = cwc.disposition
            LEFT JOIN ccTipoCalifSub ctcs ON ctcs.califSub_id = cwc.subDisposition
            LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwc.phoneACD
            LEFT JOIN cccamps ccc ON ccc.cam_Id = mwn.Cam_Id
        END
        ELSE
        BEGIN
            SELECT
                cwo.conversationId AS ConversationId,
                (CASE WHEN cwo.disposition = 0 THEN ''N/A'' ELSE ctco.Description END) AS Disposition,
                (CASE WHEN cwo.SubDisposition = 0 THEN ''N/A'' ELSE ctcso.califSubDesc END) AS SubDisposition,
                cwo.camId AS CamId,
                ISNULL(cwo.conversationDate, ''1900-01-01'') AS ConversationDate,
                (CASE
                    WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
                        OR cwo.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
                        OR cwo.tConversation IS NULL THEN 0
                    ELSE cwo.tConversation
                END) AS TConversation,
                1 AS CampType,
                cc.cam_descripcion AS CampName,
                cwo.clientId AS PhoneNumber,
                (CASE
                    WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
                        OR cwo.conversationStatus IN (10, 17)
                        OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
                    ELSE cu.User_id
                END) AS AgentId,
                (CASE
                    WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
                        OR cwo.conversationStatus IN (10, 17)
                        OR cu.User_id IS NULL THEN ''''
                    ELSE cu.Nombres
                END) AS AgentName,
                (CASE
                    WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
                        OR cwo.conversationStatus IN (10, 17)
                        OR cu.User_id IS NULL THEN ''''
                    ELSE cu.Login
                END) AS AgentLogin,
                ISNULL(CAST(ccc.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
                ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName,
				CASE
                    WHEN cwo.onQueue = 1 AND cwo.conversationStatus = 8 THEN ''queued''
                    WHEN cwo.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                    WHEN cwo.conversationStatus = 21 THEN ''pre-assigned''
                    ELSE ''finished''
                END AS ConversationStatus
            FROM ccWhatsAppConversationsOut cwo
            INNER JOIN ccCamps cc ON cc.cam_id = cwo.camId
            LEFT JOIN ccUsers cu ON cu.User_id = cwo.agentId
            INNER JOIN #TmpConversationIds tci ON tci.Id = cwo.conversationId
            LEFT JOIN ccTipoCalifOUT ctco ON ctco.calif_id = cwo.disposition
            LEFT JOIN ccTipoCalifSubOUT ctcso ON ctcso.califSub_id = cwo.subDisposition
            LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwo.phoneCamp
            LEFT JOIN ccCamps ccc on ccc.cam_id = mwn.Cam_Id
        END
    END

        DECLARE @MaxWhatsAllowed INT;
        DECLARE @ConversationCount INT;

    IF @Option = 8 -- Obtiene valor si se reabrirá o no la conversación y si será se reabrirá tipo entrada o salida
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ccRIAAgentsPermissions WHERE AgentId = @AgentId AND AllowReopenWAConversation = 1)
        BEGIN
            SELECT ''REOPEN_PERMISSION_DISABLED'' AS ReopenConversationResponse;
            RETURN(0);
        END;

        IF @CamType = 0
        BEGIN
            IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent))
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Inbound_Id = @CamId)
                BEGIN
                    SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
                    RETURN(0);
                END

                SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
                SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

                IF @ConversationCount >= @MaxWhatsAllowed
                BEGIN
                    SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
                    RETURN(0);
                END
                SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
                RETURN(0);
            END
            ELSE
            BEGIN
                SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
                RETURN(0);
            END
        END

        IF @CamType = 1
        BEGIN
            IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent))
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Cam_Id = @CamId)
                BEGIN
                    SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
                    RETURN(0);
                END

                SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
                SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

                IF @ConversationCount >= @MaxWhatsAllowed
                BEGIN
                    SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
                    RETURN(0);
                END
                SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
                RETURN(0);
            END
            ELSE
            BEGIN
                SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
                RETURN(0);
            END
        END
    END

        DECLARE @ConvId int;

    IF @Option = 9 -- Verificación al reabrir conversación
    BEGIN
        DECLARE @ConversationWithinWindowTime BIT = 0;
        DECLARE @ReopenConversationButtonResponse VARCHAR(50);
        DECLARE @AgentName varchar(50);
        DECLARE @TimeThreshold DATETIME;
        SET @TimeThreshold = DATEADD(hour, -23, GETDATE());


        IF EXISTS (SELECT TOP 1 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent))
        BEGIN
            SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION'';
        END
        ELSE
        BEGIN
            SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE'';
        END

        IF @CamType = 0
        BEGIN
            IF EXISTS (SELECT TOP 1 1 FROM ccWhatsAppConversations WHERE InboundId = @CamId AND phoneACD = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2)
            BEGIN
                SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversations WHERE InboundId = @CamId  AND phoneACD = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2;
                SELECT @AgentName = u.Nombres FROM ccWhatsAppConversations c
                                                INNER JOIN ccusers u ON c.agentId = u.User_id
                                                WHERE c.ConversationId = @ConvId;
                SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
                                    @AgentName AS AgentName;
                RETURN(0);
            END

            SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
            SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

            IF @ConversationCount >= @MaxWhatsAllowed
            BEGIN
                SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
                RETURN(0);
            END

            IF @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE''
            BEGIN
                IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_ccoWhatsLogDials_PhoneWa_PhoneClient_TimeSpam)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0 AND isManual = 0)
                BEGIN
                    SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
                                       ''N/A'' AS AgentName;
                    RETURN(0);
                END
            END

            SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
            RETURN(0);
        END

        IF @CamType = 1
        BEGIN
            IF EXISTS (SELECT TOP 1 1 FROM ccWhatsAppConversationsOut WHERE camId = @CamId AND phoneCamp = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2)
            BEGIN
                SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversationsOut WHERE camId = @CamId  AND phoneCamp = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2;
                SELECT @AgentName = u.Nombres FROM ccWhatsAppConversationsOut c
                                              INNER JOIN ccusers u ON c.agentId = u.User_id
                                              WHERE c.ConversationId = @ConvId;
                SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
                                   @AgentName AS AgentName;
                RETURN(0);
            END

            IF EXISTS (SELECT TOP 1 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_ccoWhatsLogDials_PhoneWa_PhoneClient_TimeSpam)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0 AND isManual = 0)
            BEGIN
                SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
                ''N/A'' AS AgentName;
                RETURN(0);
            END

            SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
            SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

            IF @ConversationCount >= @MaxWhatsAllowed
            BEGIN
                SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
                RETURN(0);
            END

            SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
            RETURN(0);
        END
    END

    IF @Option = 10 -- Creación de conversationId de entrada
    BEGIN
        EXEC ccsp_ConversationWASave @action=1, @phoneacd=@CamNumber, @clientid= @ClientNumber, @inboundid=@CamId, @agentId = @agentId, @IsReopenedConversation = 1, @conversationstatus=2

    END

    IF @Option = 11 -- Creación de conversationId de salida
    BEGIN
        EXEC ccsp_ConversationOutWASave @action=1, @phoneCamp=@CamNumber, @clientid= @ClientNumber, @campId=@CamId, @agentId = @agentId, @conversationstatus=2
    END'
	EXEC(@sql)

	SET @process = 'K066015 - Opcion 3, se actualiza info para preasignación entrada'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
, @conversationId     INT         = 0
, @inboundId          SMALLINT    = NULL
, @phoneACD           VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT    = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             bigint    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0
--VAR MESSAGES
, @messageId          VARCHAR(150) = NULL
, @messageIdUi        INT         = NULL
, @clientNum          VARCHAR(15) = NULL
, @vonageNum          VARCHAR(15) = NULL
, @typeMessage        VARCHAR(25) = ''''
, @content            NVARCHAR(MAX)= NULL
, @timeStampMessage   DATETIME    = NULL
, @timeStampMessageUTC DATETIME   = NULL
, @originType         VARCHAR(15) = NULL
, @currency           VARCHAR(10) = ''-''
, @price              VARCHAR(10) = ''0.00''
, @messageStatus      VARCHAR(15) = ''N/A''
, @listConversationsIds   VARCHAR(MAX) = NULL
, @IsAgentLoggingOut  BIT = 0
, @IsTransfered       BIT = 0
, @IsReopenedConversation BIT =0
, @AgentLogin         VARCHAR(50) = ''''
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN
        IF NOT EXISTS --new Conversation
        (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
                                                WHERE A.conversationId = @conversationId)
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
            , phoneACD
            , clientId
            , conversationStatus
            , tChatting
            , tWrapUp
            , finishedBy
            , onQueue
            , tQueue
            , tTimeout
            , disposition
            , subDisposition
            , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

            IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId)
                BEGIN
                    SELECT @conversationId = SCOPE_IDENTITY();
                    IF @IsReopenedConversation = 1
                    BEGIN
                        UPDATE ccwhatsappconversations set assignDate = GETDATE() where conversationid = @conversationId
                    END
                    SELECT @conversationId AS ConversationId;
                END

            ELSE
                BEGIN
                    declare @conversationIdTemporal     INT;
                    SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                    EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                    SELECT 0 AS ConversationId;
                END;

            --Save new request
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Request, MarkedAsSpam) VALUES (@inboundId, 1, 0);
                END
            ELSE
                BEGIN
                    UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
                END
            RETURN(0);
        END

        ELSE -- Reasign conversation
        BEGIN
            DECLARE @conversationStatusTemp INT = @conversationStatus;
            IF @conversationStatus in(17,18)
                BEGIN
                    SET @conversationStatusTemp = 1
                END

            DECLARE @RequestDate DATETIME = NULL;
            SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

            INSERT INTO [ccWhatsAppConversations]
            (inboundId
            , phoneACD
            , clientId
            , conversationStatus
            , tChatting
            , tWrapUp
            , finishedBy
            , onQueue
            , tQueue
            , tTimeout
            , disposition
            , subDisposition
            , agentId
            , requestDate
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
            SELECT @conversationIdNew = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore, conversationIdAfter) VALUES (@conversationId, @conversationIdNew);
            --Save new request by reassign
            UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1), EndedBySystem = EndedBySystem + 1
            WHERE InboundId = @inboundId

            EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

            SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
            RETURN(0);
        END;
END; -- End Action 1

ELSE IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end

    UPDATE ccWhatsAppConversations
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11, 13) then 1
    else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

    IF @conversationStatus in(4,10,11,13,17,18) BEGIN -- Ending Cases
            DECLARE @conversationDateTemp INT;
            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end
            from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;


            IF @conversationStatus = 13 BEGIN
                UPDATE ccWAOperatingSummary SET MarkedAsSpam = (MarkedAsSpam + 1) where Inboundid = @inboundId
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    UPDATE ccWAOperatingSummary SET Assigned = (Assigned - 1) where Inboundid = @inboundId;
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18)
            BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0
                BEGIN
                    UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

ELSE IF @action = 3
BEGIN --save conversation Status

DECLARE @isPreassign BIT = 0
DECLARE @statePreassign INT = 21;
DECLARE @stateInQueue INT = 8;
if(@conversationStatus IN (@statePreassign, @stateInQueue) )
	SET @isPreassign = 1

UPDATE ccWhatsAppConversations SET
	conversationStatus = @conversationStatus ,
	agentId = CASE WHEN @isPreassign = 1 THEN @agentId ELSE agentId END
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 4 BEGIN --save messages from conversation
IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversations
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversations
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        IF(@originType = ''Client'')
        BEGIN
            SET @AgentLogin = ''''
        END

        INSERT INTO [ccWAMessagesConversations](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus, AgentLogin) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus, @AgentLogin)
        SELECT @messageId=SCOPE_IDENTITY()
        SELECT @messageId as MessageId
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

ELSE IF @action = 5
BEGIN --save onQueue
    UPDATE ccWhatsAppConversations
            SET onQueue = 1,
            conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
    SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;

    DECLARE @onQueueConversations INT = (SELECT COUNT(CASE WHEN onQueue = 1 AND finishedBy = 0 AND conversationStatus IN (8,9) THEN 1 END)
                                            FROM ccWhatsAppConversations WHERE InboundId = @inboundId)
    UPDATE ccWAOperatingSummary SET OnQueue = @onQueueConversations WHERE InboundId = @inboundId
END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue

        --Assigned a queue conversation
    declare @agentIdTmp int
    DECLARE @inboundIdTmp int
    DECLARE @lastStatus int
	DECLARE @preassignedStatus int = 21
    SELECT @agentIdTmp = A.agentId, @inboundIdTmp = A.inboundId, @lastStatus = A.conversationStatus FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

    IF(@agentId > 0 and @IsTransfered = 1)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                conversationStatus = @conversationStatus,
                IsTransfered = @IsTransfered
        WHERE conversationId = @conversationId;
    END

    IF (@agentIdTmp is null or @agentIdTmp=0 or @lastStatus = @preassignedStatus)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus,
                tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end,
                IsTransfered = CASE WHEN ISNULL(IsTransfered, 0) = 0 THEN @IsTransfered ELSE IsTransfered END
        WHERE conversationId = @conversationId;

        SELECT @conversationId as conversationId
        SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        declare @onQueueInt int
        UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE Inboundid = @inboundId -- It´s assigned
        IF @onQueue = 1 BEGIN
            UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
            if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

                select
                @onQueueInt=count(case when onQueue =1 then 1 end)
                from ccWhatsAppConversations with(nolock)
                where inboundId= @inboundId
                and requestDate>=convert(date,getdate(),121)
                UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

            end
        END
    END
END;

ELSE IF @action = 7
    BEGIN --update price message
        UPDATE ccWAMessagesConversations
                SET price = @price,
                    currency = @currency
        WHERE messageId = @messageId;
    END;

ELSE IF @action = 8
    BEGIN --update status message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET messageStatus = @messageStatus
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 9
    BEGIN --Save last message time by conversationID
        IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
            INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
        END;
        ELSE
            BEGIN
                UPDATE ccLastMessageAgentByConversation
                    SET timeStampLastMessageAgent = getDate()
                WHERE conversationId = @conversationId;
            END;
    END;

ELSE IF @action = 10
    BEGIN --drop and insert register by conversationID
        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 11
    BEGIN --register desconnection agent by conversationID
        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 12
    BEGIN --Obtain conversationsWA post MCS reset

        declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
        UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

        declare @from as datetime;-- = ''01-07-2022'';
        select @from = convert(datetime,convert(varchar(11),getdate()))
        set @from=DATEADD(dd,-1,@from);
        declare @conversationIds table (conversationId  int primary key,phoneACD varchar(50) not null,clientId  varchar(25) not null)

        insert into @conversationIds
        select A.conversationId,A.phoneACD,A.clientId from ccWhatsAppConversations A with(nolock)
        where A.requestDate >= @from
        and A.finishedBy=0

        ;with conversationRepeat as(
            select max(conversationId) conversationId, phoneACD,clientId from @conversationIds
            group by phoneACD,clientId Having count(*)>1
        )

        update A set A.finishedBy=2
        from ccWhatsAppConversations A
        inner join conversationRepeat R on A.phoneACD=R.phoneACD and A.clientId=R.clientId
        and A.conversationId<>R.conversationId
        where A.requestDate >= @from
        and A.finishedBy=0



        select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversations A with(nolock)
        left join ccWAMessagesConversations B on A.conversationId = B.conversationId
        left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
        where A.requestDate >= @from
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18, 19)
            and A.finishedBy=0
        order by agentId desc, requestDate,timeStampMessage, inboundId, clientId


    END;
ELSE IF @action = 13
    BEGIN ---Obtain agents ON STATUS READY
        WITH agents
        AS(
            SELECT c.User_id, c.fecha, c.currentStatus
            FROM ccLogAgentesDia c
            INNER JOIN
            (
                SELECT User_id, MAX(fecha) max_time
                FROM ccLogAgentesDia with(nolock)
                where fecha>=CONVERT(date,getdate(),121)
                GROUP BY User_id
            ) AS t
            ON c.fecha = t.max_time
            AND c.User_id=t.User_id AND currentStatus in (3,34)
        ), usersByCampigns
        AS (
            select IdCampEsp, User_id from ccRIACampEspWG A
            Inner join ccRIAWorkGroupUsers B
            on A.IDWG = B.IDWG
            Inner join contactMeanIn C
            ON A.idCampEsp = C.inboundId
            where A.IDWG = 1 and A.Tipo = 0
            AND C.meanContactTypeId = 5
        )

        select DISTINCT A.User_Id from agents A
        left join usersByCampigns B on A.User_Id = B.User_Id
    END;

ELSE IF @action = 14
    BEGIN --register desconnection MCS
        INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
    END;

ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 16
    BEGIN --update agent status for reassigning error message
            UPDATE ccWhatsAppConversations
            SET IsAgentLoggingOut = @IsAgentLoggingOut
            WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 18 BEGIN
        DECLARE @dateNow DATETIME;
        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

        UPDATE ccWhatsAppConversations
        SET finishedBy = 2, conversationStatus=17
        WHERE finishedBy = 0 AND requestDate <= @dateNow
    END;
ELSE IF @action = 20 BEGIN
        UPDATE ccWhatsAppConversations
        SET tQueue = tQueue+@tQueue
        WHERE conversationId = @conversationId;
    END;
END;
'
	EXEC(@sql)

	SET @process = 'K066015 Opcion 3, se actualiza info para preasignación salida'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut]
    @action             INT,
    @conversationId     INT         = 0,
    @camId              SMALLINT    = NULL,
    @phoneCam           VARCHAR(50) = NULL,
    @clientId           VARCHAR(25) = NULL,
    @conversationStatus SMALLINT    = 0,
    @tChatting          FLOAT       = 0,
    @tWrapUp            SMALLINT    = 0,
    @finishedBy         TINYINT     = 0,
    @onQueue            BIT         = NULL,
    @tQueue             BIGINT      = 0,
    @tTimeout           INT         = 0,
    @disposition        SMALLINT    = 0,
    @subDisposition     SMALLINT    = 0,
    @agentId            INT         = 0,
    @messageId          VARCHAR(150) = NULL,
    @messageIdUi        INT         = NULL,
    @clientNum          VARCHAR(15) = NULL,
    @vonageNum          VARCHAR(15) = NULL,
    @typeMessage        VARCHAR(25) = '''',
    @content            NVARCHAR(MAX)= NULL,
    @timeStampMessage   DATETIME     = NULL,
    @timeStampMessageUTC DATETIME    = NULL,
    @originType         VARCHAR(15) = NULL,
    @currency           VARCHAR(10) = ''-'',
    @price              VARCHAR(10) = ''0.00'',
    @messageStatus      VARCHAR(15) = ''N/A'',
    @listConversationsIds VARCHAR(MAX) = NULL,
    @IsAgentLoggingOut  BIT = 0,
    @ConvId             INT = NULL OUTPUT,
    @IsTransfered       BIT = 0,
    @AgentLogin         VARCHAR(50) = ''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @meanContactTypeId SMALLINT = 1;
    DECLARE @isEndConversation BIT;

    IF @action = 1
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ccWhatsAppConversationsOut WITH (NOLOCK)
                       WHERE conversationId = @conversationId)
        BEGIN
            INSERT INTO ccWhatsAppConversationsOut
            (
                camId, phoneCamp, clientId, conversationStatus,
                tChatting, tWrapUp, finishedBy, onQueue, tQueue,
                tTimeout, disposition, subDisposition, agentId
            )
            VALUES
            (
                @camId, @phoneCam, @clientId, @conversationStatus,
                @tChatting, @tWrapUp, @finishedBy, @onQueue,
                @tQueue, @tTimeout, @disposition, @subDisposition, @agentId
            );

            SELECT @conversationId = SCOPE_IDENTITY();
            SET @ConvId = @conversationId;

            IF NOT EXISTS (SELECT 1 FROM ccWAOperatingSummaryOut WHERE camId = @camId)
                INSERT INTO ccWAOperatingSummaryOut (camId, Request)
                VALUES (@camId, 1);
            ELSE
                UPDATE ccWAOperatingSummaryOut SET Request = Request + 1 WHERE camId = @camId;

            SELECT @conversationId AS ConversationId;
            RETURN;
        END
        ELSE
        BEGIN
            DECLARE @conversationStatusTemp INT = @conversationStatus;
            IF @conversationStatus IN (17,18) SET @conversationStatusTemp = 1;

            DECLARE @RequestDate DATETIME;
            SELECT @RequestDate = requestDate
            FROM ccWhatsAppConversationsOut WITH (NOLOCK)
            WHERE conversationId = @conversationId;

            INSERT INTO ccWhatsAppConversationsOut
            (
                camId, phoneCamp, clientId, conversationStatus,
                tChatting, tWrapUp, finishedBy, onQueue, tQueue,
                tTimeout, disposition, subDisposition, agentId, requestDate
            )
            VALUES
            (
                @camId, @phoneCam, @clientId, @conversationStatusTemp,
                @tChatting, @tWrapUp, @finishedBy, @onQueue,
                @tQueue, @tTimeout, @disposition, @subDisposition,
                @agentId, @RequestDate
            );

            DECLARE @conversationIdNew INT = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationshipOut
                (conversationIdBefore, conversationIdAfter)
            VALUES (@conversationId, @conversationIdNew);

            UPDATE ccWAOperatingSummaryOut
            SET Request = Request + 1, Assigned = Assigned - 1, EndedBySystem = EndedBySystem + 1
            WHERE camId = @camId;

            EXEC ccsp_ConversationWASaveOut @action = 2,
                @conversationId = @conversationId,
                @conversationStatus = @conversationStatus;

            SELECT conversationIdAfter AS ConversationId
            FROM ccWhatsAppConversationsRelationshipOut
            WHERE conversationIdBefore = @conversationId;

            SET @ConvId = @conversationIdNew;
            RETURN;
        END
    END

    ELSE IF @action = 2
    BEGIN
        DECLARE @conversationIdTemp INT;
        DECLARE @TablaTemp TABLE (conversationId INT, status BIT);

        IF @listConversationsIds IS NOT NULL
            INSERT INTO @TablaTemp
            SELECT value, 0
            FROM fn_RIASplitDelimited(@listConversationsIds, '','')
            WHERE value <> '''';
        ELSE
            INSERT INTO @TablaTemp VALUES (@conversationId, 0);

        UPDATE ccWhatsAppConversationsOut
        SET
            conversationStatus = @conversationStatus,
            finishedBy = CASE
                            WHEN @conversationStatus IN (4,10,17,18,19,22) THEN 2
                            WHEN @conversationStatus IN (11,13) THEN 1
                            ELSE 0
                         END,
            tConversation = CASE WHEN @conversationStatus = 10 OR conversationDate IS NULL
                                 THEN 0
                                 ELSE DATEDIFF(SECOND, conversationDate, GETDATE()) END,
            tQueue = CASE WHEN @conversationStatus = 10
                          THEN DATEDIFF(SECOND, requestDate, GETDATE())
                          ELSE tQueue END,
            onQueue = CASE WHEN @conversationStatus = 10 THEN 1 ELSE onQueue END
        WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE EXISTS (SELECT 1 FROM @TablaTemp WHERE status = 0)
        BEGIN
            SELECT TOP 1 @conversationIdTemp = conversationId
            FROM @TablaTemp WHERE status = 0;

            EXEC ccsp_CreateNodeMultimedia @conversationId = @conversationIdTemp, @type = 6;

            IF @conversationStatus IN (4,10,11,13,17,18,22)
            BEGIN
                DECLARE @conversationDateTemp INT;
                SELECT @camId = camId,
                       @agentId = agentId,
                       @clientId = clientId,
                       @conversationDateTemp = CASE WHEN conversationDate IS NOT NULL THEN 1 ELSE 0 END
                FROM ccWhatsAppConversationsOut
                WHERE conversationId = @conversationId;

                IF @conversationStatus = 13
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM ccWhatsAppSpam WHERE NumberClient = @clientId)
                        INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient)
                        VALUES (@camId, @agentId, @conversationId, @clientId);
                END
                ELSE IF @conversationStatus IN (4,10,17,18,22)
                BEGIN
                    IF @conversationDateTemp = 1
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = EndedBySystem + 1,
                                                            Assigned = Assigned - 1
                        WHERE camId = @camId;
                    ELSE
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = EndedBySystem + 1
                        WHERE camId = @camId;
                END
                ELSE IF @conversationStatus = 11
                BEGIN
                    UPDATE ccWAOperatingSummaryOut
                    SET Attended = Attended + 1, Assigned = Assigned - 1
                    WHERE camId = @camId;
                END
            END

            UPDATE @TablaTemp SET status = 1 WHERE conversationId = @conversationIdTemp;
        END
    END

    ELSE IF @action = 3
    BEGIN
        DECLARE @isPreassign BIT = 0;
        IF @conversationStatus IN (21,8) SET @isPreassign = 1;

        UPDATE ccWhatsAppConversationsOut
        SET conversationStatus = @conversationStatus,
            agentId = CASE WHEN @isPreassign = 1 THEN @agentId ELSE agentId END
        WHERE conversationId = @conversationId;
    END

    ELSE IF @action = 4
    BEGIN
        IF EXISTS(SELECT 1 FROM ccWhatsAppConversationsOut WHERE conversationId = @conversationId)
           AND NOT EXISTS(SELECT 1 FROM ccWAMessagesConversationsOut WHERE messageId = @messageId)
        BEGIN
            IF (@originType IN (''Agent'',''Admin''))
               AND NOT EXISTS (SELECT 1 FROM ccWAMessagesConversationsOut
                               WHERE originType IN (''Agent'',''Admin'')
                               AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversationsOut
                SET FirstMessageAgent = @timeStampMessage
                WHERE conversationId = @conversationId;
            END

            IF @originType = ''Client''
                SET @AgentLogin = '''';

            INSERT INTO ccWAMessagesConversationsOut
            (
                messageId, messageIdUi, clientNum, vonageNum,
                typeMessage, content, conversationId,
                timeStampMessage, timeStampMessageUTC,
                originType, currency, price, messageStatus, AgentLogin
            )
            VALUES
            (
                @messageId, @messageIdUi, @clientNum, @vonageNum,
                @typeMessage, @content, @conversationId,
                @timeStampMessage, @timeStampMessageUTC,
                @originType, @currency, @price, @messageStatus, @AgentLogin
            );

            SELECT @messageId = SCOPE_IDENTITY();

            SELECT @camId = camId FROM ccWhatsAppConversationsOut WHERE conversationId = @conversationId;

            IF NOT EXISTS (SELECT 1 FROM ccWAConversationsResult WHERE camId = @camId)
                INSERT INTO ccWAConversationsResult
                (camId, SentMsg, Delivered, NotDelivered, ReadMsg, NotSupported, Received, UnSent)
                VALUES(@camId,0,0,0,0,0,0,0);

            EXEC ccsp_ConversationWASaveOut @action = 16,
                 @camId = @camId,
                 @messageStatus = @messageStatus,
                 @conversationId = @conversationId,
                 @originType = @originType;

            SELECT @messageId AS MessageId;
            RETURN;
        END
        ELSE
        BEGIN
            SELECT 0 AS MessageId;
            RETURN;
        END
    END

    ELSE IF @action = 5
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET onQueue = 1,
            conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;

        DECLARE @campaignId INT;
        SELECT @campaignId = camId
        FROM ccWhatsAppConversationsOut WHERE conversationId = @conversationId;

        DECLARE @onQueueConversations INT;
        SELECT @onQueueConversations =
            COUNT(CASE WHEN onQueue = 1 AND finishedBy = 0 AND conversationStatus IN (8,9) THEN 1 END)
        FROM ccWhatsAppConversationsOut WHERE camId = @campaignId;

        UPDATE ccWAOperatingSummaryOut
        SET OnQueue = @onQueueConversations
        WHERE camId = @campaignId;
    END

    ELSE IF @action = 6
    BEGIN
        DECLARE @agentIdTmp INT;
        SELECT @agentIdTmp = agentId
        FROM ccWhatsAppConversationsOut WHERE conversationId = @conversationId;

        IF(@agentId > 0 AND @IsTransfered = 1)
        BEGIN
            UPDATE ccWhatsAppConversationsOut
            SET agentId = @agentId,
                conversationStatus = @conversationStatus,
                IsTransfered = @IsTransfered
            WHERE conversationId = @conversationId;
        END
        ELSE
        BEGIN
            UPDATE ccWhatsAppConversationsOut
            SET agentId = @agentId,
                assignDate = GETDATE(),
                conversationStatus = @conversationStatus,
                tQueue = CASE WHEN onQueue = 1
                              THEN DATEDIFF(SECOND, requestDate, ISNULL(assignDate, GETDATE()))
                              ELSE 0 END,
                IsTransfered = CASE WHEN ISNULL(IsTransfered, 0) = 0 THEN @IsTransfered ELSE IsTransfered END
            WHERE conversationId = @conversationId;
        END

        SELECT @conversationId AS conversationId;

        SELECT @camId = camId, @onQueue = onQueue
        FROM ccWhatsAppConversationsOut WHERE conversationId = @conversationId;

        IF @onQueue = 1
            UPDATE ccWAOperatingSummaryOut SET OnQueue = OnQueue - 1 WHERE camId = @camId;
    END

    ELSE IF @action = 7
    BEGIN
        UPDATE ccWAMessagesConversationsOut
        SET price = @price, currency = @currency
        WHERE messageId = @messageId;
    END

    ELSE IF @action = 8
    BEGIN
        IF (SELECT messageStatus FROM ccWAMessagesConversationsOut WHERE messageId = @messageId) <> ''read''
        BEGIN
            UPDATE ccWAMessagesConversationsOut
            SET messageStatus = @messageStatus
            WHERE messageId = @messageId;

            EXEC ccsp_ConversationWASaveOut @action = 16,
                 @camId = @camId,
                 @messageStatus = @messageStatus,
                 @conversationId = @conversationId,
                 @originType = @originType;
        END
    END

    ELSE IF @action = 9
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId)
            INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId);
        ELSE
            UPDATE ccLastMessageAgentByConversationOut
            SET timeStampLastMessageAgent = GETDATE()
            WHERE conversationId = @conversationId;
    END

    ELSE IF @action = 10
    BEGIN
        DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
    END

    ELSE IF @action = 11
    BEGIN
        UPDATE ccLastMessageAgentByConversationOut
        SET desconnectionAgent = GETDATE()
        WHERE conversationId = @conversationId;
    END

    ELSE IF @action = 12
    BEGIN
        DECLARE @disconnectionIdTemp INT =
            (SELECT TOP 1 disconnectionId
             FROM ccDisconnectionMCSOut WITH(NOLOCK)
             WHERE timeStampConnection IS NULL
             ORDER BY timeStampDisconnection DESC);

        UPDATE ccDisconnectionMCSOut
        SET timeStampConnection = GETDATE()
        WHERE disconnectionId = @disconnectionIdTemp;

        DECLARE @from DATETIME = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()));
        SET @from = DATEADD(DAY, -1, @from);

        DECLARE @conversationIds TABLE
        (
            conversationId INT PRIMARY KEY,
            phoneCamp VARCHAR(50),
            clientId VARCHAR(25)
        );

        INSERT INTO @conversationIds
        SELECT conversationId, phoneCamp, clientId
        FROM ccWhatsAppConversationsOut
        WHERE requestDate >= @from AND finishedBy = 0;

        ;WITH conversationRepeat AS
        (
            SELECT MAX(conversationId) AS conversationId,
                   phoneCamp, clientId
            FROM @conversationIds
            GROUP BY phoneCamp, clientId
            HAVING COUNT(*) > 1
        )
        UPDATE A
        SET A.finishedBy = 2
        FROM ccWhatsAppConversationsOut A
        INNER JOIN conversationRepeat R
            ON A.phoneCamp = R.phoneCamp
           AND A.clientId = R.clientId
           AND A.conversationId <> R.conversationId
        WHERE requestDate >= @from AND A.finishedBy = 0;

        SELECT
            A.conversationId,
            A.camId AS inboundId,
            A.phoneCamp AS phoneACD,
            A.clientId,
            A.conversationStatus,
            A.requestDate,
            A.conversationDate,
            ISNULL(A.onQueue,0) AS onQueue,
            A.agentId,
            B.timeStampMessage,
            B.originType,
            B.price,
            B.messageIdUi,
            B.messageId,
            B.typeMessage,
            B.content,
            B.messageStatus,
            C.timeStampDisconnection,
            C.timeStampConnection
        FROM ccWhatsAppConversationsOut A WITH (NOLOCK)
        LEFT JOIN ccWAMessagesConversationsOut B WITH (NOLOCK)
               ON A.conversationId = B.conversationId
        LEFT JOIN ccDisconnectionMCSOut C WITH (NOLOCK)
               ON C.disconnectionId = @disconnectionIdTemp
        WHERE A.requestDate >= @from
          AND A.conversationStatus NOT IN (4,10,11,13,17,18,19,20)
          AND A.finishedBy = 0
        ORDER BY agentId DESC, requestDate, timeStampMessage, camId, clientId;
    END

    ELSE IF @action = 13
    BEGIN
        WITH agents AS
        (
            SELECT c.User_id, c.fecha, c.currentStatus
            FROM ccLogAgentesDia c
            INNER JOIN
            (
                SELECT User_id, MAX(fecha) AS max_time
                FROM ccLogAgentesDia WITH (NOLOCK)
                WHERE fecha >= CONVERT(DATE,GETDATE(),121)
                GROUP BY User_id
            ) t
                ON c.fecha = t.max_time
               AND c.User_id = t.User_id
            WHERE c.currentStatus IN (3,34)
        ),
        usersByCampigns AS
        (
            SELECT IdCampEsp, User_id
            FROM ccRIACampEspWG A
            INNER JOIN ccRIAWorkGroupUsers B ON A.IDWG = B.IDWG
            INNER JOIN contactMeanOut C ON A.idCampEsp = C.camp_id
            WHERE A.IDWG = 1 AND A.Tipo = 1 AND C.meanContactTypeId = 5
        )
        SELECT DISTINCT A.User_Id
        FROM agents A
        LEFT JOIN usersByCampigns B ON A.User_Id = B.User_Id;
    END

    ELSE IF @action = 14
    BEGIN
        INSERT INTO ccDisconnectionMCS (timeStampDisconnection)
        VALUES(GETDATE());
    END

    ELSE IF @action = 15
    BEGIN
        IF (SELECT messageStatus FROM ccWAMessagesConversationsOut WHERE messageId = @messageId) <> ''read''
        BEGIN
            UPDATE ccWAMessagesConversationsOut
            SET content = @content
            WHERE messageId = @messageId;
        END
    END

    ELSE IF @action = 16
    BEGIN
        IF @camId IS NULL OR @camId = 0
        BEGIN
            SELECT @camId = camId
            FROM ccWhatsAppConversationsOut WITH (NOLOCK)
            WHERE conversationId = @conversationId;
        END

        IF @messageStatus = ''submitted''
        BEGIN
            UPDATE ccWAConversationsResult
            SET SentMsg = SentMsg + 1
            WHERE camId = @camId;
        END
        ELSE IF @messageStatus = ''delivered''
        BEGIN
            UPDATE ccWAConversationsResult
            SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
                Delivered = Delivered + 1
            WHERE camId = @camId;
        END
        ELSE IF @messageStatus = ''read''
        BEGIN
            UPDATE ccWAConversationsResult
            SET Delivered = CASE WHEN Delivered > 0 THEN Delivered - 1 ELSE Delivered END,
                ReadMsg = ReadMsg + 1
            WHERE camId = @camId;
        END
        ELSE IF @messageStatus IN (''rejected'',''error'',''hostError'',''clientError'',''failed'')
        BEGIN
            UPDATE ccWAConversationsResult
            SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
                NotDelivered = NotDelivered + 1
            WHERE camId = @camId;
        END
        ELSE IF @messageStatus = ''N/A'' AND @originType = ''Client''
        BEGIN
            UPDATE ccWAConversationsResult
            SET Received = Received + 1
            WHERE camId = @camId;
        END
        ELSE IF @messageStatus = ''UnSent''
        BEGIN
            UPDATE ccWAConversationsResult
            SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
                UnSent = UnSent + 1
            WHERE camId = @camId;
        END
        ELSE IF @messageStatus = ''N/A'' AND @originType <> ''Agent''
        BEGIN
            UPDATE ccWAConversationsResult
            SET NotSupported = NotSupported + 1
            WHERE camId = @camId;
        END

        SELECT @messageId AS MessageId;
    END

    ELSE IF @action = 17
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET IsAgentLoggingOut = @IsAgentLoggingOut
        WHERE conversationId = @conversationId;
    END

    ELSE IF @action = 18
    BEGIN
        DECLARE @dateNow DATETIME = DATEADD(HOUR,-23,GETDATE());

        UPDATE ccWhatsAppConversationsOut
        SET finishedBy = 2,
            conversationStatus = 17
        WHERE finishedBy = 0
          AND requestDate <= @dateNow;
    END

    ELSE IF @action = 19
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET assignDate = FirstMessageAgent
        WHERE conversationId = @conversationId;
    END

    ELSE IF @action = 20
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET tQueue = tQueue + @tQueue
        WHERE conversationId = @conversationId;
    END

END
'
	EXEC(@sql)
	-------------------------------------END MACL------------------------------------------------
    -------------------------------------begin dmm------------------------------------------------

SET @process = 'Se elimina setting 285'
SET @sql = 'IF EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 285)
	BEGIN
		delete ccsettings2 where setting_id = 285
	END'
EXEC(@sql);

SET @process = 'Se crea setting 285 con tiempo para reset en Outbound'
SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 285)
	BEGIN
		insert ccsettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values (285,''0|5|3|03:01'',''Outbound Configuration'',1,''GRL'',''CheckProvider=>0:Any port,1:Cost-effective,2:Cost-effective-only|TimeTxCallsCampInfo|DefaultDialFactorIa'',''Outbound Configuration'',0,''.*'')
	END'
EXEC(@sql);

SET @process = 'Drop procedure ccsp_WhatsAppInformationOut'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_WhatsAppInformationOut'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_WhatsAppInformationOut
    END'
EXEC(@sql);

SET @process = 'Se agrega validación en option=3 para saber si hubo desconexión de agente para que no haga update en conversationDate'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
@Option SMALLINT,
@camId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL,
@AdminId int = 0

AS
SET NOCOUNT ON
IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
    print (''Camp Is Not WhatsApp'')
    return(-1);
End



DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
--set @Today SMALLDATETIME = ''2022-03-24''
IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAConversationsResult
    TRUNCATE table ccWAOperatingSummaryOut;
    TRUNCATE TABLE ccWAAverageConversationsOut;
    TRUNCATE TABLE ccLastMessageAgentByConversationOut;
END
else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                WHERE CamId = @camId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = 2


        SET @DefaultValue = @DefaultValue * 60;
        DECLARE @LessThanDefault INT = 0;
        DECLARE @ReceivedConversations INT = 0;
        DECLARE @ServiceLevel SMALLINT = 0;

        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                @AverageDialogTime = ROUND(AVG(tChatting), 4),
                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                @ReceivedConversations = COUNT(conversationDate),
                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
        FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    if exists (select * from ccWAOperatingSummaryOut WITH (NOLOCK) where CamId=@camId
    and (OnQueue<0 or Assigned<0)
    ) begin
        set @Today =convert(date,getdate(),121)

        ;WITH waOperationSummary AS (
        SELECT
            CamId,
            COUNT(CASE WHEN finishedBy = 1 THEN 1 END) AS Attended,
            COUNT(CASE WHEN conversationStatus = 1 THEN 1 END) AS OnQueue,
            COUNT(CASE WHEN finishedBy = 0 AND agentId > 0 THEN 1 END) AS Assigned,
            COUNT(*) AS Request,
            COUNT(CASE WHEN finishedBy = 2 THEN 1 END) AS EndedBySystem
        FROM ccWhatsAppConversationsOut WITH (NOLOCK)
        WHERE camId = @camId AND requestDate >= @Today
        GROUP BY CamId
    )
    UPDATE A
    SET
        A.Attended = B.Attended,
        A.Assigned = B.Assigned,
        A.OnQueue = B.OnQueue,
        A.Request = B.Request,
        A.EndedBySystem = B.EndedBySystem
    FROM ccWAOperatingSummaryOut A
    INNER JOIN waOperationSummary B ON A.CamId = B.CamId;
    END

    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
        ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
        ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
        ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
        ISNULL(ServiceLevel, 0) AS ServiceLevel,
        ISNULL(summary.Attended, 0) AS Attended,
        ISNULL(summary.Assigned, 0) AS Assigned,
        ISNULL(summary.OnQueue, 0) AS OnQueue,
        ISNULL(summary.EndedBySystem, 0) AS EndedBySystem,
        ISNULL(summary.Available, 0) AS Available,
        ISNULL(summary.Request, 0) AS Request
    FROM ccWAAverageConversationsOut conv
    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
    WHERE conv.CamId = @camId OR summary.camId = @camId
END
else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                -- Average Queue/Waiting Time, and Service Level)
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
            VALUES(@camId, 1)
        END
END
else IF @Option = 3 -- Save time from accepted conversation by agent
BEGIN
    IF @ConversationId IS NOT NULL
    BEGIN
        -- Se valida si el conversation date es null para poder actualizarlo
        DECLARE @IsTransfered BIT, @conversationDate DATETIME, @agentDisconnection BIT;
        SELECT @IsTransfered = IsTransfered, @agentDisconnection = IsAgentLoggingOut, @conversationDate = conversationDate FROM ccWhatsAppConversationsOut with(nolock)  WHERE conversationId = @ConversationId;
        IF(@IsTransfered = 0 OR @conversationDate IS NULL)
        BEGIN
            IF (ISNULL(@agentDisconnection, 0) = 0)
            BEGIN
                UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            END
            --Save Conversation Assigned
            SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
            UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
        END

    END
END
else IF @Option = 4 -- Get Disposition Information
BEGIN
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor
    when 0 then ''Sin calificación''
    when 2 then ''Sem classificação''
    else ''No disposition'' end
from ccsettings where setting_id = 27 -- 0esp
SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
        ISNULL(disposition.calif_id, 0) AS DispositionId,
        COUNT(whatsConv.disposition) AS Total,
        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
FROM ccWhatsAppConversationsOut whatsConv with(nolock)
LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
WHERE camId = @camId AND assignDate >= @Today
    and whatsConv.conversationStatus != 2
GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
END
else IF @Option = 5 -- Get Subdisposition Information
BEGIN
    SELECT relation.calif_id AS DispositionId,
            subDispositions.califSubDesc AS SubDispositionsName,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM cctipoSubCalifRel relation
    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
    INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
    WHERE whatsConv.camId = @camId AND
            whatsConv.assignDate >= @Today AND
            relation.tipoSubRel = 0
    GROUP BY subDispositions.califSubDesc, relation.calif_id
END
ELSE IF @Option = 6 -- Agents Availables
BEGIN
    IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
        BEGIN
            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
        END
    ELSE
        BEGIN
            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
        END
END

ELSE IF @Option = 7 -- Whats Conversations Results
BEGIN
    SELECT ISNULL(SentMsg, 0) AS SentMsg,
            ISNULL(Delivered, 0) AS Delivered,
            ISNULL(NotDelivered, 0) AS NotDelivered,
            ISNULL(ReadMsg, 0) AS ReadMsg,
            ISNULL(Received, 0)     AS Received,
            ISNULL(UnSent, 0)       AS UnSent,
            ISNULL(NotSupported, 0) AS NotSupported
    FROM ccWAConversationsResult
    WHERE camId = @camId
END

ELSE IF @Option = 8 -- whats outbound conversations
BEGIN
    DECLARE @ActualDay DATE = GETDATE()

    declare @conversationOut table (
    camId int not null,
    Active int not null,
    Queued int not null,
    FinishedAgent int not null,
    FinishedSystem int not null
    )
    insert into @conversationOut
    SELECT cco.camId ,
        COUNT(CASE WHEN cco.conversationStatus NOT IN (10,11,17,18) THEN 1 ELSE NULL END) Active
        ,COUNT(CASE WHEN conversationStatus = 1 THEN 1 ELSE null END) Queued
        ,count(case when finishedBy=1 then 1 end)  FinishedAgent
        ,count(case when finishedBy=2 then 1 end)  FinishedSystem
    FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
    WHERE cco.camId = @camId AND cco.conversationDate>= @ActualDay
    group by cco.camId

    --update B
    --set B.EndedBySystem=A.FinishedSystem,
    --B.OnQueue=A.Queued
    --from @conversationOut A
    --inner join ccWAOperatingSummaryOut B on A.camId=B.CamId

    select A.Active,B.OnQueue Queued,A.FinishedAgent,B.EndedBySystem as FinishedSystem
    from @conversationOut A
    inner join ccWAOperatingSummaryOut B on A.camId=B.CamId
END
IF @Option = 9
BEGIN
    DECLARE @campsIds TABLE(camid smallint)
    INSERT INTO @campsIds
    exec ccsp_GalateaAdminCampaigns @Option = 11, @CampType = 1, @AdminId = @AdminId, @IsWhatsAppCampaign=1


    SELECT
        waco.camid,
        SUM(CASE WHEN messageStatus = ''sent'' OR messageStatus = ''submitted'' THEN 1 ELSE 0 END) AS SentMsg,
        SUM(CASE WHEN messageStatus = ''delivered'' THEN 1 ELSE 0 END) AS Delivered,
        SUM(CASE WHEN messageStatus = ''read'' THEN 1 ELSE 0 END) AS ReadMsg,
        SUM(CASE WHEN messageStatus = ''rejected'' OR messageStatus = ''failed'' THEN 1 ELSE 0 END) AS [NotDelivered],
        SUM(CASE WHEN messageStatus = ''N/A'' THEN 1 ELSE 0 END) AS NA
    FROM
        ccWhatsAppConversationsOut waco
        INNER JOIN @campsIds c on c.camid = waco.camId
        INNER JOIN ccWAMessagesConversationsOut wamco
        ON waco.conversationId = wamco.conversationId
        WHERE wamco.timeStampMessage > @Today
        AND wamco.originType <> ''Client''
    GROUP BY
        waco.camid
    ORDER BY
        waco.camid;
END

SET NOCOUNT OFF'
EXEC(@sql);

SET @process = 'Drop procedure ccsp_VerifyCampaignRelationships'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_VerifyCampaignRelationships'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_VerifyCampaignRelationships
    END'
EXEC(@sql);

SET @process = 'en optiion = 1 se agrega validación para eliminar relacion de tabla ccvirtualAgemt y ccoDialerCamp al eliminar campaña'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_VerifyCampaignRelationships]
	@Option SMALLINT = 0,
            	@CamIds VARCHAR(MAX)
            AS
            BEGIN
            	SET NOCOUNT ON;

            	DECLARE @CurrentId INT;
            	DECLARE @HasRelations BIT;

            	IF @Option = 0 --ACDs
            	BEGIN
            		IF OBJECT_ID(''tempdb..#TmpACDs'') IS NOT NULL DROP TABLE #TmpACDs;
            		IF OBJECT_ID(''tempdb..#FinalACDs'') IS NOT NULL DROP TABLE #FinalACDs;
            		IF OBJECT_ID(''tempdb..#ClassifiedACDs'') IS NOT NULL DROP TABLE #ClassifiedACDs;

            		CREATE TABLE #TmpACDs (Id INT);
            		CREATE TABLE #FinalACDs (Id INT);
            		CREATE TABLE #ClassifiedACDs (
            			Id INT,
            			HasWGRelation BIT,
            			HasCampaignRelation BIT,
            			UnassignVirtualAgent BIT
            		);

            		INSERT INTO #TmpACDs (Id)
            		SELECT CAST(Value AS INT)
            		FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

            		INSERT INTO #ClassifiedACDs (Id, HasWGRelation, HasCampaignRelation, UnassignVirtualAgent)
            		SELECT
            			t.Id,
            			CASE WHEN r.IdCampEsp IS NOT NULL THEN 1 ELSE 0 END AS HasWGRelation,
            		    CASE WHEN i.inbound_id IS NOT NULL
            			THEN
            					CASE WHEN (i.cam_id IS NULL OR i.cam_id = 0)
            						AND (i.idForNonComprehension IS NULL OR i.idForNonComprehension = 0)
            						AND (i.idForSuccessfulTransaction IS NULL OR i.idForSuccessfulTransaction = 0)
            						THEN 0
            						ELSE 1
            					END
            			ELSE 0 END AS HasCampaignRelation,
            			CASE WHEN v.idCampaign IS NOT NULL THEN 1 ELSE 0 END AS UnassignVirtualAgent
            		FROM #TmpACDs t
            		LEFT JOIN ccRIACampESPWG r
            			ON r.IdCampEsp = t.Id AND r.Tipo = 0
            		LEFT JOIN ccinbound i
            			ON i.inbound_id = t.Id
            		LEFT JOIN ccVirtualAgent v
            			ON v.idCampaign = t.Id AND v.campType = 0 AND v.mediaType = 11;

            		INSERT INTO #FinalACDs (Id)
            		SELECT Id
            		FROM #ClassifiedACDs
            		WHERE HasWGRelation = 0 AND HasCampaignRelation = 0 AND UnassignVirtualAgent = 0;

            		DECLARE cur CURSOR LOCAL FOR
            		SELECT Id
            		FROM #ClassifiedACDs
            		WHERE HasWGRelation = 0 AND HasCampaignRelation = 0 AND UnassignVirtualAgent = 1;

            		OPEN cur;
            		FETCH NEXT FROM cur INTO @CurrentId;

            		WHILE @@FETCH_STATUS = 0
            		BEGIN
            			UPDATE ccVirtualAgent
            			SET idCampaign = 0,
            				mediaType = NULL
            			WHERE idCampaign = @CurrentId AND campType = 0 AND mediaType = 11;

            			INSERT INTO #FinalACDs (Id) VALUES (@CurrentId);

            			FETCH NEXT FROM cur INTO @CurrentId;
            		END

            		CLOSE cur;
            		DEALLOCATE cur;

            		DECLARE @CleanACDIds VARCHAR(MAX);
            		SELECT @CleanACDIds =
            		STUFF((
            			SELECT '','' + CAST(Id AS VARCHAR)
            			FROM #FinalACDs
            			ORDER BY Id
            			FOR XML PATH(''''), TYPE
            		).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''');

            		SET @HasRelations = CASE
            										WHEN (SELECT COUNT(*) FROM #FinalACDs) < (SELECT COUNT(*) FROM #TmpACDs)
            										THEN 1 ELSE 0
            									END;


            		SELECT
            			@HasRelations AS HasRelations,
            			ISNULL(@CleanACDIds, '''') AS ACDIds;

            		IF OBJECT_ID(''tempdb..#TmpACDs'') IS NOT NULL DROP TABLE #TmpACDs;
            		IF OBJECT_ID(''tempdb..#FinalACDs'') IS NOT NULL DROP TABLE #FinalACDs;
            		IF OBJECT_ID(''tempdb..#ClassifiedACDs'') IS NOT NULL DROP TABLE #ClassifiedACDs;
            	END


                ELSE IF @Option = 1 -- Camps
                BEGIN

                    IF OBJECT_ID(''tempdb..#TmpOutIDs'') IS NOT NULL DROP TABLE #TmpOutIDs;
                    IF OBJECT_ID(''tempdb..#FinalCampsId'') IS NOT NULL DROP TABLE #FinalCampsId;
                    IF OBJECT_ID(''tempdb..#ClassifiedCamps'') IS NOT NULL DROP TABLE #ClassifiedCamps;

                    CREATE TABLE #TmpOutIDs (Id INT NOT NULL PRIMARY KEY);
                    CREATE TABLE #FinalCampsId (Id INT NOT NULL PRIMARY KEY);
                    CREATE TABLE #ClassifiedCamps (
                        Id INT NOT NULL,
                        HasWGRelation BIT NOT NULL,
                        HasCampaignRelation BIT NOT NULL,
                        UnassignVirtualAgent BIT NOT NULL
                    );

                    INSERT INTO #TmpOutIDs (Id)
                    SELECT DISTINCT CAST(Value AS INT)
                    FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

                    INSERT INTO #ClassifiedCamps (Id, HasWGRelation, HasCampaignRelation, UnassignVirtualAgent)
                    SELECT
                        t.Id,
                        CASE WHEN r.IdCampEsp IS NOT NULL THEN 1 ELSE 0 END AS HasWGRelation,
                        CASE
                            WHEN i.inbound_id IS NOT NULL
                                 THEN CASE WHEN (i.cam_id IS NULL OR i.cam_id = 0) THEN 0 ELSE 1 END
                            ELSE 0
                        END AS HasCampaignRelation,
                        CASE WHEN v.idCampaign IS NOT NULL THEN 1 ELSE 0 END AS UnassignVirtualAgent
                    FROM #TmpOutIDs AS t
                    LEFT JOIN ccRIACampESPWG AS r
                        ON r.IdCampEsp = t.Id AND r.Tipo = 1
                    LEFT JOIN ccinbound AS i
                    ON i.cam_id = t.Id and i.IDArea is not null
                    LEFT JOIN ccVirtualAgent AS v
                        ON v.idCampaign = t.Id AND v.campType = 1 AND v.mediaType = 10;

                    BEGIN TRY
                        BEGIN TRAN;

                        UPDATE va SET va.idCampaign = 0, va.mediaType  = NULL FROM ccVirtualAgent AS va
                                                                              JOIN #ClassifiedCamps AS c ON c.Id = va.idCampaign
                                                                              WHERE va.campType = 1
                                                                                AND va.mediaType = 10
                                                                                AND c.HasWGRelation = 0
                                                                                AND c.HasCampaignRelation = 0
                                                                                AND c.UnassignVirtualAgent = 1;

                        DELETE dc FROM ccoDialerCamp AS dc WHERE dc.cam_id IN (SELECT Id FROM #ClassifiedCamps WHERE HasWGRelation = 0 AND HasCampaignRelation = 0);

                        INSERT INTO #FinalCampsId (Id) SELECT DISTINCT Id FROM #ClassifiedCamps WHERE HasWGRelation = 0 AND HasCampaignRelation = 0;

                        COMMIT;
                    END TRY
                    BEGIN CATCH
                        IF XACT_STATE() <> 0 ROLLBACK;

                        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE(),
                                @ErrSeverity INT = ERROR_SEVERITY(),
                                @ErrState INT = ERROR_STATE();
                        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
                        RETURN;
                    END CATCH

                    DECLARE @CleanCampsIds VARCHAR(MAX);

                    SELECT @CleanCampsIds =
                    STUFF((
                        SELECT '','' + CONVERT(VARCHAR(10), Id)
                        FROM (SELECT DISTINCT Id FROM #FinalCampsId) d
                        ORDER BY Id
                        FOR XML PATH(''''), TYPE
                    ).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''');

                    SET @HasRelations = CASE
                        WHEN (SELECT COUNT(*) FROM #FinalCampsId) < (SELECT COUNT(*) FROM #TmpOutIDs)
                        THEN 1 ELSE 0 END;

                    SELECT @HasRelations AS HasRelations,
                           ISNULL(@CleanCampsIds, '''') AS CampsIds;

                    IF OBJECT_ID(''tempdb..#TmpOutIDs'') IS NOT NULL DROP TABLE #TmpOutIDs;
                    IF OBJECT_ID(''tempdb..#FinalCampsId'') IS NOT NULL DROP TABLE #FinalCampsId;
                    IF OBJECT_ID(''tempdb..#ClassifiedCamps'') IS NOT NULL DROP TABLE #ClassifiedCamps;
                END
            END'
    EXEC(@sql);

    SET @process = 'Se crea índice faltante IX_ccLogAgentesDia_6'
    SET @sql = 'IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE name = ''IX_ccLogAgentesDia_6'' AND object_id = OBJECT_ID(''dbo.ccLogAgentesDia''))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6 ON ccLogAgentesDia (User_id, TipoStatusAge_id, fecha, tStatus);
    END'
    EXEC(@sql)

    SET @process = 'Creación de tabla CampaignLoad para guardar datos de cargas'
    SET @sql= 'IF NOT EXISTS (SELECT *
                     FROM INFORMATION_SCHEMA.TABLES
                     WHERE TABLE_SCHEMA = ''dbo''
                     AND  TABLE_NAME = ''CampaignLoad'')
    BEGIN
        CREATE TABLE CampaignLoad (
            [Key] NVARCHAR(255) PRIMARY KEY,
            AdminID NVARCHAR(50) NOT NULL,
            FileName NVARCHAR(255) NULL,
            ListName NVARCHAR(255) NULL,
            HasHeader NVARCHAR(10) NULL,
            CallKey NVARCHAR(100) NULL,
            Phones NVARCHAR(MAX) NULL,
            DataField NVARCHAR(MAX) NULL,
            CallBackDate NVARCHAR(50) NULL,
            InternationalRecords BIT NOT NULL DEFAULT 0,
            FilterId NVARCHAR(50) NULL,
            ArrayBlackListId NVARCHAR(MAX) NULL,
            ArrayDeletedBlackListId NVARCHAR(MAX) NULL,
            DataWhere NVARCHAR(MAX) NULL
        );
    END'
    EXEC(@sql);

    SET @process = 'DROP PROCEDURE ccsp_CampaignLoad'
    SET @sql = '
        if exists (select * from sys.procedures where name = N''ccsp_CampaignLoad'')
        begin
            DROP PROCEDURE ccsp_CampaignLoad
        end'
    EXEC(@sql)

    SET @process = 'KR152004 - Se crea SP ccsp_CampaignLoad para guardar, eliminar  y actualizar cargas hidratadas en admin'
    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_CampaignLoad]
        @action                  SMALLINT,
        @Key                     NVARCHAR(255) = NULL,
        @AdminID                 NVARCHAR(50)  = NULL,
        @FileName                NVARCHAR(255) = NULL,
        @ListName                NVARCHAR(255) = NULL,
        @HasHeader               NVARCHAR(10)  = NULL,
        @CallKey                 NVARCHAR(100) = NULL,
        @Phones                  NVARCHAR(MAX) = NULL,
        @DataField               NVARCHAR(MAX) = NULL,
        @CallBackDate            NVARCHAR(50)  = NULL,
        @InternationalRecords    BIT           = 0,
        @FilterId                NVARCHAR(50)  = NULL,
        @ArrayBlackListId        NVARCHAR(MAX) = NULL,
        @ArrayDeletedBlackListId NVARCHAR(MAX) = NULL,
        @DataWhere               NVARCHAR(MAX) = NULL
    AS
    BEGIN
        IF (@action = 1)
        BEGIN
            SELECT [Key],
                   AdminID,
                   FileName,
                   ListName,
                   HasHeader,
                   CallKey,
                   Phones,
                   DataField,
                   CallBackDate,
                   InternationalRecords,
                   FilterId,
                   ArrayBlackListId as ArrayBlackListIdString,
                   ArrayDeletedBlackListId as ArrayDeletedBlackListIdString,
                   DataWhere
               FROM dbo.CampaignLoad
               RETURN;
        END
        ELSE IF (@action = 2)
        BEGIN
            IF EXISTS (SELECT 1
                       FROM dbo.CampaignLoad WITH (UPDLOCK, HOLDLOCK)
                       WHERE [Key] = @Key)
            BEGIN
                UPDATE dbo.CampaignLoad
                   SET AdminID                     = @AdminID,
                       FileName                    = @FileName,
                       ListName                    = @ListName,
                       HasHeader                   = @HasHeader,
                       CallKey                     = @CallKey,
                       Phones                      = @Phones,
                       DataField                   = @DataField,
                       CallBackDate                = @CallBackDate,
                       InternationalRecords        = @InternationalRecords,
                       FilterId                    = @FilterId,
                       ArrayBlackListId            = @ArrayBlackListId,
                       ArrayDeletedBlackListId     = @ArrayDeletedBlackListId,
                       DataWhere                   = @DataWhere
                 WHERE [Key]                       = @Key;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.CampaignLoad (
                    [Key],
                    AdminID,
                    FileName,
                    ListName,
                    HasHeader,
                    CallKey,
                    Phones,
                    DataField,
                    CallBackDate,
                    InternationalRecords,
                    FilterId,
                    ArrayBlackListId,
                    ArrayDeletedBlackListId,
                    DataWhere
                )
                VALUES (
                    @Key,
                    @AdminID,
                    @FileName,
                    @ListName,
                    @HasHeader,
                    @CallKey,
                    @Phones,
                    @DataField,
                    @CallBackDate,
                    @InternationalRecords,
                    @FilterId,
                    @ArrayBlackListId,
                    @ArrayDeletedBlackListId,
                    @DataWhere
                );
            END

            RETURN;
        END
        ELSE IF (@action = 3)
        BEGIN
            DELETE FROM dbo.CampaignLoad
        END
    END'
    EXEC(@sql)
    -------------------------------------END dmm------------------------------------------------

    ------------------------------------- BEGIN GASJ 20250905.0.1 ------------------------------------------------

	SET @process = '#2970 - Reports - RepInCallsDetail columna grab_ID en cero ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady smallint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog float =0 ,
@currentStatus int =-2,--NUEVO PARAMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0,
@TypeAuxiliar int = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

    IF @User_id <= 0 OR (@tStatus = 0 AND @TipoStatusAge_id = 30)
        RETURN 0;

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
DECLARE @cal_tXfer float,   @cal_tRing float
declare @cal_tDialog int
declare @cal_tNotas float
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall float
declare @cal_manual int
declare @dateCheckInterval datetime


set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))

set @cal_manual =0
--4 Dialog,6 Notas, 27 Notas Fallida

IF  @isLogout=1 AND @TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0
BEGIN
    if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
    if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


        if @TipoCall = 0
        begin -- BEING IN @TipoCall = 0  ---
        SELECT @calInicio = cal_Xfer,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @Camp = Inbound_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_key = cal_Key,
        @inbound_id = inbound_id,
        @cal_telefono = cal_ani,
        @cal_whoHung = cal_whoHung,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccCallsIN WITH (NOLOCK)
        WHERE cal_id = @call_id
        AND statusCall_id = 13

        IF @cal_tXfer = 0 AND @cal_tRing = 0
        BEGIN
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
                @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND callID = @call_id
                AND Tipo = @TipoCall
                AND TipoStatusAge_id IN (5, 9)
        END
        IF @cal_tDialog = 0 AND @tDialog > 0
        BEGIN
            IF @Fecha4 < DATEADD(ms, (@sumCall + @tDialog + @cal_tNotas) * 1000, @calInicio)
            BEGIN
                SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                IF @TipoStatusAge_id = 4
                    SET @tDialog = @tDialog - 1

                IF @TipoStatusAge_id = 6
                BEGIN
                    IF @cal_tNotas > 0
                        SET @cal_tNotas = @cal_tNotas - 1
                    ELSE
                        SET @tDialog = @tDialog - 1
                END
            END

            UPDATE ccCallsIN
            WITH (ROWLOCK)

            SET cal_tDialog = @tDialog,
                cal_tNotas = @cal_tNotas,
                cal_tMoh = @tMusicHold,
                cal_tXfer=@cal_tXfer,
                cal_tRing=@cal_tRing
            WHERE cal_id = @call_id
                AND statusCall_id = 13
        END
        ----------------------------
        IF @isTransferEngine = 1
        BEGIN
            DECLARE @minimoDialogo TINYINT

            SELECT @minimoDialogo = valor
            FROM ccSettings
            WHERE setting_id = 13

            IF @cal_tDialog < @minimoDialogo
            BEGIN
                --el status 18 es para llamada cortada con transferencia en Reminder
                EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
            END
        END
        -----------------------------
        END -- END IN @TipoCall = 0  ---
        Else
        begin -- BEING IN @TipoCall = 1  ---
        SELECT @calInicio = cal_inicio,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @cam_id = cam_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccoCallsOut WITH (NOLOCK)
        WHERE cal_id = @call_id

        SET @Camp = @cam_id

        if @cal_tXfer=0 and @cal_tRing=0 begin
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
            @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
            AND callID = @call_id
            AND Tipo = @TipoCall
            AND TipoStatusAge_id IN (5, 9)

        end

        if @cal_tDialog = 0 and @tDialog>0 begin
            IF @Fecha4 < DATEADD(ss, @sumCall + @tDialog + @cal_tNotas, @calInicio)
                BEGIN
                    SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                    IF @TipoStatusAge_id = 4
                        SET @tDialog = @tDialog - 1
                    IF @TipoStatusAge_id = 6
                    BEGIN
                        IF @cal_tNotas > 0
                            SET @cal_tNotas = @cal_tNotas - 1
                        ELSE
                            SET @tDialog = @tDialog - 1
                    END
                END

                UPDATE ccoCallsOut
                WITH (ROWLOCK)
                SET cal_tDialog = @tDialog,
                    totalCall_Time = @tDialog,
                    cal_tNotas = @cal_tNotas,
                    cal_tMoh = @tMusicHold,
                    cal_tXfer = @cal_tXfer,
                    cal_tRing = @cal_tRing
                WHERE cal_id = @call_id
                    AND statusCall_id = 13

        end
        else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
            update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id
        else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
            update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id
        END -- END OUT @TipoCall = 1  ---

    select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

    if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
        insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
    end

    if @TipoStatusAge_id in(6,27) begin
    --Valida que el agente no pudo guardar el status antes de desloguear
    set @dateCheckInterval=dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4)

    if not exists(select 1 from ccLogAgentesDia with(INDEX (IX_ccLogAgentesDia_6),nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between @dateCheckInterval and @Fecha4 )
        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
    end
end --@TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1 --


IF (@TipoStatusAge_id = 4)
BEGIN -- 4 = Dialogo
    DECLARE @tStatus3 FLOAT, @Fecha3 DATETIME

    SELECT TOP 1 @tStatus3 = tstatus, @Fecha3 = fecha
    FROM ccLogAgentesDia WITH (READPAST)
    WHERE TipoStatusAge_id = 3 AND user_id = @User_id
    ORDER BY fecha DESC

    INSERT INTO ccLogAgentesDia_Dialog (
        User_id,
        Cam_id,
        fecha_Calc_ms,
        tStatus_Dispo,
        fecha_Dispo,
        tStatus_Dialog,
        fecha_Dialog
        )
    SELECT @User_id, cam_id,
        datediff(ms, dateadd(ms, - (@tStatus3 * 1000), @Fecha3), dateadd(ms, - (@tStatus3 * 1000
                    ), @Fecha4)),
        @tStatus3,
        @Fecha3,
        @tStatus,
        @Fecha4
    FROM cccampsagente
    WHERE user_id = @User_id

    ---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
    IF @call_id > 0
    BEGIN
        IF @TipoCall = 0
        BEGIN --IN
            SELECT @surveycamid = isnull(extend.SurveyCamId, 0),
                @callBackSurveyClients = i.callBackSurveyClient
            FROM ccinbound i
            LEFT JOIN ccInboundExtend extend
                ON i.inbound_id = extend.inbound_id
            WHERE i.inbound_id = @inbound_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF EXISTS (
                        SELECT 1
                        FROM cccamps
                        WHERE cam_id = @surveycamid
                            AND isnull(callsBySurvey, 0) > 0
                            AND isnull(ivrScript, 0) > 0
                        )
                BEGIN
                    IF (
                            SELECT surveyPctg
                            FROM ccCamps
                            WHERE cam_id = @surveycamid
                            ) >= rand() * 100
                    BEGIN
                        INSERT INTO ccoCallsOUTSource (
                            cal_Key,
                            cam_id,
                            cal_telefono,
                            cal_status,
                            cal_fechaDial
                            )
                        VALUES (
                            right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
                            @surveycamid,
                            @cal_telefono,
                            0,
                            dateadd(mi, 6, getdate())
                            )
                    END
                END
            END
        END --@TipoCall = 0
        ELSE
        BEGIN --OUT
            SELECT @surveycamId = isnull(surveycamid, 0),
                @callBackSurveyClients = callBackSurveyClient
            FROM cccamps
            WHERE cam_id = @cam_id

            SELECT @cal_key = cal_Key,
                @cam_id = cam_id,
                @cal_telefono = cal_telefono,
                @cal_whoHung = cal_whoHung
            FROM ccoCallsOUT WITH (
                    INDEX (IX_ccoCallsOut_11),
                    NOLOCK
                    )
            WHERE callout_id = @callout_id
                AND statusCall_id = 13
                AND cal_id = @call_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF (
                        SELECT surveyPctg
                        FROM ccCamps
                        WHERE cam_id = @surveycamId
                        ) >= rand() * 100
                BEGIN
                    INSERT INTO ccoCallsOUTSource (
                        cal_Key,
                        cam_id,
                        cal_telefono,
                        cal_status,
                        cal_fechaDial
                        )
                    VALUES (
                        right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
                        @surveycamid,
                        @cal_telefono,
                        0,
                        dateadd(mi, 6, getdate())
                        )
                END
            END
        END
    END --@callout_id>0
END --End -- 4 = Dialogo



IF @Camp > 0
    BEGIN
    declare @today datetime=dateadd(hh,-2,getdate())

     UPDATE ccLogAgentesDia WITH (ROWLOCK)
    SET IdCampEsp = @Camp,
        Tipo = @TipoCall
    WHERE fecha>@today and
     IdCampEsp = 0
        AND user_id = @User_id


    UPDATE ccLogAgentesNotReady WITH (ROWLOCK)
    SET IdCampEsp = @Camp,
        Tipo = @TipoCall
    WHERE fecha>@today and
    IdCampEsp = 0
        AND user_id = @User_id

END

set @dateCheckInterval=dateadd(ss, - 10, @Fecha4)


IF NOT (
    @isLogout = 0 AND @TipoStatusAge_id = 6
    AND EXISTS (
            SELECT 1
            FROM ccLogAgentesDia WITH (INDEX (IX_ccLogAgentesDia_6),NOLOCK)
                WHERE User_id = @User_id
                AND TipoStatusAge_id = 4
                AND fecha BETWEEN @dateCheckInterval AND @Fecha4
                AND tStatus = @tStatus + 1
                )
                )
        BEGIN
    UPDATE [ccLogAgentesDiaLast] WITH (ROWLOCK, UPDLOCK)
            SET TipoStatusAge_id = @TipoStatusAge_id,
                tStatus = @tStatus,
                fecha = @Fecha4,
                IdCampEsp = @Camp,
                Tipo = @TipoCall,
                currentStatus = @currentStatus,
                callID = @call_id
            WHERE USER_ID = @User_id

    INSERT ccLogAgentesDia (
        User_id,
        TipoStatusAge_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo,
        currentStatus,
        callID
        )
    VALUES (
        @User_id,
        @TipoStatusAge_id,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall,
        @currentStatus,
        @call_id
        )



    END


IF (@TipoStatusAge_id = 2)
BEGIN  -- 2 = No Disponible
    INSERT ccLogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall
        )

    ---Para Agente RIA: OAYC
    INSERT ccRIALogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4
        )
END

if @TipoStatusAge_id = 37
begin
    EXEC ccsp_GalateaReadyAuxiliar @action = 2, @tipoReadyId = @TypeAuxiliar, @userId = @User_id, @timeStatus= @tStatus
end
ELSE IF (
        @TipoStatusAge_id = 34
        AND @call_id > 0
        ) -- Dialogo WhatsApp
BEGIN
    IF @TipoCall = 0
    BEGIN
        UPDATE ccWhatsAppConversations
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT inboundId
                FROM ccWhatsAppConversations
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformation @Option = 2,
            @InboundId = @Camp
    END
    ELSE
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT camId
                FROM ccWhatsAppConversationsOut
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformationOut @Option = 2,
            @camId = @Camp
    END
END'
	EXEC(@sql)

	SET @process = 'Sears Alter ccoLogBlackList.calKey VARCHAR(40)'
	SET @sql = '-- Declaramos variables para mayor claridad
DECLARE @tableName NVARCHAR(128) = ''ccoLogBlackList'';
DECLARE @columnName NVARCHAR(128) = ''calKey'';
DECLARE @sql NVARCHAR(MAX);

-- Validamos si la columna existe y su longitud es diferente a 40
IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @tableName
      AND COLUMN_NAME = @columnName
      AND DATA_TYPE = ''varchar''
      AND CHARACTER_MAXIMUM_LENGTH <> 40
)
BEGIN
    ALTER TABLE ccoLogBlackList
ALTER COLUMN calKey VARCHAR(40);

END

'
    EXEC(@sql)
-------------------------------------------------------------- Begin Ulises ----------------------------------------------------------
    set @process = 'add values to descTranslate'
    set @sql = '
    if exists (select * from sys.columns where name = N''descTranslate'' and Object_ID = Object_ID(N''ccTipoResultadoDial''))
    begin
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_Answer'' where tipoResDial_id=1
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_Busy'' where tipoResDial_id=2
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_NoAnswer'' where tipoResDial_id=3
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_Fax'' where tipoResDial_id=4
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_NoDialTone'' where tipoResDial_id=5
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_Other'' where tipoResDial_id=8
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_NoService'' where tipoResDial_id=10
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_VoiceMail'' where tipoResDial_id=11
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_Congestion'' where tipoResDial_id=12
		    update  ccTipoResultadoDial set descTranslate=''systemTranslated_Cancelled'' where tipoResDial_id=13
    end'
    EXEC(@sql)
-------------------------------------------------------------- End Ulises ----------------------------------------------------------------


-------------------------------------------------------------- Begin Bryan ----------------------------------------------------------
SET @process = 'Drop procedure ccsp_CreateNodeMultimedia'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_CreateNodeMultimedia'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_CreateNodeMultimedia
    END'
EXEC(@sql);

SET @process = 'En @type = 5 y @type = 6 se agrega + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(A.disposition, 0)) para guardar correctamente las calificaciones de whatsapp'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
							, @supervisor     VARCHAR(255) = ''''
							, @template       VARCHAR(255) = ''''
							, @ScoreTemplate  INT          = 0
							, @type           INT
		AS
		BEGIN

		DECLARE @xml XML, @dateStart DATETIME, @DispXML XML, @SubXML XML;
		DECLARE @info VARCHAR(255);
		DECLARE @infoEscape VARCHAR(MAX);
		DECLARE @disp varchar(255);
		declare @subdisp varchar(255);
		DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
		SET @charEscape = ''"|''''''''|<|>|&'';
		SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

		DECLARE @existAttached BIT, @numInteracion SMALLINT;
		IF @type = 1
		BEGIN--CHAT

			select @disp = Description from ccRIAChats c left join ccTipoCalif b on c.disposition = b.calif_id where c.chatId = @conversationId
			select @subdisp = califSubDesc from ccRIAChats c left join ccTipoCalifSub b on c.subDisposition = b.califSub_id and c.subdisposition <> 0 where c.chatId = @conversationId

			SET @DispXML = (
				SELECT ''" C06="'' + @disp
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C07="'' + @subdisp
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126)))
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid)
			+ ''" CType="1''
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), chatId)
			+ ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, ''''))
			+ ''" C03="'' + CONVERT(VARCHAR(MAX), domain)
			+ ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A''))
			+ ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting)
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C08="'' + CONVERT(VARCHAR(MAX), clientname)
			+ ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126)))
			+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, ''''))
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, ''''))
			+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
			+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], ''''))
			+ ''"/>'')
					, @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
																	LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
																	LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
			WHERE chatId = @conversationId
					AND chatStatus = 4

		END;
		ELSE IF @type = 3
		BEGIN--EMAIL
			SELECT @existAttached = CASE WHEN COUNT(*) > 0
									THEN 1 ELSE 0
									END FROM attached
			WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
			SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
			--Replaza los caracteres por los comunes
			SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
			SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
																	INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

			select @disp = t.Description, @subdisp = ts.califSubDesc
			from conversation c
			left join message m on c.conversationId = m.conversationId
			left join relationMessageDisposition r on m.messageId = r.messageId
			left join ccTipoCalif t on r.dispositionId = t.calif_id
			left join ccTipoCalifSub ts on r.subDispositionId = ts.califSub_id and r.subdispositionId <> 0
			where c.conversationId = @conversationId

			SET @DispXML = (
				SELECT ''" C05="'' + @disp
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C15="'' + @subdisp
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126)))
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid)
			+ ''" CType="1''
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId)
			+ ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126)))
			+ ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion))
			+ ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, '''')))
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' '')))
			+ ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup))
			+ ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, '''')))
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid))
			+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0))
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached)
			+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, ''''))
			+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, ''''))
			+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), ''''))
			+ ''"/>'')
					, @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
																		INNER JOIN message b ON a.conversationid = b.conversationid
																		LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
																		LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
			WHERE a.conversationId = @conversationId
			GROUP BY a.conversationId
					, a.inboundid;

		END;
		ELSE IF @type = 4
		BEGIN--Twitter
			SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
			WHERE conversationTwitterId = @conversationId;

			SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126)))
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid)
			+ ''" CType="1''
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId)
			+ ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126)))
			+ ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion))
			+ ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, '''')))
			+ ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A'')))
			+ ''" C06="'' + MAX(a.screenNameClient)
			+ ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup))
			+ ''" C08="'' + MAX(a.screenNameInbound)
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid))
			+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0))
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, ''''))
			+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, ''''))
			+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
			+ ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A'')))
			+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), ''''))
			+ ''"/>'')
					, @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
																	INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
																	LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
																	LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
																	LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
																	LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
																	LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
																										AND e.subdispositionId <> 0
			WHERE a.conversationTwitterId = @conversationId
			GROUP BY a.conversationTwitterId
					, a.inboundid;
		END;
		ELSE IF @type = 5 BEGIN --WhatsApp In

			select @disp = Description from ccWhatsAppConversations c left join ccTipoCalif b on c.disposition = b.calif_id where c.conversationId = @conversationId
			select @subdisp = califSubDesc from ccWhatsAppConversations c left join ccTipoCalifSub b on c.subDisposition = b.califSub_id where c.conversationId = @conversationId

			--select * from ccWhatsAppConversations

			SET @DispXML = (
				SELECT ''" C07="'' + @disp
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C08="'' + @subdisp
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126)
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid)
			+ ''" CType="5''
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId)
			+ ''" C02="'' + ISNULL(inbound.descripcion, '''')
			+ ''" C03="'' + ISNULL(ccusers.[Login], '''')
			+ ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')
			+ ''" C05="'' + clientId
			+ ''" C06="'' + CONVERT(VARCHAR(MAX), tConversation)
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId)
			+ ''" C10="'' + phoneACD
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId)
			+ ''" C12="'' + ISNULL(@supervisor, '''')
			+ ''" C13="'' + ISNULL(@template, '''')
			+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
			+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(A.disposition, 0))
			+ ''"/>'')
					, @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
																			LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
																			LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
			WHERE A.conversationId = @conversationId;

		END;
		ELSE IF @type = 6 BEGIN --WhatsApp Out

			select @disp = Description from ccWhatsAppConversationsOut c left join ccTipoCalifOUT b on c.disposition = b.calif_id where c.conversationId = @conversationId
			select @subdisp = califSubDesc from ccWhatsAppConversationsOut c left join ccTipoCalifSubOUT b on c.subDisposition = b.califSub_id where c.conversationId = @conversationId

			SET @DispXML = (
				SELECT ''" C07="'' + @disp
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C08="'' + @subdisp
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R06 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126)
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), A.camId)
			+ ''" CType="6''
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId)
			+ ''" C02="'' + ISNULL(c.cam_descripcion, '''')
			+ ''" C03="'' + ISNULL(ccusers.[Login], '''')
			+ ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')
			+ ''" C05="'' + clientId
			+ ''" C06="'' + CONVERT(VARCHAR(MAX), isnull(tConversation,0))
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId)
			+ ''" C10="'' + phoneCamp
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId)
			+ ''" C12="'' + ISNULL(@supervisor, '''')
			+ ''" C13="'' + ISNULL(@template, '''')
			+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
			+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(A.disposition, 0))
			+ ''"/>'')
					, @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversationsOut A
																			LEFT OUTER JOIN ccCamps c ON c.cam_id=A.camId
																			LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
			WHERE A.conversationId = @conversationId;

		END;

		DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
		DECLARE @parameterDefinition NVARCHAR(MAX);

		SELECT @tableName = tableName
				, @tableNameHistory = tableNameHistory
				, @columnId = columnId FROM ccFinderServices
		WHERE id =  @type;

		SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

		IF @xml IS NOT NULL
		BEGIN

			SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
			BEGIN
				UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
			END
			else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
			BEGIN
				UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
			END
			else begin
				INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
			end
			'';

		END
		else begin
				SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
			BEGIN
				UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
			END
			else begin
				INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
			end '';
		end


			EXECUTE sp_executesql
					@sql
					, @parameterDefinition
					, @conversationId = @conversationId
					, @xml = @xml
					, @dateStart = @dateStart;

		END;'
EXEC(@sql);
-------------------------------------------------------------- End Bryan ------------------------------------------------------------
------------------------------------------ BEGIN MAGV 20250905.0.2   ------------------------------
SET @process = 'CW-10215 Drop procedure SaveDispositionsAI'
	SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''SaveDispositionsAI'')
		BEGIN
			DROP PROCEDURE dbo.SaveDispositionsAI
		END'
	EXEC(@sql);

	SET @process = 'CW-10215 CREATE STORE PROCEDURE SaveDispositionsAI'
	SET @sql = 'CREATE PROCEDURE [dbo].[SaveDispositionsAI]
@action        smallint    = NULL,
@call_Id       int         = NULL,
@Qualification varchar(MAX)= NULL,
@result        varchar(MAX)= NULL,
@Observations  varchar(MAX)= NULL,
@CallbackAT    DATETIME = NULL,
@Transcription varchar(MAX)= NULL,
@CamType       bit         = 0,
@disposition_Id SMALLINT = null
AS
BEGIN
	SET NOCOUNT ON;
	--Variables para devolución de llamada
	DECLARE @cal_key varchar(40) ='''';
	DECLARE @cam_id smallint;
	DECLARE @cal_telefono varchar(19);
	DECLARE @inbound_id smallint = NULL;
	DECLARE @CanReprogram smallint  = null

	-- Validacion del Status del Setting 289
	DECLARE @trans_status BIT = NULL;

	DECLARE @valor  NVARCHAR(15) = NULL;

	SELECT @valor = TRY_CAST(valor AS NVARCHAR(15))
	FROM ccSettings2
	WHERE setting_id = 289;

	DECLARE @status NVARCHAR(5);
	DECLARE @sep    INT;

	SET @sep = CHARINDEX(''|'', ISNULL(@valor, ''''));
	SET @status = CASE
					WHEN @sep > 0 THEN SUBSTRING(@valor, 1, @sep - 1)
					ELSE ISNULL(@valor, '''')
				  END;

	IF @action = 1  -- Outbound
	BEGIN
		IF EXISTS (SELECT 1 FROM ccoCallsOutDispositionIA WHERE call_id = @call_Id)
        BEGIN
            UPDATE ccoCallsOutDispositionIA
            SET Qualification = @Qualification,
                result = @result,
                Observations = @Observations
            WHERE call_id = @call_Id;
        END
        ELSE
        BEGIN
            INSERT INTO ccoCallsOutDispositionIA (call_id, Qualification, result, Observations)
            VALUES (@call_Id, @Qualification, @result, @Observations);
        END

		IF EXISTS (SELECT 1 FROM ccTipoCalif WHERE calif_id = @disposition_Id)
		BEGIN
			UPDATE dbo.ccoCallsOut
			SET calif_id = @disposition_Id
			WHERE cal_id = @call_Id;
		END
	END

	ELSE IF @action = 2 AND @status = ''1''   -- Outbound
	BEGIN
		--Se deja pendiente para el siguiente Sprint
		--DECLARE @cam_id smallint = NULL;

		--Select @cam_id = cam_id
		--From ccoCallsOut
		--Where cal_id = @call_Id

		--Select @trans_status = IsCallTranscriptionEnabled
		--From ccCampsExtend
		--Where cam_id  = @cam_id

		--IF @trans_status = 1
		--BEGIN
		--	INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
		--	VALUES (@call_Id, @Transcription);
		--END

		IF EXISTS (SELECT 1 FROM ccoCallsOutTranscriptionIA WHERE call_id = @call_Id)
        BEGIN
            UPDATE ccoCallsOutTranscriptionIA
            SET Transcription = @Transcription
            WHERE call_id = @call_Id;
        END
        ELSE
        BEGIN
            INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
            VALUES (@call_Id, @Transcription);
        END
	END

	ELSE IF @action = 3  -- Inbound
	BEGIN
		Select @CanReprogram = CanReprogram from ccTipoCalif where calif_id = @disposition_Id

		IF (@CallbackAT IS NOT NULL
			AND CONVERT(datetime, @CallbackAT, 120) IS NOT NULL
			AND CONVERT(datetime, @CallbackAT, 120) > GETDATE()
			AND @CanReprogram <> 0)
		BEGIN
			INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations, CallbackAT,disposition_id)
			VALUES (@call_Id, @Qualification, @result, @Observations,@CallbackAT,@disposition_Id);

			SELECT @inbound_id = Inbound_id, @cal_telefono = cal_ANI
				FROM ccCallsIn
				WHERE cal_id = @call_Id;

			SELECT @cam_id = cam_id
				FROM ccInbound
				WHERE Inbound_id  = @inbound_id

			EXEC ccsp_INInsertaCallBack
				@cal_key = @call_Id,
				@cam_id = @cam_id,
				@cal_telefono = @cal_telefono,
				@fechadial = @CallbackAT,
				@dato4 = @result,
				@dato5 = @Observations

			IF EXISTS (SELECT 1 FROM ccTipoCalif WHERE calif_id = @disposition_Id)
			BEGIN
				UPDATE ccCallsIn
				SET calif_id = @disposition_Id
				WHERE cal_id = @call_Id;
			END
		END

		ELSE BEGIN
			INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations,disposition_id)
			VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id);

			IF EXISTS (SELECT 1 FROM ccTipoCalif WHERE calif_id = @disposition_Id)
			BEGIN
				UPDATE ccCallsIn
				SET calif_id = @disposition_Id
				WHERE cal_id = @call_Id;
			END
		END

	END

	ELSE IF @action = 4 AND @status = ''1''   -- Inbound
	BEGIN

		Select @inbound_id = Inbound_id
			From ccCallsIn
			Where cal_id = @call_Id

		Select @trans_status = IsCallTranscriptionEnabled
			From ccInboundExtend
			Where Inbound_id  = @inbound_id

		IF @trans_status = 1
		BEGIN
			INSERT INTO ccCallsInTranscriptionIA (call_id, Transcription)
			VALUES (@call_Id, @Transcription);
		END
	END
END'
	EXEC(@sql)

	SET @process = 'CW-10215 query para insertar las calificaciones de llamadas ia, las cuales si tienen calificación pero se realizaron antes del cambio'
	SET @sql = 'IF OBJECT_ID(''tempdb..#ins'') IS NOT NULL
    DROP TABLE #ins;

CREATE TABLE #ins (
  cal_id    int,
  tipo      BIT,
  calif_id  SMALLINT
);

	INSERT INTO dbo.ccAVRSTransfer (cal_id, tipo, calif_id)
	OUTPUT inserted.cal_id, inserted.tipo, inserted.calif_id
INTO   #ins (cal_id, tipo, calif_id)
SELECT s.call_id, s.tipo, s.disposition_id
FROM (
    SELECT DISTINCT call_id, CONVERT(bit, 0) AS tipo, disposition_id
    FROM dbo.ccCallsInDispositionIA
    UNION ALL
    SELECT DISTINCT call_id, CONVERT(bit, 1) AS tipo, disposition_id
    FROM dbo.ccoCallsOutDispositionIA
) AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.ccAVRSTransfer t
    WHERE t.cal_id = s.call_id
      AND t.tipo = s.tipo
);


UPDATE cco SET cco.calif_id = cat.calif_id FROM dbo.ccoCallsOut AS cco
INNER JOIN  #ins AS cat
ON cat.cal_id = cco.cal_id
AND cat.tipo = 1

UPDATE cci SET cci.calif_id = cat.calif_id FROM dbo.ccCallsIn AS cci
INNER JOIN  #ins AS cat
ON cat.cal_id = cci.cal_id
AND cat.tipo = 0

IF OBJECT_ID(''tempdb..#ins'') IS NOT NULL
    DROP TABLE #ins;'
	EXEC(@sql)

	SET @process = 'CW-10197 Drop procedure ccsp_InsertDNCListWhatsApp'
	SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_InsertDNCListWhatsApp'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_InsertDNCListWhatsApp
		END'
	EXEC(@sql);

		SET @process = 'CW-10197 CREATE STORE PROCEDURE ccsp_InsertDNCListWhatsApp'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCListWhatsApp]
	@telephone as varchar(30),
	@ln_id as integer,
	@hashCalKey bigint=NULL,
	@calKey VARCHAR(40) = NULL

	AS
	SET NOCOUNT ON;


	declare @sqlcmd nvarchar(max), @tmpTableName nvarchar(40), @sqlcmd_replace nvarchar(max),
	@dropTmpPhone nvarchar(max) = null


	if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
	BEGIN
		IF EXISTS (SELECT * from ccListaNegra with(nolock) where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
			RETURN 0;
		end

		set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
		SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

		SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
		[phoneNumber] VARCHAR(30),
		[calKey] VARCHAR(40));

		INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values([dbo].[Limpia](@telephone),@calKey );
		'';
		EXEC (@dropTmpPhone);
		EXEC sp_executesql @sqlcmd, N''@telephone varchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
	END
	else begin
		SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));
	end



	IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
	IF OBJECT_ID(N''tempdb..#myprincipaltempWhatsApp'') IS NOT NULL drop table #myprincipaltempWhatsApp
	IF OBJECT_ID(N''tempdb..#mytempWhatsApp'') IS NOT NULL drop table #mytempWhatsApp
	IF OBJECT_ID(N''tempdb..#helpTempWhatsApp]'') IS NOT NULL drop table #helpTempWhatsApp


	CREATE TABLE [dbo].[#mycamps] ([campsid] [int] NULL )

	CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid])

	insert #mycamps
	select A.cam_id from Camplistanegra A
	Inner join ccCamps B on A.cam_id=B.cam_id
	where A.idtipolista = @ln_id And B.CampType=5 --WhatsApp



	CREATE TABLE [dbo].[#myprincipaltempWhatsApp](
		[WAOut_Id] [bigint] NULL,
		[cam_id] [int] NULL ,
		[tipomov] [int] NULL,
		[idtipolista] [int] NULL,
		[phoneNumber] [varchar] (30) NULL ,
		)

	CREATE CLUSTERED INDEX [IX_myprincipaltempWa] ON [dbo].[#myprincipaltempWhatsApp]([WAOut_Id])
	CREATE NONCLUSTERED INDEX [IX_myprincipaltempWa2] ON [dbo].[#myprincipaltempWhatsApp]([PhoneNumber])


	CREATE TABLE [dbo].[#helpTempWhatsApp](
		[WAOut_Id] [bigint] NULL,
		[cam_id] [int] NULL ,
		[tipomov] [int] NULL,
		[idtipolista] [int] NULL,
		[cal_telefono] [varchar] (30) NULL ,
		)

	CREATE TABLE [dbo].[#mytempWhatsApp](
		[WAOut_Id] [bigint] NULL,
		[telefono] [varchar] (30) NULL ,
		[cam_id] [smallint] NULL ,
		[tipomov] [int] NULL,
		[idtipolista] [int] NULL
	)

	CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempWhatsApp]([WAOut_Id])

	declare @fech datetime = getdate()-30

		SET @sqlcmd = ''
		insert into [#helpTempWhatsApp]
		SELECT a.WAOut_Id as WAOut_Id, a.camId,3, @ln_id as idtipolista, a.PhoneNumber
		FROM [ccWhatsAppOutSource] as a with(nolock)
		inner join #mycamps as b with(nolock) on a.camId = b.campsid
		inner join '' + @tmpTableName +'' t on
		t.phoneNumber IN (a.[SPACE_TEL])  AND t.calKey IS NULL
		where dateDial > @fech
		''

		SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''PhoneNumber'')
		EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;

		SET @sqlcmd = ''
		insert into [#helpTempWhatsApp]
		SELECT a.WAOut_Id as callout_id, a.camId,3, @ln_id as idtipolista, a.PhoneNumber
		FROM [ccWhatsAppOutSource] as a with(nolock)
		inner join #mycamps as b with(nolock) on a.camId = b.campsid
		inner join '' + @tmpTableName +'' t on
		t.phoneNumber IN (a.[SPACE_TEL])  AND t.calKey IS NULL
		where dateDial > @fech''

		SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''PhoneNumber'')
		EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;

		INSERT INTO #myprincipaltempWhatsApp
		SELECT * FROM #helpTempWhatsApp
		GROUP BY WAOut_Id, cam_id, tipomov, idtipolista, cal_telefono

	if EXISTS (select * from #myprincipaltempWhatsApp)
		begin

		declare @column nvarchar(max), @sql nvarchar(max)
		,@sqlDeleteWorking nvarchar(max)
		,@sqlUpdateWorking nvarchar(max)
		,@sqlCaseWorking nvarchar(max)
		,@params nvarchar(max)
		,@phoneEmpty varchar(1)
		,@sqlWithReplace nvarchar(max)

		set @phoneEmpty=''''
		set @column=''PhoneNumber''
		set @params=''@phoneEmpty varchar(1),@fech datetime''
		set @sqlDeleteWorking='' and cs.PhoneNumber=@phoneEmpty''
		set @sqlCaseWorking=''@phoneEmpty''

		set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
		update wt
		set PhoneNumber = CASE_UPDATE_WT
		from ccWhatsAppOutSource cs
		inner join ccoWAWorkingTable wt WITH(NOLOCK) on cs.WAOut_Id = wt.WAOut_Id
		inner join #mytempWhatsApp t on cs.WAOut_id = t.WAOut_id
		where cs.dateDial > @fech and cs.COLUMN_CHECK= wt.PhoneNumber''

		set @sql=''insert #mytempWhatsApp
	select WAOut_Id,mp.COLUMN_CHECK,cam_id,tipomov,idtipolista
	from [#myprincipaltempWhatsApp] mp with(nolock)
	inner join '' + @tmpTableName + '' t on
	t.phoneNumber = mp.COLUMN_CHECK
	where mp.COLUMN_CHECK<>@phoneEmpty

	if EXISTS (select * from #mytempWhatsApp)
	begin
		-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
		delete wt with(rowlock)
		from ccoWAWorkingTable wt
		inner join ccWhatsAppOutSource cs  on wt.WAOut_Id = cs.WAOut_Id
		inner join #mytempWhatsApp t on wt.WAOut_Id = t.WAOut_Id
		where cs.dateDial > @fech and
		cs.COLUMN_CHECK = wt.PhoneNumber
		AND_DELETE_WT

		UPDATE_WT_QUERY

		--insertar el historial
		--insert ccHistoryBlacklistSms (WAOut_Id,Phone,cam_id,movTypeId,listTypeId)
		--select * from #mytempWhatsApp

		-- Eliminamos el telefono1 de CS
		update ccWhatsAppOutSource
		set COLUMN_CHECK = @phoneEmpty
		from ccWhatsAppOutSource cs
		inner join #mytempWhatsApp t on cs.WAOut_Id = t.WAOut_Id
		where cs.dateDial > @fech

		truncate table #mytempWhatsApp
	end''
		/******************/
		/*** Telefono 1 ***/
		/******************/

		set @sqlWithReplace=
		Replace(
		REPLACE(
		REPLACE(
			REPLACE(@sql,''UPDATE_WT_QUERY'',@sqlUpdateWorking),
			''COLUMN_CHECK'',@column)
			,''AND_DELETE_WT'',@sqlDeleteWorking)
			,''CASE_UPDATE_WT'',@sqlCaseWorking
			)
		--print(@sqlWithReplace)
		exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech

	end

	IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
	IF OBJECT_ID(N''tempdb..#myprincipaltempWhatsApp'') IS NOT NULL drop table #myprincipaltempWhatsApp
	IF OBJECT_ID(N''tempdb..#mytempWhatsApp'') IS NOT NULL drop table #mytempWhatsApp
	IF OBJECT_ID(N''tempdb..#helpTempWhatsApp]'') IS NOT NULL drop table #helpTempWhatsApp
	'
	EXEC(@sql)



	set @process = 'K020035 - Detener envío de plantillas que se pausen o desactiven insert messageStatus'
        set @sql = 'if not exists (select * from messageStatus where messageStatusId in(22))
        begin
			SET IDENTITY_INSERT messageStatus ON

            insert into messageStatus (messageStatusId,name, description,isFinished) values (22,''Canceled by system (status change)'', ''Canceled by system due to template status change.'',1)

			SET IDENTITY_INSERT messageStatus OFF

			DBCC CHECKIDENT (''messageStatus'', RESEED, 22)
        end'
        EXEC(@sql)




	SET @process = 'K020035 Se elimina SP ccsp_MetaWAOutboundTemplates'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
		begin
			DROP PROCEDURE ccsp_MetaWAOutboundTemplates;
		end'
	EXEC(@sql)

	SET @process = 'K020035 create SP ccsp_MetaWAOutboundTemplates'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_MetaWAOutboundTemplates]
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
@UserId SMALLINT = 0,
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
        ,cmwan.Cam_Id AS CamId
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan
        ON cmwan.MetaId = cmwot.MetaId
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
        SELECT ISNULL(n.Cam_Id,0) as Cam_Id FROM ccMetaWAOutboundTemplates t
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
        AND (cmwot.StatusCW = 1 OR cmwot.Status <> ''DELETED'')
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
		DECLARE @isRoot BIT = 0; --Fix
		IF EXISTS(SELECT 1 FROM ccUsers_Roles where [User_id] = @UserId and Rol_id = 1)
		BEGIN
			SET @isRoot = 1;
		END

        SELECT  @idAreaNull = cc.IDArea FROM dbo.ccCamps AS cc WHERE cc.cam_id = @campId

        IF(@idAreaNull IS NULL)
        BEGIN
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue eliminada
        END

        IF NOT EXISTS(SELECT TOP 1 crcew.IdCampEsp FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu
        ON crwgu.IDWG = crcew.IDWG
        WHERE  (crwgu.User_id = @UserId OR @isRoot = 1 ) AND crcew.Tipo = 1 AND crcew.IdCampEsp = @campId)
        BEGIN
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue desasignada del grupo de trabajo
        END

        SELECT @campaignIsEliminateDesasigned;
    END
    ELSE IF(@action = 12) --Get new numbers loaded in  ccWhatsAppOutSource
    BEGIN
        SELECT cwt.Callkey, cwt.WAOut_id FROM dbo.ccoWAWorkingTable AS cwt with(nolock)
        WHERE cwt.CamId = @campId AND cwt.WaStatus = 0
        UNION
        SELECT cwaos.CallKey, cwaos.WAOut_Id FROM dbo.ccWhatsAppOutSource AS cwaos with(nolock,index(IX_WASource_1))
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
END'
	EXEC(@sql)


	SET @process = 'K020035 Se elimina SP ccspOutboundWhatsApp'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspOutboundWhatsApp'')
		begin
			DROP PROCEDURE ccspOutboundWhatsApp;
		end'
	EXEC(@sql)

	SET @process = 'K020035 create SP ccspOutboundWhatsApp'
	SET @sql = 'CREATE procedure [dbo].[ccspOutboundWhatsApp]
@action int,
@camId int = null,
@campType int = null,
@templateName varchar(512)=null,
@waMsgIds varchar(max)=null
as
if @action=1 begin
declare @Url as varchar(50)
set @Url = (select Url from ccMetaWhatsAppConfigurations where Id=1)

IF @camId IS NULL AND @campType IS NULL
BEGIN
    select
        distinct
        cast(c. cam_id as int) as CamId,
        cam_descripcion as [Name],
        1 AS CampType,
        cam_procesando as [Start],
        Number as PhoneNumber,
        REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url,
        Token,
        CAST(c.IDArea AS int) as AreaId
    from ccCamps c with(nolock)
    left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
    left join  ccCampsHorarios s ON s.cam_id = c.cam_id
    left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
    WHERE CampType=5 AND c.IDArea IS NOT NULL
    UNION
    SELECT -- load acd
        DISTINCT
        CAST(ci.Inbound_id AS INT) AS CamId,
        ci.descripcion AS [Name],
        0 AS CampType,
        CAST(ci.Status AS BIT) AS [Start],
        cmw.Number AS PhoneNumber,
        REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
        cmw.Token AS Token,
        CAST(ci.IDArea AS int) as AreaId
    FROM ccInbound ci WITH(NOLOCK)
    LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
    LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
    WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL
END
ELSE IF @campType IS NOT NULL
BEGIN
    IF @campType = 0
    BEGIN
        SELECT -- load acd
            DISTINCT
            CAST(ci.Inbound_id AS INT) AS CamId,
            ci.descripcion AS [Name],
            0 AS CampType,
            CAST(ci.Status AS BIT) AS [Start],
            cmw.Number AS PhoneNumber,
            REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
            cmw.Token AS Token,
            CAST(ci.IDArea AS int) as AreaId
        FROM ccInbound ci WITH(NOLOCK)
        LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
        LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
        WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL AND (@camId IS NULL or @camId=0 OR ci.Inbound_id = @camId)
    END
    ELSE
    BEGIN
        select
            distinct
            cast(c. cam_id as int) as CamId,
            cam_descripcion as [Name],
            1 AS CampType,
            cam_procesando as [Start],
            Number as PhoneNumber,
            REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url,
            Token,
            CAST(c.IDArea AS int) as AreaId
        from ccCamps c with(nolock)
        left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
        left join  ccCampsHorarios s ON s.cam_id = c.cam_id
        left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
        WHERE CampType=5 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
    END
END

end
else if @action=2 begin -- cargar valores del template para envio manual
    SELECT TOP 1
        A.id AS Id
       ,A.LanguageCode AS LanguageCode
       ,B.Number AS Number
       ,ISNULL(A.header, '''') AS Header
       ,ISNULL(A.body, '''') AS Body
       ,ISNULL(A.footer, '''') AS Footer
       ,ISNULL(A.buttons, '''') AS Buttons
       ,ISNULL(A.headerLink, '''') AS HeaderLink
    FROM ccMetaWAOutboundTemplates A
    INNER JOIN ccMetawhatsAppNumbers B ON B.MetaId = A.MetaId
    WHERE A.TemplateName = @templateName
    AND B.Cam_Id = @camId

end
else if @action=3 begin
declare @sql varchar(max)
    set @sql=''delete from ccoWAWorkingTable with(rowlock) where WAOut_id in(''+@waMsgIds+'')''
    exec (@sql)
END
ELSE IF @action = 4 BEGIN
    SELECT cmwot.Id AS Message_Template_Id, cmwot.Status AS Event  FROM dbo.ccMetaWAOutboundTemplates AS cmwot
    INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan
    ON cmwan.MetaId = cmwot.MetaId
    WHERE cmwot.Status IN (''PAUSED'', ''DISABLED'') AND cmwan.Cam_Id = @camId
END
'
	EXEC(@sql)




------------------------------------------ END MAGV 20250905.0.2   ------------------------------
    ------------------------------------------------BEGIN MD 20250905.0.3 -----------------------------------------------
    SET @process = 'Drop procedure ccsp_RIALoadCamps'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIALoadCamps'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_RIALoadCamps
    END'
EXEC(@sql);

SET @process = 'Se agrega  and a1.IDArea is not null en @option 2 para no omstrar campañas salida eliminadas'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todas las campa?as
BEGIN
    SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND a1.cam_id IN (
            SELECT cam_id
            FROM dbo.fGet_CampAcd_Area(@Sup, 1)
            )
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 2 -- Campa?as de un Area
BEGIN
    SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG, CASE WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 WHEN a1.CampType = 9 then 10 ELSE ISNULL(a1.CampType, 0) END as mode
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    ORDER BY cam_descripcion

    RETURN (0)
END

IF @option = 3 -- Campa?as por Supervisor
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
    WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 4 -- Rels Camps-Agents
BEGIN
    SELECT @loginDays = valor
    FROM ccSettings
    WHERE setting_id = 211 --Numero dias que cargara las relaciones

    SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
    FROM (
        SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
        FROM ccCamps C
        JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
        JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
        JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
        JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
        WHERE C.cam_id IN (
                SELECT cam_id
                FROM ccsupervisorcam
                WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
                )
        ) Relations
    GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
    ORDER BY User_id, cam_descripcion, cam_id, Prioridad

    RETURN (0)
END

IF @option = 5 -- Campa?as por Supervisor
BEGIN
    SELECT @AreaId = IDArea
    FROM ccUsers
    WHERE User_id = @sup

    SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, ''12345NNN'') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
    FROM ccCamps Camps
    LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
    LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
    JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
    JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
    WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
            SELECT cam_id
            FROM ccSupervisorCam
            WHERE tipo = 1 AND user_id = @sup
            ) AND Camps.IDArea = @AreaId
    ORDER BY 5, cam_procesando DESC, cam_descripcion

    RETURN (0)
END

IF @option = 7 -- Una sola
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 8 -- Campa?as de un Agente
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
    WHERE a3.type_id = 1 AND a4.user_id = @Sup
    ORDER BY 2

    RETURN (0)
END
IF @option = 9 -- Campa?as de un Area
BEGIN
    (SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,
	1 CamType,
    ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
    CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.CampType = 4 THEN 4 WHEN a1.CampType = 5 THEN 5 WHEN a1.CampType=7 THEN 7 WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 WHEN a1.CampType = 9 THEN 10  ELSE 0 END as [tinyint]) [MediaType]
	FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)

    UNION
    SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType,
    ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG,
    b1.chat [MediaType]
    FROM ccinbound b1
    JOIN ccRIAinboundGraph b2 ON b1.inbound_id = b2.inbound_id
    INNER JOIN ccRIAGraphics b3 ON b2.graphic_id = b3.graphic_id
    LEFT JOIN (
        SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
        FROM ccSkills
        GROUP BY inbound_id
        ) S ON S.Inbound_id = b1.inbound_id
    WHERE b3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    ) ORDER BY camtype desc,cam_descripcion

    RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF
'

EXEC(@sql);


SET @process = 'Drop procedure ccsp_RIALoadACDGroups'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIALoadACDGroups'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_RIALoadACDGroups
    END'
EXEC(@sql);

SET @process = 'Se agrega  and a1.IDArea is not null en @option 2 para no omstrar campañas entrada eliminadas'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIALoadACDGroups] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @inbound_id INT = 0, @tipoModalidad TINYINT = 0 -- llamada 0, chat 1 y ambos 2
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todas los ACDGroups
BEGIN
	SELECT a1.inbound_id, descripcion, frame, isnull(IDArea, 0)
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON (a1.inbound_id = a2.inbound_id)
	JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	WHERE a3.type_id = 1
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 2 -- ACDGroups de un Area
BEGIN
	SELECT DISTINCT a1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.inbound_id, 2) relationsWG, a1.chat mode, skillDif
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	INNER JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	LEFT JOIN (
		SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
		FROM ccSkills
		GROUP BY inbound_id
		) S ON S.Inbound_id = a1.inbound_id
	WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 3 -- ACDGroups por Supervisor
BEGIN
	SELECT DISTINCT a1.inbound_id, descripcion, frame, isnull(IDArea, 0) AS IDArea, U.monitored, a1.chat mode
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccSupervisorCam U ON a1.inbound_id = U.cam_id
	WHERE U.user_id = @sup AND tipo = 0 AND a3.type_id = 1 AND a1.inbound_id IN (
			SELECT cam_id
			FROM dbo.fGet_CampAcd_Area(@Sup, 2)
			)
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 4 -- Rels ACD-Agents
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT inbound_id, descripcion, User_id, LOGIN, skill, prioridad, IDArea, min(rel_id) rel_id
	FROM (
		SELECT E.inbound_id, E.descripcion, A.User_id, A.LOGIN, G.skill, G.prioridad, isnull(E.IDArea, 0) IDArea, G.rel_id
		FROM ccinboundAgentes G
		JOIN ccinbound E ON G.inbound_id = E.inbound_id
		JOIN ccUsers A ON A.User_id = G.User_id AND A.TipoUser_Id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
		WHERE E.inbound_id IN (
				SELECT cam_id
				FROM ccsupervisorcam
				WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 0
				)
		) AS Relations
	GROUP BY inbound_id, descripcion, User_id, LOGIN, skill, prioridad, IDArea
	ORDER BY User_id, inbound_id, descripcion, prioridad

	RETURN (0)
END

IF @option = 5 -- Todos los ACDGroups
BEGIN
	option5:

	SELECT a1.inbound_id, descripcion, frame, isnull(IDArea, 0)
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 7 -- Un solo ACDGroups
BEGIN
	SELECT a1.inbound_id, descripcion, frame, isnull(IDArea, 0)
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1 AND STATUS = 1 AND a1.inbound_id = @inbound_id
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 8 -- ACDGroups de un Agente
BEGIN
	SELECT DISTINCT a1.inbound_id, a1.descripcion, a3.frame
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccInboundAgentes a4 ON a1.inbound_id = a4.inbound_id
	WHERE a3.type_id = 1 AND a4.user_id = @Sup
	ORDER BY 2

	RETURN (0)
END

IF @option = 9 -- ACDGroups por Supervisor para mensajes llamadas o chat filtra las campaÃ±as
BEGIN
	SELECT DISTINCT a1.inbound_id, descripcion, frame, isnull(IDArea, 0) AS IDArea, U.monitored
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccSupervisorCam U ON a1.inbound_id = U.cam_id
	WHERE U.user_id = @sup AND tipo = 0 AND a3.type_id = 1 AND a1.inbound_id IN (
			SELECT cam_id
			FROM dbo.fGet_CampAcd_Area(@Sup, 2)
			) AND a1.chat IN (2, @tipoModalidad)
	ORDER BY descripcion

	RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF'

EXEC(@SQL);

    ------------------------------------------------END MD 20250905.0.2-----------------------------------------------

	SET @process = 'Alter SP ccsp_GalateaMenuReporte Correcion agregar submenu del submenu'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaMenuReporte]
    @action SMALLINT,
    @Rol_id VARCHAR(MAX) = NULL,
    @id_User VARCHAR(MAX) = NULL,
    @menu_id VARCHAR(MAX) = NULL,
    @ids_list VARCHAR(MAX) = NULL,
    @IsAdminsIds BIT = NULL,
    @RowsAffected INT = @@ROWCOUNT
AS

BEGIN
    DECLARE @userId TABLE (userId INT PRIMARY KEY);
    DECLARE @menuIds TABLE (menu_id INT, type INT, PRIMARY KEY(menu_id,type));
    DECLARE @ccmenusAndUserId TABLE (menu_id INT, userId INT, type INT);
    SET NOCOUNT ON;

    IF @action in (3,4) begin
     -- Poblar los IDs de usuario
        INSERT INTO @userId
        SELECT Value
        FROM dbo.fn_RIASplitDelimited(@ids_list, '','');

        -- Poblar los IDs de menú
        INSERT INTO @menuIds
        SELECT Value, 3
        FROM dbo.fn_RIASplitDelimited(@menu_id, '','');

        ;WITH menusWithSubMenu AS (
                SELECT A.menu_id, A.type
                FROM ccMenus A
                INNER JOIN @menuIds B ON A.parent = B.menu_id AND A.type = B.type
                UNION
                SELECT A.menu_id, A.type
                FROM ccMenus A
                INNER JOIN @menuIds B ON A.menu_id = B.menu_id AND A.type = B.type
            )

        insert into @ccmenusAndUserId
        SELECT M.menu_id, U.userId,  M.type
        FROM @userId U
        CROSS JOIN menusWithSubMenu M

    end

    IF @action = 1
    --Busca el id rol y regresa todos los menu id que tenga relacionados
    BEGIN
        IF @IsAdminsIds = 0
        BEGIN
            SELECT distinct CAST(menu_id as int) as MenuID --0 as RolID, 0 as type
            FROM ccMenuRol
            WHERE (Rol_id IN(Select Value from dbo.fn_RIASplitDelimited(@Rol_id, '','')))
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(id_Menu AS INT) as MenuID
            FROM ccMenuUser
            WHERE (id_User = @id_User) and type = 3 and id_Menu not in (1000, 1010);
        END
    END;

    IF @action = 2
    --Manda la información faltante para que el Front sepa todos los menus
    BEGIN

        SELECT CAST(menu_id as int) as MenuID, menu_descrip as MenuDesc, CAST(parent as int) as Parent
        FROM ccMenus
        WHERE parent IN (
            2000, 3000, 3140, 4000, 3130, 10000, 11000, 12000,
            6000, 8000, 8050, 8060, 8080, 7000, 13000, 14000
        )
        AND type = 3
        AND menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030)
    END;

    ELSE IF @action = 3
    --Guarda información ya sea en la tabla ccMenuUser o ccMenuRol
    BEGIN
        IF @IsAdminsIds  = 0
        BEGIN
            INSERT INTO ccMenuRol(menu_id, Rol_id, type)
            select A.menu_id,A.userId as Rol_id,A.type  from @ccmenusAndUserId A
            left join ccMenuRol M on A.menu_id=M.menu_id and A.type=M.type and A.userId=M.Rol_id
            where M.Rol_id is null

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se insertaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
        ELSE
        BEGIN

            insert into ccMenuUser(id_User,id_Menu,type)
            select A.userId,A.menu_id,A.type  from @ccmenusAndUserId A
            left join ccMenuUser M on A.menu_id=M.id_Menu and A.type=M.type and A.userId=M.id_User
            where M.id_Menu is null


            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se insertaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
    END;


ELSE IF @action = 4
    --Elimina información ya sea en la tabla ccMenuUser o ccMenuRol
    BEGIN
        IF @IsAdminsIds = 0
        BEGIN
            Delete M from @ccmenusAndUserId A
            left join ccMenuRol M on A.menu_id=M.menu_id and A.type=M.type and A.userId=M.Rol_id

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se eliminaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
        ELSE
        BEGIN
            delete M from @ccmenusAndUserId A
            left join ccMenuUser M on A.menu_id=M.id_Menu and A.type=M.type and A.userId=M.id_User

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se eliminaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
    END;
    IF @action = 5
    --Busca el id rol y regresa todos los menu id que tenga relacionados
    BEGIN
        IF @IsAdminsIds = 0
        BEGIN
            SELECT distinct CAST(menu_id as int) as MenuID --0 as RolID, 0 as type
            FROM ccMenuRol
            WHERE (Rol_id IN(Select Value from dbo.fn_RIASplitDelimited(@ids_list, '','')))
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(id_Menu AS INT) as MenuID
            FROM ccMenuUser
            WHERE (id_User = @ids_list) and type = 3 and id_Menu not in (1000, 1010);
        END
    END;
END;
'
	EXEC(@sql)


	------------------------------- BEGIN MAGV 20250905.0.5---------------------------------------------------------------------------------
	SET @process = 'Listas negras historial Add dd values in GalateaIdentifiersTable and GalateaModules'
	SET @sql = '

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers AS cgm WHERE cgm.Description = ''DNC_EDIT_NAME_LIST'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt)
			VALUES(''DNC_EDIT_NAME_LIST'', ''Nombre'', ''Name'', ''Nome'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers AS cgm WHERE cgm.Description = ''OUT_SELECT_ANI_MANUAL_DIALING'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt)
			VALUES(''OUT_SELECT_ANI_MANUAL_DIALING'', ''Aplicar modalidad de ANI en marcación manual'', ''Apply ANI mode to manual dialing'', ''Aplicar modalidade de ANI à discagem manual'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers AS cgm WHERE cgm.Description = ''OUT_ANI_MODE_MANUAL'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt)
			VALUES(''OUT_ANI_MODE_MANUAL'', ''Modalidad de ANI (llamada manual)'', ''ANI mode (manual call)'', ''Modalidade de ANI (chamada manual)'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers AS cgm WHERE cgm.Description = ''OUT_ANI_LIST_MANUAL'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt)
			VALUES(''OUT_ANI_LIST_MANUAL'', ''Lista de ANI (llamada manual)'', ''ANI list (manual call)'', ''Lista de ANI (chamada manual)'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaModules AS cgm WHERE cgm.ModuleId = 26)
		BEGIN
		INSERT INTO dbo.ccGalateaModules
		(
			ModuleId,
			MTagEs,
			MTagEn,
			MTagPt
		)
		VALUES
		(   26,  -- ModuleId - int
			''Listas negras'', -- MTagEs - varchar(250)
			''DNC lists'', -- MTagEn - varchar(250)
			''Listas negras''  -- MTagPt - varchar(250)
			);
		END


		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 147)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (147, N''Crear lista negra'', N''Create DNC list'', N''Criar lista negra'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Crear lista negra'', OpTagEn = N''Create DNC list'', OpTagPt = N''Criar lista negra'' where OperationId = 147
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 148)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (148, N''Editar lista negra'', N''Edit DNC list'', N''Editar lista negra'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Editar lista negra'', OpTagEn = N''Edit DNC list'', OpTagPt = N''Editar lista negra'' where OperationId = 148
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 149)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (149, N''Eliminar lista negra'', N''Delete DNC list'', N''Excluir lista negra'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Eliminar lista negra'', OpTagEn = N''Delete DNC list'', OpTagPt = N''Excluir lista negra'' where OperationId = 149
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 150)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (150, N''Cargar lista de teléfonos'', N''Load list of phone numbers'', N''Carregar lista de telefones'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Cargar lista de teléfonos'', OpTagEn = N''Load list of phone numbers'', OpTagPt = N''lista de telefones'' where OperationId = 150
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 151)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (151, N''Asignar lista negra a campaña'', N''Assign DNC list to campaign'', N''Atribuir lista negra a campanha'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Asignar lista negra a campaña'', OpTagEn = N''Assign DNC list to campaign'', OpTagPt = N''Atribuir lista negra a campanha'' where OperationId = 151
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 152)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (152, N''Desasignar lista negra de campaña'', N''Unassign DNC list from campaign'', N''Cancelar atribuição de lista de campanha'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Desasignar lista negra de campaña'', OpTagEn = N''Unassign DNC list from campaign'', OpTagPt = N''Cancelar atribuição de lista de campanha'' where OperationId = 152
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 153)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (153, N''Asignar lista negra a calificación'', N''Assign DNC list to disposition'', N''Atribuir lista negra a classificação'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Asignar lista negra a calificación'', OpTagEn = N''Assign DNC list to disposition'', OpTagPt = N''Atribuir lista negra a classificação'' where OperationId = 153
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 154)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (154, N''Cargar teléfono individual'', N''Load single phone number'', N''Carregar telefone individual'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Cargar teléfono individual'', OpTagEn = N''Load single phone number'', OpTagPt = N''Carregar telefone individual'' where OperationId = 154
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 155)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (155, N''Eliminar teléfono individual'', N''Remove single phone number'', N''Remover telefone individual'');
		END
		ELSE
		BEGIN
			update ccGalateaOperations set OpTagES = N''Eliminar teléfono individual'', OpTagEn = N''Remove single phone number'', OpTagPt = N''Remover telefone individual'' where OperationId = 155
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 156)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (156, N''Desasignar lista negra de calificación'', N''Unassign DNC list from disposition'', N''Cancelar atribuição de lista de classificação'');
		END
		BEGIN
			update ccGalateaOperations set OpTagES = N''Desasignar lista negra de calificación'', OpTagEn = N''Unassign DNC list from disposition'', OpTagPt = N''Cancelar atribuição de lista de classificação'' where OperationId = 156
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 172)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (172, N''Actualizar lista de teléfonos'', N''Update list of phone numbers'', N''Atualizar lista de telefones'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaOperations WHERE OperationId = 173)
		BEGIN
			INSERT INTO dbo.ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (173, N''Eliminar lista de teléfonos'', N''Remove list of phone numbers'', N''Remover lista de telefones'');
		END

		  IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=147)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 147)
		END

		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=148)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 148)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=149)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 149)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=150)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 150)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=151)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 151)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=152)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 152)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=153)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 153)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=154)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 154)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=155)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 155)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=156)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 156)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=172)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 172)
		END
		IF NOT EXISTS(SELECT OperationId FROM ccGalateaModOpRelation WHERE OperationId=173)
		BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (26, 173)
		END
	'
    EXEC(@sql)

	SET @process = 'KR234005 add table column relations to history';
SET @sql = 'IF NOT EXISTS (
			SELECT * FROM relationTableColumnIdentifiers
			WHERE Identifiers = ''OUT_ANI_MODE_MANUAL'' AND tableName = ''ccCamps''
			and colunName = ''rotativeAlgorithmManual''
		)
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''OUT_ANI_MODE_MANUAL'', ''ccCamps'', ''rotativeAlgorithmManual'')
		END

		IF NOT EXISTS (
			SELECT * FROM relationTableColumnIdentifiers
			WHERE Identifiers = ''OUT_ANI_LIST_MANUAL'' AND tableName = ''ccCamps''
			and colunName = ''idAniListManual''
		)
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''OUT_ANI_LIST_MANUAL'', ''ccCamps'', ''idAniListManual'')
		END

		IF NOT EXISTS (
			SELECT * FROM relationTableColumnIdentifiers
			WHERE Identifiers = ''OUT_SELECT_ANI_MANUAL_DIALING'' AND tableName = ''ccCamps''
			and colunName = ''selectRotationManualDialing''
		)
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''OUT_SELECT_ANI_MANUAL_DIALING'', ''ccCamps'', ''selectRotationManualDialing'')
		END
		';

EXEC(@sql);



	--------------------------------- END MAGV 20250905.0.5 -----------------------------------
    --------------------------------- BEGIN HCR 20250905.0.6-----------------------------------
	SET @process = 'Z3500 Constraint a la tabla ccCampsExtend con valor default en 0  '
	SET @sql = 'if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccCampsExtend_zipCodeSchedule'')
                begin
                    ALTER TABLE dbo.ccCampsExtend ADD CONSTRAINT
                    DF_ccCampsExtend_zipCodeSchedule DEFAULT 0 FOR [zipCodeSchedule]
                end
                '
	EXEC(@sql)
	--------------------------------- END HCR 20250905.0.6 ------------------------------------------------

       --------------------------------- BEGIN Gallardo 20250905.0.6-----------------------------------
    SET @process = 'ALTER PROCEDURE [dbo].[ccspCCserverLoadCamp] se agerga ccVirtualAgent camtype=1 para solo campañas de salida'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspCCserverLoadCamp]
            @Type as smallint
            AS
            BEGIN
                DECLARE @sql NVARCHAR(max)

                SET @sql = ''SELECT
                                c.cam_id
                            ,ISNULL(g.graphic_id, 1) graphic_id
                            ,c.cam_descripcion
                            ,c.cam_tnotas
                            ,c.cam_maxqueue
                            ,c.cam_procesando
                            ,c.CampType
                            ,ISNULL(v.idAgent, 0) AS IdAgentVirtual
                            ,ISNULL(v.nameAgent, '''''''') AS NameAgentVirtual
                            ,ISNULL(v.concurrentSessionsLimit, 0) AS AgtVirtual
                            FROM ccCamps c (NOLOCK)
                            LEFT JOIN ccRIACampsGraph g (NOLOCK) ON g.cam_id = c.cam_id
                            LEFT JOIN ccVirtualAgent v (NOLOCK) ON v.idCampaign = c.cam_id and v.campType=1
                            WHERE cam_activo = 1''

                IF @Type<>1 BEGIN
                    SET @sql = @sql + '' AND cam_bNew=2''
                END
                EXEC (@sql)
            END
        '
    EXEC(@sql)


     SET @process = '#3138 ALTER PROCEDURE [dbo].[ccsp_RIAACDCallParams] valor default'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAACDCallParams]
            @option int,
            @campId int = 0
            AS
            BEGIN
                SET NOCOUNT ON;
            declare @RecordCalls tinyint
            set @RecordCalls=0
            if(@option = 1)
            begin
                select @RecordCalls= RecordCalls from ccInboundExtend where Inbound_id = @campId
            end

            else if(@option = 2)
            begin
                select @RecordCalls= RecordCalls from ccCampsExtend where cam_id = @campId
            end
            select isnull(@RecordCalls,1) RecordCalls

                SET NOCOUNT OFF;
            END
        '
    EXEC(@sql)
    --------------------------------- END Gallardo 20250905.0.6 ------------------------------------------------

	------------------------------------------ Daniel Hernandez ------------------------------------------------
	SET @process = '#3271-KM24001 Setting for record load marking restriction'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM [dbo].[ccSettings2] WHERE [setting_id] = 291)
	BEGIN
		INSERT INTO [dbo].[ccSettings2]
			   ([setting_id]
			   ,[valor]
			   ,[descripcion]
			   ,[Status]
			   ,[Tipo]
			   ,[detalle]
			   ,[description]
			   ,[bLoadSettings]
			   ,[validate])
		 VALUES
			   (291
			   ,''0''
			   ,''Restricción de carga de registros en campañas de voz estándar''
			   ,1
			   ,''ADM''
			   ,''0:(Default)No se deberá poder cargar bases de datos a campañas al menos que la campaña se encuentre apagada. |1:Se deberá permitir la carga de bases de datos a las campañas iniciadas desde los botones o secciones ya disponibles en el sitio.''
			   ,''0:(Default) Database uploads should not be allowed to campaigns unless the campaign is turned off |1: Database uploads should be allowed to campaigns started from buttons or sections already available on the site''
			   ,1
			   ,''.*'')
	END'
    EXEC(@sql)
	------------------------------------------------------------------------------------------------------------

	------------------------------------------ Daniel Hernandez ------------------------------------------------
	SET @process = '#3823-Agentes no reciben llamadas en Vista Previa'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
		@option     INT        = NULL,
		@callout_id INT        = NULL,
		@user_id    SMALLINT   = NULL
	AS
	BEGIN
		SET NOCOUNT ON;

		IF (@option = 1 OR @option IS NULL)
		BEGIN
			SELECT
				previewData =
					CONCAT(
						CASE WHEN U.AllowDeleteRecord = 1 THEN ''true'' ELSE ''false'' END, ''~'',
						COALESCE(P.Headers, ''Data1|Data2|Data3|Data4|Data5|Data6|Data7|Data8|Data9|Data10|Data11|Data12|Data13|Data14|Data15''), ''~'',
						O.Dato1,  ''~'',
						O.Dato2,  ''~'',
						O.Dato3,  ''~'',
						O.Dato4,  ''~'',
						O.Dato5,  ''~'',
						P.Dato6,  ''~'',
						P.Dato7,  ''~'',
						P.Dato8,  ''~'',
						P.Dato9,  ''~'',
						P.Dato10, ''~'',
						P.Dato11, ''~'',
						P.Dato12, ''~'',
						P.Dato13, ''~'',
						P.Dato14, ''~'',
						P.Dato15, ''~'',
						O.cal_telefono2, ''~'',
						O.cal_telefono3, ''~'',
						O.cal_telefono4, ''~'',
						O.cal_telefono5, ''~'',
						CONVERT(VARCHAR(50), O.cal_Key),      ''~'',
						CONVERT(VARCHAR(50), O.cal_telefono), ''~'',
						S.typePreview, ''~''
					),
				previewDiscard = C.previewDiscard,
				previewUpdate  = CE.EditableContactData
			FROM ccoCallsOutSource AS O WITH (NOLOCK)
			INNER JOIN ccCamps        AS C  WITH (NOLOCK) ON O.cam_id = C.cam_id
			INNER JOIN ccCampsExtend  AS CE WITH (NOLOCK) ON C.cam_id  = CE.cam_id
			LEFT JOIN  ccoCallsPreviewData AS P WITH (NOLOCK)
				   ON  P.Cal_key = O.cal_Key
				   AND P.cam_id  = O.cam_id
			OUTER APPLY (
				SELECT TOP (1) U.AllowDeleteRecord
				FROM ccUsers AS U WITH (NOLOCK)
				WHERE U.User_id = @user_id
				  AND U.TipoUser_id = 1
			) AS U
			OUTER APPLY (
				SELECT TOP (1) S.valor AS typePreview
				FROM ccSettings AS S WITH (NOLOCK)
				WHERE S.setting_id = 248
				  AND S.Status = 1
				ORDER BY S.setting_id
			) AS S
			WHERE O.callout_id = @callout_id;
		END
		ELSE IF (@option = 2)
		BEGIN
			SELECT COUNT(*)
			FROM ccoCallsOutSource WITH (NOLOCK)
			WHERE callout_id = @callout_id;
		END

		SET NOCOUNT OFF;
	END'
    EXEC(@sql)
	----------------------------------------------------------------------------
	SET @process = '#3823-Agentes no reciben llamadas en Vista Previa'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
		@action INT,
		@tableName NVARCHAR(255),
		@cal_status int = 0,
		@idLoad int=0,
		@motivo varchar(50)=null,
		@cam_id int=null,
		@isIAQuantumCamp bit =0,
		@internationalRecords int=0

	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @sql NVARCHAR(MAX);
		DECLARE @paramDef NVARCHAR(300);
		DECLARE @count INT;
		declare @emtpy varchar(1)='''',@zipCodeSchedule bit
		declare @columnsIAQuntum varchar(max)=''''

		IF @action = 1
		BEGIN
			SET @sql = ''
			UPDATE '' + QUOTENAME(@tableName) + ''
			SET international = 1'';

			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 2
		BEGIN

			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum='', data_api_quantum, data_overflow_variables_quantum''
			end

			SET @sql = ''
			INSERT INTO dbo.ccoCallsOutSource (
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			)
			SELECT
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			FROM '' + QUOTENAME(@tableName) + ''
			WHERE callout_id = 0'';

			EXEC sp_executesql @sql;
		END

		ELSE IF @action = 3
		BEGIN
			SET @sql = ''
			INSERT INTO dbo.ccoCallsPreviewData (
				cal_Key, cam_id, TotalData, Headers,
				Dato6, Dato7, Dato8, Dato9, Dato10,
				Dato11, Dato12, Dato13, Dato14, Dato15
			)
			SELECT
				A.cal_Key, A.cam_id, A.TotalData, A.Headers,
				A.Dato6, A.Dato7, A.Dato8, A.Dato9, A.Dato10,
				A.Dato11, A.Dato12, A.Dato13, A.Dato14, A.Dato15
			FROM '' + QUOTENAME(@tableName) + '' A
			left join ccoCallsPreviewData B on A.cal_Key=B.cal_Key and A.cam_id=B.cam_id
			WHERE B.cam_id is null;
			'';

			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 4
		BEGIN
			SET @sql = ''
			UPDATE C SET
				C.Headers = A.Headers,
				C.TotalData = A.TotalData,
				C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
				C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
			FROM '' + QUOTENAME(@tableName) + '' A
			INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
				ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
			'';

			EXEC sp_executesql @sql;
		END
		ELSE IF @action =5
		BEGIN
			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum='', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum''
			end

			SET @sql = ''
			UPDATE C SET
				C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
				C.cal_telefono = A.cal_telefono,
				C.cal_telefono2 = A.cal_telefono2,
				C.cal_telefono3 = A.cal_telefono3,
				C.cal_telefono4 = A.cal_telefono4,
				C.cal_telefono5 = A.cal_telefono5,
				C.Dato1 = A.Dato1,
				C.Dato2 = A.Dato2,
				C.Dato3 = A.Dato3,
				C.Dato4 = A.Dato4,
				C.Dato5 = A.Dato5,
				C.dialPrefix = A.dialPrefix,
				C.list_id = A.list_id,
				C.cal_fechaDial = case when ISNULL(B.cal_status, 0) = 1 then C.cal_fechaDial else A.cal_fechaDial end,
				C.Region = A.Region,
				C.Localidad = A.Localidad,
				C.international = A.international,
				C.recycledByResult = @emtpy,
				C.recycledByDisposition = 0,
				C.recyclePhone = 0,
				C.recycleType = 1
				,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
				,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
				,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
				,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
				,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
			INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id'';

			SET @paramDef = N''@cal_status_param TINYINT, @emtpy varchar(1)'';
			EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @emtpy= @emtpy;
		END
		ELSE IF @action = 6
		BEGIN
			DECLARE @today DATE = CONVERT(DATE, GETDATE());

			SET @sql = ''
		UPDATE B
		SET B.list_id = A.list_id
		FROM '' + QUOTENAME(@tableName) + '' A
		INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
		INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
		WHERE B.list_id <> A.list_id;


		  UPDATE ld WITH (ROWLOCK) SET ld.canBeRecycled = 0
		  FROM '' + QUOTENAME(@tableName) + '' t
		  LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		  INNER JOIN ccoLogDials ld WITH (ROWLOCK, UPDLOCK, INDEX(IX_LogDials_cam_tipo_fecha_callout)) ON ld.cam_id = t.cam_id and ld.callout_id = t.callout_id
		  WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled=1 or ld.canBeRecycled is null);

		  UPDATE co WITH (ROWLOCK) SET co.canBeRecycled = 0
		  FROM '' + QUOTENAME(@tableName) + '' t
		  LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		  INNER JOIN ccoCallsOut co WITH (ROWLOCK, UPDLOCK) ON co.callout_id = t.callout_id
		  WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled=1 or co.canBeRecycled is null);
		  '';
			--print(@sql)
			EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
		END
		ELSE IF @action = 7
		BEGIN

			-- Contar registros inválidos
			SET @sql = ''
			SELECT @cnt = COUNT(*)
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL and A.callout_id > 0;'';

			EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

			-- Insertar en ccRIALogPhones los registros sin match
			SET @sql = ''
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, A.cal_Key, @emtpy, 2, @motivo,@internationalRecords
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC sp_executesql @sql,
				N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@emtpy=@emtpy;

			-- Eliminar los registros sin match
			SET @sql = ''
			DELETE A
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC(@sql);

			-- Retornar el count como resultado
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 8
		BEGIN


			-- Contar total de registros antes del borrado
			SET @sql = ''
			SELECT @cnt = COUNT(*) FROM '' + QUOTENAME(@tableName) + '';'';

			EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

			-- Log en ccRIALogPhones todos los registros de la tabla temporal
			SET @sql = ''
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, cal_Key, @emtpy, 2, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

			EXEC sp_executesql @sql,
					N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@emtpy=@emtpy;

			-- Eliminar todos los registros de la tabla temporal
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
			EXEC(@sql);

			-- Retornar el número de registros eliminados
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 9 BEGIN

			DECLARE @country TINYINT;
			SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
			if @country =1 begin
				select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id =@cam_id
			end
			if @zipCodeSchedule is null begin
				set @zipCodeSchedule=0
			end

			SET @sql = ''
		UPDATE T SET
			iZonaHoraria = CASE
				WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

			iZonaHoraria_verano = CASE
			  WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

			iZonaHoraria2 = CASE
				WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

			iZonaHoraria_verano2 = CASE
			  WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

			iZonaHoraria3 = CASE
				WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

			iZonaHoraria_verano3 = CASE
			  WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

			iZonaHoraria4 = CASE
				WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

			iZonaHoraria_verano4 = CASE
			  WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

			iZonaHoraria5 = CASE
				WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

			iZonaHoraria_verano5 = CASE
			  WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

		FROM '' + QUOTENAME(@tableName) + '' T
		OUTER APPLY dbo.fnGetTimeZoneByZip(T.Dato1) AS Z
		''
		EXEC sp_executesql @sql,
				N''@zipCodeSchedule bit,@country TINYINT,@emtpy varchar(1)'',
				@zipCodeSchedule = @zipCodeSchedule,
				@country = @country,
				@emtpy = @emtpy

		--print(@sql)
		END
		ELSE IF @action = 10
		BEGIN
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE callout_id = 0;'';
			EXEC sp_executesql @sql;
		END
		 ELSE IF @action = 11 BEGIN

			SET @sql = ''
		UPDATE T SET
			international=@internationalRecords
		FROM '' + QUOTENAME(@tableName) + '' T
		''
		EXEC sp_executesql @sql,
				N''@internationalRecords int'',
				@emtpy = @emtpy

		END


		ELSE
		BEGIN
			RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
			RETURN;
		END
	END'
    EXEC(@sql)

	------------------------------------------------------------------------------------------------------------

    ------------------------------------- BEGIN JUAN MEDINA -----------------------------------------

   	SET @process = 'Drop procedure ccsp_Limpia'
	SET @sql = '
		IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_Limpia'')
		BEGIN
			DROP PROCEDURE ccsp_Limpia;
		END
	'
	EXEC(@sql);

	SET @process = 'Create procedure ccsp_Limpia'

	SET @sql = '

		CREATE PROCEDURE ccsp_Limpia @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = '''', @dato1 VARCHAR(10) = ''''
		AS
		SET NOCOUNT ON

		DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
		DECLARE @checkLd_In_ANILst SMALLINT = 0
		/***
		 4  as res lista Negra
		 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
		 3 as res Number notExists
		 1 as res Longitud invalida
		 0 as res Numero correcto

		***/
		SELECT @tel = dbo.limpia(@tel)

		SELECT @lon = len(@tel)

		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104

		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17

		SELECT @extLen = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 108

		SELECT @validateTel = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 206

		SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213


		IF @lon > 1
		BEGIN

			IF @validateTel = 2
				BEGIN --Setting 206 only validates blacklist

					IF (SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)) = 1
					BEGIN
						SELECT 4 AS res, @tel AS tel --blackList
						RETURN (0)
					END
					SELECT 0 AS res, @tel AS tel

					RETURN (0)

			END
			IF @validateTel = 1
			BEGIN --Setting 206 para no validar longitud ni listas negras
				SELECT 0 AS res, @tel AS tel

				RETURN (0)
			END

			IF @extLen = @lon
			BEGIN -- Setting 108 validar el tamaño longitud del telefono
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList

					RETURN (0)
				END

				SELECT 0 AS res, @tel AS tel -- Extension

				RETURN (0)
			END
		END

		DECLARE @telTemp AS VARCHAR(15)

		SELECT @telTemp = @tel

		IF @pais = 1
		BEGIN ---Mexico
			IF @lon = 3 AND @tel = ''911''
			BEGIN
				SELECT 4 AS res, @tel AS tel --Lista Negra

				RETURN (0)
			END

			IF (@lon < 10)
			BEGIN
				SELECT 1 AS res, @tel AS tel --Longitud invalida

				RETURN (0)
			END

				IF EXISTS (
				SELECT 1
				FROM ccCampsExtend
				WHERE cam_id = @Camp
				  AND ZipCodeSchedule = 1
			)
			BEGIN
				IF (@dato1 = '''' OR NOT EXISTS (SELECT 1 FROM ccTimeZoneAreaCP WHERE ZipCode = LTRIM(RTRIM(@dato1))))
				BEGIN
					SELECT 6 AS res, @tel AS tel; -- No tiene codigo postal
					RETURN (0);
				END
			END

			IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
			BEGIN
				SELECT 2 AS res, @tel AS tel --Digitos incorrectos

				RETURN (0)
			END

			IF left(@tel, 3) = ''001''
			BEGIN
				SELECT 0 AS res, @tel AS tel

				RETURN (0)
			END

			SELECT @tel = right(@tel, 10)

			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList

				RETURN (0)
			END

			If (@Camp > 0 AND @checkLd_In_ANILst = 1)
			BEGIN
				If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.
				BEGIN
					SELECT 0 AS res, @tel AS tel
					RETURN (0)
				END

				IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
						  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
						  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
				BEGIN
					SELECT 0 AS res, @tel AS tel
					RETURN (0)
				END
				ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
						  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
						  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
				BEGIN
					SELECT 0 AS res, @tel AS tel
					RETURN (0)
				END
			END


			SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal, DEFAULT, DEFAULT)

			IF LEFT(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp AS tel --No encontrado

				RETURN (0)
			END

			SELECT 0 AS res, @tel AS tel

			RETURN (0)
		END
		ELSE IF @pais = 2
		BEGIN --Argentina
			SET @tel = dbo.completa(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

				RETURN (0)
			END

			SELECT @tel = dbo.fnClearPhoneArg(@tel)

			IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 3
		BEGIN --Colombia
			IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
			BEGIN
				SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

				RETURN (0)
			END

			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 4
		BEGIN --USA
			EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

			RETURN (0)
		END
		ELSE IF @pais = 5
		BEGIN --Chile
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 6
		BEGIN --Venezuela
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 7
		BEGIN --Reino Unido
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 8
		BEGIN --Arabia saudita
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF (len(@tel) IN (9, 10, 11))
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
		BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 1 AS res, @telTemp --Longitud Invalida
			END
			ELSE IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
				END

				SELECT 0 AS res, @tel AS tel
			END

			RETURN (0)
		END
	'
	EXEC(@sql);

   ------------------------------------- END JUAN MEDINA -------------------------------------------

     --------------------------------- BEGIN Gallardo 20250905.0.8 ------------------------------------------------
    SET @process = '#2970 - Reports - RepInCallsDetail Se elimina los datos para revisar las replicas'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
@action SMALLINT,
@maxRecordsToTransfer INT = 10,
@ids varchar(max)= 0
AS
BEGIN
SET NOCOUNT ON;

IF @action = 1
BEGIN
    DECLARE @countrId INT;
    SET @countrId = 1;

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

          -- Declarar la variable tipo tabla
        declare @tempCalls table(
        cal_id INT,
        user_id INT,
        Inbound_id INT,
        calif_id int,
        cal_extension INT,
        cal_inicio DATETIME,
        phone VARCHAR(50),
        duration INT,
        cal_key VARCHAR(50),
        cal_manual int,
        cal_puerto INT,
        dni_id INT,
        fvalida datetime,
        cal_whohung int,
        califSub_id int,
        cal_tMoh INT,
        dateEnd DATETIME,
        callType INT,
        avrsId INT,
        prefijo VARCHAR(20),
        isCallRecord BIT,
        DNIS VARCHAR(50),
        IDWG VARCHAR(1000),
        IsVoicemail BIT,
        VirtualAgentId int
    );

        declare @deleteRow table(id int primary key);
        declare @relationCallIdUser table(cal_id int, user_id int);

    WITH callsIn AS (
        SELECT TOP (@maxRecordsToTransfer)
            calls.cal_id as CallId,
            CASE WHEN ccInbound.chat = 11 THEN 0 ELSE calls.[User_id] END AS [user_id],
            calls.Inbound_id,
            calls.calif_id,
            CAST(cal_extension AS INT) AS cal_extension,
            cal_inicio,
            cal_ANI AS phone,
            ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0)
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            0 AS cal_manual,
            cal_puerto,
            calls.dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0
                ELSE cal_tMoh - trans.tAntesXfer
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            ccInbound.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            ISNULL(dni.dni_numero, '''') AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            0 AS IsVoicemail,
            CASE WHEN ccInbound.chat = 11 THEN calls.[User_id] ELSE 0 END AS VirtualAgentId
        FROM ccCallsIn AS calls WITH (NOLOCK)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers  with(nolock)
            WHERE tipo = 1 AND modo != 7
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id
    ),
    callsOut AS (
        SELECT TOP (@maxRecordsToTransfer)
            calls.cal_id AS CallId,
            user_id AS UserId,
            calls.cam_id AS camAcdId,
            CAST(calls.calif_id AS SMALLINT) AS califId,
            CAST(cal_extension AS INT) AS extension,
            cal_inicio,
            cal_telefono,
            ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0)
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            cal_manual,
            cal_puerto,
            0 AS dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0
                ELSE cal_tMoh - trans.tAntesXfer
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            camps.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            '''' AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            CASE WHEN calls.statusCall_id = 19 THEN 1 ELSE 0 END AS IsVoicemail,
            calls.virtualAgentId as VirtualAgentId
        FROM ccoCallsOut AS calls WITH (NOLOCK)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers with(nolock)
            WHERE tipo = 2
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id
    )

    INSERT INTO @tempCalls
    SELECT * FROM callsIn
    UNION
    SELECT * FROM callsOut;


    insert into @deleteRow
    select min(avrsId) id
    from @tempCalls
    group by cal_id,callType
    having count(*)>1

    delete from @tempCalls where avrsId in( select id from @deleteRow )
        delete from ccAVRSTransfer where id in( select id from @deleteRow )

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=0)
    BEGIN
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id and A.callType=0
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=0

                delete from @relationCallIdUser
        END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=1 and IsVoicemail =0)
    BEGIN
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id and A.callType=1
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=1
        END

     -- Revisar si hay registros con IsVoicemail = 1
    IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
    BEGIN
                update A
                set A.duration=B.tDialing
                FROM @tempCalls A
                Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
        WHERE A.IsVoicemail = 1;
    END

    --elimina los registros y se agrega tabla temporal para revision
    if exists(SELECT 1 FROM @tempCalls WHERE user_id=0 and IsVoicemail=0)
    begin
        delete FROM @tempCalls WHERE user_id=0 and IsVoicemail=0 and  datediff(hh,cal_inicio,getdate())<8
    end
        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and IsVoicemail=0)
    BEGIN
                delete A from ccAVRSTransfer A
                inner join @tempCalls t on A.id=t.avrsId
                where t.user_id=0 and t.IsVoicemail=0
        END

    -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
    SELECT * FROM @tempCalls;

END
ELSE IF @action = 2
BEGIN
    Delete A
    from ccAVRSTransfer A
    inner join dbo.fn_RIASplitDelimited(@ids,'','') t on A.id=t.Value

END
END;
'
    EXEC(@sql)

    SET @process = '#'
    SET @sql = ''
    EXEC(@sql)

    SET @process = '#'
    SET @sql = ''
    EXEC(@sql)


  --------------------------------- END Gallardo 20250905.0.8 ------------------------------------------------

  ------ BEGIN Ulises Espinosa ticket #5022-----------------------------------------

   SET @process = 'Se realiza cambio en el sp ccsp_RIAOUTInsertNewJOBS_WT_Camp para el ticket #5022'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000   -- exec [ccsp_RIAOUTInsertNewJOBS_WT_Camp] 192, 1, 3000
AS
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @HadError BIT = 0
DECLARE @ErrMsg NVARCHAR(4000) = NULL
DECLARE @ErrSeverity INT = 16
DECLARE @ErrState INT = 1

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
DECLARE @campType AS INT
DECLARE @recordsQuantitySetting VARCHAR(8)
DECLARE @settingValueP1 VARCHAR(25)
DECLARE @InsertedRows INT = 0;

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

        CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #claimSmsIds (smsout_id INT NOT NULL PRIMARY KEY, old_sms_status TINYINT)

        --UPDATING TABLES BEFORE LOADING
        DECLARE @date datetime = GETDATE()
        UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
        UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

        INSERT INTO #smsoutIdSource
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK)
        on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id
        WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

        UNION

        SELECT top(@top) swt2.smsout_id
        FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id
        WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

        INSERT INTO #smsoutIdSource2
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

        BEGIN TRY
        BEGIN TRAN

        INSERT INTO #claimSmsIds(smsout_id, old_sms_status)
        SELECT smsout_id, old_sms_status
        FROM (
            UPDATE TOP(@top) sos WITH (UPDLOCK, READPAST, ROWLOCK)
            SET sms_status = 4
            OUTPUT inserted.smsout_id, deleted.sms_status
            FROM dbo.smsOutSource AS sos
            WHERE sos.cam_id = @camp_id AND (sos.sms_status < 2 OR sos.sms_status = 7)
        ) AS X(smsout_id, old_sms_status);


        INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone,
        iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
        SELECT TOP(@top) sos.smsout_id, sos.cam_id, RTRIM(LEFT(LTRIM(sos.sms_phoneNumber + ''        '' + sos.sms_phoneNumber2 + ''         ''
        + sos.sms_phoneNumber3 + ''         '' + sos.sms_phoneNumber4 + ''         '' + sos.sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
            CASE c.old_sms_status WHEN 7 THEN 1 ELSE c.old_sms_status END sms_status, sos.sms_dateDial, sos.callkey,
            CASE WHEN LEN(sos.sms_phoneNumber) > 0 THEN sos.iTimeZone ELSE NULL END iTimeZone,
            CASE WHEN LEN(sos.sms_phoneNumber) > 0 THEN sos.iTimeZone_summer ELSE NULL END iTimeZone_summer,
            CASE WHEN LEN(sos.sms_phoneNumber2) > 0 THEN sos.iTimeZone2 ELSE NULL END iTimeZone2,
            CASE WHEN LEN(sos.sms_phoneNumber2) > 0 THEN sos.iTimeZone_summer2 ELSE NULL END iTimeZone_summer2,
            CASE WHEN LEN(sos.sms_phoneNumber3) > 0 THEN sos.iTimeZone3 ELSE NULL END iTimeZone3,
            CASE WHEN LEN(sos.sms_phoneNumber3) > 0 THEN sos.iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
            CASE WHEN LEN(sos.sms_phoneNumber4) > 0 THEN sos.iTimeZone4 ELSE NULL END iTimeZone4,
            CASE WHEN LEN(sos.sms_phoneNumber4) > 0 THEN sos.iTimeZone_summer4 ELSE NULL END iTimeZone_summer4,
            CASE WHEN LEN(sos.sms_phoneNumber5) > 0 THEN sos.iTimeZone5 ELSE NULL END iTimeZone5,
            CASE WHEN LEN(sos.sms_phoneNumber5) > 0 THEN sos.iTimeZone_summer5 ELSE
                    NULL END iTimeZone_summer5, sos.list_id, sos.sms_dateDialEnd, ISNULL(sos.isSegmentLoad, 0)
        FROM dbo.smsOutSource AS sos
        INNER JOIN #claimSmsIds c ON c.smsout_id = sos.smsout_id
        WHERE sos.cam_id = @camp_id

        SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempsmsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempsmsOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
	         -- Nuevos Jobs
               INSERT INTO dbo.smsWorkingTable  WITH (ROWLOCK)
                (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                SELECT t.smsout_id, t.cam_id, t.sms_phoneNumber, t.sms_status, t.sms_dateDial, 0, 0
                ,t.cal_keyw, t.iTimeZone, t.iTimeZone_summer, t.iTimeZone2, t.iTimeZone_summer2, t.iTimeZone3, t.iTimeZone_summer3
                , t.iTimeZone4, t.iTimeZone_summer4, t.iTimeZone5, t.iTimeZone_summer5, t.list_id,t.sms_dateDialEnd, t.isSegmentLoad
                FROM #tempsmsOutSource t
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                AND NOT EXISTS (
                    SELECT 1 FROM smsWorkingTable swt WITH (UPDLOCK, HOLDLOCK) WHERE swt.smsout_id = t.smsout_id
                )
                SET @InsertedRows += @@ROWCOUNT;
                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.smsOutSource
            SET sms_status = 2
            FROM dbo.smsOutSource AS sos
            INNER JOIN #claimSmsIds c ON sos.smsout_id = c.smsout_id
        END

        COMMIT
        END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH

        DROP TABLE #claimSmsIds
        DROP TABLE #smsoutIdSource
        DROP TABLE #smsoutIdSource2
        DROP TABLE #tempsmsOutSource
END
ELSE IF(@campType = 5)
BEGIN
    CREATE TABLE #tempWhatsAppOutSource (Id INT PRIMARY KEY identity, WAOut_Id INT, CallKey VARCHAR(40), camId INT, PhoneNumber VARCHAR(30), Status INT, TimeZone int, TimeZone_Summer int, List_id INT, User_id SMALLINT, dateDial DATETIME)
    CREATE NONCLUSTERED INDEX [IX_TempWAO] ON [dbo].[#tempWhatsAppOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE TABLE #WAIdSource (WAOut_Id INT NOT NULL PRIMARY KEY)

    CREATE TABLE #claimWAIds (WAOut_Id INT NOT NULL PRIMARY KEY, old_Status INT)

    INSERT INTO #WAIdSource
    SELECT top(@top) cwaos.WAOut_Id
        FROM dbo.ccWhatsAppOutSource AS cwaos WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.Status IN (0) AND cwaos.camId = @camp_id

    BEGIN TRY
    BEGIN TRAN

    INSERT INTO #claimWAIds(WAOut_Id, old_Status)
    SELECT WAOut_Id, old_Status
    FROM (
        UPDATE TOP(@top) cwaos WITH (UPDLOCK, READPAST, ROWLOCK)
        SET Status = 4
        OUTPUT inserted.WAOut_Id, deleted.Status
        FROM dbo.ccWhatsAppOutSource AS cwaos
        WHERE cwaos.camId = @camp_id AND cwaos.Status = 0
    ) AS X(WAOut_Id, old_Status);

    INSERT INTO #tempWhatsAppOutSource
    (
        WAOut_Id,
        CallKey,
        camId,
        PhoneNumber,
        Status,
        TimeZone,
        TimeZone_Summer,
        List_id,
        User_id,
        dateDial
    )
        SELECT TOP(@top) cwaos.WAOut_Id, cwaos.CallKey,cwaos.camId, RTRIM(LEFT(LTRIM(cwaos.PhoneNumber + ''        '' ), 13)) AS phoneNumber,
            c.old_Status AS WAStatus,
            CASE WHEN cwaos.TimeZone = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,0) ELSE cwaos.TimeZone END,
            CASE WHEN cwaos.TimeZone_Summer = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,1) ELSE cwaos.TimeZone_Summer END,
            list_id, cwaos.User_id, cwaos.dateDial
        FROM dbo.ccWhatsAppOutSource AS cwaos
        INNER JOIN #claimWAIds c ON c.WAOut_Id = cwaos.WAOut_Id
        WHERE cwaos.camId = @camp_id

    SELECT @rowstoInsert = COUNT(*) FROM #tempWhatsAppOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempWhatsAppOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempWhatsAppOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                INSERT INTO dbo.ccoWAWorkingTable(WAOut_id, PhoneNumber, Callkey, CamId, WaStatus, dateDial, UserId,TimeZone, TimeZone_Summer)
                SELECT WAOut_Id, PhoneNumber, CallKey, camId, Status, dateDial , User_id, TimeZone ,TimeZone_Summer
                FROM #tempWhatsAppOutSource
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                SET @InsertedRows += @@ROWCOUNT;

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.ccWhatsAppOutSource
            SET
            Status = 2,
            TimeZone = cis3.TimeZone,
            TimeZone_Summer = cis3.TimeZone_Summer
            FROM dbo.ccWhatsAppOutSource AS cwaos
            INNER JOIN #tempWhatsAppOutSource  cis3 ON cwaos.WAOut_Id = cis3.WAOut_Id
        END

    COMMIT
    END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;

    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH

        DROP TABLE #claimWAIds
        DROP TABLE #WAIdSource
        DROP TABLE #tempWhatsAppOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19),
        cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT,
        iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT,
        iZonaHoraria_verano5 INT, list_id INT, new_status int)

        CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #claimCallIds (callout_id INT NOT NULL PRIMARY KEY, old_cal_status TINYINT)

        INSERT INTO #calloutIdSource
        SELECT top(@top) cs.callout_id
        FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        inner join ccoWorkingTable wt WITH (INDEX (PK_ccoWorkingTable), NOLOCK)
        on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id
        WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

        UNION

        SELECT top(@top) Cout.callout_id
        FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
        inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id
        AND cout.cam_id = Wtab.cam_id
        WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)


        INSERT INTO #calloutIdSource2
        SELECT top(@top) callout_id
        FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
        WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

        IF exists(SELECT * FROM #calloutIdSource)
        BEGIN
            UPDATE ccoCallBacks
            SET [status] = 6, schedulerStatus = 1
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )

            UPDATE ccoCallsOutSource
            SET cal_Status = 4
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )
        END

        BEGIN TRY
        BEGIN TRAN

        INSERT INTO #claimCallIds(callout_id, old_cal_status)
        SELECT callout_id, old_cal_status
        FROM (
            UPDATE TOP(@top) cs WITH (UPDLOCK, READPAST, ROWLOCK)
            SET cal_status = 4
            OUTPUT inserted.callout_id, deleted.cal_status
            FROM ccoCallsOutSource cs
            WHERE cs.cam_id = @camp_id AND (cs.cal_status < 2 OR cs.cal_status = 7)
        ) AS X(callout_id, old_cal_status);


        INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria,
        iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
            iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
        SELECT TOP(@top) cs.callout_id, cs.cam_id, CASE WHEN ISNULL(cs.recycleType, 1) = 0 THEN
        CASE
            WHEN cs.recyclePhone = 1 THEN cs.cal_telefono
            WHEN cs.recyclePhone = 2 THEN cs.cal_telefono2
            WHEN cs.recyclePhone = 3 THEN cs.cal_telefono3
            WHEN cs.recyclePhone = 4 THEN cs.cal_telefono4
            else cs.cal_telefono5
        END
        ELSE rtrim(left(ltrim(cs.cal_telefono + ''        '' + cs.cal_telefono2 + ''         ''
            + cs.cal_telefono3 + ''         '' + cs.cal_telefono4 + ''         '' + cs.cal_telefono5 + ''         ''), 13))
        END AS cal_telefono,
            CASE c.old_cal_status WHEN 7 THEN 1 ELSE c.old_cal_status END cal_status, cs.cal_fechaDial, cs.cal_key,
            CASE WHEN LEN(cs.cal_telefono) > 0 THEN cs.iZonaHoraria ELSE NULL END iZonaHoraria,
            CASE WHEN LEN(cs.cal_telefono) > 0 THEN cs.iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria2 ELSE NULL END iZonaHoraria2,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2,
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria3 ELSE NULL END iZonaHoraria3,
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria4 ELSE NULL END iZonaHoraria4,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4,
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria5 ELSE NULL END iZonaHoraria5,
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria_verano5 ELSE
                    NULL END iZonaHoraria_verano5, cs.list_id
        FROM ccoCallsOutSource cs
        INNER JOIN #claimCallIds c ON c.callout_id = cs.callout_id
        WHERE cs.cam_id = @camp_id

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

        IF EXISTS(SELECT * FROM #tempCallsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                 INSERT INTO ccoWorkingTable  WITH (ROWLOCK)
                (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT t.callout_id, t.cam_id, t.cal_telefono, t.cal_status, t.cal_fechaDial, t.cal_keyw,
                       t.iZonaHoraria, t.iZonaHoraria_verano, t.iZonaHoraria2, t.iZonaHoraria_verano2,
                       t.iZonaHoraria3, t.iZonaHoraria_verano3, t.iZonaHoraria4, t.iZonaHoraria_verano4,
                       t.iZonaHoraria5, t.iZonaHoraria_verano5, t.list_id
                FROM #tempCallsOutSource t
                WHERE t.id > @batchsizeIni AND t.id <= @batchsizeFin
                  AND NOT EXISTS (
                    SELECT 1 FROM ccoWorkingTable w WITH (UPDLOCK, HOLDLOCK) WHERE w.callout_id = t.callout_id
                );

                SET @InsertedRows += @@ROWCOUNT;

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE ccoCallsOutSource
            SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
            FROM ccoCallsOutSource co
            INNER JOIN #claimCallIds c ON co.callout_id = c.callout_id
        END

        COMMIT
        END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH
        DROP TABLE #claimCallIds
        DROP TABLE #calloutIdSource
        DROP TABLE #calloutIdSource2
        DROP TABLE #tempCallsOutSource
END

_FIN:
UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

IF @HadError = 1
BEGIN
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END

SELECT @InsertedRows AS InsertedRows;
RETURN 0;

SET NOCOUNT OFF
'
    EXEC(@sql)


	-------------------- END Ulises Espinosa ------------------------
	-------------------- BEGIN KR234001-Marco Diaz Luna ------------------------
	SET @process = 'Setting 292 KR234001 – Setting to disable manual dialing modal'
	SET @sql = '
		IF NOT EXISTS (SELECT 1 FROM ccSettings2 WHERE setting_id = 292)
        BEGIN
			INSERT INTO ccSettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
			VALUES (
				292,
				''0'',
				''Marcación manual vía integración externa (deshabilitado: 0, habilitado: 1)'',
				1,
				''AGT'',
				''Controla la visibilidad y uso del modal de marcación manual. Cuando está en 0, el modal permanece oculto y no se permiten marcaciones manuales desde el agente. Solo se permiten marcaciones provenientes del CRM vía integración externa.'',
				''Manual dialing via external integration (disabled: 0, enabled: 1). Controls visibility and behavior of the manual dialing modal. When disabled, manual dialing from Kolob Agent is not allowed, only CRM-originated requests.'',
				1,
				''*''
			);
		END'
	EXEC(@sql)
	-------------------- END KR234001-Marco Diaz Luna ------------------------
	-------------------- BEGIN Hugo Longoria ------------------------

	SET @process = 'Setting 293 ruteo dinamico de troncales KR237000'
    SET @sql = '
		if not exists(select top 1 1 from ccsettings2 where setting_id=293)
        insert ccSettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values (293,''1'', ''Usar ruteo dinamico de troncales'', 1, ''GRL'', ''Habilita el enrutamiento dinamico de troncales'', ''Enable dynamic trunk routing'', 0, ''^[0-1]$'')'
	EXEC(@sql)

	SET @process = 'Nuevas columnas KR237000'
    SET @sql = 'IF not EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''route_id''
          AND Object_ID = Object_ID(N''dbo.ccTrunkConfiguration''))
        BEGIN
            alter table ccoLogdials add destination varchar(50), destination_name varchar(50)
			alter table ccLogTransfers add destination varchar(50), destination_name varchar(50)
			alter table ccTrunkConfiguration add route_id int
        END'
	EXEC(@sql)

	SET @process = 'Crear tabla ccTrunkRouting KR237000'
    SET @sql = 'IF not EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''ccTrunkRouting'')
		BEGIN
			CREATE TABLE [dbo].[ccTrunkRouting](
				[route_id] [int] IDENTITY(1,1) NOT NULL,
				[provider_name] [varchar](50) NOT NULL,
				[destination] [varchar](50) NOT NULL,
				[hash] [varchar](32) NOT NULL,
				[dest_length] [tinyint] NOT NULL,
				[priority] [tinyint] NOT NULL
			) ON [PRIMARY]
		END'
	EXEC(@sql)

	SET @process = 'Eliminar function GetRoute KR237000'
    SET @sql = 'IF OBJECT_ID(''dbo.GetRoute'', ''FN'') IS NOT NULL
		BEGIN
			DROP FUNCTION dbo.GetRoute
		END'
	EXEC(@sql)

	SET @process = 'Crear funcion GetRoute KR237000'
    SET @sql = 'CREATE FUNCTION [dbo].[GetRoute] (@phone varchar(50), @croute varchar(32), @trunkid int)
		RETURNS varchar(50)
		AS
		BEGIN
			declare @route varchar(50)

			if exists(select valor from ccSettings2 nolock where setting_id=293 and valor=''1'')
			select top 1 @route=destination+''|''+provider_name from (
			select destination,provider_name,(case when dest_length=len(@phone) then 3 else 0 end + case when hash=@croute then 2 else 0 end) as rate, priority
			from ccTrunkRouting nolock
			union
			select destination,provider_name,1 rate,priority from ccTrunkRouting nolock where route_id=(select route_id from ccTrunkConfiguration nolock where TrunkId=@trunkid)
			)r order by rate desc, priority desc

			return isnull(@route,'''')
		END'
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
            @iPortNumber smallint = 0,
			@trunkId int=0
            AS
            set nocount on
            declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
            declare @prefix as varchar(15), @trunk varchar(200)
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
			declare @croute varchar(32)

            set @prefix =''''
            set @tNoContesta = 25
            set @ani=''''
            set @iTipoDial = 0
            set @detectAnswerMachine = 0
            set @detectVoiceMail =1
            set @cam_tnotas = 30
            set @keepDial = 0

            select @pais = valor from ccsettings with(nolock) where setting_id = 104
            select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

            -- Mensajes
            select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
            from dbo.fn_ccCamps_SelMessage(@cam_id)

            -- Prefijo por puerto
		    select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor with(nolock) where provedor_id = (
		        select provedor_id from ccodialers with(nolock) where puerto = @iPortNumber )
		    -- Prefijo por campa?a
		    if @prefix =''''
		        select @prefix = dialPrefix from ccCamps with(nolock) where cam_id = @cam_id
		    -- Prefijo general, si es que esta habilitado
		    if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
		        select @prefix = valor from ccsettings with(nolock) where setting_id =101

            select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

            -- Propiedades de campa?a
            select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
            @detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
            @call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
            ,@PrefixRec=ISNULL(prefijo,''''), @recordIvr=ISNULL(recordIvr,0)
            from ccCamps C with(nolock) where C.cam_id=@cam_id

		    if @surveycamid > 0
		        select @ivr_script = isnull(ivrscript,0) from cccamps with(nolock) where cam_id = @surveycamid
		
		    --Custom MOH Files
		    DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
		    SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
		    FROM ccCampsMsgs VE with(nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

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
                if len(@sipheader)>32 and left(@sipheader,1)=''@''
					select @croute=substring(@sipheader, 2, 32)
            
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
                @apikeyQuantum AS key_api_quantum,
				@trunk trunk,
				dbo.GetRoute(C.cal_telefono,isnull(@croute,''''),@trunkId) destination
        		FROM @tmpccoCallsOutSource C
				left join ccoCallPriorityOrder cpo with(nolock) on cpo.callout_id = c.callout_id
                left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
                left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
                WHERE C.callout_id = @callout_id
				OPTION (RECOMPILE);
                return
            end 
            set nocount off
	 '
    EXEC(@sql)

	SET @process = 'Obtener ruta dinamica KR237000'
    SET @sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
                    @cam_id smallint=0,
                    @iPortNumber smallint = 0,
                    @phone varchar(30) = '''',
                    @callout_id int = 0,
					@trunkId int=0
                    as
                    declare @prefix as varchar(15), @sipheader varchar(500), @trunk varchar(200)
                    declare @ani as varchar(32)
                    declare @pais as tinyint
                    declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
                    declare @ivr_script smallint, @surveycamid int
                    declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
                    declare @PrefixRec varchar(40)
                    declare @carrier varchar(255)
                    declare @recordHold bit, @recordIvr bit
                    declare @RotativeAlgo int ,@aniList smallint
					declare @croute varchar(32)

                    select @pais = valor from ccsettings with(nolock) where setting_id = 104
                    select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

                    set @prefix =''''
                    -- Prefijo por puerto
                    select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
						select provedor_id from ccodialers nolock where puerto = @iPortNumber )

                    -- Prefijo por campa?a,
                    if @prefix =''''
                        select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

                    -- Prefijo general
                    if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
                        select @prefix = valor from ccsettings with(nolock) where setting_id =101

                    -- Ani
                    select @RotativeAlgo = RotativeAlgo from ccCamps where cam_id = @cam_id
                    select @aniList = id_anilist from ccCamps where cam_id =@cam_id

                    if @RotativeAlgo=0 and @aniList>0  begin
                    set @ani = dbo.TelAni(@phone, @aniList )
                    end
                    else begin
                        set @ani=''''
                    end
                    set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

                    --AnswerMachine Message Files
                    DECLARE @MsgFiles VARCHAR(8000)
                    SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile
                    FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

                    IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
                    BEGIN
                        select @MsgFiles = @MsgFiles + '',TTS/message.wav''
                    END

                    --Custom MOH Files
                    DECLARE @MohFiles VARCHAR(8000)
                    SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
                    FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

                    select @surveycamid = 0, @ivr_script = 0

                    select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
                    ,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
                    ,@call_record = dbo.EnableCallRecord(call_record, @pais, @phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
                    ,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
                    from ccCamps NOLOCK where cam_id = @cam_id

                    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
					if len(@sipheader)>32 and left(@sipheader,1)=''@''
						select @croute=substring(@sipheader, 2, 32)

                    if @surveycamid > 0
                        select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


                    if @ani = '''' begin
                    set @ani = @aniglobal
                    end

                     set @carrier = ''''
                     select @carrier = dbo.GetCarrierByTel(@phone)

                    select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
                    @call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
                    ,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr,
					@trunk trunk, dbo.GetRoute(@phone,isnull(@croute,''''),@trunkId) destination'
	EXEC(@sql)

	SET @process = 'CW-9905 + Obtener ruta dinamica KR237000'
	SET @sql = '
		ALTER procedure [dbo].[ccsp_DLRgetXferInfo]
		@camEspecId smallint=0,
		@iPortNumber smallint = 0,
		@type smallint,
		@typeTransfer smallint = 0,
		@phone varchar(50) = '''',
		@trunkId int=0
		as
		-- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
		declare @prefix as varchar(15), @trunk varchar(200)
		declare @timeout int
		declare @ani as varchar(32)
		declare @stop int
		declare @ivr_script smallint, @surveycamid int

		set @prefix =''''
		set @timeout = 20
		set @ani = ''''
		set @stop = 0

		-- Prefijo por puerto
		select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
			select provedor_id from ccodialers nolock where puerto = @iPortNumber )
		-- Prefijo por campaña o especialidad
		if @prefix =''''
			if @type = 2
				select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
			else
				select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
		-- Prefijo general
		if @prefix ='''' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
			select @prefix = valor from ccsettings where setting_id =101
		if @prefix ='''' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
			select @prefix = valor from ccsettings where setting_id =101

		-- Tiempo de marcado
		select @timeout = cast(valor as int) from ccSettings where setting_id = 109

		-- Ani y stopRecord
		if @type = 2
			select @ani = callerIdDesc, @stop = isnull(stopRecording, 0) from ccCamps nolock where cam_id = @camEspecId
		else
		begin
			select @ani = callerIdDesc, @stop = stopRecording, @surveycamid = isnull(extend.SurveyCamId,0)
			from ccInbound i (nolock)
			left join ccInboundExtend extend on extend.Inbound_id = i.Inbound_id
			where i.inbound_id= @camEspecId

			if @surveycamid > 0
				select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
		end

		if (@typeTransfer in (0,4) and @type = 2 and @phone is not null and @phone <> '''')
		begin
			select @stop = case when @typeTransfer = 0 then isnull(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone
		end

		select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording, @ivr_script as ivrScript,
		@trunk trunk, dbo.GetRoute(@phone,'''',@trunkId) destination'
    EXEC(@sql)

	SET @process = 'Sears + Guardar ruta dinamica KR237000 Alter SP ccsp_DLRSaveDialResult + update result'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult]
		@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
		@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
		@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
		@ani varchar(32)='''', @destination varchar(50)='''', @destination_name varchar(50)='''', @dialId int = 0
		AS
		BEGIN
			SET NOCOUNT ON;

			DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
			DECLARE @logDial_id INT;
			DECLARE @tAnswerBitFinal AS DATETIME;
			DECLARE @MaxCal_id INT;
			DECLARE @tTotal SMALLINT;
			DECLARE @setting292 TINYINT;

			SELECT @RecicleSIC = ISNULL(valor, 0)
			FROM ccSettings
			WHERE setting_id = 60;

			SELECT @setting292 = ISNULL(valor, 0)
			FROM ccSettings2
			WHERE setting_id = 292;

			SELECT @tTotal = @tDialing + @tAnswerBit;

			SELECT @tNow = GETDATE();

			SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);


		-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
		IF @call_id > 0 AND @tipoResDial_id = 1 and @cal_key = ''''
			BEGIN
			SELECT @cal_key = cal_key
			FROM ccoCallsOutSource WITH(NOLOCK)
			WHERE @callout_id = callout_id;
		END;

		declare @TipoLlamada int, @TipoDialingMode VARCHAR(9);
		select @TipoLlamada=dbo.fnGetTipoLlamada(@Telefono)

IF @dialId = 0 BEGIN --Begin insert
		IF @call_id > 0 AND @tipoResDial_id = 1
		BEGIN
				INSERT INTO ccoLogDials WITH (ROWLOCK)( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
				TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani,
				destination, destination_name)
					   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
					   ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS,
					   @TipoLlamada, @ani, @destination, @destination_name;
			END;
				 ELSE
			BEGIN
				INSERT INTO ccoLogDials WITH (ROWLOCK)( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
				TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani,
				destination, destination_name)
					   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
					   ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS,
					   @TipoLlamada, @ani, @destination, @destination_name;
			END;

			SELECT @logDial_id = SCOPE_IDENTITY();
			INSERT INTO ccoLogDialsData(logDial_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)
			SELECT @logDial_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @tNow
			FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id

			IF @RecicleSIC = 1
			BEGIN
				UPDATE ccoWorkingTable WITH(ROWLOCK)
				  SET tipoResDial_id = @tipoResDial_id
				WHERE callout_id = @callout_id;
			END;
END--End Insert

IF @dialId > 0 BEGIN --Begin update ccoLogDials
	PRINT(''Updating info'')
	UPDATE ccoLogDials set  tipoResDial_id = @tipoResDial_id, answerbit = @answerbit,
		canceledNoAgents = @canceledNoAgents, disconnectCause = @disconnectCause
		 WHERE callout_id = @callout_id
	SELECT @dialId as LogDialId
	RETURN 0;
END --End update
			-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
		IF @call_id > 0 AND @tipoResDial_id = 1
			BEGIN
				UPDATE ccoCallsOut WITH(ROWLOCK)
			SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
			WHERE cal_id = @call_id AND cal_puerto = 0;

				EXEC ccsp_CstoCalculaCosto @call_id;
			END;
		else IF @call_id > 0 AND @tipoResDial_id = 11
		BEGIN
				UPDATE ccoCallsOut WITH(ROWLOCK)
			SET cal_puerto = @Puerto
			WHERE cal_id = @call_id AND cal_puerto = 0;

		end

			SET @TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id );

			-- Guarda configuracion de TipoDialingMode
			UPDATE ccoLogDials WITH(ROWLOCK)
			  SET  TipoDialingMode = @TipoDialingMode,
			  manualCRM = CASE WHEN @setting292 = 1 AND RIGHT(''00'' + RTRIM(COALESCE(@TipoDialingMode, '''')), 2) LIKE ''%1%'' THEN 1 ELSE 0 END
			WHERE logDial_id = @logDial_id;
			SET NOCOUNT OFF;
		END;

			SELECT @logDial_id as LogDialId'
    EXEC(@sql);

	SET @process = 'Guardar ruta dinamica KR237000'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_EngineLogTransfers]
		@action as tinyint,
		@cal_id as integer,
		@tipo as tinyint,
		@modo as tinyint,
		@destino as varchar(50),
		@tantes integer = 0,
		@tdespues integer = 0,
		@pbxId tinyint =0,
		@channel int =0,
		@callerAni as varchar(50) = null,
		@destination varchar(50)='''',
		@destination_name varchar(50)=''''
		as
		-- tipo: 1 inbound, 2 outbound
		-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde, 6 supervisada acd, 7 in callback

		declare @totalCall_Time integer
		declare @callout_id int
		declare @xferDate datetime = getdate()

		declare @calloutId int

		if @action = 1 begin
			if @modo = 4 begin
				insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id, callerAni, destination, destination_name)
				values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino), @callerAni, @destination, @destination_name)
				if @tdespues > 0 begin
						select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
						update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
				end
			end
			else begin
				if @modo = 5 and @tipo = 1 and @cal_id = 0
				begin
					insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id, callerAni, destination, destination_name)
					values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino), @callerAni, @destination, @destination_name)
					return;
				end

				if not exists (select 1 from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
				begin
					insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id, callerAni, destination, destination_name)
					values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino), @callerAni, @destination, @destination_name)
				end

				if @tipo = 2 begin
					if @modo = 5 begin
						select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
						update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
					end

					if @modo in (0,1,2) begin
						select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
						update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
					end
				end
				else begin
					if @modo = 7 begin
					select @xferDate XferDate
					return(0)
					end
					select @calloutId = callout_id from ccCallsIn where cal_id = @cal_id
					if @calloutId <> 0
					begin
						select @cal_id = @calloutId
						select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
						update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
					end
				end
			end
			--Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
			if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
			declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
			set @tMinAVRS=5
			set @cal_manual=0
			select @tMinAVRS=valor from ccSettings where setting_id=65
			if @tipo=2 begin
				select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
			end
			else begin
				select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
			end

			if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
				insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
			end
			end
		end

		else if @action = 2
		begin
			select @calloutId = callout_id from ccCallsIn where cal_id = @cal_id
			if @calloutId <> 0
			begin
				select @cal_id = @calloutId
				update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
				select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
				update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
			end
		end

		else if @action = 4 begin
			select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
			update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		end'
	EXEC(@sql)


	-------------------- END Hugo Longoria ------------------------


    -------------------- BEGIN 127.20250905.0.8 Carlos Chavez ------------------------

     SET @process = 'Create index IX_ccoLogDials_cal_id'
    SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccoLogDials_cal_id''
      AND i.object_id = OBJECT_ID(''dbo.ccoLogDials'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccoLogDials_cal_id
    ON dbo.ccoLogDials (cal_id)
    INCLUDE (logDial_id);
END;'
    EXEC(@sql)

     SET @process = 'Create index IX_ccDispDashOut_Cam_Status_Disp_Sub'
    SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccDispDashOut_Cam_Status_Disp_Sub''
      AND i.object_id = OBJECT_ID(''dbo.ccDispositionDashboardResultOut'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccDispDashOut_Cam_Status_Disp_Sub
    ON dbo.ccDispositionDashboardResultOut (
        CamId,
        statusCallId,
        DispotitionId,
        SubDispotitionId
    );
END;'
    EXEC(@sql)

    SET @process = 'Create index IX_ccDispDashIn_Cam_Status_Disp_Sub'
    SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccDispDashIn_Cam_Status_Disp_Sub''
      AND i.object_id = OBJECT_ID(''dbo.ccDispositionDashboardResultIn'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccDispDashIn_Cam_Status_Disp_Sub
    ON dbo.ccDispositionDashboardResultIn (
        CamId,
        statusCallId,
        DispotitionId,
        SubDispotitionId
    );
END;'
    EXEC(@sql)

     SET @process = 'Alter procedure ccspSaveDispositionResult'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspSaveDispositionResult]
@action int,
@callType TINYINT=null,
@camId int =null,
@callid BIGINT=0,
@statusCallId int=0,
@dispotitionId int=null,
@subDispotitionId int=null
AS

declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
declare @callTypeInOut tinyint
if @action in(3,4) begin
    select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
    from ccsettings WITH(NOLOCK) where setting_id = 27 -- 0 esp

end
if @action in(5,6,7) begin
    select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
    from ccsettings WITH(NOLOCK) where setting_id = 27 -- 0 esp
end

set @callTypeInOut= case when @callType=1 then 0 else 1 end


if @action=0 begin
    declare @today date
    set @today =CONVERT(date,getdate())

    truncate table ccDispositionDashboardResultOut
    truncate table ccDispositionDashboardResultIn

    insert into ccDispositionDashboardResultOut
    select cam_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId
    from ccoCallsOut WITH(NOLOCK)
    where cal_Inicio>=@today

    insert into ccDispositionDashboardResultIn
    select Inbound_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId
    from ccCallsIn WITH(NOLOCK)
    where cal_Inicio>=@today
end
else if @action=1 begin
    set @dispotitionId=0
    set @subDispotitionId=0
    if @callType=1 begin
        insert into ccDispositionDashboardResultOut values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
    else begin
        insert into ccDispositionDashboardResultIn values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
end
else if @action=2 begin
    set @subDispotitionId=case when @subDispotitionId is null then null when @subDispotitionId>0 then @subDispotitionId else 0 end
    if @callType=1 begin
        update ccDispositionDashboardResultOut set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid
    end
    else begin
        update ccDispositionDashboardResultIn set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid
    end
end
else if @action=3 begin
    select @callTypeInOut as tipo,dash.CamId as CamId
    ,case when dash.statusCallId = 13 then
        case when ca.[description] is not null then ca.[description] else @nIdioma end
        else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma end
    end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId as DispotitionId
    ,count(*) Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    --,CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
    ,CASE WHEN SUM(SubDispotitionId) > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSubDisp
    from ccDispositionDashboardResultOut dash WITH(NOLOCK)
    left join ccTipoCalifOut ca WITH(NOLOCK) on dash.DispotitionId = ca.calif_id
    left join ccTipoCalifSubOUT tcsout WITH(NOLOCK) on dash.SubDispotitionId = tcsout.califSub_id
    left join ccstatusllamada sll WITH(NOLOCK) on sll.statuscall_id = dash.statusCallId
    left join ccCamps ci WITH(NOLOCK) on ci.cam_id = dash.CamId
    LEFT join cctipoSubCalifRel rel WITH(NOLOCK) on rel.calif_id = ca.calif_id and dash.SubDispotitionId = rel.califSub_id and tipoSubRel = 0
    where CamId=@camId
    group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor--,rel.calif_id

end
else if @action=4 begin
    select @callTypeInOut as tipo
    ,dash.CamId
    ,case when ca.[Description] is not null then ca.[Description] else @nIdioma end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId
    ,count(*)  as Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,0 IsSubDisp
    from ccDispositionDashboardResultIn dash WITH(NOLOCK)
    left join ccTipoCalif ca WITH(NOLOCK) on dash.DispotitionId = ca.calif_id
    left join ccInbound cci WITH(NOLOCK) on cci.inbound_id = dash.CamId
    where dash.CamId = @camId and dash.statusCallId = 13
    group by ca.[Description], dash.CamId,dash.SubDispotitionId,dash.DispotitionId,GraphColor

end

else if @action=5 begin
    select 0 as Type,co.CamId as CampId,
    case when co.statusCallId = 13
    then case when description is not null
    then description else @nIdioma end
    else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
    end as Calification,
    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
    from ccDispositionDashboardResultOut co WITH(NOLOCK)
    left join ccTipoCalifOut ca WITH(NOLOCK) on co.DispotitionId = ca.calif_id
    left join ccTipoCalifSubOUT cso WITH(NOLOCK) on co.SubDispotitionId = cso.califSub_id
    left join ccstatusllamada sll WITH(NOLOCK) on sll.statuscall_id = co.statusCallId
    left join ccCamps ci WITH(NOLOCK) on ci.cam_id = co.CamId
    where co.CamId = @camId
    and co.DispotitionId = @dispotitionId
    group by  co.CamId, co.statusCallId,description,descripcion,cso.califSubDesc
end
else if @action=6 begin
    select 0 as [type],CamId as CampId
    , ca.[description] as Calification
    , isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
    , count(ctcs.califSubDesc) as Quantity
    --,dash.DispotitionId
    from ccDispositionDashboardResultIn dash WITH(NOLOCK)
    left join ccTipoCalif ca WITH(NOLOCK) on dash.DispotitionId = ca.calif_id
    left join ccInbound cci WITH(NOLOCK) on cci.inbound_id = dash.CamId
    left join ccTipoCalifSub ctcs WITH(NOLOCK) on dash.SubDispotitionId = ctcs.califSub_id
    where dash.CamId=@camId and dash.statusCallId=13 and dash.DispotitionId=@dispotitionId
    group by ca.description, dash.CamId,ctcs.califSubDesc,dash.DispotitionId
end
else if @action=7 begin
    if @callType= 1 begin

        select 0 as Type,co.CamId as CampId,
        isnull(ca.calif_id,0) as Id,
        case when co.statusCallId = 13
        then case when description is not null
        then description else @nIdioma end
        else
        case when sll.descripcion is not null
        then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma + ''CamId''
        end
        end as Calification,
        isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(*) Quantity
        from ccDispositionDashboardResultOut co WITH(NOLOCK)
        left join ccTipoCalifOut ca WITH(NOLOCK) on co.DispotitionId = ca.calif_id
        left join ccTipoCalifSubOUT cso WITH(NOLOCK) on co.SubDispotitionId = cso.califSub_id
        left join ccstatusllamada sll WITH(NOLOCK) on sll.statuscall_id = co.statusCallId
        left join ccCamps ci WITH(NOLOCK) on ci.cam_id = co.CamId
        where co.CamId = @camId
        group by  co.CamId,ca.calif_id, co.statusCallId,description,descripcion,cso.califSubDesc
    end
    else begin
        select 0 as [type],CamId as CampId
        , isnull(ca.calif_id,0) as Id
        , ca.[description] as Calification
        , isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
        , count(*) as Quantity
        --,dash.DispotitionId
        from ccDispositionDashboardResultIn dash WITH(NOLOCK)
        left join ccTipoCalif ca WITH(NOLOCK) on dash.DispotitionId = ca.calif_id
        left join ccInbound cci WITH(NOLOCK) on cci.inbound_id = dash.CamId
        left join ccTipoCalifSub ctcs WITH(NOLOCK) on dash.SubDispotitionId = ctcs.califSub_id
        where dash.CamId=@camId and dash.statusCallId=13-- and dash.DispotitionId=@dispotitionId
        group by ca.description, dash.CamId,  ca.calif_id,ctcs.califSubDesc,dash.DispotitionId
    end
end'
    EXEC(@sql)

     SET @process = 'Drop procedure ccsp_InsertDNCList_Static'
    SET @sql = 'IF OBJECT_ID(''dbo.ccsp_InsertDNCList_Static'', ''P'') IS NOT NULL
    DROP PROCEDURE dbo.ccsp_InsertDNCList_Static;'
    EXEC(@sql)

    SET @process = 'Create procedure ccsp_InsertDNCList_Static'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCList_Static]
    @telephone NVARCHAR(30) = NULL,
    @ln_id INT,
    @calKey VARCHAR(40) = NULL,
    @skipWorkingCleanup BIT = 0 -- 0 = limpia WT/CS, 1 = solo inserta en ccListaNegra
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @phoneEmpty VARCHAR(1) = '''';

    IF OBJECT_ID(''tempdb..#tmpBlacklistInput'') IS NOT NULL DROP TABLE #tmpBlacklistInput;
    CREATE TABLE #tmpBlacklistInput
    (
        phoneNumber VARCHAR(30) NOT NULL,
        calKey      VARCHAR(40) NULL
    );

    IF @telephone IS NOT NULL
    BEGIN
        SET @telephone = dbo.Limpia(@telephone);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.ccListaNegra
            WHERE idtipolista = @ln_id
              AND telefono = @telephone
              AND (calKey = @calKey OR (calKey IS NULL AND @calKey IS NULL))
        )
        BEGIN
            INSERT INTO #tmpBlacklistInput (phoneNumber, calKey)
            VALUES (CONVERT(VARCHAR(30), @telephone), @calKey);
        END
        ELSE
        BEGIN
            RETURN;
        END
    END

    IF NOT EXISTS (SELECT 1 FROM #tmpBlacklistInput)
        RETURN;

    INSERT INTO dbo.ccListaNegra (telefono, idtipolista, HashKey, calKey)
    SELECT phoneNumber, @ln_id, dbo.hashList(calKey), calKey
    FROM #tmpBlacklistInput;

    INSERT INTO dbo.cchistoriallistanegra (telefono, idtipomov, idtipolista)
    SELECT phoneNumber, 7, @ln_id
    FROM #tmpBlacklistInput;

    IF @skipWorkingCleanup = 1
        RETURN;

    IF OBJECT_ID(''tempdb..#mycamps'') IS NOT NULL DROP TABLE #mycamps;
    CREATE TABLE #mycamps (campsid INT PRIMARY KEY);

    INSERT INTO #mycamps (campsid)
    SELECT DISTINCT A.cam_id
    FROM dbo.Camplistanegra A
    INNER JOIN dbo.ccCamps B ON A.cam_id = B.cam_id
    WHERE A.idtipolista = @ln_id
      AND B.CampType NOT IN (5,7);

    IF NOT EXISTS (SELECT 1 FROM #mycamps)
        RETURN;

    IF OBJECT_ID(''tempdb..#AffectedCalls'') IS NOT NULL DROP TABLE #AffectedCalls;
    CREATE TABLE #AffectedCalls
    (
        callout_id   INT PRIMARY KEY,
        cam_id       INT,
        cal_key      VARCHAR(40),
        cal_telefono  VARCHAR(30),
        cal_telefono2 VARCHAR(30),
        cal_telefono3 VARCHAR(30),
        cal_telefono4 VARCHAR(30),
        cal_telefono5 VARCHAR(30)
    );

    INSERT INTO #AffectedCalls
    SELECT DISTINCT
        a.callout_id,
        a.cam_id,
        a.cal_key,
        a.cal_telefono,
        a.cal_telefono2,
        a.cal_telefono3,
        a.cal_telefono4,
        a.cal_telefono5
    FROM dbo.ccoCallsOutSource a WITH (NOLOCK)
    INNER JOIN #mycamps c ON a.cam_id = c.campsid
    WHERE
        EXISTS (
            SELECT 1
            FROM #tmpBlacklistInput t
            WHERE t.calKey IS NULL
              AND t.phoneNumber IN (
                    a.cal_telefono,
                    a.cal_telefono2,
                    a.cal_telefono3,
                    a.cal_telefono4,
                    a.cal_telefono5
              )
        )
        OR EXISTS (
            SELECT 1
            FROM #tmpBlacklistInput t
            WHERE t.calKey IS NOT NULL
              AND t.calKey = a.cal_key
        );

    IF NOT EXISTS (SELECT 1 FROM #AffectedCalls)
        RETURN;

    IF OBJECT_ID(''tempdb..#ToRemove'') IS NOT NULL DROP TABLE #ToRemove;
    CREATE TABLE #ToRemove
    (
        callout_id INT,
        cam_id INT,
        pos TINYINT,
        telefono VARCHAR(30),
        PRIMARY KEY (callout_id, pos)
    );

    INSERT INTO #ToRemove
    SELECT ac.callout_id, ac.cam_id, v.pos, v.tel
    FROM #AffectedCalls ac
    CROSS APPLY (VALUES
        (1, ac.cal_telefono),
        (2, ac.cal_telefono2),
        (3, ac.cal_telefono3),
        (4, ac.cal_telefono4),
        (5, ac.cal_telefono5)
    ) v(pos, tel)
    INNER JOIN #tmpBlacklistInput t
        ON t.phoneNumber = v.tel
    WHERE v.tel <> @phoneEmpty;

    INSERT INTO dbo.cchistoriallistanegra (callout_id, telefono, cam_id, idtipomov, idtipolista)
    SELECT callout_id, telefono, cam_id, 3, @ln_id
    FROM #ToRemove;

    /*==================== POS 1 ====================*/
    IF OBJECT_ID(''tempdb..#X1'') IS NOT NULL DROP TABLE #X1;
    SELECT
        callout_id,
        cal_telefono  AS p1,
        cal_telefono2 AS p2,
        cal_telefono3 AS p3,
        cal_telefono4 AS p4,
        cal_telefono5 AS p5
    INTO #X1
    FROM #AffectedCalls
    WHERE callout_id IN (SELECT callout_id FROM #ToRemove WHERE pos = 1);

    DELETE wt
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X1 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p1
      AND NULLIF(x.p2,'''') IS NULL
      AND NULLIF(x.p3,'''') IS NULL
      AND NULLIF(x.p4,'''') IS NULL
      AND NULLIF(x.p5,'''') IS NULL;

    UPDATE wt
    SET wt.cal_telefono = COALESCE(NULLIF(x.p2,''''), NULLIF(x.p3,''''), NULLIF(x.p4,''''), NULLIF(x.p5,''''), ''''),
        wt.iZonaHoraria = NULL,
        wt.iZonaHoraria_verano = NULL
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X1 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p1;

    UPDATE cs
    SET cs.cal_telefono = '''',
        cs.iZonaHoraria = 0,
        cs.iZonaHoraria_verano = 0
    FROM dbo.ccoCallsOutSource cs
    INNER JOIN #X1 x ON x.callout_id = cs.callout_id
    WHERE cs.cal_telefono = x.p1;

    /*==================== POS 2 ====================*/
    IF OBJECT_ID(''tempdb..#X2'') IS NOT NULL DROP TABLE #X2;
    SELECT
        callout_id,
        cal_telefono2 AS p2,
        cal_telefono3 AS p3,
        cal_telefono4 AS p4,
        cal_telefono5 AS p5
    INTO #X2
    FROM #AffectedCalls
    WHERE callout_id IN (SELECT callout_id FROM #ToRemove WHERE pos = 2);

    DELETE wt
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X2 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p2
      AND NULLIF(x.p3,'''') IS NULL
      AND NULLIF(x.p4,'''') IS NULL
      AND NULLIF(x.p5,'''') IS NULL;

    UPDATE wt
    SET wt.cal_telefono = COALESCE(NULLIF(x.p3,''''), NULLIF(x.p4,''''), NULLIF(x.p5,''''), '''')
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X2 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p2;

    UPDATE cs
    SET cs.cal_telefono2 = '''',
        cs.iZonaHoraria2 = 0,
        cs.iZonaHoraria_verano2 = 0
    FROM dbo.ccoCallsOutSource cs
    INNER JOIN #X2 x ON x.callout_id = cs.callout_id
    WHERE cs.cal_telefono2 = x.p2;

    /*==================== POS 3 ====================*/
    IF OBJECT_ID(''tempdb..#X3'') IS NOT NULL DROP TABLE #X3;
    SELECT
        callout_id,
        cal_telefono3 AS p3,
        cal_telefono4 AS p4,
        cal_telefono5 AS p5
    INTO #X3
    FROM #AffectedCalls
    WHERE callout_id IN (SELECT callout_id FROM #ToRemove WHERE pos = 3);

    DELETE wt
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X3 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p3
      AND NULLIF(x.p4,'''') IS NULL
      AND NULLIF(x.p5,'''') IS NULL;

    UPDATE wt
    SET wt.cal_telefono = COALESCE(NULLIF(x.p4,''''), NULLIF(x.p5,''''), '''')
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X3 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p3;

    UPDATE cs
    SET cs.cal_telefono3 = '''',
        cs.iZonaHoraria3 = 0,
        cs.iZonaHoraria_verano3 = 0
    FROM dbo.ccoCallsOutSource cs
    INNER JOIN #X3 x ON x.callout_id = cs.callout_id
    WHERE cs.cal_telefono3 = x.p3;

    /*==================== POS 4 ====================*/
    IF OBJECT_ID(''tempdb..#X4'') IS NOT NULL DROP TABLE #X4;
    SELECT
        callout_id,
        cal_telefono4 AS p4,
        cal_telefono5 AS p5
    INTO #X4
    FROM #AffectedCalls
    WHERE callout_id IN (SELECT callout_id FROM #ToRemove WHERE pos = 4);

    DELETE wt
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X4 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p4
      AND NULLIF(x.p5,'''') IS NULL;

    UPDATE wt
    SET wt.cal_telefono = COALESCE(NULLIF(x.p5,''''), '''')
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X4 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p4;

    UPDATE cs
    SET cs.cal_telefono4 = '''',
        cs.iZonaHoraria4 = 0,
        cs.iZonaHoraria_verano4 = 0
    FROM dbo.ccoCallsOutSource cs
    INNER JOIN #X4 x ON x.callout_id = cs.callout_id
    WHERE cs.cal_telefono4 = x.p4;

    /*==================== POS 5 ====================*/
    IF OBJECT_ID(''tempdb..#X5'') IS NOT NULL DROP TABLE #X5;
    SELECT
        callout_id,
        cal_telefono5 AS p5
    INTO #X5
    FROM #AffectedCalls
    WHERE callout_id IN (SELECT callout_id FROM #ToRemove WHERE pos = 5);

    DELETE wt
    FROM dbo.ccoWorkingTable wt
    INNER JOIN #X5 x ON x.callout_id = wt.callout_id
    WHERE wt.cal_telefono = x.p5;

    UPDATE cs
    SET cs.cal_telefono5 = '''',
        cs.iZonaHoraria5 = 0,
        cs.iZonaHoraria_verano5 = 0
    FROM dbo.ccoCallsOutSource cs
    INNER JOIN #X5 x ON x.callout_id = cs.callout_id
    WHERE cs.cal_telefono5 = x.p5;
END'
    EXEC(@sql)


    SET @process = 'Alter procedure ccsp_AgentUpdateCallCALIF'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall INT,
@calif_id SMALLINT,
@TipoCall SMALLINT,
@Origin INT = 0,
@cal_key VARCHAR(40) = NULL,
@callOutId INT = 0,
@subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT,
@tel VARCHAR(30), @camp INT, @iddncList AS INT,@completatel VARCHAR(30),@camId int,@dni_id int
,@useCalkeyBlackList bit
,@userid INT
,@statusCallId int
,@hashTel INT

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)


DECLARE @killListID INT = (
        SELECT idtipolista
        FROM ccTiposListaNegra
        WHERE Tipolista = ''default/KillList''
        )
DECLARE @killListSetting INT = (
        SELECT STATUS
        FROM ccSettings
        WHERE setting_id = 215
        )

IF @TipoCall = 1
BEGIN
    UPDATE ccCallsIN
    SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key)
    , califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    WHERE cal_id = @IDCall


    exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=0,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=13

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 0 AND calif_id = @calif_id
            )
    BEGIN
        SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
        ,@camId=Inbound_id,@dni_id=dni_id
        FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
        JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
        WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

        IF @tel IS NOT NULL AND @iddncList IS NOT NULL
        BEGIN
            SELECT @useCalkeyBlackList = valor
            FROM ccSettings2
            WHERE setting_id = 288

            if @useCalkeyBlackList is null set @useCalkeyBlackList=0

            if @useCalkeyBlackList=0 set @cal_key=null


            --insert ccListaNegra
            INSERT INTO cclistanegra (telefono, idtipolista, calKey)
            VALUES (@tel, @iddncList, @cal_key)

            --insert cc_killlist
            IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
            BEGIN
                select @hashTel = dbo.hashPhone(@tel)

                IF NOT EXISTS (
                        SELECT hashtel
                        FROM cc_KillList
                        WHERE hashTel = @hashTel
                        )
                BEGIN
                    INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
                    VALUES (@hashTel, @iddncList, GETDATE())
                END
            END

            INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
            values (@tel,@iddncList,@camId,getdate(),@dni_id,6)
        END
    END

    RETURN (0)
END

IF @TipoCall = 2
BEGIN
    -- Toma como prioridad la configuración de la subcalificación (en caso de existir)
    SELECT @autoCB = autocallback
    FROM ccTipoCalifSubout
    WHERE califSub_Id = @subId

    -- Si no tiene subcalificacion toma la de la calificacion
    IF @autoCB IS NULL
    BEGIN
        SELECT @autoCB = autocallback
        FROM cctipocalifout
        WHERE calif_id = @calif_id
    END

    SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
    ,@statusCallId=statusCall_id
    ,@tel=cal_telefono
        FROM ccocallsout
        WHERE Cal_id = @IDCall

    IF @autoCB = 1
    BEGIN
        SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
        FROM cccamps cam
        WHERE cam.cam_id = @camp

        EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
    END

    UPDATE ccoCallsOUT
    SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    WHERE cal_id = @IDCall

    exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=1,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=@statusCallId

    SELECT @useCalkeyBlackList = valor
    FROM ccSettings2
    WHERE setting_id = 288

    if @useCalkeyBlackList is null set @useCalkeyBlackList=0

    set @completatel=dbo.Completa_ListaNegra(@tel)

    if @useCalkeyBlackList=0 set @cal_key=null

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 1 AND calif_id = @calif_id
            ) AND NOT EXISTS (
            select 1 from ccListaNegra bl with(nolock)
            where (telefono=@tel or telefono =@completatel)
            and calKey=@cal_key
            AND bl.idtipolista IN (
                    SELECT idTipoLista
                    FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
                    WHERE tipo = 1 AND calif_id = @calif_id
                    )
            )
    BEGIN --IF

        CREATE TABLE #NUMANDBL (id int identity,  iddncList int)
        CREATE TABLE #NUMBERS (id int identity, number varchar(30))
        DECLARE @allnumbersToBl BIT
        DECLARE @number varchar(30)

        SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id

        IF(@allnumbersToBl = 1)
        BEGIN
            SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall
            DECLARE @i SMALLINT = 0
            WHILE (@i < 5 )
            BEGIN
                SELECT @number = CASE @i
                                    WHEN 0 THEN cal_telefono
                                    WHEN 1 THEN cal_telefono2
                                    WHEN 2 THEN cal_telefono3
                                    WHEN 3 THEN cal_telefono4
                                    WHEN 4 THEN cal_telefono5
                                    END FROM ccoCallsOutSource WHERE callout_id = @callOutId AND cam_id = @camid
                SET @number = dbo.Completa_ListaNegra(@number)
                IF(LEFT(@number, 1) <> ''E'')
                BEGIN
                    INSERT INTO #NUMBERS (number) VALUES (@number)
                END
                SET @i = @i + 1
            END
        END
        ELSE
        BEGIN
            SELECT @number = co.cal_telefono
            FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
            WHERE co.cal_id = @idCall
            SET @number = dbo.Completa_ListaNegra(@number)
            IF(LEFT(@number, 1) <> ''E'')
            BEGIN
                INSERT INTO #NUMBERS (number) VALUES (@number)
            END
        END

        IF exists(SELECT 1 FROM #NUMBERS) begin
            INSERT INTO #NUMANDBL (iddncList)
            select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
        END

        DECLARE @Count int
        DECLARE @firstList bit = 1;  -- Solo la primera lista dispara limpieza WT/CS

        WHILE (SELECT count(id) from #NUMANDBL) > 0
        BEGIN  --WHILE
            select @Count = count(id) from #NUMANDBL
            SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
            DECLARE @countNumbers INT, @indexNumbers INT = 1
            SELECT @countNumbers = COUNT(*) FROM #NUMBERS
            WHILE( @indexNumbers <= @countNumbers) --WHILE NUMBERS
            BEGIN
                SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers
                IF @tel IS NOT NULL AND @iddncList IS NOT NULL
                BEGIN--Tel adn iddnclist
                    IF (@firstList = 1)
                    BEGIN
                        -- Primera lista negra: inserta en BL + limpia WT/CS
                        EXEC ccsp_InsertDNCList_Static
                            @telephone          = @tel,
                            @ln_id              = @iddncList,
                            @calKey             = @cal_key,
                            @skipWorkingCleanup = 0;
                    END
                    ELSE
                    BEGIN
                        -- Listas negras restantes: solo insertan en ccListaNegra (sin tocar WT/CS)
                        EXEC ccsp_InsertDNCList_Static
                            @telephone          = @tel,
                            @ln_id              = @iddncList,
                            @calKey             = @cal_key,
                            @skipWorkingCleanup = 1;
                    END

                    IF (@killListSetting = 1 AND @iddncList = @killListID)
                    BEGIN
                        select @hashTel = dbo.hashPhone(@tel)

                        IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
                        BEGIN
                            INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
                            VALUES (@hashTel, @iddncList, GETDATE())
                        END
                    END

                    INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
                    SELECT @tel, @iddncList, co.cam_id, getdate(), co.callout_id, 6
                    FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
                    WHERE co.cal_id = @idCall
                END --Tel adn iddnclist
                SET @indexNumbers = @indexNumbers + 1
            END --WHILE NUMBERS

            -- Despues de procesar la primera lista negra,
            -- marcamos que las siguientes ya NO deben limpiar WT/CS.
            IF (@firstList = 1)
                SET @firstList = 0;

            DELETE #NUMANDBL WHERE id = @Count
        END --WHILE
        DROP TABLE #NUMANDBL
        DROP TABLE #NUMBERS
    END --IF

    IF @RecicleSIC = 1
    BEGIN
        -- Toma como prioridad la configuración de la subcalificación (en caso de existir)
        SELECT @Reprogram = CanReprogram
        FROM ccTipoCalifSubout
        WHERE califSub_Id = @subId

        -- Si no tiene subcalificacion toma la de la calificacion
        IF @Reprogram IS NULL
        BEGIN
            SELECT @Reprogram = CanReprogram
            FROM ccTipoCalifOUT
            WHERE calif_id = @calif_id
        END

        IF @callOutId = 0
            SELECT @callOutId = callout_id
            FROM ccocallsout
            WHERE Cal_id = @IDCall

        UPDATE ccoWorkingTable
        SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
        WHERE callout_id = @callOutId
    END

    DECLARE @keepDial BIT
    DECLARE @finishPreview BIT

    -- Toma como prioridad la configuración de la subcalificación (en caso de existir)
    SELECT @keepDial = keepDial
    FROM ccTipoCalifSubout
    WHERE califSub_Id = @subId

    -- Si no tiene subcalificacion toma la de la calificacion
    IF @keepDial IS NULL
    BEGIN
        SELECT @keepDial = keepDial
        FROM ccTipoCalifout
        WHERE calif_id = @calif_id
    END

    SELECT @finishPreview = isnull(finishPreview, 0)
    FROM ccTipoCalifout
    WHERE calif_id = @calif_id

    IF @keepDial = 1
    BEGIN
        UPDATE ccologdials
        SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
        WHERE logDial_id IN (
                SELECT TOP 1 L.logDial_id
                FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
                JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
                WHERE O.cal_id = @IDCall
                ORDER BY L.logDial_id DESC
                )
    END

    SELECT @keepDial as keepDial, @finishPreview as finishPreview

    RETURN (0)
END

SET NOCOUNT OFF'
    EXEC(@sql)

     SET @process = 'Alter procedure ccsp_InsertDNCList'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as nvarchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL,
@cleanType int=0, --0 limpia,2 verifica
@skipWorkingCleanup bit = 0 -- 0 = hace toda la limpieza WT/CS, 1 = SOLO inserta en ccListaNegra
AS
BEGIN
SET NOCOUNT ON;

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

declare @hashList bigint =dbo.hashList(@calKey)

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificacion
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = @hashList) begin
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

    set @params=''@ln_id int, @phoneEmpty nvarchar(1),@motivo nvarchar(100),@keyTranslate nvarchar(100)''
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id
    ,@phoneEmpty=@phoneEmpty,@motivo =@motivo ,@keyTranslate =@keyTranslate

end

set @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.idtipolista = @ln_id AND B.telefono is not null''

set @params=''@ln_id int''
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey
FROM '' + @tmpTableName + '' A

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista
FROM '' + @tmpTableName + '' A '';

EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;


IF (@skipWorkingCleanup = 0)
BEGIN

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

    EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

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
    else @phoneEmpty end
    ,wt.iZonaHoraria=null, wt.iZonaHoraria_verano=null''

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

    UPDATE_CALL_WT_QUERY

    --insertar el historial
    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    -- Eliminamos el telefono1 de CS
    update ccoCallsOutSource
    set COLUMN_CHECK = @phoneEmpty
    ,COLUMN_ZONE_CHECK=0
    ,COLUMN_ZONE_CHECK_VERANO=0
    from ccoCallsOutSource cs
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech

    truncate table #mytempCall
end''


    /******************/
    /*** Telefono 1 ***/
    /******************/

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria'')

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

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano2'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria2'')

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

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano3'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria3'')

    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech

    /******************/
    /*** Telefono 4 ***/
    /******************/

    set @column=''cal_telefono4''

    set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''

    set @sqlCaseWorking='' case when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5
        else @phoneEmpty end ''

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano4'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria4'')

    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech

    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''cal_telefono5''
    set @sqlDeleteWorking=''''
    set @sqlCaseWorking=''''

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'','''')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano5'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria5'')

    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall'') IS NOT NULL drop table #helpTempCall


END -- IF @skipWorkingCleanup = 0
    ----------------------------------------------------------------

IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);
END'
    EXEC(@sql)



    -------------------- END 127.20250905.0.8 Carlos Chavez ------------------------

    ------------------------- Begin KR234005 Marco Garcia -----------------------------------
	SET @process = 'KR234005 drop store procedure ccsp_RIAConfCamp'
	SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIAConfCamp'')
        Begin
            DROP PROCEDURE ccsp_RIAConfCamp
        End';
	EXEC(@sql);

	SET @process = 'KR234005 create store procedure ccsp_RIAConfCamp'
	SET @sql = N'CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
    @User_id SMALLINT,
    @campID INT = NULL
AS
    SET NOCOUNT ON;

    DECLARE @tableExistsRec TABLE (
        camId INT PRIMARY KEY,
        existRec BIT
    );
    DECLARE @camByUser TABLE (
        camId INT PRIMARY KEY,
        isCheck BIT
    );
    DECLARE @camId INT, @id INT;
    DECLARE @intenationalDialingPorts BIT;
    DECLARE @tempInternationalCode INT;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT TOP 1 IdCode
            FROM ccoDialers ccoDial
            INNER JOIN ccoDialerCamp ccoDialCamp ON ccoDialCamp.dialer_id = ccoDial.dialer_id
            WHERE ccoDialCamp.cam_id = @campID
                AND ccoDial.DialingType = 0
        ) result
    ) > 0
    BEGIN
        SET @intenationalDialingPorts = 1;
    END
    ELSE
    BEGIN
        SET @intenationalDialingPorts = 0;
    END;

    IF NOT EXISTS (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
            AND Rol_id = 7
    )
    BEGIN
        INSERT INTO @camByUser
        SELECT *, 0
        FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
        WHERE @campID IS NULL
            OR cam_id = @campID;
    END
    ELSE
    BEGIN
        INSERT INTO @camByUser
        SELECT cam_id, 0
        FROM ccCamps
        WHERE (IDArea > 0 OR IDArea IS NULL)
            AND (@campID IS NULL OR cam_id = @campID);
    END;

    WHILE EXISTS (
        SELECT *
        FROM @camByUser
        WHERE isCheck = 0
    )
    BEGIN
        SELECT TOP 1 @camId = camId
        FROM @camByUser
        WHERE isCheck = 0;

        IF EXISTS (
            SELECT cam_id
            FROM ccoCallsOut
            WHERE cam_id = @camId
        )
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 1);
        END
        ELSE
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 0);
        END;

        UPDATE @camByUser
        SET isCheck = 1
        WHERE camId = @camId;
    END;

    SELECT
        a1.cam_id,
        cam_Descripcion,
        cam_tNotas,
        CAST(cam_ocupado AS INT) AS cam_ocupado,
        cam_noInt_ocupado,
        cam_inter_ocupado,
        CAST(cam_nocontesto AS INT) AS cam_nocontesto,
        cam_noInt_nocontesto,
        cam_inter_nocontesto,
        CAST(cam_fax AS INT) AS cam_fax,
        cam_noInt_fax,
        cam_inter_fax,
        CAST(cam_modomanual AS INT) AS cam_modomanual,
        ANI,
        cam_ShowCalifWnd,
        cam_StartTimerOnHangUp,
        editableCallKey,
        cam_tNoContesta,
        iTipoDial,
        detectAnswerMachine,
        detectVoiceMail,
        compliance,
        cam_inter_graba,
        cam_noint_graba,
        CAST(progDial AS TINYINT) progDial,
        CAST(excCallBack AS TINYINT) excCallBack,
        dialOrder,
        dialPrefix,
        dialPrefixMan,
        dialPrefixXfe,
        listenManualCall,
        stopRecording,
        CAST(abandonCallback AS TINYINT) abandonCallback,
        a3.frame,
        a1.t_autoCB,
        a1.id_anilist,
        a1.tDialonWrapUp,
        dbo.fn_viewMode(@User_id, 10) viewMode,
        cam_maxqueue AS queSize,
        DNCScrub,
        callerIdDesc,
        timeZoneRule,
        callsBySurvey,
        ivrScript,
        surveyPctg,
        ISNULL(a1.call_record, 1) AS call_record,
        CAST(startStopRecording AS TINYINT) startStopRecording,
        leaveRecMessage,
        manualCallOnChat,
        callBackSurveyAgent,
        callBackSurveyClient,
        CASE
            WHEN surveycamid IS NULL OR surveycamid = 0 THEN 0
            ELSE 1
        END isRelationSurvey,
        ISNULL(a1.funcEspDtmf, 0) funcEspDtmf,
        ISNULL(sipHdrFormat, '''') sipHdrFormat,
        cam_inter_cancelled,
        prefijo,
        enbleprefix = CASE
            WHEN existRec = 0 THEN 1
            ELSE 0
        END,
        ISNULL(exitAssisted, 0) exitAssisted,
        ISNULL(previewDiscard, 0) PreviewDiscard,
        case when CampType = 9 then 10 else ISNULL(CampType, 0) end as CampType,
        ISNULL(contact.conexionInfo, '''') conexionInfo,
        ISNULL(contact.connUser, '''') connUser,
        ISNULL(contact.closeConversationTime, 0) closeConversationTime,
        ISNULL(contact.answerTimeoutClient, 0) answerTimeoutClient,
        ISNULL(contact.allowFileAttachments, 0) allowFileAttachments,
        ISNULL(selectRotativeANI, 0) selectRotativeANI,
        ISNULL(rotativeAlgo, 0) rotativeAlgo,
        ISNULL(autoStart, 0) autoStart,
        ISNULL(messagingOrder, 0) messagingOrder,
        ISNULL(cam_tPreview, 0) AS CamTPreview,
        ISNULL(timesPreview, 0) AS TimesPreview,
        ISNULL(timesDiscard, 0) TimesDiscard,
        ISNULL(recordHold, 0) recordHold,
        ISNULL(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule,
        ISNULL(campsExtention.RecordCalls, 1) RecordCalls,
        ISNULL(campsExtention.simultaneousRecs, 1) simultaneousRecs,
        ISNULL(campsExtention.EditableContactData, 0) EditableContactData,
        @intenationalDialingPorts intenationalDialingPorts,
        ISNULL(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent,
        ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations,
        ISNULL(contact.MaxDaysPerWAConvo, 5) MaxDaysPerWAConvo,
        isnull(recordIvr, 1) recordIvr,
        ISNULL(CamCanceled, 4) CamCanceled,
        ISNULL(surveyCamId, 0) surveyCamId,
        -- Outbound AI Campaign Special Settings
        ISNULL(campsExtention.RescheduledSurveyAI, 0) RescheduledSurveyAI,
        ISNULL(campsExtention.ImmediateSurveyAI, 0) ImmediateSurveyAI,
        ISNULL(campsExtention.ApplyRescheduledSurveyForCompletedCallsAI, 0) ApplyRescheduledSurveyForCompletedCallsAI,
        ISNULL(campsExtention.EnableCallRecordingAI, 0) EnableCallRecordingAI,
		-- Manual Rotation Dialing Configurations
		ISNULL(a1.rotativeAlgorithmManual, 4) RotativeAlgorithmManual ,
		ISNULL(a1.idAniListManual, 0) IdAniListManual ,
		ISNULL(a1.selectRotationManualDialing, 0) SelectRotationManualDialing
    FROM ccCamps a1
    INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
    INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
    LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
    LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
    ORDER BY cam_descripcion;

    RETURN (0);

    SET NOCOUNT OFF;
';
	EXEC(@sql);

	SET @process = 'KR234005 drop store procedure ccsp_GalateaGetOutboundConfiguration'
	SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaGetOutboundConfiguration'')
        Begin
            DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration
        End';
	EXEC(@sql);

	SET @process = 'KR234005 create store procedure ccsp_GalateaGetOutboundConfiguration'
	SET @sql = N'
    CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
    @adminID INT
    ,@campID INT
    AS
    BEGIN

        DECLARE @AllCampaigns TABLE (
        cam_id SMALLINT
        ,cam_Descripcion VARCHAR(60)
        ,cam_tNotas SMALLINT
        ,cam_ocupado SMALLINT
        ,cam_noInt_ocupado SMALLINT
        ,cam_inter_ocupado SMALLINT
        ,cam_nocontesto SMALLINT
        ,cam_noInt_nocontesto SMALLINT
        ,cam_inter_nocontesto SMALLINT
        ,cam_fax SMALLINT
        ,cam_noInt_fax SMALLINT
        ,cam_inter_fax SMALLINT
        ,cam_modomanual SMALLINT
        ,ANI VARCHAR(15)
        ,cam_ShowCalifWnd BIT
        ,cam_StartTimerOnHangUp BIT
        ,editableCallKey BIT
        ,cam_tNoContesta SMALLINT
        ,iTipoDial SMALLINT
        ,detectAnswerMachine SMALLINT
        ,detectVoiceMail SMALLINT
        ,compliance SMALLINT
        ,cam_inter_graba SMALLINT
        ,cam_noint_graba SMALLINT
        ,progDial SMALLINT
        ,excCallBack SMALLINT
        ,dialOrder SMALLINT
        ,dialPrefix VARCHAR(10)
        ,dialPrefixMan VARCHAR(10)
        ,dialPrefixXfe VARCHAR(10)
        ,listenManualCall BIT
        ,stopRecording BIT
        ,abandonCallback BIT
        ,frame SMALLINT
        ,t_autoCB SMALLINT
        ,id_anilist INT
        ,tDialonWrapUp SMALLINT
        ,viewMode TINYINT
        ,queSize SMALLINT
        ,DNCScrub INT
        ,callerIdDesc VARCHAR(15)
        ,timeZoneRule INT
        ,callsBySurvey INT
        ,ivrScript INT
        ,surveyPctg INT
        ,call_record SMALLINT
        ,startStopRecording BIT
        ,leaveRecMessage BIT
        ,manualCallOnChat BIT
        ,callBackSurveyAgent BIT
        ,callBackSurveyClient BIT
        ,isRelationSurvey BIT
        ,funcEspDtmf INT
        ,sipHdrFormat VARCHAR(255)
        ,cam_inter_cancelled SMALLINT
        ,prefijo VARCHAR(40)
        ,enbleprefix BIT
        ,exitAssisted BIT
        ,previewDiscard BIT
        ,CampType INT
        ,conexionInfo VARCHAR(50)
        ,connUser VARCHAR(15)
        ,closeConversationTime INT
        ,answerTimeoutClient INT
        ,allowFileAttachments BIT
        ,selectRotativeANI INT
        ,rotativeAlgo TINYINT
        ,autoStart BIT
        ,messagingOrder BIT
        ,CamTPreview SMALLINT
        ,TimesPreview TINYINT
        ,timesDiscard TINYINT
        ,recordHold BIT
        ,zipCodeSchedule BIT
        ,RecordCalls tinyint
        ,simultaneousRecs smallint
        ,EditableContactData bit
        ,internationalDialingPortsAssigned bit
        ,AssignConversationSameAgent bit
        ,maxLimitQueueConversations SMALLINT
        ,MaxDaysPerWAConvo SMALLINT
        ,RecordIvr BIT
        ,CamCanceled INT
        ,surveyCamId int
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI BIT
        ,ImmediateSurveyAI BIT
        ,ApplyRescheduledSurveyForCompletedCallsAI BIT
        ,EnableCallRecordingAI BIT
		-- Manual Rotation Dialing Configurations
		,rotativeAlgorithmManual SMALLINT
		,idAniListManual SMALLINT
		,selectRotationManualDialing BIT
        )
        DECLARE @numbers VARCHAR(max)

        SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
        FROM ccWhatsAppNumbers
        WHERE camp_id = 0
        AND STATUS = 1

        SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
        FROM ccMetaWhatsAppNumbers
        WHERE Cam_Id = 0 or Cam_Id is null
        AND STATUS = 1

        INSERT INTO @AllCampaigns
        EXEC ccsp_RIAConfCamp @adminID
        ,@campID

        -- consulta para extraer las variables del script
        DECLARE @ScriptVariables NVARCHAR(MAX);
        WITH RecursiveExtraction AS (
            SELECT
                CAST(SUBSTRING(scriptAgent, CHARINDEX(''{{'', scriptAgent) + 2,
                CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) - 2) AS VARCHAR(MAX)) AS Variable,
                CAST(STUFF(scriptAgent, CHARINDEX(''{{'', scriptAgent),
                CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
            FROM dbo.ccVirtualAgent
            WHERE CHARINDEX(''{{'', scriptAgent) > 0
            AND idCampaign = @campID AND campType = 1

            UNION ALL

            SELECT
                CAST(SUBSTRING(RemainingText, CHARINDEX(''{{'', RemainingText) + 2,
                CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) - 2) AS VARCHAR(MAX)) AS Variable,
                CAST(STUFF(RemainingText, CHARINDEX(''{{'', RemainingText),
                CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
            FROM RecursiveExtraction
            WHERE CHARINDEX(''{{'', RemainingText) > 0
        )
        SELECT @ScriptVariables = STUFF((
            SELECT '', '' + Variable
            FROM RecursiveExtraction
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''');

        SELECT
        dialPrefixMan DialPrefixMan
        ,dialPrefixXfe DialPrefixXfe
        ,listenManualCall ListenManualCall
        ,stopRecording StopRecording
        ,abandonCallback AbandonCallBack
        ,t_autoCB AutoCB
        ,id_anilist IdIstANI
        ,tDialonWrapUp TDialOnWrapup
        ,queSize Quesize
        ,DNCScrub
        ,callerIdDesc CallerIdDesc
        ,timeZoneRule TimeZoneRule
        ,callsBySurvey CallsBySurvey
        ,ivrScript IvrScript
        ,surveyPctg SurveyPctg
        ,call_record CallRecord
        ,startStopRecording StartStopRecording
        ,leaveRecMessage LeaveRecMessage
        ,manualCallOnChat ManualCallOnChat
        ,callBackSurveyClient CallBackSurveyClient
        ,callBackSurveyAgent CallBackSurveyAgent
        ,funcEspDtmf FuncEspDtmf
        ,sipHdrFormat SipHdrsCfg
        ,dialPrefix DialPrefix
        ,prefijo Prefix
        ,dialOrder DialOrder
        ,progDial ProgDial
        ,cam_Descripcion CamDescription
        ,cam_tNotas CamTnotas
        ,cam_ocupado CamBusy
        ,cam_noInt_ocupado CamNoIntBusy
        ,cam_inter_ocupado CamInterBusy
        ,cam_nocontesto CamNoAnswer
        ,cam_noInt_nocontesto CamNoIntNoAnswer
        ,cam_inter_nocontesto CamInterNoAnswer
        ,(cam_inter_cancelled / 60) CamInterCancelled
        ,cam_fax CamFax
        ,cam_noInt_fax CamNoIntFax
        ,cam_inter_fax CamInterFax
        ,cam_modomanual CamModoManual
        ,ANI
        ,cam_StartTimerOnHangUp CamStartTimerOnHangUp
        ,editableCallKey EditableCallKey
        ,cam_tNoContesta CamTNoAnswer
        ,iTipoDial CamIntensiveDialing
        ,detectAnswerMachine DetectAnswerMachine
        ,detectVoiceMail DetectVoiceMail
        ,compliance Compliance
        ,cam_inter_graba CamInterRecord
        ,cam_noint_graba CamNoIntRecord
        ,excCallBack ExcCallBack
        ,cam_ShowCalifWnd CamShowCalifWnd
        ,frame Frame
        ,exitAssisted ExitAssistedDialMode
        ,previewDiscard PreviewDiscard
        ,CampType
        ,conexionInfo ConexionInfo
        ,connUser ConnUser
        ,closeConversationTime CloseConversationTime
        ,answerTimeoutClient MUTimeOutClient
        ,allowFileAttachments AllowFileAttachments
        ,CamTPreview
        ,CAST(TimesPreview AS SMALLINT) TimesPreview
        ,@numbers AS FreeNumbers
        ,selectRotativeANI SelectRotativeANIManualCall
        ,rotativeAlgo RotativeAlgo
        ,autoStart AutoStart
        ,messagingOrder MessagingOrder
        ,timesDiscard TimesDiscard
        ,recordHold RecordHold
        ,zipCodeSchedule ZipCodeSchedule
        ,RecordCalls RecordCalls
        ,simultaneousRecs SimultaneousRecs
        ,EditableContactData EditableContactData
        ,internationalDialingPortsAssigned internationalDialingPortsAssigned
        ,AssignConversationSameAgent AssignConversationSameAgent
        ,maxLimitQueueConversations MaxLimitQueueConversations
        ,MaxDaysPerWAConvo DaysVisualConversationWhatsApp
        ,RecordIvr
        ,ISNULL(CamCanceled, 0) CamCanceled
        ,surveyCamId SurveyCamId
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI
        ,ImmediateSurveyAI
        ,ApplyRescheduledSurveyForCompletedCallsAI
        ,EnableCallRecordingAI
		-- Manual Rotation Dialing Configurations
		,rotativeAlgorithmManual RotativeAlgorithmManual
		,idAniListManual IdAniListManual
		,selectRotationManualDialing SelectRotationManualDialing
        ,@ScriptVariables AS ScriptVariables
        FROM @AllCampaigns
        WHERE cam_id = @campID
    END';
	EXEC(@sql);


	SET @process = 'KR234005 drop store procedure ccsp_RIAUpdateCamConfig'
	SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIAUpdateCamConfig'')
        Begin
            DROP PROCEDURE ccsp_RIAUpdateCamConfig
        End';
	EXEC(@sql);

	SET @process= 'KR234005 create store procedure ccsp_RIAUpdateCamConfig'
	SET @sql ='CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
    @cam_id smallint,
    @cam_descripcion varchar(40) = null,
    @cam_tnotas smallint = null,
    @cam_ocupado tinyint = null,
    @cam_NoInt_ocupado tinyint = null,
    @cam_inter_ocupado smallint = null,
    @cam_nocontesto tinyint = null,
    @cam_NoInt_nocontesto tinyint = null,
    @cam_inter_nocontesto smallint = null,
    @cam_fax tinyint = null,
    @cam_NoInt_fax tinyint = null,
    @cam_inter_fax smallint = null,
    @cam_ModoManual tinyint= null,
    @ANI varchar(15) = null,
    @cam_ShowCalifWnd bit = null,
    @cam_StartTimerOnHangUp bit = null,
    @editableCallKey bit = null,
    @cam_tNoContesta tinyint = null,
    @cam_intensive_dialing tinyint = null,
    @detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
    @detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
    @compliance TinyInt = null,
    @cam_inter_graba smallint = null,
    @cam_NoInt_graba tinyint = null,
    @progDial smallint = null,
    @excCallBack Tinyint = null,
    @dialOrder Tinyint = null,
    @dialPrefix varchar(10) = null,
    @dialPrefixMan varchar(10) = null,
    @dialPrefixXfe varchar(10) = null,
    @listenManualCall bit = null,
    @stopRecording bit = null,
    @abandonCallback bit = null,
    @autoCB smallint = null,
    @id_listAni int = null,
    @tDialonWrapUp smallint = null,
    @quesize smallint=null,
    @DNCScrub int=null,
    @callerIdDesc varchar(15)=null,
    @timeZoneRule int=null,
    @callsBySurvey int=null,
    @ivrScript int=null,
    @surveyPctg int=null,
    @call_record tinyint=null,
    @dRestrictPlay bit = null,
    @leaveRecMessage bit = null,
    @manualCallOnChat bit = null,
    @callBackSurveyClient bit = null,
    @callBackSurveyAgent bit = null,
    @funcEspDtmf int =null,
    @sipHdrsCfg varchar(255) = null,
    @cam_inter_cancelled smallint = null,
    @prefijo varchar(max) = null,
    @exitAssisted bit = null,
    @previewDiscard bit = null,
    @rotativeAlgo tinyint = null,
    @timesPreview tinyint = null,
    @cam_tPreview smallint = null,
    @timesDiscard tinyint = null,
    @CampType int = null,
    @agentCloseConversationTime SMALLINT = NULL,
    @adminCloseConversationTime INT = NULL,
    @ConexionInfo VARCHAR(400) = NULL,
    @allowFileAttachments BIT = NULL,
    @selectRotativeANI int = null,
    @messagingOrder bit = null,
    @autoStart bit = null,
    @recordHold bit = null,
    @userId                SMALLINT     = NULL,
    @idArea                SMALLINT     = NULL,
    @isCreating            SMALLINT          = NULL,
    @camCanceled int = null,
    @recordIvr bit = null,
    @module INT = -1,
    @maxLimitQueueConversations SMALLINT = NULL,
    @maxDaysPerWAConvo SMALLINT = NULL,
	@rotativeAlgorithmManual smallint = null,
	@idAniListManual smallint = NULL,
	@selectRotationManualDialing BIT = NULL
    as
    set nocount ON

    IF EXISTS (SELECT 1 FROM ccCamps WHERE cam_descripcion = @cam_descripcion AND cam_id <> @cam_id)
    BEGIN
        SELECT -1 -- Nombre ya esta en uso
        RETURN(0)
    END

    DECLARE @timesDiscardActual int = -1, @camCanceledActual int = -1, @recordIvrActual int = -1
    SELECT @timesDiscardActual = timesDiscard, @camCanceledActual = camcanceled, @recordIvrActual = recordIvr FROM ccCamps WHERE cam_id = @cam_id
    DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
        DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

    UPDATE ccCamps SET
        cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
        cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
        cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
        cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
        cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
        cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
        cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
        cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
        cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
        cam_fax = isnull(@cam_fax,cam_fax),
        cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
        cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
        cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
        ANI = isnull(@ANI,ANI),
        cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
        editableCallKey = isnull(@editableCallKey, editableCallKey),
        cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
        iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
        detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
        detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
        compliance = isnull(@compliance, compliance),
        cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
        cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
        cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
        progDial = isnull(@progDial, progDial),
        excCallBack = isnull(@excCallBack,excCallBack),
        dialOrder = isnull(@dialOrder, dialOrder),
        dialPrefix = isnull(@dialPrefix, dialPrefix),
        dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
        dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
        listenManualCall = isnull(@listenManualCall, listenManualCall),
        stopRecording = isnull(@stopRecording, stopRecording),
        abandonCallback = isnull(@abandonCallback, abandonCallback),
        t_autoCB = isnull(@autoCB,t_autoCB),
        id_anilist = isnull(@id_listAni,id_anilist),
        tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
        cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
        cam_maxqueue = isnull(@quesize,cam_maxqueue),
        DNCScrub = isnull(@DNCScrub,DNCScrub),
        callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
        timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
        callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
        ivrScript = isnull(@ivrScript,ivrScript),
        surveyPctg = isnull(@surveyPctg,surveyPctg),
        call_record = isnull(@call_record,call_record),
        startStopRecording = isnull(@dRestrictPlay, startStopRecording),
        leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
        manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
        callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
        callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
        funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
        sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
        prefijo = isnull(@prefijo, prefijo),
        exitAssisted = isnull(@exitAssisted, exitAssisted),
        previewDiscard = isnull(@previewDiscard, previewDiscard),
        rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
        timesPreview = isnull(@timesPreview, timesPreview),
        cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
        timesDiscard = isnull(@timesDiscard, timesDiscard),
        CampType = (CASE WHEN @callsBySurvey is not null AND @ivrScript is not null THEN
                        CASE WHEN @callsBySurvey=0 and @ivrScript=0 THEN 0
                            ELSE 8
                        END
                    WHEN @CampType is not null THEN @CampType
                    WHEN @progDial = 2 THEN 6
                    WHEN @progDial IS NOT NULL AND @progDial <> 2 and @CampType is not null THEN 0
                    WHEN CampType is not null THEN CampType ELSE 0 END),
        selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
        messagingOrder = isnull(@messagingorder, messagingOrder),
        autoStart = isnull(@autoStart,autoStart),
        recordHold = isnull(@recordHold, recordHold),
        CamCanceled = ISNULL(@camCanceled, CamCanceled),
        recordIvr = isnull(@recordIvr, recordIvr),
		rotativeAlgorithmManual = ISNULL(@rotativeAlgorithmManual, rotativeAlgorithmManual),
		idAniListManual = ISNULL(@idAniListManual, idAniListManual),
		selectRotationManualDialing = ISNULL(@selectRotationManualDialing, selectRotationManualDialing)
        Where cam_id = @cam_id

            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

            Create table #ccCampsTable
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            )

            DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN
                                                                        CASE
                                                                            WHEN @Camptype = 6  THEN 44
                                                                            WHEN @Camptype = 5  THEN 46
                                                                            WHEN @Camptype IN(4, 9, 10)  THEN 48
                                                                            WHEN @Camptype = 7  THEN 50
                                                                            ELSE 42 END
                                                                    ELSE
                                                                        CASE
                                                                            WHEN @Camptype = 6  THEN 55
                                                                            WHEN @Camptype = 5  THEN 56
                                                                            WHEN @Camptype IN(4, 9, 10)  THEN 57
                                                                            WHEN @Camptype = 7  THEN 58
                                                                            ELSE 54 END
                                                                    END;

            IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

            IF(@isCreating = 1)
            BEGIN
                DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
            END

            IF(@isCreating = 2)
            BEGIN
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) AND @recordIvrActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) and @camCanceledActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
            END

            DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
            DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';

            IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
            ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
            ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
            ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
            ELSE IF(@CampType = 9) DELETE FROM #ccCampsTable WHERE columnInfo IN (''timeZoneRule'', ''CampType'');
            ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
                getDate(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
                @operation,
                @module,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                    THEN
                        CASE
                            WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                                CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                            WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN
                                CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
                            WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                                CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
                            ELSE
                                CCCT.identifierInfo
                            END
                    ELSE
                    ''''
                    END,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                    CASE
                        WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                            CASE WHEN CCCT.dataInfo = ''VOICEMAIL''
                                THEN ''COMMON_VOICE_MAIL''
                                ELSE
                                    CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END
                                END
                        WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                        WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                        WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC''
                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                                ELSE ''T&COMMON_NONE'' END

                        WHEN CCCT.identifierInfo in (''OUT_ANI_MODE'', ''OUT_ANI_MODE_MANUAL'') THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL''
                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                                ELSE ''T&COMMON_NONE'' END

                        WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE''
                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                                ELSE ''COMMON_ASSISTED'' END

                        WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                            CASE WHEN  @CampType = 5 THEN
                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                            ELSE
                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                    WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                    WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                    ELSE ''T&COMMON_NONE'' END
                            END

                        WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                    CASE @rotativeAlgo
                                                WHEN 1 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                WHEN 0 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccEdoAniList WHERE id_AniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                ELSE
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                        ISNULL(
                                                            (SELECT [description] FROM ccEdoAniList WHERE id_AniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                            CCCT.dataInfo
                                                        )
                                                    )
                                    END
						WHEN CCCT.identifierInfo = ''OUT_ANI_LIST_MANUAL'' THEN
								CASE @rotativeAlgorithmManual
												WHEN 4 THEN  ''T&COMMON_NONE''
                                                WHEN 1 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                WHEN 0 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccEdoAniList WHERE id_AniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                ELSE
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                        ISNULL(
                                                            (SELECT [description] FROM ccEdoAniList WHERE id_AniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                            CCCT.dataInfo
                                                        )
                                                    )
                                    END
                        WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                        WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                    ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                    ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'',
													''OUT_SELECT_ANI_MANUAL_DIALING'') THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END

                        ELSE CCCT.dataInfo END
                ELSE '''' END,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
            FROM #ccCampsTable AS CCCT
            WHERE CCCT.identifierInfo IS NOT NULL;

            EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

    if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
    begin
        EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
    end

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        update ccMetaWhatsAppNumbers set Cam_Id=0 where Cam_Id=@cam_id

        IF(@ConexionInfo <> '''')
        BEGIN
            IF EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @ConexionInfo)
                UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
            IF EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @ConexionInfo)
                UPDATE ccMetaWhatsAppNumbers SET Cam_Id = @cam_id WHERE number = @ConexionInfo
        END
    END

    IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
    BEGIN
        IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
        BEGIN
            SELECT 0
            RETURN(0)
        END

        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

        Create table #contactMeanOutTable
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

        DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

        set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
        UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                                                closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
                                allowFileAttachments = @allowFileAttachments,
                    maxLimitQueueConversations = @maxLimitQueueConversations,
                    MaxDaysPerWAConvo = @maxDaysPerWAConvo
        WHERE @CampType = meanContactTypeId AND camp_id = @cam_id


        IF(@isCreating > 0 AND @module > -1) BEGIN
            EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
            IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
        END

        DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
        DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(),          (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
            @operation,
            @module,
            CMOT.identifierInfo,
            CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
                CASE
                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                        CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
                        CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
                    ELSE CMOT.dataInfo END
            ELSE '''' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        FROM #contactMeanOutTable AS CMOT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable
    END
    DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

    IF @cam_ShowCalifWnd = 1
    BEGIN
        IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
        BEGIN
            SELECT 0
            RETURN(0)
        END

        UPDATE ccCamps SET
        cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
        WHERE cam_id = @cam_id


        IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                getDate(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
                @operation,
                3,
                ''OUT_SHOW_DISPOSITIONS'',
                CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
        END

        SELECT 1
        RETURN(0)
    END

    UPDATE ccCamps SET
    cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
    where cam_id = @cam_id

    IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
            @operation,
            3,
            ''OUT_SHOW_DISPOSITIONS'',
            CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
    END

    SELECT 2
    RETURN(0)

    set nocount off'
	EXEC(@sql)



	------------------------- END KR234005 Marco Garcia -----------------------------------

 ------------------------ BEGIN Marco Antonio Díaz KR234006------------------------
       SET @process = 'KR234006 Drop procedure ccsp_ManualCallGetRotativeAni if exists'
       SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_ManualCallGetRotativeAni'')
                    BEGIN
                        DROP PROCEDURE ccsp_ManualCallGetRotativeAni;
                    END'
        EXEC(@sql);

        SET @process = 'KR234006 procedure to call rotation from the agent'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ManualCallGetRotativeAni]
                    @phones VARCHAR(MAX),
                    @camId INT
                    AS
                    set nocount on

                    DECLARE @aniId INT;
                    DECLARE @rotativeAlgo INT;
                    DECLARE @isManualRotationActive BIT;
                    DECLARE @Anis TABLE(id INT, pid VARCHAR(2), phone VARCHAR(32), ani VARCHAR(32));

                    SELECT @aniId = idAniListManual, @rotativeAlgo = rotativeAlgorithmManual, @isManualRotationActive = ISNULL(selectRotationManualDialing, 0) FROM ccCamps WHERE cam_id = @camId;

                    IF (@isManualRotationActive = 1 AND @aniId IS NOT NULL) BEGIN
                    INSERT @Anis
                    EXEC ccsp_DLRGetRotativeANI @callout_id=0, @phones=@phones, @aniList=@aniId,@algo=@rotativeAlgo;
                    END

                    IF(SELECT COUNT(*) FROM @Anis) > 0 BEGIN
                        SELECT TOP 1 ani FROM @Anis
                    END ELSE IF EXISTS (SELECT valor FROM ccSettings WHERE setting_id = 177) BEGIN
                        SELECT valor FROM ccSettings WHERE setting_id = 177
                    END ELSE BEGIN
                        SELECT ''''
                    END

                    set nocount off'
        EXEC(@sql);

       SET @process = 'KR234006 Drop procedure ccsp_ValidateManualRotation if exists'
       SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_ValidateManualRotation'')
                BEGIN
                    DROP PROCEDURE ccsp_ValidateManualRotation;
                END'
          EXEC(@sql);

          SET @process = 'KR234006 procedure to validate manual rotation'
          SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ValidateManualRotation]
                @camId INT
                AS
                set nocount on

                SELECT TOP 1 ISNULL(selectRotationManualDialing, 0) FROM ccCamps WHERE cam_id = @camId;

                set nocount off'
EXEC(@sql);
    ------------------------ END Marco Antonio Díaz KR234006--------------------------


	--------------------- BEGIN MAGV #6302 ----------------------------------
	 SET @process = '#6302 Drop procedure ccsp_RIAUpdateCamConfigExtend if exists'
     SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_RIAUpdateCamConfigExtend'')
            BEGIN
                DROP PROCEDURE ccsp_RIAUpdateCamConfigExtend;
            END'
     EXEC(@sql);

	 SET @process = '#6302 CREATE PROCEDURE [ccsp_RIAUpdateCamConfigExtend]'
	 SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
        @cam_id SMALLINT,
        @zipCodeSchedule BIT = NULL,
        @userId SMALLINT = NULL,
        @idArea SMALLINT = NULL,
        @isCreating SMALLINT = NULL,
        @simultaneousRecs SMALLINT = NULL,
        @module INT = -1,
        @recordCalls TINYINT = 1,
        @editableContactData BIT = 1,
        @assignConversationSameAgent BIT = 0,
        @RescheduledSurveyAI BIT = 0,
        @ImmediateSurveyAI BIT = 0,
        @ApplyRescheduledSurveyForCompletedCallsAI BIT = 0,
        @EnableCallRecordingAI BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @country INT = (SELECT valor FROM ccSettings WHERE setting_id = 104);
        DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;

        IF EXISTS (SELECT * FROM ccCampsExtend WHERE cam_id = @cam_id)
        BEGIN
            EXEC InsertLogAdminGalatea @action = 1, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable;

            CREATE TABLE #ccCampsExtendTable
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            );

            DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
            DECLARE @operation SMALLINT = CASE
                WHEN @isCreating = 1 THEN
                    CASE
                        WHEN @Camptype = 6 THEN 44
                        WHEN @Camptype = 5 THEN 46
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 48 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 50
                        ELSE 42
                    END
                ELSE
                    CASE
                        WHEN @Camptype = 6 THEN 55
                        WHEN @Camptype = 5 THEN 56
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 57 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 58
                        ELSE 54
                    END
                END;

            UPDATE ccCampsExtend
            SET
                zipCodeSchedule = ISNULL(@zipCodeSchedule, zipCodeSchedule),
                simultaneousRecs = ISNULL(@simultaneousRecs, simultaneousRecs),
                RecordCalls = ISNULL(@recordCalls, RecordCalls),
                EditableContactData = ISNULL(@editableContactData, EditableContactData),
                AssignConversationSameAgent = ISNULL(@assignConversationSameAgent, AssignConversationSameAgent),
                -- Outbound AI Campaign Special Settings
                RescheduledSurveyAI = ISNULL(@RescheduledSurveyAI, RescheduledSurveyAI),
                ImmediateSurveyAI = ISNULL(@ImmediateSurveyAI, ImmediateSurveyAI),
                ApplyRescheduledSurveyForCompletedCallsAI = ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, ApplyRescheduledSurveyForCompletedCallsAI),
                EnableCallRecordingAI = ISNULL(@EnableCallRecordingAI, EnableCallRecordingAI)
            WHERE cam_id = @cam_id;

            IF (@isCreating > 0 AND @module > -1)
                EXEC InsertLogAdminGalatea @action = 2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId, @tableTemp = ''#ccCampsExtendTable'';

            IF (@idArea IS NULL OR @idArea = -1)
                SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id);

            IF (@isCreating = 1)
                DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') AND dataInfo = 0;

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                GETDATE(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
                @operation,
                @module,
                CCCE.identifierInfo,
                CASE
                    WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                        CASE
                            WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
                                CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                            WHEN @isCreating = 1 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' END
                                END
                            WHEN @isCreating = 2 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                END
                            WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
                                CASE
                                    WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
                                    WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
                                    WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
                                    ELSE ''COMMON_DISABLED''
                                END
                            ELSE CCCE.dataInfo
                        END
                    ELSE ''''
                END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
            FROM #ccCampsExtendTable AS CCCE WHERE CCCE.identifierInfo != @excludeIdentifier;

            EXEC InsertLogAdminGalatea @action = 3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable;

        END
        ELSE
        BEGIN
            INSERT INTO ccCampsExtend (
                cam_id,
                zipCodeSchedule,
                SimultaneousRecs,
                RecordCalls,
                AssignConversationSameAgent,
                RescheduledSurveyAI,
                ImmediateSurveyAI,
                ApplyRescheduledSurveyForCompletedCallsAI,
                EnableCallRecordingAI
            )
            VALUES (
                ISNULL(@cam_id, 0),
                ISNULL(@zipCodeSchedule, ''''),
                ISNULL(@simultaneousRecs, 0),
                ISNULL(@recordCalls, 0),
                ISNULL(@assignConversationSameAgent, 0),
                -- Outbound AI Campaign Special Settings
                ISNULL(@RescheduledSurveyAI, 0),
                ISNULL(@ImmediateSurveyAI, 0),
                ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, 0),
                ISNULL(@EnableCallRecordingAI, 1)
            );

            SET NOCOUNT OFF;
        END
        UPDATE ccCamps SET call_record = @recordCalls WHERE cam_id = @cam_id;
    END'
	EXEC(@sql)


	--------------------- END MAGV #6302 ----------------------------------
    --------------------- BEGIN DEGD ----------------------------------

    SET @process = 'Drop procedure ccsp_RIACampsManualCall if exists'
    SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_RIACampsManualCall'')
           BEGIN
               DROP PROCEDURE ccsp_RIACampsManualCall;
           END'
    EXEC(@sql);

    SET @process = 'CREATE PROCEDURE [ccsp_RIACampsManualCall]'
    SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIACampsManualCall]

    @option int,
		@UserID int = 0,
		@onChat int = 0,
		@campId int = 0
		AS
		set nocount on
		if(@option = 1)
		begin
			if (@onChat = 0)
			begin
				declare @mod smallint
				declare @IdArea smallint
				declare @DialingMode tinyint
				select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
				select @mod = defCampaing from ccRIACat_Areas A
				where A.IDArea = @IdArea
				select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual,
				isnull(c.selectRotativeANI, 0) selectRotativeANI
				, CASE WHEN c.ivrScript <> 0 AND c.callsBySurvey <> 0 THEN 8 ELSE isnull(c.CampType,0) END as CampType,
				CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
				isnull(c.timesPreview, 0) timesPreview,
				isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule
				from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
				join ccRIACampsGraph g ON g.cam_id = c.cam_id
				left join ccCampsExtend ce ON ce.cam_id = c.cam_id
				where ca.user_id = @UserID
					and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
				order by cam_descripcion
			end
			else
			begin
				select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
				, isnull(c.CampType,0) as CampType,
				isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule
				from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
				join ccRIACampsGraph g ON g.cam_id = c.cam_id
				join ccCampsExtend ce ON ce.cam_id = c.cam_id
				where ca.user_id = @UserID and manualCallOnChat = 1
				order by cam_descripcion
				SET NOCOUNT OFF;
			end
		end
		if(@option = 2)
		begin
			declare @aniList int
			declare @rotativeAniListId int
			select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId
			if @rotativeAniListId >0 begin
				select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
			end
			else begin
				select top 0 '''' telAni
			end
		end'
		exec (@sql);

    SET @process = 'Drop procedure ccsp_Limpia if exists'
    SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_Limpia'')
           BEGIN
               DROP PROCEDURE ccsp_Limpia;
           END'
    EXEC(@sql);

    SET @process = 'CREATE PROCEDURE [ccsp_Limpia]'
    SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_Limpia]

	@tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = '''', @dato1 VARCHAR(10)=''''
	AS
	SET NOCOUNT ON

	DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
	DECLARE @checkLd_In_ANILst SMALLINT = 0
	/***
	 4  as res lista Negra
	 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
	 3 as res Number notExists
	 1 as res Longitud invalida
	 0 as res Numero correcto

	***/
	SELECT @tel = dbo.limpia(@tel)

	SELECT @lon = len(@tel)

	SELECT @pais = valor
	FROM ccSettings WITH (NOLOCK)
	WHERE setting_id = 104

	SELECT @cldLocal = valor
	FROM ccSettings WITH (NOLOCK)
	WHERE setting_id = 17

	SELECT @extLen = valor
	FROM ccsettings WITH (NOLOCK)
	WHERE setting_id = 108

	SELECT @validateTel = valor
	FROM ccsettings WITH (NOLOCK)
	WHERE setting_id = 206

	SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213

	IF @lon > 1
	BEGIN

		IF @validateTel = 2
			BEGIN --Setting 206 only validates blacklist

				IF (SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList
					RETURN (0)
				END
				SELECT 0 AS res, @tel AS tel

				RETURN (0)

		END
		IF @validateTel = 1
		BEGIN --Setting 206 para no validar longitud ni listas negras
			SELECT 0 AS res, @tel AS tel

			RETURN (0)
		END

		IF @extLen = @lon
		BEGIN -- Setting 108 validar el tamaño longitud del telefono
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList

				RETURN (0)
			END

			SELECT 0 AS res, @tel AS tel -- Extension

			RETURN (0)
		END
	END

	DECLARE @telTemp AS VARCHAR(15)

	SELECT @telTemp = @tel

	IF @pais = 1
	BEGIN ---Mexico
		IF @lon = 3 AND @tel = ''911''
		BEGIN
			SELECT 4 AS res, @tel AS tel --Lista Negra

			RETURN (0)
		END

		IF (@lon < 10)
		BEGIN
			SELECT 1 AS res, @tel AS tel --Longitud invalida

			RETURN (0)
		END
			   IF EXISTS (
					SELECT 1
					FROM ccCampsExtend
					WHERE cam_id = @Camp
					  AND ZipCodeSchedule = 1
				)
				BEGIN
					IF (@dato1 = '''''''' OR NOT EXISTS (SELECT 1 FROM ccTimeZoneAreaCP WHERE ZipCode = LTRIM(RTRIM(@dato1))))
					BEGIN
						SELECT 6 AS res, @tel AS tel; -- No tiene codigo postal
						RETURN (0);
					END
				END

		IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
		BEGIN
			SELECT 2 AS res, @tel AS tel --Digitos incorrectos

			RETURN (0)
		END

		IF left(@tel, 3) = ''001''
		BEGIN
			SELECT 0 AS res, @tel AS tel

			RETURN (0)
		END

		SELECT @tel = right(@tel, 10)

		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList

			RETURN (0)
		END

		If (@Camp > 0 AND @checkLd_In_ANILst = 1)
		BEGIN
			If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.
			BEGIN
				SELECT 0 AS res, @tel AS tel
				RETURN (0)
			END

			IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
					  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
					  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
			BEGIN
				SELECT 0 AS res, @tel AS tel
				RETURN (0)
			END
			ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
					  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
					  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
			BEGIN
				SELECT 0 AS res, @tel AS tel
				RETURN (0)
			END
		END

		SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal, DEFAULT, DEFAULT)

		IF LEFT(@tel, 1) = ''E''
		BEGIN
			SELECT 3 AS res, @telTemp AS tel --No encontrado

			RETURN (0)
		END

		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END
	ELSE IF @pais = 2
	BEGIN --Argentina
		SET @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

			RETURN (0)
		END

		SELECT @tel = dbo.fnClearPhoneArg(@tel)

		IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
		BEGIN
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 3 AS res, @telTemp --Not existsFound
				END

				SELECT 0 AS res, @tel AS tel
			END
		END
		ELSE
		BEGIN
			SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
		END

		RETURN (0)
	END
	ELSE IF @pais = 3
	BEGIN --Colombia
		IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
		BEGIN
			SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

			RETURN (0)
		END

		SELECT @tel = dbo.Completa_ListaNegra(@tel)

		IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
		BEGIN
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 3 AS res, @telTemp --Not existsFound
				END

				SELECT 0 AS res, @tel AS tel
			END
		END
		ELSE
		BEGIN
			SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
		END

		RETURN (0)
	END
	ELSE IF @pais = 4
	BEGIN --USA
		EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

		RETURN (0)
	END
	ELSE IF @pais = 5
	BEGIN --Chile
		SELECT @tel = dbo.Completa_ListaNegra(@tel)

		IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
		BEGIN
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 3 AS res, @telTemp --Not existsFound
				END

				SELECT 0 AS res, @tel AS tel
			END
		END
		ELSE
		BEGIN
			SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
		END

		RETURN (0)
	END
	ELSE IF @pais = 6
	BEGIN --Venezuela
		SELECT @tel = dbo.Completa_ListaNegra(@tel)

		IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
		BEGIN
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 3 AS res, @telTemp --Not existsFound
				END

				SELECT 0 AS res, @tel AS tel
			END
		END
		ELSE
		BEGIN
			SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
		END

		RETURN (0)
	END
	ELSE IF @pais = 7
	BEGIN --Reino Unido
		SELECT @tel = dbo.Completa_ListaNegra(@tel)

		IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
		BEGIN
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 3 AS res, @telTemp --Not existsFound
				END

				SELECT 0 AS res, @tel AS tel
			END
		END
		ELSE
		BEGIN
			SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
		END

		RETURN (0)
	END
	ELSE IF @pais = 8
	BEGIN --Arabia saudita
		SELECT @tel = dbo.Completa_ListaNegra(@tel)

		IF (len(@tel) IN (9, 10, 11))
		BEGIN
			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 3 AS res, @telTemp --Not existsFound
				END

				SELECT 0 AS res, @tel AS tel
			END
		END
		ELSE
		BEGIN
			SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
		END

		RETURN (0)
	END
	ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
	BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama
		SELECT @tel = dbo.Completa_ListaNegra(@tel)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 1 AS res, @telTemp --Longitud Invalida
		END
		ELSE IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
			END

			SELECT 0 AS res, @tel AS tel
		END

		RETURN (0)
	END'
	exec (@sql);

    SET @process = 'Drop trigger trigZonaHoraria if exists'
    SET @sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE name = N''trigZonaHoraria'')
           BEGIN
               DROP TRIGGER trigZonaHoraria;
           END'
    EXEC(@sql);

    SET @process = 'CREATE TRIGGER [trigZonaHoraria]'
    SET  @sql = 'CREATE TRIGGER [dbo].[trigZonaHoraria]
    ON [dbo].[ccoCallsOutSource]
    FOR INSERT,UPDATE
    AS
    SET NOCOUNT ON
    begin
    declare @country as tinyint,@zipCodeSchedule bit
    declare @tableCpZoneSchedule table(callout_id int primary key,iZonaHoraria int,iZonaHoraria_verano int)

    select @country =convert(tinyint, valor) from ccSettings with(nolock) where setting_id = 104
    if @country =1 begin
        select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id in(select top 1 cam_id from inserted)
    end
    if @zipCodeSchedule is null begin
        set @zipCodeSchedule=0
    end

    if @zipCodeSchedule = 1 begin

        insert into @tableCpZoneSchedule
        select cs.callout_id, inv.tz_id,v.tz_id
        from ccTimeZoneAreaCP zoneCp with(nolock)
        inner join inserted cs on zoneCp.ZipCode=cs.Dato1
        inner join ccTimeZones V on V.tz_offset=zoneCp.SummerTimeDifference
        inner join ccTimeZones inv on inv.tz_offset=zoneCp.WinterTimeDifference


    end


    if update(cal_telefono) begin
        update ccoCallsOutSource
        set iZonaHoraria =case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria, 0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono,0), 0) end,
        iZonaHoraria_verano =case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria_verano, 0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono,1), 0) end
        from ccoCallsOutSource cs
        inner join inserted i
        left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
        on cs.callout_id = i.callout_id
    end

    if update(cal_telefono2) begin
        update ccoCallsOutSource
        set iZonaHoraria2 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono2,0),0) end,
        iZonaHoraria_verano2 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria_verano,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono2,1),0) end
        from ccoCallsOutSource cs
        inner join inserted i on cs.callout_id = i.callout_id
        left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id

    end

    if update(cal_telefono3) begin
        update ccoCallsOutSource
        set iZonaHoraria3 =  case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono3,0),0) end,
        iZonaHoraria_verano3 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria_verano,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono3,1),0)  end
        from ccoCallsOutSource cs
        inner join inserted i on cs.callout_id = i.callout_id
        left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
    end

    if update(cal_telefono4) begin
        update ccoCallsOutSource
        set iZonaHoraria4 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono4,0),0) end,
        iZonaHoraria_verano4 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria_verano,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono4,1),0) end
        from ccoCallsOutSource cs
        inner join inserted i on cs.callout_id = i.callout_id
        left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
    end

    if update(cal_telefono5) begin
        update ccoCallsOutSource
        set iZonaHoraria5 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono5,0),0) end,
        iZonaHoraria_verano5 = case when @zipCodeSchedule=1 then ISNULL(cp.iZonaHoraria_verano,0) else ISNULL(dbo.fnGetTimeZone(cs.cal_telefono5,1),0) end
        from ccoCallsOutSource cs
        inner join inserted i on cs.callout_id = i.callout_id
        left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
    end
    end'
	exec (@sql);

    --------------------- END DEGD ------------------------------
    --------------------- BEGIN UGMV ----------------------------
    SET @process = '#5690 Actualizacion ccStatusLLamada para traduccion en reportes de llamada'

    SET @sql = '
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE ccstatusllamada
        SET descTranslated = CASE statusCall_id
            WHEN 1  THEN ''systemTranslated_status_initial''
            WHEN 2  THEN ''systemTranslated_status_outOfSchedule''
            WHEN 3  THEN ''systemTranslated_status_outOfService''
            WHEN 4  THEN ''systemTranslated_status_noAgents''
            WHEN 5  THEN ''systemTranslated_status_waiting''
            WHEN 6  THEN ''systemTranslated_status_abandon''
            WHEN 7  THEN ''systemTranslated_status_overflowTime''
            WHEN 8  THEN ''systemTranslated_status_overflowQueue''
            WHEN 9  THEN ''systemTranslated_status_withMSSG''
            WHEN 10 THEN ''systemTranslated_status_assignedMessage''
            WHEN 11 THEN ''systemTranslated_status_assigned''
            WHEN 12 THEN ''systemTranslated_status_answeredMessage''
            WHEN 13 THEN ''systemTranslated_status_answered''
            WHEN 14 THEN ''systemTranslated_status_cancelledMessage''
            WHEN 15 THEN ''systemTranslated_status_missed''
            WHEN 16 THEN ''systemTranslated_status_dialTone''
            WHEN 18 THEN ''systemTranslated_status_abandonReminder''
            WHEN 19 THEN ''systemTranslated_status_voicemail''
        END
        WHERE descTranslated IS NULL
          AND statusCall_id IN (
                1,2,3,4,5,6,7,8,9,10,
                11,12,13,14,15,16,18,19
          );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    '
    EXEC(@sql);
--------------------- END UGMV ----------------------------------
--------------------- BEGIN RECG #3684 ----------------------------------
SET @process = '#3684 Drop procedure ccsp_WhatsAppInformationOut if exists'
     SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppInformationOut'')
            BEGIN
                DROP PROCEDURE ccsp_WhatsAppInformationOut;
            END'
     EXEC(@sql);

	 SET @process = '#3684 CREATE PROCEDURE [ccsp_WhatsAppInformationOut]'
	 SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
    @Option SMALLINT,
    @camId SMALLINT = 0,
    @ConversationId INT = 0,
    @AgentsAvailables INT = 0,
    @IncreaseDecreaseAgent BIT = NULL,
    @AdminId int = 0

    AS
    SET NOCOUNT ON
    IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
        print (''Camp Is Not WhatsApp'')
        return(-1);
    End



    DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
    --set @Today SMALLDATETIME = ''2022-03-24''
    IF @Option = 0 BEGIN-- Reset TABLES
        TRUNCATE TABLE ccWAConversationsResult
        TRUNCATE table ccWAOperatingSummaryOut;
        TRUNCATE TABLE ccWAAverageConversationsOut;
        TRUNCATE TABLE ccLastMessageAgentByConversationOut;
    END
    else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
    BEGIN
        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                    WHERE CamId = @camId
                    AND (LastUpdate IS NULL
                    OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                    OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
        BEGIN
            -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

            DECLARE @AverageConversationTime INT = 0;
            DECLARE @AverageDialogTime INT = 0;
            DECLARE @AverageWaitingTime INT = 0;
            DECLARE @MaximumWaitingTime INT = 0;
            DECLARE @DefaultValue INT = 2


            SET @DefaultValue = @DefaultValue * 60;
            DECLARE @LessThanDefault INT = 0;
            DECLARE @ReceivedConversations INT = 0;
            DECLARE @ServiceLevel SMALLINT = 0;

            --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

            SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                    @AverageDialogTime = ROUND(AVG(tChatting), 4),
                    @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                    @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                    @ReceivedConversations = COUNT(conversationDate),
                    @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
            FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
            AND requestDate >= @Today

            SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

            ----------------------------------------------------- Update table --------------------------------------------------------

            IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
            BEGIN
                UPDATE ccWAAverageConversationsOut
                SET AverageConversationTime = @AverageConversationTime,
                    AverageDialogTime = @AverageDialogTime,
                    AverageWaitingTime = @AverageWaitingTime,
                    MaximumWaitingTime = @MaximumWaitingTime,
                    ServiceLevel = @ServiceLevel,
                    StatusUpdate = 0,
                    LastUpdate = GETDATE()
                WHERE CamId = @camId
            END
            ELSE
            BEGIN
                INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                        AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                        @ServiceLevel, 0 , GETDATE())
            END
        END
        --------------------------------- Results -----------------------------------

        if exists (select * from ccWAOperatingSummaryOut WITH (NOLOCK) where CamId=@camId
        and (OnQueue<0 or Assigned<0)
        ) begin
            set @Today =convert(date,getdate(),121)

            ;WITH waOperationSummary AS (
            SELECT
                CamId,
                COUNT(CASE WHEN finishedBy = 1 THEN 1 END) AS Attended,
                COUNT(CASE WHEN conversationStatus = 1 THEN 1 END) AS OnQueue,
                COUNT(CASE WHEN finishedBy = 0 AND agentId > 0 THEN 1 END) AS Assigned,
                COUNT(*) AS Request,
                COUNT(CASE WHEN finishedBy = 2 THEN 1 END) AS EndedBySystem
            FROM ccWhatsAppConversationsOut WITH (NOLOCK)
            WHERE camId = @camId AND requestDate >= @Today
            GROUP BY CamId
        )
        UPDATE A
        SET
            A.Attended = B.Attended,
            A.Assigned = B.Assigned,
            A.OnQueue = B.OnQueue,
            A.Request = B.Request,
            A.EndedBySystem = B.EndedBySystem
        FROM ccWAOperatingSummaryOut A
        INNER JOIN waOperationSummary B ON A.CamId = B.CamId;
        END

        SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
            ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
            ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
            ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
            ISNULL(ServiceLevel, 0) AS ServiceLevel,
            ISNULL(summary.Attended, 0) AS Attended,
            ISNULL(summary.Assigned, 0) AS Assigned,
            ISNULL(summary.OnQueue, 0) AS OnQueue,
            ISNULL(summary.EndedBySystem, 0) AS EndedBySystem,
            ISNULL(summary.Available, 0) AS Available,
            ISNULL(summary.Request, 0) AS Request
        FROM ccWAAverageConversationsOut conv
        RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
        WHERE conv.CamId = @camId OR summary.camId = @camId
    END
    else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                    -- Average Queue/Waiting Time, and Service Level)
    BEGIN
        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
            BEGIN
                UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
                WHERE CamId = @camId
            END
            ELSE
            BEGIN
                INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
                VALUES(@camId, 1)
            END
    END
    else IF @Option = 3 -- Save time from accepted conversation by agent
    BEGIN
        IF @ConversationId IS NOT NULL
        BEGIN
            -- Se valida si el conversation date es null para poder actualizarlo
            DECLARE @IsTransfered BIT, @conversationDate DATETIME;
            SELECT @IsTransfered = IsTransfered, @conversationDate = conversationDate FROM ccWhatsAppConversationsOut with(nolock)  WHERE conversationId = @ConversationId;
            IF(@IsTransfered = 0 OR @conversationDate IS NULL)
            BEGIN
                UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
                --Save Conversation Assigned
                SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
                UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
            END

        END
    END
    else IF @Option = 4 -- Get Disposition Information
    BEGIN
    declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
    select @nIdioma = case valor
        when 0 then ''Sin calificación''
        when 2 then ''Sem classificação''
        else ''No disposition'' end
    from ccsettings where setting_id = 27 -- 0esp
    SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
            ISNULL(disposition.calif_id, 0) AS DispositionId,
            COUNT(whatsConv.disposition) AS Total,
            ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM ccWhatsAppConversationsOut whatsConv with(nolock)
    LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
    WHERE camId = @camId AND assignDate >= @Today
        and whatsConv.conversationStatus != 2
    GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
    END
    else IF @Option = 5 -- Get Subdisposition Information
    BEGIN
        SELECT relation.calif_id AS DispositionId,
                subDispositions.califSubDesc AS SubDispositionsName,
                COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM cctipoSubCalifRel relation
        INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
        INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
        WHERE whatsConv.camId = @camId AND
                whatsConv.assignDate >= @Today AND
                relation.tipoSubRel = 0
        GROUP BY subDispositions.califSubDesc, relation.calif_id
    END
    ELSE IF @Option = 6 -- Agents Availables
    BEGIN
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
            BEGIN
                INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
            END
        ELSE
            BEGIN
                UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
            END
    END

    ELSE IF @Option = 7 -- Whats Conversations Results
    BEGIN
        SELECT  ISNULL(SentMsg, 0)      AS SentMsg,
                ISNULL(Delivered, 0)    AS Delivered,
                ISNULL(NotDelivered, 0) AS NotDelivered,
                ISNULL(ReadMsg, 0)      AS ReadMsg,
                ISNULL(Received, 0)     AS Received,
                ISNULL(UnSent, 0)       AS UnSent,
                ISNULL(NotSupported, 0) AS NotSupported
        FROM ccWAConversationsResult
        WHERE camId = @camId;
    END

    ELSE IF @Option = 8 -- whats outbound conversations
    BEGIN
        DECLARE @ActualDay DATE = GETDATE()

        declare @conversationOut table (
        camId int not null,
        Active int not null,
        Queued int not null,
        FinishedAgent int not null,
        FinishedSystem int not null
        )
        insert into @conversationOut
        SELECT cco.camId ,
            COUNT(CASE WHEN cco.conversationStatus NOT IN (10,11,17,18) THEN 1 ELSE NULL END) Active
            ,COUNT(CASE WHEN conversationStatus = 1 THEN 1 ELSE null END) Queued
            ,count(case when finishedBy=1 then 1 end)  FinishedAgent
            ,count(case when finishedBy=2 then 1 end)  FinishedSystem
        FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
        WHERE cco.camId = @camId AND cco.conversationDate>= @ActualDay
        group by cco.camId

        --update B
        --set B.EndedBySystem=A.FinishedSystem,
        --B.OnQueue=A.Queued
        --from @conversationOut A
        --inner join ccWAOperatingSummaryOut B on A.camId=B.CamId

        select A.Active,B.OnQueue Queued,A.FinishedAgent,B.EndedBySystem as FinishedSystem
        from @conversationOut A
        inner join ccWAOperatingSummaryOut B on A.camId=B.CamId
    END
    IF @Option = 9
    BEGIN
        SET NOCOUNT ON;

        DECLARE @campsIds TABLE(camid SMALLINT);

        INSERT INTO @campsIds
        EXEC ccsp_GalateaAdminCampaigns
            @Option = 11,
            @CampType = 1,
            @AdminId = @AdminId,
            @IsWhatsAppCampaign = 1;

        SELECT
            waco.camid,

            SUM(CASE WHEN s.normStatus IN (''sent'',''submitted'') THEN 1 ELSE 0 END) AS SentMsg,
            SUM(CASE WHEN s.normStatus = ''delivered'' THEN 1 ELSE 0 END) AS Delivered,
            SUM(CASE WHEN s.normStatus = ''read'' THEN 1 ELSE 0 END) AS ReadMsg,
            SUM(CASE WHEN s.normStatus IN (''rejected'',''error'',''hostError'',''clientError'',''failed'') THEN 1 ELSE 0 END) AS NotDelivered,
            SUM(CASE WHEN s.normStatus = ''received'' THEN 1 ELSE 0 END) AS Received,
            SUM(CASE WHEN s.normStatus = ''UnSent'' THEN 1 ELSE 0 END) AS UnSent,
            SUM(CASE WHEN s.normStatus = ''N/A'' THEN 1 ELSE 0 END) AS NA

        FROM ccWhatsAppConversationsOut waco
        INNER JOIN @campsIds c
            ON c.camid = waco.camId
        INNER JOIN ccWAMessagesConversationsOut wamco
            ON waco.conversationId = wamco.conversationId

        CROSS APPLY (
            SELECT
                CASE
                    WHEN wamco.messageStatus = ''Failed''
                        AND EXISTS (
                            SELECT 1
                            FROM ccWhatsAppUnsetMessagesMCSbyWebApi wa WITH (NOLOCK)
                            WHERE wa.Id = wamco.messageId
                            AND wa.Content = ''Undeliverable''
                        )
                    THEN ''UnSent''

                    WHEN wamco.messageStatus = ''N/A'' AND wamco.originType = ''Client''
                    THEN ''received''

                    WHEN wamco.messageStatus = ''N/A'' AND wamco.originType = ''Admin''
                        AND NOT EXISTS (
                            SELECT 1
                            FROM ccWhatsAppUnsetMessagesMCSbyWebApi wa WITH (NOLOCK)
                            WHERE wa.Id = wamco.messageId
                            AND wa.Content = ''Internal''
                        )
                    THEN ''submitted''

                    WHEN wamco.messageStatus = ''N/A'' AND wamco.originType = ''Admin''
                        AND EXISTS (
                            SELECT 1
                            FROM ccWhatsAppUnsetMessagesMCSbyWebApi wa WITH (NOLOCK)
                            WHERE wa.Id = wamco.messageId
                            AND wa.Content = ''Internal''
                        )
                    THEN ''N/A''

                    ELSE wamco.messageStatus
                END AS normStatus
        ) s

        WHERE wamco.timeStampMessage > @Today
        GROUP BY waco.camid
        ORDER BY waco.camid;
    END

    SET NOCOUNT OFF'
	EXEC(@sql)


    SET @process = '#3684 Drop procedure ccsp_GalateaAdminCampaigns if exists'
     SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminCampaigns'')
            BEGIN
                DROP PROCEDURE ccsp_GalateaAdminCampaigns;
            END'
     EXEC(@sql);

	 SET @process = '#6302 CREATE PROCEDURE [ccsp_GalateaAdminCampaigns]'
	 SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
@Option AS      SMALLINT,
@CampType AS    SMALLINT = 0,
@WorkgroupId AS INT      = 0,
@Id AS          INT      = 0,
@AdminId AS     SMALLINT = 0,
@PinUpdate AS   SMALLINT = 0,
@LoadId AS      INT      = 0,
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null,
@IsWhatsAppCampaign  bit = 0,
@groupList as varchar (MAX) = NULL,
@CampId AS      SMALLINT = 0
AS
BEGIN
    SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF @WorkgroupId IS NOT NULL BEGIN
        SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
    END;
    RETURN 0;
END;
IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id
    IF @CampType = 1 BEGIN-- Campaigns Out
        IF @Id IS NOT NULL BEGIN
            DECLARE @HasWorkingRowsForCampaign BIT = 0, @HasTemplatePaused   bit = 0,
        @HasTemplateDisabled bit = 0;

            IF EXISTS (
                SELECT 1
                FROM dbo.ccoWAWorkingTable AS cwwt
                WHERE cwwt.camId = @Id
            )
            BEGIN
                SET @HasWorkingRowsForCampaign = 1;
            END

            IF EXISTS (
                SELECT 1
                FROM dbo.ccoWAWorkingTable cwwt
                JOIN dbo.ccWhatsAppOutSource cwaos  ON cwaos.WAOut_Id = cwwt.WAOut_id
                JOIN dbo.ccMetaWAOutboundTemplates cmwot ON cmwot.Id = cwaos.TemplateId
                WHERE cwaos.camId = @Id AND cmwot.Status = ''PAUSED''
            ) SET @HasTemplatePaused = 1;

            IF EXISTS(
            SELECT 1 FROM dbo.ccMetaWAOutboundTemplates AS cmwot
                INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan
                ON cmwan.MetaId = cmwot.MetaId
                WHERE cmwan.Cam_Id = @Id AND cmwot.Status = ''DISABLED''
                AND cmwot.StatusCW = 1
            )
            BEGIN
                SET @HasTemplateDisabled = 1;
            END

            SELECT DISTINCT
            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
            camps.cam_procesando IsStarted,
            ISNULL(a.AreaName, '''') AS Area,
            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
            a.ToolsTransfer,
            @HasTemplatePaused AS HasTemplatePaused,
            @HasTemplateDisabled AS HasTemplateDisabled,
            @HasWorkingRowsForCampaign AS HasWorkingRowsForCampaign
            FROM ccCamps camps
            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
            WHERE camps.cam_id = @Id
            ORDER BY camps.cam_descripcion ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
        END;
    END;
    ELSE IF @CampType = 0 -- Campaigns In (ACD)
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    SELECT DISTINCT
                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted,
                    ISNULL(a.AreaName, '''') AS Area,
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                            a.ToolsTransfer
                    FROM ccInbound inb
                            LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                            LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                    WHERE inb.Inbound_id = @Id
                            ORDER BY inb.descripcion ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
            END;
    END;
    RETURN 0;
END;
ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

    IF @Id IS NOT NULL BEGIN
        UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
BEGIN
    IF @Id IS NOT NULL
        AND @AdminId IS NOT NULL
    BEGIN
        IF @PinUpdate = 1
        BEGIN
            INSERT INTO PinedCampaigns (CampId, AdminId, Type)
            VALUES (@Id, @AdminId, @Type);
        END;

        IF @PinUpdate = 0
        BEGIN
            DELETE
            FROM PinedCampaigns
            WHERE CampId = @Id
                AND AdminId = @AdminId
                AND Type = @Type;
        END;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
                );
    END;

    RETURN 0;
END;

ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin
    IF @AdminId IS NOT NULL BEGIN
        SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
        ORDER BY Id ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
BEGIN
    IF @Id IS NOT NULL
    BEGIN
        DECLARE @BlackListIds VARCHAR(MAX);

        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
                    (MAX)), CAST(idtipolista AS VARCHAR(MAX)))
        FROM Camplistanegra
        WHERE cam_id = @Id
            AND STATUS = 1;

        SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
BEGIN
    IF (
            @Id IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
                )
            )
    BEGIN
        SELECT TOP 1 list_id
        FROM ccRIARegistryLists
        WHERE cam_id = @Id
            AND STATUS = 2
        ORDER BY list_id DESC;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
BEGIN
    IF (
            @LoadId IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                    AND STATUS <> 0
                )
            )
    BEGIN
        UPDATE ccoCallsOutSource
        SET cal_status = ''5''
        WHERE list_id = @loadID;

        DELETE
        FROM ccoWorkingTable
        WHERE list_id = @LoadId;

        EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
BEGIN
    DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
        );

    INSERT INTO @table
    SELECT DISTINCT IdCampEsp, Tipo
    FROM ccRIACampEspWG wg
    WHERE wg.IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE IDWG <> @WorkgroupId
                AND User_id = @AdminId
            );

    SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
    FROM @table A
    RIGHT JOIN (
        SELECT wg.IdCampEsp, wg.Tipo
        FROM ccRIACampEspWG wg
        WHERE wg.IDWG = @WorkgroupId
        ) B ON A.camId = B.IdCampEsp
        AND A.campType = B.Tipo
    WHERE A.camId IS NULL
    ORDER BY IdCampEsp;

    RETURN 0;
END;

ELSE IF @option = 10
BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
    DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
    DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
    DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
    DECLARE @tmpCamAgent TABLE (
        camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
            )
        );
    DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
        );
    DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
        );
    DECLARE @campDataTotal TABLE (
        camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId
            )
        );

    INSERT INTO @AdminWorkgroups
    SELECT DISTINCT IDWG
    FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
    WHERE WG.User_id = @AdminId
        OR (
            R.User_id = @AdminId
            AND R.Rol_id = 7
            );

    INSERT INTO @AgentsList
    SELECT DISTINCT A.User_id
    FROM ccRIAWorkGroupUsers A
    INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
    INNER JOIN ccUsers C ON A.User_id = C.User_id
        AND C.TipoUser_id = 1
    ORDER BY A.User_id;

    IF @IsWhatsAppCampaign  = 1
    BEGIN
        INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
        SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
                    AND @CampType = 0 THEN inbound.chat ELSE NULL END
        FROM ccRIACampEspWG campPerWg
        INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
        INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
        INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
        LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
            AND @CampType = 0
        LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
            AND @CampType = 1
        WHERE C.TipoUser_id = 1
            AND (camps.CampType = 5 or inbound.chat = 5)
            AND campPerWg.Tipo = @CampType
            AND (
                @Id = 0
                OR campPerWg.IdCampEsp = @Id
                );
    END
    ELSE
    BEGIN
        INSERT INTO @tmpCamAgent
        SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
                    AND @CampType = 0 THEN inbound.chat ELSE NULL END
        FROM ccRIACampEspWG campPerWg
        INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
        INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
        INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
        LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
            AND @CampType = 0
        LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
            AND @CampType = 1
        WHERE C.TipoUser_id = 1
            AND campPerWg.Tipo = @CampType
            AND (
                @Id = 0
                OR campPerWg.IdCampEsp = @Id
                );
    END;

        DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

    ;WITH lastState
    AS (
        SELECT A.user_id, A.fecha
        ,CASE WHEN A.currentStatus <= 0 THEN 0 ELSE A.currentStatus END AS currentStatus
        ,IdCampEsp,Tipo
        FROM ccLogAgentesDiaLast A with(nolock)
        INNER JOIN @AgentsList B ON A.User_id = B.id
        WHERE fecha >= @date
        )
    INSERT INTO @CurrentStatus
    SELECT A.User_id, currentStatus, IdCampEsp, Tipo
    FROM lastState A

                        IF @CampType = 1
                        BEGIN
                            SELECT @MultimediaType = meanContactTypeId
                            FROM contactMeanOut
                            WHERE camp_id = @Id
                        END
                        ELSE
                        BEGIN
                            SELECT @chatType = ci.chat
                            FROM dbo.ccInbound AS ci
                            WHERE ci.Inbound_id = @Id;

    IF @Id = 0
        AND @CampType = 0
    BEGIN
        DELETE
        FROM @tmpCamAgent
        WHERE multimediaType = 0
    END



    IF @CampType = 1
    BEGIN
        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanOut
        WHERE camp_id = @Id
    END
    ELSE
    BEGIN
        SELECT @chatType = ci.chat
        FROM dbo.ccInbound AS ci
        WHERE ci.Inbound_id = @Id;

        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanIn
        WHERE inboundId = @Id
    END

    IF (@chatType = 1)
    BEGIN
        SET @MultimediaType = 1
    END

    DECLARE @StateIds VARCHAR(100) = (
            SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN
                            ''23'' ELSE ''4,5,6,9'' END
            ) -- Add more for multimediaTypes

    ;with stateDialog as(
    SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
)
    INSERT INTO @AgentStatus
    SELECT A.camId, A.userId, B.CurrentState,
    (CASE
        WHEN @chatType = 1 THEN
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
        ELSE
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
        END
    END) AS isCampDialog, B.camType

    FROM @tmpCamAgent A
    INNER JOIN @CurrentStatus B ON A.userId = B.userId
    WHERE (
            @Id = 0
            OR A.camId = @Id
            )

    IF @CampType = 1
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area, ISNULL(va.concurrentSessionsLimit,0) as NumberOfVirtualAgents
        FROM campDataTotal A
        INNER JOIN ccCamps B ON A.camId = B.cam_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
        LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1
    END
    ELSE
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area, 0 as NumberOfVirtualAgents
        FROM campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END;

    WITH stateCamp
    AS (
        SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
            count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
                            ) THEN 1 WHEN A.CurrentState IN (6, 4
                            )
                        AND (
                            A.CampId != C.IdCampEsp
                            OR A.campType != @CampType
                            ) THEN 1 ELSE NULL END) AS notReady,
                            COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog,
                            COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
    COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
        FROM @AgentStatus A
        INNER JOIN @CurrentStatus C ON A.userId = C.userId
        GROUP BY A.CampId
        )
    SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady,
            0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL
                THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END
        Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, A.NumberOfVirtualAgents ,A.Area
    FROM @campDataTotal A
    LEFT JOIN stateCamp B ON A.camId = B.CampId
    ORDER BY A.campName

    RETURN 0;
END -- *****************************************************************************************
END
ELSE IF @Option = 11
BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles WITH (NOLOCK)
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        --print ''xxxx SIn Super''
            ;

        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId
            )
        SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
        INTO #tempIds
        FROM ccRIACampEspWG A WITH (NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = @CampType;

        IF(@CampType = 1)
        BEGIN
            SELECT Id FROM #tempIds ids
            INNER JOIN ccCamps c on c.cam_id = ids.Id
            WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1)
            OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
        END
        ELSE
        BEGIN
            SELECT Id FROM #tempIds ids
            INNER JOIN ccInbound c on c.Inbound_id = ids.Id
            WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1)
            OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
        END
        DROP TABLE #tempIds
    END;
    ELSE
    BEGIN
        --print ''xxxx Super''
        IF @CampType = 1
        BEGIN
            SELECT DISTINCT CAST(cam_id AS INT) AS Id
            FROM ccCamps WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
            AND(CampType = 5 AND @IsWhatsAppCampaign = 1)
            OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
            FROM ccInbound WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
            AND (chat = 5 AND @IsWhatsAppCampaign = 1)
            OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
        END
    END;

    RETURN 0;
END;

ELSE IF @Option = 12
BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
    IF @CampType = 1 -- Campaigns Out
    BEGIN
        ;WITH StopByCamp AS (
        SELECT
            cwaos.camId,
            IsStopDueTemplateStatusChange = CAST(
                CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS BIT
            )
        FROM dbo.ccoWAWorkingTable AS cwwt
        INNER JOIN dbo.ccWhatsAppOutSource AS cwaos
            ON cwaos.WAOut_Id = cwwt.WAOut_id
        INNER JOIN dbo.ccMetaWAOutboundTemplates AS cmwot
            ON cmwot.Id = cwaos.TemplateId
        WHERE cmwot.Status IN (''PAUSED'', ''DISABLED'')
        GROUP BY cwaos.camId
        )

        SELECT DISTINCT
        CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
        isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
        camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
        CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
        ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
        ISNULL(sbc.IsStopDueTemplateStatusChange, 0) AS IsStopDueTemplateStatusChange
        FROM ccCamps camps(NOLOCK)
        INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
        LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
        LEFT  JOIN StopByCamp       sbc                   ON sbc.camId = camps.cam_id
        ORDER BY camps.cam_descripcion ASC;
    END;
    ELSE
    BEGIN
        SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
            (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS
            AreaId, inb.chat AS InboundType, 0 AS OutboundType
        FROM ccInbound inb(NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
        ORDER BY inb.descripcion ASC;
    END;

    RETURN 0;
END;

ELSE IF @Option = 13
BEGIN
    BEGIN
        IF NOT EXISTS (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                    AND Rol_id = 7
                )
        BEGIN
            IF @CampType = 1
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    cam_descripcion AS Description,
                                    isnull(ccc.IDArea, -1) AS AreaID,
                                    CAST(-1 AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
                                    CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                    CAST(1 AS INT) As CampType
                FROM ccRIACampEspWG A
                INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
                INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
                LEFT JOIN ccInbound cci(NOLOCK) ON ccc.cam_id = cci.cam_id
                LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
            END
            ELSE
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(chat AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(chat AS INT) AS Channel,
                                    CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                    CAST(0 AS INT) As CampType
                FROM ccRIACampEspWG A(NOLOCK)
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 0
                INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                    LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
            END
        END;
        ELSE
        BEGIN
            IF @CampType = 1
            BEGIN
                        SELECT DISTINCT
                                CAST(ccc.cam_id AS INT) AS CampId,
                                cam_descripcion AS Description,
                                isnull(ccc.IDArea, -1) AS AreaID,
                                CAST(-1 AS SMALLINT) AS CampaignType,
                                CAST(ISNULL(i.Inbound_id,-1) AS INT) AS RelatedCampId,
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
                                CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                CAST(1 AS INT) As CampType
                        FROM ccCamps AS ccc (NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                            left join ccInbound i on i.cam_id = ccc.cam_id
                        where ccc.IDArea = @AreaId
            END
            ELSE
            BEGIN
                        SELECT DISTINCT
                                CAST(cci.Inbound_id AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(chat AS INT) AS Channel,
                                CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                CAST(0 AS INT) As CampType
                FROM ccInbound cci(NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                            LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                        where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

            END
        END;

        RETURN 0;
    END;
END;
ELSE IF @Option = 14
BEGIN
    IF NOT EXISTS (
            SELECT 1
            FROM ccUsers_Roles NOLOCK
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT
                                CAST(IdCampEsp AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
        FROM ccRIACampEspWG A(NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = 0
        INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id
            AND ((@multi_type is null AND cci.chat = @InboundType) OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
    ELSE
    BEGIN
                    SELECT DISTINCT
                    CAST(Inbound_id AS INT) AS CampId,
                    descripcion AS Description,
                    isnull(IDArea, -1) AS AreaID,
                    CAST(chat AS SMALLINT) AS CampaignType,
                    CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
END

ELSE IF @Option = 15
BEGIN
            --SELECT DISTINCT
            --CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            --FROM ccInbound NOLOCK where cam_id = @Id and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))

    select
        CAST(Inbound_id AS INT) AS CampId,
        cci.descripcion AS Description,
        isnull(cci.IDArea, -1) AS AreaID,
        CAST(chat AS SMALLINT) AS CampaignType,
        CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId
    from ccCamps ccc
    INNER JOIN ccInbound cci ON cci.IDArea = ccc.IDArea
    where ccc.cam_id = @Id
        and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
        and isnull(cci.cam_id,-1) > 0

END
ELSE IF  @Option=16
begin
    DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
    DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
    select @AreaId = IDArea from ccUsers where User_id = @Id
    declare @camps table (cam_id int)
    insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
    if((select SUM(cam_id) from @camps) IS NULL)
        begin
            select '''' as CampName
            ,0 as Conversations
            ,0 as Assign
            ,0 as OnQueu
            ,0 AS FinishedBySystem
            ,0 AS FinishedByAgent
            ,'''' as AreaName
            ,0 as IsAssignedCamps
        end
    else
        begin
            ;with camDesc as(
            select
            c.cam_id as cam_id
            ,cam_descripcion as cam_desc
            ,area.AreaName
            from ccCamps c with (nolock)
            inner join @camps id on c.cam_id = id.cam_id
            inner join ccRIACat_Areas area on area.IDArea = c.IDArea
            group by area.AreaName, c.cam_id, c.cam_descripcion
            )
            ,
            currentConversationWa as (
            select conversationId, camId, assignDate, onQueue,finishedBy
            ,case when conversationStatus = 2 then 1 else 0 end as assigned
            from ccWhatsAppConversationsOut with (nolock)
            where assignDate >= @from and assignDate <= @to
            )
            select
            b.cam_desc as CampName
            ,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
            ,COALESCE(SUM(ccw.assigned), 0) AS Assign
            ,COALESCE(count(ccw.onQueue),0) as OnQueu
            ,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
            ,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
            ,b.AreaName as AreaName
            ,1 as IsAssignedCamps
            from camDesc b
            left join currentConversationWa ccw on ccw.camId = b.cam_id
            group by b.cam_id, b.cam_desc, b.AreaName
        end
    end
ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
        IF @groupList IS NOT NULL BEGIN
            IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
            SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
            SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
            ORDER BY IdCampEsp ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
        END;
        RETURN 0;
    END;

ELSE IF @Option = 18 BEGIN -- Validar si la campaña fue eliminada del area
        DECLARE @activo INT;

        IF @CampType = 0 BEGIN
            SELECT @activo = ISNULL(IDArea, 0)
            FROM ccInbound
            WHERE Inbound_id = @Id;
        END;

        ELSE BEGIN
            SELECT @activo = ISNULL(IDArea, 0)
            FROM ccCamps
            WHERE cam_id = @Id;
        END;

        SELECT @activo;
    END;

ELSE IF @Option = 19
    BEGIN

        DECLARE @SuccessId INT, @NonComprehensionId INT;
        DECLARE @IsSuperUser BIT = 0;
        DECLARE @wgId TABLE (IDWG INT);

        IF EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7)
        BEGIN
            SET @IsSuperUser = 1;
        END
        ELSE
        BEGIN
            INSERT INTO @wgId (IDWG)
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId;
        END

        SELECT
            @SuccessId = ISNULL(idForSuccessfulTransaction, -1),
            @NonComprehensionId = ISNULL(idForNonComprehension, -1)
        FROM ccInbound WITH (NOLOCK)
        WHERE Inbound_id = @CampId;

        WITH MainCampaigns AS (
            SELECT
                CAST(cci.Inbound_id AS INT) AS CampId,
                cci.descripcion AS Description,
                ISNULL(cci.IDArea, -1) AS AreaID,
                CAST(cci.chat AS SMALLINT) AS CampaignType,
                CAST(0 AS BIT) AS IsSuccessTransfer,
                CAST(0 AS BIT) AS IsNonComprehensionTransfer
            FROM ccInbound cci WITH (NOLOCK)
            WHERE
            (
                -- Superusuario: por Área
                (@IsSuperUser = 1 AND cci.IDArea = @AreaId)
                OR
                -- Usuario normal: por Workgroup
                (@IsSuperUser = 0 AND EXISTS (
                    SELECT 1 FROM ccRIACampEspWG A WITH (NOLOCK)
                    INNER JOIN @wgId wg ON wg.IDWG = A.IDWG
                    WHERE A.Tipo = 0 AND A.IdCampEsp = cci.Inbound_id
                ))
            )
            AND cci.chat = 0
            AND cci.IDArea = @AreaId
        ),
        ReferencedCampaigns AS (
            SELECT
                CAST(cci.Inbound_id AS INT) AS CampId,
                cci.descripcion AS Description,
                ISNULL(cci.IDArea, -1) AS AreaID,
                CAST(cci.chat AS SMALLINT) AS CampaignType,
                CASE WHEN cci.Inbound_id = @SuccessId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSuccessTransfer,
                CASE WHEN cci.Inbound_id = @NonComprehensionId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNonComprehensionTransfer
            FROM ccInbound cci WITH (NOLOCK)
            WHERE cci.Inbound_id IN (@SuccessId, @NonComprehensionId)
        )

        SELECT * FROM ReferencedCampaigns
        UNION ALL
        SELECT m.*
        FROM MainCampaigns m
        LEFT JOIN ReferencedCampaigns r
        ON m.CampId = r.CampId
        WHERE r.CampId IS NULL;
    END;
END;'
	EXEC(@sql)

SET @process = '#3684 Drop procedure ccsp_WhatsAppInformationOut if exists'
    SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppInformationOut'')
            BEGIN
                DROP PROCEDURE ccsp_WhatsAppInformationOut;
            END'
     EXEC(@sql);

	 SET @process = '#3684 CREATE PROCEDURE [ccsp_WhatsAppInformationOut]'
	 SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
@Option SMALLINT,
@camId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL,
@AdminId int = 0

AS
SET NOCOUNT ON
IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
    print (''Camp Is Not WhatsApp'')
    return(-1);
End



DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
--set @Today SMALLDATETIME = ''2022-03-24''
IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAConversationsResult
    TRUNCATE table ccWAOperatingSummaryOut;
    TRUNCATE TABLE ccWAAverageConversationsOut;
    TRUNCATE TABLE ccLastMessageAgentByConversationOut;
END
else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                WHERE CamId = @camId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = 2


        SET @DefaultValue = @DefaultValue * 60;
        DECLARE @LessThanDefault INT = 0;
        DECLARE @ReceivedConversations INT = 0;
        DECLARE @ServiceLevel SMALLINT = 0;

        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                @AverageDialogTime = ROUND(AVG(tChatting), 4),
                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                @ReceivedConversations = COUNT(conversationDate),
                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
        FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    if exists (select * from ccWAOperatingSummaryOut WITH (NOLOCK) where CamId=@camId
    and (OnQueue<0 or Assigned<0)
    ) begin
        set @Today =convert(date,getdate(),121)

        ;WITH waOperationSummary AS (
        SELECT
            CamId,
            COUNT(CASE WHEN finishedBy = 1 THEN 1 END) AS Attended,
            COUNT(CASE WHEN conversationStatus = 1 THEN 1 END) AS OnQueue,
            COUNT(CASE WHEN finishedBy = 0 AND agentId > 0 THEN 1 END) AS Assigned,
            COUNT(*) AS Request,
            COUNT(CASE WHEN finishedBy = 2 THEN 1 END) AS EndedBySystem
        FROM ccWhatsAppConversationsOut WITH (NOLOCK)
        WHERE camId = @camId AND requestDate >= @Today
        GROUP BY CamId
    )
    UPDATE A
    SET
        A.Attended = B.Attended,
        A.Assigned = B.Assigned,
        A.OnQueue = B.OnQueue,
        A.Request = B.Request,
        A.EndedBySystem = B.EndedBySystem
    FROM ccWAOperatingSummaryOut A
    INNER JOIN waOperationSummary B ON A.CamId = B.CamId;
    END

    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
        ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
        ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
        ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
        ISNULL(ServiceLevel, 0) AS ServiceLevel,
        ISNULL(summary.Attended, 0) AS Attended,
        ISNULL(summary.Assigned, 0) AS Assigned,
        ISNULL(summary.OnQueue, 0) AS OnQueue,
        ISNULL(summary.EndedBySystem, 0) AS EndedBySystem,
        ISNULL(summary.Available, 0) AS Available,
        ISNULL(summary.Request, 0) AS Request
    FROM ccWAAverageConversationsOut conv
    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
    WHERE conv.CamId = @camId OR summary.camId = @camId
END
else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                -- Average Queue/Waiting Time, and Service Level)
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
            VALUES(@camId, 1)
        END
END
else IF @Option = 3 -- Save time from accepted conversation by agent
BEGIN
    IF @ConversationId IS NOT NULL
    BEGIN
        -- Se valida si el conversation date es null para poder actualizarlo
        DECLARE @IsTransfered BIT, @conversationDate DATETIME, @agentDisconnection BIT;
        SELECT @IsTransfered = IsTransfered, @agentDisconnection = IsAgentLoggingOut, @conversationDate = conversationDate FROM ccWhatsAppConversationsOut with(nolock)  WHERE conversationId = @ConversationId;
        IF(@IsTransfered = 0 OR @conversationDate IS NULL)
        BEGIN
            IF (ISNULL(@agentDisconnection, 0) = 0)
            BEGIN
                UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            END
            --Save Conversation Assigned
            SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
            UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
        END

    END
END
else IF @Option = 4 -- Get Disposition Information
BEGIN
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor
    when 0 then ''Sin calificación''
    when 2 then ''Sem classificação''
    else ''No disposition'' end
from ccsettings where setting_id = 27 -- 0esp
SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
        ISNULL(disposition.calif_id, 0) AS DispositionId,
        COUNT(whatsConv.disposition) AS Total,
        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
FROM ccWhatsAppConversationsOut whatsConv with(nolock)
LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
WHERE camId = @camId AND assignDate >= @Today
    and whatsConv.conversationStatus != 2
GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
END
else IF @Option = 5 -- Get Subdisposition Information
BEGIN
    SELECT relation.calif_id AS DispositionId,
            subDispositions.califSubDesc AS SubDispositionsName,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM cctipoSubCalifRel relation
    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
    INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
    WHERE whatsConv.camId = @camId AND
            whatsConv.assignDate >= @Today AND
            relation.tipoSubRel = 0
    GROUP BY subDispositions.califSubDesc, relation.calif_id
END
ELSE IF @Option = 6 -- Agents Availables
BEGIN
    IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
        BEGIN
            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
        END
    ELSE
        BEGIN
            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
        END
END

ELSE IF @Option = 7 -- Whats Conversations Results
BEGIN
    SELECT ISNULL(SentMsg, 0) AS SentMsg,
            ISNULL(Delivered, 0) AS Delivered,
            ISNULL(NotDelivered, 0) AS NotDelivered,
            ISNULL(ReadMsg, 0)      AS ReadMsg,
            ISNULL(Received, 0)     AS Received,
            ISNULL(UnSent, 0)       AS UnSent,
            ISNULL(NotSupported, 0) AS NotSupported
    FROM ccWAConversationsResult
    WHERE camId = @camId
END

ELSE IF @Option = 8 -- whats outbound conversations
BEGIN
    DECLARE @ActualDay DATE = GETDATE()

    declare @conversationOut table (
    camId int not null,
    Active int not null,
    Queued int not null,
    FinishedAgent int not null,
    FinishedSystem int not null
    )
    insert into @conversationOut
    SELECT cco.camId ,
        COUNT(CASE WHEN cco.conversationStatus NOT IN (10,11,17,18) THEN 1 ELSE NULL END) Active
        ,COUNT(CASE WHEN conversationStatus = 1 THEN 1 ELSE null END) Queued
        ,count(case when finishedBy=1 then 1 end)  FinishedAgent
        ,count(case when finishedBy=2 then 1 end)  FinishedSystem
    FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
    WHERE cco.camId = @camId AND cco.conversationDate>= @ActualDay
    group by cco.camId

    --update B
    --set B.EndedBySystem=A.FinishedSystem,
    --B.OnQueue=A.Queued
    --from @conversationOut A
    --inner join ccWAOperatingSummaryOut B on A.camId=B.CamId

    select A.Active,B.OnQueue Queued,A.FinishedAgent,B.EndedBySystem as FinishedSystem
    from @conversationOut A
    inner join ccWAOperatingSummaryOut B on A.camId=B.CamId
END
IF @Option = 9
BEGIN
    DECLARE @campsIds TABLE(camid smallint)
    INSERT INTO @campsIds
    exec ccsp_GalateaAdminCampaigns @Option = 11, @CampType = 1, @AdminId = @AdminId, @IsWhatsAppCampaign=1


    SELECT
        waco.camid,

        SUM(CASE WHEN s.normStatus IN (''sent'',''submitted'') THEN 1 ELSE 0 END) AS SentMsg,
        SUM(CASE WHEN s.normStatus = ''delivered'' THEN 1 ELSE 0 END) AS Delivered,
        SUM(CASE WHEN s.normStatus = ''read'' THEN 1 ELSE 0 END) AS ReadMsg,
        SUM(CASE WHEN s.normStatus IN (''rejected'',''error'',''hostError'',''clientError'',''failed'') THEN 1 ELSE 0 END) AS NotDelivered,
        SUM(CASE WHEN s.normStatus = ''received'' THEN 1 ELSE 0 END) AS Received,
        SUM(CASE WHEN s.normStatus = ''UnSent'' THEN 1 ELSE 0 END) AS UnSent,
        SUM(CASE WHEN s.normStatus = ''N/A'' THEN 1 ELSE 0 END) AS NA

    FROM ccWhatsAppConversationsOut waco
    INNER JOIN @campsIds c
        ON c.camid = waco.camId
    INNER JOIN ccWAMessagesConversationsOut wamco
        ON waco.conversationId = wamco.conversationId

    CROSS APPLY (
        SELECT
            CASE
                WHEN wamco.messageStatus = ''Failed''
                    AND EXISTS (
                        SELECT 1
                        FROM ccWhatsAppUnsetMessagesMCSbyWebApi wa WITH (NOLOCK)
                        WHERE wa.Id = wamco.messageId
                        AND wa.Content = ''Undeliverable''
                    )
                THEN ''UnSent''

                WHEN wamco.messageStatus = ''N/A'' AND wamco.originType = ''Client''
                THEN ''received''

                WHEN wamco.messageStatus = ''N/A'' AND wamco.originType = ''Admin''
                    AND NOT EXISTS (
                        SELECT 1
                        FROM ccWhatsAppUnsetMessagesMCSbyWebApi wa WITH (NOLOCK)
                        WHERE wa.Id = wamco.messageId
                        AND wa.Content = ''Internal''
                    )
                THEN ''submitted''

                WHEN wamco.messageStatus = ''N/A'' AND wamco.originType = ''Admin''
                    AND EXISTS (
                        SELECT 1
                        FROM ccWhatsAppUnsetMessagesMCSbyWebApi wa WITH (NOLOCK)
                        WHERE wa.Id = wamco.messageId
                        AND wa.Content = ''Internal''
                    )
                THEN ''N/A''

                ELSE wamco.messageStatus
            END AS normStatus
    ) s

    WHERE wamco.timeStampMessage > @Today
    GROUP BY waco.camid
    ORDER BY waco.camid;
END

SET NOCOUNT OFF'
	EXEC(@sql)
--------------------- END RECG #3684 ----------------------------------

----------------------------BEGIN MACL---------------------------------
	SET @process = 'Alter ccsp_AgentHistoricalChat'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
@option SMALLINT, 
@clientNum VARCHAR(15) = '''', 
@conversationId AS INT = 0, 
@inboundId AS SMALLINT = 0, 
@serviceType AS SMALLINT = 0,
@campType AS INT = 0
AS
BEGIN
    IF @option = 1 --whatsapp, get conversation ids
    BEGIN
        DECLARE @tempId INT = 0
        IF @campType = 0 -- INBOUND
        BEGIN
            SELECT conversationId AS ConversationId,
                @campType AS CampType,
                assignDate AS Date
            FROM ccWhatsAppConversations with(nolock)
            WHERE clientId = @clientNum AND assignDate IS NOT NULL
            GROUP BY conversationId, assignDate
        END
        ELSE
        BEGIN  -- OUTBOUND
            SELECT conversationId AS ConversationId,
                @campType AS CampType,
                assignDate AS Date
            FROM ccWhatsAppConversationsOut with(nolock)
            WHERE clientId = @clientNum AND assignDate IS NOT NULL
            GROUP BY conversationId, assignDate
        END
    END

    IF @option = 2 --whatsapp, get acdId by conversation id
    BEGIN
        IF @campType = 0
        BEGIN
            SELECT CAST(inboundId AS INT)
            FROM [ccWhatsAppConversations] with(nolock)
            WHERE conversationId = @conversationId
        END
        ELSE
        BEGIN
            SELECT CAST(camId AS INT)
            FROM [ccWhatsAppConversationsOut] with(nolock)
            WHERE conversationId = @conversationId
        END
    END

    IF @option = 3 --get data conversation
    BEGIN
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0

        SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
        FROM ccWhatsAppConversationsRelationship rel with(nolock)
        RIGHT JOIN ccWhatsAppConversations conv with(nolock) ON conv.conversationId = rel.conversationIdBefore
        WHERE rel.conversationIdAfter = @conversationId

        SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
                graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
            [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
            [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
            OldConversationId, c.agentId AS AgentId
        FROM ccInbound i
        INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
        INNER JOIN ccWhatsAppConversations c with(nolock) ON (
                c.inboundId = i.Inbound_id
                AND c.conversationId = @conversationId
                )
        INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
        WHERE i.chat = @serviceType
            AND i.Inbound_id = @inboundId

    END

    IF @option = 4 --get messages from conversation id
    BEGIN
        DECLARE @filetype AS VARCHAR(5)
        DECLARE @camp_acd_id INT = 0;

        IF @campType = 0
        BEGIN
            SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations with(nolock) WHERE conversationId = @conversationId)

			SELECT
				msg.*,
				ISNULL(graphics.graphic_id, 0) AS GraphicId
			FROM dbo.fn_GetMessagesByConversationOrMessageId(@campType, @conversationId, NULL) AS msg
            LEFT JOIN ccRIAInboundGraph graphics ON Inbound_id = @camp_acd_id
            ORDER BY msg.TIMESTAMP ASC
        END
        ELSE
        BEGIN
            SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) WHERE conversationId = @conversationId)

			SELECT
				msg.*,
				ISNULL(graphics.graphic_id, 0) AS GraphicId
			FROM dbo.fn_GetMessagesByConversationOrMessageId(@campType, @conversationId, NULL) AS msg
            LEFT JOIN ccRIACampsGraph graphics ON cam_id = @camp_acd_id
            ORDER BY msg.TIMESTAMP ASC
        END
                
    END

    IF @option = 5 --get if conversation is reassigned
    BEGIN
        IF @campType = 0
        BEGIN
            SELECT CASE 
                WHEN EXISTS (
                        SELECT *
                        FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship] with(nolock)
                        WHERE conversationIdAfter = @conversationId
                        )
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
                END
        END
        ELSE
        BEGIN
            SELECT CASE 
                WHEN EXISTS (
                        SELECT *
                        FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut] with(nolock)
                        WHERE conversationIdAfter = @conversationId
                        )
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
                END
        END
    END
END
        '
     EXEC(@sql);

	 SET @process = 'Refactor ccsp_createMessageAndGlobalId para evitar hacer consultas a las tablas por cada registro'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_createMessageAndGlobalId] 
@Type INT,
@Messages VARCHAR(MAX)
    
AS
BEGIN
    SET NOCOUNT ON;
    IF @Type = 1
    BEGIN
		DECLARE @ConvId INT;
		DECLARE @CamId VARCHAR(7)
		DECLARE @PhoneClient VARCHAR(15)
		DECLARE @PhoneWa VARCHAR(15)
		DECLARE @MetaId VARCHAR(150)
		DECLARE @TimeStamp DATETIME
		DECLARE @TimeStampUTC DATETIME
		DECLARE @TemplateCategory varchar(50);
		DECLARE @TemplateContent varchar(max);

		-- Se crean tablas temporales
		DECLARE @tmpData TABLE 
		(MetaId VARCHAR(150), TemplateCategory VARCHAR(50), TemplateContent VARCHAR(MAX),
		CamId VARCHAR(7),PhoneClient VARCHAR(15),PhoneWa VARCHAR(15),TimeStamp DATETIME,TimeStampUTC DATETIME);


		DECLARE @SplitResults TABLE
		(Id INT PRIMARY KEY,MetaId NVARCHAR(255));

		INSERT INTO @SplitResults
		SELECT Id, Value FROM dbo.fn_RIASplitDelimited(@Messages, '','')

		--Se inserta toda la info en la tabla para evitar hacer multiples selects
		INSERT INTO @tmpData
		SELECT  
			wld.MetaId,
			mwat.Category,
			waos.MessageContent,
			wld.CamId,
			wld.PhoneClient,
			wld.PhoneWa,
			wld.TimeSpam,
			DATEADD(HOUR, -tz.tz_offset, wld.TimeSpam)
		FROM @SplitResults s
		JOIN ccoWhatsLogDials wld ON wld.MetaId = s.MetaId
		JOIN ccWhatsAppOutSource waos ON wld.WaOutId = waos.WAOut_Id
		JOIN ccMetaWAOutboundTemplates mwat ON waos.TemplateId = mwat.Id
		JOIN ccTimeZones tz ON tz.tz_id = waos.TimeZone;

		select * from @tmpData

		--Se declara cursor para iterar sobre la tabla
		DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
		SELECT MetaId, TemplateCategory, TemplateContent,
			   CamId, PhoneClient, PhoneWa, TimeStamp, TimeStampUTC
		FROM @tmpData;

		OPEN cur;
		--obteniendo info de la tabla
		FETCH NEXT FROM cur INTO
			@MetaId, @TemplateCategory, @TemplateContent,
			@CamId, @PhoneClient, @PhoneWa, @TimeStamp, @TimeStampUTC;

		--Iteramos en la tabla
		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT(@metaid)
			EXEC ccsp_ConversationWASaveOut @action = 1, @camId = @CamId, @phoneCam = @PhoneWa,
				@clientId = @PhoneClient, @conversationStatus = 20, @ConvId = @ConvId OUTPUT;

			EXEC ccsp_ConversationWASaveOut @action = 4, @messageId = @MetaId, @clientNum = @PhoneClient,
				@vonageNum = @PhoneWa, @typeMessage = ''template'', @content = @TemplateContent,
				@conversationId = @ConvId, @timeStampMessage = @TimeStamp, @timeStampMessageUTC = @TimeStampUTC,
				@originType = ''Admin'', @AgentLogin = ''Admin'';

			UPDATE ccoWhatsLogDials SET conversationId = @ConvId WHERE MetaId = @MetaId;

			EXEC ccsp_WhatsAppGlobalIds @ConversationType = 1, @ConversationId = @ConvId, @MessageId = @MetaId,
				@AssociatedNumber = @PhoneWa, @ClientNumber = @PhoneClient, @TemplateCategory = @TemplateCategory;

			--Obtenemos los siguientes datos
			FETCH NEXT FROM cur INTO
				@MetaId, @TemplateCategory, @TemplateContent,
				@CamId, @PhoneClient, @PhoneWa, @TimeStamp, @TimeStampUTC;
		END

		CLOSE cur;
		DEALLOCATE cur;
    END
END'
     EXEC(@sql);

	 SET @process = 'ccsp_WhatsAppGlobalIds refactor para evitar multiples consultas a las mismas tablas'
    SET @sql = 'ALTER PROCEDURE dbo.ccsp_WhatsAppGlobalIds  
(
    @ConversationType TINYINT,
    @ConversationId INT,
    @MessageId VARCHAR(150),
    @AssociatedNumber VARCHAR(30), 
    @ClientNumber VARCHAR(30),
    @TemplateCategory VARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @originType VARCHAR(20),
        @firstMessageDateFromAgent DATETIME,
        @messageStatus VARCHAR(20),
        @globalId INT,
        @isBilled BIT = 0;

    -- Se valida si la conversación existe
    IF @ConversationType = 0 AND NOT EXISTS (SELECT 1 FROM ccWhatsAppConversations WHERE conversationId = @ConversationId)
        RETURN(1)

    IF @ConversationType = 1 AND NOT EXISTS (SELECT 1 FROM ccWhatsAppConversationsOut WHERE conversationId = @ConversationId)
        RETURN(1)

    -- Obtenemos los datos necesarios
    IF @ConversationType = 0
    BEGIN
        SELECT 
            @originType = originType,
            @firstMessageDateFromAgent = timeStampMessage,
            @messageStatus = messageStatus
        FROM ccWAMessagesConversations
        WHERE messageId = @MessageId;
    END
    ELSE
    BEGIN
        SELECT 
            @originType = originType,
            @firstMessageDateFromAgent = timeStampMessage,
            @messageStatus = messageStatus
        FROM ccWAMessagesConversationsOut
        WHERE messageId = @MessageId;
    END

    IF @originType IN (''Agent'',''Admin'')
       AND @messageStatus NOT IN (''rejected'',''undeliverable'',''submitted'')
    BEGIN
        SET @isBilled = 1;
    END
    ELSE
    BEGIN
        SET @firstMessageDateFromAgent = NULL;
    END

    -- Obtenemos el último GlobalId válido
    SELECT TOP (1) 
        @globalId = GlobalId
    FROM ccWhatsAppGlobalIds
    WHERE AssociatedNumber = @AssociatedNumber
      AND ClientNumber = @ClientNumber
      AND ((@TemplateCategory IS NULL AND Category IS NULL) OR Category = @TemplateCategory)
    ORDER BY GlobalId DESC;

    -- Crear nuevo GlobalId si no existe o expiró (>24h)
    IF @globalId IS NULL
       OR EXISTS (
            SELECT 1 
            FROM ccWhatsAppGlobalIds 
            WHERE GlobalId = @globalId 
              AND FirstMessageDateFromAgent IS NOT NULL
              AND FirstMessageDateFromAgent < DATEADD(HOUR, -24, GETDATE())
       )
    BEGIN
        INSERT INTO ccWhatsAppGlobalIds
        (
            AssociatedNumber,
            ClientNumber,
            FirstMessageDateFromAgent,
            FirstMessageConversationIdFromAgent,
            FirstMessageConversationTypeFromAgent,
            IsBilled,
            Category
        )
        VALUES
        (
            @AssociatedNumber,
            @ClientNumber,
            @firstMessageDateFromAgent,
            CASE WHEN @isBilled = 1 THEN @ConversationId END,
            CASE WHEN @isBilled = 1 THEN @ConversationType END,
            @isBilled,
            @TemplateCategory
        );

        SET @globalId = SCOPE_IDENTITY();
    END
    ELSE IF @isBilled = 1
    BEGIN
        UPDATE ccWhatsAppGlobalIds
        SET IsBilled = 1
        WHERE GlobalId = @globalId;
    END

    -- Se crea relación entre global id y conversación
    IF NOT EXISTS (
        SELECT 1 
        FROM ccWhatsAppGlobalIdsRelationship
        WHERE GlobalId = @globalId
          AND ConversationId = @ConversationId
          AND ConversationType = @ConversationType
    )
    BEGIN
        INSERT INTO ccWhatsAppGlobalIdsRelationship
        VALUES (@globalId, @ConversationId, @ConversationType);
    END

    SELECT @globalId AS GlobalId;
END'
     EXEC(@sql);

	 SET @process = 'create index IX_ccWhatsAppGlobalIds_Main'
	 SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_ccWhatsAppGlobalIds_Main''
      AND object_id = OBJECT_ID(''dbo.ccWhatsAppGlobalIds'')
)
BEGIN
    CREATE INDEX IX_ccWhatsAppGlobalIds_Main
    ON dbo.ccWhatsAppGlobalIds
    ( AssociatedNumber, ClientNumber,Category,GlobalId)
    INCLUDE (FirstMessageDateFromAgent, IsBilled);
END'
     EXEC(@sql);

	 SET @process = 'create index IX_GlobalIdsRelationship'
     SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_GlobalIdsRelationship''
      AND object_id = OBJECT_ID(''dbo.ccWhatsAppGlobalIdsRelationship'')
)
BEGIN
    CREATE INDEX IX_GlobalIdsRelationship
    ON dbo.ccWhatsAppGlobalIdsRelationship
    (GlobalId,ConversationId,ConversationType);
END'
     EXEC(@sql);

	 SET @process = 'create index IX_ccoWhatsLogDials_MetaId_WaOutId'
     SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_ccoWhatsLogDials_MetaId_WaOutId''
      AND object_id = OBJECT_ID(''dbo.ccoWhatsLogDials'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccoWhatsLogDials_MetaId_WaOutId
	ON ccoWhatsLogDials (MetaId, WaOutId)
	INCLUDE (CamId, PhoneClient, PhoneWa, TimeSpam);
END'
     EXEC(@sql);

	 SET @process = 'create index IX_ccWhatsAppOutSource_WAOut_Id_Cover'
     SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_ccWhatsAppOutSource_WAOut_Id_Cover''
      AND object_id = OBJECT_ID(''dbo.ccWhatsAppOutSource'')
)
BEGIN
	CREATE NONCLUSTERED INDEX IX_ccWhatsAppOutSource_WAOut_Id_Cover
	ON ccWhatsAppOutSource (WAOut_Id)
	INCLUDE (TemplateId, MessageContent, CamId, Status, TimeZone);
END'
     EXEC(@sql);

	 SET @process = 'create index IX_ccWhatsAppConversationsOut_conversationId'
     SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_ccWhatsAppConversationsOut_conversationId''
      AND object_id = OBJECT_ID(''dbo.ccWhatsAppConversationsOut'')
)
BEGIN
	CREATE NONCLUSTERED INDEX IX_ccWhatsAppConversationsOut_conversationId
	ON ccWhatsAppConversationsOut (conversationId)
	INCLUDE(camId)
END'
     EXEC(@sql);

	 SET @process = 'create index IX_ccWAMessagesConversationsOut_messageId'
     SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_ccWAMessagesConversationsOut_messageId''
      AND object_id = OBJECT_ID(''dbo.ccWAMessagesConversationsOut'')
)
BEGIN
	CREATE NONCLUSTERED INDEX IX_ccWAMessagesConversationsOut_messageId
	ON ccWAMessagesConversationsOut (messageId)
END'
     EXEC(@sql);

	 SET @process = 'create index IX_ccWAMessagesConversationsOut_conversationId'
     SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes 
    WHERE name = ''IX_ccWAMessagesConversationsOut_conversationId''
      AND object_id = OBJECT_ID(''dbo.ccWAMessagesConversationsOut'')
)
BEGIN
	CREATE NONCLUSTERED INDEX IX_ccWAMessagesConversationsOut_conversationId
	ON ccWAMessagesConversationsOut (conversationId)
	INCLUDE(originType, messageIdUi)
END'
     EXEC(@sql);
------------------------------END MACL---------------------------------

------------------------------BEGIN JUAN MEDINA---------------------------------
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

    SET @process = 'Sprint 4 - Actions are added for the creation, viewing, and editing flow of virtual agent models. / Sprint 5 - CREATE PROCEDURE ccsp_VirtualAgents'
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
        @originalAgentId INT = 0,

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
                    va.scriptAgent as ScriptAgent,
                    CAST(CASE
                        WHEN va.instructions IS NULL OR va.instructions = '''' THEN 0
                        ELSE 1
                        END AS bit) AS HasInstructions, 
                    ISNULL(va.ReplyGreeting, '''') AS ReplyGreeting,
                    ISNULL(va.ReplyFarewell, '''') AS ReplyFarewell,
                    ISNULL(va.ReplySystemFailure, '''') AS ReplySystemFailure,
                    ISNULL(va.ReplyNoUnderstanding, '''') AS ReplyNoUnderstanding,
                    ISNULL(va.quantumRoleId, 0) AS QuantumRolId,
                    ISNULL(va.responseLength, 0) AS ResponseLength,
                    ISNULL(va.responseTone, 0) AS ResponseTone,
                    ISNULL(va.roleName, '''') AS RolName,
                    ISNULL(va.Language, 0) as Language,
                    ISNULL(CopiesCount, 0) As CopiesCount,
                    ISNULL(OriginalAgentId, 0) As OriginalAgentId
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

                IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
                BEGIN
                    SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
                    RETURN
                END

                SELECT @TotalOfConcurrentAgents = CAST(valor AS int) FROM ccSettings2 WHERE setting_id = 281
                SELECT @UsedConcurrentAgents = ISNULL(SUM(concurrentSessionsLimit), 0) FROM ccVirtualAgent WHERE wasDeleted = 0

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
                    concurrentSessionsLimit = 0,
                    campType = 0,
                    wasDeleted = 1
                OUTPUT deleted.idAgent, deleted.nameAgent, deleted.quantumAgentId INTO #deletedVirtualAgents
                WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

                SELECT * FROM #deletedVirtualAgents
            END

            ELSE IF @action = 4 -- Change of associated campaign. Brings the info for Activity history
            BEGIN
				BEGIN TRY
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
						BEGIN
							SELECT @campaignArea =
								CASE
									WHEN EXISTS (SELECT 1 FROM ccInbound_Consulta WHERE Inbound_id = @campaignId)
										THEN 1
									ELSE 0
								END;
						END
						ELSE IF @campType = 1
						BEGIN
							SELECT @campaignArea =
								CASE
									WHEN EXISTS (SELECT 1 FROM ccCamps_Consulta WHERE cam_id = @campaignId)
										THEN 1
									ELSE 0
								END;
						END

						IF @campaignArea <> 0
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
				END TRY
				BEGIN CATCH
					SELECT ''Generic error to assign or unassign campaign to agent'' as Result, 7 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
					RETURN
				END CATCH
            END

            ELSE IF @action = 5 -- Status change
            BEGIN
                CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

                UPDATE ccVirtualAgent SET statusAgent = @statusAgent
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
                DECLARE @modifiedModelName VARCHAR(255), @objectiveModified TINYINT = 0, @rulesModified TINYINT = 0, @instructionsModified TINYINT = 0;

                IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
                BEGIN
                    SELECT 2 AS ErrorCode -- Agent deleted before saving changes
                    RETURN
                END

				SELECT 
				@objectiveModified = CASE WHEN ISNULL(cva.objective, '''') = @objective THEN 0 ELSE 1 END,
				@rulesModified = CASE WHEN ISNULL(cva.rules,'''') = @rules THEN 0 ELSE 1 END,
				@instructionsModified = CASE WHEN ISNULL(cva.instructions,'''') = @instructions THEN 0 ELSE 1 END,
				@modifiedModelName = nameAgent
				FROM dbo.ccVirtualAgent AS cva WHERE cva.idAgent = @idVirtualAgent

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
                    SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

                    -- ACTIVITY HISTORY REGISTER
                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT
                            (SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                            getDate(), 
                            @userName, 
                            170,
                            24,
                            CASE 
							WHEN @objectiveModified = 1 AND @rulesModified = 1 AND @instructionsModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION'' 
							WHEN @objectiveModified = 1 AND @rulesModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION_OBJECTIVE_RULE''
							WHEN @objectiveModified = 1 AND @instructionsModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION_OBJECTIVE_SCRIPT''
							WHEN @rulesModified = 1 AND @instructionsModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION_RULE_SCRIPT''
							WHEN @objectiveModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION_OBJECTIVE''
							WHEN @rulesModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION_RULE''
							WHEN @instructionsModified = 1 
								THEN ''VA_STRUCTURE_CONFIGURATION_SCRIPT''
							ELSE
							 ''''
							END,
                            '''',
                            @modifiedModelName;
                
                    SELECT 0 AS ErrorCode -- Success
                END
                ELSE
                BEGIN
                    SELECT 1 AS ErrorCode -- Agent with no changes or not found
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

                -- No deletion validation
                IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
                BEGIN
                    SELECT ''The agent was deleted before saving changes.'' AS Result, 7 AS ErrorCode
                    RETURN
                END
                -- 

                -- *** NUEVA LÓGICA: Manejo automático de voz al cambiar idioma ***
                DECLARE @currentVoice INT,
                        @currentLanguage INT,
                        @currentGender NVARCHAR(10),
                        @homonymousVoiceID INT = NULL;
        
                SELECT @currentVoice = ISNULL(voice, 0), 
                    @currentLanguage = ISNULL(language, 0)
                FROM ccVirtualAgent 
                WHERE idAgent = @idVirtualAgent;
        
                IF @languageAgent IS NOT NULL 
                AND @languageAgent <> @currentLanguage
                BEGIN
                    SELECT @currentGender = Gender 
                    FROM ccVirtualAgentVoices 
                    WHERE ID = @currentVoice;
            
                    IF @currentGender IS NOT NULL
                    BEGIN
                        SELECT TOP 1 @homonymousVoiceID = ID
                        FROM ccVirtualAgentVoices 
                        WHERE Language = @languageAgent 
                        AND Gender = @currentGender
                        ORDER BY IsDefault DESC, ID; -- Priorizar voz por defecto del idioma
                
                        IF @homonymousVoiceID IS NOT NULL AND (@voiceID IS NULL OR @voiceID = 0 OR @voiceID = @currentVoice)
                        BEGIN
                            SET @voiceID = @homonymousVoiceID; -- Actualizar a voz homónima
                        END
                    END
                END
        
                IF (@voiceID IS NULL OR @voiceID = 0) AND @homonymousVoiceID IS NULL
                BEGIN
                    SET @voiceID = @currentVoice;
                END

                DECLARE @AreaName  NVARCHAR(200),
                        @Login NVARCHAR(200),
                        @NameCampaing NVARCHAR(200), @nameAgentBeforeUpdate VARCHAR(255);

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

				SELECT @nameAgentBeforeUpdate = v.nameAgent
                FROM dbo.ccVirtualAgent AS v
                WHERE v.idAgent = @idVirtualAgent;

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
					CASE
					WHEN S.identifierInfo = ''VA_NAME'' THEN @nameAgentBeforeUpdate 
					ELSE 
					@NameAgent END
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

            ELSE IF (@action = 16) -- Duplicate virtual agent
            BEGIN
                SET NOCOUNT ON;

                DECLARE @newAgentId INT;

                IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
                BEGIN
                    SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
                    RETURN
                END
        
                -- Validación de capacidad (variables con nombres únicos)
                DECLARE @TotalOfConcurrentAgents_16 INT,
                        @UsedConcurrentAgents_16   INT;

                SELECT @TotalOfConcurrentAgents_16 = CAST(valor AS INT)
                FROM ccSettings2
                WHERE setting_id = 281;

                SELECT @UsedConcurrentAgents_16 = ISNULL(SUM(concurrentSessionsLimit), 0)
                FROM ccVirtualAgent
                WHERE wasDeleted = 0;

                IF ((@UsedConcurrentAgents_16 + ISNULL(@numberOfAgents,0)) > ISNULL(@TotalOfConcurrentAgents_16,0))
                BEGIN
                    SELECT ''There are not contracted agents available'' AS Result, 2 AS ErrorCode;
                    RETURN;
                END

                -- Crear el duplicado copiando del original y sobrescribiendo con valores del frontend
                INSERT INTO ccVirtualAgent (
                    nameAgent,
                    statusAgent,
                    createDateAgent,
                    latestUpdateDateAgent,
                    responseTone,
                    language,
                    quantumRoleId,
                    roleName,
                    responseLength,
                    quantumAgentId,
                    concurrentSessionsLimit,
                    voice,
                    ReplyGreeting,
                    ReplyFarewell,
                    ReplySystemFailure,
                    ReplyNoUnderstanding,
                    objective,
                    rules,
                    instructions,
                    scriptAgent,
                    OriginalAgentId,
                    CopiesCount,
                    wasDeleted,
                    idCampaign,
                    mediaType,
                    campType
                )
                SELECT
                    @nameAgent,                    
                    0,                             
                    GETDATE(),
                    GETDATE(),
                    @responseTone,                
                    @languageAgent,                
                    @quantumRoleId,                 
                    @roleDescription,                      
                    @responseLength,               
                    @quantumAgentId,               
                    @numberOfAgents,               
                    @voiceID,                         
                    @ReplyGreeting,                 
                    @ReplyFarewell,                
                    @ReplySystemFailure,            
                    @ReplyNoUnderstanding,         
                    objective,                     
                    rules,                         
                    instructions,                 
                    scriptAgent,                   
                    @originalAgentId,                       
                    0,                             -- Sin copias propias todavía
                    0,                             -- No eliminado
                    0,                             -- Sin campaña
                    0,                             -- Sin mediaType
                    0                              -- Sin campType
                FROM ccVirtualAgent
                WHERE idAgent = @originalAgentId;

                SET @newAgentId = SCOPE_IDENTITY();

                IF (@newAgentId IS NULL)
                BEGIN
                    SELECT ''Source agent not found'' AS Result, 2 AS ErrorCode, NULL AS IdAgent, @originalAgentId AS OriginalAgentId;
                    RETURN;
                END

                -- Actualizar contador del padre
                UPDATE ccVirtualAgent 
                SET CopiesCount = ISNULL(CopiesCount, 0) + 1,
                    latestUpdateDateAgent = GETDATE()
                WHERE idAgent = @originalAgentId;

                -- Registrar actividad
                SELECT @idArea = IDArea, @userName = Login 
                FROM ccUsers 
                WHERE User_id = @adminId;

                INSERT INTO ccGalateaActivityLog (
                    Area, 
                    ActivityDate, 
                    Login, 
                    OperationId, 
                    ModuleId, 
                    Identifier, 
                    Value, 
                    Target
                )
                SELECT
                    (SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                    GETDATE(), 
                    @userName, 
                    174,
                    24,
                    '''',
                    '''',
                    @nameAgent;

                -- Retornar resultado
                SELECT ''Agent duplicated successfully'' AS Result,
                        0 AS ErrorCode,
                        @newAgentId AS IdAgent,
                        @originalAgentId AS OriginalAgentId;
            END
        END	    
	'
    EXEC(@sql);

    SET @process = 'Drop procedure trsp_GetNetworkCredentialsGalatea'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''trsp_GetNetworkCredentialsGalatea'')
        BEGIN
            DROP PROCEDURE dbo.trsp_GetNetworkCredentialsGalatea
        END';
    EXEC(@sql);

    SET @process = 'Create procedure trsp_GetNetworkCredentialsGalatea'
    SET @sql = 'CREATE PROCEDURE trsp_GetNetworkCredentialsGalatea

                @pbxId Int= Null

                AS
                BEGIN
                    If @pbxId Is Null 
                        Set @pbxId =1

                    Declare @pathRepository Varchar(500),
                            @domain Varchar(100),
                            @user Varchar(100),
                            @password varchar(100)


                    Select @pathRepository=ruta_repositorio From TREC_REPOSITORIOS Where id_repositorio=@pbxId

                    If @pathRepository is null 
                        Select @pathRepository=par_valor From TREC_PARAMETROS Where par_id=1

                    Select @domain= N.domain,@user= N.[user],@password= N.[password] 
                        From RIA_NETWORKCREDENTIALS N
                        Inner Join TREC_REPO_NWCREDENTIALS R On R.id_nwCredential=N.Id
                        Where R.id_repository=@pbxId and N.status=1

                    If @domain Is Null 
                    Begin
                        Select Top 1 @domain= N.domain,@user= N.[user],@password= N.[password] 
                            From RIA_NETWORKCREDENTIALS N	
                    End

                    Select @pathRepository pathRepository,@domain domain,@user [user],@password [password] 
                END
            ';
    EXEC(@sql);


------------------------------END JUAN MEDINA---------------------------------

------------------------------BEGIN Jesus Gallardo---------------------------------

 SET @process = '#5877 ALTER procedure [dbo].[ccsp_OUTGetNewJobs]'
    SET @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = NULL,
@isDashboardApi BIT = 0
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey INT, @campType INT;
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)
declare @maxRecs varchar(3) = 0
select @maxRecs = valor from ccsettings (nolock) where setting_id = 251 and Status = 1      
select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
if @iZonas is null begin
exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0              
--Checamos si la campaña tiene horarios configurados
    if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
    begin
    if @iZonas = 0 begin
            SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
            return
    end
    end
    else begin
    if @camSurvey > 0
        begin
        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
        return
        end
    end
end
set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
    cam_id int,
    cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
    cal_status tinyint,
    cal_fechaDial datetime,
    user_id int,
    tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint,
calkey varchar(max),
nDescartes int,
name_agent varchar(max),
SimultaneousRecs int,
international int,
tz_tmp int,
tz2_tmp int,
tz3_tmp int,
tz4_tmp int,
tz5_tmp int,
cancelAttempts int
)''
-- 0=Ambas, 1=CallBacks, 2=Nuevas

DECLARE @maxCps INT = 30;
DECLARE @nSeconds INT = 25;

--select @topCount=valor from ccSettings where setting_id=94
select @maxCps=valor from ccSettings with(nolock) where setting_id=238

if @maxCps<=0 set @maxCps=30 --

SET @topCount = @maxCps*@nSeconds --se carga para tener registros suficiente por el tiempo que el outbound va buscar registros   

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID
declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END


if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount as varchar )
select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';
    
    select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
isnull(w.CancelAttempts, 0) as cancelAttempts
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status=1 -- CallBacks
and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
    ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
    ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
    ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
    ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
                                            
end -- TOMA EN CUENTA LOS CALLBACKS
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
    select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );
    select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';


select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
isnull(w.CancelAttempts, 0) as cancelAttempts
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status=0 -- Nuevas
and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
    begin
    select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
    WHERE callout_id in(select callout_id from #NEW_JOBS)''
end
if @Test = 2
begin
    select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
    declare @nSQL nvarchar(4000)
    set @nSQL=cast(@sql as nvarchar(4000))
    exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
    return(@total)
end
else
BEGIN
    IF(@isDashboardApi = 1)
    BEGIN
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
isnull(w.CancelAttempts, 0) as cancelAttempts
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status= 2 -- Procesando
and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
-- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
    END
    select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
    user_id,
case when tz>0  then tz  else tz_tmp end as tz,
case when tz2>0 then tz2 else tz2_tmp end as tz2,
case when tz3>0 then tz3 else tz3_tmp end as tz3,
case when tz4>0 then tz4 else tz4_tmp end as tz4,
case when tz5>0 then tz5 else tz5_tmp end as tz5,                           
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey,
0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs, international, cancelAttempts
FROM #NEW_JOBS where len(cal_telefono)>0
---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
''
end
set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print (@sql)
exec(@sql)
return(0)';
    EXEC(@sql);

SET @process = 'We reduced @RowsPerBlock from 250 to 60 to prevent buffer overflows and stabilise the socket connection into ccsp_ccActivityDataQuery]'
    SET @sql = 'ALTER PROCEDURE PROCEDURE ccsp_ccActivityDataQuery
@action int,@userId int=0,@camId int=0,@dnisId int=0,@WgId int=0,@tipo int =null
,@camIdOuts varchar(1000)='''',@camIdIns varchar(1000)='''',@userIds varchar(max)=''''
AS
set nocount on

declare @valdiate int
declare @packageData varchar(max)
DECLARE @blockSize INT = 8000; -- Tamaño del bloque.
declare @nTipoCallTotal int
set @packageData =''''
set @valdiate=0
set @nTipoCallTotal=0

if @action=1 begin      
if exists(select * from cccamps nolock where cam_bNew=1) begin
        set @valdiate=1
        Update ccCamps SET cam_bNew=0 Where cam_bNew=2
        Update ccCamps SET cam_bNew=2 Where cam_bNew=1
end     
select @valdiate as isUpdate
end
else if @action=2 begin         
if exists(select * from cccamps nolock where cam_bNew=3) begin
set @valdiate=1
        Update ccCamps SET cam_bNew=0 Where cam_bNew=4
        Update ccCamps SET cam_bNew=4 Where cam_bNew=3
end
select @valdiate as isUpdate
end
else if @action=3 begin         
SELECT User_id, TipoLlamadas FROM ccUsers WHERE User_ID = @userId
end
else if @action=4 begin 
SELECT A.Login, A.User_id, prioridad, skill, A.TipoLlamadas, C.cam_id, C.cam_descripcion, C.cli_id 
FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
JOIN ccUsers A  ON A.User_id = CA.User_id 
AND A.TipoUser_Id =1 AND C.cam_id =  @camId
order by A.Login, A.User_id, CA.prioridad, CA.skill, C.cam_id
end
else if @action=5 begin 
SELECT Login, TipoLlamadas, User_id, password, Nombres +'' ''+ ApellidoPaterno FROM ccUsers nolock WHERE User_id = @userId
end
else if @action=6 begin 
SELECT Inbound_id, descripcion, cli_id FROM ccInbound nolock WHERE Inbound_id =@camId
end
else if @action=7 begin 
SELECT Inbound_id, descripcion, cli_id, tnotas, nMaxQue FROM ccInbound WHERE Inbound_id = @camId
end
else if @action=8 begin 
SELECT dni_id, dni_numero, T.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id = T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=9 begin 
SELECT dni_id, dni_numero, dni_tipo, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id=T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=10 begin        
SELECT dni_id, dni_numero, D.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join cctipoDnis TD on D.tipodni_id = TD.tipodni_id
WHERE dni_tipo=2
end
else if @action=11 begin        
SELECT Inbound_id, descripcion, tNotas, nMaxQue FROM ccInbound
end
else if @action = 12 begin 
; with WgUser AS(
select 
WG.IDWG,A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.IDWG<>@WgId
)
, wGCamp AS(
select IDWG, IdCampEsp,Tipo from ccRIACampEspWG A
where A.IDWG in(select IDWG from WgUser) or A.IDWG=@WgId
), dataDiferent as
(
select distinct 
convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
as CampAndType
from wGCamp A
left join WgUser B on A.IdCampEsp=B.IdCampEsp and A.Tipo=B.Tipo 
left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1
left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0
where B.IdCampEsp is null
)
select @packageData=CampAndType+'',''+@packageData from dataDiferent    

select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.User_id=@userId
group by A.Tipo                 

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData, @nTipoCallTotal as nTipoCallTotal
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.


end

else if @action = 13 begin 
    if @tipo=2 set @tipo=1

    declare @WgUserCamp table (User_id int primary key)

    ; with WgCamp As(
    select IDWG from ccRIACampEspWG A WITH(NOLOCK)
    where tipo=@tipo and IdCampEsp=@camId and IDWG<>@WgId
    )

    insert into @WgUserCamp
    select WGUser.User_id
    from WgCamp
    inner join ccRIAWorkGroupUsers WGUser WITH(NOLOCK) on WGUser.IDWG=WgCamp.IDWG 
    inner join ccUsers C WITH(NOLOCK) on WGUser.User_id=C.User_id and C.TipoUser_id=1

    if @tipo=1 begin

        ;with dataPackage as(
            select distinct      
            convert(varchar, WG.User_id)
            +''-''+convert(varchar,isnull (campAgent.prioridad ,1))
            +''-''+convert(varchar,isnull (campAgent.skill ,1)) as package,
            (ROW_NUMBER() OVER (ORDER BY WG.User_id) - 1) / 80 AS GrupoID
            from ccRIAWorkGroupUsers WG WITH(NOLOCK)
            inner join ccCampsAgente campAgent WITH(NOLOCK) on campAgent.user_id=WG.User_id and WG.IDWG=campAgent.IDWG
            where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from @WgUserCamp)
        )
        SELECT CAST(STUFF((SELECT '','' + package FROM dataPackage d2 WHERE d2.GrupoID = d1.GrupoID FOR XML PATH('''')), 1, 1, '''') AS VARCHAR(8000)) AS packageData
        FROM dataPackage d1 GROUP BY GrupoID

    end
    else begin 

        ;with dataPackage as(
            select distinct 
            convert(varchar, WG.User_id)
            +''-''+convert(varchar,isnull (campAgent.prioridad ,1))
            +''-''+convert(varchar,isnull (campAgent.skill ,1)) as package,
            (ROW_NUMBER() OVER (ORDER BY WG.User_id) - 1) / 80 AS GrupoID
            from ccRIAWorkGroupUsers WG WITH(NOLOCK)
            inner join ccInboundAgentes campAgent WITH(NOLOCK) on campAgent.user_id=WG.User_id and WG.IDWG=campAgent.IDWG
            where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from @WgUserCamp)
        )
        SELECT CAST(STUFF((SELECT '','' + package FROM dataPackage d2 WHERE d2.GrupoID = d1.GrupoID FOR XML PATH('''')), 1, 1, '''') AS VARCHAR(8000)) AS packageData
        FROM dataPackage d1 GROUP BY GrupoID

    end
end
else if @action = 14 begin --Delete WG
; with wgCam as (
select Value as camId,1 calltype from dbo.fn_RIASplitDelimited(@camIdOuts,'','')
union
select Value as camId,0 calltype from dbo.fn_RIASplitDelimited(@camIdIns,'','')
)
, relationUser as(

select campWg.IdCampEsp as camId,campWg.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACampEspWG campWg on campWg.IDWG=Wg.IDWG         
where WG.User_id=@userId
)
, dataDiferent  as
(       
select distinct convert(varchar, wgCam.camId)+''-''+convert(varchar,wgCam.callType+1)   as CampAndType
from wgCam
left join relationUser A on wgCam.camId=A.camId and wgCam.calltype=A.Tipo
where A.camId is null
)

select @packageData=CampAndType+'',''+@packageData from dataDiferent

select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.User_id=@userId
group by A.Tipo 

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData, @nTipoCallTotal as nTipoCallTotal
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.

end
else if @action = 15 begin 

    -- 1. IMPORTANTE: Evita que el "X rows affected" confunda a la aplicación
    SET NOCOUNT ON;


    DECLARE @RowsPerBlock INT = 60; 

    -- 2. Tabla Temporal para cálculo masivo
    CREATE TABLE #TempRawData (
        RowID INT IDENTITY(1,1) PRIMARY KEY,
        User_id INT,
        IdCampEsp INT,
        Tipo INT,
        Prioridad INT,
        Skill INT,
        TotalTipo INT
    );

    -- 3. Lógica de Negocio (Set-Based / Sin Cursores)
    ;WITH TargetUsers AS (
        SELECT DISTINCT CAST(Value AS INT) as User_id
        FROM dbo.fn_RIASplitDelimited(@userIds, '','')
        WHERE Value IS NOT NULL AND Value <> ''''
    ),
    ExistingAccess AS (
        SELECT WG.User_id, CWG.IdCampEsp, CWG.Tipo
        FROM ccRIAWorkGroupUsers WG WITH(NOLOCK)
        INNER JOIN TargetUsers U ON WG.User_id = U.User_id
        INNER JOIN ccRIACampEspWG CWG WITH(NOLOCK) ON WG.IDWG = CWG.IDWG
        WHERE WG.IDWG <> @WgId
    ),
    TargetWGCampaigns AS (
        SELECT CWG.IdCampEsp, CWG.Tipo
        FROM ccRIACampEspWG CWG WITH(NOLOCK)
        WHERE CWG.IDWG = @WgId
    ),
    UserTotals AS (
        SELECT WG.User_id, SUM(CWG.Tipo + 1) as TotalTipo
        FROM ccRIAWorkGroupUsers WG WITH(NOLOCK)
        INNER JOIN TargetUsers U ON WG.User_id = U.User_id
        INNER JOIN ccRIACampEspWG CWG WITH(NOLOCK) ON WG.IDWG = CWG.IDWG
        GROUP BY WG.User_id
    )
    INSERT INTO #TempRawData (User_id, IdCampEsp, Tipo, Prioridad, Skill, TotalTipo)
    SELECT 
        U.User_id,
        T.IdCampEsp,
        T.Tipo,
        COALESCE(CA.prioridad, IA.prioridad, 1),
        COALESCE(CA.skill, IA.skill, 1),
        ISNULL(UT.TotalTipo, 0)
    FROM TargetUsers U
    CROSS JOIN TargetWGCampaigns T
    LEFT JOIN UserTotals UT ON U.User_id = UT.User_id
    LEFT JOIN ExistingAccess E 
        ON U.User_id = E.User_id AND T.IdCampEsp = E.IdCampEsp AND T.Tipo = E.Tipo
    LEFT JOIN ccCampsAgente CA WITH(NOLOCK) 
        ON T.IdCampEsp = CA.cam_id AND T.Tipo = 1 AND U.User_id = CA.User_id
    LEFT JOIN ccInboundAgentes IA WITH(NOLOCK) 
        ON T.IdCampEsp = IA.inbound_id AND T.Tipo = 0 AND U.User_id = IA.User_id
    WHERE E.IdCampEsp IS NULL;

    SELECT 
        Groups.BlockID + 1 AS segmentId, 
        
        CAST(STUFF((
            SELECT '','' + 
                CAST(T2.User_id AS VARCHAR(20)) + ''-'' +
                CAST(T2.IdCampEsp AS VARCHAR(20)) + ''-'' +
                CAST(T2.Tipo + 1 AS VARCHAR(5)) + ''-'' +
                CAST(T2.Prioridad AS VARCHAR(5)) + ''-'' +
                CAST(T2.Skill AS VARCHAR(5)) + ''-'' +
                CAST(T2.TotalTipo AS VARCHAR(10))
            FROM #TempRawData T2
            WHERE (T2.RowID - 1) / @RowsPerBlock = Groups.BlockID 
            ORDER BY T2.RowID
            FOR XML PATH(''''), TYPE
        ).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''') AS VARCHAR(8000)) AS segment

    FROM (
        SELECT DISTINCT (RowID - 1) / @RowsPerBlock AS BlockID
        FROM #TempRawData
    ) Groups
    ORDER BY Groups.BlockID;

    DROP TABLE #TempRawData;

END';
    EXEC(@sql);


SET @process = '#6640 ALTER PROCEDURE [dbo].[ccspLoadCampsOutbound]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspLoadCampsOutbound]
    @action int,  
    @nType INT=0,
    @agentId int=0,
    @campId int=0
AS
declare @sql nvarchar(max)

if @action= 0 begin
    set @sql=''SELECT cc.cam_id
                ,cam_descripcion
                ,cam_activo
                ,cam_ModoManual
                ,cam_modpredictivo
                ,cam_callratio
                ,cam_procesando
                ,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT)) cam_maxdlrxage
                ,cam_fDialOnWU
                ,cam_fDialOnDLG
                ,cam_tDialAfterWU
                ,cam_tDialBeforeReady
                ,cam_tDialAfterDLG
                ,compliance
                ,progDial
                ,excCallBack
                ,aggressionFactor
                ,listenManualCall
                ,tDialOnWrapUp
                ,callsbySurvey
                ,ivrscript
                ,cam_tNoContesta
                ,cam_inter_cancelled
                ,ISNULL(cc.CampType, 0) AS CampType
                ,ISNULL(cc.CamCanceled, 4) AS CamCanceled
                ,ISNULL(ex.SimultaneousRecs, 0) AS SimultaneousRecs
                ,ISNULL(cva.idAgent, 0) AS IdAgentVirtual
                                ,ISNULL(cva.nameAgent, '''''''') AS NameAgentVirtual
                ,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
                FROM ccCamps cc (NOLOCK) 
                LEFT JOIN ccCampsExtend ex (NOLOCK) ON ex.cam_id = cc.cam_id
                LEFT JOIN ccVirtualAgent cva ON cva.idCampaign = cc.cam_id AND cva.campType = 1
                WHERE cc.CampType not in (5,7)''
    if @nType=2 
        set @sql=@sql+'' AND cc.cam_bNew = 2 ''
    else if @nType=3
        set @sql=@sql+'' AND cc.cam_bNew in (1,2) ''
    set @sql=@sql+'' ORDER BY cc.cam_descripcion''
    --print(@sql)
    exec (@sql)
end
else if @action= 1 begin
    set @sql=''SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
        from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
        join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1 ''
    if @nType=2 
        set @sql=@sql+'' and C.cam_bNew=2''
    else if @nType=3
        set @sql=@sql+'' and C.cam_bNew in (1,2)''
    if @campId > 0
        set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
    set @sql=@sql+'' order by C.cam_id, CA.Prioridad''
    --print(@sql)
    exec (@sql)
end
else if @action= 2 begin
    set @sql=''select distinct A.Login, Prioridad, C.cam_id, Skill
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
            join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
            Where A.User_id = @agentId
            order by C.cam_id, CA.Prioridad''
    --print(@sql)
    exec sp_executesql @sql, N''@agentId int'', @agentId
end
else if @action= 3 begin
    set @sql=''SELECT dialer_id, C.cam_id FROM ccoDialerCamp R (nolock) join ccCamps C (nolock) on R.cam_id=C.cam_id AND CampType not in (5,7) ''
    if @nType=2 
        set @sql=@sql+'' and C.cam_bNew = 2 ''
    else if @nType=3
        set @sql=@sql+'' and C.cam_bNew in (1,2) ''
    if @campId > 0
        set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
    set @sql=@sql+'' ORDER BY cam_descripcion''
    --print(@sql)
    exec (@sql)
end
else if @action= 4 begin
    set @sql=''SELECT A.Login, A.TipoLLamadas, A.user_id 
    ,case when L.currentStatus <0 or L.currentStatus is null  then 0 else L.currentStatus end currentStatus
    ,case when L.TipoStatusAge_id <0 or L.TipoStatusAge_id is null  then 0 else L.TipoStatusAge_id end LastState
    FROM ccUsers A 
    INNER JOIN ccTipoUsers T on A.TipoUser_id=T.TipoUser_id
    LEFT JOIN ccLogAgentesDiaLast L on A.User_id=L.User_id
    WHERE A.TipoUser_id =1 AND A.Status=1 AND A.User_id = CASE WHEN @agentId = 0 THEN A.User_id ELSE @agentId END
    ORDER BY Login''
    exec sp_executesql @sql, N''@agentId int'', @agentId
end';
    EXEC(@sql);

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents] se cambia  @multipleUsers de 1000 a 8000'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(40)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(8000)=null
as
set nocount on

if @option=0--All Users
    begin
    select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

from ccusers as users with(nolock)
    left join ccRIACat_Areas as areas with(nolock)
    on users.IDArea=areas.IDArea
    return(0)
    end

if @option=1--selected User
    begin
    select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
    isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
    from ccusers where User_id=@UserId
    order by IDArea,Nombres,ApellidoPaterno,User_id
    return(0)
    end

if @option=2--insert
    begin
    if exists(select Login from ccUsers where Login=@Login)
    begin
    select -1--,''Login en Uso''
    return(0)
    end

    if exists(select Login from ccUsers_Consulta where Login = @Login)
    begin
    select -4 -- ''Login habia estado en Uso''
    return(0)
    end

    if exists(select Nombres from ccUsers where Nombres=@Nombres
    and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
    select -2--,''Nombre en Uso''
    return(0)
    end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
    set @UserId = null
    SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
    LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
    INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
    FROM ccusers) AS w ON w.recID = d.recID

    if @UserId is null
    begin
    select -2--insert Error
    return(0)
    end

    set identity_insert ccusers on
    insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
    select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
    set identity_insert ccusers off

    delete ccMenuUser where id_User = @UserId
    delete ccRIAUserRole where user_id = @UserId

    exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

END
ELSE
BEGIN
    insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
    select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

    if @@rowcount=1
    select @UserId=scope_identity()
    else
    begin
    select -2--insert Error
    return(0)
    end
END
    insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
    insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
    insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
    --Menu para roles RepotsRia
    exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
    return(0)
    end

if @option=3--Update
    begin
    if @Login='''' and @Password <> ''''
    begin
    Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
    return(0)
    end

    Update ccUsers
    set Login= case when @Login <> '''' then @Login else Login end,
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
    Password=case when @Password <> '''' then @Password else Password end,
    Sexo=@Sexo,canChangeStatus=@canChangeStatus
    where User_id=@UserId
    return(0)
    end

if @option=4--Delete
    begin
    delete from ccSkills where user_id =@UserId
    delete from ccMenu_ViewsUser where user_id =@UserId
    delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
delete from ccRIAAgentsPermissions where AgentId=@UserId
delete from ccUsers_Roles where User_id=@UserId
    delete from ccUsers where user_id=@UserId
    return(0)
    end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
    begin
    select @Type=TipoUser_id from ccUsers where User_id=@UserId

    if @Type not in(1,2,6)
    return(0)

    if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
    begin
    select 3
    return(0)
    end

    if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
    begin
    select 1
    return(0)
    end

    insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

    if @Type=1
    begin

    if @IDWG is null or @IDWG = 0
        begin
        select 28
        return(0)
        end
    insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

    select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

    insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
    select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
        and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

    return(0)
    end

--else @Type=2 or @Type=6--Supervisor
    insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
    select @UserId,idCampEsp,0,@IDWG
    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
    and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

    insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
    select @UserId,idCampEsp,1,@IDWG
    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
    and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
    return(0)
    end

if @option=6--Delete Agent-Supervisor from WorkGroup
    begin
    if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
    select @UserId = @multipleUsers

        else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
            select @UserId = cast(substring(@multipleUsers, 1,
            CHARINDEX('','', @multipleUsers)-1) as int)

    select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
    @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
    from ccUsers where User_id=@UserId

    Declare @sqlDelete nvarchar(4000)
    if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
    begin
    set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
    + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
    + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
    + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
    exec(@sqlDelete)
    end

    if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
    begin
    select -9 -- Se ingreso mal el id del usuario
    --delete ccinboundagentes where idwg=@IDWG
    --delete cccampsagente where idwg=@IDWG
    --delete ccSupervisorCam where idwg=@IDWG
    end

    if @DeleteUsers=1
    Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

    return(0)
    end

if @option=7--Delete Agent from WorkGroup
    begin
    select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
    set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
    '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
    ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
    '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
    exec(@sql)
    --update preview permission
    set @sql = ''update ccusers set 
        AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
        DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
        select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
        where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
        where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
    exec(@sql)
return(0)
    end

if @option=8--Delete Supervisor from WorkGroup
    begin
    select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

        set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
            + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
            delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))

              
        exec(@sql)

    set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
    ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
        
    exec(@sql)
    return(0)
    end

if @option=9
    begin
    update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
    SELECT Login from ccUsers where [User_id]=@UserId
    RETURN(0)
END
IF @option = 10
BEGIN   
    UPDATE dbo.ccUsers SET AuxiliaryRestricted=@canChangeStatus WHERE [User_id] = @UserId
    SELECT Login from ccUsers where [User_id]=@UserId
        RETURN(0)
END
set nocount off';
    EXEC(@sql);

------------------------------END Jesus Gallardo---------------------------------
------------------------------BEGIN Giovanni Vivaldo-----------------------------
SET @process = 'Delete from ccRIACATLogPhones tipoMov 6'
SET @sql = 'IF EXISTS (SELECT * FROM ccRIACATLogPhones WHERE tipoMov = 6)
    BEGIN
        DELETE FROM ccRIACATLogPhones WHERE tipoMov = 6
    END';
EXEC(@sql);

SET @process = 'Insert into ccRIACATLogPhones tipoMov 6'
SET @sql = 'INSERT INTO dbo.ccRIACATLogPhones (tipoMov, descTipoMov)
            VALUES (6, ''No cargados en proceso'')';
EXEC(@sql);

SET @process = 'Delete from ccRIACATLogPhones tipoMov 7'
SET @sql = 'IF EXISTS (SELECT * FROM ccRIACATLogPhones WHERE tipoMov = 7)
    BEGIN
        DELETE FROM ccRIACATLogPhones WHERE tipoMov = 7
    END';
EXEC(@sql);

SET @process = 'Insert into ccRIACATLogPhones tipoMov 7'
SET @sql = 'INSERT INTO dbo.ccRIACATLogPhones (tipoMov, descTipoMov)
            VALUES (7, ''Teléfono vacío o incompleto'')';
EXEC(@sql);

SET @process = 'Delete from tableLangueDbLoader tag record-not-loaded-processing'
SET @sql = 'IF EXISTS (SELECT * FROM tableLangueDbLoader WHERE tag = ''record-not-loaded-processing'')
    BEGIN
        DELETE FROM tableLangueDbLoader WHERE tag = ''record-not-loaded-processing''
    END';
EXEC(@sql);

SET @process = 'Insert into tableLangueDbLoader record-not-loaded-processing'
SET @sql = 'INSERT INTO tableLangueDbLoader (languageId, tag, translate)
            VALUES
                (0, ''record-not-loaded-processing'', ''No cargado, procesando''),
                (1, ''record-not-loaded-processing'', ''Not loaded, processing''),
                (2, ''record-not-loaded-processing'', ''N�o carregado, processando'')';
EXEC(@sql);


SET @process = 'Drop procedure ccsp_UpdateSmsOutFromTempAction'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_UpdateSmsOutFromTempAction'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_UpdateSmsOutFromTempAction
    END';
EXEC(@sql);

SET @process = 'Create procedure ccsp_UpdateSmsOutFromTempAction'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateSmsOutFromTempAction]
    @action INT,
    @tableName NVARCHAR(255),
    @sms_status int = 0,
    @idLoad int=0,
    @motivo varchar(50)=null,
    @DateStart varchar(50) = null,
    @DateEnd varchar(50) = null,
    @internationalRecords int=0

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @paramDef NVARCHAR(300);
    DECLARE @date datetime = getdate()
    declare @emtpy varchar(1)=''''

    IF @action = 1
    BEGIN
        SET @sql = ''INSERT INTO dbo.smsOutSource(callkey,sms_phoneNumber,sms_phoneNumber2,sms_phoneNumber3,sms_phoneNumber4,sms_phoneNumber5,
        data1,data2,data3,data4,data5,list_id,cam_id,Region,Localidad,sms_status,sms_dateDial,
        iTimeZone,iTimeZone_summer,iTimeZone2,iTimeZone_summer2,iTimeZone3,iTimeZone_summer3,iTimeZone4,iTimeZone_summer4,iTimeZone5,iTimeZone_summer5)
        select cal_Key,cal_telefono,cal_telefono2,cal_telefono3,cal_telefono4,cal_telefono5
        ,Dato1,Dato2,Dato3,Dato4,Dato5,list_id,cam_id,Region,Localidad,cal_status,cal_fechaDial
        ,iZonaHoraria,iZonaHoraria_verano
        ,iZonaHoraria2,iZonaHoraria_verano2
        ,iZonaHoraria3,iZonaHoraria_verano3
        ,iZonaHoraria4,iZonaHoraria_verano4
        ,iZonaHoraria5,iZonaHoraria_verano5
        from '' + QUOTENAME(@tableName) + '' where callout_id=0;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action = 2
    BEGIN
        SET @sql = N''
UPDATE A
SET A.cal_fechaDial = CASE
                         WHEN A.callout_id > 0 THEN B.sms_dateDial
                         ELSE @date
                      END
FROM '' + QUOTENAME(@tableName) + '' AS A
INNER JOIN smsOutSource AS B WITH (NOLOCK)
    ON A.callout_id = B.smsout_id;
'';
        SET @paramDef =  N''@date DATETIME'';
        EXEC sp_executesql @sql,@paramDef , @date = @date;
    END

    ELSE IF @action = 3
    BEGIN
        SET @sql = ''update C set C.sms_status = @sms_status,
C.sms_phoneNumber = A.cal_telefono,C.sms_phoneNumber2 = A.cal_telefono2,C.sms_phoneNumber3 = A.cal_telefono3,C.sms_phoneNumber4 = A.cal_telefono4,
C.sms_phoneNumber5 = A.cal_telefono5,
C.data1 = A.Dato1,C.data2 = A.Dato2,C.data3 = A.Dato3,C.data4 = A.Dato4,C.data5 = A.Dato5,
C.list_id = A.list_id,
C.sms_dateDial =  ''''''+@DateStart+'''''', C.sms_dateDialEnd =  ''''''+@DateEnd+'''''',
C.Region = A.Region,
C.Localidad = A.Localidad,
C.isSegmentLoad = 1
,C.iTimeZone=A.iZonaHoraria,C.iTimeZone_summer=A.iZonaHoraria_verano
,C.iTimeZone2=A.iZonaHoraria2,C.iTimeZone_summer2=A.iZonaHoraria_verano2
,C.iTimeZone3=A.iZonaHoraria3,C.iTimeZone_summer3=A.iZonaHoraria_verano3
,C.iTimeZone4=A.iZonaHoraria4,C.iTimeZone_summer4=A.iZonaHoraria_verano4
,C.iTimeZone5=A.iZonaHoraria5,C.iTimeZone_summer5=A.iZonaHoraria_verano5
from '' + QUOTENAME(@tableName) + '' A
left join dbo.smsWorkingTable  B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
inner join dbo.smsOutSource  C with(nolock) on A.callout_id=C.smsout_id
where B.smsout_id is null;'';

        SET @paramDef =   N''@sms_status int'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status;
    END
    ELSE IF @action = 4
    BEGIN
        SET @sql = ''update C set C.sms_status = @sms_status,
C.sms_phoneNumber = A.cal_telefono,C.sms_phoneNumber2 = A.cal_telefono2,C.sms_phoneNumber3 = A.cal_telefono3,C.sms_phoneNumber4 = A.cal_telefono4,
C.sms_phoneNumber5 = A.cal_telefono5,
C.data1 = A.Dato1,C.data2 = A.Dato2,C.data3 = A.Dato3,C.data4 = A.Dato4,C.data5 = A.Dato5,
C.list_id = A.list_id,
C.sms_dateDial =  A.cal_fechaDial,
C.Region = A.Region,
C.Localidad = A.Localidad
,C.isSegmentLoad = 0
from  '' + QUOTENAME(@tableName) + '' A
left join dbo.smsWorkingTable  B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
inner join dbo.smsOutSource  C with(nolock) on A.callout_id=C.smsout_id
where B.smsout_id is null;'';

        SET @paramDef =   N''@sms_status int'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status;
    END
    ELSE IF @action =5
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action =6
    BEGIN
        SET @sql = ''Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo,internationalRecords)
select @idLoad, A.cal_Key,@emtpy, 2, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;

delete A from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';

        SET @paramDef = N''@emtpy varchar(1),@idLoad int,@motivo varchar(50),@internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef,
        @emtpy=@emtpy,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;
    END

    ELSE IF @action =7
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';
Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo)
select @idLoad, A.cal_Key,@emtpy, 2, @motivo from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@emtpy varchar(1),@idLoad int,@motivo varchar(50)'';
        EXEC sp_executesql @sql, @paramDef, @emtpy = @emtpy,@idLoad=@idLoad,@motivo=@motivo;
    END
    ELSE IF @action = 8
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '' where callout_id=0;
delete from '' + QUOTENAME(@tableName) + '' where callout_id=0;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action =9
    BEGIN
        SET @sql = ''Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo,internationalRecords)
select @idLoad, A.cal_Key,@emtpy, 6, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@emtpy varchar(1),@idLoad int,@motivo varchar(50), @internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef,
        @emtpy=@emtpy,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;
    END
    ELSE IF @action = 10
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';'';
        EXEC sp_executesql @sql
    END
    ELSE IF @action = 11 BEGIN

        SET @sql = ''
    UPDATE T SET
        iZonaHoraria = CASE
            WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

        iZonaHoraria_verano = CASE
          WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

        iZonaHoraria2 = CASE
            WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

        iZonaHoraria_verano2 = CASE
          WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

        iZonaHoraria3 = CASE
            WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

        iZonaHoraria_verano3 = CASE
          WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

        iZonaHoraria4 = CASE
            WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

        iZonaHoraria_verano4 = CASE
          WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

        iZonaHoraria5 = CASE
            WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

        iZonaHoraria_verano5 = CASE
          WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
            ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

    FROM '' + QUOTENAME(@tableName) + '' T
    ''
    EXEC sp_executesql @sql,
            N''@emtpy varchar(1)'',
            @emtpy = @emtpy

    END


    ELSE
    BEGIN
        RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
        RETURN;
    END
END
';
EXEC(@sql);

SET @process = 'Drop procedure ccsp_RIALogPhones'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIALogPhones'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_RIALogPhones
    END';
EXEC(@sql);

SET @process = 'Create procedure ccsp_RIALogPhones'
SET @sql = 'CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON


		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int, @LoadBySegment varchar(1)
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int
		SELECT @LoadBySegment = CAST(ISNULL(LoadBySegment,''0'') as varchar) from ccRIALoading where load_id = @load_id
		IF(@option = 0)
		BEGIN
			select CAST(@LoadBySegment as bit) as LoadBySegment
			return 0;
		END

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)
		if @nType like ''%____1%'' --Record Not Loaded
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,6,7,8)
			''

		if @nType like ''%___1_%''--Number Not Loaded
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,6,7,8)
			''

		if @nType like ''%__1__%''--Record Blocked
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov IN (1)
			''

		if @nType like ''%_1___%''--Number blocked
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov IN (1,4)
			''

		if @nType like ''%1____%''--Record Updated
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp
		where crlp.load_id = @load_id and (''
		+ ISNULL(STUFF(@CaseType,CHARINDEX(''or'',@CaseType),LEN(''or''),''''),'''') +'')) tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);

				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE
				BEGIN
						IF(@isKolob = 1)
						BEGIN

						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @descriptionProcessingRecords VARCHAR(200),@descriptionEmpty VARCHAR(200);


						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''
						select @descriptionProcessingRecords = translate from tableLangueDbLoader where languageId = @language and tag = ''record-not-loaded-processing'';
                        select @descriptionEmpty = translate from tableLangueDbLoader where languageId = @language and tag = ''description-empty'';
 
						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key,
							CASE
								WHEN ISNULL(crlp.telefono, '''''''') = '''''''' THEN ''''''''
								WHEN crlp.internationalRecords = 0 THEN ''''N-'''' + REPLACE(crlp.telefono, ''''E_'''', '''''''')
								ELSE ''''I-'''' + REPLACE(crlp.telefono, ''''E_'''', '''''''')
							END AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
								WHEN crlp.tipoMov = 6 THEN @descriptionProcessingRecords
								WHEN crlp.tipoMov = 7 THEN @descriptionEmpty
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE
								crlp2.descTipoMov
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile,
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A''''
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
									WHEN crlp.tipoMov = 6 THEN @descriptionProcessingRecords
									WHEN crlp.tipoMov = 7 THEN @descriptionEmpty
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.keyTranslate is not null THEN tlan.translate
							ELSE crlp.motivo END AS motivo,
							CAST('' + @LoadBySegment + '' as BIT) AS LoadBySegment
							from ccRIALogPhones AS crlp
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id ''
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +''
							)
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key,
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id ''
				+ @CaseType
			END
			--PRINT(@sql);


			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200),@descriptionProcessingRecords VARCHAR(200),@descriptionEmpty VARCHAR(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords,@descriptionProcessingRecords=@descriptionProcessingRecords,@descriptionEmpty=@descriptionEmpty
		return(0)
		END
		set nocount OFF'
	EXEC(@sql)

    SET @process = 'cambiar tipomov en action 8 para hacer un correcto conteo de totales'
    
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
		@action INT,
		@tableName NVARCHAR(255),
		@cal_status int = 0,
		@idLoad int=0,
		@motivo varchar(50)=null,
		@cam_id int=null,
		@isIAQuantumCamp bit =0,
		@internationalRecords int=0

	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @sql NVARCHAR(MAX);
		DECLARE @paramDef NVARCHAR(300);
		DECLARE @count INT;
		declare @emtpy varchar(1)='''',@zipCodeSchedule bit
		declare @columnsIAQuntum varchar(max)=''''

		IF @action = 1
		BEGIN
			SET @sql = ''
			UPDATE '' + QUOTENAME(@tableName) + ''
			SET international = 1'';

			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 2
		BEGIN

			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum='', data_api_quantum, data_overflow_variables_quantum''
			end

			SET @sql = ''
			INSERT INTO dbo.ccoCallsOutSource (
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			)
			SELECT
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			FROM '' + QUOTENAME(@tableName) + ''
			WHERE callout_id = 0'';

			EXEC sp_executesql @sql;
		END

		ELSE IF @action = 3
		BEGIN
			SET @sql = ''
			INSERT INTO dbo.ccoCallsPreviewData (
				cal_Key, cam_id, TotalData, Headers,
				Dato6, Dato7, Dato8, Dato9, Dato10,
				Dato11, Dato12, Dato13, Dato14, Dato15
			)
			SELECT
				A.cal_Key, A.cam_id, A.TotalData, A.Headers,
				A.Dato6, A.Dato7, A.Dato8, A.Dato9, A.Dato10,
				A.Dato11, A.Dato12, A.Dato13, A.Dato14, A.Dato15
			FROM '' + QUOTENAME(@tableName) + '' A
			left join ccoCallsPreviewData B on A.cal_Key=B.cal_Key and A.cam_id=B.cam_id
			WHERE B.cam_id is null;
			'';

			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 4
		BEGIN
			SET @sql = ''
			UPDATE C SET
				C.Headers = A.Headers,
				C.TotalData = A.TotalData,
				C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
				C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
			FROM '' + QUOTENAME(@tableName) + '' A
			INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
				ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
			'';

			EXEC sp_executesql @sql;
		END
		ELSE IF @action =5
		BEGIN
			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum='', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum''
			end

			SET @sql = ''
			UPDATE C SET
				C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
				C.cal_telefono = A.cal_telefono,
				C.cal_telefono2 = A.cal_telefono2,
				C.cal_telefono3 = A.cal_telefono3,
				C.cal_telefono4 = A.cal_telefono4,
				C.cal_telefono5 = A.cal_telefono5,
				C.Dato1 = A.Dato1,
				C.Dato2 = A.Dato2,
				C.Dato3 = A.Dato3,
				C.Dato4 = A.Dato4,
				C.Dato5 = A.Dato5,
				C.dialPrefix = A.dialPrefix,
				C.list_id = A.list_id,
				C.cal_fechaDial = case when ISNULL(B.cal_status, 0) = 1 then C.cal_fechaDial else A.cal_fechaDial end,
				C.Region = A.Region,
				C.Localidad = A.Localidad,
				C.international = A.international,
				C.recycledByResult = @emtpy,
				C.recycledByDisposition = 0,
				C.recyclePhone = 0,
				C.recycleType = 1
				,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
				,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
				,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
				,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
				,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
			INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id'';

			SET @paramDef = N''@cal_status_param TINYINT, @emtpy varchar(1)'';
			EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @emtpy= @emtpy;
		END
		ELSE IF @action = 6
		BEGIN
			DECLARE @today DATE = CONVERT(DATE, GETDATE());

			SET @sql = ''
		UPDATE B
		SET B.list_id = A.list_id
		FROM '' + QUOTENAME(@tableName) + '' A
		INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
		INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
		WHERE B.list_id <> A.list_id;


		  UPDATE ld WITH (ROWLOCK) SET ld.canBeRecycled = 0
		  FROM '' + QUOTENAME(@tableName) + '' t
		  LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		  INNER JOIN ccoLogDials ld WITH (ROWLOCK, UPDLOCK, INDEX(IX_LogDials_cam_tipo_fecha_callout)) ON ld.cam_id = t.cam_id and ld.callout_id = t.callout_id
		  WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled=1 or ld.canBeRecycled is null);

		  UPDATE co WITH (ROWLOCK) SET co.canBeRecycled = 0
		  FROM '' + QUOTENAME(@tableName) + '' t
		  LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		  INNER JOIN ccoCallsOut co WITH (ROWLOCK, UPDLOCK) ON co.callout_id = t.callout_id
		  WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled=1 or co.canBeRecycled is null);
		  '';
			--print(@sql)
			EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
		END
		ELSE IF @action = 7
		BEGIN

			-- Contar registros inválidos
			SET @sql = ''
			SELECT @cnt = COUNT(*)
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL and A.callout_id > 0;'';

			EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

			-- Insertar en ccRIALogPhones los registros sin match
			SET @sql = ''
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, A.cal_Key, @emtpy, 2, @motivo,@internationalRecords
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC sp_executesql @sql,
				N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@emtpy=@emtpy;

			-- Eliminar los registros sin match
			SET @sql = ''
			DELETE A
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC(@sql);

			-- Retornar el count como resultado
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 8
		BEGIN


			-- Contar total de registros antes del borrado
			SET @sql = ''
			SELECT @cnt = COUNT(*) FROM '' + QUOTENAME(@tableName) + '';'';

			EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

			-- Log en ccRIALogPhones todos los registros de la tabla temporal
			SET @sql = ''
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, cal_Key, @emtpy, 6, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

			EXEC sp_executesql @sql,
					N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@emtpy=@emtpy;

			-- Eliminar todos los registros de la tabla temporal
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
			EXEC(@sql);

			-- Retornar el número de registros eliminados
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 9 BEGIN

			DECLARE @country TINYINT;
			SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
			if @country =1 begin
				select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id =@cam_id
			end
			if @zipCodeSchedule is null begin
				set @zipCodeSchedule=0
			end

			SET @sql = ''
		UPDATE T SET
			iZonaHoraria = CASE
				WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

			iZonaHoraria_verano = CASE
			  WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

			iZonaHoraria2 = CASE
				WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

			iZonaHoraria_verano2 = CASE
			  WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

			iZonaHoraria3 = CASE
				WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

			iZonaHoraria_verano3 = CASE
			  WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

			iZonaHoraria4 = CASE
				WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

			iZonaHoraria_verano4 = CASE
			  WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

			iZonaHoraria5 = CASE
				WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

			iZonaHoraria_verano5 = CASE
			  WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
				ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

		FROM '' + QUOTENAME(@tableName) + '' T
		OUTER APPLY dbo.fnGetTimeZoneByZip(T.Dato1) AS Z
		''
		EXEC sp_executesql @sql,
				N''@zipCodeSchedule bit,@country TINYINT,@emtpy varchar(1)'',
				@zipCodeSchedule = @zipCodeSchedule,
				@country = @country,
				@emtpy = @emtpy

		--print(@sql)
		END
		ELSE IF @action = 10
		BEGIN
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE callout_id = 0;'';
			EXEC sp_executesql @sql;
		END
		 ELSE IF @action = 11 BEGIN

			SET @sql = ''
		UPDATE T SET
			international=@internationalRecords
		FROM '' + QUOTENAME(@tableName) + '' T
		''
		EXEC sp_executesql @sql,
				N''@internationalRecords int'',
				@emtpy = @emtpy

		END


		ELSE
		BEGIN
			RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
			RETURN;
		END
	END'
    EXEC(@sql)

    SET @process = 'Modificacion para guardado de grabaciones'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_EngineLogTransfers]
		@action as tinyint,
		@cal_id as integer,
		@tipo as tinyint,
		@modo as tinyint,
		@destino as varchar(50),
		@tantes integer = 0,
		@tdespues integer = 0,
		@pbxId tinyint =0,
		@channel int =0,
		@callerAni as varchar(50) = null,
		@destination varchar(50)='''',
		@destination_name varchar(50)=''''
		as
		-- tipo: 1 inbound, 2 outbound
		-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde, 6 supervisada acd, 7 in callback

		declare @totalCall_Time integer
		declare @callout_id int
		declare @xferDate datetime = getdate()

		declare @calloutId int

		if @action = 1 begin
			if @modo = 4 begin
				insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id, callerAni, destination, destination_name)
				values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino), @callerAni, @destination, @destination_name)
				if @tdespues > 0 begin
						select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
						update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
				end
			end
			else begin
				if @modo = 5 and @tipo = 1 and @cal_id = 0
				begin
					insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id, callerAni, destination, destination_name)
					values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino), @callerAni, @destination, @destination_name)
					return;
				end

				if not exists (select 1 from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
				begin
					insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id, callerAni, destination, destination_name)
					values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino), @callerAni, @destination, @destination_name)
				end

				if @tipo = 2 begin
					if @modo = 5 begin
						select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
						update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
					end

					if @modo in (0,1,2) begin
						select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
						update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
					end
				end
				else begin
					if @modo = 7 begin
					select @xferDate XferDate
					return(0)
					end
					select @calloutId = callout_id from ccCallsIn where cal_id = @cal_id
					if @calloutId <> 0
					begin
						select @cal_id = @calloutId
						select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
						update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
					end
				end
			end
			--Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
			declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
			set @tMinAVRS=5
			set @cal_manual=0
			select @tMinAVRS=valor from ccSettings where setting_id=65
			if @tipo=2 begin
				select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
			end
			else begin
				select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
			end

			if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
				insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
			end
		end

		else if @action = 2
		begin
			select @calloutId = callout_id from ccCallsIn where cal_id = @cal_id
			if @calloutId <> 0
			begin
				select @cal_id = @calloutId
				update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
				select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
				update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
			end
		end

		else if @action = 4 begin
			select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
			update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		end'
	EXEC(@sql)

    SET @process = 'Se elimina sp ccsp_AgentUpdateCallTimes en caso de existir'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AgentUpdateCallTimes'')
			begin
				DROP PROCEDURE ccsp_AgentUpdateCallTimes;
			end'
    EXEC(@sql)
	SET @process = 'elimina validacion de no grabaciones en avrsTransfer'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]
	@IDCall int,
	@cal_tXfer float,
	@cal_tDialog float,
	@cal_tNotas float,
	@TipoCall tinyint,
	@cal_tRing float=0,
	@mtmoh smallint = 0,
	@isChatCall bit = 0,
	@isErroManualCall bit =0,
	@isTransferEngine bit =0,
	@cal_twait float = null,
	@cal_whoHung smallint = null
	AS
	set nocount on
	if @IDCall<=0 
		return(0)

	declare @tMinAVRS smallint
	declare @cal_manual int
	declare @minimoDialogo tinyint 
	select @minimoDialogo = valor from ccSettings where setting_id = 13

	set @cal_manual=0

	if @TipoCall=1 begin--INBOUND
	  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
		--el status 18 es para llamada cortada con transferencia en Reminder
		exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
	  end
	  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, 
		cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
	  cal_tNotas=@cal_tNotas, 
	  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
	  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
	  Where cal_id= @IDCall

	  exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=0,@statusCallId=13


	  --Actualizar tiempo total de llamada
	  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

	  -- Elimina callback generado por abandono
  
	  if @isTransferEngine = 0  begin
	  Declare @ANI_x varchar(19)
	  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

	  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
	  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
	  end
	end
	else if @TipoCall=2 begin--OUTBOUND 
		declare @calloutId int
		Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
		cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
		cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
    
		cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
		cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
    
		cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
		cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
		totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
		,@calloutId=callout_id,
		cal_twait = ISNULL(@cal_twait, cal_twait),
		cal_whoHung = ISNULL(@cal_whoHung, cal_whoHung)
		Where cal_id=@IDCall

		exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=1,@statusCallId=13
		
		DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE callout_id=@calloutId

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @IDCall
	  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

	 end

	select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

	if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
	  begin 
			insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
	end

	return(0)
	set nocount off'
	EXEC(@sql);


------------------------------END Giovanni Vivaldo-------------------------------
------------------------------Beggin Daniel Hernandez K071001-------------------------------
    SET @process = 'The sp ccsp_RIACATNotReadyTypes is removed if it exists. K071001'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIACATNotReadyTypes'')
			begin
				DROP PROCEDURE ccsp_RIACATNotReadyTypes;
			end'
    EXEC(@sql)
	SET @process = 'The sp ccsp_RIACATNotReadyTypes is created, modifying option 6 to return the number of available nd events according to the agent'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIACATNotReadyTypes]
	@TipoNotReady_id varchar(5)='''',
	@Descripcion varchar(30)='''',
	@Time_Acum varchar(10)='''',
	@Time_xEv varchar(5)='''',
	@Pas_Sup varchar(2)='''',
	@NextStatus varchar(5)='''',
	@graphic_id varchar(5)='''',
	@Type varchar(1)='''',
	@IsSup int = null,
	@super_id as int = null,
	@agent_id as int = null
	AS
	set nocount on
	DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint
	DECLARE @NotReadybyCampACD INT;
	
	if @Type=0
	begin
		SELECT TipoNotReady_id, Descripcion FROM ccTipoNotReady WITH(NOLOCK) WHERE StatusTipoNotReady=1
		return(0)
	end
	
	if @Type=6 -- LOAD by setting
	begin
		SELECT @Type = valor FROM ccSettings WHERE setting_id = 87;
		SELECT @NotReadybyCampACD = valor FROM ccSettings WHERE setting_id = 135;
		CREATE TABLE #NotReadyData (
			TipoNotReady_id INT,
			NumEvents VARCHAR(6)
		);
		IF (@NotReadybyCampACD = 0)
		BEGIN
			INSERT INTO #NotReadyData (TipoNotReady_id, NumEvents)
			SELECT 
				a1.TipoNotReady_id,
				dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
			FROM 
				ccTipoNotReady a1
			WHERE 
				a1.TipoNotReady_id > 0 
				AND a1.IsSup = 0;
		END
		ELSE IF (@NotReadybyCampACD = 1)
		BEGIN
			INSERT INTO #NotReadyData (TipoNotReady_id, NumEvents)
			SELECT 
				a1.TipoNotReady_id,
				dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
			FROM 
				ccTipoNotReady a1
			INNER JOIN 
				ccUnavailableRelation a4 ON a4.idunavailable = a1.tiponotready_id
			WHERE 
				a1.TipoNotReady_id > 0 
				AND a1.IsSup = 0
				AND a4.idCampACD IN (
					SELECT DISTINCT(inbound_id) FROM ccInboundAgentes WHERE user_id = @agent_id
				)
				AND a4.type = 0
	
			UNION ALL
	
			SELECT 
				a1.TipoNotReady_id,
				dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
			FROM 
				ccTipoNotReady a1
			INNER JOIN 
				ccUnavailableRelation a4 ON a4.idunavailable = a1.tiponotready_id
			WHERE 
				a1.TipoNotReady_id > 0 
				AND a1.IsSup = 0
				AND a4.idCampACD IN (
					SELECT DISTINCT(cam_id) FROM ccCampsAgente WHERE user_id = @agent_id
				)
				AND a4.type = 1;
		END
	
		IF @Type = 4 
		BEGIN
			SELECT 
				a1.TipoNotReady_id, 
				a1.Descripcion, 
				a1.Time_Acum, 
				a1.Time_xEv, 
				a1.Pas_Sup, 
				a1.NextStatus, 
				frame, 
				a1.IsSup,
				CASE 
					WHEN nr.NumEvents IS NULL THEN 1
					WHEN (nr.NumEvents = ''n'' OR nr.NumEvents > 0) THEN 1 
					ELSE 0 
				END AS expiredAttempts 
			FROM 
				ccTipoNotReady a1
			INNER JOIN 
				ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
			INNER JOIN 
				ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
			INNER JOIN 
				ccsupervisor_notready snd ON a1.tiponotready_id = snd.tiponotready_id AND snd.user_id = @super_id
			INNER JOIN 
				#NotReadyData nr ON a1.tiponotready_id = nr.TipoNotReady_id
			WHERE 
				a1.TipoNotReady_id > 0 
				AND a1.StatusTipoNotReady = 1;
		END
		ELSE 
		BEGIN
			SELECT 
				a1.TipoNotReady_id, 
				a1.Descripcion, 
				a1.Time_Acum, 
				a1.Time_xEv, 
				a1.Pas_Sup, 
				a1.NextStatus, 
				frame, 
				a1.IsSup,
				CASE 
					WHEN nr.NumEvents IS NULL THEN 1
					WHEN (nr.NumEvents = ''n'' OR nr.NumEvents > 0) THEN 1 
					ELSE 0 
				END AS expiredAttempts
			FROM 
				ccTipoNotReady a1
			INNER JOIN 
				ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
			INNER JOIN 
				ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
			LEFT JOIN 
				#NotReadyData nr ON a1.tiponotready_id = nr.TipoNotReady_id
			WHERE 
				a1.TipoNotReady_id > 0 
				AND a1.IsSup = CASE 
					WHEN @Type = 1 THEN (SELECT valor FROM ccSettings WHERE setting_id = 28)
					WHEN @Type = 2 THEN a1.IsSup 
					ELSE 1 
				END
				AND a1.StatusTipoNotReady = 1;
		END
	
		DROP TABLE #NotReadyData;
		return(0)
	end
	
	if @Type=1 -- LOAD
	begin
		select @NotReadybyCampACD = valor from ccsettings where setting_id = 135
		
		if (@NotReadybyCampACD = 0)
		begin
			SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
		end
		else if (@NotReadybyCampACD = 1)
			begin
				SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
				where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
				and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
				AND a4.type = 0
				union
				SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
				where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
				and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
				AND a4.type = 1
			end
		return(0)
	end
	
	If @Type=2 -- INSERT
	begin
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
		begin		
			select 1
			return(0)
		end
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Descripcion)
			begin		
				select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Descripcion
				update ccTipoNotReady set 
				Time_acum=@Time_Acum,
				Time_xEv=@Time_xEv,
				Pas_Sup=@Pas_Sup,
				NextStatus=@NextStatus,
				IsSup=@IsSup,
				StatusTipoNotReady=1
				where Descripcion=@Descripcion
				If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
					Begin
						insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
					End
		
				insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
				return(0)		
			end
		If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
		Begin
			insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
		End
	
		insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup,StatusTipoNotReady) 
		select @Descripcion, @Time_Acum, @Time_xEv, @Pas_Sup, @NextStatus, @IsSup,1
		select @id=SCOPE_IDENTITY()
		insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
		return(0)
	end
	
	If @Type=3 -- DELETE
	begin
		exec ccsp_AdminNotready 3,0,@TipoNotReady_id,0
		delete ccRIANotReadyGraph where tipoNotReady_id = @TipoNotReady_id
		update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id = @TipoNotReady_id
	end
	
	if(@Type=4) --UPDATE
	begin
	
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
		begin		
			select @Descripcion=''''
		end
	
		update ccTipoNotReady set 
		Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
		Time_Acum=case @Time_Acum when '''' then Time_Acum else @Time_Acum end,
		Time_xEv=case @Time_xEv when '''' then Time_xEv else @Time_xEv end,
		Pas_Sup=case @Pas_Sup when '''' then Pas_Sup else @Pas_Sup end,
		NextStatus=case @NextStatus when '''' then NextStatus else @NextStatus end,
		IsSup=ISNULL(@IsSup,IsSup)
		where TipoNotReady_id=@TipoNotReady_id
	
		IF ISNULL(@graphic_id,'''') not in('''')
		BEGIN
			If not exists (select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
			begin
				insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
			end
	
			select @graph = graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
			update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@TipoNotReady_id as tinyint)
		END
		return(0)
	end
	
	if @Type = 7 -- LOAD
		begin
			SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
			return(0)
		end
	
	if @Type = 8 -- Check admin permission
		begin
			select @Type = valor from ccSettings where setting_id = 87
	
			if @Type = 4 begin
				SELECT CAST( count(snd.TipoNotReady_id) AS BIT) AS hasPermission
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
				where a1.TipoNotReady_id = @TipoNotReady_id 
				and a1.StatusTipoNotReady=1
			end
			else begin
				SELECT CAST(1 AS bit) AS  hasPermission
			end
		end'
    EXEC(@sql)
------------------------------END Daniel Hernandez-------------------------------

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
