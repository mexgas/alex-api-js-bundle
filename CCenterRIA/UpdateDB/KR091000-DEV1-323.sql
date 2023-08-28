/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCenterRia
Required version: 125.33

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
SET @versionfix = 34
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

---------------------------------------BEGIN KR091000 Register_setting_in_BD_and_update_path Ivan Martin---------------------------------------------------------

	SET @process = 'Add column RecordCalls to ccCampsExtend'
	SET @sql = 'IF NOT EXISTS( SELECT * FROM sys.columns WHERE name = N''RecordCalls'' AND Object_ID = Object_ID(N''ccCampsExtend''))
				BEGIN
					ALTER TABLE ccCampsExtend ADD RecordCalls TINYINT NOT NULL DEFAULT(1);
				END'
	EXEC(@sql)
---------------------------------------END KR091000 Register_setting_in_BD_and_update_path Ivan Martin---------------------------------------------------------

	SET @process = 'Create table ccInboundExtend'
	SET @sql = 'if not exists (select * from sys.tables where name = N''ccInboundExtend'') begin
					CREATE TABLE [dbo].[ccInboundExtend] (
					Inbound_id INT NOT NULL PRIMARY key,
					RecordCalls TINYINT NULL,
				)
				end'
	EXEC(@sql)

	---------------------------------------BEGIN KR091000 Uriel Cabrera - Ivan Martin Identifiers and Relations ---------------------------------------------------------

	SET @process = 'Insert new labels into ccGalateaIdentifiers'
	SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_INTERNATIONAL_RECORD_CALLS'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''COMMON_INTERNATIONAL_RECORD_CALLS'',''Grabar llamadas'',''Record calls'',''Gravar chamadas'');
				END
				IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''IN_COMMON_INTERNATIONAL_RECORD_CALLS'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''IN_COMMON_INTERNATIONAL_RECORD_CALLS'',''Grabar llamadas'',''Record calls'',''Gravar chamadas'');
				END
				IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_USA_RECORD_CALLS'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''COMMON_USA_RECORD_CALLS'',''Grabar llamadas por clave LADA'',''Record calls by area code'',''Gravar chamadas por código de área'');
				END
				IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_USA_RECORD_CALLS_MODE_ALL'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''COMMON_USA_RECORD_CALLS_MODE_ALL'',''Todas las claves (automático)'',''All area codes (automatic)'',''Todos os códigos (automático)'');
				END
				IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_USA_RECORD_CALLS_MODE_AUTH'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''COMMON_USA_RECORD_CALLS_MODE_AUTH'',''Solo claves autorizadas (automático)'',''Allowed area codes only (automatic)'',''Somente códigos permitidos (automático)'');
				END
				IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_USA_RECORD_CALLS__MODE_NOAUTH'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''COMMON_USA_RECORD_CALLS_MODE_NOAUTH'',''Claves no autorizadas (manual)'',''Not allowed area codes (manual)'',''Códigos não permitidos (manual)'');
				END
				IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''IN_COMMON_USA_RECORD_CALLS'')
				BEGIN
					INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
					VALUES (''IN_COMMON_USA_RECORD_CALLS'',''Grabar llamadas por clave LADA'',''Record calls by area code'',''Gravar chamadas por código de área'');
				END'
	EXEC(@sql)

	SET @process = 'Insert relation between new column and identifiers'
	SET @sql = 'IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_INTERNATIONAL_RECORD_CALLS'')
				BEGIN
					INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
					VALUES (''COMMON_INTERNATIONAL_RECORD_CALLS'',''ccCampsExtend'',''RecordCalls'');
				END
				IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''IN_COMMON_INTERNATIONAL_RECORD_CALLS'')
				BEGIN
					INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
					VALUES (''IN_COMMON_INTERNATIONAL_RECORD_CALLS'',''ccInboundExtend'',''RecordCalls'');
				END
				IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_USA_RECORD_CALLS'')
				BEGIN
					INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
					VALUES (''COMMON_USA_RECORD_CALLS'',''ccCampsExtend'',''RecordCalls'');
				END
				IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''IN_COMMON_USA_RECORD_CALLS'')
				BEGIN
					INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
					VALUES (''IN_COMMON_USA_RECORD_CALLS'',''ccInboundExtend'',''RecordCalls'');
				END'
	EXEC(@sql)

	---------------------------------------END KR091000 Uriel Cabrera - Ivan Martin Identifiers and Relations ---------------------------------------------------------
	---------------------------------------BEGIN KR091000 Uriel Cabrera Setting configurations and utilities ---------------------------------------------------------
	SET @process = 'Drop update acd procedure'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateACDConfigExtend'') begin
					Drop PROCEDURE [dbo].[ccsp_RIAUpdateACDConfigExtend]
				end'
	EXEC(@sql)

	SET @process = 'Create procedure RIAUpdateACDConfigExtend'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateACDConfigExtend] @inbound_id smallint,
					@recordCalls tinyint = NULL,
					@userId smallint = NULL,
					@idArea smallint = NULL,
					@isCreating smallint = NULL,
					@module int = -1
					AS
					BEGIN
					  SET NOCOUNT ON;
					  DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
					  DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''IN_COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''IN_COMMON_USA_RECORD_CALLS'' END;
					  EXEC InsertLogAdminGalatea @action = 1,
												 @tableName = ''ccInboundExtend'',
												 @columnNameId = ''inbound_id'',
												 @valueId = @inbound_id,
												 @userId = @userid
					  CREATE TABLE #ccInboundExtendTable (
						columnInfo varchar(255),
						dataInfo varchar(255),
						identifierInfo varchar(255)
					  )

					  DECLARE @operation smallint = CASE
						WHEN @isCreating = 1 THEN 60
						ELSE 52
					  END;

					  IF EXISTS (SELECT * FROM ccInboundExtend WHERE Inbound_id = @inbound_id)
					  BEGIN
						UPDATE ccInboundExtend
						SET RecordCalls = ISNULL(@recordCalls, RecordCalls)
						WHERE Inbound_id = @inbound_id
					  END
					  ELSE
					  BEGIN
						INSERT INTO ccInboundExtend (Inbound_id, RecordCalls)
						  VALUES (@inbound_id, @recordCalls)
					  END
					  IF (@isCreating > 0
						  AND @module > -1) BEGIN
						  EXEC InsertLogAdminGalatea @action = 2,
													 @tableName = ''ccInboundExtend'',
													 @columnNameId = ''Inbound_id'',
													 @valueId = @inbound_id,
													 @userId = @userid,
													 @tableTemp = ''#ccInboundExtendTable''
						END
						ELSE BEGIN
						IF (@recordCalls != 1)
						  EXEC InsertLogAdminGalatea @action = 2,
													 @tableName = ''ccInboundExtend'',
													 @columnNameId = ''Inbound_id'',
													 @valueId = @inbound_id,
													 @userId = @userid,
													 @tableTemp = ''#ccInboundExtendTable'';
						END
					  INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
						SELECT (SELECT
								 [AreaName]
							   FROM ccRIACat_Areas
							   WHERE IDArea = @idArea),
							   GETDATE(),
							   (SELECT
								 [Login]
							   FROM ccUsers
							   WHERE User_id = @userid),
							   @operation,
							   CASE WHEN @isCreating = 1 THEN 3 ELSE @module END,
							   CCIE.identifierInfo,
							   CASE
								 WHEN CCIE.identifierInfo IS NOT NULL AND
								   CCIE.identifierInfo <> '''' THEN CASE
									 WHEN CCIE.identifierInfo IN (''IN_COMMON_INTERNATIONAL_RECORD_CALLS'') THEN CASE
										 WHEN CCIE.dataInfo = 1 THEN ''COMMON_ENABLED''
										 ELSE ''COMMON_DISABLED''
									   END
									WHEN CCIE.identifierInfo IN (''IN_COMMON_USA_RECORD_CALLS'') THEN
												CASE WHEN CCIE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
													WHEN CCIE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
													WHEN CCIE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
													ELSE ''COMMON_DISABLED'' END
									 ELSE CCIE.dataInfo
								   END
								 ELSE ''''
							   END,
							   (SELECT
								 [descripcion]
							   FROM ccInbound
							   WHERE inbound_id = @inbound_id)
						FROM #ccInboundExtendTable AS CCIE where CCIE.identifierInfo != @excludeIdentifier;
					  EXEC InsertLogAdminGalatea @action = 3,
												 @tableName = ''ccInboundExtend'',
												 @columnNameId = ''Inbound_id'',
												 @valueId = @inbound_id,
												 @userId = @userid;
					  IF OBJECT_ID(N''tempdb..#ccInboundExtendTable'') IS NOT NULL
						DROP TABLE #ccInboundExtendTable
					  SET NOCOUNT OFF;
					END'
	EXEC(@sql)

	SET @process = 'Update ccsp_GalateaGetInboundConfiguration'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
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
					isnull(AE.RecordCalls, 1) [RecordCalls]
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
				END'
	EXEC(@sql)

	SET @process = 'Update ccsp_GalateaGetOutboundConfiguration'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
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
	)
	DECLARE @numbers VARCHAR(max)

	SELECT @numbers = COALESCE(@numbers + '''''''', '''''''', '''''''''''''''') + number
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
	FROM @AllCampaigns
	WHERE cam_id = @campID
	END'
	EXEC(@sql)

	SET @process = 'Update ccsp_RIAConfCamp'
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
	FROM ccCamps a1
	INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
	INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
	LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
	LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
	ORDER BY cam_descripcion

	RETURN (0)

	SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'Update ccsp_RIAUpdateCamConfigExtend'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
					@cam_id smallint,
					@zipCodeSchedule BIT = NULL,
					@userId SMALLINT = NULL,
					@idArea SMALLINT = NULL, 
					@isCreating SMALLINT = NULL,
					@simultaneousRecs SMALLINT = NULL,
					@module INT = -1,
					@recordCalls tinyint = 1
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
							RecordCalls = ISNULL(@recordCalls, RecordCalls)
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
									WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'') THEN
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
						INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule,SimultaneousRecs, RecordCalls) values (@cam_id,@zipCodeSchedule,@simultaneousRecs, @recordCalls)
					end

					update ccCamps set call_record = @recordCalls where cam_id = @cam_id

					set nocount off
				END'
	EXEC(@sql)

	SET @process = 'alter procedure ccsp_UnassignedElementsInAreas'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UnassignedElementsInAreas]   
					@Action INT,   
					@AreaId INT = 0,
					@Ids VARCHAR(MAX) = ''''
				AS    
				BEGIN
					DECLARE @IdsTemp TABLE (Id INT);
					DECLARE @Id VARCHAR(MAX);
					INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

					-- Return results 
					IF @Action IN (0, 3, 6)	-- User names 
					BEGIN 
						SELECT ISNULL(login,'''')  AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccUsers users ON users.User_id = ids.Id
					END

					IF @Action IN (1, 4, 7)	-- Campaign names
					BEGIN 
						SELECT ISNULL(cam_descripcion,'''')  AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccCamps campaign ON campaign.cam_id = ids.Id
					END

					IF @Action IN (2, 5, 8)	-- Acd names
					BEGIN 
						SELECT ISNULL(descripcion,'''') AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccInbound acd ON acd.Inbound_id = ids.Id
					END
					-------------------------------------------------------
					IF @Action = 0 -- Assign Users to Unassigned area 
					BEGIN
						UPDATE ccUsers
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
							status = 1
						FROM @IdsTemp ids
						WHERE ccUsers.User_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccUsers WHERE IDArea = @AreaId AND User_id = ids.Id)
					END

					IF @Action = 1 -- Assign Users to Campaigns area 
					BEGIN
						UPDATE ccCamps
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END
						FROM @IdsTemp ids
						WHERE ccCamps.cam_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccCamps WHERE IDArea = @AreaId AND cam_id = ids.Id)
					END

					IF @Action = 2 -- Assign Users to Acds area 
					BEGIN		
						UPDATE ccInbound
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
							status = 1
						FROM @IdsTemp ids
						WHERE ccInbound.Inbound_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccInbound WHERE IDArea = @AreaId AND Inbound_Id = ids.Id)
					END

					IF @Action in (3, 4, 5, 6, 7, 8)
					BEGIN 
						SET @Id = ''0''
						WHILE EXISTS( SELECT Id FROM @IdsTemp ) 
						BEGIN
							SELECT TOP 1 @Id =Id FROM @IdsTemp 

							IF @Action = 3 -- Unassign Users from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option = 2, @DeleteUserId = @Id
							END

							IF @Action = 4 -- Unassign Campaigns from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option=4, @DeleteCamId = @Id
							END 

							IF @Action = 5 -- Unassign Acds from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option = 6, @DeleteACDGroupId = @Id
							END

							IF @Action = 6 -- Delete Users from area 
							BEGIN
								EXEC ccsp_RIA_ABCAgents @option=4, @UserId = @Id, @Login = '''', @Nombres='''',@ApellidoPaterno='''',@ApellidoMaterno='''',@Password='''',@Sexo=0,@canChangeStatus=0,@AreaId=0,@UserType=0,@IDWG=0
							END

							IF @Action = 7 -- Delete Campaigns from area 
							BEGIN
								EXEC ccsp_RIA_ABCCamps @option = 4, @UserId = 0, @Descripcion = '''', @Cam_id = @Id, @Activa = 0, @IDArea = 0, @frame = 0
								delete ccCamps with(rowlock) where cam_id = @Id
								delete ccCampsExtend with(rowlock) where cam_id = @Id
							END

							IF @Action = 8 -- Delete Acds from area 
							BEGIN
								EXEC ccsp_RIA_ABCACDGroups @option = 4, @UserId = 0, @Descripcion = '''', @Inbound_id = @Id, @IDArea = 0, @frame = 0
								delete ccInbound with(rowlock) where Inbound_id = @Id
								delete ccInboundExtend with(rowlock) whwre Inbound_Id = @Id
							END

							DELETE FROM @IdsTemp WHERE Id = @Id
						END
					END
				END'
	EXEC(@sql)
	
	SET @process = 'Drop call setting procedure'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAACDCallParams'') begin
					Drop PROCEDURE [dbo].[ccsp_RIAACDCallParams]
				end'
	EXEC(@sql)

	SET @process = 'Create ccsp_RIAACDCallParams'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAACDCallParams]
				@option int,
				@campId int = 0
				AS
				BEGIN
					SET NOCOUNT ON;

				if(@option = 1)
				begin
					select RecordCalls from ccInboundExtend where Inbound_id = @campId				
				end

				if(@option = 2)
				begin
					select RecordCalls from ccCampsExtend where cam_id = @campId				
				end


					SET NOCOUNT OFF;
				END'
	EXEC(@sql)

---------------------------------------END KR091000 Uriel Cabrera Setting configurations and utilities --------------------------------------------------------
	---------------------------------------BEGIN Jesus Gallardo KR091000 Setting grabar llamadas por campa�a ---------------------------------------------------------

set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)

