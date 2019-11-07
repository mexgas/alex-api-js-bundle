CREATE PROCEDURE ccspGenInSpec
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
-- Delete previous data in case of reprocess HLAS
DELETE ccGenInSpec WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccInboundAgentes.inbound_id
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct User_id, Inbound_id, cli_id, prioridad, skill from ccInboundAgentes)as ccInboundAgentes 
	ON (ccGenAgent.[user_id] = ccInboundAgentes.[user_id])
WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
GROUP BY timegroup, ccInboundAgentes.inbound_id
return(0)
set nocount off