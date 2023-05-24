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
SET @versionfix = 21
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci?n para cuando pasamos a una nueva versi?n LTS
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
        -------------------------------------------- BEGIN JONATHAN RAMIREZ FIX HISTORIAL ACTIVIDAD AREAS ------------------------------
SET @process = '0 - ccGalateaIdentifiers - New insertion to identifiers'
SET @sql = 'IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_NONE_O'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_NONE_O'',''Ninguno'',''None'',''Nenhum'');'
EXEC(@sql)

SET @process = '1 - ccsp_RIAUpdateCamConfig - Show record in activity lod when a phone is removed'
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
@isCreating            SMALLINT          = NULL
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
    
        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

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
            3,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                THEN
                    CASE
                        WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                            CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
                            CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
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

    
    IF(@isCreating > 0) BEGIN 
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
        3, 
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

SET @process = '2 - ccsp_GalateaUpdateWhatsAppConfiguration - Add record to ccGalateaActivityLog When phone is removed'
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
        @userId                 smallint    = null

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

        EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable''; 

        DELETE FROM #ccInboundTable WHERE columnInfo IN (''tel_maxwait'', ''tel_maxqueue'', ''tel_outservice'', ''tel_noct'');

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            53, 
            3,
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
          
          set @number = case when  @number is null or @number in('''',''0'') then ''Ninguno'' else @number end

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

        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#contactMeanInTable'';  
        IF(@number=''Ninguno'' AND @PrevConexion='''')UPDATE contactMeanIn SET conexionInfo = '''' WHERE inboundId = @inboundId;
        DELETE FROM #contactMeanInTable WHERE columnInfo IN (''name'',''connUser'',''ConnPass'');

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                53, 
                3, 
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
EXEC(@sql);

SET @process = '3 - Set default Value to parameter mediaType for Xion'
SET @sql = '
ALTER procedure [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint,
@Prefijo varchar(40) = null,
@MediaType int = 0
as
set nocount on
declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
     select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
    isnull(areas.areaname,'''') as areaname
     from ccinbound as acd with(nolock)
     left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
     return(0)
 end

if @option = 1 -- select acd
 begin
     select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id,
     prefijo as Prefijo
     from ccinbound a1 
      inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
      inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
     where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
     order by descripcion
     return(0)
 end

if @option = 2 -- insert
 begin
 
    if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
     begin
            select -1--, ''nombre en uso''
            
            return(0)
     end
    
    if @idarea = 0
    set @idarea = null


    declare @pref int
    select  @pref = valor from ccSettings where setting_id = 201
    if (@pref = 0)
        set @Prefijo = ''''
    
    DECLARE @tempDesc VARCHAR(40);
    SET @tempDesc = CASE WHEN @MediaType = 5 THEN @descripcion ELSE @descripcion+''Tmp'' END;

    insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd,prefijo)
    select @tempDesc, 1, @idarea,case when exists(select calif_id from cctipocalif) then 1 else 0 end
     , @Prefijo
    
    if @@rowcount = 1
        select @new_inbound_id = inbound_id from ccinbound where descripcion = @tempDesc and status = 1

    else
     begin
        select -2 -- Error al insertar
        return(0)
     end

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @new_inbound_id, @userId= @userid

     UPDATE ccInbound SET 
        descripcion = @descripcion,
        ShowCalifWnd = case when exists(select calif_id from cctipocalif) then 1 else 0 end
    WHERE Inbound_id = @new_inbound_id

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';  
    
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE WHEN @MediaType = 5 THEN 40 ELSE 60 END, 
        3, 
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @MediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
             WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @new_inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

    if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
     begin
        insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
        select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
     end

    if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
     begin
        insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
        select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
     end

    if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
     insert into ccriagraphics (frame,type_id) values (@frame,1)
    
     select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
     
     insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
     select @new_inbound_id
     return(0) 
 end

if @option = 3 -- update
 begin
     if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
        insert into ccriagraphics (frame, type_id) values (@frame, 1)

     select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
     update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
     update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
     return(0)
 end

if @option = 4 -- delete
 begin
     delete cccalifcamp where cam_id = @inbound_id and tipo = 0
     delete ccinboundhorarios where inbound_id = @inbound_id
     delete ccriainboundgraph where inbound_id = @inbound_id
     delete ccInboundMsgs where inbound_id = @inbound_id
     delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
     delete ccinbound where inbound_id = @inbound_id
     return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
    if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
     (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
        not exists (select cam_id from ccCamps where cam_id=@descripcion))
     begin
        select -3 -- Campaña o ACD invalido
        return(0)
     end
    
    if @descripcion=0 begin

        set @descripcion = null
        --quitamos calificaciones relacionadas a la campaña
        DELETE c FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
        Where c.cam_id=@inbound_id and ci.CanReprogram =1
        --quitamos subcalificaciones relacionadas a la calificacion
        DELETE rel FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
        inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
        left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        Where c.cam_id=@inbound_id and sb.canReprogram=1
                
    end
    
    update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
        
    if @@rowcount=0
        select -4 -- Error al actualizar

    return(0)
 end
set nocount off
'
EXEC(@sql)

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