Create PROCEDURE ccsp_GalateaCreateUser
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Password varchar(200),
@Sexo bit,
@canChangeStatus bit,
@AreaId int,
@UserType tinyint
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)

--Obtiene el idioma de de Centerware
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
  if exists(select Login from ccUsers where Login=@Login)
    begin
    select -1 as ResponseCode--,'Login en Uso'
    return(0)
    end

  if exists(select Login from ccUsers_Consulta where Login = @Login)
  begin
    select -4 as ResponseCode -- 'Login en Uso aunque el usuario ya se halla borrado de la base de datos' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
    return(0)
  end

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
    select -2 as ResponseCode--,'Nombre completo en Uso'-- valida todos los campos de nombre para ver que no existan en la base de datos
    return(0)
    end


--insert
IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
  set @UserId = null
  SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
  LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
  INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
  FROM ccusers) AS w ON w.recID = d.recID

  if @UserId is null
  begin
    select -3 as ResponseCode --Error_when_inserting_user
    return(0)
  end

  set identity_insert ccusers on
  insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
  select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
  set identity_insert ccusers off

  delete ccMenuUser where id_User = @UserId
  delete ccRIAUserRole where user_id = @UserId

  exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

END
ELSE
BEGIN
  insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
  select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

  if @@rowcount=1
    select @UserId=scope_identity()
  else
    begin
    select -2--insert Error
    return(0)
    end
END
  insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
  insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
  insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
  --Menu para roles RepotsRia
  exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario