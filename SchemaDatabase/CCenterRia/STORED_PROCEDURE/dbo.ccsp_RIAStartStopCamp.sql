CREATE PROCEDURE [dbo].[ccsp_RIAStartStopCamp]
@User int,
@Type tinyint,
@Cam_Id int
AS

declare @sql nvarchar(1000)

if( @Type=1)
	begin
		select cam_id, cam_descripcion, cast(cam_procesando as int) as cam_procesando from ccCamps
		where cam_id in (select cam_id from ccSupervisorCam 
		where user_id = @User and tipo = 1) 
		order by cam_procesando DESC, cam_descripcion
	end

if( @Type=2)
	begin
		if NOT EXISTS (select cam_id from ccCamps where cam_id = @cam_id)
		begin
			select -1
		end
		select cast(cam_procesando as int) as cam_procesando from ccCamps
		where cam_id = @cam_id
	end