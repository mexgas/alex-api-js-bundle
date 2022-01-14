CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
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
	@addDataCallBackReminder bit		= null
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
		bnocturno = CASE WHEN ISNULL(@tel_noct, 0) = '0' OR @tel_noct = '' THEN '0' ELSE '1' END,
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
		addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder)
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
END