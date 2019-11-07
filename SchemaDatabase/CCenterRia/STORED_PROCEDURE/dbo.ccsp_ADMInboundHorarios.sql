CREATE PROCEDURE ccsp_ADMInboundHorarios
@Inbound_id smallint,
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40)
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	select @Descripcion=Upper(Descripcion) from ccHorarios where horario_id=@horario_id
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccInboundHorarios where Inbound_id = @Inbound_id and horario_id=@horario_id
		) > 0
			if @idioma = 1
			select 0, 'Schedule Already Assigned'
			else
			select 0, 'Horario ya Asignado'
		else
		begin
			Insert ccInboundHorarios (Inbound_id, Horario_id  ) Values ( @Inbound_id, @horario_id )
			if @idioma = 1
			select -1, 'Schedule: ' + @Descripcion + ' Assigned to the Specialty OK'
			else
			select -1, 'Horario: ' + @Descripcion + ' Asignado en la Especialidad OK'
		end
	end
	if ( @Tipo=3 )
	begin
		Delete ccInboundHorarios where Inbound_id = @Inbound_id and horario_id=@horario_id
		if @idioma = 1
		select -1, 'Schedule: ' + @Descripcion + ' Removed from the Specialty'
		else
		select -1, 'Horario: ' + @Descripcion + ' Removido de la Especialidad'
	end