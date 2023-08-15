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
 cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd),
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

 select 1
 return(0)
end


select 2
return(0)

set nocount off
		'
		EXEC(@sql);
		-------------------------------------------- END JONATHAN RAMIREZ FIX CW-7919 - Mostrar calificaciones no guarda cambio ------------------------------
		-------------------------------------------- BEGIN JONATHAN RAMIREZ FIX CW-7912 - Mostrar Administradores recién creados ------------------------------
		SET @process='20230425.0.2 - JR - ALTER PROCEDURE - ccsp_RIALoadAgents (Se agrega nuevo @option (19))'
		SET @sql='
ALTER PROCEDURE [dbo].[ccsp_RIALoadAgents] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @UserType SMALLINT, @IDWG SMALLINT = NULL, @IDCampACD VARCHAR(max) = NULL
AS
SET NOCOUNT ON

DECLARE @IDArea INT
DECLARE @loginDays INT

SET @loginDays = 0

IF @option IN (1, 7) --1:Todos los agentes/supervisores | 7:UN solo agente/supervisor
BEGIN
    SELECT User_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
    FROM ccUsers WITH (READPAST)
    WHERE TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS > 0 AND user_id = CASE @option WHEN 7 THEN isnull(@sup, user_id) ELSE user_id END
    ORDER BY IDArea, Nombres, ApellidoPaterno, User_id

    RETURN (0)
END

IF @option = 2 --Agentes/supervisores de un Area
BEGIN
    SELECT User_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
    FROM ccusers
    WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
    ORDER BY Sexo, Nombres, ApellidoPaterno, User_id

    RETURN (0)
END

