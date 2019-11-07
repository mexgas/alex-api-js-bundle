CREATE PROCEDURE [dbo].[ccspRepInDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInDispositions WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInDispositions
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + ':00', 121), Inbound_id, '' AS ACDGroup, dispositionId, '' AS DispName, '', count(dispositionId) DispAmount, user_id, '' AS LOGIN, '' AS username, IDArea, '' AS areaName, 1 AS wgId, 'systemTranslated_WorkGroup' AS wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)), datepart(dd, max(dateHour)), datepart(hh, max(dateHour)), 0
	FROM (
		SELECT a.cal_inicio AS dateHour, a.Inbound_id, a.calif_id AS dispositionId, user_id, b.IDArea
		FROM cccallsin a
		LEFT JOIN ccInbound b ON b.Inbound_id = a.Inbound_id
		WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 --Constestada
			AND b.IDArea IS NOT NULL
		
		UNION
		
		SELECT requestDate, a.inboundId, a.disposition, a.userId, b.IDArea
		FROM ccRIAChats a
		LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
		WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
			AND b.IDArea IS NOT NULL
		) AS x
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + ':00', 121), Inbound_id, dispositionId, user_id, IDArea

	UPDATE a
	SET acdGroup = isnull(descripcion, '')
	FROM RepInDispositions a
	LEFT JOIN ccInbound b ON a.inboundId = b.Inbound_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET disposition = isnull(description, 'systemTranslated_Dispositionless'), disposition_count = isnull(description, 'systemTranslated_Dispositionless') + '_Count'
	FROM RepInDispositions a
	LEFT JOIN cctipocalif b ON a.dispositionId = b.calif_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET [user] = isnull(LOGIN, '')
	FROM RepInDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET agentName = isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, '')
	FROM RepInDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET area = isnull(AreaName, '')
	FROM RepInDispositions a
	LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
	WHERE [date] >= @from AND [date] < @to
END