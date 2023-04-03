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
SET @versionfix = 9
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

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------Begin B Dunzz  ---------------------------------------------------------
	set @process = 'KR051000 Modificacion tabla ccMenus'
	set @sql = '
		if not exists (select * from ccMenuUser where id_User = 1 and id_Menu = 3230 and [type] = 3 )
		begin
			insert into ccMenuUser (id_User, id_Menu, [type]) values (1, 3230, 3);
		end
		
		update ccMenus 
		set release = ''3f2db252ad1e8747e879159ed8498ccf30092c85618c7a5edde85033f5b8cfac'',
		type = 3
		where menu_id = 3230;
	'
	EXEC(@sql)
	---------------------------------------End B Dunzz  ---------------------------------------------------------
	---------------------------------------Begin Ulises Espinosa  ---------------------------------------------------------
	SET @process = 'TT4479 -adminKolob - En adminKolob muestra la campaña como chat'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
				@selectRotativeANI int = null
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
				 selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI)

				Where cam_id = @cam_id

				if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
				begin
					EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
				end

				IF (@CampType IS NOT NULL)
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
	';
		EXEC(@sql);
		---------------------------------------End Ulises Espinosa  ---------------------------------------------------------

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
