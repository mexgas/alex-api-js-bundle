/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: Fix muñoz

Database: CCReportsRIA
Required version: 144

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

		--- BEGIN MAGV KR234004--

		SET @process = 'KR234004 Add manualCRM  to ccoLogDials'
	SET @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''manualCRM'' AND OBJECT_ID = OBJECT_ID(''ccoLogDials''))
		begin
			ALTER TABLE ccoLogDials
			ADD manualCRM BIT NULL;
		end'
	exec (@sql)
	--- END MAGV KR234004 ----
--------------------------------------------------------BEGIN 127.20250905.0.0 Jesus Gallardo----------------------------------------------------------------------
    
        set @process = '#3306 DROP INDEX IX_RepOutAnswAndXferCalls_1'
set @sql='IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutAnswAndXferCalls_1''
      AND object_id = OBJECT_ID(''dbo.RepOutAnswAndXferCalls'')
)
BEGIN
    DROP INDEX IX_RepOutAnswAndXferCalls_1
    ON dbo.RepOutAnswAndXferCalls;    
END
'
EXEC(@sql)


set @process = '#3306 CREATE NONCLUSTERED INDEX [IX_RepOutAnswAndXferCalls_2]'
set @sql='IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutAnswAndXferCalls_2''
      AND object_id = OBJECT_ID(''dbo.RepOutAnswAndXferCalls'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepOutAnswAndXferCalls_2] 
    ON [dbo].[RepOutAnswAndXferCalls] ([date])
    INCLUDE ([dialog],[ncost],[total]);
       
END'
EXEC(@sql)

set @process = '#3306 DROP INDEX IX_RepOutCallBilling'
set @sql='IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutCallBilling''
      AND object_id = OBJECT_ID(''dbo.RepOutCallBilling'')
)
BEGIN
    DROP INDEX IX_RepOutCallBilling
    ON dbo.RepOutCallBilling;

END'
EXEC(@sql)


set @process = '#3306 CREATE NONCLUSTERED INDEX [IX_RepOutCallBilling_1]'
set @sql='IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''IX_RepOutCallBilling_1''
      AND object_id = OBJECT_ID(''dbo.RepOutCallBilling'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepOutCallBilling_1]
ON [dbo].[RepOutCallBilling] ([date])
INCLUDE ([tipoLlamada_count])
    
   
END'
EXEC(@sql)

--------------------------------  BEING Octavio -------------------------------- 
SET @process = 'AlterTable RepAgentSummary';
SET @sql = N'
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE name = N''areaId''
      AND object_id = OBJECT_ID(N''dbo.RepAgentSummary'')
)
BEGIN
    ALTER TABLE dbo.RepAgentSummary ADD areaId INT NOT NULL CONSTRAINT DF_RepAgentSummary_areaId DEFAULT(0);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE name = N''area''
      AND object_id = OBJECT_ID(N''dbo.RepAgentSummary'')
)
BEGIN
    ALTER TABLE dbo.RepAgentSummary ADD area VARCHAR(100) NULL;
END;
';
EXEC (@sql);

SET @process = 'Update: Migracion de Area en RepAgentSummary (Por lotes)';
SET @sql = N'
    SET NOCOUNT ON;
    DECLARE @BatchSize INT = 10000;

    WHILE 1 = 1
    BEGIN
        UPDATE TOP (@BatchSize) R
        SET 
            R.areaId = A.IDArea, 
            R.area = A.AreaName
        FROM RepAgentSummary R
        INNER JOIN ccUserView u ON R.userId = u.User_id
        INNER JOIN ccriacat_areas A ON u.IDArea = A.IDArea
        WHERE R.areaId = 0;

        IF @@ROWCOUNT = 0
            BREAK;
    END
';
EXEC (@sql);

SET @process = 'AlterTable RepOutCallsDetail';
SET @sql = N'
IF COL_LENGTH(N''dbo.RepOutCallsDetail'', N''areaId'') IS NULL
BEGIN
    ALTER TABLE dbo.RepOutCallsDetail
      ADD areaId INT NOT NULL
      CONSTRAINT DF_RepOutCallsDetail_areaId DEFAULT (0);
END;

IF COL_LENGTH(N''dbo.RepOutCallsDetail'', N''area'') IS NULL
BEGIN
    ALTER TABLE dbo.RepOutCallsDetail
      ADD area VARCHAR(100) NULL;
END;
';

EXEC(@sql);

SET @process = 'Update: Migracion de Area en RepOutCallsDetail (Por lotes)';
SET @sql = N'
SET NOCOUNT ON;
DECLARE @BatchSize INT = 10000;
WHILE 1 = 1
BEGIN
    UPDATE TOP (@BatchSize) R
    SET R.areaId = A.IDArea, R.area = A.AreaName
    FROM RepOutCallsDetail R
    INNER JOIN cccamps c ON R.campaignId = c.cam_id
    INNER JOIN ccriacat_areas A ON c.IDArea = A.IDArea
    WHERE R.areaId = 0;

    IF @@ROWCOUNT = 0 BREAK;
END
';
EXEC (@sql);



