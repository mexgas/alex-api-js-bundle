CREATE PROCEDURE [dbo].[ccspRepMKTAgentes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 set nocount on
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
		select @to = getdate()

if @action = 1 begin

CREATE TABLE #times(
	[ID] INT primary key,
	[Start] DATETIME,
	[Stop] DATETIME
	)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

declare @starttime datetime,@number int
	set @starttime = @from
	set @number = 0

while @number <= (datediff(mi,@starttime,@to)/15) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*15, @starttime),DATEADD(mi, (@number+1)*15, @StartTime)
		   set @number = @number +1
	end

select
	cal_inicio dateStartDetail,
	dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
	[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end,0) as timegroup,
	[dbo].[GetTimeGroup](
	dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end )	
	,1) as timegroup_next,
		 c.user_id,

		 isnull(count(case when c.statusCall_id=13 then 1 else null end),0) nacd,
         isnull(count(case when c.statusCall_id=13 and c.cal_tnotas>0 then 1 else null end),0) nacw,
         isnull(count(case when l.modo in (3,4) and l.tipo=1 then 1 else NULL end),0) cayuda,
         isnull(count(case when l.modo in (0,3,4) and l.tipo=1 then 1 else NULL end),0) nxfersal,
		 isnull(sum(case when c.statuscall_id = 13 then (c.cal_twait + c.cal_txfer + c.cal_tring) else 0 end),0) tresp,
		 isnull(sum(case when c.statusCall_id=13 and c.cal_tdialog>=0 then c.cal_tdialog else 0 end),0) tacd,
         isnull(sum(case when c.statusCall_id=13 then c.cal_tnotas else 0 end),0) tacw

		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
	   into #timeAgenteTransfer
       from cccallsin c
       LEFT OUTER JOIN ccLogTransfers l (nolock) on (l.cal_id = c.cal_id and l.fechaFin between @from and @to)
       where c.cal_inicio between @from and @to and 
	   c.user_id>0
	   and c.inbound_id>0 	  
       group by c.user_id,cal_inicio
	   ,[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end,0)
	   ,[dbo].[GetTimeGroup](
		dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end )	
		,1)

	select * into #timeAgenteTransfer2 from #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next) > 15
	insert into #timeAgenteTransfer
	select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,
		[User_id]
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacd else 0 end as nacd
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacw else 0 end as nacw
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then cayuda else 0 end as cayuda
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfersal else 0 end as nxfersal
		,[dbo].TimeInterval(th.Start,th.Stop,dateStartDetail,time_dialog) as tresp
		,[dbo].TimeInterval(th.Start,th.Stop,time_dialog,time_notes) as tacd
		,[dbo].TimeInterval(th.Start,th.Stop,time_notes,dateEndDetail) as tacw
		,time_dialog,time_notes,time_end_call

	from #timeAgenteTransfer2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0  

select dateadd(ss,-tstatus,fecha) dateStartDetail,
		   fecha dateEndDetail,
	dbo.GetTimeGroup(dateadd(ss,isnull(-tstatus,0),fecha),0)  as timegroup,
	dbo.GetTimeGroup(fecha,1 ) as timegroup_next,
	user_id,
             (case when TipoStatusAge_id = 7 then tstatus else 0 end) t_otra,
             (case when TipoStatusAge_id = 2 then tstatus else 0 end) t_aux,
             (case when TipoStatusAge_id = 3 then tstatus else 0 end) t_disp,
             (case when TipoStatusAge_id = 4 then tstatus else 0 end) t_dialog,
             (case when TipoStatusAge_id = 6 then tstatus else 0 end) t_notas,
             tstatus t_pers
		, case when TipoStatusAge_id = 7 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_otra
