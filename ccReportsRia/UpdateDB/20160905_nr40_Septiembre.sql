/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 20160608
Description:
**********************************************************************************************
	SP ReportsMasterProcess: Se cambia para que se ejecuten la replicas de manera paulatina
Database: ccReportsRiaPara
Required version: 37

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =40
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1 begin
	begin tran
	begin try

	 set @process = 'CREATE TABLE RepAgentSessionByInterval'
	set @sql='if not exists (select * from sys.tables where name = N''RepAgentSessionByInterval'')
    begin
        CREATE TABLE RepAgentSessionByInterval([date] [datetime] ,[login]  [varchar](15),[userId] int NOT NULL,[user] [varchar](255) NULL,[extension] [varchar](15) NOT NULL, [sessionTime] [INT] NULL, [year] [INT] NULL, [month] [INT] NULL, [day] [INT] NULL, [hour] [INT] NULL, [minutes] [INT] NULL) 

    end'
	EXEC(@sql)

	  set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
	DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE'
	EXEC(@sql)

	set @process = 'Alter table - ccLogAgentesDia'
	set @sql='if not exists (select * from sys.columns where name = N''release'' and Object_ID = Object_ID(N''ccmenus''))
			ALTER TABLE ccLogAgentesDia ADD currentStatus int'
	EXEC(@sql)

	set @process = 'Alter table - ccLogAgentesDia'
	set @sql='if not exists (select * from sys.columns where name = N''release'' and Object_ID = Object_ID(N''ccmenus''))
			      ALTER TABLE ccLogAgentesDia ADD callID int'
	EXEC(@sql)

	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE'
	EXEC(@sql)




		set @process = 'drop SP --[dbo].[ccspRepAgentSessionByInterval]'
		set @sql='if exists (select * from sys.procedures where name = ''ccspRepAgentSessionByInterval'')
    				begin
        				DROP PROCEDURE [dbo].[ccspRepAgentSessionByInterval]
    				end'
		EXEC(@sql)


		set @process = 'create SP -- [dbo].[ccspRepAgentSessionByInterval]'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepAgentSessionByInterval]
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
		,convert(datetime,case when datepart(mi,A.login) between 0 and 14 then convert(varchar(13),A.logout,121) + '':00:00.000''
					when datepart(mi,A.login) between 15 and 29 then convert(varchar(13),A.login,121) + '':15:00.000''
					when datepart(mi,A.login) between 30 and 44 then convert(varchar(13),A.login,121) + '':30:00.000''
					when datepart(mi,A.login) between 45 and 59 then convert(varchar(13),A.login,121) + '':45:00.000'' end) AS timegroup
		,convert(datetime,case when datepart(mi,A.logout) between 0 and 14 then convert(varchar(13),A.logout,121) + '':15:00.000''
					when datepart(mi,A.logout) between 15 and 29 then convert(varchar(13),A.logout,121) + '':30:00.000''
					when datepart(mi,A.logout) between 30 and 44 then convert(varchar(13),A.logout,121) + '':45:00.000''
					when datepart(mi,A.logout) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.logout),121) + '':00:00.000'' end) as timegroup_next
	
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
		u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension,
		A.[tlog seg],
		datepart(yyyy,A.timegroup), datepart(mm,A.timegroup), datepart(dd,A.timegroup),
		datepart(hh,A.timegroup), datepart(mi,A.timegroup)
		 from #sessionTimeGroup A
		inner join ccUsers u on A.user_id=u.User_id


		--SELECT * FROM RepAgentSessionByInterval
		--SELECT * FROM #sessionTimeMayores where user_id = 2  order by user_id 
	
		drop table #sessionTimeGroup;
		drop table #sessionTimeMayores;
		drop table #times;
		drop table #sessionTime;

		end	'
	
		EXEC(@sql)



		set @process = 'drop SP --ccspGenSession'
		set @sql='if exists (select * from sys.procedures where name = ''ccspGenSession'')
    				begin
        				DROP PROCEDURE [dbo].[ccspGenSession]
    				end'
		EXEC(@sql)
		

		set @process = 'create SP -- ccspGenSession'
		set @sql='CREATE PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

--declare @from AS smalldatetime,@to AS smalldatetime
--select  @from=''2016-08-24 03:00:00'',@to=''2016-08-25 03:00:00''

declare @date datetime
CREATE TABLE #tempccGenSession(
	[fila] int NOT NULL,
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	primary key (fila,user_id)	
)

CREATE TABLE #temUserIdLogoutNull([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull([fila] int NOT NULL,[user_id] [smallint] NOT NULL,primary key (fila,user_id))


