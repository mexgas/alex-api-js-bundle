/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Karen Rodríguez
Date: 2018/03/28
Description:
**********************************************************************************************
CW-1825 - Reporte MKT Intervalos
**********************************************************************************************
Database: ccReportsRia
Required version: 51


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =52
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try


	set @process = 'CW-1825 -- VERSION 52  Drop SP ccspRepMKTIntervalos'
    set @Sql= 'IF EXISTS (select * from sys.procedures where name = N''ccspRepMKTIntervalos'')
    begin
        DROP PROCEDURE ccspRepMKTIntervalos;
    end'
    EXEC(@Sql)

	set @process = 'CW-1825 -- VERSION 52  CREATE TABLE RepMKTIntervalos'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''RepMKTIntervalos'')
BEGIN
	CREATE TABLE RepMKTIntervalos(
		[date] DATETIME  NOT NULL,
		[inboundId] INT NOT NULL,
		[Acds] VARCHAR(50) NOT NULL,
		[avrAnswer] INT NOT NULL,
		[avgAbandonTime] INT NOT NULL,
		[acdCalls] INT NOT NULL,
		[tPromACD] INT NOT NULL,
		[tPromACW] INT NOT NULL,
		[abandonedCalls] INT NOT NULL,
		[maxDelay] INT NOT NULL,
		[entryFlow] INT NOT NULL,
		[outFlow] INT NOT NULL,
		[callsOutExt] INT NOT NULL,
		[tPromSalidaExt] INT NOT NULL,
		[callsDeleteQue] INT NOT NULL,
		[tPromElimCola] INT NOT NULL,
		[avrTimeACD] decimal(15,2) NOT NULL,
		[avrCallsAnswer] decimal(15,2) NOT NULL,
		[PromPosicionPersonal] [numeric](18, 1) NULL,
		[LlamadasporPosicion] [int] NULL,
		[tresp] INT NOT NULL, 
		[tabnd] INT NOT NULL,
		[tacd] INT NOT NULL,
		[tacw] INT NOT NULL,
		[nacw] INT NOT NULL,
		[tcalque] INT NOT NULL,
		[tprosalext] INT NOT NULL,
		[tlog] INT NOT NULL,
		[accountUserId] INT NOT NULL,
		[year] int NOT NULL,
		[month] int NOT NULL,
		[day] int NOT NULL,
		[hour] int NOT NULL,
		[minutes] int NOT NULL,
	) 

END'
	EXEC(@Sql)


	set @process = 'CW-1825 -- VERSION 52  CREATE SP ccspRepMKTIntervalos'
    set @Sql= '
CREATE PROCEDURE [dbo].[ccspRepMKTIntervalos]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = convert(datetime,convert(varchar(11),getdate()))

