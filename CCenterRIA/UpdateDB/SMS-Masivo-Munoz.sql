
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
  isnull(IDArea, 0) as AreaId,
  notificationEmail
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
  isnull(IDArea, 0) as AreaId,
  notificationEmail
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

set @process = 'Insert Permissions'
set @sql = 'if not exists (select 1 from ccPermissions where Description = ''Gestionar Segmentos'' )
begin
	Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
	FROM ccPermissions),''Gestionar Segmentos'',''RolesPermissionManageSegments'',0,0,0,''N/A'',1)
end

if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Gestionar Segmentos''))
begin
	INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Gestionar Segmentos''))
end


if not exists (select 1 from ccPermissions where Description = ''Cargar registros SMS por segmento'' )
begin
	Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
	FROM ccPermissions),''Cargar registros SMS por segmento'',''RolesPermissionLoadSMSSegments'',0,0,0,''N/A'',1)
end

if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Cargar registros SMS por segmento''))
begin
	INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Cargar registros SMS por segmento''))
end

if not exists (select 1 from ccPermissions where Description = ''Validaciones SMS Masivo'' )
begin
	Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
	FROM ccPermissions),''Validaciones SMS Masivo'',''RolesPermissionMassSMSValidation'',0,0,0,''N/A'',1)
end

if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Validaciones SMS Masivo''))
begin
	INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Validaciones SMS Masivo''))
end

if not exists (select 1 from ccPermissions where Description = ''Plantillas SMS Masivo'' )
begin
	Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
	FROM ccPermissions),''Plantillas SMS Masivo'',''RolesPermissionBulkSMSTemplates'',0,0,0,''N/A'',1)
end

if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Plantillas SMS Masivo''))
begin
	INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Plantillas SMS Masivo''))
end
'
EXEC(@sql)

--------------------------------------------------------- END KR134021 AND KR134022 -------------------------------------------------------------------

--------------------------------------------------------- BEGIN KR134016-Campaña SMS-Eliminar registros de día anterior -------------------------------------------------------------------
SET @process = 'KR134016 CREATE TABLE ccSmsSegments';
SET @sql = 'if not exists(select * from ccsettings2 where setting_id=268) begin
    insert into ccSettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
    values (268,''0'',''Setting para eliminar los registros SMS para MCA'',1,''GRL''
    ,''Eliminar Registros de las remesas para que el siguiente mande mensajes correctos''
    ,''Delete remittance records so that the next one sends correct messages'',0,''^[0-1]$'')
end
';
EXEC (@sql);

SET @process = 'KR134016 CREATE TABLE ccSmsSegments';
SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
@action int,
@camId int = null,
@SentMsg int=null,
@smsoutIds varchar(max)=null,
@SystemApiId varchar(100)=null,
@statusSystemsId int =null,
@InsufficientBalance int=null,
@date datetime =null,
@addingCampaign bit = null
as
declare @sql varchar(max)
if @action=1 begin
    set @date=getdate()

    if @addingCampaign = 1 begin
        select distinct cast(c. cam_id as int) as CamId,
                        cam_descripcion as [Name],
                        cam_procesando as [Start],
                        0 AS MessageQuantity
        from ccCamps c
        where CampType=7 and c.IDArea is not null and c.cam_id=@camId
    end
    else begin
        SELECT DISTINCT CAST(c. cam_id AS INT) AS CamId,
                        cam_descripcion AS Name,
                        cam_procesando AS Start,
                        ISNULL((w.new + w.pro),0) AS MessageQuantity
        FROM ccCamps c
        LEFT JOIN ccSmsSchedules s ON s.cam_id = c.cam_id
        LEFT JOIN ccCampsNvosCB  w ON c.cam_id = w.id
        WHERE CampType=7 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
        AND @date BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
    end
end
else if @action=2 begin
    select tz_offset from ccTimeZones ORDER BY tz_id
end
else if @action=3 begin
    select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
    from ccSmsConversationsResult where ( @camId is null or camId=@camId)
end
else if @action=4 begin
    truncate table ccSmsConversationsResult
end
else if @action=5 begin
    if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
        insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
    end
    else begin
        update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
        ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
        where camId=@camId
    end
end
else if @action=6 begin 
    set @sql=''delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')''
    exec (@sql)
