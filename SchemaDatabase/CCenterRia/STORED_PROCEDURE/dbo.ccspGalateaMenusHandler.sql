CREATE PROCEDURE ccspGalateaMenusHandler
@action tinyint,
@userID int
AS BEGIN
    IF @action = 1  -- Get GalateaMenus of an Admin
    BEGIN
				
	   DECLARE @EnableCallMonitorMenus bit,
				@EnablePositionMenus bit

	   SELECT @EnableCallMonitorMenus = valor FROM ccSettings WHERE setting_id = 68 
	   SELECT @EnablePositionMenus = valor  FROM ccSettings WHERE setting_id = 71

	   exec ccsp_RIAMenuRoles @Type=6,@User_id=@userID,@Role_id=0,@InsertMenu_id=0,@DeleteMenu_id=0,@reportRol=4,@CM=@EnableCallMonitorMenus,@AE=@EnablePositionMenus

	   RETURN(0)
    END
END