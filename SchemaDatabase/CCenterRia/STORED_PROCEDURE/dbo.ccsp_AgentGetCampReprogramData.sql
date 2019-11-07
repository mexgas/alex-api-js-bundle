CREATE PROCEDURE ccsp_AgentGetCampReprogramData
@Inbound_id smallint,
@type tinyint=1
AS
set nocount on

if @type=1 -- Verifica si hay alguna calificacion con reprogramacion asignada
 begin
	if exists (select CanReprogram from ccTipoCalif TC join ccCalifCamp CC on TC.calif_id = CC.calif_id 
	where CC.cam_id = @Inbound_id and CC.tipo = 0 and TC.CanReprogram = 1)
		select 1
	else
		select 0
	return(0)
 end

if @type=2 -- Verifica la campaña asignada a la especialidad
 begin
	select isnull(cam_id,0) from ccInbound where Inbound_id=@Inbound_id
	return(0)
 end

set nocount off