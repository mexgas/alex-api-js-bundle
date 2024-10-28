/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/30
Description: Release 126.20240930.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
    	
                ------------------------------------------- BEGIN Isaac ----------------------------------------------------------
        SET @process = 'DEV2-681 - create identifier AllowReopenWAConversation'
		SET @sql = '
		IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AllowReopenWAConversation'')
        BEGIN
            INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''AllowReopenWAConversation'', ''Gestionar conversaciones (reabrir)'', 
            ''Manage conversations (reopen)'', ''Gerenciar conversas (reabrir)'') 
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-681 - create identifier AllowTransferWAConversation'
		SET @sql = '
		IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AllowTransferWAConversation'')
        BEGIN
            insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''AllowTransferWAConversation'', ''Gestionar conversaciones (transferir)'', 
            ''Manage conversations (transfer)'', ''Gerenciar conversas (transferir)'') 
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-681 - add column AllowReopenWAConversation to ccRIAAgentsPermissions'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''AllowReopenWAConversation'' AND Object_ID = Object_ID(N''ccRIAAgentsPermissions''))
        BEGIN
            ALTER TABLE ccRIAAgentsPermissions
            ADD AllowReopenWAConversation BIT NOT NULL DEFAULT(0)
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-681 - add column AllowTransferWAConversation to ccRIAAgentsPermissions'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''AllowTransferWAConversation'' AND Object_ID = Object_ID(N''ccRIAAgentsPermissions''))
        BEGIN
            ALTER TABLE ccRIAAgentsPermissions
            ADD AllowTransferWAConversation BIT NOT NULL DEFAULT(0)
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-682 - drop sp ccsp_GalateaAdminSetPermissions'
		SET @sql = '
		IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminSetPermissions'')
        BEGIN
            DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-682 - create sp ccsp_GalateaAdminSetPermissions'
		SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
@adminId SMALLINT,
@areaId SMALLINT,
@agentsIds VARCHAR(MAX),
@allAgentsSelected BIT, 
@permissionName VARCHAR(255),
@permissionValue INT
AS
SET NOCOUNT ON


declare @changeBitTable table(permissionName VARCHAR(255), valueBit int)

insert into @changeBitTable values(''AllowCellPhoneCalls'',1)
insert into @changeBitTable values(''startStopRecording'',1)
insert into @changeBitTable values(''XferManual'',1)
insert into @changeBitTable values(''AllowTransferCalls'',1)
insert into @changeBitTable values(''AgentPermissionDailing'',1)
insert into @changeBitTable values(''DailingMode'',1)
insert into @changeBitTable values(''AgentPermissionDelete'',1)
insert into @changeBitTable values(''AllowSelectCamp'',1)

insert into @changeBitTable values(''AllowLongDistanceCalls'',2)
insert into @changeBitTable values(''XferExt'',2)

insert into @changeBitTable values(''AllowLocalCalls'',4)
insert into @changeBitTable values(''XferCamps'',4)

insert into @changeBitTable values(''XferAgents'',8)

DECLARE @changeBit INT

set @changeBit=0

select @changeBit=valueBit from @changeBitTable where permissionName=@permissionName

--print(@changeBit)
IF @agentsIds IS NOT NULL
BEGIN
    DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
    INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

    IF @permissionName = ''AllowUnassign'' 
    BEGIN                       
        UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory, AllowReopenWAConversation, AllowTransferWAConversation)
        SELECT agentIds.AgentId , @permissionValue, 0, 0, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
    else IF @permissionName = ''AllowSpam''
    BEGIN 
        UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowSpam, AllowUnassign, AllowPlayRecordsOnCallHistory, AllowReopenWAConversation, AllowTransferWAConversation)
        SELECT agentIds.AgentId , @permissionValue, 0, 0, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END

	else IF @permissionName = ''AllowPlayRecordsOnCallHistory''
    BEGIN 
        UPDATE permissions SET permissions.AllowPlayRecordsOnCallHistory = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign, AllowReopenWAConversation, AllowTransferWAConversation)
        SELECT agentIds.AgentId , @permissionValue, 0, 0, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
    ELSE IF @permissionName = ''AllowReopenWAConversation''
    BEGIN
        UPDATE permissions SET permissions.AllowReopenWAConversation = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowReopenWAConversation, AllowTransferWAConversation, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign)
        SELECT agentIds.AgentId , @permissionValue, 0, 0, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
    ELSE IF @permissionName = ''AllowTransferWAConversation''
    BEGIN
        UPDATE permissions SET permissions.AllowTransferWAConversation = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowTransferWAConversation, AllowReopenWAConversation, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign)
        SELECT agentIds.AgentId , @permissionValue, 0, 0, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
	else 
	begin
		set @permissionValue= CASE
			WHEN @permissionName in(''AllowCellPhoneCalls'',''AllowLongDistanceCalls'',''AllowLocalCalls'')
			THEN  case when @permissionValue=1 then 0 else 1 end
			else @permissionValue end   
    
		UPDATE
			ccUsers
		SET DialMask =
			CASE
			WHEN @permissionName = ''AllowCellPhoneCalls''
			OR @permissionName = ''AllowLongDistanceCalls''
			OR @permissionName = ''AllowLocalCalls''
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (DialMask & @changeBit) <> @changeBit
					THEN DialMask ^ @changeBit
					ELSE DialMask
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (DialMask & @changeBit) = @changeBit
					THEN DialMask ^ @changeBit
					ELSE DialMask
					END
				END 
			ELSE DialMask
			END,
                        
			XferMask =
			CASE
			WHEN @permissionName = ''AllowTransferCalls''
			THEN
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (XferMask & @changeBit) <> @changeBit
					THEN XferMask ^ @changeBit
					ELSE XferMask
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (XferMask & @changeBit) = @changeBit
					THEN XferMask ^ @changeBit
					ELSE XferMask
					END
				END
			ELSE XferMask
			END,

			XferAgents =
			CASE
			WHEN @permissionName = ''XferAgents''
			OR @permissionName = ''XferCamps'' 
			OR @permissionName = ''XferExt'' 
			OR @permissionName = ''XferManual'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (XferAgents & @changeBit) <> @changeBit
					THEN XferAgents ^ @changeBit
					ELSE XferAgents
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (XferAgents & @changeBit) = @changeBit
					THEN XferAgents ^ @changeBit
					ELSE XferAgents
					END
				END
			ELSE XferAgents
			END,

			startStopRecording =
			CASE
			WHEN @permissionName = ''startStopRecording'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE startStopRecording
			END,

			DialingMode = 
			CASE
			WHEN @permissionName = ''DailingMode'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (DialingMode & @changeBit) <> @changeBit
					THEN DialingMode ^ @changeBit
					ELSE DialingMode
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (DialingMode & @changeBit) = @changeBit
					THEN DialingMode ^ @changeBit
					ELSE DialingMode
					END
				END 
			ELSE DialingMode
			END,
			AllowChangeDialingMode = 
			CASE
			WHEN @permissionName = ''AgentPermissionDailing'' 
			THEN 
				CASE
				WHEN @permissionValue = 3
				THEN 1
				WHEN @permissionValue = 2
				THEN 0
				END
			ELSE AllowChangeDialingMode
			END,
			AllowDeleteRecord= 
			CASE
			WHEN @permissionName = ''AgentPermissionDelete'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE AllowDeleteRecord
			END,
			AllowMarks= 
			CASE
			WHEN @permissionName = ''AllowMarks'' 
			THEN 
				CASE
				WHEN @permissionValue = 1 THEN 1
				WHEN @permissionValue = 0 THEN 0
				END
			ELSE AllowMarks
			END,
			allowselectcamp=
			CASE
			WHEN @permissionName = ''AllowSelectCamp'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE allowselectcamp
			END
		WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)
    end
                
    DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
    DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
    DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
    DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
    DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAAgentsPermissionsTags WHERE PermissionName = @permissionName)        
    DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
                                    FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
                                    WHERE permissions.Id = @Language + 1)

    DECLARE @AgentId INT = 0
    DECLARE @AgentName VARCHAR(20) = ''''

    set @Value = isnull(@Value,@permissionName)

    IF @allAgentsSelected = 0
    BEGIN
        WHILE EXISTS(SELECT * FROM @AgentIdsTemp WHERE Status = 0)
        BEGIN 
            SELECT TOP 1 @AgentId = AgentId FROM @AgentIdsTemp WHERE Status = 0
            SET @AgentName = (SELECT Login FROM ccUsers WHERE User_id = @AgentId)
                    
            EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
            @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                        
            UPDATE @AgentIdsTemp SET Status = 1 WHERE AgentId = @AgentId
        END
    END
    ELSE
    BEGIN
        SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
                    
        EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
        @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                        
        UPDATE @AgentIdsTemp SET Status = 1
    END


END

SET NOCOUNT OFF
        '
		EXEC(@sql)

        SET @process = 'DEV2-683 - drop sp ccsp_GalateaCreateUser'
		SET @sql = '
        IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaCreateUser'')
        BEGIN
            DROP PROCEDURE ccsp_GalateaCreateUser;
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-683 - create sp ccsp_GalateaCreateUser'
		SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUser]
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
AS
BEGIN


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
            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory, AllowReopenWAConversation, AllowTransferWAConversation)
            VALUES (@UserId, 0, 0, 1, 0, 0)
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
            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory, AllowReopenWAConversation, AllowTransferWAConversation)
            VALUES (@UserId, 0, 0, 1, 0, 0)
        END 
    END
    select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario
END
        '
		EXEC(@sql)

        SET @process = 'DEV2-684 - drop sp ccsp_GalateaAdminGetPermissions'
		SET @sql = '
        IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminGetPermissions'')
        BEGIN
            DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
        END
        '
		EXEC(@sql)

        SET @process = 'DEV2-684 - create sp ccsp_GalateaAdminGetPermissions'
		SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
@user_id varchar(255),
@Type int
AS
BEGIN
    set nocount on

    declare @isRoot int;

    if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
    print @isRoot

    IF @isRoot = 1
    BEGIN
        Select 
            User_id as AgentId, 
            Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
            1-cast(dialMask & 1 as int) as AllowCellPhoneCalls,
            1-cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
            1-cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
            cast( xfermask as int) as AllowTransferCalls, 
            cast(CanChangeStatus as tinyint) CanChangeStatus,
            cast(XferAgents as tinyint) XferAgents,
            ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
            cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
            ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
            ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
            ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
            ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
            ISNULL(agentsPermissions.AllowReopenWAConversation, 0) AS AllowReopenWAConversation,
            ISNULL(agentsPermissions.AllowTransferWAConversation, 0) AS AllowTransferWAConversation,
            cast(AllowDeleteRecord as int) as AgentPermissionDelete,
            AllowMarks as AllowMarks,
            ISNULL(allowSelectCamp,0) as AllowSelectCamp
        from 
            ccUsers users
            left join ccRIAAgentsPermissions agentsPermissions on
            users.User_id = agentsPermissions.AgentId
        where 
            tipoUser_id = 1
        return(0)
    END
    ELSE
    BEGIN
        Select distinct
            A.User_id as AgentId, 
            Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
            1-cast(dialMask & 1 as int) as AllowCellPhoneCalls,
            1-cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
            1-cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
            cast( xfermask as int) as AllowTransferCalls, 
            cast(CanChangeStatus as tinyint) CanChangeStatus,
            cast(XferAgents as tinyint) XferAgents,
            ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
            cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
            ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
            ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
            ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
            ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
            ISNULL(agentsPermissions.AllowReopenWAConversation, 0) AS AllowReopenWAConversation,
            ISNULL(agentsPermissions.AllowTransferWAConversation, 0) AS AllowTransferWAConversation,
            cast(AllowDeleteRecord as int) as AgentPermissionDelete,
            AllowMarks as AllowMarks,
            ISNULL(allowSelectCamp,0) as AllowSelectCamp
        from 
            ccUsers A
        join ccRIAWorkGroupUsers B on 
            A.user_id = B.user_id
        left join ccRIAAgentsPermissions agentsPermissions on
            A.User_id = agentsPermissions.AgentId
        where 
            tipoUser_id = 1 and 
            IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
        return(0)
    END
    set nocount off
END
        '
		EXEC(@sql)


        SET @process = 'DEV2-676 - drop function fn_GetMessagesByConversationOrMessageId'
		SET @sql = '
		if exists (select * from sys.objects where object_id = OBJECT_ID(N''fn_GetMessagesByConversationOrMessageId'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
		begin
			DROP FUNCTION fn_GetMessagesByConversationOrMessageId;
		end'
		EXEC(@sql)

        SET @process = 'DEV2-676 - create function fn_GetMessagesByConversationOrMessageId'
		SET @sql = '
CREATE FUNCTION fn_GetMessagesByConversationOrMessageId
(
    @CampType INT,                           -- Parameter to select the table (0 = Inbound, 1 = Outbound)
    @conversationId INT = NULL,              -- Optional parameter for filtering by conversationId
    @messageIdList NVARCHAR(MAX) = NULL      -- Optional parameter for filtering by a list of messageIds
)
RETURNS @Messages TABLE
(
    MessageId VARCHAR(150),	
    Status VARCHAR(50),
    Origin VARCHAR(50),	
    OriginType INT,
    Timestamp DATETIME,
    Content	VARCHAR(MAX),
    Type VARCHAR(20),
    Caption	VARCHAR(MAX),
    Url	VARCHAR(MAX),
    FileSize VARCHAR(20),
    FileName VARCHAR(MAX),
    Address	VARCHAR(MAX),
    Lat	VARCHAR(MAX),
    Long VARCHAR(MAX),
    Name VARCHAR(MAX),	
    LocationURL VARCHAR(MAX)
)
AS
BEGIN


    DECLARE @tmpMessageConversations TABLE(
            [messageId] VARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [conversationId] INT NOT NULL,
            [timeStampMessage] DATETIME NOT NULL,
            [originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [messageIdUi] INT NULL,
            [currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [timeStampMessageUTC] DATETIME NULL,
            [messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
        );
    DECLARE @baseFilePath VARCHAR(MAX)
    SELECT @baseFilePath = valor FROM ccSettings WHERE setting_id = 230

    IF (@CampType = 0)
    BEGIN
        INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
        SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
        FROM ccWAMessagesConversations
        WHERE 
        (@messageIdList IS NULL OR messageId IN (SELECT value FROM dbo.fn_RIASplitDelimited(@messageIdList, '','')))
        AND
        (@conversationId IS NULL OR conversationId = @conversationId)
    END
    IF (@CampType = 1)
    BEGIN
        INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
        SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
        FROM ccWAMessagesConversationsOut
        WHERE
        (@messageIdList IS NULL OR messageId IN (SELECT value FROM dbo.fn_RIASplitDelimited(@messageIdList, '','')))
        AND
        (@conversationId IS NULL OR conversationId = @conversationId)
    END

    INSERT INTO @Messages
    SELECT
        messageId AS MessageId,
        messageStatus AS Status,
        originType AS Origin,
        CASE 
            WHEN originType =''Client'' THEN 3
            WHEN originType =''Agent'' THEN 2
            WHEN originType =''Admin'' THEN 1
            ELSE 0 
        END AS OriginType,
        timeStampMessage AS [Timestamp],
        CASE 
            WHEN typeMessage IN (''text'', ''template'') THEN content
            ELSE '''' 
        END AS Content,
        typeMessage AS Type,
        CASE
            WHEN originType = ''Client''
            THEN
                CASE
                    WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
                    WHEN typeMessage IN (''image'', ''video'')
                    THEN 
                        CASE 
                            WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2) = 0  -- soporte con mensajes de vonage
                            THEN content
                            ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
                        END
                    ELSE ''''
                END
            WHEN originType = ''Agent''
            THEN
                CASE
                    WHEN typeMessage = ''file''
                    THEN
                        CASE 
                            WHEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2) <> (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
                            THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
                            ELSE ''''
                        END
                    WHEN typeMessage IN (''image'', ''video'')
                    THEN
                        CASE
                            WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2) <> 0  -- soporte con mensajes de vonage
                            THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2)
                            ELSE ''''
                        END
                    ELSE ''''
                END
        END AS Caption,
        CASE 
            WHEN originType = ''Client'' THEN
                CASE
                    WHEN 
                        (typeMessage = ''text'' 
                        OR typeMessage = ''location''
                        OR (typeMessage = ''file'' 
                            AND 
                            (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2) = '''' )
                        )
                    THEN ''''
                    WHEN typeMessage = ''file''
                    THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 2), ''l:'') WHERE Id = 2)
                    WHEN typeMessage IN (''image'', ''video'')
                    THEN
                        CASE
                            WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 4), '':'') WHERE Id = 2) = 0 -- soporte con mensajes de vonage
                            THEN (@baseFilePath + CHAR(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + CHAR(92) + CAST(conversationId/1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + CHAR(92) + typeMessage + CHAR(92) + messageId + CASE WHEN typeMessage = ''video'' THEN ''.mp4'' WHEN typeMessage = ''image'' THEN ''.jpg'' END)
                            ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 2), ''l:'') WHERE Id = 2)
                        END
                    WHEN typeMessage = ''audio''
                    THEN
                        CASE
                            WHEN content = ''''
                            THEN (@baseFilePath + CHAR(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + CHAR(92) + CAST(conversationId/1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + CHAR(92) + typeMessage + CHAR(92) + messageId + ''.mp3'')
                            ELSE content
                        END
                END
            WHEN originType = ''Agent'' THEN
                CASE
                    WHEN typeMessage IN (''text'', ''location'', ''template'') THEN ''''
                    WHEN typeMessage  = ''file'' THEN (SELECT SUBSTRING(Value, 5, LEN(Value)) FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2)
                    WHEN typeMessage IN (''image'', ''video'')
                    THEN
                        CASE
                            WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 4), '':'') WHERE Id = 2) = 0
                            THEN content
                            ELSE (SELECT SUBSTRING(Value, 5, LEN(Value)) FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2)
                        END
                    WHEN typeMessage = ''audio'' THEN content
                END
        END AS [Url],
        CASE 
            WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2)
            WHEN typeMessage IN (''image'', ''video'')
            THEN
                CASE
                    WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2) = 0 -- soporte con mensajes de vonage
                    THEN ''''
                    ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2)
                END
            ELSE '''' 
        END AS [FileSize],
        CASE 
            WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
            WHEN typeMessage IN (''image'', ''video'')
            THEN
                CASE
                    WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2) = 0 -- soporte con mensajes de vonage
                    THEN ''''
                    ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2)
                END
            ELSE '''' 
        END AS [FileName],
        CASE 
            WHEN 
                typeMessage = ''location''
            THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 1),'':'') WHERE id=2) 
            ELSE '''' 
        END AS [Address],
        CASE 
            WHEN 
                typeMessage = ''location''
            THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2) 
            ELSE '''' 
        END AS [Lat],
        CASE
            WHEN 
                typeMessage = ''location''
            THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2) 
            ELSE '''' 
        END AS [Long],
        CASE 
            WHEN 
                typeMessage = ''location''
            THEN  (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 4),'':'') WHERE id=2) 
            ELSE '''' 
        END AS [Name],
        CASE 
            WHEN 
                typeMessage = ''location''
            THEN 
                (''https://www.google.com/maps/search/'' + 
                (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 2),'':'') WHERE id=2) + '','' +
                (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE id = 3),'':'') WHERE id=2)) 
            ELSE '''' 
        END AS [LocationURL]
    FROM @tmpMessageConversations
    ORDER BY Timestamp ASC

    RETURN;
END'
		EXEC(@sql)

        SET @process = 'DEV2-676 - drop sp ccsp_AgentHistoricalChat' 
		SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_AgentHistoricalChat'')
		begin
			DROP PROCEDURE ccsp_AgentHistoricalChat;
		end'
		EXEC(@sql)

        SET @process = 'DEV2-676 - create sp ccsp_AgentHistoricalChat '
		SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
@option SMALLINT, 
@clientNum VARCHAR(15) = '''', 
@conversationId AS INT = 0, 
@inboundId AS SMALLINT = 0, 
@serviceType AS SMALLINT = 0,
@campType AS INT = 0
AS
BEGIN
    IF @option = 1 --whatsapp, get conversation ids
    BEGIN
        DECLARE @tempId INT = 0
        IF @campType = 0 -- INBOUND
        BEGIN
            SELECT conversationId AS ConversationId,
                @campType AS CampType,
                assignDate AS Date
            FROM ccWhatsAppConversations with(nolock)
            WHERE clientId = @clientNum AND assignDate IS NOT NULL
            GROUP BY conversationId, assignDate
        END
        ELSE
        BEGIN  -- OUTBOUND
            SELECT conversationId AS ConversationId,
                @campType AS CampType,
                assignDate AS Date
            FROM ccWhatsAppConversationsOut with(nolock)
            WHERE clientId = @clientNum AND assignDate IS NOT NULL
            GROUP BY conversationId, assignDate
        END
    END

    IF @option = 2 --whatsapp, get acdId by conversation id
    BEGIN
        IF @campType = 0
        BEGIN
            SELECT CAST(inboundId AS INT)
            FROM [ccWhatsAppConversations] with(nolock)
            WHERE conversationId = @conversationId
        END
        ELSE
        BEGIN
            SELECT CAST(camId AS INT)
            FROM [ccWhatsAppConversationsOut] with(nolock)
            WHERE conversationId = @conversationId
        END
    END

    IF @option = 3 --get data conversation
    BEGIN
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0

        SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
        FROM ccWhatsAppConversationsRelationship rel with(nolock)
        RIGHT JOIN ccWhatsAppConversations conv with(nolock) ON conv.conversationId = rel.conversationIdBefore
        WHERE rel.conversationIdAfter = @conversationId

        SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
                graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
            [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
            [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
            OldConversationId, c.agentId AS AgentId
        FROM ccInbound i
        INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
        INNER JOIN ccWhatsAppConversations c with(nolock) ON (
                c.inboundId = i.Inbound_id
                AND c.conversationId = @conversationId
                )
        INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
        WHERE i.chat = @serviceType
            AND i.Inbound_id = @inboundId

    END

    IF @option = 4 --get messages from conversation id
    BEGIN
        DECLARE @filetype AS VARCHAR(5)
        DECLARE @camp_acd_id INT = 0;

        IF @campType = 0
        BEGIN
            SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations with(nolock) WHERE conversationId = @conversationId)

			SELECT
				msg.*,
				graphics.graphic_id AS GraphicId
			FROM dbo.fn_GetMessagesByConversationOrMessageId(@campType, @conversationId, NULL) AS msg
            LEFT JOIN ccRIAInboundGraph graphics ON Inbound_id = @camp_acd_id
            ORDER BY msg.TIMESTAMP ASC
        END
        ELSE
        BEGIN
            SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) WHERE conversationId = @conversationId)

			SELECT
				msg.*,
				graphics.graphic_id AS GraphicId
			FROM dbo.fn_GetMessagesByConversationOrMessageId(@campType, @conversationId, NULL) AS msg
            LEFT JOIN ccRIACampsGraph graphics ON cam_id = @camp_acd_id
            ORDER BY msg.TIMESTAMP ASC
        END
                
    END

    IF @option = 5 --get if conversation is reassigned
    BEGIN
        IF @campType = 0
        BEGIN
            SELECT CASE 
                WHEN EXISTS (
                        SELECT *
                        FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship] with(nolock)
                        WHERE conversationIdAfter = @conversationId
                        )
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
                END
        END
        ELSE
        BEGIN
            SELECT CASE 
                WHEN EXISTS (
                        SELECT *
                        FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut] with(nolock)
                        WHERE conversationIdAfter = @conversationId
                        )
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
                END
        END
    END
