/*
Autor: Raymundo Gonzalez
Fecha: 2014/03/31
Descripcion:
	Se modifica la tabla ccLogReciclaje creando el indice IX_ccLogReciclaje_3 para mejora de performance
	Se modifica la tabla cccamps agregando la columna manualCallOnChat para habilitar llamada manual durante chat
	Se insertan registros en la tabla ccRIAUsr_AdminPermissions para fix de permisos de Administradores
	Se inserta registro en la tabla cctiposlistanegra para agregar lista negra por default
	Se inserta registro en la tabla ccsettings con el setting_id 152 para agregar lista negra por default
	Se inserta registro en la tabla ccmenus para fix en asignacion de menus
	Se inserta registro en la tabla ccRIACat_AdminPermissions para habilitar clicker
	Se modifica la tabla ccmenus actualizando registros para fix en asignacion de menus
	Se modifica la funcion EnableCallRecord para que en caso de no tener una condicion valida que revisar siga grabando
	Se modifica el SP ccsp_CheckAVRSIntegrated para fix de validacion de Administradores
	Se modifica el SP ccsp_RIAADMChecaLogin para fix de validacion de Administradores
	Se modifica el SP ccsp_RIACampsManualCall para habilitar llamada manual durante chat
	Se modifica el SP ccsp_RIAConfCamp para habilitar llamada manual durante chat
	Se modifica el SP ccsp_RIAUpdateCamConfig para habilitar llamada manual durante chat
	Se modifica el SP ccsp_DLRAfterXferAge para actualizacion
	Se modifica el SP ccsp_ExtAppsCallHistory para agregar detalle de calificaciones y subcalicaciones para WS
	Se modifica el SP ccsp_RIA_ABCCamps para agregar lista negra por default
	Se modifica el SP ccsp_RIACATBList para agregar lista negra por default
	Se modifica el SP ccsp_ExtAppsCamList para fix en WS
	Se modifica el SP ccsp_AgentUpdateCallCALIF para fix en callbacks automaticos
	Se modifica el SP ccsp_INInsertaCallBack para fix en callbacks automaticos
	Se modifica el SP ccsp_OUTInsertaCallBack para ix en callbacks automaticos
	Se modifica el SP ccsp_RIAUpdateCallBack_Abandon para fix en callbacks automaticos	
	Se modifica el SP ccsp_RIAMenuRoles para fix de permisos de Administradores	
	se modifica el SP ccsp_RIAccSettingsConfig para evitar error de carga del Administrador si esta mal configurado el pais o lenguaje poner valor default
	Se modifica el Job CW Delete old records para actualizacion
	Se modifica el Job NuxibaMaintenancePlan para actualizacion
	
Version requerida: 105
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '106'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'IX_ccLogReciclaje_3 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccLogReciclaje_3] ON [dbo].[ccLogReciclaje] 
(
	[fecha] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'cccamps - Alter Table'
		set @Sql='alter table cccamps
add manualCallOnChat bit not null default(0)'
	
	EXEC(@Sql)
	
		set @process = 'ccRIAUsr_AdminPermissions - Insert'
		set @Sql='insert into ccRIAUsr_AdminPermissions
select user_id, 6 as per_id  from ccUsers 
where user_id in (select user_id from ccUsers where TipoUser_id = 2) 
and user_id not in(select user_id from ccRIAUsr_AdminPermissions where per_id=6)'
	
	EXEC(@Sql)

		set @process = 'cctiposlistanegra - Insert'
		set @Sql='insert into cctiposlistanegra(TipoLista, Status) 
values(''defaultList/General'', 1)'
	
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert'
		set @Sql='insert into ccsettings(setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings)
values(152, ''0'', ''Asociar lista negra a campañas nuevas por defecto'', 1, ''ADM'', ''Si tiene el valor 1 asocia automáticamente la lista negra por defecto a cualquier campaña que se cree. Si tiene el valor 0 el comportamiento de la creación de campañas no se ve alterado'', ''Assign a DNCL to new campaigns by default'', 1)'
	
	EXEC(@Sql)

		set @process = 'ccMenus - Insert'
		set @Sql='insert into ccMenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (80,''Acerca de...|About'',0,''A'',71,1,'''')'
	
	EXEC(@Sql)
	
		set @process = 'ccRIACat_AdminPermissions - Insert'
		set @Sql = 'insert into ccRIACat_AdminPermissions (per_desc, bStatus)
values (''Habilitar Clicker|Enable Clicker'',1)'
		
	EXEC(@Sql)
	
		set @process = 'ccmenus - Update'
		set @Sql='update ccmenus set menu_descrip=''Formatos de calificacion|Scoring Templates'' where menu_id=74 and type=1
update ccmenus set menu_descrip=''Perfiles de exportacion|Export Profiles'' where menu_id=75 and type=1
update ccMenus set parent=2 where menu_id in(45,3,46,4,50,5,49,7,8,41,29,53,59,65) 
update ccMenus set parent=9 where menu_id in(10,11,12,13,14,15,47,54,58,63,70,77) 
update ccMenus set parent=16 where menu_id in(17,18,19,20,21,52,57,78,79) 
update ccMenus set parent=22 where menu_id in(23,24,26,27,44,48,62) 
update ccMenus set parent=32 where menu_id in(30,31,35,36,38,42,43,51,55,56,64,69,71,72) 
update ccMenus set parent=73 where menu_id in(74,75,76) 
update ccMenus set parent=80 where menu_id =40 
update ccMenus set parent=60 where menu_id =61'
	
	EXEC(@Sql)

		set @process = 'EnableCallRecord - Alter Function'
		set @Sql='ALTER function [dbo].[EnableCallRecord](@call_record_cam tinyint,@pais tinyint, @tel varchar(32))
RETURNS bit
AS  
BEGIN

declare @call_record as bit
set @call_record = 1

	if @pais = 4 begin --Empieza USA		
		-- grabar
		if @call_record_cam = 1 
			return 1
		-- no grabar
		if @call_record_cam=3  
			return 0
		-- grabar zonas permitidas
		if len(@tel) = 10
			select @call_record = isnull(call_record,1)  from ccTimeZoneArea where id_country= @pais and area = left(@tel,3)

		return @call_record
	end --Termina USA

	return 1
END'
	
	EXEC(@Sql)

		set @process = 'ccsp_CheckAVRSIntegrated - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_CheckAVRSIntegrated] 
@User_id smallint = 0
AS
Declare @valor tinyint
declare @ver int
set @ver = 0

if @User_id = 0 
begin
Select @valor=valor from ccSettings where setting_id = 124
Select @valor
end
else
begin
Select @valor=valor from ccSettings where setting_id = 124
if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@User_id and per_id in (2,6))
 begin
	set @ver = 1
 end

if (@valor=1 and @ver=1)
begin
 select 1
end
else
begin
 select 0
end
end'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAADMChecaLogin - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin]
@Login varchar(12) = '''',
@Password varchar(40) = '''',
@PasswordLwC varchar(40) = null,
@adminId int = 0

as
set nocount on

declare @x int
set @x=1

if @adminId <> 0
	begin
		update ccUsers set onLine = 0 where User_id = @adminId
		return(0)
	end

declare @UserID smallint
--****
declare @TipoUser_idx int
declare @ver int
declare @changeRecDisposition int
set @ver = 0
set @changeRecDisposition = 0

--****
select @UserID=User_id,@TipoUser_idx=TipoUser_id from ccUsers Where Login=@Login AND TipoUser_id in(2,6) and status>0

if(@TipoUser_idx=2 or @TipoUser_idx=6)
begin
 if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id in (2,6))
 begin
	set @ver = 1
 end
 if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id=7)
 begin
	set @changeRecDisposition = 1
 end
end

if not exists (select Login from ccUsers Where User_id=@UserID 
AND(Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
OR Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC))
 begin
	SELECT case when @UserID is null then 0 else 1 end ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId'', 0 ''viewavrs'',0 ''changeRecDisposition''
	return(0)
 end

update ccUsers set Password=isnull(@PasswordLwC, Password) Where User_id=@UserID and Password<>@PasswordLwC

update ccUsers set onLine = 1 where User_id = @UserID

Select 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'', 
 Nombres +'' ''+ isnull(ApellidoPaterno,'''') +'' ''+isnull(ApellidoMaterno,'''') ''Nombre'', 
 (SELECT valor FROM ccSettings WHERE setting_id=8) ''ADMServer'', 
  isnull(IDArea,0) ''AreaId'',
 @ver  ''ViewAvrs'', @changeRecDisposition  ''changeRecDisposition''
From ccUsers Where User_id=@UserID
return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIACampsManualCall - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
@UserID int,
@onChat int = 0
AS
set nocount on

if (@onChat = 0)
	select distinct c.cam_id, c.cam_descripcion 
	from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id 
	where ca.user_id = @UserID and cam_modoManual = 1 
	order by cam_descripcion
else
	select distinct c.cam_id, c.cam_descripcion 
	from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id 
	where ca.user_id = @UserID and manualCallOnChat = 1 
	order by cam_descripcion

set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAConfCamp - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
	 DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
     ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAUpdateCamConfig - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null
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
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat)
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
	
		set @process = 'ccsp_DLRAfterXferAge - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_DLRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7)
--@tWait smallint=0 --no se usa
AS
set nocount on
if @cal_id=0
 return(0)
		
Update ccoCallsOut SET user_id=@User_id, cal_extension=@cal_extension, statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 1

-- calcula el costo de la llamada
exec ccsp_CstoCalculaCosto @cal_id
return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_ExtAppsCallHistory - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(30) = null,
@endDate varchar(30) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,
@multipleUser_id as varchar(500) = null,
@agentId int = 0
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500
		cal_id as call_id,
		c.inbound_id,
		isnull(a.descripcion,'''') as acdGroup,
		cal_ani as phoneNumber,
		isnull(b.user_id,0) as [user_id],
		isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,
		d.descripcion as call_status,
		cal_tDialog as call_tDialog,
		cal_inicio as call_date,
		cal_tNotas as WrapUp,
		cal_tXfer as Xfer,
		cal_tRing as Ringing,
		cal_key as callKey,
		isnull(e.calif_id,'''') as dispositionId,
		isnull(f.califSubDesc,'''') as subDisposition,
		isnull(f.califSub_id,'''') as subDispositionId
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id) 
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
	where cal_id >= @call_id
 end

-- OUTBOUND x cal_id
if @action = 2 
 begin
	select top 500
		cal_id as call_id,
		c.cam_id,
		isnull(a.cam_descripcion,'''') as Campaign,
		c.cal_telefono as phoneNumber,
		isnull(b.user_id,0) as user_id,
		isnull(login,''''),
		isnull(e.description,'''') as disposition,
		d.descripcion as call_status,
		cal_tDialog as call_tDialog,
		cal_inicio as call_date,
		cal_tNotas as WrapUp,
		cal_tXfer as Xfer,
		cal_tRing as Ringing,
		cal_manual as CallManual,
		c.cal_key as callKey,
		list_id,
		isnull(e.calif_id,'''') as dispositionId,
		isnull(f.califSubDesc,'''') as subDisposition,
		isnull(f.califSub_id,'''') as subDispositionId
	from ccocallsout c with(nolock)
	left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
	left join ccusers b on (c.user_id = b.user_id) 
	left join cccamps a on (c.cam_id = a.cam_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
	left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
	where cal_id >= @call_id
 end

if @action = 3 --Session time
	begin
		declare @fecha_ini datetime
		declare @fecha_fin datetime	

		if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
			select @fecha_ini = convert(datetime,convert(varchar(30),getdate()))
			select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
		end
		else begin
			select @fecha_ini = convert(datetime,convert(varchar(30),@startDate))
			select @fecha_fin = convert(datetime,convert(varchar(30),@endDate))
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
		select top 500
			cal_id as call_id,
			c.inbound_id,
			isnull(a.descripcion,'''') as acdGroup,
			cal_ani as phoneNumber,
			isnull(b.user_id,0) as user_id,
			isnull(login,'''') as login,
			isnull(e.description,'''') as disposition,
			d.descripcion as call_status,
			cal_tDialog as call_tDialog,
			cal_inicio as call_date,
			cal_tNotas as WrapUp,
			cal_tXfer as Xfer,
			cal_tRing as Ringing,
			cal_key as callKey,
			isnull(e.calif_id,'''') as dispositionId,
			isnull(f.califSubDesc,'''') as subDisposition,
			isnull(f.califSub_id,'''') as subDispositionId
		from cccallsin c with(nolock)
		left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
		left join ccusers b on (c.user_id = b.user_id) 
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalif e on ( c.calif_id = e.calif_id )
		left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end


	-- Single call_id Outbound
	if @action = 6
	 begin
		select top 500
			cal_id as call_id,
			c.cam_id,
			isnull(a.cam_descripcion,'''') as Campaign,
			c.cal_telefono as phoneNumber,
			isnull(b.user_id,0) as user_id,isnull(login,''''),
			isnull(e.description,'''') as disposition,
			d.descripcion as call_status,
			cal_tDialog as call_tDialog,
			cal_inicio as call_date,
			cal_tNotas as WrapUp,
			cal_tXfer as Xfer,
			cal_tRing as Ringing,
			cal_manual as CallManual,
			c.cal_key as callKey,
			cs.list_id,
			isnull(e.calif_id,'''') as dispositionId,
			isnull(f.califSubDesc,'''') as subDisposition,
			isnull(f.califSub_id,'''') as subDispositionId
		from ccocallsout c with(nolock)
		left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
		left join ccusers b on (c.user_id = b.user_id) 
		left join cccamps a on (c.cam_id = a.cam_id)
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
		left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end

if @action = 7 --Status Agente
begin 
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha), IdCampEsp, Tipo 
	from cclogagentesdia with(nolock) 
	where user_id = @agentId 
	and fecha >= @startDate 
	and fecha < @endDate 
	order by fecha
end

if @action = 8 
begin
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) fecha, IdCampEsp, Tipo, user_id 
	from cclogagentesdia with(index(IX_ccLogAgentesDia_4),nolock) 
	where user_id in (select value from fn_RIASplitDelimited(@multipleUser_id,'','')) 
	and fecha between @startDate 
	and @endDate 
	order by user_id,fecha
end'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIA_ABCCamps - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int,
@Descripcion varchar(40),
@Cam_id varchar(1000),
@Activa tinyint,
@IDArea smallint = null,
@frame tinyint, 
@MirrorInbound_Id smallint = null
as
set nocount on

if @option = 0
 begin
	 select cam_id,ISNULL(cam_descripcion,'''') as cam_descripcion
	  ,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
	 from ccCamps as CAMP with(nolock)
	 left join ccRIACat_Areas as AREas with(nolock)
	 on CAMP.IDArea = AREas.IDArea
	 return(0)
 end

if @option = 1 -- select Camp
 begin
	 select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,
	  cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0)
	 from ccCamps a1
	  inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
	  inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	 where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
	 return(0)
 end

if @option = 4 --Delete
 begin
 	 if exists (select inbound_id from ccInbound where cam_id = @Cam_id)
	  begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad'' 
		 else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
	  end

	 delete ccCampsHorarios where cam_id = @Cam_id
	 insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id)
	  Values(@Cam_id, 5, 0, 0, @UserId)
	 Delete ccCalifCamp where cam_id = @Cam_id and tipo = 1
	 Delete ccRIACampsGraph where cam_id = @Cam_id
	 delete ccHistorialListaNegra where cam_id = @Cam_id
	 delete ccRIARegistryLists where cam_id = @Cam_id

	/*** Se elimina la funcionalidad de paso de informacion de CCenterRIA a ccReports y borrado de información cuando una campaña es eliminada ***/
	/*
	-- Se inicia proceso de scheduler service para pasar informacion de ccocallsout antes de eliminarla
	 declare @server varchar(200), @sql varchar(8000), @from datetime, @to datetime
	select @server=valor from ccsettings where setting_id=22

	set @from=convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '':00'',121)
	set @to=convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '':00'',121)

	set @sql=''declare @calIni as varchar(15), @calfin as varchar(15), @Cam_id as smallint
	select @calIni=isnull(max(cal_id),1) from '' + @server + ''.dbo.ccocallsout WITH(NOLOCK) where cam_id = @Cam_id
	select @calfin=max(cal_id) from ccocallsout with(index (IX_ccoCallsOut_2),NOLOCK) where cam_id = @Cam_id 
	SET IDENTITY_INSERT '' + @server + ''.dbo.ccocallsout ON ''

	set @sql = @sql + ''
	insert into '' + @server + ''.dbo.ccocallsout (cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
	statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
	cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh)
	select cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
	statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
	cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh from ccocallsout WITH(NOLOCK) WHERE cal_id>@calIni and cal_id<=@calfin 
	and cam_id=''+cast(@Cam_id as varchar(10))+'' 
	SET IDENTITY_INSERT '' + @server + ''.dbo.ccocallsout OFF ''
	exec(@sql)

	delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @Cam_id)
	delete ccoCallsOutSource where cam_id = @Cam_id
	Delete ccCamps where cam_id = @Cam_id
	 */
	 return(0)
 end

