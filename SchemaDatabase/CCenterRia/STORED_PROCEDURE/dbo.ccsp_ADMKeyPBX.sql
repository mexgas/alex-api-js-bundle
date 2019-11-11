CREATE PROCEDURE ccsp_ADMKeyPBX
@NumeroKey smallint,
@ptopbx_id smallint,
@ext_id smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Delete
AS
declare @numKey as varchar(3)
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	select @numKey = convert(varchar(3), @NumeroKey)
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccTeclaExtensionPuerto where num_tecla = @NumeroKey and ptopbx_id = @ptopbx_id
		) > 0
			if @idioma = 1
			select 0, 'Key in Use'
			else
			select 0, 'Tecla en Uso'
		else
			if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id
			) > 0
				if @idioma = 1
				select 0, 'Extension in Use'
				else
				select 0, 'Extension en Uso'
			else
				Insert ccTeclaExtensionPuerto ( num_tecla, ptopbx_id, ext_id )
						Values ( @NumeroKey, @ptopbx_id, @ext_id )
				if @idioma = 1
				select -1, 'Key: ' + @numKey + ' Added Succesfully'
				else
				select -1, 'Tecla: ' + @numKey + ' Dada de Alta'
	end
	if ( @Tipo=2 )
	begin
		if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id and num_tecla <> @NumeroKey  
		) > 0
			if @idioma = 1
			select 0, 'Extension in Use'
			else
			select 0, 'Extension en Uso'
		else
			Update ccTeclaExtensionPuerto set ptopbx_id=@ptopbx_id, ext_id=@ext_id
					where num_tecla = @NumeroKey --and ptopbx_id = @ptopbx_id
			if @idioma = 1
			select -1, 'Key: ' + @numKey + ' Modified'
			else
			select -1, 'Tecla: ' + @numKey + ' Modificada'
	end
	if ( @Tipo=3 )
	begin
		Delete ccTeclaExtensionPuerto where num_tecla = @NumeroKey and ptopbx_id=@ptopbx_id and ext_id=@ext_id
		if @idioma = 1
		select -1, 'Key: ' + @numKey + ' Removed'
		else
		select -1, 'Tecla: ' + @numKey + ' Eliminada'
	end