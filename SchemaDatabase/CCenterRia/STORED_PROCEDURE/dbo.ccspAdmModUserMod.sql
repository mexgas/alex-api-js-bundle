CREATE PROCEDURE ccspAdmModUserMod
@id smallint,
@nombres varchar(50), 
@apellidopaterno varchar(50), 
@apellidomaterno varchar(50)
AS
UPDATE ccUsers
 SET  nombres=@nombres, apellidopaterno=@apellidopaterno, apellidomaterno=@apellidomaterno
	WHERE [user_id]=@id