SET @process = 'KR091000 Alter Column ccoCallsout.file_moved tinyint'
SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccoCallsout'' and COLUMN_NAME=''file_moved'' and DATA_TYPE=''bit''
)
begin
    alter table ccoCallsout alter column file_moved tinyint;
end'
EXEC(@sql)

SET @process = 'KR091000 Alter Column ccCallsIn.file_moved tinyint'
SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''file_moved'' and DATA_TYPE=''bit''
)
begin
    alter table ccCallsIn alter column file_moved tinyint;
end'
EXEC(@sql)

set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
EXEC(@sql)

SET @process = 'KR091000 Alter SP getPrefixByAcdId Add parameter @phone'
SET @sql = 'ALTER procedure [dbo].[getPrefixByAcdId] 
@inboundId int,@phone varchar(50) = ''''
as
declare @prefijo varchar(40),@recordHold tinyint,@call_record as tinyint
declare @countryId as tinyint 

select @countryId = valor from ccsettings with(nolock) where setting_id = 104

select @prefijo= isnull(prefijo,''''),@recordHold= ISNULL(recordHold,0)  ,@call_record=ISNULL(B.RecordCalls,1)
from ccInbound A
left join ccInboundExtend B on A.Inbound_id=B.Inbound_id
where A.Inbound_id = @inboundId