end
else if @action=7 begin
    DECLARE @TemporalProcessingSmsStatusUpdates TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, StatusSystemsId INT, IsCharged BIT)
    INSERT INTO @TemporalProcessingSmsStatusUpdates
    SELECT SystemApiId, StatusSystemsId, IsCharged FROM ProcessingSmsStatusUpdates

    DECLARE @ChargedMessages INT = (SELECT SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END) FROM @TemporalProcessingSmsStatusUpdates)
    IF @ChargedMessages <> 0
    BEGIN
        UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - @ChargedMessages WHERE setting_id = 258 AND valor > 0;
    END

    DECLARE @UpdatingSmsWorkingTable TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, OldStatusSystemsId INT, NewStatusSystemsId INT, CampaignId INT)
    INSERT INTO @UpdatingSmsWorkingTable
    SELECT S.SystemApiId, S.StatusSystemsId, T.StatusSystemsId, S.cam_id FROM smsccoLogDial S WITH(NOLOCK)
    INNER JOIN @TemporalProcessingSmsStatusUpdates T ON S.SystemApiId = T.SystemApiId
            
    ;WITH CTE AS (
    SELECT
        CampaignId,
        COUNT(CASE WHEN NewStatusSystemsId = 0 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 0 THEN 1 END) AS SentMsg,
        COUNT(CASE WHEN NewStatusSystemsId = 1 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 1 THEN 1 END) AS Delivered,
        COUNT(CASE WHEN NewStatusSystemsId = 2 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 2 THEN 1 END) AS NotDelivered,
        COUNT(CASE WHEN NewStatusSystemsId = 3 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 3 THEN 1 END) AS RecipientRejected,
        COUNT(CASE WHEN NewStatusSystemsId = 4 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 4 THEN 1 END) AS CarrierRejected,
        COUNT(CASE WHEN NewStatusSystemsId = 5 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 5 THEN 1 END) AS Exception,
        COUNT(CASE WHEN NewStatusSystemsId = 6 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 6 THEN 1 END) AS InsufficientBalance

    FROM @UpdatingSmsWorkingTable
    GROUP BY CampaignId
    )

    MERGE INTO ccSmsConversationsResult AS Target
    USING CTE AS Source ON Target.camId = Source.CampaignId
    WHEN MATCHED THEN
        UPDATE SET
            Target.SentMsg = CASE WHEN (Target.SentMsg + Source.SentMsg) < 0 THEN 0 ELSE (Target.SentMsg + Source.SentMsg) END,
            Target.Delivered = CASE WHEN (Target.Delivered + Source.Delivered) < 0 THEN 0 ELSE (Target.Delivered + Source.Delivered) END,
            Target.NotDelivered = CASE WHEN (Target.NotDelivered + Source.NotDelivered) < 0 THEN 0 ELSE (Target.NotDelivered + Source.NotDelivered) END,
            Target.RecipientRejected = CASE WHEN (Target.RecipientRejected + Source.RecipientRejected) < 0 THEN 0 ELSE (Target.RecipientRejected + Source.RecipientRejected) END,
            Target.CarrierRejected = CASE WHEN (Target.CarrierRejected + Source.CarrierRejected) < 0 THEN 0 ELSE (Target.CarrierRejected + Source.CarrierRejected) END,
            Target.Exception = CASE WHEN (Target.Exception + Source.Exception) < 0 THEN 0 ELSE (Target.Exception + Source.Exception) END,
            Target.InsufficientBalance = CASE WHEN (Target.InsufficientBalance + Source.InsufficientBalance) < 0 THEN 0 ELSE (Target.InsufficientBalance + Source.InsufficientBalance) END

    WHEN NOT MATCHED BY TARGET THEN
    INSERT (camId, SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
    VALUES (Source.CampaignId, Source.SentMsg, Source.Delivered, Source.NotDelivered, Source.RecipientRejected, Source.CarrierRejected, Source.Exception, Source.InsufficientBalance);

    UPDATE smsccoLogDial SET Bill = (CASE WHEN T.StatusSystemsId IN (0, 1, 2) THEN 0.7 ELSE 0 END),
                                statusSystemsId = T.StatusSystemsId
    FROM smsccoLogDial S WITH(NOLOCK)
    INNER JOIN @TemporalProcessingSmsStatusUpdates T ON T.SystemApiId = S.SystemApiId

    DELETE FROM ProcessingSmsStatusUpdates 
    WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalProcessingSmsStatusUpdates);

    SELECT @@ROWCOUNT;
end
else if @action=8 begin
    update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
end
else if @action=9 begin
    CREATE TABLE #TempSmsOutIds (
    smsout_id INT
    );

    INSERT INTO #TempSmsOutIds (smsout_id)
    SELECT DISTINCT wt.smsout_id
    FROM smsWorkingTable wt
    JOIN smsOutSource os WITH(NOLOCK) ON wt.smsout_id = os.smsout_id
    LEFT JOIN smsccoLogDial cco WITH(NOLOCK) ON wt.smsout_id = cco.smsout_id
    WHERE wt.cam_id=@camId and wt.sms_status IN(1,2) 
    AND cco.smsout_id IS NULL;
            

    UPDATE wt
    SET wt.sms_status = 0
    FROM smsWorkingTable wt WITH(NOLOCK)
    JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

    DROP TABLE #TempSmsOutIds;
end
else if @action=10 begin
    SELECT COUNT(*) FROM smsWorkingTable with (NOLOCK) WHERE cam_id = @camId
end
else if @action=12 begin
    IF EXISTS (SELECT 1 FROM ccSmsSchedules WITH (NOLOCK) WHERE cam_id = @camId 
    AND GETDATE() BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
    )
    AND EXISTS (SELECT 1 FROM smsWorkingTable WITH (NOLOCK) WHERE cam_id = @camId)
    BEGIN
        SELECT CAST(0 AS BIT);
        RETURN;
    END
    ELSE BEGIN
        UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
        SELECT CAST(1 AS BIT);
        RETURN;
    END
end
else if @action=13 begin
    set @date=convert(DATE,getdate(),121)
    
    delete from smsWorkingTable where @camId is null or @camId=0 or cam_id=@camId AND sms_dateDial<@date
end';
EXEC (@sql);



--------------------------------------------------------- END KR134016-Campaña SMS-Eliminar registros de día anterior -------------------------------------------------------------------