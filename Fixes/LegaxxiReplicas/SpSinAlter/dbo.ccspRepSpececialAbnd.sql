ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd]
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

	delete RepSpececialAbnd with(rowlock)
	where [date] between @from and @to
	
	insert RepSpececialAbnd select [date], campaignId, inboundId, [Espec/Camp], total, abandonedCalls, 
	cast(((abandonedCalls*100.0)/total) as decimal(5,2)) abandonedCallsPctg from (
		select convert(varchar(10),cal_inicio,121) [date], 0 campaignId, ci.inbound_id inboundId, 
		'ACD - ' + descripcion [Espec/Camp], count(*) total, 
		COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'1900-01-01 00:00:00') = '1900-01-01 00:00:00'))  THEN 1 ELSE NULL END) abandonedCalls
		from cccallsin ci with(nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id 
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, 'ACD - ' + descripcion
		union all
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
		'Camp - ' + cam_descripcion [Espec/Camp], count(*) total, 
		COUNT(CASE WHEN(statuscall_id in(11,15,16))THEN cal_id ELSE NULL END) abandonedCalls
		from ccocallsout co with(nolock) left join cccamps ca on ca.cam_id=co.cam_id 
		where cal_inicio between @from and @to and cal_manual in (0,2) group by convert(varchar(10),cal_inicio,121), co.cam_id, 'Camp - ' + cam_descripcion
    ) abnd
end