select @prefijo prefijo,@recordHold recordHold ,dbo.EnableCallRecord(@call_record,@countryId,@phone)  callRecord
'
EXEC(@sql)

SET @process = 'KR091000 Alter FN EnableCallRecord Add @call_record_cam option 3 y 4'
SET @sql = 'ALTER function [dbo].[EnableCallRecord](@call_record_cam tinyint,@pais tinyint, @tel varchar(32))
RETURNS tinyint
AS  
BEGIN


if @call_record_cam = 1  begin
	return 1 -- grabar 
end

else if @call_record_cam=3  begin
	return 0 -- no grabar
end

declare @callRecordOri tinyint

set @callRecordOri=@call_record_cam

-- grabar zonas permitidas
if @pais=4 begin
	if len(@tel) = 10 begin
		select @call_record_cam = isnull(call_record,1)  from ccTimeZoneArea where id_country= @pais and area = left(@tel,3)		
	end
end
if @call_record_cam=0 begin
	if @callRecordOri=4 begin
		return @callRecordOri  --No Grabar pero puede cambiar a grabar desde el agente
	end	
end

return @call_record_cam
	
END'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccspAgent_GetLastCalls @lastCallAgt--> PRIMARY KEY(id,tipo)'
SET @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
SET NOCOUNT ON;
DECLARE @lastCallAgt TABLE(id           INT NOT NULL
						, tipo         VARCHAR(10) NOT NULL
						, Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
						, Telefono     VARCHAR(55) NOT NULL
						, EspCamp      VARCHAR(55) NOT NULL
						, Calificacion VARCHAR(60)
						, Duracion     VARCHAR(10) NOT NULL
						, CallBack     DATETIME
						, cal_key      VARCHAR(40)
						, IDCampEsp    SMALLINT NOT NULL
						, prefijo      VARCHAR(255) NULL
						, GraphicID    INT
						, CamManualMode INT
						, SelectRotativeANI INT
						, PRIMARY KEY(id,tipo)
);

