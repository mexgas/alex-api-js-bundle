/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Octavio Arturo Ortiz Diaz


Date: 2025/11/25
Description: Cambios para HU's KR201001-KR201005

Database: CCReportsRIA
Required version: 147

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
SET @version = 148 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

--------------------------------------------------------BEGIN Octavio Ortiz----------------------------------------------------------------------------------------

---Alter Table--

    -- RepAgentSummary
    SET @process = 'AlterTable RepAgentSummary';
    SET @sql = '
    IF COL_LENGTH(''RepAgentSummary'', ''areaId'') IS NULL
    BEGIN
        ALTER TABLE RepAgentSummary 
            ADD areaId INT NOT NULL DEFAULT(0);
    END

    IF COL_LENGTH(''RepAgentSummary'', ''area'') IS NULL
    BEGIN
        ALTER TABLE RepAgentSummary 
            ADD area VARCHAR(100) NULL;
    END
    ';
    EXEC(@sql);

    -- RepInCallsDetail
    SET @process = 'AlterTable RepInCallsDetail';
    SET @sql = '
    IF COL_LENGTH(''RepInCallsDetail'', ''areaId'') IS NULL
    BEGIN
        ALTER TABLE RepInCallsDetail 
            ADD areaId INT NOT NULL DEFAULT(0);
    END

    IF COL_LENGTH(''RepInCallsDetail'', ''area'') IS NULL
    BEGIN
        ALTER TABLE RepInCallsDetail 
            ADD area VARCHAR(100) NULL;
    END
    ';
    EXEC(@sql);

    -- RepOutCallsDetail
    SET @process = 'AlterTable RepOutCallsDetail';
    SET @sql = '
    IF COL_LENGTH(''RepOutCallsDetail'', ''areaId'') IS NULL
    BEGIN
        ALTER TABLE RepOutCallsDetail 
            ADD areaId INT NOT NULL DEFAULT(0);
    END

    IF COL_LENGTH(''RepOutCallsDetail'', ''area'') IS NULL
    BEGIN
        ALTER TABLE RepOutCallsDetail 
            ADD area VARCHAR(100) NULL;
    END
    ';
    EXEC(@sql);

    -- RepOutDialDetail
    SET @process = 'AlterTable RepOutDialDetail';
    SET @sql = '
    IF COL_LENGTH(''RepOutDialDetail'', ''areaId'') IS NULL
    BEGIN
        ALTER TABLE RepOutDialDetail 
            ADD areaId INT NOT NULL DEFAULT(0);
    END

    IF COL_LENGTH(''RepOutDialDetail'', ''area'') IS NULL
    BEGIN
        ALTER TABLE RepOutDialDetail 
            ADD area VARCHAR(100) NULL;
    END
    ';
    EXEC(@sql);

    -- RepSpecialAbndCamp
    SET @process = 'AlterTable RepSpecialAbndCamp';
    SET @sql = '
    IF COL_LENGTH(''RepSpecialAbndCamp'', ''areaId'') IS NULL
    BEGIN
        ALTER TABLE RepSpecialAbndCamp 
            ADD areaId INT NOT NULL DEFAULT(0);
    END

    IF COL_LENGTH(''RepSpecialAbndCamp'', ''area'') IS NULL
    BEGIN
        ALTER TABLE RepSpecialAbndCamp 
            ADD area VARCHAR(100) NULL;
    END
    ';
    EXEC(@sql);

-------Inserts-------
    SET @process = 'Insert into ReportsFilters - KR201001';

    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 
        FROM ReportsFilters
        WHERE ReportName = ''Agent Summary''
        AND filterName = ''areas''
        AND id   = 2100
    )
    BEGIN
        INSERT INTO ReportsFilters (ReportName, filterName, id)
        VALUES (''Agent Summary'', ''areas'', 2100);
    END
    ';
    EXEC(@sql);

    SET @process = 'Insert into ReportsFilters - KR201002';

    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 
        FROM ReportsFilters
        WHERE ReportName = ''Call Detail''
        AND filterName = ''areas''
        AND id   = 3010
    )
    BEGIN
        INSERT INTO ReportsFilters (ReportName, filterName, id)
        VALUES (''Call Detail'', ''areas'', 3010);
    END
    ';
    EXEC(@sql);

    SET @process = 'Insert into ReportsFilters - KR201003';

    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 
        FROM ReportsFilters
        WHERE ReportName = ''Dialing Detail''
        AND filterName = ''areas''
        AND id   = 4010
    )
    BEGIN
        INSERT INTO ReportsFilters (ReportName, filterName, id)
        VALUES (''Dialing Detail'', ''areas'', 4010);
    END
    ';
    EXEC(@sql);

    SET @process = 'Insert into ReportsFilters - KR201004';

    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 
        FROM ReportsFilters
        WHERE ReportName = ''Answered Calls Detail''
        AND filterName = ''areas''
        AND id   = 4020
    )
    BEGIN
        INSERT INTO ReportsFilters (ReportName, filterName, id)
        VALUES (''Answered Calls Detail'', ''areas'', 4020);
    END
    ';
    EXEC(@sql);

    SET @process = 'Insert into ReportsFilters - KR201005';

    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 
        FROM ReportsFilters
        WHERE ReportName = ''Abandoned calls''
        AND filterName = ''areas''
        AND id   = 4150
    )
    BEGIN
        INSERT INTO ReportsFilters (ReportName, filterName, id)
        VALUES (''Abandoned calls'', ''areas'', 4150);
    END
    ';
    EXEC(@sql);

