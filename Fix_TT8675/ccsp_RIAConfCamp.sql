--Cliente
USE [CCenterRIA]
GO

/****** Object:  StoredProcedure [dbo].[ccsp_RIAConfCamp]    Script Date: 25/03/2024 16:53:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT,
	@campID INT = NULL
AS
SET NOCOUNT ON

DECLARE @tableExistsRec TABLE (
	camId INT PRIMARY KEY,
	existRec BIT
	)
DECLARE @camByUser TABLE (
	camId INT PRIMARY KEY,
	isCheck BIT
	)
DECLARE @camId INT,
	@id INT;

IF NOT EXISTS (
		SELECT *
		FROM ccUsers_Roles
		WHERE User_id = @User_id
			AND Rol_id = 7
		)
BEGIN
	INSERT INTO @camByUser
	SELECT *,
		0
	FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
	WHERE @campID IS NULL
		OR cam_id = @campID
END
ELSE
BEGIN
	INSERT INTO @camByUser
	SELECT cam_id,
		0
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
			@camId,
			1
			)
	END
	ELSE
	BEGIN
		INSERT INTO @tableExistsRec
		VALUES (
			@camId,
			0
			)
	END

	UPDATE @camByUser
	SET isCheck = 1
	WHERE camId = @camId
END

SELECT a1.cam_id,
	cam_Descripcion,
	cam_tNotas,
	cast(cam_ocupado AS INT) AS cam_ocupado,
	cam_noInt_ocupado,
	cam_inter_ocupado,
	cast(cam_nocontesto AS INT) AS cam_nocontesto,
	cam_noInt_nocontesto,
	cam_inter_nocontesto,
	cast(cam_fax AS INT) AS cam_fax,
	cam_noInt_fax,
	cam_inter_fax,
	cast(cam_modomanual AS INT) AS cam_modomanual,
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
	cast(progDial AS TINYINT) progDial,
	cast(excCallBack AS TINYINT) excCallBack,
	dialOrder,
	dialPrefix,
	dialPrefixMan,
	dialPrefixXfe,
	listenManualCall,
	stopRecording,
	cast(abandonCallback AS TINYINT) abandonCallback,
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
	isnull(a1.call_record, 1) AS call_record,
	cast(startStopRecording AS TINYINT) startStopRecording,
	leaveRecMessage,
	manualCallOnChat,
	callBackSurveyAgent,
	callBackSurveyClient,
	CASE WHEN surveycamid IS NULL
			OR surveycamid = 0 THEN 0 ELSE 1 END isRelationSurvey,
	isnull(a1.funcEspDtmf, 0),
	isnull(sipHdrFormat, '') sipHdrFormat,
	cam_inter_cancelled,
	prefijo,
	enbleprefix = CASE WHEN existRec = 0 THEN 1 ELSE 0 END,
	isnull(exitAssisted, 0) exitAssisted,
	isnull(previewDiscard, 0) PreviewDiscard,
	isnull(CampType, 0) CampType,
	isnull(contact.conexionInfo, '') conexionInfo,
	isnull(contact.connUser, '') connUser,
	isnull(contact.closeConversationTime, 0) closeConversationTime,
	isnull(contact.answerTimeoutClient, 0) answerTimeoutClient,
	isnull(contact.allowFileAttachments, 0) allowFileAttachments,
	ISNULL(rotativeAlgo, 0) rotativeAlgo,
	ISNULL(cam_tPreview, 0) AS CamTPreview,
	ISNULL(timesPreview, 0) AS TimesPreview
FROM ccCamps a1
INNER JOIN ccRIACampsGraph a2
	ON (a1.cam_id = a2.cam_id)
INNER JOIN ccRIAGraphics a3
	ON (a2.graphic_id = a3.graphic_id)
INNER JOIN @tableExistsRec a4
	ON a1.cam_id = a4.camId
LEFT JOIN contactMeanOut contact
	ON a1.cam_id = contact.camp_id
ORDER BY cam_descripcion

RETURN (0)

SET NOCOUNT OFF
