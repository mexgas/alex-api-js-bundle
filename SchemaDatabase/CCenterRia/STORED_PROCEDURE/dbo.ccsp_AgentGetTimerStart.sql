CREATE PROCEDURE ccsp_AgentGetTimerStart
@InOut bit, --0 in, 1 out
@cam_id integer
AS
IF @InOut =0
	select StartTimerOnHangUp from ccInbound where Inbound_id=@cam_id
ELSE
	select cam_StartTimerOnHangUp from ccCamps where cam_id=@cam_id