CREATE PROCEDURE xx_Redirecciona
@calkey as varchar(50),
@camOrigen as integer,
@camDestino as integer
as
update ccoCallsOutSource set cam_id = @camDestino where cam_id = @camOrigen and cal_key = @calkey and len(@calkey) > 0
update ccoWorkingtable  set cam_id = @camDestino where cam_id = @camOrigen and cal_keyw = @calkey and len(@calkey) > 0
if( @@ROWCOUNT = 0 )
begin
    -- No esta cargada, vuelve a cargar
    update ccoCallsOutSource set cal_status =0 where cam_id = @camDestino and cal_key = @calkey and len(@calkey) > 0
end