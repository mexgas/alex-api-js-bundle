ALTER PROCEDURE [dbo].[ccspRepInCalls]
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

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

IF OBJECT_ID('tempdb..#callsin') IS NOT NULL drop table #callsin
IF OBJECT_ID('tempdb..#callsin2') IS NOT NULL drop table #callsin2
IF OBJECT_ID('tempdb..#agentInformation') IS NOT NULL drop table #agentInformation
IF OBJECT_ID('tempdb..#ccGenInSpec') IS NOT NULL drop table #ccGenInSpec
IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL drop table #timeDetailAgent
IF OBJECT_ID('tempdb..#timeDetailAgent2') IS NOT NULL drop table #timeDetailAgent2

create table [#callsin](
row int identity,
dateStartDetail datetime,
dateEndDetail datetime,
timegroup datetime,
timegroup_next datetime,
time_endque datetime,
time_ring datetime,
time_dialog datetime,
time_notes datetime,
time_end_call datetime,
phone_in varchar(30),
cal_id int,
dni_id int,
Inbound_id int,
User_id int,
ntotal int,
ninitial int,
nout_hour int,
nout_service int,
nabnd int,
nno_agent int,
nque int,
ntimeout int,
noverflow int,
nxfer int,
nxfer_que int,
nabnd_xfer int,
nabnd_ring int,
nno_answer int,
nabnd_dialog int,
nanswer int,
nlost int,
nmsg int,
nabnd_tres int,
nansw_tres int,
tque_max int,
tque int,
txfer int,
tdialog int,
tnotes int,
tring int,
tresp int,
nMoh int,
nWHag int,
nWHcl int)

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [datetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

------ Time Agent In ----------
insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
SELECT cal_inicio as dateStartDetail
	,dateadd(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio) as dateEndDetail
	,dbo.GetTimeGroup(cal_inicio,0)	 as timegroup
	,dbo.GetTimeGroup(dateadd(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio),1)	 as timegroup_next	
	,DATEADD(ss,isnull(cal_twait,0),cal_inicio) as time_endque
	,DATEADD(ss,isnull(cal_twait + cal_txfer,0),cal_inicio) as time_ring
	,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
	,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
	,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio) as time_end_call
	,isnull(cal_Ani,0) as phone_in,cal_id,cin.dni_id,Inbound_id,[User_id]
	,1 AS ntotal
	,ISNULL(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END,0) AS ninitial
	,ISNULL(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END,0) AS nout_hour
	,ISNULL(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END,0) AS nout_service
	,ISNULL(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = '1900-01-01 00:00:00'))THEN 1 ELSE NULL END,0) AS nabnd
	,ISNULL(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END,0) AS nno_agent
	,ISNULL(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END,0) AS nque
	,ISNULL(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END,0) AS ntimeout
	,ISNULL(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END,0) AS noverflow
	,ISNULL(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END,0) AS nxfer
	,ISNULL(CASE WHEN(cal_que>0 and statuscall_id in(11,15,13,16) ) OR (statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00')	THEN 1 ELSE NULL END,0) AS nxfer_que
	,ISNULL(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END,0) AS nabnd_xfer
	,ISNULL(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END,0) AS nabnd_ring
	,ISNULL(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END,0) AS nno_answer
	,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END,0) AS nabnd_dialog
	,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END,0) AS nanswer
	,ISNULL(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END,0) AS nlost
	,ISNULL(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END,0) AS nmsg
	,ISNULL(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = '1900-01-01 00:00:00')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END,0) AS nabnd_tres
	,ISNULL(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END,0) AS nansw_tres
	,ISNULL(cal_twait,0)AS tque_max,ISNULL(cal_twait,0)AS tque,ISNULL(cal_txfer,0)AS txfer
	,ISNULL(cal_tdialog,0)AS tdialog,ISNULL(cal_tnotas,0)AS tnotes,ISNULL(cal_tring,0)AS tring
	,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END,0)AS tresp
	,ISNULL(case when cal_tMoh>0 then 1 else 0 end,0)as nMoh
	,ISNULL(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END,0)as nWHag,ISNULL(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END,0)as nWHcl
	FROM ccCallsIn cin with (nolock)
	left join ccdnis dnis on dnis.dni_id = cin.dni_id
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0	

delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0

select * into #callsin2 from #callsin where datediff(mi,timegroup,timegroup_next)>15

delete #callsin where datediff(mi,timegroup,timegroup_next) > 15

insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_in,cal_id,t.dni_id,Inbound_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,time_endque) as tque
	,dbo.TimeInterval(th.start ,th.stop, time_endque,time_ring) as txfer
	,dbo.TimeInterval(th.start ,th.stop, time_dialog,time_notes) as tdialog
	,dbo.TimeInterval(th.start ,th.stop, time_notes,time_end_call) as tnotes
	,dbo.TimeInterval(th.start ,th.stop, time_ring,time_dialog) as tring
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	from #callsin2 t
	join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	left join ccdnis dnis on dnis.dni_id = t.dni_id
	where  datediff(ss,th.start,timegroup_next)>0
	and th.start between @from and @to
	order by cal_id

------------ Session Time Start ----------------


------ Time Agent Common ----------

select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) AS timegroup,
dbo.GetTimeGroup(fecha,1) as timegroup_next
		,[User_id]
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
		,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
		into #timeDetailAgent
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	GROUP BY
	dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0),	
	dbo.GetTimeGroup(fecha,1), [User_id]	
		
select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
select
	dateStartDetail, dateEndDetail,th.start as timegroup,th.stop as timegroup_next, [User_id]
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tunknown,dateStartDetail)) as tunknown
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tnot_av,dateStartDetail)) as tnot_av
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tav,dateStartDetail)) as tav2	
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tprob,dateStartDetail)) as tprob
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tother,dateStartDetail)) as tother2	
	,isnull(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end,0) as nother
from #timeDetailAgent2 t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0
and th.start between @from and @to

;
with sessionTimeGroup as (

select session.timegroup, session.user_id
,isnull(sum(session.tlog),0) as tlog
from TmpSessionTimeGroup as session 
where login between @from and @to
group by session.timegroup,session.user_id
),
callin as (
select 
callin.timegroup,callin.user_id
,isnull(sum(callin.txfer),0) txfer,isnull(sum(callin.tdialog),0) tdialog,isnull(sum(callin.tnotes),0) tnotes
,isnull(sum(callin.tring),0) tring,isnull(sum(callin.nMoh),0) nMoh,isnull(sum(callin.nWHag),0) nWHag,isnull(sum(callin.nWHcl),0) nWHcl
from #callsin callin
group by callin.timegroup,callin.user_id
), timeAgent as(
select timeAgent.timegroup,timeAgent.user_id,isnull(sum(timeAgent.tnot_av),0) as tnot_av,isnull(sum(timeAgent.tav),0) tav
,isnull(sum(timeAgent.tprob),0) tprob, isnull(sum(timeAgent.tother),0) tother,isnull(sum(timeAgent.tunknown),0) tunknown
,isnull(sum(timeAgent.nother),0) nother
from #timeDetailAgent timeAgent
group by timeAgent.timegroup,timeAgent.user_id
)

