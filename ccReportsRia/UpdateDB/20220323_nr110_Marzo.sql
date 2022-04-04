SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 110

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'Modificación campo "En Diálogo" Reporte Detalle de llamadas contestadas y Transferidas'
	SET @sql = 'ALTER FUNCTION [dbo].[tDialog](
		@totalCall_Time int,
		@tdialing int, 
		@cal_tMsg int)
RETURNS INT 
AS
BEGIN
		DECLARE @totalDialog INT
		IF ((COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) % 60) <> 0 )
		BEGIN
			SET @totalDialog=COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) + (60 -(COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) % 60)) 
			RETURN @totalDialog
		END
		ELSE
			SET @totalDialog = COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing)
			RETURN @totalDialog

END'
	EXEC (@sql)

	SET @process = 'CW-5966 Registro setting 42 para info en reporte Detalle de Llamadas Contestadas y Transferidas '
	SET @sql = '
	if not exists (select * from ccSettings where setting_id = 42)
	begin
		insert into ccsettings values (42, ''127.0.0.1|NombreDelServidor'', ''IP y nombre del servidor principal'', 1, ''RPT'')
	end
	'
	EXEC(@sql)

	SET @process = 'CW-6451 Registro filtros menu 7200'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ReportsFiltersMenus WHERE idReport = 7200 )
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7200,N''date'')
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7200,N''filterby'')
	end
	'
	EXEC(@sql)

	SET @process = 'CW-6518 Registro filtros menu 7210'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ReportsFiltersMenus WHERE idReport = 7210)
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7210,N''date'')
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7210,N''filterby'')
	end
	'
	EXEC(@sql)

	SET @process = 'CW-6519 Registro filtros menu 7220'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ReportsFiltersMenus WHERE idReport = 7220)
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7220,N''date'')
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7220,N''filterby'')
	end'
	EXEC(@sql)

	SET @process = 'CW-6519 create table RepAgentHSBCKPI'
	SET @sql = '
	if not exists (select * from sys.tables where name = N''RepAgentHSBCKPI'')
	begin
		create table RepAgentHSBCKPI(
			date datetime not null,
			OpHoursOutbound decimal(10,2) not null,
			OpHoursInbound decimal(10,2) not null,
			PaidHours decimal(10,2) not null,
			OffLineActivities decimal(10,2) not null, 
			SignIn decimal(10,2) not null,
			AvgIdleSeconds decimal(10,3) not null, 
			AvgTalkSeconds decimal(10,3) not null,
			AvgWrapSeconds decimal(10,3) not null,
			AvgAHTSeconds decimal(10,3) not null,
			Year int not null,
			Month int not null,
			Day int not null,
			Hour int not null,
			Minutes int not null
		)
	end
	'
	EXEC(@sql)

	SET @process = 'CW-6519 create index on table RepAgentHSBCKPI'
	SET @sql = '
	if not exists (select * from sys.indexes where name = N''IX_RepAgentHSBCKPI'' and object_id = OBJECT_ID(N''RepAgentHSBCKPI''))
	begin
		CREATE INDEX IX_RepAgentHSBCKPI ON RepAgentHSBCKPI(date);
	end
	'
	EXEC(@sql)


	SET @process = 'CW-6519 drop SP ccspRepAgentHSBCKPI'
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepAgentHSBCKPI'')
	begin
		DROP PROCEDURE ccspRepAgentHSBCKPI;
	end'
	EXEC(@sql)

	SET @process = 'CW-6519 create SP ccspRepAgentHSBCKPI'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepAgentHSBCKPI]
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
				datepart(mi,max(a.date)) as Minutes
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

	SET @process = 'CW-6451 create table RepInboundKPI'
	SET @sql = '
	if not exists (select * from sys.tables where name = N''RepInboundKPI'')
	begin
		create table RepInboundKPI(
			date datetime not null,
			NCO int not null,
			NCH int not null,
			abandonedCalls int not null, 
			SL decimal(10,2) not null, 
			RPC int not null,
			PTP int not null,
			PK int not null,
			Quejas int not null,
			AvgIdleSeconds decimal(10,2) not null,
			AvgTalkSeconds decimal(10,2) not null,
			AvgWrapSeconds decimal(10,2) not null,
			Year int not null,
			month int not null,
			day int not null,
			hour int not null,
			minutes int not null
		) on [primary]
	end
	'
	EXEC(@sql)

	SET @process = 'CW-6451 create index on table RepInboundKPI'
	SET @sql = '
	if not exists (select * from sys.indexes where name = N''IX_RepInboundKPI'' and object_id = OBJECT_ID(N''RepInboundKPI''))
	begin
		CREATE INDEX IX_RepInboundKPI ON RepInboundKPI(date);
	end
	'
	EXEC(@sql)


	SET @process = 'CW-6451 drop SP ccspRepInboundKPI'
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepInboundKPI'')
	begin
		DROP PROCEDURE ccspRepInboundKPI;
	end'
	EXEC(@sql)

	SET @process = 'CW-6451 create SP ccspRepInboundKPI'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepInboundKPI]
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
	
			DELETE	FROM RepInboundKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to
	
			CREATE TABLE #NumQuejas (fecha datetime, quejas int)
			CREATE TABLE #AvgSeconds (fecha datetime, TalkSeconds decimal(10,2), WrapSeconds decimal(10,2))
			create table #AvgIdle(fecha datetime, IdleSeconds decimal(10,2))

			insert into #NumQuejas
				select convert(date,[date]), sum(cuenta) 
				from (
				(select convert(date,[date]) as date,count(1) as cuenta from RepInCallsDetail where callStatusId=13 and dispositionId in (5,6,7,8,9,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,29,30,31,32,33,34,48,49) group by convert(date,[date]))
				union all
				(select convert(date,[cal_Inicio]) as date,count(1) as cuenta from ccoCallsOut where calif_id in (31) group by convert(date,[cal_inicio]) )
				) as final
				group by convert(date,[date])

			insert into #AvgSeconds
				select convert(date,[date]) as date,
					cast(sum(tdialogin) as float) / 3600 as TalkSeconds, 
					cast(sum(tnotesin) as float) / 3600 as WrapSeconds  
				from RepAgentGI 
				group by convert(date,[date]); 

			with calls as(select convert(date, cal_inicio) date, count(DISTINCT User_id) cuenta from ccoCallsOut group by convert(date,cal_inicio))
			insert into #AvgIdle
				select convert(date,a.date), 
					case when b.cuenta > 0 
						then CAST((cast(sum(tnotav) as float)/cast(b.cuenta as float))/3600 as decimal(10,2))
						else 0
					end IdleSeconds
				from calls b
				join RepAgentGI a on convert(date,a.date) = convert(date, b.date)
				group by convert(date,a.date), cuenta
				order by convert(date,a.date)

			insert into RepInboundKPI
			select convert(date,[date]) as date, 
				sum(NCO) as NCO, 
				sum(NCH) as NCH, 
				sum(Abandoned) as Abandoned,
				case when sum(SL2) > 0 
					then CAST( ( (cast(sum(SL1) as float) / cast(sum(SL2) as float)) * 100 ) as decimal(10,2)) 
					else 0 
				end as SL,
				sum(RPC) as RPC,
				sum(PTP) as PTP,
				SUM(PK) as PK,
				case when quejas > 0 then quejas else 0 end Quejas,
				ISNULL(IdleSeconds, 0) as AVGIdle,
				ISNULL(TalkSeconds, 0) as AVGTalkSeconds,
				ISNULL(WrapSeconds, 0) as AVGWrapSeconds,
				datepart(yyyy,max(date)) as year,
				datepart(mm,max(date)) as month,
				datepart(dd,max(date)) as day,
				datepart(hh,max(date)) as hours,
				datepart(mi,max(date)) as minutes
			from(
				select date as date, 1 as NCO,
					case when userid > 0 then 1 else 0 end NCH,
					case when callStatusId in (6,7,8) then 1 else 0 end Abandoned,
					case when callStatusId = 13 and queueTime < 21 then 1 else 0 end SL1,
					case when date between @from and @to then 1 else 0 end SL2,
					case when callStatusId=13 and dispositionId in (5,6,7,8,9,22,23,24,25,26,29,30,31,32,33,34) then 1 else 0 end RPC, 
					case when callStatusId=13 and dispositionId in (5,6,7,8,9) then 1 else 0 end PTP,
					case when callStatusId=13 and dispositionId in (46,47,48,49) then 1 else 0 end PK
				from RepInCallsDetail
			) as final
			left join #NumQuejas b on convert(date, date) = convert(date, fecha)
			left join #AvgSeconds c on convert(date, date) = convert(date, c.fecha)
			left join #AvgIdle d on convert(date, date) =convert(date, d.fecha)
			where date between @from and @to 
			group by convert(date,final.date), quejas, WrapSeconds, TalkSeconds, IdleSeconds
			order by convert(date,[date])

			drop table #NumQuejas
			drop table #AvgSeconds
			drop table #AvgIdle
	end'
	EXEC(@sql)

	SET @process = 'CW-6518 create table RepOutboundKPI'
	SET @sql = '
	if not exists (select * from sys.tables where name = N''RepOutboundKPI'')
	begin
		create table RepOutboundKPI(
			date datetime not null,
			UniqueRecordCalls int not null,
			DialsAttempted int not null,
			DialsCompleteRing int not null,
			nanswer2 int not null,
			ConnectedCalls int not null,
			abandonedCalls int not null,
			RPC int not null,
			PTP int not null,
			PK int not null,
			Quejas int not null,
			Year int not null,
			month int not null,
			day int not null,
			hour int not null,
			minutes int not null
		) on [primary]
	end
	'
	EXEC(@sql)

	SET @process = 'CW-6518 create index on table RepOutboundKPI'
	SET @sql = '
	if not exists (select * from sys.indexes where name = N''IX_RepOutboundKPI'' and object_id = OBJECT_ID(N''RepOutboundKPI''))
	begin
		CREATE INDEX IX_RepOutboundKPI ON RepOutboundKPI(date);
	end
	'
	EXEC(@sql)


	SET @process = 'CW-6518 drop SP ccspRepOutboundKPI'
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepOutboundKPI'')
	begin
		DROP PROCEDURE ccspRepOutboundKPI;
	end'
	EXEC(@sql)

	SET @process = 'CW-6518 create SP ccspRepOutboundKPI'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepOutboundKPI]
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

			DELETE FROM RepOutboundKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to

			create table #UniqueRecords (date datetime, UniqueRecordsCalled int)
			create table #Connects(date datetime, Connects int)
			create table #CallsOut(date datetime, Abandono int, RPC int, PTP int, PK int)
			create table #Quejas(date datetime, Quejas int)
	

			;with t as( select distinct convert(date,[date]) as date,callKey,telephone from RepOutDialDetail  ) 
			insert into #UniqueRecords
				select distinct convert(date,[date]),count(*) from t group by convert(date,[date]) order by convert(date,[date])
	
			;with te as (select date from RepOutCallsDetail where USERID >0 and dialog>0 )
			insert into #Connects
				select distinct convert(date,[date]) as date,count(*) from te group by convert(date,[date]) 

			insert into #CallsOut
				select convert(date,date),
					sum(Abandono) as Abandono,
					sum(RPC) as RPC,
					sum(PTP) as PTP,
					sum(PK) as PK
				from(
					select [cal_Inicio] as date,
						case when statusCall_id in (6,7,8) then 1 else 0 end Abandono,
						case when calif_id in (5,6,7,8,9,22,23,24,25,26,29,30,31,32,33,34) then 1 else 0 end RPC,
						case when calif_id in (5,6,7,8,9) then 1 else 0 end as PTP,
						case when calif_id in (46,47,48,49) then 1 else 0 end as PK
					from ccoCallsOut
				) as temp
				group by convert(date,date)

			insert into #Quejas
				select convert(date,[date]), sum(cuenta) 
				from (
				(select convert(date,[date]) as date,count(1) as cuenta from RepInCallsDetail where callStatusId=13 and dispositionId in (5,6,7,8,9,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,29,30,31,32,33,34,48,49) group by convert(date,[date]))
				union all
				(select convert(date,[cal_Inicio]) as date,count(1) as cuenta from ccoCallsOut where calif_id in (31) group by convert(date,[cal_inicio]) )
				) as final
				group by convert(date,[date]);

			insert into RepOutboundKPI
			select convert(date,final.date) as date,
				ISNULL(UniqueRecordsCalled, 0) as UniqueRecordCalled,
				sum(DialsAttempted) as DialsAttemted,
				sum(dialsComplete) as DialsCompleteRing,
				sum(Answer) as Answer,
				ISNULL(Connects, 0) as Connects,
				ISNULL(Abandono, 0) as Abandono,
				ISNULL(RPC, 0) as RPC,
				ISNULL(PTP, 0) as PTP,
				ISNULL(PK, 0) as PK,
				ISNULL(Quejas, 0) as Quejas,
				datepart(yyyy,max(final.date)) as year,
				datepart(mm,max(final.date)) as month,
				datepart(dd,max(final.date)) as day,
				datepart(hh,max(final.date)) as hours,
				datepart(mi,max(final.date)) as minutes
			from (
				select date as date,
					1 as DialsAttempted,
					case when dialResultId in (1,2,3,8,11,13) then 1 else 0 end dialsComplete,
					case when dialResultId in (1) then 1 else 0 end Answer
				from RepOutDialDetail
			) as final
			left join #UniqueRecords a on convert(date,final.date) = convert(date, a.date)
			left join #CallsOut b on convert(date,final.date) = convert(date, b.date)
			left join #Quejas c on convert(date,final.date) = convert(date, c.date)
			left join #Connects d on convert(date,final.date) = convert(date, d.date)
			where final.date between @from and @to
			group by convert(date,final.date), UniqueRecordsCalled, Abandono, RPC, PTP, PK, Quejas, Connects
			order by convert(date,final.date)

			drop table #UniqueRecords
			drop table #Connects
			drop table #CallsOut
			drop table #Quejas
	end'
	EXEC(@sql)


	set @process = 'CW-6501 Alter SP  ccspGenSession'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspGenSession] @from AS SMALLDATETIME, @to AS SMALLDATETIME
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
	) A
LEFT JOIN (
	SELECT ROW_NUMBER() OVER (
			PARTITION BY user_id ORDER BY FECHA, tipoMov
			) Fila, User_id, Extension, TipoMov, fecha
	FROM ccLogLogin a
	WHERE fecha >= @from
		AND fecha <= @to
	) S
	ON A.Fila = S.Fila - 1
		AND A.User_id = S.User_id
		AND A.TipoMov = 1
		AND S.TipoMov = 0
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
		) --logout,
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

--select *,datediff(ss,login,logout) as tlog from(
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
		EXEC(@Sql)

		SET @process = 'CW-6501 DROP PROCEDURE ccspTmpTimesccLogtransfers'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccspTmpTimesccLogtransfers'')
	begin
	DROP PROCEDURE ccspTmpTimesccLogtransfers;
	end'

		EXEC (@Sql)


		set @process = 'CW-6501 Alter SP ccspTmpTimesccLogtransfers '
		set @Sql= 'CREATE PROCEDURE [dbo].[ccspTmpTimesccLogtransfers] @from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogtransfers'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogtransfers
IF OBJECT_ID(N''tempdb..#tempccLogtransfers2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogtransfers2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''TmpTimesccLogtransfers''
		)
BEGIN
	CREATE TABLE TmpTimesccLogtransfers (
	dateIni DATETIME NOT NULL, dateEnd DATETIME NOT NULL, callId INT NOT NULL, tipo TINYINT NULL, modo TINYINT NULL
	, destino VARCHAR(100) NOT NULL, tAntesXfer INT, tDespuesXfer INT	
	, timegroup DATETIME NOT NULL
	,timegroup_next DATETIME NOT NULL
	)
END
ELSE
BEGIN
	TRUNCATE TABLE TmpTimesccLogtransfers
		--drop table TmpTimesccLogtransfers
END

