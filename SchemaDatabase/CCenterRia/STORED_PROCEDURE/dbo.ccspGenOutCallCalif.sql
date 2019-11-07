CREATE PROCEDURE ccspGenOutCallCalif
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @tresDialog AS smallint
EXEC @tresDialog = ccspConfigTresDialog

-- Delete previous data in case of reprocess HLAS

DELETE ccGenOutCallCalif WHERE timegroup >= @from AND timegroup < @to



INSERT INTO ccGenOutCallCalif (timegroup, cam_id, [user_id], calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup
	, cam_id, [user_id], calif_id
	, COUNT(*)
 FROM ccoCallsOut
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 -- and cal_tdialog > @tresDialog
--AND cam_id > 0

 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121), cam_id, [user_id], calif_id