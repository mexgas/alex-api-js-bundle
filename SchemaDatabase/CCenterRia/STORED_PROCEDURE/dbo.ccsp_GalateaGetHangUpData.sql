CREATE PROCEDURE [dbo].[ccsp_GalateaGetHangUpData]
	@cam_id int,
	@type int
AS BEGIN
	IF(@type = 1)
	BEGIN
		SELECT   0 leaveRecMessage,
				CASE WHEN isnull(c.callsBySurvey,0) > 0 THEN 1 ELSE 0 END isRelationSurvey,
				isnull(i.callBackSurveyAgent,1) callBackSurveyAgent,
				isnull(i.callBackSurveyClient,1) callBackSurveyClient,
				I.ShowCalifWnd showDisposition
       FROM ccInbound i
       LEFT JOIN ccCamps c on c.cam_id=i.cam_id
       WHERE i.inbound_id=@cam_id

	END
	ELSE
	BEGIN 
		SELECT
			   CASE WHEN msgFile <> '' and leaveRecMessage = 1 THEN 1 ELSE 0 END leaveRecMessage,
			   CASE WHEN isnull(c.surveyCamId,0) >0 THEN 1 ELSE 0 END isRelationSurvey,
			   c.callBackSurveyAgent,c.callBackSurveyClient, c.cam_ShowCalifWnd showDisposition
		FROM ccCamps c
		LEFT OUTER JOIN (SELECT TOP 1 M.cam_id, coalesce(T.msgFile+',','')  msgFile
						 FROM ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
						 WHERE M.cam_id =@cam_id and type = 8) b
		on (c.cam_id = b.cam_id)
		where c.cam_id=@cam_id
	END
END