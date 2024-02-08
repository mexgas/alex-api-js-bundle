USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ReportsMasterProcessPublicationHighLoad]    Script Date: 21/12/2023 16:27:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[ReportsMasterProcessPublicationHighLoad]
as

set nocount on

declare @replicationName varchar(max)

declare @schedule_id int,@scheduleTime int
declare @i int,@count int
declare @SQL varchar(max)



declare @jobName varchar(255),@duration int
set @duration=0
 
SELECT @jobName= j.name, @duration= DATEDIFF(ms,ja.start_execution_date,GETDATE()) 
    FROM msdb.dbo.sysjobactivity ja 
    LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
    JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
    WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
    AND start_execution_date is not null
    AND stop_execution_date is null
    AND j.name in ('ReportsMasterProcessPublicationHighLoad')


IF @jobName is not null and @duration>2000
BEGIN
    print 'Process Active Job'
    SELECT @jobName AS job_name, @duration AS [Duration] 
    return(0)
END

print '--------------- Get Jobs Replication ------------------------------'
create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
	select distinct A.[name], 0 as flag from msdb.dbo.sysjobs A 
	inner join PublicationHighLoad B on A.[name] like '%'+B.namePublication+'%'	
	where A.[name] like '%ccReportsRia- 0%' and A.[name] like '%CCenterRia%'
	

select @count=count(*) from #replications

while exists(select * from #replications with(nolock) where flag = 0 )
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
		--if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
		--	print 'Stop Job in ReplicationName: '+@replicationName
		--	break	
		--end
	end
	print 'Progress End Job in ReplicationName: '+@replicationName
end

drop table #replications
