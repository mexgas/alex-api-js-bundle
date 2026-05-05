/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
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
    SET @versionfix = 7
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


	--- BEGIN Services Pack 1-8 --

    SET @process = 'Drop Procedure [dbo].[ccspRotativeAniListSequence]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccspRotativeAniListSequence'')
        Begin
            DROP PROCEDURE ccspRotativeAniListSequence
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_DLRGetRotativeANIBatchInline_A0]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_DLRGetRotativeANIBatchInline_A0'')
        Begin
            DROP PROCEDURE ccsp_DLRGetRotativeANIBatchInline_A0
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_DLRGetRotativeANIBatchInline_A1]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_DLRGetRotativeANIBatchInline_A1'')
        Begin
            DROP PROCEDURE ccsp_DLRGetRotativeANIBatchInline_A1
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_DLRGetRotativeANIBatchInline_A2]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_DLRGetRotativeANIBatchInline_A2'')
        Begin
            DROP PROCEDURE ccsp_DLRGetRotativeANIBatchInline_A2
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_DLRGetRotativeANIBatchInline_A3]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_DLRGetRotativeANIBatchInline_A3'')
        Begin
            DROP PROCEDURE ccsp_DLRGetRotativeANIBatchInline_A3
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_PurgeAniStateOrphans]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_PurgeAniStateOrphans'')
        Begin
            DROP PROCEDURE ccsp_PurgeAniStateOrphans
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_PurgeAniStateByCampaign]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_PurgeAniStateByCampaign'')
        Begin
            DROP PROCEDURE ccsp_PurgeAniStateByCampaign
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_DLRGetDialInfoMini]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_DLRGetDialInfoMini'')
        Begin
            DROP PROCEDURE ccsp_DLRGetDialInfoMini
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WA_WT_Camp]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIAOUTInsertNewJOBS_WA_WT_Camp'')
        Begin
            DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_WA_WT_Camp
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_SMS_WT_Camp]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIAOUTInsertNewJOBS_SMS_WT_Camp'')
        Begin
            DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_SMS_WT_Camp
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp'')
        Begin
            DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp'')
        Begin
            DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp
        End';
    EXEC(@sql);

   
    SET @process = 'ALTER TABLE dbo.ccRotativeAniListDetail.Seq'
    SET @sql = 'IF COL_LENGTH(''dbo.ccRotativeAniListDetail'', ''Seq'') IS NULL
BEGIN
    ALTER TABLE dbo.ccRotativeAniListDetail
    ADD Seq INT NULL;
END;'
    exec (@sql)

    SET @process = 'ALTER TABLE dbo.ccRotativeAniListDetail.prefix2'
    SET @sql = 'IF COL_LENGTH(''dbo.ccRotativeAniListDetail'', ''prefix2'') IS NULL
BEGIN
    ALTER TABLE dbo.ccRotativeAniListDetail
    ADD prefix2 AS LEFT(telAni, 2) PERSISTED;
END;'
    exec (@sql)
    
    SET @process = 'ALTER TABLE dbo.ccRotativeAniListDetail.prefix3'
    SET @sql = 'IF COL_LENGTH(''dbo.ccRotativeAniListDetail'', ''prefix3'') IS NULL
BEGIN
    ALTER TABLE dbo.ccRotativeAniListDetail
    ADD prefix3 AS LEFT(telAni, 3) PERSISTED;
END;'
    exec (@sql)

    SET @process = 'ALTER TABLE dbo.ccRotativeAniListDetail.prefix6'
    SET @sql = 'IF COL_LENGTH(''dbo.ccRotativeAniListDetail'', ''prefix6'') IS NULL
BEGIN
    ALTER TABLE dbo.ccRotativeAniListDetail
    ADD prefix6 AS LEFT(telAni, 6) PERSISTED;
END;'
    exec (@sql)    

    SET @process = 'ALTER TABLE dbo.ccRotativeAniListDetail.LocalSeq2'
    SET @sql = 'IF COL_LENGTH(''dbo.ccRotativeAniListDetail'', ''LocalSeq2'') IS NULL
BEGIN
    ALTER TABLE dbo.ccRotativeAniListDetail
    ADD LocalSeq2 INT NULL;
END;'
    exec (@sql)

    SET @process = 'ALTER TABLE dbo.ccRotativeAniListDetail.LocalSeq3'
    SET @sql = 'IF COL_LENGTH(''dbo.ccRotativeAniListDetail'', ''LocalSeq3'') IS NULL
BEGIN
    ALTER TABLE dbo.ccRotativeAniListDetail
    ADD LocalSeq3 INT NULL;
END;'
    exec (@sql)
    
    SET @process = 'CREATE TABLE dbo.ccSeries2'
    SET @sql = 'IF OBJECT_ID(''dbo.ccSeries2'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccSeries2
    (
        CLD VARCHAR(2) NOT NULL,
        CONSTRAINT PK_ccSeries2 PRIMARY KEY CLUSTERED (CLD)
    );
END;'
    exec (@sql)

    SET @process = 'CREATE TABLE dbo.ccAniGlobalCount'
    SET @sql = 'IF OBJECT_ID(''dbo.ccAniGlobalCount'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccAniGlobalCount
    (
        id_RAniList INT NOT NULL,
        PoolSize    INT NOT NULL,
        CONSTRAINT PK_ccAniGlobalCount
            PRIMARY KEY CLUSTERED (id_RAniList)
    );
END;'
    exec (@sql)

    SET @process = 'CREATE TABLE dbo.ccAniPrefixCount'
    SET @sql = 'IF OBJECT_ID(''dbo.ccAniPrefixCount'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccAniPrefixCount
    (
        id_RAniList INT NOT NULL,
        PrefixLen   TINYINT NOT NULL,
        Prefix      VARCHAR(3) NOT NULL,
        PoolSize    INT NOT NULL,
        CONSTRAINT PK_ccAniPrefixCount
            PRIMARY KEY CLUSTERED (id_RAniList, PrefixLen, Prefix)
    );
END;'
    exec (@sql)
    
    SET @process = ' ALTER TABLE dbo.ccAniPrefixCount.PrefixInt'
    SET @sql = 'IF COL_LENGTH(''dbo.ccAniPrefixCount'', ''PrefixInt'') IS NULL
BEGIN
    ALTER TABLE dbo.ccAniPrefixCount
    ADD PrefixInt AS CONVERT(INT, Prefix) PERSISTED;
END;'
    exec (@sql)

    SET @process = 'CREATE TABLE dbo.ccAniPrefixQueue'
    SET @sql = 'IF OBJECT_ID(''dbo.ccAniPrefixQueue'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccAniPrefixQueue
    (
        id_RAniList INT NOT NULL,
        PrefixLen   TINYINT NOT NULL,
        Prefix      VARCHAR(3) NOT NULL,
        QueuePos    INT NOT NULL,
        Seq         INT NOT NULL,
        telAni      VARCHAR(32) NOT NULL,
        CONSTRAINT PK_ccAniPrefixQueue
            PRIMARY KEY CLUSTERED (id_RAniList, PrefixLen, Prefix, QueuePos)
    );
END;'
    exec (@sql)    

    SET @process = 'ALTER TABLE dbo.ccAniPrefixQueue.prefix6'
    SET @sql = 'IF COL_LENGTH(''dbo.ccAniPrefixQueue'', ''prefix6'') IS NULL
BEGIN
    ALTER TABLE dbo.ccAniPrefixQueue
    ADD prefix6 VARCHAR(6) NULL;
END;'
    exec (@sql)

    SET @process = 'ALTER TABLE dbo.ccAniPrefixQueue.SeriesKey'
    SET @sql = 'IF COL_LENGTH(''dbo.ccAniPrefixQueue'', ''SeriesKey'') IS NULL
BEGIN
    ALTER TABLE dbo.ccAniPrefixQueue
    ADD SeriesKey VARCHAR(6) NULL;
END;'
    exec (@sql)
    
    SET @process = 'CREATE TYPE dbo.ANIBatchType AS TABLE'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.types t
    WHERE t.is_table_type = 1
      AND t.name = ''ANIBatchType''
      AND SCHEMA_NAME(t.schema_id) = ''dbo''
)
BEGIN
    CREATE TYPE dbo.ANIBatchType AS TABLE
    (
        callout_id INT NOT NULL,
        phone1     VARCHAR(32) NULL,
        phone2     VARCHAR(32) NULL,
        phone3     VARCHAR(32) NULL,
        phone4     VARCHAR(32) NULL,
        phone5     VARCHAR(32) NULL
    );
END;'
    exec (@sql)

    SET @process = 'CREATE TABLE dbo.ccAniRecordState'
    SET @sql = 'IF OBJECT_ID(''dbo.ccAniRecordState'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccAniRecordState
    (
        callout_id    INT       NOT NULL,
        cam_id        INT       NOT NULL,
        id_RAniList   INT       NOT NULL,
        CycleNo       INT       NOT NULL CONSTRAINT DF_ccAniRecordState_CycleNo DEFAULT (1),
        PoolSize      INT       NOT NULL,
        UsedCount     INT       NOT NULL CONSTRAINT DF_ccAniRecordState_UsedCount DEFAULT (0),
        LastRefreshAt DATETIME2 NOT NULL CONSTRAINT DF_ccAniRecordState_LastRefreshAt DEFAULT (SYSUTCDATETIME()),
        NextPos       INT       NOT NULL CONSTRAINT DF_ccAniRecordState_NextPos DEFAULT (1),
        StepPos       INT       NOT NULL CONSTRAINT DF_ccAniRecordState_StepPos DEFAULT (1)
        CONSTRAINT PK_ccAniRecordState
            PRIMARY KEY CLUSTERED (callout_id, id_RAniList)
    );
END;'
    exec (@sql)

    SET @process = ' CREATE INDEX IX_ccAniRecordState_Purge_Cam'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniRecordState'')
      AND name = ''IX_ccAniRecordState_Purge_Cam''
)
BEGIN
    CREATE INDEX IX_ccAniRecordState_Purge_Cam
    ON dbo.ccAniRecordState (cam_id);
END;'
    exec (@sql)
    
    SET @process = 'CREATE TABLE dbo.ccAniPrefixState'
    SET @sql = 'IF OBJECT_ID(''dbo.ccAniPrefixState'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccAniPrefixState
    (
        callout_id    INT          NOT NULL,
        cam_id        INT          NOT NULL,
        id_RAniList   INT          NOT NULL,
        PrefixLen     TINYINT      NOT NULL,
        Prefix        VARCHAR(3)   NOT NULL,
        CycleNo       INT          NOT NULL CONSTRAINT DF_ccAniPrefixState_CycleNo DEFAULT (1),
        PoolSize      INT          NOT NULL,
        UsedCount     INT          NOT NULL CONSTRAINT DF_ccAniPrefixState_UsedCount DEFAULT (0),
        NextPos       INT          NOT NULL CONSTRAINT DF_ccAniPrefixState_NextPos DEFAULT (1),
        LastRefreshAt DATETIME2(3) NOT NULL CONSTRAINT DF_ccAniPrefixState_LastRefreshAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_ccAniPrefixState
            PRIMARY KEY CLUSTERED (callout_id, id_RAniList, PrefixLen, Prefix)
    );
END;'
    exec (@sql)

    SET @process = 'CREATE INDEX IX_ccAniPrefixState_Lookup'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniPrefixState'')
      AND name = ''IX_ccAniPrefixState_Lookup''
)
BEGIN
    CREATE INDEX IX_ccAniPrefixState_Lookup
    ON dbo.ccAniPrefixState (id_RAniList, PrefixLen, Prefix, callout_id)
    INCLUDE (CycleNo, PoolSize, UsedCount, NextPos, LastRefreshAt);
END;'
    exec (@sql)    

    SET @process = 'CREATE INDEX IX_ccAniPrefixState_Purge_Cam'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniPrefixState'')
      AND name = ''IX_ccAniPrefixState_Purge_Cam''
)
BEGIN
    CREATE INDEX IX_ccAniPrefixState_Purge_Cam
    ON dbo.ccAniPrefixState (cam_id);
END;'
    exec (@sql)

    SET @process = 'CREATE TABLE dbo.ccAniA3State'
    SET @sql = 'IF OBJECT_ID(''dbo.ccAniA3State'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccAniA3State
    (
        callout_id     INT         NOT NULL,
        cam_id         INT         NOT NULL,
        id_RAniList    INT         NOT NULL,
        CycleNo        INT         NOT NULL CONSTRAINT DF_ccAniA3State_CycleNo DEFAULT (1),
        UsedCount      INT         NOT NULL CONSTRAINT DF_ccAniA3State_UsedCount DEFAULT (0),
        PoolSize       INT         NOT NULL CONSTRAINT DF_ccAniA3State_PoolSize DEFAULT (0),
        PrefixLen      TINYINT     NULL,
        Prefix         VARCHAR(3)  NULL,
        PrefixNextPos  INT         NOT NULL CONSTRAINT DF_ccAniA3State_PrefixNextPos DEFAULT (1),
        ExcludeNextPos INT         NOT NULL CONSTRAINT DF_ccAniA3State_ExcludeNextPos DEFAULT (1),
        GlobalNextPos  INT         NOT NULL CONSTRAINT DF_ccAniA3State_GlobalNextPos DEFAULT (1),
        LastANI        VARCHAR(32) NULL,
        LastPrefix6    VARCHAR(6)  NULL,
        LastSeriesKey  VARCHAR(6)  NULL,
        LastRefreshAt  DATETIME2   NOT NULL CONSTRAINT DF_ccAniA3State_LastRefreshAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_ccAniA3State
            PRIMARY KEY CLUSTERED (callout_id, id_RAniList)
    );
END;'
    exec (@sql)
    
    SET @process = 'CREATE INDEX IX_ccRotativeAniListDetail_RAniList_Seq'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccRotativeAniListDetail'')
      AND name = ''IX_ccRotativeAniListDetail_RAniList_Seq''
)
BEGIN
    CREATE INDEX IX_ccRotativeAniListDetail_RAniList_Seq
    ON dbo.ccRotativeAniListDetail (id_RAniList, Seq)
    INCLUDE (telAni, prefix2, prefix3, prefix6, LocalSeq2, LocalSeq3);
END;'
    exec (@sql)

    SET @process = 'CREATE INDEX IX_ccRotativeAniListDetail_RAniList_Prefix2_LocalSeq2'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccRotativeAniListDetail'')
      AND name = ''IX_ccRotativeAniListDetail_RAniList_Prefix2_LocalSeq2''
)
BEGIN
    CREATE INDEX IX_ccRotativeAniListDetail_RAniList_Prefix2_LocalSeq2
    ON dbo.ccRotativeAniListDetail (id_RAniList, prefix2, LocalSeq2)
    INCLUDE (Seq, telAni, prefix6);
END;'
    exec (@sql)

    SET @process = 'CREATE INDEX IX_ccRotativeAniListDetail_RAniList_Prefix3_LocalSeq3'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccRotativeAniListDetail'')
      AND name = ''IX_ccRotativeAniListDetail_RAniList_Prefix3_LocalSeq3''
)
BEGIN
    CREATE INDEX IX_ccRotativeAniListDetail_RAniList_Prefix3_LocalSeq3
    ON dbo.ccRotativeAniListDetail (id_RAniList, prefix3, LocalSeq3)
    INCLUDE (Seq, telAni, prefix6);
END;'
    exec (@sql)
    
    SET @process = 'CREATE INDEX IX_ccRotativeAniListDetail_A3_Seq'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccRotativeAniListDetail'')
      AND name = ''IX_ccRotativeAniListDetail_A3_Seq''
)
BEGIN
    CREATE INDEX IX_ccRotativeAniListDetail_A3_Seq
    ON dbo.ccRotativeAniListDetail (id_RAniList, Seq)
    INCLUDE (telAni);
END;'
    exec (@sql)

    SET @process = 'CREATE INDEX IX_ccAniPrefixCount_List_Len_PrefixInt'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniPrefixCount'')
      AND name = ''IX_ccAniPrefixCount_List_Len_PrefixInt''
)
BEGIN
    CREATE INDEX IX_ccAniPrefixCount_List_Len_PrefixInt
    ON dbo.ccAniPrefixCount (id_RAniList, PrefixLen, PrefixInt)
    INCLUDE (Prefix, PoolSize);
END;'
    exec (@sql)    

    SET @process = 'CREATE INDEX IX_ccAniPrefixQueue_RAniList_Prefix_Seq'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniPrefixQueue'')
      AND name = ''IX_ccAniPrefixQueue_RAniList_Prefix_Seq''
)
BEGIN
    CREATE INDEX IX_ccAniPrefixQueue_RAniList_Prefix_Seq
    ON dbo.ccAniPrefixQueue (id_RAniList, PrefixLen, Prefix, Seq)
    INCLUDE (QueuePos, telAni, prefix6, SeriesKey);
END;'
    exec (@sql)

    SET @process = 'CREATE UNIQUE INDEX IX_ccAniA3State_Update_A3'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniA3State'')
      AND name = ''IX_ccAniA3State_Update_A3''
)
BEGIN
    CREATE UNIQUE INDEX IX_ccAniA3State_Update_A3
    ON dbo.ccAniA3State (callout_id, id_RAniList)
    INCLUDE
    (
        CycleNo,
        UsedCount,
        PoolSize,
        PrefixLen,
        Prefix,
        PrefixNextPos,
        ExcludeNextPos,
        GlobalNextPos,
        LastANI,
        LastPrefix6,
        LastSeriesKey
    );
END;'
    exec (@sql)
    
    SET @process = 'CREATE INDEX IX_ccAniA3State_Purge_Cam'
    SET @sql = 'IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(''dbo.ccAniA3State'')
      AND name = ''IX_ccAniA3State_Purge_Cam''
)
BEGIN
    CREATE INDEX IX_ccAniA3State_Purge_Cam
    ON dbo.ccAniA3State (cam_id);
END;'
    exec (@sql)

    SET @process = 'TRUNCATE TABLE dbo.ccSeries2;'
    SET @sql = 'TRUNCATE TABLE dbo.ccSeries2;'
    exec (@sql)

    SET @process = 'INSERT INTO dbo.ccSeries2 '
    SET @sql = 'INSERT INTO dbo.ccSeries2 (CLD)
SELECT DISTINCT CLD
FROM dbo.Series
WHERE LEN(CLD) = 2;'
    exec (@sql)
    
    SET @process = ''
    SET @sql = 'TRUNCATE TABLE dbo.ccAniGlobalCount;'
    exec (@sql)

    SET @process = 'INSERT INTO dbo.ccAniGlobalCount'
    SET @sql = 'INSERT INTO dbo.ccAniGlobalCount
(
    id_RAniList,
    PoolSize
)
SELECT
    d.id_RAniList,
    COUNT(*) AS PoolSize
FROM dbo.ccRotativeAniListDetail d
GROUP BY
    d.id_RAniList;'
    exec (@sql)    

    SET @process = 'TRUNCATE TABLE dbo.ccAniPrefixCount;'
    SET @sql = 'TRUNCATE TABLE dbo.ccAniPrefixCount;'
    exec (@sql)

    SET @process = ''
    SET @sql = 'INSERT INTO dbo.ccAniPrefixCount
(
    id_RAniList,
    PrefixLen,
    Prefix,
    PoolSize
)
SELECT
    d.id_RAniList,
    2 AS PrefixLen,
    d.prefix2 AS Prefix,
    COUNT(*) AS PoolSize
FROM dbo.ccRotativeAniListDetail d
INNER JOIN dbo.ccSeries2 s
    ON s.CLD = d.prefix2
GROUP BY
    d.id_RAniList,
    d.prefix2;

INSERT INTO dbo.ccAniPrefixCount
(
    id_RAniList,
    PrefixLen,
    Prefix,
    PoolSize
)
SELECT
    d.id_RAniList,
    3 AS PrefixLen,
    d.prefix3 AS Prefix,
    COUNT(*) AS PoolSize
FROM dbo.ccRotativeAniListDetail d
LEFT JOIN dbo.ccSeries2 s
    ON s.CLD = d.prefix2
WHERE s.CLD IS NULL
GROUP BY
    d.id_RAniList,
    d.prefix3;'
    exec (@sql)
    
    SET @process = 'TRUNCATE TABLE dbo.ccAniPrefixQueue;'
    SET @sql = 'TRUNCATE TABLE dbo.ccAniPrefixQueue;'
    exec (@sql)

    SET @process = 'INSERT INTO dbo.ccAniPrefixQueue'
    SET @sql = 'INSERT INTO dbo.ccAniPrefixQueue
(
    id_RAniList,
    PrefixLen,
    Prefix,
    QueuePos,
    Seq,
    telAni,
    prefix6,
    SeriesKey
)
SELECT
    d.id_RAniList,
    2 AS PrefixLen,
    d.prefix2 AS Prefix,
    d.LocalSeq2 AS QueuePos,
    d.Seq,
    d.telAni,
    LEFT(d.telAni, 6) AS prefix6,
    SUBSTRING(d.telAni, 3, 4) AS SeriesKey
FROM dbo.ccRotativeAniListDetail d
INNER JOIN dbo.ccSeries2 s
    ON s.CLD = d.prefix2
WHERE d.LocalSeq2 IS NOT NULL;

INSERT INTO dbo.ccAniPrefixQueue
(
    id_RAniList,
    PrefixLen,
    Prefix,
    QueuePos,
    Seq,
    telAni,
    prefix6,
    SeriesKey
)
SELECT
    d.id_RAniList,
    3 AS PrefixLen,
    d.prefix3 AS Prefix,
    d.LocalSeq3 AS QueuePos,
    d.Seq,
    d.telAni,
    LEFT(d.telAni, 6) AS prefix6,
    SUBSTRING(d.telAni, 4, 3) AS SeriesKey
FROM dbo.ccRotativeAniListDetail d
LEFT JOIN dbo.ccSeries2 s
    ON s.CLD = d.prefix2
WHERE s.CLD IS NULL
  AND d.LocalSeq3 IS NOT NULL;'
    exec (@sql)

    SET @process = 'UPDATE ccAniPrefixQueue prefix6'
    SET @sql = 'UPDATE q
   SET q.prefix6 = LEFT(q.telAni, 6),
       q.SeriesKey = CASE
                         WHEN q.PrefixLen = 2 THEN SUBSTRING(q.telAni, 3, 4)
                         WHEN q.PrefixLen = 3 THEN SUBSTRING(q.telAni, 4, 3)
                         ELSE LEFT(q.telAni, 6)
                     END
FROM dbo.ccAniPrefixQueue q
WHERE q.prefix6 IS NULL
   OR q.SeriesKey IS NULL;'
    exec (@sql)
    
    SET @process = 'CREATE PROCEDURE ccspRotativeAniListSequence '
    SET @sql = 'CREATE PROCEDURE ccspRotativeAniListSequence    
    @action int,
    @anilistId int