IF @option = 3 --Agentes por Supervisor
BEGIN
    SELECT a3.user_id, a3.LOGIN, a3.TipoLlamadas, a3.Nombres + isnull('' '' + a3.ApellidoPaterno, '''') + isnull('' '' + a3.ApellidoMaterno, '''') name, isnull(a3.IDArea, 0) IDArea, a3.Sexo
    FROM ccsupervisorcam a1
    JOIN cccampsagente a2 ON a1.cam_id = a2.cam_id
    JOIN ccusers a3 ON a2.user_id = a3.user_id
    WHERE a1.tipo = ''1'' AND a1.user_id = @Sup AND a3.TipoUser_id = 1 AND a3.STATUS > 0
    
    UNION
    
    SELECT a3.user_id, a3.LOGIN, a3.TipoLlamadas, a3.Nombres + isnull('' '' + a3.ApellidoPaterno, '''') + isnull('' '' + a3.ApellidoMaterno, '''') name, isnull(a3.IDArea, 0) IDArea, a3.Sexo
    FROM ccsupervisorcam a1
    JOIN ccInboundagentes a2 ON a1.cam_id = a2.Inbound_id
    JOIN ccusers a3 ON a2.user_id = a3.user_id
    WHERE a1.tipo = ''0'' AND a1.user_id = @Sup AND a3.TipoUser_id = 1 AND a3.STATUS > 0
    ORDER BY 5, 4, 1

    RETURN (0)
END

IF @option = 4 --Load All Supervisors
BEGIN
    SELECT User_id, LOGIN, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name
    FROM ccUsers
    WHERE TipoUser_id IN (2, 6) AND STATUS > 0

    RETURN (0)
END

IF @option = 5 --Agentes por Supervisor de sus WG
BEGIN
    SELECT @loginDays = valor
    FROM ccSettings
    WHERE setting_id = 211 --Numero dias que cargara las relaciones

    SELECT @IDArea = IDArea
    FROM ccUsers
    WHERE User_id = @Sup

    SELECT User_id, LOGIN, TipoLlamadas, max(name) name, IDArea, Sexo, IP, sum(sumMultimedia) sumMultimedia
    FROM (
        SELECT DISTINCT A.User_id, A.LOGIN, a.TipoLLamadas, A.Nombres + isnull('' '' + A.ApellidoPaterno, '''') + isnull('' '' + A.ApellidoMaterno, '''') name, isnull(A.IDArea, 0) IDArea, A.Sexo, isnull(C.IP, ''0.0.0.0'') IP, (CASE isnull(E.chat, 0) WHEN 3 THEN POWER(2, 0) WHEN 4 THEN POWER(2, 1) ELSE 0 END) AS sumMultimedia --, E.chat mode,E.Inbound_id
        FROM ccUsers A
        INNER JOIN ccRIAWorkGroupUsers B ON A.User_id = B.User_id
        LEFT JOIN ccPosicion C ON C.user_id = A.User_id
        INNER JOIN ccRIACampEspWG D ON D.IDWG = B.IDWG
        LEFT JOIN ccInbound E ON D.IdCampEsp = E.Inbound_id AND E.IDArea = @IDArea
        WHERE A.TipoUser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays) AND B.IDWG IN (
                SELECT IDWG
                FROM ccRIAWorkGroupUsers
                WHERE user_id = @Sup
                )
        ) x
    GROUP BY user_id, LOGIN, TipoLlamadas, IDArea, Sexo, IP

    RETURN (0)
END

IF @option = 6 --Agentes por Supervisor de sus WG
BEGIN
    SELECT DISTINCT a1.user_id, a1.LOGIN, a1.TipoLlamadas, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
    FROM ccusers a1
    JOIN ccRIAWorkGroupUsers a2 ON a1.user_id = a2.user_id
    WHERE tipouser_id IN (2, 6) AND IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE user_id = @Sup
            )

    RETURN (0)
END

IF @option IN (8, 9) --8:Agentes de un WG | 9:Supervisores de un WG
BEGIN
    DECLARE @wgUsers AS VARCHAR(500)

    SELECT @wgUsers = coalesce(@wgUsers + '','', '''') + CAST(A.user_id AS VARCHAR(40))
    FROM ccRIAWorkGroupUsers A
    JOIN ccUsers B ON A.user_id = B.user_id
    WHERE IDWG = @IDWG AND TipoUser_id = CASE @option WHEN 8 THEN 1 ELSE 2 END

    SELECT @wgUsers wgUsers

    RETURN (0)
END

IF @option = 10 --Todos los agentes/supervisores
BEGIN
    SELECT User_id, LOGIN, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
    FROM ccUsers WITH (READPAST)
    WHERE TipoUser_id IN (/*2,*/ 6) AND STATUS > 0
    ORDER BY LOGIN, IDArea, Nombres, ApellidoPaterno, User_id

    RETURN (0)
END

IF @option = 11 -- Agentes por ACD
BEGIN
    SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
    FROM ccusers a1
    JOIN ccInboundAgentes a2 ON a1.user_id = a2.user_id
    WHERE a1.tipouser_id = 1 AND a2.Inbound_id IN (
            SELECT value
            FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
            )

    RETURN (0)
END

IF @option = 12 -- Agentes por Camp
BEGIN
    SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
    FROM ccusers a1
    JOIN ccCampsAgente a2 ON a1.user_id = a2.user_id
    WHERE a1.tipouser_id = 1 AND a2.cam_id IN (
            SELECT value
            FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
            )

    RETURN (0)
END

IF @option = 13 -- Sups por ACD
BEGIN
    SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
    FROM ccusers a1
    JOIN ccSupervisorCam a2 ON a1.user_id = a2.user_id
    WHERE a1.tipouser_id & 2 = 2 AND tipo = 0 AND a2.cam_id IN (
            SELECT value
            FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
            )

    RETURN (0)
END

IF @option = 14 -- Sups por Camp
BEGIN
    SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
    FROM ccusers a1
    JOIN ccSupervisorCam a2 ON a1.user_id = a2.user_id
    WHERE a1.tipouser_id & 2 = 2 AND tipo = 1 AND a2.cam_id IN (
            SELECT value
            FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
            )

    RETURN (0)
END

DECLARE @sxML AS VARCHAR(max), @xml AS XML, @action AS INT

IF @option = 15 -- Info Agentes
BEGIN
    SET @action = @option - 9
    SET @xml = cast(''<?xml version="1.0"?> <AgentData/>'' AS XML)

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT 1 AS tag, NULL AS parent, User_id "Agent!1!id", LOGIN "Agent!1!login", Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') "Agent!1!name", Sexo "Agent!1!gender", isnull(IDArea, 0) "Agent!1!areaID"
                    FROM ccUsers WITH (READPAST)
                    WHERE TipoUser_id = 1 AND STATUS > 0 AND user_id = @sup
                    ) AS x
                ORDER BY tag, "Agent!1!areaID", "Agent!1!name", "Agent!1!id"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<AgentData/>'')

    SET @xml.modify(''insert element Workgroups {""} as last into (/AgentData/Agent)[1]'')

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT 1 AS tag, NULL AS parent, W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
                    FROM ccRIACat_WorkGroup W
                    JOIN ccRIAWorkGroupUsers U ON W.IDWG = U.IDWG
                    WHERE user_id = @sup
                    ) AS x
                ORDER BY tag, "Workgroup!1!description"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

    SET @xml.modify(''insert element Campaigns {""} as last into (/AgentData/Agent)[1]'')

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT DISTINCT 1 AS tag, NULL AS parent, a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
                    FROM ccCamps a1
                    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
                    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
                    JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
                    WHERE a3.type_id = 1 AND a4.user_id = @Sup
                    ) AS x
                ORDER BY tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

    SET @xml.modify(''insert element ACDs {""} as last into (/AgentData/Agent)[1]'')

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT DISTINCT 1 AS tag, NULL AS parent, a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
                    FROM ccinbound a1
                    JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
                    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
                    JOIN ccInboundAgentes a4 ON a1.Inbound_id = a4.Inbound_id
                    WHERE a3.type_id = 1 AND a4.user_id = @Sup
                    ) AS x
                ORDER BY tag, "ACD!1!description", "ACD!1!id"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

    SET @xml.modify(''insert element action {""} as last into (/AgentData)[1]'')
    SET @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/AgentData/action)[1]'')

    SELECT @xML

    RETURN (0)
END

IF @option = 16 -- Info Sups
BEGIN
    SET @action = @option - 9
    SET @xml = cast(''<?xml version="1.0"?> <SuperData/>'' AS XML)

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT 1 AS tag, NULL AS parent, User_id "Super!1!id", LOGIN "Super!1!login", Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') "Super!1!name", Sexo "Super!1!gender", isnull(IDArea, 0) "Super!1!areaID"
                    FROM ccUsers WITH (READPAST)
                    WHERE TipoUser_id & 2 = 2 AND STATUS > 0 AND user_id = @sup
                    ) AS x
                ORDER BY tag, "Super!1!areaID", "Super!1!name", "Super!1!id"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<SuperData/>'')

    SET @xml.modify(''insert element Workgroups {""} as last into (/SuperData/Super)[1]'')

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT 1 AS tag, NULL AS parent, W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
                    FROM ccRIACat_WorkGroup W
                    JOIN ccRIAWorkGroupUsers U ON W.IDWG = U.IDWG
                    WHERE user_id = @sup
                    ) AS x
                ORDER BY tag, "Workgroup!1!description"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

    SET @xml.modify(''insert element Campaigns {""} as last into (/SuperData/Super)[1]'')

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT DISTINCT 1 AS tag, NULL AS parent, a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
                    FROM ccCamps a1
                    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
                    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
                    JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
                    WHERE a3.type_id = 1 AND a4.user_id = @Sup AND a4.tipo = 1
                    ) AS x
                ORDER BY tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

    SET @xml.modify(''insert element ACDs {""} as last into (/SuperData/Super)[1]'')

    SELECT @sxML = cast((
                SELECT *
                FROM (
                    SELECT DISTINCT 1 AS tag, NULL AS parent, a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
                    FROM ccinbound a1
                    JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
                    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
                    JOIN ccSupervisorCam a4 ON a1.inbound_id = a4.cam_id
                    WHERE a3.type_id = 1 AND a4.user_id = @Sup AND a4.tipo = 0
                    ) AS x
                ORDER BY tag, "ACD!1!description", "ACD!1!id"
                FOR XML explicit, type
                ) AS VARCHAR(max))

    SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

    SET @xml.modify(''insert element action {""} as last into (/SuperData)[1]'')
    SET @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/SuperData/action)[1]'')

    SELECT @xML

    RETURN (0)
END

IF @option = 17 -- Load all agents
BEGIN
    SELECT @loginDays = valor
    FROM ccSettings
    WHERE setting_id = 211 --Numero dias que cargara las relaciones

    SELECT DISTINCT user_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo, ''0.0.0.0'' IP, 0 AS flagMine
    INTO #allAgents
    FROM ccusers
    WHERE tipouser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)

    SELECT DISTINCT a1.user_id, a1.LOGIN, a1.TipoLlamadas, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, isnull(a1.IDArea, 0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
    INTO #myAgents
    FROM ccusers a1
    JOIN ccRIAWorkGroupUsers a2 ON a1.user_id = a2.user_id
    LEFT JOIN ccPosicion a3 ON a1.user_id = a3.user_id
    JOIN ccRIACampEspWG a4 ON a2.idwg = a4.idwg
    WHERE a1.tipouser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays) AND a2.IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE user_id = @Sup
            )

    UPDATE #allAgents
    SET flagMine = 1
    FROM #allAgents a, #myAgents b
    WHERE a.user_id = b.user_id

    SELECT *
    FROM #allAgents

    DROP TABLE #allAgents

    DROP TABLE #myAgents

    RETURN (0)
END

IF @option = 18 -- View Agents
BEGIN
    SELECT isnull(viewAgents, 0) AS viewAgents
    FROM ccusers
    WHERE tipouser_id = 2 AND user_id = @Sup

    RETURN (0)
END

IF @option = 19 -- Load Just One Supervisor
BEGIN
    SELECT User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name
    FROM ccUsers
    WHERE TipoUser_id IN (2, 6) AND STATUS > 0 AND User_id = @Sup

    RETURN (0)
END

SET NOCOUNT OFF

		'
		EXEC(@sql);
		-------------------------------------------- END JONATHAN RAMIREZ FIX CW-7912 - Mostrar Administradores recién creados ------------------------------
		-------------------------------------------- BEGIN URIEL CABRERA TT4259_Finder Bug ---------------------------------
		SET @process = 'TT4259_Finder_Bug - ALTER procedure [ccsp_BaseXmngr]'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
						@action int,
						@option tinyint = 0,
						@ids varchar(max)=null,
						@name varchar(25) = NULL,
						@top int = 0,
						@dateIni datetime =null,
						@dateEnd datetime =null,
						@dateStart dateTime= null,
						@userId int = 0,
						@node varchar(10) = null,
						@grabIds varchar(4000) = null
						AS

						declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
						declare @parameterDefinition nvarchar(max)
						declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
						declare @status tinyint
						set @sql = ''''

						select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

						if @action in (1,6) begin --obtiene los nodos a insertar en BX
							if @action = 1 set @status =0
							else if @action = 6 set @status = 2

							if @option <>2 begin

							declare @auxTag nvarchar(10)
							
							select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
							else ''@CDATE''   end
							set @parameterDefinition =N''@status int, @top int,@option int''
							set @sql=''declare @basexName varchar(max)
						select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
							with node ( ''+@columnId+ '',xmlString,dateNode)
							AS(
								select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
								,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
								from ''+ @tableName + '' A with(rowlock)
								where A.status =@status
								union
								select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
								,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
								from ''+ @tableNameHistory + '' A with(rowlock)
								where A.status =@status  
							)

							select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
							left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
							order by baseX.Xname''
							--print(@sql)
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
							end
						end
						else if @action in (2,7) begin--actualiza los nodos insertados en BX
							if @action = 2 set @status =0
							else if @action = 7 set @status = 2

							set @parameterDefinition =N''@status int''

							set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
							select @tableName,@columnId,@ids,@sql
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
							set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
							--print(@sql)
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

						end
						else if @action = 3 --trae el nombre de la base de datos en BX
						begin
							select Xname from ccBaseXDB where serviceId = @option and isFull=0
						end
						else if @action = 4 --inserta el nombre del xml en BX
						begin
							insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
						end
						else if @action = 5 begin --obtener servicios disponibles    
							select id, ref  from ccFinderServices where isActive=1
						end
						else if @action = 8 begin--trae la lista de las bases para la busqueda
							select Xname from ccBaseXDB where serviceId = @option
							and (

							@dateIni between dateStart and dateEnd
							or @dateEnd between dateStart and dateEnd
							or dateStart between @dateIni and @dateEnd
							)
							union
							select Xname from ccBaseXDB where serviceId = @option and isFull=0
							and (
								dateStart between @dateIni and @dateEnd
								or @dateIni>=dateStart

							)
						end
						else if @action = 9 begin--Cierra la base datos
							update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
							and Xname=@name
						end

						else if @action = 10 begin
						declare @filterWg varchar(max)
							declare @len int
							declare @tipo int = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
							set @filterWg=''''
							if @node is null or @node = ''R02''
							begin
								select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
								inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
								where Wguser.User_id=@userId
						
							end
							else
							begin
							declare @serviceId varchar(10)
							set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
							select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
								inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
								where Wguser.User_id=@userId and WGCam.Tipo=@tipo
							end


							set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
							select SUBSTRING(@filterWg,0, @len)
							end


						else if @action = 11 begin--trae el nombre de la base de datos en BX

							set @sql=''
							declare @dateStart datetime
							set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
							SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
							EXECUTE sp_executesql  @sql

						end

						else if @action = 13 begin
							set @sql = ''''
							select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
							select @tableName,@tableNameHistory,@columnId
							set @sql=''
							;
							with duplicateIds as(
							select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
							union
							select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
							)

							select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
							inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
							group by A.''+@columnId+'',A.dateIn
							Having count(*)>1
							order by Xname
							''
							exec (@sql)

						end'
		EXEC(@sql)
		-------------------------------------------- END URIEL CABRERA TT4259_Finder Bug ---------------------------------
		
-------------------------------------------- Daniel Hernandez CW-7873 ------------------------------
	SET @process = 'Delete stored procedure if it exists'
	SET @sql = 'if exists (select * from sys.procedures where name =''ccsp_GalateaGetCampsNvosCB'')
				begin
					DROP PROCEDURE ccsp_GalateaGetCampsNvosCB
				end'
	EXEC(@sql)

	SET @process = 'Create SP ccsp_GalateaGetCampsNvosCB FIX-Set a default value to the Overraltotalnew column when the value is null and prevent it from being zero when there are records in the campaign'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
	@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
	@regval int =0, @tcpa int=0
	as

	declare @TipoJobs as int, @isExecOutbound bit

	set @isExecOutbound= case when @regval=0 then 0 else 1 end

	-- Actualiza todas las camps
	if @Tipo in (1,2) begin

		declare @id AS INTEGER

		CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
		CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

		create table #temccocallsoutsource (cam_id int,Pend  int)

		create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

		if @cam_id = 0 begin
			if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
				where user_id = @user_id and tipo = 1
			end
			else begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				from ccCamps cam (nolock)
			end
		end
		else begin
			if @Tipo = 2
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
				from ccCamps cam with(nolock) 
				where cam.cam_id = @cam_id
			else
				if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
					insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
					select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
					from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
					where user_id = @user_id and tipo = 1
				end
				else begin
					insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
					select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
					from ccCamps cam (nolock) 
					where cam_activo=1 
				end
		end



		insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
		select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
		select A.*,dateUpdate from #Tcamps A
		left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
		where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
		group by cam_id


		
		if (select count(*) from #Tcamps2)>0 begin

			insert into #temccocallsoutsource(cam_id,Pend)
			SELECT ccos.cam_id, count(ccos.cam_id) as Pend
			FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
			join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
			WHERE cal_status in(0, 7)
			GROUP BY ccos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT A.cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
			join #Tcamps2 B on A.cam_id = B.cam_id
			GROUP BY A.cam_id	

		
			if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
			update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
			end
			else begin
				While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
					set rowcount 1
					select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
					set rowcount 0
					EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
					update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
				end
			end

			declare @TotalNew table(
					cam_id int primary key,
					OverallTotalNew int 
				)
			

			begin Tran updateccCampsNvosCB

				insert into @TotalNew
				select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
				where CampNvosCB.id = tcamp.cam_id

				delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
				where CampNvosCB.id = tcamp.cam_id

				INSERT into ccCampsNvosCB 
				SELECT cams.cam_id, cams.cam_descripcion,
				isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
				isNull(cs.Pend,0) as pend,
				isNull(wt.Pro,0) as pro,
				isNull(cams.procesando,0) cam_procesando,
				isNull(cams.cam_tipojobs,0) cam_tipojobs,
				isNull(wt.Fin,0) Fin,
				isNull(cams.cantidad,0) cantidad,
				getdate(),
				--isnull(T.OverallTotalNew,0)  as OverallTotalNew
				isnull(
				case T.OverallTotalNew
				when 0 then 
					case cams.cam_tipojobs
					when 0 then wt.New + wt.Cb
					when 1 then wt.Cb
					else wt.New end 
				else T.OverallTotalNew end
				,0)  as OverallTotalNew
				FROM #Tcamps2 cams with(nolock)
				LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
				LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
				LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

			COMMIT TRAN updateccCampsNvosCB
		end

		if @isExecOutbound = 0 begin

		if @Tipo = 2 begin
			-- devuelve resultado de la taba, solo las camps del usuario
			SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
			isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
			FROM #Tcamps tcam
			left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
			LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
			inner join cccamps cc (nolock) on res.id=cc.cam_id
		end
		else 
			SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
			cc.aggressionFactor, OverallTotalNew
			FROM ccCampsNvosCB res (nolock)
			LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
			inner join cccamps cc (nolock) on res.id=cc.cam_id
			WHERE res.id = @cam_id
		end

		drop table #Tcamps
		drop table #Tcamps2
		drop table #temccocallsoutsource
		drop table #temWorkinTable

		return(0)

	end'
	EXEC(@sql)
-------------------------------------------------------------------------------------------------------
	SET @process = 'Alter SP ccsp_Multimedia2 Se agrega parametro @multimediaType'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL
, @senderId INT = NULL,@camType bit=0
,@multimediaType int =null
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista Cam Or  ACD
		if @camType=0 begin		
			SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccInbound A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE (@inboundId IS NULL OR @inboundId = A.Inbound_id)
			and (@multimediaType is null or @multimediaType =-1 or A.chat=@multimediaType)
		end
		else begin
			SELECT DISTINCT A.cam_id AS Id,convert(tinyint, case when A.CampType =5  then A.CampType else 1 end) AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccCamps A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE (@inboundId IS NULL OR @inboundId = A.cam_id)
			and (@multimediaType is null or @multimediaType =-1 or A.CampType=@multimediaType)
		end
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes
		if @camType=0 begin
			SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
			FROM ccRIAWorkGroupUsers A
			INNER JOIN ccusers B ON A.User_id = B.User_id
			INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
			INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id  and D.IDArea is not null
			LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
			WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
			and (@multimediaType is null or @multimediaType =-1 or D.chat=@multimediaType)
			ORDER BY A.User_id
		end
		else begin
			SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
			FROM ccRIAWorkGroupUsers A
			INNER JOIN ccusers B ON A.User_id = B.User_id
			INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
			INNER JOIN ccCamps D ON C.idCampEsp = D.cam_id  and D.IDArea is not null
			LEFT JOIN ccskills S ON S.inbound_id = D.cam_id AND S.user_id = B.user_id
			WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
			and (@multimediaType is null or @multimediaType =-1 or D.CampType=@multimediaType)
			ORDER BY A.User_id
		end
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE (@senderId IS NULL OR @senderId = A.contactMeanOutId) and A.meanContactTypeId = 1
	END
	ELSE IF @action = 4
	BEGIN --List ACD Whatsapp
		if @camType=0 begin
			SELECT cast(Inbound_id as int) AS Id
			FROM ccInbound
			WHERE chat=5
		end
		else begin
			SELECT cast(cam_id as int) AS Id
			FROM ccCamps
			WHERE CampType = 5
		end
	END
END'
	EXEC(@sql)

	SET @process = 'Alter SP ccsp_GetInfoDash Se modifica para que se valide que inserta la informacion y no tenga flujo repetido'
	SET @sql = 'ALTER procedure [dbo].[ccsp_GetInfoDash]
@CampId as smallint
as
set nocount on				
declare @upd_date as datetime
declare @cps  as int 
declare @today datetime

select @cps = [valor] from ccSettings  where setting_id=238
select
	@upd_date = date_update
from ccCampsInfo with(nolock) where cam_id = @CampId

set @today=convert(date,getdate(),121)

if @upd_date is null begin
	insert into ccCampsInfo(cam_id,contact_reg,dial_retries,date_update,calls_per_second)
	values(@CampId,0,0,getdate(),@cps)

	set @upd_date=@today
end

select @today,datediff(ss, @upd_date, getdate())

if (datediff(ss, @upd_date, getdate()) > 300) begin
	if not exists(select cam_id from ccocallsout with(nolock)
	where cam_id=@CampId and statuscall_id=13 and cal_inicio>= @today)
	begin
		update ccCampsInfo
			set contact_reg=0, dial_retries=0, date_update = getdate(), calls_per_second=@cps
		where cam_id = @CampId		
	end else
	begin

		declare @vop1 decimal(5,2)
		declare @vop2 decimal(5,2)
		declare @vop3 decimal(5,2)
		declare @vop4 decimal(5,2)

		select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
		where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
		group by cam_id
		select @vop2 = count(distinct(callout_id)), @vop4 = count(distinct telefono) from ccoLogDials with(nolock) 
		where cam_id = @CampId and fecha >= @today
		group by cam_id
		select @vop3 = count(distinct telefono) from ccoLogDials with(nolock) 
		where cam_id = @CampId and fecha >= @today
		group by cam_id, Telefono having count(1) > 1
		
		select @vop1,@vop2,@vop3,@vop4
		update ccCampsInfo set
			 contact_reg=case when @vop2=0 then 0 else (@vop1/@vop2)*100 end
			, dial_retries=case when @vop4=0 then 0 else(@vop3/@vop4)*100 end
			, date_update=getdate()
	end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
	EXEC(@sql)

	SET @process = 'Alter Procedure ccsp_RIA_ABCCamps DECLARE @CampTypeNormal INT = 0 se pone default cero'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int = null,
@Descripcion varchar(40) = null,
@Cam_id varchar(1000),
@Activa tinyint = null,
@IDArea smallint = null,
@frame tinyint = null, 
@MirrorInbound_Id smallint = null,
@Prefijo varchar(40) = null
as
set nocount on

if @option = 0
	begin
		select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
		from ccCamps as CAMP with(nolock) 
		left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
		return(0)
	end

if @option = 1 -- select Camp
	begin
		select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
		prefijo as Prefijo
		from ccCamps a1 with(nolock) 
		inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
		return(0)
	end

if @option = 4 --Delete
	begin
		if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
		begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campa?a, esta asociada a una especialidad''
			else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings with(nolock) where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
		end

		delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
		insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
		Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
		Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
		delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
		delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
		return(0)
	end

if @option = 2 --Insert
	begin
	declare @new_cam_id smallint
	declare @isAssingPortbyCam bit

	DECLARE @CampTypeNormal INT = 0

	if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
		begin
		select -1 --, ''Nombre en Uso''
		return(0)  
		end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1
	declare @pref int
	select  @pref = valor from ccSettings where setting_id = 201
	if (@pref = 0)
		set @Prefijo = ''''


	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

	if @@rowcount = 1 begin
		select @new_cam_id = scope_identity()
		if not exists (select * from ccCampsExtend where cam_id = @new_cam_id) begin
			Insert into ccCampsExtend (cam_id) values (@new_cam_id);
		end
	end
	else
		begin
		select -2 --, ''Error al crear campa?a''
		return(0)
		end

	if isnull(@MirrorInbound_Id, 0)<>0
		begin
		if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
			begin
			select -3 -- Error al asignar campa?a a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
			end

		update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
		end
	set @isAssingPortbyCam=1

	select @isAssingPortbyCam=valor from ccSettings where setting_id=232

	if @isAssingPortbyCam=1 begin
		insert into ccoDialerCamp (dialer_id, cam_id) 
		select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
	end

	insert into ccCalifCamp (calif_id, cam_id, tipo) 
	select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

	If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
		end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

	--inserta la lista negra por default
	if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
	begin
		declare @tempId as int = 0
		select @tempId = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end

	--select * from cctiposlistanegra

	select @new_cam_id
	return(0)
	end

if @option = 3 -- Update
	begin
		if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		insert into ccRIAGraphics (frame,type_id) values (@frame,1)

		Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

		update ccRIACampsGraph with(rowlock)
		set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		where cam_id = @Cam_id

		return(0)
	end

	if @option = 5 --Obtener relaciones de campa?as - campa?as
	begin
		if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
		(@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
		begin
		select -3 -- Campa?a invalida
		return(0)
		end
				
	if @descripcion=0
		set @descripcion = null

	update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
					
	else
		begin
		delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

		end

	return(0)
	end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

if @option = 7 -- Checa si la campa?a no tiene grabaciones y se puede modificar el prefijo
	begin	
		select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
		--select 0 as Grabaciones	
	end

if @option = 8 -- Checa si la campa?a tiene asignada una campa?a tipo encuesta
	begin	
		SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_DLRSaveDialResult Modificacion Se obtine el @cal_key si es null para no hacer doble update ccoLogDials'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
                @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
                @tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
                @canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
                @ani varchar(32)=''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
    DECLARE @logDial_id INT;
    DECLARE @tAnswerBitFinal AS DATETIME;
    DECLARE @tTotal SMALLINT;

    SELECT @RecicleSIC = ISNULL(valor, 0)
    FROM ccSettings
    WHERE setting_id = 60;

    SELECT @tTotal = @tDialing + @tAnswerBit;

    SELECT @tNow = GETDATE();

    SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);


-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1 and @cal_key = ''''
    BEGIN
    SELECT @cal_key = cal_key
    FROM ccoCallsOutSource WITH(NOLOCK)
    WHERE @callout_id = callout_id;         
END;

IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
               fnGetTipoLlamada( @Telefono ), @ani;
    END;
         ELSE
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
               @Telefono ), @ani;
    END;

    SELECT @logDial_id = SCOPE_IDENTITY();

    IF @RecicleSIC = 1
    BEGIN
        UPDATE ccoWorkingTable WITH(ROWLOCK)
          SET tipoResDial_id = @tipoResDial_id
        WHERE callout_id = @callout_id;
    END;

    -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1
    BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
    WHERE cal_id = @call_id AND cal_puerto = 0;

        EXEC ccsp_CstoCalculaCosto @call_id;
    END;

    -- inserta informacion para reportes de workgroup
    INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
           SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
           FROM ccRIACampEspWG
WHERE tipo = 1 AND IdCampEsp = @cam_id;

    -- Guarda configuracion de TipoDialingMode
    UPDATE ccoLogDials WITH(ROWLOCK)
      SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
    WHERE logDial_id = @logDial_id;
    SET NOCOUNT OFF;
END;

    SELECT @logDial_id as LogDialId'
	EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_GetAgentECRelations se agrega parametro @camId para filtrar por la campaña'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentECRelations]
@User_id smallint,@action int =0,@camId int=0
AS
set nocount on

declare @idioma as bit, @tipo as varchar(6)

if @action=0 begin
	select distinct ''Tipo''=1, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, E.cli_id
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
	union
	select distinct ''Tipo''=2, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		order by ''Tipo''
end
else begin
	select distinct 1 tipo, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, isnull(E.cli_id,0) cli_id
	,right(''0''+cast(1 as varchar(1)),1) + right(''00000''+cast(E.Inbound_id as varchar(5)),5)
	+ right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias
		from ccInboundAgentes G 
		inner join ccInbound E on G.inbound_id = E.inbound_id
		inner join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		and (@camId =0 or E.Inbound_id=@camId)
		union
	select distinct 2 tipo, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
	,right(''0''+cast(2 as varchar(1)),1) + right(''00000''+cast(C.cam_id as varchar(5)),5)
	+ right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias
		from ccCamps C 
		inner join ccCampsAgente CA on C.cam_id = CA.cam_id
		inner join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		and (@camId =0 or C.cam_id=@camId)
		order by ''Tipo''

end'
	EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_GetAllAgentsECRelations se agrega parametro @camId para filtrar por la campaña'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAllAgentsECRelations]
@User_id varchar(max),@camId int=0
AS
set nocount on

DECLARE @userTable TABLE (Id int,userId int)
DECLARE @userIn TABLE (userId int)

insert into @userTable select * from dbo.fn_RIASplitDelimited(@User_id,''|'')

insert into @userIn
select distinct A.user_id
	from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
	inner join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
	inner join @userTable B on A.User_id = B.userId
	Where A.status > 0


select distinct
	case when CA.user_id is null and uIn.userId is null then 0
	when CA.user_id is null and uIn.userId is not null then 1
	when CA.user_id is not null and uIn.userId is null then 2
	else 3 end tipo,
	isnull(C.cam_id,0) as cam_id, B.user_id, isnull(prioridad,0) prioridad, isnull(skill,0) skill, isnull(C.cli_id,0) cli_id
	from @userTable A
	inner join ccUsers B  on A.userId = B.user_id and B.TipoUser_id =1
	left join ccCampsAgente CA on A.userId = CA.user_id
	left join ccCamps C  on C.cam_id = CA.cam_id
	left join @userIn uIn on uIn.userId = B.user_id
	Where B.status > 0 
	and (@camId=0 or (C.cam_id is not null and C.cam_id=@camId) )
	order by B.user_id,cam_id
'
	EXEC(@sql)

	SET @process = 'DEV1-335 Alter SP ccsp_OUTResetJobs se agrega parametro @today para buscar solo desde la ultima vez que se inicio la campaña en lugar del inicio del dia'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTResetJobs] 
@camid AS INT= 0,@today DATETIME=null
AS
BEGIN

  CREATE TABLE #TempccoLogDials ( 
    callout_id INT, PRIMARY KEY (callout_id)
  ); 

  if @today is null begin
	SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
  end
  else begin
	SELECT @today =dateadd(hh,-1,@today)
  end

  
  IF @camid = 0
  BEGIN
    INSERT INTO #TempccoLogDials
         SELECT callout_id
         FROM ccoLogDials AS ld WITH(NOLOCK)
         WHERE fecha >= @today
         GROUP BY callout_id;
  END;
     ELSE
    IF @camid > 0
    BEGIN
      INSERT INTO #TempccoLogDials
           SELECT callout_id
           FROM ccoLogDials AS ld WITH(NOLOCK)
           WHERE cam_id = @camid AND 
             fecha >= @today			
           GROUP BY callout_id;
    END;

  -- CALLBACKS Se han marcado recientemente
  UPDATE ccoWorkingTable WITH(ROWLOCK)
    SET cal_status = 1
  FROM ccoWorkingTable wt
     INNER JOIN
     #TempccoLogDials ld
     ON wt.callout_id = ld.callout_id
  WHERE wt.cal_status = 2   

  IF @camid = 0
  BEGIN
    -- NUEVAS - Nunca se han marcado
    UPDATE ccoWorkingTable --WITH(ROWLOCK)
      SET cal_status = 0
    WHERE cal_status = 2;
  END;
     ELSE
  BEGIN  
    -- NUEVAS - Nunca se han marcado	
    UPDATE ccoWorkingTable WITH(ROWLOCK)
      SET cal_status = 0
    WHERE cal_status = 2 AND 
        cam_id = @camid;
  END;

  DROP TABLE #TempccoLogDials;
