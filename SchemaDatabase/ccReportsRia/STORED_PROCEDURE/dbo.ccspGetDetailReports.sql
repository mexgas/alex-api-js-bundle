CREATE PROCEDURE [dbo].[ccspGetDetailReports]   
 @id int, @action int = 0
AS  
BEGIN  		
	if @action = 0 begin
		select [columns],[pivotColumns] from dbo.DetailReports where id = @id  		 
	end
	if @action = 1 begin
		select [dbColumnFilter],[showColumnsDetail] from dbo.DetailReports where id = @id  	
	end
END