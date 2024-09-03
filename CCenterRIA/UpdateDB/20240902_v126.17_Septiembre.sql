/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/07/04
Description: KR140000
Database: CCenterRia
Required version: 126.16
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 17
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
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
        
	
	SET @process = 'DEV2-639 Drop Trigger tg_ccRIALoading_IA'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE name = ''tg_ccRIALoading_IA'')
BEGIN
    DROP TRIGGER [dbo].[tg_ccRIALoading_IA];
END'
    EXEC(@sql)
    
	SET @process = 'DEV2-639 Create Trigger tg_ccRIALoading_IA'
	SET @sql = 'CREATE TRIGGER [dbo].[tg_ccRIALoading_IA]
ON [dbo].[ccRIALoading]    
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM INSERTED A INNER JOIN ccCamps c ON c.cam_id = A.cam_id WHERE c.CampType = 4)
    BEGIN
        DECLARE @datenow DATETIME = GETDATE();

        UPDATE B 
        SET B.dateUpdate = @datenow 
        FROM INSERTED A
        INNER JOIN ccRIALoadingTmpIA B ON A.[load_id] = B.[load_id]
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4;

        INSERT INTO ccRIALoadingTmpIA (load_id, dateUpdate)
        SELECT A.[load_id], @datenow 
        FROM INSERTED A
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4
        LEFT JOIN ccRIALoadingTmpIA B ON A.[load_id] = B.[load_id]
        WHERE B.dateUpdate IS NULL;
    END
END;'
    EXEC(@sql)

	SET @process = 'DEV2-639 Drop Trigger tg_ccCamps_IA'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE name = ''tg_ccCamps_IA'')
BEGIN
    DROP TRIGGER [dbo].[tg_ccCamps_IA];
END'
    EXEC(@sql)

	SET @process = 'DEV2-639 Create Trigger tg_ccCamps_IA'
	SET @sql = 'CREATE TRIGGER [dbo].[tg_ccCamps_IA]
ON [dbo].[ccCamps]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM INSERTED WHERE CampType = 4)
    BEGIN
        DECLARE @datenow DATETIME = GETDATE();

        UPDATE B 
        SET B.dateUpdate = @datenow 
        FROM INSERTED A
        INNER JOIN ccCampsTmpIA B ON A.cam_id = B.cam_id AND A.CampType = 4;

        INSERT INTO ccCampsTmpIA (cam_id, dateUpdate)
        SELECT A.cam_id, @datenow 
        FROM INSERTED A
        LEFT JOIN ccCampsTmpIA B ON A.cam_id = B.cam_id  
        WHERE B.cam_id IS NULL AND A.CampType = 4;
    END
END;'
    EXEC(@sql)

	SET @process = 'DEV2-639 Drop Trigger tg_ccoCallsOutSource_IA'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE name = ''tg_ccoCallsOutSource_IA'')
BEGIN
    DROP TRIGGER [dbo].[tg_ccoCallsOutSource_IA];
END'
    EXEC(@sql)
	
	SET @process = 'DEV2-639 Create Trigger tg_ccoCallsOutSource_IA'
	SET @sql = 'CREATE TRIGGER [dbo].[tg_ccoCallsOutSource_IA]
ON [dbo].[ccoCallsOutSource]
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM INSERTED A INNER JOIN ccCamps c ON c.cam_id = A.cam_id WHERE c.CampType = 4)
    BEGIN
        DECLARE @datenow DATETIME = GETDATE();

        UPDATE B 
        SET B.dateUpdate = @datenow 
        FROM INSERTED A
        INNER JOIN ccoCallsOutSourceTmpIA B ON A.callout_id = B.callout_id
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4;

        INSERT INTO ccoCallsOutSourceTmpIA (callout_id, dateUpdate)
        SELECT A.callout_id, @datenow 
        FROM INSERTED A
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4
        LEFT JOIN ccoCallsOutSourceTmpIA B ON A.callout_id = B.callout_id
        WHERE B.dateUpdate IS NULL;
    END
END;'
    EXEC(@sql)
	
	SET @process = 'DEV2-639 Drop Trigger tg_ccoCallsOut_IA'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE name = ''tg_ccoCallsOut_IA'')
BEGIN
    DROP TRIGGER [dbo].[tg_ccoCallsOut_IA];
END'
    EXEC(@sql)
	
	SET @process = 'DEV2-639 Create Trigger tg_ccoCallsOut_IA'
	SET @sql = 'CREATE TRIGGER [dbo].[tg_ccoCallsOut_IA]
