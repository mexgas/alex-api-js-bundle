CREATE function [dbo].[xmlAppend] (@xml xml, @add varchar(max), @betweenNode varchar(255)) -- Si se agrega se metera la cadena en el nodo
returns xml
as
begin
declare @xml1 varchar(max), @indx int
set @xml1 = cast(@xml as varchar(max))

if @xml is null
 begin
	return @xml
 end

else if @betweenNode is null
 begin 
	return cast(isnull(@xml1,'')+ isnull(@add, '') as xml)
 end

else if @add is null
 begin
	return @xml
 end

else
 begin
	set @indx = charindex(@betweenNode, @xml1, 1)
	select @xml1 = replace(@xml1, @betweenNode, '')
	select @xml1=substring(@xml1, 1, @indx-1) + 
		replace(@betweenNode, '/', '') + @add + replace(replace(@betweenNode, '/', ''), '<', '</') + 
		substring(@xml1, @indx, len(@xml1))

	set @xml = cast(@xml1 as xml)
 end
 
return @xml
end