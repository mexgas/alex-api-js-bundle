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
SET @versionfix = 10
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

	SET @process = 'DEV3-228 Add recordHold to ccCamps'
	SET @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''recordHold'' AND OBJECT_ID = OBJECT_ID(''ccCamps''))
		begin
			alter table ccCamps add recordHold bit null
		end'
	EXEC(@sql)

	SET @process = 'DEV3-228 Add recordHold to ccInbound'
	SET @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''recordHold'' AND OBJECT_ID = OBJECT_ID(''ccInbound''))
		begin
			alter table ccInbound add recordHold bit null
		end'
	exec (@sql)
	
	SET @process = 'DEV3-228 Alter procedure ccsp_RIAConfCamp'
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
	,ISNULL(recordHold, 0) recordHold
FROM ccCamps a1
INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
ORDER BY cam_descripcion

RETURN (0)

SET NOCOUNT OFF'
	exec (@sql)
	

	SET @process = 'DEV3-228 Alter procedure ccsp_GalateaGetOutboundConfiguration'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT, @campID INT
AS
BEGIN
DECLARE @AllCampaigns TABLE (		
	cam_id SMALLINT
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
	,recordHold bit
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
	,recordHold RecordHold
FROM @AllCampaigns
WHERE cam_id = @campID
END'
	exec (@sql)
		
		
	SET @process = 'DEV3-228 Alter procedure ccsp_RIAUpdateCamConfig'
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
 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 3 THEN @progDiaL ELSE 1 END),
 selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
 messagingOrder = isnull(@messagingorder, messagingOrder),
 autoStart = isnull(@autoStart,autoStart),
 recordHold = isnull(@recordHold, recordHold)

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
	
	
	
	SET @process = 'DEV3-228 Alter procedure ccsp_GalateaGetInboundConfiguration'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
@command int,
@inboundId int
AS
BEGIN

SET NOCOUNT ON;

if @command=0
begin
select descripcion from ccInbound where Inbound_id = @inboundId
end
if @command=1 -- Voice campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.tMaxWaitCall,
	A.nMaxQue,
	A.tel_maxwait,
	A.tel_maxqueue,
	A.tel_outservice,
	A.tel_noct,
	A.ShowCalifWnd,
	A.editableCallKey [EditableCallKey],
	A.queuePosition [QueuePosition],
	A.tMaxQueueCallBack,
	A.stopRecording [StopRecording],
	A.dialPrefixOverflow [DialPrefixOverflow],
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
	isnull(A.recordHold, 0) [RecordHold]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
