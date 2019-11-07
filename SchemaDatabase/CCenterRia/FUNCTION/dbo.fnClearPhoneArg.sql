CREATE function [dbo].[fnClearPhoneArg](@tel varchar(32))
RETURNS varchar(32) 
AS  
BEGIN

declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

declare @telTemp varchar(15)

set @telTemp = @tel
select @tel = dbo.Completa(@tel, @pais, @ld)
select @tel = dbo.Verifica(@tel)

if left(@tel,1) = 'E' begin return @telTemp end

if len(@tel) in (6,7,8,9,10) begin
	if left(@tel,2) = '15' begin set @tel = @ld + right(@tel,len(@tel) - 2) end 
	else begin set @tel = @ld + @tel end
end

if len(@tel) = 11 begin set @tel = right(@tel,10) end

if len(@tel) = 13 begin
	declare @index as int
	select @index = charindex('15',@tel)		
	--El unico caso en el que la lada tiene un 15 es con lada 3715
	if substring(@tel,@index-2,4) = '3715'
		begin
			select @ld = '3715'
			set @tel = @ld + right(@tel,6)
		end
	else
		begin						
			select @ld = substring(@tel,2,@index-2)				
			set @tel = @ld + right(@tel,13 - (@index + 1))
		end
end

if len(@tel) <> 10 begin
	set @tel = @telTemp
end

return @tel

end