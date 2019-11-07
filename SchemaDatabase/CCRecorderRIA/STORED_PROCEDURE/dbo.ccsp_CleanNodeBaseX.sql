CREATE PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
AS
BEGIN
	DECLARE @percentage INT, @setting INT
	DECLARE @nodos TABLE (fecha VARCHAR(100))
	DECLARE @top INT
	DECLARE @table TABLE (grabId BIGINT PRIMARY KEY, node XML NOT NULL, dateIn DATETIME NOT NULL, STATUS TINYINT NOT NULL)
	DECLARE @tableNotExists TABLE (grabId BIGINT PRIMARY KEY)

	SET @percentage = 20 --porcentaje de registros que se pasaran esta en funcion del setting 188

	SELECT @setting = valor
	FROM ccSettings
	WHERE setting_id = 188

	IF @setting IS NULL
		SET @setting = 40000
	SET @top = @setting * 100 / @percentage

	INSERT INTO @table
	SELECT TOP (@top) A.grab_id, A.node, A.dateIn, STATUS
	FROM ria_RecNode A WITH (NOLOCK)
	WHERE A.STATUS IN (1, 3)
	ORDER BY grab_id

	INSERT INTO @tableNotExists
	SELECT A.grabId
	FROM @table A
	LEFT JOIN RIA_RecNodeHistory B WITH (NOLOCK) ON B.grab_id = A.grabId
	WHERE B.grab_id IS NULL

	INSERT INTO RIA_RecNodeHistory (grab_id, node, dateIn, dateOut, STATUS)
	SELECT A.grabId, A.node, A.dateIn, getdate(), A.STATUS
	FROM @table A
	INNER JOIN @tableNotExists B ON A.grabId = B.grabId

	DELETE
	FROM ria_RecNode
	WHERE grab_id IN (
			SELECT grabId
			FROM @table
			)
END