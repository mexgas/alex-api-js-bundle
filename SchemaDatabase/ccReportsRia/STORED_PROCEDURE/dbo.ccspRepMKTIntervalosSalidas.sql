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