ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
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
							
	DECLARE @data varchar(10), @promesa INT, @promesainb INT, @tresDialog AS smallint
	EXEC @tresDialog=ccspConfigTresDialog
	select @data = isnull(valor,'1|1') from ccSettings where setting_id = 30
	SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,'|') where id = 1
	SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,'|') where id = 2
						
	delete RepSpececialAgtPerformance with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
	,us.apellidopaterno + ' ' + us.apellidomaterno + ' ' + nombres [user],login [Agent]
	,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
	from (
	select [date], user_id, SUM(answer) answer, SUM(promises) promises
	,isnull(cast(SUM(promises)*100.0/nullif(SUM(answer),0) as decimal(5,2)),0) promisesPctg
	,isnull(sum(dialog)/nullif(SUM(answer),0),0) dialog, isnull(sum(wrapup)/nullif(SUM(answer),0),0) wrapup
	from (
	select 
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
	,isnull(count(case calif_id when @promesa then 1 else null end),0) promises
	,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) answer
	from ccoCallsOut with(nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id
	union all
	select
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
	,isnull(count(case calif_id when @promesainb then 1 else null end),0) promises
	,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) answer
	from ccCallsIn with(nolock) where cal_inicio between @from and @to  and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
	left join ccUserView us on us.user_id=rcalls.user_id
end