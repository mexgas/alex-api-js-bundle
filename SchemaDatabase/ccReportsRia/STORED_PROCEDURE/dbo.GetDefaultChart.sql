CREATE PROCEDURE [dbo].[GetDefaultChart] @id int
AS
BEGIN
	select reportName, case chartType when 1 then 1 else 2 end as chartType,
	CONVERT(varchar(1),chartType) +'|'+
	case when chartType = 1 then x1
	when x1='' then subX1
	ELSE x1 + '|' + subX1 end as columns, countColumn, chartDescription, isTime
	from ReportsCharts
	WHERE id = @id
	order by id
END