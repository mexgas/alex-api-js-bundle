/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Angel Trejo
		Karen Rodríguez
Date: 2018/05/15
Description:
**********************************************************************************************
CW-1730 - Reporte MKT Agentes
CW-1825 - Reporte MKT Intervalos
CW-1937 - Reporte MKT Mensual
CW-1736 - MKT Reportes
**********************************************************************************************
Database: ccReportsRia
Required version: 52


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =53
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	
	set @process = 'CW-1730 -- DROP PROCEDURE ccspRepMKTAgentes'
    	set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepMKTAgentes'')
    begin
        DROP PROCEDURE ccspRepMKTAgentes;
    end
'
	EXEC(@sql)

set @process = 'CW-1730 -- DROP FUNCTION TimeInterval'
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''TimeInterval'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        DROP FUNCTION TimeInterval
    end
'
	EXEC(@sql)

set @process = 'CW-1730 -- DROP FUNCTION AccountInterval'
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''AccountInterval'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        DROP FUNCTION AccountInterval
    end
'
	EXEC(@sql)

set @process = 'CW-1730 -- DROP FUNCTION GetTimeGroup'
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''GetTimeGroup'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        DROP FUNCTION GetTimeGroup
    end
'
	EXEC(@sql)

	set @process = 'CW-1730 -- CREATE FUNCTION TimeInterval'
    	set @Sql= 'create FUNCTION [dbo].TimeInterval (@start datetime,@stop datetime,@state1 datetime,@state2 datetime)  
RETURNS int
AS  
BEGIN 
	declare @time int
	
	set @time= 
	case when @start <= @state1 and  @stop > @state1 and @start<= @state2 and  @stop > @state2 then datediff(ss,@state1,@state2)
	 when @start<= @state1 and  @stop > @state1 and @stop < @state2 then datediff(ss,@state1,@stop)
	 when @start> @state1 and @start<= @state2 and  @stop > @state2 then datediff(ss,@start,@state2)
	 when @start> @state1 and @stop < @state2 then datediff(ss,@start,@stop) else  0 end

	RETURN (@time)
END
'
	EXEC(@sql)

		set @process = 'CW-1730 -- CREATE FUNCTION AccountInterval'
    	set @Sql= 'create FUNCTION [dbo].[AccountInterval] (@start datetime,@stop datetime,@state1 datetime,@state2 datetime,@ntotal int)  
RETURNS int
AS  
BEGIN 
	declare @total int
	
	set @total= 
	case when @start<= @state1 and  @stop > @state1 and @stop < @state2 then @ntotal 
	else 0 end

	RETURN (@total)
END

'
	EXEC(@sql)

	set @process = 'CW-1730 -- CREATE FUNCTION GetTimeGroup'
    	set @Sql= 'CREATE FUNCTION [dbo].[GetTimeGroup] ( @date datetime,@isTimeGroupNext bit)  
RETURNS datetime
AS  
BEGIN 
	declare @timeGroup datetime
		select @timeGroup =case when datepart(mi,@date) between 0 and 14 then convert(varchar(13),@date,121) + '':00:00.000''
	when datepart(mi,@date) between 15 and 29 then convert(varchar(13),@date,121) + '':15:00.000'' 
	when datepart(mi,@date) between 30 and 44 then convert(varchar(13),@date,121) + '':30:00.000'' 
	else convert(varchar(13),@date,121) + '':45:00.000''  end

	if @isTimeGroupNext=1 begin
		set @timeGroup=DATEADD(mi,15,@timeGroup)
	end

	RETURN (@timeGroup)
END	
'
	EXEC(@sql)

	set @process = 'CW-1730 -- Add Column to RepMKTAgentes '
    	set @Sql= 'if not exists (select * from sys.columns where name = N''TiempoPromACD'' and Object_ID = Object_ID(N''RepMKTAgentes''))
    begin
        alter table RepMKTAgentes add TiempoPromACD int null
    end
'
	EXEC(@sql)

	set @process = 'CW-1730 -- Add Column to RepMKTAgentes'
    	set @Sql= 'if not exists (select * from sys.columns where name = N''TiempoPromACW'' and Object_ID = Object_ID(N''RepMKTAgentes''))
    begin
        alter table RepMKTAgentes add TiempoPromACW int null
    end
