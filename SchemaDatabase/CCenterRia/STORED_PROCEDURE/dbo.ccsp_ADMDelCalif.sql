CREATE PROCEDURE ccsp_ADMDelCalif
@calif_id smallint,
@cam_id smallint,
@Tipo tinyint,
@user_id smallint = 1
AS

delete ccCalifCamp where calif_id=@calif_id and cam_id =@cam_id and tipo=@Tipo

if @calif_id = 0 delete ccCalifCamp where cam_id = @cam_id and tipo = @Tipo 
	and (cam_id in (select cam_id from ccSupervisorCam where tipo = @Tipo and user_id = @user_id) or @user_id = 1)
--HLAS 20050311 --Si calif_id es 0 quitar todas las calificaciones a la especialidad
if @cam_id = 0 delete ccCalifCamp where calif_id = @calif_id and tipo = @Tipo  --HLAS 20050311 --Si cam_id es 0 quitar todas la calificacion de todas las campa;as
	and (cam_id in (select cam_id from ccSupervisorCam where tipo = @Tipo and user_id = @user_id) or @user_id = 1)

if @cam_id = 0 and @calif_id = 0 delete ccCalifCamp where tipo = @Tipo  --HLAS 20050311 --Si cam_id es 0 y calif_id = 0 quitar todas las calificacion de todas las campa;as de in o out
	and (cam_id in (select cam_id from ccSupervisorCam where tipo = @Tipo and user_id = @user_id) or @user_id = 1)