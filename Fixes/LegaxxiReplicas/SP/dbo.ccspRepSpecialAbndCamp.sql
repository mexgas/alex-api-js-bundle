ALTER PROCEDURE [dbo].[ccspRepSpecialAbndCamp]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpecialAbndCamp with(rowlock)	where [date] between @from and @to

	insert RepSpecialAbndCamp
	select [date], campaignId, cam_descripcion, total, abandonedCalls,
	cast(isnull(((abandonedCalls*100.0)/nullif(total,0)),0) as decimal(5,2)) abandonedCallsPctg,
	[year],[month],[day],[hour],[minutes]
	from(
		select convert(datetime,convert(varchar(13),cal_inicio,121)+':00') as [date], co.cam_id campaignId,
		cam_descripcion , count(*) total,
		COUNT(CASE WHEN(statuscall_id in(5,6,7,8,9,10,11,15,16))THEN cal_id ELSE NULL END) abandonedCalls,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) as [minutes]
		from ccocallsout co with(nolock) left join cccamps ca on ca.cam_id=co.cam_id
		where cal_inicio between @from and @to and
		cal_manual in (0,2)
		group by convert(varchar(13),cal_inicio,121), co.cam_id,  cam_descripcion)X

end