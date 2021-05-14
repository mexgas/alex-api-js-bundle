CREATE PROCEDURE [dbo].[ccspRepOutSubDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepOutSubDispositions WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepOutSubDispositions
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + ':00', 121) AS dateHour, a.cam_id, '' AS Campaign, 
	isnull(a.calif_id, 0), '' AS DispName, '', count(calif_id) DispAmount, user_id, '' AS LOGIN, '' AS username, b.IDArea, '' AS areaName, 1 AS wgId, 'systemTranslated_WorkGroup' AS wg, datepart(yyyy, max(cal_inicio)) AS year,
	datepart(mm, max(cal_inicio)), datepart(dd, max(cal_inicio)), datepart(hh, max(cal_inicio)), datepart(mi, max(cal_inicio))
	FROM ccocallsout a(NOLOCK)
	LEFT JOIN ccCamps b ON b.cam_Id = a.cam_id
	WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 AND cal_manual IN (0, 2) AND b.IDArea IS NOT NULL
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + ':00', 121), a.cam_id, a.calif_id, user_id, b.IDArea

	UPDATE a
	SET campaign = isnull(cam_descripcion, '')
	FROM RepOutSubDispositions a
	LEFT JOIN ccCamps b ON a.campaignId = b.cam_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET subDisposition = isnull(Description, 'systemTranslated_Dispositionless'), subDisposition_count = isnull(Description, 'systemTranslated_Dispositionless') + '_Count'
	FROM RepOutSubDispositions a
	LEFT JOIN cctipocalifout b ON a.subDispositionId = b.calif_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET [user] = isnull(LOGIN, '')
	FROM RepOutSubDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET agentName = isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, '')
	FROM RepOutSubDispositions a
	LEFT JOIN ccUserView b ON a.userId = b.user_id
	WHERE [date] >= @from AND [date] < @to

	UPDATE a
	SET area = isnull(AreaName, '')
	FROM RepOutSubDispositions a
	LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
	WHERE [date] >= @from AND [date] < @to
END