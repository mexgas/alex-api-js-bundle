/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	CW-1087 Setting de Cola mensajeria
	CW-1058 Programar notReady en la maquina de estados
	CW-1160 Cambio para guardar tiempo llamada ACD
	CW-1170 Guardar las lista de calificaciones
	CW-1439 Setting_ID 201 Cadena de conexion(ODBC) para consultar una BD externa en la llamada manual
	
Database: CCenterRia
Required version: 119.74

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 129 sin fix
set @versionfix = 1
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

select @actualVersion,@actualVersionFix,@versionfix

if @actualVersion in(@version ,@version-1)
	begin
		begin tran
		begin try	
    set @process = 'CW-718 -- Drop SP ccspAgent_GetLastCalls'
    set @Sql= 'if exists (select * from sys.procedures where name = N''ccspAgent_GetLastCalls'')
    begin
        DROP PROCEDURE ccspAgent_GetLastCalls;
    end
'
    EXEC(@Sql)

	set @process = 'CW-718 -- Create SP ccspAgent_GetLastCalls'
    set @Sql= 'CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

select * from

(select top 10 cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, cast(cal_tDialog / 3600 as varchar(10)) + '':'' + right(''0'' + cast(cal_tDialog / 60 % 60 as varchar(3)), 2) + 
'':'' + right(''0'' + cast(cal_tDialog % 60 as varchar(3)), 2) as Duracion, '''' as CallBack, cal_key, c.inbound_id as IDCampEsp
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound i on c.inbound_id = i.inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())
order by cal_id desc) a

Union

select * from
(select top 10 cal_id as id, ''OUT'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, cast(cal_tDialog / 3600 as varchar(10)) + '':'' + right(''0'' + cast(cal_tDialog / 60 % 60 as varchar(3)), 2) + 
'':'' + right(''0'' + cast(cal_tDialog % 60 as varchar(3)), 2) as Duracion, convert(varchar(16), cal_fcallback, 121) as CallBack, cal_key, c.cam_id as IDCampEsp
from ccoCallsOut c with(nolock index(IX_ccoCallsOut_9)) 
inner join ccCamps o on c.cam_id = o.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())
order by cal_id desc) b

order by hora desc

set nocount off
	'
    EXEC(@Sql)

    set @process = 'CW-1162 -- Drop SP ccsp_LoadGraphics'
    set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_LoadGraphics'')
    begin
        DROP PROCEDURE ccsp_LoadGraphics;
    end
'
    EXEC(@Sql)

	set @process = 'CW-1162 - CW-714 Tonos DTMF --- Create SP ccsp_LoadGraphics'
    set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	DECLARE @AuthorizationPlayStopRec TABLE(value bit)
	DECLARE @realValue bit
 
	INSERT INTO @AuthorizationPlayStopRec 
	exec ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType

	select @realValue=value from @AuthorizationPlayStopRec

	
	if (@callType=1)
	begin		
		select a1.Inbound_id, a2.descripcion, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage ,
		case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
		isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
		a2.ShowCalifWnd as ShowDisposition,isnull(a2.startStopRecording,0) as StartStopRecording,@realValue as IsStartStopRecording,isnull(a2.editableDtmf, 0) as isEditDtmf
		from ccRIAInboundGraph a1 
		inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
		 inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
		 left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id		
	 end	
END'
    EXEC(@Sql)

	set @process = 'CW-1148 -- Alter column ccLogAgentesDia.tStatus float '
    set @Sql= 'ALTER TABLE ccLogAgentesDia ALTER COLUMN tStatus float'
    EXEC(@Sql)

    set @process = 'CW-1148 -- Alter column ccLogAgentesNotReady.tStatus float '
    set @Sql= 'ALTER TABLE ccLogAgentesNotReady ALTER COLUMN tStatus float;'
    EXEC(@Sql)

	set @process = 'Setting_id 183 WebRTC Configuration Se modifica la longitud de la columna valor'
    set @Sql= 'ALter table ccSettings Alter column valor varchar(300)'
	EXEC(@Sql)

	set @process = ''
    set @Sql= ''
    EXEC(@Sql)
   

    set @process = 'CW-1058 Programar notReady en la maquina de estados'
    set @Sql= 'ALTER procedure [dbo].[ccsp_RIAGetSelectedNotReady]
@user_id int = 0,
@tipoNR int

AS

-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer
declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime
declare @AcumTime int

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin	
	set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
	set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set  @fStart = dateadd( d,-1, @fEnd )
end

select @AcumTime =isnull( sum(tStatus),0)  from ccRIALogAgentesNotReady where fecha between @fStart and @fEnd and tiponotready_id=@tipoNR and (user_id = @user_id)

select a1.tiponotready_id,descripcion, frame, time_acum, time_xev,  pas_sup, nextstatus, @AcumTime as AcumTime, 
dbo.NeventsNRdisp(@user_id, nextstatus, getdate())  as NeventsNRdisp
 from cctiponotready a1
inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
where a1.tiponotready_id=@tipoNR
'
    EXEC(@Sql)

    set @process = 'Alter SP -- ccsp_RIAGetNotReadyHistory'
    set @Sql= 'ALTER  procedure [dbo].[ccsp_RIAGetNotReadyHistory]
@user_id int = 0
AS
set nocount on
-- Para horarios depues de las 12 de la noche
declare @fStart datetime, @fEnd datetime
declare @inicioTurno int, @AcumTime int
declare @fecha smalldatetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()

if datepart(hh,@fecha)>@inicioTurno-1
 begin	
	set @fStart=convert(datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set @fEnd=dateadd(d,1,@fstart)
 end

else
 begin
	set @fEnd=convert(datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set @fStart=dateadd(d,-1,@fEnd)
 end

select 
	l.tiponotready_id, Descripcion, frame, 
	CONVERT(CHAR(8),DATEADD(second,sum(tStatus),0),108) as Tiempo,
	count(l.tiponotready_id) as veces, 0 as fecha, time_Acum,time_xEv,
	CONVERT(CHAR(8),DATEADD(second,time_Acum,0),108) as maxTimeAcum
	from ccRIALogAgentesNotReady l with(index(IX_ccRIALogAgentesNotReady_1)) 
	inner join ccTipoNotReady t on l.tiponotready_id = t.tiponotready_id
	inner join ccRIAnotreadyGraph a2 on (t.tiponotready_id=a2.tiponotready_id)
	inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where fecha between @fStart and @fEnd and user_id = @user_id
	group by t.descripcion, l.tiponotready_id, frame,time_Acum,time_xEv

union

select l.TipoNotReady_id, Descripcion, 0 as frame,
CONVERT(CHAR(8),DATEADD(second,tStatus,0),108) as Tiempo, 
 0 as veces, fecha, 0 as time_Acum,0  as time_xEv, ''00:00:00'' as maxTimeAcum
from ccRIALogAgentesNotReady l with(index(IX_ccRIALogAgentesNotReady_1)) 
inner join ccTipoNotReady t on l.tiponotready_id = t.tiponotready_id
where fecha between @fStart and @fEnd and (user_id = @user_id)
order by l.TipoNotReady_id, fecha

set nocount off'
    EXEC(@Sql)

    set @process = 'Alter ccsp_RIAGetNotReadyTypes_xUser -- Galatea'
    set @Sql= 'ALTER procedure [dbo].[ccsp_RIAGetNotReadyTypes_xUser]
@user_id int
as
set nocount on

declare @NotReadybyCampACD int
select @NotReadybyCampACD = valor from ccsettings where setting_id = 135

declare @NotReadyRestricted tinyint
set @NotReadyRestricted =0
select @NotReadyRestricted = NotReadyRestricted from ccUsers where User_id = @user_id

if (@NotReadybyCampACD = 0)
	begin
		select a1.TipoNotReady_id, Descripcion, frame, 
		dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()) as NumEvents, @NotReadyRestricted NotReadyRestricted
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on a1.tiponotready_id = a2.tiponotready_id
		inner join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a1.TipoNotReady_id > 0 and a1.IsSup = 0
	end
else if (@NotReadybyCampACD = 1)
	begin
		select a1.TipoNotReady_id, Descripcion, frame, dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()) as NumEvents, @NotReadyRestricted NotReadyRestricted
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id = a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = 0
		and a4.idCampACD in (select distinct(inbound_id) from ccInboundAgentes where user_id = @user_id)
		AND a4.type = 0
		union
		select a1.TipoNotReady_id, Descripcion, frame, dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate())as NumEvents, @NotReadyRestricted NotReadyRestricted
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id = a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = 0
		and a4.idCampACD in (select distinct(cam_id) from ccCampsAgente where user_id = @user_id)
		AND a4.type = 1
	end

return(0)

set nocount off'
    EXEC(@Sql)

    set @process = 'Alter SP -- ccsp_RIACampsSupAgent'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIACampsSupAgent]
@loginAgent varchar(30),
@PassAgent varchar(32),
@PassSup varchar(32)
AS
SET NOCOUNT ON
select 
 (select count(distinct cam_id) as x from ccCampsAgente where cam_id in
	(select sca.cam_id 
	from ccsupervisorcam sca join ccusers usr on sca.user_id=usr.user_id
	where sca.tipo = 1 and (usr.tipoUser_id&2=2) and (usr.password=@PassSup or usr.password=dbo.md5(@PassSup))
 ) and user_id in (select user_id from ccusers where tipoUser_id = 1 and login = @loginAgent))
+
 (select count(distinct inbound_id) from ccInboundAgentes where inbound_id in
	(select sca.cam_id 
	from ccsupervisorcam sca join ccusers usr on sca.user_id=usr.user_id
	where sca.tipo = 0 and (usr.tipoUser_id&2=2) and (usr.password=@PassSup or usr.password=dbo.md5(@PassSup))
 ) and user_id in ( select user_id from ccusers where tipoUser_id = 1 and login = @loginAgent))
 as Accountant
SET NOCOUNT OFF'
    EXEC(@Sql)

    set @process = 'Add Column -- ccUsers.LoginAttempts --LoginAttempts Number of times users have tried to login to the system.'
    set @Sql= 'IF not exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = ''LoginAttempts'' AND TABLE_NAME = ''ccUsers'')
	ALTER TABLE ccUsers ADD  LoginAttempts int default 0'
    EXEC(@Sql)

    set @process = 'Add column ccUsers.LastLoginAttempt -- LastLoginAttempt day and hour whene the user tried to access the system for the last time.'
    set @Sql= 'IF not exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = ''LastLoginAttempt'' AND TABLE_NAME = ''ccUsers'') 
BEGIN
	ALTER TABLE ccUsers ADD  LastLoginAttempt datetime;

	ALTER TABLE ccUsers 
		ADD CONSTRAINT Default_LastLoginAttempt
		DEFAULT GETDATE() FOR LastLoginAttempt
END
'
    EXEC(@Sql)

	set @process = 'update ccUsers.LoginAttempts'
    set @Sql= 'UPDATE ccUsers SET LoginAttempts = 0 WHERE LoginAttempts IS NULL'
    EXEC(@Sql)

	set @process = 'update ccUsers.LastLoginAttempt'
    set @Sql= 'UPDATE ccUsers SET LastLoginAttempt = GETDATE() WHERE LastLoginAttempt IS NULL'
    EXEC(@Sql)

	set @process = 'Setting_ID 197 Time the user will wait before being able to access the system after severar bad login attempts'
    set @Sql= 'IF not exists (SELECT * FROM ccSettings WHERE setting_id = 197)
	INSERT INTO ccSettings 
			(setting_id,valor,
			descripcion,
			Status, Tipo,
			detalle,
			description,
			bLoadSettings, validate)
	VALUES	(197, ''5'',
			''Tiempo de bloqueo para Login Erroneo (mins)'',
			1, ''x'',
			''Tiempo (mins) que el usuario tendra que esperar antes de volverse a Logear, luego de producirse demasiados intentos de login.'',
			''Time to block user after several Bad Login Attempts (mins)'',
			1,''^\d{1,3}$'')'
    EXEC(@Sql)
	set @process = 'CW-1439 Setting_ID 201 Cadena de conexion(ODBC) para consultar una BD externa en la llamada manual'
    set @Sql= '
	IF not exists (SELECT * FROM ccSettings WHERE setting_id = 201)
	INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
	VALUES	(201, 
			''Driver={SQL Server};Server=192.168.0.112;Database=ccenterRIA;Uid=sa; Pwd=nuxiba;'',
			''Cadena de conexion(ODBC) para consultar una BD externa en la llamada manual'',	
			1,
			''AGT'',
			''Cadena de conexion(ODBC) para la BD externa a la cual se va a conectar el agente para buscar contactos en la ventana de llamada manual. Si no aplica el valor debe venir vacio'',
			''Database connection string(ODBC) for manual call'',
			0,
			 ''*'')
	'
    EXEC(@Sql)
	set @process = 'Setting_id 256 Number of chances the user have to try accessing the system'
    set @Sql= 'IF not exists (SELECT * FROM ccSettings WHERE setting_id = 198)
	INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
	VALUES	(198, ''5'', ''Cantidad permita de intentos en Login'',	1,''x'',
			''Numero de veces que un usuario puede intentar ingresar al sistema antes de que se bloquee.'',
			''Number of Login Attempts available before blocking'',	1, ''^\d{1,3}$'')'
    EXEC(@Sql)

	set @process = 'Setting_id 183 WebRTC Configuration Se modifica la descripcion del setting'
    set @Sql= 'UPDATE ccSettings set detalle =''Configuración para WebRTC <type>|<ws[,ws_gw]>|<private_identity>|<public_identity>|<password>|<realm>|<ice_servers>|<IMS>|<WebBreaker>|<ServerMaxReconnection>|<ServerReconectionTimeout>|<authorizationUser>|<register>|<iceCheckingTimeout>|<userAgentString>|<traceSip>|<builtinEnabled>|<level>'' where setting_id = 183'
    EXEC(@Sql)

	set @process = 'Setting_id 183 WebRTC Configuration Se modifica la descripcion del setting'
    set @Sql= 'UPDATE ccSettings set description =''WebRTC Configuration <type>|<ws[,ws_gw]>|<private_identity>|<public_identity>|<password>|<realm>|<ice_servers>|<IMS>|<WebBreaker>|<ServerMaxReconnection>|<ServerReconectionTimeout>|<authorizationUser>|<register>|<iceCheckingTimeout>|<userAgentString>|<traceSip>|<builtinEnabled>|<level>'' where setting_id = 183'
    EXEC(@Sql)


	set @process = 'CW-1170/CW-1347  -- Alter ccsp_AgentGetCalificaciones'
    set @Sql= 'ALTER procedure [dbo].[ccsp_AgentGetCalificaciones]
@InOut tinyint, --0 in, 1 out
@cam_id int, --ADC or CAMP Id
@isXml bit=1

AS
set nocount on
declare @sql varchar(max)

IF @InOut = 0 BEGIN
if exists(
	select calif.calif_id from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
	 declare @relationCamId int
	select @relationCamId =cam_id from ccInbound where Inbound_id=@cam_id
	if @relationCamId is null set @relationCamId=0

	set @sql =''
	select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.orden "selection!1!califorden",
		isnull(calif.EndConversation,0) "selection!1!endConversation",
		null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!orden",  null "subSelection!2!endConversation",
		isnull(calif.CanReprogram,0) "selection!1!canReprogram", null "subSelection!2!canReprogram"
		from ccTipoCalif calif
	 inner join ccCalifCamp camp on camp.calif_id=calif.calif_id 
	 and camp.cam_id=''+convert(varchar(max), @cam_id)+'' and  camp.tipo = ''+convert(varchar(max), @InOut)+''
	 left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	 left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	 where calif.CanReprogram=0 or (
		calif.CanReprogram=1 and ''+convert(varchar(max), @relationCamId)+''>0
	 )
	 union
	 select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", calif.orden "selection!1!califorden", isnull(calif.EndConversation,0) "selection!1!endConversation",
		sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", cast(sb.orden as int) "subSelection!2!orden" ,isnull(sb.EndConversation,0) "subSelection!2!endConversation",
		null "selection!1!canReprogram", isnull(sb.CanReprogram,0) "subSelection!2!canReprogram"
		from ccTipoCalif calif
		inner join ccCalifCamp camp on camp.calif_id=calif.calif_id and camp.cam_id=''+convert(varchar(max), @cam_id)+'' and  camp.tipo = ''+convert(varchar(max), @InOut)+''
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where sb.califsub_id is not null
		and (
			sb.CanReprogram=0 or
			(sb.CanReprogram=1 and ''+convert(varchar(max), @relationCamId)+''>0)
		)''
	  
	  if @isXml=1 begin
		set @sql= @sql+'' order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type''
	  end
	  else begin 
	  set @sql=''select 
				tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''''''') as Description,
				"selection!1!califorden" as Orden, "selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
				isnull("subSelection!2!string",'''''''') as SubDescription, isnull("subSelection!2!orden",0) as SubOrden,	
				isnull("subSelection!2!endConversation",0) as SubEndConversation, 
				isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
			from (  '' + @sql+'' )X''
	  end
	  print (@sql)
	  exec (@sql)
  end
 return(0)
 END

IF @InOut = 1 BEGIN
 if exists(
	select calif.calif_id from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
	left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
	set @sql =''
		select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.keepDial "selection!1!keepOnDial",
		calif.orden "selection!1!califorden", isnull(calif.finishPreview,0) "selection!1!finishPreview", null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!keepOnDial",
		null "subSelection!2!orden",   isnull(calif.CanReprogram,0) "selection!1!canReprogram", null "subSelection!2!canReprogram"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = ''+convert(varchar(max), @cam_id)+'' and tipo = ''+convert(varchar(max),@InOut)+''
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", null "selection!1!keepOnDial",
		calif.orden "selection!1!califorden", isnull(calif.finishPreview,0) "selection!1!finishPreview", sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string",
		sb.keepDial "subSelection!2!keepOnDial",
		cast(sb.orden as int) "subSelection!2!orden",
		null "selection!1!canReprogram", isnull(sb.CanReprogram,0) "subSelection!2!canReprogram"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = ''+convert(varchar(max), @cam_id)+'' and tipo =''+convert(varchar(max),@InOut)+'' and sb.califsub_id is not null	''
		if @isXml=1 begin
			set @sql= @sql+'' order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type''
		end
		else begin 
		  set @sql=''select 	tag as Tag, isnull(parent,0) Parent, "selection!1!id" as Id,isnull("selection!1!string",'''''''') as Description,
					isnull("selection!1!keepOnDial",'''''''') as KeepOnDial,
					"selection!1!califorden" as Orden, "selection!1!finishPreview" FinishPreview, isnull("subSelection!2!id",0) as SubId,
					isnull("subSelection!2!string",'''''''') as SubDescription,isnull("subSelection!2!keepOnDial",0) as SubKeepOnDial,
					isnull("subSelection!2!orden",0) as SubOrden,
					isnull("selection!1!canReprogram", 0) CanReprogram,  isnull("subSelection!2!canReprogram",0) SubCanReprogram
					
				from (  '' + @sql+'' )X''
		  end
		  print @sql
		exec (@sql)
  end
 return(0)
 END

IF @InOut = 10
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSub S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=1 and S.califSub_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

IF @InOut = 11
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSubOut S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=0 and S.califSubOut_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

set nocount off'
    EXEC(@Sql)

    set @process = 'CW-1160 -- ccsp_AgentLogINOUT'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]
@UserID smallint,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@TipoMov tinyint,	-- 0= LogOut,  1=LogIN,	3=Consulta
@fecha datetime=null
AS
set nocount on
if @fecha is null set @fecha=getdate()

declare @hourlogin   varchar(8)
declare @sessionsecs int
declare @sessiontime varchar(8)
declare @fecha_ini datetime

IF  @TipoMov=1
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov,fecha ) Values( @UserID, @Extension, 1, @fecha)
	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID)	VALUES( @UserID, 0, 0, @fecha,0,0,1,0)

	Update c Set User_id=@UserID from ccPosicion c WITH (INDEX (IX_ccPosicion)) Where Computer =@Computer
	update c set user_id = 0 from ccPosicion c WITH (INDEX (IX_ccPosicion_2)) where Computer <> @Computer and user_id = @UserId
	update ccUsers set TipoStatusAge_id=3 where User_id=@UserID

	if exists(select valor from ccSettings where tipo=''AGT'' and Status=''1'' and setting_id=''53'' and valor=2)
	 begin
	 	if not exists (select axLic_Desc from axLicG729_Data where axLic_Status=1 and pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid))
		 begin
	 		raiserror(''Error. Without License'', 18, 1)
			return(0)
		 end

		update axLicG729_Data set axLic_Status=2 where axLic_Status=1 and pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid)
		select ''0'' CPLic
		return(0)
	 end

	return(0)
 END

IF @TipoMov=0
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov, fecha ) Values( @UserID, @Extension, 0, @fecha )
	Update c Set User_id= 0 from ccPosicion c WITH (INDEX (IX_ccPosicion_2)) Where Computer =@Computer or user_id = @Userid
	update ccUsers set TipoStatusAge_id=0 where User_id=@UserID

	if exists(select valor from ccSettings where tipo=''AGT'' and Status=''1'' and setting_id=53 and valor=''2'')
	 begin
		update axLicG729_Data set axLic_Status=0, pos_id=null, fecha_log=null where pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid)
	 end

	return(0)
 END

IF @TipoMov=3
 BEGIN
    select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

	select @hourlogin = convert(varchar(8), isnull(min(fecha), getdate()), 114)
	       from ccLogLogin where TipoMov=1 and user_id=@UserID and fecha >= @fecha_ini

    SELECT @sessionsecs = isnull (case
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
			THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
			         convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END, 0)
		FROM ccLogLogin where user_id=@UserID and fecha > dateadd(hh, -10, getdate())

    SELECT @sessiontime = RIGHT(''0'' + CONVERT(varchar(6),  @sessionsecs / 3600),       2) + '':'' +
                          RIGHT(''0'' + CONVERT(varchar(2), (@sessionsecs % 3600) / 60), 2) + '':'' +
                          RIGHT(''0'' + CONVERT(varchar(2),  @sessionsecs % 60),         2)

    select ''HourLogin'' = @hourlogin, ''SessionTime'' = @sessiontime, ''SessionSecs'' = @sessionsecs
	return(0)
 END'
    EXEC(@Sql)

    set @process = 'CW-1160 -- alter SP ccsp_AgentSetCallStatus'
    set @Sql= 'ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)='''',
@isChatCall bit = 0
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4 begin
			Update ccoCallsOUT with(rowlock) Set cal_Inicio=getdate(), statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end Where cal_id=@cal_id
		end
		else if @TipoMov = 14
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id

		return(0)
	end


	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN =callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select distinct(callout_id) from ccRIAUpdateCallBack_Abandon with(rowlock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock)
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock)
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'
    EXEC(@Sql)


    set @process = 'CW-1160 -- alter SP ccsp_SaveLogoutLastState'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_SaveLogoutLastState]
