CREATE PROCEDURE ccsp_ADMlogAgentsMovs 
@superID as integer,
@user_id as integer,
@EC_id as integer,
@tipoAsig as integer,
@tipoMov as integer
AS
	insert into ccCampsMovsAgts (superID, user_id, EC_id, tipoasig, tipomov) values ( @superID, @user_id, @EC_id, @tipoAsig, @tipoMov )