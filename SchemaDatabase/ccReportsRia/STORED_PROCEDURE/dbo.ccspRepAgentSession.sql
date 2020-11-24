CREATE PROCEDURE [dbo].[ccspRepAgentSession]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepAgentSession where date >= @from and date < @to

	insert into RepAgentSession(date,login,userId,[user],extension,loginTime,logoutTime,sessionTime,sessionTimeSeconds,year,month,day,hour,minutes)
	select A.login as date,u.Login,A.user_id,
	u.apellidopaterno + ' ' + u.apellidomaterno + ' ' + u.nombres as [user], extension,
	A.login,a.logout,
	datediff(ss,A.login,logout) as sessionTime,
	datediff(ss,A.login,logout) as sessionTimeSeconds,
	datepart(yyyy,A.login) [year], datepart(mm,A.login) [mount], datepart(dd,A.login) as [day],
	datepart(hh,A.login) as [hour], datepart(mi,A.login) as [minute]
	 from TmpSessionGeneral A
	inner join ccUserView u on A.user_id=u.User_id

end