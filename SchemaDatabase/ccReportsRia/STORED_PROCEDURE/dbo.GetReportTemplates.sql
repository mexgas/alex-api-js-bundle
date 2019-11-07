CREATE PROCEDURE [dbo].[GetReportTemplates] @userId int 
AS
BEGIN
	select id, parameters, reportName, CONVERT(VARCHAR(8),date,108) AS date
	from ccTemplates
	where user_id = @userId
	order by date desc
END