insert into #tempccGenSession
select A.Fila, A.User_id,A.fecha login,S.fecha logout,A.Extension
from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha--convert(varchar(19),fecha,121) fecha 
from ccLogLogin a where fecha >= @from and fecha <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a where fecha >= @from	and fecha <= @to 
) S
on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
where A.TipoMov=1 --and A.User_id in(3754)
order by login


update x  set x.fila = x.row
from(
	select fila, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login) row from #tempccGenSession
)x
	

insert into #temUserIdLogoutNull
select user_id from #tempccGenSession where logout is null group by user_id


insert into #temIdMaxLogoutNull
select A.fila,A.user_id from #tempccGenSession A 
inner join (
select max(fila) fila,user_id from #tempccGenSession where user_id in( select user_id from #temUserIdLogoutNull ) group by user_id)B
	on A.fila=B.fila and A.user_id=B.user_id
	where A.logout is null

set @date=GETDATE()
update A set A.logout=case when @to<@date then @to else @date end from #tempccGenSession A
inner join #temIdMaxLogoutNull B on A.user_id=B.user_id and A.fila=B.fila


update A set A.logout =
	(select case when  max(fecha) is not null then max(fecha) when DATEDIFF(ss,A.login,B.login)<2 then DATEADD(ms,-10,B.login) else DATEADD(ms,5,A.login) end from ccLogAgentesDia C where A.user_Id=C.User_id and fecha between A.login and B.login ) --logout,
 from #tempccGenSession A 
left join #tempccGenSession B on A.fila=B.fila-1  and A.user_id=B.user_id
where A.logout is null 


delete from #tempccGenSession where login=logout

delete A
from #tempccGenSession A
inner join
(
select user_id,convert(varchar(19),[login],121)[login],convert(varchar(19),logout,121)logout  from #tempccGenSession 
group by user_id,convert(varchar(19),[login],121),convert(varchar(19),logout,121) having count(*)>1
) B
on A.user_id=B.user_id and convert(varchar(19), A.login,121) =B.login and convert(varchar(19), A.logout,121)=B.logout



SELECT TOP 0 * INTO #temp_ccGenSession FROM #tempccGenSession

INSERT INTO #temp_ccGenSession ([user_id], extension, login, logout)
select user_id, ext, login, logout
from(select a.user_id, max(Extension) as ext, a.fecha as ''logout'',
		(select isnull(max(Fecha),getdate())
			from ccLogLogin b with(nolock)
			where b.user_id = a.user_id and
			b.tipomov = 1 and
			b.fecha <= a.fecha and
			b.fecha >= (select isnull(max(fecha),b.fecha)
						from ccLogLogin with(nolock)
						where user_id = b.user_id and
						tipomov = 0 and
						fecha < a.fecha)
		) as ''login''
		from ccLogLogin a
		where a.tipomov=0
		and fecha >= @from
		and fecha <= @to
		group by a.user_id, a.fecha) as sessiontime
		where datediff(day,login,logout) >= 1
order by user_id, login

UPDATE a with (ROWLOCK)
SET a.logout = b.logout
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a on a.user_id = b.user_id and a.login = b.login and a.logout <> b.logout


select user_id, dateadd(ss,-1,[login]),convert(varchar(19),dateadd(ss,1,[logout]),121),extension from #tempccGenSession

DROP TABLE #temp_ccGenSession
drop table #tempccGenSession
drop table #temUserIdLogoutNull
drop table #temIdMaxLogoutNull


--return(0)
--set nocount off
'
		EXEC(@sql)

		set @process ='DROP SP --ccspTimesReports'
		set @sql='if exists (select * from sys.procedures where name = ''ccspTimesReports'')
    				begin
        				DROP PROCEDURE [dbo].[ccspTimesReports]
    				end'
		EXEC(@sql)


		set @process ='create SP -- ccspTimesReports'
		set @sql='CREATE PROCEDURE [dbo].[ccspTimesReports]
@from as smalldatetime,
@to as smalldatetime,
@interval int =15
AS
set nocount on

CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

declare @starttime datetime,@number int
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
set @number = 0



while @number <= (datediff(mi,@starttime,@to)/@interval) begin
	insert into #times
	select @number,DATEADD(mi, @number*@interval, @starttime),DATEADD(mi, (@number+1)*@interval, @StartTime)
	set @number = @number +1
end

select * from #times
drop table #times'
	
		
		EXEC(@sql)


		set @process =' CREATE NONCLUSTERED INDEX [IX_RepAgentSessionByInterval] ON [dbo].[RepAgentSessionByInterval]'
		set @sql='ALTER PROCEDURE [dbo].[ccspGenSession]
		if not exists (select * from sys.indexes where name = N''yourIndexName'' and object_id = OBJECT_ID(N''yourTableName''))
		begin
       CREATE NONCLUSTERED INDEX [IX_RepAgentSessionByInterval] ON [dbo].[RepAgentSessionByInterval]
		(
		[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	 end'

	 EXEC(@sql)



		set @process ='ALTER PROCEDURE [dbo].[ccspGenSession]-----------------'
		set @sql='ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

--declare @from AS smalldatetime,@to AS smalldatetime
--select  @from=''2016-08-24 03:00:00'',@to=''2016-08-25 03:00:00''

declare @date datetime
CREATE TABLE #tempccGenSession(
	[fila] int NOT NULL,
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	primary key (fila,user_id)	
)

CREATE TABLE #temUserIdLogoutNull([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull([fila] int NOT NULL,[user_id] [smallint] NOT NULL,primary key (fila,user_id))


insert into #tempccGenSession
select A.Fila, A.User_id,A.fecha login,S.fecha logout,A.Extension
from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha--convert(varchar(19),fecha,121) fecha 
from ccLogLogin a where fecha >= @from and fecha <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a where fecha >= @from	and fecha <= @to 
) S
on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
where A.TipoMov=1 --and A.User_id in(3754)
order by login


update x  set x.fila = x.row
from(
	select fila, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login) row from #tempccGenSession
)x
	

