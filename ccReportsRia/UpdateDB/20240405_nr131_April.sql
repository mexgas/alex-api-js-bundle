/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 131 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	----------------------------- begin Ulises ----------------------------

	set @process = 'insertar o actualizar el pivote en la tabla PivotReports'
	set @sql = 'if not exists (select 1 from PivotReports where id = 2100)
	begin
		insert into PivotReports values (2100,''descripcion_time|descripcion_auxiliarRedyTime_time'',''date|login|user|loginMktTime|logoutMktTime|sessionTime|unknownStatus|otherStatus|Available|ndTime|transferStatus|ringingTime|callTengaged|twrapup|failureStatus|chatTengaged|dialingStatus|undefinedTime|NCallsOut|NCallsIn|NCallsCorta|NAtend|NNoCalif|avgCallTengaged'',''max'',1)
	end
	else 
	begin
		update PivotReports set columns = ''descripcion_time|descripcion_auxiliarRedyTime_time'' where id = 2100
	end'
	EXEC(@sql)

	set @process = 'insert de las columnas para el redy auxiliar'
	set @sql = 'IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''RepAgentSummary'' AND COLUMN_NAME = ''TipoReadyAuxiliarId'')
	BEGIN
		EXEC(''ALTER TABLE RepAgentSummary ADD TipoReadyAuxiliarId INT'');
	END

	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''RepAgentSummary'' AND COLUMN_NAME = ''auxiliarRedy_descripcion'')
	BEGIN
		EXEC(''ALTER TABLE RepAgentSummary ADD auxiliarRedy_descripcion VARCHAR(50)'');
	END

	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''RepAgentSummary'' AND COLUMN_NAME = ''descripcion_auxiliarRedyTime_time'')
	BEGIN
		EXEC(''ALTER TABLE RepAgentSummary ADD descripcion_auxiliarRedyTime_time VARCHAR(50)'');
	END
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''RepAgentSummary'' AND COLUMN_NAME = ''auxiliarRedyTime'')
	BEGIN
		EXEC(''ALTER TABLE RepAgentSummary ADD auxiliarRedyTime INT'');
	END'
	EXEC(@sql)

	SET @process = 'si existe se elimina el sp ccspGetAuxiliarReadyDetail'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspGetAuxiliarReadyDetail'')
	begin
		DROP PROCEDURE ccspGetAuxiliarReadyDetail;
	end'
	EXEC(@sql)

	set @process = 'Se crea nuevamente el sp ccspGetAuxiliarReadyDetail'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspGetAuxiliarReadyDetail] @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