'
	EXEC(@sql)

	set @process = 'CW-1730 -- CREATE PROCEDURE ccspRepMKTAgentes'
    	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepMKTAgentes]
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
	[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0) as timegroup,
	[dbo].[GetTimeGroup](
	dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )	
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
	   c.user_id>0--=36 -->0
	   and c.inbound_id>0 
	  -- and c.cal_id between 60 and 76
       group by c.user_id,cal_inicio
	   ,[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0)
	   ,[dbo].[GetTimeGroup](
		dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )	
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

	cast((case when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':00:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 45 and 59 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':45:00.000'' end) as datetime)  as timegroup,
	cast((case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
	     when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
		 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
		 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as datetime) as timegroup_next,
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
(isnull(u.apellidopaterno,u.apellidopaterno)+'' ''+isnull(u.apellidomaterno,'''')+'' ''+isnull(u.nombres,'''')) agt_name,
CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes from cte a
inner join ccusers as u on a.user_id=u.user_id
order by date,Login

drop table #times
drop table #timeAgenteTransfer
drop table #timeAgenteTransfer2
drop table #timeAgenteStatus
drop table #timeAgenteStatus2

end
'
	EXEC(@sql)


	set @process = 'CW-1730 -- insert into ReportsFilters'
    	set @Sql= 'delete from ReportsFilters where id=7120
insert into ReportsFilters (reportName,filterName,id)
values(''MKT Agents'',''users'',7120)
'
	EXEC(@sql)
	

	set @process = 'CW-1730 -- insert into ReportsFiltersMenus '
    	set @Sql= 'delete from ReportsFiltersMenus where idReport=7120
		insert into ReportsFiltersMenus values 
(7120,''groupby''),
(7120,''filterby''),
(7120,''date'')'
	EXEC(@sql)
	

	set @process = 'CW-1730 -- insert into GroupByReports '
    	set @Sql= 'delete from GroupByReports where id=7120
		insert into GroupByReports values(7120,''userId|max([login]):login|max([agentName]):agentName|sum([CallsperACDGroupD]):CallsperACDGroupD|case when sum([CallsperACDGroupD])>0 then sum([tACD])/sum([CallsperACDGroupD]) else 0 end:TiempoPromACD|case when sum([nacw])>0 then sum([tacw])/sum([nacw]) else 0 end:TiempoPromACW|sum([tACD]):tACD|sum([tACW]):tACW|sum([tAgent]):TiempoLlamadoAgente|sum([oHour]):oHour|sum([tAux]):tAux|sum([readyTime]):readyTime|sum([tPer]):tPer|sum([Ayuda]):Ayuda|sum([nxfer]):nxfer'',''userId'')'
	EXEC(@sql)
	

	set @process = 'CW-1730 -- insert into ReportsTotals '
    	set @Sql= 'delete from ReportsTotals where id = 7120
insert into ReportsTotals values (7120,''special:CallsperACDGroupD:sum(CallsperACDGroupD)|
special:TiempoPromACD:case when sum([CallsperACDGroupD])>0 then sum([tACD])/sum([CallsperACDGroupD]) else 0 end|
special:TiempoPromACW:case when sum([nacw])>0 then sum([tacw])/sum([nacw]) else 0 end|
sum:tACD|special:tACW:sum(tACW)|special:TiempoLlamadoAgente:sum(tAgent)|sum:oHour|sum:tAux|sum:readyTime|sum:tPer|sum:Ayuda|sum:nxfer'')
'
	EXEC(@sql)
	
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
select @to = getdate()

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
	INSERT INTO ReportsTotals values(7150, ''special:avrAnswer:(case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end)|special:avgAbandonTime:(case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end)|sum:acdCalls|special:tPromACD:(case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end)|special:tPromACW:(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)|sum:abandonedCalls|max:maxDelay|sum:entryFlow|sum:outFlow|sum:callsOutExt|special:tPromSalidaExt:(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end)|sum:callsDeleteQue|special:tPromElimCola:(case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end)|special:avrTimeACD:(case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end)>0 then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100)>100 then 100         else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100) end)    else 0 end)|special:avrCallsAnswer:(isnull(case when (sum(acdCalls)+sum(abandonedCalls))>0 then convert(decimal(15,2),(convert(float,sum(acdCalls))*100)/(convert(float,sum(acdCalls))+convert(float,sum(abandonedCalls)))) else 0 end,0))'')
END'
	EXEC(@Sql)

set @process = 'CW-1866 '
    	set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepMKTIntervalosTiemposAcuTotales'')
    begin
        DROP PROCEDURE ccspRepMKTIntervalosTiemposAcuTotales;
    end'
	EXEC(@sql)

	set @process = 'CW-1866 '
    	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = convert(datetime,convert(varchar(11),getdate()))

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin
delete from [RepMKTIntervalosTiemposAcuTotales] with(rowlock) 
	where date >= @from AND date <= @to 

	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
	CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #hold ([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,call_id int not null,inbound_id int not null,  marca int not null, Tipo_marca int not null,
					Tipo_llamada int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL, [time_dialog] [datetime] not null,[time_notes] [datetime] not null
					,[time_hold] [datetime] not null)
	CREATE TABLE #tempccHoldSession([fila] int NOT NULL,[call_id] [smallint] NOT NULL,[inbound_id] [int] NOT NULL,[hold] [datetime] NOT NULL,[unhold] [datetime] NULL,[Tipo_marca] [int] not null
				,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL primary key (fila,call_id)			)
	CREATE TABLE #holdMayores2 (call_id int not null, inbound_id int not null,  hold [datetime] not null , [unhold] [datetime] not null,Tipo_marca int not null,tiempoHold int not null,
					[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,nabnd int,
				tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int, thold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int
				)
	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,
				nabnd int,tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int,  thold int, [timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int
				)
	create table #tempccLogAgentesDia(row int not null,user_id int not null,[IdCampEsp] [int] not null,[callId] [int]not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	create table #timeDetailAgent([User_id] int null,[IdCampEsp][int] not null,[callId][int] not null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tlogout int,tcliente int ,tchatting int null,[PromPosicionPersonal] [numeric](18, 1) NULL,)
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)


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
	INSERT into #sessionTimeMayores 
	SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
		
	insert into #sessionTimeGroup
	select [User_id],[login],logout, th.[start] as timegroup,th.[stop] as timegroup_next,
		[dbo].TimeInterval( th.[start],th.[stop] ,[login],logout) as [tlog seg],inb_id
	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0		

-------------------HOLD PROCESS-------------------
insert into #hold
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,cal_id as cal_id,
		inbound_id as inbound_id,
		isnull(h.marca,0) as Marca,
		case when (h.tipo_marca>0) then h.tipo_marca else 0 end as Tipo_marca,
		isnull(tipo_llamada,0) as Tipo_llamada
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup_next
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + marca,0),cal_Inicio) as time_hold
		
	from cccallsin i (nolock) 
	left join RiaMarkHold h (nolock) on i.cal_id=h.call_id and h.tipo_llamada=1
	where cal_Inicio between @from and @to 
