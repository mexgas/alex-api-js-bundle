/*******************************/
/*******************************/
/*
Author: Equipo Galatea
Date: 2026/07/04
Description: July Release - K070177 (Dashboard Campana IA de Entrada) + K070381 (Extraccion de datos en Calificaciones IA)
Database: CCenterRia
Required version: 127.7
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
USE CCenterRIA;

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

    -- =====================================================================
    -- K070177 - Calificaciones de campana de llamadas de entrada (IA) en Dashboard
    -- BD: CCenterRIA
    -- Cambios:
    --   1. SP ccsp_GalateaGetCalifDayIA: conteo del dia de calificaciones
    --      puestas por agentes virtuales en campanas IA de entrada, para la
    --      card "Calificaciones" del Dashboard (grafica de pastel + desglose).
    -- Notas:
    --   - Devuelve TODAS las calificaciones configuradas en la campana
    --     (ccCalifCampIA) aunque tengan 0 usos, para que la card muestre el
    --     catalogo completo.
    --   - Fila con CalificationId = 0 representa "Sin calificacion":
    --     llamadas atendidas (statusCall_id = 13) del dia sin calificacion.
    --     El front traduce la etiqueta (ES/EN/PT).
    --   - Registros con calificacion cuentan sin filtrar status (una llamada
    --     reencolada/abandonada puede conservar la calif del agente virtual).
    --   - Porcentajes se calculan en el front.
    -- =====================================================================
    SET @process = 'K070177 - DROP ccsp_GalateaGetCalifDayIA'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetCalifDayIA'')
    begin
            DROP PROCEDURE ccsp_GalateaGetCalifDayIA;
    end'
    exec (@sql)

    SET @process = 'K070177 - CREATE ccsp_GalateaGetCalifDayIA'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaGetCalifDayIA]
    @InboundId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today DATETIME = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 101));

    SELECT
        cat.calif_id                       AS CalificationId,
        cat.Name_cal                       AS Calification,
        ISNULL(cat.Color, '''')            AS GraphColor,
        ISNULL(cnt.Total, 0)               AS Total
    FROM ccCalifCampIA rel WITH (NOLOCK)
    INNER JOIN cctipoCalif_IA cat WITH (NOLOCK)
        ON cat.calif_id = rel.calif_id
    LEFT JOIN (
        SELECT calif_id, COUNT(*) AS Total
        FROM ccCallsIn WITH (NOLOCK)
        WHERE cal_Inicio > @today
          AND Inbound_id = @InboundId
          AND ISNULL(calif_id, 0) > 0
        GROUP BY calif_id
    ) cnt ON cnt.calif_id = cat.calif_id
    WHERE rel.cam_id = @InboundId
      AND rel.tipo = 0

    UNION ALL

    SELECT
        CAST(0 AS SMALLINT)                AS CalificationId,
        ''systemTranslated_NoDisposition'' AS Calification,
        ''''                               AS GraphColor,
        COUNT(*)                           AS Total
    FROM ccCallsIn WITH (NOLOCK)
    WHERE cal_Inicio > @today
      AND Inbound_id = @InboundId
      AND statusCall_id = 13
      AND ISNULL(calif_id, 0) = 0
END
'
    exec (@sql)

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
    --      documentado por Quantum) como fuente de required_data.
    --   6. ALTER ccsp_ManageQuantumDispositions: se agrega Action=7, que
    --      devuelve los items de extraccion requeridos por calificacion
    --      para toda la campana, para que la capa de aplicacion arme
    --      required_data: [{name,type,description}] al sincronizar con
    --      Quantum.
    --   7. Migracion de cctipoCalif_IA a IDENTITY (ver detalle abajo).
    -- Notas:
    --   - Sin FOR JSON / OPENJSON (SQL Server 2012): el JSON de
    --     required_data se arma en C#.
    --   - Type en catalogo: 0=Numero, 1=Texto, 2=Fecha.
    -- =====================================================================
    SET @process = 'K070381 - CREATE TABLE ccExtractionDataCatalog'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccExtractionDataCatalog'')
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
'
    exec (@sql)

    SET @process = 'K070381 - CREATE TABLE ccDispositionExtractionData'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccDispositionExtractionData'')
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
'
    exec (@sql)

    SET @process = 'K070381 - DROP ccsp_GalateaAdminExtractionDataCatalog'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminExtractionDataCatalog'')
    begin
            DROP PROCEDURE ccsp_GalateaAdminExtractionDataCatalog;
    end'
    exec (@sql)

    SET @process = 'K070381 - CREATE ccsp_GalateaAdminExtractionDataCatalog'
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
END
'
    exec (@sql)

    SET @process = 'K070381 - DROP ccsp_GalateaAdminDispositionExtractionData'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositionExtractionData'')
    begin
            DROP PROCEDURE ccsp_GalateaAdminDispositionExtractionData;
    end'
    exec (@sql)

    SET @process = 'K070381 - CREATE ccsp_GalateaAdminDispositionExtractionData'
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
END
'
    exec (@sql)

    SET @process = 'K070381 - ALTER ccsp_ManageQuantumDispositions (Action=3 fix + Action=7 extraction data, preservando limpieza de Marco/K070405: sin Action=5, Transfer via ccCalif_IA_TransferConfig)'
    SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
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
        -- Result set 1: cabecera de disposiciones (sin ExtDescription -- K070381).
        -- Transfer usa dbo.ccCalif_IA_TransferConfig (K070405, ya vigente en produccion),
        -- no AplTransfer solo -- mantener alineado con el SP que Marco ya desplego.
        SELECT
            cci.calif_id AS [Id],
        cci.Name_cal AS [Name],
        cci.Description_cal AS [Description],
        CAST(CASE WHEN cci.CanReprogram = 1 OR cci.autoCallback = 1 THEN 1 ELSE 0 END AS INT) AS Callback,
        CAST(
            CASE
                WHEN cci.AplTransfer = 1 AND EXISTS (
                    SELECT 1
                    FROM dbo.ccCalif_IA_TransferConfig AS ccitc
                    WHERE ccitc.DispositionId = cci.calif_id
                      AND (
                          NULLIF(ccitc.DestinationNumber, '''') IS NOT NULL
                          OR ISNULL(ccitc.DestinationCampId, 0) > 0
                          OR ISNULL(ccitc.DestinationDirectoryId, 0) > 0
                      )
                ) THEN 1
                ELSE 0
            END
        AS INT) AS Transfer
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
END
'
    exec (@sql)

    -- =====================================================================
    -- K070381 - Migrar cctipoCalif_IA a IDENTITY
    -- Motivo: la tabla se creo originalmente "Sin identity" (calif_id
    -- calculado a mano con MAX(calif_id)+1), y en algun punto de
    -- ServicesPack9 la SP dejo de calcularlo, provocando "Cannot insert
    -- the value NULL into column calif_id" al crear una calificacion IA
    -- nueva. Ademas, el calculo manual MAX+1 es una condicion de carrera
    -- real en un sistema concurrente. Se resuelve pasando la columna a
    -- IDENTITY, que es atomico.
    --
    -- ADVERTENCIA - REPLICACION: cctipoCalif_IA puede ser articulo de
    -- replicacion (transaccional/snapshot) en instalaciones existentes.
    -- Este bloque ABORTA si detecta que la tabla sigue siendo articulo
    -- de una publicacion -- en ese caso, el despliegue de esta version
    -- DEBE ejecutarse con la opcion "Eliminar Replicas" activa en el
    -- instalador (installGroup.replicationRemove) antes de correr este
    -- script.
    -- =====================================================================
    SET @process = 'K070381 - Migrar cctipoCalif_IA a IDENTITY'
    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''dbo.cctipoCalif_IA'') AND name = ''calif_id'' AND is_identity = 1
    )
    BEGIN
        IF EXISTS (
            SELECT 1 FROM sysarticles a
            INNER JOIN syspublications p ON a.pubid = p.pubid
            WHERE a.name = ''cctipoCalif_IA''
        )
        BEGIN
            RAISERROR(''cctipoCalif_IA sigue siendo articulo de replicacion. Ejecutar el update con "Eliminar Replicas" activo en el instalador antes de aplicar este script.'', 16, 1)
        END
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = ''FK_ccDispositionExtractionData_Calif'')
            ALTER TABLE dbo.ccDispositionExtractionData DROP CONSTRAINT FK_ccDispositionExtractionData_Calif

        EXEC sp_rename ''dbo.cctipoCalif_IA'', ''cctipoCalif_IA_old''
        EXEC sp_rename ''dbo.cctipoCalifIA'', ''cctipoCalifIA_old'', ''OBJECT''

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
        DBCC CHECKIDENT (''dbo.cctipoCalif_IA'', RESEED, @maxCalifId)

        ALTER TABLE dbo.ccDispositionExtractionData
            ADD CONSTRAINT FK_ccDispositionExtractionData_Calif FOREIGN KEY (calif_id)
            REFERENCES dbo.cctipoCalif_IA (calif_id)

        DROP TABLE dbo.cctipoCalif_IA_old
    END
'
    exec (@sql)

    SET @process = 'K070300 - CREATE TABLE ccLogTransfers_IA (captura de transferencias IA para reporte de Agentes Virtuales)'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccLogTransfers_IA'')
    BEGIN
        CREATE TABLE dbo.ccLogTransfers_IA (
            cal_id INT NOT NULL,
            tipo TINYINT NOT NULL,
            modo TINYINT NOT NULL,
            destino VARCHAR(50) NULL,
            tAntesXfer INT NULL,
            tDespuesXfer INT NULL,
            fechaFin DATETIME NOT NULL,
            pbxId TINYINT NULL,
            channel INT NULL,
            tipoLlamada_id SMALLINT NULL,
            callerAni VARCHAR(50) NULL,
            replkey UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ccLogTransfers_IA_replkey DEFAULT (NEWSEQUENTIALID()),
            destination VARCHAR(50) NULL,
            destination_name VARCHAR(50) NULL,
            rowguid UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL CONSTRAINT DF_ccLogTransfers_IA_rowguid DEFAULT (NEWSEQUENTIALID()),
            CONSTRAINT PK_ccLogTransfers_IA PRIMARY KEY CLUSTERED (cal_id, tipo)
        )
    END

    IF OBJECT_ID(''dbo.ccsp_InsertLogTransfers_IA'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_InsertLogTransfers_IA
    '
    exec (@sql)

    SET @process = 'K070300 - CREATE ccsp_InsertLogTransfers_IA'
    SET @sql = '
CREATE PROCEDURE dbo.ccsp_InsertLogTransfers_IA
    @cal_id INT,
    @tipo TINYINT,
    @modo TINYINT,
    @fechaFin DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ccLogTransfers_IA (cal_id, tipo, modo, fechaFin)
    VALUES (@cal_id, @tipo, @modo, @fechaFin);
END
'
    exec (@sql)

    SET @process = 'KM28005 - DROP ccsp_ValidateZipCodeCampSchedule si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_ValidateZipCodeCampSchedule'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_ValidateZipCodeCampSchedule
    '
    exec (@sql)

    SET @process = 'KM28005 - CREATE ccsp_ValidateZipCodeCampSchedule (valida CP contra horario real de campana, CW-11164/CW-11166)'
    SET @sql = '
CREATE PROCEDURE dbo.ccsp_ValidateZipCodeCampSchedule
    @campId  INT,
    @zipCode NVARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @offset INT;
    SELECT @offset = WinterTimeDifference
    FROM ccTimeZoneAreaCP
    WHERE ZipCode = @zipCode;

    IF @offset IS NULL
    BEGIN
        SELECT CAST(1 AS BIT) AS IsAllowed;
        RETURN;
    END

    SET DATEFIRST 1;

    DECLARE @utcNow DATETIME = GETUTCDATE();
    DECLARE @localTime DATETIME = DATEADD(HOUR, @offset, @utcNow);
    DECLARE @h  INT = DATEPART(HH, @localTime);
    DECLARE @m  INT = DATEPART(MI, @localTime);
    DECLARE @dw INT = DATEPART(DW, @localTime);

    SELECT CAST(
        CASE WHEN EXISTS (
            SELECT 1
            FROM ccHorarios h
            INNER JOIN ccCampsHorarios ch ON h.horario_id = ch.Horario_id
            WHERE ch.cam_id = @campId
              AND ( @h > h.HoraInicio OR (@h = h.HoraInicio AND @m >= h.MinInicio) )
              AND ( @h < h.HoraFin    OR (@h = h.HoraFin    AND @m <= h.MinFin)    )
              AND (
                    (@dw = 1 AND h.Lunes     = 1) OR
                    (@dw = 2 AND h.Martes    = 1) OR
                    (@dw = 3 AND h.Miercoles = 1) OR
                    (@dw = 4 AND h.Jueves    = 1) OR
                    (@dw = 5 AND h.Viernes   = 1) OR
                    (@dw = 6 AND h.Sabado    = 1) OR
                    (@dw = 7 AND h.Domingo   = 1)
              )
        ) THEN 1 ELSE 0 END
    AS BIT) AS IsAllowed;
END
'
    exec (@sql)

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
