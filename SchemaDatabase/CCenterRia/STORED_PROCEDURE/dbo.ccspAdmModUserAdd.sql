CREATE PROCEDURE ccspAdmModUserAdd
@nombres varchar(50), 
@apellidopaterno varchar(50), 
@apellidomaterno varchar(50)
AS
DECLARE @id smallint
SELECT @id=ISNULL([user_id],0)+1 FROM ccUsers
INSERT INTO ccUsers ([user_id], nombres, apellidopaterno, apellidomaterno)
 VALUES (@id, @nombres, @apellidopaterno, @apellidomaterno)
SELECT @id AS 'NewID'