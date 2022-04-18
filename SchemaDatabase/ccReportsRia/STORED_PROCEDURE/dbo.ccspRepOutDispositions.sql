CREATE PROCEDURE [dbo].[ccspRepOutDispositions] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepOutDispositions
	WHERE DATE >= @from
		AND DATE < @to;

	WITH detailWorkGroup
	AS (
		SELECT min(IDWG) IDWG
			,IdCampEsp
			,min(WGName) WGName
		FROM ccRIACampEspWGView
		WHERE Tipo = 1
		GROUP BY IdCampEsp
		)
		,callOut
	AS (
		SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + ':00', 121) AS DATE
			,a.cam_id
			,a.calif_id
			,count(calif_id) DispAmount
			,user_id
		FROM ccocallsout a
		WHERE cal_inicio >= @from
			AND cal_inicio < @to
			AND a.statuscall_id = 13
			AND cal_manual IN (0, 2)
		GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + ':00', 121)
			,a.cam_id
			,a.calif_id
			,user_id
		)

	insert into RepOutDispositions
	SELECT A.DATE
		,a.cam_id campaignId
		,ISNULL(b.cam_descripcion, '') AS Campaign
		,a.calif_id dispositionId
		,isnull(c.Description, 'systemTranslated_Dispositionless') AS disposition
		,isnull(c.Description, 'systemTranslated_Dispositionless') + '_Count' AS disposition_count
		,a.DispAmount AS [count]
		,A.user_id userId
		,ISNULL(d.LOGIN, '') [agentName]
		,isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, '') AS username
		,isnull(b.IDArea, 0) AS areaId
		,isnull(e.AreaName, '') AS area
		,isnull(wg.IDWG, 0) AS workgroupId
		,isnull(wg.WGName, '-') AS wg
		,datepart(yyyy, DATE) AS year
		,datepart(mm, DATE) AS mounth
		,datepart(dd, DATE) AS day
		,datepart(hh, DATE) AS hour
		,datepart(mi, DATE) AS min
	FROM callOut A
	LEFT JOIN cccamps b ON a.cam_id = b.cam_id
	LEFT JOIN cctipocalifout c ON A.calif_id = c.calif_id
	LEFT JOIN ccUserView d ON a.User_id = d.User_id
	LEFT JOIN ccRIACat_Areas e ON b.IDArea = e.IDArea
	LEFT JOIN detailWorkGroup wg ON wg.IdCampEsp = A.cam_id
END