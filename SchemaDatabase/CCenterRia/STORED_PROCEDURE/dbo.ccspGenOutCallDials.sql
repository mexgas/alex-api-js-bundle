CREATE PROCEDURE ccspGenOutCallDials
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS

DELETE ccGenOutCallDials WHERE timegroup >= @from AND timegroup < @to


INSERT INTO ccGenOutCallDials (timegroup, cam_id, [puerto], tiporesdial_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + ':00', 121) AS timegroup
	, cam_id, puerto, tiporesdial_id
	, COUNT(*)
 FROM ccologdials
 WHERE fecha >= @from AND  fecha < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + ':00', 121), cam_id, [puerto], tiporesdial_id