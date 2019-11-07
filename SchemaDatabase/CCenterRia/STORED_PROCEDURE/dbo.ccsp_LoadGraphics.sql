CREATE PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	DECLARE @AuthorizationPlayStopRec TABLE(value bit)
	DECLARE @realValue bit
 
	INSERT INTO @AuthorizationPlayStopRec 
	exec ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType

	select @realValue=value from @AuthorizationPlayStopRec

	if (@callType=1)
	begin		
		select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage ,
		case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
		isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
		a2.ShowCalifWnd as ShowDisposition,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording,
		isnull(a2.editableDtmf, 0) as isEditDtmf
		from ccRIAInboundGraph a1 
		inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
		 inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
		 left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id		
	 end	
	 else
	 begin
		select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
		case when msgFile <> '' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
		case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
		a2.cam_ShowCalifWnd as ShowDisposition,
		a2.callBackSurveyAgent,a2.callBackSurveyClient,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording
		from ccRIACampsGraph a1 
		inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
		inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
		left outer join (select top 1 M.cam_id, coalesce(msgFile+',','') as msgFile 
		from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
		where M.cam_id = @Id and type = 8) b 
		on (a2.cam_id = b.cam_id) 
		where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
	 end	
END