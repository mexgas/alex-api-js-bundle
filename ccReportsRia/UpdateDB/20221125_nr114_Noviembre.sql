SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 114

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-7612 ccspGenSession DROP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspGenSession'')
	begin
        DROP PROCEDURE ccspGenSession;
    end
	'
	EXEC(@sql)

	set @process = 'CW-7612 ccspGenSession CREATE'
	set @sql = '
CREATE PROCEDURE [dbo].[ccspGenSession]
@from AS SMALLDATETIME,
@to AS SMALLDATETIME
AS
SET NOCOUNT ON

DECLARE @date DATETIME

CREATE TABLE #tempccGenSession ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, [login] [datetime] NOT NULL, [logout] [datetime] NULL, [extension] [varchar](7) NOT NULL, PRIMARY KEY (fila, user_id))
CREATE TABLE #temUserIdLogoutNull ([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, PRIMARY KEY (fila, user_id))

INSERT INTO #tempccGenSession
	SELECT A.Fila, A.User_id, dateadd(ms, - DATEPART(ms, A.fecha), A.fecha) LOGIN, dateadd(ms, - DATEPART(ms, S.fecha), S.fecha) logout, A.Extension
	FROM (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY user_id ORDER BY FECHA, tipoMov
				) Fila, User_id, Extension, TipoMov, fecha
		FROM ccLogLogin a
		WHERE fecha >= @from
			AND fecha <= @to
			----------
			AND TipoMov=1
		) A
	RIGHT JOIN 
	(
		SELECT ROW_NUMBER() OVER (
				PARTITION BY user_id ORDER BY FECHA, tipoMov
				) Fila, User_id, Extension, TipoMov, fecha
		FROM ccLogLogin a
		WHERE fecha >= @from
			AND fecha <= @to
			----------
			AND TipoMov=0
		) S
		ON	
			A.Fila = S.Fila
			AND A.User_id = S.User_id
		WHERE A.TipoMov = 1
	ORDER BY LOGIN

	UPDATE x
	SET x.fila = x.row
	FROM (
		SELECT fila, ROW_NUMBER() OVER (
				PARTITION BY user_id ORDER BY LOGIN
				) row
		FROM #tempccGenSession
		) x

	INSERT INTO #temUserIdLogoutNull
		SELECT user_id
		FROM #tempccGenSession
		WHERE logout IS NULL
		GROUP BY user_id

	INSERT INTO #temIdMaxLogoutNull
		SELECT A.fila, A.user_id
		FROM #tempccGenSession A
		INNER JOIN (
			SELECT max(fila) fila, user_id
			FROM #tempccGenSession
			WHERE user_id IN (
					SELECT user_id
					FROM #temUserIdLogoutNull
					)
			GROUP BY user_id
			) B
			ON A.fila = B.fila
				AND A.user_id = B.user_id
		WHERE A.logout IS NULL

	SET @date = GETDATE()

	UPDATE A
		SET A.logout = CASE WHEN @to < @date THEN @to ELSE @date END
		FROM #tempccGenSession A
		INNER JOIN #temIdMaxLogoutNull B
			ON A.user_id = B.user_id
				AND A.fila = B.fila

	UPDATE A
		SET A.logout = (
				SELECT CASE WHEN max(fecha) IS NOT NULL THEN max(fecha) WHEN DATEDIFF(ss, A.LOGIN, B.LOGIN) < 2 THEN DATEADD(ms, - 10, B.LOGIN) ELSE DATEADD(ms, 5, A.LOGIN) END
				FROM ccLogAgentesDia C
				WHERE A.user_Id = C.User_id
					AND fecha BETWEEN A.LOGIN
						AND B.LOGIN
				)
		FROM #tempccGenSession A
		LEFT JOIN #tempccGenSession B
			ON A.fila = B.fila - 1
				AND A.user_id = B.user_id
		WHERE A.logout IS NULL

	DELETE
	FROM #tempccGenSession
	WHERE LOGIN = logout

	DELETE A
	FROM #tempccGenSession A
	INNER JOIN (
		SELECT user_id, [login], logout
		FROM #tempccGenSession
		GROUP BY user_id, [login], logout
		HAVING count(*) > 1
		) B
		ON A.user_id = B.user_id
			AND A.LOGIN = B.LOGIN
			AND A.logout = B.logout

	UPDATE a
	WITH (ROWLOCK)

	SET a.logout = b.logout
	FROM #tempccGenSession b
	INNER JOIN #tempccGenSession a
		ON a.user_id = b.user_id
			AND a.LOGIN = b.LOGIN
			AND a.logout <> b.logout;

	WITH tmpccGenSession
	AS (
		SELECT user_id, dateadd(ss, - 1, [login]) AS [login], convert(VARCHAR(19), dateadd(ss, 1, [logout]), 121) AS [logout], extension
		, dbo.GetTimeGroup(dateadd(ss, - 1, [login]), 0) AS timeGroup, dbo.GetTimeGroup(dateadd(ss, 1, [logout]), 1) AS timeGroupNext
		FROM #tempccGenSession
		)
	SELECT A.*, datediff(ss, [login], [logout]) AS tlog
	FROM tmpccGenSession A