@UserID smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@call_id int=0,
@tDialog int =0 ,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@fecha datetime=null
AS
set nocount on

if @fecha is null set @fecha=getdate()

exec ccsp_AgentLogINOUT @UserID=@UserID,@Extension=@Extension,@Computer=@Computer,@TipoMov=0,@fecha=@fecha
exec ccsp_SaveStatusAgent @User_id=@UserID,@TipoStatusAge_id=@TipoStatusAge_id,@TipoNotReady=@TipoNotReady,@tStatus=@tStatus,@TipoCall=@TipoCall,@Camp=0,@callout_id=0,@call_id=@call_id,@isLogout=1,@tDialog =@tDialog,@Fecha4=@fecha
'
    EXEC(@Sql)

    set @process = 'CW-1160 -- Alter SP ccsp_SaveStatusAgent'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null
AS
if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

	declare @cam_id int,@surveycamId int
	declare @cal_telefono varchar(30)
	declare @cal_key varchar(20)
	declare @inbound_id int
	declare @callBackSurveyClients bit
	declare @cal_whoHung tinyint
	declare @cal_tDialog int
	declare @cal_tNotas int
	declare @cal_tNotaOri int
	declare @tMinAVRS smallint
	declare @calInicio datetime
	declare @sumCall int
	set @cal_tNotas =0
	set @cal_tNotaOri=0
	--4 Dialog,6 Notas, 27 Notas Fallida
	if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
		if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
		if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


		if @TipoCall = 0 begin --IN
			select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

			if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
				if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end
		else begin --OUT
			select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
			@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
			set @Camp=@cam_id

			if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
				if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end

		select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

		if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1
		begin
			insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
		end

		if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
			--Valida que el agente no pudo guardar el status antes de desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
				INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
		end


	end


	if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id


		---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
		if @call_id>0 begin
			if @TipoCall = 0 begin --IN

					select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

					if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
						if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
							begin
								if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
								begin
									insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
									values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
								end
							end
					end
			end	--@TipoCall = 0
			else begin	--OUT



				select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
				select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
					from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
					where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

				if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
					if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
					begin
						insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
						values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
					end
				end
			end
		end--@isTransferSurvey = 0 and @callout_id>0


	 end

	 
	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )	

	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end

			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
    EXEC(@Sql)


	set @process = 'CW-711 -- Alter SP ccsptelefonosTransferencia'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsptelefonosTransferencia]
