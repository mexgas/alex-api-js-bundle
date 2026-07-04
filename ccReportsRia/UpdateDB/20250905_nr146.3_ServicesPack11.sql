/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: ServicesPACK9

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
SET @version = 146 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	
    SET @process = 'CREATE CLUSTERED INDEX CIX_RepOutTrunkBusy_Date'
    SET @sql = 'IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = ''CIX_RepOutTrunkBusy_Date''
          AND object_id = OBJECT_ID(''dbo.RepOutTrunkBusy'')
    )
    BEGIN
        CREATE CLUSTERED INDEX CIX_RepOutTrunkBusy_Date
        ON dbo.RepOutTrunkBusy([date]);
    END'
    exec (@sql)

    SET @process = 'DROP INDEX IX_RepOutTrunkBusy'
    SET @sql = 'IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = ''IX_RepOutTrunkBusy''
          AND object_id = OBJECT_ID(''dbo.RepOutTrunkBusy'')
    )
    BEGIN
        DROP INDEX IX_RepOutTrunkBusy
        ON dbo.RepOutTrunkBusy;
    END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy] se modifica para DELETE TOP (10000) FROM dbo.RepTrunkBusy'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy] @action AS TINYINT
    ,@from AS DATETIME = NULL
    ,@to AS DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
    CREATE TABLE #RtnValue (
        fecha DATETIME
        ,puerto INT
        ,cam_id INT
        ,tbusy INT
        ,contador INT
        ,fechafin DATETIME
        ,timegroup DATETIME
        ,timegroupNext DATETIME
        )

    CREATE TABLE #RtnValue2 (
        fecha DATETIME
        ,puerto INT
        ,cam_id INT
        ,tbusy INT
        ,contador INT
        ,fechafin DATETIME
        ,timegroup DATETIME
        ,timegroupNext DATETIME
        );

    WITH trunkOut
    AS (
        SELECT dials.fecha
            ,dials.Puerto
            ,dials.cam_id
            ,dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0) AS tBusy
            ,1 AS contador
            ,dateadd(ss, dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0), dials.fecha) AS fechafin
        FROM ccologdials AS dials
        LEFT JOIN ccocallsout AS calls ON (
                dials.Puerto = calls.cal_puerto
                AND dials.cal_id = calls.cal_id
                )
        WHERE dials.fecha BETWEEN @from
                AND @to
        )
    INSERT INTO #RtnValue
    SELECT fecha
        ,puerto
        ,cam_id
        ,tBusy
        ,contador
        ,fechafin
        ,dbo.GetTimeGroup(fecha, 0) AS timegroup
        ,dbo.GetTimeGroup(fechafin, 0) AS timegroupNext
    FROM trunkOut
    WHERE tBusy > 0

    INSERT INTO #RtnValue2
    SELECT *
    FROM #RtnValue
    WHERE datediff(mi, fecha, fechafin) > 15

    DELETE #RtnValue
    WHERE datediff(mi, fecha, fechafin) > 15

    INSERT INTO #RtnValue
    SELECT t.fecha
        ,t.Puerto
        ,t.cam_id
        ,dbo.TimeInterval(th.start, th.stop, t.fecha, fechafin) AS tBusy
        ,t.contador AS llamadas
        ,fechafin
        ,th.start
        ,th.stop
    FROM #RtnValue2 t
    INNER JOIN TmpTimesInterval th ON (
            t.fecha > th.Start
            AND t.fecha < th.stop
            )
        OR th.Start BETWEEN t.fecha
            AND t.fechafin

    SELECT timegroup
        ,puerto AS [port]
        ,cam_id
        ,SUM(tBusy) tBusy
        ,sum(contador) AS llamadas
        ,1 AS tipo
    INTO #ccGenOutPortStats
    FROM #RtnValue
    GROUP BY timegroup
        ,puerto
        ,cam_id

    INSERT INTO #ccGenOutPortStats
    SELECT timegroup
        ,cal_puerto AS [port]
        ,Inbound_id AS cam_id
        ,sum(txfer + tRing + tDialog) AS tBusy
        ,count(*) llamadas
        ,0 AS tipo
    FROM tmpTimesInboundData
    GROUP BY timegroup
        ,cal_puerto
        ,Inbound_id
    HAVING sum(txfer + tRing + tDialog) > 0

    
    WHILE 1 = 1
    BEGIN
        DELETE TOP (10000)
        FROM dbo.RepInTrunkBusy
        WHERE [date] >= @from
          AND [date] < @to;

        IF @@ROWCOUNT = 0
            BREAK;
    END;    

    INSERT INTO RepInTrunkBusy
    SELECT timegroup
        ,A.cam_id
        ,[in].descripcion
        ,[port]
        ,tbusy
        ,llamadas
        ,datepart(yyyy, timegroup) AS [year]
        ,datepart(mm, timegroup) AS [month]
        ,datepart(dd, timegroup) AS [day]
        ,datepart(hh, timegroup) AS [hour]
        ,datepart(mi, timegroup) AS [minutes]
    FROM #ccGenOutPortStats A
    INNER JOIN ccInbound [in] ON [in].inbound_id = A.cam_id
        AND A.tipo = 0

    WHILE 1 = 1
    BEGIN
        DELETE TOP (10000)
        FROM dbo.RepOutTrunkBusy
        WHERE [date] >= @from
          AND [date] < @to;

        IF @@ROWCOUNT = 0
            BREAK;
    END;

    INSERT INTO RepOutTrunkBusy
    SELECT timegroup
        ,A.cam_id
        ,[out].cam_descripcion
        ,[port]
        ,tbusy
        ,llamadas
        ,datepart(yyyy, timegroup) AS [year]
        ,datepart(mm, timegroup) AS [month]
        ,datepart(dd, timegroup) AS [day]
        ,datepart(hh, timegroup) AS [hour]
        ,datepart(mi, timegroup) AS [minutes]
    FROM #ccGenOutPortStats A
    INNER JOIN cccamps [out] ON (
            [out].cam_id = A.cam_id
            AND A.tipo = 1
            )

    WHILE 1 = 1
    BEGIN
        DELETE TOP (10000)
        FROM dbo.RepTrunkBusy
        WHERE [date] >= @from
          AND [date] < @to;

        IF @@ROWCOUNT = 0
            BREAK;
    END;

    INSERT INTO RepTrunkBusy
    SELECT timegroup
        ,port
        ,tbusy
        ,llamadas
        ,datepart(yyyy, timegroup) AS [year]
        ,datepart(mm, timegroup) AS [month]
        ,datepart(dd, timegroup) AS [day]
        ,datepart(hh, timegroup) AS [hour]
        ,datepart(mi, timegroup) AS [minutes]
    FROM #ccGenOutPortStats A

    DROP TABLE #RtnValue

    DROP TABLE #RtnValue2

    DROP TABLE #ccGenOutPortStats
