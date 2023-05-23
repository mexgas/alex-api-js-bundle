/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 17
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN MARCO GARCIA CW-7905 Registros a Marcar No toma los registros activos correctos------------------------------
		SET @process = 'KR078000-Dashboard campaña de salida-Mostrar registro en estado Procesando delete store procedure [ccsp_OUTGetNewJobs]'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_OUTGetNewJobs'')
		BEGIN
			DROP PROCEDURE ccsp_OUTGetNewJobs
		END'
	EXEC(@sql)

	SET @process = 'KR078000-Dashboard campaña de salida-Mostrar registro en estado Procesando create store procedure [ccsp_OUTGetNewJobs]';
	SET @sql = 'CREATE procedure [dbo].[ccsp_OUTGetNewJobs]
		@CAMPID int,
		@test int=0,
		@nAgentsLogin int=1,
		@iZonas int = NULL,
		@isDashboardApi BIT = 0
		as
		--set nocount on
		declare @total int
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
		SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
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
		--Checamos si la campaÃ±a tiene horarios configurados
			  if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
			  begin
						  if @iZonas = 0 begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
			  else begin
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
		list_id int,
		sequence smallint,
		calkey varchar(max),
		nDescartes int,
		name_agent varchar(max)
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
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status=1 -- CallBacks
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
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
					order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
					
					--select @sql
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status=0 -- Nuevas
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

		end -- TOMA EN CUENTA LAS NUEVAS
		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ ''SET rowcount 0''
		if @Test=0
			  begin
					select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
					WHERE callout_id in(select callout_id from #NEW_JOBS)''
		end

		if @Test = 2
		begin
			  select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
			  declare @nSQL nvarchar(4000)
			  set @nSQL=cast(@sql as nvarchar(4000))
			  exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
			  return(@total)
		end
		else
		BEGIN
			IF(@isDashboardApi = 1)
			BEGIN
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status= 2 -- Procesando
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
					 -- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
			END

			select @sql=@sql+nchar(13)+ ''SET rowcount 0''


			select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
			user_id, tz, tz2, tz3, tz4, tz5,
			case when tz is null then '''''''' else cal_telefono end as tel,
			case when tz2 is null then '''''''' else cal_telefono end as tel2,
			case when tz3 is null then '''''''' else cal_telefono end as tel3,
			case when tz4 is null then '''''''' else cal_telefono end as tel4,
			case when tz5 is null then '''''''' else cal_telefono end as tel5,
			NULL as dialOrder, list_id, sequence, calkey,
			0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent
			FROM #NEW_JOBS where len(cal_telefono)>0

			---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
			declare @regval int
			SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
			exec ccsp_GetCampsNvosCB @cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '',@Tipo=0,@user_id =0
			''
		end

		set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		--print (@sql)
		exec(@sql)

		return(0)';
		EXEC(@sql);


		-------------------------------------------- END MARCO GARCIA KR078000-Dashboard campaña de salida-Mostrar registro en estado Procesando------------------------------
		
		-------------------------------------------- BEGIN HUGO LONGORIA DEV2-213_Fix_Preview ------------------------------
		SET @process = 'DEV2-213_Fix_Preview - Delete store procedure [ccsp_RegProcessPreviewRecord]'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RegProcessPreviewRecord'')
			BEGIN
				DROP PROCEDURE ccsp_RegProcessPreviewRecord
			END'
		EXEC(@sql)

		SET @process = 'DEV2-213_Fix_Preview - Create store procedure [ccsp_RegProcessPreviewRecord]';
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
			@process smallint,
			@callout_id int,
			@agent_id smallint,
			@camId int,
			@previewTime smallint,
			@callId int)
			AS
			DECLARE @result_callout_id INT
			DECLARE @result_maxtimespreview INT = 0
			DECLARE @result_maxtimesdiscard INT = 0
			DECLARE @insert_date DATETIME = SYSDATETIME()
			DECLARE @process_insert int =  @process

			if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
				set @result_callout_id =1
			end

			IF (@process=1 AND @result_callout_id > 0)
			BEGIN
				DELETE ccoWorkingTable WHERE callout_id = @callout_id
			END

			IF (@process NOT IN (1, 7))
			BEGIN
			DECLARE @first_date DATETIME = DATEADD(hh, 00, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
				if(
					(SELECT COUNT(process) FROM RegProcessPreviewRecord 
					WHERE reg_date BETWEEN @first_date AND @insert_date
					and (process != 1 AND process != 7 AND process != 9) 
					and (callout_id=@callout_id)
					)
					>=
					(SELECT timesPreview FROM ccCamps WHERE cam_id = @camId)
					)
				begin
						set @result_maxtimespreview = 1
						set @process_insert = 8
						DELETE ccoWorkingTable WHERE callout_id = @callout_id
				end
			END

			IF (@process NOT IN (1, 7, 8))
			BEGIN
				update ccoWorkingTable set timesDiscard+=1 where callout_id=@callout_id
			END

			IF (@result_callout_id > 0 or @process in (4,7))
			BEGIN
				INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview, callID) VALUES (@agent_id,@process_insert,@callout_id,@camId,@insert_date,@previewTime,@callId)
			END

			CREATE TABLE #result (result INT);
			INSERT INTO #result
			exec ccsp_CheckTimesDiscard @action=1,@camId=@camId, @calloutId=@callout_id
			select @result_maxtimesdiscard=result from #result
			DROP TABLE #result

			select case when @result_maxtimespreview = 1 or @result_maxtimesdiscard = 1 then 1 else 0 end as ''value'''
		EXEC(@sql);
		-------------------------------------------- END MARCO GARCIA DEV2-213_Fix_Preview------------------------------
		-------------------------------------------- BEGIN JONATHAN RAMIREZ FIX CW-7919 - Mostrar calificaciones no guarda cambio ------------------------------
		SET @process='20230425.0.2 - JR - ALTER PROCEDURE - ccsp_RIAUpdateCamConfig (IF (@CampType IS NOT NULL AND @CampType IN (3, 5)))'
		SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null,
@sipHdrsCfg varchar(255) = null,
@cam_inter_cancelled smallint = null,
@prefijo varchar(max) = null,
@exitAssisted bit = null,
@previewDiscard bit = null,
@rotativeAlgo tinyint = null,
@timesPreview tinyint = null,
@cam_tPreview smallint = null,
@timesDiscard tinyint = null,
@CampType int = null,
@agentCloseConversationTime SMALLINT = NULL,
@adminCloseConversationTime INT = NULL,
@ConexionInfo VARCHAR(400) = NULL,
@allowFileAttachments BIT = NULL,
@selectRotativeANI int = null,
@messagingOrder bit = null,
@autoStart bit = null,
@recordHold bit = null
as
set nocount on
DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)

UPDATE ccCamps SET
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
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
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
 prefijo = isnull(@prefijo, prefijo),
 exitAssisted = isnull(@exitAssisted, exitAssisted),
 previewDiscard = isnull(@previewDiscard, previewDiscard),
 rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
 timesPreview = isnull(@timesPreview, timesPreview),
 cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
 timesDiscard = isnull(@timesDiscard, timesDiscard),
 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
 selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
 messagingOrder = isnull(@messagingorder, messagingOrder),
 autoStart = isnull(@autoStart,autoStart),
 recordHold = isnull(@recordHold, recordHold)

Where cam_id = @cam_id

if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
begin
    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
end

IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
BEGIN
    IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
    BEGIN
        SELECT 0
        RETURN(0)
    END
    set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then '''' else @ConexionInfo end
    UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                              closeConversationTime = @agentCloseConversationTime, answerTimeoutClient = @adminCloseConversationTime,
                              allowFileAttachments = @allowFileAttachments
    WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        IF(@ConexionInfo <> '''')
        BEGIN 
            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
        END
    END
END 

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

UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
select 2
return(0)

set nocount off
		'
		EXEC(@sql);
		-------------------------------------------- END JONATHAN RAMIREZ FIX CW-7919 - Mostrar calificaciones no guarda cambio ------------------------------

		
		----------------------------------------------------------------------------------------------------------------------------
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END