@userID INT
as
set nocount on

BEGIN
declare @value bit
declare @IDArea int
set @value = 0
set @IDArea =1
select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

select @IDArea =IDArea from ccUsers where User_id =@userID
if @value = 1
	begin
		select numtra_id id, nombre as  name, tel as number, isnull(IDArea,@IDArea) as id_area from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre
	end
	else
	begin
		select numtra_id id, isnull(cast(IDArea as varchar(20) )+'' - ''+  nombre , nombre ) as name, tel as number, isnull(IDArea,@IDArea) as id_area from telefonosTransferencia  order by nombre
	end
END'
    EXEC(@Sql)


	set @process = 'CW-711 -- Alter SP ccsp_AgentTransfLstArea'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int

set @value = 0
select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

	IF @value = 0
		begin
			select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name from ccusers cu join
			(
				select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
				join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
			)
			x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
			Order by name
		end

	if @value = 1
		begin
			if (@current <> 0)
				begin
					select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
					Order by name
				end
			else
				begin
					select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select IDArea from ccUsers where User_id = @userID)
					Order by name
				end
		end
END
set nocount off'
    EXEC(@Sql)


	set @process = 'CW-711 -- Alter SP ccsp_AgentGetEspecialidadesActivas'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
@userID INT,
@current integer = 0
as
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @value int

	SET DATEFIRST 1

	select @fecha =  getdate()
	select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)

	set @value = 0
	select @value = valor from ccSettings where setting_id = 191

	if @value = 0
		begin
			select -1 as inbound_id, ''IVR'' as name
			union
			select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
			(
				select inbound_id from ccInboundHorarios where horario_id in
				(
					select horario_id  from ccHorarios
					where
					( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
					AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
					AND (
						Lunes  = @dia or
						Martes *2 = @dia or
						Miercoles*3 = @dia or
						Jueves*4 = @dia or
						Viernes*5 = @dia or
						Sabado*6 = @dia or
						domingo*7 = @dia
					)
				)
			)
			and inbound_id <> @current
			-- las activas
			and status <> 0
			-- las que tienen agentes firmados
			-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
			order by 2
		end

	if @value = 1
		begin
			if (@current <> 0)
				begin
					select -1 as inbound_id, ''IVR'' as name
					union
					select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
					(
						select inbound_id from ccInboundHorarios where horario_id in
						(
							select horario_id  from ccHorarios
							where
							( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
							AND (
								Lunes  = @dia or
								Martes *2 = @dia or
								Miercoles*3 = @dia or
								Jueves*4 = @dia or
								Viernes*5 = @dia or
								Sabado*6 = @dia or
								domingo*7 = @dia
							)
						)
					)
					and inbound_id <> @current
					-- las activas
					and status <> 0
					and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
					order by 2
				end
			else
				begin
					select -1 as inbound_id, ''IVR'' as name
					union
					select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
					(
						select inbound_id from ccInboundHorarios where horario_id in
						(
							select horario_id  from ccHorarios
							where
							( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
							AND (
								Lunes  = @dia or
								Martes *2 = @dia or
								Miercoles*3 = @dia or
								Jueves*4 = @dia or
								Viernes*5 = @dia or
								Sabado*6 = @dia or
								domingo*7 = @dia
							)
						)
					)
					and inbound_id <> @current
					-- las activas
					and status <> 0
					and IDArea in (
					select IDArea from ccUsers where User_id = @userID
					)
					-- las que tienen agentes firmados
					-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
					order by 2
				end
		end'
    EXEC(@Sql)

	
	set @process = 'CW-703 -- Alter SP ccsp_RIACampsManualCall'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
		@UserID int,
		@onChat int = 0
		AS
		set nocount on

		if (@onChat = 0)
		begin
			declare @mod smallint
			select @mod = defCampaing from ccRIACat_Areas A
			where A.IDArea = (select IDArea from ccUsers where User_id = @UserID) 

			select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [default]
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			where ca.user_id = @UserID and cam_modoManual = 1
			order by cam_descripcion
		end
		else
			select distinct c.cam_id, c.cam_descripcion
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			where ca.user_id = @UserID and manualCallOnChat = 1
			order by cam_descripcion

set nocount off'
    EXEC(@Sql)    

    set @process = ''
    set @Sql= ''
    EXEC(@Sql)

	set @process = 'CW-1274 -- Alter SP ccsp_RIAAgentGetDialMask'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
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
			if ((left(ltrim(rtrim(@tel)),2) =''0'') and len(ltrim(rtrim(@tel))) = 11)
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

--Australia
if @country = 9
begin

	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if (left(ltrim(rtrim(@tel)),2) = ''04'' and len(ltrim(rtrim(@tel))) = 10)
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''04'' and len(ltrim(rtrim(@tel))) = 10)
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
			if ((Len(ltrim(rtrim(@tel))) = 8) or
				(''0'' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or
				(left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
			 begin
				set @value = 6
			 end
		 end
	 end
end

--Brasil
if @country = 10
	begin
		declare @lon int
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)
			if
				(@lon in(7,8) and left(@tel,1) in (''6'',''7'',''8'',''9'') )
				or (@lon=9 and left(@tel,1) = ''9'' )
				or (@lon=10 and substring(@tel,3,1) in (''6'',''7'',''8'',''9'') )
				or (@lon=11 and substring(@tel,3,1) = ''9'')
				--or (@lon=12 and substring(@tel,5,1) in (''6'',''7'',''8'',''9'') )
				--or (@lon=13 and substring(@tel,5,1) = ''9'' )
				--or (@lon=13 and substring(@tel,5,1) = ''9'' )
				begin
					set @value = 4
				end
		end

		--Restringe larga distancia
		if(@value=0)
		begin
			if ((@mask & 2) > 0)
			begin
				select @lada=valor from ccSettings WHERE setting_id=17
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)
				if  @lon>=10 and left(@tel,2) <> @lada
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
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)
				if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
				begin
					set @value = 6
				end
			end
		end

		--Restringe por cobrar
		if(@value=0)
		begin
			declare @llamadasPorCobrar varchar(4);
			select @llamadasPorCobrar= valor from ccSettings where setting_id=126
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)
			if @lon >= 12 and  left(@tel,2) = ''90'' and @llamadasPorCobrar=''0''
			begin
				set @value = 10 -- pone para llamadas por cobrar
			end
		end

	end -- Termina Brasil


--Guatemala
if @country = 11
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''3,4,5'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,6,7'') > 0
					set @value = 6
			end
		end

	end -- Termina Guatemala

--Costa Rica
if @country = 12
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''5,6,7,8'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,3,4'') > 0
					set @value = 6
			end
		end

	end -- Termina Costa Rica

--Salvador
if @country = 13
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2'') > 0
					set @value = 6
			end
		end

	end -- Termina Salvador

