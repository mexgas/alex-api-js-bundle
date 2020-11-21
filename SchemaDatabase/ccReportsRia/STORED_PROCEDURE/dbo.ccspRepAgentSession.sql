CREATE PROCEDURE [dbo].[ccspRepAgentSession]
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

CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)

delete from RepAgentSession with(rowlock) where date >= @from and date < @to

INSERT INTO #sessionTime
exec ccspGenSession @from=@from,@to=@to

insert into RepAgentSession(date,login,userId,[user],extension,loginTime,logoutTime,sessionTime,sessionTimeSeconds,year,month,day,hour,minutes)
select A.login as date,u.Login,A.user_id,
u.apellidopaterno + ' ' + u.apellidomaterno + ' ' + u.nombres as [user], extension,
A.login,a.logout,
datediff(ss,A.login,logout) as sessionTime,
datediff(ss,A.login,logout) as sessionTimeSeconds,
datepart(yyyy,A.login), datepart(mm,A.login), datepart(dd,A.login),
datepart(hh,A.login), datepart(mi,A.login)
 from #sessionTime A
inner join ccUserView u on A.user_id=u.User_id

drop table #sessionTime

end