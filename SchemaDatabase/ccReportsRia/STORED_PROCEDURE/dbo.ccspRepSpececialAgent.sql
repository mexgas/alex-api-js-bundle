CREATE PROCEDURE [dbo].[ccspRepSpececialAgent]
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

	DECLARE @tresRing AS smallint
	DECLARE @tresDialog AS smallint
	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog

	delete RepSpececialAgent with(rowlock) where [date] between @from and @to

	insert RepSpececialAgent
	select ses.date,ses.userId,[user],login,[session] sessionTime,loginTime,logoutTime
	,isnull(cout.dialog,0)+isnull(cin.dialog,0)+isnull(cin.wrapup,0)+isnull(cout.wrapup,0) dialogTime
	,ISNULL(nd.total,0) ndTime
	,ISNULL(cout.ncalls,0) callsOut
	,ISNULL(cin.ncalls,0) callsIn
	,ISNULL(cout.abnd_xfer,0)+ISNULL(cout.abnd_ring,0)+ISNULL(cout.abnd_dialog,0)+ISNULL(cin.abnd_xfer,0)+ISNULL(cin.abnd_ring,0)+ISNULL(cin.abnd_dialog,0) abandonedCalls
	,ISNULL(cout.answer,0)+ISNULL(cin.answer,0) nanswer2
	,ISNULL(cout.nocalif,0)+ISNULL(cin.nocalif,0) unrated
	from
	(
	select convert(varchar(10),[date],121) [date], login, userid, [user], sum(sessionTimeSeconds) [session], min(logintime) loginTime, max(logouttime) logoutTime
	from RepAgentsession where [date] between @from and @to
	group by convert(varchar(10),[date],121), login, userId, [user]
	)ses
	left join(
	select convert(varchar(10),[date],121) [date], userId,SUM(timeseconds) total from RepAgentNotReady
	where [date] between @from and @to group by convert(varchar(10),[date],121), userId
	) nd on nd.date=ses.date and nd.userId=ses.userId
	left join(
	select CONVERT(varchar(10),cal_inicio,121) [date], USER_ID,SUM(cal_tdialog) dialog, SUM(cal_tnotas) wrapup
	,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccoCallsOut with(index(IX_ccoCallsOut_2),nolock) where cal_inicio between @from and @to and cal_manual in(0,2)
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID
	) cout on cout.date=ses.date and cout.User_id = ses.userId
	left join(
	select
	CONVERT(varchar(10),cal_inicio,121) [date], USER_ID
	,SUM(cal_tdialog) dialog, SUM(cal_tnotas) wrapup
	,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND (isnull(cal_xfer,'1900-01-01 00:00:00') <> '1900-01-01 00:00:00')))THEN 1 ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID
	) cin on cin.date = ses.date and cin.User_id=ses.userId

end