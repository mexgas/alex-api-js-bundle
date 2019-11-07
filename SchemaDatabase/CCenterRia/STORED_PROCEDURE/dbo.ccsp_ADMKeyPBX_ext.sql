CREATE PROCEDURE ccsp_ADMKeyPBX_ext
@extension varchar(7),
@NumeroKey smallint,
@ptopbx_id smallint
AS
declare @ext_id as smallint
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27


	select @ext_id = ext_id from ccMonitorExt where extension=@extension

	if ( @ext_id is not null )
	begin
		if ( select count(*) from ccTeclaExtensionPuerto where num_tecla= @NumeroKey and ptopbx_id = @ptopbx_id 
		) > 0
		begin
			update ccTeclaExtensionPuerto set ext_id=@ext_id where num_tecla= @NumeroKey and ptopbx_id = @ptopbx_id 
			if @idioma = 1
			select -1, 'Key: ' + convert(varchar(4), @NumeroKey) +'  Modified'
			else
			select -1, 'Tecla: ' + convert(varchar(4), @NumeroKey) +'  Actualizada'
		end
		else
			if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id
			) > 0
				if @idioma = 1
				select 0, 'Extension in Use'
				else
				select 0, 'Extension en Uso'
			else
			begin
				Insert ccTeclaExtensionPuerto ( num_tecla, ptopbx_id, ext_id )
						Values ( @NumeroKey, @ptopbx_id, @ext_id )
				if @idioma = 1		
				select -1, 'Key: ' + convert(varchar(4), @NumeroKey) +'  Added Succesfully'
				else
				select -1, 'Tecla: ' + convert(varchar(4), @NumeroKey) +'  Dada de Alta'
			end
	end