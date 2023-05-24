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


