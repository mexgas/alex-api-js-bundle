SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 101
/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
			set @process = 'CW-4691 crear tabla de relaciones de calificaciones y subcalificaciones'
			set @sql = 'if exists (select * from sys.tables where name = N''ccCodsSLR'')
    begin
        drop table ccCodsSLR
    end

 begin 
	Create table [dbo].[ccCodsSLR] (
		[id_cod] [smallint], 
		[tipoResDial_id] [smallint],
		[califSub_id] [smallint],
		[cod] [VARCHAR](4),
		[cod_description] [VARCHAR](40),
		[cod_action] [VARCHAR](40),
		[status] [VARCHAR](40)
		)
end

INSERT INTO ccCodsSLR VALUES(''1'',NULL,''15'',''0001'',''CONTACTO CON TITULAR PERO NO DEFINE'',''LLAMADA'',''CONTACTO EFECTIVO'')
,(''2'',NULL,''16'',''0004'',''COMPROMISO DE LIQUIDACION'',''LLAMADA'',''CONTACTO EFECTIVO'')
,(''3'',NULL,''13'',''0005'',''CONTACTO CON TERCERO'',''LLAMADA'',''CONTACTO'')
,(''4'',NULL,''1'',''0005'',''CONTACTO CON TERCERO'',''LLAMADA'',''CONTACTO'')
,(''5'',''3'',NULL,''0006'',''NO CONTESTA'',''LLAMADA'',''NO CONTACTO'')
,(''6'',NULL,''19'',''0006'',''NO CONTESTA'',''LLAMADA'',''NO CONTACTO'')
,(''7'',''10'',NULL,''0007'',''FUERA DE SERVICIO'',''LLAMADA'',''NO CONTACTO'')
,(''8'',''5'',NULL,''0007'',''FUERA DE SERVICIO'',''LLAMADA'',''NO CONTACTO'')
,(''9'',''2'',NULL,''0007'',''FUERA DE SERVICIO'',''LLAMADA'',''NO CONTACTO'')
,(''10'',NULL,''20'',''0007'',''FUERA DE SERVICIO'',''LLAMADA'',''NO CONTACTO'')
,(''11'',NULL,''4'',''0008'',''NUMERO EQUIVOCADO'',''LLAMADA'',''NO CONTACTO'')
,(''12'',NULL,''21'',''0008'',''NUMERO EQUIVOCADO'',''LLAMADA'',''NO CONTACTO'')
,(''13'',NULL,''17'',''0009'',''NEGATIVA DE PAGO'',''LLAMADA'',''CONTACTO EFECTIVO'')
,(''14'',NULL,''3'',''0009'',''NEGATIVA DE PAGO'',''LLAMADA'',''CONTACTO EFECTIVO'')
,(''15'',NULL,''22'',''0011'',''DEFUNCION'',''LLAMADA'',''NO CONTACTO'')
,(''16'',NULL,''23'',''0012'',''CUELGA LLAMADA'',''LLAMADA'',''NO CONTACTO'')
,(''17'',''13'',NULL,''0012'',''CUELGA LLAMADA'',''LLAMADA'',''NO CONTACTO'')
,(''18'',''4'',NULL,''0013'',''SE DEJA MENSAJE EN BUZON'',''LLAMADA'',''NO CONTACTO'')
,(''19'',''11'',NULL,''0013'',''SE DEJA MENSAJE EN BUZON'',''LLAMADA'',''NO CONTACTO'')
,(''20'',NULL,''24'',''0013'',''SE DEJA MENSAJE EN BUZON'',''LLAMADA'',''NO CONTACTO'')
,(''21'',NULL,''25'',''0014'',''RECORDATORIO DE PAGO'',''LLAMADA'',''NO CONTACTO'')
,(''22'',NULL,''26'',''0015'',''SEGUIMIENTO PROMESA INCUMPLIDA'',''LLAMADA'',''NO CONTACTO'')
,(''23'',NULL,''14'',''0018'',''ACLARACION'',''LLAMADA'',''CONTACTO'')
,(''24'',''8'',NULL,''0033'',''SE ENVIA SMS'',''SMS'',''NO CONTACTO'')
,(''25'',''12'',NULL,''0033'',''SE ENVIA SMS'',''SMS'',''NO CONTACTO'')
,(''26'',''80'',NULL,''0033'',''SE ENVIA SMS'',''SMS'',''NO CONTACTO'')'
    		EXEC(@sql)
    		
set @process = 'CW-4691 Create ccspGetReportWithCods'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspGetReportWithCods'')
            begin
          DROP PROCEDURE ccspGetReportWithCods;
            end'
    EXEC(@sql)
		set @process = 'CW-4691 Check if exists ccspGetReportWithCods'	
	set @sql = 'Create PROCEDURE [dbo].[ccspGetReportWithCods]
AS
declare @fechaInicio datetime,@fechaFin datetime
select  @fechaFin=convert(varchar(10),getdate(),121)+'' 22:00:00''

select  @fechaInicio= convert(varchar(10),getdate(),121)+'' 06:00:00''
print(@fechaInicio)
print(@fechaFin)