BEGIN
	if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	IF OBJECT_ID(''tempdb..#auxiliarReady'') IS NOT NULL
		DROP TABLE #auxiliarReady
	IF OBJECT_ID(''tempdb..#auxiliarReady2'') IS NOT NULL
		DROP TABLE #auxiliarReady2;

	;WITH auxiliarReadyDetail1 as(

	SELECT	
		laar.user_Id AS userId,
		laar.TipoAuxiliarReady_id AS tipoAuxiliarReadyId,
		DATEADD(s, - tstatus, fecha) AS startDate,
		fecha AS endDate,
		tStatus AS statusTime
	FROM ccLogAgentesAuxiliarReady laar
	INNER JOIN TipoReadyAuxiliar tra on tra.TipoReadyAuxiliar_Id = laar.TipoAuxiliarReady_id
	LEFT JOIN ccUserView usr ON usr.user_id = laar.user_id 
	where laar.fecha between @from and @to and tStatus>0
	)

	select 
	userId,startDate,endDate, convert(date,startDate,121)timegroup 
	,convert(date,endDate,121) timegroup_next,statusTime as tStatus,tipoAuxiliarReadyId
	into #auxiliarReady
	from auxiliarReadyDetail1

	--Para separar por dia si el notready esta entre dos dias
	select *
	INTO #auxiliarReady2
	from #auxiliarReady 
	where DATEDIFF(dd, timegroup, timegroup_next) > 1

	DELETE #auxiliarReady
	WHERE DATEDIFF(dd, timegroup, timegroup_next) > 1
	
	;with timeByDay as(
	select convert(date,Start,121) Start,convert(date,max(Stop),121) Stop from TmpTimesInterval 
	group by convert(date,Start,121)
	)

	insert into #auxiliarReady
	select t.userId,t.startDate,t.endDate, th.start AS timegroup, th.stop AS timegroup_next,
		dbo.TimeInterval(th.start, th.stop, startDate, endDate) AS [tStatus], tipoAuxiliarReadyId

		from #auxiliarReady2 t
	inner join timeByDay th ON (t.timegroup > th.Start AND t.timegroup < th.stop) OR th.Start BETWEEN t.timegroup AND t.timegroup_next
		WHERE datediff(ss, th.start, timegroup_next) > 0


	;with auxiliarReadyByDay as(
	select userId,timegroup,sum(tStatus) tStatus,tipoAuxiliarReadyId 
	from #auxiliarReady	
	group by userId,timegroup,tipoAuxiliarReadyId
	)
	,AgentSession
		AS (
			SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user],
			MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
			FROM RepAgentSession
			WHERE dbo.getdaygroup(loginTime) BETWEEN @from
					AND @to
			GROUP BY dbo.getdaygroup(logintime), userId, [user]
			)


	select A.timegroup 
	, A.userId, userView.apellidopaterno + '' '' + userView.apellidomaterno + '' '' + userView.nombres AS [user]
	, S.sessionTime
	, isnull(d.TipoReadyAuxiliar_Id,0) as TipoReadyAuxiliarId, isnull(d.Description, '''') descripcion
	, isnull(d.Description, '''') + ''_TimeAux'' AS descripcion_time
	, isnull(A.tStatus, 0) AS [time]
	, isnull(A.tStatus, 0) AS timeSeconds

	from auxiliarReadyByDay A
	INNER JOIN ccUserView userView ON A.userId = userView.User_id
	LEFT JOIN TipoReadyAuxiliar d	ON A.tipoAuxiliarReadyId = d.TipoReadyAuxiliar_Id
	left join AgentSession s on S.userId=A.userId and S.date=A.timegroup

	IF OBJECT_ID(''tempdb..#auxiliarReady'') IS NOT NULL
		DROP TABLE #auxiliarReady

	IF OBJECT_ID(''tempdb..#auxiliarReady2'') IS NOT NULL
		DROP TABLE #auxiliarReady2
END'
	EXEC(@sql)

	set @process = 'Se elimina el sp ccspRepAgentSummary'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepAgentSummary'')
	begin
		DROP PROCEDURE ccspRepAgentSummary;
	end'
	EXEC(@sql)

	set @process = 'Se crea el sp ccspRepAgentSummary'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
	SELECT @to = GETDATE()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN	
	select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN

	IF OBJECT_ID(''tempdb..#AuxiliarReadyDetail'') IS NOT NULL
    DROP TABLE #AuxiliarReadyDetail

	CREATE TABLE #AuxiliarReadyDetail
	(
		timegroup DATE,
		userId INT,
		[user] VARCHAR(50),
		[sessionTime] INT,
		TipoReadyAuxiliarId INT,
		descripcion VARCHAR(50),
		descripcion_time VARCHAR(50),
		[time] DECIMAL(18, 3),
		timeSeconds DECIMAL(18, 3)
	)

	INSERT INTO #AuxiliarReadyDetail
	EXEC ccspGetAuxiliarReadyDetail @from = @from, @to = @to
		
	DELETE RepAgentSummary WHERE DATE BETWEEN @from	AND @to;
	;
	WITH AgentSession
	AS (
		SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
		FROM RepAgentSession
		WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
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
		SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
		, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
		, SUM(txfer)  txferOut, SUM(tring)  tringOut
		FROM tmpTimesOutboundData
		where cal_manual in (0,2,3)
		GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
		), tmpCallout
	AS (
		SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
		, isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
		, isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
		, sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
		, sum(nabnd_dialog) abnd_dialog, [date]
		, SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
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
		SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
		, sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
		, SUM(txfer)  txferIn, SUM(tring)  tringIn
		FROM tmpTimesInboundData
		GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
		), tmpCallIn
	AS (
		SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
		, isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
		, isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
		, sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
		, sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
		, SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
		FROM dataCallsInByDay A
		INNER JOIN dataCallsIn B
			ON A.cal_id = B.cal_id
		GROUP BY [date], User_id
		), RepDetail
	AS (
		SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
		FROM RepAgentNotReady r with(nolock)
		WHERE r.DATE BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup(r.DATE), r.userId
		)
	,notReadyDay as(
	SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
		,descripcion_time,descripcion,tiponotreadyId
		FROM RepAgentNotReady r with(nolock)
		WHERE r.DATE BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
	),auxiliarReadyDay as(
		SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(timegroup) AS daygroup
		,descripcion_time,descripcion,TipoReadyAuxiliarId
		FROM #AuxiliarReadyDetail r with(nolock)
		GROUP BY dbo.getdaygroup(timegroup), r.userId,descripcion,descripcion_time,TipoReadyAuxiliarId
	), RepAgentGIGroup as(
		SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
		, SUM(tunknown) AS tunknown
		, SUM(tother) AS tother
		, SUM(tprob) AS tprob
		, SUM(tChatting) AS tChatting		
		, SUM(tundefined) AS tundefined
		, SUM([tManual]) AS [tManual]
		FROM RepAgentGI
		WHERE [date] BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup([date]), userId
	)
	--select * from AgentSession
	
	INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
	,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
	,chatTengaged,undefinedTime,dialingStatus,TipoReadyAuxiliarId,auxiliarRedy_descripcion,descripcion_auxiliarRedyTime_time,auxiliarRedyTime)
	SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
	, A.logout AS logoutMktTime
	, isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
	, ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
	, ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
	, ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
	, ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif	
	, ISNULL(AgtGI.tav, 0) AS Available
		,ISNULL(	
		(	ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
			/
		 nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
		, 0) AS avgCallTengaged
		
		,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
		, notReady.TipoNotReadyId
		, notReady.descripcion
		, notReady.descripcion_time
		, notReady.timeSeconds
		, ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
		, ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
		, ISNULL(AgtGI.tunknown, 0) unknownStatus
		, ISNULL(AgtGI.tother, 0) otherStatus
		, ISNULL(AgtGI.tprob, 0) failureStatus
		, ISNULL(AgtGI.tChatting, 0) chatTengaged
		, ISNULL(AgtGI.tundefined, 0) undefinedTime
		, ISNULL(AgtGI.tManual, 0) dialingStatus
		, auxiliarReady.TipoReadyAuxiliarId
		, auxiliarReady.descripcion as auxiliarRedy_descripcion
		, auxiliarReady.descripcion_time as descripcion_auxiliarRedyTime_time
		, convert(int,auxiliarReady.timeSeconds) as auxiliarRedyTime
	FROM AgentSession A
	LEFT JOIN tmpCallout co ON A.DATE = co.DATE	AND A.userId = co.userId
	LEFT JOIN tmpCallIn ci	ON A.DATE = ci.DATE	AND A.userId = ci.userId
	LEFT JOIN RepDetail r	ON r.daygroup = A.DATE AND A.userId = r.userId
	inner join notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
	LEFT join #AuxiliarReadyDetail auxiliarReady on auxiliarReady.userId=A.userId and auxiliarReady.timegroup=A.date
	left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
	order by A.[date],A.userId

END'
	EXEC(@sql)

	----------------------------- Begin TEAM Nuevos Rec -------------------

SET @process = 'KR123000 Se agregan los filtros correspondientes'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportsFiltersMenus where idReport = 2130)
BEGIN
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(2130,N''date'')
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(2130,N''filterby'')
	INSERT INTO ReportsFilters values(''Special Detail (Auxiliary)'',''users'',2130)
	INSERT INTO ReportsFilters values(''Special Detail (Auxiliary)'',''auxiliar'',2130)
END'
EXEC(@sql)

SET @process = 'KR123000 Se inserta el menu de auxiliar a la tabla Filters'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM Filters where id = 34)
BEGIN
	INSERT INTO Filters(id,[name], [type], xmlParentNode, xmlChildNode) VALUES(34,N''auxiliar'', 34, ''Auxiliar'', ''Auxiliar'')
END'
EXEC(@sql)

SET @process = 'KR123000 se inserta el nuevo reporte en la tabla ReportsTotals'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportsTotals where id = 2130)
BEGIN
	INSERT INTO ReportsTotals(id,totalColumns) VALUES(2130, ''sum:statusTimeAuxiliar'')
END'
EXEC(@sql)

SET @process = 'KR123000 se añade laa columnaa tipoAuxiliarReady_id, descripcion, descripcion_Time y timea la tabla  RepAgentCallStatusesByInterval '
SET @sql = 'IF NOT EXISTS(select column_name from INFORMATION_SCHEMA.columns  where table_name = ''RepAgentCallStatusesByInterval'' and column_name = ''tipoAuxiliarReady_id'')
BEGIN
	ALTER TABLE RepAgentCallStatusesByInterval ADD 
	tipoAuxiliarReady_id int null,
	[descripcion] varchar(max), 
	[descripcion_Time] varchar(max),
	[time] int null
END'
EXEC(@sql)

SET @process = 'KR123000 se insertan valores en la tabla PivotReports, GroupByReports y se modifican ReportsTotals para el reporte 2070'
SET @sql = 'IF NOT EXISTS (select 1 from PivotReports where id = 2070)
BEGIN
	insert into PivotReports 
	values(2070,''descripcion_time'',''date|userId|login|startInterval|endInterval|readyTime|twrapup|tring|tother|tnav|tCallTransf|twbCall'',''sum'',1)

	insert into GroupByReports 
	values(2070,''userId|login|min(startInterval):startInterval|max(endInterval):endInterval|sum(readyTime):readyTime|sum(twrapup):twrapup|sum(tring):tring|sum(tother):tother|sum(tnav):tnav|sum(tCallTransf):tCallTransf|sum(twbCall):twbCall|sum([time]):time:pivotGroup|max(descripcion_time):descripcion_time:pivotGroup'',''userId|login|descripcion_time'')

	update ReportsTotals set totalColumns = ''sum:readyTime|sum:tring|sum:twrapup|sum:tother|sum:tnav|sum:tCallTransf|sum:twbCall|sum:time'' 
	where id = 2070

END'
EXEC(@sql)

SET @process = 'KR123000 se agregan las columnas tAuxiliar para la tabla RepMKTIntervalosTiemposAcuTotales'
SET @sql = 'IF NOT EXISTS(select column_name from INFORMATION_SCHEMA.columns  where table_name = ''RepMKTIntervalosTiemposAcuTotales'' and column_name = ''tAuxiliar'')
BEGIN
	ALTER TABLE RepMKTIntervalosTiemposAcuTotales ADD 
	tAuxiliar int null
END

UPDATE ReportsTotals set 
totalColumns = ''special:PromPosicionPersonal:sum(PromPosicionPersonal)|special:LlamadasRecibidas:sum(LlamadasRecibidas)|special:LlamadasAtendidas:sum(LlamadasAtendidas)|special:LlamadasAban:sum(LlamadasAban)|special:tACD:sum(tACD)|special:tACW:sum(tACW)|special:tLogout:sum(tLogout)|special:tDescon:sum(tDescon)|special:tnotav:sum(tnotav)|special:tAuxiliar:sum(tAuxiliar)|special:TiempoDispo:sum(TiempoDispo)|special:txfer:sum(txfer)|special:tother:sum(tother)|special:tCliente:sum(tCliente)|special:tring:sum(tring)|special:tprob:sum(tprob)|special:tManual:sum(tManual)|special:timeretention:sum(timeretention)|special:LlamadasSalidaExt:sum(LlamadasSalidaExt)|special:TiempoSalidaExt:sum(TiempoSalidaExt)|special:PorcNiveldeServicio4080:case when sum(LlamadasRecibidas)>0 then (sum(nserv) * 100) / sum(LlamadasRecibidas) else 0 end|special:AHT:((case when sum(LlamadasAtendidas)>0 then sum(tACD)/sum(LlamadasAtendidas) else 0 end)+(case when sum(nacw)>0 then sum(tACW)/sum(nacw) else 0 end)+(case when sum(LlamadasenRing)>0 then sum(tring)/sum(LlamadasenRing) else 0 end)+(case when sum(LlamadasRetenidas)>0 then sum([timeretention])/sum(LlamadasRetenidas) else 0 end))|special:LlamadasRetenidas:sum(LlamadasRetenidas)|special:LlamadasenRing:sum(LlamadasenRing)''
WHERE id = 7160

UPDATE GroupByReports SET
[columns] = ''InboundId|max([descripcion]):descripcion|sum([PromPosicionPersonal]):PromPosicionPersonal|sum([LlamadasRecibidas]):LlamadasRecibidas|sum([LlamadasAtendidas]):LlamadasAtendidas|sum([LlamadasAban]):LlamadasAban|sum([tacd]):tACD|sum([tACW]):tACW|sum([tLogout]):tLogout|sum([tDescon]):tDescon|sum([tnotav]):tnotav|sum([tAuxiliar]):tAuxiliar|sum([TiempoDispo]):TiempoDispo|sum([txfer]):txfer|sum([tother]):tother|sum([tCliente]):tCliente|sum([tring]):tring|sum([tprob]):tprob|sum([tManual]):tManual|sum([timeretention]):timeretention|sum([LlamadasSalidaExt]):LlamadasSalidaExt|sum([TiempoSalidaExt]):TiempoSalidaExt|case when sum(LlamadasRecibidas)>0 then (sum(nserv) * 100) / sum(LlamadasRecibidas) else 0 end:PorcNiveldeServicio4080|((case when sum(LlamadasAtendidas)>0 then sum(tACD)/sum(LlamadasAtendidas) else 0 end)+(case when sum(nacw)>0 then sum(tACW)/sum(nacw) else 0 end)+(case when sum(LlamadasenRing)>0 then sum(tring)/sum(LlamadasenRing) else 0 end)+(case when sum(LlamadasRetenidas)>0 then sum([timeretention])/sum(LlamadasRetenidas) else 0 end)):AHT|sum([LlamadasRetenidas]):LlamadasRetenidas|sum([LlamadasenRing]):LlamadasenRing''
where id = 7160'
EXEC(@sql)

SET @process = 'KR123000 se odifica el sp ccspRepCatalogos'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepCatalogos]
	@type as tinyint,
	@action tinyint = 0 -- 0 Filter select; 1 Filters Range
	,@userId int =0 ---- se agrega parametro para filtros
	,@menuId INT = 0

	AS
	declare @tablatemp table (id int, description varchar(100) null)
	declare @tempwork table (idwg int)
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @condition NVARCHAR(300) = '''';
	DECLARE @columnName NVARCHAR(100) = '''';
	DECLARE @consult NVARCHAR (2000) = '''';

	if @action = 0
	BEGIN
	IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
	BEGIN
		CREATE TABLE #filters ([Type] VARCHAR(200))
	END

		-- CAMPAIGNS
	IF @type = 1 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName =	''campaignId'';
		END

		SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)	
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
				where us.[User_id] = @userId ''
				+ @consult + '' inner join @tablatemp A on camp.cam_id = A.id'' + @condition;
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
	END


		-- DIAL RESULTS
	if @type = 2 begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

		-- WORKGROUPS
	if @type = 3 begin
		if @userId <> 0 begin
			select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
			from ccWgByAcdView v
			inner join ccriacat_workgroup c on c.IDWG=v.IDWG
			where USER_ID= @userId
			return
		end
		else  begin
			select idwg as id, wgname as description, ''workgroupId'' as dbColumn
			from ccRIACat_WorkGroup
			group by idwg, wgname	select * from ccRIACat_WorkGroup
			order by wgname
		end
	end


	-- AREAS
	if @type = 4 begin
	if @userId <> 0 begin

		insert into @tablatemp
		select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
		inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
		where us.[User_id] = @userId

		select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
		from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
		return
	end
		else begin

			select idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas
			group by idArea, AreaName
			order by AreaName
		end
	end

	-- DISPOSITIONS OUT
	if @type = 5 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

		-- USER
	if @type = 6 	begin
		if @userId <> 0 begin

				insert into @tempwork
						select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

				select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

				inner join @tempwork awg on wgu.IDWG = awg.idwg
				where us.TipoUser_id = 1 and [status] = 1

				return
			end

			else begin

				SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
				FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
				ORDER BY description
			end
	end

		-- ACDS**************
	IF @type = 7 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName = ''inboundId'';
		END

		SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
			FROM ccinbound B''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId;''
				+ @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;'';		
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
	end

		-- DIDS
	if @type = 8 	begin
		select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
		union
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

		--DISPOSITIONS IN
	if @type = 9 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

		--SUBDISPOSITIONS IN
	if @type = 10	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

		--PROVIDER
	if @type = 11 begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

		-- UNAVAILABLES
	if @type = 12 begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

		-- DIALERS
	if @type = 13 begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

		-- CallTYpes
	if @type = 14	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

		-- SUBDISPOSITIONS OUT
	if @type = 21	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

		--AVRS TEMPLATE-SECTION
	if @type = 15 	begin
		SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
		FROM RIA_FORMATOCONCEPTO fc
		INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato, nombre) as rf
		ON rf.id_formato = fc.templateId
		inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
		order by fc.id
	END

	--exec dbo.ccspRepCatalogos @type=15,@action=0

		--AVRS TEMPLATES
	if @type = 16 	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

		--AVRS TEMPLATES
	if @type = 31 	begin
		SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
		FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
										FROM RIA_CONCEPTOS
										group by id_concepto) as t
		ON c.id_concepto = t.id_concepto AND c.version = t.version
		order by c.con_descripcion
	END

		--AVRS QUESTIONS
	if @type = 23 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END


	--AVRS QUESTIONS CHAT
	if @type = 24 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END

		-- AVRS SUPERVISOR
	if @type = 17 	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUserView
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

		--Status Call
	if @type = 25 	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

		--Survey
	if @type = 26 	begin
		select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
		from Survey
		order by [description]
	end

	--dialType
	if @type = 29 begin
		select dialId as id, [description] as description, ''dialId'' as dbcolumn
		from dialType
		order by [description]
	end

		--dial
	if @type = 30 	begin
		select id as id, [description] as description, ''dialId'' as dbcolumn
		from Dials
		order by [description]
	end

	if @type = 33 begin
		if @userId <> 0 begin
 			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
			inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat = 0
			where us.[User_id] = @userId

			SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound B
			inner join @tablatemp A on B.inbound_id = A.id
			return
		end
		else begin
			select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound where chat = 0
		end
	end
	--Auxiliar
				IF @type = 34 	BEGIN
					SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
					FROM TipoReadyAuxiliar
					ORDER BY [description]
				END

	end --Action 0

	IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
	BEGIN
		DROP TABLE #filters;
	END

	-----------------------------------------------------------
	if @action = 1 begin
		-- TRUNKS
		if @type = 13
		begin
			SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
		end

		-- AVRS DISPOSITION
		if @type = 18
		begin
			SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
		end

		-- AVG DISPOSITION
		if @type = 19
		begin
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end

		-- SCORE
		if @type = 20
		begin
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end
	END
'
EXEC(@sql)


SET @process = 'KR123000 se modifica el sp ccspRepMKTIntervalosTiemposAcuTotales'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @dateNow DATETIME
	,@maxLogout DATETIME

IF @action = 1
BEGIN
	

	IF OBJECT_ID(''tempdb..#RepMKTIntervalosTiemposAcuTotalesTemp'') IS NOT NULL
		DROP TABLE #RepMKTIntervalosTiemposAcuTotalesTemp

	IF OBJECT_ID(''tempdb..#timeDetailAgentFinal'') IS NOT NULL
		DROP TABLE #timeDetailAgentFinal	

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL
		DROP TABLE #sessionTimeGroup

	CREATE TABLE #sessionTimeGroup (
		[user_id] [smallint] NOT NULL
		,[timegroup] [datetime] NOT NULL
		,[tlog] [INT] NULL
		,[inb_id] [int] NOT NULL
		);

	;WITH relationWg
	AS (
		SELECT DISTINCT wgu.User_id
			,wg.IdCampEsp
		FROM ccriaworkgroupusers wgu
		INNER JOIN ccRIACampEspWG wg
			ON wg.IDWG = WGU.IDWG
		WHERE wg.Tipo = 0
		)


	INSERT INTO #sessionTimeGroup
	SELECT st.[user_id]
		,timegroup
		,tlog
		,wgu.IdCampEsp
	FROM TmpSessionTimeGroup st
	INNER JOIN relationWg wgu
		ON st.User_id = wgu.User_id

			---------------------oRows---------------------
			;

	WITH timeDetailAgent
	AS (
		SELECT userId
			,timeGroup
			,CASE WHEN A.tipostatusage_id = 1 THEN A.tStatus ELSE 0 END tunknown
			,CASE WHEN A.tipostatusage_id = 2 THEN A.tStatus ELSE 0 END tnot_av
			,CASE WHEN A.tipostatusage_id = 3 THEN A.tStatus ELSE 0 END tav
			,CASE WHEN A.tipostatusage_id IN (11, 25, 26, 27) THEN A.tStatus ELSE 0 END tprob
			,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
			CASE WHEN A.tipostatusage_id = 7 THEN A.tStatus ELSE 0 END tother
			,CASE WHEN A.TipoStatusAge_id = 8 THEN A.tStatus ELSE 0 END tcliente
			,CASE WHEN A.TipoStatusAge_id = 0 THEN A.tStatus ELSE 0 END tlogout
			,CASE WHEN A.tipostatusage_id = 21 THEN A.tStatus ELSE 0 END tmanualCall
			,CASE WHEN A.tipostatusage_id = 37 THEN A.tStatus ELSE 0 END tAuxiliar
		FROM tmpccLogAgentesDia A
		)

	SELECT B.inb_id as IdCampEsp
		,A.timeGroup
		,sum(tunknown) tunknown
		,sum(tnot_av) tnot_av
		,sum(tav) tav
		,sum(tother) tother
		,sum(tprob) tprob
		,sum(tmanualCall) tmanualCall
		,sum(tlogout) tlogout
		,sum(tcliente) tcliente
		,sum(tAuxiliar) tAuxiliar
	INTO #timeDetailAgentFinal
	FROM timeDetailAgent A
	INNER JOIN #sessionTimeGroup B
		ON A.timeGroup = B.timegroup
			AND A.userId = B.user_id
	GROUP BY B.inb_id
		,A.timeGroup
	
	----------------------------------------------------------
	
	;with 
	 relationCallIdCamId as(
		select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
	),
	transferData as(
		select B.userId,B.InboundId
		,CASE WHEN t.modo = 2 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fent
		,CASE WHEN t.modo = 2 and t.tipo=1 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fsal
		,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) then [dbo].TimeInterval( timegroup,timegroup_next,dateIni,dateEnd) else 0 end as tprosalext	
		,dateIni as dateStart	
		,dateEnd
		,timegroup
		,timegroup_next
		from TmpTimesccLogtransfers T
		inner join relationCallIdCamId B on t.callId=B.callId	
		where tipo=1
	), transferDataGroup as(

	select userId, timegroup, InboundId 
	,sum(fent) fent,sum(fsal) fsal, sum(salExt) salExt,sum(tprosalext) as tprosalext
	,min(dateStart) as [dateTTransferStart]
	,max(dateEnd) as [dateTTransferEnd]
	from transferData
	group by timegroup, InboundId,userId
	), inboundGroup as(

	select 
	i.timegroup
	,i.inbound_Id as inboundId	
	,i.User_id as userId
	,sum(case when statusCall_id =13 and ntotal>0 then 1 else 0 end) as nacd
	,sum(case when statusCall_id <>13 and ntotal>0 then 1 else 0 end) as nabnd	
	,sum(case when statusCall_id=13 then tdialog else 0 end) as tacd
	,sum(case when statusCall_id=13 then tnotes else 0 end) as tacw
	,sum(case when statusCall_id=13 and ntotal>0 and tnotes>0 then 1 else 0 end) as nacw 
	,sum(ntotal) nCalls
	,sum(case when statusCall_id=13 then txfer else 0 end) as txfer
	,isnull(sum(t.SalExt),0) as SalExt
	,isnull(sum(t.tprosalext),0) as tprosalext	
	,sum(nMoh) as nhold 
	,sum(case when statusCall_id=13 and ntotal>0 and tque+txfer+tring<40 then 1 else 0 end) as nserv 
	,sum(tring) AS tring
	,sum(case when statusCall_id=13 and ntotal>0 and tring>0 then 1 else 0 end) nring
	,sum(cal_tmoh) AS thold	
	,count(DISTINCT i.User_id) as countUserDistinct
	,count(distinct case when statusCall_id =13 and ntotal>0 then  userId end ) countUserDistinctNacd
	from tmpTimesInboundData i
	left join transferDataGroup t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId and i.User_id=t.userId	
	group by i.timegroup,i.inbound_Id,i.User_id
	), groupLog as(
	select userId as User_id ,camId as IdCampEsp,TipoStatusAge_id
	,sum(tStatus) as tStatus
	,sum(1) nstatusfra
	,timegroup	
	from tmpccLogAgentesDia
	where TipoStatusAge_id=3
	group by userId,camId,TipoStatusAge_id,timegroup
	)
	-----------------------------------------------------------------------------------
	
	SELECT DISTINCT CASE WHEN c.timegroup IS NOT NULL THEN c.timegroup ELSE G.timegroup END AS [date]
		,isnull(c.inboundId, inb_id) AS inboundId
		,isnull(ci.descripcion, '''') AS [descripcion]
		,isnull(c.ncalls, 0) AS ncalls --LlamadasRecibidas
		,isnull(c.nacd, 0) AS nacd --atendidas
		,isnull(c.nabnd, 0) AS nabnd --abandonadas
		,isnull(c.tacd, 0) AS tacd --TiempoACD
		,isnull(c.tacw, 0) AS tacw --TiempoACW
		,isnull(d.tlogout, 0) AS tlogout --TiempoLogout
		,isnull(c.nacw, 0) AS nacw --nACW
		,isnull(d.tunknown, 0) AS tunknown --TiempoDescon
		,isnull(d.tnot_av, 0) AS tnot_av --TiempoNoDispo
		,isnull(c.txfer, 0) AS txfer --TiempoXfer
		,isnull(d.tother, 0) AS tother --TiempoOtra
		,isnull(d.tcliente, 0) AS tcliente --TiempoCliente
		,isnull(d.tprob, 0) AS tprob --TiempoProblema
		,isnull(d.tmanualCall, 0) AS tmanualCall --TiempoManual
		,G.user_id userId
		,isnull(G.[tlog], 0) AS tlog
		,isnull(hi.tiempohold, 0) AS tiempoHold
		,isnull(c.SalExt, 0) AS SalExt
		,isnull(c.tprosalext, 0) tprosalext
		,isnull(c.nhold, 0) nhold
		,isnull(thold, 0) thold
		,isnull(c.nserv, 0) nserv
		,isnull(c.nring, 0) nring
		,isnull(c.tring, 0) tring
		,isnull(d.tAuxiliar, 0) tAuxiliar
	INTO #RepMKTIntervalosTiemposAcuTotalesTemp
	FROM inboundGroup c
	FULL JOIN #sessionTimeGroup G ON G.timegroup = c.[timegroup] AND c.inboundId = G.inb_id AND G.user_id = c.userId
	LEFT JOIN tmpTimesHoldIn hi ON hi.inbound_id = C.inboundId AND hi.timegroup = C.timegroup
	LEFT JOIN ccinbound ci(NOLOCK) ON ci.Inbound_id = c.inboundId
	LEFT JOIN #timeDetailAgentFinal d(NOLOCK) ON d.IdCampEsp = ci.Inbound_id AND d.timegroup = C.timegroup
	LEFT JOIN groupLog lo ON c.timegroup = lo.timegroup AND c.inboundId = lo.IdCampEsp AND c.userId = lo.user_id

	DELETE
	FROM [RepMKTIntervalosTiemposAcuTotales]
	WHERE DATE >= @from
		AND DATE <= @to

	INSERT INTO [RepMKTIntervalosTiemposAcuTotales]
	SELECT [date] AS [date]
		,inboundId
		,inb.descripcion AS descripcion
		,round(CASE WHEN count(DISTINCT userId) > 1 THEN ((convert(FLOAT, (sum([tlog]) * 100)) / convert(FLOAT, count(DISTINCT userId) * 1800)) * count(DISTINCT userId)
							) / 100 ELSE 0 END, 1) AS [PromPosicionPersonal]
		,sum(ncalls) LlamadasRecibidas
		,sum(nacd) LlamadasAtendidas
		,sum(nabnd) LlamadasAban
		,sum(tacd) AS TiempoACD --tACD
		,sum(tacw) AS TiempoACW --tACW
		,sum(c.tlogout) AS TiempoLogout --tLogout
		,sum(c.tunknown) AS TiempoDescon --tDescon
		,sum(DISTINCT c.tnot_av) AS TiempoNoDispo --tnotav
		,sum(DISTINCT d.tav) AS TiempoDispo
		,sum(txfer) AS TiempoXfer --txfer
		,sum(c.tother) AS TiempoOtra --tother
		,sum(c.tcliente) AS TiempoCliente --tCliente
		,sum(tring) AS TiempoRing --tring
		,sum(c.tprob) AS TiempoProblema --tprob
		,sum(c.tmanualCall) AS TiempoManual --tManual
		,sum(tiempoHold) AS TiempoReten --[timeretention]
		,sum(SalExt) AS LlamadasSalidaExt
		,CASE WHEN sum(SalExt) > 0 THEN sum(tprosalext) ELSE 0 END AS [TiempoSalidaExt]
		,CASE WHEN sum(ncalls) > 0 THEN (sum(nserv) * 100) / sum(ncalls) ELSE 0 END [PorcNiveldeServicio4080]
		,(
			(CASE WHEN sum(nacd) > 0 THEN sum(tacd) / sum(nacd) ELSE 0 END) + (CASE WHEN sum(nacw) > 0 THEN sum(tacw) / sum(nacw) ELSE 0 END) + (CASE WHEN sum(nring) > 0 THEN sum(tring) / sum(nring) ELSE 0 END
				) + (CASE WHEN sum(nhold) > 0 THEN sum(thold) / sum(nhold) ELSE 0 END)
			) [AHT]
		,sum(nhold) AS LlamadasRetenidas
		,sum(nring) AS LlamadasenRing
		,DATEPART(YYYY, [date]) AS [year]
		,DATEPART(mm, [date]) AS [month]
		,DATEPART(dd, [date]) AS [day]
		,DATEPART(hh, [date]) AS [hour]
		,DATEPART(mi, [date]) AS [minutes]
		,sum(nserv) AS nserv
		,sum(nacw) AS nacw
		,sum(c.tAuxiliar) as tAuxiliar
	FROM #RepMKTIntervalosTiemposAcuTotalesTemp c
	LEFT JOIN ccinbound inb
		ON inb.Inbound_id = inboundId
	LEFT JOIN #timeDetailAgentFinal d(NOLOCK)
		ON d.IdCampEsp = c.inboundId
			AND d.timegroup = c.DATE
	GROUP BY [date]
		,inboundId
		,inb.descripcion
	HAVING sum(nacd) > 0
		OR sum(nabnd) > 0
		OR sum(tlog) > 0


	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL
		DROP TABLE #sessionTimeGroup;	

	IF OBJECT_ID(''tempdb..#RepMKTIntervalosTiemposAcuTotalesTemp'') IS NOT NULL
		DROP TABLE #RepMKTIntervalosTiemposAcuTotalesTemp
			
	IF OBJECT_ID(''tempdb..#timeDetailAgentFinal'') IS NOT NULL
		DROP TABLE #timeDetailAgentFinal		
END'
EXEC(@sql)

SET @process = 'KR123000 se crea la tabla RepSpecialStatusDetail '
SET @sql = 'IF NOT EXISTS (select * from sys.tables where name = N''RepSpecialStatusDetail'')
BEGIN
	CREATE TABLE [dbo].[RepSpecialStatusDetail](
	[date] [datetime] NOT NULL,
	[agentName] varchar(80) not null,
	[userId] [int] NOT NULL,
	[login] varchar(40) not null,
	[auxiliar] varchar(80) not null,
	[startDate] datetime not null,
	[endDate] datetime not null,
	[statusTimeAuxiliar] int not null,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL,
	[auxiliarId] int NOT NULL
	) ON [PRIMARY];

	CREATE INDEX IX_RepSpecialStatusDetail ON RepSpecialStatusDetail([date], userId, auxiliarId);
END'
EXEC(@sql)

SET @process = 'KR123000  se modifica el sp ccspRepSpecialStatusDetail'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepSpecialStatusDetail]
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
  DELETE FROM RepSpecialStatusDetail WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to

  ;WITH AuxiliarDetail
	AS (
		SELECT user_id, DATEADD(s, - tstatus, fecha) AS fechaInicio, fecha, tStatus, TipoAuxiliarReady_id		
		FROM ccLogAgentesAuxiliarReady
		WHERE fecha BETWEEN @from AND @to
		)
	
	INSERT INTO RepSpecialStatusDetail
	SELECT convert(DATE, fechaInicio, 121) [date],
			isNull(usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno + '' '' + usr.Nombres, ''systemTranslated_NoName'') AS [user],
			xdet.user_Id AS userId,
			isNull(usr.[Login], ''systemTranslated_NoUserName'') AS [login],
			isNull(tn.[Description], ''systemTranslated_NoStatus'') AS [status], 
			fechaInicio AS startDate, 
			fecha AS endDate, 
			convert(int,tStatus) AS statusTime,
			datepart(yyyy, fechaInicio) [year],
			datepart(mm, fechaInicio) [mounth],
			datepart(dd, fechaInicio) [day], datepart(hh, fechaInicio) [hour],
			datepart(mi, fechaInicio) 	[minute],
			tn.TipoReadyAuxiliar_Id		
	FROM AuxiliarDetail xdet
	LEFT JOIN ccUserView usr ON usr.user_id = xdet.user_id
	LEFT JOIN TipoReadyAuxiliar tn	ON tn.TipoReadyAuxiliar_Id = xdet.TipoAuxiliarReady_id
END'
EXEC(@sql)

SET @process = 'KR123000 se elimina la vista RepMKTIntervalosTiemposAcuTotalesView'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepMKTIntervalosTiemposAcuTotalesView'')
BEGIN
	DROP VIEW RepMKTIntervalosTiemposAcuTotalesView
