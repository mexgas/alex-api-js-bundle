USE CCenterRIA
GO

DECLARE @process VARCHAR(100)
DECLARE @sql NVARCHAR(MAX)

BEGIN TRAN
BEGIN TRY

    -- =====================================================================
    -- K070381 - Mejoras en la extraccion de datos (Calificaciones IA)
    -- BD: CCenterRIA
    -- Cambios:
    --   1. Tabla ccExtractionDataCatalog: catalogo global (por cliente) de
    --      "datos a extraer" configurables desde el panel "Anadir dato"
    --      del modal de Calificacion IA (Nombre/Tipo/Descripcion).
    --   2. Tabla ccDispositionExtractionData: relacion N:M entre una
    --      Calificacion IA (cctipoCalif_IA) y los items del catalogo
    --      seleccionados para esa calificacion (maximo 10, validado en
    --      capa de aplicacion).
    --   3. SP ccsp_GalateaAdminExtractionDataCatalog: CRUD del catalogo
    --      (patron identico a BlackList.Catalog: @Option + acciones).
    --   4. SP ccsp_GalateaAdminDispositionExtractionData: guarda/lee la
    --      relacion N:M para una calificacion (delete+insert, mismo
    --      patron que listas separadas por coma via fn_RIASplitDelimited).
    --   5. ALTER ccsp_ManageQuantumDispositions (Action=3): se deja de leer
    --      cci.ExtDescription (texto libre, no cumplia el contrato
    --      documentado por Quantum) como fuente de required_data. No se
    --      borra la columna ExtDescription por si algun otro consumidor
    --      la usa; solo se deja de usar para este fin.
    --   6. ALTER ccsp_ManageQuantumDispositions: se agrega Action=7, que
    --      devuelve los items de extraccion requeridos por calificacion
    --      (calif_id, Name, Type, Description) para toda la campana, para
    --      que la capa de aplicacion arme required_data:
    --      [{name,type,description}] al sincronizar con Quantum.
    --      Se agrega como Action independiente (no como segundo result
    --      set de Action=3) porque el helper base de acceso a datos en
    --      C# (InvokeStoreProcedureWithResults) solo lee un result set
    --      por llamada -- mismo patron que el resto del repositorio.
    -- Notas:
    --   - Sin FOR JSON / OPENJSON (SQL Server 2012, guardarraiz cw-database
    --     y cw-reports-asp): el JSON de required_data se arma en C#.
    --   - Type en catalogo: 0=Numero, 1=Texto, 2=Fecha (mapeo a
    --     number/string/date se hace en capa de aplicacion).
    -- =====================================================================

    SET @process = 'K070381 - Tabla ccExtractionDataCatalog'

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ccExtractionDataCatalog')
    BEGIN
        CREATE TABLE dbo.ccExtractionDataCatalog (
            Id              INT IDENTITY(1,1) NOT NULL,
            Name            VARCHAR(20)  NOT NULL,
            [Key]           VARCHAR(30)  NOT NULL,
            Type            TINYINT      NOT NULL, -- 0=Numero, 1=Texto, 2=Fecha
            Description     VARCHAR(150) NULL,
            Active          BIT          NOT NULL DEFAULT 1,
            CreatedBy       SMALLINT     NULL,
            CreatedDate     DATETIME     NOT NULL DEFAULT GETDATE(),
            CONSTRAINT PK_ccExtractionDataCatalog PRIMARY KEY CLUSTERED (Id),
            CONSTRAINT UQ_ccExtractionDataCatalog_Key UNIQUE ([Key])
        )
    END

    SET @process = 'K070381 - Tabla ccDispositionExtractionData'

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ccDispositionExtractionData')
    BEGIN
        CREATE TABLE dbo.ccDispositionExtractionData (
            calif_id         SMALLINT NOT NULL,
            ExtractionDataId INT      NOT NULL,
            CONSTRAINT PK_ccDispositionExtractionData PRIMARY KEY CLUSTERED (calif_id, ExtractionDataId),
            CONSTRAINT FK_ccDispositionExtractionData_Calif FOREIGN KEY (calif_id)
                REFERENCES dbo.cctipoCalif_IA (calif_id),
            CONSTRAINT FK_ccDispositionExtractionData_Catalog FOREIGN KEY (ExtractionDataId)
                REFERENCES dbo.ccExtractionDataCatalog (Id)
        )
    END

    SET @process = 'K070381 - SP ccsp_GalateaAdminExtractionDataCatalog'

    IF OBJECT_ID('ccsp_GalateaAdminExtractionDataCatalog') IS NOT NULL
        DROP PROCEDURE ccsp_GalateaAdminExtractionDataCatalog

    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminExtractionDataCatalog]
    @Option      SMALLINT,           -- 1=CREATE, 2=READ (list), 3=UPDATE, 4=DEACTIVATE
    @Id          INT           = NULL,
    @Name        VARCHAR(20)   = NULL,
    @Key         VARCHAR(30)   = NULL,
    @Type        TINYINT       = NULL,
    @Description VARCHAR(150)  = NULL,
    @User_id     SMALLINT      = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 1 -- CREATE
    BEGIN
        IF EXISTS (SELECT 1 FROM ccExtractionDataCatalog WHERE [Key] = @Key AND Active = 1)
        BEGIN
            RAISERROR(''Duplicate extraction data key'', 16, 1)
            RETURN
        END

        INSERT INTO ccExtractionDataCatalog (Name, [Key], Type, Description, Active, CreatedBy, CreatedDate)
        VALUES (@Name, @Key, @Type, @Description, 1, @User_id, GETDATE())

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id, @Name AS Name, @Key AS [Key], @Type AS Type, @Description AS Description
    END

    IF @Option = 2 -- READ (catalogo completo activo)
    BEGIN
        SELECT
            Id,
            Name,
            [Key],
            Type,
            Description
        FROM ccExtractionDataCatalog WITH (NOLOCK)
        WHERE Active = 1
        ORDER BY Name
    END

    IF @Option = 3 -- UPDATE
    BEGIN
        UPDATE ccExtractionDataCatalog
        SET Name = ISNULL(@Name, Name),
            Type = ISNULL(@Type, Type),
            Description = @Description
        WHERE Id = @Id

        SELECT Id, Name, [Key], Type, Description FROM ccExtractionDataCatalog WHERE Id = @Id
    END

    IF @Option = 4 -- DEACTIVATE (no se borra fisicamente por integridad con relaciones historicas)
    BEGIN
        UPDATE ccExtractionDataCatalog SET Active = 0 WHERE Id = @Id
    END
