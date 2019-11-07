CREATE  FUNCTION [dbo].[fPercentage] (@num1 int, @num2 int)
RETURNS decimal(10,2)
AS
BEGIN

	declare @porcentaje decimal(10,2)

	set @porcentaje = isnull(((@num1*1.00)/nullif((@num2*1.00),0))*100.00,0)

	RETURN (@porcentaje)
END