CREATE PROCEDURE [dbo].[ccspRepInDispositions] 
@action AS TINYINT, 
@from AS DATETIME = NULL, 
@to AS DATETIME = NULL
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
	SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + ':00', 121), Inbound_id, ACDGroup, dispositionId, DispName, disposition_count, count(dispositionId) DispAmount, User_id, LOGIN, username, IDArea, areaName, IDWG AS wgId, wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)) AS mes, datepart(dd, max(dateHour)) AS dia, datepart(hh, max(dateHour)), 0
	FROM (
		SELECT a.cal_inicio AS dateHour, a.Inbound_id, isnull(b.descripcion, '') as ACDGroup, a.calif_id AS dispositionId, DispName = isnull(description, 'systemTranslated_Dispositionless'), disposition_count = isnull(description, 'systemTranslated_Dispositionless') + '_Count', a.User_id, LOGIN = isnull(LOGIN, ''), username = isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, ''), b.IDArea, isnull(AreaName, '') AS areaName, c.IDWG, isnull(c.WGName,'systemTranslated_WorkGroup') AS wg
		FROM cccallsin a
		INNER JOIN ccWgByAcdView b ON a.Inbound_id=b.Inbound_id
		LEFT JOIN ccRIACat_WorkGroup c ON c.IDWG=b.IDWG
		--INNER JOIN ccRIACampEspWG c ON b.Inbound_id=c.IdCampEsp
		LEFT JOIN cctipocalif tc ON a.calif_id = tc.calif_id
		LEFT JOIN ccUserView d ON a.User_id = d.user_id
		LEFT JOIN ccRIACat_Areas e ON b.IdArea = e.IDArea
		WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 --Constestada
			AND b.IDArea IS NOT NULL
		
		UNION

		SELECT requestDate, a.inboundId, isnull(b.descripcion, '') as ACDGroup, a.disposition, DispName = isnull(description, 'systemTranslated_Dispositionless'), disposition_count = isnull(description, 'systemTranslated_Dispositionless') + '_Count', a.userId, LOGIN = isnull(LOGIN, ''), username = isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno, ''), b.IDArea, isnull(AreaName, '') AS areaName, b.IDWG, isnull(c.WGName,'systemTranslated_WorkGroup') AS wg
		FROM ccRIAChats a
		--LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
		INNER JOIN ccWgByAcdView b ON a.inboundId=b.Inbound_id
		LEFT JOIN ccRIACat_WorkGroup c ON c.IDWG=b.IDWG
		--INNER JOIN ccRIACampEspWG c ON b.Inbound_id=c.IdCampEsp
		LEFT JOIN cctipocalif tc ON a.disposition = tc.calif_id
		LEFT JOIN ccUserView d ON a.userId = d.user_id
		LEFT JOIN ccRIACat_Areas e ON b.IdArea = e.IDArea
		WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
			AND b.IDArea IS NOT NULL
		) AS x
	GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + ':00', 121), Inbound_id, ACDGroup, dispositionId,  DispName, disposition_count, user_id, LOGIN, username, IDArea, areaName, IDWG, wg
END