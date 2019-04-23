/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.34

Se agrega la tarea
CW-SETTNGS

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
SET @versionfix = 35

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 34
BEGIN
	BEGIN TRAN
	BEGIN TRY
		
			
		SET @process = 'CW-2805 Drop SP ccsp_GalateaAdminSettings'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSettings'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSettings;
    end'
		EXEC (@Sql)


		SET @process = 'CW-2805 Galatea Settings'
		SET @Sql = '	CREATE PROCEDURE ccsp_GalateaAdminSettings
AS
BEGIN
	CREATE TABLE #Settings (setting_id tinyint , valor varchar(300), ip_host tinyint)

	INSERT INTO #Settings 
	EXEC  ccsp_RIAADMLoadSettings @ip_admin =''''

	INSERT INTO #Settings (setting_id,valor) 
	SELECT setting_id, valor 
	FROM ccSettings
	WHERE setting_id in(160, 199, 53)
 
	SELECT distinct setting_id, valor from #Settings ORDER BY setting_id 

	DROP TABLE #Settings;
END
'
		EXEC (@Sql)
				

		-- *********************** END  121.03-3_201900307 *********************** ---
		

		-- *********************** START 121.03-5_20190417 *********************** ---

		SET @process = 'CW-2737 Drop Table xxClienteCarga'
		SET @Sql = 'if exists (SELECT * FROM sys.tables WHERE name = N''xxClienteCarga'')
		begin
		DROP TABLE xxClienteCarga;
		end'
		EXEC (@Sql)

		SET @process = 'CW-2737 Create Table xxClienteCarga'
		SET @Sql = '	CREATE TABLE xxClienteCarga (
			[cuenta] [varchar](20) NOT NULL,
			[tel1] [varchar](13) NOT NULL,
			[tel2] [varchar](13) NOT NULL,
			[tel3] [varchar](13) NOT NULL,
			[tel4] [varchar](13) NOT NULL,
			[tel5] [varchar](13) NOT NULL,
			[dato1] [varchar](255) NOT NULL,
			[dato2] [varchar](255) NOT NULL,
			[dato3] [varchar](255) NOT NULL,
			[dato4] [varchar](255) NOT NULL,
			[dato5] [varchar](255) NOT NULL,
			[callout_id] [int] NULL,
			[cam_id] [int] NULL,
			[FCallBack] [smalldatetime] NULL,
			[User_id] [int] NOT NULL,
		 CONSTRAINT [PK_clienteCarga] PRIMARY KEY CLUSTERED 
		(
			[cuenta] ASC
		))

		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel1]  DEFAULT ('''') FOR [tel1]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel2]  DEFAULT ('''') FOR [tel2]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel3]  DEFAULT ('''') FOR [tel3]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel4]  DEFAULT ('''') FOR [tel4]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel5]  DEFAULT ('''') FOR [tel5]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato1]  DEFAULT ('''') FOR [dato1]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato2]  DEFAULT ('''') FOR [dato2]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato3]  DEFAULT ('''') FOR [dato3]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato4]  DEFAULT ('''') FOR [dato4]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato5]  DEFAULT ('''') FOR [dato5]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_User_id] DEFAULT ((0)) FOR [User_id]
		'
		EXEC (@Sql)


						
		SET @process = 'CW-2737 Drop Procedure xx_ChecaHorario'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_ChecaHorario'')
		begin
		DROP PROCEDURE xx_ChecaHorario;
		end'
		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_ChecaHorario'
				SET @Sql = '	CREATE PROCEDURE xx_ChecaHorario
		as
		declare @hora integer

		set  @hora = datepart( hh, getdate())

		if @hora > 6 or @hora < 22
			select 1 as ok	-- valido (dentro de horario de operaciones)
		else
			select 0 as ok -- invalido (fuera de horario de operaciones)
		'
		EXEC (@Sql)



		SET @process = 'CW-2737 Drop Procedure xx_Inserta'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_Inserta'')
		begin
		DROP PROCEDURE xx_Inserta;
		end'
		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_Inserta'
				SET @Sql = '	CREATE PROCEDURE xx_Inserta 
		@cal_key varchar(20),
		@cal_telefono varchar(19),
		@cal_telefono2 varchar(19),
		@cal_telefono3 varchar(19),
		@cal_telefono4 varchar(19),
		@cal_telefono5 varchar(19),
		@dato1 varchar(255),
		@dato2 varchar(255),
		@dato3 varchar(255),
		@dato4 varchar(255),
		@dato5 varchar(255),
		@cam_id integer,
		@FCallBack smalldatetime = '''',
		@cal_status tinyint=0,
		@User_id integer=0
		as
		declare @calloutid int
		if (@cal_status=0) set @FCallBack=getdate()
		Insert into ccoCallsOutSource ( cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id)
		values ( @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5, @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id)
		select @calloutid=scope_identity()
		Insert into xxClienteHistorial ( callout_id , fechaAct ) values ( @calloutid, getdate() )
		select @calloutid
		'
		EXEC (@Sql)



		SET @process = 'CW-2737 Drop Procedure xx_OUTInsertNewJOBS_WT_Camp'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_OUTInsertNewJOBS_WT_Camp'')
		begin
		DROP PROCEDURE xx_OUTInsertNewJOBS_WT_Camp;
		end'
		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_OUTInsertNewJOBS_WT_Camp'
				SET @Sql = '	CREATE PROCEDURE xx_OUTInsertNewJOBS_WT_Camp
		@camp_id as int
		AS
		set nocount on
		declare @prioridad varchar(8)

		Insert ccoWorkingTable ( callout_id, user_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano,
		 iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5  )
		SELECT callout_id, user_id, cam_id, 
		rtrim(left(ltrim(cal_telefono + ''         ''
				 + cal_telefono2 + ''         ''
				 + cal_telefono3 + ''         ''
				 + cal_telefono4 + ''         ''
				 + cal_telefono5 + ''         ''),13)) as cal_telefono,
		case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
		case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
		case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
		case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
		case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
		case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end
		FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_11), nolock)
		WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

		--la prioridad establecidad (si existe) 
		select @prioridad = NULL
		select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

		UPDATE ccoCallsOutSource with(rowlock) SET cal_status = 3, dial_tels = isNull( @prioridad, ''12345NNN''), nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
		where cal_status in (0, 1, 7) and cam_id = @camp_id
		'
		EXEC (@Sql)



		SET @process = 'CW-2737 Drop Procedure xx_Redirecciona'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_Redirecciona'')
		begin
		DROP PROCEDURE xx_Redirecciona;
		end'
		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_Redirecciona'
				SET @Sql = '	CREATE PROCEDURE xx_Redirecciona
		@calkey as varchar(50),
		@camOrigen as integer,
		@camDestino as integer
		as
			update ccoCallsOutSource set cam_id = @camDestino where cam_id = @camOrigen and cal_key = @calkey and len(@calkey) > 0
			update ccoWorkingtable  set cam_id = @camDestino where cam_id = @camOrigen and cal_keyw = @calkey and len(@calkey) > 0
			if( @@ROWCOUNT = 0 )
			begin
				-- No esta cargada, vuelve a cargar
				update ccoCallsOutSource set cal_status =0 where cam_id = @camDestino and cal_key = @calkey and len(@calkey) > 0
			end
		'
		EXEC (@Sql)		
		
		SET @process = 'CW-2804 Correction to ccsp_GalateaAdminSettings'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] 
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

			SELECT  @LoginOK = LoginOK, @PswdOK = PswdOK,  @Nombre = Nombre, @ADMServer=ADMServer,@AreaId=AreaId,
				@ViewAvrs = ViewAvrs, @changeRecDisposition=changeRecDisposition, @PasswordExpired =LastPasswordchange	 FROM #temp
			
			IF @LoginOK = 1 
			BEGIN 
				SELECT @User_id =  User_id FROM ccUsers where Login = @Login
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
		

		-- *********************** END 	121.03-5_20190417 *********************** ---
		
	
		
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
