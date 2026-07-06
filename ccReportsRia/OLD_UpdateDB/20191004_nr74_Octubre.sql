SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 74

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		

		SET @process = 'CW-3494 Replication Create table PublicationHighLoad'
		SET @sql = 'if not exists(select * from sys.tables where name=''PublicationHighLoad'') begin
	create table PublicationHighLoad(namePublication varchar(255))
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Create table PublicationLowLoad'
		SET @sql = 'if not exists(select * from sys.tables where name=''PublicationLowLoad'') begin
	create table PublicationLowLoad(namePublication varchar(255))
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Insert PublicationHighLoad'
		SET @sql = 'if not exists(select * from PublicationHighLoad) begin
	insert into PublicationHighLoad values(''LogAgentesDia'')
	insert into PublicationHighLoad values(''LogAgentesDia_Dialog'')
	insert into PublicationHighLoad values(''ccRIAWorkGroup_Calid'')
	insert into PublicationHighLoad values(''CallsOutSource'')
	insert into PublicationHighLoad values(''CallsOut'')
	insert into PublicationHighLoad values(''LogDials'')
	insert into PublicationHighLoad values(''CallsIn'')
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Insert PublicationLowLoad'
		SET @sql = 'if not exists(select * from PublicationLowLoad) begin
	insert into PublicationLowLoad values(''Chats'')
	insert into PublicationLowLoad values(''ConversationMail'')
	insert into PublicationLowLoad values(''Conversationtweet'')
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication DROP PROCEDURE ReportsMasterProcessPublicationHighLoad'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ReportsMasterProcessPublicationHighLoad'')
    begin
        DROP PROCEDURE ReportsMasterProcessPublicationHighLoad;
    end'
		EXEC (@sql)

		SET @process = 'CW-3494 ReplicationDROP PROCEDURE ReportsMasterProcessPublicationLowLoad '
		SET @sql = 'if exists (select * from sys.procedures where name = N''ReportsMasterProcessPublicationLowLoad'')
    begin
        DROP PROCEDURE ReportsMasterProcessPublicationLowLoad;
    end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication '
		SET @sql = 'CREATE procedure [dbo].[ReportsMasterProcessPublicationHighLoad]
as

set nocount on

declare @replicationName varchar(max)
declare @dateStart datetime
declare @schedule_id int,@scheduleTime int
declare @i int,@count int
declare @SQL varchar(max)


set @dateStart = getdate()
set @scheduleTime = 5

print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcessPublicationHighLoad''

print ''--------------- Get Jobs Replication ------------------------------''
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
	select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 
	inner join PublicationHighLoad B on A.[name] like ''%''+B.namePublication+''%''	
	where A.[name] like ''%ccReportsRia- 0%'' and A.[name] like ''%CCenterRia%''
	

select @count=count(*) from #replications

while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@dateStart,getdate())<(@scheduleTime*60)
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0
	
	if (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) <>4 
	or not exists(SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc	)
	
	begin
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		print ''sp_start_job ''+@replicationName
	end
	else begin
		print ''Job is Init ''+@replicationName
	end

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY ''00:00:03''		

	while (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) = 4
	begin	
		WAITFOR DELAY ''00:00:01''
		print ''In Progress Job in ReplicationName: ''+@replicationName
		if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
			print ''Stop Job in ReplicationName: ''+@replicationName
			break	
		end
	end
	print ''Progress End Job in ReplicationName: ''+@replicationName
end

drop table #replications
'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Create SP ReportsMasterProcessPublicationLowLoad'
		SET @sql = 'create procedure [dbo].[ReportsMasterProcessPublicationLowLoad]
as

set nocount on

declare @replicationName varchar(max)
declare @dateStart datetime
declare @schedule_id int,@scheduleTime int
declare @i int,@count int
declare @SQL varchar(max)



set @dateStart = getdate()
set @scheduleTime = 15

print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcessPublicationLowLoad''

print ''--------------- Get Jobs Replication ------------------------------''
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
	select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 
	inner join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''	
	where A.[name] like ''%ccReportsRia- 0%'' and A.[name] like ''%CCenterRia%''	

select @count=count(*) from #replications

while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@dateStart,getdate())<(@scheduleTime*60)
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0
	
	if (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) <>4 
	or not exists(SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc	)
	
	begin
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		print ''sp_start_job ''+@replicationName
	end
	else begin
		print ''Job is Init ''+@replicationName
	end

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY ''00:00:03''		

	while (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) = 4
	begin	
		WAITFOR DELAY ''00:00:01''
		print ''In Progress Job in ReplicationName: ''+@replicationName
		if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
			print ''Stop Job in ReplicationName: ''+@replicationName
			break	
		end
	end
	print ''Progress End Job in ReplicationName: ''+@replicationName
end

drop table #replications
'
		EXEC (@sql)



		SET @process = 'CW-3494 Replication Alter SP ReportsMasterProcess '
		SET @sql = 'ALTER procedure [dbo].[ReportsMasterProcess] 
@from as datetime=null,@WithMedia bit =1
as

set nocount on

declare @replicationName varchar(max)
declare @dateStart datetime,@dateSP datetime
declare @schedule_id int,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)

set @dateStart = getdate()
set @scheduleTime = 10