--------------------------------  END Octavio  --------------------------------
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
        
    DELETE RepAgentSummary WHERE loginMktTime BETWEEN @from AND @to;
    DELETE RepAgentSummary_VersionAmatech WHERE loginMktTime BETWEEN @from  AND @to;
    ;
    WITH AgentSession
    AS (
        SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
        FROM RepAgentSession
        WHERE loginTime BETWEEN @from AND @to
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
        ,ISNULL(notReady.TipoNotReadyId, 0) AS TipoNotReadyId
        ,ISNULL(notReady.descripcion, 0) AS descripcion
       ,ISNULL(notReady.descripcion_time, 0) AS descripcion_time
       ,ISNULL(notReady.timeSeconds, 0) AS timeSeconds
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
    
    --------------------------------  END GASJ -------------------------------- 


	------------------------------------- BEGIN MAGV ticket #5325 -----------------------------------------
    

	------------------------------------- END MAGV --------------------------------------
    -------------------------------------------------------BEGIN Octavio Ortiz----------------------------------------------------------------------------------------
    SET @process = 'AlterTable RepInCallsDetail';
    SET @sql = N'
    IF COL_LENGTH(N''dbo.RepInCallsDetail'', N''areaId'') IS NULL
    BEGIN
        ALTER TABLE dbo.RepInCallsDetail
          ADD areaId INT NOT NULL
          CONSTRAINT DF_RepInCallsDetail_areaId DEFAULT (0);
    END;

    IF COL_LENGTH(N''dbo.RepInCallsDetail'', N''area'') IS NULL
    BEGIN
        ALTER TABLE dbo.RepInCallsDetail
          ADD area VARCHAR(100) NULL;
    END;
    ';

    EXEC(@sql);
    
    SET @process = 'Update: Migracion de Area en RepInCallsDetail (Por lotes)';
    SET @sql = N'
    SET NOCOUNT ON;
    DECLARE @BatchSize INT = 10000;
    WHILE 1 = 1
    BEGIN
        UPDATE TOP (@BatchSize) R
        SET R.areaId = A.IDArea, R.area = A.AreaName
        FROM RepInCallsDetail R
        INNER JOIN ccinbound c ON R.inboundId = c.inbound_id
        INNER JOIN ccriacat_areas A ON c.IDArea = A.IDArea
        WHERE R.areaId = 0;

        IF @@ROWCOUNT = 0 BREAK;
    END
    ';
    EXEC (@sql);

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

    SET @process = 'AlterTable RepOutDialDetail';
    SET @sql = N'
    IF COL_LENGTH(N''dbo.RepOutDialDetail'', N''areaId'') IS NULL
    BEGIN
        ALTER TABLE dbo.RepOutDialDetail
          ADD areaId INT NOT NULL
          CONSTRAINT DF_RepOutDialDetail_areaId DEFAULT (0);
    END;

    IF COL_LENGTH(N''dbo.RepOutDialDetail'', N''area'') IS NULL
    BEGIN
        ALTER TABLE dbo.RepOutDialDetail
          ADD area VARCHAR(100) NULL;
    END;
    ';

    EXEC(@sql);

   SET @process = 'Update: Migracion de Area en RepOutDialDetail (Por lotes)';
    SET @sql = N'
    SET NOCOUNT ON;
    DECLARE @BatchSize INT = 10000;
    WHILE 1 = 1
    BEGIN
        UPDATE TOP (@BatchSize) R
        SET R.areaId = A.IDArea, R.area = A.AreaName
        FROM RepOutDialDetail R
        INNER JOIN cccamps c ON R.campaignId = c.cam_id
        INNER JOIN ccriacat_areas A ON c.IDArea = A.IDArea
        WHERE R.areaId = 0;

        IF @@ROWCOUNT = 0 BREAK;
    END
    ';
    EXEC (@sql);


    SET @process = 'AlterTable RepSpecialAbndCamp';
    SET @sql = N'
    IF COL_LENGTH(N''dbo.RepSpecialAbndCamp'', N''areaId'') IS NULL
    BEGIN
        ALTER TABLE dbo.RepSpecialAbndCamp
          ADD areaId INT NOT NULL
          CONSTRAINT DF_RepSpecialAbndCamp_areaId DEFAULT (0);
    END;

    IF COL_LENGTH(N''dbo.RepSpecialAbndCamp'', N''area'') IS NULL
    BEGIN
        ALTER TABLE dbo.RepSpecialAbndCamp
          ADD area VARCHAR(100) NULL;
    END;
    ';

    EXEC(@sql);

    SET @process = 'Update: Migracion de Area en RepSpecialAbndCamp (Por lotes)';
    SET @sql = N'
    SET NOCOUNT ON;
    DECLARE @BatchSize INT = 10000;
    WHILE 1 = 1
    BEGIN
        UPDATE TOP (@BatchSize) R
        SET R.areaId = A.IDArea, R.area = A.AreaName
        FROM RepSpecialAbndCamp R
        INNER JOIN cccamps c ON R.campaignId = c.cam_id
        INNER JOIN ccriacat_areas A ON c.IDArea = A.IDArea
        WHERE R.areaId = 0;

        IF @@ROWCOUNT = 0 BREAK;
    END
    ';
    EXEC (@sql);

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
                  WHEN SUBSTRING(dial.TipoDialingMode, 2, 1) = ''1'' AND co.cal_manual = 0 THEN ''systemTranslated_Assisted'' 
                  WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
                  WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
				  WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(dial.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
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
        ''_Time'' AS descripcion_time,
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
        ''_TimeAux'' AS descripcion_auxiliarRedyTime_time,
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
        descripcion_time,
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
        ISNULL(descripcion_auxiliarRedyTime_time, ''_TimeAux'') AS descripcion_auxiliarRedyTime_time,
        auxiliarRedyTime,
        areaId,
        area
    FROM RepAgentSummary
    '
    EXEC(@sql);

    SET @process = 'UpdatePivotReportsComplementColumns';
    SET @sql = '
        UPDATE PivotReports 
        SET complementColumns = ''date|login|user|loginMktTime|logoutMktTime|sessionTime|unknownStatus|otherStatus|Available|ndTime|transferStatus|ringingTime|callTengaged|twrapup|failureStatus|chatTengaged|dialingStatus|undefinedTime|NCallsOut|NCallsIn|NCallsCorta|NAtend|NNoCalif|avgCallTengaged|area''
        WHERE id = 2100;
    ';
    EXEC(@sql);
    -------------------------------------------------------END Octavio Ortiz----------------------------------------------------------------------------------------
    -------------------------------- BEGIN LMZN 127.20250905.0.8-------------------------------------------------------
	
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
	[date],
	cal_final,
	inboundId as inboundCamp,
	ACDGroup as campaign,
	callStatusId,
	callStatus,
	dispositionId,
	disposition,
	subDispositionId,
	subDisposition,
	dnisId,
	dnis as didNumber,
	userId,
	[user],
	callKey as callKey,
	[source],--new
	[destinationNumber],--new
	callbackDate,--new,
	[cal_tWait] as queueTime,--new
	ANI as aniNumber,
	xferTime,
	ringingTime,
	dialogTime,
	mohTime as holdTime,
	twrapup,
	AverageHandleTime as handleTime,
	extension,
	agentName,
	whoHangUp as endedBy,
	recibeCallBy,
	year,
	month,
	day,
	hour,
	minutes,
	provedorId,
	provider as providerInCallsDetail,
	trunk as trunkInCallsDetail,
	fileMoved,
	Dato1,
	Dato2,
	Dato3,
	Dato4,
	Dato5,
	callid as callId,
	grabId,
	nameDNI,
	numDNI,
	collectCall,
	timeTotalInCallSec,
	timeTotalInCallMin,
	statusCallByIVR,
	IVR_ID as ivrId,
	callHung,
    areaId,
	area
	FROM RepInCallsDetail NOLOCK;
    '
    EXEC(@sql);

    SET @process = 'ALTER ReportsTotals queueTime';
    SET @sql = 'update ReportsTotals set totalColumns = ''sum:queueTime|sum:xferTime|sum:ringingTime|sum:dialogTime|sum:holdTime|sum:twrapup''where id = 3010';
    EXEC(@sql);
    -------------------------------- END LMZN 127.20250905.0.8-------------------------------------------------------
	----------------------------------------- BEGIN MACL KR186000 --------------------------------------
    
    SET @process = 'Alter table  RepOutCallsDetail'
    SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''originNumber''
          AND Object_ID = Object_ID(N''RepOutCallsDetail''))
BEGIN
    ALTER TABLE RepOutCallsDetail ADD 
	originNumber VARCHAR(50),
	callbackDate DATETIME,
	queueTimes INT,
	ringingTime INT
END'
    EXEC(@sql)

	SET @process = 'DROP VIEW RepViewOutCallsDetail'
    SET @sql = 'if exists (select * FROM sys.views where name = N''RepViewOutCallsDetail'')
begin
    DROP VIEW RepViewOutCallsDetail
end'
    EXEC(@sql)

	SET @process = 'UPDATE reportsTotals for report 4020'
    SET @sql = 'update reportsTotals set totalColumns = ''sum:transferTime|sum:queueTimes|sum:dialog|sum:nque|sum:wrapup|sum:duration|sum:ncost|sum:totalRow|sum:ringingTime''
where id = 4020'
    EXEC(@sql)

	SET @process = 'Create View RepViewOutCallsDetail'
    SET @sql = 'CREATE VIEW [dbo].[RepViewOutCallsDetail] AS 
	SELECT
	[date],
	[callKey],
	[originNumber],
	[telephone],
	[transfer] as transferTime,
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
	[login] [agentName],
	[username] [login],
	[campaign],
	[duration],
	[ncost],
	[iva],
	[total] as [totalRow],
	[ByCarrier],
	[Calltypes],
	[dialType],
	[whoHangUp],
	[dialResult] as [callStatus],
	[calId],
	[year],
	[month],
	[day],
	[hour],
	[minutes],
	[trunk],
	[data1] [Dato1],
	[data2] [Dato2],
	[data3] [Dato3],
	[data4] [Dato4],
	[data5] [Dato5],
	[MessageTime],
	[grabId],
	[campaignId],
	[areaId],
	[area]
	FROM RepOutCallsDetail nolock'
    EXEC(@sql)

	SET @process = 'Alter SP ccspRepOutCallsDetail'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
        @action AS TINYINT,
        @from  AS DATETIME = NULL,
        @to    AS DATETIME = NULL
    AS
        IF @from IS NULL
            SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

        IF @to IS NULL
            SELECT @to = GETDATE();
			print(@from)
			print(@to)
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

            INSERT INTO dbo.RepOutCallsDetail
            (
                [date],
                [callKey],
                [telephone],
                [transfer],
                [dialog],
                [nque],
                [wrapup],
                [CallDisposition],
                [extension],
                [userId],
                [login],
                [username],
                [campaignId],
                [campaign],
                [duration],
                [ncost],
                [iva],
                [total],
                [ByCarrier],
                [Calltypes],
                [dialType],
                [whoHangUp],
                [subDisposition],
                [dialResult],
                [calId],
                [year],
                [month],
                [day],
                [hour],
                [minutes],
                [trunk],
                [data1],
                [data2],
                [data3],
                [data4],
                [data5],
                [MessageTime],
                [grabId],
                [areaId],
                [area],
		originNumber,
		callbackDate,
		queueTimes,
		ringingTime
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
                ISNULL(sta.descTranslated,'''') AS  [dialResult], 
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
		ld.ani as originNumber,
		call.cal_fcallback as callbackDate,
		cal_que as queueTimes,
		Call.cal_txfer + call.cal_tring 
		+ CASE WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ld.tDialing ELSE 0 END
		as ringingTime
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
        END'
    EXEC(@sql)

	------------------------------------------ END MACL ---------------------------------------------

	------------------------------------------ BEGIN Rod Salazar ---------------------------------------------

	set @process = 'Fix columnas sin totales'
	set @sql='
	IF EXISTS (select 1 from ReportsTotals where id = 2010)
	BEGIN
		update ReportsTotals set totalColumns = ''sum:tauxiliarready|sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tChatting|sum:tManual|sum:tundefined|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout]),0),0)'' where id = 2010
	END'
	EXEC(@sql)

	set @process = 'insert menu 2110'
	set @sql='
	IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2110)
	BEGIN
		INSERT INTO ccMenus VALUES (2110, ''Tiempos de jornada|Shift Time'', 2000, ''B'', 2, 3, '''', ''59e49d1a69b47480dbea6022fcbb02d186f63530500b9861f99ff8de26f86450'');
	END'
	EXEC(@sql)

	set @process = 'insert menu 2120'
	set @sql='
	IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2120)
	BEGIN
		INSERT INTO ccMenus VALUES (2120, ''Detalle auxiliares por agente|Auxiliary details by agent'', 2100, ''B'', 2, 3, '''', ''fffe3e1af96616008d0b5b3f644e16cf792d8be7cfe33d4b93a43208ee10d77da093aaa985dcf1d0fe1952499fc34801be116ff32af2f5336b1563861cb91646'');  
	END'
	EXEC(@sql)

	set @process = 'insert menu 2130'
	set @sql='
	IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2130)
	BEGIN
		INSERT INTO ccMenus VALUES (2130, ''Detalle de Especial (Auxiliar)|Special Detail (Auxiliary)'', 2000, ''B'', 2, 3, '''', ''d0df11930b9ac68aa5866c2760e456b7b5a686b8d838d01ab8ae7f4db57a2ff1418b4220a5daa1e20c6857d053450c444c77e33264bc19586d1c950b29c2fcb4'');   
	END'
	EXEC(@sql)

	set @process = 'se actualiza sp 7010'
	set @sql='
	if exists (select 1 from ReportsTotals where id = 7010)
	begin
		update ReportsTotals set totalColumns = ''sum:totalInOutCalls|sum:abandonedCalls|avg:abandonedCallsPctg'' where id = 7010
	end'
	EXEC(@sql)
	------------------------------------------ END Rod Salazar ---------------------------------------------
    ------------------------------------------ BEGIN Pavel Martinez ---------------------------------------------

     set @process = 'Se inserta el reporte para Reporte Conversaciones de WA detalle de conversacion Salida'
     set @sql='if not exists (select 1 from ccmenus where menu_id =14010)
        begin
            INSERT INTO ccmenus 
                VALUES (
                    14010, 
                    ''Detalle de conversaciones|Conversations Detail'', 
                    14000, 
                    ''B'', 
                    7, 
                    3, 
                    '''', 
                    ''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370''
                 )
        end '
      EXEC(@sql)
------------------------------------------ END Pavel Martinez ---------------------------------------------

-------------------------------  BEING Marco Díaz -------------------------------- 

SET @process = 'AlterColumn RepSpececialPromises.percentage'

SET @sql = '
IF EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.name = N''percentage''
      AND c.object_id = OBJECT_ID(N''dbo.RepSpececialPromises'')
      AND NOT (
            t.name = N''decimal''
            AND c.precision = 10
            AND c.scale = 4
            AND c.is_nullable = 0
      )
)
BEGIN
    ALTER TABLE dbo.RepSpececialPromises
    ALTER COLUMN percentage DECIMAL(10,4) NOT NULL
END'
EXEC(@sql)

--------------------------------  END Marco Díaz --------------------------------

--------------------------------  BEING Marco Díaz --------------------------------

    set @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialPromises]'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialPromises]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
    select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    DECLARE @data varchar(10), @promesa INT, @promesainb INT
    DECLARE @dummyInbound INT
    SELECT TOP 1 @dummyInbound = inbound_id FROM ccInbound
    select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
    SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
    SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2

    delete RepSpececialPromises with(rowlock)
    where [date] between @from and @to
    
    insert RepSpececialPromises SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_outbound'' [type],
    cout.campaignId campaignId,@dummyInbound inboundId,
    camp.cam_descripcion [campACDDescription],
    ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0) AS promises,
    ISNULL(SUM(cout.count),0) AS total,
    CASE ISNULL(SUM(cout.count),0) WHEN 0 THEN 0 ELSE  
    CONVERT(decimal(10,4),ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0))/ 
    CONVERT(decimal(10,4),ISNULL(SUM(cout.count),0)) END AS percentage 
    FROM RepOutDispositions as cout JOIN ccCamps as camp ON camp.cam_id = cout.campaignId 
    WHERE cout.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cout.campaignId, camp.cam_descripcion
    union all
    SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_inbound'' [type],
    0 campaignId, cin.inboundId inboundId,
    espe.descripcion [campACDDescription],
    ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0) AS promises,
    ISNULL(SUM(cin.count),0) AS TOTAL,
    CASE ISNULL(SUM(cin.count),0) WHEN 0 THEN 0 ELSE
    CONVERT(decimal(10,4),ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0))/ 
    CONVERT(decimal(10,4),ISNULL(SUM(cin.count),0)) END AS percentage
    FROM RepInDispositions as cin JOIN ccInbound as espe ON espe.inbound_id = cin.inboundId
    WHERE cin.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cin.inboundId, espe.descripcion
end'
    EXEC(@sql)

--------------------------------  END Marco Díaz -------------------------------------------------------------------------

--------------------------------------------------------BEGIN Marco Diaz----------------------------------------------------------------------

SET @process = 'CLEAN DUPLICATES RepInNotTransferred';

SET @sql = '
IF EXISTS (
    SELECT 1
    FROM RepInNotTransferred
    GROUP BY date, inboundId, callStatusId, workgroupId, phonein
    HAVING COUNT(*) > 1
)
BEGIN

    WITH duplicates AS
    (
        SELECT *,
        ROW_NUMBER() OVER(
        PARTITION BY 
            date,
            inboundId,
            callStatusId,
            workgroupId,
            phonein
        ORDER BY date
        ) AS rn
        FROM RepInNotTransferred
    )
    DELETE FROM duplicates
    WHERE rn > 1

END
'

EXEC(@sql)



SET @process = 'CREATE UNIQUE INDEX UX_RepInNotTransferred_NoDuplicates';

SET @sql = '
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = ''UX_RepInNotTransferred_NoDuplicates''
      AND object_id = OBJECT_ID(''dbo.RepInNotTransferred'')
)
BEGIN

    CREATE UNIQUE INDEX UX_RepInNotTransferred_NoDuplicates
    ON dbo.RepInNotTransferred
    (
        date,
        inboundId,
        callStatusId,
        workgroupId,
        phonein
    )

END
'

EXEC(@sql)

--------------------------------------------------------END Marco Diaz----------------------------------------------------------------------

------------------------------BEGIN Jesus Gallardo MED Nova Monti 9---------------------------------

set @process = '#6535 ALTER VIEW [dbo].[ccUserView] isnull(IDArea,1)'
set @sql='ALTER VIEW [dbo].[ccUserView] AS
SELECT 
    User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
    TipoStatusAge_id, TipoUser_id, Status, Sexo, isnull(IDArea,1) IDArea, fCreate 
FROM ccUsers
UNION
SELECT 
    User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
    TipoStatusAge_id, TipoUser_id, Status, Sexo, isnull(IDArea,1) IDArea, fCreate 
FROM ccUsers_Consulta;'
EXEC(@sql)



SET @process = '#7806 DROP INDEX repetidos'
SET @sql = '
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentGI_date''AND object_id = OBJECT_ID(''RepAgentGI'') ) BEGIN DROP INDEX IX_RepAgentGI_date ON RepAgentGI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentKPI_date''AND object_id = OBJECT_ID(''RepAgentKPI'') ) BEGIN DROP INDEX IX_RepAgentKPI_date ON RepAgentKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentNotReady_date''AND object_id = OBJECT_ID(''RepAgentNotReady'') ) BEGIN DROP INDEX IX_RepAgentNotReady_date ON RepAgentNotReady END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentNotReadyDet_date''AND object_id = OBJECT_ID(''RepAgentNotReadyDet'') ) BEGIN DROP INDEX IX_RepAgentNotReadyDet_date ON RepAgentNotReadyDet END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentSession_date''AND object_id = OBJECT_ID(''RepAgentSession'') ) BEGIN DROP INDEX IX_RepAgentSession_date ON RepAgentSession END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentSessionByInterval_date''AND object_id = OBJECT_ID(''RepAgentSessionByInterval'') ) BEGIN DROP INDEX IX_RepAgentSessionByInterval_date ON RepAgentSessionByInterval END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentTimeShift_date''AND object_id = OBJECT_ID(''RepAgentTimeShift'') ) BEGIN DROP INDEX IX_RepAgentTimeShift_date ON RepAgentTimeShift END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAuxiliariesByAgentDet_date''AND object_id = OBJECT_ID(''RepAuxiliariesByAgentDet'') ) BEGIN DROP INDEX IX_RepAuxiliariesByAgentDet_date ON RepAuxiliariesByAgentDet END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInChangeFlow''AND object_id = OBJECT_ID(''RepInChangeFlow'') ) BEGIN DROP INDEX IX_RepInChangeFlow ON RepInChangeFlow END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInChangeFlow_date''AND object_id = OBJECT_ID(''RepInChangeFlow'') ) BEGIN DROP INDEX IX_RepInChangeFlow_date ON RepInChangeFlow END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInNotTransferred''AND object_id = OBJECT_ID(''RepInNotTransferred'') ) BEGIN DROP INDEX IX_RepInNotTransferred ON RepInNotTransferred END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInNotTransferred_date''AND object_id = OBJECT_ID(''RepInNotTransferred'') ) BEGIN DROP INDEX IX_RepInNotTransferred_date ON RepInNotTransferred END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDialDetail''AND object_id = OBJECT_ID(''RepOutDialDetail'') ) BEGIN DROP INDEX IX_RepOutDialDetail ON RepOutDialDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDialDetail_date''AND object_id = OBJECT_ID(''RepOutDialDetail'') ) BEGIN DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpecialRecordingsDownload_date''AND object_id = OBJECT_ID(''RepSpecialRecordingsDownload'') ) BEGIN DROP INDEX IX_RepSpecialRecordingsDownload_date ON RepSpecialRecordingsDownload END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpecialStatusDetail_date''AND object_id = OBJECT_ID(''RepSpecialStatusDetail'') ) BEGIN DROP INDEX IX_RepSpecialStatusDetail_date ON RepSpecialStatusDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepWhatsAppByCampaignIn_date''AND object_id = OBJECT_ID(''RepWhatsAppByCampaignIn'') ) BEGIN DROP INDEX IX_RepWhatsAppByCampaignIn_date ON RepWhatsAppByCampaignIn END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepWhatsAppByCampaignOut_date''AND object_id = OBJECT_ID(''RepWhatsAppByCampaignOut'') ) BEGIN DROP INDEX IX_RepWhatsAppByCampaignOut_date ON RepWhatsAppByCampaignOut END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepWhatsAppDetailConversationIn_date''AND object_id = OBJECT_ID(''RepWhatsAppDetailConversationIn'') ) BEGIN DROP INDEX IX_RepWhatsAppDetailConversationIn_date ON RepWhatsAppDetailConversationIn END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepWhatsAppDetailConversationOut_date''AND object_id = OBJECT_ID(''RepWhatsAppDetailConversationOut'') ) BEGIN DROP INDEX IX_RepWhatsAppDetailConversationOut_date ON RepWhatsAppDetailConversationOut END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepWhatsConversationsMarkedAsSpam_date''AND object_id = OBJECT_ID(''RepWhatsConversationsMarkedAsSpam'') ) BEGIN DROP INDEX IX_RepWhatsConversationsMarkedAsSpam_date ON RepWhatsConversationsMarkedAsSpam END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepWhatsConversationsUnassigned_date''AND object_id = OBJECT_ID(''RepWhatsConversationsUnassigned'') ) BEGIN DROP INDEX IX_RepWhatsConversationsUnassigned_date ON RepWhatsConversationsUnassigned END


IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepACDChats''AND object_id = OBJECT_ID(''RepACDChats'') ) BEGIN DROP INDEX IX_RepACDChats ON RepACDChats END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentCallStatusesByInterval''AND object_id = OBJECT_ID(''RepAgentCallStatusesByInterval'') ) BEGIN DROP INDEX IX_RepAgentCallStatusesByInterval ON RepAgentCallStatusesByInterval END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentGI_VersionOld''AND object_id = OBJECT_ID(''RepAgentGI_VersionOld'') ) BEGIN DROP INDEX IX_RepAgentGI_VersionOld ON RepAgentGI_VersionOld END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentHSBCKPI''AND object_id = OBJECT_ID(''RepAgentHSBCKPI'') ) BEGIN DROP INDEX IX_RepAgentHSBCKPI ON RepAgentHSBCKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentSummary''AND object_id = OBJECT_ID(''RepAgentSummary'') ) BEGIN DROP INDEX IX_RepAgentSummary ON RepAgentSummary END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAnsweredCallsByDialingRetries''AND object_id = OBJECT_ID(''RepAnsweredCallsByDialingRetries'') ) BEGIN DROP INDEX IX_RepAnsweredCallsByDialingRetries ON RepAnsweredCallsByDialingRetries END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAvgAnswerTimeChats''AND object_id = OBJECT_ID(''RepAvgAnswerTimeChats'') ) BEGIN DROP INDEX IX_RepAvgAnswerTimeChats ON RepAvgAnswerTimeChats END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAVRSDisposition''AND object_id = OBJECT_ID(''RepAVRSDisposition'') ) BEGIN DROP INDEX IX_RepAVRSDisposition ON RepAVRSDisposition END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepCallTimeSummary''AND object_id = OBJECT_ID(''RepCallTimeSummary'') ) BEGIN DROP INDEX IX_RepCallTimeSummary ON RepCallTimeSummary END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepCallXfer''AND object_id = OBJECT_ID(''RepCallXfer'') ) BEGIN DROP INDEX IX_RepCallXfer ON RepCallXfer END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsAndCallsGeneral''AND object_id = OBJECT_ID(''RepChatsAndCallsGeneral'') ) BEGIN DROP INDEX IX_RepChatsAndCallsGeneral ON RepChatsAndCallsGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsDetail''AND object_id = OBJECT_ID(''RepChatsDetail'') ) BEGIN DROP INDEX IX_RepChatsDetail ON RepChatsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsEffectiveness''AND object_id = OBJECT_ID(''RepChatsEffectiveness'') ) BEGIN DROP INDEX IX_RepChatsEffectiveness ON RepChatsEffectiveness END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsNotContacted''AND object_id = OBJECT_ID(''RepChatsNotContacted'') ) BEGIN DROP INDEX IX_RepChatsNotContacted ON RepChatsNotContacted END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepDetailAgent''AND object_id = OBJECT_ID(''RepDetailAgent'') ) BEGIN DROP INDEX IX_RepDetailAgent ON RepDetailAgent END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepDialingResultsDetail''AND object_id = OBJECT_ID(''RepDialingResultsDetail'') ) BEGIN DROP INDEX IX_RepDialingResultsDetail ON RepDialingResultsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailACD''AND object_id = OBJECT_ID(''RepEmailACD'') ) BEGIN DROP INDEX IX_RepEmailACD ON RepEmailACD END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailAgente''AND object_id = OBJECT_ID(''RepEmailAgente'') ) BEGIN DROP INDEX IX_RepEmailAgente ON RepEmailAgente END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailDetail''AND object_id = OBJECT_ID(''RepEmailDetail'') ) BEGIN DROP INDEX IX_RepEmailDetail ON RepEmailDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailGeneral''AND object_id = OBJECT_ID(''RepEmailGeneral'') ) BEGIN DROP INDEX IX_RepEmailGeneral ON RepEmailGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInAbnd''AND object_id = OBJECT_ID(''RepInAbnd'') ) BEGIN DROP INDEX IX_RepInAbnd ON RepInAbnd END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInAnsw''AND object_id = OBJECT_ID(''RepInAnsw'') ) BEGIN DROP INDEX IX_RepInAnsw ON RepInAnsw END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInBill01900''AND object_id = OBJECT_ID(''RepInBill01900'') ) BEGIN DROP INDEX IX_RepInBill01900 ON RepInBill01900 END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInboundKPI''AND object_id = OBJECT_ID(''RepInboundKPI'') ) BEGIN DROP INDEX IX_RepInboundKPI ON RepInboundKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInCalls''AND object_id = OBJECT_ID(''RepInCalls'') ) BEGIN DROP INDEX IX_RepInCalls ON RepInCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInCallsDetail''AND object_id = OBJECT_ID(''RepInCallsDetail'') ) BEGIN DROP INDEX IX_RepInCallsDetail ON RepInCallsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInDIDResume''AND object_id = OBJECT_ID(''RepInDIDResume'') ) BEGIN DROP INDEX IX_RepInDIDResume ON RepInDIDResume END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInDispositions''AND object_id = OBJECT_ID(''RepInDispositions'') ) BEGIN DROP INDEX IX_RepInDispositions ON RepInDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInEffectiveness''AND object_id = OBJECT_ID(''RepInEffectiveness'') ) BEGIN DROP INDEX IX_RepInEffectiveness ON RepInEffectiveness END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInRejectedCalls''AND object_id = OBJECT_ID(''RepInRejectedCalls'') ) BEGIN DROP INDEX IX_RepInRejectedCalls ON RepInRejectedCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInSubDispositions''AND object_id = OBJECT_ID(''RepInSubDispositions'') ) BEGIN DROP INDEX IX_RepInSubDispositions ON RepInSubDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInTrunkBusy''AND object_id = OBJECT_ID(''RepInTrunkBusy'') ) BEGIN DROP INDEX IX_RepInTrunkBusy ON RepInTrunkBusy END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRByOptions''AND object_id = OBJECT_ID(''RepIVRByOptions'') ) BEGIN DROP INDEX IX_RepIVRByOptions ON RepIVRByOptions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRDetail''AND object_id = OBJECT_ID(''RepIVRDetail'') ) BEGIN DROP INDEX IX_RepIVRDetail ON RepIVRDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRFirstOption''AND object_id = OBJECT_ID(''RepIVRFirstOption'') ) BEGIN DROP INDEX IX_RepIVRFirstOption ON RepIVRFirstOption END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRGeneral''AND object_id = OBJECT_ID(''RepIVRGeneral'') ) BEGIN DROP INDEX IX_RepIVRGeneral ON RepIVRGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepMKTTiemposTotales_1''AND object_id = OBJECT_ID(''RepMKTTiemposTotales'') ) BEGIN DROP INDEX IX_RepMKTTiemposTotales_1 ON RepMKTTiemposTotales END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutAnswCalls''AND object_id = OBJECT_ID(''RepOutAnswCalls'') ) BEGIN DROP INDEX IX_RepOutAnswCalls ON RepOutAnswCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutboundKPI''AND object_id = OBJECT_ID(''RepOutboundKPI'') ) BEGIN DROP INDEX IX_RepOutboundKPI ON RepOutboundKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallBacks''AND object_id = OBJECT_ID(''RepOutCallBacks'') ) BEGIN DROP INDEX IX_RepOutCallBacks ON RepOutCallBacks END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCalls''AND object_id = OBJECT_ID(''RepOutCalls'') ) BEGIN DROP INDEX IX_RepOutCalls ON RepOutCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallsByTelephone''AND object_id = OBJECT_ID(''RepOutCallsByTelephone'') ) BEGIN DROP INDEX IX_RepOutCallsByTelephone ON RepOutCallsByTelephone END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallsDetail''AND object_id = OBJECT_ID(''RepOutCallsDetail'') ) BEGIN DROP INDEX IX_RepOutCallsDetail ON RepOutCallsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallsOnChatDetail''AND object_id = OBJECT_ID(''RepOutCallsOnChatDetail'') ) BEGIN DROP INDEX IX_RepOutCallsOnChatDetail ON RepOutCallsOnChatDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDials''AND object_id = OBJECT_ID(''RepOutDials'') ) BEGIN DROP INDEX IX_RepOutDials ON RepOutDials END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDispositions''AND object_id = OBJECT_ID(''RepOutDispositions'') ) BEGIN DROP INDEX IX_RepOutDispositions ON RepOutDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutKPI''AND object_id = OBJECT_ID(''RepOutKPI'') ) BEGIN DROP INDEX IX_RepOutKPI ON RepOutKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutManagementBase_1''AND object_id = OBJECT_ID(''RepOutManagementBase'') ) BEGIN DROP INDEX IX_RepOutManagementBase_1 ON RepOutManagementBase END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutSubDispositions''AND object_id = OBJECT_ID(''RepOutSubDispositions'') ) BEGIN DROP INDEX IX_RepOutSubDispositions ON RepOutSubDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutTrunkBusy''AND object_id = OBJECT_ID(''RepOutTrunkBusy'') ) BEGIN DROP INDEX IX_RepOutTrunkBusy ON RepOutTrunkBusy END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialAbnd''AND object_id = OBJECT_ID(''RepSpececialAbnd'') ) BEGIN DROP INDEX IX_RepSpececialAbnd ON RepSpececialAbnd END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialAgent''AND object_id = OBJECT_ID(''RepSpececialAgent'') ) BEGIN DROP INDEX IX_RepSpececialAgent ON RepSpececialAgent END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialAgtPerformance''AND object_id = OBJECT_ID(''RepSpececialAgtPerformance'') ) BEGIN DROP INDEX IX_RepSpececialAgtPerformance ON RepSpececialAgtPerformance END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialCamMovs''AND object_id = OBJECT_ID(''RepSpececialCamMovs'') ) BEGIN DROP INDEX IX_RepSpececialCamMovs ON RepSpececialCamMovs END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialPromises''AND object_id = OBJECT_ID(''RepSpececialPromises'') ) BEGIN DROP INDEX IX_RepSpececialPromises ON RepSpececialPromises END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpecialCallKeyHistory''AND object_id = OBJECT_ID(''RepSpecialCallKeyHistory'') ) BEGIN DROP INDEX IX_RepSpecialCallKeyHistory ON RepSpecialCallKeyHistory END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpecialTimes''AND object_id = OBJECT_ID(''RepSpecialTimes'') ) BEGIN DROP INDEX IX_RepSpecialTimes ON RepSpecialTimes END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepTrunkBusy''AND object_id = OBJECT_ID(''RepTrunkBusy'') ) BEGIN DROP INDEX IX_RepTrunkBusy ON RepTrunkBusy END'
EXEC(@sql)


SET @process = '#7806 ALTER PROCEDURE [dbo].[ccSpCreateIndexReport] se quita los inidices en reportes'
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

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_8'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
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


    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end'
EXEC(@sql)


SET @process = '#7806  CREATE NONCLUSTERED INDEX [IX_ccoLogDials_cal_id_logDial]'
SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = ''IX_ccoLogDials_cal_id_logDial''
      AND i.object_id = OBJECT_ID(''dbo.ccoLogDials'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ccoLogDials_cal_id_logDial]
    ON [dbo].[ccoLogDials] ([cal_id] desc)
    INCLUDE ([logDial_id])
END'
EXEC(@sql)


SET @process = '#7806 CREATE NONCLUSTERED INDEX IX_ccoLogDials_fecha_repOutDialDetail'
SET @sql = 'IF NOT EXISTS (
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
END'
EXEC(@sql)


SET @process = '#7806 CREATE NONCLUSTERED INDEX IX_ccoCallsOut_cal_id_repOutDialDetail'
SET @sql = 'IF NOT EXISTS (
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
END'
EXEC(@sql)

SET @process = 'KR140003 - Tabla nueva en BD de Reporte de Detalle de Marcación'
    SET @sql = '
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''ccoLogDialsData'')
BEGIN
    CREATE TABLE ccoLogDialsData(
        logDial_id INT NOT NULL PRIMARY KEY,
        callout_id INT NOT NULL,
        Data1 VARCHAR(255) NOT NULL,
        Data2 VARCHAR(255) NOT NULL,
        Data3 VARCHAR(255) NOT NULL,
        Data4 VARCHAR(255) NOT NULL,
        Data5 VARCHAR(255) NOT NULL,
        callDate DATETIME NOT NULL
    )

    CREATE INDEX IX_ccoLogDialsData ON ccoLogDialsData (callout_id, callDate)
END'
    EXEC(@sql)


SET @process = '#7806  CREATE NONCLUSTERED INDEX IX_ccoLogDialsData_logDial_repOutDialDetail'
SET @sql = 'IF NOT EXISTS (
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
END'
EXEC(@sql)


SET @process = '#7806  DROP INDEX IX_RepOutDialDetail ON RepOutDialDetail;'
SET @sql = 'IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''IX_RepOutDialDetail''
    AND object_id = OBJECT_ID(''RepOutDialDetail'')
)
BEGIN
    DROP INDEX IX_RepOutDialDetail ON RepOutDialDetail;
END'
EXEC(@sql)


SET @process = '#7806 DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail'
SET @sql = 'IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''IX_RepOutDialDetail_date''
    AND object_id = OBJECT_ID(''RepOutDialDetail'')
)
BEGIN
    DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail;
END'
EXEC(@sql)

SET @process = 'Configuración de Menú (2150) - Agentes Virtuales';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2150)
BEGIN
    INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) 
    VALUES (2150, ''Agentes virtuales|Virtual Agents'', 2000, ''B'', 2, 3, '''', ''505b0c30ff896f2db7e7b7946607de282293a6ed731cb58b9192c6d4a764bb05'');
    PRINT ''Menú 2150 insertado en ccMenus.'';
END

IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 2150)
BEGIN
    INSERT INTO ccMenuUser (id_User, id_Menu, type) 
    VALUES (1, 2150, 3);
    PRINT ''Permiso asignado al usuario 1 en ccMenuUser.'';
END
'
EXEC(@sql);

------------------------------------ BEGIN Nueva Tabla RepVirtualAgent ------------------------------------
SET @process = 'Creación segura de tabla RepVirtualAgent e índices';

SET @sql = '
IF OBJECT_ID(''[dbo].[RepVirtualAgent]'', ''U'') IS NULL
BEGIN
    CREATE TABLE [dbo].[RepVirtualAgent] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [idAgent] INT NOT NULL,
        [Date] DATETIME NOT NULL,                   
        [ModelName] VARCHAR(255) NOT NULL,            
        [CampaignName] VARCHAR(50) NOT NULL,         
        [CallsHandled] INT NOT NULL,                 
        [CallsTransferred] INT NOT NULL,             
        [AverageHandleTime] INT NOT NULL,     
        [activeTime] INT NOT NULL             
    );
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''idAgent'' AND Object_ID = Object_ID(N''dbo.RepVirtualAgent''))
    BEGIN
        ALTER TABLE dbo.RepVirtualAgent ADD idAgent INT NOT NULL DEFAULT 0;
    END
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepVirtualAgent_ReportDate_ModelName'' AND object_id = OBJECT_ID(''[dbo].[RepVirtualAgent]''))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepVirtualAgent_ReportDate_ModelName] ON [dbo].[RepVirtualAgent] ([Date], [ModelName]);
END
'
EXEC(@sql);

