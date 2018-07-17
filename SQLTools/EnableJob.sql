
if  exists (select * from sys.tables where name='jobsEnable' ) begin
	update j set enabled=1 from MSDB.dbo.sysjobs j
	inner join jobsEnable je on j.job_id=je.job_id


	drop table jobsEnable
end
