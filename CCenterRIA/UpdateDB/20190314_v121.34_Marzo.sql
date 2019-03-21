/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez
		Karen Rodríguez
		
Date: 2019/03/12
Description: 

Database: CCenterRia
Required version: 121.33

Se agrega la tarea
CW-2729-Validar_setting_para_no_tener_admin_y_agente_al_mismo_tiempo

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 34

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 33
BEGIN
	BEGIN TRAN
	BEGIN TRY
		SET @process = 'CW-2729 Create table ccGalateaActiveSession'
		SET @Sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccGalateaActiveSession'')
BEGIN
CREATE TABLE ccGalateaActiveSession(
	session_id int IDENTITY(1,1) PRIMARY KEY,
	[user_id] smallint NOT NULL ,
	user_ip varchar(30) NOT NULL,
	FOREIGN KEY (user_id)
	REFERENCES ccUsers(User_id)
)
END
		'
		EXEC (@Sql)
		SET @process = 'CW-2617 Drop SP ccsp_GalateaAdminLogin'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminLogin'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminLogin;
    end'
		EXEC (@Sql)


		SET @process = 'CW-2697 Galatea Login Admin'
		SET @Sql = '	CREATE PROCEDURE [dbo].[ccsp_GalateaAdminLogin] 
	@Login varchar(20) = '''',
	@Password varchar(40) = '''',
	@PasswordLwC varchar(40) = null,
	@IPAddress varchar(20) = '''',
	@adminId int = 0
AS
begin
SET NOCOUNT ON

	DECLARE @LoginOK bit = 0, 
			@PswdOK bit = 0,
			@User_id smallint, 
			@Nombre varchar(100), 
			@ADMServer varchar(300), 
			@AreaId smallint, 
			@ViewAvrs int, 
			@changeRecDisposition int, 
			@PasswordExpired int = 0,
			@UsernameMatch bit = 1,
			@UserBlocked bit = 0,
			@LastPasswordChange datetime,
			@Ext varchar(80);

	CREATE TABLE #temp 
	(LoginOK int, 
		PswdOK int,
		User_id smallint, 
		Nombre varchar(100), 
		ADMServer varchar(300), 
		AreaId smallint, 
		ViewAvrs int, 
		changeRecDisposition int, 
		LastPasswordchange int );

	INSERT INTO #temp
	exec ccsp_RIAADMChecaLogin @Login, @Password, @PasswordLwC, @adminId

	SELECT  @LoginOK = LoginOK, @PswdOK = PswdOK, @User_id = User_id, @Nombre = Nombre, @ADMServer=ADMServer,@AreaId=AreaId,
		@ViewAvrs = ViewAvrs, @changeRecDisposition=changeRecDisposition, @PasswordExpired =LastPasswordchange	 FROM #temp
	
	IF @LoginOK = 1 
	BEGIN 
		DECLARE @LastLoginAttempt DATETIME, @LoginAttempts int, @MaxAttemptsAllow int, @TimeBloqued int, @TimeFromLastAttempt int
		SELECT @LastLoginAttempt = LastLoginAttempt,
				 @LoginAttempts = LoginAttempts, 
				 @LastPasswordChange = LastPasswordChange FROM  ccUsers WHERE User_id = @User_id 
		SELECT @MaxAttemptsAllow = valor FROM  ccSettings WHERE setting_id = 198
		SELECT @TimeBloqued = valor FROM  ccSettings WHERE setting_id = 197
		SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE())  
		IF @LoginAttempts > @MaxAttemptsAllow  
		BEGIN
			SET @LoginAttempts = 0
			UPDATE ccUsers SET LoginAttempts = 0, LastLoginAttempt = GETDATE() WHERE User_id = @User_id 
		END
		IF(@LoginAttempts >= @MaxAttemptsAllow AND @TimeFromLastAttempt < @TimeBloqued)
		BEGIN 
			SET @UserBlocked = 1
		END 

		
		--Checks Username match case sensitive    
		IF CAST(@Login as varbinary(200)) <> (SELECT CAST(LOGIN as varbinary(200)) FROM ccUsers WHERE User_id = @User_id )
		BEGIN 
			SET @UsernameMatch = 0
		END
		
		--Increments attemps if error
		IF   @UserBlocked = 0  AND (@UsernameMatch = 0 OR @PswdOK = 0)
		BEGIN
			UPDATE ccUsers SET LoginAttempts = @LoginAttempts + 1, LastLoginAttempt = GETDATE(), onLine = 0  WHERE User_id = @User_id 

		END
		
		--Sets to default to try another attempt
		DECLARE @ExpirationTime int 
		SELECT @ExpirationTime = valor FROM ccSettings where setting_id = 29
		SELECT @PasswordExpired = (CASE WHEN DATEDIFF(DAY,LastPasswordChange ,GETDATE()) > @ExpirationTime AND @ExpirationTime>0 THEN 1 ELSE 0 END )  FROM ccUsers

		IF   @UserBlocked = 0  AND @UsernameMatch = 1 AND  @PswdOK = 1 AND @PasswordExpired = 0
		BEGIN
			UPDATE ccUsers SET LoginAttempts = 0, LastLoginAttempt = GETDATE() WHERE User_id = @User_id 
		END
		
		SELECT @Ext = dbo.fn_Ext_X_ip (@IPAddress);
	END


	SELECT @LoginOK UserExists, @UserBlocked UserBlocked , @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, CAST(@PasswordExpired AS BIT) PasswordExpired, @User_id UserID,
	@Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition, @Ext Ext

END
'
		EXEC (@Sql)
		SET @process = 'CW-2729 Drop SP ccsp_GalateaValidateActiveSession'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaValidateActiveSession'')
    begin
        DROP PROCEDURE ccsp_GalateaValidateActiveSession;
    end'
		EXEC (@Sql)


		SET @process = 'CW-2729 Create ccsp_GalateaValidateActiveSession'
		SET @Sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaValidateActiveSession]
@userId varchar(30),
@userIp varchar(30),
@action tinyint = NULL,
@userType tinyint -- 1-Agente 2-Admin
AS
--VALIDA QUE NO EXISTA UN MISMO USUARIO CON LA MISMA SESION Y QUE
--EL SETING DE LA SESION ESTA ACTIVO.
	IF @action = 1
	BEGIN
		IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 110 and valor = 0)
		BEGIN
			IF EXISTS (SELECT * FROM ccGalateaActiveSession WHERE user_ip = @userIp) 
			BEGIN
				--SE OBTIENE EL TIPO DE USUARIO YA REGISTRADO
				IF 0 <> (
						SELECT TOP 1 ccUsers.User_id
						FROM ccUsers
						LEFT JOIN ccGalateaActiveSession 
						ON ccGalateaActiveSession.user_id = ccUsers.User_id
						where ccUsers.TipoUser_id <> @userType
						AND ccGalateaActiveSession.user_ip = @userIp
				)
				BEGIN
					SELECT cast (1 as bit) ''IpAlreadyExists'' 
				END
				ELSE
				BEGIN
					SELECT cast (0 as bit) ''IpAlreadyExists'' 
				END
			END
			ELSE
			BEGIN
				SELECT cast (0 as bit) ''IpAlreadyExists'' 
			END
		END
		ELSE
		BEGIN
			SELECT cast (0 as bit) ''IpAlreadyExists'' 
		END
	END
	--INSERTA EN LA TABLA DE SESIONES ACTIVAS EL REGISTRO DEL USUARIO ACTUAL
	IF @action = 2
	BEGIN 	
		INSERT INTO ccGalateaActiveSession VALUES (@userId, @userIp) 
	END
	--ELIMINA EN LA TABLA DE SESIONES ACTIVAS EL REGISTRO DEL USUARIO ACTUAL
	IF @action = 3
	BEGIN
		DELETE FROM ccGalateaActiveSession WHERE @userId = user_id
	END
		'
		EXEC (@Sql)
		
		
		set @process = 'Cambios lenguaje'
		set @Sql= 'update ccRIALog_Module set descripcion=''RECORDING SERVER|RECORDING SERVER'' where module_id=59
					update ccRIALog_Module set descripcion=''RECORDINGS MANAGER|RECORDINGS MANAGER'' where module_id=57
					update ccRIALog_Operation set descripcion=''ADJUNTAR EN EMAIL|EMAIL FILE''where operationType=172'
		EXEC(@Sql)

				

		-- *********************** END  121.03-3_201900307 *********************** ---


				/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix
		
		
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
