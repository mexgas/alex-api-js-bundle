CREATE PROCEDURE [dbo].[ccsp_OUTCancelDialJOB]
@callout_id int,
@IsAnswer tinyint,
@nOcupado tinyint,
@nNoContesta tinyint,
@nFax tinyint,
@nContestadora tinyint,
@nShortCall tinyint,
@nOtro  tinyint,
@ExisteWT   tinyint=1
AS

declare @RecicleSIC tinyint

SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60

	-- En workingtable
	if ( @ExisteWT > 0 )
	begin
		if (@IsAnswer = 1 )
		begin

			UPDATE ccoWorkingTable set cal_fechaDial=dateadd( hh, 1, getdate() ), cal_status=1, nOcupado=1, nNoContesta=1, nShortCall=nShortCall +1
			WHERE callout_id = @callout_id
		end
		else
		begin
			
			if (@RecicleSIC = 0)
			begin
				DELETE ccoWorkingTable WHERE callout_id = @callout_id
			end
		end
	end