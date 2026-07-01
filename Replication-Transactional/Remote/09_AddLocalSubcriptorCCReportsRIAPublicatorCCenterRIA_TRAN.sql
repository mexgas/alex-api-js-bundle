SET NOCOUNT ON;

USE [CCReportsRIA];

DECLARE @Version int,
        @Version_Actual int;

---------------- VERSION ----------------
SET @Version = 102;

EXEC @Version_Actual = dbo.ccsp_getVersion 'BD';

IF @Version_Actual >= @Version
BEGIN
    DECLARE @Sql nvarchar(max);
    DECLARE @publicationServer nvarchar(max);
    DECLARE @hostName nvarchar(max);
    DECLARE @indexInstancia tinyint;

    SELECT @hostName = @@SERVERNAME;
    SELECT @indexInstancia = CHARINDEX('\', @hostName);

    IF @indexInstancia > 0
        SET @hostName = SUBSTRING(@hostName, 1, CHARINDEX('\', @hostName) - 1);

    --------------------------------------------------------------------
    -- Obtener servidor de publicación
    --------------------------------------------------------------------
    SELECT @publicationServer = CONVERT(nvarchar(max), valor)
    FROM ccSettings
    WHERE setting_id = 31;

    IF CHARINDEX('|', @publicationServer) > 0
    BEGIN
        SET @publicationServer = LEFT(@publicationServer, CHARINDEX('|', @publicationServer) - 1);
    END;

    IF ISNULL(@publicationServer, '') = ''
    BEGIN
        RAISERROR('No se pudo obtener @publicationServer desde ccSettings setting_id = 31.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------------------
    -- Variables de credenciales
    --------------------------------------------------------------------
    DECLARE @jobLogin nvarchar(max);
    DECLARE @jobPassword nvarchar(max);
    DECLARE @userNameSQL nvarchar(50);
    DECLARE @passwordSQL nvarchar(50);
    DECLARE @userNameWin nvarchar(50);
    DECLARE @passwordWin nvarchar(50);

    DECLARE @publDistLogin nvarchar(max);
    DECLARE @publDistPassword nvarchar(max);

    DECLARE @settingBD nvarchar(100);

    DECLARE @temp TABLE
    (
        id int,
        value nvarchar(100)
    );

    SELECT @settingBD = valor
    FROM ccSettings
    WHERE setting_id = 35;

    INSERT INTO @temp
    SELECT id, value
    FROM fn_RIASplitDelimited(@settingBD, '|');

    SELECT @userNameWin = value
    FROM @temp
    WHERE id = 1;

    SELECT @passwordWin = value
    FROM @temp
    WHERE id = 2;

    SELECT @userNameSQL = value
    FROM @temp
    WHERE id = 3;

    SELECT @passwordSQL = value
    FROM @temp
    WHERE id = 4;

    SELECT @hostName = value
    FROM @temp
    WHERE id = 5;

    --------------------------------------------------------------------
    -- Credenciales WINDOWS
    --------------------------------------------------------------------
    SET @jobLogin = ISNULL(NULLIF(@userNameWin, ''), @hostName + '\SnapshotReplication');
    SET @jobPassword = ISNULL(NULLIF(@passwordWin, ''), 'Nuxiba2010');

    --------------------------------------------------------------------
    -- Credenciales SQL SERVER
    --------------------------------------------------------------------
    SET @publDistLogin = ISNULL(NULLIF(@userNameSQL, ''), 'replication');
    SET @publDistPassword = ISNULL(NULLIF(@passwordSQL, ''), 'replication');

    --------------------------------------------------------------------
    -- Cambiar owner a sa si aplica
    --------------------------------------------------------------------
    IF EXISTS
    (
        SELECT 1
        FROM sys.databases
        WHERE name = 'CCReportsRIA'
          AND SUSER_SNAME(owner_sid) <> 'sa'
    )
    BEGIN
        ALTER AUTHORIZATION ON DATABASE::CCReportsRIA TO sa;
    END;

    --------------------------------------------------------------------
    -- Validar tabla de publicaciones
    --------------------------------------------------------------------
    IF OBJECT_ID(N'dbo.publicationTableCCenterRIA', N'U') IS NULL
    BEGIN
        RAISERROR('No existe la tabla dbo.publicationTableCCenterRIA en CCReportsRIA.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------------------
    -- Inicio de creación de pull subscriptions
    --------------------------------------------------------------------
    DECLARE @publicationId int;
    DECLARE @publicationName varchar(100);
    DECLARE @ExisteSuscripcion bit;

    UPDATE publicationTableCCenterRIA
    SET status = 0;

    WHILE EXISTS
    (
        SELECT 1
        FROM publicationTableCCenterRIA
        WHERE status = 0
    )
    BEGIN
        SELECT TOP 1
            @publicationName = publicationName,
            @publicationId = Id
        FROM publicationTableCCenterRIA
        WHERE status = 0
        ORDER BY Id;

        SET @ExisteSuscripcion = 0;

        ----------------------------------------------------------------
        -- Validar existencia de suscripción sin romper si la tabla no existe
        ----------------------------------------------------------------
        IF OBJECT_ID(N'dbo.MSreplication_subscriptions', N'U') IS NOT NULL
        BEGIN
            SET @Sql = N'
                IF EXISTS
                (
                    SELECT 1
                    FROM dbo.MSreplication_subscriptions
                    WHERE UPPER(publisher) = UPPER(@publisher)
                      AND UPPER(publisher_db) = UPPER(@publisher_db)
                      AND UPPER(publication) = UPPER(@publication)
                )
                BEGIN
                    SET @existe = 1;
                END
                ELSE
                BEGIN
                    SET @existe = 0;
                END;
            ';

            EXEC sp_executesql
                @Sql,
                N'@publisher nvarchar(255),
                  @publisher_db nvarchar(255),
                  @publication nvarchar(255),
                  @existe bit OUTPUT',
                @publisher = @publicationServer,
                @publisher_db = N'CCenterRia',
                @publication = @publicationName,
                @existe = @ExisteSuscripcion OUTPUT;
        END
        ELSE
        BEGIN
            SET @ExisteSuscripcion = 0;
        END;

        ----------------------------------------------------------------
        -- Crear suscripción si no existe
        ----------------------------------------------------------------
        IF @ExisteSuscripcion = 0
        BEGIN
            BEGIN TRY

                PRINT 'Creando pull subscription para publicacion: ' + @publicationName;

                EXEC sp_addpullsubscription
                    @publisher = @publicationServer,
                    @publication = @publicationName,
                    @publisher_db = N'CCenterRia',
                    @independent_agent = N'True',
                    @subscription_type = N'pull',
                    @description = N'',
                    @update_mode = N'read only',
                    @immediate_sync = 0;

                EXEC sp_addpullsubscription_agent
                    @publisher = @publicationServer,
                    @publisher_db = N'CCenterRia',
                    @publication = @publicationName,
                    @distributor = @publicationServer,
                    @distributor_security_mode = 0,
                    @distributor_login = @publDistLogin,
                    @distributor_password = @publDistPassword,
                    @enabled_for_syncmgr = N'False',
                    @frequency_type = 1,
                    @frequency_interval = 0,
                    @frequency_relative_interval = 0,
                    @frequency_recurrence_factor = 0,
                    @frequency_subday = 0,
                    @frequency_subday_interval = 0,
                    @active_start_time_of_day = 0,
                    @active_end_time_of_day = 0,
                    @active_start_date = 0,
                    @active_end_date = 19950101,
                    @alt_snapshot_folder = N'',
                    @working_directory = N'',
                    @use_ftp = N'False',
                    @job_login = @jobLogin,
                    @job_password = @jobPassword,
                    @publication_type = 0;

                PRINT 'Pull subscription creada correctamente para publicacion: ' + @publicationName;

            END TRY
            BEGIN CATCH

                SELECT
                    ERROR_NUMBER() AS ErrorNumber,
                    ERROR_MESSAGE() AS ErrorMessage,
                    ERROR_PROCEDURE() AS ErrorProcedure,
                    ERROR_LINE() AS ErrorLine,
                    @publicationServer AS PublicationServer,
                    N'CCenterRia' AS PublisherDB,
                    @publicationName AS PublicationName,
                    @publDistLogin AS DistributorLogin,
                    @jobLogin AS JobLogin;

            END CATCH;
        END
        ELSE
        BEGIN
            PRINT 'La suscripcion ya existe para la publicacion: ' + @publicationName;
        END;

        ----------------------------------------------------------------
        -- Marcar publicación como procesada
        ----------------------------------------------------------------
        UPDATE publicationTableCCenterRIA
        SET status = 1
        WHERE Id = @publicationId;
    END;

    --------------------------------------------------------------------
    -- Fin
    --------------------------------------------------------------------
    SELECT 'Pull subscription setup completed successfully.' AS Resultado;
END;
ELSE
BEGIN
    SELECT
        'Version incorrecta de base de datos, version actual: '
        + CAST(@Version_Actual AS varchar(5))
        + ', version que desea ingresar: '
        + CAST(@Version AS varchar(5)) AS Resultado;
END;

SET NOCOUNT OFF;