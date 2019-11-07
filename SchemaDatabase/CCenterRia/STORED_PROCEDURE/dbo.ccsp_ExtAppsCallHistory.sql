CREATE PROCEDURE [dbo].[ccsp_ExtAppsCallHistory] @action SMALLINT
	,@call_id INT = 0
	,@startDate VARCHAR(30) = NULL
	,@endDate VARCHAR(30) = NULL
	,@state INT = 0
	,@multipleCall_id AS VARCHAR(500) = NULL
	,@multipleUser_id AS VARCHAR(500) = NULL
	,@agentId INT = 0
	,@camId INT = 0
	,@PageNumber INT = 1
	,@isCount BIT = false
	,@userName AS VARCHAR(20) = ''
	,@password AS VARCHAR(33) = ''
AS
DECLARE @RowsPerPage INT

SET @RowsPerPage = 500

-- INBOUND x cal_id
IF @action = 1
BEGIN
	IF (
			@startDate = ''
			OR @startDate IS NULL
			)
	BEGIN
		SET @startDate = (
				SELECT TOP 1 cal_inicio
				FROM ccCallsIn
				ORDER BY cal_Inicio
				)
	END

	IF (
			@endDate = ''
			OR @endDate IS NULL
			)
	BEGIN
		SET @endDate = (
				SELECT TOP 1 cal_inicio
				FROM ccCallsIn
				ORDER BY cal_Inicio DESC
				)
	END

	SELECT TOP 500 cal_id AS call_id
		,c.inbound_id
		,isnull(a.descripcion, '') AS acdGroup
		,cal_ani AS phoneNumber
		,isnull(b.user_id, 0) AS [user_id]
		,isnull(LOGIN, '') AS LOGIN
		,isnull(e.description, '') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_key AS callKey
		,isnull(e.calif_id, '') AS dispositionId
		,isnull(f.califSubDesc, '') AS subDisposition
		,isnull(f.califSub_id, '') AS subDispositionId
		,cal_tmoh AS hold
	FROM cccallsin c WITH (NOLOCK)
	LEFT JOIN ccInbound a ON (c.Inbound_id = a.Inbound_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalif e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSub f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id >= @call_id
		AND c.cal_Inicio >= @startDate
		AND c.cal_Inicio <= @endDate
	ORDER BY cal_Inicio
END
		-- OUTBOUND x cal_id
ELSE IF @action = 2
BEGIN
	IF (
			@startDate = ''
			OR @startDate IS NULL
			)
	BEGIN
		SET @startDate = (
				SELECT TOP 1 cal_inicio
				FROM ccoCallsOut
				ORDER BY cal_Inicio
				)
			--select @startDate
	END

	IF (
			@endDate = ''
			OR @endDate IS NULL
			)
	BEGIN
		SET @endDate = (
				SELECT TOP 1 cal_inicio
				FROM ccoCallsOut
				ORDER BY cal_Inicio DESC
				)
			--select @endDate
	END

	SELECT TOP 500 cal_id AS call_id
		,c.cam_id
		,isnull(a.cam_descripcion, '') AS Campaign
		,c.cal_telefono AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '')
		,isnull(e.description, '') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_manual AS CallManual
		,c.cal_key AS callKey
		,list_id
		,isnull(e.calif_id, '') AS dispositionId
		,isnull(f.califSubDesc, '') AS subDisposition
		,isnull(f.califSub_id, '') AS subDispositionId
		,cal_tmoh AS hold
	FROM ccocallsout c WITH (NOLOCK)
	LEFT JOIN ccocallsoutsource cs ON (cs.callout_id = c.callout_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id >= @call_id
		AND c.cal_Inicio >= @startDate
		AND c.cal_Inicio <= @endDate
	ORDER BY cal_Inicio
END
ELSE IF @action = 3
BEGIN --Session time
	DECLARE @fecha_ini DATETIME
	DECLARE @fecha_fin DATETIME

	IF (
			@startDate IS NULL
			OR @endDate IS NULL
			)
		OR (
			@startDate = ''
			OR @endDate = ''
			)
	BEGIN
		SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(30), getdate()))

		SELECT @fecha_fin = dateadd(ss, - 1, dateadd(dd, 1, convert(DATETIME, convert(VARCHAR(11), getdate()))))
	END
	ELSE
	BEGIN
		SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(30), @startDate))

		SELECT @fecha_fin = convert(DATETIME, convert(VARCHAR(30), @endDate))
	END

	SELECT user_id
		,LOGIN
		,logout
		,datediff(ss, LOGIN, logout) AS logintime
	FROM (
		SELECT a.user_id
			,a.fecha AS 'login'
			,(
				SELECT isnull(max(Fecha), getdate())
				FROM ccLogLogin b WITH (NOLOCK)
				WHERE b.user_id = a.user_id
					AND b.tipomov = 0
					AND b.fecha >= a.fecha
					AND b.fecha <= (
						SELECT isnull(min(fecha), '99991231 23:59:59.998')
						FROM ccLogLogin WITH (NOLOCK)
						WHERE user_id = b.user_id
							AND tipomov = 1
							AND fecha > a.fecha
						)
				) AS 'logout'
		FROM ccLogLogin a
		WHERE a.tipomov = 1
			AND fecha >= @fecha_ini
			AND fecha <= @fecha_fin
		) AS sessiontime
	ORDER BY user_id
		,LOGIN
