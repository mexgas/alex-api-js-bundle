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
	
-------------------------------------------- Daniel Hernandez CW-7842 ------------------------------
	SET @process = 'Delete stored procedure if it exists'
	SET @sql = 'if exists (select * from sys.procedures where name =''ccspRepOutDialDetail'')
				begin
					DROP PROCEDURE ccspRepOutDialDetail
				end'


	EXEC(@sql)
	
	set @process = 'Create SP ccspRepOutDialDetail FIX-It was fixed the source of the cal_key from ccocallsout to ccoLogDials, to ensure that the cal_key is correct regardless of the dialing result'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepOutDialDetail] 
		@action AS TINYINT, 
		@from AS   DATETIME = NULL, 
		@to AS     DATETIME = NULL
		AS
		SET NOCOUNT ON

		IF @from IS NULL
			SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
		if @to is null
			SELECT @to = GETDATE()

		IF @action = 1
		BEGIN  

		DECLARE @country SMALLINT
		SELECT @country = valor
		FROM ccSettings
		WHERE setting_id = 104

		--Borrar lo que esta para no repetir          
		DELETE FROM RepOutDialDetail WHERE date >= @from            AND date < @to
		        
			IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
			IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
			IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

			SELECT	dial.logDial_id
				,dial.callout_id
				,dial.cam_id
				,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
				,ISNULL(tr.descripcion ,'''') as resultDialDesc
				,dial.Telefono
				,dial.Puerto
				,dial.fecha
				,dial.tDialing
				,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
					  WHEN LEFT(dial.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' 
					  WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
					  WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType			  
				,dial.tBusy
				,dial.answerbit
				,dial.canceledNoAgents
				,dial.cal_id
				,dial.disconnectCause
				,dial.cal_key
				,co.file_moved
				,dial.tipoLlamada_id
				,tco.[Description] AS CallDisposition
				,tsco.califSubDesc
				,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
				,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
					WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel
				,ISNULL(regp.tPreview,'''') as tpreview
				,co.User_id as UserID
			INTO #dials
			FROM ccoLogDials dial(NOLOCK)
			LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
			LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
			LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
			LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) ON regp.callout_id = co.callout_id and regp.callId = co.cal_id
			LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dial.tipoResDial_id = tr.tiporesdial_id
			WHERE fecha >= @from AND fecha < @to
			union
			(
			select 
					''''
					,reg.callout_id
					,ccoa.cam_id
					,reg.process
					,ISNULL(cctyp.translatedDesc,'''')
					,ccoa.cal_telefono
					,''''
					,reg.reg_date
					,''''
					,''systemTranslated_Preview'' 		  
					,''''
					,''''
					,''''
					,''''
					,''''
					,ccoa.cal_Key
					,''''
					,''''
					,''''
					,''''
					,''''
					,''''	
					,reg.tPreview
					,reg.userId 
			FROM RegProcessPreviewRecord reg(NOLOCK)
			left join ccoCallsOutSource ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
			left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
			WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process !=7
			)
	
				select distinct cast(codeSip as int) as codeSip,disconnectCause into #codeSip from #dials where codeSip<>'''' and IsNumeric(codeSip)=1
			
				select A.codeSip,A.disconnectCause,B.description into #relationCodeSip from #codeSip A
				inner join DC_Extra B on A.codeSip=B.id
	
		--Inserta informacon de reporte  
			INSERT INTO RepOutDialDetail
				SELECT fecha as [date]
				,case when dials.cal_key is null or  cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
				,telefono telephone
				,dials.tiporesdial_id as tiporesdialId
				,CASE WHEN dials.tipoResDial_id = 14 THEN ''systemTranslated_CancelledBySystem'' ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
				,dials.[cam_id] campaignId
				,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campaign
				,dials.tbusy AS timeMessage
				,DATEPART(yyyy, fecha) year	
				,DATEPART(mm, fecha) month	
				,DATEPART(dd, fecha) day	
				,DATEPART(hh, fecha) hour	
				,DATEPART(mi, fecha) minutes
				,ISNULL(rl.name, '''') listName
				,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
				,ISNULL(cs.Dato1, '''') AS data1
				,ISNULL(cs.Dato2, '''') AS data2
				,ISNULL(cs.Dato3, '''') AS data3
				,ISNULL(cs.Dato4, '''') AS data4
				,ISNULL(cs.Dato5, '''') AS data5
				,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' ELSE ''Local'' END AS fileMoved
				,dials.disconnectCause
				,COALESCE(dat.description, descripcion, ''N/A'') DCCustomer
				,dials.dialType
				,TipoTel
				,ISNULL(CallDisposition, ''N/A'') AS CallDisposition
				,ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
				,ISNULL(csP.Dato6, '''') AS data6
				,ISNULL(csP.Dato7, '''') AS data7
				,ISNULL(csP.Dato8, '''') AS data8
				,ISNULL(csP.Dato9, '''') AS data9
				,ISNULL(csP.Dato10, '''') AS data10
				,ISNULL(csP.Dato11, '''') AS data11
				,ISNULL(csP.Dato12, '''') AS data12
				,ISNULL(csP.Dato13, '''') AS data13
				,ISNULL(csP.Dato14, '''') AS data14
				,ISNULL(csP.Dato15, '''') AS data15
				,dials.tpreview AS preview_Time
				,ISNULL(us.Login,'''')
			FROM #dials as dials
			LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
			LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
			LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
			LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
			LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
			LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
			LEFT JOIN ccUsers us (NOLOCK) ON  us.User_id = dials.UserID

			IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
			IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
			IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;
		END'
	EXEC(@Sql)	




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