end
if @command=2 -- WhatsApp campaign
begin
	declare @numbers varchar(max)
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

	select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
	ISNULL(c.conexionInfo,'''') [Number],
	ISNULL(@numbers,'''') [FreeNumbersStr],
	ISNULL(c.closeConversationTime, 0) [MaxAnswerTime],
	ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
	ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
	i.tNotas [tNotas],
	i.ExitWrapUpDisposition,
	i.ShowCalifWnd
	from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
	left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
	where i.Inbound_id=@inboundId
end
if @command=3 -- Email campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.ShowCalifWnd,
	C.conexionInfo [ConnInfo],
	C.connUser  [ConnUserName],
	C.ConnPass [ConnPwd],
	C.isActive [IsActive],
	C.timeAlertMessage,
	C.closeConversationTime [CloseConversationTime],
	C.answerTimeOut [AnswerTimeOut],
	C.name [SenderName]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
	where A.Inbound_id=@inboundId
end
RETURN(0)

SET NOCOUNT OFF;    
END
	'
	EXEC(@sql)
	

	SET @process = 'DEV3-228 Alter procedure ccsp_GalateaUpdateVoiceConfiguration'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
	@inboundId				smallint,
	@frame					smallint	= null,
	@description			varchar(50) = null,
	@mediaType				tinyint		= null,
	@status					smallint	= null,
	@tNotas					int			= null,
	@tMaxWaitCall			smallint	= null,
	@nMaxQue				smallint	= null,
	@tel_maxwait			varchar(15) = null,
	@tel_maxqueue			varchar(15) = null,
	@tel_outservice			varchar(15) = null,
	@tel_noct				varchar(15) = null,
	@showCalifWnd			bit			= null,
	@editableCallKey		bit			= null,
	@queuePosition			bit			= null,
	@tMaxQueueCallBack		smallint	= null,
	@stopRecording			bit			= null,
	@dialPrefixOverflow		varchar(10) = null,
	@callerIdDesc			varchar(15) = null,
	@startStopRecording		bit			= null,
	@callBackSurveyAgent	bit			= null,
	@callBackSurveyClient	bit			= null,
	@editableDtmf			bit			= null,
	@addDataCallBackReminder bit		= null,
	@recordHold				bit			= null
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @graph_id smallint

	UPDATE ccInbound SET
		descripcion = ISNULL(@description, descripcion),
		chat = ISNULL(@mediaType, chat),
		Status = ISNULL(@status, Status),
		tNotas = ISNULL(@tNotas, tNotas),
		tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall),
		nMaxQue = ISNULL(@nMaxQue, nMaxQue),
		tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait),
		tel_maxqueue = ISNULL(@tel_maxqueue, tel_maxqueue),
		tel_outservice = ISNULL(@tel_outservice, tel_outservice),
		tel_noct = ISNULL(@tel_noct, tel_noct),
		bnocturno = CASE WHEN ISNULL(@tel_noct, 0) = ''0'' OR @tel_noct = '''' THEN ''0'' ELSE ''1'' END,
		editableCallKey = ISNULL(@editableCallKey, editableCallKey),
		queuePosition = ISNULL(@queuePosition, queuePosition),
		tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack),
		stopRecording = ISNULL(@stopRecording, stopRecording),
		dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow),
		callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc),
		startStopRecording = ISNULL(@startStopRecording, startStopRecording),
		callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent),
		callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient),
		editableDtmf = ISNULL(@editableDtmf, editableDtmf),
		addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
		recordHold = ISNULL(@recordHold, recordHold)
	WHERE Inbound_id = @inboundId

	IF @frame IS NOT NULL
	BEGIN
		SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
		UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId
	END

	IF @showCalifWnd = 1
    BEGIN
		IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
			UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
			SELECT 1 [Result]
			RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
	 BEGIN
		UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
	 END

	SELECT 1 [Result]
	RETURN(0);

	SET NOCOUNT OFF;
END'
    EXEC(@sql)
	
	SET @process = 'DEV3-228 Alter procedure ccsp_RIAUpdateEspecConfig'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] 
@inbound_id              SMALLINT, 
@descripcion             VARCHAR(50)  = NULL, 
@Status                  TINYINT      = NULL, 
@tNotas                  INT          = NULL, 
@tMaxWaitCall            INT          = NULL, 
@nMaxQue                 INT          = NULL, 
@tel_maxwait             VARCHAR(15)  = NULL, 
@tel_MaxQueue            VARCHAR(15)  = NULL, 
@tel_outservice          VARCHAR(15)  = NULL, 
@tel_noct                VARCHAR(15)  = NULL, 
@ShowCalifWnd            BIT          = NULL, 
@StartTimerOnHangUp      BIT          = NULL, 
@editableCallKey         BIT          = NULL, 
@queuePosition           BIT          = NULL, 
@tMaxQueueCallBack       SMALLINT     = NULL, 
@stopRecording           BIT          = NULL, 
@dialPrefixOverflow      VARCHAR(10)  = NULL, 
@OpriorityT              SMALLINT     = NULL, 
@callerIdDesc            VARCHAR(15)  = NULL, 
@chat                    TINYINT      = NULL, 
@inactiveChatTime        SMALLINT     = NULL, 
@maxChats                TINYINT      = NULL, 
@chatDomain              VARCHAR(MAX) = NULL, 
@chatQueue               SMALLINT     = NULL, 
@chatTime                SMALLINT     = NULL, 
@dRestrictPlay           BIT          = NULL, 
@callBackSurveyAgent     BIT          = NULL, 
@callBackSurveyClient    BIT          = NULL, 
@agts_notavailable       VARCHAR(15)  = NULL, 
@editableDtmf            BIT          = NULL, 
@prefijo                 VARCHAR(MAX) = NULL, 
@addDataCallBackReminder BIT          = NULL,
@recordHold				 BIT	  	  = NULL
AS
SET NOCOUNT ON;
UPDATE ccInbound
SET 
   descripcion = ISNULL(@descripcion, descripcion), 
   STATUS = ISNULL(@status, STATUS), 
   tNotas = ISNULL(@tNotas, tNotas), 
   tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall), 
   nMaxQue = ISNULL(@nMaxQue, nMaxQue), 
   tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait), 
   tel_MaxQueue = ISNULL(@tel_MaxQueue, tel_MaxQueue), 
   tel_outservice = ISNULL(@tel_outservice, tel_outservice), 
   tel_noct = ISNULL(@tel_noct, tel_noct), 
   bnocturno = CASE
				   WHEN ISNULL(@tel_noct, 0) = ''0''
						OR @tel_noct = ''''
				   THEN ''0''
				   ELSE ''1''
			   END, 
   StartTimerOnHangUp = ISNULL(@StartTimerOnHangUp, StartTimerOnHangUp), 
   editableCallKey = ISNULL(@editableCallKey, editableCallKey), 
   queuePosition = ISNULL(@queuePosition, queuePosition), 
   tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack), 
   stopRecording = ISNULL(@stopRecording, stopRecording), 
   dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow), 
   OpriorityT = ISNULL(@OpriorityT, OpriorityT), 
   callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc), 
   chat = ISNULL(@chat, chat), 
   inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime), 
   maxChats = ISNULL(@maxChats, maxChats), 
   chatQueueOverflow = ISNULL(@chatQueue, ISNULL(chatQueueOverflow, 15)), 
   chatTimeOverflow = ISNULL(@chatTime, ISNULL(chatTimeOverflow, 300)), 
   startStopRecording = ISNULL(@dRestrictPlay, startStopRecording), 
   callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent), 
   callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient), 
   agts_notavailable = ISNULL(@agts_notavailable, agts_notavailable), 
   editableDtmf = ISNULL(@editableDtmf, editableDtmf), 
   prefijo = ISNULL(@prefijo, prefijo), 
   addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
   recordHold = ISNULL(@recordHold, recordHold)
