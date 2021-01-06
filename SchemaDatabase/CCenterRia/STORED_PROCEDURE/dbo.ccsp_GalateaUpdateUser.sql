CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Sexo bit,
@canChangeStatus bit
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @userIdOnDb int
Declare @LoginOnDb varchar(40)
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

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin

		select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
	  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

	  	select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
	  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

	  if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
		begin
			select -2 as ResponseCode--,'Nombre completo en Uso'-- valida todos los campos de nombre para ver que no existan en la base de datos
			return(0)
		end
    end

--update
	Update ccUsers set 
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,
	ApellidoMaterno=@ApellidoMaterno,
	Sexo=@Sexo,
	canChangeStatus=@canChangeStatus
	where User_id=@UserId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario