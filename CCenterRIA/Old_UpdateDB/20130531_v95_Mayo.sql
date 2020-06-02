/*
Autor: Raymundo Gonzalez
Fecha: 2013/05/31
Descripcion:
	Se actualiza la tabla ccsettings en el campo valor del setting 128 (Ivinex)
	Se actualiza la tabla ccsettings en el campo Tipo y bLoadSettings de los settings 121 y 122 (Ivinex)
	Se actualiza la tabla ccsettings en el campo detalle del setting 53
	Se inserta en la tabla ccsettings el setting 129 para configuracion de login remoto usando Ivinex
	Se inserta en la tabla ccsettings el setting 130 para configuracion del home page del admin
	Se inserta en la tabla ccsettings el setting 131 para configuracion de los parametros del webphone Mizuphone
	Se inserta en la tabla ccmenus el menu 4210 para reporte de montepio
	Se crea el indice IX_ccoCallsOut12, IX_ccoLogDials_4 y IX_ccRIARegistryLists para mejora de performance
	Se crea el SP ccsp_RIASearchLoading para realizar busquedas de las cargas de registros realizadas
	Se modifica el SP ccsp_AgentSetCallStatus para mejora de performance y fix en inserción del campo cal_key en la tabla ccoCallsOUTSource
	Se modifica el SP ccsp_OUTGetNewJobs para mejora de performance
	Se modifica el SP ccsp_OUTGetNewProviderJobs para mejora de performance
	Se modifica el SP ccsp_OUTResetJobs para mejora de performance
	Se modifica el SP ccsp_RIA_mnuReciclar para mejora de performance
	Se modifica el SP ccsp_RIALoadWorkGroup para fix en logitud de campo de tabla temporal

	*** DLL de carga ***
	Se inserta en la tabla ccsettings el setting 254 para Loader LogLevel
	Se crea la tabla xxLog en caso de no existir
	Se modifica la tabla xxclientecarga agregando el campo User_id
	Se crea la tabla xxClienteConexiones
	Se crea el SP xx_ClienteActividad
	Se crea el SP xx_ChecaVersion
	Se crea el SP ccsp_OUTCancelDialJOB
	Se crea el SP xx_OUTInsertNewJOBS_WT_Camp
	Se crea el SP xx_Inserta

Version requerida: 94
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '95'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccsettings - Update(1)'
		set @Sql='update ccsettings set valor = ''1'' where setting_id = 128'
		
	EXEC(@Sql)

		set @process = 'ccsettings - Update(2)'
		set @Sql='update ccsettings set Tipo = ''AGT'',bLoadSettings = 1 where setting_id in(121,122)'
		
	EXEC(@Sql)
	
		set @process = 'ccsettings - Update(3)'
		set @Sql='update ccsettings 
set detalle = ''Indica si se ocupara sipphoneWeb o un softphone externo.Dependiendo de este valor el agente por default abrira indexsip.aspx, indexg729.aspx o index,aspx. 0-otro / 1-SipPhoneWeb / 2-SipPhoneWeb con g729 (depende de licencias disponibles) / 3-Mizu''
where setting_id = 53'
	
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert(1)'
		set @Sql='insert into ccsettings 
values(129,'''',''Configuracion url remoteLogin usando Ivinex'',1,''AGT'',''Configuracion url remoteLogin usando Ivinex'',''Configuration url remoteLogin using Ivinex'',1)'
		
	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert(2)'
		set @Sql='insert into ccsettings(setting_id, valor, descripcion, status, tipo, detalle, description, bloadsettings)
values(130,1,''Tipo de soft Phone para sitio de Admin'',1,''ADM'',''Dependiendo de este valor el admin por default abrira un home page distinto. 0-AdministratorRIA.aspx; 1-AdministratorRIASip.aspx; 2-SipPhoneWeb con g729(depende de licencias disponibles); 3-AdministratorRIAMizu.aspx'',''Admin soft phone type'',0)'

	EXEC(@Sql)
	
		set @process = 'ccsettings - Insert(3)'
		set @Sql='Insert into ccSettings 
values (131, ''0|2|0|0'', ''Parámetros Mizuphone'', 1, ''AGT'', ''Parámetros de configuración para Mizuphone: Use_G729|Use_Stun|Use_Rport|Log_Level. Use_G729: Utilizar el códec G729 con mayor prioridad que el códec G711 (0=no, 1=si). Use_Stun: Utilizar protocolo stun (-1=IP privada, 0=no, 1=sólo para NAT simétrica, 2=siempre, 3=incluso con IP pública). Use_Rport: Verifica rport en la señalización SIP (en header VIA). Log_Level: Nivel de la traza (0=no notificar al usuario, entre 1 y 6=mensajes de debug). Use_Stun y Use_Rport funcionan con el setting 119 en 1'', ''Mizuphone Parameters'', 1)'
	
	EXEC(@Sql)
	
		set @process = 'ccmenus - Insert'
		set @Sql='insert into ccmenus values(4210, ''Reporte MLS|MLS Report|MLS'',4000,''B'',4,2,'''')'
		
	EXEC(@Sql)
	
		set @process = 'IX_ccoCallsOut12 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoCallsOut12] ON [dbo].[ccoCallsOut] 
(
	[callout_id] DESC,
	[cal_Inicio] DESC,
	[calif_id] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
						
	EXEC(@Sql)
	
		set @process = 'IX_ccoLogDials_4 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] 
(
	[callout_id] DESC,
	[fecha] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
						
	EXEC(@Sql)
	
		set @process = 'IX_ccRIARegistryLists - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccRIARegistryLists] ON [dbo].[ccRIARegistryLists] 
(
	[list_id] DESC,
	[status] DESC,
	[sequence] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
							
	EXEC(@Sql)

		set @process = 'ccsp_RIASearchLoading - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIASearchLoading] 
@option smallint, 
@startDate datetime, 
@endDate datetime AS

if @option = 1
	begin
		select cam_id, load_id, camName, frame, [state], pctg, [description], case upPrepared when 0 then ''False'' else ''True'' end, 
		regsLoaded, telsLoaded, regsNotLoaded, telsNotLoaded, regsBlocked, telsBlocked, alreadyLoaded
		from ccRIALoading
		where convert(datetime,convert(varchar(11),loadDate)) >= @startDate
		and convert(datetime,convert(varchar(11),loadDate)) <= @endDate
		and [state] in (3,4)
	end'
						
	EXEC(@Sql)
	
		set @process = 'ccsp_AgentSetCallStatus - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
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
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
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

		select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono
		from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		where callout_id = @callout_id
		and statusCall_id = 13
		and cal_id = @cal_id

		select @surveycamid = isnull(surveycamid,0) from cccamps where cam_id = @cam_id

		if @surveycamid > 0
			begin
				if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
				begin
					insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
					values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()))
				end
			end

		return(0)
	end

	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select distinct(callout_id) from ccRIAUpdateCallBack_Abandon with(rowlock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x

	select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani
	from ccCallsIN with(index(IX_ccCallsIn_6),nolock)
	where cal_id = @cal_id
	and statusCall_id = 13

	select @surveycamid = isnull(cam_id,0) from ccinbound where inbound_id = @inbound_id

	if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
		begin
			if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
			begin
				insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
				values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()) )
			end
		end

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

		set @process = 'ccsp_OUTGetNewJobs - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
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
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @CAMPID 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0
 
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
 
SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
 
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
	   if @camSurvey > 0
			begin
				SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
				return
			end

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
	   FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
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
	   FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
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
	   select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
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
	
		set @process = 'ccsp_OUTGetNewProviderJobs - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int, 
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @CAMPID 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano 
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

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
	if @camSurvey > 0
		begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return	
		end

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
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
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
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) 
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
	select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
 end

select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, 
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''

select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
						
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTResetJobs - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_OUTResetJobs]
@camid as int=0
AS

if (@camid=0)
begin
	-- NUEVAS Hace tiempo que se marcaron
	update ccoWorkingTable with(rowlock)
	set cal_status=0 
	from ccoWorkingTable wt inner join ccoLogDials ld with (index (IX_ccoLogDials_2))
	on wt.callout_id=ld.callout_id
	where wt.cal_status = 2
	and ld.fecha <= dateadd(d, -1, getdate()) 
	
	-- CALLBACKS Se han marcado recientemente
	update ccoWorkingTable with(rowlock)
	set cal_status=1 
	from ccoWorkingTable wt inner join ccoLogDials ld with (index (IX_ccoLogDials_2))
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
	from ccoWorkingTable wt inner join ccoLogDials ld with (index (IX_ccoLogDials_2))
	on wt.callout_id=ld.callout_id
	where wt.cal_status = 2
	and wt.cam_id=@camid
	and ld.fecha <= dateadd(d, -1, getdate()) 
	
	-- CALLBACKS Se han marcado recientemente
	update ccoWorkingTable with(rowlock)
	set cal_status=1
	from ccoWorkingTable wt inner join ccoLogDials ld with (index (IX_ccoLogDials_2))
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
	
		set @process = 'ccsp_RIA_mnuReciclar - Alter Procedure'
		set @Sql='ALTER proc [dbo].[ccsp_RIA_mnuReciclar]
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
		update ccoCallsOutSource with(rowlock) 
		set dato5 = isnull(dato5, '''') 
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) where cam_id = @cam_id and cal_status = 1)
		
		update ccoCallBacks with(rowlock)
		set [status] = 3, schedulerStatus = 1
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) where cam_id = @cam_id and cal_status = 1)
		and [status] = 0

		update ccoWorkingTable with(rowlock) set cal_status = 0 where cam_id = @cam_id and cal_status = 1
	end
	else begin
		update ccoCallsOutSource with(rowlock) 
		set dato5 = isnull(dato5, '''') 
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id)

		update ccoCallBacks with(rowlock) 
		set [status] = 3, schedulerStatus = 1
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id)
		and [status] = 0

		update ccoWorkingTable with(rowlock) set cal_status = 0 where cam_id = @cam_id and cal_status = 1 and list_id = @list_id
	end

	return(0)
 end

if @type in(1,3)
 begin
	update ccoCallsOutSource with(rowlock)
	set dato5 = isnull(dato5, '''') where callout_id in (
	 select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_11),nolock)
	 where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1)

	update ccoCallBacks with(rowlock)
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select distinct(callout_id)
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
						 where cam_id = @cam_id 
						 and cal_status = 1 
						 and tiporesdial_id <> 1
						 and callout_id in (select distinct(b.callout_id)
												from ccologdials a with (index (IX_ccoLogDials_4),nolock) 
												left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
												on a.callout_id = b.callout_id
												and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
												where calif_id = 0
												and calif_id is not null))
	and [status] = 0

	update ccoWorkingTable with(rowlock)
	set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id 
	and cal_status = 1 
	and tiporesdial_id <> 1
	and callout_id in (select distinct(b.callout_id)
						   from ccologdials a with (index (IX_ccoLogDials_4),nolock) 
						   left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
						   on a.callout_id = b.callout_id
						   and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
						   where calif_id = 0
						   and calif_id is not null)
 end

if @type in(2,3)
 begin
	Set @SQL = ''update ccoCallsOutSource with(rowlock) set dato5 = isnull(dato5, '''''''') where callout_id in ('' +
	 ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_13),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''+'')'' + nchar(13)
	exec(@SQL)

	Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
	 ''where callout_id in ('' +
	 ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
	 ''and calif_id in ('' + @calif_id + ''))'' +
	 ''and [status] = 0''

	exec(@SQL)

	Set @SQL = ''update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
	 + -- and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''

	exec(@SQL)
 end

if @type = 4
 begin
	update ccoCallsOutSource with(rowlock) 
	set dato5 = isnull(dato5, '''') 
	where callout_id in (select distinct(callout_id)
					     from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)

	update ccoCallBacks with(rowlock) 
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select distinct(callout_id)
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)
	and [status] = 0

	update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'
						
	EXEC(@Sql)

		set @process = 'ccsp_RIALoadWorkGroup - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIALoadWorkGroup]
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
		nombre varchar(117), 
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

		set @process = 'Loader - Insert, Create and Alter'
		set @Sql='if not exists(select valor from ccsettings where setting_id=254)
Begin
  insert into ccSettings values (254,''8'',''Loader LogLevel'',1,''X'',''0/Nada 2/Funciones 4/Errores 8/Especiales'',''Loader LogLevel'',0)
end
if not exists(select table_name from INFORMATION_SCHEMA.TABLES where TABLE_NAME=''xxLog'')
Begin
  create table xxLog (Hostname varchar(256) null,Level tinyint null,Info varchar(1000) null,Info2 varchar(1000) null,Date datetime not null default (getdate()))
end
if not exists(select column_name from INFORMATION_SCHEMA.COLUMNS where column_name = ''User_id'' and table_name = ''xxclientecarga'')
Begin
  alter table xxclientecarga add User_id int not null default (0)
end'
		
	EXEC(@Sql)

		set @process = 'Loader - Drop'
		set @Sql='IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE  TABLE_NAME = ''xxClienteConexiones'') 
Begin
	drop table xxClienteConexiones
end

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.routines WHERE  ROUTINE_NAME = ''xx_ClienteActividad'') 
Begin
	drop PROCEDURE xx_ClienteActividad
end

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.routines WHERE  ROUTINE_NAME = ''xx_ChecaVersion'') 
Begin
	drop PROCEDURE xx_ChecaVersion
end

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.routines WHERE  ROUTINE_NAME = ''ccsp_OUTCancelDialJOB'') 
Begin
	drop PROCEDURE ccsp_OUTCancelDialJOB
end

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.routines WHERE  ROUTINE_NAME = ''xx_OUTInsertNewJOBS_WT_Camp'') Begin
	drop PROCEDURE xx_OUTInsertNewJOBS_WT_Camp
end

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.routines WHERE  ROUTINE_NAME = ''xx_Inserta'') Begin
	drop PROCEDURE xx_Inserta
end'
		
	EXEC(@Sql)
	
		set @process = 'xxClienteConexiones - Create Table'
		set @Sql='CREATE TABLE [dbo].[xxClienteConexiones] (
	[computadora] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[usuario] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[fecha] [datetime] NOT NULL,
	[activo] [bit] NOT NULL 
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'xx_ClienteActividad - Create Procedure'
		set @Sql='CREATE procedure xx_ClienteActividad 
@bloquear int = 0
as 
declare @usr varchar(50)
declare @pc varchar(50)
declare @existe int

select @usr = user_name(), @pc= host_name()
select @existe = count(*) from xxClienteConexiones where computadora = @pc
if @existe =0 
	insert into xxClienteConexiones values ( @pc, @usr, getdate(), 0 )
else
	update xxClienteConexiones  set usuario = @usr, fecha = getdate() where computadora = @pc

if @bloquear = 0
begin
	update xxClienteConexiones  set activo =0 where computadora = @pc
	select 2
end
else
begin
	select @existe = count(*) from xxClienteConexiones where activo <> 0 and computadora <> @pc
	if @existe > 0
		select 0
	else
	begin
		update xxClienteConexiones  set activo =1 where computadora = @pc
		select 1
	end
end'
		
	EXEC(@Sql)
		
		set @process = 'xx_ChecaVersion - Create Procedure'
		set @Sql='CREATE procedure [dbo].[xx_ChecaVersion]
@major as integer,
@minor as integer
as

if @major=1 and @minor=13
	select 1 as ok
else
	select 0 as ok'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_OUTCancelDialJOB - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_OUTCancelDialJOB]
@callout_id int,
@IsAnswer tinyint,
@nOcupado tinyint,
@nNoContesta tinyint,
@nFax tinyint,
@nContestadora tinyint,
@nShortCall tinyint,
@nOtro  tinyint,
@ExisteWT   tinyint=1
AS

declare @RecicleSIC tinyint

SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60

	-- En workingtable
	if ( @ExisteWT > 0 )
	begin
		if (@IsAnswer = 1 )
		begin

			UPDATE ccoWorkingTable set cal_fechaDial=dateadd( hh, 1, getdate() ), cal_status=1, nOcupado=1, nNoContesta=1, nShortCall=nShortCall +1
			WHERE callout_id = @callout_id
		end
		else
		begin
			
			if (@RecicleSIC = 0)
			begin
				DELETE ccoWorkingTable WHERE callout_id = @callout_id
			end
		end
	end'
		
	EXEC(@Sql)
		
		set @process = 'xx_OUTInsertNewJOBS_WT_Camp - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]
@camp_id as int
AS
set nocount on
declare @prioridad varchar(8)

Insert ccoWorkingTable ( callout_id, user_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano,
 iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5  )
SELECT callout_id, user_id, cam_id, 
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
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_1), nolock)
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

UPDATE ccoCallsOutSource SET cal_status = 3, dial_tels = isNull( @prioridad, ''12345NNN''), nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id'
		
	EXEC(@Sql)
	
		set @process = 'xx_Inserta - Create Procedure'
		set @Sql='create procedure [dbo].[xx_Inserta] 
@cal_key varchar(20),
@cal_telefono varchar(19),
@cal_telefono2 varchar(19),
@cal_telefono3 varchar(19),
@cal_telefono4 varchar(19),
@cal_telefono5 varchar(19),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@cam_id integer,
@FCallBack smalldatetime = '''',
@cal_status tinyint=0,
@User_id integer=0
as
declare @calloutid int
if (@cal_status=0) set @FCallBack=getdate()
Insert into ccoCallsOutSource ( cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id)
values ( @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5, @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id)
select @calloutid=scope_identity()
Insert into xxClienteHistorial ( callout_id , fechaAct ) values ( @calloutid, getdate() )
select @calloutid'
		
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
