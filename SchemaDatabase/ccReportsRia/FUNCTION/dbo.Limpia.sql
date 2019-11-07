CREATE FUNCTION [dbo].[Limpia](@Cadena varchar(32))
RETURNS varchar(32) AS  
BEGIN
if datalength(@Cadena) > 1 begin
	return dbo.Limpia(left(@Cadena, 1)) + dbo.Limpia(substring(@Cadena, 2, 255))
end else begin
	return case when CHARINDEX(@Cadena, '1234567890') > 0 then @Cadena else '' end
end
return ''
end