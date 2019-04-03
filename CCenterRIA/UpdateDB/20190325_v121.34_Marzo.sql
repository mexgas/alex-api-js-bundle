/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez
		Karen Rodr?uez
		Erick Mu?z
		Daniel Vega
		Armando Rodriguez
		
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
			@cal_id INT
			AS
				DECLARE @disconnectCause AS VARCHAR(250)
				--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS EST?ACTIVO
				DECLARE @callout_id AS INT
				IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
				BEGIN
					--VALIDA QUE EL CALLOUT_ID EXISTA EN CCOLOGDIALS
					SELECT @callout_id=callout_id FROM ccoCallsOut WHERE cal_id = @cal_id
					IF @callout_id IS NOT NULL
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

		set @process = 'CW-2762 agrega etiqueta default'
		set @Sql= 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccGalateaCustomErrorMessages'')
			BEGIN
			IF NOT EXISTS (SELECT * FROM ccGalateaCustomErrorMessages WHERE message_id = ''DEFAULT'')
				BEGIN
					INSERT INTO ccGalateaCustomErrorMessages
					(message_id, message_description)
					VALUES (''DEFAULT'',''This is the default custom message'')
				END
			END'
		EXEC(@Sql)		
		
		set @process = 'Cambios lenguaje'
		set @Sql= 'update ccRIALog_Module set descripcion=''RECORDING SERVER|RECORDING SERVER'' where module_id=59
					update ccRIALog_Module set descripcion=''RECORDINGS MANAGER|RECORDINGS MANAGER'' where module_id=57
					update ccRIALog_Operation set descripcion=''ADJUNTAR EN EMAIL|EMAIL FILE''where operationType=172'
		EXEC(@Sql)
		
		set @process = 'correcion de identificacion del tipo de llamada'
				set @Sql= 'ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
		@callout_id int,
		@cam_id smallint,
		@tipoResDial_id tinyint,
		@Telefono varchar(30),
		@Puerto smallint,
		@tDialing tinyint=0,
		@tBusy smallint=0,
		@call_id int = 0,
		@answerbit bit = null,
		@tAnswerBit smallint = 0,
		@canceledNoAgents bit =0,
		@disconnectCause varchar(250) = '''',
		@cal_key varchar(20) = '''',
		@call_TS varchar(15) = ''''
		AS
		set nocount on
		declare @tNow as datetime, @RecicleSIC tinyint
		declare @logDial_id int, @preview smallint
		declare @tAnswerBitFinal as datetime
		
		SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
		select @tNow=getdate()
		
		select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)
		
		if @call_id > 0 and @tipoResDial_id = 1
		BEGIN
			INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id)
			select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(@Telefono)
		END
		ELSE
		BEGIN
			INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id)
			select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(@Telefono)
		END
		
		select @logDial_id=scope_identity()
		
		if (@RecicleSIC=1) begin
			UPDATE ccoWorkingTable with(rowlock) SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
		end
		
		select @logDial_id
		
		-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
		if @call_id > 0 and @tipoResDial_id = 1
		begin
			select @preview = case when progdial=2 then 1 else 0 end from cccamps nolock where cam_id=@cam_id
			if @preview = 1
			begin
				update ccoCallsOut with(rowlock) set cal_puerto = @Puerto where cal_id = @call_id and cal_puerto = 0
			end
			else
			begin
				update ccoCallsOut with(rowlock) set cal_manual = 2, cal_puerto = @Puerto where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
			end
			exec ccsp_CstoCalculaCosto @call_id
		
			if @cal_key ='''' begin
				select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
				update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
			end
		
		end
		
		-- inserta informacion para reportes de workgroup
		insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
		select IDWG, @logDial_id, IdCampEsp, getdate() 
		from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id
		
		-- Guarda configuracion de TipoDialingMode
		update ccoLogDials with(rowlock) set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
		set nocount off'
		EXEC(@Sql)
		
		set @process = 'correcion de identificacion del tipo de llamada'
				set @Sql= 'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
		 @action as tinyint,
		 @cal_id as integer,
		 @tipo as tinyint,
		 @modo as tinyint,
		 @destino as varchar(50),
		 @tantes integer = 0,
		 @tdespues integer = 0,
		 @pbxId tinyint =0,
		 @channel int =0
		 as
		 -- tipo: 1 inbound, 2 outbound
		 -- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde
		 
		 declare @totalCall_Time integer
		 declare @callout_id int
		 
		 if @action = 1 begin
		     if @modo = 4 begin
		         insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
		         values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate(), @pbxId,@channel, dbo.fnGetTipoLlamada(@destino) )
		         if @tdespues > 0 begin
		                 select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
		                 update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
		         end
		     end
		     else begin
		         if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
		             insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
		             values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() ,@pbxId,@channel, dbo.fnGetTipoLlamada(@destino) )
		 
		         if @tipo = 2 begin
		             if @modo = 5 begin
		                 select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		                 update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
		             end
		         
		             if @modo in (0,1,2) begin
		                 select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
		                 update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		             end
		         end
		 
		         else begin
		             if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
		                 select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		                 select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
		                 update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		             end
		         end
		     end
		    --Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
		   if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
		     declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
		     set @tMinAVRS=5
		     set @cal_manual=0
		     select @tMinAVRS=valor from ccSettings where setting_id=65
		     if @tipo=2 begin
		       select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
		     end
		     else begin
		       select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
		     end
		 
		     if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
		       insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
		     end
		   end
		 end
		 
		 else if @action = 2 begin   
		     if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
		         select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		         update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
		         select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
		         update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
		     end
		 end
		 
		 else if @action = 4 begin
		     select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
		     update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		end
		'
		EXEC(@Sql)
		
		set @process = 'correcion de identificacion del tipo de llamada'
				set @Sql= 'ALTER function [dbo].[fnGetTipoLlamada](@tel varchar(32))
		RETURNS tinyint
		AS
		BEGIN
		
		declare @ladatemp smallint, @ldlocal smallint, @serie smallint, @numeracion smallint, @lenght tinyint
		declare @mod varchar(10), @country tinyint
		
		select @country = valor from ccsettings where setting_id = 104
		select @lenght = LEN(@tel), @ldlocal = valor from ccSettings with(nolock) where setting_id = 17
		--print '' longitud: '' + convert(varchar(2),@lenght) + '' lada: '' + convert(varchar(3),@ldlocal)
		
			declare @table table(
			id int not null,
			prefijo nvarchar(100) not null
			)
		
			declare @t_tipos table(
			tipollamada_id int not null,
			prefijo nvarchar(100) not null,
			rowid int not null
			)
		
		declare @tipoLlamada_id smallint, @prefijo varchar(15), @tipo tinyint, @cantidadLL tinyint
		set @tipoLlamada_id = 0
		--set @tipo = 0
		
			insert into @t_tipos
			select tipoLlamada_id, prefijo, ROW_NUMBER() over(order by len(prefijo) desc) as rowid from (select tipoLlamada_id, longitud, prefijo, (select count(*) from fn_RIASplitDelimited(longitud,''|'') where value=@lenght) as exist
			from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
			where country_id = @country
			and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) ) as a where exist = 1
		
			select @cantidadLL =count(*) from @t_tipos 
			--print ''cantidad de regs'' + convert(varchar(2),@cantidadLL)
		
			if @cantidadLL <> 0 begin
				--print ''existen opciones''
				declare @i int = 1;
		
				while @i <= @cantidadLL
				begin
					select @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo from @t_tipos where rowid = @i
					--print ''tipo llamada:'' + convert(varchar(2),@tipoLlamada_id) + '' prefijo:'' + @prefijo
		
					insert into @table
					select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc
		
					if (select count(*)	from @table	where @tel like prefijo) = 1
					begin
						set @tipo = @tipoLlamada_id
						set @i = @cantidadLL
					end
		
					set @i = @i + 1
				end
			end
			else begin
				--print ''revisar contra longitud 0''
		
				select @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo from (select tipoLlamada_id, longitud, prefijo, (select count(*) from fn_RIASplitDelimited(prefijo,''|'') where @tel like (value)) as exist
				from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
				where country_id = @country and longitud = ''0''
				and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) ) as a where exist = 1
		
				if @tipoLlamada_id <> 0 begin
					set @tipo = @tipoLlamada_id
				end
				else begin
					--print ''revisar contra series''
		
					if @lenght = 10 - LEN(@ldlocal) begin
						select @tel = convert(varchar(3),@ldlocal) + @tel
					end
		
					select @tel = RIGHT(@tel,10)
					select @ladatemp = left(@tel,2)
		
					if(@ladatemp in (55,56,33,81)) begin
						--print ''es de dos digitos''
						select @serie = convert(smallint,SUBSTRING(@tel,3,4)), @numeracion = RIGHT(@tel,4)
						--print ''serie: '' + convert(varchar(4),@serie) + '' numeracion: '' + convert(varchar(4),@numeracion)
						select @mod = MODALIDAD from Series where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
					end
					else begin
						--print ''es de tres digitos''
						select @ladatemp = left(@tel,3)
						select @serie = convert(smallint,SUBSTRING(@tel,4,3)), @numeracion = RIGHT(@tel,4)
						--print ''serie: '' + convert(varchar(4),@serie) + '' numeracion: '' + convert(varchar(4),@numeracion)
						select @mod =MODALIDAD from Series where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
					end
		
					if @mod in (''FIJO'', ''MPP'') begin
						if @ldlocal = @ladatemp begin
							--print ''misma lada -> es local''
							set @tipo = 1
						end
						else begin
							--print ''diferente lada -> es ld''
							set @tipo = 2
						end
					end
		
					if @mod in (''CPP'') begin
						if @ldlocal = @ladatemp begin
							--print ''misma lada -> es celular local''
							set @tipo = 3
						end
						else begin
							--print ''diferente lada -> es celular ld''
							set @tipo = 4
						end
					end
				end
			end
		
			return @tipo
		END'
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
