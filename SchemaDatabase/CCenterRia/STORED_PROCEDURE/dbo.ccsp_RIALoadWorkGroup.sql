CREATE PROCEDURE [dbo].[ccsp_RIALoadWorkGroup] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @CamEspId SMALLINT, @InOut TINYINT
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todos los WG
BEGIN
	-- Agentes y Supervisores
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a4.User_id AS ID, CASE TipoUser_id WHEN 1 THEN 'A' WHEN 2 THEN 'S' WHEN 6 THEN 'S' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIAWorkGroupUsers a3 ON a1.IDWG = a3.IDWG
	JOIN ccUsers a4 ON a3.User_id = a4.User_id
	
	UNION
	
	-- Campañas/acds
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a3.IdCampEsp AS ID, CASE Tipo WHEN 0 THEN 'I' WHEN 1 THEN 'C' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIACampEspWG a3 ON a1.IDWG = a3.IDWG
	ORDER BY 1, 2, 5, 4

	RETURN (0)
END

IF @option = 2 -- WG de un Area
BEGIN
	-- Agentes y Supervisores
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a4.User_id AS ID, CASE TipoUser_id WHEN 1 THEN 'A' WHEN 2 THEN 'S' WHEN 6 THEN 'S' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIAWorkGroupUsers a3 ON a1.IDWG = a3.IDWG
	JOIN ccUsers a4 ON (a3.User_id = a4.User_id)
	WHERE a2.IDArea = @AreaId
	
	UNION
	
	-- Campañas
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a3.IdCampEsp AS ID, CASE Tipo WHEN 0 THEN 'I' WHEN 1 THEN 'C' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIACampEspWG a3 ON a1.IDWG = a3.IDWG
	WHERE a2.IDArea = @AreaId
	ORDER BY 1, 2, 5, 4

	RETURN (0)
END

IF @option = 3 -- WG por Supervisor
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones
		-- Agentes y Supervisores

	SELECT DISTINCT a2.IDArea, a1.IDWG, a1.WGName, a4.User_id AS ID, CASE TipoUser_id WHEN 1 THEN 'A' WHEN 2 THEN 'S' WHEN 6 THEN 'S' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIAWorkGroupUsers a3 ON a1.IDWG = a3.IDWG
	JOIN ccUsers a4 ON a3.User_id = a4.User_id AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
	JOIN ccRIAWorkGroupUsers a5 ON a1.IDWG = a5.IDWG
	WHERE a5.User_id = @sup
	
	UNION
	
	-- Campañas y Especialidades
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a3.IdCampEsp AS ID, CASE Tipo WHEN 0 THEN 'I' WHEN 1 THEN 'C' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIACampEspWG a3 ON a1.IDWG = a3.IDWG
	JOIN ccRIAWorkGroupUsers a4 ON a1.IDWG = a4.IDWG
	WHERE a4.User_id = @sup
	ORDER BY 1, 2, 5, 4

	RETURN (0)
END

IF @option = 4 -- Datos Agents y Sups por WG de un area 
BEGIN
	SELECT a.IDWG, a.WGName, isnull(d.TipoUser_id, '') TipoUser_id, isnull(d.user_id, '') user_id, isnull(d.LOGIN, '') LOGIN, isnull(d.TipoLlamadas, '') TipoLlamadas, isnull(d.Nombres, '') + ' ' + isnull(d.ApellidoPaterno, '') + ' ' + isnull(d.ApellidoMaterno, '') AS nombre, isnull(d.sexo, '') sexo, dbo.fn_CampEspWG(a.IDWG, 0) nAcd, dbo.fn_CampEspWG(a.IDWG, 1) nCamp
	FROM ccRIACat_WorkGroup a
	JOIN ccRIAAreaWorkGroup b ON b.IDWG = a.IDWG
	LEFT JOIN ccRIAWorkGroupUsers c ON c.IDWG = a.IDWG
	LEFT JOIN ccUsers d ON d.User_id = c.User_id
	WHERE b.IDArea = @AreaID
	ORDER BY a.WGName, a.IDWG, d.TipoUser_id, d.user_id

	RETURN (0)