print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcess''



print ''---Kill Process Replication Merge Agent----''
while exists(SELECT	s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like ''%Replication Merge Agent%''	
	and DB_NAME(p.dbid)=''ccReportsRia''	
) begin
	insert into @sessionKIll(id,sessionId)
	
	SELECT	ROW_NUMBER() OVER(ORDER BY s.session_id) AS Row#, s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like ''%Replication Merge Agent%''
	and DB_NAME(p.dbid)=''ccReportsRia''

	select * from @sessionKIll

	select @i=1,@count =COUNT(*) from @sessionKIll
	while @i<=@count begin
		select @sessionId=sessionId from @sessionKIll where id=@i
		SET @SQL = ''KILL '' + CAST(@sessionId as varchar(max))
		begin try
			EXEC (@SQL)
		end try
		begin catch
			print @SQL+ '' is proccess end''
		end catch
		set @i=@i+1
	end
	delete from @sessionKIll
end

print ''--------------- Get Jobs Replication ------------------------------''
create table #replications ([name] nvarchar(100), flag bit)

if @WithMedia = 0 begin
	insert into #replications
	select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCenterRia%''
	and [name] not like ''%Chats%'' and [name] not like ''%ConversationMail%'' and [name] not like ''%Conversationtweet%''
end
else begin
	insert into #replications
	select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCenterRia%''
end


insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCRecorderRia%'' order by [name]

select @count=count(*) from #replications

while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@dateStart,getdate())<(@scheduleTime*60)
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0
	
	if (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) <>4 
	or not exists(SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc	)
	
	begin
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		print ''sp_start_job ''+@replicationName
	end
	else begin
		print ''Job is Init ''+@replicationName
	end

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY ''00:00:03''		

	while (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) = 4
	begin	
		WAITFOR DELAY ''00:00:01''
		print ''In Progress Job in ReplicationName: ''+@replicationName
		if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
			print ''Stop Job in ReplicationName: ''+@replicationName
			break	
		end
	end
	print ''Progress End Job in ReplicationName: ''+@replicationName
end

drop table #replications

print ''--------------------------- Creacion tablas cada domingo ---------------------------''
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = ''logsReportsMaster'') begin
		drop table logsReportsMaster
	end

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

print ''--------------------------- Termina Creacion tablas cada domingo ---------------------------''


declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

insert into @tableArticle(nameArticle,objectId)
SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
inner join sys.tables t on t.name=Art.name

insert into @tableTrigger
select t.name as nameTrigger from @tableArticle Art
inner join sys.triggers  t on Art.objectId=t.parent_id
where name not like ''MSmerge_%''

select @i=1,@count =count(*) from @tableTrigger
while @i<=@count
begin
	select @name = nameArticle  from @tableTrigger where id=@i
	set @sql =''DROP TRIGGER ''+ @name 
	exec (@sql)
	set @i = @i+1
end

print ''--------------------------- DROP TRIGGER Tables ---------------------------''


-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------			
create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] not in(''ccspRepCatalogos'',''ccsprepLogAgentriaseparate'')

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count and datediff(mi,@dateStart,getdate()) < @scheduleTime
begin
	select @name = name from #tmpProcedureReports where id=@i
	
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))

	set @sql =''EXEC ''+ @name +'' @action=1,@from=''''''+convert(varchar(max),@from,121)+''''''''
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

		if( datediff(ss,@dateStart,getdate()) > @scheduleTime*60) begin		
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime+1,error=''Increment time shuduler ''+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart=''19000101'' and dateEnd=''19000101''			
			break
		end		
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
	end try
	begin catch
		select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''		
	end catch

	set @i = @i+1
end

drop table #tmpProcedureReports

print ''---#reinitmergepullsubscription----''
declare @lastTenMinuteFirst datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-@scheduleTime*2,getdate())

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select distinct s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where 
(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
mh.comments like  ''%The Merge Agent failed because the schema of the article at the Publisher does not match the schema of the article at the Subscriber%'')
and mh.time >= @lastTenMinuteFirst
and ma.subscriber_db = ''ccReportsRia''

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0
		
		exec sp_reinitmergepullsubscription  @publisher = @publisher_reinit,    @puSblisher_db = @publisher_db_reinit,    @publication = @publication_reinit,    @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription

if DATEDIFF(ss,@dateStart,getdate())>@scheduleTime*60 begin
	set @scheduleTime=@scheduleTime+1
	if  @scheduleTime < 59 begin
		EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
	end	
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Create Job ReportsMasterProcessPublicationHighLoad'
		SET @sql = 'USE [msdb]

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ReportsMasterProcessPublicationHighLoad'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationHighLoad'', @delete_unused_schedule=1

/****** Object:  Job [ReportsMasterProcess]    Script Date: 04/10/2019 12:52:44 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/10/2019 12:52:44 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationHighLoad'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcess'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 04/10/2019 12:52:44 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessPublicationHighLoad'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Create Job ReportsMasterProcessPublicationLowLoad'
		SET @sql = 'USE [msdb]

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ReportsMasterProcessPublicationLowLoad'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/10/2019 12:52:44 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcess'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 04/10/2019 12:52:44 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessPublicationLowLoad'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC (@sql)


		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
