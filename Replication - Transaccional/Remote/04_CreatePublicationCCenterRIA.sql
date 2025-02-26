-- Desactiva la cantidad de filas afectadas devueltas por cada consulta
SET NOCOUNT ON

-- Cambia a la base de datos CCenterRIA
USE [CCenterRIA]

-- Declaración de variables para manejar versiones
DECLARE @Version INT, @Version_Actual INT

-- ---------------- VERSION ----------------
SET @Version = 126 -- Versión deseada

-- Ejecuta un procedimiento almacenado para obtener la versión actual de la BD
EXEC @Version_Actual = dbo.ccsp_getVersion 'BD'

-- Verifica si la versión actual es mayor o igual a la deseada
IF @Version_Actual >= @Version
BEGIN
    -- Declaración de variables
    DECLARE @dataBaseName VARCHAR(100)
    SET @dataBaseName = N'CCenterRIA';
    
    DECLARE @publicationServer NVARCHAR(MAX)

    DECLARE @hostName NVARCHAR(MAX), @indexInstancia TINYINT

    -- Obtiene el nombre del servidor
    SELECT @hostName = @@servername
    SELECT @indexInstancia = CHARINDEX('\', @hostName)

    -- Si el servidor tiene una instancia, extrae solo el nombre
    IF @indexInstancia > 0
        SET @hostName = SUBSTRING(@hostName, 0, CHARINDEX('\', @hostName))

    -- Convierte el nombre del servidor a NVARCHAR(MAX)
    SET @publicationServer = CONVERT(NVARCHAR(MAX), @@servername)

    -- Declaración de credenciales y variables adicionales
    DECLARE @jobLogin NVARCHAR(MAX)
    DECLARE @jobPassword NVARCHAR(MAX)
    DECLARE @userNameSQL NVARCHAR(50)
    DECLARE @passwordSQL NVARCHAR(50)
    DECLARE @userNameWin NVARCHAR(50)
    DECLARE @passwordWin NVARCHAR(50)

    DECLARE @publisherLogin NVARCHAR(MAX)
    DECLARE @publisherPassword NVARCHAR(MAX)    

    DECLARE @settingBD NVARCHAR(300)

    -- Almacena temporalmente los valores de configuración
    DECLARE @temp TABLE (id INT, value NVARCHAR(100));
    SELECT @settingBD = valor FROM ccSettings WHERE setting_id = 176
    INSERT INTO @temp SELECT id, Value FROM fn_RIASplitDelimited(@settingBD, '|')

    -- Asigna valores de configuración a variables
    SELECT @userNameWin = value  FROM @temp WHERE id = 1
    SELECT @passwordWin = value  FROM @temp WHERE id = 2
    SELECT @userNameSQL = value  FROM @temp WHERE id = 3
    SELECT @passwordSQL = value  FROM @temp WHERE id = 4
    SELECT @hostName = value  FROM @temp WHERE id = 5

    -- Credenciales WINDOWS
    SET @jobLogin = ISNULL(@userNameWin, @hostName + '\SnapshotReplication')
    SET @jobPassword = ISNULL(@passwordWin, 'Nuxiba2010')

    -- Credenciales SQL SERVER
    SET @publisherLogin = ISNULL(@userNameSQL, 'replication')
    SET @publisherPassword = ISNULL(@passwordSQL, 'replication')

    -- Define el periodo de retención
    DECLARE @retentionDay INT
    SET @retentionDay = 48
    
-- ****************
-- *** Publicaciones ***
-- ****************

    -- Declaración de variables para las publicaciones y artículos
    DECLARE @publicationId INT, @publicationName VARCHAR(100)
    DECLARE @articleId INT, @articleName VARCHAR(100)
	declare @hasIdentity bit
    DECLARE @force_invalidate_snapshot INT 

    -- Desactiva todas las publicaciones y artículos
    UPDATE publicationTableCCenterRIA SET status = 0
    UPDATE articleTableCCenterRIA SET status = 0

    -- Bucle para procesar cada publicación
    WHILE EXISTS(SELECT publicationName FROM publicationTableCCenterRIA WHERE status = 0)
    BEGIN
        -- Selecciona la primera publicación pendiente
        SELECT TOP 1 @publicationName = publicationName, @publicationId = Id FROM publicationTableCCenterRIA WHERE status = 0
			
        -- Verifica si la publicación ya existe
        IF NOT EXISTS (SELECT * FROM dbo.syspublications WHERE [name] = @publicationName)
        BEGIN
            -- Agrega la publicación de mezcla
            SET @force_invalidate_snapshot = 0
           EXEC sp_addpublication 
			@publication                 = @publicationName,          -- Nombre de la publicación (variable previamente definida)
			@description                 = N'Publicación transaccional de CCenterRIA para reportes (pull) cada 10-15 minutos',  
			@sync_method                 = N'concurrent',             -- Uso de sincronización concurrente para evitar bloqueos durante el snapshot
			@retention                   = @retentionDay,             -- Período de retención (en horas) para la metadata de replicación; se define externamente
			@allow_push                  = N'false',                  -- Desactiva el modo push; se usarán suscripciones pull
			@allow_pull                  = N'true',                   -- Habilita suscripciones pull para que los suscriptores extraigan los datos
			@allow_anonymous             = N'false',                 -- No se permiten suscriptores anónimos para mejorar la seguridad
			@snapshot_in_defaultfolder   = N'true',                   -- Usa la carpeta predeterminada para almacenar el snapshot			
			@compress_snapshot = N'false',
			@repl_freq                   = N'continuous',             -- Replicación continua: los cambios se registran de forma inmediata para que el suscriptor pull obtenga datos actualizados
			@status                      = N'active',                 -- Publicación activa de inmediato			
			@independent_agent           = N'true',                   -- Requerido cuando @immediate_sync es true; el agente opera de forma independiente
			@immediate_sync              = N'false',                   -- Permite sincronización inmediata para reflejar cambios en tiempo real						
			@allow_sync_tran             = N'true',                   -- Permite que se sincronicen transacciones, garantizando la consistencia
			@autogen_sync_procs          = N'true',                   -- Genera automáticamente los procedimientos necesarios para la sincronización
			@replicate_ddl               = 1,                         -- Replica cambios en DDL para mantener la estructura de los objetos actualizada

			@allow_initialize_from_backup = N'false'                -- No se permite inicializar desde un backup para evitar inconsistencias
			
		

            -- Agrega el snapshot para la publicación
           EXEC sp_addpublication_snapshot 
			@publication                 = @publicationName, 
			@frequency_type              = 1,                      -- Ejecutar manualmente
			@frequency_interval          = 0, 
			@frequency_subday            = 0, 
			@frequency_subday_interval   = 0, 
			@frequency_relative_interval = 0, 
			@frequency_recurrence_factor = 0, 
			@active_start_date           = 0,                      -- Sin fecha de inicio programada
			@active_end_date             = 0,                      -- Sin fecha de finalización programada
			@active_start_time_of_day    = 0,                    -- Hora de inicio (por ejemplo, 05:00:00)
			@active_end_time_of_day      = 235959,                 -- Hora de fin (23:59:59)			
			@publisher_security_mode     = 0,                      -- Modo de seguridad: 0 (sin seguridad integrada)
			@publisher_login             = @publisherLogin, 
			@publisher_password          = @publisherPassword, 
			@job_login                   = @jobLogin, 
			@job_password                = @jobPassword    	

		
        END
        ELSE
        BEGIN
            -- Si la publicación ya existe, invalida el snapshot
            SET @force_invalidate_snapshot = 1
        END

        -- Bucle para procesar cada artículo de la publicación
        WHILE EXISTS(SELECT articleName FROM articleTableCCenterRIA WHERE publicationId = @publicationId AND status = 0)
        BEGIN
            -- Selecciona el primer artículo pendiente
            SELECT TOP 1 @articleName = articleName, @articleId = id FROM articleTableCCenterRIA WHERE publicationId = @publicationId AND status = 0

            -- Verifica si el artículo ya existe
            IF NOT EXISTS (SELECT * FROM dbo.sysarticles WHERE [name] = @articleName)
            BEGIN

			print  @publicationName+','+@articleName
                 -- Agrega el artículo a la publicación
				-- Verificar si la tabla tiene una columna con IDENTITY
				SELECT @hasIdentity = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
				FROM sys.columns 
				WHERE object_id = OBJECT_ID(@articleName) 
				AND is_identity = 1;

                IF @hasIdentity = 1
				BEGIN
					EXEC sp_addarticle 
						@publication                = @publicationName, 
						@article                    = @articleName, 
						@source_owner               = N'dbo', 
						@source_object              = @articleName, 
						@type                       = N'logbased',  
						@description                = N'Artículo transaccional', 
						@creation_script            = NULL, 
						@pre_creation_cmd           = N'drop',  
						@schema_option              = 0x00000010,  
						@destination_table          = @articleName, 
						@destination_owner          = N'dbo', 
						@identityrangemanagementoption = N'auto',  
						@pub_identity_range         = 2,  
						@identity_range             = 1000000,  
						@threshold                  = 50,  
						@force_invalidate_snapshot  = @force_invalidate_snapshot;
				END
				ELSE
				BEGIN
					EXEC sp_addarticle 
						@publication                = @publicationName, 
						@article                    = @articleName, 
						@source_owner               = N'dbo', 
						@source_object              = @articleName, 
						@type                       = N'logbased',  
						@description                = N'Artículo transaccional', 
						@creation_script            = NULL, 
						@pre_creation_cmd           = N'drop',  
						@identityrangemanagementoption = N'manual',  
						@schema_option              = 0x00000010,  
						@destination_table          = @articleName, 
						@destination_owner          = N'dbo', 
						@force_invalidate_snapshot  = @force_invalidate_snapshot;
				END;

            END			

            -- Actualiza el estado del artículo
            UPDATE articleTableCCenterRIA SET status = 1 WHERE id = @articleId 
        END

        -- Asigna permisos de acceso a la publicación
        EXEC sp_grant_publication_access @publication = @publicationName, @login = @publisherLogin
		EXEC sp_grant_publication_access @publication = @publicationName, @login = @jobLogin
        

        -- Actualiza el estado de la publicación
        UPDATE publicationTableCCenterRIA SET status = 1 WHERE id = @publicationId
    END

    -- Fin del proceso
    SELECT 'Merge Publications Finished'
END

ELSE
BEGIN
    -- Mensaje en caso de que la versión de la BD no sea correcta
    SELECT 'Versión incorrecta de base de datos, versión actual: ' + CAST(@Version_Actual AS VARCHAR(5)) + ', versión requerida: ' + CAST(@Version AS VARCHAR(5))
END

-- Reactiva la cuenta de filas afectadas
SET NOCOUNT OFF
