CREATE PROCEDURE ccspGenOutCamp
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCamp WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCamp (timegroup, cam_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccCampsAgente.cam_id
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct user_id, cam_id, prioridad, skill from ccCampsAgente) as ccCampsAgente
	ON (ccGenAgent.[user_id] = ccCampsAgente.[user_id])
WHERE timegroup >= @from AND timegroup < @to
GROUP BY timegroup, ccCampsAgente.cam_id

return(0)
set nocount off