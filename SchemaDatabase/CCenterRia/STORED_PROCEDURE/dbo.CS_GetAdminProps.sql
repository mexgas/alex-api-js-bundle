CREATE PROCEDURE [dbo].[CS_GetAdminProps] @admin_id INT
AS
SET NOCOUNT ON;

SELECT convert(int,user_id) as [user_id], Nombres as [name]
	,Upper(left(nombres, 1) + left(apellidopaterno, 1)) AS [initials]
FROM ccUsers a
WHERE TipoUser_id = 2
	AND User_id = @admin_id