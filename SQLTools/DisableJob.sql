if not exists (select * from sys.tables where name='jobsEnable' ) begin
	create table jobsEnable(job_id uniqueidentifier not null,name varchar(256) not null)
end
insert into jobsEnable(job_id,[name])
select j.job_id,j.[name] from MSDB.dbo.sysjobs j
left join jobsEnable je on j.job_id=je.job_id
where enabled=1 and je.job_id is null

update j set enabled=0 from MSDB.dbo.sysjobs j
inner join jobsEnable je on j.job_id=je.job_id