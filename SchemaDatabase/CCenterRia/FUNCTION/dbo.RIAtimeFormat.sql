CREATE FUNCTION RIAtimeFormat (@time int)
RETURNS varchar(10)
BEGIN 
	declare @valor nvarchar(2)
	declare @temp nvarchar(2)
	
	set @temp  = cast(@time as nvarchar(2))
	if len(@temp ) = 1 
		set @valor = '0' + @temp
	else if len(@temp ) = 2
		set @valor = @temp

	return @valor
END