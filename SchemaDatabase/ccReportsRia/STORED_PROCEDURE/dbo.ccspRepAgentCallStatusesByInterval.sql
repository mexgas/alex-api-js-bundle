CREATE PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
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

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	declare @valuenav varchar(100)
	declare @tnav int, @twbCall int
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)

	select @valuenav = valor from ccSettings where setting_id = 40

	select @tnav = Value from dbo.fn_RIASplitDelimited(@valuenav,'|') where Id = 1
	select @twbCall = Value from dbo.fn_RIASplitDelimited(@valuenav,'|') where Id = 2

	create table #outboundData(row int identity, [User_id] int, cal_id int,
	dateStartDetail datetime, dateEndDetail datetime,
	timegroup datetime, timegroup_next datetime,
	tque int, txfer int, tring int, tdialog int, tnotes int,
	time_endque datetime, time_ring datetime, time_dialog datetime, time_notes datetime, time_end_call datetime)

	create nonclustered index iX_CamUserId on #outboundData([User_id] DESC)

	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	--Tiempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,
	dateIni datetime not null,dateEnd datetime not null,currentStatus int)

	create table #timeDetailAgent([User_id] int null, dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null,
	tav int null, tother int null,  tunknown2 decimal(10,3))

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	create nonclustered index ix_timesNotReady on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesNotReady2 on #times([Start] DESC)

	--Tiempos del agente en not ready
	create table #tempccLogAgentesNotReadyDay (row int not null, user_id int not null, TipoNotReady_id tinyint not null, tStatus int not null,
	dateStart datetime null, dateEnd datetime null)

	create table #tempNotReady (user_id int not null,
	dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null, tnav int null, twbcall int null)

	--Tiempo en transferencia estado en llamada
	create nonclustered index ix_timesCallTransf on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesCallTransf2 on #times([Start] DESC)

	create table #tempccLogtransfers (user_id int not null, cal_id int,
	dateStartTransf datetime null, dateEndTransf datetime null,
	timegroup datetime null, timegroup_next datetime null, tcallTransf int not null )

	set @dateNow=getdate()
	set @interval=15

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	-- Columnas Hora intervalo inicio = dateStartDetail, Hora intervalo fin = dateEndDetail, Tiempo en timbrando = tring, Tiempo de notas (acw) = tnotes
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cal_id,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		   ,dbo.GetTimeGroup(dateadd(ss,(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),cal_Inicio),1) as timegroup_next		   
		   ,cal_id
		   , [User_id]
		   ,ISNULL((cal_twait),0) as tque
		   ,ISNULL((cal_txfer),0)AS txfer
		   ,isnull((cal_tring),0) as tring
		   ,isnull((cal_tdialog),0) as tdialog
		   ,isnull((cal_tnotas),0) as tnotes
		  ,DATEADD(ss,isnull((0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to

	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)	 
	 ,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	 ,C.time_notes=@dateNow
	 ,C.time_end_call=@dateNow
	 ,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	 ,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	 from ccLogAgentesDia A
	 inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	 inner join #outboundData C on A.callID=C.cal_id
	 WHERE currentStatus in (4,5,6,9) and A.Tipo=1

	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
	,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
	,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
	,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
	,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
	,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id
	from #outboundData2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------

	--Columnas Tiempo disponible = tav, Tiempo en otro = tother
	insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to

	delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
	inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia

	insert into #timeDetailAgent
	select A.user_id, A.dateIni, A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tav,tother,tunknown2)
	 select
	 	User_id,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail
		,dbo.GetTimeGroup(B.fecha,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) as timegroup_next
	 	,case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	0,0 as tunknown2
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id = B.id
		where A.currentStatus not in(-2,-1,0)

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tav,tother,tunknown2)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------

	--Columnas Tiempo en capacitación (ND) = tnav, Tiempo en “trabajo previo a llamada” = twbcall
	insert into #tempccLogAgentesNotReadyDay(row,[User_id],TipoNotReady_id,tStatus,dateStart,dateEnd)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoNotReady_id,tStatus,DATEADD(ss,-tStatus,fecha)as dateStart, fecha as dateEnd
	from cclogagentesnotready
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to and TipoNotReady_id in (@tnav,@twbCall)

	insert into #tempNotReady (user_id,dateStartDetail,dateEndDetail, timegroup, timegroup_next, tnav, twbcall)
	select user_id,dateStart,dateEnd
	,dbo.GetTimeGroup(A.dateStart,0)  AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.TipoNotReady_id=@tnav then A.tStatus else 0 end tnav,
	case when A.TipoNotReady_id=@twbCall then A.tStatus else 0 end twbcall
	from #tempccLogAgentesNotReadyDay A
	where  A.dateStart>=@from AND A.dateStart<@to and A.TipoNotReady_id in (@tnav,@twbCall)

	select * into #tempNotReady2 from #tempNotReady where datediff(mi,timegroup,timegroup_next)>15
	delete #tempNotReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #tempNotReady (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tnav,twbcall)
	select dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,twbcall,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,twbcall,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	from #tempNotReady2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	--------------------------------------------------------------------------------------------

	--Columnas Tiempo en “Transferencia estando en llamada” = tcallTransf
	insert into #tempccLogtransfers (user_id, cal_id, dateStartTransf, dateEndTransf, timegroup, timegroup_next, tcallTransf)
	select A.[User_id],A.cal_id, A.dateStartDetail, A.dateEndDetail
	,dbo.GetTimeGroup(A.dateStartDetail,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEndDetail,1) as timegroup_next
	,isnull((0 + B.tAntesXfer + B.tDespuesXfer),0) as tcallTransf
	from #outboundData A
	left join ccLogtransfers B on A.cal_id=B.cal_id and Tipo=2 and modo <> 6
	where  A.dateStartDetail>=@from AND A.dateEndDetail<@to

	select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
	delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15
	--
	insert into #tempccLogtransfers (dateStartTransf,dateEndTransf,timegroup,timegroup_next,User_id,tcallTransf)
	select dateStartTransf,dateEndTransf,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,th.stop)
				when th.start > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,th.stop) else  0 end),0) as tcallTransf
	from #tempccLogtransfers2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------------------------------
	delete RepAgentCallStatusesByInterval with(rowlock) where date >= @from AND date < @to

	insert into RepAgentCallStatusesByInterval
	select
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [date],
		case when U.user_id is not null then U.user_id when Agent.User_id is not null then Agent.User_id else nReady.user_id end as [userId],
		U.login as [agentName],
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [startInterval],
		case when O.timegroup_next is not null then O.timegroup_next when Agent.timegroup_next is not null then Agent.timegroup_next else nReady.timegroup_next end as [endInterval],
		case when Agent.tav is not null then Agent.tav else 0 end as [readyTime],
		case when O.tnotes is not null then O.tnotes else 0 end as [twrapup],
		case when O.tring is not null then O.tring else 0 end as [tring],
		case when Agent.tother is not null then Agent.tother else 0 end as [tother],
		case when nReady.tnav is not null then nReady.tnav else 0 end as [tnav],
		case when O.tcallTransf is not null then O.tcallTransf else 0 end as [tCallTransf],
		case when nReady.twbcall is not null then nReady.twbcall else 0 end as [twbCall],
		datepart(yyyy,O.timegroup) as [year], datepart(mm,O.timegroup)  as [month], datepart(dd,O.timegroup)  as [day],
		datepart(hh,O.timegroup) as [hour], datepart(mi,O.timegroup)  as [minutes]
		from
			(select O.timegroup, O.timegroup_next, O.User_id, sum(tnotes) as tnotes, sum(tring) as tring
			,isnull(sum(tcallTransf),0) as tcallTransf
			from #outboundData O
			left join #tempccLogtransfers L on O.cal_id=L.cal_id
			group by O.timegroup,O.timegroup_next, O.User_id) O
		full join
			(select timegroup,timegroup_next,User_id,sum(tav) as tav,sum(tother) as tother from #timeDetailAgent
			group by timegroup,timegroup_next,User_id)
		Agent on O.timegroup=Agent.timegroup and O.User_id=Agent.User_id
		full join
			(select timegroup, timegroup_next,user_id, sum(tnav) as tnav,sum(twbcall) as twbcall from #tempNotReady
			group by timegroup, timegroup_next,user_id)
		nReady on nReady.timegroup=O.timegroup and O.User_id=nReady.User_id
		inner join ccUserView U on O.User_id = U.User_id or Agent.User_id=U.User_id or nReady.User_id=U.User_id
		where  O.timegroup>=@from AND O.timegroup_next<@to
		


	---DROP TABLES TEMP
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #times
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #tempAgentLastStatus
	drop table #outboundData
	drop table #tempccLogAgentesNotReadyDay
	drop table #tempNotReady
	drop table #tempNotReady2
	drop table #outboundData2
	drop table #tempccLogtransfers
	drop table #tempccLogtransfers2
	end
end