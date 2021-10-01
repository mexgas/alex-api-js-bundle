CREATE PROCEDURE [dbo].[ccsp_AgentGetAssistedPermission]
		@age_id int,
		@cam_id int
		AS
		BEGIN
			SET NOCOUNT ON;

			select isnull(exitAssisted,0) Allowed from ccCamps (nolock) where cam_id = @cam_id
		END