---- =============================================
---- Author:		ulises Espinosa
---- Create date: 15/05/2020
---- Description:	Role management and permissions in galatea Admin
---- =============================================
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRolesManagement]
	@action SMALLINT,
	@User_id VARCHAR(MAX)= '',
	@subaction VARCHAR(50)= '',
	@description VARCHAR(250)= '',
	@keyJson VARCHAR(250)= '',
	@active BIT= 1,
	@Roles_id VARCHAR(MAX)= '',
	@Permissions_Id VARCHAR(MAX)= '',
	@menus_id VARCHAR(250)= ''
AS
--DECLARE
--	@action SMALLINT = 4,
--	@User_id VARCHAR(MAX) = '2',
--	@subaction VARCHAR(50)= '',
--	@description VARCHAR(250)= 'aa',
--	@keyJson VARCHAR(250)= '',
--	@active BIT= 1,
--	@Roles_id VARCHAR(50)= '1051',
--	@Permissions_Id VARCHAR(MAX)= '1,2',
--	@menus_id VARCHAR(250)= '';
BEGIN TRY
    BEGIN TRANSACTION;-- Inicia el bloque de la transaccion
	DECLARE @resultado varchar(50) = '';
	DECLARE @returnValue SMALLINT;
    BEGIN
	 IF @action = 1
        BEGIN
        IF @subaction = 'Permissions'
            BEGIN
                IF OBJECT_ID('tempdb..#Permissions') IS NOT NULL DROP TABLE #Permissions;

				SELECT DISTINCT
					   (rp.Permissions_id)
				INTO #Permissions
				FROM ccUsers_Roles ur
					 INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_id = ur.Rol_id
				WHERE User_id = @User_id;
				SELECT p.Permissions_Id, 
					   p.KeyJson, 
					   p.Parent, 
					   p.Type, 
					   p.OrderGrl,
					   CASE
						   WHEN tp.Permissions_Id IS NOT NULL
						   THEN 1
						   ELSE 0
					   END AS State
				FROM ccPermissions p
					 LEFT JOIN #Permissions tp WITH(NOLOCK) ON tp.Permissions_Id = p.Permissions_Id
				ORDER BY OrderGrl, 
						 Parent;
        END;
        IF @subaction = 'Roles'
            BEGIN
                SELECT r.Rol_id AS RolId, 
                       r.KeyJson, 
                       r.Description,
					   r.Level,
                       CONVERT(VARCHAR(10), r.CreateDate, 103) AS CreateDate,
                       CASE
                           WHEN ur.Rol_id IS NOT NULL
                           THEN 1
                           ELSE 0
                       END AS State,
					   STUFF(
								(SELECT ', ' + CAST(ur.User_id AS varchar)
								FROM ccUsers_Roles ur
								INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
								WHERE c.Rol_id = r.Rol_id
								FOR XML PATH ('')),
							1,2,'')As Users_Ids,
						STUFF(
								(SELECT ', ' + CAST(pr.Permissions_Id AS varchar)
								FROM ccRoles_Permissions pr
								INNER JOIN ccRoles C ON pr.Rol_id = C.Rol_id
								WHERE c.Rol_id = r.Rol_id
								FOR XML PATH ('')),
							1,2,'')As Permissions_ids
                FROM ccRoles r
                     LEFT JOIN ccUsers_Roles ur WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                                                                AND ur.User_id = @User_id
        END;
        IF @subaction = 'Users'
            BEGIN
                SELECT User_id, 
                       Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno AS Names
                FROM ccUsers
                WHERE TipoUser_id = 2 AND User_id > 1;
        END;
    END;
	END;
    IF @action = 2
        BEGIN
            SELECT p.Permissions_id, 
                   Parent, 
                   Type, 
                   OrderGrl
            FROM ccUsers_Roles ur
                 INNER JOIN ccRoles r WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                 INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_Id = ur.Rol_id
                 INNER JOIN ccPermissions p WITH(NOLOCK) ON p.Permissions_id = rp.Permissions_id
            WHERE ur.User_Id = @User_id
                  AND r.Active = 1
                  AND p.Active = 1;
    END;
    IF @action = 3 -- assign roles to user
        BEGIN
            IF OBJECT_ID('tempdb..#Users_Ids') IS NOT NULL DROP TABLE #Users_Ids
			IF OBJECT_ID('tempdb..#Users_split') IS NOT NULL DROP TABLE #Users_split
			IF OBJECT_ID('tempdb..#Roles_split') IS NOT NULL DROP TABLE #Roles_split
			
			SELECT value
			INTO #Users_split
			FROM fn_RIASplitDelimited(@User_id, ',')

			SELECT value
			INTO #Roles_split
			FROM fn_RIASplitDelimited(@Roles_id, ',')

			SELECT DISTINCT(User_id)
			INTO #Users_Ids
			FROM ccUsers_Roles
			WHERE User_id in (SELECT value FROM #Users_split)

			IF @subaction = 'NewRelate'
			BEGIN
				IF EXISTS( select top 1 * from #Users_Ids)
					BEGIN
						DELETE ccUsers_Roles
						WHERE User_id IN (select * from #Users_Ids);
					END
				END
			IF @Roles_id <> ''
			BEGIN
				INSERT INTO ccUsers_Roles
				select a.value User_id,b.value as Rol_id from #Users_split a
				CROSS JOIN #Roles_split b

			END
			SET @returnValue = (select top 1 * from  #Users_split)
    END;
    IF @action = 4 -- Delete Roles
        BEGIN
			IF OBJECT_ID('tempdb..#UsersIds') IS NOT NULL DROP TABLE #UsersIds
			SET @resultado = STUFF(
					(SELECT Distinct(', ' + CAST(ur.User_id AS varchar))
					FROM ccUsers_Roles ur
					INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
					WHERE c.Rol_id in (SELECT value FROM fn_RIASplitDelimited(@Roles_id, ','))
					FOR XML PATH ('')),
				1,2,'')
            IF OBJECT_ID('tempdb..#roles_permissions') IS NOT NULL DROP TABLE #roles_permissions
			IF OBJECT_ID('tempdb..#Users_Roles') IS NOT NULL DROP TABLE #Users_Roles

			SELECT DISTINCT(Rol_id)
			INTO #roles_permissions
				FROM ccroles_permissions a
						INNER JOIN
				(
					SELECT value
					FROM fn_RIASplitDelimited(@Roles_id, ',')
				) b ON b.value = a.Rol_Id

			SELECT  DISTINCT(value) AS Rol_id
			INTO #Users_Roles
			FROM fn_RIASplitDelimited(@Roles_id, ',') a
					INNER JOIN ccUsers_Roles b ON b.Rol_id = a.Value
			WHERE b.Rol_id IS NOT NULL
			IF EXISTS(SELECT TOP 1 * FROM #roles_permissions)
			BEGIN
				--select * from #roles_permissions
				DELETE ccroles_permissions WHERE Rol_id in (select Rol_id from #roles_permissions )
			END
			IF EXISTS(SELECT TOP 1 * FROM #Users_Roles)
			BEGIN
				--select * from #Users_Roles
				DELETE ccUsers_Roles WHERE Rol_id in (select Rol_id from #Users_Roles )
			END
			IF EXISTS(select top 1 Rol_id from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, ',')))
			BEGIN
				--select * from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, ','))
				DELETE ccRoles WHERE Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, ','))
				IF(@resultado IS NULL OR @resultado = '') SET @resultado = '1'
			END
		END;
    IF @action = 5 -- New Role
        BEGIN
            IF @menus_id <> ''
               OR @Permissions_Id <> ''
                BEGIN
                    DECLARE @exists BIT;
                    SET @returnValue = 0;
                    SET @exists = 1;

					/*IF @menus_id <> '' --Check if role with same menus exists
						BEGIN
							Para cuando esten los menus
						END*/

                    IF @Permissions_Id <> ''
                       AND @exists = 1 --Check if role with same permissions exists
                        BEGIN
                            IF NOT EXISTS
                            (
                                SELECT c.Rol_Id
                                FROM ccroles_permissions a
                                     INNER JOIN
                                (
                                    SELECT value
                                    FROM fn_RIASplitDelimited(@Permissions_Id, ',')
                                ) b ON b.value = a.Permissions_Id
                                     INNER JOIN
                                (
                                    SELECT Rol_id, 
                                           COUNT(*) AS contador
                                    FROM ccRoles_Permissions
                                    GROUP BY Rol_Id
                                ) AS c ON c.Rol_id = a.Rol_id
                                     INNER JOIN
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, ',')
                                ) d ON d.contador = c.contador
                                GROUP BY c.Rol_Id
                                HAVING COUNT(*) =
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, ',')
                                )
                            )
                                SET @exists = 0;
                    END;
                    IF @exists = 0 -- IF not exist role with same menus and permissions create
                        BEGIN
                            SELECT @exists = COUNT(*)
                            FROM ccRoles
                            WHERE Description = @description;
                            IF @exists = 0
                                BEGIN
                                    DECLARE @newRoleId INT;
                                    INSERT INTO ccroles
                                    (Description, 
                                     KeyJson, 
                                     CreateDate, 
                                     Active,
									 Level
                                    )
                                    VALUES
                                    (@description, 
                                     @keyJson, 
                                     GETDATE(), 
                                     @active,
									 1001
                                    );
                                    SELECT @newRoleId = SCOPE_IDENTITY();
                                    IF @Permissions_Id <> ''
                                        BEGIN
                                            INSERT INTO ccroles_permissions
                                                   SELECT @newRoleId, 
                                                          value
                                                   FROM fn_RIASplitDelimited(@Permissions_Id, ',') AS a
                                                        INNER JOIN ccPermissions b ON a.value = b.Permissions_Id
                                                   GROUP BY value;
                                    END;
                                    SET @returnValue = @newRoleId; --  if new role was created return Role_id
                            END;
                                ELSE
                                BEGIN
                                    SET @returnValue = -1;
                            END;-- else if role name exists, return -1
                    END;
                    --SELECT @returnValue; --  else if exists role with same menus & permissions, return 0
            END;
    END;
    COMMIT TRANSACTION;
	if @resultado <>''
	begin
		select @resultado
	end
	else
	begin
    -- Indica que la operación se efectuo correctamente
		SELECT @returnValue
	end
END TRY

/* Manejo de error de la transacción */

BEGIN CATCH
	SET @returnValue = -1;
    SELECT @returnValue
    ROLLBACK TRANSACTION;
END CATCH;