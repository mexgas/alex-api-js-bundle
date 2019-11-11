CREATE PROCEDURE ccsp_DLRUpdateCallSetStatus
@cal_id int,
@nStatus tinyint
AS
	IF @nStatus=5 	--En Espera
	BEGIN
		Update ccoCallsOut SET cal_que=1, statusCall_id=5 --En Espera
		where cal_id=@cal_id
	END
	ELSE
	BEGIN
		Update ccoCallsOut SET statusCall_id=@nStatus
		where cal_id=@cal_id
	END