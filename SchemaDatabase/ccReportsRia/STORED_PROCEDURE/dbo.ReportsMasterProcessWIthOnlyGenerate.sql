CREATE PROCEDURE [dbo].[ReportsMasterProcessWIthOnlyGenerate] @from AS DATETIME = NULL
	,@to AS DATETIME = NULL
	,@scheduleTime INT = 10
	,@dateStart DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE @i INT
	,@count INT
DECLARE @SQL VARCHAR(max)
DECLARE @name SYSNAME
DECLARE @descError NVARCHAR(max)
DECLARE @dateSP DATETIME

IF @from IS NULL
BEGIN
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
END

IF @to IS NULL
BEGIN
	SET @to = getdate()
END

IF @dateStart IS NULL
BEGIN
	SET @dateStart = getdate()
END

EXEC ccspTmpTimesInterval @from = @from	,@to = @to	,@interval = 15
EXEC ccspTmpSessionGeneral @from = @from	,@to = @to
EXEC ccspTmpSessionTimeGroup @from = @from	,@to = @to

EXEC ccspTimesccLogAgentesDia @from = @from	,@to = @to

EXEC ccspTimesOutboundData @from = @from	,@to = @to

EXEC ccspTimesInboundData @from = @from	,@to = @to

exec ccspTmpTimesccLogtransfers @from = @from, @to = @to

exec ccsptmpTimesHoldIn @from = @from, @to = @to

CREATE TABLE #tmpProcedureReports (
	id INT
	,name SYSNAME
	)

INSERT INTO #tmpProcedureReports
SELECT ROW_NUMBER() OVER (
		ORDER BY [name]
		) AS id
	,[name]
FROM sys.procedures
WHERE [name] LIKE 'ccspRep%'
	AND [name] NOT IN ('ccspRepCatalogos', 'ccsprepLogAgentriaseparate')
	AND name NOT IN (
		SELECT name
		FROM logsReportsMaster
		WHERE STATUS = 0
			AND dateStart >= @dateStart
		)

INSERT INTO [logsReportsMaster] (
	name
	,STATUS
	,dateStart
	,dateEnd
	,error
	,maxTime
	)
SELECT name
	,0
	,'19000101'
	,'19000101'
	,''
	,@scheduleTime
FROM #tmpProcedureReports

SELECT @i = 1
	,@count = count(*)
FROM #tmpProcedureReports

WHILE @i <= @count
	AND datediff(mi, @dateStart, getdate()) < @scheduleTime
BEGIN
	SELECT @name = name
	FROM #tmpProcedureReports
	WHERE id = @i

	SET @sql = 'EXEC ' + @name + ' @action=1,@from=''' + convert(VARCHAR(max), @from, 121) + ''', @to=''' + convert(VARCHAR(max), @to, 121) + ''''
	SET @dateSP = getdate()

	PRINT (@sql)

	BEGIN TRY
		EXEC (@sql)

		WAITFOR DELAY '00:00:01'

		WHILE (
				SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
					AND a.session_id = @@SPID
					AND d.TEXT = @sql
				) > 0
		BEGIN
			WAITFOR DELAY '00:00:01'
		END

		IF (datediff(ss, @dateStart, getdate()) > @scheduleTime * 60)
		BEGIN
			UPDATE [logsReportsMaster]
			SET STATUS = 2
				,dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime + 1
				,error = 'Increment time shuduler ' + convert(VARCHAR(max), @scheduleTime)
			WHERE name = @name
				AND STATUS = 0
				AND dateStart = '19000101'
				AND dateEnd = '19000101'

			UPDATE [logsReportsMaster]
			SET dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime
			WHERE STATUS = 0
				AND dateStart = '19000101'
				AND dateEnd = '19000101'

			BREAK
		END

		UPDATE [logsReportsMaster]
		SET STATUS = 1
			,dateStart = @dateSP
			,dateEnd = getdate()
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = '19000101'
			AND dateEnd = '19000101'
	END TRY

	BEGIN CATCH
		SELECT @descError = 'Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		SELECT @descError
			,@name

		UPDATE [logsReportsMaster]
		SET STATUS = 3
			,dateStart = @dateSP
			,dateEnd = getdate()
			,error = @descError
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = '19000101'
			AND dateEnd = '19000101'
	END CATCH

	SET @i = @i + 1
END

DROP TABLE #tmpProcedureReports