DROP TABLE #tempccGenSession
DROP TABLE #temUserIdLogoutNull
DROP TABLE #temIdMaxLogoutNull

SET NOCOUNT OFF
    '
	EXEC(@sql)

set @process = 'CW-7219 alter SP ccspRepAgentSummary'
	set @sql = '
	ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
	SELECT @to = GETDATE()

IF @action = 1
BEGIN
	IF OBJECT_ID(N''tempdb..#notReadyTable'') IS NOT NULL
		DROP TABLE #notReadyTable

	IF OBJECT_ID(N''tempdb..##tipoNotReady'') IS NOT NULL
		DROP TABLE ##tipoNotReady

	DECLARE @params NVARCHAR(4000) = ''@from datetime, @to datetime''
	DECLARE @column VARCHAR(max), @columnIsNull VARCHAR(max), @columnTable VARCHAR(max)
	DECLARE @sql NVARCHAR(max)

	CREATE TABLE #notReadyTable (notReadyId INT, descripcion VARCHAR(255))

	INSERT INTO #notReadyTable
	VALUES (- 1, ''break'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''pagos'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''personal'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''trabajoAdm'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''retro'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''falla'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''capacitacion'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''CWCallWork'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''pausaGrl'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''rh'')

	INSERT INTO #notReadyTable
	VALUES (- 1, ''inicio'')

	SELECT @column = '''', @columnIsNull = '''', @columnTable = ''''

	SELECT @column = quotename(descripcion) + '','' + @column, @columnIsNull = ''isnull('' + quotename(descripcion) + '',0) as ['' + descripcion + ''_],'' + @columnIsNull, @columnTable = ''['' + descripcion + ''_] int,'' + @columnTable
	FROM #notReadyTable

	SELECT @column = SUBSTRING(@column, 0, len(@column)), @columnIsNull = SUBSTRING(@columnIsNull, 0, len(@columnIsNull))

	UPDATE B
	SET B.notReadyId = A.TipoNotReady_id
	FROM cctiponotready A
	INNER JOIN #notReadyTable B
		ON A.Descripcion = B.descripcion

	SET @sql = ''
	create table ##tipoNotReady (userId int , daygroup date,'' + @columnTable + '')

	insert into ##tipoNotReady
	select userId,daygroup,'' + @columnIsNull + '' from (
	SELECT userId
			,dbo.getdaygroup(startDate) daygroup
			,[status]
			,sum(statusTime) as statusTime
		FROM RepAgentNotReadyDet A
		WHERE startDate BETWEEN @from				AND @to and
		tiponotreadyId in(select notReadyId from #notReadyTable where notReadyId>0)
		GROUP BY dbo.getdaygroup(startDate),userId,status
			) t 
			pivot
			(sum(statusTime)
			for [status] in ('' + @column + '')
			) as pivot_table
		''

	--print (@sql)
	EXEC sp_executesql @sql, @params, @from, @to

	DELETE RepAgentSummary WHERE DATE BETWEEN @from	AND @to;

	WITH AgentSession
	AS (
		SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
		FROM RepAgentSession
		WHERE dbo.getdaygroup(loginTime) BETWEEN @from
				AND @to
		GROUP BY dbo.getdaygroup(logintime), userId, [user]
		),
		-------------OUT -------------------
	dataCallsOut
	AS (
		SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
		FROM tmpTimesOutboundData
		where cal_manual in (0,2,3)
		GROUP BY cal_id, statusCall_id
		), dataCallsOutByDay
	AS (
		SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
		FROM tmpTimesOutboundData
		where cal_manual in (0,2,3)
		GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
		), tmpCallout
	AS (
		SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut, isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut, isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut, sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
		FROM dataCallsOutByDay A
		INNER JOIN dataCallsOut B
			ON A.cal_id = B.cal_id
		GROUP BY [date], User_id
		),
		------------- IN -------------------
	dataCallsIn
	AS (
		SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
		FROM tmpTimesInboundData
		GROUP BY cal_id, statusCall_id
		), dataCallsInByDay
	AS (
		SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn, sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
		FROM tmpTimesInboundData
		GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
		), tmpCallIn
	AS (
		SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn, isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn, isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn, sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
		FROM dataCallsInByDay A
		INNER JOIN dataCallsIn B
			ON A.cal_id = B.cal_id
		GROUP BY [date], User_id
		), RepDetail
	AS (
		SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
		FROM RepAgentNotReady r
		WHERE r.DATE BETWEEN @from
				AND @to
		GROUP BY dbo.getdaygroup(r.DATE), r.userId
		)

	
	INSERT INTO RepAgentSummary
	SELECT A.[date], A.[login], A.[user], '''' AS campaing, A.sessionTime, A.dateLogin AS loginMktTime
	, A.logout AS logoutMktTime
	, isnull(co.tDialogOut, 0) + isnull(co.tNotesOut, 0) + isnull(ci.tDialogIn, 0) + isnull(ci.tNotesIn, 0) dialogTime, ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn, ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta, ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend, ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif, ISNULL(t.break_, 0) AS NdBreak, ISNULL(t.personal_, 0) AS NdPersonal, ISNULL(t.pagos_, 0) AS NdPagos, ISNULL(t.trabajoAdm_, 0) AS NdTrabajoAdm, ISNULL(t.retro_, 0) AS NdRetro, ISNULL(t.falla_, 0) AS NdFalla, ISNULL(t.capacitacion_, 0) AS NdCapacitacion, ISNULL(t.CWCallWork_, 0) AS NdCWCallWork, ISNULL(t.pausagrl_, 0) AS NdPausaGrl, ISNULL(t.rh_, 0) AS NdRH, ISNULL(t.inicio_, 0) AS NdInicio, ISNULL(a.sessionTime, 0) - ISNULL(r.notready, 0) AS 
		Available
		,ISNULL(	
		(	ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
			/
		 nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
		, 0) AS PromDialog
		, 0 AS Skill, ''Verde'' AS Center, ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
	FROM AgentSession A
	LEFT JOIN tmpCallout co
		ON A.DATE = co.DATE
			AND A.userId = co.userId
	LEFT JOIN tmpCallIn ci
		ON A.DATE = ci.DATE
			AND A.userId = ci.userId
	LEFT JOIN RepDetail r
		ON r.daygroup = A.DATE
			AND A.userId = r.userId
	LEFT JOIN ##tipoNotReady t
		ON t.userId = A.userId
			AND t.daygroup = A.[date]

	IF OBJECT_ID(N''tempdb..#notReadyTable'') IS NOT NULL
		DROP TABLE #notReadyTable

	IF OBJECT_ID(N''tempdb..##tipoNotReady'') IS NOT NULL
		DROP TABLE ##tipoNotReady
END

	'
	EXEC(@sql)





	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
