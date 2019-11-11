CREATE PROCEDURE [dbo].[SaveUserTemplate] @userId int, @reportName nvarchar(50), @parameters nvarchar(MAX)
AS
BEGIN
	DECLARE @id int  

	if exists (select * from FavoriteTemplates where userid = @userId)
		begin
			select @id = max(id) + 1 
			from FavoriteTemplates 
			where userid = @userId
		end
	else
		begin
			select @id = 1
		end
	
    INSERT INTO dbo.FavoriteTemplates
    VALUES(@id,@userId,replace(@parameters,',','|'),@reportName,getdate()) 
    
END