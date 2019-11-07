CREATE PROCEDURE ccsp_DLRSaveDialResultOLD
@callout_id int,
@cam_id smallint,
@tipoResDial_id int,
@Telefono varchar(14),
@Puerto int,
@last_dialed int,
@fecVenc 	datetime = 0
AS

if ( @tipoResDial_id <>13 ) 
begin
	INSERT ccoLogDials ( callout_id, cam_id, tipoResDial_id, Telefono, Puerto  )
		VALUES ( @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto )

	if ( @tipoResDial_id =11) -- Eliminar de CallsOUT, no Marcar por Validacion de Saldo Cliente
		Delete ccoWorkingTable Where callout_id = @callout_id
	else
		if (@tipoResDial_id = 12) begin
			update ccoWorkingTable set cal_fechaDial = dateadd(dd, 1, @fecVenc), cal_status = 1 where callout_id = @callout_id
			--update ccoCallsOutSource set cal_fechaDial = dateadd(dd, 1, @fecVenc) where callout_id = @callout_id
		end
		else
			update ccocallsoutsource set last_dialed = @last_dialed where callout_id = @callout_id
end
else
begin
	update ccoWorkingTable set cal_status =5 where callout_id = @callout_id
end