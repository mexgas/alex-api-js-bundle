/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 
		
Date: 2019/01/08
Description:

Database: CCenterRia
Required version: 121.32

Se agrega la tarea
CW-2031
CW-2576

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 32

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 32
BEGIN
	BEGIN TRAN

	BEGIN TRY

		
		SET @process = 'CW-2357 update ccUsers.LastLoginAttempt'
		SET @Sql = 'DECLARE @tempSessionAgent TABLE (userId INT NOT NULL, fecha DATETIME NOT NULL, PRIMARY KEY (userId))
DECLARE @dateLastLogin DATETIME

SET @dateLastLogin = dateadd(dd, - 240, getdate())

INSERT INTO @tempSessionAgent
SELECT User_id, max(fecha)
FROM ccLogLogin
WHERE TipoMov = 1
GROUP BY User_id

UPDATE A
SET LastLoginAttempt = CASE WHEN fCreate > isnull(B.fecha, @dateLastLogin) THEN fCreate ELSE isnull(B.fecha, @dateLastLogin) END
FROM ccUsers A
LEFT JOIN @tempSessionAgent B ON A.User_id = B.userId
WHERE TipoUser_id = 1
'
		EXEC (@Sql)

		SET @process = 'CW-2357 Add Setting '
		SET @Sql = 'IF NOT EXISTS (
		SELECT *
		FROM ccSettings
		WHERE setting_id = 211
		)
BEGIN
	INSERT INTO ccSettings (setting_id, valor, descripcion, STATUS, Tipo, detalle, description, bLoadSettings, validate)
	VALUES (211, ''0'', ''Mostrar agentes en grupo de trabajo con una conexión no mayor a (días)'', 1, ''ADM'', ''0 carga todas las relaciones, mayor a cero valida que el ultimo inicio de sesion por numero de dias'', ''Load the list of agents last login'', 0, ''^[0-1]$'')
END
'
		EXEC (@Sql)

		SET @process = 'CW-2357 ALTER SP ccsp_AgentLogINOUT'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT] @UserID SMALLINT, @Extension VARCHAR(7) = NULL, @Computer VARCHAR(20) = NULL, @TipoMov TINYINT, -- 0= LogOut,  1=LogIN,	3=Consulta
	@fecha DATETIME = NULL
AS
SET NOCOUNT ON

IF @fecha IS NULL
	SET @fecha = getdate()

DECLARE @hourlogin VARCHAR(8)
DECLARE @sessionsecs INT
DECLARE @sessiontime VARCHAR(8)
DECLARE @fecha_ini DATETIME

IF @TipoMov = 1
BEGIN
	INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
	VALUES (@UserID, @Extension, 1, @fecha)

	INSERT ccLogAgentesDia (User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callID)
	VALUES (@UserID, 0, 0, @fecha, 0, 0, 1, 0)

	UPDATE c
	SET User_id = @UserID
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion))
	WHERE Computer = @Computer

	UPDATE c
	SET user_id = 0
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
	WHERE Computer <> @Computer AND user_id = @UserId

	UPDATE ccUsers
	SET TipoStatusAge_id = 3, LastLoginAttempt = @fecha
	WHERE User_id = @UserID

	IF EXISTS (
			SELECT valor
			FROM ccSettings
			WHERE tipo = ''AGT'' AND STATUS = ''1'' AND setting_id = ''53'' AND valor = 2
			)
	BEGIN
		IF NOT EXISTS (
				SELECT axLic_Desc
				FROM axLicG729_Data
				WHERE axLic_Status = 1 AND pos_id IN (
						SELECT pos_id
						FROM ccPosicion
						WHERE Computer = @Computer OR user_id = @Userid
						)
				)
		BEGIN
			RAISERROR (''Error. Without License'', 18, 1)

			RETURN (0)
		END

		UPDATE axLicG729_Data
		SET axLic_Status = 2
		WHERE axLic_Status = 1 AND pos_id IN (
				SELECT pos_id
				FROM ccPosicion
				WHERE Computer = @Computer OR user_id = @Userid
				)

		SELECT ''0'' CPLic

		RETURN (0)
	END

	RETURN (0)
