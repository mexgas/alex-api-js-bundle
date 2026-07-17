--Version 122.01-6_20200424_1
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 81

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		
		SET @process = 'CW-3956 Corregir columna loginTime '
SET @sql = '
IF EXISTS(SELECT * FROM sys.columns WHERE name = N''loginTime'' AND Object_ID = OBJECT_ID(N''repagentsummary'') )
BEGIN
	exec sp_rename ''RepAgentSummary.loginTime'', ''loginMktTime'', ''column''
END'
EXEC(@sql)

SET @process = 'CW-3956 Corregir columna logoutTime'
SET @sql = '
IF EXISTS(SELECT * FROM sys.columns WHERE name = N''logoutTime'' AND Object_ID = OBJECT_ID(N''repagentsummary'') )
BEGIN
	exec sp_rename ''RepAgentSummary.logoutTime'', ''logoutMktTime'', ''column''
END
'
EXEC(@sql)

SET @process = 'CW-3957 Crear tabla RepMKTIntervalosSalida'
SET @sql = '
if not exists (select * from sys.tables where name = N''RepMKTIntervalosSalida'')
begin
	create table RepMKTIntervalosSalida(
		date datetime,
		rango1 varchar(5),
		rango2 varchar(5),
		Staff smallint,
		Realizadas smallint,
		Ocupado smallint,
		NoContestan smallint,
		Fax smallint,
		Buzon smallint,
		SinTono smallint,
		nout_service smallint,
		Other smallint,
		Congestion smallint,
		Cancelado smallint,
		contacted smallint,
		Answered smallint,
		abandonedCalls smallint,
		SinAgentes smallint,
		NoContestadas smallint,
		nabndxferout smallint,
		nabndringout smallint,
		nabnddlgout smallint,
		TMO int,
		promDialogo int,
		holdTime int,
		tnotesout int,
		tringout int,
		readyTime int,
		notReadyTime int,
		Personal int,
		avrAnswer int,
		Reductor numeric(18,2),
		AvgAbandon numeric(18,2),
		OcupacionCOPC numeric(18,2),
		Cam_id int
	)
end
'
EXEC(@sql)

SET @process = 'CW-3957 Registrar reporte en ReportsFilters'
SET @sql = '
if not exists(select * from ReportsFilters where id = 4260) begin
	insert into ReportsFilters values (''Outbound Calls Intervals'', ''campaigns'', 4260)
end
'
EXEC(@sql)

SET @process = 'CW-3957 Registrar reporte en ReportsFiltersMenus'
SET @sql = '
if not exists (select * from ReportsFiltersMenus where idReport = 4260) begin
	insert into ReportsFiltersMenus values (4260,''date'')
	insert into ReportsFiltersMenus values (4260,''filterby'')
end
'
EXEC(@sql)

