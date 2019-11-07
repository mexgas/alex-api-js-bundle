CREATE PROCEDURE [dbo].[ccsp_RIACATHorario]
@Descripcion varchar(40) = null,
@horario_id varchar(10) = null,
@HoraInicio varchar(2) = null,
@MinInicio varchar(3) = null,
@HoraFin varchar(2) = null,
@MinFin varchar(2) = null,
@Lunes varchar(1) = null,
@Martes varchar(1) = null,
@Miercoles varchar(1) = null,
@Jueves varchar(1) = null,
@Viernes varchar(1) = null,
@Sabado varchar(1) = null,
@Domingo varchar(1) = null,
@Tipo varchar(2) = null
as
set nocount on
if @Tipo=1
 begin
	select horario_id, Descripcion, dbo.RIAtimeFormat(HoraInicio) as HoraInicio, dbo.RIAtimeFormat(MinInicio) as MinInicio,
	 dbo.RIAtimeFormat(HoraFin) as HoraFin, dbo.RIAtimeFormat(MinFin) as MinFin, cast(Lunes as int) as Lunes,
	 cast(Martes as int) as Martes, cast(Miercoles as int)as Miercoles, cast(Jueves as int) as Jueves,
	 cast(Viernes as int) as Viernes, cast(Sabado as int) as Sabado, cast(Domingo as int) as Domingo
	from ccHorarios Order by Descripcion
	return(0)
 end

if @Tipo=2
 begin
	if exists(select Descripcion from ccHorarios where Descripcion = @Descripcion)
	 begin
	 	select 1, 'Nombre en Uso'
	 	return(0)
	 end

	Insert ccHorarios (Descripcion, HoraInicio, MinInicio, HoraFin, MinFin,
		Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo)
	Select @Descripcion, @HoraInicio, @MinInicio, @HoraFin, @MinFin,
		@Lunes, @Martes, @Miercoles, @Jueves, @Viernes, @Sabado, @Domingo
	return(0)
 end

if @Tipo=3
 begin
	Update ccHorarios set Descripcion = ISNULL(@Descripcion,Descripcion), HoraInicio=ISNULL(@HoraInicio,HoraInicio),
	MinInicio=ISNULL(@MinInicio,MinInicio), HoraFin=ISNULL(@HoraFin,HoraFin), MinFin=ISNULL(@MinFin,MinFin),
	Lunes=ISNULL(@Lunes,Lunes), Martes=ISNULL(@Martes,Martes), Miercoles=ISNULL(@Miercoles,Miercoles),
	Jueves=ISNULL(@Jueves,Jueves), Viernes=ISNULL(@Viernes,Viernes), Sabado=ISNULL(@Sabado,Sabado),
	Domingo=ISNULL(@Domingo,Domingo) where horario_id = @horario_id

	if @@rowcount>0
		select 0 horario_id, cast(@horario_id as varchar(3)) + '-' + Descripcion from ccHorarios Where horario_id = @horario_id
	return(0)
 end

if @Tipo=4
 begin
	if exists(select Horario_id from ccInboundHorarios where horario_id = @horario_id)
	 begin
		select 1, 'Este Horario tiene alguna Especialidad asignada'
		return(0)
	 end

	select @Descripcion = Descripcion from ccHorarios Where horario_id = @horario_id
	Delete ccHorarios Where horario_id = @horario_id
	if @@ROWCOUNT=0
		select 2, 'No se elimino el horario, debido a que este no existe'

	select 0 horario_id, cast(@horario_id as varchar(3)) + '-' + @Descripcion Descripcion
	return(0)
 end
 if @Tipo = 5 begin --saber horarios asignados campaña
	select b.cam_id from ccHorarios a inner join ccCampsHorarios b on a.horario_id=b.horario_id where a.horario_id=@horario_id
	return(0)
 end
set nocount off