if @action = 1
begin
	delete from [RepMKTIntervalos] with(rowlock) 
	where date >= @from AND date <= @to

	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
	CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)

	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,nacd int,tresp int,nabnd int,
	tAbnd int,tacd int,nacw int,tacw int,maxdem int,ncalque int,tcalque int,fent int,fsal int,SalExt int,tprosalext int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTWait] datetime,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int, ntotal int
	)

	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,nacd int,tresp int,nabnd int,
	tAbnd int,tacd int,nacw int,tacw int,maxdem int,ncalque int,tcalque int,fent int,fsal int,SalExt int,tprosalext int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTWait] datetime,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int, ntotal int
	)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=15
	
	INSERT INTO #sessionTime
	exec ccspGenSession @from, @to	

	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,dbo.GetTimeGroup([login],0) as timeGroup,dbo.GetTimeGroup(logout,1) as timeGroupNext,DATEDIFF(ss,[login],logout) as tlog, wg.IdCampEsp from #sessionTime st
		Inner Join ccriaworkgroupusers wgu ON st.User_id = wgu.User_id
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
	where wg.Tipo = 0 		

	INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
		
	insert into #sessionTimeGroup
	select [User_id],[login],logout, th.[start] as timegroup,th.[stop] as timegroup_next,
		[dbo].TimeInterval( th.[start],th.[stop] ,[login],logout) as [tlog seg],inb_id
	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0		

	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,Inbound_id as inboundId
		,case when i.statusCall_id=13 then 1 else 0 end as nacd,
		case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as tresp,
		case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd,
		case when (i.statuscall_id <> 13) then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end AS tAbnd
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else 0 end as nacw
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as maxdem
		,case when (i.statuscall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then 1 else 0 end as ncalque
		,case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then i.cal_tWait else 0 end as tcalque
		,CASE WHEN t.modo = 2 then 1 else 0 end as fent
		,CASE WHEN t.modo = 2 and t.tipo=1 then 1 else 0 end as fsal
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup
		,dateadd(ss,i.cal_twait,cal_Inicio) as [dateTWait]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,1 as ntotal
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to
	
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,inboundId,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as tresp,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		case when tAbnd=0 then 0 else [dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) end as tAbnd,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,maxdem) as maxdem,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ncalque) as ncalque,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,[dateTWait]) as tcalque,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,fent) as fent,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,fsal) as fsal,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 th.[start] as timegroup,th.[stop] as timegroup_next,
		[dateTWait] ,[dateTResp] ,[dateTACD] ,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ntotal) as ntotal
	from #inboundTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		
	
	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.tresp,0) as tresp,isnull(c.nacd,0) as nacd
		,isnull(c.tabnd,0) tabnd,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.maxdem,0) maxdem
		,isnull(c.fent,0)  fent, isnull(c.fsal,0) fsal,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext		
		,isnull(c.ncalque,0) ncalque,isnull(c.tcalque,0) tcalque
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(c.ntotal, 0) AS ntotal
	INTO #RepMKTIntervalosTemp 				
	 from (
		select [timegroup]
			,inboundId,userId	
			,sum(c.tresp) as tresp,sum(c.nacd) as nacd			
			,sum(c.tabnd) as tabnd
			,sum(c.nabnd) as nabnd
			,sum(c.tacd) as tacd
			,sum(c.tacw) as tacw
			,sum(c.nacw) as nacw			
			,max(c.maxdem) as maxdem			
			,sum(c.ncalque) as ncalque
			,sum(c.tcalque) as tcalque			
			,sum(fent) as fent
			,sum(fsal) as fsal
			,sum(SalExt) as SalExt
			,sum(tprosalext) as tprosalext
			,sum(ntotal) as ntotal	
		from #inbound as c 
		group by [timegroup],inboundId,userId) c		
		full join 
		(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
		on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId		
		
	INSERT INTO [RepMKTIntervalos]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,case when sum(nacd)>0 then sum(tresp)/sum(nacd) else 0 end as [avrAnswer]
		,case when sum(nabnd)>0 then sum(tabnd)/sum(nabnd) else 0 end as [AvgAbandonTime]
		,sum(nacd)  [acdCalls]
		,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
		,sum(nabnd) as [abondeonedCalls]
		,max(maxdem) as [maxDelay]
		,sum(fent) as  [entryFlow]	
		,sum(fsal) as  [outFLow]
		,sum(SalExt) as [calloutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
		,sum(ncalque) as [callDeleteQue]	
		,case when sum(ncalque)>0 then sum(tcalque)/sum(ncalque) else 0 end as [TpromElimCola]
		,case when round(case when count(distinct userId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1)>0 
		then (case when convert(decimal(15,2),((sum(nacd) * case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end) / convert(float,((round(case when (count(distinct userId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1))*1800)))*100)>100 then 100 
			   else convert(decimal(15,2),((sum(nacd) * case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end) / convert(float,((round(case when count(distinct userId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1))*1800)))*100) end)
		else 0 end [% Tiempo ACD]
		,isnull(case when (sum(nacd)+sum(nabnd))>0 then convert(decimal(15,2),(convert(float,sum(nacd))*100)/(convert(float,sum(nacd))+convert(float,sum(nabnd)))) else 0 end,0) [% Llamadas Resp]
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,case when sum(nacd) >0 then (case when sum(nacd)/count(distinct userId) >0 then convert(int, sum(nacd)/count(distinct userId)) else 1 end) else 0 end as [LlamadasporPosicion]
		,sum(tresp) as tresp
		,sum(tabnd) as tabnd
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw		
		,sum(tcalque) as tcalque			
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,isnull(userId,0) accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		from #RepMKTIntervalosTemp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		having sum(nacd)>0 or sum(nabnd)>0 or sum(tlog) >0	

	drop table #sessionTimeGroup;
	drop table #sessionTimeMayores;
	drop table #times;
	drop table #sessionTime;
	drop table #inbound
	drop table #inboundTimeMayores
	drop table #RepMKTIntervalosTemp
	
end'
	EXEC(@Sql)

	set @process = 'CW-1825 -- VERSION 52  INSERT DATE FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7140 AND [filterMenuName] = ''date'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7140, N''date'')
END'
	EXEC(@Sql)

	set @process = 'CW-1825 -- VERSION 52  INSERT filterby FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7140 AND [filterMenuName] = ''filterby'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7140, N''filterby'')
END'
	EXEC(@Sql)

	set @process = 'CW-1825 -- VERSION 52  INSERT filterby FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7140 AND [filterMenuName] = ''groupby'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7140, N''groupby'')
END'
	EXEC(@Sql)
	
	set @process = 'CW-1825 -- VERSION 52  INSERT acds FILTER INTO ReportsFilters'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFilters] WHERE [id] = 7140 AND [filterName] = ''acds'')
BEGIN
	INSERT INTO ReportsFilters 
	VALUES (''MKT Intervalos'', ''acds'', 7140)
END'
	EXEC(@Sql)

	set @process = 'CW-1825 -- VERSION 52  INSERT Totals FILTER INTO ReportsTotals'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsTotals] WHERE [id] = 7140)