END

IF @TipoMov = 0
BEGIN
	INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
	VALUES (@UserID, @Extension, 0, @fecha)

	UPDATE c
	SET User_id = 0
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
	WHERE Computer = @Computer OR user_id = @Userid

	UPDATE ccUsers
	SET TipoStatusAge_id = 0
	WHERE User_id = @UserID

	IF EXISTS (
			SELECT valor
			FROM ccSettings
			WHERE tipo = ''AGT'' AND STATUS = ''1'' AND setting_id = 53 AND valor = ''2''
			)
	BEGIN
		UPDATE axLicG729_Data
		SET axLic_Status = 0, pos_id = NULL, fecha_log = NULL
		WHERE pos_id IN (
				SELECT pos_id
				FROM ccPosicion
				WHERE Computer = @Computer OR user_id = @Userid
				)
	END

	RETURN (0)
END

IF @TipoMov = 3
BEGIN
	SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(11), getdate()))

	SELECT @hourlogin = convert(VARCHAR(8), isnull(min(fecha), getdate()), 114)
	FROM ccLogLogin
	WHERE TipoMov = 1 AND user_id = @UserID AND fecha >= @fecha_ini

	SELECT @sessionsecs = isnull(CASE WHEN sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) > 0 THEN sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) ELSE sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) + convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14))) END, 0)
	FROM ccLogLogin
	WHERE user_id = @UserID AND fecha > dateadd(hh, - 10, getdate())

	SELECT @sessiontime = RIGHT(''0'' + CONVERT(VARCHAR(6), @sessionsecs / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (@sessionsecs % 3600) / 60), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), @sessionsecs % 60), 2)

	SELECT ''HourLogin'' = @hourlogin, ''SessionTime'' = @sessiontime, ''SessionSecs'' = @sessionsecs

	RETURN (0)
END
'
		EXEC (@Sql)
		
		SET @process = 'CW-2357 ALTER SP ccsp_RIALoadACDGroups'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIALoadACDGroups] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @inbound_id INT = 0, @tipoModalidad TINYINT = 0 -- llamada 0, chat 1 y ambos 2
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
'
		EXEC (@Sql)
		
		SET @process = 'CW-2357 ALTER SP ccsp_RIALoadAgents'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIALoadAgents] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @UserType SMALLINT, @IDWG SMALLINT = NULL, @IDCampACD VARCHAR(max) = NULL
AS
SET NOCOUNT ON

DECLARE @IDArea INT
DECLARE @loginDays INT

SET @loginDays = 0

IF @option IN (1, 7) --1:Todos los agentes/supervisores | 7:UN solo agente/supervisor
BEGIN
	SELECT User_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
	FROM ccUsers WITH (READPAST)
	WHERE TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS > 0 AND user_id = CASE @option WHEN 7 THEN isnull(@sup, user_id) ELSE user_id END
	ORDER BY IDArea, Nombres, ApellidoPaterno, User_id

	RETURN (0)
END

IF @option = 2 --Agentes/supervisores de un Area
BEGIN
	SELECT User_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
	FROM ccusers
	WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
	ORDER BY Sexo, Nombres, ApellidoPaterno, User_id

	RETURN (0)
END

