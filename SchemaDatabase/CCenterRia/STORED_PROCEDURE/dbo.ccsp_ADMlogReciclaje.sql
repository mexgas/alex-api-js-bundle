CREATE PROCEDURE ccsp_ADMlogReciclaje
@cam_id as integer,
@user_id as integer,
@tipo as integer,
@calificaciones as varchar(50) = ''
AS
	if @tipo = 2 or @tipo = 0
	insert into ccLogReciclaje (cam_id, user_id, tipoRecicle, calificaciones) values ( @cam_id, @user_id, @tipo, @calificaciones)
	else
	insert into ccLogReciclaje (cam_id, user_id, tipoRecicle) values ( @cam_id, @user_id, @tipo)