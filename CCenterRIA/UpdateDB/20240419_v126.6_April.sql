/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 6
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
    	

	----------------------------------------------------- BEGIN SMS Masivo Muñoz KR134000  ----------------------------------------------------------------

	----------------------------------------------------- BEGIN KR134001-Módulo de segmentos  ----------------------------------------------------------------


	SET @process = 'KR134001 CREATE TABLE SmsRemesasMuñoz';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''SmsRemesasMuñoz'') BEGIN
	    CREATE TABLE [dbo].[SmsRemesasMuñoz](
		[id_credito] [bigint] NOT NULL,
		[fecha_actualizacion] [datetime] NULL,
		[id_Cartera] [bigint] NULL,
		[credito] [nvarchar](40) NOT NULL,
		[COMPRAS_DISPMONEDA] [decimal](9, 0) NULL,
		[DIA_CORTE] [nvarchar](255) NULL,
		[DIA_CORTE_NUM] [int] NULL,
		[DIAACTUAL] [varchar](15) NULL,
		[DIAMASCINCO] [varchar](15) NULL,
		[DIAMASCUATRO] [varchar](15) NULL,
		[DIAMASDOS] [varchar](15) NULL,
		[DIAMASTRES] [varchar](15) NULL,
		[DIAMASUNO] [varchar](15) NULL,
		[ETIQUETA_BASE_RECOM] [varchar](100) NULL,
		[FECHACORTE] [varchar](255) NULL,
		[IMPORTE_1ERPAGO_MULTIPAYMENT] [real] NULL,
		[IMPORTE_2DOPAGO_MULTIPAYMENT] [real] NULL,
		[IMPORTE_3ERPAGO_MULTIPAYMENT] [real] NULL,
		[IMPORTE_ENDOSPAGOS] [real] NULL,
		[IMPORTE_PAGO_ONESHOT] [real] NULL,
		[IMPORTE_PAGO_ONESHOT_2] [real] NULL,
		[IMPORTE_PAGOBON_ONESHOT] [real] NULL,
		[INTERES_IVA_COMISION] [real] NULL,
		[MESES_VENCIDOS] [int] NULL,
		[MINIMOPAGARPESOS] [real] NULL,
		[NoSMS] [varchar](25) NULL,
		[PQC_MULTIPAYMENT_SIMULACION] [varchar](25) NULL,
		[PQC_ONESHOT_SIMULACION] [varchar](25) NULL,
		[PRODUCTO_GENERAL] [varchar](25) NULL,
		[Quita_capital_3Pagos] [real] NULL,
		[Quita_capital_ONESHOT] [real] NULL,
		[RCV7DESCPRODUCTO] [varchar](30) NULL,
		[RCV7MV0_MONEDA] [varchar](50) NULL,
		[RCV7MV1_FILTRO] [real] NULL,
		[RCV7MV1_MONEDA] [varchar](50) NULL,
		[RCV7MV2_FILTRO] [real] NULL,
		[RCV7MV2_MONEDA] [varchar](50) NULL,
		[RCV7MV3_MONEDA] [varchar](50) NULL,
		[SALDO_ACTUALMONEDA] [decimal](18, 0) NULL,
		[SALDO_CAPITAL] [decimal](9, 0) NULL,
		[SALDO_DEUDOR] [decimal](9, 0) NULL,
		[SALDO_VENCIDOMONEDA] [decimal](18, 0) NULL,
		[SEG_CUENTA] [varchar](15) NULL,
		[SegmentoMC] [varchar](8) NULL,
		[SumaMultiPayment] [float] NULL,
		[TDCT] [varchar](255) NOT NULL,
		[TELEFONOS1] [nvarchar](50) NULL,
		[TERMINACION] [varchar](4) NULL,
		[CAMPAÑABENJAMIN] [varchar](150) NULL,
		[TIPO_TELEFONO] [varchar](20) NULL,
		[N_EMAIL] [varchar](150) NULL,
		[TEL_POSICION] [varchar](10) NULL,
		[SALDO_DEUDOR_FILTRO] [decimal](18, 0) NULL,
		[NUM_CUENTA] [varchar](20) NULL,
		[INTERES_IVA_COMISION_FILTRO] [decimal](18, 0) NULL,
		[STATUS] [varchar](100) NULL,
		[PROMESA] [varchar](10) NULL,
		[FILA] [varchar](100) NULL,
		[LOCACION] [varchar](20) NULL,
		[ESTADO_FUNCIONAL] [varchar](100) NULL,
		[CORTE_REAL] [varchar](20) NULL,
		[CORTE] [varchar](20) NULL
	)
	END';
	EXEC (@sql);

	SET @process = 'KR134001 CREATE TABLE ccSmsSegments';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsSegments'') BEGIN
	    CREATE TABLE ccSmsSegments(
	        SegmentId INT IDENTITY(1,1) PRIMARY KEY,
	        Name VARCHAR(255),
	        IsGlobal BIT DEFAULT(0),
	        CampaignId SMALLINT DEFAULT (0)
	    )
	END';
	EXEC (@sql);

	SET @process = 'KR134001 CREATE TABLE ccSmsConditions FK SegmentId';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsConditions'') BEGIN
	CREATE TABLE ccSmsConditions(
		ConditionId INT IDENTITY(1,1) PRIMARY KEY,
		SegmentId INT FOREIGN KEY REFERENCES ccSmsSegments(SegmentId),
		PrimaryField VARCHAR(255),
		LogicOperator VARCHAR(2),
		ComparisonValue VARCHAR(150), 
		ComparisonField  VARCHAR(150),
		ArithmeticOperator VARCHAR(2),
		Value VARCHAR(255),
		DailyLimit INT, 
		WeeklyLimit INT,
	)
	END';
	EXEC (@sql);

	SET @process = 'KR134001 CREATE TABLE ccSmsSubconditions FK ConditionId';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsSubconditions'') BEGIN
	CREATE TABLE ccSmsSubconditions(
		SubconditionId INT IDENTITY(1,1) PRIMARY KEY,
		ConditionId INT FOREIGN KEY REFERENCES ccSmsConditions(ConditionId),
		PrimaryField VARCHAR(255),
		LogicOperator VARCHAR(2),
		ComparisonValue VARCHAR(150),
		ComparisonField  VARCHAR(150),
		ArithmeticOperator VARCHAR(2),
		Value VARCHAR(255),
		LogicConector VARCHAR(3)
	)
	END';
	EXEC (@sql);

	SET @process = 'KR134001 CREATE TABLE ccSmsSegmentFlagB';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsSegmentFlagB'') BEGIN
	CREATE TABLE ccSmsSegmentFlagB(
		Id SMALLINT IDENTITY(1,1) PRIMARY KEY,
		Validation VARCHAR(40) UNIQUE,
		IsActive BIT
	)
	END';
	EXEC (@sql);

	      
	----------------------------------------------------- END KR134001-Módulo de segmentos ----------------------------------------------------------------

	-------------------------------------------------------- BEGIN KR134021 AND KR134022 ------------------------------------------------------------------

	set @process = 'Alter de tabla ccuser'
	set @sql = 'IF NOT EXISTS (
	    SELECT 1
	    FROM INFORMATION_SCHEMA.COLUMNS
	    WHERE TABLE_NAME = ''ccUsers'' AND COLUMN_NAME = ''notificationEmail''
	)
	BEGIN
	    ALTER TABLE ccUsers
	    ADD notificationEmail NVARCHAR(255) DEFAULT '''' NOT NULL;
	END;'
	EXEC(@sql)

	set @process = 'Alter de sp ccsp_GalateaCreateUser'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaCreateUser]
	                    @UserId int,
	                    @Login varchar(40),
	                    @Nombres varchar(45),
	                    @LastName varchar(45),
	                    @NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
	                    @Password varchar(200),
	                    @Sexo bit,
	                    @canChangeStatus bit,
	                    @AreaId int,
	                    @UserType tinyint,
	                    @AdminId int,
						@NotificationEmail varchar(255)
	                    as

	                    Declare @ApellidoMaterno varchar(45)
	                    Declare @ApellidoPaterno varchar(45)

	                    --Obtiene el idioma de de Centerware
	                    Declare @lenguageXion varchar
	                    select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

	                    --se acondiciona los apellidos con el nombre opcional dependiendo del idioma
	                        if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
	                        begin
	                            set @ApellidoPaterno = @LastName
	                            set @ApellidoMaterno = @NombreOpcionalExtra
	                        end
	                        else-- es idioma ingles
	                        begin
	                            set @ApellidoPaterno = @NombreOpcionalExtra 
	                            set @ApellidoMaterno = @LastName
	                        end

	                    -- validaciones 
	                        if exists(select Login from ccUsers where Login=@Login)
	                        begin
	                        select -1 as ResponseCode--,''Login en Uso''
	                        return(0)
	                        end

	                        if exists(select Login from ccUsers_Consulta where Login = @Login)
	                        begin
	                        select -4 as ResponseCode -- ''Login en Uso aunque el usuario ya se halla borrado de la base de datos'' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
	                        return(0)
	                        end

	                        if exists(select Nombres from ccUsers where Nombres=@Nombres
	                        and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
	                        begin
	                        select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
	                        return(0)
	                        end


	                    --insert
	                    IF( select isnull(max(user_id),0) from ccusers) > 32700
	                    BEGIN
	                        set @UserId = null
	                        SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
	                        FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
	                        LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
	                        INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
	                        FROM ccusers) AS w ON w.recID = d.recID

	                        if @UserId is null
	                        begin
	                        select -3 as ResponseCode --Error_when_inserting_user
	                        return(0)
	                        end
							select * from ccUsers
	                        set identity_insert ccusers on
	                        insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id, Status,TipoLLamadas,Sexo,canChangeStatus,IDArea,notificationEmail)
	                        select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end, @NotificationEmail
	                        set identity_insert ccusers off

	                        delete ccMenuUser where id_User = @UserId
	                        delete ccRIAUserRole where user_id = @UserId

	                        exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

	                        --Insert Agent into ccRIAAgentsPermissions
	                        IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
	                        BEGIN
	                        IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
	                        BEGIN 
	                            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
	                            VALUES (@UserId, 0, 0, 1)
	                        END
	                        END

	                    END
	                    ELSE
	                    BEGIN
	                        insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
	                        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea,notificationEmail)
	                        select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
	                        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end, @NotificationEmail

	                        if @@rowcount=1
	                        select @UserId=scope_identity()
	                        else
	                        begin
	                        select -2--insert Error
	                        return(0)
	                        end

	                        --INSERT INTO ACTIVITY LOG, CREATE AGENT
	                        DECLARE @areaName AS VARCHAR(40);
	                        DECLARE @userLogin AS VARCHAR(40);
	                        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId);

	                        IF(@AreaId <> 0) BEGIN
	                            SET @areaName = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId);
	                        END

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
	                        VALUES (CASE WHEN @AreaID = 0 THEN NULL ELSE @areaName END, getDate(), @userLogin, CASE WHEN @UserType = 1 THEN 22 ELSE 29 END, 3, '''', '''', @Login);

	                    END
	                        insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
	                        insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
	                        insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
	                        --Menu para roles RepotsRia
	                        exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

	                        --Insert Agent into ccRIAAgentsPermissions
	                        IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
	                        BEGIN
	                        IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
	                        BEGIN 
	                            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
	                            VALUES (@UserId, 0, 0, 1)
	                        END 
	                        END
	                    select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario'
	EXEC(@sql)

	set @process = 'Alter sp ccsp_GalateaUpdateUser'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
	@UserId int,
	@Login varchar(40),
	@Nombres varchar(45),
	@LastName varchar(45),
	@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
	@Sexo bit,
	@canChangeStatus bit,
	@AdminId int,
	@AreaId int,
	@NotificationEmail varchar(255)
	as

	Declare @ApellidoMaterno varchar(45)
	Declare @ApellidoPaterno varchar(45)
	Declare @userIdOnDb int
	Declare @LoginOnDb varchar(40)
	--Obtiene el idioma de Centerware
	Declare @lenguageXion varchar
	select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

	--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
	    if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
	        begin
	            set @ApellidoPaterno = @LastName
	            set @ApellidoMaterno = @NombreOpcionalExtra
	        end
	    else-- es idioma ingles
	        begin
	            set @ApellidoPaterno = @NombreOpcionalExtra 
	            set @ApellidoMaterno = @LastName
	        end

	-- validaciones 
	    if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
	        begin
	        select -5 as ResponseCode--,''el usuario no existe''
	        return(0)
	        end

	  if exists(select Nombres from ccUsers where Nombres=@Nombres
	  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
	    begin

	        select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
	      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

	        select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
	      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

	      if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
	        begin
	            select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
	            return(0)
	        end
	    end

	--update and insert into activity log a record for each modified property

	    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

	    Update ccUsers set 
	    Nombres=@Nombres,
	    ApellidoPaterno=@ApellidoPaterno,
	    ApellidoMaterno=@ApellidoMaterno,
	    Sexo=@Sexo,
	    canChangeStatus=@canChangeStatus,
		notificationEmail=@NotificationEmail
	    where User_id=@UserId

	    DECLARE @CCUsersTable TABLE 
	    (
	        columnInfo VARCHAR(255),
	        dataInfo VARCHAR(255),
	        identifierInfo VARCHAR(255)
	    )

	    INSERT INTO @CCUsersTable EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId;

	    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	    SELECT 
	        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
	        getDate(), 
	        (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
	        CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
	        3, 
	        CUT.identifierInfo,
	        CASE WHEN CUT.identifierInfo IS NOT NULL THEN
	            CASE 
	                WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
	                ELSE CUT.dataInfo END
	        ELSE '''' END, 
	        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
	    FROM @CCUsersTable AS CUT;

	    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

	select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
	        '
	EXEC(@sql)

	set @process = 'Alter de sp ccsp_GalateaLoadUsersForManagement'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
	 @option SMALLINT,
	 @AreaId SMALLINT,
	 @UserType INT = null,
	 @Username VARCHAR(200)=null,
	 @userId INT = 0
	as

	--Obtiene el idioma de de Centerware
	Declare @lenguageXion varchar
	select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para espanol, 1 para ingles, 2 para portugues

	IF @option = 1 --Agentes/supervisores de un Area
	BEGIN
	  SELECT  TipoUser_id as UserType,
	  User_id as UserId,
	  LOGIN as Username,
	  Nombres as Names,
	  CASE
	    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	    ELSE isnull(ApellidoPaterno, '''')
	  END as LastName,

	  CASE
	    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	    ELSE isnull(ApellidoMaterno, '''')
	  END as OptionalExtraName,

	  Password as Password,
	  Sexo as IsMan,
	  CanChangeStatus as EnableNotReady,
	  isnull(IDArea, 0) as AreaId,
	  notificationEmail
	  FROM ccusers
	  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
		AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
	  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

	  RETURN (0)
	END

	IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
	BEGIN
	  SELECT  TipoUser_id as UserType,
	  User_id as UserId,
	  LOGIN as Username,
	  Nombres as Names,
	  CASE
	    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	    ELSE isnull(ApellidoPaterno, '''')
	  END as LastName,

	  CASE
	    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	    ELSE isnull(ApellidoMaterno, '''')
	  END as OptionalExtraName,

	  Password as Password,
	  Sexo as IsMan,
	  CanChangeStatus as EnableNotReady,
	  isnull(IDArea, 0) as AreaId,
	  notificationEmail
	  FROM ccusers
	  WHERE Login=@Username

	  RETURN (0)
	END

	IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
	BEGIN
	  SELECT  TipoUser_id as UserType,
	  User_id as UserId,
	  LOGIN as Username,
	  Nombres as Names,
	  CASE
	    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	    ELSE isnull(ApellidoPaterno, '''')
	  END as LastName,

	  CASE
	    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	    ELSE isnull(ApellidoMaterno, '''')
	  END as OptionalExtraName,

	  Password as Password,
	  Sexo as IsMan,
	  CanChangeStatus as EnableNotReady,
	  isnull(IDArea, 0) as AreaId,
	  notificationEmail
	  FROM ccusers
	  WHERE user_id=@userId

	  RETURN (0)
	END




	IF @option = 4 -- supervisores en Area/Sistema
	BEGIN
		DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
		INSERT INTO @Admins
		SELECT User_id as UserId,
		LOGIN as Username,
		Nombres as Names,
		CASE
		  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
		  ELSE isnull(ApellidoPaterno, '''')
		END as LastName,

		CASE
		  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
		  ELSE isnull(ApellidoMaterno, '''')
		END as OptionalExtraName,

		isnull(IDArea, 0) as AreaId
		FROM ccusers
		WHERE TipoUser_id = 2 AND STATUS = 1


		IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
			SELECT UserId, Username, Names, LastName, OptionalExtraName
			FROM @Admins
			WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
			ORDER BY Username, Names, LastName, UserId
		END
		ELSE BEGIN
			SELECT UserId, Username, Names, LastName, OptionalExtraName
			FROM @Admins
			ORDER BY Username, Names, LastName, UserId
		END
		Return(0)
	END

	IF @option = 5 --Usuarios inactivos por mas de 60 dias por area
		BEGIN
			SELECT [User_id] as UserId,
			LOGIN as Username
			FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
			AND @AreaId = IDArea
			RETURN 0;
		END'
	EXEC(@sql)

	set @process = 'Insert Permissions'
	set @sql = 'if not exists (select 1 from ccPermissions where Description = ''Gestionar Segmentos'' )
	begin
		Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
		FROM ccPermissions),''Gestionar Segmentos'',''RolesPermissionManageSegments'',0,0,0,''N/A'',1)
	end

	if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Gestionar Segmentos''))
	begin
		INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Gestionar Segmentos''))
	end


	if not exists (select 1 from ccPermissions where Description = ''Cargar registros SMS por segmento'' )
	begin
		Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
		FROM ccPermissions),''Cargar registros SMS por segmento'',''RolesPermissionLoadSMSSegments'',0,0,0,''N/A'',1)
	end

	if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Cargar registros SMS por segmento''))
	begin
		INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Cargar registros SMS por segmento''))
	end

	if not exists (select 1 from ccPermissions where Description = ''Validaciones SMS Masivo'' )
	begin
		Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
		FROM ccPermissions),''Validaciones SMS Masivo'',''RolesPermissionMassSMSValidation'',0,0,0,''N/A'',1)
	end

	if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Validaciones SMS Masivo''))
	begin
		INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Validaciones SMS Masivo''))
	end

	if not exists (select 1 from ccPermissions where Description = ''Plantillas SMS Masivo'' )
	begin
		Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
		FROM ccPermissions),''Plantillas SMS Masivo'',''RolesPermissionBulkSMSTemplates'',0,0,0,''N/A'',1)
	end

	if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Plantillas SMS Masivo''))
	begin
		INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Plantillas SMS Masivo''))
	end
	'
	EXEC(@sql)

	--------------------------------------------------------- END KR134021 AND KR134022 -------------------------------------------------------------------

	--------------------------------------------------------- BEGIN KR134016-Campaña SMS-Eliminar registros de día anterior -------------------------------------------------------------------
	SET @process = 'KR134016 CREATE TABLE ccSmsSegments';
	SET @sql = 'if not exists(select * from ccsettings2 where setting_id=268) begin
	    insert into ccSettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
	    values (268,''0'',''Setting para eliminar los registros SMS para MCA'',1,''GRL''
	    ,''Eliminar Registros de las remesas para que el siguiente mande mensajes correctos''
	    ,''Delete remittance records so that the next one sends correct messages'',0,''^[0-1]$'')
	end
	';
	EXEC (@sql);

	SET @process = 'KR134016 Create table ccSmsValidateRegistryWeek';
	SET @sql = 'if not exists(SELECT * FROM sys.objects WHERE name = ''ccSmsValidateRegistryWeek'') begin
	    Create table ccSmsValidateRegistryWeek(
	        registryClient varchar(60) primary key not null,
	        total int not null,
	        totaltoDay int not null,
	        loadRegistry int not null
	        )
	end';
	EXEC (@sql);

	SET @process = 'KR134016 CREATE TABLE ccSmsSegments';
	SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
	@action int,
	@camId int = null,
	@SentMsg int=null,
	@smsoutIds varchar(max)=null,
	@SystemApiId varchar(100)=null,
	@statusSystemsId int =null,
	@InsufficientBalance int=null,
	@date datetime =null,
	@addingCampaign bit = null
	as
	declare @sql varchar(max)
	if @action=1 begin
	    set @date=getdate()

	    if @addingCampaign = 1 begin
	        select distinct cast(c. cam_id as int) as CamId,
	                        cam_descripcion as [Name],
	                        cam_procesando as [Start],
	                        0 AS MessageQuantity
	        from ccCamps c
	        where CampType=7 and c.IDArea is not null and c.cam_id=@camId
	    end
	    else begin
	        SELECT DISTINCT CAST(c. cam_id AS INT) AS CamId,
	                        cam_descripcion AS Name,
	                        cam_procesando AS Start,
	                        ISNULL((w.new + w.pro),0) AS MessageQuantity
	        FROM ccCamps c
	        LEFT JOIN ccSmsSchedules s ON s.cam_id = c.cam_id
	        LEFT JOIN ccCampsNvosCB  w ON c.cam_id = w.id
	        WHERE CampType=7 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
	        AND @date BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
	    end
	end
	else if @action=2 begin
	    select tz_offset from ccTimeZones ORDER BY tz_id
	end
	else if @action=3 begin
	    select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
	    from ccSmsConversationsResult where ( @camId is null or camId=@camId)
	end
	else if @action=4 begin
	    truncate table ccSmsConversationsResult
	end
	else if @action=5 begin
	    if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
	        insert into ccSmsConversationsResult(camId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance,Exception)
			values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
	    end
	    else begin
	        update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
	        ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
	        where camId=@camId
	    end
	end
	else if @action=6 begin 
	    set @sql=''delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')''
	    exec (@sql)
	end
	else if @action=7 begin
	    DECLARE @TemporalProcessingSmsStatusUpdates TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, StatusSystemsId INT, IsCharged BIT)
	    INSERT INTO @TemporalProcessingSmsStatusUpdates
	    SELECT SystemApiId, StatusSystemsId, IsCharged FROM ProcessingSmsStatusUpdates

	    DECLARE @ChargedMessages INT = (SELECT SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END) FROM @TemporalProcessingSmsStatusUpdates)
	    IF @ChargedMessages <> 0
	    BEGIN
	        UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - @ChargedMessages WHERE setting_id = 258 AND valor > 0;
	    END

	    DECLARE @UpdatingSmsWorkingTable TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, OldStatusSystemsId INT, NewStatusSystemsId INT, CampaignId INT)
	    INSERT INTO @UpdatingSmsWorkingTable
	    SELECT S.SystemApiId, S.StatusSystemsId, T.StatusSystemsId, S.cam_id FROM smsccoLogDial S WITH(NOLOCK)
	    INNER JOIN @TemporalProcessingSmsStatusUpdates T ON S.SystemApiId = T.SystemApiId
	            
	    ;WITH CTE AS (
	    SELECT
	        CampaignId,
	        COUNT(CASE WHEN NewStatusSystemsId = 0 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 0 THEN 1 END) AS SentMsg,
	        COUNT(CASE WHEN NewStatusSystemsId = 1 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 1 THEN 1 END) AS Delivered,
	        COUNT(CASE WHEN NewStatusSystemsId = 2 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 2 THEN 1 END) AS NotDelivered,
	        COUNT(CASE WHEN NewStatusSystemsId = 3 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 3 THEN 1 END) AS RecipientRejected,
	        COUNT(CASE WHEN NewStatusSystemsId = 4 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 4 THEN 1 END) AS CarrierRejected,
	        COUNT(CASE WHEN NewStatusSystemsId = 5 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 5 THEN 1 END) AS Exception,
	        COUNT(CASE WHEN NewStatusSystemsId = 6 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 6 THEN 1 END) AS InsufficientBalance

	    FROM @UpdatingSmsWorkingTable
	    GROUP BY CampaignId
	    )

	    MERGE INTO ccSmsConversationsResult AS Target
	    USING CTE AS Source ON Target.camId = Source.CampaignId
	    WHEN MATCHED THEN
	        UPDATE SET
	            Target.SentMsg = CASE WHEN (Target.SentMsg + Source.SentMsg) < 0 THEN 0 ELSE (Target.SentMsg + Source.SentMsg) END,
	            Target.Delivered = CASE WHEN (Target.Delivered + Source.Delivered) < 0 THEN 0 ELSE (Target.Delivered + Source.Delivered) END,
	            Target.NotDelivered = CASE WHEN (Target.NotDelivered + Source.NotDelivered) < 0 THEN 0 ELSE (Target.NotDelivered + Source.NotDelivered) END,
	            Target.RecipientRejected = CASE WHEN (Target.RecipientRejected + Source.RecipientRejected) < 0 THEN 0 ELSE (Target.RecipientRejected + Source.RecipientRejected) END,
	            Target.CarrierRejected = CASE WHEN (Target.CarrierRejected + Source.CarrierRejected) < 0 THEN 0 ELSE (Target.CarrierRejected + Source.CarrierRejected) END,
	            Target.Exception = CASE WHEN (Target.Exception + Source.Exception) < 0 THEN 0 ELSE (Target.Exception + Source.Exception) END,
	            Target.InsufficientBalance = CASE WHEN (Target.InsufficientBalance + Source.InsufficientBalance) < 0 THEN 0 ELSE (Target.InsufficientBalance + Source.InsufficientBalance) END

	    WHEN NOT MATCHED BY TARGET THEN
	    INSERT (camId, SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
	    VALUES (Source.CampaignId, Source.SentMsg, Source.Delivered, Source.NotDelivered, Source.RecipientRejected, Source.CarrierRejected, Source.Exception, Source.InsufficientBalance);

	    UPDATE smsccoLogDial SET Bill = (CASE WHEN T.StatusSystemsId IN (0, 1, 2) THEN 0.7 ELSE 0 END),
	                                statusSystemsId = T.StatusSystemsId
	    FROM smsccoLogDial S WITH(NOLOCK)
	    INNER JOIN @TemporalProcessingSmsStatusUpdates T ON T.SystemApiId = S.SystemApiId

	    DELETE FROM ProcessingSmsStatusUpdates 
	    WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalProcessingSmsStatusUpdates);

	    SELECT @@ROWCOUNT;
	end
	else if @action=8 begin
	    update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
	end
	else if @action=9 begin
	    CREATE TABLE #TempSmsOutIds (
	    smsout_id INT
	    );

	    INSERT INTO #TempSmsOutIds (smsout_id)
	    SELECT DISTINCT wt.smsout_id
	    FROM smsWorkingTable wt
	    JOIN smsOutSource os WITH(NOLOCK) ON wt.smsout_id = os.smsout_id
	    LEFT JOIN smsccoLogDial cco WITH(NOLOCK) ON wt.smsout_id = cco.smsout_id
	    WHERE wt.cam_id=@camId and wt.sms_status IN(1,2) 
	    AND cco.smsout_id IS NULL;
	            

	    UPDATE wt
	    SET wt.sms_status = 0
	    FROM smsWorkingTable wt WITH(NOLOCK)
	    JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

	    DROP TABLE #TempSmsOutIds;
	end
	else if @action=10 begin
	    SELECT COUNT(*) FROM smsWorkingTable with (NOLOCK) WHERE cam_id = @camId
	end
	else if @action=12 begin
	    IF EXISTS (SELECT 1 FROM ccSmsSchedules WITH (NOLOCK) WHERE cam_id = @camId 
	    AND GETDATE() BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
	    )
	    AND EXISTS (SELECT 1 FROM smsWorkingTable WITH (NOLOCK) WHERE cam_id = @camId)
	    BEGIN
	        SELECT CAST(0 AS BIT);
	        RETURN;
	    END
	    ELSE BEGIN
	        UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
	        SELECT CAST(1 AS BIT);
	        RETURN;
	    END
	end
	else if @action=13 begin
	    set @date=convert(DATE,getdate(),121)
	    
	    delete from smsWorkingTable where @camId is null or @camId=0 or cam_id=@camId AND sms_dateDial<@date
	end';
	EXEC (@sql);
	--------------------------------------------------------- END KR134016-Campaña SMS-Eliminar registros de día anterior -------------------------------------------------------------------
	-------------------------------------------------------------BEGIN MACL----------------------------------------------------
	-----------------------------Templates-------------------------
	SET @process = 'KR134006-7 se agregan operaciones, modulos e identificadores para el historial de actividad'
	SET @sql= 'IF NOT EXISTS (select * from ccGalateaOperations where OperationId = 106)
	BEGIN
		INSERT INTO ccGalateaModules(ModuleId, MTagEs, MTagEn, MTagPt) 
		values(16,''Plantillas de SMS'', ''SMS templates'', ''Modelos de SMS'')
			
		INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (106, ''Crear plantilla'', ''Create template'', ''Criar modelo''),
		(107, ''Editar plantilla'', ''Edit template'', ''Editar modelo''),
		(108, ''Eliminar plantilla'', ''Delete template'', ''Excluir modelo'')

		INSERT INTO ccGalateaModOpRelation values(16,106),(16,107),(16,108)

		INSERT INTO ccGalateaIdentifiers([Description], TagEs, TagEn, TagPt) 
		values(''SMS_TEMPLATE_NAME'', ''Nombre'', ''Name'', ''Nome''),
		(''SMS_TEMPLATE_MESSAGE'', ''Mensaje'', ''Message'', ''Mensagem'')
	END'

	EXEC(@sql);

	SET @process = 'KR134006-7 Se crea tabla para las plantillas'
	SET @sql= 'IF NOT EXISTS (select * from sys.tables where name = N''ccSmsTemplate'')
	BEGIN
		CREATE TABLE ccSmsTemplate(
			TemplateId INT IDENTITY(1,1) PRIMARY KEY,
			[Description] VARCHAR(40),
			[Type] INT not null,
			[MessageTemplate] VARCHAR(500),
			[Status] bit
		);
	END'
	EXEC(@sql);

	SET @process = 'KR134006-7 Plnantillas SMS Salida - Se crea SP ccsp_SmsTemplate para administrar las plantillas'
	SET @sql= 'CREATE OR ALTER PROCEDURE [dbo].[ccsp_SmsTemplate]
		@Action TINYINT,
		@TemplateId INT = 0,
		@Description VARCHAR(40) = NULL,
		@TemplateType INT = 0,
		@MessageTemplate VARCHAR(500) = ''''
	AS
	BEGIN 
		DECLARE @Result int = 0;
		IF @Action = 1 --Create
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM ccSmsTemplate WHERE [Status] = 1 and [Description] = @Description)
			BEGIN
				INSERT INTO ccSmsTemplate([Description],[Type],[MessageTemplate], [Status])
				VALUES (@Description, @TemplateType, @MessageTemplate, 1)
				SET @Result = @@IDENTITY
			END
			ELSE BEGIN
				SET @Result = -1
			END
			SELECT @Result as result;
			RETURN 0;
		END

		IF @Action = 2 --Edit
		BEGIN
			Declare @message varchar(500)='''', @desc varchar(40)='''', @updateResult int
			IF NOT EXISTS(SELECT 1 FROM ccSmsTemplate WHERE [Status] = 1 and [Description] = @Description and TemplateId != @TemplateId)
			BEGIN
				SELECT @message = MessageTemplate, @desc = [Description] FROM ccSmsTemplate WHERE TemplateId = @TemplateId
				IF(@message != @MessageTemplate AND @desc != @Description)
				BEGIN
					UPDATE ccSmsTemplate SET [Description] = @Description,
					MessageTemplate = @MessageTemplate
					WHERE TemplateId = @TemplateId AND [STATUS] = 1
					SET @Result = @@ROWCOUNT
					SET @updateResult = 3
				END
				ELSE IF (@message != @MessageTemplate AND @desc = @Description)
				BEGIN
					UPDATE ccSmsTemplate SET MessageTemplate = @MessageTemplate
					WHERE TemplateId = @TemplateId AND [STATUS] = 1
					SET @Result = @@ROWCOUNT
					SET @updateResult = 2
				END
				ELSE IF (@message = @MessageTemplate AND @desc != @Description)
				BEGIN
					UPDATE ccSmsTemplate SET [Description] = @Description
					WHERE TemplateId = @TemplateId AND [STATUS] = 1
					SET @Result = @@ROWCOUNT
					SET @updateResult = 1
				END

				IF(@Result = 1)
				BEGIN
					SET @Result = @updateResult
				END
				ELSE BEGIN --Not Updated
					IF EXISTS(SELECT 1 FROM ccSmsTemplate WHERE TemplateId = @TemplateId and [Status] = 0)
					BEGIN
						SET @Result = -2 --The template not exists or is deleted
					END
				END
			END
			ELSE BEGIN -- Name Already exists with other id
				set @Result = -1
			END
			SELECT @message as OldMessage, @desc as OldDescription, @Result as Result;
			RETURN 0;
		END

		IF @Action = 3 --Delete
		BEGIN
			UPDATE ccSmsTemplate SET [Status] = 0 WHERE TemplateId = @TemplateId and Status = 1
			SET @Result = @@ROWCOUNT
			SELECT @Result as result;
			RETURN 0;
		END

		IF @Action = 4 --Get templates
		BEGIN
			IF @TemplateType = 0 AND @TemplateId = 0
			BEGIN
				SELECT TemplateId, [Description],[Type] as TemplateType,[MessageTemplate]
				FROM ccSmsTemplate
				WHERE [Status] = 1
				RETURN 0;
			END
			IF @TemplateId > 0
			BEGIN
				SELECT TemplateId, [Description],[Type] as TemplateType,[MessageTemplate]
				FROM ccSmsTemplate
				WHERE [Status] = 1 and TemplateId = @TemplateId
				RETURN 0;
			END
			SELECT TemplateId, [Description],[Type] as TemplateType,[MessageTemplate]
			FROM ccSmsTemplate WHERE [Status] = 1 and [Type] = @TemplateType;
			RETURN 0;
		END

		IF @Action = 5 --Get MC Variables
		BEGIN
			DECLARE @TableName sysname;
			DECLARE @query nvarchar(MAX) = ''''
			SET @TableName = ''SmsRemesasMuñoz''
			IF OBJECT_ID(N''tempdb..#resultsTable'', N''U'') IS NOT NULL  drop table #resultsTable
			CREATE TABLE #resultsTable (columnName varchar(100), previewValue varchar(max))

			DECLARE @whileIter int = 1
			DECLARE @whileTotal int  

			SELECT @whileTotal = COUNT(*) FROM sys.columns c
										INNER JOIN 
											sys.types t ON c.user_type_id = t.user_type_id
										WHERE
											c.object_id = OBJECT_ID(@TableName)
			WHILE @whileIter <= @whileTotal
			BEGIN

			SELECT  @query =  N''INSERT INTO #resultsTable (columnName,  previewValue) SELECT '''''' + sc.name + '''''' AS columnName, ISNULL(max(['' + sc.name + '']),0) FROM ['' + t.name + '']''  
			FROM  sys.tables AS t
			INNER JOIN sys.columns AS sc ON t.object_id = sc.object_id
			INNER JOIN sys.types AS st ON sc.system_type_id = st.system_type_id
			WHERE column_id = @whileIter
			AND t.name = @TableName
			

			exec sp_executesql @query
			SET @whileIter += 1
			END
			SELECT rt.columnName, rt.previewValue, CAST(len(rt.previewValue) AS int) maxValue,
			CASE WHEN c.DATA_TYPE in (''bigint'', ''int'', ''decimal'', ''real'', ''short'') 
			THEN  CAST(1 AS bit) ELSE  CAST(0 AS bit) END as isNumber
			FROM #resultsTable rt
			INNER JOIN INFORMATION_SCHEMA.COLUMNS c
			ON c.COLUMN_NAME = rt.columnName
			WHERE c.TABLE_NAME = @TableName

			TRUNCATE TABLE #resultsTable
			DROP TABLE #resultsTable
		END
	END'
	EXEC(@sql);

	SET @process = 'Se agrega funcion para valdar telefonos'
	SET @sql= 'CREATE OR ALTER FUNCTION [dbo].[VerificaSmsMCA] (@tel VARCHAR(32))
	RETURNS INT
	AS
	BEGIN
		DECLARE @ld VARCHAR(7)
		DECLARE @lon TINYINT
		DECLARE @result TINYINT
		DECLARE @mod VARCHAR(10)
		DECLARE @tipo VARCHAR(10)
		DECLARE @Cadena VARCHAR(32)
		DECLARE @isLocal BIT
		declare @serie varchar(10)
		DECLARE @pais TINYINT = 0;
		DECLARE @cldLocal VARCHAR(7);


		SET @pais = 1;
		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17

		SELECT @tel = dbo.limpia(@tel)

		IF @pais = 1
		BEGIN --Empieza Mexico
			SELECT @lon = len(@tel), @mod = ''''

			IF @lon < 10
			BEGIN
				RETURN 3
			END

			SELECT @tel = right(@tel, 10)

			SELECT @lon = len(@tel)

			IF @lon = 10
			BEGIN
				IF EXISTS (
						SELECT TOP 1 cld
						FROM series NOLOCK
						WHERE cld = left(@tel, 3)
						and serie=SUBSTRING(@tel,4,3)
						)
					SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
				ELSE IF EXISTS (
						SELECT TOP 1 cld
						FROM series NOLOCK
						WHERE cld = left(@tel, 2)
						and serie=SUBSTRING(@tel,3,4)
						)
					SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)
				ELSE
					RETURN 3

				SELECT TOP 1 @mod = modalidad, @tipo = [TIPO DE RED]
				FROM series NOLOCK
				WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

				IF @mod = ''FIJO''
				BEGIN
					RETURN 5
				END
				
				IF @tipo <> ''MOVIL''
				BEGIN
					RETURN 5
				END

				RETURN 0;
			END
			ELSE
			BEGIN
				RETURN 3
			END
		END
		RETURN 3;
	END'
	EXEC(@sql);

	SET @process = 'Se crea tabla SmsRemesasMuñosDay'
	SET @sql= 'IF NOT EXISTS (SELECT 1 FROM sys.tables where name = ''SmsRemesasMuñozDay'')
	BEGIN
	CREATE TABLE [dbo].[SmsRemesasMuñozDay](
		[id_credito] [bigint] NOT NULL,
		[fecha_actualizacion] [datetime] NULL,
		[id_Cartera] [bigint] NULL,
		[credito] [nvarchar](40) NOT NULL,
		[COMPRAS_DISPMONEDA] [decimal](9, 0) NULL,
		[DIA_CORTE] [nvarchar](255) NULL,
		[DIA_CORTE_NUM] [int] NULL,
		[DIAACTUAL] [varchar](15) NULL,
		[DIAMASCINCO] [varchar](15) NULL,
		[DIAMASCUATRO] [varchar](15) NULL,
		[DIAMASDOS] [varchar](15) NULL,
		[DIAMASTRES] [varchar](15) NULL,
		[DIAMASUNO] [varchar](15) NULL,
		[ETIQUETA_BASE_RECOM] [varchar](100) NULL,
		[FECHACORTE] [varchar](255) NULL,
		[IMPORTE_1ERPAGO_MULTIPAYMENT] [real] NULL,
		[IMPORTE_2DOPAGO_MULTIPAYMENT] [real] NULL,
		[IMPORTE_3ERPAGO_MULTIPAYMENT] [real] NULL,
		[IMPORTE_ENDOSPAGOS] [real] NULL,
		[IMPORTE_PAGO_ONESHOT] [real] NULL,
		[IMPORTE_PAGO_ONESHOT_2] [real] NULL,
		[IMPORTE_PAGOBON_ONESHOT] [real] NULL,
		[INTERES_IVA_COMISION] [real] NULL,
		[MESES_VENCIDOS] [int] NULL,
		[MINIMOPAGARPESOS] [real] NULL,
		[NoSMS] [varchar](25) NULL,
		[PQC_MULTIPAYMENT_SIMULACION] [varchar](25) NULL,
		[PQC_ONESHOT_SIMULACION] [varchar](25) NULL,
		[PRODUCTO_GENERAL] [varchar](25) NULL,
		[Quita_capital_3Pagos] [real] NULL,
		[Quita_capital_ONESHOT] [real] NULL,
		[RCV7DESCPRODUCTO] [varchar](50) NULL,
		[RCV7MV0_MONEDA] [varchar](50) NULL,
		[RCV7MV1_FILTRO] [real] NULL,
		[RCV7MV1_MONEDA] [varchar](50) NULL,
		[RCV7MV2_FILTRO] [real] NULL,
		[RCV7MV2_MONEDA] [varchar](50) NULL,
		[RCV7MV3_MONEDA] [varchar](50) NULL,
		[SALDO_ACTUALMONEDA] [decimal](18, 0) NULL,
		[SALDO_CAPITAL] [decimal](9, 0) NULL,
		[SALDO_DEUDOR] [decimal](9, 0) NULL,
		[SALDO_VENCIDOMONEDA] [decimal](18, 0) NULL,
		[SEG_CUENTA] [varchar](15) NULL,
		[SegmentoMC] [varchar](8) NULL,
		[SumaMultiPayment] [float] NULL,
		[TDCT] [varchar](255) NOT NULL,
		[TELEFONOS1] [nvarchar](50) NULL,
		[TERMINACION] [varchar](4) NULL,
		[CAMPAÑABENJAMIN] [varchar](150) NULL,
		[TIPO_TELEFONO] [varchar](20) NULL,
		[N_EMAIL] [varchar](150) NULL,
		[TEL_POSICION] [varchar](10) NULL,
		[SALDO_DEUDOR_FILTRO] [decimal](18, 0) NULL,
		[NUM_CUENTA] [varchar](10) NULL,
		[INTERES_IVA_COMISION_FILTRO] [decimal](18, 0) NULL,
		[STATUS] [varchar](100) NULL,
		[PROMESA] [varchar](10) NULL,
		[FILA] [varchar](100) NULL,
		[LOCACION] [varchar](20) NULL,
		[ESTADO_FUNCIONAL] [varchar](100) NULL,
		[CORTE_REAL] [varchar](20) NULL,
		[CORTE] [varchar](20) NULL,
		[RESULTADO] VARCHAR(100) NULL,
		[RESULTADO_ID] INT NULL,
		[RESULTADO_ENVIO] VARCHAR(10) NULL,

	) 

	CREATE INDEX IX_SmsRemesasMuñozDay_TDCT ON SmsRemesasMuñozDay (TDCT)
	CREATE INDEX IX_SmsRemesasMuñozDay_CREDITO ON SmsRemesasMuñozDay (CREDITO)
	CREATE INDEX IX_SmsRemesasMuñozDay_SEGMENTOMC ON SmsRemesasMuñozDay (SegmentoMC)
	CREATE INDEX IX_SmsRemesasMuñozDay_FILA ON SmsRemesasMuñozDay (SegmentoMC)
	CREATE INDEX IX_SmsRemesasMuñozDay_RESULTADO ON SmsRemesasMuñozDay (SegmentoMC)
	END'
	EXEC(@sql);

	SET @process = 'Se crea tabla SmsRemesasMuñosDayBefore'
	SET @sql= 'USE CCenterRIA
	IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''SmsRemesasMuñozDayBefore'')
	BEGIN
	    CREATE TABLE SmsRemesasMuñozDayBefore (
	        id_credito BIGINT NOT NULL,
	        fecha_actualizacion DATETIME DEFAULT NULL, 
	        id_Cartera BIGINT DEFAULT NULL,
	        credito NVARCHAR(40) NOT NULL,
	        COMPRAS_DISPMONEDA DECIMAL(9) DEFAULT NULL,
	        DIA_CORTE NVARCHAR(255) DEFAULT NULL,
	        DIA_CORTE_NUM INT DEFAULT NULL,
	        DIAACTUAL VARCHAR(15) DEFAULT NULL,
	        DIAMASCINCO VARCHAR(15) DEFAULT NULL,
	        DIAMASCUATRO VARCHAR(15) DEFAULT NULL,
	        DIAMASDOS VARCHAR(15) DEFAULT NULL,
	        DIAMASTRES VARCHAR(15) DEFAULT NULL,
	        DIAMASUNO VARCHAR(15) DEFAULT NULL,
	        ETIQUETA_BASE_RECOM VARCHAR(100) DEFAULT NULL,
	        FECHACORTE VARCHAR(255) DEFAULT NULL,
	        IMPORTE_1ERPAGO_MULTIPAYMENT FLOAT(8) DEFAULT NULL,
	        IMPORTE_2DOPAGO_MULTIPAYMENT FLOAT(8) DEFAULT NULL,
	        IMPORTE_3ERPAGO_MULTIPAYMENT FLOAT(8) DEFAULT NULL,
	        IMPORTE_ENDOSPAGOS FLOAT(8) DEFAULT NULL,
	        IMPORTE_PAGO_ONESHOT FLOAT(8) DEFAULT NULL,
	        IMPORTE_PAGO_ONESHOT_2 FLOAT(8) DEFAULT NULL,
	        IMPORTE_PAGOBON_ONESHOT FLOAT(8) DEFAULT NULL,
	        INTERES_IVA_COMISION FLOAT(8) DEFAULT NULL,
	        MESES_VENCIDOS INT DEFAULT NULL,
	        MINIMOPAGARPESOS FLOAT(8) DEFAULT NULL,
	        NoSMS VARCHAR(25) DEFAULT NULL,
	        PQC_MULTIPAYMENT_SIMULACION VARCHAR(25) DEFAULT NULL,
	        PQC_ONESHOT_SIMULACION VARCHAR(25) DEFAULT NULL,
	        PRODUCTO_GENERAL VARCHAR(25) DEFAULT NULL,
	        Quita_capital_3Pagos FLOAT(8) DEFAULT NULL,
	        Quita_capital_ONESHOT FLOAT(8) DEFAULT NULL,
	        RCV7DESCPRODUCTO VARCHAR(30) DEFAULT NULL,
	        RCV7MV0_MONEDA VARCHAR(50) DEFAULT NULL,
	        RCV7MV1_FILTRO FLOAT(8) DEFAULT NULL,
	        RCV7MV1_MONEDA VARCHAR(50) DEFAULT NULL,
	        RCV7MV2_FILTRO FLOAT(8) DEFAULT NULL,
	        RCV7MV2_MONEDA VARCHAR(50) DEFAULT NULL,
	        RCV7MV3_MONEDA VARCHAR(50) DEFAULT NULL,
	        SALDO_ACTUALMONEDA DECIMAL(18) DEFAULT NULL,
	        SALDO_CAPITAL DECIMAL(9) DEFAULT NULL,
	        SALDO_DEUDOR DECIMAL(9) DEFAULT NULL,
	        SALDO_VENCIDOMONEDA DECIMAL(18) DEFAULT NULL,
	        SEG_CUENTA VARCHAR(15) DEFAULT NULL,
	        SegmentoMC VARCHAR(8) DEFAULT NULL,
	        SumaMultiPayment FLOAT DEFAULT NULL,
	        TDCT VARCHAR(255) UNIQUE NOT NULL,
	        TELEFONOS1 NVARCHAR(50) DEFAULT NULL,
	        TERMINACION VARCHAR(4) DEFAULT NULL,
	        CAMPAÑABENJAMIN VARCHAR(150) DEFAULT NULL,
	        TIPO_TELEFONO VARCHAR(20) DEFAULT NULL,
	        N_EMAIL VARCHAR(150) DEFAULT NULL,
	        TEL_POSICION VARCHAR(10) DEFAULT NULL,
	        SALDO_DEUDOR_FILTRO DECIMAL(18) DEFAULT NULL,
	        NUM_CUENTA VARCHAR(20) DEFAULT NULL,
	        INTERES_IVA_COMISION_FILTRO DECIMAL(18) DEFAULT NULL,
	        STATUS VARCHAR(100) DEFAULT NULL,
	        PROMESA VARCHAR(10) DEFAULT NULL,
	        FILA VARCHAR(100) DEFAULT NULL,
	        LOCACION VARCHAR(20) DEFAULT NULL,
	        ESTADO_FUNCIONAL VARCHAR(100) DEFAULT NULL,
	        CORTE_REAL VARCHAR(20) DEFAULT NULL,
	        CORTE VARCHAR (20) DEFAULT NULL,
			RESULTADO VARCHAR(50) DEFAULT NULL,
			RESULTADO_ID INT NULL,
			RESULTADO_ENVIO VARCHAR(10) NULL
	    );

		CREATE INDEX IX_SmsRemesasMuñozDayBefore_TDCT ON SmsRemesasMuñozDayBefore (TDCT)
		CREATE INDEX IX_SmsRemesasMuñozDayBefore_CREDITO ON SmsRemesasMuñozDayBefore (CREDITO)
		CREATE INDEX IX_SmsRemesasMuñozDayBefore_SEGMENTOMC ON SmsRemesasMuñozDayBefore (SegmentoMC)
		CREATE INDEX IX_SmsRemesasMuñozDayBefore_FILA ON SmsRemesasMuñozDayBefore (FILA)
		CREATE INDEX IX_SmsRemesasMuñozDayBefore_RESULTADO ON SmsRemesasMuñozDayBefore (RESULTADO)
		CREATE INDEX IX_SmsRemesasMuñozDayBefore_ESTADO_FUNCIONAL ON SmsRemesasMuñozDayBefore (ESTADO_FUNCIONAL)
	END'
	EXEC(@sql);

	SET @process = 'Se agrega el callkey para guardar al momento de hacer el venvío'
	SET @sql= 'IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''smsccoLogDial'' and COLUMN_NAME = ''callkey'')
	BEGIN
		ALTER TABLE smsccoLogDial ADD callkey varchar(40)
	END'
	EXEC(@sql);

	SET @process = 'si existe se elimina el sp ccspLoadRegistrySegments'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspLoadRegistrySegments'')
	begin
		DROP PROCEDURE ccspLoadRegistrySegments;
	end'
	EXEC(@sql)

	SET @process = 'Se crea sp ccspLoadRegistrySegments para validacion de segmentos'
	SET @sql= 'CREATE procedure [dbo].[ccspLoadRegistrySegments] 
	@action int,
	@camId int = null,
	@typeTemplate int=2, --1 Segmentos, 2 Plantillas Archivos
	@phone varchar(32)=null,
	@templateId int=null,
	@callKey varchar(60)=null,
	@userId int=0,
	@msg varchar(160)=null,
	@smsout_id int=null,
	@SystemApiId varchar(100)=null,
	@statusSystemsId int=null,
	@dateStart datetime=null,
	@dateEnd datetime=null,
	@segmentIds varchar(max)='''',
	@columns varchar(max)=''*''
	as

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	DECLARE @sql VARCHAR(max)
	declare @today date=convert(date,getdate(),121)
	declare @monday datetime


	if @action=1 begin --List Segments
		select SegmentId,Name from ccSmsSegments where IsGlobal=1 or CampaignId=@camId
	end
	else if @action=2 begin  --ListColumnsTable
	    SELECT name
		FROM sys.columns
		WHERE object_id = OBJECT_ID(''SmsRemesasMuñoz'')
		and name like ''TELEFONOS[0-9]%''
	end
	else if @action=3 begin --List Plantillas
	    select TemplateId,Description as Name,MessageTemplate from ccSmsTemplate where Type=@typeTemplate
	end
	else if @action=4 begin
	    Select iDate DateStart,fDate DateEnd from ccSmsSchedules where cam_id=@camId
	end
	else if @action=5 begin
	    select top 1 * from SmsRemesasMuñoz
	end
	else if @action=6 begin
	    SET @columns = ''''
		SELECT @columns = @columns + ''isnull(max(len('' + COLUMN_NAME + '')),0)as '' + COLUMN_NAME + '',''
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''SmsRemesasMuñoz''
		AND DATA_TYPE IN (''varchar'', ''nvarchar'', ''char'', ''nchar'');

		SET @columns = SUBSTRING(@columns, 0, len(@columns))
		SET @sql = ''select '' + @columns + '' from SmsRemesasMuñoz''

		--PRINT (@sql)
		EXEC (@sql)

	end
	else if @action=7 begin
	    declare @valueInt int, @value varchar(100)
		select @valueInt=valor from ccSettings where setting_id=104
		select @value=valor from ccSettings where setting_id=17		

		select @phone= dbo.Verifica2(@phone,@valueInt,@value,1)
		if LEFT(@phone, 1)=''E'' begin
			select -1 as Result,''is not cellPhone''
			return -1;
		end
		select @valueInt=valor from ccSettings2 where setting_id=258
		if @valueInt<=0 begin
			select -2 as Result,''Credit Sms Zero''
		end
		select @value=valor from ccSettings where setting_id=247

		select 1 as Result,@value as ApiBackBone
		,MessageTemplate
		from ccSmsTemplate where TemplateId=@templateId
	end
	else if @action=8 begin --smsOutSource
	    insert into smsOutSource (callkey,cam_id,sms_phoneNumber,sms_status,sms_attemps,user_id,sms_dateDial,dial_tels)
		values (@callKey,@camId,@phone,0,0,@userId,getdate(),''12345NNN'')
		select @smsout_id=SCOPE_IDENTITY()

		insert into smsoutSourceMessage(smsout_id,message)
		values(@smsout_id,@msg)

		select @smsout_id as smsoutId
	end
	else if @action=9 begin --smsccoLogDial
		insert into smsccoLogDial (smsout_id,cam_id,phone,smsDate,registryClient,SystemApiId,statusSystemsId,Bill,ProviderId)
		values (@smsout_id,@camId,@phone,getdate(),@callKey,@SystemApiId,@statusSystemsId,
		case when @statusSystemsId=0 then 0.7 else 0 end,0
		)	
	end
	else if @action=10 begin --ChangeSchedule
		delete from ccSmsSchedules where cam_id=@camId
		insert into ccSmsSchedules(cam_id,iDate,fDate) values(@camId,@dateStart,@dateEnd)
	end
	else if @action=11 begin --Carga los registros cargados
		truncate table ccSmsValidateRegistryWeek;
		SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
		---------------Revisa la lista de registros es necesario moverlo a otro proceso para que lo tenga en la carga---------------------
		insert into ccSmsValidateRegistryWeek(registryClient,total,totaltoDay,loadRegistry)
		select registryClient,count(*) total,
		count(case when smsDate>=@today  then 1 end) totaltoday,
		0 loadRegistry
		from smsccoLogDial with(nolock)
		where smsDate>=@monday
		group by registryClient

	end
	else if @action in(12,13) begin --Validar Carga
		declare @segmentTable table(id int, status bit, segmentName VARCHAR(10))
		declare @segmentNames varchar(max)
		declare @conditionTable table(conditionId int,smsCondition varchar(max),DailyLimit int,WeeklyLimit int,status bit)
		--declare @SmsRemesasId table (credictId int)
		create table #SmsRemesasId(creditId nvarchar(40), TDCT VARCHAR(max))
		create table #SmsRemesasIdTemp(creditId nvarchar(40), TDCT VARCHAR(max))
		create table #functionalState(creditId nvarchar(40), smsSent int)
		declare @FlagB table(credictId int, TDCT VARCHAR(max))
		------------Se obtiene los dias de la semana que han pasado
		DECLARE @lastMonday datetime, @WeekStart datetime;
		DECLARE @DaysFromWeek int, @LastMondaymonth int, @ActualMonth int
		DECLARE @actualDate datetime = getdate()
		SET @lastMonday = DATEADD(DAY, -(DATEPART(WEEKDAY, @actualDate) + 5) % 7, @actualDate);
		--select @lastMonday lastMonday, @actualDate actualDate

		SET @LastMondaymonth = DATEPART(MONTH, @lastMonday);
		SET @ActualMonth = DATEPART(MONTH, @actualDate);

		IF(@ActualMonth = @LastMondaymonth)
		BEGIN
			SELECT @DaysFromWeek = DATEDIFF(DAY, @lastMonday, @actualDate);
		END
		ELSE BEGIN
			SELECT @DaysFromWeek = DATEDIFF(DAY, DATEADD(DAY, 1 - DATEPART(DAY, @actualDate), @actualDate), @actualDate);
		END
		SET @WeekStart = CONVERT(datetime, CONVERT(date, @actualDate-@DaysFromWeek));
		

		--------------------------Comienza validacion--------------

		insert into @segmentTable
		select a.value,0 status, s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
		inner join ccSmsSegments s on s.segmentId = a.value

		--Condicion para obtener solo los que coincidan con SegmentoMC
		SELECT @segmentNames = COALESCE(@segmentNames + '', '', '''') + QUOTENAME(a.segmentName, '''''''')
		FROM @segmentTable a

		--Tabla con todos los id de la tabla remesa que hacen match con los segmentos
		INSERT INTO #SmsRemesasIdTemp
		SELECT a.credito, a.TDCT from SmsRemesasMuñozDay a 
		INNER JOIN @segmentTable b on a.SegmentoMC = b.segmentName
		--Reseteamos todos los resultados para los segmentos
		UPDATE rmd SET rmd.RESULTADO = '''', rmd.RESULTADO_ID = 0
		FROM SmsRemesasMuñozDay rmd 
		INNER JOIN #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
		--Actualizamos resultado para FLAG B
		UPDATE rmd SET rmd.RESULTADO = ''FLAG B'', rmd.RESULTADO_ID = 1
		FROM SmsRemesasMuñozDay rmd
		inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
		inner join ccSmsSegmentFlagB sfb on rmd.Fila = sfb.Validation
		WHERE rmd.RESULTADO_ID = 0 AND sfb.IsActive = 1

		--Actualizamos resultado para Telefono fijo y telefono no existe
		UPDATE rmd SET 
		rmd.RESULTADO = CASE 
			WHEN dbo.VerificaSmsMCA(rmd.TELEFONOS1) = 3 THEN ''NO ES POSIBLE ENVIO, CELUAR NO SE ENCUENTRA EN IFT''
			WHEN dbo.VerificaSmsMCA(rmd.TELEFONOS1) = 5 THEN ''TELEFONO FIJO''
			ELSE '''' END,
		rmd.RESULTADO_ID = dbo.VerificaSmsMCA(rmd.TELEFONOS1)
		FROM SmsRemesasMuñozDay rmd
		inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
		WHERE rmd.RESULTADO_ID = 0

		--Regla de Estado Funcional para segmento BMX_122
		UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4
		FROM SmsRemesasMuñozDay rmd
		inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
		WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
		AND ESTADO_FUNCIONAL <> ''F''

		INSERT INTO #functionalState
		select rid.creditId, count(rid.creditId) from smsccoLogDial ld
		inner join #SmsRemesasIdTemp rid on rid.TDCT = ld.callkey
		where ld.smsDate >= @WeekStart
		GROUP BY rid.creditId

		UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4
		FROM SmsRemesasMuñozDay rmd
		inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
		inner join #functionalState fs on rmd.id_credito = fs.creditId
		WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
		AND fs.smsSent >= 3;


		declare @subQuery nvarchar(max)
		
		SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
		
		if not exists(select * from ccSmsValidateRegistryWeek)begin
			exec ccspLoadRegistrySegments @action=11
		end
		

		declare @conditionId int,@segmentId int,@SubConditionId int
		declare @conditionWhere varchar(max)
		declare @SubConditionWhere varchar(max),@LogicConector varchar(20)
		declare @DailyLimit int,@WeeklyLimit int

		DECLARE @Params NVARCHAR(MAX)
		SET @Params = N''@WeeklyLimit int,@DailyLimit int'';
		
	---Lista de @segmentIds
	while exists(select * from @segmentTable where status=0) begin
		select top 1 @segmentId=id from @segmentTable where status=0		
		set @conditionId=0
		-------------------------------- Revisa las condiciones por segmentId --------------------------------
		while exists(select * from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId) begin
			
			select top 1
			@DailyLimit=DailyLimit,	@WeeklyLimit=WeeklyLimit,@conditionId=ConditionId,
			@conditionWhere= PrimaryField+LogicOperator
			+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
			+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')=''''then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end 
			+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
			from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId
			
			set @SubConditionId=0
			while exists(select * from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId) 
			begin
			
				select top 1
				@LogicConector=LogicConector,
				@SubConditionId=SubconditionId,
				@SubConditionWhere=
				PrimaryField+LogicOperator
				+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
				+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')='''' then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end
				+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
				from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId

				set @conditionWhere=@conditionWhere+'' ''+ @LogicConector+'' '' +@SubConditionWhere

				
			end
				
			insert into @conditionTable values(@conditionId,@conditionWhere,@DailyLimit,@WeeklyLimit,0)		
		end 
		-------------------------------- Termina las condiciones por segmentId --------------------------------
		update @segmentTable set status=1 where id=@segmentId
	end
	while exists(select * from @conditionTable where status=0) begin		
		select top 1 
		@conditionId=conditionId, @DailyLimit=DailyLimit, @WeeklyLimit=WeeklyLimit,	@conditionWhere=smsCondition
		from @conditionTable 
		where status=0
		
		set @subQuery= ''select A.id_credito, A.TDCT from SmsRemesasMuñozDay A with(nolock)
		left join ccSmsValidateRegistryWeek B on A.credito=B.registryClient and B.total<@WeeklyLimit and B.totaltoDay<@DailyLimit
		where  SegmentoMC in ('' + @segmentNames + '') AND RESULTADO_ID = 0 AND '' + @conditionWhere	
		print(@subQuery)
		insert into #SmsRemesasId
		EXEC sp_executesql @subQuery,@Params,@WeeklyLimit,@DailyLimit;
		update @conditionTable set status=1 where @conditionId=conditionId
	end

	--Actualizamos los ids que no coindiden
	UPDATE rmd SET rmd.RESULTADO = ''CUENTA CON T. Celular para envio de sms'' , rmd.RESULTADO_ID = 6
	FROM SmsRemesasMuñozDay rmd
	INNER JOIN #SmsRemesasId rid on rid.TDCT = rmd.TDCT
	WHERE RESULTADO_ID = 0;

	--Actualizamos todo lo que no cumple
	UPDATE rmd SET rmd.RESULTADO = ''NO CUMPLE CON REGLA DE CORTE'' , rmd.RESULTADO_ID = 2
	FROM SmsRemesasMuñozDay rmd
	INNER JOIN #SmsRemesasIdTemp rid on rid.TDCT = rmd.TDCT
	WHERE RESULTADO_ID = 0;
		
	if @action=12 begin
		declare @countValidate int,@nonValid int
		select @countValidate=count(1) from SmsRemesasMuñozDay A with(nolock)
		inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6

		select @nonValid=count(1) from SmsRemesasMuñozDay A with(nolock)
		inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID <> 6

		select @countValidate as ValidRecords,@nonValid as InvalidRecords
	end
	else begin
		
		set @sql=''select ''+@columns+'',0 PhoneStatus,0 callout_id,credito as Record_id,convert(varchar(100),'''''''') as DataPhone, TDCT as callkey
		into TEMPO_''+convert(varchar(10),@camId)+''
		from SmsRemesasMuñozDay A with(nolock) where A.TDCT in(select TDCT from #SmsRemesasId)''
		print(@sql)
		exec(@sql)
	end
	drop table #SmsRemesasId
	drop table #SmsRemesasIdTemp
	end
	else if @action =14 begin --Validar Carga
		select MessageTemplate from ccSmsTemplate where TemplateId=@templateId
	end

	else if @action =15 begin --Obtener resultados de validación por segmentos

		DECLARE @counter int = 0
		DECLARE @ActualDay DATETIME = GETDATE();
		DECLARE @FirstDayMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ActualDay),0)
		DECLARE @DayCounter DATETIME;
		DECLARE @WeekCount int = 0;

		WHILE @counter < DAY(@ActualDay)
		BEGIN
			SET @DayCounter =  DATEADD(DAY, @counter, @FirstDayMonth)
			IF DATEPART(WEEKDAY,@DayCounter) = 2
				SET @WeekCount = @WeekCount + 1
			print @DayCounter
			set @counter = @counter + 1
		END

		IF DATEPART(WEEKDAY, @FirstDayMonth) <> 2 BEGIN
			SET @WeekCount = @WeekCount + 1
		END

		declare @segments table(segmentName VARCHAR(10))

		insert into @segments
		select s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
		inner join ccSmsSegments s on s.segmentId = a.value

		select	id_credito AS id_credit, credito AS credit, GETDATE() as snapshot_date, MESES_VENCIDOS as expired_month, SEG_CUENTA as seg_account,
				FILA as seg_row, LOCACION as [location], DIA_CORTE as cut_day, SegmentoMC as segment_mc, @WeekCount as [week], DATEPART(WEEKDAY, @ActualDay) week_day,
				TELEFONOS1 as phones1, RESULTADO as result, ISNULL(ESTADO_FUNCIONAL, '''') as functional_state, ISNULL(CORTE_REAL, '''')  as real_cut
		from SmsRemesasMuñozDay rmd
		inner join @segments s on rmd.SegmentoMC = s.segmentName;
		
	end'
	EXEC(@sql);
	---------------------------------------------------------------END MACL-----------------------------------------------------
	----------------------------------------------------- BEGIN KR134001-Módulo de segmentos  ----------------------------------------------------------------
	SET @process = 'KR134001 DROP PROCEDURE ccspSmsSegments';
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''ccspSmsSegments'')
	BEGIN
	    DROP PROCEDURE ccspSmsSegments
	END';
	EXEC (@sql);

	SET @process = 'KR134001 CREATE PROCEDURE ccspSmsSegments';
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspSmsSegments] 
	@Action SMALLINT = NULL, 
	@TableName VARCHAR(100) = NULL, 
	@IsDelete BIT = NULL,
	@CampaignId INT = NULL,
	@Ids VARCHAR(MAX) = NULL,
	@SegmentId INT = NULL,
	@SegmentName VARCHAR(255) = NULL,
	@SegmentIsGlobal BIT = NULL,
	@ConditionId INT = NULL,
	@SubconditionId INT = NULL, 
	@PrimaryField VARCHAR(255) = NULL,
	@LogicOperator VARCHAR(2) = NULL,
	@ComparisonValue VARCHAR(150) = NULL, 
	@ComparisonField  VARCHAR(150) = NULL,
	@ArithmeticOperator VARCHAR(2) = NULL,
	@Value VARCHAR(255) = NULL,
	@LogicConector VARCHAR(3) = NULL,
	@DailyLimit INT = NULL, 
	@WeeklyLimit INT = NULL,
	@Id SMALLINT = NULL,
	@Validation VARCHAR(40) = NULL,
	@IsActive BIT = NULL
	AS

	DECLARE @IdsTemp TABLE (Id INT);
	DECLARE @Result TABLE (Names VARCHAR(MAX));
	INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

	IF @Action IS NOT NULL BEGIN
		IF @Action = 0 BEGIN		-- Get column names
			SELECT c.name AS ColumnName,
				   t.name AS ColumnType,
				   LEN(CONVERT(NVARCHAR(MAX), c.name)) AS ColumnLength
			FROM sys.columns c
			JOIN sys.types t ON c.system_type_id = t.system_type_id
			WHERE c.object_id = OBJECT_ID(@TableName) AND t.name <> ''sysname'';

		END
		IF @Action = 1 BEGIN		-- Get all segments, conditions, and rules
			SELECT  ISNULL(s.SegmentId, 0) AS SegmentId, 
					ISNULL(s.Name, '''') AS SegmentName, 
					ISNULL(s.IsGlobal, 0) AS SegmentIsGlobal,
					ISNULL(s.CampaignId, 0) AS CampaignId,
					ISNULL(c.ConditionId, 0) AS ConditionId, 
					ISNULL(c.PrimaryField, '''') AS ConditionPrimaryField,
					ISNULL(c.LogicOperator, '''') AS ConditionLogicOperator,
					ISNULL(c.ComparisonValue, 0) AS ConditionComparisonValue,
					ISNULL(c.ComparisonField, '''') AS ConditionComparisonField,
					ISNULL(c.ArithmeticOperator, '''') AS ConditionArithmeticOperator,
					ISNULL(c.Value, '''') AS ConditionValue, 
					ISNULL(c.DailyLimit, 0) AS ConditionDailyLimit,
					ISNULL(c.WeeklyLimit, 0) AS ConditionWeeklyLimit,
					ISNULL(sc.SubconditionId, 0) AS SubconditionId,
					ISNULL(sc.PrimaryField, '''') AS SubconditionPrimaryField,
					ISNULL(sc.LogicOperator, '''') AS SubconditionLogicOperator,
					ISNULL(sc.ComparisonValue, 0) AS SubconditionComparisonValue,
					ISNULL(sc.ComparisonField, '''') AS SubconditionComparisonField,
					ISNULL(sc.ArithmeticOperator, '''') AS SubconditionArithmeticOperator,
					ISNULL(sc.Value, '''') AS SubconditionValue,
					ISNULL(sc.LogicConector, '''') AS SubconditionLogicConector
			FROM ccSmsSegments s
			LEFT JOIN ccSmsConditions c ON s.SegmentId = c.SegmentId
			LEFT JOIN ccSmsSubconditions sc ON sc.ConditionId = c.ConditionId
			ORDER BY s.SegmentId, c.ConditionId, sc.SubconditionId;
			RETURN 0
		END
		ELSE IF @Action = 2 BEGIN		-- Assign/unassign segments to/from campaign 
			UPDATE ccSmsSegments
			SET CampaignId = CASE WHEN @CampaignId != 0 THEN @CampaignId ELSE 0 END
			FROM @IdsTemp ids
			WHERE ccSmsSegments.SegmentId = ids.Id

			INSERT INTO @Result
			SELECT ISNULL(segments.Name,'''')
	        FROM @IdsTemp ids
	        INNER JOIN ccSmsSegments segments ON segments.SegmentId = ids.Id
		END
		ELSE IF @Action = 3 BEGIN
	    BEGIN TRY
	        BEGIN TRANSACTION;
				-- Insert segment names into @Result before deletion
				INSERT INTO @Result
				SELECT ISNULL(segments.Name,'''')
				FROM @IdsTemp ids
				INNER JOIN ccSmsSegments segments ON segments.SegmentId = ids.Id
				WHERE segments.CampaignId = 0;

				DECLARE @ConditionIdsToDelete TABLE (ConditionId INT);
				DECLARE @SubconditionIdsToDelete TABLE (SubconditionId INT);

				INSERT INTO @ConditionIdsToDelete (ConditionId)
				SELECT c.ConditionId
				FROM ccSmsSegments s
				INNER JOIN ccSmsConditions c ON s.SegmentId = c.SegmentId
				INNER JOIN @IdsTemp ids ON s.SegmentId = ids.Id
				WHERE s.CampaignId = 0;

				INSERT INTO @SubconditionIdsToDelete (SubconditionId)
				SELECT sc.SubconditionId
				FROM ccSmsConditions c
				INNER JOIN ccSmsSubconditions sc ON c.ConditionId = sc.ConditionId
				WHERE c.ConditionId IN (SELECT ConditionId FROM @ConditionIdsToDelete)


				-- Delete from ccSmsSubconditions
				DELETE FROM ccSmsSubconditions
				WHERE SubconditionId IN (SELECT SubconditionId FROM @SubconditionIdsToDelete);

				-- Delete from ccSmsConditions
				DELETE FROM ccSmsConditions
				WHERE ConditionId IN (SELECT ConditionId FROM @ConditionIdsToDelete);

				-- Delete from ccSmsSegments
				DELETE FROM ccSmsSegments
				WHERE SegmentId IN (SELECT Id FROM @IdsTemp) 
				AND CampaignId = 0;


				COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
				
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END
		ELSE IF @Action = 4 BEGIN     -- Create or Edit Segment
	    BEGIN TRY
	        BEGIN TRANSACTION;
				-- Check if segment name already exists
				IF (
						((@SegmentId IS NULL OR @SegmentId = 0) AND EXISTS (SELECT 1 FROM ccSmsSegments WHERE Name = @SegmentName))
					OR
						(@SegmentId IS NOT NULL AND @SegmentId > 0 AND EXISTS (SELECT 1 FROM ccSmsSegments WHERE Name = @SegmentName AND SegmentId <> @SegmentId))
					)
				BEGIN
					INSERT INTO @Result VALUES (-2);
				END
				ELSE
				BEGIN
					-- Segment name does not exist, proceed with insert/update
					MERGE INTO ccSmsSegments AS Target
					USING (VALUES (@SegmentId, @SegmentName, @SegmentIsGlobal)) AS Source (SegmentId, SegmentName, SegmentIsGlobal)
					ON Target.SegmentId = Source.SegmentId
					WHEN MATCHED THEN
						UPDATE SET Name = Source.SegmentName, IsGlobal = Source.SegmentIsGlobal
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (Name, IsGlobal, CampaignId)
						VALUES (Source.SegmentName, Source.SegmentIsGlobal, 0);

					IF @@ROWCOUNT > 0
					BEGIN
						INSERT INTO @Result 
						SELECT (ISNULL(Name,'''') + ''>'' + CAST(SegmentId AS VARCHAR(MAX))) 
						FROM ccSmsSegments 
						WHERE SegmentId = @SegmentId OR SegmentId = SCOPE_IDENTITY();
					END
					ELSE
					BEGIN
						RAISERROR(''Failed to insert or update segment.'', 16, 1);
						ROLLBACK TRANSACTION;
						INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
					END
				END
				COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
	        
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END

		ELSE IF @Action = 5 BEGIN   -- Create or Edit Condition
	    BEGIN TRY
	        BEGIN TRANSACTION;

				MERGE INTO ccSmsConditions AS Target
				USING (VALUES (@ConditionId, @SegmentId, @PrimaryField, @LogicOperator, 
							   CASE WHEN @ComparisonValue = '''' THEN NULL ELSE @ComparisonValue END, 
							   CASE WHEN @ComparisonField = '''' THEN NULL ELSE @ComparisonField END, 
							   @ArithmeticOperator, @Value, @DailyLimit, @WeeklyLimit)) 
					AS Source (ConditionId, SegmentId, PrimaryField, LogicOperator, ComparisonValue, ComparisonField, ArithmeticOperator, Value, DailyLimit, WeeklyLimit)
				ON Target.ConditionId = Source.ConditionId
				WHEN MATCHED THEN
					UPDATE SET PrimaryField = Source.PrimaryField, LogicOperator = Source.LogicOperator, ComparisonValue = Source.ComparisonValue,
							   ComparisonField = Source.ComparisonField, ArithmeticOperator = Source.ArithmeticOperator, Value = Source.Value,
							   DailyLimit = Source.DailyLimit, WeeklyLimit = Source.WeeklyLimit
				WHEN NOT MATCHED BY TARGET THEN
					INSERT (SegmentId, PrimaryField, LogicOperator, ComparisonValue, ComparisonField, ArithmeticOperator, Value, DailyLimit, WeeklyLimit)
					VALUES (Source.SegmentId, Source.PrimaryField, Source.LogicOperator, Source.ComparisonValue, Source.ComparisonField,
							Source.ArithmeticOperator, Source.Value, Source.DailyLimit, Source.WeeklyLimit);

				IF @@ROWCOUNT > 0
				BEGIN
					INSERT INTO @Result SELECT CAST(ConditionId AS VARCHAR(MAX)) FROM ccSmsConditions WHERE ConditionId = @ConditionId OR ConditionId = SCOPE_IDENTITY();
				END
				ELSE
				BEGIN
					RAISERROR(''Failed to insert or update condition.'', 16, 1);
					ROLLBACK TRANSACTION;
					INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
				END

				COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
	        
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END

		ELSE IF @Action = 6 BEGIN  -- Create or Edit Subcondition
	    BEGIN TRY
	        BEGIN TRANSACTION;

				MERGE INTO ccSmsSubconditions AS Target
				USING (VALUES (@SubconditionId, @ConditionId, @PrimaryField, @LogicOperator,
							   CASE WHEN @ComparisonValue = '''' THEN NULL ELSE @ComparisonValue END, 
							   CASE WHEN @ComparisonField = '''' THEN NULL ELSE @ComparisonField END,
							   @ArithmeticOperator, @Value, @LogicConector)) 
					AS Source (SubconditionId, ConditionId, PrimaryField, LogicOperator, ComparisonValue, ComparisonField, ArithmeticOperator, Value, LogicConector)
				ON Target.SubconditionId = Source.SubconditionId
				WHEN MATCHED THEN
					UPDATE SET PrimaryField = Source.PrimaryField, LogicOperator = Source.LogicOperator, ComparisonValue = Source.ComparisonValue,
							   ComparisonField = Source.ComparisonField, ArithmeticOperator = Source.ArithmeticOperator, Value = Source.Value,
							   LogicConector = Source.LogicConector
				WHEN NOT MATCHED BY TARGET THEN
					INSERT (ConditionId, PrimaryField, LogicOperator, ComparisonValue, ComparisonField, ArithmeticOperator, Value, LogicConector)
					VALUES (Source.ConditionId, Source.PrimaryField, Source.LogicOperator, Source.ComparisonValue, Source.ComparisonField,
							Source.ArithmeticOperator, Source.Value, Source.LogicConector);

				IF @@ROWCOUNT > 0
				BEGIN
					INSERT INTO @Result VALUES (1); -- Return 1 if successful
				END
				ELSE
				BEGIN
					RAISERROR(''Failed to insert or update subcondition.'', 16, 1);
					ROLLBACK TRANSACTION;
					INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
				END

				COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
	        
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END
		ELSE IF @Action = 7 BEGIN  -- Delete Conditions
	    BEGIN TRY
	        BEGIN TRANSACTION;

				-- Delete Subconditions
				DELETE FROM ccSmsSubconditions
				WHERE ConditionId IN (SELECT Id FROM @IdsTemp);

				DELETE FROM ccSmsConditions
				WHERE ConditionId IN (SELECT Id FROM @IdsTemp);

				IF @@ROWCOUNT > 0
				BEGIN
					COMMIT TRANSACTION;
					INSERT INTO @Result VALUES (1); -- Return 1 if successful
				END
				ELSE
				BEGIN
					RAISERROR(''No rows were affected.'', 16, 1);
					ROLLBACK TRANSACTION;
					INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
				END
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
	        
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END
		ELSE IF @Action = 8 BEGIN  -- Delete Subconditions
	    BEGIN TRY
	        BEGIN TRANSACTION;

				-- Delete Subconditions
				DELETE FROM ccSmsSubconditions
				WHERE SubconditionId IN (SELECT Id FROM @IdsTemp);

				IF @@ROWCOUNT > 0
				BEGIN
					COMMIT TRANSACTION;
					INSERT INTO @Result VALUES (1); -- Return 1 if successful
				END
				ELSE
				BEGIN
					RAISERROR(''No rows were affected.'', 16, 1);
					ROLLBACK TRANSACTION;
					INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
				END
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
	        
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END

		ELSE IF @Action = 9 BEGIN  -- Create or Edit Validation
	    BEGIN TRY
	        BEGIN TRANSACTION;

				IF @IsDelete = 1 BEGIN
					DELETE FROM ccSmsSegmentFlagB WHERE Id = @Id;

					IF @@ROWCOUNT > 0
					BEGIN
						INSERT INTO @Result SELECT @Validation;
					END
					ELSE
					BEGIN
						RAISERROR(''Failed to delete validation.'', 16, 1);
						ROLLBACK TRANSACTION;
						INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
					END
				END
				ELSE BEGIN
					MERGE INTO ccSmsSegmentFlagB AS Target
					USING (VALUES (@Id, @Validation, @IsActive)) 
					AS Source (Id, Validation, IsActive)
					ON Target.Id = Source.Id
					WHEN MATCHED THEN
						UPDATE SET IsActive = Source.IsActive
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (Validation, IsActive)
						VALUES (Source.Validation, Source.IsActive);

					IF @@ROWCOUNT > 0
					BEGIN
						INSERT INTO @Result SELECT Validation FROM ccSmsSegmentFlagB WHERE Id = @Id OR Id = SCOPE_IDENTITY();
					END
					ELSE
					BEGIN
						RAISERROR(''Failed to insert or update validation.'', 16, 1);
						ROLLBACK TRANSACTION;
						INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
					END

				END

				COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
				PRINT ''Error Message: '' + ERROR_MESSAGE();
				IF @@TRANCOUNT > 0 
					ROLLBACK TRANSACTION;
	        
				INSERT INTO @Result VALUES (-1); -- Return -1 in case of error
			END CATCH;
		END

		ELSE IF @Action = 10 BEGIN  -- Bulkcopy SmsRemesasMuñozDay to SmsRemesasMuñozDayBefore
		BEGIN TRY
			BEGIN TRANSACTION;

				DELETE FROM SmsRemesasMuñozDayBefore;

				INSERT INTO SmsRemesasMuñozDayBefore
				SELECT
					id_credito,
					fecha_actualizacion,
					id_Cartera,
					credito,
					COMPRAS_DISPMONEDA,
					DIA_CORTE,
					DIA_CORTE_NUM,
					DIAACTUAL,
					DIAMASCINCO,
					DIAMASCUATRO,
					DIAMASDOS,
					DIAMASTRES,
					DIAMASUNO,
					ETIQUETA_BASE_RECOM,
					FECHACORTE,
					IMPORTE_1ERPAGO_MULTIPAYMENT,
					IMPORTE_2DOPAGO_MULTIPAYMENT,
					IMPORTE_3ERPAGO_MULTIPAYMENT,
					IMPORTE_ENDOSPAGOS,
					IMPORTE_PAGO_ONESHOT,
					IMPORTE_PAGO_ONESHOT_2,
					IMPORTE_PAGOBON_ONESHOT,
					INTERES_IVA_COMISION,
					MESES_VENCIDOS,
					MINIMOPAGARPESOS,
					NoSMS,
					PQC_MULTIPAYMENT_SIMULACION,
					PQC_ONESHOT_SIMULACION,
					PRODUCTO_GENERAL,
					Quita_capital_3Pagos,
					Quita_capital_ONESHOT,
					RCV7DESCPRODUCTO,
					RCV7MV0_MONEDA,
					RCV7MV1_FILTRO,
					RCV7MV1_MONEDA,
					RCV7MV2_FILTRO,
					RCV7MV2_MONEDA,
					RCV7MV3_MONEDA,
					SALDO_ACTUALMONEDA,
					SALDO_CAPITAL,
					SALDO_DEUDOR,
					SALDO_VENCIDOMONEDA,
					SEG_CUENTA,
					SegmentoMC,
					SumaMultiPayment,
					TDCT,
					TELEFONOS1,
					TERMINACION,
					CAMPAÑABENJAMIN,
					TIPO_TELEFONO,
					N_EMAIL,
					TEL_POSICION,
					SALDO_DEUDOR_FILTRO,
					NUM_CUENTA,
					INTERES_IVA_COMISION_FILTRO,
					STATUS,
					PROMESA,
					FILA,
					LOCACION,
					ESTADO_FUNCIONAL,
					CORTE_REAL,
					CORTE,
					RESULTADO,
					RESULTADO_ID,
					RESULTADO_ENVIO
				FROM SmsRemesasMuñozDay;

				COMMIT TRANSACTION;
				INSERT INTO @Result VALUES (1);
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION;
				INSERT INTO @Result VALUES (-1);
			END CATCH
		END
		IF @Action <> 0 BEGIN SELECT * FROM @Result END
	END
	ELSE BEGIN
		RAISERROR(''Invalid action specified.'', 16, 1);
		RETURN -1;
	END
	';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Modules for Activity History';
	SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM ccGalateaModules WHERE ModuleId = 15) BEGIN
		INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt)
		VALUES (15, ''Segmentos'', ''Segments'', ''Segmentos'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Operation for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 96) BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (96, ''Asignar segmento'', ''Assign segment'', ''Atribuir segmento'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Operation for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 97) BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (97, ''Desasignar segmento'', ''Unassign segment'', ''Cancelar atribuição de segmento'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Operation for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 109) BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (109, ''Eliminar segmento'', ''Delete segment'', ''Excluir segmento'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Operation for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 110) BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (110, ''Crear segmento'', ''Create segment'', ''Criar segmento'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Operation for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 111) BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (111, ''Editar segmento'', ''Edit segment'', ''Editar segmento'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Operation for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 112) BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (112, ''Editar parámetros de validación'', ''Edit verification parameters'', ''Editar parâmetros de verificação'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Identifiers for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description LIKE ''%ADD_FLAGB_VALIDATION%'') BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
		VALUES (''ADD_FLAGB_VALIDATION'', ''Parámetro añadido'', ''Added parameter'', ''Parâmetro adicionado'');
	END;';
	EXEC (@sql);

	SET @process = 'KR134001 Insert Identifiers for Activity History';
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description LIKE ''%DELETE_FLAGB_VALIDATION%'') BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
		VALUES (''DELETE_FLAGB_VALIDATION'', ''Parámetro eliminado'', ''Deleted parameter'', ''Parâmetro excluído'');
	END;';
	EXEC (@sql);
	----------------------------------------------------- END KR134001-Módulo de segmentos  ----------------------------------------------------------------
	----------------------------------------------- Ulises Espinosa Begin ----------------------------------------------------------------------------------
	set @process = 'insertar ccMenus'
	set @sql = 'if not exists (select 1 from ccMenus where menu_id = 13030)
	begin
		INSERT INTO ccMenus (menu_id, menu_descrip, parent, nivel, ordengral, [type], HelpSWF, release)
		VALUES(13030, ''Detalle de segmentos'',13000, ''B'', 12, 3, '''', '''' )
	end'
	EXEC(@sql)

	set @process = 'Insert relation user-menu'
	set @sql = 'IF not exists (select 1 from ccMenuUser where id_User = 1 and id_Menu = 13030)
	BEGIN
		INSERT INTO ccMenuUser(id_User, id_Menu, type) VALUES (1, 13030,3)
	END'
	EXEC(@sql)
	-------------------------------------------------- Ulises Espinosa End -----------------------------------------------------------------------------------

	 	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
