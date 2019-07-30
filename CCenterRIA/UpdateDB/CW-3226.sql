/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.37

Se agrega la tarea
cw-2915
cw-3001
CW-3201
CW-3032
CW-3045
CW-3199

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 37
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'cw-3226 update ccListaNegra set Hashtel=null'
		set @sql = 'update ccListaNegra set Hashtel=null where Hashtel is not null'
		exec (@sql)

		set @process = 'cw-3226 Drop index IX_ccListaNegra_I on ccListaNegra'
		set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    Drop index IX_ccListaNegra_I on ccListaNegra
end'
		exec (@sql)

		set @process = 'cw-3226 Drop index IX_ccListaNegra_II on ccListaNegra'
		set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    Drop index IX_ccListaNegra_II on ccListaNegra
end'
		exec (@sql)

		set @process = 'cw-3226 Alter COLUMN ccListaNegra.Hashtel'
		set @sql = 'if exists(select A.name,B.name from sys.columns A inner join  sys.types B on A.system_type_id=B.system_type_id
where A.name = N''Hashtel'' and Object_ID = Object_ID(N''ccListaNegra'') and B.name=''int'') begin
ALTER TABLE ccListaNegra ALTER COLUMN Hashtel bigint
select ''change''
end'
		exec (@sql)

		set @process = 'cw-3226 Alter COLUMN ccListaNegra.HashKey'
		set @sql = 'if exists(select A.name,B.name from sys.columns A inner join  sys.types B on A.system_type_id=B.system_type_id
where A.name = N''HashKey'' and Object_ID = Object_ID(N''ccListaNegra'') and B.name=''int'') begin
ALTER TABLE ccListaNegra ALTER COLUMN HashKey bigint
select ''change''
end'
		exec (@sql)

		set @process = 'cw-3226 CREATE index IX_ccListaNegra_I on ccListaNegra'
		set @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    CREATE index IX_ccListaNegra_I on ccListaNegra(idtipolista, Hashtel)
end
'
		exec (@sql)

		set @process = 'cw-3226 CREATE index IX_ccListaNegra_II on ccListaNegra'
		set @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    CREATE index IX_ccListaNegra_II on ccListaNegra([idtipolista], Hashtel, HashKey)
end'
		exec (@sql)

		set @process = 'cw-3226 Alter dbo.hashPhone '
		set @sql = 'ALTER FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
  return convert(bigint,@phoneNumber) % 99999999999973
END
'
		exec (@sql)

		set @process = 'cw-3226 Alter dbo.hashList'
		set @sql = '
ALTER FUNCTION [dbo].[hashList] (@calKey varchar(255)) 
RETURNS bigint AS
BEGIN
declare @codigo varchar(max)
declare @hash bigint

set @codigo=''''
set @hash=0
declare @i int,@len int
select @i=1,@len=len(@calKey)
while @i<=@len begin
	select @codigo=@codigo+convert(varchar(max), ASCII(SUBSTRING(@calKey,@i,1)))
	
	if @i%5=0 begin
		set @hash=@hash+cast(@codigo as bigint)
		set @codigo=''''
	end	
	set @i=@i+1
end
if @codigo<>''''
set @hash=@hash+cast(@codigo as bigint)
return @hash % 99999999999973
END'
		exec (@sql)		

		set @process = 'cw-3226 CW Update ccListaNegra Hashtel JOb'
		set @sql = 'USE [msdb]


if exists(select * from msdb.dbo.sysjobs_view where name=N''CW Update ccListaNegra Hashtel'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Update ccListaNegra Hashtel'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Update ccListaNegra Hashtel'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 05/06/2019 10:12:59 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''if exists(select * from ccListaNegra where Hashtel is null) begin
    update top (20000) ccListaNegra set  Hashtel=dbo.hashPhone(telefono) where Hashtel is null
end
else begin 
    EXEC msdb.dbo.sp_delete_job @job_name=N''''CW Update ccListaNegra Hashtel'''', @delete_unused_schedule=1
end'', 
		@database_name=N''CCenterRia'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Update ccListaNegra Hashtel schedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		exec (@sql)
		

		

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
