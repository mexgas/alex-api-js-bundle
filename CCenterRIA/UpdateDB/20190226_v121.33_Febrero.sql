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
		SET @process = 'CW-2617 Drop SP ccsp_GalateaAdminLogin'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminLogin'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminLogin;
    end'
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
		

		-- *********************** Start  121.03-3_20190227 *********************** ---


		SET @process = 'CW-2617 update  Area location DF --> CDMX '
		SET @Sql = 'update ccTimeZoneArea set location=''CDMX'' where id_country=1 and location=''DF'''
		EXEC (@Sql)

		SET @process = 'CW-2617 Add Area ccTimeZoneArea '
		SET @Sql = 'if not exists(select * from ccTimeZoneArea where id_country=1 and area=''56'') begin
		insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''221'',''PUE'',64,32)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''479'',''GTO'',64,32)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''56'',''CDMX'',64,32)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''663'',''BC'',256,128)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''729'',''MEX'',64,32)
end '
		EXEC (@Sql)


		SET @process = 'CW-2642 Cerate Table ccRiaArecode '
		SET @Sql = 'IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''ccRiaArecode''
		)
BEGIN
	CREATE TABLE ccRiaArecode (area VARCHAR(10) NOT NULL, PRIMARY KEY (area))
END'
		EXEC (@Sql)

		SET @process = 'CW-2642 ALTER FN Completa '
		SET @Sql = 'ALTER FUNCTION [dbo].[Completa] (@phone VARCHAR(32), @pais VARCHAR(2) = '''', @cldLocal VARCHAR(5) = '''')
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @resultado VARCHAR(32)
	DECLARE @ld VARCHAR(7)
	DECLARE @isLocal BIT

	IF @pais = ''''
	BEGIN
		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104
	END

	IF @cldLocal = ''''
	BEGIN
		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17
	END

	SELECT @phone = dbo.limpia(@phone)

	SELECT @resultado = @phone

	DECLARE @lenPhone INT, @lenLd INT

	SET @lenPhone = len(@resultado)
	SET @lenLd = len(@cldLocal)

	IF @pais = 1
	BEGIN --Empieza Mexico 		
		IF @lenPhone < 10
		BEGIN
			RETURN ''E_NV_Longitud'';
		END

		IF @lenPhone = 12 AND left(@phone, 2) <> ''01''
		BEGIN
			RETURN ''E_NV_Longitud'';
		END

		IF @lenPhone = 13 AND left(@phone, 3) NOT IN (''044'', ''045'')
		BEGIN
			RETURN ''E_NV_Longitud'';
		END

		SET @resultado = right(@resultado, 10)
		SET @isLocal = 0

		DECLARE @specialDialPlan TINYINT

		SELECT @specialDialPlan = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 195

		IF EXISTS (
				SELECT TOP 1 area
				FROM ccRiaArecode NOLOCK
				WHERE area = left(@resultado, 3)
				)
			SELECT @ld = left(@resultado, 3), @isLocal = 1
		ELSE IF EXISTS (
				SELECT TOP 1 area
				FROM ccRiaArecode NOLOCK
				WHERE area = left(@resultado, 2)
				)
			SELECT @ld = left(@resultado, 2), @isLocal = 1
		ELSE
		BEGIN
			SET @ld = @cldLocal

			IF left(@resultado, len(@ld)) = @ld
			BEGIN
				SET @isLocal = 1
			END
		END

		SET @lenLd = len(@ld)

		IF @specialDialPlan = 1
		BEGIN
			--Number local 10 digit
			--Number LD 12 digit
			--Number Cell 13 digit
			SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE ''01'' + @resultado END --10 Dig Local, LD
					WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE @phone END --12 Dig Local, LD
					WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
					ELSE ''E_NV_Longitud'' END --Other Long
		END
		ELSE IF @specialDialPlan = 0
		BEGIN
			--Number local 7 o 8 digit
			--Number LD 12 digit
			--Number Cell 13 digit
			SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE ''01'' + @resultado END --10 Dig Local, LD
					WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE @phone END --12 Dig Local, LD							
					WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
					ELSE ''E_NV_Longitud'' END
		END

		--Termina Mexico
		RETURN @resultado
	END
	ELSE IF @pais = 2
	BEGIN -- Empieza Argentina
		SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 3) OR (@lenPhone = 6 AND @lenLd = 4) THEN @resultado
						-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
						-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
				WHEN @lenPhone = 8 THEN CASE WHEN @lenLd = 4 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado END ELSE CASE WHEN @lenLd = 2 THEN @resultado END END
						-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
				WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''E_NV_Cel'' END
						-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
						-- Si es diferente se le agrega un 0 para llamadas de larga distancia
				WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''0'' + @resultado END END
						-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
						-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
				WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END
						-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
						-- si no es local se le agrega el 0 y se marca el numero
				WHEN @lenPhone = 12 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN CASE WHEN substring(@resultado, @lenLd + 1, 2) = ''15'' THEN right(@resultado, 12 - @lenLd) ELSE ''E_NV_Cel'' END ELSE ''0'' + @resultado END
						-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
				WHEN @lenPhone = 13 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN substring(@resultado, @lenLd + 2, 12 - @lenLd) ELSE @resultado END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END

		--Termina Argentina
		RETURN @resultado
	END
	ELSE IF @pais = 3
	BEGIN --Empieza colombia
		SELECT @resultado = CASE 
				--Si son 7 digitos, se regresa igual
				WHEN @lenPhone = 7 THEN @resultado
						--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
				WHEN @lenPhone = 8 THEN CASE WHEN left(@resultado, 1) = @cldLocal THEN right(@resultado, 7) ELSE @resultado END
						-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
				WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN ''0'' + @resultado ELSE ''E_NV_Cel'' END
						--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
						--prefijo de celular
				WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END

		-- Termina Colombia
		RETURN @resultado
	END
	ELSE IF @pais = 4
	BEGIN --Empieza USA
		SELECT @resultado = CASE @lenPhone WHEN 3 THEN CASE @resultado WHEN ''911'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN @resultado WHEN 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE ''1'' + @resultado END WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''1'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END ELSE ''E_NV_Longitud'' END

		--Termina USA
		RETURN @resultado
	END
	ELSE IF @pais = 5
	BEGIN --5:Chile
		SELECT @resultado = CASE @lenPhone WHEN 6 THEN @resultado WHEN 7 THEN @resultado
						-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
				WHEN 8 THEN CASE WHEN @cldLocal = left(@resultado, @lenLd) THEN right(@resultado, 8 - @lenLd) ELSE CASE WHEN left(@resultado, 1) IN (8, 9) THEN ''09'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''6'' THEN CASE WHEN left(@resultado, 2) IN (61, 63, 64, 65, 67) THEN @resultado ELSE ''09'' + @resultado END ELSE CASE WHEN left(@resultado, 1) = ''7'' THEN CASE WHEN left(@resultado, 2) IN (71, 72, 73, 75) THEN @resultado ELSE ''09'' + @resultado END ELSE @resultado END END END END
						-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
						-- de telefonia voIp se le agrega el 0 al inicio
				WHEN 9 THEN CASE WHEN @cldLocal = left(@resultado, 2) THEN right(@resultado, 7) ELSE CASE WHEN left(@resultado, 2) IN (41, 32, 65) THEN @resultado ELSE CASE WHEN left(@resultado, 2) = ''44'' THEN ''0'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''9'' AND substring(@resultado, 2, 1) IN (6, 7, 8, 9) THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END END END END WHEN 10 THEN CASE WHEN left(@resultado, 2) = ''09'' THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END

		-- Termina Chile
		RETURN @resultado
	END

	IF @pais = 6
	BEGIN -- Venezuela
		SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 10 THEN ''0'' + @resultado WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END

		RETURN @resultado
	END
			--Termina Venezuela
	ELSE IF @pais = 7
	BEGIN --7: Reino Unido
		SELECT @resultado = CASE @lenPhone WHEN 11 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''0'' + @resultado END WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END WHEN 8 THEN CASE WHEN substring(@resultado, 1, 2) = ''08'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN CASE WHEN left(@resultado, 1) = ''8'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END

		RETURN @resultado
	END
			-- Termina UK
	ELSE IF @pais = 8
	BEGIN -- arabia saudita
		SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 8 THEN CASE substring(@resultado, 1, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE ''0'' + @resultado END WHEN 9 THEN CASE substring(@resultado, 1, 1) WHEN ''5'' THEN ''0'' + @resultado WHEN ''0'' THEN CASE substring(@resultado, 2, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE @resultado END ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE substring(@resultado, 2, 1) WHEN ''5'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 11 THEN CASE substring(@resultado, 2, 1) WHEN ''8'' THEN CASE substring(@resultado, 3, 3) WHEN ''111'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE CASE WHEN substring(@resultado, 3, 3) = ''510'' OR substring(@resultado, 3, 3) = ''511'' THEN @resultado ELSE ''E_NV_Longitud'' END END WHEN 13 THEN @resultado ELSE ''E_NV_Longitud'' END

		RETURN @resultado
	END -- arabia saudita
	ELSE IF @pais = 9
	BEGIN --Australia
		SELECT @resultado = CASE @lenPhone WHEN 8 THEN
						/*case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,@cldLocal)
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
						CASE substring(@resultado, 1, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @cldLocal + @resultado END
						/*else case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,''04'')
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
    ''04'' +  @resultado
    else ''E_NV_Cel'' end end*/
				WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN CASE substring(@resultado, 2, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE ''0'' + @resultado END ELSE ''E_NV_LD'' END WHEN 10 THEN CASE substring(@resultado, 3, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @resultado END ELSE ''E_NV_Longitud'' END

		RETURN @resultado
	END
	ELSE IF @pais = 10
	BEGIN --Brasil
		SELECT @resultado = CASE @lenPhone
				--llamada local fijo o celular
				WHEN 8 THEN @resultado WHEN 9 THEN @resultado WHEN 10 THEN -- Numero nacional
						CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 8) ELSE @resultado END WHEN 11 THEN -- Este caso solomente es para numero celular
						CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 9) ELSE @resultado END WHEN 12 THEN -- llamadas por cobrar local
						CASE WHEN (left(@resultado, 4) = ''9090'') THEN right(@resultado, 8) ELSE ''E_NV_PC'' END WHEN 13 THEN CASE WHEN left(@resultado, 4) = ''9090'' THEN right(@resultado, 9) -- llamadas por cobrar local celular
							WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 10) END -- llamadas de LDN
							ELSE ''E_NV_Longitud'' END WHEN 14 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- llamadas por cobrar larga distancia
									CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 11) END WHEN left(@resultado, 1) = ''0'' THEN --llamada larga distancia a celular
									CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END WHEN 15 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- Llamadas por cobrar a celular LD
									CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END

		RETURN @resultado
	END
	ELSE IF @pais = 11
	BEGIN --Guatemala
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,3,4,5,6,7'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE
			SELECT @resultado = ''E_NV_Longitud''

		RETURN @resultado
	END
	ELSE IF @pais = 12
	BEGIN --Costa Rica
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF @lenPhone = 10 AND charindex(substring(@resultado, 1, 3), ''800,900,905'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), ''00,08'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END

		RETURN @resultado
	END
	ELSE IF @pais = 13
	BEGIN --Salvador
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,6,7'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END

		RETURN @resultado
	END
	ELSE IF @pais = 14
	BEGIN --Spain
		IF @lenPhone = 9 AND charindex(substring(@resultado, 1, 1), ''5,6,7,8,9'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END

		RETURN @resultado
	END
	ELSE IF @pais = 15
	BEGIN --Peru
		SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 1) OR (@lenPhone = 6 AND @lenLd = 2) THEN @resultado WHEN @lenPhone = 8 THEN CASE WHEN substring(@resultado, 1, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE ''0'' + @resultado END WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 1) = ''0'' AND substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE @resultado END ELSE ''E_NV_Longitud'' END

		RETURN @resultado
	END --Termina Peru
	ELSE IF @pais = 16
	BEGIN --Panama
		SELECT @resultado = CASE WHEN (@lenPhone = 7) THEN CASE WHEN substring(@resultado, 1, 1) IN (''2'', ''3'', ''4'', ''5'', ''7'', ''9'') THEN @resultado ELSE ''E_'' + @resultado END WHEN (@lenPhone = 8) THEN CASE WHEN substring(@resultado, 1, 1) = ''6'' THEN @resultado ELSE ''E_'' + @resultado END ELSE CASE WHEN substring(@resultado, 1, 2) = ''00'' THEN @resultado ELSE ''E_'' + @resultado END END

		RETURN @resultado
	END

	-- Termina
	RETURN @resultado
END
'
		EXEC (@Sql)

		SET @process = 'CW-2642 ALTER FN Verifica2 '
		SET @Sql = 'ALTER FUNCTION [dbo].[Verifica2] (@tel VARCHAR(32), @pais TINYINT = 0, @cldLocal VARCHAR(7) = '''')
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @ld VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT

	IF (@pais = 0 AND @cldLocal = '''')
	BEGIN
		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104

		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17
	END

	SELECT @tel = dbo.limpia(@tel)

	IF @pais = 1
	BEGIN --Empieza Mexico
		SELECT @lon = len(@tel), @mod = ''''

		IF @lon < 10
		BEGIN
			RETURN ''E_'' + @tel
		END

		SELECT @tel = right(@tel, 10)

		SELECT @lon = len(@tel)

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 3)
					)
				SELECT @ld = left(@tel, 3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 2)
					)
				SELECT @ld = left(@tel, 2)
			ELSE
				RETURN ''E_'' + @tel

			SELECT TOP 1 @mod = modalidad
			FROM series NOLOCK
			WHERE cld = @ld AND serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
			BEGIN
				RETURN ''E_'' + @tel
			END

			DECLARE @specialDialPlan TINYINT

			SELECT @specialDialPlan = valor
			FROM ccsettings WITH (NOLOCK)
			WHERE setting_id = 195

			IF @specialDialPlan = 2
			BEGIN --Number 10 digits
				RETURN @tel
			END

			SET @isLocal = 0

			IF EXISTS (
					SELECT *
					FROM ccRiaArecode
					WHERE area = @ld
					)
			BEGIN
				SET @isLocal = 1
			END
			ELSE IF @cldLocal = @ld
			BEGIN
				SET @isLocal = 1
			END

			IF @specialDialPlan = 1
			BEGIN
				--Number local 10 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN @tel ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
								CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
			END
			ELSE
			BEGIN
				--Number local 7 o 8 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
								CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
			END
		END
		ELSE IF @lon > 0
		BEGIN
			SET @tel = ''E_'' + @tel
		END

		RETURN @tel
	END --Termina Mexico
			--------------------------- Empieza Argentina ---------------------------
	ELSE IF @pais = 2
	BEGIN
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			RETURN @tel
		END

		SELECT @lon = len(@tel)

		IF @lon IN (6, 7, 8) AND left(@tel, 2) <> ''15''
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		IF @lon IN (8, 9, 10) AND left(@tel, 2) = ''15''
		BEGIN
			SET @tel = @cldLocal + substring(@tel, 3, @lon - 2)
		END

		--Buscamos el 15
		IF @lon = 13
		BEGIN
			DECLARE @index AS INT

			SELECT @index = charindex(''15'', @tel)

			--El unico caso en el que la lada tiene un 15 es con lada 3715
			IF @index < 2
			BEGIN
				SELECT @tel = ''E_'' + @tel

				RETURN @tel
			END
			ELSE
			BEGIN
				IF substring(@tel, @index - 2, 4) = ''3715''
				BEGIN
					SELECT @ld = ''3715''

					SET @tel = @ld + right(@tel, 6)
				END
				ELSE
				BEGIN
					SELECT @ld = substring(@tel, 2, @index - 2)

					SET @tel = @ld + right(@tel, 13 - (@index + 1))
				END
			END
		END

		SELECT @tel = right(@tel, 10)

		IF len(@tel) = 10
		BEGIN
			DECLARE @serie AS VARCHAR(5)

			BEGIN
				-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				DECLARE @contLD AS INT
				DECLARE @cont AS INT

				SET @contLD = 4

				BuscaLada:

				IF isnull(@ld, '''') = '''' AND @contLD >= 2
				BEGIN
					SELECT @ld = cld
					FROM seriesArg
					WHERE cld = left(@tel, @contLD)

					IF isnull(@ld, '''') = ''''
					BEGIN
						SET @contLD = @contLD - 1

						GOTO BuscaLada
					END
				END
				ELSE
				BEGIN
					IF isnull(@ld, '''') = ''''
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END
			END

			-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
			BEGIN
				IF len(@ld) = 2
				BEGIN
					SET @cont = 5

					buscaSerie2:

					IF isnull(@serie, '''') = '''' AND @cont >= 4
					BEGIN
						SELECT @serie = serie
						FROM seriesArg
						WHERE cld = @ld AND serie = substring(@tel, 3, @cont)

						IF isnull(@serie, '''') = ''''
						BEGIN
							SET @cont = @cont - 1

							GOTO buscaSerie2
						END
					END
				END
				ELSE
				BEGIN
					IF len(@ld) = 3
					BEGIN
						SET @cont = 4

						buscaSerie3:

						IF isnull(@serie, '''') = '''' AND @cont >= 3
						BEGIN
							SELECT @serie = serie
							FROM seriesArg
							WHERE cld = @ld AND serie = substring(@tel, 4, @cont)

							IF isnull(@serie, '''') = ''''
							BEGIN
								SET @cont = @cont - 1

								GOTO buscaSerie3
							END
						END
					END
					ELSE
					BEGIN
						IF len(@ld) = 4
						BEGIN
							SET @cont = 3

							buscaSerie4:

							IF isnull(@serie, '''') = '''' AND @cont >= 2
							BEGIN
								SELECT @serie = serie
								FROM seriesArg
								WHERE cld = @ld AND serie = substring(@tel, 5, @cont)

								IF isnull(@serie, '''') = ''''
								BEGIN
									SET @cont = @cont - 1

									GOTO buscaSerie4
								END
							END
						END
					END
				END
			END

			SELECT @mod = modalidad
			FROM seriesArg
			WHERE cld = @ld AND serie = @serie AND right(@tel, 10 - len(@ld) - len(@serie)) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie			
			IF isNull(@serie, '''') = '''' AND @contLD > 1
			BEGIN
				SET @contLD = len(@ld) - 1
				SET @ld = NULL

				GOTO BuscaLada
			END

			SELECT @tel = CASE WHEN @mod IN (''BASICA'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''0'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''15'' + right(@tel, 10 - len(@ld)) ELSE ''0'' + @ld + ''15'' + right(@tel, 10 - len(@ld)) END ELSE ''E_'' + @tel END
		END
		ELSE
		BEGIN
			IF len(@tel) > 0
			BEGIN
				SELECT @tel = ''E_'' + @tel
			END
		END

		RETURN @tel
	END ------------------ Termina Argentina ------------------
	ELSE IF @pais = 3
	BEGIN --Empieza Colombia
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			RETURN @tel
		END

		IF len(@tel) NOT IN (7, 8, 10, 11)
		BEGIN
			RETURN ''E_'' + @tel
		END

		IF len(@tel) = 7
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = left(@tel, 4) AND @cldLocal = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 8
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 2, 4) AND left(@tel, 1) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 10
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 5, 3) AND (left(@tel, 3) + ''-'' + substring(@tel, 4, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 11
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 6, 3) AND (substring(@tel, 2, 3) + ''-'' + substring(@tel, 5, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END
	END --Termina Colombia

	-- Empieza Chile
	IF @pais = 5
	BEGIN
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			RETURN @tel
		END

		IF len(@tel) = 6 AND len(@cldLocal) = 2
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesChi
					WHERE cld = @cldLocal AND left(@tel, 3) = serie AND right(@tel, 3) BETWEEN numeracioninicial AND numeracionFinal
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF len(@tel) = 7
		BEGIN
			IF @cldLocal IN (2, 41, 44, 32)
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE serie = left(@tel, 4)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					IF left(@tel, 3) = ''200'' AND EXISTS (
							SELECT serie
							FROM serieschi
							WHERE serie = left(@tel, 3)
							)
					BEGIN
						RETURN @tel
					END
				END
			END
		END

		IF len(@tel) = 8
		BEGIN
			IF left(@tel, 1) = ''2''
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE serie = substring(@tel, 2, 4)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM serieschi
							WHERE serie = substring(@tel, 2, 5)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END
			ELSE
			BEGIN
				RETURN @tel
			END
		END

		IF len(@tel) = 10
		BEGIN
			IF left(@tel, 2) = ''09''
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE cld = substring(@tel, 3, 1) AND serie = substring(@tel, 5, 3)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN ''E_'' + @tel
				END
			END
		END
	END

	--Termina Chile
	IF @pais = 6
	BEGIN --Empieza Venezuela
		SELECT @lon = len(@tel)

		IF @lon = 7
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		SELECT @tel = right(@tel, 10)

		IF len(@tel) = 10
		BEGIN
			SELECT @ld = left(@tel, 3)

			SELECT @mod = tipo
			FROM seriesVen
			WHERE left(@tel, 3) = LD

			IF @mod = ''CPP''
			BEGIN
				IF EXISTS (
						SELECT *
						FROM seriesVen
						WHERE LD = @ld
						)
				BEGIN
					IF @ld = @cldLocal
					BEGIN
						SELECT @tel = right(@tel, 7)
					END
					ELSE
					BEGIN
						SELECT @tel = ''0'' + @tel
					END
				END
				ELSE
				BEGIN
					SELECT @tel = ''E_'' + @tel
				END
			END
			ELSE
			BEGIN
				IF @mod = ''FIJO''
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesVen
							WHERE serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [Inicio] AND [Fin]
							)
					BEGIN
						IF @ld = @cldLocal
						BEGIN
							SELECT @tel = right(@tel, 7)
						END
						ELSE
						BEGIN
							SELECT @tel = ''0'' + @tel
						END
					END
					ELSE
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END
				ELSE
				BEGIN
					SELECT @tel = ''E_'' + @tel
				END
			END
		END
		ELSE
		BEGIN
			IF len(@tel) > 0
			BEGIN
				SELECT @tel = ''E_'' + @tel
			END
		END

		RETURN @tel
	END --Termina Venezuela

	IF @pais = 7
	BEGIN -- Empieza UK
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN -- regresa error por longitud
			RETURN @tel
		END

		SELECT @lon = len(@tel)

		--numeros no geograficos
		IF (left(@tel, 2) IN (''03'', ''07'', ''09'') AND @lon <> 11) OR (left(@tel, 3) IN (''055'', ''056'', ''070'') AND @lon <> 11)
		BEGIN
			RETURN ''E_'' + @tel --error por longitud con lada correcta
		END
		ELSE
		BEGIN
			IF left(@tel, 7) IN (''0845464'') OR left(@tel, 5) = ''07624'' OR left(@tel, 4) IN (''0500'', ''0800'') OR left(@tel, 3) IN (''055'', ''056'', ''070'', ''76'') OR left(@tel, 2) IN (''03'', ''07'', ''08'', ''09'')
			BEGIN
				RETURN @tel;--longitud correcta y numero no geografico
			END
		END

		--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
		IF (left(@tel, 7) IN (''0159575'', ''0159576'')) OR (left(@tel, 5) IN (''02820'', ''02821'', ''02825'', ''02827'', ''02828'', ''02829'', ''02830'', ''02837'', ''02838'', ''02840'', ''02841'', ''02842'', ''02843'', ''02844'', ''02866'', ''02867'', ''02868'', ''02870'', ''02871'', ''02877'', ''02879'', ''02880'', ''02881'', ''02882'', ''02885'', ''02886'', ''02887'', ''02889'', ''02890'', ''02891'', ''02892'', ''02893'', ''02894'', ''02895'', ''02897'') AND @lon = 11) OR --claves 2xxx tienen formato 4-6
			(left(@tel, 4) IN (''0113'', ''0114'', ''0115'', ''0116'', ''0117'', ''0118'', ''0121'', ''0131'', ''0141'', ''0151'', ''0161'', ''0238'', ''0239'') AND @lon = 11) OR --3-digit area codes have 7-digit subscribers.
			(left(@tel, 3) IN (''020'', ''024'', ''029'') AND @lon = 11)
		BEGIN --2-digit area codes have 8-digit subscribers.
			RETURN @tel;
		END

		--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
		IF left(@tel, 2) = ''01''
		BEGIN
			SELECT @ld = count(cld)
			FROM seriesuk
			WHERE cld = substring(@tel, 2, 4) --mayor numero de ladas (va primero por ser mas probable)

			IF @ld > 0
			BEGIN
				RETURN @tel;
			END
			ELSE
			BEGIN
				SELECT @ld = count(cld)
				FROM seriesuk
				WHERE cld = substring(@tel, 2, 5) --ladas restantes

				IF @ld > 0
				BEGIN
					RETURN @tel;
				END
			END
		END --si no encontro ni error ni coincidencia entonces esta mal

		RETURN ''E_'' + @tel
	END --Termina UK

	IF @pais = 8
	BEGIN --Empieza Arabia Saudita
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF @lon = 7
		BEGIN
			SET @tel = ''0'' + @cldLocal + @tel
		END

		SELECT @lon = len(@tel)

		IF @lon = 9
		BEGIN
			IF EXISTS (
					SELECT regiones
					FROM seriesSA
					WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 2) = cld
					)
			BEGIN
				IF (substring(@tel, 2, 1) = @cldLocal)
				BEGIN
					RETURN right(@tel, 7)
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT regiones
					FROM seriesSA
					WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 4, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 3) = cld
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END

		IF @lon = 11
		BEGIN
			IF EXISTS (
					SELECT regiones, *
					FROM seriesSA
					WHERE right(@tel, 6) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 6 AND left(@tel, 2) = cld
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END
	END --Termina Arabia Saudita

	IF @pais = 9
	BEGIN --Empieza Australia
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF EXISTS (
					SELECT Regiones
					FROM SeriesAU
					WHERE convert(INT, LD) = convert(INT, substring(@tel, 1, 2)) AND convert(INT, AreaCode) = convert(INT, substring(@tel, 3, 2)) AND convert(INT, substring(@tel, 5, 6)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN ''E_'' + @tel
			END
		END
		ELSE
		BEGIN
			RETURN @tel
		END
	END --Termina Australia

	IF @pais = 10
	BEGIN -- Inicia Brasil
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF @lon IN (8, 9)
			BEGIN --numero local
				IF EXISTS (
						SELECT Regiones
						FROM seriesBR
						WHERE convert(INT, AreaCode) = convert(INT, @cldLocal) AND convert(INT, @tel) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN ''E_'' + @tel
				END
			END

			IF @lon IN (10, 11)
			BEGIN --numero nacional
				IF EXISTS (
						SELECT Regiones
						FROM seriesBR
						WHERE convert(INT, AreaCode) = convert(INT, left(@tel, 2)) AND convert(INT, right(@tel, @lon - 2)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN ''E_'' + @tel
				END
			END
		END
		ELSE
		BEGIN
			RETURN @tel
		END
	END -- Termina Brasil

	IF @pais = 11
	BEGIN -- Inicia Guatemala
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF EXISTS (
					SELECT zonaGeografica
					FROM seriesGT(NOLOCK)
					WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
					)
				RETURN @tel
			ELSE
				RETURN ''E_'' + @tel
		END
		ELSE
			RETURN @tel
	END -- Termina Guatemala

	IF @pais = 12
	BEGIN -- Inicia Costa Rica
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 8
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesCR(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			ELSE IF len(@tel) = 10
			BEGIN
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesCR(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 3) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			END
			ELSE IF charindex(substring(@tel, 1, 2), ''00,08'') <= 0
				RETURN ''E_'' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Costa Rica

	IF @pais = 13
	BEGIN -- Inicia Salvador
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 8
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesSV(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
				RETURN ''E_'' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Salvador

	IF @pais = 14
	BEGIN -- Inicia Spain
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 9
				IF EXISTS (
						SELECT provincia
						FROM seriesEsp(NOLOCK)
						WHERE indicativo = substring(@tel, 1, 1) AND right(@tel, 8) BETWEEN numInicial AND numFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
				RETURN ''E_'' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Espa?a

	IF @pais = 15
	BEGIN --Inicia Peru
		SELECT @tel = dbo.Completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF @lon BETWEEN 6 AND 7
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		SELECT @tel = right(@tel, 9)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF @lon = 9
			BEGIN
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesPE(NOLOCK)
						WHERE left(@tel, 1) = 9 OR substring(@tel, 2, 1) = 1 AND areaNumeracion = 1 AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal OR substring(@tel, 2, 1) <> 1 AND left(@tel, 2) = areaNumeracion AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN ''E_'' + @tel
			END
		END
	END --Termina Peru

	IF @pais = 16
	BEGIN --Panama
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> ''E''
		BEGIN
			IF len(@tel) = 7
			BEGIN -- Local
				IF (substring(@tel, 1, 1) != ''6'')
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesPa(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN ''E_'' + @tel
			END

			IF len(@tel) = 8
			BEGIN --Celular
				IF (substring(@tel, 1, 1) = ''6'')
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesPa(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN ''E_'' + @tel
			END
			ELSE
			BEGIN
				IF charindex(substring(@tel, 1, 2), ''00'') <= 0
					RETURN ''E_'' + @tel
				ELSE
					RETURN @tel
			END
		END
	END

	RETURN @tel
END
'
		EXEC (@Sql)

		SET @process = 'CW-2642 ALTER FN VerificaMex '
		SET @Sql = 'ALTER FUNCTION [dbo].[VerificaMex] (@tel VARCHAR(32))
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @ld VARCHAR(7), @cldLocal VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT

	SELECT @lon = len(@tel), @mod = ''''

	IF @lon < 10
	BEGIN
		RETURN ''E_'' + @tel
	END

	SELECT @cldLocal = valor
	FROM ccSettings WITH (NOLOCK)
	WHERE setting_id = 17

	SELECT @tel = right(@tel, 10)

	SELECT @lon = len(@tel)

	IF @lon = 10
	BEGIN
		IF EXISTS (
				SELECT TOP 1 cld
				FROM series NOLOCK
				WHERE cld = left(@tel, 2)
				)
			SELECT @ld = left(@tel, 2)
		ELSE IF EXISTS (
				SELECT TOP 1 cld
				FROM series NOLOCK
				WHERE cld = left(@tel, 3)
				)
			SELECT @ld = left(@tel, 3)
		ELSE
			RETURN ''E_'' + @tel

		SELECT TOP 1 @mod = modalidad
		FROM series NOLOCK
		WHERE cld = @ld AND serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

		IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
		BEGIN
			RETURN ''E_'' + @tel
		END

		SET @isLocal = 0

		IF EXISTS (
				SELECT *
				FROM ccRiaArecode
				WHERE area = @ld
				)
		BEGIN
			SET @isLocal = 1
		END
		ELSE IF @cldLocal = @ld
		BEGIN
			SET @isLocal = 1
		END

		SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END --Casa
				WHEN @mod = ''CPP'' THEN CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
	END
	ELSE IF @lon > 0
	BEGIN
		SET @tel = ''E_'' + @tel
	END

	RETURN @tel
END
'
		EXEC (@Sql)

		SET @process = 'CW-2642 ALTER SP ccsp_Limpia'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_Limpia] @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = ''''
AS
SET NOCOUNT ON

DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)

/***
 4  as res lista Negra
 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
 3 as res Number notExists
 1 as res Longitud invalida
 0 as res Numero correcto
 
***/
SELECT @tel = dbo.limpia(@tel)

SELECT @lon = len(@tel)

SELECT @pais = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 104

SELECT @cldLocal = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 17

SELECT @extLen = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 108

SELECT @validateTel = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 206

IF @lon > 1
BEGIN
	IF @validateTel = 1
	BEGIN --Setting 206 para no validar longitud ni listas negras
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	IF @extLen = @lon
	BEGIN -- Setting 108 validar el tamaño de longitud del telefono
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList

			RETURN (0)
		END

		SELECT 0 AS res, @tel AS tel -- Extension

		RETURN (0)
	END
END

DECLARE @telTemp AS VARCHAR(15)

SELECT @telTemp = @tel

IF @pais = 1
BEGIN ---Mexico
	IF @lon = 3 AND @tel = ''911''
	BEGIN
		SELECT 4 AS res, @tel AS tel --Lista Negra

		RETURN (0)
	END

	IF (@lon < 10)
	BEGIN
		SELECT 1 AS res, @tel AS tel --Longitud invalida

		RETURN (0)
	END

	IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
	BEGIN
		SELECT 2 AS res, @tel AS tel --Digitos incorrectos

		RETURN (0)
	END

	IF left(@tel, 3) = ''001''
	BEGIN
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	SELECT @tel = right(@tel, 10)

	IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList

		RETURN (0)
	END

	SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal)

	IF LEFT(@tel, 1) = ''E''
	BEGIN
		SELECT 3 AS res, @telTemp AS tel --No encontrado

		RETURN (0)
	END

	SELECT 0 AS res, @tel AS tel

	RETURN (0)
END
ELSE IF @pais = 2
BEGIN --Argentina 
	SET @tel = dbo.completa(@tel, @pais, @cldLocal)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.fnClearPhoneArg(@tel)

	IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos      
	END

	RETURN (0)
END
ELSE IF @pais = 3
BEGIN --Colombia  
	IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 4
BEGIN --USA 
	EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

	RETURN (0)
END
ELSE IF @pais = 5
BEGIN --Chile  
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 6
BEGIN --Venezuela    
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 7
BEGIN --Reino Unido
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 8
BEGIN --Arabia saudita   
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10, 11))
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España, 15:Peru, 16: Panama 
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp --Longitud Invalida   
	END
	ELSE IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList      
	END
	ELSE
	BEGIN
		SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
		END

		SELECT 0 AS res, @tel AS tel
	END

	RETURN (0)
END
'
		EXEC (@Sql)


		SET @process = 'CW-1698 Se modifica SP ccsp_InsertDNCList'
		SET @Sql = '
ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey int=null
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#myprincipaltemp](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE UNIQUE INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltemp]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltemp]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltemp]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltemp]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltemp]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytemp](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

declare @Sql nvarchar(max)

if @hashCalKey is not null or @hashCalKey > 0
begin
	set @Sql = ''insert into [#myprincipaltemp] '' +
	''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
	''FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on (a.cam_id = b.campsid) '' +
	''WHERE dbo.hashList(cal_Key) = '' + cast(@hashCalKey as nvarchar) +
	'' and  cal_fechadial > dateadd(dd,-30,getdate())''
end
else begin
	set @Sql = ''insert into [#myprincipaltemp] '' +
	''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
	''FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on (a.cam_id = b.campsid) '' +
	''WHERE ('''''' + @tel + '''''' IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
	''or right('''''' + @tel + '''''',10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
	''or right('''''' + @tel + '''''',11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) '' +
	''and  cal_fechadial > dateadd(dd,-30,getdate())''
end

EXEC(@Sql)

if (select count(*) from #myprincipaltemp with(nolock)) > 0
	begin
		/******************/
		/*** Telefono 1 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono = @tel or cal_telefono = right(@tel, 10) or cal_telefono = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono = wt.cal_telefono
			and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
								 + cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
												+ cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono1 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 2 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono2 = @tel or cal_telefono2 = right(@tel, 10) or cal_telefono2 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono2 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono2 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 3 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono3 = @tel or cal_telefono3 = right(@tel, 10) or cal_telefono3 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono  
			and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
								  + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono3 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono3 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 4 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono4 = @tel or cal_telefono4 = right(@tel, 10) or cal_telefono4 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono4= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono4= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono4 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono4 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 5 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono5 = @tel or cal_telefono5 = right(@tel, 10) or cal_telefono5 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono5= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono5 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono5 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
		end
	end

drop table [#myprincipaltemp]
drop table [#mytemp]
drop table [#mycamps]		
'
		EXEC (@Sql)


		-- *********************** END  121.03-3_20190227 *********************** ---

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
