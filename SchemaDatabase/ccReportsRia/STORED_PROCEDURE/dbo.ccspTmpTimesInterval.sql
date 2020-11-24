CREATE PROCEDURE [dbo].[ccspTmpTimesInterval]
@from as smalldatetime,
@to as smalldatetime,
@interval as int
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,2, convert(varchar(15),getdate(),121)+':00')
end

if not exists( select * from sys.tables where name='TmpTimesInterval') begin
	CREATE TABLE TmpTimesInterval([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on TmpTimesInterval([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on TmpTimesInterval([Start] DESC)

end
else begin
	truncate table TmpTimesInterval
--	drop table TmpTimesInterval
end

insert into TmpTimesInterval
exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

set nocount off