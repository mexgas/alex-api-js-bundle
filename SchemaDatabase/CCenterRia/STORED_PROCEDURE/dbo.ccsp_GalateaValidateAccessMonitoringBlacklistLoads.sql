CREATE PROCEDURE ccsp_GalateaValidateAccessMonitoringBlacklistLoads 
@userID smallint 
AS

if exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
	SELECT 200 AS Result
ELSE
	SELECT -1 AS Result