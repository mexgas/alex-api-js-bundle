CREATE PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByRegistry]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
create table #tempPhone(
[date] datetime,camId int,
tel1 int,tel2 int,tel3 int,tel4 int,tel5 int,
listid int
)
create table #sumTempPhone (
[date] datetime,
totalPhone int
)

create index IX_TEMPPHONE  on #tempPhone(listid)

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepSpecialTelephoneNumbersByRegistry with(rowlock) where date >= @from and date < @to

	insert into #tempPhone
		select
		convert(datetime,convert(varchar(11),min(cal_fechaDial))) as [date],
		cam_id as camId,
		sum(case when cal_telefono <> '' then 1 else 0 end),
		sum(case when cal_telefono2 <> '' then 1 else 0 end),
		sum(case when cal_telefono3 <> '' then 1 else 0 end),
		sum(case when cal_telefono4 <> '' then 1 else 0 end),
		sum(case when cal_telefono5 <> '' then 1 else 0 end),
		list_id
	from ccoCallsOutSource with(index(IX_ccoCallsOutSource_19),nolock)
	where cal_fechaDial >= @from and cal_fechaDial < @to
	group by cam_id,list_id


	insert into #sumTempPhone
	select 	[date],SUM(tel1+tel2+tel3+tel4+tel5) from #tempPhone
	group by [date]



	insert into RepSpecialTelephoneNumbersByRegistry
	select date,campaignId,campaign,listId,listName
	,cPhoneNumber_count as cPhoneNumbers,'systemTranslated_' + cPhoneNumber_count+'_Count' as cPhoneNumber_Count,[count]
	,percentage_avg as percentage,'systemTranslated_' + percentage_avg + '_Avg' as percentage_avg,[avg],
	[year],[month],[day],[hour],[minutes]
	from (
	select tem.[date],
	camId as 'campaignId', camp.cam_descripcion as 'campaign',
		isnull(rl.list_id,0) as 'listId', isnull(rl.name, '') as 'listName',
		tem.tel1 as cPhoneNumbers1,tem.tel2 as cPhoneNumbers2,tem.tel3 as cPhoneNumbers3,tem.tel4 as cPhoneNumbers4,tem.tel5 as cPhoneNumbers5,
		dbo.fPercentage(tem.tel1,sumTemp.totalPhone ) as percentage1,
		dbo.fPercentage(tem.tel2,sumTemp.totalPhone) as percentage2,
		dbo.fPercentage(tem.tel3,sumTemp.totalPhone) as percentage3,
		dbo.fPercentage(tem.tel4,sumTemp.totalPhone) as percentage4,
		dbo.fPercentage(tem.tel5, sumTemp.totalPhone) as percentage5,
		datepart(yy,convert(datetime, convert(varchar(11),tem.[date]))) as [year],
		datepart(mm,convert(datetime, convert(varchar(11),tem.[date]))) as [month],
		datepart(dd,convert(datetime, convert(varchar(11),tem.[date]))) as [day],
		datepart(hh,convert(datetime, convert(varchar(11),tem.[date]))) as [hour],
		datepart(mi,convert(datetime, convert(varchar(11),tem.[date]))) as [minutes]
	 from #tempPhone tem
	 inner join ccRIARegistryLists rl on tem.listid =  rl.list_id
	 inner join cccamps camp on camp.cam_id=tem.camId
	 inner join #sumTempPhone sumTemp on tem.date=sumTemp.date)p
	 UNPIVOT(
	 [count] FOR cPhoneNumber_count IN  (cPhoneNumbers1, cPhoneNumbers2, cPhoneNumbers3, cPhoneNumbers4, cPhoneNumbers5)
		)AS unpvt
	 UNPIVOT(
	 [avg] FOR percentage_avg IN  (percentage1, percentage2, percentage3, percentage4, percentage5)
		)AS unpvt2
	where RIGHT(cPhoneNumber_count,1) = RIGHT(percentage_avg,1)

	drop table #tempPhone
	drop table #sumTempPhone

end