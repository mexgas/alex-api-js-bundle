CREATE PROCEDURE [dbo].[ccspRepTrunkBusy]

@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
begin
	
	create table #RtnValue(cal_id int,
	[user_id] int,
	fecha datetime,
	puerto int,
	cam_id int,
	tbusy int,
	contador int,
	tipo int,
	fechafin datetime,
	fechaInicio datetime,
	fechaFinal datetime)

	create nonclustered index ix_RtnValue on #RtnValue(
	[fecha] DESC,
	[fechafin] DESC
	)

	create nonclustered index ix_RtnValue2 on #RtnValue(
	[fechaInicio] DESC,
	[fechafinal] DESC
	)

	create table #RtnValue2(cal_id int,
	[user_id] int,
	fecha datetime,
	puerto int,
	cam_id int,
	tbusy int,
	contador int,
	tipo int,
	fechafin datetime,
	fechaInicio datetime,
	fechaFinal datetime)

	create nonclustered index ix_RtnValue on #RtnValue2(
	[fecha] DESC,
	[fechafin] DESC
	)

	insert into #RtnValue
		select dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id,
		sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)) as tBusy,1 as contador, 1 as tipo,
		dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha) as fechafin			
		,dbo.GetTimeGroup(dials.fecha,0) as timegroup		
		,dbo.GetTimeGroup(
		dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)			
		,1) as timegroup_next					
		from ccologdials as dials left join ccocallsout as calls 
		on (dials.Puerto = calls.cal_puerto and dials.cal_id = calls.cal_id ) 
		where dials.fecha >= @from and dials.fecha < getdate()
		group by dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id 
	union all
		select incall.cal_id,incall.user_id,incall.cal_inicio as fecha,incall.cal_puerto as puerto, incall.inbound_id as cam_id, 
		sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)) as tBusy,1 as contador, 0 as tipo,
		dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio) as fechafin
		,dbo.GetTimeGroup(incall.cal_inicio,0) as timegroup	
		,dbo.GetTimeGroup(
		dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)
		,1) as timegroup_next				
		from cccallsin as incall 
		where cal_inicio >= @from and cal_inicio < getdate()
		group by incall.cal_id, incall.user_id, incall.cal_inicio, incall.cal_puerto, incall.inbound_id  

	delete #RtnValue
	where tbusy = 0
		
	CREATE TABLE #times(
	[ID] INT primary key,
	[Start] DATETIME,
	[Stop] DATETIME
	)

	create nonclustered index ix_times on #times(
	[Start] DESC,
	[Stop] DESC
	)
	create nonclustered index ix_times2 on #times(
	[Start] DESC
	)

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=15
		
	insert into #RtnValue2
	select *
	from #RtnValue
	where datediff(mi,fechainicio,fechafinal) > 15

	delete #RtnValue
	where datediff(mi,fechainicio,fechafinal) > 15

	insert into #RtnValue
	select cal_id, [user_id], th.start as fecha, t.Puerto, t.cam_id
		,dbo.TimeInterval(th.start,th.stop,t.fecha,fechafin)  as tBusy				
	,t.contador as llamadas, tipo, th.stop, th.start, th.stop
	from #RtnValue2 t
	join #times th on (t.fecha > th.Start and t.fecha < th.stop) OR th.Start between t.fecha and t.fechafin

	drop table #times
	drop table #RtnValue2

	select fecha as timegroup, puerto as port,cam_id,sum(tBusy) as tbusy,sum(contador) as llamadas,tipo
	into #ccGenOutPortStats
	from #RtnValue
	group by fecha, puerto, cam_id, tipo

	drop table #RtnValue
		
	delete from RepInTrunkBusy where date >= @from AND date < @to

	insert into RepInTrunkBusy
		select timegroup, #ccGenOutPortStats.cam_id, [in].descripcion, port, tbusy, llamadas,
		datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		from #ccGenOutPortStats
		inner join ccInbound [in] on ([in].inbound_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 0)
		where timegroup >= @from and timegroup < @to
			
	delete from RepOutTrunkBusy where date >= @from AND date < @to

	insert into RepOutTrunkBusy
		select timegroup, #ccGenOutPortStats.cam_id, [out].cam_descripcion, port, tbusy, llamadas,
		datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		from #ccGenOutPortStats
		inner join cccamps [out] on ([out].cam_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 1)
		where timegroup >= @from and timegroup < @to
		
	delete from RepTrunkBusy where date >= @from AND date < @to

	insert into RepTrunkBusy
		select timegroup, port, tbusy, llamadas,
		datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		from #ccGenOutPortStats
		where timegroup >= @from and timegroup < @to
				
	drop table #ccGenOutPortStats 
end