------------------------------------ BEGIN Ajustes Tablas y Vistas ------------------------------------
SET @process = 'Agregar columnas a tablas Detalle y actualizar vistas';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''ModelName'' AND Object_ID = Object_ID(N''dbo.RepInCallsDetail''))
    ALTER TABLE dbo.RepInCallsDetail ADD ModelName VARCHAR(MAX) DEFAULT ''N/A'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.RepInCallsDetail''))
    ALTER TABLE dbo.RepInCallsDetail ADD CapturedData VARCHAR(MAX) DEFAULT '''';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''ModelName'' AND Object_ID = Object_ID(N''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD ModelName VARCHAR(MAX) DEFAULT ''N/A'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''ani'' AND Object_ID = Object_ID(N''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD ani VARCHAR(MAX) DEFAULT ''N/A'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD CapturedData VARCHAR(MAX) DEFAULT '''';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''calId'' AND Object_ID = Object_ID(''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD calId INT DEFAULT 0;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''dialog'' AND Object_ID = Object_ID(''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD dialog INT DEFAULT 0;
'
EXEC(@sql);

SET @sql = '
ALTER VIEW [dbo].[RepViewInCallsDetail] AS  
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
    [user],
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
    agentName,
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
FROM RepInCallsDetail WITH (NOLOCK);
'
EXEC(@sql);

