CREATE PROCEDURE ccsp_ADMClient
@Descripcion varchar(40),
@cli_id smallint,
@Tipo tinyint
AS
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccClientes where cli_nombre = @Descripcion
		) > 0
			if @idioma = 1
			select 0, 'The client already exists'
			else
			select 0, 'El cliente ya existe'
		else
		begin
			Insert ccClientes ( cli_nombre )  Values( @Descripcion )
			if @idioma = 1		
			select -1, 'Client: ' + @Descripcion + ' added succesfully'
			else
			select -1, 'Cliente: ' + @Descripcion + ' dado de alta'
		end
	end
	if ( @Tipo=2 )
	begin
		Update ccClientes set cli_nombre= @Descripcion where cli_id = @cli_id
		if @idioma = 1
		select -1, 'Client: ' + @Descripcion + ' updated'
		else
		select -1, 'Cliente: ' + @Descripcion + ' modificado'
	end
	if ( @Tipo=3 )
	begin
		if ( select count(*) from ccInbound where cli_id = @cli_id
		) > 0
			if @idioma = 1
			select 0, 'There are Specialties Related to this Client'
			else
			select 0, 'Existen Especialidades Relacionadas con este Cliente'
		else
			if ( select count(*) from ccCamps where cli_id = @cli_id
			) > 0
				if @idioma = 1
				select 0, 'There are Campaigns Related to this Client'
				else
				select 0, 'Existen Campaas Relacionadas con este Cliente'
			else
			begin
				Delete ccClientes Where cli_id = @cli_id
				if @idioma = 1
				select -1, 'Client: ' + upper(@Descripcion) + ' deleted'
				else
				select -1, 'Cliente: ' + upper(@Descripcion) + ' eliminado'
			end
	end