CREATE PROCEDURE [dbo].[ccspGetGroupByColumns]   
 @id int   
AS  
BEGIN  
 SELECT [columns],[groupByColumns]
    FROM dbo.GroupByReports   
    WHERE id = @id  
END