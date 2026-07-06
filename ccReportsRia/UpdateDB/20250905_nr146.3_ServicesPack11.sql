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

    SET @process = 'K061001 Report Filters Catalog'
    SET @sql = '
if not exists (select * from Filters  where id = 33) begin
    insert into Filters (id, name, type, xmlParentNode, xmlChildNode) 
    values (33, ''inboundCamps'', ''33'', ''InboundCamps'', ''InboundCamp'')
end

update ReportsFilters set filterName = ''inboundCamps'' where id=3010 and filterName = ''acds''
'
EXEC (@sql)
	
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
	
	SET @process = '#8379 CREATE NONCLUSTERED INDEX IX_ccoLogDials_fecha_cal_id_MKTIntervalos'
    SET @sql = 'IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = ''IX_ccoLogDials_fecha_cal_id_MKTIntervalos''
          AND object_id = OBJECT_ID(''dbo.ccoLogDials'')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_ccoLogDials_fecha_cal_id_MKTIntervalos
		ON dbo.ccoLogDials
		(
			fecha,
			cal_id
		)
		INCLUDE
		(
			cam_id,
			tipoResDial_id,
			tDialing,
			answerbit,
			canceledNoAgents
		);
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

	SET @process = 'Drop View RepViewAgentGIUnion';
    SET @sql = '
    IF OBJECT_ID(N''dbo.RepViewAgentGIUnion'', ''V'') IS NOT NULL
    BEGIN
        DROP VIEW [dbo].[RepViewAgentGIUnion];
    END';
    EXEC(@sql);

    SET @process = ''
    SET @sql = 'CREATE VIEW [dbo].[RepViewAgentGIUnion] AS
	select [date],userId,[user],[login]
	,sum(tlog) tlog
	,sum(tunknown) tunknown
	,sum(tav) tav
	,sum(tnotav) tnotav
	,sum(tother) tother
	,sum(tprob) tprob
	,sum(tChatting) tChatting
	,sum(tundefined) tundefined
	,sum(nxferin) nxferin
	,sum(nanswerin) nanswerin
	,sum(nabndxferin) nabndxferin
	,sum(nabndringin) nabndringin
	,sum(nabnddlgin) nabnddlgin
	,sum(abndaxferin) abndaxferin
	,sum(nnoanswerin) nnoanswerin
	,sum(nlostin) nlostin
	,sum(tdialogin) tdialogin
	,sum(tnotesin) tnotesin
	,sum(tringin) tringin
	,sum(txferin) txferin
	,sum(nxferout) nxferout
	,sum(nanswerout) nanswerout
	,sum(nabndxferout) nabndxferout
	,sum(nabndringout) nabndringout
	,sum(nabnddlgout) nabnddlgout
	,sum(abndaxferout) abndaxferout
	,sum(nnoanswerout) nnoanswerout
	,sum(nlostout) nlostout
	,sum(tdialogout) tdialogout
	,sum(tnotesout) tnotesout
	,sum(tringout) tringout
	,sum(txferout) txferout
	,sum(nother) nother
	,sum(nmohin) nmohin
	,sum(nmohout) nmohout
	,sum(nwhagin) nwhagin
	,sum(nwhagout) nwhagout
	,sum(nwhcliin) nwhcliin
	,sum(nwhcliout) nwhcliout
	,[year],[month],[day],[hour],[minutes]
	,0 tManual,0 tauxiliarready
	,0 tnotavg
	from RepAgentGI_VersionOld
	group by [date],userId,[user],[login],[year],[month],[day],[hour],[minutes]
	union
	select [date],userId,[user],[login]
	,tlog
	,tunknown
	,tav
	,tnotav
	,tother
	,tprob
	,tChatting
	,tundefined
	,nxferin
	,nanswerin
	,nabndxferin
	,nabndringin
	,nabnddlgin
	,abndaxferin
	,nnoanswerin
	,nlostin
	,tdialogin
	,tnotesin
	,tringin
	,txferin
	,nxferout
	,nanswerout
	,nabndxferout
	,nabndringout
	,nabnddlgout
	,abndaxferout
	,nnoanswerout
	,nlostout
	,tdialogout
	,tnotesout
	,tringout
	,txferout
	,nother
	,nmohin
	,nmohout
	,nwhagin
	,nwhagout
	,nwhcliin
	,nwhcliout
	,[year],[month],[day],[hour],[minutes]
	,tManual
	,0 tauxiliarready
	,0 tnotavg
	from RepAgentGI'
    exec (@sql)

    SET @process = '#8379 ALTER PROCEDURE [dbo].[ccspRepOutDials]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
    select @to = getdate()

