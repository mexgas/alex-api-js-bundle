CREATE PROCEDURE ccsp_DLRUpdateLogDial
@logDial_id int=0,
@tLineBusy smallint=0,
@cal_id int=0,
@tDialogDialer smallint=0
AS
	if ( @logDial_id>0 and @tLineBusy>0)
		Update ccoLogDials Set tBusy = @tLineBusy where logDial_id=@logDial_id


	if ( @cal_id>0 )
		Update ccoCallsOut Set cal_tDialogDialer=@tDialogDialer, cal_tLineBusy = @tLineBusy where cal_id=@cal_id