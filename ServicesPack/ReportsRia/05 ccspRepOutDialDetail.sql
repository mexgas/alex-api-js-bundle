USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepOutDialDetail]    Script Date: 24/03/2026 10:54:55 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]
@action AS TINYINT,
@from   AS DATETIME = NULL,
@to     AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

IF @action = 1
BEGIN
    DECLARE @country SMALLINT

    SELECT @country = valor
    FROM ccSettings
    WHERE setting_id = 104

    DELETE FROM RepOutDialDetail
    WHERE [date] >= @from
      AND [date] < @to

    IF OBJECT_ID('tempdb..#dials') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID('tempdb..#codeSip') IS NOT NULL DROP TABLE #codeSip
    IF OBJECT_ID('tempdb..#relationCodeSip') IS NOT NULL DROP TABLE #relationCodeSip

    CREATE TABLE #dials
    (
        logDial_id        INT          NOT NULL,
        callout_id        INT          NOT NULL,
        cam_id            INT          NOT NULL,
        tipoResDial_id    SMALLINT     NOT NULL,
        resultDialDesc    VARCHAR(50)  NOT NULL,
        Telefono          VARCHAR(30)  NOT NULL,
        Puerto            SMALLINT     NOT NULL,
        fecha             DATETIME     NOT NULL,
        tDialing          SMALLINT     NOT NULL,
        dialType          VARCHAR(50)  NULL,
        tBusy             SMALLINT     NOT NULL,
        answerbit         BIT          NULL,
        canceledNoAgents  BIT          NULL,
        cal_id            INT          NOT NULL,
        disconnectCause   VARCHAR(250) NOT NULL,
        cal_key           VARCHAR(40)  NULL,
        file_moved        TINYINT      NULL,
        tipoLlamada_id    SMALLINT     NULL,
        CallDisposition   VARCHAR(150) NULL,
        califSubDesc      VARCHAR(150) NULL,
        codeSip           VARCHAR(3)   NOT NULL,
        TipoTel           VARCHAR(30)  NOT NULL,
        tpreview          SMALLINT     NOT NULL,
        UserID            SMALLINT     NOT NULL
    )

    INSERT INTO #dials
    (
        logDial_id,
        callout_id,
        cam_id,
        tipoResDial_id,
        resultDialDesc,
        Telefono,
        Puerto,
        fecha,
        tDialing,
        dialType,
        tBusy,
        answerbit,
        canceledNoAgents,
        cal_id,
        disconnectCause,
        cal_key,
        file_moved,
        tipoLlamada_id,
        CallDisposition,
        califSubDesc,
        codeSip,
        TipoTel,
        tpreview,
        UserID
    )
    SELECT
         dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
        ,ISNULL(tr.descTranslate,'') AS resultDialDesc
        ,dial.Telefono
        ,dial.Puerto
        ,dial.fecha
        ,dial.tDialing
        ,CASE WHEN dial.TipoDialingMode = '100000000' THEN 'systemTranslated_Preview'
              WHEN SUBSTRING(dial.TipoDialingMode, 2, 1) = '1' AND co.cal_manual = 0 THEN 'systemTranslated_Assisted'
              WHEN RIGHT(dial.TipoDialingMode,5) IN ('01000','10000') THEN 'systemTranslated_Callback'
              WHEN RIGHT(dial.TipoDialingMode, 2) = '00' THEN 'systemTranslated_Auto'
              WHEN RIGHT(dial.TipoDialingMode, 2) IN ('10', '01') AND ISNULL(dial.manualCRM,0) = 1 THEN 'systemTranslated_Manual_Mode_Integration'
              WHEN RIGHT(dial.TipoDialingMode, 2) IN ('10', '01') THEN 'systemTranslated_Manual' END AS dialType
        ,dial.tBusy
        ,dial.answerbit
        ,dial.canceledNoAgents
        ,ISNULL(dial.cal_id,0)
        ,dial.disconnectCause
        ,co.cal_key
        ,co.file_moved
        ,dial.tipoLlamada_id
        ,tco.[Description] AS CallDisposition
        ,tsco.califSubDesc
        ,CASE WHEN dial.disconnectCause <> '' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '' END AS codeSip
        ,CASE
            WHEN @country<>1 THEN ''
            WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN 'systemTranslated_fijo'
            WHEN dial.tipoLlamada_id IN (3, 4) THEN 'systemTranslated_cellPhone'
            ELSE 'systemTranslated_Indefinite'
         END AS TipoTel
        ,ISNULL(regp.tPreview,0) AS tpreview
        ,ISNULL(co.User_id,0) AS UserID
    FROM ccoLogDials dial (NOLOCK)
    LEFT JOIN ccoCallsOut co (NOLOCK) ON dial.cal_id = co.cal_id
    LEFT JOIN ccTipoCalifOUT tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
    LEFT JOIN ccTipoCalifSubOUT tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
    LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK)
        ON regp.callout_id = co.callout_id AND regp.callId = co.cal_id
    LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dial.tipoResDial_id = tr.tipoResDial_id
    WHERE dial.fecha >= @from
      AND dial.fecha < @to

    UNION

    SELECT
         0                              AS logDial_id
        ,reg.callout_id
        ,reg.camId                      AS cam_id
        ,CONVERT(SMALLINT, reg.process) AS tipoResDial_id
        ,ISNULL(cctyp.translatedDesc,'') AS resultDialDesc
        ,ISNULL(ccoa.cal_telefono,'')   AS cal_telefono
        ,0                              AS Puerto
        ,reg.reg_date                   AS fecha
        ,0                              AS tDialing
        ,'systemTranslated_Preview'     AS dialType
        ,0                              AS tBusy
        ,CONVERT(BIT, 0)                AS answerbit
        ,CONVERT(BIT, 0)                AS canceledNoAgents
        ,0                              AS cal_id
        ,''                             AS disconnectCause
        ,NULL                           AS cal_key
        ,CONVERT(TINYINT, 0)            AS file_moved
        ,NULL                           AS tipoLlamada_id
        ,''                             AS CallDisposition
        ,''                             AS califSubDesc
        ,''                             AS codeSip
        ,''                             AS TipoTel
        ,reg.tPreview                   AS tpreview
        ,reg.userId                     AS UserID
    FROM RegProcessPreviewRecord reg (NOLOCK)
    LEFT JOIN ccoCallsOut ccoa (NOLOCK)
        ON reg.callout_id = ccoa.callout_id
    LEFT JOIN ccTypeProcessPreview cctyp (NOLOCK)
        ON cctyp.typeProcess_id = reg.process
    WHERE reg.reg_date >= @from
      AND reg.reg_date < @to
      AND reg.process NOT IN (5,7,13,14)

    CREATE NONCLUSTERED INDEX IX_#dials_logDial_id
    ON #dials(logDial_id)

    CREATE NONCLUSTERED INDEX IX_#dials_callout_id
    ON #dials(callout_id)

    SELECT DISTINCT
         CAST(codeSip AS INT) AS codeSip
        ,disconnectCause
    INTO #codeSip
    FROM #dials
    WHERE codeSip <> ''
      AND ISNUMERIC(codeSip) = 1

    SELECT
         A.codeSip
        ,A.disconnectCause
        ,B.[description]
    INTO #relationCodeSip
    FROM #codeSip A
    INNER JOIN DC_Extra B ON A.codeSip = B.id

    INSERT INTO RepOutDialDetail
    SELECT
         fecha AS [date]
        ,CASE
            WHEN dials.cal_key IS NULL AND cs.cal_key IS NULL THEN ''
            WHEN dials.cal_key IS NOT NULL THEN dials.cal_key
            ELSE cs.cal_key
         END AS cal_key
        ,ISNULL(dials.Telefono,'') AS telephone
        ,dials.tipoResDial_id AS tiporesdialId
        ,CASE
            WHEN dials.tipoResDial_id = 14 THEN
                CASE
                    WHEN camps.campType = 6 THEN 'systemTranslated_CancelledByEngaged'
                    ELSE 'systemTranslated_CancelledBySystem'
                END
            ELSE ISNULL(dials.resultDialDesc, '')
         END AS dialResult
        ,ISNULL(dials.cam_id,'') AS campaignId
        ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),'systemTranslated_NoCampaign') AS campaign
        ,dials.tbusy AS timeMessage
        ,DATEPART(yyyy, fecha) AS year
        ,DATEPART(mm, fecha) AS month
        ,DATEPART(dd, fecha) AS day
        ,DATEPART(hh, fecha) AS hour
        ,DATEPART(mi, fecha) AS minutes
        ,ISNULL(rl.[name], '') AS listName
        ,CASE
            WHEN answerbit = 1 THEN 'systemTranslated_Charged'
            ELSE 'systemTranslated_NotCharged'
         END AS billed
        ,ISNULL(ldd.Data1, ISNULL(cs.Dato1, '')) AS data1
        ,ISNULL(ldd.Data2, ISNULL(cs.Dato2, '')) AS data2
        ,ISNULL(ldd.Data3, ISNULL(cs.Dato3, '')) AS data3
        ,ISNULL(ldd.Data4, ISNULL(cs.Dato4, '')) AS data4
        ,ISNULL(ldd.Data5, ISNULL(cs.Dato5, '')) AS data5
        ,CASE
            WHEN dials.file_moved = 1 THEN 'systemTranslated_Remoto'
            WHEN dials.file_moved = 2 THEN 'systemTranslated_noRecordingCamp'
            ELSE 'systemTranslated_Local'
         END AS fileMoved
        ,dials.disconnectCause
        ,COALESCE(dat.[description], tr.descTranslate, 'N/A') AS DCCustomer
        ,dials.dialType
        ,TipoTel
        ,ISNULL(CallDisposition, 'N/A') AS CallDisposition
        ,ISNULL(califSubDesc, 'N/A') AS CallSubDisposition
        ,ISNULL(csP.Dato6,  '') AS data6
        ,ISNULL(csP.Dato7,  '') AS data7
        ,ISNULL(csP.Dato8,  '') AS data8
        ,ISNULL(csP.Dato9,  '') AS data9
        ,ISNULL(csP.Dato10, '') AS data10
        ,ISNULL(csP.Dato11, '') AS data11
        ,ISNULL(csP.Dato12, '') AS data12
        ,ISNULL(csP.Dato13, '') AS data13
        ,ISNULL(csP.Dato14, '') AS data14
        ,ISNULL(csP.Dato15, '') AS data15
        ,dials.tpreview AS preview_Time
        ,ISNULL(us.[Login],'') AS [Login]
        ,ISNULL(ar.IDArea, 1) AS areaId
        ,ISNULL(ar.AreaName,'Default') AS area
    FROM #dials AS dials
    LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON dials.callout_id = cs.callout_id
    LEFT JOIN ccoLogDialsData   ldd (NOLOCK) ON ldd.logDial_id   = dials.logDial_id
    LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dials.tipoResDial_id = tr.tipoResDial_id
    LEFT JOIN ccCamps camps (NOLOCK) ON camps.cam_id = dials.cam_id
    LEFT JOIN ccRIARegistryLists rl (NOLOCK) ON cs.list_id = rl.list_id
    LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
    LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
    LEFT JOIN ccUsers us (NOLOCK) ON us.User_id = dials.UserID
    LEFT JOIN ccRIACat_Areas ar (NOLOCK) ON ar.IDArea = camps.IDArea

    IF OBJECT_ID('tempdb..#dials') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID('tempdb..#codeSip') IS NOT NULL DROP TABLE #codeSip
    IF OBJECT_ID('tempdb..#relationCodeSip') IS NOT NULL DROP TABLE #relationCodeSip
END