select ROW_NUMBER() OVER(ORDER BY session.timegroup,session.[user_id] ) AS Row,
session.timegroup, session.user_id
,isnull(timeAgent.tnot_av,0) as tnot_av,isnull(timeAgent.tav,0) tav,isnull(timeAgent.tprob,0) tprob
,isnull(timeAgent.tother,0) tother,isnull(timeAgent.tunknown,0) tunknown,isnull(timeAgent.nother,0) nother
,isnull(callin.txfer,0) txfer,isnull(callin.tdialog,0) tdialog,isnull(callin.tnotes,0) tnotes
,isnull(callin.tring,0) tring,isnull(callin.nMoh,0) nMoh,isnull(callin.nWHag,0) nWHag,isnull(callin.nWHcl,0) nWHcl
,isnull(session.tlog,0) as tlog
into #agentInformation
from sessionTimeGroup as session 
left join timeAgent on timeAgent.User_id=session.user_id and timeAgent.timegroup=session.timegroup
left join callin on callin.User_id=session.user_id and session.timegroup=callin.timegroup
order by session.timegroup

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
select timegroup, B.inbound_id
, COUNT(DISTINCT B.[user_id]) AS pos_max -- pos_tot
	,SUM (tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog- (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
from #agentInformation X
INNER JOIN ccInboundAgentes B ON X.[user_id] = B.[user_id]
WHERE timegroup >= @from AND timegroup < @to  
group by timegroup, B.inbound_id

--Borrar lo que esta para no repetir
delete from [RepInCalls] where date >= @from AND date < @to

;
with callsin as(
select timegroup as tg
	,inbound_id as inboundId,	dni_id	
	,ntotal, nxfer, nabnd as nabnd_que, nxfer_que,
	(ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , tque_max,
	tque, NULLIF(nque, 0) nque , nanswer, nno_answer , nlost,
		(nabnd_xfer) nabnd_xfer , nabnd_ring, nabnd_dialog
		--,0 as pos_tot, 0 as pos_time --completar		
		, (nansw_tres + nabnd_tres) AS SL_P_1 ,
		(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2
		,ISNULL(tque/ NULLIF(nque, 0), 0) as [avg]
		--,ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL
		,nMoh,  nWHag	,nWHcl
		,DATEPART(yyyy,timegroup) as [year]
		,DATEPART(mm,timegroup) as [mounth]
		,DATEPART(dd,timegroup) as [day]
		,DATEPART(hh,timegroup) as [hour]
		,DATEPART(mi,timegroup) as [minute]
		,cal_id,phone_in	,dateStartDetail
		FROM #callsin		
),
wgByAcd as(
	select max(IDWG) as IDWG,Inbound_id,descripcion from ccWgByAcdView
	group by Inbound_id,descripcion
)

insert into [RepInCalls]
select tg as date,inboundId,ccInbound.descripcion as  inbound
,xDetail.dni_id,isnull(ccDnis.dni_Descripcion,'S/DNIS') as dnis
,wgByAcd.IDWG workgroupId,isnull(wgByAcd.descripcion,'') workgroup,ccInbound.IDArea areaID,D.AreaName area
,ntotal,nxfer,nabnd_que,nxfer_que,nno_xfer,tque_max,tque,isnull(nque,0) as nque,nanswer
,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
,spec.pos_tot pos_tot,spec.pos_tot pos_time
,SL_P_1,SL_P_2,avg,ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL
,nMoh,nWHag,nWHcl
,year,mounth,day,hour,minute,cal_id,phone_in,dateStartDetail,isnull(dni_numero,'') as DniNumber
 from callsin xDetail
 INNER JOIN ccInbound ON xDetail.inboundId = ccInbound.inbound_id
 LEFT JOIN ccDnis ON xDetail.dni_id = ccDnis.dni_id
 INNER join wgByAcd on wgByAcd.Inbound_id=ccinbound.Inbound_id
 INNER JOIN ccriacat_areas D ON D.IDArea = ccInbound.IDArea
 inner join #ccGenInSpec spec on spec.timegroup=xDetail.tg and spec.inbound_id=xDetail.inboundId
 --order by tg


IF OBJECT_ID('tempdb..#callsin') IS NOT NULL drop table #callsin
IF OBJECT_ID('tempdb..#callsin2') IS NOT NULL drop table #callsin2
IF OBJECT_ID('tempdb..#agentInformation') IS NOT NULL drop table #agentInformation
IF OBJECT_ID('tempdb..#ccGenInSpec') IS NOT NULL drop table #ccGenInSpec
IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL drop table #timeDetailAgent
IF OBJECT_ID('tempdb..#timeDetailAgent2') IS NOT NULL drop table #timeDetailAgent2
end