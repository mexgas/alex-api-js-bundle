USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N'CW Stop inactive campaigns') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N'CW Stop inactive campaigns', @delete_unused_schedule=1
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CW Stop inactive campaigns', 
		@enabled=1, 
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N'No description available.', 
		@category_name=N'Nuxiba', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run sp', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0,  @subsystem=N'TSQL', 
		@command=N'/*
Detener campa?as inactivas:
	Localiza campa?as que no tienen agentes asignados (Base de Reportes)
	Localiza campa?que no tienen informacion en ccGenOutCallDials (Base de Reportes)
	Contabiliza las llamadas de la ultima semana en ccoLogDials (Base de Reportes)
	Genera una media de llamadas por dia de la campa?a, previas a la ultima semana en base a ccoLogDials (Base de Reportes)
	Verifica que las llamadas de la ultima semana sean mayores a la media por campa?a multiplicado por el porcentaje definido en el setting (Base de Reportes, String de CCenterRIA)
	Si las llamadas no superan el porcentaje de la media, son detenidas junto a las campa?as que no tienen agentes (incluye autoinicio en CCenterRIA)
*/
set nocount on
declare @cam_id int, @iEjecutar int, @Ejecutar bit, @dias int, @ReportServer varchar(50), @SQL varchar(4000)
select @iEjecutar = cast(valor as int) from ccSettings where setting_id = 86
select @Ejecutar = cast(@iEjecutar as bit)

if @Ejecutar = 1
begin

select @ReportServer = valor from ccSettings where setting_id = 22
select @ReportServer = @ReportServer + ''.dbo.'', @dias = 8 -- dias de rango (semana)

create table temp_cam_id (cam_id int)

set @SQL=''declare @cccamps as table(cam_id int)
insert into @cccamps select cam_id from ccCamps where cam_procesando = 1 and cam_id not in 
(select cam_id from ccCampsAgente) union 
select cam_id from ccCamps where cam_procesando = 1 and cam_id not in 
(select cam_id from ''+@ReportServer+''ccGenOutCallDials)

insert into temp_cam_id select total.cam_id from (select c.cam_id, isnull(count(l.cam_id), 0) LastCalls_Week
from ''+@ReportServer+''ccoLogDials l right join ccCamps c 
on c.cam_id = l.cam_id and l.fecha > (getdate()-''+cast(@dias as varchar(10))+'')
where c.cam_id not in (select cam_id from @cccamps) and c.cam_procesando = 1
group by c.cam_id) 
total join
(select cam_id, avg(suma) mediaXdia, avg(suma)*cast(''+cast(@iEjecutar as varchar(10))+'' as decimal(18,2))/100 mediaXsetting
from (SELECT cam_id, convert(varchar(10), timegroup, 112) fecha, count(*) suma
FROM ''+@ReportServer+''ccGenOutCallDials where timegroup < (getdate()-''+cast(@dias as varchar(10))+'')
and cam_id not in (select cam_id from @cccamps)
group by cam_id, convert(varchar(10), timegroup, 112)) pre_media group by cam_id) 
media on total.cam_id = media.cam_id where total.LastCalls_Week < media.mediaXsetting
union
select camp.cam_id from @cccamps camp
order by 1''

exec(@SQL)

DECLARE camp CURSOR FOR 
	select cam_id from temp_cam_id
OPEN camp

FETCH NEXT FROM camp
INTO @cam_id
WHILE @@FETCH_STATUS = 0
BEGIN
   exec ccsp_OUTCampMovs @cam_id, 0, 1
   update ccCamps set cam_bnew = 4 where cam_id = @cam_id
   FETCH NEXT FROM camp
   INTO @cam_id
END

CLOSE camp
DEALLOCATE camp

drop table temp_cam_id
end
set nocount off',
		@database_name=N'ccenterRia',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Sunday at 5:00', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20100201, 
		@active_end_date=99991231, 
		@active_start_time=50000,  
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave: