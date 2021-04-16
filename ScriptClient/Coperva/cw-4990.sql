SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 123 

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
			set @process = 'CW-4990 Verificar si existe el ccspGetReportCooperva'
			set @sql = 'if exists (select * from sys.procedures where name = N''ccspGetReportCooperva'')
            begin
          		DROP PROCEDURE ccspGetReportCooperva;
            end'
    		EXEC(@sql)
    		
			SET @process = 'CW-4490 SP que genera el reporte automático de cargas del día'
			SET @sql = '
			
CREATE PROCEDURE [dbo].[ccspGetReportCooperva]

AS

declare @from datetime,@to datetime
select  @to=convert(varchar(10),getdate(),121)+'' 22:30:00''

select  @from= convert(varchar(10),getdate(),121)


declare @fileName varchar(200)
select @fileName=''Reporte_''+replace(convert(varchar, getdate(),3),''/'','''')

/***RUTA DONDE SE GUARDARA EL REPORTE***/
declare @pathFile varchar(100)
set @pathFile=''C:\ReportsCooperva''


select 

convert(varchar,loads.loadDate,5) [Fecha],
loads.camName [CamNombre],
isnull(lists.name,'''') [Lista],
loads.regsLoaded [Cargados],
loads.regsNotLoaded [Rechazados]
into reportCooperva_out --Tabla a escribir..
from ccRIALoading loads with(nolock) 
left join ccriaregistrylists lists on lists.list_id=loads.list_id
where loads.loadDate>=@from and loads.loadDate<=@to


--alter procedure proc_generate_excel_with_columns
--(
declare 
	@db_name	varchar(100),
	@table_name	varchar(100),	
	@file_name	varchar(100)
--)
--as

select @db_name=''CCenterRIA'', @table_name=''reportCooperva_out'',@file_name=@pathFile+''\''+@fileName+''.csv''
--Generate column names as a recordset
declare @columns varchar(8000), @sql varchar(8000), @data_file varchar(100)
select 
	@columns=coalesce(@columns+'','','''')+column_name+'' as ''+column_name 
from 
	information_schema.columns
where 
	table_name=@table_name
order by ORDINAL_POSITION

select @columns=''''''''''''+replace(replace(@columns,'' as '','''''''''' as ''),'','','','''''''''')

--Create a dummy file to have actual data
select @data_file=substring(@file_name,1,len(@file_name)-charindex(''\'',reverse(@file_name)))+''\data_file..csv''

----Generate column names in the passed EXCEL file
set @sql=''exec master..xp_cmdshell ''''bcp " select * from (select ''+@columns+'') as t" queryout "''+@file_name+''"  -c -t, -T -S -U -P nuxiba''''''
print @sql
exec(@sql)


--Generate data in the dummy file
set @sql=''exec master..xp_cmdshell ''''bcp "select * from ''+@db_name+''..''+@table_name+''" queryout "''+@data_file+''"  -c -t, -T -S -U sa -P nuxiba''''''
print @sql
exec(@sql)

--Copy dummy file to passed EXCEL file
set @sql= ''exec master..xp_cmdshell ''''type ''+@data_file+'' >> "''+@file_name+''"''''''
exec(@sql)

--Delete dummy file 
set @sql= ''exec master..xp_cmdshell ''''del ''+@data_file+''''''''
exec(@sql)

drop table reportCooperva_out


			'
			EXEC(@sql)

			SET @process = 'CW-4490 Genera reporte de la carga de registros con el nombre de la lista de carga'
			SET @sql = 'USE [msdb]
			/****** Object:  Job [ReportsCoperva]    Script Date: 14/04/2021 12:08:32 p. m. ******/
			if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsCoperva'') begin
				EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsCoperva'', @delete_unused_schedule=1
			end
			/****** Object:  Job [ReportsCoperva]    Script Date: 14/04/2021 12:08:33 p. m. ******/
			BEGIN TRANSACTION
			DECLARE @ReturnCode INT
			SELECT @ReturnCode = 0
			/****** Object:  JobCategory [Nuxiba]    Script Date: 14/04/2021 12:08:33 p. m. ******/
			IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
			BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

			END

			DECLARE @jobId BINARY(16)
			EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsCoperva'', 
					@enabled=1, 
					@notify_level_eventlog=0, 
					@notify_level_email=0, 
					@notify_level_netsend=0, 
					@notify_level_page=0, 
					@delete_level=0, 
					@description=N''Generar reporte 10:00 pm fecha, Camp, Nombre de la lista, Registros cargados, registros rechazados'', 
					@category_name=N''Nuxiba'', 
					@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			/****** Object:  Step [Generar reporte]    Script Date: 14/04/2021 12:08:34 p. m. ******/
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generar reporte'', 
					@step_id=1, 
					@cmdexec_success_code=0, 
					@on_success_action=1, 
					@on_success_step_id=0, 
					@on_fail_action=2, 
					@on_fail_step_id=0, 
					@retry_attempts=0, 
					@retry_interval=0, 
					@os_run_priority=0, @subsystem=N''TSQL'', 
					@command=N''EXEC ccspGetReportCooperva'', 
					@database_name=N''CCenterRIA'', 
					@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''diario'', 
					@enabled=1, 
					@freq_type=4, 
					@freq_interval=1, 
					@freq_subday_type=1, 
					@freq_subday_interval=0, 
					@freq_relative_interval=0, 
					@freq_recurrence_factor=0, 
					@active_start_date=20210317, 
					@active_end_date=99991231, 
					@active_start_time=223000, 
					@active_end_time=235959
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			COMMIT TRANSACTION
			GOTO EndSave
			QuitWithRollback:
			    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
			EndSave:'
		EXEC(@sql)

		
		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
