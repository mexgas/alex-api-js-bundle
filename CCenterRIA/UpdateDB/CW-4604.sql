
set @process = 'CW-4604 Alter sp ccsp_GalateaAdminLogin'
set @sql = '
  ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(40) = '''', 
                                                 @Password    VARCHAR(40) = '''', 
                                                 @PasswordLwC VARCHAR(40) = NULL, 
                                                 @IPAddress   VARCHAR(20) = '''', 
                                                 @adminId     INT         = 0
  AS
      BEGIN
          SET NOCOUNT ON;
          DECLARE @LoginOK BIT= 0, @PswdOK BIT= 0, @User_id SMALLINT, @Nombre VARCHAR(100), @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, @PasswordExpired INT= 0, @UsernameMatch BIT= 1, @UserBlocked BIT= 0, @LastPasswordChange DATETIME, @Ext VARCHAR(80), @ViewAgents BIT= 0, @Theme smallint = 0;
          CREATE TABLE #temp
          (LoginOK              INT, 
           PswdOK               INT, 
           User_id              SMALLINT, 
           Nombre               VARCHAR(100), 
           ADMServer            VARCHAR(300), 
           AreaId               SMALLINT, 
           ViewAvrs             INT, 
           changeRecDisposition INT, 
           LastPasswordchange   INT
          );
          INSERT INTO #temp
          EXEC ccsp_RIAADMChecaLogin 
               @Login, 
               @Password, 
               @PasswordLwC, 
               @adminId;
          SELECT @LoginOK = LoginOK, 
                 @PswdOK = PswdOK, 
                 @Nombre = Nombre, 
                 @ADMServer = ADMServer, 
                 @AreaId = AreaId, 
                 @ViewAvrs = ViewAvrs, 
                 @changeRecDisposition = changeRecDisposition, 
                 @PasswordExpired = LastPasswordchange
          FROM #temp;
          IF @LoginOK = 1
              BEGIN
                  SELECT @User_id = User_id, 
                         @ViewAgents = viewAgents,
  					   @Theme = theme
                  FROM ccUsers
                  WHERE Login = @Login;
                  DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, @TimeBloqued INT, @TimeFromLastAttempt INT;
                  SELECT @LastLoginAttempt = LastLoginAttempt, 
                         @LoginAttempts = LoginAttempts, 
                         @LastPasswordChange = LastPasswordChange
                  FROM ccUsers
                  WHERE User_id = @User_id;
                  SELECT @MaxAttemptsAllow = valor
                  FROM ccSettings
                  WHERE setting_id = 198;
                  SELECT @TimeBloqued = valor
                  FROM ccSettings
                  WHERE setting_id = 197;
                  SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE());
                  IF @LoginAttempts > @MaxAttemptsAllow
                      BEGIN
                          SET @LoginAttempts = 0;
                          UPDATE ccUsers
                            SET 
                                LoginAttempts = 0, 
                                LastLoginAttempt = GETDATE()
                          WHERE User_id = @User_id;
                  END;
                  IF(@LoginAttempts >= @MaxAttemptsAllow
                     AND @TimeFromLastAttempt < @TimeBloqued)
                      BEGIN
                          SET @UserBlocked = 1;
                  END;

                  --Checks Username match case sensitive    
                  IF CAST(@Login AS VARBINARY(200)) <>
                  (
                      SELECT CAST(LOGIN AS VARBINARY(200))
                      FROM ccUsers
                      WHERE User_id = @User_id
                  )
                      BEGIN
                          SET @UsernameMatch = 0;
                  END;

                  --Increments attemps if error
                  IF @UserBlocked = 0
                     AND (@UsernameMatch = 0
                          OR @PswdOK = 0)
                      BEGIN
                          UPDATE ccUsers
                            SET 
                                LoginAttempts = @LoginAttempts + 1, 
                                LastLoginAttempt = GETDATE(), 
                                onLine = 0
                          WHERE User_id = @User_id;
                  END;

                  --Sets to default to try another attempt
                  DECLARE @ExpirationTime INT;
                  SELECT @ExpirationTime = valor
                  FROM ccSettings
                  WHERE setting_id = 29;
                  SELECT @PasswordExpired = (CASE
                                                 WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > @ExpirationTime
                                                      AND @ExpirationTime > 0
                                                 THEN 1
                                                 ELSE 0
                                             END)
                  FROM ccUsers;
                  IF @UserBlocked = 0
                     AND @UsernameMatch = 1
                     AND @PswdOK = 1
                     AND @PasswordExpired = 0
                      BEGIN
                          UPDATE ccUsers
                            SET 
                                LoginAttempts = 0, 
                                LastLoginAttempt = GETDATE(), 
                                onLine = 1
                          WHERE User_id = @User_id;
                  END;
                  SELECT @Ext = dbo.fn_Ext_X_ip(@IPAddress);
                  
  				DECLARE @WorkGroup VARCHAR(MAX);
                  SELECT @WorkGroup = COALESCE(@WorkGroup + ''|'' + CAST(IDWG AS VARCHAR(MAX)), CAST(IDWG AS VARCHAR(MAX)))
                  FROM ccRIAWorkGroupUsers
                  WHERE User_id = @User_id;
          END;
          SELECT @LoginOK UserExists, 
                 @UserBlocked UserBlocked, 
                 @UsernameMatch UsernameMatch, 
                 @PswdOK PasswordMatch, 
                 CAST(@PasswordExpired AS BIT) PasswordExpired, 
                 @User_id UserID, 
                 @Nombre Name, 
                 @ADMServer ADMServer, 
                 @AreaId AreaId, 
                 @ViewAvrs ViewAvrs, 
                 @changeRecDisposition ChangeRecDisposition, 
                 @Ext Ext, 
                 isnull(@ViewAgents,0) ViewAgents,
  			   ISNULL(@WorkGroup, 0) WorkGroup,
  			   ISNULL(@Theme, 0) Theme;
      END;
  '
EXEC(@sql)