DECLARE @pais TINYINT;
DECLARE @maxHours SMALLINT;
DECLARE @topRows INT;
DECLARE @setting VARCHAR(6);
DECLARE @hidePhone BIT;
DECLARE @dateStart DATETIME;

SET @hidePhone = 1;

SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

IF @maxHours = 0
BEGIN
	SELECT Id
		, tipo
		, (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
		, Telefono
		, EspCamp
		, Calificacion
		, CallBack
		, Duracion
		, '''' AS CallBack
		, cal_key
		, IDCampEsp
		, prefijo
		, GraphicID
		, SelectRotativeANI
		, @hidePhone AS HidePhone FROM @lastCallAgt;

	RETURN 0;
END;

SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

SELECT @hidePhone = CASE WHEN valor = ''0''
					THEN 0 ELSE 1
					END FROM ccSettings WHERE setting_id = 223;

IF @topRows = 0
BEGIN
	SET @topRows = 10000;
END;

SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

WITH timeTransfer
	AS (SELECT cal_id
			, tipo
			, SUM(tAntesXfer) AS tAntesXfer
			, SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
		WHERE fechaFin > @dateStart
		GROUP BY cal_id
				, tipo)

	INSERT INTO @lastCallAgt
			---Insert OUT
			SELECT TOP (@topRows) c.cal_id AS id
								, ''OUT'' AS Tipo
								, cal_inicio
								, cal_telefono AS Telefono
								, cam_descripcion AS EspCamp
								, ISNULL(cal.Description, '''') AS Calificacion
								, CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																						THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																						END, 0), 114) AS Duracion
								, cal_fcallback AS CallBack
								, cal_key
								, c.cam_id AS IDCampEsp
								, ISNULL(ccCamps.prefijo, '''') Prefijo
								, graph.graphic_id GraphicID
								, cam_ModoManual as CamManualMode 
								, ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
																INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
																LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
																LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
																LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																							AND t.tipo = 2
			WHERE user_id = @user_id
				AND cal_inicio > @dateStart
			UNION
			--- IN
			SELECT TOP (@topRows) c.cal_id AS id
								, ''IN'' AS Tipo
								, cal_inicio
								, cal_ani AS Telefono
								, descripcion AS EspCamp
								, ISNULL(cal.Description, '''') AS Calificacion
								, CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																								THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																								END, 0), 108) Duracion
								, NULL AS CallBack
								, cal_key
								, c.inbound_id AS IDCampEsp
								, ISNULL(ccInbound.prefijo, '''') Prefijo
								, graph.graphic_id GraphicID
								, '''' as CamManualMode 
								, 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
																JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
																INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
																LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
																LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																							AND t.tipo = 1
			WHERE user_id = @user_id
				AND cal_inicio > @dateStart;

SELECT Id
	, tipo
	, CASE WHEN @pais = 4
	THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
	END AS Hora
	, Telefono
	, EspCamp
	, Calificacion
	, ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
	, Duracion
	, CallBack
	, cal_key
	, IDCampEsp
	, prefijo
	, GraphicID
	, @hidePhone AS HidePhone 
	, CamManualMode 
	, SelectRotativeANI FROM @lastCallAgt
ORDER BY hora DESC;
SET NOCOUNT OFF;
		'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_LoadGraphics @realValue variable bit->int'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_LoadGraphics]
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

		select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage ,
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
		@realValue as IsStartStopRecording
		from ccRIACampsGraph a1 
		inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
		inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
		left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
		from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
		where M.cam_id = @Id and type = 8) b 
		on (a2.cam_id = b.cam_id) 
		where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
	 end	
