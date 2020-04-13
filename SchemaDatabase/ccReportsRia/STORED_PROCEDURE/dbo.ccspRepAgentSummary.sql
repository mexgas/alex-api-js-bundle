CREATE PROCEDURE [dbo].[ccspRepAgentSummary] 
	@action as tinyint, @from as datetime = null, @to as datetime = null	
	AS
	SET NOCOUNT ON
	if @from is null
		select @from = convert(datetime, convert(varchar(11), getdate()))
	if @to is null
		select @to = getdate()

	if @action = 1
	BEGIN

	declare @break integer 
	declare @pagos integer 
	declare @personal integer 
	declare @trabajoAdm integer
	declare @retro integer
	declare @falla integer
	declare @capacitacion integer
	declare @callwork integer
	declare @pausaGrl integer
	declare @rh integer
	declare @inicio integer

	declare @tresRing AS smallint
	declare @tresDialog AS smallint
	exec @tresRing=ccspConfigTresRing
	exec @tresDialog=ccspConfigTresDialog

	create table #AgentSession(
		user_id int not null,
		[user] varchar(255),
		login datetime ,
		logout datetime,
		sessionTime int,
		daygroup datetime
	)

	create table #RepDetail(
		user_id int not null,
		notReady int,
		daygroup datetime
	)

	create table #tipoNotReady(
		user_id int not null,
		daygroup datetime,
		break_ int,
		pagos_ int,
		personal_ int,
		trabajoAdm_ int,
		retro_ int,
		falla_ int,
		capacitacion_ int,
		callwork_ int,
		pausagrl_ int,
		rh_ int,
		inicio_ int
	)

	create table #CallsOut(
		user_id int not null,
		NoCalifOut int,
		NotAttendedCallOut int,
		AttendedCallOut int,
		tDialogOut int,
		tNotesOut int,
		abnd_xfer int,
		abnd_ring int,
		abnd_dialog int,
		daygroup datetime
	)

	create table #CallsIn(
		user_id int not null,
		NoCalifIn int,
		NotAttendedCallIn int,
		AttendedCallIn int,
		tDialogIn int,
		tNotesIn int,
		abnd_xfer int,
		abnd_ring int,
		abnd_dialog int,
		daygroup datetime
	)

	select 
		@break = max(case when descripcion like 'break' then tiponotready_id else -1 end), 
		@pagos = max(case when descripcion like 'pagos' then tiponotready_id else -1 end), 
		@personal = max(case when descripcion like 'personal' then tiponotready_id else -1 end),
		@trabajoAdm = max(case when descripcion like 'trabajoAdm' then tiponotready_id else -1 end),
		@retro = max(case when descripcion like 'retro' then tiponotready_id else -1 end),
		@falla = max(case when descripcion like 'falla' then tiponotready_id else -1 end),
		@capacitacion = max(case when descripcion like 'capacitacion' then tiponotready_id else -1 end), 
		@callwork = max(case when descripcion like 'CWCallWork' then tiponotready_id else -1 end), 
		@pausaGrl = max(case when descripcion like 'pausaGrl' then tiponotready_id else -1 end),
		@rh = max(case when descripcion like 'rh' then tiponotready_id else -1 end),
		@inicio = max(case when descripcion like 'inicio' then tiponotready_id else -1 end) 
	from cctiponotready 

	insert into #AgentSession
		select	g.userId, g.[user] as [user], min(g.loginTime) as login, MAX(g.logoutTime) as logout, sum(g.sessionTimeSeconds) as sessionTime,
			dbo.getdaygroup(g.loginTime) as daygroup
		from RepAgentSession g
		where dbo.getdaygroup(g.loginTime) BETWEEN @from AND @to
		group by dbo.getdaygroup(g.logintime), g.userId, g.[user]

	insert into #RepDetail
		select r.userId, sum(r.timeSeconds) as notReady, dbo.getdaygroup(r.date) as daygroup
		from RepAgentNotReady r
		where dbo.getdaygroup(r.date) BETWEEN @from AND @to
		group by dbo.getdaygroup(r.date), r.userId

	insert into #tipoNotReady
		select	r.userId, dbo.getdaygroup(r.startDate) daygroup,
			isnull(sum(case r.tiponotreadyId when @break then r.statusTime end), 0) as break_,
			isnull(sum(case r.tiponotreadyId when @pagos then r.statusTime end), 0) as pagos_,
			isnull(sum(case r.tiponotreadyId when @personal then r.statusTime end), 0) as personal_,
			isnull(sum(case r.tiponotreadyId when @trabajoAdm then r.statusTime end), 0) as trabajoAdm_,
			isnull(sum(case r.tiponotreadyId when @retro then r.statusTime end), 0) as retro_,
			isnull(sum(case r.tiponotreadyId when @falla then r.statusTime end), 0) as falla_,
			isnull(sum(case r.tiponotreadyId when @capacitacion then r.statusTime end), 0) as capacitacion_,
			isnull(sum(case r.tiponotreadyId when @callwork then r.statusTime end), 0) as callwork_,
			isnull(sum(case r.tiponotreadyId when @pausaGrl then r.statusTime end), 0) as pausagrl_,
			isnull(sum(case r.tiponotreadyId when @rh then r.statusTime end), 0) as rh_,
			isnull(sum(case r.tiponotreadyId when @inicio then r.statusTime end), 0) as inicio_
		from RepAgentNotReadyDet r
		where dbo.getdaygroup(r.startDate) between @from and @to
		group by dbo.getdaygroup(r.startDate), r.userId

	insert into #CallsOut
		select	r.User_id,
			isnull(sum(case when r.calif_id =0 then 1 else null end),0) NoCalifOut,
			isnull(sum(case when r.statusCall_id = 11 then 1 else null end),0) NotAttendedCallOut,
			isnull(sum(case when r.statusCall_id = 13 then 1 else null end),0) AttendedCallOut,
			sum(r.cal_tDialog) tDialogOut, sum(r.cal_tNotas) tNotesOut,
			COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer,
			COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring,
			COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog,
			dbo.getdaygroup(r.cal_Inicio) as daygroup
		from ccoCallsOut r with(index(IX_ccoCallsOut_2),nolock)
		where dbo.getdaygroup(r.cal_Inicio) between @from and @to and cal_manual in (0,2)
		group by dbo.getdaygroup(r.cal_Inicio), r.User_id

	insert into #CallsIn
		select	r.User_id,
			isnull(sum(case when r.calif_id =0 then 1 else null end),0) NoCalifIn,
			isnull(sum(case when r.statusCall_id = 11 then 1 else null end),0) NotAttendedCallIn,
			isnull(sum(case when r.statusCall_id = 13 then 1 else null end),0) AttendedCallIn,
			sum(r.cal_tDialog) tDialogIn, sum(r.cal_tNotas) tNotesIn,
			COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END)AS abnd_xfer,
			COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring,
			COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog,
			dbo.getdaygroup(r.cal_Inicio) as daygroup
		from ccCallsIn r with(index(IX_ccCallsIn),nolock)
		where dbo.getdaygroup(r.cal_Inicio) between @from and @to
		group by dbo.getdaygroup(r.cal_Inicio), r.User_id 

	delete RepAgentSummary with(rowlock) where date between @from and @to

	insert into RepAgentSummary

	select	a.daygroup as date,
		a.user_id as userId, 
		a.[user] as [user],
		''  as Campaing,
		sum(a.sessionTime) as sessionTime,
		MIN(a.login) as loginTime,
		MAX(a.logout) as logoutTime,
		(sum(isnull(co.tDialogOut,0)) + sum(isnull(co.tNotesOut,0)) + sum(isnull(ci.tDialogIn,0)) + sum(isnull(ci.tNotesIn,0))) as dialogTime,
		ISNULL(sum(r.notready),0) as ndTime,
		sum(isnull(co.AttendedCallOut,0)) as NCallsOut,
		sum(isnull(ci.AttendedCallIn,0)) as NCallsIn,
		ISNULL(sum(co.abnd_xfer) + sum(co.abnd_ring) + sum(co.abnd_ring) + sum(ci.abnd_xfer) + sum(ci.abnd_ring) + sum(ci.abnd_ring),0) as NCallsCorta,
		ISNULL(SUM(isnull(co.NotAttendedCallOut,0)) + SUM(isnull(ci.NotAttendedCallIn,0)),0) as NAtend,
		ISNULL(sum(isnull(ci.NoCalifIn,0)) + sum(isnull(co.NoCalifOut,0)),0) as NNoCalif,
		ISNULL(SUM(isnull(t.break_,0)), 0) as NdBreak,
		ISNULL(SUM(t.personal_), 0) as NdPersonal,
		ISNULL(SUM(t.pagos_), 0) as NdPagos,
		ISNULL(SUM(t.trabajoAdm_), 0) as NdTrabajoAdm,
		ISNULL(SUM(t.retro_), 0) as NdRetro,
		ISNULL(SUM(t.falla_), 0) as NdFalla,
		ISNULL(SUM(t.capacitacion_), 0) as NdCapacitacion,
		ISNULL(SUM(t.callwork_), 0) as NdCWCallWork,
		ISNULL(SUM(t.pausagrl_), 0) as NdPausaGrl,
		ISNULL(SUM(t.rh_), 0) as NdRH,
		ISNULL(SUM(t.inicio_), 0) as NdInicio,
		ISNULL(sum(a.sessionTime),0) - ISNULL(sum(r.notready),0) as Available,
		ISNULL((sum(isnull(co.tDialogOut,0)) + sum(isnull(co.tNotesOut,0)) + sum(isnull(ci.tDialogIn,0)) + sum(isnull(ci.tNotesIn,0))) / (sum(co.AttendedCallOut) + sum(ci.AttendedCallIn)),0)  as PromDialog,
		0 as Skill,
		'Verde' as Center
	from #AgentSession a
	left join #RepDetail r on r.user_id = a.user_id and r.daygroup = a.daygroup
	left join #tipoNotReady t on t.user_id = a.user_id and t.daygroup = a.daygroup
	left join #CallsOut co on co.user_id = a.user_id and co.daygroup = a.daygroup
	left join #CallsIn ci on ci.user_id = a.user_id and ci.daygroup = a.daygroup 
	group by a.user_id, a.daygroup, a.[user]
	order by a.daygroup

	drop table #AgentSession
	drop table #RepDetail
	drop table #tipoNotReady
	drop table #CallsOut
	drop table #CallsIn

	END