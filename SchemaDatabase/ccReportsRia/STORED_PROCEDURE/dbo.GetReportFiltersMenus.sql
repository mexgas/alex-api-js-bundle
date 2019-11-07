CREATE PROCEDURE [dbo].[GetReportFiltersMenus]
	@id int
AS
BEGIN
	SELECT id,name
	FROM dbo.FiltersMenus as f, dbo.ReportsFiltersMenus fm
	WHERE f.name = fm.filterMenuName
	AND fm.idReport = @id
	order by id
END