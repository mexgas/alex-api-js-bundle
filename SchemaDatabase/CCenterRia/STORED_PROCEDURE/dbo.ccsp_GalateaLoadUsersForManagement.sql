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