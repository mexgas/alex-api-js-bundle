CREATE PROCEDURE [dbo].[ccspTimesReports]
@from as smalldatetime,
@to as smalldatetime,
@interval int =15
AS
set nocount on

CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

declare @starttime datetime,@number int
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ ':00',121)
set @number = 0



while @number <= (datediff(mi,@starttime,@to)/@interval) begin
	insert into #times
	select @number,DATEADD(mi, @number*@interval, @starttime),DATEADD(mi, (@number+1)*@interval, @StartTime)
	set @number = @number +1
end

select * from #times
drop table #times