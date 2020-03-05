--================================================================
-- DATABASE MAIL CONFIGURATION
--================================================================
USE master;
GO
sp_CONFIGURE 'show advanced', 1
GO
RECONFIGURE
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE
GO
--==========================================================
-- Create a Database Mail account
--==========================================================
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'Mail Centernext2',
    @email_address = 'notifications@centernext.net',
    @mailserver_name = 'smtp.1and1.com',
	@port = 587,
	@enable_ssl=0,
	@username='notifications@centernext.net',
	@password='@PhAiobES6'

--==========================================================
-- Create a Database Mail Profile
--==========================================================
EXECUTE msdb.dbo.sysmail_add_profile_sp
@profile_name = 'SQLMailProfile',
@description = 'DB Mail Service for SQL Server' 
--==========================================================
-- Add account to the profile
--==========================================================
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = 'SQLMailProfile',
@account_name = 'Mail Centernext2',
@sequence_number =1 ;
--==========================================================
-- Grant access to the profile
--==========================================================
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
@profile_name = 'SQLMailProfile',
@principal_id = 0,
@is_default = 1

--==========================================================
-- Create stored procedure to export
--==========================================================

USE ccReportsRia;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE[dbo].[spgenerate_excel_with_columns]
(
    @db_name    varchar(100),
    @table_name varchar(100),   
    @file_name  varchar(100),
   @file varchar(100) 
)
as
select @file=@file_name+@file
--Generate column names as a recordset
declare @columns varchar(8000), @sql varchar(8000), @data_file varchar(1000)


select 
    @columns=coalesce(@columns+',','')+column_name+' as '+column_name 
from 
    information_schema.columns
where 
    table_name=@table_name
