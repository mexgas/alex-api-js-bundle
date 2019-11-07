CREATE PROCEDURE ccsp_GalateaAdminSettings
AS
BEGIN
	CREATE TABLE #Settings (setting_id tinyint , valor varchar(300), ip_host tinyint)

	INSERT INTO #Settings 
	EXEC  ccsp_RIAADMLoadSettings @ip_admin =''

	INSERT INTO #Settings (setting_id,valor) 
	SELECT setting_id, valor 
	FROM ccSettings
	WHERE setting_id in(160, 199, 53)
 
	SELECT distinct setting_id, valor from #Settings ORDER BY setting_id 

	DROP TABLE #Settings;
END