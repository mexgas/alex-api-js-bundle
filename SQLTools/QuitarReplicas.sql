-- =============================================
-- Remove Merge or Transactional Replication
-- =============================================

USE master;
GO

DECLARE @sql NVARCHAR(MAX);
DECLARE @subscriptionReportsRiaDB SYSNAME = N'ccReportsRia';
DECLARE @subscriptionAVRSDB SYSNAME = N'CCRecorderRIA';
DECLARE @publicationCWDB SYSNAME = N'CCenterRia';
DECLARE @publicationAVRSDB SYSNAME = N'CCRecorderRIA';

-- =============================================
-- Drop migration-related tables
-- =============================================
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'CCenterRia')
BEGIN
    SET @sql = '
    USE [CCenterRia];
    IF EXISTS (SELECT * FROM sysobjects WHERE name = ''migration'') DROP TABLE migration;
    IF EXISTS (SELECT * FROM sysobjects WHERE name = ''migrationAVRS'') DROP TABLE migrationAVRS;
    ';
    EXEC sp_executesql @sql;
END;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'CCRecorderRia')
BEGIN
    SET @sql = '
    USE [CCRecorderRia];
    IF EXISTS (SELECT * FROM sysobjects WHERE name = ''migrationAVRSReports'') DROP TABLE migrationAVRSReports;
    ';
    EXEC sp_executesql @sql;
END;

-- =============================================
-- Remove merge-related indexes (ccReportsRia)
-- =============================================
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ccReportsRia')
BEGIN
    SET @sql = '
    USE [ccReportsRia];

    DECLARE @num INT, @count INT;
    DECLARE @name NVARCHAR(MAX), @tableName NVARCHAR(MAX), @sql NVARCHAR(MAX);

    DECLARE @tempIndex TABLE(
        row INT NOT NULL,
        name_index VARCHAR(500) NOT NULL,
        table_name VARCHAR(500) NOT NULL
    );

    INSERT INTO @tempIndex
    SELECT 
        ROW_NUMBER() OVER(ORDER BY A.name DESC) AS row,
        A.name AS name_index,
        OBJECT_NAME(A.id) AS table_name
    FROM sysindexes A
    WHERE name LIKE ''%merge%'' AND OBJECT_NAME(A.id) NOT LIKE ''%merge%'';

    SELECT @count = COUNT(*) FROM @tempIndex;
    SET @num = 1;

    WHILE @num <= @count
    BEGIN
        SELECT @tableName = table_name, @name = name_index FROM @tempIndex WHERE row = @num;
        SET @sql = ''DROP INDEX '' + @name + '' ON '' + @tableName;
		--print (@sql)
        EXEC(@sql);
        SET @num = @num + 1;
    END;

    IF @count > 0
        PRINT ''Merge-related indexes removed from ccReportsRia'';
    ELSE
        PRINT ''No merge-related indexes found in ccReportsRia'';
    ';
    EXEC sp_executesql @sql;
END;


-- =============================================
-- Remove local subscriptions and publications
-- =============================================
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ccReportsRia')
BEGIN
    BEGIN TRY
        SET @sql = '
        USE [ccReportsRia];
        EXEC sp_removedbreplication @subscriptionReportsRiaDB;
        ';
        EXEC sp_executesql @sql, N'@subscriptionReportsRiaDB sysname', @subscriptionReportsRiaDB = @subscriptionReportsRiaDB;
        PRINT 'Local subscriptions removed from ccReportsRia';
    END TRY
    BEGIN CATCH
        PRINT 'No local subscriptions in ccReportsRia';
    END CATCH
END;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'CCRecorderRIA')
BEGIN
    BEGIN TRY
        SET @sql = '
        USE [CCRecorderRIA];
        EXEC sp_removedbreplication @subscriptionAVRSDB;
        EXEC sp_msforeachtable @command1 = ''DECLARE @int INT; SET @int = OBJECT_ID("?"); EXEC sys.sp_identitycolumnforreplication @int, 0'';
        ';
        EXEC sp_executesql @sql, N'@subscriptionAVRSDB sysname', @subscriptionAVRSDB = @subscriptionAVRSDB;
        PRINT 'Local subscriptions removed from CCRecorderRIA';
    END TRY
    BEGIN CATCH
        PRINT 'No local subscriptions in CCRecorderRIA';
    END CATCH
END;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'CCenterRia')
BEGIN
    BEGIN TRY
        SET @sql = '
        USE [CCenterRia];
        EXEC sp_removedbreplication @publicationCWDB;
        EXEC sp_msforeachtable @command1 = ''DECLARE @int INT; SET @int = OBJECT_ID("?"); EXEC sys.sp_identitycolumnforreplication @int, 0'';
        ';
        EXEC sp_executesql @sql, N'@publicationCWDB sysname', @publicationCWDB = @publicationCWDB;
        PRINT 'Local publications removed from CCenterRia';
    END TRY
    BEGIN CATCH
        PRINT 'No local publications in CCenterRia';
    END CATCH
END;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'CCRecorderRIA')
BEGIN
    BEGIN TRY
        SET @sql = '
        USE [CCRecorderRIA];
        EXEC sp_removedbreplication @publicationAVRSDB;
        EXEC sp_msforeachtable @command1 = ''DECLARE @int INT; SET @int = OBJECT_ID("?"); EXEC sys.sp_identitycolumnforreplication @int, 0'';
        ';
        EXEC sp_executesql @sql, N'@publicationAVRSDB sysname', @publicationAVRSDB = @publicationAVRSDB;
        PRINT 'Local publications removed from CCRecorderRIA';
    END TRY
    BEGIN CATCH
        PRINT 'No local publications in CCRecorderRIA';
    END CATCH
END;

-- =============================================
-- Remove distributor
-- =============================================
BEGIN TRY
    EXEC sp_dropdistributor @no_checks = 1;
    PRINT 'Replication distributor removed';
END TRY
BEGIN CATCH
    PRINT 'No replication distributor installed';
END CATCH;

-- =============================================
-- Clean Up Linked Servers and Jobs Related to Transactional Replication
-- =============================================
IF EXISTS (SELECT * FROM sys.servers WHERE name = 'SvrPublisher_transactional')
BEGIN
    EXEC master.dbo.sp_dropserver @server = 'SvrPublisher_transactional', @droplogins = NULL;
    PRINT 'Dropped linked server: SvrPublisher_transactional';
END;

DECLARE @jobList TABLE (rownum INT IDENTITY(1,1), jobName NVARCHAR(255));
INSERT INTO @jobList (jobName)
SELECT name
FROM msdb.dbo.sysjobs
WHERE name IN (
    'CW_Tran_Replication_CCReportsRIA',
    'CW_Tran_Replication_CCRecorderRIA',
    'AVRSReports Tran Replication',
    'CW Tran Replication',
	-- Merge replication-related jobs start here
    'AVRSReports Merge Replication',
	'CW Merge Replication',
	'CW_Merge_Replication_CCRecorderRIA',
	'CW_Merge_Replication_CCReportsRIA'
);

DECLARE @row INT = 1, @total INT;
SELECT @total = COUNT(*) FROM @jobList;

WHILE @row <= @total
BEGIN
    DECLARE @jobName NVARCHAR(255);
    SELECT @jobName = jobName FROM @jobList WHERE rownum = @row;

    IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @jobName)
    BEGIN
        EXEC msdb.dbo.sp_delete_job @job_name = @jobName, @delete_unused_schedule = 1;
        PRINT 'Deleted job: ' + @jobName;
    END

    SET @row = @row + 1;
END;