-------Store procedures------
--ccspRepOutCallsDetail
SET @process = 'Drop Procedure [ccspRepOutCallsDetail]';
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepOutCallsDetail'')
BEGIN
    DROP PROCEDURE [dbo].[ccspRepOutCallsDetail];
END';
EXEC(@sql);



SET @process = 'CreateProcedure ccspRepOutCallsDetail';
SET @sql = '
CREATE PROCEDURE [dbo].[ccspRepOutCallsDetail] 
    @action AS TINYINT,
    @from  AS DATETIME = NULL,
    @to    AS DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @from IS NULL
        SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

    IF @to IS NULL
        SELECT @to = GETDATE();

    DECLARE @IVA INT, @IVAstring VARCHAR(3);
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

        INSERT INTO RepOutCallsDetail
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
            ISNULL(CONVERT(VARCHAR(255), Usr.[LOGIN]), ''systemTranslated_NoUserName'') AS [username],
            camps.cam_id AS [campaignId],
            ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
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
                WHEN ld.TipoDialingMode = ''10000000''   THEN ''systemTranslated_Assisted'' 
                WHEN ld.TipoDialingMode IN (''00001000'',''00010000'', ''000010000'') THEN ''systemTranslated_Callback'' 
                WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto'' 
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
            sta.descTranslated AS [dialResult], 
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
            ar.AreaName AS [area]
        FROM ccoCallsOut Call (NOLOCK)
        LEFT JOIN ccoLogDials      ld   (NOLOCK) ON Call.cal_id    = ld.cal_id
        LEFT JOIN ccTipoCalifOUT   Tipo (NOLOCK) ON Call.calif_id  = Tipo.calif_id
        LEFT JOIN ccUserView       Usr  (NOLOCK) ON Usr.[user_id]  = Call.[user_id]
        LEFT JOIN ccCamps          camps(NOLOCK) ON camps.[cam_id] = Call.[cam_id]
        LEFT JOIN ccStatusLlamada  sta  (NOLOCK) ON Call.statuscall_id = sta.statuscall_id
        LEFT JOIN cstoProvedor     prov (NOLOCK) ON prov.[provedor_id] = Call.[provedor_id]
        LEFT JOIN cstoTipoLlamada  tl   (NOLOCK) ON tl.[tipoLlamada_id] = ld.[tipoLlamada_id] 
                                                AND tl.Country_id       = @country
        LEFT JOIN ccTipoCalifSubOut sub (NOLOCK) ON Call.califsub_id = sub.califsub_id
        LEFT JOIN ccoDialers       di   (NOLOCK) ON di.dialer_id = Call.cal_puerto 
                                                AND Call.provedor_id = di.provedor_id
        LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON Call.callout_id = cs.callout_id
        LEFT JOIN ccoCallsOutData  cod  (NOLOCK) ON cod.cal_id = Call.cal_id
        LEFT JOIN ccCallCost_RIA   cc   (NOLOCK) ON cc.country_id = tl.country_id 
                                                AND cc.tipoLlamada_id = tl.tipoLlamada_id
        LEFT JOIN Ria_grabacion    rc   (NOLOCK) ON rc.cal_id = Call.cal_id 
                                                AND rc.tipo_llamada = 2
        LEFT JOIN dbo.ccRIACat_Areas AS ar (NOLOCK) ON ar.IDArea = camps.IDArea
        WHERE Call.cal_inicio >= @from 
          AND Call.cal_inicio <  @to 
          AND Call.cal_manual IN (0, 2) 
          AND ld.TipoDialingMode IS NOT NULL
        ORDER BY DATE;
    END
END';
EXEC(@sql);

--ccspRepOutDialDetail
SET @process = 'Drop Procedure [ccspRepOutDialDetail]';
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepOutDialDetail'')
BEGIN
    DROP PROCEDURE [dbo].[ccspRepOutDialDetail];
END';
EXEC(@sql);


SET @process = 'CreateProcedure ccspRepOutDialDetail';
SET @sql = '
CREATE PROCEDURE [dbo].[ccspRepOutDialDetail] 
    @action AS TINYINT, 
    @from   AS DATETIME = NULL, 
    @to     AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15

IF @to IS NULL
    SELECT @to = GETDATE()

