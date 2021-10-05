CREATE PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT,
 @Username VARCHAR(200)=null,
 @userId INT =0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area  
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion='1' THEN isnull(ApellidoMaterno, '')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '')
  END as LastName,

  CASE 
    WHEN @lenguageXion='1' THEN isnull(ApellidoPaterno, '')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion='1' THEN isnull(ApellidoMaterno, '')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '')
  END as LastName,

  CASE 
    WHEN @lenguageXion='1' THEN isnull(ApellidoPaterno, '')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion='1' THEN isnull(ApellidoMaterno, '')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '')
  END as LastName,

  CASE 
    WHEN @lenguageXion='1' THEN isnull(ApellidoPaterno, '')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END


IF @option = 4 -- supervisores en Area/Sistema
BEGIN
	DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
	INSERT INTO @Admins
	SELECT User_id as UserId,
	LOGIN as Username,
	Nombres as Names,
	CASE 
	  WHEN @lenguageXion='1' THEN isnull(ApellidoMaterno, '')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '')
	END as LastName,

	CASE 
	  WHEN @lenguageXion='1' THEN isnull(ApellidoPaterno, '')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '')
	END as OptionalExtraName,

	isnull(IDArea, 0) as AreaId
	FROM ccusers
	WHERE TipoUser_id = 2 AND STATUS = 1


	IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
		ORDER BY Username, Names, LastName, UserId
	END
	ELSE BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		ORDER BY Username, Names, LastName, UserId
	END

  RETURN (0)
END