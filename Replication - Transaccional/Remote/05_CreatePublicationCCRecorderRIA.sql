-- Desactiva la cuenta de filas afectadas
SET NOCOUNT ON

-- Cambia al contexto de la base de datos CCRecorderRIA
USE [CCRecorderRIA]

-- Declaración de variables para controlar la versión
DECLARE @Version INT, @Version_Actual INT

-- ---------------- VERSION ----------------
-- Define la versión requerida
SET @Version = 9



-- Obtiene la versión actual de la base de datos
SELECT @Version_Actual = par_valor FROM TREC_PARAMETROS WHERE par_id = 30

-- Verifica si la versión actual es mayor o igual a la requerida
IF @Version_Actual >= @Version
BEGIN
    -- Declaración de variables para el proceso
    DECLARE @dataBaseName VARCHAR(100)
    SET @dataBaseName = N'CCRecorderRIA';

    DECLARE @Sql NVARCHAR(MAX)
    DECLARE @publicationServer NVARCHAR(MAX)
    DECLARE @hostName NVARCHAR(MAX), @indexInstancia TINYINT

    -- Obtiene el nombre del servidor
    SELECT @hostName = @@servername
    SELECT @indexInstancia = CHARINDEX('\', @hostName)

    -- Si el nombre del servidor incluye una instancia, la separa
    IF @indexInstancia > 0
        SET @hostName = SUBSTRING(@hostName, 0, CHARINDEX('\', @hostName))

    -- Asigna el nombre del servidor como el servidor de publicación
    SET @publicationServer = CONVERT(NVARCHAR(MAX), @@servername)

    -- Declaración de credenciales
    DECLARE @jobLogin NVARCHAR(MAX)
    DECLARE @jobPassword NVARCHAR(MAX)
    DECLARE @userNameSQL NVARCHAR(50)
    DECLARE @passwordSQL NVARCHAR(50)
    DECLARE @userNameWin NVARCHAR(50)
    DECLARE @passwordWin NVARCHAR(50)

    DECLARE @publisherLogin NVARCHAR(MAX)
    DECLARE @publisherPassword NVARCHAR(MAX)

    -- Obtiene configuración de la base de datos
    DECLARE @settingBD NVARCHAR(100)

    -- Tabla temporal para almacenar los valores obtenidos
    DECLARE @temp TABLE (id INT, value NVARCHAR(100));

    -- Obtiene los parámetros de conexión
    SELECT @settingBD = par_valor FROM TREC_PARAMETROS WHERE par_id = 73
    INSERT INTO @temp SELECT id, Value FROM fn_RIASplitDelimited(@settingBD, '|')

    -- Asigna valores de la configuración a las variables
    SELECT @userNameWin = value  FROM @temp WHERE id = 1
    SELECT @passwordWin = value  FROM @temp WHERE id = 2
    SELECT @userNameSQL = value  FROM @temp WHERE id = 3
    SELECT @passwordSQL = value  FROM @temp WHERE id = 4
    SELECT @hostName = value  FROM @temp WHERE id = 5

    -- Agregado de credenciales WINDOWS
    SET @jobLogin = ISNULL(@userNameWin, @hostName + '\SnapshotReplication')
    SET @jobPassword = ISNULL(@passwordWin, 'Nuxiba2010')

    -- Agregado de credenciales SQL SERVER
    SET @publisherLogin = ISNULL(@userNameSQL, 'replication')
    SET @publisherPassword = ISNULL(@passwordSQL, 'replication')

    -- Definir periodo de retención en días
    DECLARE @retentionDay INT
    SET @retentionDay = 2

    -- ****************
    -- *** Publicaciones ***
    -- ****************

    DECLARE @publicationId INT, @publicationName VARCHAR(100)
    DECLARE @articleId INT, @articleName VARCHAR(100)
    DECLARE @force_invalidate_snapshot INT 

    -- Restablecer el estado de las publicaciones y artículos
    UPDATE publicationTableCCRecorderRIA SET status = 0
    UPDATE articleTableCCRecorderRIA SET status = 0

    -- Bucle para procesar publicaciones pendientes
    WHILE EXISTS(SELECT publicationName FROM publicationTableCCRecorderRIA WHERE status = 0)
    BEGIN
        -- Selecciona la primera publicación pendiente
        SELECT TOP 1 @publicationName = publicationName, @publicationId = Id FROM publicationTableCCRecorderRIA WHERE status = 0

        -- Si la publicación no existe, agregarla
        IF NOT EXISTS (SELECT * FROM dbo.syspublications WHERE [name] = @publicationName)
        BEGIN
            -- Agregar la publicación de mezcla
			SET @force_invalidate_snapshot = 0
            EXEC sp_addpublication 
            @publication = @publicationName, 
            @description = N'Transactional publication of database CCRecorderRIA', 
            @status = N'active', 
            @sync_method = N'concurrent',   -- 🔥 Evita bloqueos durante snapshot
            @retention = @retentionDay,  
            @allow_push = 1, 
            @allow_pull = 1, -- 🔥 Permite suscriptores PULL (reduce carga en el publicador)
            @allow_anonymous = 0, -- 🔐 Seguridad: No permitir suscriptores anónimos
            @enabled_for_internet = 0,  
            @snapshot_in_defaultfolder = 1,
            @compress_snapshot = 2,  -- 🔥 Comprime snapshot para transferencias más rápidas
            @ftp_port = 21,  
            @ftp_login = N'anonymous',  
            @allow_subscription_copy = 0,  
            @add_to_active_directory = 0,  
            @replicate_ddl = 1, -- 🔥 Replica cambios de estructura
            @immediate_sync = 0, -- 🔥 Sincronización en tiempo real
            @allow_initialize_from_backup = 0,  
            @enabled_for_p2p = 0,  
            @publication_compatibility_level = N'110RTM'; -- 🔥 Mínimo SQL Server 2012            

           -- Agrega el snapshot para la publicación
            EXEC sp_addpublication_snapshot @publication = @publicationName, 
                @frequency_type = 1,  -- 🔥 1 = Ejecutar solo manualmente
                @frequency_interval = 0, 
                @frequency_relative_interval = 0, 
                @frequency_recurrence_factor = 0, 
                @frequency_subday = 0, 
                @frequency_subday_interval = 0, 
                @active_start_time_of_day = 500, 
                @active_end_time_of_day = 235959, 
                @active_start_date = 0, 
                @active_end_date = 0, 
                @job_login = @jobLogin, 
                @job_password = @jobPassword, 
                @publisher_security_mode = 0, 
                @publisher_login = @publisherLogin, 
                @publisher_password = @publisherPassword,
                @compress_snapshot = 2;  -- 🔥 Comprime los datos para que la transferencia sea más rápida
        END
        ELSE
        BEGIN
            -- Si la publicación ya existe, invalida el snapshot
            SET @force_invalidate_snapshot = 1
        END

        -- Bucle para procesar artículos de la publicación
        WHILE EXISTS(SELECT articleName FROM articleTableCCRecorderRIA WHERE publicationId = @publicationId AND status = 0)
        BEGIN
            -- Selecciona el primer artículo pendiente
            SELECT TOP 1 @articleName = articleName, @articleId = id FROM articleTableCCRecorderRIA WHERE publicationId = @publicationId AND status = 0

            -- Si el artículo no existe, agregarlo
            IF NOT EXISTS (SELECT * FROM dbo.sysarticles WHERE [name] = @articleName)
            BEGIN
                -- Agregar el artículo
                EXEC sp_addarticle 
                    @publication = @publicationName, 
                    @article = @articleName, 
                    @source_owner = N'dbo', 
                    @source_object = @articleName, 
                    @type = N'logbased',  -- 🔥 Replicación basada en el transaction log
                    @description = N'Artículo transaccional', 
                    @creation_script = NULL, 
                    @pre_creation_cmd = N'drop',  -- 🔥 Si existe en el suscriptor, la elimina y la vuelve a crear
                    @schema_option = 0x00000010,  -- 🔥 Replica solo índice primario y estructura
                    @destination_table = @articleName, 
                    @destination_owner = N'dbo', 
                    @force_invalidate_snapshot = @force_invalidate_snapshot;
            END
            -- Actualiza el estado del artículo
            UPDATE articleTableCCRecorderRIA SET status = 1 WHERE id = @articleId
        END

        -- Otorga acceso a la publicación al usuario
        EXEC sp_grant_publication_access @publication = @publicationName, @login = @publisherLogin

       
        -- Actualiza el estado de la publicación
        UPDATE publicationTableCCRecorderRIA SET status = 1 WHERE id = @publicationId
    END

    -- Mensaje de finalización
    SELECT 'Merge Publications Finished'
END
ELSE
BEGIN
    -- Mensaje si la versión es incorrecta
    SELECT 'Versión incorrecta de base de datos, versión actual: ' + CAST(@Version_Actual AS VARCHAR(5)) + ', versión requerida: ' + CAST(@Version AS VARCHAR(5))
END

-- Reactiva la cuenta de filas afectadas
SET NOCOUNT OFF
