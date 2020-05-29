/*
Autor: Jesus Gallardo
Fecha: 2014/06/09
Descripcion:
	Se agrega menu para reporte de llamadas con chat
	Se agrega filtros para reportes de llamadas con chat campañas y usuarios
	Se agrega filtros en ReportsFiltersMenus para reportes de llamadas fecha y filtrar por
	Se agrega graficas en ReportsCharts para reportes de llamadas para campaña
	Se agrega Reportes totales en ReportsTotals para llamadas con chat
	Se agrega las traduciones en TranslatedReports para reportes llamadas con chat
	Se crea la tabla RepOutCallsOnChatDetail para el reporte de llamadas con chat
	Se crea el indece IX_RepOutCallsOnChatDetail para la tabla RepOutCallsOnChatDetail
	Se actuliza nombre de columna avgAbandonTime por avgAbandonTimeChat en RepChatsEffectiveness fix tipo dato
	Se actuliza ReportsTotals por cambia de columna del reporte RepChatsEffectiveness
	Se Modifica el SP ccspRepOutDialDetail para 
	Se crea el SP ccspRepOutCallsOnChatDetail para el reporte de llamadas con chat
	Se pone rol dbwoner al sa si este es diferente
	Se crea el JOB ccspRepOutCallsOnChatDetail para la generacion de informacion del reporte de llamadas con chat
	Se actualiza el plan de mantenmiento 
	
Version requerida: 15
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '16'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
	set @process = 'ccMenus -- insert '
	set @Sql=' if not exists(select * from ccmenus where menu_id=4140 and type=3) 
	insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF)
values (4140,''Detalle de llamadas en chat contestadas|Answered Calls On Chat Detail'',4000,''B'',4,3,'''')'

	EXEC(@Sql)

	set @process = 'ReportsFilters -- insert '
	set @Sql='insert into ReportsFilters (reportName, filterName, id) values(''Answered Calls On Chat Detail'', ''campaigns'', 4140)
insert into ReportsFilters (reportName, filterName, id) values(''Answered Calls On Chat Detail'', ''users'', 4140)'

	EXEC(@Sql)


	set @process = 'ReportsFiltersMenus -- insert'
	set @Sql='INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4140, N''date'')
INSERT [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) VALUES (4140, N''filterby'')'

	EXEC(@Sql)

	set @process = 'ReportsCharts -- insert'
	set @Sql='insert into ReportsCharts values (4140, ''Answered Calls On Chat Detail'', 1, ''campaign'', '''', '''', '''', '''', ''Answered calls on chat detail per Campaign'', 0) 
insert into ReportsCharts values (4140, ''Answered Calls On Chat Detail'', 2, ''year|month|day'', ''campaign'', '''', '''', '''', ''Answered calls on chat detail per Campaign by day'', 0)'

	EXEC(@Sql)


	set @process = 'ReportsTotals -- insert'
	set @Sql='insert into ReportsTotals values(4140,''sum:transfer|sum:dialog|sum:nque|sum:wrapup|sum:duration|sum:ncost|sum:total'')'

	EXEC(@Sql)

	set @process = 'TranslatedReports --  insert'
	set @Sql='insert into TranslatedReports values(4140,''login|campaign|ByCarrier|Calltypes|dialType|whoHangUp|subDisposition'')'

	EXEC(@Sql)


		set @process = 'RepOutCallsOnChatDetail -- Create Table'
		set @Sql = 'CREATE TABLE [dbo].[RepOutCallsOnChatDetail](
	[date] [datetime] NOT NULL,
	[callKey] [varchar](255) NOT NULL,
	[telephone] [varchar](255) NOT NULL,
	[transfer] [int] NOT NULL,
	[dialog] [int] NOT NULL,
	[nque] [int] NOT NULL,
	[wrapup] [int] NOT NULL,
	[CallDisposition] [varchar](255) NOT NULL,
	[extension] [varchar](255) NOT NULL,
	[userId] [int] NOT NULL,
	[login] [varchar](255) NOT NULL,
	[username] [varchar](255) NOT NULL,
	[campaignId] [int] NOT NULL,
	[campaign] [varchar](255) NOT NULL,
	[duration] [int] NOT NULL,
	[ncost] [decimal](10, 2) NOT NULL,
	[iva] [int] NOT NULL,
	[total] [decimal](10, 2) NOT NULL,
	[ByCarrier] [varchar](255) NOT NULL,
	[Calltypes] [varchar](255) NOT NULL,
	[dialType] [varchar](255) NOT NULL,
	[whoHangUp] [varchar](255) NOT NULL,
	[subDisposition] [varchar](255) NOT NULL,
	[dialResult] [varchar](255) NOT NULL,
	[calId] [int] NOT NULL,
	[trunk] [smallint] NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
		
		EXEC(@Sql)
		
		set @process = 'IX_RepOutCallsOnChatDetail -- Create Index'
		set @Sql = 'CREATE NONCLUSTERED INDEX [IX_RepOutCallsOnChatDetail] ON [dbo].[RepOutCallsOnChatDetail]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
'
		
		EXEC(@Sql)
		
		set @process = 'RepChatsEffectiveness --  Rename column'
		set @Sql = 'sp_RENAME ''[RepChatsEffectiveness].[avgAbandonTime]'' , ''avgAbandonTimeChat'', ''COLUMN'''
		
		EXEC(@Sql)
		
		set @process = 'ReportsTotals -- update RepChatsEffectiveness'
		set @Sql = 'update ReportsTotals set TotalColumns = ''sum:ntotalChat|sum:nanswerChat|sum:nabndChat|special:avgAnswerTime:convert(decimal(10_2)_ISNULL((sum(nanswerChat) * 100.00)/NULLIF(sum(ntotalChat)_0)_0))|special:avgQueueTime:convert(decimal(10_2)_sum(avgQueueTime))|special:avgAbandonTimeChat:convert(decimal(10_2)_ISNULL((sum(nabndChat) * 100.00)/NULLIF(sum(ntotalChat)_0)_0))'' WHERE Id=3135'
		
		EXEC(@Sql)
		
		set @process = 'ccspRepOutDialDetail --  Alter SP'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		--Borrar lo que esta para no repetir
		delete from RepOutDialDetail with(rowlock)
		where date >= @from AND date < @to

		--Inserta información de reporte
		insert into RepOutDialDetail
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime, datepart(yyyy,fecha),
		datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha)
		FROM
			(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key
			FROM ccoLogDials dial
			left join ccocallsout co on (dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono and 
			tiporesdial_id = 1  
and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) >= 
	convert(datetime,convert(varchar(19),dial.fecha),121) 
and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) <= 
	convert(datetime,convert(varchar(19),dial.fecha),121))
			WHERE fecha >= @from AND fecha < @to) dials     
		LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id LEFT JOIN cctipoResultadoDial tr
		ON dials.tiporesdial_id=tr.tiporesdial_id LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]    
		WHERE fecha >= @from AND fecha < @to
		order by fecha
	end'
		
		EXEC(@Sql)
		
		set @process = 'ccspRepOutCallsOnChatDetail -- Create SP'
		set @Sql = 'CREATE PROCEDURE [dbo].[ccspRepOutCallsOnChatDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsOnChatDetail with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepOutCallsOnChatDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else ''systemTranslated_NoCarrier'' end as [ByCarrier],		
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''systemTranslated_Client'' else ''systemTranslated_Agent'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		,Call.cal_puerto
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = 1)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual = 3
		order by date
	end'
		
		EXEC(@Sql)				
			

	set @process = 'update -- dbowner DATABASE'
	set @Sql='if not exists (select * from sys.databases where suser_sname(owner_sid)=''sa'' and name=''ccReportsRia'') ALTER AUTHORIZATION ON DATABASE::ccReportsRia TO sa'

	EXEC(@Sql)

		
		set @process = 'ccspRepOutCallsOnChatDetail -- Job'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepOutCallsOnChatDetail]    Script Date: 03/06/2014 09:10:15 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/06/2014 09:10:15 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepOutCallsOnChatDetail'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ccspRepOutCallsOnChatDetail'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 03/06/2014 09:10:16 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC [ccspRepOutCallsOnChatDetail] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
		EXEC(@Sql)
		
		set @process = 'NuxibaNewReportsMaintenancePlan -- Job'
		set @Sql = 'USE [msdb]

/****** Object:  Job [NuxibaNewReportsMaintenancePlan]    Script Date: 04/09/2014 16:23:13 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaNewReportsMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaNewReportsMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaNewReportsMaintenancePlan]    Script Date: 04/07/2014 16:48:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/07/2014 16:48:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaNewReportsMaintenancePlan'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''NuxibaNewReportsMaintenancePlan'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 04/07/2014 16:48:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Database Task]    Script Date: 04/07/2014 16:48:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Database Task'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKDATABASE(N''''ccReportsRia'''', 10, TRUNCATEONLY)'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccReports_Log'''',1)'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reorginize Index Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Reorginize Index Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [uc_ccCalifCamp] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_6] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCallsReject] ON [dbo].[cccallsreject] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamps] ON [dbo].[cccamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cccatgpo_camp] ON [dbo].[cccatgpo_camp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccDNIS] ON [dbo].[ccdnis] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccdnis] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGen900] ON [dbo].[ccGen900] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [DF_ccGenAgent_tnot_av] ON [dbo].[ccGenAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAbndWG] ON [dbo].[ccGenInAbndWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAnswWG] ON [dbo].[ccGenInAnswWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCalifWG] ON [dbo].[ccGenInCalifWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCallWG] ON [dbo].[ccGenInCallWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInSpec] ON [dbo].[ccGenInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInSpecWG] ON [dbo].[ccGenInSpecWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInsubCalif] ON [dbo].[ccGenInSubCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenMktIntervaloSalida] ON [dbo].[ccGenMktIntervaloSalida] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallCalifWG] ON [dbo].[ccGenOutCallCalifWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [campana] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallDialsWG] ON [dbo].[ccGenOutCallDialsWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDialsWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [WorkGroup] ON [dbo].[ccGenOutCallDialsWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallWG] ON [dbo].[ccGenOutCallWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCamp] ON [dbo].[ccGenOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCampWG] ON [dbo].[ccGenOutCampWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenOutCstoRes_userId] ON [dbo].[ccGenOutCstoResumen] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenOutDialCamp] ON [dbo].[ccGenOutDialCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenOutDialCamp_1] ON [dbo].[ccGenOutDialCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutPortStats] ON [dbo].[ccGenOutPortStats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutsubCalif] ON [dbo].[ccGenOutSubCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IndiceResumen] ON [dbo].[ccGenResumenAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSession] ON [dbo].[ccGenSession] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccinbound] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccinboundagentes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[cclogagentesnotready] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[cclogagentesnotready] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[cclogagentesnotready] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[cclogagentesnotready] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccloglogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccloglogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccloglogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccloglogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogtransfers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallbacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallbacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallbacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallbacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_13] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut12] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_11] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_12] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_13] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_14] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoDialers] ON [dbo].[ccodialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccodialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionCamps1] ON [dbo].[ccPosicionCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionCamps2] ON [dbo].[ccPosicionCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionCamps3] ON [dbo].[ccPosicionCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionEspecialidad1] ON [dbo].[ccPosicionEspecialidad] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionEspecialidad2] ON [dbo].[ccPosicionEspecialidad] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionEspecialidad3] ON [dbo].[ccPosicionEspecialidad] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChats_1] ON [dbo].[ccriachats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatStatus] ON [dbo].[ccriachatstatus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logdial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logdial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccriaworkgroupusers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccstatusllamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSup_Usuario] ON [dbo].[ccSup_Usuario] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ix_tipo_1] ON [dbo].[ccsupervisorcam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccsupervisorcam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[cctipocalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[cctipocalifsub] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[cctipocalifsubout] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[cctiponotready] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[cctipoResultadodial] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctiposubcalifrel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_Charts] ON [dbo].[Charts] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoprovedor] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstotarifa] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstotipollamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_FavoriteTemplates] ON [dbo].[FavoriteTemplates] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_Filters] ON [dbo].[Filters] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_FiltersMenus] ON [dbo].[FiltersMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[ivrcallsin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepACDChats] ON [dbo].[RepACDChats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAgentGI] ON [dbo].[RepAgentGI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAgentKPI] ON [dbo].[RepAgentKPI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAgentNotReady] ON [dbo].[RepAgentNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAgentNotReadyDet] ON [dbo].[RepAgentNotReadyDet] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAgentSession] ON [dbo].[RepAgentSession] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAvgAnswerTimeChats] ON [dbo].[RepAvgAnswerTimeChats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSAgent] ON [dbo].[RepAVRSAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSDisposition] ON [dbo].[RepAVRSDisposition] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSQuestionDetail] ON [dbo].[RepAVRSQuestionDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSRateDetail] ON [dbo].[RepAVRSRateDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSScores] ON [dbo].[RepAVRSScores] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSSection] ON [dbo].[RepAVRSSection] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepAVRSSupervisor] ON [dbo].[RepAVRSSupervisor] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepCallXfer] ON [dbo].[RepCallXfer] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepChatsAndCallsGeneral] ON [dbo].[RepChatsAndCallsGeneral] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepChatsDetail] ON [dbo].[RepChatsDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepChatsEffectiveness] ON [dbo].[RepChatsEffectiveness] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepChatsNotContacted] ON [dbo].[RepChatsNotContacted] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInAbnd] ON [dbo].[RepInAbnd] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInAnsw] ON [dbo].[RepInAnsw] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInBill01900] ON [dbo].[RepInBill01900] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInCalls] ON [dbo].[RepInCalls] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInCallsDetail] ON [dbo].[RepInCallsDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInChangeFlow] ON [dbo].[RepInChangeFlow] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_RepInChangeFlow] ON [dbo].[RepInChangeFlow] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInDIDResume] ON [dbo].[RepInDIDResume] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInDispositions] ON [dbo].[RepInDispositions] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInEffectiveness] ON [dbo].[RepInEffectiveness] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInNotTransferred] ON [dbo].[RepInNotTransferred] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInRejectedCalls] ON [dbo].[RepInRejectedCalls] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInSubDispositions] ON [dbo].[RepInSubDispositions] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepInTrunkBusy] ON [dbo].[RepInTrunkBusy] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepIVRByOptions] ON [dbo].[RepIVRByOptions] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepIVRDetail] ON [dbo].[RepIVRDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepIVRFirstOption] ON [dbo].[RepIVRFirstOption] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepIVRGeneral] ON [dbo].[RepIVRGeneral] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ReportsCharts] ON [dbo].[ReportsCharts] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ReportsFilters] ON [dbo].[ReportsFilters] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ReportsTotals] ON [dbo].[ReportsTotals] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutAnswCalls] ON [dbo].[RepOutAnswCalls] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutCallBacks] ON [dbo].[RepOutCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutCallBilling] ON [dbo].[RepOutCallBilling] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutCalls] ON [dbo].[RepOutCalls] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutCallsByTelephone] ON [dbo].[RepOutCallsByTelephone] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutCallsDetail] ON [dbo].[RepOutCallsDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutCallsOnChatDetail] ON [dbo].[RepOutCallsOnChatDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutDialDetail] ON [dbo].[RepOutDialDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutDials] ON [dbo].[RepOutDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutDispositions] ON [dbo].[RepOutDispositions] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutKPI] ON [dbo].[RepOutKPI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutKPI_1] ON [dbo].[RepOutKPI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutSubDispositions] ON [dbo].[RepOutSubDispositions] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepOutTrunkBusy] ON [dbo].[RepOutTrunkBusy] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpececialAbnd] ON [dbo].[RepSpececialAbnd] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpececialAgent] ON [dbo].[RepSpececialAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpececialAgtPerformance] ON [dbo].[RepSpececialAgtPerformance] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpececialCamMovs] ON [dbo].[RepSpececialCamMovs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpececialPromises] ON [dbo].[RepSpececialPromises] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpecialCallKeyHistory] ON [dbo].[RepSpecialCallKeyHistory] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpecialCallKeyHistory2] ON [dbo].[RepSpecialCallKeyHistory] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepSpecialTimes] ON [dbo].[RepSpecialTimes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_RepTrunkBusy] ON [dbo].[RepTrunkBusy] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_RIA_CONCEPTOS] ON [dbo].[RIA_CONCEPTOS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_TREC_FORMACALIF] ON [dbo].[RIA_FORMACALIF] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_RIA_FORMATOS] ON [dbo].[RIA_FORMATOS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_RIA_GRABACION] ON [dbo].[RIA_GRABACION] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_TREC_GRABACIONCONSULTA] ON [dbo].[RIA_GRABACIONCONSULTA] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_RIA_PREGUNTAS] ON [dbo].[RIA_PREGUNTAS] REORGANIZE WITH ( LOB_COMPACTION = ON )'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rebuild Index Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Rebuild Index Task'', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [uc_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_6] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCallsReject] ON [dbo].[cccallsreject] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamps] ON [dbo].[cccamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cccatgpo_camp] ON [dbo].[cccatgpo_camp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccDNIS] ON [dbo].[ccdnis] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccdnis] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGen900] ON [dbo].[ccGen900] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [DF_ccGenAgent_tnot_av] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAbndWG] ON [dbo].[ccGenInAbndWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAnswWG] ON [dbo].[ccGenInAnswWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCalifWG] ON [dbo].[ccGenInCalifWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCallWG] ON [dbo].[ccGenInCallWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInSpec] ON [dbo].[ccGenInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInSpecWG] ON [dbo].[ccGenInSpecWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInsubCalif] ON [dbo].[ccGenInSubCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenMktIntervaloSalida] ON [dbo].[ccGenMktIntervaloSalida] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallCalifWG] ON [dbo].[ccGenOutCallCalifWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [campana] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallDialsWG] ON [dbo].[ccGenOutCallDialsWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDialsWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [WorkGroup] ON [dbo].[ccGenOutCallDialsWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallWG] ON [dbo].[ccGenOutCallWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCamp] ON [dbo].[ccGenOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCampWG] ON [dbo].[ccGenOutCampWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenOutCstoRes_userId] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenOutDialCamp] ON [dbo].[ccGenOutDialCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenOutDialCamp_1] ON [dbo].[ccGenOutDialCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutPortStats] ON [dbo].[ccGenOutPortStats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutsubCalif] ON [dbo].[ccGenOutSubCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IndiceResumen] ON [dbo].[ccGenResumenAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSession] ON [dbo].[ccGenSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccinbound] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccinboundagentes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[cclogagentesnotready] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[cclogagentesnotready] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[cclogagentesnotready] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[cclogagentesnotready] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccloglogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccloglogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccloglogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccloglogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogtransfers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallbacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallbacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallbacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallbacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_13] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut12] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_11] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_12] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_13] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_14] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoDialers] ON [dbo].[ccodialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccodialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionCamps1] ON [dbo].[ccPosicionCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionCamps2] ON [dbo].[ccPosicionCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionCamps3] ON [dbo].[ccPosicionCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionEspecialidad1] ON [dbo].[ccPosicionEspecialidad] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionEspecialidad2] ON [dbo].[ccPosicionEspecialidad] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionEspecialidad3] ON [dbo].[ccPosicionEspecialidad] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChats_1] ON [dbo].[ccriachats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatStatus] ON [dbo].[ccriachatstatus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logdial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logdial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccriaworkgroupusers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccstatusllamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSup_Usuario] ON [dbo].[ccSup_Usuario] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ix_tipo_1] ON [dbo].[ccsupervisorcam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccsupervisorcam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[cctipocalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[cctipocalifsub] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[cctipocalifsubout] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[cctiponotready] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[cctipoResultadodial] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctiposubcalifrel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_Charts] ON [dbo].[Charts] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoprovedor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstotarifa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstotipollamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )
ALTER INDEX [PK_FavoriteTemplates] ON [dbo].[FavoriteTemplates] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_Filters] ON [dbo].[Filters] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_FiltersMenus] ON [dbo].[FiltersMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[ivrcallsin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepACDChats] ON [dbo].[RepACDChats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAgentGI] ON [dbo].[RepAgentGI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAgentKPI] ON [dbo].[RepAgentKPI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAgentNotReady] ON [dbo].[RepAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAgentNotReadyDet] ON [dbo].[RepAgentNotReadyDet] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAgentSession] ON [dbo].[RepAgentSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAvgAnswerTimeChats] ON [dbo].[RepAvgAnswerTimeChats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSAgent] ON [dbo].[RepAVRSAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSDisposition] ON [dbo].[RepAVRSDisposition] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSQuestionDetail] ON [dbo].[RepAVRSQuestionDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSRateDetail] ON [dbo].[RepAVRSRateDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSScores] ON [dbo].[RepAVRSScores] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSSection] ON [dbo].[RepAVRSSection] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepAVRSSupervisor] ON [dbo].[RepAVRSSupervisor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepCallXfer] ON [dbo].[RepCallXfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepChatsAndCallsGeneral] ON [dbo].[RepChatsAndCallsGeneral] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepChatsDetail] ON [dbo].[RepChatsDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepChatsEffectiveness] ON [dbo].[RepChatsEffectiveness] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepChatsNotContacted] ON [dbo].[RepChatsNotContacted] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInAbnd] ON [dbo].[RepInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInAnsw] ON [dbo].[RepInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInBill01900] ON [dbo].[RepInBill01900] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInCalls] ON [dbo].[RepInCalls] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInCallsDetail] ON [dbo].[RepInCallsDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInChangeFlow] ON [dbo].[RepInChangeFlow] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_RepInChangeFlow] ON [dbo].[RepInChangeFlow] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInDIDResume] ON [dbo].[RepInDIDResume] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInDispositions] ON [dbo].[RepInDispositions] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInEffectiveness] ON [dbo].[RepInEffectiveness] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInNotTransferred] ON [dbo].[RepInNotTransferred] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInRejectedCalls] ON [dbo].[RepInRejectedCalls] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInSubDispositions] ON [dbo].[RepInSubDispositions] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepInTrunkBusy] ON [dbo].[RepInTrunkBusy] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepIVRByOptions] ON [dbo].[RepIVRByOptions] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepIVRDetail] ON [dbo].[RepIVRDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepIVRFirstOption] ON [dbo].[RepIVRFirstOption] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepIVRGeneral] ON [dbo].[RepIVRGeneral] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ReportsCharts] ON [dbo].[ReportsCharts] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ReportsFilters] ON [dbo].[ReportsFilters] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ReportsTotals] ON [dbo].[ReportsTotals] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutAnswCalls] ON [dbo].[RepOutAnswCalls] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutCallBacks] ON [dbo].[RepOutCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutCallBilling] ON [dbo].[RepOutCallBilling] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutCalls] ON [dbo].[RepOutCalls] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutCallsByTelephone] ON [dbo].[RepOutCallsByTelephone] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutCallsDetail] ON [dbo].[RepOutCallsDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutCallsOnChatDetail] ON [dbo].[RepOutCallsOnChatDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutDialDetail] ON [dbo].[RepOutDialDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutDials] ON [dbo].[RepOutDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutDispositions] ON [dbo].[RepOutDispositions] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutKPI] ON [dbo].[RepOutKPI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutKPI_1] ON [dbo].[RepOutKPI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutSubDispositions] ON [dbo].[RepOutSubDispositions] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepOutTrunkBusy] ON [dbo].[RepOutTrunkBusy] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpececialAbnd] ON [dbo].[RepSpececialAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpececialAgent] ON [dbo].[RepSpececialAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpececialAgtPerformance] ON [dbo].[RepSpececialAgtPerformance] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpececialCamMovs] ON [dbo].[RepSpececialCamMovs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpececialPromises] ON [dbo].[RepSpececialPromises] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpecialCallKeyHistory] ON [dbo].[RepSpecialCallKeyHistory] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpecialCallKeyHistory2] ON [dbo].[RepSpecialCallKeyHistory] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepSpecialTimes] ON [dbo].[RepSpecialTimes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_RepTrunkBusy] ON [dbo].[RepTrunkBusy] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_RIA_CONCEPTOS] ON [dbo].[RIA_CONCEPTOS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_TREC_FORMACALIF] ON [dbo].[RIA_FORMACALIF] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_RIA_FORMATOS] ON [dbo].[RIA_FORMATOS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_RIA_GRABACION] ON [dbo].[RIA_GRABACION] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_TREC_GRABACIONCONSULTA] ON [dbo].[RIA_GRABACIONCONSULTA] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_RIA_PREGUNTAS] ON [dbo].[RIA_PREGUNTAS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Statistics Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Update Statistics Task'', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''UPDATE STATISTICS [dbo].[ccCalifCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccallsreject] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMovs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccatgpo_camp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccdnis] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGen900] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgentNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenChart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAbnd] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAbndWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAnsw] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAnswWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCalifWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCallDNI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCallWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSpecWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSubCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenMktIntervaloSalida] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallCalifWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallDialsWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCampWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCstoResumen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutDialCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutPortStats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutSubCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenResumenAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSession] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccgenTelMarcados] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccinbound] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccinboundagentes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia_Dialog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cclogagentesnotready] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccloglogin] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogtransfers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenuUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallbacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOut] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOutSource] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialerCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccodialers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoLogDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicion] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionEspecialidad] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccriaareaworkgroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccriacat_areas] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccriacat_workgroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccriachats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccriachatstatus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_Calid] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_logdial_id] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccriaworkgroupusers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSettings] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccstatusllamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSup_Usuario] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccsupervisorcam] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTemplates] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctipocalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctipocalifsub] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctipocalifsubout] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctiponotready] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctipoResultadodial] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoStatusAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctiposubcalifrel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Charts] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoprovedor] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstotarifa] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstotipollamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[DetailReports] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Exp_Jobs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[exportReports] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[FavoriteTemplates] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Filters] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[FiltersMenus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[GroupByReports] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ivrcallsin] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRLlamadas] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ivroptions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ivrstructure] 
WITH FULLSCAN
If exists (select name from sysobjects where name = ''''migration'''')
	begin
		UPDATE STATISTICS [dbo].[migration] 
		WITH FULLSCAN
	end
UPDATE STATISTICS [dbo].[PivotReports] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepACDChats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAgentGI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAgentKPI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAgentNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAgentNotReadyDet] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAgentSession] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAvgAnswerTimeChats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSDisposition] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSQuestionDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSRateDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSScores] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSSection] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepAVRSSupervisor] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepCallXfer] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepChatsAndCallsGeneral] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepChatsDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepChatsEffectiveness] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepChatsNotContacted] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInAbnd] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInAnsw] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInBill01900] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInCalls] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInCallsDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInChangeFlow] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInDIDResume] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInDispositions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInEffectiveness] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInNotTransferred] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInRejectedCalls] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInSubDispositions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepInTrunkBusy] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepIVRByOptions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepIVRDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepIVRFirstOption] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepIVRGeneral] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ReportsCharts] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ReportsFilters] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ReportsFiltersMenus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ReportsFiltersRange] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ReportsFiltersText] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ReportsTotals] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutAnswCalls] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutCallBacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutCallBilling] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutCalls] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutCallsByTelephone] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutCallsDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutCallsOnChatDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutDialDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutDispositions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutKPI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutSubDispositions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepOutTrunkBusy] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpececialAbnd] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpececialAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpececialAgtPerformance] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpececialCamMovs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpececialPromises] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpecialCallKeyHistory] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepSpecialTimes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RepTrunkBusy] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_CONCEPTOS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_FORMACALIF] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_FORMATOS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_GRABACION] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_GRABACIONCONSULTA] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_PREGUNTAS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_RESPUESTAS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[RIA_RESULTADOSFORMA] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosConferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosTransferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[TranslatedReports] 
WITH FULLSCAN'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up History Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Clean Up History Task'', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @dt datetime 
select @dt = getdate()

exec msdb.dbo.sp_delete_backuphistory @dt

EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt

EXECUTE msdb..sp_maintplan_delete_log null,null,@dt'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Back Up Database Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Back Up Database Task'', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = ''''ccReportsRia_backup_MP'''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''.bak''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''\'''' + @date

drop table #RutaBak

BACKUP DATABASE [ccReportsRia] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10
'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Maintenance Clean Up Task]    Script Date: 04/07/2014 16:48:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Maintenance Clean Up Task'', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''bak'''',@date

drop table #RutaBak'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
