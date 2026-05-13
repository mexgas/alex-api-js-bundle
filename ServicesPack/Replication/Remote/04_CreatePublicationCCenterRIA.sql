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

    DECLARE @Sql NVARCHAR(MAX)
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
    DECLARE @snapshotFolder NVARCHAR(MAX)

    DECLARE @settingBD NVARCHAR(100)

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
    SET @retentionDay = 2

    -- Cambia a la base de datos CCenterRia para las publicaciones
    USE [CCenterRia] 

    -- Declaración de variables para las publicaciones y artículos
    DECLARE @publicationId INT, @publicationName VARCHAR(100)
    DECLARE @articleId INT, @articleName VARCHAR(100)
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
        IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = @publicationName)
        BEGIN
            -- Agrega la publicación de mezcla
            SET @force_invalidate_snapshot = 0
            EXEC sp_addmergepublication @publication = @publicationName, 
                @description = N'Merge publication of database CCenterRIA', 
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

            -- Agrega el snapshot para la publicación
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

        -- Bucle para procesar cada artículo de la publicación
        WHILE EXISTS(SELECT articleName FROM articleTableCCenterRIA WHERE publicationId = @publicationId AND status = 0)
        BEGIN
            -- Selecciona el primer artículo pendiente
            SELECT TOP 1 @articleName = articleName, @articleId = id FROM articleTableCCenterRIA WHERE publicationId = @publicationId AND status = 0

            -- Verifica si el artículo ya existe
            IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = @articleName)
            BEGIN
                -- Agrega el artículo a la publicación
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
                    @subscriber_upload_options = 2, 
                    @delete_tracking = N'true', 
                    @compensate_for_errors = N'false', 
                    @stream_blob_columns = N'false', 
                    @partition_options = 0,
                    @force_invalidate_snapshot = @force_invalidate_snapshot
            END

            -- Actualiza el estado del artículo
            UPDATE articleTableCCenterRIA SET status = 1 WHERE id = @articleId 
        END

        -- Asigna permisos de acceso a la publicación
        EXEC sp_grant_publication_access @publication = @publicationName, @login = @publisherLogin

        -- Verifica y ajusta el período de retención si es necesario
        IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = @publicationName AND [retention] <> @retentionDay)
        BEGIN
            EXEC sp_changemergepublication @publication = @publicationName, @property = 'retention', @value = @retentionDay, @force_reinit_subscription = 1
        END

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
