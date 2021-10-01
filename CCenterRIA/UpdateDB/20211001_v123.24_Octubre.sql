/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 24
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

    set @process = 'CW-5828 ccsp_GalateaLoadUsersForManagement - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadUsersForManagement'')
            begin
          DROP PROCEDURE ccsp_GalateaLoadUsersForManagement;
            end'
    EXEC(@sql)

    set @process = 'CW-5828 ccsp_CleanNodeBaseX '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
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
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
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
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
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
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
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
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '''')
	END as LastName,

	CASE 
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '''')
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
END'
    EXEC(@sql)

    set @process = 'CW-5828 ccsp_GalateaChangeHistory - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaChangeHistory'')
            begin
          DROP PROCEDURE ccsp_GalateaChangeHistory;
            end'
    EXEC(@sql)

    set @process = 'CW-5828 ccsp_GalateaChangeHistory'
    set @sql = ' '
    EXEC(@sql)

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END