IF @action = 1
BEGIN  

    DECLARE @country SMALLINT
    SELECT @country = valor
    FROM ccSettings
    WHERE setting_id = 104

    DELETE FROM RepOutDialDetail WHERE [date] >= @from AND [date] < @to
        
    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip;

    SELECT  dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
        ,ISNULL(tr.descTranslate,'''') AS resultDialDesc
        ,dial.Telefono
        ,dial.Puerto
        ,dial.fecha
        ,dial.tDialing
        ,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
              WHEN dial.TipoDialingMode =  ''10000000'' THEN ''systemTranslated_Assisted'' 
              WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
              WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType            
        ,dial.tBusy
        ,dial.answerbit
        ,dial.canceledNoAgents
        ,dial.cal_id
        ,dial.disconnectCause
        ,co.cal_key
        ,co.file_moved
        ,dial.tipoLlamada_id
        ,tco.[Description] AS CallDisposition
        ,tsco.califSubDesc
        ,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END AS codeSip
        ,CASE 
            WHEN @country<>1 THEN '''' 
            WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
            WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' 
            ELSE ''systemTranslated_Indefinite'' 
         END AS TipoTel
        ,ISNULL(regp.tPreview,'''') AS tpreview
        ,co.User_id AS UserID
    INTO #dials
    FROM ccoLogDials dial (NOLOCK)
    LEFT JOIN ccoCallsOut co (NOLOCK) ON dial.cal_id = co.cal_id
    LEFT JOIN ccTipoCalifOUT tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
    LEFT JOIN ccTipoCalifSubOUT tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
    LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) 
        ON regp.callout_id = co.callout_id AND regp.callId = co.cal_id
    LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dial.tipoResDial_id = tr.tipoResDial_id
    WHERE fecha >= @from AND fecha < @to
    UNION
    (
        SELECT 
             ''''                          AS logDial_id
            ,reg.callout_id
            ,ccoa.cam_id
            ,reg.process                  AS tipoResDial_id
            ,ISNULL(cctyp.translatedDesc,'''') AS resultDialDesc
            ,ccoa.cal_telefono
            ,''''                         AS Puerto
            ,reg.reg_date                 AS fecha
            ,''''                         AS tDialing
            ,''systemTranslated_Preview'' AS dialType        
            ,''''                         AS tBusy
            ,''''                         AS answerbit
            ,''''                         AS canceledNoAgents
            ,''''                         AS cal_id
            ,''''                         AS disconnectCause
            ,''''                         AS cal_key -- temporal, se rellena abajo con ccoa.cal_key
            ,''''                         AS file_moved
            ,''''                         AS tipoLlamada_id
            ,''''                         AS CallDisposition
            ,''''                         AS califSubDesc
            ,''''                         AS codeSip
            ,''''                         AS TipoTel   
            ,reg.tPreview                 AS tpreview
            ,reg.userId                   AS UserID
        FROM RegProcessPreviewRecord reg (NOLOCK)
        LEFT JOIN ccoCallsOut ccoa (NOLOCK) 
            ON reg.callout_id = ccoa.callout_id
        LEFT JOIN ccTypeProcessPreview cctyp (NOLOCK) 
            ON cctyp.typeProcess_id = reg.process
        WHERE reg.reg_date >= @from 
          AND reg.reg_date < @to 
          AND reg.process NOT IN (5,7,13,14)
    )

    SELECT DISTINCT 
        CAST(codeSip AS INT) AS codeSip,
        disconnectCause 
    INTO #codeSip 
    FROM #dials 
    WHERE codeSip <> '''' 
      AND ISNUMERIC(codeSip) = 1;

    SELECT 
        A.codeSip,
        A.disconnectCause,
        B.[description]
    INTO #relationCodeSip 
    FROM #codeSip A
    INNER JOIN DC_Extra B ON A.codeSip = B.id;


    INSERT INTO RepOutDialDetail
        SELECT 
             fecha AS [date]
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
            ,ISNULL(dials.cam_id,'''')   AS campaignId
            ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),''systemTranslated_NoCampaign'') AS campaign
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
            ,COALESCE(dat.[description], tr.descTranslate, ''N/A'') AS DCCustomer
            ,dials.dialType
            ,TipoTel
            ,ISNULL(CallDisposition, ''N/A'')    AS CallDisposition
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
            ,ISNULL(us.[Login],'''')            AS [Login]
            ,ISNULL(ar.IDArea, 1)               AS areaId   
            ,ISNULL(ar.AreaName,''Default'')    AS area 
    FROM #dials AS dials
    LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON dials.callout_id = cs.callout_id
    LEFT JOIN ccoLogDialsData   ldd (NOLOCK) ON ldd.logDial_id   = dials.logDial_id
    LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dials.tipoResDial_id = tr.tipoResDial_id
    LEFT JOIN ccCamps           camps (NOLOCK) ON camps.cam_id    = dials.cam_id
    LEFT JOIN ccRIARegistryLists rl (NOLOCK) ON cs.list_id        = rl.list_id
    LEFT JOIN #relationCodeSip  dat           ON dat.disconnectCause = dials.disconnectCause
    LEFT JOIN ccoCallsPreviewData csP         ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
    LEFT JOIN ccUsers           us  (NOLOCK)  ON us.User_id       = dials.UserID
    LEFT JOIN ccRIACat_Areas    ar  (NOLOCK)  ON ar.IDArea        = camps.IDArea

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip;
END';
EXEC(@sql);

--ccspRepSpecialAbndCamp
SET @process = 'Drop Procedure [ccspRepSpecialAbndCamp]';
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepSpecialAbndCamp'')
BEGIN
    DROP PROCEDURE [dbo].[ccspRepSpecialAbndCamp];
END';
EXEC(@sql);



SET @process = 'CreateProcedure ccspRepSpecialAbndCamp';
SET @sql = '
CREATE PROCEDURE [dbo].[ccspRepSpecialAbndCamp]
    @action AS TINYINT,
    @from   AS DATETIME = NULL,
    @to     AS DATETIME = NULL
AS

IF @action = 1
BEGIN
    IF @from IS NULL
        SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))
    IF @to IS NULL
        SELECT @to = GETDATE()

    DELETE RepSpecialAbndCamp WITH (ROWLOCK)
    WHERE [date] BETWEEN @from AND @to

    INSERT RepSpecialAbndCamp
    SELECT 
        [date], 
        campaignId, 
        cam_descripcion, 
        total, 
        abandonedCalls,
        CAST(ISNULL(((abandonedCalls * 100.0) / NULLIF(total, 0)), 0) AS DECIMAL(5,2)) AS abandonedCallsPctg,
        [year],
        [month],
        [day],
        [hour],
        [minutes], 
        areaId, 
        area  
    FROM (
        SELECT 
            CONVERT(DATETIME, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'') AS [date], 
            co.cam_id AS campaignId,
            cam_descripcion,
            COUNT(*) AS total,
            COUNT(
                CASE 
                    WHEN statuscall_id IN (5,6,7,8,9,10,11,15,16) 
                        THEN cal_id 
                    ELSE NULL 
                END
            ) AS abandonedCalls,
            DATEPART(yyyy, CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121)) AS [year],
            DATEPART(mm,   CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121)) AS [month],
            DATEPART(dd,   CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121)) AS [day],
            DATEPART(hh,   CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121)) AS [hour],
            DATEPART(mi,   CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121)) AS [minutes],
            MAX(ca.IDArea)     AS areaId,       
            MAX(ar.AreaName)   AS area      
        FROM ccocallsout co WITH (NOLOCK)
        LEFT JOIN cccamps        ca  ON ca.cam_id  = co.cam_id
        LEFT JOIN ccRIACat_Areas ar  ON ar.IDArea  = ca.IDArea
        WHERE cal_inicio BETWEEN @from AND @to
          AND cal_manual IN (0,2)
        GROUP BY 
            CONVERT(VARCHAR(13), cal_inicio, 121), 
            co.cam_id,  
            cam_descripcion, 
            ca.IDArea
    ) X