END'
EXEC(@sql)

SET @process = 'KR123000 se crea la vista RepMKTIntervalosTiemposAcuTotalesView '
SET @sql = '
CREATE VIEW RepMKTIntervalosTiemposAcuTotalesView AS
	SELECT [date]
      ,[inboundId]
      ,[descripcion]
      ,[PromPosicionPersonal]
      ,[LlamadasRecibidas]
      ,[LlamadasAtendidas]
      ,[LlamadasAban]
      ,[tACD]
      ,[tACW]
      ,[tLogout]
      ,[tDescon]
      ,[tnotav]
      ,[TiempoDispo]
	  ,[tAuxiliar]
      ,[txfer]
      ,[tother]
      ,[tCliente]
      ,[tring]
      ,[tprob]
      ,[tManual]
      ,[timeretention]
      ,[LlamadasSalidaExt]
      ,[TiempoSalidaExt]
      ,[PorcNiveldeServicio4080]
      ,[AHT]
      ,[LlamadasRetenidas]
      ,[LlamadasenRing]
      ,[year]
      ,[month]
      ,[day]
      ,[hour]
      ,[minutes]
      ,[nserv]
      ,[nacw]
  FROM [dbo].[RepMKTIntervalosTiemposAcuTotales]'
EXEC(@sql)