END
        '
        EXEC(@sql)

        SET @process = 'DEV2-676 - drop function fn_RIASplitDelimited'
		SET @sql = '
		if exists (select * from sys.objects where object_id = OBJECT_ID(N''fn_RIASplitDelimited'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
		begin
			DROP FUNCTION fn_RIASplitDelimited;
		end'
		EXEC(@sql)

        SET @process = 'DEV2-676 - create function fn_RIASplitDelimited'
		SET @sql = '
CREATE FUNCTION fn_RIASplitDelimited
( 
	@List nvarchar(MAX),
	@SplitOn varchar(20)
)
RETURNS @RtnValue table (
	Id int identity(1,1),
	Value nvarchar(MAX)
)
AS
BEGIN
	While (Charindex(@SplitOn,@List)>0)
	Begin 
		Insert Into @RtnValue (value)
		Select 
			Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
		Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
	End 
  
	Insert Into @RtnValue (Value)
	Select Value = ltrim(rtrim(@List))

	Return
END'
		EXEC(@sql)

        SET @process = 'K020118 Editar plantillas para campañas de Whatsapp - drop sp ccsp_MetaWAOutboundTemplates' 
		SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
		begin
			DROP PROCEDURE ccsp_MetaWAOutboundTemplates;
		end'
		EXEC(@sql)

        SET @process = 'K020118 Editar plantillas para campañas de Whatsapp - create sp ccsp_MetaWAOutboundTemplates '
		SET @sql = '
CREATE PROCEDURE ccsp_MetaWAOutboundTemplates
@action TINYINT = NULL,
@whatsAppTemplateID BIGINT = 0,
@id varchar(200) = NULL,
@Category varchar(50) = NULL,
@TemplateName varchar(512) = NULL,
@AllowCategoryChange tinyint = NULL,
@LanguageCode varchar(10)= NULL,
@Status varchar(200)= NULL, 
@header nvarchar(max)= null,
@body nvarchar(max) = null,
@footer nvarchar(max) = null,
@buttons nvarchar(max) = null,
@metaStatus varchar(30) = NULL,
@FilePath varchar(1024) = null,
@HistoryLog varchar(max) = null,
@campId SMALLINT = NULL,
@UserId	SMALLINT = 0,
@MetaId INT = 0
AS
BEGIN
    IF(@action = 1) -- get template by id
    BEGIN
        SELECT 
        cmwot.Id 
        ,cmwot.TemplateName AS Name
        ,cmwot.Status AS Status
        ,Category AS Category
        ,ISNULL(cmwot.notes, '''' ) AS Notes
        ,cmwot.header AS Header
        ,Body
        ,cmwot.footer AS Footer
        ,cmwot.buttons AS Buttons
        ,cmwot.LanguageCode
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,cmwot.FilePath
        ,cmwot.Status AS Status
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        WHERE cmwot.Id = @whatsAppTemplateID
    END
    ELSE IF(@action = 2)
    BEGIN
        SELECT cmwan.MetaId AS Id, cmwan.Number FROM dbo.ccMetaWhatsAppNumbers AS cmwan
        Left JOIN dbo.ccMetaWhatsAppConfigurations AS cmwac
        ON cmwan.MetaId = cmwac.Id
        WHERE cmwan.Status = 1
    END
    ELSE IF(@action = 3)
    BEGIN
        UPDATE ccMetaWAOutboundTemplates SET StatusCW = 0 WHERE Id = @whatsAppTemplateID
        SELECT @@ROWCOUNT;
        RETURN 0;
    END
    ELSE IF(@action = 4) --create
    BEGIN
        insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons,FilePath,MetaId,StatusCW)
                            values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons,@FilePath,@MetaId,1)
    END
    ELSE IF(@action = 5) -- Get Template Config By Id
    BEGIN
        SELECT n.WAAccountId, n.Token, c.Url as [Url], t.TemplateName 
        FROM ccMetaWAOutboundTemplates t
        INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
        left JOIN ccMetaWhatsAppConfigurations c on c.Id = 2
        WHERE t.Id = @whatsAppTemplateID
        RETURN 0;
    END
    ELSE IF(@action = 6) -- update status to delete
    BEGIN
        DECLARE @newStatus bit = 1;
        IF(@metaStatus = ''DELETED'')
        BEGIN
            SET @newStatus = 0
        END
        UPDATE ccMetaWAOutboundTemplates SET 
        [Status] = @metaStatus, 
        StatusCW = @newStatus,
        RemovalDate = ISNULL(RemovalDate, GETDATE())
        WHERE Id = @whatsAppTemplateID
        AND [StatusCW] = 1;
        SELECT @@ROWCOUNT;
        RETURN 0;
    END
    ELSE IF(@action = 7) -- Get template campaigns associated
    BEGIN
        SELECT ISNULL(n.Cam_Id,0) as Cam_Id, ISNULL(n.Inbound_Id,0) AS Inbound_Id FROM ccMetaWAOutboundTemplates t
        INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
        left JOIN ccMetaWhatsAppConfigurations c on n.MetaId = c.Id
        WHERE t.Id = @whatsAppTemplateID
        RETURN 0;
    END
    ELSE IF (@action = 8) -- update template
    BEGIN
        DECLARE @tableHistoryLog TABLE (Id INT, Value VARCHAR(MAX))
        DECLARE @areaName VARCHAR(50),
                @login VARCHAR(50)

        SELECT
            @areaName = ca.AreaName,
            @login = cu.Login
        FROM ccUsers cu
        INNER JOIN ccRIACat_Areas ca with(nolock) ON cu.IDArea = ca.IDArea
        WHERE cu.User_id = @UserId

        INSERT INTO @tableHistoryLog 
        SELECT tb.Id, tb.Value
        FROM dbo.fn_RIASplitDelimited(@HistoryLog, '',,'') tb


        -- insert into activity log table and update template data
        IF (@header IS NULL OR LEN(@header) = 0) AND (SELECT LEN(ISNULL(header,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when header is null or '''' and before update header contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'',''COMMON_NONE_O'',@TemplateName)
        END
        IF (@footer IS NULL OR LEN(@footer) = 0) AND (SELECT LEN(ISNULL(footer,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when footer is null or '''' and before update footer contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'',''COMMON_NONE_O'',@TemplateName)
        END
        IF (@buttons IS NULL OR LEN(@buttons) = 0) AND (SELECT LEN(ISNULL(buttons,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when buttons is null or '''' and before update buttons contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'',''COMMON_NONE_O'',@TemplateName)
        END
        
        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccMetaWAOutboundTemplates'', @columnNameId=''Id'', @valueId= @Id, @userId= 1
        Create table #ccMetaWAOutboundTemplates 
        (
            columnInfo VARCHAR(MAX),
            dataInfo VARCHAR(MAX),
            identifierInfo VARCHAR(MAX)
        )

        UPDATE ccMetaWAOutboundTemplates
        SET Category = @Category,
            header = @header,
            body = @body,
            footer = @footer,
            buttons = @buttons,
            FilePath = @FilePath
        WHERE Id = @Id

        EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccMetaWAOutboundTemplates'', @columnNameId = ''Id'', @valueId = @Id, @userId = 1,  @tableTemp=''#ccMetaWAOutboundTemplates'';

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            @areaName,
            GETDATE(),
            @login,
            122,
            20,
            cc.identifierInfo,
            tb1.Value,
            @TemplateName
        FROM #ccMetaWAOutboundTemplates cc
        INNER JOIN  @tableHistoryLog  tb1 ON cc.columnInfo = (CASE 
                                                                WHEN tb1.Id = 1 THEN ''Category''
                                                                WHEN tb1.Id = 2 THEN ''header'' 
                                                                WHEN tb1.Id = 3 THEN ''body'' 
                                                                WHEN tb1.Id = 4 THEN ''footer''
                                                                WHEN tb1.Id > 4 THEN ''buttons''
                                                                END)
    END
    else IF(@action = 9) -- get templates by phone number
    BEGIN
        ;WITH tb1 as(
            SELECT
                gal.Target AS TemplateName,
                MAX(gal.ActivityDate) AS Date
            FROM ccGalateaActivityLog gal 
            WHERE gal.OperationId = 122 
            AND gal.ModuleId = 20 
            AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
            GROUP BY gal.Target, CAST(gal.ActivityDate AS DATE)
        )
        ,TemplateIsEditable AS (
            SELECT
                tb1.TemplateName,
                CASE WHEN COUNT(*) >= 10 THEN 2 WHEN MAX(tb1.Date) >= DATEADD(HOUR, -24, GETDATE()) THEN 1 ELSE 0 END AS IsEditable
            FROM tb1
            GROUP BY tb1.TemplateName
        )
        SELECT 
        cmwot.Id 
        ,cmwot.TemplateName AS Name
        ,cmwot.Status AS Status
        ,Category AS Category
        ,ISNULL(cmwot.notes, '''' ) AS Notes
        ,cmwot.header AS Header
        ,Body
        ,cmwot.footer AS Footer
        ,cmwot.buttons AS Buttons
        ,cmwot.LanguageCode
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,ISNULL(tie.IsEditable, 0) AS IsEditable
        ,cmwot.FilePath
        FROM  dbo.ccMetaWAOutboundTemplates cmwot
        LEFT JOIN TemplateIsEditable tie ON tie.TemplateName = CAST(cmwot.TemplateName AS VARCHAR(MAX))
        WHERE cmwot.MetaId = @whatsAppTemplateID
        AND cmwot.StatusCW = 1
    END
    ELSE IF(@action = 10) -- Check if an other load is executing for the campaign
    BEGIN
        SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT , 1) ELSE CONVERT(BIT, 0) END AS IsProcessExecuting FROM dbo.ccRIALoading AS crl
        WHERE crl.cam_id = @campId AND crl.state IN (0,2) AND crl.loadType = 3;
    END
    ELSE IF(@action = 11) --Check if the campaign was eliminated or desasigned
    BEGIN
        DECLARE @campaignIsEliminateDesasigned BIT = 0;
        DECLARE @idAreaNull SMALLINT = 0;

        SELECT  @idAreaNull = cc.IDArea FROM dbo.ccCamps AS cc WHERE cc.cam_id = @campId

        IF(@idAreaNull IS NULL)
        BEGIN
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue eliminada
        END

        IF NOT EXISTS(SELECT TOP 1 crcew.IdCampEsp FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu
        ON crwgu.IDWG = crcew.IDWG
        WHERE crwgu.User_id = @UserId AND crcew.Tipo = 1 AND crcew.IdCampEsp = @campId)
        BEGIN 
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue desasignada del grupo de trabajo
        END

        SELECT @campaignIsEliminateDesasigned;
    END
    ELSE IF(@action = 12) --Get new numbers loaded in  ccWhatsAppOutSource 
    BEGIN
        SELECT cwt.Callkey FROM dbo.ccoWAWorkingTable AS cwt WHERE cwt.CamId = @campId AND cwt.WaStatus = 0
        UNION
        SELECT cwaos.CallKey FROM dbo.ccWhatsAppOutSource AS cwaos 
        WHERE cwaos.camId = @campId AND cwaos.Status = 0
    END
    IF(@action = 13) -- Get templates by campaign number assigned
    BEGIN
        SELECT 
        cmwot.Id 
        ,cmwot.TemplateName AS Name
        ,cmwot.Status AS Status
        ,Category AS Category
        ,ISNULL(cmwot.notes, '''' ) AS Notes
        ,cmwot.header AS Header
        ,Body
        ,cmwot.footer AS Footer
        ,cmwot.buttons AS Buttons
        ,cmwot.LanguageCode
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,cmwot.FilePath
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan ON 
        cmwot.MetaId = cmwan.MetaId
        WHERE cmwot.StatusCW = 1 AND cmwan.Cam_Id = @campId AND cmwot.Status = ''APPROVED''
    END
    ELSE IF (@action = 14) -- check if campaing exists
    BEGIN
        IF EXISTS(SELECT 1 FROM dbo.ccMetaWAOutboundTemplates cmwot WHERE cmwot.Id = @whatsAppTemplateID)
            SELECT 1
        ELSE
            SELECT 0
    END
END
        '
        EXEC(@sql)

        -------------------------------------------  END Isaac  ----------------------------------------------------------
    	
		------------------------------------------------- BEGIN Frida----------------------------------------------------------------------------------
		SET @process = 'DEV2-631 - drop sp ccsp_MultimediaCommon'
		SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
		begin
			DROP PROCEDURE ccsp_MultimediaCommon;
		end
			'
		EXEC(@sql)

		SET @process = 'DEV2-631 - create sp ccsp_MultimediaCommon '
		SET @sql = '
		
CREATE PROCEDURE ccsp_MultimediaCommon
@Option AS SMALLINT,
@inboundId AS SMALLINT = 0,
@conversationId AS INT = 0,
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0,
@messagesList as varchar(max) = '''',
@agentId AS SMALLINT = 0,
@CampType bit =0,
@phoneNumber varchar(30)='''',
@campaignNumber VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET @phoneNumber = NULLIF(@phoneNumber, '''');
    IF @Option = 0 --  Obtener lista de configuraciones de campañas
    BEGIN
        SELECT CAST(campaign.cam_id AS INT) AS Id,
               campaign.cam_descripcion AS [Name],
               ISNULL(configuration.number, '''') AS Phone,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               0 AS isMeta
        FROM ccCamps campaign 
        INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
        INNER JOIN ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id
        WHERE configuration.status != 0 AND campaign.CampType = 5

        UNION ALL

        SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
               campaign.cam_descripcion AS [Name],
               ISNULL(configuration.number, '''') AS Phone,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               1 AS isMeta
        FROM ccCamps campaign 
        INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
        INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
        WHERE configuration.status != 0 AND campaign.CampType = 5   
                                                            
    END

    ELSE IF @Option = 1 -- Obtener lista de configuraciones de ACDs
    BEGIN
        SELECT CAST(inbound.Inbound_id AS INT) AS Id,
               inbound.descripcion AS [Name],
               ISNULL(numbers.number, '''') AS Phone,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               0 AS isMeta
        FROM ccInbound inbound
        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
        INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId  
        WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 

        UNION ALL

        SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
               inbound.descripcion AS [Name],
               ISNULL(numbers.number, '''') AS Phone,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               1 AS isMeta
        FROM ccInbound inbound
        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
        INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id
        WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 
                                                            
    END

     ELSE IF(@Option = 2)
    BEGIN
		SET @phoneNumber = NULLIF(@phoneNumber, '''');
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0
		DECLARE @isMeta BIT
		select @isMeta = CAST(IsMeta AS BIT) from ccAllWhatsAppNumbers with (nolock) where Number=@phoneNumber

        IF @CampType = 0 BEGIN -- ACD
            SELECT @OldAgentId = conv.agentId,
                   @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationship rel 
            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT CAST(i.chat AS int) AS ServiceType,
                   CAST(c.conversationId AS int) AS ConversationID,
                   c.clientId AS ClientId,
                   cm.conexionInfo AS [To],
                   CAST(i.Inbound_id AS int) AS ACDId,
                   i.descripcion AS ACDName,
                   CAST(g.graphic_id AS int) AS ACDGraphicId,
                   CAST(cm.closeConversationTime AS int) AS [TimeOut],
                   CAST(cm.answerTimeOut AS int) AS [TimeOutWarning],
                   i.ExitWrapUpDisposition AS [ExitWrapUpDisposition],
                   i.tNotas AS [WrapUpTime],
                   i.ShowCalifWnd,
                   CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                   ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                   ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                   ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                   ISNULL(@OldAgentId, 0) AS OldAgentId,
                   ISNULL(@OldConversationId, 0) AS OldConversationId,
                   c.agentId AS AgentId,
                   ISNULL(c.IsAgentLoggingOut, 0) AS IsAgentLoggingOut,
                   ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments,
				   c.conversationDate AS ConversationDate,
				   @isMeta AS IsMeta
            FROM ccWhatsAppConversations c
            LEFT JOIN ccInbound i ON c.inboundId = i.Inbound_id 
            LEFT JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId    
            LEFT JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
            LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
            WHERE c.conversationId = @conversationId

        END ELSE BEGIN -- Campaña
            SELECT @OldAgentId = conv.agentId,
                   @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationshipOut rel 
            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT CAST(i.CampType AS int) AS ServiceType,
                   CAST(c.conversationId AS int) AS ConversationID,
                   c.clientId AS ClientId,
                   c.phoneCamp AS [To],
                   CAST(i.cam_id AS int) AS ACDId,
                   i.cam_descripcion AS ACDName,
                   CAST(g.graphic_id AS int) AS ACDGraphicId,
                   CAST(cm.closeConversationTime AS int) AS [TimeOut],
                   CAST(cm.answerTimeoutClient AS int) AS [TimeOutWarning],
                   i.exitAssisted AS [ExitWrapUpDisposition],              
                   CAST(i.cam_tnotas AS int) AS [WrapUpTime],
                   i.cam_ShowCalifWnd AS ShowCalifWnd, 
                   CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                   ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                   ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                   ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                   ISNULL(@OldAgentId, 0) AS OldAgentId,
                   ISNULL(@OldConversationId, 0) AS OldConversationId,
                   c.agentId AS AgentId,
                   ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments,
				   c.conversationDate AS ConversationDate
            FROM ccWhatsAppConversationsOut c
            LEFT JOIN ccCamps i ON c.camId = i.cam_id 
            LEFT JOIN contactMeanOut cm ON c.camId = cm.camp_id
            LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
            WHERE c.conversationId = @conversationId
        END
    END
    
     ELSE IF(@Option = 3)
    BEGIN
        IF @CampType = 0 BEGIN -- ACD
            SELECT CAST(inbound.Inbound_id AS INT) AS Id,
                   inbound.descripcion AS Name,
                   ISNULL(configuration.conexionInfo, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                   inbound.tNotas AS WrapUpTime,
                   CAST(ISNULL(graphics.graphic_id, 1) AS INT) AS GraphicId,
                   0 AS isMeta
            FROM ccInbound inbound
            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
            INNER JOIN ccWhatsAppNumbers von ON von.inboundId = inbound.Inbound_id
            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
            WHERE inbound.Inbound_id = @inboundId

            UNION ALL

            SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
                   inbound.descripcion AS [Name],
                   ISNULL(numbers.number, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                   inbound.tNotas AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   1 AS isMeta
            FROM ccInbound inbound
            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
            INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id 
            WHERE inbound.Inbound_id = @inboundId       
        END ELSE BEGIN
            SELECT CAST(campaign.cam_id AS INT) AS Id,
                   campaign.cam_descripcion AS [Name],
                   ISNULL(configuration.conexionInfo, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
                   CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   0 AS isMeta
            FROM ccCamps campaign
            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
            INNER JOIN ccWhatsAppNumbers von ON von.camp_id = campaign.cam_id
            INNER JOIN contactMeanOut configuration ON campaign.cam_id = configuration.camp_id 
            WHERE campaign.cam_id = @inboundId

            UNION ALL

            SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
                   campaign.cam_descripcion AS [Name],
                   ISNULL(configuration.number, '''') AS Phone,
                   CAST(ISNULL(configurationOut.answerTimeoutClient, 0) AS int) AS TimeOut,
                   CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   1 AS isMeta
            FROM ccCamps campaign 
            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
            INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
            INNER JOIN contactMeanOut configurationOut ON (campaign.cam_id = configurationOut.camp_id AND campaign.cam_id = @inboundId)
            WHERE campaign.cam_id = @inboundId
        END
    END

    ELSE IF(@Option = 4)
    Begin
		SELECT
		*
		FROM dbo.fn_GetMessagesByConversationOrMessageId(@CampType, NULL, @messagesList)
    END
                                                                            
    ELSE IF(@Option = 5)
    BEGIN
        if @CampType =0 begin
            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                FROM contactMeanIn
            WHERE inboundId = @inboundId
        end 
        else begin
            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                FROM contactMeanOut
            WHERE camp_id = @inboundId
        end 
    END
    ELSE IF(@Option = 6)
    BEGIN
        SELECT [Login] AS ''OriginName''
            FROM [ccUsers]
        WHERE [User_id] = @agentId
    END
	ELSE IF(@Option = 7)
    BEGIN
		IF @CampType = 0 BEGIN
        -- No se sabe si se va a implementar
        SELECT -1
        END 
        ELSE BEGIN
			SELECT CAST(ISNULL(maxLimitQueueConversations,99) AS INT) AS MaxLimitQueueConversations 
            FROM contactMeanOut
            WHERE conexionInfo = @campaignNumber
        END 
    END
END'
		EXEC(@sql)

		SET @process = 'DEV2-631 - create setting 279 '
		SET @sql = '
		if not exists (select * from ccSettings2 where setting_id=279)
		begin
			insert into ccsettings2 (setting_id,valor,Status,Tipo,descripcion,detalle,description,bLoadSettings) values 
			(279,''C:/Multimedia/Conversations/WhatsApp|E:/CenterWare/WhatsApp'',1,''AGT'',''Ruta donde están guardados los archivos de las conversaciones de whatsApp'',''Ruta donde están guardados los archivos de las conversaciones de whatsApp'',
			''Path where the conversation files are saved'',1)
		end
			'
		EXEC(@sql)

		------------------------------------------- END Frida ----------------------------------------------------------

        ------------------------------------------- BEGIN Carlos Muñoz ----------------------------------------------------------
        set @process = 'K002151 Insert menu for deassignment reports'
		set @sql = 'if not exists (select 1 from ccMenus where menu_id = 12015)
		begin
            INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
            VALUES (12015, ''Detalle de desasignaciones|Deassignments details'', 12000, ''B'', 7, 3, '''', ''9a05140d99e34def9554e1bc34862113a197a3b3a6f96c5973200bde9d74c5d56671efd486ce9b4817c4b2bd3a2781ee4483f8fd82006fd0898f038e1f58f056'')
		end'
		EXEC(@sql)

        set @process = 'K002151 Insert user-menu for deassignment reports'
        set @sql = '
        IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 12015)
        BEGIN
            INSERT INTO ccMenuUser(id_User, id_Menu, type) 
            VALUES (1, 12015, 3)
        END'
        EXEC(@sql)
        
        set @process = 'K002152 Insert menu for spam reports'
		set @sql = 'if not exists (select 1 from ccMenus where menu_id = 12017)
		begin
            INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
            VALUES (12017, ''Detalle de conversaciones enviadas a SPAM|Detail of conversations sent to SPAM'', 12000, ''B'', 7, 3, '''', ''4a80200b610ac847a8d8adb01a398ddd7beb4c96b0314a257dca209b43d0fbbb79cba6c047a2df9772cfd4dded5925d629b0be059c1a8306f9c97ab6712b73d433c513c5e787039a9a54df821e61cfe6'')
		end'
		EXEC(@sql)

        set @process = 'K002152 Insert user-menu for spam reports'
        set @sql = '
        IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 12017)
        BEGIN
            INSERT INTO ccMenuUser(id_User, id_Menu, type) 
            VALUES (1, 12017, 3)
        END'
        EXEC(@sql)

        ------------------------------------------- END Carlos Muñoz ----------------------------------------------------------

        ------------------------------------------- BEGIN Ivan Martin Fix ----------------------------------------------------------
        set @process = 'Fix para totales de mensajes en monitoreo de campañas de salida. Cambios en action 16 para validar numeros negativos y no tomar en cuenta los mensajes del cliente en la suma.'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
				                    , @conversationId     INT         = 0
				                    , @camId          SMALLINT    = NULL
				                    , @phoneCam           VARCHAR(50) = NULL
				                    , @clientId           VARCHAR(25) = NULL
				                    , @conversationStatus SMALLINT    = 0
				                    , @tChatting          FLOAT    = 0
				                    , @tWrapUp            SMALLINT    = 0
				                    , @finishedBy         TINYINT     = 0
				                    , @onQueue            BIT         = NULL
				                    , @tQueue             SMALLINT    = 0
				                    , @tTimeout           INT         = 0
				                    , @disposition        SMALLINT    = 0
				                    , @subDisposition     SMALLINT    = 0
				                    , @agentId            INT         = 0
				                    --VAR MESSAGES
				                    , @messageId          VARCHAR(150) = NULL
				                    , @messageIdUi        INT         = NULL
				                    , @clientNum          VARCHAR(15) = NULL
				                    , @vonageNum          VARCHAR(15) = NULL
				                    , @typeMessage        VARCHAR(25) = ''''
				                    , @content            NVARCHAR(MAX)= NULL
				                    , @timeStampMessage   DATETIME    = NULL
				                    , @timeStampMessageUTC DATETIME   = NULL
				                    , @originType         VARCHAR(15) = NULL
				                    , @currency           VARCHAR(10) = ''-''
				                    , @price              VARCHAR(10) = ''0.00''
				                    , @messageStatus      VARCHAR(15) = ''N/A''
				                    , @listConversationsIds   VARCHAR(MAX) = NULL
				                    , @IsAgentLoggingOut  BIT = 0
									, @ConvId             INT = NULL OUTPUT
				                    AS
				                    BEGIN
				                        DECLARE @isEndConversation BIT;
				                        DECLARE @meanContactTypeId SMALLINT;
				                        DECLARE @conversationIdNew INT;
				                        SET @meanContactTypeId = 1;
				                        SET NOCOUNT ON;

				                    IF @action = 1
				                    BEGIN --new Conversation
				                        IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock)
				                        WHERE A.conversationId = @conversationId)
				                        BEGIN
				                            INSERT INTO [ccWhatsAppConversationsOut]
				                            (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
				                            VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
				                            
				                            
				                            SELECT @conversationId = SCOPE_IDENTITY();
											SELECT @ConvId = @conversationId;
				                            SELECT @conversationId AS ConversationId;

				--        Save new request
				        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
				        INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
				        END
				        ELSE BEGIN
				            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
				        END
				        RETURN(0);
				    END
				    ELSE BEGIN
				        DECLARE @conversationStatusTemp INT = @conversationStatus;
				        IF @conversationStatus in(17,18) BEGIN
				            SET @conversationStatusTemp = 1
				        END 

				        DECLARE @RequestDate DATETIME = NULL;
				        SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversationsOut WITH(NOLOCK) WHERE conversationId = @conversationId;

				        INSERT INTO [ccWhatsAppConversationsOut]
				            (camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId, requestDate)
				        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, 
				            @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
				        SELECT @conversationIdNew = SCOPE_IDENTITY();

				        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
				        VALUES (@conversationId, @conversationIdNew);
				        --Save new request by reassign
				        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
				        WHERE camId = @camId

				    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

				                        SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
										SELECT @ConvId = conversationIdAfter FROM ccWhatsAppConversationsRelationshipOut WHERE conversationIdBefore = @conversationId;
				                        RETURN(0);
				                    END;
				                    END;

				else IF @action = 2
				BEGIN --save conversation Times
				    DECLARE @conversationIdTemp INT;
				    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

				    IF @listConversationsIds IS NOT NULL begin
				        INSERT INTO @TablaTemp
				        SELECT value,0
				        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
				        where value is not null and value<>''''
				    end
				    else begin
				        INSERT INTO @TablaTemp values(@conversationId,0)
				    end
				    
				    UPDATE ccWhatsAppConversationsOut
				    SET
				    conversationStatus = @conversationStatus
				    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
				    when @conversationStatus in(11) then 1
				        else 0 end
				    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
				    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
				    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
				    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

				    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
				    BEGIN
				        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
				        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

				        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
				            DECLARE @conversationDateTemp INT;
				            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
				            from ccWhatsAppConversationsOut where conversationId = @conversationId;

				            IF @conversationStatus = 13 BEGIN
				                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam with(nolock) where NumberClient = @clientId) BEGIN
				                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
				                END
				            END
				            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
				                IF @conversationDateTemp > 0 BEGIN
				                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
				                END
				                ELSE BEGIN
				                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
				                END
				            END
				            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
				                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
				            END
				        END
				        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
				    END

				END;

				else IF @action = 3
				BEGIN --save conversation Status
				    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
				END;

				else IF @action = 4 BEGIN --save messages from conversation
				    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId)
				        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A with(nolock) WHERE A.messageId=@messageId)
				    BEGIN
				        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
				            (SELECT messageIdUi
				                FROM ccWAMessagesConversationsOut
				                WHERE originType IN (''Agent'', ''Admin'')
				                AND conversationId = @conversationId)
				            BEGIN
				                UPDATE ccWhatsAppConversationsOut
				                    SET FirstMessageAgent = @timeStampMessage
				                    WHERE conversationId = @conversationId;
				            END

				        INSERT INTO [ccWAMessagesConversationsOut](
				                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
				                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
				        SELECT @messageId=SCOPE_IDENTITY()
				    
				    SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
				        if not exists(select * from ccWAConversationsResult where camId=@camId)begin
				            insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
				        end
				        exec ccsp_ConversationWASaveOut @action=16,@camId=@camId,@messageStatus=@messageStatus,@conversationId=@conversationId,@originType=@originType
				        
				        SELECT @messageId as MessageId
				        
				        RETURN (0)
				    END
				    ELSE BEGIN
				        SELECT 0 AS MessageId
				        RETURN (0)
				    END
				END;

				else IF @action = 5
				BEGIN --save onQueue
				    UPDATE ccWhatsAppConversationsOut
				            SET onQueue = 1,
				            conversationStatus = @conversationStatus
				    WHERE conversationId = @conversationId;
				    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
				    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
				END;

				else IF @action = 6
				BEGIN --save agent, assigdate and tqueue
				    declare @agentIdTmp int
				    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
				    
				        UPDATE ccWhatsAppConversationsOut
				                SET agentId = @agentId,
				                assignDate = getdate(),
				                conversationStatus = @conversationStatus
				                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
				        WHERE conversationId = @conversationId;

				    SELECT @conversationId as conversationId
				    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;

				    IF @onQueue = 1 BEGIN
				    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
				    END
				END;

				Else IF @action = 7
				BEGIN --update price message
				    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
				END;
				else IF @action = 8
				BEGIN --update status message
				    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A with(nolock) 
				        WHERE A.messageId=@messageId) <> ''read'' 
				    BEGIN
				        UPDATE ccWAMessagesConversationsOut
				                SET messageStatus = @messageStatus
				        WHERE messageId = @messageId;
				        exec ccsp_ConversationWASaveOut @action=16,@camId=@camId,@messageStatus=@messageStatus,@conversationId=@conversationId,@originType=@originType
				        
				    END;
				END;

				else IF @action = 9
				BEGIN --Save last message time by conversationID
				    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A with(nolock) 
				        WHERE A.conversationId=@conversationId) IS NULL BEGIN
				        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
				    END;
				    ELSE
				        BEGIN
				            UPDATE ccLastMessageAgentByConversationOut
				                SET timeStampLastMessageAgent = getDate()
				            WHERE conversationId = @conversationId;
				        END;
				END;

				else IF @action = 10
				BEGIN --drop and insert register by conversationID
				    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
				END;

				Else IF @action = 11
				BEGIN --register desconnection agent by conversationID
				    exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
				END;

				else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
				    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] with(nolock) 
				    where timeStampConnection is null order by timeStampDisconnection desc);
				    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

				                        declare @from as datetime;
				                        select @from = convert(datetime,convert(varchar(11),getdate()))
				                        set @from=DATEADD(dd,-1,@from);
				                            select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
				                            , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
				                            isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
				                            isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
				                            ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
				                            from ccWhatsAppConversationsOut A with(nolock) 
				                            left join ccWAMessagesConversationsOut B with(nolock) on A.conversationId = B.conversationId
				                            left join [ccDisconnectionMCSOut] C with(nolock) on C.disconnectionId = @disconnectionIdTemp        
				                            where A.requestDate >= @from 
				                                and A.conversationStatus not in (4, 10, 11, 13, 17, 18, 19, 20)
												and A.finishedBy=0
				                            order by agentId desc, requestDate,timeStampMessage, camId, clientId 
				                    END;
				                    else IF @action = 13
				                    BEGIN ---Obtain agents ON STATUS READY
				                        WITH agents
				                        AS(
				                            SELECT c.User_id, c.fecha, c.currentStatus
				                            FROM ccLogAgentesDia c
				                            INNER JOIN 
				                            (
				                                SELECT User_id, MAX(fecha) max_time
				                                FROM ccLogAgentesDia with(nolock)
				                                where fecha>=CONVERT(date,getdate(),121)
				                                GROUP BY User_id
				                            ) AS t
				                            ON c.fecha = t.max_time
				                            AND c.User_id=t.User_id AND currentStatus in (3,34)
				                        ), usersByCampigns
				                        AS (
				                            select IdCampEsp, User_id from ccRIACampEspWG A
				                            Inner join ccRIAWorkGroupUsers B
				                            on A.IDWG = B.IDWG
				                            Inner join contactMeanOut C
				                            ON A.idCampEsp = C.camp_id
				                            where A.IDWG = 1 and A.Tipo = 1
				                            AND C.meanContactTypeId = 5
				                        )

				    select DISTINCT A.User_Id from agents A
				    left join usersByCampigns B on A.User_Id = B.User_Id
				END;

				else IF @action = 14
				BEGIN --register desconnection MCS
				    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
				END;
				ELSE IF @action = 15
				    BEGIN --update content message
				        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
				            UPDATE ccWAMessagesConversationsOut
				                    SET content = @content
				            WHERE messageId = @messageId;
				        END;
				    END;
				ELSE IF @action = 16 BEGIN --update content message

				        if @camId is null or @camId=0 begin 
				        SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
				        end
				                
				        IF @messageStatus = ''submitted''
						BEGIN
							UPDATE ccWAConversationsResult 
							SET SentMsg = SentMsg + 1;
						END
						ELSE IF @messageStatus = ''delivered''
						BEGIN
							UPDATE ccWAConversationsResult 
							SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
								Delivered = Delivered + 1;
						END
						ELSE IF @messageStatus = ''read''
						BEGIN
							UPDATE ccWAConversationsResult 
							SET Delivered = CASE WHEN Delivered > 0 THEN Delivered - 1 ELSE Delivered END,
								ReadMsg = ReadMsg + 1;
						END
						ELSE IF @messageStatus = ''rejected'' OR @messageStatus = ''error''
						BEGIN
							UPDATE ccWAConversationsResult 
							SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
								NotDelivered = NotDelivered + 1;
						END
						ELSE IF (@messageStatus = ''N/A'' AND @originType != ''Agent'')
						BEGIN
							UPDATE ccWAConversationsResult 
							SET NotSupported = NotSupported + 1;
						END


				        SELECT @messageId as MessageId
				    END;
				ELSE IF @action = 17 BEGIN --update agent status for reassigning error message
				    UPDATE ccWhatsAppConversationsOut
				    SET IsAgentLoggingOut = @IsAgentLoggingOut
				    WHERE conversationId = @conversationId;
				END;
				ELSE IF @action = 18 BEGIN
				        DECLARE @dateNow DATETIME;
				        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

				                            UPDATE ccWhatsAppConversationsOut 
				                        SET finishedBy = 2, conversationStatus=17
				                            WHERE finishedBy = 0  AND requestDate <= @dateNow   
				                        END;
									ELSE IF @action = 19 select * from ccWhatsAppConversationsOut
									BEGIN 
										UPDATE ccWhatsAppConversationsOut SET assignDate = FirstMessageAgent where conversationId = @conversationId;
									END
									END;'
		EXEC(@sql)

		------------------------------------------- END Ivan Martin ----------------------------------------------------------

		SET @process = 'Alter SP ccsp_GalateaAreas se agrega if @option = 2 borrar la tabla #Areas'
        SET @sql = 'ALTER procedure [dbo].[ccsp_GalateaAreas] 
        @option int = 2,
        @IDArea smallint = 0,
        @Descripcion varchar(40) = NULL,
        @maxMails smallint = 3,
        @maxChats smallint = 3,
        @maxTweets smallint = 3,
        @maxWhats smallint = 3,
        @maxWhatsOut smallint = 3,
        @callWhileChat bit = 0,
        @callWhileEmail bit = 0,
        @callWhileTwitter bit = 0,
        @CallWhileWhatsAppIn bit = 0,
        @CallWhileWhatsAppOut bit = 0,
        @defCampaing smallint = 0,
        @movesfromArea bit = 0,
        @userId int = NULL,
        @groupAreas varchar (MAX) = NULL,
        @toolsTransfer tinyint = NULL 
    AS

    SET NOCOUNT ON;
    
        declare @opt int = @option -1
    
        DECLARE @userLogin as varchar(40);
        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

        if @option = 1 --Superuser info
        begin
            create table #campsIds(
                id int,
                cadena varchar(max)
            )
            
            declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
            set @idPivots =''''
            set @idConcat=''''
            
            select @idPivots=@idPivots+Id+'','',
                @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
                ''
                from (
                select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
                )x
            
            set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
            set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
            set @sql=''
                select IDArea,''+@idConcat+'' from 
                (   select IDArea, cam_id from ccCamps) as T
                PIVOT (
                max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

            insert into #campsIds
            exec(@sql)
            
            select a.IDArea Id, 
                a.AreaName Name, 
                a.StatusArea Status, 
                a.maxMails Mails, 
                a.maxChats Chats, 
                a.maxTweets Tweets, 
                a.maxWhats Whats,
                a.maxWhatsOut WhatsOut,
                a.callWhileChat callChat,
                a.callWhileEmail callEmail,
                a.CallWhileWhatsAppIn callWhatsIn,
                a.CallWhileWhatsAppOut callWhatsOut,
                a.CreateDate as CreateDate,         
                ISNULL(b.cadena, 0) as CampaignIds  
            from ccRIACat_Areas a --Falta el datetime 
            left join #campsIds b on a.IDArea = b.id

            drop table #campsIds
        end
        if @option = 2 -- Select de las areas
        begin
            IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
            Create table #Areas(
                IDArea smallint,
                AreaName varchar(MAX),
                maxChats tinyint ,
                maxMails tinyint ,
                maxWhats tinyint ,
                maxWhatsOut tinyint ,
                callWhileChat bit, 
                callWhileEmail bit,
                CallWhileWhatsAppIn bit,
                CallWhileWhatsAppOut bit,
                users int,
                admins int,
                camps int,
                acds int,
                maxTweets tinyint,
                toolsTransfer tinyint
            )
            insert into #Areas
            EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@maxWhats=@maxWhats,@maxWhatsOut=@maxWhatsOut,@callWhileChat=@callWhileChat,@callWhileEmail=@callWhileEmail,@callWhileWhatsAppIn=@callWhileWhatsAppIn,@callWhileWhatsAppOut=@callWhileWhatsAppOut,@defCampaing=@defCampaing, @isKolob=1
            select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
            from #Areas a
            inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

            IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        end
        if @option = 3 -- Insert new area
        begin
        IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
            Create table #InsertAreas(
                result int,
                idAreas decimal
            )
            insert into #InsertAreas
            EXEC ccsp_RIA_ABCAreas 
                @option = @opt,
                @IDArea=@IDArea,
                @Descripcion=@Descripcion,
                @maxMails=@maxMails,
                @maxChats=@maxChats,
                @maxTweets=@maxTweets,
                @maxWhats=@maxWhats,
                @maxWhatsOut=@maxWhatsOut,
                @callWhileChat=@callWhileChat,
                @callWhileEmail=@callWhileEmail,
                @callWhileWhatsAppIn=@callWhileWhatsAppIn,
                @callWhileWhatsAppOut=@callWhileWhatsAppOut,
                @defCampaing=@defCampaing,
                @toolsTransfer=@toolsTransfer
            if (select result from #InsertAreas) = 1
                begin

                    --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                    if(@movesfromArea = 1) begin
                        Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                    end
                end
            Select * from #InsertAreas
        end
        if @option = 4 -- Delete Areas
        begin
            IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
            SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
            if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
              or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
            BEGIN
                Select -1 as result
            END
            ELSE
            BEGIN
                declare @DWorkGroups as varchar(500)
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select user_id,cam_id,prioridad,skill,rel_id,IDWG
                from ccCampsAgente
                where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
                select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
                from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
                Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
                select user_id,cam_id,tipo,IDWG,monitored
                from ccSupervisorCam
                where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
                delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
                delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
                where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

                Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
                Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

                Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
                Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
                Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

                select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
                Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

                if (select valor from ccSettings where setting_id=95)=1
                begin
                Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
                Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
                Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
                end

                Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea in (Select IDArea from #AreasDelete);

                select 1 as result
            END
        end
        if @option = 5 -- update Areas
        begin
            if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
                begin
                    select -1 as result
                    return
                end
            else
                begin

                    --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                    DECLARE @PrevDescription AS VARCHAR(50);
                    DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                    SELECT @PrevDescription = AreaName
                    FROM ccRIACat_Areas 
                    WHERE IDArea = @IDArea;

                    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                    DECLARE @AreasTable TABLE 
                    (
                        columnInfo VARCHAR(255),
                        dataInfo VARCHAR(255),
                        identifierInfo VARCHAR(255)
                    )

                    update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileWhatsAppIn=isnull(@callWhileWhatsAppIn,callWhileWhatsAppIn),callWhileWhatsAppOut=isnull(@callWhileWhatsAppOut,callWhileWhatsAppOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                   INSERT INTO @AreasTable EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId;

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                    SELECT 
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                        ELSE '''' END,
                        getDate(), 
                        @userLogin, 
                        18, 
                        3, 
                        AT.identifierInfo,
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                                WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                    CASE 
                                        WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                        ELSE ''T&COMMON_NONE'' END
                                WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                                    CASE
                                        WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                        ELSE ''COMMON_DISABLED'' END
                                when at.identifierInfo = ''T&SET_CALL_WHILE_CHAT'' then 
                                    case 
                                        when @callWhileChat = 1 then ''COMMON_ENABLED''
                                        else ''COMMON_DISABLED'' end
                                when at.identifierInfo = ''T&SET_CALL_WHILE_EMAIL'' then 
                                    case 
                                        when @callWhileEmail = 1 then ''COMMON_ENABLED''
                                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_IN'' then 
                        case 
                        when @CallWhileWhatsAppIn = 1 then ''COMMON_ENABLED''
                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_OUT'' then 
                    case 
                    when @CallWhileWhatsAppOut= 1 then ''COMMON_ENABLED''
                        else ''COMMON_DISABLED'' end

                                ELSE AT.dataInfo END
                        ELSE '''' END, 
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                        ELSE '''' END
                    FROM @AreasTable AS AT;

                    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                    --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                end
            if @maxChats is not null
                begin
                    Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
                end
            if @movesfromArea = 1
            Begin
                Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
            End
            select 1 as result
        END
        IF @option = 6 -- get configAreaMultimedia by userId
        BEGIN
            SELECT 
            crca.callWhileChat
            , crca.callWhileEmail
            , crca.CallWhileWhatsAppIn
            , crca.CallWhileWhatsAppOut
            FROM  
            dbo.ccRIAWorkGroupUsers AS crwgu INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
            ON crawg.IDWG = crwgu.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca 
            ON crca.IDArea = crawg.IDArea WHERE crwgu.User_id = @userId 
            GROUP BY crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut

            RETURN (0)
        END
        IF(@option = 7) -- get area campaign relation by areaId
        BEGIN
            SELECT crcew.IdCampEsp, crawg.IDArea FROM dbo.ccRIACampEspWG AS crcew 
                                    INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg
                                    ON crawg.IDWG = crcew.IDWG
                                    WHERE crcew.Tipo = 1 AND crawg.IDArea = @idArea
            RETURN (0)
        END
        
        
    SET NOCOUNT ON;'
        EXEC(@sql);
		-------------------------------------------------------------------- Ulises Begin ------------------------------------------------------------------------
		SET @process = 'Alter SP ccsp_RIAInsertChat'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@idArea INT = NULL,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) ='''',
@template varchar (100)= '''',
@ScoreTemplate int = 0,
@causeFinishedId INT = NULL
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = case when @userId = 0 then userId else @userId end, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished, userID =case when @userId = 0 then userId else @userId end where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
  --Se agrega esta ejecucion para que se cree el nodo
  exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=1,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, userId = case when @userId = 0 then userId else @userId END WHERE chatId = @chatId
       end

       if @action = 6 begin
            update ccRIAChats set userId = case when @userId = 0 then userId else @userId end  where chatId = @chatId
       end
       
       exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=1,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate
      
end
else if(@action = 7) -- Se añadio al cambio
begin 
    if @chatId > 0
    begin
        UPDATE dbo.ccRIAChats SET chatDate = GETDATE() WHERE chatId = @chatId
    end
END
ELSE if(@action = 8) -- Se añadio al cambio
BEGIN 
    UPDATE dbo.ccRIAChats SET causeFinishedId = @causeFinishedId  WHERE chatId = @chatId
END
ELSE IF(@action = 9) -- Se realiza para consultar la configuracón de areas
BEGIN
    SELECT crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
    ON crawg.IDWG = crcew.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca ON crca.IDArea = crawg.IDArea
    WHERE crcew.Tipo = 1 AND crcew.IdCampEsp = @inboundId GROUP by crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut;
END'
        EXEC(@sql);
		-------------------------------------------------------------------- Ulises End --------------------------------------------------------------------------
                     

		-------------------------------------------------------------------- BEGIN MACL --------------------------------------------------------------------------
		SET @process = 'Alter SP ccspOutboundWhatsApp para obtener eñ AreaId'
        SET @sql = 'ALTER procedure [dbo].[ccspOutboundWhatsApp]
@action int,
@camId int = null,
@campType int = null,
@templateName varchar(512)=null
as
if @action=1 begin
declare @Url as varchar(50)
set @Url = (select Url from ccMetaWhatsAppConfigurations where Id=1)

IF @camId IS NULL AND @campType IS NULL
BEGIN
	select 
		distinct 
		cast(c. cam_id as int) as CamId,
		cam_descripcion as [Name],
		1 AS CampType,
		cam_procesando as [Start],
		Number as PhoneNumber, 
		REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url, 
		Token,
		CAST(c.IDArea AS int) as AreaId
	from ccCamps c with(nolock)
	left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
	left join  ccCampsHorarios s ON s.cam_id = c.cam_id
	left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
	WHERE CampType=5 AND c.IDArea IS NOT NULL
	UNION
	SELECT -- load acd
		DISTINCT 
		CAST(ci.Inbound_id AS INT) AS CamId,
		ci.descripcion AS [Name],
		0 AS CampType,
		CAST(ci.Status AS BIT) AS [Start],
		cmw.Number AS PhoneNumber,
		REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
		cmw.Token AS Token,
		CAST(ci.IDArea AS int) as AreaId
	FROM ccInbound ci WITH(NOLOCK)
	LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
	LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
	WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL
END
ELSE IF @campType IS NOT NULL
BEGIN
	IF @campType = 0
	BEGIN
		SELECT -- load acd
			DISTINCT 
			CAST(ci.Inbound_id AS INT) AS CamId,
			ci.descripcion AS [Name],
			0 AS CampType,
			CAST(ci.Status AS BIT) AS [Start],
			cmw.Number AS PhoneNumber,
			(CASE ci.Status WHEN 0 THEN '''' ELSE REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) END) AS Url,
			cmw.Token AS Token,
			CAST(ci.IDArea AS int) as AreaId
		FROM ccInbound ci WITH(NOLOCK)
		LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
		LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
		WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL AND (@camId IS NULL or @camId=0 OR ci.Inbound_id = @camId)
	END
	ELSE
	BEGIN
		select 
			distinct 
			cast(c. cam_id as int) as CamId,
			cam_descripcion as [Name],
			1 AS CampType,
			cam_procesando as [Start],
			Number as PhoneNumber, 
			case cam_procesando when 0 then '''' else REPLACE(@Url, ''phoneId'', PhoneNumberId) end as Url, 
			Token,
			CAST(c.IDArea AS int) as AreaId
		from ccCamps c with(nolock)
		left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
		left join  ccCampsHorarios s ON s.cam_id = c.cam_id
		left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
		WHERE CampType=5 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
	END
END

end
else if @action=2 begin
	select top 1 A.id,A.LanguageCode,B.Number from ccMetaWAOutboundTemplates A
	inner join ccMetawhatsAppNumbers B on B.MetaId=A.MetaId
	where A.TemplateName=@templateName and B.Cam_Id=@camId

end'
        EXEC(@sql);
		-------------------------------------------------------------------- BEGIN MACL --------------------------------------------------------------------------
		
		-------------------------------------------------------------------- BEGIN DMM  --------------------------------------------------------------------------
		SET @process = 'Se elimina SP ccsp_GetAgentAndCampaignRelationship'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetAgentAndCampaignRelationship'')
					begin
						DROP PROCEDURE ccsp_GetAgentAndCampaignRelationship;
					end'
		EXEC(@sql)

		SET @process = ' HUs -> k066001
						 Se crea SP ccsp_GetAgentAndCampaignRelationship. 
						 @Option=1 - Obtiene filtros
						 @Option=2 - Obtiene paginado de conversaciones
						 @Obtien=3 - Obtiene máximo de días a buscar en historial dependiendo a filtro de campaña'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GetAgentAndCampaignRelationship]
		 @Option smallint = null,
		 @agentId smallint = null,
		 @From datetime = null,
		 @To datetime = null,
		 @InboundIdsLst varchar(max) = null,
		 @OutboundIdsLst varchar(max) = null,
		 @ClientNumbersLst varchar(max) = null,   
		 @MaxConversationHistory smallint = null,
		 @ConversationIndex smallint = null,
		 @ConversationId int = null,
		 @CamType bit = null,
		 @CamId int = null

		AS
		BEGIN
			DECLARE @MaxConversationHistoryTime INT = NULL;
			DECLARE @MaxDaysPerWAConvo INT = NULL;
			DECLARE @FinalMaxValue INT = NULL;

		IF @Option = 1 -- Obtiene filtros
		BEGIN
			DECLARE @campsIn VARCHAR(MAX) = ''''
			DECLARE @InboundNames VARCHAR(MAX) = ''''
			DECLARE @OutboundNames VARCHAR(MAX) = ''''
			DECLARE @campsOut VARCHAR(MAX) = ''''
			DECLARE @combinedCampsIn VARCHAR(MAX) = ''''
			DECLARE @combinedCampsOut VARCHAR(MAX) = ''''
			DECLARE @combinedInboundNames VARCHAR(MAX) = ''''
			DECLARE @combinedOutboundNames VARCHAR(MAX) = ''''
			DECLARE @ClientIds VARCHAR(MAX) = ''''
			DECLARE @count INT
			DECLARE @id INT
			DECLARE @wg INT

			IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
				DROP TABLE #AgentsRelations;

			SELECT ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
				   IDWG, @campsIn AS campsIn, @campsOut AS campsOut, 
				   @InboundNames AS InboundNames, @OutboundNames AS OutboundNames
			INTO #AgentsRelations
			FROM ccRIAAreaWorkGroup wg
			WHERE EXISTS (
				SELECT 1 
				FROM ccRIAWorkGroupUsers wgu 
				WHERE wgu.IDWG = wg.IDWG 
					AND wgu.user_id = @agentId
			);

			SELECT @count = COUNT(idWG) FROM #AgentsRelations;
			SET @id = 1;

			WHILE @id <= @count
			BEGIN
				SELECT @wg = idwg FROM #AgentsRelations WHERE Row = @id;

				SET @campsIn = '''';
				SET @campsOut = '''';
				SET @InboundNames = '''';
				SET @OutboundNames = '''';

				SELECT @campsIn = ISNULL(@campsIn + CASE WHEN @campsIn = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), inbound_id), @campsIn)
				FROM ccInbound i 
				INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
				WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
				ORDER BY inbound_id;

				SELECT @campsOut = ISNULL(@campsOut + CASE WHEN @campsOut = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), cam_id), @campsOut)
				FROM ccCamps c 
				INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
				WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
				ORDER BY cam_id;

				SELECT @InboundNames = ISNULL(@InboundNames + CASE WHEN @InboundNames = '''' THEN '''' ELSE '','' END + i.descripcion, @InboundNames)
				FROM ccInbound i
				WHERE i.Inbound_id IN (
					SELECT inbound_id FROM ccInbound 
					INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
					WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
				)
				ORDER BY i.Inbound_id;

				SELECT @OutboundNames = ISNULL(@OutboundNames + CASE WHEN @OutboundNames = '''' THEN '''' ELSE '','' END + c.cam_descripcion, @OutboundNames)
				FROM ccCamps c
				WHERE c.cam_id IN (
					SELECT cam_id FROM ccCamps 
					INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
					WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
				)
				ORDER BY c.cam_id;

				IF @campsIn IS NOT NULL AND @campsIn <> ''''
					SET @combinedCampsIn = ISNULL(@combinedCampsIn + CASE WHEN @combinedCampsIn = '''' THEN '''' ELSE '','' END + @campsIn, @combinedCampsIn);

				IF @campsOut IS NOT NULL AND @campsOut <> ''''
					SET @combinedCampsOut = ISNULL(@combinedCampsOut + CASE WHEN @combinedCampsOut = '''' THEN '''' ELSE '','' END + @campsOut, @combinedCampsOut);

				IF @InboundNames IS NOT NULL AND @InboundNames <> ''''
					SET @combinedInboundNames = ISNULL(@combinedInboundNames + CASE WHEN @combinedInboundNames = '''' THEN '''' ELSE '','' END + @InboundNames, @combinedInboundNames);

				IF @OutboundNames IS NOT NULL AND @OutboundNames <> ''''
					SET @combinedOutboundNames = ISNULL(@combinedOutboundNames + CASE WHEN @combinedOutboundNames = '''' THEN '''' ELSE '','' END + @OutboundNames, @combinedOutboundNames);

				SET @id = @id + 1;
			END

			IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
			BEGIN
				IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;

				CREATE TABLE #TmpInboundIds (Id INT);
				INSERT INTO #TmpInboundIds (Id)
				SELECT CAST(value AS INT) 
				FROM fn_RIASplitDelimited(@combinedCampsIn, '','');

				SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
				FROM ccInbound i
				INNER JOIN #TmpInboundIds tmp ON tmp.Id = i.Inbound_id;

				IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
			END

			IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
			BEGIN
				IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;

				CREATE TABLE #TmpOutboundIds (Id INT);
				INSERT INTO #TmpOutboundIds (Id)
				SELECT CAST(value AS INT) 
				FROM fn_RIASplitDelimited(@combinedCampsOut, '','');

				SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
				FROM contactMeanOut cmo 
				INNER JOIN #TmpOutboundIds tmp ON tmp.Id = cmo.camp_id;

				IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
			END

			SET @FinalMaxValue = CASE 
				WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
				WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
				ELSE CASE 
					WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
					ELSE @MaxDaysPerWAConvo
				END
			END;

			SELECT 
				@combinedCampsIn AS InboundIdsLst, 
				@combinedInboundNames AS InboundNamesLst, 
				@combinedCampsOut AS OutboundIdsLst, 
				@combinedOutboundNames AS OutboundNamesLst, 
				CAST(@FinalMaxValue AS SMALLINT) AS MaxConversationHistory;

			IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
				DROP TABLE #AgentsRelations;
			END
		END

		IF @Option = 2 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados 
		BEGIN
			DECLARE @ClientNumberTable TABLE (ClientNumber BIGINT);
			DECLARE @InboundIdTable TABLE (InboundId INT);
			DECLARE @OutboundIdTable TABLE (OutboundId INT);
			DECLARE @PageSize INT = 10; 

			IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
			BEGIN
				INSERT INTO @ClientNumberTable (ClientNumber)
				SELECT CAST(value AS BIGINT)
				FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
			END

			IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
			BEGIN
				INSERT INTO @InboundIdTable (InboundId)
				SELECT CAST(value AS INT)
				FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
			END

			IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
			BEGIN
				INSERT INTO @OutboundIdTable (OutboundId)
				SELECT CAST(value AS INT)
				FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
			END

			DECLARE @TotalConversations INT;
			SELECT 
				@TotalConversations = COUNT(DISTINCT ConversationId)
			FROM (
				SELECT ConversationId 
				FROM ccWhatsAppConversations 
				WHERE AgentId = @agentId 
				AND conversationDate IS NOT NULL
				AND requestDate BETWEEN @From AND @To
				AND (@ClientNumbersLst IS NULL OR @ClientNumbersLst = '''' OR clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@InboundIdsLst IS NULL OR @InboundIdsLst = '''' OR InboundId IN (SELECT InboundId FROM @InboundIdTable))  

				UNION ALL

				SELECT ConversationId 
				FROM ccWhatsAppConversationsOut
				WHERE AgentId = @agentId 
				AND tChatting <> 0    
				AND requestDate BETWEEN @From AND @To
				AND (@ClientNumbersLst IS NULL OR @ClientNumbersLst = '''' OR clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@OutboundIdsLst IS NULL OR @OutboundIdsLst = '''' OR camId IN (SELECT OutboundId FROM @OutboundIdTable))
			) AS AllConversations;

			DECLARE @Offset INT;
			SET @Offset = ISNULL(@ConversationIndex, 1) - 1; 

			IF @ConversationIndex >= @TotalConversations
			BEGIN
				SET @Offset = @TotalConversations - @PageSize; 
				IF @Offset < 0 SET @Offset = 0; 
			END

			;WITH LatestInboundMessages AS (
				SELECT 
					c.ConversationId,
					c.InboundId AS CampaignId,
					g.graphic_id AS GraphicId,
					c.clientId AS ClientNumber,
					m.content AS MessageContent,
					m.TimeStampMessage AS LastMessageTimestamp,
					''Inbound'' AS CampType,
					ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
				FROM ccWhatsAppConversations c
				LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
				LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
				WHERE c.AgentId = @agentId 
					AND c.conversationDate IS NOT NULL
					AND c.requestDate BETWEEN @From AND @To
					AND (@ClientNumbersLst IS NULL OR @ClientNumbersLst = '''' OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
					AND (@InboundIdsLst IS NULL OR @InboundIdsLst = '''' OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))
			),
    
			LatestOutboundMessages AS (
				SELECT 
					c.ConversationId,
					c.camId AS CampaignId,
					g.graphic_id AS GraphicId,
					c.clientId AS ClientNumber,
					m.content AS MessageContent,
					m.TimeStampMessage AS LastMessageTimestamp,
					''Outbound'' AS CampType,
					ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
				FROM ccWhatsAppConversationsOut c
				LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
				LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
				WHERE c.AgentId = @agentId 
					AND c.tChatting <> 0 
					AND c.requestDate BETWEEN @From AND @To
					AND (@ClientNumbersLst IS NULL OR @ClientNumbersLst = '''' OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
					AND (@OutboundIdsLst IS NULL OR @OutboundIdsLst = '''' OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
			),

			CombinedMessages AS (
				SELECT 
					ConversationId,
					CampaignId,
					GraphicId,
					ClientNumber,
					MessageContent,
					LastMessageTimestamp,
					CampType
				FROM LatestInboundMessages
				WHERE rn = 1
        
				UNION ALL
        
				SELECT 
					ConversationId,
					CampaignId,
					GraphicId,
					ClientNumber,
					MessageContent,
					LastMessageTimestamp,
					CampType
				FROM LatestOutboundMessages
				WHERE rn = 1
			)

			SELECT conversationId as ConversationId,
				   CampaignId as CamId,
				   CAST(GraphicId AS SMALLINT) AS Frame,
				   ClientNumber as ClientNumber,
				   MessageContent as MessageContent,
				   CampType AS CamType,
				   LastMessageTimestamp as LastMessageDateTime,
				   @TotalConversations AS ConversationsCount
				   FROM CombinedMessages
				   where MessageContent is not null  
				   ORDER BY LastMessageTimestamp DESC
				   OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY; 
		END;

		IF @Option = 3 -- Obtiene número máximo de días a buscar por historial cuando se filtra por campañas 
		BEGIN 											
			IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

			CREATE TABLE #TmpInboundIdsCampFilter (Id INT);

			INSERT INTO #TmpInboundIdsCampFilter (Id)
			SELECT CAST(value AS INT) 
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');

			SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
			FROM ccInbound i
			INNER JOIN #TmpInboundIdsCampFilter tmp ON tmp.Id = i.Inbound_id;

			IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

			IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

			CREATE TABLE #TmpOutboundIdsCampFilter (Id INT);

			INSERT INTO #TmpOutboundIdsCampFilter (Id)
			SELECT CAST(value AS INT) 
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');

			SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
			FROM contactMeanOut cmo 
			INNER JOIN #TmpOutboundIdsCampFilter tmp ON tmp.Id = cmo.camp_id;

			IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

			SET @FinalMaxValue = CASE 
				WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
				WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
				ELSE CASE 
					WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
					ELSE @MaxDaysPerWAConvo
				END
			END;

			 SELECT CAST(@FinalMaxValue AS SMALLINT) AS MaxConversationHistory;
		END;'
		EXEC(@sql)
		-------------------------------------------------------------------- BEGIN DMM  --------------------------------------------------------------------------
        -------------------------------------------------------------------- BEGIN Ivan Martin DEV2-721 No se asigna el numero de WhatsApp de salida correctamente en creación--------------------------------------------------------------------------

        SET @process = ' DEV2-721 Se elimina SP ccsp_RIAUpdateCamConfig'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfig'')
					begin
						DROP PROCEDURE ccsp_RIAUpdateCamConfig;
					end'
		EXEC(@sql)

        SET @process = ' DEV2-721 Se mueve la asignación de campañas al numero de whatsapp y de meta fuera del if para que se actualice correctamente en la creación. Líneas 3245 a 3256'
		SET @sql = '
                    CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
                    @cam_id smallint,
                    @cam_descripcion varchar(40) = null,
                    @cam_tnotas smallint = null,
                    @cam_ocupado tinyint = null,
                    @cam_NoInt_ocupado tinyint = null,
                    @cam_inter_ocupado smallint = null,
                    @cam_nocontesto tinyint = null,
                    @cam_NoInt_nocontesto tinyint = null,
                    @cam_inter_nocontesto smallint = null,
                    @cam_fax tinyint = null,
                    @cam_NoInt_fax tinyint = null,
                    @cam_inter_fax smallint = null,
                    @cam_ModoManual tinyint= null,
                    @ANI varchar(15) = null,
                    @cam_ShowCalifWnd bit = null,
                    @cam_StartTimerOnHangUp bit = null,
                    @editableCallKey bit = null,
                    @cam_tNoContesta tinyint = null,
                    @cam_intensive_dialing tinyint = null,
                    @detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
                    @detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
                    @compliance TinyInt = null,
                    @cam_inter_graba smallint = null,
                    @cam_NoInt_graba tinyint = null,
                    @progDial smallint = null,
                    @excCallBack Tinyint = null,
                    @dialOrder Tinyint = null,
                    @dialPrefix varchar(10) = null,
                    @dialPrefixMan varchar(10) = null,
                    @dialPrefixXfe varchar(10) = null,
                    @listenManualCall bit = null,
                    @stopRecording bit = null,
                    @abandonCallback bit = null,
                    @autoCB smallint = null,
                    @id_listAni int = null,
                    @tDialonWrapUp smallint = null,
                    @quesize smallint=null,
                    @DNCScrub int=null,
                    @callerIdDesc varchar(15)=null,
                    @timeZoneRule int=null,
                    @callsBySurvey int=null,
                    @ivrScript int=null,
                    @surveyPctg int=null,
                    @call_record tinyint=null,
                    @dRestrictPlay bit = null,
                    @leaveRecMessage bit = null,
                    @manualCallOnChat bit = null,
                    @callBackSurveyClient bit = null,
                    @callBackSurveyAgent bit = null,
                    @funcEspDtmf int =null,
                    @sipHdrsCfg varchar(255) = null,
                    @cam_inter_cancelled smallint = null,
                    @prefijo varchar(max) = null,
                    @exitAssisted bit = null,
                    @previewDiscard bit = null,
                    @rotativeAlgo tinyint = null,
                    @timesPreview tinyint = null,
                    @cam_tPreview smallint = null,
                    @timesDiscard tinyint = null,
                    @CampType int = null,
                    @agentCloseConversationTime SMALLINT = NULL,
                    @adminCloseConversationTime INT = NULL,
                    @ConexionInfo VARCHAR(400) = NULL,
                    @allowFileAttachments BIT = NULL,
                    @selectRotativeANI int = null,
                    @messagingOrder bit = null,
                    @autoStart bit = null,
                    @recordHold bit = null,
                    @userId                SMALLINT     = NULL, 
                    @idArea                SMALLINT     = NULL, 
                    @isCreating            SMALLINT          = NULL,
                    @camCanceled int = null,
                    @recordIvr bit = null,
                    @module INT = -1,
                    @maxLimitQueueConversations SMALLINT = NULL,
                    @maxDaysPerWAConvo SMALLINT = NULL
                    as
                    set nocount on
                    
                    IF EXISTS (SELECT 1 FROM ccCamps WHERE cam_descripcion = @cam_descripcion AND cam_id <> @cam_id)
                    BEGIN
                        SELECT -1 -- Nombre ya esta en uso
                        RETURN(0)
                    END
                    
                    DECLARE @timesDiscardActual int = -1, @camCanceledActual int = -1, @recordIvrActual int = -1
                    SELECT @timesDiscardActual = timesDiscard, @camCanceledActual = camcanceled, @recordIvrActual = recordIvr FROM ccCamps WHERE cam_id = @cam_id
                    DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
                        DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
                        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

                    UPDATE ccCamps SET
                        cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
                        cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
                        cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
                        cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
                        cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
                        cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
                        cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
                        cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
                        cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
                        cam_fax = isnull(@cam_fax,cam_fax),
                        cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
                        cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
                        cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
                        ANI = isnull(@ANI,ANI),
                        cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
                        editableCallKey = isnull(@editableCallKey, editableCallKey),
                        cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
                        iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
                        detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
                        detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
                        compliance = isnull(@compliance, compliance),
                        cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
                        cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
                        cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
                        progDial = isnull(@progDial, progDial),
                        excCallBack = isnull(@excCallBack,excCallBack),
                        dialOrder = isnull(@dialOrder, dialOrder),
                        dialPrefix = isnull(@dialPrefix, dialPrefix),
                        dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
                        dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
                        listenManualCall = isnull(@listenManualCall, listenManualCall),
                        stopRecording = isnull(@stopRecording, stopRecording),
                        abandonCallback = isnull(@abandonCallback, abandonCallback),
                        t_autoCB = isnull(@autoCB,t_autoCB),
                        id_anilist = isnull(@id_listAni,id_anilist),
                        tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
                        cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
                        cam_maxqueue = isnull(@quesize,cam_maxqueue),
                        DNCScrub = isnull(@DNCScrub,DNCScrub),
                        callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
                        timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
                        callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
                        ivrScript = isnull(@ivrScript,ivrScript),
                        surveyPctg = isnull(@surveyPctg,surveyPctg),
                        call_record = isnull(@call_record,call_record),
                        startStopRecording = isnull(@dRestrictPlay, startStopRecording),
                        leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
                        manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
                        callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
                        callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
                        funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
                        sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
                        prefijo = isnull(@prefijo, prefijo),
                        exitAssisted = isnull(@exitAssisted, exitAssisted),
                        previewDiscard = isnull(@previewDiscard, previewDiscard),
                        rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
                        timesPreview = isnull(@timesPreview, timesPreview),
                        cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
                        timesDiscard = isnull(@timesDiscard, timesDiscard),
                        CampType = (CASE WHEN @callsBySurvey is not null AND @ivrScript is not null THEN
                                        CASE WHEN @callsBySurvey=0 and @ivrScript=0 THEN 0 
                                            ELSE 8 
                                        END
                                    WHEN @CampType is not null THEN @CampType 
                                    WHEN @progDial = 2 THEN 6 
                                    WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 
                                    WHEN CampType is not null THEN CampType ELSE 0 END),
                        selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
                        messagingOrder = isnull(@messagingorder, messagingOrder),
                        autoStart = isnull(@autoStart,autoStart),
                        recordHold = isnull(@recordHold, recordHold),
                    CamCanceled = ISNULL(@camCanceled, CamCanceled),
                    recordIvr = isnull(@recordIvr, recordIvr)

                        Where cam_id = @cam_id

                            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

                            Create table #ccCampsTable 
                            (
                                columnInfo VARCHAR(255),
                                dataInfo VARCHAR(255),
                                identifierInfo VARCHAR(255)
                            )

                            DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
                                                                                        CASE 
                                                                                            WHEN @Camptype = 6  THEN 44
                                                                                            WHEN @Camptype = 5  THEN 46
                                                                                            WHEN @Camptype = 4  THEN 48
                                                                                            WHEN @Camptype = 7  THEN 50
                                                                                            ELSE 42 END
                                                                                    ELSE 
                                                                                        CASE 
                                                                                            WHEN @Camptype = 6  THEN 55
                                                                                            WHEN @Camptype = 5  THEN 56
                                                                                            WHEN @Camptype = 4  THEN 57
                                                                                            WHEN @Camptype = 7  THEN 58
                                                                                            ELSE 54 END
                                                                                    END;
                            
                            IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

                            IF(@isCreating = 1) 
                            BEGIN
                                DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
                                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
                                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
                            END

                            IF(@isCreating = 2) 
                            BEGIN
                                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) AND @recordIvrActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
                                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) and @camCanceledActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');				
                            END
                                
                            DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
                            DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
                                
                            IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
                            ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
                            ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
                            ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
                            ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

                            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            SELECT 
                                (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
                                getDate(), 
                                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                                @operation, 
                                @module,
                                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                                    THEN
                                        CASE
                                            WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                                                CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                                            WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
                                                CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
                                            WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                                                CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
                                            ELSE
                                                CCCT.identifierInfo
                                            END
                                    ELSE
                                    ''''
                                    END,
                                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                                    CASE 
                                        WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                                            CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
                                                THEN ''COMMON_VOICE_MAIL'' 
                                                ELSE 
                                                    CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
                                                END
                                        WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
                                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                                        WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
                                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                                        WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
                                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
                                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                                                ELSE ''T&COMMON_NONE'' END

                                        WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
                                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
                                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                                                ELSE ''T&COMMON_NONE'' END

                                        WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
                                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
                                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                                                ELSE ''COMMON_ASSISTED'' END

                                        WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                                            CASE WHEN  @CampType = 5 THEN 
                                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                            ELSE
                                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                                    WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                                    WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                                    ELSE ''T&COMMON_NONE'' END
                                            END

                                        WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                                    ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

                                        WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                                        WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                                    ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                                    ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
                                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                        WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
                                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                            
                                        ELSE CCCT.dataInfo END
                                ELSE '''' END, 
                                CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
                            FROM #ccCampsTable AS CCCT;

                            EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
                            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

                    if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
                    begin
                        EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
                    end

                    IF @CampType = 5 BEGIN
                        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
                        update ccMetaWhatsAppNumbers set Cam_Id=0 where Cam_Id=@cam_id

                        IF(@ConexionInfo <> '''')
                        BEGIN
                            IF EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @ConexionInfo)
                                UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
                            IF EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @ConexionInfo)
                                UPDATE ccMetaWhatsAppNumbers SET Cam_Id = @cam_id WHERE number = @ConexionInfo
                        END
                    END

                    IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
                    BEGIN
                        IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
                        BEGIN
                            SELECT 0
                            RETURN(0)
                        END

                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

                        Create table #contactMeanOutTable 
                        (
                            columnInfo VARCHAR(255),
                            dataInfo VARCHAR(255),
                            identifierInfo VARCHAR(255)
                        )

                        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

                        DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

                        set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
                        UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                                                                closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
                                                allowFileAttachments = @allowFileAttachments,
                                    maxLimitQueueConversations = @maxLimitQueueConversations,
                                    MaxDaysPerWAConvo = @maxDaysPerWAConvo
                        WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

                            
                        IF(@isCreating > 0 AND @module > -1) BEGIN 
                            EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
                            IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
                        END

                        DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
                        DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                            getDate(), 			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                            @operation, 
                            @module, 
                            CMOT.identifierInfo,
                            CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
                                CASE
                                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                                        CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
                                        CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
                                    ELSE CMOT.dataInfo END
                            ELSE '''' END, 
                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
                        FROM #contactMeanOutTable AS CMOT;

                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable
                    END 
                    DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

                    IF @cam_ShowCalifWnd = 1
                    BEGIN
                        IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
                        BEGIN
                            SELECT 0
                            RETURN(0)
                        END

                        UPDATE ccCamps SET
                        cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
                        WHERE cam_id = @cam_id


                        IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            SELECT 
                                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                                getDate(), 
                                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                                @operation, 
                                3, 
                                ''OUT_SHOW_DISPOSITIONS'',
                                CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
                        END

                        SELECT 1
                        RETURN(0)
                    END

                    UPDATE ccCamps SET
                    cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
                    where cam_id = @cam_id

                    IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                            getDate(), 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                            @operation, 
                            3, 
                            ''OUT_SHOW_DISPOSITIONS'',
                            CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
                    END

                    SELECT 2
                    RETURN(0)

                    set nocount off'
		EXEC(@sql)


----------------------------------------------------------- Start Hugo Longoria -------------------------------------------------------------------------

    set @process = 'Alter SP ccsp_DLRInsertCall'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_DLRInsertCall]
	@callout_id int,
	@cam_id smallint,
	@cal_Key varchar(20),
	@cal_Telefono varchar(14),
	@Puerto smallint,
	@logDial_id int=0
	AS

	INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --Status 6=Pide Agente
	  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto, getdate(), 6 )

	select scope_identity() as cal_id
	'
    EXEC(@sql)



----------------------------------------------------------- End Hugo Longoria -------------------------------------------------------------------------

---------------------------------------- End fix/125.20231211.0.9 fix/125.20231211.0.15 fix/125.20231211.0.16- -------------------------------------------------
    SET @process = 'Alter ccsp_AvrsSyncronization para cambiar la duration cuando se graba el hold'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
    @action SMALLINT,
    @maxRecordsToTransfer INT = 10,
    @id INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN
        DECLARE @countrId INT;
        SET @countrId = 1;

        SELECT @countrId = valor
        FROM ccSettings
        WHERE setting_id = 104;

                 -- Declarar la variable tipo tabla
         declare @tempCalls table(
            cal_id INT,
            user_id INT,
            Inbound_id INT,
            calif_id int,
            cal_extension INT,
            cal_inicio DATETIME,
            phone VARCHAR(50),
            duration INT,
            cal_key VARCHAR(50),
            cal_manual int,
            cal_puerto INT,
            dni_id INT,
            fvalida datetime,
            cal_whohung int,
            califSub_id int,
            cal_tMoh INT,
            dateEnd DATETIME,
            callType INT,
            avrsId INT,
            prefijo VARCHAR(20),
            isCallRecord BIT,
            DNIS VARCHAR(50),
            IDWG INT,
            IsVoicemail BIT
        );


        WITH callsIn AS (
            SELECT TOP (@maxRecordsToTransfer) 
                calls.cal_id as CallId,
                user_id,
                calls.Inbound_id,
                calls.calif_id,
                CAST(cal_extension AS INT) AS cal_extension,
                cal_inicio,
                cal_ANI AS phone,
                ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
                + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
                cal_key,
                0 AS cal_manual,
                cal_puerto,
                calls.dni_id,
                fvalida,
                cal_whohung,
                ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
                CASE 
                    WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                    WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                    ELSE cal_tMoh - trans.tAntesXfer 
                END AS cal_tMoh,
                DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
                avrs.tipo + 1 AS callType,
                avrs.id AS avrsId,
                ccInbound.prefijo,
                CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
                ISNULL(dni.dni_numero, '''') AS DNIS,
                dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
                0 AS IsVoicemail
            FROM ccCallsIn AS calls WITH (NOLOCK)
            INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
            INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
            LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
            LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
            LEFT JOIN (
                SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
                FROM ccLogTransfers  with(nolock)
                WHERE tipo = 1 AND modo != 7
                GROUP BY cal_id, tipo
            ) trans ON calls.cal_id = trans.cal_id
            WHERE calls.User_id > 0
        ),
        callsOut AS (
            SELECT TOP (@maxRecordsToTransfer) 
                calls.cal_id AS CallId,
                user_id AS UserId,
                calls.cam_id AS camAcdId,
                CAST(calls.calif_id AS SMALLINT) AS califId,
                CAST(cal_extension AS INT) AS extension,
                cal_inicio,
                cal_telefono,
                ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
                + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
                cal_key,
                cal_manual,
                cal_puerto,
                0 AS dni_id,
                fvalida,
                cal_whohung,
                ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
                CASE 
                    WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                    WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                    ELSE cal_tMoh - trans.tAntesXfer 
                END AS cal_tMoh,
                DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
                avrs.tipo + 1 AS callType,
                avrs.id AS avrsId,
                camps.prefijo,
                CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
                '''' AS DNIS,
                dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
                CASE WHEN calls.statusCall_id = 19 THEN 1 ELSE 0 END AS IsVoicemail
            FROM ccoCallsOut AS calls WITH (NOLOCK)
            INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
            INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
            LEFT JOIN (
                SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
                FROM ccLogTransfers with(nolock)
                WHERE tipo = 2
                GROUP BY cal_id, tipo
            ) trans ON calls.cal_id = trans.cal_id
            WHERE calls.User_id > 0 OR calls.statusCall_id = 19
        )

                INSERT INTO @tempCalls
                
        SELECT * FROM callsIn
        UNION 
        SELECT * FROM callsOut;


                 -- Revisar si hay registros con IsVoicemail = 1
        IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
        BEGIN
            
                        update A
                        set A.duration=B.tDialing
                        FROM @tempCalls A
            Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
            WHERE A.IsVoicemail = 1;
        END
        
        -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
        SELECT * FROM @tempCalls;
        
    END
    ELSE IF @action = 2
    BEGIN
        DELETE FROM ccAVRSTransfer
        WHERE id = @id;
    END
END;
'
        EXEC(@sql);

        SET @process = 'feature/KR179003 Alter SP ccsp_BaseXmngr'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null,
@grabIds varchar(4000) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
declare @filterWg varchar(max)
declare @len int
declare @tipo int
declare @serviceId varchar(10)

set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
                            
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
    else ''@CDATE''   end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by Xname''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
    update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
    and Xname=@name
end

else if @action = 10 begin
    
    set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
                        
    end
    else
    begin
    
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
    end


    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
    select SUBSTRING(@filterWg,0, @len)
    end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    set @sql=''
    declare @dateStart datetime
    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
    EXECUTE sp_executesql  @sql

end

else if @action = 13 begin
    set @sql = ''''
    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
    select @tableName,@tableNameHistory,@columnId
    set @sql=''
    ;
    with duplicateIds as(
    select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
    union
    select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
    )

    select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
    inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
    group by A.''+@columnId+'',A.dateIn
    Having count(*)>1
    order by Xname
    ''
    exec (@sql)

end

else if @action = 14 begin
    declare @CidNameOut varchar(100),@CidNameIn varchar(100)
    declare @filterCamId varchar(max), @filterInboundId varchar(max);
    declare @campType int
    declare @cidOut varchar(max)=''''
    declare @cidin varchar(max)=''''

    set @filterWg=''''
    if @node is null begin
        set @node=''R02''
    end

    set @CidNameOut=''$CID_OUT''
    set @CidNameIn=''$CID_IN''

    set @filterCamId=''''
    
    select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
    inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
    inner join ccCamps c on c.cam_id=WGCam.IdCampEsp --and c.CampType not in(5,7)
    where Wguser.User_id=@userId and WGCam.Tipo=1                               
    

    if @filterCamId<>'''' begin
        set @filterWg=''let ''+@CidNameOut+'':=(''

        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
        set @filterCamId=@filterCamId+'')''+char(10)    

        set @filterWg=@filterWg+@filterCamId
        set @cidOut=''(exists(index-of($CID_OUT, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
    end

    SET @filterInboundId= ''''
            
    select @filterInboundId=@filterInboundId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp
        where Wguser.User_id=@userId and WGCam.Tipo=0
    
    if @filterInboundId<>'''' begin
        set @filterInboundId=SUBSTRING(@filterInboundId,0,len(@filterInboundId))
        set @filterInboundId=@filterInboundId+'')''+char(10)    

        set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterInboundId
        set @cidin=''(exists(index-of($CID_IN, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
    end
    
    select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
end
else if @action = 15 begin --Saber si hacer busqueda en basex
  select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
  if @node=''R02'' begin
    select 1
    return(0)
  end

  set @sql=''if exists(select * from ''+@tableName+'') begin
        select 1
    end
    else if exists(select * from ''+@tableNameHistory+'') begin
        select 1
    end
    select 0''
    exec (@sql)
    
end'
    EXEC(@sql);

    SET @process = 'Drop procedure ccsp_DLRAfterInsertCall'
    SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_DLRAfterInsertCall'')
begin
    DROP PROCEDURE ccsp_DLRAfterInsertCall;
end'
     EXEC(@sql);

     SET @process = 'feature/KR179003 Alter SP ccsp_DLRAfterInsertCall'
     SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRAfterInsertCall]
@cam_id smallint,
@cal_id BIGINT=0,
@status int=0
AS
set nocount on

if @status = 0 begin
  set @status = 6 --Status 6=Pide Agente
end
else if @status=19
begin
    update ccoCallsOut set statusCall_id=@status where cal_id =@cal_id;
    insert into ccAVRSTransfer(cal_id,tipo) values(@cal_id,1)
    return
end
DECLARE @callout_id int, @date datetime

SELECT @callout_id=callout_id, @date=cal_Inicio from ccoCallsout nolock WHERE cal_id=@cal_id

INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
SELECT @cal_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @date
FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id


insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
where wg.Tipo=1 and wg.idcampesp=@cam_id

exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=@status

set nocount off'
    EXEC(@sql);

SET @process = 'feature/KR179003 Alter SP ccsp_DLRSaveDialResult'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
@ani varchar(32)=''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
    DECLARE @logDial_id INT;
    DECLARE @tAnswerBitFinal AS DATETIME;
    DECLARE @MaxCal_id INT;
    DECLARE @tTotal SMALLINT;

    SELECT @RecicleSIC = ISNULL(valor, 0)
    FROM ccSettings
    WHERE setting_id = 60;

    SELECT @tTotal = @tDialing + @tAnswerBit;

    SELECT @tNow = GETDATE();

    SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);


-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1 and @cal_key = ''''
    BEGIN
    SELECT @cal_key = cal_key
    FROM ccoCallsOutSource WITH(NOLOCK)
    WHERE @callout_id = callout_id;         
END;

declare @TipoLlamada int
select @TipoLlamada=dbo.fnGetTipoLlamada(@Telefono)

IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, 
               @TipoLlamada, @ani;
    END;
         ELSE
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS,
               @TipoLlamada, @ani;
    END;

    SELECT @logDial_id = SCOPE_IDENTITY();
    IF NOT EXISTS(SELECT 1 FROM ccoLogDialsData where logDial_id = @logDial_id)
    BEGIN
        INSERT INTO ccoLogDialsData(logDial_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
        SELECT @logDial_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @tNow
        FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id
    END

    IF @RecicleSIC = 1
    BEGIN
        UPDATE ccoWorkingTable WITH(ROWLOCK)
          SET tipoResDial_id = @tipoResDial_id
        WHERE callout_id = @callout_id;
    END;

    -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1
    BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
    WHERE cal_id = @call_id AND cal_puerto = 0;

        EXEC ccsp_CstoCalculaCosto @call_id;
    END;
else IF @call_id > 0 AND @tipoResDial_id = 11
BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto
    WHERE cal_id = @call_id AND cal_puerto = 0;

end

    -- inserta informacion para reportes de workgroup
    INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
           SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
           FROM ccRIACampEspWG
WHERE tipo = 1 AND IdCampEsp = @cam_id;

    -- Guarda configuracion de TipoDialingMode
    UPDATE ccoLogDials WITH(ROWLOCK)
      SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
    WHERE logDial_id = @logDial_id;
    SET NOCOUNT OFF;
END;

    SELECT @logDial_id as LogDialId'
        EXEC(@sql);    

        SET @process = 'feature/KR179003 update ccSettings setting_id=236'
        SET @sql = 'update ccSettings 
set detalle=''Habilita la grabacion de audio antes de que se conteste la llamada (Early Media). 0-Deshabilitado, 1-Habilitado,2- grabacion early media en buzon''
,description=''Enable audio recording before the call is answered (Early Media). 0-Disabled, 1-Enabled, 2- recording early media en voicemail''
where setting_id=236
'
        EXEC(@sql);

        SET @process = 'feature/KR179003 Add ccStatusLLamada Buzon'
        SET @sql = 'if not exists(select * from ccStatusLLamada where statusCall_id=19) begin
        insert into ccStatusLLamada (statusCall_id,descripcion,inAbandonConfig)
        values (19,''Buzon'',0)
end'
        EXEC(@sql);

 SET @process = 'Alter Funcion fnGetTipoLlamada mejora en el manejo y se valida si no es mexico no compare la lada'
        SET @Sql = 'ALTER FUNCTION [dbo].[fnGetTipoLlamada](@tel VARCHAR(32))
RETURNS TINYINT
AS
BEGIN
    DECLARE @ladatemp VARCHAR(5), @ldlocal VARCHAR(10), @serie VARCHAR(10), @numeracion SMALLINT, @length TINYINT
    DECLARE @mod VARCHAR(10), @country TINYINT, @lengthStr VARCHAR(10)
    DECLARE @tipoLlamada_id SMALLINT = 0, @tipo TINYINT = 0, @cantidadLL TINYINT

    -- Recuperar cÃ³digo de paÃ­s y cÃ³digo de Ã¡rea local de las configuraciones
    SELECT @country = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 104
    SELECT @ldlocal = valor FROM ccSettings WITH (NOLOCK) WHERE setting_id = 17

        set @length = LEN(@tel)
    SET @lengthStr = CONVERT(VARCHAR(10), @length)

    -- Tabla para almacenar los tipos de llamadas
    DECLARE @t_tipos TABLE (
        tipollamada_id INT NOT NULL,
        prefijo NVARCHAR(100) NOT NULL,
        rowid INT NOT NULL
    )

    -- Si el paÃ­s es igual a 1
    IF @country = 1
    BEGIN
        -- Insertar prefijos especÃ­ficos para el paÃ­s 1 (local)
        INSERT INTO @t_tipos
        SELECT tipoLlamada_id, prefijo, ROW_NUMBER() OVER (ORDER BY LEN(prefijo) DESC) AS rowid
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        WHERE country_id = 1
        AND tipoLlamada_id NOT IN (8, 9, 10, 11, 12)  -- Excluir ciertos tipos de llamadas
        AND CHARINDEX(@lengthStr, longitud) > 0  -- Usamos CHARINDEX para encontrar la longitud
    END
    ELSE
    BEGIN
        -- Insertar prefijos para paÃ­ses que no son el paÃ­s 1
        INSERT INTO @t_tipos
        SELECT tipoLlamada_id, prefijo, ROW_NUMBER() OVER (ORDER BY LEN(prefijo) DESC) AS rowid
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        WHERE country_id = @country
        AND CHARINDEX(@lengthStr, longitud) > 0  -- Usamos CHARINDEX en lugar de LIKE
    END

    -- Verificar si existen registros coincidentes
    SELECT @cantidadLL = COUNT(*) FROM @t_tipos

    IF @cantidadLL > 0
    BEGIN
        -- Buscar la mejor coincidencia (para ambos casos de paÃ­s)
        SELECT TOP 1 @tipo = tipollamada_id
        FROM @t_tipos t
        CROSS APPLY dbo.fn_RIASplitDelimited(t.prefijo, ''|'') AS splitPrefijo
        WHERE @tel LIKE splitPrefijo.value + ''%''
        ORDER BY LEN(splitPrefijo.value) DESC
    END
    ELSE
    BEGIN
        -- BÃºsqueda por defecto en cstoTipoLlamada si no hay coincidencias
        SELECT TOP 1 @tipoLlamada_id = tipoLlamada_id
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        CROSS APPLY dbo.fn_RIASplitDelimited(cstoTipoLlamada.prefijo, ''|'') AS split
        WHERE country_id = @country
        AND longitud = ''0''
        AND @tel LIKE split.value + ''%''
        AND (country_id <> 1 OR (country_id = 1 AND tipoLlamada_id NOT IN (8, 9, 10, 11, 12)))
        ORDER BY LEN(split.value) DESC

        IF @tipoLlamada_id > 0
        BEGIN
            SET @tipo = @tipoLlamada_id
        END
        ELSE IF @country != 1
        BEGIN
            -- Si no es el paÃ­s 1 y no hay coincidencias, regresar @tipo
            RETURN @tipo
        END
        ELSE
        BEGIN
            -- LÃ³gica adicional cuando es el paÃ­s 1
            IF @length = 10 - LEN(@ldlocal)
            BEGIN
                -- Ajustar el nÃºmero de telÃ©fono segÃºn la longitud
                SELECT @tel = CONVERT(VARCHAR(3), @ldlocal) + @tel
            END

            -- Reestructurar el nÃºmero para verificar prefijos
            SELECT @tel = RIGHT(@tel, 10)
            SELECT @ladatemp = LEFT(@tel, 2)

            -- Verificar prefijos de dos dÃ­gitos
            IF @ladatemp IN (''55'', ''56'', ''33'', ''81'')
            BEGIN
                SELECT @serie = SUBSTRING(@tel, 3, 4), 
                       @numeracion = RIGHT(@tel, 4)                
            END
            ELSE
            BEGIN
                -- Verificar prefijos de tres dÃ­gitos                
                SELECT @ladatemp = LEFT(@tel, 3), 
                                           @serie = SUBSTRING(@tel, 4, 3), 
                       @numeracion = RIGHT(@tel, 4)                
            END

            -- Buscar modalidad en la tabla `Series`
            SELECT TOP 1 @mod = MODALIDAD 
            FROM Series WITH (NOLOCK) 
            WHERE CLD = @ladatemp 
            AND SERIE = @serie 
            AND @numeracion BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

            -- Verificar si el nÃºmero es local
            DECLARE @isLocal BIT = 0

            IF EXISTS (SELECT 1 FROM ccRiaArecode WITH (NOLOCK) WHERE area = @ladatemp)
               OR @ldlocal = @ladatemp
            BEGIN
                SET @isLocal = 1;
            END

            -- Determinar el tipo de llamada segÃºn la modalidad y si es local
            IF @mod IN (''FIJO'', ''MPP'')
            BEGIN
                -- Llamada fija o mÃ³vil postpago
                SET @tipo = CASE 
                            WHEN @isLocal = 1 THEN 1  -- Llamada local
                            ELSE 2                     -- Llamada de larga distancia
                        END;
            END
            ELSE IF @mod = ''CPP''
            BEGIN
                -- Llamada celular prepago
                SET @tipo = CASE 
                            WHEN @isLocal = 1 THEN 3  -- Llamada celular local
                            ELSE 4                    -- Llamada celular de larga distancia
                        END;
            END
        END
    END

    RETURN @tipo
END
'
         EXEC (@Sql)

        -- SET @process = 'feature/KR179003 Alter SP ccsp_AvrsSyncronization'
        -- SET @sql = ''
        -- EXEC(@sql);

--------------------------- End Jesus 125.20231211.0.18 ----------------------------------------------------------------------------------

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
