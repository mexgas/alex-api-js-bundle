/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 29
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

	SET @process = 'KR063003-Setting 207-No permitir editar contraseña con contraseña previamente asignada al usuario'
	SET @sql = 'if not exists (select * from sys.tables where name = N''ccPasswordHistory'')
			begin

				CREATE TABLE [dbo].[ccPasswordHistory](
					[(User_id] smallint NOT NULL,
					[Password] varchar(33) NOT NULL,
					[PasswdDate] datetime NOT NULL
				)
			end';
	EXEC(@sql);

	SET @process = 'KR063003-Setting 207-No permitir editar contraseña con contraseña previamente asignada al usuario'
	SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_UserPasswds'' and object_id = OBJECT_ID(N''ccPasswordHistory''))
    begin
        CREATE INDEX IX_UserPasswds ON ccPasswordHistory(User_id)
    end';
	EXEC(@sql);

	-------------------------------------------- Ivan Martin (Gerardo Zumaya) K002082-DescargaConv_WA --------------------
	SET @process = 'K002082-DescargaConv_WA Drop procedure ccspGalatea_Finder'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccspGalatea_Finder'')
				BEGIN
					DROP PROCEDURE ccspGalatea_Finder;
				END';
	EXEC(@sql);

	SET @process = 'K002082-DescargaConv_WA Se actualiza el @action 3'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccspGalatea_Finder] 
				@action INT, 
				@userId INT = 0, 
				@conversationId BIGINT = 0,
				@isSuperUser bit=0
				AS
				IF @action = 1
				    BEGIN--trae el nombre de la base de datos en BX
				    if @isSuperUser =0 begin

				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
				                                        AND WGCam.Tipo = 1
				            WHERE Wguser.User_id = @userId
				            UNION
				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
				                                            AND WGCam.Tipo = 0
				            WHERE Wguser.User_id = @userId;
				        end
				        else begin
				        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
				        UNION
				        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
				        end
				        RETURN 0;
				END;
				IF @action = 2
				    BEGIN
				    if @isSuperUser =0 begin
				        WITH WgId
				            AS (SELECT IDWG
				                FROM ccRIAWorkGroupUsers Wguser
				                WHERE Wguser.User_id = @userId)
				            SELECT DISTINCT 
				                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
				                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
				                                        AND TipoUser_id = 1;
				end
				else begin
				        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				        from ccUsers where TipoUser_id = 1;
				end
				        RETURN 0;
				END;
				IF @action = 3
				         BEGIN--Informacion de la conversacion de whatsApp
				               SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversations A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.inboundId, graph.graphic_id, A.phoneACD, A.clientId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;';
	EXEC(@sql);

		set @process = 'DEV2-154_FAOM_Block_Agent_Setting207 alter table ccusers'
		set @sql = 'if not exists (select * from sys.columns where name = N''isBlocked'' and Object_ID = Object_ID(N''ccusers''))
		begin
			alter table ccusers add isBlocked tinyint null
		end'
		EXEC(@sql)


		set @process = 'DEV2-154_FAOM_Block_Agent_Setting207 drop ccsp_GalateaUpdatePassword'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdatePassword'')
		begin
			DROP PROCEDURE ccsp_GalateaUpdatePassword;
		end'
		EXEC(@sql)

		set @process = 'DEV2-154_FAOM_Block_Agent_Setting207 create ccsp_GalateaUpdatePassword '
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdatePassword]
		@UserId smallint,
		@Login varchar(40),
		@Password varchar(33)
		as
	
		-- validaciones	
			if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
				begin
					select -5 as ResponseCode--el usuario no existe
					return(0)
				end

			if  @Password <> '''' 
				begin 
					declare @date datetime = GETDATE()
					declare @setting207 int = (select valor from ccSettings where setting_id=207)

					if (@setting207 = 1 and exists(select Password from ccPasswordHistory where Password=@Password and User_id=@UserId))
					 begin
						select -7 as ResponseCode -- La contraseña ya existe
					 end
					else
					 begin
						Update ccUsers set Password=@Password, LastPasswordChange = @date, isBlocked=0, LoginAttempts=0 where User_id=@UserId	and Login=@Login
				
						if @setting207 = 1
						 begin
							insert into ccPasswordHistory(User_id, Password, PasswdDate)
							values (@UserId, @Password, @date)
						 end

						select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
					 end
				end
			else
				begin 
					select -6 as ResponseCode -- la nueva contraseña es vacia
				end'
		EXEC(@sql)


	-------------------------------------------- JCL KR063006 --------------------
	SET @process = 'KR063006-Admin-Alerta de bloqueo de contraseña-Backend'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_ParametersPassSecure'')
				BEGIN
					DROP PROCEDURE ccsp_ParametersPassSecure;
				END';
	EXEC(@sql);

	SET @process = 'KR063006-Admin-Alerta de bloqueo de contraseña-Backend'
	SET @sql = 'CREATE PROCEDURE ccsp_ParametersPassSecure
	@login varchar(40),
	@passsecure bit
	AS
	BEGIN

	declare @RemainingDays int
	declare @setting207 int

	select @setting207 = valor from ccSettings where setting_id = 207

		if @passsecure=1 or @setting207 =1
		begin
			set @passsecure=1
			select @RemainingDays = DATEDIFF(d, getdate(), DATEADD(dd, 30, LastPasswordChange)) from ccUsers nolock where login = @login
			--se retorna 8 en LongPass de acuerdo a reglas del setting 207
			select @passsecure passSecure, case when @RemainingDays < 0 then 0 else @RemainingDays end RemainingDays, 8 LongPass
		end
		else
		begin
			declare @setting29 int = (select valor from ccSettings where setting_id = 29)
			declare @setting30 int = (select valor from ccSettings where setting_id = 30)
			if @setting29 != 0
			begin
				set @passsecure = 1
				select @RemainingDays = DATEDIFF(d, getdate(), DATEADD(dd, @setting29, LastPasswordChange)) from ccUsers nolock where login = @login

				select @passsecure passSecure, case when @RemainingDays < 0 then 0 else @RemainingDays end RemainingDays, @setting30 LongPass
			end
			else
			begin
				select @passsecure passSecure, 0 RemainingDays, @setting30 LongPass
			end
		end

	END';
	EXEC(@sql);		
	----------------------------------------------------------------------------------------------------------------------

	set @process = 'DEV2-153_intentos_fallidos_conexion drop ccsp_GalateaAdminLogin'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminLogin'')
		begin
			DROP PROCEDURE ccsp_GalateaAdminLogin;
		end'
		EXEC(@sql)

	set @process = 'DEV2-153_intentos_fallidos_conexion create ccsp_GalateaAdminLogin '
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(40) = '''', 
                                               @Password    VARCHAR(40) = '''', 
                                               @PasswordLwC VARCHAR(40) = NULL, 
                                               @IPAddress   VARCHAR(20) = '''', 
                                               @adminId     INT         = 0
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @LoginOK BIT= 0, @PswdOK BIT= 0, @User_id SMALLINT, @Nombre VARCHAR(100), @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, @PasswordExpired INT= 0, @UsernameMatch BIT= 1, @UserBlocked BIT= 0, @LastPasswordChange DATETIME, @Ext VARCHAR(80), @ViewAgents BIT= 0, @Theme SMALLINT= 0, @UserBlockedByMaxAttempts BIT = 0;
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
             @adminId,
			 1;
        SELECT @LoginOK = LoginOK, @PswdOK = PswdOK, @Nombre = Nombre, @ADMServer = ADMServer, @AreaId = AreaId, @ViewAvrs = ViewAvrs, @changeRecDisposition = changeRecDisposition, @PasswordExpired = LastPasswordchange
        FROM #temp;

        IF @LoginOK = 1
            BEGIN
			IF (SELECT isBlocked
			FROM ccUsers
			WHERE User_id = @User_id) = 1
			BEGIN
			SET @UserBlockedByMaxAttempts = 1;
			END
			ELSE
			BEGIN

                SELECT @User_id = User_id, @ViewAgents = viewAgents, @Theme = theme
                FROM ccUsers
                WHERE Login = @Login;
                DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, @TimeBloqued INT, @TimeFromLastAttempt INT;
                SELECT @LastLoginAttempt = LastLoginAttempt, @LoginAttempts = LoginAttempts, @LastPasswordChange = LastPasswordChange
                FROM ccUsers
                WHERE User_id = @User_id;
				
				IF (SELECT valor
				FROM ccSettings
				WHERE setting_id = 207) = 1
				BEGIN
					IF (SELECT LoginAttempts
					FROM ccUsers
					WHERE User_id = @User_id) > 3
					BEGIN
						SET @UserBlockedByMaxAttempts = 1;
						UPDATE ccUsers SET isBlocked = 1 WHERE User_id = @User_id;
					END
				END
				ELSE
				BEGIN
				
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

				END
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
                IF (@UserBlocked = 0
                   AND (@UsernameMatch = 0
                        OR @PswdOK = 0)) AND @UserBlockedByMaxAttempts = 0
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
                                                    AND @ExpirationTime > 0 THEN 1 ELSE 0
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
                DECLARE @Roles VARCHAR(MAX);
                SELECT @Roles = STUFF(
                (
                    SELECT '', '' + CAST(ur.Rol_id AS VARCHAR)
                    FROM ccUsers_Roles ur
                    WHERE User_id = @User_id FOR XML PATH('''')
                ), 1, 2, '''');
        END;
		END;
		
		IF (SELECT valor
		FROM ccSettings
		WHERE setting_id = 207) = 1
		BEGIN
			IF (SELECT LoginAttempts
			FROM ccUsers
			WHERE User_id = @User_id) > 3
			BEGIN
				SET @UserBlockedByMaxAttempts = 1;
				UPDATE ccUsers SET isBlocked = 1 WHERE User_id = @User_id;
			END
		END
        SELECT @LoginOK UserExists, @UserBlocked UserBlocked, @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, CAST(@PasswordExpired AS BIT) PasswordExpired, @User_id UserID, @Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition, @Ext Ext, ISNULL(@ViewAgents, 0) ViewAgents, ISNULL(@WorkGroup, 0) WorkGroup, ISNULL(@Theme, 0) Theme, ISNULL(@Roles, 0) Roles, @UserBlockedByMaxAttempts UserBlockedByMaxAttempts;
    END;'
		EXEC(@sql)

		----------------------------------------------------------------------------------------------------------------------
		set @process = 'DEV2-171_Setting_207-Password_Agent drop ccsp_AgentChangePass'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AgentChangePass'')
		begin
			DROP PROCEDURE ccsp_AgentChangePass;
		end'
		EXEC(@sql)

		set @process = 'DEV2-171_Setting_207-Password_Agent drop ccsp_AgentChangePass'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentChangePass]
		@User_id smallint,		--ID del agente 
		@NewPass varchar(33)   --Nuevo Password
		as
		set nocount on
			declare @date datetime = GETDATE()
			declare @setting207 int = (select valor from ccSettings where setting_id=207)

		-- Cambia el password del agente especificado
		if (@setting207 = 1 and exists(select Password from ccPasswordHistory where Password=@NewPass and User_id=@User_id))
					begin
						select -1 as ResponseCode -- La contraseña ya existe
					end
					else
					begin
						UPDATE ccUsers SET Password = @NewPass, LastPasswordChange = @date WHERE User_Id = @User_id
						
						if @setting207 = 1
						begin
							insert into ccPasswordHistory(User_id, Password, PasswdDate)
							values (@User_id, @NewPass, @date)
						end

						select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
					end
			--UPDATE ccUsers SET Password = @NewPass, LastPasswordChange = @date WHERE User_Id = @User_id
		return(0)
		set nocount off'
		EXEC(@sql)
		
		----------------------------------------------------------------------------------------------------------------------

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
