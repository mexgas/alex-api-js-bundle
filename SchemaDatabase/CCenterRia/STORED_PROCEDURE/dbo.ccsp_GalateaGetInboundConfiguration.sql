CREATE PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
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
        isnull(A.callerIdDesc, '') [CallerIdDesc],
        isnull(A.startStopRecording,0) [StartStopRecording],
        case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
        case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
        case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
        isnull(A.editableDtmf,0) [EditableDtmf],
        isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder]
        from ccInbound A
        left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
        left join ccCamps C on C.cam_id=A.cam_id
        where A.Inbound_id=@inboundId
      end
      if @command=2 -- WhatsApp campaign
      begin
        declare @numbers varchar(max)
        select @numbers=COALESCE(@numbers + ',', '') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

        select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
        ISNULL(c.conexionInfo,'') [Number],
        ISNULL(@numbers,'') [FreeNumbersStr],
        ISNULL(c.closeConversationTime, 0) [MaxAnswerTime],
        ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
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
      RETURN(0)
        
      SET NOCOUNT OFF;    
      END