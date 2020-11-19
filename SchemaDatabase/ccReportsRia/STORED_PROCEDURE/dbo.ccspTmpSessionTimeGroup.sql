CREATE PROCEDURE [dbo].[ccspTmpSessionTimeGroup]
@from as smalldatetime,
@to as smalldatetime 
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+':00')
end

IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID('tempdb..#sessionTimeMayores') IS NOT NULL drop table #sessionTimeMayores;

CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)


if not exists( select * from sys.tables where name='tmpSessionTimeGroup') begin
	CREATE TABLE tmpSessionTimeGroup([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
end
else begin
	truncate table tmpSessionTimeGroup	
	--drop table tmpSessionGeneral
end


INSERT INTO #sessionTimeGroup
select * from tmpSessionGeneral

INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
	select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
	dbo.TimeInterval(th.start,th.stop,login,logout) as [tlog seg]	 

from #sessionTimeMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;


insert into tmpSessionTimeGroup
select user_id,min([login]) as [login],max([logout]) as [logout],min(extension) as extension,timegroup,timegroup_next,sum(tlog) as tlog from #sessionTimeGroup	
group by user_id,timegroup,timegroup_next	
	

IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID('tempdb..#sessionTimeMayores') IS NOT NULL drop table #sessionTimeMayores;

set nocount off