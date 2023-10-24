/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 42
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

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

	-----------------------------------------------------BEGIN Marco Garcia KR099000 Nuevos permisos para roles de administradores -----------------------------------------------------------------
	SET @process = 'KR099001-Permiso de usuario asignación/desasignación de agentes a grupos de trabajo add permission with id 10034 to ccPermissions table'
SET @sql = 'IF NOT EXISTS(SELECT cp.Permissions_Id FROM dbo.ccPermissions AS cp WHERE cp.Permissions_Id = 10034)
		BEGIN
			INSERT INTO dbo.ccPermissions(Permissions_Id, Description, KeyJson, Parent, Type, OrderGrl, Release, Active) VALUES(10034, ''Monitorear áreas y asignar/desasignar usuarios'', ''RolesPermissionAreasUsers'', 0, 0, 0, ''N/A'', 1);
		END'
EXEC(@sql);

SET @process = 'KR099002-Consultar grabaciones sin permiso para descargar add permission with id 10035 to ccPermissions table'
SET @sql = 'IF NOT EXISTS(SELECT cp.Permissions_Id FROM dbo.ccPermissions AS cp WHERE cp.Permissions_Id = 10035)
		BEGIN
			INSERT INTO dbo.ccPermissions(Permissions_Id, Description, KeyJson, Parent, Type, OrderGrl, Release, Active) VALUES(10035, ''Acceder a buscador (sin descarga de archivos)'', ''RolesPermissionFinderNoDownloads'', 0, 0, 0, ''N/A'', 1);
		END'
EXEC(@sql);

set @process = 'KR099001-Permiso de usuario asignación/desasignación de agentes a grupos de trabajo add permission to root role'
		set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10034)
		begin
		  insert into ccRoles_Permissions values(1,10034)
		end'
		EXEC(@sql)

		set @process = 'KR099002-Consultar grabaciones sin permiso para descargar add permission to root role'
		set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10035)
		begin
		  insert into ccRoles_Permissions values(1,10035)
		end'
		EXEC(@sql)
	-----------------------------------------------------END Marco Garcia KR099000 Nuevos permisos para roles de administradores -----------------------------------------------------------------s
	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
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