--Spain
if @country = 14
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''8,9'') > 0
					set @value = 6
			end
		end

	end -- Termina Spain

select @value Response
'
    EXEC(@Sql)

	
	set @process = 'CW-1274 -- Alter SP ccsp_CheckTarifas'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CheckTarifas]
@tel varchar(255)
AS
set nocount on

--declare @tel varchar(255)
declare @countryId tinyint
declare @len varchar(10)
declare @porcentaje tinyint
declare @typeLlamada tinyint

if (select valor from ccsettings where setting_id=164)= 1 begin

	set @tel = dbo.limpia(@tel)
	set @len = convert(varchar(10),len(@tel))
	
	select @countryId=valor from ccsettings where setting_id=104

	select @typeLlamada=tipoLlamada_id
	from cstoTipoLlamada where country_id=@countryId and prefijo = substring(@tel,0,CHARINDEX(''%'',prefijo))+''%'' and longitud like ''%''+@len+''%'' 


	if exists (select * from cstoTarifa where tipoLlamada_Id= @typeLlamada)  select 0 Response ,''Existe tarifa'' Note
	else select 11 Response ,''No existe tarifa'' Note

end
else begin 
	select 0 Response
end

set nocount off
'
    EXEC(@Sql)


	    set @process = 'CW-1274 Alter SP -- ccsp_RIADialerAssignment'
    set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_RIADialerAssignment]
