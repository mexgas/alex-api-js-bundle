CREATE PROCEDURE [dbo].[ccspRepSpecialDialingResults]
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
	delete from RepSpecialDialingResults with(rowlock) where date >= @from and date < @to
	create table #temptable(
		[date] datetime,
		[Count] int
	)

	create index IX_TemptableDate on #temptable([date])

	insert into #temptable
	select convert(datetime, convert(varchar(14),[fecha],121)+ '00',121),isnull( COUNT(callout_id), 0)
	from ccoLogDials with(nolock)
	where fecha >= @from and fecha < @to and tipoResDial_id  <> 0
	group by convert(datetime, convert(varchar(14),[fecha],121)+ '00',121)

	insert into RepSpecialDialingResults
	select x.[date],[campaignId],[campaign],[statusCallId],[statusCall],[statusCall_Count]
	,isnull( COUNT(callout_id), 0) as 'Count',[statusCall_avg]
	,dbo.fPercentage(isnull( COUNT(callout_id), 0), t.[Count]) as 'avg',
		datepart(yy,convert(datetime, convert(varchar(14),x.[date] ,121)+ '00',121)) as [year],
		datepart(mm,convert(datetime, convert(varchar(14),x.[date] ,121)+ '00',121)) as [month],
		datepart(dd,convert(datetime, convert(varchar(14),x.[date] ,121)+ '00',121)) as [day],
		datepart(hh,convert(datetime, convert(varchar(14),x.[date] ,121)+ '00',121)) as [hour],
		datepart(mi,convert(datetime, convert(varchar(14),x.[date] ,121)+ '00',121)) as [minutes]
	 from (
		select convert(datetime, convert(varchar(14),[fecha],121)+ '00',121) as [date],
			[cld].cam_id as 'campaignId',
			cms.cam_descripcion as 'campaign',
			case when ctr.descripcion is null then 8 else isnull([cld].tipoResDial_id ,0) end as 'statusCallId',
			case when ctr.descripcion is null then 'Otro' else isnull(ctr.descripcion,'') end as 'statusCall',
			case when ctr.descripcion is null then 'Otro_Count' else ctr.descripcion + '_Count' end as [statusCall_Count],
			callout_id,
			case when ctr.descripcion is null then 'Otro_Avg' else ctr.descripcion + '_Avg' end as 'statusCall_avg'
		from ccoLogDials  [cld]
		left join ccTipoResultadoDial ctr on [cld].tipoResDial_id = ctr.tipoResDial_id
		left join cccamps cms on [cld].cam_id = cms.cam_id
		where [fecha] >= @from and [fecha] < @to
	)X
	inner join #temptable t on X.date=t.date
	group by x.[date],[campaignId],[campaign],[statusCallId],[statusCall],[statusCall_Count],[statusCall_avg],t.[Count]

	drop table #temptable
end