CREATE TABLE #tempccLogtransfers (
	dateIni DATETIME NOT NULL, dateEnd DATETIME NOT NULL, callId INT NOT NULL, tipo TINYINT NULL, modo TINYINT NULL
	, destino VARCHAR(100) NOT NULL, tAntesXfer INT, tDespuesXfer INT
	,dateStarBeforetTransf DATETIME NOT NULL	
	, timegroup DATETIME NOT NULL
	,timegroup_next DATETIME NOT NULL
	)
	;

with logtransfer as(

SELECT DATEADD(ss, - tAntesXfer - tDespuesXfer, fechaFin)as  dateIni, fechaFin  as dateEnd
	, cal_id callId, tipo, modo, destino, tAntesXfer, tDespuesXfer
	, dbo.GetTimeGroup(DATEADD(ss, - tAntesXfer - tDespuesXfer, fechaFin), 0) AS timegroup
	, dbo.GetTimeGroup(fechaFin, 1) AS timegroup_next
FROM ccLogtransfers
WHERE fechaFin BETWEEN @from		AND @to

)

INSERT INTO #tempccLogtransfers
select dateIni,dateEnd,callId, tipo, modo, destino, tAntesXfer, tDespuesXfer
,dateadd(ss,tAntesXfer,dateIni) as dateStarBeforetTransf
,timegroup,timegroup_next
from logtransfer

select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15

insert into TmpTimesccLogtransfers
select dateIni,dateEnd,callId
	,tipo, modo, destino
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateStarBeforetTransf) AS tAntesXfer
	,dbo.TimeInterval(th.start, th.stop, dateStarBeforetTransf, dateEnd) AS tDespuesXfer	
,th.start as timegroup,th.stop as timegroup_next
	from #tempccLogtransfers2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
union all
select dateIni,dateEnd,callId	,tipo, modo, destino,
tAntesXfer,tDespuesXfer,timegroup,timegroup_next
from #tempccLogtransfers

IF OBJECT_ID(N''tempdb..#tempccLogtransfers'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogtransfers
IF OBJECT_ID(N''tempdb..#tempccLogtransfers2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogtransfers2
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspTimesReports '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspTimesReports]
@from as smalldatetime,
@to as smalldatetime,
@interval int =15
AS
set nocount on

declare @row int
declare @starttime datetime

set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
--set @to=dateadd(mi,15,@to)


select @row=ABS( CEILING(1.0*DATEDIFF(mi,@starttime,@to)/@interval))


;WITH Numbers AS
(
    SELECT TOP (@row) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
    FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
)
SELECT  ROW_NUMBER() OVER (ORDER BY n) as [ID], DATEADD(MINUTE,@interval* (n-1), @from) as [Start], DATEADD(MINUTE,@interval* (n), @from) as [Stop]
FROM Numbers
'
		EXEC(@Sql)

		SET @process = 'CW-6501 DROP PROCEDURE ccspTimesOutboundData'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccspTimesOutboundData'')
	begin
	DROP PROCEDURE ccspTimesOutboundData;
	end'

		EXEC (@Sql)

		set @process = 'CW-6501 Alter SP  ccspTimesOutboundData'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccspTimesOutboundData] @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesOutboundData''
		)
BEGIN
	CREATE TABLE tmpTimesOutboundData (
		row INT identity
		,dateStartDetail DATETIME
		,dateEndDetail DATETIME
		,timegroup DATETIME
		,timegroup_next DATETIME
		,cam_id INT
		,User_id INT
		,ntotal INT
		,nno_agent INT
		,nxfer INT
		,nabnd_xfer INT
		,nabnd_ring INT
		,nno_answer INT
		,nabnd_dialog INT
		,nanswer INT
		,nlost INT
		,tque INT
		,txfer INT
		,tring INT
		,tdialog INT
		,tnotes INT
		,tresp INT
		,nhangup INT
		,nMoh INT
		,nWHag INT
		,nWHcl INT
		,time_endque DATETIME
		,time_ring DATETIME
		,time_dialog DATETIME
		,time_notes DATETIME
		,time_end_call DATETIME
		,phone_out VARCHAR(30)
		,cal_id INT
		,cal_puerto INT
		,idwg INT
		,statuscall_id INT
		,calif_id INT
		,cal_manual int
		,cal_tMoh int
		)
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesOutboundData
		--drop table tmpTimesOutboundData
END

DECLARE @relastionCampWg TABLE (
	idwg INT
	,camId INT
	)

INSERT INTO @relastionCampWg
SELECT max(IDWG) AS IDWG
	,IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 1
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT

SELECT @HourExtend = 2

DECLARE @fromExtended AS SMALLDATETIME

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH TimesOutboundData
AS (
	SELECT cal_Inicio AS dateStartDetail
		,DATEADD(ss, isnull((cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_Inicio) AS dateEndDetail
		,cam_id
		,[User_id]
		,1 AS ntotal
		,CASE WHEN (statuscall_id = 4) THEN 1 ELSE 0 END AS nno_agent
		,CASE WHEN (statuscall_id >= 10) THEN 1 ELSE 0 END AS nxfer
		,CASE WHEN (statuscall_id = 11) THEN 1 ELSE 0 END AS nabnd_xfer
		,CASE WHEN (
					statuscall_id = 15
					AND cal_tring <= @tresRing
					) THEN 1 ELSE 0 END AS nabnd_ring
		,CASE WHEN (
					statuscall_id = 15
					AND cal_tring > @tresRing
					) THEN 1 ELSE 0 END AS nno_answer
		,CASE WHEN (
					statuscall_id = 13
					AND cal_tdialog <= @tresDialog
					) THEN 1 ELSE 0 END AS nabnd_dialog
		,CASE WHEN (
					statuscall_id = 13
					AND cal_tdialog > @tresDialog
					) THEN 1 ELSE 0 END AS nanswer
		,CASE WHEN (statuscall_id = 16) THEN 1 ELSE 0 END AS nlost
		,cal_twait AS tque
		,cal_txfer AS txfer
		,cal_tring AS tring
		,cal_tdialog AS tdialog
		,cal_tnotas AS tnotes
		,CASE WHEN (
					statuscall_id = 13
					AND cal_tdialog > @tresDialog
					) THEN (cal_txfer + cal_tring) ELSE 0 END AS tresp
		,CASE WHEN (statuscall_id = 6) THEN 1 ELSE 0 END AS nhangup
		,CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
		,CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
		,CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
		,DATEADD(ss, cal_twait, cal_inicio) AS time_endque
		,DATEADD(ss, cal_twait + cal_txfer, cal_inicio) AS time_ring
		,DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio) AS time_dialog
		,DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio) AS time_notes
		,DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio) AS time_end_call
		,cal_telefono AS phone_out
		,cal_id
		,cal_puerto
		,B.idwg AS idwg
		,A.statuscall_id
		,A.calif_id
		,A.cal_manual
		,A.cal_tMoh
	FROM ccoCallsOut A WITH (
			NOLOCK
			,INDEX (IX_ccoCallsOut_2)
			)
	LEFT JOIN @relastionCampWg B ON A.cam_id = B.camId
	WHERE cal_Inicio >= @fromExtended
		AND cal_inicio < @to
		--AND cal_manual IN (0, 2, 3)
	)
INSERT INTO tmpTimesOutboundData (
	dateStartDetail
	,dateEndDetail
	,cam_id
	,User_id
	,ntotal
	,nno_agent
	,nxfer
	,nabnd_xfer
	,nabnd_ring
	,nno_answer
	,nabnd_dialog
	,nanswer
	,nlost
	,tque
	,txfer
	,tring
	,tdialog
	,tnotes
	,tresp
	,nhangup
	,nMoh
	,nWHag
	,nWHcl
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_out
	,cal_id
	,cal_puerto
	,idwg
	,statuscall_id
	,calif_id
	,cal_manual
	,cal_tMoh
	,timegroup
	,timegroup_next
	)
SELECT A.*
	,dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
	,dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
FROM TimesOutboundData A

IF CONVERT(DATE, @dateNow, 121) = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId
			,max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN convert(DATE, @to, 121)
				AND @to
		GROUP BY userId
		)
		,timeAcumlate
	AS (
		SELECT A.userId
			,A.camId
			,A.callId
			,sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus ELSE 0 END) AS tdialog
			,sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes
			,max(A.dateEnd) AS dateEnd
			,max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN convert(DATE, @to, 121)
				AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 1
		GROUP BY A.userId
			,A.camId
			,A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd
		,A.timegroup_next = B.timeGroupNext
		,A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.tdialog END
		,A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END
		,A.time_notes = CASE WHEN B.tdialog > 0 THEN B.dateEnd ELSE A.time_dialog END
		,A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
	FROM tmpTimesOutboundData A
	INNER JOIN timeAcumlate B ON A.User_id = B.userId
		AND A.cam_id = B.camId
		AND A.cal_id = B.callId
END

SELECT *
INTO #outboundData2
FROM tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO tmpTimesOutboundData (
	dateStartDetail
	,dateEndDetail
	,timegroup
	,timegroup_next
	,cam_id
	,User_id
	,ntotal
	,nno_agent
	,nxfer
	,nabnd_xfer
	,nabnd_ring
	,nno_answer
	,nabnd_dialog
	,nanswer
	,nlost
	,tque
	,txfer
	,tring
	,tdialog
	,tnotes
	,tresp
	,nhangup
	,nMoh
	,nWHag
	,nWHcl
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_out
	,cal_id
	,cal_puerto
	,idwg
	,statuscall_id
	,calif_id
	,cal_manual
	,cal_tMoh
	)
SELECT dateStartDetail
	,dateEndDetail
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,cam_id
	,[User_id]
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ntotal ELSE 0 END AS ntotal
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nxfer ELSE 0 END AS nxfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nanswer ELSE 0 END AS nanswer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nlost ELSE 0 END AS nlost
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
	,dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer
	,dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
	,dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
	,dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, dateadd(ss, tresp, dateStartDetail)) AS tresp
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nhangup ELSE 0 END AS nhangup
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nMoh ELSE 0 END AS nMoh
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHag ELSE 0 END AS nWHag
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_out
	,cal_id
	,cal_puerto
	,idwg
	,statuscall_id
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id
	,cal_manual
	,dbo.AccountInterval(th.start,th.stop,dateStartDetail,dateEndDetail,cal_tMoh) as cal_tMoh
FROM #outboundData2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timegroup_next
WHERE datediff(ss, th.start, timegroup_next) > 0

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2
'
		EXEC(@Sql)

		SET @process = 'CW-6501 DROP PROCEDURE ccspTimesccLogAgentesDia'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccspTimesccLogAgentesDia'')
	begin
	DROP PROCEDURE ccspTimesccLogAgentesDia;
	end'

		EXEC (@Sql)

		set @process = 'CW-6501 Alter SP  ccspTimesccLogAgentesDia'
		set @Sql= 'CREATE PROCEDURE [dbo].ccspTimesccLogAgentesDia @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpccLogAgentesDia''
		)
BEGIN
	CREATE TABLE tmpccLogAgentesDia (
		id INT NOT NULL IDENTITY PRIMARY KEY
		,userId INT NOT NULL
		,TipoStatusAge_id TINYINT NOT NULL
		,tStatus FLOAT NOT NULL
		,dateIni DATETIME NOT NULL
		,dateEnd DATETIME NOT NULL
		,currentStatus INT NOT NULL
		,timeGroup DATETIME NOT NULL
		,timeGroupNext DATETIME NOT NULL
		,camId SMALLINT
		,camType SMALLINT
		,callId INT
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpccLogAgentesDia
		--drop table tmpccLogAgentesDia
END

CREATE TABLE #tempccLogAgentesDia (
	row INT NOT NULL
	,user_id INT NOT NULL
	,TipoStatusAge_id TINYINT NOT NULL
	,tStatus FLOAT NOT NULL
	,dateIni DATETIME NOT NULL
	,dateEnd DATETIME NOT NULL
	,currentStatus INT
	,timeGroup DATETIME NOT NULL
	,timeGroupNext DATETIME NOT NULL
	,camId SMALLINT
	,camType SMALLINT
	,callId INT
	);;

WITH tmpLog
AS (
	SELECT User_id AS userId
		,TipoStatusAge_id
		,tStatus
		,DATEADD(ss, - tStatus, fecha) dateIni
		,fecha dateEnd
		,ISNULL(currentStatus, 0) AS currentStatus
		,dbo.GetTimeGroup(DATEADD(ss, - tStatus, fecha), 0) AS timegroup
		,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
		,IdCampEsp AS camId
		,Tipo AS camType
		,callId
	FROM ccLogAgentesDia
	WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to 
	)
INSERT INTO #tempccLogAgentesDia
SELECT ROW_NUMBER() OVER (
		PARTITION BY userId ORDER BY dateIni
		) AS Row
	,userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timegroup
	,timegroup_next
	,camId
	,camType
	,callId
FROM tmpLog

DELETE A
FROM (
	SELECT CASE WHEN A.tStatus > S.tStatus THEN S.row ELSE A.row END row
		,A.user_id
	FROM #tempccLogAgentesDia A
	LEFT JOIN #tempccLogAgentesDia S ON A.Row = S.Row - 1
		AND A.user_id = S.user_id
	WHERE A.dateIni >= @from
		AND A.dateIni < @to
		AND A.TipoStatusAge_id = S.TipoStatusAge_id
		AND (
			S.dateEnd BETWEEN A.dateIni
				AND A.dateEnd
			OR S.dateIni BETWEEN A.dateIni
				AND A.dateEnd
			)
		AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 1
	) x
INNER JOIN #tempccLogAgentesDia A ON A.row = x.row
	AND A.user_id = x.user_id;

-----------Se agrega el estado actual
DECLARE @dateNow DATETIME
	,@date DATE
	,@maxLogout DATETIME;

SET @dateNow = GETDATE();

SELECT @maxLogout = MAX(logout)
FROM TmpSessionTimeGroup;

IF CONVERT(DATE, @dateNow, 121) = CONVERT(DATE, @to, 121)
BEGIN

	declare @today date

	set @today=convert(DATE, @to, 121)
		;

	WITH tempAgentLastStatus
	AS (
		SELECT User_id AS userId
			,MAX(fecha) AS fecha
		FROM ccLogAgentesDia
		WHERE fecha BETWEEN @today AND @to
		GROUP BY User_id
		)		

	INSERT INTO #tempccLogAgentesDia
	SELECT 0
		,A.user_id
		,A.currentStatus
		,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
		,A.dateEnd
		,@dateNow
		,A.currentStatus
		,dbo.GetTimeGroup(B.fecha, 0) AS timegroup
		,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
		,A.camId
		,A.camType
		,A.callId
	FROM #tempccLogAgentesDia A
	INNER JOIN tempAgentLastStatus B ON A.dateEnd = B.fecha
		AND A.User_id = B.userId
	WHERE A.dateIni BETWEEN convert(DATE, @to, 121)
			AND @to
		AND A.currentStatus NOT IN (- 2, - 1, 0);
END

SELECT *
INTO #tempccLogAgentesDia2
FROM #tempccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15

DELETE #tempccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;

INSERT INTO #tempccLogAgentesDia
SELECT 1
	,t.user_id
	,TipoStatusAge_id
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,t.camId
	,t.camType
	,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
	AND th.Start BETWEEN @from
		AND @to;

INSERT INTO tmpccLogAgentesDia (
	userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timeGroup
	,timeGroupNext
	,camId
	,camType
	,callId
	)
SELECT user_id AS userId
	,TipoStatusAge_id
	,SUM(tStatus) tStatus
	,MIN(dateIni) dateIni
	,MIN(dateEnd) dateEnd
	,currentStatus
	,timeGroup
	,timeGroupNext
	,min(camId) AS camId
	,min(camType) AS camType
	,min(callId) AS callId
FROM #tempccLogAgentesDia
GROUP BY timeGroup
	,user_id
	,TipoStatusAge_id
	,currentStatus
	,timeGroupNext
