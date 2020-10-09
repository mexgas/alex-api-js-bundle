CREATE PROCEDURE [dbo].[ccsp_GalateaUserInfoManagement] @Option AS SMALLINT,  
											  @UserId AS INT = 0, 
											  @Theme AS SMALLINT = 0--[dbo].[ccsp_GalateaUserInfo] 1, 3, 1
AS
BEGIN
	set nocount on
	IF @Option = 1	 -- Update user theme
		BEGIN
			IF @UserId IS NOT NULL AND @theme IS NOT NULL
				BEGIN
					UPDATE ccusers SET theme=@Theme
					WHERE User_id = @UserId;

				END
			ELSE
				BEGIN
					raiserror('ERROR. El usuario no existe', 18, 1)
				END	
		END
END