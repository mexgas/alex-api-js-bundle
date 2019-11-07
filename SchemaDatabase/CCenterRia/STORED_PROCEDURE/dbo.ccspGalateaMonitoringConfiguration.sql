CREATE PROCEDURE ccspGalateaMonitoringConfiguration
@userId smallint,
@viewAgents int
AS
BEGIN
	UPDATE ccusers
	SET viewAgents = @viewAgents
	WHERE user_id = @userId
END