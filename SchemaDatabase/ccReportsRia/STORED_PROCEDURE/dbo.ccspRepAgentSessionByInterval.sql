CREATE PROCEDURE [dbo].[ccspRepAgentSessionByInterval]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	delete from  RepAgentSessionByInterval where [date] between @from and @to;

	insert into RepAgentSessionByInterval(date,login,userId,[user],extension,sessionTime,year,month,day,hour,minutes)
	select  A.timegroup,
	u.Login,A.user_id,
	u.apellidopaterno + ' ' + u.apellidomaterno + ' ' + u.nombres as [user], extension,
	A.tlog tlog,
	datepart(yyyy,A.timegroup) [year], datepart(mm,A.timegroup) [mount], datepart(dd,A.timegroup) [day],
	datepart(hh,A.timegroup) [hour], datepart(mi,A.timegroup) [minute]
		from TmpSessionTimeGroup  A
	inner join ccUserView u on A.user_id=u.User_id	
end