insert into #temUserIdLogoutNull
select user_id from #tempccGenSession where logout is null group by user_id


insert into #temIdMaxLogoutNull
select A.fila,A.user_id from #tempccGenSession A 
inner join (
select max(fila) fila,user_id from #tempccGenSession where user_id in( select user_id from #temUserIdLogoutNull ) group by user_id)B
	on A.fila=B.fila and A.user_id=B.user_id
	where A.logout is null

set @date=GETDATE()
update A set A.logout=case when @to<@date then @to else @date end from #tempccGenSession A
inner join #temIdMaxLogoutNull B on A.user_id=B.user_id and A.fila=B.fila


update A set A.logout =
	(select case when  max(fecha) is not null then max(fecha) when DATEDIFF(ss,A.login,B.login)<2 then DATEADD(ms,-10,B.login) else DATEADD(ms,5,A.login) end from ccLogAgentesDia C where A.user_Id=C.User_id and fecha between A.login and B.login ) --logout,
 from #tempccGenSession A 
left join #tempccGenSession B on A.fila=B.fila-1  and A.user_id=B.user_id
where A.logout is null 


delete from #tempccGenSession where login=logout

delete A
from #tempccGenSession A
inner join
(
select user_id,convert(varchar(19),[login],121)[login],convert(varchar(19),logout,121)logout  from #tempccGenSession 
group by user_id,convert(varchar(19),[login],121),convert(varchar(19),logout,121) having count(*)>1
) B
on A.user_id=B.user_id and convert(varchar(19), A.login,121) =B.login and convert(varchar(19), A.logout,121)=B.logout



SELECT TOP 0 * INTO #temp_ccGenSession FROM #tempccGenSession

INSERT INTO #temp_ccGenSession (fila,[user_id], extension, login, logout)
select -1,user_id, ext, login, logout
from(select a.user_id, max(Extension) as ext, a.fecha as ''logout'',
		(select isnull(max(Fecha),getdate())
			from ccLogLogin b with(nolock)
			where b.user_id = a.user_id and
			b.tipomov = 1 and
			b.fecha <= a.fecha and
			b.fecha >= (select isnull(max(fecha),b.fecha)
						from ccLogLogin with(nolock)
						where user_id = b.user_id and
						tipomov = 0 and
						fecha < a.fecha)
		) as ''login''
		from ccLogLogin a
		where a.tipomov=0
		and fecha >= @from
		and fecha <= @to
		group by a.user_id, a.fecha) as sessiontime
		where datediff(day,login,logout) >= 1
order by user_id, login

UPDATE a with (ROWLOCK)
SET a.logout = b.logout
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a on a.user_id = b.user_id and a.login = b.login and a.logout <> b.logout


select user_id, dateadd(ss,-1,[login]),convert(varchar(19),dateadd(ss,1,[logout]),121),extension from #tempccGenSession

DROP TABLE #temp_ccGenSession
drop table #tempccGenSession
drop table #temUserIdLogoutNull
drop table #temIdMaxLogoutNull


--return(0)
--set nocount off


'
		EXEC(@sql)

		
		set @process ='ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]-----------'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

--declare @action as tinyint=1,
--@from as datetime = null,
--@to as datetime = null

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

create table #timeDetailAgent(	
	[User_id] int not null,
	dateStartDetail datetime null,dateEndDetail datetime null,dateNext datetime null
	,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null,
	tunknown2 decimal(10,3) 
	)

