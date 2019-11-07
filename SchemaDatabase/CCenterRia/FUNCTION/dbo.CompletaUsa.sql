CREATE FUNCTION [dbo].[CompletaUsa](@Cadena varchar(32))
RETURNS varchar(32) AS  
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)

select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

-- Para locales a 7 digitos y ld a 11
select @resultado = case len(@resultado)
 when 3 then
	case @resultado when '911' then @resultado else 'E_NV_Longitud' end
 when 7 then @resultado
 when 10 then 
   case when left(@resultado, len(@ld)) = @ld 
    then right(@resultado, 10 - len(@ld)) else '1' + @resultado end
 when 11 then 
   case when left(@resultado, 1) = '1' then
     case when substring(@resultado, 2, len(@ld)) = @ld
       then right(@resultado, 10 - len(@ld)) else @resultado end
    else 'E_NV_LD' end
else 'E_NV_Longitud' end
return @resultado
end