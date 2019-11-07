CREATE  PROCEDURE [dbo].[ccsp_DLRUpdateMachineTime]
			@CallID as int,
			@tMsg smallint = 0
			AS
			/*
			SP para guardar el tiempo que dur? reproduciendo el mensaje
			*/
			update ccocallsout set cal_tMsg = @tMsg where cal_id = @CallID