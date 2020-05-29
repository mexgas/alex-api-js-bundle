/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jose Velasco. Jesus Gallardo
Date: 2015/03/10
Description:

	Alter SP -- procedure ccspRepOutKPI
	Alter SP -- GetReportMenus
	Alter SP -- ccspRepAgentSession
	Alter SP --	ccspRepAgentNotReady
    Alter SP --	ReportsMasterProcess
Database: ccReportsRia
Required version: 25

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 26

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process ='update time schedule default 20 minutes'
	set @sql = 'declare @schedule_id int,@nameSchudule sysname,@job_id uniqueidentifier,@scheduleTime int

select  @job_id=A.job_id,@schedule_id=C.schedule_id, @nameSchudule=C.name,@scheduleTime=C.freq_subday_interval
      FROM msdb.dbo.sysjobs A
      LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
      INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
      where A.name=''ReportsMasterProcess''

EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = 20'
	EXEC(@sql)

	set @process ='Update ccsettings time replication'
	set @sql = 'update ccsettings set valor=''10|10'' where setting_id=28'
	EXEC(@sql)

	set @process ='Alter ----- procedure ReportsMasterProcess '
	set @sql = 'ALTER procedure [dbo].[ReportsMasterProcess] as

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100), @replicationName nvarchar(100)
declare @numOfReports int,@numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int,@minReports int

---shedule
declare @schedule_id int,@nameSchudule sysname,@job_id uniqueidentifier,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

