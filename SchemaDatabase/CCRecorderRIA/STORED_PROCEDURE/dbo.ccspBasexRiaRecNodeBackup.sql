CREATE PROCEDURE ccspBasexRiaRecNodeBackup @days INT = 90, @delete BIT = 0, ---Borra los registrs en el intervalo indicado
	@from DATETIME = NULL -- Para generar el backup y no elimina la informacion
AS
BEGIN
	DECLARE @nodes VARCHAR(max)
	DECLARE @grabId BIGINT, @grabIdNode BIGINT
	DECLARE @tempNodeBaseX TABLE (nodes XML)
	DECLARE @top INT
	DECLARE @now DATETIME
	DECLARE @count INT
	DECLARE @i BIGINT = 0
	DECLARE @len BIGINT
	DECLARE @dateStart DATETIME, @dateEnd DATETIME
	DECLARE @to DATETIME

	IF OBJECT_ID('tempdb..#tempGrabIdNode') IS NOT NULL
		DROP TABLE #tempGrabIdNode

	CREATE TABLE #tempGrabIdNode (grabid BIGINT, PRIMARY KEY (grabid))

	IF NOT EXISTS (
			SELECT *
			FROM sys.tables
			WHERE name = 'RiaRecnodeBasexBackup'
			)
	BEGIN
		CREATE TABLE RiaRecnodeBasexBackup (ID INT IDENTITY(1, 1) PRIMARY KEY, nodes XML NOT NULL, Xname VARCHAR(255) NOT NULL, dateStart DATETIME NOT NULL, dateEnd DATETIME NOT NULL, STATUS BIT NOT NULL)
	END

	SELECT @nodes = '', @grabIdNode = 0, @grabId = 0, @top = 1000, @count = 200000

	SET @to = convert(DATETIME, convert(VARCHAR(10), getdate(), 121))
	SET @to = DATEADD(dd, - @days, @to)

	IF @from IS NULL
		SELECT @from = min(dateIn)
		FROM RIA_RecNodeHistory

	SELECT @nodes, @grabIdNode, @grabId, @top, @count, @from, @to

	WHILE EXISTS (
			SELECT grab_id
			FROM RIA_RecNodeHistory
			WHERE grab_id > @grabId AND dateIn >= @from AND dateIn < @to
			) ---Recorre todas las grabaciones
	BEGIN
		SET @now = getdate()

		WHILE @i < @count
		BEGIN
			SET @grabIdNode = @grabId

			SELECT TOP (@top) @nodes = @nodes + convert(VARCHAR(max), node, 0), @grabId = grab_id
			FROM RIA_RecNodeHistory
			WHERE grab_id > @grabId AND dateIn >= @from AND dateIn < @to
			ORDER BY grab_id

			INSERT #tempGrabIdNode
			SELECT TOP (@top) grab_id
			FROM RIA_RecNodeHistory
			WHERE grab_id > @grabIdNode AND dateIn >= @from AND dateIn < @to
			ORDER BY grab_id

			INSERT INTO @tempNodeBaseX
			SELECT @nodes AS nodeBasex

			SELECT @nodes = ''

			SET @i = @i + @top
		END --Loop para conseguir @count	

		SELECT @nodes = @nodes + convert(VARCHAR(max), nodes, 0) + CHAR(10)
		FROM @tempNodeBaseX

		SELECT @dateStart = min(dateIn), @dateEnd = max(dateIn)
		FROM #tempGrabIdNode A
		INNER JOIN RIA_RecNodeHistory B ON A.grabid = B.grab_id

		INSERT INTO RiaRecnodeBasexBackup (nodes, Xname, dateStart, dateEnd, STATUS)
		SELECT @nodes AS nodeBasex, 'R02' + convert(VARCHAR(10), @now, 112) + '_' + replace(convert(VARCHAR(10), @now, 108), ':', '') AS Xname, @dateStart AS dateStart, @dateEnd AS dateEnd, 0 AS STATUS

		IF @delete = 1
		BEGIN
			DELETE B
			FROM #tempGrabIdNode A
			INNER JOIN RIA_RecNodeHistory B ON A.grabid = B.grab_id
		END

		TRUNCATE TABLE #tempGrabIdNode

		DELETE
		FROM @tempNodeBaseX

		SELECT @nodes = '', @i = 0
	END

	IF OBJECT_ID('tempdb..#tempGrabIdNode') IS NOT NULL
		DROP TABLE #tempGrabIdNode
END