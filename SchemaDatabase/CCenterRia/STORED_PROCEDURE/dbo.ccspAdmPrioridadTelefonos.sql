CREATE PROCEDURE ccspAdmPrioridadTelefonos 
	@cam_id int,
	@prioridad varchar(8),
	@callbacks bit = 0
AS

--Actualiza la prioridad en la tabla
update ccCampsPrioridadTel set prioridad = @prioridad where cam_id=@cam_id

if @callbacks = 0 begin
	--Ahora cambia todos los registros en ccoCallsoutsource.  Solo nuevos
	Update ccoCallsoutsource set dial_tels = @prioridad
	where cam_id = @cam_id 
	and callout_id in 
		( 
		select callout_id from ccoWorkingTable where cam_id=@cam_id and cal_status = 0
		)
end else begin
	Update ccoCallsoutsource set dial_tels = @prioridad
	where cam_id = @cam_id 
end