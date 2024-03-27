
----------------------------------------------------- BEGIN SMS Masivo Muñoz KR134000  ----------------------------------------------------------------

----------------------------------------------------- BEGIN KR134001-Módulo de segmentos  ----------------------------------------------------------------


SET @process = 'KR134001 CREATE TABLE ccSmsSegments';
SET @sql = '
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsSegments'') BEGIN
    CREATE TABLE ccSmsSegments(
        SegmentId INT IDENTITY(1,1) PRIMARY KEY,
        Name VARCHAR(255),
        IsGlobal BIT DEFAULT(0),
        CampaignId SMALLINT DEFAULT (0)
    )
END';
EXEC (@sql);

SET @process = 'KR134001 CREATE TABLE ccSmsConditions FK SegmentId';
SET @sql = '
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsConditions'') BEGIN
    CREATE TABLE ccSmsConditions(
        ConditionId INT IDENTITY(1,1) PRIMARY KEY,
        SegmentId INT FOREIGN KEY REFERENCES ccSmsSegments(SegmentId),
        Field VARCHAR(255),
        Operator VARCHAR(2),
        Value VARCHAR(255),
        DailyLimit INT, 
        WeeklyLimit INT
    )
END';
EXEC (@sql);

SET @process = 'KR134001 DROP PROCEDURE ccspSmsSegments';
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''ccspSmsSegments'')
BEGIN
    DROP PROCEDURE ccspSmsSegments
END';
EXEC (@sql);

SET @process = 'KR134001 CREATE PROCEDURE ccspSmsSegments';
SET @sql = '
ALTER PROCEDURE [dbo].[ccspSmsSegments] 
@Action SMALLINT = NULL, 
@CampaignId INT = 0,
@Ids VARCHAR(MAX) = ''''
AS

DECLARE @IdsTemp TABLE (Id INT);
DECLARE @Result TABLE (Names VARCHAR(MAX));
INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

IF @Action IS NOT NULL BEGIN
    IF @Action = 1 BEGIN        -- Get all segments and conditions
        SELECT s.SegmentId, 
               s.Name AS SegmentName, 
               s.IsGlobal AS SegmentIsGlobal,
               s.CampaignId,
               c.ConditionId, 
               c.Field AS ConditionField,
               c.Operator AS ConditionOperator, 
               c.Value AS ConditionValue, 
               c.DailyLimit AS ConditionDailyLimit,
               c.WeeklyLimit AS ConditionWeeklyLimit
        FROM ccSmsSegments s
        LEFT JOIN ccSmsConditions c ON s.SegmentId = c.SegmentId
        ORDER BY s.SegmentId, c.ConditionId;
        RETURN 0
    END
    ELSE IF @Action = 2 BEGIN       -- Assign/unassign segments to/from campaign 
        UPDATE ccSmsSegments
        SET CampaignId = CASE WHEN @CampaignId != 0 THEN @CampaignId ELSE 0 END
        FROM @IdsTemp ids
        WHERE ccSmsSegments.SegmentId = ids.Id

        INSERT INTO @Result
        SELECT ISNULL(segments.Name,'''')
        FROM @IdsTemp ids
        INNER JOIN ccSmsSegments segments ON segments.SegmentId = ids.Id
    END
    SELECT * FROM @Result
END
ELSE BEGIN
    RAISERROR(''Invalid action specified.'', 16, 1);
    RETURN -1;
END';
EXEC (@sql);


      
----------------------------------------------------- END KR134001-Módulo de segmentos ----------------------------------------------------------------

-------------------------------------------------------- BEGIN KR134021 AND KR134022 ------------------------------------------------------------------

set @process = 'Alter de tabla ccuser'
set @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = ''ccUsers'' AND COLUMN_NAME = ''notificationEmail''
)
BEGIN
    ALTER TABLE ccUsers
    ADD notificationEmail NVARCHAR(255) NULL;
END;'
EXEC(@sql)

