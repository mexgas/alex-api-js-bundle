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

	
    set @process = 'CW-Roles se quita relacion permiso-rol Solo monitoreo'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10017)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10017
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Areas'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10007)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10007
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestion de Campañas eliminar,agregar, etc'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10013)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10013
    end'
    EXEC(@sql)

	/* Supervisor */
    set @process = 'CW-Roles se quita relacion permiso-rol CenterScript|CenterScript'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10003)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 6 AND Permissions_Id = 10003
    end'
    EXEC(@sql)
    /************************/
    set @process = 'CW-Roles se quita relacion permiso-rol Iniciar y detener campañas|Start and stop Campaign'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10001)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10001)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Carga de base de datos|Data Import'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10002)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10002)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Eliminar nuevos registros|Delete new records'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10005)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10005)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Devolucion de llamada|CallBacks'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10006)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10006)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar de areas'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10008)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10008)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar tipos de no disponible'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10009)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10009)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar permisos de agente'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10010)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10010)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar campañas'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10011)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10011)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar horarios'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10014)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10014)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar chat con agentes'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10015)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10015)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar monitoreo de llamada'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10016)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10016)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar inicio automático'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10020)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10020)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar calificaciones'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10021)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10021)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestionar listas negras'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10025)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10025)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Acceder a reporteador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10026)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10026)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Acceder a buscador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10027)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10027)
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


