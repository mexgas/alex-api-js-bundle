/*
Autor: Raymundo González
Fecha: 2012/08/28
Descripcion: 
	Inserciones en ccMenus para colocar como visibles los nuevos reportes para asigancion a supervisores
	Se crean y eliminan indices con el fin de mejorar los tiempos de ejecucion de las consultas
	Creacion de la Vista ccGenViewRelsSupsAgent para relciones de agentes y supervisores
	Creacion de la Tabla ccoCallBacks para registrar los callbacks programados por los agentes
	Modificacion del Job CW Callback/abandoned update para actualizar el status de los callbacks a expirado
	Modificacion del Job CW Delete old records para actualizar el status de los callbacks a registro viejo
	Creacion del Job CW Transfer CallBacks Info para paso de informacion de los callbacks de CenterWare a Reportes
	Modificacion del SP ccsp_ADMCalifInformation para mejora en tiempo de respuesta
	Modificacion del SP ccsp_AgentLastNotReady se cambio bloqueo de tabla, utilizacion de indice y evaluacion de NULL
	Modificacion del SP ccsp_AgentSetCallStatus el cual cambia el status de los callbacks de nuevo reporte a Contestado y No Contestado
	Modificacion del SP ccsp_ExtAppsCallHistory para calculo mejorado de los tiempos de sesion, obtiene registros por cal_id y entrega estados del agente
	Modificacion del SP ccsp_GetAgentIndividualCounters para mejora en tiempo de respuesta
	Modificacion del SP ccsp_GetAgentNotReadyDetail para mejora en tiempo de respuesta
	Modificacion del SP ccsp_GetConversionFactor para mejora en tiempo de respuesta y se elimino la informacion de TotalCalls
	Modificacion del SP ccsp_OUTGetAve_Camps se cambio el bloque de tablas, se agregaron y eliminaron indices
	Modificacion del SP ccsp_OUTResetJobs se cambio el bloqueo por fila para la ejecucion del Update
	Modificacion del SP ccsp_RIA_mnuReciclar para cambiar el status a Reciclado de los callbacks del nuevo reporte
	Modificacion del SP ccsp_RIAAdmDelRegs se cambio el bloequeo por fila en Update y Delete
	Modificacion del SP ccsp_RIAGetCampsNvosCB se cambio el bloqueo de tablas
	Modificacion del SP ccsp_RIALoadCamps se cambio la consulta, agrego nueva variable y se utilizo el indice adecuado
	Modificacion del SP ccsp_RIALoadWorkGroup se cambio consulta con subqueries innecesarios
	Modificacion del SP ccsp_RIAOUTInsertNewJOBS_WT_Camp se cambio bloqueo por fila en update y delete, cambios de status a Carga de Registro de los callbacks para nuevo reporte
	Modificacion del SP ccspAgent_GetLastCalls agregando los indices faltantes
	Modificacion del SP ccsp_RIAMenuRoles se agrego validacion para validacion en el caso de ND = 4
	Modificacion del SP ccsp_AdminNotready para corregir errores de tipo de dato
	Modificacion del SP ccsp_DLRInsertDNCList para agregar el telefono original en caso de que el telefono de lista negra sea erroneo
	Modificacion del SP ccsp_AgentUpdateCallTimes para recibir el cal_tmoh desde el agente
	Creacion y modificacion de objetos para planes de marcacion de UK y Arabia

Version requerida: 80
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '81'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

			set @Sql = 'INSERT INTO ccMenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) 
VALUES(2090,''Tiempo en espera|Hold time'',2000,''B'',2,2,'''')

INSERT INTO ccMenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) 
VALUES(4200,''Reprogramación|CallBacks'',4000,''B'',4,2,'''')'
		EXEC(@Sql)

			set @Sql = 'CREATE NONCLUSTERED INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] 
(
	[user_id] ASC,
	[cal_Inicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] 
(
	[User_id] ASC,
	[statuscall_id] ASC,
	[cal_inicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] 
(
	[fecha] ASC,
	[User_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] 
(
	[User_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] 
(
	[user_id] ASC,
	[cal_inicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] 
(
	[User_id] ASC,
	[statuscall_id] ASC,
	[cal_inicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[ccoLogDials]'') AND name = N''IX_ccoLogDials_4'')
DROP INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] WITH ( ONLINE = OFF )'
		EXEC(@Sql)

			set @Sql = 'create view [dbo].[ccGenViewRelsSupsAgent] as

--Relaciones Sup-Agt de acuerdo a WorkGroups  
select distinct a1.user_id as agt, a5.user_id as sup, a5.login from ccusers a1   
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)  
inner join   
(select a3.user_id, a4.IDWG, a3.login  from ccusers a3   
inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)'
		EXEC(@Sql)

			set @Sql = 'CREATE TABLE [dbo].[ccoCallBacks](
	[callout_id] [int] NULL,
	[user_id] [int] NULL,
	[cam_id] [int] NULL,
	[cal_key] [varchar](20) NULL,
	[cal_telefono] [varchar](30) NULL,
	[cal_telCB] [varchar](30) NULL,
	[cal_fecha] [datetime] NULL,
	[cal_fusercallback] [datetime] NULL,
	[cal_fcallback] [datetime] NULL,
	[status] [tinyint] NULL,
	[schedulerStatus] [tinyint] NULL
) ON [PRIMARY]'
		EXEC(@Sql)

			set @Sql = 'USE [msdb]

/****** Object:  Job [CW Callback/abandoned update]    Script Date: 08/17/2012 12:31:50 ******/
BEGIN TRANSACTION

/****** Object:  Job [CW Callback/abandoned update]    Script Date: 08/23/2012 12:17:20 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Callback/abandoned update'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Callback/abandoned update'', @delete_unused_schedule=1

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/17/2012 12:31:50 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Callback/abandoned update'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Delete ccRIAUpdateCallBack_Abandon info'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 08/17/2012 12:31:50 ******/
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
		@command=N''declare @callout_id_array varchar(max), @SQL varchar(max)
set @callout_id_array=''''|''''

select @callout_id_array=@callout_id_array+coalesce('''',''''+cast(callout_id as varchar(10)), @callout_id_array, '''''''') 
from ccRIAUpdateCallBack_Abandon where minCallBackAbandonXpire < getdate()

if len(@callout_id_array)>1
 begin
	select @callout_id_array=replace(@callout_id_array, ''''|,'''', '''''''')

	set @SQL=''''delete ccoWorkingTable where callout_id in (''''+@callout_id_array+'''')''''
	exec(@SQL)

	set @SQL=''''delete ccRIAUpdateCallBack_Abandon where callout_id in (''''+@callout_id_array+'''')''''
	exec(@SQL)

	set @SQL=''''update ccoCallBacks set [status] = 4, schedulerStatus = 1 where callout_id in (''''+@callout_id_array+'''') and [status] = 0''''
	exec(@SQL)
 end'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every 10 mins'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20040101, 
		@active_end_date=99991231, 
		@active_start_time=300, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@Sql)

			set @Sql = 'USE [msdb]

/****** Object:  Job [CW Delete old records]    Script Date: 08/17/2012 12:36:57 ******/
BEGIN TRANSACTION

/****** Object:  Job [CW Delete old records]    Script Date: 08/23/2012 12:14:36 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/17/2012 12:36:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
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
/****** Object:  Step [Run sp]    Script Date: 08/17/2012 12:36:58 ******/
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
		@command=N''DECLARE @meses int
set @meses = 8

truncate table cclogInfo
truncate table ccBorrardasReciclaje
truncate table ccUploadTemporal
truncate table ccLogCampsAgentesDia 

delete from cchistoriallistanegra where fecha < dateadd(mm, -@meses, getdate())
delete from ccRIAlog where operationDate < dateadd(mm, -@meses, getdate())

delete xxclientehistorial where fechaAct < dateadd(mm, -@meses, getdate())
delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(mm, -1, getdate())
delete ccRIAWorkGroup_Calid where timestamp < dateadd(mm, -1, getdate())
delete ccRIALogAgentesNotReady where fecha < dateadd(mm, -1, getdate())
delete ccRIAcallbacks where año < datepart(yy,getdate())
delete ccRIAcallbacks where mes < datepart(mm,getdate())

delete from ccLogAgentesDia where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogAgentesNotReady where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogLogin where fecha < dateadd(mm, -@meses, getdate())
delete from ccoLogDials where fecha < dateadd(mm, -@meses, getdate())
delete from ccoCallsOut where cal_inicio < dateadd(mm, -@meses, getdate())
update ccoCallBacks set [status] = 5, schedulerStatus = 1 where callout_id in (select callout_id from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate()))
delete from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate())
delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -@meses-1, getdate())
'', 
		@database_name=N''CCenterRia'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every Sunday at 1:30'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=13000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@Sql)

			set @Sql = 'ALTER Procedure [dbo].[ccsp_ADMCalifInformation]
@user_id as int,
@type as int
as
if @type = 1
begin
	declare @fecha_ini datetime

	--0 in, 1 out
	select @fecha_ini = convert(datetime,convert(varchar(11),getdate()+'' 00:00''))	
    
    --Obtener calificaciones de salida
	(select calif.calif_id AS ''calificationId'' , 
    description, 	
	agt [agentId],
	case when llamadas is null then 0 else llamadas end [calls], 
    1 as ''type''
	  from 
     (select calif_id, description,agt from cctipocalifout,ccGenViewRelsSupsAgent where califout_status = 1 AND sup = @user_id) calif
     left join
    (SELECT [user_id], calif_id, COUNT(*) llamadas
	FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2)), dbo.ccGenViewRelsSupsAgent b 
     WHERE cal_inicio >= @fecha_ini
     AND b.sup = @user_id AND statuscall_id = 13 AND calif_id > 0 and user_id = b.agt
	 GROUP BY [user_id], calif_id 
	) data      	
	on (calif.calif_id = data.calif_id AND data.[user_id] = calif.agt))

	union all
    
    --Obtener calificaciones de entrada
	(select calif.calif_id AS ''calificationId'', 
    description, 	
	agt [agentId],
	case when llamadas is null then 0 else llamadas end [calls],     
    0 as ''type''
	  from 
     (select calif_id, description, agt from cctipocalif,ccGenViewRelsSupsAgent where calif_status = 1 AND sup = @user_id) calif 
     left join 
    (SELECT [user_id], calif_id, COUNT(*) llamadas
	FROM cccallsin with (nolock, index(IX_ccCallsIn)), dbo.ccGenViewRelsSupsAgent b WHERE 
      cal_inicio >=  @fecha_ini 
      and b.sup = @user_id and calif_id > 0 AND user_id = b.agt
	 GROUP BY [user_id], calif_id 
	) data      	
	on (calif.calif_id = data.calif_id AND data.[user_id] = calif.agt))

end

if @type = 2
begin
	select calif_id, description, 0 type from cctipocalif where calif_status = 1
	union all
	select calif_id, description,1 type from cctipocalifout where califout_status = 1
end'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_AgentLastNotReady] @user_id smallint AS
set nocount on

declare @lastStatus tinyint
declare @info varchar(100)

--select @info = ''AgentLastNotReady '' + cast(@user_id as varchar(10))
--exec ccsp_LogInfo @info, 1

select @lastStatus = 0

select top 1 @lastStatus = isnull(tipoStatusAge_id,0)
from ccLogAgentesDia --with(nolock index(IX_ccLogAgentesDia_1))
where user_id = @user_id 
order by fecha desc

if @lastStatus = 2 
 begin
	select top 1 tipoNotReady_Id 
	from ccLogAgentesNotReady --with(nolock index(IX_ccLogAgentesNotReady_3))
	where user_id = @user_id 
	order by fecha desc
	
	--select @info = ''AgentLastNotReady '' + cast(@user_id as varchar(10)) + '':'' + cast(@lastStatus as varchar(3))
	--exec ccsp_LogInfo @info, 1

	return(0)
 end 

select 0 as tipoNotReady_Id

set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)=''''
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int

if @TipoMov=4 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT Set statusCall_id=13 Where cal_id=@cal_id
		if @RecicleSIC=0
			DELETE ccoWorkingTable WHERE callout_id=@callout_id

		update ccoCallBacks 
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a, ccoCallsOUT b
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	end

	Update ccCallsIN Set statusCall_id=13 Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x

	return(0)
 end

if  @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id
		if @RecicleSIC=0
			DELETE ccoWorkingTable WHERE callout_id=@callout_id

		update ccoCallBacks 
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a, ccoCallsOUT b
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id
	
	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks 
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a, ccoCallsOUT b
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks 
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a, ccoCallsOUT b
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end
	
	Update ccCallsIN Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(20) = null,
@endDate varchar(20) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
	isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id) 
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

-- OUTBOUND x cal_id
if @action = 2 
 begin
	select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing
	from ccocallsout c with(nolock)
	left join ccusers b on (c.user_id = b.user_id) 
	left join cccamps a on (c.cam_id = a.cam_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

if @action = 3 --Session time
	begin
		declare @fecha_ini datetime
		declare @fecha_fin datetime	

		if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
			select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
			select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
		end
		else begin
			select @fecha_ini = convert(datetime,convert(varchar(11),@startDate))
			select @fecha_fin = convert(datetime,convert(varchar(11),@endDate))
		end

		select user_id, login, logout, datediff(ss,login,logout) as logintime 
		from(select a.user_id, a.fecha as ''login'',
				(select isnull(max(Fecha),getdate())
					from ccLogLogin b with(nolock)
					where b.user_id = a.user_id and
					b.tipomov = 0 and
					b.fecha >= a.fecha and
					b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
								from ccLogLogin with(nolock)
								where user_id = b.user_id and
								tipomov = 1 and
								fecha > a.fecha)) as ''logout''
				from ccLogLogin a
				where a.tipomov=1
				and fecha >= @fecha_ini
				and fecha <= @fecha_fin) as sessiontime
		order by user_id, login
	end

	if @action = 4 -- Estados de los agentes
	begin	
		select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
	end

	if @action = 5 -- Sinlge Call id Inbound
	 begin
		select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing
		from cccallsin c with(nolock)
		left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
		left join ccusers b on (c.user_id = b.user_id) 
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalif e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end


	-- Single call_id Outbound
	if @action = 6
	 begin
		select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
		d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing
		from ccocallsout c with(nolock)
		left join ccusers b on (c.user_id = b.user_id) 
		left join cccamps a on (c.cam_id = a.cam_id)
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters] @type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
	begin
		SELECT User_id, case 
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0 
				THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))  
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) + 
				convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END as logintime
		FROM ccLogLogin a, ccGenViewRelsSupsAgent b
		where fecha >= @fecha_ini
		and a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id
	end

if @type = 2 --Status agent
	begin
		SELECT User_id, TipoStatusAge_id, sum(tStatus) As segundos 
		FROM ccLogAgentesDia a with(index(IX_ccLogAgentesDia_4)), ccGenViewRelsSupsAgent b 
		WHERE fecha >= @fecha_ini
		AND a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id, TipoStatusAge_id 
		ORDER BY User_id
	end

if @type = 3
	begin

        select calls.*, users.login
		from ccusers As users ,
        (
			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'', 
			CASE  
			  WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada          
			  WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
			  ELSE 2                          --Llamada de OutBound          
			END AS ''type_calls''
			FROM ccoCallsOut a WITH (NOLOCK index(IX_ccoCallsOut_10)) , ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --OutBound sin estado definitivo 
			AND cal_inicio >= @fecha_ini		
			GROUP BY User_id, statuscall_id, cal_manual
	        
			UNION

			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'', 
			CASE  
			  WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada          
			  ELSE 1                          --Llamada de InBound          
			END AS ''type_calls''
			FROM ccCallsIn a WITH (NOLOCK index(IX_ccCallsIn_5)), ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --InBound sin estado definitivo 
			AND cal_inicio >= @fecha_ini		
			GROUP BY User_id, statuscall_id
        ) AS calls 
        where users.user_id = calls.user_id	

	end

if @type = 4
	begin
        select a.user_id, a.login 
        from ccusers a, ccGenViewRelsSupsAgent b
		where user_id = b.agt
		and b.sup = @sup_id
    end

set nocount on'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentNotReadyDetail] @user_id as int = 0, @sup_id as int = 0, @action as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

create table #cctiponotready(
user_id int not null,
tiponotready_id int not null,
tstatus int not null,
Descripcion varchar(255) not null,
time_acum int not null,
Time_xEv int not null
)

if @action = 1
   begin

        SELECT a.user_id,a.TipoNotReady_id,isnull(sum(tStatus),0) as ''time'',a.descripcion,a.Time_Acum,a.Time_xEV
		FROM
		(SELECT user_id,b.login,TipoNotReady_id,descripcion,Time_Acum,Time_xEV
		FROM cctiponotready a,ccusers b, ccGenViewRelsSupsAgent c
        WHERE  b.user_id = c.agt
		and c.sup = @sup_id) a
		LEFT JOIN 
		(SELECT user_id,TipoNotReady_id,tStatus FROM ccLogAgentesNotReady
        WHERE fecha >= @fecha_ini)  b 
		ON a.user_id = b.user_id AND a.TipoNotReady_id = b.TipoNotReady_id        
		GROUP BY a.user_id,a.TipoNotReady_id,a.descripcion,a.Time_Acum,a.Time_xEV	
	
   end

else if @user_id = 0 and @sup_id > 0
	begin
		        
        SELECT DISTINCT a.user_id, 1 AS ''type'', c.login
        from ccLogAgentesNotReady a,cctiponotready b, ccusers c, ccGenViewRelsSupsAgent d
        WHERE  a.user_id = d.agt
		and d.sup = @sup_id 
		AND a.TipoNotReady_id = b.TipoNotReady_id 
		AND b.Time_xEv <> 0 AND a.tStatus > b.Time_xEv
		and a.fecha >= @fecha_ini
		and a.user_id = c.user_id

        UNION
       
        SELECT DISTINCT a.user_id, 2 AS ''type'', c.login
        from ccLogAgentesNotReady a,cctiponotready b, ccusers c, ccGenViewRelsSupsAgent d
        WHERE a.user_id = d.agt
		and d.sup = @sup_id 
		AND a.TipoNotReady_id = b.TipoNotReady_id 
		AND b.Time_Acum <> 0 
		and a.fecha >= @fecha_ini
		and a.user_id = c.user_id
        GROUP BY a.user_id, a.TipoNotReady_id,b.Time_Acum, c.login
        HAVING sum(a.tStatus) > b.Time_Acum

		UNION
		
		SELECT a.agt, 0 AS ''type'', b.login
		FROM ccGenViewRelsSupsAgent a, ccusers b
		where a.agt = b.user_id
		and a.sup = @sup_id

	end

else if @user_id > 0 and @sup_id = 0
	begin
		insert into #cctiponotready
		select a.user_id, a.tiponotready_id, a.tstatus, b.descripcion, b.time_acum, b.time_xev
		from ccLogAgentesNotReady a, cctiponotready b
		where user_id = @user_id
		and fecha >= @fecha_ini
		and a.tiponotready_id = b.tiponotready_id

		insert into #cctiponotready
		select @user_id, tiponotready_id, 0, descripcion, time_acum, time_xev
		from ccTipoNotReady
		where tiponotready_id not in (select tiponotready_id from #cctiponotready)
		and issup = 0

		select *
		from #cctiponotready
end

drop table #cctiponotready

set nocount on'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GetConversionFactor]
	@userId int = 0 ,
    @califId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Clean temp tables--

	IF OBJECT_ID(''tempdb..#LoginTimeAgent'') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTimeAgent
	END

	--Clean temp tables--

	--Create time ranges--

	declare @fecha datetime
	select @fecha = convert(datetime,convert(varchar(11),getdate()))

	--Create time ranges--

	--Create flags for searches--

	declare @agentFlag bit 
	IF @userId < 1
	  BEGIN
		--Select all agents
		SET @agentFlag = 1
	  END
	ELSE
	  BEGIN
		--Find agent specified in param @userId
		SET @agentFlag = 0
	  END

	declare @califFlag bit
	IF @califId < 1
	  BEGIN
		--Select all califications
		SET @califFlag = 1
	  END
	ELSE
	  BEGIN
		--Find specified calification in param @califId
		SET @califFlag = 0
	  END

	--Create flags for searches--

	--Get login times of the current day for all agents--

	SELECT a.User_id as uid, case 
		WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0 
			THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))  
		ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) + 
			convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
		END as time_secs
	INTO #LoginTimeAgent
	FROM ccLogLogin a, ccUsers b
	where fecha >= @fecha
	and a.User_id = b.User_id
	GROUP BY a.User_id

	--Get login times for the day of all agents--

	--Get disposition calls for the day of all agents--
	        	    
	SELECT R.user_id As ''userId'',U.login,R.calif_id As ''califId'',R.description,R.llamadas AS ''calls'',CASE WHEN T.time_secs <1 THEN 1 ELSE T.time_secs END As ''time_secs'' FROM
		((select calif.calif_id, description, 
		case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
		case when user_id is null then 0 else user_id end [user_id],
		case when llamadas is null then 0 else llamadas end [llamadas], 1 as type
		  from (select calif_id, description from cctipocalifout where califout_status = 1 AND (@califFlag=1 OR calif_id = @califId)) calif
		  left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
		FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13  and calif_id > 0 
		 AND (@agentFlag=1 OR user_id = @userId) 
		 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
		) data
		on (calif.calif_id = data.calif_id))
		union all
		(select calif.calif_id, description, 
		case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
		case when user_id is null then 0 else user_id end [user_id],
		case when llamadas is null then 0 else llamadas end [llamadas], 0 as type
		  from (select calif_id, description from cctipocalif where calif_status = 1 AND (@califFlag=1 OR calif_id = @califId)) calif
		  left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
		FROM cccallsin with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13  and calif_id > 0 
		 AND (@agentFlag=1 OR user_id = @userId) 
		 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
		) data
		on (calif.calif_id = data.calif_id))) AS R   
	, #LoginTimeAgent As T
	, ccUsers As U
	WHERE R.user_id = T.uid 
	AND R.user_id = U.user_id
	ORDER BY R.user_id

	--Get disposition calls for the day of all agents--

	--Clean temp tables--

	IF OBJECT_ID(''tempdb..#LoginTimeAgent'') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTimeAgent
	END

	--Clean temp tables--

END'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetAve_Camps] AS
declare @FInicio as smalldatetime
select @FInicio = dateadd(mi,-20, getdate())

select	A.cam_id, ((A.Abandon *100.0)/ A.Contesta) as AbanPorcentaje,
	((D.Contesta *100.0)/ D.Marcaciones) as AnswerPorcentaje, A.Abandon, A.Contesta, D.Marcaciones
from (
	select 
		cam_id,
		count(case statuscall_id when 6 then 1 else null end) as Abandon,
		count(*) as Contesta		
	from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
	where cal_Inicio > @FInicio
	group by cam_id
) A join 
(
	select cam_id,
		count(case tipoResDial_id when 1 then 1 else null end) as Contesta,
		count(*) as Marcaciones
	from ccoLogDials with(nolock index(IX_ccoLogDials))
	where fecha > @FInicio
	group by cam_id
) D on A.cam_id=D.cam_id'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTResetJobs]
@camid as int=0
AS

if (@camid=0)
begin
	-- NUEVAS Hace tiempo que se marcaron
	update ccoWorkingTable with(rowlock)
	set cal_status=0 
	from ccoWorkingTable wt inner join ccoLogDials ld
	on wt.callout_id=ld.callout_id
	where wt.cal_status = 2
	and ld.fecha <= dateadd(d, -1, getdate()) 
	
	-- CALLBACKS Se han marcado recientemente
	update ccoWorkingTable with(rowlock)
	set cal_status=1 
	from ccoWorkingTable wt inner join ccoLogDials ld
	on wt.callout_id=ld.callout_id
	where wt.cal_status = 2
	and ld.fecha > dateadd(d, -1, getdate()) 
	
	-- NUEVAS - Nunca se han marcado
	update ccoWorkingTable with(rowlock)
	set cal_status=0
	where cal_status = 2
end 

if (@camid>0)
begin
	-- NUEVAS Hace tiempo que se marcaron
	update ccoWorkingTable with(rowlock)
	set cal_status=0 
	from ccoWorkingTable wt inner join ccoLogDials ld
	on wt.callout_id=ld.callout_id
	where wt.cal_status = 2
	and wt.cam_id=@camid
	and ld.fecha <= dateadd(d, -1, getdate()) 
	
	-- CALLBACKS Se han marcado recientemente
	update ccoWorkingTable with(rowlock)
	set cal_status=1
	from ccoWorkingTable wt inner join ccoLogDials ld
	on wt.callout_id=ld.callout_id
	where wt.cal_status = 2
	and wt.cam_id=@camid
	and ld.fecha > dateadd(d, -1, getdate()) 
	
	-- NUEVAS - Nunca se han marcado
	update ccoWorkingTable with(rowlock)
	set cal_status=0
	where cal_status = 2
	and cam_id=@camid
end'
		EXEC(@Sql)

			set @Sql = 'ALTER proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados / 
--				  3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings where setting_id = 60

If @Valor = 1
 begin
	declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
	select @Valor = valor from ccSettings where setting_id = 59
	
	If @Valor = 0 
	 begin
		select -2, ''No hay un limite para volver a reciclar''
		return(0)
	 end

	select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

	-- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
	select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')
	
	exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id
	If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
	begin
		select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
 		return(0)
	end

 end

if @type=0
 begin
	if @list_id = 0 begin
		update ccoCallsOutSource set dato5 = isnull(dato5, '''') where callout_id in (select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 1)
		
		update ccoCallBacks set [status] = 3, schedulerStatus = 1
		where callout_id in (select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 1)
		and [status] = 0

		update ccoWorkingTable set cal_status = 0 where cam_id = @cam_id and cal_status = 1
	end
	else begin
		update ccoCallsOutSource set dato5 = isnull(dato5, '''') where callout_id in (select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and list_id = @list_id)

		update ccoCallBacks set [status] = 3, schedulerStatus = 1
		where callout_id in (select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and list_id = @list_id)
		and [status] = 0

		update ccoWorkingTable set cal_status = 0 where cam_id = @cam_id and cal_status = 1 and list_id = @list_id
	end

	return(0)
 end

if @type in(1,3)
 begin
	update ccoCallsOutSource set dato5 = isnull(dato5, '''') where callout_id in (
	 select callout_id from ccoWorkingTable 
	 where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1)

	update ccoCallBacks set [status] = 3, schedulerStatus = 1
	where callout_id in (select callout_id from ccoWorkingTable
		where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1
		and callout_id not in (select b.callout_id
		from ccologdials a left join ccocallsout b on a.callout_id = b.callout_id
		and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
		where isnull(calif_id, 0) <> 0))
	and [status] = 0

	update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1
	and callout_id not in (select b.callout_id
	 from ccologdials a left join ccocallsout b on a.callout_id = b.callout_id
	 and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
	 where isnull(calif_id, 0) <> 0)
 end

