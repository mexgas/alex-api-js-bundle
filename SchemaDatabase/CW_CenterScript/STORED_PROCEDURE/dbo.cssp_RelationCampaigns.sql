CREATE PROCEDURE [dbo].[cssp_RelationCampaigns]
				@Campaign int,
				@Template_id int
			AS
			set nocount on;

			begin
			if exists(select * from Campaign where Template_id = @Template_id)
			begin
			Update Campaign
			Set cam_id = @Campaign where Template_id = @Template_id
			end
			else
			begin
			insert Campaign (Cam_id,Template_id)
			values(@Campaign,@Template_id)
			end
			end