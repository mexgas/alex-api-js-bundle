/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez
		Karen Rodr?uez
		Erick Mu?z
		Daniel Vega
		
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

		SET @process = 'CW-2762 Create Table ccGalateaCustomErrorMessages'
		SET @Sql = '
			IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccGalateaCustomErrorMessages'')
			BEGIN
			CREATE TABLE ccGalateaCustomErrorMessages(
				message_id varchar(50) NOT NULL PRIMARY KEY,
				message_description varchar(50) NOT NULL,
			)
			END'
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

		SET @process = 'CW-2758 Menus ccspGalateaMenusHandler'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccspGalateaMenusHandler'')
	    begin
	        DROP PROCEDURE ccspGalateaMenusHandler;
	    end'
		EXEC (@Sql)

		SET @process = 'CW-2758 Menus ccspGalateaMenusHandler'
		SET @Sql = 'CREATE PROCEDURE ccspGalateaMenusHandler
		@action tinyint,
		@userID int
		AS BEGIN
			IF @action = 1  -- Get GalateaMenus of an Admin
			BEGIN
				
				DECLARE @EnableCallMonitorMenus bit,
						@EnablePositionMenus bit

				SELECT @EnableCallMonitorMenus = valor FROM ccSettings WHERE setting_id = 68 
				SELECT @EnablePositionMenus = valor  FROM ccSettings WHERE setting_id = 71

				exec ccsp_RIAMenuRoles @Type=6,@User_id=@userID,@Role_id=0,@InsertMenu_id=0,@DeleteMenu_id=0,@reportRol=4,@CM=@EnableCallMonitorMenus,@AE=@EnablePositionMenus

				RETURN(0)
			END
		END'
		EXEC (@Sql)

		SET @process = 'CW-2775 ALTER SP ccsp_AgentGetEspecialidadesActivas'
		SET @Sql = '
		ALTER PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
		@userID INT,
		@current integer = 0
		as
		declare @fecha datetime
		declare @dia smallint
		declare @hora smallint
		declare @minuto smallint
		declare @value int

			SET DATEFIRST 1

			select @fecha =  getdate()
			select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)

			set @value = 0
			select @value = valor from ccSettings where setting_id = 191

			if @value = 0
				begin
				select -8  as inbound_id, ''Survey'' as name
					union
					select -1 as inbound_id, ''IVR'' as name
					union
					select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
					(
						select inbound_id from ccInboundHorarios where horario_id in
						(
							select horario_id  from ccHorarios
							where
							( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
							AND (
								Lunes  = @dia or
								Martes *2 = @dia or
								Miercoles*3 = @dia or
								Jueves*4 = @dia or
								Viernes*5 = @dia or
								Sabado*6 = @dia or
								domingo*7 = @dia
							)
						)
					)
					and inbound_id <> @current
					-- las activas
					and status <> 0
					-- las que tienen agentes firmados
					-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
					order by 1
				end

			if @value = 1
				begin
					if (@current <> 0)
						begin
							select -1 as inbound_id, ''IVR'' as name
							union
							select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
							(
								select inbound_id from ccInboundHorarios where horario_id in
								(
									select horario_id  from ccHorarios
									where
									( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
									AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
									AND (
										Lunes  = @dia or
										Martes *2 = @dia or
										Miercoles*3 = @dia or
										Jueves*4 = @dia or
										Viernes*5 = @dia or
										Sabado*6 = @dia or
										domingo*7 = @dia
									)
								)
							)
							and inbound_id <> @current
							-- las activas
							and status <> 0
							and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
							order by 2
						end
					else
						begin
							select -1 as inbound_id, ''IVR'' as name
							union
							select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
							(
								select inbound_id from ccInboundHorarios where horario_id in
								(
									select horario_id  from ccHorarios
									where
									( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
									AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
									AND (
										Lunes  = @dia or
										Martes *2 = @dia or
										Miercoles*3 = @dia or
										Jueves*4 = @dia or
										Viernes*5 = @dia or
										Sabado*6 = @dia or
										domingo*7 = @dia
									)
								)
							)
							and inbound_id <> @current
							-- las activas
							and status <> 0
							and IDArea in (
							select IDArea from ccUsers where User_id = @userID
							)
							-- las que tienen agentes firmados
							-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
							order by 2
						end
				end'
		EXEC (@Sql)

		SET @process = 'CW-2762 Set Setting for ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
			IF NOT EXISTS(SELECT * FROM ccsettings WHERE setting_id=212)
			INSERT ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
			VALUES (212,0,''Mensajes de error personalizados para llamada manual'',1,''ADM'',''0:Desactivado,1:Habilitar'',''Custom messages for manual call errors. 0:Disabled,1:Enabled'',1,''^[0-1]$'')'
		EXEC (@Sql)

		SET @process = 'CW-2762 agrega operation module ccRIALog_Module'
		SET @Sql = '
			IF NOT EXISTS
			(
			    SELECT *
			    FROM ccRIALog_Module
			    WHERE module_id = 60
			)
			   INSERT INTO ccRIALog_Module
				(module_id, 
				 descripcion
				)
				VALUES
				(60, 
				 ''RE-ENCRYPTER OF RECORDINGS| REENCRIPTADOR DE GRABACIONES''
				);
			'
		EXEC (@Sql)

		SET @process = 'CW-2762 agrega operation en ccRIALog_Operation'
		SET @Sql = '
			IF NOT EXISTS
			(
			    SELECT *
			    FROM ccRIALog_Operation
			    WHERE operationType = 177
			)
			    INSERT INTO ccRIALog_Operation
			    (operationType, 
			     descripcion
			    )
			    VALUES
			    (177, 
			     ''Re-Encrypt|Reencryptar''
			    );

			'
		EXEC (@Sql)

		SET @process = 'CW-2762 agrega operation module ccRIALog_Module'
		SET @Sql = '
			IF NOT EXISTS
			(
			    SELECT *
			    FROM ccRIALog_Module
			    WHERE module_id = 60
			)
			    INSERT INTO ccRIALog_Module
			    (module_id, 
			     descripcion
			    )
			    VALUES
			    (60, 
			     ''RE-ENCRYPTER OF RECORDINGS| REENCRIPTADOR DE GRABACIONES''
			    );
			'
		EXEC (@Sql)

		SET @process = 'CW-2762 Drop SP ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
			IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaGetCustomErrorMessages'')
		    BEGIN
		        DROP PROCEDURE ccsp_GalateaGetCustomErrorMessages;
		    END'
		EXEC (@Sql)

		SET @process = 'CW-2762 Create ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
			CREATE PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
			@callout_id int 
			AS
				DECLARE @disconnectCause AS VARCHAR(250)
				--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS EST?ACTIVO
				IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
				BEGIN
					--VALIDA QUE EL CALLOUT_ID EXISTA EN CCOLOGDIALS
					IF EXISTS (SELECT * FROM ccoLogDials WHERE callout_id = @callout_id) 
					BEGIN
						--SE OBTIENE EL TIPO DE USUARIO YA REGISTRADO
						SELECT @disconnectCause=disconnectCause
						FROM ccoLogDials
						WHERE callout_id = @callout_id

						WHILE PATINDEX(''%[^0-9]%'',@disconnectCause) <> 0
						BEGIN
						    --ELIMINA LAS LETRAS PARA DEJAR SOLO N?EROS
						    SET @disconnectCause = STUFF(@disconnectCause,PATINDEX(''%[^0-9]%'',@disconnectCause),1,'''')
						END

						--VALIDA QUE EXISTA UN MENSAJE DE ERROR PARA EL C?IGO
						IF EXISTS (SELECT message_description FROM ccGalateaCustomErrorMessages WHERE message_id = @disconnectCause)
						BEGIN
							--REGRESA MENSAJE ASOCIADO AL C?IGO DE ERROR
							SELECT message_description
							FROM ccGalateaCustomErrorMessages
							WHERE message_id = @disconnectCause
						END
						ELSE
						BEGIN
							--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA UNO ASOCIADO AL C?IGO DE ERROR
							SELECT message_description
							FROM ccGalateaCustomErrorMessages
							WHERE message_id = ''DEFAULT''
						END
					END
					ELSE
					BEGIN
						--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA EN CCOLOGDIALS EL CALLOUT_ID
						SELECT message_description
						FROM ccGalateaCustomErrorMessages
						WHERE message_id = ''DEFAULT''
					END
				END
				ELSE
				BEGIN
					--REGRESA UN MENSAJE PREDETERMINADO PARA INFORMAR QUE EL SETTING EST? DESHABILITADO
					SELECT ''SETTING_DISABLED'' ''message_description''
				END'
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
