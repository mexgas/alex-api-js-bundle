CREATE function [dbo].[GetProveedor](@tel varchar(32), @pto int, @tipocall int)
RETURNS int 
AS  
BEGIN
declare @resultado int

select @resultado = d.provedor_id
from cstoTarifa t WITH(NOLOCK)
inner join ccoDialers d WITH(NOLOCK) on d.provedor_id = t.provedor_id
where t.tipollamada_id = @tipocall
and d.puerto = @pto


-- Termina
return @resultado

end