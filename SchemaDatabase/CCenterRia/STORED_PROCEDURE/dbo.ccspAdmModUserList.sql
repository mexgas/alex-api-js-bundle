CREATE PROCEDURE ccspAdmModUserList
AS
SELECT [user_id], nombres  + ' ' + apellidopaterno + ' ' + ISNULL(apellidomaterno, '')
 FROM  ccUsers