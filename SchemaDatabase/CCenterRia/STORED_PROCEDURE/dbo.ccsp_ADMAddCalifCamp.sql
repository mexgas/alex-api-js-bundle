CREATE PROCEDURE [dbo].[ccsp_ADMAddCalifCamp]
@calif_id smallint, --Id Calificacion
@Tipo tinyint, --0=In, 1=Out
@cam_id smallint=0, --Inbound_id, or cam_id, si es 0 la Agrega a Todos
@user_id smallint=1
AS

if ( @calif_id >0 and ( @Tipo=1or @Tipo=0 ) )
begin
	if ( @cam_id>0 ) -- Agrega Una a una Campañas  por Tipo
		if (select count(*) from ccCalifCamp where calif_id = @calif_id and cam_id = @cam_id and tipo = @tipo) = 0
		      insert into ccCalifCamp (calif_id,cam_id,tipo) values ( @calif_id, @cam_id, @Tipo)
	
	if (@cam_id=0 )   -- Agrega Una a Todas las Campañas por Tipo
	begin
		delete ccCalifCamp where calif_id=@calif_id and tipo=@Tipo and (cam_id in (select cam_id from ccSupervisorCam where tipo = @tipo and user_id = @user_id)  or @user_id = 1)
	
		if (@Tipo=0) -- InBound
		begin			
			insert into ccCalifCamp(calif_id,cam_id,tipo)
			select @calif_id as calif_id, Inbound_id, 0 as tipo from ccInbound
			where inbound_id in (select cam_id from ccSupervisorCam where tipo = 0 and user_id = @user_id) or @user_id = 1
		end
	
		if (@Tipo=1) -- OutBound
		begin	
			insert into ccCalifCamp(calif_id,cam_id,tipo)
			select @calif_id as calif_id, cam_id, 1 as tipo from ccCamps
			where cam_id in (select cam_id from ccSupervisorCam where tipo = 0 and user_id = @user_id) or @user_id = 1
		end
	end
end