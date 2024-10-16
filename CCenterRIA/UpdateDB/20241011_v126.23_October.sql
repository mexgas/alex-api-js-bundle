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
    Content	VARCHAR(250),
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
                    THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 2), '':'') WHERE Id = 2)
                    WHEN typeMessage IN (''image'', ''video'')
                    THEN
                        CASE
                            WHEN (SELECT COUNT(value) FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 4), '':'') WHERE Id = 2) = 0 -- soporte con mensajes de vonage
                            THEN (@baseFilePath + CHAR(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + CHAR(92) + CAST(conversationId/1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + CHAR(92) + typeMessage + CHAR(92) + messageId + CASE WHEN typeMessage = ''video'' THEN ''.mp4'' WHEN typeMessage = ''image'' THEN ''.jpg'' END)
                            ELSE (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content,''|'') WHERE Id = 2), '':'') WHERE Id = 2)
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
