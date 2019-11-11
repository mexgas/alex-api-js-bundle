CREATE PROCEDURE [dbo].[DeleteUserTemplate] @reportName nvarchar(50), @userId int
AS
BEGIN
	DECLARE @id int

	select @id = id 
	from FavoriteTemplates
	WHERE userId = @userId 
	AND reportName = @reportName

	DELETE FROM dbo.FavoriteTemplates
	WHERE userId = @userId 
	AND reportName = @reportName

	update FavoriteTemplates
	set id = id - 1
	where userId = @userId
	and id > @id
END