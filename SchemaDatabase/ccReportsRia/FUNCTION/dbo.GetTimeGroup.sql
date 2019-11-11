CREATE FUNCTION [dbo].[GetTimeGroup] ( @date datetime,@isTimeGroupNext bit)  
RETURNS datetime
AS  
BEGIN 
	declare @timeGroup datetime
		select @timeGroup =case when datepart(mi,@date) between 0 and 14 then convert(varchar(13),@date,121) + ':00:00.000'
	when datepart(mi,@date) between 15 and 29 then convert(varchar(13),@date,121) + ':15:00.000' 
	when datepart(mi,@date) between 30 and 44 then convert(varchar(13),@date,121) + ':30:00.000' 
	else convert(varchar(13),@date,121) + ':45:00.000'  end

	if @isTimeGroupNext=1 begin
		set @timeGroup=DATEADD(mi,15,@timeGroup)
	end

	RETURN (@timeGroup)
END