select * from #hold
insert into #tempccHoldSession
select A.Fila, A.call_id
,a.inbound_id
,A.time_hold hold,
isnull(S.time_hold,a.time_notes) unhold,
a.Tipo_marca Tipo_marca
,a.timegroup timegroup
,a.timegroup_next timegroup_next
from (select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
from #hold a where time_hold >= @from and time_hold <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
from #hold a where time_hold >= @from	and time_hold <= @to
) S
on A.Fila=S.Fila-1 and A.call_id=S.call_id and A.tipo_marca=1 and S.tipo_marca=0
where A.tipo_llamada=1 
order by hold


select 
	ths.call_id,
	ths.inbound_id,
	ths.hold,
	ths.unhold,
	ths.Tipo_marca,
	[dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold) as tiempohold,
	ths.timegroup,
	ths.timegroup_next
	into #tiempoHold
 from #tempccHoldSession ths
 inner join #times th on (ths.timegroup > th.Start and ths.timegroup < th.stop) OR th.Start between ths.timegroup and ths.timegroup_next
 where [dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold)>0 and Tipo_marca=1
 INSERT into #holdMayores2 SELECT * from #tiempoHold where datediff(mi,timegroup,timegroup_next)>15 
	delete #tiempoHold where  datediff(mi,timegroup,timegroup_next)>15	

insert into #tiempoHold
	select DISTINCT  call_id,
		inbound_id,
		hold,
		unhold,
		Tipo_marca,
		[dbo].TimeInterval( th.[start],th.[stop],hold ,unhold) as tiempohold,
		th.[start] as timegroup,
		th.[stop] as timegroup_next
	from #holdMayores2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop ) OR th.Start between t.timegroup and t.timegroup_next
	where [dbo].TimeInterval( th.[start],th.[stop],hold ,unhold)>0 
select 
inbound_id,
sum(tiempohold) tiempohold,
timegroup,
timegroup_next
 into #timeHoldInterval from #tiempoHold where tiempoHold>0 and Tipo_marca=1
 group by inbound_id,timegroup,Tipo_marca,timegroup_next
 ---------------------FINAL HOLD PROCESS----------------------
---------------------oRows---------------------

