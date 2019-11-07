CREATE PROCEDURE ccspGenInCalif
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @tresDialog AS smallint
EXEC @tresDialog = ccspConfigTresDialog

-- Delete previous data in case of reprocess HLAS

DELETE ccGenInCalif WHERE timegroup >= @from AND timegroup < @to


INSERT INTO ccGenInCalif (timegroup, inbound_id, [user_id], calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup
	, inbound_id, [user_id], calif_id
	, COUNT(cal_inicio)
 FROM ccCallsIN
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 --and cal_tdialog > @tresDialog
AND INBOUND_ID > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121), inbound_id, [user_id], calif_id