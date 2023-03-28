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
SET @versionfix = 8
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
		-------------------------------------------- BEGIN URIEL CABRERA and IVAN MARTIN Add Zipcode To Campaign Configuration ------------------------------
		SET @process = 'Create new table ccCampsExtend, which is an extention to ccCamps. This was done due to the number of settings in ccCamps'
		SET @sql = ''
		EXEC(@sql)

		SET @process = 'Adding parameter ZipCodeSchedule to ccsp_RIAConfCamp as well as inner join with new table ccCampsExtend. Lines (228 and 234)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
					AS
					SET NOCOUNT ON

					DECLARE @tableExistsRec TABLE (
						camId INT PRIMARY KEY
						,existRec BIT
						)
					DECLARE @camByUser TABLE (
						camId INT PRIMARY KEY
						,isCheck BIT
						)
					DECLARE @camId INT
						,@id INT;

					IF NOT EXISTS (
							SELECT *
							FROM ccUsers_Roles
							WHERE User_id = @User_id
								AND Rol_id = 7
							)
					BEGIN
						INSERT INTO @camByUser
						SELECT *
							,0
						FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
						WHERE @campID IS NULL
							OR cam_id = @campID
					END
					ELSE
					BEGIN
						INSERT INTO @camByUser
						SELECT cam_id
							,0
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
							VALUES (
								@camId
								,1
								)
						END
						ELSE
						BEGIN
							INSERT INTO @tableExistsRec
							VALUES (
								@camId
								,0
								)
						END

						UPDATE @camByUser
						SET isCheck = 1
						WHERE camId = @camId
					END

					SELECT a1.cam_id
						,cam_Descripcion
						,cam_tNotas
						,cast(cam_ocupado AS INT) AS cam_ocupado
						,cam_noInt_ocupado
						,cam_inter_ocupado
						,cast(cam_nocontesto AS INT) AS cam_nocontesto
						,cam_noInt_nocontesto
						,cam_inter_nocontesto
						,cast(cam_fax AS INT) AS cam_fax
						,cam_noInt_fax
						,cam_inter_fax
						,cast(cam_modomanual AS INT) AS cam_modomanual
						,ANI
						,cam_ShowCalifWnd
						,cam_StartTimerOnHangUp
						,editableCallKey
						,cam_tNoContesta
						,iTipoDial
						,detectAnswerMachine
						,detectVoiceMail
						,compliance
						,cam_inter_graba
						,cam_noint_graba
						,cast(progDial AS TINYINT) progDial
						,cast(excCallBack AS TINYINT) excCallBack
						,dialOrder
						,dialPrefix
						,dialPrefixMan
						,dialPrefixXfe
						,listenManualCall
						,stopRecording
						,cast(abandonCallback AS TINYINT) abandonCallback
						,a3.frame
						,a1.t_autoCB
						,a1.id_anilist
						,a1.tDialonWrapUp
						,dbo.fn_viewMode(@User_id, 10) viewMode
						,cam_maxqueue AS queSize
						,DNCScrub
						,callerIdDesc
						,timeZoneRule
						,callsBySurvey
						,ivrScript
						,surveyPctg
						,isnull(a1.call_record, 1) AS call_record
						,cast(startStopRecording AS TINYINT) startStopRecording
						,leaveRecMessage
						,manualCallOnChat
						,callBackSurveyAgent
						,callBackSurveyClient
						,CASE 
							WHEN surveycamid IS NULL
								OR surveycamid = 0
								THEN 0
							ELSE 1
							END isRelationSurvey
						,isnull(a1.funcEspDtmf, 0)
						,isnull(sipHdrFormat, '''''''') sipHdrFormat
						,cam_inter_cancelled
						,prefijo
						,enbleprefix = CASE 
							WHEN existRec = 0
								THEN 1
							ELSE 0
							END
						,isnull(exitAssisted, 0) exitAssisted
						,isnull(previewDiscard, 0) PreviewDiscard	
						,isnull(CampType, 0) CampType
						,isnull(contact.conexionInfo, '''''''') conexionInfo
						,isnull(contact.connUser, '''''''') connUser
						,isnull(contact.closeConversationTime, 0) closeConversationTime
						,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
						,isnull(contact.allowFileAttachments, 0) allowFileAttachments
						,isnull(selectRotativeANI, 0) selectRotativeANI
						,ISNULL(rotativeAlgo, 0) rotativeAlgo
						,isnull(autoStart, 0) autoStart
						,isnull(messagingOrder, 0) messagingOrder
						,ISNULL(cam_tPreview, 0) AS CamTPreview
						,ISNULL(timesPreview, 0) AS TimesPreview
						,isnull(timesDiscard, 0) TimesDiscard
						,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
					FROM ccCamps a1
					INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
					INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
					INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
					LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
					INNER JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
					ORDER BY cam_descripcion

					RETURN (0)

					SET NOCOUNT OFF'
		EXEC(@sql)

		SET @process = 'Adding parameter ZipCodeSchedule to ccsp_GalateaGetOutboundConfiguration. Lines(318 and 400)'
		SET @sql = 'Alter PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT, @campID INT
					AS
					BEGIN
						DECLARE @AllCampaigns TABLE (		cam_id SMALLINT
							,cam_Descripcion VARCHAR(60)
							,cam_tNotas SMALLINT
							,cam_ocupado SMALLINT
							,cam_noInt_ocupado SMALLINT
							,cam_inter_ocupado SMALLINT
							,cam_nocontesto SMALLINT
							,cam_noInt_nocontesto SMALLINT
							,cam_inter_nocontesto SMALLINT
							,cam_fax SMALLINT
							,cam_noInt_fax SMALLINT
							,cam_inter_fax SMALLINT
							,cam_modomanual SMALLINT
							,ANI VARCHAR(15)
							,cam_ShowCalifWnd BIT
							,cam_StartTimerOnHangUp BIT
							,editableCallKey BIT
							,cam_tNoContesta SMALLINT
							,iTipoDial SMALLINT
							,detectAnswerMachine SMALLINT
							,detectVoiceMail SMALLINT
							,compliance SMALLINT
							,cam_inter_graba SMALLINT
							,cam_noint_graba SMALLINT
							,progDial SMALLINT
							,excCallBack SMALLINT
							,dialOrder SMALLINT
							,dialPrefix VARCHAR(10)
							,dialPrefixMan VARCHAR(10)
							,dialPrefixXfe VARCHAR(10)
							,listenManualCall BIT
							,stopRecording BIT
							,abandonCallback BIT
							,frame SMALLINT
							,t_autoCB SMALLINT
							,id_anilist INT
							,tDialonWrapUp SMALLINT
							,viewMode TINYINT
							,queSize SMALLINT
							,DNCScrub INT
							,callerIdDesc VARCHAR(15)
							,timeZoneRule INT
							,callsBySurvey INT
							,ivrScript INT
							,surveyPctg INT
							,call_record SMALLINT
							,startStopRecording BIT
							,leaveRecMessage BIT
							,manualCallOnChat BIT
							,callBackSurveyAgent BIT
							,callBackSurveyClient BIT
							,isRelationSurvey BIT
							,funcEspDtmf INT
							,sipHdrFormat VARCHAR(255)
							,cam_inter_cancelled SMALLINT
							,prefijo VARCHAR(40)
							,enbleprefix BIT
							,exitAssisted BIT
							,previewDiscard BIT
							,CampType INT
							,conexionInfo VARCHAR(50)
							,connUser VARCHAR(15)
							,closeConversationTime SMALLINT
							,answerTimeoutClient INT
							,allowFileAttachments BIT
							,selectRotativeANI int
							,rotativeAlgo TINYINT
							,autoStart BIT
							,messagingOrder BIT
							,CamTPreview SMALLINT
							,TimesPreview TINYINT
							,timesDiscard TINYINT
							,zipCodeSchedule BIT 
							)
						DECLARE @numbers VARCHAR(max)

						SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
						FROM ccWhatsAppNumbers
						WHERE camp_id = 0
							AND STATUS = 1

						INSERT INTO @AllCampaigns
						EXEC ccsp_RIAConfCamp @adminID
							,@campID

						SELECT dialPrefixMan DialPrefixMan
							,dialPrefixXfe DialPrefixXfe
							,listenManualCall ListenManualCall
							,stopRecording StopRecording
							,abandonCallback AbandonCallBack
							,t_autoCB AutoCB
							,id_anilist IdIstANI
							,tDialonWrapUp TDialOnWrapup
							,queSize Quesize
							,DNCScrub
							,callerIdDesc CallerIdDesc
							,timeZoneRule TimeZoneRule
							,callsBySurvey CallsBySurvey
							,ivrScript IvrScript
							,surveyPctg SurveyPctg
							,call_record CallRecord
							,startStopRecording StartStopRecording
							,leaveRecMessage LeaveRecMessage
							,manualCallOnChat ManualCallOnChat
							,callBackSurveyClient CallBackSurveyClient
							,callBackSurveyAgent CallBackSurveyAgent
							,funcEspDtmf FuncEspDtmf
							,sipHdrFormat SipHdrsCfg
							,dialPrefix DialPrefix
							,prefijo Prefix
							,dialOrder DialOrder
							,progDial ProgDial
							,cam_Descripcion CamDescription
							,cam_tNotas CamTnotas
							,cam_ocupado CamBusy
							,cam_noInt_ocupado CamNoIntBusy
							,cam_inter_ocupado CamInterBusy
							,cam_nocontesto CamNoAnswer
							,cam_noInt_nocontesto CamNoIntNoAnswer
							,cam_inter_nocontesto CamInterNoAnswer
							,(cam_inter_cancelled / 60) CamInterCancelled
							,cam_fax CamFax
							,cam_noInt_fax CamNoIntFax
							,cam_inter_fax CamInterFax
							,cam_modomanual CamModoManual
							,ANI
							,cam_StartTimerOnHangUp CamStartTimerOnHangUp
							,editableCallKey EditableCallKey
							,cam_tNoContesta CamTNoAnswer
							,iTipoDial CamIntensiveDialing
							,detectAnswerMachine DetectAnswerMachine
							,detectVoiceMail DetectVoiceMail
							,compliance Compliance
							,cam_inter_graba CamInterRecord
							,cam_noint_graba CamNoIntRecord
							,excCallBack ExcCallBack
							,cam_ShowCalifWnd CamShowCalifWnd
							,frame Frame
							,exitAssisted ExitAssistedDialMode
							,previewDiscard PreviewDiscard
							,CampType
							,conexionInfo ConexionInfo
							,connUser ConnUser
							,closeConversationTime CloseConversationTime
							,answerTimeoutClient MUTimeOutClient
							,allowFileAttachments AllowFileAttachments
							,CamTPreview
							,CAST(TimesPreview AS SMALLINT) TimesPreview
							,@numbers AS FreeNumbers
							,selectRotativeANI SelectRotativeANIManualCall
							,rotativeAlgo RotativeAlgo
							,autoStart AutoStart
							,messagingOrder MessagingOrder
							,timesDiscard TimesDiscard
							,zipCodeSchedule ZipCodeSchedule
						FROM @AllCampaigns
						WHERE cam_id = @campID
					END'
		EXEC(@sql)
		-------------------------------------------- END IVAN OUTBOUND HISTORICAL CHAT ------------------------------
		
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