END
ELSE IF @action = 4
BEGIN -- Estados de los agentes
	SELECT User_id
		,tStatus
		,fecha
	FROM cclogagentesdia WITH (NOLOCK)
	WHERE TipoStatusAge_id = @state
		AND fecha >= @startDate
		AND fecha < @endDate
	ORDER BY User_id
		,fecha
END
ELSE IF @action = 5
BEGIN -- Sinlge Call id Inbound
	SELECT TOP 500 cal_id AS call_id
		,c.inbound_id
		,isnull(a.descripcion, '') AS acdGroup
		,cal_ani AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '') AS LOGIN
		,isnull(e.description, '') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_key AS callKey
		,isnull(e.calif_id, '') AS dispositionId
		,isnull(f.califSubDesc, '') AS subDisposition
		,isnull(f.califSub_id, '') AS subDispositionId
	FROM cccallsin c WITH (NOLOCK)
	LEFT JOIN ccInbound a ON (c.Inbound_id = a.Inbound_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalif e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSub f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleCall_id, ',')
			)
END
ELSE IF @action = 6
BEGIN -- Single call_id Outbound
	SELECT TOP 500 cal_id AS call_id
		,c.cam_id
		,isnull(a.cam_descripcion, '') AS Campaign
		,c.cal_telefono AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '')
		,isnull(e.description, '') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_manual AS CallManual
		,c.cal_key AS callKey
		,cs.list_id
		,isnull(e.calif_id, '') AS dispositionId
		,isnull(f.califSubDesc, '') AS subDisposition
		,isnull(f.califSub_id, '') AS subDispositionId
	FROM ccocallsout c WITH (NOLOCK)
	LEFT JOIN ccocallsoutsource cs(NOLOCK) ON (cs.callout_id = c.callout_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleCall_id, ',')
			)
END
ELSE IF @action = 7
BEGIN --Status Agente
	SELECT tipostatusAge_id
		,tstatus
		,dateadd(ss, (- 1 * tstatus), fecha)
		,IdCampEsp
		,Tipo
	FROM cclogagentesdia WITH (NOLOCK)
	WHERE user_id = @agentId
		AND fecha >= @startDate
		AND fecha < @endDate
	ORDER BY fecha
END
ELSE IF @action = 8
BEGIN
	SELECT tipostatusAge_id
		,tstatus
		,dateadd(ss, (- 1 * tstatus), fecha) fecha
		,IdCampEsp
		,Tipo
		,user_id
	FROM cclogagentesdia WITH (
			INDEX (IX_ccLogAgentesDia_4)
			,NOLOCK
			)
	WHERE user_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleUser_id, ',')
			)
		AND fecha BETWEEN @startDate
			AND @endDate
	ORDER BY user_id
		,fecha
