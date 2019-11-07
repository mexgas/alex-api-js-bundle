CREATE PROCEDURE [dbo].[GetUserTemplates] @userId int 	
AS
BEGIN   
	SELECT id,parameters,reportName,date
	FROM dbo.FavoriteTemplates 
	WHERE userId = @userId 
	order by date desc
END