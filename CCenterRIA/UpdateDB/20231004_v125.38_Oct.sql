/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.37

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
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
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

	---------------------------------------BEGIN Jonathan Ramírez (KR095000 Setting deshabilitar campos editables en agent)---------------------------------------------------------

	SET @process = '1 - JR - KR095000 - Add column EditableContactData to table ccCampsExtend'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = ''EditableContactData'' AND OBJECT_ID = OBJECT_ID(''ccCampsExtend''))
		BEGIN
			ALTER TABLE ccCampsExtend ADD EditableContactData bit NOT NULL DEFAULT 1;
		END
	'
	EXEC(@sql);

	SET @process = '2 - JR - KR095000 - Add column EditableContactData to table ccInbound'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = ''EditableContactData'' AND OBJECT_ID = OBJECT_ID(''ccInbound''))
		BEGIN
			ALTER TABLE ccInbound ADD EditableContactData bit NOT NULL DEFAULT 1;
		END
	'
	EXEC(@sql);
	
	SET @process = '3 - JR - KR095000 - Edit SP ccsp_RIAUpdateCamConfigExtend, Add new paramtater @editableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
					@cam_id smallint,
					@zipCodeSchedule BIT = NULL,
					@userId SMALLINT = NULL,
					@idArea SMALLINT = NULL, 
					@isCreating SMALLINT = NULL,
					@simultaneousRecs SMALLINT = NULL,
					@module INT = -1,
					@recordCalls tinyint = 1,
					@editableContactData BIT = 1
				AS
				BEGIN
					SET NOCOUNT ON;
					DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
					DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;
					if exists(select * from ccCampsExtend where cam_id=@cam_id) begin

						EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCampsExtend'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

						IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

						Create table #ccCampsExtendTable 
						(
							columnInfo VARCHAR(255),
							dataInfo VARCHAR(255),
							identifierInfo VARCHAR(255)
						)

						DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
						DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
																					CASE 
																						WHEN @Camptype = 6  THEN 44
																						WHEN @Camptype = 5  THEN 46
																						WHEN @Camptype = 4  THEN 48
																						WHEN @Camptype = 7  THEN 50
																						ELSE 42 END
																				ELSE 
																					CASE 
																						WHEN @Camptype = 6  THEN 55
																						WHEN @Camptype = 5  THEN 56
																						WHEN @Camptype = 4  THEN 57
																						WHEN @Camptype = 7  THEN 58
																						ELSE 54 END
																				END;

						UPDATE ccCampsExtend SET
							zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule),
							simultaneousRecs = isnull(@simultaneousRecs,simultaneousRecs),
							RecordCalls = ISNULL(@recordCalls, RecordCalls),
							EditableContactData = isnull(@editableContactData,EditableContactData)
						Where cam_id = @cam_id  

						IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsExtendTable'';

						IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

						INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT 
							(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
							getDate(), 
							(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
							@operation, 
							@module, 
							CCCE.identifierInfo,
							CASE WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
								CASE 
									WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
										CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
									WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
										CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
											WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
											WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
											ELSE ''COMMON_DISABLED'' END
									ELSE CCCE.dataInfo END
							ELSE '''' END,
							(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
						FROM #ccCampsExtendTable AS CCCE where CCCE.identifierInfo != @excludeIdentifier;

						EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
						IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

					end
					else begin
						INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule,SimultaneousRecs, RecordCalls, EditableContactData) values (@cam_id,@zipCodeSchedule,@simultaneousRecs, @recordCalls, @editableContactData)
					end

					update ccCamps set call_record = @recordCalls where cam_id = @cam_id

					set nocount off
				END
	'
	EXEC(@sql);

	SET @process = '4 - JR - KR095000 - Add new Record to ccGalateaIdentifiers, EDIT_CALL_DATASET'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''EDIT_CALL_DATASET'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''EDIT_CALL_DATASET'', ''Editar datos del contacto'', ''Edit contact’s data'', ''Editar dados do contato'');
		END
	'
	EXEC(@sql);

	SET @process = '5 - JR - KR095000 - Insert new records to relationTableColumnIdentifiers'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''EDIT_CALL_DATASET'' AND tableName = ''ccCampsExtend'' AND colunName = ''EditableContactData'')
		BEGIN 
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''EDIT_CALL_DATASET'', ''ccCampsExtend'', ''EditableContactData'')
		END

	IF NOT EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''EDIT_CALL_DATASET'' AND tableName = ''ccInbound'' AND colunName = ''EditableContactData'')
		BEGIN 
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''EDIT_CALL_DATASET'', ''ccInbound'', ''EditableContactData'')
		END
	'
	EXEC(@sql);

	SET @process = '6 - JR - KR095000 - UPDATE SP ccsp_GalateaGetOutboundConfiguration, Add property EditableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
,@campID INT
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
,closeConversationTime INT
,answerTimeoutClient INT
,allowFileAttachments BIT
,selectRotativeANI INT
,rotativeAlgo TINYINT
,autoStart BIT
,messagingOrder BIT
,CamTPreview SMALLINT
,TimesPreview TINYINT
,timesDiscard TINYINT
,recordHold BIT
,zipCodeSchedule BIT
,RecordCalls tinyint
,simultaneousRecs smallint
	,EditableContactData bit
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
,zipCodeSchedule ZipCodeSchedule
,RecordCalls RecordCalls
,simultaneousRecs SimultaneousRecs
,EditableContactData EditableContactData
FROM @AllCampaigns
WHERE cam_id = @campID
END
	'
	EXEC(@sql);

	SET @process = '7 - JR - KR095000 - UPDATE SP ccsp_RIAConfCamp, Add property EditableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
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
		,isnull(sipHdrFormat, '''') sipHdrFormat
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
		,isnull(contact.conexionInfo, '''') conexionInfo
		,isnull(contact.connUser, '''') connUser
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
		,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
		,isnull(campsExtention.RecordCalls, 1) RecordCalls
		,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
		,isnull(campsExtention.EditableContactData, 0) EditableContactData
	FROM ccCamps a1
	INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
	INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
	LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
	LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
	ORDER BY cam_descripcion

	RETURN (0)

	SET NOCOUNT OFF
	'
	EXEC(@sql);

	SET @process = '8 - JR - KR095000 - UPDATE SP ccsp_GalateaGetInboundConfiguration, Add property EditableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
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
					isnull(A.recordHold, 0) [RecordHold],
					isnull(AE.RecordCalls, 1) [RecordCalls],
					isnull(A.EditableContactData, 0) [EditableContactData]
					from ccInbound A
					left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
					left join ccInboundExtend AE on AE.Inbound_id = @inboundId
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
					CAST(ISNULL(c.closeConversationTime, 0) AS INT) [MaxAnswerTime],
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
				if @command=4 -- Chat campaign
				begin
					select 
					i.Inbound_id [InboundId],
					i.descripcion [Description],
					i.chat [MediaType],
					i.Status,
					isnull(ig.graphic_id,1) [Frame],
					i.tNotas,
					i.ShowCalifWnd,
					i.inactiveChatTime [InactiveChatTime],
					i.chatDomain [ChatDomain],
					i.chatTimeOverflow [ChatTimeOverflow],
					i.chatQueueOverflow [ChatQueueOverflow]
					from ccInbound i
					left join ccRIAInboundGraph ig on ig.Inbound_id=i.Inbound_id
					where i.Inbound_id =@inboundId
				end

				RETURN(0)

				SET NOCOUNT OFF;    
				END
	'
	EXEC(@sql);

	SET @process = '9 - JR - KR095000 - UPDATE SP ccsp_RIAUpdateEspecConfig, Add property EditableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] 
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
    @recordHold              BIT          = NULL,
    @editableContactData     BIT          = NULL,
    @userId                  SMALLINT     = NULL, 
    @idArea                  SMALLINT     = NULL, 
    @isCreating              BIT          = NULL
AS
SET NOCOUNT ON;

declare @domainInUse bit = 0
declare @returnValue int = 2

EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

UPDATE ccInbound
SET 
    descripcion = ISNULL(@descripcion, descripcion), 
    STATUS = ISNULL(@status, STATUS), 
    tNotas = ISNULL(CASE WHEN @chat <> 5 THEN @tNotas ELSE 10 END, tNotas), 
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
    recordHold = ISNULL(@recordHold, recordHold),
    EditableContactData = ISNULL(@editableContactData, EditableContactData)
WHERE inbound_id = @inbound_id;


IF NOT EXISTS (SELECT inbound_id FROM ccinbound WHERE inbound_id <> @inbound_id AND chatDomain = @chatDomain AND chatDomain <> '''')
BEGIN
    IF @chatDomain IS NOT NULL
    BEGIN
        UPDATE ccinbound SET chatDomain = @chatDomain WHERE inbound_id = @inbound_id
    END
END
ELSE
BEGIN
    UPDATE ccinbound SET chatDomain = '''' WHERE inbound_id = @inbound_id
    set @domainInUse = 1
END


IF @ShowCalifWnd = 1
BEGIN
    IF EXISTS (SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inbound_id AND tipo = 0)
    BEGIN
        UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;
        SET @returnValue = 1
    END
    ELSE
    BEGIN
        SET @returnValue = 0
    END
END;
ELSE
    UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;



IF(@chat <> 5) 
BEGIN
    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
    
    IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

    DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE
            WHEN @chat = 1 THEN 63
            ELSE 60 END,
        3, 
        CCIT.identifierInfo,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                    CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                        THEN ''COMMON_VOICE_MAIL'' 
                        ELSE 
                            CASE WHEN CCIT.dataInfo IS NOT NULL THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
                        END
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'', ''EDIT_CALL_DATASET'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CONDUCT_SURVEY'' THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
END

IF @chat = 5 
BEGIN
    IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
    BEGIN
        INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            40, 
            3,'''','''', 
            @descripcion);
    END
END;

if (@domainInUse = 1)
BEGIN
    RAISERROR(''Domain already in another ACD Group'', 15, 4)
END

if(@returnValue <> 2)
    SELECT @returnValue
ELSE
    SELECT 2
RETURN(0)

SET NOCOUNT OFF
	'
	EXEC(@sql);

	SET @process = '10 - JR - KR095000 - UPDATE SP ccsp_GalateaUpdateVoiceConfiguration, Add property EditableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
    @inboundId              smallint,
    @frame                  smallint    = null,
    @description            varchar(50) = null,
    @mediaType              tinyint     = null,
    @status                 smallint    = null,
    @tNotas                 int         = null,
    @tMaxWaitCall           smallint    = null,
    @nMaxQue                smallint    = null,
    @tel_maxwait            varchar(15) = null,
    @tel_maxqueue           varchar(15) = null,
    @tel_outservice         varchar(15) = null,
    @tel_noct               varchar(15) = null,
    @showCalifWnd           bit         = null,
    @editableCallKey        bit         = null,
    @queuePosition          bit         = null,
    @tMaxQueueCallBack      smallint    = null,
    @stopRecording          bit         = null,
    @dialPrefixOverflow     varchar(10) = null,
    @callerIdDesc           varchar(15) = null,
    @startStopRecording     bit         = null,
    @callBackSurveyAgent    bit         = null,
    @callBackSurveyClient   bit         = null,
    @editableDtmf           bit         = null,
    @addDataCallBackReminder bit        = null,
    @recordHold             bit         = null,
    @editableContactData    bit         = null,
    @userId                 smallint    = null,
    @module                 int         = -1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @graph_id smallint


    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
    
    DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);

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
        recordHold = ISNULL(@recordHold, recordHold),
        EditableContactData = ISNULL(@editableContactData, EditableContactData)
    WHERE Inbound_id = @inboundId

    IF(@module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable'';    

    DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        52, 
        @module,
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
            CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCIT.dataInfo IS NOT NULL AND CCIT.dataInfo <> '''' THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'', ''EDIT_CALL_DATASET'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END,
        CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    IF @frame IS NOT NULL
    BEGIN
        SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
        UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            CASE WHEN @mediaType = 5 THEN 40 ELSE 52 END, 
            3,
            '''',
            ''IN_CALL_EDIT_ICON'', 
            (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)

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
END

	'
	EXEC(@sql);

	SET @process = '11 - JR - KR095000 - UPDATE SP ccsp_LoadGraphics, Add property EditableContactData'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint,
@phone varchar(50)=null
AS
BEGIN
        
    SET NOCOUNT ON  
    DECLARE @realValue int      
    exec @realValue= ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType,@phone=@phone
    
    if (@callType=1)
    begin
        DECLARE @canReprogram bit  
        create table #canReprogram (canReprogram bit)
        insert into #canReprogram
        exec ccsp_AgentGetCampReprogramData @Id, @callType
        select @canReprogram = canReprogram from #canReprogram
        drop table #canReprogram

        select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage , a2.EditableContactData,
        case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
        isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
        a2.ShowCalifWnd as ShowDisposition,
        isnull(a2.startStopRecording,0) as StartStopRecording,
        @realValue as IsStartStopRecording,
        isnull(a2.editableDtmf, 0) as isEditDtmf,
        @canReprogram  CanReprogram
        from ccRIAInboundGraph a1 
        inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
         inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
         left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id        
     end    
     else
     begin
        select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
        case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
        case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
        a2.cam_ShowCalifWnd as ShowDisposition,
        a2.callBackSurveyAgent,a2.callBackSurveyClient,
        isnull(a2.startStopRecording,0) as StartStopRecording,
        @realValue as IsStartStopRecording,
        a4.EditableContactData
        from ccRIACampsGraph a1 
        inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
        inner join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)
        left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
        from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
        where M.cam_id = @Id and type = 8) b 
        on (a2.cam_id = b.cam_id) 
        where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
     end    
END
	'
	EXEC(@sql);

	---------------------------------------END Jonathan Ramírez (KR095000 Setting deshabilitar campos editables en agent)------------------------------------------------------------
	
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