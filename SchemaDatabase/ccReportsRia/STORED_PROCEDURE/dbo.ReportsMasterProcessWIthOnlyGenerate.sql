CREATE procedure [dbo].[ReportsMasterProcessWIthOnlyGenerate] 

@from as datetime=null,@to as datetime=null,@scheduleTime int=10,@dateStart datetime =null
as

SET ANSI_WARNINGS off
SET NOCOUNT ON

declare @i int,@count int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)
declare @dateSP datetime

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin	
	set @to=getdate()
end

if @dateStart is null begin
	set @dateStart =getdate()
end
exec ccspTmpSessionGeneral @from= @from,@to=@to
exec ccspTmpTimesInterval @from= @from,@to=@to,@interval=15
exec ccspTmpSessionTimeGroup @from= @from,@to=@to

create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like 'ccspRep%' and [name] not in('ccspRepCatalogos','ccsprepLogAgentriaseparate')
and name not in(select name from logsReportsMaster where status=0 and dateStart>=@dateStart) 

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,'19000101','19000101','',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count and datediff(mi,@dateStart,getdate()) < @scheduleTime
begin
	select @name = name from #tmpProcedureReports where id=@i
	

	set @sql ='EXEC '+ @name +' @action=1,@from='''+convert(varchar(max),@from,121)+''', @to='''+convert(varchar(max),@to,121)+''''
	set @dateSP = getdate()
	
	print (@sql)
	begin try

		exec (@sql)
		WAITFOR DELAY '00:00:01'

		while(SELECT count(*)
			FROM sys.dm_exec_requests a
			INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
			INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d WHERE a.session_id > 50
			AND a.session_id = @@SPID and d.text = @sql) > 0
		begin
			WAITFOR DELAY '00:00:01'
		end
		if( datediff(ss,@dateStart,getdate()) > @scheduleTime*60) begin		
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime+1,error='Increment time shuduler '+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart='19000101' and dateEnd='19000101'
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart='19000101' and dateEnd='19000101'			
			break
		end	
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart='19000101' and dateEnd='19000101'
	end try
	begin catch
	    
		select @descError = 'Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		select @descError,@name
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart='19000101' and dateEnd='19000101'		
		
	end catch

	set @i = @i+1
end

drop table #tmpProcedureReports