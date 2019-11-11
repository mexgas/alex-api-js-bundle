CREATE PROCEDURE [dbo].[ccspRepAgentSessionByInterval]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS


if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin

CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL)
CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
CREATE TABLE #sessionTimeMayores(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

insert into #times
exec ccspTimesReports @from=@from,@to=@to,@interval=15


INSERT INTO #sessionTime
exec ccspGenSession @from=@from,@to=@to

INSERT INTO #sessionTimeGroup
select user_id,login,logout,extension
,dbo.GetTimeGroup(A.login, 0 ) AS timegroup
,dbo.GetTimeGroup(A.logout, 1 ) AS timegroup_next
 ,datediff(ss,login,logout)
 from #sessionTime as A


INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
 select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
 isnull((case when th.start <= login and  th.stop > login and th.start <= dateadd(ss,[tlog seg],login) and  th.stop > dateadd(ss,[tlog seg],login) then datediff(ss,login,dateadd(ss,[tlog seg],login))
				when th.start <= login and  th.stop > login and th.stop < dateadd(ss,[tlog seg],login) then datediff(ss,login,th.stop)
				when th.start > login and th.start <= dateadd(ss,[tlog seg],login) and  th.stop > dateadd(ss,[tlog seg],login) then datediff(ss,th.start,dateadd(ss,[tlog seg],login))
				when th.start > login and th.stop < dateadd(ss,[tlog seg],login) then datediff(ss,th.start,th.stop) else  0 end),0) as [tlog seg]

from #sessionTimeMayores t
inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;


delete from  RepAgentSessionByInterval where [date] between @from and @to;

insert into RepAgentSessionByInterval(date,login,userId,[user],extension,sessionTime,year,month,day,hour,minutes)
select  A.timegroup,
u.Login,A.user_id,
u.apellidopaterno + ' ' + u.apellidomaterno + ' ' + u.nombres as [user], extension,
A.[tlog seg],
datepart(yyyy,A.timegroup), datepart(mm,A.timegroup), datepart(dd,A.timegroup),
datepart(hh,A.timegroup), datepart(mi,A.timegroup)
 from #sessionTimeGroup A
inner join ccUserView u on A.user_id=u.User_id

drop table #sessionTimeGroup;
drop table #sessionTimeMayores;
drop table #times;
drop table #sessionTime;

end