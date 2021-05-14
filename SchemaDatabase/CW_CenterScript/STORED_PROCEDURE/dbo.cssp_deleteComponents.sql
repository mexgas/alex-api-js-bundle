CREATE PROCEDURE [dbo].[cssp_deleteComponents]
			    @Template_id int,
				@i varchar(255),
				@Component_id int,
				@UserID int = 22
			AS
			set nocount on;

			if(@Component_id=1) -- Label
			begin
				delete from labelComponent where Template_id = @Template_id and i = @i
			end
			ELSE IF(@Component_id=2)
			begin
				delete from ImageComponent where Template_id= @Template_id and i =@i
			END
			else 
				if exists(select * from componentsRelation where i=@i and Template_id = @Template_id)
					delete from componentsRelation where Template_id= @Template_id and i =@i
				else
					delete from Components_per_Template where Template_id= @Template_id and i =@i
			

			
	EXEC ccsp_Logger @action = 2
		,@action_id = 4
		,@template_id = @Template_id
		,@user_id = @UserID