AS
BEGIN   
    SET NOCOUNT ON;

    if @action=1  --Update Seq
    begin
        ;WITH X AS
        (
            SELECT
                Seq,
                ROW_NUMBER() OVER
                (
                    PARTITION BY id_RAniList
                    ORDER BY NEWID()
                ) AS NewSeq
            FROM dbo.ccRotativeAniListDetail
            where @anilistId=0 or  id_RAniList=@anilistId
        )
        UPDATE X
        SET Seq = NewSeq;
    end
    else if @action=2 --Update LocalSeq2
    begin
        ;WITH X AS
        (
            SELECT
                d.LocalSeq2,
                ROW_NUMBER() OVER
                (
                    PARTITION BY d.id_RAniList, d.prefix2
                    ORDER BY d.Seq
                ) AS NewLocalSeq2
            FROM dbo.ccRotativeAniListDetail d
            INNER JOIN dbo.ccSeries2 s ON s.CLD = d.prefix2
            where @anilistId=0 or  id_RAniList=@anilistId
        )
        UPDATE X
        SET LocalSeq2 = NewLocalSeq2;
    end
    else if @action=3 --Update LocalSeq3
    begin
        ;WITH X AS
        (
            SELECT
                d.LocalSeq3,
                ROW_NUMBER() OVER
                (
                    PARTITION BY d.id_RAniList, d.prefix3
                    ORDER BY d.Seq
                ) AS NewLocalSeq3
            FROM dbo.ccRotativeAniListDetail d
            LEFT JOIN dbo.ccSeries2 s ON s.CLD = d.prefix2
            WHERE s.CLD IS NULL
            and @anilistId=0 or  id_RAniList=@anilistId
        )
        UPDATE X
        SET LocalSeq3 = NewLocalSeq3;
    end
    else if @action=4 -- PoolSize ccAniGlobalCount para no revisar en cada vuelta
    begin
        delete from ccAniGlobalCount  WHERE (@anilistId = 0 OR id_RAniList = @anilistId)

        MERGE dbo.ccAniGlobalCount AS target
        USING (
            SELECT
                d.id_RAniList,
                COUNT(*) AS PoolSize
            FROM dbo.ccRotativeAniListDetail d
            WHERE (@anilistId = 0 OR d.id_RAniList = @anilistId)
            GROUP BY d.id_RAniList
        ) AS source
        ON target.id_RAniList = source.id_RAniList

        WHEN MATCHED THEN
            UPDATE SET
                target.PoolSize = source.PoolSize

        WHEN NOT MATCHED THEN
            INSERT (id_RAniList, PoolSize)
            VALUES (source.id_RAniList, source.PoolSize);
    end
    else if @action=5 -- PoolSize ccAniPrefixCount  por prefijos 2 y 3 digitos
    begin
        delete from ccAniPrefixCount  WHERE (@anilistId = 0 OR id_RAniList = @anilistId)  --para comenzar si hay cambios 

        MERGE dbo.ccAniPrefixCount AS target
        USING (
            SELECT
                d.id_RAniList,
                2 AS PrefixLen,
                d.prefix2 AS Prefix,
                COUNT(*) AS PoolSize
            FROM dbo.ccRotativeAniListDetail d
            INNER JOIN dbo.ccSeries2 s ON s.CLD = d.prefix2
            WHERE (@anilistId = 0 OR d.id_RAniList = @anilistId)
            GROUP BY d.id_RAniList, d.prefix2
        ) AS source
        ON target.id_RAniList = source.id_RAniList
           AND target.PrefixLen = source.PrefixLen
           AND target.Prefix = source.Prefix

        WHEN MATCHED THEN
            UPDATE SET target.PoolSize = source.PoolSize

        WHEN NOT MATCHED THEN
            INSERT (id_RAniList, PrefixLen, Prefix, PoolSize)
            VALUES (source.id_RAniList, source.PrefixLen, source.Prefix, source.PoolSize);

       MERGE dbo.ccAniPrefixCount AS target
        USING (
            SELECT
                d.id_RAniList,
                3 AS PrefixLen,
                d.prefix3 AS Prefix,
                COUNT(*) AS PoolSize
            FROM dbo.ccRotativeAniListDetail d
            LEFT JOIN dbo.ccSeries2 s
                ON s.CLD = d.prefix2
            WHERE s.CLD IS NULL
              AND (@anilistId = 0 OR d.id_RAniList = @anilistId)
            GROUP BY
                d.id_RAniList,
                d.prefix3
        ) AS source
        ON  target.id_RAniList = source.id_RAniList
        AND target.PrefixLen   = source.PrefixLen
        AND target.Prefix      = source.Prefix

        WHEN MATCHED THEN
            UPDATE SET
                target.PoolSize = source.PoolSize

        WHEN NOT MATCHED THEN
            INSERT
            (
                id_RAniList,
                PrefixLen,
                Prefix,
                PoolSize
            )
            VALUES
            (
                source.id_RAniList,
                source.PrefixLen,
                source.Prefix,
                source.PoolSize
            );


    end
    else if @action=6 -- PoolSize ccAniPrefixQueue moverse en posiciones para saber cual es el siguiente numero
    begin
        delete from ccAniPrefixQueue  WHERE (@anilistId = 0 OR id_RAniList = @anilistId)  --para comenzar si hay cambios 

        MERGE dbo.ccAniPrefixQueue AS target
        USING (
            SELECT
                d.id_RAniList,
                2 AS PrefixLen,
                d.prefix2 AS Prefix,
                d.LocalSeq2 AS QueuePos,
                d.Seq,
                d.telAni,
                LEFT(d.telAni, 6) AS prefix6,
                SUBSTRING(d.telAni, 3, 4) AS SeriesKey
            FROM dbo.ccRotativeAniListDetail d
            INNER JOIN dbo.ccSeries2 s ON s.CLD = d.prefix2
            WHERE d.LocalSeq2 IS NOT NULL
              AND (@anilistId = 0 OR d.id_RAniList = @anilistId)
        ) AS source
        ON target.id_RAniList = source.id_RAniList
           AND target.PrefixLen = source.PrefixLen
           AND target.Prefix = source.Prefix
           AND target.QueuePos = source.QueuePos

        WHEN MATCHED THEN
            UPDATE SET
                target.Seq = source.Seq,
                target.telAni = source.telAni,
                target.prefix6 = source.prefix6,
                target.SeriesKey = source.SeriesKey

        WHEN NOT MATCHED THEN
            INSERT (id_RAniList, PrefixLen, Prefix, QueuePos, Seq, telAni, prefix6, SeriesKey)
            VALUES (source.id_RAniList, source.PrefixLen, source.Prefix, source.QueuePos, source.Seq, source.telAni, source.prefix6, source.SeriesKey);

        INSERT INTO dbo.ccAniPrefixQueue
        (
            id_RAniList,
            PrefixLen,
            Prefix,
            QueuePos,
            Seq,
            telAni,
            prefix6,
            SeriesKey
        )
        SELECT
            d.id_RAniList,
            3 AS PrefixLen,
            d.prefix3 AS Prefix,
            d.LocalSeq3 AS QueuePos,
            d.Seq,
            d.telAni,
            LEFT(d.telAni, 6) AS prefix6,
            SUBSTRING(d.telAni, 4, 3) AS SeriesKey
        FROM dbo.ccRotativeAniListDetail d
        LEFT JOIN dbo.ccSeries2 s
            ON s.CLD = d.prefix2
        WHERE s.CLD IS NULL
          AND d.LocalSeq3 IS NOT NULL
          and  @anilistId=0 or  id_RAniList=@anilistId

    end

END
'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A0'
    SET @sql = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A0
(
    @Batch dbo.ANIBatchType READONLY,
    @cam_id INT,
    @aniList INT
)
AS
BEGIN
    select callout_id,
    dbo.TelAni(phone1,@aniList) ani,
    dbo.TelAni(phone2,@aniList) ani2,
    dbo.TelAni(phone3,@aniList) ani3,
    dbo.TelAni(phone4,@aniList) ani4,
    dbo.TelAni(phone5,@aniList) ani5
    from @Batch
END'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A1'
    SET @sql = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A1
