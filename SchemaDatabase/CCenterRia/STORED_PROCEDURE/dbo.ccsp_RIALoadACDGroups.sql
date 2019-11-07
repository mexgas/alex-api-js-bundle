CREATE PROCEDURE [dbo].[ccsp_RIALoadACDGroups] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @inbound_id INT = 0, @tipoModalidad TINYINT = 0 -- llamada 0, chat 1 y ambos 2
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todas los ACDGroups
BEGIN
	SELECT a1.inbound_id, descripcion, frame, isnull(IDArea, 0)
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON (a1.inbound_id = a2.inbound_id)
	JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	WHERE a3.type_id = 1
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 2 -- ACDGroups de un Area
BEGIN
	SELECT DISTINCT a1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.inbound_id, 2) relationsWG, a1.chat mode, skillDif
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	INNER JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	LEFT JOIN (
		SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
		FROM ccSkills
		GROUP BY inbound_id
		) S ON S.Inbound_id = a1.inbound_id
	WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 3 -- ACDGroups por Supervisor
BEGIN
	SELECT DISTINCT a1.inbound_id, descripcion, frame, isnull(IDArea, 0) AS IDArea, U.monitored, a1.chat mode
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccSupervisorCam U ON a1.inbound_id = U.cam_id
	WHERE U.user_id = @sup AND tipo = 0 AND a3.type_id = 1 AND a1.inbound_id IN (
			SELECT cam_id
			FROM dbo.fGet_CampAcd_Area(@Sup, 2)
			)
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 4 -- Rels ACD-Agents
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT inbound_id, descripcion, User_id, LOGIN, skill, prioridad, IDArea, min(rel_id) rel_id
	FROM (
		SELECT E.inbound_id, E.descripcion, A.User_id, A.LOGIN, G.skill, G.prioridad, isnull(E.IDArea, 0) IDArea, G.rel_id
		FROM ccinboundAgentes G
		JOIN ccinbound E ON G.inbound_id = E.inbound_id
		JOIN ccUsers A ON A.User_id = G.User_id AND A.TipoUser_Id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
		WHERE E.inbound_id IN (
				SELECT cam_id
				FROM ccsupervisorcam
				WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 0
				)
		) AS Relations
	GROUP BY inbound_id, descripcion, User_id, LOGIN, skill, prioridad, IDArea
	ORDER BY User_id, inbound_id, descripcion, prioridad

	RETURN (0)
END

IF @option = 5 -- Todos los ACDGroups
BEGIN
	option5:

	SELECT a1.inbound_id, descripcion, frame, isnull(IDArea, 0)
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 7 -- Un solo ACDGroups
BEGIN
	SELECT a1.inbound_id, descripcion, frame, isnull(IDArea, 0)
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1 AND STATUS = 1 AND a1.inbound_id = @inbound_id
	ORDER BY descripcion

	RETURN (0)
END

IF @option = 8 -- ACDGroups de un Agente
BEGIN
	SELECT DISTINCT a1.inbound_id, a1.descripcion, a3.frame
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccInboundAgentes a4 ON a1.inbound_id = a4.inbound_id
	WHERE a3.type_id = 1 AND a4.user_id = @Sup
	ORDER BY 2

	RETURN (0)
END

IF @option = 9 -- ACDGroups por Supervisor para mensajes llamadas o chat filtra las campaÃ±as
BEGIN
	SELECT DISTINCT a1.inbound_id, descripcion, frame, isnull(IDArea, 0) AS IDArea, U.monitored
	FROM ccinbound a1
	JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccSupervisorCam U ON a1.inbound_id = U.cam_id
	WHERE U.user_id = @sup AND tipo = 0 AND a3.type_id = 1 AND a1.inbound_id IN (
			SELECT cam_id
			FROM dbo.fGet_CampAcd_Area(@Sup, 2)
			) AND a1.chat IN (2, @tipoModalidad)
	ORDER BY descripcion

	RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF