/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2020/01/06
Description: 

Database: CCenterRia
Required version: 122.13

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 13
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion = @version AND @actualVersionFix >= 11) OR (@actualVersion = @version-1 AND @actualVersionFix >= 41)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-3764 - Actualizar sp ccsp_RIAAdmPrioridadTelefonos'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAAdmPrioridadTelefonos]
  @cam_id int,
  @prioridad varchar(8),
  @callbacks bit = 0,
  @Type tinyint
AS


IF @Type = 3
    BEGIN
        INSERT INTO ccCampsPrioridadTel
        VALUES
        (@cam_id, 
         ''12345NNN''
        )
END
IF @Type = 2
    BEGIN
        IF NOT EXISTS
        (
            SELECT *
            FROM ccCampsPrioridadTel
            WHERE cam_id = @cam_id
        )
            BEGIN
                INSERT INTO ccCampsPrioridadTel
                VALUES
                (@cam_id, 
                 ''12345NNN''
                )
        END
        UPDATE ccCampsPrioridadTel
          SET 
              prioridad = @prioridad
        WHERE cam_id = @cam_id
        IF @callbacks = 1
            BEGIN
                --Ahora cambia todos los registros en ccCampsPrioridadTel.  Solo nuevos
                UPDATE ccCampsPrioridadTel
                  SET 
                      Prioridad = @prioridad
                WHERE cam_id = @cam_id
                      AND cam_id IN
                (
                    SELECT cam_id
                    FROM ccoWorkingTable
                    WHERE cam_id = @cam_id
                          AND cal_status = 0
                )
        END
END
IF @Type = 1
    BEGIN
        SELECT ccCamps.cam_id, 
               Prioridad
        FROM ccCamps, 
             ccCampsPrioridadTel
        WHERE ccCamps.cam_id = @cam_id
              AND ccCampsPrioridadTel.cam_id = @cam_id
END'
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp ccsp_DLRGetDialInfo'
		set @sql='ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0
AS
set nocount on
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104
select @PrefixRec=ISNULL(prefijo,'''') from ccCamps where cam_id = @cam_id

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña
if @prefix =''''
    select @prefix = dialPrefix from ccCamps where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campaña
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0)
from ccCamps C (nolock) where C.cam_id=@cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo    
set @prefixCalKey=''''
if (select valor from ccSettings where setting_id=202)=''1'' begin
    select @prefixCalKey=isnull(dialPrefix,'''') from ccoCallsOutSource with(nolock) where callout_id=@callout_id 
end

if @iPortNumber >= 0 
begin
	SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
	
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
    , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
    , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani
    , case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2
    , case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3
    , case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4
    , case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '''') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
    , isnull(@MohFiles,'''') as mohFiles
    ,@ivr_script ivrScript
	,@sipheader data
	,@PrefixRec as Prefijo
    FROM ccoCallsOutSource C with(nolock)
	left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
	left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
    WHERE C.callout_id = @callout_id
    return
end 

set nocount off'
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp ccsp_INInsertaCallBack'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
@cal_key varchar(20) ='''',
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
declare @iZonaHoraria2 int,@iZonaHoraria_verano2 int
declare @iZonaHoraria3 int,@iZonaHoraria_verano3 int
declare @iZonaHoraria4 int,@iZonaHoraria_verano4 int
declare @iZonaHoraria5 int,@iZonaHoraria_verano5 int
if @isAuto=0
	select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
else
	set @difference = 0
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
 begin
	select @callout_id=callout_id,@cal_statusTemp =cal_status,
	@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
	@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
	@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
	@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
	@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end, 
	@TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource 
	where cal_Key = @cal_key and cam_id = @cam_id

	update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
		,iZonaHoraria,iZonaHoraria_verano
		,iZonaHoraria2,iZonaHoraria_verano2
		,iZonaHoraria3,iZonaHoraria_verano3
		,iZonaHoraria4,iZonaHoraria_verano4
		,iZonaHoraria5,iZonaHoraria_verano5)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
		,@iZonaHoraria,@iZonaHoraria_verano
		,@iZonaHoraria2,@iZonaHoraria_verano2
		,@iZonaHoraria3,@iZonaHoraria_verano3
		,@iZonaHoraria4,@iZonaHoraria_verano4
		,@iZonaHoraria5,@iZonaHoraria_verano5

		if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
			begin
				insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
				values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
			end
		else
			begin
				update ccoCallBacks
				set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
				where callout_id = @callout_id
			end
  end

else
 begin
	select @FechaOriginal = getdate()

	insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,cal_status)
	values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,''2'')

	select @TelOriginal = @cal_telefono

	select @callout_id = scope_identity()
	select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

	select @callout_id=callout_id,
	@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
	@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
	@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
	@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
	@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
	from ccoCallsOutSource 
	where callout_id=@callout_id


	 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	 else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
		,iZonaHoraria,iZonaHoraria_verano
		,iZonaHoraria2,iZonaHoraria_verano2
		,iZonaHoraria3,iZonaHoraria_verano3
		,iZonaHoraria4,iZonaHoraria_verano4
		,iZonaHoraria5,iZonaHoraria_verano5)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
		,@iZonaHoraria,@iZonaHoraria_verano
		,@iZonaHoraria2,@iZonaHoraria_verano2
		,@iZonaHoraria3,@iZonaHoraria_verano3
		,@iZonaHoraria4,@iZonaHoraria_verano4
		,@iZonaHoraria5,@iZonaHoraria_verano5

		if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
			begin
				insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
				values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
			end
		else
			begin
				update ccoCallBacks
				set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
				where callout_id = @callout_id
			end
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp ccsp_OUTGetNewProviderJobs'
		set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
		@CAMPID as int,
		@test as int=0,
		@nAgentsLogin as int=1
		as
		set nocount on
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = 0

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
		SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
		select @revHorario=valor from ccsettings where setting_id = 112
		-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
		SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
		SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

		SET DATEFIRST 1
		--Checamos si es horario de verano
		select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
		if @iZonas is null begin

			INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			select @iZonas=value from @iZonasTable
			--Checamos si la campaña tiene horarios configurados
			if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
				begin
				declare @horaUniversal as datetime
				set @horaUniversal=getutcdate()

				if @iZonas = 0 begin
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
			end
		end

		set @sql=''CREATE TABLE #NEW_JOBS
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
		tel_type smallint,
		tel2_type smallint,
		tel3_type smallint,
		tel4_type smallint,
		tel5_type smallint,
		dialOrder varchar(10),
		list_id int,
		sequence smallint,
		calkey varchar(max)
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

		declare @isVerano varchar(max)
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
			begin
			select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

			select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
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
			couts.cal_telefono5 as tel5,''
			if @country_id = 1
			begin
				set @sql=@sql+''dbo.fnGetCallType(couts.cal_telefono) tel_type,
				dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
				dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
				dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
				dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
				''
			end
			else
			begin
				set @sql=@sql+''0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,''
			end
			set @sql=@sql+''
			cpt.Prioridad as dialOrder, W.list_id, isnull(R.sequence,0) as sequence,
			couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
			FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
			on W.list_id = R.list_id
			left join ccocallsoutsource couts (nolock)
			on W.callout_id = couts.callout_id
			inner join ccCampsPrioridadTel cpt (nolock)
			on cpt.cam_id = W.cam_id
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
			select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

			select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
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
			couts.cal_telefono5 as tel5,''
			if @country_id = 1
			begin
				set @sql=@sql+''dbo.fnGetCallType(couts.cal_telefono) tel_type,
				dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
				dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
				dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
				dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
				''
			end
			else
			begin
				set @sql=@sql+''0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,''
			end
			set @sql=@sql+''
			cpt.Prioridad as dialOrder, W.list_id, isNull(R.sequence,0) as sequence,
			couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
			FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
			on W.list_id = R.list_id
			left join ccocallsoutsource couts (nolock)
			on W.callout_id = couts.callout_id
			inner join ccCampsPrioridadTel cpt (nolock)
			on cpt.cam_id = W.cam_id
			WHERE W.cal_status=0 -- Nuevas
			and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
			and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
			and (
				( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
			or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
				( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
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
		select @sql=@sql+nchar(13)+ ''SET rowcount 0''
		if @Test=0
			begin
			select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
			WHERE callout_id in(select callout_id from #NEW_JOBS)''
			end

		select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
		user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence, calkey,
		tel_type, tel2_type, tel3_type, tel4_type, tel5_type
		FROM #NEW_JOBS where len(cal_telefono)>0''

		select @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		--print @sql
		exec(@sql)
		return(0)'
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp ccsp_OUTInsertaCallBack'
		set @sql='ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
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
declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

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
      select @phoneCompleted = dbo.Completa(@Telefono, @pais, @ld)
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
      +'',cal_status=2,iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
      exec(@sSQL)
END

ELSE--@>0 telefono ya existente
BEGIN
      update ccoCallsOutSource set cal_status=2
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
	begin
		UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
		cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
		iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
		iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
		iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
		iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
		iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
		WHERE callout_id=@callout_id
	end
else
	begin
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
		[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
		iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5,list_id)
		select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
		@user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
		@iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5,@list_id
	end

if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
	begin
		insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
		values (@callout_id,@user_id,@Camp,@cal_key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
	end
else
	begin
		update ccoCallBacks
		set user_id = @user_id, cam_id = @Camp, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @Telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
		where callout_id = @callout_id
	end

set nocount off '
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp ccsp_OUTInsertNewJOBS_WT_Camp'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
AS
set nocount on
declare @callout_id int
declare @cam_id int
declare @cal_telefono varchar(20)
declare @cal_telefono2 varchar(20)
declare @cal_telefono3 varchar(20)
declare @cal_status int
declare @cal_fechaGNP smalldatetime
declare @cal_fechaDial smalldatetime
declare @dato3 varchar(20)
declare @dato4 varchar(20)
declare @prioridad varchar(8)
declare @space varchar(13)

declare @dbname varchar(50)
select @dbname = c.name from sys.sysaltfiles a join sys.database_files c
 on a.filename = c.physical_name collate SQL_Latin1_General_CP1_CI_AS
 join master..sysprocesses d on a.dbid = d.dbid where d.spid=@@SPID and c.type=0

-- BORRAR LAS CUENTA QUE YA NO VIENEN 
--dejar en wt las que ya existen antes de subir y borrar las demas
if @reciclar = 1 and 1 = 0
 begin
	--Version HLAS 20041016
	update ccoWorkingTable set cal_Status = cal_Status + 22 
	from ccoWorkingTable wt left join ccUploadTemporal ut
	on wt.cal_keyw = ut.cal_key 
	where wt.cam_id = ut.cam_id and
	wt.cam_id = @camp_id
	and ut.cal_key is null
	and cal_status < 2

	insert into ccBorrardasReciclaje ( callout_id, cal_key, cal_status, cam_id)
	select callout_id, cal_keyw, cal_status - 22, cam_id from
	ccoWorkingTable where cam_id=@camp_id
	and cal_status in (22,23)

	delete ccoWorkingTable where cam_id=@camp_id
	and cal_status in (22,23)
 end

Delete ccUploadTemporal where cam_id = @camp_id

-- DEJAR LAS CUENTAS CON CALLBACK COMO ESTAN 
update ccoCallsOutSource set cal_Status = 4
from ccoCallsOutSource cs inner join ccoWorkingTable wt 
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7)

set @space = ''             ''

Insert ccoWorkingTable ( callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw
	,iZonaHoraria,iZonaHoraria_verano
	,iZonaHoraria2,iZonaHoraria_verano2
	,iZonaHoraria3,iZonaHoraria_verano3
	,iZonaHoraria4,iZonaHoraria_verano4
	,iZonaHoraria5,iZonaHoraria_verano5)
SELECT callout_id, cam_id, 
	rtrim(left(ltrim(cal_telefono    +@space
	+ cal_telefono2 + @space
	+ cal_telefono3 + @space
	+ cal_telefono4 + @space
	+ cal_telefono5 + @space),13)) as cal_telefono,
	case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key
	,case when len(cal_telefono)>0 then iZonaHoraria else null end, case when len(cal_telefono)>0 then iZonaHoraria_verano else null end
	,case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end
	,case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end
	,case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end
	,case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel where cam_id = @camp_id

if @prioridad is null set @prioridad=''12345NNN''

UPDATE ccoCallsOutSource SET cal_status = 2, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id
set nocount off'
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp ccsp_RIAOUTInsertNewJOBS_WT_Camp'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1
AS
SET NOCOUNT ON

CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(20), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
declare @top int

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00
set @top=3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

INSERT INTO #calloutIdSource
SELECT top(@top) cs.callout_id
FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
on cs.cal_key = wt.cal_keyw AND cs.cam_id = wt.cam_id 
WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

UNION

SELECT top(@top) Cout.callout_id
FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)

INSERT INTO #calloutIdSource2
SELECT top(@top) callout_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

IF exists(SELECT * FROM #calloutIdSource) 
BEGIN
	UPDATE ccoCallBacks
	SET [status] = 6, schedulerStatus = 1
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis
			)

	UPDATE ccoCallsOutSource
	SET cal_Status = 4
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis
			)
END

INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
 iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT top(@top) callout_id, cam_id, rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
+ cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) AS cal_telefono,
 CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
 CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
  CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
  CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
   CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
    CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
    CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
    CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
    CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
			NULL END iZonaHoraria_verano5, list_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

IF exists(SELECT * FROM #tempCallsOutSource)
BEGIN
	SELECT @rango = isnull(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
	FROM #tempCallsOutSource WITH (NOLOCK)

	SET @batchsizeFin = @batchsizeFin + @rango

	WHILE 1 = 1
	BEGIN
		-- Nuevos Jobs
		INSERT INTO ccoWorkingTable
		WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
		SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
		FROM #tempCallsOutSource
		WHERE id > @batchsizeIni AND id <= @batchsizeFin

		IF @batchsizeFin > @rowstoInsert
			BREAK
		ELSE
		BEGIN
			SET @batchsizeIni = @batchsizeIni + @rango
			SET @batchsizeFin = @batchsizeFin + @rango
		END
	END

	UPDATE ccoCallsOutSource
	SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
	FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
	WHERE co.callout_id = cis3.callout_id
END

DROP TABLE #calloutIdSource

DROP TABLE #calloutIdSource2

DROP TABLE #tempCallsOutSource

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF
'
		EXEC(@sql)

		set @process = 'CW-3764 - Actualizar sp xx_OUTInsertNewJOBS_WT_Camp'
		set @sql='ALTER PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]
@camp_id as int
AS
set nocount on
declare @prioridad varchar(8)
declare @space varchar(13)

set @space = ''             ''

Insert ccoWorkingTable ( callout_id, user_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano,
iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5  )
SELECT callout_id, user_id, cam_id, 
rtrim(left(ltrim(cal_telefono + @space
		  + cal_telefono2 + @space
		  + cal_telefono3 + @space
		  + cal_telefono4 + @space
		  + cal_telefono5 + @space),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_11), nolock)
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock) SET cal_status = 3, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id
		'
		EXEC(@sql)

		set @process = 'CW-3555 - Actualizar sp ccsp_RIAADMGetCalifDay'
		set @sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = null
AS
set nocount on
create table #CalifTemp (
id int identity,
tipo integer,
Cam_id varchar(60),
Calificacion varchar(60),
subCalificacion varchar(60) null,
calif_id smallint null,
Total int,
iTotal4Campaign int null)

declare @typeACD smallint --= 0
declare @today datetime
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

set @today = convert(datetime, convert (varchar(11), getdate(), 101))
select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
@nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

---------------OUT ----------------------------
if @type=0 begin
    insert into #CalifTemp
    select 0 as tipo,co.cam_id as cam_id,
    case when co.statuscall_id = 13
	   then case when description is not null
	   then description else @nIdioma end
    else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
    else ''cw:'' + @nIdioma
    end end as Calificacion
    ,0 as subCalificaion,
    co.calif_id,count(*) cantidad,0 as iTotal4Campaign
    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
    left join ccCamps ci on ci.cam_id = co.cam_id
    where co.cal_inicio > @today
    group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

    select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
    case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
    from #CalifTemp
    group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

end
---------------IN ----------------------------
else if @type = 1 begin

    if @typeACD = 0 begin  --Calls
    insert into #CalifTemp
    select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
		  ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
		  ,count(*) as total,0 as iTotal4Campaign
		  from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		  left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		  left join ccInbound cci on cci.inbound_id = ci.inbound_id
		  left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		  where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
		  group by description, cci.inbound_id,ci.calif_id

    if (select valor from ccSettings where setting_id = 78) = 0 begin
	   update #CalifTemp set iTotal4Campaign = 0
    end
    else begin
    update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
	   from (
		  select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
	   inner join #CalifTemp c on t.cam_id = c.cam_id
    end
    end
    else if @typeACD = 1 begin--Chats
    insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
		  case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		  a.disposition as calif_id, count(disposition) as Total
		  from ccriachats a
		  left join ccTipoCalif b on a.disposition=b.calif_id
	   where a.chatDate > @today and
	   a.chatStatus=4 and a.inboundId=@inbound_id
    group by inboundId, [description],disposition
    end
    else if @typeACD = 3 begin ---Mail
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
    from conversation conver
    inner join message mess on mess.conversationId = conver.conversationId
    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    where mess.date > @today and
    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
    group by conver.inboundId,relmesdis.dispositionId,disp.Description

    end
    else if @typeACD = 4 begin --calif twetter
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
    from conversationTwitter conver
    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    where mess.date > @today and
    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
    group by conver.inboundId,relmesdis.dispositionId,disp.Description

    end
    select camtemp.tipo,camtemp.cam_id,
    case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
    camtemp.subcalificacion,camtemp.calif_id,camtemp.total
    from #CalifTemp camtemp
    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
end
-------------------SUBCALIFICACIONES IN-------------------
else if @type = 2 begin
    if @typeACD = 0 begin --Calls
    select @typeACD as tipo,cci.inbound_id as cam_id,  [description] as Calificacion,
    isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
    from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
    left join ccTipoCalif ca on ci.calif_id = ca.calif_id
    left join ccInbound cci on cci.inbound_id = ci.inbound_id
    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
    where ci.cal_inicio > @today
    and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
    end
    else if @typeACD = 1 begin --Chat
    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
		  isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
		  from ccriachats a
		  left join ccTipoCalif b on a.disposition=b.calif_id
		  left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
		  where a.chatDate > @today and
		  a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
		  group by inboundId, [description],ctcs.califSubDesc
    end
    else if @typeACD = 3 begin --Mail
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
    from conversation conver
    inner join message mess on mess.conversationId = conver.conversationId
    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
    where mess.date > @today and
    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
    group by conver.inboundId,disp.Description,subDisp.califSubDesc


    end
    else if @typeACD = 4 begin --Twitter
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
    from conversationTwitter conver
    inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
    left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
    where mess.date > @today and
    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
    group by conver.inboundId,disp.Description,subDisp.califSubDesc
    end

end
-------------------SUBCALIFICACIONES OUT-------------------
else if @type = 4 begin
    select 0 as Type,co.cam_id as CampId,
    case when co.statuscall_id = 13
    then case when description is not null
    then description else @nIdioma end
    else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
    end as Calification,
    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
    left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id 
    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
    left join ccCamps ci on ci.cam_id = co.cam_id
    where co.cal_inicio > @today
    and co.cam_id = @inbound_id
    and co.calif_id = @calif_id
    group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end


drop table #CalifTemp
set nocount off'
		EXEC(@sql)

		set @process = 'CW-3555 - Actualizar sp ccsp_RIAADMGetCalifDayForced'
		set @sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint,
@calif_id smallint = null
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(50), 
subCalificacion varchar(50) null,
calif_id smallint null,
Total int ) 

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
from ccsettings where setting_id = 27 -- 0esp

select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
		then case when description is not null 
					then description 
					else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
					end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
end end as Calificacion,
case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
and co.cam_id = @cam_id
group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id



if @type=1 
insert into #CalifTemp 
select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
where ci.cal_inicio > @today
and ci.inbound_id = @cam_id
and statuscall_id = 13 
group by description, cci.inbound_id,ci.califSub_id,ci.calif_id



-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign 
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @type=1 
select tipo, cam_id, calificacion,subCalificacion,calif_id ,sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total--,0 as iTotal4Campaign
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	and a.inboundId = @cam_id
	group by inboundId, Description
	
	union all
	
	
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end as Calificacion,
	case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total  --iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end, Cam_id,calif_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id 
if @type=0 

select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
then calificacion 
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaña
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
then calificacion 
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
end, Cam_id,subCalificacion, calif_id, iTotal4Campaign



if @type = 3 begin -----entrada acd''s
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @cam_id
	and statuscall_id = 13 
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end

if @type = 4 begin --salida campañas
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
			then case when description is not null 
						then description 
						else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
						end
	else case when sll.descripcion is not null 
	then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id 
	where co.cal_inicio > @today
	and co.cam_id = @cam_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 
 

drop table #CalifTemp 
set nocount off'
		EXEC(@sql)

	set @process = 'CW-3779 - Actualizar sp ccsp_OUTGetCallsInfo_AllCamps'
	set @sql='
		ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
		@Tipo as tinyint=0,
		@cam_id as smallint = 0,
		@sup_id as smallint=0
		AS

		declare @mToday as smalldatetime

		select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
		if @Tipo = 0
		begin
		  SELECT cam_id, cam_descripcion,
		    0 as pContesta,
		    0 as pOcupado,
		    0 as pNoContesta,
		    0 as pFaxModem,
		    0 as pNoService,
		    0 as Marcaciones, 0 as Contestan,  0 as Ocupado, 0 as NoContesta, 0 as FaxModem, 0 as NoService
		  FROM ccCamps
		  order by cam_id
		end

		else if @Tipo = 1
		begin
		  select cam_id, L.Campana,
		    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
		    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		    ((L.NoService*100)/ L.Marcaciones) as pNoService,
		    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		    ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
		  from (
		  select cam_id, '''' as Campana,
		    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Marcaciones
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
		    ,count(case tipoResDial_id when 11 then 1 else null end) as buzon
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as congestion

		  from ccoLogDials with(nolock)
		  Where fecha >  @mToday
		  group by cam_id
		  ) L order by Campana

		end

		else if @Tipo = 2
		begin
		  select cam_id, L.Campana,
		    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
		    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		    ((L.NoService*100)/ L.Marcaciones) as pNoService,
		    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		  from (
		  select C.cam_id as cam_id, cam_descripcion as Campana,
		    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Marcaciones
		  from ccoLogDials L with(nolock)
		  inner join ccCamps C on L.cam_id=C.cam_id
		  Where fecha >  @mToday
		  group by C.cam_id, cam_descripcion
		  ) L order by Campana
		end

		else if @Tipo = 3 --Busqueda por campaña
		begin
		  select L.cam_id,
		    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		  from (
		  select cam_id,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Calls
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion

		  from ccoLogDials with(nolock)
		  Where cam_id = @cam_id
		  and fecha >  @mToday
		  group by cam_id
		  ) L 
		  left join (select 
		    cam_id,
		    count(case statuscall_id when 6 then 1 else null end) as Abandon,
		    count(*) as Contesta    
		  from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		  where cal_Inicio > @mToday
		  group by cam_id) callsOut on L.cam_id = callsOut.cam_id

		end

		else if @Tipo = 4-- Busqueda por campañas asociadas a admin
		begin
		  select L.cam_id,
		    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		  from (
		  select logDials.cam_id,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Calls
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion
		  from ccoLogDials logDials with(nolock)
		  right join (select distinct cam_id from ccSupervisorCam supCam where user_id=2) B ON logDials.cam_id = B.cam_id
		  Where fecha >  @mToday
		  group by logDials.cam_id
		  ) L 
		  left join (select 
		    cam_id,
		    count(case statuscall_id when 6 then 1 else null end) as Abandon,
		    count(*) as Contesta    
		  from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		  where cal_Inicio > @mToday
		  group by cam_id) callsOut on L.cam_id = callsOut.cam_id
		  order by L.cam_id

		end
	'
	EXEC(@sql)

	set @process = 'Alter procedure getacdCampaignList'
	set @sql = '