if @type in(2,3)
 begin
	Set @SQL = ''update ccoCallsOutSource set dato5 = isnull(dato5, '''''''') where callout_id in ('' +
	 ''select callout_id from ccoWorkingTable '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''+'')'' + nchar(13)
	exec(@SQL)

	Set @SQL = ''update ccoCallBacks set [status] = 3, schedulerStatus = 1'' +
	 ''where callout_id in ('' +
	 ''select callout_id from ccoWorkingTable'' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
	 ''and calif_id in ('' + @calif_id + ''))'' +
	 ''and [status] = 0''

	exec(@SQL)

	Set @SQL = ''update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
	 + -- and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''

	exec(@SQL)
 end

if @type = 4
 begin
	update ccoCallsOutSource set dato5 = isnull(dato5, '''') where callout_id in (
	 select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 3)

	update ccoCallBacks set [status] = 3, schedulerStatus = 1
	where callout_id in (select callout_id from ccoWorkingTable where cam_id = @cam_id and cal_status = 3)
	and [status] = 0

	update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0 
	 where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
	@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
	@cam_id int,
	@phone varchar(30) = ''''
	AS

	if @tipoDel = 1 --nuevos
	 begin
		delete ccoWorkingTable with(rowlock) where cam_id = @cam_id and cal_status = 0
	 end

	if @tipoDel = 2 --callbacks
	 begin
		delete ccoWorkingTable  with(rowlock) where cam_id = @cam_id and cal_status = 1
	 end

	if @tipoDel = 3 -- 3 Registros sin meter a WT
	 begin
		update ccocallsoutsource with(rowlock)
		set cal_Status = 5 
		where cam_id = @cam_id 
		and cal_status in(0, 7)
		
		Delete ccUploadTemporal with(rowlock) where cam_id = @cam_id
	 end

	if @tipoDel = 4 --callbacks
	 begin
		delete ccoWorkingTable with(rowlock) where cam_id = @cam_id and cal_status = 1 and user_id=0
	 end

	if @tipoDel = 5 --callbacks
	 begin
		delete ccoWorkingTable with(rowlock) where cam_id = @cam_id and cal_status = 3
	 end

	if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
	begin	
		delete ccoWorkingTable with(rowlock) 
		where callout_id in (select isnull(callout_id,0) 
								from ccocallsoutsource with(nolock)
								where cam_id = @cam_id 
								and (cal_telefono = @phone or 
										cal_telefono2 = @phone or 
										cal_telefono3 = @phone or 
										cal_telefono4 = @phone or 
										cal_telefono5 = @phone))

		update ccocallsoutsource with(rowlock)
		set cal_Status = 5 
		where callout_id in (select isnull(callout_id,0) 
								from ccocallsoutsource with(nolock)
								where cam_id = @cam_id 
								and (cal_telefono = @phone or 
										cal_telefono2 = @phone or 
										cal_telefono3 = @phone or 
										cal_telefono4 = @phone or 
										cal_telefono5 = @phone))
	end

	if @tipoDel = 7 -- Delete all the records from a specific campaign
	begin
		delete from ccoWorkingTable with(rowlock) where cam_id = @cam_id

		update ccocallsoutsource with(rowlock) set cal_Status = 5 where cam_id = @cam_id
	end'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB] @cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0 as
set nocount on

declare @regval as int



-- Actualiza todas las camps
if @Tipo=2
	begin
		declare @ultimo as datetime,@id AS INTEGER

		select @ultimo = isnull( convert(datetime, valor, 121), dateadd(hh, -1, getdate() ) ) from ccSettings where setting_id = 21

		if datediff(ss, @ultimo, getdate()) > 120
			begin
				CREATE TABLE #Tcamps
				(cam_id int,
				cantidad int)

				DECLARE CCamp CURSOR FOR 
				select cam_id from ccCamps

				Open CCamp
				Fetch Next From CCamp
				Into @id
				if @@FETCH_STATUS = 0
					Begin 
						While @@FETCH_STATUS = 0
							Begin 
								EXEC @regval = ccsp_OUTGetNewJobs @id,2,0

								INSERT #Tcamps
								select @id,@regval
								Fetch Next From CCamp
								Into  @id
							End
					End
				CLOSE CCamp
				DEALLOCATE CCamp

				UPDATE ccSettings set valor = convert( varchar(23), getdate(),121) where setting_id = 21

				delete ccCampsNvosCB

				INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
				SELECT cams.cam_id, cams.cam_descripcion, 
				isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb, 
				isNull(cs.Pend,0) as pend,
				isNull(wt.Pro,0) as pro,
				cams.cam_procesando, cams.cam_tipojobs, isNull(wt.Fin,0) Fin,
				tc.cantidad
				FROM ccCamps cams with(nolock)
				LEFT JOIN
				(
					SELECT cam_id,
					count(case cal_status when 0 then 1 else null end) as New,
					count(case cal_status when 1 then 1 else null end) as Cb,
					count(case cal_status when 2 then 1 else null end) as Pro,
					count(case cal_status when 3 then 1 else null end) as Fin
					FROM ccoworkingtable with(nolock)
					GROUP BY cam_id
				) wt on cams.cam_id = wt.cam_id
				LEFT JOIN
				(
					SELECT cam_id, count(cam_id) as Pend
					FROM ccocallsoutsource with(nolock index(IX_ccoCallsOutSource))
					WHERE cal_status in(0, 7)
					GROUP BY cam_id
				) cs on cams.cam_id = cs.cam_id
				left join #Tcamps tc on (tc.cam_id = cams.cam_id)

				drop table #Tcamps
			end

		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
		FROM ccCampsNvosCB res
		LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
		WHERE res.id in(select cam_id from ccSupervisorCam where tipo = 1 and user_id = @user_id)

		return(0)
	end

-- Actualiza una camp
if @Tipo=1
	begin
		exec @regval = ccsp_OUTGetNewJobs @cam_id,2,0

		delete ccCampsNvosCB with(rowlock) where id = @cam_id

		INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
		SELECT cams.cam_id, cams.cam_descripcion, 
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb, 
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		cams.cam_procesando, cams.cam_tipojobs, isNull(wt.Fin,0) Fin,
		isnull(@regval,0) NextDial
		FROM ccCamps cams with(nolock)
		LEFT JOIN
		(
			SELECT @cam_id as cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable with(nolock index(IX_ccoWorkingTable))
			WHERE cam_id = @cam_id

		) wt on cams.cam_id = wt.cam_id
		LEFT JOIN
		(
			SELECT @cam_id as cam_id, count(cam_id) as Pend
			FROM ccocallsoutsource with(nolock index(IX_ccoCallsOutSource_11))
			WHERE cal_status in (0,7) 

			AND cam_id = @cam_id
		) cs on cams.cam_id = cs.cam_id
		WHERE cams.cam_id = @cam_id

		-- devuelve resultado de la taba
		SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
		FROM ccCampsNvosCB res

		LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
		WHERE res.id = @cam_id

		return(0)
	end

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCedure [dbo].[ccsp_RIALoadCamps]
@option smallint,
@AreaId smallint = null,
@Sup smallint = null
as
set nocount on
if @option = 1 -- Todas las campañas
begin
      select a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0), isnull(DNCscrub,0)
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 1))
      order by 5,2
      return(0)
end
 
if @option = 2 -- Campañas de un Area
begin
      select distinct a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0)
      IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
      order by cam_descripcion
      return(0)
end
 
if @option = 3 -- Campañas por Supervisor
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea,0) IDArea
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
      where a3.type_id = 1 and a4.tipo = 1 and a4.user_id = @Sup
      order by 5, 2
      return(0)
end
 
if @option = 4 -- Rels Camps-Agents
begin
      select Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
      from (select A.Login, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea,0) IDArea, CA.rel_id
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
            join ccRIACampsGraph a2 on C.cam_id = a2.cam_id
            join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
            join ccUsers A on A.User_id = CA.User_id and A.TipoUser_id = 1 and A.Status = 1
            where C.cam_id in(select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0)
             when 0 then user_id else @Sup end and tipo=1)) Relations
      group by Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
      order by User_id, cam_descripcion, cam_id, Prioridad
      return(0)
end
 
if @option = 5 -- Campañas por Supervisor
      begin
            select distinct Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea,0)IDArea,
            IsNull(CN.New, 0) as New, IsNull(CN.CB, 0) as CB, IsNull(CN.Pro, 0) as Pro,
            IsNull(CN.pen, 0) as Pen, cast(Camps.cam_procesando as int) as St, Camps.cam_TipoJobs as Job,
            isnull(CN.Fin, 0)Fin, isnull(CP.prioridad,''12345NNN'') prioridad, cast(camps.dialorder as tinyint) dialorder,
            cast(camps.progDial as tinyint) progDial
            from ccCamps Camps left join ccCampsPrioridadTel CP on CP.cam_id = Camps.cam_id
            left join ccCampsNvosCB CN on CN.id = Camps.cam_id
            join ccRIACampsGraph a2 on (Camps.cam_id = a2.cam_id)
            join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
            join ccSupervisorCam U on Camps.cam_id = U.cam_id
            where U.user_id = @sup
            and tipo = 1
            and a3.type_id = 1
            and Camps.cam_id in (select cam_id from ccSupervisorCam where tipo = 1 and user_id = @sup)
            order by 5, cam_procesando desc, cam_descripcion
            return(0)
      end
 
if @option = 7 -- Una sola
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea,0) IDArea
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id=1 and isnull(a1.cam_id,0)=isnull(@AreaId,0)
      order by 5,2
      return(0)
end
 
if @option = 8 -- Campañas de un Agente
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccCampsAgente a4 on a1.cam_id = a4.cam_id
      where a3.type_id=1 and a4.user_id = @Sup
      order by 2
      return(0)
end
 
return(0)
set nocount off'
             EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIALoadWorkGroup]
@option smallint,
@AreaId smallint,
@Sup smallint,
@CamEspId smallint,
@InOut tinyint
as

set nocount on

if @option = 1 -- Todos los WG
	begin
		-- Agentes y Supervisores
		select a2.IDArea,a1.IDWG, a1.WGName, a4.User_id as ID, 
		Case TipoUser_id when 1 then ''A'' when 2 then ''S'' when 6 then ''S'' end as TypeLoad 
		from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
		join ccRIAWorkGroupUsers a3 on a1.IDWG = a3.IDWG
		join ccUsers a4 on a3.User_id = a4.User_id
		UNION
		-- Campañas/acds
		select a2.IDArea,a1.IDWG, a1.WGName, a3.IdCampEsp as ID, 
		Case Tipo when 0 then ''I'' when 1 then ''C'' end as TypeLoad 
		from ccRIACat_WorkGroup a1
		join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
		join ccRIACampEspWG a3 on a1.IDWG = a3.IDWG
		Order By 1,2,5,4
		return(0)
	end

if @option = 2 -- WG de un Area
	begin
		-- Agentes y Supervisores
		select a2.IDArea,a1.IDWG, a1.WGName, a4.User_id as ID, 
		Case TipoUser_id when 1 then ''A'' when 2 then ''S'' when 6 then ''S'' end as TypeLoad 
		from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
		join ccRIAWorkGroupUsers a3 on a1.IDWG = a3.IDWG
		join ccUsers a4 on (a3.User_id = a4.User_id)
		where a2.IDArea = @AreaId
		UNION
		-- Campañas
		select a2.IDArea,a1.IDWG, a1.WGName, a3.IdCampEsp as ID, 
		Case Tipo when 0 then ''I'' when 1 then ''C'' end as TypeLoad 
		from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
		join ccRIACampEspWG a3 on a1.IDWG = a3.IDWG
		where a2.IDArea = @AreaId
		Order By 1,2,5,4
		return(0)
	end

if @option = 3 -- WG por Supervisor
	begin
		-- Agentes y Supervisores
		select distinct a2.IDArea,a1.IDWG, a1.WGName, a4.User_id as ID, 
		Case TipoUser_id when 1 then ''A'' when 2 then ''S'' when 6 then ''S'' end as TypeLoad 
		from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
		join ccRIAWorkGroupUsers a3 on a1.IDWG = a3.IDWG 
		join ccUsers a4 on a3.User_id = a4.User_id
		join ccRIAWorkGroupUsers a5 on a1.IDWG = a5.IDWG
		where a5.User_id = @sup
		UNION
		-- Campañas y Especialidades
		select a2.IDArea,a1.IDWG, a1.WGName, a3.IdCampEsp as ID, 
		Case Tipo when 0 then ''I'' when 1 then ''C'' end as TypeLoad 
		from ccRIACat_WorkGroup a1 join ccRIAAreaWorkGroup a2 on a1.IDWG = a2.IDWG
		join ccRIACampEspWG a3 on a1.IDWG = a3.IDWG
		join ccRIAWorkGroupUsers a4 on a1.IDWG = a4.IDWG
		where a4.User_id = @sup
		Order By 1,2,5,4
		return(0)
	end

If @option = 4 -- Datos Agents y Sups por WG de un area 
	begin
		select a.IDWG,a.WGName, isnull(d.TipoUser_id,'''') TipoUser_id, isnull(d.user_id,'''') user_id,
		isnull(d.login,'''') login, isnull(d.TipoLlamadas,'''') TipoLlamadas, isnull(d.Nombres,'''') + '' '' + 
		isnull(d.ApellidoPaterno,'''') + '' '' + isnull(d.ApellidoMaterno,'''') as nombre,
		isnull(d.sexo,'''') sexo, dbo.fn_CampEspWG(a.IDWG,0) nAcd, dbo.fn_CampEspWG(a.IDWG,1) nCamp
		from ccRIACat_WorkGroup a 
		join ccRIAAreaWorkGroup b on b.IDWG = a.IDWG
		left join ccRIAWorkGroupUsers c on c.IDWG = a.IDWG
		left join ccUsers d on d.User_id = c.User_id 
		where b.IDArea = @AreaID
		order by a.WGName, a.IDWG,d.TipoUser_id, d.user_id
		return(0)
	end

If @option in (5, 7)
	begin
		create table #WGPriority(
		IDWG smallint, 
		WGName varchar(50), 
		TipoUser_id int, 
		User_id smallint, 
		login varchar(20), 
		TipoLlamadas tinyint, 
		nombre varchar(70), 
		sexo bit, 
		prioridad tinyint, 
		WGPriority tinyint, 
		rel_id int null)

		if @InOut = 1
			begin
				insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
				select distinct a.IDWG,d.WGName,c.TipoUser_id, b.User_id, c.login, c.TipoLlamadas, 
				c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
				c.sexo, e.prioridad, a.priority as WGPriority, e.rel_id relation_id
				from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
				join ccUsers c on b.User_id = c.User_id
				join cccampsagente e on c.User_id = e.User_id and e.cam_id = @CamEspId and a.IDWG = e.IDWG
				join ccRIACat_WorkGroup d on d.IDWG = a.IDWG 
				where a.IdCampEsp = @CamEspId 
				and a.tipo = 1 
				and c.tipouser_id=1
				order by 1,2,3

				insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
				select distinct a.IDWG,d.WGName, 2, b.User_id, c.login, c.TipoLlamadas, 
				c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
				c.sexo, 0, a.priority as WGPriority, 0
				from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
				join ccUsers c on b.User_id = c.User_id
				join ccsupervisorcam e on c.User_id = e.User_id and e.cam_id = @CamEspId and a.IDWG = e.IDWG 
				join ccRIACat_WorkGroup d on d.IDWG = a.IDWG 
				where a.IdCampEsp = @CamEspId 
				and a.tipo = 1 
				and c.tipouser_id in (2,6) 
				and e.tipo=@InOut
				order by 1,2,3		
			end
		else
			begin
				insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority)
				select distinct a.IDWG,d.WGName,c.TipoUser_id, b.User_id, c.login, c.TipoLlamadas, 
				c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
				c.sexo, e.prioridad, a.priority as WGPriority
				from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
				join ccUsers c on b.User_id = c.User_id
				join ccInboundAgentes e on c.User_id = e.User_id and e.Inbound_id = @CamEspId and a.IDWG = e.IDWG
				join ccRIACat_WorkGroup d on d.IDWG = a.IDWG
				where a.IdCampEsp = @CamEspId 
				and tipo = 0
				order by 1,2,3

				insert into #WGPriority (IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id)
				select distinct a.IDWG,d.WGName, 2, b.User_id, c.login, c.TipoLlamadas, 
				c.Nombres + '' '' + c.ApellidoPaterno + '' '' + c.ApellidoMaterno as nombre,
				c.sexo, 0, a.priority as WGPriority, 0
				from ccRIACampEspWg a join ccRIAWorkGroupUsers b on a.IDWG = b.IDWG
				join ccUsers c on b.User_id = c.User_id
				join ccsupervisorcam e on c.User_id = e.User_id and e.cam_id = @CamEspId and a.IDWG = e.IDWG 
				join ccRIACat_WorkGroup d on d.IDWG = a.IDWG 
				where a.IdCampEsp = @CamEspId 
				and a.tipo = 0 
				and c.tipouser_id in (2,6) 
				and e.tipo=@InOut
				order by 1,2,3	
			end

		update #WGPriority 
		set WGPriority = 0 
		where IDWG in (select IDWG from (select IDWG, count(distinct prioridad) prioridad
										 from #WGPriority group by IDWG, prioridad) as x 
										 group by IDWG, prioridad
										 having count(prioridad) > 1)

		if @option = 5
			begin
				select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, 
				nombre, sexo, prioridad, WGPriority, min(rel_id) relational_id
				from #WGPriority
				group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, 
				nombre, sexo, prioridad, WGPriority
			end

		if @option = 7
			begin
				select 1 as tag, null parent, 0 "WorkGroup!1!TipoUser_id", IDWG "WorkGroup!1!id", WGName "WorkGroup!1!description", WGPriority "WorkGroup!1!priority",
				null "Agent!3!id", null "Agent!3!login", null "Agent!3!callType", null "Agent!3!name", null "Agent!3!gender", null "Agent!3!priority", null "Agent!3!relational_id",
				null "Supervisor!2!id", null "Supervisor!2!login", null "Supervisor!2!callType", null "Supervisor!2!name", null "Supervisor!2!gender", null "Supervisor!2!priority", null "Supervisor!2!relational_id"
				from (select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
					  from #WGPriority) as WGPriority 
				group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority
				union	
				select 2 as tag, 1 parent,TipoUser_id, IDWG, null, null, null, null, null, null, null, null, null, User_id, login, TipoLlamadas, nombre, sexo, prioridad, min(rel_id) relational_id
				from (select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
					  from #WGPriority where TipoUser_id = 2) as WGPriority 
				group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority
				union
				select 3 as tag, 1 parent, TipoUser_id, IDWG, null, null, User_id, login, TipoLlamadas, nombre, sexo, prioridad, min(rel_id) relational_id, null, null, null, null, null, null, null
				from (select IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority, rel_id
					  from #WGPriority where TipoUser_id = 1) as WGPriority 
				group by IDWG, WGName, TipoUser_id, User_id, login, TipoLlamadas, nombre, sexo, prioridad, WGPriority
				order by "WorkGroup!1!id", tag, "WorkGroup!1!TipoUser_id" desc, "Supervisor!2!name", "Agent!3!name"
				for xml explicit, type
			end

		return(0)
	end
  
If @option = 6
	begin
		select W.Tipo, I.Inbound_id IdCampEsp, I.descripcion
		from ccInbound I join ccRIACampEspWG W on I.Inbound_id = W.IdCampEsp
		and W.IDWG = isnull(@AreaId, W.IDWG) and W.Tipo = 0
		union
		select W.Tipo, C.cam_id, C.cam_descripcion
		from ccCamps C join ccRIACampEspWG W on C.cam_id = W.IdCampEsp
		and W.IDWG = isnull(@AreaId, W.IDWG) and W.Tipo = 1
		order by W.Tipo desc, 2
		return(0)
	end

if @option=8
	begin
		SELECT isnull(viewMode.typeView,0) typeView FROM ccMenu_Views as viewMode
		join ccMenu_Views as [view] on viewMode.mView_id = [view].mView_id
		where viewMode.status=1 and [view].menu_id = 4
		and (case when viewMode.typeView = dbo.fn_viewMode (@Sup, [view].menu_id) then 1 else 0 end) = 1
		return(0)
	end

if @option=9
	begin
		declare @assignACDCamp as tinyint
		
		select @assignACDCamp = isnull(per_id,0) 
		FROM ccRIAUsr_AdminPermissions 
		WHERE per_id = 3 
		and user_id = @Sup

		SELECT case when @assignACDCamp > 0 then 1 else 0 end as granted
		return(0)
	end

return(0)

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

declare @prioridad varchar(8)

Delete ccUploadTemporal with(rowlock)
where cam_id = @camp_id

update ccoCallBacks
set [status] = 6, schedulerStatus = 1
where callout_id in (select cs.callout_id
from ccoCallsOutSource cs inner join ccoWorkingTable wt
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7))

update ccoCallsOutSource with(rowlock)
set cal_Status = 4 
from ccoCallsOutSource cs inner join ccoWorkingTable wt
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7)

update ccoCallBacks
set [status] = 6, schedulerStatus = 1
where callout_id in (select Cout.callout_id
from ccoCallsOutSource Cout JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7))

update ccoCallsOutSource with(rowlock)
set cal_Status = 4 
from ccoCallsOutSource Cout JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7)