ON [dbo].[ccoCallsOut]
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM INSERTED A INNER JOIN ccCamps c ON c.cam_id = A.cam_id WHERE c.CampType = 4)
    BEGIN
        DECLARE @datenow DATETIME = GETDATE();

        UPDATE B 
        SET B.dateUpdate = @datenow 
        FROM INSERTED A
        INNER JOIN ccoCallsOutTmpIA B ON A.cal_id = B.cal_id
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4;

        INSERT INTO ccoCallsOutTmpIA (cal_id, dateUpdate)
        SELECT A.cal_id, @datenow 
        FROM INSERTED A
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4
        LEFT JOIN ccoCallsOutTmpIA B ON A.cal_id = B.cal_id
        WHERE B.dateUpdate IS NULL;
    END
END;'
    EXEC(@sql)
	
	SET @process = 'DEV2-639 Drop Trigger tg_ccoLogDials_IA'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE name = ''tg_ccoLogDials_IA'')
BEGIN
    DROP TRIGGER [dbo].[tg_ccoLogDials_IA];
END'
    EXEC(@sql)
	
	SET @process = 'DEV2-639 Create Trigger tg_ccoLogDials_IA'
	SET @sql = 'CREATE TRIGGER [dbo].[tg_ccoLogDials_IA]
ON [dbo].[ccoLogDials]
AFTER INSERT, UPDATE
AS 
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM INSERTED A INNER JOIN ccCamps c ON c.cam_id = A.cam_id WHERE c.CampType = 4)
    BEGIN
        DECLARE @datenow DATETIME = GETDATE();

        UPDATE B 
        SET B.dateUpdate = @datenow 
        FROM INSERTED A
        INNER JOIN ccoLogDialsTmpIA B ON A.logDial_id = B.logDial_id
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4;

        INSERT INTO ccoLogDialsTmpIA (logDial_id, dateUpdate)
        SELECT A.logDial_id, @datenow 
        FROM INSERTED A
        INNER JOIN ccCamps c ON c.cam_id = A.cam_id AND c.CampType = 4
        LEFT JOIN ccoLogDialsTmpIA B ON A.logDial_id = B.logDial_id
        WHERE B.logDial_id IS NULL;
    END
