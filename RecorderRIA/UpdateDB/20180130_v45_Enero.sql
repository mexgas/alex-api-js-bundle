/*
Autor: Omar Mejia
Descripcion:


Version requerida: 44
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 45
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	
	set @process = 'CW-1182 ALTER SP trsp_GetFilesAnalisisGritos'
 	set @sql ='
	ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
			--@idRepositorios as varchar(32),
			@sExtension as varchar(10) = ''.vox''
			AS

			declare @Integrado as int
			declare @FInicio as datetime
			declare @sSql1 as nvarchar(max)
			declare @sSql2 as nvarchar (max)
			declare @sSql3 as nvarchar(max) 
			declare @sSql as nvarchar (max)
			declare @dLenAnt as tinyint
			declare @dLenNew as tinyint
			declare @Encriptado as int
			declare @ENC  as varchar(4)


			set @FInicio = dateadd(MINUTE, -1, getdate())
			set @sSql = N''
			set @sSql3 = N''
			set @sExtension = (select par_valor from trec_parametros where par_id = 54)

			select @integrado = par_valor from trec_parametros where par_id = 29
			select @Encriptado = par_valor from trec_parametros where par_id = 15

			--AVRS Integrada
			if (@integrado = 1)

				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1)''

				END

			--AVRS Standalone
			else if(@integrado = 0)

				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1)''

				END

			--AVRS XION
			else if(@integrado = 2)
				BEGIN
					
					if @Encriptado = 1
						begin
							set @ENC = ''.enc''
						end
					else
						begin
							set @ENC = ''''
						end
									
					/**/
					set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension + @ENC+char(0x27) 
					set @sSql2 = ''extension, isnull(tipo_llamada,0) tipo_llamada, id_repositorio from ria_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1) and cal_id in ( select cal_id from ccRIAWorkGroup_Calid)''

				END

			set @sSql = @sSql1 + @sSql2 + N'' order by finicio asc''
			exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio
	'
	
	EXEC(@sql)

	set @process = 'CW-1182 CREATE SP tmp_detGritosOut'
 	set @sql ='
	CREATE PROCEDURE [dbo].[tmp_detGritosOut]
AS
BEGIN
	SET NOCOUNT ON;

	declare @ENC  as varchar(4),@sExtension as varchar(10),@Encriptado as int
	declare @sSql1 as nvarchar(max)

	set @sExtension = (select par_valor from trec_parametros where par_id = 54)
	select @Encriptado = par_valor from trec_parametros where par_id = 15
	
	if @Encriptado = 1
	begin
		set @ENC = ''.enc''
	end
	else
	begin
		set @ENC = ''''
	end
									

	set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension + @ENC+char(0x27) 
	+ '', isnull(tipo_llamada,0), id_repositorio from ria_grabacion NOLOCK where finicio < dateadd(MINUTE, -1, getdate()) ''
	 + '' and id_nivel_grito is NULL and cal_id in ( select cal_id from ccRIAWorkGroup_Calid)  and grab_id not in (select grab_id from ria_RecNode)''
	--select into @temptable
	DECLARE @grab_id bigint
	DECLARE @t TABLE ( grab_id bigint, cal_id int, campo1 varchar(2000), campo2 smallint, id_repositorio tinyint )
	insert into @t exec sp_executesql @sSql1
	--select grab_id from @t
	DECLARE detector_cursor cursor for
	select grab_id from @t
	open detector_cursor
	FETCH NEXT FROM detector_cursor INTO @grab_id
	WHILE @@FETCH_STATUS = 0  
	BEGIN
	--print @grab_id
	update RIA_GRABACION set id_nivel_grito=-1 where grab_id=@grab_id
	exec trsp_InsertRecNode  @grab_id,0
	FETCH NEXT FROM detector_cursor   
	    INTO @grab_id  
	END
	CLOSE detector_cursor
	DEALLOCATE detector_cursor
	
END
	'
	
	EXEC(@sql)
	set @process = 'CW-1182 CREATE Job [tmp_detGritosOut]'
 	set @sql ='
	USE [msdb]
/****** Object:  Job [tmp_detGritosOut]    Script Date: 25/10/2017 06:16:16 p. m. ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''tmp_detGritosOut'')
EXEC msdb.dbo.sp_delete_job @job_name=N''tmp_detGritosOut'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 25/10/2017 06:16:16 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''tmp_detGritosOut'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [uno]    Script Date: 25/10/2017 06:16:16 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''uno'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''tmp_detGritosOut'', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''20 seg'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=2, 
		@freq_subday_interval=20, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20171025, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N''bfff3804-2270-497b-8498-e3bb749c15c4''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
	'
	
	EXEC(@sql)
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