SET @process = 'KR123000 se mofifica el sp ccspRepAgentCallStatusesByInterval'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

BEGIN
SET NOCOUNT ON

if @from is null
	select @from = CONVERT(datetime, convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 begin

	select @from as [from], @to as [to]
	
	IF OBJECT_ID(N''tempdb..#tempNotReady'', N''U'') IS NOT NULL  drop table #tempNotReady
	IF OBJECT_ID(N''tempdb..#tempNotReady2'', N''U'') IS NOT NULL  drop table #tempNotReady2
	IF OBJECT_ID(N''tempdb..#tempAuxiliarReady'', N''U'') IS NOT NULL  drop table #tempAuxiliarReady
	IF OBJECT_ID(N''tempdb..#tempAuxiliarReady2'', N''U'') IS NOT NULL  drop table #tempAuxiliarReady2

	declare @valuenav varchar(100)
	declare @tnav int, @twbCall int
	
	select @valuenav = valor from ccSettings where setting_id = 40

	select @tnav = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 1
	select @twbCall = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 2

	
	--Tiempos del agente en not ready	
	create table #tempNotReady (userId int not null,
	dateStart datetime null, dateEnd datetime null,
	timegroup datetime null, timegroup_next datetime null, tnav int null, twbcall int null)

		-----------------------------------------------------------------------------------

	--Columnas Tiempo en capacitaci?n (ND) = tnav, Tiempo en ?trabajo previo a llamada? = twbcall
	;with notReadyTmp as(
	
	select User_id as userId,TipoNotReady_id,tStatus
	, DATEADD(ss,-tStatus,fecha)as dateStart, fecha as dateEnd
	, dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha), 0) AS timegroup
	, dbo.GetTimeGroup(fecha, 1) AS timegroup_next
	from cclogagentesnotready
	WHERE fecha between @from AND @to and TipoNotReady_id in (@tnav,@twbCall)
	)

	insert into #tempNotReady 
	select userId,dateStart,dateEnd,timegroup,timegroup_next,
	case when TipoNotReady_id=@tnav then tStatus else 0 end tnav,
	case when TipoNotReady_id=@twbCall then tStatus else 0 end twbcall
	from notReadyTmp

	select * into #tempNotReady2 from #tempNotReady where datediff(mi,timegroup,timegroup_next)>15
	delete #tempNotReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #tempNotReady 
	select userId,dateStart,dateEnd,th.start as timegroup,th.stop as timegroup_next
	,case when tnav>0 then dbo.TimeInterval(th.start,th.stop,dateStart,dateEnd) else 0 end as tnav
	,case when twbcall>0 then dbo.TimeInterval(th.start,th.stop,dateStart,dateEnd) else 0 end as twbcall
	from #tempNotReady2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	--------------------------------------------------------------------------------------------
	
	--Tiempos del agente en auxiliar	
	create table #tempAuxiliarReady (userId int not null,
	dateStart datetime null, dateEnd datetime null,
	timegroup datetime null, timegroup_next datetime null, tipoAuxiliarReady_id int null, tStatus int null)

	-----------------------------------------------------------------------------------
	;with auxiliarReadyTmp as(
	
	select User_id as userId,TipoAuxiliarReady_id,tStatus
	, DATEADD(ss,-tStatus,fecha)as dateStart, fecha as dateEnd
	, dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha), 0) AS timegroup
	, dbo.GetTimeGroup(fecha, 1) AS timegroup_next
	from ccLogAgentesAuxiliarReady
	WHERE fecha between @from AND @to
	)

	insert into #tempAuxiliarReady 
	select userId,dateStart,dateEnd,timegroup,timegroup_next, TipoAuxiliarReady_id, tStatus
	from auxiliarReadyTmp

	select * into #tempAuxiliarReady2 from #tempAuxiliarReady where datediff(mi,timegroup,timegroup_next)>15
	delete #tempAuxiliarReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #tempAuxiliarReady 
	select userId,dateStart,dateEnd,th.start as timegroup,th.stop as timegroup_next
	,tipoAuxiliarReady_id
	,dbo.TimeInterval(th.start,th.stop,dateStart,dateEnd) as tStatus
	from #tempAuxiliarReady2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------------------------------

	delete RepAgentCallStatusesByInterval where date >= @from AND date < @to
	
	-----------------------------------------------------------------------------------------------------------------------------------
	; with  timeDetailAgent as(

	select timeGroup,userId
	,isnull(sum(case when TipoStatusAge_id=3 then tStatus else 0 end),0) as readyTime
	,isnull(sum(case when TipoStatusAge_id=7 then tStatus else 0 end),0)  as tother

	from tmpccLogAgentesDia 
	group by timeGroup,userId
	), outCall as(
	select timegroup, user_id as userId ,tnotes as twrapup, tring,cal_id
	from tmpTimesOutboundData

	), TransferCall as (

	select A.timegroup, A.user_id as userId
	,isnull(sum(B.tAntesXfer + B.tDespuesXfer),0)  as tcallTransf  
	from tmpTimesOutboundData A
	inner join TmpTimesccLogtransfers B on A.cal_id=B.callId and A.timegroup=B.timegroup and  B.Tipo=2 and B.modo <> 6
	group by A.timegroup, A.user_id 
	), NotReady as(
		select userId,timegroup,sum(tnav) as tnav,sum(twbcall) as twbcall from #tempNotReady
		group by userId,timegroup
	), AuxiliarReady as (
		select 	userId, timegroup, tipoAuxiliarReady_id,
		ISNULL(tra.[Description], '''') as [description],
		tStatus as [time]
		from #tempAuxiliarReady tar
		INNER JOIN TipoReadyAuxiliar tra on tra.TipoReadyAuxiliar_Id =  tar.tipoAuxiliarReady_id
		--GROUP BY userId, timegroup, tipoAuxiliarReady_id, [Description], t
	)

	insert into RepAgentCallStatusesByInterval
	select A.timegroup as [date],A.user_id as userId
	,U.login as [agentName]
	,A.timegroup as [startInterval],A.timegroup_next as endInterVal
	,isnull(B.readyTime,0) as readyTime
	,isnull(B.tother,0) as tother
	,isnull(n.tnav,0) as tnav
	,isnull(C.twrapup,0) as twrapup
	,isnull(C.tring,0) as tring
	,isnull(T.tcallTransf,0) as tcallTransf
	,isnull(n.[twbCall],0) as [twbCall]
	,datepart(yyyy,A.timegroup) [year]
	,datepart(mm,A.timegroup) [mounth]
	,datepart(dd,A.timegroup) [day]
	,datepart(hh,A.timegroup) [hour]
	,datepart(mi,A.timegroup) [minute]
	,ISNULL(AR.tipoAuxiliarReady_id, 0) tipoAuxiliarReady_id
	,ISNULL(AR.[description], '''') AS [description]
	,ISNULL(AR.[description], '''') + ''_Time'' as [description_time]
	,ISNULL(AR.[time],0) as [time]
	from TmpSessionTimeGroup A
	inner join ccUserView U on A.User_id = U.User_id
	left join timeDetailAgent B on A.timegroup=B.timegroup and A.user_id=B.userId
	left join outCall C on A.timegroup=C.timegroup and A.user_id=C.userId
	left join TransferCall T on A.timegroup=T.timegroup and A.user_id=T.userId
	left join NotReady n  on A.timegroup=n.timegroup and A.user_id=n.userId
	left join AuxiliarReady AR on A.timegroup = AR.timegroup and A.user_id = AR.userId
	order by [date],userId	   
	

	---DROP TABLES TEMP
	IF OBJECT_ID(N''tempdb..#tempNotReady'', N''U'') IS NOT NULL  drop table #tempNotReady
	IF OBJECT_ID(N''tempdb..#tempNotReady2'', N''U'') IS NOT NULL  drop table #tempNotReady2
	IF OBJECT_ID(N''tempdb..#tempAuxiliarReady'', N''U'') IS NOT NULL  drop table #tempAuxiliarReady
	IF OBJECT_ID(N''tempdb..#tempAuxiliarReady2'', N''U'') IS NOT NULL  drop table #tempAuxiliarReady2

	end
end'
EXEC(@sql)



-------------------
SET @process = 'KR123000 se realiza la inserción en la tabla PivotReports'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM PivotReports where id = 2120)
BEGIN
	INSERT INTO PivotReports (id, columns, complementColumns, pivotFunction, isGroupPivot)
		VALUES (2120, ''descripcion_count|descripcion_time'', ''Date|AgentName|userId|Login|SessionTime'', ''max'', 1);
END'
EXEC(@sql)

SET @process = 'KR123000 se realiza la inserción en la tabla ReportsFilters'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportsFilters where id = 2120)
BEGIN
	insert into ReportsFilters (reportName, filterName, id)
		values (''Auxiliaries by agents use'', ''users'', 2120), (''Auxiliaries by agents use'', ''auxiliar'', 2120)
END'
EXEC(@sql)

SET @process = 'KR123000 se realiza la inserción a la tabla ReportsFiltersMenus '
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportsFiltersMenus where idReport = 2120)
BEGIN
	INSERT INTO ReportsFiltersMenus (idReport, filterMenuName, showFilter)
		VALUES (2120, ''date'', 1),  (2120, ''filterby'', 1)
END'
EXEC(@sql)

SET @process = 'KR123000 se realiza la inserción a la tabla ReportsTotals'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportsTotals where id = 2120)
BEGIN
	INSERT INTO ReportsTotals 
		VALUES (2120,''sum:sessionTime'')
END'
EXEC(@sql)

SET @process = 'KR123000 se realiza la creación de la tabla RepAuxiliariesByAgentDet'
SET @sql = 'IF NOT EXISTS(select * FROM sys.tables where name = ''RepAuxiliariesByAgentDet'')
BEGIN
	create TABLE RepAuxiliariesByAgentDet (
	Date datetime,
	AgentName varchar(80),
    	userId smallint,
    	Login varchar(40),
    	SessionTime time,
	descripcion varchar(50),
	descripcion_count varchar(50),
	count smallint,
	descripcion_time varchar(50),
	time int,
	auxiliarId int
);

CREATE INDEX IX_RepAuxiliariesByAgentDet_I
ON RepAuxiliariesByAgentDet (date, userId, auxiliarId);
END
'
EXEC(@sql)

SET @process = 'KR123000 se modifica el sp ccspRepAuxiliariesByAgentDet'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepAuxiliariesByAgentDet] @action AS TINYINT = null, @from AS DATETIME = null, @to AS DATETIME = null
AS

exec ccspRepSpecialStatusDetail @action= 1, @from = @from	,@to = @to

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

IF OBJECT_ID(''tempdb..#auxReady'') IS NOT NULL
	DROP TABLE #auxReady
IF OBJECT_ID(''tempdb..#auxReady2'') IS NOT NULL
	DROP TABLE #auxReady2;

IF @action = 1
BEGIN

WITH auxReadyDetail
AS (
select userId,startDate,endDate,statusTimeAuxiliar as tStatus, auxiliar	
,convert(DATETIME, convert(VARCHAR(13), startDate, 121) + '':00:00'', 121) AS timegroup 
,convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, endDate), 121) + '':00:00'', 121) AS timegroup_next
,auxiliarId
from RepSpecialStatusDetail with(nolock) where startDate between @from and @to 
)

SELECT timegroup, timegroup_next, userId, auxiliar, tStatus AS [time], startDate, endDate, 1 AS [count],auxiliarId
INTO #auxReady
FROM auxReadyDetail 

SELECT *
INTO #auxReady2
FROM #auxReady WHERE DATEDIFF(hh, timegroup, timegroup_next) > 1

DELETE #auxReady
WHERE datediff(HH, timegroup, timegroup_next) > 1	
; 

DELETE FROM RepAuxiliariesByAgentDet WITH (ROWLOCK) WHERE Date >= @from AND Date <  @to;

;WITH timebyHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), Start, 121) + '':00:00'', 121) AS [start]
	, convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + '':00:00'', 121) AS [stop]
	FROM TmpTimesInterval 
	GROUP BY convert(VARCHAR(13), Start, 121), convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + '':00:00'', 121)
	), auxByHour
AS (
	SELECT th.start AS timegroup, th.stop AS timegroup_next, userId, auxiliar, dbo.TimeInterval(th.start, th.stop, startDate, endDate) AS [time], startDate, endDate, dbo.AccountInterval(th.start, th.stop, 
			startDate, endDate, [count]) AS [count]
			,auxiliarId
	FROM #auxReady2 t
	INNER JOIN timebyHour th
	ON (t.timegroup > th.Start AND t.timegroup < th.stop) OR th.Start BETWEEN t.timegroup AND t.timegroup_next
	WHERE datediff(ss, th.start, timegroup_next) > 0
	)

	insert into #auxReady
	select * from auxByHour

	delete from RepAuxiliariesByAgentDet where [date] between @from and @to
	
	;with auxGroupbyHour as(
		select timegroup,userId,auxiliar,SUM(time) as time, 
		SUM(count) as [count]
		,auxiliarId
		from #auxReady
		group by timegroup,userId,auxiliar,auxiliarId		
	)
	,timeSessionByHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + '':00:00'', 121) AS timegroup, user_id AS userId, sum(tlog) AS tlog
	FROM TmpSessionTimeGroup 
	GROUP BY convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + '':00:00'', 121), user_id
	)

insert into RepAuxiliariesByAgentDet
SELECT A.timegroup as Date
, uv.Nombres + '' '' + uv.apellidopaterno  AS AgentName
, A.userId
,uv.[Login] as Login
, A.tlog AS sessionTime
, isnull(auxReady.auxiliar ,'''') as descripcion
, isnull(d.Description, '''') + ''_Count'' AS descripcion_count
, isnull(auxReady.[count], 0) [count]
, isnull(d.Description, '''') + ''_Time'' AS descripcion_time
, isnull(auxReady.TIME, 0) AS [time]
, isnull(auxReady.auxiliarId,0) auxiliarId
FROM timeSessionByHour A
INNER JOIN ccUserView uv ON A.userId = uv.User_id
LEFT JOIN auxGroupbyHour auxReady	ON auxReady.userId = A.userId AND A.timegroup = auxReady.timegroup 
LEFT JOIN TipoReadyAuxiliar d	ON auxReady.auxiliar = d.Description
select * from RepAuxiliariesByAgentDet where Date between @from and @to

IF OBJECT_ID(''tempdb..#auxReady'') IS NOT NULL
	DROP TABLE #auxReady

IF OBJECT_ID(''tempdb..#auxReady2'') IS NOT NULL 
	DROP TABLE #auxReady2
end'

EXEC(@sql)


SET @process = 'KR123000 se actualiza la tabla groupbyreports'
SET @sql = 'update groupbyreports 
set columns = ''userId|max([user]):user|max([login]):login|sum([tlog]):tlog|sum([tunknown]):tunknown|sum([tav]):tav|sum([tnotav]):tnotav|sum([tother]):tother|sum([tprob]):tprob|sum([tChatting]):tChatting|sum([tManual]):tManual|sum([tundefined]):tundefined|sum([tauxiliarready]):tauxiliarready|sum([nxferin]):nxferin|sum([nanswerin]):nanswerin|sum([nabndxferin]):nabndxferin|sum([nabndringin]):nabndringin|sum([nabnddlgin]):nabnddlgin|sum([abndaxferin]):abndaxferin|sum([nnoanswerin]):nnoanswerin|sum([nlostin]):nlostin|sum([tdialogin]):tdialogin|sum([tnotesin]):tnotesin|sum([tringin]):tringin|sum([txferin]):txferin|sum([nxferout]):nxferout|sum([nanswerout]):nanswerout|sum([nabndxferout]):nabndxferout|sum([nabndringout]):nabndringout|sum([nabnddlgout]):nabnddlgout|sum([abndaxferout]):abndaxferout|sum([nnoanswerout]):nnoanswerout|sum([nlostout]):nlostout|sum([tdialogout]):tdialogout|sum([tnotesout]):tnotesout|sum([tringout]):tringout|sum([txferout]):txferout|sum([nother]):nother|sum([nmohin]):nmohin|sum([nmohout]):nmohout|sum([nwhagin]):nwhagin|sum([nwhagout]):nwhagout|sum([nwhcliin]):nwhcliin|sum([nwhcliout]):nwhcliout|isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout])_0)_0):tnotavg''
where id = 2010'
	EXEC(@sql)

SET @process = 'KR123000 se actualiza la tabla ReportsTotals'
SET @sql = 'update ReportsTotals
set totalColumns = ''sum:tauxiliarready|sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout]),0),0)''
where id = 2010'
	EXEC(@sql)