if @option = 2 --Insert
 begin
	declare @new_cam_id smallint

	if exists(select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
	 begin
		select -1 --, ''Nombre en Uso''
		return(0)  
	 end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1

	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
	 begin
		select -2 --, ''Error al crear campaña''
		return(0)
	 end

	if isnull(@MirrorInbound_Id, 0)<>0
	 begin
		if not exists(select inbound_id from ccInbound where inbound_id=@MirrorInbound_Id)
		 begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
		 end

		update ccinbound set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
	 end

	insert into ccoDialerCamp (dialer_id, cam_id)
	select dialer_id, @new_cam_id from ccoDialers where status = 1

	insert into ccCalifCamp (calif_id, cam_id, tipo) select calif_id, @new_cam_id, 1 from ccTipoCalifOUT where CalifOut_Status = 1

	If not exists (select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	 begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
	 end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics where frame = @frame and type_id = 1

	--inserta la lista negra por default
	if (select valor from ccsettings where setting_id=152)=''1''
	begin
		declare @tempId as int
		DECLARE @dnclId TABLE 
		(
		  id int 
		);
		insert into @dnclId
		exec dbo.ccsp_RIACATBList null, null, 5
		select @tempId=id from @dnclId;
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end

	select @new_cam_id
	return(0)
 end

if @option = 3 -- Update
 begin
	 if not exists(select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	  insert into ccRIAGraphics (frame,type_id) values (@frame,1)

	 Update ccCamps set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

	 update ccRIACampsGraph
	  set graphic_id = (select graphic_id from ccRIAGraphics where frame = @frame and type_id = 1)
	  where cam_id = @Cam_id

	 return(0)
 end

 if @option = 5 --Obtener relaciones de campañas - campañas
   begin
      if not exists (select cam_id from ccCamps where cam_id = @Cam_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña invalida
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null

	update ccCamps set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
		
	else
	 begin
		delete cccalifcamp where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	 end

	return(0)
   end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIACATBList - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIACATBList]
@BLID smallint,
@name varchar(50),
@Type tinyint 
AS
set nocount on
if @Type=1
 begin
	Select idtipolista AS ID, tipolista AS TIPO 
	from cctiposlistanegra where idtipolista = case isnull(@BLID,0) when 0 then idtipolista else @BLID end
	and Status= 1 order by 2
	return(0)
 end

If @Type=2
 begin
	if exists(select tipolista from cctiposlistanegra where tipolista=@name)
		select 1, ''Nombre en Uso''
	else	
		insert into cctiposlistanegra (tipolista) values(@name)
	return(0)
 end

if @Type=4
 begin
	update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
 end

if @Type=5
	begin
		declare @dnclid as int
		set @dnclid = 0;

		select @dnclid = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
		select @dnclid
		return(0)
		end
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_ExtAppsCamList - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCamList]
@action smallint,
@area int =0
AS 
set nocount on
if @action = 1 
 begin
	if @area = 0
		select a1.inbound_id, descripcion
		from ccinbound a1 join ccRIAinboundGraph a2 on (a1.inbound_id = a2.inbound_id)
		join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1
		order by descripcion
	else
		select distinct a1.inbound_id, descripcion
		from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
		join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@area, 0)
		order by descripcion
	return(0)
 end
if @action = 2 
 begin
	if @area = 0
	    select a1.cam_id, cam_descripcion
		from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
		join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a3.type_id = 1 
		order by 2
	else
		select distinct a1.cam_id, cam_descripcion
        from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
        join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
        where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@area, 0)
        order by cam_descripcion
	return(0)
 end
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_AgentUpdateCallCALIF - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0
as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key), 
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall
	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin		
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista 
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and dbo.Completa_ListaNegra(co.cal_telefono)<>''E_NV_Longitud'' and cbl.tipo=1

		exec ccsp_InsertDNCList @tel, @iddncList

		insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
		select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and dbo.Completa_ListaNegra(co.cal_telefono)<>''E_NV_Longitud'' and cbl.tipo=1
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId
		
		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id, 
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp) 
		where logDial_id in (select top 1 L.logDial_id from 
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock) 
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock) 
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end
	 
	select @keepDial
	return(0)
 end

