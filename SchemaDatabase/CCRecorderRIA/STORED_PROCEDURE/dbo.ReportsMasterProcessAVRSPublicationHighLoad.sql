create procedure [dbo].[ReportsMasterProcessAVRSPublicationHighLoad] as
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

print '---Get schedule_id and @scheduleTime ----'
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name='ReportsMasterProcessAVRSPublicationHighLoad'


print '---Get Jobs Replication ----'
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 	 
	inner join PublicationHighLoad C on A.[name] like '%'+C.namePublication+'%'
	where A.[name] like '%CCRecorderRIA- 0%' and A.[name] like '%CCenterRia%'	

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