SET @process = 'CW-3957 Registrar reporte en ReportsTotals'
SET @sql = '
if not exists (select * from ReportsTotals where id = 4260) begin
	insert into ReportsTotals values (4260, '''')
end
'
EXEC(@sql)

SET @process = 'CW-3957 Stored procedure ccspRepMKTIntervalosSalida'
SET @sql = '

if exists (select * from sys.procedures where name = N''ccspRepMKTIntervalosSalidas'')
begin
	DROP PROCEDURE ccspRepMKTIntervalosSalidas;
end'
EXEC(@sql)

SET @process = 'CW-3957 Crear stored procedure ccspRepMKTIntervalosSalidas'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepMKTIntervalosSalidas] 
	@action as tinyint, @from as datetime = null, @to as datetime = null	
	AS
	SET NOCOUNT ON
	if @from is null
		select @from = convert(datetime, convert(varchar(11), getdate()))
	if @to is null
		select @to = getdate()

	if @action = 1
	BEGIN
		declare
		@tresDialog AS smallint,
		@tresRing AS smallint,
		@number as int

		set @number = 0

		create table #OutboundCalls(
			dia datetime,
			rango1 varchar(5),
			Reductor numeric(18,2),
			Realizadas smallint,
			Staff smallint,
			Contactos smallint,
			Ocupado smallint,
			NoContestan smallint,
			Fax smallint,
			Buzon smallint,
			SinTono smallint,
			NoService smallint,
			Otro smallint,
			Congestion smallint,
			Cancelado smallint,
			Contestadas smallint,
			Abandonadas smallint,
			SinAgentes smallint,
			NoContestadas smallint,
			CortadasRing smallint,
			CortadasDespRing smallint,
			CortadasDlg smallint,
			TMO int,
			TiempoTotalTT int,
			TiempoTotalHold int,
			TiempoTotalACW int,
			TiempoTotalRing int,
			VelocidadResp int,
			Abandono numeric(18,2),
			OcupacionCOPC numeric(18,2),
			Cam_id int
		)

		CREATE TABLE #ccintervalos
			   ([Id]     [int],
				[fecha]  [datetime],
				[rango1] [varchar](5),
				[rango2] [varchar](5))

		create table #tPersonal(
				rango1 varchar(5),
				rango2 varchar(5),
				uid int,
				tlogueofra int
			)

		create table #sessionTime (
			[user_id] int,
			[tlogueo] int,
			[login] datetime,
			logout datetime,
			login2 varchar(5),
			logout2 varchar(5)
		)

		create table #loglogin(
			[user_id] int,
			tipo int,
			fecha datetime,
			cam_id int
		)

		create table #tDisp(
			fecha datetime,
			rango1 varchar(5),
			rango2 varchar(5),
			tnodispo int,
			tdispo int
		)

		while @number < (datediff(mi,@from,DATEADD(DD,1,@from))/30) 
		begin
			insert into #ccintervalos
			SELECT @number,
			@from,
			StartTime = right(''00'' + cast(datepart(hh,DATEADD(mi, @number*30, @from)) as varchar(2)),2) + '':'' + right(''00'' + cast(datepart(mi,DATEADD(mi, @number*30, @from)) as varchar(2)),2),
			EndTime = right(''00'' + cast(datepart(hh,DATEADD(mi, (@number+1)*30, @from)) as varchar(2)),2) + '':'' + right(''00'' + cast(datepart(mi,DATEADD(mi, (@number+1)*30, @from)) as varchar(2)),2)
			set @number = @number +1
		end

		insert into #loglogin
		select cc.User_id, cc.TipoMov, cc.fecha, cl.IdCampEsp
		from ccloglogin cc
		inner join ccLogAgentesDia cl on cc.User_id = cl.User_id and cc.fecha = cl.fecha
		order by cc.fecha

		EXEC @tresDialog=ccspConfigTresDialog
		EXEC @tresRing=ccspConfigTresRing
	
			insert into #sessionTime
	select [user_id], DATEDIFF(ss, d.login, d.logout) as tlogueo, min(d.login) as login, max(d.logout) as logout,
	case when datepart(mi,min(d.login)) < 30 then right(''00'' + cast(datepart(hh,min(d.login)) as varchar(2)),2) + '':00'' 
	else right(''00'' + cast(datepart(hh,min(d.login)) as varchar(2)),2) + '':30'' end as login2,
	case when datepart(mi,max(logout)) < 30 then right(''00'' + cast(datepart(hh,max(logout)) as varchar(2)),2) + '':30'' 
	else right(''00'' + cast(datepart(hh,max(logout)) + 1 as varchar(2)),2) + '':00'' end as logout2
	from(
	select a.[user_id], a.fecha as ''login'',
	(select isnull(max(Fecha),getdate()) from #loglogin b with(nolock) where b.user_id = a.user_id and b.tipo = 0 and b.fecha >= a.fecha and b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
	from #loglogin with(nolock) where [user_id] = b.[user_id] and tipo = 1 and fecha > a.fecha )) as ''logout'' from #loglogin a
	where a.tipo=1 and fecha >= @from and fecha <= @to
	union 
	select * 
	from( select a.[user_id], 
		(select isnull(max(Fecha),getdate()) 
		from #loglogin b with(nolock)
		where b.[user_id] = a.[user_id] and b.tipo = 1 and b.fecha <= a.fecha and b.fecha >= (select isnull(max(fecha),b.fecha) from #loglogin with(nolock) where [user_id] = b.[user_id] and tipo = 0 and fecha < a.fecha )
		) as ''login'', a.fecha as ''logout''
	from #loglogin a
	where a.tipo = 0 and fecha >= @from and fecha <= @to
	) as session
	where datediff(day,[login],logout) >= 1
	) as D
	group by [user_id], d.login, d.logout
	order by [user_id]

			insert into #tPersonal
			select Pg.rango1 rango1, Pg.rango2 rango2, count(distinct Pg.uid) uid, sum(Pg.tlogueofra) tlogueofra
				from(
					select Ss.rango1 rango1, Ss.rango2 rango2, Tt.user_id uid,
						sum(case when convert(varchar(5),Tt.login,108)>Ss.rango1 and convert(varchar(5),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(5),Tt.login,108),convert(varchar(8),Tt.logout,108))
									when convert(varchar(5),Tt.login,108)>Ss.rango1 and convert(varchar(5),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(5),Tt.login,108),(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end))
									when convert(varchar(5),Tt.login,108)<Ss.rango1 and convert(varchar(5),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then 1800
									when convert(varchar(5),Tt.login,108)<Ss.rango1 and convert(varchar(5),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,Ss.rango1,convert(varchar(5),Tt.logout,108))
						else 0 end) tlogueofra 						
					from #ccintervalos Ss
					LEFT OUTER JOIN #sessionTime Tt ON Tt.login2 <= Ss.rango1 and (Tt.logout2 >= case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end or Tt.logout2 is null)		
					group by Ss.rango1,	Ss.rango2, Tt.user_id
				) PG
			group by Pg.rango1,	Pg.rango2
	
			insert into #tDisp
			select Tm.fecha fecha, Tm.rango1 rango1, tm.rango2 rango2,
				isnull(sum(case when Tm.TipoStatusAge_id=2 then Tm.tstatusfra end),0) tnodispo,
				isnull(sum(case when Tm.TipoStatusAge_id=3 then Tm.tstatusfra end),0) tdispo
			from(
				select G.fecha fecha, G.rango1 rango1, G.rango2 rango2, G.user_id user_id,
					case when G.login >= Rg.RangoFinal then 0
							when G.tlogueofra = 1800 and Rg.tstatusfra = 1800 then 1800 
							when Rg.tstatusfra = 1800 then G.tlogueofra 
							when G.tlogueofra = 1800 then Rg.tstatusfra 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and Rg.RangoInicial >= G.login and Rg.RangoFinal >= G.logout) then datediff(ss,Rg.RangoInicial,G.logout) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial and G.logout <= Rg.RangoFinal) then datediff(ss,G.login,G.logout) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial and G.logout >= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal)
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial and G.logout <= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,G.logout)
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial and G.logout >= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal)
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,G.login,Rg.RangoFinal) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,G.logout) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal)
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,G.login,G.logout) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,G.logout) 
							when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,G.login,G.logout) 
							when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal)
							when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,G.Rango1,convert(varchar(5),G.logout,108)) 
							when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,G.Rango1,convert(varchar(5),Rg.RangoFinal,108)) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,convert(varchar(5),G.login,108),G.Rango2) 
							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,convert(varchar(5),Rg.RangoInicial,108),G.Rango2)
							when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal) 
							when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoFinal) then datediff(ss,Rg.RangoFinal,G.login) 
 							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoInicial) then datediff(ss,G.logout,Rg.RangoInicial) 
 							when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,G.logout) 
							else 0     
					end  tstatusfra,
					case when Rg.tstatusfra is not null then 1 else 0 end nstatusfra,G.tlogueofra tlogueofra,Rg.TipoStatusAge_id TipoStatusAge_id
				from(
					select distinct (S.fecha + S.rango1) fecha, S.rango1 rango1, S.rango2 rango2, T.user_id user_id, T.login login, T.logout logout,
						case when convert(varchar(5),t.login,108)>s.rango1 and convert(varchar(5),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(5),t.login,108),convert(varchar(5),t.logout,108))
				    				when convert(varchar(5),t.login,108)>s.rango1 and convert(varchar(5),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(5),t.login,108),(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end))
									when convert(varchar(5),t.login,108)<s.rango1 and convert(varchar(5),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then 1800
									when convert(varchar(5),t.login,108)<s.rango1 and convert(varchar(5),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,s.rango1,convert(varchar(5),t.logout,108))
						else 0 end tlogueofra 						
					from #ccintervalos S
					LEFT OUTER JOIN #sessionTime t ON t.login2 <= s.rango1 and (t.logout2 >= case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end or t.logout2 is null)
				)G
				LEFT OUTER JOIN(
					select	lg.user_id user_id, lg.rangoinicial rangoinicial, lg.rangofinal rangofinal, V.rango1 rango1, V.rango2 rango2,
						sum(case when convert(varchar(5),lg.rangoInicial,108)>V.rango1 and convert(varchar(5),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(5),lg.rangoInicial,108),convert(varchar(5),lg.rangoFinal,108))
							when convert(varchar(5),lg.rangoInicial,108)>V.rango1 and convert(varchar(5),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(5),lg.rangoInicial,108),(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end))
							when convert(varchar(5),lg.rangoInicial,108)<V.rango1 and convert(varchar(5),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then 1800
							when convert(varchar(5),lg.rangoInicial,108)<V.rango1 and convert(varchar(5),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,V.rango1,convert(varchar(5),lg.rangoFinal,108))
							else 0 end) tstatusfra, 
							lg.TipoStatusAge_id TipoStatusAge_id
					from(
						select user_id as user_id, dateadd(ss,-1*(t.tStatus),t.fecha) rangoInicial,t.fecha rangoFinal,							
							isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0) rango1,
							isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0) rango2,														
							sum(t.tStatus) tstatus, t.TipoStatusAge_id TipoStatusAge_id
						from  cclogagentesdia t 
						where t.fecha between @from and @to
						group by user_id,dateadd(ss,-1*(t.tStatus),t.fecha),t.fecha,
							isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0),
							isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0),
							t.TipoStatusAge_id
					) lg
					left outer join (SELECT rango1,rango2 from #ccintervalos) V on (V.rango1 >= lg.rango1 and case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end <= lg.rango2)
					group by lg.user_id,lg.rangoinicial,lg.rangofinal,V.rango1,V.rango2,lg.TipoStatusAge_id 
				) Rg on (Rg.user_id = G.user_id and Rg.rango1 = G.rango1 and Rg.rangoinicial < G.logout and Rg.rangofinal > G.login)
			) Tm
			group by Tm.fecha,Tm.rango1,Tm.rango2

			insert into #OutboundCalls
			select 
				convert(varchar(10),fecha,121) dia, rango1, isnull(reductor,0) Reductor, isnull(Recibidas,0) Realizadas, isnull(uid,0) Staff,
				isnull(Contactos,0) Contactos, isnull(Ocupado,0) Ocupado, isnull(NoContestan,0) NoContestan, isnull(Fax,0) [Fax/Modem],
				isnull(Buzon,0) Buzon, isnull(SinTono,0) SinTono, isnull(NoService,0) SinServicio, isnull(Otro,0) Otros, isnull(Congestion,0) Congestion,
				isnull(Cancelado,0) Canceladas,isnull(Contestadas,0) Contestadas, isnull(Abandonadas,0) Abandonadas, isnull(SinAgentes,0) SinAgentes,
				isnull(NoContestadas,0) NoContestadas, isnull(CortadasRing,0) CortadasRing, isnull(CortadasDespRing,0) CortadasDespRing , isnull(CortadasDlg,0) CortadasDlg,
				isnull(TMO,0) TMO, isnull(TiempoTotalTT,0) TiempoTotalTT, isnull(TiempoTotalHold,0) TiempoTotalHold, isnull(TiempoTotalACW,0) TiempoTotalACW,
				isnull(TiempoTotalRing,0) TiempoTotalRing, isnull(VelocidadResp,0) VelocidadResp, isnull([Abandono],0) Abandono, isnull(Ocupacion,0) Ocupacion, cam_id as cam_id
				from (
					select 	
						case when CONVERT(int, SUBSTRING(CONVERT(char(30),case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 
						then CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' 
						else CONVERT(varchar(2),case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' 
						end as rango1,
						sum(cal_tnotas) reductor,
						convert(varchar(10),fecha,121) fecha,
						COUNT(distinct co.user_id) as uid,
						COUNT(*) [Recibidas],
						lo.cam_id as cam_id, 
						COUNT(case when tipoResDial_id = 2 then 1 else null end) Ocupado,
						COUNT(case when tipoResDial_id = 3 then 1 else null end) NoContestan,
						COUNT(case when tipoResDial_id = 4 then 1 else null end) Fax,
						COUNT(case when tipoResDial_id = 11 then 1 else null end) Buzon,
						COUNT(case when tipoResDial_id = 5 then 1 else null end) SinTono,
						COUNT(case when tipoResDial_id = 10 then 1 else null end) NoService,
						COUNT(case when tipoResDial_id = 8 then 1 else null end) Otro,
						COUNT(case when tipoResDial_id = 12 then 1 else null end) Congestion,
						COUNT(case when tipoResDial_id = 13 then 1 else null end) Cancelado,
						COUNT(case when tipoResDial_id = 1 then 1 else null end) [Contactos], --contactos sistema
						COUNT(case when statuscall_id=13 and cal_tdialog > @tresDialog then 1 else null end) [Contestadas], --contactos agente
						COUNT(case when statusCall_id in (6,10,11,12,14,15,16) or (canceledNoAgents<>0 and answerbit=1) or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end) [Abandonadas],
						COUNT(case when statuscall_id = 6 then 1 else null end) SinAgentes,
						COUNT(case when statuscall_id in (15,16) then 1 else null end) NoContestadas,
						COUNT(case when statuscall_id in (11,10,12,14) and cal_tring<=@tresRing then 1 else null end) CortadasRing,
						COUNT(case when statuscall_id in (11,10,12,14) and cal_tring>@tresRing then 1 else null end) CortadasDespRing,
						COUNT(case when statuscall_id=13 and cal_tdialog <=@tresDialog then 1 else null end) CortadasDlg,
						case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh)/COUNT(case when statuscall_id=13 then 1 else null end) end as TMO,
						case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else SUM(cal_tDialog)/COUNT(case when statuscall_id=13 then 1 else null end) end as TiempoTotalTT,
						SUM(cal_tMoh) TiempoTotalHold,
						SUM(cal_tnotas) TiempoTotalACW,
						sum(cal_tring+cal_txfer) TiempoTotalRing,
						case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else sum(cal_twait)/COUNT(case when statuscall_id=13 then 1 else null end) end VelocidadResp,
						cast(case when count(case when statusCall_id=13 then 1 else null end)=0 then 0 else count(case when statusCall_id in (6,10,11,12,14,15,16) or (canceledNoAgents<>0 and answerbit=1) or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end)*100.00/count(case when tipoResDial_id=1 then 1 else null end) end as decimal(5,2)) [Abandono],
						SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh) [Ocupacion]
						from ccologdials lo (nolock) 
						left join ccoCallsOut co (nolock) on co.cal_id=lo.cal_id
						where fecha between @from and @to 
						group by 
							case when CONVERT(int, SUBSTRING(CONVERT(char(30), case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 
							then CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' 		
							else CONVERT(varchar(2),case when ({ fn HOUR( case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR( case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR( case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' 
							end, convert(varchar(10),fecha,121), lo.cam_id
				)x
				order by convert(varchar(10),fecha,121)

				delete RepMKTIntervalosSalida with(rowlock) where date between @from and @to

				insert into RepMKTIntervalosSalida
				select 
					oc.dia as date,
					r.rango1,
					r.rango2,
					oc.Staff,
					oc.Realizadas,
					oc.Ocupado,
					oc.NoContestan,
					oc.Fax,
					oc.Buzon,
					oc.SinTono,
					oc.NoService as nout_service,
					oc.Otro as other,
					oc.Congestion,
					oc.Cancelado,
					oc.Contactos,
					oc.Contestadas as Answered,
					oc.Abandonadas as abandonedCalls,
					oc.SinAgentes,
					oc.NoContestadas,
					oc.CortadasRing as nabndxferout,
					oc.CortadasDespRing as nabndringout,
					oc.CortadasDlg nabnddlgout,
					oc.TMO,
					oc.TiempoTotalTT as promDialogo,
					oc.TiempoTotalHold as holdTime,
					oc.TiempoTotalACW as tnotesout,
					TiempoTotalRing as tringout,
					d.tdispo as readyTime,
					d.tnodispo as notReadyTime,
					l.tlogueofra as Personal,
					VelocidadResp as avrAnswer,
					isnull(case when L.tlogueofra=0 then 0 else (oc.Reductor+d.tnodispo)*100/L.tlogueofra end,0) as Reductor,
					oc.Abandono as AvgAbandon,
					isnull(case when L.tlogueofra=0 then 0 else oc.OcupacionCOPC*100.00/L.tlogueofra end,0) as OcupacionCOPC,
					Cam_id
				from #OutboundCalls oc
				left join #ccintervalos r on oc.rango1 = r.rango1
				left join #tPersonal L on L.rango1=r.rango1 and L.rango2=r.rango2
				left join #tDisp d on d.rango1 = r.rango1 and d.rango2 = r.rango2

		drop table #ccintervalos
		drop table #OutboundCalls
		drop table #sessionTime
		drop table #loglogin
		drop table #tPersonal
		drop table #tDisp
	END

'
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