set nocount off'
		
	EXEC(@Sql)

		set @process = 'ccsp_INInsertaCallBack - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
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
@user_id int=0,
@isAuto bit=0
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

select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

declare @difference as int
declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
if @isAuto=0
	select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
else
	set @difference = 0
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

		insert into ccoCallBacks
		(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
		values
		(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
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

		insert into ccoCallBacks
		(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
		values
		(@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTInsertaCallBack - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
@cal_id int,
@Telefono varchar(15),
@Camp smallint,
@FechaDial smalldatetime,
@callout_id int=0,
@TelReprograma smallint=-1,
@user_id int=0,
@cal_Key varchar(33)='''',
@isAuto bit=0
as
set nocount on
IF @TelReprograma<0
      return(0)
 
declare @Fecha smalldatetime, @sSQL nvarchar(max)
declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
declare @idZone int, @idZoneDaylight int, @list_id int
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
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
 
if @isAuto=0
	select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
else
	set @difference = 0
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
@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end,
@list_id=list_id
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
      iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5,list_id)
      select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
      @user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
      @iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5,@list_id
 
      insert into ccoCallBacks 
	  (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus) 
	  values
	  (@callout_id,@user_id,@Camp,@cal_Key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
 
set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAUpdateCallBack_Abandon - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on

declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)

if isnull(@cam_id, 0)=0
	return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
	return(0)

if (select substring(dbo.completa(@ANI),1,1))= ''E''
	return(0)

 begin try
	insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
	select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial

	select @ANI=dbo.completa(@ANI)
	exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, ''Callback by abandon'', @fechadial, '''', '''', '''', 1, 0, 1

	select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
	update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
	return(0)
 end try

 begin catch
	return(0)
 end catch
set nocount off'
		
	EXEC(@Sql)

		set @process = 'ccsp_RIAMenuRoles - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAMenuRoles]
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
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint

select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145


If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin	
	if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	begin	
		if @Role_id in (1, 10, 14) begin			
			if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin						
				Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)		
			end
			else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin					
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
				end
			else if @reportRol = 3 begin				
				insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id 			 			
			end
		end
		else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) ) 
		begin			
			if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol		
				insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
		end		
	end		
	--Asigna un rol por default o lo actuliza
	if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
	
	--Solo es necesario en caso admin y reports
	if @reportRol in(1,2) begin 
		--    inserta parent en caso de no haberlo hecho en rol personalizado        
		insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from               
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

		select @User_id, parent, @reportRol from               
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0
		
	end
	return (0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
      else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
      select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))  
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))  
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