Insert ccoWorkingTable (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
	iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT callout_id, cam_id, 
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end,
list_id
FROM ccoCallsOutSource
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

Insert into ccoCallBacks
SELECT callout_id, user_id, cam_id, cal_key,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono1,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono2,cal_fechaDial,cal_fechaDial,NULL,0,1
FROM ccoCallsOutSource
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock)
SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) 
and cam_id = @camp_id

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

select * from

(select top 10 cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as ''Esp/Camp'', 
isnull(cal.Description, '''') as Calificacion, cast(cal_tDialog / 3600 as varchar(10)) + '':'' + right(''0'' + cast(cal_tDialog / 60 % 60 as varchar(3)), 2) + 
'':'' + right(''0'' + cast(cal_tDialog % 60 as varchar(3)), 2) as Duracion, '''' as CallBack, cal_key, c.inbound_id as IDCampEsp
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound i on c.inbound_id = i.inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > convert(varchar(11), dateadd(hh, -3, getdate()), 101)
order by cal_id desc) a

Union

select * from
(select top 10 cal_id as id, ''OUT'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_telefono as Telefono,cam_descripcion as ''Esp/Camp'', 
isnull(cal.Description, '''') as Calificacion, cast(cal_tDialog / 3600 as varchar(10)) + '':'' + right(''0'' + cast(cal_tDialog / 60 % 60 as varchar(3)), 2) + 
'':'' + right(''0'' + cast(cal_tDialog % 60 as varchar(3)), 2) as Duracion, convert(varchar(16), cal_fcallback, 121) as CallBack, cal_key, c.cam_id as IDCampEsp
from ccoCallsOut c with(nolock index(IX_ccoCallsOut_9)) 
inner join ccCamps o on c.cam_id = o.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > convert(varchar(11), dateadd(hh, -3, getdate()), 101)
order by cal_id desc) b

order by hora desc

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on
select @reportRol = case @reportRol when 0 then 1 else @reportRol end, 
 @role_id = case @role_id when 0 then 1 else @role_id end

select @AE = valor from ccsettings where setting_id = 71

Declare @NRS tinyint
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id 
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin
	if @Role_id in (1, 10) and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	 begin
		Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
		if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)
					Insert into ccMenuUser values(@User_id,40,1)
		else If not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999))
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, 2 from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
		
	 end

	else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
	 begin
		if @InsertMenu_id <> 40
			  delete ccMenuUser where id_User = @User_id and type = @reportRol

		Insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
		If @reportRol = 1
			  Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,1)
	 end

	If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--    inserta parent en caso de no haberlo hecho en rol personalizado        
	Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
	(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
	where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
	where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

	return(0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
  Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

      else
            insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
      select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1))
      order by ordengral asc
      return(0)
 end

If @Type = 7 -- Get language
 begin
      select valor from ccSettings where setting_id = 27
      return(0)
 end

If @Type = 8 -- Insert the personalized menus of a supervisor
 begin
      insert into ccMenuUser (id_User, id_Menu, type)
      select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
       begin
            Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
            return(0)
       end

      insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 9 -- Delete all supervisor menus 
 begin
      delete ccMenuUser where id_User = @User_id and type = @reportRol
      return(0)
 end

If @Type = 10 -- Delete all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
      where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol 
      group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

      return(0)
 end

If @Type = 12
 begin
      declare @lan as tinyint
      select @lan = valor from ccSettings where setting_id = 27
      select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
      return(0)
 end

return(0)
set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_AdminNotready]
@Type tinyint,	-- 1:ND x Supervisor/2:actualiza x supervisor/3:Actualiza todo/4:trae ND/5:Trae supervisores
@User_id smallint = null,
@id_ND smallint = null,
@valor bit=1
as
set nocount on

declare @sql as nvarchar(2000)
declare @dato1 as varchar (100)

if @Type not in (1,2,3,4,5)
	raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

if @Type = 1
 begin

 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror(''ERROR. invalid user id'', 18, 1)
		return(0)
	 end

select @dato1 = valor from (select case when valor= 3 then ''nd.issup =1'' when valor = 2 then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' when valor = 4 
	then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' else (select ''nd.tiponotready_id = '' + valor from ccsettings where setting_id = 28) end valor 
	from ccsettings where setting_id =87) as a



	set @sql = ''select nd.tiponotready_id, nd.descripcion , snd.user_id, Nombres + replace('''' ''''+isnull(ApellidoPaterno, '''''''') + '''' ''''+
	isnull(ApellidoMaterno, ''''''''), ''''  '''', '''' '''') Nombre, a3.frame, u.login 
	from cctiponotready nd 
	join ccSupervisor_NotReady snd on (nd.tiponotready_id = snd.tiponotready_id)
	join ccUsers u on (u.user_id = snd.user_id)
	inner join ccRIAnotreadyGraph a2 on (nd.tiponotready_id=a2.tiponotready_id) 
	inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where nd.tiponotready_id > 0 and nd.statustiponotready = 1 and snd.user_id = case when '' + convert(varchar(10),@User_id) + '' <> 0 then '''''' 
	+ convert(varchar(10),@User_id) + '''''' else convert(varchar(10),snd.user_id) end
	and '' + @dato1 + '' order by snd.user_id ,nd.tiponotready_id''

exec sp_executesql @sql
--print (@sql)

	return(0)
 end

if @Type = 2
 begin

 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror(''ERROR. invalid user id'', 18, 1)
		return(0)
	 end


 	if not exists(select tiponotready_id from cctiponotready where tiponotready_id =@id_ND)
	 begin
		raiserror(''ERROR. invalid notReady id'', 18, 1)
		return(0)
	 end

	if @valor=0
		delete from ccSupervisor_NotReady where user_id = @User_id and tiponotready_id = @id_ND

	else if not exists (select user_id from ccSupervisor_NotReady where user_id = @User_id and tiponotready_id = @id_ND)
		insert ccSupervisor_NotReady select @user_id, @id_ND

	return(0)
 end

if @Type = 3
 begin

 	if not exists(select tiponotready_id from cctiponotready where tiponotready_id =@id_ND)
	 begin
		raiserror(''ERROR. invalid notReady id'', 18, 1)
		return(0)
	 end

	if @valor=0
		delete from ccSupervisor_NotReady where tiponotready_id = @id_ND

	else
		insert ccSupervisor_NotReady select u.User_id , nd.tiponotready_id
		from ccUsers u cross join cctipoNotReady nd
		where u.tipouser_id in (2,6) and nd.tiponotready_id = @id_ND
		and cast(u.User_id as varchar(10)) + ''|'' + cast(nd.tiponotready_id as varchar(10))
		not in (select cast(User_id as varchar(10)) + ''|'' + cast(tiponotready_id as varchar(10)) 
		from ccSupervisor_NotReady)

	return(0)
 end

if @Type = 4
 begin
	
	select @dato1 = valor from (select case when valor= 3 then ''nd.issup =1'' when valor = 2 then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' when valor = 4 then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' else (select ''nd.tiponotready_id = '' + valor from ccsettings where setting_id = 28) end valor from ccsettings where setting_id =87) as a

	set @sql = ''select nd.tiponotready_id, nd.descripcion, a3.frame from cctiponotready nd 
			inner join ccRIAnotreadyGraph a2 on (nd.tiponotready_id=a2.tiponotready_id) 
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where nd.statustiponotready = 1 and '' + @dato1

	exec sp_executesql @sql
	--print (@sql)
	return(0)
 end

if @Type = 5
 begin

	select User_id, Login, Nombres + 
	replace('' ''+isnull(ApellidoPaterno, '''') + '' ''+isnull(ApellidoMaterno, ''''), ''  '', '' '') Nombre
	from ccUsers where tipouser_id in (2,6)
	order by Login
	return(0)

 end

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_DLRInsertDNCList]
@tel varchar(30),
@cam_id as int
as
set nocount on
declare @DNClist as int, @telephone as varchar(30)
select @telephone = dbo.Completa_ListaNegra(@tel)

if left(@telephone,1) = ''E'' begin
	select @telephone = @tel
end

if exists(select * from Camplistanegra cl where cl.status = 1 and cl.cam_id = @cam_id)
begin
	select top 1 @DNClist = cl.idtipolista from Camplistanegra  cl where cl.status = 1 and cl.cam_id = @cam_id
	exec ccsp_InsertDNCList @telephone, @DNClist 
	
	insert cchistoriallistanegra 
	values(NULL,@telephone,getdate(),NULL,''8'',@DNClist)
end'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0
AS
set nocount on
if @IDCall<=0 
	return(0)

declare @tMinAVRS smallint

if @TipoCall=1 --INBOUND
 begin
    If @mtmoh > 0
		Update ccCallsIN Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, cal_tMoh=@mtmoh Where cal_id= @IDCall
    Else
       Update ccCallsIN Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13 Where cal_id= @IDCall

 
	-- Elimina callback generado por abandono
	Declare @ANI_x varchar(19)
	select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn)) where cal_id=@IDCall

	DELETE ccoWorkingTable WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin
   If @mtmoh > 0
	Update ccoCallsOUT Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13,  cal_tMoh=@mtmoh Where cal_id=@IDCall
   Else 
    Update ccoCallsOUT Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13 Where cal_id=@IDCall

	-- calcula el costo de la llamada
	exec ccsp_CstoCalculaCosto @IDCall
 end

select @tMinAVRS=valor from ccSettings where setting_id=65
select @tMinAVRS=isnull(@tMinAVRS, 5)	

if @cal_tDialog >= @tMinAVRS
 begin
	insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
	return(0)
 end

set nocount off'
		EXEC(@Sql)

			set @Sql = 'alter table ccHorarioVerano
	add country_id tinyint NOT NULL CONSTRAINT DF_ccHorarioVerano_country_id DEFAULT 0'
		EXEC(@Sql)

			set @Sql = 'UPDATE ccHorarioVerano set country_id = 1

CREATE TABLE dbo.ccTimeZoneArea
	(
	id_country smallint NOT NULL,
	area varchar(10) NOT NULL,
	location varchar(500) NOT NULL,
	tz_standard int NOT NULL,
	tz_daylight int NOT NULL
	)  ON [PRIMARY]
 
ALTER TABLE dbo.ccTimeZoneArea ADD CONSTRAINT
	PK_ccTimeZoneArea_1 PRIMARY KEY CLUSTERED 
	(
	id_country,
	area
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE dbo.ccsp_INInsertaCallBack
@cal_key varchar(20) =''b'',
@cam_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0
AS
set nocount on
declare @TelOriginal as varchar(15)
declare @FechaOriginal as datetime

if len(@cal_telefono)<=3
	return(0)

if isnull(@cal_key,'''') = ''''
 begin
      -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
      Genera_cal_key:
      select @cal_key = right(newID(), 10)
      if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
            goto Genera_cal_key
 end

declare @bIsDaylight as bit
declare @idioma as int
declare @country_id as varchar(3)

select @country_id = valor from ccsettings where setting_id = 104

select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id

declare @difference as int
select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
 begin
	select @callout_id=callout_id,@cal_statusTemp =cal_status,@iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano, @TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource where cal_Key = @cal_key and cam_id = @cam_id
	update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano  

		insert ccoCallBacks values(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
  end

else
 begin
	select @FechaOriginal = getdate()

	insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,dial_tels,cal_status)
	values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1''),''2'')

	select @TelOriginal = @cal_telefono

	select @callout_id = scope_identity()
	select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

	 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	 else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano

		insert ccoCallBacks values(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
		EXEC(@Sql)

			set @Sql = 'Alter procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(4000), @Order_Asc_Desc char(4)
 
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
 
SET DATEFIRST 1
--Checamos si es horario de verano
       select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
       from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id
 
select @bIsDaylight=isnull(@bIsDaylight,1)
 
--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
begin
       declare @horaUniversal as datetime
       set @horaUniversal=getutcdate()
 
       select @iZonas=sum(distinct tz_id)from
       (select tz_id,
             datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora,
             datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
             datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
             from ccTimeZones
       )zonas inner join cchorarios on
       ((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
             AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
             AND (
                    Lunes=dia or
                    Martes*2=dia or
                    Miercoles*3=dia or
                    Jueves*4=dia or
                    Viernes*5=dia or
                    Sabado*6=dia or
                    domingo*7=dia
              )
       ) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid
 
       if @iZonas is null begin
             SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
             return
       end
end
 
else
begin
       if @revHorario=0
             select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
       else
             select @iZonas=Null
 
end
 
set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
cal_status tinyint,
cal_fechaDial datetime,
user_id int,
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''
 
-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94
 
if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 20 end
 
select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
       select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
 
       select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
       SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
       W.list_id, isNull(R.sequence,0) as sequence
       FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
       WHERE cal_status=1 -- CallBacks
       and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
       and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
       and (
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
       )
       and isnull(R.status,2) = 2
       order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 
end -- TOMA EN CUENTA LOS CALLBACKS
 
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
       select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
 
       select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
       SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
       izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
       W.list_id, isNull(R.sequence,0) as sequence
       FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
       WHERE cal_status=0 -- Nuevas sin Tiempo
       and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
       and (
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
       ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
       or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
       )
       and isnull(R.status,2) = 2
       order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''
      
end -- TOMA EN CUENTA LAS NUEVAS
 
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
 begin
       select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
       WHERE callout_id in(select callout_id from #NEW_JOBS)''
end
 
if @Test = 2
begin
	select @Sql=@Sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
	declare @nSQL nvarchar(4000)
	set @nSQL=cast(@Sql as nvarchar(4000))
	exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
	return(@total)
end
else
begin
 
select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''
end
 
select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
		EXEC(@Sql)

			set @Sql = 'Alter procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int, 
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(MAX), @Order_Asc_Desc char(4)

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano 
	select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
	from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id

select @bIsDaylight=isnull(@bIsDaylight,1)

--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
 begin
	declare @horaUniversal as datetime 
	set @horaUniversal=getutcdate()

	select @iZonas=sum(distinct tz_id)from 
	(select tz_id,
		datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
		datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
		datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
		from ccTimeZones 
	)zonas inner join cchorarios on
	((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
		AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
		AND (
			Lunes=dia or
			Martes*2=dia or
			Miercoles*3=dia or
			Jueves*4=dia or
			Viernes*5=dia or
			Sabado*6=dia or
			domingo*7=dia
		)
	) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid

	if @iZonas is null begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
 end 

else
begin
	if @revHorario=0
	begin
		select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
	end
	else
	begin
		select @iZonas=Null
	end
end

set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
 cam_id int,
 cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
 cal_status tinyint,
 cal_fechaDial datetime,
 user_id int, 
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
list_id int,
sequence smallint
)''

-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
 select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id, 
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=0 -- Nuevas sin Tiempo
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''
	
 end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0 
 begin
	select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
 end

select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, 
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''

select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
		EXEC(@Sql)

		set @Sql = 'ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
@cal_id int,
@Telefono varchar(15),
@Camp smallint,
@FechaDial varchar(17),
@callout_id int=0,
@TelReprograma smallint=-1,
@user_id int=0,
@cal_Key varchar(33)=''''
as
set nocount on
IF @TelReprograma<0
      return(0)
 
declare @Fecha smalldatetime, @sSQL nvarchar(max)
declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
declare @idZone int, @idZoneDaylight int
declare @bIsDaylight bit, @difference int
declare @TelOriginal varchar(15)
declare @FechaOriginal datetime
 
select @callout_id = callout_id, @TelOriginal = cal_telefono, @FechaOriginal = cal_Inicio
from ccocallsout
where Cal_id=@cal_id
 
IF @TelReprograma=0 --Otro telefono
BEGIN
      declare @tel2 varchar(20), @tel3 varchar(20), @tel4 varchar(20), @tel5 varchar(20)
      declare @phoneCompleted varchar(20)
      declare @emptyPhoneMsg varchar(50)
 
      select @idZone = dbo.fnGetTimeZone(@Telefono,0)
      select @idZoneDaylight = dbo.fnGetTimeZone(@Telefono,1)
      select @phoneCompleted = dbo.Completa(@Telefono)
      select @emptyPhoneMsg = case valor when 0 then ''El teléfono no puede ser nulo o vacío'' else ''Phone number can not be null or empty'' end from ccsettings where setting_id = 27
 
      if charIndex(''E_NV'',@phoneCompleted) > 0
            set @phoneCompleted = @Telefono
            if @phoneCompleted = ''''
            begin
                  raiserror(@emptyPhoneMsg, 18, 1)
            end
 
     select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
     from ccoCallsoutSource where callout_id=@callout_id
     
      select @TelReprograma=case when isnull(@tel4,'''')='''' then 4 when isnull(@tel3,'''')='''' then 3     when isnull(@tel2,'''')='''' then 2 else 5 end
 
      select @sSQL=''update ccoCallsOutSource set cal_telefono''+cast(@TelReprograma as varchar(1))+''=''''''+@phoneCompleted+''''''''
      +'',cal_status=2,dial_Tels=''''''+cast(@TelReprograma as char(1))+replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')+''''''''
      +'', iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
      exec(@sSQL)
END
 
ELSE--@>0 telefono ya existente
BEGIN
      update ccoCallsOutSource set cal_status=2,
      dial_Tels=cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')
      where callout_id=@callout_id
 
      select @sSQL= N''select @outA=cal_key, @outB=izonahoraria'' +replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outC=izonahoraria_verano''+replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outD= rtrim(left(ltrim(cal_telefono + ''''        ''''
            + cal_telefono2 + ''''         ''''
            + cal_telefono3 + ''''         ''''
            + cal_telefono4 + ''''         ''''
            + cal_telefono5 + ''''         ''''),13)) from ccoCallsOutSource where callout_id = '' +cast(@callout_id as varchar)
      exec sp_executesql @sSQL, N''@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT'', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
END
 
-- PARA LA FECHA
declare @country_id as int
select @country_id = valor from ccsettings where setting_id = 104
      select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id
 
select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))    
update ccoCallsOut set cal_fcallback=@FechaDial where cal_id=@cal_id
 
--PARA LAS ESTADISTICAS
if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha) and mes=month(@Fecha) and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp)
      update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp
else
      insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@Camp
 
select @iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end, @iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end,
 @iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, @iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end,
@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, @iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end,
@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, @iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end,
@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
from ccocallsoutsource where callout_id=@callout_id
 
if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
      UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
      cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
      iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
      iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
      iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
      iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
      iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
      WHERE callout_id=@callout_id
 
else
      INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
      [user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
      iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5)
      select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
      @user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
      @iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5
 
      insert ccoCallBacks values(@callout_id,@user_id,@Camp,@cal_Key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
 
set nocount off'
		EXEC(@Sql)

			set @Sql = 'INSERT INTO ccHorarioVerano
select inicio, fin,2 from ccHorarioVeranoArg

INSERT INTO ccHorarioVerano
select inicio, fin,3 from ccHorarioVeranoCol

INSERT INTO ccHorarioVerano
select inicio, fin,4 from ccHorarioVeranoUSA

INSERT INTO ccHorarioVerano
select inicio, fin,5 from ccHorarioVeranoCHI

INSERT INTO ccHorarioVerano
select inicio, fin,6 from ccHorarioVeranoVen

insert into ccTimeZoneArea
select 1,area,location,tz_standard,tz_daylight from cctimezoneareamex
 
drop table cctimezoneareamex
 
insert into ccTimeZoneArea
select 2,area,location,tz_standard,tz_daylight from cctimezoneareaarg
 
drop table cctimezoneareaarg
drop table ccTimeZoneAreaArgDetailDifficult
 
insert into ccTimeZoneArea
select 3,area,location,tz_standard,tz_daylight from cctimezoneareacol
 
drop table cctimezoneareacol
 
insert into ccTimeZoneArea
select 4,area,location,tz_standard,tz_daylight from cctimezoneareausa
 
drop table cctimezoneareausa
drop table ccTimeZoneAreaUsaDetailDificult
 
insert into ccTimeZoneArea
select 5,area,location,tz_standard,tz_daylight from cctimezoneareachi
 
drop table cctimezoneareachi
 
insert into ccTimeZoneArea
select 6,area,location,tz_standard,tz_daylight from cctimezoneareaven
 
drop table cctimezoneareaven
 
update ccRIACat_Country set CtyCode = ''52'' where CtyID = 1
update ccRIACat_Country set CtyCode = ''54'' where CtyID = 2
update ccRIACat_Country set CtyCode = ''57'' where CtyID = 3
update ccRIACat_Country set CtyCode = ''1'' where CtyID = 4
update ccRIACat_Country set CtyCode = ''56'' where CtyID = 5
update ccRIACat_Country set CtyCode = ''58'' where CtyID = 6

alter table cstoTarifa drop constraint FK_cstoTarifa_cstoTipoLlamada
alter table ccoCallsOut drop constraint FK_ccoCallsOut_cstoTipoLlamada

exec sp_rename ''cstoTipoLlamada'', ''cstoTipoLlamadaMex'''
		EXEC(@Sql)

			set @Sql = 'CREATE TABLE dbo.cstoTipoLlamada
	(
	country_id smallint NOT NULL,
	tipoLlamada_id smallint NOT NULL,
	descrip varchar(50) NOT NULL,
	longitud tinyint NOT NULL,
	prefijo varchar(15) NOT NULL
	)  ON [PRIMARY]

CREATE UNIQUE CLUSTERED INDEX IX_cstoTipoLlamada ON dbo.cstoTipoLlamada
	(
	country_id,
	tipoLlamada_id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
		EXEC(@Sql)

			set @Sql = 'insert into cstoTipoLlamada
select 1,tipoLlamada_id,descrip,longitud,prefijo from cstoTipoLlamadaMex

drop table cstoTipoLlamadaMex
 
insert into cstoTipoLlamada
select 2,tipoLlamada_id,descrip,longitud,prefijo from cstoTipoLlamadaArg
 
drop table cstoTipoLlamadaArg
 
insert into cstoTipoLlamada
select 3,tipoLlamada_id,descrip,longitud,prefijo from cstoTipoLlamadaCol
 
drop table cstoTipoLlamadaCol
 
insert into cstoTipoLlamada
select 6,tipoLlamada_id,descrip,longitud,prefijo from cstoTipoLlamadaVen
 
drop table cstoTipoLlamadaVen'
		EXEC(@Sql)

			set @Sql = 'Alter function dbo.fnGetTipoLlamada( @tel varchar(20) )
returns int
as
 begin
	declare @len integer, @tipo integer, @country varchar(5)
	select @country = valor from ccsettings where setting_id = 104
	set @len = len( @tel )
	
	select @tipo= tipoLlamada_id from cstoTipoLlamada with(index(IX_cstoTipoLlamada)) 
	where country_id = @country and (@len = longitud or longitud =0 )and @tel like prefijo 
	order by len(prefijo) asc -- para agarrar el ultimo ( el mas especifico), si se devuelven varias lineas
	return isnull(@tipo , 0)
 end'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccspOutDialTypes]	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @country varchar(100) ;
	SELECT @country = valor FROM dbo.ccSettings WHERE setting_id = 104 ;
	
	SELECT tipoLlamada_id,longitud,prefijo FROM dbo.cstoTipoLlamada where country_id = @country ;	
END'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIACATRates]
@carrier_id smallint,
@CallType_id varchar(2),
@firstMinute varchar(20) = null,
@extraMinute varchar(20) = null,
@Type tinyint 
AS

DECLARE @sql nvarchar(1000),@country as tinyInt
select @country = valor from ccSettings where setting_id = 104

	if( @Type=1)
		begin
			--select cstoProvedor.provedor_id, cstoProvedor.descrip, cstoTarifa.tipollamada_id, cstoTipoLlamada.descrip, cstoTarifa.minutoUno, cstoTarifa.minutoAdicional from cstoTarifa, cstoProvedor, cstoTipoLlamada where cstoProvedor.provedor_id = cstoTarifa.provedor_id And cstoTarifa.tipollamada_id = cstoTipoLlamada.tipollamada_id order by cstoProvedor.provedor_id asc
			select a.provedor_id, a.descrip,c.tipoLlamada_id,c.descrip, b.minutoUno,b.minutoAdicional from cstoProvedor a 
			left outer join cstoTarifa b on a.provedor_id = b.provedor_id
			left outer join cstoTipoLlamada c on (b.tipoLlamada_id = c.tipoLlamada_id and c.country_id = @country)
		end
	If( @Type=2)
		begin
			insert into cstoTarifa (provedor_id, tipollamada_id, minutoUno, minutoAdicional) values (@carrier_id,@CallType_id,@firstMinute,@extraMinute)
		end
	If( @Type=3)
		begin
			delete cstoTarifa where tipollamada_id = @CallType_id and provedor_id = @carrier_id
			select 3
		end
	if( @Type=4)
		begin
			/*set @sql = ''update cstoTarifa set ''
			IF @firstMinute not in('''',null)
				BEGIN
					set @sql = @sql + ''minutoUno = '''''' +@firstMinute + '''''',''
				END
			IF @extraMinute not in('''',null)
				BEGIN
					set @sql = @sql + ''minutoAdicional = '''''' + @extraMinute + '''''',''
				END
			
			set @sql = left( @sql, len( @sql)-1 )
			set @sql = @sql + '' where tipollamada_id = '' + @CallType_id + '' and provedor_id = '' + @carrier_id
		
			print @sql
			execute sp_executesql @sql
		*/
			update cstoTarifa set
			minutoUno = (case @firstMinute when null then minutoUno else @firstMinute end),  
			minutoAdicional = (case @extraMinute when null then minutoAdicional else @extraMinute end) 
			where tipollamada_id = @CallType_id and provedor_id = @carrier_id
		end
	If( @Type=5)
		begin
			select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = @country --where tipoLlamada_id not in (
			--select tipoLlamada_id from cstoTarifa where provedor_id = @carrier_id)
		end'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_GetProveedor]
@tel as varchar(32),
@cam_id as varchar(5)
as
declare @sql varchar(4000), @country varchar(2), @tabla varchar(100)
select @country = valor from ccSettings where setting_id = 104

select @tabla = ''cstoTipoLlamada''

set @sql = ''declare @bestprov as varchar(10), @typeCall as varchar(2), @Cost as varchar(10)
set @bestprov = ''''''''
select top 1 @typeCall = tipollamada_id from '' + @tabla + '' where country_id = '' + convert(varchar(3),@country) + '' and len('''''' + @tel + '''''') = longitud and '''''' + @tel + '''''' like prefijo order by len(prefijo) desc

select top 1 @Cost = minutouno, @typeCall = tipoLlamada_id from cstotarifa where tipoLlamada_id = @typeCall
and provedor_id in (select distinct provedor_id from ccodialers where dialer_id in (select dialer_id from ccodialercamp where cam_id = ''+@cam_id+''))
order by minutoUno, minutoAdicional

select top 3 @bestprov = @bestprov + case when @bestprov = '''''''' then '''''''' else ''''&'''' end + convert(varchar(2),provedor_id), @typeCall = tipoLlamada_id  from cstotarifa 
where tipoLlamada_id = @typeCall and minutouno = @Cost and provedor_id in (select distinct provedor_id from ccodialers where dialer_id in (select dialer_id from ccodialercamp where cam_id = ''+@cam_id+''))

if @bestProv is null or @bestProv = ''''''''
begin
	select top 1 @bestProv = provedor_id, @typeCall = tipoLlamada_id from cstotarifa where provedor_id in (select distinct provedor_id from ccodialers where dialer_id in (select dialer_id from ccodialercamp where cam_id = ''+@cam_id+'')) order by minutoUno desc, minutoAdicional desc
end

select @bestprov + ''''|'''' + @typeCall''

--print @sql
exec (@sql)'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]
--@idcampana as varchar(10),
--@fechacal as datetime
AS

declare @ld varchar(4)
declare @idagenda  int
declare @campsid int
declare @fechacal datetime
declare @Listid int

SET NOCOUNT ON

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL 
) ON [PRIMARY]

select top 1 @idagenda = idagenda, @campsid = campsid, @fechacal=fecharegs   from ccagendalistanegra where status= 1 and fechaaplicar < getdate() order by fechaaplicar asc
IF @idagenda is not  null
BEGIN

select top 1 @Listid = idtipolista from ccagenda_tipolistanegra where idagenda = @idagenda order by idtipolista asc

update ccagendalistanegra set inicio=getdate() where idagenda=@idagenda

insert #mycamps
select  campsid  from ccagendalistanegra where idagenda=@idagenda and  status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

CREATE TABLE [dbo].[#mytemp] (
	[callout_id] [int] NULL, 
             [telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
             [idtipolista] [int] NULL
) ON [PRIMARY]

CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) ON [PRIMARY]

select @ld = valor from ccSettings where setting_id = 17

-----------------------------------------------------------------------------  telefono1

IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra 
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
              insert #mytemp
	---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra 
	select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
delete ccoWOrkingTable 
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
							 + cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono1 de CS
update ccoCallsOutSource set cal_telefono = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp


----------------------------------------------------------------------------------- -telefono 2
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
             insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono2 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
delete ccoWOrkingTable 
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono and rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
							 + cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id

where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono2 de CS
update ccoCallsOutSource set cal_telefono2 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 3
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono3 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable 
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono  and  rtrim(left(ltrim(            cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(             cs.cal_telefono4 + ''         ''
							 + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono3 de CS
update ccoCallsOutSource set cal_telefono3 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 4
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono4 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable 
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono = 
rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs 
inner join ccoWorkingTable wt
on cs.callout_id = wt.callout_id
inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono4 de CS
update ccoCallsOutSource set cal_telefono4 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 5
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
	insert #mytemp 
	--Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
	select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs inner join ccListaNegra ln
	on cs.cal_telefono5 = dbo.Completa(ln.telefono)
	INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable 
from ccoWOrkingTable wt inner join ccoCallsOutSource cs
on wt.callout_id = cs.callout_id
inner join #mytemp t
on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp
truncate table #mycamps

update ccagendalistanegra set termino=getdate() where idagenda=@idagenda
update ccagendalistanegra set status=''0'' where idagenda=@idagenda

END'
		EXEC(@Sql)

			set @Sql = 'ALTER proc [dbo].[ccspOutDialerCsto]
as
set nocount on
declare @RtnValue table (prov_Id int identity(1,1), costoloc decimal(15,3), costoLD decimal(15,3), costoCel decimal(15,3), costoCelLD decimal(15,3), costo01800 decimal(15,3), costoLDUsa decimal(15,3), costoLDInter decimal(15,3))
declare @sql as varchar(max), @insert as varchar(max), @sql2 as varchar(max), @query as varchar(max), @country tinyint
select @country = valor from ccsettings where setting_id = 104
set @query = ''declare @RtnValue table (provedor_id int ''
set @sql = ''select provedor_id ''
set @insert = ''''
select @sql = @sql + '', sum(case when tipollamada_id = '' + convert(varchar(3),tipollamada_id) + '' then isnull(minutoUno,100) else 0 end) [''+ descrip +'']'', @insert = @insert + '', [''+ descrip +'']'', @query = @query + '', ['' + descrip +''] decimal(15,3) '' from cstotipollamada where country_id = @country
set @sql = '' Insert Into @RtnValue (provedor_id'' + @insert + '') '' + @sql + '' from cstotarifa group by provedor_id ''
set @query = @query + '')''
set @sql2 = '' select dialer_id, Puerto, Extension, Status, Descripcion, d.provedor_id'' + @insert + '' FROM ccoDialers d Left Join @RtnValue c on d.provedor_id = c.provedor_id ORDER BY Puerto''
--print (@query + @sql + @sql2)
exec (@query + @sql + @sql2)
set nocount off'
		EXEC(@Sql)

			set @Sql = 'alter table dbo.ccEstadosAni
	alter column Estado varchar(350) NOT NULL

alter table dbo.ccEstadosAni
	alter column area varchar(20) NOT NULL

alter table dbo.ccEstadosAni
	alter column telAni varchar(30) NOT NULL'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccspGenCatalogos]
@server AS varchar(200)
AS
SET NOCOUNT ON
declare @sql  varchar(8000)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccUsers'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccCalifCamp'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccCamps'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccCampsAgente'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccInbound'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccStatusLlamada'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccSupervisorCam'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccTipoCalif'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccTipoCalifOUT'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccTipoNotReady'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccTipoStatusAgente'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccInboundAgentes'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccTipoResultadoDial'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table cstoProvedor'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccPosicion'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccDNIS'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table cstoTipoLlamada'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccodialers'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table cstoTarifa'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccriacat_workgroup'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccRIAWorkGroupUsers'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccRIACat_Areas'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccRIAAreaWorkGroup'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table telefonostransferencia'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table telefonosConferencia'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table ccCallsReject'' + char(39)
--print @sql
exec(@sql)

set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table cctipocalifsub'' + char(39)
--print @sql
exec(@sql)
set @sql = @server + ''.dbo.sp_executesql N'' + char(39) + ''truncate table cctipocalifsubout'' + char(39)
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccCalifCamp (calif_id, cam_id, tipo) ''
set @sql = @sql + ''select calif_id, cam_id, tipo from ccCalifCamp''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccUsers (User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange) ''
set @sql = @sql + ''select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange from ccUsers''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccUsers (User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange) ''
set @sql = @sql + ''select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,Password,TipoUser_id,Status,TipoLLamadas,Sexo,filter,CanChangeStatus,fCreate,DialMask,xFerMask,LastPasswordChange from ccUsers_Consulta''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccCamps (cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_''

set @sql = @sql + ''ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_t''
set @sql = @sql + ''DialBeforeWU, cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani) ''
set @sql = @sql + ''select cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_ocupado, cam_inter_noconte''
set @sql = @sql + ''sto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, cam_tDialBef''
set @sql = @sql + ''oreReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani from ccCamps''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccCamps (cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_''

set @sql = @sql + ''ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_t''
set @sql = @sql + ''DialBeforeWU, cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani) ''
set @sql = @sql + ''select cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, cam_inter_ocupado, cam_inter_noconte''
set @sql = @sql + ''sto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql, cam_tnotas, cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, cam_tDialBef''
set @sql = @sql + ''oreReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, cam_fCreate, cam_MaxDlrXage, ani from ccCamps_Consulta''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccCampsAgente (user_id, cam_id, prioridad, skill) ''
set @sql = @sql + ''select distinct user_id, cam_id, prioridad, skill from ccCampsAgente''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccInbound (cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath)''
set @sql = @sql + ''select isnull(cli_id,0) cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath from ccInbound''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccInbound (cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath)''
set @sql = @sql + ''select isnull(cli_id,0) cli_id,Inbound_id,descripcion,Status,dnis,standby,tNotas,tMaxWaitCall,nMaxQue,Msg_id,tel_maxwait,tel_maxqueue,tel_outservice,tel_noct,bnocturno,ShowCalifWnd,StartTimerOnHangUp,voicePath from ccInbound_Consulta''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccStatusLlamada (statusCall_id,descripcion) ''
set @sql = @sql + ''select statusCall_id,descripcion from ccStatusLlamada''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccSupervisorCam (user_id,cam_id,tipo) ''
set @sql = @sql + ''select distinct user_id,cam_id,tipo from ccSupervisorCam''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccTipoCalif (calif_id,Description,orden) ''
set @sql = @sql + ''select calif_id,Description,orden from ccTipoCalif''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccTipoCalifOUT (calif_id,Description,autoTime,CanReprogram,orden) ''
set @sql = @sql + ''select calif_id,Description,autoTime,CanReprogram,orden from ccTipoCalifOUT''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccTipoNotReady (TipoNotReady_id,Descripcion) ''
set @sql = @sql + ''select TipoNotReady_id,Descripcion from ccTipoNotReady''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccTipoStatusAgente (TipoStatusAge_id,descripcion) ''
set @sql = @sql + ''select TipoStatusAge_id,descripcion from ccTipoStatusAgente''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccInboundAgentes (User_id,Inbound_id,cli_id,prioridad,skill) ''
set @sql = @sql + ''select distinct User_id,Inbound_id,cli_id,prioridad,skill from ccInboundAgentes''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccTipoResultadoDial ( tipoResDial_id,descripcion) ''
set @sql = @sql + ''select tipoResDial_id,descripcion from ccTipoResultadoDial''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.cstoProvedor ( provedor_id,descrip) ''
set @sql = @sql + ''select provedor_id,descrip from cstoProvedor''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccPosicion (pos_id,Computer,ext_id,user_id,Status,tipoConexion,IP) ''
set @sql = @sql + ''select pos_id,Computer,ext_id,user_id,Status,tipoConexion,IP from ccPosicion''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccDNIS (dni_id,dni_numero,dni_tipo,tipodni_id,dni_tpoMaxEspera,dni_Descripcion) ''
set @sql = @sql + ''select dni_id,dni_numero,dni_tipo,tipodni_id,dni_tpoMaxEspera,dni_Descripcion from ccDNIS''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) ''
set @sql = @sql + ''select country_id,tipoLlamada_id,descrip,longitud,prefijo from cstoTipoLlamada''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccoDialers (dialer_id, Descripcion, Puerto, Extension, Status, provedor_id) ''
set @sql = @sql + ''select dialer_id, Descripcion, Puerto, Extension, Status, provedor_id from ccoDialers''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.cstoTarifa (provedor_id, tipoLlamada_id, minutoUno, minutoAdicional) ''
set @sql = @sql + ''select provedor_id, tipoLlamada_id, minutoUno, minutoAdicional from cstoTarifa''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccriacat_workgroup (idwg,wgname) ''
set @sql = @sql + ''select idwg,wgname from ccriacat_workgroup''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccRIAWorkGroupUsers (idwg, user_id) ''
set @sql = @sql + ''select idwg,user_id from ccRIAWorkGroupUsers''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccRIACat_Areas (IDArea,AreaName) ''
set @sql = @sql + ''select IDArea, AreaName from ccRIACat_Areas''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccRIAAreaWorkGroup (IDWG,IDArea) ''
set @sql = @sql + ''select IDWG, IDArea from ccRIAAreaWorkGroup''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.telefonosConferencia (nombre,tel) ''
set @sql = @sql + ''select nombre,tel from telefonosConferencia''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.telefonosTransferencia (nombre,tel) ''
set @sql = @sql + ''select nombre,tel from telefonosConferencia''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.ccCallsReject (cal_id, ani, dnis, puerto, cal_inicio, Inbound_id) ''
set @sql = @sql + ''select cal_id, ani, dnis, puerto, cal_inicio, Inbound_id from ccCallsReject''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.cctipocalifsub (califsub_id, califsubdesc, orden, canreprogram,califsub_status) ''
set @sql = @sql + ''select califsub_id, califsubdesc, isnull(orden,0), isnull(canreprogram,0),califsub_status from cctipocalifsub''
--print @sql
exec(@sql)

set @sql = ''insert into '' + @server +''.dbo.cctipocalifsubout (califsub_id, califsubdesc,canreprogram,orden,idtipolista,califsubout_status,keepdial,autocallback) ''
set @sql = @sql + ''select califsub_id, califsubdesc,isnull(canreprogram,0),isnull(orden,0),isnull(idtipolista,0),califsubout_status,isnull(keepdial,0),isnull(autocallback,0) from cctipocalifsubout''
--print @sql
exec(@sql)'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Other'')

--EXEC sp_generate_inserts ''ccRIANotReadyGraph''
DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada
DBCC CHECKIDENT (''cstoTipoLlamada'', RESEED, 0)
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104
insert into cstoTipoLlamada values (@country_id,1,''Standard call'', 8, ''%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Ask for general information'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Call hung'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')'
		EXEC(@Sql)

			set @Sql = 'ALTER procEDURE [dbo].[configuraIdiomaCatalogosEspañol]
AS
Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
truncate table cstoTarifa
delete cstoTipoLlamada
DBCC CHECKIDENT (''cstoTipoLlamada'', RESEED, 0)
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,1,''Local'',8,''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,2,''LD nacional'',12,''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,3,''Cel'',13,''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,4,''Cel LD'',13,''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,5,''01800'',12,''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,6,''LD usa'',13,''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,7,''LD inter'',0,''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita Informacion General'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se Corto la Llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccspGenOutCstoResumen]
@from AS smalldatetime,
@to AS smalldatetime
AS
declare @country as tinyInt
select @country = valor from ccSettings where setting_id = 104

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCstoResumen (timegroup, cam_id, [user_id], provedor_id, tipoLlamada_id, amount, mins, costo)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cam_id, [user_id], provedor_id, tipoLlamada_id 
	, COUNT(*)
	, SUM( mins)
	, SUM( costo )
FROM
(
	SELECT cal_inicio, cam_id, [user_id], provedor_id, tipoLlamada_id, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
	FROM ccoCallsOut
	WHERE cal_inicio >= @from AND  cal_inicio < @to and provedor_id is not null and cal_manual in (0,2)

	-- Tambien las llamdas que fueron fax
	UNION ALL

	SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, 1, t.MinutoUno as costo
	FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
	WHERE 
	l.country_id = @country
	and cco.answerbit = 1 and cco.tiporesdial_id <> 1
	and cco.fecha >=  @from AND cco.fecha < @to
	and cco.puerto = cd.puerto
	and cd.provedor_id = p.provedor_id	
	and p.provedor_id = t.provedor_id
	and l.longitud = len(cco.telefono)
	and cco.telefono like l.prefijo
	and t.tipoLlamada_id = l.tipoLlamada_id
)x
GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id'
		EXEC(@Sql)

			set @Sql = '--script de agregar un pais
update ccsettings set detalle = ''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita'' where setting_id = 104

--agregar valores a la tabla de cctimezonearea
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 1, ''Riyadh'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 2, ''Jeddah, Taif, Rabigh'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 3, ''Qatif, Dammam, Dhahran, Hafar Al-Batin'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 4, ''Al-Madinah, Tabuk, Al-Jawf'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 5, ''cellphone'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 6, ''Al-Qassim, Buraidah, Majma and Hail'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 7, ''Asir, Al-Baha, Jizan, Najran, Khamis Mushait'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 8, ''Atheeb GO Telecom phone numbers'', 32768, 32768)
insert into cctimeZoneArea (id_country, area, location, tz_standard,tz_daylight) values (8, 9, ''Saudi Arabia'', 32768, 32768)

insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''113'', ''Leeds'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''114'', ''Sheffield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''115'', ''Nottingham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''116'', ''Leicester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''117'', ''Bristol'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''118'', ''Reading'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1200'', ''Clitheroe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1202'', ''Bournemouth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1204'', ''Bolton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1205'', ''Boston'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1206'', ''Colchester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1207'', ''Consett'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1208'', ''Bodmin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1209'', ''Redruth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''121'', ''Birmingham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1223'', ''Cambridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1224'', ''Aberdeen'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1225'', ''Bath'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1226'', ''Barnsley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1227'', ''Canterbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1228'', ''Carlisle'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1229'', ''Barrow-in-Furness'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1233'', ''Ashford (Kent)'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1234'', ''Bedford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1235'', ''Abingdon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1236'', ''Coatbridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1237'', ''Bideford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1239'', ''Cardigan'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1241'', ''Arbroath'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1242'', ''Cheltenham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1243'', ''Chichester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1244'', ''Chester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1245'', ''Chelmsford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1246'', ''Chesterfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1248'', ''Bangor (Gwynedd)'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1249'', ''Chippenham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1250'', ''Blairgowrie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1252'', ''Aldershot'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1253'', ''Blackpool'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1254'', ''Blackburn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1255'', ''Clacton-on-Sea'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1256'', ''Basingstoke'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1257'', ''Coppull'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1258'', ''Blandford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1259'', ''Alloa'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1260'', ''Congleton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1261'', ''Banff'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1262'', ''Bridlington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1263'', ''Cromer'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1264'', ''Andover'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1267'', ''Carmarthen'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1268'', ''Basildon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1269'', ''Ammanford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1270'', ''Crewe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1271'', ''Barnstable'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1273'', ''Brighton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1274'', ''Bradford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1275'', ''Clevedon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1276'', ''Camberley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1277'', ''Brentwood'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1278'', ''Bridgwater'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1279'', ''Bishops Stortford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1280'', ''Buckingham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1282'', ''Burnley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1283'', ''Burton-on-Trent'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1284'', ''Bury-St-Edmunds'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1285'', ''Cirencester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1286'', ''Caernarvon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1287'', ''Guisborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1288'', ''Bude'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1289'', ''Berwick-on-Tweed'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1290'', ''Cumnock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1291'', ''Chepstow'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1292'', ''Ayr'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1293'', ''Crawley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1294'', ''Ardrossan'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1295'', ''Banbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1296'', ''Aylesbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1297'', ''Axminster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1298'', ''Buxton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1299'', ''Bewdley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1300'', ''Cerne Abbas'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1301'', ''Arrochar'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1302'', ''Doncaster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1303'', ''Folkestone'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1304'', ''Dover'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1305'', ''Dorchester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1306'', ''Dorking'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1307'', ''Forfar'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1308'', ''Bridport'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1309'', ''Forres'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''131'', ''Edinburgh'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1320'', ''Fort Augustus'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1322'', ''Dartford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1323'', ''Eastbourne'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1324'', ''Falkirk'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1325'', ''Darlington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1326'', ''Falmouth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1327'', ''Daventry'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1328'', ''Fakenham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1329'', ''Fareham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1330'', ''Banchory'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1332'', ''Derby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1333'', ''Peat Inn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1334'', ''St Andrews'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1335'', ''Ashbourne'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1337'', ''Ladybank'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1339'', ''Aboyne'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1340'', ''Craigellachie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1341'', ''Barmouth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1342'', ''East Grinstead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1343'', ''Elgin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1344'', ''Bracknell'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1346'', ''Fraserburgh'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1347'', ''Easingwold'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1348'', ''Fishguard'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1349'', ''Dingwall'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1350'', ''Dunkeld'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1352'', ''Mold'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1353'', ''Ely'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1354'', ''Chatteris'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1355'', ''East Kilbride'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1356'', ''Brechin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1357'', ''Strathaven'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1358'', ''Ellon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1359'', ''Pakenham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1360'', ''Killearn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1361'', ''Duns'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1362'', ''Dereham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1363'', ''Crediton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1364'', ''Ashburton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1366'', ''Downham Market'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1367'', ''Faringdon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1368'', ''Dunbar'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1369'', ''Dunoon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1371'', ''Great Dunmow'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1372'', ''Esher'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1373'', ''Frome'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1375'', ''Grays Thurrock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1376'', ''Braintree'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1377'', ''Driffield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1379'', ''Diss'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1380'', ''Devizes'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1381'', ''Fortrose'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1382'', ''Dundee'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1383'', ''Dunfermline'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1384'', ''Dudley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1386'', ''Evesham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1387'', ''Dumfries'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''13873'', ''Langholm'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1388'', ''Stanhope'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1389'', ''Dumbarton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1392'', ''Exeter'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1394'', ''Felixstowe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1395'', ''Budleigh Salterton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1397'', ''Fort William'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1398'', ''Dulverton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1400'', ''Honington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1403'', ''Horsham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1404'', ''Honiton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1405'', ''Goole'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1406'', ''Holbeach'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1407'', ''Holyhead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1408'', ''Golspie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1409'', ''Holsworthy'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''141'', ''Glasgow'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1420'', ''Alton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1422'', ''Halifax'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1423'', ''Harrogate'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1424'', ''Hastings'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1425'', ''Ringwood'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1427'', ''Gainsborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1428'', ''Haslemere'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1429'', ''Hartlepool'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1430'', ''North Cave'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1431'', ''Helmsdale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1432'', ''Hereford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1433'', ''Hathersage'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1434'', ''Bellingham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1435'', ''Heathfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1436'', ''Helensburgh'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1437'', ''Clynderwen'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1438'', ''Stevenage'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1439'', ''Helmsley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1440'', ''Haverhill'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1442'', ''Hemel Hempstead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1443'', ''Pontypridd'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1444'', ''Haywards Heath'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1445'', ''Gairloch'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1446'', ''Barry'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1449'', ''Stowmarket'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1450'', ''Hawick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1451'', ''Stow-on-the-Wold'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1452'', ''Gloucester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1453'', ''Dursley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1454'', ''Chipping Sodbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1455'', ''Hinckley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1456'', ''Glenurquhart'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1457'', ''Glossop'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1458'', ''Glastonbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1460'', ''Chard'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1461'', ''Gretna'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1462'', ''Hitchin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1463'', ''Inverness'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1464'', ''Insch'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1465'', ''Girvan'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1466'', ''Huntly'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1467'', ''Inverurie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1469'', ''Killingholme'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1470'', ''Isle of Skye – Edinbane'', 1, 32768)

insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1471'', ''Isle of Skye – Broadford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1472'', ''Grimsby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1473'', ''Ipswich'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1474'', ''Gravesend'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1475'', ''Greenock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1476'', ''Grantham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1477'', ''Holmes Chapel'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1478'', ''Isle of Skye – Portree'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1479'', ''Grantown-on-Spey'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1480'', ''Huntingdon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1481'', ''Guernsey'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1482'', ''Hull'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1483'', ''Guildford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1484'', ''Huddersfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1485'', ''Hunstanton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1487'', ''Warboys'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1488'', ''Hungerford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1489'', ''Bishops Waltham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1490'', ''Corwen'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1491'', ''Henley-on-Thames'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1492'', ''Colwyn Bay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1493'', ''Great Yarmouth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1494'', ''High Wycombe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1495'', ''Pontypool'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1496'', ''Port Ellen'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1497'', ''Hay-on-Wye'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1499'', ''Inveraray'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1501'', ''Harthill'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1502'', ''Lowestoft'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1503'', ''Looe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1505'', ''Johnstone'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1506'', ''Bathgate'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1507'', ''Spilsby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1508'', ''Brooke'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1509'', ''Loughborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''151'', ''Liverpool'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1520'', ''Lochcarron'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1522'', ''Lincoln'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1524'', ''Lancaster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''15242'', ''Hornby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1525'', ''Leighton Buzzard'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1526'', ''Martin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1527'', ''Redditch'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1528'', ''Laggan'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1529'', ''Sleaford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1530'', ''Coalville'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1531'', ''Ledbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1534'', ''Jersey'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1535'', ''Keighley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1536'', ''Kettering'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1538'', ''Ipstones'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1539'', ''Kendal'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''15394'', ''Hawkshead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''15395'', ''Grange-Over-Sands'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''15396'', ''Sedbergh'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1540'', ''Kingussie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1542'', ''Keith'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1543'', ''Cannock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1544'', ''Kington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1545'', ''Llanarth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1546'', ''Lochgilphead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1547'', ''Knighton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1548'', ''Kingsbridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1549'', ''Lairg'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1550'', ''Llandovery'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1553'', ''Kings Lynn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1554'', ''Llanelli'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1555'', ''Lanark'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1556'', ''Castle Douglas'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1557'', ''Kirkcudbright'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1558'', ''Llandeilo'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1559'', ''Llandyssul'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1560'', ''Moscow'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1561'', ''Laurencekirk'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1562'', ''Kidderminster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1563'', ''Kilmarnock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1564'', ''Lapworth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1565'', ''Knutsford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1566'', ''Launceston'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1567'', ''Killin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1568'', ''Leominster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1569'', ''Stonehaven'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1570'', ''Lampeter'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1571'', ''Lochinver'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1572'', ''Oakham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1573'', ''Kelso'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1575'', ''Kirriemuir'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1576'', ''Lockerbie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1577'', ''Kinross'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1578'', ''Lauder'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1579'', ''Liskeard'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1580'', ''Cranbrook'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1581'', ''New Luce'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1582'', ''Luton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1583'', ''Carradale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1584'', ''Ludlow'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1586'', ''Campbeltown'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1588'', ''Bishops Castle'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1590'', ''Lymington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1591'', ''Llanwrtyd Wells'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1592'', ''Kirkcaldy'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1593'', ''Lybster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1594'', ''Lydney'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1595'', ''Lerwick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1597'', ''Llandrindod Wells'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1598'', ''Lynton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1599'', ''Kyle'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1600'', ''Monmouth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1603'', ''Norwich'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1604'', ''Northampton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1606'', ''Northwich'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1608'', ''Chipping Norton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1609'', ''Northallerton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''161'', ''Manchester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1620'', ''North Berwick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1621'', ''Maldon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1622'', ''Maidstone'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1623'', ''Mansfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1624'', ''Isle of Man'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1625'', ''Macclesfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1626'', ''Newton Abbot'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1628'', ''Maidenhead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1629'', ''Matlock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1630'', ''Market Drayton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1631'', ''Oban'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1633'', ''Newport'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1634'', ''Medway'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1635'', ''Newbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1636'', ''Newark'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1637'', ''Newquay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1638'', ''Newmarket'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1639'', ''Neath'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1641'', ''Strathy'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1642'', ''Middlesbrough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1643'', ''Minehead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1644'', ''New Galloway'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1646'', ''Milford Haven'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1647'', ''Moretonhampstead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1650'', ''Cemmaes Road'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1651'', ''Oldmeldrum'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1652'', ''Brigg'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1653'', ''Malton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1654'', ''Machynlleth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1655'', ''Maybole'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1656'', ''Bridgend'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1659'', ''Sanquhar'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1661'', ''Prudhoe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1663'', ''New Mills'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1664'', ''Melton Mowbray'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1665'', ''Alnwick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1666'', ''Malmesbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1667'', ''Nairn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1668'', ''Bamburgh'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1669'', ''Rothbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1670'', ''Morpeth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1671'', ''Newton Stewart'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1672'', ''Marlborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1673'', ''Market Rasen'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1674'', ''Montrose'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1675'', ''Coleshill'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1676'', ''Meriden'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1677'', ''Bedale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1678'', ''Bala'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1680'', ''Isle of Mull – Craignure'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1681'', ''Isle of Mull – Fionnphort'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1683'', ''Moffat'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1684'', ''Malvern'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1685'', ''Merthyr Tydfil'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1686'', ''Llanidloes'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1687'', ''Mallaig'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1688'', ''Isle of Mull – Tobermory'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1689'', ''Orpington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1690'', ''Betws-y-Coed'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1691'', ''Oswestry'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1692'', ''North Walsham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1694'', ''Church Stretton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1695'', ''Skelmersdale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1697'', ''Brampton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''16973'', ''Wigton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''16974'', ''Raughton Head'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1698'', ''Motherwell'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1700'', ''Rothesay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1702'', ''Southend-on-Sea'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1704'', ''Southport'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1706'', ''Rochdale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1707'', ''Welwyn Garden City'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1708'', ''Romford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1709'', ''Rotherham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1720'', ''Isles of Scilly'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1721'', ''Peebles'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1722'', ''Salisbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1723'', ''Scarborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1724'', ''Scunthorpe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1725'', ''Rockbourne'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1726'', ''St Austell'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1727'', ''St Albans'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1728'', ''Saxmundham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1729'', ''Settle'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1730'', ''Petersfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1732'', ''Sevenoaks'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1733'', ''Peterborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1736'', ''Penzance'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1737'', ''Redhill'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1738'', ''Perth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1740'', ''Sedgefield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1743'', ''Shrewsbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1744'', ''St Helens'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1745'', ''Rhyl'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1746'', ''Bridgnorth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1747'', ''Shaftesbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1748'', ''Richmond'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1749'', ''Shepton Mallet'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1750'', ''Selkirk'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1751'', ''Pickering'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1752'', ''Plymouth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1753'', ''Slough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1754'', ''Skegness'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1756'', ''Skipton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1757'', ''Selby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1758'', ''Pwllheli'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1759'', ''Pocklington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1760'', ''Swaffham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1761'', ''Temple Cloud'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1763'', ''Royston'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1764'', ''Crieff'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1765'', ''Ripon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1766'', ''Porthmadog'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1767'', ''Sandy'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1768'', ''Penrith'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''17683'', ''Appleby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''17684'', ''Pooley Bridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''17687'', ''Keswick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1769'', ''South Molton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1770'', ''Isle of Arran'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1771'', ''Maud'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1772'', ''Preston'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1773'', ''Ripley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1775'', ''Spalding'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1776'', ''Stranraer'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1777'', ''Retford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1778'', ''Bourne'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1779'', ''Peterhead'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1780'', ''Stamford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1782'', ''Stoke-on-Trent'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1784'', ''Staines'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1785'', ''Stafford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1786'', ''Stirling'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1787'', ''Sudbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1788'', ''Rugby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1789'', ''Stratford-upon-Avon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1790'', ''Spilsby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1792'', ''Swansea'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1793'', ''Swindon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1794'', ''Romsey'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1795'', ''Sittingbourne'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1796'', ''Pitlochry'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1797'', ''Rye'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1798'', ''Pulborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1799'', ''Saffron Walden'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1803'', ''Torquay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1805'', ''Torrington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1806'', ''Shetland'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1807'', ''Ballindalloch'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1808'', ''Tomatin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1809'', ''Tomdoun'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1821'', ''Kinrossie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1822'', ''Tavistock'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1823'', ''Taunton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1824'', ''Ruthin'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1825'', ''Uckfield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1827'', ''Tamworth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1828'', ''Coupar Angus'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1829'', ''Tarporley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1830'', ''Kirkwhelpington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1832'', ''Clopton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1833'', ''Barnard Castle'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1834'', ''Narberth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1835'', ''St Boswells'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1837'', ''Okehampton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1838'', ''Dalmally'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1840'', ''Camelford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1841'', ''Newquay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1842'', ''Thetford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1843'', ''Thanet'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1844'', ''Thame'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1845'', ''Thirsk'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1847'', ''Thurso'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1848'', ''Thornhill'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1851'', ''Stornoway'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1852'', ''Kilmelford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1854'', ''Ullapool'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1855'', ''Ballachulish'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1856'', ''Orkney'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1857'', ''Sanday'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1858'', ''Market Harborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1859'', ''Harris'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1862'', ''Tain'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1863'', ''Ardgay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1864'', ''Abington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1865'', ''Oxford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1866'', ''Kilchrenan'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1869'', ''Bicester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1870'', ''Isle of Benbecula'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1871'', ''Castlebay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1872'', ''Truro'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1873'', ''Abergavenny'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1874'', ''Brecon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1875'', ''Tranent'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1876'', ''Lochmaddy'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1877'', ''Callandar'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1878'', ''Lochboisdale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1879'', ''Scarinish'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1880'', ''Tarbert'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1882'', ''Kinloch Rannoch'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1883'', ''Caterham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1884'', ''Tiverton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1885'', ''Pencombe'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1886'', ''Bromyard'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1887'', ''Aberfeldy'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1888'', ''Turriff'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1889'', ''Rugely'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1890'', ''Coldstream'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1892'', ''Tunbridge Wells'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1895'', ''Uxbridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1896'', ''Galashiels'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1899'', ''Biggar'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1900'', ''Workington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1902'', ''Wolverhampton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1903'', ''Worthing'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1904'', ''York'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1905'', ''Worcester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1908'', ''Milton Keynes'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1909'', ''Worksop'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''191'', ''Tyneside'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1920'', ''Ware'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1922'', ''Walsall'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1923'', ''Watford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1924'', ''Wakefield'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1925'', ''Warrington'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1926'', ''Warwick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1928'', ''Runcorn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1929'', ''Wareham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1931'', ''Shap'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1932'', ''Weybridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1933'', ''Wellingborough'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1934'', ''Weston-Super-Mare'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1935'', ''Yeovil'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1937'', ''Wetherby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1938'', ''Welshpool'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1939'', ''Wem'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1942'', ''Wigan'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1943'', ''Guiseley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1944'', ''West Heslerton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1945'', ''Wisbech'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1946'', ''Whitehaven'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''19467'', ''Gosforth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1947'', ''Whitby'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1948'', ''Whitchurch'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1949'', ''Whatton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1950'', ''Sandwick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1951'', ''Colonsay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1952'', ''Telford'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1953'', ''Wymondham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1954'', ''Madingley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1955'', ''Wick'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1957'', ''Mid Yell'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1959'', ''Westerham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1962'', ''Winchester'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1963'', ''Wincanton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1964'', ''Hornsea'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1967'', ''Strontian'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1968'', ''Penicuik'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1969'', ''Leyburn'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1970'', ''Aberystwyth'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1971'', ''Scourie'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1972'', ''Glenborrodale'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1974'', ''Llanon'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1975'', ''Alford (Aberdeen)'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1977'', ''Pontefract'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1978'', ''Wrexham'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1980'', ''Amesbury'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1981'', ''Wormbridge'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1982'', ''Builth Wells'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1983'', ''Isle of Wight'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1984'', ''Watchet'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1985'', ''Warminster'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1986'', ''Bungay'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1987'', ''Ebbsfleet'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1988'', ''Wigtown'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1989'', ''Ross-on-Wye'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1992'', ''Lea Valley'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1993'', ''Witney'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1994'', ''St Clears'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1995'', ''Garstang'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''1997'', ''Strathpeffer'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''20'', ''London'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''23'', ''Southampton'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''24'', ''Coventry'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''28'', ''Ballycastle'', 1, 32768)
insert into ccTimeZoneArea(id_country, area, location, tz_standard, tz_daylight) values(7, ''29'', ''Cardiff'', 1, 32768)'
		EXEC(@Sql)

			set @Sql = '--------------modificacion de funcion completa
ALTER function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32) 
AS  
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita
if @pais = 1 
 begin
	--Empieza Mexico
	select @resultado = case 
	 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
	 when len(@resultado)=12 then 
	   case when left(@resultado, 2) = ''01'' then
		 case when substring(@resultado, 3, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	 when len(@resultado)=13 then
	   case when left(@resultado, 3) in (''044'', ''045'') then
		 case when substring(@resultado, 4, len(@ld)) = @ld then
		   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10) 
		 end
	   else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Mexico
	return @resultado
 end

if @pais = 2 
 begin
	-- Empieza Argentina
	select @resultado = case 
	 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then 
		@resultado
	-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
	-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
	 when len(@resultado) = 8 then
		case when len(@ld) = 4 then
			case when left(@resultado,2) = ''15'' then @resultado end
		else 
			case when len(@ld) = 2 then @resultado end
		end
	-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
	 when len(@resultado)=9 then
		case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
	-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
	 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else 
			case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end 
	   end
	-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
	-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
	 when len(@resultado)=11 then 
	   case when left(@resultado, 1) = ''0'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
	-- si no es local se le agrega el 0 y se marca el numero
	 when len(@resultado)=12 then
		case when left(@resultado, len(@ld)) = @ld then 
			case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then 
				right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
	-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
	 when len(@resultado)=13 then
		case when left(@resultado, 1) = ''0'' then
			case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Argentina	
	return @resultado	
 end

if @pais = 3 
 begin
	--Empieza colombia
	select @resultado = case 
	--Si son 7 digitos, se regresa igual
	 when len(@resultado)=7 then 
		@resultado
	--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
	 when len(@resultado) = 8  then
		case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end		
	-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
	 when len(@resultado)=10 then
		case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado 
		else
			''E_NV_Cel'' 
		end
	--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
	--prefijo de celular
	 when len(@resultado)=11 then 
		case when left(@resultado,1)=''0'' then
			case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end	

	-- Termina Colombia
	return @resultado	
 end

if @pais = 4 
 begin
	--Empieza USA
	select @resultado = case len(@resultado)
	 when 3 then
		case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
	 when 7 then @resultado
	 when 10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
	 when 11 then 
	   case when left(@resultado, 1) = ''1'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	else ''E_NV_Longitud'' end

	--Termina USA
	return @resultado
 end

if @pais = 5 
 begin
	select @resultado = case len(@resultado) 
	 when 6 then @resultado 
	 when 7 then @resultado
	-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
	 when 8 then

		case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else				
			case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
				case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
				 else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end	
			 end
		end
	-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
	-- de telefonia voIp se le agrega el 0 al inicio
	 when 9 then
		case when @ld = left(@resultado,2) then right(@resultado,7) else
			case when left(@resultado,2) in (41,32,65) then @resultado else 
				case when left(@resultado,2) = ''44'' then ''0'' + @resultado else 
					case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
				 end
			end
		end
	 when 10 then
		case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	-- Termina Chile
	return @resultado
 end

-- Venezuela
if @pais = 6 begin
	select @resultado = case len(@resultado)
		when 7 then @resultado
		when 10 then ''0'' + @resultado
		when 11 then 
			case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
		else 
	    ''E_NV_Longitud'' end
end
--Termina Venezuela

-- UK
if @pais = 7 begin
	select @resultado = case len(@resultado)
		when 11 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''E_NV_Longitud''
			end
		when 10 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''0'' + @resultado
			end
		when 9 then
			case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		when 8 then
			case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
		when 7 then
			case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		else
		''E_NV_Longitud''
	end
end
-- Termina UK

if @pais = 8 begin -- arabia saudita
	select @resultado = case len(@resultado)
	when 7 then @resultado
	when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
	when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado 
				when ''0'' then case substring(@resultado, 2, 1) 
						when @ld then right(@resultado, 7) else @resultado end 
				else ''E_NV_Longitud''
				end
	when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
	when 11 then case substring(@resultado, 2, 1) 
					when ''8'' then case substring(@resultado, 3, 3) 
									when ''111'' then @resultado else ''E_NV_Longitud'' end 
					else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
					end
	when 13 then @resultado
	else ''E_NV_Longitud'' end
end -- arabia saudita

-- Termina
return @resultado

end'
		EXEC(@Sql)

			set @Sql = '----- agrega registros a tabla cstoTipoLlamada
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(8,1,''Local'', 7,''%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(8,2,''LD Old'', 9,''0%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(8,3,''Cel'', 10,''05%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(8,4,''LD New'', 11,''0%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(8,5,''LD Inter'', 13,''00%'')

insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(7,1,''Local'', 10,''%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(7,2,''LD'', 11,''0%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(7,3,''Cel'', 11,''07%'')
insert into cstoTipoLlamada (country_id, tipoLlamada_id, descrip, longitud, prefijo) values(7,4,''LD Inter'', 13,''00%'')

------agrega registros a la tabla ccHorarioVerano
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20120402 02:00:00'',''20120402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20130402 02:00:00'',''20130402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20140402 02:00:00'',''20140402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20150402 02:00:00'',''20150402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20160402 02:00:00'',''20160402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20170402 02:00:00'',''20170402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20180402 02:00:00'',''20180402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20190402 02:00:00'',''20190402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20200402 02:00:00'',''20200402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20210402 02:00:00'',''20210402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20220402 02:00:00'',''20220402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20230402 02:00:00'',''20230402 02:00:00'')
insert into ccHorarioVerano (country_id, inicio, fin) values(8, ''20240402 02:00:00'',''20240402 02:00:00'')

insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/25 01:00:00.000'', ''2012/10/28 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/31 01:00:00.000'', ''2012/10/13 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/14 01:00:00.000'', ''2012/10/14 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/15 01:00:00.000'', ''2012/10/15 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/16 01:00:00.000'', ''2012/10/16 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/17 01:00:00.000'', ''2012/10/17 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/18 01:00:00.000'', ''2012/10/18 02:00:00.000'')
insert into ccHorarioVerano(country_id, inicio, fin) values(7, ''2012/03/19 01:00:00.000'', ''2012/10/19 02:00:00.000'')'
		EXEC(@Sql)

			set @Sql = '----------------crea tabla de series
CREATE TABLE dbo.seriesSA
	(
	Regiones nvarchar(MAX) NOT NULL,
	CLD varchar(4) NULL,
	[SERIE Inicio] varchar(4) NULL,
	[SERIE Fin] varchar(4) NULL,
	[Numeracion inicial] varchar(7) NULL,
	[Numeracion Final] varchar(7) NULL,
	[Tipo de red] varchar(10) NULL,
	Modalidad varchar(10) NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]

CREATE TABLE [dbo].[seriesUK](
	[id] [int] IDENTITY(1,1) PRIMARY KEY,
	[CLD] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Region] [varchar](35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NumeracionInicial] [varchar](9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NumeracionFinal] [varchar](9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Modalidad] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]'
		EXEC(@Sql)

			set @Sql = '------------------------agrega registros a la tabla seriesSA
insert into seriesSA values(''Riyadh'',''01'',''800'',''899'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Afif,Sulayil, Tamarh, Khamasin, Nowayimah'',''01'',''700'',''799'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Dawadmi, Sajir, Artawi, Arja, Bijadiyah, Faydah, Nifi, Qurayn,Shaqra, Marat, Ushayqir, Qasab,Quwayiyah, Jilah, Rayn, Muhhayriqah, Halaban, Al Ruwaydah, Al Khasirah,Layla'',''01'',''600'',''699'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Hurayamala, Uyaynah,Rimah,Durma, Muzahimiyah, Jow, Ghat, Al Jufayr,Al Kharj, Sahnah, Dilam,Hawtat Bani Tamim, Hariq'',''01'',''500'',''599'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Riyadh'',''01'',''400'',''499'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Sattelite services'',''01'',''300'',''399'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Riyadh'',''01'',''200'',''299'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Muwayah, Zalim, Al Dafinah,Khurmah, Turabah, Ranyah, Al Amlah'',''02'',''800'',''899'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Taif, Al Qoray, Sahan Bani Saad, Yelamlam, Hadad Bani Malik, Ushayrah'',''02'',''700'',''799'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Jeddah'',''02'',''600'',''699'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Makkah, Jumum, Sharayi Al Mujahidin'',''02'',''500'',''599'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Jeddah'',''02'',''400'',''499'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''02'',''300'',''399'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Jeddah'',''02'',''200'',''299'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Dammam, Khobar, Dahran, Seihat, Qatif, Safwa, Ras Tanurah, Traut, Thoqbah, Rahimah'',''03'',''800'',''899'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Hafer Al Baten, Ruqi , Quaysmah, King Khalid City,Nairiyah, Khafji,Sarar, Qariyat Al Ulya, Ma’aqala, Nita'',''03'',''700'',''799'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Dammam, Khobar, Dahran, Seihat, Qatif, Safwa, Ras Tanurah, Traut, Thoqbah, Rahimah'',''03'',''600'',''699'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Abqaiq, Ain Dar, Urayirah,Hofuf, Salwa, Uqayr, Ahsa, Harad, Khurais'',''03'',''500'',''599'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''03'',''400'',''499'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Nairiyah, Khafji,Sarar, Qariyat Al Ulya, Ma’aqala, Nita,Jubail'',''03'',''300'',''399'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''03'',''200'',''299'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Al Ula,Khaybar, Al Silsilah,Hanakiyah, Mahd Al Dahab, Al Suwaydrah, Al Hisu,Medinah, Al Mulayleeh'',''04'',''800'',''899'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''04'',''700'',''799'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Rafha, Duwayd, Uwayqilah, Maaniyah,Lawqah, Linah, Shuabat Nisab, Nisab, Um Ruhaymah, Samah, Samudah,Arar, Turayf, Judaidah,Sakaka, Domat Al Jandal, Nabk Abu Qasr, Qara, Tabarjal,Qurayat, Isawiyah, Haditha, Kaf, Qaraqir, Hadraj, Maabiyah'',''04'',''600'',''699'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''04'',''500'',''599'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Tabuk, Haql, Hallet Amar, Uyaynah, Talaah, Badiah, Fajr, Akhadar, Qalibah,Umluj, Wajh,Duba, Bada, Shaqrah, Sharaf, Shawq,Tayma, Al Jabawiyah'',''04'',''400'',''499'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Umluj, Wajh,Badr Hunayn, Al Musayjid, Al Wasitah, Al Rayyan, Al Akhal, Al Rayyis,Yenbu, Al Ayiss'',''04'',''300'',''399'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''04'',''200'',''299'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Saudi Telecom Company'',''050'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Future use'',''051'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Future use'',''052'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Saudi Telecom Company'',''053'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Mobily'',''054'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Saudi Telecom Company'',''055'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Mobily'',''056'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Future use'',''057'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Zain Saudi Arabia'',''058'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Zain Saudi Arabia'',''059'',''200'',''899'',''0000'',''9999'',''MOVIL'',''CPP'')
insert into seriesSA values(''Future use'',''06'',''800'',''899'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''06'',''700'',''799'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''06'',''600'',''699'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Baqa,Hail, Jubbah'',''06'',''500'',''599'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Al Maah, Al Zilfi, Al Ghat, Thumair, Hawtat Sudair, Thadiq, Rawdat Sudair, Al Artawiyah, Jalajil'',''06'',''400'',''499'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Ain Bin Fuhayd,Buraydah, Unayzah, Badaya, Al Rass, Riyadh Al Khabrah, Al Bukayriyah, Al Miznab, Uyun Al Jiwa, Al Safra, Al Shihiyah, Shamasiyah'',''06'',''300'',''399'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Subayh, Uqalat As Suqur, Dulaymiyah,Dukhnah,Hayit, Shamli'',''06'',''200'',''299'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''07'',''800'',''899'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Lith, Qunfudah,Biljurashi, Hamir, Baha, Bani Dhabyan, Atawlah Mandaq'',''07'',''700'',''799'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Bisha, Sabt Al Alaya'',''07'',''600'',''699'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Najran, Al Arissah, Al Faysaliyah,Sharorah'',''07'',''500'',''599'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Future use'',''07'',''400'',''499'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Jizan, Tuwal, Abu Arish, Sabya, Samitah, Baysh, Suq Al Ahad, Damad, Darb'',''07'',''300'',''399'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Abha, Khamis Mushait, Usran, Rownah, Ahad Rofiydah, Sorat Abidah Dharan Al Janoub,Al Nimas, Al Sarh, Tanumah, Balasmar, Barik'',''07'',''200'',''299'',''0000'',''9999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''08'',''111'',''111'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''01'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''02'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''03'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''04'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''05'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''06'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')
insert into seriesSA values(''Atheeb GO Telecom phone numbers'',''07'',''510'',''511'',''000000'',''999999'',''Fijo'',''Fijo'')

-- aqui van las seriesuk
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''113'', ''Leeds'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''114'', ''Sheffield'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''115'', ''Nottingham'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''116'', ''Leicester'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''117'', ''Bristol'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''118'', ''Reading'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1200'', ''Clitheroe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1202'', ''Bournemouth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1204'', ''Bolton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1205'', ''Boston'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1206'', ''Colchester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1207'', ''Consett'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1208'', ''Bodmin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1209'', ''Redruth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''121'', ''Birmingham'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1223'', ''Cambridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1224'', ''Aberdeen'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1225'', ''Bath'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1226'', ''Barnsley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1227'', ''Canterbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1228'', ''Carlisle'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12292'', ''Barrow-in-Furness'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12293'', ''Millom'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12294'', ''Barrow-in-Furness'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12295'', ''Barrow-in-Furness'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12296'', ''Barrow-in-Furness'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12297'', ''Millom'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12298'', ''Barrow-in-Furness'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''12299'', ''Millom'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1233'', ''Ashford (Kent)'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1234'', ''Bedford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1235'', ''Abingdon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1236'', ''Coatbridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1237'', ''Bideford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1239'', ''Cardigan'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1241'', ''Arbroath'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1242'', ''Cheltenham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1243'', ''Chichester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1244'', ''Chester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1245'', ''Chelmsford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1246'', ''Chesterfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1248'', ''Bangor (Gwynedd)'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1249'', ''Chippenham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1250'', ''Blairgowrie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1252'', ''Aldershot'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1253'', ''Blackpool'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1254'', ''Blackburn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1255'', ''Clacton-on-Sea'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1256'', ''Basingstoke'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1257'', ''Coppull'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1258'', ''Blandford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1259'', ''Alloa'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1260'', ''Congleton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1261'', ''Banff'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1262'', ''Bridlington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1263'', ''Cromer'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1264'', ''Andover'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1267'', ''Carmarthen'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1268'', ''Basildon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1269'', ''Ammanford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1270'', ''Crewe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1271'', ''Barnstable'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1273'', ''Brighton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1274'', ''Bradford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1275'', ''Clevedon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1276'', ''Camberley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1277'', ''Brentwood'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1278'', ''Bridgwater'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1279'', ''Bishops Stortford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1280'', ''Buckingham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1282'', ''Burnley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1283'', ''Burton-on-Trent'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1284'', ''Bury-St-Edmunds'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1285'', ''Cirencester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1286'', ''Caernarvon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1287'', ''Guisborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1288'', ''Bude'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1289'', ''Berwick-on-Tweed'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1290'', ''Cumnock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1291'', ''Chepstow'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1292'', ''Ayr'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1293'', ''Crawley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1294'', ''Ardrossan'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1295'', ''Banbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1296'', ''Aylesbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1297'', ''Axminster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1298'', ''Buxton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1299'', ''Bewdley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1300'', ''Cerne Abbas'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1301'', ''Arrochar'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1302'', ''Doncaster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1303'', ''Folkestone'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1304'', ''Dover'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1305'', ''Dorchester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1306'', ''Dorking'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1307'', ''Forfar'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1308'', ''Bridport'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1309'', ''Forres'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''131'', ''Edinburgh'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1320'', ''Fort Augustus'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1322'', ''Dartford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1323'', ''Eastbourne'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1324'', ''Falkirk'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1325'', ''Darlington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1326'', ''Falmouth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1327'', ''Daventry'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1328'', ''Fakenham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1329'', ''Fareham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1330'', ''Banchory'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1332'', ''Derby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1333'', ''Peat Inn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1334'', ''St Andrews'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1335'', ''Ashbourne'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1337'', ''Ladybank'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13392'', ''Aboyne'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13393'', ''Aboyne'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13394'', ''Ballater'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13395'', ''Aboyne'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13396'', ''Ballater'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13397'', ''Ballater'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13398'', ''Aboyne'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13399'', ''Ballater'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1340'', ''Craigellachie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1341'', ''Barmouth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1342'', ''East Grinstead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1343'', ''Elgin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1344'', ''Bracknell'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1346'', ''Fraserburgh'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1347'', ''Easingwold'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1348'', ''Fishguard'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1349'', ''Dingwall'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1350'', ''Dunkeld'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1352'', ''Mold'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1353'', ''Ely'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1354'', ''Chatteris'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1355'', ''East Kilbride'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1356'', ''Brechin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1357'', ''Strathaven'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1358'', ''Ellon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1359'', ''Pakenham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1360'', ''Killearn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1361'', ''Duns'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1362'', ''Dereham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1363'', ''Crediton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1364'', ''Ashburton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1366'', ''Downham Market'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1367'', ''Faringdon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1368'', ''Dunbar'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1369'', ''Dunoon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1371'', ''Great Dunmow'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1372'', ''Esher'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1373'', ''Frome'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1375'', ''Grays Thurrock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1376'', ''Braintree'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1377'', ''Driffield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1379'', ''Diss'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1380'', ''Devizes'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1381'', ''Fortrose'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1382'', ''Dundee'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1383'', ''Dunfermline'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1384'', ''Dudley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1386'', ''Evesham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1387'', ''Dumfries'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13873'', ''Langholm'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13882'', ''Stanhope'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13883'', ''Bishop Auckland'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13884'', ''Bishop Auckland'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13885'', ''Stanhope'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13886'', ''Bishop Auckland'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13887'', ''Bishop Auckland'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13888'', ''Bishop Auckland'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''13889'', ''Bishop Auckland'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1389'', ''Dumbarton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1392'', ''Exeter'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1394'', ''Felixstowe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1395'', ''Budleigh Salterton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1397'', ''Fort William'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1398'', ''Dulverton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1400'', ''Honington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1403'', ''Horsham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1404'', ''Honiton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1405'', ''Goole'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1406'', ''Holbeach'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1407'', ''Holyhead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1408'', ''Golspie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1409'', ''Holsworthy'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''141'', ''Glasgow'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1420'', ''Alton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1422'', ''Halifax'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14232'', ''Harrogate'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14233'', ''Boroughbridge'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14234'', ''Boroughbridge'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14235'', ''Harrogate'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14236'', ''Harrogate'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14237'', ''Harrogate'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14238'', ''Harrogate'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14239'', ''Boroughbridge'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1424'', ''Hastings'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1425'', ''Ringwood'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1427'', ''Gainsborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1428'', ''Haslemere'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1429'', ''Hartlepool'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14302'', ''North Cave'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14303'', ''North Cave'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14304'', ''North Cave'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14305'', ''North Cave'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14306'', ''Market Weighton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14307'', ''Market Weighton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14308'', ''Market Weighton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14309'', ''Market Weighton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1431'', ''Helmsdale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1432'', ''Hereford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1433'', ''Hathersage'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14342'', ''Bellingham'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14343'', ''Haltwhistle'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14344'', ''Bellingham'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14345'', ''Haltwhistle'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14346'', ''Hexham'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14347'', ''Hexham'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14348'', ''Hexham'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14349'', ''Bellingham'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1435'', ''Heathfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1436'', ''Helensburgh'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14372'', ''Clynderwen'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14373'', ''Clynderwen'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14374'', ''Clynderwen'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14375'', ''Clynderwen'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14376'', ''Haverfordwest'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14377'', ''Haverfordwest'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14378'', ''Haverfordwest'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''14379'', ''Haverfordwest'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1438'', ''Stevenage'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1439'', ''Helmsley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1440'', ''Haverhill'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1442'', ''Hemel Hempstead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1443'', ''Pontypridd'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1444'', ''Haywards Heath'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1445'', ''Gairloch'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1446'', ''Barry'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1449'', ''Stowmarket'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1450'', ''Hawick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1451'', ''Stow-on-the-Wold'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1452'', ''Gloucester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1453'', ''Dursley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1454'', ''Chipping Sodbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1455'', ''Hinckley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1456'', ''Glenurquhart'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1457'', ''Glossop'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1458'', ''Glastonbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1460'', ''Chard'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1461'', ''Gretna'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1462'', ''Hitchin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1463'', ''Inverness'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1464'', ''Insch'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1465'', ''Girvan'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1466'', ''Huntly'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1467'', ''Inverurie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1469'', ''Killingholme'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1470'', ''Isle of Skye – Edinbane'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1471'', ''Isle of Skye – Broadford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1472'', ''Grimsby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1473'', ''Ipswich'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1474'', ''Gravesend'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1475'', ''Greenock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1476'', ''Grantham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1477'', ''Holmes Chapel'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1478'', ''Isle of Skye – Portree'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1479'', ''Grantown-on-Spey'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1480'', ''Huntingdon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1481'', ''Guernsey'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1482'', ''Hull'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1483'', ''Guildford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1484'', ''Huddersfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1485'', ''Hunstanton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1487'', ''Warboys'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1488'', ''Hungerford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1489'', ''Bishops Waltham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1490'', ''Corwen'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1491'', ''Henley-on-Thames'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1492'', ''Colwyn Bay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1493'', ''Great Yarmouth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1494'', ''High Wycombe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1495'', ''Pontypool'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1496'', ''Port Ellen'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1497'', ''Hay-on-Wye'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1499'', ''Inveraray'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1501'', ''Harthill'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1502'', ''Lowestoft'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1503'', ''Looe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1505'', ''Johnstone'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1506'', ''Bathgate'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15072'', ''Spilsby'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15073'', ''Louth'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15074'', ''Alford (Lincs)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15075'', ''Spilsby'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15076'', ''Louth'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15077'', ''Louth'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15078'', ''Alford (Lincs)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15079'', ''Alford (Lincs)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1508'', ''Brooke'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1509'', ''Loughborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''151'', ''Liverpool'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1520'', ''Lochcarron'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1522'', ''Lincoln'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1524'', ''Lancaster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15242'', ''Hornby'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1525'', ''Leighton Buzzard'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1526'', ''Martin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1527'', ''Redditch'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1528'', ''Laggan'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1529'', ''Sleaford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1530'', ''Coalville'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1531'', ''Ledbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1534'', ''Jersey'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1535'', ''Keighley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1536'', ''Kettering'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1538'', ''Ipstones'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1539'', ''Kendal'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15394'', ''Hawkshead'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15395'', ''Grange-Over-Sands'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''15396'', ''Sedbergh'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1540'', ''Kingussie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1542'', ''Keith'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1543'', ''Cannock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1544'', ''Kington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1545'', ''Llanarth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1546'', ''Lochgilphead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1547'', ''Knighton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1548'', ''Kingsbridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1549'', ''Lairg'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1550'', ''Llandovery'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1553'', ''Kings Lynn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1554'', ''Llanelli'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1555'', ''Lanark'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1556'', ''Castle Douglas'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1557'', ''Kirkcudbright'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1558'', ''Llandeilo'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1559'', ''Llandyssul'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1560'', ''Moscow'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1561'', ''Laurencekirk'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1562'', ''Kidderminster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1563'', ''Kilmarnock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1564'', ''Lapworth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1565'', ''Knutsford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1566'', ''Launceston'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1567'', ''Killin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1568'', ''Leominster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1569'', ''Stonehaven'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1570'', ''Lampeter'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1571'', ''Lochinver'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1572'', ''Oakham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1573'', ''Kelso'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1575'', ''Kirriemuir'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1576'', ''Lockerbie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1577'', ''Kinross'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1578'', ''Lauder'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1579'', ''Liskeard'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1580'', ''Cranbrook'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1581'', ''New Luce'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1582'', ''Luton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1583'', ''Carradale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1584'', ''Ludlow'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1586'', ''Campbeltown'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1588'', ''Bishops Castle'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1590'', ''Lymington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1591'', ''Llanwrtyd Wells'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1592'', ''Kirkcaldy'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1593'', ''Lybster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1594'', ''Lydney'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1595'', ''Lerwick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''159575'', ''Foula'',''0000'', ''9999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''159576'', ''Fair Isle'',''0000'', ''9999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1597'', ''Llandrindod Wells'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1598'', ''Lynton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1599'', ''Kyle'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1600'', ''Monmouth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1603'', ''Norwich'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1604'', ''Northampton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1606'', ''Northwich'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1608'', ''Chipping Norton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1609'', ''Northallerton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''161'', ''Manchester'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1620'', ''North Berwick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1621'', ''Maldon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1622'', ''Maidstone'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1623'', ''Mansfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1624'', ''Isle of Man'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1625'', ''Macclesfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1626'', ''Newton Abbot'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1628'', ''Maidenhead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1629'', ''Matlock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1630'', ''Market Drayton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1631'', ''Oban'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1633'', ''Newport'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1634'', ''Medway'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1635'', ''Newbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1636'', ''Newark'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1637'', ''Newquay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1638'', ''Newmarket'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1639'', ''Neath'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1641'', ''Strathy'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1642'', ''Middlesbrough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1643'', ''Minehead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1644'', ''New Galloway'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1646'', ''Milford Haven'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1647'', ''Moretonhampstead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1650'', ''Cemmaes Road'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1651'', ''Oldmeldrum'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1652'', ''Brigg'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1653'', ''Malton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1654'', ''Machynlleth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1655'', ''Maybole'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1656'', ''Bridgend'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1659'', ''Sanquhar'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1661'', ''Prudhoe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1663'', ''New Mills'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1664'', ''Melton Mowbray'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1665'', ''Alnwick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1666'', ''Malmesbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1667'', ''Nairn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1668'', ''Bamburgh'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1669'', ''Rothbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1670'', ''Morpeth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1671'', ''Newton Stewart'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1672'', ''Marlborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1673'', ''Market Rasen'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1674'', ''Montrose'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1675'', ''Coleshill'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1676'', ''Meriden'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1677'', ''Bedale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1678'', ''Bala'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1680'', ''Isle of Mull – Craignure'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1681'', ''Isle of Mull – Fionnphort'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1683'', ''Moffat'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1684'', ''Malvern'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1685'', ''Merthyr Tydfil'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16862'', ''Llanidloes'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16863'', ''Llanidloes'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16864'', ''Llanidloes'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16865'', ''Newtown'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16866'', ''Newtown'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16867'', ''Llanidloes'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16868'', ''Newtown'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16869'', ''Newtown'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1687'', ''Mallaig'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1688'', ''Isle of Mull – Tobermory'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1689'', ''Orpington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1690'', ''Betws-y-Coed'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1691'', ''Oswestry'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1692'', ''North Walsham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1694'', ''Church Stretton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1695'', ''Skelmersdale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1697'', ''Brampton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16973'', ''Wigton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''16974'', ''Raughton Head'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1698'', ''Motherwell'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1700'', ''Rothesay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1702'', ''Southend-on-Sea'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1704'', ''Southport'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1706'', ''Rochdale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1707'', ''Welwyn Garden City'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1708'', ''Romford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1709'', ''Rotherham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1720'', ''Isles of Scilly'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1721'', ''Peebles'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1722'', ''Salisbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1723'', ''Scarborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1724'', ''Scunthorpe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1725'', ''Rockbourne'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1726'', ''St Austell'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1727'', ''St Albans'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1728'', ''Saxmundham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1729'', ''Settle'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1730'', ''Petersfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1732'', ''Sevenoaks'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1733'', ''Peterborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1736'', ''Penzance'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1737'', ''Redhill'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1738'', ''Perth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1740'', ''Sedgefield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1743'', ''Shrewsbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1744'', ''St Helens'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1745'', ''Rhyl'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1746'', ''Bridgnorth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1747'', ''Shaftesbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1748'', ''Richmond'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1749'', ''Shepton Mallet'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1750'', ''Selkirk'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1751'', ''Pickering'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1752'', ''Plymouth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1753'', ''Slough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1754'', ''Skegness'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1756'', ''Skipton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1757'', ''Selby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1758'', ''Pwllheli'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1759'', ''Pocklington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1760'', ''Swaffham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1761'', ''Temple Cloud'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1763'', ''Royston'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1764'', ''Crieff'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1765'', ''Ripon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1766'', ''Porthmadog'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1767'', ''Sandy'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1768'', ''Penrith'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''17683'', ''Appleby'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''17684'', ''Pooley Bridge'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''17687'', ''Keswick'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1769'', ''South Molton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1770'', ''Isle of Arran'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1771'', ''Maud'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1772'', ''Preston'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1773'', ''Ripley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1775'', ''Spalding'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1776'', ''Stranraer'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1777'', ''Retford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1778'', ''Bourne'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1779'', ''Peterhead'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1780'', ''Stamford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1782'', ''Stoke-on-Trent'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1784'', ''Staines'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1785'', ''Stafford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1786'', ''Stirling'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1787'', ''Sudbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1788'', ''Rugby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1789'', ''Stratford-upon-Avon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1790'', ''Spilsby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1792'', ''Swansea'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1793'', ''Swindon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1794'', ''Romsey'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1795'', ''Sittingbourne'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1796'', ''Pitlochry'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1797'', ''Rye'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1798'', ''Pulborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1799'', ''Saffron Walden'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1803'', ''Torquay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1805'', ''Torrington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1806'', ''Shetland'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1807'', ''Ballindalloch'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1808'', ''Tomatin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1809'', ''Tomdoun'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1821'', ''Kinrossie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1822'', ''Tavistock'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1823'', ''Taunton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1824'', ''Ruthin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1825'', ''Uckfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1827'', ''Tamworth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1828'', ''Coupar Angus'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1829'', ''Tarporley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1830'', ''Kirkwhelpington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1832'', ''Clopton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1833'', ''Barnard Castle'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1834'', ''Narberth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1835'', ''St Boswells'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1837'', ''Okehampton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1838'', ''Dalmally'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1840'', ''Camelford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1841'', ''Newquay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1842'', ''Thetford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1843'', ''Thanet'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1844'', ''Thame'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1845'', ''Thirsk'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18472'', ''Thurso'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18473'', ''Thurso'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18474'', ''Thurso'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18475'', ''Thurso'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18476'', ''Tongue'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18477'', ''Tongue'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18478'', ''Thurso'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18479'', ''Tongue'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1848'', ''Thornhill'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18512'', ''Stornoway'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18513'', ''Stornoway'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18514'', ''Great Bernera'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18515'', ''Stornoway'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18516'', ''Great Bernera'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18517'', ''Stornoway'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18518'', ''Stornoway'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18519'', ''Great Bernera'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1852'', ''Kilmelford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1854'', ''Ullapool'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1855'', ''Ballachulish'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1856'', ''Orkney'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1857'', ''Sanday'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1858'', ''Market Harborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1859'', ''Harris'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1862'', ''Tain'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1863'', ''Ardgay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1864'', ''Abington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1865'', ''Oxford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1866'', ''Kilchrenan'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1869'', ''Bicester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1870'', ''Isle of Benbecula'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1871'', ''Castlebay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1872'', ''Truro'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1873'', ''Abergavenny'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1874'', ''Brecon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1875'', ''Tranent'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1876'', ''Lochmaddy'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1877'', ''Callandar'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1878'', ''Lochboisdale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1879'', ''Scarinish'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1880'', ''Tarbert'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1882'', ''Kinloch Rannoch'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1883'', ''Caterham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1884'', ''Tiverton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1885'', ''Pencombe'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1886'', ''Bromyard'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1887'', ''Aberfeldy'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1888'', ''Turriff'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1889'', ''Rugely'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18902'', ''Coldstream'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18903'', ''Coldstream'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18904'', ''Coldstream'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18905'', ''Ayton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18906'', ''Ayton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18907'', ''Ayton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18908'', ''Coldstream'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''18909'', ''Ayton'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1892'', ''Tunbridge Wells'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1895'', ''Uxbridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1896'', ''Galashiels'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1899'', ''Biggar'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1900'', ''Workington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1902'', ''Wolverhampton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1903'', ''Worthing'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1904'', ''York'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1905'', ''Worcester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1908'', ''Milton Keynes'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1909'', ''Worksop'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1912'', ''Tyneside'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1913'', ''Durham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1914'', ''Tyneside'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1915'', ''Sunderland'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1916'', ''Tyneside'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1920'', ''Ware'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1922'', ''Walsall'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1923'', ''Watford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1924'', ''Wakefield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1925'', ''Warrington'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1926'', ''Warwick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1928'', ''Runcorn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1929'', ''Wareham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1931'', ''Shap'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1932'', ''Weybridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1933'', ''Wellingborough'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1934'', ''Weston-Super-Mare'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1935'', ''Yeovil'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1937'', ''Wetherby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1938'', ''Welshpool'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1939'', ''Wem'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1942'', ''Wigan'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1943'', ''Guiseley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1944'', ''West Heslerton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1945'', ''Wisbech'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1946'', ''Whitehaven'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19467'', ''Gosforth'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1947'', ''Whitby'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1948'', ''Whitchurch'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1949'', ''Whatton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1950'', ''Sandwick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1951'', ''Colonsay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1952'', ''Telford'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1953'', ''Wymondham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1954'', ''Madingley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1955'', ''Wick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1957'', ''Mid Yell'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1959'', ''Westerham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1962'', ''Winchester'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1963'', ''Wincanton'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19642'', ''Hornsea'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19643'', ''Patrington'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19644'', ''Patrington'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19645'', ''Hornsea'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19646'', ''Patrington'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19647'', ''Patrington'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19648'', ''Hornsea'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19649'', ''Hornsea'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1967'', ''Strontian'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1968'', ''Penicuik'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1969'', ''Leyburn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1970'', ''Aberystwyth'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1971'', ''Scourie'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1972'', ''Glenborrodale'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1974'', ''Llanon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19752'', ''Alford (Aberdeen)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''3'', ''Strathdon'',''000000000'', ''999999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19754'', ''Alford (Aberdeen)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19755'', ''Alford (Aberdeen)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19756'', ''Strathdon'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19757'', ''Strathdon'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19758'', ''Strathdon'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''19759'', ''Alford (Aberdeen)'',''00000'', ''99999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1977'', ''Pontefract'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1978'', ''Wrexham'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1980'', ''Amesbury'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1981'', ''Wormbridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1982'', ''Builth Wells'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1983'', ''Isle of Wight'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1984'', ''Watchet'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1985'', ''Warminster'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1986'', ''Bungay'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1987'', ''Ebbsfleet'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1988'', ''Wigtown'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1989'', ''Ross-on-Wye'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1992'', ''Lea Valley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1993'', ''Witney'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1994'', ''St Clears'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1995'', ''Garstang'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''1997'', ''Strathpeffer'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''20'', ''London'',''00000000'', ''99999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''238'', ''Southampton'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''239'', ''Portsmouth'',''0000000'', ''9999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''24'', ''Coventry'',''00000000'', ''99999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2820'', ''Ballycastle'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2821'', ''Martinstown'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2825'', ''Ballymena'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2827'', ''Ballymoney'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2828'', ''Larne'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2829'', ''Kilrea'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2830'', ''Newry'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2837'', ''Armagh'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2838'', ''Portadown'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2840'', ''Banbridge'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2841'', ''Rostrevor'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2842'', ''Kircubbin'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2843'', ''Newcastle(Co. Down)'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2844'', ''Downpatrick'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2866'', ''Enniskillen'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2867'', ''Lisnaskea'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2868'', ''Kesh'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2870'', ''Coleraine'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2871'', ''Londonderry'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2877'', ''Limavady'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2879'', ''Magherafelt'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2880'', ''Carrickmore'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2881'', ''Newtownstewart'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2882'', ''Omagh'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2885'', ''Ballygawley'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2886'', ''Cookstown'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2887'', ''Dungannon'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2889'', ''Fivemiletown'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2890'', ''Belfast'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2891'', ''Bangor'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2892'', ''Lisburn'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2893'', ''Ballyclare'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2894'', ''Antrim'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2895'', ''Belfast'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''2897'', ''Saintfield'',''000000'', ''999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''29'', ''Cardiff'',''00000000'', ''99999999'', ''Fijo'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''70'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''74'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''75'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''76'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''77'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''78'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''79'', ''mobile'',''00000000'', ''99999999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''79112'', ''mobile'',''00000'', ''99999'', ''CPP'')
insert into seriesUK(CLD, Region, NumeracionInicial, NumeracionFinal, Modalidad) values(''79118'', ''mobile'',''00000'', ''99999'', ''CPP'')'
		EXEC(@Sql)

			set @Sql = 'ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN				
	declare @idioma as int	
	declare @lada as varchar(5)	
	declare @timeZone as int
		
	select @lada = valor from ccsettings where setting_id = 17	

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
			where id_country = @country and (
			( len(@phone) = 8 and @lada = area and len(area) = 2 ) 
			or
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))		
		end	
			
		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone)
			if left(@phone,1) = ''E'' begin set @phone = @telTemp end
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
						( len(@phone) = 6 and @lada = area and len(area) = 4 )
						or
						( len(@phone) = 7 and @lada = area and len(area) = 3 )
						or
						( len(@phone) = 8 and @lada = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )		
						or
						( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or	
						( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )	
						or
						( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )	
						if @timeZone is null  
							begin  
								select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
								where id_country = @country and ( 
									( len(@phone) = 6 and @lada = area and len(area) = 4 and right(@phone,4) = area )
									or
									( len(@phone) = 7 and @lada = area and len(area) = 3 and right(@phone,3) = area )
									or
									( len(@phone) = 8 and @lada = area and len(area) = 2 and right(@phone,2) = area )
									or
									( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
							end	
		end

	if @country = 3 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area ) 
		or
		( len(@phone) = 8 and left(@phone,1) = area ) 
		or
		( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
	end
	
	if @country = 4

		begin					
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
			( len(@phone) = 7 and @lada = area and len(area) = 3 and right(@phone,3) = prefix )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
			if @timeZone is null  
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea 
					where id_country = @country and (
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))	
				end					
		end	

	if @country = 5 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 6 and @lada = area ) 
		or
		( len(@phone) = 7 and @lada = area ) 
		or
		( len(@phone) = 8 and left(@phone,1) = area ) 
		or
		( len(@phone) = 8 and left(@phone,2) = area ) 
		or
		( len(@phone) = 9 and left(@phone,2) = area ) 
		or
		( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
	end

	if @country = 6 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area and len(area) = 3 ) 			
		or
		( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )) 
	end

	if @country = 7 begin
		declare @phoneTemp as varchar(10)
		select @phoneTemp = right ( @phone, 10 )
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea 
		where id_country = @country and (
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,2) = area ) 
		) 
	end

	if @country = 8 begin		
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea 
		where id_country = @country and (
		(len(@phone) = 7 and @lada = area) or
		(len(@phone) = 9 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 10 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 11 and substring(@phone, 2, 1) = area)) 
	end

	return isNull(@timeZone,0)
 END'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita
if @country = 1 
 begin
	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045''))
		 begin
			set @value = 4
		 end 
	 end	
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			 end
		 end
	 end
 end
	
-- Argentina
if @country = 2 
 begin
	--Restringe celulares
	if ((@mask & 1) > 0)
	 begin			
		if (left(@tel,2)=''15'') or (len(@tel)>=13 and substring(@tel,1,1)=''0'' and 
			(substring(@tel,4,2)=''15'' or substring(@tel,5,2)=''15'' or substring(@tel,3,2)=''15''))
		 begin
			set @value = 4
		 end 
	 end
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ((left(ltrim(rtrim(@tel)),2) = ''0'') and len(ltrim(rtrim(@tel))) = 11)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask&4)>0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value=6
			 end
		 end
	 end
 end

if @country = 3 --Colombia
 begin
	--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) > 8
		 begin
			set @value = 4
		 end 
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) = 8 or left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
			 begin
				set @value = 6
			 end
		 end
	 end
 end

if @country = 4 --USA
 begin
	--Restringe larga distancia usa
	if ((@mask & 2) > 0)
	 begin
		if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = ''1'')
		 begin
			set @value = 5
		 end
	 end

	--Restringe locales usa
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			--if Len(ltrim(rtrim(@tel))) = 7
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			end
		 end
	 end
 end

--Chile
if @country = 5 
 begin

		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) >= 10 and left(@tel,2) = ''09''
		 begin
			set @value = 4
		 end 
	 end

		--Restringe Locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin				
			if Len(@tel) in (6,7)
			 begin
				set @value = 6
			 end
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 8 and len(@tel) < 10
			 begin
				set @value = 5
			 end
		 end
	 end
 end

--Venezuela
if @country = 6
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) >= 10 and left(@tel,2) = ''04''
		 begin
			set @value = 4
		 end 
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 10 and left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			 end
		 end
	 end

end

--United Kingdom
if @country = 7
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if (len(@tel) >= 9) and left(@tel,2) = ''07''
		 begin
			set @value = 4
		 end 
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 9 and left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			if len(@tel) >= 9 and left(@tel,1) <> ''0''
			 begin
				set @value = 6
			 end
		 end
	 end

end

--arabia saudita
if @country = 8
begin
	
	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if (left(ltrim(rtrim(@tel)),2) = ''05'' and len(ltrim(rtrim(@tel))) = 10 )
		 begin
			set @value = 4
		 end 
	 end	
	
	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''05'' and len(ltrim(rtrim(@tel))) in (11, 9))
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
			 begin
				set @value = 6
			 end
		 end
	 end
end

select @value'
		EXEC(@Sql)

			set @Sql = 'ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
RETURNS varchar(30) AS  
begin
declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint
select @resultado=dbo.Completa(@Cadena)

select @ld=valor from ccSettings where setting_id=17
select @pais = valor from ccsettings where setting_id = 104
select @BLActivo = valor from ccsettings where setting_id = 114

if @BLActivo = 1 begin
	if @pais in (1,4)
	 begin
		if left(@resultado, 1)=''E''
			return @resultado

		select @resultado = case
		 when len(@resultado)in(7,8) then @ld + @resultado
		 when @resultado=''911'' OR len(@resultado)=10 then @resultado
		 when len(@resultado) in (11,12,13) then right(@resultado,10)
		 else ''E_NV_Longitud''
		 end

		 return @resultado
	 end
		
	if @pais = 2 
	 begin
		select @resultado = dbo.fnClearPhoneArg(@cadena)
		return @resultado
	 end

	if @pais = 3 and left(@resultado,1) <> ''E'' 
	 begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) in(8,10) then @resultado
			when len(@resultado) = 11 then right(@resultado,10) 
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 5 and left(@resultado,1) <> ''E'' 
	 begin
		select @resultado = case
			when len(@resultado) in (6,7) then @ld + @resultado
			when len(@resultado) in (8,9) then @resultado
			when len(@resultado) = 10 then right(@resultado,9)
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 6 and left(@resultado,1) <> ''E''
	begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) = 10 then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado	
	end

	if @pais = 7 and left(@resultado,1) <> ''E''
	begin
		select @resultado = right(@resultado,10)
		return @resultado
	end

	if @pais = 8
	begin
		if left(@resultado,1) = ''E''
		begin
			return @resultado
		end
		select @resultado = case
			when len(@resultado) = 7 then ''0'' + @ld + @resultado
			when len(@resultado) = 9 and substring(@resultado,1,1) = ''0'' then @resultado
			when len(@resultado) = 10 and substring(@resultado,2,1) = ''5'' then @resultado
			when len(@resultado) = 11 and substring(@resultado,3,3) in (''111'',''510'',''511'') then @resultado
			else ''E_NV_Longitud'' end
		return @resultado	
	end

end
else begin
 select @resultado = dbo.Limpia(@cadena)
end 

return @resultado
end'
		EXEC(@Sql)

			set @Sql = 'ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS  
 BEGIN
	declare @ld varchar(7)
	declare @lon tinyint
	declare @result tinyint
	declare @mod varchar(10)
	declare @Cadena varchar(32)
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select  @cldLocal = valor from ccsettings where setting_id = 17
	select @tel = dbo.limpia(@tel)

	select @pais = valor from ccSettings where setting_id = 104

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon between 7 and 8 begin
			set @tel = @cldLocal + @tel
		end
		select @tel = right(@tel, 10)
		select @lon = len(@tel)

		if @lon = 10 begin
			select @ld = case when left(@tel, 2) in (''55'', ''33'', ''81'') then left(@tel, 2) else left(@tel, 3) end
			
			select @mod = modalidad from series where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]
			
			select @tel = case 
				when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
				else ''E_'' + @tel
			end
		end else begin
			if @lon > 0 begin
				select @tel = ''E_'' + @tel
			end	
		end
		return @tel
	end --Termina Mexico

	-- Empieza Argentina
	if @pais = 2 begin 
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin return @tel end
		select @lon = len(@tel)
		if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
			set @tel = @cldLocal + @tel
		end

		if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
			set @tel = @cldLocal + substring(@tel,3,@lon - 2)
		end

		--Buscamos el 15
		if @lon = 13 begin
			declare @index as int
			select @index = charindex(''15'',@tel)		
			--El unico caso en el que la lada tiene un 15 es con lada 3715
			if @index < 2 begin
				select @tel = ''E_'' + @tel						
				return @tel
			end
			else begin
				if substring(@tel,@index-2,4) = ''3715''
					begin
						select @ld = ''3715''
						set @tel = @ld + right(@tel,6)
					end
				else
					begin						
						select @ld = substring(@tel,2,@index-2)				
						set @tel = @ld + right(@tel,13 - (@index + 1))
					end
			end
		end

		select @tel = right(@tel, 10)

		if len(@tel) = 10 begin
			declare @serie as varchar(5)	
			begin 
				-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				declare @contLD as int
				declare @cont as int
				set @contLD=4
					BuscaLada:
					if isnull(@ld,'''') = '''' and @contLD >= 2
						begin					
							select @ld = cld from seriesArg where cld=left(@tel,@contLD)
							if isnull(@ld,'''') = '''' begin						
								set @contLD = @contLD - 1
								goto BuscaLada
							end
						end
					else begin
							if isnull(@ld,'''') = '''' begin
								select @tel = ''E_'' + @tel						
							end 
					end
			end

			-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
			begin
			if len(@ld) = 2 begin
					set @cont = 5
					buscaSerie2:
					if isnull(@serie,'''') = '''' and @cont >= 4 begin				
						select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)				
						if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
					end			
			end
			else begin
				if len(@ld) = 3 begin
					set @cont = 4
					buscaSerie3:
					if isnull(@serie,'''') = '''' and @cont >= 3 begin
						select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
						if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
					end			
				end		
				else begin
					if len(@ld) = 4 begin
						set @cont = 3
						buscaSerie4:
						if isnull(@serie,'''') = '''' and @cont >= 2 begin
							select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
							if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
						end			
					end					
				end
			end		
					
			end
			
			select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]		
			
			-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
			--select @ld,@serie,@mod,@contLD
			if isNull(@serie,'''') = '''' and @contLD>1 begin		
			set @contLD = len(@ld) - 1
			set @ld = null
			goto buscaLada
			end	

			select @tel = case 
				when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
				else ''E_'' + @tel
			end
		end else begin
			if len(@tel) > 0 begin
				select @tel = ''E_'' + @tel
			end	
		end
		return @tel
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin
			return @tel
		end

		if len(@tel) not in (7,8,10,11) begin
			return ''E_'' + @tel		
		end
				
		if len(@tel) = 7 begin		
			if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end
		end	

		if len(@tel) = 8 begin
			if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end		
		end

		if len(@tel) = 10 begin
			if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end		
		end

		if len(@tel) = 11 begin
			if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end		
		end
	end  --Termina Colombia

	-- Empieza Chile
	if @pais = 5 begin
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin
			return @tel
		end

		if len(@tel) = 6 and len(@cldLocal) = 2 begin
			if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
				return @tel
			end
			else begin return ''E_'' + @tel end
		end
		
		if len(@tel) = 7 begin
			if @cldLocal in (2,41,44,32) begin
				if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
				else begin
					if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
				end
			end
		end

		if len(@tel) = 8 begin
			if left(@tel,1) = ''2'' begin
					if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
					else begin
						if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end					
						else begin return ''E_'' + @tel end			
					end
			end
			else begin
				return @tel
			end
		end

		if len(@tel) = 10 begin
			if left(@tel,2) = ''09'' begin
				if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
					return @tel
				end
				else begin
					return ''E_'' + @tel
				end
			end

		end
	end
	--Termina Chile

	if @pais = 6 begin --Empieza Venezuela
		select @lon = len(@tel)
		if @lon = 7  begin
			set @tel = @cldLocal + @tel
		end

		select @tel = right(@tel, 10)

		if len(@tel) = 10 begin
			select @ld = left(@tel,3)
			select @mod = tipo from seriesVen where left(@tel,3) = LD	

			if @mod = ''CPP'' begin
				if exists( select * from seriesVen where LD = @ld ) begin
					if @ld = @cldLocal begin
						select @tel = right(@tel,7)
					end
					else begin
						select @tel = ''0'' + @tel
					end
				end
				else begin
					select @tel = ''E_'' + @tel
				end
			end
			else begin
				if @mod = ''FIJO'' begin
					if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
						if @ld = @cldLocal begin
							select @tel = right(@tel,7)
						end
						else begin
							select @tel = ''0'' + @tel
						end
					end
					else begin
						select @tel = ''E_'' + @tel
					end
				end 
				else begin
					select @tel = ''E_'' + @tel
				end	
			end
		end 
		else begin
			if len(@tel) > 0 begin
				select @tel = ''E_'' + @tel
			end	
		end
		return @tel
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @tel = dbo.completa(@tel)
		if left(@tel, 1) = ''E'' begin -- regresa error por longitud
			return @tel
		end
		select @lon = len(@tel)

		--numeros no geograficos
		if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
			return ''E_'' + @tel --error por longitud con lada correcta
		end
		else begin
			if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
				return @tel; --longitud correcta y numero no geografico
			end
		end

		--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
		if (left(@tel, 7) in(''0159575'', ''0159576'')) or
			(left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890'',''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
			(left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
			(left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
			return @tel;
		end

		--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
		if left(@tel, 2) = ''01'' begin
			select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
			if @ld > 0 begin
				return @tel;
			end
			else begin
				select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
				if @ld > 0 begin
					return @tel;
				end
			end
		end --si no encontro ni error ni coincidencia entonces esta mal
		return ''E_'' + @tel
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @tel = dbo.completa(@tel)
		select @lon = len(@tel)
		if @lon = 7 begin
			set @tel = ''0'' + @cldLocal + @tel
		end
		select @lon = len(@tel)

		if @lon = 9 begin
			if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
				if (substring(@tel,2,1) = @cldLocal)
				begin
					return right(@tel,7)
				end else begin
					return @tel
				end	
			end		
			else begin
				return ''E_'' + @tel
			end
		end
		if @lon = 10 begin
			if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end
		end
		if @lon = 11 begin
			if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
				return @tel	
			end		
			else begin
				return ''E_'' + @tel
			end
		end  
	end --Termina Arabia Saudita

	return @tel
 end'
		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(30),
@Camp int = 0
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint 
select @tel = dbo.limpia(@tel)
select @lon = len(@tel)
select @ld = valor from ccsettings where setting_id = 17
select @pais = valor from ccsettings where setting_id = 104
select @extLen = valor from ccsettings where setting_id = 108
declare @telTemp as varchar(15)

if @extLen=@lon and @lon>1
 begin
	select 0 as res, @tel as tel -- Extension
	return(0)
 end	
	
if @pais = 1 
 begin
	if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
	 begin
		select 1 as res, @tel as tel --Longitud invalida
		return(0)
	 end

	if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
	 begin
		select 2 as res, @tel as tel--Digitos incorrectos
		return(0)
	 end

	if left(@tel, 3) = ''001'' 
	 begin
		select 0 as res, @tel as tel
		return(0)
	 end

	declare @mod varchar(5)
	select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
	select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

	if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
	on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	 begin
		select 4 as res, @tel as tel
		return(0)
	 end 

	if @mod = ''CPP'' 
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
		return(0)
	 end

	if @mod in (''FIJO'', ''MPP'') 
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
		return(0)
	 end

	--if @mod is null 
	select 3 as res, @tel as tel--No encontrado					
	return(0)
 end

if @pais = 2 
 begin	
	select @telTemp = @tel
	set @tel = dbo.completa(@tel)
	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return
	end

	select @tel = dbo.fnClearPhoneArg(@tel)

	if len(@tel) = 10 and left(@tel,1) <> ''E'' begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	   begin				
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end else begin
			select 4 as res, @tel
			return(0)
		end
	end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos 
 end

if @pais = 3 
 begin
	select @telTemp = @tel
	if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	end
	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 4 and (select valor from ccsettings where setting_id = 27) = 1
 begin
	exec ccsp_LimpiaUsa @tel, @Camp
	return(0)
 end

if @pais = 5 
 begin	
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if len(@tel) in(8,9) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 6
 begin
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)


	if len(@tel) = 10 and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 7
 begin	
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end


if @pais = 8
 begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)

	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return (0)
	end

	if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
	begin
		if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		begin
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end
		else 
		begin
			select 4 as res, @tel
			return(0)
		end
	end
 end

set nocount off'
		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@IdAniLista as smallint = NULL,
@cld as varchar(40)= NULL,
@AniTel as varchar(40)= NULL,
@edo as varchar(40) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = ''select distinct '' + case @type when 1 then
case @pais	when 1 then ''estado, cld as area '' 
			when 2 then ''estado, cld as area ''
			when 3 then ''municipio as estado, region +''''+ serie as area ''
			when 4 then ''location as estado, area ''
			when 5 then ''cld as estado, cld as area ''
			when 6 then ''region as estado, LD as area ''
			when 7 then ''region as estado, CLD as area ''
			when 8 then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area '' 
			else '''' end
when 4 then
case @pais	when 1 then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 2 then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 3 then ''municipio as estado, region +''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 4 then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
			when 5 then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 6 then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani '' 
			when 7 then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani''
			when 8 then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani '' 
			else '''' end end + ''from '' +
case @pais	when 1 then ''series'' 
			when 2 then ''seriesarg where estado <> '''' order by 1'' 
			when 3 then ''seriescol'' 
			when 4 then ''ccTimeZoneArea where id_country = '' + convert(varchar(5),@pais) + '''' 
			when 5 then ''serieschi''
			when 6 then	''SeriesVen''
			when 7 then	''SeriesUK''
			when 8 then ''SeriesSA'' 
			else '''' end + ''''

if @type = 1 

begin
	exec(@listEdos + '' order by estado'')
	--print(@listEdos + '' order by estado'')
	return(0)
end

if @type = 2 
begin
	select @sql = ''select id_AniList, description from ccEdoAniList where idArea = '' + convert(varchar(5),@idArea) +  case when isnull(@IdAniLista,'''') <> '''' then '' and id_AniList = '' + convert(varchar(5),@IdAniLista) else '''' end
	exec(@sql) 
	return(0)
end

if @type = 3 
begin
	select @sql = ''select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = '' + convert(varchar(5),@IdAniLista) + '' and estado like ''''%'' + @edo + ''%'''' and telani <> '''''''' and id_AniList in (select id_AniList from ccEdoAniList where idArea 
= '' +
	 convert(varchar(5),@idArea) + '') order by estado''
	exec(@sql)
	--print(@sql) 
	return(0)
end

if @type = 4 
begin  --insert new aniList
	if @descriptionList <> '''' begin
		if exists(select * from dbo.ccEdoAniList where [description] = @descriptionList )
		 begin
			--raiserror(''ERROR. invalid ID'', 18, 1)
			select 1 
			return(0)
		 end 
		insert into ccEdoAniList values(@descriptionList, @idArea)
		select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
		set @listEdos = ''insert into ccEstadosAni (estado, area, id_anilist, telani) '' + @listEdos
		set @listEdos = replace(@listEdos, ''@id_anilist'', convert(varchar(6),@idLista))
		exec(@listEdos)
		--print(@listEdos)
	end
	return(0)
end

if @type = 5 
begin --update ccEstadosAni
	if not exists(select * from dbo.ccEstadosAni WHERE id_anilist = @IdAniLista and area = @cld )
	 begin
		--raiserror(''ERROR. invalid ID'', 18, 1) 
		select 1
		return(0)
	 end 

	update ccEstadosAni set telani= ISNULL(@AniTel, TELANI) WHERE id_anilist = @IdAniLista and area = @cld
	if @@rowcount>0
		select 0 id, [description]+''(Ld:''+cast(@cld as varchar(10))+'')'' [description] from ccEdoAniList WHERE id_anilist = @IdAniLista
	return(0)
end

if @type = 6 
begin --borra listas
	if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea )
	 begin
		select 1
		return(0)
	 end 

	select @descriptionList=[description] from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea
	delete from ccEstadosAni where id_anilist = @IdAniLista
	delete from ccEdoAniList WHERE id_anilist = @IdAniLista 
	
	if @@rowcount>0
		select 0 id, @descriptionList descriptionList
	return(0)
end'
		EXEC(@Sql)

			set @Sql = 'ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
RETURNS varchar(32) 
AS  
BEGIN
--declare @edo varchar(250)
declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)

select  @cldLocal = valor from ccsettings where setting_id = 17
select @pais = valor, @ret = '''' from ccSettings where setting_id = 104

	if @lista = 0 begin
		select @tel = ''''
	end

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 8 and @cldlocal = area and len(area) = 2 ) 
				or
				( len(@tel) = 7 and @cldlocal = area and len(area) = 3 )
				or
				( len(@tel) >= 10 and left(right(@tel, 10), 3) = area and len(area) = 3 )
				or
				( len(@tel) >= 10 and left(right(@tel, 10), 2) = area and len(area) = 2 ))
		end
		else begin	
			select @tel = ''''
		end

		return @tel
	end --Termina Mexico

	if @pais = 2 begin  -- Empieza Argentina
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @tel = telAni from ccEstadosAni where id_anilist = @lista and
							(( @lon = 6 and left(@tel,4) = area and len(area) = 4 )
							or
							( @lon = 7 and left(@tel,4) = area and len(area) = 3 )
							or
							( @lon = 8 and left(@tel,4) = area and len(area) = 2 )
							or
							( @lon = 11 and substring(@tel, 2, 2) = area and len(area) = 2 )
							or
							( @lon = 11 and substring(@tel, 2, 3) = area and len(area) = 3 )
							or
							( @lon = 11 and substring(@tel, 2, 4) = area and len(area) = 4 )		
							or
							( @lon = 13 and substring(@tel, 2, 2) = area and len(area) = 2 )
							or	
							( @lon = 13 and substring(@tel, 2, 3) = area and len(area) = 3 )	
							or
							( @lon = 13 and substring(@tel, 2, 4) = area and len(area) = 4 ))	
		end
		else begin	
			select @tel = ''''
		end
			return @tel
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin	
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(( len(@tel) = 7 and @cldlocal = area ) 
				or
				( len(@tel) = 8 and left(@tel,5) = area ) 
				or
				( len(@tel) in(10,11) and (left(@tel,1) = ''3'' or substring(@tel,2,1) = ''3'')))
		end
		else begin	
			select @tel = ''''
		end
		return @tel
	end  --Termina Colombia

	if @pais = 4 begin --Empieza USA
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			if @lon = 7 begin
				set @tel = @cldLocal + @tel
			end
			set @tel = right(@tel, 10)
			--select @edo = location from ccTimeZoneAreaUsa where area = left(@tel,3) 
			select @tel = telani from ccEstadosAni where area = left(@tel,3) and id_anilist = @lista
		end
		else begin	
			select @tel = ''''
		end
		return @tel
	end --Termina USA

	if @pais = 5 begin -- Empieza Chile
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 6 and @cldlocal = area ) 
			or
			( len(@tel) = 7 and @cldlocal = area ) 
			or
			( len(@tel) = 8 and left(@tel,1) = area ) 
			or
			( len(@tel) = 8 and left(@tel,2) = area ) 
			or
			( len(@tel) = 9 and left(@tel,2) = area ) 
			or
			( len(@tel) = 10 and substring(@tel,3,1) = area and left(@tel,2) = ''09'' ))
		end
		else begin	
			select @tel = ''''
		end
		return @tel
	end --Termina Chile

	if @pais = 6 begin -- Venezuela
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=11 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and 
				(len(@tel) = 7 and left(@tel,3) = area or
				len(@tel) = 11 and substring(@tel,2,3) = area)
		end
		else begin	
			select @tel = ''''
		end

		return @tel
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @lon = len(@tel)
		if left(@tel,1) = ''0'' begin
			set  @tel = substring(@tel,2,(len(@tel)-1))
		end

		if @lon >= 9 and @lon <=11 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 10 and substring(@tel,1,5) = area ) 
			or
			( len(@tel) = 10 and substring(@tel,1,4) = area ) 
			or
			( len(@tel) = 10 and substring(@tel,1,3) = area ) 
			or
			( len(@tel) = 10 and substring(@tel,1,2) = area ) 
			or
			( len(@tel) = 9 and substring(@tel,1,5) = area ) 
			or
			( len(@tel) = 9 and substring(@tel,1,4) = area ) )	
		end
		else begin	
			select @tel = ''''
		end
		return @tel
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and 
				(len(@tel) = 7 and ''0''+@cldlocal + ''-''+ substring(@tel,1,1) + ''00'' = area or
				len(@tel) = 9 and substring(@tel,1,3) + ''00'' = replace(area,''-'','''') or
				len(@tel) = 10 and substring(@tel,1,4) + ''00'' = replace(area,''-'','''') or
				len(@tel) = 11 and substring(@tel,1,4)+ ''0'' = replace(area,''-'','''') or
				len(@tel) = 11 and substring(@tel,1,5) = replace(area,''-'',''''))
		end
		else begin	
			select @tel = ''''
		end

		return @tel
	end --Termina Arabia Saudita

	return @ret
END'
		EXEC(@Sql)


			set @Sql = 'update ccmenus set menu_descrip = ''Gestión de grupos de trabajo|Work Group Management''  where menu_id = 4'
		EXEC(@Sql)

			set @Sql = '--------------------------------------------------se agrega a la tabla ccriacat_country 
insert into ccriacat_country (CtyName, CtyCode, minPhoneLength, maxPhoneLength) values (''United Kingdom'',1,10,13)
insert into ccriacat_country (CtyName, CtyCode, minPhoneLength, maxPhoneLength) values (''Saudi Arabia'',996,7,13)'
		EXEC(@Sql)

			set @Sql = 'insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (3220, ''Sub Calificaciones|Call SubDisposition'',3000,''B'',3,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (4190, ''Sub Calificaciones|Call SubDisposition'',4000,''B'',4,2,'''')

insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (6000, ''IVR|IVR'',6000,''A'',6,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (6010, ''Detalle de IVR|IVR Detail'',6000,''B'',6,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (6020, ''IVR General|IVR General'',6000,''B'',6,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (6030, ''Primera opcion del menu|First optionselected'',6000,''B'',6,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (6040, ''Por Opciones|By Options'',6000,''B'',6,2,'''')


insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (8000, ''General|General'',8000,''A'',8,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (8010, ''Ocupacion de puertos|Trunk`s busy'',8000,''B'',8,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (8020, ''Ocupacion de puertos outbound|Outbound Trunk`sbusy'',8000,''B'',8,2,'''')
insert into ccmenus (menu_id,menu_descrip,parent, Nivel, ordengral,type,helpswf) values (8030, ''Ocupacion de puertos inbound|Inbound Trunks busy'',8000,''B'',8,2,'''')'
		EXEC(@Sql)

	set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetAllInfoEspecNew]
@User_id as smallint
AS
set nocount on
-- declare @tresDialog int
-- exec @tresDialog = ccspConfigTresDialog

select a.inbound_id, calls = ISNULL(count(*), 0), -- calls
abandon = isnull(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
OverFlowQueue = ISNULL(count (case when statusCall_id =8 then 1 else null end), 0),
OverFlowTimeOut = ISNULL(count (case when statusCall_id =7 then 1 else null end), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
Dialogs = ISNULL(count (case when statusCall_id = 13 then 1 else null end), 0), -- Answered
DlgsAveTime= ISNULL(sum (case when statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
QueueAveTime=ISNULL( avg( case when cal_que > 0 then cal_tWait else null end), 0) ,
another=0, --ISNULL(count (case when statusCall_id in(2, 3, 4, 11, 15, 16) then 1 else null end), 0), -- others
outOfSchedule=ISNULL(count (case when statusCall_id =2 then 1 else null end), 0), -- fuera de horario
outOfService=ISNULL(count (case when statusCall_id =3 then 1 else null end), 0), -- fuera de servicio
noAgentsLoggedIn=ISNULL(count (case when statusCall_id =4 then 1 else null end), 0), -- sin agentes firmados
assigned=ISNULL(count (case when statusCall_id =11 then 1 else null end), 0), -- asignada
assignedAndNotAnswered=ISNULL(count (case when statusCall_id =15 then 1 else null end), 0), -- asignada y no contestada
assignedAndTookLine=ISNULL(count (case when statusCall_id =16 then 1 else null end), 0), -- asignada y toma linea
shortCalls=0 --ISNULL(sum(case when cal_tDialog < @tresDialog then 1 else 0 end), 0)
from ccCallsIn a 
where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
group by a.inbound_id
set nocount off
return(0)'
		EXEC(@Sql)

	set @Sql = 'ALTER procEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
@cal_id int,
@cal_tIVRCallDuration smallint,
@statuscal_id tinyint, 
-- Aqui solo se Aceptan Edos Terminales 2(Fuera de Horario), 3(Fuera de Servicio), 4(NoAgentesFirmados), 7(TimeOut), 8(DesbordeQue),
@cal_opciones varchar(10),
@cal_colgada tinyint,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on

Update ccCallsIn SET statusCall_id = case when @statuscal_id in (2, 3, 4, 7, 8) then @statuscal_id else case when statusCall_id = 5 then 6 else statuscall_id end end, 
 user_id=@User_id, cal_extension=@cal_extension, cal_tWait=@tWait where cal_id=@cal_id

exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id

set nocount off'
		EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
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
