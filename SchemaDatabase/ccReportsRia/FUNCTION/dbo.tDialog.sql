CREATE FUNCTION [dbo].[tDialog](
		@totalCall_Time int,
		@tdialing int, 
		@cal_tMsg int)
RETURNS INT 
AS
BEGIN
		DECLARE @totalDialog INT
		IF ((COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) % 60) <> 0 )
		BEGIN
			SET @totalDialog=COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) + (60 -(COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) % 60)) 
			RETURN @totalDialog
		END
		ELSE
			SET @totalDialog = 60 + COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing)
			RETURN @totalDialog

END