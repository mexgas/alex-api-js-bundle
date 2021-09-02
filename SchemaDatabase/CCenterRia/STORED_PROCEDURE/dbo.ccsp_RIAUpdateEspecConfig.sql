CREATE PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] @inbound_id              SMALLINT, 
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
                                                  @addDataCallBackReminder BIT          = NULL
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
                           WHEN ISNULL(@tel_noct, 0) = '0'
                                OR @tel_noct = ''
                           THEN '0'
                           ELSE '1'
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
           addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder)
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
               AND chatDomain <> ''
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
                   chatDomain = ''
             WHERE inbound_id = @inbound_id;
             RAISERROR('Domain already in another ACD Group', 15, 4);
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
     SET NOCOUNT OFF;