END

'
    exec (@sql)

     SET @process = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]  INSERT INTO dbo.ReportJsonKeys (id, ReportDate, JsonKey) '
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail] 
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
            ModelName,
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
            callbackDate,
            CapturedData
        )
        SELECT 
            A.cal_inicio AS cal_ini, 
            A.cal_id,
            A.Inbound_id,
            ISNULL(ccIn.descripcion, '''') AS Inbound,
            ISNULL(va.nameAgent, ''NA'') AS ModelName,
            A.statusCall_id, 
            ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
            A.calif_id,
            CASE 
            
                WHEN ccIn.chat = 11 THEN ISNULL(disposition_IA.name_cal, '''')
                ELSE ISNULL(disposition.[description], '''') 
             END AS calif, 
            ISNULL(A.califSub_id, 0), 
            ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
            A.dni_id, 
            ISNULL(dnis.dni_numero, '''') AS dni, 
            A.user_id, 
            CASE 
                WHEN ccIn.chat = 11 THEN ''NA'' 
                ELSE ISNULL([LOGIN], '''') 
            END AS [user], 
            ISNULL(A.cal_key, '''') AS cal_key, 
            A.cal_ANI, 
            A.cal_tWait, 
            A.cal_tXfer, 
            A.cal_tRing, 
            A.cal_tDialog, 
            A.cal_extension, 
            CASE 
                WHEN ccIn.chat = 11 THEN ''NA''
                ELSE ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') 
            END AS agentName,
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
            cbx.callbackDate,
            CASE 
                WHEN CapturedData = '''' THEN ''N/A''
                ELSE ISNULL(CapturedData,''N/A'') 
            END AS CapturedData
        FROM ccCallsIn A   
        LEFT JOIN ccoDialers        di       ON di.dialer_id   = A.cal_puerto
        LEFT JOIN cstoProvedor      prov     ON di.provedor_id = prov.provedor_id
        LEFT JOIN @tab              tab      ON tab.callId     = A.cal_id
        LEFT JOIN Ria_grabacion     rc       ON rc.cal_id      = A.cal_id AND rc.tipo_llamada = 1
        LEFT JOIN ccInbound         ccIn     ON A.Inbound_id   = ccIn.Inbound_id
        LEFT JOIN ccVirtualAgent    va       ON va.idAgent     = A.User_id AND ccIn.chat = 11 
        LEFT JOIN ccRIACat_Areas    ar       ON ar.IDArea      = ccIn.IDArea 
        LEFT JOIN ccstatusllamada   statusLlamada 
                                            ON A.statusCall_id = statusLlamada.statusCall_id
        LEFT JOIN cctipocalif       disposition 
                                            ON A.calif_id      = disposition.calif_id
        LEFT JOIN cctipoCalif_IA    disposition_IA 
                                            ON A.calif_id      = disposition_IA.calif_id
        LEFT JOIN cctipocalifsub    subDisposition 
                                            ON A.califSub_id   = subDisposition.califSub_id
        LEFT JOIN ccdnis            dnis     ON A.dni_id       = dnis.dni_id
        LEFT JOIN ccUserView        ccuser   ON A.User_id      = ccuser.user_id
        LEFT JOIN repIVRDetail      ivrCIN   ON A.IVR_id       = ivrCIN.IVR_ID 
        LEFT JOIN CallbackData cbx ON cbx.cal_id = a.cal_id 
        LEFT JOIN ccCallsInDispositionIA cidia ON cidia.call_id = a.cal_id
        WHERE A.cal_inicio >= @from
          AND A.cal_inicio <  @to;

        EXEC SupportReportCallInIVR 1, @from, @to;

        declare @processsId int =3010

      DELETE FROM dbo.ReportJsonKeys
      WHERE id = @processsId
      AND ReportDate between @from and @to


    INSERT INTO dbo.ReportJsonKeys (id, ReportDate, JsonKey)
       SELECT
       @processsId as reportName,
        CONVERT(date,d.[date],121) as reportDate,
        j.[key]
    FROM dbo.RepInCallsDetail d
    CROSS APPLY OPENJSON(d.CapturedData) j
    WHERE d.[Date] >= @from
      AND d.[Date] < @to
      AND d.CapturedData IS NOT NULL
      AND d.CapturedData <> ''''
      AND d.CapturedData <> ''NULL''
      AND ISJSON(d.CapturedData) = 1
    GROUP BY j.[key],CONVERT(date,d.[date],121)

    END
END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]  INSERT INTO dbo.ReportJsonKeys (id, ReportDate, JsonKey)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
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

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip

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
        CallDisposition_IA VARCHAR(150)NULL,
        califSubDesc      VARCHAR(150) NULL,
        codeSip           VARCHAR(3)   NOT NULL,
        TipoTel           VARCHAR(30)  NOT NULL,
        tpreview          SMALLINT     NOT NULL,
        UserID            SMALLINT     NOT NULL,
        virtualAgentId    int          NOT NULL,
        ani               VARCHAR(32)  NOT NULL,
        CapturedData      Varchar(MAX) NOT NULL
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
        UserID,
        virtualAgentId,
        ani,
        CapturedData,
        CallDisposition_IA
    )
    SELECT
         dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE 
            WHEN co.statusCall_Id = 20 THEN 15 
            WHEN dial.canceledNoAgents = 1 THEN 14 
            ELSE dial.tipoResDial_id 
         END AS tipoResDial_id
        ,CASE 
            WHEN co.statusCall_Id = 20 THEN ''systemTranslated_QuantumVoicemail'' 
            ELSE ISNULL(tr.descTranslate,'''') 
         END AS resultDialDesc
        ,dial.Telefono AS cal_telefono
        ,dial.Puerto
        ,dial.fecha
        ,ISNULL(co.cal_tDialog, 0) AS cal_tDialog
        ,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview''
              WHEN SUBSTRING(dial.TipoDialingMode, 2, 1) = ''1'' AND co.cal_manual = 0 THEN ''systemTranslated_Assisted''
              WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
              WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto''
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(dial.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType
        ,dial.tBusy
        ,dial.answerbit
        ,dial.canceledNoAgents
        ,ISNULL(dial.cal_id,0) AS cal_id
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
        ,ISNULL(regp.tPreview,0) AS tpreview
        ,ISNULL(co.User_id,0) AS UserID
        ,ISNULL(co.virtualAgentId,0) AS virtualAgentId
        ,dial.ani
        ,ISNULL(CapturedData,'''') AS CapturedData
        ,CASE 
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
    WHERE dial.fecha >= @from
      AND dial.fecha < @to

    UNION

    SELECT
         0                              AS logDial_id
        ,reg.callout_id                 AS callout_id
        ,reg.camId                      AS cam_id
        ,CONVERT(SMALLINT, reg.process) AS tipoResDial_id
        ,ISNULL(cctyp.translatedDesc,'''') AS resultDialDesc
        ,ISNULL(ccoa.cal_telefono,'''')   AS cal_telefono
        ,0                              AS Puerto
        ,reg.reg_date                   AS fecha
        ,0                              AS tDialing
        ,''systemTranslated_Preview''     AS dialType
        ,0                              AS tBusy
        ,CONVERT(BIT, 0)                AS answerbit
        ,CONVERT(BIT, 0)                AS canceledNoAgents
        ,0                              AS cal_id
        ,''''                             AS disconnectCause
        ,NULL                           AS cal_key
        ,CONVERT(TINYINT, 0)            AS file_moved
        ,NULL                           AS tipoLlamada_id
        ,''''                             AS CallDisposition
        ,''''                             AS califSubDesc
        ,''''                             AS codeSip
        ,''''                             AS TipoTel
        ,reg.tPreview                   AS tpreview
        ,reg.userId                     AS UserID
        ,ISNULL(ccoa.virtualAgentId,0) AS virtualAgentId
        ,''''                             AS ani
        ,''''                             AS CapturedData
        ,''N/A''                          AS CallDisposition_IA
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
    WHERE codeSip <> ''''
      AND ISNUMERIC(codeSip) = 1

    SELECT
         A.codeSip
        ,A.disconnectCause
        ,B.[description]
    INTO #relationCodeSip
    FROM #codeSip A
    INNER JOIN DC_Extra B ON A.codeSip = B.id


    INSERT INTO RepOutDialDetail(
        [date],
        [calId],
        [callKey],
        [telephone],
        [dialResultId],
        [dialResult],
        [dialog],
        [campaignId],
        [campaign],
        [ModelName],
        [timeMessage],
        [year],
        [month],
        [day],
        [hour],
        [minutes],
        [listName],
        [billed],
        [data1],
        [data2],
        [data3],
        [data4],
        [data5],
        [fileMoved],
        [disconnectCause],
        [DCCustomer],
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
        [login],
        [areaId],
        [area],
        [ani],
        [CapturedData]
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

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip

    declare @processsId int =4010

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
'
    exec (@sql)

     SET @process = 'ALTER VIEW [dbo].[RepViewInCallsDetail]'
    SET @sql = 'ALTER VIEW [dbo].[RepViewInCallsDetail] AS  
SELECT [date] AS receptionDate,
    cal_final,
    inboundId AS inboundCamp,
    ACDGroup AS campaign,
    ModelName,
    callStatusId,
    callStatus,
    dispositionId,
    disposition AS disposition_InCallsDetail,
    subDispositionId,
    subDisposition AS sub_Disposition,
    dnisId,
    dnis AS didNumber,
    userId,
    [user] as agentUsername,
    callKey AS call_Key,
    [source],
    [destinationNumber],
    callbackDate,
    [cal_tWait] as queueTime,
    ANI AS aniNumber,
    queueTime AS queue_Time,
    xferTime,
    ringingTime,
    dialogTime AS dialog_Time,
    mohTime AS hold_Time,
    twrapup,
    AverageHandleTime AS handleTime,
    extension,
    agentName as [user],
    whoHangUp AS endedBy,
    recibeCallBy
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    provedorId,
    provider AS provider_InCallsDetail,
    trunk AS trunk_InCallsDetail,
    fileMoved,
    [CapturedData],
    Dato1,
    Dato2,
    Dato3,
    Dato4,
    Dato5,
    callid AS call_Id,
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
FROM RepInCallsDetail WITH (NOLOCK);'
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
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