END
ELSE IF @action = 9
BEGIN --Call History by CamId and day
	DECLARE @date DATETIME
		,@countRegistry BIGINT

	IF @PageNumber <= 0
		SET @PageNumber = 1
	SET @date = convert(DATETIME, convert(NVARCHAR(11), GETDATE(), 121))

	IF @isCount = 0
	BEGIN ---Datos para la informacion
		SELECT cal_id AS call_id
			,c.cam_id
			,isnull(a.cam_descripcion, '') AS Campaign
			,c.cal_telefono AS phoneNumber
			,isnull(b.user_id, 0) AS user_id
			,isnull(LOGIN, '')
			,isnull(e.description, '') AS disposition
			,d.descripcion AS call_status
			,cal_tDialog AS call_tDialog
			,cal_inicio AS call_date
			,cal_tNotas AS WrapUp
			,cal_tXfer AS Xfer
			,cal_tRing AS Ringing
			,cal_manual AS CallManual
			,c.cal_key AS callKey
			,list_id
			,isnull(e.calif_id, '') AS dispositionId
			,isnull(f.califSubDesc, '') AS subDisposition
			,isnull(f.califSub_id, '') AS subDispositionId
			,rowNum
			,cs.Dato1
			,cs.Dato2
			,cs.Dato3
			,cs.Dato4
			,cs.Dato5
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY cal_id
					) AS rowNum
				,c.callout_id
				,cal_id
				,c.cam_id
				,c.cal_telefono
				,cal_tDialog
				,cal_inicio
				,cal_tNotas
				,cal_tXfer
				,cal_tRing
				,cal_manual
				,c.cal_key
				,c.statusCall_id
				,c.calif_id
				,c.califSub_id
				,c.user_id
			FROM ccocallsout c WITH (
					NOLOCK
					,INDEX (IX_ccoCallsOut_3)
					)
			WHERE cam_id = @camId
				--and cal_Inicio >= @date and cal_Inicio<GETDATE()
			) AS c
		LEFT JOIN ccocallsoutsource cs ON (cs.callout_id = c.callout_id)
		LEFT JOIN ccusers b ON (c.user_id = b.user_id)
		LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
		LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
		LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
		LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
		WHERE rowNum BETWEEN ((@PageNumber - 1) * @RowsPerPage) + 1
				AND @RowsPerPage * (@PageNumber)
	END
	ELSE
	BEGIN --Numero de paginas y registros actuales
		SELECT @countRegistry = count(*)
		FROM ccocallsout c WITH (
				NOLOCK
				,INDEX (IX_ccoCallsOut_3)
				)
		WHERE cam_id = @camId

		--and cal_Inicio >= @date and cal_Inicio<GETDATE()
		SELECT @RowsPerPage AS pagesize
			,@PageNumber AS currentpage
			,@countRegistry / cast(@RowsPerPage AS FLOAT) AS totalpages
	END
END
ELSE IF (@action = 10)
BEGIN -- get agent status (Logged in or Logged out)
	DECLARE @isLoggedIn AS INT
	DECLARE @lastLogIn_Out AS DATETIME
	DECLARE @status AS INT

	SELECT @status = tipostatusage_id
	FROM ccUsers
	WHERE User_id = @agentId
		AND TipoUser_id = 1

	--SELECT @status
	IF (@status = 3)
	BEGIN
		SELECT @isLoggedIn = 1

		SELECT @lastLogIn_Out = max(fecha)
		FROM ccLogLogin
		WHERE fecha >= convert(DATE, getdate())
			AND User_id = @agentId
			AND TipoMov = 1 -- Login
	END
	ELSE IF (@status = 0)
	BEGIN
		SELECT @isLoggedIn = @status

		SELECT @lastLogIn_Out = max(fecha)
		FROM ccLogLogin
		WHERE fecha >= CONVERT(DATE, getdate())
			AND User_id = @agentId
			AND TipoMov = 0 --Logout 
	END

	SELECT @isLoggedIn
		,@lastLogIn_Out
END
ELSE IF (@action = 11) --verify User
BEGIN
	DECLARE @response AS INT

	SELECT @response = User_id
	FROM ccUsers
	WHERE LOGIN = @username
		AND password = dbo.md5(@password)

	SELECT isnull(@response, '')
END