SET @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
		SET @sql = 'if not exists (select * from sys.columns where name = N''tauxiliarready'' and Object_ID = Object_ID(N''RepAgentGI''))
    begin
        ALTER TABLE RepAgentGI  ADD tauxiliarready smallint  NULL 
    end';

EXEC (@sql);

set @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
	set @sql = 'update RepAgentGI set [tauxiliarready]=0 where [tauxiliarready] is null'
	EXEC(@sql)

SET @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepAgentGI] 
@action AS TINYINT ,@from AS DATETIME ,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
	SELECT @to = GETDATE();

IF @action = 1
BEGIN
	
	DELETE	FROM RepAgentGI	WHERE DATE >= @from	AND DATE < @to

	;with timeDetailAgent as(	
	SELECT userId, timegroup		
		,sum(CASE WHEN tipostatusage_id = 1 THEN tStatus ELSE 0 END) tunknown
		,sum(CASE WHEN tipostatusage_id = 2 THEN tStatus ELSE 0 END) tNotReady
		,sum(CASE WHEN tipostatusage_id IN (3, 31) THEN tStatus ELSE 0 END) tReady 	--3	Ready y 31	Ready PreviewPro	
		,sum(CASE WHEN tipostatusage_id IN (11, 25, 26, 27) THEN tStatus ELSE 0 END) tprob --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida		
		,sum(CASE WHEN tipostatusage_id = 7 THEN tStatus ELSE 0 END) tother
		,sum(CASE WHEN tipostatusage_id = 7 THEN 1 ELSE 0 END) nother
		,sum(CASE WHEN tipostatusage_id = 21 THEN tStatus ELSE 0 END) tmanualcall		
		,sum(CASE WHEN tipostatusage_id IN (23, 24) THEN tStatus ELSE 0 END) AS tchatting
		,sum(CASE WHEN tipostatusage_id = 30 THEN tStatus ELSE 0 END) AS tReconnectKolob
		,sum(CASE WHEN tipostatusage_id = 32 THEN tStatus ELSE 0 END) AS tPreview
		,sum(CASE WHEN tipostatusage_id = 33 THEN tStatus ELSE 0 END) AS tAssisted
		,sum(CASE WHEN tipostatusage_id = 34 THEN tStatus ELSE 0 END) AS tDialogoWhatsApp
		,sum(CASE WHEN A.TipoStatusAge_id = 37 THEN A.tStatus ELSE 0 END) AS tAuxiliarReady
		FROM tmpccLogAgentesDia A
		group by A.userId,A.timegroup
	)	
	,inboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,sum(nxfer) AS nxferin
			,sum(nanswer) AS nanswerin
			,sum(nabnd_xfer) AS nabndxferin
			,sum(nabnd_ring) AS nabndringin
			,sum(nabnd_dialog) AS nabnddlgin
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
			,sum(nno_answer) AS nnoanswerin
			,sum(nlost) AS nlostin
			,sum(nMoh) AS nMohIn
			,sum(nWHag) AS nWHagIn
			,sum(nWHcl) AS nWHclIn
			,sum(tdialog) AS tdialogIn
			,sum(tnotes) AS tnotesIn
			,sum(tring) AS tringIn
			,sum(txfer) AS txferIn			
		FROM tmpTimesInboundData
		WHERE user_id > 0
		group by timegroup,user_id
		)
		,outboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,sum(nxfer) AS nxferOut
			,sum(nanswer) AS nanswerOut
			,sum(nabnd_xfer) AS nabndxferOut
			,sum(nabnd_ring) AS nabndringOut
			,sum(nabnd_dialog) AS nabnddlgOut
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
			,sum(nno_answer) AS nnoanswerOut
			,sum(nlost) AS nlostOut
			,sum(nMoh) AS nMohOut
			,sum(nWHag) AS nWHagOut
			,sum(nWHcl) AS nWHclOut
			,sum(tdialog) AS tdialogOut
			,sum(tnotes) AS tnotesOut
			,sum(tring) AS tringOut
			,sum(txfer) AS txferOut			
		FROM tmpTimesOutboundData
		WHERE user_id > 0
			AND cal_manual IN (0, 2, 3)
			group by timegroup,user_id
		)
	
	INSERT INTO RepAgentGI
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,A.tlog
		,isnull(atgStatus.tunknown,0) as tunknown
		,isnull(atgStatus.tReady,0) as tReady
		,isnull(atgStatus.tNotReady,0) as tNotReady
		,isnull(atgStatus.tother,0) as tother
		,isnull(atgStatus.tprob,0) as tprob
		,isnull(atgStatus.tchatting,0) as tchatting
		,isnull(A.tlog-( 
		isnull(atgStatus.tunknown+atgStatus.tReady+atgStatus.tNotReady+atgStatus.tother+atgStatus.tprob+atgStatus.tchatting+atgStatus.tmanualcall+ atgStatus.tAuxiliarReady,0)
		+isnull( txferin+tringin+tdialogin+tnotesIn,0)
		+isnull(txferout+tringout+tdialogout+tnotesout,0)
		
		),0) as tundefined
		
		---------------- Count IN Call -----------------------
		,ISNULL(inCount.nxferin, 0) nXferIn
		,ISNULL(inCount.nanswerin, 0) nAnswerIn
		,ISNULL(inCount.nabndxferin, 0) nAbndXferIn
		,ISNULL(inCount.nabndringin, 0) nAbndRingIn
		,ISNULL(inCOunt.nabnddlgin, 0) AS nAbnddlgIn
		,ISNULL(inCount.abndaxferin, 0) abndaXferIn
		,ISNULL(inCount.nnoanswerin, 0) AS nnoAnswerIn
		,ISNULL(inCount.nlostIn, 0) AS nlostIn
		,isnull(inCount.tdialogIn, 0) AS tdialogIn
		,isnull(inCount.tnotesIn, 0) tnotesIn
		,isnull(inCount.tringIn, 0) tringIn
		,isnull(inCount.txferIn, 0) txferIn

		---------------- Count Out Call -----------------------      
		,isnull(outTime.nXferOut, 0) nXferOut
		,isnull(outTime.nAnswerOut, 0) nAnswerOut
		,isnull(outTime.nAbndXferOut, 0) nAbndXferOut
		,isnull(outTime.nAbndRingOut, 0) nAbndRingOut
		,isnull(outTime.nAbnddlgOut, 0) AS nAbnddlgOut
		,isnull(outTime.abndaXferOut, 0) abndaXferOut
		,isnull(outTime.nnoAnswerOut, 0) AS nnoAnswerOut
		,isnull(outTime.nlostOut, 0) AS nlostOut
		,ISNULL(outTime.tdialogOut, 0) tdialogOut
		,ISNULL(outTime.tnotesOut, 0) tnotesOut
		,ISNULL(outTime.tringOut, 0) tringOut
		,ISNULL(outTime.txferOut, 0) txferOut
		
		---------------- Time Agent Common -----------------------      
		,ISNULL(atgStatus.nother,0) nOther
		
		---------------- Count In/Out Call-----------------------      
		,isnull(inCount.nMohIn, 0) AS nMohIn
		,isnull(outTime.nMohOut, 0) AS nMohOut
		,isnull(inCount.nWHagIn, 0) AS nWHagIn
		,isnull(outTime.nWHagOut, 0) AS nWHagOut 
		,isnull(inCount.nWHclIn, 0) AS nWHclIn
		,isnull(outTime.nWHclOut, 0) AS nWHclOut				

		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,isnull(atgStatus.tmanualcall,0) as tmanualcall
		,isnull(atgStatus.tAuxiliarReady,0) as tAuxiliarReady 
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	left join timeDetailAgent as atgStatus on atgStatus.userId=A.user_id and atgStatus.timegroup=A.timegroup
	LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	left join outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id	
END;'
EXEC(@sql)

SET @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepViewAgentGI'')
BEGIN
	DROP VIEW RepViewAgentGI
END
'
EXEC(@sql)

SET @process = 'KR123017 se crea la vista  RepViewAgentGI'
SET @sql = '
CREATE VIEW [dbo].[RepViewAgentGI] AS
SELECT date,
       userId,
       [user],
       login,
       tlog,
       tunknown,
       tav,
       tnotav,
       tother,
       tprob,
       tChatting,
       tundefined,
       tauxiliarready,
       nxferin,
       nanswerin,
       nabndxferin,
       nabndringin,
       nabnddlgin,
       abndaxferin,
       nnoanswerin,
       nlostin,
       tdialogin,
       tnotesin,
       tringin,
       txferin,
       nxferout,
       nanswerout,
       nabndxferout,
       nabndringout,
       nabnddlgout,
       abndaxferout,
       nnoanswerout,
       nlostout,
       tdialogout,
       tnotesout,
       tringout,
       txferout,
       nother,
       nmohin,
       nmohout,
       nwhagin,
       nwhagout,
       nwhcliin,
       nwhcliout,
       year,
       month,
       day,
       hour,
       minutes,
       tManual FROM RepAgentGI
'
EXEC(@sql)


SET @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepViewAgentGISpecial'')
BEGIN
	DROP VIEW RepViewAgentGISpecial
END
'
EXEC(@sql)

SET @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
SET @sql = '
CREATE VIEW [dbo].[RepViewAgentGISpecial] AS
SELECT date,
userId,
login,
[user],
tnotesout AS tnotesoutNum,
tdialogout AS tdialogoutxxx,
tringout AS tringoutxxx,
txferout AS txferoutxxx,
tunknown AS tunknownxxx,
tother AS totherxxx,
tprob AS tprobxxx,
tundefined AS tundefinedxxx,
tav AS tavNum,
0.0 AS tTalkNum,
tnotav AS tnotavNum,
tauxiliarready AS tauxNum,
0.0 AS TotalNum,
year,month,day,hour,minutes FROM RepAgentGI
'
EXEC(@sql)