if @action = 1 
begin
    declare @total decimal(10,2)
        
        

    select @total = count(*) from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_fecha_cal_id_MKTIntervalos))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and cal_id is not null
        
    delete from RepOutDials where date >= @from AND date < @to
        
        
    ;with tmpRepOutDials as(
    select  DATEADD(HOUR, DATEDIFF(HOUR, 0, fecha), 0) as fecha ,cal_id
    ,a.tipoResDial_id, descripcion,cam_id
    from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_fecha_cal_id_MKTIntervalos))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and a.cal_id is not null
    and cam_id>0
    )

    
   insert into RepOutDials

    select fecha as [date]      
    ,isnull(a.cam_id,0) as campaignId, isnull(c.cam_descripcion,'''') as campaign
    , isnull(min(d.idwg),1) as workgroupId, isnull(min(wgname),'''') as workgroup, isnull(min(c.idarea),1) as areaId, isnull(min(areaname),'''') as area
        
    ,a.tipoResDial_id, descripcion,
    descripcion + ''_Count'' as descripcion_count,
    count(*) as count,
    descripcion + ''_Avg'' as descripcion_avg,
    convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
    datepart(yyyy,fecha) AS [year],
    datepart(mm,fecha) as [month],
    datepart(dd,fecha) as [day],
    datepart(hh,fecha) as [hour],
    0 as [minutes]
    from  tmpRepOutDials as a
    left join ccCampsView as c (NOLOCK) on (a.cam_id = c.cam_id)
    left join ccRIACampEspWG as d (NOLOCK) on a.cam_id = d.IdCampEsp and d.tipo = 1 
    left join ccRIACat_WorkGroup as e (NOLOCK) on (d.idwg = e.idwg)
    left join ccRIAAreaWorkGroup as f (NOLOCK) on (e.idwg = f.idwg)
    left join ccRIACat_Areas as g (NOLOCK) on (c.idarea = g.idarea)     
    group by fecha ,        
    a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
    
end'
    exec (@sql)

    SET @process = '#8379 ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;

declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)

/****************************INDICES PARA REPORTES *******************************/
if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut13'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_11'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogTransfers_3'' and object_id = OBJECT_ID(N''ccLogtransfers''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_6'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesNotReady_5'' and object_id = OBJECT_ID(N''cclogagentesnotready''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end
    
if not exists (select * from sys.indexes where name = N''IX_ccLogLogin_6'' and object_id = OBJECT_ID(N''ccloglogin''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_fecha_cal_id_MKTIntervalos'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_fecha_cal_id_MKTIntervalos
ON dbo.ccoLogDials
(
    fecha,
    cal_id
)
INCLUDE
(
    cam_id,
    tipoResDial_id,
    tDialing,
    answerbit,
    canceledNoAgents
)
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_8'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_9'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpSessionTimeGroup_1'' and object_id = OBJECT_ID(N''tmpSessionTimeGroup''))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end
   
if not exists (select * from sys.indexes where name = N''IX_tmpccLogAgentesDia_2'' and object_id = OBJECT_ID(N''tmpccLogAgentesDia''))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_1'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_2'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_1'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_2'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccoLogDials_cal_id_logDial''
      AND i.object_id = OBJECT_ID(''dbo.ccoLogDials'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ccoLogDials_cal_id_logDial]
    ON [dbo].[ccoLogDials] ([cal_id] desc)
    INCLUDE ([logDial_id])
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccoLogDials_fecha_repOutDialDetail''
      AND i.object_id = OBJECT_ID(''dbo.ccoLogDials'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccoLogDials_fecha_repOutDialDetail
    ON dbo.ccoLogDials
    (
        fecha ASC
    )
    INCLUDE
    (
        logDial_id,
        callout_id,
        cam_id,
        tipoResDial_id,
        Telefono,
        Puerto,
        tDialing,
        tBusy,
        answerbit,
        TipoDialingMode,
        cal_id,
        canceledNoAgents,
        disconnectCause,
        tipoLlamada_id,
        manualCRM
    );
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccoLogDialsData_logDial_repOutDialDetail''
      AND i.object_id = OBJECT_ID(''dbo.ccoLogDialsData'')
)
BEGIN

    CREATE NONCLUSTERED INDEX IX_ccoLogDialsData_logDial_repOutDialDetail
    ON dbo.ccoLogDialsData
    (
        logDial_id
    )
    INCLUDE
    (
        Data1,
        Data2,
        Data3,
        Data4,
        Data5
    );
END

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''CIX_RepOutDialDetail_date''
    AND object_id = OBJECT_ID(''RepOutDialDetail'')
)
BEGIN
    CREATE CLUSTERED INDEX CIX_RepOutDialDetail_date
    ON dbo.RepOutDialDetail([date]);
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccoCallsOut_cal_id_repOutDialDetail''
      AND i.object_id = OBJECT_ID(''dbo.ccoCallsOut'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccoCallsOut_cal_id_repOutDialDetail
    ON dbo.ccoCallsOut
    (
        cal_id
    )
    INCLUDE
    (
        callout_id,
        User_id,
        cal_key,
        calif_id,
        califSub_id,
        cal_manual,
        file_moved
    );
END

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''IX_smsoutSourceMessage_smsout_id''
    AND object_id = OBJECT_ID(''smsoutSourceMessage'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_smsoutSourceMessage_smsout_id
    ON dbo.smsoutSourceMessage (smsout_id)
    INCLUDE ([message]);
END

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''IX_smsccoLogDial_smsDate''
    AND object_id = OBJECT_ID(''smsccoLogDial'')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_smsccoLogDial_smsDate
    ON dbo.smsccoLogDial (smsDate)
    INCLUDE (smsout_id, cam_id, phone, [Message], statusSystemsId, Bill, logId, registryClient)
END

/**************************** INDICES Reportes *******************************/
set @column=''date''
delete from @tIndexMerge

insert into @tIndexMerge(tableName,status)
SELECT     
    t.TABLE_NAME,0
FROM 
    INFORMATION_SCHEMA.COLUMNS c
INNER JOIN 
    INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_NAME LIKE ''Rep%''
    AND c.COLUMN_NAME = ''date''
    AND t.TABLE_TYPE = ''BASE TABLE''
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;

while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''IX_''+ @tableName+''_date'' 

    set @sql=''
-- Validar que NO exista ya un indice equivalente NONCLUSTERED ([date])
if not exists
(
    SELECT 1
    FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(@tableName)
      AND i.is_hypothetical = 0
      AND i.type = 2 -- NONCLUSTERED
      AND i.is_primary_key = 0
      AND i.is_unique_constraint = 0

      -- Debe tener exactamente una columna key
      AND
      (
          SELECT COUNT(*)
          FROM sys.index_columns ic
          WHERE ic.object_id = i.object_id
            AND ic.index_id = i.index_id
            AND ic.is_included_column = 0
      ) = 1

      -- No debe tener columnas INCLUDE
      AND
      (
          SELECT COUNT(*)
          FROM sys.index_columns ic
          WHERE ic.object_id = i.object_id
            AND ic.index_id = i.index_id
            AND ic.is_included_column = 1
      ) = 0

      -- La unica columna key debe ser [date]
      AND exists
      (
          SELECT 1
          FROM sys.index_columns ic
          INNER JOIN sys.columns c
              ON ic.object_id = c.object_id
             AND ic.column_id = c.column_id
          WHERE ic.object_id = i.object_id
            AND ic.index_id = i.index_id
            AND ic.is_included_column = 0
            AND ic.key_ordinal = 1
            AND c.name=@column
      )
)

-- Seguridad adicional: evitar duplicar nombre del indice
and not exists
(
    select 1
    from sys.indexes
    where name = @indexName
      and object_id = OBJECT_ID(@tableName)
)

-- Validar que la columna exista en la tabla
and exists
(
    select 1
    from sys.columns
    where name = @column
      and object_id = object_id(@tableName)
)

begin
    CREATE NONCLUSTERED INDEX ''+@indexName+''
    ON [dbo].[''+@tableName+''] ([date])
end
    ''

    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    --print (@sql)

    update @tIndexMerge set status=1 where @id=id
end


    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end'
    exec (@sql)

	SET @process = '#8379 DROP INDEX IX_ccoLogDials_8'
    SET @sql = 'IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = ''IX_ccoLogDials_8''
          AND object_id = OBJECT_ID(''dbo.ccoLogDials'')
    )
    BEGIN
        DROP INDEX IX_ccoLogDials_8
        ON dbo.ccoLogDials;
    END'
    exec (@sql)

    SET @process = '#8379 ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosSalidas]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosSalidas] 
@action as tinyint, @from as datetime = null, @to as datetime = null	
AS
SET NOCOUNT ON
if @from is null
	select @from = convert(datetime, convert(varchar(11), getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
	
	DECLARE @tresRing AS SMALLINT
	EXEC @tresRing = ccspConfigTresRing;						
			
delete RepMKTIntervalosSalida with(rowlock) where date >= @from and date < @to;

IF OBJECT_ID(''tempdb..#tPersonal'') IS NOT NULL drop table #tPersonal
IF OBJECT_ID(''tempdb..#tDisp'') IS NOT NULL drop table #tDisp;
IF OBJECT_ID(''tempdb..#callOut'') IS NOT NULL drop table #callOut;
IF OBJECT_ID(''tempdb..#OutboundCalls'') IS NOT NULL drop table #OutboundCalls;
IF OBJECT_ID(''tempdb..#OutboundCallGroup'') IS NOT NULL drop table #OutboundCallGroup;

select count(distinct user_id) as uid
	,sum(tlog) tlog
,DATEADD(mi, CASE WHEN DATEPART(mi, timegroup_next) in (15,45) THEN - 15 ELSE 0 END, timegroup_next) timegroup_next
into #tPersonal
from TmpSessionTimeGroup
group by DATEADD(mi, CASE WHEN DATEPART(mi, timegroup_next) in (15,45) THEN - 15 ELSE 0 END, timegroup_next)
	
select 
DATEADD(mi, 
case when DATEPART(mi,timeGroupNext)= 15 then -15 
	else 0 end
, timeGroupNext) as timeGroupNext
,sum(case when TipoStatusAge_id=2 then tStatus else 0 end) tnodispo
,sum(case when TipoStatusAge_id=2 then tStatus else 0 end) tdispo
into #tDisp
from tmpccLogAgentesDia
where TipoStatusAge_id in (2,3)
group by DATEADD(mi, 
case when DATEPART(mi,timeGroupNext)= 15 then -15 
	else 0 end
, timeGroupNext) 

	SELECT cal_id,dateStartDetail, dateEndDetail,timegroup_next
		, user_id, ntotal AS Recibidas, nanswer AS [Contestadas], nabnd_dialog AS [Abandonadas], nhangup AS SinAgentes, statusCall_id, tque, 
		txfer, tring, tdialog, tnotes, cal_tMoh
	INTO #callOut
	FROM tmpTimesOutboundData

	CREATE CLUSTERED INDEX IX_callOut_cal_id ON #callOut(cal_id)
	
	SELECT lo.cal_id
	,co.cal_id AS callId
	,co.dateStartDetail
	,co.dateEndDetail	
	,CASE WHEN co.statusCall_id = 13 THEN co.timegroup_next ELSE dbo.getTimegroup(DATEADD(ss, tDialing, lo.fecha),1) END AS timegroup_next	
	,Recibidas
	,co.user_id AS userId
	,cam_id AS cam_id
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 2 THEN 1 ELSE 0 END Ocupado
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 3 THEN 1 ELSE 0 END NoContestan
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 4 THEN 1 ELSE 0 END Fax
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 11 THEN 1 ELSE 0 END Buzon
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 5 THEN 1 ELSE 0 END SinTono
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 10 THEN 1 ELSE 0 END NoService
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 8 THEN 1 ELSE 0 END Otro
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 12 THEN 1 ELSE 0 END Congestion
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 13 THEN 1 ELSE 0 END Cancelado
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 1 THEN 1 ELSE 0 END [Contactos] --contactos sistema
	,[Contestadas]
	,CASE WHEN statusCall_id IN (6, 10, 11, 12, 14, 15, 16)
			OR (
				canceledNoAgents <> 0 AND answerbit = 1
				)
			OR ([Abandonadas] > 0) THEN 1 ELSE 0 END AS [Abandonadas]
	,SinAgentes
	,CASE WHEN statuscall_id IN (15, 16) THEN 1 ELSE 0 END AS NoContestadas
	,CASE WHEN statuscall_id IN (11, 10, 12, 14) AND tring <= @tresRing THEN 1 ELSE 0 END AS CortadasRing
	,CASE WHEN statuscall_id IN (11, 10, 12, 14) AND tring > @tresRing THEN 1 ELSE 0 END AS CortadasDespRing
	,[Abandonadas] AS CortadasDlg
	,CASE WHEN statuscall_id = 13 THEN co.txfer + co.tring + co.tdialog + co.tnotes + co.cal_tMoh ELSE 0 END TMO
	,CASE WHEN statuscall_id = 13 THEN 1 ELSE NULL END countStatus13
	,co.tdialog
	,co.cal_tMoh AS TiempoTotalHold
	,co.tnotes
	,co.txfer + co.tring AS TiempoTotalRing
	,co.tque
	,co.txfer + co.tring + co.tdialog + co.tnotes  [Ocupacion]
	,co.statuscall_id
	,co.tring
	,tipoResDial_id
INTO #OutboundCalls
FROM ccologdials(NOLOCK) lo
LEFT JOIN #callOut co
	ON co.cal_id = lo.cal_id
WHERE lo.fecha >= @from
		AND lo.fecha < @to

SELECT 
dateadd(mi, case when datepart(mi,timegroup_next) in (15,45) then -15 else 0 end,timegroup_next) as timegroup_next
,count(distinct userId )as Staff
,sum(Recibidas) as Recibidas
,sum(Ocupado) as Ocupado
,sum(NoContestan) as NoContestan	
,sum(Fax) as Fax
,sum(Buzon) as Buzon
,sum(SinTono) as SinTono
,sum(NoService) as nout_service	
,sum(Otro) as Other	
,sum(Congestion) as Congestion
,sum(Cancelado) as Cancelado
,sum(Contactos) as contacted
,sum(Contestadas) as Answered
,sum(Abandonadas) as abandonedCalls
,sum(SinAgentes) as SinAgentes
,sum(NoContestadas) as NoContestadas
,sum(CortadasRing) as nabndxferout
,sum(CortadasDespRing) as nabndringout
,sum(CortadasDlg) nabnddlgout
,isnull(SUM([Ocupacion])/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0)  as TMO
,isnull(SUM(tdialog)/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0) as promDialogo
,sum(TiempoTotalHold) as holdTime
,sum(tnotes) as tnotesout
,sum(TiempoTotalRing) as tringout
,isnull(sum(tque)*1.0/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0)  as avrAnswer
, case when count(case when statusCall_id=13 then 1 end ) = 0 or count(case when tipoResDial_id=1 then 1 end) = 0 then 0.00
else convert(decimal(10,2),sum(Abandonadas)*100.0/count(case when tipoResDial_id=1 then 1 end) ) end as AvgAbandon
,Cam_id
,sum([Ocupacion]) as sumTime
INTO #OutboundCallGroup
FROM #OutboundCalls co
group by dateadd(mi, case when datepart(mi,timegroup_next) in (15,45) then -15 else 0 end,timegroup_next),cam_id

insert into RepMKTIntervalosSalida
select convert(datetime, convert([date],oc.timegroup_next,121)) as [date]
,convert(varchar(5),oc.timegroup_next,108) rango1
,convert(varchar(5),dateadd(mi,30,oc.timegroup_next),108) rango2
,oc.Staff
,oc.Recibidas
,oc.Ocupado
,oc.NoContestan
,oc.Fax
,oc.Buzon
,oc.SinTono
,oc.nout_service
,oc.Other
,oc.Congestion
,oc.Cancelado
,oc.contacted
,oc.Answered
,oc.abandonedCalls
,oc.SinAgentes
,oc.NoContestadas
,oc.nabndxferout
,oc.nabndringout
,oc.nabnddlgout
,oc.TMO
,oc.promDialogo
,oc.holdTime
,oc.tnotesout
,oc.tringout
,isnull(d.tdispo,0) as readyTime
,isnull(d.tnodispo,0) as notReadyTime
,isnull(l.tlog,0) as Personal
,oc.avrAnswer
,isnull(case when l.tlog=0 then 0.00 else convert(decimal(10,2), (oc.tnotesout+d.tnodispo)*100.0/L.tlog) end,0.00) as Reductor
,oc.AvgAbandon
,case when l.tlog is null or l.tlog =0  then 0.00 else convert(decimal(10,2), oc.sumTime*100.0/L.tlog,0) end as OcupacionCOPC
,oc.Cam_id
from #OutboundCallGroup oc
left join #tPersonal L on oc.timegroup_next=L.timegroup_next
left join #tDisp d on oc.timegroup_next=d.timeGroupNext

IF OBJECT_ID(''tempdb..#tPersonal'') IS NOT NULL drop table #tPersonal
IF OBJECT_ID(''tempdb..#tDisp'') IS NOT NULL drop table #tDisp;
IF OBJECT_ID(''tempdb..#callOut'') IS NOT NULL drop table #callOut;
IF OBJECT_ID(''tempdb..#OutboundCalls'') IS NOT NULL drop table #OutboundCalls;
IF OBJECT_ID(''tempdb..#OutboundCallGroup'') IS NOT NULL drop table #OutboundCallGroup;
END'
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