SET @sql = '
ALTER VIEW [dbo].[RepOutDialDetailView] AS 
SELECT [date],
    [calId],
    [callKey],
    [telephone],
    [dialResultId],
    [dialResult],
    [dialog],
    [campaignId],
    [campaign],
    ModelName,
    [timeMessage],
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    [listName],
    [billed],
    [CapturedData],
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
    [area],
    [ani]
FROM RepOutDialDetail WITH (NOLOCK);
'
EXEC(@sql);

------------------------------------ BEGIN Configuración Filtros ------------------------------------
SET @process = 'Configuración de Filtros para Reporte Virtual Agent';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM Filters WHERE id = 37)
    INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode) VALUES (37, ''CampaignName'', 37, ''CampaignName'', ''CampaignName'');

IF NOT EXISTS (SELECT 1 FROM Filters WHERE id = 38)
    INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode) VALUES (38, ''ModelName'', 38, ''ModelName'', ''ModelName'');

IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE id = 2150 AND filterName = ''CampaignName'')
    INSERT INTO ReportsFilters (reportName, filterName, id) VALUES (''Virtual Agent'', ''CampaignName'', 2150);

IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE id = 2150 AND filterName = ''ModelName'')
    INSERT INTO ReportsFilters (reportName, filterName, id) VALUES (''Virtual Agent'', ''ModelName'', 2150);

IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE filterName = ''ModelName'' AND id = 3010)
BEGIN
    Insert into ReportsFilters VALUES(''Virtual Agent'',''ModelName'',3010)
END
IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE filterName = ''ModelName'' AND id = 4010)
BEGIN
  Insert into ReportsFilters VALUES(''Virtual Agent'',''ModelName'',4010)
END
'
EXEC(@sql);

------------------------------------ BEGIN Agentes Virtuales (SP) ------------------------------------
SET @process = 'SP ccspRepVirtualAgent';

SET @sql = '
IF OBJECT_ID(''[dbo].[ccspRepVirtualAgent]'') IS NULL
BEGIN
    EXEC(''CREATE PROCEDURE [dbo].[ccspRepVirtualAgent] AS RETURN 0'')
END
'
EXEC(@sql);

SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepVirtualAgent]
    @action tinyint,
    @from   DATETIME,
    @to     DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    IF (@action = 1)
    BEGIN
        -- 1. LIMPIEZA PREVIA
        DELETE [dbo].[RepVirtualAgent]
        WHERE [date] >= @from
          AND [date] <  @to;

        ;WITH

        CTE_RawCalls AS (
            SELECT
                ci.User_id                                          AS idAgent,
                ci.Inbound_id,
                ci.cal_id,
                CAST(ci.cal_tDialog AS INT)                         AS tDialogSec,
                CAST(ci.cal_Inicio  AS DATE)                        AS CallDate,
                ci.cal_Inicio                                       AS StartTime,
                DATEADD(SECOND, CAST(ci.cal_tDialog AS INT),
                        ci.cal_Inicio)                              AS EndTime,
                CASE WHEN lt.cal_id IS NOT NULL THEN 1 ELSE 0 END   AS IsTransferred

            FROM ccCallsIn ci WITH (NOLOCK)

            LEFT JOIN (
                SELECT DISTINCT cal_id
                FROM ccLogTransfers
                WHERE tipo = 1
            ) lt ON ci.cal_id = lt.cal_id

            WHERE ci.cal_Inicio >= @from
              AND ci.cal_Inicio <  @to
              AND ci.cal_tDialog > 0
        ),

        CTE_VolumeMetrics AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                COUNT(cal_id)       AS CallsHandled,
                SUM(IsTransferred)  AS CallsTransferred,
                SUM(tDialogSec)     AS TotalDialogTime
            FROM CTE_RawCalls
            GROUP BY idAgent, Inbound_id, CallDate
        ),

        CTE_OrderedCalls AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                StartTime,
                EndTime,
                LAG(EndTime) OVER (
                    PARTITION BY idAgent, Inbound_id, CallDate
                    ORDER BY StartTime
                ) AS PrevEndTime
            FROM CTE_RawCalls
        ),

        CTE_IslandFlags AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                StartTime,
                EndTime,
                CASE
                    WHEN PrevEndTime IS NULL OR StartTime > PrevEndTime THEN 1
                    ELSE 0
                END AS IsNewIsland
            FROM CTE_OrderedCalls
        ),

        CTE_Islands AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                StartTime,
                EndTime,
                SUM(IsNewIsland) OVER (
                    PARTITION BY idAgent, Inbound_id, CallDate
                    ORDER BY StartTime
                    ROWS UNBOUNDED PRECEDING
                ) AS IslandID
            FROM CTE_IslandFlags
        ),

        CTE_UptimeByIsland AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                IslandID,
                DATEDIFF(SECOND, MIN(StartTime), MAX(EndTime)) AS IslandSeconds
            FROM CTE_Islands
            GROUP BY idAgent, Inbound_id, CallDate, IslandID
        ),

        CTE_TotalUptime AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                SUM(IslandSeconds) AS FinalUptime
            FROM CTE_UptimeByIsland
            GROUP BY idAgent, Inbound_id, CallDate
        )

        INSERT INTO [dbo].[RepVirtualAgent] (
            [idAgent],
            [Date],
            [ModelName],
            [CampaignName],
            [CallsHandled],
            [CallsTransferred],
            [AverageHandleTime],
            [activeTime]
        )
        SELECT
            vm.idAgent,
            vm.CallDate,
            va.nameAgent,
            camp.descripcion,
            vm.CallsHandled,
            vm.CallsTransferred,
            vm.TotalDialogTime / vm.CallsHandled,  -- CallsHandled >= 1 por el filtro tDialogSec > 0
            tu.FinalUptime

        FROM CTE_VolumeMetrics vm
        INNER JOIN CTE_TotalUptime tu
            ON  vm.idAgent    = tu.idAgent
            AND vm.Inbound_id = tu.Inbound_id
            AND vm.CallDate   = tu.CallDate
        INNER JOIN ccVirtualAgent va WITH (NOLOCK)
            ON vm.idAgent = va.idAgent
        INNER JOIN ccInbound camp WITH (NOLOCK)
            ON vm.Inbound_id = camp.Inbound_id;

    END
END'
EXEC(@sql);

SET @process = 'Insert ccspRepVirtualAgent in to ReportHighUse';

SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportHighUse WHERE nameSp = ''ccspRepVirtualAgent'')
BEGIN
    INSERT INTO ReportHighUse VALUES (''ccspRepVirtualAgent'')
END'
EXEC(@sql);

------------------------------------ BEGIN Update ccspRepCatalogos ------------------------------------
SET @process = 'SP ccspRepCatalogos';

SET @sql = '
IF OBJECT_ID(''[dbo].[ccspRepCatalogos]'') IS NULL
BEGIN
    EXEC(''CREATE PROCEDURE [dbo].[ccspRepCatalogos] AS RETURN 0'')
END
'
EXEC(@sql);

SET @sql = 'ALTER  PROCEDURE [dbo].[ccspRepCatalogos]
        @type as tinyint,
        @action tinyint = 0 -- 0 Filter select; 1 Filters Range
        ,@userId int =0 ---- se agrega parametro para filtros
        ,@menuId INT = 0

        AS
        declare @tablatemp table (id int, description varchar(100) null)
        declare @tempwork table (idwg int)
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @condition NVARCHAR(300) = '''';
        DECLARE @columnName NVARCHAR(100) = '''';
        DECLARE @consult NVARCHAR (2000) = '''';

        if @action = 0
        BEGIN
        IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
        BEGIN
            CREATE TABLE #filters ([Type] VARCHAR(200))
        END

            -- CAMPAIGNS
        IF @type = 1 BEGIN

    
            INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
            IF EXISTS (SELECT * FROM #filters)
            BEGIN
                SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
                SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
            END
            ELSE BEGIN
                SET @columnName =   ''campaignId'';
            END

            SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

            IF @userId <> 0 BEGIN
            
                DECLARE @isJustVoiceFilter BIT = CASE WHEN @menuId IN (4010) THEN 1 ELSE 0 END;

                SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null) 
                    insert into @tablatemp
                    select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
                    inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
                    inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1'';

               IF @isJustVoiceFilter = 1
               BEGIN 
                    SET @SQL += '' INNER JOIN dbo.cccamps AS c ON caesp.IdCampEsp = c.cam_id ''
               END

               SET @SQL += '' where us.[User_id] = @userId '';

               IF @isJustVoiceFilter = 1
               BEGIN 
                    SET @SQL += '' AND c.CampType IN (0,6,9) '';
               END
           
                
                SET @sql +=''if exists(select 1 from @tablatemp) begin ''
                    + @consult + '' inner join @tablatemp A on camp.cam_id = A.id '' + @condition
                    +''end
                    else begin
                        SELECT 0 as id, ''''N/A'''' as description, ''''campaignId'''' as dbColumn
                    end'';
            END
            ELSE BEGIN
                SET @SQL = @consult + @condition;
            END
            EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
        
        END


            -- DIAL RESULTS
        if @type = 2 begin
            Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
            from ccTipoResultadoDial
            order by descripcion
        end

            -- WORKGROUPS
        if @type = 3 begin
            if @userId <> 0 begin
                select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
                from ccWgByAcdView v
                inner join ccriacat_workgroup c on c.IDWG=v.IDWG
                where USER_ID= @userId
                return
            end
            else  begin
                select idwg as id, wgname as description, ''workgroupId'' as dbColumn
                from ccRIACat_WorkGroup
                group by idwg, wgname   select * from ccRIACat_WorkGroup
                order by wgname
            end
        end


        -- AREAS
        if @type = 4 begin
        if @userId <> 0 begin

            insert into @tablatemp
            select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
            inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
            where us.[User_id] = @userId

            select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
            from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
            return
        end
            else begin

                select idArea as id, AreaName as description, ''areaId'' as dbColumn
                from ccRIACat_Areas
                group by idArea, AreaName
                order by AreaName
            end
        end

        -- DISPOSITIONS OUT
        if @type = 5 begin
            SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
            FROM ccTipoCalifOut
            order by [description]
        end

            -- USER
        if @type = 6    begin
            if @userId <> 0 begin

                    insert into @tempwork
                            select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

                    select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
                    inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

                    inner join @tempwork awg on wgu.IDWG = awg.idwg
                    where us.TipoUser_id = 1 and [status] = 1

                    return
                end

                else begin

                    SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
                    FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
                    ORDER BY description
                end
        end

            -- ACDS**************
        IF @type = 7 BEGIN

            INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
            IF EXISTS (SELECT * FROM #filters)
            BEGIN
                SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
                SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
            END
            ELSE BEGIN
                SET @columnName = ''inboundId'';
            END

            SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
                FROM ccinbound B''

            IF @userId <> 0 BEGIN

                SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
                    insert into @tablatemp
                    select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
                    inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
                    inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
                    where us.[User_id] = @userId;''
                    +''if exists(select 1 from @tablatemp) begin''
                    + @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;''
                    +''end
                    else begin
                        SELECT 0 as id, ''''N/A'''' as description, ''''inboundId'''' as dbColumn
                    end'';   
            END
            ELSE BEGIN
                SET @SQL = @consult + @condition;
            END
            EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
        end

            -- DIDS
        if @type = 8    begin
            select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
            union
            select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
            from ccdnis
        end

            --DISPOSITIONS IN
        if @type = 9 begin
            SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
            FROM ccTipoCalif
            order by [description]
        end

            --SUBDISPOSITIONS IN
        if @type = 10   begin
            SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
            FROM ccTipoCalifSub
            order by [description]
        end

            --PROVIDER
        if @type = 11 begin
            SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
            FROM cstoProvedor
            order by [description]
        end

            -- UNAVAILABLES
        if @type = 12 begin
            SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
            FROM cctiponotready
            order by descripcion
        end

            -- DIALERS
        if @type = 13 begin
            SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
            FROM ccoDialers
            order by descripcion
        end

            -- CallTYpes
        if @type = 14   begin
                SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
                FROM ccStatusLlamada
            order by descripcion
        end

            -- SUBDISPOSITIONS OUT
        if @type = 21   begin
            SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
            FROM cctipocalifsubout
            order by [description]
        end

            --AVRS TEMPLATE-SECTION
        if @type = 15   begin
            SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
            FROM RIA_FORMATOCONCEPTO fc
            INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
                                            FROM RIA_FORMATOS
                                            WHERE activo = 1
                                            group by id_formato, nombre) as rf
            ON rf.id_formato = fc.templateId
            inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
            order by fc.id
        END

        --exec dbo.ccspRepCatalogos @type=15,@action=0

            --AVRS TEMPLATES
        if @type = 16   begin
            SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
            FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
                                            FROM RIA_FORMATOS
                                            WHERE activo = 1
                                            group by id_formato) as t
            ON f.id_formato = t.id_formato AND f.version = t.version
            order by f.nombre
        end

            --AVRS TEMPLATES
        if @type = 31   begin
            SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
            FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
                                            FROM RIA_CONCEPTOS
                                            group by id_concepto) as t
            ON c.id_concepto = t.id_concepto AND c.version = t.version
            order by c.con_descripcion
        END

            --AVRS QUESTIONS
        if @type = 23   begin
            SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
            FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
                                            FROM RIA_PREGUNTAS
                                            group by id_pregunta) as t
            ON p.id_pregunta = t.id_pregunta
            order by p.enunciado_pregunta
        END


        --AVRS QUESTIONS CHAT
        if @type = 24   begin
            SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
            FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
                                            FROM RIA_PREGUNTAS
                                            group by id_pregunta) as t
            ON p.id_pregunta = t.id_pregunta
            order by p.enunciado_pregunta
        END

            -- AVRS SUPERVISOR
        if @type = 17   begin
            SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
            FROM ccUserView
            WHERE [status] = 1
            and TipoUser_id = 2
            ORDER BY [login]
        end

            --Status Call
        if @type = 25   begin
            select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
            from ccstatusllamada
            order by [descripcion]
        end

            --Survey
        if @type = 26   begin
            select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
            from Survey
            order by [description]
        end

        --dialType
        if @type = 29 begin
            select dialId as id, [description] as description, ''dialId'' as dbcolumn
            from dialType
            order by [description]
        end

            --dial
        if @type = 30   begin
            select id as id, [description] as description, ''dialId'' as dbcolumn
            from Dials
            order by [description]
        end

        if @type = 33 begin
            if @userId <> 0 begin
                insert into @tablatemp
                select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
                inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
                inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
                inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat in (0,11)
                where us.[User_id] = @userId

                SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
                from ccinbound B
                inner join @tablatemp A on B.inbound_id = A.id
                return
            end
            else begin
                select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
                from ccinbound where chat in (0,11)
            end
        end
        IF @type = 34   
        BEGIN
            SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
            FROM TipoReadyAuxiliar
            ORDER BY [description]
        END
        IF @type = 35   
        BEGIN
            select SegmentId as Id,Name as description, ''SegmentId'' as dbColumn from ccSmsSegments
        END
        if @type = 36 begin
            if @userId <> 0 begin

                    insert into @tempwork
                            select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

                    select distinct us.User_id as id, us.Login as description,  ''adminId'' as dbcolumn from ccUserView us
                    inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

                    inner join @tempwork awg on wgu.IDWG = awg.idwg
                    where us.TipoUser_id = 2 and [status] = 1

                    return
                end

                else begin

                    SELECT [user_id] as id, [login] AS description, ''adminId'' as dbColumn
                    FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 2
                    ORDER BY description
                end
        end
        IF @type = 37 
            BEGIN
                SELECT DISTINCT 
                    descripcion AS id,             -- IMPORTANTE: El ID es el nombre (texto)
                    descripcion AS description,    -- Lo que ve el usuario
                    ''CampaignName'' AS dbcolumn     -- Apunta a la columna de texto en RepVirtualAgent
                FROM ccinbound 
                WHERE chat = 11 -- (O los filtros que requieras)
                ORDER BY description
            END
        IF @type = 38 
            BEGIN
                SELECT 
                    nameAgent AS id,                 -- El ID es el número (ej. 55)
                    nameAgent AS description,      -- El usuario ve "UlisesVirtualAgent"
                    ''ModelName'' AS dbcolumn          -- IMPORTANTE: Apunta a la columna numérica idAgent de tu tabla
                FROM ccVirtualAgent
                ORDER BY description
            END
        END --Action 0

        IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
        BEGIN
            DROP TABLE #filters;
        END

        -----------------------------------------------------------
        if @action = 1 begin
            -- TRUNKS
            if @type = 13
            begin
                SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
            end

            -- AVRS DISPOSITION
            if @type = 18
            begin
                SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
            end

            -- AVG DISPOSITION
            if @type = 19
            begin
                SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
            end

            -- SCORE
            if @type = 20
            begin
                SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
            end
        end'
EXEC(@sql);

------------------------------------ BEGIN Update ccspRepInCallsDetail ------------------------------------
SET @process = 'SP ccspRepInCallsDetail';

SET @sql = '
IF OBJECT_ID(''[dbo].[ccspRepInCallsDetail]'') IS NULL
BEGIN
    EXEC(''CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] AS RETURN 0'')
END
'
EXEC(@sql);

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
    END
END'
EXEC(@sql);

------------------------------------ BEGIN Update ccspRepOutDialDetail ------------------------------------
SET @process = 'SP ccspRepOutDialDetail';

SET @sql = '
IF OBJECT_ID(''[dbo].[ccspRepOutDialDetail]'') IS NULL
BEGIN
    EXEC(''CREATE PROCEDURE [dbo].[ccspRepOutDialDetail] AS RETURN 0'')
END
'
EXEC(@sql);

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
        ,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
        ,ISNULL(tr.descTranslate,'''') AS resultDialDesc
        ,dial.Telefono AS cal_telefono
        ,dial.Puerto
        ,dial.fecha
        ,co.cal_tDialog
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
        ,ISNULL(tc_ia.Name_cal,''N/A'') AS CallDisposition_IA
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
            ,COALESCE(dat.[description], tr.descTranslate, ''N/A'') AS DCCustomer
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
END'
EXEC(@sql);


set @process = ''
set @sql=''
EXEC(@sql)

------------------------------END Jesus Gallardo Sears Nova Monti 9---------------------------------

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
