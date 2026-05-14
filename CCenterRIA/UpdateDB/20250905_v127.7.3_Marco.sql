/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
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
    SET @version = 127 --**********actualizar a 124 sin fix
    SET @versionfix = 7
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

    SET @process = 'ALTER TABLE ccCampsExtend ADD ManualCallANIMode SMALLINT NULL;'
    SET @sql = 'IF not exists (SELECT 1 FROM SYS.columns WHERE name=''ManualCallANIMode'' 
AND OBJECT_ID = OBJECT_ID(''ccCampsExtend''))
begin
    ALTER TABLE ccCampsExtend ADD ManualCallANIMode SMALLINT NULL;
end'
    exec (@sql)

    SET @process = ' ALTER TABLE ccCamps DROP COLUMN selectRotationManualDialing'
    SET @sql = 'IF exists (SELECT 1 FROM SYS.columns WHERE name=''selectRotationManualDialing'' 
AND OBJECT_ID = OBJECT_ID(''ccCamps''))
begin
    ALTER TABLE ccCamps DROP COLUMN selectRotationManualDialing
end'
    exec (@sql)

    SET @process = 'INSERT INTO relationTableColumnIdentifiers'
    SET @sql = 'IF NOT EXISTS(select 1 from relationTableColumnIdentifiers 
where tableName = ''cccampsextend'' and colunName = ''ManualCallANIMode'')
BEGIN
    INSERT INTO relationTableColumnIdentifiers(Identifiers, tableName, colunName)
    VALUES(''OUT_MANUAL_CALL_ANI_MODE'', ''ccCampsExtend'', ''ManualCallANIMode'')
END

IF NOT EXISTS(select 1 from ccGalateaIdentifiers 
where [Description] = ''OUT_MANUAL_CALL_ANI_MODE'')
BEGIN
    INSERT INTO ccGalateaIdentifiers([Description], TagEs, TagEn, TagPt) VALUES
    (''OUT_MANUAL_CALL_ANI_MODE'', ''Asignación de ANI (llamada manual)'', ''ANI assignment (manual call)'', ''Atribuição de ANI (chamada manual)''),
    (''OUT_MANUAL_CALL_ANI_MODE_SYSTEM'', ''Por sistema'', ''By system'', ''Pelo sistema''),
    (''OUT_MANUAL_CALL_ANI_MODE_AGENT'', ''Por agente'', ''By agent'', ''Pelo agente''),
    (''OUT_MANUAL_CALL_ANI_MODE_NONE'', ''Ninguna'', ''None'', ''Nenhuma'')
END '
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
    @User_id SMALLINT,
    @campID INT = NULL
