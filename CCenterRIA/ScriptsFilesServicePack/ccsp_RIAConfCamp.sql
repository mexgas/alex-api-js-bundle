/*==============================================================
 KM28002 - Validación de marcación por código postal
==============================================================*/

IF EXISTS (
    SELECT 1
    FROM sys.procedures
    WHERE name = 'ccsp_RIAConfCamp'
)
BEGIN
    DROP PROCEDURE dbo.ccsp_RIAConfCamp;
END
GO

CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
    @User_id SMALLINT,
    @campID INT = NULL
AS
BEGIN

SET NOCOUNT ON;

DECLARE @tableExistsRec TABLE (
    camId INT PRIMARY KEY,
    existRec BIT
);

DECLARE @camByUser TABLE (
    camId INT PRIMARY KEY,
    isCheck BIT
);

DECLARE @camId INT;
DECLARE @intenationalDialingPorts BIT;

IF (
    SELECT COUNT(*)
    FROM (
        SELECT TOP 1 IdCode
        FROM ccoDialers ccoDial
        INNER JOIN ccoDialerCamp ccoDialCamp
            ON ccoDialCamp.dialer_id = ccoDial.dialer_id
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
    SELECT 1
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
    SELECT 1
    FROM @camByUser
    WHERE isCheck = 0
)
BEGIN

    SELECT TOP 1 @camId = camId
    FROM @camByUser
    WHERE isCheck = 0;

    IF EXISTS (
        SELECT 1
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
    END AS isRelationSurvey,

    ISNULL(a1.funcEspDtmf, 0) AS funcEspDtmf,
    ISNULL(sipHdrFormat, '') AS sipHdrFormat,

    cam_inter_cancelled,
    prefijo,

    CASE
        WHEN existRec = 0 THEN 1
        ELSE 0
    END AS enbleprefix,

    ISNULL(exitAssisted, 0) AS exitAssisted,
    ISNULL(previewDiscard, 0) AS PreviewDiscard,

    CASE
        WHEN CampType = 9 THEN 10
        ELSE ISNULL(CampType, 0)
    END AS CampType,

    ISNULL(contact.conexionInfo, '') AS conexionInfo,
    ISNULL(contact.connUser, '') AS connUser,
    ISNULL(contact.closeConversationTime, 0) AS closeConversationTime,
    ISNULL(contact.answerTimeoutClient, 0) AS answerTimeoutClient,
    ISNULL(contact.allowFileAttachments, 0) AS allowFileAttachments,

    ISNULL(selectRotativeANI, 0) AS selectRotativeANI,
    ISNULL(rotativeAlgo, 0) AS rotativeAlgo,
    ISNULL(autoStart, 0) AS autoStart,
    ISNULL(messagingOrder, 0) AS messagingOrder,

    ISNULL(cam_tPreview, 0) AS CamTPreview,
    ISNULL(timesPreview, 0) AS TimesPreview,
    ISNULL(timesDiscard, 0) AS TimesDiscard,
    ISNULL(recordHold, 0) AS recordHold,

    /* ============================================
       Campo real existente en BD
    ============================================ */
    ISNULL(campsExtention.zipCodeSchedule, 1) AS ZipCodeSchedule,

    ISNULL(campsExtention.RecordCalls, 1) AS RecordCalls,
    ISNULL(campsExtention.simultaneousRecs, 1) AS simultaneousRecs,
    ISNULL(campsExtention.EditableContactData, 0) AS EditableContactData,

    @intenationalDialingPorts AS intenationalDialingPorts,

    ISNULL(campsExtention.AssignConversationSameAgent, 0) AS AssignConversationSameAgent,

    ISNULL(contact.maxLimitQueueConversations, 99) AS maxLimitQueueConversations,
    ISNULL(contact.MaxDaysPerWAConvo, 5) AS MaxDaysPerWAConvo,

    ISNULL(recordIvr, 1) AS recordIvr,
    ISNULL(CamCanceled, 4) AS CamCanceled,
    ISNULL(surveyCamId, 0) AS surveyCamId,

    -- Outbound AI Campaign Special Settings
    ISNULL(campsExtention.RescheduledSurveyAI, 0) AS RescheduledSurveyAI,
    ISNULL(campsExtention.ImmediateSurveyAI, 0) AS ImmediateSurveyAI,
    ISNULL(campsExtention.ApplyRescheduledSurveyForCompletedCallsAI, 0) AS ApplyRescheduledSurveyForCompletedCallsAI,
    ISNULL(campsExtention.EnableCallRecordingAI, 0) AS EnableCallRecordingAI,

    -- Manual Rotation Dialing Configurations
    ISNULL(a1.rotativeAlgorithmManual, 4) AS RotativeAlgorithmManual,
    ISNULL(a1.idAniListManual, 0) AS IdAniListManual,
    ISNULL(a1.selectRotationManualDialing, 0) AS SelectRotationManualDialing,

    /* ============================================
       FIX KM28002
       Exponer correctamente el valor esperado
       por backend/UI usando la columna REAL.
    ============================================ */
    CASE
        WHEN campsExtention.cam_id IS NULL THEN 1
        ELSE ISNULL(campsExtention.zipCodeSchedule, 1)
    END AS ManualCallTimeZoneValidation

FROM ccCamps a1

INNER JOIN ccRIACampsGraph a2
    ON a1.cam_id = a2.cam_id

INNER JOIN ccRIAGraphics a3
    ON a2.graphic_id = a3.graphic_id

INNER JOIN @tableExistsRec a4
    ON a1.cam_id = a4.camId

LEFT JOIN contactMeanOut contact
    ON a1.cam_id = contact.camp_id

LEFT JOIN ccCampsExtend campsExtention
    ON a1.cam_id = campsExtention.cam_id

ORDER BY cam_descripcion;

SET NOCOUNT OFF;

RETURN (0);

END
GO