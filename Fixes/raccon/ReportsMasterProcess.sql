USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ReportsMasterProcess]    Script Date: 18/1/2024 10:23:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[ReportsMasterProcess]
as

set nocount on

declare @replicationName varchar(max)
declare @SubProcessNameReports varchar(max)
declare @dateStart datetime, @dateSP datetime
declare @schedule_id int,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)

set @dateStart = getdate()
set @scheduleTime = 15


declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

print '--------------------------- DROP TRIGGER Tables ---------------------------'
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



print '--------------- Get Jobs Replication ------------------------------'
create table #replications ([name] nvarchar(100), flag bit)

;

with jobNotStart as(
select distinct A.[name] from msdb.dbo.sysjobs A
	inner join PublicationLowLoad B on A.[name] like '%'+B.namePublication+'%'
	where A.[name] like '%CCReportsRIA- 0%' and A.[name] like '%CCenterRIA%'
union all
select distinct A.[name] from msdb.dbo.sysjobs A
	inner join PublicationHighLoad B on A.[name] like '%'+B.namePublication+'%'
	where A.[name] like '%CCReportsRIA- 0%' and A.[name] like '%CCenterRIA%'
)

insert into #replications
select distinct A.[name],0 from msdb.dbo.sysjobs A
	where A.[name] like '%CCReportsRIA- 0%' and A.[name] like '%CCenterRIA%'
	and A.name not in(select name from jobNotStart)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like '%CCReportsRIA- 0%' and [name] like '%CCRecorderRIA%' order by [name]

select @count=count(*) from #replications

while(
select count(*) from #replications with(nolock) where flag = 0) > 0
)
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

print '---#reinitmergepullsubscription----'

insert into RIA_FORMATOCONCEPTO
SELECT
t.id_formato AS 'ID Formato', c.id_concepto as 'id concepto'
FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato, nombre, MAX(version) as version
						FROM RIA_FORMATOS
						WHERE activo = 1
						group by id_formato, nombre) as t
ON f.id_formato = t.id_formato AND f.version = t.version inner join RIA_CONCEPTOS c
on t.id_formato = c.id_formato and t.version = c.version

left join RIA_FORMATOCONCEPTO as a on a.templateId = t.id_formato  and a.sectionId = c.id_concepto
where a.id is null

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
and ma.subscriber_db = 'CCReportsRIA'

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

		

print '--------------------------- Comienzo de subprocesos de reportes ---------------------------'


PRINT 'EXEC ReportsMasterSubProcess'
EXEC ReportsMasterSubProcess