SET @process = 'KR123017 - Auxiliar - Reporte Información General (Especial)'
SET @sql = 'UPDATE dbo.GroupByReports 
SET columns = ''userId|max([user]):user|max([login]):login|[dbo].[FNTruncateToDecimal]((sum([tdialogoutxxx])+sum([tringoutxxx])+sum([txferoutxxx])+sum([tunknownxxx])+sum([totherxxx])+sum([tprobxxx])+sum([tundefinedxxx]))):tTalkNum|[dbo].[FNTruncateToDecimal](sum([tnotesoutNum])):tnotesoutNum|[dbo].[FNTruncateToDecimal](sum([tavNum])):tavNum|[dbo].[FNTruncateToDecimal](sum([tnotavNum])):tnotavNum|[dbo].[FNTruncateToDecimal](sum([tauxNum])):tauxNum|[dbo].[FNTruncateToDecimal]((sum([tdialogoutxxx])+sum([tringoutxxx])+sum([txferoutxxx])+sum([tunknownxxx])+sum([totherxxx])+sum([tprobxxx])+sum([tundefinedxxx]))+(sum([tnotesoutNum]))+(sum([tavNum]))+(sum([tnotavNum]))+(sum([tauxNum]))):TotalNum''
WHERE id = 2090;
'
EXEC(@sql)

SET @process = 'KR123000 se modifica el sp ccspRepSpececialAgent'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepSpececialAgent] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
IF @action = 1
BEGIN
	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	DELETE RepSpececialAgent	WHERE [date] BETWEEN @from			AND @to

	;WITH outCall
	AS (
		SELECT convert([date], timegroup, 121) [date]
			,User_id AS userId
			,COUNT(CASE WHEN statuscall_id >= 10
						AND ntotal > 0 THEN 1 ELSE NULL END) AS ncalls
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) nabnd
			,sum(nanswer) AS nanswer
			,COUNT(CASE WHEN statuscall_id = 13
						AND ntotal > 0
						AND (
							calif_id IS NULL
							OR calif_id = 0
							) THEN 1 ELSE NULL END) AS nocalif
		FROM tmpTimesOutboundData
		GROUP BY convert([date], timegroup, 121)
			,User_id
		)
		,inCall
	AS (
		SELECT convert([date], timegroup, 121) [date]
			,User_id AS userId
			,COUNT(CASE WHEN statuscall_id >= 10
						AND ntotal > 0 THEN 1 ELSE NULL END) AS ncalls
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) nabnd
			,sum(nanswer) AS nanswer
			,COUNT(CASE WHEN statuscall_id = 13
						AND ntotal > 0
						AND (
							calif_id IS NULL
							OR calif_id = 0
							) THEN 1 ELSE NULL END) AS nocalif
		FROM tmpTimesInboundData
		GROUP BY convert([date], timegroup, 121)
			,User_id
		)
		,AgentGI
	AS (
		SELECT convert([date], [date], 121) [date]
			,userId
			,[user]
			,[login]
			,sum(tlog) [session]
			,sum(tnotav) ndTime
			,sum(tdialogin + tnotesin + tdialogout + tnotesout) dialogTime
			,sum(tauxiliarready) as tauxiliarready
		FROM RepAgentGI WITH (NOLOCK)
		WHERE [date] BETWEEN @from
				AND @to
		GROUP BY convert([date], [date], 121)
			,userId
			,[user]
			,[login]
		)
		,ses
	AS (
		SELECT convert([date], [date], 121) [date]
			,userId
			,min(logintime) loginTime
			,max(logouttime) logoutTime
		FROM RepAgentsession WITH (NOLOCK)
		WHERE [date] BETWEEN @from
				AND @to
		GROUP BY convert([date], [date], 121)
			,userId
		)
	INSERT RepSpececialAgent
	SELECT A.[date]
		,A.userId
		,A.[user]
		,A.[login]
		,A.[session]
		,ses.loginTime
		,ses.logoutTime
		,A.dialogTime
		,A.ndTime
		,ISNULL(cout.ncalls, 0) callsOut
		,ISNULL(cin.ncalls, 0) callsIn
		,isnull(cout.nabnd, 0) + isnull(cin.nabnd, 0) AS abandonedCalls
		,ISNULL(cout.nanswer, 0) + ISNULL(cin.nanswer, 0) nanswer2
		,ISNULL(cout.nocalif, 0) + ISNULL(cin.nocalif, 0) unrated
		,isnull(A.tauxiliarReady,0) as tauxiliarready
	FROM AgentGI A
	INNER JOIN ses ON ses.[date] = A.[date]
		AND ses.userId = A.userId
	LEFT JOIN outCall cout ON cout.[date] = A.[date]
		AND cout.userId = A.userId
	LEFT JOIN inCall cin ON cin.[date] = A.[date]
		AND cin.userId = A.userId
END
'
	EXEC(@sql)


SET @process = 'KR123000 se agrega la columna tauxiliarready a la tabla RepSpececialAgent'
SET @sql = 'if not exists (select * from sys.columns where name = N''tauxiliarready'' and Object_ID = Object_ID(N''RepSpececialAgent''))
begin
ALTER TABLE RepSpececialAgent  ADD tauxiliarready smallint  NULL 

update RepSpececialAgent set [tauxiliarready]=0 where [tauxiliarready] is null
end';

EXEC (@sql);

SET @process = 'KR123000 se elimina la vista RepViewSpececialAgent'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepViewSpececialAgent'')
BEGIN
	DROP VIEW RepViewSpececialAgent
END'

EXEC(@sql)

SET @process = 'KR123000 se crea la vista RepViewSpececialAgent'
SET @sql = 'CREATE VIEW [dbo].[RepViewSpececialAgent] AS
SELECT date,
    userId,
    [user],
    login,
    sessionTime,
    loginTime,
    logoutTime,
    dialogTime,
    ndTime,
    tauxiliarready,
    callsOut,
    callsIn,
    abandonedCalls,
    nanswer2,
    unrated FROM RepSpececialAgent'

EXEC(@sql)



--------------



SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
		SET @sql = 'if not exists (select * from sys.columns where name = N''auxiliaryReadyTime'' and Object_ID = Object_ID(N''RepDetailAgent''))
    begin
        ALTER TABLE RepDetailAgent  ADD auxiliaryReadyTime int  NULL 
    end';

EXEC (@sql);

set @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
	set @sql = 'update RepDetailAgent set [auxiliaryReadyTime]=0 where [auxiliaryReadyTime] is null'
	EXEC(@sql)


SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
		SET @sql = 'if not exists (select * from sys.columns where name = N''readyTime'' and Object_ID = Object_ID(N''RepDetailAgent''))
    begin
        ALTER TABLE RepDetailAgent  ADD readyTime int  NULL 
    end';

EXEC (@sql);

set @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
	set @sql = 'update RepDetailAgent set [readyTime]=0 where [readyTime] is null'
	EXEC(@sql)

	SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
		SET @sql = 'if not exists (select * from sys.columns where name = N''otherTime'' and Object_ID = Object_ID(N''RepDetailAgent''))
    begin
        ALTER TABLE RepDetailAgent  ADD otherTime int  NULL 
    end';

EXEC (@sql);

set @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
	set @sql = 'update RepDetailAgent set [otherTime]=0 where [otherTime] is null'
	EXEC(@sql)

	SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
		SET @sql = 'if not exists (select * from sys.columns where name = N''auxiliaryReadyPercent'' and Object_ID = Object_ID(N''RepDetailAgent''))
    begin
        ALTER TABLE RepDetailAgent  ADD auxiliaryReadyPercent float  NULL 
    end';

EXEC (@sql);

set @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
	set @sql = 'update RepDetailAgent set [auxiliaryReadyPercent]=0 where [auxiliaryReadyPercent] is null'
	EXEC(@sql)

	SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
		SET @sql = 'if not exists (select * from sys.columns where name = N''unavaiblePercent'' and Object_ID = Object_ID(N''RepDetailAgent''))
    begin
        ALTER TABLE RepDetailAgent  ADD unavaiblePercent float  NULL 
    end';

EXEC (@sql);

set @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
	set @sql = 'update RepDetailAgent set [unavaiblePercent]=0 where [unavaiblePercent] is null'
	EXEC(@sql)

	SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
		SET @sql = 'if not exists (select * from sys.columns where name = N''otherPercent'' and Object_ID = Object_ID(N''RepDetailAgent''))
    begin
        ALTER TABLE RepDetailAgent  ADD otherPercent float  NULL 
    end';

EXEC (@sql);

set @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
	set @sql = 'update RepDetailAgent set [otherPercent]=0 where [otherPercent] is null'
	EXEC(@sql)


SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepDetailAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

declare @califout int , @califin int
declare @var varchar(100)

BEGIN
SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to =getdate()

if @action=1 begin

    
set @califout =1
set @califin =1

select @var= valor from ccsettings where setting_id = 39
select @califout = Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=1
select @califin =  Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=2

delete from RepDetailAgent where date>=@from and date<@to

 ;with notReady as(
 select A.date,A.userId,SUM(A.timeSeconds) as tnot_av
 from RepAgentNotReady A 
 where A.date between @from and @to
 group by A.date,A.userId
 ) , AgentSession as (
 select A.userId,A.login as [user],A.[user] as [userName]
 ,convert(datetime,convert(varchar(14),A.date,121)+''00:00'',121) as [date]
 ,sum(A.sessionTime) as sessionTime
 from RepAgentSessionByInterval A
 where A.date between @from and @to
 group by A.userId,A.login ,A.[user],convert(datetime,convert(varchar(14),A.date,121)+''00:00'',121)
 ), callDataOut as(
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,A.User_id as UserId,sum(A.txfer) as txfer,sum(A.tring) as tring  ,sum(A.tdialog) as tdialog
 ,sum(A.tnotes) as tnotes, SUM(ntotal) as ntotal
 ,count(case when A.calif_id = @califout then 1 else null end) as completeOut --Revisar el calificacionId
 from tmpTimesOutboundData A
 where A.cal_manual in(0,2)
 group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),A.User_id
 ), callDataIn as(
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,A.User_id as UserId,sum(A.txfer) as txfer,sum(A.tring) as tring  ,sum(A.tdialog) as tdialog
 ,sum(A.tnotes) as tnotes, SUM(ntotal) as ntotal
 ,count(case when A.calif_id = @califin then 1 else null end) as completeIn --Revisar el calificacionId
 from tmpTimesInboundData A
 group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),A.User_id
 ),timeAgent as(  
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,userId
 ,sum(case when TipoStatusAge_id =3 then tStatus else 0 end) tav
 ,sum(case when TipoStatusAge_id =37 then tStatus else 0 end) tauxReady
 ,sum(case when TipoStatusAge_id =1 then tStatus else 0 end) tunknown
 ,sum(case when TipoStatusAge_id =7 then tStatus else 0 end) tother
 ,sum(case when TipoStatusAge_id =8 then tStatus else 0 end) tclient
 from tmpccLogAgentesDia A
where TipoStatusAge_id>0
group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),userId
 )
 , callData as(   
 select isnull(callOut.date,callIn.date) as [date],isnull(callOut.userId,callIn.UserId) as UserId
 ,isnull(callOut.txfer,0) +isnull(callIn.txfer,0) as txfer
 ,isnull(callOut.tring,0) +isnull(callIn.tring,0) as tring
 ,isnull(callOut.tdialog,0) +isnull(callIn.tdialog,0) as tdialog
 ,isnull(callOut.tnotes,0) +isnull(callIn.tnotes,0) as tnotes
 ,isnull(callOut.ntotal,0)+isnull(callIn.ntotal,0) as ntotal 
 ,isnull(callOut.completeOut,0)+isnull(callIn.completeIn,0) as  [complete]
 from callDataOut callOut
 full outer join callDataIn callIn on callOut.[date]=callIn.[date] and callOut.UserId=callIn.userId
 )

 insert into RepDetailAgent
 select A.userId,A.[user],A.userName,A.[date],A.sessionTime
 ,A.sessionTime - isnull(B.tnot_av,0) as [activeTime]
 ,isnull(C.tdialog+C.tnotes,0) as [talkingtTime]
 ,isnull(C.txfer+C.tring,0) as [holdTime]
 ,isnull(B.tnot_av,0) as [unavaibleTime]
 ,convert ( decimal(18,3),  isnull(C.tdialog*1.0 ,0)/36.0 ) as [talkingPercent]
 ,convert ( decimal(18,3),  isnull((C.txfer+C.tring)*1.0 ,0)/36.0 ) as [waitpercent]
 ,convert ( decimal(18,3), isnull(t.tav *1.0,0) /36.0 ) as [readyPercent]
 ,convert ( decimal(10,3), ( (1.0*A.sessionTime)-( isnull(B.tnot_av,0) ))/A.sessionTime  ) as [adherencia]
 ,isnull(C.ntotal,0) as [totalCalls]
 ,isnull(C.ntotal,0)  as [callsByHour]
 ,isnull(C.[complete],0) as  [complete]
 ,convert(decimal(10,4),  (isnull(C.[complete]*1.0,0) )/7.0) as  [completeByHour] --se va ocultar en la interfaz
 ,case when C.ntotal=0 or C.ntotal is null then 0.0000
    else convert(decimal(10,4), isnull( ( C.[complete]*1.0)/ C.ntotal,0) )  end as [percentComplete]
 ,datepart(YYYY,A.[date]) [year]