If @Type = 10 -- update all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from 
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
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
 
 if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
 begin
	insert into ccMenuUser([id_user],[id_Menu],[type])
	select a.User_id, b.menu_id, b.type 
		from ccUsers a cross join ccMenus b
		left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id	
		where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and 
		b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

	insert into ccRIAUserRole([User_id],[Role_id],[type])
		select a.[User_id], 14 as role_id, 3 as type from ccUsers a
			left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
			where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id
				
	return (0)
	
 end

return(0)
set nocount off'
	
	EXEC(@Sql)		

		set @process = 'ccsp_RIAccSettingsConfig - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null 
AS
set nocount on

declare @idioma tinyint
declare @activeChat tinyint

select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145

if @command=0
 begin
	SELECT case @idioma when 0 then descripcion else [description] end descripcion 
	FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
	order by descripcion
	return(0)
 end

if @command=1
 begin
	Select setting_id, case @idioma when 0 then descripcion else [description] end descripcion, valor, tipo
	from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'') 
	and (setting_id not in (139,140,141)
	or   setting_id     in (139,140,141) and @activeChat > 0)
	order by tipo, descripcion
	return(0)
 end

if @command=2
 begin
	if @setting_id = 27 and @value not in(''0'',''1'') begin
		set @value = 0
	end
	else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'') begin
		set @value = 1
	end
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
 end

