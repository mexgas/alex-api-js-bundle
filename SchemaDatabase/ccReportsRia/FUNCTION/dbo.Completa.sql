CREATE function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32) 
AS  
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia
if @pais = 1 
 begin
	--Empieza Mexico
	select @resultado = case 
	 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else '01' + @resultado end
	 when len(@resultado)=12 then 
	   case when left(@resultado, 2) = '01' then
		 case when substring(@resultado, 3, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else 'E_NV_LD' end
	 when len(@resultado)=13 then
	   case when left(@resultado, 3) in ('044', '045') then
		 case when substring(@resultado, 4, len(@ld)) = @ld then
		   '044' + right(@resultado, 10) else '045' + right(@resultado, 10) 
		 end
	   else 'E_NV_Cel' end
	else 'E_NV_Longitud' end

	--Termina Mexico
	return @resultado
 end

if @pais = 2 
 begin
	-- Empieza Argentina
	select @resultado = case 
	 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then 
		@resultado
	-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
	-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
	 when len(@resultado) = 8 then
		case when len(@ld) = 4 then
			case when left(@resultado,2) = '15' then @resultado end
		else 
			case when len(@ld) = 2 then @resultado end
		end
	-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
	 when len(@resultado)=9 then
		case when left(@resultado, 2) = '15' then @resultado else 'E_NV_Cel' end
	-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
	 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
	 when len(@resultado)=10 then 
	   case when left(@resultado, len(@ld)) = @ld 
		then right(@resultado, 10 - len(@ld)) else 
			case when left(@resultado,2) = '15' then @resultado else '0' + @resultado end 
	   end
	-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
	-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
	 when len(@resultado)=11 then 
	   case when left(@resultado, 1) = '0' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else 'E_NV_LD' end
	-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
	-- si no es local se le agrega el 0 y se marca el numero
	 when len(@resultado)=12 then
		case when left(@resultado, len(@ld)) = @ld then 
			case when substring(@resultado, len(@ld) + 1, 2) = '15' then 
				right(@resultado,12 - len(@ld)) else 'E_NV_Cel' end else '0' + @resultado end
	-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
	 when len(@resultado)=13 then
		case when left(@resultado, 1) = '0' then
			case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
		else 'E_NV_Cel' end
	else 'E_NV_Longitud' end

	--Termina Argentina	
	return @resultado	
 end

if @pais = 3 
 begin
	--Empieza colombia
	select @resultado = case 
	--Si son 7 digitos, se regresa igual
	 when len(@resultado)=7 then 
		@resultado
	--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
	 when len(@resultado) = 8  then
		case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end		
	-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
	 when len(@resultado)=10 then
		case when left(@resultado,3) in ('300','301','302','303','304','305','310','311','312','313','314','315','316','317','318','319','320') then '0' + @resultado 
		else
			'E_NV_Cel' 
		end
	--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
	--prefijo de celular
	 when len(@resultado)=11 then 
		case when left(@resultado,1)='0' then
			case when substring(@resultado,2,3) in ('300','301','302','303','304','305','310','311','312','313','314','315','316','317','318','319','320') then @resultado else 'E_NV_Cel' end
		else 'E_NV_Cel' end
	else 'E_NV_Longitud' end	

	-- Termina Colombia
	return @resultado	
 end

if @pais = 4 
 begin
	--Empieza USA
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

	--Termina USA
	return @resultado
 end

if @pais = 5 
 begin
	select @resultado = case len(@resultado) 
	 when 6 then @resultado 
	 when 7 then @resultado
	-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
	 when 8 then

		case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else				
			case when left(@resultado,1) in (8,9) then '09' + @resultado else
				case when left(@resultado,1) = '6' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else '09' + @resultado end
				 else case when left(@resultado,1) = '7' then case when left(@resultado,2) in (71,72,73,75) then @resultado else '09' + @resultado end else @resultado end end	
			 end
		end
	-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
	-- de telefonia voIp se le agrega el 0 al inicio
	 when 9 then
		case when @ld = left(@resultado,2) then right(@resultado,7) else
			case when left(@resultado,2) in (41,32,65) then @resultado else 
				case when left(@resultado,2) = '44' then '0' + @resultado else 
					case when left(@resultado,1) = '9' and substring(@resultado,2,1) in (6,7,8,9) then '0' + @resultado else 'E_NV_Longitud' end
				 end
			end
		end
	 when 10 then
		case when left(@resultado,2) = '09' then @resultado else 'E_NV_Cel' end
	else 'E_NV_Longitud' end

	-- Termina Chile
	return @resultado
 end

-- Venezuela
if @pais = 6 begin
	select @resultado = case len(@resultado)
		when 7 then @resultado
		when 10 then '0' + @resultado
		when 11 then 
			case when left(@resultado,1) = '0' then @resultado else 'E_NV_Longitud' end
		else 
	    'E_NV_Longitud' end
end
--Termina Venezuela

-- UK
if @pais = 7 begin
	select @resultado = case len(@resultado)
		when 11 then
			case left(@resultado,1)
				when '0' then @resultado else 'E_NV_Longitud'
			end
		when 10 then
			case left(@resultado,1)
				when '0' then @resultado else '0' + @resultado
			end
		when 9 then
			case when left(@resultado,1) <> '0' then '0' + @resultado else 'E_NV_Longitud' end
		when 8 then
			case when substring(@resultado, 1, 2) = '08' then @resultado else 'E_NV_Longitud' end
		when 7 then
			case when left(@resultado,1) = '8' then '0' + @resultado else 'E_NV_Longitud' end
		else
		'E_NV_Longitud'
	end
end
-- Termina UK

if @pais = 8 begin -- arabia saudita
	select @resultado = case len(@resultado)
	when 7 then @resultado
	when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else '0' + @resultado end
	when 9 then case substring(@resultado, 1, 1) when '5' then '0' + @resultado 
				when '0' then case substring(@resultado, 2, 1) 
						when @ld then right(@resultado, 7) else @resultado end 
				else 'E_NV_Longitud'
				end
	when 10 then case substring(@resultado, 2, 1) when '5' then @resultado else 'E_NV_Longitud' end
	when 11 then case substring(@resultado, 2, 1) 
					when '8' then case substring(@resultado, 3, 3) 
									when '111' then @resultado else 'E_NV_Longitud' end 
					else case when substring(@resultado, 3, 3) = '510' or substring(@resultado, 3, 3) = '511' then @resultado else 'E_NV_Longitud' end
					end
	when 13 then @resultado
	else 'E_NV_Longitud' end
end -- arabia saudita

if @pais = 9 --Australia
begin
	select @resultado = case len(@resultado)
	when 8 then 
		/*case when exists (select AreaCode 
						  from SeriesAU 
						  where convert(int,LD) = convert(int,@ld) 
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
			case substring(@resultado, 1, 4) when '5550' then 'E_NV_LD' else @ld +  @resultado end
		/*else case when exists (select AreaCode 
						  from SeriesAU 
						  where convert(int,LD) = convert(int,'04') 
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
		'04' +  @resultado 
		else 'E_NV_Cel' end end*/
	when 9 then 
		case when left(@resultado,1) <> '0' then 
			case substring(@resultado, 2, 4) when '5550' then 'E_NV_LD' else '0' + @resultado end
		else 'E_NV_LD' end
	when 10 then 
		case substring(@resultado, 3, 4) when '5550' then 'E_NV_LD' else @resultado end 
	else 'E_NV_Longitud' end
end


if @pais = 10 --Brasil
begin
				
	select @resultado = case len(@resultado)
--llamada local fijo o celular	
	when 8 then @resultado 
    when 9 then @resultado 	
	when 10 then  -- Numero nacional
		case when left(@resultado, 2) = @ld 
			then right(@resultado,8) else @resultado end
	when 11 then	-- Este caso solomente es para numero celular
			case when left(@resultado, 2) = @ld
				 then right(@resultado,9) else @resultado end		
	when 12 then	-- llamadas por cobrar local
		case when (left(@resultado,4) = '9090') then right(@resultado,8) else 'E_NV_PC' end
	when 13 then 
		case when left(@resultado,4) = '9090' then right(@resultado,9) -- llamadas por cobrar local celular	
			 when left(@resultado,1) = '0' then 				
			case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
		else 'E_NV_Longitud' end
	when 14 then
			case when left(@resultado,2) = '90' then -- llamadas por cobrar larga distancia
					case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end			     
				 when left(@resultado,1) = '0'  then --llamada larga distancia a celular					
						case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end				
			else 'E_NV_Longitud' end
	when 15 then 
		case when left(@resultado,2) = '90' then -- Llamadas por cobrar a celular LD
				case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end			
			else 'E_NV_Longitud' end	

	else 'E_NV_Longitud' end

end


-- Termina
return @resultado

end