END

IF @option IN (5, 7)
BEGIN
	CREATE TABLE #WGPriority (IDWG SMALLINT, WGName VARCHAR(50), TipoUser_id INT, User_id SMALLINT, LOGIN VARCHAR(20), TipoLlamadas TINYINT, nombre VARCHAR(117), sexo BIT, prioridad TINYINT, WGPriority TINYINT, rel_id INT NULL)

	IF @InOut = 1
	BEGIN
		INSERT INTO #WGPriority (IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		SELECT DISTINCT a.IDWG, d.WGName, c.TipoUser_id, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + ' ' + c.ApellidoPaterno + ' ' + c.ApellidoMaterno AS nombre, c.sexo, e.prioridad, a.priority AS WGPriority, e.rel_id relation_id
		FROM ccRIACampEspWg a
		JOIN ccRIAWorkGroupUsers b ON a.IDWG = b.IDWG
		JOIN ccUsers c ON b.User_id = c.User_id
		JOIN cccampsagente e ON c.User_id = e.User_id AND e.cam_id = @CamEspId AND a.IDWG = e.IDWG
		JOIN ccRIACat_WorkGroup d ON d.IDWG = a.IDWG
		WHERE a.IdCampEsp = @CamEspId AND a.tipo = 1 AND c.tipouser_id = 1
		ORDER BY 1, 2, 3

		INSERT INTO #WGPriority (IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		SELECT DISTINCT a.IDWG, d.WGName, 2, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + ' ' + c.ApellidoPaterno + ' ' + c.ApellidoMaterno AS nombre, c.sexo, 0, a.priority AS WGPriority, 0
		FROM ccRIACampEspWg a
		JOIN ccRIAWorkGroupUsers b ON a.IDWG = b.IDWG
		JOIN ccUsers c ON b.User_id = c.User_id
		JOIN ccsupervisorcam e ON c.User_id = e.User_id AND e.cam_id = @CamEspId AND a.IDWG = e.IDWG
		JOIN ccRIACat_WorkGroup d ON d.IDWG = a.IDWG
		WHERE a.IdCampEsp = @CamEspId AND a.tipo = 1 AND c.tipouser_id IN (2, 6) AND e.tipo = @InOut
		ORDER BY 1, 2, 3
	END
	ELSE
	BEGIN
		INSERT INTO #WGPriority (IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority)
		SELECT DISTINCT a.IDWG, d.WGName, c.TipoUser_id, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + ' ' + c.ApellidoPaterno + ' ' + c.ApellidoMaterno AS nombre, c.sexo, e.prioridad, a.priority AS WGPriority
		FROM ccRIACampEspWg a
		JOIN ccRIAWorkGroupUsers b ON a.IDWG = b.IDWG
		JOIN ccUsers c ON b.User_id = c.User_id
		JOIN ccInboundAgentes e ON c.User_id = e.User_id AND e.Inbound_id = @CamEspId AND a.IDWG = e.IDWG
		JOIN ccRIACat_WorkGroup d ON d.IDWG = a.IDWG
		WHERE a.IdCampEsp = @CamEspId AND tipo = 0
		ORDER BY 1, 2, 3

		INSERT INTO #WGPriority (IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		SELECT DISTINCT a.IDWG, d.WGName, 2, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + ' ' + c.ApellidoPaterno + ' ' + c.ApellidoMaterno AS nombre, c.sexo, 0, a.priority AS WGPriority, 0
		FROM ccRIACampEspWg a
		JOIN ccRIAWorkGroupUsers b ON a.IDWG = b.IDWG
		JOIN ccUsers c ON b.User_id = c.User_id
		JOIN ccsupervisorcam e ON c.User_id = e.User_id AND e.cam_id = @CamEspId AND a.IDWG = e.IDWG
		JOIN ccRIACat_WorkGroup d ON d.IDWG = a.IDWG
		WHERE a.IdCampEsp = @CamEspId AND a.tipo = 0 AND c.tipouser_id IN (2, 6) AND e.tipo = @InOut
		ORDER BY 1, 2, 3
	END

	UPDATE #WGPriority
	SET WGPriority = 0
	WHERE IDWG IN (
			SELECT IDWG
			FROM (
				SELECT IDWG, count(DISTINCT prioridad) prioridad
				FROM #WGPriority
				GROUP BY IDWG, prioridad
				) AS x
			GROUP BY IDWG, prioridad
			HAVING count(prioridad) > 1
			)

	IF @option = 5
	BEGIN
		SELECT IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, min(rel_id) relational_id
		FROM #WGPriority
		GROUP BY IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority
	END

	IF @option = 7
	BEGIN
		SELECT 1 AS tag, NULL parent, 0 "WorkGroup!1!TipoUser_id", IDWG "WorkGroup!1!id", WGName "WorkGroup!1!description", WGPriority "WorkGroup!1!priority", NULL "Agent!3!id", NULL "Agent!3!login", NULL "Agent!3!callType", NULL "Agent!3!name", NULL "Agent!3!gender", NULL "Agent!3!priority", NULL "Agent!3!relational_id", NULL "Supervisor!2!id", NULL "Supervisor!2!login", NULL "Supervisor!2!callType", NULL "Supervisor!2!name", NULL "Supervisor!2!gender", NULL "Supervisor!2!priority", NULL "Supervisor!2!relational_id"
		FROM (
			SELECT IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
			FROM #WGPriority
			) AS WGPriority
		GROUP BY IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority
		
		UNION
		
		SELECT 2 AS tag, 1 parent, TipoUser_id, IDWG, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, min(rel_id) relational_id
		FROM (
			SELECT IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
			FROM #WGPriority
			WHERE TipoUser_id = 2
			) AS WGPriority
		GROUP BY IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority
		
		UNION
		
		SELECT 3 AS tag, 1 parent, TipoUser_id, IDWG, NULL, NULL, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, min(rel_id) relational_id, NULL, NULL, NULL, NULL, NULL, NULL, NULL
		FROM (
			SELECT IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
			FROM #WGPriority
			WHERE TipoUser_id = 1
			) AS WGPriority
		GROUP BY IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority
		ORDER BY "WorkGroup!1!id", tag, "WorkGroup!1!TipoUser_id" DESC, "Supervisor!2!name", "Agent!3!name"
		FOR XML explicit, type
	END

	RETURN (0)
