/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 
		
Date: 2019/01/08
Description:

Database: CCenterRia
Required version: 121.31

Se agrega la tarea
CW-2031
CW-2576
CW-2487

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
SET @versionfix = 33

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 32
BEGIN
	BEGIN TRAN
	BEGIN TRY			
		SET @process = 'CW-2697 Galatea Login Admin'
		SET @Sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin]
@Login varchar(20) = '''',
@Password varchar(40) = '''',
@PasswordLwC varchar(40) = null,
@adminId int = 0

as
set nocount on

declare @x int
set @x=1

if @adminId <> 0
begin
update ccUsers set onLine = 0 where User_id = @adminId
return(0)
end

declare @UserID smallint
--****
declare @TipoUser_idx int
declare @ver int
declare @changeRecDisposition int
set @ver = 0
set @changeRecDisposition = 0

--****
select @UserID=User_id,@TipoUser_idx=TipoUser_id from ccUsers Where Login=@Login AND TipoUser_id in(2,6) and status>0

if(@TipoUser_idx=2 or @TipoUser_idx=6)
begin
if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id in (2,6))
begin
set @ver = 1
end
if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id=7)
begin
set @changeRecDisposition = 1
end
end

if not exists (select Login from ccUsers Where User_id=@UserID
AND(Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
OR Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC))
begin
SELECT case when @UserID is null then 0 else 1 end ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId'', 0 ''viewavrs'',0 ''changeRecDisposition'', 0 ''LastPasswordchange''
return(0)
end

update ccUsers set Password=isnull(@PasswordLwC, Password) Where User_id=@UserID and Password<>@PasswordLwC

update ccUsers set onLine = 1 where User_id = @UserID

Select 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'',
Nombres +'' ''+ isnull(ApellidoPaterno,'''') +'' ''+isnull(ApellidoMaterno,'''') ''Nombre'',
(SELECT valor FROM ccSettings WHERE setting_id=8) [ADMServer],
isnull(IDArea,0) ''AreaId'',
@ver  ''ViewAvrs'', @changeRecDisposition  ''changeRecDisposition'',
CASE when DATEDIFF(DAY,LastPasswordChange ,GETDATE()) >30 THEN 1 ELSE 0 END ''LastPasswordchange''
From ccUsers Where User_id=@UserID
return(0)
set nocount off   
		'
		EXEC (@Sql)
		

		SET @process = 'CW-2697 Galatea Login Admin'
		SET @Sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminLogin] 
	@Login varchar(20) = '''',
	@Password varchar(40) = '''',
	@PasswordLwC varchar(40) = null,
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
			@LastPasswordChange datetime

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
		SELECT @PasswordExpired = (CASE WHEN DATEDIFF(DAY,LastPasswordChange ,GETDATE()) > @ExpirationTime AND @ExpirationTime>0 THEN 1 ELSE 0 END ) FROM ccUsers

		IF   @UserBlocked = 0  AND @UsernameMatch = 1 AND  @PswdOK = 1 AND @PasswordExpired = 0
		BEGIN
			UPDATE ccUsers SET LoginAttempts = 0, LastLoginAttempt = GETDATE() WHERE User_id = @User_id 
		END
		
	END


	SELECT @LoginOK UserExists, @UserBlocked UserBlocked , @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, @PasswordExpired PasswordExpired, @User_id UserID,
	@Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition

END
		'
		EXEC (@Sql)
		
		
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
