/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

 
/*
Author: 
		
Date: 2018/08/21
Description:

Release  120.24_20180906

Database: CCenterRia
Required version: 120.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120
set @versionfix = 24


/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 22
	begin
		begin tran
		begin try

		set @process = 'CW-2027 Plan de marcación agregar setting 205'
		set @Sql= 'delete from ccSettings Where setting_id=205
		insert into ccSettings (setting_id, valor, descripcion, Status, Tipo,detalle,description,bLoadSettings, validate)
		values(205,''0'',''Activar'
		EXEC(@Sql)

		set @process = 'CW-2027 Plan de marcación agregar a cstoTipoLlamada'
		set @Sql= 'delete from cstoTipoLlamada where country_id =1 and tipoLlamada_id = 12
		insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud)
		values (1,12,''Local'',''%'',''10'')'
		EXEC(@Sql)

		set @process = 'CW-2027 Plan de marcación ALTER function Completa'
		set @Sql= 'ALTER function [dbo].[Completa](@Cadena varchar(32), @pais varchar(2) = '''', @ld varchar(5) = '''')
			RETURNS varchar(32)
			AS
			BEGIN
			declare @resultado varchar(32)
			declare @SCMex smallint

			select @SCMex = valor from ccsettings where setting_id = 205

			if (@pais = '''' and @ld = '''')
				begin
					select @pais = valor from ccSettings with(nolock) where setting_id = 104
					select @ld = valor from ccSettings with(nolock) where setting_id = 17
				end
			select @resultado = dbo.limpia(@Cadena)

			--Completa 1:M?xico 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala 12:Costa Rica 13:Salvador
			if @pais = 1
			 begin
				 IF(@SCMex =0)
					BEGIN
						--Empieza Mexico
						select @resultado = case
						 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
						 when len(@resultado)=10 then
						   case when left(@resultado, len(@ld)) = @ld
							then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
						 when len(@resultado)=12 then
						   case when left(@resultado, 2) = ''01'' then
							 case when substring(@resultado, 3, len(@ld)) = @ld
							   then right(@resultado, 10 - len(@ld)) else @resultado end
							else ''E_NV_LD'' end
						 when len(@resultado)=13 then
						   case when left(@resultado, 3) in (''044'', ''045'') then
							 case when substring(@resultado, 4, len(@ld)) = @ld then
							   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10)
							 end
						   else ''E_NV_Cel'' end
						else ''E_NV_Longitud'' end

						--Termina Mexico
						return @resultado
					end
				IF(@SCMex =1)
					BEGIN
						--Empieza Mexico
						select @resultado = case
						 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
						 when len(@resultado)=10 then
						   case when left(@resultado, len(@ld)) = @ld
							then @resultado else ''01'' + @resultado end --arroja el numero a 10 digitos completos
						 when len(@resultado)=12 then
						   case when left(@resultado, 2) = ''01'' then
							 case when substring(@resultado, 3, len(@ld)) = @ld
							   then right(@resultado, 10 - len(@ld)) else @resultado end
							else ''E_NV_LD'' end
						 when len(@resultado)=13 then
						   case when left(@resultado, 3) in (''044'', ''045'') then
							 case when substring(@resultado, 4, len(@ld)) = @ld then
							   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10)
							 end
						   else ''E_NV_Cel'' end
						else ''E_NV_Longitud'' end

						--Termina Mexico
						return @resultado
					end
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
						case when left(@resultado,2) = ''15'' then @resultado end
					else
						case when len(@ld) = 2 then @resultado end
					end
				-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
				 when len(@resultado)=9 then
					case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
				-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
				 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
				 when len(@resultado)=10 then
				   case when left(@resultado, len(@ld)) = @ld
					then right(@resultado, 10 - len(@ld)) else
						case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end
				   end
				-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
				-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
				 when len(@resultado)=11 then
				   case when left(@resultado, 1) = ''0'' then
					 case when substring(@resultado, 2, len(@ld)) = @ld
					   then right(@resultado, 10 - len(@ld)) else @resultado end
					else ''E_NV_LD'' end
				-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
				-- si no es local se le agrega el 0 y se marca el numero
				 when len(@resultado)=12 then
					case when left(@resultado, len(@ld)) = @ld then
						case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then
							right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
				-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
				 when len(@resultado)=13 then
					case when left(@resultado, 1) = ''0'' then
						case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
					else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

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
					case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado
					else
						''E_NV_Cel''
					end
				--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
				--prefijo de celular
				 when len(@resultado)=11 then
					case when left(@resultado,1)=''0'' then
						case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
					else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

				-- Termina Colombia
				return @resultado
			 end

			if @pais = 4
			 begin
				--Empieza USA
				select @resultado = case len(@resultado)
				 when 3 then
					case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
				 when 7 then @resultado
				 when 10 then
				   case when left(@resultado, len(@ld)) = @ld
					then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
				 when 11 then
				   case when left(@resultado, 1) = ''1'' then
					 case when substring(@resultado, 2, len(@ld)) = @ld
					   then right(@resultado, 10 - len(@ld)) else @resultado end
					else ''E_NV_LD'' end
				else ''E_NV_Longitud'' end

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
						case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
							case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
							 else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end
						 end
					end
				-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
				-- de telefonia voIp se le agrega el 0 al inicio
				 when 9 then
					case when @ld = left(@resultado,2) then right(@resultado,7) else
						case when left(@resultado,2) in (41,32,65) then @resultado else
							case when left(@resultado,2) = ''44'' then ''0'' + @resultado else
								case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
							 end
						end
					end
				 when 10 then
					case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

				-- Termina Chile
				return @resultado
			 end

			-- Venezuela
			if @pais = 6 begin
				select @resultado = case len(@resultado)
					when 7 then @resultado
					when 10 then ''0'' + @resultado
					when 11 then
						case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
					else
					''E_NV_Longitud'' end
			end
			--Termina Venezuela

			-- UK
			if @pais = 7 begin
				select @resultado = case len(@resultado)
					when 11 then
						case left(@resultado,1)
							when ''0'' then @resultado else ''E_NV_Longitud''
						end
					when 10 then
						case left(@resultado,1)
							when ''0'' then @resultado else ''0'' + @resultado
						end
					when 9 then
						case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
					when 8 then
						case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
					when 7 then
						case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
					else
					''E_NV_Longitud''
				end
			end
			-- Termina UK

			if @pais = 8 begin -- arabia saudita
				select @resultado = case len(@resultado)
				when 7 then @resultado
				when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
				when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado
							when ''0'' then case substring(@resultado, 2, 1)
									when @ld then right(@resultado, 7) else @resultado end
							else ''E_NV_Longitud''
							end
				when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
				when 11 then case substring(@resultado, 2, 1)
								when ''8'' then case substring(@resultado, 3, 3)
												when ''111'' then @resultado else ''E_NV_Longitud'' end
								else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
								end
				when 13 then @resultado
				else ''E_NV_Longitud'' end
			end -- arabia saudita

			if @pais = 9 --Australia
			begin
				select @resultado = case len(@resultado)
				when 8 then
					/*case when exists (select AreaCode
									  from SeriesAU
									  where convert(int,LD) = convert(int,@ld)
									  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
						case substring(@resultado, 1, 4) when ''5550'' then ''E_NV_LD'' else @ld +  @resultado end
					/*else case when exists (select AreaCode
									  from SeriesAU
									  where convert(int,LD) = convert(int,''04'')
									  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
					''04'' +  @resultado
					else ''E_NV_Cel'' end end*/
				when 9 then
					case when left(@resultado,1) <> ''0'' then
						case substring(@resultado, 2, 4) when ''5550'' then ''E_NV_LD'' else ''0'' + @resultado end
					else ''E_NV_LD'' end
				when 10 then
					case substring(@resultado, 3, 4) when ''5550'' then ''E_NV_LD'' else @resultado end
				else ''E_NV_Longitud'' end
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
					case when (left(@resultado,4) = ''9090'') then right(@resultado,8) else ''E_NV_PC'' end
				when 13 then
					case when left(@resultado,4) = ''9090'' then right(@resultado,9) -- llamadas por cobrar local celular
						 when left(@resultado,1) = ''0'' then
						case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
					else ''E_NV_Longitud'' end
				when 14 then
						case when left(@resultado,2) = ''90'' then -- llamadas por cobrar larga distancia
								case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end
							 when left(@resultado,1) = ''0''  then --llamada larga distancia a celular
									case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end
						else ''E_NV_Longitud'' end
				when 15 then
					case when left(@resultado,2) = ''90'' then -- Llamadas por cobrar a celular LD
							case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end
						else ''E_NV_Longitud'' end

				else ''E_NV_Longitud'' end

			end

			if @pais = 11 --Guatemala
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,3,4,5,6,7'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					select @resultado = ''E_NV_Longitud''
			end

			if @pais = 12 --Costa Rica
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,3,4,5,6,7,8'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else if len(@resultado)=10
					begin
						if charindex(substring(@resultado,1,3),''800,900,905'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00,08'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 13 --Salvador
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,6,7'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 14 --Espa?a
			begin
				if len(@resultado)=9
					begin
						if charindex(substring(@resultado,1,1),''5,6,7,8,9'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 15 --Peru
			begin
				select @resultado = case
				 when (len(@resultado)=7 and len(@ld)=1) or (len(@resultado)=6 and len(@ld)=2) then @resultado
				 when len(@resultado)=8 then
				  case when substring(@resultado, 1, len(@ld)) = @ld
				   then right(@resultado, 8 - len(@ld)) else ''0'' + @resultado end
				 when len(@resultado)=9 then
				   case when left(@resultado,1) = ''0'' and substring(@resultado, 2, len(@ld)) = @ld
					then right(@resultado, 8 - len(@ld)) else @resultado end
				else ''E_NV_Longitud'' end
			end --Termina Peru


			if @pais = 16 --Panama
			begin
				select @resultado = case
					when (len(@resultado)=7) then
					case when substring(@resultado,1,1) in (''2'',''3'',''4'',''5'',''7'',''9'') then @resultado else ''E_'' + @resultado end
					when (len(@resultado)=8) then
					case when substring(@resultado,1,1) = ''6'' then @resultado else ''E_'' + @resultado end
					else
						case when substring(@resultado,1,2) = ''00''then @resultado else ''E_'' + @resultado end
					end
			end

			-- Termina
			return @resultado

			end'
		EXEC(@Sql)


		set @process = 'CW-2027 Plan de marcación ALTER function fnGetTipoLlamada'
		set @Sql= 'ALTER function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
		returns int
		as
		 begin
			declare @len integer, @tipo integer, @country varchar(5)
			declare @tipoLlamada_id smallint
			declare @prefijo varchar(15), @longitud varchar(15)
			declare @SCMex smallint

			declare @table table(
			id int not null,
			prefijo nvarchar(100) not null
			)
	
			select @SCMex = valor from ccsettings where setting_id = 205
			select @country = valor from ccsettings where setting_id = 104
			set @len = len( @tel )
			set @tipo = 0

			declare @prefixTable table(
			tipoLlamada_id smallint not null,
			longitud varchar(15) not null,
			prefijo varchar(15) not null,
			[status] bit not null
			)

			IF(@SCMex =0)
				BEGIN
					insert into @prefixTable
					select tipoLlamada_id, longitud, prefijo, 0
					from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
					where country_id = @country 
					and 
					(country_id <> 1
					 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) --no incluir tarifas por region (Mexico)
					order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones
				END
			ELSE
				BEGIN
					--posible edicion pa agregar el setting
					insert into @prefixTable
					select tipoLlamada_id, longitud, prefijo, 0
					from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
					where country_id = @country 
					and 
					(country_id <> 1
					 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11))) --no incluir tarifas por region (Mexico)
					order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones
				END


			while (select count(*) from @prefixTable where [status] = 0) > 0
			begin
				select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
				from @prefixTable 
				where [status] = 0

				insert into @table
				select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc

				if (select count(*) from fn_RIASplitDelimited(@longitud,''|'') where value=@len) = 1
					begin
						if (select count(*)	from @table	where @tel like prefijo) = 1
							set @tipo = @tipoLlamada_id
					end
				else if @longitud = ''0''
					begin
						if (select count(*)	from @table	where @tel like prefijo) = 1
							set @tipo = @tipoLlamada_id
					end

				if @tipo <> 0
					update @prefixTable
					set [status] = 1
				else
					begin
						update @prefixTable
						set [status] = 1
						where tipoLlamada_id = @tipoLlamada_id

						delete @table
					end
			end

			return @tipo
		 end'
		EXEC(@Sql)

		set @process = 'CW-2027 Plan de marcación alter function verifica'
		set @Sql= 'ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
			RETURNS varchar(32) AS
			 BEGIN
				declare @ld varchar(7)
				declare @lon tinyint
				declare @result tinyint
				declare @mod varchar(10)
				declare @Cadena varchar(32)
				declare @cldLocal varchar(7)
				declare @pais tinyint
				declare @SCMex smallint

				select @SCMex = valor from ccsettings where setting_id = 205
				select @cldLocal = valor from ccsettings with(nolock) where setting_id = 17
				select @pais = valor from ccSettings with(nolock) where setting_id = 104
				select @tel = dbo.limpia(@tel)

				if @pais = 1 begin --Empieza Mexico
					select @lon = len(@tel)
					if @lon between 7 and 8 begin
						set @tel = @cldLocal + @tel
					end
					select @tel = right(@tel, 10)
					select @lon = len(@tel)

					if @lon = 10 begin

						if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
							select @ld = left(@tel,2)
						else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
							select @ld = left(@tel,3)
						else
							return ''E_'' + @tel

						select @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

						if (@SCMex=0)
						select @tel = case
							when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
							when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
							else ''E_'' + @tel end
						 if (@SCMex=1)
						 select @tel = case
							when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10) else ''01'' + @tel end
							when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
							else ''E_'' + @tel end
						
					end else begin
						if @lon > 0 begin
							select @tel = ''E_'' + @tel
						end
					end
					return @tel
				end --Termina Mexico

				-- Empieza Argentina
				if @pais = 2 begin
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel,1) = ''E'' begin return @tel end
					select @lon = len(@tel)
					if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
						set @tel = @cldLocal + @tel
					end

					if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
						set @tel = @cldLocal + substring(@tel,3,@lon - 2)
					end

					--Buscamos el 15
					if @lon = 13 begin
						declare @index as int
						select @index = charindex(''15'',@tel)
						--El unico caso en el que la lada tiene un 15 es con lada 3715
						if @index < 2 begin
							select @tel = ''E_'' + @tel
							return @tel
						end
						else begin
							if substring(@tel,@index-2,4) = ''3715''
								begin
									select @ld = ''3715''
									set @tel = @ld + right(@tel,6)
								end
							else
								begin
									select @ld = substring(@tel,2,@index-2)
									set @tel = @ld + right(@tel,13 - (@index + 1))
								end
						end
					end

					select @tel = right(@tel, 10)

					if len(@tel) = 10 begin
						declare @serie as varchar(5)
						begin
							-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
							declare @contLD as int
							declare @cont as int
							set @contLD=4
								BuscaLada:
								if isnull(@ld,'''') = '''' and @contLD >= 2
									begin
										select @ld = cld from seriesArg where cld=left(@tel,@contLD)
										if isnull(@ld,'''') = '''' begin
											set @contLD = @contLD - 1
											goto BuscaLada
										end
									end
								else begin
										if isnull(@ld,'''') = '''' begin
											select @tel = ''E_'' + @tel
										end
								end
						end

						-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
						begin
						if len(@ld) = 2 begin
								set @cont = 5
								buscaSerie2:
								if isnull(@serie,'''') = '''' and @cont >= 4 begin
									select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
									if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
								end
						end
						else begin
							if len(@ld) = 3 begin
								set @cont = 4
								buscaSerie3:
								if isnull(@serie,'''') = '''' and @cont >= 3 begin
									select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
									if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
								end
							end
							else begin
								if len(@ld) = 4 begin
									set @cont = 3
									buscaSerie4:
									if isnull(@serie,'''') = '''' and @cont >= 2 begin
										select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
										if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
									end
								end
							end
						end

						end

						select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

						-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
						--select @ld,@serie,@mod,@contLD
						if isNull(@serie,'''') = '''' and @contLD>1 begin
						set @contLD = len(@ld) - 1
						set @ld = null
						goto BuscaLada
						end

						select @tel = case
							when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
							when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
							else ''E_'' + @tel
						end
					end else begin
						if len(@tel) > 0 begin
							select @tel = ''E_'' + @tel
						end
					end
					return @tel
				end  --Termina Argentina

				if @pais = 3 begin  --Empieza Colombia
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel,1) = ''E'' begin
						return @tel
					end

					if len(@tel) not in (7,8,10,11) begin
						return ''E_'' + @tel
					end

					if len(@tel) = 7 begin
						if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end

					if len(@tel) = 8 begin
						if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end

					if len(@tel) = 10 begin
						if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end

					if len(@tel) = 11 begin
						if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
				end  --Termina Colombia

				-- Empieza Chile
				if @pais = 5 begin
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel,1) = ''E'' begin
						return @tel
					end

					if len(@tel) = 6 and len(@cldLocal) = 2 begin
						if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
							return @tel
						end
						else begin return ''E_'' + @tel end
					end

					if len(@tel) = 7 begin
						if @cldLocal in (2,41,44,32) begin
							if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
							else begin
								if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
							end
						end
					end

					if len(@tel) = 8 begin
						if left(@tel,1) = ''2'' begin
								if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
								else begin
									if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
									else begin return ''E_'' + @tel end
								end
						end
						else begin
							return @tel
						end
					end

					if len(@tel) = 10 begin
						if left(@tel,2) = ''09'' begin
							if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
								return @tel
							end
							else begin
								return ''E_'' + @tel
							end
						end

					end
				end
				--Termina Chile

				if @pais = 6 begin --Empieza Venezuela
					select @lon = len(@tel)
					if @lon = 7  begin
						set @tel = @cldLocal + @tel
					end

					select @tel = right(@tel, 10)

					if len(@tel) = 10 begin
						select @ld = left(@tel,3)
						select @mod = tipo from seriesVen where left(@tel,3) = LD

						if @mod = ''CPP'' begin
							if exists( select * from seriesVen where LD = @ld ) begin
								if @ld = @cldLocal begin
									select @tel = right(@tel,7)
								end
								else begin
									select @tel = ''0'' + @tel
								end
							end
							else begin
								select @tel = ''E_'' + @tel
							end
						end
						else begin
							if @mod = ''FIJO'' begin
								if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
									if @ld = @cldLocal begin
										select @tel = right(@tel,7)
									end
									else begin
										select @tel = ''0'' + @tel
									end
								end
								else begin
									select @tel = ''E_'' + @tel
								end
							end
							else begin
								select @tel = ''E_'' + @tel
							end
						end
					end
					else begin
						if len(@tel) > 0 begin
							select @tel = ''E_'' + @tel
						end
					end
					return @tel
				end --Termina Venezuela

				if @pais = 7 begin -- Empieza UK
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel, 1) = ''E'' begin -- regresa error por longitud
						return @tel
					end
					select @lon = len(@tel)

					--numeros no geograficos
					if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
						return ''E_'' + @tel --error por longitud con lada correcta
					end
					else begin
						if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
							return @tel; --longitud correcta y numero no geografico
						end
					end

					--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
					if (left(@tel, 7) in(''0159575'', ''0159576'')) or
						(left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890'',''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
						(left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
						(left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
						return @tel;
					end

					--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
					if left(@tel, 2) = ''01'' begin
						select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
						if @ld > 0 begin
							return @tel;
						end
						else begin
							select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
							if @ld > 0 begin
								return @tel;
							end
						end
					end --si no encontro ni error ni coincidencia entonces esta mal
					return ''E_'' + @tel
				end --Termina UK

				if @pais = 8 begin --Empieza Arabia Saudita
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					select @lon = len(@tel)
					if @lon = 7 begin
						set @tel = ''0'' + @cldLocal + @tel
					end
					select @lon = len(@tel)

					if @lon = 9 begin
						if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
							if (substring(@tel,2,1) = @cldLocal)
							begin
								return right(@tel,7)
							end else begin
								return @tel
							end
						end
						else begin
							return ''E_'' + @tel
						end
					end
					if @lon = 10 begin
						if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
					if @lon = 11 begin
						if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
				end --Termina Arabia Saudita

				if @pais = 9
					begin --Empieza Australia
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						select @lon = len(@tel)

						if left(@tel,1) <> ''E''
							begin
								if exists(select Regiones
										  from SeriesAU
										  where convert(int,LD) = convert(int,substring(@tel, 1, 2))
										  and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
										  and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
									begin
										return @tel
									end
								else
									begin
										return ''E_'' + @tel
									end
							end
						else
							begin
								return @tel
							end
					end --Termina Australia

				if @pais= 10
					begin -- Inicia Brasil
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						select @lon = len(@tel)
						if left(@tel,1) <> ''E''
							begin
								if @lon in (8,9) begin --numero local
									if exists(
									select Regiones
										from seriesBR where
											convert(int,AreaCode) = convert(int,@cldLocal) and
											convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
									)
									begin
										return @tel
									end
									else begin
										return ''E_'' + @tel
									end
								end
								if @lon in (10,11) begin --numero nacional
									if exists(
									select Regiones
										from seriesBR where
											convert(int,AreaCode) = convert(int,left(@tel,2)) and
											convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
									)
									begin
										return @tel
									end
									else begin
										return ''E_'' + @tel
									end
								end
							end

						else begin
							return @tel
						end
					end -- Termina Brasil

				if @pais= 11
					begin -- Inicia Guatemala
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
									return @tel
								else
									return ''E_'' + @tel
							end
						else
							return @tel
					end -- Termina Guatemala

					if @pais= 12
					begin -- Inicia Costa Rica
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=8
									if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else if len(@tel)=10 begin
									if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								end
								else
									if charindex(substring(@tel,1,2),''00,08'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Costa Rica

				if @pais= 13
					begin -- Inicia Salvador
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=8
									if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Salvador

				if @pais= 14
					begin -- Inicia Spain
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=9
									if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Espa?a

				if @pais= 15 begin --Inicia Peru
					select @tel = dbo.Completa(@tel, @pais, @cldLocal)
					select @lon = len(@tel)
					if @lon between 6 and 7 begin
						set @tel = @cldLocal + @tel
					end
					select @tel = right(@tel, 9)
					select @lon = len(@tel)
					if left(@tel,1) <> ''E'' begin
						if @lon = 9 begin
							if exists(select zonaGeografica from seriesPE (nolock) where
								left(@tel,1) = 9 or
								substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
								substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
							)
								return @tel
							else
								return ''E_'' + @tel
						end
					end
				end --Termina Peru

				if @pais= 16
					begin -- Inicia Panama
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=7 begin -- Local
									if(substring(@tel,1,1) != ''6'') begin
										if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
											return @tel
										else
											return ''E_'' + @tel
									end
									else
										return ''E_'' + @tel
								end
								if len(@tel)=8 begin --Celular
									if(substring(@tel,1,1) = ''6'') begin
										if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
											return @tel
										else
											return ''E_'' + @tel
									end
									else
										return ''E_'' + @tel
								end
								else begin
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
								end
							end
					end -- Termina Panama

				return @tel
			end'
		EXEC(@Sql)

		set @process = 'CW-2027 Plan de marcación alter function verifica2'
		set @Sql= 'ALTER FUNCTION [dbo].[Verifica2]
			(@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
			RETURNS varchar(32) AS
			BEGIN
			declare @ld varchar(7)
			declare @lon tinyint
			declare @result tinyint
			declare @mod varchar(10)
			declare @Cadena varchar(32)
			declare @manOpt smallint
			declare @SCMex smallint

			select @SCMex = valor from ccsettings where setting_id = 205

			if (@pais = 0 and @ld = '''')
			begin
			 select @pais = valor from ccSettings with(nolock) where setting_id = 104
			 select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
			end
			select @manOpt = valor from ccsettings with(nolock) where setting_id = 195
			select @tel = dbo.limpia(@tel)

			if @pais = 1 begin --Empieza Mexico
			 select @lon = len(@tel)
			 if @lon between 7 and 8 begin
			  set @tel = @cldLocal + @tel
			 end
			 select @tel = right(@tel, 10)
			 select @lon = len(@tel)

			 if @lon = 10 begin

			  if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
			   select @ld = left(@tel,2)
			  else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
			   select @ld = left(@tel,3)
			  else
			   return ''E_'' + @tel

			  select @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]
			  if (@SCMex=0)
				  select @tel = case
				   when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
				   when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
				   else ''E_'' + @tel end
			  if (@SCMex=1)
				  select @tel = case
				   when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10) else ''01'' + @tel end
				   when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
				   else ''E_'' + @tel
			  end

  
				if @manOpt = 1 --10 digits
				begin
					set @lon = len(@tel)
					if @lon = 10 - len(@ld)
						set @tel = @ld + @tel

					if @lon = 12 and left(@tel, 2) = ''01'' and left(right(@tel, 10), len(@cldLocal)) = @cldLocal
						set @tel = right(@tel, 10)

				end

			 end else begin
			  if @lon > 0 begin
			   select @tel = ''E_'' + @tel
			  end
			 end
			 return @tel
			end --Termina Mexico

			 -- Empieza Argentina
				if @pais = 2 begin
				 select @tel = dbo.completa(@tel, @pais, @cldLocal)
				 if left(@tel,1) = ''E'' begin return @tel end
				 select @lon = len(@tel)
				 if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
				  set @tel = @cldLocal + @tel
				 end

				 if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
				  set @tel = @cldLocal + substring(@tel,3,@lon - 2)
				 end

				 --Buscamos el 15
				 if @lon = 13 begin
				  declare @index as int
				  select @index = charindex(''15'',@tel)
				  --El unico caso en el que la lada tiene un 15 es con lada 3715
				  if @index < 2 begin
				   select @tel = ''E_'' + @tel
				   return @tel
				  end
				  else begin
				   if substring(@tel,@index-2,4) = ''3715''
					begin
					 select @ld = ''3715''
					 set @tel = @ld + right(@tel,6)
					end
				   else
					begin
					 select @ld = substring(@tel,2,@index-2)
					 set @tel = @ld + right(@tel,13 - (@index + 1))
					end
				  end
				 end

				 select @tel = right(@tel, 10)

				 if len(@tel) = 10 begin
				  declare @serie as varchar(5)
				  begin
				   -- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				   declare @contLD as int
				   declare @cont as int
				   set @contLD=4
					BuscaLada:
					if isnull(@ld,'''') = '''' and @contLD >= 2
					 begin
					  select @ld = cld from seriesArg where cld=left(@tel,@contLD)
					  if isnull(@ld,'''') = '''' begin
					   set @contLD = @contLD - 1
					   goto BuscaLada
					  end
					 end
					else begin
					  if isnull(@ld,'''') = '''' begin
					   select @tel = ''E_'' + @tel
					  end
					end
				  end

				  -- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
				  begin
				  if len(@ld) = 2 begin
					set @cont = 5
					buscaSerie2:
					if isnull(@serie,'''') = '''' and @cont >= 4 begin
					 select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
					 if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
					end
				  end
				  else begin
				   if len(@ld) = 3 begin
					set @cont = 4
					buscaSerie3:
					if isnull(@serie,'''') = '''' and @cont >= 3 begin
					 select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
					 if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
					end
				   end
				   else begin
					if len(@ld) = 4 begin
					 set @cont = 3
					 buscaSerie4:
					 if isnull(@serie,'''') = '''' and @cont >= 2 begin
					  select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
					  if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
					 end
					end
				   end
				  end

				  end

				  select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

				  -- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
				  --select @ld,@serie,@mod,@contLD
				  if isNull(@serie,'''') = '''' and @contLD>1 begin
				  set @contLD = len(@ld) - 1
				  set @ld = null
				  goto BuscaLada
				  end

				  select @tel = case
				   when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
				   when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
				   else ''E_'' + @tel
				  end
				 end else begin
				  if len(@tel) > 0 begin
				   select @tel = ''E_'' + @tel
				  end
				 end
				 return @tel
				end  --Termina Argentina

				if @pais = 3 begin  --Empieza Colombia
				 select @tel = dbo.completa(@tel, @pais, @cldLocal)
				 if left(@tel,1) = ''E'' begin
				  return @tel
				 end

				 if len(@tel) not in (7,8,10,11) begin
				  return ''E_'' + @tel
				 end

				 if len(@tel) = 7 begin
				  if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				   return @tel
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end

				 if len(@tel) = 8 begin
				  if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				   return @tel
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end

				 if len(@tel) = 10 begin
				  if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				   return @tel
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end

				 if len(@tel) = 11 begin
				  if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				   return @tel
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end
				end  --Termina Colombia

				-- Empieza Chile
				if @pais = 5 begin
				 select @tel = dbo.completa(@tel, @pais, @cldLocal)
				 if left(@tel,1) = ''E'' begin
				  return @tel
				 end

				 if len(@tel) = 6 and len(@cldLocal) = 2 begin
				  if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
				   return @tel
				  end
				  else begin return ''E_'' + @tel end
				 end

				 if len(@tel) = 7 begin
				  if @cldLocal in (2,41,44,32) begin
				   if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
				   else begin
					if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
				   end
				  end
				 end

				 if len(@tel) = 8 begin
				  if left(@tel,1) = ''2'' begin
					if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
					else begin
					 if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
					 else begin return ''E_'' + @tel end
					end
				  end
				  else begin
				   return @tel
				  end
				 end

				 if len(@tel) = 10 begin
				  if left(@tel,2) = ''09'' begin
				   if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
					return @tel
				   end
				   else begin
					return ''E_'' + @tel
				   end
				  end

				 end
				end
				--Termina Chile

				if @pais = 6 begin --Empieza Venezuela
				 select @lon = len(@tel)
				 if @lon = 7  begin
				  set @tel = @cldLocal + @tel
				 end

				 select @tel = right(@tel, 10)

				 if len(@tel) = 10 begin
				  select @ld = left(@tel,3)
				  select @mod = tipo from seriesVen where left(@tel,3) = LD

				  if @mod = ''CPP'' begin
				   if exists( select * from seriesVen where LD = @ld ) begin
					if @ld = @cldLocal begin
					 select @tel = right(@tel,7)
					end
					else begin
					 select @tel = ''0'' + @tel
					end
				   end
				   else begin
					select @tel = ''E_'' + @tel
				   end
				  end
				  else begin
				   if @mod = ''FIJO'' begin
					if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
					 if @ld = @cldLocal begin
					  select @tel = right(@tel,7)
					 end
					 else begin
					  select @tel = ''0'' + @tel
					 end
					end
					else begin
					 select @tel = ''E_'' + @tel
					end
				   end
				   else begin
					select @tel = ''E_'' + @tel
				   end
				  end
				 end
				 else begin
				  if len(@tel) > 0 begin
				   select @tel = ''E_'' + @tel
				  end
				 end
				 return @tel
				end --Termina Venezuela

				if @pais = 7 begin -- Empieza UK
				 select @tel = dbo.completa(@tel, @pais, @cldLocal)
				 if left(@tel, 1) = ''E'' begin -- regresa error por longitud
				  return @tel
				 end
				 select @lon = len(@tel)

				 --numeros no geograficos
				 if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
				  return ''E_'' + @tel --error por longitud con lada correcta
				 end
				 else begin
				  if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
				   return @tel; --longitud correcta y numero no geografico
				  end
				 end

				 --numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
				 if (left(@tel, 7) in(''0159575'', ''0159576'')) or
				  (left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890''
			,''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
				  (left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
				  (left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
				  return @tel;
				 end

				 --numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
				 if left(@tel, 2) = ''01'' begin
				  select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
				  if @ld > 0 begin
				   return @tel;
				  end
				  else begin
				   select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
				   if @ld > 0 begin
					return @tel;
				   end
				  end
				 end --si no encontro ni error ni coincidencia entonces esta mal
				 return ''E_'' + @tel
				end --Termina UK

				if @pais = 8 begin --Empieza Arabia Saudita
				 select @tel = dbo.completa(@tel, @pais, @cldLocal)
				 select @lon = len(@tel)
				 if @lon = 7 begin
				  set @tel = ''0'' + @cldLocal + @tel
				 end
				 select @lon = len(@tel)

				 if @lon = 9 begin
				  if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
				   if (substring(@tel,2,1) = @cldLocal)
				   begin
					return right(@tel,7)
				   end else begin
					return @tel
				   end
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end
				 if @lon = 10 begin
				  if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
				   return @tel
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end
				 if @lon = 11 begin
				  if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
				   return @tel
				  end
				  else begin
				   return ''E_'' + @tel
				  end
				 end
				end --Termina Arabia Saudita

				if @pais = 9
				 begin --Empieza Australia
				  select @tel = dbo.completa(@tel, @pais, @cldLocal)
				  select @lon = len(@tel)

				  if left(@tel,1) <> ''E''
				   begin
					if exists(select Regiones
						from SeriesAU
						where convert(int,LD) = convert(int,substring(@tel, 1, 2))
						and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
						and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
					 begin
					  return @tel
					 end
					else
					 begin
					  return ''E_'' + @tel
					 end
				   end
				  else
				   begin
					return @tel
				   end
				 end --Termina Australia

				if @pais= 10
				 begin -- Inicia Brasil
				  select @tel = dbo.completa(@tel, @pais, @cldLocal)
				  select @lon = len(@tel)
				  if left(@tel,1) <> ''E''
				   begin
					if @lon in (8,9) begin --numero local
					 if exists(
					 select Regiones
					  from seriesBR where
					   convert(int,AreaCode) = convert(int,@cldLocal) and
					   convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
					 )
					 begin
					  return @tel
					 end
					 else begin
					  return ''E_'' + @tel
					 end
					end
					if @lon in (10,11) begin --numero nacional
					 if exists(
					 select Regiones
					  from seriesBR where
					   convert(int,AreaCode) = convert(int,left(@tel,2)) and
					   convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
					 )
					 begin
					  return @tel
					 end
					 else begin
					  return ''E_'' + @tel
					 end
					end
				   end

				  else begin
				   return @tel
				  end
				 end -- Termina Brasil

				if @pais= 11
				 begin -- Inicia Guatemala
				  select @tel = dbo.completa(@tel, @pais, @cldLocal)
				  if left(@tel,1) <> ''E''
				   begin
					if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
					 return @tel
					else
					 return ''E_'' + @tel
				   end
				  else
				   return @tel
				 end -- Termina Guatemala

				 if @pais= 12
				 begin -- Inicia Costa Rica
				  select @tel = dbo.completa(@tel, @pais, @cldLocal)
				  if left(@tel,1) <> ''E''
				   begin
					if len(@tel)=8
					 if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
					  return @tel
					 else
					  return ''E_'' + @tel
					else if len(@tel)=10 begin
					 if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
					  return @tel
					 else
					  return ''E_'' + @tel
					end
					else
					 if charindex(substring(@tel,1,2),''00,08'') <= 0
					  return ''E_'' + @tel
					 else
					  return @tel
				   end
				 end -- Termina Costa Rica

				if @pais= 13
				 begin -- Inicia Salvador
				  select @tel = dbo.completa(@tel, @pais, @cldLocal)
				  if left(@tel,1) <> ''E''
				   begin
					if len(@tel)=8
					 if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
					  return @tel
					 else
					  return ''E_'' + @tel
					else
					 if charindex(substring(@tel,1,2),''00'') <= 0
					  return ''E_'' + @tel
					 else
					  return @tel
				   end
				 end -- Termina Salvador

				if @pais= 14
				 begin -- Inicia Spain
				  select @tel = dbo.completa(@tel, @pais, @cldLocal)
				  if left(@tel,1) <> ''E''
				   begin
					if len(@tel)=9
					 if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
					  return @tel
					 else
					  return ''E_'' + @tel
					else
					 if charindex(substring(@tel,1,2),''00'') <= 0
					  return ''E_'' + @tel
					 else
					  return @tel
				   end
				 end -- Termina Espa?a

				if @pais= 15 begin --Inicia Peru
				 select @tel = dbo.Completa(@tel, @pais, @cldLocal)
				 select @lon = len(@tel)
				 if @lon between 6 and 7 begin
				  set @tel = @cldLocal + @tel
				 end
				 select @tel = right(@tel, 9)
				 select @lon = len(@tel)
				 if left(@tel,1) <> ''E'' begin
				  if @lon = 9 begin
				   if exists(select zonaGeografica from seriesPE (nolock) where
					left(@tel,1) = 9 or
					substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
					substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
				   )
					return @tel
				   else
					return ''E_'' + @tel
				  end
				 end
				end --Termina Peru

				if @pais = 16 begin --Panama
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					 if left(@tel,1) <> ''E''
					 begin
					  if len(@tel)=7 begin -- Local
					   if(substring(@tel,1,1) != ''6'') begin
						if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
						 return @tel
						else
						 return ''E_'' + @tel
					   end
					   else
						return ''E_'' + @tel
					  end
					  if len(@tel)=8 begin --Celular
					   if(substring(@tel,1,1) = ''6'') begin
						if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
						 return @tel
						else
						 return ''E_'' + @tel
					   end
					   else
						return ''E_'' + @tel
					  end
					  else begin
					   if charindex(substring(@tel,1,2),''00'') <= 0
						return ''E_'' + @tel
					   else
						return @tel
					  end
				   end
				end

				return @tel
			   end'
		EXEC(@Sql)

	
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix 

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
