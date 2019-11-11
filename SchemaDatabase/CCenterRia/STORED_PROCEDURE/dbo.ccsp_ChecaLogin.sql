CREATE PROCEDURE ccsp_ChecaLogin
@Login varchar(12),
@Password varchar(32),
@Computer varchar(20)
AS
declare @LoginOK tinyint
declare @PswdOK tinyint
declare @CompuOK tinyint
declare @ExtenOK tinyint
declare @TeclaOK tinyint
declare @Nombre varchar(60)
declare @Extension varchar(7)
declare @UserID smallint
declare @CCServer varchar(20)

--Para posiciones ip, by ODC
declare @ext_id int
declare @pos_id int

-- Para live connected
-- Tipo de conexion: 0 normal, 1 liveconnected
declare @tipoConexion smallint

SELECT @LoginOK=0, @PswdOK=0, @CompuOK=0, @ExtenOK=0, @TeclaOK=0, @Extension='', @UserID='', @Nombre='', @tipoConexion = 0
SELECT @CCServer=valor FROM ccSettings WHERE setting_id=7

select @LoginOK= count(*)
from ccUsers
Where Login = @Login and status > 0 and tipoUser_id = 1

IF ( @LoginOK > 0 )
BEGIN
	select @PswdOK= count(*)
	from ccUsers
	Where Login = @Login
	AND (Password=@Password OR Password = dbo.md5(@password)) and status > 0 and tipoUser_id = 1
	IF ( @PswdOK > 0 )
	BEGIN
		select @CompuOK = count(*)
		from ccPosicion
		Where Computer = @Computer

		IF ( @CompuOK = 0) begin
			insert ccposicion (computer, ext_id) values (@Computer, 0)
			select @CompuOK = 1
		end
			
		IF ( @CompuOK > 0 )
		BEGIN
			select @ExtenOK = count(*)
			from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
			Where Computer = @Computer
	
			IF ( @ExtenOK > 0)
			BEGIN

				select @Extension = Extension, @ext_id = p.ext_id, @pos_id = p.pos_id, @tipoConexion = p.tipoConexion
				from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
				Where Computer = @Computer

				select @TeclaOK=count(*)
				from ccTeclaExtensionPuerto T join ccMonitorExt M on T.ext_id=M.ext_id
				where M.Extension=@Extension

				select	@UserID=user_id,
					@Nombre=Nombres + ' ' + isnull(ApellidoPaterno,'') + ' ' +isnull(ApellidoMaterno,'')
				from ccUsers
				Where Login = @Login
				AND TipoUser_id=1
				AND status > 0 and tipoUser_id = 1
			END
		END
	END
END

--Para posiciones ip, by ODC
-- No verifica ccTeclaExtensionPuerto, @TeclaOK =1 
-- Regresa un etension 'virtual'.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
IF( @ext_id = 0 )
BEGIN
	select @TeclaOK =1, @Extension = cast( @pos_id * -1 as varchar(7))
END

IF @tipoConexion = 1
	select @TeclaOK =1

SELECT 'LoginOK'=@LoginOK, 'PswdOK'=@PswdOK, 'CompuOK'= @CompuOK, 'ExtenOK'=@ExtenOK, 'Extension'=@Extension, 'UserID'=@UserID, 'Nombre'=@Nombre, 'CCServer'=@CCServer, 'TeclaOK'=@TeclaOK, 'TipoConexion' = @tipoConexion