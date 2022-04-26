CREATE PROCEDURE [dbo].[ccspRepMKTIntervalos]
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
	
	IF OBJECT_ID('tempdb..#sessionTimeGroup')  IS NOT NULL  drop table #sessionTimeGroup
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

	IF OBJECT_ID('tempdb..#sessionTimeGroup')  IS NOT NULL  drop table #sessionTimeGroup	
	
end