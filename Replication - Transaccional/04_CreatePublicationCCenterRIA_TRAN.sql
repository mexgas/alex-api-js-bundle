
SET NOCOUNT ON

USE [CCenterRIA]

DECLARE @Version INT, @Version_Actual INT

-- ---------------- VERSION ----------------
SET @Version = 126

EXEC @Version_Actual = dbo.ccsp_getVersion 'BD'

IF @Version_Actual >= @Version
BEGIN
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

    -- Declaracion de credenciales y variables adicionales
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
    
    -- Almacena temporalmente los valores de configuracion
    DECLARE @temp TABLE (id INT, value NVARCHAR(100));
    SELECT @settingBD = valor FROM ccSettings WHERE setting_id = 176
    INSERT INTO @temp SELECT id, Value FROM fn_RIASplitDelimited(@settingBD, '|')

    -- Asigna valores de configuracion a variables
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

    -- Define el periodo de retencion
    DECLARE @retentionHours INT
    SET @retentionHours = 48

    -- Cambia a la base de datos CCenterRia para las publicaciones
    USE [CCenterRia] 

    -- Declaracion de variables para las publicaciones y articulos
    DECLARE @publicationId INT, @publicationName VARCHAR(100)
    DECLARE @articleId INT, @articleName VARCHAR(100)
    DECLARE @force_invalidate_snapshot INT 

    -- Desactiva todas las publicaciones y articulos
    UPDATE publicationTableCCenterRIA SET status = 0
    UPDATE articleTableCCenterRIA SET status = 0

    -- Bucle para procesar cada publicacion
    WHILE EXISTS(SELECT publicationName FROM publicationTableCCenterRIA WHERE status = 0)
    BEGIN
        -- Selecciona la primera publicacion pendiente
        SELECT TOP 1 @publicationName = publicationName, @publicationId = Id FROM publicationTableCCenterRIA WHERE status = 0

        -- Verifica si la publicacion ya existe
        IF NOT EXISTS (SELECT * FROM dbo.syspublications WHERE [name] = @publicationName)
        BEGIN
            -- Agrega la publicacion
            SET @force_invalidate_snapshot = 0
            exec sp_addpublication @publication = @publicationName, 
			@description = N'Transactional publication of database CCenterRIA', 
			@sync_method = N'concurrent', --allow to make the sync without locking
			@retention = @retentionHours,
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
			@repl_freq = N'continuous', 
			@status = N'active', 
			@independent_agent = N'true', 
			@immediate_sync = N'true', 
			@allow_sync_tran = N'false', 
			@autogen_sync_procs = N'false', 
			@allow_queued_tran = N'false', 
			@allow_dts = N'false', 
			@replicate_ddl = 1, 
			@allow_initialize_from_backup = N'false', 
			@enabled_for_p2p = N'false', 
			@enabled_for_het_sub = N'false'

            -- Agrega el snapshot para la publicacion
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
            -- Si la publicacion ya existe, invalida el snapshot
            SET @force_invalidate_snapshot = 1
        END

        -- Bucle para procesar cada articulo de la publicacion
        WHILE EXISTS(SELECT articleName FROM articleTableCCenterRIA WHERE publicationId = @publicationId AND status = 0)
        BEGIN
            SELECT TOP 1 @articleName = articleName, @articleId = id FROM articleTableCCenterRIA WHERE publicationId = @publicationId AND status = 0
			
            --Codigo para validar PK 
            if NOT exists
            (
                select 1
                from 
                    sys.tables tab
                inner join 
                    sys.indexes pk
                on 
                    tab.object_id = pk.object_id    
                where
                    pk.is_primary_key = 1
                    and tab.name =@articleName
            ) 
            BEGIN
                declare @sqlcmd varchar(1000)=''
                set @sqlcmd='ALTER TABLE ['+@articleName+'] ADD replkey UNIQUEIDENTIFIER DEFAULT newsequentialid() NOT null'
                EXEC(@sqlcmd)    

                if exists
                (
                    SELECT  1
                    FROM    sys.indexes i
                    JOIN    sys.objects o ON i.object_id = o.object_id
                    WHERE   i.type = 1 
                    and o.name like @articleName
                )
                begin
                    set @sqlcmd='ALTER TABLE ['+@articleName+'] ADD constraint PK_'+@articleName+'_ primary key  nonclustered(replkey)'
                    EXEC(@sqlcmd)
                END
                ELSE
                begin
                    set @sqlcmd='ALTER TABLE ['+@articleName+'] ADD constraint PK_'+@articleName+'_ primary key  clustered(replkey)'
                    EXEC(@sqlcmd)
                end
            END

            -- Verifica si el articulo ya existe
            IF NOT EXISTS (SELECT * FROM dbo.sysarticles WHERE [name] = @articleName)
            BEGIN
                -- Agrega el articulo a la publicacion
                exec sp_addarticle @publication = @publicationName, 
				@article = @articleName, 
				@source_owner = N'dbo', 
				@source_object = @articleName, 
				@type = N'logbased', 
				@description = N'', 
				@creation_script = N'', 
				@pre_creation_cmd = N'drop', 
				@schema_option = 0x00000000080050DF, 
				@identityrangemanagementoption = N'manual', 
				@destination_table = @articleName, 
				@destination_owner = N'dbo', 
				--@status = 24, 
				@vertical_partition = N'false', 
				@ins_cmd = 'SQL', 
				@del_cmd = 'SQL', 
				@upd_cmd = 'SQL'
            END

            -- Actualiza el estado del articulo
            UPDATE articleTableCCenterRIA SET status = 1 WHERE id = @articleId 
        END

        -- Asigna permisos de acceso a la publicacion
        EXEC sp_grant_publication_access @publication = @publicationName, @login = @publisherLogin

        -- Verifica y ajusta el periodo de retencion si es necesario
        IF EXISTS (SELECT * FROM dbo.syspublications WHERE [name] = @publicationName AND [retention] <> @retentionHours)
        BEGIN
            EXEC sp_changepublication @publication = @publicationName, @property = 'retention', @value = @retentionHours, @force_reinit_subscription = 1
        END

        UPDATE publicationTableCCenterRIA SET status = 1 WHERE id = @publicationId
    END

    SELECT 'Transactional Replication Publications Finished' AS Message
END
ELSE
BEGIN
    SELECT 'Version incorrecta de base de datos, version actual: ' + CAST(@Version_Actual AS VARCHAR(5)) + ', version requerida: ' + CAST(@Version AS VARCHAR(5))
END

SET NOCOUNT OFF