END';
EXEC(@sql);


-----Views------

--RepOutDialDetailView
SET @process = 'Drop View [RepOutDialDetailView]';
SET @sql = '
IF OBJECT_ID(N''dbo.RepOutDialDetailView'', ''V'') IS NOT NULL
BEGIN
    DROP VIEW [dbo].[RepOutDialDetailView];
END';
EXEC(@sql);


SET @process = 'CreateView RepOutDialDetailView';
SET @sql = '
CREATE VIEW [dbo].[RepOutDialDetailView] AS 
SELECT
    [date],
    [callKey],
    [telephone],
    [dialResultId],
    [dialResult],
    [campaignId],
    [campaign],
    [timeMessage],
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    [listName],
    [billed],
    [data1] AS [Dato1],
    [data2] AS [Dato2],
    [data3] AS [Dato3],
    [data4] AS [Dato4],
    [data5] AS [Dato5],
    [fileMoved],
    [DCCustomer],
    [disconnectCause],
    [dialType],
    [TipoTel],
    [CallDisposition],
    [CallSubDisposition],
    [data6],
    [data7],
    [data8],
    [data9],
    [data10],
    [data11],
    [data12],
    [data13],
    [data14],
    [data15],
    [preview_Time],
    [login] AS [user],
    [areaId],
    [area]
FROM RepOutDialDetail WITH (NOLOCK)';
EXEC(@sql);

--RepViewOutCallsDetail
SET @process = 'Drop View [RepViewOutCallsDetail]';
SET @sql = '
IF OBJECT_ID(N''dbo.RepViewOutCallsDetail'', ''V'') IS NOT NULL
BEGIN
    DROP VIEW [dbo].[RepViewOutCallsDetail];
END';
EXEC(@sql);


SET @process = 'CreateView RepViewOutCallsDetail';
SET @sql = '
CREATE VIEW [dbo].[RepViewOutCallsDetail] AS 
SELECT
    [date],
    callKey,
    telephone,
    transfer,
    dialog,
    nque,
    wrapup,
    CallDisposition,
    subDisposition,
    extension,
    userId,
    [login] AS [userName],
    username AS [login],
    campaignId,
    campaign,
    duration,
    ncost,
    iva,
    total AS totalRow,
    ByCarrier,
    Calltypes,
    dialType,
    whoHangUp,
    dialResult AS callStatus,
    calId,
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    trunk,
    data1 AS [Dato1],
    data2 AS [Dato2],
    data3 AS [Dato3],
    data4 AS [Dato4],
    data5 AS [Dato5],
    MessageTime,
    grabId,
    areaId,
    area
FROM RepOutCallsDetail WITH (NOLOCK)';
EXEC(@sql);


--RepViewSpecialAbndCamp
SET @process = 'Drop View [RepViewSpecialAbndCamp]';
SET @sql = '
IF OBJECT_ID(N''dbo.RepViewSpecialAbndCamp'', ''V'') IS NOT NULL
BEGIN
    DROP VIEW [dbo].[RepViewSpecialAbndCamp];
END';
EXEC(@sql);

SET @process = 'CreateView RepViewSpecialAbndCamp';
SET @sql = '
CREATE VIEW [dbo].[RepViewSpecialAbndCamp] AS 
SELECT
    [date],
    campaignId,
    campaign,
    dialedCalls,
    abandonedCalls,
    abandonedCallsPctg,
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    areaId,
    area
FROM RepSpecialAbndCamp WITH (NOLOCK)';
EXEC(@sql);

--RepViewSummary

SET @process = 'Drop View [RepViewSummary]';
SET @sql = '
IF EXISTS (
    SELECT 1
    FROM sys.views
    WHERE name = ''RepViewSummary''
      AND schema_id = SCHEMA_ID(''dbo'')
)
BEGIN
    DROP VIEW [dbo].[RepViewSummary];