WHERE inbound_id = @inbound_id;
IF @chat = 5 
BEGIN
	IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
	BEGIN
		INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));
	END
END;

IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
BEGIN
   UPDATE contactMeanIn set name = @descripcion where inboundId = @inbound_id;
END
IF NOT EXISTS
(
 SELECT inbound_id
 FROM ccinbound
 WHERE inbound_id <> @inbound_id
	   AND chatDomain = @chatDomain
	   AND chatDomain <> ''''
)
 BEGIN
	 IF @chatDomain IS NOT NULL
		 BEGIN
			 UPDATE ccinbound
			   SET 
				   chatDomain = @chatDomain
			 WHERE inbound_id = @inbound_id;
	 END;
END;
 ELSE
 BEGIN
	 UPDATE ccinbound
	   SET 
		   chatDomain = ''''
	 WHERE inbound_id = @inbound_id;
	 RAISERROR(''Domain already in another ACD Group'', 15, 4);
END;
IF @ShowCalifWnd = 1
 BEGIN
	 IF EXISTS
	 (
		 SELECT cam_id
		 FROM ccCalifCamp
		 WHERE cam_id = @inbound_id
			   AND tipo = 0
	 )
		 BEGIN
			 UPDATE ccInbound
			   SET 
				   ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
			 WHERE inbound_id = @inbound_id;
			 SELECT 1;
			 RETURN(0);
	 END;
	 SELECT 0;
	 RETURN(0);
END;
 ELSE
 UPDATE ccInbound
   SET 
	   ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
 WHERE inbound_id = @inbound_id;
 

SELECT 2;
RETURN(0);
SET NOCOUNT OFF;'
    EXEC(@sql)

	SET @process = 'DEV3-228 Alter procedure ccsp_DLRGetDialInfo'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
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
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)
declare @recordHold bit

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104
select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''''
	select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
	select @prefix = valor from ccsettings nolock where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0)
from ccCamps C (nolock) where C.cam_id=@cam_id

if @surveycamid > 0
	select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max)
set @prefixCalKey=''''
select @mainPrefix = valor from ccSettings where setting_id=202
SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
	@phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
