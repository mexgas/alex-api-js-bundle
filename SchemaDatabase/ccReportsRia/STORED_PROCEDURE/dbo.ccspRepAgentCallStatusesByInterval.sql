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

	
	IF OBJECT_ID(N'tempdb..#tempNotReady', N'U') IS NOT NULL  drop table #tempNotReady
	IF OBJECT_ID(N'tempdb..#tempNotReady2', N'U') IS NOT NULL  drop table #tempNotReady2

	declare @valuenav varchar(100)
	declare @tnav int, @twbCall int
	
	select @valuenav = valor from ccSettings where setting_id = 40

	select @tnav = Value from dbo.fn_RIASplitDelimited(@valuenav,'|') where Id = 1
	select @twbCall = Value from dbo.fn_RIASplitDelimited(@valuenav,'|') where Id = 2

	
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
	IF OBJECT_ID(N'tempdb..#tempNotReady', N'U') IS NOT NULL  drop table #tempNotReady
	IF OBJECT_ID(N'tempdb..#tempNotReady2', N'U') IS NOT NULL  drop table #tempNotReady2
	
	end
end