,datepart(MM,A.[date]) [month]
,datepart(DD,A.[date]) [day]
,datepart(HH,A.[date]) [hour]
,0 [minutes]
,ISNULL(t.tauxReady, 0) as [auxiliaryReadyTime]
,ISNULL(t.tav, 0) as [readyTime]
,ISNULL(t.tunknown + t.tother + t.tclient, 0) as [otherTime]
,convert ( decimal(18,3), isnull(t.tauxReady *1.0,0) /36.0 ) as [auxiliaryReadyPercent]
,convert ( decimal(18,3), ISNULL(B.tnot_av *1.0,0) /36.0 ) as [unavaiblePercent]
,convert ( decimal(18,3), ISNULL((t.tunknown + t.tother + t.tclient) *1.0,0) /36.0 ) as [otherPercent]
 from AgentSession A 
 left join notReady B on A.date=B.date and A.userId=B.userId
 left join callData C on A.date=C.date and A.userId=C.userId 
 left join timeAgent t on A.date=t.date and A.userId=t.userId
 order by A.[date]
end
END'
EXEC(@sql)

SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día Se crea nueva vista RepViewDetailAgent para el nuevo orden de columnas de la tabla RepDetailAgent'
SET @sql = '
IF EXISTS(select * FROM sys.views where name = ''RepViewDetailAgent'')
BEGIN
	DROP VIEW RepViewDetailAgent
END'
EXEC(@sql)


SET @process = 'KR123019 - Auxiliar - Reporte Detalle de Agente por Día Se crea nueva vista RepViewDetailAgent para el nuevo orden de columnas de la tabla RepDetailAgent'
SET @sql = '
CREATE VIEW RepViewDetailAgent AS
			SELECT
				[userId],
				[user] as login,
				[userName],
				[date],
				[sessionTime],
				[activeTime],
				[talkingtTime],
				[readyTime] AS readyInTime,
				[holdTime],
				[unavaibleTime],
				[auxiliaryReadyTime],
				[otherTime],
				[talkingPercent],
				[readyPercent],
				[waitpercent],
				[unavaiblePercent],
				[auxiliaryReadyPercent],
				[otherPercent],
				[adherencia],
				[totalCalls],
				[callsByHour],
				[complete],
				[completeByHourHideAndRename],
				[percentComplete],
				[year],
				[month],
				[day],
				[hour],
				[minutes]
			FROM [dbo].[RepDetailAgent]'
EXEC(@sql)

SET @process = 'KR123029 - Auxiliar - Reporte Resumen de intervalo de tiempos totales'
SET @sql = 'if not exists (select * from sys.columns where name = N''TPromAuxiliar'' and Object_ID = Object_ID(N''RepMKTTiemposTotales''))
begin
ALTER TABLE RepMKTTiemposTotales  ADD TPromAuxiliar int  NULL 
ALTER TABLE RepMKTTiemposTotales  ADD tauxiliarRdy int  NULL 
ALTER TABLE RepMKTTiemposTotales  ADD nauxiliar int  NULL 

update RepMKTTiemposTotales set [TPromAuxiliar]=0 where [TPromAuxiliar] is null
update RepMKTTiemposTotales set [tauxiliarRdy]=0 where [tauxiliarRdy] is null
update RepMKTTiemposTotales set [nauxiliar]=0 where [nauxiliar] is null
end';

EXEC (@sql);


SET @process = 'KR123029 - Auxiliar - Reporte Resumen de intervalo de tiempos totales'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepViewMKTTiemposTotales'')
BEGIN
	DROP VIEW RepViewMKTTiemposTotales
END'

EXEC(@sql)

SET @process = 'KR123029 - Auxiliar - Reporte Resumen de intervalo de tiempos totales'
SET @sql = '
CREATE VIEW [dbo].[RepViewMKTTiemposTotales] AS
SELECT date,
    inboundId,
    Acds,
    PromPosicionPersonal,
    receivedCalls,
    acdCalls,
    abandonedCalls,
    tPromACD,
    tPromACW,
    tPromRetention,
    callsOutExt,
    tPromSalidaExt,
    TPromDispon,
    TPromRing,
    TPromAuxiliar,
    AHT,
    tacd,
    tacw,
    nacw,
    tprosalext,
    tlog,
    thold,
    nhold,
    tdispo,
    ndispo,
    tring,
    nring,
    tauxiliarRdy,
    nauxiliar,
    accountUserId,
    year,
    month,
    day,
    hour,
    minutes FROM RepMKTTiemposTotales'

EXEC(@sql)

SET @process = 'KR123029 - Auxiliar - Reporte Resumen de intervalo de tiempos totales'
SET @sql = 'UPDATE dbo.GroupByReports 
SET columns = ''Acds|inboundId|round(case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end,1):PromPosicionPersonal|sum(receivedCalls):receivedCalls|sum(acdCalls):acdCalls|sum(abandonedCalls):abandonedCalls|case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end:tPromACD|case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end:tPromACW|case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end:tPromRetention|sum(callsOutExt):callsOutExt|isnull(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end,0):tPromSalidaExt|case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end:TPromDispon|case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end:TPromRing|case when sum(nauxiliar)>0 then sum(tauxiliarRdy)/sum(nauxiliar) else 0 end:TPromAuxiliar|sum(((case when acdCalls>0 then tacd/acdCalls else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))):AHT''
WHERE id = 7170;'
	EXEC(@sql)

SET @process = 'KR123029 - Auxiliar - Reporte Resumen de intervalo de tiempos totales'
	SET @sql = 'UPDATE dbo.ReportsTotals 
SET totalColumns = ''special:PromPosicionPersonal:(round(case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end,1)) |sum:receivedCalls|special:acdCalls:(sum(acdCalls))|sum:abandonedCalls|special:tPromACD:(case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end)|special:tPromACW:(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)  |special:tPromRetention:(case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end )|sum:callsOutExt|special:tPromSalidaExt:(isnull(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end,0))  |special:TPromDispon:(case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end)|special:TPromRing:(case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end) |special:TPromAuxiliar:(case when sum(nauxiliar)>0 then sum(tauxiliarRdy)/sum(nauxiliar) else 0 end) |special:AHT:(sum(((case when acdCalls>0 then tacd/acdCalls else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))))''
WHERE id = 7170;'
	EXEC(@sql)


SET @process = 'KR123029 - Auxiliar - Reporte Resumen de intervalo de tiempos totales'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;			
		
	IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
	
	IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog	

	IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData		
	

	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,
	[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
			
	
	;with 
	 relationCallIdCamId as(
		select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
	),
	transferData as(
		select B.userId,B.InboundId
		,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4)  then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext			
		,timegroup		
		from TmpTimesccLogtransfers T
		inner join relationCallIdCamId B on t.callId=B.callId	
		where tipo=1
	), transferDataGroup as(

	select userId, timegroup, InboundId 
	,sum(SalExt) SalExt,sum(tprosalext) tprosalext
	from transferData
	group by timegroup, InboundId,userId
	)
	

	select * into #transferData from transferDataGroup

	;with relationWg as(
		select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
		where wg.Tipo = 0
	)

	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,timegroup,timegroup_next timeGroupNext,tlog, wgu.IdCampEsp from TmpSessionTimeGroup st
		Inner Join relationWg wgu ON st.User_id = wgu.User_id

	
	select userId as user_id,camId as IdCampEsp,TipoStatusAge_id,
	sum(tstatus) as tstatus,
	sum(CASE WHEN timeGroup > dateIni AND timeGroupNext > dateEnd THEN 1 ELSE 0 END) AS nstatusfra,
	timeGroup
	INTO #groupLog
	from tmpccLogAgentesDia
	where TipoStatusAge_id IN (3,37) 
	GROUP BY userId,camId,TipoStatusAge_id,timegroup
	order by userId,timegroup,camId
		   	 	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	;with inCount as(
		select i.timegroup,Inbound_id as inboundId,User_id userId 
		,sum(CASE WHEN i.timeGroup > dateStartDetail AND i.timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nacd			
				,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nabnd
				,sum(tdialog) as tacd
				,sum(tnotes) as tacw
				,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tnotes>0 THEN 1 ELSE 0 END) as nacw			
				,sum(SalExt) as SalExt
				,sum(tprosalext) as tprosalext
				,sum(ntotal) as ncalls	
				,SUM(tring) as tring
				,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tring>0 THEN 1 ELSE 0 END) as nring
				,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13   THEN nMoh ELSE 0 END) as nhold
		from tmpTimesInboundData i
		left join #transferData  t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId
					group by i.timegroup,Inbound_id,User_id 
	)

	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.nacd,0) as nacd
		,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(c.ncalls, 0) AS ncalls		
		,isnull(c.tring, 0) AS tring
		,isnull(c.nring, 0) AS nring
		,isnull(c.nhold, 0) AS nhold
	 INTO #IntervalosInbound
	 from (
			select * from  inCount where inboundId > 0		
		) c		
	full join 
	(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
	on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId

	
	select i.*
	,isnull(case when lo.TipoStatusAge_id=3 then isnull(lo.tStatus,0) end,0) tdispo
	,isnull(case when lo.TipoStatusAge_id=3 then lo.nstatusfra end,0) ndispo
	,isnull(case when lo.TipoStatusAge_id=37 then isnull(lo.tStatus,0) end,0) tauxiliar
	,isnull(case when lo.TipoStatusAge_id=37 then 1 end,0) nauxiliar
	,isnull(h.tiempohold, 0) AS thold
	INTO #HoldDisp
	from #IntervalosInbound i
	left JOIN #groupLog lo on i.date = lo.timegroup and i.inboundId = lo.IdCampEsp and i.userId = lo.user_id
	left JOIN tmpTimesHoldIn h on h.inbound_id = i.inboundId and i.date = h.timegroup and i.userId = h.userId	

	delete from [RepMKTTiemposTotales]	where date >= @from AND date <= @to

	INSERT INTO [RepMKTTiemposTotales]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,sum(ncalls) [Recibidas]
		,sum(nacd) [Atendidas]
		,sum(nabnd) [Abandonadas]
		,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
		,case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end as [tPromRetention]
		,sum(SalExt) as [callsOutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
		,case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end as [TPromDispon]
		,case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end [TPromRing]
		,sum(((case when nacd>0 then tacd/nacd else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))) [AHT1]
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw				
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,sum(nhold) as nhold
		,sum(thold) as thold
		,sum(tdispo) as tdispo
		,sum(ndispo) as ndispo
		,sum(tring) as tring
		,sum(nring) as nring
		,userId as accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		,case when sum(nauxiliar)>0 then sum(tauxiliar)/sum(nauxiliar) else 0 end [TPromAuxiliar]
		,sum(tauxiliar) as tauxiliarRdy
		,sum(nauxiliar) as nauxiliar
		from #HoldDisp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		order by date		

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;					
	IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
	
	IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog	

	IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData		

END'
	EXEC(@sql)

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
	SET @sql = 'if not exists (select * from sys.columns where name = N''AvgAuxiliarySeconds'' and Object_ID = Object_ID(N''RepAgentHSBCKPI''))
begin
    ALTER TABLE RepAgentHSBCKPI  ADD AvgAuxiliarySeconds [DECIMAL](10, 3) NULL

	update RepAgentHSBCKPI set [AvgAuxiliarySeconds]=0 where [AvgAuxiliarySeconds] is null
end';

EXEC (@sql);

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepViewAgentHSBCKPI'')
BEGIN
	DROP VIEW RepViewAgentHSBCKPI
END'

EXEC(@sql)

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
SET @sql = '
CREATE VIEW [dbo].[RepViewAgentHSBCKPI] AS
SELECT date,
    OpHoursOutbound,
    OpHoursInbound,
    PaidHours,
    OffLineActivities,
    SignIn,
    AvgAuxiliarySeconds,
    AvgIdleSeconds,
    AvgTalkSeconds,
    AvgWrapSeconds,
    AvgAHTSeconds,
    Year,
    Month,
    Day,
    Hour,
    Minutes FROM RepAgentHSBCKPI'

EXEC(@sql)

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepAgentHSBCKPI]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		SET NOCOUNT ON

		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null
			select @to = getdate()

		if @action = 1
		begin
	
			DELETE	FROM RepAgentHSBCKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to

			create table #General (date datetime, General decimal(10,2), OpHoursOutBound decimal(10,2), OpHoursInbound decimal(10,2), SignIn decimal(10,2))
			create table #AvgIdle(fecha datetime, IdleSeconds decimal(10,2), analistas int)

			insert into #General
			select convert(date, [date]) as date, sum(General), sum(OpHoursOutBound), sum(OpHoursInbound), sum(SignIn)
			from (
				(select convert(date,[cal_inicio]) as date,
					(CONVERT(decimal(10,2),(sum(cal_tDialog)+sum(cal_tNotas)+sum(cal_tXfer)+sum(cal_tRing)))) as general,
					(CONVERT(decimal(10,2),(sum(cal_tDialog)+sum(cal_tNotas)+sum(cal_tXfer)+sum(cal_tRing)))) as OpHoursOutBound,
					0 as OpHoursInbound,
					(CONVERT(decimal(10,2),(sum(cal_tDialog)+sum(cal_tNotas)+sum(cal_tXfer)+sum(cal_tRing)))) as SignIn
				from ccoCallsOut 
				group by convert(date,[cal_inicio]))
			union all
				(select convert(date,[date]) as date,
					(CONVERT(decimal(10,2),sum(xfertime)+sum(ringingTime)+sum(dialogTime))) as general,
					0 as OpHoursOutBound,
					(CONVERT(decimal(10,2),sum(xfertime)+sum(ringingTime)+sum(dialogTime))) as OpHoursInbound,
					(CONVERT(decimal(10,2),sum(xfertime)+sum(ringingTime)+sum(dialogTime))) as SignIn
				from RepInCallsDetail 
				group by convert(date,[date]))
			union all
				(select convert(date,[date]) as date, 
					(CONVERT(decimal(10,2),sum(tnotesout)+sum(tringout)+sum(tav)+sum(tnotav))) as general,
					0 as OpHoursOutBound,
					0 as OpHoursInbound,
					(CONVERT(decimal(10,2),sum(tnotesout)+sum(tringout))) as SignIn
				from RepAgentGI 
				group by convert(date,[date]))
			) as final
			group by convert(date,[date])

			;with calls as(select convert(date, cal_inicio) date, count(DISTINCT User_id) cuenta from ccoCallsOut where User_id > 0 group by convert(date,cal_inicio))
			insert into #AvgIdle
				select convert(date,a.date), 
					case when b.cuenta > 0 
						then CAST((cast(sum(tnotav) as float)/cast(b.cuenta as float))/3600 as decimal(10,2))
						else 0
					end IdleSeconds,
					b.cuenta as analistas
				from calls b
				join RepAgentGI a on convert(date,a.date) = convert(date, b.date)
				group by convert(date,a.date), cuenta
				order by convert(date,a.date)

			insert into RepAgentHSBCKPI
			select convert(date,a.date), 
				ISNULL(OpHoursOutBound, 0) / 3600 as OpHoursOutbound,
				ISNULL(OpHoursInbound, 0) / 3600 as OpHoursInbound,
				ISNULL(General, 0) / 3600  as PaidHours,
				case when analistas > 0 then ((ISNULL(General, 0) / analistas )) / 3600 else 0 end OffLineActivities,
				ISNULL(SignIn ,0) / 3600  as SignIn,
				ISNULL(IdleSeconds, 0) as AvgIdleSeconds,
				ISNULL(cast((cast(sum(tdialogout) as float) / 3600) as decimal(10,3)), 0) as AvgTalkSeconds,
				ISNULL(cast((cast(sum(tnotesout) as float) / 3600) as decimal(10,3)), 0) as AvgWrapSeconds,
				ISNULL(cast((cast((sum(tdialogout)+sum(tnotesout)) as float) / 3600) as decimal(10,3)), 0) as AvgAHTSeconds,
				datepart(yyyy,max(a.date)) as Year,
				datepart(mm,max(a.date)) as Month,
				datepart(dd,max(a.date)) as Day,
				datepart(hh,max(a.date)) as Hours,
				datepart(mi,max(a.date)) as Minutes,
				ISNULL(cast((cast(sum(b.tauxiliarready) as float) / 3600) as decimal(10,3)), 0) as AvgAuxiliarySeconds
			from #General a
			left join RepAgentGI b on  convert(date,a.date) = convert(date,b.date)
			left join #AvgIdle c on convert(date,a.date) = convert(date,fecha)
			where a.date between @from and @to 
			group by convert(date,a.date), OpHoursOutBound, OpHoursInbound, General, SignIn, analistas, IdleSeconds
			order by convert(date,a.date)

			drop table #General
			drop table #AvgIdle
		end'
	EXEC(@sql)

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
SET @sql = 'if not exists (select * from sys.columns where name = N''auxiliaryReadyTime'' and Object_ID = Object_ID(N''RepSpecialTimes''))
begin
ALTER TABLE RepSpecialTimes  ADD auxiliaryReadyTime [int] NULL

