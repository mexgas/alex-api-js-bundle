CREATE FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
RETURNS varchar(30) AS
begin
declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint

select @ld=valor from ccSettings with(nolock) where setting_id=17
select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @BLActivo = valor from ccsettings with(nolock) where setting_id = 114

select @resultado=dbo.Completa(@Cadena, @pais, @ld)

if @BLActivo = 1 begin
	if @pais in (1,4)
		begin
		if left(@resultado, 1)='E'
			return @resultado

		select @resultado = case
			when len(@resultado)in(7,8) then @ld + @resultado
			when @resultado='911' OR len(@resultado)=10 then @resultado
			when len(@resultado) in (11,12,13) then right(@resultado,10)
			else 'E_NV_Longitud'
			end

			return @resultado
		end

	if @pais = 2 begin
		select @resultado = dbo.fnClearPhoneArg(@cadena)
		return @resultado
	end

	if @pais = 3 and left(@resultado,1) <> 'E' begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) in(8,10) then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else 'E_NV_Longitud' end
		return @resultado
	end

	if @pais = 5 and left(@resultado,1) <> 'E' begin
		select @resultado = case
			when len(@resultado) in (6,7) then @ld + @resultado
			when len(@resultado) in (8,9) then @resultado
			when len(@resultado) = 10 then right(@resultado,9)
			else 'E_NV_Longitud' end
		return @resultado
	end

	if @pais = 6 and left(@resultado,1) <> 'E' begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) = 10 then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else 'E_NV_Longitud' end
		return @resultado
	end

	if @pais = 7 and left(@resultado,1) <> 'E' begin
		select @resultado = right(@resultado,10)
		return @resultado
	end

	if @pais = 8 begin
		if left(@resultado,1) = 'E' begin
			return @resultado
		end
		select @resultado = case
			when len(@resultado) = 7 then '0' + @ld + @resultado
			when len(@resultado) = 9 and substring(@resultado,1,1) = '0' then @resultado
			when len(@resultado) = 10 and substring(@resultado,2,1) = '5' then @resultado
			when len(@resultado) = 11 and substring(@resultado,3,3) in ('111','510','511') then @resultado
			else 'E_NV_Longitud' end
		return @resultado
	end

	if @pais in(9,10,11,12,13,14,15,16) and left(@resultado,1) <> 'E' begin
		return @resultado
	end
	
end
else begin
	select @resultado = dbo.Limpia(@cadena)
end

return @resultado
end