END
';
EXEC(@sql);

SET @process = 'CreateView RepViewSummary';
SET @sql = '
CREATE VIEW [dbo].[RepViewSummary] AS 
SELECT 
    [date],
    [login],
    [user],
    sessionTime,
    loginMktTime,
    logoutMktTime,
    0 AS callTengaged,
    ndTime,
    NCallsOut,
    NCallsIn,
    NCallsCorta,
    NAtend,
    NNoCalif,
    Available,
    0 AS avgCallTengaged,
    twrapup,
    userId,
    0 AS TypeNotReady,
    '''' AS descripcion,
    0 AS [time],
    0 AS transferStatus,
    0 AS ringingTime,
    0 AS unknownStatus,
    0 AS otherStatus,
    0 AS failureStatus,
    0 AS chatTengaged,
    0 AS undefinedTime,
    0 AS dialingStatus,
    NULL AS TipoReadyAuxiliarId,
    '''' AS auxiliarRedy_descripcion,
    0 AS auxiliarRedyTime,
    1 AS areaId,
    ''Default'' AS area
FROM RepAgentSummary_VersionAmatech

UNION

SELECT 
    [date],
    [login],
    [user],
    sessionTime,
    loginMktTime,
    logoutMktTime,
    callTengaged,
    ndTime,
    NCallsOut,
    NCallsIn,
    NCallsCorta,
    NAtend,
    NNoCalif,
    Available,
    avgCallTengaged,
    twrapup,
    userId,
    TypeNotReady,
    descripcion,
    [time],
    transferStatus,
    ringingTime,
    unknownStatus,
    otherStatus,
    failureStatus,
    chatTengaged,
    undefinedTime,
    dialingStatus,
    TipoReadyAuxiliarId,
    auxiliarRedy_descripcion,
    auxiliarRedyTime,
    areaId,
    area
FROM RepAgentSummary
';
EXEC(@sql);


-------Pitov AgentSummaryReport------
SET @process = 'UpdatePivotReportsComplementColumns';
SET @sql = '
    UPDATE PivotReports 
    SET complementColumns = ''date|login|user|loginMktTime|logoutMktTime|sessionTime|unknownStatus|otherStatus|Available|ndTime|transferStatus|ringingTime|callTengaged|twrapup|failureStatus|chatTengaged|dialingStatus|undefinedTime|NCallsOut|NCallsIn|NCallsCorta|NAtend|NNoCalif|avgCallTengaged|area''
    WHERE id = 2100;
';
EXEC(@sql);
----------------------------------------------------------END Octavio Ortiz------------------------------------------------------------------------------------------

