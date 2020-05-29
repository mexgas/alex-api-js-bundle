/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.37

Se agrega la tarea
cw-2915
cw-3001
CW-3201
CW-3032
CW-3045
CW-3199

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
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 37
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'cw-Mantener drop ccsp_GalateaLoadCamps filtro de agentes conectados'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadCamps'')
    begin
        DROP PROCEDURE ccsp_GalateaLoadCamps;
    end'

		exec (@sql)

		SET @process = 'CW-3225 Obtener campañas ccsp_GalateaLoadCamps'
		SET @Sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaLoadCamps] @option    SMALLINT, 
                                              @Sup       SMALLINT = NULL, 
                                              @TypeCamp  SMALLINT = NULL, 
                                              @CamId     SMALLINT = NULL, 
                                              @PinUpdate SMALLINT = NULL
AS
     SET NOCOUNT ON;
     DECLARE @AreaId SMALLINT;
     SELECT @AreaId = IDArea
     FROM ccUsers
     WHERE User_id = @Sup;
     IF @option = 1 -- Get Camps
         BEGIN
             IF @TypeCamp = 1 -- Campañas salida por Supervisor
                 SELECT DISTINCT 
                        rel.cam_id, 
                        camps.cam_descripcion, 
                        graph.graphic_id AS Frame,
                        CASE
                            WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                            THEN 1
                            ELSE 0
                        END AS Pin
                 FROM ccSupervisorCam rel
                      LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                    AND rel.cam_id = pin.Cam_Id
                      LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                      LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                 WHERE rel.user_id = @Sup
                       AND rel.tipo = 1
                 ORDER BY camps.cam_descripcion ASC;
             IF @TypeCamp = 2 -- Campañas entrada por Supervisor (ACDs)
                 BEGIN
                     SELECT CAST(inbound.Inbound_id AS INT) AS Cam_id, 
                            inbound.descripcion AS Cam_descripcion, 
                            graph.graphic_id AS Frame, 
                            0
                     FROM ccInbound inbound
                          LEFT JOIN ccRIAinboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
                          LEFT JOIN ccSupervisorCam supCam ON inbound.Inbound_id = supCam.cam_id
                     WHERE supCam.user_id = @Sup
                           AND tipo = 0
                     ORDER BY inbound.descripcion ASC;
             END;
     END;
     IF @option = 2 -- update Pin campaing
         BEGIN
             IF @PinUpdate = 1
                 BEGIN
                     INSERT INTO PinCampaings
                     (Cam_Id, 
                      Sup_Id
                     )
                     VALUES
                     (@CamId, 
                      @Sup
                     );
             END;
                 ELSE
                 IF @PinUpdate = 0
                     BEGIN
                         DELETE FROM PinCampaings
                         WHERE Cam_Id = @CamId
                               AND Sup_Id = @Sup;
                 END;
     END;
 '

	exec (@sql)
		

		SET @process = 'cw-Mantener Alter SP ccsp_GalateaAdminLogin filtro de agentes conectados'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] 
	@Login varchar(20) = '''',
	@Password varchar(40) = '''',
	@PasswordLwC varchar(40) = null,
	@IPAddress varchar(20) = '''',
	@adminId int = 0
AS
begin
SET NOCOUNT ON

	DECLARE @LoginOK bit, 
			@PswdOK bit ,
			@User_id smallint, 
			@Nombre varchar(100), 
			@ADMServer varchar(300), 
			@AreaId smallint, 
			@ViewAvrs int, 
			@changeRecDisposition int, 
			@PasswordExpired int ,
			@UsernameMatch bit ,
			@UserBlocked bit ,
			@LastPasswordChange datetime,
			@Ext varchar(80),
			@ViewAgents bit  ;

			select @LoginOK =0, 
			@PswdOK = 0,			
			@PasswordExpired = 0,
			@UsernameMatch  = 1,
			@UserBlocked = 0,
			@ViewAgents  =0

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
		SELECT @User_id =  User_id, @ViewAgents = viewAgents FROM ccUsers where Login = @Login
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
			UPDATE ccUsers SET LoginAttempts = 0, LastLoginAttempt = GETDATE() , onLine = 1 WHERE User_id = @User_id 
		END
		
		SELECT @Ext = dbo.fn_Ext_X_ip (@IPAddress);
	END


	SELECT @LoginOK UserExists, @UserBlocked UserBlocked , @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, CAST(@PasswordExpired AS BIT) PasswordExpired, @User_id UserID,
	@Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition, @Ext Ext, @ViewAgents ViewAgents
END


'
		EXEC (@Sql)

		
		set @process = 'cw-3085 No mostrar calificaciones en Agente Kolob'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetHangUpData'')
    begin
        DROP PROCEDURE ccsp_GalateaGetHangUpData;
    end'

		exec (@sql)
		
		set @process = 'cw-3085 No mostrar calificaciones en Agente Kolob'
		SET @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetHangUpData]
	@cam_id int,
	@type int
AS BEGIN
	IF(@type = 1)
	BEGIN
		SELECT   0 leaveRecMessage,
				CASE WHEN isnull(c.callsBySurvey,0) > 0 THEN 1 ELSE 0 END isRelationSurvey,
				isnull(i.callBackSurveyAgent,1) callBackSurveyAgent,
				isnull(i.callBackSurveyClient,1) callBackSurveyClient,
				I.ShowCalifWnd showDisposition
       FROM ccInbound i
       LEFT JOIN ccCamps c on c.cam_id=i.cam_id
       WHERE i.inbound_id=@cam_id

	END
	ELSE
	BEGIN 
		SELECT
			   CASE WHEN msgFile <> '''' and leaveRecMessage = 1 THEN 1 ELSE 0 END leaveRecMessage,
			   CASE WHEN isnull(c.surveyCamId,0) >0 THEN 1 ELSE 0 END isRelationSurvey,
			   c.callBackSurveyAgent,c.callBackSurveyClient, c.cam_ShowCalifWnd showDisposition
		FROM ccCamps c
		LEFT OUTER JOIN (SELECT TOP 1 M.cam_id, coalesce(T.msgFile+'','','''')  msgFile
						 FROM ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
						 WHERE M.cam_id =@cam_id and type = 8) b
		on (c.cam_id = b.cam_id)
		where c.cam_id=@cam_id
	END
END
'
		EXEC (@Sql)


		set @process = 'Devops Alter FUNCTION VerificaRegionLocalidad'
		SET @Sql = 'ALTER FUNCTION [dbo].[VerificaRegionLocalidad](@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
RETURNS @retVRL TABLE
(
    tel varchar(32) PRIMARY KEY NOT NULL,
    region varchar(32) NULL,
    localidad varchar(32) NULL
)
 BEGIN
 declare @ld varchar(7)
 declare @lon tinyint 
 declare @lonLd tinyint 
 declare @region varchar(20)
 declare @localidad varchar(20) 
 declare @serie varchar(4)
 
 select @region='''',@localidad=''''

 if (@pais = 0 and @cldLocal = '''') begin
	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end

 select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
	select @lon = len(@tel)
	if @lon in(7,8) begin
		set @tel = @cldLocal + @tel
		set @ld=@cldLocal
	end	
	
	select @tel = right(@tel, 10)
	select @lon = len(@tel)	
  if @lon = 10 begin		
	
		if @ld is null begin
			if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))begin
				select @ld = left(@tel,2)			
			end
			else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))  begin
				select @ld = left(@tel,3)			
			end
		end

		if @ld is not null begin
			set @lonLd=len(@ld)		
			set @serie=substring(@tel,len(@ld)+1,case @lonLd when 2 then 4 else 3 end)		
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@ld and SERIE=@serie
		end
		else begin
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@cldLocal
		end

	end
   else  begin
		if (@region is null) begin
			select top 1 @region = estado from series nolock where cld=@cldLocal
		end		
	end