ALTER PROCEDURE [dbo].[cs_GetACDCampaignList] @action AS SMALLINT
AS
IF (@action = 1)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1
		AND cam_id NOT IN (
			SELECT Cam_id
			FROM CW_CenterScript..Campaign
			)
		AND IDArea > 0 
END

IF (@action = 2)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1
		AND Inbound_id NOT IN (
			SELECT Inbound_id
			FROM CW_CenterScript..ACD
			)
		AND IDArea > 0 and chat = 0
END

IF (@action = 3)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1
		AND IDArea > 0
END

IF (@action = 4)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1
		AND IDArea > 0
		AND chat = 0
END


	'
	exec (@sql)

	set @process = 'CW-3853 Alter procedure ccsp_OUTGetAve_Camps'
	set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_OUTGetAve_Camps] 
		@Tipo as tinyint=0,
		@Cam_ID as tinyint=0
		AS
		declare @FInicio as smalldatetime

		if @Tipo = 0 --para obtener la tabla de todo el día
		begin
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
			) D on A.cam_id=D.cam_id

		end
		if @Tipo = 1 --para obtener la tabla de todo el día
		begin
			select @FInicio = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
			select	A.cam_id, ((A.Abandon *100.0)/ A.Contesta) as AbandonRate,
			((D.Contesta *100.0)/ D.Marcaciones) as AnswerRate, A.Abandon, A.Contesta as Answer, D.Marcaciones as Calls
			from (
				select 
					cam_id,
					count(case statuscall_id when 6 then 1 else null end) as Abandon,
					count(*) as Contesta		
				from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
				where cal_Inicio > @FInicio
				and cam_id = @Cam_ID
				group by cam_id
			) A join 
			(
				select cam_id,
					count(case tipoResDial_id when 1 then 1 else null end) as Contesta,
					count(*) as Marcaciones
				from ccoLogDials with(nolock index(IX_ccoLogDials))
				where fecha > @FInicio
				and cam_id = @Cam_ID
				group by cam_id
			) D on A.cam_id=D.cam_id

		end
	'
	exec (@sql)

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