AS
    SET NOCOUNT ON;

    DECLARE @tableExistsRec TABLE (
        camId INT PRIMARY KEY,
        existRec BIT
    );
    DECLARE @camByUser TABLE (
        camId INT PRIMARY KEY,
        isCheck BIT
    );
    DECLARE @camId INT, @id INT;
    DECLARE @intenationalDialingPorts BIT;
    DECLARE @tempInternationalCode INT;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT TOP 1 IdCode
            FROM ccoDialers ccoDial
            INNER JOIN ccoDialerCamp ccoDialCamp ON ccoDialCamp.dialer_id = ccoDial.dialer_id
            WHERE ccoDialCamp.cam_id = @campID
                AND ccoDial.DialingType = 0
        ) result
    ) > 0
    BEGIN
        SET @intenationalDialingPorts = 1;
    END
    ELSE
    BEGIN
        SET @intenationalDialingPorts = 0;
    END;

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
            OR cam_id = @campID;
    END
    ELSE
    BEGIN
        INSERT INTO @camByUser
        SELECT cam_id, 0
        FROM ccCamps
        WHERE (IDArea > 0 OR IDArea IS NULL)
            AND (@campID IS NULL OR cam_id = @campID);
    END;

    WHILE EXISTS (
        SELECT *
        FROM @camByUser
        WHERE isCheck = 0
    )
    BEGIN
        SELECT TOP 1 @camId = camId
        FROM @camByUser
        WHERE isCheck = 0;

        IF EXISTS (
            SELECT cam_id
            FROM ccoCallsOut
            WHERE cam_id = @camId
        )
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 1);
        END
        ELSE
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 0);
        END;

        UPDATE @camByUser
        SET isCheck = 1
        WHERE camId = @camId;
    END;

    SELECT
        a1.cam_id,
        cam_Descripcion,
        cam_tNotas,
        CAST(cam_ocupado AS INT) AS cam_ocupado,
        cam_noInt_ocupado,
        cam_inter_ocupado,
        CAST(cam_nocontesto AS INT) AS cam_nocontesto,
        cam_noInt_nocontesto,
        cam_inter_nocontesto,
        CAST(cam_fax AS INT) AS cam_fax,
        cam_noInt_fax,
        cam_inter_fax,
        CAST(cam_modomanual AS INT) AS cam_modomanual,
        ANI,
        cam_ShowCalifWnd,
        cam_StartTimerOnHangUp,
        editableCallKey,
        cam_tNoContesta,
        iTipoDial,
        detectAnswerMachine,
        detectVoiceMail,
        compliance,
        cam_inter_graba,
        cam_noint_graba,
        CAST(progDial AS TINYINT) progDial,
        CAST(excCallBack AS TINYINT) excCallBack,
        dialOrder,
        dialPrefix,
        dialPrefixMan,
        dialPrefixXfe,
        listenManualCall,
        stopRecording,
        CAST(abandonCallback AS TINYINT) abandonCallback,
        a3.frame,
        a1.t_autoCB,
        a1.id_anilist,
        a1.tDialonWrapUp,
        dbo.fn_viewMode(@User_id, 10) viewMode,
        cam_maxqueue AS queSize,
        DNCScrub,
        callerIdDesc,
        timeZoneRule,
        callsBySurvey,
        ivrScript,
        surveyPctg,
        ISNULL(a1.call_record, 1) AS call_record,
        CAST(startStopRecording AS TINYINT) startStopRecording,
        leaveRecMessage,
        manualCallOnChat,
        callBackSurveyAgent,
        callBackSurveyClient,
        CASE
            WHEN surveycamid IS NULL OR surveycamid = 0 THEN 0
            ELSE 1
        END isRelationSurvey,
        ISNULL(a1.funcEspDtmf, 0) funcEspDtmf,
        ISNULL(sipHdrFormat, '''') sipHdrFormat,
        cam_inter_cancelled,
        prefijo,
        enbleprefix = CASE
            WHEN existRec = 0 THEN 1
            ELSE 0
        END,
        ISNULL(exitAssisted, 0) exitAssisted,
        ISNULL(previewDiscard, 0) PreviewDiscard,
        case when CampType = 9 then 10 else ISNULL(CampType, 0) end as CampType,
        ISNULL(contact.conexionInfo, '''') conexionInfo,
        ISNULL(contact.connUser, '''') connUser,
        ISNULL(contact.closeConversationTime, 0) closeConversationTime,
        ISNULL(contact.answerTimeoutClient, 0) answerTimeoutClient,
        ISNULL(contact.allowFileAttachments, 0) allowFileAttachments,
        ISNULL(selectRotativeANI, 0) selectRotativeANI,
        ISNULL(rotativeAlgo, 0) rotativeAlgo,
        ISNULL(autoStart, 0) autoStart,
        ISNULL(messagingOrder, 0) messagingOrder,
        ISNULL(cam_tPreview, 0) AS CamTPreview,
        ISNULL(timesPreview, 0) AS TimesPreview,
        ISNULL(timesDiscard, 0) TimesDiscard,
        ISNULL(recordHold, 0) recordHold,
        ISNULL(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule,
        ISNULL(campsExtention.RecordCalls, 1) RecordCalls,
        ISNULL(campsExtention.simultaneousRecs, 1) simultaneousRecs,
        ISNULL(campsExtention.EditableContactData, 0) EditableContactData,
        @intenationalDialingPorts intenationalDialingPorts,
        ISNULL(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent,
        ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations,
        ISNULL(contact.MaxDaysPerWAConvo, 5) MaxDaysPerWAConvo,
        isnull(recordIvr, 1) recordIvr,
        ISNULL(CamCanceled, 4) CamCanceled,
        ISNULL(surveyCamId, 0) surveyCamId,
        -- Outbound AI Campaign Special Settings
        ISNULL(campsExtention.RescheduledSurveyAI, 0) RescheduledSurveyAI,
        ISNULL(campsExtention.ImmediateSurveyAI, 0) ImmediateSurveyAI,
        ISNULL(campsExtention.ApplyRescheduledSurveyForCompletedCallsAI, 0) ApplyRescheduledSurveyForCompletedCallsAI,
        ISNULL(campsExtention.EnableCallRecordingAI, 0) EnableCallRecordingAI,
        -- Manual Rotation Dialing Configurations
        ISNULL(a1.rotativeAlgorithmManual, 4) RotativeAlgorithmManual ,
        ISNULL(a1.idAniListManual, 0) IdAniListManual ,
        ISNULL(campsExtention.ManualCallANIMode, 0) ManualCallANIMode
    FROM ccCamps a1
    INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
    INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
    LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
    LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
    ORDER BY cam_descripcion;

    RETURN (0);

    SET NOCOUNT OFF;
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
@option int,
@UserID int = 0,
@onChat int = 0,
@campId int = 0
AS
set nocount on
if(@option = 1)
begin
    if (@onChat = 0)
    begin
        declare @mod smallint
        declare @IdArea smallint
        declare @DialingMode tinyint
        select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
        select @mod = defCampaing from ccRIACat_Areas A
        where A.IDArea = @IdArea 
        select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual, 
        CASE WHEN isnull(ce.ManualCallANIMode, 0) = 2 THEN 1 ELSE 0 END as selectRotativeANI
        , CASE WHEN c.ivrScript <> 0 AND c.callsBySurvey <> 0 THEN 8 ELSE isnull(c.CampType,0) END as CampType,
        CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
        isnull(c.timesPreview, 0) timesPreview,
        isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule,
        ISNULL(rotativeAlgorithmManual,0) as ManualCallAniAlgorithm
        from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
        join ccRIACampsGraph g ON g.cam_id = c.cam_id
        left join ccCampsExtend ce ON ce.cam_id = c.cam_id
        where ca.user_id = @UserID  
            and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
        order by cam_descripcion
    end
    else 
    begin 
        select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
        , isnull(c.CampType,0) as CampType,
        isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule
        from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
        join ccRIACampsGraph g ON g.cam_id = c.cam_id
        join ccCampsExtend ce ON ce.cam_id = c.cam_id
        where ca.user_id = @UserID and manualCallOnChat = 1
        order by cam_descripcion
        SET NOCOUNT OFF;
    end
end
if(@option = 2)
begin
    declare @aniList int 
    declare @rotativeAlgorithmManual int
    select @aniList = idAniListManual, @rotativeAlgorithmManual  = rotativeAlgorithmManual from ccCamps where cam_id = @campId
    if @rotativeAlgorithmManual > 0 begin
        select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
    end
    else BEGIN
        if exists(select 1 from ccEstadosAni where id_AniList = @aniList and telAni != '''' ) BEGIN
            select telAni from ccEstadosAni where id_AniList = @aniList and telAni != ''''
        END
        ELSE BEGIN
            select top 0 '''' telAni 
        END
    END         
end
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
    @adminID INT
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
        ,internationalDialingPortsAssigned bit
        ,AssignConversationSameAgent bit
        ,maxLimitQueueConversations SMALLINT
        ,MaxDaysPerWAConvo SMALLINT
        ,RecordIvr BIT
        ,CamCanceled INT
        ,surveyCamId int
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI BIT
        ,ImmediateSurveyAI BIT
        ,ApplyRescheduledSurveyForCompletedCallsAI BIT
        ,EnableCallRecordingAI BIT
        -- Manual Rotation Dialing Configurations
        ,rotativeAlgorithmManual SMALLINT
        ,idAniListManual SMALLINT
        ,ManualCallANIMode SMALLINT
        )
        DECLARE @numbers VARCHAR(max)

        SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
        FROM ccWhatsAppNumbers
        WHERE camp_id = 0
        AND STATUS = 1

        SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
        FROM ccMetaWhatsAppNumbers
        WHERE Cam_Id = 0 or Cam_Id is null
        AND STATUS = 1

        INSERT INTO @AllCampaigns
        EXEC ccsp_RIAConfCamp @adminID
        ,@campID

        -- consulta para extraer las variables del script
        DECLARE @ScriptVariables NVARCHAR(MAX);
        WITH RecursiveExtraction AS (
            SELECT
                CAST(SUBSTRING(scriptAgent, CHARINDEX(''{{'', scriptAgent) + 2,
                CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) - 2) AS VARCHAR(MAX)) AS Variable,
                CAST(STUFF(scriptAgent, CHARINDEX(''{{'', scriptAgent),
                CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
            FROM dbo.ccVirtualAgent
            WHERE CHARINDEX(''{{'', scriptAgent) > 0
            AND idCampaign = @campID AND campType = 1

            UNION ALL

            SELECT
                CAST(SUBSTRING(RemainingText, CHARINDEX(''{{'', RemainingText) + 2,
                CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) - 2) AS VARCHAR(MAX)) AS Variable,
                CAST(STUFF(RemainingText, CHARINDEX(''{{'', RemainingText),
                CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
            FROM RecursiveExtraction
            WHERE CHARINDEX(''{{'', RemainingText) > 0
        )
        SELECT @ScriptVariables = STUFF((
            SELECT '', '' + Variable
            FROM RecursiveExtraction
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''');

        SELECT
        dialPrefixMan DialPrefixMan
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
        ,internationalDialingPortsAssigned internationalDialingPortsAssigned
        ,AssignConversationSameAgent AssignConversationSameAgent
        ,maxLimitQueueConversations MaxLimitQueueConversations
        ,MaxDaysPerWAConvo DaysVisualConversationWhatsApp
        ,RecordIvr
        ,ISNULL(CamCanceled, 0) CamCanceled
        ,surveyCamId SurveyCamId
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI
        ,ImmediateSurveyAI
        ,ApplyRescheduledSurveyForCompletedCallsAI
        ,EnableCallRecordingAI
        -- Manual Rotation Dialing Configurations
        ,ISNULL(rotativeAlgorithmManual, 4) RotativeAlgorithmManual
        ,idAniListManual IdAniListManual
        ,ManualCallANIMode ManualCallANIMode
        ,@ScriptVariables AS ScriptVariables
        FROM @AllCampaigns
        WHERE cam_id = @campID
    END
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]'
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
    @maxLimitQueueConversations SMALLINT = NULL,
    @maxDaysPerWAConvo SMALLINT = NULL,
    @rotativeAlgorithmManual smallint = null,
    @idAniListManual smallint = NULL,
    @selectRotationManualDialing BIT = NULL
    as
    set nocount ON

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
                    WHEN @progDial IS NOT NULL AND @progDial <> 2 and @CampType is not null THEN 0
                    WHEN CampType is not null THEN CampType ELSE 0 END),
        selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
        messagingOrder = isnull(@messagingorder, messagingOrder),
        autoStart = isnull(@autoStart,autoStart),
        recordHold = isnull(@recordHold, recordHold),
        CamCanceled = ISNULL(@camCanceled, CamCanceled),
        recordIvr = isnull(@recordIvr, recordIvr),
        rotativeAlgorithmManual = ISNULL(@rotativeAlgorithmManual, rotativeAlgorithmManual),
        idAniListManual = ISNULL(@idAniListManual, idAniListManual)
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
                                                                            WHEN @Camptype IN(4, 9, 10)  THEN 48
                                                                            WHEN @Camptype = 7  THEN 50
                                                                            ELSE 42 END
                                                                    ELSE
                                                                        CASE
                                                                            WHEN @Camptype = 6  THEN 55
                                                                            WHEN @Camptype = 5  THEN 56
                                                                            WHEN @Camptype IN(4, 9, 10)  THEN 57
                                                                            WHEN @Camptype = 7  THEN 58
                                                                            ELSE 54 END
                                                                    END;

            IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

            IF(@isCreating = 1)
            BEGIN
                DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
                DELETE FROM #ccCampsTable WHERE identifierInfo =''OUT_ANI_MODE_MANUAL'' and dataInfo NOT IN (0,1,2,3); 
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
            ELSE IF(@CampType = 9) DELETE FROM #ccCampsTable WHERE columnInfo IN (''timeZoneRule'', ''CampType'');
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

                        WHEN CCCT.identifierInfo in (''OUT_ANI_MODE'', ''OUT_ANI_MODE_MANUAL'') THEN
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
                                    CASE @rotativeAlgo
                                                WHEN 1 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                WHEN 0 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccEdoAniList WHERE id_AniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                ELSE
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                        ISNULL(
                                                            (SELECT [description] FROM ccEdoAniList WHERE id_AniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                            CCCT.dataInfo
                                                        )
                                                    )
                                    END
                        WHEN CCCT.identifierInfo = ''OUT_ANI_LIST_MANUAL'' THEN
                                CASE @rotativeAlgorithmManual
                                                WHEN 4 THEN  ''T&COMMON_NONE''
                                                WHEN 1 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                WHEN 0 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccEdoAniList WHERE id_AniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                ELSE
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                        ISNULL(
                                                            (SELECT [description] FROM ccEdoAniList WHERE id_AniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                            CCCT.dataInfo
                                                        )
                                                    )
                                    END
                        WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                        WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                    ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                    ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'',
                                                    ''OUT_SELECT_ANI_MANUAL_DIALING'') THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END

                        ELSE CCCT.dataInfo END
                ELSE '''' END,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
            FROM #ccCampsTable AS CCCT
            WHERE CCCT.identifierInfo IS NOT NULL;

            EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

    if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
    begin
        EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
    end

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
                    maxLimitQueueConversations = @maxLimitQueueConversations,
                    MaxDaysPerWAConvo = @maxDaysPerWAConvo
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
            getDate(),          (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
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
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
        @cam_id SMALLINT,
        @zipCodeSchedule BIT = NULL,
        @userId SMALLINT = NULL,
        @idArea SMALLINT = NULL,
        @isCreating SMALLINT = NULL,
        @simultaneousRecs SMALLINT = NULL,
        @module INT = -1,
        @recordCalls TINYINT = 1,
        @editableContactData BIT = 1,
        @assignConversationSameAgent BIT = 0,
        @RescheduledSurveyAI BIT = 0,
        @ImmediateSurveyAI BIT = 0,
        @ApplyRescheduledSurveyForCompletedCallsAI BIT = 0,
        @EnableCallRecordingAI BIT = 1,
        @ManualCallANIMode SMALLINT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @country INT = (SELECT valor FROM ccSettings WHERE setting_id = 104);
        DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;

        IF EXISTS (SELECT * FROM ccCampsExtend WHERE cam_id = @cam_id)
        BEGIN
            EXEC InsertLogAdminGalatea @action = 1, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable;

            CREATE TABLE #ccCampsExtendTable
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            );

            DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
            DECLARE @operation SMALLINT = CASE
                WHEN @isCreating = 1 THEN
                    CASE
                        WHEN @Camptype = 6 THEN 44
                        WHEN @Camptype = 5 THEN 46
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 48 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 50
                        ELSE 42
                    END
                ELSE
                    CASE
                        WHEN @Camptype = 6 THEN 55
                        WHEN @Camptype = 5 THEN 56
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 57 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 58
                        ELSE 54
                    END
                END;

            UPDATE ccCampsExtend
            SET
                zipCodeSchedule = ISNULL(@zipCodeSchedule, zipCodeSchedule),
                simultaneousRecs = ISNULL(@simultaneousRecs, simultaneousRecs),
                RecordCalls = ISNULL(@recordCalls, RecordCalls),
                EditableContactData = ISNULL(@editableContactData, EditableContactData),
                AssignConversationSameAgent = ISNULL(@assignConversationSameAgent, AssignConversationSameAgent),
                -- Outbound AI Campaign Special Settings
                RescheduledSurveyAI = ISNULL(@RescheduledSurveyAI, RescheduledSurveyAI),
                ImmediateSurveyAI = ISNULL(@ImmediateSurveyAI, ImmediateSurveyAI),
                ApplyRescheduledSurveyForCompletedCallsAI = ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, ApplyRescheduledSurveyForCompletedCallsAI),
                EnableCallRecordingAI = ISNULL(@EnableCallRecordingAI, EnableCallRecordingAI),
                ManualCallANIMode = ISNULL(@ManualCallANIMode, ManualCallANIMode)
            WHERE cam_id = @cam_id;

            IF (@isCreating > 0 AND @module > -1)
                EXEC InsertLogAdminGalatea @action = 2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId, @tableTemp = ''#ccCampsExtendTable'';

            IF (@idArea IS NULL OR @idArea = -1)
                SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id);

            IF (@isCreating = 1) BEGIN
                DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') AND dataInfo = 0;
                DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_ANI_MODE_MANUAL'') 
            END
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                GETDATE(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
                @operation,
                @module,
                CCCE.identifierInfo,
                CASE
                    WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                        CASE
                            WHEN CCCE.identifierInfo = ''OUT_MANUAL_CALL_ANI_MODE'' THEN
                                CASE
                                    WHEN @ManualCallANIMode = 0 THEN ''OUT_MANUAL_CALL_ANI_MODE_NONE''
                                    WHEN @ManualCallANIMode = 1 THEN ''OUT_MANUAL_CALL_ANI_MODE_SYSTEM''
                                    WHEN @ManualCallANIMode = 2 THEN ''OUT_MANUAL_CALL_ANI_MODE_AGENT''
                                    ELSE ''''
                                END
                            WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
                                CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                            WHEN @isCreating = 1 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' END
                                END
                            WHEN @isCreating = 2 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                END
                            WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
                                CASE
                                    WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
                                    WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
                                    WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
                                    ELSE ''COMMON_DISABLED''
                                END
                            ELSE CCCE.dataInfo
                        END
                    ELSE ''''
                END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
            FROM #ccCampsExtendTable AS CCCE WHERE CCCE.identifierInfo != @excludeIdentifier;

            EXEC InsertLogAdminGalatea @action = 3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable;

        END
        ELSE
        BEGIN
            INSERT INTO ccCampsExtend (
                cam_id,
                zipCodeSchedule,
                SimultaneousRecs,
                RecordCalls,
                AssignConversationSameAgent,
                RescheduledSurveyAI,
                ImmediateSurveyAI,
                ApplyRescheduledSurveyForCompletedCallsAI,
                EnableCallRecordingAI,
                ManualCallANIMode
            )
            VALUES (
                ISNULL(@cam_id, 0),
                ISNULL(@zipCodeSchedule, ''''),
                ISNULL(@simultaneousRecs, 0),
                ISNULL(@recordCalls, 0),
                ISNULL(@assignConversationSameAgent, 0),
                -- Outbound AI Campaign Special Settings
                ISNULL(@RescheduledSurveyAI, 0),
                ISNULL(@ImmediateSurveyAI, 0),
                ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, 0),
                ISNULL(@EnableCallRecordingAI, 1),
                ISNULL(@ManualCallANIMode, 0)
            );

            SET NOCOUNT OFF;
        END
        UPDATE ccCamps SET call_record = @recordCalls WHERE cam_id = @cam_id;
    END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_ManualCallGetRotativeAni]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ManualCallGetRotativeAni]
@phones VARCHAR(MAX),
@camId INT
AS
set nocount on
DECLARE @ManualCallANIMode SMALLINT

SELECT @ManualCallANIMode = ISNULL(ManualCallANIMode, 0) FROM ccCampsExtend WHERE cam_id = @camId;

IF(@ManualCallANIMode > 0) BEGIN
    DECLARE @aniId INT;
    DECLARE @rotativeAlgo INT;
    DECLARE @Anis TABLE(id INT, pid VARCHAR(2), phone VARCHAR(32), ani VARCHAR(32));

    SELECT @aniId = [idAniListManual], @rotativeAlgo = [rotativeAlgorithmManual] FROM ccCamps WHERE cam_id = @camId;

    INSERT @Anis
    EXEC ccsp_DLRGetRotativeANI @callout_id=0, @phones=@phones, @aniList=@aniId,@algo=@rotativeAlgo;

    IF(SELECT COUNT(*) FROM @Anis) > 0 BEGIN
        SELECT TOP 1 ani FROM @Anis
    END ELSE IF EXISTS (SELECT valor FROM ccSettings WHERE setting_id = 177) BEGIN
        SELECT * FROM ccSettings WHERE setting_id = 177
    END ELSE BEGIN
        SELECT ''''
    END
END
ELSE BEGIN
    SELECT ''''
END
set nocount off'
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    
    --- END  ----


    

    

    

	
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