@User_Id smallint,
@cam_id smallint,
@dialer_id varchar(4000),
@Type2 tinyint,
@Type tinyint
AS
set nocount on
declare @SQL as nvarchar(4000), @nUser_id as nvarchar(10), @params as nvarchar(1000)

If @Type=0--get ports
 begin
	select a.dialer_id, a.puerto, a.Descripcion, b.descrip from ccoDialers a with(index([IX_ccoDialers_I]),nolock)
	inner join cstoProvedor b with(index(PK_cstoProvedor),nolock) on a.provedor_id=b.provedor_id
	order by a.dialer_id
	return(0)
 end

If @Type=1--get cams
 begin
	SELECT a1.cam_id, cam_descripcion FROM ccCamps a1 with(nolock)
	inner join ccRIACampsGraph a2 with(nolock) on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 with(nolock) on(a2.graphic_id=a3.graphic_id)
	where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	order by cam_descripcion
	return(0)
 end

If @Type=2--get port/cam relation
 begin
	select c.cam_id, cd.dialer_id, d.descripcion,
	d.puerto, e.descrip from ccCamps c with(nolock)
	left join ccoDialerCamp cd on cd.cam_id=c.cam_id
	left join ccoDialers d with(index(IX_ccoDialers_I),nolock) on cd.dialer_id=d.dialer_id
	inner join cstoProvedor e with(index(PK_cstoProvedor),nolock) on d.provedor_id=e.provedor_id
	where c.cam_id=@cam_id
	ORDER BY c.cam_id, cd.dialer_id
	return(0)
 end

