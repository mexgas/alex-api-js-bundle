CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Password varchar(200),
@Sexo bit,
@canChangeStatus bit
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @CurrentPass varchar(200)
--Obtiene el idioma de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
	if @lenguageXion= '0' or @lenguageXion= '2' --para español y portugues
		begin
			set @ApellidoPaterno = @LastName
			set @ApellidoMaterno = @NombreOpcionalExtra
		end
	else-- es idioma ingles
		begin
			set @ApellidoPaterno = @NombreOpcionalExtra 
			set @ApellidoMaterno = @LastName
		end

-- validaciones	
	if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
		begin
		select -5 as ResponseCode--,'el usuario no existe'
		return(0)
		end

--verificamos si la constrasena ha cambiado
	--select @CurrentPass= Password from ccUsers where User_id=@UserId and Login=@Login

	--if @Password <> '' and @Password <> null and @Password <> @CurrentPass -- si la contraseña si cambio actualizamos en base el fecha de actualizacion de pass
	--	begin 
	--	Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
	--	end

--update
	Update ccUsers set 
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,
	ApellidoMaterno=@ApellidoMaterno,
	--Password=case when @Password <> '' then @Password else Password end,
	Sexo=@Sexo,
	canChangeStatus=@canChangeStatus
	where User_id=@UserId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario