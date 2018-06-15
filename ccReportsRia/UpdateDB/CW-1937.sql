/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Karen Rodríguez
Date: 2018/06/28
Description:
**********************************************************************************************
CW-1937 - Reporte MKT Mensual
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

	set @process = 'CW-1937 -- VERSION 52  DROP SP RepViewMKTMensual'
    set @Sql= 'IF EXISTS(select * FROM sys.views where name = ''RepViewMKTMensual'')
    BEGIN
        DROP VIEW RepViewMKTMensual;
    END'
    EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  CREATE VIEW RepViewMKTMensual'
    set @Sql= 'CREATE VIEW [dbo].RepViewMKTMensual AS
select 
	 convert(date, [date])
	 AS date
	,inboundId
	,Acds	
	,case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end as [avrAnswer]
	,case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end as [avgAbandonTime]
	,sum(acdCalls)  [acdCalls]
	,case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end as [tPromACD]
	,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
	,sum(abandonedCalls) as [abandonedCalls]
	,max(maxDelay) as [maxDelay]
	,sum(entryFlow) as  [entryFlow]	
	,sum(outFlow) as  [outFlow]
	,sum(callsOutExt) as [callsOutExt]	
	,isnull(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end,0) as [tPromSalidaExt]
	,sum(callsDeleteQue) as [callsDeleteQue]	
	,case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end as [tPromElimCola]
	,count(distinct accountUserId) accountUserId	
	,case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*86400))*count(distinct accountUserId))/100 else 0 end)>0 
		then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*86400))*count(distinct accountUserId))/100 else 0 end))*86400)))*100)>100 then 100 
			   else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*86400))*count(distinct accountUserId))/100 else 0 end))*86400)))*100) end)
		else 0 end [avrTimeACD]
	,isnull(case when (sum(acdCalls)+sum(abandonedCalls))>0 then convert(decimal(15,2),(convert(float,sum(acdCalls))*100)/(convert(float,sum(acdCalls))+convert(float,sum(abandonedCalls)))) else 0 end,0) [avrCallsAnswer]
	,sum(tresp) as tresp
	,sum(tabnd) as tabnd
	,sum(tacd) as tacd
	,sum(tacw) as tacw
	,sum(nacw) as nacw		
	,sum(tcalque) as tcalque			
	,sum(tprosalext) as tprosalext
	,sum(tlog) as tlog
	,DATEPART(YYYY, convert(date, [date])) as [year] 
	,DATEPART(mm, convert(date, [date])) as [month]
	,0 as [day]
	,0 as [hour]
	,0 as [minutes]
from RepMKTIntervalos
group by 	
	convert(date, [date])
	,inboundId, Acds'
	EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  INSERT Groups INTO GroupByReports'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[GroupByReports] WHERE [id] = 7150)
BEGIN
INSERT INTO GroupByReports values(7150, ''Acds|inboundId|case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end:avrAnswer|case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end:avgAbandonTime|
sum(acdCalls):acdCalls|case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end:tPromACD|case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end:tPromACW|sum(abandonedCalls):abandonedCalls|max(maxDelay):maxDelay|
sum(entryFlow):entryFlow|sum(outFlow):outFlow|sum(callsOutExt):callsOutExt|case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end:tPromSalidaExt|sum(callsDeleteQue):callsDeleteQue|
case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end:tPromElimCola|
case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*MAX(datediff(ss,CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + ''''-01'''', 121),CONVERT(smalldatetime, EOMONTH(date), 121)))))*count(distinct accountUserId))/100 else 0 end)>0 
		then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)
		*MAX(datediff(ss,CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + ''''-01'''', 121),CONVERT(smalldatetime, EOMONTH(date), 121)))))
		*count(distinct accountUserId))/100 else 0 end))*MAX(datediff(ss,CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + ''''-01'''', 121),CONVERT(smalldatetime, EOMONTH(date), 121))))))*100)>100 then 100 
			   else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)
			   *MAX(datediff(ss,CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + ''''-01'''', 121),CONVERT(smalldatetime, EOMONTH(date), 121)))))*
			   count(distinct accountUserId))/100 else 0 end))*MAX(datediff(ss,CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + ''''-01'''', 121),CONVERT(smalldatetime, EOMONTH(date), 121))))))*100) end)
		else 0 end:avrTimeACD|avg(avrCallsAnswer):avrCallsAnswer'',''Acds|inboundId'')
END'
	EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  INSERT DATE FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7150 AND [filterMenuName] = ''date'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7150, N''date'')
END'
	EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  INSERT filterby FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7150 AND [filterMenuName] = ''filterby'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7150, N''filterby'')
END'
	EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  INSERT acds FILTER INTO ReportsFilters'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFilters] WHERE [id] = 7150 AND [filterName] = ''acds'')
BEGIN
	INSERT INTO ReportsFilters 
	VALUES (''MKT Mensual'', ''acds'', 7150)
END'
	EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  INSERT Totals FILTER INTO ReportsTotals'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsTotals] WHERE [id] = 7150)
BEGIN
	INSERT INTO ReportsTotals values(7150, ''avg:avrAnswer|sum:acdCalls|avg:avgAbandonTime|avg:tPromACD|avg:tPromACW|sum:abandonedCalls|max:maxDelay|sum:entryFlow|sum:outFlow|sum:callsOutExt|avg:tPromSalidaExt|sum:callsDeleteQue|avg:tPromElimCola'')
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