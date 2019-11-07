CREATE function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
returns int
as
 begin
	declare @len integer, @tipo integer, @country varchar(5)
	declare @tipoLlamada_id smallint
	declare @prefijo varchar(15), @longitud varchar(15)

	declare @table table(
	id int not null,
	prefijo nvarchar(100) not null
	)

	select @country = valor from ccsettings where setting_id = 104
	set @len = len( @tel )
	set @tipo = 0

	declare @prefixTable table(
	tipoLlamada_id smallint not null,
	longitud varchar(15) not null,
	prefijo varchar(15) not null,
	[status] bit not null
	)

	insert into @prefixTable
	select tipoLlamada_id, longitud, prefijo, 0
	from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
	where country_id = @country 
	and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11))) --no incluir tarifas por region (Mexico)
	order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones

	while (select count(*) from @prefixTable where [status] = 0) > 0
	begin
		select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
		from @prefixTable 
		where [status] = 0

		insert into @table
		select * from fn_RIASplitDelimited(@prefijo,'|') order by len(value) desc

		if (select count(*) from fn_RIASplitDelimited(@longitud,'|') where value=@len) = 1
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end
		else if @longitud = '0'
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

	if @tipo = 0 and len(@tel) = 12 and LEFT(@tel,5) = 'E_800' begin
		set @tipo = 5
	end

	return @tipo
 end