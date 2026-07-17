/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Equipo Galatea
Date: 2026/07/15
Description: K070305 - Reporte Detalle de llamada contestada para agentes virtuales (4020)

Database: CCReportsRIA
Required version: 146

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

SET NOCOUNT ON --

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
SET @version = 147 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

    -- =====================================================================
    -- K070305 - Reporte Detalle de llamada contestada para agentes virtuales
    -- BD: CCReportsRIA  |  Reporte: 4020 (RepViewOutCallsDetail)
    --
    -- ROLLBACK 4010 (cambios aplicados por error):
    --   R1. ReportsFilters: quitar campaignType de reporte 4010
    --   R2. RepOutDialDetailView: revertir a estado K070300 (sin campType)
    --
    -- CAMBIOS PARA 4020:
    --   0. RepOutCallsDetail: nueva columna campType TINYINT NULL
    --   0b. RepOutCallsDetail: nueva columna ModelName VARCHAR(255) NULL
    --   0c. RepOutCallsDetail: nueva columna CapturedData VARCHAR(MAX)
    --   3a. Filters: registrar campaignType en catalogo (idempotente)
    --   3b. ReportsFilters: agregar campaignType para reporte 4020
    --   3c. RepViewOutCallsDetail: exponer campType + reposicionar/renombrar
    --       originNumber a ANI despues de telephone
    --
    -- PROCEDIMIENTOS:
    --   A. ccspRepOutDialDetail: revertir a version K070300 (sin campType)
    --   B. ccspRepOutCallsDetail: agregar campType + ModelName + CapturedData
    --      + [username]='N/A' para CampType=9 (IA) + poblar ReportJsonKeys
    --   C. ccspRepCatalogos: type=39 campaignType + @isJustVoiceFilter
    --      incluye 4010 y 4020
    -- =====================================================================
    SET @process = 'K070305 - ROLLBACK: quitar campaignType de ReportsFilters id=4010'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM ReportsFilters WHERE id = 4010 AND filterName = ''campaignType'')
        DELETE FROM ReportsFilters WHERE id = 4010 AND filterName = ''campaignType''
'
    exec (@sql)

    SET @process = 'K070305 - Garantizar columna IsAICampaign en RepOutDialDetail'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''IsAICampaign'' AND Object_ID = OBJECT_ID(''dbo.RepOutDialDetail''))
        ALTER TABLE dbo.RepOutDialDetail ADD IsAICampaign BIT NULL;
'
    exec (@sql)

    SET @process = 'CW-11078 - Garantizar columna ValidationMode en RepOutDialDetail'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''ValidationMode'' AND Object_ID = OBJECT_ID(''dbo.RepOutDialDetail''))
        ALTER TABLE dbo.RepOutDialDetail ADD ValidationMode VARCHAR(100) NULL;
'
    exec (@sql)

    -- ---------------------------------------------------------------
    -- CW-11078 - Tabla ccoCallsOutSource_ZipCode (CCenterRIA)
    -- Decision de reunion (Marco/Charlie): se separa en tabla propia
    -- en vez de agregar columnas a ccoCallsOutSource (ya sobrecargada).
    -- Estructura confirmada contra AddTableSource_ZipCodeFinal.sql.
    -- ---------------------------------------------------------------
    SET @process = 'CW-11078 - Crear tabla ccoCallsOutSource_ZipCode en CCenterRIA'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM CCenterRIA.sys.tables WHERE name = ''ccoCallsOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
    BEGIN
        CREATE TABLE CCenterRIA.dbo.ccoCallsOutSource_ZipCode (
            callout_id INT NOT NULL,
            zipCode VARCHAR(10) DEFAULT(''''''''),
            isZipCodeValidation BIT DEFAULT(0),

            CONSTRAINT PK_ccoCallsOutSource_ZipCode PRIMARY KEY CLUSTERED (callout_id),
            CONSTRAINT FK_ccoCallsOutSource_ZipCode_Main FOREIGN KEY (callout_id)
                REFERENCES CCenterRIA.dbo.ccoCallsOutSource(callout_id) ON DELETE CASCADE
        );

        CREATE INDEX IX_ccoCallsOutSource_ZipCode_Zip1 ON CCenterRIA.dbo.ccoCallsOutSource_ZipCode(zipCode);
    END
'
    exec (@sql)

    -- ---------------------------------------------------------------
    -- CW-11078 - Exponer ValidationMode en el reporte 4010 (visible).
    -- IsAICampaign NO se agrega aqui: es columna funcional interna del
    -- SP (uso para N/A de Login/CallDisposition), no se muestra en UI.
    -- Posicion: inmediatamente despues de dialType, segun KM28006.
    -- ---------------------------------------------------------------
    SET @process = 'CW-11078 - Agregar ValidationMode a TranslatedReports id=4010'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM TranslatedReports WHERE id = 4010)
       AND CHARINDEX(''ValidationMode'', (SELECT [columns] FROM TranslatedReports WHERE id = 4010)) = 0
        UPDATE TranslatedReports
        SET [columns] = REPLACE([columns], ''dialType|'', ''dialType|ValidationMode|'')
        WHERE id = 4010
'
    exec (@sql)

    SET @process = 'K070305 - ROLLBACK: revertir RepOutDialDetailView sin campType'
    SET @sql = '
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
    ISNULL([IsAICampaign], 0) AS [IsAICampaign]
FROM RepOutDialDetail WITH (NOLOCK);
'
    exec (@sql)

    SET @process = 'K070305 - ADD campType to RepOutCallsDetail'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''campType'' AND Object_ID = OBJECT_ID(''dbo.RepOutCallsDetail''))
        ALTER TABLE dbo.RepOutCallsDetail ADD campType TINYINT NULL;
'
    exec (@sql)

    SET @process = 'K070305 - ADD ModelName to RepOutCallsDetail'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''ModelName'' AND Object_ID = OBJECT_ID(''dbo.RepOutCallsDetail''))
        ALTER TABLE dbo.RepOutCallsDetail ADD ModelName VARCHAR(255) NULL;