select @columns=''''''+replace(replace(@columns,' as ',''''' as '),',',',''''')

--Create a dummy file to have actual data
select @data_file=substring(@file_name,1,len(@file_name)-charindex('\',reverse(@file_name)))+'\data_file_template.xls'

--Generate column names in the passed EXCEL file
set @sql='exec master..xp_cmdshell ''bcp " select * from (select '+@columns+') as t" queryout "'+@file+'" -T -c'''
exec(@sql)
print @sql



--Generate data in the dummy file
set @sql='exec master..xp_cmdshell ''bcp "select * from '+@db_name+'..'+@table_name+'" queryout "'+@data_file+'" -T -c'''
exec(@sql)
print @sql
--Copy dummy file to passed EXCEL file

set @sql= 'exec master..xp_cmdshell ''type '+@data_file+' >> "'+@file+'"'''
exec(@sql)
print @sql
--Delete dummy file 
set @sql= 'exec master..xp_cmdshell ''del '+@data_file+''''
exec(@sql)
print @sql

GO

--==========================================================
-- Create Job GenerarEnviarReporteDiario
--==========================================================

USE [msdb]
GO

/****** Object:  Job [GenerarEnviarReporteDiario]    Script Date: 04/03/2020 01:15:56 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/03/2020 01:15:56 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'GenerarEnviarReporteDiario', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generar Archivo Reporte Detalle de Marcacion]    Script Date: 04/03/2020 01:15:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generar Archivo Reporte Detalle de Marcacion', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @dbCustomer VARCHAR(100);
SET @dbCustomer = ''ccReportsRia''

DECLARE @customerName VARCHAR(200);
SET @customerName = ''DetalleMarcacion''

DECLARE @fechaIni varchar(40);
SET @fechaIni = REPLACE(CONVERT(NVARCHAR, DATEADD(DD, 0, GETDATE() ) , 102), ''.'', ''-'') + '' 00:00'';

DECLARE @Repository varchar(250);
SET @Repository = ''C:\Centerware\ReportesDiarios\'' + @customerName + ''\'' + REPLACE(CONVERT(NVARCHAR, DATEADD(DD, 0, GETDATE() ), 102), ''.'', ''_'') + ''\''

-- Creando repositorio donde se pondran los reportes del día
DECLARE @commnad varchar(200)
SET @commnad = ''MD '' + @Repository
EXEC xp_cmdshell  @commnad

Declare @nombreArch varchar(50)    
       SET @nombreArch = convert(varchar, getdate(), 112) + ''.xls''

    --- Tabla que conendrá la información de la campaña
    IF OBJECT_ID(''dbo.tempCallReport2'', ''U'') IS NOT NULL 
        DROP TABLE dbo.tempCallReport2;

    CREATE TABLE tempCallReport2
    (
        [Fecha] varchar(MAX),
		[callKey] varchar(MAX),
		[Telefono] varchar(MAX),
		[Resultado de marcacion] varchar(MAX),
		[Campaña] varchar(MAX),
		[tiempo de rep mensaje] varchar(MAX),
		[Año] varchar(MAX),
		[Mes] varchar(MAX),
		[Día] varchar(MAX),
		[Hora] varchar(MAX),
		[Minutos] varchar(MAX),
		[Nombre de Lista] varchar(MAX),
		[Facturación] varchar(MAX),
		[Dato1] varchar(MAX),
		[Dato2] varchar(MAX),
		[Dato3] varchar(MAX),
		[Dato4] varchar(MAX),
		[Data5] varchar(MAX),
		[Repositorio de grabación] varchar(MAX),
		[Estado de proveedor] varchar(MAX),
		[Estado de proveedor 2] varchar(MAX),
		[Tipo de marcación] varchar(MAX),
		[Tipo de teléfono] varchar(MAX),
		[Calificación] varchar(MAX),
		[Sub Calificaciones] varchar(MAX)
    );

    INSERT INTO tempCallReport2
    values
        (''Fecha'' ,
		''callKey'' ,
		''Telefono'' ,
		''Resultado de marcacion'' , 
		''Campaña'' ,
		''tiempo de rep mensaje'' ,
		''Año'' ,
		''Mes'' ,
		''Día'' ,
		''Hora'' ,
		''Minutos'' ,
		''Nombre de Lista'' ,
		''Facturación'' ,
		''Dato1'' ,
		''Dato2'' ,
		''Dato3'' ,
		''Dato4'' ,
		''Data5'' ,
		''Repositorio de grabación'' ,
		''Estado de proveedor'' ,
		''Estado de proveedor 2'' ,
		''Tipo de marcación'' ,
		''Tipo de teléfono'' ,
		''Calificación'' ,
		''Sub Calificaciones'')

    INSERT INTO tempCallReport2 with(tablockx)
    exec sp_executesql @stmt=N''SELECT date,
										callKey,
										telephone,
										dialResult,
										campaign,
										timeMessage,
										year,
										month,
										day,
										hour,
										minutes,
										listName,
										CASE 
											WHEN billed = ''''systemTranslated_NotCharged'''' THEN ''''No cobrada''''
											WHEN billed = ''''systemTranslated_Charged'''' THEN ''''Cobrada''''
											ELSE billed 
										END AS billed,
										data1,
										data2,
										data3,
										data4,
										data5,
										CASE
											WHEN fileMoved = ''''systemTranslated_Remoto'''' THEN ''''Remoto''''
											ELSE fileMoved
										END AS fileMoved,
										disconnectCause,
										DCCustomer,
										CASE 
											WHEN dialType = ''''systemTranslated_Auto'''' THEN ''''Automático''''
											WHEN dialType = ''''systemTranslated_Manual'''' THEN ''''Manual''''
										ELSE dialType
										END AS dialType,
										CASE
											WHEN TipoTel = ''''systemTranslated_Indefinite'''' THEN ''''Indefinido''''
											WHEN TipoTel = ''''systemTranslated_cellPhone'''' THEN ''''Celular''''
											WHEN TipoTel = ''''systemTranslated_fijo'''' THEN ''''Fijo''''
										ELSE TipoTel END AS TipoTel,
										CallDisposition,
										CallSubDisposition
								FROM RepOutDialDetail WITH(NOLOCK)
								WHERE date >= @dateStart''
								,@params=N''@dateStart DateTime''
								,@dateStart=@fechaIni

    EXEC spgenerate_excel_with_columns @dbCustomer, ''tempCallReport2'', @Repository, @nombreArch

    DROP TABLE tempCallReport2
', 
		@database_name=N'ccReportsRia', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Enviar Reporte Detalle de Marcacion]    Script Date: 04/03/2020 01:15:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Enviar Reporte Detalle de Marcacion', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=10, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @customerName VARCHAR(200);
SET @customerName = ''DetalleMarcacion''

Declare @nombreArch varchar(50)    
       SET @nombreArch = convert(varchar, getdate(), 112) + ''.xls''

DECLARE @attachmentFile varchar(250);
SET @attachmentFile = ''C:\Centerware\ReportesDiarios\'' + @customerName + ''\'' + REPLACE(CONVERT(NVARCHAR, DATEADD(DD, 0, GETDATE() ), 102), ''.'', ''_'') + ''\''+@nombreArch

SELECT @attachmentFile


EXEC msdb.dbo.sp_send_dbmail
	@profile_name = ''SQLMailProfile''
	,@recipients = ''soluciones@reddemate.com; cesar.zaragoza@mccollect.com.mx; infodata@conefectiva.com; coordinacion@conefectiva.com; bacKoffice@conefectiva.com''
	,@body = ''Se adjunta el reporte de Detalle de Marcación''
	,@subject = ''Reporte Detalle de Marcación'',
     @file_attachments=@attachmentFile', 
		@database_name=N'ccReportsRia', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generar Archivo Reporte Detalle de Llamadas Contestadas]    Script Date: 04/03/2020 01:15:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generar Archivo Reporte Detalle de Llamadas Contestadas', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @dbCustomer VARCHAR(100);
SET @dbCustomer = ''ccReportsRia''

DECLARE @customerName VARCHAR(200);
SET @customerName = ''DetalleLlamadasC''

DECLARE @fechaIni varchar(40);
SET @fechaIni = REPLACE(CONVERT(NVARCHAR, DATEADD(DD, 0, GETDATE() ) , 102), ''.'', ''-'') + '' 00:00'';

DECLARE @Repository varchar(250);
SET @Repository = ''C:\Centerware\ReportesDiarios\'' + @customerName + ''\'' + REPLACE(CONVERT(NVARCHAR, DATEADD(DD, 0, GETDATE() ), 102), ''.'', ''_'') + ''\''

-- Creando repositorio donde se pondran los reportes del día
DECLARE @commnad varchar(200)
SET @commnad = ''MD '' + @Repository
EXEC xp_cmdshell  @commnad

Declare @nombreArch varchar(50)    
       SET @nombreArch = convert(varchar, getdate(), 112) + ''.xls''

    --- Tabla que conendrá la información de la campaña
    IF OBJECT_ID(''dbo.tempCallReport'', ''U'') IS NOT NULL 
        DROP TABLE dbo.tempCallReport;

    CREATE TABLE tempCallReport
    (
        [Fecha] varchar(MAX),
		[callKey] varchar(MAX),
		[Telefono] varchar(MAX),
		[En trasferencia] varchar(MAX),
		[En diálogo] varchar(MAX),
		[En espera] varchar(MAX),
		[Tiempo de Notas] varchar(MAX),
		[Calificación] varchar(MAX),
		[Extensión] varchar(MAX),
		[ID de agente] varchar(MAX),
		[Agente] varchar(MAX),
		[Nombre de Usuario] varchar(MAX),
		[Campaña] varchar(MAX),
		[Duración] varchar(MAX),
		[Costo] varchar(MAX),
		[IVA] varchar(MAX),
		[Total] varchar(MAX),
		[Proveedor] varchar(MAX),
		[Tipos de llamadas] varchar(MAX),
		[Tipo de marcación] varchar(MAX),
		[Colgó] varchar(MAX),
		[Sub Calificación] varchar(MAX),
		[Resultado de marcacion] varchar(MAX),
		[ID de llamada] varchar(MAX),
		[Año] varchar(MAX),
		[Mes] varchar(MAX),
		[Día] varchar(MAX),
		[Hora] varchar(MAX),
		[Minutos] varchar(MAX),
		[Puerto] varchar(MAX),
		[Dato1] varchar(MAX),
		[Dato2] varchar(MAX),
		[Dato3] varchar(MAX),
		[Dato4] varchar(MAX),
		[Data5] varchar(MAX),
		[Tiempo en mensaje] varchar(MAX)
    );

    INSERT INTO tempCallReport
    values
        (''Fecha'',
			''callKey'',
			''Telefono'',
			''En trasferencia'',
			''En diálogo'',
			''En espera'',
			''Tiempo de Notas'',
			''Calificación'',
			''Extensión'',
			''ID de agente'',
			''Agente'',
			''Nombre de Usuario'',
			''Campaña'',
			''Duración'',
			''Costo'',
			''IVA'',
			''Total'',
			''Proveedor'',
			''Tipos de llamadas'',
			''Tipo de marcación'',
			''Colgó'',
			''Sub Calificación'',
			''Resultado de marcacion'',
			''ID de llamada'',
			''Año'',
			''Mes'',
			''Día'',
			''Hora'',
			''Minutos'',
			''Puerto'',
			''Dato1'',
			''Dato2'',
			''Dato3'',
			''Dato4'',
			''Data5'',
			''Tiempo en mensaje'')

    INSERT INTO tempCallReport with(tablockx)
    exec sp_executesql @stmt=N''SELECT date,callKey,telephone,transfer,dialog,nque,wrapup
									,CallDisposition
									,extension,userId,login,username,campaign,duration,
									ncost,iva
									,total
									,Case When ByCarrier = ''''systemTranslated_NoCarrier'''' Then ''''Sin proveedor'''' else ByCarrier end AS ByCarrier
									,Case When Calltypes = ''''systemTranslated_Indefinite'''' Then ''''Indefinido'''' else Calltypes end AS Calltypes
									,Case When dialType = ''''systemTranslated_Manual'''' THEN ''''Manual'''' 
										  WHEN dialType = ''''systemTranslated_Auto'''' THEN ''''Automático'''' 
										  ELSE dialType END AS dialType
									,Case When whoHangUp = ''''systemTranslated_Agent'''' THEN ''''Agente'''' 
										  WHEN whoHangUp = ''''systemTranslated_Client'''' THEN ''''Cliente'''' 
										  ELSE whoHangUp END AS whoHangUp
									,subDisposition,
									dialResult,calId,year,month,day,hour,minutes,trunk,data1,data2,data3,
									data4,data5,MessageTime
								FROM RepOutCallsDetail WITH(NOLOCK) 
								WHERE date >= @dateStart'',@params=N''@dateStart DateTime'',@dateStart=@fechaIni

    EXEC spgenerate_excel_with_columns @dbCustomer, ''tempCallReport'', @Repository, @nombreArch

    DROP TABLE tempCallReport
', 
		@database_name=N'ccReportsRia', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Enviar Reporte Detalle de Llamadas Contestadas]    Script Date: 04/03/2020 01:15:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Enviar Reporte Detalle de Llamadas Contestadas', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=10, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @customerName VARCHAR(200);
SET @customerName = ''DetalleLlamadasC''

Declare @nombreArch varchar(50)    
       SET @nombreArch = convert(varchar, getdate(), 112) + ''.xls''

DECLARE @attachmentFile varchar(250);
SET @attachmentFile = ''C:\Centerware\ReportesDiarios\'' + @customerName + ''\'' + REPLACE(CONVERT(NVARCHAR, DATEADD(DD, 0, GETDATE() ), 102), ''.'', ''_'') + ''\''+@nombreArch

SELECT @attachmentFile


EXEC msdb.dbo.sp_send_dbmail
	@profile_name = ''SQLMailProfile''
	,@recipients = ''soluciones@reddemate.com; cesar.zaragoza@mccollect.com.mx; infodata@conefectiva.com; coordinacion@conefectiva.com; bacKoffice@conefectiva.com''
	,@body = ''Se adjunta el reporte de Detalle de llamadas contestadas''
	,@subject = ''Reporte Detalle de llamadas contestadas'',
     @file_attachments=@attachmentFile', 
		@database_name=N'ccReportsRia', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Termino de horario', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200304, 
		@active_end_date=99991231, 
		@active_start_time=221000, 
		@active_end_time=235959, 
		@schedule_uid=N'4810adbd-8110-4062-822b-61c6a2409640'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