IF @option = 3 --Agentes por Supervisor
BEGIN
	SELECT a3.user_id, a3.LOGIN, a3.TipoLlamadas, a3.Nombres + isnull('' '' + a3.ApellidoPaterno, '''') + isnull('' '' + a3.ApellidoMaterno, '''') name, isnull(a3.IDArea, 0) IDArea, a3.Sexo
	FROM ccsupervisorcam a1
	JOIN cccampsagente a2 ON a1.cam_id = a2.cam_id
	JOIN ccusers a3 ON a2.user_id = a3.user_id
	WHERE a1.tipo = ''1'' AND a1.user_id = @Sup AND a3.TipoUser_id = 1 AND a3.STATUS > 0
	
	UNION
	
	SELECT a3.user_id, a3.LOGIN, a3.TipoLlamadas, a3.Nombres + isnull('' '' + a3.ApellidoPaterno, '''') + isnull('' '' + a3.ApellidoMaterno, '''') name, isnull(a3.IDArea, 0) IDArea, a3.Sexo
	FROM ccsupervisorcam a1
	JOIN ccInboundagentes a2 ON a1.cam_id = a2.Inbound_id
	JOIN ccusers a3 ON a2.user_id = a3.user_id
	WHERE a1.tipo = ''0'' AND a1.user_id = @Sup AND a3.TipoUser_id = 1 AND a3.STATUS > 0
	ORDER BY 5, 4, 1

	RETURN (0)
END

IF @option = 4 --Load All Supervisors
BEGIN
	SELECT User_id, LOGIN, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name
	FROM ccUsers
	WHERE TipoUser_id IN (2, 6) AND STATUS > 0

	RETURN (0)
END

IF @option = 5 --Agentes por Supervisor de sus WG
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT @IDArea = IDArea
	FROM ccUsers
	WHERE User_id = @Sup

	SELECT User_id, LOGIN, TipoLlamadas, max(name) name, IDArea, Sexo, IP, sum(sumMultimedia) sumMultimedia
	FROM (
		SELECT DISTINCT A.User_id, A.LOGIN, a.TipoLLamadas, A.Nombres + isnull('' '' + A.ApellidoPaterno, '''') + isnull('' '' + A.ApellidoMaterno, '''') name, isnull(A.IDArea, 0) IDArea, A.Sexo, isnull(C.IP, ''0.0.0.0'') IP, (CASE isnull(E.chat, 0) WHEN 3 THEN POWER(2, 0) WHEN 4 THEN POWER(2, 1) ELSE 0 END) AS sumMultimedia --, E.chat mode,E.Inbound_id
		FROM ccUsers A
		INNER JOIN ccRIAWorkGroupUsers B ON A.User_id = B.User_id
		LEFT JOIN ccPosicion C ON C.user_id = A.User_id
		INNER JOIN ccRIACampEspWG D ON D.IDWG = B.IDWG
		LEFT JOIN ccInbound E ON D.IdCampEsp = E.Inbound_id AND E.IDArea = @IDArea
		WHERE A.TipoUser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays) AND B.IDWG IN (
				SELECT IDWG
				FROM ccRIAWorkGroupUsers
				WHERE user_id = @Sup
				)
		) x
	GROUP BY user_id, LOGIN, TipoLlamadas, IDArea, Sexo, IP

	RETURN (0)
END

IF @option = 6 --Agentes por Supervisor de sus WG
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.TipoLlamadas, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	FROM ccusers a1
	JOIN ccRIAWorkGroupUsers a2 ON a1.user_id = a2.user_id
	WHERE tipouser_id IN (2, 6) AND IDWG IN (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers
			WHERE user_id = @Sup
			)

	RETURN (0)
END

IF @option IN (8, 9) --8:Agentes de un WG | 9:Supervisores de un WG
BEGIN
	DECLARE @wgUsers AS VARCHAR(500)

	SELECT @wgUsers = coalesce(@wgUsers + '','', '''') + CAST(A.user_id AS VARCHAR(40))
	FROM ccRIAWorkGroupUsers A
	JOIN ccUsers B ON A.user_id = B.user_id
	WHERE IDWG = @IDWG AND TipoUser_id = CASE @option WHEN 8 THEN 1 ELSE 2 END

	SELECT @wgUsers wgUsers

	RETURN (0)
END

IF @option = 10 --Todos los agentes/supervisores
BEGIN
	SELECT User_id, LOGIN, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
	FROM ccUsers WITH (READPAST)
	WHERE TipoUser_id IN (/*2,*/ 6) AND STATUS > 0
	ORDER BY LOGIN, IDArea, Nombres, ApellidoPaterno, User_id

	RETURN (0)
END

IF @option = 11 -- Agentes por ACD
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	FROM ccusers a1
	JOIN ccInboundAgentes a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id = 1 AND a2.Inbound_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

IF @option = 12 -- Agentes por Camp
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	FROM ccusers a1
	JOIN ccCampsAgente a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id = 1 AND a2.cam_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

IF @option = 13 -- Sups por ACD
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	FROM ccusers a1
	JOIN ccSupervisorCam a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id & 2 = 2 AND tipo = 0 AND a2.cam_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

IF @option = 14 -- Sups por Camp
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	FROM ccusers a1
	JOIN ccSupervisorCam a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id & 2 = 2 AND tipo = 1 AND a2.cam_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

DECLARE @sxML AS VARCHAR(max), @xml AS XML, @action AS INT

IF @option = 15 -- Info Agentes
BEGIN
	SET @action = @option - 9
	SET @xml = cast(''<?xml version="1.0"?> <AgentData/>'' AS XML)

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, User_id "Agent!1!id", LOGIN "Agent!1!login", Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') "Agent!1!name", Sexo "Agent!1!gender", isnull(IDArea, 0) "Agent!1!areaID"
					FROM ccUsers WITH (READPAST)
					WHERE TipoUser_id = 1 AND STATUS > 0 AND user_id = @sup
					) AS x
				ORDER BY tag, "Agent!1!areaID", "Agent!1!name", "Agent!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<AgentData/>'')

	SET @xml.modify(''insert element Workgroups {""} as last into (/AgentData/Agent)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
					FROM ccRIACat_WorkGroup W
					JOIN ccRIAWorkGroupUsers U ON W.IDWG = U.IDWG
					WHERE user_id = @sup
					) AS x
				ORDER BY tag, "Workgroup!1!description"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	SET @xml.modify(''insert element Campaigns {""} as last into (/AgentData/Agent)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup
					) AS x
				ORDER BY tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	SET @xml.modify(''insert element ACDs {""} as last into (/AgentData/Agent)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
					FROM ccinbound a1
					JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccInboundAgentes a4 ON a1.Inbound_id = a4.Inbound_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup
					) AS x
				ORDER BY tag, "ACD!1!description", "ACD!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

	SET @xml.modify(''insert element action {""} as last into (/AgentData)[1]'')
	SET @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/AgentData/action)[1]'')

	SELECT @xML

	RETURN (0)
END

IF @option = 16 -- Info Sups
BEGIN
	SET @action = @option - 9
	SET @xml = cast(''<?xml version="1.0"?> <SuperData/>'' AS XML)

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, User_id "Super!1!id", LOGIN "Super!1!login", Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') "Super!1!name", Sexo "Super!1!gender", isnull(IDArea, 0) "Super!1!areaID"
					FROM ccUsers WITH (READPAST)
					WHERE TipoUser_id & 2 = 2 AND STATUS > 0 AND user_id = @sup
					) AS x
				ORDER BY tag, "Super!1!areaID", "Super!1!name", "Super!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<SuperData/>'')

	SET @xml.modify(''insert element Workgroups {""} as last into (/SuperData/Super)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
					FROM ccRIACat_WorkGroup W
					JOIN ccRIAWorkGroupUsers U ON W.IDWG = U.IDWG
					WHERE user_id = @sup
					) AS x
				ORDER BY tag, "Workgroup!1!description"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	SET @xml.modify(''insert element Campaigns {""} as last into (/SuperData/Super)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup AND a4.tipo = 1
					) AS x
				ORDER BY tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	SET @xml.modify(''insert element ACDs {""} as last into (/SuperData/Super)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
					FROM ccinbound a1
					JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccSupervisorCam a4 ON a1.inbound_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup AND a4.tipo = 0
					) AS x
				ORDER BY tag, "ACD!1!description", "ACD!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

	SET @xml.modify(''insert element action {""} as last into (/SuperData)[1]'')
	SET @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/SuperData/action)[1]'')

	SELECT @xML

	RETURN (0)
END

IF @option = 17 -- Load all agents
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT DISTINCT user_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo, ''0.0.0.0'' IP, 0 AS flagMine
	INTO #allAgents
	FROM ccusers
	WHERE tipouser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)

	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.TipoLlamadas, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, isnull(a1.IDArea, 0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
	INTO #myAgents
	FROM ccusers a1
	JOIN ccRIAWorkGroupUsers a2 ON a1.user_id = a2.user_id
	LEFT JOIN ccPosicion a3 ON a1.user_id = a3.user_id
	JOIN ccRIACampEspWG a4 ON a2.idwg = a4.idwg
	WHERE a1.tipouser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays) AND a2.IDWG IN (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers
			WHERE user_id = @Sup
			)

	UPDATE #allAgents
	SET flagMine = 1
	FROM #allAgents a, #myAgents b
	WHERE a.user_id = b.user_id

	SELECT *
	FROM #allAgents

	DROP TABLE #allAgents

	DROP TABLE #myAgents

	RETURN (0)
END

IF @option = 18 -- View Agents
BEGIN
	SELECT isnull(viewAgents, 0) AS viewAgents
	FROM ccusers
	WHERE tipouser_id = 2 AND user_id = @Sup

	RETURN (0)
END

SET NOCOUNT OFF
'
		EXEC (@Sql)
		
		SET @process = 'CW-2357 ALTER SP ccsp_RIALoadCamps'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todas las campañas
BEGIN
	SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
	FROM ccCamps a1
	JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1 AND a1.cam_id IN (
			SELECT cam_id
			FROM dbo.fGet_CampAcd_Area(@Sup, 1)
			)
	ORDER BY 5, 2

	RETURN (0)
END

IF @option = 2 -- Campañas de un Area
BEGIN
	SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
	FROM ccCamps a1
	JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
	ORDER BY cam_descripcion

	RETURN (0)
END

IF @option = 3 -- Campañas por Supervisor
BEGIN
	SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
	FROM ccCamps a1
	JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
	WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
	ORDER BY 5, 2

	RETURN (0)
END

IF @option = 4 -- Rels Camps-Agents
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
	FROM (
		SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
		FROM ccCamps C
		JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
		JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
		JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
		JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
		WHERE C.cam_id IN (
				SELECT cam_id
				FROM ccsupervisorcam
				WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
				)
		) Relations
	GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
	ORDER BY User_id, cam_descripcion, cam_id, Prioridad

	RETURN (0)
END

IF @option = 5 -- Campañas por Supervisor
BEGIN
	SELECT @AreaId = IDArea
	FROM ccUsers
	WHERE User_id = @sup

	SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, ''12345NNN'') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
	FROM ccCamps Camps
	LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
	LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
	JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
	JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
	WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
			SELECT cam_id
			FROM ccSupervisorCam
			WHERE tipo = 1 AND user_id = @sup
			) AND Camps.IDArea = @AreaId
	ORDER BY 5, cam_procesando DESC, cam_descripcion

	RETURN (0)
END

IF @option = 7 -- Una sola
BEGIN
	SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
	FROM ccCamps a1
	JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
	ORDER BY 5, 2

	RETURN (0)
END

IF @option = 8 -- Campañas de un Agente
BEGIN
	SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
	FROM ccCamps a1
	JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
	WHERE a3.type_id = 1 AND a4.user_id = @Sup
	ORDER BY 2

	RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF
'
		EXEC (@Sql)
		
		SET @process = 'CW-2357 ALTER SP ccsp_RIALoadWorkGroup'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIALoadWorkGroup] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @CamEspId SMALLINT, @InOut TINYINT
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todos los WG
BEGIN
	-- Agentes y Supervisores
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a4.User_id AS ID, CASE TipoUser_id WHEN 1 THEN ''A'' WHEN 2 THEN ''S'' WHEN 6 THEN ''S'' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIAWorkGroupUsers a3 ON a1.IDWG = a3.IDWG
	JOIN ccUsers a4 ON a3.User_id = a4.User_id
	
	UNION
	
	-- Campañas/acds
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a3.IdCampEsp AS ID, CASE Tipo WHEN 0 THEN ''I'' WHEN 1 THEN ''C'' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIACampEspWG a3 ON a1.IDWG = a3.IDWG
	ORDER BY 1, 2, 5, 4

	RETURN (0)
END

IF @option = 2 -- WG de un Area
BEGIN
	-- Agentes y Supervisores
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a4.User_id AS ID, CASE TipoUser_id WHEN 1 THEN ''A'' WHEN 2 THEN ''S'' WHEN 6 THEN ''S'' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIAWorkGroupUsers a3 ON a1.IDWG = a3.IDWG
	JOIN ccUsers a4 ON (a3.User_id = a4.User_id)
	WHERE a2.IDArea = @AreaId
	
	UNION
	
	-- Campañas
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a3.IdCampEsp AS ID, CASE Tipo WHEN 0 THEN ''I'' WHEN 1 THEN ''C'' END AS TypeLoad
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

	SELECT DISTINCT a2.IDArea, a1.IDWG, a1.WGName, a4.User_id AS ID, CASE TipoUser_id WHEN 1 THEN ''A'' WHEN 2 THEN ''S'' WHEN 6 THEN ''S'' END AS TypeLoad
	FROM ccRIACat_WorkGroup a1
	JOIN ccRIAAreaWorkGroup a2 ON a1.IDWG = a2.IDWG
	JOIN ccRIAWorkGroupUsers a3 ON a1.IDWG = a3.IDWG
	JOIN ccUsers a4 ON a3.User_id = a4.User_id AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
	JOIN ccRIAWorkGroupUsers a5 ON a1.IDWG = a5.IDWG
	WHERE a5.User_id = @sup
	
	UNION
	
	-- Campañas y Especialidades
	SELECT a2.IDArea, a1.IDWG, a1.WGName, a3.IdCampEsp AS ID, CASE Tipo WHEN 0 THEN ''I'' WHEN 1 THEN ''C'' END AS TypeLoad
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
	SELECT a.IDWG, a.WGName, isnull(d.TipoUser_id, '''') TipoUser_id, isnull(d.user_id, '''') user_id, isnull(d.LOGIN, '''') LOGIN, isnull(d.TipoLlamadas, '''') TipoLlamadas, isnull(d.Nombres, '''') + '' '' + isnull(d.ApellidoPaterno, '''') + '' '' + isnull(d.ApellidoMaterno, '''') AS nombre, isnull(d.sexo, '''') sexo, dbo.fn_CampEspWG(a.IDWG, 0) nAcd, dbo.fn_CampEspWG(a.IDWG, 1) nCamp
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
		SELECT DISTINCT a.IDWG, d.WGName, c.TipoUser_id, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno AS nombre, c.sexo, e.prioridad, a.priority AS WGPriority, e.rel_id relation_id
		FROM ccRIACampEspWg a
		JOIN ccRIAWorkGroupUsers b ON a.IDWG = b.IDWG
		JOIN ccUsers c ON b.User_id = c.User_id
		JOIN cccampsagente e ON c.User_id = e.User_id AND e.cam_id = @CamEspId AND a.IDWG = e.IDWG
		JOIN ccRIACat_WorkGroup d ON d.IDWG = a.IDWG
		WHERE a.IdCampEsp = @CamEspId AND a.tipo = 1 AND c.tipouser_id = 1
		ORDER BY 1, 2, 3

		INSERT INTO #WGPriority (IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		SELECT DISTINCT a.IDWG, d.WGName, 2, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno AS nombre, c.sexo, 0, a.priority AS WGPriority, 0
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
		SELECT DISTINCT a.IDWG, d.WGName, c.TipoUser_id, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno AS nombre, c.sexo, e.prioridad, a.priority AS WGPriority
		FROM ccRIACampEspWg a
		JOIN ccRIAWorkGroupUsers b ON a.IDWG = b.IDWG
		JOIN ccUsers c ON b.User_id = c.User_id
		JOIN ccInboundAgentes e ON c.User_id = e.User_id AND e.Inbound_id = @CamEspId AND a.IDWG = e.IDWG
		JOIN ccRIACat_WorkGroup d ON d.IDWG = a.IDWG
		WHERE a.IdCampEsp = @CamEspId AND tipo = 0
		ORDER BY 1, 2, 3

		INSERT INTO #WGPriority (IDWG, WGName, TipoUser_id, User_id, LOGIN, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
		SELECT DISTINCT a.IDWG, d.WGName, 2, b.User_id, c.LOGIN, c.TipoLlamadas, c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno AS nombre, c.sexo, 0, a.priority AS WGPriority, 0
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
'
		EXEC (@Sql)
				
			
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
