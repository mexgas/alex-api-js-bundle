CREATE PROCEDURE [dbo].[ccsp_RIAEspTablero]
@User varchar(4)
AS

			select inbound_id, descripcion from ccinbound  where status = 1 
			and inbound_id in (select cam_id from ccSupervisorCam where user_id = @User and tipo = 0) 
			order by descripcion