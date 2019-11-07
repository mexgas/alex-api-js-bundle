CREATE PROCEDURE ccsp_DLRUpdateCallEnd
@callout_id int,
@cal_id int,
@cal_colgada tinyint,
@nTryingContact tinyint,
@logDial_id int=0,
@tBusy smallint=0
AS

declare @RecicleSIC tinyint

SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60


	Update ccoWorkingTable set nTryingContact = @nTryingContact where callout_id = @callout_id
	if ( @nTryingContact > 2 ) and (@RecicleSIC = 0)
	begin
		Delete ccoWorkingTable Where callout_id = @callout_id		
	end 
	if ( @cal_id > 0 )
	begin
		Update ccoCallsOut SET cal_colgada=@cal_colgada
		where cal_id=@cal_id
	end

	--if (@logDial_id>0 and @tBusy>0)
	--Update ccoLogDials Set tBusy = @tBusy where logDial_id=@logDial_id