insert into #tempccLogAgentesDia(row,[User_id],[IdCampEsp],[callId],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,IdCampEsp,callID,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id,a.IdCampEsp,a.callId
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
	inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,IdCampEsp,callId,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia

	insert into #timeDetailAgent
	select A.user_id,A.IdCampEsp,A.callId,A.dateIni,A.dateEnd
	,convert(datetime,case when datepart(mi,A.dateIni) between 0 and 14 then convert(varchar(13),A.dateIni,121) + '':00:00.000''
			when datepart(mi,A.dateIni) between 15 and 29 then convert(varchar(13),A.dateIni,121) + '':15:00.000''
			when datepart(mi,A.dateIni) between 30 and 44 then convert(varchar(13),A.dateIni,121) + '':30:00.000''
			when datepart(mi,A.dateIni) between 45 and 59 then convert(varchar(13),A.dateIni,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000''
			when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
			when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
			when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	,isnull(case when A.TipoStatusAge_id=0 then A.tStatus end,0) tlogout
	,isnull(case when A.TipoStatusAge_id=8 then A.tStatus end,0) tcliente	
	,case when A.tipostatusage_id in (23,24) then A.tStatus else 0 end  as tchatting
	,0.0 [PromPosicionPersonal]
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

insert into #timeDetailAgent(User_id,IdCampEsp,callId,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall,tunknown2,tlogout,tcliente,tchatting)
	 select
	 	User_id,
		IdCampEsp,
		callId,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail,
	 	case when datepart(mi,B.fecha) between 0 and 14 then convert(varchar(13),B.fecha,121) + '':00:00.000''
	 		when datepart(mi,B.fecha) between 15 and 29 then convert(varchar(13),B.fecha,121) + '':15:00.000''
	 		when datepart(mi,B.fecha) between 30 and 44 then convert(varchar(13),B.fecha,121) + '':30:00.000''
	 		when datepart(mi,B.fecha) between 45 and 59 then convert(varchar(13),B.fecha,121) + '':45:00.000'' end as timegroup
	 	,case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':15:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':30:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':45:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then  convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end as timegroup_next
	 	,case when currentStatus = 1 then tiempo else 0 end as tunknown,
	 	case when currentStatus = 2 then tiempo else 0 end as tnot_av,
	 	case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	 0,0,0,0,0 as tunknown2
		 ,0,0
		,case when currentStatus in (23,24) then tiempo else 0 end as tchatting
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
		where A.currentStatus not in(-2,-1,0)

select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,IdCampEsp,callId,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall,tunknown2,tlogout,tcliente,tchatting)

	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id],IdCampEsp,callId
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tlogout,dateStartDetail) and  th.stop > dateadd(ss,tlogout,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tlogout,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tlogout,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tlogout,dateStartDetail) and  th.stop > dateadd(ss,tlogout,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tlogout,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tlogout,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tlogout
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tcliente,dateStartDetail) and  th.stop > dateadd(ss,tcliente,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tcliente,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tcliente,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tcliente,dateStartDetail) and  th.stop > dateadd(ss,tcliente,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tcliente,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tcliente,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tcliente
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tchatting,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tchatting
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

  select 
		isnull(c.IdCampEsp,0) as IdCampEsp
		,C.timegroup
		,isnull(c.tunknown,0) as tunknown
		,isnull(c.tnot_av,0) as tnot_av
		,isnull(c.tav,0) as tav
		,isnull(c.tother,0) as tother
		,isnull(c.tprob,0) as tprob
		,isnull(c.tmanualCall,0) as tmanualCall
		,isnull(c.tlogout,0) as tlogout
		,isnull(c.tcliente,0) as tcliente
	INTO #timeDetailAgentFinal		
	 from (
		select IdCampEsp,
				timegroup,
				sum(tunknown) tunknown,
				sum(tnot_av) tnot_av,
				sum(tav) tav,
				sum(tother) tother,
				sum(tprob) tprob,
				sum(tmanualCall) tmanualCall,
				sum(tlogout) tlogout,
				sum(tcliente) tcliente
		from #timeDetailAgent as c 
		group by [timegroup],IdCampEsp) c
		left join #sessionTimeGroup s (nolock) on s.inb_id=c.IdCampEsp AND s.timegroup=C.timegroup
----------------------------------------------------------
	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,i.Inbound_id as inboundId
		,i.cal_id as cal_id
		,1 as [LlamadasRecibidas]
		,case when i.statusCall_id=13 then 1 else 0 end as nacd, --[LlamadasAtendidas]
		case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end as nacw
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statusCall_id=13 then i.cal_txfer else 0 end as txfer
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext
		,case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else 0 end nhold
		,case when i.statusCall_id=13 and (i.cal_twait+i.cal_txfer+i.cal_tring)<40 then 1 else null end as nserv
		,case when i.statusCall_id=13 and i.cal_tring>0 then 1 else 0 end as nring
		,case when i.statusCall_id=13 then i.cal_tring else 0 end as tring
		,case when i.statuscall_id = 13 then i.cal_tmoh else 0 end as thold
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer,cal_Inicio) as [dateTRing]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to

	select * from #inbound

				
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,
		inboundId
		,cal_id
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,[LlamadasRecibidas]) as[LlamadasRecibidas],
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as txfer,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nhold) as nhold,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nserv) as nserv,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nring) as nring,
		 [dbo].TimeInterval( th.[start],th.[stop] ,dateTRing,dateTResp) as tring,
		 thold,
		 th.[start] as timegroup,th.[stop] as timegroup_next
		,[dateTResp],[dateTRing] ,[dateTACD] 
		,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
	from #inboundTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	
	 select distinct case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(ci.descripcion,'''') as [descripcion]
		,isnull(c.ncalls,0) as ncalls--LlamadasRecibidas
		,isnull(c.nacd,0) as nacd	--atendidas
		,isnull(c.nabnd,0) as nabnd	--abandonadas
		,isnull(c.tacd,0) as tacd --TiempoACD
		,isnull(c.tacw,0) as tacw --TiempoACW
		,isnull(d.tlogout,0) as tlogout --TiempoLogout
		,isnull(c.nacw,0) as nacw --nACW
		,isnull(d.tunknown,0) as tunknown --TiempoDescon
		,isnull(d.tnot_av,0) as tnot_av --TiempoNoDispo
		,isnull(d.tav,0) as tav --TiempoDispo
		,isnull(c.txfer,0) as txfer --TiempoXfer
		,isnull(d.tother,0) as tother --TiempoOtra
		,isnull(d.tcliente,0) as tcliente --TiempoCliente
		,isnull(d.tprob,0) as tprob --TiempoProblema
		,isnull(d.tmanualCall,0) as tmanualCall --TiempoManual
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(hi.tiempohold,0) as tiempoHold
		,isnull(c.SalExt,0) as SalExt
		,isnull(c.tprosalext,0)  tprosalext	
		,isnull(c.nhold,0) nhold
		,isnull(thold,0) thold
		,isnull(c.nserv,0) nserv
		,isnull(c.nring,0) nring
		,isnull(c.tring,0) tring
	INTO #RepMKTIntervalosTiemposAcuTotalesTemp				
	 from (
		select [timegroup]
			,inboundId,userId	
			,sum(nacd) as nacd			
			,sum(nabnd) as nabnd
			,sum(tacd) as tacd
			,sum(tacw) as tacw
			,sum(nacw) as nacw
			,sum(LlamadasRecibidas) as ncalls
			,sum(txfer) as txfer
			,sum(SalExt) as SalExt
			,sum(tprosalext) as tprosalext
			,sum(nhold) as nhold
			,count(nserv) as nserv
			,sum(tring) as tring
			,sum(nring) as nring
			,sum(thold) as thold
		from #inbound as c 
		group by [timegroup],inboundId,userId) c
		full join 
		(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
		on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId
		LEFT JOIN #timeHoldInterval hi ON hi.inbound_id=C.inboundId AND hi.timegroup=C.timegroup
		left join ccinbound ci (nolock) on ci.Inbound_id=c.inboundId	
		left join #timeDetailAgentFinal d (nolock) on d.IdCampEsp=ci.Inbound_id AND d.timegroup=C.timegroup

	
insert INTO [RepMKTIntervalosTiemposAcuTotales]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as descripcion
	    ,round(case when count(distinct userId)>1 then ((convert(float,(sum([tlog])*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [PromPosicionPersonal]
		,sum(ncalls) LlamadasRecibidas
		,sum(nacd)  LlamadasAtendidas
		,sum(nabnd)  LlamadasAban
		,sum(tacd) as TiempoACD --tACD
		,sum(tacw) as TiempoACW --tACW
		,sum(tlogout) as TiempoLogout --tLogout
		,sum(tunknown) as TiempoDescon --tDescon
		,sum(tnot_av) as TiempoNoDispo --tnotav
		,sum(tav) as TiempoDispo
		,sum(txfer) as TiempoXfer  --txfer
		,sum(tother) as TiempoOtra --tother
		,sum(tcliente) as TiempoCliente --tCliente
		,sum(tring) as TiempoRing --tring
		,sum(tprob) as TiempoProblema --tprob
		,sum(tmanualCall) as TiempoManual --tManual
		,sum(tiempoHold) as TiempoReten --[timeretention]
		,sum(SalExt) as LlamadasSalidaExt
		,case when sum(SalExt)>0 then sum(tprosalext) else 0 end as [TiempoSalidaExt]
		,case when sum(ncalls)>0 then (sum(nserv) * 100) / sum(ncalls) else 0 end [PorcNiveldeServicio4080]
		,((case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end)+(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)+(case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end)+(case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end)) [AHT]
		,sum(nhold) as LlamadasRetenidas
		,sum(nring) as LlamadasenRing
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		,sum(nserv) as nserv
		from #RepMKTIntervalosTiemposAcuTotalesTemp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId,  inb.descripcion
		having sum(nacd)>0 or sum(nabnd)>0 or sum(tlog) >0	

	drop table #sessionTimeGroup;
	drop table #sessionTimeMayores;
	drop table #times;
	drop table #sessionTime;
	drop table #inbound
	drop table #inboundTimeMayores
	drop table #RepMKTIntervalosTiemposAcuTotalesTemp 
	drop table #hold
	drop table #tempccHoldSession
	drop table #holdMayores2
	drop table #tiempoHold
	drop table #timeHoldInterval
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #tempAgentLastStatus
	drop table #timeDetailAgentFinal

end'
	EXEC(@sql)

	set @process = 'CW-1866 CREATE TABLE RepMKTIntervalosTiemposAcuTotales'
    	set @Sql= 'if not exists (select * from sys.tables where name = N''RepMKTIntervalosTiemposAcuTotales'')
    begin
        CREATE TABLE [dbo].[RepMKTIntervalosTiemposAcuTotales](
	[date] [datetime] NOT NULL,
	[inboundId] [varchar](5) NULL,
	[descripcion] [varchar](50) NULL,
	[PromPosicionPersonal] [numeric](18, 1) NULL,
	[LlamadasRecibidas] [int] NULL,
	[LlamadasAtendidas] [int] NULL,
	[LlamadasAban] [int] NULL,
	[tACD] [int] NULL,
	[tACW] [int] NULL,
	[tLogout] [int] NULL,
	[tDescon] [int] NULL,
	[tnotav] [int] NULL,
	[TiempoDispo] [int] NULL,
	[txfer] [int] NULL,
	[tother] [int] NULL,
	[tCliente] [int] NULL,
	[tring] [int] NULL,
	[tprob] [int] NULL,
	[tManual] [int] NULL,
	[timeretention] [int] NULL,
	[LlamadasSalidaExt] [int] NULL,
	[TiempoSalidaExt] [int] NULL,
	[PorcNiveldeServicio4080] [int] NULL,
	[AHT] [int] NULL,
	[LlamadasRetenidas] [int] NULL,
	[LlamadasenRing] [int] NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL,
	[nserv] [int] null,
	[nacw] [int] null,
) ON [PRIMARY]
    end'
	EXEC(@sql)
	
	set @process = 'CW-1866 insert into ReportsFilters'
    	set @Sql= 'delete from ReportsFilters where id=7160
		insert into ReportsFilters (reportName,filterName,id)
values(''Summary of Total Accumulated Time Intervals'',''acds'',7160)
'
	EXEC(@sql)

	set @process = 'CW-1866 insert into ReportsFiltersMenus'
    	set @Sql= 'delete from ReportsFiltersMenus where idReport=7160
		insert into ReportsFiltersMenus values 
(7160,''groupby''),
(7160,''filterby''),
(7160,''date'')'
	EXEC(@sql)

	set @process = 'CW-1866 insert into GroupByReports'
    	set @Sql= 'delete from GroupByReports where id=7160
insert into GroupByReports values(7160,''InboundId|max([descripcion]):descripcion|sum([PromPosicionPersonal]):PromPosicionPersonal|sum([LlamadasRecibidas]):LlamadasRecibidas|sum([LlamadasAtendidas]):LlamadasAtendidas|sum([LlamadasAban]):LlamadasAban|sum([tacd]):tACD|sum([tACW]):tACW|sum([tLogout]):tLogout|sum([tDescon]):tDescon|sum([tnotav]):tnotav|sum([TiempoDispo]):TiempoDispo|sum([txfer]):txfer|sum([tother]):tother|sum([tCliente]):tCliente|sum([tring]):tring|sum([tprob]):tprob|sum([tManual]):tManual|sum([timeretention]):timeretention|sum([LlamadasSalidaExt]):LlamadasSalidaExt|sum([TiempoSalidaExt]):TiempoSalidaExt|case when sum(LlamadasRecibidas)>0 then (sum(nserv) * 100) / sum(LlamadasRecibidas) else 0 end:PorcNiveldeServicio4080|((case when sum(LlamadasAtendidas)>0 then sum(tACD)/sum(LlamadasAtendidas) else 0 end)+(case when sum(nacw)>0 then sum(tACW)/sum(nacw) else 0 end)+(case when sum(LlamadasenRing)>0 then sum(tring)/sum(LlamadasenRing) else 0 end)+(case when sum(LlamadasRetenidas)>0 then sum([timeretention])/sum(LlamadasRetenidas) else 0 end)):AHT|sum([LlamadasRetenidas]):LlamadasRetenidas|sum([LlamadasenRing]):LlamadasenRing'',''InboundId'')
'
	EXEC(@sql)

	set @process = 'CW-1866 insert into ReportsTotals'
    	set @Sql= 'delete from ReportsTotals where id = 7160
insert into ReportsTotals values (7160,''special:PromPosicionPersonal:sum(PromPosicionPersonal)|special:LlamadasRecibidas:sum(LlamadasRecibidas)|special:LlamadasAtendidas:sum(LlamadasAtendidas)|special:LlamadasAban:sum(LlamadasAban)|special:tACD:sum(tACD)|special:tACW:sum(tACW)|special:tLogout:sum(tLogout)|special:tDescon:sum(tDescon)|special:tnotav:sum(tnotav)|special:TiempoDispo:sum(TiempoDispo)|special:txfer:sum(txfer)|special:tother:sum(tother)|special:tCliente:sum(tCliente)|special:tring:sum(tring)|special:tprob:sum(tprob)|special:tManual:sum(tManual)|special:timeretention:sum(timeretention)|special:LlamadasSalidaExt:sum(LlamadasSalidaExt)|special:TiempoSalidaExt:sum(TiempoSalidaExt)|special:PorcNiveldeServicio4080:case when sum(LlamadasRecibidas)>0 then (sum(nserv) * 100) / sum(LlamadasRecibidas) else 0 end|special:AHT:((case when sum(LlamadasAtendidas)>0 then sum(tACD)/sum(LlamadasAtendidas) else 0 end)+(case when sum(nacw)>0 then sum(tACW)/sum(nacw) else 0 end)+(case when sum(LlamadasenRing)>0 then sum(tring)/sum(LlamadasenRing) else 0 end)+(case when sum(LlamadasRetenidas)>0 then sum([timeretention])/sum(LlamadasRetenidas) else 0 end))|special:LlamadasRetenidas:sum(LlamadasRetenidas)|special:LlamadasenRing:sum(LlamadasenRing)'')
'
	EXEC(@sql)

	set @process = 'CW-1736 -- VERSION 52  DROP SP RepViewMKTDiario'
    set @Sql= 'IF EXISTS(select * FROM sys.views where name = ''RepViewMKTDiario'')
    BEGIN
        DROP VIEW RepViewMKTDiario;
    END'
    EXEC(@Sql)

	set @process = 'CW-1736 -- VERSION 52  CREATE VIEW RepViewMKTDiario'
    set @Sql= 'CREATE VIEW [dbo].RepViewMKTDiario AS
select 
	convert(date, [date]) as[date]		
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
	,sum(tresp) as tresp2
	,sum(tabnd) as tabnd
	,sum(tacd) as tacd
	,sum(tacw) as tacw
	,sum(nacw) as nacw		
	,sum(tcalque) as tcalque			
	,sum(tprosalext) as tprosalext
	,sum(tlog) as tlog
	,DATEPART(YYYY, convert(date, [date])) as [year] 
	,DATEPART(mm, convert(date, [date])) as [month]
	,DATEPART(dd, convert(date, [date])) as [day]
	,0 as [hour]
	,0 as [minutes]
	from RepMKTIntervalos
	group by convert(date, [date]),inboundId, Acds'
	EXEC(@Sql)

	set @process = 'CW-1937 -- VERSION 52  INSERT Groups INTO GroupByReports'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[GroupByReports] WHERE [id] = 7130)
BEGIN
INSERT INTO GroupByReports values(7130, ''Acds|inboundId|case when sum(acdCalls)>0 then sum(tresp2)/sum(acdCalls) else 0 end:avrAnswer|case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end:avgAbandonTime|  sum(acdCalls):acdCalls|case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end:tPromACD|case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end:tPromACW|sum(abandonedCalls):abandonedCalls|max(maxDelay):maxDelay|  sum(entryFlow):entryFlow|sum(outFlow):outFlow|sum(callsOutExt):callsOutExt|case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end:tPromSalidaExt|sum(callsDeleteQue):callsDeleteQue|  case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end:tPromElimCola|  case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*86400))*count(distinct accountUserId))/100 else 0 end)>0     then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*86400))*count(distinct accountUserId))/100 else 0 end))*86400)))*100)>100 then 100         else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*86400))*count(distinct accountUserId))/100 else 0 end))*86400)))*100) end)    else 0 end:avrTimeACD|avg(avrCallsAnswer):avrCallsAnswer'',''Acds|inboundId'')
END'
	EXEC(@Sql)

	set @process = 'CW-1736 -- VERSION 52  INSERT DATE FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7130 AND [filterMenuName] = ''date'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7130, N''date'')
END'
	EXEC(@Sql)

	set @process = 'CW-1736 -- VERSION 52  INSERT filterby FILTER INTO ReportsFiltersMenus'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFiltersMenus] WHERE [idReport] = 7130 AND [filterMenuName] = ''filterby'')
BEGIN
	INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName])
	VALUES (7130, N''filterby'')
END'
	EXEC(@Sql)

	set @process = 'CW-1736 -- VERSION 52  INSERT acds FILTER INTO ReportsFilters'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsFilters] WHERE [id] = 7130 AND [filterName] = ''acds'')
BEGIN
	INSERT INTO ReportsFilters 
	VALUES (''MKT Tiempos'', ''acds'', 7130)
END'
	EXEC(@Sql)

	set @process = 'CW-1736 -- VERSION 52  INSERT Totals FILTER INTO ReportsTotals'
    set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ReportsTotals] WHERE [id] = 7130)
BEGIN
	INSERT INTO ReportsTotals values(7130, ''special:avrAnswer:(case when sum(acdCalls)>0 then sum(tresp2)/sum(acdCalls) else 0 end)|special:avgAbandonTime:(case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end)|sum:acdCalls|special:tPromACD:(case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end)|special:tPromACW:(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)|sum:abandonedCalls|max:maxDelay|sum:entryFlow|sum:outFlow|sum:callsOutExt|special:tPromSalidaExt:(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end)|sum:callsDeleteQue|special:tPromElimCola:(case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end)|special:avrTimeACD:(case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end)>0 then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100)>100 then 100         else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100) end)    else 0 end)|special:avrCallsAnswer:(isnull(case when (sum(acdCalls)+sum(abandonedCalls))>0 then convert(decimal(15,2),(convert(float,sum(acdCalls))*100)/(convert(float,sum(acdCalls))+convert(float,sum(abandonedCalls)))) else 0 end,0))'')
END'
	EXEC(@Sql)


	set @process = 'CW- -- VERSION 52  Update MDF ReportsMasterProcess add Reinicializa replicas '
    set @Sql= 'ALTER procedure [dbo].[ReportsMasterProcess] as

set nocount on

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100), @replicationName nvarchar(100)
declare @numOfReports int,@numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int,@minReports int
DECLARE @dateBegin DATETIME,@dateSP datetime

---shedule
declare @schedule_id int,@nameSchudule sysname,@job_id uniqueidentifier,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint


declare @descError nvarchar(max)
declare @i int,@count int
declare @name sysname,@sql nvarchar(max)
--------------------------- Creacion tablas cada domingo ---------------------------
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = ''logsReportsMaster'')
			drop table logsReportsMaster

	create table [logsReportsMaster](
		[id] int identity not null primary key,
		[name] varchar(100) not null,
		[status] tinyint not null,
		[dateStart] datetime not null,
		[dateEnd] datetime not null,
		[error] varchar(max) not null,
		[maxTime] int not null)

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster1] ON [dbo].[logsReportsMaster]
	(
		[name] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster2] ON [dbo].[logsReportsMaster]
	(
	[status] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster3] ON [dbo].[logsReportsMaster]
	(
	[maxTime] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

end

--------------------------- Termina Creacion tablas cada domingo ---------------------------

set @dateStart = getdate()
set @delay = 0
set @strDelay = ''''
set @reportName = ''''
set @replicationName = ''''
set @numOfReports = 0
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 0
set @minReports = 0
set @scheduleTime = 10

--- obtiene el job_id, y el nombre del schedule_id asocioado al job reports Master
select  @job_id=A.job_id,@schedule_id=C.schedule_id, @nameSchudule=C.name,@scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcess''

-- obtiene los valores de los settings para el tiempo ejecucion de las replicas  y los jobs
select @minReplication = cast(substring(valor, 0, charindex(''|'',valor)) as int) from ccsettings where setting_id = 28
select @minReports = cast(substring(valor, charindex(''|'',valor) + 1, len(valor)) as int) from ccsettings where setting_id = 28

---- revisar los tiempos y actulizar el setting
if (@minReplication + @minReports) > @scheduleTime
begin
	set @scheduleTime= @minReplication + @minReports
	EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
end

set @minReplication = @minReplication * 60

-------------------- Revision que no existe conflictos  -----------------------------------------

declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

insert into @tableArticle(nameArticle,objectId)
SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
inner join sys.tables t on t.name=Art.name

insert into @tableTrigger
select t.name as nameTrigger from @tableArticle Art
inner join sys.triggers  t on Art.objectId=t.parent_id
where name not like ''MSmerge_%''

select @i=1,@count =count(*) from @tableTrigger
while @i<=@count
begin
	select @name = nameArticle  from @tableTrigger where id=@i
	set @sql =''DROP TRIGGER ''+ @name 
	exec (@sql)
	set @i = @i+1
end


-------------------- ejecuccion de las replicas -----------------------------------------

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCenterRia%''

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCRecorderRia%'' order by [name]

select @numOfReplications = count(*) from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = CONVERT(char(8), DATEADD(second, @repDelay, ''00:00:00''), 108)

set @dateSP = getdate()

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName


	update #replications with(rowlock) 	set flag = 1 where [name] = @replicationName

	WAITFOR DELAY ''00:00:01''

	while(
		SELECT count(*) FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) > 0
	begin
		WAITFOR DELAY ''00:00:01''
	end
end

drop table #replications

-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------

create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] not in(''ccspRepCatalogos'',''ccsprepLogAgentriaseparate'')

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count
begin
	select @name = name from #tmpProcedureReports where id=@i

	set @sql =''EXEC ''+ @name +'' @action=1''
	set @dateSP = getdate()
	begin try

		exec (@sql)
		WAITFOR DELAY ''00:00:01''

		while(SELECT count(*)
			FROM sys.dm_exec_requests a
			INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
			INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d WHERE a.session_id > 50
			AND a.session_id = @@SPID and d.text = @sql) > 0
		begin
			WAITFOR DELAY ''00:00:01''
		end

		if( datediff(mi,@dateStart,getdate()) > @scheduleTime) begin
		set @scheduleTime = @scheduleTime+1
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime,error=''Increment time shuduler ''+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart=''19000101'' and dateEnd=''19000101''

			set @minReplication=@minReplication/60
			if(@scheduleTime>60) set @scheduleTime=59
			EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
			update ccsettings set valor=convert(varchar(max),@minReplication)+''|''+convert(varchar(max),@minReports+1),descripcion = ''Min. replicas | Min. reportes este se modifica automaticamente revisar tabla de logsReportsMaster, (Total ''+convert(varchar(max),@scheduleTime) +'' Minutos)'' where setting_id = 28
			break
		end
		set @i = @i+1
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
	end try
	begin catch
		select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
		set @i = @i+1
	end catch
