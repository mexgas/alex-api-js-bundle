declare @replicationName varchar(max)
create table #replications ([name] nvarchar(max), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like '%ccReportsRia- 0%' and [name] like '%CCenterRia%'

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like '%ccReportsRia- 0%' and [name] like '%CCRecorderRia%' order by [name]

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	EXEC msdb.dbo.sp_purge_jobhistory  @job_name=@replicationName
	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName
end


drop table #replications