END

IF @option = 6
BEGIN
	SELECT W.Tipo, I.Inbound_id IdCampEsp, I.descripcion
	FROM ccInbound I
	JOIN ccRIACampEspWG W ON I.Inbound_id = W.IdCampEsp AND W.IDWG = isnull(@AreaId, W.IDWG) AND W.Tipo = 0
	
	UNION
	
	SELECT W.Tipo, C.cam_id, C.cam_descripcion
	FROM ccCamps C
	JOIN ccRIACampEspWG W ON C.cam_id = W.IdCampEsp AND W.IDWG = isnull(@AreaId, W.IDWG) AND W.Tipo = 1
	ORDER BY W.Tipo DESC, 2

	RETURN (0)
END

IF @option = 8
BEGIN
	SELECT isnull(viewMode.typeView, 0) typeView
	FROM ccMenu_Views AS viewMode
	JOIN ccMenu_Views AS [view] ON viewMode.mView_id = [view].mView_id
	WHERE viewMode.STATUS = 1 AND [view].menu_id = 4 AND (CASE WHEN viewMode.typeView = dbo.fn_viewMode(@Sup, [view].menu_id) THEN 1 ELSE 0 END) = 1

	RETURN (0)
END

IF @option = 9
BEGIN
	DECLARE @assignACDCamp AS TINYINT

	SELECT @assignACDCamp = isnull(per_id, 0)
	FROM ccRIAUsr_AdminPermissions
	WHERE per_id = 3 AND user_id = @Sup

	SELECT CASE WHEN @assignACDCamp > 0 THEN 1 ELSE 0 END AS granted

	RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF