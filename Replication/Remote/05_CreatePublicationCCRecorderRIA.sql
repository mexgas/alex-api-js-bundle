-- Desactiva la cuenta de filas afectadas
SET NOCOUNT ON

-- Declaración de variables para controlar la versión
DECLARE @Version INT, @Version_Actual INT

-- ---------------- VERSION ----------------
-- Define la versión requerida
SET @Version = 9

-- Cambia al contexto de la base de datos CCRecorderRIA
USE [CCRecorderRIA]

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
        IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = @publicationName)
        BEGIN
            -- Agregar la publicación de mezcla
            EXEC sp_addmergepublication @publication = @publicationName, 
                @description = N'Merge publication of database CCRecorderRIA', 
                @sync_mode = N'native', 
                @retention = @retentionDay,
                @allow_push = N'true', 
                @allow_pull = N'true', 
                @allow_anonymous = N'true', 
                @enabled_for_internet = N'false', 
                @snapshot_in_defaultfolder = N'true',
                @compress_snapshot = N'false', 
                @ftp_port = 21, 
                @ftp_login = N'anonymous', 
                @allow_subscription_copy = N'false', 
                @add_to_active_directory = N'false',
                @dynamic_filters = N'false', 
                @conflict_retention = @retentionDay, 
                @keep_partition_changes = N'false', 
                @allow_synctoalternate = N'false', 
                @max_concurrent_merge = 0,
                @max_concurrent_dynamic_snapshots = 0, 
                @use_partition_groups = NULL, 
                @publication_compatibility_level = N'90RTM', 
                @replicate_ddl = 1,
                @allow_subscriber_initiated_snapshot = N'false', 
                @allow_web_synchronization = N'false', 
                @allow_partition_realignment = N'true', 
                @retention_period_unit = N'days',
                @conflict_logging = N'both', 
                @automatic_reinitialization_policy = 0,
                @generation_leveling_threshold = 0

            -- Agregar el snapshot para la publicación
            EXEC sp_addpublication_snapshot @publication = @publicationName, 
                @frequency_type = 1, 
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
                @publisher_password = @publisherPassword 	
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
            IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = @articleName)
            BEGIN
                -- Agregar el artículo
                EXEC sp_addmergearticle @publication = @publicationName, 
                    @article = @articleName, 
                    @source_owner = N'dbo', 
                    @source_object = @articleName, 
                    @type = N'table', 
                    @description = N'', 
                    @creation_script = NULL, 
                    @pre_creation_cmd = N'drop', 
                    @schema_option = 0x000000000800B311, 
                    @identityrangemanagementoption = N'manual', 
                    @destination_owner = N'dbo', 
                    @force_reinit_subscription = 1, 
                    @column_tracking = N'false', 
                    @subset_filterclause = NULL, 
                    @vertical_partition = N'false', 
                    @verify_resolver_signature = 1, 
                    @allow_interactive_resolver = N'false', 
                    @fast_multicol_updateproc = N'true', 
                    @check_permissions = 0, 
                    @subscriber_upload_options = 1, 
                    @delete_tracking = N'true', 
                    @compensate_for_errors = N'false', 
                    @stream_blob_columns = N'false', 
                    @partition_options = 0,
                    @force_invalidate_snapshot = @force_invalidate_snapshot
            END
            -- Actualiza el estado del artículo
            UPDATE articleTableCCRecorderRIA SET status = 1 WHERE id = @articleId
        END

        -- Otorga acceso a la publicación al usuario
        EXEC sp_grant_publication_access @publication = @publicationName, @login = @publisherLogin

        -- Verifica si es necesario ajustar el periodo de retención
        IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = @publicationName AND [retention] <> @retentionDay)
        BEGIN
            EXEC sp_changemergepublication @publication = @publicationName, @property = 'retention', @value = @retentionDay, @force_reinit_subscription = 1
        END

        -- Actualiza el estado de la publicación
        UPDATE publicationTableCCRecorderRIA SET status = 1 WHERE id = @publicationId
    END

    -- Mensaje de finalización
    SELECT 'Merge Publications Finished'
END
ELSE
BEGIN
    -- Mensaje si la versión es incorrecta
    SELECT 'Versión incorrecta de base de datos, versión actual: ' + CAST(@Version_Actual AS VARCHAR(5)) + ', versión que desea ingresar: ' + CAST(@Version AS VARCHAR(5))
END

-- Reactiva la cuenta de filas afectadas
SET NOCOUNT OFF
