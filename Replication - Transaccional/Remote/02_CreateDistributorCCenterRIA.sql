SET NOCOUNT ON;
USE [CCenterRIA];

DECLARE @Version INT, @Version_Actual INT;

---------------- VERSION ----------------
SET @Version = 127;  -- Ajusta el número de versión según corresponda
EXEC @Version_Actual = dbo.ccsp_getVersion 'BD';

IF @Version_Actual >= @Version
BEGIN
    DECLARE @dataBaseName VARCHAR(100) = N'CCenterRIA';
    DECLARE @publicationServer NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX), @@SERVERNAME);

    -- Obtener nombre del servidor sin la instancia
    DECLARE @hostName NVARCHAR(MAX) = @@SERVERNAME;
    DECLARE @indexInstancia TINYINT = CHARINDEX('\', @hostName);
    IF @indexInstancia > 0
        SET @hostName = SUBSTRING(@hostName, 0, @indexInstancia);

    -- Configurar credenciales
    DECLARE @jobLogin NVARCHAR(MAX);
    DECLARE @jobPassword NVARCHAR(MAX);
    DECLARE @userNameSQL NVARCHAR(50);
    DECLARE @passwordSQL NVARCHAR(50);
    DECLARE @userNameWin NVARCHAR(50);
    DECLARE @passwordWin NVARCHAR(50);
    DECLARE @publisherLogin NVARCHAR(MAX);
    DECLARE @publisherPassword NVARCHAR(MAX);
    DECLARE @snapshotFolder NVARCHAR(MAX);

    -- Obtener credenciales desde configuración
    DECLARE @settingBD NVARCHAR(100);
    DECLARE @temp TABLE (id INT, value NVARCHAR(100));
    SELECT @settingBD = valor FROM ccSettings WHERE setting_id = 176;
    INSERT INTO @temp SELECT id, Value FROM fn_RIASplitDelimited(@settingBD, '|');

    SELECT @userNameWin = value FROM @temp WHERE id = 1;
    SELECT @passwordWin = value FROM @temp WHERE id = 2;
    SELECT @userNameSQL = value FROM @temp WHERE id = 3;
    SELECT @passwordSQL = value FROM @temp WHERE id = 4;
    SELECT @hostName = value FROM @temp WHERE id = 5;

    -- Configurar credenciales para agentes
    SET @jobLogin = ISNULL(@userNameWin, @hostName + '\SnapshotReplication');
    SET @jobPassword = ISNULL(@passwordWin, 'Nuxiba2010');
    SET @publisherLogin = ISNULL(@userNameSQL, 'replication');
    SET @publisherPassword = ISNULL(@passwordSQL, 'replication');

    -- Configurar carpeta de snapshot
    SET @snapshotFolder = '\\' + @hostName + '\ReplData\' + @publicationServer;

    ------------------ INICIO SCRIPT ------------------

 --   /***************************/
	--/*** Install Distributor ***/
	--/***************************/
	use [master]

	create table #distributor(
	[installed] [int] null,
	[distribution server] [sysname] null,
	[distribution db installed] [int] null,
	[is distribution publisher] [int] null,
	[has remote distribution publisher] [int] null
	)

	insert into #distributor
	exec sp_get_distributor

	if (select [installed] from #distributor) = 0
	begin
		exec sp_adddistributor @distributor = @publicationServer, @password = N'Nux1ba2025';		  
	end
			
	if (select [distribution db installed] from #distributor) = 0
		begin
			exec sp_adddistributiondb @database= N'distribution', @security_mode = 0,@login =@publisherLogin, @password =@publisherPassword 
		end

	if (select [is distribution publisher] from #distributor) = 0
		begin			
			exec sp_adddistpublisher @publisher = @publicationServer, 
			@distribution_db = N'distribution' , @security_mode =0,  @login =@publisherLogin,@password = @publisherPassword
		end

	drop table #distributor

	
	/**************************************/
	/*** Change default Snapshot Folder ***/
	/**************************************/

	USE [CCenterRIA]	
	exec sp_changedistpublisher @publisher = @publicationServer, @property = 'working_directory', @value = @snapshotFolder
	/***********************************/
	/*** Enable replication database ***/
	/***********************************/
	USE [CCenterRIA];
	EXEC sp_replicationdboption @dbname = @dataBaseName, @optname = N'publish', @value = N'true';

 --   /***********************************/
	--/*** Create replication profiles ***/
	--/***********************************/
	

	--if not exists(SELECT * FROM msdb..MSagent_profiles  WHERE profile_name = 'Nuxiba' collate database_default AND agent_type = 3)
	--	exec sp_add_agent_profile @profile_name = 'Nuxiba', @profile_type = 1, @agent_type = 3, @default = 1


	--if not exists(SELECT * FROM msdb..MSagent_profiles  WHERE profile_name = 'Nuxiba' collate database_default AND agent_type = 4)
	--	exec sp_add_agent_profile @profile_name = 'Nuxiba', @profile_type = 1, @agent_type = 4, @default = 1


	--DECLARE @profileidDA AS int
	--DECLARE @profileidMA AS int

	--CREATE TABLE #profiles (
	--	profile_id int,
	--	profile_name sysname,
	--	agent_type int,
	--	[type] int,
	--	description varchar(3000),
	--	def_profile bit)

	--INSERT INTO #profiles (profile_id, profile_name,
	--	agent_type, [type],description, def_profile)
	--	EXEC sp_help_agent_profile

	--SET @profileidDA = (SELECT profile_id FROM #profiles where agent_type = 3 and profile_name = 'Nuxiba' )
	--SET @profileidMA = (SELECT profile_id FROM #profiles where agent_type = 4 and profile_name = 'Nuxiba' )

	--DROP TABLE #profiles

	--EXEC sp_change_agent_parameter @profile_id = @profileidDA, @parameter_name = N'-QueryTimeout', @parameter_value = 3600
	--EXEC sp_change_agent_parameter @profile_id = @profileidMA, @parameter_name = N'-QueryTimeout', @parameter_value = 3600

	/******************************/
	/*** Change user dboowner *****/
	/******************************/
    IF EXISTS (SELECT * FROM sys.databases WHERE name = @dataBaseName)
       AND NOT EXISTS (SELECT * FROM sys.databases WHERE suser_sname(owner_sid) <> 'sa' AND name = @dataBaseName)
    BEGIN
        ALTER AUTHORIZATION ON DATABASE::CCenterRIA TO sa;
    END;

    ------------------ FIN SCRIPT ------------------

    SELECT 'Configuración del Distribuidor Finalizada';
END
ELSE
BEGIN
    SELECT 'Versión incorrecta de la base de datos, versión actual: ' 
        + CAST(@Version_Actual AS VARCHAR(5)) 
        + ', versión requerida: ' + CAST(@Version AS VARCHAR(5));
END;
SET NOCOUNT OFF;
