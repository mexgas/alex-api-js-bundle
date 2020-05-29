/*
Autor: Jesus Gallardo
Fecha: 2014/08/08
Descripcion:
		
	Se modifica el SP ccspRepIVRDetail
		
Version requerida: 22
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '23'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'
	
if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Drop TABLE  -- RepOutKPI'
	set @Sql='if exists (select * from sys.tables where name = N''RepOutKPI'') DROP TABLE [dbo].[RepOutKPI]'

	EXEC(@Sql)

	set @process = 'CREATE TABLE -- RepOutKPI'
	set @Sql='CREATE TABLE [dbo].[RepOutKPI](
	[date] [datetime] NOT NULL,
	[campaignId] [smallint] NOT NULL,
	[campaign] [varchar](255) NOT NULL,
	[totalCalls] [smallint] NOT NULL,
	[avgXfer] [smallint] NOT NULL,
	[avgCallTime] [smallint] NOT NULL,
	[c10Secs] [smallint] NOT NULL,
	[c20Secs] [smallint] NOT NULL,
	[c30Secs] [smallint] NOT NULL,
	[cMaxSecs] [smallint] NOT NULL,
	[AnsweredCalls] [smallint] NOT NULL,
	[answeredCallsPctg] [smallint] NOT NULL,
	[remainingCalls] [smallint] NOT NULL,
	[remainingCallsPctg] [smallint] NOT NULL,
	[abandonedCalls] [smallint] NOT NULL,
	[abandonedCallsPctg] [smallint] NOT NULL,
	[avgTimeBetweenCalls] [smallint] NOT NULL,
	[year] [int] NULL,
	[month] [int] NULL,
	[day] [int] NULL,
	[hour] [int] NULL,
	[minutes] [int] NULL
) ON [PRIMARY]
'

	EXEC(@Sql)

	set @process = 'Create index -- IX_RepOutKPI'
	set @Sql='if not exists (select * from sys.indexes where name = N''IX_RepOutKPI'' and object_id = OBJECT_ID(N''RepOutKPI''))
	begin			
	CREATE NONCLUSTERED INDEX [IX_RepOutKPI] ON [dbo].[RepOutKPI]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'

	EXEC(@Sql)


	set @process = 'Create index -- IX_RepOutKPI_1'
	set @Sql='if not exists (select * from sys.indexes where name = N''IX_RepOutKPI'' and object_id = OBJECT_ID(N''RepOutKPI''))
	begin	
	CREATE NONCLUSTERED INDEX [IX_RepOutKPI_1] ON [dbo].[RepOutKPI]
(
	[date] ASC,
	[campaignId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'

	EXEC(@Sql)	
	
	set @process = 'insert -- ReportsFiltersText'
	set @Sql='insert into [ReportsFiltersText] (reportName, restrictExp, dbColumn, id) values (''IVR Detail'', ''A-Z a-z0-9 _\-'', ''ivrName'', 6010)'

	EXEC(@Sql)

	set @process = 'insert -- ReportsFiltersMenus'
	set @Sql='insert into [ReportsFiltersMenus] (idReport, filterMenuName) values (6010, ''text'')'

	EXEC(@Sql)

	set @process = 'Delete -- TranslatedReports'
	set @Sql='delete [TranslatedReports] where id = 6010'

	EXEC(@Sql)

	set @process = 'update -- RepIVRDetail'
	set @Sql='update RepIVRDetail set ivrName = '''' where ivrName = ''systemTranslated_NoName'''

	EXEC(@Sql)	
	
	set @process = 'Alter SP -- ccspRepIVRDetail'
	set @Sql='ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin

	select A.Ivr_id,A.cal_ani,isnull(B.user_id,0) as [user_id],isnull(B.calif_id,0) as [calif_id]
	,isnull(B.cal_id,0) as [cal_id],A.date,A.dnis
	into #IVRLlamadas
	from IVRCallsIn as A 
	left join ccCallsIn As B on  A.IVR_id = B.IVR_id 
	where date >= @from and date < @to
		
	delete from RepIVRDetail with(rowlock)
	where date >= @from AND date < @to
		
	insert into RepIVRDetail
		select #IVRLlamadas.date as fecha, cal_ani as telefono
			, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
			, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
			, isnull(
			(
				select selectedOption + '',''	from IVROptions (nolock)
				where IVROptions.ivr_id = #IVRLlamadas.ivr_id
				order by IVROptions.date for xml path('''')
			),'''') as opciones
			, isnull(datediff( ss, date, maxdate),0) as tiempo,
			datepart(yyyy,[date]),
			datepart(mm,[date]),
			datepart(dd,[date]),
			datepart(hh,[date]),
			datepart(mi,[date]),
			dnis as DNIS,
			isnull(name,'''') as name
			--case when name is NULL then ''systemTranslated_NoName'' when name = '''' then ''systemTranslated_NoName'' else name end
			from #IVRLlamadas
			left join
			(
				select ivr_id,name, max(date) as maxDate from IVROptions nolock
				group by ivr_id,name
			) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
			left join ccusers u (nolock) on (u.user_id = #IVRLlamadas.user_id)
			left join cctipocalif calif on (calif.calif_id = #IVRLlamadas.calif_id)
			where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
			order by date
	
	drop table #IVRLlamadas
	end'	
	
	EXEC(@Sql)

	set @process = 'Alter SP -- ccspRepOutKPI'
	set @Sql='ALTER PROCEDURE [dbo].[ccspRepOutKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete RepOutKPI with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutKPI
	select dateHour, cam_id, '''' as campaign, totalCalls, avgXfer, avgCallTime, c10sec, c20sec, c30sec, cMax, AnsweredCalls, ISNULL((AnsweredCalls * 100.00)/NULLIF(totalCalls,0),0) as AnsweredPctg,
	ComplementCalls as RemainingCalls,  ISNULL((ComplementCalls * 100.00)/NULLIF(totalCalls,0),0) as RemainingPct, AbandonedCalls, ISNULL((AbandonedCalls * 100.00)/NULLIF(totalCalls,0),0) as AbandonedPctg, ISNULL((3600*1.00/NULLIF(totalCalls,0)),0) as AvgTimeBtwCalls, 
	[year], [month], [day],  [hour], [minutes] from (
			select CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) as dateHour,
			calls.cam_id, sum(isnull(total,0)) + sum(isnull(total2,0)) + sum(isnull(total3,0)) as totalCalls,avg(calls.cal_tXfer) as avgXfer, avg(calls.cal_tDialog) as avgCallTime,
			sum(isnull(c10,0)) as c10sec ,sum(isnull(c20,0)) as c20sec ,sum(isnull(c30,0)) as c30sec, sum(isnull(cMax,0)) as cMax,
			sum(isnull(total,0)) as AnsweredCalls, sum(isnull(total2,0)) as ComplementCalls, sum(isnull(total3,0)) as AbandonedCalls,
			datepart(yyyy,max(cal_inicio)) as [year], datepart(mm,max(cal_inicio)) as [month], datepart(dd,max(cal_inicio)) as [day],
			datepart(hh,max(cal_inicio)) as [hour], datepart(mi,max(cal_inicio)) as [minutes]
			from ccocallsout as calls with(nolock, index(IX_ccoCallsOut_2))
			left join (
					select count(cal_id) as total,cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour,
					case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
					case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
					case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
					case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax
					from ccocallsout with(nolock, index(IX_ccoCallsOut_13)) 
					where statusCall_id = 13 and cal_inicio >= @from and cal_inicio < @to 
					group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times 
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times.dateHour and calls.cal_id = times.cal_id )
			left join (
					select count(cal_id) as total2, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
					from ccocallsout with(nolock, index(IX_ccoCallsOut_13)) 
					where statusCall_id not in(13,5) and cal_inicio >= @from and cal_inicio < @to 
					group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times2 
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
			left join (
					select count(cal_id) as total3, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
					 from ccocallsout with(nolock, index(IX_ccoCallsOut_13)) where statusCall_id in(5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
			) as times3
			on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
			where cal_inicio >= @from and cal_inicio < @to 			
			group by calls.cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)
			) as tablon

			update RepOutKPI with(rowlock)
			set campaign = isnull(b.cam_descripcion,'''')
			from RepOutKPI a
			left join ccCamps b
			on a.campaignId = b.cam_id
			where date >= @from AND date < @to	
end'

	EXEC(@Sql)
	
		
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off