CREATE PROCEDURE [dbo].[ccsp_RIAADMChecaLogin] @Login            VARCHAR(40) = '', 
                                              @Password         VARCHAR(40) = '', 
                                              @PasswordLwC      VARCHAR(40) = NULL, 
                                              @adminId          INT         = 0, 
                                              @isChangePassword BIT         = 0
AS
     SET NOCOUNT ON;
     DECLARE @x INT;
     SET @x = 1;
     IF @adminId <> 0
         BEGIN
             UPDATE ccUsers
               SET 
                   onLine = 0
             WHERE User_id = @adminId;
             RETURN(0);
     END;
     DECLARE @UserID SMALLINT;
     --****
     DECLARE @TipoUser_idx INT;
     DECLARE @ver INT;
     DECLARE @changeRecDisposition INT;
     SET @ver = 0;
     SET @changeRecDisposition = 0;

     --****
     SELECT @UserID = User_id, @TipoUser_idx = TipoUser_id
     FROM ccUsers
     WHERE Login = @Login
           AND TipoUser_id IN(2, 6)
     AND STATUS > 0;
     IF(@TipoUser_idx = 2
        OR @TipoUser_idx = 6)
         BEGIN
             IF EXISTS
             (
                 SELECT *
                 FROM ccRIAUsr_AdminPermissions
                 WHERE User_id = @UserID
                       AND per_id IN(2, 6)
             )
                 BEGIN
                     SET @ver = 1;
             END;
             IF EXISTS
             (
                 SELECT *
                 FROM ccRIAUsr_AdminPermissions
                 WHERE User_id = @UserID
                       AND per_id = 7
             )
                 BEGIN
                     SET @changeRecDisposition = 1;
             END;
     END;
     IF NOT EXISTS
     (
         SELECT Login
         FROM ccUsers
         WHERE User_id = @UserID
               AND (Password = @Password
                    OR Password = dbo.md5(@password)
         OR dbo.md5(Password) = @Password
         OR Password = @PasswordLwC
         OR Password = dbo.md5(@PasswordLwC)
     OR dbo.md5(Password) = @PasswordLwC)
     )
         BEGIN             
             SELECT CASE
                        WHEN @UserID IS NULL THEN 0 ELSE 1
                    END 'LoginOK', 0 'PswdOK', 0 'UserID', 0 'Nombre', 0 'ADMServer', 0 'AreaId', 0 'viewavrs', 0 'changeRecDisposition', 0 'LastPasswordchange';
             RETURN(0);
     END;
     IF @isChangePassword = 1
         BEGIN
             UPDATE ccUsers
               SET 
                   Password = ISNULL(@PasswordLwC, Password)
             WHERE User_id = @UserID
                   AND Password <> @PasswordLwC;
     END;
     UPDATE ccUsers
       SET 
           onLine = 1
     WHERE User_id = @UserID;
     SELECT 1 'LoginOK', 1 'PswdOK', User_id 'UserID', Nombres + ' ' + ISNULL(ApellidoPaterno, '') + ' ' + ISNULL(ApellidoMaterno, '') 'Nombre',
     (
         SELECT valor
         FROM ccSettings
         WHERE setting_id = 8
     ) [ADMServer], ISNULL(IDArea, 0) 'AreaId', @ver 'ViewAvrs', @changeRecDisposition 'changeRecDisposition',
                                                                                       CASE
                                                                                           WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > 30 THEN 1 ELSE 0
                                                                                       END 'LastPasswordchange'
     FROM ccUsers
     WHERE User_id = @UserID;
     
     RETURN(0);
     SET NOCOUNT OFF;