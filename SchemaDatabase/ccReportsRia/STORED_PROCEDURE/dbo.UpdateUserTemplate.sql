CREATE PROCEDURE [dbo].[UpdateUserTemplate] @userId int, @reportName nvarchar(50), @newReportName nvarchar(50), @parameters nvarchar(MAX)
AS
BEGIN
    UPDATE dbo.FavoriteTemplates
    SET reportName = @newReportName,
    parameters = replace(@parameters,',','|'),
    date = getdate()
    WHERE userId = @userId 
    AND reportName = @reportName
END