ORDER BY dateIni
	,userId

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2
'
		EXEC(@Sql)

		SET @process = 'CW-6501 DROP PROCEDURE ccspTimesInboundData'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccspTimesInboundData'')
	begin
	DROP PROCEDURE ccspTimesInboundData;
	end'

		EXEC (@Sql)

		set @process = 'CW-6501 Alter SP ccspTimesInboundData '
		set @Sql= 'CREATE PROCEDURE [dbo].ccspTimesInboundData @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#inboundData'', N''U'') IS NOT NULL
	DROP TABLE #inboundData

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesInboundData''
		)
BEGIN
	CREATE TABLE tmpTimesInboundData (
		[row] INT
		,dateStartDetail DATETIME
		,dateEndDetail DATETIME
		,timegroup DATETIME
		,timegroup_next DATETIME
		,time_endque DATETIME
		,time_ring DATETIME
		,time_dialog DATETIME
		,time_notes DATETIME
		,time_end_call DATETIME
		,phone_in VARCHAR(40)
		,cal_id INT
		,dni_id INT
		,Inbound_id INT
		,[User_id] INT
		,ntotal INT
		,ninitial INT
		,nout_hour INT
		,nout_service INT
		,nabnd INT
		,nno_agent INT
		,nque INT
		,ntimeout INT
		,noverflow INT
		,nxfer INT
		,nxfer_que INT
		,nabnd_xfer INT
		,nabnd_ring INT
		,nno_answer INT
		,nabnd_dialog INT
		,nanswer INT
		,nlost INT
		,nmsg INT
		,nabnd_tres INT
		,nansw_tres INT
		,tque_max INT
		,tque INT
		,txfer INT
		,tdialog INT
		,tnotes INT
		,tring INT
		,tresp INT
		,nMoh INT
		,nWHag INT
		,nWHcl INT
		,statusCall_id INT
		,[dateTResp] DATETIME
		,[dateTACD] DATETIME
		,calif_id INT
		,cal_tMoh int
		,cal_puerto int
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesInboundData
		--drop table tmpTimesInboundData
END

DECLARE @relastionCampWg TABLE (
	idwg INT
	,camId INT
	)

INSERT INTO @relastionCampWg
SELECT MAX(IDWG) AS IDWG
	,IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 0
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT

SELECT @HourExtend = 2

DECLARE @fromExtended AS SMALLDATETIME

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH inboundData
AS (
	SELECT ROW_NUMBER() OVER (
			ORDER BY cal_id ASC
			) AS Row#
		,CASE WHEN cal_Xfer IS NULL
				OR cal_Xfer = ''1900-01-01 00:00:00'' THEN cal_inicio ELSE cal_Xfer END AS dateStartDetail
		,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, CASE WHEN cal_Xfer IS NULL
					OR cal_Xfer = ''1900-01-01 00:00:00'' THEN cal_inicio ELSE cal_Xfer END) dateEndDetail
		,*
	FROM ccCallsIn
	WHERE cal_inicio >= @fromExtended
		AND cal_inicio < @to
		AND INBOUND_ID > 0
	)

INSERT INTO tmpTimesInboundData
SELECT Row#
	,dateStartDetail
	,dateEndDetail
	,dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
	,dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
	,dateStartDetail AS time_endque
	,DATEADD(ss, cal_txfer, dateStartDetail) AS time_ring
	,DATEADD(ss, cal_txfer + cal_tring, dateStartDetail) AS time_dialog
	,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, dateStartDetail) AS time_notes
	,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, dateStartDetail) AS time_end_call
	,cal_Ani AS phone_in
	,cal_id
	,dni_id
	,Inbound_id
	,[User_id]
	,1 AS ntotal
	,CASE WHEN statuscall_id = 1 THEN 1 ELSE 0 END AS ninitial
	,CASE WHEN statuscall_id = 2 THEN 1 ELSE 0 END AS nout_hour
	,CASE WHEN statuscall_id = 3 THEN 1 ELSE 0 END AS nout_service
	,CASE WHEN statuscall_id IN (5, 6) AND cal_que > 0
			AND (cal_xfer is null or  cal_xfer = ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd
	,CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
	,CASE WHEN cal_que > 0 THEN 1 ELSE 0 END AS nque
	,CASE WHEN statuscall_id = 7 THEN 1 ELSE 0 END AS ntimeout
	,CASE WHEN statuscall_id = 8 THEN 1 ELSE 0 END AS noverflow
	,CASE WHEN statuscall_id IN (11, 15, 13, 16)
			OR (
				statuscall_id = 6
				AND cal_xfer <> ''1900-01-01 00:00:00''
				) THEN 1 ELSE 0 END AS nxfer
	,CASE WHEN cal_que > 0
			AND (
				statuscall_id IN (11, 15, 13, 16)
				OR (
					statuscall_id = 6
					AND cal_xfer <> ''1900-01-01 00:00:00''
					)
				) THEN 1 ELSE 0 END AS nxfer_que
	,CASE WHEN (statuscall_id = 11)
			OR (
				statuscall_id = 6
				AND cal_xfer <> ''1900-01-01 00:00:00''
				) THEN 1 ELSE 0 END AS nabnd_xfer
	,CASE WHEN (
				(statuscall_id = 15)
				AND (cal_tring <= @tresRing)
				) THEN 1 ELSE 0 END AS nabnd_ring
	,CASE WHEN (
				(statuscall_id = 15)
				AND (cal_tring > @tresRing)
				) THEN 1 ELSE 0 END AS nno_answer
	,CASE WHEN (
				(statuscall_id = 13)
				AND (cal_tdialog <= @tresDialog)
				) THEN 1 ELSE 0 END AS nabnd_dialog
	,CASE WHEN (
				(statuscall_id = 13)
				AND (cal_tdialog > @tresDialog)
				) THEN 1 ELSE 0 END AS nanswer
	,CASE WHEN (statuscall_id = 16) THEN 1 ELSE 0 END AS nlost
	,CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE 0 END AS nmsg
	,CASE WHEN (
				(
					statuscall_id IN (5, 6)
					AND cal_que > 0
					AND (cal_xfer is null or  cal_xfer = ''1900-01-01 00:00:00'')
					)
				AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)
				) THEN 1 ELSE 0 END AS nabnd_tres
	,CASE WHEN (
				(
					statuscall_id = 13
					AND cal_tdialog > @tresDialog
					)
				AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)
				) THEN 1 ELSE 0 END AS nansw_tres
	,cal_twait AS tque_max
	,cal_twait AS tque
	,cal_txfer AS txfer
	,cal_tdialog AS tdialog
	,cal_tnotas AS tnotes
	,cal_tring AS tring
	,CASE WHEN statuscall_id = 13
			AND cal_tdialog > @tresDialog THEN cal_twait + cal_txfer + cal_tring ELSE 0 END AS tresp
	,CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
	,CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
	,CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
	,statusCall_id
	,dateadd(ss, cal_twait + cal_txfer + cal_tring, cal_Inicio) AS [dateTResp]
	,dateadd(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_Inicio) AS [dateTACD]
	,calif_id
	,cal_tMoh
	,cal_puerto
FROM inboundData

IF CONVERT(DATE, @dateNow, 121) = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId
			,max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN convert(DATE, @to, 121)
				AND @to
		GROUP BY userId
		)
		,timeAcumlate
	AS (
		SELECT A.userId
			,A.camId
			,A.callId
			,sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus ELSE 0 END) AS tdialog
			,sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes
			,max(A.dateEnd) AS dateEnd
			,max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN convert(DATE, @to, 121)
				AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 0
		GROUP BY A.userId
			,A.camId
			,A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd
		,A.timegroup_next = B.timeGroupNext
		,A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.tdialog END
		,A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END
		,A.time_notes = CASE WHEN B.tdialog > 0 THEN B.dateEnd ELSE A.time_dialog END
		,A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
		,A.User_id = CASE WHEN A.User_id > 0 THEN B.userId ELSE A.User_id END
	FROM tmpTimesInboundData A
	INNER JOIN timeAcumlate B ON A.Inbound_id = B.camId
		AND A.cal_id = B.callId
END

SELECT *
INTO #inboundData2
FROM tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

DELETE tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

INSERT INTO tmpTimesInboundData
SELECT [row]
	,dateStartDetail
	,dateEndDetail
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_in
	,cal_id
	,dni_id
	,Inbound_id
	,[User_id]
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ntotal ELSE 0 END AS ntotal
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ninitial ELSE 0 END AS ninitial
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nout_hour ELSE 0 END AS nout_hour
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nout_service ELSE 0 END AS nout_service
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd ELSE 0 END AS nabnd
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nque ELSE 0 END AS nque
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ntimeout ELSE 0 END AS ntimeout
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN noverflow ELSE 0 END AS noverflow
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nxfer ELSE 0 END AS nxfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nxfer_que ELSE 0 END AS nxfer_que
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nanswer ELSE 0 END AS nanswer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nlost ELSE 0 END AS nlost
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nmsg ELSE 0 END AS nmsg
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_tres ELSE 0 END AS nabnd_tres
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nansw_tres ELSE 0 END AS nansw_tres
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN tque_max ELSE 0 END AS tque_max
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
	,dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer
	,dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
	,dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
	,dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nMoh ELSE 0 END AS nMoh
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHag ELSE 0 END AS nWHag
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl
	,statusCall_id
	,[dateTResp]
	,[dateTACD]
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id
	,dbo.AccountInterval(th.start ,th.stop , dateStartDetail,dateEndDetail,cal_tMoh) as cal_tMoh
	,cal_puerto
FROM #inboundData2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timegroup_next
WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
	AND th.Start BETWEEN @from
		AND @to
ORDER BY [row]
	,th.start

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2
'
		EXEC(@Sql)

		SET @process = 'CW-6501 DROP PROCEDURE ccsptmpTimesHoldIn'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsptmpTimesHoldIn'')
	begin
	DROP PROCEDURE ccsptmpTimesHoldIn;
	end'

		EXEC (@Sql)

		set @process = 'CW-6501 Alter SP  ccsptmpTimesHoldIn'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccsptmpTimesHoldIn] @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#hold'', N''U'') IS NOT NULL
	DROP TABLE #hold

IF OBJECT_ID(N''tempdb..tempccHoldSession'', N''U'') IS NOT NULL
	DROP TABLE #tempccHoldSession

IF OBJECT_ID(N''tempdb..#holdMayores2'', N''U'') IS NOT NULL
	DROP TABLE #holdMayores2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesHoldIn''
		)
BEGIN
	CREATE TABLE tmpTimesHoldIn (
		inbound_id INT NOT NULL
		,userId INT NOT NULL
		,tiempohold INT NOT NULL
		,timegroup DATETIME
		,timegroup_next DATETIME
		)
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesHoldIn
		--drop table tmpTimesHoldIn
END

CREATE TABLE #hold (
	Fila INT
	,[userId] INT NOT NULL
	,[dateStart] [datetime] NOT NULL
	,[dateEnd] [datetime] NOT NULL
	,call_id INT NOT NULL
	,inbound_id INT NOT NULL
	,marca INT NOT NULL
	,Tipo_marca INT NOT NULL
	,Tipo_llamada INT NOT NULL
	,[timegroup] [datetime] NOT NULL
	,[timegroup_next] [datetime] NOT NULL
	,[time_dialog] [datetime] NOT NULL
	,[time_notes] [datetime] NOT NULL
	,[time_hold] [datetime] NOT NULL
	)

CREATE TABLE #tempccHoldSession (
	[fila] INT NOT NULL
	,[call_id] [int] NOT NULL
	,[userId] INT NOT NULL
	,[inbound_id] [int] NOT NULL
	,[hold] [datetime] NOT NULL
	,[unhold] [datetime] NULL
	,[Tipo_marca] [int] NOT NULL
	,[timegroup] [datetime] NOT NULL
	,[timegroup_next] [datetime] NOT NULL PRIMARY KEY (
		fila
		,call_id
		)
	)

CREATE TABLE #holdMayores2 (
	call_id INT NOT NULL
	,[userId] INT NOT NULL
	,inbound_id INT NOT NULL
	,hold [datetime] NOT NULL
	,[unhold] [datetime] NOT NULL
	,Tipo_marca INT NOT NULL
	,tiempoHold INT NOT NULL
	,[timegroup] [datetime] NOT NULL
	,[timegroup_next] [datetime] NOT NULL
	);

WITH timeHold
AS (
	SELECT User_id AS userId
		,cal_Inicio AS [dateStart]
		,dateadd(ss, cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas, cal_Inicio) AS [dateEnd]
		,cal_id AS cal_id
		,inbound_id AS inbound_id
		,isnull(h.marca, 0) AS Marca
		,CASE WHEN (h.tipo_marca > 0) THEN h.tipo_marca ELSE 0 END AS Tipo_marca
		,isnull(tipo_llamada, 0) AS Tipo_llamada
		,dbo.GetTimeGroup(cal_Inicio, 0) AS timegroup
		,dbo.GetTimeGroup(dateadd(ss, cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas, cal_Inicio), 1) AS timegroup_next
		,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring, 0), cal_inicio) AS time_dialog
		,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog, 0), cal_inicio) AS time_notes
		,DATEADD(ss, isnull(cal_twait + cal_txfer + cal_tring + marca, 0), cal_Inicio) AS time_hold
	FROM cccallsin i(NOLOCK)
	LEFT JOIN RiaMarkHold h(NOLOCK)
		ON i.cal_id = h.call_id
			AND h.tipo_llamada = 1
	WHERE cal_Inicio BETWEEN @from
			AND @to
	)
INSERT INTO #hold
SELECT ROW_NUMBER() OVER (
		PARTITION BY cal_id ORDER BY time_hold
			,tipo_marca
		) Fila
	,*
FROM timeHold a
WHERE time_hold >= @from
	AND time_hold <= @to

INSERT INTO #tempccHoldSession
SELECT A.Fila
	,A.call_id
	,a.userId
	,a.inbound_id
	,A.time_hold hold
	,isnull(S.time_hold, a.time_notes) unhold
	,a.Tipo_marca Tipo_marca
	,a.timegroup timegroup
	,a.timegroup_next timegroup_next
FROM #hold A
LEFT JOIN #hold S
	ON A.Fila = S.Fila - 1
		AND A.call_id = S.call_id
		AND A.tipo_marca = 1
		AND S.tipo_marca = 0
WHERE A.tipo_llamada = 1
ORDER BY hold

SELECT ths.call_id
	,ths.userId
	,ths.inbound_id
	,ths.hold
	,ths.unhold
	,ths.Tipo_marca
	,[dbo].TimeInterval(th.[start], th.[stop], ths.hold, ths.unhold) AS tiempohold
	,ths.timegroup
	,ths.timegroup_next
INTO #tiempoHold
FROM #tempccHoldSession ths
INNER JOIN TmpTimesInterval th
	ON (
			ths.timegroup > th.Start
			AND ths.timegroup < th.stop
			)
		OR th.Start BETWEEN ths.timegroup
			AND ths.timegroup_next
WHERE [dbo].TimeInterval(th.[start], th.[stop], ths.hold, ths.unhold) > 0
	AND Tipo_marca = 1
	AND th.Start BETWEEN @from
		AND @to

INSERT INTO #holdMayores2
SELECT *
FROM #tiempoHold
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE #tiempoHold
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO #tiempoHold
SELECT call_id
	,userId AS userId
	,inbound_id AS inbound_id
	,hold
	,unhold
	,Tipo_marca
	,[dbo].TimeInterval(th.[start], th.[stop], hold, unhold) AS tiempohold
	,th.[start] AS timegroup
	,th.[stop] AS timegroup_next
FROM #holdMayores2 t
INNER JOIN TmpTimesInterval th
	ON (
			t.timegroup > th.Start
			AND t.timegroup < th.stop
			)
		OR th.Start BETWEEN t.timegroup
			AND t.timegroup_next
WHERE [dbo].TimeInterval(th.[start], th.[stop], hold, unhold) > 0
	AND th.Start BETWEEN @from
		AND @to

INSERT INTO tmpTimesHoldIn
SELECT inbound_id
	,userId
	,sum(tiempohold) AS tiempohold
	,timegroup
	,timegroup_next
