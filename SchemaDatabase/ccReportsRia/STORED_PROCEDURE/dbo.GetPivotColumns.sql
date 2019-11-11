CREATE PROCEDURE [dbo].[GetPivotColumns]
@id int
AS
BEGIN
SELECT [columns],complementColumns,pivotFunction,isGroupPivot
FROM dbo.PivotReports
WHERE id = @id
END