end

drop table #tmpProcedureReports

-------------------- Reinicializa las subcripciones en caso de caducar-----------------------------------------

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where 
(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
mh.comments like  ''%Start the Snapshot Agent to generate the snapshot for this publication%'')
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''ccReportsRia''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@Sql)


	set @process = 'CW- -- VERSION 52  Update MDF JOB ReportsMasterProcess'
    set @Sql= 'USE [msdb]

/****** Object:  Job [ReportsMasterProcess]    Script Date: 23/06/2018 11:25:37 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''ReportsMasterProcess'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcess'', @delete_unused_schedule=1

/****** Object:  Job [ReportsMasterProcess]    Script Date: 23/06/2018 11:25:37 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:25:37 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcess'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcess'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 23/06/2018 11:25:37 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcess'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=20, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	EXEC(@Sql)

	set @process = 'CW- -- VERSION 52  Update MDF JOB '
    set @Sql= 'USE [msdb]

/****** Object:  Job [DatabaseCentinella]    Script Date: 23/06/2018 11:24:41 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

/****** Object:  Job [DatabaseCentinella]    Script Date: 23/06/2018 11:24:41 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:24:41 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Autor: Raymundo Gonzalez
				Fecha: 2018/06/15
				Descripcion:
					Centinela para monitoreo de performance y mantenimiento de las BD de SQL
				'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 23/06/2018 11:24:41 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''use [master]

set nocount on

declare @idDb int
declare @dbName nvarchar(100)
declare @dbLog nvarchar(100)
declare @sql nvarchar(max)
declare @idIndex int
declare @tableName nvarchar(100)
declare @indexName nvarchar(100)
declare @process int
declare @firstSunday datetime
declare @idCmdSql int
declare @cmdSql nvarchar(max)
declare @maxTimeSeconds int
declare @maxTimeSecondsSunday int
declare @dateExecution datetime

set @idDb = 0
set @dbName = ''''''''
set @dbLog = ''''''''
set @sql = ''''''''
set @idIndex = 0
set @tableName = ''''''''
set @indexName = ''''''''
set @process = 1
set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
set @idCmdSql = 0
set @cmdSql = ''''''''
set @maxTimeSeconds = 7200
set @maxTimeSecondsSunday = 14400
set @dateExecution = getdate()

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
	begin
		if exists (select * from sys.tables where name = ''''userDatabases'''')
			drop table userDatabases

		if exists (select * from sys.tables where name = ''''indexMaintenance'''')
			drop table indexMaintenance

		if exists (select * from sys.tables where name = ''''logCentinella'''')
			drop table logCentinella
	end

if not exists (select * from sys.tables where name = ''''userDatabases'''')
	begin
		create table dbo.userDatabases(
			[idDb] int not null identity primary key,
			[dbName] nvarchar(100) not null,
			[dbLog] nvarchar(100) not null,
			[status] bit not null
		)

		CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
		(
			[dbName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
	begin
		create table dbo.indexMaintenance(
			[idIndex] int not null identity primary key,
			[dbName] nvarchar(100) not null,
			[tableName] nvarchar(100) not null,
			[indexName] nvarchar(100) not null,
			[indexType] nvarchar(100) not null,
			[indexFragmentation] nvarchar(100) not null,
			[status] bit not null
		)

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
		(
			[dbName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
		(
			[tableName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

if not exists (select * from sys.tables where name = ''''logCentinella'''')
	begin
		create table dbo.logCentinella(
			[idCmdSql] int not null identity primary key,
			[date] datetime not null,
			[cmdSql] nvarchar(max) not null,
			[status] int not null,
			[dateStart] datetime not null,
			[dateEnd] datetime not null,
			[executionTimeSeconds] int not null
		)

		CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
		(
			[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

insert into userDatabases
select db_name(database_id), '''''''', 0
from sys.master_files
where state = 0
and has_dbaccess(db_name(database_id)) = 1
and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
and type = 0

update userDatabases
set [dbLog] = name
from sys.master_files
inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

while (select count(*) from userDatabases where status = 0) > 0
	begin
		set rowcount 1
			select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
		set rowcount 0

		select @sql = ''''use ['''' + @dbName + '''']

insert into master.dbo.indexMaintenance
SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
WHERE indexstats.avg_fragmentation_in_percent > 30
ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

		exec(@sql)

		update userDatabases
		set status = 1
		where idDb = @idDb
	end

while (select count(*) from indexMaintenance where status = 0) > 0
	begin
		set rowcount 1
			select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
		set rowcount 0

		select @sql = ''''use ['''' + @dbName + ''''] ''''

		if @process = 1
				select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )''''
		else if @process = 2
				select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )''''
		else if @process = 3
				select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN''''

		insert into logCentinella
		select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

		if @process < 3
			update indexMaintenance set status = 1 where idIndex = @idIndex
		else
			update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

		if @process < 3
			begin
				if (select count(*) from indexMaintenance where status = 0) = 0
					begin
						update indexMaintenance
						set status = 0

						set @process = @process + 1
					end
			end
	end

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
	begin
		update userDatabases
		set status = 0

		while (select count(*) from userDatabases where status = 0) > 0
			begin
				set rowcount 1
					select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
				set rowcount 0

				select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''

				insert into logCentinella
				select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0							

				select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

				insert into logCentinella
				select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

				select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

drop table #RutaBak

BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

				insert into logCentinella
				select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

				update userDatabases
				set status = 1
				where idDb = @idDb
			end

		select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

drop table #RutaBak''''

		insert into logCentinella
		select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

	end

set @dateExecution = getdate()

while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
	begin
		set rowcount 1
			select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
		set rowcount 0

		update logCentinella
		set dateStart = getdate()
		where idCmdSql = @idCmdSql

		exec(@cmdSql)

		WAITFOR DELAY ''''00:00:01''''

		while(SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b
				ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c
				ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
				AND a.session_id = @@SPID
				and d.text = @cmdSql) > 0
			begin
				WAITFOR DELAY ''''00:00:01''''
			end

		if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
			begin
				if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
					BREAK
			end
		else
			begin
				if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
					BREAK
			end

		update logCentinella
		set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
		where idCmdSql = @idCmdSql
	end

delete userDatabases
delete indexMaintenance'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140724, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
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