If @Type=3--delete port/dialer relation
 begin
	If @Type2=1--Sistema
	 begin
		set @nUser_id=@User_Id
		set @sql=''delete ccoDialerCamp with(rowlock) where dialer_id in('' + @dialer_id + '')''
		execute sp_executesql @sql
		return(0)
	 end

	If @Type2=2--Camp
	 begin
		delete ccoDialerCamp with(rowlock) where cam_id=@cam_id and dialer_id=@dialer_id
		return(0)
	 end
 end

If @Type=4--insert new relation
 begin
	If @Type2=1--Sistema
	 begin
		set @nUser_id=@User_Id
		set @sql=''insert ccoDialerCamp(cam_id, dialer_id)
		select a.cam_id, b.dialer_id from ccCamps a, ccoDialers b where
		b.dialer_id in('' + @dialer_id + '') and not exists(
		select c.cam_id, c.dialer_id from ccoDialerCamp c
		where b.dialer_id=c.dialer_id and a.cam_id=c.cam_id)''
		execute sp_executesql @sql
		return(0)
	 end

	If @Type2=2--Camp
	 begin
		set @params=''@Ncam_id int''
 		set @sql=''insert ccoDialerCamp(cam_id, dialer_id) select distinct @Ncam_id,
 		dialer_id from ccCamps, ccoDialers where dialer_id not in(select dialer_id
 		from ccoDialerCamp where dialer_id in('' + @dialer_id + '')and cam_id=@Ncam_id)
		and dialer_id in('' + @dialer_id + '')''
		execute sp_executesql @sql, @params, @Ncam_id=@cam_id
		return(0)
 	 end
 end