set nocount off'
		
	EXEC(@Sql)

		set @process = 'CW Delete old records - Drop and Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [CW Delete old records]    Script Date: 03/25/2014 17:05:05 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1

/****** Object:  Job [CW Delete old records]    Script Date: 03/25/2014 17:04:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 03/25/2014 17:04:48 ******/
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
/****** Object:  Step [Run sp]    Script Date: 03/25/2014 17:04:48 ******/
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
delete from ccRiaChat_log where fecha_chat < dateadd(mm, -@meses, getdate())

delete xxclientehistorial where fechaAct < dateadd(mm, -@meses, getdate())
delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -15, getdate())
delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -15, getdate())
delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -15, getdate())
delete ccRIAcallbacks where año < datepart(yy,getdate())
delete ccRIAcallbacks where mes < datepart(mm,getdate())

delete from ccLogAgentesDia where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogAgentesNotReady where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogLogin where fecha < dateadd(mm, -@meses, getdate())
delete from ccoLogDials where fecha < dateadd(mm, -@meses, getdate())
delete from ccoCallsOut where cal_inicio < dateadd(mm, -@meses, getdate())
delete from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate())
delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -@meses-1, getdate())

delete from ccPosicionEspecialidad where Fecha < dateadd(dd, -15, getdate())
delete from ccPosicionCamps where Fecha < dateadd(dd, -15, getdate())

delete from ccocallbacks where cal_fecha < dateadd(dd, -15, getdate())
delete from ccLogReciclaje where fecha < dateadd(dd, -15, getdate())'', 
		@database_name=N''CCenterRIA'', 
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
	
		set @process = 'NuxibaMaintenancePlan - Drop and Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 04/09/2014 16:19:11 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 04/07/2014 16:43:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/07/2014 16:43:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaMaintenancePlan'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''NuxibaMaintenancePlan'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Call Center Activity Task]    Script Date: 04/07/2014 16:43:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Call Center Activity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @fecha_ini datetime
declare @fecha_fin datetime

select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

