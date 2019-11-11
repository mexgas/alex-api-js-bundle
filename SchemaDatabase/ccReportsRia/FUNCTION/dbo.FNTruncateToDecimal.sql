Create FUNCTION [dbo].[FNTruncateToDecimal] (@Valor float)
RETURNS  float
AS
begin
Declare @NumConverted as float;
set @NumConverted=(cast((cast(@Valor*100 as int)/100.00)/3600.00 as decimal(18,2)))
	return @NumConverted
END