USE CCReportsRIA
GO

DECLARE @process VARCHAR(100)

BEGIN TRAN
BEGIN TRY

    -- =====================================================================
    -- K070305 - Reporte Detalle de llamada contestada para agentes virtuales
    -- BD: CCReportsRIA
    -- Cambios:
    --   0. RepOutDialDetail: nueva columna campType TINYINT NULL
    --   1. SP ccspRepOutDialDetail: poblar campType, IsAICampaign, login='N/A' para IA, calId
    --   2. TranslatedReports id=4010: agregar ModelName a columnas traducibles
    --   3. Filters/ReportsFilters: filtro campaignType para reporte 4010
    --   3c. RepOutDialDetailView: exponer ValidationMode, IsAICampaign, campType
    -- PASO 4 (fuera del TRAN): ccspRepCatalogos type=39 para campaignType
    -- =====================================================================

    -- -----------------------------------------------------------------
    -- 0. campType: nueva columna en RepOutDialDetail
    -- -----------------------------------------------------------------
    SET @process = 'K070305 - ADD campType to RepOutDialDetail'

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = 'campType' AND Object_ID = OBJECT_ID('dbo.RepOutDialDetail'))
        ALTER TABLE dbo.RepOutDialDetail ADD campType TINYINT NULL;

    -- Garantizar ValidationMode e IsAICampaign por si este servidor no tiene el 14 Script
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = 'ValidationMode' AND Object_ID = OBJECT_ID('dbo.RepOutDialDetail'))
        ALTER TABLE dbo.RepOutDialDetail ADD ValidationMode VARCHAR(100) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = 'IsAICampaign' AND Object_ID = OBJECT_ID('dbo.RepOutDialDetail'))
        ALTER TABLE dbo.RepOutDialDetail ADD IsAICampaign BIT NULL;

    -- -----------------------------------------------------------------
    -- 1. SP ccspRepOutDialDetail
    -- -----------------------------------------------------------------
    SET @process = 'K070305 - SP ccspRepOutDialDetail'

    IF OBJECT_ID('ccspRepOutDialDetail') IS NOT NULL
        DROP PROCEDURE ccspRepOutDialDetail

    EXEC('
CREATE PROCEDURE [dbo].[ccspRepOutDialDetail]
    @action AS TINYINT,
    @from   AS DATETIME = NULL,
    @to     AS DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @from IS NULL SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15;
    IF @to IS NULL SELECT @to = GETDATE();

    IF @action = 1
    BEGIN
        DECLARE @country SMALLINT; SELECT @country = valor FROM ccSettings WHERE setting_id = 104;

        DELETE FROM RepOutDialDetail WHERE [date] >= @from AND [date] < @to;

        IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials;
        IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip;
        IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip;

        SELECT
            dial.logDial_id,
            dial.callout_id,
            dial.cam_id,
            CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id,
            ISNULL(tr.descTranslate,'''') AS resultDialDesc,
            dial.Telefono,
            dial.Puerto,
            dial.fecha,
            dial.tDialing,
            CASE
                WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview''
                WHEN SUBSTRING(dial.TipoDialingMode, 2, 1) = ''1'' AND co.cal_manual = 0 THEN ''systemTranslated_Assisted''
                WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
                WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto''
                WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(dial.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
                WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual''
            END AS dialType,
            dial.tBusy,
            dial.answerbit,
            dial.canceledNoAgents,
            CAST(dial.cal_id AS VARCHAR(20)) AS cal_id,
            dial.disconnectCause,
            co.cal_key,
            co.file_moved,
            dial.tipoLlamada_id,
            tco.[Description] AS CallDisposition,
            tsco.califSubDesc,
            CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END AS codeSip,
            CASE
                WHEN @country<>1 THEN ''''
                WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo''
                WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone''
                ELSE ''systemTranslated_Indefinite''
            END AS TipoTel,
            ISNULL(regp.tPreview,'''') AS tpreview,
            co.User_id AS UserID,
            co.virtualAgentId,
            dial.ani,
            codia.CapturedData
        INTO #dials
        FROM ccoLogDials dial (NOLOCK)
        LEFT JOIN ccoCallsOut co (NOLOCK)
            ON dial.cal_id = co.cal_id
        LEFT JOIN ccTipoCalifOUT tco WITH (NOLOCK)
            ON tco.calif_id = co.calif_id
        LEFT JOIN ccTipoCalifSubOUT tsco WITH (NOLOCK)
            ON tsco.califSub_id = co.califSub_id
        LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK)
            ON regp.callout_id = co.callout_id AND regp.callId = co.cal_id
        LEFT JOIN ccTipoResultadoDial tr (NOLOCK)
            ON dial.tipoResDial_id = tr.tipoResDial_id
        LEFT JOIN ccoCallsOutDispositionIA codia (NOLOCK)
            ON codia.call_id = dial.cal_id
        WHERE fecha >= @from AND fecha < @to

        UNION

        (SELECT
            '''' AS logDial_id,
            reg.callout_id,
            ccoa.cam_id,
            reg.process AS tipoResDial_id,
            ISNULL(cctyp.translatedDesc,'''') AS resultDialDesc,
            ccoa.cal_telefono,
            '''' AS Puerto,
            reg.reg_date AS fecha,
            '''' AS tDialing,
            ''systemTranslated_Preview'' AS dialType,
            '''' AS tBusy,
            '''' AS answerbit,
            '''' AS canceledNoAgents,
            '''' AS cal_id,
            '''' AS disconnectCause,
            '''' AS cal_key,
            '''' AS file_moved,
            '''' AS tipoLlamada_id,
            '''' AS CallDisposition,
            '''' AS califSubDesc,
            '''' AS codeSip,
            '''' AS TipoTel,
            reg.tPreview AS tpreview,
            reg.userId AS UserID,
            ccoa.virtualAgentId AS virtualAgentId,
            '''' AS ani,
            '''' AS CapturedData
        FROM RegProcessPreviewRecord reg (NOLOCK)
        LEFT JOIN ccoCallsOut ccoa (NOLOCK)
            ON reg.callout_id = ccoa.callout_id
        LEFT JOIN ccTypeProcessPreview cctyp (NOLOCK)
            ON cctyp.typeProcess_id = reg.process
        WHERE reg.reg_date >= @from AND reg.reg_date < @to
          AND reg.process NOT IN (5,7,13,14))

        SELECT DISTINCT CAST(codeSip AS INT) AS codeSip, disconnectCause
        INTO #codeSip
        FROM #dials WHERE codeSip <> '''' AND ISNUMERIC(codeSip) = 1;

        SELECT A.codeSip, A.disconnectCause, B.[description]
        INTO #relationCodeSip
        FROM #codeSip A INNER JOIN DC_Extra B ON A.codeSip = B.id;

        INSERT INTO RepOutDialDetail(
            [date], [callKey], [telephone], [dialResultId], [dialResult],
            [campaignId], [campaign], [ModelName], [timeMessage],
            [year], [month], [day], [hour], [minutes],
            [listName], [billed],
            [data1], [data2], [data3], [data4], [data5],
            [fileMoved], [disconnectCause], [DCCustomer],
            [dialType], [TipoTel],
            [CallDisposition], [CallSubDisposition],
            [data6], [data7], [data8], [data9], [data10],
            [data11], [data12], [data13], [data14], [data15],
            [preview_Time], [login], [areaId], [area],
            [ani], [CapturedData], [ValidationMode],
            [IsAICampaign], [calId], [campType]
        )
        SELECT
            dials.fecha AS [date],
            CASE
                WHEN dials.cal_key IS NULL AND cs.cal_key IS NULL THEN ''''
                WHEN dials.cal_key IS NOT NULL THEN dials.cal_key
                ELSE cs.cal_key
            END AS cal_key,
            ISNULL(dials.Telefono,'''') AS telephone,
            dials.tipoResDial_id AS dialResultId,
            CASE
                WHEN dials.tipoResDial_id = 14 THEN
                    CASE WHEN camps.campType = 6 THEN ''systemTranslated_CancelledByEngaged''
                         ELSE ''systemTranslated_CancelledBySystem'' END
                ELSE ISNULL(dials.resultDialDesc, '''')
            END AS dialResult,
            ISNULL(dials.cam_id,'''') AS campaignId,
            ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),''systemTranslated_NoCampaign'') AS campaign,
            ISNULL(va.nameAgent,''NA'') AS ModelName,
            dials.tbusy AS timeMessage,
            DATEPART(yyyy, dials.fecha) AS [year],
            DATEPART(mm,   dials.fecha) AS [month],
            DATEPART(dd,   dials.fecha) AS [day],
            DATEPART(hh,   dials.fecha) AS [hour],
            DATEPART(mi,   dials.fecha) AS [minutes],
            ISNULL(rl.[name], '''') AS listName,
            CASE WHEN dials.answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed,
            ISNULL(ldd.Data1, ISNULL(cs.Dato1, '''')) AS data1,
            ISNULL(ldd.Data2, ISNULL(cs.Dato2, '''')) AS data2,
            ISNULL(ldd.Data3, ISNULL(cs.Dato3, '''')) AS data3,
            ISNULL(ldd.Data4, ISNULL(cs.Dato4, '''')) AS data4,
            ISNULL(ldd.Data5, ISNULL(cs.Dato5, '''')) AS data5,
            CASE
                WHEN dials.file_moved = 1 THEN ''systemTranslated_Remoto''
                WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
                ELSE ''systemTranslated_Local''
            END AS fileMoved,
            dials.disconnectCause,
            COALESCE(dat.[description], tr.descTranslate, ''N/A'') AS DCCustomer,
            dials.dialType,
            dials.TipoTel,
            ISNULL(dials.CallDisposition, ''N/A'') AS CallDisposition,
            ISNULL(dials.califSubDesc, ''N/A'') AS CallSubDisposition,
            ISNULL(csP.Dato6,  '''') AS data6,
            ISNULL(csP.Dato7,  '''') AS data7,
            ISNULL(csP.Dato8,  '''') AS data8,
            ISNULL(csP.Dato9,  '''') AS data9,
            ISNULL(csP.Dato10, '''') AS data10,
            ISNULL(csP.Dato11, '''') AS data11,
            ISNULL(csP.Dato12, '''') AS data12,
            ISNULL(csP.Dato13, '''') AS data13,
            ISNULL(csP.Dato14, '''') AS data14,
            ISNULL(csP.Dato15, '''') AS data15,
            dials.tpreview AS preview_Time,
            CASE
                WHEN camps.CampType = 9 THEN ''N/A''
                ELSE ISNULL(us.[Login],'''')
            END AS [Login],
            ISNULL(ar.IDArea, 1) AS areaId,
            ISNULL(ar.AreaName,''Default'') AS area,
            dials.ani,
            dials.CapturedData,
            CASE
                WHEN cs_zip.isZipCodeValidation = 1
                     AND ISNULL(LTRIM(RTRIM(cs_zip.zipCode)), '''') <> ''''
                THEN ''Zona horaria (C. P. '' + cs_zip.zipCode + '')''
                ELSE ''COFETEL''
            END AS ValidationMode,
            CASE WHEN camps.CampType = 9 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsAICampaign,
            CASE WHEN ISNUMERIC(dials.cal_id) = 1 THEN CAST(dials.cal_id AS INT) ELSE 0 END AS calId,
            CASE
                WHEN camps.CampType = 9 THEN CAST(9 AS TINYINT)
                WHEN camps.CampType = 6 THEN CAST(6 AS TINYINT)
                ELSE CAST(0 AS TINYINT)
            END AS campType
        FROM #dials AS dials
        LEFT JOIN ccoCallsOutSource cs (NOLOCK)
            ON dials.callout_id = cs.callout_id
        LEFT JOIN ccoLogDialsData ldd (NOLOCK)
            ON ldd.logDial_id = dials.logDial_id
        LEFT JOIN ccTipoResultadoDial tr (NOLOCK)
            ON dials.tipoResDial_id = tr.tipoResDial_id
        LEFT JOIN ccCamps camps (NOLOCK)
            ON camps.cam_id = dials.cam_id
        LEFT JOIN ccVirtualAgent va (NOLOCK)
            ON va.idAgent = dials.virtualAgentId
        LEFT JOIN ccRIARegistryLists rl (NOLOCK)
            ON cs.list_id = rl.list_id
        LEFT JOIN #relationCodeSip dat
            ON dat.disconnectCause = dials.disconnectCause
        LEFT JOIN ccoCallsPreviewData csP
            ON dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id
        LEFT JOIN ccUsers us (NOLOCK)
            ON us.User_id = dials.UserID
        LEFT JOIN ccRIACat_Areas ar (NOLOCK)
            ON ar.IDArea = camps.IDArea
        LEFT JOIN CCenterRIA.dbo.ccoCallsOutSource_ZipCode cs_zip
            ON cs_zip.callout_id = dials.callout_id

        IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials;
        IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip;
        IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip;
    END
END
')

    -- -----------------------------------------------------------------
    -- 2. TranslatedReports: agregar ModelName para reporte 4010
    -- -----------------------------------------------------------------
    SET @process = 'K070305 - TranslatedReports id=4010 agrega ModelName'

    IF NOT EXISTS (
        SELECT 1 FROM TranslatedReports
        WHERE id = 4010 AND columns LIKE '%ModelName%'
    )
    BEGIN
        UPDATE TranslatedReports
        SET columns = columns + '|ModelName'
        WHERE id = 4010
    END

    -- -----------------------------------------------------------------
    -- 3a. Filters: registrar campaignType en el catalogo maestro
    -- -----------------------------------------------------------------
    SET @process = 'K070305 - Filters campaignType catalogo maestro'

    IF NOT EXISTS (SELECT 1 FROM Filters WHERE name = 'campaignType')
    BEGIN
        DECLARE @nextFilterId INT
        SELECT @nextFilterId = MAX(id) + 1 FROM Filters

        INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode)
        VALUES (@nextFilterId, 'campaignType', @nextFilterId, 'CampaignTypes', 'CampaignType')
    END

    -- -----------------------------------------------------------------
    -- 3b. ReportsFilters: agregar filtro campaignType para reporte 4010
    -- -----------------------------------------------------------------
    SET @process = 'K070305 - ReportsFilters campaignType para id=4010'

    IF NOT EXISTS (
        SELECT 1 FROM ReportsFilters
        WHERE id = 4010 AND filterName = 'campaignType'
    )
    BEGIN
        INSERT INTO ReportsFilters (id, reportName, filterName)
        VALUES (4010, 'Dialing Detail', 'campaignType')
    END

    -- -----------------------------------------------------------------
    -- 3c. ALTER VIEW RepOutDialDetailView: exponer ValidationMode,
    --     IsAICampaign y campType
    -- -----------------------------------------------------------------
    SET @process = 'K070305 - ALTER VIEW RepOutDialDetailView'

    EXEC('
ALTER VIEW [dbo].[RepOutDialDetailView] AS
SELECT
    [date], [calId], [callKey], [telephone], [dialResultId], [dialResult], [dialog],
    [campaignId], [campaign], [ModelName], [timeMessage],
    [year], [month], [day], [hour], [minutes],
    [listName], [billed], [CapturedData],
    [data1]  AS [Dato1],
    [data2]  AS [Dato2],
    [data3]  AS [Dato3],
    [data4]  AS [Dato4],
    [data5]  AS [Dato5],
    [fileMoved], [DCCustomer], [disconnectCause], [dialType], [TipoTel],
    [CallDisposition], [CallSubDisposition],
    [data6], [data7], [data8], [data9], [data10],
    [data11], [data12], [data13], [data14], [data15],
    [preview_Time], [login] AS [user], [areaId], [area], [ani],
    [ValidationMode],
    ISNULL([IsAICampaign], 0) AS [IsAICampaign],
    ISNULL([campType],    0) AS [campType]
FROM RepOutDialDetail WITH (NOLOCK);
')

    COMMIT TRAN
    PRINT 'K070305 - Pasos 0-3c aplicados correctamente.'

END TRY
BEGIN CATCH
    ROLLBACK TRAN
    DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @errLine INT = ERROR_LINE()
    PRINT 'ERROR en proceso [' + ISNULL(@process,'') + '] linea ' + CAST(@errLine AS VARCHAR) + ': ' + @errMsg
END CATCH
GO

-- =======================================================================
-- PASO 4 (fuera del TRAN — DDL de procedimiento no puede ir dentro)
-- K070305 - ccspRepCatalogos: agregar type=39 para filtro campaignType
--
-- Devuelve 3 opciones mapeadas a la columna campType de RepOutDialDetail:
--   0 = Salida estandar  (CampType != 9 y != 6)
--   9 = Salida IA        (CampType  = 9)
--   6 = Salida VP        (CampType  = 6)
--
-- GenericReport construye automaticamente:
--   AND CHARINDEX(','+CAST([campType] AS VARCHAR)+',', ',<vals>,') > 0
-- No se requieren cambios en cw-reports-asp.
-- =======================================================================
IF OBJECT_ID('dbo.ccspRepCatalogos') IS NOT NULL
    DROP PROCEDURE dbo.ccspRepCatalogos
GO

CREATE PROCEDURE [dbo].[ccspRepCatalogos]
    @type     TINYINT,
    @action   TINYINT  = 0,
    @userId   INT      = 0,
    @menuId   INT      = 0
AS
BEGIN

    DECLARE @tablatemp TABLE (id INT, description VARCHAR(100) NULL)
    DECLARE @tempwork  TABLE (idwg INT)
    DECLARE @SQL       NVARCHAR(MAX)
    DECLARE @condition    NVARCHAR(300) = ''
    DECLARE @columnName   NVARCHAR(100) = ''
    DECLARE @consult      NVARCHAR(2000) = ''

    IF @action = 0
    BEGIN
        IF OBJECT_ID('TEMPDB..#filters') IS NULL
        BEGIN
            CREATE TABLE #filters ([Type] VARCHAR(200))
        END

        -- CAMPAIGNS
        IF @type = 1
        BEGIN
            INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = 'campaigns' AND ReportId = @menuId
            IF EXISTS (SELECT * FROM #filters)
            BEGIN
                SET @condition  = ' WHERE camp.campType IN (SELECT * FROM #filters)'
                SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = 'campaigns' AND ReportId = @menuId
            END
            ELSE BEGIN
                SET @columnName = 'campaignId'
            END

            SET @consult = N' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp'

            IF @userId <> 0
            BEGIN
                DECLARE @isJustVoiceFilter BIT = CASE WHEN @menuId IN (4010) THEN 1 ELSE 0 END

                SET @SQL = ' DECLARE @tablatemp TABLE (id INT, description VARCHAR(100) NULL)
                    INSERT INTO @tablatemp
                    SELECT DISTINCT caesp.IdCampEsp, '''' AS description FROM ccUserView us
                    INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                    INNER JOIN ccRIACampEspWG caesp ON wgu.IDWG = caesp.IDWG AND caesp.Tipo=1'

                IF @isJustVoiceFilter = 1
                BEGIN
                    SET @SQL += ' INNER JOIN dbo.cccamps AS c ON caesp.IdCampEsp = c.cam_id'
                END

                SET @SQL += ' WHERE us.[User_id] = @userId'

                IF @isJustVoiceFilter = 1
                BEGIN
                    SET @SQL += ' AND c.CampType IN (0,6,9)'
                END

                SET @SQL += ' IF EXISTS(SELECT 1 FROM @tablatemp) BEGIN '
                    + @consult + ' INNER JOIN @tablatemp A ON camp.cam_id = A.id ' + @condition
                    + ' END
                    ELSE BEGIN
                        SELECT 0 AS id, ''N/A'' AS description, ''campaignId'' AS dbColumn
                    END'
            END
            ELSE BEGIN
                SET @SQL = @consult + @condition
            END
            EXEC sp_executesql @SQL, N'@userId AS INT = 0, @columnName AS NVARCHAR(100)', @userId=@userId, @columnName=@columnName
        END

        -- DIAL RESULTS
        IF @type = 2
        BEGIN
            SELECT tiporesdial_id AS id, descripcion AS description, 'dialResultId' AS dbColumn
            FROM ccTipoResultadoDial
            ORDER BY descripcion
        END

        -- WORKGROUPS
        IF @type = 3
        BEGIN
            IF @userId <> 0
            BEGIN
                SELECT v.IDWG AS id, c.WGName AS description, 'workgroupId' AS dbColumn
                FROM ccWgByAcdView v
                INNER JOIN ccriacat_workgroup c ON c.IDWG = v.IDWG
                WHERE USER_ID = @userId
                RETURN
            END
            ELSE BEGIN
                SELECT idwg AS id, wgname AS description, 'workgroupId' AS dbColumn
                FROM ccRIACat_WorkGroup
                GROUP BY idwg, wgname
                ORDER BY wgname
            END
        END

        -- AREAS
        IF @type = 4
        BEGIN
            IF @userId <> 0
            BEGIN
                INSERT INTO @tablatemp
                SELECT DISTINCT ISNULL(us.IDArea, 0) AS IDArea, wgu.User_id FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                WHERE us.[User_id] = @userId

                SELECT DISTINCT idArea AS id, ISNULL(AreaName, 'S/AREA') AS description, 'areaId' AS dbColumn
                FROM ccRIACat_Areas area INNER JOIN @tablatemp tem ON area.IDArea = tem.id
                RETURN
            END
            ELSE BEGIN
                SELECT idArea AS id, AreaName AS description, 'areaId' AS dbColumn
                FROM ccRIACat_Areas
                GROUP BY idArea, AreaName
                ORDER BY AreaName
            END
        END

        -- DISPOSITIONS OUT
        IF @type = 5
        BEGIN
            SELECT calif_id AS id, [description] AS description, 'dispositionId' AS dbColumn
            FROM ccTipoCalifOut
            ORDER BY [description]
        END

        -- USER
        IF @type = 6
        BEGIN
            IF @userId <> 0
            BEGIN
                INSERT INTO @tempwork
                    SELECT IDWG FROM ccRIAWorkGroupUsers WITH (INDEX(IX_ccRIAWorkGroupUsers_I)) WHERE User_id = @userId

                SELECT DISTINCT us.User_id AS id, us.Login AS description, 'userId' AS dbcolumn FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                INNER JOIN @tempwork awg ON wgu.IDWG = awg.idwg
                WHERE us.TipoUser_id = 1 AND [status] = 1
                RETURN
            END
            ELSE BEGIN
                SELECT [user_id] AS id, [login] AS description, 'userId' AS dbColumn
                FROM ccUserView WHERE [status] = 1 AND TipoUser_id = 1
                ORDER BY description
            END
        END

        -- ACDS
        IF @type = 7
        BEGIN
            INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = 'acds' AND ReportId = @menuId
            IF EXISTS (SELECT * FROM #filters)
            BEGIN
                SET @condition  = ' WHERE B.chat IN (SELECT * FROM #filters)'
                SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = 'acds' AND ReportId = @menuId
            END
            ELSE BEGIN
                SET @columnName = 'inboundId'
            END

            SET @consult = N' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn FROM ccInbound B'

            IF @userId <> 0
            BEGIN
                SET @SQL = ' DECLARE @tablatemp TABLE (id INT, description VARCHAR(100) NULL)
                    INSERT INTO @tablatemp
                    SELECT DISTINCT caesp.IdCampEsp, '''' AS description FROM ccUserView us
                    INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                    INNER JOIN ccRIACampEspWG caesp ON wgu.IDWG = caesp.IDWG AND caesp.Tipo=0
                    WHERE us.[User_id] = @userId;'
                    + ' IF EXISTS(SELECT 1 FROM @tablatemp) BEGIN'
                    + @consult + ' INNER JOIN @tablatemp A ON B.inbound_id = A.id' + @condition + ' RETURN;'
                    + ' END
                    ELSE BEGIN
                        SELECT 0 AS id, ''N/A'' AS description, ''inboundId'' AS dbColumn
                    END'
            END
            ELSE BEGIN
                SET @SQL = @consult + @condition
            END
            EXEC sp_executesql @SQL, N'@userId INT = 0, @columnName AS NVARCHAR(100)', @userId=@userId, @columnName=@columnName
        END

        -- DIDS
        IF @type = 8
        BEGIN
            SELECT 0 AS id, 'S/DNIS' AS description, 'dnisId' AS dbColumn
            UNION
            SELECT dni_id AS id, CASE WHEN dni_Descripcion = '' THEN CONVERT(VARCHAR, dni_numero) ELSE dni_Descripcion END AS description, 'dnisId' AS dbColumn
            FROM ccdnis
        END

        -- DISPOSITIONS IN
        IF @type = 9
        BEGIN
            SELECT calif_id AS id, [description] AS description, 'dispositionId' AS dbColumn
            FROM ccTipoCalif
            ORDER BY [description]
        END

        -- SUBDISPOSITIONS IN
        IF @type = 10
        BEGIN
            SELECT califSub_id AS id, [califSubDesc] AS description, 'subDispositionId' AS dbColumn
            FROM ccTipoCalifSub
            ORDER BY [description]
        END

        -- PROVIDER
        IF @type = 11
        BEGIN
            SELECT proveedor_id AS id, descrip AS description, 'providerId' AS dbColumn
            FROM cstoProveedor
            ORDER BY [description]
        END

        -- UNAVAILABLES
        IF @type = 12
        BEGIN
            SELECT tiponotready_id AS id, descripcion AS description, 'tiponotreadyId' AS dbColumn
            FROM cctiponotready
            ORDER BY descripcion
        END

        -- DIALERS
        IF @type = 13
        BEGIN
            SELECT dialer_id AS id, descripcion AS description, 'dialerId' AS dbColumn
            FROM ccoDiaers
            ORDER BY descripcion
        END

        -- CALL TYPES
        IF @type = 14
        BEGIN
            SELECT statusCall_id AS id, descripcion AS description, 'callStatusId' AS dbColumn
            FROM ccStatusLlamada
            ORDER BY descripcion
        END

        -- AVRS TEMPLATE-SECTION
        IF @type = 15
        BEGIN
            SELECT fc.id AS id, (rf.nombre + ' ' + rc.con_descripcion) + ' ' + CONVERT(VARCHAR(10), fc.id) AS description, 'templateSectionId' AS dbColumn
            FROM RIA_FORMATOCONCEPTO fc
            INNER JOIN (SELECT id_formato, nombre, MAX(version) AS version FROM RIA_FORMATOS WHERE activo = 1 GROUP BY id_formato, nombre) AS rf ON rf.id_formato = fc.templateId
            INNER JOIN RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
            ORDER BY fc.id
        END

        -- AVRS TEMPLATES
        IF @type = 16
        BEGIN
            SELECT f.id_formato AS id, f.nombre AS description, 'templateId' AS dbColumn
            FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato, MAX(version) AS version FROM RIA_FORMATOS WHERE activo = 1 GROUP BY id_formato) AS t
            ON f.id_formato = t.id_formato AND f.version = t.version
            ORDER BY f.nombre
        END

        -- AVRS SUPERVISOR
        IF @type = 17
        BEGIN
            SELECT [user_id] AS id, [login] AS description, 'supervisorId' AS dbColumn
            FROM ccUserView
            WHERE [status] = 1 AND TipoUser_id = 2
            ORDER BY [login]
        END

        -- AVRS SECTIONS
        IF @type = 31
        BEGIN
            SELECT c.id_concepto AS id, c.con_descripcion AS description, 'sectionId' AS dbColumn
            FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto, MAX(version) AS version FROM RIA_CONCEPTOS GROUP BY id_concepto) AS t
            ON c.id_concepto = t.id_concepto AND c.version = t.version
            ORDER BY c.con_descripcion
        END

        -- AVRS QUESTIONS
        IF @type = 23
        BEGIN
            SELECT p.id_pregunta AS id, p.enunciado_pregunta AS description, 'questionId' AS dbColumn
            FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta FROM RIA_PREGUNTAS GROUP BY id_pregunta) AS t ON p.id_pregunta = t.id_pregunta
            ORDER BY p.enunciado_pregunta
        END

        -- AVRS QUESTIONS CHAT
        IF @type = 24
        BEGIN
            SELECT p.id_pregunta AS id, p.enunciado_pregunta AS description, 'questionId' AS dbColumn
            FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta FROM RIA_PREGUNTAS GROUP BY id_pregunta) AS t ON p.id_pregunta = t.id_pregunta
            ORDER BY p.enunciado_pregunta
        END

        -- STATUS CALL
        IF @type = 25
        BEGIN
            SELECT statusCall_id AS id, [descripcion] AS description, 'statusCallId' AS dbcolumn
            FROM ccstatusLlamada
            ORDER BY [descripcion]
        END

        -- SURVEY
        IF @type = 26
        BEGIN
            SELECT surveyId AS id, [description] AS description, 'surveyId' AS dbcolumn
            FROM Survey
            ORDER BY [description]
        END

        -- DIAL TYPE
        IF @type = 29
        BEGIN
            SELECT dialId AS id, [description] AS description, 'dialId' AS dbcolumn
            FROM dialType
            ORDER BY [description]
        END

        -- DIALS
        IF @type = 30
        BEGIN
            SELECT id AS id, [description] AS description, 'dialId' AS dbcolumn
            FROM Dials
            ORDER BY [description]
        END

        -- INBOUND CHAT CAMPAIGNS
        IF @type = 33
        BEGIN
            IF @userId <> 0
            BEGIN
                INSERT INTO @tablatemp
                SELECT DISTINCT caesp.IdCampEsp, '' AS description FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                INNER JOIN ccRIACampEspWG caesp ON wgu.IDWG = caesp.IDWG AND caesp.Tipo=0
                INNER JOIN ccInbound i ON caesp.IdCampEsp = i.Inbound_id AND i.chat IN (0,11)
                WHERE us.[User_id] = @userId

                SELECT inbound_id AS id, descripcion AS description, 'inboundCamp' AS dbColumn
                FROM ccInbound B INNER JOIN @tablatemp A ON B.inbound_id = A.id
                RETURN
            END
            ELSE BEGIN
                SELECT inbound_id AS id, descripcion AS description, 'inboundCamp' AS dbColumn
                FROM ccInbound WHERE chat IN (0,11)
            END
        END

        -- AUXILIAR TYPES
        IF @type = 34
        BEGIN
            SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, 'auxiliarId' AS dbcolumn
            FROM TipoReadyAuxiliar
            ORDER BY [description]
        END

        -- SMS SEGMENTS
        IF @type = 35
        BEGIN
            SELECT SegmentId AS id, Name AS description, 'SegmentId' AS dbColumn FROM ccSmsSegments
        END

        -- ADMIN USER
        IF @type = 36
        BEGIN
            IF @userId <> 0
            BEGIN
                INSERT INTO @tempwork
                    SELECT IDWG FROM ccRIAWorkGroupUsers WITH (INDEX(IX_ccRIAWorkGroupUsers_I)) WHERE User_id = @userId

                SELECT DISTINCT us.User_id AS id, us.Login AS description, 'adminId' AS dbcolumn FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                INNER JOIN @tempwork awg ON wgu.IDWG = awg.idwg
                WHERE us.TipoUser_id = 2 AND [status] = 1
                RETURN
            END
            ELSE BEGIN
                SELECT [user_id] AS id, [login] AS description, 'adminId' AS dbColumn
                FROM ccUserView WHERE [status] = 1 AND TipoUser_id = 2
                ORDER BY description
            END
        END

        -- IA INBOUND CAMPAIGNS (proceso 2150)
        IF @type = 37
        BEGIN
            IF @userId <> 0
            BEGIN
                SELECT DISTINCT
                    i.Inbound_id  AS id,
                    i.descripcion AS description,
                    'inboundId'   AS dbcolumn
                FROM ccInbound i
                INNER JOIN ccRIACampEspWG cewg ON cewg.IdCampEsp = i.Inbound_id
                INNER JOIN ccRIAWorkGroupUsers wgu ON wgu.IDWG = cewg.IDWG
                INNER JOIN ccUsers u ON wgu.User_id = u.user_id
                WHERE wgu.User_id = @userId
                  AND i.chat = 11
                  AND i.IDArea = u.IDArea
            END
            ELSE
            BEGIN
                SELECT DISTINCT
                    Inbound_id  AS id,
                    descripcion AS description,
                    'inboundId' AS dbcolumn
                FROM ccInbound
                WHERE chat = 11
                ORDER BY description
            END
        END

        -- VIRTUAL AGENT MODEL NAME (procesos 2150, 3010, 4010)
        IF @type = 38
        BEGIN
            SELECT
                nameAgent AS id,
                nameAgent AS description,
                'ModelName' AS dbcolumn
            FROM ccVirtualAgent
            ORDER BY description
        END

        -- CAMPAIGN TYPE (proceso 4010)
        -- Filtra por campType en RepOutDialDetail: 0=Estandar, 9=IA, 6=VP
        IF @type = 39
        BEGIN
            SELECT id, description, dbcolumn FROM (VALUES
                (0, 'systemTranslated_StandardOutbound', 'campType'),
                (9, 'systemTranslated_AIOutbound',       'campType'),
                (6, 'systemTranslated_VPOutbound',       'campType')
            ) AS t(id, description, dbcolumn)
        END

    END -- Action 0

    IF OBJECT_ID('TEMPDB..#filters') IS NOT NULL
        DROP TABLE #filters

    -- ---------------------------------------------------------
    IF @action = 1
    BEGIN
        -- TRUNKS
        IF @type = 13
        BEGIN
            SELECT MIN(trunk) AS [min], MAX(trunk) AS [max], 'trunk' AS dbColumn FROM RepTrunkBusy
        END

        -- AVRS DISPOSITION
        IF @type = 18
        BEGIN
            SELECT 0 AS [min], 100 AS [max], 'Disposition' AS dbColumn
        END

        -- AVG DISPOSITION
        IF @type = 19
        BEGIN
            SELECT 0 AS [min], 100 AS [max], 'avgDisposition' AS dbColumn
        END

        -- SCORE
        IF @type = 20
        BEGIN
            SELECT 0 AS [min], 100 AS [max], 'avgDisposition' AS dbColumn
        END
    END

END
GO