If @Type=5--Get existance of dialers
 begin
	if exists (select c.cam_id, cd.dialer_id, d.descripcion,
			   d.puerto, e.descrip from ccCamps c with(nolock)
			   left join ccoDialerCamp cd with(nolock) on cd.cam_id=c.cam_id
			   left join ccoDialers d with(nolock) on cd.dialer_id=d.dialer_id
			   inner join cstoProvedor e with(nolock) on d.provedor_id=e.provedor_id
			   where c.cam_id = @cam_id)
		select 0 Response
	else
		select 13 Response
	return(0)
 end
'
    EXEC(@Sql)

	set @process = 'CW-1346 ALTER ccsptelefonosTransferencia'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsptelefonosTransferencia]
@userID INT
as
set nocount on

BEGIN
declare @value bit
declare @IDArea int
set @value = 0
set @IDArea =1
select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

select @IDArea =IDArea from ccUsers where User_id =@userID
if @value = 1
	begin
		select numtra_id id, nombre as  name, tel as number, isnull(IDArea,@IDArea) as id_area 
		from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre asc 
	end
	else
	begin
		select numtra_id id, isnull(cast(IDArea as varchar(20) )+'' - ''+  nombre , nombre ) as name, 
		tel as number, isnull(IDArea,@IDArea) as id_area 
		from telefonosTransferencia  order by nombre asc
	end
END'
    EXEC(@Sql)

set @process = 'CW-1346 ccsp_AgentTransfLstArea'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int

set @value = 0
select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

	IF @value = 0
		begin
			select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name from ccusers cu join
			(
				select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
				join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
			)
			x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
			Order by name asc
		end

	if @value = 1
		begin
			if (@current <> 0)
				begin
					select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
					Order by name asc
				end
			else
				begin
					select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select IDArea from ccUsers where User_id = @userID)
					Order by name asc
				end
		end
END
set nocount off'
    EXEC(@Sql)

    set @process = ''
    set @Sql= ''
    EXEC(@Sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end