FROM ccoCallsOutSource NOLOCK WHERE callout_id=@callout_id 

if @iPortNumber >= 0 
begin
	declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

	insert @Anis
	exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

	SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

	SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
	, ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
	, C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
	, @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
	, case when anis.p1 <> '''' then anis.p1 else @ani end ani
	, case when anis.p2 <> '''' then anis.p2 else @ani end ani2
	, case when anis.p3 <> '''' then anis.p3 else @ani end ani3
	, case when anis.p4 <> '''' then anis.p4 else @ani end ani4
	, case when anis.p5 <> '''' then anis.p5 else @ani end ani5
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
	,@PrefixRec as Prefijo,
	dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
	dbo.GetCarrierByTel(cal_telefono2) carrier2, 
	dbo.GetCarrierByTel(cal_telefono3) carrier3, 
	dbo.GetCarrierByTel(cal_telefono4) carrier4, 
	dbo.GetCarrierByTel(cal_telefono5) carrier5,
	@recordHold as recordHold
	FROM ccoCallsOutSource C with(nolock)
	left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
	left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
	left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
	WHERE C.callout_id = @callout_id
	return
end 
set nocount off'
	EXEC(@sql)

	
	SET @process = 'DEV3-228 Alter procedure ccsp_DLRgetDialPrefix'
	set @sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = '''',
@callout_id int = 0
as
declare @prefix as varchar(15), @sipheader varchar(500)
declare @ani as varchar(32)
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
declare @ivr_script smallint, @surveycamid int
declare @call_record bit, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
declare @PrefixRec varchar(40)
declare @carrier varchar(255)
declare @recordHold bit

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id
select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campaña,
if @prefix =''''
	select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

-- Prefijo general
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
	select @prefix = valor from ccsettings with(nolock) where setting_id =101

-- Ani
set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

--AnswerMachine Message Files
DECLARE @MsgFiles VARCHAR(8000) 
SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

select @surveycamid = 0, @ivr_script = 0

select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
,@call_record = dbo.EnableCallRecord(@call_record_cam,@pais,@phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
from ccCamps where cam_id = @cam_id

SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

if @surveycamid > 0
	select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


if @ani = '''' begin 
set @ani = @aniglobal 
end 

 select @PrefixRec=ISNULL(prefijo,'''') from ccCamps where cam_id = @cam_id

 set @carrier = ''''
 select @carrier = dbo.GetCarrierByTel(@phone)

select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold'
	EXEC(@sql)


	SET @process = 'DEV3-228 drop procedure getPrefixByAcdId'
    set @Sql= 'if exists (select * from sys.procedures where name = N''getPrefixByAcdId'')
    begin
        DROP PROCEDURE getPrefixByAcdId;
    end'
	EXEC(@sql)


	set @process = 'DEV3-228 Create procedure getPrefixByAcdId'
    set @Sql= 'CREATE procedure getPrefixByAcdId 
@inboundId int 
as
select isnull(prefijo,''''), ISNULL(recordHold,0) recordHold from ccInbound where Inbound_id = @inboundId'
    EXEC(@Sql)




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
