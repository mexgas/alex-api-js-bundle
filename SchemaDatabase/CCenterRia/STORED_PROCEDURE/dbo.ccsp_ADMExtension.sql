CREATE PROCEDURE ccsp_ADMExtension
@NumeroExt varchar(7),
@ext_id smallint, -- Si Tipo =2, aqui viene el ID de la Extension
@Status smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion
AS
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccMonitorExt where Extension = @NumeroExt
		) > 0		
			if @idioma = 1
			select 0, 'Name in Use'
			else
			select 0, 'Nombre en Uso'
		else
		begin
			Insert ccMonitorExt ( Extension, Status ) Values ( @NumeroExt, 1 )
			if @idioma = 1
			select -1, 'Extension: ' + @NumeroExt + ' Added Succesfully'
			else
			select -1, 'Extension: ' + @NumeroExt + ' Dada de Alta'
		end
	end
	if ( @Tipo=2 )
	begin
		Update ccMonitorExt set Extension = @NumeroExt, Status=@Status Where ext_id = @ext_id
		if @idioma = 1
		select -1, 'Extension: ' + @NumeroExt + ' Modified'
		else
		select -1, 'Extension: ' + @NumeroExt + ' Modificada'
	end
	if ( @Tipo=3 )
	begin
		if ( select count(*) from ccPosicion where ext_id = @ext_id
		) > 0
			if @idioma = 1
			select 0, 'There are Positions using this Extension'
			else
			select 0, 'Existen Posiciones utilizando esta Extension'
		else
			if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id
			) > 0
				if @idioma = 1
				select 0, 'There are keys using this extension'
				else
				select 0, 'Existen Teclas utilizando esta Extension'
			else
			begin
				Delete ccMonitorExt Where ext_id = @ext_id
				if @idioma = 1
				select -1, 'Extension: ' + @NumeroExt + ' Removed'
				else
				select -1, 'Extension: ' + @NumeroExt + ' Eliminada'
			end
	end