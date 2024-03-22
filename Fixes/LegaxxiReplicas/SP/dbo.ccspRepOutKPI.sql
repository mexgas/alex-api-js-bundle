ALTER PROCEDURE [dbo].[ccspRepOutKPI]
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
	select dateHour, cam_id, campaign, sum(totalCalls) as totalCalls,
	sum(txfer)/sum(totalCalls) as avgXfer, sum(tDialog)/sum(totalCalls) as avgCallTime,
	sum(C10) as c10sec, sum(C20) as c20sec, sum(C30) as c30sec, sum(CMax) as cMax,
	sum(AnsweredCalls) as AnsweredCalls, (sum(AnsweredCalls) * 100.00)/sum(totalCalls) as AnsweredPctg,
	sum(RemainingCalls) as RemainingCalls, (sum(RemainingCalls) * 100.00)/sum(totalCalls) as RemainingPct,
	sum(AbandonedCalls) as AbandonedCalls, (sum(AbandonedCalls) * 100.00)/sum(totalCalls) as AbandonedPctg,
	(3600*1.00)/sum(totalCalls) as AvgTimeBtwCalls,
	datepart(yyyy,max(dateHour)) as [year], datepart(mm,max(dateHour)) as [month], datepart(dd,max(dateHour)) as [day],
	datepart(hh,max(dateHour)) as [hour], datepart(mi,max(dateHour)) as [minutes]
	from
	(
		select CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121) as dateHour, cam_id, '' as campaign,
		count(*) as totalCalls,
		cal_tXfer as tXfer,
		cal_tDialog as tDialog,
		case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
		case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
		case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
		case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax,
		case when statusCall_id = 13 then 1 else 0 end as AnsweredCalls,
		0.00 as AnsweredPctg,
		case when statusCall_id not in (13,5) then 1 else 0 end  as RemainingCalls,
		0.00 as RemainingPct,
		case when statusCall_id in(5,6,7,8,9,10,11,15,16) then 1 else 0 end  as AbandonedCalls,
		0.00 as AbandonedPctg,
		0.00 as AvgTimeBtwCalls
		from ccocallsout with(nolock)
		where cal_inicio >= @from and cal_inicio < @to
		group by statusCall_id, cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121), cal_tXfer, cal_tDialog
	) as final
	group by dateHour, cam_id, campaign
	order by dateHour, cam_id

	update RepOutKPI with(rowlock)
	set campaign = isnull(b.cam_descripcion,'')
	from RepOutKPI a
	left join ccCamps b
	on a.campaignId = b.cam_id
	where date >= @from AND date < @to

end