'
    exec (@sql)

    SET @process = 'K070305 - ADD CapturedData to RepOutCallsDetail'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''CapturedData'' AND Object_ID = OBJECT_ID(''dbo.RepOutCallsDetail''))
        ALTER TABLE dbo.RepOutCallsDetail ADD CapturedData VARCHAR(MAX) DEFAULT '''';
'
    exec (@sql)

    SET @process = 'K070305 - Filters campaignType catalogo maestro'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM Filters WHERE name = ''campaignType'')
    BEGIN
        DECLARE @nextFilterId INT
        SELECT @nextFilterId = MAX(id) + 1 FROM Filters

        INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode)
        VALUES (@nextFilterId, ''campaignType'', @nextFilterId, ''CampaignTypes'', ''CampaignType'')
    END
'
    exec (@sql)

    SET @process = 'K070305 - ReportsFilters campaignType para id=4020'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE id = 4020 AND filterName = ''campaignType'')
    BEGIN
        INSERT INTO ReportsFilters (id, reportName, filterName)
        VALUES (4020, ''Answered Calls Detail'', ''campaignType'')
    END
'
    exec (@sql)

    SET @process = 'K070305 - ALTER VIEW RepViewOutCallsDetail (campType + ANI)'
    SET @sql = '
ALTER VIEW [dbo].[RepViewOutCallsDetail] AS
SELECT
    [date],
    [callKey],
    [telephone],
    [originNumber] AS [ANI],
    [transfer]     AS transferTime,
    [queueTimes],
    [ringingTime],
    [dialog],
    [nque],
    [wrapup],
    [CallDisposition],
    [subDisposition],
    [callbackDate],
    [extension],
    [userId],
    [login]        [agentName],
    [username]     [login],
    [campaign],
    [ModelName],
    [duration],
    [ncost],
    [iva],
    [total]        AS [totalRow],
    [ByCarrier],
    [Calltypes],
    [dialType],
    [whoHangUp],
    [dialResult]   AS [callStatus],
    [calId],
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    [trunk],
    [CapturedData],
    [data1]        [Dato1],
    [data2]        [Dato2],
    [data3]        [Dato3],
    [data4]        [Dato4],
    [data5]        [Dato5],
    [MessageTime],
    [grabId],
    [campaignId],
    [areaId],
    [area],
    [callStatusId],
    ISNULL([campType], 0) AS [campType]
FROM RepOutCallsDetail WITH (NOLOCK);
'
    exec (@sql)

    SET @process = 'K070305 - DROP ccspRepOutDialDetail'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepOutDialDetail'')
    begin
            DROP PROCEDURE ccspRepOutDialDetail;
    end'
    exec (@sql)

    SET @process = 'CW-11078 - CREATE ccspRepOutDialDetail (base real 192.168.1.58 + ValidationMode + IsAICampaign)'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccspRepOutDialDetail]
    @action AS TINYINT,
    @from   AS DATETIME = NULL,
    @to     AS DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @from IS NULL SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));
    IF @to   IS NULL SELECT @to   = GETDATE();

    IF @action = 1
    BEGIN
        DECLARE @country SMALLINT;
        SELECT @country = valor FROM ccSettings WHERE setting_id = 104;

        DELETE FROM RepOutDialDetail WHERE [date] >= @from AND [date] < @to;

        IF OBJECT_ID(''tempdb..#dials'')           IS NOT NULL DROP TABLE #dials;
        IF OBJECT_ID(''tempdb..#codeSip'')         IS NOT NULL DROP TABLE #codeSip;
        IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip;

        CREATE TABLE #dials
        (
            logDial_id         INT          NOT NULL,
            callout_id         INT          NOT NULL,
            cam_id             INT          NOT NULL,
            tipoResDial_id     SMALLINT     NOT NULL,
            resultDialDesc     VARCHAR(50)  NOT NULL,
            Telefono           VARCHAR(30)  NOT NULL,
            Puerto             SMALLINT     NOT NULL,
            fecha              DATETIME     NOT NULL,
            tDialing           SMALLINT     NOT NULL,
            dialType           VARCHAR(50)  NULL,
            tBusy              SMALLINT     NOT NULL,
            answerbit          BIT          NULL,
            canceledNoAgents   BIT          NULL,
            cal_id             INT          NOT NULL,
            disconnectCause    VARCHAR(250) NOT NULL,
            cal_key            VARCHAR(40)  NULL,
            file_moved         TINYINT      NULL,
            tipoLlamada_id     SMALLINT     NULL,
            CallDisposition    VARCHAR(150) NULL,
            CallDisposition_IA VARCHAR(150) NULL,
            califSubDesc       VARCHAR(150) NULL,
            codeSip            VARCHAR(3)   NOT NULL,
            TipoTel            VARCHAR(30)  NOT NULL,
            tpreview           SMALLINT     NOT NULL,
            UserID             SMALLINT     NOT NULL,
            virtualAgentId     INT          NOT NULL,
            ani                VARCHAR(32)  NOT NULL,
            CapturedData       VARCHAR(MAX) NOT NULL
        )

        INSERT INTO #dials
        (
            logDial_id, callout_id, cam_id, tipoResDial_id, resultDialDesc,
            Telefono, Puerto, fecha, tDialing, dialType, tBusy, answerbit,
            canceledNoAgents, cal_id, disconnectCause, cal_key, file_moved,
            tipoLlamada_id, CallDisposition, califSubDesc, codeSip, TipoTel,
            tpreview, UserID, virtualAgentId, ani, CapturedData, CallDisposition_IA
        )
        SELECT
              dial.logDial_id
            , dial.callout_id
            , dial.cam_id
            , CASE
                  WHEN co.statusCall_Id = 20 THEN 15
                  WHEN dial.canceledNoAgents = 1 THEN 14
                  ELSE dial.tipoResDial_id
              END AS tipoResDial_id
            , CASE
                  WHEN co.statusCall_Id = 20 THEN ''systemTranslated_QuantumVoicemail''
                  ELSE ISNULL(tr.descTranslate,'''')
              END AS resultDialDesc
            , dial.Telefono AS cal_telefono
            , dial.Puerto
            , dial.fecha
            , ISNULL(co.cal_tDialog, 0) AS cal_tDialog
            , CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview''
                   WHEN SUBSTRING(dial.TipoDialingMode, 2, 1) = ''1'' AND co.cal_manual = 0 THEN ''systemTranslated_Assisted''
                   WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
                   WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto''
                   WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(dial.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
                   WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType
            , dial.tBusy
            , dial.answerbit
            , dial.canceledNoAgents
            , ISNULL(dial.cal_id,0) AS cal_id
            , dial.disconnectCause
            , co.cal_key
            , co.file_moved
            , dial.tipoLlamada_id
            , tco.[Description] AS CallDisposition
            , tsco.califSubDesc
            , CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END AS codeSip
            , CASE
                  WHEN @country<>1 THEN ''''
                  WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo''
                  WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone''
                  ELSE ''systemTranslated_Indefinite''
              END AS TipoTel
            , ISNULL(regp.tPreview,0) AS tpreview
            , ISNULL(co.User_id,0) AS UserID
            , ISNULL(co.virtualAgentId,0) AS virtualAgentId
            , dial.ani
            , ISNULL(codia.CapturedData,'''') AS CapturedData
            , CASE
                  WHEN co.statusCall_Id = 20 THEN ''Buzón de voz''
                  ELSE ISNULL(tc_ia.Name_cal,''N/A'')
              END AS CallDisposition_IA
        FROM ccoLogDials dial (NOLOCK)
        LEFT JOIN ccoCallsOut co (NOLOCK) ON dial.cal_id = co.cal_id
        LEFT JOIN ccTipoCalifOUT tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
        LEFT JOIN cctipoCalif_IA tc_ia WITH (NOLOCK) ON tc_ia.calif_id = co.calif_id
        LEFT JOIN ccTipoCalifSubOUT tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
        LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK)
            ON regp.callout_id = co.callout_id AND regp.callId = co.cal_id
        LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dial.tipoResDial_id = tr.tipoResDial_id
        LEFT JOIN ccoCallsOutDispositionIA codia (NOLOCK) ON codia.call_id = dial.cal_id
        WHERE dial.fecha >= @from AND dial.fecha < @to

        UNION

        SELECT
              0                              AS logDial_id
            , reg.callout_id                 AS callout_id
            , reg.camId                      AS cam_id
            , CONVERT(SMALLINT, reg.process) AS tipoResDial_id
            , ISNULL(cctyp.translatedDesc,'''') AS resultDialDesc
            , ISNULL(ccoa.cal_telefono,'''')   AS cal_telefono
            , 0                              AS Puerto
            , reg.reg_date                   AS fecha
            , 0                              AS tDialing
            , ''systemTranslated_Preview''     AS dialType
            , 0                              AS tBusy
            , CONVERT(BIT, 0)                AS answerbit
            , CONVERT(BIT, 0)                AS canceledNoAgents
            , 0                              AS cal_id
            , ''''                             AS disconnectCause
            , NULL                           AS cal_key
            , CONVERT(TINYINT, 0)            AS file_moved
            , NULL                           AS tipoLlamada_id
            , ''''                             AS CallDisposition
            , ''''                             AS califSubDesc
            , ''''                             AS codeSip
            , ''''                             AS TipoTel
            , reg.tPreview                   AS tpreview
            , reg.userId                     AS UserID
            , ISNULL(ccoa.virtualAgentId,0) AS virtualAgentId
            , ''''                             AS ani
            , ''''                             AS CapturedData
            , ''N/A''                          AS CallDisposition_IA
        FROM RegProcessPreviewRecord reg (NOLOCK)
        LEFT JOIN ccoCallsOut ccoa (NOLOCK)
            ON reg.callout_id = ccoa.callout_id
        LEFT JOIN ccTypeProcessPreview cctyp (NOLOCK)
            ON cctyp.typeProcess_id = reg.process
        WHERE reg.reg_date >= @from AND reg.reg_date < @to
          AND reg.process NOT IN (5,7,13,14)

        CREATE NONCLUSTERED INDEX IX_#dials_logDial_id
        ON #dials(logDial_id)

        CREATE NONCLUSTERED INDEX IX_#dials_callout_id
        ON #dials(callout_id)

        SELECT DISTINCT
              CAST(codeSip AS INT) AS codeSip
            , disconnectCause
        INTO #codeSip
        FROM #dials
        WHERE codeSip <> ''''
          AND ISNUMERIC(codeSip) = 1

        SELECT
              A.codeSip
            , A.disconnectCause
            , B.[description]
        INTO #relationCodeSip
        FROM #codeSip A
        INNER JOIN DC_Extra B ON A.codeSip = B.id

        INSERT INTO RepOutDialDetail(
            [date], [calId], [callKey], [telephone], [dialResultId], [dialResult],
            [dialog], [campaignId], [campaign], [ModelName], [timeMessage],
            [year], [month], [day], [hour], [minutes], [listName], [billed],
            [data1], [data2], [data3], [data4], [data5],
            [fileMoved], [disconnectCause], [DCCustomer], [dialType], [TipoTel],
            [CallDisposition], [CallSubDisposition],
            [data6], [data7], [data8], [data9], [data10],
            [data11], [data12], [data13], [data14], [data15],
            [preview_Time], [login], [areaId], [area], [ani], [CapturedData],
            [ValidationMode], [IsAICampaign]
        )
            SELECT
                 fecha AS [date]
                 ,cal_id
                ,CASE
                    WHEN dials.cal_key IS NULL AND cs.cal_key IS NULL THEN ''''
                    WHEN dials.cal_key IS NOT NULL THEN dials.cal_key
                    ELSE cs.cal_key
                 END AS cal_key
                ,ISNULL(dials.Telefono,'''') AS telephone
                ,dials.tipoResDial_id        AS tiporesdialId
                ,CASE
                    WHEN dials.tipoResDial_id = 14 THEN
                        CASE
                            WHEN camps.campType = 6 THEN ''systemTranslated_CancelledByEngaged''
                            ELSE ''systemTranslated_CancelledBySystem''
                        END
                    ELSE ISNULL(dials.resultDialDesc, '''')
                 END AS dialResult
                ,tDialing
                ,ISNULL(dials.cam_id,'''')   AS campaignId
                ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),''systemTranslated_NoCampaign'') AS campaign
                ,ISNULL(va.nameAgent,''NA'') AS ModelName
                ,dials.tbusy                 AS timeMessage
                ,DATEPART(yyyy, fecha)       AS year
                ,DATEPART(mm,   fecha)       AS month
                ,DATEPART(dd,   fecha)       AS day
                ,DATEPART(hh,   fecha)       AS hour
                ,DATEPART(mi,   fecha)       AS minutes
                ,ISNULL(rl.[name], '''')     AS listName
                ,CASE
                    WHEN answerbit = 1 THEN ''systemTranslated_Charged''
                    ELSE ''systemTranslated_NotCharged''
                 END AS billed
                ,ISNULL(ldd.Data1, ISNULL(cs.Dato1, '''')) AS data1
                ,ISNULL(ldd.Data2, ISNULL(cs.Dato2, '''')) AS data2
                ,ISNULL(ldd.Data3, ISNULL(cs.Dato3, '''')) AS data3
                ,ISNULL(ldd.Data4, ISNULL(cs.Dato4, '''')) AS data4
                ,ISNULL(ldd.Data5, ISNULL(cs.Dato5, '''')) AS data5
                ,CASE
                    WHEN dials.file_moved = 1 THEN ''systemTranslated_Remoto''
                    WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
                    ELSE ''systemTranslated_Local''
                 END AS fileMoved
                ,dials.disconnectCause
                ,case when dat.[description] is not null then dat.[description] when  tr.descTranslate is not null then tr.descTranslate else ''N/A'' END AS DCCustomer
                ,dials.dialType
                ,TipoTel
                ,CASE
                    WHEN camps.campType = 9 THEN dials.CallDisposition_IA
                    ELSE ISNULL(CallDisposition, ''N/A'')
                END AS CallDisposition
                ,ISNULL(califSubDesc, ''N/A'')       AS CallSubDisposition
                ,ISNULL(csP.Dato6,  '''')            AS data6
                ,ISNULL(csP.Dato7,  '''')            AS data7
                ,ISNULL(csP.Dato8,  '''')            AS data8
                ,ISNULL(csP.Dato9,  '''')            AS data9
                ,ISNULL(csP.Dato10, '''')            AS data10
                ,ISNULL(csP.Dato11, '''')            AS data11
                ,ISNULL(csP.Dato12, '''')            AS data12
                ,ISNULL(csP.Dato13, '''')            AS data13
                ,ISNULL(csP.Dato14, '''')            AS data14
                ,ISNULL(csP.Dato15, '''')            AS data15
                ,dials.tpreview                     AS preview_Time
                ,CASE
                    WHEN camps.CampType = 9 THEN ''N/A''
                    ELSE ISNULL(us.[Login],''N/A'')
                 END AS [Login]
                ,ISNULL(ar.IDArea, 1)               AS areaId
                ,ISNULL(ar.AreaName,''Default'')    AS area
                ,dials.ani                        AS ani
                ,CASE
                    WHEN dials.CapturedData = '''' THEN ''N/A''
                    ELSE dials.CapturedData
                 END AS CapturedData
                ,CASE
                    WHEN cs_zip.isZipCodeValidation = 1
                         AND ISNULL(LTRIM(RTRIM(cs_zip.zipCode)), '''') <> ''''
                    THEN ''filterValidation_'' + LTRIM(RTRIM(cs_zip.zipCode))
                    ELSE ''COFETEL''
                 END AS ValidationMode
                ,CASE WHEN camps.CampType = 9 THEN 1 ELSE 0 END AS IsAICampaign
        FROM #dials AS dials
        LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON dials.callout_id = cs.callout_id
        LEFT JOIN ccoLogDialsData   ldd (NOLOCK) ON ldd.logDial_id   = dials.logDial_id
        LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dials.tipoResDial_id = tr.tipoResDial_id
        LEFT JOIN ccCamps           camps (NOLOCK) ON camps.cam_id    = dials.cam_id
        LEFT JOIN ccVirtualAgent va (NOLOCK) ON va.idAgent = dials.virtualAgentId
        LEFT JOIN ccRIARegistryLists rl (NOLOCK) ON cs.list_id        = rl.list_id
        LEFT JOIN #relationCodeSip  dat           ON dat.disconnectCause = dials.disconnectCause
        LEFT JOIN ccoCallsPreviewData csP         ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
        LEFT JOIN ccUsers           us  (NOLOCK)  ON us.User_id       = dials.UserID
        LEFT JOIN ccRIACat_Areas    ar  (NOLOCK)  ON ar.IDArea        = camps.IDArea
        LEFT JOIN CCenterRIA.dbo.ccoCallsOutSource_ZipCode cs_zip
            ON cs_zip.callout_id = dials.callout_id

        IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
        IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip
        IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip

        -- ---------------------------------------------------------------
        -- Poblar ReportJsonKeys (reporte 4010) con las llaves del JSON de
        -- CapturedData (restaurado desde ServicesPack11; ver CW-11078).
        -- ---------------------------------------------------------------
        declare @processsId int = 4010

        DELETE FROM dbo.ReportJsonKeys
        WHERE id = @processsId
        AND ReportDate between @from and @to

        INSERT INTO dbo.ReportJsonKeys (id, ReportDate, JsonKey)
        SELECT
         @processsId as reportName,
         CONVERT(date,d.[date],121) as reportDate,
         j.[key]
         FROM dbo.RepOutDialDetail d
         CROSS APPLY OPENJSON(d.CapturedData) j
         WHERE d.[Date] >= @from
           AND d.[Date] < @to
           AND d.CapturedData IS NOT NULL
           AND d.CapturedData <> ''''
           AND d.CapturedData <> ''NULL''
           AND ISJSON(d.CapturedData) = 1
         GROUP BY j.[key],CONVERT(date,d.[date],121)
    END
END
'
    exec (@sql)

    SET @process = 'K070305 - DROP ccspRepOutCallsDetail'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepOutCallsDetail'')
    begin
            DROP PROCEDURE ccspRepOutCallsDetail;
    end'
    exec (@sql)

    SET @process = 'K070305 - CREATE ccspRepOutCallsDetail (campType + ModelName + CapturedData + ReportJsonKeys)'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccspRepOutCallsDetail]
    @action AS TINYINT,
    @from   AS DATETIME = NULL,
    @to     AS DATETIME = NULL
AS
    IF @from IS NULL
        SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

    IF @to IS NULL
        SELECT @to = GETDATE();

    DECLARE @IVA INT, @IVAstring VARCHAR(5);
    DECLARE @country AS TINYINT;

    SELECT @IVA = CONVERT(INT, ISNULL(valor, 0))
    FROM ccsettings
    WHERE setting_id = 25;

    SELECT @IVAstring = CONVERT(VARCHAR(5), @IVA) + ''%'';

    SELECT @country = CONVERT(TINYINT, ISNULL(valor, 1))
    FROM ccsettings
    WHERE setting_id = 104;

    IF @country IS NULL
        SET @country = 1;

    IF @action = 1
    BEGIN
        DELETE FROM RepOutCallsDetail WITH (ROWLOCK)
        WHERE DATE >= @from
          AND DATE <  @to;

        INSERT INTO dbo.RepOutCallsDetail
        (
            [date], [callKey], [telephone], [transfer], [dialog], [nque], [wrapup],
            [CallDisposition], [extension], [userId], [login], [username],
            [campaignId], [campaign], [ModelName], [duration], [ncost], [iva], [total],
            [ByCarrier], [Calltypes], [dialType], [whoHangUp], [subDisposition],
            [dialResult], [calId], [year], [month], [day], [hour], [minutes],
            [trunk], [data1], [data2], [data3], [data4], [data5],
            [MessageTime], [grabId], [areaId], [area],
            originNumber, callbackDate, queueTimes, ringingTime,
            callStatusId, [campType], [CapturedData]
        )
        SELECT
            Call.cal_inicio AS [date],
            Call.cal_key AS [callKey],
            Call.cal_telefono AS [telephone],
            Call.cal_txfer + Call.cal_tring AS [transfer],
            Call.cal_tdialog AS [dialog],
            ISNULL(Call.cal_tMoh, 0) AS [nque],
            Call.cal_tnotas AS [wrapup],
            ISNULL(Tipo.[description], '''') AS [CallDisposition],
            Call.cal_extension AS [extension],
            ISNULL(Usr.user_id, 0) AS [userId],
            ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [login],
            CASE
                WHEN camps.CampType = 9 THEN ''N/A''
                ELSE ISNULL(CONVERT(VARCHAR(255), Usr.[LOGIN]), ''systemTranslated_NoUserName'')
            END AS [username],
            camps.cam_id AS [campaignId],
            ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
            ISNULL(va.nameAgent, ''NA'') AS [ModelName],
            (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
            CONVERT(DECIMAL(10, 2), dbo.fnGetCstoTarifa(
                Call.tipoLlamada_id,
                Call.provedor_id,
                (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),
                @country
            )) AS [ncost],
            @IVAstring AS iva,
            CONVERT(DECIMAL(10, 2), dbo.fnGetCstoTarifa(
                Call.tipoLlamada_id,
                Call.provedor_id,
                (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),
                @country
            ) * (1 + (@IVA / 100.00))) AS total,
            CASE
                WHEN prov.descrip IS NOT NULL THEN prov.descrip
                ELSE ''systemTranslated_NoCarrier''
            END AS [ByCarrier],
            CASE
                WHEN @country <> 1 THEN ''''
                WHEN ld.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo''
                WHEN ld.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone''
                ELSE ''systemTranslated_Indefinite''
            END AS [Calltypes],
            CASE
                WHEN ld.TipoDialingMode = ''100000000''  THEN ''systemTranslated_Preview''
                WHEN SUBSTRING(ld.TipoDialingMode, 2, 1) = ''1'' AND Call.cal_manual = 0 THEN ''systemTranslated_Assisted''
                WHEN ld.TipoDialingMode IN (''00001000'',''00010000'', ''000010000'') THEN ''systemTranslated_Callback''
                WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto''
                WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(ld.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
                WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual''
                WHEN ld.TipoDialingMode = ''000000000'' THEN ''systemTranslated_Auto''
                ELSE ''''
            END AS [dialType],
            CASE
                WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client''
                WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent''
                ELSE ''systemTranslated_AgentSurvey''
            END AS [whoHangUp],
            CASE
                WHEN Call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition''
                ELSE ISNULL(sub.califSubDesc, '''')
            END AS [subDisposition],
            ISNULL(sta.descTranslated,'''') AS [dialResult],
            Call.cal_id AS [calId],
            DATEPART(yyyy, Call.cal_inicio) AS [year],
            DATEPART(mm,   Call.cal_inicio) AS [month],
            DATEPART(dd,   Call.cal_inicio) AS [day],
            DATEPART(hh,   Call.cal_inicio) AS [hour],
            DATEPART(mi,   Call.cal_inicio) AS [minutes],
            Call.cal_puerto,
            ISNULL(cod.Data1, ISNULL(cs.Dato1, '''')) AS [data1],
            ISNULL(cod.Data2, ISNULL(cs.Dato2, '''')) AS [data2],
            ISNULL(cod.Data3, ISNULL(cs.Dato3, '''')) AS [data3],
            ISNULL(cod.Data4, ISNULL(cs.Dato4, '''')) AS [data4],
            ISNULL(cod.Data5, ISNULL(cs.Dato5, '''')) AS [data5],
            ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
            ISNULL(rc.grab_id, 0) AS grabId,
            camps.IDArea AS [areaId],
            ar.AreaName AS [area],
            ld.ani AS originNumber,
            Call.cal_fcallback AS callbackDate,
            cal_que AS queueTimes,
            Call.cal_txfer + Call.cal_tring
                + CASE WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ld.tDialing ELSE 0 END
                AS ringingTime,
            Call.statusCall_id AS callStatusId,
            CASE
                WHEN camps.CampType = 9 THEN CAST(9 AS TINYINT)
                WHEN camps.CampType = 6 THEN CAST(6 AS TINYINT)
                ELSE                         CAST(0 AS TINYINT)
            END AS campType,
            ISNULL(codia.CapturedData, '''') AS CapturedData
        FROM ccoCallsOut Call (NOLOCK)
        LEFT JOIN ccoLogDials       ld    (NOLOCK) ON Call.cal_id        = ld.cal_id
        LEFT JOIN ccTipoCalifOUT    Tipo  (NOLOCK) ON Call.calif_id      = Tipo.calif_id
        LEFT JOIN ccUserView        Usr   (NOLOCK) ON Usr.[user_id]      = Call.[user_id]
        LEFT JOIN ccCamps           camps (NOLOCK) ON camps.[cam_id]     = Call.[cam_id]
        LEFT JOIN ccVirtualAgent    va    (NOLOCK) ON va.idAgent         = Call.virtualAgentId
        LEFT JOIN ccStatusLlamada   sta   (NOLOCK) ON Call.statuscall_id = sta.statuscall_id
        LEFT JOIN cstoProvedor      prov  (NOLOCK) ON prov.[provedor_id] = Call.[provedor_id]
        LEFT JOIN cstoTipoLlamada   tl    (NOLOCK) ON tl.[tipoLlamada_id] = ld.[tipoLlamada_id]
                                                  AND tl.Country_id       = @country
        LEFT JOIN ccTipoCalifSubOut sub   (NOLOCK) ON Call.califsub_id   = sub.califsub_id
        LEFT JOIN ccoDialers        di    (NOLOCK) ON di.dialer_id       = Call.cal_puerto
                                                  AND Call.provedor_id   = di.provedor_id
        LEFT JOIN ccoCallsOutSource cs    (NOLOCK) ON Call.callout_id    = cs.callout_id
        LEFT JOIN ccoCallsOutData   cod   (NOLOCK) ON cod.cal_id         = Call.cal_id
        LEFT JOIN ccCallCost_RIA    cc    (NOLOCK) ON cc.country_id      = tl.country_id
                                                  AND cc.tipoLlamada_id  = tl.tipoLlamada_id
        LEFT JOIN Ria_grabacion     rc    (NOLOCK) ON rc.cal_id          = Call.cal_id
                                                  AND rc.tipo_llamada    = 2
        LEFT JOIN dbo.ccRIACat_Areas AS ar (NOLOCK) ON ar.IDArea         = camps.IDArea
        LEFT JOIN ccoCallsOutDispositionIA codia (NOLOCK) ON codia.call_id = Call.cal_id
        WHERE Call.cal_inicio >= @from
          AND Call.cal_inicio <  @to
          AND Call.cal_manual IN (0, 2)
          AND ld.TipoDialingMode IS NOT NULL
        ORDER BY DATE;

        -- ---------------------------------------------------------------
        -- Poblar ReportJsonKeys (reporte 4020) con las llaves del JSON de
        -- CapturedData, mismo patron usado por ccspRepInCallsDetail (3010)
        -- para habilitar el patron de columnas dinamicas _Ex en el
        -- reporte C# (CapturedDataDetailReport.EnsureDbJsonKeys).
        -- ---------------------------------------------------------------
        DECLARE @processId INT = 4020;

        DELETE FROM dbo.ReportJsonKeys
        WHERE id = @processId
          AND ReportDate BETWEEN @from AND @to;

        INSERT INTO dbo.ReportJsonKeys (id, ReportDate, JsonKey)
        SELECT
            @processId AS id,
            CONVERT(DATE, d.[date], 121) AS ReportDate,
            j.[key]
        FROM dbo.RepOutCallsDetail d
        CROSS APPLY OPENJSON(d.CapturedData) j
        WHERE d.[date] >= @from
          AND d.[date] <  @to
          AND d.CapturedData IS NOT NULL
          AND d.CapturedData <> ''''
          AND d.CapturedData <> ''NULL''
          AND ISJSON(d.CapturedData) = 1
        GROUP BY j.[key], CONVERT(DATE, d.[date], 121);
    END
'
    exec (@sql)

    SET @process = 'K070305 - DROP ccspRepCatalogos'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCatalogos'')
    begin
            DROP PROCEDURE ccspRepCatalogos;
    end'
    exec (@sql)

    SET @process = 'K070305 - CREATE ccspRepCatalogos (type=39 campaignType)'
    SET @sql = '
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
    DECLARE @condition    NVARCHAR(300) = ''''
    DECLARE @columnName   NVARCHAR(100) = ''''
    DECLARE @consult      NVARCHAR(2000) = ''''

    IF @action = 0
    BEGIN
        IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
        BEGIN
            CREATE TABLE #filters ([Type] VARCHAR(200))
        END

        -- CAMPAIGNS
        IF @type = 1
        BEGIN
            INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
            IF EXISTS (SELECT * FROM #filters)
            BEGIN
                SET @condition  = '' WHERE camp.campType IN (SELECT * FROM #filters)''
                SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
            END
            ELSE BEGIN
                SET @columnName = ''campaignId''
            END

            SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

            IF @userId <> 0
            BEGIN
                DECLARE @isJustVoiceFilter BIT = CASE WHEN @menuId IN (4010, 4020) THEN 1 ELSE 0 END

                SET @SQL = '' DECLARE @tablatemp TABLE (id INT, description VARCHAR(100) NULL)
                    INSERT INTO @tablatemp
                    SELECT DISTINCT caesp.IdCampEsp, '''''''' AS description FROM ccUserView us
                    INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                    INNER JOIN ccRIACampEspWG caesp ON wgu.IDWG = caesp.IDWG AND caesp.Tipo=1''

                IF @isJustVoiceFilter = 1
                BEGIN
                    SET @SQL += '' INNER JOIN dbo.cccamps AS c ON caesp.IdCampEsp = c.cam_id''
                END

                SET @SQL += '' WHERE us.[User_id] = @userId''

                IF @isJustVoiceFilter = 1
                BEGIN
                    SET @SQL += '' AND c.CampType IN (0,6,9)''
                END

                SET @SQL += '' IF EXISTS(SELECT 1 FROM @tablatemp) BEGIN ''
                    + @consult + '' INNER JOIN @tablatemp A ON camp.cam_id = A.id '' + @condition
                    + '' END
                    ELSE BEGIN
                        SELECT 0 AS id, ''''N/A'''' AS description, ''''campaignId'''' AS dbColumn
                    END''
            END
            ELSE BEGIN
                SET @SQL = @consult + @condition
            END
            EXEC sp_executesql @SQL, N''@userId AS INT = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName
        END

        -- DIAL RESULTS
        IF @type = 2
        BEGIN
            SELECT tiporesdial_id AS id, descripcion AS description, ''dialResultId'' AS dbColumn
            FROM ccTipoResultadoDial
            ORDER BY descripcion
        END

        -- WORKGROUPS
        IF @type = 3
        BEGIN
            IF @userId <> 0
            BEGIN
                SELECT v.IDWG AS id, c.WGName AS description, ''workgroupId'' AS dbColumn
                FROM ccWgByAcdView v
                INNER JOIN ccriacat_workgroup c ON c.IDWG = v.IDWG
                WHERE USER_ID = @userId
                RETURN
            END
            ELSE BEGIN
                SELECT idwg AS id, wgname AS description, ''workgroupId'' AS dbColumn
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

                SELECT DISTINCT idArea AS id, ISNULL(AreaName, ''S/AREA'') AS description, ''areaId'' AS dbColumn
                FROM ccRIACat_Areas area INNER JOIN @tablatemp tem ON area.IDArea = tem.id
                RETURN
            END
            ELSE BEGIN
                SELECT idArea AS id, AreaName AS description, ''areaId'' AS dbColumn
                FROM ccRIACat_Areas
                GROUP BY idArea, AreaName
                ORDER BY AreaName
            END
        END

        -- DISPOSITIONS OUT
        IF @type = 5
        BEGIN
            SELECT calif_id AS id, [description] AS description, ''dispositionId'' AS dbColumn
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

                SELECT DISTINCT us.User_id AS id, us.Login AS description, ''userId'' AS dbcolumn FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                INNER JOIN @tempwork awg ON wgu.IDWG = awg.idwg
                WHERE us.TipoUser_id = 1 AND [status] = 1
                RETURN
            END
            ELSE BEGIN
                SELECT [user_id] AS id, [login] AS description, ''userId'' AS dbColumn
                FROM ccUserView WHERE [status] = 1 AND TipoUser_id = 1
                ORDER BY description
            END
        END

        -- ACDS
        IF @type = 7
        BEGIN
            INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
            IF EXISTS (SELECT * FROM #filters)
            BEGIN
                SET @condition  = '' WHERE B.chat IN (SELECT * FROM #filters)''
                SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
            END
            ELSE BEGIN
                SET @columnName = ''inboundId''
            END

            SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn FROM ccInbound B''

            IF @userId <> 0
            BEGIN
                SET @SQL = '' DECLARE @tablatemp TABLE (id INT, description VARCHAR(100) NULL)
                    INSERT INTO @tablatemp
                    SELECT DISTINCT caesp.IdCampEsp, '''''''' AS description FROM ccUserView us
                    INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                    INNER JOIN ccRIACampEspWG caesp ON wgu.IDWG = caesp.IDWG AND caesp.Tipo=0
                    WHERE us.[User_id] = @userId;''
                    + '' IF EXISTS(SELECT 1 FROM @tablatemp) BEGIN''
                    + @consult + '' INNER JOIN @tablatemp A ON B.inbound_id = A.id'' + @condition + '' RETURN;''
                    + '' END
                    ELSE BEGIN
                        SELECT 0 AS id, ''''N/A'''' AS description, ''''inboundId'''' AS dbColumn
                    END''
            END
            ELSE BEGIN
                SET @SQL = @consult + @condition
            END
            EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName
        END

        -- DIDS
        IF @type = 8
        BEGIN
            SELECT 0 AS id, ''S/DNIS'' AS description, ''dnisId'' AS dbColumn
            UNION
            SELECT dni_id AS id, CASE WHEN dni_Descripcion = '''' THEN CONVERT(VARCHAR, dni_numero) ELSE dni_Descripcion END AS description, ''dnisId'' AS dbColumn
            FROM ccdnis
        END

        -- DISPOSITIONS IN
        IF @type = 9
        BEGIN
            SELECT calif_id AS id, [description] AS description, ''dispositionId'' AS dbColumn
            FROM ccTipoCalif
            ORDER BY [description]
        END

        -- SUBDISPOSITIONS IN
        IF @type = 10
        BEGIN
            SELECT califSub_id AS id, [califSubDesc] AS description, ''subDispositionId'' AS dbColumn
            FROM ccTipoCalifSub
            ORDER BY [description]
        END

        -- PROVIDER
        IF @type = 11
        BEGIN
            SELECT proveedor_id AS id, descrip AS description, ''providerId'' AS dbColumn
            FROM cstoProveedor
            ORDER BY [description]
        END

        -- UNAVAILABLES
        IF @type = 12
        BEGIN
            SELECT tiponotready_id AS id, descripcion AS description, ''tiponotreadyId'' AS dbColumn
            FROM cctiponotready
            ORDER BY descripcion
        END

        -- DIALERS
        IF @type = 13
        BEGIN
            SELECT dialer_id AS id, descripcion AS description, ''dialerId'' AS dbColumn
            FROM ccoDiaers
            ORDER BY descripcion
        END

        -- CALL TYPES
        IF @type = 14
        BEGIN
            SELECT statusCall_id AS id, descripcion AS description, ''callStatusId'' AS dbColumn
            FROM ccStatusLlamada
            ORDER BY descripcion
        END

        -- AVRS TEMPLATE-SECTION
        IF @type = 15
        BEGIN
            SELECT fc.id AS id, (rf.nombre + '' '' + rc.con_descripcion) + '' '' + CONVERT(VARCHAR(10), fc.id) AS description, ''templateSectionId'' AS dbColumn
            FROM RIA_FORMATOCONCEPTO fc
            INNER JOIN (SELECT id_formato, nombre, MAX(version) AS version FROM RIA_FORMATOS WHERE activo = 1 GROUP BY id_formato, nombre) AS rf ON rf.id_formato = fc.templateId
            INNER JOIN RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
            ORDER BY fc.id
        END

        -- AVRS TEMPLATES
        IF @type = 16
        BEGIN
            SELECT f.id_formato AS id, f.nombre AS description, ''templateId'' AS dbColumn
            FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato, MAX(version) AS version FROM RIA_FORMATOS WHERE activo = 1 GROUP BY id_formato) AS t
            ON f.id_formato = t.id_formato AND f.version = t.version
            ORDER BY f.nombre
        END

        -- AVRS SUPERVISOR
        IF @type = 17
        BEGIN
            SELECT [user_id] AS id, [login] AS description, ''supervisorId'' AS dbColumn
            FROM ccUserView
            WHERE [status] = 1 AND TipoUser_id = 2
            ORDER BY [login]
        END

        -- AVRS SECTIONS
        IF @type = 31
        BEGIN
            SELECT c.id_concepto AS id, c.con_descripcion AS description, ''sectionId'' AS dbColumn
            FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto, MAX(version) AS version FROM RIA_CONCEPTOS GROUP BY id_concepto) AS t
            ON c.id_concepto = t.id_concepto AND c.version = t.version
            ORDER BY c.con_descripcion
        END

        -- AVRS QUESTIONS
        IF @type = 23
        BEGIN
            SELECT p.id_pregunta AS id, p.enunciado_pregunta AS description, ''questionId'' AS dbColumn
            FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta FROM RIA_PREGUNTAS GROUP BY id_pregunta) AS t ON p.id_pregunta = t.id_pregunta
            ORDER BY p.enunciado_pregunta
        END

        -- AVRS QUESTIONS CHAT
        IF @type = 24
        BEGIN
            SELECT p.id_pregunta AS id, p.enunciado_pregunta AS description, ''questionId'' AS dbColumn
            FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta FROM RIA_PREGUNTAS GROUP BY id_pregunta) AS t ON p.id_pregunta = t.id_pregunta
            ORDER BY p.enunciado_pregunta
        END

        -- STATUS CALL
        IF @type = 25
        BEGIN
            SELECT statusCall_id AS id, [descripcion] AS description, ''statusCallId'' AS dbcolumn
            FROM ccstatusLlamada
            ORDER BY [descripcion]
        END

        -- SURVEY
        IF @type = 26
        BEGIN
            SELECT surveyId AS id, [description] AS description, ''surveyId'' AS dbcolumn
            FROM Survey
            ORDER BY [description]
        END

        -- DIAL TYPE
        IF @type = 29
        BEGIN
            SELECT dialId AS id, [description] AS description, ''dialId'' AS dbcolumn
            FROM dialType
            ORDER BY [description]
        END

        -- DIALS
        IF @type = 30
        BEGIN
            SELECT id AS id, [description] AS description, ''dialId'' AS dbcolumn
            FROM Dials
            ORDER BY [description]
        END

        -- INBOUND CHAT CAMPAIGNS
        IF @type = 33
        BEGIN
            IF @userId <> 0
            BEGIN
                INSERT INTO @tablatemp
                SELECT DISTINCT caesp.IdCampEsp, '''' AS description FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                INNER JOIN ccRIACampEspWG caesp ON wgu.IDWG = caesp.IDWG AND caesp.Tipo=0
                INNER JOIN ccInbound i ON caesp.IdCampEsp = i.Inbound_id AND i.chat IN (0,11)
                WHERE us.[User_id] = @userId

                SELECT inbound_id AS id, descripcion AS description, ''inboundCamp'' AS dbColumn
                FROM ccInbound B INNER JOIN @tablatemp A ON B.inbound_id = A.id
                RETURN
            END
            ELSE BEGIN
                SELECT inbound_id AS id, descripcion AS description, ''inboundCamp'' AS dbColumn
                FROM ccInbound WHERE chat IN (0,11)
            END
        END

        -- AUXILIAR TYPES
        IF @type = 34
        BEGIN
            SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
            FROM TipoReadyAuxiliar
            ORDER BY [description]
        END

        -- SMS SEGMENTS
        IF @type = 35
        BEGIN
            SELECT SegmentId AS id, Name AS description, ''SegmentId'' AS dbColumn FROM ccSmsSegments
        END

        -- ADMIN USER
        IF @type = 36
        BEGIN
            IF @userId <> 0
            BEGIN
                INSERT INTO @tempwork
                    SELECT IDWG FROM ccRIAWorkGroupUsers WITH (INDEX(IX_ccRIAWorkGroupUsers_I)) WHERE User_id = @userId

                SELECT DISTINCT us.User_id AS id, us.Login AS description, ''adminId'' AS dbcolumn FROM ccUserView us
                INNER JOIN ccRIAWorkGroupUsers wgu ON us.User_id = wgu.User_id
                INNER JOIN @tempwork awg ON wgu.IDWG = awg.idwg
                WHERE us.TipoUser_id = 2 AND [status] = 1
                RETURN
            END
            ELSE BEGIN
                SELECT [user_id] AS id, [login] AS description, ''adminId'' AS dbColumn
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
                    ''inboundId''   AS dbcolumn
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
                    ''inboundId'' AS dbcolumn
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
                ''ModelName'' AS dbcolumn
            FROM ccVirtualAgent
            ORDER BY description
        END

        -- CAMPAIGN TYPE (proceso 4020)
        -- Filtra por campType en RepOutCallsDetail: 0=Estandar, 9=IA, 6=VP
        IF @type = 39
        BEGIN
            SELECT id, description, dbcolumn FROM (VALUES
                (0, ''Salida Estándar'', ''campType''),
                (9, ''Salida IA'',       ''campType''),
                (6, ''Salida VP'',       ''campType'')
            ) AS t(id, description, dbcolumn)
        END

    END -- Action 0

    IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
        DROP TABLE #filters

    -- ---------------------------------------------------------
    IF @action = 1
    BEGIN
        -- TRUNKS
        IF @type = 13
        BEGIN
            SELECT MIN(trunk) AS [min], MAX(trunk) AS [max], ''trunk'' AS dbColumn FROM RepTrunkBusy
        END

        -- AVRS DISPOSITION
        IF @type = 18
        BEGIN
            SELECT 0 AS [min], 100 AS [max], ''Disposition'' AS dbColumn
        END

        -- AVG DISPOSITION
        IF @type = 19
        BEGIN
            SELECT 0 AS [min], 100 AS [max], ''avgDisposition'' AS dbColumn
        END

        -- SCORE
        IF @type = 20
        BEGIN
            SELECT 0 AS [min], 100 AS [max], ''avgDisposition'' AS dbColumn
        END
    END

END
'
    exec (@sql)

    SET @process = 'K070300 - ReportsTotals fila de totales reportes 4010 y 3010'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM ReportsTotals WHERE id = 4010)
        UPDATE ReportsTotals SET totalColumns = ''count:telephone'' WHERE id = 4010
    ELSE
        INSERT INTO ReportsTotals (id, totalColumns) VALUES (4010, ''count:telephone'')

    IF EXISTS (SELECT 1 FROM ReportsTotals WHERE id = 3010)
        UPDATE ReportsTotals SET totalColumns = ''count:call_Id'' WHERE id = 3010
    ELSE
        INSERT INTO ReportsTotals (id, totalColumns) VALUES (3010, ''count:call_Id'')
    '
    exec (@sql)

    SET @process = 'K070300 - Filters id=37 scope de usuario (Acds/Acd)'
    SET @sql = '
    UPDATE Filters
    SET xmlParentNode = ''Acds'', xmlChildNode = ''Acd''
    WHERE id = 37
    '
    exec (@sql)

    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
