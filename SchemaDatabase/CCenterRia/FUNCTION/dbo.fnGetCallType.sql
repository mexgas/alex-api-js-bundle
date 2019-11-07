CREATE function [dbo].[fnGetCallType](@tel varchar(32))
		RETURNS tinyint
		AS
		BEGIN
				
			declare @ladatemp smallint, @ldlocal smallint, @serie smallint, @numeracion smallint, @lenght tinyint, @tipo tinyint
			declare @mod varchar(10)

			set @lenght = LEN(@tel)

			select top 1 @tipo=tipollamada_id from cstoTipoLlamada nolock where country_id=1 and tipoLlamada_id in (5,6,7) and (longitud=@lenght or longitud=0) and @tel like prefijo order by tipollamada_id

			if @tipo is not null
			begin
				return @tipo
			end

			select @tipo = 0, @ldlocal = valor from ccSettings with(nolock) where setting_id = 17
				
			if @lenght = 10 - LEN(@ldlocal) begin
				select @tel = convert(varchar(3),@ldlocal) + @tel
			end
				
			select @tel = RIGHT(@tel,10)
			select @ladatemp = left(@tel,2)
				
			if(@ladatemp in (55,56,33,81)) begin
				select @serie = convert(smallint,SUBSTRING(@tel,3,4)), @numeracion = RIGHT(@tel,4)
				select @mod = MODALIDAD from Series nolock where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
			end
			else begin
				select @ladatemp = left(@tel,3)
				select @serie = convert(smallint,SUBSTRING(@tel,4,3)), @numeracion = RIGHT(@tel,4)
				select @mod =MODALIDAD from Series nolock where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
			end
				
			if @mod in ('FIJO', 'MPP') begin
				if @ldlocal = @ladatemp begin
					set @tipo = 1
				end
				else begin
					set @tipo = 2
				end
			end
				
			if @mod in ('CPP') begin
				if @ldlocal = @ladatemp begin
					set @tipo = 3
				end
				else begin
					set @tipo = 4
				end
			end

			return @tipo
		END