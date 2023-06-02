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
SET @versionfix = 25
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

	---------------------------------------BEGIN Jonathan Ramirez K020101, K020102, K020103 Whatsapp Out---------------------------------------------------------
	SET @process = '0 - JR - The module Settings was added and the relation with their operations '
	SET @sql = '
IF NOT EXISTS (SELECT * FROM ccGalateaModules WHERE ModuleId = 5) INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) VALUES (5, ''Ajustes'', ''Settings'', ''Ajustes'');

IF EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 54) AND EXISTS (SELECT * FROM ccGalateaModules WHERE ModuleId = 5) INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (5, 54);
IF EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 55) AND EXISTS (SELECT * FROM ccGalateaModules WHERE ModuleId = 5) INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (5, 55);
IF EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 56) AND EXISTS (SELECT * FROM ccGalateaModules WHERE ModuleId = 5) INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (5, 56);
IF EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 57) AND EXISTS (SELECT * FROM ccGalateaModules WHERE ModuleId = 5) INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (5, 57);
IF EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 58) AND EXISTS (SELECT * FROM ccGalateaModules WHERE ModuleId = 5) INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (5, 58);

IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MANUAL_DIALING_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MANUAL_DIALING_WHATS'',''Enviar mensaje manualmente'',''Send message manually'',''Enviar mensagem manualmente'');
	'
	EXEC(@sql)

	SET @process = '1 - JR - ccsp_RIAUpdateCamConfig - Was added a new property @module to know from where comes the change'
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
@recordHold bit = null,
@userId                SMALLINT     = NULL, 
@idArea                SMALLINT     = NULL, 
@isCreating            SMALLINT          = NULL,
@module INT = -1
as
set nocount on
DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
    DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

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

        IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
        
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
                              closeConversationTime = @agentCloseConversationTime, answerTimeoutClient = @adminCloseConversationTime,
                              allowFileAttachments = @allowFileAttachments
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
        IF(@ConexionInfo <> '''')
        BEGIN 
            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
        END
    END
END 
DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

if @cam_ShowCalifWnd = 1
begin
 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
  begin
  select 0
  return(0)
  end


 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
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

 select 1
 return(0)
end

 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
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

select 2
return(0)

set nocount off
	'
	EXEC(@sql)

	SET @process = '2 - JR - ccsp_RIA_ABCCamps - The property @module was added to validate the change of the Icon only from Areas Module'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
                    @option smallint,
                    @UserId int = null,
                    @Descripcion varchar(40) = null,
                    @Cam_id varchar(1000),
                    @Activa tinyint = null,
                    @IDArea smallint = null,
                    @frame tinyint = null, 
                    @MirrorInbound_Id smallint = null,
                    @Prefijo varchar(40) = null,
                    @MediaType int = null,
					@isCreating int = null,
					@module int = -1
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

                        DECLARE @CampTypeNormal INT = 1

                        if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
                            begin
                            select -1 --, ''Nombre en Uso''
                            return(0)  
                            end

                        -- ODC: la campa?a siempre esta activa
                        set @Activa = 1
                        declare @pref int
                        select  @pref = valor from ccSettings where setting_id = 201
                        if (@pref = 0)
                            set @Prefijo = ''''


                        Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
                        select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
                        case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

                        if @@rowcount = 1 BEGIN
                        select @new_cam_id = scope_identity()

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                            getDate(), 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                            CASE 
                                WHEN @MediaType = 6 THEN 44
                                WHEN @MediaType = 5 THEN 46
                                WHEN @MediaType = 4 THEN 48
                                WHEN @MediaType = 7 THEN 50
                                ELSE 42 END, 
                            3, 
                            '''',
                            '''', 
                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @new_cam_id);

                        END else
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

                            DECLARE @PrevFrame SMALLINT = (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id);

                            update ccRIACampsGraph with(rowlock)
                            set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            where cam_id = @Cam_id

							IF(@isCreating IS NOT NULL AND @isCreating = 2 AND @PrevFrame <> (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id) AND @module = 3) BEGIN
                                DECLARE @Media INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @Cam_id);

                                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                                SELECT 
                                    (SELECT CRA.[AreaName] FROM ccRIACat_Areas AS CRA, ccCamps AS CCC WHERE CRA.IDArea = CCC.IDArea AND CCC.cam_id = @Cam_id),
                                    getDate(), 
                                    (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                                    CASE
                                        WHEN @Media = 6 THEN 55
                                        WHEN @Media = 5 THEN 56
                                        WHEN @Media = 4 THEN 57
                                        WHEN @Media = 7 THEN 58
                                        ELSE 54 END, 
                                    3, 
                                    '''',
                                    ''OUT_CALL_EDIT_ICON'', 
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @Cam_id);
                            END

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
                    set nocount off
	'
	EXEC(@sql)

	SET @process = ' 3 - JR - ccspConfigSMSCamp - Was added a new property @module to know from where comes the change'
	SET @sql = '
ALTER procedure [dbo].[ccspConfigSMSCamp] (@process int, @cam_id smallint,@strIDates nvarchar(max),@strFDates nvarchar(max),
    @userId                SMALLINT, 
    @idArea                SMALLINT, 
	@isCreating			   SMALLINT,
	@module			       INT = -1
 )
    as
    declare @i int
    declare @tempTableFDates as table (Id int,Value nvarchar(255))
    declare @tempTableIDates as table (Id int,Value nvarchar(255))

    select @i=1
    insert into @tempTableFDates select * from fn_RIASplitDelimited(@strFDates,'','')
    insert into @tempTableIDates select * from fn_RIASplitDelimited(@strIDates,'','')

    if(@process = 0) --Create SMS campaign
    begin
        while @i <= (select count(Value) from @tempTableFDates)
        begin
            insert into ccSmsSchedules (cam_id,iDate,fDate) values (@cam_id, (select cast(Value as datetime) from @tempTableIDates where Id = @i), (select cast(Value as datetime) from @tempTableFDates where Id = @i))
            set @i = @i +1
        end
    end
    if(@process = 1) -- Update SMS campaign
    begin

        declare @ccSmsSchedulesDelete table (
        cam_id  smallint,
        iDate   datetime,
        fDate   datetime,
        status int, --0 NOTHING, 2 DELETE
        schedPosition int)

        declare @ccSmsSchedulesUpdate table (
        cam_id  smallint,
        iDate   datetime,
        fDate   datetime,
        status int,
        schedPosition int)

        IF (@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)


        DECLARE @CamDesc VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
        DECLARE @Login VARCHAR(MAX) = (SELECT [Login] FROM ccUsers WHERE User_id = @userid);
        DECLARE @AreaName VARCHAR(MAX) = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea);

        INSERT INTO @ccSmsSchedulesDelete
        SELECT *, 2, ROW_NUMBER() OVER(ORDER BY iDate, fDate ) from ccSmsSchedules WHERE cam_id = @cam_id

        while @i <= (select count(Value) from @tempTableFDates)
        begin

            DECLARE @iDate NVARCHAR(255), @fDate NVARCHAR(255);
            SELECT @iDate = (select cast(Value as datetime) from @tempTableIDates where Id = @i), @fDate = (select cast(Value as datetime) from @tempTableFDates where Id = @i);

            IF(@isCreating = 1) BEGIN 
                insert into ccSmsSchedules (cam_id,iDate,fDate) values (@cam_id, @iDate, @fDate);
                
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    @AreaName,
                    getDate(), 
                    @Login, 
                    CASE WHEN @isCreating = 1 THEN 50 ELSE 58 END, 
                    3, 
                    ''COMMON_DATE_''+CAST(@i AS varchar),
                    @iDate+''&''+@fDate, 
                    @CamDesc;

            END 
            ELSE BEGIN
                insert into @ccSmsSchedulesUpdate (cam_id, iDate, fDate, status, schedPosition)
                values (@cam_id, @iDate, @fDate, 1, @i);
            END

            set @i = @i +1
        end

        update A set A.status=0 from @ccSmsSchedulesDelete A
        inner join @ccSmsSchedulesUpdate B on A.cam_id=B.cam_id and A.iDate=B.iDate and A.fDate=B.fDate

        update A set A.status=0 from @ccSmsSchedulesUpdate A
        inner join @ccSmsSchedulesDelete B on A.cam_id=B.cam_id and A.iDate=B.iDate and A.fDate=B.fDate

        IF EXISTS(SELECT * FROM @ccSmsSchedulesDelete) BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                @AreaName,
                getDate(), 
                @Login, 
                CASE WHEN @isCreating = 1 THEN 50 ELSE 58 END, 
				@module, 
                ''COMMON_DELETE_SCHEDULE_''+CAST(SD.schedPosition AS varchar),
                CONVERT(varchar(max),SD.iDate,109)+''&''+CONVERT(varchar(max),SD.fDate,109),
                @CamDesc
            FROM @ccSmsSchedulesDelete AS SD WHERE SD.status = 2;

            DELETE ccSS 
            FROM ccSmsSchedules ccSS
            INNER JOIN @ccSmsSchedulesDelete ccSDEL ON ccSS.cam_id = ccSDEL.cam_id
            WHERE ccSDEL.iDate = ccSS.iDate AND ccSDEL.fDate = ccSS.fDate AND ccSDEL.status = 2

        END

        IF EXISTS(SELECT * FROM @ccSmsSchedulesUpdate) BEGIN

            DELETE FROM @ccSmsSchedulesUpdate WHERE status = 0;

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    @AreaName,
                    getDate(),
                    @Login, 
                    CASE WHEN @isCreating = 1 THEN 50 ELSE 58 END, 
					@module, 
                    ''COMMON_ADD_SCHEDULE_''+CAST((schedPosition) AS varchar),
                     CONVERT(varchar(max),iDate,109)+''&''+CONVERT(varchar(max),fDate,109), 
                    @CamDesc
                FROM @ccSmsSchedulesUpdate

                INSERT INTO ccSmsSchedules (cam_id, iDate, fDate)  
                SELECT cam_id, iDate, fDate FROM @ccSmsSchedulesUpdate

        END
    end
	'
	EXEC(@sql)

	SET @process = '4 - JR - ccsp_GalateaUpdateVoiceConfiguration - Was added a new property @module to know from where comes the change'
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
	@userId 				smallint	= null,
	@module					int			= -1
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
        recordHold = ISNULL(@recordHold, recordHold)
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
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'') THEN
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
	EXEC(@sql)

	SET @process = '5 - JR - ccsp_GalateaUpdateWhatsAppConfiguration - Was added a new property @module to know from where comes the change'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
        @inboundId        smallint,
        @frame          smallint  = null,
        @description      varchar(50) = null,
        @mediaType        tinyint   = null,
        @status         smallint  = null,
        @number         varchar(400)= null,
        @maxAnswerTime      tinyint   = null,
        @muTimeOutClient    int     = null,
        @tNotas         int     = null,
        @exitWrapUpDisposition  bit     = null,
        @showCalifWnd     bit     = null,
        @allowFileAttachments bit    = null,
		@userId 				smallint	= null,
		@module			int = -1

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
          ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
        WHERE Inbound_id = @inboundId

		IF(@module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable'';	

        DELETE FROM #ccInboundTable WHERE columnInfo IN (''tel_maxwait'', ''tel_maxqueue'', ''tel_outservice'', ''tel_noct'');

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            53, 
			@module,
            CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
            ELSE
                CCIT.identifierInfo
            END,
            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN
                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    ELSE CCIT.dataInfo END
            ELSE '''' END, 
            CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
        FROM #ccInboundTable AS CCIT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

        DECLARE @descUpdate varchar(50)
        DECLARE @statusCCInbound smallint
        select @descUpdate = ISNULL(@description, descripcion), @statusCCInbound = status from ccInbound where Inbound_id =@inboundId

        IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
          BEGIN
              INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
          values (5, @descUpdate, @inboundId, @statusCCInbound);
          END

        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
          BEGIN
          DECLARE @PrevConexion VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanIn WHERE inboundId = @inboundId);
          
		  set @number = case when  @number is null or @number in('''',''0'', ''Ninguno'') then ''Ninguno'' else @number end

          EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inboundId, @userId= @userId

            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

            Create table #contactMeanInTable 
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            )


          UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo)
          ,connUser=ISNULL(@number, connUser)
          ,ConnPass=ISNULL(@number, ConnPass) 
          ,closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime),
          answerTimeoutClient = ISNULL(@muTimeOutClient, answerTimeoutClient),
          allowFileAttachments = ISNULL(@allowFileAttachments, allowFileAttachments)
          where inboundId = @inboundId;

		IF(@module > -1) BEGIN
        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#contactMeanInTable'';  
		END

        IF(@number=''Ninguno'' AND @PrevConexion='''')UPDATE contactMeanIn SET conexionInfo = '''' WHERE inboundId = @inboundId;
        DELETE FROM #contactMeanInTable WHERE columnInfo IN (''name'',''connUser'',''ConnPass'');

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                53, 
				@module, 
                CMIT.identifierInfo,
                CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
                    CASE
                        WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
                            CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        WHEN CMIT.identifierInfo IN (''IN_ASSOCIATED_PHONE_WHATS'') THEN
                            CASE WHEN CMIT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMIT.dataInfo END
                        ELSE CMIT.dataInfo END
                ELSE '''' END, 
                (SELECT [name] FROM contactMeanIn WHERE inboundId = @inboundId)
            FROM #contactMeanInTable AS CMIT;

            EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

          update ccWhatsAppNumbers set inboundId=0 where inboundId=@inboundId
          if @number <> '''' begin
            update ccWhatsAppNumbers set inboundId=@inboundId where inboundId=0 and number=@number
          end

          END

        IF @frame IS NOT NULL
        BEGIN
          SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
          UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

          INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
          SELECT 
                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                53, 
                3,
                '''',
                ''IN_CALL_EDIT_ICON'', 
                (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
        END

        DECLARE @prevCalif BIT = (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId);

        IF @showCalifWnd = 1
          BEGIN
          IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
              BEGIN

            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
                  WHERE inbound_id = @inboundId

            IF(@prevCalif <> @showCalifWnd) BEGIN
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    53, 
                    3,
                    ''IN_SHOW_DISPOSITIONS'',
                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
            END

            SELECT 1 [Result]
            RETURN(0)
              END

              SELECT -1 [Result]
              RETURN(0)
           END
           ELSE
         BEGIN
          UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;

          IF(@prevCalif <> @showCalifWnd) BEGIN
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    53, 
                    3,
                    ''IN_SHOW_DISPOSITIONS'',
                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
            END
         END

         SELECT 1 [Result]
         RETURN(0)

        SET NOCOUNT OFF;
      END
	'
	EXEC(@sql)

    SET @process = '6 - JR - ccsp_RIAUpdateCamConfigExtend - The property @simultaneousRecs was added to the insert, to detect correctly changes and set them on the activity log'
    SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
        @cam_id smallint,
        @zipCodeSchedule BIT = NULL,
        @userId SMALLINT = NULL,
        @idArea SMALLINT = NULL, 
        @isCreating SMALLINT = NULL,
        @simultaneousRecs SMALLINT = NULL,
        @module INT = -1
    AS
    BEGIN
        SET NOCOUNT ON;
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
                simultaneousRecs = isnull(@simultaneousRecs,simultaneousRecs)
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
                        WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'') THEN
                            CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        
                        ELSE CCCE.dataInfo END
                ELSE '''' END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
            FROM #ccCampsExtendTable AS CCCE;

            EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

        end
        else begin
            INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule,SimultaneousRecs) values (@cam_id,@zipCodeSchedule,@simultaneousRecs)
        end
        set nocount off
    END
    '
    EXEC(@sql)
	
	---------------------------------------END Jonathan Ramirez -----------------------------------------------------------
	
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
