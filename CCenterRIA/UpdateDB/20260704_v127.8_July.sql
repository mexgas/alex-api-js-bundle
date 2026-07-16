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

    -- =====================================================================
    -- Sprint6_finalPart (David Medina) - transferencias de entrada IA
    -- Guarda el id del agente virtual en ccCallsIn para que el StateMachine
    -- pueda leer la info del agente virtual al procesar la llamada de
    -- entrada (ya existia el equivalente de salida via ccoCallsOut.virtualAgentId).
    -- Se llama desde InBridgeAgentQuantumHelper (cw-service-telephony,
    -- rama demo/sprint6_finalpart). Confirmado vigente para Sprint 7 por
    -- David Medina (autor) el 2026-07-15 -- es independiente del rediseno
    -- de transferencias por calificacion, solo persiste el agente virtual.
    -- =====================================================================
    SET @process = 'Sprint6_finalPart - ALTER TABLE ccCallsIn ADD virtualAgentId'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''dbo.ccCallsIn'') AND name = ''virtualAgentId'')
    BEGIN
        ALTER TABLE dbo.ccCallsIn ADD virtualAgentId INT NULL
    END
    '
    exec (@sql)

    SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateVirtualAgentId si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateVirtualAgentId'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateVirtualAgentId
    '
    exec (@sql)

    SET @process = 'Sprint6_finalPart - CREATE ccsp_UpdateVirtualAgentId'
    SET @sql = '
CREATE PROCEDURE dbo.ccsp_UpdateVirtualAgentId
    @callId INT,
    @virtualAgentId INT
AS
BEGIN
    UPDATE dbo.ccCallsIn SET virtualAgentId = @virtualAgentId WHERE cal_id = @callId
END
'
    exec (@sql)

    -- =====================================================================
    -- K070334 - Fix mapeo ORM card "Resultados de Marcacion" (Dashboard IA Entrada)
    -- BD: CCenterRIA
    -- Causa raiz: ccsp_GalateaAdminInbound @Option=1 (query "Inbound.GetInboundCallsState")
    -- devolvia columnas (Calls, Answer, Abandon, OverflowedCalls, NoAgentsCalls,
    -- InterruptedCalls) con nombres distintos a las propiedades de
    -- InboundCallsStateDashboardDto (TotalCalls, Attended, Abandoned, TotalOverflow,
    -- NoLoggedInAgents, ShortDialogs, Assigned). Database.SqlQuery<T> de Entity
    -- Framework mapea por nombre de columna, no por posicion -- al no coincidir,
    -- casi todas las propiedades del DTO quedaban en su valor default (0), aunque
    -- el SP devolviera datos reales. Solo OutOfServiceCalls/OutOfScheduleCalls
    -- coincidian por casualidad de nombre.
    -- Fix: se renombran los alias de columnas de la rama @Option=1 (unica
    -- consumida por el codigo C#, confirmado sin otras referencias en el repo)
    -- para que coincidan exactamente con las propiedades del DTO, y se agrega
    -- Assigned (status=11, mismo criterio que @Option=3). Las demas ramas
    -- (@Option=2..10) quedan sin cambios.
    -- =====================================================================
    SET @process = 'K070334 - DROP ccsp_GalateaAdminInbound si existe (fix de alias @Option=1 para mapeo ORM InboundCallsStateDashboardDto)'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminInbound'')
    begin
            DROP PROCEDURE ccsp_GalateaAdminInbound;
    end'
    exec (@sql)

    SET @process = 'K070334 - CREATE ccsp_GalateaAdminInbound (alias @Option=1 corregidos: Calls->TotalCalls, Answer->Attended, Abandon->Abandoned, OverflowedCalls->TotalOverflow, NoAgentsCalls->NoLoggedInAgents, InterruptedCalls->ShortDialogs, agrega Assigned)'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT,
                                    @InboundId AS SMALLINT = 0,
                                    @User_id AS SMALLINT = 0,
                                    @OutboundID AS SMALLINT = 0,
                                    @multi_cam as varchar(max) = null,
                                    @Module AS SMALLINT = 13,
                                    @Type AS SMALLINT = 0,
                                    @HistoryAction AS SMALLINT = 1,
                                    @AreaId AS SMALLINT = 0,
                                    @NonComprehensionId AS SMALLINT = -1,
                                    @SuccessfulTransactionCampaignId AS SMALLINT = -1,
                                    @CallBackCampaignId AS SMALLINT = -1,
                                    @IsEditing AS BIT = 0
