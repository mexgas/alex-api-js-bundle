CREATE PROCEDURE ccsp_ADMHorario
@Descripcion varchar(40),
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@HoraInicio tinyint,
@MinInicio tinyint,
@HoraFin tinyint,
@MinFin tinyint,
@Lunes tinyint,
@Martes tinyint,
@Miercoles tinyint,
@Jueves tinyint,
@Viernes tinyint,
@Sabado tinyint,
@Domingo tinyint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion
AS
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccHorarios where Descripcion = @Descripcion) > 0
			if @idioma = 1
			select 0, 'Name in use'
			else
			select 0, 'Nombre en Uso'
		else
		begin
			Insert ccHorarios ( Descripcion, HoraInicio, MinInicio, HoraFin, MinFin,
						Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo )
					Values ( @Descripcion, @HoraInicio, @MinInicio, @HoraFin, @MinFin,
						@Lunes, @Martes, @Miercoles, @Jueves, @Viernes, @Sabado, @Domingo )
			if @idioma = 1
			select -1, 'Schedule:  ' + upper(@Descripcion) + ' Added Succesfully'
			else
			select -1, 'Horario: ' + upper(@Descripcion) + ' Dado de Alta'
		end
	end
	if ( @Tipo=2 )
	begin
		Update ccHorarios set Descripcion=@Descripcion, HoraInicio=@HoraInicio, MinInicio=@MinInicio,
					HoraFin=@HoraFin, MinFin=@MinFin,
					Lunes=@Lunes, Martes=@Martes, Miercoles=@Miercoles, Jueves=@Jueves, 
					Viernes=@Viernes, Sabado=@Sabado, Domingo=@Domingo
				where horario_id = @horario_id
		if @idioma = 1
		select -1, 'Schedule:  ' + upper(@Descripcion) + ' Modified'
		else
		select -1, 'Horario: ' + upper(@Descripcion) + ' Modificado'
	end
	if ( @Tipo=3 )
	begin
		if ( select count(*) from ccInboundHorarios where horario_id = @horario_id ) > 0
			if @idioma = 1
			select 0, 'This Schedule has some Specialty assigned'
			else
			select 0, 'Este Horario tiene alguna Especialidad asignada'
		else
		begin
			Delete ccHorarios Where horario_id = @horario_id
			if @idioma = 1
			select -1, 'Schedule:  ' + upper(@Descripcion) + ' Removed'
			else
			select -1, 'Horario: ' + upper(@Descripcion) + ' Eliminado'
		end
	end