(
    @Batch dbo.ANIBatchType READONLY,
    @cam_id INT,
    @aniList INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PoolSize INT;

    BEGIN TRY
        BEGIN TRAN;

        IF @cam_id IS NULL OR @cam_id <= 0 
        BEGIN
            print ''Parametro @cam_id invalido.''
            return
        END

        IF @aniList IS NULL OR @aniList <= 0
        BEGIN
            print ''Parametro @aniList invalido.''
            return
        END

        SELECT @PoolSize = g.PoolSize
        FROM dbo.ccAniGlobalCount g
        WHERE g.id_RAniList = @aniList;

        IF @PoolSize IS NULL OR @PoolSize <= 0
        BEGIN
            print ''No existe PoolSize valido para la ANI list indicada.''
            return
        END

        /* =========================================================
           1. NeedCount directo desde @Batch
              #CalloutNeed como HEAP para evitar sort en insert
           ========================================================= */
        IF OBJECT_ID(''tempdb..#CalloutNeed'') IS NOT NULL DROP TABLE #CalloutNeed;

        CREATE TABLE #CalloutNeed
        (
            callout_id  INT NOT NULL,
            id_RAniList INT NOT NULL,
            NeedCount   INT NOT NULL
        );

        INSERT INTO #CalloutNeed
        (
            callout_id,
            id_RAniList,
            NeedCount
        )
        SELECT
            b.callout_id,
            @aniList,
            (CASE WHEN NULLIF(b.phone1, '''') IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN NULLIF(b.phone2, '''') IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN NULLIF(b.phone3, '''') IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN NULLIF(b.phone4, '''') IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN NULLIF(b.phone5, '''') IS NOT NULL THEN 1 ELSE 0 END)
        FROM @Batch b;

        CREATE UNIQUE CLUSTERED INDEX IX_CalloutNeed
            ON #CalloutNeed(callout_id, id_RAniList);

        /* =========================================================
           2. Validar tamaño del pool
           ========================================================= 
        IF EXISTS
        (
            SELECT 1
            FROM #CalloutNeed n
            WHERE n.NeedCount > @PoolSize
        )
        BEGIN
            print ''El pool ANI no tiene suficientes elementos para asignar ANI distintos dentro del mismo registro.''
        END;
        */

        /* =========================================================
           3. Telefonos normalizados
              #BatchWork como HEAP para evitar sort en insert
           ========================================================= */
        IF OBJECT_ID(''tempdb..#BatchWork'') IS NOT NULL DROP TABLE #BatchWork;

        CREATE TABLE #BatchWork
        (
            callout_id  INT         NOT NULL,
            id_RAniList INT         NOT NULL,
            PhonePos    TINYINT     NOT NULL,
            phone       VARCHAR(32) NOT NULL,
            PhoneRN     TINYINT     NOT NULL
        );

        INSERT INTO #BatchWork
        (
            callout_id,
            id_RAniList,
            PhonePos,
            phone,
            PhoneRN
        )
        SELECT
            b.callout_id,
            @aniList,
            v.PhonePos,
            v.phone,
            v.PhonePos
        FROM @Batch b
        CROSS APPLY
        (
            VALUES
                (1, NULLIF(b.phone1, '''')),
                (2, NULLIF(b.phone2, '''')),
                (3, NULLIF(b.phone3, '''')),
                (4, NULLIF(b.phone4, '''')),
                (5, NULLIF(b.phone5, ''''))
        ) v(PhonePos, phone)
        WHERE v.phone IS NOT NULL;

        CREATE UNIQUE CLUSTERED INDEX IX_BatchWork
            ON #BatchWork(callout_id, PhoneRN);

        /* =========================================================
           4. Inicializar estado faltante
           ========================================================= */
        INSERT INTO dbo.ccAniRecordState
        (
            callout_id,
            cam_id,
            id_RAniList,
            CycleNo,
            PoolSize,
            UsedCount,
            NextPos,
            StepPos,
            LastRefreshAt
        )
        SELECT
            n.callout_id,
            @cam_id,
            n.id_RAniList,
            1,
            @PoolSize,
            0,
            1 + ABS(CHECKSUM(n.callout_id)) % @PoolSize,
            1,
            SYSUTCDATETIME()
        FROM #CalloutNeed n
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.ccAniRecordState s WITH (UPDLOCK, HOLDLOCK)
            WHERE s.callout_id  = n.callout_id
              AND s.id_RAniList = n.id_RAniList
        );

        /* =========================================================
           5. Reset tecnico si cambio PoolSize
           ========================================================= */
        UPDATE s
           SET s.CycleNo       = 1,
               s.PoolSize      = @PoolSize,
               s.UsedCount     = 0,
               s.NextPos       = 1 + ABS(CHECKSUM(s.callout_id)) % @PoolSize,
               s.StepPos       = 1,
               s.LastRefreshAt = SYSUTCDATETIME()
        FROM dbo.ccAniRecordState s
        INNER JOIN #CalloutNeed n
            ON n.callout_id  = s.callout_id
           AND n.id_RAniList = s.id_RAniList
        WHERE s.PoolSize <> @PoolSize;

        /* =========================================================
           6. Leer y bloquear estado actual
           ========================================================= */
        IF OBJECT_ID(''tempdb..#State'') IS NOT NULL DROP TABLE #State;

        CREATE TABLE #State
        (
            callout_id  INT NOT NULL,
            id_RAniList INT NOT NULL,
            CycleNo     INT NOT NULL,
            PoolSize    INT NOT NULL,
            UsedCount   INT NOT NULL,
            NextPos     INT NOT NULL
        );

        INSERT INTO #State
        (
            callout_id,
            id_RAniList,
            CycleNo,
            PoolSize,
            UsedCount,
            NextPos
        )
        SELECT
            s.callout_id,
            s.id_RAniList,
            s.CycleNo,
            s.PoolSize,
            s.UsedCount,
            s.NextPos
        FROM dbo.ccAniRecordState s WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN #CalloutNeed n
            ON n.callout_id  = s.callout_id
           AND n.id_RAniList = s.id_RAniList;

        CREATE UNIQUE CLUSTERED INDEX IX_State
            ON #State(callout_id, id_RAniList);

        /* =========================================================
           7. Resolver ANI por posicion
           ========================================================= */
        IF OBJECT_ID(''tempdb..#AssignedAni'') IS NOT NULL DROP TABLE #AssignedAni;

        CREATE TABLE #AssignedAni
        (
            callout_id      INT         NOT NULL,
            id_RAniList     INT         NOT NULL,
            PhonePos        TINYINT     NOT NULL,
            phone           VARCHAR(32) NOT NULL,
            AssignedCycleNo INT         NOT NULL,
            AssignedSeq     INT         NOT NULL,
            AssignedANI     VARCHAR(32) NOT NULL
        );

        INSERT INTO #AssignedAni
        (
            callout_id,
            id_RAniList,
            PhonePos,
            phone,
            AssignedCycleNo,
            AssignedSeq,
            AssignedANI
        )
        SELECT
            bw.callout_id,
            bw.id_RAniList,
            bw.PhonePos,
            bw.phone,
            s.CycleNo + ((s.UsedCount + (bw.PhoneRN - 1)) / s.PoolSize),
            ((s.NextPos - 1 + (bw.PhoneRN - 1)) % s.PoolSize) + 1,
            d.telAni
        FROM #BatchWork bw
        INNER JOIN #State s
            ON s.callout_id  = bw.callout_id
           AND s.id_RAniList = bw.id_RAniList
        INNER JOIN dbo.ccRotativeAniListDetail d
            ON d.id_RAniList = bw.id_RAniList
           AND d.Seq = ((s.NextPos - 1 + (bw.PhoneRN - 1)) % s.PoolSize) + 1;

        CREATE UNIQUE CLUSTERED INDEX IX_AssignedAni
            ON #AssignedAni(callout_id, PhonePos);

        /* =========================================================
           8. Nuevo estado
           ========================================================= */
        IF OBJECT_ID(''tempdb..#StateUpdate'') IS NOT NULL DROP TABLE #StateUpdate;

        CREATE TABLE #StateUpdate
        (
            callout_id   INT NOT NULL,
            id_RAniList  INT NOT NULL,
            NewCycleNo   INT NOT NULL,
            NewUsedCount INT NOT NULL,
            NewNextPos   INT NOT NULL,
            PoolSize     INT NOT NULL
        );

        INSERT INTO #StateUpdate
        (
            callout_id,
            id_RAniList,
            NewCycleNo,
            NewUsedCount,
            NewNextPos,
            PoolSize
        )
        SELECT
            s.callout_id,
            s.id_RAniList,
            s.CycleNo + ((s.UsedCount + n.NeedCount) / s.PoolSize),
            (s.UsedCount + n.NeedCount) % s.PoolSize,
            ((s.NextPos - 1 + n.NeedCount) % s.PoolSize) + 1,
            s.PoolSize
        FROM #State s
        INNER JOIN #CalloutNeed n
            ON n.callout_id  = s.callout_id
           AND n.id_RAniList = s.id_RAniList;

        CREATE UNIQUE CLUSTERED INDEX IX_StateUpdate
            ON #StateUpdate(callout_id, id_RAniList);

        UPDATE s
           SET s.CycleNo       = u.NewCycleNo,
               s.UsedCount     = u.NewUsedCount,
               s.NextPos       = u.NewNextPos,
               s.StepPos       = 1,
               s.PoolSize      = u.PoolSize,
               s.LastRefreshAt = SYSUTCDATETIME()
        FROM dbo.ccAniRecordState s
        INNER JOIN #StateUpdate u
            ON u.callout_id  = s.callout_id
           AND u.id_RAniList = s.id_RAniList;

        /* =========================================================
           9. Salida pivotada
           ========================================================= */
        SELECT
            n.callout_id,
            MAX(CASE WHEN a.PhonePos = 1 THEN a.AssignedANI END) AS ani1,
            MAX(CASE WHEN a.PhonePos = 2 THEN a.AssignedANI END) AS ani2,
            MAX(CASE WHEN a.PhonePos = 3 THEN a.AssignedANI END) AS ani3,
            MAX(CASE WHEN a.PhonePos = 4 THEN a.AssignedANI END) AS ani4,
            MAX(CASE WHEN a.PhonePos = 5 THEN a.AssignedANI END) AS ani5
        FROM #CalloutNeed n
        LEFT JOIN #AssignedAni a
            ON a.callout_id = n.callout_id
        GROUP BY n.callout_id
        ORDER BY n.callout_id;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END
'
    exec (@sql)
    
    SET @process = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A2'
    SET @sql = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A2
(
    @Batch dbo.ANIBatchType READONLY,
    @cam_id INT,
    @aniList INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

          IF @cam_id IS NULL OR @cam_id <= 0 
        BEGIN
            print ''Parametro @cam_id invalido.''
            return
        END

        IF @aniList IS NULL OR @aniList <= 0
        BEGIN
            print ''Parametro @aniList invalido.''
            return
        END

        /* =========================================================
           1. Telefonos normalizados
           ========================================================= */
        IF OBJECT_ID(''tempdb..#BatchPhones'') IS NOT NULL DROP TABLE #BatchPhones;

        CREATE TABLE #BatchPhones
        (
            callout_id    INT         NOT NULL,
            id_RAniList   INT         NOT NULL,
            PhonePos      TINYINT     NOT NULL,
            phone         VARCHAR(32) NOT NULL,
            ReqPrefixLen  TINYINT     NOT NULL,
            ReqPrefix     VARCHAR(3)  NOT NULL,
            ReqPrefixInt  INT         NOT NULL
        );

        INSERT INTO #BatchPhones
        (
            callout_id,
            id_RAniList,
            PhonePos,
            phone,
            ReqPrefixLen,
            ReqPrefix,
            ReqPrefixInt
        )
        SELECT
            b.callout_id,
            @aniList,
            v.PhonePos,
            v.phone,
            CASE WHEN s2.CLD IS NOT NULL THEN 2 ELSE 3 END,
            CASE WHEN s2.CLD IS NOT NULL THEN LEFT(v.phone, 2) ELSE LEFT(v.phone, 3) END,
            CONVERT(INT, CASE WHEN s2.CLD IS NOT NULL THEN LEFT(v.phone, 2) ELSE LEFT(v.phone, 3) END)
        FROM @Batch b
        CROSS APPLY
        (
            VALUES
                (1, NULLIF(LTRIM(RTRIM(b.phone1)), '''')),
                (2, NULLIF(LTRIM(RTRIM(b.phone2)), '''')),
                (3, NULLIF(LTRIM(RTRIM(b.phone3)), '''')),
                (4, NULLIF(LTRIM(RTRIM(b.phone4)), '''')),
                (5, NULLIF(LTRIM(RTRIM(b.phone5)), ''''))
        ) v(PhonePos, phone)
        LEFT JOIN dbo.ccSeries2 s2
            ON s2.CLD = LEFT(v.phone, 2)
        WHERE v.phone IS NOT NULL
          AND LEN(v.phone) >= 3;

        CREATE UNIQUE CLUSTERED INDEX IX_BatchPhones
            ON #BatchPhones(callout_id, PhonePos);

        CREATE INDEX IX_BatchPhones_PoolResolve
            ON #BatchPhones(id_RAniList, ReqPrefixLen, ReqPrefixInt)
            INCLUDE(callout_id, PhonePos, phone, ReqPrefix);

        /* =========================================================
           2. Resolver pool
           ========================================================= */
        IF OBJECT_ID(''tempdb..#ResolvedPool'') IS NOT NULL DROP TABLE #ResolvedPool;

        CREATE TABLE #ResolvedPool
        (
            callout_id     INT         NOT NULL,
            id_RAniList    INT         NOT NULL,
            PhonePos       TINYINT     NOT NULL,
            phone          VARCHAR(32) NOT NULL,
            ReqPrefixLen   TINYINT     NOT NULL,
            ReqPrefix      VARCHAR(3)  NOT NULL,
            ReqPrefixInt   INT         NOT NULL,
            PoolPrefixLen  TINYINT     NULL,
            PoolPrefix     VARCHAR(3)  NULL,
            PoolPrefixInt  INT         NULL,
            PoolSize       INT         NULL
        );

        INSERT INTO #ResolvedPool
        (
            callout_id,
            id_RAniList,
            PhonePos,
            phone,
            ReqPrefixLen,
            ReqPrefix,
            ReqPrefixInt,
            PoolPrefixLen,
            PoolPrefix,
            PoolPrefixInt,
            PoolSize
        )
        SELECT
            bp.callout_id,
            bp.id_RAniList,
            bp.PhonePos,
            bp.phone,
            bp.ReqPrefixLen,
            bp.ReqPrefix,
            bp.ReqPrefixInt,
            x.PrefixLen,
            x.Prefix,
            x.PrefixInt,
            x.PoolSize
        FROM #BatchPhones bp
        OUTER APPLY
        (
            SELECT TOP (1)
                pc.PrefixLen,
                pc.Prefix,
                pc.PrefixInt,
                pc.PoolSize
            FROM dbo.ccAniPrefixCount pc
            WHERE pc.id_RAniList = bp.id_RAniList
            ORDER BY
                CASE
                    WHEN pc.PrefixLen = bp.ReqPrefixLen
                     AND pc.PrefixInt = bp.ReqPrefixInt THEN 0
                    WHEN pc.PrefixLen = bp.ReqPrefixLen THEN 1
                    ELSE 2
                END,
                ABS(pc.PrefixInt - bp.ReqPrefixInt),
                CASE WHEN pc.PrefixInt <= bp.ReqPrefixInt THEN 0 ELSE 1 END,
                pc.PrefixInt
        ) x;

        CREATE UNIQUE CLUSTERED INDEX IX_ResolvedPool
            ON #ResolvedPool(callout_id, PhonePos);

        CREATE INDEX IX_ResolvedPool_Pool
            ON #ResolvedPool(callout_id, id_RAniList, PoolPrefixLen, PoolPrefix)
            INCLUDE(PhonePos, phone, PoolSize);

        /* =========================================================
           3. Necesidad por pool
           ========================================================= */
        IF OBJECT_ID(''tempdb..#PoolNeed'') IS NOT NULL DROP TABLE #PoolNeed;

        CREATE TABLE #PoolNeed
        (
            callout_id  INT        NOT NULL,
            id_RAniList INT        NOT NULL,
            PrefixLen   TINYINT    NOT NULL,
            Prefix      VARCHAR(3) NOT NULL,
            NeedCount   INT        NOT NULL,
            PoolSize    INT        NOT NULL
        );

        INSERT INTO #PoolNeed
        (
            callout_id,
            id_RAniList,
            PrefixLen,
            Prefix,
            NeedCount,
            PoolSize
        )
        SELECT
            rp.callout_id,
            rp.id_RAniList,
            rp.PoolPrefixLen,
            rp.PoolPrefix,
            COUNT(*) AS NeedCount,
            MAX(rp.PoolSize) AS PoolSize
        FROM #ResolvedPool rp
        WHERE rp.PoolPrefix IS NOT NULL
        GROUP BY
            rp.callout_id,
            rp.id_RAniList,
            rp.PoolPrefixLen,
            rp.PoolPrefix;

        CREATE UNIQUE CLUSTERED INDEX IX_PoolNeed
            ON #PoolNeed(callout_id, id_RAniList, PrefixLen, Prefix);

        /* =========================================================
           4. Numerar dentro de cada pool
           ========================================================= */
        IF OBJECT_ID(''tempdb..#BatchWork'') IS NOT NULL DROP TABLE #BatchWork;

        CREATE TABLE #BatchWork
        (
            callout_id  INT         NOT NULL,
            id_RAniList INT         NOT NULL,
            PhonePos    TINYINT     NOT NULL,
            phone       VARCHAR(32) NOT NULL,
            PrefixLen   TINYINT     NOT NULL,
            Prefix      VARCHAR(3)  NOT NULL,
            PoolRN      INT         NOT NULL
        );

        INSERT INTO #BatchWork
        (
            callout_id,
            id_RAniList,
            PhonePos,
            phone,
            PrefixLen,
            Prefix,
            PoolRN
        )
        SELECT
            rp.callout_id,
            rp.id_RAniList,
            rp.PhonePos,
            rp.phone,
            rp.PoolPrefixLen,
            rp.PoolPrefix,
            ROW_NUMBER() OVER
            (
                PARTITION BY rp.callout_id, rp.id_RAniList, rp.PoolPrefixLen, rp.PoolPrefix
                ORDER BY rp.PhonePos
            )
        FROM #ResolvedPool rp
        WHERE rp.PoolPrefix IS NOT NULL;

        CREATE UNIQUE CLUSTERED INDEX IX_BatchWork
            ON #BatchWork(callout_id, id_RAniList, PrefixLen, Prefix, PoolRN);

        CREATE INDEX IX_BatchWork_Phone
            ON #BatchWork(callout_id, id_RAniList, PhonePos)
            INCLUDE(PrefixLen, Prefix, PoolRN);

        /* =========================================================
           5. Inicializar estado faltante
           ========================================================= */
        INSERT INTO dbo.ccAniPrefixState
        (
            callout_id,
            cam_id,
            id_RAniList,
            PrefixLen,
            Prefix,
            CycleNo,
            PoolSize,
            UsedCount,
            NextPos,
            LastRefreshAt
        )
        SELECT
            pn.callout_id,
            @cam_id,
            pn.id_RAniList,
            pn.PrefixLen,
            pn.Prefix,
            1,
            pn.PoolSize,
            0,
            CASE
                WHEN pn.PoolSize > 0
                    THEN 1 + ABS(CHECKSUM(pn.callout_id, pn.PrefixLen, pn.Prefix)) % pn.PoolSize
                ELSE 1
            END,
            SYSUTCDATETIME()
        FROM #PoolNeed pn
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.ccAniPrefixState s WITH (UPDLOCK, HOLDLOCK, INDEX(PK_ccAniPrefixState))
            WHERE s.callout_id  = pn.callout_id
              AND s.id_RAniList = pn.id_RAniList
              AND s.PrefixLen   = pn.PrefixLen
              AND s.Prefix      = pn.Prefix
        )
        OPTION (RECOMPILE);

        /* =========================================================
           6. Reset tecnico si cambio PoolSize
           ========================================================= */
        UPDATE s
           SET s.CycleNo       = 1,
               s.PoolSize      = pn.PoolSize,
               s.UsedCount     = 0,
               s.NextPos       = CASE
                                    WHEN pn.PoolSize > 0
                                        THEN 1 + ABS(CHECKSUM(s.callout_id, s.PrefixLen, s.Prefix)) % pn.PoolSize
                                    ELSE 1
                                 END,
               s.LastRefreshAt = SYSUTCDATETIME()
        FROM #PoolNeed pn
        INNER JOIN dbo.ccAniPrefixState s WITH (UPDLOCK, INDEX(PK_ccAniPrefixState))
            ON s.callout_id  = pn.callout_id
           AND s.id_RAniList = pn.id_RAniList
           AND s.PrefixLen   = pn.PrefixLen
           AND s.Prefix      = pn.Prefix
        WHERE s.PoolSize <> pn.PoolSize
        OPTION (RECOMPILE);

        /* =========================================================
           7. Leer y bloquear estado
           ========================================================= */
        IF OBJECT_ID(''tempdb..#State'') IS NOT NULL DROP TABLE #State;

        CREATE TABLE #State
        (
            callout_id  INT        NOT NULL,
            id_RAniList INT        NOT NULL,
            PrefixLen   TINYINT    NOT NULL,
            Prefix      VARCHAR(3) NOT NULL,
            CycleNo     INT        NOT NULL,
            PoolSize    INT        NOT NULL,
            UsedCount   INT        NOT NULL,
            NextPos     INT        NOT NULL
        );

        INSERT INTO #State
        (
            callout_id,
            id_RAniList,
            PrefixLen,
            Prefix,
            CycleNo,
            PoolSize,
            UsedCount,
            NextPos
        )
        SELECT
            s.callout_id,
            s.id_RAniList,
            s.PrefixLen,
            s.Prefix,
            s.CycleNo,
            s.PoolSize,
            s.UsedCount,
            s.NextPos
        FROM #PoolNeed pn
        INNER JOIN dbo.ccAniPrefixState s WITH (UPDLOCK, HOLDLOCK, INDEX(PK_ccAniPrefixState))
            ON s.callout_id  = pn.callout_id
           AND s.id_RAniList = pn.id_RAniList
           AND s.PrefixLen   = pn.PrefixLen
           AND s.Prefix      = pn.Prefix
        OPTION (RECOMPILE);

        CREATE UNIQUE CLUSTERED INDEX IX_State
            ON #State(callout_id, id_RAniList, PrefixLen, Prefix);

        /* =========================================================
           8. Asignar ANI en un solo INSERT
           ========================================================= */
        IF OBJECT_ID(''tempdb..#AssignedAni'') IS NOT NULL DROP TABLE #AssignedAni;

        CREATE TABLE #AssignedAni
        (
            callout_id      INT         NOT NULL,
            id_RAniList     INT         NOT NULL,
            PhonePos        TINYINT     NOT NULL,
            phone           VARCHAR(32) NOT NULL,
            PrefixLen       TINYINT     NULL,
            Prefix          VARCHAR(3)  NULL,
            AssignedCycleNo INT         NULL,
            AssignedPos     INT         NULL,
            AssignedSeq     INT         NULL,
            AssignedANI     VARCHAR(32) NULL
        );

        INSERT INTO #AssignedAni
        (
            callout_id,
            id_RAniList,
            PhonePos,
            phone,
            PrefixLen,
            Prefix,
            AssignedCycleNo,
            AssignedPos,
            AssignedSeq,
            AssignedANI
        )
        SELECT
            rp.callout_id,
            rp.id_RAniList,
            rp.PhonePos,
            rp.phone,
            rp.PoolPrefixLen,
            rp.PoolPrefix,
            CASE
                WHEN st.PoolSize IS NOT NULL
                    THEN st.CycleNo + ((st.UsedCount + (bw.PoolRN - 1)) / st.PoolSize)
                ELSE NULL
            END,
            CASE
                WHEN st.PoolSize IS NOT NULL
                    THEN ((st.NextPos - 1 + (bw.PoolRN - 1)) % st.PoolSize) + 1
                ELSE NULL
            END,
            q.Seq,
            q.telAni
        FROM #ResolvedPool rp
        LEFT JOIN #BatchWork bw
            ON bw.callout_id  = rp.callout_id
           AND bw.id_RAniList = rp.id_RAniList
           AND bw.PhonePos    = rp.PhonePos
        LEFT JOIN #State st
            ON st.callout_id  = bw.callout_id
           AND st.id_RAniList = bw.id_RAniList
           AND st.PrefixLen   = bw.PrefixLen
           AND st.Prefix      = bw.Prefix
        LEFT JOIN dbo.ccAniPrefixQueue q
            ON q.id_RAniList = bw.id_RAniList
           AND q.PrefixLen   = bw.PrefixLen
           AND q.Prefix      = bw.Prefix
           AND q.QueuePos    = ((st.NextPos - 1 + (bw.PoolRN - 1)) % st.PoolSize) + 1;

        CREATE UNIQUE CLUSTERED INDEX IX_AssignedAni
            ON #AssignedAni(callout_id, PhonePos);

        /* =========================================================
           9. Actualizar estado directo, sin #StateUpdate
           ========================================================= */
        UPDATE s
           SET s.CycleNo       = st.CycleNo + ((st.UsedCount + pn.NeedCount) / st.PoolSize),
               s.UsedCount     = (st.UsedCount + pn.NeedCount) % st.PoolSize,
               s.NextPos       = ((st.NextPos - 1 + pn.NeedCount) % st.PoolSize) + 1,
               s.PoolSize      = st.PoolSize,
               s.LastRefreshAt = SYSUTCDATETIME()
        FROM #State st
        INNER JOIN #PoolNeed pn
            ON pn.callout_id  = st.callout_id
           AND pn.id_RAniList = st.id_RAniList
           AND pn.PrefixLen   = st.PrefixLen
           AND pn.Prefix      = st.Prefix
        INNER JOIN dbo.ccAniPrefixState s WITH (UPDLOCK, INDEX(PK_ccAniPrefixState))
            ON s.callout_id  = st.callout_id
           AND s.id_RAniList = st.id_RAniList
           AND s.PrefixLen   = st.PrefixLen
           AND s.Prefix      = st.Prefix
        OPTION (RECOMPILE);

        /* =========================================================
           10. Salida pivotada
           ========================================================= */
        SELECT
            b.callout_id,
            MAX(CASE WHEN a.PhonePos = 1 THEN a.AssignedANI END) AS ani1,
            MAX(CASE WHEN a.PhonePos = 2 THEN a.AssignedANI END) AS ani2,
            MAX(CASE WHEN a.PhonePos = 3 THEN a.AssignedANI END) AS ani3,
            MAX(CASE WHEN a.PhonePos = 4 THEN a.AssignedANI END) AS ani4,
            MAX(CASE WHEN a.PhonePos = 5 THEN a.AssignedANI END) AS ani5
        FROM @Batch b
        LEFT JOIN #AssignedAni a
            ON a.callout_id = b.callout_id
        GROUP BY b.callout_id
        ORDER BY b.callout_id;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        THROW;
    END CATCH
END'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A3'
    SET @sql = 'CREATE PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline_A3
(
    @Batch dbo.ANIBatchType READONLY,
    @cam_id INT,
    @aniList INT    
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET ANSI_WARNINGS OFF;

    DECLARE @GlobalPoolSize INT;

    BEGIN TRY
        BEGIN TRAN;

        SELECT @GlobalPoolSize = PoolSize
        FROM dbo.ccAniGlobalCount
        WHERE id_RAniList = @aniList;

        IF ISNULL(@GlobalPoolSize, 0) <= 0 
        BEGIN
            print ''No existe PoolSize global valido.''
            return
        END

        /* =========================================================
           1. Normalizar batch
           ========================================================= */

        DROP TABLE IF EXISTS #BatchPhones;

        CREATE TABLE #BatchPhones
        (
            callout_id   INT NOT NULL,
            id_RAniList  INT NOT NULL,
            PhonePos     TINYINT NOT NULL,
            PhoneRN      INT NOT NULL,
            phone        VARCHAR(32) NOT NULL,
            ReqPrefixLen TINYINT NOT NULL,
            ReqPrefix    VARCHAR(3) NOT NULL,
            ReqPrefixInt INT NOT NULL
        );

        INSERT INTO #BatchPhones
        (
            callout_id,
            id_RAniList,
            PhonePos,
            PhoneRN,
            phone,
            ReqPrefixLen,
            ReqPrefix,
            ReqPrefixInt
        )
        SELECT
            x.callout_id,
            @aniList,
            x.PhonePos,
            x.PhonePos,
            x.phone,
            CASE WHEN LEFT(x.phone, 2) IN (''33'', ''55'', ''56'', ''81'') THEN 2 ELSE 3 END,
            CASE WHEN LEFT(x.phone, 2) IN (''33'', ''55'', ''56'', ''81'') THEN LEFT(x.phone, 2) ELSE LEFT(x.phone, 3) END,
            CONVERT(INT, CASE WHEN LEFT(x.phone, 2) IN (''33'', ''55'', ''56'', ''81'') THEN LEFT(x.phone, 2) ELSE LEFT(x.phone, 3) END)
        FROM
        (
            SELECT
                b.callout_id,
                v.PhonePos,
                v.phone
            FROM @Batch b
            CROSS APPLY
            (
                VALUES
                    (1, NULLIF(b.phone1, '''')),
                    (2, NULLIF(b.phone2, '''')),
                    (3, NULLIF(b.phone3, '''')),
                    (4, NULLIF(b.phone4, '''')),
                    (5, NULLIF(b.phone5, ''''))
            ) v(PhonePos, phone)
            WHERE v.phone IS NOT NULL
              AND LEN(v.phone) >= 3
        ) x;

        CREATE UNIQUE CLUSTERED INDEX IX_BatchPhones
            ON #BatchPhones(callout_id, PhoneRN);

        CREATE NONCLUSTERED INDEX IX_BatchPhones_Prefix
            ON #BatchPhones(id_RAniList, ReqPrefixLen, ReqPrefixInt)
            INCLUDE(callout_id, PhonePos, PhoneRN, phone, ReqPrefix);

        /* =========================================================
           2. Resolver prefijo aplicable
           ========================================================= */

        DROP TABLE IF EXISTS #ResolvedPool;

        CREATE TABLE #ResolvedPool
        (
            callout_id    INT NOT NULL,
            id_RAniList   INT NOT NULL,
            PhonePos      TINYINT NOT NULL,
            PhoneRN       INT NOT NULL,
            phone         VARCHAR(32) NOT NULL,
            PoolPrefixLen TINYINT NULL,
            PoolPrefix    VARCHAR(3) NULL,
            PoolSize      INT NULL
        );

        INSERT INTO #ResolvedPool
        (
            callout_id,
            id_RAniList,
            PhonePos,
            PhoneRN,
            phone,
            PoolPrefixLen,
            PoolPrefix,
            PoolSize
        )
        SELECT
            bp.callout_id,
            bp.id_RAniList,
            bp.PhonePos,
            bp.PhoneRN,
            bp.phone,
            pc.PrefixLen,
            pc.Prefix,
            pc.PoolSize
        FROM #BatchPhones bp
        OUTER APPLY
        (
            SELECT TOP (1)
                c.PrefixLen,
                c.Prefix,
                c.PoolSize
            FROM dbo.ccAniPrefixCount c
            WHERE c.id_RAniList = bp.id_RAniList
            ORDER BY
                CASE
                    WHEN c.PrefixLen = bp.ReqPrefixLen
                     AND c.PrefixInt = bp.ReqPrefixInt THEN 0
                    WHEN c.PrefixLen = bp.ReqPrefixLen THEN 1
                    ELSE 2
                END,
                ABS(c.PrefixInt - bp.ReqPrefixInt),
                CASE WHEN c.PrefixInt <= bp.ReqPrefixInt THEN 0 ELSE 1 END,
                c.PrefixInt
        ) pc;

        CREATE UNIQUE CLUSTERED INDEX IX_ResolvedPool
            ON #ResolvedPool(callout_id, PhoneRN);

        CREATE NONCLUSTERED INDEX IX_ResolvedPool_CalloutList
            ON #ResolvedPool(callout_id, id_RAniList)
            INCLUDE(PhonePos, PhoneRN, phone, PoolPrefixLen, PoolPrefix, PoolSize);

        /* =========================================================
           3. Necesidad por callout
           ========================================================= */

        DROP TABLE IF EXISTS #CalloutNeed;

        SELECT
            callout_id,
            id_RAniList,
            COUNT(*) AS NeedCount
        INTO #CalloutNeed
        FROM #ResolvedPool
        GROUP BY callout_id, id_RAniList;

        CREATE UNIQUE CLUSTERED INDEX IX_CalloutNeed
            ON #CalloutNeed(callout_id, id_RAniList);

        /* =========================================================
           4. Inicializar estado faltante
           ========================================================= */

        INSERT INTO dbo.ccAniA3State
        (
            callout_id,
            cam_id,
            id_RAniList,
            CycleNo,
            UsedCount,
            PoolSize,
            PrefixLen,
            Prefix,
            PrefixNextPos,
            ExcludeNextPos,
            GlobalNextPos,
            LastANI,
            LastPrefix6,
            LastSeriesKey,
            LastRefreshAt
        )
        SELECT
            n.callout_id,
            @cam_id,
            n.id_RAniList,
            1,
            0,
            @GlobalPoolSize,
            fp.PoolPrefixLen,
            fp.PoolPrefix,
            1,
            1,
            1 + ABS(CHECKSUM(n.callout_id, n.id_RAniList)) % @GlobalPoolSize,
            NULL,
            NULL,
            NULL,
            SYSUTCDATETIME()
        FROM #CalloutNeed n
        OUTER APPLY
        (
            SELECT TOP (1)
                rp.PoolPrefixLen,
                rp.PoolPrefix
            FROM #ResolvedPool rp
            WHERE rp.callout_id = n.callout_id
              AND rp.id_RAniList = n.id_RAniList
            ORDER BY rp.PhoneRN
        ) fp
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.ccAniA3State s WITH (UPDLOCK, HOLDLOCK)
            WHERE s.callout_id = n.callout_id
              AND s.id_RAniList = n.id_RAniList
        );

        /* =========================================================
           5. Leer estado bloqueado
           ========================================================= */

        DROP TABLE IF EXISTS #State;

        SELECT
            s.callout_id,
            s.id_RAniList,
            s.CycleNo,
            s.UsedCount,
            s.PoolSize,
            s.PrefixNextPos,
            s.ExcludeNextPos,
            s.GlobalNextPos,
            s.LastANI,
            s.LastPrefix6,
            s.LastSeriesKey
        INTO #State
        FROM dbo.ccAniA3State s WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN #CalloutNeed n
            ON n.callout_id = s.callout_id
           AND n.id_RAniList = s.id_RAniList;

        CREATE UNIQUE CLUSTERED INDEX IX_State
            ON #State(callout_id, id_RAniList);

        /* =========================================================
           6. Work
              GlobalTargetSeq se calcula aquí.
              Se elimina UPDATE posterior sobre #Work.
           ========================================================= */

        DROP TABLE IF EXISTS #Work;

        SELECT
            z.callout_id,
            z.id_RAniList,
            z.PhonePos,
            z.PhoneRN,
            z.phone,
            z.PoolPrefixLen,
            z.PoolPrefix,
            z.PrefixPoolSize,
            z.CycleNo,
            z.UsedCount,
            z.Phase,
            z.PhaseRN,
            z.LastPrefix6,
            z.LastSeriesKey,
            CASE
                WHEN z.Phase = 3
                THEN ((z.GlobalNextPos - 1 + z.PhaseRN - 1) % @GlobalPoolSize) + 1
                ELSE NULL
            END AS GlobalTargetSeq
        INTO #Work
        FROM
        (
            SELECT
                rp.callout_id,
                rp.id_RAniList,
                rp.PhonePos,
                rp.PhoneRN,
                rp.phone,
                rp.PoolPrefixLen,
                rp.PoolPrefix,
                rp.PoolSize AS PrefixPoolSize,
                st.CycleNo,
                st.UsedCount,
                st.GlobalNextPos,
                CASE
                    WHEN rp.PoolPrefix IS NULL THEN 3
                    WHEN st.UsedCount = 0 THEN 1
                    WHEN st.UsedCount = 1 THEN 2
                    ELSE 3
                END AS Phase,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        rp.callout_id,
                        rp.id_RAniList,
                        CASE
                            WHEN rp.PoolPrefix IS NULL THEN 3
                            WHEN st.UsedCount = 0 THEN 1
                            WHEN st.UsedCount = 1 THEN 2
                            ELSE 3
                        END,
                        rp.PoolPrefixLen,
                        rp.PoolPrefix
                    ORDER BY rp.PhoneRN
                ) AS PhaseRN,
                st.LastPrefix6,
                st.LastSeriesKey
            FROM #ResolvedPool rp
            INNER JOIN #State st
                ON st.callout_id = rp.callout_id
               AND st.id_RAniList = rp.id_RAniList
        ) z;

        CREATE UNIQUE CLUSTERED INDEX IX_Work
            ON #Work(callout_id, PhoneRN);

        CREATE NONCLUSTERED INDEX IX_Work_Phase
            ON #Work(Phase, id_RAniList, PoolPrefixLen, PoolPrefix)
            INCLUDE
            (
                callout_id,
                PhoneRN,
                PhonePos,
                phone,
                PhaseRN,
                PrefixPoolSize,
                LastPrefix6,
                LastSeriesKey,
                GlobalTargetSeq
            );

        /* =========================================================
           7. Asignaciones
           ========================================================= */

        DROP TABLE IF EXISTS #AssignedAni;

        CREATE TABLE #AssignedAni
        (
            callout_id      INT NOT NULL,
            id_RAniList     INT NOT NULL,
            PhonePos        TINYINT NOT NULL,
            PhoneRN         INT NOT NULL,
            phone           VARCHAR(32) NOT NULL,
            Phase           TINYINT NOT NULL,
            AssignedCycleNo INT NOT NULL,
            AssignedPos     INT NULL,
            AssignedSeq     INT NULL,
            AssignedANI     VARCHAR(32) NULL,
            prefix6         VARCHAR(6) NULL,
            SeriesKey       VARCHAR(6) NULL
        );

        /* Fase 1 */
        INSERT INTO #AssignedAni
        SELECT
            w.callout_id,
            w.id_RAniList,
            w.PhonePos,
            w.PhoneRN,
            w.phone,
            w.Phase,
            w.CycleNo,
            q.QueuePos,
            q.Seq,
            q.telAni,
            q.prefix6,
            q.SeriesKey
        FROM #Work w
        INNER JOIN #State st
            ON st.callout_id = w.callout_id
           AND st.id_RAniList = w.id_RAniList
        INNER JOIN dbo.ccAniPrefixQueue q
            ON q.id_RAniList = w.id_RAniList
           AND q.PrefixLen = w.PoolPrefixLen
           AND q.Prefix = w.PoolPrefix
           AND q.QueuePos = ((st.PrefixNextPos - 1 + w.PhaseRN - 1) % w.PrefixPoolSize) + 1
        WHERE w.Phase = 1
          AND w.PrefixPoolSize > 0;

        /* Fase 2 */
        INSERT INTO #AssignedAni
        SELECT
            w.callout_id,
            w.id_RAniList,
            w.PhonePos,
            w.PhoneRN,
            w.phone,
            w.Phase,
            w.CycleNo,
            qx.QueuePos,
            qx.Seq,
            qx.telAni,
            qx.prefix6,
            qx.SeriesKey
        FROM #Work w
        INNER JOIN #State st
            ON st.callout_id = w.callout_id
           AND st.id_RAniList = w.id_RAniList
        CROSS APPLY
        (
            SELECT ((st.ExcludeNextPos - 1 + w.PhaseRN - 1) % w.PrefixPoolSize) + 1 AS StartPos
        ) p
        OUTER APPLY
        (
            SELECT TOP (1)
                q.QueuePos,
                q.Seq,
                q.telAni,
                q.prefix6,
                q.SeriesKey
            FROM dbo.ccAniPrefixQueue q
            WHERE q.id_RAniList = w.id_RAniList
              AND q.PrefixLen = w.PoolPrefixLen
              AND q.Prefix = w.PoolPrefix
              AND q.QueuePos >= p.StartPos
              AND ISNULL(q.prefix6, '''') <> ISNULL(w.LastPrefix6, '''')
              AND ISNULL(q.SeriesKey, '''') <> ISNULL(w.LastSeriesKey, '''')
            ORDER BY q.QueuePos
        ) q1
        OUTER APPLY
        (
            SELECT TOP (1)
                q.QueuePos,
                q.Seq,
                q.telAni,
                q.prefix6,
                q.SeriesKey
            FROM dbo.ccAniPrefixQueue q
            WHERE q.id_RAniList = w.id_RAniList
              AND q.PrefixLen = w.PoolPrefixLen
              AND q.Prefix = w.PoolPrefix
              AND q.QueuePos < p.StartPos
              AND ISNULL(q.prefix6, '''') <> ISNULL(w.LastPrefix6, '''')
              AND ISNULL(q.SeriesKey, '''') <> ISNULL(w.LastSeriesKey, '''')
            ORDER BY q.QueuePos
        ) q2
        CROSS APPLY
        (
            SELECT
                COALESCE(q1.QueuePos, q2.QueuePos) AS QueuePos,
                COALESCE(q1.Seq, q2.Seq) AS Seq,
                COALESCE(q1.telAni, q2.telAni) AS telAni,
                COALESCE(q1.prefix6, q2.prefix6) AS prefix6,
                COALESCE(q1.SeriesKey, q2.SeriesKey) AS SeriesKey
        ) qx
        WHERE w.Phase = 2
          AND w.PrefixPoolSize > 0
          AND qx.telAni IS NOT NULL;

        /* Fallback fase 2 */
        INSERT INTO #AssignedAni
        SELECT
            w.callout_id,
            w.id_RAniList,
            w.PhonePos,
            w.PhoneRN,
            w.phone,
            w.Phase,
            w.CycleNo,
            q.QueuePos,
            q.Seq,
            q.telAni,
            q.prefix6,
            q.SeriesKey
        FROM #Work w
        INNER JOIN #State st
            ON st.callout_id = w.callout_id
           AND st.id_RAniList = w.id_RAniList
        INNER JOIN dbo.ccAniPrefixQueue q
            ON q.id_RAniList = w.id_RAniList
           AND q.PrefixLen = w.PoolPrefixLen
           AND q.Prefix = w.PoolPrefix
           AND q.QueuePos = ((st.PrefixNextPos - 1 + w.PhaseRN - 1) % w.PrefixPoolSize) + 1
        WHERE w.Phase = 2
          AND w.PrefixPoolSize > 0
          AND NOT EXISTS
          (
              SELECT 1
              FROM #AssignedAni a
              WHERE a.callout_id = w.callout_id
                AND a.PhoneRN = w.PhoneRN
          );

        /* Fase 3 global */
        INSERT INTO #AssignedAni
        SELECT
            w.callout_id,
            w.id_RAniList,
            w.PhonePos,
            w.PhoneRN,
            w.phone,
            w.Phase,
            w.CycleNo,
            d.Seq,
            d.Seq,
            d.telAni,
            LEFT(d.telAni, 6),
            CASE
                WHEN LEFT(d.telAni, 2) IN (''33'', ''55'', ''56'', ''81'') THEN SUBSTRING(d.telAni, 3, 4)
                ELSE SUBSTRING(d.telAni, 4, 3)
            END
        FROM #Work w
        INNER JOIN dbo.ccRotativeAniListDetail d
            ON d.id_RAniList = w.id_RAniList
           AND d.Seq = w.GlobalTargetSeq
        WHERE w.Phase = 3;

        CREATE UNIQUE CLUSTERED INDEX IX_AssignedAni
            ON #AssignedAni(callout_id, PhonePos);

        /* =========================================================
           8. Agregados para estado
           ========================================================= */

        DROP TABLE IF EXISTS #WorkAgg;

        SELECT
            w.callout_id,
            w.id_RAniList,
            SUM(CASE WHEN w.Phase IN (1, 2) THEN 1 ELSE 0 END) AS PrefixCnt,
            MAX(CASE WHEN w.Phase IN (1, 2) THEN w.PrefixPoolSize ELSE NULL END) AS PrefixPoolSize,
            SUM(CASE WHEN w.Phase = 2 THEN 1 ELSE 0 END) AS ExcludeCnt,
            MAX(CASE WHEN w.Phase = 2 THEN w.PrefixPoolSize ELSE NULL END) AS ExcludePoolSize,
            SUM(CASE WHEN w.Phase = 3 THEN 1 ELSE 0 END) AS GlobalCnt,
            MAX(CASE WHEN w.PoolPrefix IS NOT NULL THEN w.PoolPrefixLen ELSE NULL END) AS PoolPrefixLen,
            MAX(CASE WHEN w.PoolPrefix IS NOT NULL THEN w.PoolPrefix ELSE NULL END) AS PoolPrefix
        INTO #WorkAgg
        FROM #Work w
        GROUP BY w.callout_id, w.id_RAniList;

        CREATE UNIQUE CLUSTERED INDEX IX_WorkAgg
            ON #WorkAgg(callout_id, id_RAniList);

        DROP TABLE IF EXISTS #LastAssigned;

        SELECT
            x.callout_id,
            x.id_RAniList,
            x.AssignedANI,
            x.prefix6,
            x.SeriesKey
        INTO #LastAssigned
        FROM
        (
            SELECT
                a.callout_id,
                a.id_RAniList,
                a.AssignedANI,
                a.prefix6,
                a.SeriesKey,
                ROW_NUMBER() OVER
                (
                    PARTITION BY a.callout_id, a.id_RAniList
                    ORDER BY a.PhoneRN DESC
                ) AS rn
            FROM #AssignedAni a
        ) x
        WHERE x.rn = 1;

        CREATE UNIQUE CLUSTERED INDEX IX_LastAssigned
            ON #LastAssigned(callout_id, id_RAniList);

        DROP TABLE IF EXISTS #StateUpdate;

        SELECT
            st.callout_id,
            st.id_RAniList,
            CASE
                WHEN st.UsedCount + 1 >= st.PoolSize THEN st.CycleNo + 1
                ELSE st.CycleNo
            END AS NewCycleNo,
            CASE
                WHEN st.UsedCount + 1 >= st.PoolSize THEN 0
                ELSE st.UsedCount + 1
            END AS NewUsedCount,
            ((st.PrefixNextPos - 1 + ISNULL(wa.PrefixCnt, 0)) % ISNULL(NULLIF(wa.PrefixPoolSize, 0), 1)) + 1 AS NewPrefixNextPos,
            ((st.ExcludeNextPos - 1 + ISNULL(wa.ExcludeCnt, 0)) % ISNULL(NULLIF(wa.ExcludePoolSize, 0), 1)) + 1 AS NewExcludeNextPos,
            ((st.GlobalNextPos - 1 + ISNULL(wa.GlobalCnt, 0)) % @GlobalPoolSize) + 1 AS NewGlobalNextPos,
            la.AssignedANI,
            la.prefix6,
            la.SeriesKey,
            wa.PoolPrefixLen,
            wa.PoolPrefix
        INTO #StateUpdate
        FROM #State st
        INNER JOIN #WorkAgg wa
            ON wa.callout_id = st.callout_id
           AND wa.id_RAniList = st.id_RAniList
        LEFT JOIN #LastAssigned la
            ON la.callout_id = st.callout_id
           AND la.id_RAniList = st.id_RAniList;

        CREATE UNIQUE CLUSTERED INDEX IX_StateUpdate
            ON #StateUpdate(callout_id, id_RAniList);

        UPDATE s
           SET s.CycleNo        = u.NewCycleNo,
               s.UsedCount      = u.NewUsedCount,
               s.PoolSize       = @GlobalPoolSize,
               s.PrefixLen      = u.PoolPrefixLen,
               s.Prefix         = u.PoolPrefix,
               s.PrefixNextPos  = u.NewPrefixNextPos,
               s.ExcludeNextPos = u.NewExcludeNextPos,
               s.GlobalNextPos  = u.NewGlobalNextPos,
               s.LastANI        = CASE WHEN u.NewUsedCount = 0 THEN NULL ELSE u.AssignedANI END,
               s.LastPrefix6    = CASE WHEN u.NewUsedCount = 0 THEN NULL ELSE u.prefix6 END,
               s.LastSeriesKey  = CASE WHEN u.NewUsedCount = 0 THEN NULL ELSE u.SeriesKey END,
               s.LastRefreshAt  = SYSUTCDATETIME()
        FROM dbo.ccAniA3State s WITH (INDEX(IX_ccAniA3State_Update_A3))
        INNER JOIN #StateUpdate u
            ON u.callout_id = s.callout_id
           AND u.id_RAniList = s.id_RAniList;       

        /* =========================================================
           10. Salida sin ORDER BY
           ========================================================= */

        SELECT
            a.callout_id,
            MAX(CASE WHEN a.PhonePos = 1 THEN a.AssignedANI END) AS ani1,
            MAX(CASE WHEN a.PhonePos = 2 THEN a.AssignedANI END) AS ani2,
            MAX(CASE WHEN a.PhonePos = 3 THEN a.AssignedANI END) AS ani3,
            MAX(CASE WHEN a.PhonePos = 4 THEN a.AssignedANI END) AS ani4,
            MAX(CASE WHEN a.PhonePos = 5 THEN a.AssignedANI END) AS ani5
        FROM #AssignedAni a
        GROUP BY a.callout_id;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        THROW;
    END CATCH
END;'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline'
    SET @sql = 'ALTER PROCEDURE dbo.ccsp_DLRGetRotativeANIBatchInline
(
    @Batch dbo.ANIBatchType READONLY,
    @cam_id INT,
    @aniList INT,
    @algo int
)
AS
BEGIN
   if @aniList > 0 begin
       if @algo = 0 begin --Ani Local
            exec ccsp_DLRGetRotativeANIBatchInline_A0 @Batch=@Batch,@cam_id=@cam_id,@aniList=@aniList
       end
       if @algo = 1 begin --Ani Rotativo
            exec ccsp_DLRGetRotativeANIBatchInline_A1 @Batch=@Batch,@cam_id=@cam_id,@aniList=@aniList
       end
       else if @algo = 2 begin --Regionalizado
            exec ccsp_DLRGetRotativeANIBatchInline_A2 @Batch=@Batch,@cam_id=@cam_id,@aniList=@aniList
       end
       if @algo = 3 begin -- Rotativo Inteligente
            exec ccsp_DLRGetRotativeANIBatchInline_A3 @Batch=@Batch,@cam_id=@cam_id,@aniList=@aniList
       end
   end
    
END'
    exec (@sql)
    
    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
    @type SMALLINT,
    @idArea SMALLINT = NULL,
    @descriptionList VARCHAR(50) = NULL,
    @id_RAniList SMALLINT = NULL,
    @PageIndex      INT = 0,
    @PageSize       INT = 0,
    @UserId         SMALLINT = 0,
    @LoadType SMALLINT = 0

AS
BEGIN
    SET NOCOUNT ON;

    IF (@type = 1) -- Read Rotative ANI List Catalog
    BEGIN
SELECT CAST(cral.id_RAniList AS SMALLINT) id_RAniList,
                cral.description,
                cral.idArea
        FROM dbo.ccRotativeANIList AS cral
        WHERE cral.idArea IN (@idArea,-1) 
        AND cral.id_RAniList = ISNULL(@id_RAniList, cral.id_RAniList);
        RETURN 0;
    END;
    IF (@type = 2)
    BEGIN
        SELECT * 
        FROM
            (SELECT ROW_NUMBER() OVER(ORDER BY loadDate ASC) AS RowNum,
        CAST(id_RAniList AS SMALLINT) id_RAniList,
                telAni,
                loadDate
            FROM dbo.ccRotativeANIListDetail
            WHERE id_RAniList = @id_RAniList) tmp
        WHERE  tmp.RowNum > @PageSize * (@PageIndex - 1)
        AND tmp.RowNum <= @PageSize * @PageIndex
        RETURN 0;
    END;
    If @type=3 --Create Rotative ANI List
    begin
        declare @newANILstId SMALLINT = -1 --Name in use

        if not exists(select id_RAniList from ccRotativeANIList where description = @descriptionList)
        begin
            insert into ccRotativeANIList (description,idArea) values(@descriptionList, @idArea)
            select @newANILstId = SCOPE_IDENTITY() 
        end

        select @newANILstId as [result]
        return(0)
    end
    If @type=4 --Update Rotative ANI List
    begin
        declare @idAreaOfExistingLst smallint

        select @idAreaOfExistingLst = idArea from ccRotativeANIList where id_RAniList = @id_RAniList
        if(@idAreaOfExistingLst = -1 and @idArea <> @idAreaOfExistingLst)   --Changing from global to particular idArea
        begin
            if exists(select cam_id from ccCamps where IDArea <> @idArea and id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
            begin
                select -2 as [result] --Cant change idArea cause the ANI list is related to camps on other IDArea
                return(0)
            end
        end

        if exists(select id_RAniList from ccRotativeANIList where [description] = @descriptionList and id_RAniList <> @id_RAniList)
        begin
            SELECT -1 as [result] --Name in use
            return(0)
        end
        
        update ccRotativeANIList set [description] = @descriptionList, idArea = @idArea where id_RAniList = @id_RAniList
        SELECT 1 as [result]
        return(0)
    end
    If @type=5 --Delete Rotative ANI List
    begin
        declare @result int = -2   --ANI list is related to campaign

        if not exists(select cam_id from ccCamps where id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
        begin
            delete ccRotativeANIListDetail where id_RAniList = @id_RAniList
            delete ccRotativeANIList where id_RAniList = @id_RAniList
            delete from ccAniGlobalCount  WHERE id_RAniList = @id_RAniList
            delete from ccAniPrefixCount  WHERE id_RAniList = @id_RAniList
            delete from ccAniPrefixQueue  WHERE id_RAniList = @id_RAniList

            select @result = 1
        end

        select @result as [result]
        return(0)
    END
    IF (@type = 6) -- Read Rotative ANI List By Id
    BEGIN
SELECT CAST(cral.id_RAniList AS SMALLINT) id_RAniList,
                cral.description,
                cral.idArea
        FROM dbo.ccRotativeANIList AS cral
        WHERE cral.id_RAniList = @id_RAniList
        RETURN 0;
    END

    IF (@type = 7) -- Get List size
    BEGIN
        SELECT COUNT(*) AS listSize FROM dbo.ccRotativeANIListDetail WHERE id_RAniList = @id_RAniList
        RETURN 0;
    END
    IF(@type = 8) --Check if exist an other process executing
    BEGIN 
        SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isProcessExecuting FROM dbo.ccRIALoading AS crl
        WHERE crl.cam_id = @id_RAniList AND crl.state IN (0,2) AND crl.loadType = 2;
        RETURN (0);
    END
    IF(@type = 9) --Check if exist a campaign executing
    BEGIN
        SELECT CASE WHEN COUNT(cc.cam_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isCampaignExecuting   FROM dbo.ccCamps AS cc
        WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
        AND cc.cam_procesando = 1
        RETURN 0;
    END
    IF(@type = 10) --Update current Rotative ANI List loads to error
    BEGIN
        IF(@UserId = 0)
        BEGIN
                        UPDATE ccRIALoading SET [state] = 4 WHERE loadType = @LoadType AND [state] < 3
        END
        UPDATE ccRIALoading SET [state] = 4
                WHERE loadType = @LoadType AND [state] < 3 AND userID = @UserId 
        SELECT CASE WHEN @@ROWCOUNT > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS LoadError
        RETURN 0;
    END
    IF(@type = 11) -- Get campaign and area by ani list id
    BEGIN
        SELECT cc.id_anilist, crg.frame, cc.cam_descripcion,crca.AreaName
        FROM dbo.ccCamps AS cc INNER JOIN dbo.ccRIACat_Areas AS crca ON crca.IDArea = cc.IDArea
        INNER JOIN dbo.ccRIACampsGraph AS crcg ON crcg.cam_id = cc.cam_id
        INNER JOIN dbo.ccRIAGraphics AS crg ON crg.graphic_id = crcg.graphic_id
        WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
    END
SET NOCOUNT OFF

END'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_PurgeAniStateOrphans]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_PurgeAniStateOrphans]
(    
    @BatchSize INT = 5000,
    @MaxBatchesPerTable INT = 1000
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @BatchSize IS NULL OR @BatchSize <= 0
        SET @BatchSize = 5000;

    IF @MaxBatchesPerTable IS NULL OR @MaxBatchesPerTable <= 0
        SET @MaxBatchesPerTable = 1000;

    DECLARE 
        @Rows INT,
        @Batch INT,
        @DeletedRecord BIGINT = 0,
        @DeletedPrefix BIGINT = 0,
        @DeletedA3 BIGINT = 0,
        @OrphanCallouts BIGINT = 0;

    -------------------------------------------------------------------------
    -- 1. Crear tabla temporal de callout_id huérfanos
    -------------------------------------------------------------------------
    CREATE TABLE #OrphanCallouts
    (
        callout_id BIGINT NOT NULL
    );

    -------------------------------------------------------------------------
    -- 2. Detectar huérfanos una sola vez
    -------------------------------------------------------------------------
    INSERT INTO #OrphanCallouts (callout_id)
    SELECT q.callout_id
    FROM
    (
        SELECT s.callout_id
        FROM dbo.ccAniRecordState AS s WITH (READPAST)
        WHERE s.callout_id IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.ccoWorkingTable AS wt
              WHERE wt.callout_id = s.callout_id
          )

        UNION

        SELECT s.callout_id
        FROM dbo.ccAniPrefixState AS s WITH (READPAST)
        WHERE s.callout_id IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.ccoWorkingTable AS wt
              WHERE wt.callout_id = s.callout_id
          )

        UNION

        SELECT s.callout_id
        FROM dbo.ccAniA3State AS s WITH (READPAST)
        WHERE s.callout_id IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.ccoWorkingTable AS wt
              WHERE wt.callout_id = s.callout_id
          )
    ) AS q;

    SET @OrphanCallouts = @@ROWCOUNT;

    CREATE UNIQUE CLUSTERED INDEX IX_OrphanCallouts_Callout
    ON #OrphanCallouts (callout_id);

    -------------------------------------------------------------------------
    -- 3. Borrar ccAniRecordState
    -------------------------------------------------------------------------
    SET @Rows = 1;
    SET @Batch = 0;

    WHILE @Rows > 0 AND @Batch < @MaxBatchesPerTable
    BEGIN
        DELETE TOP (@BatchSize) s
        FROM dbo.ccAniRecordState AS s WITH (READPAST)
        INNER JOIN #OrphanCallouts AS o
            ON o.callout_id = s.callout_id
        OPTION (RECOMPILE);

        SET @Rows = @@ROWCOUNT;
        SET @DeletedRecord += @Rows;
        SET @Batch += 1;
    END;

    -------------------------------------------------------------------------
    -- 4. Borrar ccAniPrefixState
    -------------------------------------------------------------------------
    SET @Rows = 1;
    SET @Batch = 0;

    WHILE @Rows > 0 AND @Batch < @MaxBatchesPerTable
    BEGIN
        DELETE TOP (@BatchSize) s
        FROM dbo.ccAniPrefixState AS s WITH (READPAST)
        INNER JOIN #OrphanCallouts AS o
            ON o.callout_id = s.callout_id
        OPTION (RECOMPILE);

        SET @Rows = @@ROWCOUNT;
        SET @DeletedPrefix += @Rows;
        SET @Batch += 1;
    END;

    -------------------------------------------------------------------------
    -- 5. Borrar ccAniA3State
    -------------------------------------------------------------------------
    SET @Rows = 1;
    SET @Batch = 0;

    WHILE @Rows > 0 AND @Batch < @MaxBatchesPerTable
    BEGIN
        DELETE TOP (@BatchSize) s
        FROM dbo.ccAniA3State AS s WITH (READPAST)
        INNER JOIN #OrphanCallouts AS o
            ON o.callout_id = s.callout_id
        OPTION (RECOMPILE);

        SET @Rows = @@ROWCOUNT;
        SET @DeletedA3 += @Rows;
        SET @Batch += 1;
    END;

    -------------------------------------------------------------------------
    -- Resultado para log del Job
    -------------------------------------------------------------------------
    SELECT        
        @OrphanCallouts AS orphan_callout_ids_detected,
        @DeletedRecord AS deleted_ccAniRecordState,
        @DeletedPrefix AS deleted_ccAniPrefixState,
        @DeletedA3 AS deleted_ccAniA3State,
        SYSUTCDATETIME() AS finished_at_utc;
END;'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_PurgeAniStateByCampaign]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_PurgeAniStateByCampaign]
(
    @cam_id INT,
    @BatchSize INT = 5000,
    @MaxBatchesPerTable INT = 1000
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @cam_id IS NULL
        RETURN;

    IF @BatchSize IS NULL OR @BatchSize <= 0
        SET @BatchSize = 5000;

    IF @MaxBatchesPerTable IS NULL OR @MaxBatchesPerTable <= 0
        SET @MaxBatchesPerTable = 1000;

    DECLARE
        @Rows INT,
        @Batch INT,
        @DeletedRecord BIGINT = 0,
        @DeletedPrefix BIGINT = 0,
        @DeletedA3 BIGINT = 0;

    -------------------------------------------------------------------------
    -- ccAniRecordState
    -------------------------------------------------------------------------
    SET @Rows = 1;
    SET @Batch = 0;

    WHILE @Rows > 0 AND @Batch < @MaxBatchesPerTable
    BEGIN
        DELETE TOP (@BatchSize)
        FROM dbo.ccAniRecordState
        WHERE cam_id = @cam_id
        OPTION (RECOMPILE);

        SET @Rows = @@ROWCOUNT;
        SET @DeletedRecord += @Rows;
        SET @Batch += 1;
    END;

    -------------------------------------------------------------------------
    -- ccAniPrefixState
    -------------------------------------------------------------------------
    SET @Rows = 1;
    SET @Batch = 0;

    WHILE @Rows > 0 AND @Batch < @MaxBatchesPerTable
    BEGIN
        DELETE TOP (@BatchSize)
        FROM dbo.ccAniPrefixState
        WHERE cam_id = @cam_id
        OPTION (RECOMPILE);

        SET @Rows = @@ROWCOUNT;
        SET @DeletedPrefix += @Rows;
        SET @Batch += 1;
    END;

    -------------------------------------------------------------------------
    -- ccAniA3State
    -------------------------------------------------------------------------
    SET @Rows = 1;
    SET @Batch = 0;

    WHILE @Rows > 0 AND @Batch < @MaxBatchesPerTable
    BEGIN
        DELETE TOP (@BatchSize)
        FROM dbo.ccAniA3State
        WHERE cam_id = @cam_id
        OPTION (RECOMPILE);

        SET @Rows = @@ROWCOUNT;
        SET @DeletedA3 += @Rows;
        SET @Batch += 1;
    END;

    SELECT
        @cam_id AS cam_id,
        @DeletedRecord AS deleted_ccAniRecordState,
        @DeletedPrefix AS deleted_ccAniPrefixState,
        @DeletedA3 AS deleted_ccAniA3State,
        SYSUTCDATETIME() AS finished_at_utc;
END'
    exec (@sql)
    
    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetNewJobs]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetNewJobs]
    @CAMPID INT,
    @test INT = 0,
    @nAgentsLogin INT = 1,
    @iZonas INT = NULL,
    @isDashboardApi BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total INT;
    DECLARE @topCount INT, @bIsDaylight BIT;
    DECLARE @country_id INT, @TipoJobs INT,  @apikeyQuantum VARCHAR(300);
    DECLARE @sql NVARCHAR(MAX), @sqlReplace NVARCHAR(MAX), @Order_Asc_Desc VARCHAR(4);
    DECLARE @camSurvey INT = 0;
    DECLARE @maxRecs INT = 0;
    DECLARE @maxCps INT = 30;
    DECLARE @nSeconds INT = 32;
    DECLARE @isVerano VARCHAR(MAX), @csisVerano VARCHAR(MAX);
    DECLARE @dial_tels varchar(8) = ''12345NNN''
    DECLARE @message_name varchar(8000), @messageDNCL_name varchar(max), @messageDNCLConfirm_name varchar(max), @MohFiles VARCHAR(8000)
    DECLARE @empty varchar(1)=''''
    DECLARE @tNoContesta tinyint, @iTipoDial tinyint,@detectAnswerMachine smallint, @detectVoiceMail tinyint, @rotativeAlgo tinyint,@cam_tnotas smallint, @keepDial bit,
    @call_record_cam tinyint, 
    @ivr_script smallint =0 , 
    @surveycamid int ,
    @PrefixRec varchar(40),
    @recordHold bit, @recordIvr bit,
    @CampType   int,
    @aniList int,
    @algo int    

    DECLARE @params NVARCHAR(MAX) = N''
        @CAMPID INT,
        @iZonas INT,
        @maxRecs INT,
        @topCount INT,
        @dial_tels varchar(8),
        @message_name varchar(8000), 
        @messageDNCL_name varchar(max), 
        @messageDNCLConfirm_name varchar(max),
        @empty varchar(1),
        @tNoContesta tinyint,
        @iTipoDial tinyint,
        @detectAnswerMachine smallint,
        @detectVoiceMail tinyint,
        @rotativeAlgo tinyint,
        @cam_tnotas smallint,
        @keepDial bit,
        @call_record_cam tinyint,
        @country_id INT,
        @MohFiles VARCHAR(8000),
        @ivr_script smallint,
        @PrefixRec varchar(40),
        @recordHold bit, 
        @recordIvr bit,
        @apikeyQuantum VARCHAR(300),
        @CampType int,
        @aniList int,
        @algo int,
        @outA INT OUTPUT'';

    SELECT @maxRecs = TRY_CAST(valor AS INT) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 251 AND [Status] = 1;

    SELECT @camSurvey = cam_id FROM ccCamps WHERE cam_id = @CAMPID AND ISNULL(callsBySurvey, 0) > 0 AND ISNULL(ivrScript, 0) > 0;

    SELECT @country_id = valor FROM ccSettings WHERE setting_id = 104;

    select @apikeyQuantum = ISNULL(valor, '''') from dbo.ccSettings2 where setting_id=284

    SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
    FROM ccCampsMsgs VE with(nolock) 
    INNER JOIN ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @CAMPID and TYPE = 15
    ORDER BY orden

    SELECT @Order_Asc_Desc = ISNULL(CASE dialOrder WHEN 1 THEN ''desc'' ELSE ''asc'' END, ''asc''), @tNoContesta=cam_tNoContesta,  @iTipoDial=iTipoDial,
    @detectAnswerMachine=detectAnswerMachine,@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas,@keepDial=keepDial,
    @rotativeAlgo=isnull(rotativeAlgo,0)
    ,@call_record_cam = isnull(call_record,1)
    ,@surveycamid = isnull(surveycamid,0)
    ,@PrefixRec=ISNULL(prefijo,'''')
    ,@recordHold=ISNULL(recordHold,0)
    ,@recordIvr=ISNULL(recordIvr,0)
    ,@CampType = CampType
    ,@aniList = id_anilist
    ,@algo = rotativeAlgo
    FROM ccCamps WHERE cam_id = @CAMPID;
    
    
    if @surveycamid > 0
        select @ivr_script = isnull(ivrscript,0) from cccamps with(nolock) where cam_id = @surveycamid
        
    -- Mensajes
    SELECT @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm from dbo.fn_ccCamps_SelMessage(@CAMPID)

    SET DATEFIRST 1;

    SELECT @bIsDaylight = dbo.fnIsDayLight(@country_id, GETDATE());

    IF @iZonas IS NULL
    BEGIN
        EXEC @iZonas = ccsp_OUTcheckTimeZone
            @cam_id = @CAMPID,
            @isReturnSelect = 0;

        IF EXISTS (
            SELECT 1
            FROM ccCampsHorarios WITH (INDEX(IX_ccCampsHorarios))
            WHERE cam_id = @CAMPID
        )
        BEGIN
            IF @iZonas = 0
            BEGIN
                SELECT 0 AS callout_id, 0 AS cam_id, '''' AS cal_telefono, 0 AS cal_status,
                       '''' AS cal_fechaDial, 0 AS user_id, 0 AS tz
                WHERE 1 = 0;
                RETURN;
            END
        END
        ELSE IF @camSurvey > 0
        BEGIN
            SELECT 0 AS callout_id, 0 AS cam_id, '''' AS cal_telefono, 0 AS cal_status,
                   '''' AS cal_fechaDial, 0 AS user_id, 0 AS tz
            WHERE 1 = 0;
            RETURN;
        END
    END

    SET @sql = N''
    CREATE TABLE #NEW_JOBS
    (
        callout_id INT,
        cam_id INT,
        phone VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        cal_telefono VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        cal_telefono2 VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        cal_telefono3 VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        cal_telefono4 VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        cal_telefono5 VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        cal_status TINYINT,
        cal_fechaDial DATETIME,
        user_id INT,
        tz INT,
        tz2 INT,
        tz3 INT,
        tz4 INT,
        tz5 INT,
        list_id INT,
        sequence SMALLINT,
        calkey VARCHAR(MAX),
        nDescartes INT,
        name_agent VARCHAR(MAX),
        SimultaneousRecs INT,
        international INT,
        tz_tmp INT,
        tz2_tmp INT,
        tz3_tmp INT,
        tz4_tmp INT,
        tz5_tmp INT,
        cancelAttempts INT,
        Prioridad varchar(8),
        data_api_quantum varchar(max)
    );
    CREATE TABLE #AniRotative
    (
        callout_id INT,        
        ani VARCHAR(32),        
        ani2 VARCHAR(32),
        ani3 VARCHAR(32),
        ani4 VARCHAR(32),
        ani5 VARCHAR(32)
    );'';

    SELECT @maxCps = valor FROM ccSettings WITH (NOLOCK) WHERE setting_id = 238;

    IF @maxCps <= 0 SET @maxCps = 30;

    SET @topCount = @maxCps * @nSeconds;

    --SET @topCount = 1

    SELECT @TipoJobs = cam_TipoJobs FROM ccCamps WHERE cam_id = @CAMPID;

    SET @isVerano = ''W.izonahoraria'' + CASE WHEN @bIsDaylight = 1 THEN ''_verano'' ELSE '''' END;
    SET @csisVerano = ''cs.izonahoraria'' + CASE WHEN @bIsDaylight = 1 THEN ''_verano'' ELSE '''' END;

    SET @sqlReplace = N''    
    INSERT #NEW_JOBS
    SELECT TOP (@topCount)
        W.callout_id,
        W.cam_id,
        W.cal_telefono,
        cs.cal_telefono,
        cs.cal_telefono2,
        cs.cal_telefono3,
        cs.cal_telefono4,
        cs.cal_telefono5,
        W.cal_status,
        W.cal_fechaDial,
        W.user_id,
        '' + @isVerano + '',
        '' + @isVerano + ''2,
        '' + @isVerano + ''3,
        '' + @isVerano + ''4,
        '' + @isVerano + ''5,
        W.list_id,
        ISNULL(R.sequence, 0) AS sequence,
        cs.cal_key + ''''~'''' + RTRIM(dato1) + ''''~'''' + RTRIM(dato2) + ''''~'''' + RTRIM(dato3) + ''''~'''' + RTRIM(dato4) + ''''~'''' + RTRIM(dato5) AS calkey,
        W.nDescartes,
        ISNULL(us.nombres, @empty) + '''' '''' + ISNULL(us.ApellidoPaterno, @empty) + '''' '''' + ISNULL(us.ApellidoMaterno, @empty) AS Name_agent,
        ISNULL(ce.SimultaneousRecs, 1) AS SimultaneousRecs,
        ISNULL(cs.international, 0) AS international,
        '' + @csisVerano + '',
        '' + @csisVerano + ''2,
        '' + @csisVerano + ''3,
        '' + @csisVerano + ''4,
        '' + @csisVerano + ''5,
        ISNULL(W.CancelAttempts, 0) AS cancelAttempts,
        ISNULL(cpo.priorityCall,@dial_tels) dial_tels,
        case when @CampType <> 8 then  @empty else 
        (
        CASE 
            WHEN RIGHT(RTRIM(ISNULL(cs.data_api_quantum, N''''{}'''')), 1) = N''''}''''
                THEN LEFT(RTRIM(ISNULL(cs.data_api_quantum, N''''{}'''')), LEN(RTRIM(ISNULL(cs.data_api_quantum, N''''{}''''))) - 1)
            ELSE RTRIM(ISNULL(cs.data_api_quantum, N''''{}''''))
        END
        +
        CASE 
            WHEN LEN(
                    LTRIM(RTRIM(
                        CASE 
                            WHEN LEFT(LTRIM(RTRIM(ISNULL(cs.data_api_quantum, N''''{}''''))),1) = N''''{'''' 
                            AND RIGHT(RTRIM(ISNULL(cs.data_api_quantum, N''''{}'''')),1) = N''''}''''
                            THEN SUBSTRING(
                                    LTRIM(RTRIM(ISNULL(cs.data_api_quantum, N''''{}''''))),
                                    2,
                                    LEN(LTRIM(RTRIM(ISNULL(cs.data_api_quantum, N''''{}'''')))) - 2
                                )
                            ELSE LTRIM(RTRIM(ISNULL(cs.data_api_quantum, N''''{}'''')))
                        END
                    ))
                ) > 0 
            THEN N'''','''' ELSE N'''''''' 
        END
        +
        N''''"country": '''' + CONVERT(NVARCHAR(20),@country_id)
        +
        N'''', "time_zone": '''' 
        + CONVERT(NVARCHAR(20),
            CASE
                WHEN '' + @csisVerano + ''  > 0 THEN '' + @csisVerano + ''
                WHEN '' + @csisVerano + ''2 > 0 THEN '' + @csisVerano + ''2
                WHEN '' + @csisVerano + ''3 > 0 THEN '' + @csisVerano + ''3 
                WHEN '' + @csisVerano + ''4 > 0 THEN '' + @csisVerano + ''4
                WHEN '' + @csisVerano + ''5 > 0 THEN '' + @csisVerano + ''5
                ELSE 0
            END
            )
        +
        N''''}''''
    ) END AS data_api_quantum
    FROM ccoWorkingTable W
    LEFT JOIN ccRIARegistryLists R WITH (INDEX(IX_ccRIARegistryLists)) ON W.list_id = R.list_id
    LEFT JOIN ccocallsoutsource cs WITH (NOLOCK) ON cs.callout_id = W.callout_id
    LEFT JOIN ccUsers us WITH (NOLOCK) ON us.User_id = W.user_id
    LEFT JOIN ccCampsExtend ce ON ce.cam_id = W.cam_id
    LEFT JOIN ccoCallPriorityOrder cpo ON cpo.callout_id = W.callout_id
    WHERE W.cal_status = REPLACE_STATUS
      AND W.cal_fechaDial < DATEADD(MINUTE, 5, GETDATE())
      AND W.cam_id = @CAMPID
      AND (
            (('' + @isVerano + ''  & @iZonas) > 0 OR '' + @isVerano + '' = 0) OR
            (('' + @isVerano + ''2 & @iZonas) > 0 OR '' + @isVerano + ''2 = 0) OR
            (('' + @isVerano + ''3 & @iZonas) > 0 OR '' + @isVerano + ''3 = 0) OR
            (('' + @isVerano + ''4 & @iZonas) > 0 OR '' + @isVerano + ''4 = 0) OR
            (('' + @isVerano + ''5 & @iZonas) > 0 OR '' + @isVerano + ''5 = 0)
          )
      AND ISNULL(R.status, 2) = 2
    ORDER BY REPLACE_PRIORIDAD, W.cal_fechaDial '' + @Order_Asc_Desc + '', callout_id '' + @Order_Asc_Desc + '';'';

   -- print(@sqlReplace)

    
    IF @isDashboardApi = 1
    BEGIN
        SET @sql += NCHAR(13) +
            REPLACE(REPLACE(@sqlReplace, ''REPLACE_STATUS'', ''2 /** Procesando **/''),
                    ''REPLACE_PRIORIDAD'', ''R.sequence'');
    END;
    
    ELSE IF @TipoJobs IN (0, 1)
    BEGIN
        SET @sql += NCHAR(13) +
            REPLACE(REPLACE(@sqlReplace, ''REPLACE_STATUS'', ''1 /** CallBacks **/''),
                    ''REPLACE_PRIORIDAD'', ''prioridad_cb desc'');
    END;

    IF @TipoJobs IN (0, 2)
    BEGIN
        SET @sql += NCHAR(13) +
            REPLACE(REPLACE(@sqlReplace, ''REPLACE_STATUS'', ''0 /** Nuevas **/''),
                    ''REPLACE_PRIORIDAD'', ''R.sequence desc'');
    END;

    IF @test = 0
    BEGIN
        SET @sql += NCHAR(13) + N''
        UPDATE ccoWorkingTable WITH (ROWLOCK)
        SET cal_status = 2
        WHERE callout_id IN (SELECT callout_id FROM #NEW_JOBS);
        '';      
    END;

    ELSE IF @test = 2
    BEGIN
        SET @sql += NCHAR(13) + N''
        SELECT @outA = COUNT(*)
        FROM #NEW_JOBS
        WHERE LEN(cal_telefono) > 0;'';
    END
   

    SET @sql += NCHAR(13) + N''    
    if @aniList > 0
        BEGIN

            DECLARE @Batch dbo.ANIBatchType;

            INSERT INTO @Batch (callout_id, phone1, phone2, phone3, phone4, phone5)
            SELECT
            callout_id,
            cal_telefono,
            cal_telefono2,
            cal_telefono3,
            cal_telefono4,
            cal_telefono5
            FROM #NEW_JOBS
                        
            insert into #AniRotative(callout_id,ani,ani2,ani3,ani4,ani5)
            EXEC dbo.ccsp_DLRGetRotativeANIBatchInline
            @Batch = @Batch,
            @cam_id = @CAMPID,
            @aniList = @aniList,
            @algo = @algo                       

        END
    SELECT
        A.callout_id,
        A.cam_id,
        A.phone,
        A.cal_status,
        A.cal_fechaDial,
        A.user_id,
        CASE WHEN A.tz  > 0 THEN A.tz  ELSE A.tz_tmp  END AS tz,
        CASE WHEN A.tz2 > 0 THEN A.tz2 ELSE A.tz2_tmp END AS tz2,
        CASE WHEN A.tz3 > 0 THEN A.tz3 ELSE A.tz3_tmp END AS tz3,
        CASE WHEN A.tz4 > 0 THEN A.tz4 ELSE A.tz4_tmp END AS tz4,
        CASE WHEN A.tz5 > 0 THEN A.tz5 ELSE A.tz5_tmp END AS tz5,
        CASE WHEN A.tz  IS NULL THEN @empty ELSE A.cal_telefono END AS tel,
        CASE WHEN A.tz2 IS NULL THEN @empty ELSE A.cal_telefono2 END AS tel2,
        CASE WHEN A.tz3 IS NULL THEN @empty ELSE A.cal_telefono3 END AS tel3,
        CASE WHEN A.tz4 IS NULL THEN @empty ELSE A.cal_telefono4 END AS tel4,
        CASE WHEN A.tz5 IS NULL THEN @empty ELSE A.cal_telefono5 END AS tel5,
        NULL AS dialOrder,
        A.list_id,
        A.sequence,
        A.calkey,
        0 AS tel_type,
        0 AS tel2_type,
        0 AS tel3_type,
        0 AS tel4_type,
        0 AS tel5_type,
        A.nDescartes,
        A.name_agent,
        A.SimultaneousRecs,
        @maxRecs AS maxRecs,
        A.international,
        A.cancelAttempts,
        A.prioridad dial_tels,
        ISNULL(@message_name, @empty) as message_name,
        @tNoContesta tNoContesta,
        @iTipoDial iTipoDial,
        @detectAnswerMachine detectAnswerMachine, 
        @detectVoiceMail detectVoiceMail,
        @cam_tnotas cam_tnotas,
        @keepDial keepDial,
        ISNULL(@messageDNCL_name, @empty) as messageDNCL_name,
        dbo.EnableCallRecord(@call_record_cam,@country_id,A.cal_telefono) as call_record,
        dbo.EnableCallRecord(@call_record_cam,@country_id,A.cal_telefono2) as call_record2,
        dbo.EnableCallRecord(@call_record_cam,@country_id,A.cal_telefono3) as call_record3,
        dbo.EnableCallRecord(@call_record_cam,@country_id,A.cal_telefono4) as call_record4,
        dbo.EnableCallRecord(@call_record_cam,@country_id,A.cal_telefono5) as call_record5,
        ISNULL(@messageDNCLConfirm_name, @empty) as messageDNCLConfirm_name,
        ISNULL(@MohFiles,@empty) as mohFiles,
        @ivr_script ivrScript,
        @PrefixRec as Prefijo,
        dbo.GetCarrierByTel(A.cal_telefono) carrier1, 
        dbo.GetCarrierByTel(A.cal_telefono2) carrier2, 
        dbo.GetCarrierByTel(A.cal_telefono3) carrier3, 
        dbo.GetCarrierByTel(A.cal_telefono4) carrier4, 
        dbo.GetCarrierByTel(A.cal_telefono5) carrier5,
        @recordHold as recordHold,
        @recordIvr as recordIvr,
        A.data_api_quantum,
        @apikeyQuantum AS key_api_quantum,
        isnull(B.ani,@empty)  as ani1,
        isnull(B.ani2,@empty) as ani2,
        isnull(B.ani3,@empty) as ani3,
        isnull(B.ani3,@empty) as ani4,
        isnull(B.ani5,@empty) as ani5
    FROM #NEW_JOBS A
    LEFT JOIN #AniRotative B on A.callout_id = B.callout_id
    WHERE LEN(phone) > 0;
        
    SELECT @outA = COUNT(*) FROM #NEW_JOBS WHERE LEN(phone) > 0;
    '';

    IF @test = 1
    BEGIN
        SET @sql += NCHAR(13) + N''
        delete A from ccAniRecordState A
        inner join  #NEW_JOBS B on A.callout_id = B.callout_id

        delete A from ccAniPrefixState A
        inner join  #NEW_JOBS B on A.callout_id = B.callout_id

        delete A from ccAniA3State A
        inner join  #NEW_JOBS B on A.callout_id = B.callout_id
        '';
    END

    SET @sql += NCHAR(13) + N''DROP TABLE #NEW_JOBS;'';
    
   --PRINT(@sql);

  -- select @sql

    EXEC sp_executesql
        @sql,
        @params,
        @CAMPID = @CAMPID,
        @iZonas = @iZonas,
        @maxRecs = @maxRecs,
        @topCount = @topCount,
        @dial_tels = @dial_tels,
        @message_name = @message_name ,      
        @empty = @empty,
        @tNoContesta  = @tNoContesta ,
        @iTipoDial = @iTipoDial,
        @detectAnswerMachine = @detectAnswerMachine,
        @detectVoiceMail = @detectVoiceMail,
        @cam_tnotas = @cam_tnotas,
        @keepDial = @keepDial,
        @messageDNCL_name = @messageDNCL_name , 
        @messageDNCLConfirm_name = @messageDNCLConfirm_name,
        @rotativeAlgo = @rotativeAlgo,
        @call_record_cam = @call_record_cam,
        @country_id = @country_id,
        @MohFiles = @MohFiles,
        @ivr_script = @ivr_script,
        @PrefixRec = @PrefixRec,
        @recordHold = @recordHold,
        @recordIvr  = @recordIvr,
        @apikeyQuantum = @apikeyQuantum,
        @CampType = @CampType,
        @aniList = @aniList,
        @algo = @algo,
        @outA = @total OUTPUT;

   

    IF @test = 2
        RETURN(@total);

    RETURN(0);
END'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfoMini]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfoMini]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0,
@trunkId int=0
AS
set nocount on
if @iPortNumber <= 0 
begin
    return 
end


declare @prefix as varchar(15), @trunk varchar(200)
declare @prefixCalKey as varchar(30)
declare @sipHdrFormat varchar(255)
declare @croute varchar(32), @sipheader varchar(500)
declare @cal_telefono varchar(30)

set @prefix =''''


-- Prefijo por puerto
select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor with(nolock) where provedor_id = (
    select provedor_id from ccodialers with(nolock) where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''''
    select @prefix = dialPrefix from ccCamps with(nolock) where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings with(nolock) where setting_id =101

select @iPortNumber = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,'''')
from ccCamps C with(nolock) where C.cam_id=@cam_id
    
--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max)
set @prefixCalKey=''''
select @mainPrefix = valor from ccSettings where setting_id=202

SELECT         
    @cal_telefono =cal_telefono,
    @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END
FROM ccoCallsOutSource AS c WITH (NOLOCK)
WHERE c.callout_id = @callout_id;


SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

if len(@sipheader)>32 and left(@sipheader,1)=''@''
    select @croute=substring(@sipheader, 2, 32)
            
SELECT @callout_id callout_id    
,@prefix+@prefixCalKey as sDialPrefix
,@sipheader sSIPData,
dbo.GetRoute(@cal_telefono,isnull(@croute,''''),@trunkId) destination,
@trunk trunk    
    
set nocount off
     '
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_ADMCamp]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ADMCamp]
@Descripcion varchar(40),
@cam_id smallint,
@cli_id smallint=1,
@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 2=Eliminar
@ventana tinyint = 2, -- 0 Falso, 1 Verdadero, 2 Sin Cambio
@timer int = 2,
@Activa tinyint = 2,
@user_id int=0
AS
set nocount on
--ccsp_ADMCamp ''ABCD'', 1, 0, 2, 1 , 1 , 1
declare @new_cam_id smallint
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

--HLAS no crear campa±as sin cliente asignado 20050104
if not exists(select cli_id from ccClientes where cli_id = @cli_id)
    return(0)

select @cli_id = max(cli_id) from ccClientes
if isnull(@cli_id,0)=0 
    begin
    select 0, case @idioma when 1 then ''Please check Clients Catalogue and make sure there is at least one client''
    else ''Favor de revisar el Catálogo de Clientes y verificar que exista alguno'' end
    return(0)
    end 

if @Tipo in(1,4)
begin
    if exists (select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
        begin
        select 0, case @idioma when 1 then ''Name in Use'' else ''Nombre en Uso'' end
        return(0)
        end

    Insert ccCamps (cam_descripcion, cli_id, cam_ShowCalifWnd, cam_StartTimerOnHangUp)
        Values(@Descripcion, @cli_id, @ventana, @timer)
    select @new_cam_id = SCOPE_IDENTITY()
            
    if @new_cam_id is null and @Tipo=4
        begin
        select 0, case @idioma when 1 then ''Error creating campaign'' else ''Error al crear campaña'' end
        return(0)
        end

    insert into ccoDialerCamp (dialer_id, cam_id)
        select dialer_id, @new_cam_id as cam_id from ccoDialers where status=1

    insert into ccCalifCamp (calif_id, cam_id, tipo)
        select calif_id, @new_cam_id as cam_id, 1 as tipo from ccTipoCalifOUT

    if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
        begin
        Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
        select @user_id, @new_cam_id, 1, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
        end

    else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
        begin
        Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
        select @user_id, @new_cam_id, 1, 0
        end

    select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Added Succesfully''
    else ''Campaña: '' + upper(@Descripcion) + '' Dada de Alta'' end
    return(0)
    end

if @Tipo=2
    begin
    Update ccCamps set cam_descripcion= @Descripcion where cam_id = @cam_id
    if @ventana <> 2 Update ccCamps set cam_ShowCalifWnd=@ventana where cam_id = @cam_id
    if @timer <> 2  Update ccCamps set cam_StartTimerOnHangUp=@timer where cam_id = @cam_id
    if @Activa <> 2 Update ccCamps set cam_activo=@Activa where cam_id = @cam_id

    select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Modified''
    else ''Campaña: '' + upper(@Descripcion) + '' Modificada'' end
    return(0)
    end

if @Tipo=3
    begin
    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @cam_id

    delete from ccCampsAgente where cam_id = @cam_id
    delete from ccoDialerCamp where cam_id = @cam_id
    delete from ccoWorkingTable where cam_id = @cam_id
    delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
    delete from ccoLogDials where cam_id = @cam_id
    delete from ccoCallsOut where cam_id = @cam_id
    delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
    delete from ccoCallsOutSource where cam_id = @cam_id
    
    exec [ccsp_PurgeAniStateByCampaign] @cam_id = @cam_id

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCamBackup B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @cam_id and A.tipo = 1
            
    Delete ccSupervisorCam where cam_id  = @cam_id and tipo = 1
            
    if exists(select cam_id from ccCampsAgente where cam_id = @cam_id)
        begin
        select 0, case @idioma when 1 then ''There are Agents Related to this Campaign''
        else ''Existen Agentes Relacionados con esta Campaña'' end
        return(0)
        end
            
    if exists(select cam_id from ccoCallsOut where cam_id = @cam_id)
        begin
        select 0, case @idioma when 1 then ''There are Call Registries Related with this Campaign''
        else ''Existen Registros de Llamadas Relacionados con esta Campaña'' end
        return(0)
        end

    insert ccCampsMovs (cam_id, TipoMov, NewRecords,  CBRecords, user_id) 
        Values(@cam_id, 5, 0,0,@user_id)
    Delete ccCamps Where cam_id = @cam_id

    select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Deleted''
    else ''Campaa: '' + upper(@Descripcion) + '' Eliminada'' end
    return(0)
    end

set nocount off'
    exec (@sql)
    
    SET @process = 'ALTER procedure [dbo].[ccsp_GalateaAreas] '
    SET @sql = 'ALTER procedure [dbo].[ccsp_GalateaAreas] 
@option int = 2,
@IDArea smallint = 0,
@Descripcion varchar(40) = NULL,
@maxMails smallint = 3,
@maxChats smallint = 3,
@maxTweets smallint = 3,
@maxWhats smallint = 3,
@maxWhatsOut smallint = 3,
@callWhileChat bit = 0,
@callWhileEmail bit = 0,
@callWhileTwitter bit = 0,
@CallWhileWhatsAppIn bit = 0,
@CallWhileWhatsAppOut bit = 0,
@defCampaing smallint = 0,
@movesfromArea bit = 0,
@userId int = NULL,
@groupAreas varchar (MAX) = NULL,
@toolsTransfer tinyint = NULL 
AS

SET NOCOUNT ON;
    
declare @opt int = @option -1
    
DECLARE @userLogin as varchar(40);
SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

if @option = 1 --Superuser info
begin
    create table #campsIds(
        id int,
        cadena varchar(max)
    )
            
    declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
    set @idPivots =''''
    set @idConcat=''''
            
    select @idPivots=@idPivots+Id+'','',
        @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
        ''
        from (
        select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
        )x
            
    set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
    set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
    set @sql=''
        select IDArea,''+@idConcat+'' from 
        (   select IDArea, cam_id from ccCamps) as T
        PIVOT (
        max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

    insert into #campsIds
    exec(@sql)
            
    select a.IDArea Id, 
        a.AreaName Name, 
        a.StatusArea Status, 
        a.maxMails Mails, 
        a.maxChats Chats, 
        a.maxTweets Tweets, 
        a.maxWhats Whats,
        a.maxWhatsOut WhatsOut,
        a.callWhileChat callChat,
        a.callWhileEmail callEmail,
        a.CallWhileWhatsAppIn callWhatsIn,
        a.CallWhileWhatsAppOut callWhatsOut,
        a.CreateDate as CreateDate,         
        ISNULL(b.cadena, 0) as CampaignIds  
    from ccRIACat_Areas a --Falta el datetime 
    left join #campsIds b on a.IDArea = b.id

    drop table #campsIds
end
if @option = 2 -- Select de las areas
begin
    IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
    Create table #Areas(
        IDArea smallint,
        AreaName varchar(MAX),
        maxChats tinyint ,
        maxMails tinyint ,
        maxWhats tinyint ,
        maxWhatsOut tinyint ,
        callWhileChat bit, 
        callWhileEmail bit,
        CallWhileWhatsAppIn bit,
        CallWhileWhatsAppOut bit,
        users int,
        admins int,
        camps int,
        acds int,
        maxTweets tinyint,
        toolsTransfer tinyint
    )
    insert into #Areas
    EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@maxWhats=@maxWhats,@maxWhatsOut=@maxWhatsOut,@callWhileChat=@callWhileChat,@callWhileEmail=@callWhileEmail,@callWhileWhatsAppIn=@callWhileWhatsAppIn,@callWhileWhatsAppOut=@callWhileWhatsAppOut,@defCampaing=@defCampaing, @isKolob=1
    select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
    from #Areas a
    inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

    IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
end
if @option = 3 -- Insert new area
begin
IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
    Create table #InsertAreas(
        result int,
        idAreas decimal
    )
    insert into #InsertAreas
    EXEC ccsp_RIA_ABCAreas 
        @option = @opt,
        @IDArea=@IDArea,
        @Descripcion=@Descripcion,
        @maxMails=@maxMails,
        @maxChats=@maxChats,
        @maxTweets=@maxTweets,
        @maxWhats=@maxWhats,
        @maxWhatsOut=@maxWhatsOut,
        @callWhileChat=@callWhileChat,
        @callWhileEmail=@callWhileEmail,
        @callWhileWhatsAppIn=@callWhileWhatsAppIn,
        @callWhileWhatsAppOut=@callWhileWhatsAppOut,
        @defCampaing=@defCampaing,
        @toolsTransfer=@toolsTransfer
    if (select result from #InsertAreas) = 1
        begin

            --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

            if(@movesfromArea = 1) begin
                Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
            end
        end
    Select * from #InsertAreas
end
if @option = 4 -- Delete Areas
begin
    IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
    SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
    if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
        or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
    BEGIN
        Select -1 as result
    END
    ELSE
    BEGIN
        declare @DWorkGroups as varchar(500)
        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
        select user_id,cam_id,prioridad,skill,rel_id,IDWG
        from ccCampsAgente
        where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
        select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
        from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

        Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
        Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
        select user_id,cam_id,tipo,IDWG,monitored
        from ccSupervisorCam
        where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

        Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

        delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
        delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
        delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
        where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

        delete from ccAniRecordState  where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
        delete from ccAniPrefixState  where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
        delete from ccAniA3State  where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))

        Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
        Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

        Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
        Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
        Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

        select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
        Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

        if (select valor from ccSettings where setting_id=95)=1
        begin
        Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
        Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
        Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
        end

        Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

        --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
        FROM ccRIACat_Areas 
        WHERE IDArea in (Select IDArea from #AreasDelete);

        select 1 as result
    END --  exec ccsp_GalateaAreas @option=5,@IDArea=1,@Descripcion=NULL,@maxMails=NULL,@maxChats=NULL,@maxWhats=NULL,@maxWhatsOut=NULL,@callWhileChat=1,@callWhileEmail=1,@callWhileWhatsAppIn=0,@callWhileWhatsAppOut=0,@defCampaing=NULL,@movesfromArea=0,@userId=17,@toolsTransfer=3;
end
if @option = 5 -- update Areas       
begin
    if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
        begin
            select -1 as result
            return
        end
    else
        begin

            --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

            DECLARE @PrevDescription AS VARCHAR(50);
            DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

            SELECT @PrevDescription = AreaName
            FROM ccRIACat_Areas 
            WHERE IDArea = @IDArea;

            EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                CREATE TABLE #CCAreasTable 
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            );  

            update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileWhatsAppIn=isnull(@callWhileWhatsAppIn,callWhileWhatsAppIn),callWhileWhatsAppOut=isnull(@callWhileWhatsAppOut,callWhileWhatsAppOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

            EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId, @tableTemp=''#CCAreasTable'';

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                CASE WHEN AT.identifierInfo IS NOT NULL THEN
                    CASE 
                        WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                ELSE '''' END,
                getDate(), 
                @userLogin, 
                18, 
                3, 
                AT.identifierInfo,
                CASE WHEN AT.identifierInfo IS NOT NULL THEN
                    CASE 
                        WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                        WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                            CASE 
                                WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                ELSE ''T&COMMON_NONE'' END
                        WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                            CASE
                                WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                ELSE ''COMMON_DISABLED'' END
                        when at.identifierInfo = ''T&SET_CALL_WHILE_CHAT'' then 
                            case 
                                when @callWhileChat = 1 then ''COMMON_ENABLED''
                                else ''COMMON_DISABLED'' end
                        when at.identifierInfo = ''T&SET_CALL_WHILE_EMAIL'' then 
                            case 
                                when @callWhileEmail = 1 then ''COMMON_ENABLED''
                                    else ''COMMON_DISABLED'' end
        when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_IN'' then 
                case 
                when @CallWhileWhatsAppIn = 1 then ''COMMON_ENABLED''
                    else ''COMMON_DISABLED'' end
        when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_OUT'' then 
            case 
            when @CallWhileWhatsAppOut= 1 then ''COMMON_ENABLED''
                else ''COMMON_DISABLED'' end

                        ELSE AT.dataInfo END
                ELSE '''' END, 
                CASE WHEN AT.identifierInfo IS NOT NULL THEN
                    CASE 
                        WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                ELSE '''' END
            FROM #CCAreasTable AS AT;

            EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

            IF OBJECT_ID(N''tempdb..#CCUsersTable'') IS NOT NULL DROP TABLE #CCUsersTable

            --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

        end
    if @maxChats is not null
        begin
            Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
        end
    if @movesfromArea = 1
    Begin
        Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
    End
    select 1 as result
END
IF @option = 6 -- get configAreaMultimedia by userId
BEGIN
    SELECT 
    crca.callWhileChat
    , crca.callWhileEmail
    , crca.CallWhileWhatsAppIn
    , crca.CallWhileWhatsAppOut
    FROM  
    dbo.ccRIAWorkGroupUsers AS crwgu INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
    ON crawg.IDWG = crwgu.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca 
    ON crca.IDArea = crawg.IDArea WHERE crwgu.User_id = @userId 
    GROUP BY crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut

    RETURN (0)
END
IF(@option = 7) -- get area campaign relation by areaId
BEGIN
    SELECT crcew.IdCampEsp, crawg.IDArea FROM dbo.ccRIACampEspWG AS crcew 
                            INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg
                            ON crawg.IDWG = crcew.IDWG
                            WHERE crcew.Tipo = 1 AND crawg.IDArea = @idArea
    RETURN (0)
END
        
SET NOCOUNT ON;'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_ProcessDNCQueue]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ProcessDNCQueue]
    @BatchSize INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LockResult INT;

    EXEC @LockResult = sp_getapplock
        @Resource = ''dbo.ccsp_ProcessDNCQueue'',
        @LockMode = ''Exclusive'',
        @LockOwner = ''Session'',
        @LockTimeout = 0;

    IF @LockResult < 0
        RETURN;

    BEGIN TRY

         DECLARE @Rows INT = 1;

        /* Recupera registros atorados en procesando */
        UPDATE dbo.ccDNCQueue
           SET status = 0,
               started_at = NULL
         WHERE status = 1
           AND started_at < DATEADD(MINUTE, -10, GETDATE());

        IF OBJECT_ID(''tempdb..#QueueBatch'') IS NOT NULL DROP TABLE #QueueBatch;
        CREATE TABLE #QueueBatch
        (
            QueueId BIGINT NOT NULL PRIMARY KEY,
            telefono VARCHAR(30) NOT NULL,
            ln_id INT NOT NULL,
            calKey VARCHAR(40) NULL
        );

        ;WITH cte AS
        (
            SELECT TOP (@BatchSize)
                   q.QueueId,
                   q.telefono,
                   q.ln_id,
                   q.calKey
            FROM dbo.ccDNCQueue q WITH (READPAST, UPDLOCK, ROWLOCK)
            WHERE q.status = 0
            ORDER BY q.QueueId
        )
        INSERT INTO #QueueBatch (QueueId, telefono, ln_id, calKey)
        SELECT QueueId, telefono, ln_id, calKey
        FROM cte;

        IF NOT EXISTS (SELECT 1 FROM #QueueBatch)
        BEGIN
            DROP TABLE #QueueBatch;
            EXEC sp_releaseapplock
                @Resource = ''dbo.ccsp_ProcessDNCQueue'',
                @LockOwner = ''Session'';
            RETURN;
        END

        UPDATE q
           SET q.status = 1,
               q.started_at = GETDATE(),
               q.retry_count = ISNULL(q.retry_count, 0) + 1,
               q.error_message = NULL
        FROM dbo.ccDNCQueue q
        INNER JOIN #QueueBatch b
            ON b.QueueId = q.QueueId;

        IF OBJECT_ID(''tempdb..#mycamps'') IS NOT NULL DROP TABLE #mycamps;
        CREATE TABLE #mycamps
        (
            QueueId BIGINT NOT NULL,
            cam_id INT NOT NULL,
            PRIMARY KEY (QueueId, cam_id)
        );

        INSERT INTO #mycamps (QueueId, cam_id)
        SELECT DISTINCT
               b.QueueId,
               cln.cam_id
        FROM #QueueBatch b
        INNER JOIN dbo.Camplistanegra cln
            ON cln.idtipolista = b.ln_id
        INNER JOIN dbo.ccCamps c
            ON c.cam_id = cln.cam_id
        WHERE c.CampType NOT IN (5,7);

        IF OBJECT_ID(''tempdb..#AffectedCalls'') IS NOT NULL DROP TABLE #AffectedCalls;
        CREATE TABLE #AffectedCalls
        (
            QueueId BIGINT NOT NULL,
            callout_id INT NOT NULL,
            cam_id INT NOT NULL,
            cal_key VARCHAR(40) NULL,
            cal_telefono VARCHAR(30) NULL,
            cal_telefono2 VARCHAR(30) NULL,
            cal_telefono3 VARCHAR(30) NULL,
            cal_telefono4 VARCHAR(30) NULL,
            cal_telefono5 VARCHAR(30) NULL,
            PRIMARY KEY (QueueId, callout_id)
        );

        INSERT INTO #AffectedCalls
        (
            QueueId,
            callout_id,
            cam_id,
            cal_key,
            cal_telefono,
            cal_telefono2,
            cal_telefono3,
            cal_telefono4,
            cal_telefono5
        )
        SELECT DISTINCT
               b.QueueId,
               a.callout_id,
               a.cam_id,
               a.cal_key,
               a.cal_telefono,
               a.cal_telefono2,
               a.cal_telefono3,
               a.cal_telefono4,
               a.cal_telefono5
        FROM #QueueBatch b
        INNER JOIN #mycamps mc
            ON mc.QueueId = b.QueueId
        INNER JOIN dbo.ccoCallsOutSource a WITH (NOLOCK)
            ON a.cam_id = mc.cam_id
        WHERE b.telefono IN
        (
            a.cal_telefono,
            a.cal_telefono2,
            a.cal_telefono3,
            a.cal_telefono4,
            a.cal_telefono5
        );

        IF OBJECT_ID(''tempdb..#ToRemove'') IS NOT NULL DROP TABLE #ToRemove;
        CREATE TABLE #ToRemove
        (
            QueueId BIGINT NOT NULL,
            callout_id INT NOT NULL,
            cam_id INT NOT NULL,
            pos TINYINT NOT NULL,
            telefono VARCHAR(30) NOT NULL,
            cal_key VARCHAR(40) NULL,
            PRIMARY KEY (QueueId, callout_id, pos)
        );

        INSERT INTO #ToRemove
        (
            QueueId,
            callout_id,
            cam_id,
            pos,
            telefono,
            cal_key    
        )
        SELECT
            ac.QueueId,
            ac.callout_id,
            ac.cam_id,
            v.pos,
            v.tel,
            ac.cal_key
        FROM #AffectedCalls ac
        INNER JOIN #QueueBatch b
            ON b.QueueId = ac.QueueId
        CROSS APPLY
        (
            VALUES
                (1, ac.cal_telefono),
                (2, ac.cal_telefono2),
                (3, ac.cal_telefono3),
                (4, ac.cal_telefono4),
                (5, ac.cal_telefono5)
        ) v(pos, tel)
        WHERE ISNULL(v.tel, '''') <> ''''
          AND v.tel = b.telefono;

        /* Limpia solo la posicion encontrada */
        UPDATE cs
           SET cs.cal_telefono = '''',
               cs.iZonaHoraria = 0,
               cs.iZonaHoraria_verano = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 1
        WHERE cs.cal_telefono = r.telefono;       
        
        UPDATE cs
           SET cs.cal_telefono2 = '''',
               cs.iZonaHoraria2 = 0,
               cs.iZonaHoraria_verano2 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 2
        WHERE cs.cal_telefono2 = r.telefono;  

        UPDATE cs
           SET cs.cal_telefono3 = '''',
               cs.iZonaHoraria3 = 0,
               cs.iZonaHoraria_verano3 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 3
        WHERE cs.cal_telefono3 = r.telefono; 

        UPDATE cs
           SET cs.cal_telefono4 = '''',
               cs.iZonaHoraria4 = 0,
               cs.iZonaHoraria_verano4 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 4
        WHERE cs.cal_telefono4 = r.telefono;

        UPDATE cs
           SET cs.cal_telefono5 = '''',
               cs.iZonaHoraria5 = 0,
               cs.iZonaHoraria_verano5 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 5
        WHERE cs.cal_telefono5 = r.telefono;

        CREATE TABLE #DeletedCallouts
        (
            cam_id     INT NOT NULL,
            callout_id INT NOT NULL,
            CONSTRAINT PK_DeletedCallouts PRIMARY KEY CLUSTERED (callout_id, cam_id)
        );

        /* Elimina de working table si despues de limpiar ya no quedan telefonos */
        DELETE wt
        OUTPUT deleted.cam_id, deleted.callout_id
        INTO #DeletedCallouts (cam_id, callout_id)
        FROM dbo.ccoWorkingTable wt
        INNER JOIN
        (
            SELECT DISTINCT callout_id
            FROM #ToRemove
        ) x
            ON x.callout_id = wt.callout_id
        INNER JOIN dbo.ccoCallsOutSource cs
            ON cs.callout_id = wt.callout_id
        WHERE NULLIF(cs.cal_telefono, '''') IS NULL
          AND NULLIF(cs.cal_telefono2, '''') IS NULL
          AND NULLIF(cs.cal_telefono3, '''') IS NULL
          AND NULLIF(cs.cal_telefono4, '''') IS NULL
          AND NULLIF(cs.cal_telefono5, '''') IS NULL;
        
        SET @Rows = @@ROWCOUNT;
        IF @Rows > 0
        BEGIN
            DELETE s
            FROM dbo.ccAniRecordState AS s
            INNER JOIN #DeletedCallouts AS d
                ON d.callout_id = s.callout_id                

            DELETE s
            FROM dbo.ccAniPrefixState AS s
            INNER JOIN #DeletedCallouts AS d
                ON d.callout_id = s.callout_id                

            DELETE s
            FROM dbo.ccAniA3State AS s
            INNER JOIN #DeletedCallouts AS d
                ON d.callout_id = s.callout_id                
        END;

        UPDATE wt
        SET wt.cal_telefono = COALESCE(
                NULLIF(cs.cal_telefono,''''),
                NULLIF(cs.cal_telefono2,''''),
                NULLIF(cs.cal_telefono3,''''),
                NULLIF(cs.cal_telefono4,''''),
                NULLIF(cs.cal_telefono5,''''),
                ''''
            ),
            wt.iZonaHoraria = CASE WHEN NULLIF(cs.cal_telefono,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria END,
            wt.iZonaHoraria_verano = CASE WHEN NULLIF(cs.cal_telefono,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano END,
            wt.iZonaHoraria2 = CASE WHEN NULLIF(cs.cal_telefono2,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria2 END,
            wt.iZonaHoraria_verano2 = CASE WHEN NULLIF(cs.cal_telefono2,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano2 END,
            wt.iZonaHoraria3 = CASE WHEN NULLIF(cs.cal_telefono3,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria3 END,
            wt.iZonaHoraria_verano3 = CASE WHEN NULLIF(cs.cal_telefono3,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano3 END,
            wt.iZonaHoraria4 = CASE WHEN NULLIF(cs.cal_telefono4,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria4 END,
            wt.iZonaHoraria_verano4 = CASE WHEN NULLIF(cs.cal_telefono4,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano4 END,
            wt.iZonaHoraria5 = CASE WHEN NULLIF(cs.cal_telefono5,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria5 END,
            wt.iZonaHoraria_verano5 = CASE WHEN NULLIF(cs.cal_telefono5,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano5 END
        FROM dbo.ccoWorkingTable wt
        INNER JOIN dbo.ccoCallsOutSource cs
            ON cs.callout_id = wt.callout_id
        INNER JOIN
        (
            SELECT DISTINCT callout_id
            FROM #ToRemove
        ) r
            ON r.callout_id = wt.callout_id;

        /* Borra de cola todo el lote procesado correctamente */
        DELETE q
        FROM dbo.ccDNCQueue q
        INNER JOIN #QueueBatch b
            ON b.QueueId = q.QueueId
        WHERE q.status = 1;

        DROP TABLE #ToRemove;
        DROP TABLE #AffectedCalls;
        DROP TABLE #mycamps;
        DROP TABLE #QueueBatch;

        EXEC sp_releaseapplock
            @Resource = ''dbo.ccsp_ProcessDNCQueue'',
            @LockOwner = ''Session'';

    END TRY
    BEGIN CATCH

        DECLARE @ErrorMessage VARCHAR(1000);
        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE q
           SET q.status = 2,
               q.error_message = LEFT(@ErrorMessage, 1000)
        FROM dbo.ccDNCQueue q
        INNER JOIN #QueueBatch b
            ON b.QueueId = q.QueueId
        WHERE q.status = 1;

        IF OBJECT_ID(''tempdb..#ToRemove'') IS NOT NULL DROP TABLE #ToRemove;
        IF OBJECT_ID(''tempdb..#AffectedCalls'') IS NOT NULL DROP TABLE #AffectedCalls;
        IF OBJECT_ID(''tempdb..#mycamps'') IS NOT NULL DROP TABLE #mycamps;
        IF OBJECT_ID(''tempdb..#QueueBatch'') IS NOT NULL DROP TABLE #QueueBatch;

        EXEC sp_releaseapplock
            @Resource = ''dbo.ccsp_ProcessDNCQueue'',
            @LockOwner = ''Session'';

        THROW;
    END CATCH
END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3, 
@maxChats smallint = 3,
@maxTweets smallint = 3,
@maxWhats smallint = 3,
@maxWhatsOut smallint = 3,
@callWhileChat bit = 0,
@callWhileEmail bit = 0,
@callWhileWhatsAppIn bit = 0,
@callWhileWhatsAppOut bit = 0,
@defCampaing smallint = NULL, 
@isKolob bit = 0,
@toolsTransfer bit = 0
AS

set nocount on

if @option = 1 begin --Selected Area
    Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
    isnull(a.maxWhats,3) as maxWhats, isnull(a.maxWhatsOut,3) as maxWhatsOut,a.callWhileChat, 
    a.callWhileEmail, a.callWhileWhatsAppIn, a.callWhileWhatsAppOut,
    isnull(users,0) users, isnull(admins,0) admins, 
    isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets , ToolsTransfer
    from ccRIACat_Areas a (nolock)
    left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
    left join (select IDArea,count(case when TipoUser_id = 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60)  then 1 else null end) users, count(case when TipoUser_id > 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60) then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(0,0) when 0 then isnull(IDArea,0) else 0 end group by IDArea) userswg on userswg.IDArea=a.IDArea
    left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
    left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
    where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
    when 0 then isnull(a.IDArea,0) else @IDArea end
    order by AreaName
    return(0)
end
else if @option=2 begin --Insert Area
        if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion) begin
        select -1 as result,-1 as idAreas--, Nombre en Uso
        return(0)
        end
    Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,maxWhats,maxWhatsOut,callWhileChat,callWhileEmail,callWhileWhatsAppIn,callWhileWhatsAppOut,defCampaing,CreateDate,ToolsTransfer) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@maxWhats,@maxWhatsOut,@callWhileChat,@callWhileEmail,@callWhileWhatsAppIn,@callWhileWhatsAppOut,@defCampaing,Getdate(),@toolsTransfer)
    select 1 as result, scope_identity() as idAreas--, Area Insertada
    return(0)
end
else if @option=3 begin--Update Area
    if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
        Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,maxWhats=@maxWhats,maxWhatsOut=@maxWhatsOut,callWhileChat=@callWhileChat,callWhileEmail=@callWhileEmail,callWhileWhatsAppIn=@callWhileWhatsAppIn,callWhileWhatsAppOut=@callWhileWhatsAppOut,defCampaing=@defCampaing where IDArea=@IDArea
    else
        Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,maxWhats=@maxWhats,maxWhatsOut=@maxWhatsOut,callWhileChat=@callWhileChat,callWhileEmail=@callWhileEmail,callWhileWhatsAppIn=@callWhileWhatsAppIn,callWhileWhatsAppOut=@callWhileWhatsAppOut,defCampaing=@defCampaing where IDArea=@IDArea

    if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
        Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
    return(0)
end

else if @option=4 begin --Delete Area
    if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
    or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
    begin
    select -1
    return(0)
    end

    declare @DWorkGroups as varchar(500)

        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
        select user_id,cam_id,prioridad,skill,rel_id,IDWG
        from ccCampsAgente
        where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
        select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
        from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

        Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
        Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
        select user_id,cam_id,tipo,IDWG,monitored
        from ccSupervisorCam
        where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

        Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

        delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
        delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
        delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
        where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

        delete from ccAniRecordState  where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
        delete from ccAniPrefixState  where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
        delete from ccAniA3State  where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)

        Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
        Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

        Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
        Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
        Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

        select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
        Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

        if (select valor from ccSettings where setting_id=95)=1
        begin
        Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
        Update ccCamps set IDArea=NULL where IDArea=@IDArea
        Update ccUsers set IDArea=NULL where IDArea=@IDArea
        end

        Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

        select @DWorkGroups

    return(0)
end
else if @option=5 begin -- Select Areas Campaings and show its default Campaing 
    select A.IDArea as IDArea, C.cam_id as campID, C.cam_descripcion as campName,
    case when A.defCampaing=C.cam_id then 1 else 0 end as isDefault
    from ccRIACat_Areas A (nolock)
    inner join ccCamps C on A.IDArea=C.IDArea
    order by IDArea asc, isDefault desc, campName
    return(0)
    end'
    exec (@sql)
    
    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null,
@AdminId smallint = 0
as
set nocount on

if @option = 1 -- Insert User Area
    begin
    if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
        begin
        Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
        return(0)
        end 
                     
    select 1
    return(0)
    end

if @option = 3 -- Insert camp area
    begin
    if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
        begin
        Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
        where cam_id = @InsertCamId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 4 begin-- Delete camp area
    

    --Si existe una campa? relacionada con el grupo
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
        select -4
        return(0)    
    end

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
                 
    delete from ccCampsAgente where cam_id = @DeleteCamId   

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1    

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1  
    delete from ccoWorkingTable where cam_id = @DeleteCamId

    exec [ccsp_PurgeAniStateByCampaign] @cam_id = @DeleteCamId
    
    Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
    return(0)
    end

if @option = 5 -- Insert ACDGroup area
    begin
    if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
        begin
        Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 6 -- Delete ACDGroup area
    begin
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
    delete ccInboundDnis where Inbound_id = @DeleteACDGroupId

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
    select 1
    return(0)
    end

if @option in (2, 9, 10, 11)
    begin
        declare @Type tinyint
    select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
                    
    if @option in (2, 10, 11) -- Delete User area
        begin
        if @Type = 1 -- Agente
            begin

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

            delete from ccCampsAgente where user_id = @DeleteUserId
            delete from ccInboundAgentes where user_id = @DeleteUserId

            if @option = 11
                begin
                    select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

                    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                                    
                    select * from #WorkGroupUsers
                    drop table #WorkGroupUsers
                                    
                    return(0)
                end
            end

        else if @Type in (2, 6) -- Supervisor
        begin
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            delete from ccSupervisorCam where user_id = @DeleteUserId
        end

        delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                        
        if @option=2
            begin
            update ccPosicion set user_id = 0 where user_id = @DeleteUserId
            update ccUsers set IDArea = null where user_id = @DeleteUserId  
            end
        return(0)
    end

    declare @UserWG varchar(100)
    -- @option = 9 -- Delete User area and get his workgroups

    select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

    if @Type = 1 -- Agente
        begin
        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccCampsAgente where user_id = @DeleteUserId
        delete from ccInboundAgentes where user_id = @DeleteUserId
        end

    if @Type in (2, 6) -- Supervisor
        begin
        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccSupervisorCam where user_id = @DeleteUserId
        delete from ccMenuUser where id_User = @DeleteUserId
        end

    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
    update ccPosicion set user_id = 0 where user_id = @DeleteUserId
                    
    if @option <> 11 BEGIN

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas AS CCRA, ccUsers AS CCU WHERE CCU.User_id = @DeleteUserId AND CCRA.IDArea = CCU.IDArea),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId),
            CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @DeleteUserId) = 1 THEN 28 ELSE 35 END,
            3,
            '''', 
            '''',
            (SELECT [Login] FROM ccUsers WHERE User_id = @DeleteUserId)
        );

        update ccUsers set IDArea = null where user_id = @DeleteUserId
    END
                    
    select @UserWG, @Type
    return(0)
    end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 begin-- Delete camp area
    
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
    
        ---Borra las calificacion con reprogramacion
        delete ccCalifCamp from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
        where A.cam_id=@DeleteCamId
        ---Borra las subcalificacion con reprogramacion
        delete rel from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id 
        inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
        inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        where A.cam_id=@DeleteCamId and sb.canReprogram=1
    
        update ccInbound set cam_id = null where cam_id=@DeleteCamId                
         
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

    delete from ccCampsAgente where cam_id = @DeleteCamId
    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1
    
    delete from ccoWorkingTable where cam_id = @DeleteCamId 
    exec ccsp_PurgeAniStateByCampaign @cam_id= @DeleteCamId

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    select @AreaDescripcion = area.AreaName
    from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
        with(nolock) on camp.IDArea = area.IDArea
    where camp.cam_id = @DeleteCamId
    Update ccCamps set IDArea = null where cam_id = @DeleteCamId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    return(0)
    end

if @option = 8 --Delete ACDGroup area
    begin
    if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
    begin
        update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
    delete ccInboundDnis where Inbound_id = @DeleteACDGroupId

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    select @AreaDescripcion = area.AreaName
    from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
        with(nolock) on ACD.IDArea = area.IDArea
    where ACD.Inbound_id = @DeleteACDGroupId
    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    
    if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        DECLARE @TwitterResult table(--Se declaro por que el SP ccsp_MailAdminAccount regresa una consulta.  
        result int,  
        operation varchar(30));
        insert @TwitterResult
        EXEC [dbo].[ccsp_MailAdminAccount] @action = 22,@meanContactTypeId = 2, @inboundId = @DeleteACDGroupId--se ejecutara el SP para desasociar la cuenta de mail
    end
    if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId = @DeleteACDGroupId and meanContactTypeId=1
    end
    update ccinbound set chatDomain = '''' where inbound_id = @DeleteACDGroupId--para desasociar el dominio del chat
    return(0)
    end

return(0)
set nocount off
'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WA_WT_Camp]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WA_WT_Camp]
(
    @camp_id INT,
    @reciclar INT = 1, -- se conserva por compatibilidad
    @top INT = 3000,
    @InsertedRows INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrMsg NVARCHAR(4000);
    DECLARE @ErrSeverity INT;
    DECLARE @ErrState INT;

    DECLARE @batchsizeIni INT = 0;
    DECLARE @batchsizeFin INT = 0;
    DECLARE @rango DECIMAL(10, 2) = 0.00;
    DECLARE @rowstoInsert INT = 0;

    SET @InsertedRows = 0;

    IF @top IS NULL OR @top <= 0
        SET @top = 3000;

    -------------------------------------------------------------------------
    -- Temporales
    -------------------------------------------------------------------------
    CREATE TABLE #claimWAIds
    (
        WAOut_Id INT NOT NULL PRIMARY KEY,
        old_Status INT NOT NULL
    );

    CREATE TABLE #tempWhatsAppOutSource
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        WAOut_Id INT NOT NULL,
        CallKey VARCHAR(40) NULL,
        camId INT NOT NULL,
        PhoneNumber VARCHAR(30) NULL,
        Status INT NOT NULL,
        TimeZone INT NULL,
        TimeZone_Summer INT NULL,
        List_id INT NULL,
        User_id SMALLINT NULL,
        dateDial DATETIME NULL
    );

    -------------------------------------------------------------------------
    -- Id ya es PRIMARY KEY. No se crea índice adicional sobre Id.
    -------------------------------------------------------------------------

    BEGIN TRY
        BEGIN TRAN;

        ---------------------------------------------------------------------
        -- 1. Reclamar registros WhatsApp
        --    Status 4 = tomado temporalmente por este proceso.
        ---------------------------------------------------------------------
        INSERT INTO #claimWAIds
        (
            WAOut_Id,
            old_Status
        )
        SELECT
            WAOut_Id,
            old_Status
        FROM
        (
            UPDATE TOP (@top) cwaos WITH (UPDLOCK, READPAST, ROWLOCK)
                SET Status = 4
            OUTPUT
                inserted.WAOut_Id,
                deleted.Status
            FROM dbo.ccWhatsAppOutSource AS cwaos
            WHERE cwaos.camId = @camp_id
              AND cwaos.Status = 0
        ) AS X
        (
            WAOut_Id,
            old_Status
        );

        ---------------------------------------------------------------------
        -- Si no se reclamó nada, salir limpio
        ---------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM #claimWAIds)
        BEGIN
            COMMIT;            
            SELECT @InsertedRows AS InsertedRows;
            RETURN 0;
        END;

        ---------------------------------------------------------------------
        -- 2. Preparar registros a insertar en ccoWAWorkingTable
        ---------------------------------------------------------------------
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
        SELECT TOP (@top)
            cwaos.WAOut_Id,
            cwaos.CallKey,
            cwaos.camId,
            RTRIM
            (
                LEFT
                (
                    LTRIM(cwaos.PhoneNumber + ''        ''),
                    13
                )
            ) AS PhoneNumber,
            c.old_Status AS Status,
            CASE
                WHEN cwaos.TimeZone = 0 THEN dbo.fnGetTimeZone(cwaos.PhoneNumber, 0)
                ELSE cwaos.TimeZone
            END AS TimeZone,
            CASE
                WHEN cwaos.TimeZone_Summer = 0 THEN dbo.fnGetTimeZone(cwaos.PhoneNumber, 1)
                ELSE cwaos.TimeZone_Summer
            END AS TimeZone_Summer,
            cwaos.list_id,
            cwaos.User_id,
            cwaos.dateDial
        FROM dbo.ccWhatsAppOutSource AS cwaos
        INNER JOIN #claimWAIds AS c
            ON c.WAOut_Id = cwaos.WAOut_Id
        WHERE cwaos.camId = @camp_id;

        SELECT @rowstoInsert = COUNT(*)
        FROM #tempWhatsAppOutSource;

        ---------------------------------------------------------------------
        -- Si se reclamaron registros pero no se pudo preparar la carga,
        -- regresar Status anterior.
        ---------------------------------------------------------------------
        IF @rowstoInsert = 0
        BEGIN
            UPDATE cwaos
                SET Status = c.old_Status
            FROM dbo.ccWhatsAppOutSource AS cwaos
            INNER JOIN #claimWAIds AS c
                ON c.WAOut_Id = cwaos.WAOut_Id;

            COMMIT;

            SELECT @InsertedRows AS InsertedRows;
            RETURN 0;
        END;

        ---------------------------------------------------------------------
        -- 3. Dividir carga en 3 rangos, igual que el SP original
        ---------------------------------------------------------------------
        SELECT @rango = ISNULL
        (
            CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))),
            0.00
        )
        FROM #tempWhatsAppOutSource;

        IF @rango <= 0
            SET @rango = @rowstoInsert;

        SET @batchsizeIni = 0;
        SET @batchsizeFin = @rango;

        WHILE 1 = 1
        BEGIN
            INSERT INTO dbo.ccoWAWorkingTable
            (
                WAOut_id,
                PhoneNumber,
                Callkey,
                CamId,
                WaStatus,
                dateDial,
                UserId,
                TimeZone,
                TimeZone_Summer
            )
            SELECT
                t.WAOut_Id,
                t.PhoneNumber,
                t.CallKey,
                t.camId,
                t.Status,
                t.dateDial,
                t.User_id,
                t.TimeZone,
                t.TimeZone_Summer
            FROM #tempWhatsAppOutSource AS t
            WHERE t.Id > @batchsizeIni
              AND t.Id <= @batchsizeFin
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM dbo.ccoWAWorkingTable AS wt WITH (UPDLOCK, HOLDLOCK)
                  WHERE wt.WAOut_id = t.WAOut_Id
              );

            SET @InsertedRows += @@ROWCOUNT;

            IF @batchsizeFin >= @rowstoInsert
                BREAK;

            SET @batchsizeIni = @batchsizeFin;
            SET @batchsizeFin = @batchsizeFin + @rango;
        END;

        ---------------------------------------------------------------------
        -- 4. Marcar como procesados los registros reclamados
        --    y actualizar zonas horarias calculadas.
        ---------------------------------------------------------------------
        UPDATE cwaos
            SET Status = 2,
                TimeZone = t.TimeZone,
                TimeZone_Summer = t.TimeZone_Summer
        FROM dbo.ccWhatsAppOutSource AS cwaos
        INNER JOIN #tempWhatsAppOutSource AS t
            ON t.WAOut_Id = cwaos.WAOut_Id;

        COMMIT;

        SELECT @InsertedRows AS InsertedRows;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @ErrMsg = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();

        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
        RETURN -1;
    END CATCH;
END;'
    exec (@sql)

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_SMS_WT_Camp]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_SMS_WT_Camp]
(
    @camp_id INT,
    @reciclar INT = 1, -- se conserva por compatibilidad
    @top INT = 3000,
    @InsertedRows INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrMsg NVARCHAR(4000);
    DECLARE @ErrSeverity INT;
    DECLARE @ErrState INT;

    DECLARE @batchsizeIni INT = 0;
    DECLARE @batchsizeFin INT = 0;
    DECLARE @rango DECIMAL(10, 2) = 0.00;
    DECLARE @rowstoInsert INT = 0;
    DECLARE @date DATETIME = GETDATE();

    SET @InsertedRows = 0;

    IF @top IS NULL OR @top <= 0
        SET @top = 3000;

    -------------------------------------------------------------------------
    -- Actualizar registros vencidos por carga segmentada
    -------------------------------------------------------------------------
    UPDATE dbo.smsOutSource
        SET sms_status = 2
    WHERE sms_dateDialEnd < @date
      AND isSegmentLoad = 1;

    UPDATE dbo.smsWorkingTable
        SET sms_status = 2
    WHERE sms_dateDialEnd < @date
      AND isSegmentLoad = 1;

    -------------------------------------------------------------------------
    -- Temporales
    -------------------------------------------------------------------------
    CREATE TABLE #claimSmsIds
    (
        smsout_id INT NOT NULL PRIMARY KEY,
        old_sms_status TINYINT NOT NULL
    );

    CREATE TABLE #tempsmsOutSource
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        smsout_id INT NOT NULL,
        cam_id INT NOT NULL,
        sms_phoneNumber VARCHAR(19) NULL,
        sms_status TINYINT NOT NULL,
        sms_dateDial DATETIME NULL,
        cal_keyw VARCHAR(40) NULL,
        iTimeZone INT NULL,
        iTimeZone_summer INT NULL,
        iTimeZone2 INT NULL,
        iTimeZone_summer2 INT NULL,
        iTimeZone3 INT NULL,
        iTimeZone_summer3 INT NULL,
        iTimeZone4 INT NULL,
        iTimeZone_summer4 INT NULL,
        iTimeZone5 INT NULL,
        iTimeZone_summer5 INT NULL,
        list_id INT NULL,
        sms_dateDialEnd DATETIME NULL,
        isSegmentLoad BIT NULL
    );

    -------------------------------------------------------------------------
    -- El índice sobre Id es redundante porque Id ya es PK clustered.
    -- Se deja fuera para evitar costo innecesario.
    -------------------------------------------------------------------------

    BEGIN TRY
        BEGIN TRAN;

        ---------------------------------------------------------------------
        -- 1. Reclamar registros de SMS
        --    Cambiamos temporalmente a status 4 para evitar que otro proceso
        --    tome los mismos registros.
        ---------------------------------------------------------------------
        INSERT INTO #claimSmsIds
        (
            smsout_id,
            old_sms_status
        )
        SELECT
            smsout_id,
            old_sms_status
        FROM
        (
            UPDATE TOP (@top) sos WITH (UPDLOCK, READPAST, ROWLOCK)
                SET sms_status = 4
            OUTPUT
                inserted.smsout_id,
                deleted.sms_status
            FROM dbo.smsOutSource AS sos
            WHERE sos.cam_id = @camp_id
              AND (sos.sms_status < 2 OR sos.sms_status = 7)
        ) AS X
        (
            smsout_id,
            old_sms_status
        );

        ---------------------------------------------------------------------
        -- Si no se reclamó nada, salir limpio
        ---------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM #claimSmsIds)
        BEGIN
            COMMIT;

            SELECT @InsertedRows AS InsertedRows;
            RETURN 0;
        END;

        ---------------------------------------------------------------------
        -- 2. Preparar registros a insertar en smsWorkingTable
        ---------------------------------------------------------------------
        INSERT INTO #tempsmsOutSource
        (
            smsout_id,
            cam_id,
            sms_phoneNumber,
            sms_status,
            sms_dateDial,
            cal_keyw,
            iTimeZone,
            iTimeZone_summer,
            iTimeZone2,
            iTimeZone_summer2,
            iTimeZone3,
            iTimeZone_summer3,
            iTimeZone4,
            iTimeZone_summer4,
            iTimeZone5,
            iTimeZone_summer5,
            list_id,
            sms_dateDialEnd,
            isSegmentLoad
        )
        SELECT TOP (@top)
            sos.smsout_id,
            sos.cam_id,
            RTRIM
            (
                LEFT
                (
                    LTRIM
                    (
                        sos.sms_phoneNumber  + ''        '' +
                        sos.sms_phoneNumber2 + ''         '' +
                        sos.sms_phoneNumber3 + ''         '' +
                        sos.sms_phoneNumber4 + ''         '' +
                        sos.sms_phoneNumber5 + ''         ''
                    ),
                    13
                )
            ) AS sms_phoneNumber,
            CASE c.old_sms_status
                WHEN 7 THEN 1
                ELSE c.old_sms_status
            END AS sms_status,
            sos.sms_dateDial,
            sos.callkey,
            CASE WHEN LEN(sos.sms_phoneNumber)  > 0 THEN sos.iTimeZone         ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber)  > 0 THEN sos.iTimeZone_summer  ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber2) > 0 THEN sos.iTimeZone2        ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber2) > 0 THEN sos.iTimeZone_summer2 ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber3) > 0 THEN sos.iTimeZone3        ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber3) > 0 THEN sos.iTimeZone_summer3 ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber4) > 0 THEN sos.iTimeZone4        ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber4) > 0 THEN sos.iTimeZone_summer4 ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber5) > 0 THEN sos.iTimeZone5        ELSE NULL END,
            CASE WHEN LEN(sos.sms_phoneNumber5) > 0 THEN sos.iTimeZone_summer5 ELSE NULL END,
            sos.list_id,
            sos.sms_dateDialEnd,
            ISNULL(sos.isSegmentLoad, 0)
        FROM dbo.smsOutSource AS sos
        INNER JOIN #claimSmsIds AS c
            ON c.smsout_id = sos.smsout_id
        WHERE sos.cam_id = @camp_id;

        SELECT @rowstoInsert = COUNT(*)
        FROM #tempsmsOutSource;

        ---------------------------------------------------------------------
        -- Si se reclamaron registros pero no se pudo preparar carga,
        -- regresar status anterior.
        ---------------------------------------------------------------------
        IF @rowstoInsert = 0
        BEGIN
            UPDATE sos
                SET sms_status = c.old_sms_status
            FROM dbo.smsOutSource AS sos
            INNER JOIN #claimSmsIds AS c
                ON c.smsout_id = sos.smsout_id;

            COMMIT;

            SELECT @InsertedRows AS InsertedRows;
            RETURN 0;
        END;

        ---------------------------------------------------------------------
        -- 3. Dividir carga en 3 rangos como el SP original
        ---------------------------------------------------------------------
        SELECT @rango = ISNULL
        (
            CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))),
            0.00
        )
        FROM #tempsmsOutSource;

        IF @rango <= 0
            SET @rango = @rowstoInsert;

        SET @batchsizeIni = 0;
        SET @batchsizeFin = @rango;

        WHILE 1 = 1
        BEGIN
            INSERT INTO dbo.smsWorkingTable WITH (ROWLOCK)
            (
                smsout_id,
                cam_id,
                sms_phoneNumber,
                sms_status,
                sms_dateDial,
                attemps,
                user_id,
                cal_keyw,
                iTimeZone,
                iTimeZone_summer,
                iTimeZone2,
                iTimeZone_summer2,
                iTimeZone3,
                iTimeZone_summer3,
                iTimeZone4,
                iTimeZone_summer4,
                iTimeZone5,
                iTimeZone_summer5,
                list_id,
                sms_dateDialEnd,
                isSegmentLoad
            )
            SELECT
                t.smsout_id,
                t.cam_id,
                t.sms_phoneNumber,
                t.sms_status,
                t.sms_dateDial,
                0,
                0,
                t.cal_keyw,
                t.iTimeZone,
                t.iTimeZone_summer,
                t.iTimeZone2,
                t.iTimeZone_summer2,
                t.iTimeZone3,
                t.iTimeZone_summer3,
                t.iTimeZone4,
                t.iTimeZone_summer4,
                t.iTimeZone5,
                t.iTimeZone_summer5,
                t.list_id,
                t.sms_dateDialEnd,
                t.isSegmentLoad
            FROM #tempsmsOutSource AS t
            WHERE t.Id > @batchsizeIni
              AND t.Id <= @batchsizeFin
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM dbo.smsWorkingTable AS swt WITH (UPDLOCK, HOLDLOCK)
                  WHERE swt.smsout_id = t.smsout_id
              );

            SET @InsertedRows += @@ROWCOUNT;

            IF @batchsizeFin >= @rowstoInsert
                BREAK;

            SET @batchsizeIni = @batchsizeFin;
            SET @batchsizeFin = @batchsizeFin + @rango;
        END;

        ---------------------------------------------------------------------
        -- 4. Marcar como procesados solo los reclamados
        ---------------------------------------------------------------------
        UPDATE sos
            SET sms_status = 2
        FROM dbo.smsOutSource AS sos
        INNER JOIN #claimSmsIds AS c
            ON c.smsout_id = sos.smsout_id;

        COMMIT;

        SELECT @InsertedRows AS InsertedRows;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @ErrMsg = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();

        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
        RETURN -1;
    END CATCH;
END;'
    exec (@sql)
    
    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp]
(
    @camp_id INT,
    @reciclar INT = 1, -- se conserva por compatibilidad
    @top INT = 3000,
    @InsertedRows INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ErrMsg NVARCHAR(4000);
    DECLARE @ErrSeverity INT;
    DECLARE @ErrState INT;

    DECLARE @batchsizeIni INT = 0;
    DECLARE @batchsizeFin INT = 0;
    DECLARE @rango DECIMAL(10, 2) = 0.00;
    DECLARE @rowstoInsert INT = 0;

    SET @InsertedRows = 0;

    IF @top IS NULL OR @top <= 0
        SET @top = 3000;

    -------------------------------------------------------------------------
    -- Temporales
    -------------------------------------------------------------------------
    CREATE TABLE #tempCallsOutSource
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        callout_id INT NOT NULL,
        cam_id INT NOT NULL,
        cal_telefono VARCHAR(19) NULL,
        cal_status TINYINT NOT NULL,
        cal_fechaDial DATETIME NULL,
        cal_keyw VARCHAR(40) NULL,
        iZonaHoraria INT NULL,
        iZonaHoraria_verano INT NULL,
        iZonaHoraria2 INT NULL,
        iZonaHoraria_verano2 INT NULL,
        iZonaHoraria3 INT NULL,
        iZonaHoraria_verano3 INT NULL,
        iZonaHoraria4 INT NULL,
        iZonaHoraria_verano4 INT NULL,
        iZonaHoraria5 INT NULL,
        iZonaHoraria_verano5 INT NULL,
        list_id INT NULL,
        new_status INT NULL
    );

    CREATE TABLE #calloutIdSource
    (
        callout_id INT NOT NULL PRIMARY KEY
    );

    CREATE TABLE #calloutIdSource2
    (
        callout_id INT NOT NULL PRIMARY KEY
    );

    CREATE TABLE #claimCallIds
    (
        callout_id INT NOT NULL PRIMARY KEY,
        old_cal_status TINYINT NOT NULL
    );

    -------------------------------------------------------------------------
    -- 1. Detectar registros que ya están en WT y deben quedar como no cargables
    -------------------------------------------------------------------------
    INSERT INTO #calloutIdSource (callout_id)
    SELECT TOP (@top) cs.callout_id
    FROM dbo.ccoCallsOutSource AS cs WITH (INDEX(IX_ccoCallsOutSource_17), NOLOCK)
    INNER JOIN dbo.ccoWorkingTable AS wt WITH (INDEX(PK_ccoWorkingTable), NOLOCK)
        ON cs.callout_id = wt.callout_id
       AND cs.cam_id = wt.cam_id
    WHERE cs.cam_id = @camp_id
      AND cs.cal_status IN (0, 7)
      AND wt.cal_status <= 2

    UNION

    SELECT TOP (@top) cout.callout_id
    FROM dbo.ccoCallsOutSource AS cout WITH (INDEX(IX_ccoCallsOutSource_16), NOLOCK)
    INNER JOIN dbo.ccoWorkingTable AS wtab WITH (NOLOCK)
        ON cout.callout_id = wtab.callout_id
       AND cout.cam_id = wtab.cam_id
    WHERE cout.cam_id = @camp_id
      AND (cout.cal_status < 2 OR cout.cal_status = 7);

    INSERT INTO #calloutIdSource2 (callout_id)
    SELECT TOP (@top) callout_id
    FROM dbo.ccoCallsOutSource WITH (INDEX(IX_ccoCallsOutSource_11), NOLOCK)
    WHERE cal_status IN (0, 1, 7)
      AND cam_id = @camp_id;

    IF EXISTS (SELECT 1 FROM #calloutIdSource)
    BEGIN
        UPDATE cb
            SET [status] = 6,
                schedulerStatus = 1
        FROM dbo.ccoCallBacks AS cb
        INNER JOIN #calloutIdSource AS cis
            ON cis.callout_id = cb.callout_id;

        UPDATE cs
            SET cal_Status = 4
        FROM dbo.ccoCallsOutSource AS cs
        INNER JOIN #calloutIdSource AS cis
            ON cis.callout_id = cs.callout_id;
    END;

    BEGIN TRY
        BEGIN TRAN;

        ---------------------------------------------------------------------
        -- 2. Reclamar registros de llamadas
        --    cal_status 4 = tomado temporalmente por este proceso.
        ---------------------------------------------------------------------
        INSERT INTO #claimCallIds
        (
            callout_id,
            old_cal_status
        )
        SELECT
            callout_id,
            old_cal_status
        FROM
        (
            UPDATE TOP (@top) cs WITH (UPDLOCK, READPAST, ROWLOCK)
                SET cal_status = 4
            OUTPUT
                inserted.callout_id,
                deleted.cal_status
            FROM dbo.ccoCallsOutSource AS cs
            WHERE cs.cam_id = @camp_id
              AND (cs.cal_status < 2 OR cs.cal_status = 7)
        ) AS X
        (
            callout_id,
            old_cal_status
        );

        ---------------------------------------------------------------------
        -- Si no se reclamó nada, salir limpio
        ---------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM #claimCallIds)
        BEGIN
            COMMIT;

            SELECT @InsertedRows AS InsertedRows;
            RETURN 0;
        END;

        ---------------------------------------------------------------------
        -- 3. Preparar registros a insertar en ccoWorkingTable
        ---------------------------------------------------------------------
        INSERT INTO #tempCallsOutSource
        (
            callout_id,
            cam_id,
            cal_telefono,
            cal_status,
            cal_fechaDial,
            cal_keyw,
            iZonaHoraria,
            iZonaHoraria_verano,
            iZonaHoraria2,
            iZonaHoraria_verano2,
            iZonaHoraria3,
            iZonaHoraria_verano3,
            iZonaHoraria4,
            iZonaHoraria_verano4,
            iZonaHoraria5,
            iZonaHoraria_verano5,
            list_id
        )
        SELECT TOP (@top)
            cs.callout_id,
            cs.cam_id,
            CASE
                WHEN ISNULL(cs.recycleType, 1) = 0 THEN
                    CASE
                        WHEN cs.recyclePhone = 1 THEN cs.cal_telefono
                        WHEN cs.recyclePhone = 2 THEN cs.cal_telefono2
                        WHEN cs.recyclePhone = 3 THEN cs.cal_telefono3
                        WHEN cs.recyclePhone = 4 THEN cs.cal_telefono4
                        ELSE cs.cal_telefono5
                    END
                ELSE
                    RTRIM
                    (
                        LEFT
                        (
                            LTRIM
                            (
                                cs.cal_telefono  + ''        '' +
                                cs.cal_telefono2 + ''         '' +
                                cs.cal_telefono3 + ''         '' +
                                cs.cal_telefono4 + ''         '' +
                                cs.cal_telefono5 + ''         ''
                            ),
                            13
                        )
                    )
            END AS cal_telefono,
            CASE c.old_cal_status
                WHEN 7 THEN 1
                ELSE c.old_cal_status
            END AS cal_status,
            cs.cal_fechaDial,
            cs.cal_key,
            CASE WHEN LEN(cs.cal_telefono)  > 0 THEN cs.iZonaHoraria         ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono)  > 0 THEN cs.iZonaHoraria_verano  ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria2        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria_verano2 ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria3        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria_verano3 ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria4        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria_verano4 ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria5        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria_verano5 ELSE NULL END,
            cs.list_id
        FROM dbo.ccoCallsOutSource AS cs
        INNER JOIN #claimCallIds AS c
            ON c.callout_id = cs.callout_id
        WHERE cs.cam_id = @camp_id;

        SELECT @rowstoInsert = COUNT(*)
        FROM #tempCallsOutSource;

        ---------------------------------------------------------------------
        -- Si se reclamaron registros pero no se preparó carga,
        -- regresar status anterior.
        ---------------------------------------------------------------------
        IF @rowstoInsert = 0
        BEGIN
            UPDATE cs
                SET cal_status = c.old_cal_status
            FROM dbo.ccoCallsOutSource AS cs
            INNER JOIN #claimCallIds AS c
                ON c.callout_id = cs.callout_id;

            COMMIT;

            SELECT @InsertedRows AS InsertedRows;
            RETURN 0;
        END;

        ---------------------------------------------------------------------
        -- 4. Limpiar ANI viejo antes de insertar nuevamente en ccoWorkingTable
        --    Se limpia solo por callout_id.
        ---------------------------------------------------------------------
        DELETE s
        FROM dbo.ccAniRecordState AS s
        INNER JOIN #tempCallsOutSource AS t
            ON t.callout_id = s.callout_id;

        DELETE s
        FROM dbo.ccAniPrefixState AS s
        INNER JOIN #tempCallsOutSource AS t
            ON t.callout_id = s.callout_id;

        DELETE s
        FROM dbo.ccAniA3State AS s
        INNER JOIN #tempCallsOutSource AS t
            ON t.callout_id = s.callout_id;

        ---------------------------------------------------------------------
        -- 5. Dividir carga en 3 rangos como el SP original
        ---------------------------------------------------------------------
        SELECT @rango = ISNULL
        (
            CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))),
            0.00
        )
        FROM #tempCallsOutSource;

        IF @rango <= 0
            SET @rango = @rowstoInsert;

        SET @batchsizeIni = 0;
        SET @batchsizeFin = @rango;

        WHILE 1 = 1
        BEGIN
            INSERT INTO dbo.ccoWorkingTable WITH (ROWLOCK)
            (
                callout_id,
                cam_id,
                cal_telefono,
                cal_status,
                cal_fechaDial,
                cal_keyw,
                iZonaHoraria,
                iZonaHoraria_verano,
                iZonaHoraria2,
                iZonaHoraria_verano2,
                iZonaHoraria3,
                iZonaHoraria_verano3,
                iZonaHoraria4,
                iZonaHoraria_verano4,
                iZonaHoraria5,
                iZonaHoraria_verano5,
                list_id
            )
            SELECT
                t.callout_id,
                t.cam_id,
                t.cal_telefono,
                t.cal_status,
                t.cal_fechaDial,
                t.cal_keyw,
                t.iZonaHoraria,
                t.iZonaHoraria_verano,
                t.iZonaHoraria2,
                t.iZonaHoraria_verano2,
                t.iZonaHoraria3,
                t.iZonaHoraria_verano3,
                t.iZonaHoraria4,
                t.iZonaHoraria_verano4,
                t.iZonaHoraria5,
                t.iZonaHoraria_verano5,
                t.list_id
            FROM #tempCallsOutSource AS t
            WHERE t.Id > @batchsizeIni
              AND t.Id <= @batchsizeFin
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM dbo.ccoWorkingTable AS w WITH (UPDLOCK, HOLDLOCK)
                  WHERE w.callout_id = t.callout_id
              );

            SET @InsertedRows += @@ROWCOUNT;

            IF @batchsizeFin >= @rowstoInsert
                BREAK;

            SET @batchsizeIni = @batchsizeFin;
            SET @batchsizeFin = @batchsizeFin + @rango;
        END;

        ---------------------------------------------------------------------
        -- 6. Marcar como procesados solo los reclamados
        ---------------------------------------------------------------------
        UPDATE co
            SET cal_status = 2,
                nOcupado = 0,
                nNoContesta = 0,
                nFax = 0,
                nContestadora = 0,
                nShortCall = 0,
                nOtro = 0
        FROM dbo.ccoCallsOutSource AS co
        INNER JOIN #claimCallIds AS c
            ON co.callout_id = c.callout_id;

        COMMIT;

        SELECT @InsertedRows AS InsertedRows;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SET @ErrMsg = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();

        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
        RETURN -1;
    END CATCH;
END;'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT_Camp]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT_Camp]
    @camp_id AS INT,
    @reciclar AS INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @prioridad VARCHAR(8);
    DECLARE @space VARCHAR(13);

    DECLARE @dbname VARCHAR(50);

    SELECT @dbname = c.name
    FROM sys.sysaltfiles a
    JOIN sys.database_files c
        ON a.filename = c.physical_name COLLATE SQL_Latin1_General_CP1_CI_AS
    JOIN master..sysprocesses d
        ON a.dbid = d.dbid
    WHERE d.spid = @@SPID
      AND c.type = 0;   

    DELETE dbo.ccUploadTemporal
    WHERE cam_id = @camp_id;

    -------------------------------------------------------------------------
    -- DEJAR LAS CUENTAS CON CALLBACK COMO ESTAN
    -------------------------------------------------------------------------
    UPDATE cs
        SET cs.cal_Status = 4
    FROM dbo.ccoCallsOutSource AS cs
    INNER JOIN dbo.ccoWorkingTable AS wt
        ON cs.cal_key = wt.cal_keyw
       AND cs.cam_id = wt.cam_id
    WHERE cs.cam_id = @camp_id
      AND wt.cal_status <= 2
      AND cs.cal_status IN (0, 7);

    SET @space = ''             '';

    -------------------------------------------------------------------------
    -- 1. Congelar callout_id que realmente entrarán a WT
    -------------------------------------------------------------------------
    CREATE TABLE #CalloutsToInsert
    (
        callout_id INT NOT NULL PRIMARY KEY
    );

    INSERT INTO #CalloutsToInsert (callout_id)
    SELECT DISTINCT cs.callout_id
    FROM dbo.ccoCallsOutSource AS cs
    WHERE cs.cam_id = @camp_id
      AND cs.callout_id IS NOT NULL
      AND (cs.cal_status < 2 OR cs.cal_status = 7);

    IF EXISTS (SELECT 1 FROM #CalloutsToInsert)
    BEGIN
        ---------------------------------------------------------------------
        -- 2. Limpiar ANI viejo antes de insertar a WT
        ---------------------------------------------------------------------
        DELETE s
        FROM dbo.ccAniRecordState AS s
        INNER JOIN #CalloutsToInsert AS c
            ON c.callout_id = s.callout_id;

        DELETE s
        FROM dbo.ccAniPrefixState AS s
        INNER JOIN #CalloutsToInsert AS c
            ON c.callout_id = s.callout_id;

        DELETE s
        FROM dbo.ccAniA3State AS s
        INNER JOIN #CalloutsToInsert AS c
            ON c.callout_id = s.callout_id;

        ---------------------------------------------------------------------
        -- 3. Insertar a WorkingTable solo los congelados
        ---------------------------------------------------------------------
        INSERT dbo.ccoWorkingTable
        (
            callout_id,
            cam_id,
            cal_telefono,
            cal_status,
            cal_fechaDial,
            cal_keyw,
            iZonaHoraria,
            iZonaHoraria_verano,
            iZonaHoraria2,
            iZonaHoraria_verano2,
            iZonaHoraria3,
            iZonaHoraria_verano3,
            iZonaHoraria4,
            iZonaHoraria_verano4,
            iZonaHoraria5,
            iZonaHoraria_verano5
        )
        SELECT
            cs.callout_id,
            cs.cam_id,
            RTRIM
            (
                LEFT
                (
                    LTRIM
                    (
                        cs.cal_telefono  + @space +
                        cs.cal_telefono2 + @space +
                        cs.cal_telefono3 + @space +
                        cs.cal_telefono4 + @space +
                        cs.cal_telefono5 + @space
                    ),
                    13
                )
            ) AS cal_telefono,
            CASE cs.cal_status
                WHEN 7 THEN 1
                ELSE cs.cal_status
            END AS cal_status,
            cs.cal_fechaDial,
            cs.cal_key,
            CASE WHEN LEN(cs.cal_telefono)  > 0 THEN cs.iZonaHoraria         ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono)  > 0 THEN cs.iZonaHoraria_verano  ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria2        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria_verano2 ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria3        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria_verano3 ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria4        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria_verano4 ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria5        ELSE NULL END,
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria_verano5 ELSE NULL END
        FROM dbo.ccoCallsOutSource AS cs
        INNER JOIN #CalloutsToInsert AS c
            ON c.callout_id = cs.callout_id;
    END;

    -------------------------------------------------------------------------
    -- La prioridad establecida, si existe
    -------------------------------------------------------------------------
    SELECT @prioridad = NULL;

    SELECT @prioridad = Prioridad
    FROM dbo.ccCampsPrioridadTel
    WHERE cam_id = @camp_id;

    IF @prioridad IS NULL
        SET @prioridad = ''12345NNN'';

    -------------------------------------------------------------------------
    -- 4. Marcar como IN PROGRESS solo lo que congelamos
    -------------------------------------------------------------------------
    UPDATE cs
        SET cal_status = 2,
            nOcupado = 0,
            nNoContesta = 0,
            nFax = 0,
            nContestadora = 0,
            nShortCall = 0,
            nOtro = 0
    FROM dbo.ccoCallsOutSource AS cs
    INNER JOIN #CalloutsToInsert AS c
        ON c.callout_id = cs.callout_id
    WHERE cs.cal_status IN (0, 1, 7)
      AND cs.cam_id = @camp_id;

    SET NOCOUNT OFF;
END;'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT] 
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -------------------------------------------------------------------------
    -- Para traer los datos de ccoCallsOutSource a ccoWorkingTable
    -- ccoCallsOutSource ========> ccoWorkingTable
    -------------------------------------------------------------------------

    UPDATE dbo.ccoCallsOutSource
        SET cal_status = 3
    WHERE callout_id IN
    (
        SELECT callout_id
        FROM dbo.ccoWorkingTable
    );

    UPDATE cs
        SET cs.cal_status = 4
    FROM dbo.ccoCallsOutSource AS cs
    WHERE cs.cal_key IN
    (
        SELECT cs2.cal_key
        FROM dbo.ccoWorkingTable AS wt
        INNER JOIN dbo.ccoCallsOutSource AS cs2
            ON cs2.callout_id = wt.callout_id
        WHERE wt.cal_status IN (0, 1, 2)
    );

    -------------------------------------------------------------------------
    -- 1. Congelar los callout_id que realmente van a entrar a WT
    -------------------------------------------------------------------------
    CREATE TABLE #CalloutsToInsert
    (
        callout_id INT NOT NULL PRIMARY KEY
    );

    INSERT INTO #CalloutsToInsert (callout_id)
    SELECT DISTINCT cs.callout_id
    FROM dbo.ccoCallsOutSource AS cs
    WHERE cs.callout_id IS NOT NULL
      AND (cs.cal_status < 2 OR cs.cal_status = 7);

    -------------------------------------------------------------------------
    -- Si no hay nada que insertar, salir
    -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM #CalloutsToInsert)
        RETURN;

    -------------------------------------------------------------------------
    -- 2. Limpiar ANI viejo antes de meter nuevamente el callout_id a WT
    -------------------------------------------------------------------------
    DELETE s
    FROM dbo.ccAniRecordState AS s
    INNER JOIN #CalloutsToInsert AS c
        ON c.callout_id = s.callout_id;

    DELETE s
    FROM dbo.ccAniPrefixState AS s
    INNER JOIN #CalloutsToInsert AS c
        ON c.callout_id = s.callout_id;

    DELETE s
    FROM dbo.ccAniA3State AS s
    INNER JOIN #CalloutsToInsert AS c
        ON c.callout_id = s.callout_id;

    -------------------------------------------------------------------------
    -- 3. Insertar a WorkingTable solo los callout_id congelados
    -------------------------------------------------------------------------
    INSERT dbo.ccoWorkingTable
    (
        callout_id,
        cam_id,
        cal_telefono,
        cal_status,
        cal_fechaDial,
        cal_keyw,
        iZonaHoraria,
        iZonaHoraria_verano,
        iZonaHoraria2,
        iZonaHoraria_verano2,
        iZonaHoraria3,
        iZonaHoraria_verano3,
        iZonaHoraria4,
        iZonaHoraria_verano4,
        iZonaHoraria5,
        iZonaHoraria_verano5
    )
    SELECT 
        cs.callout_id,
        cs.cam_id,
        RTRIM
        (
            LEFT
            (
                LTRIM
                (
                    cs.cal_telefono  + ''        '' +
                    cs.cal_telefono2 + ''         '' +
                    cs.cal_telefono3 + ''         '' +
                    cs.cal_telefono4 + ''         '' +
                    cs.cal_telefono5 + ''         ''
                ),
                13
            )
        ) AS cal_telefono,
        CASE cs.cal_status 
            WHEN 7 THEN 1 
            ELSE cs.cal_status 
        END AS cal_status,
        cs.cal_fechaDial,
        cs.cal_key,
        CASE WHEN LEN(cs.cal_telefono)  > 0 THEN cs.iZonaHoraria         ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono)  > 0 THEN cs.iZonaHoraria_verano  ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria2        ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria_verano2 ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria3        ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria_verano3 ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria4        ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria_verano4 ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria5        ELSE NULL END,
        CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria_verano5 ELSE NULL END
    FROM dbo.ccoCallsOutSource AS cs
    INNER JOIN #CalloutsToInsert AS c
        ON c.callout_id = cs.callout_id;

    -------------------------------------------------------------------------
    -- 4. Marcar como IN PROGRESS solo lo que se insertó
    -------------------------------------------------------------------------
    UPDATE cs
        SET cal_status = 2,
            nOcupado = 0,
            nNoContesta = 0,
            nFax = 0,
            nContestadora = 0,
            nShortCall = 0,
            nOtro = 0
    FROM dbo.ccoCallsOutSource AS cs
    INNER JOIN #CalloutsToInsert AS c
        ON c.callout_id = cs.callout_id
    WHERE cs.cal_status IN (0, 1, 7);
END;'
    exec (@sql)
    
    SET @process = 'ALTER PROCEDURE dbo.ccsp_RIAOUTInsertNewJOBS_WT_Camp'
    SET @sql = 'ALTER PROCEDURE dbo.ccsp_RIAOUTInsertNewJOBS_WT_Camp
    @camp_id INT,
    @reciclar INT = 1,
    @top INT = 3000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @campType INT;
    DECLARE @InsertedRows INT = 0;
    DECLARE @recordsQuantitySetting varchar(255)=''''

    IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') 
    BEGIN
        SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
        IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') 
        BEGIN
            select @top=CONVERT(int,Value) from dbo.fn_RIASplitDelimited(@recordsQuantitySetting,''|'') where id=2 
        END         
    END

    if @top is null set @top=3000

    SELECT @campType = cc.CampType
    FROM dbo.ccCamps AS cc
    WHERE cc.cam_id = @camp_id;

    IF (@campType = 7)
    BEGIN
        EXEC dbo.ccsp_RIAOUTInsertNewJOBS_SMS_WT_Camp
            @camp_id = @camp_id,
            @reciclar = @reciclar,
            @top = @top,
            @InsertedRows = @InsertedRows OUTPUT;
    END
    ELSE IF (@campType = 5)
    BEGIN
        EXEC dbo.ccsp_RIAOUTInsertNewJOBS_WA_WT_Camp
            @camp_id = @camp_id,
            @reciclar = @reciclar,
            @top = @top,
            @InsertedRows = @InsertedRows OUTPUT;
    END
    ELSE
    BEGIN
        EXEC dbo.ccsp_RIAOUTInsertNewJOBS_CALL_WT_Camp
            @camp_id = @camp_id,
            @reciclar = @reciclar,
            @top = @top,
            @InsertedRows = @InsertedRows OUTPUT;
    END;

    UPDATE dbo.ccCampsNvosCB
    SET dateUpdate = NULL
    WHERE id = @camp_id;

    SELECT @InsertedRows AS InsertedRows;

    RETURN 0;
END;'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]'
    SET @sql = 'ALTER PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]
    @camp_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @prioridad VARCHAR(8) = ''12345NNN'';
    DECLARE @emptyNumber VARCHAR(15) = ''         '';
    DECLARE @batchSize INT = 5000;
    DECLARE @processed INT = 0;

    -------------------------------------------------------------------------
    -- Cargar prioridad personalizada si existe
    -------------------------------------------------------------------------
    SELECT @prioridad = ISNULL(Prioridad, @prioridad)
    FROM dbo.ccCampsPrioridadTel WITH (NOLOCK)
    WHERE cam_id = @camp_id;

    -------------------------------------------------------------------------
    -- Temporal del lote
    -------------------------------------------------------------------------
    CREATE TABLE #BatchSource
    (
        callout_id INT NOT NULL PRIMARY KEY,
        user_id INT NULL,
        cam_id INT NOT NULL,
        cal_telefono VARCHAR(19) NULL,
        cal_status INT NOT NULL,
        cal_fechaDial DATETIME NULL,
        cal_keyw VARCHAR(40) NULL,
        iZonaHoraria INT NULL,
        iZonaHoraria_verano INT NULL,
        iZonaHoraria2 INT NULL,
        iZonaHoraria_verano2 INT NULL,
        iZonaHoraria3 INT NULL,
        iZonaHoraria_verano3 INT NULL,
        iZonaHoraria4 INT NULL,
        iZonaHoraria_verano4 INT NULL,
        iZonaHoraria5 INT NULL,
        iZonaHoraria_verano5 INT NULL
    );

    -------------------------------------------------------------------------
    -- Procesar por bloques
    -------------------------------------------------------------------------
    WHILE 1 = 1
    BEGIN
        TRUNCATE TABLE #BatchSource;

        ---------------------------------------------------------------------
        -- 1. Tomar lote candidato
        ---------------------------------------------------------------------
        INSERT INTO #BatchSource
        (
            callout_id,
            user_id,
            cam_id,
            cal_telefono,
            cal_status,
            cal_fechaDial,
            cal_keyw,
            iZonaHoraria,
            iZonaHoraria_verano,
            iZonaHoraria2,
            iZonaHoraria_verano2,
            iZonaHoraria3,
            iZonaHoraria_verano3,
            iZonaHoraria4,
            iZonaHoraria_verano4,
            iZonaHoraria5,
            iZonaHoraria_verano5
        )
        SELECT TOP (@batchSize)
            A.callout_id,
            A.user_id,
            A.cam_id,
            RTRIM
            (
                LEFT
                (
                    LTRIM
                    (
                        A.cal_telefono  + @emptyNumber +
                        A.cal_telefono2 + @emptyNumber +
                        A.cal_telefono3 + @emptyNumber +
                        A.cal_telefono4 + @emptyNumber +
                        A.cal_telefono5 + @emptyNumber
                    ),
                    13
                )
            ) AS cal_telefono,
            CASE A.cal_status
                WHEN 7 THEN 1
                ELSE A.cal_status
            END AS cal_status,
            A.cal_fechaDial,
            A.cal_key AS cal_keyw,
            CASE WHEN LEN(A.cal_telefono)  > 0 THEN A.iZonaHoraria         ELSE NULL END AS iZonaHoraria,
            CASE WHEN LEN(A.cal_telefono)  > 0 THEN A.iZonaHoraria_verano  ELSE NULL END AS iZonaHoraria_verano,
            CASE WHEN LEN(A.cal_telefono2) > 0 THEN A.iZonaHoraria2        ELSE NULL END AS iZonaHoraria2,
            CASE WHEN LEN(A.cal_telefono2) > 0 THEN A.iZonaHoraria_verano2 ELSE NULL END AS iZonaHoraria_verano2,
            CASE WHEN LEN(A.cal_telefono3) > 0 THEN A.iZonaHoraria3        ELSE NULL END AS iZonaHoraria3,
            CASE WHEN LEN(A.cal_telefono3) > 0 THEN A.iZonaHoraria_verano3 ELSE NULL END AS iZonaHoraria_verano3,
            CASE WHEN LEN(A.cal_telefono4) > 0 THEN A.iZonaHoraria4        ELSE NULL END AS iZonaHoraria4,
            CASE WHEN LEN(A.cal_telefono4) > 0 THEN A.iZonaHoraria_verano4 ELSE NULL END AS iZonaHoraria_verano4,
            CASE WHEN LEN(A.cal_telefono5) > 0 THEN A.iZonaHoraria5        ELSE NULL END AS iZonaHoraria5,
            CASE WHEN LEN(A.cal_telefono5) > 0 THEN A.iZonaHoraria_verano5 ELSE NULL END AS iZonaHoraria_verano5
        FROM dbo.ccoCallsOutSource AS A WITH (ROWLOCK, READPAST, INDEX(IX_ccoCallsOutSource_11))
        WHERE A.cam_id = @camp_id
          AND A.cal_status IN (0, 1, 7)
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.ccoWorkingTable AS W WITH (NOLOCK)
              WHERE W.callout_id = A.callout_id
          );

        SET @processed = @@ROWCOUNT;

        IF @processed = 0
            BREAK;

        ---------------------------------------------------------------------
        -- 2. Limpiar ANI viejo antes de insertar nuevamente en ccoWorkingTable
        ---------------------------------------------------------------------
        DELETE s
        FROM dbo.ccAniRecordState AS s
        INNER JOIN #BatchSource AS b
            ON b.callout_id = s.callout_id;

        DELETE s
        FROM dbo.ccAniPrefixState AS s
        INNER JOIN #BatchSource AS b
            ON b.callout_id = s.callout_id;

        DELETE s
        FROM dbo.ccAniA3State AS s
        INNER JOIN #BatchSource AS b
            ON b.callout_id = s.callout_id;

        ---------------------------------------------------------------------
        -- 3. Insertar lote en ccoWorkingTable
        ---------------------------------------------------------------------
        INSERT INTO dbo.ccoWorkingTable WITH (ROWLOCK)
        (
            callout_id,
            user_id,
            cam_id,
            cal_telefono,
            cal_status,
            cal_fechaDial,
            cal_keyw,
            iZonaHoraria,
            iZonaHoraria_verano,
            iZonaHoraria2,
            iZonaHoraria_verano2,
            iZonaHoraria3,
            iZonaHoraria_verano3,
            iZonaHoraria4,
            iZonaHoraria_verano4,
            iZonaHoraria5,
            iZonaHoraria_verano5
        )
        SELECT
            b.callout_id,
            b.user_id,
            b.cam_id,
            b.cal_telefono,
            b.cal_status,
            b.cal_fechaDial,
            b.cal_keyw,
            b.iZonaHoraria,
            b.iZonaHoraria_verano,
            b.iZonaHoraria2,
            b.iZonaHoraria_verano2,
            b.iZonaHoraria3,
            b.iZonaHoraria_verano3,
            b.iZonaHoraria4,
            b.iZonaHoraria_verano4,
            b.iZonaHoraria5,
            b.iZonaHoraria_verano5
        FROM #BatchSource AS b
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.ccoWorkingTable AS W WITH (UPDLOCK, HOLDLOCK)
            WHERE W.callout_id = b.callout_id
        );

        SET @processed = @@ROWCOUNT;

        IF @processed < @batchSize
            BREAK;
    END;

    -------------------------------------------------------------------------
    -- Update final
    -------------------------------------------------------------------------
    UPDATE dbo.ccoCallsOutSource WITH (ROWLOCK, READPAST)
    SET cal_status = 3,
        dial_tels = @prioridad,
        nOcupado = 0,
        nNoContesta = 0,
        nFax = 0,
        nContestadora = 0,
        nShortCall = 0,
        nOtro = 0
    WHERE cam_id = @camp_id
      AND cal_status IN (0, 1, 7)
    OPTION (OPTIMIZE FOR (@camp_id UNKNOWN));
END;
'
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
    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    
    --- END  ----


    

    

    

	
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
