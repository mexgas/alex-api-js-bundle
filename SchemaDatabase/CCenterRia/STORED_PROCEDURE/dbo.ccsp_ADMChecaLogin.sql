CREATE PROCEDURE [dbo].[ccsp_ADMChecaLogin]
@Login varchar(12),
@Password varchar(15)
AS
declare @LoginOK tinyint
declare @PswdOK tinyint
declare @Nombre varchar(60)
declare @UserID smallint
declare @ADMServer varchar(20)

SELECT @LoginOK=0, @PswdOK=0,  @UserID='', @Nombre=''
SELECT @ADMServer=valor FROM ccSettings WHERE setting_id=8

select @LoginOK= count(*)
from ccUsers
Where Login like @Login
AND TipoUser_id > 1 and status > 0

IF ( @LoginOK > 0 )
BEGIN
	select @PswdOK= count(*)
	from ccUsers
	Where Login = @Login
	AND (Password=@Password or password = dbo.md5(@Password)) AND TipoUser_id > 1 and status > 0

	IF ( @PswdOK > 0 )
	BEGIN
		select	@UserID=user_id,
			@Nombre=Nombres + ' ' + isnull(ApellidoPaterno,'') + ' ' +isnull(ApellidoMaterno,'')
		from ccUsers
		Where Login like @Login
		AND TipoUser_id > 1 and status > 0
	END
END
SELECT 'LoginOK'=@LoginOK, 'PswdOK'=@PswdOK, 'UserID'=@UserID, 'Nombre'=@Nombre, 'ADMServer'=@ADMServer