end --Termina Mexico

  INSERT @retVRL
        SELECT @tel as phone, @region as estado, @localidad as municipio
  RETURN

end'
		EXEC (@Sql)
		
		
		set @process = 'cw-2542 enmascaramiento xfer asistida'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_DLRgetDialMask'')
			begin
				DROP PROCEDURE ccsp_DLRgetDialMask;
			end'
		EXEC (@Sql)
			
		set @process = 'cw-2542 enmascaramiento xfer asistida'
		set @sql = 'create procedure ccsp_DLRgetDialMask
@cam_id int,
@phone varchar(50)
as
declare @checkLd_In_ANILst smallint
declare @ani varchar(50), @pais varchar(3)

set @checkLd_In_ANILst=0

SELECT @pais = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 104

SELECT @checkLd_In_ANILst = valor 
FROM ccsettings WITH (NOLOCK) 
WHERE setting_id = 213

IF @pais = 1
BEGIN ---Mexico
	If (@cam_id > 0 AND @checkLd_In_ANILst = 1)
	BEGIN
		select @ani = ltrim(rtrim(ani)) FROM ccCamps nolock WHERE cam_id = @cam_id
		If datalength(@ani) > 0
		BEGIN
			SELECT @ani	ani
			RETURN (0)
		END

		IF len(@phone) < 10 select @phone = dbo.Completa(@phone, @pais, '''')

		IF len(@phone) < 10 or isnumeric(@phone) <= 0 select '''' ani

		select @phone = right(@phone, 10)

		SELECT TOP 1 @ani=ltrim(rtrim(telAni)) FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @cam_id and telAni <> '''''''' and area = left(@phone, 3)
		If datalength(@ani) > 0
		BEGIN
			SELECT @ani ani
			RETURN (0)
		END
		SELECT TOP 1 @ani=ltrim(rtrim(telAni)) FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @cam_id and telAni <> '''''''' and area = left(@phone, 2)
		If datalength(@ani) > 0
		BEGIN
			SELECT @ani ani
			RETURN (0)
		END
	END
	select '''' ani
END
			'

		exec (@sql)



		------------------------------------------------- 121.03-8_20190715_1 -------------------------------------

				set @process = 'CW-2708 -- Add New Setting ccSettings 216'
		set @sql = 'IF NOT EXISTS
(
	SELECT *
	FROM ccSettings
	WHERE setting_id = 216
)
BEGIN
	INSERT INTO ccSettings( setting_id, valor, descripcion, STATUS, Tipo, detalle, description, bLoadSettings, validate )
	VALUES( 216, ''3|24|smtp.ionos.com|notifications@centernext.net|6zJLvMd2|587|0|0'', ''Notificar vencimiento de licencia vía correo electrónico '', 1,
	''X'', ''Numero dias envio del correo #DaysBefore|#HourSendMail|STMPServer|User|Password|Port|SSL|TLS'',
	''Notify license expiration via email L'', 0,
	''^(\d+)\|(\d+)\|(\w+\.?)+\|[_a-z0-9-]+(.[_a-z0-9-]+)*@[a-z0-9-]+(.[a-z0-9-]+)*(.[a-z]{2,4})\|.*\|\d+\|[0-1]$'' );
END;'
		exec (@sql)

		set @process = 'CW-2708 -- Create table ccRiaCat_AccountMailNotifyExpirationLicense'
		set @sql = 'if not exists(select * from sys.tables where name=''ccRiaCat_AccountMailNotifyExpirationLicense'') begin
create table ccRiaCat_AccountMailNotifyExpirationLicense(
Mail varchar(255) Not NUll,
Name varchar(255) Not null default('''')
)
end'
		exec (@sql)



				set @process = 'CW-3225 -- Create table PinCampaings'
		set @sql = 'if not exists(select * from sys.tables where name=''PinCampaings'') begin
CREATE TABLE [dbo].[PinCampaings](
	[Cam_Id] [int] NULL,
	[Sup_Id] [int] NULL
) 

end'
		exec (@sql)


		set @process = 'CW-2708 -- Create Index ccRiaCat_AccountMailNotifyExpirationLicense.IX_ccRiaCat_AccountMailNotifyExpirationLicense_I'
		set @sql = 'IF NOT EXISTS (SELECT name from sys.indexes  
           WHERE name = N''IX_ccRiaCat_AccountMailNotifyExpirationLicense_I'')   begin   
   CREATE UNIQUE INDEX IX_ccRiaCat_AccountMailNotifyExpirationLicense_I ON ccRiaCat_AccountMailNotifyExpirationLicense (mail);   
end'
		exec (@sql)

		set @process = 'CW-2708 -- Add Mail Send Notify license expiration'
		set @sql = 'if not exists(select * from ccRiaCat_AccountMailNotifyExpirationLicense where Mail=''instalaciones@nuxiba.com'')
insert into ccRiaCat_AccountMailNotifyExpirationLicense (Mail) values(''instalaciones@nuxiba.com'')
'
		exec (@sql)

		

		

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
