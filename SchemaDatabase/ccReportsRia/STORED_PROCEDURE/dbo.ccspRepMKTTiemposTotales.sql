CREATE PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
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

	IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL drop table #sessionTimeGroup;			
		
	IF OBJECT_ID('tempdb..#IntervalosInbound') IS NOT NULL DROP TABLE #IntervalosInbound
	
	IF OBJECT_ID('tempdb..#HoldDisp') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID('tempdb..#groupLog') IS NOT NULL drop table #groupLog	

	IF OBJECT_ID('tempdb..#transferData') IS NOT NULL drop table #transferData		
	

	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,
	[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
			
	
	;with 
	 relationCallIdCamId as(
		select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
	),
	transferData as(
		select B.userId,B.InboundId
		,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4)  then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext			
		,timegroup		
		from TmpTimesccLogtransfers T
		inner join relationCallIdCamId B on t.callId=B.callId	
		where tipo=1
	), transferDataGroup as(

	select userId, timegroup, InboundId 
	,sum(SalExt) SalExt,sum(tprosalext) tprosalext
	from transferData
	group by timegroup, InboundId,userId
	)
	

	select * into #transferData from transferDataGroup

	;with relationWg as(
		select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
		where wg.Tipo = 0
	)

	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,timegroup,timegroup_next timeGroupNext,tlog, wgu.IdCampEsp from TmpSessionTimeGroup st
		Inner Join relationWg wgu ON st.User_id = wgu.User_id

	
	select userId as user_id,camId as IdCampEsp,TipoStatusAge_id,
	sum(tstatus) as tstatus,
	sum(CASE WHEN timeGroup > dateIni AND timeGroupNext > dateEnd THEN 1 ELSE 0 END) AS nstatusfra,
	timeGroup
	INTO #groupLog
	from tmpccLogAgentesDia
	where TipoStatusAge_id=3 
	GROUP BY userId,camId,TipoStatusAge_id,timegroup
	order by userId,timegroup,camId
		   	 	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	;with inCount as(
		select i.timegroup,Inbound_id as inboundId,User_id userId 
		,sum(CASE WHEN i.timeGroup > dateStartDetail AND i.timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nacd			
				,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nabnd
				,sum(tdialog) as tacd
				,sum(tnotes) as tacw
				,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tnotes>0 THEN 1 ELSE 0 END) as nacw			
				,sum(SalExt) as SalExt
				,sum(tprosalext) as tprosalext
				,sum(ntotal) as ncalls	
				,SUM(tring) as tring
				,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tring>0 THEN 1 ELSE 0 END) as nring
				,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13   THEN nMoh ELSE 0 END) as nhold
		from tmpTimesInboundData i
		left join #transferData  t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId
					group by i.timegroup,Inbound_id,User_id 
	)

	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.nacd,0) as nacd
		,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(c.ncalls, 0) AS ncalls		
		,isnull(c.tring, 0) AS tring
		,isnull(c.nring, 0) AS nring
		,isnull(c.nhold, 0) AS nhold
	 INTO #IntervalosInbound
	 from (
			select * from  inCount where inboundId > 0		
		) c		
	full join 
	(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
	on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId

	
	select i.*
	,isnull(case when lo.TipoStatusAge_id=3 then isnull(lo.tStatus,0) end,0) tdispo
	,isnull(case when lo.TipoStatusAge_id=3 then lo.nstatusfra end,0) ndispo
	,isnull(h.tiempohold, 0) AS thold
	INTO #HoldDisp
	from #IntervalosInbound i
	left JOIN #groupLog lo on i.date = lo.timegroup and i.inboundId = lo.IdCampEsp and i.userId = lo.user_id
	left JOIN tmpTimesHoldIn h on h.inbound_id = i.inboundId and i.date = h.timegroup and i.userId = h.userId	

	delete from [RepMKTTiemposTotales]	where date >= @from AND date <= @to

	INSERT INTO [RepMKTTiemposTotales]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,sum(ncalls) [Recibidas]
		,sum(nacd) [Atendidas]
		,sum(nabnd) [Abandonadas]
		,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
		,case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end as [tPromRetention]
		,sum(SalExt) as [callsOutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
		,case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end as [TPromDispon]
		,case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end [TPromRing]
		,sum(((case when nacd>0 then tacd/nacd else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))) [AHT1]
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw				
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,sum(nhold) as nhold
		,sum(thold) as thold
		,sum(tdispo) as tdispo
		,sum(ndispo) as ndispo
		,sum(tring) as tring
		,sum(nring) as nring
		,userId as accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		from #HoldDisp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		order by date		

	IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL drop table #sessionTimeGroup;					
	IF OBJECT_ID('tempdb..#IntervalosInbound') IS NOT NULL DROP TABLE #IntervalosInbound
	
	IF OBJECT_ID('tempdb..#HoldDisp') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID('tempdb..#groupLog') IS NOT NULL drop table #groupLog	

	IF OBJECT_ID('tempdb..#transferData') IS NOT NULL drop table #transferData		

END