set @process = 'Alter de sp ccsp_GalateaCreateUser'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaCreateUser]
                    @UserId int,
                    @Login varchar(40),
                    @Nombres varchar(45),
                    @LastName varchar(45),
                    @NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
                    @Password varchar(200),
                    @Sexo bit,
                    @canChangeStatus bit,
                    @AreaId int,
                    @UserType tinyint,
                    @AdminId int,
					@NotificationEmail varchar(255)
                    as

                    Declare @ApellidoMaterno varchar(45)
                    Declare @ApellidoPaterno varchar(45)

                    --Obtiene el idioma de de Centerware
                    Declare @lenguageXion varchar
                    select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

                    --se acondiciona los apellidos con el nombre opcional dependiendo del idioma
                        if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
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
                        select -1 as ResponseCode--,''Login en Uso''
                        return(0)
                        end

                        if exists(select Login from ccUsers_Consulta where Login = @Login)
                        begin
                        select -4 as ResponseCode -- ''Login en Uso aunque el usuario ya se halla borrado de la base de datos'' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
                        return(0)
                        end

                        if exists(select Nombres from ccUsers where Nombres=@Nombres
                        and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
                        begin
                        select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
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
						select * from ccUsers
                        set identity_insert ccusers on
                        insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id, Status,TipoLLamadas,Sexo,canChangeStatus,IDArea,notificationEmail)
                        select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end, @NotificationEmail
                        set identity_insert ccusers off

                        delete ccMenuUser where id_User = @UserId
                        delete ccRIAUserRole where user_id = @UserId

                        exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

                        --Insert Agent into ccRIAAgentsPermissions
                        IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
                        BEGIN
                        IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
                        BEGIN 
                            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
                            VALUES (@UserId, 0, 0, 1)
                        END
                        END

                    END
                    ELSE
                    BEGIN
                        insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
                        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea,notificationEmail)
                        select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
                        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end, @NotificationEmail

                        if @@rowcount=1
                        select @UserId=scope_identity()
                        else
                        begin
                        select -2--insert Error
                        return(0)
                        end

                        --INSERT INTO ACTIVITY LOG, CREATE AGENT
                        DECLARE @areaName AS VARCHAR(40);
                        DECLARE @userLogin AS VARCHAR(40);
                        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId);

                        IF(@AreaId <> 0) BEGIN
                            SET @areaName = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId);
                        END

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                        VALUES (CASE WHEN @AreaID = 0 THEN NULL ELSE @areaName END, getDate(), @userLogin, CASE WHEN @UserType = 1 THEN 22 ELSE 29 END, 3, '''', '''', @Login);

                    END
                        insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
                        insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
                        insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
                        --Menu para roles RepotsRia
                        exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

                        --Insert Agent into ccRIAAgentsPermissions
                        IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
                        BEGIN
                        IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
                        BEGIN 
                            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
                            VALUES (@UserId, 0, 0, 1)
                        END 
                        END
                    select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario'
EXEC(@sql)

set @process = 'Alter sp ccsp_GalateaUpdateUser'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Sexo bit,
@canChangeStatus bit,
@AdminId int,
@AreaId int,
@NotificationEmail varchar(255)
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @userIdOnDb int
Declare @LoginOnDb varchar(40)
--Obtiene el idioma de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
    if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
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
        select -5 as ResponseCode--,''el usuario no existe''
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
            select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
            return(0)
        end
    end

--update and insert into activity log a record for each modified property

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

    Update ccUsers set 
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,
    ApellidoMaterno=@ApellidoMaterno,
    Sexo=@Sexo,
    canChangeStatus=@canChangeStatus,
	notificationEmail=@NotificationEmail
    where User_id=@UserId

    DECLARE @CCUsersTable TABLE 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    INSERT INTO @CCUsersTable EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
        CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
        3, 
        CUT.identifierInfo,
        CASE WHEN CUT.identifierInfo IS NOT NULL THEN
            CASE 
                WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
                ELSE CUT.dataInfo END
        ELSE '''' END, 
        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
    FROM @CCUsersTable AS CUT;

    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
        '
EXEC(@sql)

set @process = 'Alter de sp ccsp_GalateaLoadUsersForManagement'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT = null,
 @Username VARCHAR(200)=null,
 @userId INT = 0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para espanol, 1 para ingles, 2 para portugues

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
	AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
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
  isnull(IDArea, 0) as AreaId,
  notificationEmail
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
	Return(0)
END

IF @option = 5 --Usuarios inactivos por mas de 60 dias por area
	BEGIN
		SELECT [User_id] as UserId,
		LOGIN as Username
		FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
		AND @AreaId = IDArea
		RETURN 0;
	END'
EXEC(@sql)

--------------------------------------------------------- END KR134021 AND KR134022 -------------------------------------------------------------------