END'
    exec (@sql)

    SET @process = 'K070381 - SP ccsp_GalateaAdminDispositionExtractionData'

    IF OBJECT_ID('ccsp_GalateaAdminDispositionExtractionData') IS NOT NULL
        DROP PROCEDURE ccsp_GalateaAdminDispositionExtractionData

    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositionExtractionData]
    @Option              SMALLINT,          -- 1=SAVE (delete+insert), 2=GET
    @CalifId             SMALLINT,
    @ExtractionDataIds   VARCHAR(MAX) = NULL -- CSV de Id''s, solo para @Option=1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 1 -- SAVE
    BEGIN
        DELETE FROM ccDispositionExtractionData WHERE calif_id = @CalifId

        IF @ExtractionDataIds IS NOT NULL AND LEN(@ExtractionDataIds) > 0
        BEGIN
            INSERT INTO ccDispositionExtractionData (calif_id, ExtractionDataId)
            SELECT @CalifId, CAST(value AS INT)
            FROM dbo.fn_RIASplitDelimited(@ExtractionDataIds, '','')
        END
    END

    IF @Option = 2 -- GET
    BEGIN
        SELECT
            cat.Id,
            cat.Name,
            cat.[Key],
            cat.Type,
            cat.Description
        FROM ccDispositionExtractionData rel WITH (NOLOCK)
        INNER JOIN ccExtractionDataCatalog cat WITH (NOLOCK)
            ON cat.Id = rel.ExtractionDataId
        WHERE rel.calif_id = @CalifId
        ORDER BY cat.Name
    END
