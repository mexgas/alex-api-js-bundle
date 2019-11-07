CREATE FUNCTION [dbo].[hashList] (@calKey varchar(255)) 
RETURNS bigint AS
BEGIN
declare @codigo varchar(max)
declare @hash bigint

set @codigo=''
set @hash=0
declare @i int,@len int
select @i=1,@len=len(@calKey)
while @i<=@len begin
	select @codigo=@codigo+convert(varchar(max), ASCII(SUBSTRING(@calKey,@i,1)))
	
	if @i%5=0 begin
		set @hash=@hash+cast(@codigo as bigint)
		set @codigo=''
	end	
	set @i=@i+1
end
if @codigo<>''
set @hash=@hash+cast(@codigo as bigint)
return @hash % 99999999999973
END