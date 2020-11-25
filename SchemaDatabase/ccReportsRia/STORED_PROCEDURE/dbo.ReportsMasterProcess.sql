CREATE procedure [dbo].[ReportsMasterProcess] 
@from as datetime=null,@WithMedia bit =1,@to as datetime=null
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


print '---Get schedule_id and @scheduleTime ----'
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name='ReportsMasterProcess'



print '---Kill Process Replication Merge Agent----'
while exists(SELECT	s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like '%Replication Merge Agent%'	
	and DB_NAME(p.dbid)='ccReportsRia'	
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
	and s.[program_name] like '%Replication Merge Agent%'
	and DB_NAME(p.dbid)='ccReportsRia'

	select * from @sessionKIll

	select @i=1,@count =COUNT(*) from @sessionKIll
	while @i<=@count begin
		select @sessionId=sessionId from @sessionKIll where id=@i
		SET @SQL = 'KILL ' + CAST(@sessionId as varchar(max))
		begin try
			EXEC (@SQL)
		end try
		begin catch
			print @SQL+ ' is proccess end'
		end catch
		set @i=@i+1
	end
	delete from @sessionKIll
end

print '--------------- Get Jobs Replication ------------------------------'
create table #replications ([name] nvarchar(100), flag bit)

;

with jobNotStart as(
select distinct A.[name] from msdb.dbo.sysjobs A 
	inner join PublicationLowLoad B on A.[name] like '%'+B.namePublication+'%'		
	where A.[name] like '%ccReportsRia- 0%' and A.[name] like '%CCenterRia%'	
--union all
--select distinct A.[name] from msdb.dbo.sysjobs A 
--	inner join PublicationHighLoad B on A.[name] like '%'+B.namePublication+'%'	
--	where A.[name] like '%ccReportsRia- 0%' and A.[name] like '%CCenterRia%'
)

insert into #replications
select distinct A.[name],0 from msdb.dbo.sysjobs A 
	where A.[name] like '%ccReportsRia- 0%' and A.[name] like '%CCenterRia%'	
	and A.name not in(select name from jobNotStart)	

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like '%ccReportsRia- 0%' and [name] like '%CCRecorderRIA%' order by [name]

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
		print 'sp_start_job '+@replicationName
	end
	else begin
		print 'Job is Init '+@replicationName
	end

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY '00:00:03'		

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
		WAITFOR DELAY '00:00:01'
		print 'In Progress Job in ReplicationName: '+@replicationName
		if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
			print 'Stop Job in ReplicationName: '+@replicationName
			break	
		end
	end
	print 'Progress End Job in ReplicationName: '+@replicationName
end

drop table #replications

print '--------------------------- Creacion tablas cada domingo ---------------------------'
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = 'logsReportsMaster') begin
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

print '--------------------------- Termina Creacion tablas cada domingo ---------------------------'


declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

insert into @tableArticle(nameArticle,objectId)
SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
inner join sys.tables t on t.name=Art.name

insert into @tableTrigger
select t.name as nameTrigger from @tableArticle Art
inner join sys.triggers  t on Art.objectId=t.parent_id
where name not like 'MSmerge_%'

select @i=1,@count =count(*) from @tableTrigger
while @i<=@count
begin
	select @name = nameArticle  from @tableTrigger where id=@i
	set @sql ='DROP TRIGGER '+ @name 
	exec (@sql)
	set @i = @i+1
end

print '--------------------------- DROP TRIGGER Tables ---------------------------'


-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------			
exec ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=@scheduleTime,@dateStart=@dateStart

print '---#reinitmergepullsubscription----'
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
select distinct s.name, ma.publisher_db, ma.publication, 'false', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where 
(mh.comments like '%You must reinitialize the subscription (without upload)%' or
mh.comments like  '%The Merge Agent failed because the schema of the article at the Publisher does not match the schema of the article at the Subscriber%')
and mh.time >= @lastTenMinuteFirst
and ma.subscriber_db = 'ccReportsRia'

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
end