END'
    exec (@sql)

    SET @process = 'K070381 - ALTER ccsp_ManageQuantumDispositions (Action=3: fix required_data)'

    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
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
        -- Result set 1: cabecera de disposiciones (sin ExtDescription -- K070381)
        SELECT
            cci.calif_id AS [Id],
        cci.Description_cal AS [Description],
        CAST(CASE WHEN cci.CanReprogram = 1 OR cci.autoCallback = 1 THEN 1 ELSE 0 END AS INT) AS Callback,
        CAST(CASE
        WHEN cci.TransferOpcion = 1 THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0 END  AS INT) AS Fallback,
        CAST(CASE
        WHEN cci.TransferOpcion = 2  THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0  END AS INT) AS Success,
        CAST(CASE
        WHEN cci.TransferOpcion = 3 THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0 END AS INT) AS Ivr
        FROM dbo.ccCalifCampIA AS ccci INNER JOIN dbo.cctipoCalif_IA AS cci
        ON cci.calif_id = ccci.calif_id
        WHERE ccci.tipo = @CampType
        AND ccci.cam_id = @CampId
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
        IF @CampType = 0
        BEGIN
            SELECT
                 CASE
                -- 1. If both transfer options are disabled (0), return FALSE (0).
                WHEN ISNULL(cie.TransferToHumanAgents, 0) = 0
                     AND ISNULL(cie.TransferOnSuccessfulHandling, 0) = 0 THEN CAST(0 AS BIT)

                -- 2. LOGICAL VALIDATION:
                -- Ensure that all active configurations are valid and have no missing requirements.
                WHEN
                    (
                        -- Validate ''TransferToHumanAgents'' integrity
                        CASE
                            WHEN cie.TransferToHumanAgents = 2 THEN 1 -- Valid: External transfer
                            WHEN cie.TransferToHumanAgents = 1 AND ISNULL(ci2.idForNonComprehension, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
                            WHEN cie.TransferToHumanAgents = 0 THEN 1 -- Valid: Option is disabled, skip validation
                            ELSE 0 -- Invalid: Option enabled but missing target campaign ID
                        END = 1
                    )
                    AND -- ALL enabled configurations must be valid simultaneously
                    (
                        -- Validate ''TransferOnSuccessfulHandling'' integrity
                        CASE
                            WHEN cie.TransferOnSuccessfulHandling = 2 THEN 1 -- Valid: External transfer
                            WHEN cie.TransferOnSuccessfulHandling = 1 AND ISNULL(ci2.idForSuccessfulTransaction, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
                            WHEN cie.TransferOnSuccessfulHandling = 0 THEN 1 -- Valid: Option is disabled, skip validation
                            ELSE 0 -- Invalid: Option enabled but missing target campaign ID
                        END = 1
                    )
                    THEN CAST(1 AS BIT)

                ELSE CAST(0 AS BIT)
            END
            FROM dbo.ccInboundExtend AS cie
            INNER JOIN dbo.ccInbound AS ci2
            ON ci2.Inbound_id = cie.Inbound_id
            WHERE cie.Inbound_id= @CampId;
        END
        ELSE
        BEGIN
            SELECT
            CASE
                WHEN EXISTS (SELECT 1 FROM dbo.ccInbound WHERE cam_id = @CampId)
                THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END AS ExisteCampana;
        END
    END

    IF @Action = 6 -- Agent Id By Campaign
    BEGIN
        IF(@CampType = 0)
        BEGIN

            SELECT ISNULL(
                (SELECT TOP 1 idAgent
                 FROM ccVirtualAgent
                 WHERE idCampaign = @CampId
                   AND mediaType = 11
                   AND campType = 0),
                0
            ) AS idAgent;
        END
        ELSE
        BEGIN
            SELECT ISNULL(
                    (SELECT TOP 1 idAgent
                     FROM ccVirtualAgent
                     WHERE idCampaign = @CampId
                       AND mediaType = 10 AND campType = 1),
                    0
                ) AS idAgent;
        END
    END

    IF @Action = 7 -- Get Quantum Extraction Data by camp (K070381)
    BEGIN
        -- Items de extraccion requeridos por calificacion, para toda la
        -- campana. Action independiente (no segundo result set de
        -- Action=3) porque el helper base de acceso a datos en C# solo
        -- lee un result set por llamada. Reemplaza el uso de
        -- cci.ExtDescription (texto libre) como fuente de required_data
        -- -- ahora se arma en C# como [{name,type,description}]
        SELECT
            ccci.calif_id           AS [Id],
            cat.Name                AS [Name],
            cat.Type                AS [Type],
            cat.Description         AS [Description]
        FROM dbo.ccCalifCampIA AS ccci
        INNER JOIN dbo.ccDispositionExtractionData AS rel
            ON rel.calif_id = ccci.calif_id
        INNER JOIN dbo.ccExtractionDataCatalog AS cat
            ON cat.Id = rel.ExtractionDataId
        WHERE ccci.tipo = @CampType
        AND ccci.cam_id = @CampId
        AND cat.Active = 1
        ORDER BY ccci.calif_id
    END
END'
    exec (@sql)

    -- =====================================================================
    -- K070381 - Migrar cctipoCalif_IA a IDENTITY
    -- Motivo: la tabla se creo originalmente "Sin identity" (calif_id
    -- calculado a mano con MAX(calif_id)+1), y en algun punto de
    -- ServicesPack9 la SP dejo de calcularlo, provocando "Cannot insert
    -- the value NULL into column calif_id" al crear una calificacion IA
    -- nueva. Ademas, el calculo manual MAX+1 es una condicion de carrera
    -- real en un sistema concurrente (dos altas simultaneas pueden
    -- calcular el mismo id). Se resuelve pasando la columna a IDENTITY,
    -- que es atomico.
    --
    -- ADVERTENCIA - REPLICACION: cctipoCalif_IA puede ser articulo de
    -- replicacion (transaccional/snapshot) en instalaciones existentes.
    -- Este bloque ABORTA si detecta que la tabla sigue siendo articulo
    -- de una publicacion -- en ese caso, el despliegue de esta version
    -- DEBE ejecutarse con la opcion "Eliminar Replicas" activa en el
    -- instalador (installGroup.replicationRemove) antes de correr este
    -- script. La replica se debe volver a agregar y resincronizar
    -- despues (el instalador ya contempla este flujo para actualizaciones).
    -- =====================================================================

    SET @process = 'K070381 - Migrar cctipoCalif_IA a IDENTITY'

    IF EXISTS (
        SELECT 1 FROM sysarticles a
        INNER JOIN syspublications p ON a.pubid = p.pubid
        WHERE a.name = 'cctipoCalif_IA'
    )
    BEGIN
        RAISERROR('cctipoCalif_IA sigue siendo articulo de replicacion. Ejecutar el update con "Eliminar Replicas" activo en el instalador antes de aplicar este script.', 16, 1)
    END

    IF NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID('dbo.cctipoCalif_IA') AND name = 'calif_id' AND is_identity = 1
    )
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ccDispositionExtractionData_Calif')
            ALTER TABLE dbo.ccDispositionExtractionData DROP CONSTRAINT FK_ccDispositionExtractionData_Calif

        EXEC sp_rename 'dbo.cctipoCalif_IA', 'cctipoCalif_IA_old'
        EXEC sp_rename 'dbo.cctipoCalifIA', 'cctipoCalifIA_old', 'OBJECT'

        CREATE TABLE dbo.cctipoCalif_IA (
            calif_id smallint IDENTITY(1,1) NOT NULL,
            Name_cal varchar(150) NULL,
            Description_cal varchar(100) NULL,
            CanReprogram bit DEFAULT 0,
            autoCallback bit DEFAULT 0,
            ReturnCall smallint DEFAULT 0,
            Color varchar(15) NULL,
            AplTransfer bit DEFAULT 0,
            TransferOpcion smallint DEFAULT 0,
            DestinyIVR bit DEFAULT 0,
            DestinyIVR_camp smallint DEFAULT 0,
            DestinyIVR_number VARCHAR(20) NULL,
            DestinyIVR_directory smallint DEFAULT 0,
            AplExtDate bit DEFAULT 0,
            ExtDescription varchar(150) NULL,
            AplBlackList bit NULL,
            Cali_StatusIA bit NULL,
            DirectoryNumberFlag bit DEFAULT 1,
            CONSTRAINT cctipoCalifIA PRIMARY KEY CLUSTERED (calif_id)
        )

        SET IDENTITY_INSERT dbo.cctipoCalif_IA ON

        INSERT INTO dbo.cctipoCalif_IA (
            calif_id, Name_cal, Description_cal, CanReprogram, autoCallback, ReturnCall, Color,
            AplTransfer, TransferOpcion, DestinyIVR, DestinyIVR_camp, DestinyIVR_number,
            DestinyIVR_directory, AplExtDate, ExtDescription, AplBlackList, Cali_StatusIA, DirectoryNumberFlag
        )
        SELECT
            calif_id, Name_cal, Description_cal, CanReprogram, autoCallback, ReturnCall, Color,
            AplTransfer, TransferOpcion, DestinyIVR, DestinyIVR_camp, DestinyIVR_number,
            DestinyIVR_directory, AplExtDate, ExtDescription, AplBlackList, Cali_StatusIA, DirectoryNumberFlag
        FROM dbo.cctipoCalif_IA_old

        SET IDENTITY_INSERT dbo.cctipoCalif_IA OFF

        DECLARE @maxCalifId INT
        SELECT @maxCalifId = ISNULL(MAX(calif_id), 0) FROM dbo.cctipoCalif_IA
        DBCC CHECKIDENT ('dbo.cctipoCalif_IA', RESEED, @maxCalifId)

        ALTER TABLE dbo.ccDispositionExtractionData
            ADD CONSTRAINT FK_ccDispositionExtractionData_Calif FOREIGN KEY (calif_id)
            REFERENCES dbo.cctipoCalif_IA (calif_id)

        DROP TABLE dbo.cctipoCalif_IA_old
    END

    COMMIT TRAN

END TRY
BEGIN CATCH
    ROLLBACK TRAN
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
    RAISERROR('K070381 failed at process [%s]: %s', @ErrorSeverity, @ErrorState, @process, @ErrorMessage)
END CATCH
