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