FROM #tiempoHold
WHERE tiempoHold > 0
	AND Tipo_marca = 1
GROUP BY userId
	,inbound_id
	,timegroup
	,timegroup_next

IF OBJECT_ID(N''tempdb..#hold'', N''U'') IS NOT NULL
	DROP TABLE #hold

IF OBJECT_ID(N''tempdb..tempccHoldSession'', N''U'') IS NOT NULL
	DROP TABLE #tempccHoldSession

IF OBJECT_ID(N''tempdb..#holdMayores2'', N''U'') IS NOT NULL
	DROP TABLE #holdMayores2
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepAgentCallStatusesByInterval'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
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

	
	IF OBJECT_ID(N''tempdb..#tempNotReady'', N''U'') IS NOT NULL  drop table #tempNotReady
	IF OBJECT_ID(N''tempdb..#tempNotReady2'', N''U'') IS NOT NULL  drop table #tempNotReady2

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

	--Columnas Tiempo en capacitación (ND) = tnav, Tiempo en “trabajo previo a llamada” = twbcall
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
	from TmpSessionTimeGroup A
	inner join ccUserView U on A.User_id = U.User_id
	left join timeDetailAgent B on A.timegroup=B.timegroup and A.user_id=B.userId
	left join outCall C on A.timegroup=C.timegroup and A.user_id=C.userId
	left join TransferCall T on A.timegroup=T.timegroup and A.user_id=T.userId
	left join NotReady n  on A.timegroup=n.timegroup and A.user_id=n.userId
	order by [date],userId	   
	

	---DROP TABLES TEMP
	IF OBJECT_ID(N''tempdb..#tempNotReady'', N''U'') IS NOT NULL  drop table #tempNotReady
	IF OBJECT_ID(N''tempdb..#tempNotReady2'', N''U'') IS NOT NULL  drop table #tempNotReady2
	
	end
end'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepAgentGI'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentGI] @action AS TINYINT
	,@from AS DATETIME
	,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
	SELECT @to = GETDATE();

IF @action = 1
BEGIN
	IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL
		DROP TABLE #timeDetailAgent;

	CREATE TABLE #timeDetailAgent (
		[User_id] INT NULL
		,dateStartDetail DATETIME NULL
		,dateEndDetail DATETIME NULL
		,timegroup DATETIME NULL
		,timegroup_next DATETIME NULL
		,tunknown INT NULL
		,tnot_av INT NULL
		,tav INT NULL
		,tprob INT NULL
		,tother INT NULL
		,nother INT NULL
		,tmanualcall INT NULL
		,tunknown2 DECIMAL(10, 3)
		,tchatting INT NULL
		,tReconnectKolob INT NULL
		,tPreview INT NULL
		,tAssisted INT NULL
		,tDialogoWhatsApp INT NULL
		);

	INSERT INTO #timeDetailAgent
	SELECT A.userId
		,A.dateIni
		,A.dateEnd
		,A.timegroup
		,A.timeGroupNext
		,CASE WHEN A.tipostatusage_id = 1 THEN A.tStatus ELSE 0 END tunknown
		,CASE WHEN A.tipostatusage_id = 2 THEN A.tStatus ELSE 0 END tnot_av
		,CASE WHEN A.tipostatusage_id IN (3, 31) THEN A.tStatus ELSE 0 END tav
		,--3	Ready y 31	Ready PreviewPro
		CASE WHEN A.tipostatusage_id IN (11, 25, 26, 27) THEN A.tStatus ELSE 0 END tprob
		,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
		CASE WHEN A.tipostatusage_id = 7 THEN A.tStatus ELSE 0 END tother
		,CASE WHEN A.tipostatusage_id = 7 THEN 1 ELSE 0 END nother
		,CASE WHEN A.tipostatusage_id = 21 THEN A.tStatus ELSE 0 END tmanualcall
		,CASE WHEN ABS(ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0)) > A.tStatus THEN 0 WHEN A.currentStatus IN (0, - 1, - 2) THEN 0 --Logout
			WHEN S.TipoStatusAge_id = 1 THEN 0 ELSE ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0) END AS tunknown2
		,CASE WHEN A.tipostatusage_id IN (23, 24) THEN A.tStatus ELSE 0 END AS tchatting
		,CASE WHEN A.tipostatusage_id = 30 THEN A.tStatus ELSE 0 END AS tReconnectKolob
		,CASE WHEN A.tipostatusage_id = 32 THEN A.tStatus ELSE 0 END AS tPreview
		,CASE WHEN A.tipostatusage_id = 33 THEN A.tStatus ELSE 0 END AS tAssisted
		,CASE WHEN A.tipostatusage_id = 34 THEN A.tStatus ELSE 0 END AS tDialogoWhatsApp
	FROM tmpccLogAgentesDia A
	LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
		AND A.userId = S.userId

	UPDATE #timeDetailAgent
	SET tunknown2 = 0
	WHERE ABS(tunknown2) > 2.7;

	DELETE	FROM RepAgentGI	WHERE DATE >= @from		AND DATE < @to

	;WITH inboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,nxfer AS nxferin
			,nanswer AS nanswerin
			,nabnd_xfer AS nabndxferin
			,nabnd_ring AS nabndringin
			,nabnd_dialog AS nabnddlgin
			,(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
			,nno_answer AS nnoanswerin
			,nlost AS nlostin
			,nMoh AS nMohIn
			,nWHag AS nWHagIn
			,nWHcl AS nWHclIn
			,tdialog AS tdialogIn
			,tnotes AS tnotesIn
			,tring AS tringIn
			,txfer AS txferIn
			,cal_id AS callIdIn
			,phone_in AS phoneIn
			,dateStartDetail AS dateStartDetailIn
		FROM tmpTimesInboundData
		WHERE user_id > 0
		)
		,outboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,nxfer AS nxferOut
			,nanswer AS nanswerOut
			,nabnd_xfer AS nabndxferOut
			,nabnd_ring AS nabndringOut
			,nabnd_dialog AS nabnddlgOut
			,(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
			,nno_answer AS nnoanswerOut
			,nlost AS nlostOut
			,nMoh AS nMohOut
			,nWHag AS nWHagOut
			,nWHcl AS nWHclOut
			,tdialog AS tdialogOut
			,tnotes AS tnotesOut
			,tring AS tringOut
			,txfer AS txferOut
			,cal_id AS callIdOut
			,phone_out AS phoneOut
			,dateStartDetail AS dateStartDetailOut
		FROM tmpTimesOutboundData
		WHERE user_id > 0
			AND cal_manual IN (0, 2, 3)
		)
		,agentTime
	AS (
		SELECT user_Id
			,timegroup
			,sum(nother) nOther
			,sum(tunknown) tunknown
			,sum(tnot_av) tnotAv
			,sum(tav) tav
			,sum(tother) AS tother
			,sum(tprob) AS tprob
			,sum(tchatting) AS tchatting
		FROM #timeDetailAgent
		GROUP BY user_Id
			,timegroup
		), outboundCountGroup as(
		select timegroup ,userId
		,sum(tdialogOut) tdialogOut
		,sum(tnotesOut) tnotesOut
		,sum(tringOut) tringOut
		,sum(txferOut) txferOut
		from outboundCount
		group by timegroup ,userId
		), inboundCountGroup as(
		select timegroup ,userId
		,sum(tdialogIn) tdialogIn
		,sum(tnotesIn) tnotesIn
		,sum(tringIn) tringIn
		,sum(txferIn) txferIn
		from inboundCount
		group by timegroup ,userId
		)

	
	
	INSERT INTO RepAgentGI
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,
		---------------- Count IN Call -----------------------
		ISNULL(inCount.nxferin, 0) nXferIn
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
		,
		---------------- Count Out Call -----------------------      
		0 AS nXferOut
		,0 AS nAnswerOut
		,0 AS nAbndXferOut
		,0 AS nabndringOut
		,0 AS nAbnddlgOut
		,0 AS abndaXferOut
		,0 AS nnoAnswerOut
		,0 AS nlostOut
		,0 AS tdialogOut
		,0 tnotesOut
		,0 tringOut
		,0 txferOut
		
		---------------- Time Agent Common -----------------------      
		,0 nOther
		,0 tunknown
		,0 tnotAv
		,0 as tlog
		,0 tav
		,0 tOther
		,0 tprob
		,
		---------------- Count In/Out Call-----------------------      
		isnull(inCount.nMohIn, 0) AS nMohIn
		,0 AS nMohOut
		,isnull(inCount.nWHagIn, 0) AS nWHagIn
		,0 AS nWHagOut
		,isnull(inCount.nWHclIn, 0) AS nWHclIn
		,0 AS nWHclOut
		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,
		---------------- Detail In Call-----------------------      
		isnull(inCount.phoneIn, '''') AS phoneIn
		,isnull(inCount.dateStartDetailIn, '''') AS dateStartDetailIn
		,isnull(inCount.callIdIn, 0) AS callIdIn
		,
		---------------- Detail out Call-----------------------      
		'''' AS phoneOut
		,''1900-01-01'' AS dateStartDetailOut
		,0 AS callIdOut
		---------------- Time Agent Common -----------------------      
		,0 tnotAvg
		,0 AS tundefined
		,0 tchatting
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	
	UNION ALL
	
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,
		---------------- Count IN Call -----------------------
		0 nXferIn
		,0 nAnswerIn
		,0 nAbndXferIn
		,0 nAbndRingIn
		,0 AS nAbnddlgIn
		,0 abndaXferIn
		,0 AS nnoAnswerIn
		,0 AS nlostIn
		,0 tdialogIn
		,0 tnotesIn
		,0 tringIn
		,0 txferIn
		,
		---------------- Count Out Call -----------------------      
		isnull(outTime.nXferOut, 0) nXferOut
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
		,
		---------------- Time Agent Common -----------------------      
		0 AS nOther
		,0 AS tunknown
		,0 AS tnotAv
		,0 AS tlog
		,0 AS tav
		,0 AS tOther
		,0 AS tprob
		,
		---------------- Count In/Out Call-----------------------      
		0 AS nMohIn
		,isnull(outTime.nMohOut, 0) AS nMohOut
		,0 AS nWHagIn
		,isnull(outTime.nWHagOut, 0) AS nWHagOut
		,0 AS nWHclIn
		,isnull(outTime.nWHclOut, 0) AS nWHclOut
		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,
		---------------- Detail In Call-----------------------      
		'''' AS phoneIn
		,''1900-01-01'' AS dateStartDetailIn
		,0 AS callIdIn
		,
		---------------- Detail out Call-----------------------      
		isnull(outTime.phoneOut, '''') AS phoneOut
		,isnull(outTime.dateStartDetailOut, ''1900-01-01'') AS dateStartDetailOut
		,isnull(outTime.callIdOut, 0) AS callIdOut
		---------------- Time Agent Common -----------------------      
		,0 tnotAvg
		,0 AS tundefined
		,0 tchatting
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	LEFT JOIN outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id


	---------------------SOLO TIEMPOS  ---------------------
	union All
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,
		---------------- Count IN Call -----------------------
		0 nXferIn
		,0 nAnswerIn
		,0 nAbndXferIn
		,0 nAbndRingIn
		,0 AS nAbnddlgIn
		,0 abndaXferIn
		,0 AS nnoAnswerIn
		,0 AS nlostIn
		,0 AS tdialogIn
		,0 tnotesIn
		,0 tringIn
		,0 txferIn
		,
		---------------- Count Out Call -----------------------      
		0 AS nXferOut
		,0 AS nAnswerOut
		,0 AS nAbndXferOut
		,0 AS nabndringOut
		,0 AS nAbnddlgOut
		,0 AS abndaXferOut
		,0 AS nnoAnswerOut
		,0 AS nlostOut
		,0 AS tdialogOut
		,0 tnotesOut
		,0 tringOut
		,0 txferOut
		,
		---------------- Time Agent Common -----------------------      
		isnull(agentTime.nOther, 0) nOther
		,isnull(agentTime.tunknown, 0) tunknown
		,isnull(agentTime.tnotAv, 0) tnotAv
		,A.tlog as tlog
		,isnull(agentTime.tav, 0) tav
		,isnull(agentTime.tOther, 0) tOther
		,isnull(agentTime.tprob, 0) tprob
		,
		---------------- Count In/Out Call-----------------------      
		0 AS nMohIn
		,0 AS nMohOut
		,0 AS nWHagIn
		,0 AS nWHagOut
		,0 AS nWHclIn
		,0 AS nWHclOut
		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,
		---------------- Detail In Call-----------------------      
		'''' AS phoneIn
		,''1900-01-01'' AS dateStartDetailIn
		,0 AS callIdIn
		,
		---------------- Detail out Call-----------------------      
		'''' AS phoneOut
		,''1900-01-01'' AS dateStartDetailOut
		,0 AS callIdOut
		---------------- Time Agent Common -----------------------      
		,isnull(agentTime.tnotAv, 0) tnotAvg
		,A.tlog - isnull(inCount.tdialogin, 0) - isnull(inCount.tnotesin, 0) - isnull(inCount.tringin, 0) - isnull(inCount.txferin, 0) 
		- isnull(outTime.tdialogOut, 0) - isnull(outTime.tnotesOut, 0) - isnull(outTime.tringOut, 0) - isnull(outTime.txferOut, 0) 
		- isnull(agentTime.tunknown, 0) - isnull(agentTime.tnotAv, 0) - isnull(agentTime.tav, 0) - isnull(agentTime.tOther, 0) 
		- isnull(agentTime.tprob, 0) - isnull(agentTime.tchatting, 0) 
		
		AS tundefined
		,isnull(agentTime.tchatting, 0) tchatting
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	LEFT JOIN inboundCountGroup inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	LEFT JOIN agentTime ON agentTime.User_id = A.user_id AND agentTime.timegroup = A.timegroup
	LEFT JOIN outboundCountGroup outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id

	--ORDER BY userId		,[date]

	IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL
		DROP TABLE #timeDetailAgent;
END;
'
		EXEC(@Sql)
		
		set @process = 'CW-6501 Alter SP  ccspRepAgentNotReady'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
		
	
IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL
	DROP TABLE #notReady

IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL
	DROP TABLE #notReady2;

WITH notReadyDetail
AS (
	SELECT user_id userId, DATEADD(s, - tstatus, fecha) AS startDate, fecha endDate, tStatus, separado, TipoNotReady_id AS TipoNotReadyId, convert(DATETIME, convert(VARCHAR(13), DATEADD(ss, - tStatus, fecha), 121) + '':00:00''
			, 121) AS timegroup, convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, fecha), 121) + '':00:00'', 121) AS timegroup_next
	FROM ccLogAgentesNotReady
	WHERE fecha BETWEEN @from
			AND @to
	)
--TmpSessionTimeGroup
SELECT timegroup, timegroup_next, userId, TipoNotReadyId, tStatus AS [time], startDate, endDate, 1 AS [count]
INTO #notReady
FROM notReadyDetail

SELECT *
INTO #notReady2
FROM #notReady
WHERE DATEDIFF(hh, timegroup, timegroup_next) > 1

DELETE #notReady
WHERE datediff(HH, timegroup, timegroup_next) > 1	
	;

	
	--Delete tepetidos
	delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to;
	

WITH timebyHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), Start, 121) + '':00:00'', 121) AS [start], convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + '':00:00'', 121) AS [stop]
	FROM TmpTimesInterval
	GROUP BY convert(VARCHAR(13), Start, 121), convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + '':00:00'', 121)
	), notReadybyHour
AS (
	SELECT th.start AS timegroup, th.stop AS timegroup_next, userId, TipoNotReadyId, dbo.TimeInterval(th.start, th.stop, startDate, endDate) AS [time], startDate, endDate, dbo.AccountInterval(th.start, th.stop, 
			startDate, endDate, [count]) AS [count]
	FROM #notReady2 t
	INNER JOIN timebyHour th
		ON (
				t.timegroup > th.Start
				AND t.timegroup < th.stop
				)
			OR th.Start BETWEEN t.timegroup
				AND t.timegroup_next
	WHERE datediff(ss, th.start, timegroup_next) > 0
	
	UNION
	
	SELECT *
	FROM #notReady
	), timeSessionByHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + '':00:00'', 121) AS timegroup, user_id AS userId, sum(tlog) AS tlog
	FROM TmpSessionTimeGroup
	GROUP BY convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + '':00:00'', 121), user_id
	), notReadyGroupbyHour
AS (
	SELECT timegroup, timegroup_next, userId, TipoNotReadyId, sum([time]) AS [time], min(startDate) startDate, max(endDate) endDate, sum([count]) [count]
	FROM notReadybyHour
	GROUP BY timegroup, timegroup_next, userId, TipoNotReadyId
	)

insert into RepAgentNotReady
SELECT A.timegroup, userView.[Login]
, A.userId, userView.apellidopaterno + '' '' + userView.apellidomaterno + '' '' + userView.nombres AS [user]
, A.tlog AS sessionTime
, isnull(notReady.TipoNotReadyId,0) as TipoNotReadyId, isnull(d.descripcion, '''') 
	descripcion, isnull(d.descripcion, '''') + ''_Count'' AS descripcion_count, isnull(notReady.[count], 0) [count], isnull(d.descripcion, '''') + ''_Time'' AS descripcion_time, isnull(notReady.TIME, 0) AS [time], isnull(
		notReady.TIME, 0) AS timeSeconds
		,datepart(yyyy,A.timegroup) as [year]
		,datepart(HH,A.timegroup) as [mount]
		,datepart(MM,A.timegroup) as [day]
		,datepart(mi,A.timegroup) as [hour]
		,0 as minute
FROM timeSessionByHour A
INNER JOIN ccUserView userView
	ON A.userId = userView.User_id
LEFT JOIN notReadyGroupbyHour notReady
	ON notReady.userId = A.userId
		AND A.timegroup = notReady.timegroup
LEFT JOIN ccTipoNotReady d
	ON notReady.TipoNotReadyId = d.TipoNotReady_id

IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL
	DROP TABLE #notReady

IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL
	DROP TABLE #notReady2


	
end'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepAgentNotReadyDet'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE
	FROM RepAgentNotReadyDet
	WHERE DATE >= @from
		AND DATE < @to;

	WITH notReadyDetail
	AS (
		SELECT user_id, DATEADD(s, - tstatus, fecha) AS fechaInicio, fecha, tStatus, separado, TipoNotReady_id		
		FROM ccLogAgentesNotReady
		WHERE fecha BETWEEN @from
				AND @to
		)
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(DATE, fechaInicio, 121) [date], isNull(usr.[Login], ''systemTranslated_NoUserName'') AS [login], xdet.user_Id AS userId, isNull(usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno + '' '' + usr.Nombres, 
			''systemTranslated_NoName'') AS [user], xdet.TipoNotReady_id AS tiponotreadyId, isNull(tn.Descripcion, ''systemTranslated_NoStatus'') AS [status], fechaInicio AS startDate, fecha AS endDate, tStatus AS 
		statusTime, tStatus AS statusTimeSeconds, datepart(yyyy, fechaInicio) [year], datepart(mm, fechaInicio) [mounth], datepart(dd, fechaInicio) [day], datepart(hh, fechaInicio) [hour], datepart(mi, fechaInicio) 
		[minute]
	FROM notReadyDetail xdet
	LEFT JOIN ccUserView usr
		ON usr.user_id = xdet.user_id
	LEFT JOIN ccTipoNotReady tn
		ON tn.tipoNotready_id = xdet.tiponotready_id
	ORDER BY startDate
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepAgentSummary'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
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
	SELECT A.[date], A.[login], A.[user], '''' AS campaing, A.sessionTime, A.dateLogin AS loginMktTime, A.logout AS logoutMktTime, isnull(co.tDialogOut, 0) + isnull(co.tNotesOut, 0) + isnull(ci.tDialogIn, 0) + isnull(ci.tNotesIn, 0) dialogTime, ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn, ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta, ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend, ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif, ISNULL(t.break_, 0) AS NdBreak, ISNULL(t.personal_, 0) AS NdPersonal, ISNULL(t.pagos_, 0) AS NdPagos, ISNULL(t.trabajoAdm_, 0) AS NdTrabajoAdm, ISNULL(t.retro_, 0) AS NdRetro, ISNULL(t.falla_, 0) AS NdFalla, ISNULL(t.capacitacion_, 0) AS NdCapacitacion, ISNULL(t.CWCallWork_, 0) AS NdCWCallWork, ISNULL(t.pausagrl_, 0) AS NdPausaGrl, ISNULL(t.rh_, 0) AS NdRH, ISNULL(t.inicio_, 0) AS NdInicio, ISNULL(a.sessionTime, 0) - ISNULL(r.notready, 0) AS 
		Available, ISNULL((ISNULL(co.tDialogOut, 0)) + (ISNULL(co.tNotesOut, 0)) + (ISNULL(ci.tDialogIn, 0)) + (ISNULL(ci.tNotesIn, 0)) / ((co.AttendedCallOut) + (ci.AttendedCallIn)), 0) AS PromDialog, 0 AS Skill, ''Verde'' AS Center, ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
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
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepCallTimeSummary '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepCallTimeSummary]
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
	
	IF OBJECT_ID(''tempdb..#chats'') IS NOT NULL drop table #chats;
	IF OBJECT_ID(''tempdb..#chatsMayores'') IS NOT NULL drop table #chatsMayores;
	

CREATE TABLE #chats([user_id] [smallint] NOT NULL
,chatStart datetime not null,chatEnd datetime not null, timeChat smallint not null
,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL,chat_id int not null,total int not null
)

CREATE TABLE #chatsMayores([user_id] [smallint] NOT NULL
,chatStart datetime not null,chatEnd datetime not null,timeChat smallint not null
,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL,chat_id int not null,total int not null
)

--------------------CHATS---------------------------------------
;with timeChats as( --CTE
select userId,isnull(chatDate,requestDate) as chatStart,dateadd(ss,tChatting,isnull(chatDate,requestDate)) as chatEnd,tChatting,chatId
from ccriachats where chatStatus=4 and userId>0 and requestDate between @from and @to
)

insert into #chats
select userId,chatStart,chatEnd,tChatting,
dbo.GetTimeGroup(chatStart,0),dbo.GetTimeGroup(chatEnd,1),chatId,1 as total
from timeChats

INSERT into #chatsMayores SELECT * from #chats where datediff(mi,timegroup,timegroup_next)>15
delete #chats where  datediff(mi,timegroup,timegroup_next)>15


insert into #chats
select [user_id],t.chatStart,t.chatEnd, 
	dbo.TimeInterval(th.start,th.stop,t.chatStart,t.chatEnd) as [tChatting]	 
	,convert(datetime,th.start,121) as timegroup, convert(datetime, th.stop,121) as timegroup_next
	,chat_id
	,case when th.start > t.chatStart and th.stop > t.chatEnd then 1 else 0 end as ntotal
from #chatsMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;

DELETE	FROM RepCallTimeSummary WITH (ROWLOCK)		WHERE DATE >= @from AND DATE < @to

-------------------------------CTE''S--------------------------

;
WITH logAgentDia
AS (
	SELECT userId, timegroup, isnull(sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END), 0) AS timeAux, isnull(sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END), 0) AS timeDisp
	FROM tmpccLogAgentesDia
	WHERE TipoStatusAge_id IN (2, 3)
	GROUP BY timegroup, userId
	), callTimeGroup
AS (
	SELECT user_id, timegroup, sum(tdialog) AS cal_tDialog, sum(ntotal) totalIn, avg(tdialog) avgtimein
	FROM tmpTimesInboundData A
	GROUP BY A.[User_id], A.timegroup
	), callTimeGroupOutbound
AS (
	SELECT user_id, timegroup, sum(tdialog) AS cal_tDialog, sum(ntotal) totalOut, avg(tdialog) avgtimeout
	FROM tmpTimesOutboundData A
	GROUP BY A.[User_id], A.timegroup
	), AbandTime
AS (
	SELECT A.user_id, A.timegroup, count(DISTINCT cal_id) AS totalAband
	FROM tmpTimesInboundData A
	WHERE statusCall_id IN (
			SELECT statusCall_id
			FROM ccstatusllamada
			WHERE inAbandonConfig = 1
			)
	GROUP BY A.[User_id], A.timegroup
	)
	,chatTime as( --CTE
select A.user_id,A.timegroup,sum(timeChat) as timeChat,sum(total) as totalChat,avg(total) avgtTotal,avg(timeChat) avgttimeChat from #chats A
group by A.[User_id],A.timegroup
)

--------------------QUERY---------------------------------------
INSERT INTO RepCallTimeSummary
SELECT A.timegroup AS [date], A.user_id AS userId, u.Nombres + '' '' + u.ApellidoPaterno ''user'', u.LOGIN ''Agent'', a.tlog ''sesionTime''
	, ISNULL(auxt.timeAux, 0) ''unavailableTime''
	, ISNULL(auxt.timeDisp, 0) ''TiempoDispo''
	, stuff( right(convert(VARCHAR(30), A.LOGIN, 109), 14), 9, 4, '' '') ''sessionStart''
	, stuff(right(convert(VARCHAR(30), A.logout, 109), 14), 9, 4, '' '') ''sessionEnd''
	, isnull(callIn.cal_tDialog, 0) + isnull(callOut.cal_tDialog , 0) ''generalDialog''
	, isnull((isnull(callIn.cal_tDialog, 0) + isnull(callOut.cal_tDialog, 0)) / (nullif(isnull(callIn.totalIn, 0) + isnull(callOut.totalOut, 0), 0)), 0) ''avgCallTime'' 
	,isnull(callIn.cal_tDialog, 0) ''inboundDialog''
	, isnull(callIn.avgtimein, 0) AS ''avginboundDialog''
	, isnull(callOut.cal_tDialog, 0) ''outboundDialog''
	, isnull(callOut.avgtimeout, 0) ''avgoutboundDialog''	
	,isnull(chatTime.timeChat,0) as ''chatTime''
	,ISNULL(chatTime.avgttimeChat,0) as ''avgchatTime''
	,isnull(chatTime.totalChat,0) as ''attendedChat''
	, isnull(callOut.totalOut, 0) AS ''callsOut''
	, isnull(callIn.totalIn, 0) AS ''callsIn'', isnull(abant.totalAband, 0) AS ''abandonedCalls''
	, isnull(callOut.totalOut, 0) + isnull(callIn.totalIn, 0) ''answerCalls''
	, datepart(yyyy, A.timegroup) AS [year]
	, datepart(mm, A.timegroup) AS [month]
	, datepart(dd, A.timegroup) AS [day]
	, datepart(hh, A.timegroup) AS [hour]
	, datepart(mi, A.timegroup) 
	AS [minutes]
FROM TmpSessionTimeGroup A
LEFT JOIN ccUserView u	ON A.user_id = u.User_id
LEFT JOIN logAgentDia auxt	ON A.user_id = auxt.userId		AND A.timegroup = auxt.timegroup 
LEFT JOIN callTimeGroup callIn	ON A.user_id = callIn.user_id		AND A.timegroup = callIn.timegroup
LEFT JOIN callTimeGroupOutbound callOut	ON A.user_id = callOut.user_id		AND A.timegroup = callOut.timegroup
LEFT JOIN AbandTime abant	ON A.timegroup = abant.timegroup
left join chatTime chatTime on A.user_id=chatTime.user_id and A.timegroup=chatTime.timegroup
ORDER BY [date], userId

IF OBJECT_ID(''tempdb..#chats'') IS NOT NULL drop table #chats;
IF OBJECT_ID(''tempdb..#chatsMayores'') IS NOT NULL drop table #chatsMayores;

	
END'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepInEffectiveness'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepInEffectiveness] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
SET NOCOUNT ON
SET ANSI_NULLS OFF
SET ANSI_WARNINGS OFF

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()


IF @action = 1
BEGIN
	--Consulta de agentes conectados agrupados por hora e inboundid
	CREATE TABLE [dbo].[#ccGenSession] ([user_id] [smallint] NOT NULL, fechaInicio [datetime] NOT NULL, [tlog] INT NOT NULL) ON [PRIMARY]

	CREATE TABLE #AgentsperInbound (NumberAgents INT, fechaInicio DATETIME, fechaFinal DATETIME, Inbound_id INT)

	INSERT INTO [#ccGenSession]
	SELECT A.user_id, convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS fechaInicio, sum(tlog) tlog
	FROM TmpSessionTimeGroup A
	GROUP BY A.user_id, convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121);

	WITH RtnValue3
	AS (
		SELECT DISTINCT 1 AS cont, A.user_id, B.Inbound_id, A.fechaInicio, DATEADD(hh, 1, A.fechaInicio) AS fechaFinal
		FROM [#ccGenSession] A
		INNER JOIN ccinboundagentes B
			ON A.user_id = B.User_id
		)
	INSERT INTO #AgentsperInbound
	SELECT sum(cont) AS NumberAgents, fechaInicio, fechaFinal, Inbound_id
	FROM RtnValue3
	GROUP BY fechaInicio, fechaFinal, Inbound_id

	--Fin consulta agentes conectados por inbound
	CREATE TABLE [dbo].[#ccGenInCall] (
		[timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [dni_id] [smallint] NOT NULL, [user_id] [smallint] NOT NULL, [ntotal] [smallint] NOT NULL, [nabnd] [smallint] NOT NULL, [nno_agent] [smallint] NOT 
		NULL, [nque] [smallint] NOT NULL, [ntimeout] [smallint] NOT NULL, [noverflow] [smallint] NOT NULL, [nno_answer] [smallint] NOT NULL, [nanswer] [smallint] NOT NULL, [nlost] [smallint] NOT NULL, [nabnd_tres] [smallint] 
		NOT NULL, [nansw_tres] [smallint] NOT NULL, [tque_max] [smallint] NOT NULL, [tque] [int] NOT NULL, [txfer] [int] NOT NULL, [tdialog] [int] NOT NULL, [tnotes] [int] NOT NULL, [tring] [int] NOT NULL, [tresp] [int] NOT NULL, 
		[nMoh] [smallint] NOT NULL DEFAULT((0)), [nWHag] [smallint] NOT NULL DEFAULT((0)), [nWHcl] [smallint] NOT NULL DEFAULT((0))
		) ON [PRIMARY]

	CREATE TABLE [dbo].[#agents] (
		[timegroup] [smalldatetime] NOT NULL, [user_id] [smallint] NOT NULL, [tlog] [int] NOT NULL DEFAULT(0), [treq] [int] NOT NULL DEFAULT(0), [tnot_av] [int] NOT NULL, [tav] [int] NOT NULL DEFAULT(0), [tprob] [int] NOT NULL 
		DEFAULT(0), [tunknown] [int] NOT NULL DEFAULT(0), [tother] [int] NOT NULL DEFAULT(0), [nother] [int] NOT NULL DEFAULT(0), [nMoh] [int] NOT NULL DEFAULT((0)), [nWHag] [int] NOT NULL DEFAULT((0
				)), [nWHcl] [int] NOT NULL DEFAULT((0))
		) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInSpec] ([timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [pos_tot] [smallint] NOT NULL, [pos_time] [int] NOT NULL, [pos_efect] [smallint] NOT NULL) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInAbnd] (
		[timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [amount] [smallint] NOT NULL, [time_max] [smallint] NOT NULL, [time_tot] [bigint] NOT NULL, [<10] [smallint] NOT NULL, [<20] [smallint] NOT NULL, 
		[<30] [smallint] NOT NULL, [<40] [smallint] NOT NULL, [<50] [smallint] NOT NULL, [<60] [smallint] NOT NULL, [<120] [smallint] NOT NULL, [<180] [smallint] NOT NULL, [<240] [smallint] NOT NULL, [<300] [smallint] NOT NULL, 
		[+300] [smallint] NOT NULL
		) ON [PRIMARY]

	INSERT INTO #ccGenInCall (
		timegroup, inbound_id, dni_id, [user_id], ntotal, nabnd, nno_agent, nque, ntimeout, noverflow, nno_answer, nanswer, nlost, nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, tnotes, tresp, nMoh, nWHag, 
		nWHcl
		)
	SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS timegroup, Inbound_id, dni_id, User_id, isnull(sum(ntotal), 0) AS ntotal, isnull(sum(nabnd), 0) AS nabnd, isnull(sum(nno_agent), 0) AS 
		nno_agent, isnull(sum(nque), 0) AS nque, isnull(sum(ntimeout), 0) AS ntimeout, isnull(sum(noverflow), 0) AS noverflow, isnull(sum(nno_answer), 0) AS nno_answer, isnull(sum(nanswer), 0) AS nanswer, isnull(sum(nlost
			), 0) AS nlost, isnull(sum(nabnd_tres), 0) AS nabnd_tres, isnull(sum(nansw_tres), 0) AS nansw_tres, isnull(max(tque_max), 0) AS tque_max, isnull(sum(tque), 0) AS tque, isnull(sum(txfer), 0) AS txfer, isnull(sum(
				tdialog), 0) AS tdialog, isnull(sum(tnotes), 0) AS tnotes, isnull(sum(tring), 0) AS tring, isnull(sum(tresp), 0) AS tresp, isnull(sum(nMoh), 0) AS nMoh, isnull(sum(nWHag), 0) AS nWHag, isnull(sum(nWHcl), 0) AS 
		nWHcl
	FROM tmpTimesInboundData
	GROUP BY convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121), inbound_id, dni_id, [user_id];

	WITH timeAgent
	AS (
		SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) timegroup, userId, ISNULL(SUM(CASE WHEN (tipostatusage_id = 2) THEN tStatus ELSE NULL END), 0) AS 
			tnot_av, ISNULL(SUM(CASE WHEN (tipostatusage_id = 3) THEN tStatus ELSE NULL END), 0) AS tav, ISNULL(SUM(CASE WHEN (tipostatusage_id = 11) THEN 
								tStatus ELSE NULL END), 0) AS tprob, ISNULL(SUM(CASE WHEN (tipostatusage_id = 1) THEN tStatus ELSE NULL END), 0) AS tunknown, ISNULL(SUM(CASE WHEN (tipostatusage_id = 7
								) THEN tStatus ELSE NULL END), 0) AS tother, COUNT(CASE WHEN (tipostatusage_id = 7) THEN 1 ELSE NULL END) AS nother
		FROM tmpccLogAgentesDia
		GROUP BY convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121), userId
		)
	INSERT INTO #agents (timegroup, [user_id], tlog, tnot_av, tav, tprob, tunknown, tother, nother, nMoh, nWHag, nWHcl)
	SELECT A.fechaInicio AS timegroup, A.user_id, A.tlog, isnull(B.tnot_av, 0) AS tnot_av, isnull(B.tav, 0) AS tav, isnull(B.tprob, 0) AS tprob, isnull(B.tunknown, 0) AS tunknown, isnull(B.tother, 0) AS tother, isnull(B.nother
			, 0) AS nother, isnull(ci.nMoh, 0) AS nMoh, isnull(ci.nWHag, 0) AS nWHag, isnull(ci.nWHcl, 0) AS nWHcl
	FROM [#ccGenSession] A
	LEFT JOIN timeAgent B
		ON A.user_id = B.userId
			AND A.fechaInicio = B.timegroup
	LEFT JOIN #ccGenInCall ci
		ON A.user_id = ci.user_id
			AND A.fechaInicio = ci.timegroup

	INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
	SELECT timegroup, ccInboundAgentes.inbound_id, 
	COUNT(DISTINCT #agents.[user_id]) AS pos_max, 
	SUM(tlog - (tnot_av + tprob + tother)) AS pos_time, 
	COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	FROM #agents
	INNER JOIN ccInboundAgentes
		ON (#agents.[user_id] = ccInboundAgentes.[user_id])
	WHERE timegroup >= @from
		AND timegroup < @to
		AND INBOUND_ID > 0
	GROUP BY timegroup, ccInboundAgentes.inbound_id		
		;

	WITH callInAbnd
	AS (
		SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + ''00:00'', 121) AS timegroup, inbound_id, tque + txfer + tring AS tAbnd, nabnd, CASE WHEN statuscall_id IN (5, 6)
					AND nabnd > 0 THEN 1 ELSE 0 END nabnd2
		FROM tmpTimesInboundData
		WHERE statuscall_id IN (5, 6)
		)
	INSERT INTO #ccGenInAbnd
	SELECT timegroup, inbound_id, sum(nabnd2) amount, max(tAbnd) time_max, sum(tAbnd) AS time_tot, COUNT(CASE WHEN tAbnd < 10 THEN 1 ELSE NULL END) AS [<10], COUNT(CASE WHEN tAbnd BETWEEN 10
						AND 19 THEN 1 ELSE NULL END) AS [<20], COUNT(CASE WHEN tAbnd BETWEEN 20
						AND 29 THEN 1 ELSE NULL END) AS [<30], COUNT(CASE WHEN tAbnd BETWEEN 30
						AND 39 THEN 1 ELSE NULL END) AS [<40], COUNT(CASE WHEN tAbnd BETWEEN 40
						AND 49 THEN 1 ELSE NULL END) AS [<50], COUNT(CASE WHEN tAbnd BETWEEN 50
						AND 59 THEN 1 ELSE NULL END) AS [<60], COUNT(CASE WHEN tAbnd BETWEEN 60
						AND 119 THEN 1 ELSE NULL END) AS [<120], COUNT(CASE WHEN tAbnd BETWEEN 120
						AND 179 THEN 1 ELSE NULL END) AS [<180], COUNT(CASE WHEN tAbnd BETWEEN 180
						AND 239 THEN 1 ELSE NULL END) AS [<240], COUNT(CASE WHEN tAbnd BETWEEN 240
						AND 299 THEN 1 ELSE NULL END) AS [<300], COUNT(CASE WHEN tAbnd >= 300 THEN 1 ELSE NULL END) AS [+300]
	FROM callInAbnd
	GROUP BY timegroup, inbound_id

	--Borrar lo que esta para no repetir  
	DELETE	FROM RepInEffectiveness 	WHERE DATE >= @from		AND DATE < @to
	
	;with xDetCall as(
	SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, ISNULL(sum(tque) / NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) AS tQue_tot, sum(nQue) 
		AS nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp
	FROM #ccGenInCall
	WHERE timegroup >= @from
		AND timegroup < @to
	GROUP BY timegroup, inbound_id
	),xDetSpec as(
	SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect
			FROM #ccGenInSpec
			WHERE timegroup >= @from
				AND timegroup < @to
			GROUP BY timegroup, inbound_id
	),xDetAbnd as (
	SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot
			FROM #ccGenInAbnd
			WHERE timegroup >= @from
				AND timegroup < @to
			GROUP BY timegroup, inbound_id
	),xDetail as(
	SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) 
			ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) 
			tabnd_tot, ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot
		FROM  xDetCall
		LEFT JOIN xDetSpec
			ON 
					xDetCall.timegroup = xDetSpec.timegroup
					AND xDetCall.inbound_id = xDetSpec.inbound_id
					
		LEFT JOIN  xDetAbnd
			ON 
					xDetCall.timegroup = xDetAbnd.timegroup
					AND xDetCall.inbound_id = xDetAbnd.inbound_id
	)
	----------
	INSERT INTO RepInEffectiveness
	SELECT timegroup AS DATE, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion, ntotal, nanswer, nabnd, 
	isnull(tatention / nullif(nanswer, 0), 0) as tatencion, tque_avg AS tqueavg, tQue_tot AS tQuetot
		, nQue_tot AS nQuetot, isnull(tabnd_tot / NULLIF(nabnd, 0), 0) AS avgAbandonTime, SL_P_1 AS SLP1, SL_P_2 AS SLP2, tresp,
		isnull(c.NumberAgents,0) AS NumberAgents, ISNULL(SL_P_1 * 100 / NULLIF(SL_P_2, 0), 0) AS Porcentaje
		, datepart(yyyy, timegroup) AS [year]
		, datepart(mm, timegroup) AS [month]
		, datepart(dd, timegroup) AS [day]
		, datepart(hh, timegroup) AS [hour]
		, 0 AS [minutes]
		, convert(DECIMAL(10, 2), (nabnd / nullif(convert(DECIMAL(10, 2), ntotal), 0)) * 100) AS [avgAbandon]
		, tabnd_tot AS tabndtot
	FROM xDetail
	LEFT JOIN ccInbound ON xDetail.inbound_id = ccInbound.inbound_id
	left join #AgentsperInbound C on xDetail.inbound_id=C.Inbound_id and xDetail.timegroup=C.fechaInicio
	ORDER BY DATE

	
	DROP TABLE #ccGenInCall

	DROP TABLE #ccGenInSpec

	DROP TABLE #ccGenSession

	DROP TABLE #agents

	DROP TABLE #ccGenInAbnd

	DROP TABLE #AgentsperInbound
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepMKTIntervalos'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
	
set nocount on
set ansi_nulls off
set ANSI_WARNINGS off


if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin
	
	IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[timegroup] [datetime]  NOT NULL, [tlog] [INT] NULL, [inb_id] [int] NOT NULL)	
	
	;with relationWg as(
		select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
		where wg.Tipo = 0
	)

	INSERT INTO #sessionTimeGroup
	select st.[user_id],timegroup,tlog, wgu.IdCampEsp 
	from TmpSessionTimeGroup st
	Inner Join relationWg wgu ON st.User_id = wgu.User_id


	delete from [RepMKTIntervalos] 	where date >= @from AND date <= @to
		
	
	
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
	), mktInterval as(

	select 
	i.timegroup
	,i.inbound_Id as inboundId	
	,i.User_id as userId
	,sum(tresp) as tresp
	,sum(case when statusCall_id =13 and ntotal>0 then 1 else 0 end) as nacd
	,sum(case when statuscall_id <> 13 then tque+txfer+tring else 0 end) AS tAbnd
	,sum(case when statusCall_id <>13 and ntotal>0 then 1 else 0 end) as nabnd	
	,sum(case when statusCall_id=13 then tdialog else 0 end) as tacd
	,sum(tnotes) as tacw
	,sum(case when statusCall_id=13 and ntotal>0 and tnotes>0 then 1 else 0 end) as nacw 
	,sum(case when statuscall_id = 13 then tque + txfer + tring else 0 end) as maxdem
	,sum(case when statuscall_id in (7,8) AND nque > 0 AND txfer=0 then 1 else 0 end) as ncalque
	,sum(case when statusCall_id in (7,8) AND nque > 0 AND txfer=0 then tque else 0 end) as tcalque
	,isnull(sum(t.fent),0) as fent
	,isnull(sum(t.fsal),0) as fsal
	,isnull(sum(t.SalExt),0) as SalExt
	,isnull(sum(t.tprosalext),0) as tprosalext	
	,isnull(sum(ntotal),0) as ntotal
	,1 as countUserDistinct
	,count(distinct case when statusCall_id =13 and ntotal>0 then  userId end ) countUserDistinctNacd
	from tmpTimesInboundData i
	left join transferDataGroup t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId and i.User_id=t.userId	
	group by i.timegroup,i.inbound_Id,i.User_id 
	)

	INSERT INTO [RepMKTIntervalos]
	select 
	isnull(A.timegroup,g.timegroup) as [date]
	,isnull(A.inboundId,g.[inb_id]) as inboundId
	,inb.descripcion as Acds
	,case when A.nacd>0 then A.tresp/isnull(nullif(A.nacd,0), 1) else 0 end as [avrAnswer]
	,case when A.nabnd>0 then A.tabnd/A.nabnd else 0 end as [AvgAbandonTime]
	,isnull(A.nacd,0) [acdCalls]
	,case when A.nacd>0 then A.tacd/A.nacd else 0 end as [tPromACD]
	,case when A.nacw>0 then A.tacw/A.nacw else 0 end as [tPromACW]
	,isnull(A.nabnd,0) as [abondeonedCalls]
	,isnull(A.maxdem,0) as [maxDelay]
	,isnull(A.fent,0) as  [entryFlow]	
	,isnull(A.fsal,0) as  [outFLow]
	,isnull(A.SalExt,0) as [calloutExt]	
	,isnull(case when A.SalExt>0 then A.tprosalext/A.SalExt else 0 end,0) as [TPromSalidaExt]
	,isnull(A.ncalque,0) as [callDeleteQue]	
	,case when A.ncalque>0 then A.tcalque/A.ncalque else 0 end as [TpromElimCola]		
	,case when round(case when countUserDistinct>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1)>0 
		then (case when convert(decimal(15,2),(((nacd) * case when (nacd)>0 then (tacd)/isnull(nullif((nacd),0), 1) else 0 end) / convert(float,((round(case when (countUserDistinct)>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1))*1800)))*100)>100 then 100 
			   else convert(decimal(15,2),(((nacd) * case when (nacd)>0 then (tacd)/isnull(nullif((nacd),0), 1) else 0 end) / convert(float,((round(case when countUserDistinct>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1))*1800)))*100) end)
		else 0 end avrTimeACD		
	,isnull(convert(decimal(10,2), case when nacd+nabnd>0 then convert(decimal(10,2), nacd*100.0/(nacd+nabnd)) else 0.00 end),0.00) avrCallsAnswer	
	,isnull(convert(decimal(10,2), round( case when countUserDistinct is not null then (tlog*100.0/1800)/100 else 0 end,1)),0.00) as PromPosicionPersonal	
	,case when (nacd) >0 then (case when (nacd)/isnull(nullif(countUserDistinctNacd,0), 1) >0 then convert(int, (nacd)/isnull(nullif(countUserDistinctNacd,0), 1)) else 1 end) else 0 end as [LlamadasporPosicion]
	,isnull(A.tresp,0) as tresp
	,isnull(A.tabnd,0) as tabnd
	,isnull(A.tacd,0) as tacd
	,isnull(A.tacw,0) as tacw
	,isnull(A.nacw,0) as nacw		
	,isnull(A.tcalque,0) as tcalque			
	,isnull(A.tprosalext,0) as tprosalext
	,isnull(g.tlog,0) as tlog
	,isnull(A.userId,g.user_id) accountUserId	
	,DATEPART(YYYY, isnull(A.timegroup,g.timegroup)) as [year] 
	,DATEPART(mm, isnull(A.timegroup,g.timegroup)) as [month]
	,DATEPART(dd, isnull(A.timegroup,g.timegroup)) as [day]
	,DATEPART(hh, isnull(A.timegroup,g.timegroup)) as [hour]
	,DATEPART(mi, isnull(A.timegroup,g.timegroup)) as [minutes]
	from mktInterval A
	full join #sessionTimeGroup g on A.timegroup=g.timegroup and A.inboundId=g.[inb_id] and A.userId=g.[user_id]
	Left join ccinbound inb ON inb.Inbound_id = A.inboundId or inb.Inbound_id=g.inb_id
	where ntotal>0
	order by [date],inboundId,A.userId

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup	
	
end
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepMKTIntervalosSalidas'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosSalidas] 
@action as tinyint, @from as datetime = null, @to as datetime = null	
AS
SET NOCOUNT ON
if @from is null
	select @from = convert(datetime, convert(varchar(11), getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
	
	DECLARE @tresRing AS SMALLINT
	EXEC @tresRing = ccspConfigTresRing;						
			
delete RepMKTIntervalosSalida with(rowlock) where date between @from and @to;

WITH tPersonal  as(

select count(distinct user_id) as uid
	,sum(tlog) tlog
,DATEADD(mi, CASE WHEN DATEPART(mi, timegroup_next) in (15,45) THEN - 15 ELSE 0 END, timegroup_next) timegroup_next
from TmpSessionTimeGroup 
group by DATEADD(mi, CASE WHEN DATEPART(mi, timegroup_next) in (15,45) THEN - 15 ELSE 0 END, timegroup_next)
	
),tDisp as (
select 
DATEADD(mi, 
case when DATEPART(mi,timeGroupNext)= 15 then -15 
	else 0 end
, timeGroupNext) as timeGroupNext
,sum(case when TipoStatusAge_id=2 then tStatus else 0 end) tnodispo
,sum(case when TipoStatusAge_id=2 then tStatus else 0 end) tdispo
from tmpccLogAgentesDia
where TipoStatusAge_id in (2,3)
group by DATEADD(mi, 
case when DATEPART(mi,timeGroupNext)= 15 then -15 
	else 0 end
, timeGroupNext) 
),
callOut
AS (
	SELECT cal_id,dateStartDetail, dateEndDetail,timegroup_next
		, user_id, ntotal AS Recibidas, nanswer AS [Contestadas], nabnd_dialog AS [Abandonadas], nhangup AS SinAgentes, statusCall_id, tque, 
		txfer, tring, tdialog, tnotes, cal_tMoh
	FROM tmpTimesOutboundData
	), OutboundCalls
AS (
	SELECT lo.cal_id
	,co.cal_id AS callId
	,co.dateStartDetail
	,co.dateEndDetail	
	,CASE WHEN co.statusCall_id = 13 THEN co.timegroup_next ELSE dbo.getTimegroup(DATEADD(ss, tDialing, fecha),1) END AS timegroup_next	
	,Recibidas
	,co.user_id AS userId
	,cam_id AS cam_id
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 2 THEN 1 ELSE 0 END Ocupado
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 3 THEN 1 ELSE 0 END NoContestan
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 4 THEN 1 ELSE 0 END Fax
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 11 THEN 1 ELSE 0 END Buzon
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 5 THEN 1 ELSE 0 END SinTono
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 10 THEN 1 ELSE 0 END NoService
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 8 THEN 1 ELSE 0 END Otro
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 12 THEN 1 ELSE 0 END Congestion
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 13 THEN 1 ELSE 0 END Cancelado
	,CASE WHEN Recibidas > 0 AND tipoResDial_id = 1 THEN 1 ELSE 0 END [Contactos] --contactos sistema
	,[Contestadas]
	,CASE WHEN statusCall_id IN (6, 10, 11, 12, 14, 15, 16)
			OR (
				canceledNoAgents <> 0 AND answerbit = 1
				)
			OR ([Abandonadas] > 0) THEN 1 ELSE 0 END AS [Abandonadas]
	,SinAgentes
	,CASE WHEN statuscall_id IN (15, 16) THEN 1 ELSE 0 END AS NoContestadas
	,CASE WHEN statuscall_id IN (11, 10, 12, 14) AND tring <= @tresRing THEN 1 ELSE 0 END AS CortadasRing
	,CASE WHEN statuscall_id IN (11, 10, 12, 14) AND tring > @tresRing THEN 1 ELSE 0 END AS CortadasDespRing
	,[Abandonadas] AS CortadasDlg
	,CASE WHEN statuscall_id = 13 THEN co.txfer + co.tring + co.tdialog + co.tnotes + co.cal_tMoh ELSE 0 END TMO
	,CASE WHEN statuscall_id = 13 THEN 1 ELSE NULL END countStatus13
	,co.tdialog
	,co.cal_tMoh AS TiempoTotalHold
	,co.tnotes
	,co.txfer + co.tring AS TiempoTotalRing
	,co.tque
	,co.txfer + co.tring + co.tdialog + co.tnotes  [Ocupacion]
	,co.statuscall_id
	,co.tring
	,tipoResDial_id
FROM ccologdials(NOLOCK) lo
LEFT JOIN callOut co
	ON co.cal_id = lo.cal_id
WHERE fecha BETWEEN @from
		AND @to
), OutboundCallGroup as (

SELECT 
dateadd(mi, case when datepart(mi,timegroup_next) in (15,45) then -15 else 0 end,timegroup_next) as timegroup_next
,count(distinct userId )as Staff
,sum(Recibidas) as Recibidas
,sum(Ocupado) as Ocupado
,sum(NoContestan) as NoContestan	
,sum(Fax) as Fax
,sum(Buzon) as Buzon
,sum(SinTono) as SinTono
,sum(NoService) as nout_service	
,sum(Otro) as Other	
,sum(Congestion) as Congestion
,sum(Cancelado) as Cancelado
,sum(Contactos) as contacted
,sum(Contestadas) as Answered
,sum(Abandonadas) as abandonedCalls
,sum(SinAgentes) as SinAgentes
,sum(NoContestadas) as NoContestadas
,sum(CortadasRing) as nabndxferout
,sum(CortadasDespRing) as nabndringout
,sum(CortadasDlg) nabnddlgout
,isnull(SUM([Ocupacion])/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0)  as TMO
,isnull(SUM(tdialog)/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0) as promDialogo
,sum(TiempoTotalHold) as holdTime
,sum(tnotes) as tnotesout
,sum(TiempoTotalRing) as tringout
,isnull(sum(tque)*1.0/nullif(COUNT(case when statuscall_id=13 then 1 end),0),0)  as avrAnswer
, case when count(case when statusCall_id=13 then 1 end ) = 0 or count(case when tipoResDial_id=1 then 1 end) = 0 then 0.00
else convert(decimal(10,2),sum(Abandonadas)*100.0/count(case when tipoResDial_id=1 then 1 end) ) end as AvgAbandon
,Cam_id
,sum([Ocupacion]) as sumTime
FROM OutboundCalls co
group by dateadd(mi, case when datepart(mi,timegroup_next) in (15,45) then -15 else 0 end,timegroup_next),cam_id
)


insert into RepMKTIntervalosSalida
select convert(datetime, convert([date],oc.timegroup_next,121)) as [date]
,convert(varchar(5),oc.timegroup_next,108) rango1
,convert(varchar(5),dateadd(mi,30,oc.timegroup_next),108) rango2
,oc.Staff
,oc.Recibidas
,oc.Ocupado
,oc.NoContestan
,oc.Fax
,oc.Buzon
,oc.SinTono
,oc.nout_service
,oc.Other
,oc.Congestion
,oc.Cancelado
,oc.contacted
,oc.Answered
,oc.abandonedCalls
,oc.SinAgentes
,oc.NoContestadas
,oc.nabndxferout
,oc.nabndringout
,oc.nabnddlgout
,oc.TMO
,oc.promDialogo
,oc.holdTime
,oc.tnotesout
,oc.tringout
,isnull(d.tdispo,0) as readyTime
,isnull(d.tnodispo,0) as notReadyTime
,isnull(l.tlog,0) as Personal
,oc.avrAnswer
,isnull(case when l.tlog=0 then 0.00 else convert(decimal(10,2), (oc.tnotesout+d.tnodispo)*100.0/L.tlog) end,0.00) as Reductor
,oc.AvgAbandon
,case when l.tlog is null or l.tlog =0  then 0.00 else convert(decimal(10,2), oc.sumTime*100.0/L.tlog,0) end as OcupacionCOPC
,oc.Cam_id

from OutboundCallGroup oc
left join tPersonal L on oc.timegroup_next=L.timegroup_next
left join tDisp d on oc.timegroup_next=d.timeGroupNext
END

'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepMKTIntervalosTiemposAcuTotales '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales] @action AS TINYINT
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
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepMKTTiemposTotales'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
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
	where TipoStatusAge_id=3 
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
		from #HoldDisp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		order by date		

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;					
	IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
	
	IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog	

	IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData		

END
	'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepOutAnswAndXferCalls'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
	SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT
SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO

declare @descriptionXfer varchar(100)

SELECT @descriptionXfer=[description] FROM dialType WHERE dialId = 3

;with ccld as(
	SELECT *, [dbo].[GetProveedor](Telefono, Puerto,tipoLlamada_id) AS proBIDs,tipoLlamada_id as CallType  FROM ccologdials
	WHERE fecha between @from and @to and answerbit = 1
)

INSERT INTO RepOutAnswAndXferCalls
SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
	ISNULL(ccld.cal_id,0) AS [callid],
	ISNULL(ccld.cam_id,0) AS [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
	ISNULL([Call].user_id,0) AS [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
	dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
	ccld.telefono AS [telephone],
	ISNULL(Call.cal_manual,0) AS [dialId],
	ISNULL(dialType.[description],''systemTranslated_Auto'') AS [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
	CASE 
		WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
			dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country)
		ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)))
	END AS [ncost],
	@IVA AS iva,
	CASE
		WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),
				COALESCE(Call.provedor_id,ccld.proBIDs), dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country),0.00) * (1 + (@IVA / 100.00)))
		ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
	END	AS total,
	COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
	case when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
	COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) as dialTimeSec
FROM ccld
	LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
			AND ccld.answerbit = 1
	LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
	LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id		AND ccost.country_id = tl.country_id
	left join dialType on dialType.dialId = Call.cal_manual


;with clt as (

SELECT *
, DATEADD(ss,-(tAntesXfer + tDespuesXfer),fechaFin) AS [date]
, tipoLlamada_id AS  CallType 
,case WHEN modo in(5,6) then abs(destino) else null end posicion
	FROM cclogtransfers WITH(NOLOCK) 
	WHERE modo not in (1,2) 
		AND (tAntesXfer > 0 or tDespuesXfer > 0) 
		AND fechaFin between @from and @to
)


INSERT INTO RepOutAnswAndXferCalls	
SELECT clt.[date],
	clt.cal_id AS [callid],
	COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
	COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
	ISNULL((CASE tipo 
				WHEN 1 THEN ci.User_id 
				ELSE co.User_id 
			END),0) AS [userId],
	ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
				(CASE tipo 
					WHEN 1 THEN ci.User_id 
					ELSE co.User_id 
				END)),''systemTranslated_NoName'') as [Agent],
	dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
	CASE 
		WHEN modo = 0 THEN clt.destino
		WHEN modo = 3 THEN clt.destino 
		WHEN modo = 4 THEN clt.destino 
		WHEN modo in(5,6) THEN isnull((SELECT top 1 Computer FROM ccposicion WHERE pos_id = posicion),clt.destino) 
	END AS [telephone],
	3 AS [dialId],
	@descriptionXfer AS [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
		ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
	END AS [ncost],
	@IVA AS iva,
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
			,@country),0.00) * (1 + (@IVA / 100.00))) 
		ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
	END AS [total],
	IsNull(clt.channel, 0) as [trunk],
	case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,camps.id_anilist) else camps.ani end else '''' end [ANI],
	ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM clt
	LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
	LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
	LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
	LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
	LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
	LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id

end'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepOutCalls'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to  is null
	select @to = getdate()

	IF OBJECT_ID(N''tempdb..#tempTime'', N''U'') IS NOT NULL  drop table #tempTime
	IF OBJECT_ID(N''tempdb..#tempRepOutCalls'', N''U'') IS NOT NULL  drop table #tempRepOutCalls


if @action = 1
begin

	
	 select ROW_NUMBER() OVER(Order by row) as id,
		  A.row, A.timegroup as [date],isnull(B.IDArea,0) as areaId,isnull(C.AreaName, '''') as area
		 ,A.idwg as workgroupid,isnull(WG.WGName, '''') as workgroup
		 ,A.cam_id as campaignid,isnull(B.cam_descripcion,'''') as campaign
		 ,A.[User_id] as userId,isnull(userView.[Login],'''') as [user]
		 ,ntotal, nxfer, nno_agent, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog
		 ,1 as pos_tot,
		 tmp.tlog as  pos_time,  ---falta restar tnot_av + tprob + tother
		 
		 nhangup, (tdialog + tnotes) as  tatencion
		 ,datepart(yy,convert(datetime,A.timegroup)) as [year]
		 ,datepart(mm,convert(datetime,A.timegroup)) as [mounth]
		 ,datepart(dd,convert(datetime,A.timegroup)) as [day]
		 ,datepart(hh,convert(datetime,A.timegroup)) as [hour]
		 ,datepart(mi,convert(datetime,A.timegroup)) as [minutes]
		 ,cal_id,phone_out,dateStartDetail
		 into #tempRepOutCalls
		 from tmpTimesOutboundData A
		 left join ccUserView userView on A.User_id=userView.User_id
		 left join cccamps B on A.cam_id=B.cam_id
		 left join ccriacat_areas C on B.IDArea=C.IDArea
		 left join ccriacat_workgroup WG on Wg.IDWG=A.idwg
		 left join TmpSessionTimeGroup  tmp ON tmp.timegroup=A.timegroup and tmp.user_id=A.User_id
		 where A.User_id>0 AND B.IDArea IS NOT NULL AND B.IDArea>0
		 and cal_manual in (0,2,3)
		 

	 SELECT
      RANK() OVER(PARTITION BY row ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepOutCalls
      where row in
            (select row from #tempRepOutCalls temp GROUP BY temp.row HAVING Count(*) > 1 )

       update t
            set ntotal=0,nxfer=0,nno_agent=0,nanswer=0,nno_answer=0,nlost=0,nabnd_xfer=0,nabnd_ring=0,nabnd_dialog=0,tatencion=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    	
	delete #tempTime

    insert into #tempTime([rank],rowNumber,id)
    SELECT
      RANK() OVER(PARTITION BY cal_id ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepOutCalls
      where cal_id in
            (select cal_id from #tempRepOutCalls temp GROUP BY temp.cal_id HAVING Count(*) > 1 )

       update t
            set pos_tot=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    --Borrar lo que esta para no repetir
	delete from RepOutCalls with(rowlock)
	where date >= @from AND date < @to

     insert into RepOutCalls
		select date,areaId,area,workgroupid,workgroup,campaignid,campaign,userId,[user],ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0),isnull(pos_time,0),nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls order by cal_id	


	IF OBJECT_ID(N''tempdb..#tempTime'', N''U'') IS NOT NULL  drop table #tempTime
	IF OBJECT_ID(N''tempdb..#tempRepOutCalls'', N''U'') IS NOT NULL  drop table #tempRepOutCalls	

end'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepOutDialDetail '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
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
		        

;WITH dials
AS (
	SELECT dial.logDial_id
		,dial.callout_id
		,dial.cam_id
		,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
		,dial.Telefono
		,dial.Puerto
		,dial.fecha
		,dial.tDialing
		,CASE WHEN LEFT(dial.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType
		,dial.tBusy
		,dial.answerbit
		,dial.canceledNoAgents
		,dial.cal_id
		,dial.disconnectCause
		,co.cal_key
		,co.file_moved
		,dial.tipoLlamada_id
		,tco.[Description] AS CallDisposition
		,tsco.califSubDesc
		,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
		,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
			WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel		
	FROM ccoLogDials dial(NOLOCK)
	LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
	LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
	LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
	WHERE fecha >= @from AND fecha < @to
	), codeSip as(
		select distinct cast(codeSip as int) as codeSip,disconnectCause from dials where codeSip<>'''' and IsNumeric(codeSip)=1
	)
	, relationCodeSip as(
		select A.codeSip,A.disconnectCause,B.description from codeSip A
		inner join DC_Extra B on A.codeSip=B.id
	)


--Inserta informacon de reporte  
	INSERT INTO RepOutDialDetail
		SELECT fecha as [date]
		,case when dials.cal_key is null or  cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
		,telefono telephone
		,dials.tiporesdial_id as tiporesdialId
		,CASE WHEN dials.tipoResDial_id = 14 THEN ''systemTranslated_CancelledBySystem'' ELSE ISNULL(descripcion, '''') END AS dialResult
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
	FROM dials
	LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
	LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
	LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
	LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
	LEFT JOIN relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause

END'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepOutDispositions '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutDispositions] @action AS TINYINT
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
		SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121) AS DATE
			,a.cam_id
			,a.calif_id
			,count(calif_id) DispAmount
			,user_id
		FROM ccocallsout a
		WHERE cal_inicio >= @from
			AND cal_inicio < @to
			AND a.statuscall_id = 13
			AND cal_manual IN (0, 2)
		GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121)
			,a.cam_id
			,a.calif_id
			,user_id
		)

	insert into RepOutDispositions
	SELECT A.DATE
		,a.cam_id campaignId
		,ISNULL(b.cam_descripcion, '''') AS Campaign
		,a.calif_id dispositionId
		,isnull(c.Description, ''systemTranslated_Dispositionless'') AS disposition
		,isnull(c.Description, ''systemTranslated_Dispositionless'') + ''_Count'' AS disposition_count
		,a.DispAmount AS [count]
		,A.user_id userId
		,ISNULL(d.LOGIN, '''') [agentName]
		,isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS username
		,isnull(b.IDArea, 0) AS areaId
		,isnull(e.AreaName, '''') AS area
		,isnull(wg.IDWG, 0) AS workgroupId
		,isnull(wg.WGName, ''-'') AS wg
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
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepOutManagementBase '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutManagementBase] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE
	FROM RepOutManagementBase
	WHERE [date] >= @from
		AND [date] < @to

	INSERT INTO RepOutManagementBase (
		DATE
		,dialResultCode
		,dialResultId
		,dialResult
		,dispositionId
		,disposition
		,subDispositionId
		,subDisposition
		,total
		,Agent
		,Campaigns
		,year
		,month
		,day
		,hour
		,minutes
		,calKey
		,telephone
		)
	SELECT fecha AS [date]
		,logdial.callout_id AS dialResultCode
		,logdial.tipoResDial_id AS dialResultId
		,ISNULL(resdial.descripcion, '''') AS dialResult
		,ISNULL(tipocal.calif_id, 0) AS dispositionId
		,ISNULL(tipocal.Description, '''') AS disposition
		,ISNULL(tiposubcal.califSub_id, 0) AS subDispositionId
		,ISNULL(tiposubcal.califSubDesc, '''') AS subDisposition
		,1 AS Total
		,ISNULL(cUser.LOGIN, '''') AS Agent
		,ISNULL(ccCamps.cam_descripcion, '''') AS Campaigns
		,DATEPART(yyyy, fecha) AS [year]
		,DATEPART(mm, fecha) AS [month]
		,DATEPART(dd, fecha) AS [day]
		,DATEPART(hh, fecha) AS [hour]
		,DATEPART(mi, fecha) AS [minutes]
		,ISNULL(logdial.cal_Key, '''') AS cal_key
		,ISNULL(logdial.Telefono, '''') AS cal_telefono
	FROM ccoLogDials logdial WITH (NOLOCK)
	LEFT JOIN cctipoResultadodial resdial ON logdial.tipoResDial_id = resdial.tipoResDial_id
	LEFT JOIN ccoCallsOut cout ON cout.cal_id = logdial.cal_id
	LEFT JOIN cctipocalifout tipocal ON cout.calif_id = tipocal.calif_id
	LEFT JOIN cctipocalifsubout tiposubcal ON cout.califSub_id = tiposubcal.califSub_id
	LEFT JOIN ccUserView cUser ON cUser.User_id = cout.User_id
	LEFT JOIN ccCamps ON ccCamps.cam_id = logdial.cam_id
	WHERE fecha BETWEEN @from
			AND @to
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepSpececialAgent'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepSpececialAgent] @action AS TINYINT
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
	FROM AgentGI A
	INNER JOIN ses ON ses.[date] = A.[date]
		AND ses.userId = A.userId
	LEFT JOIN outCall cout ON cout.[date] = A.[date]
		AND cout.userId = A.userId
	LEFT JOIN inCall cin ON cin.[date] = A.[date]
		AND cin.userId = A.userId
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepSpecialCallKeyHistory'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepSpecialCallKeyHistory] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	DELETE RepSpecialCallKeyHistory
	WHERE [date] BETWEEN @from
			AND @to

	INSERT RepSpecialCallKeyHistory
	SELECT CONVERT(VARCHAR(16), fecha, 121) [date]
		,ISNULL(ld.cam_id, 0) campaignId
		,ISNULL(cam_descripcion, ''systemTranslated_NoCampaign'') campaign
		,ld.cal_Key callKey
		,ld.Telefono telephone
		,ISNULL(rd.descripcion, ''systemTranslated_NoStatus'') dialResult
		,ISNULL(cal.Description, ''systemTranslated_Dispositionless'') disposition
		,ISNULL(cal_tdialog, 0) dialogTime
		,ISNULL(convert(VARCHAR(30), cal_fcallback, 121), ''systemTranslated_NoCallback'') CallBacks
		,isNull(us.LOGIN, ''systemTranslated_NoUserName'') [login]
		,isNull(us.ApellidoPaterno + '' '' + us.ApellidoMaterno + '' '' + us.Nombres, ''systemTranslated_NoName'') AS [user]
	FROM ccoLogDials ld WITH (NOLOCK)
	LEFT JOIN ccoCallsOut co(NOLOCK) ON co.cal_id = ld.cal_id
	LEFT JOIN ccTipoResultadoDial rd ON rd.tipoResDial_id = ld.tipoResDial_id
	LEFT JOIN ccCamps ca ON ca.cam_id = ld.cam_id
	LEFT JOIN ccTipoCalifOUT cal ON cal.calif_id = co.calif_id
	LEFT JOIN ccUserView us ON us.User_id = co.User_id
	WHERE ld.fecha BETWEEN @from
			AND @to
		AND len(ld.cal_key) > 0
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ccspRepSpecialTimes '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepSpecialTimes] @action AS TINYINT
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
			,CASE WHEN tipostatusage_id = 3 THEN ''Tiempo Disponible'' WHEN tipostatusage_id = 4 THEN ''Tiempo Dialogo'' WHEN tipostatusage_id = 2 THEN ''Tiempo No Disponible'' ELSE ''Otro'' END AS tDescripcion
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
			,isnull([Tiempo Disponible], 0) + isnull([Tiempo Dialogo], 0) + isnull([Tiempo No Disponible], 0) + isnull([Otro], 0) AS [Tiempo Sesion]
			,isnull([Tiempo Disponible], 0) AS [Tiempo Disponible]
			,isnull([Tiempo Dialogo], 0) AS [Tiempo Dialogo]
			,isnull([Tiempo No Disponible], 0) AS [Tiempo No Disponible]
			,isnull([Otro], 0) AS [Otro]
		FROM times
		pivot(max(tstatus) FOR [tdescripcion] IN ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) AS pvtTimes
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
	FROM Report1 a
	LEFT JOIN notready b ON (
			a.[Espec/Camp] = b.[Espec/Camp]
			AND a.timeGroup = b.timeGroup
			)
	WHERE b.timeGroup IS NULL
	ORDER BY a.[Espec/Camp]
		,a.timeGroup
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP  ccspRepTrunkBusy'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
	CREATE TABLE #RtnValue (
		fecha DATETIME
		,puerto INT
		,cam_id INT
		,tbusy INT
		,contador INT
		,fechafin DATETIME
		,timegroup DATETIME
		,timegroupNext DATETIME
		)

	CREATE TABLE #RtnValue2 (
		fecha DATETIME
		,puerto INT
		,cam_id INT
		,tbusy INT
		,contador INT
		,fechafin DATETIME
		,timegroup DATETIME
		,timegroupNext DATETIME
		);

	WITH trunkOut
	AS (
		SELECT dials.fecha
			,dials.Puerto
			,dials.cam_id
			,dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0) AS tBusy
			,1 AS contador
			,dateadd(ss, dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0), dials.fecha) AS fechafin
		FROM ccologdials AS dials
		LEFT JOIN ccocallsout AS calls ON (
				dials.Puerto = calls.cal_puerto
				AND dials.cal_id = calls.cal_id
				)
		WHERE dials.fecha BETWEEN @from
				AND @to
		)
	INSERT INTO #RtnValue
	SELECT fecha
		,puerto
		,cam_id
		,tBusy
		,contador
		,fechafin
		,dbo.GetTimeGroup(fecha, 0) AS timegroup
		,dbo.GetTimeGroup(fechafin, 0) AS timegroupNext
	FROM trunkOut
	WHERE tBusy > 0

	INSERT INTO #RtnValue2
	SELECT *
	FROM #RtnValue
	WHERE datediff(mi, fecha, fechafin) > 15

	DELETE #RtnValue
	WHERE datediff(mi, fecha, fechafin) > 15

	INSERT INTO #RtnValue
	SELECT t.fecha
		,t.Puerto
		,t.cam_id
		,dbo.TimeInterval(th.start, th.stop, t.fecha, fechafin) AS tBusy
		,t.contador AS llamadas
		,fechafin
		,th.start
		,th.stop
	FROM #RtnValue2 t
	INNER JOIN TmpTimesInterval th ON (
			t.fecha > th.Start
			AND t.fecha < th.stop
			)
		OR th.Start BETWEEN t.fecha
			AND t.fechafin

	SELECT timegroup
		,puerto AS [port]
		,cam_id
		,SUM(tBusy) tBusy
		,sum(contador) AS llamadas
		,1 AS tipo
	INTO #ccGenOutPortStats
	FROM #RtnValue
	GROUP BY timegroup
		,puerto
		,cam_id

	INSERT INTO #ccGenOutPortStats
	SELECT timegroup
		,cal_puerto AS [port]
		,Inbound_id AS cam_id
		,sum(txfer + tRing + tDialog) AS tBusy
		,count(*) llamadas
		,0 AS tipo
	FROM tmpTimesInboundData
	GROUP BY timegroup
		,cal_puerto
		,Inbound_id
	HAVING sum(txfer + tRing + tDialog) > 0

	DELETE
	FROM RepInTrunkBusy
	WHERE DATE >= @from
		AND DATE < @to

	INSERT INTO RepInTrunkBusy
	SELECT timegroup
		,A.cam_id
		,[in].descripcion
		,[port]
		,tbusy
		,llamadas
		,datepart(yyyy, timegroup) AS [year]
		,datepart(mm, timegroup) AS [month]
		,datepart(dd, timegroup) AS [day]
		,datepart(hh, timegroup) AS [hour]
		,datepart(mi, timegroup) AS [minutes]
	FROM #ccGenOutPortStats A
	INNER JOIN ccInbound [in] ON [in].inbound_id = A.cam_id
		AND A.tipo = 0

	DELETE
	FROM RepOutTrunkBusy
	WHERE DATE >= @from
		AND DATE < @to

	INSERT INTO RepOutTrunkBusy
	SELECT timegroup
		,A.cam_id
		,[out].descripcion
		,[port]
		,tbusy
		,llamadas
		,datepart(yyyy, timegroup) AS [year]
		,datepart(mm, timegroup) AS [month]
		,datepart(dd, timegroup) AS [day]
		,datepart(hh, timegroup) AS [hour]
		,datepart(mi, timegroup) AS [minutes]
	FROM #ccGenOutPortStats A
	INNER JOIN cccamps [out] ON (
			[out].cam_id = A.cam_id
			AND A.tipo = 1
			)

	DELETE
	FROM RepTrunkBusy
	WHERE DATE >= @from
		AND DATE < @to

	INSERT INTO RepTrunkBusy
	SELECT timegroup
		,port
		,tbusy
		,llamadas
		,datepart(yyyy, timegroup) AS [year]
		,datepart(mm, timegroup) AS [month]
		,datepart(dd, timegroup) AS [day]
		,datepart(hh, timegroup) AS [hour]
		,datepart(mi, timegroup) AS [minutes]
	FROM #ccGenOutPortStats A

	DROP TABLE #RtnValue

	DROP TABLE #RtnValue2

	DROP TABLE #ccGenOutPortStats
END
'
		EXEC(@Sql)

		set @process = 'CW-6501 Alter SP ReportsMasterProcessWIthOnlyGenerate '
		set @Sql= 'ALTER PROCEDURE [dbo].[ReportsMasterProcessWIthOnlyGenerate] @from AS DATETIME = NULL
	,@to AS DATETIME = NULL
	,@scheduleTime INT = 10
	,@dateStart DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE @i INT
	,@count INT
DECLARE @SQL VARCHAR(max)
DECLARE @name SYSNAME
DECLARE @descError NVARCHAR(max)
DECLARE @dateSP DATETIME

IF @from IS NULL
BEGIN
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
END

IF @to IS NULL
BEGIN
	SET @to = getdate()
END

IF @dateStart IS NULL
BEGIN
	SET @dateStart = getdate()
END

EXEC ccspTmpTimesInterval @from = @from	,@to = @to	,@interval = 15
EXEC ccspTmpSessionGeneral @from = @from	,@to = @to
EXEC ccspTmpSessionTimeGroup @from = @from	,@to = @to

EXEC ccspTimesccLogAgentesDia @from = @from	,@to = @to

EXEC ccspTimesOutboundData @from = @from	,@to = @to

EXEC ccspTimesInboundData @from = @from	,@to = @to

exec ccspTmpTimesccLogtransfers @from = @from, @to = @to

exec ccsptmpTimesHoldIn @from = @from, @to = @to

CREATE TABLE #tmpProcedureReports (
	id INT
	,name SYSNAME
	)

INSERT INTO #tmpProcedureReports
SELECT ROW_NUMBER() OVER (
		ORDER BY [name]
		) AS id
	,[name]
FROM sys.procedures
WHERE [name] LIKE ''ccspRep%''
	AND [name] NOT IN (''ccspRepCatalogos'', ''ccsprepLogAgentriaseparate'')
	AND name NOT IN (
		SELECT name
		FROM logsReportsMaster
		WHERE STATUS = 0
			AND dateStart >= @dateStart
		)

INSERT INTO [logsReportsMaster] (
	name
	,STATUS
	,dateStart
	,dateEnd
	,error
	,maxTime
	)
SELECT name
	,0
	,''19000101''
	,''19000101''
	,''''
	,@scheduleTime
FROM #tmpProcedureReports

SELECT @i = 1
	,@count = count(*)
FROM #tmpProcedureReports

WHILE @i <= @count
	AND datediff(mi, @dateStart, getdate()) < @scheduleTime
BEGIN
	SELECT @name = name
	FROM #tmpProcedureReports
	WHERE id = @i

	SET @sql = ''EXEC '' + @name + '' @action=1,@from='''''' + convert(VARCHAR(max), @from, 121) + '''''', @to='''''' + convert(VARCHAR(max), @to, 121) + ''''''''
	SET @dateSP = getdate()

	PRINT (@sql)

	BEGIN TRY
		EXEC (@sql)

		WAITFOR DELAY ''00:00:01''

		WHILE (
				SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
					AND a.session_id = @@SPID
					AND d.TEXT = @sql
				) > 0
		BEGIN
			WAITFOR DELAY ''00:00:01''
		END

		IF (datediff(ss, @dateStart, getdate()) > @scheduleTime * 60)
		BEGIN
			UPDATE [logsReportsMaster]
			SET STATUS = 2
				,dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime + 1
				,error = ''Increment time shuduler '' + convert(VARCHAR(max), @scheduleTime)
			WHERE name = @name
				AND STATUS = 0
				AND dateStart = ''19000101''
				AND dateEnd = ''19000101''

			UPDATE [logsReportsMaster]
			SET dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime
			WHERE STATUS = 0
				AND dateStart = ''19000101''
				AND dateEnd = ''19000101''

			BREAK
		END

		UPDATE [logsReportsMaster]
		SET STATUS = 1
			,dateStart = @dateSP
			,dateEnd = getdate()
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = ''19000101''
			AND dateEnd = ''19000101''
	END TRY

	BEGIN CATCH
		SELECT @descError = ''Line: '' + cast(error_line() AS NVARCHAR) + '' Number: '' + cast(@@error AS NVARCHAR) + '' Message: '' + error_message()

		SELECT @descError
			,@name

		UPDATE [logsReportsMaster]
		SET STATUS = 3
			,dateStart = @dateSP
			,dateEnd = getdate()
			,error = @descError
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = ''19000101''
			AND dateEnd = ''19000101''
	END CATCH

	SET @i = @i + 1
END

DROP TABLE #tmpProcedureReports
'
		EXEC(@Sql)
			

	IF @actualVersion = @version - 1
	EXEC ccsp_getVersion 'BD', @version

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
