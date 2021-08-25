/***************************************/
/********* NUXIBA TECHNOLOGIES *********/
/***************************************/

/* Date: 2021/07 */
/* Description: Script to monitoring DB's */


/* Create database ▶ NuxibaDB_Monitor */
/* Create tables ▶ DB_Config | DB_Status | DB_Details */
/******************************************************/
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name='NuxibaDB_Monitor') BEGIN
	CREATE DATABASE NuxibaDB_Monitor;
END
GO

USE NuxibaDB_Monitor;
GO
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name IN('DB_Status','DB_Details','DB_Config')) BEGIN

  CREATE TABLE DB_Config
    (dbID int NOT NULL IDENTITY(1,1), dbName NVARCHAR(128), MonitoringMB int, PathNDF NVARCHAR(128), SizeNDF NVARCHAR(15),MaxSizeNDF NVARCHAR(15),FilegrowthNDF NVARCHAR(15)
	);

  CREATE TABLE DB_Status
    (dbID int, dbName NVARCHAR(128), Status NVARCHAR(50), CurrentStatus NVARCHAR(50), DataFiles int, DataMB DECIMAL(10,2), LogFiles int, LogMB DECIMAL(10,2),
				TotalUsedMB DECIMAL(10,2), MonitoringMB int DEFAULT 0, UserAccess NVARCHAR(50), RecoveryModel NVARCHAR(50), CreationDate NVARCHAR(50), LastBackup NVARCHAR(128)
    );

  CREATE TABLE DB_Details
    (ID int NOT NULL IDENTITY(1,1), dbName NVARCHAR(128), FilegroupName NVARCHAR(128) DEFAULT 'Not Applicable', FileType NVARCHAR(10), FileName NVARCHAR(128), TypeDescription NVARCHAR(128),
				MaxSizeMB DECIMAL(10,2), CurrentSizeMB DECIMAL(10,2), Growth DECIMAL(10,2), FreeSpaceMB DECIMAL(10,2), MonitoringMB int DEFAULT 0, CurrentSizePercent DECIMAL(10,2),
				PhysicalName NVARCHAR(520), Solved NVARCHAR(10)
	);
END



/* Create Function ▶ GetNumbersFromText */
/****************************************/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'GetNumbersFromText') AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
    BEGIN
      DROP FUNCTION [dbo].[GetNumbersFromText]
    END
