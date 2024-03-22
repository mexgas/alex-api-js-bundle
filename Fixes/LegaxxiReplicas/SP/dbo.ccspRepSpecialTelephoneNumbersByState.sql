ALTER PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByState]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

declare @totales int

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepSpecialTelephoneNumbersByState with(rowlock) where date >= @from and date < @to

	select @totales = isnull( COUNT(callout_id), 0)
	from ccoCallsOutSource with(nolock)
	where cal_fechaDial >= @from
	and cal_fechaDial < @to
	and Region is not null

	insert into RepSpecialTelephoneNumbersByState
	select convert(datetime,convert(varchar(11),cal_fechaDial)) as [date],
	   isnull([cos].list_id,0) as 'listId', isnull(rl.name, '') as 'listName',
	   Region as [state],
	   Region + '_Count' as [state_Count],
	   isnull( COUNT(callout_id), 0) as 'Count',
	   Region + '_Avg' as 'state_avg',
	   dbo.fPercentage(isnull( COUNT(callout_id), 0), @totales) as 'avg',
	   datepart(yy,convert(datetime, convert(varchar(11),cal_fechaDial))) as [year],
	   datepart(mm,convert(datetime, convert(varchar(11),cal_fechaDial))) as [month],
	   datepart(dd,convert(datetime, convert(varchar(11),cal_fechaDial))) as [day],
	   datepart(hh,convert(datetime, convert(varchar(11),cal_fechaDial))) as [hour],
	   datepart(mi,convert(datetime, convert(varchar(11),cal_fechaDial))) as [minutes]
	   from ccoCallsOutSource [cos] with(nolock)
	   left join ccRIARegistryLists rl on [cos].list_id =  rl.list_id
	where cal_fechaDial >= @from
	and cal_fechaDial < @to
	and Region is not null
	group by convert(datetime,convert(varchar(11),cal_fechaDial)) , [cos].list_id, rl.name, Region
end