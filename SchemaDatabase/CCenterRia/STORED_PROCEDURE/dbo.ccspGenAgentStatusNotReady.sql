CREATE PROCEDURE ccspGenAgentStatusNotReady
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS

DELETE ccGenAgentNotReady WHERE timegroup >= @from AND timegroup < @to


INSERT INTO ccGenAgentNotReady (timegroup, [user_id], tiponotready_id, amount, [time], amountReal)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + ':00', 121) AS timegroup
	, [user_id], tiponotready_id
	, COUNT(tStatus), SUM(tStatus)
	, sum( case when separado in (0,3) then 1 else null end ) --amount Real
 FROM ccLogAgentesNotReady
 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + ':00', 121), [user_id], tiponotready_id