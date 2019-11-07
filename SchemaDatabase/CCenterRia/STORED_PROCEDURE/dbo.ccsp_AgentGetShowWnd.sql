CREATE PROCEDURE ccsp_AgentGetShowWnd 
@InOut bit, --0 in, 1 out
@cam_id integer
AS
IF @InOut =0
	select ShowCalifWnd from ccInbound where Inbound_id=@cam_id
ELSE
	select cam_ShowCalifWnd from ccCamps where cam_id=@cam_id