--------------------------- Creacion tablas cada domingo ---------------------------
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = ''logsReportsMaster'')
			drop table logsReportsMaster

	create table [logsReportsMaster](
		[id] int identity not null primary key,
		[name] varchar(100) not null,
		[status] tinyint not null,
		[dateStart] datetime not null,
		[dateEnd] datetime not null,
		[error] varchar(max) not null,
		[maxTime] int not null)

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster1] ON [dbo].[logsReportsMaster]
	(
		[name] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster2] ON [dbo].[logsReportsMaster]
	(
	[status] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster3] ON [dbo].[logsReportsMaster]
	(
	[maxTime] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

end

--------------------------- Termina Creacion tablas cada domingo ---------------------------

set nocount on

set @dateStart = getdate()
set @delay = 0
set @strDelay = ''''
set @reportName = ''''
set @replicationName = ''''
set @numOfReports = 0
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 0
set @minReports = 0
set @scheduleTime = 10

--- obtiene el job_id, y el nombre del schedule_id asocioado al job reports Master
select  @job_id=A.job_id,@schedule_id=C.schedule_id, @nameSchudule=C.name,@scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcess''

-- obtiene los valores de los settings para el tiempo ejecucion de las replicas  y los jobs
select @minReplication = cast(substring(valor, 0, charindex(''|'',valor)) as int) from ccsettings where setting_id = 28
select @minReports = cast(substring(valor, charindex(''|'',valor) + 1, len(valor)) as int) from ccsettings where setting_id = 28

---- revisar los tiempos y actulizar el setting
if (@minReplication + @minReports) > @scheduleTime
begin
	set @scheduleTime= @minReplication + @minReports
	EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
end

set @minReplication = @minReplication * 60

-------------------- ejecuccion de las replicas -----------------------------------------

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCenterRia%''

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCRecorderRia%'' order by [name]

select @numOfReplications = count(*) from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@repDelay)) + convert(VARCHAR(6),@repDelay),3,0,'':''),6,0,'':'')

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock)
	set flag = 1
	where [name] = @replicationName

	waitfor delay @repStrDelay
end

drop table #replications

-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------

declare @descError nvarchar(max)
declare @i int,@count int
declare @name sysname,@sql nvarchar(max)
DECLARE @dateBegin DATETIME,@dateSP datetime


create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] <> ''ccspRepCatalogos''

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count
begin
	select @name = name from #tmpProcedureReports where id=@i

	set @sql =''EXEC ''+ @name +'' @action=1''
	set @dateSP = getdate()
	begin try

		exec (@sql)
		WAITFOR DELAY ''00:00:01''

		while(SELECT count(*)
			FROM sys.dm_exec_requests a
			INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
			INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d WHERE a.session_id > 50
			AND a.session_id = @@SPID and d.text = @sql) > 0
		begin
			WAITFOR DELAY ''00:00:01''
		end

		if( datediff(mi,@dateStart,getdate()) > @scheduleTime) begin
		set @scheduleTime = @scheduleTime+1
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime,error=''Increment time shuduler ''+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart=''19000101'' and dateEnd=''19000101''

			set @minReplication=@minReplication/60
			EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
			update ccsettings set valor=convert(varchar(max),@minReplication)+''|''+convert(varchar(max),@minReports+1),descripcion = ''Min. replicas | Min. reportes este se modifica automaticamente revisar tabla de logsReportsMaster, (Total ''+convert(varchar(max),@scheduleTime) +'' Minutos)'' where setting_id = 28
			break
		end
		set @i = @i+1
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
	end try
	begin catch
		select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
		set @i = @i+1
	end catch
end

drop table #tmpProcedureReports

-------------------- Reinicializa las subcripciones en caso de caducar-----------------------------------------

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where mh.comments like ''%You must reinitialize the subscription (without upload)%''
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''ccReportsRia''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@sql)

	set @process ='----- procedure GetReportMenus '
	set @sql = 'ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint,
	@activeCRM tinyint=0,
	@activeEmail tinyint=0
AS
BEGIN

	select menu_id,
		substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
		nullif(parent,menu_id) as parent,Nivel,ordengral
		into #tempCCMenus from ccMenus with(nolock)
		where type = 3 and menu_id >= 2000 and(
			(menu_id not in (
			3130,3131,3132,3133,3134,3135,3136,
			8050,8060,8061,8062,8063,8070,8071,8072,8080,
			9000,9010,
			10000,10010,10020,10030,10040
			))
			or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
			or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
			or  (@activeCRM = 1 and menu_id in (9000,9010) )
			or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
			)
			order by menu_id


	;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent)
	AS
	(
		select
			distinct b.Nivel as Nivel,
			b.menu_descrip as menu_descrip,
			b.menu_id as menu_id,
			b.ordengral as ordengral,
			b.parent as parent
			from #tempCCMenus as b
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
		UNION ALL
	--RECURSIViDAD
		select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent
			from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
	)

	select distinct Nivel,menu_descrip,menu_id,ordengral,parent into #tempCCMenusUser from ccMenusUserRec order by menu_id

	select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType from #tempCCMenusUser A
	where  menu_id not in
		(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
	order by menu_id

	drop table #tempCCMenus
	drop table #tempCCMenusUser

END'
	EXEC(@sql)

	set @process ='ALTER ---------- procedure ccspRepOutKPI '
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutKPI]
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
		select CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour, cam_id, '''' as campaign,
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
		case when statusCall_id = 5 then 1 else 0 end  as AbandonedCalls,
		0.00 as AbandonedPctg,
		0.00 as AvgTimeBtwCalls
		from ccocallsout with(index(IX_ccoCallsOut_2),nolock)
		where cal_inicio >= @from and cal_inicio < @to
		group by statusCall_id, cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121), cal_tXfer, cal_tDialog
	) as final
	group by dateHour, cam_id, campaign
	order by dateHour, cam_id

	update RepOutKPI with(rowlock)
	set campaign = isnull(b.cam_descripcion,'''')
	from RepOutKPI a
	left join ccCamps b
	on a.campaignId = b.cam_id
	where date >= @from AND date < @to

end'
	EXEC(@sql)

	set @process ='ALTER -------- procedure ccspRepAgentSession '
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSession]
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
   delete from RepAgentSession with(rowlock) where date >= @from and date < @to

	  select *  into #tempSession from(
	   select a.extension, a.user_id, a.fecha as ''subLogin'',
		(
			select isnull(max(Fecha),getdate()) from ccLogLogin b with(nolock)
				where b.user_id = a.user_id and b.tipomov = 0 and  b.fecha >= a.fecha and b.fecha <=
				(
					select isnull(min(fecha),''99991231 23:59:59.998'') from ccLogLogin with(nolock)
					where user_id = b.user_id and tipomov = 1 and fecha > a.fecha)
			) as ''subLogout''
		from ccLogLogin a where a.tipomov=1 and fecha >= @from and fecha <= @to)x


	select distinct subLogin as date, u.login as userLogin, sessiontime.user_id,
   u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, subLogin as loginTime,
   subLogout as logoutTime,
   datediff(ss,subLogin,subLogout) as sessionTime,
   datediff(ss,subLogin,subLogout) as sessionTimeSeconds,
   datepart(yyyy,subLogin), datepart(mm,subLogin), datepart(dd,subLogin),
   datepart(hh,subLogin), datepart(mi,subLogin)
	from (
	select  a.extension, a.user_id,subLogin,
	(
		select isnull(min(fecha),subLogout) from ccLogLogin where a.user_id= user_id and fecha>subLogin and fecha <subLogout
	) subLogout
	 from #tempSession a
	)sessiontime
	 left join ccusers u on (sessiontime.user_id = u.user_id)




  SELECT TOP 0 * INTO #temp_RepAgentSession FROM RepAgentSession

  INSERT INTO #temp_RepAgentSession
  select subLogin as date, u.login as userLogin, sessiontime.user_id,
  u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, subLogin as loginTime,
  subLogout as logoutTime,
  datediff(ss,subLogin,subLogout) as sessionTime,
  datediff(ss,subLogin,subLogout) as sessionTimeSeconds,
  datepart(yyyy,subLogin), datepart(mm,subLogin), datepart(dd,subLogin),
  datepart(hh,subLogin), datepart(mi,subLogin)
  from(select a.extension, a.user_id, a.fecha as ''subLogout'',
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
    ) as ''subLogin''
    from ccLogLogin a
    where a.tipomov=0
    and fecha >= @from
    and fecha <= @to
   ) as sessiontime
   left join ccusers u on (sessiontime.user_id = u.user_id)
   where datediff(day,subLogin,subLogout) >= 1
  order by user_id, loginTime

  UPDATE a with (rowlock)
  SET a.logoutTime = b.logoutTime,
  a.sessionTime = b.sessionTime,
  a.sessionTimeSeconds = b.sessionTimeSeconds
  FROM #temp_RepAgentSession b
  INNER JOIN RepAgentSession a
  on a.userId = b.userId
  and a.loginTime = b.loginTime
  and a.logoutTime <> b.logoutTime

  drop table #tempSession
  DROP TABLE #temp_RepAgentSession


end'
	EXEC(@sql)


	set @process ='ALTER ------ procedure ccspRepAgentNotReady'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

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

if @action = 1
begin
	delete from RepAgentNotReady with(rowlock)
	where date >= @from AND date < @to

	-- Session Time
	select sessiontime.user_id as user_id, subLogin as login,
	subLogout as logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''subLogin'',
	(select isnull(max(Fecha),getdate())
		from ccLogLogin b with(nolock)
		where b.user_id = a.user_id and
		b.tipomov = 0 and
		b.fecha >= a.fecha and
		b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 1 and
		fecha > a.fecha)
	) as ''subLogout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where u.login is not null
	order by user_id, login

	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime

	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id as user_id, subLogin as login,
	subLogout as logout, extension
	from(select a.extension, a.user_id, a.fecha as ''subLogout'',
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
	) as ''subLogin''
	from ccLogLogin a
	where a.tipomov=0
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where datediff(day,subLogin,subLogout) >= 1
	order by user_id, login

	UPDATE a with (rowlock)
	SET a.logout = b.logout
	FROM #temp_RepAgentSession b
	INNER JOIN #sessionTime a
	on a.user_Id = b.user_Id
	and a.login = b.login
	and a.logout <> b.logout

	DROP TABLE #temp_RepAgentSession

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
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
					 FROM ccLogAgentesDia with(nolock, index(IX_ccLogAgentesDia))
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]

	SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
		, [user_id], tiponotready_id
		, COUNT(tStatus) as [count], SUM(tStatus) as [time]
		--, sum( case when separado in (0,3) then 1 else null end ) as amountReal --amount Real
	 into #notReady
	 FROM ccLogAgentesNotReady with(nolock, index(IX_ccLogAgentesNotReady_2))
	 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id], tiponotready_id


	insert into RepAgentNotReady
	select a.timegroup as date, c.login, a.user_id as [userId], c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres as [user],
	a.tlog as sessionTime,
	isnull(d.tiponotready_id,0) tiponotready_id, isnull(d.descripcion,'''') descripcion,
	isnull(d.descripcion,'''') + ''_Count'' as descripcion_count, isnull([count],0) count, isnull(d.descripcion,'''') + ''_Time'' as descripcion_time,
	isnull([time],0) time, isnull([time],0) as timeSeconds--, amountReal
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



	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #notReady

end'
	EXEC(@sql)

			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

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