END;'
	EXEC(@sql)

-------------------------------------------BEGIN MACL CW-7990, CW-7991--------------------------------------------------
SET @process = 'CW-7990 - Se actualiza ccsp_RecycleByDispositionOrResult para que coincida el reciclaje de llamadas al reciclar por resultado de marcacion'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RecycleByDispositionOrResult]
		@Action SMALLINT = 0,
		@cam_id SMALLINT = 0,
		@result_id SMALLINT = 0,
		@disposition_id SMALLINT = 0,
		@subDisposition_id SMALLINT = 0
		AS
		BEGIN
			DECLARE @date DATE = CONVERT(VARCHAR,GETDATE(),23);
			DECLARE @count INT = 0;

			IF(@Action = 1) BEGIN --Count registers to recycle by Result
				SELECT DISTINCT COUNT(*) OVER() AS TotalRecords
				FROM ccoLogDials ld
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE ld.fecha > @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(ld.canBeRecycled, 1) = 1
				AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
				AND ld.tipoResDial_id = @result_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				AND ld.cam_id = @cam_id
				GROUP BY ld.callout_id
				RETURN 0;
			END

			IF(@Action = 2) BEGIN --Count registers to recycle by Calif
				SELECT COUNT(DISTINCT co.callout_id) AS TotalRecords
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND ISNULL(co.califSub_id, 0) <= 0
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				RETURN 0;
			END

			IF(@Action = 3) BEGIN --Count registers to recycle by CalifSub
				SELECT COUNT(DISTINCT co.callout_id) AS TotalRecords
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND co.califSub_id = @subDisposition_id
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				RETURN 0;
			END

			IF(@Action = 4) BEGIN --Recycle registers to load by Result
				SELECT ld.callout_id, ld.Telefono, ld.fecha,
				ROW_NUMBER() OVER (PARTITION BY ld.callout_id ORDER BY ld.fecha ASC) AS RowFilter
				INTO #tmpCalloutIdResult
				FROM ccoLogDials ld
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = ld.callout_id and cs.cam_id = ld.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE ld.fecha > @date
				AND cs.cal_status not in (0,1,7)
				AND NOT EXISTS (select value FROM fn_RIASplitDelimited(ISNULL(cs.recycledByResult, ''0''), '','') where value = CONVERT(VARCHAR(2), @result_id))
				AND ISNULL(ld.canBeRecycled, 1) = 1
				AND ld.tipoResDial_id = @result_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				AND ld.cam_id = @cam_id
				GROUP BY ld.callout_id, ld.Telefono, ld.fecha

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutIdResult tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				UPDATE cs SET cs.cal_status = 0, cs.recycledByResult = ISNULL(cs.recycledByResult, '''') + '','' +CONVERT(VARCHAR(2), @result_id),
				cs.recyclePhone = CASE 
					WHEN tc.Telefono = cs.cal_telefono THEN 1
					WHEN tc.Telefono = cs.cal_telefono2 THEN 2
					WHEN tc.Telefono = cs.cal_telefono3 THEN 3
					WHEN tc.Telefono = cs.cal_telefono4 THEN 4
					ELSE 5 END, 
				cs.recycleType = 0
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutIdResult tc on cs.callout_id = tc.callout_id
				WHERE tc.RowFilter = 1

				UPDATE ld SET ld.canBeRecycled = 0
				FROM ccoLogDials ld
				INNER JOIN #tmpCalloutIdResult tc on ld.callout_id = tc.callout_id
				WHERE ld.fecha >= @date
				AND ld.tipoResDial_id = @result_id

				SELECT @count = COUNT(*) from #tmpCalloutIdResult

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutIdResult

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END

			IF(@Action = 5) BEGIN --Recycle registers to load by Calif
				SELECT co.callout_id INTO #tmpCalloutId
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND ISNULL(co.califSub_id, 0) <= 0
				AND cs.cam_id = @cam_id
				AND (wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id

				UPDATE cs SET cs.cal_status = 0, cs.recycledByDisposition = 1, cs.recycleType = 1
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutId tc on cs.callout_id = tc.callout_id

				UPDATE co SET co.canBeRecycled = 0
				FROM ccoCallsOut co
				INNER JOIN #tmpCalloutId tc on co.callout_id = tc.callout_id
				WHERE co.cal_Inicio >= @date

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutId tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				SELECT @count = COUNT(*) from #tmpCalloutId

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutId

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END

			IF(@Action = 6) BEGIN --Recycle registers by CalifSub
				SELECT co.callout_id INTO #tmpCalloutIdSub
				FROM ccoCallsOut co
				INNER JOIN ccoCallsOutSource cs 
				ON cs.callout_id = co.callout_id and cs.cam_id = co.cam_id
				LEFT JOIN ccoWorkingTable wt on cs.callout_id = wt.callout_id
				WHERE co.cal_Inicio >= @date
				AND cs.cal_status not in (0,1,7)
				AND ISNULL(co.canBeRecycled, 1) = 1
				AND ISNULL(recycledByDisposition, 0) = 0
				AND co.calif_id = @disposition_id
				AND co.califSub_id = @subDisposition_id
				AND cs.cam_id = @cam_id
				AND(wt.callout_id IS NULL OR wt.cal_status = 1)
				GROUP BY co.callout_id

				DELETE wt
				FROM ccoWorkingTable wt
				INNER JOIN #tmpCalloutIdSub tc on wt.callout_id = tc.callout_id
				WHERE wt.cal_status = 1

				UPDATE cs SET cs.cal_status = 0, cs.recycledByDisposition = 1, cs.recycleType = 1
				FROM ccoCallsOutSource cs
				INNER JOIN #tmpCalloutIdSub tc on cs.callout_id = tc.callout_id

				UPDATE co SET co.canBeRecycled = 0
				FROM ccoCallsOut co
				INNER JOIN #tmpCalloutIdSub tc on co.callout_id = tc.callout_id
				WHERE co.cal_Inicio >= @date

				SELECT @count = COUNT(*) from #tmpCalloutIdSub

				EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp @camp_id = @cam_id, @top = @count

				DROP TABLE #tmpCalloutIdSub

				SELECT cam_descripcion FROM ccCamps where cam_id = @cam_id

				RETURN 0;
			END
		END'

EXEC (@sql)

SET @process = 'CW-7990 - Se actualiza ccsp_GalateaLoadUsersForManagement para obtener usuarios inactivos'
SET @sql ='ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT = null,
 @Username VARCHAR(200)=null,
 @userId INT = 0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
	AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END




IF @option = 4 -- supervisores en Area/Sistema
BEGIN
	DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
	INSERT INTO @Admins
	SELECT User_id as UserId,
	LOGIN as Username,
	Nombres as Names,
	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '''')
	END as LastName,

	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '''')
	END as OptionalExtraName,

	isnull(IDArea, 0) as AreaId
	FROM ccusers
	WHERE TipoUser_id = 2 AND STATUS = 1


	IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
		ORDER BY Username, Names, LastName, UserId
	END
	ELSE BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		ORDER BY Username, Names, LastName, UserId
	END
	Return(0)
END

IF @option = 5 --Usuarios inactivos por mas de 60 días por área
	BEGIN
		SELECT [User_id] as UserId,
		LOGIN as Username
		FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
		AND @AreaId = IDArea
		RETURN 0;
	END'

EXEC (@sql)

SET @process = 'CW-7990 - Se actualiza ccsp_RIA_ABCAreas para filtrar usuarios inactivos'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
		@option smallint,
		@IDArea smallint,
		@Descripcion varchar(40),
		@maxMails smallint = 3, 
		@maxChats smallint = 3,
		@maxTweets smallint = 3,
		@defCampaing smallint = NULL, 
		@isKolob bit = 0
		AS

		set nocount on



		if @option = 1 begin --Selected Area
		 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
		 isnull(users,0) users, isnull(admins,0) admins,
		 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets
		 from ccRIACat_Areas a (nolock)
		 left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
		 left join (select IDArea,count(case when TipoUser_id = 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60)  then 1 else null end) users, count(case when TipoUser_id > 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60) then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(0,0) when 0 then isnull(IDArea,0) else 0 end group by IDArea) userswg on userswg.IDArea=a.IDArea
		 left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
		 left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
		 where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
		 when 0 then isnull(a.IDArea,0) else @IDArea end
		 order by AreaName
		 return(0)
		end
		else if @option=2 begin --Insert Area
			 if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion) begin
			  select -1 as result,-1 as idAreas--, Nombre en Uso
			  return(0)
			 end
			Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,defCampaing,CreateDate) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@defCampaing,Getdate())
			select 1 as result, scope_identity() as idAreas--, Area Insertada
			return(0)
		end
		else if @option=3 begin--Update Area
			if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
				Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea
			else
				Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea

			if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
				Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
		 return(0)
		end

		else if @option=4 begin --Delete Area
		 if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
		  or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
		 begin
		  select -1
		  return(0)
		 end

			declare @DWorkGroups as varchar(500)

			 insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			 select user_id,cam_id,prioridad,skill,rel_id,IDWG
			 from ccCampsAgente
			 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
			 select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
			 from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
			 Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
			 select user_id,cam_id,tipo,IDWG,monitored
			 from ccSupervisorCam
			 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
			 delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
			 delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
			 where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

			 Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
			 Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

			 Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
			 Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
			 Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

			 select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
			 Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

			 if (select valor from ccSettings where setting_id=95)=1
			 begin
			  Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
			  Update ccCamps set IDArea=NULL where IDArea=@IDArea
			  Update ccUsers set IDArea=NULL where IDArea=@IDArea
			 end

			 Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

			 select @DWorkGroups

		 return(0)
		end
		else if @option=5 begin -- Select Areas Campaings and show its default Campaing 
			select A.IDArea as IDArea, C.cam_id as campID, C.cam_descripcion as campName,
			case when A.defCampaing=C.cam_id then 1 else 0 end as isDefault
			from ccRIACat_Areas A (nolock)
			inner join ccCamps C on A.IDArea=C.IDArea
			order by IDArea asc, isDefault desc, campName
			return(0)
		 end'

EXEC (@sql)

SET @process = 'CW-7990 - Se actualiza ccsp_GalateaAreas para filtrar usuarios inactivos'
SET @sql = 'ALTER procedure [dbo].[ccsp_GalateaAreas] 
	@option int = 2,
	@IDArea smallint = 0,
	@Descripcion varchar(40) = NULL,
	@maxMails smallint = 3,
	@maxChats smallint = 3,
	@maxTweets smallint = 3,
	@defCampaing smallint = 0,
	@movesfromArea bit = 0,
	@userId int = NULL,
	@groupAreas varchar (MAX) = NULL
AS

SET NOCOUNT ON;
	
	declare @opt int = @option -1
	if @option = 1 --Superuser info
	begin
		create table #campsIds(
			id int,
			cadena varchar(max)
		)
			
		declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
			
		set @idPivots =''''
		set @idConcat=''''
			
		select @idPivots=@idPivots+Id+'','',
			@idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
			''
			from (
			select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
			)x
			
		set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
		set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
			
		set @sql=''
			select IDArea,''+@idConcat+'' from 
			(	select IDArea, cam_id from ccCamps) as T
			PIVOT (
			max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

		insert into #campsIds
		exec(@sql)
			
		select a.IDArea Id, 
			a.AreaName Name, 
			a.StatusArea Status, 
			a.maxMails Mails, 
			a.maxChats Chats, 
			a.maxTweets Tweets, 
			a.CreateDate as CreateDate,			
			ISNULL(b.cadena, 0) as CampaignIds  
		from ccRIACat_Areas a --Falta el datetime 
		left join #campsIds b on a.IDArea = b.id

		drop table #campsIds
	end
	if @option = 2 -- Select de las areas
	begin
		IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
		Create table #Areas(
			IDArea smallint,
			AreaName varchar(MAX),
			maxChats tinyint ,
			maxMails tinyint ,
			users int,
			admins int,
			camps int,
			acds int,
			maxTweets tinyint
		)
		insert into #Areas
		EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1
		select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
		from #Areas a
		inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea
	end
	if @option = 3 -- Insert new area
	begin
	IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
		Create table #InsertAreas(
			result int,
			idAreas decimal
		)
		insert into #InsertAreas
		EXEC ccsp_RIA_ABCAreas 
			@option = @opt,
			@IDArea=@IDArea,
			@Descripcion=@Descripcion,
			@maxMails=@maxMails,
			@maxChats=@maxChats,
			@maxTweets=@maxTweets,
			@defCampaing=@defCampaing
		if (select result from #InsertAreas) = 1 and @movesfromArea = 1
			begin
				Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
			end
		Select * from #InsertAreas
	end
	if @option = 4 -- Delete Areas
	begin
		IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
		SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
		
		
		if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
		  or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
		BEGIN
			Select -1 as result
		END
		ELSE
		BEGIN
			declare @DWorkGroups as varchar(500)
			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			select user_id,cam_id,prioridad,skill,rel_id,IDWG
			from ccCampsAgente
			where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
			select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
			from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
			Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
			select user_id,cam_id,tipo,IDWG,monitored
			from ccSupervisorCam
			where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
			delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
			delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
			where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

			Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
			Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

			Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
			Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
			Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

			select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
			Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

			if (select valor from ccSettings where setting_id=95)=1
			begin
			Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
			Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
			Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
			end

			Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

			select 1 as result
		END
	end
	if @option = 5 -- update Areas
	begin
		if(@Descripcion is null)
		begin
			Update ccRIACat_Areas set maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=@defCampaing where IDArea=@IDArea
		end
		else 
		if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
			begin
				select -1 as result
				return
			end
		else
			begin
				update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=@defCampaing where IDArea=@IDArea	
			end
		if @maxChats is not null
			begin
				Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
			end
		if @movesfromArea = 1
		Begin
			Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
		End
		select 1 as result
	end
SET NOCOUNT ON;'

EXEC (@sql)
------------------------------------------------------END MACL----------------------------------------------------
SET @process = ''
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''ccCallsIn''
		AND COLUMN_NAME = ''cal_final''
	)
	BEGIN
		ALTER TABLE ccCallsIn
		ADD cal_final DATETIME NULL
	END
'
EXEC(@sql)


SET @process = ''
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_IVRUpdateCallEndNew'')
	BEGIN
	    DROP PROCEDURE ccsp_IVRUpdateCallEndNew;
	END
'

EXEC(@sql)

SET @process = ''
SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
	@cal_id INT,
	@cal_tIVRCallDuration INT,
	@statuscal_id TINYINT, 
	@cal_opciones VARCHAR(10),
	@cal_colgada TINYINT,
	@User_id SMALLINT,
	@cal_extension VARCHAR(7),
	@tWait SMALLINT,
	@cbPhone VARCHAR(20)
	AS
	SET NOCOUNT ON

	UPDATE ccCallsIn 
	SET statusCall_id = 
		CASE 
			WHEN @statuscal_id IN (2, 3, 4, 7, 8) THEN @statuscal_id 
			ELSE 
				CASE 
					WHEN statusCall_id = 5 THEN 6 
					ELSE statuscall_id 
				END 
		END, 
		user_id = 
		CASE 
			WHEN user_id = 0 AND @User_id > 0 THEN @User_id 
			ELSE user_id 
		END, 
	cal_extension = 
		CASE 
			WHEN LEN(cal_extension) = 0 AND LEN(@cal_extension) > 0 THEN @cal_extension 
			ELSE cal_extension 
		END, 
	cal_tWait = @tWait, 
	cal_final = getdate() 
	WHERE cal_id=@cal_id

	EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id, @cbPhone
	EXEC ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

	SET NOCOUNT OFF 
'

EXEC(@sql)
-------------------------------------------- END Roberto Nava -------------------------------------------------------
	SET @process = ''
	SET @sql = ''
	EXEC(@sql)
		
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


