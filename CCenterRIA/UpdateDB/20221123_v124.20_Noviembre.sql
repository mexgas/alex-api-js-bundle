/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 123.27

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 20
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


set @process = 'DEV3-154 Alter ccUsers add AllowMarks'
set @sql = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccUsers'' AND COLUMN_NAME = ''AllowMarks'')
	Begin
	ALTER TABLE ccUsers 
	ADD AllowMarks bit NOT NULL
	CONSTRAINT DF_ccUsers_AllowMarks DEFAULT 1
	WITH VALUES
	End'
EXEC(@sql)


set @process = 'DEV3-154 Insert AllowMarks permission in ccRIAAgentsPermissionsTags'
set @sql = 'IF EXISTS (SELECT NAME FROM sys.tables WHERE name = N''ccRIAAgentsPermissionsTags'')
BEGIN
	IF NOT EXISTS (SELECT PermissionId FROM ccRIAAgentsPermissionsTags WHERE PermissionId = 15)
	BEGIN
		INSERT INTO ccRIAAgentsPermissionsTags (PermissionId, PermissionName, PermissionTag)
		VALUES (15, ''AllowMarks'',  ''Añadir marcas a grabaciones|Add marks to recordings|Adicionar marcas às gravações'')
	END
END'
EXEC(@sql)


set @process = 'DEV3-154 Drop procedure ccsp_GalateaAdminGetPermissions'
set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminGetPermissions'')
BEGIN
	DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
END'
EXEC(@sql)


set @process = 'DEV3-154 Create Procedure ccsp_GalateaAdminGetPermissions'
set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
@user_id varchar(255),
@Type int
AS
set nocount on

declare @isRoot int;

if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
print @isRoot

IF @isRoot = 1
BEGIN
	Select 
	User_id as AgentId, 
	Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
	cast(dialMask & 1 as int) as AllowCellPhoneCalls,
	cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
	cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
	cast( xfermask as int) as AllowTransferCalls, 
	cast(CanChangeStatus as tinyint) CanChangeStatus,
	cast(XferAgents as tinyint) XferAgents,
	ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
	cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
	ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
	ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
	ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
	ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
	cast(AllowDeleteRecord as int) as AgentPermissionDelete,
	AllowMarks as AllowMarks
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
	cast(dialMask & 1 as int) as AllowCellPhoneCalls,
	cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
	cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
	cast( xfermask as int) as AllowTransferCalls, 
	cast(CanChangeStatus as tinyint) CanChangeStatus,
	cast(XferAgents as tinyint) XferAgents,
	ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
	cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
	ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
	ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
	ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
	ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
	cast(AllowDeleteRecord as int) as AgentPermissionDelete,
	AllowMarks as AllowMarks
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
set nocount off'
EXEC(@sql)


set @process = 'DEV3-154 Drop procedure ccsp_GalateaAdminSetPermissions'
set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminSetPermissions'')
BEGIN
	DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
END'
EXEC(@sql)


set @process = 'DEV3-154 Create procedure ccsp_GalateaAdminSetPermissions'
set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
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

		INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
		SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
		LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
		WHERE permissions.AgentId IS NULL
	END
	IF @permissionName = ''AllowSpam''
	BEGIN 
		UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
		INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

		INSERT INTO ccRIAAgentsPermissions(AgentId, AllowSpam, AllowUnassign, AllowPlayRecordsOnCallHistory)
		SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
		LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
		WHERE permissions.AgentId IS NULL
	END

	IF @permissionName = ''AllowPlayRecordsOnCallHistory''
	BEGIN 
		UPDATE permissions SET permissions.AllowPlayRecordsOnCallHistory = @permissionValue FROM @AgentIdsTemp agentIds
		INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

		INSERT INTO ccRIAAgentsPermissions(AgentId, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign)
		SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
		LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
		WHERE permissions.AgentId IS NULL
	END

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
			WHEN @permissionValue = 1
			THEN 1
			WHEN @permissionValue = 0
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
        END
	WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)

					
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

SET NOCOUNT OFF'
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