AS
BEGIN
    set nocount on;

    DECLARE @idArea SMALLINT = NULL;
    DECLARE @operation INT = -1;
    DECLARE @mediaType INT = 0;

    IF(@Option IN (5, 6)) BEGIN
        IF(@Module IS NOT NULL AND @Module <> 13) BEGIN

            IF(@Type = 0)BEGIN

                IF(@multi_cam is not null) BEGIN
                    SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'''')))
                END ELSE BEGIN
                    SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundId)
                END

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

                SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @OutboundID)

                SET @operation = CASE WHEN @HistoryAction = 1 THEN
                                                                    CASE
                                                                            WHEN @mediaType = 6  THEN 44
                                                                            WHEN @mediaType = 5  THEN 46
                                                                            WHEN @mediaType = 9  THEN 48
                                                                            WHEN @mediaType = 7  THEN 50
                                                                            ELSE 42 END
                                                               ELSE
                                                                    CASE
                                                                            WHEN @mediaType = 6  THEN 55
                                                                            WHEN @mediaType = 5  THEN 56
                                                                            WHEN @mediaType = 9  THEN 57
                                                                            WHEN @mediaType = 7  THEN 58
                                                                            ELSE 54 END
                                                                END;
            END

        END ELSE BEGIN
            SET @operation = CASE WHEN @Option = 5 THEN 93 ELSE 94 END;
        END
    END

    if(@Option = 1) -- To campaign (K070334 - alias renombrados para coincidir con InboundCallsStateDashboardDto)
    begin
        select
            ISNULL(count (*), 0) as TotalCalls,
            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Attended,
            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandoned,
            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as TotalOverflow,
            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoLoggedInAgents, -- sin agentes firmados
            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as ShortDialogs,
            ISNULL(count (case when statusCall_id = 11 then 1 else null end), 0) as Assigned
        from ccCallsIn a (nolock)
        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

    end

    if(@Option = 2) -- All campaigns
    begin
        select
            inbound.Inbound_id as IDEspec,
            inbound.descripcion as Name,
            ISNULL(count (*), 0) as Calls,
            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5)
            THEN 1 ELSE NULL END), 0) AS Other
        from ccCallsIn a (nolock)
        left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
        group by inbound.Inbound_id, inbound.descripcion
    end

    if(@Option = 3) -- Get All ACD call data, the data is showing in the administrator dashboard information
    begin
        SELECT
            a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
            Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
            DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
            QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
            abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
            OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
            OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
            outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
            outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
            noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
            assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
            callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
        FROM ccCallsIn a (nolock)
        WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
        GROUP BY a.inbound_id
    end

    if(@Option = 4) -- Load ACD of administrator that sent
    begin
        SELECT cam_id
        FROM ccSupervisorCam  nolock
        WHERE user_id = @User_id and tipo = 0
        SET nocount off
        return(0)
    end

    IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
    BEGIN
        IF(@idArea IS NULL OR @idArea = -1) SET @idArea =
            CASE WHEN @Type = 0
                THEN
                    CASE WHEN @multi_cam IS NULL
                        THEN (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)
                        ELSE (SELECT [IDArea] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'''')))
                        END
                ELSE (SELECT [IDArea] FROM ccCamps WHERE cam_id = @OutboundID)
                END

        IF(@multi_cam is not null)
        BEGIN
            UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
                SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,''''))

            IF (@multi_cam <> '''' )
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                getDate(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @User_id),
                @operation,
                @Module,
                CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
                CASE WHEN @Type = 0 THEN
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
                                    ELSE
                                        (SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'''')))
                                    END,
                CASE WHEN @Type = 0 THEN
                                        (SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'''')))
                                    ELSE
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
                                    END

            SELECT 1;
            RETURN 1;
        END
        IF((SELECT ISNULL(cam_id,0) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId and chat in (0,11)) != 0 )
            BEGIN
                SELECT -1;
                RETURN -1;
            END;
        ELSE
            BEGIN
                UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;

                IF(@Type <> 1 AND @InboundID <> 0)
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                SELECT
                    (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                    getDate(),
                    (SELECT [Login] FROM ccUsers WHERE User_id = @User_id),
                    @operation,
                    @Module,
                    CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
                    (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

                SELECT 1;
                RETURN 1;
            END;
    END;
    IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
    BEGIN

    IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @User_id),
            @operation,
            @Module,
            CASE WHEN @Module = 13 THEN '''' ELSE ''DISASSOCIATED_CAMP_CALLBACK'' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
            (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

        UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
        SELECT 1;
        RETURN 1;
    END;
    IF(@Option = 7) -- Check if the inbound Campaign is related
    BEGIN
        SELECT CAST(CASE WHEN cam_id IS NULL OR cam_id = 0 THEN -1 ELSE cam_id END AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
    END
    IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
    BEGIN
        UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
        SELECT 1;
        RETURN 1;
    END
    IF(@Option = 9)
    BEGIN

        SET @Module = 3 --Corresponds to "Area", reference in ccGalateaModules
        SET @operation = CASE @IsEditing WHEN 1 THEN 138 ELSE 137 END -- Corresponds to edition and creation, reference ccGalateaOperations

        DECLARE @CurrentNonComprehensionId SMALLINT,
                @CurrentCallbackId SMALLINT,
                @CurrentSuccessfullTransactionId SMALLINT,
                @UserName VARCHAR(40),
                @AreaName VARCHAR(50),
                @CampaignName VARCHAR(40)

        SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
        SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

        SELECT
            @CurrentNonComprehensionId = ISNULL( idForNonComprehension , -1 ),
            @CurrentCallbackId = ISNULL( cam_id, -1 ),
            @CurrentSuccessfullTransactionId = ISNULL( idForSuccessfulTransaction, -1),
            @CampaignName = descripcion
        FROM ccInbound WHERE Inbound_id = @InboundId

        IF @CurrentCallbackId <> @CallBackCampaignId AND @CallBackCampaignId <> -1
        BEGIN
            UPDATE ccInbound
            SET cam_id = @CallBackCampaignId
            WHERE Inbound_id = @InboundId

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@AreaName,
                    GETDATE(),
                    @UserName,
                    @operation,
                    @Module,
                    ''ASSOCIATED_CAMP_CALLBACK'',
                    CASE @CallBackCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT cam_descripcion FROM ccCamps WHERE cam_id = @CallBackCampaignId) END,
                    @CampaignName)
        END

        IF @CurrentNonComprehensionId <> @NonComprehensionId AND @NonComprehensionId <> -1
        BEGIN
            UPDATE ccInbound
            SET idForNonComprehension = @NonComprehensionId
            WHERE Inbound_id = @InboundId

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@AreaName,
                    GETDATE(),
                    @UserName,
                    @operation,
                    @Module,
                    ''ASSOCIATED_CAMP_XFER_IA'',
                    CASE @NonComprehensionId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @NonComprehensionId) END,
                    @CampaignName)
        END

        IF @CurrentSuccessfullTransactionId <> @SuccessfulTransactionCampaignId AND @SuccessfulTransactionCampaignId <> -1
        BEGIN
            UPDATE ccInbound
            SET idForSuccessfulTransaction = @SuccessfulTransactionCampaignId
            WHERE Inbound_id = @InboundId

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@AreaName,
                    GETDATE(),
                    @UserName,
                    @operation,
                    @Module,
                    ''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'',
                    CASE @SuccessfulTransactionCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @SuccessfulTransactionCampaignId) END,
                    @CampaignName)
        END

        SELECT 1
    END
    IF(@Option = 10) -- Get Dispositions Not Assigned To Inbound IA  Campaign
    BEGIN
        SELECT CAST(calif_id AS INT) AS calif_id
            FROM cctipoCalif_IA MAIN
            WHERE MAIN.Cali_StatusIA = 1
            AND EXISTS (
                SELECT 1
                FROM ccInbound I
                WHERE I.Inbound_id = @InboundId
                AND (
                    (
                       (MAIN.CanReprogram = 1 OR MAIN.autoCallback = 1)
                       AND
                       (I.cam_id IS NULL OR I.cam_id = 0)
                    )

                    OR
                    (
                        MAIN.AplTransfer = 1
                        AND (
                            (MAIN.TransferOpcion = 1
                            AND (I.idForNonComprehension IS NULL OR I.idForNonComprehension = 0))

                            OR

                            (MAIN.TransferOpcion = 2 AND
                            (I.idForSuccessfulTransaction IS NULL OR I.idForSuccessfulTransaction = 0))
                        )
                    )
                )
            )
    END
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
