USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'AVRSSaveWorkGroupCalid') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N'AVRSSaveWorkGroupCalid', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Nuxiba' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Nuxiba'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'AVRSSaveWorkGroupCalid',
		@enabled=0,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'This Job allows everyday, save the relations  between ccRIAWorkGroup_Calid and recordings in the new column added in RIAGrabacion (IDWG) so that customers can check the recordings without any problem after the purification process in  ccRIAWorkGroup_Calid',
		@category_name=N'Nuxiba',
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'/',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0,  @subsystem=N'TSQL',
		@command=N'declare @idWgs nvarchar(max) ,@idWgsCorchetes nvarchar(max) ,@sql nvarchar(max)
SELECT @idWgsCorchetes=COALESCE(@idWgsCorchetes + '', '', '''') + convert(varchar(max),QUOTENAME(IDWG)) FROM ccRIACat_WorkGroup
SELECT @idWgs=COALESCE(@idWgs + ''+ '', '''') + ''case when '' + convert(varchar(max),QUOTENAME(IDWG)) + '' is null then '''''''' else cast(''+ convert(varchar(max),QUOTENAME(IDWG)) + '' as nvarchar(max)) + '''','''' end'' FROM ccRIACat_WorkGroup

set @sql=''
create table #tempIDWG (
	cal_id int NOT NULL,
	User_id int NOT NULL,
	tipo int NOT NULL,
	idWgs varchar(1000) NOT NULL	
)

CREATE CLUSTERED INDEX IX_tempIDWG_I ON [dbo].#tempIDWG(cal_id ASC,	User_id ASC,	tipo ASC) 

insert into #tempIDWG 
select cal_id,User_id,tipo,'' + @idWgs + '' as idWgs
from
(select IDWG ,cal_id,User_id,tipo from ccRIAWorkGroup_Calid --with(index(IX_ccRIAWorkGroup_Calid_3),nolock)
	where timestamp >=  DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()-1))  and  timestamp  <  DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) ) a
pivot(
	max(IDWG)
	for idwg in(''+@idWgsCorchetes+'')
)as pvt
--select cal_id,User_id,tipo,substring(idWgs,0,len(idWgs)) idWgs from #tempIDWG


UPDATE a
SET a.IDWG= substring(idWgs,0,len(idWgs))
From RIA_GRABACION a with(rowlock)
INNER JOIN  #tempIDWG b with(index(IX_tempIDWG_I),nolock) ON a.cal_id = b.cal_id and a.age_id=b.User_id and a.tipo_llamada=(b.tipo + 1 )

drop table #tempIDWG
''
exec(@sql)
',
		@database_name=N'CCRecorderRIA',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'AVRSSaveWorkgroupCalidSchedule',
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave: