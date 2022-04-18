CREATE PROCEDURE [dbo].[ccspTimesReports]
@from as smalldatetime,
@to as smalldatetime,
@interval int =15
AS
set nocount on

declare @row int
declare @starttime datetime

set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ ':00',121)
--set @to=dateadd(mi,15,@to)


select @row=ABS( CEILING(1.0*DATEDIFF(mi,@starttime,@to)/@interval))


;WITH Numbers AS
(
    SELECT TOP (@row) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
    FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
)
SELECT  ROW_NUMBER() OVER (ORDER BY n) as [ID], DATEADD(MINUTE,@interval* (n-1), @from) as [Start], DATEADD(MINUTE,@interval* (n), @from) as [Stop]
FROM Numbers