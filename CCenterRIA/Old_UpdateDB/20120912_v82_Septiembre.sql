/*
Autor: Raymundo González
Fecha: 2012/09/12
Descripcion: 
	Se eliminan los espacios en blanco de las columnas de telefonos en las tablas ccoCallsOutSource, ccoCallsOut, ccoCallBacks
	Se agrega columna callerIdDesc y coloca string en blanco en las tablas ccCamps y ccInbound
	Se elimina el menu de reportes de hold de la ventana de permisos de administrador
	Se actualizan los campos value y target de la tabla ccrialog para aceptar 250 caracteres
	Se crea el SP AgentCheckCamps para validar si la campaña tiene permisos para marcacion manual
	Se modifica el SP ccsp_RIAUpdateCamConfig para agregar parametro callerIdDesc para configuracion
	Se modifica el SP ccsp_RIAConfCamp para devolver el nuevo campo callerIdDesc para XML de configuracion
	Se modifica el SP ccsp_RIAUpdateEspecConfig para agregar parametro callerIdDesc para configuracion
	Se modifica el SP ccsp_RIAConfEspec para devolver el nuevo campo callerIdDesc para XML de configuracion
	Se modifica el SP ccsp_DLRgetDialPrefix para devolver callerId configurado para campañas y ACDs
	Se modifica el SP ccsp_RIAGetAllInfoEspecNew para agregar el campo de onQueue para obtener las llamadas que están en espera cuando se loguea el administrador
	Se modifica el SP ccsp_RIA_ABCLog para recibir los parametros value y target con hasta 250 caracteres

Version requerida: 81
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '82'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

			set @Sql = 'alter table cccamps
add callerIdDesc varchar(15) null default ''''

alter table ccInbound
add callerIdDesc varchar(15) null default ''''

DELETE FROM ccMenus 
WHERE menu_id = 2090

alter table ccrialog
alter column [value] varchar(250) NOT NULL

alter table ccrialog
alter column [target] varchar(250) NOT NULL'

		EXEC(@Sql)

			set @Sql = 'update cccamps
set callerIdDesc = ''''
where callerIdDesc is NULL

update ccInbound
set callerIdDesc = ''''
where callerIdDesc is NULL'

		EXEC(@Sql)

			set @Sql = 'CREATE PROCEDURE [dbo].[AgentCheckCamps]
@cam_id as smallint,
@user_id as smallint,
@forceManualCall as tinyint = 0
AS

declare @isValidCall as int

select @isValidCall = count(*) from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id

if @isValidCall <> 0 and @forceManualCall = 0 begin
	select @isValidCall = cam_ModoManual from ccCamps with(nolock) where cam_id = @cam_id
end

select @isValidCall as Validation'

		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null, 
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null, 
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null, 
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null
as
set nocount on
UPDATE ccCamps SET 
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial), 
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine), 
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc)
Where cam_id = @cam_id 

if @cam_ShowCalifWnd = 1
 begin
	If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
	 begin
		select 0
		return(0)
	 end
	 
	UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
	where cam_id = @cam_id
	select 1
	return(0)
  end

--else
UPDATE ccCamps SET 
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint 
AS 
set nocount on
	select a1.cam_id, cam_Descripcion
	 , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
	 , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
	 , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
	 , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
	 , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
	 , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
	 DNCScrub, callerIdDesc
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint,
@descripcion varchar(50) = null,
@Status tinyint = null,
@tNotas int = null,
@tMaxWaitCall int = null,
@nMaxQue int = null,
@tel_maxwait varchar(15) = null,
@tel_MaxQueue varchar(15) = null,
@tel_outservice varchar(15) = null,
@tel_noct varchar(15) = null,
@ShowCalifWnd bit = null,
@StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@queuePosition bit = null, 
@tMaxQueueCallBack smallint = null,
@stopRecording bit = null,
@dialPrefixOverflow varchar(10) = null,
@OpriorityT smallint= null,
@callerIdDesc varchar(15)=null
as
set nocount on
UPDATE ccInbound SET 
 descripcion = isnull(@descripcion,descripcion),
 Status = isnull(@status,status),
 tNotas = isnull(@tNotas,tNotas),
 tMaxWaitCall = isnull(@tMaxWaitCall,tMaxWaitCall),
 nMaxQue = isnull(@nMaxQue,nMaxQue),
 tel_maxwait = isnull(@tel_maxwait,tel_maxwait),
 tel_MaxQueue = isnull(@tel_MaxQueue,tel_MaxQueue),
 tel_outservice = isnull(@tel_outservice,tel_outservice),
 tel_noct = isnull(@tel_noct,tel_noct),
 bnocturno = case when isnull(@tel_noct,''0'')=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
 StartTimerOnHangUp = isnull(@StartTimerOnHangUp,StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey,editableCallKey),
 queuePosition = isnull(@queuePosition,queuePosition),
 tMaxQueueCallBack = isnull(@tMaxQueueCallBack,tMaxQueueCallBack),
 stopRecording = isnull(@stopRecording, stopRecording),
 dialPrefixOverflow = isnull(@dialPrefixOverflow, dialPrefixOverflow),
 OpriorityT = isnull(@OpriorityT, OpriorityT),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc)
where inbound_id = @inbound_id

if @ShowCalifWnd = 1
 begin
	If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
	 begin
		UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
		where inbound_id = @inbound_id
		select 1
		return(0)
	 end

	select 0
	return(0)
 end

else
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
	where inbound_id = @inbound_id
	return(0)
set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER procEDURE [dbo].[ccsp_RIAConfEspec] 
@User_id int 
AS 
set nocount on
	select inbound_id, Descripcion, Status, tNotas,
	 tMaxWaitCall, nMaxQue,tel_maxwait, tel_MaxQueue, tel_outservice, tel_noct, ShowCalifWnd, 
	 StartTimerOnHangUp, editableCallKey, queuePosition, tMaxQueueCallBack, stopRecording, dialPrefixOverflow,OpriorityT, callerIdDesc
	 from ccInbound 
	 where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 2))
	 return(0)
set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = '''',
@typecall tinyint = null,
@inboundId smallint = 0
as
set nocount on
declare @prefix as varchar(15), @prefixdialer as varchar(15), @prefixUse tinyint, @lista_id smallint, @ani varchar(32), @ani2 varchar(32)
declare @tNoContesta as smallint	
select @prefix = valor from ccsettings where setting_id = 101
select @prefixUse = valor from ccsettings where setting_id = 102 
set @prefixUse=isnull(@prefixUse,''15'')
select @lista_id = isnull(id_anilist,''0''), @ani2 = ani from ccCamps where cam_id = @cam_id

declare @callerIdDesc varchar(15)	
set @callerIdDesc = ''''

if not exists(select cam_id from cccamps where cam_id=@cam_id)
 begin
	--Cuando la campaña es 0, por lo general es una transferencia, se saca el tiempo de marcado configurado en ccSettings
	select @tNoContesta = valor from ccSettings where setting_id = 109

	if exists(select inbound_id from ccInbound where inbound_id=@inboundId)
		select @callerIdDesc = isnull(callerIdDesc,'''') from ccInbound where inbound_id=@inboundId
	
	select isnull(@prefix,'''') sDialPrefix, isnull(@tNoContesta,24) tNoContesta, '''' ani, ''0'' detectAnswerMachine, ''1'' detectVoiceMail, @prefixUse PrefixUse, @phone phone, 0 as stopRecording, @callerIdDesc as callerIdDesc	
	return(0)
 end

select @prefixdialer = case prefix when '''' then isnull(@prefixdialer,'''') else prefix end from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

if isnull(@prefixdialer,'''') = '''' or isnull(@prefixdialer,'' '') = '' ''
begin
	if @typecall = 2 and exists (select dialPrefixMan from cccamps where cam_id=@cam_id)
	 begin
		select @prefix = case dialPrefixMan when '''' then isnull(@prefix,'''') else dialPrefixMan end, @prefixUse=@typecall, @callerIdDesc = isnull(callerIdDesc,'''') from ccCamps where cam_id = @cam_id
	 end

	if @typecall = 4 and exists (select dialPrefixXfe from cccamps where cam_id=@cam_id)
	 begin
		select @prefix = case dialPrefixXfe when '''' then isnull(@prefix,'''') else dialPrefixXfe end, @prefixUse=@typecall, @callerIdDesc = isnull(callerIdDesc,'''') from ccCamps where cam_id = @cam_id
	 end

	if @typecall = 8 and exists (select dialPrefixOverflow from ccInbound where Inbound_id=@cam_id)
	 begin
  		select @tNoContesta = valor from ccSettings where setting_id = 109
		select @prefix = case dialPrefixOverflow when '''' then isnull(@prefix,'''') else dialPrefixOverflow end, @prefixUse=@typecall, @callerIdDesc = isnull(callerIdDesc,'''') from ccInbound where Inbound_ID = @cam_id
	 end
end
else
begin
	select @prefix = @prefixdialer
end

select @ani = dbo.TelAni(@phone,@lista_id)

select @prefix as sDialPrefix, case when isnull(@tNoContesta,0) = 0 then isnull(cam_tNoContesta,24) else @tNoContesta end as tNoContesta, 
case when @ani <> '''' then @ani else isnull(ani,'''') end ani, 
isnull(detectAnswerMachine,0) detectAnswerMachine, isnull(detectVoiceMail,1) detectVoiceMail, @prefixUse PrefixUse, isnull(@phone,'''') phone, isnull(stopRecording,0) stopRecording, @callerIdDesc as callerIdDesc
from ccCamps where cam_id=@cam_id

set nocount off'

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
shortCalls=0, --ISNULL(sum(case when cal_tDialog < @tresDialog then 1 else 0 end), 0)
onQueue = isnull(count(case when statusCall_id = 5 then 1 else null end), 0)
from ccCallsIn a 
where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
group by a.inbound_id
set nocount off
return(0)'

		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIA_ABCLog]
@option tinyint,
@areaName varchar(50)=null,
@operationType tinyint = null,
@login varchar(20) = null,
@moduleId int=null,
@value varchar(250)=null,
@target varchar(250)=null,
@operationDateIni smalldatetime = null,
@operationDateFin smalldatetime = null,
@top int = 0
as
set nocount on

if @option=1 -- muestra todo
 begin
	select log_id, areaName, operationDate, operationType, login, module_id, value, target
	from ccRIALog with(nolock)
	return(0)
 end

if @option=2 -- insert
 begin
	declare @areaNameValue as varchar(50)
	set @areaNameValue = @areaName

	if (left(@areaName,1) = ''!'')
	 begin
		select @areaNameValue = areaName
		from dbo.ccRIACat_Areas AS AREAS WITH(NOLOCK)
		where AREAS.IDArea = right(@areaName,len(@areaName)-1)
	 end

	INSERT INTO ccRIALog VALUES(@areaNameValue, GETDATE(), @operationType, @login, @moduleId, @value, @target)
	return(0)
 end

declare @lang tinyint
select @lang = valor from ccsettings where setting_id=27

if @option=3 -- muestra información por filtros (System>Log) // Fechas
 begin
	set rowcount @top
	select L.log_id, L.areaName, L.operationDate, 
	case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
	 else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+1, len(o.descripcion)) END operationType, L.login, 
	case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
	 else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+1, len(m.descripcion)) END module_id, L.value, L.target
	from CCRIALOG L join ccRIALog_Module M with(index(IX_ccRIALog_Module)) on L.module_id = M.module_id join ccRIALog_Operation O with(index(IX_ccRIALog_Operation)) on L.operationType = O.operationType
	where L.operationType = case isnull(@operationType, 0) when 0 then L.operationType else @operationType end
	 and L.login = case isnull(@login, '''') when '''' then L.login else @login end
	 and L.module_id = case isnull(@moduleId, 0) when 0 then L.module_id else @moduleId end
	 and L.target = case isnull(@target, '''') when '''' then L.target else @target end
	 and L.operationDate >= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
		isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, -1, @operationDateIni) else L.operationDate end
	 and L.operationDate <= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
		isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, 1, @operationDateFin) else L.operationDate end
	order by L.operationDate desc
	return(0)
 end

if @option=4 -- Catalogo de modulos
 begin
	select m.module_id, o.operationType, 
	case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
	 else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+1, len(m.descripcion)) END as mDescripcion, 
	 case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
	 else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+1, len(o.descripcion)) END as oDescripcion
	from ccRIALog_Operation o with(index(IX_ccRIALog_Operation)) join ccRIALog_Cat_Relation r on o.operationType = r.operationType
	 join ccRIALog_Module m with(index(IX_ccRIALog_Module)) on r.module_id = m.module_id
	UNION
	select 0, -1, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END, ''-''
	UNION
	select 0, 0, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END
	UNION
	select module_id, 0, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion, 
	 case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END from ccRIALog_Module with(index(IX_ccRIALog_Module)) 
	UNION
	select module_id, -1, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion, ''-'' 
	 from ccRIALog_Module with(index(IX_ccRIALog_Module)) 	
    order by mDescripcion, oDescripcion
	return(0)
 end

if @option=5 -- Catalogo de operaciones
 begin
	select operationType, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+1, len(descripcion)) END as descripcion
	from ccRIALog_Operation with(index(IX_ccRIALog_Operation))
	union
	select 0, case @lang when 0 then ''-TODAS-'' else ''-ALL-'' END 
	order by 2
	return(0)
 end

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