IF EXISTS (SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
datediff(s,login,isnull(max(logout),getdate())) loginTime
FROM (SELECT uid, ext, login, ISNULL(logout, 
(SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(IX_ccLogLogin_2))  
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout   
FROM (SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout   
FROM (SELECT uid, ext, MAX(login) as login, logout
FROM(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha)
FROM ccLogLogin subLogin with (nolock, index(IX_ccLogLogin_2)) WHERE subLogin.tipomov = 0      
AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout]      
FROM ccLogLogin Login with (nolock, index(IX_ccLogLogin_2))     
WHERE login.fecha >= dateadd(dd, -5, @fecha_ini) and tipomov = 1     
GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail     
WHERE logout IS not NULL GROUP BY uid, ext, logout) Login    
RIGHT OUTER JOIN ccLogLogin  with (nolock, index(IX_ccLogLogin_2))   
ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login 
AND ccLogLogin.extension = Login.ext)   WHERE tipomov = 1   and ccLogLogin.fecha 
>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail WHERE logout IS NULL 
and login >= @fecha_ini and login < @fecha_fin 
GROUP BY uid, login)
BEGIN
  RAISERROR(''''Agents online.'''', 11, 1);
END
ELSE
BEGIN
	RETURN
END'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 04/07/2014 16:43:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Database Task]    Script Date: 04/07/2014 16:43:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Database Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKDATABASE(N''''CCenterRia'''', 10, TRUNCATEONLY)'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 04/07/2014 16:43:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccenter_Log'''',1)'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reorganize Index Task]    Script Date: 04/07/2014 16:43:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Reorganize Index Task'', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_axLicG729_Data] ON [dbo].[axLicG729_Data] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_Camplistanegra] ON [dbo].[Camplistanegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAbandonoSalida_Chart] ON [dbo].[ccAbandonoSalida_Chart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgenda_TipolistaNegra] ON [dbo].[ccAgenda_TipolistaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra_1] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra_2] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAgendaListaNegra_3] ON [dbo].[ccAgendaListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_INFOESPEC_FECHA] ON [dbo].[ccAllInfoEspec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_INFOESPEC_INBOUND_ID] ON [dbo].[ccAllInfoEspec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccalifblacklist] ON [dbo].[cccalifblacklist] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [IX_cccallsin_tmpChart] ON [dbo].[cccallsin_tmpChart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCallsReject] ON [dbo].[ccCallsReject] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamEspAgentStatus] ON [dbo].[ccCamEspAgentStatus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamps_Consulta] ON [dbo].[ccCamps_Consulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [iii] ON [dbo].[ccCampsAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsHorarios] ON [dbo].[ccCampsHorarios] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsMsgs] ON [dbo].[ccCampsMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsNvosCB] ON [dbo].[ccCampsNvosCB] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCampsPrioridadTel] ON [dbo].[ccCampsPrioridadTel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccClientes] ON [dbo].[ccClientes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccDNIS] ON [dbo].[ccDNIS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccEdoAniList] ON [dbo].[ccEdoAniList] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSpec] ON [dbo].[ccGenInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSpecOut] ON [dbo].[ccGenOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenLogin] ON [dbo].[ccGenSession] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra_1] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra_2] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHistorialListaNegra_3] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccHorarios] ON [dbo].[ccHorarios] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHorarioVerano] ON [dbo].[ccHorarioVerano] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccHorarioVeranoUsa] ON [dbo].[ccHorarioVeranoUsa] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInbound_Consulta] ON [dbo].[ccInbound_Consulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccInboundAgentes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundDNIS] ON [dbo].[ccInboundDnis] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInboundHorarios] ON [dbo].[ccInboundHorarios] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs_1] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs_2] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs_3] ON [dbo].[ccInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccListaNegra] ON [dbo].[ccListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje_1] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje_2] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogReciclaje_3] ON [dbo].[ccLogReciclaje] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogTransfers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenu_Views] ON [dbo].[ccMenu_Views] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenu_ViewsUser] ON [dbo].[ccMenu_ViewsUser] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccMenusReportes] ON [dbo].[ccMenusReportes] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMonitorExt] ON [dbo].[ccMonitorExt] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccMsgFiles] ON [dbo].[ccMsgFiles] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks5] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
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
ALTER INDEX [PK_ccoDatos] ON [dbo].[ccoDatos] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_1] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_2] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_3] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_4] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_5] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_6] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_7] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_8] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion_1] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion_2] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccPuertosPBX] ON [dbo].[ccPuertosPBX] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallBacks] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks_1] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks_2] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACallBacks_3] ON [dbo].[ccRIACallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatFinder] ON [dbo].[ccRIAChatFinder] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccRIAChatInboundMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatPredefinedMsg] ON [dbo].[ccRIAChatPredefinedMsg] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChats_1] ON [dbo].[ccRIAChats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAChatStatus] ON [dbo].[ccRIAChatStatus] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAClienteCarga] ON [dbo].[ccRIAClienteCarga] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAClienteCarga_1] ON [dbo].[ccRIAClienteCarga] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIADispMonitorRel] ON [dbo].[ccRIADispMonitorRel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAExternalApplications] ON [dbo].[ccRIAExternalApplications] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAGraphics] ON [dbo].[ccRIAGraphics] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAGraphicType] ON [dbo].[ccRIAGraphicType] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAInboundGraph] ON [dbo].[ccRIAInboundGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALoading] ON [dbo].[ccRIALoading] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALoading_1] ON [dbo].[ccRIALoading] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIALoading] ON [dbo].[ccRIALoading] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIALog] ON [dbo].[ccRIALog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALog_Module] ON [dbo].[ccRIALog_Module] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALog_Operation] ON [dbo].[ccRIALog_Operation] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALogAgentesNotReady] ON [dbo].[ccRIALogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIALogAgentesNotReady_1] ON [dbo].[ccRIALogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIANotReadyGraph] ON [dbo].[ccRIANotReadyGraph] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIARegistryLists] ON [dbo].[ccRIARegistryLists] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIARegistryLists_1] ON [dbo].[ccRIARegistryLists] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_Table_1] ON [dbo].[ccRIARegistryLists] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRiaRemoteLog] ON [dbo].[ccRiaRemoteLog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAUpdateCallBack_Abandon_1] ON [dbo].[ccRIAUpdateCallBack_Abandon] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAUpdateCallBack_Abandon] ON [dbo].[ccRIAUpdateCallBack_Abandon] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logDial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logDial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSettings] ON [dbo].[ccSettings] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccStatusLLamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSupervisorND] ON [dbo].[ccSupervisor_NotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ix_tipo_1] ON [dbo].[ccSupervisorCam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_TideWater_Templates] ON [dbo].[ccTideWater_Templates] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTideWater_Templates_Cols] ON [dbo].[ccTideWater_Templates_Cols] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTideWater_TipoConexion] ON [dbo].[ccTideWater_TipoConexion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_Timetable] ON [dbo].[ccTimetable] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimetablechange] ON [dbo].[ccTimetablechange] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimetabledetail] ON [dbo].[ccTimetabledetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [pk_areaprefix] ON [dbo].[ccTimeZoneAreaUsaDetail] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTimeZones] ON [dbo].[ccTimeZones] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoFiltro] ON [dbo].[ccTipoFiltro] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoMovsListaNegra] ON [dbo].[ccTipoMovsListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoMsgs] ON [dbo].[ccTipoMsgs] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoPBX] ON [dbo].[ccTipoPBX] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTiposListaNegra] ON [dbo].[ccTiposListaNegra] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctipoSubCalifRel] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccUploadTemporal] ON [dbo].[ccUploadTemporal] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccUploadTemporal_1] ON [dbo].[ccUploadTemporal] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccUsers_Consulta] ON [dbo].[ccUsers_Consulta] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_Series] ON [dbo].[Series] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_Series_1] ON [dbo].[Series] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_telefonosConferencia] ON [dbo].[telefonosConferencia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_clienteCarga] ON [dbo].[xxClienteCarga] REORGANIZE WITH ( LOB_COMPACTION = ON )'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rebuild Index Task]    Script Date: 04/07/2014 16:43:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Rebuild Index Task'', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_axLicG729_Data] ON [dbo].[axLicG729_Data] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_Camplistanegra] ON [dbo].[Camplistanegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAbandonoSalida_Chart] ON [dbo].[ccAbandonoSalida_Chart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgenda_TipolistaNegra] ON [dbo].[ccAgenda_TipolistaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra_1] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra_2] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAgendaListaNegra_3] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_INFOESPEC_FECHA] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_INFOESPEC_INBOUND_ID] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccalifblacklist] ON [dbo].[cccalifblacklist] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [IX_cccallsin_tmpChart] ON [dbo].[cccallsin_tmpChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCallsReject] ON [dbo].[ccCallsReject] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamEspAgentStatus] ON [dbo].[ccCamEspAgentStatus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamps_Consulta] ON [dbo].[ccCamps_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [iii] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsHorarios] ON [dbo].[ccCampsHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsMsgs] ON [dbo].[ccCampsMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsNvosCB] ON [dbo].[ccCampsNvosCB] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCampsPrioridadTel] ON [dbo].[ccCampsPrioridadTel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccClientes] ON [dbo].[ccClientes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccEdoAniList] ON [dbo].[ccEdoAniList] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSpec] ON [dbo].[ccGenInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSpecOut] ON [dbo].[ccGenOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenLogin] ON [dbo].[ccGenSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra_1] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra_2] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHistorialListaNegra_3] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccHorarios] ON [dbo].[ccHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHorarioVerano] ON [dbo].[ccHorarioVerano] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccHorarioVeranoUsa] ON [dbo].[ccHorarioVeranoUsa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInbound_Consulta] ON [dbo].[ccInbound_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccInboundAgentes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundDNIS] ON [dbo].[ccInboundDnis] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInboundHorarios] ON [dbo].[ccInboundHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs_1] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs_2] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs_3] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccListaNegra] ON [dbo].[ccListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesDia_5] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNotReady_4] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje_1] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje_2] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogReciclaje_3] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogTransfers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenu_Views] ON [dbo].[ccMenu_Views] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenu_ViewsUser] ON [dbo].[ccMenu_ViewsUser] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccMenusReportes] ON [dbo].[ccMenusReportes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMonitorExt] ON [dbo].[ccMonitorExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccMsgFiles] ON [dbo].[ccMsgFiles] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks3] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks4] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks5] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
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
ALTER INDEX [PK_ccoDatos] ON [dbo].[ccoDatos] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_1] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_2] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_3] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_4] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_5] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_6] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_7] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_8] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion_1] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion_2] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccPuertosPBX] ON [dbo].[ccPuertosPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks_1] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks_2] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACallBacks_3] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatFinder] ON [dbo].[ccRIAChatFinder] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccRIAChatInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatPredefinedMsg] ON [dbo].[ccRIAChatPredefinedMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChats_1] ON [dbo].[ccRIAChats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAChatStatus] ON [dbo].[ccRIAChatStatus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAClienteCarga] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAClienteCarga_1] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIADispMonitorRel] ON [dbo].[ccRIADispMonitorRel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAExternalApplications] ON [dbo].[ccRIAExternalApplications] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAGraphics] ON [dbo].[ccRIAGraphics] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAGraphicType] ON [dbo].[ccRIAGraphicType] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAInboundGraph] ON [dbo].[ccRIAInboundGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALoading_1] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIALog] ON [dbo].[ccRIALog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALog_Module] ON [dbo].[ccRIALog_Module] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALog_Operation] ON [dbo].[ccRIALog_Operation] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALogAgentesNotReady] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIALogAgentesNotReady_1] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIANotReadyGraph] ON [dbo].[ccRIANotReadyGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIARegistryLists] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIARegistryLists_1] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_Table_1] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRiaRemoteLog] ON [dbo].[ccRiaRemoteLog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAUpdateCallBack_Abandon_1] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAUpdateCallBack_Abandon] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSettings] ON [dbo].[ccSettings] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccStatusLLamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSupervisorND] ON [dbo].[ccSupervisor_NotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ix_tipo_1] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_TideWater_Templates] ON [dbo].[ccTideWater_Templates] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTideWater_Templates_Cols] ON [dbo].[ccTideWater_Templates_Cols] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTideWater_TipoConexion] ON [dbo].[ccTideWater_TipoConexion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_Timetable] ON [dbo].[ccTimetable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimetablechange] ON [dbo].[ccTimetablechange] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimetabledetail] ON [dbo].[ccTimetabledetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [pk_areaprefix] ON [dbo].[ccTimeZoneAreaUsaDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTimeZones] ON [dbo].[ccTimeZones] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoFiltro] ON [dbo].[ccTipoFiltro] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoMovsListaNegra] ON [dbo].[ccTipoMovsListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoMsgs] ON [dbo].[ccTipoMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoPBX] ON [dbo].[ccTipoPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTiposListaNegra] ON [dbo].[ccTiposListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctipoSubCalifRel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccUploadTemporal] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccUploadTemporal_1] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccUsers_Consulta] ON [dbo].[ccUsers_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_Series] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_Series_1] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_telefonosConferencia] ON [dbo].[telefonosConferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_clienteCarga] ON [dbo].[xxClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Statistics Task]    Script Date: 04/07/2014 16:43:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Update Statistics Task'', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''UPDATE STATISTICS [dbo].[ACDlistanegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[axLicG729_Data] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Camplistanegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAbandonoSalida] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAbandonoSalida_Chart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAgenda_TipolistaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAgendaListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAllInfoEspec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccAVRSTransfer] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccBorrardasReciclaje] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccalifblacklist] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCalifCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccallsin_tmpChart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsReject] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamEspAgentStatus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamps_Consulta] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsAutoInicio] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsDialInfo] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsHorarios] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMovs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMovsAgts] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsNvosCB] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsPrioridadTel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccClientes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDataAgents] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDataCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDataGridByUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDias] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDNIS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccEdoAniList] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccEstadosAni] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgentNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenChart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAbnd] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAnsw] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCallDNI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCstoResumen] 
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
UPDATE STATISTICS [dbo].[ccHistorialListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarios] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVerano] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoArg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoChi] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoCol] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoUsa] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccHorarioVeranoVen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInbound] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInbound_Consulta] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundAgentes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundDnis] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundHorarios] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundInfo] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia_Dialog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogCampsAgentesDia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogInfo] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogLogin] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogReciclaje] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogTransfers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenu_Views] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenu_ViewsUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenuReportesUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenusReportes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMenuUser] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMonitorExt] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccMsgFiles] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccNPALocalPrefixes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallBacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOut] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOutSource] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDatos] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialerCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoLogDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoWorkingTable] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoXferType] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicion] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionEspecialidad] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPuertosPBX] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRateByCarrier] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIA_vmACDMailBoxes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIA_vmMailBoxes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIA_vmMessages] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAAreaWorkGroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACallBack_Queue] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACallBacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACampEspWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACampsGraph] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_AdminPermissions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_AdminRole] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_Areas] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_Country] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_DataGrid] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_DialMode] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_WorkGroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACatConnStrings] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACatFunExt] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACATLogPhones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChat_Log] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChat_TipoMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatFinder] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatInboundMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatInboundPredefinedMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatMailbox] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatPredefinedMsg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAChatStatus] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAClassPath] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAClienteCarga] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIADispMonitorRel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAExternalApplications] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAGraphics] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAGraphicType] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAInboundGraph] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALoading] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog_Cat_Relation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog_Module] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALog_Operation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALogAgentesNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIALogPhones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIANotReadyGraph] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIARegistryLists] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRiaRemoteLog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIARoleMenu] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAUpdateCallBack_Abandon] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAUserRole] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAUsr_AdminPermissions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_Calid] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_logDial_id] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroupUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSettings] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccStatusLLamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSupervisor_NotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSupervisorCam] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTeclaExtensionPuerto] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTideWater_Templates] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTideWater_Templates_Cols] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTideWater_TipoConexion] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimetable] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimetablechange] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimetabledetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZoneArea] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZoneAreaArgDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZoneAreaUsaDetail] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTimeZones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifSub] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifSubOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoDias] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoDnis] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoFiltro] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoMovsListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoMsgs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoPBX] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoResultadoDial] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTiposListaNegra] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoStatusAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cctipoSubCalifRel] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUnavailableRelation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUploadBlocked] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUploadTemporal] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUploadWrong] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUsers_Consulta] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cli_TipoOrigenLlamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoProvedor] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoTarifa] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoTipoLlamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ivrActividadPto] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVROptions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRStructure] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRTemplate] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRTemplateAudio] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRTemplateStruct] 
WITH FULLSCAN
If exists (select name from sysobjects where name = ''''migration'''')
	begin
		UPDATE STATISTICS [dbo].[migration] 
		WITH FULLSCAN
	end
If exists (select name from sysobjects where name = ''''migrationAVRS'''')
	begin
		UPDATE STATISTICS [dbo].[migrationAVRS] 
		WITH FULLSCAN
	end
UPDATE STATISTICS [dbo].[ScriptingAgentConfiguration] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingAnswerTemplate] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingCampaignRelation] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingTemplate] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ScriptingTemplateStruct] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Series] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[SeriesArg] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesAU] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesBR] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesChi] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[SeriesCol] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesSA] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[seriesUK] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[SeriesVen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosConferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosIvr] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosTransferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxClienteCarga] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxClienteConexiones] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxClienteHistorial] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[xxLog] 
WITH FULLSCAN'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up History Task]    Script Date: 04/07/2014 16:43:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Clean Up History Task'', 
		@step_id=8, 
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
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Back Up Database Task]    Script Date: 04/07/2014 16:43:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Back Up Database Task'', 
		@step_id=9, 
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
select @date = ''''CCenterRia_backup_MP'''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''.bak''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''\'''' + @date

drop table #RutaBak

BACKUP DATABASE [CCenterRia] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10
'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Maintenance Clean Up Task]    Script Date: 04/07/2014 16:43:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Maintenance Clean Up Task'', 
		@step_id=10, 
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
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Monthly'', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20130716, 
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
