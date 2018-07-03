/*
Autor: Jesus Gallardo
Descripcion:


Version requerida: 48
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 49
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'Alter SP ReportsMasterProcessAVRS'
	set @Sql= 'ALTER procedure [dbo].[ReportsMasterProcessAVRS] as

declare @replicationName nvarchar(100)
declare @timeSch int
declare @now datetime
set nocount on

set @replicationName = ''''
set @now=getdate()




declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
DECLARE @SQL nvarchar(1000)

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
	and DB_NAME(p.dbid)=''CCRecorderRIA''	
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
	and DB_NAME(p.dbid)=''CCRecorderRIA''

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




create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%CCRecorderRIA- 0%'' and [name] like ''%CCenterRia%'' order by [name]

select @count=count(*),@timeSch=600 from #replications

while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@now,getdate())<@timeSch
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
	) <>4 begin
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		print ''sp_start_job ''+@replicationName
	end
	else begin
		print ''Job is Init ''+@replicationName
	end

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY ''00:00:01''		

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
		if datediff(ss,@now,getdate())>(@timeSch/@count) begin
			print ''Stop Job in ReplicationName: ''+@replicationName
			break 
		end
	end
end

drop table #replications
-------------------------Para busquedas en finder

if not exists (select * from sys.indexes where name = N''IX_ccRIAWorkGroupUsersConsulta2'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta''))
begin
	CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta]
		(
			[IDWG] ASC,
			[User_id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
end
-----------------------


declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-120,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,120,@lastTenMinuteFirst)

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
mh.comments like  ''%Start the Snapshot Agent to generate the snapshot for this publication%'')
--and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
--and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''CCRecorderRIA''
--order by mh.time desc

select * from #reinitmergepullsubscription

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		--EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit
		EXEC sp_reinitmergesubscription @publication = @publication_reinit, @subscriber = @publisher_reinit, @subscriber_db = ''CCRecorderRIA'', @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@sql)
	


 	set @process = 'CW-  VERSION 120.11 Alter Table  MigrationAVRSReports.status'
    set @Sql= 'if exists(select * from sys.tables where name=''MigrationAVRSReports'') begin
	alter table MigrationAVRSReports alter column [status] int
end'
    EXEC(@Sql)

    set @process = 'CW-  VERSION 120.11 JOb [AVRSReports Merge Replication] '
    set @Sql= 'USE [msdb]

/****** Object:  Job [AVRSReports Merge Replication]    Script Date: 23/06/2018 11:08:46 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''AVRSReports Merge Replication'')
EXEC msdb.dbo.sp_delete_job @job_name=N''AVRSReports Merge Replication'', @delete_unused_schedule=1

/****** Object:  Job [AVRSReports Merge Replication]    Script Date: 23/06/2018 11:08:46 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:08:46 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRSReports Merge Replication'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AVRSReports Merge Replication]    Script Date: 23/06/2018 11:08:46 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''AVRSReports Merge Replication'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''
declare @id int,@i int,@count int
declare @publicationName varchar(max)
declare @dateStart datetime,@dateNow datetime
declare @status int
declare @maxId int,@minId int

--delete from MigrationAVRSReports

select @maxId=isnull(max(id),99),@dateNow =getdate(),@i=0 FROM MigrationAVRSReports

insert into MigrationAVRSReports
SELECT ROW_NUMBER() OVER(ORDER BY name desc)+@maxId AS id, P.name as [description],0 as status,'''''''' as error,''''1901-01-01'''' as dateStart,''''1901-01-01'''' as dateEnd FROM dbo.sysmergepublications P
left join MigrationAVRSReports M on P.name=M.[description]
where  P.publisher_db=''''CCRecorderRIA'''' and M.[description] is null 

select @minId=ISNULL(min(id),99), @maxId=isnull(max(id),99),@count=COUNT(*) FROM MigrationAVRSReports

select * FROM MigrationAVRSReports

if exists(select * FROM MigrationAVRSReports where status in(0,1)) begin

	while @i<@count and DATEDIFF(ss,@dateNow,getdate())<59 begin
		select @publicationName=[description],  @dateStart  = dateStart, @status = status from MigrationAVRSReports  with (nolock) where id=@minId+@i
		
		if @status = 2 begin		 
		 set @i=@i+1
		 continue;
		end

		if (not exists( select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCRecorderRIA'''' and b.id = a.agent_id 
			and a.runstatus = 2 and b.publication = @publicationName and a.start_time < convert(datetime,convert(varchar(10),@dateStart,121)))	   
			) begin
				 update MigrationAVRSReports with (rowlock) set [status] = 1, [dateStart] = getdate() where id=@minId+@i     
				 
				 exec sp_startpublication_snapshot @publication = @publicationName

				 WAITFOR DELAY ''''00:00:01''''

				while not exists(
					select *
					from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
					where b.publisher_db = ''''CCRecorderRIA'''' and b.id = a.agent_id 
					and a.runstatus = 2
					and b.publication = @publicationName and a.start_time > convert(datetime,convert(varchar(10),@dateStart,121))	
				)
				begin
					WAITFOR DELAY ''''00:00:01''''
					if DATEDIFF(ss,@dateNow,getdate())>=59 begin
						break
					end
				end
				update MigrationAVRSReports with (rowlock) set [status] = 2, [dateEnd] = getdate() where id=@minId+@i
		end
		else if(@status = 1 and
				exists( select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
						where b.publisher_db = ''''CCRecorderRIA'''' and b.id = a.agent_id 
						and a.runstatus = 2 and b.publication = @publicationName and a.start_time > convert(datetime,convert(varchar(10),@dateStart,121))
						)
			) begin 	
			update MigrationAVRSReports with (rowlock) set [status] = 2, [dateEnd] = getdate() where id=@minId+@i  and status=1
		end		
		set @i=@i+1
		
	end

end
'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130625, 
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
    EXEC(@Sql)

    set @process = 'CW-  VERSION 120.11 JOb AVRSSaveWorkGroupCalid'
    set @Sql= 'USE [msdb]

/****** Object:  Job [AVRSSaveWorkGroupCalid]    Script Date: 23/06/2018 11:09:44 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''AVRSSaveWorkGroupCalid'')
EXEC msdb.dbo.sp_delete_job @job_name=N''AVRSSaveWorkGroupCalid'', @delete_unused_schedule=1

/****** Object:  Job [AVRSSaveWorkGroupCalid]    Script Date: 23/06/2018 11:09:44 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:09:44 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRSSaveWorkGroupCalid'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''This Job allows everyday, save the relations  between ccRIAWorkGroup_Calid and recordings in the new column added in RIAGrabacion (IDWG) so that customers can check the recordings without any problem after the purification process in  ccRIAWorkGroup_Calid'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [/]    Script Date: 23/06/2018 11:09:44 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''/'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @idWgs nvarchar(max) ,@idWgsCorchetes nvarchar(max) ,@sql nvarchar(max)
SELECT @idWgsCorchetes=COALESCE(@idWgsCorchetes + '''', '''', '''''''') + convert(varchar(max),QUOTENAME(IDWG)) FROM ccRIACat_WorkGroup
SELECT @idWgs=COALESCE(@idWgs + ''''+ '''', '''''''') + ''''case when '''' + convert(varchar(max),QUOTENAME(IDWG)) + '''' is null then '''''''''''''''' else cast(''''+ convert(varchar(max),QUOTENAME(IDWG)) + '''' as nvarchar(max)) + '''''''','''''''' end'''' FROM ccRIACat_WorkGroup

set @sql=''''
create table #tempIDWG (
	cal_id int NOT NULL,
	User_id int NOT NULL,
	tipo int NOT NULL,
	idWgs varchar(1000) NOT NULL	
)

CREATE CLUSTERED INDEX IX_tempIDWG_I ON [dbo].#tempIDWG(cal_id ASC,	User_id ASC,	tipo ASC) 

insert into #tempIDWG 
select cal_id,User_id,tipo,'''' + @idWgs + '''' as idWgs
from
(select IDWG ,cal_id,User_id,tipo from ccRIAWorkGroup_Calid --with(index(IX_ccRIAWorkGroup_Calid_3),nolock)
	where timestamp >=  DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()-1))  and  timestamp  <  DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) ) a
pivot(
	max(IDWG)
	for idwg in(''''+@idWgsCorchetes+'''')
)as pvt
--select cal_id,User_id,tipo,substring(idWgs,0,len(idWgs)) idWgs from #tempIDWG


UPDATE a
SET a.IDWG= substring(idWgs,0,len(idWgs))
From RIA_GRABACION a with(rowlock)
INNER JOIN  #tempIDWG b with(index(IX_tempIDWG_I),nolock) ON a.cal_id = b.cal_id and a.age_id=b.User_id and a.tipo_llamada=(b.tipo + 1 )

drop table #tempIDWG
''''
exec(@sql)
'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''AVRSSaveWorkgroupCalidSchedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150522, 
		@active_end_date=99991231, 
		@active_start_time=4000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@Sql)

    set @process = 'CW-  VERSION 120.11 JOb DatabaseCentinella'
    set @Sql= 'USE [msdb]

/****** Object:  Job [DatabaseCentinella]    Script Date: 23/06/2018 11:24:41 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

/****** Object:  Job [DatabaseCentinella]    Script Date: 23/06/2018 11:24:41 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:24:41 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Autor: Raymundo Gonzalez
				Fecha: 2018/06/15
				Descripcion:
					Centinela para monitoreo de performance y mantenimiento de las BD de SQL
				'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 23/06/2018 11:24:41 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''use [master]

set nocount on

declare @idDb int
declare @dbName nvarchar(100)
declare @dbLog nvarchar(100)
declare @sql nvarchar(max)
declare @idIndex int
declare @tableName nvarchar(100)
declare @indexName nvarchar(100)
declare @process int
declare @firstSunday datetime
declare @idCmdSql int
declare @cmdSql nvarchar(max)
declare @maxTimeSeconds int
declare @maxTimeSecondsSunday int
declare @dateExecution datetime

set @idDb = 0
set @dbName = ''''''''
set @dbLog = ''''''''
set @sql = ''''''''
set @idIndex = 0
set @tableName = ''''''''
set @indexName = ''''''''
set @process = 1
set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
set @idCmdSql = 0
set @cmdSql = ''''''''
set @maxTimeSeconds = 7200
set @maxTimeSecondsSunday = 14400
set @dateExecution = getdate()

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
	begin
		if exists (select * from sys.tables where name = ''''userDatabases'''')
			drop table userDatabases

		if exists (select * from sys.tables where name = ''''indexMaintenance'''')
			drop table indexMaintenance

		if exists (select * from sys.tables where name = ''''logCentinella'''')
			drop table logCentinella
	end

if not exists (select * from sys.tables where name = ''''userDatabases'''')
	begin
		create table dbo.userDatabases(
			[idDb] int not null identity primary key,
			[dbName] nvarchar(100) not null,
			[dbLog] nvarchar(100) not null,
			[status] bit not null
		)

		CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
		(
			[dbName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
	begin
		create table dbo.indexMaintenance(
			[idIndex] int not null identity primary key,
			[dbName] nvarchar(100) not null,
			[tableName] nvarchar(100) not null,
			[indexName] nvarchar(100) not null,
			[indexType] nvarchar(100) not null,
			[indexFragmentation] nvarchar(100) not null,
			[status] bit not null
		)

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
		(
			[dbName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
		(
			[tableName] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

if not exists (select * from sys.tables where name = ''''logCentinella'''')
	begin
		create table dbo.logCentinella(
			[idCmdSql] int not null identity primary key,
			[date] datetime not null,
			[cmdSql] nvarchar(max) not null,
			[status] int not null,
			[dateStart] datetime not null,
			[dateEnd] datetime not null,
			[executionTimeSeconds] int not null
		)

		CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
		(
			[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
		(
			[status] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	end

insert into userDatabases
select db_name(database_id), '''''''', 0
from sys.master_files
where state = 0
and has_dbaccess(db_name(database_id)) = 1
and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
and type = 0

update userDatabases
set [dbLog] = name
from sys.master_files
inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

while (select count(*) from userDatabases where status = 0) > 0
	begin
		set rowcount 1
			select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
		set rowcount 0

		select @sql = ''''use ['''' + @dbName + '''']

insert into master.dbo.indexMaintenance
SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
WHERE indexstats.avg_fragmentation_in_percent > 30
ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

		exec(@sql)

		update userDatabases
		set status = 1
		where idDb = @idDb
	end

while (select count(*) from indexMaintenance where status = 0) > 0
	begin
		set rowcount 1
			select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
		set rowcount 0

		select @sql = ''''use ['''' + @dbName + ''''] ''''

		if @process = 1
				select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )''''
		else if @process = 2
				select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )''''
		else if @process = 3
				select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN''''

		insert into logCentinella
		select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

		if @process < 3
			update indexMaintenance set status = 1 where idIndex = @idIndex
		else
			update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

		if @process < 3
			begin
				if (select count(*) from indexMaintenance where status = 0) = 0
					begin
						update indexMaintenance
						set status = 0

						set @process = @process + 1
					end
			end
	end

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
	begin
		update userDatabases
		set status = 0

		while (select count(*) from userDatabases where status = 0) > 0
			begin
				set rowcount 1
					select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
				set rowcount 0

				select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''

				insert into logCentinella
				select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0							

				select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

				insert into logCentinella
				select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

				select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

drop table #RutaBak

BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

				insert into logCentinella
				select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

				update userDatabases
				set status = 1
				where idDb = @idDb
			end

		select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

drop table #RutaBak''''

		insert into logCentinella
		select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

	end

set @dateExecution = getdate()

while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
	begin
		set rowcount 1
			select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
		set rowcount 0

		update logCentinella
		set dateStart = getdate()
		where idCmdSql = @idCmdSql

		exec(@cmdSql)

		WAITFOR DELAY ''''00:00:01''''

		while(SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b
				ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c
				ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
				AND a.session_id = @@SPID
				and d.text = @cmdSql) > 0
			begin
				WAITFOR DELAY ''''00:00:01''''
			end

		if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
			begin
				if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
					BREAK
			end
		else
			begin
				if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
					BREAK
			end

		update logCentinella
		set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
		where idCmdSql = @idCmdSql
	end

delete userDatabases
delete indexMaintenance'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140724, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@Sql)

    set @process = 'CW-  VERSION 120.11 JOb [Move Recordings]'
    set @Sql= 'USE [msdb]

/****** Object:  Job [Move Recordings]    Script Date: 23/06/2018 11:25:10 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''Move Recordings'')
EXEC msdb.dbo.sp_delete_job @job_name=N''Move Recordings'', @delete_unused_schedule=1


/****** Object:  Job [Move Recordings]    Script Date: 23/06/2018 11:25:10 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 23/06/2018 11:25:10 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Database Maintenance'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Database Maintenance''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Move Recordings'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Moves recordings from RIA_GRABACION to RIA_GRABACIONCONSULTA'', 
		@category_name=N''Database Maintenance'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [move and erase]    Script Date: 23/06/2018 11:25:10 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''move and erase'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec trsp_muevegrabaciones'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every day'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080422, 
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
    EXEC(@Sql)

    set @process = 'CW-  VERSION 120.11 JOb ReportsMasterProcessAVRS'
    set @Sql= 'USE [msdb]

/****** Object:  Job [ReportsMasterProcessAVRS]    Script Date: 23/06/2018 11:26:05 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''ReportsMasterProcessAVRS'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessAVRS'', @delete_unused_schedule=1

/****** Object:  Job [ReportsMasterProcessAVRS]    Script Date: 23/06/2018 11:26:05 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:26:05 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessAVRS'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcessAVRS'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 23/06/2018 11:26:05 a.m. ******/
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
		@command=N''EXEC ReportsMasterProcessAVRS'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportsMasterProcessAVRS'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
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
    EXEC(@Sql)
		
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