create table #sessionTime(	
	[User_id] int not null,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL 
	)

insert into #timeDetailAgent
 exec ccsprepLogAgentriaseparate @from=@from,@to=@to

 declare @dateNow datetime
declare @starttime datetime,@number int
 set @dateNow=getdate()
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
set @number = 0

create table #tempFechasR(id int,fecha datetime,tiempo int)

CREATE TABLE #times([ID] INT primary key, [Start] DATETIME,	[Stop] DATETIME	)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

while @number <= (datediff(mi,@starttime,@to)/60) begin
   insert into #times
   select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
   set @number = @number +1
end

if @action = 1
begin
	--

	-- Session Time
	insert into #sessionTime
 exec [ccspGenSession] @from=@from,@to=@to

	-- Inbound Data
	SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
	,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
	,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
	into #inboundData
	FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
		,COUNT(cal_id)AS ntotal
		,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
		,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour
		,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
		,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd
		,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
		,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que
		,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
		,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
		,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
		,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
		,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
		,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
		,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
		,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
		,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
		,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
		,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
		,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
		,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
		,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
	GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
	right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
	FROM(SELECT timegroup,inbound_id,[user_id]
		,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
		,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
		,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
		,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
		,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
		,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
		,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
		,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
		,*
	FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
	UNION
	SELECT timegroup_next,inbound_id,[user_id]
		,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
		,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
		,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
		,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
		,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
		,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
		,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
		,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
		,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
	GROUP BY timegroup,inbound_id,[user_id])xDetailTime
	ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,inbound_id,[user_id]

	--Outbound Data
	SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
	into #outboundData
	FROM(
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,cam_id,[user_id]

	-- Agent Information
	SELECT timegroup,[user_id],tlog, 0 as treq, tnot_av
	,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,nother,nMoh,nWHag,nWHcl
	into #agentInformation
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
				,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
				,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
				,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
				,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
				,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
				,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl

				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4

			 FROM(
					select User_id,timegroup
				,case when sum(tunknown2)>0 then sum(tunknown+tunknown2) else sum(tunknown) end as tunknown
				,case when sum(tnot_av2)>0 then sum(tnot_av+tnot_av2) else sum(tnot_av) end as tnot_av
				,case when sum(tav2)>0 then sum(tav+tav2) else sum(tav) end as tav
				,case when sum(tprob2)>0 then sum(tprob+tprob2) else sum(tprob) end as tprob
				,case when sum(tother2)>0 then sum(tother+tother2) else sum(tother) end as tother
				,case when sum(tmanualcall2)>0 then sum(tmanualcall+tmanualcall2) else sum(tmanualcall) end as tmanualcall
				,sum(nother) as nother
				--,sum(tunknown2Other) as tunknown2Other,
				,0 as tunknown2
					from(
				select User_id,timegroup
				,tunknown,tnot_av,tav,tprob,tother,tmanualcall,nother
				,cast(case when tunknown>0 then tunknown2 else 0 end as int) as tunknown2
				,cast(case when tnot_av>0 then tunknown2 else 0 end as int) as tnot_av2
				,cast(case when tav>0 then tunknown2 else 0 end as int) as tav2
				,cast(case when tprob>0 then tunknown2 else 0 end as int) as tprob2
				,cast(case when tother>0 then tunknown2 else 0 end as int) as tother2
				,cast(case when tmanualcall>0 then tunknown2 else 0 end as int) as tmanualcall2
				--,cast(case when tunknown=0 and tnot_av=0 and tav=0 and tprob=0 and tother=0 and tmanualcall=0 then tunknown2 else 0 end as int) as tunknown2Other
				from #timeDetailAgent )x
				group by timegroup,User_id
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]


  SELECT DATEADD(ss,-(tStatus),(fecha)) as dateStartDetail,(fecha) as dateEndDetail,
  convert(smalldatetime,convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000'',121) AS timegroup
  ,dateadd(hh,1,convert(smalldatetime,convert(varchar(13),fecha,121) + '':00:00.000'',121)) as timegroup_next, TipoNotReady_id
    ,[User_id],(tStatus) as [timeNotReady],1 as [count], tstatus as [time]
	into #notReady
  FROM ccLogAgentesNotReady
  WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to

  
  insert into #tempFechasR select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(13), @dateNow,121) group by User_id

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,TipoNotReady_id,[User_id],[timeNotReady],[count],[time])
	select 		
		B.fecha as dateStartDetail,
		@dateNow as dateEndDetail,
		CONVERT(smalldatetime,CONVERT(varchar(13),B.fecha,121)+ '':00'',121) AS timegroup,
		case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
		else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end AS timegroup_next
		,0 as TipoNotReady_id,User_id,0 as timeNotReady,1 as [count],tiempo as [time]
		from ccLogAgentesDia A
		inner JOIN #tempFechasR B ON A.fecha=B.fecha  and A.User_id=B.id WHERE currentStatus =2	

 select * into #notReady2 from #notReady where datediff(HH,timegroup,timegroup_next)>1
 delete #notReady where datediff(HH,timegroup,timegroup_next) > 1
 
 insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next, tiponotready_id,User_id,timeNotReady, [count], [time])
 select (dateStartDetail),(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next, tiponotready_id,[User_id]
 ,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
     when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady,1 as [count], isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
     when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as [time] 
 from #notReady2 t
 inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
 where  datediff(ss,th.start,timegroup_next)>0
	
	delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to

	insert into RepAgentNotReady
	select a.timegroup as date, c.login, a.user_id as [userId], c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres as [user],
	a.tlog as sessionTime,
	isnull(d.tiponotready_id,0) tiponotready_id, isnull(d.descripcion,'''') descripcion,
	isnull(d.descripcion,'''') + ''_Count'' as descripcion_count, sum(isnull([count],0)) count, isnull(d.descripcion,'''') + ''_Time'' as descripcion_time,
	sum(isnull([time],0)) time, sum(isnull([time],0)) as timeSeconds--, amountReal
	,datepart(yyyy,a.timegroup) year, datepart(mm,a.timegroup) [mounth], datepart(dd,a.timegroup) [day], datepart(hh,a.timegroup) [hour], datepart(mi,a.timegroup) [minute]
	from #agentInformation a
	left outer join #notReady b on (a.timegroup = b.timegroup and  a.user_id =b.user_id)
	left outer join (
		select user_id, login, apellidopaterno, apellidomaterno, nombres
		from ccusers
	) as c on (a.user_id = c.user_id)
	left outer join (
		select tiponotready_id, descripcion
		from ccTipoNotReady
	) as d on (b.tiponotready_id = d.tiponotready_id)
	group by a.timegroup, c.Login, a.user_id,c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres, a.tlog, d.tiponotready_id, d.descripcion



	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #notReady
	drop table #timeDetailAgent
	drop table #notReady2
	drop table #times
	drop table #tempFechasR


end'
		EXEC(@sql)


		set @process ='ALTER PROCEDURE [dbo].[ccspRepAgentSession]---------------'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentSession]
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
u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension,
A.login,a.logout,
datediff(ss,A.login,logout) as sessionTime,
datediff(ss,A.login,logout) as sessionTimeSeconds,
datepart(yyyy,A.login), datepart(mm,A.login), datepart(dd,A.login),
datepart(hh,A.login), datepart(mi,A.login)
 from #sessionTime A
inner join ccUsers u on A.user_id=u.User_id



drop table #sessionTime

end'
		EXEC(@sql)




		set @process ='ALTER PROCEDURE [dbo].[ccspRepOutCalls]---------------'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

if @action = 1
begin

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	declare @interval int
	 declare @starttime datetime
     declare @number int
     set @starttime = @from
     set @number = 0   
	 set @interval=15

      create table #inboundData(row int identity, dateStartDetail datetime,
      dateEndDetail datetime,      timegroup datetime, timegroup_next datetime,      time_endque datetime,
      time_ring datetime,      time_dialog datetime, time_notes datetime,      time_end_call datetime,
      phone_in varchar(30),      cal_id int, dni_id int,      Inbound_id int,
      User_id int,      ntotal int, ninitial int,      nout_hour int,
      nout_service int, nabnd int,     nno_agent int,
      nque int,      ntimeout int,    noverflow int,
      nxfer int,      nxfer_que int,     nabnd_xfer int,      nabnd_ring int,
      nno_answer int,      nabnd_dialog int,
      nanswer int,      nlost int,     nmsg int,      nabnd_tres int,
      nansw_tres int,      tque_max int,
      tque int,      txfer int,     tdialog int,      tnotes int,
      tring int,      tresp int,     nMoh int,      nWHag int,
      nWHcl int)
     
      create table #outboundData( row int identity,
      dateStartDetail datetime, dateEndDetail datetime,
      timegroup datetime, timegroup_next datetime,
      cam_id int,User_id int,ntotal int,nno_agent int,
      nxfer int,nabnd_xfer int,nabnd_ring int, nno_answer int,
      nabnd_dialog int,nanswer int,
      nlost int,tque int,txfer int,tring int,
      tdialog int,tnotes int,tresp int,nhangup int, nMoh int,nWHag int,nWHcl int,time_endque datetime,
      time_ring datetime,time_dialog datetime,
      time_notes datetime,time_end_call datetime,
      phone_out varchar(30),cal_id int,cal_puerto int, idwg int)
     
     CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
 
    create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
    create nonclustered index ix_times2 on #times([Start] DESC)
	CREATE TABLE #sessionTime([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	
	
	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	insert into #sessionTime
	exec ccspGenSession @from=@from,@to=@to	

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,       
		  case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
		  ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull(max(cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]            
		  ,COUNT(cal_id)AS ntotal
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		  ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		  ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl           
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0               
		  group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id
	   
	delete #inboundData WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
	AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0                                                   
   
	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15
               
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)     
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call                                
		  ,phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent       
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres           
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque         
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring              
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp                                                                      
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl               
		  from #inboundData2 t
		  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
		  order by cal_id                         
   
	drop table #inboundData2                      
		
	      
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)	
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		  ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		  ,case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas + 60),0),cal_Inicio) ,121) + '':00:00.000'' end as timegroup_next 
				,cam_id, [User_id]
				,COUNT(cal_id) AS ntotal
				,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
				,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
				,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
				,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
				,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
				,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
				,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
				,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
				,ISNULL(SUM(cal_twait),0) as tque
				,ISNULL(SUM(cal_txfer),0)AS txfer
				,isnull(SUM(cal_tring),0) as tring
				,isnull(SUM(cal_tdialog),0) as tdialog        
				,isnull(SUM(cal_tnotas),0) as tnotes
				,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
				,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0) AS nhangup
				,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
				,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl                       
				,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
				,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
				,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto, 0 as idwg     
		  FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))         
		  WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		  -- para contar bien las llamadas manuales
		  and cal_manual in (0,2,3)
		  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto		  
		
	
	delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
		  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0  and nhangup=0     
    
    
    
    update A
    set idwg = B.idwg
    from #outboundData A
    inner join ccriaworkgroup_calid B on A.cal_id = B.cal_id        
        
                      
	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15         
                                      
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_out,cal_id,cal_puerto,idwg           
		  from #outboundData2 t
		  inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
     
                    
	drop table #outboundData2 
		
	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
				,[User_id]
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				into #timeDetailAgent
		  from ccLogAgentesDia
		  WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		  GROUP BY
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
                  
	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15         
      
	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
	select
		  min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav                         
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]
                                                  
	drop table #timeDetailAgent2

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
		  xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
		  ,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
		  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
		  ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
					 FROM #sessionTime
					 WHERE [user_id]=xTimeDetail.[user_id]
						   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		  ),0)AS t1                               
		  ,ISNULL((SELECT top 1 900
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t2                         
		  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t3
		  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t4
		  into #agentInformation
		  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
			 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother        
				from #timeDetailAgent
				group by timegroup,timegroup_next,user_id
				)xTimeDetail
	right join
	(select CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
					 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
		  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
				  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [user_id]
		  ,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
		  ,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
		  ,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
		  ,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
		  ,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
		  ,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
		  ,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl            
	from #inboundData
	FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])       
	group by
		  case when #inboundData.timegroup IS NOT NULL then #inboundData.timegroup
				 when #outboundData.timegroup IS NOT NULL then #outboundData.timegroup else NULL end
		  ,case when #inboundData.[user_id] IS NOT NULL then #inboundData.[user_id]
				  when #outboundData.[user_id] IS NOT NULL then #outboundData.[user_id] else NULL end
	) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null
	         
	drop table #timeDetailAgent


	 SELECT timegroup, ccCampsAgente.cam_id		
		, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN ((t1+t2+t3+t4) - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE 0 END) AS tresPos
	 INTO #ccGenOutCamp
	 FROM #agentInformation
		INNER JOIN ccCampsAgente ON (#agentInformation.[user_id] = ccCampsAgente.[user_id])
	 WHERE timegroup >= @from AND timegroup < @to
	 GROUP BY timegroup, ccCampsAgente.cam_id
			
	 select ROW_NUMBER() OVER(Order by row) as id,
		  #outboundData.row, #outboundData.timegroup as [date],0 as areaId,'''' as area
		 ,idwg as workgroupid,'''' as workgroup
		 ,#outboundData.cam_id as campaignid,'''' as campaign
		 ,[User_id] as userId,'''' as [user]		 
		 ,ntotal, nxfer, nno_agent, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog
		 ,1 as pos_tot, pos_time, nhangup, (tdialog + tnotes) as  tatencion
		 ,datepart(yy,convert(datetime,#outboundData.timegroup)) as [year]
		 ,datepart(mm,convert(datetime,#outboundData.timegroup)) as [mounth]
		 ,datepart(dd,convert(datetime,#outboundData.timegroup)) as [day]
		 ,datepart(hh,convert(datetime,#outboundData.timegroup)) as [hour]
		 ,datepart(mi,convert(datetime,#outboundData.timegroup)) as [minutes]
		 ,cal_id,phone_out,dateStartDetail
		 into #tempRepOutCalls
		 from #outboundData
		 left join #ccGenOutCamp  ON (#outboundData.timegroup = #ccGenOutCamp.timegroup and #outboundData.cam_id=#ccGenOutCamp.cam_id)
	 
	 SELECT 
      RANK() OVER(PARTITION BY row ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepOutCalls
      where row in
            (select row from #tempRepOutCalls temp GROUP BY temp.row HAVING Count(*) > 1 )
      
       update t
            set ntotal=0,nxfer=0,nno_agent=0,nanswer=0,nno_answer=0,nlost=0,nabnd_xfer=0,nabnd_ring=0,nabnd_dialog=0,tatencion=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
    
    delete #tempTime
    
    insert into #tempTime([rank],rowNumber,id)
    SELECT 
      RANK() OVER(PARTITION BY cal_id ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id      
      FROM #tempRepOutCalls
      where cal_id in
            (select cal_id from #tempRepOutCalls temp GROUP BY temp.cal_id HAVING Count(*) > 1 )
      
       update t
            set pos_tot=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
        
    --Borrar lo que esta para no repetir
	delete from RepOutCalls with(rowlock)
	where date >= @from AND date < @to 
    
     insert into RepOutCalls
		select date,areaId,area,workgroupid,workgroup,campaignid,campaign,userId,user,ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0),isnull(pos_time,0),nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls order by cal_id

     
	delete RepOutCalls
	where userId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls
	set areaId = idArea
	from RepOutCalls 
	left outer join ccriaareaworkgroup on (workgroupid = idwg)
	where idarea is not null 
	and [date] >= @from and [date] < @to

	delete RepOutCalls
	where areaId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls set
	area = (select areaname from ccriacat_areas where idarea = areaid)
	,workgroup = (select wgname from ccriacat_workgroup where idwg = workgroupid)
	,campaign = (select cam_descripcion from cccamps where cam_id = campaignid)
	,[user] = (select login from ccusers where user_id = userid)
	where [date] >= @from and [date] < @to					
		
	drop table #times
	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #ccGenOutCamp
	drop table #tempTime
	drop table #tempRepOutCalls	
	
end'
		EXEC(@sql)




		set @process ='ALTER PROCEDURE [dbo].[ccspRepSpececialAgent]------------------------'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAgent]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

--declare @action as tinyint,
--@from AS datetime = null,
--@to AS datetime = null

--select @action=1, @from=''2016-09-08 00:00:00'',@to=''2016-09-09 00:00:00''

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
	,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND (isnull(cal_xfer,''1900-01-01 00:00:00'') <> ''1900-01-01 00:00:00'')))THEN 1 ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID
	) cin on cin.date = ses.date and cin.User_id=ses.userId
	
end'
		EXEC(@sql)



		set @process ='drop  PROCEDURE [dbo].[ccsprepLogAgentriaseparate]----------'
		set @sql='if exists (select * from sys.procedures where name = ''ccsprepLogAgentriaseparate'')
		begin
			drop procedure ccsprepLogAgentriaseparate
		end'
		EXEC(@sql)


		set @process ='create PROCEDURE [dbo].[ccsprepLogAgentriaseparate]----------'
		set @sql='create PROCEDURE [dbo].[ccsprepLogAgentriaseparate]
@from as datetime = null,
@to as datetime = null
as

declare @dateNow datetime
set @dateNow=getdate()

declare @starttime datetime,@number int
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
set @number = 0

CREATE TABLE #times([ID] INT primary key, [Start] DATETIME,	[Stop] DATETIME	)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

while @number <= (datediff(mi,@starttime,@to)/60) begin
   insert into #times
   select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
   set @number = @number +1
end

create table #tempFechasR(id int,fecha datetime,tiempo int)

create table #tempccLogAgentesDia(
	row int not null,user_id int not null,TipoStatusAge_id tinyint not null,
	tStatus int not null,dateIni datetime not null,dateEnd datetime not null,
	currentStatus int
)

create table #timeDetailAgent(	
	[User_id] int not null,
	dateStartDetail datetime null,dateEndDetail datetime null,dateNext datetime null
	,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null,
	tunknown2 decimal(10,3) 
	)


insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd,currentStatus
from ccLogAgentesDia 
WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to 

delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id	
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,
TipoStatusAge_id,tStatus,dateIni, dateEnd
	 into #tempccLogAgentesDia2 
from #tempccLogAgentesDia

insert into #timeDetailAgent
select A.user_id,A.dateIni,A.dateEnd,S.dateIni dateNext,
	CONVERT(smalldatetime,CONVERT(varchar(13),A.dateIni,121)+ '':00'',121) AS timegroup,
	case when A.dateEnd=CONVERT(smalldatetime,CONVERT(varchar(13),A.dateEnd,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),A.dateEnd,121)+ '':00'',121)
	else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,A.dateEnd),121)+ '':00'',121) end AS timegroup_next,
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0 
	when A.TipoStatusAge_id=25 and S.TipoStatusAge_id=5 or A.TipoStatusAge_id=5 and S.TipoStatusAge_id=25  then 0
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2	
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id	
	WHERE  A.dateIni>=@from AND A.dateIni<@to

update #timeDetailAgent set tunknown2=0  where tunknown2>2.5

insert into #tempFechasR select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id

	insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall)
	select 
		User_id,
		B.fecha as dateStartDetail,
		@dateNow as dateEndDetail,
		CONVERT(smalldatetime,CONVERT(varchar(13),B.fecha,121)+ '':00'',121) AS timegroup,
		case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
		else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end AS timegroup_next
		,case when currentStatus=1 then tiempo else 0 end as tunknown,
		case when currentStatus=2 then tiempo else 0 end as tnot_av,
		case when currentStatus=3 then tiempo else 0 end as tav,
		 0,0,0,0
		from #tempccLogAgentesDia A
		inner JOIN #tempFechasR B ON A.dateEnd=B.fecha  and A.User_id=B.id WHERE currentStatus not in (-2,0)	

select * into #timeDetailAgent2 from #timeDetailAgent where datediff(hh,timegroup,timegroup_next)>1
delete #timeDetailAgent where datediff(hh,timegroup,timegroup_next) > 1

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall)
	select
	 min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	 ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

select * from  #timeDetailAgent order by User_id,dateStartDetail

drop table #tempFechasR
drop table #timeDetailAgent
drop table #times
drop table #tempccLogAgentesDia
--drop table #timeDetailAgent
--drop table #timeDetailAgent2
    				'
		EXEC(@sql)


		set @process ='INSERTAR FILTROS PARA REPORTE SESSIONESPOR INTERVALO'
		set @sql='
		INSERT INTO ReportsFilters (reportName,filterName,id) values (''Sessions by Interval'',''users'',2060);
		INSERT INTO ReportsFiltersMenus (idReport,filterMenuName) values(2060,''date'');
		INSERT INTO ReportsFiltersMenus (idReport,filterMenuName) values(2060,''groupBy'');
		INSERT INTO ReportsFiltersMenus (idReport,filterMenuName) values(2060,''filterby'');




		INSERT INTO ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
		values(2060	,''Sessions by Interval'',1,''user'','''','''','''',''sum([sessionTimeSeconds])'',''Session time per user'',1)

		INSERT INTO ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
		values(2060	,''Sessions by Interval'',2,''year|month|day'','''','''','''',''sum([sessionTimeSeconds])'',''Session time per user by day'',1)






		INSERT INTO GroupByReports([id],[columns],[groupByColumns]) values 
		(2060, ''max([login]):login|userId|max([user]):user|max([extension]):extension|sum([sessionTime]):sessionTime'' ,''userId'')


		INSERT INTO ReportsTotals (id,totalColumns) values(2060,''sum:sessionTime'')
				'
		EXEC(@sql)


		set @process =''
		set @sql=''
		EXEC(@sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		set @actualVersion = @version
		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
if @actualVersion = @version begin
	begin tran
	begin try

	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off