, case when TipoStatusAge_id = 2 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_aux
, case when TipoStatusAge_id = 3 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_disp
, case when TipoStatusAge_id = 4 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_dialog
, case when TipoStatusAge_id = 6 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_notas
,fecha time_total
		into #timeAgenteStatus
       from cclogagentesdia
	   where fecha between @from and @to 
	order by user_id,fecha

	select * into #timeAgenteStatus2 from #timeAgenteStatus where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteStatus where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeAgenteStatus
	select dateStartDetail,dateEndDetail,th.start,th.stop,user_id
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,dateStartDetail,time_otra)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,th.start,time_otra)
	  when th.start > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,th.start,th.stop) else  0 end as t_otra
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0  then datediff(ss,dateStartDetail,time_aux)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0 then datediff(ss,th.start,time_aux)
	  when th.start > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,th.start,th.stop)  else  0 end as t_aux

	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,dateStartDetail,time_disp)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,th.start,time_disp)
	  when th.start > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,th.start,th.stop) else  0 end as t_disp

	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,time_dialog)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,th.start,time_dialog)
	  when th.start > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,th.start,th.stop) else  0 end as t_dialog
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,dateStartDetail,time_notas)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,th.start,time_notas)
	  when th.start > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,th.start,th.stop) else  0 end as t_notas
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,dateStartDetail,time_total)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,th.start,time_total)
	  when th.start > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,th.start,th.stop) else  0 end as t_pers
	,time_otra,time_aux,time_disp,time_dialog,time_notas,time_total
	from #timeAgenteStatus2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0


delete from dbo.RepMKTAgentes with(rowlock)
		where date >= @from AND date < @to

;WITH cte (date,user_id,CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes)
AS
(
select isnull(convert(varchar(24),acd.timegroup,121),convert(varchar(24),tready.timegroup,121)) date,
		isnull(acd.user_Id,tready.User_id),
		isnull(acd.nacd,0) [CallsperACDGroupD],
		isnull(acd.tacd,0) [tACD],
		isnull(acd.tresp,0) [tAgent],
		isnull(tready.t_otra,0) [oHour],
       isnull(tready.t_aux,0) [tAux],
       isnull(tready.t_disp,0) [readyTime],
       isnull(tready.t_pers,0) [tPer],
       isnull(acd.cayuda,0) [Ayuda],
       isnull(acd.nxfersal,0) [nxfer],
	   isnull(acd.nacw,0) [nacw],
	   isnull(acd.tACW,0) [tACW],
	isnull(datepart(yyyy,convert(varchar(24),acd.timegroup,121)),0) year,
	isnull(datepart(mm, acd.timegroup),0) month,
	isnull(datepart(dd, convert(varchar(24),acd.timegroup,121)),0) day,
	isnull(datepart(hh, convert(varchar(24),acd.timegroup,121)),0) hour,
	isnull(datepart(mi,convert(varchar(24),acd.timegroup,121)),0) minutes
from (
select 
acd.timegroup,
acd.user_id,
sum(nacd) nacd,
sum(nacw) nacw,
sum(cayuda) cayuda ,
sum(nxfersal) nxfersal,
sum(tresp) tresp,
sum(tacd) tacd,
sum(tacw) tacw
	from #timeAgenteTransfer acd group by acd.timegroup,acd.user_id 
	) acd
full join
(select 
timegroup,
user_id,
sum(t_otra) t_otra,
sum(t_aux) t_aux,
sum(t_disp) t_disp,
sum(t_pers) t_pers
	from #timeAgenteStatus group by timegroup,user_id)tready on tready.user_id=acd.user_id and tready.timegroup=acd.timegroup) 

insert into RepMKTAgentes(date,userId,login,agentName,CallsperACDGroupD,tACD,tAgent,oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW,year,month,day,hour,minutes)
select date,a.user_id,u.Login,
(isnull(u.apellidopaterno,u.apellidopaterno)+' '+isnull(u.apellidomaterno,'')+' '+isnull(u.nombres,'')) agt_name,
CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes from cte a
inner join ccUserView as u on a.user_id=u.user_id
order by date,Login

drop table #times
drop table #timeAgenteTransfer
drop table #timeAgenteTransfer2
drop table #timeAgenteStatus
drop table #timeAgenteStatus2

end