BEGIN
	INSERT INTO ReportsTotals values(7140, ''special:avrAnswer:(case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end)|special:avgAbandonTime:(case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end)|sum:acdCalls|special:tPromACD:(case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end)|special:tPromACW:(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)|sum:abandonedCalls|max:maxDelay|sum:entryFlow|sum:outFlow|sum:callsOutExt|special:tPromSalidaExt:(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end)|sum:callsDeleteQue|special:tPromElimCola:(case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end)|special:avrTimeACD:(case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end)>0 then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100)>100 then 100         else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100) end)    else 0 end)|special:avrCallsAnswer:(isnull(case when (sum(acdCalls)+sum(abandonedCalls))>0 then convert(decimal(15,2),(convert(float,sum(acdCalls))*100)/(convert(float,sum(acdCalls))+convert(float,sum(abandonedCalls)))) else 0 end,0))|special:PromPosicionPersonal:(round(case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end,1))|special:LlamadasporPosicion:(case when sum(acdCalls) >0 then (case when sum(acdCalls)/count(distinct accountUserId) > 1 then sum(acdCalls)/count(distinct accountUserId) else 1 end) else 0 end)'')
END'
	EXEC(@Sql)

	set @process = 'CW-1825 -- VERSION 52  INSERT Groups INTO GroupByReports'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[GroupByReports] WHERE [id] = 7140)
BEGIN
	INSERT INTO GroupByReports values(7140, ''Acds|inboundId|case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end:avrAnswer|case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end:avgAbandonTime|
sum(acdCalls):acdCalls|case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end:tPromACD|case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end:tPromACW|sum(abandonedCalls):abandonedCalls|max(maxDelay):maxDelay|
sum(entryFlow):entryFlow|sum(outFlow):outFlow|sum(callsOutExt):callsOutExt|case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end:tPromSalidaExt|sum(callsDeleteQue):callsDeleteQue|
case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end:tPromElimCola|
case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end)>0 
		then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100)>100 then 100 
			   else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100) end)
		else 0 end:avrTimeACD|avg(avrCallsAnswer):avrCallsAnswer|
round(case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end,1):PromPosicionPersonal|
case when sum(acdCalls) >0 then (case when sum(acdCalls)/count(distinct accountUserId) > 1 then sum(acdCalls)/count(distinct accountUserId) else 1 end) else 0 end:LlamadasporPosicion'',''Acds|inboundId'')
END'
	EXEC(@Sql)

		 if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off