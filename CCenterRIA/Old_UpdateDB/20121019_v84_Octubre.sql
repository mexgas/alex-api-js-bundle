/*
Autor: Raymundo González
Fecha: 2012/10/19
Descripcion: 
	Se agrega columna timeZoneRule en la tabla ccCamps
	Se modifica el SP ccsp_RIAUpdateCamConfig que graba el nuevo valor de timeZoneRule para la campaña en cuestión
	Se modifica el SP ccsp_RIAConfCamp que devuelve el nuevo valor de timeZoneRule para la campaña consultada en configuración de campañas
	Se modifica el SP AgentCheckCamps que devuelve valor de timeZoneRule para la acampaña consultada
	Se crea el SP ccsp_ManualCallApplyTimeZoneRules  para validar zona horaria para el telefono marcado manualmente en la campaña correspondiente

Version requerida: 83
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '84'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @Sql = 'alter table ccCamps add timeZoneRule int not null default 0'

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
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null
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
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule)
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
	 DNCScrub, callerIdDesc, timeZoneRule
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'

	EXEC(@Sql)

		set @Sql = 'ALTER PROCEDURE [dbo].[AgentCheckCamps]
@cam_id as smallint,
@user_id as smallint,
@forceManualCall as tinyint = 0
AS

declare @isValidCall as int
declare @timeZoneRule as int

select @isValidCall = count(*) from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
select @timeZoneRule = 0

if @isValidCall <> 0 and @forceManualCall = 0 begin
	select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule from ccCamps with(nolock) where cam_id = @cam_id
end

select @isValidCall as Validation, @timeZoneRule as TimeZoneRule'

	EXEC(@Sql)

		set @Sql = 'CREATE procedure [dbo].[ccsp_ManualCallApplyTimeZoneRules] @campid as int, @tel varchar(15) as

set nocount on

declare @bIsDaylight bit
declare @revHorario bit
declare @country_id int
declare @iZonas int
declare @Sql varchar(MAX)
declare @izonahoraria int
declare @izonahoraria_verano int

create table #TimeZone(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
izonahoraria int,
izonahoraria_verano int
)

/*** Revisa zona horaria incluyendo de verano ***/
select @izonahoraria = dbo.fnGetTimeZone(@tel,0)
select @izonahoraria_verano = dbo.fnGetTimeZone(@tel,1)

insert into #TimeZone
values (@campid,@tel,@izonahoraria,@izonahoraria_verano)

/*** Valida el pais y la lada configurada ***/
SELECT @country_id = valor 
FROM ccSettings 
WHERE setting_id = 104

select @revHorario = valor 
from ccsettings 
where setting_id = 112

/*** Coloca el primer dia de la semana a Lunes ***/
SET DATEFIRST 1

/*** Se revisa si es horario de verano ***/
select @bIsDaylight = isnull(case when getdate()between inicio and fin then 1 else 0 end,1)
from ccHorarioVerano 
where year(getdate()) = year(inicio) 
and country_id = @country_id

/*** Se revisa si la campaña tiene horarios configurados ***/
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
	begin
		declare @horaUniversal as datetime 
		select @horaUniversal = getutcdate()

		select @iZonas = sum(distinct tz_id)
		from (select tz_id,
			  datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
			  datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
			  datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
			  from ccTimeZones )zonas 
			  inner join cchorarios on((hora > HoraInicio OR(hora = HoraInicio AND minuto >= MinInicio))
			  AND (hora < HoraFin OR(hora = HoraFin AND minuto <= MinFin))
			  AND (Lunes = dia or
				   Martes*2 = dia or
				   Miercoles*3 = dia or
				   Jueves*4 = dia or
				   Viernes*5 = dia or
				   Sabado*6 = dia or
				   domingo*7 = dia)
			 ) 
		inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id = ccCampsHorarios.horario_id 
		and ccCampsHorarios.cam_id = @campid

		if @iZonas is null 
			begin
				SELECT 0 as CanCall
				return
			end
	end 
else
	begin
		if @revHorario = 0
			begin
				select @iZonas = sum(distinct tz_id)from ccTimeZones
			end
		else
			begin
				select @iZonas = Null
			end
	end

set @Sql = ''CREATE TABLE #NEW_JOBS(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS)

INSERT #NEW_JOBS
SELECT cam_id, '' + @tel + ''
FROM #TimeZone
WHERE cam_id = '' + cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
and (((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0))

if (SELECT count(*) FROM #NEW_JOBS where len(cal_telefono)>0) > 0 
	begin 
		select 1 as CanCall
	end
else
	begin
		select 0 as CanCall
	end

DROP table #NEW_JOBS''

exec(@Sql)

DROP table #TimeZone

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
