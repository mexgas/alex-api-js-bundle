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

	---- =============================================================================== ----- 
	----SPRINT6FINALPART CREACIÓN 7 EDICIÓN / MODIFICACIÓN DE TABLAS E INSERCIÓN DE REGISTROS A CATALOGOS -----
	 SET @process = 'KM28003 - CREATE TABLE ccoCallsOutSource_ZipCode TO CALLS'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccoCallsOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
		BEGIN
			CREATE TABLE dbo.ccoCallsOutSource_ZipCode (
				callout_id INT NOT NULL, 
        
				zipCode VARCHAR(10) DEFAULT(''''),
				isZipCodeValidation BIT DEFAULT(0)
        
				CONSTRAINT PK_ccoCallsOutSource_ZipCode PRIMARY KEY CLUSTERED (callout_id),
				CONSTRAINT FK_ccoCallsOutSource_ZipCode_Main FOREIGN KEY (callout_id) 
					REFERENCES dbo.ccoCallsOutSource(callout_id) ON DELETE CASCADE
			);

			CREATE INDEX IX_ccoCallsOutSource_ZipCode_Zip1 ON dbo.ccoCallsOutSource_ZipCode(zipCode);
		END'
    exec (@sql)

	SET @process = 'KM28003 - CREATE TABLE ccWhatsAppOutSource_ZipCode TO whatsapp'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccWhatsAppOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
	BEGIN
		CREATE TABLE dbo.ccWhatsAppOutSource_ZipCode (
			WAOut_Id BIGINT NOT NULL, 
			zipCode VARCHAR(10) DEFAULT(''''),
			isZipCodeValidation BIT DEFAULT(0),
        
			CONSTRAINT PK_ccWhatsAppOutSource_ZipCode PRIMARY KEY CLUSTERED (WAOut_Id),
			CONSTRAINT FK_ccWhatsAppOutSource_ZipCode_Main FOREIGN KEY (WAOut_Id) 
				REFERENCES dbo.ccWhatsAppOutSource(WAOut_Id) ON DELETE CASCADE
		);
	END'
    exec (@sql)

		SET @process = 'KM28003 - CREATE TABLE smsOutSource_ZipCode TO sms'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''smsOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
		BEGIN
			CREATE TABLE dbo.smsOutSource_ZipCode (
				smsout_id INT NOT NULL, 
				zipCode VARCHAR(10) DEFAULT(''''),
				isZipCodeValidation BIT DEFAULT(0),
        
				CONSTRAINT PK_smsOutSource_ZipCode PRIMARY KEY CLUSTERED (smsout_id),
				CONSTRAINT FK_smsOutSource_ZipCode_Main FOREIGN KEY (smsout_id) 
					REFERENCES dbo.smsOutSource(smsout_id) ON DELETE CASCADE
			);
		END'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone from ccWhatsAppOutSource table'
    SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''dbo.ccWhatsAppOutSource'') AND name = ''TimeZone''
		)
		BEGIN
			ALTER TABLE ccWhatsAppOutSource 
			ALTER COLUMN TimeZone INT NULL;
		END;'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone_Summer from ccWhatsAppOutSource table'
    SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''dbo.ccWhatsAppOutSource'') AND name = ''TimeZone_Summer''
		)
		BEGIN
			ALTER TABLE ccWhatsAppOutSource 
			ALTER COLUMN TimeZone_Summer INT NULL;
		END;'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone from ccoWAWorkingTable table'
    SET @sql = 'IF EXISTS (
				SELECT 1 FROM sys.columns 
				WHERE object_id = OBJECT_ID(''dbo.ccoWAWorkingTable'') AND name = ''TimeZone''
			)
			BEGIN
				ALTER TABLE dbo.ccoWAWorkingTable 
				ALTER COLUMN TimeZone INT NULL;
			END;'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone_Summer from ccoWAWorkingTable table'
    SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''dbo.ccoWAWorkingTable'') AND name = ''TimeZone_Summer''
		)
		BEGIN
			ALTER TABLE ccoWAWorkingTable 
			ALTER COLUMN TimeZone_Summer INT NULL;
		END;'
    exec (@sql)

	 SET @process = 'KM28003 drop function fnGetTimeZoneByZip'
        SET @Sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''fnGetTimeZoneByZip'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
		begin
			Drop function fnGetTimeZoneByZip
		end'
        EXEC (@Sql)
		SET @process = 'KM28003 CREATE function fnGetTimeZoneByZip'
		SET @sql = 'CREATE FUNCTION [dbo].[fnGetTimeZoneByZip]
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
				v.tz_id   AS tz_id_verano,
				z.State
			FROM ccTimeZoneAreaCP AS z WITH (NOLOCK)
			INNER JOIN ccTimeZones AS inv
				ON inv.tz_offset = z.WinterTimeDifference
			INNER JOIN ccTimeZones AS v
				ON v.tz_offset   = z.SummerTimeDifference
			WHERE z.ZipCode = @zipCode
		);';
		EXEC(@sql);


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

	 -- =============================================================================
    -- Sprint 6 final part (Marco García, David Medina) - Transferencia de salida IA y transferencia de entrada IA
    -- Se agregaron los action 5 , 6 y 7, para obtener la información del agente virtual 
    -- y la transcripción de la llamada.
    -- el state machine consulta esa información, para poder mostrarla en la UI 
    -- =============================================================================
    SET @process = 'Sprint6_finalPart - DROP SaveDispositionsAI si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.SaveDispositionsAI'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.SaveDispositionsAI
    '
    exec (@sql)

        SET @process = 'Sprint6_finalPart - CREATE SaveDispositionsAI'
        SET @sql = '
        CREATE PROCEDURE [dbo].[SaveDispositionsAI]
        @action        smallint    = NULL,
        @call_Id       int         = NULL,
        @Qualification varchar(MAX)= NULL,
        @result        varchar(MAX)= NULL,
        @Observations  varchar(MAX)= NULL,
        @CallbackAT    DATETIME = NULL,
        @Transcription varchar(MAX)= NULL,
        @CamType       bit         = 0,
        @disposition_Id SMALLINT = null,
        @CapturedData varchar(max) = null
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
            declare @name_cal varchar(150) = '''';

            SET @sep = CHARINDEX(''|'', ISNULL(@valor, ''''));
            SET @status = CASE
                            WHEN @sep > 0 THEN SUBSTRING(@valor, 1, @sep - 1)
                            ELSE ISNULL(@valor, '''')
                          END;

            IF @action = 1  -- Outbound
            BEGIN
                select @name_cal = isnull(Name_cal, ''N/A'') from cctipoCalif_IA where Description_cal = @Qualification
                IF EXISTS (SELECT 1 FROM ccoCallsOutDispositionIA WHERE call_id = @call_Id)
                BEGIN
                    UPDATE ccoCallsOutDispositionIA
                    SET Qualification = @Qualification,
                        name_cal = @name_cal,
                        result = @result,
                        Observations = @Observations,
                        CapturedData = @CapturedData
                    WHERE call_id = @call_Id;
                END
                ELSE
                BEGIN
                    INSERT INTO ccoCallsOutDispositionIA (call_id, name_cal, Qualification, result, Observations,CapturedData)
                    VALUES (@call_Id, @name_cal, @Qualification, @result, @Observations,@CapturedData);
                END

                IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA AS cci WHERE cci.calif_id = @disposition_Id)
                BEGIN
                    UPDATE dbo.ccoCallsOut 
                    SET calif_id = @disposition_Id
                    WHERE cal_id = @call_Id;
                END
            END

            ELSE IF @action = 2 AND @status = ''1''   -- Outbound
            BEGIN
                Select @cam_id = cam_id
                From ccoCallsOut
                Where cal_id = @call_Id

                Select @trans_status = IsCallTranscriptionEnabled
                From ccCampsExtend
                Where cam_id  = @cam_id
            
                if  @trans_status = 1 BEGIN

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
            END

            ELSE IF @action = 3  -- Inbound
            BEGIN
                Select @CanReprogram = CanReprogram from dbo.cctipoCalif_IA  where calif_id = @disposition_Id
                
                IF (@CallbackAT IS NOT NULL  
                    AND CONVERT(datetime, @CallbackAT, 120) IS NOT NULL 
                    AND CONVERT(datetime, @CallbackAT, 120) > GETDATE()  
                    AND @CanReprogram <> 0)
                BEGIN
                    INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations, CallbackAT,disposition_id,CapturedData)
                    VALUES (@call_Id, @Qualification, @result, @Observations,@CallbackAT,@disposition_Id,@CapturedData);

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

                    IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA WHERE calif_id = @disposition_Id)
                    BEGIN
                        UPDATE ccCallsIn
                        SET calif_id = @disposition_Id
                        WHERE cal_id = @call_Id;
                    END
                END

                ELSE BEGIN
                    INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations,disposition_id,CapturedData)
                    VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id,@CapturedData);

                    IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA WHERE calif_id = @disposition_Id)
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

            ELSE IF @action = 5 -- Get ia call transcription by callId  
            BEGIN
                IF(@CamType = 1)
                BEGIN
                    SELECT ccoti.call_id AS CallId ,
                           ccoti.Transcription,
                           ISNULL(ccodi.disposition_id, 0) AS DispositionID ,
                           ISNULL(ccodi.Qualification, '''') AS Qualification,
                           ccodi.result AS DispositionResult
                           FROM dbo.ccoCallsOutTranscriptionIA AS ccoti
                           INNER JOIN dbo.ccoCallsOutDispositionIA AS ccodi
                           ON ccodi.call_id = ccoti.call_id 
                    WHERE ccoti.call_id = @call_Id
                END
                ELSE
                BEGIN
                    SELECT cciti.call_id AS CallId,
                           cciti.Transcription,
                           ISNULL(ccidi.disposition_id, 0) AS DispositionID ,
                           ISNULL(ccidi.Qualification, '''') AS Qualification,
                           ccidi.result AS DispositionResult
                           FROM dbo.ccCallsInTranscriptionIA AS cciti
                           INNER JOIN dbo.ccCallsInDispositionIA AS ccidi  
                           ON ccidi.call_id = cciti.call_id 
                    WHERE cciti.call_id = @call_Id
                END
            END

            ELSE IF @action = 6 -- Get IA Call Model by call_id
            BEGIN
                IF(@CamType = 1)
                BEGIN
                    SELECT cva.idAgent AS IdAgent, cva.nameAgent AS NameAgent FROM dbo.ccoCallsOut AS cco
                    INNER JOIN dbo.ccVirtualAgent AS cva
                    ON cco.virtualAgentId = cva.idAgent
                    WHERE cco.cal_id = @call_Id
                END
                ELSE 
                BEGIN
                    select cva.idAgent AS IdAgent, cva.nameAgent AS NameAgent FROM dbo.ccCallsIn AS cci
                    INNER JOIN dbo.ccVirtualAgent AS cva
                    ON cci.virtualAgentId = cva.idAgent
                    WHERE cci.cal_id = @call_Id
                END 
            END

        ELSE IF @action = 7 -- Verify if IA data is completely saved (Retry Pattern Flag)
            BEGIN
                DECLARE @IsDataReady BIT = 0;

                IF(@CamType = 1)
                BEGIN
                    IF EXISTS (SELECT 1 FROM dbo.ccoCallsOutDispositionIA WHERE call_id = @call_Id)
                    BEGIN
                        SET @IsDataReady = 1;
                    END
                END
                ELSE
                BEGIN
                    IF EXISTS (SELECT 1 FROM dbo.ccCallsInDispositionIA WHERE call_id = @call_Id)
                    BEGIN
                        SET @IsDataReady = 1;
                    END
                END

                -- Retornamos el flag
                SELECT @IsDataReady AS IsDataReady;
            END
        END'
        exec (@sql)

		 -- =============================================================================
    -- Sprint 6 final part (Marco García) Carga de base de datos para campañas de salida
	-- validar el código postal cuando se realiza la carga si el check esta seleccionad
	-- deberia de validar el código postal que se ingrese en el dropdown
	-- de igual forma guardar los mensajes de validación cuando el código postal esta mal
	--estos cambios son para la HU KM28003 y KM28004
    -- =============================================================================
    SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateCallsOutFromTempAction si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateCallsOutFromTempAction'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateCallsOutFromTempAction
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
		@action INT,
		@tableName NVARCHAR(255),
		@cal_status int = 0,
		@idLoad int=0,
		@motivo varchar(50)=null,
		@cam_id int=null,
		@isIAQuantumCamp bit =0,
		@internationalRecords int=0,
		@isZipCodeValidation BIT = 0

	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @sql NVARCHAR(MAX);
		DECLARE @paramDef NVARCHAR(300);    
		DECLARE @count INT;
		declare @empty varchar(1)='''',@zipCodeSchedule bit = 0;
		declare @columnsIAQuntum varchar(max)='''' , @columnsZipCode varchar(max)='''', @valuesColumnsZipCode varchar(max)='''';  

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
			END

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
			WHERE callout_id = 0;'';

			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = '', zipCode, isZipCodeValidation''
				SET @valuesColumnsZipCode = '', T.cal_zipCodeValidation, '' +CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				INSERT INTO dbo.ccoCallsOutSource_ZipCode (callout_id '' + @columnsZipCode  + '')
				SELECT 
					C.callout_id
					'' + @valuesColumnsZipCode  + ''
				FROM '' + QUOTENAME(@tableName) + '' AS T
				INNER JOIN dbo.ccoCallsOutSource AS C WITH (NOLOCK)
					ON T.cal_Key = C.cal_Key 
					AND T.cam_id = C.cam_id
				WHERE T.callout_id = 0 
				  AND T.cal_zipCodeValidation IS NOT NULL 
				  AND T.cal_zipCodeValidation <> '''''''';'';
			END

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
			END

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
				C.recycledByResult = @empty,
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
			INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id;'';

			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = ''Z.zipCode = A.cal_zipCodeValidation, Z.isZipCodeValidation = '' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				UPDATE Z SET 
					'' + @columnsZipCode + ''
				FROM '' + QUOTENAME(@tableName) + '' A
				LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
				INNER JOIN dbo.ccoCallsOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.callout_id = Z.callout_id;

				INSERT INTO dbo.ccoCallsOutSource_ZipCode (callout_id, zipCode, isZipCodeValidation)
				SELECT A.callout_id, A.cal_zipCodeValidation, 1
				FROM '' + QUOTENAME(@tableName) + '' A
				WHERE A.callout_id > 0 
				  AND A.cal_zipCodeValidation IS NOT NULL 
				  AND A.cal_zipCodeValidation <> ''''''''
				  AND NOT EXISTS (SELECT 1 FROM dbo.ccoCallsOutSource_ZipCode Z WHERE Z.callout_id = A.callout_id);'';
			END
			
			SET @paramDef = N''@cal_status_param TINYINT, @empty varchar(1)'';
			EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @empty= @empty;
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

		WHILE 1 = 1
		BEGIN
		    ;WITH cte AS
		    (
		        SELECT TOP (200) ld.logDial_id
		        FROM '' + QUOTENAME(@tableName) + '' t
		        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		        INNER JOIN ccoLogDials ld WITH (UPDLOCK) ON ld.callout_id = t.callout_id
		        WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled = 1 OR ld.canBeRecycled IS NULL)
				ORDER BY ld.logDial_id
		    )
		    UPDATE ld
		    SET ld.canBeRecycled = 0
		    FROM ccoLogDials ld
		    INNER JOIN cte x
		        ON ld.logDial_id = x.logDial_id;

		    IF @@ROWCOUNT = 0 BREAK;

			WAITFOR DELAY ''''00:00:00.05'''';
		END


		WHILE 1 = 1
		BEGIN
		    ;WITH cte AS
		    (
		        SELECT TOP (200) co.cal_id
		        FROM '' + QUOTENAME(@tableName) + '' t
		        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		        INNER JOIN ccoCallsOut co WITH (UPDLOCK) ON co.callout_id = t.callout_id
		        WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled = 1 OR co.canBeRecycled IS NULL)
				ORDER BY co.cal_id
		    )
		    UPDATE co
		    SET co.canBeRecycled = 0
		    FROM ccoCallsOut co
		    INNER JOIN cte x
		        ON co.cal_id = x.cal_id;

		    IF @@ROWCOUNT = 0 BREAK;

			WAITFOR DELAY ''''00:00:00.05'''';
		END

			'';
			--print(@sql)
    --EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
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
			SELECT @idLoad, A.cal_Key, @empty, 2, @motivo,@internationalRecords
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC sp_executesql @sql,
				N''@idLoad INT, @motivo NVARCHAR(200),@empty varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@empty=@empty;

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
			SELECT @idLoad, cal_Key, @empty, 6, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

			EXEC sp_executesql @sql,
					N''@idLoad INT, @motivo NVARCHAR(200),@empty varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@empty=@empty;

			-- Eliminar todos los registros de la tabla temporal
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
			EXEC(@sql);

			-- Retornar el número de registros eliminados
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 9 BEGIN
			
			DECLARE @country TINYINT;
			DECLARE @zipLogic_Inv VARCHAR(100) = '''';
			DECLARE @zipLogic_Ver VARCHAR(100) = '''';
			DECLARE @zipJoin VARCHAR(MAX) = '''';
			DECLARE @zipRegion VARCHAR(MAX) = '''';

			SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
			
			if @country =1 begin
				select @zipCodeSchedule=@isZipCodeValidation;
			end
			if @zipCodeSchedule is null begin
				set @zipCodeSchedule=0
			END
        
			IF @zipCodeSchedule = 1 
			BEGIN
				SET @zipLogic_Inv = ''WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) '';
				SET @zipLogic_Ver = ''WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) '';
				SET @zipJoin = '' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z '';
				SET @zipRegion = '', Region = Z.State'';
			END

			SET @sql = ''
			UPDATE T SET 
				iZonaHoraria = CASE 
					WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0 
					'' + @zipLogic_Inv + '' 
					ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,
	 
				iZonaHoraria_verano = CASE 
					WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + '' 
					 ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,
	 
				iZonaHoraria2 = CASE 
					WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''             
					 ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,
	 
				iZonaHoraria_verano2 = CASE 
					WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0  
					 '' + @zipLogic_Ver + ''            
					 ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

				iZonaHoraria3 = CASE 
					WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''            
					 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,
	 
				iZonaHoraria_verano3 = CASE 
					WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + ''           
					 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

				iZonaHoraria4 = CASE 
					WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''             
					 ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,
	 
				iZonaHoraria_verano4 = CASE 
					WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + ''          
					 ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

				iZonaHoraria5 = CASE 
					WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''              
					 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,
	 
				iZonaHoraria_verano5 = CASE 
					WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + ''           
					 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END
					'' + @zipRegion + ''

			FROM '' + QUOTENAME(@tableName) + '' T '' + @zipJoin;
		
			EXEC sp_executesql @sql,
				N''@country TINYINT,@empty varchar(1)'',
				@country = @country,
				@empty = @empty

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
				@empty = @empty

		END
		ELSE
		BEGIN
			RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
			RETURN;
		END
	END'
	EXEC(@sql)

	 SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateSmsOutFromTempAction si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateSmsOutFromTempAction'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateSmsOutFromTempAction
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateSmsOutFromTempAction]
    @action INT,
    @tableName NVARCHAR(255),
    @sms_status int = 0,
    @idLoad int=0,
    @motivo varchar(50)=null,   
    @DateStart varchar(50) = null,
    @DateEnd varchar(50) = null,
    @internationalRecords int=0,
	@isZipCodeValidation BIT = 0

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @paramDef NVARCHAR(300);
    DECLARE @date datetime = getdate()  
    declare @empty varchar(1)='''',@zipCodeSchedule BIT = 0 ;
	DECLARE @columnsZipCode varchar(max)='''', @valuesColumnsZipCode varchar(max)='''';

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

		IF (@isZipCodeValidation = 1)
		BEGIN
			SET @columnsZipCode = '', zipCode, isZipCodeValidation''
			SET @valuesColumnsZipCode = '', T.cal_zipCodeValidation, '' +CAST(@isZipCodeValidation AS VARCHAR(1));

			SET @sql += ''
			INSERT INTO dbo.smsOutSource_ZipCode (smsout_id '' + @columnsZipCode  + '')
			SELECT 
				C.smsout_id
				'' + @valuesColumnsZipCode  + ''
			FROM '' + QUOTENAME(@tableName) + '' AS T
			INNER JOIN dbo.smsOutSource AS C WITH (NOLOCK)
				ON T.cal_Key = C.callkey 
				AND T.cam_id = C.cam_id
			WHERE T.callout_id=0
				AND T.cal_zipCodeValidation IS NOT NULL 
				AND T.cal_zipCodeValidation <> '''''''';'';
		END
       
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
		
		IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = ''Z.zipCode = '' + CASE WHEN @isZipCodeValidation = 1 THEN ''A.cal_zipCodeValidation'' ELSE ''@empty'' END + 
                        '', Z.isZipCodeValidation = '' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				UPDATE Z SET 
					'' + @columnsZipCode + ''
				FROM '' + QUOTENAME(@tableName) + '' A
				LEFT JOIN dbo.smsWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
				INNER JOIN dbo.smsOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.callout_id = Z.smsout_id
				WHERE B.smsout_id IS NULL;

				INSERT INTO dbo.smsOutSource_ZipCode (smsout_id, zipCode, isZipCodeValidation)
				SELECT A.callout_id, A.cal_zipCodeValidation, 1
				FROM '' + QUOTENAME(@tableName) + '' A
				WHERE A.callout_id > 0 
					AND A.cal_zipCodeValidation IS NOT NULL 
					AND A.cal_zipCodeValidation <> ''''''''
					AND NOT EXISTS (SELECT 1 FROM dbo.smsOutSource_ZipCode Z WHERE Z.smsout_id = A.callout_id);'';
			END
        
        SET @paramDef =   N''@sms_status int, @empty varchar(1)'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status, @empty = @empty;     

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
select @idLoad, A.cal_Key,@empty, 2, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;

delete A from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';

        SET @paramDef = N''@empty varchar(1),@idLoad int,@motivo varchar(50),@internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef, 
        @empty=@empty,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;
    END

    ELSE IF @action =7
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';
Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo)
select @idLoad, A.cal_Key,@empty, 2, @motivo from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@empty varchar(1),@idLoad int,@motivo varchar(50)'';
        EXEC sp_executesql @sql, @paramDef, @empty = @empty,@idLoad=@idLoad,@motivo=@motivo;
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
select @idLoad, A.cal_Key,@empty, 6, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@empty varchar(1),@idLoad int,@motivo varchar(50), @internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef, 
        @empty=@empty,
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

		DECLARE @country TINYINT;
		DECLARE @zipLogic_Inv VARCHAR(100) = '''';
		DECLARE @zipLogic_Ver VARCHAR(100) = '''';
		DECLARE @zipJoin VARCHAR(MAX) = '''';
		DECLARE @zipRegion VARCHAR(MAX) = '''';

		SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
		IF @country =1 begin
				select @zipCodeSchedule=@isZipCodeValidation;
		END
        
		if @zipCodeSchedule is null begin
			set @zipCodeSchedule=0
		END
        
		IF @zipCodeSchedule = 1 
		BEGIN
			SET @zipLogic_Inv = ''WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) '';
			SET @zipLogic_Ver = ''WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) '';
			SET @zipJoin = '' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z '';
			SET @zipRegion = '', Region = Z.State'';
		END
                
        SET @sql = ''
		UPDATE T SET 
			iZonaHoraria = CASE 
				WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0   
				 '' + @zipLogic_Inv + '' 
				  ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,
 
			iZonaHoraria_verano = CASE 
			  WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0  
			   '' + @zipLogic_Ver + ''   
				 ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,
 
			iZonaHoraria2 = CASE 
				WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0 
				 '' + @zipLogic_Inv + '' 
				  ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,
 
			iZonaHoraria_verano2 = CASE 
			  WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0               
			   '' + @zipLogic_Ver + ''   
				 ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

			iZonaHoraria3 = CASE 
				WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0
				 '' + @zipLogic_Inv + '' 
				 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,
 
			iZonaHoraria_verano3 = CASE 
			  WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0  
			   '' + @zipLogic_Ver + ''   
				 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

			iZonaHoraria4 = CASE 
				WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0  
				 '' + @zipLogic_Inv + '' 
				 ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,
 
			iZonaHoraria_verano4 = CASE 
			  WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0 
			   '' + @zipLogic_Ver + ''   
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

			iZonaHoraria5 = CASE 
				WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
				 '' + @zipLogic_Inv + '' 
				 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,
 
			iZonaHoraria_verano5 = CASE 
			   WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
			    '' + @zipLogic_Ver + ''         
				 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END
			'' + @zipRegion + ''

		FROM '' + QUOTENAME(@tableName) + '' T '' + @zipJoin;

		EXEC sp_executesql @sql,
				N''@country TINYINT,@empty varchar(1)'', 
				@country = @country,
				@empty = @empty

    END
    ELSE
    BEGIN
        RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
        RETURN;
    END
END'
	EXEC(@sql)

	 SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateWhatsAppOutFromTempAction si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateWhatsAppOutFromTempAction'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateWhatsAppOutFromTempAction
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE ccsp_UpdateWhatsAppOutFromTempAction 
    @action INT,
    @tableName NVARCHAR(255),
    @isZipCodeValidation BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @paramDef NVARCHAR(300);
	DECLARE @empty varchar(1)='''',@zipCodeSchedule BIT;
	declare @columnsZipCode varchar(max)='''', @valuesColumnsZipCode varchar(max)='''';  


	IF @action = 1 -- insert into ccWhatsAppOutSource from tableTmp
	BEGIN
		SET @sql = ''INSERT INTO dbo.ccWhatsAppOutSource(
		CallKey, camId, PhoneNumber, Status, TimeZone, TimeZone_Summer,
		List_id, User_id, TemplateId, componentJson, Data1,
		Data2, Data3, Data4, Data5, dateDial, MessageContent
		)
		SELECT CallKey, camId, PhoneNumber, Status, 
		TimeZone, TimeZone_Summer, List_id, 
		User_id, TemplateId, componentJson,
		Data1, Data2, Data3, 
		Data4, Data5, dateDial, 
		MessageContent 
		FROM '' + QUOTENAME(@tableName) + '' 
		where IsUpdated=0 AND IsReadyToDelete=0;''


		IF (@isZipCodeValidation = 1)
		BEGIN
			SET @columnsZipCode = '', zipCode, isZipCodeValidation''
			SET @valuesColumnsZipCode = '', T.cal_zipCodeValidation, '' +CAST(@isZipCodeValidation AS VARCHAR(1));

			SET @sql += ''
			INSERT INTO dbo.ccWhatsAppOutSource_ZipCode (WAOut_Id '' + @columnsZipCode  + '')
			SELECT 
				C.WAOut_Id
				'' + @valuesColumnsZipCode  + ''
			FROM '' + QUOTENAME(@tableName) + '' AS T
			INNER JOIN dbo.ccWhatsAppOutSource AS C WITH (NOLOCK)
				ON T.CallKey = C.CallKey 
				AND T.camId = C.camId
			WHERE T.IsUpdated = 0 AND T.IsReadyToDelete = 0
				AND T.cal_zipCodeValidation IS NOT NULL 
				AND T.cal_zipCodeValidation <> '''''''';'';
		END

		SET @sql += ''UPDATE '' + QUOTENAME(@tableName) + '' SET IsReadyToDelete = 1 WHERE IsUpdated = 0 AND IsReadyToDelete = 0;'';

		EXEC sp_executesql @sql;
	END
	ELSE IF @action = 2 -- update info in ccWhatsAppOutSource from tableTmp
	BEGIN


		SET @sql = ''UPDATE cwaos
            SET
                PhoneNumber = A.PhoneNumber,
                Data1 = A.Data1,
                Data2 = A.Data2,
                Data3 = A.Data3,
                Data4 = A.Data4,
                Data5 = A.Data5,
                componentJson = A.componentJson,
                MessageContent = A.MessageContent,
                TemplateId = A.TemplateId,
                dateDial = CASE WHEN ISNULL(cwwt.WaStatus, 0) = 0 THEN  A.dateDial ELSE cwaos.dateDial END,
				Status = CASE WHEN cwwt.WAOut_id IS NULL THEN 0 ELSE cwaos.Status END
            FROM '' + QUOTENAME(@tableName) + ''  as A
            inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_id = cwaos.WAOut_id
            left join dbo.ccoWAWorkingTable AS cwwt with(nolock) ON A.WAOut_id = cwwt.WAOut_id
            WHERE (cwwt.WAOut_id is null OR cwwt.WaStatus = 0)  and A.IsUpdated = 1 AND A.IsReadyToDelete = 0;'';


			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = ''Z.zipCode = '' + CASE WHEN @isZipCodeValidation = 1 THEN ''A.cal_zipCodeValidation'' ELSE ''@empty'' END + 
                        '', Z.isZipCodeValidation = '' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				UPDATE Z SET 
					'' + @columnsZipCode + ''
				FROM '' + QUOTENAME(@tableName) + '' A
				LEFT JOIN dbo.ccoWAWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.WAOut_id = B.WAOut_id
				INNER JOIN dbo.ccWhatsAppOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.WAOut_id = Z.WAOut_id
				WHERE (B.WAOut_id is null OR B.WaStatus = 0)  and A.IsUpdated = 1 AND A.IsReadyToDelete = 0;

				INSERT INTO dbo.ccWhatsAppOutSource_ZipCode (WAOut_id, zipCode, isZipCodeValidation)
				SELECT A.WAOut_id, A.cal_zipCodeValidation, 1
				FROM '' + QUOTENAME(@tableName) + '' A
				inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_id = cwaos.WAOut_id
				LEFT JOIN dbo.ccoWAWorkingTable B WITH (NOLOCK) ON A.WAOut_id = B.WAOut_id
				WHERE A.WAOut_id > 0 
					AND A.IsUpdated = 1 AND A.IsReadyToDelete = 0
					AND (B.WAOut_id IS NULL OR B.WaStatus = 0)
					AND A.cal_zipCodeValidation IS NOT NULL 
					AND A.cal_zipCodeValidation <> ''''''''
					AND NOT EXISTS (SELECT 1 FROM dbo.ccWhatsAppOutSource_ZipCode Z WHERE Z.WAOut_id = A.WAOut_id);'';
			END

			SET @sql += ''UPDATE '' + QUOTENAME(@tableName) + '' SET IsReadyToDelete = 1 WHERE IsUpdated = 1 AND IsReadyToDelete = 0;'';
			

		EXEC sp_executesql @sql,
			N''@empty varchar(1)'',
			@empty = @empty;
	END
    ELSE IF @action = 3 -- update phone number in workingtable if it is exist and WaStatus is Zero, not load by outbound whatsapp
	BEGIN
		SET @sql = ''UPDATE cwwt
            SET
                cwwt.PhoneNumber = A.phoneNumber,
				cwwt.dateDial = cwaos.dateDial
          FROM '' + QUOTENAME(@tableName) + '' as A inner join dbo.ccoWAWorkingTable AS cwwt with(nolock) ON A.WAOut_Id = cwwt.WAOut_Id
            inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_Id = cwaos.WAOut_Id
            WHERE A.IsUpdated = 1 and cwwt.WaStatus = 0;''

			EXEC sys.sp_executesql @sql;
	END
	ELSE IF @action = 4 -- update time zone
	BEGIN
		DECLARE @country TINYINT;
		DECLARE @zipLogic_Inv VARCHAR(100) = '''';
		DECLARE @zipLogic_Ver VARCHAR(100) = '''';
		DECLARE @zipJoin VARCHAR(MAX) = '''';

		SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
		IF @country = 1
		BEGIN
			select @zipCodeSchedule=@isZipCodeValidation;
		END
		  
		if @zipCodeSchedule is null begin
			set @zipCodeSchedule=0
		END

		IF @zipCodeSchedule = 1 
		BEGIN
			SET @zipLogic_Inv = ''WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) '';
			SET @zipLogic_Ver = ''WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) '';
			SET @zipJoin = '' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z '';
		END
        
		SET @sql = ''
		UPDATE T SET 
			TimeZone = CASE 
				WHEN (PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = @empty) THEN 0   
				 '' + @zipLogic_Inv + '' 
				  ELSE dbo.fnGetTimeZone(T.PhoneNumber,  0) END,
			TimeZone_Summer = CASE 
				WHEN (PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = @empty) THEN 0  
				 '' + @zipLogic_Ver + ''   
				  ELSE dbo.fnGetTimeZone(T.PhoneNumber,  1) END
		FROM '' + QUOTENAME(@tableName) + '' T '' + @zipJoin;

		EXEC sp_executesql @sql,
		N''@country TINYINT,@empty varchar(1)'',
			@country = @country,
			@empty = @empty;
	END
	ELSE IF @action = 5 --- delete table temp registries
	BEGIN
	 SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE IsReadyToDelete = 1;'';    
			EXEC sp_executesql @sql;
	END
END;'
	EXEC(@sql)

	 SET @process = 'Sprint6_finalPart - DROP ccsp_RIAOUTInsertNewJOBS_WT_Camp si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_RIAOUTInsertNewJOBS_WT_Camp'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_RIAOUTInsertNewJOBS_WT_Camp
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000   
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
            CASE WHEN LEN(cwaos.PhoneNumber) > 0 THEN cwaos.TimeZone  ELSE NULL END,
            CASE WHEN LEN(cwaos.PhoneNumber) > 0 THEN  cwaos.TimeZone_Summer ELSE NULL END, 
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
    --Se elimina de workingtable en caso de que no se hayan borrado correctamente no genere error al insertar nuevos registros
        DELETE wt FROM ccoWorkingTable wt
        INNER JOIN #tempCallsOutSource tcs on wt.callout_id = tcs.callout_id
        WHERE wt.cam_id = @camp_id

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
	EXEC(@sql);

	 SET @process = 'Sprint6_finalPart - DROP ccsp_RIALogPhones si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_RIALogPhones'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_RIALogPhones
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE SP ccsp_RIALogPhones 
	Se quito la línea
	   if @nType like %____1%
            select @CaseType = @CaseType +   or telefono<> '' and crlp.tipoMov = 0
	Debido a que al filtrar solo por registros no cargados tambien traia los telefonos, y eso estaba
	mal ya que para ver los telefonos no cargados existe el filtro de telefonos'
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
