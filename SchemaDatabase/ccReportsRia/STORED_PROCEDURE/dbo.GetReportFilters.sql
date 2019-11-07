CREATE PROCEDURE [dbo].[GetReportFilters] @id nvarchar(100), @action tinyint = 0 -- 0 Filter select; 1 Filters Range 
AS
BEGIN
	if @action = 0 begin
		SELECT Filters.[type],Filters.xmlParentNode,Filters.xmlChildNode
		FROM Filters, ReportsFilters 
		WHERE Filters.name = ReportsFilters.filterName 
		AND ReportsFilters.id = @id
	end
	if @action = 1 begin
		SELECT Filters.[type], Filters.xmlParentNode, Filters.xmlChildNode
		FROM Filters, ReportsFiltersRange 
		WHERE Filters.name = ReportsFiltersRange.filterName 
		AND ReportsFiltersRange.id = @id
	end
	if @action = 2 begin
		SELECT restrictExp, dbColumn
		FROM ReportsFiltersText 
		WHERE id = @id
	end
END