END
'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_DLRgetDialPrefix variable @call_record_cam bit->tinyint'
SET @sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
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
declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
declare @PrefixRec varchar(40)
declare @carrier varchar(255)
declare @recordHold bit

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id
select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campa�a,
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

SET @process = 'KR091000 ALTER SP ccsp_AvrsSyncronization change column isCallRecord convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization] @action SMALLINT, @maxRecordsToTransfer INT = 10, @id INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	DECLARE @countrId INT

	SET @countrId = 1

	SELECT @countrId = valor
	FROM ccSettings
	WHERE setting_id = 104;

	WITH callsIn
	AS (
		SELECT TOP (@maxRecordsToTransfer) 
		calls.cal_id, user_id, calls.Inbound_id, calls.calif_id 
		, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone
		, isnull(cal_tDialog - cal_tMoh, 0) + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
		, cal_key, 0 AS cal_manual, cal_puerto
		, calls.dni_id, fvalida, cal_whohung
		, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
		, CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
		, dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo
		
		, convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
		, isnull(dni.dni_numero, '''') AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
		
		FROM ccCallsIn  AS  calls 	with(nolock)
		INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
		INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id	AND avrs.tipo = 0
		LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
		left join ccInboundExtend inbExt on inbExt.Inbound_id=calls.Inbound_id
		LEFT JOIN (
			SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
			FROM ccLogTransfers
			WHERE tipo = 1
			GROUP BY cal_id, tipo
			) trans ON calls.cal_id = trans.cal_id
		WHERE calls.User_id > 0
		), callsOut
	AS (
		SELECT TOP (@maxRecordsToTransfer) 
		calls.cal_id AS CallId, user_id AS UserId, calls.cam_id AS camAcdId
		, cast(calls.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, cal_inicio, cal_telefono
		, isnull(cal_tDialog - cal_tMoh, 0) + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
		, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, cal_whohung
		, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
		, CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
		, dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo
		
		, convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
		, '''' AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
		FROM ccoCallsOut AS calls with(nolock)
		INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
		INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
		LEFT JOIN (
			SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
			FROM ccLogTransfers
			WHERE tipo = 2
			GROUP BY cal_id, tipo
			) trans ON calls.cal_id = trans.cal_id
		WHERE calls.User_id > 0
		)

		select * from callsIn
		union 
		select * from callsOut
		
END
ELSE IF @action = 2
BEGIN
	DELETE
	FROM ccAVRSTransfer
	WHERE id = @id
END
'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_AgentGetStartStopPermission change statement->return and validate value @callrecord'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentGetStartStopPermission]
@age_id int,
@cam_id int,
@call_type int,
@phone varchar(50)=null
AS
BEGIN
	SET NOCOUNT ON;

	declare @agentRec int, @valor as int
	declare @callrecord tinyint
	set @valor = 0
	select @agentRec=isnull(startStopRecording,0) from ccusers (nolock) where [User_id] = @age_id
	
	IF @agentRec = 1
	BEGIN
		
		---------- Entra agente con permiso de StartStopRecording
		IF @call_type = 1 ------- Revisamos camp In
			select @valor=isnull(startStopRecording,0),@callrecord=ISNULL(B.RecordCalls,1) from ccInbound  A (nolock) 
			left join ccInboundExtend B on A.Inbound_id=B.Inbound_id
			where A.Inbound_id = @cam_id
		ELSE ------- Revisamos Camp Out
			select @valor=isnull(startStopRecording,0),@callrecord=ISNULL(call_record,1) from ccCamps (nolock) where cam_id = @cam_id		

		if @valor=0 begin
			return 0 --Permiso desactivo antes
		end
		declare @countryId as tinyint 
		select @countryId = valor from ccsettings with(nolock) where setting_id = 104

		set @callrecord=dbo.EnableCallRecord(@callrecord,@countryId,@phone)
				
		return @callrecord
	END	
	return 0
END'
EXEC(@sql)

---------------------------------------END Jesus Gallardo KR091000 Setting grabar llamadas por campa�a ---------------------------------------------------------

		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
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