declare @fileName varchar(200)
select @fileName=''gets_''+replace(convert(varchar, getdate(),3),''/'','''')
--select @fileName,@fechaInicio,@fechaFin 


/***RUTA DONDE SE GUARDARA EL REPORTE***/
declare @pathFile varchar(100)
set @pathFile=''C:\ReporteEspecial''

select 
NULLIF(cals.cal_Key,'''') [PLAN_PAGOS],
NULLIF(convert(varchar, cals.fecha, 112),'''') [Fecha_Gestion],
NULLIF(replace(convert(varchar,cals.fecha,8),'':'',''''),'''') [Hora_Gestion], 
NULLIF(COALESCE(tipo_cod.cod,cali_cod.cod),'''') [COD],
NULLIF(calssource.Dato3,'''') [Fecha_Promesa], 
NULLIF(calssource.Dato4,'''') [Monto_Promesa],
NULLIF(calssource.Dato5,'''') [Comentario], 
NULLIF(COALESCE(tipo_cod.cod_description,cali_cod.cod_description,calif_out.califSubDesc),'''') [Cod_descripcion]

into SLR_out
from ccoLogDials cals with(nolock) 
left join ccoCallsOut calsout on calsout.cal_id=cals.cal_id 
left join ccoCallsOutSource calssource on calssource.callout_id=calsout.callout_id 
left join ccCodsSLR tipo_cod on tipo_cod.tipoResDial_id=cals.tipoResDial_id
left join ccCodsSLR cali_cod on cali_cod.califSub_id=calsout.califSub_id
left join cctipocalifsubout calif_out on calif_out.califSub_id=calsout.califSub_id 
where cals.fecha>=@fechaInicio and cals.fecha<=@fechaFin 
order by cals.fecha


declare 
	@db_name	varchar(100),
	@table_name	varchar(100),	
	@file_name	varchar(100)


select @db_name=''CCReportsRIA'', @table_name=''SLR_out'',@file_name=@pathFile+''\''+@fileName+''.txt''

declare @columns varchar(8000), @sql varchar(8000), @data_file varchar(100)
select 
	@columns=coalesce(@columns+'','','''')+column_name+'' as ''+column_name 
from 
	information_schema.columns
where 
	table_name=@table_name
order by ORDINAL_POSITION



select @columns=''''''''''''+replace(replace(@columns,'' as '','''''''''' as ''),'','','','''''''''')

select @data_file=substring(@file_name,1,len(@file_name)-charindex(''\'',reverse(@file_name)))+''\data_file.txt''
set @sql=''exec master..xp_cmdshell ''''bcp " select * from (select ''+@columns+'') as t" queryout "''+@file_name+''" -c -t "|" -T -U sa -P nuxiba''''''
print @sql
exec(@sql)
set @sql=''exec master..xp_cmdshell ''''bcp "select * from ''+@db_name+''..''+@table_name+''" queryout "''+@data_file+''" -c -t "|" -T -U sa -P nuxiba ''''''
print @sql
exec(@sql)
set @sql= ''exec master..xp_cmdshell ''''type ''+@data_file+'' >> "''+@file_name+''"''''''
exec(@sql)
set @sql= ''exec master..xp_cmdshell ''''del ''+@data_file+''''''''
exec(@sql)

drop table SLR_out'
    EXEC(@sql)
    set @process = 'CW-4691 generar job para la creación de reporte'
			set @sql = '
/****** Object:  Job [Reporte Especial Servicios Legales]    Script Date: 20/05/2021 12:01:13 p. m. ******/

if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''Reporte Especial Servicios Legales'') begin
				EXEC msdb.dbo.sp_delete_job @job_name=N''Reporte Especial Servicios Legales'', @delete_unused_schedule=1
			end
/****** Object:  Job [Reporte Especial Servicios Legales]    Script Date: 20/05/2021 12:01:13 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Nuxiba]    Script Date: 20/05/2021 12:01:14 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Reporte Especial Servicios Legales'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Generación de reporte a las 10:00 pm con la información de la actividad del día relacionada con un tabla especial para el cliente.'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generar Reporte]    Script Date: 20/05/2021 12:01:15 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generar Reporte'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccspGetReportWithCods'', 
		@database_name=N''CCReportsRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Enviar Correo]    Script Date: 20/05/2021 12:01:15 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Enviar Correo'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''
declare @pathFile varchar(100)
set @pathFile=''''C:\ReporteEspecial\''''
declare @fileName varchar(200)
select @fileName=''''gets_''''+replace(convert(varchar, getdate(),3),''''/'''','''''''')+''''.txt''''

DECLARE @attachmentFile varchar(250);
SET @attachmentFile = @pathFile+@fileName

SELECT @attachmentFile


EXEC msdb.dbo.sp_send_dbmail
	@profile_name = ''''notificationscw''''
	,@recipients = ''''eflores@nuxiba.com''''
	,@copy_recipients =''''eflores@nuxiba.com''''
	,@body = ''''Se adjunta el reporte de la operación del día en un archivo de texto separado por pipes''''
	,@subject = ''''Reporte especial NUXIBA'''',
     @file_attachments=@attachmentFile;'', 
		@database_name=N''CCReportsRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''10 pm'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210520, 
		@active_end_date=99991231, 
		@active_start_time=235200, 
		@active_end_time=235959, 
		@schedule_uid=N''3c5949d5-8c15-4d3d-80b5-24e9bdfc52e0''
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
