set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 64
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

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
	insert into PublicationHighLoad values(''ccRIAWorkGroup_Calid'')
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Insert PublicationLowLoad'
		SET @sql = 'if not exists(select * from PublicationLowLoad) begin
	insert into PublicationLowLoad values(''Chats'')
	insert into PublicationLowLoad values(''ConversationMail'')
	insert into PublicationLowLoad values(''Conversationtweet'')
end'
		EXEC (@sql)



		SET @process = 'CW-3494 Replication DROP PROCEDURE ReportsMasterProcessAVRSPublicationLowLoad'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ReportsMasterProcessAVRSPublicationLowLoad'')
    begin
        DROP PROCEDURE ReportsMasterProcessAVRSPublicationLowLoad;
    end'
		EXEC (@sql)

		SET @process = 'CW-3494 ReplicationDROP PROCEDURE ReportsMasterProcessAVRSPublicationHighLoad '
		SET @sql = 'if exists (select * from sys.procedures where name = N''ReportsMasterProcessAVRSPublicationHighLoad'')
    begin
        DROP PROCEDURE ReportsMasterProcessAVRSPublicationHighLoad;
    end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication Alter SP ReportsMasterProcessAVRS '
		SET @sql = 'ALTER procedure [dbo].[ReportsMasterProcessAVRS] as
set nocount on
declare @replicationName varchar(max),@name varchar(255)
declare @dateStart datetime
declare @schedule_id int,@scheduleTime int

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)


set @dateStart = getdate()
set @scheduleTime = 5


print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcessAVRS''



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

print ''---Get Jobs Replication ----''
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 
	left join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''	
	left join PublicationHighLoad C on A.[name] like ''%''+C.namePublication+''%''
	where A.[name] like ''%CCRecorderRIA- 0%'' and A.[name] like ''%CCenterRia%''
	and B.namePublication is null and C.namePublication is null 

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





declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

insert into @tableArticle(nameArticle,objectId)
SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
inner join sys.tables t on t.name=Art.name

insert into @tableTrigger
select t.name as nameTrigger from @tableArticle Art
inner join sys.triggers  t on Art.objectId=t.parent_id
where name not like ''MSmerge_%'' and name<>''IX_ccRIAWorkGroupUsersConsulta2''

select @i=1,@count =count(*) from @tableTrigger
while @i<=@count
begin
	select @name = nameArticle  from @tableTrigger where id=@i
	set @sql =''DROP TRIGGER ''+ @name 
	exec (@sql)
	set @i = @i+1
end

print ''--------------------------- DROP TRIGGER Tables ---------------------------''


if not exists (select * from sys.indexes where name = N''IX_ccRIAWorkGroupUsersConsulta2'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta''))
begin
	CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta]
		(
			[IDWG] ASC,
			[User_id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
end

print ''-------------------------Add Trigger IX_ccRIAWorkGroupUsersConsulta2-------------------------''

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
and ma.subscriber_db = ''CCRecorderRIA''

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0			

		exec sp_reinitmergepullsubscription  @publisher = @publisher_reinit,    @publisher_db = @publisher_db_reinit,    @publication = @publication_reinit,    @upload_first = @upload_first_reinit		

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription

if DATEDIFF(mi,@dateStart,getdate())>@scheduleTime begin
	set @scheduleTime=@scheduleTime+1
	if  @scheduleTime< 59 begin
		EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
	end
	
end'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication CRATE SP ReportsMasterProcessAVRSPublicationLowLoad '
		SET @sql = 'create procedure [dbo].[ReportsMasterProcessAVRSPublicationLowLoad] as
set nocount on
declare @replicationName varchar(max)
declare @dateStart datetime
declare @schedule_id int,@scheduleTime int

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)


set @dateStart = getdate()
set @scheduleTime = 15


print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcessAVRSPublicationLowLoad''


print ''---Get Jobs Replication ----''
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 	 
	inner join PublicationLowLoad C on A.[name] like ''%''+C.namePublication+''%''
	where A.[name] like ''%CCRecorderRIA- 0%'' and A.[name] like ''%CCenterRia%''	

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

drop table #replications'
		EXEC (@sql)

		SET @process = 'CW-3494 Replication CREATE SP ReportsMasterProcessAVRSPublicationHighLoad '
		SET @sql = 'create procedure [dbo].[ReportsMasterProcessAVRSPublicationHighLoad] as
set nocount on
declare @replicationName varchar(max)
declare @dateStart datetime
declare @schedule_id int,@scheduleTime int

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)


set @dateStart = getdate()
set @scheduleTime = 5

print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcessAVRSPublicationHighLoad''


print ''---Get Jobs Replication ----''
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 	 
	inner join PublicationHighLoad C on A.[name] like ''%''+C.namePublication+''%''
	where A.[name] like ''%CCRecorderRIA- 0%'' and A.[name] like ''%CCenterRia%''	

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

drop table #replications'
		EXEC (@sql)


	SET @process = 'CW-3494 Alter SP trsp_muevegrabaciones'
	SET @Sql = 'ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
AS
BEGIN
declare @fecha datetime
declare @Integrado as int

select @integrado = par_valor from trec_parametros where par_id = 29
set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)
declare @top int
set @top=3000

--AVRS XION
if (@integrado = 2) BEGIN       

       	INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh)												
		SELECT top(@top) grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh
		FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;		

		DELETE top(@top) RIA_GRABACION WHERE [finicio] < @fecha;
END
else BEGIN  --AVRS Integrada ó AVRS Stand Alone
       SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

       INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG)
       SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
       FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

       SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

       DELETE TREC_GRABACION with(rowlock) WHERE [finicio] < @fecha;
END
END'
	EXEC (@Sql)

	SET @process = 'CW-3494 Job Move Recordings'
	SET @Sql = 'USE [msdb]

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Move Recordings'')
EXEC msdb.dbo.sp_delete_job  @job_name=N''Move Recordings'', @delete_unused_schedule=1


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 09/19/2019 20:44:31 ******/
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
/****** Object:  Step [move and erase]    Script Date: 09/19/2019 20:44:31 ******/
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
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080422, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=45959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	EXEC (@Sql)

	SET @process = 'CW-3494 Replication Create Job ReportsMasterProcessAVRS'
	SET @sql = 'USE [msdb]

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ReportsMasterProcessAVRS'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessAVRS'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/10/2019 02:18:38 p. m. ******/
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
/****** Object:  Step [Generate Reports]    Script Date: 04/10/2019 02:18:38 p. m. ******/
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
	EXEC (@sql)

	SET @process = 'CW-3494 Replication Create Job ReportsMasterProcessAVRSPublicationHighLoad'
	SET @sql = 'USE [msdb]

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ReportsMasterProcessAVRSPublicationHighLoad'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessAVRSPublicationHighLoad'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/10/2019 02:18:38 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessAVRSPublicationHighLoad'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcessAVRSPublicationHighLoad'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 04/10/2019 02:18:38 p. m. ******/
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
		@command=N''EXEC ReportsMasterProcessAVRSPublicationHighLoad'', 
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

	SET @process = 'CW-3494 Replication Create Job ReportsMasterProcessAVRSPublicationLowLoad'
	SET @sql = 'USE [msdb]

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ReportsMasterProcessAVRSPublicationLowLoad'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessAVRSPublicationLowLoad'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/10/2019 02:18:38 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessAVRSPublicationLowLoad'', 
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
/****** Object:  Step [Generate Reports]    Script Date: 04/10/2019 02:18:38 p. m. ******/
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
		@command=N''EXEC ReportsMasterProcessAVRSPublicationLowLoad'', 
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
