CREATE   FUNCTION [dbo].[fPorcentaje] (@num1 decimal,@num2 decimal) 
RETURNS varchar(10)
AS  
BEGIN 

	declare @porcentaje decimal
	declare @total as varchar(10)
	declare @decimal as decimal
	declare @tmp1 as decimal

	set @porcentaje = @num1 * 100.0
	set @decimal = @porcentaje % @num2
	set @tmp1 = (@porcentaje - @decimal) / @num2
	set @total = @tmp1
	set @decimal = @decimal * 100.0
	set @decimal = @decimal / @num2
    
	set @total = @total + '.' + substring(convert(varchar(10),@decimal),1,2)

	RETURN (@total)
END