update RepSpecialTimes set [auxiliaryReadyTime]=0 where [auxiliaryReadyTime] is null
end';

EXEC (@sql);

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
SET @sql = 'IF EXISTS(select * FROM sys.views where name = ''RepViewSpecialTimes'')
BEGIN
DROP VIEW RepViewSpecialTimes
END'

EXEC(@sql)

SET @process = 'KR123030 - Auxiliar - Reporte KPIs Especiales Agente'
SET @sql = 'CREATE VIEW [dbo].[RepViewSpecialTimes] AS
SELECT date,
campaignId,
inboundId,
campACDDescription,
sessionTime,
readyTime,
dialogTime,
auxiliaryReadyTime,
notReadyTime,
other,
descripcion,
descripcion_count,
count,
descripcion_time,
time,
timeSeconds,
year,
month,
day,
hour,
minutes	 FROM RepSpecialTimes'

EXEC(@sql)

SET @process = 'KR123031 - Auxiliar - Reporte Tiempos especiales'
SET @sql = 'UPDATE dbo.PivotReports SET complementColumns = ''date|campACDDescription|sessionTime|readyTime|dialogTime|auxiliaryReadyTime|notReadyTime|other'' WHERE id = 8040'
EXEC(@sql)

SET @process = 'KR123031 - Auxiliar - Reporte Tiempos especiales'
SET @sql = 'UPDATE dbo.ReportsTotals SET totalColumns = ''sum:auxiliaryReadyTime|sum:count|sum:time'' WHERE id = 8040'
EXEC(@sql)

SET @process = 'KR123031 - Auxiliar - Reporte Tiempos especiales'
SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepSpecialTimes] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepSpecialTimes
	WHERE DATE >= @from
		AND DATE < @to

	DECLARE @NotReady VARCHAR(max)

	SELECT TOP 1 @NotReady = descripcion
	FROM ccTipoNotReady
	ORDER BY tiponotready_id;

	WITH timeAgent
	AS (
		SELECT dateadd(mi, CASE WHEN datePart(mi, timeGroup) IN (15, 45) THEN - 15 ELSE 0 END, timeGroup) AS timeGroup
			,camId
			,camType
			,CASE WHEN tipostatusage_id = 3 THEN ''Tiempo Disponible'' WHEN tipostatusage_id = 4 THEN ''Tiempo Dialogo'' WHEN tipostatusage_id = 2 THEN ''Tiempo No Disponible'' 
			WHEN tipostatusage_id = 37  THEN ''Tiempo Auxiliar'' ELSE ''Otro'' END AS tDescripcion
			,tStatus
			,TipoStatusAge_id
			,dateIni
			,dateEnd
			,dbo.AccountInterval(dateIni, dateEnd, timeGroup, timeGroupNext, 1) ntotal
		FROM tmpccLogAgentesDia
		WHERE tStatus > 0
		)
		,times
	AS (
		SELECT C.cam_id
			,0 AS inbound_id
			,''Camp - '' + C.cam_descripcion AS [Espec/Camp]
			,A.timegroup
			,A.tDescripcion
			,sum(tStatus) AS tStatus
		FROM timeAgent A
		INNER JOIN cccamps C ON A.camId = C.cam_id
			AND A.camType = 1
		GROUP BY C.cam_id
			,C.cam_descripcion
			,A.timeGroup
			,A.tDescripcion
		
		UNION ALL
		
		SELECT 0 AS cam_id
			,inbound_id
			,''ACD - '' + C.descripcion AS [Espec/Camp]
			,A.timegroup
			,A.tDescripcion
			,sum(tStatus) AS tStatus
		FROM timeAgent A
		INNER JOIN ccinbound C ON A.camId = C.inbound_id
			AND A.camType = 0
		GROUP BY C.inbound_id
			,C.descripcion
			,A.timeGroup
			,A.tDescripcion
		)
		,Report1
	AS (
		SELECT cam_id
			,inbound_id
			,[Espec/Camp]
			,timegroup
			,isnull([Tiempo Disponible], 0) + isnull([Tiempo Dialogo], 0) + isnull([Tiempo Auxiliar], 0) + isnull([Tiempo No Disponible], 0) + isnull([Otro], 0) AS [Tiempo Sesion]
			,isnull([Tiempo Disponible], 0) AS [Tiempo Disponible]
			,isnull([Tiempo Dialogo], 0) AS [Tiempo Dialogo]
			,isnull([Tiempo Auxiliar], 0) AS [Tiempo Auxiliar]
			,isnull([Tiempo No Disponible], 0) AS [Tiempo No Disponible]
			,isnull([Otro], 0) AS [Otro]
		FROM times
		pivot(max(tstatus) FOR [tdescripcion] IN ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo Auxiliar], [Tiempo No Disponible], [Otro])) AS pvtTimes
		WHERE [Espec/Camp] IS NOT NULL
		)
		,NotReadyTime
	AS (
		SELECT A.timeGroup
			,B.TipoNotReady_id
			,C.Descripcion
			,A.tStatus
			,A.camId
			,A.camType
			,A.ntotal
		FROM timeAgent A
		LEFT JOIN ccLogAgentesNotReady B ON A.dateEnd = B.fecha
		LEFT JOIN ccTipoNotReady c ON B.TipoNotReady_id = c.tiponotready_id
		WHERE TipoStatusAge_id = 2
		)
		,notready
	AS (
		SELECT ''Camp - '' + cam_descripcion AS [Espec/Camp]
			,A.timeGroup
			,A.Descripcion AS [descriptionT]
			,sum(A.tstatus) AS T
			,A.Descripcion AS [descriptionN]
			,sum(ntotal) AS N
		FROM NotReadyTime A
		LEFT JOIN cccamps b ON A.camId = b.cam_id
			AND A.camType = 1
		GROUP BY cam_descripcion
			,timeGroup
			,A.Descripcion
		
		UNION
		
		SELECT ''ACD - '' + b.descripcion AS [Espec/Camp]
			,A.timeGroup
			,A.Descripcion AS [descriptionT]
			,sum(A.tstatus) AS T
			,A.Descripcion AS [descriptionN]
			,sum(ntotal) AS N
		FROM NotReadyTime A
		LEFT JOIN ccinbound b ON A.camId = b.Inbound_id
			AND A.camType = 0
		GROUP BY b.descripcion
			,timeGroup
			,A.Descripcion
		)

	INSERT INTO RepSpecialTimes
	SELECT a.timeGroup AS [date]
		,a.cam_id AS [campaignId]
		,a.inbound_id AS [inboundId]
		,a.[Espec/Camp] AS [campACDDescription]
		,[Tiempo Sesion] AS [sessionTime]
		,[Tiempo Disponible] AS [readyTime]
		,[Tiempo Dialogo] AS [dialogTime]
		,[Tiempo No Disponible] AS [notReadyTime]
		,[Otro] AS [other]
		,descriptionN AS [descripcion]
		,descriptionN + ''_Count'' AS [descripcion_count]
		,[N] AS [count]
		,b.descriptionT + ''_Time'' AS [descripcion_time]
		,[T] AS [time]
		,[T] AS [timeSeconds]
		,datepart(yyyy, a.timeGroup) AS [year]
		,datepart(mm, a.timeGroup) AS [month]
		,datepart(dd, a.timeGroup) AS [day]
		,datepart(hh, a.timeGroup) AS [hour]
		,datepart(mi, a.timeGroup) AS [minutes]
		,[Tiempo Auxiliar] AS [auxiliaryReadyTime]
	FROM Report1 a
	LEFT JOIN notready b ON (
			a.[Espec/Camp] = b.[Espec/Camp]
			AND a.timeGroup = b.timeGroup
			)
	WHERE b.timeGroup IS NOT NULL
	
	UNION
	
	SELECT a.timeGroup
		,a.cam_id
		,a.inbound_id
		,a.[Espec/Camp]
		,[Tiempo Sesion] AS [Tiempo Sesion]
		,[Tiempo Disponible] AS [Tiempo Disponible]
		,[Tiempo Dialogo] AS [Tiempo Dialogo]
		,[Tiempo No Disponible] AS [Tiempo No Disponible]
		,[Otro] AS [Otro]
		,@NotReady
		,@NotReady + ''_Count''
		,0
		,@NotReady + ''_Time''
		,''0''
		,0
		,datepart(yyyy, a.timeGroup) AS [year]
		,datepart(mm, a.timeGroup) AS [month]
		,datepart(dd, a.timeGroup) AS [day]
		,datepart(hh, a.timeGroup) AS [hour]
		,datepart(mi, a.timeGroup) AS [minutes]
		,[Tiempo Auxiliar] AS [auxiliaryReadyTime]
	FROM Report1 a
	LEFT JOIN notready b ON (
			a.[Espec/Camp] = b.[Espec/Camp]
			AND a.timeGroup = b.timeGroup
			)
	WHERE b.timeGroup IS NULL
	ORDER BY a.[Espec/Camp]
		,a.timeGroup
END'
EXEC(@sql)


-----------END Team Nuevos Rec ------------------------------------------

	




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
