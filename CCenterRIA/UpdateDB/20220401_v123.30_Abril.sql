/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 30
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

	set @process = 'CW-Roles permiso gestionar chats'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10015)
    begin
        insert into ccPermissions values (10015, ''Gestionar chat con agentes'', ''RolesPermissionChatManagement'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar chats'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10015)
    begin
        insert into ccRoles_Permissions values(1,10015)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar llamada'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10016)
    begin
        insert into ccPermissions values (10016, ''Gestionar monitoreo de llamada'', ''RolesPermissionCallMonitoring'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar llamada'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10016)
    begin
        insert into ccRoles_Permissions values(1,10016)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso solo monitoreo'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10017)
    begin
        insert into ccPermissions values (10017, ''Solo monitoreo'', ''RolesPermissionMonitoring'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol solo monitoreo'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10017)
    begin
        insert into ccRoles_Permissions values(1,10017)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar formatos'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10018)
    begin
        insert into ccPermissions values (10018, ''Gestionar formatos de evaluación'', ''RolesPermissionFormsManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar formatos'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10018)
    begin
        insert into ccRoles_Permissions values(1,10018)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar historial'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10019)
    begin
        insert into ccPermissions values (10019, ''Gestionar historial de actividad, ''RolesPermissionActivityLogManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar historial'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10019)
    begin
        insert into ccRoles_Permissions values(1,10019)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar autoinicio'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10020)
    begin
        insert into ccPermissions values (10020, ''Gestionar inicio automático'', ''RolesPermissionAutostartManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar autoinicio'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10020)
    begin
        insert into ccRoles_Permissions values(1,10020)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar calificaciones'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10021)
    begin
        insert into ccPermissions values (10021, ''Gestionar calificaciones'', ''RolesPermissionDispositionManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar calificaciones'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10021)
    begin
        insert into ccRoles_Permissions values(1,10021)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar marcacion'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10022)
    begin
        insert into ccPermissions values (10022, ''Gestionar factor de marcación fijo'', ''RolesPermissionDialFactorManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar marcacion'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10022)
    begin
        insert into ccRoles_Permissions values(1,10022)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar ani local'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10023)
    begin
        insert into ccPermissions values (10023, ''Gestionar lista de ANI local'', ''RolesPermissionANIListManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rolgestionar ani local'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10023)
    begin
        insert into ccRoles_Permissions values(1,10023)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar dnis'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10024)
    begin
        insert into ccPermissions values (10024, ''Gestionar números DNIS'', ''RolesPermissionDnisNumManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar dnis'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10024)
    begin
        insert into ccRoles_Permissions values(1,10024)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar listas negras'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10025)
    begin
        insert into ccPermissions values (10025, ''Gestionar listas negras'', ''RolesPermissionBlacklistManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar listas negras'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10025)
    begin
        insert into ccRoles_Permissions values(1,10025)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso acceder a reporteador'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10026)
    begin
        insert into ccPermissions values (10026, ''Acceder a reporteador'', ''RolesPermissionReporter'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol acceder a reporteador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10026)
    begin
        insert into ccRoles_Permissions values(1,10026)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso acceder a buscador'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10027)
    begin
        insert into ccPermissions values (10027, ''Acceder a buscador'', ''RolesPermissionFinder'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol acceder a buscador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10027)
    begin
        insert into ccRoles_Permissions values(1,10027)
    end'
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


