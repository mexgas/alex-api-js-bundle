CREATE PROCEDURE ccsp_GalateaUpdatePassword
@UserId int,
@Login varchar(200),
@Password varchar(200)
as

-- validaciones	
	if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
		begin
			select -5 as ResponseCode--el usuario no existe
			return(0)
		end

	if  @Password <> '' 
		begin 
			Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId	and Login=@Login
			select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
		end
	else
		begin 
			select -6 as ResponseCode -- la nueva contraseña es vacia
		end