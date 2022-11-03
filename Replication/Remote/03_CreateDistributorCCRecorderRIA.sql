set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
use [CCRecorderRIA]

select @Version_Actual = par_valor from TREC_PARAMETROS where par_id = 30

if @Version_Actual >= @Version
 begin
	declare @dataBaseName varchar(100)
	set @dataBaseName=N'CCRecorderRIA';

	declare @Sql nvarchar(max)
	declare @publicationServer nvarchar(max)

	declare @hostName nvarchar(max),@indexInstancia tinyint
	select @hostName =@@servername
	select @indexInstancia =charindex('\',@hostName )
	if @indexInstancia>0
		set @hostName = substring(@hostName , 0, charindex('\',@hostName ))


	set @publicationServer = convert(nvarchar(max),@@servername)
	
	declare @userNameSQL nvarchar(50)
	declare @passwordSQL nvarchar(50)

	declare @publisherLogin nvarchar(max)
	declare @publisherPassword nvarchar(max)
	declare @snapshotFolder nvarchar(max)


	declare @settingBD nvarchar(100)

	declare @temp table	(id int, value nvarchar(100));
	select @settingBD = par_valor from TREC_PARAMETROS where par_id = 73
	insert into @temp select id,Value from fn_RIASplitDelimited(@settingBD,'|')
	
	select @userNameSQL = value  from @temp where id = 3
	select @passwordSQL = value  from @temp where id = 4
	select @hostName = value  from @temp where id = 5
	

	-----Agregado de credenciales SQL SERVER-----
	set @publisherLogin = isnull(@userNameSQL,'replication')
	set @publisherPassword =  isnull(@passwordSQL,'replication')

	-----Folder compartido para las replicas-----
	set @snapshotFolder =  '\\' + @hostName + '\ReplData\'+@publicationServer	

	/***********************************************/
	/*** Revisa la BD distribution para replicas ***/
	/***********************************************/
	declare @DefaultData nvarchar(512)
	declare @DefaultLog nvarchar(512)

	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultData output
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLog output


	declare @MasterData nvarchar(512)
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg0', @MasterData output
	select @MasterData=substring(@MasterData, 3, 255)
	select @MasterData=substring(@MasterData, 1, len(@MasterData) - charindex('\', reverse(@MasterData)))

	declare @MasterLog nvarchar(512)
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg2', @MasterLog output
	select @MasterLog=substring(@MasterLog, 3, 255)
	select @MasterLog=substring(@MasterLog, 1, len(@MasterLog) - charindex('\', reverse(@MasterLog)))

	declare @distributionMDF varchar(512)
	declare @distributionLDF varchar(512)
	declare @exists int
	set @exists = 0

	select @distributionMDF = isnull(@DefaultData, @MasterData) + '\distribution.mdf'
	select @distributionLDF = isnull(@DefaultLog, @MasterLog) + '\distribution.ldf'
	

	if exists (SELECT name FROM master..sysdatabases where name = 'distribution')
		select @exists = 1

	DECLARE @out INT
	EXEC xp_fileexist @distributionMDF, @out OUTPUT;
	if (@out = 1 and @exists = 0)
		begin
			exec sp_configure 'show advanced options', 1
			reconfigure
			exec sp_configure 'xp_cmdshell', 1
			reconfigure
			declare @delDistributionMDF sysname
			set @delDistributionMDF = 'del "' + @distributionMDF + '"'
			exec xp_cmdshell @delDistributionMDF, no_output
		end

	EXEC xp_fileexist @distributionLDF, @out OUTPUT;
	if (@out = 1 and @exists = 0)
		begin
			exec sp_configure 'show advanced options', 1
			reconfigure
			exec sp_configure 'xp_cmdshell', 1
			reconfigure
			declare @delDistributionLDF varchar(512)
			set @delDistributionLDF = 'del "' + @distributionLDF + '"'
			exec xp_cmdshell @delDistributionLDF, no_output
		end

	
	------------------ INICIO SCRIPT ------------------

	/***************************/
	/*** Install Distributor ***/
	/***************************/
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
			exec sp_adddistributor @distributor = @publicationServer						  
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

	USE [CCRecorderRIA]	
	exec sp_changedistpublisher @publisher = @publicationServer, @property = 'working_directory', @value = @snapshotFolder

	/***********************************/
	/*** Enable replication database ***/
	/***********************************/
	use [master]
	exec sp_replicationdboption @dbname = @dataBaseName, @optname = N'merge publish', @value = N'true'


	/***********************************/
	/*** Create replication profiles ***/
	/***********************************/
	

	if not exists(SELECT * FROM msdb..MSagent_profiles  WHERE profile_name = 'Nuxiba' collate database_default AND agent_type = 3)
		exec sp_add_agent_profile @profile_name = 'Nuxiba', @profile_type = 1, @agent_type = 3, @default = 1


	if not exists(SELECT * FROM msdb..MSagent_profiles  WHERE profile_name = 'Nuxiba' collate database_default AND agent_type = 4)
		exec sp_add_agent_profile @profile_name = 'Nuxiba', @profile_type = 1, @agent_type = 4, @default = 1


	DECLARE @profileidDA AS int
	DECLARE @profileidMA AS int

	CREATE TABLE #profiles (
		profile_id int,
		profile_name sysname,
		agent_type int,
		[type] int,
		description varchar(3000),
		def_profile bit)

	INSERT INTO #profiles (profile_id, profile_name,
		agent_type, [type],description, def_profile)
		EXEC sp_help_agent_profile

	SET @profileidDA = (SELECT profile_id FROM #profiles where agent_type = 3 and profile_name = 'Nuxiba' )
	SET @profileidMA = (SELECT profile_id FROM #profiles where agent_type = 4 and profile_name = 'Nuxiba' )

	DROP TABLE #profiles

	EXEC sp_change_agent_parameter @profile_id = @profileidDA, @parameter_name = N'-QueryTimeout', @parameter_value = 3600
	EXEC sp_change_agent_parameter @profile_id = @profileidMA, @parameter_name = N'-QueryTimeout', @parameter_value = 3600

	/******************************/
	/*** Change user dboowner *****/
	/******************************/

	if exists (select * from sys.databases where name=@dataBaseName) and
		not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name=@dataBaseName) begin
			ALTER AUTHORIZATION ON DATABASE::CCRecorderRIA TO sa
	end

	------------------ FIN SCRIPT ------------------

	select 'Create Distributor Finished'
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off