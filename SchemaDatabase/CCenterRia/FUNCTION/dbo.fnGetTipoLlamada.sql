CREATE function [dbo].[fnGetTipoLlamada](@tel varchar(32))
		RETURNS tinyint
		AS
		BEGIN
		
		declare @ladatemp smallint, @ldlocal varchar(10), @serie smallint, @numeracion smallint, @lenght tinyint
		declare @mod varchar(10), @country tinyint
		
		select @country = valor from ccsettings where setting_id = 104
		select @lenght = LEN(@tel),
		@ldlocal = valor from ccSettings with(nolock) where setting_id = 17
		--print ' longitud: ' + convert(varchar(2),@lenght) + ' lada: ' + convert(varchar(3),@ldlocal)
		
			declare @table table(
			id int not null,
			prefijo nvarchar(100) not null
			)
		
			declare @t_tipos table(
			tipollamada_id int not null,
			prefijo nvarchar(100) not null,
			rowid int not null
			)
		
		declare @tipoLlamada_id smallint, @prefijo varchar(15), @tipo tinyint, @cantidadLL tinyint
		set @tipoLlamada_id = 0
		--set @tipo = 0
		
			insert into @t_tipos
			select tipoLlamada_id, prefijo, ROW_NUMBER() over(order by len(prefijo) desc) as rowid from (select tipoLlamada_id, longitud, prefijo, (select count(*) from fn_RIASplitDelimited(longitud,'|') where value=@lenght) as exist
			from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
			where country_id = @country
			and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) ) as a where exist = 1
		
			select @cantidadLL =count(*) from @t_tipos 
			--print 'cantidad de regs' + convert(varchar(2),@cantidadLL)
		
			if @cantidadLL <> 0 begin
			   --print 'existen opciones'
			   declare @i int ;
				set @i=1

			   while @i <= @cantidadLL
			   begin
					 select @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo from @t_tipos where rowid = @i
					 --print 'tipo llamada:' + convert(varchar(2),@tipoLlamada_id) + ' prefijo:' + @prefijo
		
					 insert into @table
					 select * from fn_RIASplitDelimited(@prefijo,'|') order by len(value) desc
		
					 if (select count(*)	from @table	where @tel like prefijo) = 1
					 begin
						set @tipo = @tipoLlamada_id
						set @i = @cantidadLL
					 end
		
					 set @i = @i + 1
			   end
			end
			else begin
			   --print 'revisar contra longitud 0'
		
			   select @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo from (select tipoLlamada_id, longitud, prefijo, (select count(*) from fn_RIASplitDelimited(prefijo,'|') where @tel like (value)) as exist
			   from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
			   where country_id = @country and longitud = '0'
			   and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) ) as a where exist = 1
		
			   if @tipoLlamada_id <> 0 begin
					 set @tipo = @tipoLlamada_id
			   end
			   else begin
					 --print 'revisar contra series'
		
					 if @lenght = 10 - LEN(@ldlocal) begin
						select @tel = convert(varchar(3),@ldlocal) + @tel
					 end
		
					 select @tel = RIGHT(@tel,10)
					 select @ladatemp = left(@tel,2)
		
					 if(@ladatemp in (55,56,33,81)) begin
						--print 'es de dos digitos'
						select @serie = convert(smallint,SUBSTRING(@tel,3,4)), @numeracion = RIGHT(@tel,4)
						--print 'serie: ' + convert(varchar(4),@serie) + ' numeracion: ' + convert(varchar(4),@numeracion)
						select @mod = MODALIDAD from Series where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
					 end
					 else begin
						--print 'es de tres digitos'
						select @ladatemp = left(@tel,3)
						select @serie = convert(smallint,SUBSTRING(@tel,4,3)), @numeracion = RIGHT(@tel,4)
						--print 'serie: ' + convert(varchar(4),@serie) + ' numeracion: ' + convert(varchar(4),@numeracion)
						select @mod =MODALIDAD from Series where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
					 end


					declare @isLocal bit
					SET @isLocal = 0

					IF EXISTS (
							SELECT *
							FROM ccRiaArecode
							WHERE area = @ladatemp
							)
					BEGIN
						SET @isLocal = 1
					END
					ELSE IF @ldlocal = @ladatemp
					BEGIN
						SET @isLocal = 1
					END

		
					 if @mod in ('FIJO', 'MPP') begin
						if(@isLocal = 1)
						begin
							--print 'misma lada -> es local'
							set @tipo = 1
						end
						else begin
							--print 'diferente lada -> es ld'
							set @tipo = 2
						end
					 end
		
					 if @mod in ('CPP') 
					 begin
						if(@isLocal = 1)
						begin
							--print 'misma lada -> es celular local'
							set @tipo = 3
						end
						else begin
							--print 'diferente lada -> es celular ld'
							set @tipo = 4
						end
					 end
			   end
			end
		
			return @tipo
		END