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
SET @versionfix = 7
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

	SET @process = 'create table ccSmsSchedules'
	SET @sql = '
	if not exists (select * from sys.tables where name = N''ccSmsSchedules'')
    begin
        create table ccSmsSchedules (sched_id smallint identity, cam_id smallint,iDate datetime, fDate datetime) 
    end
	'
	EXEC(@sql)

	SET @process = 'Add column messagingOrder'
	SET @sql = '
	if not exists (select * from sys.columns where name = N''messagingOrder'' and Object_ID = Object_ID(N''cccamps''))
    begin
	    alter table ccCamps add messagingOrder bit null
    end
	'
	EXEC(@sql)
	
	SET @process = 'Add column autoStart'
	SET @sql = '
	if not exists (select * from sys.columns where name = N''autoStart'' and Object_ID = Object_ID(N''cccamps''))
    begin
	    alter table ccCamps add autoStart bit null
    end
	'
	EXEC(@sql)

	set @process = 'Setting 253 horarios legales'
	set @Sql= 'if not exists(select * from ccsettings where setting_id=253)
		insert ccsettings (setting_id,valor,descripcion,status,tipo,detalle,description,bloadsettings,validate) 
		values (253,''1|07:00|22:00'',''Marcar sólo en horarios permitidos por ley.'',1,''GRL'',''Configuracion el horario permitido indepentiende del horario de la campaña activo|hh:mm|hh:mm ejemplo(1|07:00|22:00)'',''Dial only during compliance schedules.'',1,''^[0-1]\|([0-1]?[0-9]|2[0-3]):[0-5][0-9]\|([0-1]?[0-9]|2[0-3]):[0-5][0-9]$'')
		'
    EXEC(@Sql)

	SET @process = 'KR076000 Validación y eliminación de sp ccsp_RIAConfCamp'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAConfCamp'')
				begin
					DROP PROCEDURE ccsp_RIAConfCamp;
				end
	'
	EXEC(@sql)

	SET @process = 'KR076000 Creación de sp ccsp_RIAConfCamp'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
				AS
				SET NOCOUNT ON

				DECLARE @tableExistsRec TABLE (camId INT PRIMARY KEY, existRec BIT)
				DECLARE @camByUser TABLE (camId INT PRIMARY KEY, isCheck BIT)
				DECLARE @camId INT, @id INT;

				IF NOT EXISTS (
						SELECT *
						FROM ccUsers_Roles
						WHERE User_id = @User_id
							AND Rol_id = 7
						)
				BEGIN
					INSERT INTO @camByUser
					SELECT *, 0
					FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
					WHERE @campID IS NULL
						OR cam_id = @campID
				END
				ELSE
				BEGIN
					INSERT INTO @camByUser
					SELECT cam_id, 0
					FROM ccCamps
					WHERE (
							IDArea > 0
							OR IDArea IS NULL
							)
						AND (
							@campID IS NULL
							OR cam_id = @campID
							)
				END

				WHILE EXISTS (
						SELECT *
						FROM @camByUser
						WHERE isCheck = 0
						)
				BEGIN
					SELECT TOP 1 @camId = camId
					FROM @camByUser
					WHERE isCheck = 0

					IF EXISTS (
							SELECT cam_id
							FROM ccoCallsOut
							WHERE cam_id = @camId
							)
					BEGIN
						INSERT INTO @tableExistsRec
						VALUES (@camId, 1)
					END
					ELSE
					BEGIN
						INSERT INTO @tableExistsRec
						VALUES (@camId, 0)
					END

					UPDATE @camByUser
					SET isCheck = 1
					WHERE camId = @camId
				END

				SELECT a1.cam_id, cam_Descripcion, cam_tNotas, cast(cam_ocupado AS INT) AS cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto AS INT) 
					AS cam_nocontesto, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax AS INT) AS cam_fax, cam_noInt_fax, cam_inter_fax, cast(cam_modomanual AS 
						INT) AS cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial, detectAnswerMachine, 
					detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial AS TINYINT) progDial, cast(excCallBack AS TINYINT) excCallBack, 
					dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall, stopRecording, cast(abandonCallback AS TINYINT) abandonCallback, a3.frame, 
					a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue AS queSize, DNCScrub, callerIdDesc, timeZoneRule
					, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record, 1) AS call_record, cast(startStopRecording AS TINYINT) startStopRecording, 
					leaveRecMessage, manualCallOnChat, callBackSurveyAgent, callBackSurveyClient, CASE 
						WHEN surveycamid IS NULL
							OR surveycamid = 0
							THEN 0
						ELSE 1
						END isRelationSurvey, isnull(a1.funcEspDtmf, 0), isnull(sipHdrFormat, '''') sipHdrFormat, cam_inter_cancelled, prefijo, enbleprefix = CASE 
						WHEN existRec = 0
							THEN 1
						ELSE 0
						END, isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard, isnull(CampType, 0) Chat, isnull(contact.conexionInfo, '''') 
					conexionInfo, isnull(contact.closeConversationTime, 0) closeConversationTime, isnull(contact.answerTimeoutClient, 0) answerTimeoutClient, 
					isnull(contact.allowFileAttachments, 0) allowFileAttachments, isnull(selectRotativeANI, 0) selectRotativeANI, ISNULL(rotativeAlgo, 0) rotativeAlgo
				FROM ccCamps a1
				INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
				INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
				INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
				LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
				ORDER BY cam_descripcion

				RETURN (0)

				SET NOCOUNT OFF
	'
	EXEC(@sql)

	SET @process = 'KR076000 Validación y eliminación de sp ccsp_GalateaGetOutboundConfiguration'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
				begin
					DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
				end
	'
	EXEC(@sql)

	SET @process = 'KR076000 Creación de sp ccsp_GalateaGetOutboundConfiguration'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT, @campID INT
				AS
				BEGIN
					DECLARE @AllCampaigns TABLE (
						cam_id SMALLINT, cam_Descripcion VARCHAR(60), cam_tNotas SMALLINT, cam_ocupado 
						SMALLINT, cam_noInt_ocupado SMALLINT, cam_inter_ocupado SMALLINT, 
						cam_nocontesto SMALLINT, cam_noInt_nocontesto SMALLINT, cam_inter_nocontesto 
						SMALLINT, cam_fax SMALLINT, cam_noInt_fax SMALLINT, cam_inter_fax SMALLINT, 
						cam_modomanual SMALLINT, ANI VARCHAR(15), cam_ShowCalifWnd BIT, 
						cam_StartTimerOnHangUp BIT, editableCallKey BIT, cam_tNoContesta SMALLINT, 
						iTipoDial SMALLINT, detectAnswerMachine SMALLINT, detectVoiceMail SMALLINT, 
						compliance SMALLINT, cam_inter_graba SMALLINT, cam_noint_graba SMALLINT, 
						progDial SMALLINT, excCallBack SMALLINT, dialOrder SMALLINT, dialPrefix VARCHAR
						(10), dialPrefixMan VARCHAR(10), dialPrefixXfe VARCHAR(10), listenManualCall 
						BIT, stopRecording BIT, abandonCallback BIT, frame SMALLINT, t_autoCB SMALLINT, 
						id_anilist INT, tDialonWrapUp SMALLINT, viewMode TINYINT, queSize SMALLINT, 
						DNCScrub INT, callerIdDesc VARCHAR(15), timeZoneRule INT, callsBySurvey INT, 
						ivrScript INT, surveyPctg INT, call_record SMALLINT, startStopRecording BIT, 
						leaveRecMessage BIT, manualCallOnChat BIT, callBackSurveyAgent BIT, 
						callBackSurveyClient BIT, isRelationSurvey BIT, funcEspDtmf INT, sipHdrFormat 
						VARCHAR(255), cam_inter_cancelled SMALLINT, prefijo VARCHAR(40), enbleprefix 
						BIT, exitAssisted BIT, previewDiscard BIT, CampType INT, conexionInfo VARCHAR(50
						), closeConversationTime SMALLINT, answerTimeoutClient INT, 
						allowFileAttachments BIT, selectRotativeANI int, rotativeAlgo tinyint
						)

					declare @numbers varchar(max)
					select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where camp_id = 0 and status = 1

					INSERT INTO @AllCampaigns
					EXEC ccsp_RIAConfCamp @adminID, @campID

					SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall 
						ListenManualCall, stopRecording StopRecording, abandonCallback 
						AbandonCallBack, t_autoCB AutoCB, id_anilist IdIstANI, tDialonWrapUp 
						TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, 
						timeZoneRule TimeZoneRule, callsBySurvey CallsBySurvey, ivrScript IvrScript, 
						surveyPctg SurveyPctg, call_record CallRecord, startStopRecording 
						StartStopRecording, leaveRecMessage LeaveRecMessage, manualCallOnChat 
						ManualCallOnChat, callBackSurveyClient CallBackSurveyClient, 
						callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf, 
						sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix, prefijo Prefix, dialOrder 
						DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas 
						CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy, 
						cam_inter_ocupado CamInterBusy, cam_nocontesto CamNoAnswer, 
						cam_noInt_nocontesto CamNoIntNoAnswer, cam_inter_nocontesto 
						CamInterNoAnswer, (cam_inter_cancelled / 60) CamInterCancelled, 
						cam_fax CamFax, cam_noInt_fax CamNoIntFax, cam_inter_fax CamInterFax, 
						cam_modomanual CamModoManual, ANI, cam_StartTimerOnHangUp 
						CamStartTimerOnHangUp, editableCallKey EditableCallKey, cam_tNoContesta 
						CamTNoAnswer, iTipoDial CamIntensiveDialing, detectAnswerMachine 
						DetectAnswerMachine, detectVoiceMail DetectVoiceMail, compliance Compliance, 
						cam_inter_graba CamInterRecord, cam_noint_graba CamNoIntRecord, excCallBack 
						ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted 
						ExitAssistedDialMode, previewDiscard PreviewDiscard, CampType, 
						conexionInfo ConexionInfo, closeConversationTime CloseConversationTime, 
						answerTimeoutClient MUTimeOutClient, allowFileAttachments 
						AllowFileAttachments, @numbers AS FreeNumbers, selectRotativeANI SelectRotativeANIManualCall, 
						rotativeAlgo RotativeAlgo
					FROM @AllCampaigns
					WHERE cam_id = @campID
				END
	'
	EXEC(@sql)

	SET @process = 'KR076000 Validación y eliminación de sp ccsp_RIAUpdateCamConfig'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfig'')
				begin
					DROP PROCEDURE ccsp_RIAUpdateCamConfig;
				end
	'
	EXEC(@sql)

	SET @process = 'KR076000 Creación de sp ccsp_RIAUpdateCamConfig'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
				 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 3 THEN @progDiaL ELSE 1 END),
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
	'
	EXEC(@sql)


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