GO
CREATE FUNCTION [dbo].[GetNumbersFromText](@String VARCHAR(2000))
RETURNS int 
AS BEGIN
	DECLARE @int int
	SET @String= RIGHT(@String,CHARINDEX('\',REVERSE(@String))-1)
	SELECT @int=CAST(SUBSTRING(S.Value, S1.Pos, S2.L) AS int)
	FROM (SELECT @String+' ') AS S(Value) 
		CROSS APPLY(SELECT PATINDEX('%[0-9]%', S.Value)) AS S1(Pos) 
		CROSS APPLY(SELECT PATINDEX('%[^0-9]%', STUFF(S.Value, 1, S1.Pos, ''))) AS S2(L)
	return @int 	
END
GO



/* Update table data ▶ DB_Status */
/*********************************/
CREATE PROCEDURE ccSpLoadDbStatus
AS
BEGIN	
	SET NOCOUNT ON;
    TRUNCATE TABLE [DB_Status]
	INSERT INTO [DB_Status]
		SELECT database_id AS [dbID], CONVERT(VARCHAR(25), DB.name) AS [dbName],
			CONVERT(VARCHAR(10),DATABASEPROPERTYEX(name, 'status')) AS [Status],
			state_desc AS [CurrentStatus],
			(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS [DataFiles],
			(SELECT SUM((size)/128.0) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS [DataMB],
			(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS [LogFiles],
			(SELECT SUM((size)/128.0) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS [LogMB],
			(SELECT SUM((size)/128.0) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows')+
			(SELECT SUM((size)/128.0) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS [TotalUsedMB],
			ISNULL((SELECT MonitoringMB FROM DB_Config DB WHERE DB_NAME(database_id) = DB.dbName),0) AS [MonitoringMB],
			user_access_desc AS [UserAccess], recovery_model_desc AS [RecoveryModel],
			CONVERT(VARCHAR(20), create_date, 103) + ' ' + CONVERT(VARCHAR(20), create_date, 108) AS [CreationDate],
			ISNULL((SELECT TOP 1
			CASE TYPE WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction log' END + ' – ' +
			LTRIM(ISNULL(STR(ABS(DATEDIFF(DAY, GETDATE(),Backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
			CONVERT(VARCHAR(20), backup_start_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
			CONVERT(VARCHAR(20), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
			' (' + CAST(DATEDIFF(second, BK.backup_start_date,BK.backup_finish_date) AS VARCHAR(4)) + ' ' + 'seconds)'
			FROM msdb..backupset BK WHERE BK.database_name = DB.name ORDER BY backup_set_id DESC),'-') AS [LastBackup]
		FROM sys.databases DB
		inner join DB_Config DBConfig on DB.name=DBConfig.dbName
		ORDER BY dbName, [LastBackup] DESC;
END
GO



/* Update table data ▶ DB_Details */
/**********************************/
CREATE PROCEDURE [dbo].[ccSpLoadDbDetails]
AS
BEGIN
	SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(max), @dbName NVARCHAR(255)
    DECLARE @tmp TABLE (dbName NVARCHAR(255), status bit)
    INSERT INTO @tmp SELECT dbName,0 FROM DB_Config

    IF OBJECT_ID('tempdb..#MaxNumb') IS NOT NULL DROP TABLE #MaxNumb
    IF OBJECT_ID('tempdb..#MaxNumbe') IS NOT NULL DROP TABLE #MaxNumbe
    IF OBJECT_ID('tempdb..#MaxNumber') IS NOT NULL DROP TABLE #MaxNumber
    IF OBJECT_ID('tempdb..#FileSize') IS NOT NULL DROP TABLE #FileSize

    CREATE TABLE #MaxNumb(dbNAME nvarchar(128),Number nvarchar(128))
    CREATE TABLE #MaxNumbe(dbNAME nvarchar(128))
    CREATE TABLE #MaxNumber(dbNAME nvarchar(128),Number nvarchar(128))
    CREATE TABLE #FileSize
    (dbName NVARCHAR(128), FilegroupName NVARCHAR(128), FileType NVARCHAR(10), FileName NVARCHAR(128),
			TypeDescription NVARCHAR(128), MaxSizeMB DECIMAL(10,2), CurrentSizeMB DECIMAL(10,2), Growth DECIMAL(10,2),
			FreeSpaceMB DECIMAL(10,2), MonitoringMB int, CurrentSizePercent DECIMAL(10,2), PhysicalName NVARCHAR(520), Solved NVARCHAR(10)
    );

    TRUNCATE TABLE [DB_Details]
    WHILE EXISTS(SELECT dbName FROM @tmp WHERE status=0)
		BEGIN
				SELECT @dbName=dbName FROM @tmp WHERE status=0
				SET @sql='Use '+@dbName+' 
				INSERT INTO #MaxNumb
				SELECT distinct DB_NAME(), NuxibaDB_Monitor.dbo.GetNumbersFromText(physical_name)
				FROM sys.database_files AS DBF'
				exec (@sql)
				UPDATE @tmp SET status=1 WHERE dbName=@dbName
		END

    DELETE FROM @tmp
    INSERT INTO @tmp
    SELECT dbName,0 FROM DB_Config

    WHILE EXISTS(SELECT dbName FROM @tmp where status=0) BEGIN
		SELECT @dbName=dbName FROM @tmp WHERE status=0
		SET @sql='Use '+@dbName+'
		INSERT INTO #FileSize
		SELECT DB_NAME() AS DbName, ISNULL(DS.name,''Not Applicable'') AS [FilegroupName], UPPER(RIGHT(DBF.physical_name,3)) AS [FileType], DBF.name AS [FileName],
			DBF.type_desc AS [TypeDescription], DBF.max_size/128.0 AS [MaxSizeMB], DBF.size/128.0 AS [CurrentSizeMB],
			DBF.growth/128.0 AS [Growth], DBF.size/128.0 - CAST(FILEPROPERTY(DBF.name, ''SpaceUsed'') AS int)/128.0 AS [FreeSpaceMB],
			[MonitoringMB]=
				CASE
					WHEN UPPER(RIGHT(DBF.physical_name,3))=''LDF'' THEN 0
					ELSE ISNULL(DBC.MonitoringMB,0)
				END,
			CurrentSizePercent=
				CASE
					WHEN (DBC.MonitoringMB)>0 AND UPPER(RIGHT(DBF.physical_name,3))<>''LDF'' THEN ((DBF.size/128.0)*100)/(DBC.MonitoringMB)
					ELSE 0
				END,
			DBF.physical_name AS [PhysicalName],
			[Solved]=
				CASE
					WHEN UPPER(RIGHT(DBF.physical_name,3))=''MDF'' AND DBS.DataFiles>1 THEN ''YES''				
					WHEN (SELECT [NuxibaDB_Monitor].[dbo].[GetNumbersFromText](DBF.physical_name))
					<>
					(SELECT MN3.Number FROM #MaxNumber AS MN3 WHERE MN3.dbNAME=DB_NAME()) AND 
					(SELECT [NuxibaDB_Monitor].[dbo].[GetNumbersFromText](DBF.physical_name)) >1								
					THEN ''YES''
					WHEN UPPER(RIGHT(DBF.physical_name,3))=''LDF'' THEN ''NA''
					ELSE ''NO''
				END
		FROM sys.database_files AS DBF 
		LEFT JOIN sys.data_spaces AS DS ON DBF.data_space_id = DS.data_space_id
		LEFT JOIN [NuxibaDB_Monitor].[dbo].[DB_Config] AS DBC ON DB_NAME() = DBC.dbName
		LEFT JOIN [NuxibaDB_Monitor].[dbo].[DB_Status] AS DBS ON DB_NAME() = DBS.dbName
		WHERE DBF.type IN (0,1) AND DB_NAME() IN (SELECT dbName FROM [NuxibaDB_Monitor].[dbo].[DB_Config])'
		exec (@sql)
		UPDATE @tmp SET status=1 WHERE dbName=@dbName
END

INSERT INTO [NuxibaDB_Monitor].dbo.[DB_Details] SELECT * FROM #FileSize
IF OBJECT_ID('tempdb..#MaxNumb') IS NOT NULL drop table #MaxNumb
IF OBJECT_ID('tempdb..#MaxNumbe') IS NOT NULL drop table #MaxNumbe
IF OBJECT_ID('tempdb..#MaxNumber') IS NOT NULL drop table #MaxNumber
IF OBJECT_ID('tempdb..#FileSize') IS NOT NULL drop table #FileSize

END
GO



/* Create NDF Files Without Mail and Log.csv ▶ DB's Monitoring */
/***************************************************************/
CREATE PROCEDURE [dbo].[ccSpCreateNDF]
AS
BEGIN
DECLARE @CurrentTotal int;
SELECT @CurrentTotal = COUNT(CurrentSizePercent) FROM [NuxibaDB_Monitor].[dbo].[DB_Details] WHERE CurrentSizePercent>95.00 AND Solved='NO';
	IF(@CurrentTotal>0)
		BEGIN
			DECLARE @MaxRownum int, @Iter int, @Num int
			DECLARE @dbName NVARCHAR(128), @Filegroup NVARCHAR(128), @Path NVARCHAR(128), @Size NVARCHAR(128), @MaxSize NVARCHAR(128), @FGW NVARCHAR(128), @SQLString NVARCHAR(max)
			CREATE TABLE #dbNewNDF (ID int not null IDENTITY(1,1),dbName NVARCHAR(128), FGName NVARCHAR(128), PhysicalName NVARCHAR(128),
									MaxSize DECIMAL(10,2),CurrentSize DECIMAL(10,2), Monitoring int, PathNDF NVARCHAR(128), Num int, SizeNDF NVARCHAR(15), MaxSNDF NVARCHAR(15), FgwNDF NVARCHAR(15))
			INSERT INTO #dbNewNDF 
				SELECT D.dbName, FilegroupName, D.PhysicalName, D.MaxSizeMB, D.CurrentSizeMB, D.MonitoringMB, C.PathNDF,
						(SELECT [NuxibaDB_Monitor].[dbo].[GetNumbersFromText](D.PhysicalName)),C.SizeNDF,C.MaxSizeNDF,C.FilegrowthNDF  
				FROM [NuxibaDB_Monitor].[dbo].[DB_Details] as D LEFT JOIN [NuxibaDB_Monitor].[dbo].[DB_Config] AS C ON D.dbName = C.dbName
				WHERE CurrentSizePercent>95.00 AND Solved='NO'
			SET @MaxRownum = (SELECT COUNT(dbName) FROM #dbNewNDF)
			SET @Iter = 1
			WHILE @Iter <= @MaxRownum
				BEGIN
					SELECT @dbName=dbName, @Filegroup=FGName, @Path=PathNDF, @Num=(Num+1), @Size=SizeNDF, @MaxSize=MaxSNDF, @FGW=FgwNDF FROM #dbNewNDF WHERE ID = @Iter
					SET @SQLString = 
					'ALTER DATABASE ['+@dbName+'] '+  
					'ADD FILE (  '+ 
					'	NAME = '+@dbName+'dat'+CAST(@Num AS VARCHAR)+',
						FILENAME = '''+@Path+@dbName+'_dat'+CAST(@Num AS VARCHAR)+'.ndf'',  
						SIZE = '+@Size+',
						MAXSIZE = '+@MaxSize+',  
						FILEGROWTH = '+@FGW+')
					TO FILEGROUP ['+@Filegroup+'];';
					EXECUTE(@SQLString)
					SET @Iter = @Iter + 1 
				END
			IF OBJECT_ID('tempdb..#dbNewNDF') IS NOT NULL DROP TABLE #dbNewNDF
		END
END
GO


/* Create NDF Files With Mail and Log.csv ▶ DB's Monitoring */
/************************************************************/
CREATE PROCEDURE [dbo].[ccSpCreateNDFandSendMail]
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @CurrentTotal int;
	SELECT @CurrentTotal = COUNT(CurrentSizePercent) FROM [NuxibaDB_Monitor].[dbo].[DB_Details] WHERE CurrentSizePercent>95.00 AND Solved='NO';
	IF(@CurrentTotal>0)
		BEGIN
			DECLARE @MaxRownum int, @Iter int, @BeforeNum int, @Num int
			DECLARE @dbName NVARCHAR(128), @Filegroup NVARCHAR(128), @Path NVARCHAR(128), @Size NVARCHAR(128), @MaxSize NVARCHAR(128), @FGW NVARCHAR(128), @SQLString NVARCHAR(max)
			CREATE TABLE ##dbNewNDF (ID int not null IDENTITY(1,1),dbName NVARCHAR(128), FGName NVARCHAR(128), PhysicalName NVARCHAR(128),
									MaxSize DECIMAL(10,2),CurrentSize DECIMAL(10,2), Monitoring int, PathNDF NVARCHAR(128), Num int, SizeNDF NVARCHAR(15), MaxSNDF NVARCHAR(15), FgwNDF NVARCHAR(15))
			CREATE TABLE ##NDFNewLocation (dbName NVARCHAR(128), Num int, FGName NVARCHAR(128), LName NVARCHAR(128),FName NVARCHAR(128), Size NVARCHAR(128), MaxS NVARCHAR(128), Fgw NVARCHAR(128))
			INSERT INTO ##dbNewNDF 
				SELECT D.dbName, FilegroupName, D.PhysicalName, D.MaxSizeMB, D.CurrentSizeMB, D.MonitoringMB, C.PathNDF,
						(SELECT [NuxibaDB_Monitor].[dbo].[GetNumbersFromText](D.PhysicalName)),C.SizeNDF,C.MaxSizeNDF,C.FilegrowthNDF  
				FROM [NuxibaDB_Monitor].[dbo].[DB_Details] as D LEFT JOIN [NuxibaDB_Monitor].[dbo].[DB_Config] AS C ON D.dbName = C.dbName
				WHERE CurrentSizePercent>95.00 AND Solved='NO'
			SET @MaxRownum = (SELECT COUNT(dbName) FROM ##dbNewNDF)
			SET @Iter = 1
			WHILE @Iter <= @MaxRownum
				BEGIN
					SELECT @BeforeNum=Num FROM ##dbNewNDF WHERE ID = @Iter
					SELECT @dbName=dbName, @Filegroup=FGName, @Path=PathNDF, @Num=(Num+1), @Size=SizeNDF, @MaxSize=MaxSNDF, @FGW=FgwNDF FROM ##dbNewNDF WHERE ID = @Iter
					SET @SQLString = 
					'ALTER DATABASE ['+@dbName+'] '+  
					'ADD FILE (  '+ 
					'	NAME = '+@dbName+'dat'+CAST(@Num AS VARCHAR)+',
						FILENAME = '''+@Path+@dbName+'_dat'+CAST(@Num AS VARCHAR)+'.ndf'',  
						SIZE = '+@Size+',
						MAXSIZE = '+@MaxSize+',  
						FILEGROWTH = '+@FGW+')
					TO FILEGROUP ['+@Filegroup+'];';
					INSERT INTO ##NDFNewLocation VALUES(@dbName,@BeforeNum,@Filegroup,@dbName+'dat'+CAST (@Num AS VARCHAR),@Path+@dbName+'_dat'+CAST (@Num AS VARCHAR)+'.ndf',@Size,@MaxSize,@FGW)
					EXECUTE(@SQLString)
					SET @Iter = @Iter + 1 
				END
			DECLARE @archivo VARCHAR(50), @query   VARCHAR(300), @query2  VARCHAR(300), @query3  VARCHAR(300), @comando VARCHAR(2000) 
			SET @archivo = ' "C:\Log.csv" '
			SET @query   = ' "SELECT ''dbName'',''FilegroupName'',''OLD_PhysicalName'',''OLD_MaxSizeMB'',''OLD_CurrentSizeMB'',''MonitoringMB'',''NEW_PhysicalName'',''NEW_MaxSizeMB'',''NEW_InitialSize'',''NEW_Growth_At'' UNION ALL '
			SET @query2  = ' SELECT N.dbName, N.FGName, N.PhysicalName, CAST(N.MaxSize AS VARCHAR(10)), CAST(N.CurrentSize AS VARCHAR(10)), CAST(N.Monitoring AS VARCHAR(10)),L.FName, L.MaxS, L.Size, L.Fgw '
			SET @query3  = ' FROM ##dbNewNDF AS N LEFT JOIN ##NDFNewLocation AS L ON N.Num = L.Num WHERE N.dbName = L.dbName AND N.FGName = L.FGName " '
			SET @comando = ' bcp ' +@query+@query2+@query3+ ' queryout '+ @archivo + ' -c -t, -T'
			EXEC master..xp_cmdshell @comando
			IF OBJECT_ID('tempdb..##dbNewNDF') IS NOT NULL DROP TABLE ##dbNewNDF
			IF OBJECT_ID('tempdb..##NDFNewLocation') IS NOT NULL DROP TABLE ##NDFNewLocation

			--OPTIONAL STEP
			--EXECUTE msdb.dbo.sp_start_job 'Alert NDF Created' ;
		END
END
GO