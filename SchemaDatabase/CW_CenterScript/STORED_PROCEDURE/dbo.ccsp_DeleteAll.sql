CREATE PROCEDURE [dbo].[ccsp_DeleteAll]
			@Template_id int,
			@UserID int = 22

			AS
			set nocount on;

			delete from labelComponent where Template_id = @Template_id
			delete from ImageComponent where Template_id = @Template_id
			delete from Components_per_Template where Template_id = @Template_id
			delete from componentsRelation where Template_id = @Template_id
			
			EXEC ccsp_Logger @action = 2
			,@action_id = 4
			,@template_id = @Template_id
			,@user_id = @UserID