CREATE PROCEDURE ccspAdmModUserGet
@id smallint
AS
SELECT [user_id], nombres, apellidopaterno, ISNULL(apellidomaterno,'')
 FROM  ccUsers
 WHERE [user_id]=@id