------------------------------------ BEGIN UNION 127.20250905.0.6 -- 127.20251008.0.1 ------------------------------------
    --------------------------------  BEING GASJ --------------------------------
    set @process = 'ALTER PROCEDURE [dbo].[ccspRepAgentSummary]'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN   
    select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN

    IF OBJECT_ID(''tempdb..#AuxiliarReadyDetail'') IS NOT NULL
    DROP TABLE #AuxiliarReadyDetail

    CREATE TABLE #AuxiliarReadyDetail
    (
        timegroup DATE,
        userId INT,
        [user] VARCHAR(50),
        [sessionTime] INT,
        TipoReadyAuxiliarId INT,
        descripcion VARCHAR(50),
        descripcion_time VARCHAR(50),
        [time] DECIMAL(18, 3),
        timeSeconds DECIMAL(18, 3)
    )

    INSERT INTO #AuxiliarReadyDetail
    EXEC ccspGetAuxiliarReadyDetail @from = @from, @to = @to
        
    DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;
    DELETE RepAgentSummary_VersionAmatech WHERE DATE BETWEEN @from  AND @to;
    ;
    WITH AgentSession
    AS (
        SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
        FROM RepAgentSession
        WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(logintime), userId, [user]
        ),
        -------------OUT -------------------
    dataCallsOut
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY cal_id, statusCall_id
        ), dataCallsOutByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
        , sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferOut, SUM(tring)  tringOut
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallout
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
        , sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
        , sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
        FROM dataCallsOutByDay A
        INNER JOIN dataCallsOut B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ),
        ------------- IN -------------------
    dataCallsIn
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesInboundData
        GROUP BY cal_id, statusCall_id
        ), dataCallsInByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
        , sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferIn, SUM(tring)  tringIn
        FROM tmpTimesInboundData
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallIn
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
        , sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
        , sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
        FROM dataCallsInByDay A
        INNER JOIN dataCallsIn B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ), RepDetail
    AS (
        SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId
        )
    ,notReadyDay as(
    SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
        ,descripcion_time,descripcion,tiponotreadyId
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
    ),auxiliarReadyDay as(
        SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(timegroup) AS daygroup
        ,descripcion_time,descripcion,TipoReadyAuxiliarId
        FROM #AuxiliarReadyDetail r with(nolock)
        GROUP BY dbo.getdaygroup(timegroup), r.userId,descripcion,descripcion_time,TipoReadyAuxiliarId
    ), RepAgentGIGroup as(
        SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
        , SUM(tunknown) AS tunknown
        , SUM(tother) AS tother
        , SUM(tprob) AS tprob
        , SUM(tChatting) AS tChatting       
        , SUM(tundefined) AS tundefined
        , SUM([tManual]) AS [tManual]
        FROM RepAgentGI
        WHERE [date] BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup([date]), userId
    )
    --select * from AgentSession
    
    INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
    ,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
    ,chatTengaged,undefinedTime,dialingStatus,TipoReadyAuxiliarId,auxiliarRedy_descripcion,descripcion_auxiliarRedyTime_time,auxiliarRedyTime,areaId, area)
    SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
    , A.logout AS logoutMktTime
    , isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
    , ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
    , ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
    , ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
    , ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif    
    , ISNULL(AgtGI.tav, 0) AS Available
        ,ISNULL(    
        (   ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
            /
         nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
        , 0) AS avgCallTengaged
        
        ,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
        , notReady.TipoNotReadyId
        , notReady.descripcion
        , notReady.descripcion_time
        , notReady.timeSeconds
        , ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
        , ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
        , ISNULL(AgtGI.tunknown, 0) unknownStatus
        , ISNULL(AgtGI.tother, 0) otherStatus
        , ISNULL(AgtGI.tprob, 0) failureStatus
        , ISNULL(AgtGI.tChatting, 0) chatTengaged
        , ISNULL(AgtGI.tundefined, 0) undefinedTime
        , ISNULL(AgtGI.tManual, 0) dialingStatus
        , isnull(auxiliarReady.TipoReadyAuxiliarId,0) as TipoReadyAuxiliarId
        , isnull(auxiliarReady.descripcion,'''') as auxiliarRedy_descripcion
        , isnull(auxiliarReady.descripcion_time,''_Time2'') as descripcion_auxiliarRedyTime_time
        , convert(int,isnull(auxiliarReady.timeSeconds,0)) as auxiliarRedyTime
        , ISNULL(ar.IDArea, 1) AS areaId   
        , ISNULL(ar.AreaName,''Default'') AS area 
    FROM AgentSession A
    LEFT JOIN tmpCallout co ON A.DATE = co.DATE AND A.userId = co.userId
    LEFT JOIN tmpCallIn ci  ON A.DATE = ci.DATE AND A.userId = ci.userId
    LEFT JOIN RepDetail r   ON r.daygroup = A.DATE AND A.userId = r.userId
    LEFT JOIN notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
    LEFT join #AuxiliarReadyDetail auxiliarReady on auxiliarReady.userId=A.userId and auxiliarReady.timegroup=A.date
    left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
    LEFT JOIN ccUsers us WITH (NOLOCK) ON us.User_id = A.userId      
    LEFT JOIN ccRIACat_Areas ar WITH (NOLOCK) ON ar.IDArea = us.IDArea   
    order by A.[date],A.userId

END'
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)
    

    set @process = ''
    set @sql=''
    EXEC(@sql)
    
    --------------------------------  END GASJ -------------------------------- 

-------------------------------- BEGIN LMZN 127.20250905.0.8-------------------------------------------------------

SET @process = 'Create Column source';
SET @sql = '
-- source
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns 
    WHERE Name = ''source''
      AND Object_ID = Object_ID(''dbo.RepInCallsDetail'')
)
BEGIN
    ALTER TABLE dbo.RepInCallsDetail 
        ADD source VARCHAR(20);
END';
EXEC(@sql);

SET @process = 'Create Column destinationNumber';
SET @sql = '
-- destinationNumber
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns 
    WHERE Name = ''destinationNumber''
      AND Object_ID = Object_ID(''dbo.RepInCallsDetail'')
)
BEGIN
    ALTER TABLE dbo.RepInCallsDetail 
        ADD destinationNumber VARCHAR(20);
END';
EXEC(@sql);

SET @process = 'Create Column queueTime';
SET @sql = '
-- cal_tWait
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns 
    WHERE Name = ''cal_tWait''
      AND Object_ID = Object_ID(''dbo.RepInCallsDetail'')
)
BEGIN
    ALTER TABLE dbo.RepInCallsDetail 
        ADD cal_tWait INT;
END';
EXEC(@sql);

SET @process = 'Create Column callbackDate';
SET @sql = '
-- callbackDate
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns 
    WHERE Name = ''callbackDate''
      AND Object_ID = Object_ID(''dbo.RepInCallsDetail'')
)
BEGIN
    ALTER TABLE dbo.RepInCallsDetail 
        ADD callbackDate DATETIME;
END';
EXEC(@sql);

SET @process = 'Object drop: PROCEDURE [dbo].[ccspRepInCallsDetail]';
SET @sql = '
    IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepInCallsDetail'')
    BEGIN
        DROP PROCEDURE [dbo].[ccspRepInCallsDetail];
    END';
EXEC(@sql);



SET @process = 'Object create: PROCEDURE [dbo].[ccspRepInCallsDetail] --KR187000 (Se agregan columnas para fecha callback, source, destination y queueTime)';
SET @sql = '
CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] 
    @action AS TINYINT, 
    @from   AS DATETIME = NULL, 
    @to     AS DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @from IS NULL
        SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

    IF @to IS NULL
        SELECT @to = GETDATE();

    IF @action = 1
    BEGIN
        DECLARE @tab TABLE (
            callId INT PRIMARY KEY,
            [Dato1] VARCHAR(255),
            [Dato2] VARCHAR(255),
            [Dato3] VARCHAR(255),
            [Dato4] VARCHAR(255),
            [Dato5] VARCHAR(255)
        );

        DECLARE @fechaSUM DATETIME;

        INSERT INTO @tab
        SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
        FROM (
            SELECT A.CallId, [Data], [Description]
            FROM DataCallIn A
            INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
            WHERE B.cal_Inicio >= @from 
              AND B.cal_Inicio < @to
        ) AS SourceTable
        PIVOT (
            MAX([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])
        ) AS pvt;

        DELETE
        FROM RepInCallsDetail
        WHERE [date] >= @from 
          AND [date] < @to;

        ;WITH CallbackData AS (
            SELECT 
                cb.cal_fusercallback AS callbackDate,
                ci.cal_id
            FROM ccoCallBacks cb
            OUTER APPLY (
                SELECT TOP 1 la.callID
                FROM ccLogAgentesDia la
                WHERE 
                    la.User_id = cb.user_id
                    AND la.currentStatus = 4
                    AND la.fecha <= cb.cal_fecha
                ORDER BY ABS(DATEDIFF(SECOND, la.fecha, cb.cal_fecha))
            ) la
            LEFT JOIN ccCallsIn ci ON ci.cal_id = la.callID
            WHERE 
                ci.cal_ANI = cb.cal_telefono
        )
        INSERT INTO RepInCallsDetail (
            [date],
            callid,
            inboundId,
            ACDGroup,
            callStatusId,
            callStatus,
            dispositionId,
            disposition,
            subDispositionId,
            subDisposition,
            dnisId,
            dnis,
            userId,
            [user],
            callKey,
            ANI,
            queueTime,
            xferTime,
            ringingTime,
            dialogTime,
            extension,
            agentName,
            whoHangUp,
            mohTime,
            year,
            month,
            day,
            hour,
            minutes,
            provedorId,
            provider,
            trunk,
            fileMoved,
            twrapup,
            AverageHandleTime,
            Dato1,
            Dato2,
            Dato3,
            Dato4,
            Dato5,
            grabId,
            nameDNI,
            numDNI,
            collectCall,
            timeTotalInCallSec,
            timeTotalInCallMin,
            statusCallByIVR,
            IVR_ID,
            callHung,
            recibeCallBy,
            cal_final,
            areaId,
            area,
            source,
            destinationNumber,
            cal_tWait,
            callbackDate
        )
        SELECT 
            A.cal_inicio AS cal_ini, 
            A.cal_id,
            A.Inbound_id,
            ISNULL(ccIn.descripcion, '''') AS Inbound, 
            A.statusCall_id, 
            ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
            A.calif_id, 
            ISNULL(disposition.[description], '''') AS calif, 
            ISNULL(A.califSub_id, 0), 
            ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
            A.dni_id, 
            ISNULL(dnis.dni_numero, '''') AS dni, 
            A.user_id, 
            ISNULL([LOGIN], '''') AS [user], 
            ISNULL(A.cal_key, '''') AS cal_key, 
            A.cal_ANI, 
            A.cal_tWait, 
            A.cal_tXfer, 
            A.cal_tRing, 
            A.cal_tDialog, 
            A.cal_extension, 
            ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
            CASE
                WHEN A.cal_whoHung = 0 THEN ''systemTranslated_Client''
                WHEN A.cal_whoHung = 1 THEN ''systemTranslated_Agent''
                ELSE ''systemTranslated_AgentSurvey''
            END AS [whoHangUp], 
            A.cal_tMoh, 
            DATEPART(yyyy, A.cal_inicio) AS [year], 
            DATEPART(mm,   A.cal_inicio) AS [month], 
            DATEPART(dd,   A.cal_inicio) AS [day], 
            DATEPART(hh,   A.cal_inicio) AS [hour], 
            DATEPART(mi,   A.cal_inicio) AS [minute], 
            di.provedor_id, 
            prov.descrip AS [Proveedor], 
            A.cal_puerto,
            CASE
                WHEN A.file_moved = 1 THEN ''systemTranslated_Remoto''
                WHEN A.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
                ELSE ''Local''
            END AS file_Moved, 
            A.cal_tNotas, 
            A.cal_tNotas + A.cal_tDialog AS AverageHandleTime,
            ISNULL(tab.Dato1, '''') AS Dato1, 
            ISNULL(tab.Dato2, '''') AS Dato2, 
            ISNULL(tab.Dato3, '''') AS Dato3, 
            ISNULL(tab.Dato4, '''') AS Dato4, 
            ISNULL(tab.Dato5, '''') AS Dato5, 
            ISNULL(rc.grab_id, 0) AS grabId,
            ISNULL(dni_Descripcion, '''') AS nameDNI,
            ISNULL(dnis.dni_numero, '''') AS dni, 
            CASE
                WHEN statusLlamada.descripcion IS NOT NULL THEN ''Si''
                ELSE ''No''
            END AS collectCall,
            CASE
                WHEN A.cal_final IS NULL THEN 0
                ELSE CAST(DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) AS INT)
            END AS timeTotalInCallSec,
            CASE
                WHEN A.cal_final IS NULL THEN 0
                ELSE CAST(FLOOR(DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) / 60) AS INT) 
            END + 
            CASE
                WHEN A.cal_final IS NULL THEN 0
                ELSE
                    CASE
                        WHEN CAST(CEILING(DATEDIFF(SECOND, A.cal_Inicio, A.cal_final)) AS INT) % 60 != 0 THEN 1
                        ELSE 0
                    END
            END AS timeTotalInCallMin,
            CASE 
                WHEN A.IVR_id <> 0 
                     AND ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' 
                    THEN ''systemTranslated_AbandonedInIVR''
                WHEN A.statusCall_id = 13 THEN ''systemTranslated_Answered''
                WHEN A.statusCall_id <> 13 THEN ''''
                ELSE ''''
            END AS statusCallByIVR,
            ISNULL(ivrCIN.IVR_ID, 0) AS IVR,
            CASE
                WHEN ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' 
                    THEN ''systemTranslated_ClientSystem''
                ELSE ''''
            END AS statusCallByIVR,
            CASE
                WHEN ivrCIN.callid = A.cal_id THEN ''systemTranslated_SystemIVR''
                WHEN A.IVR_id = 0 THEN ''systemTranslated_CallInbound'' 
                ELSE ''''
            END AS [recibeCallBy], 
            ISNULL(A.cal_final, NULL) AS cal_final,
            ISNULL(ccIn.IDArea, 1) AS areaId,  
            ISNULL(ar.AreaName, ''Default'') AS area,
            ISNULL(a.cal_ANI,''N/A'') as source,
            ISNULL(dnis.dni_numero, ''N/A'') as destinationNumber,
            ISNULL(CAST(ROUND(a.cal_tWait, 0) AS INT), 0) as cal_tWait,
            cbx.callbackDate 
        FROM ccCallsIn A   
        LEFT JOIN ccoDialers        di       ON di.dialer_id   = A.cal_puerto
        LEFT JOIN cstoProvedor      prov     ON di.provedor_id = prov.provedor_id
        LEFT JOIN @tab              tab      ON tab.callId     = A.cal_id
        LEFT JOIN Ria_grabacion     rc       ON rc.cal_id      = A.cal_id AND rc.tipo_llamada = 1
        LEFT JOIN ccInbound         ccIn     ON A.Inbound_id   = ccIn.Inbound_id
        LEFT JOIN ccRIACat_Areas    ar       ON ar.IDArea      = ccIn.IDArea 
        LEFT JOIN ccstatusllamada   statusLlamada 
                                            ON A.statusCall_id = statusLlamada.statusCall_id
        LEFT JOIN cctipocalif       disposition 
                                            ON A.calif_id      = disposition.calif_id
        LEFT JOIN cctipocalifsub    subDisposition 
                                            ON A.califSub_id   = subDisposition.califSub_id
        LEFT JOIN ccdnis            dnis     ON A.dni_id       = dnis.dni_id
        LEFT JOIN ccUserView        ccuser   ON A.User_id      = ccuser.user_id
        LEFT JOIN repIVRDetail      ivrCIN   ON A.IVR_id       = ivrCIN.IVR_ID 
        LEFT JOIN CallbackData cbx ON cbx.cal_id = a.cal_id 
        WHERE A.cal_inicio >= @from
          AND A.cal_inicio <  @to;

        EXEC SupportReportCallInIVR 1, @from, @to;
    END
END';
EXEC(@sql);

SET @process = 'Object drop: VIEW [dbo].[RepViewInCallsDetail]';
SET @sql = '
IF OBJECT_ID(N''dbo.RepViewInCallsDetail'', ''V'') IS NOT NULL
BEGIN
    DROP VIEW [dbo].[RepViewInCallsDetail];
END';
EXEC(@sql);

SET @process = 'CreateView RepViewInCallsDetail';
SET @sql = '
CREATE VIEW [dbo].[RepViewInCallsDetail] AS
SELECT
    [date] AS receptionDate,
    cal_final,
    inboundId        AS inboundCamp,
    ACDGroup         AS campaign,
    callStatusId,
    callStatus,
    dispositionId,
    disposition      AS disposition_InCallsDetail,
    subDispositionId,
    subDisposition   AS sub_Disposition,
    dnisId,
    dnis             AS didNumber,
    userId,
    [user],
    callKey          AS call_Key,
    [source],
    [destinationNumber],
    callbackDate,
    [cal_tWait] as queueTime,
    ANI              AS aniNumber,
    queueTime        AS queue_Time,
    xferTime,
    ringingTime,
    dialogTime       AS dialog_Time,
    mohTime          AS hold_Time,
    twrapup,
    AverageHandleTime AS handleTime,
    extension,
    agentName,
    whoHangUp        AS endedBy,
    recibeCallBy,
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    provedorId,
    provider         AS provider_InCallsDetail,
    trunk            AS trunk_InCallsDetail,
    fileMoved,
    Dato1,
    Dato2,
    Dato3,
    Dato4,
    Dato5,
    callid           AS call_Id,
    grabId,
    nameDNI,
    numDNI,
    collectCall,
    timeTotalInCallSec,
    timeTotalInCallMin,
    statusCallByIVR,
    IVR_ID,
    callHung,
    areaId,
    area
FROM RepInCallsDetail WITH (NOLOCK)';
EXEC(@sql);

SET @process = 'ALTER ReportsTotals queueTime';
SET @sql = 'UPDATE ReportsTotals SET totalColumns = ''sum:queue_Time|sum:xferTime|sum:ringingTime|sum:dialog_Time|sum:hold_Time|sum:twrapup|sum:queueTime'' where id=3010';
EXEC(@sql);
-------------------------------- END LMZN -------------------------------------------------------------------------
          
------------------------------------ END UNION 127.20250905.0.6 -- 127.20251008.0.1 ------------------------------------



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