END;'
    EXEC(@sql)
	
	SET @process = 'TT11673 TT11674 Alter sp ccsp_RIAUpdateCamConfig - se agrega validacion para nombre duplicado'
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
	@recordHold bit = null,
	@userId                SMALLINT     = NULL, 
	@idArea                SMALLINT     = NULL, 
	@isCreating            SMALLINT          = NULL,
	@camCanceled int = null,
	@recordIvr bit = null,
	@module INT = -1,
	@maxLimitQueueConversations SMALLINT = NULL
	as
	set nocount on
	
	IF EXISTS (SELECT 1 FROM ccCamps WHERE cam_descripcion = @cam_descripcion AND cam_id <> @cam_id)
	BEGIN
		SELECT -1 -- Nombre ya esta en uso
		RETURN(0)
	END
	
	DECLARE @timesDiscardActual int = -1, @camCanceledActual int = -1, @recordIvrActual int = -1
	SELECT @timesDiscardActual = timesDiscard, @camCanceledActual = camcanceled, @recordIvrActual = recordIvr FROM ccCamps WHERE cam_id = @cam_id
	DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
		DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

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
		CampType = (CASE WHEN @callsBySurvey is not null AND @ivrScript is not null THEN
						CASE WHEN @callsBySurvey=0 and @ivrScript=0 THEN 0 
							ELSE 8 
						END
					WHEN @CampType is not null THEN @CampType 
					WHEN @progDial = 2 THEN 6 
					WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 
					WHEN CampType is not null THEN CampType ELSE 0 END),
		selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
		messagingOrder = isnull(@messagingorder, messagingOrder),
		autoStart = isnull(@autoStart,autoStart),
		recordHold = isnull(@recordHold, recordHold),
	CamCanceled = ISNULL(@camCanceled, CamCanceled),
	recordIvr = isnull(@recordIvr, recordIvr)

		Where cam_id = @cam_id

			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

			Create table #ccCampsTable 
			(
				columnInfo VARCHAR(255),
				dataInfo VARCHAR(255),
				identifierInfo VARCHAR(255)
			)

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
			
			IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

			IF(@isCreating = 1) 
			BEGIN
				DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
			END

			IF(@isCreating = 2) 
			BEGIN
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) AND @recordIvrActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) and @camCanceledActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');				
			END
				
			DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
			DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
				
			IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
			ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
			ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
			ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
			ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				@module,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
					THEN
						CASE
							WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
								CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
								CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
								CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
							ELSE
								CCCT.identifierInfo
							END
					ELSE
					''''
					END,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
					CASE 
						WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
							CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
								THEN ''COMMON_VOICE_MAIL'' 
								ELSE 
									CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
								END
						WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
								ELSE ''COMMON_ASSISTED'' END

						WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
							CASE WHEN  @CampType = 5 THEN 
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							ELSE
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
									WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
									WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
									ELSE ''T&COMMON_NONE'' END
							END

						WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
									ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

						WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
						WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
													''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
													''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
						WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							
						ELSE CCCT.dataInfo END
				ELSE '''' END, 
				CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
			FROM #ccCampsTable AS CCCT;

			EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

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

		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		Create table #contactMeanOutTable 
		(
			columnInfo VARCHAR(255),
			dataInfo VARCHAR(255),
			identifierInfo VARCHAR(255)
		)

		EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

		DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

		set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
		UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
												closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
								allowFileAttachments = @allowFileAttachments,
					maxLimitQueueConversations = @maxLimitQueueConversations
		WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

			
		IF(@isCreating > 0 AND @module > -1) BEGIN 
			EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
			IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
		END

		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			@module, 
			CMOT.identifierInfo,
			CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
				CASE
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
						CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
						CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
					ELSE CMOT.dataInfo END
			ELSE '''' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		FROM #contactMeanOutTable AS CMOT;

		EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		IF @CampType = 5 BEGIN
			update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
			update ccMetaWhatsAppNumbers set Cam_Id=0 where Cam_Id=@cam_id

			IF(@ConexionInfo <> '''')
			BEGIN
				IF EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @ConexionInfo)
					UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
				IF EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @ConexionInfo)
					UPDATE ccMetaWhatsAppNumbers SET Cam_Id = @cam_id WHERE number = @ConexionInfo
			END
		END
	END 
	DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

	IF @cam_ShowCalifWnd = 1
	BEGIN
		IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		UPDATE ccCamps SET
		cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
		WHERE cam_id = @cam_id


		IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				3, 
				''OUT_SHOW_DISPOSITIONS'',
				CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
				(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
		END

		SELECT 1
		RETURN(0)
	END

	UPDATE ccCamps SET
	cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
	where cam_id = @cam_id

	IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			3, 
			''OUT_SHOW_DISPOSITIONS'',
			CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
	END

	SELECT 2
	RETURN(0)

	set nocount off'
	EXEC (@sql)
	
	SET @process = 'DEV2-386 Add column dialPrefix to xxClienteCarga'
	SET @sql = 'if not exists (select * from sys.columns where name = N''dialPrefix'' and Object_ID = Object_ID(N''xxClienteCarga''))
begin
	alter table xxClienteCarga add dialPrefix varchar(30) null default ''''
end'
	EXEC(@sql)
	
	SET @process = 'DEV2-386 Drop sp xx_Inserta'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''xx_Inserta'')
    BEGIN
        DROP PROCEDURE [dbo].[xx_Inserta]
    END'
	EXEC(@sql)

	SET @process = 'DEV2-386 Create sp xx_Inserta'
	SET @sql = 'CREATE PROCEDURE [dbo].[xx_Inserta] 
	@cal_key varchar(20),
	@cal_telefono varchar(19),
	@cal_telefono2 varchar(19),
	@cal_telefono3 varchar(19),
	@cal_telefono4 varchar(19),
	@cal_telefono5 varchar(19),
	@dato1 varchar(255),
	@dato2 varchar(255),
	@dato3 varchar(255),
	@dato4 varchar(255),
	@dato5 varchar(255),
	@cam_id integer,
	@FCallBack smalldatetime = '''',
	@cal_status tinyint=0,
	@User_id integer=0,
	@dialPrefix varchar(30) = ''''
	as
	declare @calloutid int
	if (@cal_status=0) set @FCallBack=getdate()
	Insert into ccoCallsOutSource ( cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id, dialPrefix)
	values ( @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5, @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id, @dialPrefix)
	select @calloutid=scope_identity()
	--Insert into xxClienteHistorial ( callout_id , fechaAct ) values ( @calloutid, getdate() )
	select @calloutid'
	EXEC(@sql)
	




        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
